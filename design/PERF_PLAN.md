# YÜKSƏK qrafika ilə Brawl Stars səviyyəsində performans — həll planı

**v2, 2026-10-17.** Sahibin tələbi:

1. **Qrafikadan güzəşt yoxdur.** Hamı bugünkü YÜKSƏK görüntünü görür: tam kirpiklər,
   kontakt kölgəsi, spekulyar, rim, parlama (glow), 80+30 su zərrəciyi, axın
   cizgiləri, effektlərin tam sayı.
2. **Oyun APK kimi oynanır** (Android; iOS sonra). Brauzer yalnız sınaq üçündür:
   orada performans hədəfi yoxdur, sadəcə işləməlidir.

Bu tələblər v1-i (MİNİMUM və brauzer üzərində qurulmuş planı) əvəz edir.
`design/ART_BIBLE.md` və `design/BRAWL_UPGRADE.md` MƏNBƏDİR: burada heç bir görüntü
qərarı dəyişmir. Dəyişən yalnız görüntünün HARADA hesablandığıdır.

---

## 0. Əsas fikir

Bizim oyun **prosessorda (CPU) ilişir, GPU-da yox.** Hər mikrob hər kadrda
GDScript-də nöqtə-nöqtə qurulur və GPU-ya yeni poliqonlar kimi göndərilir. Brawl
Stars və digər mobil hit-lər isə görüntünü ya **əvvəlcədən hazırlayır** (modellər,
teksturalar), ya da **GPU-da hesablayır** (shader-lər). Prosessor hər kadrda
yalnız bir neçə ədəd ötürür.

Ona görə "heç nə itirmədən sürət" mümkündür: **NƏ çəkildiyini deyil, HARADA
hesablandığını** dəyişirik. Qrafika heç vaxt avtomatik enmir. Cihaza uyğunlaşan
yeganə şey kadr sürətidir (60 ↔ 30) — Brawl Stars da elə edir.

---

## 1. Digər oyunlar bunu konkret necə edir

### 1.1 Supercell (Brawl Stars, Clash Royale)

- **Öz mühərriki — Titan.** Native koddur; Supercell-in bütün oyunları onunla
  işləyir.
- **2D məzmun əvvəlcədən hazırlanır.** UI, VFX, hissəciklər və personajların üz
  animasiyaları Adobe Animate-dən `.sc` formatına çıxarılır. İçində forma
  (Shape), animasiya klipi (MovieClip) və TexturePacker-lə yığılmış atlas var.
  İşləmə vaxtında yalnız atlasdan götürülmüş üçbucaqlar, matris və rəng
  çevrilmələri qalır. (İcmanın tərs mühəndislik alətlərinə görə; rəsmi sənəd yoxdur.)
- **İşləmə vaxtı filtr yoxdur.** `.sc` eksportu filtrləri (blur, glow)
  dəstəkləmir — parlama teksturaya **bişirilir**, ekranda bulandırılmır.
- **3D modellər** `.scw` formatındadır, yeni build-lərdə `.glb` də var. Mühitin
  animasiyası modelin içindədir.
- **Kadr siyasəti:** kadr həddini oyunçu seçir. Batareya azalanda və ya qənaət
  rejimində oyun özü 30-a keçir. Supercell sabit 30 kadrı dəyişkən 30–60-dan hamar
  sayır. Qrafika yox, **kadr** uyğunlaşır.

### 1.2 Nordeus (Spellsouls) və Arm — parlama tam ekran keçidsiz

Mobil GPU-lar (Mali daxil) ekranı kafel-kafel çəkir, ona görə tam ekran keçidləri
(bloom, blur) bahadır. Arm-ın Spellsouls yazısında aşağı səviyyəli cihazlar üçün
ən ucuz üsul **billboard** üsuludur: hər parlayan obyektin arxasına əvvəlcədən
bulandırılmış, əlavə (additive) qarışan sprite qoyulur. Daha güclü cihazlar üçün
aşağı ölçülü ayrıca işıq keçidi var.

### 1.3 Android-in rəsmi oyun alətləri (Unity, Unreal, Cocos bunları işlədir)

