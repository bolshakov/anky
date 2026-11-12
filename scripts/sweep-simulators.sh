#!/bin/sh
# Shuts down and deletes every unused simulator whose name matches SWEEP_NAME_GLOB and whose folder is past the grace period.
SWEEP_NAME_GLOB=${SWEEP_NAME_GLOB:-anky-*}
SWEEP_GRACE_SECONDS=${SWEEP_GRACE_SECONDS:-10800}
SWEEP_STEP_SECONDS=${SWEEP_STEP_SECONDS:-45}
SWEEP_DEVICES_DIR=${SWEEP_DEVICES_DIR:-$HOME/Library/Developer/CoreSimulator/Devices}
SWEEP_TERM_SECONDS=${SWEEP_TERM_SECONDS:-2}
SWEEP_KILL=${SWEEP_KILL:-kill}

for tool in xcrun timeout; do
  command -v "$tool" > /dev/null 2>&1 || { echo "sweep-simulators: $tool not found" >&2; exit 2; }
done

# usage: step <name> <shutdown|delete> <udid>. Runs one simctl call under the step limit and says when it failed.
step() {
  timeout "$SWEEP_STEP_SECONDS" xcrun simctl "$2" "$3" < /dev/null > /dev/null 2>&1 && return 0
  status=$?
  echo "$1: $2 failed"
  return "$status"
}

# usage: keep_reason <udid>. Prints why the device stays, or nothing when it may go.
keep_reason() {
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
    "$SWEEP_KILL" -TERM "$pid" || continue
    echo "ended $pid $name"
    signalled="$signalled $pid"
  done <<EOF
$orphans
EOF
  sleep "$SWEEP_TERM_SECONDS"
  for pid in $signalled; do
    ! "$SWEEP_KILL" -0 "$pid" || "$SWEEP_KILL" -KILL "$pid"
  done
}
sweep_orphans
exit 0
