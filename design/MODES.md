# Germ Arena — Oyun Rejimləri (spesifikasiya)

**Vəziyyət:** BÜTÜN altı mərhələ **TƏTBİQ OLUNUB** (bax §14). Dörd rejim də
oyundadır: SONSUZ ARENA, TƏK QALAN, CÜT, ÜÇLÜK.

**Bir dizayn səhvi düzəldilib:** §4 komanda üçün İKİ bit deyirdi (bit 8-9,
0..3), amma CÜT-də BEŞ komanda var (5 × 2 = 10 mikrob). Kod üç bit işlədir
(bit 8-10) və komandanı `team + 1` kimi yazır ki, sıfır "komandasız" qalsın.

Bu sənəd tətbiqin mənbəyidir — rəqəmlər dəyişəndə həm burası, həm
`constants.gd` yenilənməlidir. Tətbiq olunmuş rəqəmlərin son sözü
`constants.gd`-dədir; ziddiyyət görsən, kod haqlıdır.

**Nə üçün lazım idi:** oyunun **matç anlayışı yox idi**. Oyunçu girir,
oynayır, partlayanda menyuya qayıdırdı — `World` sonsuz, qalib yox, komanda
yox. Aşağıdakı hər şey bunun üzərinə gəldi.

---

## 0. Söz ehtiyatı

| Söz | Mənası |
|---|---|
| **Matç** | Başlanğıcı və qalibi olan bir oyun. `World`-ün bir həyat dövrü |
| **Raund** | Matçın içindəki alt-oyun (yalnız ÜÇLÜK-də) |
| **Quru zona** | Daralan qabın çölündə qalan sahə — orada mikrob dolur |
| **Yaş radius** | Qabın hazırkı işlək radiusu (`Sim.dish_radius`) |
| **Spor** | İri qida yığını, yeyənə `+CAPACITY_STEP` tutum verir |
| **Yer** | Matçdakı sıra: 1 = qalib, 10 = ilk çıxan |

---

## 1. Rejim siyahısı

```gdscript
enum Mode {
    ENDLESS = 0,   ## SONSUZ ARENA — indiki davranış, dəyişmir
    SOLO    = 1,   ## TƏK QALAN    — 10 mikrob, sona qalan udur
    DUO     = 2,   ## CÜT          — 5 komanda × 2, eyni quruyan qab
    TRIO    = 3,   ## ÜÇLÜK        — 3v3, üç raundun ikisi
}
```

Rejim **dünyanın xassəsidir**, oyunçunun yox: `World.mode`. Lobby oyunçunun
istədiyi rejimə uyğun dünya axtarır, tapmasa yenisini açır.

| Rejim | Mikrob | Komanda | Qab | Dirilmə | Qalib |
|---|---|---|---|---|---|
| ENDLESS | 10 | yox | sabit `1200` | — (menyuya qayıdır) | yoxdur |
| SOLO | 10 | yox | quruyur | **yox** | sona qalan |
| DUO | 10 | 5 × 2 | quruyur | 15 s (yoldaş sağdırsa) | sona qalan cüt |
| TRIO | 6 | 2 × 3 | `700`, sonra quruyur | **yox** (raund boyu) | 3 raundun 2-si |

---

## 2. Matçın vəziyyət maşını

```gdscript
enum Phase {
    WAITING   = 0,  ## oyunçu gözlənilir (ENDLESS-də heç vaxt olmur)
    COUNTDOWN = 1,  ## 3 saniyə — mikroblar görünür, giriş bağlıdır
    PLAYING   = 2,
    ROUND_END = 3,  ## yalnız TRIO — 3 saniyə, hesab göstərilir
    OVER      = 4,  ## nəticə ekranı, 5 saniyə sonra dünya bağlanır
}
```

### Keçidlər

| Keçid | Şərt |
|---|---|
| `WAITING → COUNTDOWN` | Ən azı **bir insan** var. Qalan yerlər botla dolur |
| `COUNTDOWN → PLAYING` | 3 saniyə keçdi |
| `PLAYING → OVER` | Qalib müəyyən oldu (rejimə görə, §6) |
| `PLAYING → ROUND_END` | TRIO: bir komanda tam çıxdı, yaxud raund vaxtı bitdi |
| `ROUND_END → COUNTDOWN` | Hələ qalib yoxdur (hesab 2-yə çatmayıb) |
| `ROUND_END → OVER` | Bir komanda ikinci raundu udub |
| `OVER → (bağlanır)` | 5 saniyə |

**ENDLESS istisnası:** həmişə `PLAYING`. Vəziyyət maşını var, amma heç vaxt
çıxmır — belə olanda kod bir yoldan gedir və köhnə rejim yeni sistemin
altında toxunulmaz qalır.

### Vaxtlar

```gdscript
const COUNTDOWN_TIME := 3.0      ## Növbə YOXDUR — bax §9
const ROUND_BREAK := 3.0         ## TRIO raundları arası
const RESULT_TIME := 5.0         ## Nəticə ekranı
const MATCH_MAX := 240.0         ## Təhlükəsizlik həddi: heç bir matç 4 dəqiqədən uzun deyil
```

`MATCH_MAX` bitəndə: **ən çox topu olan** udur (SOLO/DUO), TRIO-da isə raund
bərabərlikdə sayılır və qab sürətlə quruyur.

---

## 3. Quruyan qab

Brawl Stars-ın zəhərli qazının qarşılığı. **Açar qərar:** quru zonada mikrob
top **itirmir — qazanır**. Qab quruyur, mühit qatılaşır, mikrob dolub partlayır.

### Radius düsturu

```gdscript
## Yaş radius YALNIZ matç saatından çıxır — mövqedən, təsadüfdən və
## vəziyyətdən asılı deyil. Səbəb prediction-dur (bax §8).
static func dish_radius(mode: Mode, t: float) -> float:
    match mode:
        Mode.ENDLESS:
            return WORLD_RADIUS
        Mode.TRIO:
            # Raund saatı. 40-cı saniyəyə qədər sabit, sonra sürətlə.
            return _shrink(TRIO_START_RADIUS, TRIO_END_RADIUS, t, 40.0, 20.0)
        _:
            return _shrink(WORLD_RADIUS, SOLO_END_RADIUS, t, DRY_DELAY, DRY_TIME)


## `hold` saniyə sabit, sonra `span` saniyəyə `from`-dan `to`-ya yumşaq keçid.
static func _shrink(from: float, to: float, t: float, hold: float, span: float) -> float:
    if t <= hold:
        return from
    var k := clampf((t - hold) / span, 0.0, 1.0)
    return lerpf(from, to, smoothstep(0.0, 1.0, k))
```

### Sabitlər

```gdscript
const DRY_DELAY := 45.0          ## Quruma bu qədər saniyədən sonra başlayır
const DRY_TIME := 105.0          ## Tam qurumaya qədər
const SOLO_END_RADIUS := 250.0   ## Son sıxılma — 10 mikrob burada rastlaşmalıdır
const TRIO_START_RADIUS := 700.0 ## 6 mikrob 1200-lük qabda bir-birini tapmır
const TRIO_END_RADIUS := 220.0

## Quru zonada bir topun yığılma müddəti (saniyə).
## Metabolizm 6 saniyəyə BİR top yandırır — quruma ondan 5 dəfə sürətlidir,
## yəni orada qalmaq real qərardır, adət deyil.
const DRY_GAIN_PERIOD := 1.2
## Kənardan uzaqlaşdıqca sürətlənir: bu məsafədə period yarıya düşür.
const DRY_RAMP := 260.0
```

### Zona qaydası

```
mikrob quru zonadadırsa (|pos| > dish_radius):
    dərinlik = |pos| - dish_radius
    period   = DRY_GAIN_PERIOD / (1 + dərinlik / DRY_RAMP)
    hər `period` saniyədə: balls += 1
    tutumu aşdısa → partlayır (killer = 0, yəni heç kim hesab almır)
```

**Qida və toplar quru zonada normal davranır.** Yalnız mikrob təsirlənir —
əlavə qayda oyunçunun başında saxlaya biləcəyindən çox olmamalıdır.

**Mikrob quru zonaya İTƏLƏNMİR.** `Sim._confine` yaş radiusa görə yox, həmişə
`WORLD_RADIUS`-a görə saxlayır: quru zona divar deyil, təhlükəli sahədir.
Oyunçu ora **öz seçimi ilə** girir.

### Niyə qazanmaq, itirmək yox

1. Oyunun **imza ölümünü** işlədir — partlayış, top yağışı, ekran zərbəsi.
   Aclıqla sönmək sönükdür.
2. **Dilemma yaradır:** kənar həm təhlükə, həm yemdir. Boşalmış oyunçu qəsdən
   çölə çıxıb dolduraraq qayıda bilər.
3. **Dolu oyunçunu mərkəzə sıxır**, ac oyunçu isə kənarda nəfəs alır — sahə
   daraldıqca güclünün yeri azalır.

### Görüntü

| Element | Necə |
|---|---|
| Quru döşəmə | `dish_floor.svg`-nin ikinci variantı: kəhrəba-boz, sediment qalın |
| Sərhəd | Qalın (18 px), yavaş nəbz vuran halqa, `WARNING` rəngi |
| Zərrəciklər | Quru zonada **çəkilmir** — su qurudu |
| HUD | Quru zonada `_warn_lbl`: “QURUYUR — mərkəzə get” |

