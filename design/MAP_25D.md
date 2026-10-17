# Xəritə 2.5D — Brawl Stars araşdırması, dörd versiya, Codex assetləri

Bu sənəd xəritənin "Brawl Stars kimi 2.5D və interaktiv" görünüşə keçməsinin
planıdır. Asset-lər Codex ilə çəkilir (maketlər və ortaq dəst hazırdır, versiya
dəstləri növbədədir — §6); oyuna tətbiq SONRAKI işdir (§7).
Hələ heç bir oyun faylı dəyişməyib.

Mənbə hesabatlar (ingiliscə, tam):

| Fayl | Nə var |
|---|---|
| [`map_art/research/brawl_stars_research.md`](map_art/research/brawl_stars_research.md) | Brawl Stars xəritələri: kamera, kafel, tile növləri, mövzular, interaktivlik, mənbələrlə |
| [`map_art/research/godot_25d_technique.md`](map_art/research/godot_25d_technique.md) | Bizim kodda 2.5D-nin dörd yolu, çəkiliş çağırışı, VRAM, asset şablonu |
| [`map_art/research/map_versions_design.md`](map_art/research/map_versions_design.md) | Dörd versiyanın dizaynı və asset siyahıları |
| [`map_art/research/design_critique.md`](map_art/research/design_critique.md) | Dizaynın sərt yoxlaması: 14 səhv və DÜZƏLDİLMİŞ son siyahılar (briflər bundan yazılıb) |

---

## 1. Brawl Stars xəritəsi necə qurulub — bizə lazım olanlar

- **Əsl 3D-dir**, 2D deyil: hər divar, kol, döşəmə `.glb` modelidir, kamera
  perspektivlə təxminən 55–60° aşağı baxır (dəqiq rəqəm tapılmayıb — icma
  təxminidir). Divarın **işıqlı üst üzü və tünd CƏNUB üzü**
  görünür — "hündürlük" hissi buradan gəlir.
- **İşıq kameraya bağlıdır (matcap)** — ona görə divar modellərini təsadüfi
  fırlada bilirlər, işıq dəyişmir. Biz işığı sprite-a bişiririk, ona görə
  fırlatmaq OLMAZ (ART_BIBLE §4b bu dərsi artıq öyrənib) — variasiya ayrı,
  eyni işıqlı sprite ilə verilir.
- **Kölgə yüngüldür:** kölgədəki piksel cəmi ×0.75 tündləşir. Hər tile-ın
  "saxta kölgə" parametrləri var; oxunuşu (yozum, təsdiqlənməyib): kölgə öz
  siluetinin 60% sıxılmış, əyilmiş, aşağıya sürüşmüş nüsxəsidir — bu, 2D-yə
  birbaşa köçür.
- **Kafel:** 1 tile = 300 vahid, oyunçunun toqquşma radiusu 120 vahid. Bizim
  `BASE_RADIUS` 28 px-dir, yəni **1 tile ≈ 70 px**. 3v3 xəritəsi 21×33 tile,
  Showdown 60×60. Bizim qab (2400 px) təxminən 34 tile enindədir.
- **Eyni ayaq izi, müxtəlif dəri:** xəritənin düzümü ilə mövzusu ayrıdır. Bir
  mövzu eyni slotları doldurur (divar, kol, su, hasar, kövrək, qırıntı...) və
  qayda heç vaxt dəyişmir, yalnız görünüş. Mövzular ayda bir fırlanır.
  **Deep Sea** mövzusu (meduza divarları, köpük çıxaran qırıntı, dəniz otu
  yellənməsi) bizə ən yaxın nümunədir.
- **İnteraktivlik ucuzdur:** kol hündürlüyə görə yellənir (fazası mövqedən),
  divar vurulanda titrəyir, sınan divar SINIQ QALIR, bayraq/məşəl 2–3 kadrın
  180–350 ms-də dəyişməsidir (skelet animasiyası yox).
- **Oxunaqlılıq:** döşəmə orta-tünd və sakit, rəng oyunçulardadır; divarlar
  alçaqdır (oyunçunu gizlətmir); hər boşluq ən azı 2 tile-dır (~140 px),
  yəni piksel dəqiqliyi ilə boşluq oxumaq lazım olmur.

