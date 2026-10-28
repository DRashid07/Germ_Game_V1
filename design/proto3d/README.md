# Kirpiklinin 3D vizual prototipi (2026-10-28)

Məqsəd: bir **Kirpikli** mikrobun indiki 2D GPU görüntüsünü həcmli 3D model, jel materialı
və prosedur animasiyalarla **müqayisə etmək**. Döyüş qaydaları, server, protokol dəyişmir;
tam 3D keçidi deyil.

## Nə var

| Fayl | Nədir |
|---|---|
| `design/proto3d/build_ciliate3d.py` | Blender qurma skripti — modelin MƏNBƏYİ (təkrar qurulur) |
| `design/proto3d/ciliate3d.blend` | Redaktə edilən Blender faylı (skriptin çıxışı) |
| `game/assets/proto3d/ciliate3d.glb` | Godot-un idxal etdiyi model (skriptin çıxışı) |
| `game/shaders/proto3d_jelly.gdshader` | Laym jel materialı (GL Compatibility) |
| `game/scripts/tools/germ3d.gd` | `Germ3D` — bir 3D mikrob, vəziyyəti simulyasiyadan oxuyur |
| `game/scripts/tools/germ3d_stand.gd` | Müqayisə və ölçü stendi (`--germ3d`) |

Model **prosedurdur** (Blender skripti ilə qurulur) — peşəkar rəssamın hazırladığı asset deyil.
Blender 5.2.3 bu kompüterdə var:

```bash
blender -b --factory-startup --python design/proto3d/build_ciliate3d.py -- \
    game/assets/proto3d/ciliate3d.glb design/proto3d/ciliate3d.blend
```

Model: aşağı poliqonlu yumşaq gövdə (28×18 sfera, şəkil açarları **Fire**, **Squash**,
**Tension**, **Breath**), gövdəyə bağlı **məsamə** (bioloji atəş çıxışı, silah deyil), içində
**nüvə** və top sayı qədər **daxili top** (MultiMesh), gövdənin ətrafında 36 **kirpik**
(MultiMesh), 5 sümüklü armatura ilə **qamçı**. Xəritə nümunələri: selik ləkəsi, kol, kövrək
qabıq (fasetli). Rənglər Principled BSDF-in "Base Color"-undadır (glTF ancaq onu ixrac edir).
İdxalda tangent qurulması bağlıdır (`meshes/ensure_tangents=false`) — jel shader-i onu işlətmir.

## İşə salma

