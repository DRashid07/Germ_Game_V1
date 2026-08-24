#!/usr/bin/env bash
# Oyun serverinin sağ olub-olmadığını yoxlayır.
#
#   bash tools/check_server.sh                      # Railway serveri
#   bash tools/check_server.sh ws://127.0.0.1:27015 # lokal server
#
# NƏ ÜÇÜN LAZIMDIR: server veb sayt deyil, ona görə brauzerdə açanda
# "502 Application failed to respond" görünür. Bu NORMALDIR — server yalnız
# WebSocket dilində danışır, brauzerin adi HTTP sorğusuna cavab vermir.
# Bu skript oyunun etdiyi kimi WebSocket əl sıxması göndərir və əsl vəziyyəti deyir.
set -uo pipefail

URL="${1:-wss://germ-arena-production.up.railway.app}"

# curl HTTP sxemi gözləyir, ona görə ws→http, wss→https çeviririk.
HTTP_URL="${URL/#wss:/https:}"
HTTP_URL="${HTTP_URL/#ws:/http:}"

echo "Yoxlanılır: $URL"
echo

RESPONSE=$(curl -s -i -m 20 -N \
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

if grep -qE "502|Application failed to respond" <<<"$RESPONSE"; then
  echo "❌ SERVER CAVAB VERMİR"
  echo "   WebSocket əl sıxmasına da 502 gəldi — deməli tətbiq həqiqətən düşüb."
  echo "   Logları yoxla:  railway logs --service germ-arena"
  exit 1
fi

echo "⚠️  GÖZLƏNİLMƏYƏN CAVAB"
echo "$RESPONSE" | head -12
exit 2
