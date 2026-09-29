# Germ Arena — Audio Bible

**Üslub:** maye dünya. Heç bir səs "metal" deyil — zərbə yox, **qabarcıq,
çırtıltı, sıçrama**. Bütün kliplər [`design/tools/gen_audio.js`](tools/gen_audio.js)
ilə sintez olunur; hazır sample yoxdur.

```bash
node design/tools/gen_audio.js          # design/audio/ qovluğuna yazır
cp design/audio/*.wav game/assets/sfx/
```

Skript yazdığı faylı geri oxuyub yoxlayır: format (44.1 kHz, mono, 16-bit),
müddət həddi, pik səviyyə, kənar fade-lər və ümumi ölçü. Yoxlama keçməsə
`run()` xəta atır — pozuq klip layihəyə düşə bilmir.

---

## 1. İyerarxiya

Eyni anda 10 mikrob atəş açır, qida udur, partlayır. Hamısı bərabər səslənsəydi,
nəticə fasiləsiz xışıltı olardı. Ona görə səslər üç səviyyəyə bölünüb:

| Səviyyə | Səslər | Qayda |
|---|---|---|
| **1. Sənə olan** | `you_burst`, `level_up`, `danger` | Həmişə tam səslə |
| **2. Sənin etdiyin** | `eject`, `hit_confirm`, `absorb`, `spawn` | Tam səslə, amma qısa |
| **3. Ətrafda olan** | başqasının `eject` (−6 dB), `hit`, `burst` | Sönük və ya seyrək |

İki konkret qərar:

- **Başqasının udması ümumiyyətlə eşidilmir.** Ekranda saniyədə onlarla qida
  udulur; hamısı çalınsaydı fon xışıltıya dönərdi. Kod yalnız öz rəngini yoxlayır
  ([`arena.gd → _flush_fx`](../game/scripts/client/arena.gd)).
- **Xəbərdarlıq saniyədə bir dəfədən çox çalınmır.** HUD hər kadr "təhlükədəyəm"
  deyir, qulaq isə bunu bir dəfə eşitməlidir — [`Sfx.play_danger()`](../game/scripts/client/sfx.gd).

---

## 2. Kliplər

| Fayl | Müddət | Pik | Nədir |
|---|---|---|---|
| `eject.wav` | 105 ms | −6.5 dB | Təzyiq — mikrob topu içindən sıxır, qısa "püf" |
| `blunk.wav` | 115 ms | −7.0 dB | Top pərdəni **yarıb çıxdı** — enən "blunk" |
| `absorb.wav` | 90 ms | −8.0 dB | Qida udulur — qalxan "blup" |
| `hit.wav` | 145 ms | −4.5 dB | Top rəqibin içinə keçdi — yaş "çırt" |
| `hit_confirm.wav` | 80 ms | −7.0 dB | Sənin topun dəydi — qalxan, parlaq qabarcıq "pop" |
| `burst.wav` | 700 ms | −1.5 dB | **Mikrob öldü** — qopma + cırılma + alt gurultu + damcılar |
| `spawn.wav` | 420 ms | −4.0 dB | Doğuş — üç qalxan qabarcıq |
| `danger.wav` | 240 ms | −5.0 dB | İki qısa siqnal: dolursan və ya acsan |
| `level_up.wav` | 480 ms | −3.0 dB | Tutum artdı — qalxan üç not + oktava |
| `you_burst.wav` | 1180 ms | −2.0 dB | **SƏN öldün** — eyni partlayış, daha dərin + sönən nəfəs |
| `ui_click.wav` | 55 ms | −8.0 dB | Menyu toxunuşu |

Ümumi: 11 fayl, ~311 KiB.

---

## 3. Tezlik sahələri — niyə belədir

**`eject` və `blunk` bir cütdür, bir səs deyil.**

Atəş İKİ hadisədir və oyunçu ikisini də eşitməlidir: mikrob topu sıxır
(`eject`, atəş anında), sonra top pərdəni yarıb çıxır (`blunk`). Aradakı
gecikmə uydurma deyil — topun mərkəzdən membrana qədər getdiyi əsl vaxtdır
(`radius / SHOT_SPEED`): kiçik mikrobda 67 ms, ən böyüyündə 204 ms. Ona görə
böyük mikrobun atəşi "ağır" eşidilir, kiçikdə isə iki səs demək olar birləşir.

Vaxtı `Arena` yox, görüntü node-u bilir: `GermVisual` pərdəni yardığı kadrda
`broke_through` siqnalını göndərir, səs ona bağlanır.

**`eject` və `hit` qəsdən ayrı sahələrdədir.**

- `eject` — 460 → 175 Hz enən ton + 260–2600 Hz səs-küy zolağı (yuxarı-orta)
- `hit` — 210 → 82 Hz enən ton + 180–3000 Hz zolaq, `drive 1.35` ilə doyurulmuş (aşağı, dolğun)

Səbəb: oyunçu ekranın yalnız bir hissəsinə baxır. Top atdığını gözü ilə görür,
amma **dəydiyini eşitməlidir**. İki səs eyni sahədə olsaydı, fasiləsiz atəşdə
biri o birini örtərdi.