- **ADPF Performance Hint:** oyun hər kadrın hədəf və real müddətini sistemə
  bildirir. Android buna görə nüvə tezliyini düzgün seçir — xüsusən yalnız kiçik
  nüvəli telefonlarda (A04s) kadr titrəməsini azaldır.
- **ADPF Thermal API** (`getThermalHeadroom`): telefon qızmağa başlamazdan ƏVVƏL
  xəbər verir. Oyun yükü əvvəlcədən azaldır, sonra "boğulmur".
- **Game Mode API:** oyunçunun sistemdə seçdiyi "performans / batareya" rejimi.
- **Swappy (kadr ritmi):** 90 Hz ekranda 30 kadr dəqiq hər 3-cü vsync-də gəlir.
  Godot 4.4-ün inkişafı zamanı Android Vulkan yoluna əlavə olunub.

### 1.4 Hamının işlətdiyi texnikalar

- Atlas, batching, instancing (Arm Mali tövsiyələri).
- Animasiya vertex shader-də: GPU skinning, külək və titrəmə shader-ləri, MultiMesh.
- Hissəciklər GPU-da.
- Shader-lərin əvvəlcədən kompilyasiyası: Godot 4.5 Shader Baker, Unity warm-up,
  Unreal PSO keşi.
- Obyekt hovuzları.
- Test cihazları və kadr büdcəsi.

---

## 2. Bu gün — ölçülmüş vəziyyət (2026-10-17)

Ssenari: onlayn SONSUZ ARENA, ekranda 2–3 mikrob.

| | YÜKSƏK | MİNİMUM |
|---|---:|---:|
| Masaüstü native, kadrın işi | ~4.1–4.5 ms (render 2.5–2.7) | 2.6–3.2 ms (render 1.4) |
| Masaüstü native, kadrda çəkiliş çağırışı | 180–280 | 106–185 |
| APK, Android emulyatoru, CPU kadr başına | **20–24 ms**, 60-ı tutmur (44–46 FPS) | 11–12 ms, 30 sabit |
| Emulyatorda bunun GDScript hissəsi | 17–18 ms | 7–8 ms |

**YÜKSƏK-in əsas xərcləri** (masaüstü native):

| Nə | Xərc | 10 mikrobluq döyüşdə | A04s-də (×13) |
|---|---:|---:|---:|
| Tam detallı mikrob `_draw` | ~0.3 ms / mikrob | ~3 ms | ~39 ms |
| Su zərrəcikləri (80+30) | 0.17 ms | 0.17 ms | ~2 ms |
| Mühərrikin render-i (kirpik lentləri, glow) | 2.5–2.7 ms | ~4 ms | ~50 ms |

**Təxmin:** A04s-də APK bu gün YÜKSƏK-də **~10–17 FPS**, MİNİMUM-da 20–25 FPS verir.
Masaüstü A04s-dən ~13 dəfə sürətlidir, emulyator isə masaüstündən ~3 dəfə yavaşdır.
Rəqəmlər real telefonda təsdiqlənməlidir (F0).

---

## 3. Hədəflər

| Cihaz sinfi | Bu gün, APK, YÜKSƏK | Hədəf, YÜKSƏK |
|---|---|---|
| Zəif: Galaxy A04s / A13 / A14 (Exynos 850) | ~10–17 FPS | **sabit 30**, telefon soyuq olanda 60 |
| Orta: Helio G85, Snapdragon 680 | ~20–35 FPS | **sabit 60** |
| Güclü | 60 | 60, seçimlə 90/120 |

Büdcə: A04s-də 30 kadr = 33 ms. 20% ehtiyatla CPU üçün 26 ms qalır, bu da
masaüstü native-də **≤ 2.0 ms** deməkdir. A04s-də 60 kadr üçün ≤ 1.0 ms lazımdır.

| Alt sistem (masaüstü native, YÜKSƏK, 10 mikrob) | Bu gün | Büdcə |
|---|---:|---:|
| Mikrobların görüntüsü (CPU) | ~3 ms | 0.15 ms |
| Mühərrikin render-i | ~4 ms | 0.8 ms |
| Arena məntiqi (render fazası, tick, snapshot) | ~0.8 ms | 0.5 ms |
| Zərrəciklər, effektlər, HUD | ~0.4 ms | 0.15 ms |
| Kadrda çəkiliş çağırışı | 250+ | ≤ 50 |

