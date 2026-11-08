#!/bin/sh
# Proves fetch in install-linux-tools.sh retries a failed download, checks the pinned hash once, and that running the
# script still installs both tools. Fakes stand in for curl, sleep, sha256sum and pip, so it needs no network.
here=$(cd "$(dirname "$0")" && pwd)
script=$here/install-linux-tools.sh
real_sha=$(command -v sha256sum)
failures=0
root=$(mktemp -d)
trap 'rm -rf "${root:?}"' EXIT

check() {
  desc=$1
  shift
  if "$@"; then echo "ok: $desc"; else echo "FAIL: $desc"; failures=$((failures + 1)); fi
}

count() {
  if [ -f "$1" ]; then wc -l < "$1" | tr -d ' '; else echo 0; fi
}

new_case() {
  dir=$(mktemp -d "$root/case.XXXXXX")
  bin=$dir/bin
  mkdir -p "$bin" "$dir/tmp" "$dir/home" "$dir/scratch"
  cat > "$bin/sleep" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/sleep.log"
EOF
  cat > "$bin/sha256sum" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/sha.log"
exec "$REAL_SHA" "$@"
EOF
  chmod +x "$bin/sleep" "$bin/sha256sum"
}

# A failed try leaves partial bytes behind, as curl does when a connection drops mid-download.
fake_failing_curl() {
  cat > "$bin/curl" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/curl.log"
tries=$(( $(wc -l < "$FAKE_DIR/curl.log") ))
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
if [ "$tries" -le "$FAKE_CURL_FAILS" ]; then printf 'partial' > "$out"; exit 22; fi
printf '%s' "$FAKE_CURL_BODY" > "$out"
EOF
  chmod +x "$bin/curl"
}

good='invented bytes'
good_sha=$(printf '%s' "$good" | "$real_sha" | cut -d' ' -f1)
url=https://example.invalid/tool.zip

# usage: run_fetch <number of leading curl calls that fail> <bytes a passing curl writes> <pause, empty to leave unset>
run_fetch() {
  new_case
  fake_failing_curl
  (
    export PATH="$bin:$PATH" FAKE_DIR="$dir" REAL_SHA="$real_sha" FAKE_CURL_FAILS=$1 FAKE_CURL_BODY=$2 HOME="$dir/home" \
      TMPDIR="$dir/scratch"
    if [ -n "$3" ]; then export FETCH_PAUSE_SECONDS=$3; else unset FETCH_PAUSE_SECONDS; fi
    . "$script"
    tmp=$dir/tmp
    fetch "$url" "$good_sha" tool.zip
  ) > "$dir/stdout" 2> "$dir/stderr"
  status=$?
  curls=$(count "$dir/curl.log")
  shas=$(count "$dir/sha.log")
  sleeps=$(count "$dir/sleep.log")
}

has_line() { grep -Fxq "$1" "$2"; }
lacks_line() { ! has_line "$1" "$2"; }
sleeps_are() { [ "$(cat "$dir/sleep.log" 2> /dev/null)" = "$1" ]; }
file_is() { [ "$(cat "$1")" = "$2" ]; }
is_installed() { [ -x "$dir/home/.local/bin/swiftlint" ] && [ -x "$dir/home/.local/bin/swiftformat" ]; }
nothing_ran() { [ ! -e "$dir/home/.local" ] && [ -z "$(ls -A "$dir/scratch")" ]; }

run_fetch 2 "$good" 0
check "retry-then-pass: fetch returns 0 after two failed tries" [ "$status" = 0 ]
check "retry-then-pass: curl ran 3 times" [ "$curls" = 3 ]
check "retry-then-pass: the hash was checked once" [ "$shas" = 1 ]
check "retry-then-pass: the file in place is the passing try's" file_is "$dir/tmp/tool.zip" "$good"

run_fetch 99 "$good" 0
check "retry-gives-up: fetch returns non-zero" [ "$status" != 0 ]
check "retry-gives-up: curl ran 4 times" [ "$curls" = 4 ]
check "retry-gives-up: stderr names the URL and the 4 tries" has_line "fetch: giving up on $url after 4 tries" "$dir/stderr"
check "retry-gives-up: no hash check ran" [ "$shas" = 0 ]

run_fetch 0 "wrong bytes" 0
check "bad-sha-still-fails: fetch returns non-zero" [ "$status" != 0 ]
check "bad-sha-still-fails: curl ran once" [ "$curls" = 1 ]
check "bad-sha-still-fails: the hash was checked once" [ "$shas" = 1 ]
check "bad-sha-still-fails: it does not say it gave up" lacks_line "fetch: giving up on $url after 4 tries" "$dir/stderr"

run_fetch 0 "$good" 0
check "a first try that passes returns 0" [ "$status" = 0 ]
check "a first try that passes makes one curl call and one hash check" [ "$curls$shas" = 11 ]
check "a first try that passes does not pause" [ "$sleeps" = 0 ]

run_fetch 99 "$good" 7
check "the pause is FETCH_PAUSE_SECONDS, between the 4 tries and not after the last" sleeps_are "$(printf '7\n7\n7')"

run_fetch 99 "$good" ""
check "the pause defaults to 5 seconds" sleeps_are "$(printf '5\n5\n5')"

new_case
(
  export PATH="$bin:$PATH" FAKE_DIR="$dir" REAL_SHA="$real_sha" HOME="$dir/home" TMPDIR="$dir/scratch"
  . "$script"
)
check "sourcing the script runs nothing and makes no temp dir" nothing_ran

new_case
mkdir -p "$dir/zips/swiftlint" "$dir/zips/swiftformat"
printf '#!/bin/sh\n' > "$dir/zips/swiftlint/swiftlint-static"
printf '#!/bin/sh\n' > "$dir/zips/swiftformat/swiftformat_linux"
chmod +x "$dir/zips/swiftlint/swiftlint-static" "$dir/zips/swiftformat/swiftformat_linux"
(cd "$dir/zips/swiftlint" && zip -q ../swiftlint.zip swiftlint-static)
(cd "$dir/zips/swiftformat" && zip -q ../swiftformat.zip swiftformat_linux)
cat > "$bin/curl" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/curl.log"
while [ $# -gt 0 ]; do [ "$1" = -o ] && out=$2; shift; done
cp "$FAKE_DIR/zips/${out##*/}" "$out"
EOF
cat > "$bin/pip" <<'EOF'
#!/bin/sh
echo "$*" >> "$FAKE_DIR/pip.log"
EOF
printf '#!/bin/sh\ncat > /dev/null\n' > "$bin/sha256sum"
chmod +x "$bin/curl" "$bin/pip" "$bin/sha256sum"
env PATH="$bin:$PATH" FAKE_DIR="$dir" HOME="$dir/home" TMPDIR="$dir/scratch" GITHUB_PATH="$dir/github_path" \
  "$script" > "$dir/stdout" 2> "$dir/stderr"
status=$?
check "running the script succeeds" [ "$status" = 0 ]
check "running the script installs swiftlint and swiftformat" is_installed
check "running the script fetches both tools" [ "$(count "$dir/curl.log")" = 2 ]
check "running the script installs lizard" grep -Fq 'lizard==1.24.3' "$dir/pip.log"
check "running the script puts the bin dir on the runner's PATH" has_line "$dir/home/.local/bin" "$dir/github_path"

[ "$failures" = 0 ] && echo "install-linux-tools tests: all passed"
exit "$failures"
