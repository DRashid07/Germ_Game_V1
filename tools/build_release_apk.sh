#!/usr/bin/env bash
# Play Store üçün imzalanmış release APK qurur.
#
# İmza açarı QƏSDƏN repodan kənardadır — bu sirdir və git-ə düşməməlidir.
# Godot açarı mühit dəyişənlərindən oxuyur, ona görə parol heç bir fayla yazılmır.
#
#   bash tools/build_release_apk.sh
set -euo pipefail

GODOT="${GODOT:-/c/Users/User/Godot/Godot_v4.7.2-stable_win64_console.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_ENV="${GERM_ARENA_KEY_ENV:-/c/Users/User/.keystores/germ_arena_release.env}"

if [ ! -f "$KEY_ENV" ]; then
  echo "XƏTA: imza açarının məlumat faylı tapılmadı: $KEY_ENV" >&2
  echo "Yeni açar yaratmaq üçün README.md-dəki 'Release imzası' bölməsinə bax." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$KEY_ENV"

export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$GERM_ARENA_KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$GERM_ARENA_KEYSTORE_USER"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$GERM_ARENA_KEYSTORE_PASSWORD"

mkdir -p "$ROOT/build"
OUT="$ROOT/build/GermArena-release.apk"

echo "Release APK qurulur (yalnız arm64-v8a)..."
"$GODOT" --headless --path "$ROOT/game" \
         --export-release "Android Release" "$OUT"

echo
echo "Hazırdır: $OUT"
ls -lh "$OUT"
