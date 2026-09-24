# Brawl Stars səviyyəsinə qaldırma — icra brifi

Bu sənəd BİR dəfəlik iş planıdır: mikrobun obrazı, xəritənin materialı və
animasiya/VFX qatı "production mobil arena" səviyyəsinə qaldırılır.

`design/ART_BIBLE.md` MƏNBƏDİR — bu brif onu əvəz etmir, davam etdirir.
İş bitəndə ART_BIBLE dəyişən hər rəqəmlə birlikdə yenilənməlidir.

---

## 0. Kilidlənmiş iki qərar

Bu iki qərar oyunun sahibi tərəfindən verilib və MÜZAKİRƏ OLUNMUR:

1. **Mikrobların SİMASI YOXDUR.** Göz, ağız, bəbək ƏLAVƏ EDİLMİR. Art Bible-ın
   elmi/abstrakt dili qalır. Cazibə simadan yox, **siluetdən, materialdan və
   hərəkətdən** gəlir: qalın tünd kontur, tam tutqun sel-shading, rim-light,
   kontakt kölgəsi, squash & stretch.

2. **Xəritə "oxunaqlı arena" olur, "işıqlı arena" YOX.** Bioluminessent qaranlıq
   qab konsepti qalır — palitra kökündən açılmır. Qazanc ÜÇ şeydən gəlir:
   döşəmənin orta tona qaldırılması, maneələrə **HÜNDÜRLÜK** verilməsi
   (üst üz + tünd yan üz + düşən kölgə), və sərhədin qalın/aydın olması.

---

## 1. Toxunulmaz sərhədlər

Bunlardan biri pozulursa, dəyişiklik SƏHVDİR:

| Qayda | Səbəb |
|---|---|
| **Oyun məntiqi DƏYİŞMİR** | Server-authoritative. `sim.gd`, `world.gd`, `bot.gd`, `net.gd` və `constants.gd`-dəki oyun rəqəmləri (radius, sürət, tutum, zərər, atəş dövrü) TOXUNULMAZ. |
| **Toqquşma həndəsəsi DƏYİŞMİR** | `DishMap.obstacles()` siyahısı (mövqe, radius, növ) olduğu kimi qalır. Yalnız GÖRÜNÜŞÜ dəyişir. |
| **`--simtest` tam keçməlidir** | 260 test. Xüsusilə `_check_gait` (ayağın yük dövrü) və `_test_arena_core_is_free`. |
| **Çəkiliş çağırışı ≤ 350 (pik)** | İndi 130–300. Hər yeni `draw_*` çağırışı ölçülməlidir. Batch yalnız ARDICIL və eyni teksturalı elementlərdə işləyir. |
| **`Quality.LOW` real olaraq ucuz olmalıdır** | Telefonda ilkin dəyər AŞAĞI-dır. Hər yeni zərrəcik/effekt LOW-da yarıya düşməli və ya sönməlidir. |
| **Şərhlər AZƏRBAYCANCA** | Mövcud `##` doc-comment üslubu ilə eyni: nə etdiyini yox, NİYƏ belə olduğunu yaz. Rəqəm seçilibsə, niyə məhz o rəqəm — və hansı alternativ sınanıb uğursuz olub. |
| **Rəng sabitləri yalnız `palette.gd`-də** | Faylın içində hard-coded hex YAZILMIR. Yeni rəng lazımdırsa `Palette`-ə sabit əlavə et. |

### İşıq istiqaməti — qlobal və TƏK

Bütün yeni kölgə/işıq **yuxarı-soldan** gəlir. Səbəb: maneə sprite-ları onsuz da
belə işıqlanıb və `_spawn_obstacles` şərhi maneələrin QƏSDƏN fırladılmadığını
izah edir. `Palette`-ə əlavə et:

```gdscript
const LIGHT_DIR := Vector2(-0.45, -0.89)   ## normallaşdırılmış, yuxarı-sol
```

Hər kölgə `-LIGHT_DIR` istiqamətinə düşür, hər işıq bandı `+LIGHT_DIR` tərəfdədir.
İki yerdə iki fərqli işıq istiqaməti OLMAMALIDIR — indiki səhv budur.