> Ən vacib fərq: Brawl Stars-da divarın ÜSTÜ ayaq izindən yuxarı çıxır, oyunçu
> isə bazasını oxuyur. Bizdə bu ART_BIBLE §4b ilə QADAĞANDIR ("siluet =
> toqquşma izi"), çünki bizim boşluqlar 22–158 px-dir və tile-a bölünmür —
> böyüdükcə mikrob üçün "keçirəm / keçmirəm" sərhədi onlarla piksel tərpənir.
> Versiyaların əsas fərqi məhz bu qayda qarşısındakı mövqedir (§3).

## 2. Bizim kodda 2.5D-nin dörd yolu

| Yol | Nədir | Hökm |
|---|---|---|
| **A. Hündürlük ayaq izinin İÇİNDƏ** | Üst üz bir az yuxarı sürüşür, cənubda tünd bant; kölgəni pipeline düzəldir | **Əsas yol.** Şeyder yox, çəkiliş çağırışı ~20 → ~10 |
| **B. Qaldırılmış qapaq** | Üst üz ayaq izindən ≤ 0.10 R (≤ 16 px) çıxır; iki qat (baza mikrobun altında, qapaq üstündə), "xəyal halqası" və öz mikrobunun rentgen konturu | Sahibin qərarı (§4b-ni pozur) |
| **C. Perspektiv** | Kamera `zoom = (k, 0.82k)`: qab ovala dönür, sprite-lar 3/4 görünüşdə | Yalnız prototip, ayrıca art dəsti istəyir |
| **D. Əsl 3D** | Node3D + Camera3D | **Rədd:** Codex model çəkmir, `GermVisual` (2473 sətir) yenidən yazılmalı olardı, veb başlanğıcı ağırlaşır |

Araşdırmada tapılan, VERSİYADAN asılı olmayan üç şey (tətbiqdə ilk bunlar):

1. **Səhv (F1): kolun yarpaqları mikrobun ALTINDA çəkilir.** `GermVisual`
   `z_index = 1/2` qoyur, `_canopy` isə z 0-dadır — z ağac sırasından əvvəl
   gəlir. ART_BIBLE §4b-nin "yarpaqlar mikrobun üstündən keçir" sözü ekranda
   heç vaxt olmayıb. Düzəldiləndə **toplar, izlər və nişan xəttinin üst hissəsi
   (səkmə halqaları, ox, kilid çərçivəsi) yarpaqların ÜSTÜNDƏ** qalmalıdır, yoxsa
   koldan keçən top görünməz olar. Öz mikrobun kolda indi alfa 0.45-ə düşür;
   yarpaq üstündən keçəndə demək olar ki itər — alfa ~0.70 + rentgen konturu.
2. **F2:** README "modulate batch-i qırır" deyir, Godot 4.7.2-nin GLES3
   mənbəyi isə modulate-i instansiya başına saxlayır. 131 → 242 artımının
   başqa səbəbi olmalıdır — `--perf` ilə yenidən ölçülməlidir.
3. **F3:** `_draw` hər kadr iki görünməz tam-ekran disk çəkir (döşəmə onları
   örtür). Qabın xaricində bir halqa mesh-i ilə əvəzlənsə, ən zəif rejimdə
   1–2 ekran doldurma qənaət olunur.

## 3. Dörd versiya

| # | Ad | Texnika | Mövzu | §4b | Codex şəkli |
|---|---|---|---|---|---|
| **1** | **Damla** | A — hündürlük izin içində | **Aqar:** indiki tünd firuzəyi, bitmiş | qorunur | maket + 12 |
| **2** | **Sütun** | B — qaldırılmış qapaq | **Gölməçə:** günəşli gölməçə damlası, zeytun lil, jele barabanlar, diatomlar, su otu | **pozur** | maket + 12 + kaustika |
| **3** | **Mağara** | A — 1 ilə eyni | **Biofilm:** tünd bənövşəyi mağara, döşəmə mikrobların altında zəif işıldayır | qorunur | maket + 12 |
| **4** | **Perspektiv** | C — əyik kamera | Aqar (1 ilə eyni, yalnız kamera fərqlidir) | **pozur** + kamera | maket + 3 sınaq |

Müqayisə məntiqi: **1 ↔ 3** eyni texnika, fərqli mövzu — mövzu tək başına
nə qədər dəyişir; **1 ↔ 4** eyni mövzu, fərqli kamera — əyik kamera nə qatır;
**2** "əsl Brawl Stars" paketi. Üç mövzu üç düzümə də uyğun gəlir (Halqalar =
Aqar, Arxipelaq = Gölməçə, Spiral = Biofilm) — Brawl Stars-ın hər xəritəyə
mövzu bağlaması kimi.

Seçilməyənlər: **Buz** (göy/firuzəyi mikrob rənglərinin üstünə düşür) və
**İsti bulaq** (kəhrəba "diqqət" kanalını — kövrək, cərəyan, quruyan zona —
silərdi).

Hər versiyada dörd növün qaydası FORMA ilə oxunur (rəng korluğunda da):
bütöv tünd kontur = bloklayır, konturu yoxdur + yarpaq = gizlədir, 9 kəhrəba
kəsik + burulğan = cərəyan, kəhrəba çat = sınır. Kövrəyin üç mərhələsi
ölçülə bilən hədəflərlə çəkilir: üst üzün kəhrəba payı 4–6 / 9–12 / 18–25 %,
s1-də bir, s2-də üç kənardan-kənara çat.

İnteraktivlik (hamısı kodla, kadr yox): kol yellənməsi və xışıltı (yalnız
GÖRÜNƏN mikrob üçün — gizlinin xışıltısı serverin gizlətdiyini ifşa edərdi),
selik topu səkdirəndə titrəmə, kövrəyin mərhələ dəyişməsi + qəlpələr + qalıcı
qırıntı, suda dalğa halqaları, cərəyan burulğanı, toxunanda sönən/parlayan
şüşə dodaq, vurulanda partlayan döşəmə qırıntısı. Versiya 2-də əlavə: iki
tezlikli su otu yellənməsi, köpük, kaustika; versiya 3-də: mikrobun altında
işıq gölməçəsi.

İstəyə bağlı oyun tile-ları (hər biri SİMULYASİYA dəyişikliyidir, heç bir
versiya onlardan asılı deyil): Osmos bulağı (müalicə yastığı), Fışqırıq
(atma yastığı), Məsamə cütü (teleport), Yapışqan ləkə (yavaşlatma), Axın
zolağı (sürətləndirmə).

## 4. Sahibin qərarları

1. **§4b:** selik və kövrəyin qapağı ayaq izindən çıxa bilərmi? (V2: ≤ 0.10 R /
   ≤ 16 px; V4: 0.14 R)
2. **Düzüm fırlanması:** indi canlı oyunda YALNIZ düzüm 0 oynanır —
   `DishMap.layout` server/şəbəkə kodunda heç yerdə seçilmir. "Hər düzümə bir
   mövzu" üçün server seçimi + handshake baytı lazımdır. Alternativ: mövzu
   müştəri ayarı olsun (server dəyişmir).
3. **Kolun rəngi:** indiki parlaq `#4FCB72` (BRAWL_UPGRADE §3.3 belə deyir) və ya
   `#3E9068`. İkincinin TONU nanə mikrobu ilə eynidir (151° / 150°), amma xeyli
   tünd və solğundur (V 0.56, nanə 1.0): HIGH-da parıldamır və döşəmənin yenə
   ən parlaq yaşıl kütləsi qalır. Briflər ikincisi ilə yazılıb.
4. **Şeyder siyasəti:** BRAWL_UPGRADE §6 "şeyder yox" deyir. İki kiçik
   `canvas_item` şeyderi (döşəmə makro×detal; kolun "deşiyi") HIGH/LOW-da
   gözəl olardı; hər şey onlarsız da işləyir.
5. **Perspektiv:** maketdən sonra 1 günlük prototip, yoxsa imtina.
6. **Oyun tile-ları** (§3 sonu): yol xəritəsinə girirmi?
7. **Toplar və nişan xətti kol yarpaqlarının üstündə** (F1 düzəlişi ilə birlikdə,
   bütün versiyalarda) — tövsiyə olunur, Brawl Stars-da da belədir.

## 5. Codex assetləri — necə çəkilib

Qovluq: [`map_art/`](map_art/).

| Fayl | Nə |
|---|---|
| `brief/STYLE_MAP.md` | Bütün xəritə çəkilişlərinin ortaq qaydaları: sima yox, cüt ləkə yox, yazı yox, işıq cümləsi, versiyanın proyeksiya cümləsi, kontur dili, dəyər tavanları, şəffaflıq tələsi |
| `brief/BRIEF_MAP_MOCKUPS.md` | Dörd versiyanın müqayisə kadrı |
| `brief/BRIEF_MAP_SHARED.md` | Mövzudan asılı olmayan beş asset (ağ-boz, oyunda boyanır) |
| `brief/BRIEF_MAP_V1..V4.md` | Hər versiyanın dəsti |
| `brief/PROMPTS_MAP_*.md` | Codex-in faktiki işlətdiyi promptlar (hesabat) |
| `template.gd` → `templates/` | 11 ölçü vərəqi — qırmızı = toqquşma dairəsi (512,512) r 384, göy = üst üz, ştrix = cənub bandı, sarı = V2-nin qalxma zonası; `template_strip_green` V3 üçün |
| `verify.ps1` | Hər PNG-ni ölçür: format, künc/mərkəz alfası, bbox, dəyər (p99, yarımşəffaf üçün p99_any, kəhrəbasız p99_noamber), kəhrəba payı, neytrallıq (spread, spread8), açar rəng, kolun boş mərkəzi |
| `resize.ps1` | image_gen-in 1254²-sini dəqiq 1024²-yə (və ya 1536×1024) gətirir — yalnız mütənasib, alfa qorunur, mənbənin formatını çap edir |
| `run_codex.sh` | Bir brifi `build/codex/<ad>/`-da işə salır (gpt-6-astra, reasoning max), WMI ilə ayrı prosesdə; köhnə iş qovluğunu kənara qoyur |
| `raw/<iş>/` | Codex-in qəbul olunmuş xam çıxışı; `raw/mockups/compare_versions.png` — dörd maket bir vərəqdə |

Niyə şablon: image_gen "dairə kətanın 75%-idir" sözünü hər dəfə başqa ölçüdə
çəkir. Bir dəstin maneələri isə eyni ölçü sistemində olmalıdır — tətbiqdə
pipeline hər şəkli toqquşma dairəsinə oturdacaq. Şablon `-i` ilə verilir və
"heç bir xəttini köçürmə" deyilir.

Niyə kölgə çəkilmir: hər bloklayan maneənin silueti EYNİ dairədir, yəni bir
kölgə/AO hüceyrəsi hamısına yarayır və işıq istiqaməti kodda dəqiq qalır.

## 6. Nəticələr

Hər işin faylları `map_art/raw/<iş>/`-də, faktiki promptlar
`map_art/brief/PROMPTS_MAP_<İŞ>.md`-dədir.

| İş | Vəziyyət | Fayllar |
|---|---|---|
| **Maketlər** | ✅ 4/4 (10 cəhd) | `raw/mockups/map_v1..v4_mockup.png` — 1536×1024 |
| **Ortaq** | ⚠️ 5/5, üçündə qeydiyyat qüsuru (aşağıda) | `raw/shared/`: floor_detail, vent_swirl, ripple, splash, debris — 1024² |
| **V1 Damla dəsti** | ✅ 12/12 (4 işdə, Codex limitləri arasında) | `raw/v1/`: mucus_blob, mucus_bloom, brittle_s0/s1/s2, brittle_rubble, bush_base, bush_canopy, vent_base, floor_macro, rim_north (1536×1024, maqenta açar), clutter (2×2) |
| V2 Sütun dəsti | ⏳ 12/13 (Codex limiti; 18 okt 04:42-də davam) | `raw/v2/`: mucus_blob (baraban), mucus_bloom (qurbağa kürüsü), brittle_s0/s1/s2 (diatom), brittle_rubble, bush_base, bush_canopy (su otu), vent_base (köpük bulağı), floor_macro (zeytun lil), rim_north (yosunlu şüşə; tikiş düzəlişi lazımdır), clutter; qalan: kaustika. Risk: diatom s0-ın badam sahəsi göz kimi oxuna bilər |
| V3 Mağara dəsti | gözləyir | 12 |
| V4 Perspektiv sınağı | gözləyir (V1-in sprite-larına istinad edir) | 3 |

Maketlər haqqında qeydlər:
- **V1** — təmiz və oxunaqlı; günbəzlər öz dairəsindədir, kol yeganə "yuxarı
  qalxan" şeydir. Ən sakit versiya.
- **V2** — ən çox Brawl Stars hissi: baraban qapağı bazasından bir az yuxarıdır,
  arxadakı qırmızı mikrobun konturu barabanın içindən görünür, açıq baza
  halqası əsl toqquşma dairəsini göstərir. Zeytun döşəmədə sarı/kəhrəba
  mikroblar ən zəif seçilir.
- **V3** — mikroblar (bənövşəyi və magenta da) ən yaxşı burada seçilir, çünki
  döşəmə ən tünddür.
- **V4** — kamera fərqi bir baxışda görünür: elliptik bazalar, cənub üzü,
  hündür uzaq divar.

V1 dəsti haqqında (ətraflı `PROMPTS_MAP_V1.md`-nin başında): lövbər damla Claude-un təsdiqi ilə
seçilib (cənub bandı ~120 px, hədəf 76); kövrəyin üç mərhələsi uzaqdan aydın seçilir, amma
qabıq brifdən tünddür (kömür, "soyuyan lava daşı" kimi) və s2 hədəfdən çox parlayır
(kəhrəba közü 8.6%, hədəf 3–5%) — HIGH-ın parıltısında yoxlanmalıdır; kol tacı ~1.2× böyükdür,
pipeline 0.83 kiçildəcək.

Maketlərə baxanda bilməli olduqlarınız (test 2026-10-02, ölçülüb) — bunlar konsept
kadrdır, dəstlər şablonla çəkilir, maketdən yox:
- **V1 ilə V4 fərqi maketdə bulanıqdır:** "düz yuxarıdan" olmalı V1-də dalğa
  halqaları və cərəyan dodağı artıq ellipsdir (0.78–0.87), V4 isə 0.82 əvəzinə
  0.62–0.66 sıxılıb. Oyunda qurulacaq V4 maketdən YUMŞAQ olacaq. V1-də şüşə divar
  zolağı da demək olar yoxdur (kadrın 4–11%-i, brif 15–20% istəyirdi).
- **V2-nin barabanı** sütun kimi yox, halqa üstündə asılı günbəz kimi oxunur:
  ön bant ilə baza halqası arasında 16–20 px döşəmə görünür. Brifdə ön bandın
  bazaya qədər enməsi indi ayrıca tələb olunur.
- Qabın xaricində (V1, V4, zəif V2/V3) **tikanlı, virusa bənzər fiqurlar** var,
  V4-ün uzaq divarında düz panel tikişləri, V2/V3-də yan-yana iki baloncuq (göz
  kimi) — briflərdə bunlar qadağandır; rim zolaqlarına "şüşənin arxasında heç nə
  yoxdur" yazılıb.
- Maketdə **qida** doymuş nanə rəngindədir (oyunda solğun `#D9FFC0`), cərəyan
  burulğanı tək qollu spiraldır (oyunda üç qol), V1 döşəməsi brifdən parlaq və
  firuzəyidir; V3-ün "işıq gölməçəsi" demək olar görünmür (oyunda kodla olacaq).
  Qidanın kontrastını və cərəyanın görünüşünü maketdən mühakimə etməyin.
- V1 maketində cərəyan dodağında 9 yox, 8 kəsik var.

Ortaq assetlər haqqında: Codex işin sonunda istifadə limitinə düşdü və
finalları seçə bilmədi. Codex namizədləri müxtəlif səbəblərlə rədd etmişdi
(ölçü, alfa tozu, qeydiyyat, faktura). Finalları Claude seçib `resize.ps1` ilə
1024²-yə gətirdi (başqa dəyişiklik yoxdur) — seçimin səbəbi
`PROMPTS_MAP_SHARED.md`-nin başındadır. Testin ölçdüyü qüsurlar — hamısını
pipeline avtomatik düzəldə bilər, yenidən çəkmək lazım deyil:

| Asset | Qüsur | Düzəliş (pipeline, §7 addım 2) |
|---|---|---|
| vent_swirl | Fırlanma mərkəzi (527,558)-dədir, (512,512) deyil — oyunda fırlananda ~10 ekran px yırğalanar; r 349-a çatır (brif 269); hər yerdə alfa 1–7 tozu | (-15,-46) sürüşdür, 0.82 kiçilt, alfa < 8 → 0, boz rəngə çevir |
| splash | r 504-ə çatır (brif 420), mərkəz halqası ~23 px aşağıdadır | (-5,-23), 0.82, alfa < 8 → 0 |
| debris | Parçalar hücrə mərkəzindən 199–238 px-ə çatır (brif 180); kontur ~9 px (brif 15) | hər hücrəni 0.76 kiçilt + mərkəzlə; konturu 4–6 px qalınlaşdır |
| floor_detail | Tikişsiz DEYİL (kənar sütunlar təsadüfi sütunlar qədər fərqlidir, 4.6 səviyyəlik pillə); 1.7% piksel ±6%-dən çıxır; 5 halqa hər kafeldə eyni yerdə | yarım sürüşmə + 64 px keçid, 113..143-ə sıxma; 3×3-də halqalar görünərsə ikisini sil |
| ripple | Brifə uyğundur | — |
| hamısı | Yarımşəffaf kənarlarda rəng izi (spread8 51–57) | R=G=B |

Testdən sonra briflərə əlavə olunanlar: image_gen ölçünü saxlamır (hər final
`resize.ps1` ilə dəqiq ölçüyə gətirilir, əvvəl isə toxunulmamış faylın alfası
yoxlanılır); `checker` yalnız məlumat üçündür; kol tacı, qırıntı, cərəyan, zolaq
və qırıntı vərəqi üçün AYRI yoxlama sətirləri (ümumi qayda düzgün tacı rədd
edirdi); kəhrəba payı indi ölçülür (`amber`, `amber_glow`); işıq cümləsindən
qadağan "face" sözü çıxarıldı; "iki çip / iki köz" əvəzinə tək sayda (cüt göz
kimi oxunurdu); image_gen bir çağırışda ən çox 5 istinad şəkli qəbul edir;
PROMPTS.md iş gedərkən yazılır (limit işi kəsə bilər).

## 7. Tətbiq planı (sonrakı iş)

Ardıcıllıq texniki hesabatın §8-indən:

1. BÜTÜN versiyalarda: F1 (kol z-sırası; toplar, izlər və `aim_guide`-ın üst
   qatı yarpaqların üstündə), öz mikrobun kolda alfa ~0.70 + rentgen konturu,
   F3 (halqa mesh-i), F2-nin `--perf` ilə yenidən ölçülməsi — dəqiqələrlik iş,
   ölçülə bilən qazanc.
2. Pipeline: `process.gd`-yə `obstacle` (dairəyə oturtma, maska, kontur, kölgə,
   L 512 / S 256 hüceyrə) və `atlas` (2048² səhifə + `manifest.json`) rejimləri;
   mərhələlər üçün delta-kompozit (s1/s2 yalnız dəyişən yeri s0-ın üstünə qoyur),
   zolaq və kafellər üçün tikiş düzəlişi; ortaq assetlər üçün mərkəzləmə, miqyas,
   alfa < 8 → 0 və boz rəng (§6 cədvəli).
3. Seçilən versiyanın dəsti → atlas kodu (`_spawn_obstacles` `region_rect`
   ilə), rim `Line2D`, döşəmə qatları (quruyan zona ayrıca node-a köçür, yoxsa
   döşəmənin altında qalar).
4. İnteraktivlik (§3).
5. V2 seçilərsə: qapaq qatı, xəyal halqası, qapağın altında qalan öz mikrobun
   rentgen konturu.

Hər addımdan sonra `--simtest` və `--perf` (pik ≤ 350 çəkiliş çağırışı).
`sim_test._test_blob_textures` hər növün iki ölçü sinfində hüceyrəsi olduğunu
yoxlamalıdır.