---

## 4. Mərhələlər

Sıra təsirə görədir. Hər mərhələ F0-ın ölçü ssenarisi ilə başlayır və bitir.
Qazanc göstərməyən dəyişiklik geri qaytarılır.

### F0 — Ölçü və cihaz laboratoriyası (2–3 gün)

Supercell kimi studiyalar performansı real zəif cihazda, büdcə ilə idarə edir.

1. **Cihazlar:** bir Exynos 850 telefon (A04s/A13/A14) və bir orta telefon
   (Helio G85 və ya Snapdragon 680). İşlənmiş aparat ucuzdur; emulyasiyanın
   təxminlərini əvəz edir.
2. **Alətlər:**
   - Godot-un uzaqdan profileri (telefonda);
   - Android GPU Inspector və ya Arm Performance Studio (Streamline — CPU,
     Frame Advisor — GPU kadrı);
   - Perfetto (kadr ritmi, nüvə tezlikləri, istilik).
3. **Kadr probu repoya:** `scripts/tools/frame_probe.gd` + `--frame-probe N`.
   Kadrı fizika, məntiq və render hissəsinə bölür, `--probe-phases` ilə qatları
   növbə ilə gizlədib payını ölçür.
4. **Təkrarlanan ssenari:** `--seed N` `Sim.rng` (`sim.gd:294`) və `Bot._rng`
   (`bot.gd:56`) üçün `randomize()`-i əvəz edir. Məşq rejimində TƏK QALAN, ekranda
   10 mikrob, YÜKSƏK.
5. **APK skripti:** `tools/perf/apk_bench.sh`. Ssenari ixrac presetinin
   `command_line/extra_args`-ına yazılır, CPU `/proc/<pid>/stat`-dan oxunur.
   Bu, 2026-10-17-də emulyatorda işlədilib.

**Çıxış şərti:** eyni ssenari iki dəfə işə salınanda ±5% daxilində eyni nəticə verir.

### F1 — Mikrob tamamilə GPU-da, TAM detalla (2–3 həftə) — ən böyük qazanc

**Necə edirlər:** Brawl Stars-ın personajı hazır modeldir, CPU hər kadr yalnız
onun yerini və animasiya vaxtını ötürür. Bizim mikrob hazır şəkil ola bilməz
(ART_BIBLE «Niyə sprite deyil»: ölçü, top sayı və addım ritmi oyunda dəyişir).
Amma eyni parametrik formulları GPU-da hesablamaq olar. CPU mikrob başına ~12
ədəd ötürür, formanı GPU qurur.

**Yoxlanmış zəmin (Godot 4.7, Compatibility):** 2D shader-də `instance uniform`
işləyir. Bir `ShaderMaterial`-ı paylaşan sprite-lar hərəsi öz parametri ilə **bir
çəkiliş çağırışında** çəkildi. Bütün mikrob gövdələri bir çağırışa yığıla bilər.

1. **Gövdə** — `germ_body.gdshader`, hər mikrob bir düzbucaqlı (SDF):
   - Membran polar funksiyadır: iki sinus titrəməsi, sürətə görə dartılma (16%,
     həcm qorunur), nişan qabarığı, zərbə və atəş əyilmələri.
     Bu, `_shape_ring`, `_strain`, `_event_deform`, `_fit_hit`-in GLSL-ə köçürülməsidir.
   - Kontur (eni `clamp(r × 0.10, 2.4, 6.0)`), iki tonlu işıq (`_lit_polygon`,
     qlobal `LIGHT_DIR`), spekulyar (`_specular_polygon`), rim (`_rim_segment`),
     iki qatlı kontakt kölgəsi, halo və aura — hamısı eyni shader-də. Bu gün
     bunların hər biri ayrıca poliqondur.
   - Kənar `fwidth` ilə yumşaldılır — bu gün gövdə poliqonu pilləlidir.
   - Amöbün iki qatı (jel + zol) və ləçəkləri (`_crawl_body`) — polar terminlər.
   - Təhlükə çatları, zərbə parıltısı, doğuş halqası, hazır-super qığılcımları da
     shader-ə köçür.
