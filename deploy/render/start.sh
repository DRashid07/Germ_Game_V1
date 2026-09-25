#!/bin/bash
# Germ Arena — Render konteynerinin girişi: oyun serveri + nginx.
#
# Render yalnız `PORT` portunu internetə açır. O portu nginx tutur: `/` brauzer
# build-ini verir, `/ws` isə içəridə 27015-də dinləyən oyun serverinə ötürülür.
set -euo pipefail

: "${PORT:=10000}"
envsubst '${PORT}' < /etc/nginx/germ-arena.conf.template > /etc/nginx/conf.d/default.conf

# Render dayandıranda (yeni deploy, yuxu) SIGTERM PID 1-ə gəlir və bash onu
# övladlara özü ötürmür. Proseslər başlamadan qurulur — arada siqnal itməsin.
trap 'kill -TERM $(jobs -p) 2>/dev/null; wait; exit 0' TERM INT

# `PORT` server üçün silinir: onu görsə həmin portu ÖZÜ tutmağa çalışardı
# (bax boot.gd `_start_server`) və nginx ilə toqquşardı.
# `stdbuf` olmasa Godot-un stdout-u buferlənir və Render loglarında heç nə görünmür.
# `--max-fps 60`: həddsiz headless dövr ~130 kadr/s fırlanır. 60-da CPU ~13%
# az yeyir və tick-lər bərabər düşür (ən uzun ara 31 ms; 30-da 48 ms idi).
env -u PORT stdbuf -o0 -e0 /app/germ_arena_server --headless --max-fps 60 \
    -- --server --ws --port 27015 --verbose &
nginx -g 'daemon off;' &

# Biri düşsə konteyner də düşür və Render onu yenidən qaldırır. Əks halda sayt
# açılar, oyun isə səssizcə qoşulmazdı.
wait -n
echo "[start] proses dayandı — konteyner yenidən başladılır" >&2
exit 1
