# Germ Arena — brauzer versiyasını verən statik host.
#
# Konteynerə YALNIZ hazır web build-i düşür. Build-i əvvəlcədən Godot ilə çıxarmaq lazımdır:
#   godot --headless --path game --export-release "Web" web/public/index.html
#
# Bu, oyun serveri DEYİL. Oyun `germ-arena` servisindəki WebSocket serverinə qoşulur.

FROM nginx:1.27-alpine

COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY public/ /usr/share/nginx/html/

# Godot-un wasm-ı sıxılmamış 39 MB-dır, gzip sonrası ~10 MB.
# Sıxma burada bir dəfə edilir; `gzip_static on` isə hazır .gz faylını verir.
RUN set -eu; \
    find /usr/share/nginx/html -type f \
        \( -name '*.wasm' -o -name '*.js' -o -name '*.pck' -o -name '*.html' \) \
        | while read -r f; do gzip -9 -c "$f" > "$f.gz"; done

# Railway `PORT` dəyişənini özü verir; lokal sınaq üçün standart dəyər.
ENV PORT=8080
EXPOSE 8080
