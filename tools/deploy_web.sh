#!/usr/bin/env bash
# Brauzer versiyasını yenidən qurub Railway-ə göndərir.
#
#   bash tools/deploy_web.sh
#
# İki addım edir:
#   1) Godot ilə "Web" presetini `web/public/` qovluğuna ixrac edir
#   2) `web/` qovluğunu `germ-arena-web` servisinə deploy edir
#
# Oyun serveri AYRI servisdir (`germ-arena`) — bu skript ona toxunmur,
# onun üçün tools/deploy_server.sh var.
set -euo pipefail

GODOT="${GODOT:-/c/Users/User/Godot/Godot_v4.7.2-stable_win64_console.exe}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# `railway up` layihə bağlantısını cari qovluqdan oxuyur, biz isə `web/` içindən
# işə salırıq — ona görə layihə və mühit açıq şəkildə ötürülür.
# Layihə id-si `railway status` ilə görünür; ilk deploydan əvvəl `railway link` lazımdır.
PROJECT_ID="${RAILWAY_PROJECT_ID:-}"
ENVIRONMENT="${RAILWAY_ENVIRONMENT:-production}"
SERVICE="${RAILWAY_WEB_SERVICE:-germ-arena-web}"

if [ -z "$PROJECT_ID" ]; then
  echo "XƏTA: RAILWAY_PROJECT_ID təyin olunmayıb." >&2
  echo "  railway status   → layihə id-sini göstərir" >&2
  echo "  RAILWAY_PROJECT_ID=<id> bash tools/deploy_web.sh" >&2
  exit 1
fi

echo "1/2  Web build ixrac olunur..."
mkdir -p "$ROOT/web/public"
"$GODOT" --headless --path "$ROOT/game" \
         --export-release "Web" "$ROOT/web/public/index.html"

echo
echo "2/2  Railway-ə göndərilir (servis: $SERVICE)..."
cd "$ROOT/web"
railway up --ci -y -p "$PROJECT_ID" -e "$ENVIRONMENT" -s "$SERVICE"

echo
echo "Hazırdır: https://germ-arena-web-production.up.railway.app"
