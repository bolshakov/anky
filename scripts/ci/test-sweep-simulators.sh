#!/bin/sh
# Proves sweep-simulators.sh decides each simulator correctly. Stubs stand in for xcrun, ps, stat and kill, so it runs on Linux.
here=$(cd "$(dirname "$0")" && pwd)
sweep=$here/../sweep-simulators.sh
failures=0
root=$(mktemp -d)
trap 'rm -rf "${root:?}"' EXIT

old=7200
young=60
u1=AAAAAAAA-0000-4000-8000-000000000001
u2=AAAAAAAA-0000-4000-8000-000000000002
u3=AAAAAAAA-0000-4000-8000-000000000003

report() {
  if [ "$2" = 0 ]; then echo "ok: $1"; else echo "FAIL: $1"; failures=$((failures + 1)); fi
}

# usage: link_tools <dir> <tool...>. Links the real tools into a folder that holds nothing else.
link_tools() {
  dir=$1
  shift
  mkdir -p "$dir"
  for tool in "$@"; do ln -s "$(command -v "$tool")" "$dir/$tool"; done
}

# usage: device <name> <udid> <state> <age in seconds, unreadable, or zero>. Adds one line to the fixture.
device() {
  echo "$1|$2|$3|$4" >> "$fixture"
}

# Each stub appends its call to one log, so the calls are visible. The fixture holds one simulator per line.
new_tree() {
  tree=$(mktemp -d "$root/case.XXXXXX")
  bin=$tree/bin
  calls=$tree/calls.log
  out=$tree/out.log
  err=$tree/err.log
  fixture=$tree/fixture
  mkdir -p "$bin"
  : > "$calls"
  : > "$fixture"
  : > "$tree/ps.out"
  cat > "$bin/xcrun" <<EOF
#!/bin/sh
echo "xcrun \$*" >> "$calls"
case "\$1 \$2" in
  "simctl list")
    case "\$STUB_LIST" in
      fail) echo "CoreSimulatorService connection invalid" >&2; exit 1 ;;
      empty) exit 0 ;;
    esac
    echo "== Devices =="
    echo "-- iOS 26.5 --"
    while IFS='|' read -r name udid state age; do
      printf '    %s (%s) (%s) \n' "\$name" "\$udid" "\$state"
    done < "$fixture" ;;
  "simctl shutdown")
    [ "\$STUB_HANG" = "shutdown \$3" ] && exec sleep 30
    [ "\$STUB_FAIL" = "shutdown \$3" ] && exit 1 ;;
  "simctl delete")
    [ "\$STUB_HANG" = "delete \$3" ] && exec sleep 30
    [ "\$STUB_FAIL" = "delete \$3" ] && exit 1 ;;
  *) echo "stub xcrun: unexpected call \$*" >&2; exit 99 ;;
esac
exit 0
EOF
  cat > "$bin/stat" <<EOF
#!/bin/sh
echo "stat \$*" >> "$calls"
udid=\$(basename "\$3")
while IFS='|' read -r name id state age; do
  [ "\$id" = "\$udid" ] || continue
  [ "\$age" = unreadable ] && exit 1
  [ "\$age" = zero ] && { echo 0; exit 0; }
  echo \$((\$(date +%s) - age))
  exit 0
done < "$fixture"
exit 1
EOF
  cat > "$bin/ps" <<EOF
#!/bin/sh
cat "$tree/ps.out"
EOF
  cat > "$bin/kill" <<EOF
#!/bin/sh
echo "kill \$*" >> "$calls"
[ "\$1" = -0 ] && case " \$STUB_ALIVE " in *" \$2 "*) exit 0 ;; *) exit 1 ;; esac
case " \$STUB_KILL_FAIL " in *" \$2 "*) exit 1 ;; esac
exit 0
EOF
  chmod +x "$bin/xcrun" "$bin/stat" "$bin/ps" "$bin/kill"
}

