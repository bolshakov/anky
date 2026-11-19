#!/bin/sh
# Xcode build phase: sets CFBundleVersion of the built app to the number of commits up to the built commit, so a build
# number is a function of the commit alone. A build never fails for it: without a full git history it keeps the number
# from CURRENT_PROJECT_VERSION and warns.
plist="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

if [ "$(git -C "$SRCROOT" rev-parse --is-shallow-repository 2>/dev/null)" != false ]; then
  echo "warning: no full git history here, so the build number stays $CURRENT_PROJECT_VERSION"
  exit 0
fi

count=$(git -C "$SRCROOT" rev-list --count HEAD 2>/dev/null)
case $count in
  '' | *[!0-9]*)
    echo "warning: git could not count the commits, so the build number stays $CURRENT_PROJECT_VERSION"
    exit 0
    ;;
esac

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $count" "$plist"