---

## 2. MƏRHƏLƏ 1 — Mikrobun obrazı

Fayllar: `game/scripts/client/germ_visual.gd`, `game/scripts/shared/palette.gd`.

### 2.1 Siluet və kontur (ən böyük qazanc)

İndi kirpikli və ayaqlının gövdəsi `Color(_base…, 0.30)` ilə ŞƏFFAF çəkilir —
fon onların içindən görünür və siluet itir. Amöbdə artıq tam tutqundur və məhz
ona görə üçündən ƏN YAXŞI oxunanı odur.

- Hər üç növün gövdəsi **TAM TUTQUN** olur.
- Xarici siluetə **qalın tünd kontur**: en `clampf(r * 0.10, 2.4, 6.0)`,
  rəng `Palette.OUTLINE` (alfa 0.95).
- Kontur HƏQİQİ membran çoxbucaqlısını izləyir — dartılma, atəş qabarması və
  amöbin ləçəkləri daxil. Dairə ilə çəkilmir.
- Sıra: dolu formalar → kontur → xətlər (kirpik/ayaq/quyruq) → rim-light.

### 2.2 Sel-shading — iki ton + rim

Şeyder YOXDUR (`gl_compatibility`, mobil). İki çoxbucaqlı ilə edilir:

1. Gövdə **TÜND** tonda çəkilir: `_base.lerp(Palette.OUTLINE, 0.30)`.
2. Üstünə **AÇIQ** ton: eyni çoxbucaqlı `r * 0.10` içəri çəkilmiş və
   `LIGHT_DIR` istiqamətinə `r * 0.14` sürüşdürülmüş halda,
   rəng `_base.lerp(Color.WHITE, 0.28)`. Nəticə yuxarı-solda aypara şəklində
   işıq bandıdır.
3. **Rim-light**: siluetin aşağı-sağ qövsündə (işığın ƏKSİ) nazik parlaq qövs —
   en `r * 0.06`, rəng `_light` alfa 0.55. Bu, gövdəni fondan qoparan şeydir.

Amöbdə iki qat (plazmagel zolağı + plazmazol iç) MEXANİZMDİR, saxlanılır —
eyni işıq/kölgə məntiqi hər iki qata ayrıca tətbiq olunur.

### 2.3 Kontakt kölgəsi

İndi `draw_circle(Vector2(0, 4), r * 1.02, alfa 0.35)` — dairədir və sürüşmə
məsafəsi ölçüdən asılı deyil.

- Ellips olur: miqyas `(1.0, 0.62)`, sürüşmə `-LIGHT_DIR * r * 0.22`.
- İKİ qat: geniş/sönük (alfa 0.18, miqyas 1.15) + dar/tünd (alfa 0.45).
  Bulanıq kölgə təsiri verir, şeyder tələb etmir.
- Amöbdə gövdənin öz silueti işlədilir (indiki həll doğrudur, saxlanılır).

### 2.4 Squash & stretch — beş hadisə

| Hadisə | Deformasiya | Müddət | Əyri |
|---|---|---|---|
| Sürətlənmə | mövcud `STRETCH_MAX` üstünə +0.10 | 0.18 s | ease-out |
| Zərbə yemə (`flash`) | gələn istiqamətə PERPENDİKULYAR 0.88 / 1.14 | 0.14 s | elastic-out |
| Atəş (`eject`) | `-aim` istiqamətinə `r*0.06` geri təpmə + 0.94 / 1.06 | 0.12 s | ease-out |
| Doğuş (`setup`) | miqyas 0 → 1.12 → 1.0 + yerdə halqa | 0.35 s | back-out |
| Boşdayanma | `rush < 0.05` olanda radius × `(1 + 0.018·sin(t·2.1))` + ±1.5° yellənmə | fasiləsiz | sinus |

Deformasiya **membran çoxbucaqlısına** tətbiq olunur, `Node2D.scale`-ə YOX:
miqyas kölgəni, adı və kirpikləri də dartardı.

