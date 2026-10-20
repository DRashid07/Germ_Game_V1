# Ana ekranın illüstrasiyaları və ikonları

Ana ekranın fonu, podiumu, üç növün qəhrəman şəkli, üç portret kartı və on səkkiz ikonu **Codex ilə
çəkilib** (`codex exec`, daxili `image_gen` aləti). Oyunun qalan qrafikası
kodla və ya SVG ilə çəkilir — bunlar və döyüşdəki dörd nişan ikonu (aşağıda, «DÖYÜŞ
HUD-u») layihədə yeganə raster şəkillərdir.

Niyə kodla yox: ana ekran Brawl Stars lobbisinin məntiqi ilə qurulub — fiqur
ekranın SAHİBİDİR. Əvvəl orada oyunun öz [`GermVisual`]-ı 4.2× böyüdülürdü:
oyunla eyni idi, amma boş qara fonda kiçik bir ləkə kimi oxunurdu. Oyundakı
görünüş itmir — növün səhifəsindəki «OYUNDA» pəncərəsi canlı `GermVisual`-dır.

| Fayl (oyunda) | Xam mənbə | Nə |
|---|---|---|
| `game/assets/menu/menu_bg.jpg` | `raw/menu_bg.png` | Petri qabının içi, suyun altından; mərkəz sakit, künclər tünd |
| `game/assets/menu/menu_podium.png` | `raw/menu_podium.png` | Şüşə petri halqası — qəhrəmanın səhnəsi |
| `game/assets/menu/hero_ciliate.png` | `raw/hero_ciliate.png` | KİRPİKLİ |
| `game/assets/menu/hero_heliozoan.png` | `raw/hero_heliozoan.png` | AYAQLI |
| `game/assets/menu/hero_amoeba.png` | `raw/hero_amoeba.png` | AMÖB |
| `game/assets/menu/icon_brawlers.png` | `raw/icons/icon_brawlers.png` | Sol lent: MİKROBLAR — üç növ bir yerdə |
| `game/assets/menu/icon_practice.png` | `raw/icons/icon_practice.png` | Sol lent: MƏŞQ — hədəf lövhəsi və top |
| `game/assets/menu/icon_settings.png` | `raw/icons/icon_settings.png` | Dişli — AYARLAR |
| `game/assets/menu/mode_endless.png` | `raw/icons/mode_endless.png` | SONSUZ ARENA — firuzəyi sonsuzluq |
| `game/assets/menu/mode_solo.png` | `raw/icons/mode_solo.png` | TƏK QALAN — taclı tək mikrob |
| `game/assets/menu/mode_duo.png` | `raw/icons/mode_duo.png` | CÜT — iki mikrob |
| `game/assets/menu/mode_trio.png` | `raw/icons/mode_trio.png` | ÜÇLÜK — üç bənövşəyi mikrob |
| `game/assets/menu/icon_shop.png` | `raw/icons/icon_shop.png` | MAĞAZA* — çəhrayı çanta, içindən mikrob baxır |
| `game/assets/menu/icon_pass.png` | `raw/icons/icon_pass.png` | MİKRO PASS* — qızılı bilet, mikrob möhürü |
| `game/assets/menu/icon_quests.png` | `raw/icons/icon_quests.png` | TAPŞIRIQLAR* — tumar və yaşıl işarə |
| `game/assets/menu/currency_food.png` | `raw/icons/currency_food.png` | QİDA* — yumşaq valyuta, parlaq qida topu |
| `game/assets/menu/currency_dna.png` | `raw/icons/currency_dna.png` | DNT* — premium valyuta, DNT sarmalı kristal |

\* Görünüş üçün: arxalarında hələ sistem yoxdur (bax `design/ART_BIBLE.md` § 6b).

**MİKROBLAR kolleksiyası** (bax `design/ART_BIBLE.md` § 6d):