Çəkiliş qiyməti: **+1 çağırış** (sərhəd halqası). Quru döşəmə eyni teksturanın
ikinci nüsxəsidir, batch qırılmır.

---

## 4. Komandalar

### Bit yerləşməsi

`GF.FLAGS` sahəsində 0–7 doludur (qalxan, növ, super doluluğu, super aktiv).
Komanda **8–9-cu bitlərə** girir — yenə **sıfır əlavə bayt**.

```gdscript
enum GFlag {
    SAFE = 1,
    SPECIES_SHIFT = 1,  SPECIES_MASK = 6,
    CHARGE_SHIFT = 3,   CHARGE_MASK = 120,
    SUPER = 128,
    TEAM_SHIFT = 8,     TEAM_MASK = 768,   ## bit 8-9 → 0..3
}
```

`GermState.team: int` — `-1` komandasız (ENDLESS, SOLO).

### Qaydalar

| Qayda | Harada |
|---|---|
| Yoldaşa top dəymir | `Sim._step_shots` — hədəf seçimində `g.team == s.team` atlanır |
| Yoldaş yoldaşı itələmir | `_separate_germs` **DƏYİŞMİR** — üst-üstə düşmək oxunmazlıq yaradır |
| Trixosist yoldaşı itələyir | Dəyişmir: itələmə zərər deyil, hətta yoldaşı qurtara bilər |
| Aksopodiya toru yoldaşı yavaşlatmır | `_net_slow` komandaya baxır |

### Rəng və tanınma

10 fərqli mikrob rəngi qalır — **komanda rəngi onları əvəz etmir**. Səbəb:
rəng "kim" sualına cavab verir, komanda isə "dost ya düşmən" sualına. İkisi
ayrı sualdır.

| Kanal | Necə |
|---|---|
| Ad yazısı | Yoldaşın adı **laym**, düşmənin adı ağ |
| Xəritə nöqtəsi | Yoldaş halqalı, düşmən dolu |
| Membran | Yoldaşın konturunda nazik laym halqa (doğuş qalxanından fərqli: kəsiksiz) |

### Dirilmə (yalnız DUO)

```gdscript
const REVIVE_TIME := 15.0
```

Yoldaş sağdırsa 15 saniyə sonra qayıdır:
- `balls = START_BALLS`, **`capacity = START_CAPACITY`** (bütün böyümə gedir)
- `safe_t = SPAWN_SAFE_TIME`
- Mövqe: yoldaşın yanında, yaş radiusun içində
- Super doluluğu **sıfırlanır**

Yoldaş da ölübsə — cüt matçdan çıxır, yer verilir.

---

## 5. Spor (güc kublarının qarşılığı)

Brawl Stars-da güc kubu can və zərər artırır. Bizdə artan şey **tutumdur** —
onsuz da partlatmanın mükafatı odur.

```gdscript
const SPORE_COUNT := 3           ## Qabda eyni anda
const SPORE_RESPAWN := 20.0      ## Yeyiləndən sonra
const SPORE_RADIUS := 22.0       ## Adi qida 10-dur
## Verdiyi tutum — partlatma ilə EYNİ. İki yol, bir mükafat.
const SPORE_CAPACITY := CAPACITY_STEP
```

- Yalnız SOLO və DUO-da. TRIO qısadır və komanda balansını pozar.
- Yaş radiusun **içində** doğulur, mərkəzdən uzaqda (`0.4r`–`0.85r` zolağı).
- Görüntü: adi qidadan iki dəfə iri, yavaş nəbz vuran, `FOCUS` rəngli halqalı.
- Yeyəndə `+SPORE_CAPACITY` tutum, `+1` top. Səs: `level_up`.

**Şəbəkə:** sporlar qida massivində gedir, dördüncü sahə ilə yox — ayrıca
`PackedFloat32Array` (mövqe + id), çünki qida axını `FOOD_STRIDE = 3` ilə
sıx paketlənib və onu pozmaq bahalıdır.

---

## 6. Rejimlərin tam qaydaları

### 6.1 SONSUZ ARENA (`ENDLESS`)

**Dəyişmir.** Faza həmişə `PLAYING`, radius sabit, komanda yoxdur, spor yoxdur.
Oyunçu partlayanda nəticə ekranı görür və menyuya qayıdır — indiki davranış.

Bu rejim **təhlükəsizlik şəbəkəsidir**: matçlı rejimlərdə problem olsa, oyun
yenə oynanır.

### 6.2 TƏK QALAN (`SOLO`)

| Parametr | Dəyər |
|---|---|
| Mikrob | 10 (`WORLD_CAPACITY`) |
| Botlar | Boş yerləri **dərhal** doldurur |
| Dirilmə | Yoxdur |
| Qab | `1200 → 250`, 45-ci saniyədən başlayaraq 105 saniyəyə |
| Spor | 3 ədəd |
| Qalib | Sona qalan bir mikrob |
| `MATCH_MAX` | Ən çox topu olan udur |

**Yer:** partlayan mikrob o anda **sağ qalanların sayı + 1** yerini alır. Yəni
ilk ölən 10-cu, qalib 1-ci.

**Nəticə ekranı:**
```
2-ci YER            (10 mikrobdan)
Partlatdığın: 2 · Tutum: 20 · Yaşadın: 1:47
```

### 6.3 CÜT (`DUO`)

SOLO-nun hər qaydası + komanda. Ayrı arena **deyil**.

| Parametr | Dəyər |
|---|---|
| Komanda | 5 × 2 |
| Dirilmə | 15 s, yoldaş sağdırsa (§4) |
| Qalib | Sona qalan cüt |
| Yer | Cütə verilir (1-ci..5-ci) |

Yoldaş botdursa: bot yoldaşı qorumur, sadəcə ona atmır — bot AI-nin
mürəkkəbləşməsi bu mərhələdə lazım deyil.

### 6.4 ÜÇLÜK (`TRIO`)

| Parametr | Dəyər |
|---|---|
| Mikrob | 6 (3v3) |
| Qab | `700` başlanğıc; 40-cı saniyədən `220`-yə |
| Raund | 60 saniyə |
| Dirilmə | **Yoxdur** (raund boyu) — ölən insan yoldaşını izləyir və növbəti raundda doğulur |
| Raund qalibi | Rəqib komanda tam çıxdı, yaxud vaxt bitəndə **çox mikrobu qalan** |
| Matç qalibi | Üç raundun ikisini udan |
| Spor | Yoxdur |
| Bərabərlik | Vaxt bitəndə sağ sayı bərabərdirsə — **top cəmi çox olan** |

Raund arası 3 saniyə: hesab göstərilir (`1 — 0`), sonra hamı yeni yerdə,
`START_BALLS` və `START_CAPACITY` ilə doğulur. **Tutum raunddan raunda
keçmir** — hər raund bərabər başlayır.

---

## 7. Şəbəkə

### Snapshot-a əlavə

`Snap` enum-una **sonda** yeni sahə əlavə olunur (ortada yox — client
indekslə oxuyur):

```gdscript
enum Snap { TICK, GERMS, SHOTS, FOOD, EVENTS, BOARD, POP, WALLS, MATCH }
```

`MATCH` — bir massiv, **dünya başına bir dəfə** (mikrob başına yox):

```gdscript
enum MF {
    MODE,       ## int   — Mode
    PHASE,      ## int   — Phase
    CLOCK,      ## float — fazanın öz saatı (saniyə)
    RADIUS,     ## float — yaş radius (client düsturla da hesablaya bilər,
                ##         amma bir float göndərmək daha ucuzdur, bax §8)
    SCORE_A,    ## int   — TRIO raund hesabı
    SCORE_B,
    ALIVE,      ## int   — sağ qalan mikrob sayı (yer hesablamaq üçün)
}
```

**Qiymət:** 7 ədəd × 9 bayt = **63 bayt / snapshot**, mikrob sayından asılı
deyil. 30 Hz-də ~1.9 KB/s. Qəbul edilə bilər — qida axını bundan qat-qat
ağırdır.

### Komanda və yer

- Komanda → `GF.FLAGS` bit 8–9 (**0 bayt**)
- Yer → yalnız partlayanda, `you_burst` mesajında (onsuz da göndərilir)

### `join_info_for` əlavəsi

```gdscript
"mode": int(mode),
"team": g.team,
```

---

## 8. Prediction müqaviləsi

**Ən böyük risk budur.** Client öz mikrobunu özü hesablayır; server ilə fərq
olsa mikrob hər snapshot-da geri sıçrayır.

| Şey | Client bilirmi | Necə |
|---|---|---|
| Yaş radius | **Bəli** | Snapshot-dakı `MF.RADIUS`. Düsturla da hesablana bilər, amma faza keçidləri (raund başlanğıcı) saatı sıfırlayır — bir float göndərmək səhv riskini aradan qaldırır |
| Quru zona zərəri | **Xeyr** | Metabolizm kimi: `_no_metabolism` bayrağı altında, yalnız serverdə. Client top sayını proqnozlaşdırmır |
| Komanda | Bəli | Bayraqdan |
| Faza | Bəli | Giriş `COUNTDOWN`-da bloklanır — client də bloklamalıdır, yoxsa hərəkət proqnozu serverdən qabağa düşür |