> **Toqquşma radiusu ilə uyğunsuzluğa DİQQƏT.** `STRETCH_MAX` şərhi deyir ki,
> 0.16-dan çox dartılma membranı həqiqi radiusdan uzağa aparır. Yeni keçici
> dartılma bu həddi pozmamalıdır — cəmi (sabit + keçici) ≤ 0.26 və keçici
> hissə 0.2 saniyədən uzun yaşamır.

### 2.5 Növ fərqinin gücləndirilməsi

- **KİRPİKLİ:** kirpik indi bərabər enli xətdir. Dibi qalın, ucu nazik
  **konusvari lent** olur (`draw_colored_polygon` ilə, dörd nöqtə). Quyruğun
  kökü enli, ucu qamçı kimi incə.
- **AYAQLI:** hər ayaq İKİ keçiddə — əvvəl qalın tünd (kontur), üstündən nazik
  parlaq (aksopodun mineral özəyi). Yerə basılı ayağın ucunda kiçik tünd
  **pəncə ləkəsi** — hansı ayağın yerdə olduğu bir baxışda oxunsun.
- **AMÖB:** arxada **uroid** (quyruq qabarması) əlavə olunur; jel zolağının
  işıqlı kənarı gücləndirilir.

### 2.6 Təhlükə vəziyyəti

`strain >= 0.75` olanda:
- konturun özü `Palette.DANGER`-ə doğru 6 Hz nəbzlə çalır;
- membranda 3–5 qısa **isti çat** qövsü görünür (alfa nəbzlə);
- `rush`-dan asılı olmayan yüngül titrəyiş (±`r*0.015`).

İndiki incə rəng çaları kifayət deyil — partlamağa yaxın rəqib UZAQDAN
oxunmalıdır.

---

## 3. MƏRHƏLƏ 2 — Xəritə və mühit

Fayllar: `game/scripts/client/arena.gd` (`_draw`, `_spawn_obstacles`,
`_spawn_canopy`), `game/assets/sprites/*.svg`, `design/sprites/*.svg`,
`game/scripts/shared/palette.gd`.

> SVG dəyişəndə HƏM `design/sprites/`, HƏM `game/assets/sprites/` yenilənməlidir
> — ikisi eyni fayldır, biri mənbə, biri idxal olunan.

### 3.1 Döşəmə

- `Palette.DISH` `#0C1A1E` → təxminən `#12262C` (orta ton). `BG_OUTER` qaranlıq
  qalır — kontrast məhz bu fərqdən doğur.
- `dish_floor.svg` yenidən çəkilir: radial qradiyent + üzvi **agar ləkələri**
  (yumşaq, təkrarlanmayan) + bişirilmiş **vinyet**. Tək teksturadır, yəni
  bir çəkiliş çağırışı.
- Şəbəkə saxlanılır, amma kafel hissi üçün hər 400 px-dən bir yüngül **beveled**
  xətt gəlir (mövcud `draw_multiline_colors` tək çağırışı pozulmadan).

### 3.2 Maneələrə HÜNDÜRLÜK — bu mərhələnin əsas işi

İndi maneələr yastı yuxarıdan-baxış ləkələridir. Brawl Stars-da divar hündür
oxunur, çünki üç üzü var.

**Həll: hündürlük SVG-yə BİŞİRİLİR.** Səbəb: maneələr QƏSDƏN fırladılmır
(`_spawn_obstacles` şərhi), yəni işıq istiqaməti sabitdir və yan üz sprite-ın
içində dura bilər. Belə olanda əlavə çəkiliş çağırışı **SIFIRDIR** — indiki beş
çağırış beş qalır. İkinci sprite qatı ilə edilsəydi, hər tekstura üçün bir
çağırış daha gedərdi.

Hər BLOKLAYAN maneə (`MUCUS`, `BRITTLE`) üç hissədən ibarət olur:

1. **Düşən kölgə** — `-LIGHT_DIR` istiqamətində, yumşaq kənarlı, ən altda;
2. **Yan üz** — üst üzün altında, `LIGHT_DIR` boyunca sürüşdürülmüş tünd bant
   (hündürlük ≈ sprite radiusunun 22%-i), aşağıya doğru daha da tündləşən;
