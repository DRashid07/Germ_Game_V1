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
   > **Hazırdır (2026-10-19).** Məşq rejimində işləyir; yalnız canlı matç kadrlarını
   > sayır — oyunçu öləndə arenanı bağlayıb yenisini açır (avtomatik oyunçu TƏK
   > QALAN-da 15–25 saniyə yaşayır, `--perf` isə ondan sonrakı menyunu da sayırdı).
   > 50 ms-dən uzun kadrlar hissələri ilə ayrıca yazılır. Fazalı ölçmə canlı matçda
   > səs-küylüdür (emulyatorda ±1 ms); dəqiq qat qiyməti üçün səhnəni dondurub
   > qatları növbə ilə gizlətmək lazımdır (bax aşağıda, «Render-in bölgüsü»).
4. **Təkrarlanan ssenari:** `--seed N` `Sim.rng` (`sim.gd:294`) və `Bot._rng`
   (`bot.gd:56`) üçün `randomize()`-i əvəz edir. Məşq rejimində TƏK QALAN, ekranda
   10 mikrob, YÜKSƏK.
5. **APK skripti:** `tools/perf/apk_bench.sh`. Ssenari ixrac presetinin
   `command_line/extra_args`-ına yazılır, CPU `/proc/<pid>/stat`-dan oxunur.
   Bu, 2026-10-17-də emulyatorda işlədilib.

**Çıxış şərti:** eyni ssenari iki dəfə işə salınanda ±5% daxilində eyni nəticə verir.

### F1 — Mikrob tamamilə GPU-da, TAM detalla (2–3 həftə) — ən böyük qazanc

> **Vəziyyət (2026-10-18): A, B və C addımları hazırdır, işləkdir.** Oyunun öz
> yoludur; `--germ-cpu` köhnə yola qaytarır. Bax README «Mikrob GPU-da çəkilir».
> C: super (amöbün qabığı, ayaqlının toru) ön mesh-in qatlarıdır — node-un öz
> `_draw`-ı GPU yolunda heç nə çəkmir, super açıq olanda da hər kadr yenidən
> çəkiliş yoxdur. F6-dan shader isinməsi də edilib (`GermGPU.warm_up`, menyuda).
>
> Aşağıdakı ilkin plandan fərqi: SDF düzbucaqlısı və ayrıca MultiMesh əvəzinə hər
> növün **iki sabit mesh-i** var (təpələrdə kod: qat, indeks, rol), vəziyyət isə
> float teksturasında mikrob başına bir sətirdir (~80 ədəd) — beləliklə GDScript
> yolunun HƏR qatı (antialias-lı xətlər Godot-un öz həndəsəsi ilə) eyni sırada
> qaldı və görüntü yan-yana stenddə bərabər çıxdı.
>
> **B (kontur GPU-da):** membranın konturu kiçik RGBA8 render hədəfində ayrıca
> keçiddə qurulur (shaders/germ_shape.gdshader) — GDScript-in konturu ilə fərq
> ≤ 0.006 px (`--germ-bench --bench-verify`). Koordinatlar 16 bitlik sabit nöqtə
> ədədidir: float render hədəfi hər GPU-da yoxdur. Keçid öz World3D-sindədir —
> yoxsa arenanın glow mühiti onun baytlarına tətbiq olunur. Ayaqların addımı və
> super hələ GDScript-dədir.
>
> Ölçülüb (release, 10 mikrob): masaüstü stend 4.58 → **0.80 ms** kadr işi (A-dan
> sonra 0.98 idi), 344 → **38** çağırış; emulyator APK stend 87.2 ms (MİNİMUM
> 38.2) → **2.9 ms**; emulyator APK TƏK QALAN YÜKSƏK 35 → **57 FPS** orta,
> 16 → **36 FPS** 1% ən pis. M1-in emulyator hədəfi (≤ 10 ms CPU/kadr) mikrob
> üçün keçildi. B-nin emulyatordakı xalis qazancı kiçikdir: məntiq −0.6 ms, kontur
> keçidinin sabit render xərci +0.3–0.5 ms (emulyatorda GL çağırışı bahadır);
> mikrob başına CPU isə ~0.13 → ~0.025 ms-ə düşüb, yəni mikrob artdıqca qazanc
> böyüyür. Zəif telefonda B-nin real qazancı ölçülməlidir.
>
> **A04s ssenarisi (README «A04s ssenarisi»):** 1600×720, TƏK QALAN, YÜKSƏK,
> avtomatik oyunçu (`--auto`), A, B, C və isinmə birlikdə. Kadr probu ilə (yalnız
> canlı matç kadrları, 2026-10-19): emulyator matçı ~37 / ~22 → **60 / 32 FPS**
> (orta / 1% ən pis), kadrın işi 25.5 → **8.3 ms**, 50 ms-dən uzun ilişmə 3–16 →
> **0**; kompüter matçı 2.1 → **1.14 ms**. Ekranda 10 mikrob: kompüter 4.2 →
> **0.86 ms**, emulyator 63 → **1.75 ms**; A04s-ə çevrilmiş təxmin (×13) ~55 → ~11
> ms. Mali GPU-su ölçülməyib — dövrlərə görə təxmin 10 mikroba +~1 ms. Görüntü:
> mikrob piksellərinin 1.1–1.5%-i fərqlənir, hamısı kənar antialiası (Android-də və,
> düzəlişdən sonra, brauzerdə də). Brauzerdə tapılan səhv (2026-10-19): sətir nömrəsi
> `instance uniform` idi və veb build-də bəzi qatlara çatmırdı — mikrob başqasının
> sətrini çəkirdi; indi hər sətrin öz material nüsxəsi var (README, «Mikrob GPU-da
> çəkilir»). Android və masaüstü buna düşmürdü. İlk ölçü
> `--perf` ilə idi (49 → 59 FPS) və ölümdən sonrakı menyu kadrlarını da sayırdı;
> orada görünən iki kadrlıq ~70 ms "ilişmə" matçın içində deyil, menyu səhnəsinin
> yüklənməsidir.
>
> Növbəti addımlar:
> - Real Mali-də shader-lərin qiymətini ölçmək (F0): ən bahalıları kontur keçidi,
>   rim və işıq qatıdır — konturu gəzən dövrlər.
> - Ayaqların addımı (`_walk`) hələ GDScript-dədir — ayaqlı növün CPU işinin çoxu.

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

