#!/bin/sh
# Proves check-privacy.sh fails on each kind of violation and passes on a clean tree.
here=$(cd "$(dirname "$0")" && pwd)
failures=0

# usage: expect <pass|fail> <description> <setup commands run inside a fresh tree>
expect() {
  want=$1 desc=$2 setup=$3
  tree=$(mktemp -d)
  mkdir -p "$tree/Sources/AnkyDomain" "$tree/App"
  printf 'import Foundation\n' > "$tree/Sources/AnkyDomain/Clean.swift"
  printf 'import SwiftUI\n' > "$tree/App/AnkyApp.swift"
  printf '// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: "Anky")\n' > "$tree/Package.swift"
  printf 'name: Anky\npackages:\n  Anky:\n    path: .\n' > "$tree/project.yml"
  (cd "$tree" && eval "$setup")
  if "$here/check-privacy.sh" "$tree" > /dev/null 2>&1; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then echo "FAIL: $desc (wanted $want, got $got)"; failures=$((failures + 1)); fi
  rm -rf "${tree:?}"
}

expect pass "a clean tree" ":"
expect fail "HealthKit import" "echo 'import HealthKit' > App/Health.swift"
expect fail "CloudKit import" "echo 'import CloudKit' > Sources/AnkyDomain/Sync.swift"
expect fail "Network import" "echo 'import Network' > Sources/AnkyDomain/Net.swift"
expect fail "tracking import" "echo 'import AppTrackingTransparency' > App/Track.swift"
expect fail "URLSession use" "echo 'let s = URLSession.shared' > Sources/AnkyDomain/Http.swift"
expect fail "iCloud key-value store" "echo 'let s = NSUbiquitousKeyValueStore.default' > App/Kv.swift"
expect fail "SwiftData CloudKit store" "echo 'let c = ModelConfiguration(cloudKitDatabase: .automatic)' > App/Store.swift"
expect fail "a URL literal" "echo 'let u = \"https://example.com\"' > App/Url.swift"
expect fail "remote package in Package.swift" "echo '.package(url: \"https://x.test/a\", exact: \"1.0.0\")' >> Package.swift"
expect fail "remote package in project.yml" "printf '  Remote:\n    url: https://x.test/a\n' >> project.yml"
expect fail "an entitlements file" "touch App/Anky.entitlements"
expect fail "a HealthKit usage key" "echo 'INFOPLIST_KEY_NSHealthShareUsageDescription: x' >> project.yml"
expect fail "a tracking usage key" "echo 'NSUserTrackingUsageDescription' > App/Info.plist"
expect pass "a violation only in a test" "mkdir -p Tests/T && echo 'import HealthKit' > Tests/T/T.swift"

[ "$failures" = 0 ] && echo "check-privacy tests: all passed"
exit "$failures"