# usage: run_sweep [VAR=value ...]. Sets code to the script's exit status. Runs it under sh, as launchd does.
run_sweep() {
  env PATH="$bin:$PATH" SWEEP_KILL="$bin/kill" SWEEP_DEVICES_DIR="$tree/devices" SWEEP_GRACE_SECONDS=3600 \
    SWEEP_STEP_SECONDS=5 SWEEP_LOCK_DIR="$tree/lock" "$@" sh "$sweep" > "$out" 2> "$err"
  code=$?
}

# usage: no_call <pattern>. Passes when no logged call matches.
no_call() {
  ! grep -q "$1" "$calls"
}

new_tree
device anky-dead $u1 Booted $old
run_sweep
[ "$code" = 0 ] && grep -qx "removed anky-dead" "$out" \
  && [ "$(grep -v '^stat ' "$calls" | tail -n 2)" = "xcrun simctl shutdown $u1
xcrun simctl delete $u1" ]
report "a dead booted device older than the grace period is shut down, deleted and named" $?

new_tree
device anky-young $u1 Booted $young
run_sweep
[ "$code" = 0 ] && grep -qx "kept anky-young: younger than grace" "$out" \
  && no_call "simctl shutdown" && no_call "simctl delete"
report "a device younger than the grace period is kept and named" $?

new_tree
device "iPad mini (A17 Pro)" $u1 Booted $old
device iPhone-anky $u2 Shutdown $old
run_sweep
[ "$code" = 0 ] && no_call "simctl shutdown" && no_call "simctl delete" && no_call "$u1" && no_call "$u2" \
  && [ ! -s "$out" ]
report "a device whose name does not match the glob is never looked up, shut down or deleted" $?

new_tree
device anky-mine $u1 Booted $old
device anky-theirs $u2 Booted $old
run_sweep SWEEP_NAME_GLOB=anky-mine
[ "$code" = 0 ] && grep -qx "removed anky-mine" "$out" && no_call "$u2"
report "SWEEP_NAME_GLOB narrows the sweep to its own device" $?

new_tree
device anky-quiet $u1 Shutdown $old
run_sweep
[ "$code" = 0 ] && grep -qx "removed anky-quiet" "$out" && no_call "simctl shutdown" \
  && grep -qx "xcrun simctl delete $u1" "$calls"
report "an unused device that is already shut down is deleted with no shutdown call" $?

new_tree
device anky-stopping $u1 "Shutting Down" $old
run_sweep
[ "$code" = 0 ] && grep -qx "xcrun simctl shutdown $u1" "$calls" && grep -qx "removed anky-stopping" "$out"
report "a device that is shutting down still gets a shutdown call" $?

new_tree
device anky-unknown $u1 Booted unreadable
run_sweep
[ "$code" = 0 ] && grep -qx "kept anky-unknown: age unreadable" "$out" \
  && no_call "simctl shutdown" && no_call "simctl delete"
report "a device whose birth time cannot be read is kept" $?

new_tree
device anky-zero $u1 Booted zero
run_sweep
[ "$code" = 0 ] && grep -qx "kept anky-zero: age unreadable" "$out" && no_call "simctl delete"
report "a birth time of zero is treated as unreadable" $?

new_tree
device anky-dead $u1 Booted $old
run_sweep STUB_LIST=fail
[ "$code" = 2 ] && [ -s "$err" ] && no_call "simctl shutdown" && no_call "simctl delete"
report "a failing simctl list exits 2 and deletes nothing" $?

new_tree
device anky-dead $u1 Booted $old
run_sweep STUB_LIST=empty
[ "$code" = 2 ] && [ -s "$err" ] && no_call "simctl shutdown" && no_call "simctl delete"
report "an empty simctl list exits 2 and deletes nothing" $?

new_tree
device anky-dead $u1 Booted $old
link_tools "$tree/tools" sed date
env PATH="$bin:$tree/tools" SWEEP_DEVICES_DIR="$tree/devices" /bin/sh "$sweep" > "$out" 2> "$err"
code=$?
[ "$code" = 2 ] && grep -q timeout "$err" && no_call "simctl shutdown" && no_call "simctl delete"
report "a missing timeout exits 2 and deletes nothing" $?

new_tree
device anky-dead $u1 Booted $old
link_tools "$tree/tools" sed date timeout
env PATH="$tree/tools" SWEEP_DEVICES_DIR="$tree/devices" /bin/sh "$sweep" > "$out" 2> "$err"
code=$?
[ "$code" = 2 ] && grep -q xcrun "$err" && no_call "simctl shutdown" && no_call "simctl delete"
report "a missing xcrun exits 2 and deletes nothing" $?

new_tree
device anky-stuck $u1 Booted $old
device anky-next $u2 Booted $old
run_sweep STUB_FAIL="shutdown $u1"
[ "$code" = 0 ] && grep -qx "anky-stuck: shutdown failed" "$out" && no_call "simctl delete $u1" \
  && grep -qx "removed anky-next" "$out" && ! grep -q "removed anky-stuck" "$out"
report "a failed shutdown prints its failed line, skips the delete, and the next device is still processed" $?

new_tree
device anky-stuck $u1 Shutdown $old
device anky-next $u2 Shutdown $old
run_sweep STUB_FAIL="delete $u1"
[ "$code" = 0 ] && grep -qx "anky-stuck: delete failed" "$out" && grep -qx "removed anky-next" "$out" \
  && ! grep -q "removed anky-stuck" "$out"
report "a failed delete prints its failed line and the next device is still processed" $?

new_tree
device anky-a $u1 Booted $old
device anky-b $u2 Shutdown $young
device anky-c $u3 Booted unreadable
run_sweep
[ "$(wc -l < "$out" | tr -d ' ')" = 3 ]
report "each device gets exactly one line of output" $?


# usage: ps_line <pid> <command...>. Adds one process to the fixture, as ps -o pid=,command= prints it.
ps_line() {
  printf '%6s %s\n' "$1" "$2" >> "$tree/ps.out"
}

# usage: kept_in_use <process command line>. Passes when that process keeps an old device and nothing is removed.
kept_in_use() {
  new_tree
  device anky-busy $u1 Booted $old
  ps_line 4242 "$1"
  run_sweep
  [ "$code" = 0 ] && grep -qx "kept anky-busy: in use" "$out" && no_call "simctl shutdown" && no_call "simctl delete"
}

# usage: removed_despite <process command line>. Passes when that process does not keep an old device.
removed_despite() {
  new_tree
  device anky-idle $u1 Booted $old
  ps_line 4242 "$1"
  run_sweep
  [ "$code" = 0 ] && grep -qx "removed anky-idle" "$out" && ! grep -q "in use" "$out"
}

kept_in_use "/Applications/Xcode.app/Contents/Developer/usr/bin/simctl spawn $u1 sleep 120"
report "a simctl process naming the device keeps it" $?

kept_in_use "/usr/bin/xcodebuild test -scheme Anky -destination id=$u1"
report "an xcodebuild process naming the device keeps it" $?

kept_in_use "/opt/homebrew/bin/axe tap --id log-entry --udid $u1"
report "an axe process naming the device keeps it" $?

kept_in_use "/bin/sh /work/anky/scripts/ci/run-ui-tests.sh light .derived $u1"
report "a run-ui-tests.sh process run through sh keeps the device" $?

kept_in_use "bash scripts/ci/run-ui-tests.sh $u1"
report "a run-ui-tests.sh process run through bash keeps the device" $?

kept_in_use "scripts/ci/run-ui-tests.sh $u1"
report "a run-ui-tests.sh process run by its own path keeps the device" $?

kept_in_use "/usr/bin/xcodebuild test -destination id=$(echo "$u1" | tr 'A-F' 'a-f')"
report "a lowercase UDID on the command line still keeps the device" $?

removed_despite "/usr/bin/simctl spawn $u2 sleep 120"
report "a simctl process naming another device keeps nothing" $?

removed_despite "/Library/Developer/CoreSimulator/Volumes/RuntimeRoot/sbin/launchd_sim /Devices/$u1/data/var/run/launchd_bootstrap.plist"
report "a device whose only process is its own launchd_sim is removed" $?

removed_despite "vim /notes/$u1.txt"
report "an editor holding the UDID does not keep the device" $?

removed_despite "/bin/sh /work/notes.sh $u1"
report "a shell running another script with the UDID does not keep the device" $?

removed_despite "/usr/bin/xcodebuild-helper --device $u1"
report "a process whose name only starts with xcodebuild does not keep the device" $?

removed_despite "/usr/bin/xcodebuild test -scheme Anky"
report "an xcodebuild process that does not name the device keeps nothing" $?

new_tree
device anky-young $u1 Booted $young
ps_line 4242 "/usr/bin/simctl spawn $u1 sleep 120"
run_sweep
[ "$code" = 0 ] && grep -qx "kept anky-young: in use" "$out" && ! grep -q "younger than grace" "$out"
report "a young device with an in-use process prints the in-use line" $?

new_tree
device anky-old $u1 Booted $old
device anky-busy $u2 Booted $old
ps_line 4242 "/usr/bin/simctl spawn $u2 sleep 120"
run_sweep
[ "$code" = 0 ] && grep -qx "removed anky-old" "$out" && grep -qx "kept anky-busy: in use" "$out" && no_call "$u2 "
report "an in-use device is kept while an idle one beside it is removed" $?

new_tree
device anky-old $u1 Booted $old
env PATH="$bin:$PATH" SWEEP_KILL="$bin/kill" SWEEP_DEVICES_DIR="$tree/devices" SWEEP_GRACE_SECONDS=3600 \
  SWEEP_STEP_SECONDS=5 sh -c 'echo "$$ /usr/bin/simctl list $3" > "$1"; exec sh "$2"' sweep "$tree/ps.out" "$sweep" "$u1" \
  > "$out" 2> "$err"
code=$?
[ "$code" = 0 ] && grep -qx "removed anky-old" "$out"
report "the sweep's own process never keeps a device" $?

rt="/Library/Developer/CoreSimulator/Volumes/iOS_23F77/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 26.5.simruntime/Contents/Resources/RuntimeRoot"
fw=/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/Resources/SimRenderingServices.simdeviceio/Contents/XPCServices

# usage: proc <pid> <ppid> <command>. Adds one line to the ps fixture, as `ps -o pid=,ppid=,command=` prints it.
proc() {
  printf '%6s %5s %s\n' "$1" "$2" "$3" >> "$tree/ps.out"
}

# usage: killed <signal> <pid>. Passes when the stub kill was called with that signal for that pid.
killed() {
  grep -qx "kill -$1 $2" "$calls"
}

new_tree
proc 4101 1 "$rt/usr/libexec/backboardd"
run_sweep SWEEP_TERM_SECONDS=0
[ "$code" = 0 ] && killed TERM 4101 && grep -qx "ended 4101 backboardd" "$out"
report "a parent-1 runtime process gets TERM and is named by its executable" $?

new_tree
proc 4101 1 "$rt/usr/libexec/backboardd"
proc 4102 1 "$rt/usr/libexec/logd"
run_sweep SWEEP_TERM_SECONDS=0 STUB_ALIVE=4101
[ "$code" = 0 ] && killed TERM 4101 && killed KILL 4101 && killed TERM 4102 && ! killed KILL 4102
report "only a process that survives TERM gets KILL" $?

new_tree
proc 4101 1 "$rt/usr/libexec/backboardd"
proc 4102 1 "$rt/usr/libexec/logd"
run_sweep SWEEP_TERM_SECONDS=0
last_term=$(grep -n '^kill -TERM' "$calls" | tail -n 1 | cut -d: -f1)
first_check=$(grep -n '^kill -0' "$calls" | head -n 1 | cut -d: -f1)
[ "$(grep -c '^kill -TERM' "$calls")" = 2 ] && [ "$last_term" -lt "$first_check" ]
report "every orphan gets TERM before any liveness check" $?

new_tree
proc 4101 1 "$rt/System/Library/PrivateFrameworks/RemoteManagement.framework/XPCServices/Subscriber.xpc/Subscriber -flag"
run_sweep SWEEP_TERM_SECONDS=0
grep -qx "ended 4101 Subscriber" "$out"
report "the named executable drops the arguments and a runtime path with spaces" $?

new_tree
proc 4101 1 "launchd_sim /Users/someone/Library/Developer/CoreSimulator/Devices/$u1/data/var/run/launchd_bootstrap.plist"
proc 4102 4101 "$rt/usr/libexec/logd"
proc 4103 1 "$rt/usr/libexec/backboardd"
run_sweep SWEEP_TERM_SECONDS=0
[ "$code" = 0 ] && ! killed TERM 4101 && ! killed TERM 4102 && killed TERM 4103 \
  && [ "$(grep -c '^ended' "$out")" = 1 ]
report "a runtime process whose parent is a launchd_sim, and the launchd_sim itself, get no signal" $?

new_tree
proc 3001 1 /Library/Developer/PrivateFrameworks/CoreSimulator.framework/Versions/A/XPCServices/com.apple.CoreSimulator.CoreSimulatorService.xpc/Contents/MacOS/com.apple.CoreSimulator.CoreSimulatorService
proc 3002 1 /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app/Contents/MacOS/SimulatorTrampoline
proc 3003 1 "$fw/SimMetalHost.xpc/Contents/MacOS/SimMetalHost"
proc 3004 1 "$fw/SimRenderServer.xpc/Contents/MacOS/SimRenderServer"
run_sweep SWEEP_TERM_SECONDS=0
[ "$code" = 0 ] && no_call "^kill" && [ ! -s "$out" ]
report "the shared simulator daemons with parent 1 get no signal" $?

new_tree
proc 5001 7000 "$rt/usr/libexec/logd"
proc 5002 1 /usr/sbin/cfprefsd
run_sweep SWEEP_TERM_SECONDS=0
[ "$code" = 0 ] && no_call "^kill" && [ ! -s "$out" ]
report "no orphans prints nothing and sends nothing" $?

new_tree
proc 4101 1 "$rt/usr/libexec/backboardd"
proc 4102 1 "$rt/usr/libexec/logd"
run_sweep SWEEP_TERM_SECONDS=0 STUB_KILL_FAIL=4101 STUB_ALIVE=4101
[ "$code" = 0 ] && ! grep -q "ended 4101" "$out" && ! killed KILL 4101 && grep -qx "ended 4102 logd" "$out"
report "a process that TERM cannot reach is neither named nor sent KILL" $?

new_tree
device anky-dead $u1 Booted $old
proc 4101 1 "$rt/usr/libexec/backboardd"
run_sweep SWEEP_TERM_SECONDS=0 SWEEP_NAME_GLOB=no-such-device
[ "$code" = 0 ] && grep -qx "ended 4101 backboardd" "$out" && no_call "simctl delete"
report "orphans are ended whatever the device glob matches" $?

# usage: seconds_taken <command...>. Sets taken to the whole seconds the command ran.
seconds_taken() {
  began=$(date +%s)
  "$@"
  taken=$(($(date +%s) - began))
}

new_tree
device anky-stuck $u1 Booted $old
device anky-next $u2 Booted $old
seconds_taken run_sweep STUB_HANG="shutdown $u1" SWEEP_STEP_SECONDS=1
[ "$code" = 0 ] && [ "$taken" -lt 10 ] && grep -qx "gave up on anky-stuck: shutdown timed out" "$out" \
  && no_call "simctl delete $u1" && grep -qx "removed anky-next" "$out" && ! grep -q "failed" "$out"
report "a shutdown that hangs is given up on, the device is left, and the next device is processed" $?

new_tree
device anky-stuck $u1 Shutdown $old
device anky-next $u2 Shutdown $old
seconds_taken run_sweep STUB_HANG="delete $u1" SWEEP_STEP_SECONDS=1
[ "$code" = 0 ] && [ "$taken" -lt 10 ] && grep -qx "gave up on anky-stuck: delete timed out" "$out" \
  && grep -qx "removed anky-next" "$out" && ! grep -q "removed anky-stuck" "$out" && ! grep -q "failed" "$out"
report "a delete that hangs is given up on and the next device is processed" $?

new_tree
device anky-stopping $u1 "Shutting Down" $old
seconds_taken run_sweep STUB_HANG="shutdown $u1" SWEEP_STEP_SECONDS=1
[ "$code" = 0 ] && grep -qx "xcrun simctl shutdown $u1" "$calls" \
  && grep -qx "gave up on anky-stopping: shutdown timed out" "$out" && no_call "simctl delete"
report "a device stuck shutting down is given a shutdown call and given up on when it hangs" $?

new_tree
mkdir "$tree/lock"
echo $$ > "$tree/lock/pid"
device anky-dead $u1 Booted $old
run_sweep
[ "$code" = 0 ] && [ "$(cat "$out")" = "sweep already running" ] && [ ! -s "$calls" ] && [ -d "$tree/lock" ] \
  && [ "$(cat "$tree/lock/pid")" = "$$" ]
report "a run while the lock holds a live pid prints that a sweep is running, calls nothing and keeps the lock" $?

new_tree
sh -c 'exit 0' &
dead=$!
wait "$dead"
mkdir "$tree/lock"
echo "$dead" > "$tree/lock/pid"
device anky-dead $u1 Booted $old
run_sweep
[ "$code" = 0 ] && grep -qx "removed anky-dead" "$out" && ! grep -q "already running" "$out" && [ ! -d "$tree/lock" ]
report "a lock whose pid is dead is taken over and removed when the run ends" $?

new_tree
mkdir "$tree/lock"
device anky-dead $u1 Booted $old
run_sweep
[ "$code" = 0 ] && grep -qx "removed anky-dead" "$out" && [ ! -d "$tree/lock" ]
report "a lock with no pid in it is taken over" $?

new_tree
device anky-dead $u1 Booted $old
run_sweep
[ "$code" = 0 ] && [ ! -d "$tree/lock" ]
report "the lock is removed after a normal run" $?

new_tree
device anky-dead $u1 Booted $old
run_sweep STUB_LIST=fail
[ "$code" = 2 ] && [ ! -d "$tree/lock" ]
report "the lock is removed after a run that exits 2" $?

# usage: lock_after_term. Passes when a run stopped by TERM while it waits on simctl leaves no lock and ends through its
# own trap, which exits 1. A shell that TERM killed outright ends with 143, and macOS sh removes the lock then too.
lock_after_term() {
  new_tree
  device anky-stuck $u1 Booted $old
  env PATH="$bin:$PATH" SWEEP_KILL="$bin/kill" SWEEP_DEVICES_DIR="$tree/devices" SWEEP_GRACE_SECONDS=3600 \
    SWEEP_STEP_SECONDS=1 SWEEP_LOCK_DIR="$tree/lock" STUB_HANG="shutdown $u1" sh "$sweep" > "$out" 2> "$err" &
  sweep_pid=$!
  tries=0
  while [ ! -s "$tree/lock/pid" ] && [ "$tries" -lt 50 ]; do
    tries=$((tries + 1))
    sleep 0.1
  done
  kill -s TERM "$sweep_pid"
  wait "$sweep_pid"
  term_code=$?
  [ "$term_code" = 1 ] && [ ! -d "$tree/lock" ]
}

lock_after_term
report "the lock is removed and the run exits through its trap when it is stopped by TERM" $?

[ "$failures" = 0 ]