> **Render-in bölgüsü (2026-10-19, masaüstü, matç dondurulub, qatlar növbə ilə
> gizlədilib, 5 dövr):** render CPU 0.92 ms, GPU 0.41 ms, 90 çağırış. Parlama
> −0.17 ms CPU və **−0.16 ms GPU (GPU vaxtının 40%-i)**; su zərrəcikləri −0.09 CPU;
> HUD −0.05 CPU, amma **38 çağırış**; mikroblar −0.04 CPU, 8 çağırış; qida, xəritə,
> effektlər ≤ 0.02 ms. Hamısı gizlənəndə 0.70 ms / 26 çağırış qalır — döşəmə,
> kontur keçidi, kadr buferləri. Yəni F1-dən sonra ən böyük dəyişən xərc parlamadır;
> Mali-də tam ekran bulanıqlıq keçidləri və RGBA16F bufer bundan da bahadır. F2-nin
> A/B-si (qərar 1) növbəti ən böyük addımdır.
>
> HUD-un 38 çağırışı: hər `Label` iki çağırışdır (dinamik şriftdə kontur qlifləri
> ayrı teksturadadır), atəş düyməsi 8, super düyməsi 5, minixəritə 4. Mikrob adları
> da hər biri iki çağırışdır. MSDF (F4.3) konturu və mətni bir teksturaya yığır —
> bütün yazılar bir-iki çağırış olar; qliflərin kənarı bir az dəyişir (A/B lazımdır).
>
> **MSDF sınağı (2026-10-19): rədd.** Nunito və Baloo 2 MSDF ilə (piksel diapazonu
> 24) hərflərdə görünən qüsurlar verir — "OYNA"-da "A"-nın təpəsində tünd çıxıntı,
> "Mikrob"-da "M"-in küncündə tikan. Səbəb şriftlərin üst-üstə düşən konturlarıdır
> (dəyişkən şrift). Yalnız konturları birləşdirilmiş (remove overlaps) statik
> nüsxələrlə yenidən sınamaq olar.
>
> **Hadisə node-ları (F6.3) ölçüldü — hovuz hələ dəyməz.** Emulyatorda (A04s ekranı,
> 60 s) çağırış başına: `_pop_text` 0.32 ms (ən çox 1.0), `_spawn_fx` 0.07 ms
> (406 dəfə), `_play_super` 0.24, `_explode` 0.12 — kadr başına cəmi ~0.015 ms.
> Ən yavaş 1% kadrların artığı əsasən simulyasiya tick-indədir (məşqdə yerli
> dünya + snapshot, +4.5 ms) və SuperFx / BurstFx-in GDScript `_draw`-ındadır
> (+1.9 / +1.2 ms; SuperFx median kadrda da 0.35 ms) — növbəti CPU hədəfləri bunlardır.

