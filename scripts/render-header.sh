#!/bin/sh
# Renders AppStore/header.html to the 21:9 (3840x1646) and 16:9 (5244x2950) App Store
# product page headers with headless Chromium, then removes the alpha channel.
# Needs Chromium.app and ImageMagick. Usage: scripts/render-header.sh
set -eu

cd "$(dirname "$0")/../AppStore"
chromium=/Applications/Chromium.app/Contents/MacOS/Chromium
"$chromium" --headless --hide-scrollbars --force-device-scale-factor=1 --window-size=3840,1646 \
    --screenshot=header-21x9.png "file://$PWD/header.html" 2>/dev/null
"$chromium" --headless --hide-scrollbars --force-device-scale-factor=1 --window-size=5244,2950 \
    --screenshot=header-16x9.png "file://$PWD/header.html#wide" 2>/dev/null
for f in header-21x9.png header-16x9.png; do
    magick "$f" -alpha off "PNG24:$f"
done
