# Performans araşdırması — qrafikadan heç nə itirmədən (2026-11-22)

Sahibin tapşırığı: qrafikadan heç nə itirmədən maksimum performansı necə əldə edə
biləcəyimizi araşdırmaq. Sonra Brawl Stars kimi oyunların qrafika menyusu olmadan zəif
telefonda necə yaxşı işlədiyini araşdırıb yazmaq. Hər rəqəm bu gün ölçülüb; ölçülməyən
təxminlər ayrıca "təxmin" kimi yazılıb.

---

## 1. Qısa nəticə

1. **Oyun bu gün bütün yeddi rejimdə sağlamdır.** APK emulyatorda (A04s ekranı,
   720×1600) 58.6–59.9 FPS verir, kadrın işi 4.9–6.8 ms-dir. Masaüstü release-də kadrın
   işi 1.05–1.44 ms-dir. Oktyabrdan bəri əlavə olunan rejimlər, koloniyalar, membran və
   mutasiyalar ortalamanı pisləşdirməyib.
2. **Bir real donma tapılıb və düzəldilib.** YAŞ ADA-da qab quruyan anda (0:20) palçığın
   shader-i matçın ortasında kompilyasiya olunurdu. Bu, masaüstündə 81 ms, emulyatorda
   75 ms davam edən bir kadr idi. İndi bu shader menyunun isinməsində kompilyasiya olunur.
   Yeddi rejimin heç birində matç zamanı yeni shader proqramı kompilyasiya olunmur.