| Fayl (oyunda) | Xam mənbə | Nə |
|---|---|---|
| `game/assets/menu/card_ciliate.png` | `raw/cards/card_ciliate.png` | KİRPİKLİ portret kartı — kəhrəba (CƏLD) |
| `game/assets/menu/card_heliozoan.png` | `raw/cards/card_heliozoan.png` | AYAQLI — bənövşəyi (NƏZARƏTÇİ), spikalar arasında tor |
| `game/assets/menu/card_amoeba.png` | `raw/cards/card_amoeba.png` | AMÖB — göy (MÜDAFİƏÇİ), ətrafında sist qabığı |
| `game/assets/menu/class_swift.png` | `raw/icons/class_swift.png` | Sinif: CƏLD |
| `game/assets/menu/class_control.png` | `raw/icons/class_control.png` | Sinif: NƏZARƏTÇİ |
| `game/assets/menu/class_guard.png` | `raw/icons/class_guard.png` | Sinif: MÜDAFİƏÇİ |
| `game/assets/menu/super_trichocyst.png` | `raw/icons/super_trichocyst.png` | Super: TRİXOSİST |
| `game/assets/menu/super_net.png` | `raw/icons/super_net.png` | Super: AKSOPODİYA TORU |
| `game/assets/menu/super_cyst.png` | `raw/icons/super_cyst.png` | Super: SİSTLƏŞMƏ |

**DOSTLAR və KOMANDA** (bax kök `README.md`, «Dostlar və komanda»):

| Fayl (oyunda) | Xam mənbə | Nə |
|---|---|---|
| `game/assets/menu/icon_friends.png` | `raw/icons/icon_friends.png` | Sağ lent: DOSTLAR — iki mikrob psevdopodla "əl sıxır" |
| `game/assets/menu/icon_add_friend.png` | `raw/icons/icon_add_friend.png` | DOST ƏLAVƏ ET — laym mikrob və yaşıl «+» nişanı |
| `game/assets/menu/icon_crown.png` | `raw/icons/icon_crown.png` | Komanda LİDERİ — qızılı tac, daşları qida topu |
| `game/assets/menu/icon_invite.png` | `raw/icons/icon_invite.png` | KOMANDA DƏVƏTİ — məktub, mikrob möhürü ilə |
| `game/assets/menu/icon_link.png` | `raw/icons/icon_link.png` | PAYLAŞ / LİNK — iki firuzəyi zəncir halqası |

**DÖYÜŞ HUD-u — NİŞAN** (bax kök `README.md`, «Nişan — toxun və ya sürüşdür»). Bunlar
menyu yox, matçın içindədir və **ağ-boz** çəkilib: oyun onları oyunçunun rəngi ilə
vuraraq (`modulate`) boyayır, ona görə hər rəng üçün ayrı fayl lazım deyil:

| Fayl (oyunda) | Xam mənbə | Nə |
|---|---|---|
| `game/assets/ui/hud_fire.png` | `raw/hud/hud_fire.png` | Atəş düyməsinin ikonu — yuxarı-sağa uçan top, arxasında üç sürət cizgisi |
| `game/assets/ui/hud_aim_knob.png` | `raw/hud/hud_aim_knob.png` | Nişan başı — nişangahlı disk, sürüşdürərkən barmağın altında |
| `game/assets/ui/hud_target.png` | `raw/hud/hud_target.png` | Kilid çərçivəsi — avtomatik nişanın hədəfinin üstündə; ortası BOŞDUR |
| `game/assets/ui/hud_aim_arrow.png` | `raw/hud/hud_aim_arrow.png` | Nişan xəttinin ucu — sağa (+X) baxan şevron |

Dördü də `gpt-6-astra`, reasoning effort **`max`** ilə çəkilib (Codex CLI 0.159.2).
Brif: `brief/BRIEF_AIM.md`, faktiki promptlar: `brief/PROMPTS_AIM.md`. İstinad:
oyunun öz kadrı və dörd təsdiqlənmiş ikon (`icon_practice`, `icon_settings`,
`icon_link`, `super_trichocyst`). Neytrallıq yoxlanılıb — qeyri-şəffaf pikseldə
kanallar arası fərq 24-dən azdır, yoxsa boyanan rəng çirklənərdi. İkonlar uzun
tərəfi 256 px-ə kəsilib (`process.gd trim … 256`), `.import`-da mipmap açıqdır.

Yuxarıdakı beşi `gpt-6-astra` modeli ilə, reasoning effort **`max`** çəkilib (Codex CLI
0.159.2; 0.148 bu modeli tanımırdı). Brif: `brief/BRIEF_SOCIAL.md`, Codex-in
hesabatı və faktiki promptlar: `brief/PROMPTS_SOCIAL.md`. Stil istinadı kimi
dörd təsdiqlənmiş ikon `-i` ilə verildi (`mode_duo`, `icon_quests`,
`icon_settings`, `class_guard`) — ayrıca istinad vərəqinə ehtiyac qalmadı.

