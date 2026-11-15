#!/bin/bash
# Vantagram: Telegram's bundled fake provisioning profiles expire; re-sign copies of them
# with a far-future ExpirationDate so rules_apple accepts them.
# Usage: vantagram-refresh-profiles.sh <source fake-codesigning dir> <output dir>
set -euo pipefail

SRC="$1"
OUT="$2"
WORK="${VANTAGRAM_WORK:-$(mktemp -d)}"
mkdir -p "$WORK"

rm -rf "$OUT"
mkdir -p "$OUT/profiles" "$OUT/certs"
cp "$SRC"/certs/* "$OUT/certs/"

openssl req -x509 -newkey rsa:2048 -nodes -keyout "$WORK/key.pem" -out "$WORK/cert.pem" \
  -subj "/CN=Vantagram Fake Signer" -days 3650 >/dev/null 2>&1

for f in "$SRC"/profiles/*.mobileprovision; do
  name="$(basename "$f")"
  openssl smime -verify -noverify -inform der -in "$f" -out "$WORK/orig.plist" >/dev/null 2>&1
  perl -0pe 's#(<key>ExpirationDate</key>\s*<date>)[^<]*#${1}2030-10-01T00:00:00Z#' "$WORK/orig.plist" > "$WORK/patched.plist"
  if ! grep -q "2030-10-01T00:00:00Z" "$WORK/patched.plist"; then
    echo "ExpirationDate patch failed for $name" >&2
    exit 1
  fi
  openssl smime -sign -signer "$WORK/cert.pem" -inkey "$WORK/key.pem" -binary \
    -in "$WORK/patched.plist" -outform der -nodetach -out "$OUT/profiles/$name"
  # sanity check: Make.py reads profiles exactly like this
  openssl smime -verify -noverify -inform der -in "$OUT/profiles/$name" -out "$WORK/check.plist" >/dev/null 2>&1
  grep -q "2030-10-01T00:00:00Z" "$WORK/check.plist"
  echo "refreshed $name"
done

rm -rf "$WORK"
