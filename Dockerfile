# Germ Arena — hədəf server (Railway / istənilən Docker hostinqi)
#
# Godot-un Linux "dedicated server" ixracı tək fayla yığılıb (PCK daxildir),
# ona görə burada quraşdırma yoxdur — sadəcə binarı kopyalayıb işə salırıq.
#
# Binarı əvvəlcədən hazırlamaq lazımdır:
#   godot --headless --path game --export-release "Linux Server" \
#         build/server/germ_arena_server.x86_64

FROM debian:bookworm-slim

# Godot headless rejimdə şrift və şəbəkə üçün bu kitabxanaları istəyir.
RUN apt-get update && apt-get install -y --no-install-recommends \
        libfontconfig1 \
        libfreetype6 \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY build/server/germ_arena_server.x86_64 /app/germ_arena_server
RUN chmod +x /app/germ_arena_server

# Railway portu `PORT` mühit dəyişəni ilə verir; yoxdursa lokal standart port.
ENV PORT=27015
EXPOSE 27015

# `PORT` təyin olunubsa server avtomatik WebSocket-ə keçir (Railway UDP vermir).
# `stdbuf` olmadan Godot-un stdout-u buferlənir və Railway loglarında heç nə görünmür.
CMD ["stdbuf", "-o0", "-e0", "/app/germ_arena_server", "--headless", "--", "--server", "--verbose"]
