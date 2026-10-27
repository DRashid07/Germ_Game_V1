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
| Dirilmə | **Yoxdur** (raund boyu) |
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
| Öləndən sonra izləmə (spectate)? | **Yox** — dərhal menyuya. İzləmə yeni ekran, yeni şəbəkə axını deməkdir |
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
- Topla vurmaq onu itələyir (`200 × 20 / çəki` px/s) və **+2 çəki** verir; 40-ı keçəndə
  Nüvə partlayır, 2 s sonra mərkəzdə yenisi. Çəki 1.5 s-də 1 azalır (20-yə qədər).
- TRİXOSİST itələməsi Nüvəyə də təsir edir. Suyun burulğanı onu **35%** aparır (tam axında
  Nüvə şüşəyə yapışıb qalırdı). Şüşənin **menisküsü**: kənardan 40 px-ə yaxın Nüvə içəri
  yuvarlanır — şüşəyə sıxılmış Nüvənin arxasına mikrob sığmırdı.
- **Qapı (məsamə)** şüşədədir: qərbdəki komanda 0-ın, şərqdəki komanda 1-in. Eni 236 px,
  iki yanında selik dirəyi (585, ±150). Nüvə rəqibin qapısına girəndə **qol**: hamı yerinə
  qayıdır, 3 s sayım (matçın saatı dayanır).
- İlk **2** qol udur; 2:30-da çox qolu olan; bərabərdirsə **45 s** ərzində ilk qol, sonra heç-heçə.
- Botlu ölçü (20 matç): 14-ü qaliblə, matç başına 1.1 qol.

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