**Qayda:** quru zona `Sim._step_germs`-də **`_no_metabolism` yoxlamasının
altında** olmalıdır. Əks halda client top sayını özü artırar və hər snapshot
onu düzəldər — HUD-dakı rəqəm yanıb-sönər.

---

## 9. Matchmaking — oyunçu HEÇ VAXT gözləmir

**Növbə yoxdur.** OYNA basan kimi:

1. Lobby həmin rejimdə **yer olan** dünya axtarır (`WAITING` və ya
   `COUNTDOWN` fazasında).
2. Tapmasa yeni dünya açır və `WAITING`-ə qoyur.
3. Oyunçu girən kimi faza `COUNTDOWN` olur, boş yerlər **botla** dolur.
4. 3 saniyə sonra matç başlayır.

**Sonra gələn insan botun yerini alır** — yalnız `COUNTDOWN` fazasında.
`PLAYING` başlayandan sonra dünya bağlıdır; gec gələn yeni dünyaya düşür.

Səbəb: oyunçu bazası kiçikdir. Növbə "boş oyun" hissi yaradır — gözləyirsən,
heç kim gəlmir, çıxırsan. Menyuda yazılmış vədin (*"girdin, oynadın"*) davamıdır.

### Bağlantı kəsilməsi

Mövcud `REJOIN_GRACE = 20.0` matçlı rejimlərdə də işləyir: mikrob dünyada
qalır, tərpənmir, vurula bilir. Matç bitsə və oyunçu hələ qayıtmayıbsa,
nişan ləğv olunur.

---

## 10. Botlar

| Rejim | Bot nə etməlidir |
|---|---|
| Hamısı | Quru zonadan qaçmalı: yaş radiusun `0.85`-indən kənardasa mərkəzə |
| SOLO/DUO | Spor görsə ona getməli (adi qidadan üstün tutur) |
| DUO/TRIO | Yoldaşa **atmamalı** (hədəf seçimi komandaya baxır) |
| TRIO | Əlavə davranış yoxdur — sadə qalır |

Bot yoldaşını **qorumur** və koordinasiya etmir. Bu mərhələdə lazım deyil:
bot mükəmməl oynamamalıdır.

---

## 11. Menyu və HUD

### Menyu — rejim seçicisi

OYNA düyməsinin üstündəki lövhə seçiciyə çevrilir (yeri hazırdır):

```
SONSUZ ARENA   girdin, oynadın · gözləmə yoxdur
TƏK QALAN      10 mikrob · sona qalan udur · qab quruyur
CÜT            5 cüt · yoldaşın səni qaytarır
ÜÇLÜK          3v3 · üç raundun ikisi · dirilmə yoxdur
```

Seçim `settings.cfg`-də saxlanılır (növ kimi).

### HUD əlavələri

| Element | Nə vaxt | Yer |
|---|---|---|
| Geriyə sayım | `COUNTDOWN` | Mərkəz, böyük: `3 · 2 · 1` |
| Sağ qalan | SOLO/DUO | Liderlər cədvəlinin üstündə: `SAĞ: 7` |
| Raund hesabı | TRIO | Yuxarı mərkəz: `1 — 0` |
| Matç saatı | TRIO | Raundun qalan vaxtı |
| Quruma xəbərdarlığı | Quru zonada | Mövcud `_warn_lbl` |
| Yoldaş oxu | DUO/TRIO | Ekrandan kənardasa kənarda kiçik ox |

### Nəticə ekranı

Mövcud `Hud.show_result` genişlənir: başlığa **yer** və ya **raund hesabı**
əlavə olunur. ENDLESS-də dəyişmir.

---

## 12. Bütün sabitlər bir yerdə

```gdscript
# ---------- Matç ----------
const COUNTDOWN_TIME := 3.0
const ROUND_BREAK := 3.0
const RESULT_TIME := 5.0
const MATCH_MAX := 240.0

# ---------- Quruyan qab ----------
const DRY_DELAY := 45.0
const DRY_TIME := 105.0
const SOLO_END_RADIUS := 250.0
const TRIO_START_RADIUS := 700.0
const TRIO_END_RADIUS := 220.0
const DRY_GAIN_PERIOD := 1.2
const DRY_RAMP := 260.0

# ---------- Komanda ----------
const REVIVE_TIME := 15.0
const DUO_TEAMS := 5
const TRIO_TEAM_SIZE := 3
const TRIO_ROUND_TIME := 60.0
const TRIO_ROUNDS_TO_WIN := 2

# ---------- Spor ----------
const SPORE_COUNT := 3
const SPORE_RESPAWN := 20.0
const SPORE_RADIUS := 22.0
const SPORE_CAPACITY := CAPACITY_STEP
```

**Toxunulmaz qalanlar:** `SHOT_PAYLOAD`, `FIRE_COOLDOWN`, `CAPACITY_STEP`,
`MIN_BALLS`, `FIRE_MIN_BALLS`. Rejim heç birini dəyişmir — bunlar oyunun
riyaziyyatıdır və `sim_test` onları qoruyur.

---

## 13. Testlər (tətbiqlə birlikdə yazılmalı)

| Test | Nəyi qoruyur |
|---|---|
| Faza ardıcıllığı düzgündür | Vəziyyət maşını sıçramır |
| ENDLESS həmişə `PLAYING`-dədir | Köhnə rejim yeni sistemdən təsirlənmir |
| `dish_radius` yalnız saatdan asılıdır | Prediction müqaviləsi (§8) |
| Quru zonada top ARTIR, azalmır | Açar qərar pozulmayıb |
| Quru zona `_no_metabolism` altındadır | Client top sayını proqnozlaşdırmır |
| Yoldaşa atılan top dəymir | Dost atəşi yoxdur |
| Komanda biti növü/superi pozmur | Bayraq paketlənməsi |
| Sonuncu mikrob qalanda matç bitir | SOLO qalib şərti |
| Yoldaşı ölən cüt matçdan çıxır | DUO qalib şərti |
| İki raund udan matçı udur | TRIO qalib şərti |
| Raund arası tutum sıfırlanır | Hər raund bərabər başlayır |
| Rejimlər döyüş riyaziyyatını dəyişmir | Ən vacibi — mövcud testin genişlənməsi |

---

## 14. Tətbiq ardıcıllığı

| # | Mərhələ | Nəticə |
|---|---|---|
| 1 | **Matç skeleti** — vəziyyət maşını, geriyə sayım, `MATCH` sahəsi, nəticə ekranı | Görünən dəyişiklik yoxdur, bütün texniki risk bitir |
| 2 | **Daralan qab** — `Sim.dish_radius` refaktoru (20 istifadə yeri), quru zona, görüntü | ENDLESS-də radius sabit qalır |
| 3 | **TƏK QALAN** — spor, yer sıralaması, qalib şərti | İlk əsl rejim |

**1–3 bitdi.** Nəticə: 190 headless test keçir, hər iki rejim 60 FPS
büdcəsinin 25%-ni işlədir, `--practice --mode 1` ilə şəbəkəsiz oynanır və
`ws://`-lə server üzərindən yoxlanılıb (`[lobby] dünya #2 açıldı (TƏK QALAN)`).

Tətbiq zamanı dizaynda olmayan üç şey ortaya çıxdı və düzəldildi:

1. **Matçın bitmə şərti `sim.step`-dən SONRA yoxlanmalıdır.** Əvvəl
   yoxlansaydı, sonuncu rəqib partlayandan sonra oyunçu bir kadr boyu ölü
   dünyada qalırdı.
2. **`Hud.set_match` xəbərdarlıq mətnini YAZMAMALIDIR**, yalnız bayraq
   qoymalıdır — `update_gauge` ondan sonra gəlir və üstündən silirdi. Nəticədə
   rejimin ən ölümcül xəbərdarlığı ("QURUYUR") heç vaxt görünmürdü.
3. **Sıra şəkilçisi rəqəmdən deyil, oxunuşundan asılıdır** — `"%d-ci"`
   doqquzda və altıda səhv yazır (9-cu, 6-cı). `Const.ordinal` əlavə olundu.

Sonra rejim TAM matçlarla ölçüldü və dizaynda görünməyən dördüncü problem
çıxdı: **matç heç vaxt döyüşlə bitmirdi.** Beş ölçmənin beşi 240 saniyəlik
vaxt limitinə, 2 sağ qalanla çatırdı.

Səbəb balansda deyildi. Botlar maneəni yalnız ATƏŞ üçün nəzərə alırdı,
hərəkət üçün yox — qab daralıb hamını mərkəzə sıxanda maneəyə dirənib donurdu.
Üç bot matçın son 60 saniyəsində mərkəzdən eyni məsafədə (177, 177, 154 px)
tərpənmədən qalırdı. Bir neçə balans düzəlişi (qida sıxlığı, quruma sürəti,
botun aqressivliyi) nəticəni dəyişmədi, çünki problem balansda deyildi.

Düzəlişlər:

| Düzəliş | Səbəb |
|---|---|
| `Bot._avoid` — maneədən tangens boyunca yan keçmə | **əsl səbəb** — botlar donmurdu artıq |
| Quru zonada qida quruyur (`Sim._dry_food`) | 90 px-lik qabda 293 qida yığılmışdı, heç kim acmırdı |
| Qida hədəfi qabın radiusu ilə miqyaslanır | sabit say daralan qabda sıxlığı partladırdı |
| Son sıxılma: 250 px → 90 px (`SOLO_MIN_RADIUS`) | əsas quruma bitəndən sonra 90 saniyə heç nə dəyişmirdi |
| Botun kənar toleransı qabla miqyaslanır | mütləq 140 px 90 px-lik qabda absurd idi |
| Ac bot rəqib qidadan yaxındırsa döyüşür | daimi ac iki mikrob heç vaxt atəş açmırdı |

Nəticə: **altı matçdan altısı** 2:34–3:34 arasında, tək qalibi ilə bitir —
təsdiqlənmiş 2.5–4 dəqiqə aralığında. `_test_full_solo_match` bunu qoruyur.

Qalibin ekranı da ayrıca quruldu: `QALİB!` başlığı, qızıl xətt, böyümə
animasiyası və "Sonuncu mikrob sənsən" sətri. Qalib PARTLAMADIĞI üçün onun
yeri ayrıca verilir (`World._award_survivors`) — bu olmasaydı, matçı UDAN
oyunçu nəticə ekranında yerini "0" görərdi.

Qalan mərhələlər (4–6) üçün yuxarıdakı cədvəl dəyişməyib.
| 4 | **Komanda infrastrukturu** — bitlər, dost atəşi, rəng, bot | Görünən rejim yoxdur |
| 5 | **CÜT** — dirilmə | Yeni sistem demək olar yoxdur |
| 6 | **ÜÇLÜK** — raund döngəsi | Ən çox vəziyyət saxlayan, ona görə sonuncu |

---

## 15. Açıq suallar

Aşağıdakılar **qərar gözləyir** — dizaynda mövqeyim var, amma son söz sizindir.

| Sual | Mənim təklifim |
|---|---|
| ENDLESS qalsın? | ✅ **QƏRAR: qalır və ilkin rejimdir** |
| Matç ortasında qoşulma olsun? | **Yox** — yalnız `COUNTDOWN`-da. Yarımçıq matça düşmək pisdir |
| Öləndən sonra izləmə (spectate)? | ~~Yox — dərhal menyuya~~ → **2026-11-22: ÜÇLÜK-də BƏLİ.** Menyuya atmaq 3 raund formatını insan üçün bir raunda endirirdi (QA). Yeni şəbəkə axını lazım olmadı: server görüş sahəsini komandanın ən kiçik id-li sağ mikrobuna qurur, client eyni qaydanı snapshot-dan çıxarır (`World.spectate_target`, `Arena._spectate_id`). Qaydalar versiyası 6 |
| Spor TRIO-da olsun? | **Yox** — qısa matçda balansı pozur |
| Yer/hesab yadda saxlansın? | **Yox** — iqtisadiyyat qərarı “sonra”dır |
| TRIO-da 3 raund çoxdurmu? | Sınamaq lazımdır. Raund 60 s → matç ~3.5 dəqiqə. Uzun gəlsə: 2 raund |

---

## 16. Obyekt rejimləri — ANA HÜCEYRƏ, YAŞ ADA, NÜVƏ TOPU (2026-10-21)

Sahib təqdimatdan («CÜT və ÜÇLÜK — Ssenarilər») üçünü seçdi: **ANA HÜCEYRƏ** və
**YAŞ ADA** ÜÇLÜK (3v3) üçün, **NÜVƏ TOPU** CÜT (2v2) üçün. Şərt: hər rejimin
**öz xəritəsi** — yalnız rejimə lazım olan maneələr. Köhnə CÜT/ÜÇLÜK dəyişmir.

Rəqəmlər botlu matçlarla ölçülüb (`--objtest --probe --no-human`, rejim başına 20 toxum)
və aşağıda niyə belə olduqları yazılıb. Testlər: `game/scripts/tools/objective_test.gd`.

### 16.1 Ümumi qayda

| | ANA HÜCEYRƏ | YAŞ ADA | NÜVƏ TOPU |
|---|---|---|---|
| `Mode` | `MOTHER = 4` | `ISLAND = 5` | `BALL = 6` |
| Komanda | 2 × 3 | 2 × 3 | 2 × 2 |
| Qabın şüşəsi (radius) | 800 | 720 | 640 |
| Matç | 2:30 (+30 s əlavə) | 3:00 (+bərabərlikdə ilk xal) | 2:30 (+45 s ilk qol) |
| Ölüm | 5 s sonra öz yuvasında | 5 s sonra öz kənarında | 4 s sonra öz yarısında |
| Qalib | rəqib Ana partlayır / 2:30-da daha boş Ana | ilk 70 xal | ilk 2 qol |

- **Şüşə rejimə görədir** (`Const.wall_radius`): kiçik komanda kiçik qabda oynayır,
  NÜVƏ TOPU-nun qapısı isə məhz şüşənin üstündədir.
- **Xəritə rejimə görədir** (`DishMap.obstacles_for(Const.mode_layout(mode))`):
  köhnə rejimlər HALQALAR düzümündə qalır.
- Dirilmədə tutum 10-a, top 5-ə qayıdır; superin doluluğu QALIR. Bazaya yaxın doğulur,
  4 s qalxanla.
- Mikroblar arasında döyüş riyaziyyatı (zərbə +2, atəş −1, partlatma +5 tutum, soyuma,
  döşəmələr) **toxunulmazdır**. Yeni şeylər mövqeyə, obyektə və vaxta təsir edir.
- Komanda 0 qərbdə, komanda 1 şərqdədir. Rənglər baxana görədir: **bizimki laym, onlarınkı
  narıncı**.
- Geri sayımda botlar da dayanır (insanların girişi onsuz da bağlıdır) — BÜTÜN matçlı
  rejimlərdə. Əvvəl botlar sayımda tərpənirdi: NÜVƏ TOPU-nda qoldan sonrakı sayımda Nüvəni
  qapıya itələyirdilər (qol sayılmırdı, Nüvə yox olurdu), CÜT/ÜÇLÜK-də isə insandan 3 s
  qabaq yer seçirdilər. Ölçü (12 botlu matç): sayımda mikrobların cəmi yerdəyişməsi
  4.5–7.6 min px → 0.6–1.4 min px (qalanı su axınının sürüşdürməsidir, insana da eynidir).
- Komandalı rejimdə bot yoldaşını hədəf seçmir (`Bot._nearest_enemy`). Əvvəl CÜT/ÜÇLÜK
  botları ən yaxın mikroba nişan alırdı və top yoldaşın içindən keçib boşa gedirdi. Ölçü
  (12 matç): yoldaşa nişan CÜT 21% → 1%, ÜÇLÜK 28% → 3%; mikroba dəymə CÜT 35% → 38%,
  ÜÇLÜK 28% → 38%; CÜT matçı orta 148 s → 115 s (hamısı yenə sona qalan cütlə bitir).

### 16.2 ANA HÜCEYRƏ

- Hər komandanın bazasında hərəkətsiz **ANA**: tutum **140**, **70** topla başlayır,
  radius 100. Maneədir (`DishMap.Kind.MOTHER`): mikrobu və topu saxlayır.
- **Rəqibin topu** Anaya girir və onu **+1** doldurur (`MOTHER_FEED`); 140-ı keçəndə Ana
  partlayır — matç bitir. **Öz topun** Anadan sıçrayır (dost atəşi yoxdur). +2 ilə botlu
  matçların üçdə biri 60 s-dən tez bitirdi: partlatmalarla böyüyən hücumçu yuvanın ağzında
  dirilənləri vururdu, yoldaşları Ananı 35 s-də doldururdu.
- **Əmmək:** öz Anana toxunanda hər **0.4 s**-də 1 top Anadan sənə keçir; Ana **80%-i**
  keçibsə **0.2 s**. Şərt: Ana 30%-dən doludur və sən tutumun bir topundan aşağısan —
  əmmək səni heç vaxt partlatmır. Əmilən top elə hücumun sursatıdır: əm, dol, rəqibin
  Anasına at — rejimin dövrü budur.
- Yuva: Ananın qarşısında üç selik (ağızlar 87 px — açıq), arxada şüşə ilə selik arasında
  50 px-lik **arxa qapı** — yalnız amöb (tutum ≤ 13) sığır.
- 2:30-da daha BOŞ Ana udur. Fərq 6 topdan azdırsa **30 s əlavə vaxt**: əmmək dayanır,
  iki Ana da saniyədə +1 top dolur, birinci partlayan uduzur; sonda yenə bərabərdirsə —
  heç-heçə.
- Botlu ölçü (20 matç): 8:11 qələbə, 1 heç-heçə; 4 matç partlamaqla bitir, ən qısası 61 s.
- Növlərin fərqli adi atəşindən sonra (§17, 20 matç, eyni toxumlar): hamısı qaliblə; Ana
  **1** matçda partlayır (köhnə kodda 6), matç başına Anaya dəymə 73 (köhnə 77).

### 16.3 YAŞ ADA

