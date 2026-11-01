#!/bin/sh
# Takes the App Store screenshots on the iPhone 18 Pro Max (6.9") and iPad Pro 13-inch (M5)
# simulators, in light mode at 9:41 with a full status bar. Each screen opens through the Debug
# build's -screenshot launch argument (DayByDay/Screenshots/ScreenshotScene.swift) on a demo
# child. The 6.3" set is resized from the 6.9" one; every PNG is flattened to RGB.
# Usage: scripts/take-screenshots.sh [scene ...]   (default: every scene, in App Store order)
# TEXT_SIZE=accessibility-extra-extra-extra-large (any simctl content_size) shoots at that text
# size into AppStore/screenshots-<size> instead.
set -eu

cd "$(dirname "$0")/.."
all="home routine animals train trace counting calendar progress"
scenes="${*:-$all}"
size="${TEXT_SIZE:-}"
out=AppStore/screenshots${size:+-$size}
derived=.build/screenshots
app="$derived/Build/Products/Debug-iphonesimulator/DayByDay.app"
bundle=net.cleberg.DayByDay

xcodebuild build -project DayByDay.xcodeproj -scheme DayByDay -configuration Debug \
    -destination 'generic/platform=iOS Simulator' -derivedDataPath "$derived" -quiet

udid() {
    xcrun simctl list devices available | grep -F "    $1 (" | head -1 | sed 's/.*(\([0-9A-F-]\{36\}\)).*/\1/'
}

flatten() {
    # Drops the alpha channel, which App Store Connect rejects.
    sips -s format jpeg -s formatOptions 100 "$1" --out "$1.jpg" >/dev/null
    sips -s format png "$1.jpg" --out "$1" >/dev/null
    rm "$1.jpg"
}

shoot() { # device name, output folder
    device="$(udid "$1")"
    [ -n "$device" ] || { echo "No simulator named $1." >&2; exit 1; }
    xcrun simctl boot "$device" 2>/dev/null || true
    xcrun simctl bootstatus "$device" -b >/dev/null
    xcrun simctl ui "$device" appearance light
    xcrun simctl ui "$device" content_size "${size:-large}"
    xcrun simctl install "$device" "$app"
    mkdir -p "$out/$2"
    for scene in $scenes; do
        n="$(printf '%s\n' "$all" | tr ' ' '\n' | grep -nx "$scene" | cut -d: -f1)"
        [ -n "$n" ] || { echo "Unknown scene $scene; one of: $all" >&2; exit 1; }
        xcrun simctl terminate "$device" "$bundle" 2>/dev/null || true
        # Set per launch: changing content_size restarts the status bar and drops the override.
        xcrun simctl status_bar "$device" override --time 9:41 --dataNetwork wifi --wifiMode active \
            --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
        xcrun simctl launch "$device" "$bundle" -screenshot "$scene" >/dev/null
        file="$out/$2/$(printf %02d "$n")-$scene.png"
        # A screen that has not drawn yet is blank white, which compresses to a few KB.
        tries=0
        while :; do
            sleep 3
            xcrun simctl io "$device" screenshot "$file" >/dev/null 2>&1
            [ "$(stat -f%z "$file")" -gt 100000 ] && break
            tries=$((tries + 1))
            [ "$tries" -lt 10 ] || { echo "$scene stayed blank on $1." >&2; exit 1; }
        done
        flatten "$file"
        echo "$file"
    done
    xcrun simctl terminate "$device" "$bundle" 2>/dev/null || true
    xcrun simctl status_bar "$device" clear
    xcrun simctl ui "$device" content_size large
}

shoot "iPhone 18 Pro Max" iphone-6.9
shoot "iPad Pro 13-inch (M5)" ipad

mkdir -p "$out/iphone-6.3"
for file in "$out"/iphone-6.9/*.png; do
    sips -z 2622 1206 "$file" --out "$out/iphone-6.3/$(basename "$file")" >/dev/null
done
