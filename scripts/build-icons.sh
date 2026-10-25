#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h:h}"
asset_dir="$project_dir/assets"
source_svg="$asset_dir/app-icon.svg"
base_png="$asset_dir/icon-1024.png"
iconset="$asset_dir/AppIcon.iconset"

mkdir -p "$asset_dir"
rm -rf "$iconset"
mkdir -p "$iconset"

qlmanage -t -s 1024 -o "$asset_dir" "$source_svg" >/dev/null 2>&1
mv "$asset_dir/app-icon.svg.png" "$base_png"

for spec in "16 icon_16x16.png" "32 icon_16x16@2x.png" "32 icon_32x32.png" "64 icon_32x32@2x.png" "128 icon_128x128.png" "256 icon_128x128@2x.png" "256 icon_256x256.png" "512 icon_256x256@2x.png" "512 icon_512x512.png" "1024 icon_512x512@2x.png"; do
  size="${spec%% *}"
  name="${spec#* }"
  sips -z "$size" "$size" "$base_png" --out "$iconset/$name" >/dev/null
done

iconutil -c icns "$iconset" -o "$asset_dir/icon.icns"

python3 "$project_dir/scripts/make-ico.py" "$asset_dir/icon.ico" \
  "$iconset/icon_16x16.png" \
  "$iconset/icon_32x32.png" \
  "$iconset/icon_128x128.png" \
  "$iconset/icon_256x256.png"