- 0:20-yə qədər qab yaşdır. 0:20–0:25 arasında hər yer quruyur, yalnız **r 220**-lik ada qalır.
- Ada orta xətt (x = 0) boyunca şimal–cənub yırğalanır (±340 px, **64 s**-lik dövr). Yeri
  YALNIZ matç saatından çıxır (`Const.wet_circle`) — proqnoz müqaviləsi qorunur. Bazalar
  qərbdə və şərqdədir, yəni ada hər an iki bazadan EYNİ uzaqdadır. Əvvəlki «səkkiz» yolu
  ilk ilmədə qərbə əyilirdi və komanda 0 ondan yeddi-səkkiz matçı udurdu.
- Quru zona burada **cəbbəxanadır**: hər **2 s**-də +1 top (dərinlikdən asılı deyil),
  doğuş qalxanında yığılmır. Qida yalnız adada doğulur, quruda qalan qida quruyur.
- Adada SAĞ mikrobu çox olan komanda saniyədə **+1 xal**. 25+ xal geridə qalan komanda
  adadakı bərabərliyi özünə yazır.
- İlk **70** xal udur; 3:00-da çox xalı olan; bərabərdirsə ilk xal fərqi qərar verir
  (ən gec 4:00, sonra heç-heçə). 100 xalla botlu matçların çoxu vaxtla bitirdi (72–93 xal).
- Xəritə: ada zolağında (|x| ≤ 220) heç nə yoxdur; dörd dirək (±320, ±240) yolda sığınacaq,
  dörd kol bazaların yanında, iki cərəyan deşiyi (±470, 0) dirilən mikrobu adaya atır.
- Botlu ölçü (16 matç): 13-ü 70 xalla bitir, qələbələr 6:10.

### 16.4 NÜVƏ TOPU

- Mərkəzdə neytral **NÜVƏ**: çəkisi **20**, radiusu `30 + (çəki − 20) × 0.8`.
- Gövdə ilə itələmək **pulsuzdur** (Nüvə mikrobu itələmir — proqnoz toxunulmaz qalır).
  Təkan mikrobun normal sürətinin **2 misli**dir; Nüvə suda ~3 s sürüşür. Bir neçə mikrobun
  təkanı toplanıb bir dəfə tətbiq olunur — sıradan asılı deyil, qarşı-qarşıya itələmə ləğv olur.
- Mikroba çırpılan Nüvə şüşədəki kimi **0.6** ilə sıçrayır; mikroblar Nüvəni əvvəlki
  sürətindən və ən güclü tək itələmədən sürətli edə bilmir. Əvvəl təmas tam elastik idi və
  mikrobun sürətini üstə gəlirdi: iki rəqibin arasında sıxılan Nüvə hər tick sürət yığırdı
  (ölçülüb: 0.3 s-də 350 → 1436 px/s, 5.9 s-də iki qol). İndi ən çox ~400 px/s.
- Topla vurmaq onu itələyir (`200 × 20 / çəki` px/s) və **+2 çəki** verir; 40-ı keçəndə
  Nüvə partlayır, 2 s sonra mərkəzdə yenisi. Çəki 1.5 s-də 1 azalır (20-yə qədər).
- TRİXOSİST itələməsi Nüvəyə də təsir edir. Suyun burulğanı onu **35%** aparır (tam axında
  Nüvə şüşəyə yapışıb qalırdı). Şüşənin **menisküsü**: kənardan 40 px-ə yaxın Nüvə içəri
  yuvarlanır — şüşəyə sıxılmış Nüvənin arxasına mikrob sığmırdı.
- **Qapı (məsamə)** şüşədədir: qərbdəki komanda 0-ın, şərqdəki komanda 1-in. Eni 236 px,
  iki yanında selik dirəyi (585, ±150). Nüvə rəqibin qapısına girəndə **qol**: hamı yerinə
  qayıdır, 3 s sayım (matçın saatı dayanır).
- İlk **2** qol udur; 2:30-da çox qolu olan; bərabərdirsə **45 s** ərzində ilk qol, sonra heç-heçə.
- Botlu ölçü (20 matç): 14-ü qaliblə, matç başına 1.1 qol. §17-dən və təkanın düzəlişindən
  sonra (20 matç, eyni toxumlar): 15-i qaliblə, 22 qol (köhnə kod: 13 qaliblə, 20 qol).

### 16.5 Şəbəkə

- Komanda bitləri dəyişmir. `MF`-ə sonda iki sahə gəlir: `OBJ` (rejimin obyekti,
  `PackedFloat32Array`) və `RESPAWN` (baxanın dirilməsinə qalan saniyə).
  `SCORE_US/EM` — ANA-da Anaların top sayı, ADA-da xal, TOP-da qol.
- `OBJ`: birinci ədəd matçın saatıdır (qoldan sonrakı sayım fazanın saatını sıfırlayır,
  matçınkını yox); sonra ANA — `[əlavə vaxt 0/1]`; ADA — `[x, y, r]`;
  TOP — `[x, y, vx, vy, çəki, sağ 0/1]`.
- Ölüm obyekt rejimində nəticə ekranı AÇMIR: mikrob doğulma növbəsinə düşür, nəticə hamıya
  matçın sonunda gedir (`draw`, `score_us`, `score_them` əlavə açarları ilə).
- Köhnə client yeni sahələri oxumur; yeni client köhnə serverdə də işləyir (sahələr yoxdursa
  sadəcə istifadə olunmur).

## 17. Növlərin fərqli adi atəşi və obyekt rejimləri (2026-10-28)

Qaydalar README-dədir («Hər növün öz atəşi»): kirpiklinin oxu, ayaqlının iki iynəsi (hərəsi +1),
amöbün damcısı, superdə miniqan. Hərəkət başına −1 top, mikroblara cəmi ən çox +2.

- **Ana** hərəkət başına `MOTHER_FEED` (+1) dolur — iki iynə də, damcı da Ananı iki dəfə
  doldurmur. Damcı Ananın kənarına düşəndə (sahəsi Anaya toxunur) Ana onu udur; öz Ananın
  yanına düşən damcı qida olur. Damcı yuvanın seliklərinin üstündən keçir.
- **Nüvə** hərəkət başına cəmi **+2 çəki və bir təkan** alır. Damcının təkanı uçuş
  istiqamətindədir.
- **Düşmə qərarı:** sahədə rəqib varsa — ona; yoxdursa Nüvəyə; yoxdursa rəqibin Anasına;
  yoxdursa qida.
- **Botlar:** ayaqlı Anaya yalnız iynələrin çatdığı yerdən atır (iynə məsafəsinin 85%-i),
  amöb düşmə nöqtəsini Ananın kənarında, rəqib mikroblardan ən uzaq yerdə seçir
  (Anaya nişanlanan damcıların 93%-i Anaya düşür; əvvəl 31%-i Anaya toxunub əmən
  müdafiəçiyə düşürdü). Nüvəyə atəş profilə görədir: iynələr yalnız ikisi də dəyəcəyi
  yaxınlıqdan (əvvəl 320 px-dən atılan iynələr Nüvənin yanından keçirdi).
- Ölçü (`--objtest --probe --no-human`, 20 toxum, köhnə → yeni): NÜVƏ TOPU qalibli 13 → 15,
  qol 20 → 22; ANA HÜCEYRƏ qalibli 20 → 20, Ananın partlaması 6 → 1; YAŞ ADA (14 toxum)
  xalla bitən 14 → 13.
- **Ana niyə az partlayır:** matçlar bərabərləşib. Matç başına Ana yemləməsi 72 → 65,
  komandalar arasındakı fərq 46 → 26 yemləmə, ölüm 31 → 35. Əvvəl bir komanda birtərəfli
  üstün gəlib rəqibin Anasını partladırdı. İki variant yoxlandı — Ananın tutumu 140 → 130 və
  başlanğıc doluluğu 70 → 76; hər ikisi 20 matçda yenə 1 partlama verdi, ona görə qayda
  dəyişmədi. Partlama tez-tez olsun, yoxsa bərabər matçlar xalla bitsin — sahibin qərarıdır
  (rəqəmlər botlarladır, insanlarla yoxlanmalıdır).

## 18. Qida koloniyaları — SONSUZ ARENA (2026-10-28)

Məqsəd: oyunçu üç qida yolu arasında seçsin — mərkəzə yaxın **bol** mənbə (döyüş orada
olur), kənarda **zəif** mənbə və səpələnmiş qida. Koloniya neytraldır: tutmaq xal vermir,
komanda sahibliyi və qoruma yaratmır. Yalnız `Mode.ENDLESS`; qalan altı rejimin qida, spor
və obyekt qaydaları dəyişmir (test: join info və snapshot-da koloniya sətri boşdur, TƏK
QALAN-da qida köhnə hədəfə dolur).

### 18.1 Qaydalar (rəqəmlər prototipdir, `constants.gd` «Qida koloniyaları»)

| | Bol (2) | Zəif (2) |
|---|---|---|
| Mərkəzdən | 350–500 px | 750–900 px |
| Ehtiyat | 20 | 12 |
| İstehsal dövrü | 0.45 s | 0.8 s |
| Tükənəndən sonra bərpa | 24 s | 30 s |
| Dünyada udulmamış qidası | ≤ 8 | ≤ 8 |