3. **Üst üz** — yuxarı-soldan işıqlanmış, parlaq kənarlı.

> Hündürlük sprite ilə birlikdə miqyaslanır, yəni İRİ maneə HÜNDÜR görünür.
> Bu, qəsdəndir: yuxarıdan baxışda ölçü ilə hündürlüyün eyni istiqamətdə
> getməsi ən təbii oxunuşdur.

### 3.3 Maneə növləri ayrı-ayrılıqda

- **SELİK (`mucus_blob`, `mucus_bloom`)** — bloklayır. Yaş, qalın, hündür.
  İki naxış fərqi saxlanılır (oriyentir üçün lazımdır).
- **KOL (`mucus_bush`, `mucus_bush_top`)** — YASTI qalır (yan üz YOXDUR: kolun
  içindən keçilir, deməli hündür oxunmamalıdır). Əvəzinə **parlaq doymuş yaşıl**
  olur və döşəmədən kəskin ayrılır. `mucus_bush_top` frondları çoxalır və
  yüngül **külək yellənməsi** alır (`_canopy` node-unda, tək `_process`).
- **KÖVRƏK (`mucus_crust`, `crust2`, `crust3`)** — üç zərbə mərhələsi UZAQDAN
  fərqlənməlidir: çatlar hər mərhələdə aydın dərinləşir, kənardan parça qopur.
- **CƏRƏYAN (`mucus_vent`)** — döşəmədəki DƏLİKDİR, yəni hündürlüyü MƏNFİ:
  yan üz içəri, kölgə isə deşiyin yuxarı-sol daxili divarında. Fırlanan burulğan
  animasiyası əlavə olunur (ikinci sprite qatı, yalnız `vent` üçün — vent sayı
  azdır, bir çəkiliş çağırışına dəyər).

### 3.4 Sərhəd

- Şüşə kənar qalınlaşır və **qalxmış dodaq** kimi oxunur: yuxarı-solda parlaq
  işıq qövsü, içəridə tünd daxili kölgə.
- Kənardan bayırda vinyet gücləndirilir ki, göz içəri çəkilsin.

### 3.5 Quruyan zona (SOLO / DUO / TRIO)

İndi kəhrəba örtük + nəbz vuran halqadır. Əlavə olunur:
- quru döşəmədə **çatlamış** naxış (doymamış, sönük);
- halqa boyunca yavaş sürüşən **buxar** kəkilləri (`Quality.LOW`-da sönür);
- halqanın nəbzi yaş radius kiçildikcə sürətlənir.

---

## 4. MƏRHƏLƏ 3 — Animasiya, VFX və UI juice

Fayllar: `burst_fx.gd`, `arena.gd` (`_flush_fx`, `_spawn_fx`, `_explode`,
`_on_impact`), `hud.gd`, `super_button.gd`, `fire_button.gd`, `menu_v2.gd`,
`water_motes.gd`.

### 4.1 Yeni effektlər

| Effekt | Nə vaxt | Qeyd |
|---|---|---|
| **Lülə alovu** | `eject` | Membranın yarıldığı nöqtədə qısa (0.08 s) parlaq ləçək, nişan istiqamətində. |
| **Zərbə sıçrantısı** | top mikroba dəyəndə | İSTİQAMƏTLİ — topun gəldiyi oxda konus şəklində qığılcım, radial yox. |
| **Zərbə dalğası** | partlayış | Genişlənən nazik parlaq halqa (0.4 s), mövcud `BurstFx`-ə əlavə qat. |
| **Qida udulması** | top yığılanda | Qida mikroba doğru qısa qövslə uçur, sonra membranda kiçik dalğa. |
| **Tutum mükafatı** | `+5 TUTUM` anında | Qısa qızılı aura + halqa (uçan rəqəm onsuz da var). |
| **Kol xışıltısı** | mikrob kola girəndə/çıxanda | `_canopy` frondlarında lokal dalğa. |
| **Qabıq qırıntısı** | kövrək maneə zərbə yeyəndə | Parça + toz buludu; üçüncü zərbədə tam dağılma. |
| **Cərəyan axını** | fasiləsiz | Deşiyə doğru sorulan zərrəciklər (`Quality.LOW`-da sönür). |
| **Doğuş** | mikrob görünəndə | Yerdə halqa + gövdənin pop-in miqyası (bax §2.4). |