2. **Toplar:** `MultiMeshInstance2D`. "Günəbaxan" düzümü qapalı formuldur
   (`2.39996` rad), mövqe vertex shader-də `INSTANCE_ID`-dən çıxır. Daxili axınla
   sürüşmə və titrəmə də orada hesablanır. Amöbün ulduzları SDF ilə çəkilir.
3. **Kirpiklər — TAM SAYDA:** növ başına bir dəfə qurulan `ArrayMesh` (hər kirpik
   lent). Metaxronal dalğa vertex shader-də kirpiyin bucağından, vaxtdan və
   sürətdən hesablanır. Bu gün YÜKSƏK-də mikrob başına 18–30 poliqondur, sonra
   **bir** çağırış olur.
4. **Qamçı:** zolaq mesh-i, sinus dalğası vertex shader-də.
5. **Ayaqlar** CPU-da qalır: addım dünyaya bağlıdır, vəziyyət simulyasiyadan
   gəlir (ART_BIBLE §3). Onsuz da `BatchDraw` + multiline ilə 2–3 çağırışdır.
6. **Super effektləri** (sist, tor) — ayrıca shader düzbucaqlıları.
7. `GermVisual`-ın API-si dəyişmir (`setup`, `apply`, `flash`, `eject`) — arena
   koduna toxunulmur. Node yalnız parametrləri yeniləyir.

**Gözlənilən qazanc:**
- Mikrob başına CPU ~0.3 ms-dən ~0.02 ms-ə enir. 10 mikrobda bu, masaüstündə
  −3 ms, A04s-də **−35–40 ms**-dir.
- Kirpik poliqonları getdiyi üçün mühərrikin render-i −1.5–2.5 ms azalır.
- Mikrob başına çəkiliş çağırışı 25–35-dən 2–3-ə enir.

**Görüntü bərabərliyi:**
- Növ stendində (`--preview`) hər növün hər vəziyyəti əvvəl və sonra çəkilir:
  dayanma, hərəkət, atəş, zərbə, təhlükə, super, doğuş.
- ART_BIBLE kontraktının rəqəmləri (kontur eni, işıq istiqaməti, dartılma, ölçü)
  testlə yoxlanır.
- Yeganə fərq kənarın hamarlığıdır.

**GPU yükü:** 10 mikrob × ~6 400 piksel × ~100 əməliyyat ≈ 6 M əməliyyat kadrda.
Mali-G52 MP1-də bu, ~0.3 ms təxmin olunur və real telefonda ölçülür.

### F2 — Parlama (glow) mobil oyunlar kimi: billboard (1 həftə)

**Necə edirlər:** Supercell-in 2D məzmununda işləmə vaxtı filtr yoxdur. Arm
aşağı səviyyəli cihazlar üçün billboard üsulunu tövsiyə edir.

**Bu gün:** `WorldEnvironment` glow (eşik 0.62, tam ekran, bir neçə bulanıq
səviyyə) və onun üçün `hdr_2d` ilə RGBA16F kadr buferi. Bu, hər kadr iki dəfə çox
yaddaş zolağı və bir neçə tam ekran keçidi deməkdir.

1. Eşik 0.62 olduğuna görə bu gün də yalnız **canlı şeylər** parlayır: mikrob,
   qida, top, qığılcım, effektlər. Elə bu obyektlərin hər birinə öz parlamasını
   verən additive halo qoyulur. Mikrobda bu, F1-in shader-indədir; qida və top
   üçün atlasda əvvəlcədən bulandırılmış halo sprite-ı olur.
2. Halo-nun ölçüsü və qradiyenti bugünkü glow-un şəklinə tənzimlənir
   (`glow_intensity 1.15`, `glow_strength 1.20`, `glow_bloom 0.14`).
3. `WorldEnvironment` glow və `hdr_2d` söndürülür: bufer RGBA8 olur, bulanıqlıq
   keçidləri gedir.
