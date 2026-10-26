#!/bin/sh
# Fails when the app could send entries off the device. The promise is on-device only, so each exception needs the
# stakeholder's approval and a change to this script in the same pull request.
root=${1:-.}
fail=0
violation() { echo "PRIVACY VIOLATION: $1" && fail=1; }

code="$root/Sources $root/App"

imports='HealthKit|CloudKit|Network|WebKit|AdSupport|AppTrackingTransparency'
if grep -rEn --include="*.swift" "^[[:space:]]*(@testable[[:space:]]+)?import[[:space:]]+($imports)([^[:alnum:]_]|$)" $code
then violation "imports a framework that reads health data, syncs, tracks, or reaches the network"; fi

calls='URLSession|URLRequest|NWConnection|NSUbiquitousKeyValueStore|ubiquityContainer|cloudKitDatabase'
if grep -rEn --include="*.swift" "($calls)" $code
then violation "uses a network or iCloud API"; fi

if grep -rEn --include="*.swift" "https?://" $code
then violation "contains a URL literal"; fi

if grep -En '\.package\([^)]*(url|id):' "$root/Package.swift"
then violation "Package.swift pulls a remote package"; fi

if grep -En '^[[:space:]]+(url|github):' "$root/project.yml"
then violation "project.yml pulls a remote package"; fi

if find "$root" -name "*.entitlements" -not -path "*/.build/*" -not -path "*/.derived/*" -not -path "*/.spm/*" | grep .
then violation "an entitlements file grants a capability"; fi

if grep -rEn --include="project.yml" --include="*.plist" --include="*.xcconfig" \
  "NSHealth|NSUserTracking|com\.apple\.developer\.(healthkit|icloud)|aps-environment" "$root" \
  --exclude-dir=.build --exclude-dir=.derived --exclude-dir=.spm
then violation "a health, tracking, iCloud, or push key is set"; fi

exit $fail
