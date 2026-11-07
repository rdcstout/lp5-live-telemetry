#!/bin/zsh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
version="$(node -p "require('$root/package.json').version")"
dmg="$root/dist/LP5 Live Telemetry-$version-arm64.dmg"
identity="24FDC9EFA4EA3BCA978CC6DF0D6249416BF80DED"

codesign --force --timestamp --sign "$identity" "$dmg"
codesign --verify --verbose=4 "$dmg"