4. **Qərar 1:** YÜKSƏK-glow ilə billboard-un A/B şəkilləri sahibə göstərilir.
   Qəbul olunmasa, ehtiyat yol: Godot glow-u qalır, amma yalnız 1–2 səviyyə ilə
   (ölçülür).

**Qazanc:** əsasən GPU-dadır (zəif GPU-da 60 kadr üçün şərtdir); CPU-da glow
keçidlərinin hazırlığı da gedir.

### F3 — Su zərrəcikləri, axın və effektlər GPU-da, TAM sayda (1 həftə)

1. **Su zərrəcikləri (80+30) və cərəyan deşiklərinə axın:** `GPUParticles2D` öz
   proses shader-i ilə. `Const.current_at` analitik funksiyadır (sin/cos sahəsi)
   və GLSL-ə birbaşa köçür. Zərrəcik mövqeyini GPU özü inteqrasiya edir, CPU
   işi sıfıra enir.
2. **Quruyan zonanın buxarı və çatları** (TƏK QALAN): buxar shader-də, çatlar
   statik qatda (artıq belədir).
3. **Effektlər** (`juice_fx`, `burst_fx`, `super_fx`): onsuz da bir neçə batch-dir.
   Yalnız profildə görünən hissələr GPU hissəciklərinə keçir.
4. **Zərbə rəqəmləri:** `_pop_text` hər zərbədə `Label.new()` + `Tween` yaradır;
   onun yerinə hovuz və MSDF şrift (F4) gəlir.

### F4 — Atlas və instancing — Supercell-in `.sc` yanaşması (1 həftə)

1. **Atlas:** oyunun içindəki bütün sprite-lar 1–2 atlasda olur — qida, spor, top,
   qığılcım, disk, halo, maneələr, kollar, deşiklər. HUD ikonları ayrıca atlasda.
   Fərqli obyektlər ardıcıl gələndə bir çağırışa yığılır.
2. **Instancing:** qida, toplar və partlayış damcıları üçün qat başına bir
   `MultiMeshInstance2D`. Yüzlərlə `Sprite2D` node-u (`_render_food`, `_take`
   hovuzu) getmir, mövqelər bir `multimesh.buffer` yazısı ilə ötürülür.
3. **MSDF şrift:** Nunito və Baloo 2 `multichannel_signed_distance_field` ilə.
   Bir atlas bütün ölçüləri və konturları verir; yeni ölçüdə yazı çıxanda qliflər
   işləmə vaxtı rasterləşmir. Piksel diapazonu ən böyük konturun iki qatıdır
   (≥ 24). Azərbaycan hərfləri yoxlanır.
4. **Hədəf:** YÜKSƏK-də tam döyüşdə kadrda ≤ 50 çəkiliş çağırışı (bu gün 250+).

### F5 — Android platforması: render, kadr ritmi, ADPF (1–2 həftə)

1. **Render üçün A/B** (qərar 2):
   - Bu gün Compatibility (GLES3) işlədilir.
   - Mobile (Vulkan) bunları verir: Swappy kadr ritmi; ubershader və Shader Baker
     (shader-lər ixracda kompilyasiya olunur, ilk effektdə ilişmə olmur); bir çox
     cihazda daha az sürücü xərci.
   - Risk: köhnə Mali-G52 Vulkan sürücüləri. Laboratoriyada iki cihazda ölçülür.
     Vulkan dəstəklənməyəndə GLES3-ə avtomatik düşmə saxlanılır.
2. **ADPF plugin-i** (Godot-da hazır yoxdur — Unity, Unreal, Cocos və Defold-un
   var). Kiçik Android plugin-i (Kotlin + NDK) yazılır:
   - **Performance Hint:** hər kadrın hədəfi (33.3 və ya 16.7 ms) və real
     müddəti bildirilir.
   - **Thermal headroom:** istilik həddə yaxınlaşanda kadr həddi 60 → 30 enir.
     Qrafika yox, kadr enir — telefon sonra boğulmur.
   - **Game Mode:** oyunçunun "batareya" rejimi 30 kadr deməkdir.
