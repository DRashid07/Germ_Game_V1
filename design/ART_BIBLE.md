# Germ Arena — Art Bible

**Üslub:** *Bioluminescent petri dish* — qaranlıq laboratoriya qabında öz-özünə
işıq saçan mikroblar. Heç bir metal, heç bir künc; hər şey yumşaq, yaş və canlıdır.

---

## 1. Palitra

Kodda tək mənbə: [`game/scripts/shared/palette.gd`](../game/scripts/shared/palette.gd).
Rəngi dəyişəndə həm oradakı sabit, həm bu sənəd yenilənməlidir.

### Qab (fon)

| Ad | Kod | İşlədilir |
|---|---|---|
| `BG_OUTER` | `#071012` | Qabın kənarından bayır — dünyanın sərhədi |
| `DISH` | `#0C1A1E` | Qabın döşəməsi |
| `DISH_EDGE` | `#1E4650` | Şüşə kənar (8 px qalınlıqda halqa) |
| `GRID` | `#122A31` | Döşəmə şəbəkəsi və məsafə halqaları |
| `MUCUS` / `MUCUS_EDGE` | `#16333B` / `#245562` | Selik ləkələri (maneə) |

Fon QƏSDƏN aşağı kontrastdır: ekranda 10 mikrob, 50 qida topu və uçan toplar var —
oxunaqlıq yalnız ön planın parlaq olması ilə qazanılır.

### Mikrob rəngləri (10 ədəd)

`7CFF5B` laym · `2FE8E0` firuzəyi · `FF5BC8` magenta · `FFB43D` kəhrəba ·
`A96BFF` bənövşəyi · `FF6B5B` mərcan · `4D9BFF` göy · `4BFFA5` nanə ·
`FF87A8` çəhrayı · `F2E14C` qızılı

Bir dünyada maksimum 10 mikrob var və hər birinə AYRI rəng düşür
([`World._free_color`](../game/scripts/server/world.gd)) — iki eyni rəngli mikrob
heç vaxt görünmür. Rənglər həm tondan, həm parlaqlıqdan fərqlənir ki, rəng
korluğunda da ayırd edilsin; forma dili isə rəngdən asılı deyil (bax §3).

### Vəziyyət rəngləri

| Ad | Kod | Mənası |
|---|---|---|
| `SAFE` | `#52E08A` | Doluluq 30–85% — sağlam |
| `WARNING` | `#FFB020` | Doluluq ≤30% — ac qalırsan |
| `DANGER` | `#FF4757` | Doluluq ≥85% — partlamağa yaxınsan |
| `FOOD` | `#D9FFC0` | Yerdəki sərbəst top |
| `FOCUS` | `#FFD166` | Öz mikrobunun halqası |

Bu üç rəng oyunun bütün qaydasını izah edir: **sarı = az, yaşıl = yaxşı, qırmızı = çox**.
Eyni məntiq həm HUD göstəricisində, həm hər mikrobun ətrafındakı halqadadır.

---

## 2. Mikrob niyə sprite deyil

Mikrobun **ölçüsü tutumdan**, **içindəki topların sayı isə mövcud saydan** asılıdır.
İkisi də oyun boyu dəyişir (tutum 10 → 60, top sayı 0 → 60), ona görə hazır şəkil
uyğun gəlmir. Mikrob tamamilə kodla çəkilir:
[`game/scripts/client/germ_visual.gd`](../game/scripts/client/germ_visual.gd).

Quruluş (içəridən çölə):

1. **Toplar** — "günəbaxan" (phyllotaxis) düzümü: qızıl bucaq `2.39996` rad.
   Say dəyişəndə düzüm sıçramır, sadəcə bir top artır.
2. **Membran** — 24 nöqtəli çoxbucaqlı, radiusu iki fərqli tezlikli sinusla
   modullaşdırılır. Doluluq artdıqca titrəmə həm güclənir, həm sürətlənir:
   *gərginlik* budur.
3. **Doluluq halqası** — membranın 5 px kənarında, saat əqrəbi istiqamətində dolur.
4. **Psevdopodiya** — nişan istiqamətindəki kiçik çıxıntı: mikrobun hansı tərəfə
   atacağını göstərir.