- Koloniya ətrafına (mərkəzdən ≤ 56 px) **adi +1 qida** çıxarır, udma qaydası eynidir
  (tutum doludursa yemirsən, `food_acc` və super doldurma eynidir). Hər qida ehtiyatdan bir
  vahid çıxır. Ehtiyat sıfır olanda istehsal dayanır, bərpa sayğacı başlayır; vaxt bitəndə
  ehtiyat dolur, əvvəlki qida yerində qalır, səkkiz hədd yenə işləyir.
- **Səkkiz hədd mənşəyə görədir** (`FoodState.origin`, yalnız serverdə): axın qidanı uzağa
  aparsa da koloniyanınkı sayılır. Say hər tick qidanın özündən yığılır — udulma, quruma və
  ya başqa silinmə yolu olsa da hesab düz qalır.
- **Borc yoxdur:** gözləmədə (8 çıxış, ümumi hədəf) sayğac sıfırda dayanır; yer açılanda bir
  qida çıxır, sonra ritm. Böyük addımda (5 s, 60 s) da koloniya başına ən çoxu 8, səpələnmiş
  ən çoxu 32 qida — test edilib.

### 18.2 Qida iqtisadiyyatı (`Sim._spawn_ecology`)

1. **Səpələnmiş (ekoloji) qida** öz canlı hədəfinə — **32** — adi doğuş sürəti ilə
   (8/s) qayıdır və 32-də dayanır. Köhnə generator dünyanı 110 səpələnmiş qida ilə doldururdu;
   indi o, yalnız SONSUZ ARENA-dan kənarda işləyir. Ölüm səpintisi və boşa çıxan top (mənşə
   `LOOSE`) bu minimumun əvəzi sayılmır və **limit üçün silinmir**. Bu minimum ümumi
   hədəfin içində bilərəkdən qorunan istisnadır, sərt maksimum deyil.
2. **Koloniyalar** ümumi hədəfdən (`_food_target()` = 110) qalan yerdə işləyir: dünyadakı
   bütün qida hədəfi keçibsə istehsal dayanır.

### 18.3 Yer, şəbəkə, görüntü

- **Yer** (`DishMap.colony_spots`): düzüm + toxumdan deterministik. Bol cüt qarşı-qarşıya,
  zəif cüt onlara dik. Əvvəl toxumdan 24 namizəd, sonra bucaq × məsafə şəbəkəsi; sahə
  (90 px) şüşənin içində və **hər** maneədən (kol və cərəyan deşiyi də) aralı, koloniyalar
  arası ≥ 420 px, ən azı iki ayrı tərəfdən (aralarında > 90°) yaxınlaşılır. Uyğun yer
  yoxdursa koloniya qoyulmur və xəbərdarlıq yazılır (maneəyə səssizcə düşmür). Üç ümumi
  düzümdə 40 toxumun hamısında dördü də yerləşdi (ən az 2–3 tərəf). Koloniya bərk deyil.
  Toxumu dünya yaranarkən server seçir; client yerləri join info-da alır.
- **Şəbəkə:** join info `colonies` = `[x, y, növ] × 4`; snapshot-un sonunda
  `Snap.COLONY` = hər koloniyaya 2 bayt (ehtiyat, bərpaya qalan vaxt 0.25 s vahidində) —
  serializasiya ilə 16 bayt, `SNAP_FIXED` 330 → 346. Hər snapshot-da TAM gedir, AOI-siz
  (dörd sabit mənbə, mikrob məlumatı yoxdur). Qaydalar versiyası 2 → 3: köhnə client
  "oyunu yenilə" alır.
- **Görüntü** (`ColonyView`): qida rəngində (glow həddindən aşağı) hüceyrə rozeti — bol 9,
  zəif 6 hüceyrə; doluluq azaldıqca hüceyrələr bir-bir kiçilir, tükənəndə quru boz nüvə və
  12-dən dolan bərpa halqası. Vəziyyət yalnız snapshot-dan; doluluq yumşaq yaxınlaşır, halqa
  yerli saatla gedib hər snapshot-la düzəlir. Hər koloniya ayrı node-dur və yalnız görüntüsü
  dəyişəndə çəkilir. YÜKSƏK və MİNİMUM-da eyni oxunur (ekran görüntüsü ilə yoxlanıb).
  Minimap: qida rəngində nöqtə (bol iri), az qalanda sönük, tükənəndə boz halqa.
- **Botlar** (`Bot._pick_colony`): ac bot, yaxında (200 px) qida yoxdursa, koloniyanı
  `məsafə − 14 × qida (≤ 12) + 300 × görünən rəqib` dəyəri ilə səpələnmiş qida ilə müqayisə
  edir. Rəqib yalnız botun gördüyüdür (görüş sahəsi, başqa kol yox). Tükənmiş və sahəsi boş
  koloniya seçilmir; sahəsinə çatıb qida tapmadığı koloniyanı bot 8 s saymır. Dolu bot ora
  göndərilmir. Ayaqlının toru koloniya qidasını adi qida kimi çəkir (ehtiyat təkrarlanmır).

### 18.4 Ölçü (2026-10-28)

**Botlu dünya**, SONSUZ ARENA, 12 toxum × 180 s (köhnə → yeni; skript scratch-dadır):

| | Köhnə | Yeni (spesifikasiya) | Variant: hədəfdə yalnız ekoloji qida |
|---|---:|---:|---:|
| Partlatma / dəq | 7.50 | 7.53 | 8.61 |
| Aclıqdan ölüm / dəq | 0.08 | 0.19 | 0.03 |
| İlk ölüm (orta) | 18.1 s | 8.6 s | 8.6 s |
| Ac bot-tick-ləri | 17.0% | 19.1% | 15.3% |
| Xəritədə qida (orta) | 205 | 202 | 230 |
| Yeyilən qida / dəq | 182 | koloniya 17, səpələnmiş 26, səpinti 154 | koloniya 39, səpələnmiş 25, səpinti 163 |
| Koloniyaya gəliş / dəq | — | 14.2 | 14.6 |
| Tükənmə / dəq | — | 0.64 | 2.75 |

Koloniyanın halı (8 toxum × 180 s): **spesifikasiyada 79% vaxt ümumi hədəfə görə
dayanır** (işləyir 4%, tükənib 7%, 8 hədd 11%) — çünki botlu matçda xəritədə orta 162
səpinti (boşa çıxan top, ölüm) qidası var və o, 110-luq hədəfi tək başına keçir.

**Açıq sual (sahibin qərarı):** spesifikasiya "ümumi hədəf keçilibsə koloniyanı dayandır"
deyir və kod belədir. Ölçüyə görə aktiv matçda koloniyalar çox vaxt susur, seçim azalır.
Variant — hədəfə yalnız ekoloji qidanı (səpələnmiş + koloniya) saymaq — koloniyaları
canlandırır (tükənmə 0.64 → 2.75/dəq, aclıq 0.19 → 0.03/dəq), amma xəritədə qida artır
(202 → 230) və döyüş bir az çoxalır (7.5 → 8.6/dəq). Dəyişiklik `_spawn_ecology`-də üç
sətirdir. Hər ikisi botlarladır — insanlarla yoxlanmalıdır.

**İlk ölüm erkən gəlir** (18 → 8.6 s): ac botlar mərkəzə yaxın bol mənbədə görüşür. Bu,
"riskli bol mənbə" ideyasıdır, amma əhali testi (`_test_endless_untouched`) bir anlıq
"5 / 6" ilə düşürdü (60 təzə dünyanın 5-də 6.7 s-də); test indi dolmanı yoxlayır.

**Paket** (10 mikrob, baxan ən sıx yerdə, 6 toxum × 90 s): orta 809 → 844 bayt, p99
1060 → 1116, maks 1164 → 1244, MTU-nu (1392) aşan 0 → 0. Fərq: koloniya sətri 16 bayt +
bir az çox qida (27.8 → 29.1 / snapshot).

**Kadr:** serverin tick-i (10 bot, masaüstü) 0.553 → 0.572 ms. Masaüstü məşq (kirpikli,
`--auto`, 2 cüt): 240 FPS-də proses 0.52–0.57 → 0.58–0.60 ms. Android emulyatoru (APK,
kirpikli məşq, 60 Hz): köhnə 5 qaçış orta 6.16 ms, yeni 6 qaçış orta 7.19 ms, hamısı 60 FPS
və ilişməsiz. Görüntüsü söndürülmüş variant (koloniyalar oyunda, `ColonyView` yox) da eyni
idi (7.34 ms) — fərq görüntünün yox, səhnənin özünün (koloniyada görüşən botlar) daha
sıx olmasındandır. Emulyator açılandan sonrakı ilk qaçış hər iki kodda yavaşdır (bir dəfə
yeni kodda 31 FPS, təkrarda köhnə kod birinci qaçdı və o yavaş oldu: 58.6 FPS).

**Onlayn:** server + iki avtomatik client: A əvvəldən, B 15 s sonra girir, 12-ci saniyədə
qopub nişanla qayıdır. Sonda ikisi də eyni koloniya halını görür (0.05 / 0.05 / 0.33 / 1.00),
skript xətası yoxdur.

