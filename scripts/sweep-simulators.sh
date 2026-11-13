#!/bin/sh
# Shuts down and deletes every unused simulator whose name matches SWEEP_NAME_GLOB and whose folder is past the grace period.
SWEEP_NAME_GLOB=${SWEEP_NAME_GLOB:-anky-*}
SWEEP_GRACE_SECONDS=${SWEEP_GRACE_SECONDS:-10800}
SWEEP_STEP_SECONDS=${SWEEP_STEP_SECONDS:-45}
SWEEP_DEVICES_DIR=${SWEEP_DEVICES_DIR:-$HOME/Library/Developer/CoreSimulator/Devices}
SWEEP_TERM_SECONDS=${SWEEP_TERM_SECONDS:-2}
SWEEP_KILL=${SWEEP_KILL:-kill}
SWEEP_LOCK_DIR=${SWEEP_LOCK_DIR:-${TMPDIR:-/tmp}/anky-sweep.lock}

for tool in xcrun timeout; do
  command -v "$tool" > /dev/null 2>&1 || { echo "sweep-simulators: $tool not found" >&2; exit 2; }
done

# usage: lock_holder_alive. Succeeds when the pid in the lock names a running process. Pid 0 would name our own group.
lock_holder_alive() {
  holder=$(cat "$SWEEP_LOCK_DIR/pid" 2> /dev/null)
  case "$holder" in
    '' | *[!0-9]* | 0) return 1 ;;
  esac
  kill -0 "$holder" 2> /dev/null
}

# mkdir is atomic, so of two overlapping runs only one takes the lock. A dead pid in the lock means a crashed run.
if ! mkdir "$SWEEP_LOCK_DIR" 2> /dev/null; then
  if lock_holder_alive; then
    echo "sweep already running"
    exit 0
  fi
  rm -rf "$SWEEP_LOCK_DIR"
  mkdir "$SWEEP_LOCK_DIR" 2> /dev/null || { echo "sweep already running"; exit 0; }
fi
echo $$ > "$SWEEP_LOCK_DIR/pid"
trap 'rm -rf "$SWEEP_LOCK_DIR"' EXIT
trap 'exit 1' TERM INT

# usage: step <name> <shutdown|delete> <udid>. Runs one simctl call under the step limit and says when it failed.
# Status 124 is timeout's own, so a stuck call is given up on and left for the next run.
step() {
  timeout "$SWEEP_STEP_SECONDS" xcrun simctl "$2" "$3" < /dev/null > /dev/null 2>&1 && return 0
  status=$?
  if [ "$status" = 124 ]; then
    echo "gave up on $1: $2 timed out"
  else
    echo "$1: $2 failed"
  fi
  return "$status"
}

# usage: in_use <udid>. Succeeds when a running job of ours names the device. A process that merely holds the UDID, such
# as the device's own launchd_sim or an editor, is not a job, so only these programs count, run directly or through a shell.
in_use() {
  ps -axww -o pid=,command= 2> /dev/null | awk -v udid="$1" -v self="$$" '
    $1 == self { next }
    {
      exe = $2
      if (exe ~ /(^|\/)(sh|bash|zsh)$/) exe = $3
      sub(/.*\//, "", exe)
    }
    exe ~ /^(xcodebuild|run-ui-tests\.sh|axe|simctl)$/ && index(tolower($0), tolower(udid)) { found = 1; exit }
    END { exit !found }
  '
}

# usage: keep_reason <udid>. Prints why the device stays, or nothing when it may go.
keep_reason() {
  if in_use "$1"; then echo "in use"; return; fi
  born=$(stat -f %B "$SWEEP_DEVICES_DIR/$1" 2> /dev/null) || born=
  case "$born" in
    '' | *[!0-9]* | 0) echo "age unreadable"; return ;;
  esac
  if [ $(($(date +%s) - born)) -lt "$SWEEP_GRACE_SECONDS" ]; then echo "younger than grace"; fi
}

# usage: sweep_device <name> <udid> <state>.
sweep_device() {
  why=$(keep_reason "$2")
  if [ -n "$why" ]; then echo "kept $1: $why"; return; fi
  if [ "$3" != Shutdown ]; then step "$1" shutdown "$2" || return; fi
  step "$1" delete "$2" && echo "removed $1"
}

# A device line reads "    <name> (<udid>) (<state>) ". The name may hold parentheses and the state a space.
list=$(timeout "$SWEEP_STEP_SECONDS" xcrun simctl list devices < /dev/null) || list=
[ -n "$list" ] || {
  echo "sweep-simulators: simctl list devices failed or returned nothing" >&2
  exit 2
}
printf '%s\n' "$list" \
  | sed -n 's/^ *\(.*\) (\([0-9A-Fa-f-]\{36\}\)) (\([^)]*\)).*$/\1|\2|\3/p' \
  | while IFS='|' read -r name udid state; do
    # shellcheck disable=SC2254
    case "$name" in
      $SWEEP_NAME_GLOB) sweep_device "$name" "$udid" "$state" ;;
    esac
  done

# A runtime service whose launchd_sim is gone is adopted by launchd, pid 1. The shared daemons and launchd_sim also have
# parent 1 but live outside a runtime's RuntimeRoot folder, so the path keeps them out.
# usage: sweep_orphans. Sends TERM to every orphan, then KILL to those that still answer, and names each one.
sweep_orphans() {
  orphans=$(ps -axww -o pid=,ppid=,command= | while read -r pid ppid command; do
    [ "$ppid" = 1 ] || continue
    rest=${command#*/RuntimeRoot/}
    [ "$rest" != "$command" ] || continue
    exe=${rest%% *}
    echo "$pid ${exe##*/}"
  done)
  [ -n "$orphans" ] || return 0
  signalled=
  while read -r pid name; do
    "$SWEEP_KILL" -TERM "$pid" 2> /dev/null || continue
    echo "ended $pid $name"
    signalled="$signalled $pid"
  done <<EOF
$orphans
EOF
  sleep "$SWEEP_TERM_SECONDS"
  for pid in $signalled; do
    ! "$SWEEP_KILL" -0 "$pid" 2> /dev/null || "$SWEEP_KILL" -KILL "$pid" 2> /dev/null
  done
}
sweep_orphans
exit 0