> **Çəkiliş sırası vacibdir.** Əvvəlcə bütün DOLU formalar, sonra bütün XƏTLƏR.
> Qarışsa, hər mikrob 15-20 ayrıca çəkiliş çağırışı olur — mobil GPU-da əsas
> məhdudiyyət məhz çağırış sayıdır.

---

## 3. Forma dili

| Obyekt | Forma | Niyə |
|---|---|---|
| Mikrob | titrəyən dairə | canlı, sərhədi qeyri-müəyyən |
| Qida | kiçik hamar top, parlaq nüvə | hərəkətsiz, "yem" |
| Atılan top | eyni top + rəng + iz | qidadan RƏNGİ ilə ayrılır |
| Maneə | böyük tünd ləkə, ləkəli səth | fon qatındandır, ön plana çıxmır |
| Partlama | halqa + səpilən damlalar | maddə itmir, ətrafa yayılır |

Rəng korluğu üçün əsas ayırd etmə formadadır: qida HƏMİŞƏ kiçik və solğun-yaşıl,
mikrob HƏMİŞƏ böyük və titrəyən, maneə HƏMİŞƏ hərəkətsiz və tünddür.

---

## 4. SVG qaydaları

> ⚠️ **SVG-də `<text>` elementi işlətmə.** Godot SVG-ni ThorVG ilə rasterləşdirir,
> ThorVG isə mətn elementlərini **sükutla atır** — heç bir xəta vermir, sadəcə
> yazı görünmür.
>
> Loqodakı "GERM ARENA" yazısı məhz buna görə SVG-də yox, kodda çəkilir:
> [`main_menu.gd → _make_logo()`](../game/scripts/client/main_menu.gd).

Digər qaydalar:

- **Tək rəngli sprite + `modulate`.** Atılan top (`shot_ball.svg`) və partlama
  (`burst.svg`) ağ-boz çəkilib, rəngi kodda verilir. Belə olanda 10 rəng üçün
  bir tekstura bəs edir və hamısı bir çəkiliş çağırışına yığılır.
- **Radius sprite-da sabit.** `mucus_blob.svg`-də ləkənin radiusu 120 px-dir;
  kod `scale = radius / 120` ilə ölçüləndirir. Bu rəqəm dəyişsə kod da dəyişməlidir.
- **Haşiyə üçün yer saxla.** Parlaq haşiyə sprite-ın kənarına toxunmamalıdır,
  əks halda miqyaslananda kəsilir.

---

## 5. Assetlərin siyahısı

Hamısı `design/` altındadır və oradan `game/assets/`-ə kopyalanır.

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `sprites/food_ball.svg` | 32² | Kodda `scale 0.85` |
| `sprites/shot_ball.svg` | 36² | `modulate` ilə rənglənir |
| `sprites/mucus_blob.svg` | 256² | Ləkə radiusu 120 |
| `sprites/spark.svg` | 64² | Dəymə/udma qığılcımı |
| `sprites/burst.svg` | 256² | Partlama, `modulate` ilə rənglənir |
| `ui/joystick_base.svg` | 220² | Üzən joystickin bazası |
| `ui/joystick_knob.svg` | 96² | Joystickin başlığı |
| `ui/button_primary.svg` | 480×110 | İçi tünd — mətn kodla üstünə yazılır |
| `ui/button_secondary.svg` | 480×110 | Eyni, sönük variant |
| `ui/panel.svg` | 480×300 | Nəticə lövhəsi üçün çərçivə |
| `ui/logo.svg` | 600×220 | YALNIZ nişan, yazısız |
| `ui/app_icon.svg` | 512² | `game/icon.svg` ilə eynidir |

Top atma düyməsi ([`fire_button.gd`](../game/scripts/client/fire_button.gd)) hazırda
kodla çəkilir — oyunçunun rəngini və sursat vəziyyətini göstərməli olduğu üçün.
Sprite-a keçirilsə, rəng `modulate` ilə verilməlidir.