Adi açılış heç bir 3D resursu yükləmir (test: `--simtest`-də "3D prototipin modeli, shader-i
və skripti adi yolda yüklənmir"). Yalnız bayraqla:

```bash
# Müqayisə: solda indiki 2D GPU yolu, sağda 3D; mərhələ şəkilləri və dəymə ellipsi
godot --path game -- --germ3d [--germ3d-overlay] [--shot <prefiks>]
# Ölçü: N mikrob; 2d — indiki yol, 3d — ortaq SubViewport, 3d-each — hər mikroba ayrı
godot --path game -- --germ3d --germ3d-bench 10 --germ3d-mode 3d [--germ3d-secs 8]
```

Müqayisənin zaman xətti: dayanma → üzmə → atəş → zərbə → aşağı ehtiyat → dolu → super →
kol (örtülmə) → partlama → doğuş. `--shot` hər mərhələdə `<prefiks>_<mərhələ>.png` yazır.

## Arenaya necə qoşulub — və niyə ayrıca stend

3D görüntü **ortoqrafik kamera + SubViewport** ilə çəkilir (2D (x, y) → 3D (x, 0, y), kamera
yuxarıdan) və 2D səhnəyə tekstura kimi qoyulur. Arenanın özünə qoşulmayıb: stend eyni `Sim`-i
işlədir, iki görüntü eyni mikrobun vəziyyətini (mövqe, radius, sürət, nişan, top sayı) və
hadisələrini (atəş, zərbə, super) oxuyur. Beləcə oyunun yükləmə və kadr yoluna heç nə əlavə
olunmur, iki görüntü isə eyni kadrda yan-yana müqayisə olunur.

**Membran = dəymə həndəsəsi.** `Germ3D`-nin `Deform` node-u `Sim.hit_shape`-in
ellipsini (radius, sürət boyu dartılma, yana sıxılma) affin çevirmə kimi verir; gövdə onun
içində nişana dönür (məsamə, kirpiklər, qamçı nişanı izləyir), silüet isə ellipsdir.
`--germ3d-overlay` membranın ellipsini (top radiusu çıxılmış) iki görüntünün üstünə çəkir —
dayanmada, üzmədə və doluda 3D membran onun üzərindədir (şəkillər). Zərbədə 0.26 s qısa
sıxılma ellipsdən bilərəkdən çıxır (animasiya).

## Animasiyalar (prosedur, vəziyyətdən)

1. Dayanma — zəif nəfəs (Breath açarı), maye yellənməsi.
2. Üzmə — kirpik ritmi sürətlə 2 → 9 Hz (metaxron dalğa), qamçının gecikən dalğası (sümüklər).
3. Dönmə — gövdə nişana yumşaq (eksponensial) dönür.
4. Atəş — məsamə açılır (Fire açarı, 0.18 s), qısa geri təpmə. **Top anında yaranır** —
   hazırlıq gecikməsi yoxdur, animasiya serverin atəş hadisəsinə reaksiyadır.
5. Zərbə — gələn istiqamət boyu sıxılma və ağ parıltı.
6. Doğuş (yumşaq "pop"), təhlükəli doluluq (dartılmış parlaq kənar + narıncı nəbz, Tension),
   aşağı ehtiyat (solğun rəng), partlama (böyüyüb yox olur).
7. Super (trixosist) — kirpiklər iynə kimi atılır, ağ parıltı.

Dəqiq sursat göstəricisi əsas qalır (HUD), mikrob konsentrik halqalarla örtülmür.

## Ölçü (2026-10-28)

**Masaüstü** — NVIDIA RTX 5050 Laptop, 1280×720, vsync bağlı, 8 s (1 s isinmədən sonra):

| | Kadr orta | p99 / ən pis | Render CPU | Çəkiliş çağ. | Video yaddaş | İlk istifadə kadrı | GPU |
|---|---:|---:|---:|---:|---:|---:|---:|
| 1 mikrob, 2D (indiki) | 0.89 ms | 1.39 / 2.51 | 0.05 ms | 2 | 26.7 MB | 27 ms | 0.09 ms |
| 1 mikrob, 3D ortaq | 0.90 ms | 1.39 / 10.84 | 0.24 ms | 7–8 | 47.9 MB | 16 ms | 0.17 ms |
| 1 mikrob, 3D hərəyə | 0.97 ms | 1.39 / 3.47 | 0.26 ms | 8 | 27.7 MB | 15 ms | 0.15 ms |
| 10 mikrob, 2D (indiki) | 1.13 ms | 1.39 / 2.21 | 0.08 ms | 10–12 | 28.8 MB | 32 ms | 0.12 ms |
| 10 mikrob, 3D ortaq | 2.26 ms | 2.78 / 4.32 | 0.51 ms | 53 (pik 71) | 50.3 MB | 30 ms | 0.62 ms |
| 10 mikrob, 3D hərəyə | 3.77 ms | 4.76 / 6.59 | 1.53 ms | 79 | 42.5 MB | 83 ms | 1.75 ms |

**Brauzer** (headless Chrome, WebGL2, eyni masaüstü): 10 mikrob 2D — 4.2 ms (rAF həddi 238 FPS),
1 mikrob 3D — 8.9 ms (ən pis 117 ms), **10 mikrob 3D ortaq — 42 ms (24 FPS)**, GPU vaxtı
ölçülmür (renderer 0 qaytarır).

**Android emulyatoru** (APK, GL Compatibility, Android 14, 60 Hz, 2 qaçış): 10 mikrob — 2D və
3D ikisi də 59 FPS, amma render CPU **2D 0.65–1.1 ms, 3D 5.6–16 ms**, çəkiliş çağırışı 10.5 → 49–55,
video yaddaş 48 → 67 MB; GPU vaxtı ölçülmür. Emulyatorun GL çağırışları hosta keçir — telefon
rəqəmi deyil, nisbət göstəricisidir. **Həqiqi telefon yoxlanmayıb.**

"Görüntünün CPU işi" sütunu ölçüldü, amma cədvəldə yoxdur: 2D yolunun mikrob başına işi kadrın
sonunda (`frame_pre_draw`) gedir və `_process` ölçüsü onu tutmur — müqayisə render CPU və kadr
vaxtı ilədir.

## Nəticə və məhdudiyyətlər

- 3D görüntü oxunaqlıdır (həcm, jel, nüvə, toplar, kirpik və qamçı), dəymə ellipsinə uyğundur,
  kol onu düzgün örtür. Amma 10 mikrobda masaüstündə kadr ~2×, render CPU ~6×, çəkiliş çağırışı
  ~5× artır; brauzerdə 10× yavaşdır, Android emulyatorunda render CPU 5–15× artır.
- **Hər mikroba ayrıca SubViewport** ən bahalı variantdır (10-da kadr 3.8 ms, ilk istifadə 83 ms) —
  ortaq səhnə + bir viewport daha yaxşıdır, amma o da 2D yolundan xeyli ağırdır.
- Növbəti addım (edilməyib): kirpikləri və topları bir MultiMesh-də bütün mikroblar üçün
  birləşdirmək, gövdəni bir instanced çağırışa yığmaq, sonra telefonda ölçmək. Tam keçid yoxdur.
- Android-də müqayisə görüntüsünün şəkli çəkilməyib (stend şəkildən əvvəl bitdi); skript xətası 0.
