#!/bin/zsh
set -euo pipefail

app_path="${1:?usage: sign-mac.sh /path/to/App.app}"
identity="24FDC9EFA4EA3BCA978CC6DF0D6249416BF80DED"

codesign --force --deep --options runtime --timestamp --sign "$identity" "$app_path"
codesign --verify --deep --strict --verbose=4 "$app_path"