### 4.2 Kamera

Mövcud dörd kanal (ağ parıltı, donmuş kadr, kamera zərbəsi, uçan rəqəm)
SAXLANILIR — README-də sənədləşib və səbəbi izah olunub. Əlavə:
- zərbə yeyəndə kamera zərbənin İSTİQAMƏTİNƏ kiçik təpik alır (indi təsadüfi
  titrəyişdir);
- rəqib partlayanda qısa **zoom-punch** (mövcud `_punch` mexanizmi ilə).

> **`Engine.time_scale` İŞLƏDİLMİR.** README bunu ayrıca izah edir: proqnoz
> tick-ləri yavaşıyar və düzəliş mikrobu sıçradar. Donma YALNIZ görüntüdədir.

### 4.3 UI juice

- Düymə basılanda miqyas 0.94 → 1.0 (back-out).
- Super düyməsi: doldurma animasiyası + hazır olanda nəbz + üzərindən keçən
  işıq zolağı.
- HUD doluluq zolağı: animasiya ilə dolur; `DANGER` zonasında titrəyir.
- Uçan rəqəm və bildirişlər: aşırma ilə miqyas artımı (back-out).
- Menyuda növ kartları: basılanda və seçiləndə hərəkət.

### 4.4 Keyfiyyət səviyyəsi

Hər yeni zərrəcikli effekt `Net.quality == Const.Quality.LOW` olanda ya sayca
yarıya düşür, ya tamam sönür. Səviyyə YALNIZ görüntüyə təsir edir — qayda,
görüş sahəsi və şəbəkə eynidir.

---

## 5. Yoxlama — hər mərhələdən sonra MƏCBURİ

`GODOT = C:/Users/User/Godot/Godot_v4.7.2-stable_win64.exe`

```bash
# 1. Simulyasiya testləri (260) — tam keçməlidir
"$GODOT" --headless --path game -- --simtest

# 2. Oyunun kadrı
"$GODOT" --path game --resolution 1280x720 --max-fps 60 \
    -- --practice --shot build/shots/world.png --shot-delay 300

# 3. Üç növün stendi (2 = amöb, 1 = ayaqlı, 0 = kirpikli)
"$GODOT" --path game --resolution 720x1280 \
    -- --preview --preview-species 2 --shot build/shots/amoeba.png --shot-delay 120

# 4. Xəritə düzümü (üst baxış, maneələrin həqiqi sprite-ları ilə)
"$GODOT" --path game --resolution 760x760 \
    -- --map --map-layout 0 --shot build/shots/map0.png --shot-delay 60

# 5. Performans — çəkiliş çağırışı və kadr vaxtı büdcədə qalmalıdır
"$GODOT" --path game --resolution 1280x720 --disable-vsync \
    -- --practice --mode 0 --perf 12
```

`build/` git-də saxlanılmır (`.gitignore`), yəni kadrlar oraya sərbəst yazıla bilər.

---

## 6. Nə ETMƏ

- Sima, göz, ağız ƏLAVƏ ETMƏ (bax §0.1).
- Palitranı kökündən açma (bax §0.2).
- Oyun rəqəmlərinə toxunma (bax §1).
- Şeyder əlavə etmə — `gl_compatibility` və mobil hədəf.
- Şərhləri silmə. Mövcud şərhlərin çoxu SƏHVİN TARİXİDİR: niyə məhz bu rəqəm,
  hansı alternativ sınanıb və nə üçün uğursuz olub. Kod dəyişəndə şərh də
  yenilənməlidir, amma səbəb izahı İTMƏMƏLİDİR.
- Bir addımda hər üç mərhələni birdən etmə — hər mərhələ ayrıca yoxlanılır.