### F3 — Su zərrəcikləri, axın və effektlər GPU-da, TAM sayda (1 həftə)

1. **Su zərrəcikləri (80+30) və cərəyan deşiklərinə axın:** `GPUParticles2D` öz
   proses shader-i ilə. `Const.current_at` analitik funksiyadır (sin/cos sahəsi)
   və GLSL-ə birbaşa köçür. Zərrəcik mövqeyini GPU özü inteqrasiya edir, CPU
   işi sıfıra enir.
   > **Zərrəciklər hazırdır (2026-10-19, README «Su zərrəcikləri GPU-da»).** Görüntü
   > piksel-piksel eynidir (`--germ-bench --bench-motes`: GL-də ən böyük fərq 1/255,
   > ANGLE-də 0). Masaüstü release matçı 1.24 → 1.14 ms (proses −0.13, render
   > +0.03), A04s-ə çevrilmiş təxmin ~1.3 ms. Emulyatorda +0.3 ms (GL çağırışı orada
   > baha, GDScript isə A55-dən sürətli). Deşik axını vəziyyətsizdir, GDScript-də
   > qalıb (7 cizgi × deşik). Yol üstündə tapıldı: emulyatorda saat oxumaq ~10 µs-dir
   > və zərrəciklərin "1.1 ms"-i əslində 110 saat çağırışı idi — indi faza kadrın
   > oyun saatındandır.
2. **Quruyan zonanın buxarı və çatları** (TƏK QALAN): buxar shader-də, çatlar
   statik qatda (artıq belədir).
3. **Effektlər** (`juice_fx`, `burst_fx`, `super_fx`): onsuz da bir neçə batch-dir.
   Yalnız profildə görünən hissələr GPU hissəciklərinə keçir.
   > **SuperFx hazırdır (2026-10-19, README «Superin açılış effekti GPU-da»).**
   > Profildə ən böyük skript çəkilişi idi (emulyatorda median kadrda 0.35 ms, ən
   > yavaş kadrlarda 2.3 ms). İndi mesh + shader, görüntü eynidir (yalnız böyük
   > halqanın 0° tikişi qapalıdır). Eyni anda ~36 effekt: emulyator 51–87 → 3.4 ms,
   > masaüstü 3.3 → 0.69 ms, çağırış 277 → 37; adi matçın ortası dəyişmir.
   > Yoxlama (2026-10-19): yan-yana piksel müqayisəsi GL, ANGLE, Chrome, WebKit və
   > APK-da, 24 və 12 iynə ilə — kadrda ≤ 18 piksel (0° tikişi); kadr probunun super
   > anı bölgüsü ilə superin kadra əlavəsi masaüstündə 0.19 → 0.06 ms, emulyatorda
   > 1.3 → 0.6 ms. Tapılıb və düzəldilib: isinmə effekti arenada ekrandan kənarda
   > kəsilirdi (menyusuz matçda ilk super Chrome-da 177 ms donurdu) və mikrob
   > shader-ləri ilə eyni kadrda menyunun donmasını uzadırdı; mesh-lər də isinmədə
   > qurulur. Ayrıca ilk-super ilişməsi qalmayıb: superin başladığı kadrlar (8
   > ardıcıl super) proses hissəsində 0.9–3.6 ms-dir (masaüstü debug, adi kadrın
   > p90-ı ~2 ms), ilki sonrakılardan ağır deyil; `_play_super`-in özü 0.3–0.85 ms.
   > BurstFx-in hər nüsxəsinin təsadüfi damcıları və sürtünmə ilə addım-addım
   > hərəkəti var — piksel-piksel köçürmək üçün hissəcik sistemi lazımdır, qazancı
   > (median 0.07 ms) hələ dəyməz.
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

