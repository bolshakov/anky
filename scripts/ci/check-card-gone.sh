#!/bin/sh
# Fails when a text of the old Check In card is under App/. The card was removed from Today, and a returning card would
# show one waiting dose twice.
root=${1:-.}
fail=0
violation() { echo "CARD GONE VIOLATION: $1" && fail=1; }

texts=$(grep -rFn --include="*.swift" --include="Localizable.xcstrings" \
  -e "How is your pain now?" -e "Log pain" "$root/App")
if [ -n "$texts" ]; then
  echo "$texts"
  violation "the old Check In card's text is back, Today has no card that asks how the pain is now"
fi

exit $fail
