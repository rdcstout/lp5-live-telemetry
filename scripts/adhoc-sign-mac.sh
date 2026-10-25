#!/bin/zsh
set -euo pipefail

app_path="${1:?Pass the path to the packaged macOS app}"
codesign --force --deep --sign - --timestamp=none "$app_path"
codesign --verify --deep --strict --verbose=4 "$app_path"