> **Vəziyyət (2026-10-20, README «Kadr ritmi və enerji siyasəti»):** plugin-siz edildi.
> Godot 4.7-nin `AndroidRuntime` + `JavaClassWrapper`-i Android API-lərini birbaşa
> GDScript-dən çağırır, yəni bu iş üçün 3-cü qərar (Kotlin/NDK) lazım deyil.
> [`FramePacer`](../game/scripts/client/frame_pacer.gd): `Surface.setFrameRate`, ekrana
> bölünən bərabər hədd (90 Hz-də 60 → 45), batareya qənaəti və qızma (thermal headroom
> proqnozu) — 30. Emulyatorda: 90 Hz-də 60 həddinin 50% titrəməsi gedir; 60 Hz-də
> 30 həddi (yüklü host) 61% → 26% ritmdən çıxır; 60 Hz-də 60 dəyişmir. Hələ edilməyib:
> ADPF Performance Hint (işləyir, amma emulyatorda +0.3 ms/kadr, faydası yalnız real
> telefonda ölçülər), Game Mode "batareya" (manifestdə `game_mode_config` — Gradle
> build), Swappy (yalnız Vulkan render-də). Brauzer eyni bərabər ritmi `web/shell.html`-də
> tətbiq edir.

### F6 — Yükləmə və ilişmələr (1 həftə)

1. **Matç axtarışı ekranı** (Brawl Stars kimi): OYNA basılan kimi arena, onun
   skriptləri və teksturaları yüklənir, server qoşulması da bu vaxt gedir.
   Arenaya keçəndə donma olmur (A04s modelində bu gün ~3.2 s).
   > **Fon yükləməsi hazırdır (2026-10-19, README «Arenaya keçid: arena fonda
   > yüklənir»).** Menyu arenanı isinmədən sonra fon axınında yükləyir, sonra
   > xəritənin teksturalarını da (menyuda ~34 MB videoyaddaş — sahibin nəzərinə);
   > keçid kadrı masaüstü debug-da 706–827 → **40 ms**, emulyatorda (APK, yavaş rejim)
   > 1226–1319 → 282–333 ms. Brauzerin axınsız build-ində dəyişiklik yoxdur (sorğu
   > orada menyunu dondurardı). Telefon ssenarisi (A/B, 2026-10-20): birinci keçid
   > 528 → 81 ms, ikinci 224 → 75 ms, super anı +6.4 → +1.0 ms; qiyməti menyuda bir
   > uzanan kadr (+20–90 ms) və ~34 MB tekstura yaddaşıdır.
2. **Shader qızdırma** — axtarış ekranında hər material bir dəfə ekrandan kənarda
   çəkilir. Mobile render-ə keçilsə, Shader Baker bunu ixracda edir.
   > **Menyunun isinməsi hissələrə bölünüb (2026-10-20, README «Mikrob GPU-da çəkilir»).**
   > `germ_gpu.gd` fonda yüklənir, mesh-lər və hər shader ayrı kadrdadır; masaüstü
   > release-də isinmə kadrı 72–103 → 16–27 ms, Chrome-un A04s modelində (13×) ən uzun
   > kadr 3.5 → 2.5 s. Mesh keşi massivlərdən əvvəl yoxlanır (hər doğuşda boş yerə
   > qurulurdu). Fon yükləməsi bitməmiş OYNA menyunu bloklamır (520–800 → ~100 ms,
   > masaüstü debug). Tapıldı: Chrome-da (ANGLE) əsas
   > shader-in ilk kompilyasiyası 3.6–4.9 s-dir (ikinci açılışda keşdən, ~50 ms).
   > **Qalan proqramlar da isidilir (2026-10-21, README «Mikrob GPU-da çəkilir»).**
   > Godot-un shader keşinin faylları ilə ölçüldü: `water_motes` və parlama menyuda onsuz
   > da kompilyasiya olunurdu. Arenaya yalnız `map_floor` və nazik xətlərin "primitive"
   > variantı qalırdı. İndi onları da isinmə ekrandan kənarda çəkir və matç heç bir yeni
   > proqram kompilyasiya etmir (masaüstü GL, Android, onlayn və üç keyfiyyət yoxlanıb).
   > Soyuq keşlə giriş kadrı:
   > - Chrome: render 64–68 → 17–30 ms;
   > - emulyator: 53 → 39 ms (render 22.5 → 7).
   > **Açılış (2026-10-20):** klient serverin siniflərini (Lobby, World, SocialHub,
   > Bot) artıq kompilyasiya etmir — `boot.gd` və `friends.gd` onları adla çağırırdı.
   > Brauzerdə (CPU 13×) menyu 25.8–26.3 → 24.0–24.8 s, APK emulyatorunda 4767 → 4454 ms.
   > Məşq dünyası APK-da menyuda fonda yüklənir. Axınsız brauzerdə arenaya keçid hələ
   > ana axındadır (13×-də ~19 s; yarıdan çoxu `arena.gd`-nin kompilyasiyası) — indi
   > "Matç hazırlanır…" örtüyü ilə; axınlı veb build-i real telefonda yoxlanmalıdır.
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
