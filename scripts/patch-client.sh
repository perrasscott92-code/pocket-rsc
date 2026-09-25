#!/usr/bin/env bash
# patch-client.sh
# Patches the OpenRSC Android client so "Local Instance" defaults to
# 127.0.0.1:43602 when the IP and port boxes are left blank.
#
# Run inside the proot Ubuntu environment, in the folder holding openrsc.apk:
#   apt install -y apktool apksigner zipalign openjdk-21-jdk-headless
#   bash patch-client.sh openrsc.apk
#
# Output: openrsc-local.apk (uninstall the stock client before installing it,
# since the new signature differs).

set -e

IN="${1:-openrsc.apk}"
OUT="openrsc-local.apk"
KS="my.keystore"

[ -f "$IN" ] || { echo "APK not found: $IN" >&2; exit 1; }

echo "Decompiling $IN"
apktool d -f "$IN" -o orsc

echo "Patching Local Instance defaults"
FILES=$(grep -rl '"192.168.1.100"' orsc/smali* || true)
if [ -z "$FILES" ]; then
  echo "Default IP string not found; this client version may differ." >&2
  exit 1
fi
echo "$FILES" | xargs -d '\n' sed -i \
  's/"192\.168\.1\.100"/"127.0.0.1"/g; s/"43594"/"43602"/g'
grep -rn '"127.0.0.1"' orsc/smali* | head -5

echo "Rebuilding"
apktool b orsc -o unsigned.apk
zipalign -f 4 unsigned.apk aligned.apk

if [ ! -f "$KS" ]; then
  echo "Creating signing key ($KS). Keep it out of version control."
  keytool -genkey -keystore "$KS" -alias orsc -keyalg RSA -keysize 2048 \
    -validity 10000 -storepass android -keypass android -dname "CN=orsc"
fi

apksigner sign --ks "$KS" --ks-pass pass:android --out "$OUT" aligned.apk
rm -f unsigned.apk aligned.apk
ls -la "$OUT"
echo "Done. Install $OUT after uninstalling the stock OpenRSC client."
