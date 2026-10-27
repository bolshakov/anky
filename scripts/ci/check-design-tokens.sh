#!/bin/sh
# Fails when a corner radius is written as a number outside App/Design. The card radius has one name, Corner.card,
# so a number anywhere else would drift from the mockups without any build error.
root=${1:-.}
fail=0
violation() { echo "DESIGN TOKEN VIOLATION: $1" && fail=1; }

radii=$(grep -rEn --include="*.swift" "Radius[[:space:]]*[:(][[:space:]]*[0-9]" "$root/App" | grep -v "^$root/App/Design/")
if [ -n "$radii" ]; then
  echo "$radii"
  violation "writes a corner radius as a number, use Corner.card from App/Design"
fi

exit $fail