3. **Batareya:** qənaət rejimində və ya batareya azalanda 30 kadr (Brawl Stars
   kimi).
4. **Kadr seçimi AYARLAR-da:** 30 / 60 / 90 / 120 (cihaz nə dəstəkləyirsə).
   Qrafika seçimi yoxdur — görüntü hamıda eynidir.

### F6 — Yükləmə və ilişmələr (1 həftə)

1. **Matç axtarışı ekranı** (Brawl Stars kimi): OYNA basılan kimi arena, onun
   skriptləri və teksturaları yüklənir, server qoşulması da bu vaxt gedir.
   Arenaya keçəndə donma olmur (A04s modelində bu gün ~3.2 s).
2. **Shader qızdırma** — axtarış ekranında hər material bir dəfə ekrandan kənarda
   çəkilir. Mobile render-ə keçilsə, Shader Baker bunu ixracda edir.
3. **Hovuzlar:** `BurstFx`, effekt node-ları, zərbə rəqəmləri — matçda yeni node
   yaranmır.
4. **Android ixrac şablonu:** `disable_3d=yes`, `lto=full`, istifadə olunmayan
   modullar söndürülür. APK kiçilir, açılış qısalır. Mətn serverinə toxunulmur
   (Azərbaycan hərfləri riskə salınmır).

### F7 — Məntiq: GDScript-in isti yerləri (1–2 həftə, ölçü tələb etsə)

1. **Tick başına yox, kadr başına:** `_do_tick`-dəki `set_fire_state`, `set_super`,
   `set_match`, `update_gauge` kadrda bir dəfəyə enir.
2. **Snapshot-ın tənbəl açılması:** `_ingest` yalnız interpolyasiyanın işlətdiyi
   snapshot-ların mikroblarını açır.
3. **Fizika tick-i:** layihədə fizika node-u yoxdur, amma saniyədə 60 boş addım
   işləyir. 30-a endirilməsi sınanır.
4. **C++ (GDExtension), yalnız client tərəfdə:** snapshot açılması, interpolyasiya,
   topların proqnozu — F1–F6-dan sonra profil göstərsə. Supercell-in hər şeyi
   native-dir; bizdə isə yalnız ölçünün göstərdiyi yer köçür.
   - `Sim` serverlə ortaqdır və GDScript-də qalır: client C++-a keçsə, proqnoz
     serverdən ayrıla bilər.
   - Brauzer sınağı üçün `dlink` veb şablonu və ya GDScript ehtiyat yolu saxlanılır.

### F8 — Kadr siyasəti və davamlı nəzarət

1. F1–F4 büdcəni tutandan sonra **keyfiyyət səviyyələri götürülür**: hamı YÜKSƏK
   görür. MİNİMUM yalnız dəstəklənməyən cihazlar üçün gizli ehtiyat kimi bir
   buraxılış saxlanılır (qərar 5).
2. **Hər buraxılışdan əvvəl** APK ölçüsü emulyatorda F0-ın ssenarisi ilə gedir.
   Kadr büdcəni aşsa, buraxılış dayanır. `sim_test`-dəki mənbə yoxlamaları
   genişlənir (kadrda `Label.new()` və `Sprite2D.new()` qadağası).
3. **Oyunçulardan FPS və istilik telemetriyası** HTTP ilə toplanır, RPC ilə yox —
   yeni RPC köhnə APK-ların RPC nömrələrini sürüşdürür.

---

## 5. Mərhələ hədəfləri

| Nöqtə | Mərhələlər | Şərt |
|---|---|---|
| M1 | F0 + F1 | APK, YÜKSƏK, 10 mikrob: emulyatorda ≤ 10 ms CPU/kadr; A04s-də ≥ 25 FPS |
| M2 | + F2, F3, F4 | Emulyatorda ≤ 7 ms; A04s-də sabit 30; ≤ 50 çağırış; orta telefonda 60 |
| M3 | + F5, F6, F7 | A04s-də 20 dəqiqə 30 FPS, istilikdən düşmədən; matç girişində və ilk partlayışda 100 ms-dən uzun ilişmə yoxdur |

