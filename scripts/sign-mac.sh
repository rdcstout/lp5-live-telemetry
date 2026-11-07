#!/bin/zsh
set -euo pipefail

app_path="${1:?usage: sign-mac.sh /path/to/App.app}"
identity="24FDC9EFA4EA3BCA978CC6DF0D6249416BF80DED"
entitlements="$(cd "$(dirname "$0")/.." && pwd)/node_modules/app-builder-lib/templates/entitlements.mac.plist"

# Electron ships several linker-signed Mach-O files inside its frameworks.
# Sign every leaf first, then nested bundles, then the outer app so none of the
# ad-hoc/linker signatures survive into the notarization candidate.
while IFS= read -r -d '' item; do
  if /usr/bin/file -b "$item" | /usr/bin/grep -q 'Mach-O'; then
    codesign --force --options runtime --timestamp --entitlements "$entitlements" --sign "$identity" "$item"
  fi
done < <(/usr/bin/find "$app_path" -type f -print0)

while IFS= read -r -d '' bundle; do
  [[ "$bundle" == "$app_path" ]] && continue
  codesign --force --options runtime --timestamp --entitlements "$entitlements" --sign "$identity" "$bundle"
done < <(/usr/bin/find "$app_path" -depth -type d \( -name '*.framework' -o -name '*.app' -o -name '*.xpc' \) -print0)

codesign --force --options runtime --timestamp --entitlements "$entitlements" --sign "$identity" "$app_path"
codesign --verify --deep --strict --verbose=4 "$app_path"