3. **CPU tərəfində piksel dəyişmədən edilə biləcək böyük iş qalmayıb.** Skriptin işi
   onlarca kiçik funksiyaya paylanıb, ən böyüyü kadrda ~0.06 ms-dir (masaüstü). Render
   CPU-nun yarıdan çoxu mühərrikin sabit kadr xərcidir. Kiçik optimallaşdırmalar ölçü
   səs-küyündən aşağı qalır. Sahibin qaydasına görə ("faydası ölçülməyən dəyişiklik
   saxlanmır") onları etmədim.
4. **Ən böyük naməlum zəif telefonun GPU-sudur (Mali-G52).** Burada real telefon yoxdur.
   GPU-nun piksel sayına bağlı olduğu rejimdə (masaüstü, 3.2× piksel) **parlama keçidləri
   GPU vaxtının 31%-idir**. Bütün məzmun (mikroblar, xəritə, qida, HUD) cəmi ~9%-dir.
   Qalan ~60% sabit tam ekran keçidləridir.
5. **Brawl Stars** qrafikanı cihaza görə aşağı salmır. Kontent əvvəlcədən hazırlanır,
   mühərrik yalnız mobil üçün yazılıb, cihazla uyğunlaşan isə kadr sürətidir (30/60). Biz
   eyni yoldayıq: mikroblar, su zərrəcikləri və super effekti GPU-dadır, isinmə, fon
   yükləməsi və kadr ritmi də var. Qalan addımlar 6-cı bölmədədir.
6. **"Brawl Stars kimi həll" (8-ci bölmə).** Onların iki əsas üsulu bizdə hələ yoxdur:
   parlamanın əvvəlcədən bişirilməsi (GPU-nun 31%-i) və isti kodun native olması (C++).
   Birincisi görüntünü bir az dəyişir və A/B tələb edir. İkincisi piksel dəyişmir, amma
   böyük işdir. 3D modellər, gizli aşağı çözüm və dar formalar bizə ya uyğun deyil, ya da
   az verir.

---

## 2. Necə ölçüldü

| Alət | Nə ölçür |
|---|---|
| Kadr probu (`--frame-probe N`, repoda) | Yalnız canlı matç kadrları. Məşğulluq fizika, proses və render hissələrinə bölünür. 50 ms-dən uzun kadrlar ayrıca yazılır. |
| `--probe-phases` + skretç fazaları | Qatlar növbə ilə gizlədilir, hər qatın payı ölçülür. Skretçdə əlavə fazalar var idi: GPU taymeri, kontur keçidi, "hər şey gizli". |
| Shader keşinin zaman xətti (skretç) | Soyuq keşlə matç oynanır və hər proqram faylının yazılma anına baxılır. Kompilyasiya donmalarını tapmağın yeganə deterministik üsuludur. |
| Funksiya profileri (skretç) | 400-dən çox funksiya taymerlə bükülür. Kadrda funksiya başına µs və ağır kadrlarda ilk 10 funksiya yazılır. |
| Görünən element sayı və sprite örtüyü (skretç) | Qatlar üzrə canvas elementləri, sprite-ların ekran sahəsi və onun tam şəffaf texel payı. |

Platformalar:

- **Masaüstü:** release export, 1600×720, vsync söndürülüb, `--max-fps 0`. Kompüter:
  16 axınlı CPU, RTX 5050 Laptop.
- **Emulyator:** x86_64 release APK, `wm size 720x1600`, `density 280`, 60 Hz, hər
  qaçışdan əvvəl `pm clear`.
- **Onlayn:** skretç nüsxədən yerli WebSocket server, emulyator ona `adb reverse` ilə
  qoşulur.

Bütün skretç nüsxələr öz user qovluğu ilə işləyib (`GermArenaPerf`). Sahibin
`settings.cfg` faylına toxunulmayıb.

**Emulyatorun hədləri.** Emulyatorun CPU-su A04s-dən təxminən 4 dəfə sürətlidir (A04s
masaüstündən ~13 dəfə, emulyator ~3 dəfə yavaşdır). Emulyatorda hər GL çağırışı host-a
keçir, ona görə render CPU orada şişir. Emulyatorun GPU-su host-un NVIDIA kartıdır, yəni
Mali-nin GPU xərcini göstərmir. Emulyator shader-ləri NVIDIA sürücüsü ilə kompilyasiya
edir və sürücü onları öz diskində keşləyir. Ona görə kompilyasiya donması emulyatorda
yalnız ilk qaçışda görünür. Axşam boyu host-un sürəti dəyişdi: eyni APK 6.5 ms-dən
4.3 ms-ə düşdü. Ona görə yalnız növbəli A/B qaçışlar müqayisə olunur.

---

## 3. Bugünkü vəziyyət (ölçülüb)

### 3.1 Masaüstü, release, YÜKSƏK, avtomatik oyunçu

| Rejim | Kadrın işi | Proses | Render | Çəkiliş çağırışı (pik) |
|---|---:|---:|---:|---:|
| 0 SONSUZ | 1.15 ms | 0.29 | 0.86 | 84 |
| 1 TƏK QALAN | 1.05 ms | 0.33 | 0.71 | 86 |
| 2 CÜT | 1.08 ms | 0.32 | 0.76 | 74 |
| 3 ÜÇLÜK | 1.10 ms | 0.33 | 0.76 | 91 |
| 4 ANA HÜCEYRƏ | 1.05 ms | 0.28 | 0.77 | 98 |
| 5 YAŞ ADA | 1.30 ms | 0.42 | 0.88 | 89 |
| 6 NÜVƏ TOPU | 1.44 ms | 0.41 | 1.02 | 123 |

Heç bir rejimdə 50 ms-dən uzun kadr olmayıb.

### 3.2 Emulyator, APK, YÜKSƏK, 60 Hz (bütün rejimlər eyni saatda ölçülüb)

| Rejim | FPS | Kadrın işi (orta / p90 / p99) | Proses / render | 1% ən pis kadr | > 50 ms |
|---|---:|---|---|---:|---|
| 0 SONSUZ | 59.7 | 6.08 / 8.79 / 14.51 | 2.41 / 3.55 | 31.7 ms | yoxdur |
| 1 TƏK QALAN | 58.8 | 6.49 / 9.23 / 20.85 | 2.91 / 3.44 | 35.3 ms | 1 (proses 43 ms) |
| 2 CÜT | 58.9 | 6.35 / 9.36 / 15.71 | 2.90 / 3.31 | 35.6 ms | yoxdur |
| 3 ÜÇLÜK | 58.6 | 6.76 / 9.78 / 16.92 | 3.25 / 3.37 | 37.5 ms | yoxdur |
| 4 ANA HÜCEYRƏ | 59.1 | 6.32 / 8.89 / 17.26 | 2.28 / 3.91 | 34.0 ms | 2 |
| 5 YAŞ ADA | 59.0 | 6.84 / 9.60 / 17.83 | 2.97 / 3.72 | 35.9 ms | 2, biri 0:20-də **palçıq shader-i** |
| 6 NÜVƏ TOPU | 59.9 | 4.87 / 6.80 / 9.74 | 1.73 / 3.04 | 22.2 ms | yoxdur |
| Onlayn SONSUZ | 58.6 | 6.07 / 8.87 / 17.70 | 2.20 / 3.68 | 36.1 ms | 1 (2.1 s-də) |

Qalan tək-tək ilişmələr təkrarlanmır və hər dəfə başqa təsadüfi funksiyaya düşür. Onlayn
matçda 55.8-ci saniyədə 96 ms-lik bir render kadrı oldu. Emulyatorun öz shader keşi
həmin anda heç nəyin kompilyasiya olunmadığını göstərir. Bunlar host-un səs-küyüdür.
Əvvəlki sessiyalar da eyni şeyi qeyd edib.

### 3.3 Kadrın işi hara gedir

**Masaüstü, TƏK QALAN, qatlar növbə ilə gizlədilib:**

- Bütün kadr 0.99 ms-dir: proses 0.28, render 0.71, GPU 0.33 ms, 75 çağırış.
- **Demək olar hər şey gizlənəndə** (8 çağırış qalır) render yenə 0.45 ms-dir, GPU
  0.07 ms. Deməli render CPU-nun ~63%-i mühərrikin və sürücünün sabit kadr xərcidir.
  Məzmunun özü cəmi ~0.27 ms-dir.
- Parlama: CPU −0.11 ms, **GPU 0.34 → 0.18 ms**. GPU vaxtının ~yarısı parlamaya gedir.
- Qalan qatların hər biri ≤ 0.05 ms-dir.

**Emulyator, TƏK QALAN, eyni fazalar** (bu qaçışda bütün kadr 4.26 ms, 80 çağırış idi):

| Gizlədilən | Qazanc | Qeyd |
|---|---:|---|
| HUD | −0.63 ms | 37 çağırış: 4 yazı × 2, atəş düyməsi 8, super 5, minixəritə 4 |
| Mikrobların kontur keçidi | −0.34 ms | ayrıca SubViewport |
| Parlama | −0.11 ms | |
| Qida | −0.11 ms | |
| Xəritə | −0.09 ms | |
| Effektlər | −0.08 ms | |
| Mikroblar | −0.04 ms | |
| Hər şey | → 2.60 ms qalır | 8 çağırış: sabit xərc kadrın ~61%-i |

**Skript, masaüstü funksiya profileri:**

| İş | Xərc (masaüstü) | Qeyd |
|---|---:|---|
| Məşqin yerli dünyasının tick-i | **668–753 µs / tick** | sim.step 302–363 µs (qida 113–118, toplar 80–85, qidanın doğulması 53); botlar 32–47 µs / bot, 6–9 bot |
| Klientin öz tick-i | ~370 µs / tick | proqnoz, snapshot-un açılması, HUD |
| Mikrobların GPU sətirləri | 63 µs / kadr | ~16 µs / mikrob |
| Rəqib toplarının proqnozu | 51 µs / kadr | ~17 µs / top |
| Mikrobların interpolyasiyası | 41 µs / kadr | |
| `GermVisual._process` | ~10 µs / mikrob | |
| Mühitin animasiyası | 21 µs / kadr | |

Tick saniyədə 30 dəfədir, telefon isə 60 kadr çəkir. Ona görə tick hər ikinci kadra
düşür. Məşqdə yerli dünya orta hesabla kadrda ~0.35 ms aparır, yəni skript işinin ən
böyük hissəsidir. Emulyatorda p90 ilə p50 arasındakı fərq (+3–3.5 ms) məhz tick
kadrlarıdır.

**Səhnə:** kadrda 153–224 görünən canvas elementi var. Ən çox maneələrin qatındadır
(49–90), sonra qida (32), dekorlar (19), mikroblar (7–22) və HUD (13–16) gəlir.

**Şəffaf piksellər (GPU):** sprite-lar ekranın 0.47–0.81 qədərini örtür. Bunun **0.29–0.49
ekranı tam şəffaf texeldir**, yəni GPU onları heç nə dəyişmədən emal edir. Ən çoxu
maneələrin qatındadır (sprite-larının 56–65%-i şəffafdır).

**Təxmin (ölçülməyib):** CPU-da A04s masaüstündən ~13 dəfə yavaşdır. Bu, kadrın işi üçün
14–19 ms deməkdir: 30 kadr rahat tutulur, 60 kadr üçün sərhəddədir. GPU-da Mali-G52 MP1
RTX 5050-dən on dəfələrlə zəifdir. Masaüstünün 0.33 ms-lik GPU vaxtı orada bir neçə on
ms ola bilər. Bu çox kobud təxmindir, amma göstərir ki, A04s-də darboğaz GPU ola bilər.
Bunu yalnız real telefon deyə bilər.

---

## 4. Bu gün edilən düzəliş

**YAŞ ADA-da qab quruyanda donma.** `island_dry.gdshader`-in qatı 0:20-yə qədər gizlidir.
İsinmənin siyahısında yalnız mikrob, super, döşəmə və nazik xətlər var idi. Ona görə
palçığın shader-i məhz rejimin ən gərgin anında, qab quruyanda kompilyasiya olunurdu.

- **Dəyişiklik:** `GermGPU.warm_up` palçığı da öz kadrında, ekrandan kənarda çəkir.
  Arena onu çoxbucaqlı kimi çəkir (`_build_island`), isinmə də elə çəkir. Düzbucaqlı
  shader-in başqa variantını kompilyasiya edərdi. Shader resursu saxlanılır, arenanın
  `preload`-u eyni resursu alır.
- **Fayllar:** `germ_gpu.gd`, `sim_test.gd` (yeni yoxlama), README, PERF_PLAN.
- **Yoxlama:**
  - Soyuq keşlə YAŞ ADA-da həmin proqram (`84c09366…`) əvvəl matçın 20-ci saniyəsində
    yazılırdı. İndi isinmədə yazılır və 4.5 s-dən sonra heç bir yeni fayl yoxdur.
  - Digər rejimlərdə (məşq 45 s, onlayn 90 s) matçda yeni proqram yoxdur.
  - Kadrın işi dəyişmir. Emulyatorda növbəli A/B: yeni 4.39–4.57, köhnə 4.50–4.70 ms.
  - Menyunun kadrları masaüstündə hər iki variantda eynidir (ən pis 4.5–4.7 ms).
  - Testlər: sim_test 1057/0 (HEAD-də 1056/0, üstəgəl yeni yoxlama), obyekt testləri
    119/0.
  - QA agenti masaüstündə YAŞ ADA və SONSUZ-da işlədilib. APK-da (emulyator) YAŞ ADA iki
    dəfə yoxlanılıb, shader xətası yoxdur. Agentin tək-tək "basıldı, işə düşmədi"
    qeydləri köhnə APK-da da var, yəni bu dəyişiklikdən deyil.
- **Real telefonda:** Godot proqramları diskdə saxlayır. Ona görə bu donma oyunçuda
  quraşdırmadan və hər yeniləmədən sonra ilk YAŞ ADA matçında olurdu, Mali-də isə
  emulyatordan uzun.

Commit edilməyib.

---

## 5. Yoxlanıb və rədd edilib (ya da dəyməz)

| Fikir | Nəticə |
|---|---|
| Render-i ayrıca axında aparmaq (`rendering/driver/threads/thread_model = Separate`) | Godot 4.7 bunu "eksperimental" adlandırır. Bizim layihədə açılışda çökür (`FATAL: Index p_index = 0 is out of bounds`). İşlətmək olmaz. |
| HUD-un çağırışlarını azaltmaq | Artıq birləşdirilib (BatchDraw). Qalan çağırışlar şrift teksturalarındandır: hər ölçü və kontur ayrı teksturadır. MSDF 2026-10-19-da şriftlərin qüsuruna görə rədd edilib. |
| Skriptdə kiçik optimallaşdırmalar (sətirlərin yığılması, mühitin animasiyası, qida) | Hər biri masaüstündə 10–25 µs-dir, emulyatorun A/B səs-küyündən (±0.3 ms) aşağıdır. Faydası göstərilə bilmir. |
| Rəqib toplarının proqnozunu sadələşdirmək | Bu, zərbənin düzgünlüyünün kodudur, hər sətri ölçülmüş bir səhvi düzəldir. Qazanc kiçikdir, risk böyükdür. |
| Botların düşünməsini seyrəltmək | Masaüstündə tick-də ~0.2 ms qazanc verərdi, amma botların reaksiyasını dəyişir. Bu, oyun qərarıdır, qrafika yox. |
| Fizika tick-ini 60-dan 30-a endirmək | Şəbəkə (`multiplayer.poll`) fizika kadrında işləyir. Snapshot-lar 33 ms-ə qədər gec oxunardı. |
| Parlamanın səviyyələrini dəyişmək, HDR-i söndürmək | Pikseli dəyişir. HDR ilə 2D qarışdırma xətti rəng fəzasındadır. |
| Digər rejimlərdə gec kompilyasiya | Axtarıldı, yoxdur (yeddi rejim, məşq və onlayn). |

---

## 6. Qalan imkanlar: piksel dəyişmədən, təsir sırası ilə

1. **Real zəif telefonda ölçü (F0 — sahibin 4-cü qərarı).** Ən böyük naməlum Mali GPU-dur.
   İşlənmiş Galaxy A04s/A13 (Exynos 850) bəsdir. Arm Performance Studio pulsuzdur,
   Streamline CPU-nu, Frame Advisor GPU kadrını göstərir. Android GPU Inspector da hər
   çəkiliş çağırışının GPU vaxtını verir. Aşağıdakı 2-ci və 3-cü bəndlərin qazancı yalnız orada sübut olunur.
2. **Şəffaf hissələri çəkməmək (dar çoxbucaqlılar).** Hər kadrda ekranın 0.29–0.49 qədəri
   tam şəffaf texeldir, ən çoxu maneələrin qatındadır. Sprite-ı dörd küncdən yox, şəkilin
   konturu ilə kəsilmiş çoxbucaqlı ilə çəkmək pikseli dəyişmir. Şəffaf texel heç nə
   əlavə etmir. Kontur bilinear süzgəcə və mipmap-a görə 1–2 texel ehtiyatla genişlənməlidir.
   Qiyməti hər sprite-a bir neçə təpədir (CPU). Supercell-in `.sc` formaları da belə
   kəsilir. **Yenidən ölçülüb (8.2):** 3.2× pikseldə bütün məzmun GPU-nun cəmi ~9%-idir,
   yəni kəsmə ən çox ~4–5% verər. Prioritet aşağıdır.
3. **Məşqin dünyasını ayrı axına köçürmək.** Məşqdə hər tick ~0.7 ms (masaüstü),
   A04s-də təxminən 9 ms ana axında gedir. Bunu `WorkerThreadPool`-a köçürmək olar,
   amma onda yerli dünya bir tick (33 ms) geridən cavab verər, onlayndakı kimi. Proqnoz
   buna hazırdır, amma məşqə xas bir neçə yer "dünya eyni tick-də cavab verir" fərziyyəsi
   ilə yazılıb. Bu, oyun hissinə toxunur, ona görə sahibin qərarıdır. Onlayn rejimə
   təsiri yoxdur.
4. **Tick kadrlarını yüngülləşdirmək.** Tick kadrları adi kadrdan +3–3.5 ms ağırdır
   (emulyator). Hər kadr lazım olmayan HUD yeniləmələri tick-siz kadra keçirilə bilər.
   Qazanc kiçikdir (≤ 0.3 ms emulyatorda). Real telefonda p90 ölçüləndən sonra dəyər.
5. **Vulkan (Mobile) render (sahibin 2-ci qərarı).** Shader Baker (ixracda kompilyasiya),
   Swappy (dəqiq kadr ritmi) və pre-rotation (Android-in fırlatma keçidi düşür) verir.
   Parlamanın implementasiyası başqadır, yəni piksellər bir az dəyişə bilər. A/B lazımdır.

**Pikseli dəyişən, amma ən böyük GPU qazancı verən iki addım** (yalnız A/B şəkil və
sahibin təsdiqi ilə):

- **F2, billboard parlama.** Masaüstündə GPU vaxtının ~yarısıdır. Mali-də tam ekran
  bulanıqlıq keçidləri və RGBA16F bufer bundan da bahadır.
- **Xəritə teksturalarını ASTC-yə sıxmaq.** Bu gün itkisizdir, menyuda ~34 MB
  videoyaddaş tutur. ASTC 4×4 yaddaşı və zolağı 4–8 dəfə azaldır, amma itkili sıxmadır.

---

## 7. Brawl Stars kimi oyunlar qrafika menyusu olmadan zəif telefonda necə işləyir

### 7.1 Faktlar (mənbələrlə)

- **Öz mühərriki — Titan.** Supercell-in bütün oyunları onunla işləyir. O, yalnız mobil
  üçün qurulub və ayda 300 milyon oyunçuya xidmət edir. Supercell-in dediyinə görə hədəf
  ən bahalı telefon deyil: hələ də kiminsə Clash Royale oynadığı ən köhnə, ən ucuz
  Android telefonudur. Mühəndislərinin sözü ilə, yalnız mobilə ixtisaslaşmaq Unity və
  Unreal-da lazım olan "mobil üçün optimallaşdırma" işinin çoxunu aradan qaldırır.
  ([PocketGamer.biz](https://www.pocketgamer.biz/supercells-titan-engine-spanning-flagships-to-the-cheapest-oldest-android-handset-in-the-world/))
- **Problemi kontentdə yox, mühərrikdə həll edirlər.** Köhnə Android-də Brawl Stars
  ~35 s yüklənirdi, matç isə ~3 dəqiqədir. Yükləmə ardıcıl "yüklə, gözlə" zəncirinə
  çevrilmişdi. Komanda asılılıqları xəritələyib, yükləməni növbəyə qoyub və bir neçə işçi
  axınında paralel aparıb. Serverin erkən mesajları üçün bufer əlavə olunub, çünki
  onlar əvvəl oyunu çökdürürdü. Nəticə: 35 s → 5–6 s (iPhone-da 7 → 2.5 s). Logo
  animasiyası gündə bir dəfəyə endirilib. İş ~4 ay çəkib, ilk buraxılışda çökmə artımı
  olub və düzəldilib.
  ([Supercell](https://supercell.com/en/news/titan-game-engine/),
  [Gamigion](https://www.gamigion.com/brawl-stars-loading-time-was-killing-player-sessions/))
- **Görüntü əvvəlcədən hazırlanır.** Bu bölmə 2026-10-17-də PERF_PLAN §1.1-də toplanıb.
  2D məzmun (UI, VFX, üz animasiyası) Adobe Animate-dən `.sc`-yə çıxarılır: atlas,
  formalar və matrisli animasiya klipləri. İşləmə vaxtında filtr yoxdur, parlama
  teksturaya bişirilir. 3D modellər animasiyası ilə birlikdə hazır gəlir. Mənbə icmanın
  tərs mühəndislik alətləridir, rəsmi sənəd yoxdur.
- **Qrafika yox, kadr uyğunlaşır.** 2026-10-17-də oxunan dəstək səhifəsində oyunçuya
  verilən əsas seçim kadr həddi idi. Səhifəyə görə oyun batareya qənaətində 30-a keçir
  və sabit 30-u dəyişkən 30–60-dan hamar sayır. Bu gün səhifə avtomatik oxumanı rədd
  etdi (HTTP 403). Axtarışın göstərdiyi parçalar eyni şeyi deyir: batareya azalanda və ya
  qənaət rejimində kadr həddi 30-a düşür, qrafika seçimləri yalnız Android-dədir və bəziləri
  cihazın aparatından asılıdır. Səhifənin hansı oyuna aid olduğu parçalarda yazılmayıb.
  ([dəstək səhifəsi](https://support.ftgames.com/hc/en-us/articles/7918056936721-How-can-I-change-my-graphics-settings))
- **Büdcə və cihaz çeşidi iş tələbidir.** Supercell-in render vakansiyalarına görə mühəndis
  CPU, GPU, yaddaş, yükləmə və kadr vaxtını geniş iOS və Android cihaz çeşidində profil
  edir, aşağı səviyyəli aparatda performansı saxlamalıdır.
  ([vakansiya](https://supercell.com/en/careers/senior-engine-programmer-rendering-clash-royale/f49ebe91-f999-4f8b-84d1-29c801b38a71/))

### 7.2 Bunlardan çıxan prinsiplər

1. **Zəif cihaz dizaynın hədəfidir, sonradan düşünülən şey deyil.** Büdcə ən zəif
   telefona görə qoyulur. Güclü telefon əlavə kadr alır, əlavə qrafika yox.
2. **İşləmə vaxtı yalnız ucuz iş qalır.** Atlasdan üçbucaqlar, matris və rəng
   çevrilmələri. Bulanıqlıq, filtr və parlama əvvəlcədən hazırlanır.
3. **Ağır işi bir dəfə görmək:** shader-lər, yükləmə və meşlər oyunçu gözləyəndə yox,
   ondan əvvəl hazırlanır.
4. **Mühərrikin sistemini dəyişməkdən qorxmamaq.** Yükləmə problemi bir oyunda deyil,
   mühərrikdə həll olundu.
5. **Kadr siyasəti:** sabit 30 titrəyən 60-dan yaxşıdır. Batareya azalanda və telefon
   qızanda 30-a keçilir.

### 7.3 Biz harada dayanmışıq

| Prinsip | Bizdə |
|---|---|
| Ağır görüntü GPU-da | Edilib: mikroblar (F1), su zərrəcikləri və super effekti (F3) |
| Shader-in əvvəlcədən kompilyasiyası | Edilib. Bu gün YAŞ ADA da əlavə olundu, matçda yeni proqram yoxdur. |
| Fon və paralel yükləmə | Edilib: arena və xəritə fonda yüklənir, OYNA bloklanmır (F6). Titan-ın 35 → 5 s işinin eyni ideyası. |
| Kadr siyasəti (30/60, batareya, istilik) | Edilib: FramePacer (F5) |
| Filtrsiz parlama (bişirilmiş/billboard) | Yox. F2, sahibin A/B qərarı. GPU-nun ən böyük xərci. |
| Dar formalı sprite-lar (az şəffaf piksel) | Yox. Piksel dəyişmir, amma ölçüyə görə az verir (~4–5% GPU, 8.2). |
| Ən zəif cihazda ölçü və büdcə | Yox. Real telefon lazımdır (F0). |
| Native (C++) isti kod | Yox. Mühərriki dəyişmək lazım deyil, amma məşqin yerli dünyası A04s-də ən böyük skript işidir (8.1). |

---

## 8. Brawl Stars kimi həll edə bilərikmi?

Qısa cavab: **qismən bəli.** Onların yolunun üç hissəsi var:

1. Mühərrik və isti kod native-dir.
2. Görüntü əvvəlcədən hazırlanır, yəni işləmə vaxtında tam ekran filtri yoxdur.
3. Cihaza görə yalnız kadr sürəti uyğunlaşır.

Üçüncünü artıq edirik. Birinci və ikincinin bizə uyğun gələn iki hissəsi hələ yoxdur:
parlamanı bişirmək və məşqin dünyasını native etmək. Onlarsız zəif Mali-də Brawl Stars
səviyyəsinə çatmaq çətin olacaq. Supercell-in öz mühərrikini yazmaq isə bizim yolumuz
deyil (PERF_PLAN §7, "Mühərriki dəyişmə"). Ölçülər problemin Godot-un özündə olmadığını
göstərir: problem parlama keçidlərində və yerli dünyanın GDScript-dəki tick-indədir.

### 8.1 Texnika-texnika

| Brawl Stars nə edir | Bizdə | Ölçü / təxmin | Görüntüyə təsiri | Qərar |
|---|---|---|---|---|
| **Tam ekran filtri yoxdur, parlama teksturaya bişirilir** | Godot-un parlaması: tam ekran bulanıqlıq keçidləri | **GPU-nun 31%-i** (3.2× piksel: 1.29 → 0.89 ms); emulyatorda render CPU −0.11 ms | Bir az dəyişir: halo-nun forması tam eyni olmur | **Ən böyük addım.** Prototip + A/B şəkillər, sonra sənin qərarın |
| **İsti kod native-dir (C++)** | GDScript. Məşqin yerli dünyası hər tick-də 0.67–0.75 ms (masaüstü), klientin isti funksiyaları ~0.3 ms / kadr | Təxmin: A04s-də məşq kadrına ~4–5 ms qazanc (orta), tick kadrında ~9 ms | Piksel dəyişmir | Böyük iş: `Sim` serverlə ortaqdır, C++ versiyası hər iki tərəfdə EYNİ olmalıdır (GDExtension: Android, Linux server, Windows; brauzerdə GDScript ehtiyatı). Əvvəl məşqin dünyası |
| 3D modellər, hazır animasiya | 2D prosedur mikrob, GPU-da | 3D prototip ölçülüb (2026-10-28): emulyatorda render CPU 5.6–16 ms, 2D-də 0.65–1.1 ms; masaüstündə 2.26 / 1.13 ms | Görüntü başqa olar | **Rədd.** Godot-un Compatibility render-ində 3D bizə 5–15 dəfə baha başa gəlir |
| Atlas, dar kəsilmiş formalar (`.sc` Shape) | Dördbucaq sprite-lar, ekranın 0.29–0.49-u şəffaf texeldir | 3.2× pikseldə BÜTÜN məzmun GPU-nun ~9%-i, kəsmə ən çox ~4–5% verər | Piksel dəyişmir | Aşağı prioritet |
| Sabit 30 / 60, batareyada və qızanda 30 | FramePacer | — | Yoxdur | Edilib |
| Paralel yükləmə, serverin erkən mesajları üçün bufer | Fon yükləməsi, reyestr buferi (`_buffer_roster`) | — | Yoxdur | Edilib |
| Zəif telefonda gizli aşağı çözüm / dinamik çözüm (yalnız üçüncü tərəf iddiaları, rəsmi deyil) | Yoxdur | — | Görüntü itir | Sahibin qaydasına ziddir, etmirik |
| Cihaz laboratoriyası və CPU/GPU/yaddaş/batareya büdcəsi (Supercell-in render vakansiyaları bunu tələb edir) | Yoxdur | — | — | Real telefon lazımdır (F0) |

### 8.2 Ölçü: GPU vaxtı hara gedir

Masaüstünün GPU-su telefon deyil. Amma piksel sayı çox olanda o da piksel sayına bağlı
işləyir, zəif telefon kimi. Onda xərclərin nisbəti telefona yaxın olur. Ölçmə 2560×1440-də
aparılıb (1600×720-dən 3.2 dəfə çox piksel), TƏK QALAN rejimində, fazalar 5 dövr boyu
növbə ilə gedib:

| Faza | GPU | Fərq |
|---|---:|---:|
| Hamısı açıq | 1.29 ms | — |
| Parlama söndürülüb (HDR bufer qalır) | 0.89 ms | **−31%** |
| HDR bufer söndürülüb (parlama qalır) | 1.25 ms | −3% |
| Döşəmə gizli | 1.23 ms | −5% |
| Maneələr və kol yarpaqları gizli | 1.27 ms | −2% |
| Bütün məzmun gizli (mikroblar, xəritə, qida, zərrəciklər, HUD; 11 çağırış qalır) | 1.17 ms | −9% |

1600×720-də parlamanın payı daha da böyükdür: 0.37 → 0.20 ms (−46%).

Nəticə: GPU vaxtının ~60%-i sabit tam ekran keçidləridir (döşəmə, HDR-dən ekrana keçid,
kontur), ~31%-i parlama keçidləri, cəmi ~9%-i məzmundur. Yəni GPU-da mikrobları və
xəritəni daha da sadələşdirməyin mənası yoxdur. Böyük qazanc yalnız parlamadadır.
Brawl Stars-da məhz bu keçidlər yoxdur. Mali-də tam ekran keçidlərinin yaddaş zolağı
masaüstündən baha olduğu üçün orada pay daha böyük ola bilər (ölçülməyib).

### 8.3 Bizim üçün "Brawl Stars yolu": təklif olunan ardıcıllıq

1. **Real telefon (Exynos 850).** Aşağıdakı iki addımın qazancı orada təsdiqlənir.
2. **Bişirilmiş parlamanın prototipi (F2).** Hər parlayan obyekt (mikrob, qida, top,
   effekt) əvvəlcədən bulandırılmış, additive qarışan halo alır. Godot-un parlaması
   söndürülür, HDR bufer QALIR, yəni rənglərin qarışması dəyişmir. İndiki görüntü ilə
   yan-yana A/B şəkillər hazırlanır, qərarı sən verirsən. Təxmini qazanc halo-ların öz
   xərci çıxılandan sonra GPU-nun ~25–30%-idir.
3. **Məşqin dünyası C++-da** (GDExtension) və ya ayrı axında (sonuncu dünyanın cavabını
   bir tick gecikdirir). Piksel dəyişmir, məşqdə A04s-də kadra ~4–5 ms qazanc verər
   (təxmin).
4. **Qalan GDScript isti nöqtələri C++-a** yalnız real telefonun profili göstərsə.

---

## 9. Sahibin qərarı lazım olanlar

1. Bir Exynos 850 telefonu almaq: ən vacib addımdır. Qalan GPU qərarları ona əsaslanacaq.
2. Bişirilmiş parlamanın (F2) prototipi və A/B şəkillər hazırlansınmı? Brawl Stars-ın
   üsuludur və GPU-nun ən böyük xərcidir.
3. Məşqin dünyası C++-a köçsünmü, yoxsa ayrı axına (bir tick gecikmə ilə)?
4. Dar çoxbucaqlı sprite-lar: ölçüyə görə az verir (~4–5%), real telefondan sonraya qalsın.
5. Vulkan Mobile üçün A/B.

---

## 10. Mənbələr

- Supercell, Titan və Brawl Stars-ın yükləməsi: https://supercell.com/en/news/titan-game-engine/
- PocketGamer.biz, Titan: https://www.pocketgamer.biz/supercells-titan-engine-spanning-flagships-to-the-cheapest-oldest-android-handset-in-the-world/
- Gamigion: https://www.gamigion.com/brawl-stars-loading-time-was-killing-player-sessions/
- Supercell dəstəyi, qrafika ayarları (bu gün 403, 2026-10-17-də oxunub): https://support.ftgames.com/hc/en-us/articles/7918056936721-How-can-I-change-my-graphics-settings
- Supercell, render mühəndisi vakansiyası (Clash Royale): https://supercell.com/en/careers/senior-engine-programmer-rendering-clash-royale/f49ebe91-f999-4f8b-84d1-29c801b38a71/
- 3D prototipin ölçüləri: `design/proto3d/README.md`
- Dar sprite meşləri və şəffaf piksellər: https://www.codeandweb.com/texturepacker/tutorials/optimizing-unity-sprite-meshes ,
  https://gamedev.net/tutorials/programming/graphics/oops-are-your-unity-sprites-too-tight-r5501
- Godot, GPU optimallaşdırması: https://docs.godotengine.org/en/latest/tutorials/performance/gpu_optimization.html
- Arm, Mali-də ən yaxşı təcrübələr və Performance Studio: https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/arm-mali-best-practices ,
  https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/finding-and-fixing-hidden-performance-problems-in-mobile-games-with-arm-performance-studio
- Android, Godot-un Vulkan işi (pre-rotation): https://developer.android.com/stories/games/godot-vulkan
- Əvvəlki mənbələr (`.sc`, Nordeus, ADPF, Swappy): `design/PERF_PLAN.md` §8.
