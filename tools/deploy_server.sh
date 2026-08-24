#!/usr/bin/env bash
# Oyun serverini yenidən qurub Railway-ə göndərir.
#
#   bash tools/deploy_server.sh
#
# İki addım edir:
#   1) Linux server binarını `build/server/` qovluğuna ixrac edir
#   2) Kök qovluğu `germ-arena` servisinə deploy edir (Dockerfile binarı götürür)
#
# Brauzer versiyası AYRI servisdir — bax: tools/deploy_web.sh
set -euo pipefail

GODOT="${GODOT:-/c/Users/User/Godot/Godot_v4.7.2-stable_win64_console.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE="${RAILWAY_SERVICE:-germ-arena}"

echo "1/2  Linux server binarı ixrac olunur..."
mkdir -p "$ROOT/build/server"
"$GODOT" --headless --path "$ROOT/game" \
         --export-release "Linux Server" "$ROOT/build/server/germ_arena_server.x86_64"

echo
echo "2/2  Railway-ə göndərilir (servis: $SERVICE)..."
cd "$ROOT"
railway up --ci -y --service "$SERVICE"

echo
echo "Hazırdır. Yoxla:  bash tools/check_server.sh"
