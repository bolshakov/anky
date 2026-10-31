#!/bin/sh
# Fails when a Swift file does not open with the license line, so each file of the GPL-licensed code states its license.
root=${1:-.}
expected='// SPDX-License-Identifier: GPL-3.0-or-later'

swift_files() {
  for dir in App Sources Tests; do
    if [ -d "$root/$dir" ]; then find "$root/$dir" -type f -name '*.swift'; fi
  done
  if [ -f "$root/Package.swift" ]; then printf '%s\n' "$root/Package.swift"; fi
}

files=$(swift_files)
if [ -z "$files" ]; then
  printf 'LICENSE HEADER VIOLATION: no Swift file under %s\n' "$root"
  exit 1
fi

# The loop runs in a subshell, so its findings come back as output rather than as an exit status.
violations=$(printf '%s\n' "$files" | while IFS= read -r f; do
  if [ "$(head -n 1 "$f")" != "$expected" ]; then printf 'LICENSE HEADER VIOLATION: %s\n' "$f"; fi
done)

if [ -n "$violations" ]; then
  printf '%s\n' "$violations"
  exit 1
fi
exit 0
