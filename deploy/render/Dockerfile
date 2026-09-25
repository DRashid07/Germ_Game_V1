# Germ Arena — Render-də TƏK servis: brauzer oyunu + oyun serveri bir konteynerdə.
#
#   https://<servis>.onrender.com/     brauzer versiyası (nginx, statik fayllar)
#   wss://<servis>.onrender.com/ws     oyun serveri (nginx → 127.0.0.1:27015)
#
# Niyə bir servis: pulsuz planda hər servis 15 dəqiqə boş qalanda yatır. İki servis
# olsaydı oyunçu əvvəl saytın, sonra serverin oyanmasını gözləyərdi. Həm də domen
# eyni olduğuna görə brauzer build-i server ünvanını səhifənin öz ünvanından
# götürür (bax `Const.default_server`) — ünvanı build-ə yazmaq lazım deyil.
#
# Hər şey MƏNBƏDƏN qurulur: Godot və lazımi ixrac şablonları burada yüklənir,
# ona görə repoda hazır binar saxlamaq lazım deyil. Kontekst repo köküdür:
#   docker build -f deploy/render/Dockerfile -t germ-arena .

ARG GODOT_VERSION=4.7.2

# ---------- 1) Godot ilə ixrac ----------
FROM debian:bookworm-slim AS export
ARG GODOT_VERSION

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl unzip python3 libfontconfig1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/godot
RUN set -eu; \
    base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"; \
    zip="Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"; \
    curl -fsSLO "$base/$zip"; \
    curl -fsSL "$base/SHA512-SUMS.txt" | grep " $zip\$" | sha512sum -c -; \
    unzip -q "$zip"; \
    mv "Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot; \
    rm "$zip"

# Tam şablon arxivi 1.28 GB-dır — skript ondan yalnız bu iki faylı çəkir.
COPY deploy/render/fetch_templates.py .
RUN python3 fetch_templates.py "${GODOT_VERSION}" web_nothreads_release.zip linux_release.x86_64

WORKDIR /src
COPY game/ game/
# Təmiz klonda idxal keşi (.godot/) yoxdur. Ayrı `--import` keçidi olmasa ixrac
# qlobal sinifləri (class_name) hələ tanımaya bilər.
RUN godot --headless --path game --import
RUN mkdir -p /out/web /out/server \
 && godot --headless --path game --export-release "Web" /out/web/index.html \
 && godot --headless --path game --export-release "Linux Server" /out/server/germ_arena_server.x86_64 \
 && test -s /out/web/index.wasm \
 && test -s /out/server/germ_arena_server.x86_64

# ---------- 2) İşləyən konteyner ----------
# nginx-in Debian obrazı (alpine yox): Godot binarı glibc istəyir.
FROM nginx:1.28-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        libfontconfig1 libfreetype6 \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/conf.d/default.conf /usr/share/nginx/html/*

COPY --from=export /out/server/germ_arena_server.x86_64 /app/germ_arena_server
COPY --from=export /out/web/ /usr/share/nginx/html/

# wasm sıxılmamış ~39 MB-dır, gzip-dən sonra ~10 MB. Bir dəfə burada sıxılır,
# `gzip_static` isə hər sorğuda hazır .gz faylını verir.
RUN find /usr/share/nginx/html -type f \
        \( -name '*.wasm' -o -name '*.js' -o -name '*.pck' -o -name '*.html' \) \
        -exec gzip -9 -k {} \;

COPY deploy/render/nginx.conf.template /etc/nginx/germ-arena.conf.template
COPY deploy/render/start.sh /start.sh
RUN chmod +x /app/germ_arena_server /start.sh

# Render portu `PORT` ilə verir (standart 10000); lokal sınaq üçün eyni dəyər.
ENV PORT=10000
EXPOSE 10000
# nginx obrazının öz girişi (/docker-entrypoint.sh) yalnız nginx-i qaldırır —
# oyun serveri üçün start.sh onu əvəz edir. Obraz STOPSIGNAL-ı SIGQUIT qoyur,
# start.sh isə TERM gözləyir — geri qaytarılmasa dayanma 30 s-lik SIGKILL-ə qalır.
STOPSIGNAL SIGTERM
ENTRYPOINT ["/start.sh"]
