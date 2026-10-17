#!/usr/bin/env bash
# Bir Codex işini (bir brif) ayrıca iş qovluğunda işə salır.
#
#   design/map_art/run_codex.sh <iş_adı> <brif.md> <attach1> [attach2 ...] [-- ref3 ref4 ...]
#
# Repo kökündən işə sal (yollar repo-nisbidir).
# - İş qovluğu: build/codex/<iş_adı>/ (git-də saxlanılmır). İçinə STYLE_MAP.md,
#   verify.ps1, resize.ps1, bütün şablonlar (ref/template_*.png) və verilən
#   istinadlar (ref/) köçürülür; Codex yalnız orada işləyir, nəticə out/-a düşür.
# - "--"-dan ƏVVƏLKİ fayllar həm ref/-ə köçür, həm -i ilə Codex-ə göstərilir;
#   SONRAKILAR yalnız ref/-ə köçür (image_gen onları yolla götürə bilər).
#   image_gen bir çağırışda ən çox 5 istinad şəkli qəbul edir — -i siyahısını
#   qısa saxla.
# - Model və səy menu_art ilə eynidir: gpt-6-astra, reasoning effort max.
# - Codex WMI (Win32_Process.Create) ilə AYRI prosesdə başlayır və skript dərhal
#   çıxır. Səbəb: bir iş 30–90 dəqiqə çəkir, Claude Code-un fon əmrləri isə vaxt
#   həddində öldürülür; Start-Process isə çağıranın çıxış borusunu uşağa ötürürdü
#   və skript Codex bitənə qədər asılı qalırdı. Codex irəliləyişi stderr-ə
#   (codex.err), son cavabı stdout-a (codex.log) yazır; cmd-nin PID-i codex.pid-də.
# - Eyni adlı köhnə iş qovluğu varsa, <ad>.prev-<vaxt> adı ilə kənara qoyulur:
#   yarımçıq qalmış işin (məs. limitə düşmüş) köhnə out/ faylları yenisinə qarışmasın.
# - Bu skripti İŞLƏYƏN nüsxəsi olanda redaktə ETMƏ: bash skripti hissə-hissə
#   oxuyur və dəyişmiş faylın ortasından davam edir.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
NAME="$1"; BRIEF="$2"; shift 2
WORK="$ROOT/build/codex/$NAME"

# Bütün girişlər ƏVVƏLCƏDƏN yoxlanılır — yarımçıq qovluq qalmasın.
for f in "$BRIEF" "$@"; do
  [ "$f" = "--" ] && continue
  if [ ! -f "$f" ]; then echo "[run_codex] missing input: $f" >&2; exit 1; fi
  case "$(basename "$f")" in
    *" "*|*\"*|*\'*) echo "[run_codex] file name with a space or quote: $f" >&2; exit 1 ;;
  esac
done
if [ -e "$WORK" ]; then
  mv "$WORK" "$WORK.prev-$(date +%Y%m%d-%H%M%S)"
fi

mkdir -p "$WORK/ref" "$WORK/out/rejected"
cp "$ROOT/design/map_art/brief/STYLE_MAP.md" "$WORK/"
cp "$ROOT/design/map_art/verify.ps1" "$ROOT/design/map_art/resize.ps1" "$WORK/"
cp "$ROOT/design/map_art/templates/"*.png "$WORK/ref/"
cp "$BRIEF" "$WORK/BRIEF.md"
ARGS="exec --skip-git-repo-check -s workspace-write -m gpt-6-astra -c model_reasoning_effort=max"
only_ref=0
for f in "$@"; do
  if [ "$f" = "--" ]; then only_ref=1; continue; fi
  cp "$f" "$WORK/ref/"
  if [ $only_ref -eq 0 ]; then ARGS="$ARGS -i ref/$(basename "$f")"; fi
done
WIN_WORK="$(cygpath -w "$WORK")"
# CODEX_CMD mühitdən verilə bilər — test üçün saxta codex (limit/pul xərcləmədən).
CODEX_CMD="${CODEX_CMD:-$(cygpath -w "$APPDATA/npm/codex.cmd" 2>/dev/null || echo codex.cmd)}"
echo "[run_codex] $NAME: $(date) args=$ARGS" > "$WORK/codex.start"
powershell -NoProfile -Command "\$r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create \
  -Arguments @{ CommandLine = 'cmd /c \"\"$CODEX_CMD\" $ARGS < BRIEF.md > codex.log 2> codex.err\"'; \
  CurrentDirectory = '$WIN_WORK' }; \$r.ProcessId" < /dev/null | tr -d '\r' > "$WORK/codex.pid"
echo "[run_codex] $NAME started, cmd pid $(cat "$WORK/codex.pid"), progress in $WORK/codex.err"
