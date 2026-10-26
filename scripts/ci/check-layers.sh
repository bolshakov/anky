#!/bin/sh
# Fails when a layer imports one it must not. SwiftPM alone lets an undeclared import through on a warm build.
fail=0
check() {
  if grep -rEn --include="*.swift" "^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+($2)([^[:alnum:]_]|$)" "$1"
  then echo "LAYER VIOLATION: $3" && fail=1
  fi
}
check Sources/AnkyDomain "SwiftUI|UIKit|SwiftData|HealthKit" "AnkyDomain must stay pure"
exit $fail
