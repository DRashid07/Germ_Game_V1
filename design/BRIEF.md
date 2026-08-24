# Dizayn brifi — Codex üçün

Hazırkı assetlər **müvəqqətidir**: oyunun işləməsi üçün lazım olan minimum.
Bu sənəd onları əvəz edəcək dizayner (Codex) üçün yazılıb — nə lazımdır,
hansı ölçüdə və hansı texniki məhdudiyyətlə.

Üslub və palitra: [ART_BIBLE.md](ART_BIBLE.md) · Səs: [AUDIO_BIBLE.md](AUDIO_BIBLE.md)

---

## Dəyişməz məhdudiyyətlər

Bunlar dizayn seçimi deyil, mühərrikin tələbidir:

1. **SVG-də `<text>` YOXDUR.** ThorVG mətn elementlərini sükutla atır.
   Yazı lazımdırsa ya `<path>` həndəsəsinə çevir, ya da kodda `Label` işlədilir.
2. **Rənglənəcək sprite-lar ağ-boz olmalıdır.** `shot_ball.svg` və `burst.svg`
   kodda `modulate` ilə mikrobun rənginə boyanır.
3. **Düymələrin içi tünd olmalıdır.** Mətn kodla üstünə yazılır (açıq rəngdə).
4. **Sprite-ın kənarında haşiyə üçün boşluq qalmalıdır** — miqyaslananda kəsilməsin.
5. **Mikrobun özü sprite ola bilməz.** Ölçüsü tutumla, içindəki topların sayı
   isə mövcud sayla dəyişir — kodla çəkilir (bax ART_BIBLE §2).

---

## Nə lazımdır

### A. Əvəz olunmalı sprite-lar

| Fayl | Ölçü | İndiki hal | Nə istənilir |
|---|---|---|---|
| `sprites/food_ball.svg` | 32² | sadə gradient top | canlı "qida" hissi: nüvə, işıq, bəlkə yüngül halo |
| `sprites/shot_ball.svg` | 36² | boz top | sürət hissi verən forma (uçuş izi sprite-ın içində ola bilər) |
| `sprites/mucus_blob.svg` | 256² | dairə + ləkələr | qeyri-müntəzəm, üzvi ləkə; radius 120 SABİT qalmalıdır |
| `sprites/spark.svg` | 64² | ağ ulduz | maye sıçraması |
| `sprites/burst.svg` | 256² | halqa + damcılar | membranın cırılması, daha dramatik |

### B. UI

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `ui/logo.svg` | 600×220 | Yazısız nişan. Yazı kodda `_make_logo()`-dadır; nişan sol tərəfdə ~200 px sahədə qalmalıdır |
| `ui/button_primary.svg` | 480×110 | Vurğulu düymə |
| `ui/button_secondary.svg` | 480×110 | Sönük düymə |
| `ui/joystick_base.svg` | 220² | Yarım şəffaf, barmağın altında qalır |
| `ui/joystick_knob.svg` | 96² | — |
| `ui/panel.svg` | 480×300 | Nəticə lövhəsi |
| `ui/app_icon.svg` | 512² | Play Store ikonu; `game/icon.svg` ilə eyni fayl |

### C. Hazırda kodla çəkilən, sprite-a keçirilə bilən

- **Top atma düyməsi** ([`fire_button.gd`](../game/scripts/client/fire_button.gd)) —
  8-10 çəkiliş çağırışıdır. Sprite olsa bir dənəyə düşər. Amma iki vəziyyəti
  göstərməlidir: **sursat var / yoxdur** və **atəş dövrünün qalığı** (halqa).
  Yəni ən azı iki fayl + kodda halqa.
- **Petri qabının şəbəkəsi və halqaları** ([`arena.gd → _draw`](../game/scripts/client/arena.gd)) —
  tək böyük tekstura ilə əvəz oluna bilər, amma dünya 2400 px enindədir,
  ona görə təkrarlanan (tileable) naxış lazımdır.

---

## Ekranlar

Real ekran görüntüləri (mockup yox, oyunun özü):

- [`docs/screenshot_menu.png`](../docs/screenshot_menu.png) — baş menyu
- [`docs/screenshot_world.png`](../docs/screenshot_world.png) — oyun ekranı

Yenidən çəkmək üçün:

```bash
GODOT --path game --resolution 720x1560 --max-fps 60 \
      -- --practice --shot C:/yol/kadr.png --shot-delay 500
```

Dizayn dəyişikliyini yoxlamağın ən sürətli yolu budur — redaktoru açmağa ehtiyac yoxdur.

---

## Assetin layihəyə düşməsi

```bash
cp design/sprites/*.svg game/assets/sprites/
cp design/ui/*.svg      game/assets/ui/
cp design/ui/app_icon.svg game/icon.svg
GODOT --headless --path game --import      # yeni SVG-ləri idxal edir
```