Portretlər Brawl Stars brawler kartı kimidir: qəhrəman yaxından, qəhrəmanlıq
pozasında, sinfin rəngində şüalı fonda; kartın alt 25%-i sakitdir — ad orada
yazılır. Qəhrəman şəkilləri (`raw/hero_*.png`) istinad kimi verilib ki, dizayn
dəyişməsin. Brif: `brief/BRIEF_CARDS.md`, `brief/BRIEF_ICONS3.md`.

İkonlar Brawl Stars-ın glif dilindədir: qalın qara kontur (enin ~4%-i), doymuş
rəng, yuxarı-soldan işıq, 64 px-ə kiçildiləndə də oxunan iri formalar. Rejim
ikonlarının rəngi `MenuV2.MODE_TINT` ilə eynidir — ana ekrandakı rejim kartı
da həmin rəngə boyanır. Brif: `brief/BRIEF_ICONS.md` və `brief/BRIEF_ICONS2.md`, promptlar:
`brief/PROMPTS_ICONS.md` və `brief/PROMPTS_ICONS2.md`.

## Loqo və açılış ekranı

Oyun əvvəl Godot loqosu ilə açılırdı. İndi açılışda oyunun öz loqosudur — iki
sətirli söz nişanı: iri laym **GERM**, altında fil sümüyü rəngli **ARENA**, qalın
tünd kontur və qısa tünd-firuzəyi dərinlik. Parıltı, işıq şüası, metal, nişan
lövhəsi yoxdur: sahib "sadə, süni intellekt loqosu kimi şatafatlı olmayan,
premium oyun hissi verən" loqo istədi.

| Fayl (oyunda) | Mənbə | Nə |
|---|---|---|
| `game/assets/ui/boot_splash.png` | `raw/logo/logo_c2.png` | Açılış şəkli: 1920×1080, şəffaf, loqo hündürlüyün 38%-i, mərkəzdə. Solda petri halqasında mikrob nişanı, sağda iki sətir — sahib C2-ni seçib |
| — | `raw/logo/logo_a2.png` | Variant A2: yalnız iki sətirlik söz nişanı (alternativ) |
| — | `raw/logo/logo_a.png`, `logo_b.png`, `logo_c.png` | 1-ci turun variantları (A əvvəl oyunda idi) |

Codex ilə çəkilib (`gpt-6.1-sol`, reasoning effort **`max`**, Codex CLI 0.159.2), iki
turda. İstinadlar: ana ekranın kadrı, dörd təsdiqlənmiş şəkil və "GERM ARENA"
sözünün oyunun öz başlıq şriftində (Baloo 2, `wght` 800) çəkilmiş nümunəsi — hərflər
menyudakı OYNA, AMÖB yazıları ilə eyni ailədən görünür. Yuxarıdakı 3-cü sərt qayda
(yazı yoxdur) loqoya aid deyil — loqonun işi elə addır.

- **1-ci tur** — üç istiqamət (A iki sətir, B bir sətir + mikrob, C nişan + iki
  sətir). Brif: `brief/BRIEF_LOGO.md`, hesabat və promptlar: `brief/PROMPTS_LOGO.md`.
- **2-ci tur** — A və C cilalanıb. A-da dərinlik dənəli idi, ARENA-nın parıltıları
  ləkə kimi oxunurdu, kontur nazik, A-ların dəliyi kiçik idi; A2-də kontur ~1.4×
  qalın və bərabər, doqquz hərfdə eyni kapsul parıltı, dərinlik düz #0E3A40,
  dəliklər açıq. C-də halqa tünd fonda itirdi; C2-də görünən şüşə-firuzəyi halqa,
  sakit amöb. Brif: `brief/BRIEF_LOGO2.md`, hesabat: `brief/PROMPTS_LOGO2.md`.