**Testlər** (`colony_test.gd`, 35 yoxlama): yerləşmə (3 düzüm × 40 toxum), toxumla təkrar,
digər rejimlər, tükənmə/bərpa, bərpada köhnə qida, ritm, 8 hədd, sürüşən qida, həqiqi udma,
gözləmədən sonra partlayış yoxdur, böyük addım, 32 minimum, səpinti minimuma sayılmır,
ümumi hədəf, qidanın yeri (576 qida), torla çəkilmə, join/snapshot, gec qoşulma və paket
itkisi (client görüntüsü), bot seçimi, tükənmiş koloniyadan ayrılma, gizli rəqib, təhlükədən
qaçma, dolu bot.

## 19. Matç içi mutasiyalar — eksperimental profil (2026-10-28)

Məqsəd: böyümə döyüş tərzini dəyişsin, hər həyatda başqa quruluş yaransın. İlk versiya
YALNIZ SONSUZ ARENA-da və yalnız eksperimental qaydalar profilindədir; standart profil
buraxılışın indiki davranışıdır. Qalan altı rejim profili heç vaxt almır (test edilib).

### 19.1 Profil və işə salma

- `Const.Profile` { STANDARD, MUTATIONS }. Prosesin profili komanda sətrindən bir dəfə
  oxunur (`World.default_rules`): server `-- --server --ws --profile mutations`, məşq
  `-- --practice --mutations`. Bayraq yoxdursa — standart.
- Dünya profili join info-da (`profile`) deyir; client kartları və proqnozu YALNIZ bununla
  açır — öz bayrağı ilə simulyasiya qaydasını dəyişmir.
- Render-də açmaq üçün başlanğıc əmrinə `--profile mutations` əlavə etmək kifayətdir
  (yerləşdirilməyib).

### 19.2 Açılma və seçim

- Serverin saydığı həyat yaşı 45 və 90 s-ə çatanda bir seçim açılır (`Const.mut_earned` —
  sayılır, hadisə deyil: iki hədd bir snapshot-da keçilsə də iki seçim qalır). Ən çox iki
  mutasiya, eyni mutasiya iki dəfə yoxdur; hər mərhələdə hələ seçilməmişlər təklif olunur.
- Ölüm (yeni `GermState`) mutasiyaları, seçimləri və yaşı sıfırlayır; yenidən qoşulan sağ
  mikrob (`resume_peer`) hamısını saxlayır.
- Seçim yeni RPC deyil: Godot RPC-ləri ADA görə sıralanmış indekslə çağırır və yeni metod
  köhnə client-in `request_join`-unu başqa metoda yönəldərdi — "oyunu yenilə" cavabı da
  gəlməzdi. Ona görə seçim girişin bayraq ədədinin 5–6-cı bitlərindədir (`m + 1`), massivin
  düzümü dəyişmir. Client onu təsdiq (mikrobun bayrağında bit) gələnə qədər hər girişdə
  təkrarlayır; 3 s-də gəlməsə kartlar yenidən açılır. Server (`World.choose_mutation`) seçimi
  dərhal yoxlayır və bir dəfə tətbiq edir; rədd səbəbləri: `profile`, `dead`, `unknown`,
  `taken`, `full`, `early`.

### 19.3 Təsirlər (paylaşılan funksiyalar, `constants.gd` «Mutasiyalar»)

| Mutasiya | Nəyə toxunur |
|---|---|
| UZUN ÇIXINTI | `shot_speed` ×0.85, `shot_life` ×1.20/0.85 → məsafə ×1.20 (hər profildə: ox, iynə, miniqan); damcı: `lob_max` 460 → 552 px, `lob_flight` 0.85 → 1.0 s — düşmə yeri, uçuş, xəbərdarlıq, botun qabaqlaması eyni hesabdan |
| İMPULS QAMÇISI | `recoil` ×1.30; buraxılan hərəkətin sönmə əmsalı ×0.80 (`mut_brake`) — əmsala vurulur, sürətə yox |
| YAPIŞQAN AYAQLAR | su axını (`current_at`) və cərəyan deşiyinin itələməsi (`_vent_push`) ×0.75; öz ən böyük sürəti ×0.95. Trixosistin itələməsi, atəşin geri təpməsi, mikrobların ayrılması DƏYİŞMİR |

- Yük (+2, iynə hərəsi +1) və qiymət (−1 top) dəyişmir. Atılmış top atəş anının qaydası ilə
  uçur (`ShotState.long`) — mutasiya sonradan seçilsə də.
- Proqnoz mutasiyanı öz mikrobunun bayrağından alır; təsirlər hər tick vəziyyətdən oxunur,
  yenidən oynatma onları bir dəfə tətbiq edir. Test: server və proqnoz eyni girişlərlə (QAMÇI +
  AYAQLAR, atəş, sürüşmə) 90 tick-də 0.0000 px fərqlə gedir.

### 19.4 Şəbəkə və uyğunluq (qaydalar versiyası 3 → 4)

- Mikrob bayrağı: bit 11–13 aktiv mutasiyalar (`GFlag.MUT_*`). Sahə float32-dir — 24 bitə
  qədər tam ədəd dəqiqdir, bit 0–10 dolu idi (yoxlanılıb, fərz edilməyib).
- Top META-sı: bit 22 — atıcı UZUN ÇIXINTI-lı idi; client uzaqdakı topun sürətini və damcının
  uçuşunu bundan hesablayır. Bit 0–21 (profil, yük, qrup) toxunulmazdır (test).
- Snapshot-un sonunda `Snap.EVO` — baxanın açılmış seçim sayı (standart profildə -1). Şəxsidir:
  rəqib başqasının gözləyən seçimini görmür, aktiv mutasiyalar isə anatomiyada hamıya görünür.
- Ən pis snapshot (10 mikrobun hamısı iki mutasiyalı, uçan toplar, qida): 1260 bayt < 1392.

### 19.5 Görüntü

- Kartlar (`MutationCards`) sol yuxarıda, top sayının altında yığcam sütun: hər kart adı,
  "+" üstünlüyü və "−" qiyməti bir yerdə yazır; 1/2/3, bağlamaq və "MUTASİYA · N" göstəricisindən
  açmaq olar, avtomatik seçim yoxdur, oyun dayanmır. Seçilən kart "SERVER GÖZLƏNİLİR…" yazır.
  Əvvəl yuxarı ortada idi və "GİZLƏNDİN" kimi mərkəzi mesajların üstünə düşürdü (ekran
  görüntüsündə görüldü) — köçürüldü.
- Anatomiya (`MutationAnatomy`) — GermVisual-ın ilk uşağı, node-un arxasında: GDScript
  gövdəsi də, GPU gövdə qatı da kökləri örtür, yəni iki yol eyni şeyi göstərir (ikisinin də
  ekran görüntüsü çəkilib). Çıxıntı nişan tərəfə, qamçı arxada yellənir (transformasiya),
  yastıqlar membranın altından çıxır. Halqa yoxdur, membran böyümür. Yalnız mutasiya və ya
  ölçü dəyişəndə yenidən çəkilir.

### 19.6 Botlar

Botlar eyni hədlərdə və eyni yoxlamadan (`choose_mutation`) keçən seçim edir:
kirpikli — çıxıntı, qamçı; ayaqlı — ayaqlar, qamçı; amöb — çıxıntı, ayaqlar. Durduğu
məsafə, atəşin çatması, qabaqlama və damcının məsafəsi öz mutasiyası ilə hesablanır.
Gizli üstünlük yoxdur.

### 19.7 Sınaq (2026-10-28)

- `mutation_test.gd` — 27 yoxlama: rəqəmlər, iqtisadiyyat, 45/90 s, iki hədd birdən, rədd
  səbəbləri, təkrar paket, birləşmə, ölüm, clone/giriş/bayraq/META gedib-gəlməsi, yenidən
  qoşulma, proqnoz = server, havadakı top, standart profil və altı rejim, botlar, kartlar,
  ən pis paket. `--simtest` 999/0.
- **Yerli botlu oyun** (məşq, profil açıq, 110 s, avtomatik oyunçu kartları UI ilə seçir):
  45 s-də 1, 90 s-də 2 mutasiya, proqnoz serverlə eyni bitləri görür, hədd aşan mikrob 0.
  Bu matçda heç bir bot 45 s yaşamadı.
- **Server + iki client** (`--profile mutations`): A birbaşa — iki seçim təsdiqləndi, sonda
  iki mutasiya və 2 açılmış seçim; proksili client-lər (70±30 ms) 45 s-ə çatmadan partladı.
  Hər iki client serverdə mutasiyalı botları gördü (UZUN ÇIXINTI).
- **Gecikmə ilə seçim** (scratch nüsxədə hədlər 8/16 s-ə endirilib, kod dəyişməyib):
  proksili client iki seçimi ~0.5 s-də təsdiq aldı, uzun çıxıntılı 46 topun proqnozu
  serverlə 0.0 px.
- **Yoxlanmayıb:** APK və brauzer (anatomiya 45 s-dən sonra çıxır, avtomatik ssenari yoxdur);
  insanlarla balans. Botlu matçda mutasiyaya çatmaq çətindir (çoxu 45 s yaşamır) — hədlər
  prototipdir.

## 20. Vaxtlı, istiqamətli membran müdafiəsi — eksperimental profil (2026-10-28)

