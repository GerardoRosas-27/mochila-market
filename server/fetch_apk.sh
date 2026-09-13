#!/bin/sh
set -eu
mkdir -p downloads
NOTES="$(dirname "$0")/install_notes"
TAGGED_NEW="https://github.com/GerardoRosas-27/mochila-market/releases/download/v1.3.0-mobile/MochilaMarket.apk"
LATEST="https://github.com/GerardoRosas-27/mochila-market/releases/latest/download/MochilaMarket.apk"
TAGGED_OLD="https://github.com/GerardoRosas-27/mochila-market/releases/download/v1.2.0-mobile/MochilaMarket.apk"
TAGGED_OLDER="https://github.com/GerardoRosas-27/mochila-market/releases/download/v1.1.0-mobile/MochilaMarket.apk"
echo Fetching_APK
if ! curl -fL --retry 3 --retry-delay 2 -o downloads/mochila-market.apk "$TAGGED_NEW"; then
  echo fallback_latest
  if ! curl -fL --retry 3 --retry-delay 2 -o downloads/mochila-market.apk "$LATEST"; then
    echo fallback_v1_1_0
    if ! curl -fL --retry 3 --retry-delay 2 -o downloads/mochila-market.apk "$TAGGED_OLD"; then
      echo fallback_v1_0_0
      curl -fL --retry 3 --retry-delay 2 -o downloads/mochila-market.apk "$TAGGED_OLDER"
    fi
  fi
fi
test -s downloads/mochila-market.apk
ls -lh downloads/mochila-market.apk
TMP_A=$(mktemp -d)
cp downloads/mochila-market.apk "$TMP_A/mochila-market.apk"
cp "$NOTES/INSTALL_ANDROID.txt" "$TMP_A/INSTALL_ANDROID.txt"
(cd "$TMP_A" && zip -q -r /app/downloads/mochila-market-android.zip mochila-market.apk INSTALL_ANDROID.txt)
rm -rf "$TMP_A"
ls -lh downloads/mochila-market-android.zip
TMP_I=$(mktemp -d)
cp "$NOTES/INSTALL_IOS.txt" "$TMP_I/INSTALL_IOS.txt"
(cd "$TMP_I" && zip -q -r /app/downloads/mochila-market-ios.zip INSTALL_IOS.txt)
rm -rf "$TMP_I"
ls -lh downloads/mochila-market-ios.zip
