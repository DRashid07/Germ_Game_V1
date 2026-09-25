#!/usr/bin/env bash
# Oyun serverinin sağ olub-olmadığını yoxlayır.
#
#   bash tools/check_server.sh                         # Render serveri
#   bash tools/check_server.sh ws://127.0.0.1:27015    # lokal server
#   bash tools/check_server.sh ws://127.0.0.1:10000/ws # lokal Render konteyneri
#
# Oyunun etdiyi kimi WebSocket əl sıxması göndərir və əsl vəziyyəti deyir.
# Server özü veb sayt deyil — adi HTTP sorğusuna cavab vermir. Render-də sayt
# `/`-dədir, server isə `/ws`-də (bax deploy/render/).
set -uo pipefail

URL="${1:-wss://germ-arena.onrender.com/ws}"

# curl HTTP sxemi gözləyir, ona görə ws→http, wss→https çeviririk.
HTTP_URL="${URL/#wss:/https:}"
HTTP_URL="${HTTP_URL/#ws:/http:}"

echo "Yoxlanılır: $URL"
echo

# 90 s: Render-in pulsuz planında yatmış servis ~1 dəqiqəyə oyanır və sorğu
# o vaxta qədər gözlədilir. Qısa hədd oyanan serveri "ölü" göstərərdi.
RESPONSE=$(curl -s -i -m 90 -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  "$HTTP_URL" 2>&1 | head -c 2000)

if grep -qi "101 Switching Protocols" <<<"$RESPONSE"; then
  echo "✅ SERVER İŞLƏYİR"
  echo "   WebSocket əl sıxması qəbul edildi (101 Switching Protocols)."
  echo "   Oyunun menyusunda bu ünvanı yazıb oynaya bilərsən."
  exit 0
fi

if grep -qE "^HTTP/[0-9.]+ (502|503|404)" <<<"$RESPONSE"; then
  echo "❌ SERVER CAVAB VERMİR"
  echo "$RESPONSE" | head -1
  echo "   Logları yoxla:  render logs --resources <srv-id> --tail"
  exit 1
fi

echo "⚠️  GÖZLƏNİLMƏYƏN CAVAB"
echo "$RESPONSE" | head -12
exit 2