**`hit` və `hit_confirm` bir cütdür.** `hit` hamıya “nəyəsə dəydi” deyir;
`hit_confirm` isə yalnız atıcıya “SƏNİN topun dəydi” cavabını verir. Buna görə
təsdiq səsi `hit`-in aşağı gövdəsindən ayrı, yüksək zolaqdadır. Hədəf dolduqca
`pitch_scale` qalxır və qulaq onun partlamağa yaxınlaşdığını eşidir.

**`burst` yeganə alt tezlikli səsdir** (240 → 34 Hz). Dünyada ən vacib hadisə odur;
başqa heç bir klip ora enmir, ona görə telefonun kiçik dinamikində belə seçilir.

### Ölüm səsi niyə beş qatdır

`burst` tək bir "boom" deyil. Partlayış ekranda bir anlıq hadisədir, amma qulaq
onu **üç fazada** oxuyur — nə oldu, nə qədər böyük idi, nədən ibarət idi:

| Qat | Vaxt | Nə deyir |
|---|---|---|
| Qopma (900–9000 Hz, 6 ms sönmə) | 0 ms | *baş verdi* — transient, "zərbə" hissi |
| Membranın cırılması (300–5400 Hz) | 0–190 ms | *bir şey yırtıldı* |
| Yayılan maye (85–1500 Hz) | 25–545 ms | *yaş idi* — gövdə |
| Alt ton (240 → 34 Hz) | 0–440 ms | *böyük idi* — ağırlıq |
| Damcı quyruğu (3 qalxan qabarcıq) | 180–470 ms | *yerə qida töküldü* |

Sonuncu qat qəsdən `absorb` ilə eyni dildədir: partlayış həm ölümdür, həm də
yerdə qalan qidadır — quyruq elə həmin təklifi səsləndirir.

**`you_burst` eyni dildədir, üç fərqlə:** daha dərinə enir (30 Hz), daha uzun
sürür və sonunda **sönən nəfəs** var. Qulaq ilk ikisini "böyük", üçüncüsünü
"bitdi" kimi oxuyur — nəticə ekranı görünməmişdən əvvəl oyunçu artıq bilir.

Səs [`burst_fx.gd`](../game/scripts/client/burst_fx.gd) effekti ilə cütdür:
effektin ömrü (1.15 s) səsdən uzundur ki, qulaq susandan sonra göz hələ də
hadisənin qalıqlarını görsün.

**`level_up` yeganə major akkorddur** (C–E–G + oktava). Oyunun tək mükafatıdır —
qulaq onu dərhal "yaxşı bir şey oldu" kimi oxuyur.

---

## 4. Səsi dəyişmək

Hər klipin öz `create*` funksiyası var. Rəqəmi dəyişib skripti yenidən işə salmaq
kifayətdir:

```js
// design/tools/gen_audio.js
function createEject(spec) {
  addTone(sound, {
    frequencyStart: 460,   // ← burada
    frequencyEnd: 175,
    ...
```

Müddət `SOUND_SPECS`-də verilir və `limit` ilə məhdudlaşır. `eject` üçün
`strictLimit: true` qoyulub: saniyədə ~3 top atılır, klip 130 ms-i keçsə
səslər üst-üstə düşür.

---

## 5. Şinlər və oyunçunun sürgüləri

Üç şin var və hamısı kodda qurulur
([`Settings._ensure_buses`](../game/scripts/shared/settings.gd)), `default_bus_layout.tres`
faylı ilə yox: resurs redaktordan asılıdır, kod isə şərh oluna bilir.

```
UI  ─┐
SFX ─┴→ Master → cihaz
```

| Şin | Nə gedir | İlkin |
|---|---|---|
| `UI` | `ui_click` | 80% |
| `SFX` | qalan 10 klip | 100% |
| `Master` | hamısı | 90% |

**Sürgü klipin öz səviyyəsinə TOXUNMUR.** Yuxarıdakı üçpilləli iyerarxiya
(səviyyə 3 səsləri `−6 dB` ilə çalınır) şindən ƏVVƏLdir, yəni sürgü nə olursa
olsun menyu toxunuşu ilə partlayış arasındakı nisbət qorunur. Hər klipə ayrıca
dəyər verilsəydi, bu tarazlıq ilk sürüşdürmədə dağılardı.

**`UI` niyə ayrıdır:** menyu toxunuşu ilə oyunun səsi bir-birinin işi deyil.
Oyunçu arenada effektləri qısıb düymə cavabını saxlaya bilər, ya da əksinə.
Tək şin olsaydı, "səsi azalt" hər ikisini birlikdə aparardı.

**Səssiz rejim = `Master` sıfırda**, ayrıca bayraq yox: səviyyə geri
qaldırılanda oyunçunun köhnə dəyəri olduğu yerdə qalır.

**Musiqi şini YOXDUR, çünki musiqi yoxdur.** Heç nəyi idarə etməyən sürgü
bütün ayarlar ekranına olan etibarı aparır. Trek gələndə `MUSIC` şini və bir
sürgü sətri əlavə olunacaq — qalan hər şey hazırdır.

**Titrəmə səsin əvəzi deyil, cütüdür.** Zərbə (22 ms), super (45), tutum
artımı (60) və ölüm (160) — telefonda səs kəsilə bilər, ekran isə həmişə
barmağın altındadır. Ayarlardan söndürülür.