Məqsəd: oyunçu vaxtlama ilə bir atəşi qaytara bilsin, hücum edən isə müdafiəni aldadıb
(bərpa hissəsinə) sonrakı zərbəni planlasın. Superlərin heç birini əvəz etmir: kirpiklinin
trixosisti və amöbün miniqanı olduğu kimidir; köhnə qabıq məntiqi qayıtmayıb.

### 20.1 Profil

- Profillər BİT maskasıdır: `Const.Profile` { STANDARD 0, MUTATIONS 1, MEMBRANE 2 },
  `Const.rule_on`. Yalnız SONSUZ ARENA dünyası alır; altı rejim olduğu kimi qalır (test).
- **2026-10-28 (sahibin qərarı): membran SONSUZ ARENA-nın STANDART qaydasıdır** — rəy toplamaq
  üçün. Bayraqsız proses membranlıdır (`World.rules_from_args`), söndürmək `--no-membrane`;
  mutasiyalar eksperimental qalır (`--mutations` / `--profile mutations`). Matç başında izah
  ilk üç matçda göstərilir (`Settings.tip_due("membrane")`).
- Botlu ölçü (12 toxum × 180 s, membranlı → membransız): partlatma 6.14 → 7.53/dəq (membran
  döyüşü ~18% azaldır), aclıqdan ölüm 0.11 → 0.19, ac bot-tick-ləri 25.6% → 19.1% (hər istifadə
  1 top aparır), xəritədə qida 177 → 202. Serverin tick-i dəyişmir (0.61 → 0.61–0.62 ms).
- `Sim.membrane_on` — serverdə profildən, proqnozda join info-dakı profildən. Client öz
  bayrağı ilə qaydanı açmır.

### 20.2 Qayda (`constants.gd` «Membran müdafiəsi»)

| Sabit | Dəyər |
|---|---|
| `MEMBRANE_ACTIVE` | 0.18 s |
| `MEMBRANE_RECOVER` | 0.35 s |
| `MEMBRANE_COOLDOWN` | 7 s (aktivləşmədən) |
| `MEMBRANE_COST` | 1 top |
| `MEMBRANE_HALF` | 60° (sektor cəmi 120°) |
| döşəmə | `membrane_floor()` = `FIRE_MIN_BALLS` |

- İstiqamət aktivləşmə anındakı nişandır, 64 addıma yuvarlaqlaşdırılıb (5.6°) və bu istifadə
  üçün kilidlidir — server, tarixçə, bayraq və görüntü eyni bucağı görür.
- `GermState.membrane_ready()`: canlı, super işləmir, doğuş qalxanı yoxdur, soyuma bitib,
  top ≥ döşəmə. Rədd edilən istək heç nə xərcləmir.
- Ardıcıllıq `Sim._step_germs`-dədir (server və proqnoz eyni kod): əvvəl qanuni membran,
  qəbul olunsa həmin tick-in super və atəşi atılır; aktiv + bərpa boyu ikisi də bloklu.
- İstək girişin 7-ci bitidir (128), BİR tick gedir; birləşən girişlərdə OR ilə köçür, tick-dən
  sonra sıfırlanır — basılı düymə və saxlanan giriş ikinci cəhd yaratmır.

### 20.3 Qayıtma (`Sim._step_shots`, `_can_parry`, `_resolve_parries`, `_reflect`)

- Mikroba dəyən mərmi üçün qurbanın atıcının GÖRDÜYÜ andakı halı oxunur (`_rewound_bits`:
  tarixçədə `HIST_MEM` biti və istiqamət). Aktivdirsə, toqquşma nöqtəsinin normalı sektordadırsa,
  mərmi damcı deyilsə və əvvəl qaytarılmayıbsa — qərar tick-in sonuna saxlanılır.
- Tick sonunda hər müdafiəçiyə TƏMAS ANI (seqmentdəki pay) ən erkən olan (bərabərdə kiçik id)
  qayıdır, qalanları adi dəyir: iki iynədən biri qayıdır (+1 qalır), o biri +1 verir.
- Əks: `v − 2(v·n)n`, top membranın çölünə qoyulur; sahib/komanda/rəng müdafiəçiyə keçir,
  `rewind` 0, `parried` = true. Qalan ömür, sıçrayış sayı, yük, profil və qrup (`volley` —
  qida/obyekt büdcəsi köhnə hərəkətinkidir, ikiqat qida və mükafat yoxdur) dəyişmir. Yeni sahib
  öz topuna dəymir (sahib həmişə keçilir), ilk atıcıya isə dəyir; partlatma müdafiəçinindir.
- PARRY hadisəsi (`EvKind.PARRY`) yalnız görüntüdür: super doldurmur, HIT deyil.
- Neytral obyektlər (Nüvə, Ana) qaytarmır; yoldaşın topu onsuz da dəymir; ölmüş atıcının
  topu adi düşmən topudur — qayıdanda müdafiəçinin olur.

### 20.4 Şəbəkə (qaydalar versiyası 5)

- Bayraq: bit 14–15 faza (`MemPhase`), 16–21 istiqamət (64 addım). Ən yüksək bit 21-dir —
  float32-nin dəqiq 24 bitinə sığır (yoxlanılıb).
- Snapshot-un sonunda `Snap.MEM` — baxanın öz soyuması (standartda -1). Faza və istiqamət
  hamıya bayraqdadır: rəqib aktiv və bərpa hissəsini görür.
- Proqnoz: öz mikrobunun membranı eyni koddan; düzəlişdə faza bayraqdan, soyuma `Snap.MEM`-dən
  gəlir — server rədd edibsə faza NONE gəlir və yerli animasiya söner. Öz topun aktiv membrana
  dəyəndə zərbə serveri gözləyir (`_soft_reason` → "membran"); botun topu sənin aktiv
  membranına gələndə "əmin dəymə" proqnozlaşdırılmır. Topun rəngi dəyişəndə (qayıdıb) öz
  proqnoz topu dayanır və server sətri yeni rəngdə çəkilir.
- Ən pis snapshot (hamısı membranlı və mutasiyalı, uçan toplar): MTU-dan aşağı (test).

### 20.5 Görüntü və idarə

- `MembraneArc` — yalnız kilidli istiqamətin ±60°-si: aktivdə qalın ağ-mavi qövs, bərpada
  nazik narıncı qırıq qövs. Gövdənin önündə, GermVisual-ın uşağı — GPU və GDScript yolunda
  eyni (ekran görüntüsü ilə yoxlanıb). Tam dairəvi qalxan yoxdur.
- `MembraneButton` — superin üstündə (atəşi və superi örtmür, minimap və hərəkət zonasından
  uzaq); hazır / aktiv / bərpa / soyuma; mümkün olmayanda səbəb yazılır. Klaviaturada E.
  Matçın əvvəlində qısa izah: "öndən gələn ilk topu qaytarır · damcı yuxarıdan keçir".
- Damcının düşmə halqasında kiçik aşağı ox — membran onu saxlamır (ilk prototipin açıq
  istisnası; enmə fazasına xüsusi müdafiə bu işə daxil deyil).

### 20.6 Botlar

Yalnız üzünə uçan, 0.2 s-dən az qalmış, görünən düz mərmiyə (`Bot._incoming_shot`; damcı yox,
gizli rəqibin yeri istifadə olunmur), tick başına `0.12 × bacarıq` ehtimalla: nişan mərmiyə
dönür, həmin tick atəş və super yoxdur. Testdə 20 təhlükənin 8-də açdı, hamısında topa dönmüşdü.

### 20.7 Sınaq (2026-10-28)

- `membrane_test.gd` — 31 yoxlama: rəqəmlər, aktivləşmə və qiymət, kilidli istiqamət, beş
  qanunsuz istək (pulsuz), döşəmə, eyni tick ardıcıllığı və blok, basılı düymə (3 s — bir
  aktivləşmə), birləşən giriş, pəncərənin içi/bərpa/yox, sektor sərhədi (56° qaytarır, 62° yox,
  arxa yox), əksin həndəsəsi, birinci qayıdır-ikinci dəyir, iki iynə (+1, təmas anı), sahib və
  partlatma, super/HIT yoxdur, ömür/sıçrayış, ikinci membran qaytarmır, damcı keçir, tarixi hal
  (geri sarma), clone/giriş/bayraq/snapshot, standart profil və altı rejim, amöbün superi,
  bot, proqnoz = server, UI node-ları, ən pis paket.
- **Onlayn** (`--profile membrane,mutations`, server + client-lər, biri 70±30 ms proksi ilə):
  birbaşa client 6 basış → serverdə 6 aktivləşmə, botlar onun 2 topunu qaytardı (client
  sahib dəyişməsini düzgün çəkdi), 45 s-də mutasiya da seçildi; proksili client 8-ci saniyədə
  qopub nişanla qayıtdı — 2 basış → 2 aktivləşmə; skript xətası yoxdur.
- **Yoxlanmayıb:** itən UDP paketi (WebSocket TCP-dir — itki proksidə yoxdur; birləşmə və
  təkrar unit testlərdədir), APK, insanlarla balans. **Balans riski:** 0.18 s pəncərə
  insan üçün dar ola bilər; botların 12%/tick reaksiyası təxminidir.
