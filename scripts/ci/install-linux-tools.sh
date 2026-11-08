#!/bin/sh
# Installs the pinned lint tools on a Linux x64 runner. The hosted image has no SwiftLint and an older SwiftFormat.
set -eu

# Only the download is retried. The pinned hash is checked once, on the bytes of the try that exited 0.
fetch() {
  url=$1 sha=$2 out=$3
  tries=0
  until curl -fsSL "$url" -o "$tmp/$out"; do
    tries=$((tries + 1))
    if [ "$tries" = 4 ]; then
      echo "fetch: giving up on $url after 4 tries" >&2
      return 1
    fi
    sleep "${FETCH_PAUSE_SECONDS:-5}"
  done
  echo "$sha  $tmp/$out" | sha256sum -c -
}

main() {
  bin="${HOME}/.local/bin"
  tmp=$(mktemp -d)
  mkdir -p "$bin"

  fetch https://github.com/realm/SwiftLint/releases/download/0.65.1/swiftlint_linux_amd64.zip \
    caeed6f4a679c35539ffaf124f6c4ab4a8416917f7d8796279dc52b74026059d swiftlint.zip
  fetch https://github.com/nicklockwood/SwiftFormat/releases/download/0.64.3/swiftformat_linux.zip \
    45fe2d2fed940c6d7cf403fbf21bbb7645f0f5f2dd01e179fbb46c450cadc205 swiftformat.zip

  unzip -oq "$tmp/swiftlint.zip" -d "$tmp/swiftlint"
  unzip -oq "$tmp/swiftformat.zip" -d "$tmp/swiftformat"
  install "$tmp/swiftlint/swiftlint-static" "$bin/swiftlint"
  install "$tmp/swiftformat/swiftformat_linux" "$bin/swiftformat"
  pip install --user lizard==1.24.3
  echo "$bin" >> "${GITHUB_PATH:-/dev/null}"
}

case ${0##*/} in
  install-linux-tools.sh) main ;;
esac
