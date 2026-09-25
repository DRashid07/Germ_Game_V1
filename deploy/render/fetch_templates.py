#!/usr/bin/env python3
"""Godot ixrac şablonlarından YALNIZ lazım olan faylları yükləyir.

Rəsmi `.tpz` arxivi 1.28 GB-dır və bütün platformaları daşıyır, Render build-i
isə ondan cəmi iki fayl istəyir (web + Linux server). `.tpz` adi zip-dir və
mündəricatı faylın SONUNDADIR, ona görə HTTP Range sorğuları ilə əvvəl
mündəricatı, sonra yalnız lazım olan faylların baytlarını oxuyuruq.
Hər faylın CRC-sini `zipfile` özü yoxlayır — kəsik yükləmə build-i dayandırır.

    python3 fetch_templates.py 4.7.2 web_nothreads_release.zip linux_release.x86_64
"""
import io
import os
import re
import shutil
import sys
import urllib.request

import zipfile

## Bir Range sorğusunun ölçüsü. Kiçik olsa yüzlərlə sorğu gedir.
CHUNK = 16 * 1024 * 1024


class RangeFile(io.RawIOBase):
    """Uzaq faylı `seek`/`read` edilə bilən lokal fayl kimi göstərir.

    Hər sorğu ORİJİNAL ünvana gedir: GitHub onu müddətli imzalı ünvana
    yönləndirir və o ünvan bir neçə dəqiqəyə köhnəlir.
    """

    def __init__(self, url: str) -> None:
        self.url = url
        self.pos = 0
        with self._get(0, 0) as r:
            # "bytes 0-0/1281349702"
            self.size = int(re.search(r"/(\d+)$", r.headers["Content-Range"]).group(1))

    def _get(self, start: int, end: int):
        req = urllib.request.Request(self.url, headers={"Range": "bytes=%d-%d" % (start, end)})
        r = urllib.request.urlopen(req, timeout=120)
        if r.status != 206:
            r.close()
            raise IOError("server Range sorğusunu dəstəkləmir (HTTP %d)" % r.status)
        return r

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self.pos

    def seek(self, offset: int, whence: int = io.SEEK_SET) -> int:
        base = {io.SEEK_SET: 0, io.SEEK_CUR: self.pos, io.SEEK_END: self.size}[whence]
        self.pos = base + offset
        return self.pos

    def readinto(self, buf) -> int:
        n = min(len(buf), self.size - self.pos)
        if n <= 0:
            return 0
        with self._get(self.pos, self.pos + n - 1) as r:
            data = r.read()
        buf[: len(data)] = data
        self.pos += len(data)
        return len(data)


def main() -> None:
    version, names = sys.argv[1], sys.argv[2:]
    url = (
        "https://github.com/godotengine/godot/releases/download/"
        "%s-stable/Godot_v%s-stable_export_templates.tpz" % (version, version)
    )
    dest = os.path.expanduser("~/.local/share/godot/export_templates/%s.stable" % version)
    os.makedirs(dest, exist_ok=True)

    remote = io.BufferedReader(RangeFile(url), buffer_size=CHUNK)
    with zipfile.ZipFile(remote) as tpz:
        for name in names + ["version.txt"]:
            with tpz.open("templates/" + name) as src, open(os.path.join(dest, name), "wb") as dst:
                shutil.copyfileobj(src, dst, CHUNK)
            print("[templates] %s  %d bayt" % (name, os.path.getsize(os.path.join(dest, name))))


if __name__ == "__main__":
    main()