2-ci turda Codex-in **son ixracı işlənmir** — onun öz PowerShell "təmizləməsi"
dərinliyi demək olar görünməz etdi. Oyuna onun image_gen QARALAMASI girir
(`raw/logo/src/*_key.png`, çəhrayı fonda): fon `process.gd -- keyc` ilə çıxarılır,
şəklin dəni `ffmpeg nlmeans` ilə yığılır (kənarlara toxunmur). `keyc` açar rəngini
künclərdən götürür: image_gen-in "magentası" əslində ~#FC40C1-dir və köhnə `key`
rejimi (#FF00FF) onu səhv oxuyur. Ağ və sarı fonda yoxlanılıb — çəhrayı haşiyə qalmır.

Şəkil üç yerdə görünür, üçündə də **eyni fonda** (`#070F12`, oyunun
`default_clear_color`-u):

1. Mühərrikin açılış ekranı — `project.godot` → `application/boot_splash/*`.
   `Keep` rejimi bütün kətanı ekrana sığdırır, ona görə loqonun ölçüsünü kətan təyin edir.
2. Brauzerin yükləmə ekranı — ixrac şəkli `index.png` kimi yazır, `shell.html`
   onu `fullsize--true` ilə (`object-fit: contain`) eyni ölçüdə göstərir.
3. Oyunun içində [`BootLogo`] — menyu yüklənənə qədər həmin şəkli saxlayır, sonra əvvəl
   loqo tünd fonda sönür (0.25 s), sonra fon əriyib menyunu açır (0.3 s). Mühərrik
   şəkli yalnız ilk kadra qədər göstərir; onsuz loqo kəsilib menyu birdən çıxırdı.

`boot_splash.png.import` → `skip`: şəkil teksturaya çevrilmir. İxrac açılış şəklini onsuz
da xam PNG kimi saxlayır və `BootLogo` onu baytlarla oxuyur — APK-da bir nüsxədir.

**Android.** Android 12+ mühərrikdən ƏVVƏL öz açılış ekranını göstərir. Godot-un hazır
şablonunda orada Godot robotu, mavi fon, "temalı ikon" qatında da Godot robotu idi.
İxrac seçimləri (`export_presets.cfg`, iki Android profili):

| Seçim | Fayl | Niyə |
|---|---|---|
| `launcher_icons/adaptive_foreground_432x432` | `game/assets/ui/android/icon_foreground.png` | Mikrob + halqalar, 264 px-lik zəmanətli dairənin içində |
| `launcher_icons/adaptive_background_432x432` | `…/icon_background.png` | Petri qabının dibi; şablonun mavi fonunu əvəz edir |
| `launcher_icons/adaptive_monochrome_432x432` | `…/icon_monochrome.png` | Temalı ikon (Android 13+); şablonda Godot robotu idi |
| `splash_screen/icon` | `…/splash_icon.png` | Açılış ekranının ikonu — ÖZ tünd diski ilə |
| `screen/background_color` | `#070F12` | İlk kadra qədər pəncərənin rəngi (əvvəl qara idi) |

Tələ: hazır (gradle-siz) APK-da sistem açılış ekranının FONU dəyişmir — şablon ona
rəng yerinə şəkil (`@mipmap/icon_background`) verir, Android onu oxumur və ağ (tünd
rejimdə boz) fon çəkir. `splash_screen/background_color` yalnız gradle build-də işləyir.
Ona görə ikon öz tünd diskini daşıyır və istənilən fonda eyni görünür. Emulyatorda
(Android 14) yazılıb: ağ fonda ikon → tünd-firuzəyi → loqo → menyu, Godot loqosu yoxdur.

Mənbələr `design/ui/android/*.svg`-dir (`app_icon.svg`-nin mikrobu, 0.643 miqyasında).
`.import` → `skip`: onları yalnız ixrac oxuyur, oyuna lazım deyil.

```bash
# Loqo: çəhrayı fonlu qaralamadan şəffaf fayla, sonra dəni yığmaq
GODOT --headless --path <boş_layihə> -s process.gd -- keyc raw/logo/src/logo_c2_key.png c2_keyed.png 1536
ffmpeg -i c2_keyed.png -filter_complex "[0]format=rgba,split[x][y];[x]alphaextract[a];[y]format=gbrp,nlmeans=s=3:p=5:r=11[c];[c][a]alphamerge,format=rgba" raw/logo/logo_c2.png
# Açılış şəkli (loqo hündürlüyün 38%-i — C2 enlidir, A2 üçün 0.44 idi):
GODOT --headless --path <boş_layihə> -s process.gd -- splash raw/logo/logo_c2.png game/assets/ui/boot_splash.png 1920 1080 0.38
# Android ikon qatları:
GODOT --headless --path <boş_layihə> -s process.gd -- png design/ui/android/icon_foreground.svg game/assets/ui/android/icon_foreground.png
```

## Sərt qaydalar

Bunlar `brief/STYLE.md`-dədir və hər yeni şəkil üçün keçərlidir:

1. **Mikrobların SİMASI YOXDUR** — göz, ağız, bəbək yoxdur (bax
   `design/BRAWL_UPGRADE.md` § 0). Codex-in ilk təklifləri bəzən iki parlaq
   nöqtə qoyur və o, göz kimi oxunur — belə şəkil rədd edilir.
2. Qalın tünd kontur (`#04090B`), işıq **yuxarı-soldan**, içində oyunun
   parlaq topları görünür. Rəng — laym `#7CFF5B`, oyundakı menyu rəngi.
3. Heç bir yazı, loqo, su nişanı yoxdur.

## Şəffaflıq tələsi

`image_gen` "şəffaf fon" istəyinə bəzən **şahmat naxışını şəklin İÇİNƏ
çəkməklə** cavab verir: fayl 24-bit RGB-dir, alfa yoxdur. Gözlə baxanda
şəffaf görünür, oyunda isə mikrobun ətrafında boz kvadratlar çıxır. İlk
kirpikli məhz belə gəldi və rədd edildi.

Ona görə brifdə yoxlama MƏCBURİDİR: fayl `Format32bppArgb` olmalı və künc
pikselinin alfası 0 olmalıdır. Alınmasa, ikinci yol — düz magenta
(`#FF00FF`) fon üzərində çəkmək; `process.gd`-nin `key` rejimi onu çıxarır.

## Necə yenidən çəkmək

```bash
# Brif + stil + istinad şəkilləri (oyundakı növün kadrı) bir qovluqda:
codex exec --skip-git-repo-check -s workspace-write \
  -i ingame_species_0.png -i ingame_species_1.png -i ingame_species_2.png \
  < brief/BRIEF_HEROES.md
```

İstinad kadrı oyunun öz stendindən çəkilir:

```bash
GODOT --path game --resolution 1280x720 -- --preview --preview-species 0 \
  --preview-balls 8 --preview-cap 14 --shot species_0.png
```

Codex-in faktiki işlətdiyi promptlar: `brief/PROMPTS_ENV.md`,
`brief/PROMPTS_HEROES.md`.

## Emal

Xam şəkil oyuna birbaşa girmir. `process.gd` şəffaf haşiyəni kəsir (2%
saxlayır), uzun tərəfi kiçildir və lazım gəlsə magenta fonu çıxarır. Python
tələb etmir — Godot-un özü ilə işləyir (boş bir `project.godot` olan qovluqda):

```bash
GODOT --headless --path <boş_layihə> -s process.gd -- trim raw/hero_amoeba.png hero_amoeba.png 768
GODOT --headless --path <boş_layihə> -s process.gd -- trim raw/menu_podium.png menu_podium.png 900
ffmpeg -i raw/menu_bg.png -q:v 2 menu_bg.jpg
# Kart portreti: kartın üz nisbətinə (274:387) kəs, 548 en, künc radiusu 32
GODOT --headless --path <boş_layihə> -s process.gd -- card raw/cards/card_amoeba.png card_amoeba.png 548 0.708010335917 32
```

`card` rejimi künclərin alfasını özü kəsir: TextureRect künc kəsə bilmir,
`clip_children` isə mobil (Compatibility) renderdə etibarsızdır. Artıq hissənin
35%-i yuxarıdan, 65%-i aşağıdan götürülür — qəhrəman yuxarı-ortadadır.

| | Ölçü | Niyə |
|---|---|---|
| Qəhrəman | uzun tərəf 768 | 1080p telefonda ekranda ~540 px-dir; artığı APK-nı böyüdür |
| Podium | en 900 | 1080p-də ekranda 864 px |
| Fon | 1672×941, JPG | şəffaflıq lazım deyil; PNG 1.5 MB, JPG 170 KB |
| İkon | uzun tərəf 256 | ekranda ən çox 82 px (1080p-də ~125 px); mipmap ilə kiçildilir |
| Kart portreti | 548×774, künc radiusu 32 | ekranda 274×387 (kolleksiya) və 354×500 (səhifə); 2× kəskinlik |

Qəhrəmanların və ikonların `.import` faylında `mipmaps/generate=true` açıqdır: şəkil
ekranda 2–3 dəfə kiçildilir və mipmap-sız kiçiltmə kirpikləri titrədir.

`PODIUM_TOP` (`menu_v2.gd`) podium şəklinin üst üzünün mərkəzidir — podium
yenidən çəkilsə, bu rəqəm də yenidən ölçülməlidir.
