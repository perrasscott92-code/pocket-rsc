#!/data/data/com.termux/files/usr/bin/bash
# install-termux.sh - installs the launcher, watchdog, and icon into Termux.
# Run from the root of this repo, inside Termux.
set -e
cd "$(dirname "$0")/.."
mkdir -p ~/.shortcuts/icons
cp scripts/RSC ~/.shortcuts/RSC
cp scripts/RSC-Stop ~/.shortcuts/RSC-Stop
cp scripts/rsc-watch.sh ~/rsc-watch.sh
cp assets/RSC.png ~/.shortcuts/icons/RSC.png
chmod +x ~/.shortcuts/RSC ~/.shortcuts/RSC-Stop ~/rsc-watch.sh
echo "Installed. Add the Termux:Widget shortcut widget to your home screen and pick RSC."
echo "Also enable Settings > Apps > Termux > Display over other apps."