Ümumi həcm: təxminən 7–10 həftə. F1 ən uzun və ən vacibidir.

---

## 6. Sahibin qərarları

1. **Parlama:** billboard üsulu A/B şəkillə qəbul olunacaqmı (F2)? Ehtiyat yol —
   Godot glow-u az səviyyə ilə.
2. **APK-da Vulkan (Mobile) render:** cihaz laboratoriyasında A/B-yə icazə (F5)?
3. **Android plugin-i və C++ alət zənciri** (NDK, GDExtension): layihəyə əlavə
   olunsunmu (F5, F7)?
4. **Test cihazları:** bir Exynos 850 telefon və bir orta telefon alınsınmı (F0)?
5. **Keyfiyyət səviyyələri** M2-dən sonra götürülsünmü (F8)?
6. **iOS** — bu planın xaricindədir. Mobile render Metal-da da işləyir, ona görə
   F1–F4 orada da keçərlidir.

---

## 7. Nə ETMƏ

- **Görüntünü sadələşdirmə** — tələb budur. Hər texnika dəyişikliyi A/B şəkil
  ilə yoxlanır.
- **Mühərriki dəyişmə.** Problem Godot deyil, işin harada görüldüyüdür.
- **Hər şeyi C++-a köçürmə.** Ən böyük xərc görüntüdür və onun yeri GPU-dur.
- **Brauzer üçün ayrıca optimallaşdırma etmə** — orada yalnız işləmək bəsdir
  (2026-10-17 düzəlişləri qalır).
- **Ölçüsüz dəyişiklik etmə.**
- **Telemetriya üçün yeni RPC əlavə etmə.**

---

## 8. Mənbələr

- Supercell — Titan mühərriki: https://supercell.com/en/career-stories/
- Brawl Stars qrafika ayarları (kadr həddi, batareyada 30, sabit 30):
  https://support.ftgames.com/hc/en-us/articles/7918056936721-How-can-I-change-my-graphics-settings
- `.sc` formatı (icma alətləri): https://github.com/sc-workshop/SC ,
  https://github.com/sc-workshop/SupercellSWF-Animate , https://npmjs.com/package/supercell-swf ,
  https://cdn.jsdelivr.net/npm/@ultrapowa/sc-tools@2.0.4/README.md
- `.scw` 3D formatı: https://www.fileinfo.com/extension/scw
- Arm — mobil post-processing və billboard parlama:
  https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/post-processing-effects-on-mobile-optimization-and-alternatives
- Nordeus — 60 FPS-də post-processing: https://engineering.nordeus.com/post-processing-effects-at-60-fps-on-mid-range-smartphones-unite-berlin-2018/
- Arm — Mali GPU tövsiyələri: https://developer.arm.com/community/arm-community-blogs/b/mobile-graphics-and-gaming-blog/posts/new-developer-guide-arm-mali-application-developer-best-practices
- Android ADPF: https://developer.android.com/games/optimize/adpf ;
  MediaTek: https://developer.android.com/stories/games/mediatek-adpf ;
  UNISOC: https://developer.android.com/stories/games/unisoc-adpf ;
  Unreal plugin-i: https://developer.android.com/games/engines/unreal/unreal-adpf ;
  Defold: https://defold.com/extension-adpf
- Godot — shader ilişmələri, ubershader, Shader Baker:
  https://docs.godotengine.org/en/4.5/tutorials/performance/pipeline_compilations.html ,
  https://gamefromscratch.com/godot-4-5-released/
- Godot — Android-də Swappy və Vulkan işi: https://phoronix.com/news/Godot-Better-Vulkan
- Godot — MultiMesh: https://docs.godotengine.org/en/4.4/tutorials/performance/using_multimesh.html
- Godot — instance uniform-lar: https://godotengine.org/article/godot-40-gets-global-and-instance-shader-uniforms
- Godot — MSDF (SystemFont): https://docs.godotengine.org/en/4.2/classes/class_systemfont.html
- Bizim ölçülər: README, «Brauzerdə (Android) donma və kəsilmə», 8-ci bənd; bu sənədin §2-si.
