# Germ Arena

Onlayn **io tipli** mikrob arenası. Mobil (Android) üçün, **yatay** ekranda.
10 nəfərlik sonsuz petri qabı: girirsən, yeyirsən, böyüyürsən — partlayanda çıxırsan.

- **Format:** matç yoxdur, növbə yoxdur. Düyməni basan kimi dünyadasan.
- **Hərəkət:** telefonda sol barmaq üzən joystick, sağ aşağıda top atma düyməsi
- **Super:** hər növün öz gücü — atəş düyməsinin üstündəki halqa dolanda basılır
- **PC-də:** `WASD` / ox düymələri hərəkət, `BOŞLUQ` top atır
- **Nişan:** yoxdur — top getdiyin tərəfə gedir, dayanmısansa son baxdığın tərəfə
- **Ekran:** yatay, 1280×720 baza — telefon kilidlənir, brauzerdə portret
  pəncərədə "telefonu yan çevir" örtüyü çıxır
- **Motor:** Godot 4.7.2 · **Dil:** GDScript · **Şəbəkə:** server-authoritative

## Oyunun qaydası

Mikrobun içindəki top sayı həm **sursat**, həm **candır**:

```
        ┌──────────────────────────────────────────────┐
        │  SƏN 7/10        top at →○          RƏQİB 8/10│
        │  ↓ 6/10                             ↓ 10/10  │
        │                  top at →○                   │
        │  ↓ 5/10                             ↓ 💥 12/10│
        │                                              │
        │  Sənin tutumun:  10 → 15  (+5)               │
        └──────────────────────────────────────────────┘
```

| Hadisə | Nəticə |
|---|---|
| **Top atırsan** | səndə −1, dəydiyi rəqibdə **+2** (top içəridə bölünür) |
| **Top haradan çıxır** | mikrobun **öz içindən** — membranı yararaq |
| **Rəqibin sayı tutumu aşır** | rəqib **partlayır**, sən **+5 tutum** alırsan |
| **Sənin sayın 2-dən aşağı düşür** | **acından partlayırsan** — heç kim hesab almır |
| **Qida yeyirsən** | +1 (tutumun doludursa yemirsən) |
| **Metabolizm** | hər ~6 saniyəyə bir top yanır — yemək məcburidir |

Üç nəticə:

1. **Hücum risklidir** — hər atəş səni ölüm həddinə yaxınlaşdırır.
2. **Zəifi vurmaq mənasızdır** — verdiyin toplar onun sursatına çevrilir.
   Doğru hədəf **dolu** rəqibdir.
3. **Dolan oyunçu top ataraq boşala bilər** — saniyədə bir top. Sənin atdığın
   içəridə ikiyə bölündüyü üçün hücum edən saniyədə xalis +1 qazanır:
   partlatmaq mümkündür, amma vaxt və dəqiqlik istəyir.

Böyüməyin qiyməti var: tutum artdıqca mikrob **böyüyür** (iri hədəf),
**yavaşlayır** və **daha tez acır**. Lider sonsuz böyüyə bilmir.

### Qab su ilə doludur

Mikrob quru döşəmədə sürüşmür — **maye içində üzür**, və bu, görüntü deyil,
simulyasiyanın bir hissəsidir:

| | Nə edir |
|---|---|
| **İtələmə / müqavimət** | Barmağını qaldıranda mikrob dərhal dayanmır, ~1 saniyə sürüşür. Geri təpmə də ona görə əsl manevr vasitəsidir. |
| **Axın** | Qabda yavaş burulğanlar var. Hər şey — mikroblar da, yerdəki qida da — onlarla birlikdə sürüşür. |
| **Yapışma qatı** | Şüşəyə yaxın maye dayanır, ona görə axın heç nəyi divara sıxmır. |

Axın sahəsi YALNIZ mövqedən asılıdır (vaxtdan yox) və **divergensiyasızdır**:
bu iki xassə təsadüfi deyil — birincisi olmasa client-in proqnozu serverlə
uyuşmazdı, ikincisi olmasa qida burulğanların mərkəzinə yığılıb ilişərdi.
Kod: [`Const.current_at`](game/scripts/shared/constants.gd).

Üçüncü xassə isə tamamilə **qavrayışla** bağlıdır: burulğanın dalğa uzunluğu
(430 px) ekranın enindən (620 px) KİÇİK olmalıdır. Böyük olsa ekrandakı bütün
zərrəciklər eyni tərəfə baxır və oyunçu fırlanmanı görmür — riyaziyyat düzgün
işləsə də effekt yox olur. İlk versiyada məhz belə idi (760 px, orta sürət
BASE_SPEED-in 6.7%-i); indi orta sürət 11%-dir və testlə qorunur.

### Xəritə interaktivdir

Maneə `Vector4(x, y, radius, kind)`-dır. Toqquşma həndəsəsi hər növdə eynidir
— dairə — amma QAYDA fərqlidir:

| Növ | Mikrob | Top | Xüsusi |
|---|---|---|---|
| **SELİK** | bloklayır | sıçrayır | — |
| **KOL** | keçir | keçir | içindəki mikrob **GİZLİDİR** |
| **KÖVRƏK** | bloklayır | **sındırır** | 3 zərbədən sonra dağılır, yol açılır |
| **CƏRƏYAN** | keçir | keçir | **mərkəzə doğru itələyir** |

Növ [`DishMap`](game/scripts/shared/dish_map.gd)-dədir, yəni PAYLAŞILAN
koddadır: client proqnozu ilə server eyni qaydanı icra etməlidir, əks halda
mikrob client-də keçdiyi yerdən serverdə keçə bilməz və düzəliş onu geri
sıçradar.

**Gizlənmə YALNIZ serverdə mövcuddur.** Kolun içindəki mikrobun mövqeyi
rəqiblərə **göndərilmir** ([`World._near_germs`](game/scripts/server/world.gd)).
Client-də gizlətmək gizlənmə olmazdı: paket onsuz da şəbəkədə gedir və onu
oxuyan hər kəs mikrobu görər. Eyni kolun içindəki iki oyunçu isə bir-birini
görür — yoxsa kolda toqquşub bir-birini heç vaxt tapa bilməzdilər.

> **Böyük mikrob kiçik kolda gizlənə bilmir.** Bu, oyunun öz qaydasının
> davamıdır: böyümənin qiyməti var — iri hədəf, yavaş hərəkət, tez acma, və
> indi bir də gizlənə bilməmək. Lider kolda oturub oyunu dondura bilmir.

**Dağılan qabıq bərpa olunmur** — dünya oyun getdikcə AÇILIR. Vəziyyət hər
snapshot ilə tam gedir (maneə başına bir bayt, `Const.Snap.WALLS`), fərq kimi
yox: fərq göndərilsəydi bir itən paket client-i əbədi səhv vəziyyətdə qoyardı.

Düzümü yuxarıdan görmək üçün — stend maneələri OYUNDAKI sprite-larla çəkir,
yəni bir kadrda beş sprite-ın da həqiqi görkəmi yoxlanılır:
```bash
GODOT --path game --resolution 760x760 -- --map --map-layout 0 \
      --shot C:/yol/kadr.png --shot-delay 60
```

### Zərbə hissi

Hadisə baş verəndə oyun bunu **dörd ayrı kanaldan** deyir. Səbəb odur ki,
ekranda 10 mikrob var və tək kanal (məsələn, yalnız səs) itir:

| Kanal | Nə vaxt | Kod |
|---|---|---|
| **Ağ parıltı** | top rəqibin içinə keçəndə | [`GermVisual.flash`](game/scripts/client/germ_visual.gd) |
| **Donmuş kadr** (75 ms) | yaxında biri partlayanda | [`Arena._apply_freeze`](game/scripts/client/arena.gd) |
| **Kamera zərbəsi** | partlama və tutum artımı | `Arena._punch` |
| **Uçan rəqəm** | `+2` zərbədə, `+5 TUTUM` mükafatda | [`Arena._pop_text`](game/scripts/client/arena.gd) |

Uçan toplar da iz buraxır — [`ShotTrails`](game/scripts/client/shot_trails.gd).

> **Donma `Engine.time_scale` ilə edilmir və bu, məcburidir.** `time_scale`
> `_process` deltasını da kiçildir, yəni proqnoz tick-ləri yavaşıyır və serverə
> daha az giriş gedir. Server isə 30 Hz-lə işləməyə davam edir: client geri
> qalır, donma bitəndə düzəliş mikrobu sıçradır. Zərbə hissi üçün qoyulan
> effekt öz zərbəsini yeyərdi. Ona görə donma YALNIZ görüntüdədir — kamera və
> mikrob animasiyaları dayanır, simulyasiya isə tam sürətlə davam edir.

### Bioluminessensiya (glow)

Parlaq piksellər ətrafa işıq saçır — [`Arena._build_glow`](game/scripts/client/arena.gd).
`gl_compatibility` renderer-ində DƏ işləyir, amma **iki şərtlə**:

1. `rendering/viewport/hdr_2d` açıq olmalıdır (`project.godot`), yoxsa rənglər
   1.0-da kəsilir və hədd heç vaxt keçilmir;
2. `glow_hdr_threshold` 1.0-dan **aşağı** olmalıdır (indi `0.62`), çünki
   `Palette`-dəki bütün rənglər ≤ 1.0-dır — heç nə öz-özünə HDR diapazonuna
   çıxmır.

Hədd fonu (`0.05`) toxunulmaz saxlayır: yalnız **canlı** olan şeylər işıq verir.

## Rejimlər

İki rejim var və oyunçu menyuda OYNA düyməsinin üstündəki kartdan seçir.
Qaydalar (top, partlama, növ gücləri) hər ikisində EYNİDİR — fərq yalnız
matçın olub-olmamasındadır.

| | **SONSUZ ARENA** (ilkin) | **TƏK QALAN** |
|---|---|---|
| Giriş | dərhal — gözləmə yoxdur | 3 saniyə geriyə sayım |
| Mikrob sayı | ən azı 6, botlarla saxlanılır | 10, matç boyu bərpa olunmur |
| Ölüm | nəticə ekranı, sonra menyu — dərhal yenidən girirsən | matç bitir, yer alırsan |
| Qab | sabit | 45 s sonra quruyub daralır |
| Bitiş | yoxdur | sonuncu mikrob qalanda |

**Quru zona top ARTIRIR, azaltmır.** Bu, rejimin əsas qərarıdır: oyunun imza
ölümü partlamaqdır, aclıqla sönmək deyil. Ona görə kənar həm təhlükə, həm də
yemdir — dolu oyunçunu öldürür, ac oyunçunu isə xilas edə bilər. Oyunçu hər
dəfə real seçim edir: "kənara girib doldurummu, yoxsa mərkəzdə qalım?"

Qabın radiusu YALNIZ matç saatından asılıdır (`Const.dish_radius`) — client
eyni düsturu işlədir, ona görə daralma proqnozla ziddiyyət yaratmır.

**Spor** — matçda doğulan iri qida yığını. Yeyənə **tutum** verir, yəni
partlatmaqla eyni mükafata ikinci yol açır: döyüşməyən oyunçu da irəliləyir.

**Quru zonada qida yoxdur.** Qab daralanda kənarda qalan qida quruyur və
doğuş hədəfi də qabın ölçüsü ilə kiçilir. Bu, qaydanı bir cümləyə yığır:
*quru zonada TOP var, QİDA yoxdur.* Onsuz matçın sonu ilişirdi — aşağıya bax.

**Matç bitəndə qab dayanmır.** Əsas quruma 250 px-də bitir, sonra matçın
sonuna qədər 90 px-ə qədər yavaş sıxılma davam edir. Dayansaydı, son dəqiqədə
heç nə dəyişməzdi.

Tam quruluş: [design/MODES.md](design/MODES.md). Orada həm tətbiq olunmuş
hissə, həm də növbəti mərhələ (CÜT 2v2, ÜÇLÜK 3v3) yazılıb.

## Ekranlar

[Baş menyu](docs/screenshot_menu.png) · [Oyun ekranı](docs/screenshot_world.png)

---

## Windows-da sınamaq — ən sürətli yol

```
build/GermArena.exe
```

Tək fayldır (PCK içindədir), quraşdırma tələb etmir. Açıb **MƏŞQ (offline)**
düyməsini bas — botlarla dolu dünya dərhal açılır, serverə ehtiyac yoxdur.

| | |
|---|---|
| `WASD` və ya ox düymələri | hərəkət |
| `BOŞLUQ` (və ya `ENTER`) | top atmaq |
| `SHIFT` (və ya `Q`) | **super** — dolubsa |
| Siçan | ekran joysticki və düymələr |

> **Niyə klaviatura?** Oyun toxunuş üçün qurulub, siçan isə Godot-da BİR toxunuş
> kimi emulyasiya olunur — yəni siçanla eyni anda həm hərəkət etmək, həm atmaq
> mümkün deyil. PC-də əsl oyun hissi yalnız klaviatura ilə alınır.
> Əsl sınaq yenə telefondadır (`build/GermArena.apk`).

`build/GermArena.console.exe` eyni oyundur, amma terminal pəncərəsi ilə açılır —
xəta və server loglarını görmək üçün.

Yenidən qurmaq:
```bash
GODOT --headless --path game --export-release "Windows" build/GermArena.exe
```

---

## Canlı server — HƏLƏ QURULMAYIB

Menyuda əvvəlcədən doldurulan ünvan **yer tutucudur**:

```
wss://germ-arena-production.up.railway.app
```

Bu ünvan hələ mövcud deyil — Railway layihəsi yaradılmayıb. Hazırda oynamağın
iki yolu var:

1. **MƏŞQ (offline)** — menyudakı ikinci düymə. Şəbəkəyə heç toxunmur,
   eyni dünya kodu botlarla yerli işləyir.
2. **Öz kompüterində server** — aşağıdakı "Serveri lokal qaldırmaq" bölməsi.

Serveri Railway-ə qaldırdıqdan sonra ünvanı iki yerdə yeniləmək lazımdır:
[`constants.gd → DEFAULT_SERVER`](game/scripts/shared/constants.gd) və
[`tools/check_server.sh`](tools/check_server.sh).

> ⚠️ **Server ünvanını brauzerdə açma — `502` görəcəksən və bu NORMALDIR.**
> Server veb sayt deyil, oyun serveridir: yalnız WebSocket dilində danışır.
> Sağlamlığı belə yoxlanılır:
> ```bash
> bash tools/check_server.sh ws://127.0.0.1:27015
> ```

Texniki qərarlar və yol xəritəsi: [PLAN.md](PLAN.md) ·
Vizual üslub: [design/ART_BIBLE.md](design/ART_BIBLE.md) ·
Səs üslubu: [design/AUDIO_BIBLE.md](design/AUDIO_BIBLE.md) ·
Dizayner brifi: [design/BRIEF.md](design/BRIEF.md)

---

## Qovluq strukturu

```
game/                    Godot layihəsi
  scripts/
    shared/              Client VƏ server tərəfindən paylaşılan kod
      sim.gd             ★ Oyunun bütün məntiqi (hərəkət, top, udma, partlama)
      constants.gd       Sabitlər və snapshot sahə indeksləri (autoload: Const)
      net.gd             Bütün RPC-lər, ENet/WebSocket seçimi (autoload: Net)
      dish_map.gd        Petri qabındakı maneələrin düzümü
      bot.gd             Bot mikrob — serverdə işləyir, dünyanı canlı saxlayır
      palette.gd         Kod tərəfdən çəkilən rənglər
    server/
      lobby.gd           Dünyalar, giriş/çıxış, yenidən qoşulma
      world.gd           Bir petri qabı: Sim + oyunçular + botlar + snapshot
    client/
      arena.gd           ★ Oyun ekranı: prediction, interpolyasiya, kamera, reconnect
      menu_v2.gd         ★ Baş menyu: canlı mikrob, növ kartları, qoşulma
      main_menu.gd       KÖHNƏ şaquli menyu — ehtiyat (`--menu1`), sonra silinir
      hud.gd             Doluluq göstəricisi, liderlər, xəbərdarlıqlar, nəticə
      germ_visual.gd     Bir mikrobun görüntüsü — ÜÇ NÖV (üzür, yeriyir, sürünür)
      burst_fx.gd        Partlayaraq ölmə effekti (dalğa, damcı, membran parçaları)
      shot_trails.gd     Uçan topların izi — hamısı BİR çəkiliş çağırışında
      water_motes.gd     Suda asılı zərrəciklər — axını gözlə görünən edir
      minimap.gd         Petri qabının kiçik xəritəsi
      touch_stick.gd     Üzən virtual joystick (hərəkət)
      fire_button.gd     Top atma düyməsi (basılı saxlananda davamlı atəş)
      super_button.gd    Super düyməsi — dolan halqa, atəşin üstündə
      super_button.gd    Super düyməsi — dolan halqa, atəşin üstündə
      sfx.gd             Səs effektləri (autoload: Sfx)
    tools/
      sim_test.gd        226 headless test
      auto_client.gd     Şəbəkə testi üçün insansız client
      screenshot.gd      Redaktorsuz ekran görüntüsü
      species_preview.gd Növün görüntü stendi — tək mikrob, böyüdülmüş
      map_preview.gd     Xəritə düzümünün stendi — bütün qab yuxarıdan
      perf_probe.gd      Kadr vaxtı və çəkiliş çağırışı ölçmə
  assets/                SVG sprite-lar, UI, şriftlər, WAV səslər
    fonts/               Baloo 2 (başlıq) + Nunito (mətn) — bax «Şriftlər»
    ui/theme.tres        Şrift rolları; bütün Control-lar bunu oxuyur
    sprites/             maneə sprite-ları: blob, bloom (SELİK) · crust ×3 (KÖVRƏK,
                         zədə mərhələləri) · bush + bush_top (KOL) · vent (CƏRƏYAN)
                         · dish_floor (qabın döşəməsi)
  web/shell.html         Brauzer versiyasının HTML qabığı
design/                  Dizayn mənbəyi (art/audio bible, brif, sprite, səs generatoru)
tools/                   Build və deploy skriptləri
build/                   Hazır APK və Linux server binarı
web/                     Brauzer versiyasının hostinqi (nginx konteyneri)
Dockerfile               Hədəf serverin konteyner tərifi
railway.json             Railway deploy konfiqurasiyası
```

★ ilə işarələnən iki fayl layihənin özəyidir.

---

## Necə işə salmaq

Godot bu maşında quraşdırılıb:
`C:\Users\User\Godot\Godot_v4.7.2-stable_win64.exe` (aşağıda `GODOT`).

```bash
GODOT --path game --editor        # redaktorda aç
GODOT --path game                 # oyunu işə sal (menyudan)
```

### Məşq rejimi — şəbəkəsiz, botlarla
```bash
GODOT --path game -- --practice

# Mikrob növünü seçərək (0 kirpikli · 1 ayaqlı · 2 amöb):
GODOT --path game -- --practice --species 2

# Rejimi seçərək (0 sonsuz arena · 1 TƏK QALAN):
GODOT --path game -- --practice --mode 1
```
Eyni `World` və `Sim` kodu yerli işləyir; fərq yalnız snapshot-ların şəbəkədən
yox, yaddaşdan gəlməsidir. Server yatmış olsa da oyun oynanır.

`--species` və `--mode` menyunu keçdiyimiz üçün lazımdır: birbaşa dünyaya
düşəndə `settings.cfg` oxunmur. `--shot` ilə birlikdə hər növün və hər
rejimin görüntüsünü redaktoru açmadan, təkrarlana bilən şəkildə yoxlamağa
imkan verir.

> Quruma `--mode 1`-də 45 saniyə sonra başlayır — ekran görüntüsü üçün çox
> gözlətmə. Yoxlayarkən `Const.DRY_DELAY`-i müvəqqəti azalt, çək, sonra geri
> qaytar. Bayraq ƏLAVƏ ETMƏ: sınaq üçün qoyulan bayraq buraxılışda qalır.

### Serveri lokal qaldırmaq
```bash
GODOT --headless --path game -- --server --port 27015            # ENet (UDP)
GODOT --headless --path game -- --server --ws --verbose          # WebSocket + diaqnostika
```
Sonra menyuda server sahəsinə `ws://127.0.0.1:27015` yaz.
Server və oyun EYNİ build-dir — simulyasiya kodu ikisində eynidir.

### Testlər
```bash
# Simulyasiya + World testləri (226 test)
GODOT --headless --path game -- --simtest

# Şəbəkə inteqrasiya testi: 1 server + 2 insansız client
#   --mode <0|1> və --species <0|1|2> ilə rejim/növ seçilir; onsuz
#   TƏK QALAN-ın onlayn yolu heç vaxt sınanmır.
GODOT --headless --path game -- --server --ws --verbose &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label A --quit-after 30 &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --quit-after 30 &

# Yenidən qoşulma testi: B 10 saniyə sonra qəsdən düşür və nişanla qayıdır
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --drop-after 10 --quit-after 30 &
```

Testlər oyunun HƏR İKİ ölüm qaydasını ayrıca yoxlayır: tutumu aşıb partlamaq
və acından partlamaq. Bunlar oyunun bütün balansının dayandığı iki qaydadır.

Ayaqlı mikrobun **yerişi** də buradadır — ekran görüntüsü ilə yoxlana bilməyən
üç xassə: dayanan mikrob ayaqlarını tərpətməməli, ayaqlar sonsuz dartılmamalı,
və hər an ayaqların çoxu yerdə qalmalıdır. Sonuncu məhz bu testlə tapıldı:
mikrob yerindən tərpənəndə bütün ayaqlar bir anda qalxırdı, yəni yerimirdi,
sıçrayırdı — bir kadrlıq hadisə olduğuna görə gözlə görünmürdü.

Maye modeli də buradadır: mikrobun buraxandan sonra sürüşdüyü, axının hər
nöqtədə eyni qaldığı, şüşənin dibində dayandığı və **divergensiyasız** olduğu
ayrıca yoxlanılır. Sonuncu ədədi testdir (mərkəzi fərqlə `∂vx/∂x + ∂vy/∂y`) —
pozulsa qida burulğanlarda ilişər və dünyanın bir hissəsi acından qırılar.

### Performans ölçmək
```bash
GODOT --path game --resolution 1280x720 --disable-vsync -- --practice --mode 0 --perf 12
```

> ⚠️ **`--disable-vsync` MƏCBURİDİR.** Alət divar saatının kadr aralığını ölçür;
> vsync açıq olanda o aralıq oyunun yükündən yox, EKRANIN tezliyindən çıxır.
> 240 Hz monitorda nəticə həmişə 4.17 ms olur — yük nə olursa olsun. Bir dəfə
> bu rəqəmə inanılıb buraya "büdcənin 25%-i" yazılmışdı; həqiqi yük 10–12%
> imiş. Alət indi vsync açıq olanda xəbərdarlıq edir, amma bayrağı vermək
> yenə sənin işindir.

Orta, **1% ən pis** kadr, çəkiliş çağırışı və yaddaş yazılır.
Masaüstü nəticəsi (RTX 5050), `--disable-vsync` ilə:

| Rejim | Orta kadr | 60 FPS büdcəsi | Çəkiliş çağırışı (pik) |
|---|---|---|---|
| SONSUZ ARENA (6 mikrob) | 1.85 ms | **11%** | ~230 |
| TƏK QALAN (10 mikrob) | 2.82 ms | **17%** | ~212 |

Fərq tam olaraq dörd əlavə mikrobdandır — quruma kənarı cəmi **2** çağırışdır
(iki `draw_arc`). Mikrob ən bahalı elementdir, ona görə mikrob sayını artıran
hər rejim bu cədvəldə ölçülməlidir.

> Çəkiliş çağırışının 280-dən ~170-ə düşməsi bir dəyişiklikdən gəlir: səhnə
> qatları növlərə bölündü (bütün qida bir qatda, bütün toplar başqasında) və
> maneələr sprite-a keçirildi. Godot yalnız ARDICIL və eyni teksturalı elementləri
> bir çağırışa yığır — qarışıq düzülsə, hər qida topu ayrıca çağırış olur.

### Ekran görüntüsü almaq
```bash
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --shot C:/yol/kadr.png --shot-delay 500
```

### Xəritənin bir yerini gözlə yoxlamaq

Doğuş yeri təsadüfidir, kol və cərəyan deşiyi isə dünyanın müəyyən
yerlərindədir — ona görə "kolun içi necə görünür" sualına ekran görüntüsü ilə
cavab vermək təsadüfə qalırdı. `--at` mikrobu istənilən nöqtədə doğurur:

```bash
GODOT --path game --resolution 1280x720 --fixed-fps 60 \
      -- --practice --at "-190,610" --shot C:/yol/kadr.png --shot-delay 26
```

Düzümdəki koordinatlar [`DishMap`](game/scripts/shared/dish_map.gd)-dədir.
Kadr nömrəsi vacibdir: `--shot` mikrobu hərəkətə salır, ona görə uzun
gecikmədə o, artıq yoxlamaq istədiyin yerdən çıxmış olur.

### Növün görüntüsü üzərində işləmək
```bash
GODOT --path game --resolution 900x900 --fixed-fps 60 \
      -- --preview --preview-species 2 --preview-balls 6 \
         --shot C:/yol/kadr.png --shot-delay 100
```
Oyunun içində mikrob 30 piksel radiusundadır — telefonda kifayətdir, forma
üzərində işləyəndə isə heç nə seçilmir. Stend eyni [`GermVisual`]-i böyüdüb
çəkir və mikrobu **həqiqi sürətlə** hərəkət etdirir: sürünmə, addım və kirpik
dövrü sürətdən çıxdığı üçün dayanan mikroba baxmaq mənasızdır.

`--fixed-fps` kadrı deterministik edir, yəni eyni `--shot-delay` həmişə eyni
kadrı verir — dəyişikliyi əvvəl/sonra müqayisə etmək mümkün olur.

---

## Android

### Test APK (debug imza, arm64 + x86_64)
```bash
GODOT --headless --path game --export-debug "Android" build/GermArena.apk
adb install -r build/GermArena.apk
```

### Release APK (Play Store, arm64)
```bash
bash tools/build_release_apk.sh
```

**Release imzası.** İmza açarı qəsdən repodan kənardadır. Skript onu
`C:\Users\User\.keystores\germ_arena_release.env` faylından oxuyur:

```bash
# germ_arena_release.env
GERM_ARENA_KEYSTORE=C:/Users/User/.keystores/germ_arena_release.keystore
GERM_ARENA_KEYSTORE_USER=germarena
GERM_ARENA_KEYSTORE_PASSWORD=...
```

Açar yaratmaq:
```bash
keytool -genkeypair -v -keystore germ_arena_release.keystore -alias germarena \
        -keyalg RSA -keysize 2048 -validity 10000
```

> ⚠️ **Keystore faylını və parolu mütləq ehtiyat nüsxələyin.** Play Store-a
> yüklənən tətbiq həmişə eyni açarla imzalanmalıdır. Açar itsə, tətbiqi bir daha
> yeniləmək mümkün olmur — yalnız yeni paket adı ilə sıfırdan yayımlamaq qalır.
>
> **iOS:** Windows-da mümkün deyil, Mac tələb olunur.

---

## Şəbəkə modeli

```
Client (60 FPS)                          Server (30 Hz, headless)
  giriş oxu ──────────────────────────>   giriş buferi
  öz hərəkətini dərhal oynat (predict)     Sim.step() — yeganə həqiqət
  snapshot gələndə düzəlt (reconcile) <──  30 Hz snapshot yayımı
  rəqibləri 100 ms geridə göstər
```

Üç prinsip:

1. **Client heç nə qərar vermir.** Yalnız giriş göndərir; dəymə, udma, partlama serverdədir.
2. **Simulyasiya bir dəfə yazılıb.** `sim.gd` həm serverdə, həm client proqnozunda işləyir.
3. **Godot fizikası istifadə olunmur.** Prediction üçün simulyasiyanı geri sarıb yenidən
   oynatmaq lazımdır; fizika mühərriki bunu deterministik etmir.

> **Öz topun gecikməli xəttdə çəkilmir.** Rəqiblər 100 ms geridə göstərilir, öz
> mikrobun isə proqnozdan — yəni indi. Top da gecikməli xəttə salınsaydı (və
> salınırdı), öz atdığın top mikrobunun 100 ms əvvəlki yerində doğulardı: top
> 420 px/s getdiyinə görə bu, 42 piksel, mikrobun radiusundan (28 px) çox.
> Ekranda görünən budur ki, top mikrobun **arxasında** peyda olur, gövdənin
> içindən keçir və qabaqdan çıxır — sanki kənardan atılıb. Ona görə öz topun
> atəş açılan andakı doğuş nöqtəsindən uçur və serverin sözünü gözləmir;
> serverin xəttinə yalnız divardan sıçrayanda qayıdır, çünki sıçrayışı proqnoz
> bilmir.

### Görüş sahəsi (area of interest)

Dünya ekrandan ~4 dəfə böyükdür (2400 px enində), ona görə hər oyunçuya **yalnız
öz ətrafı** göndərilir. Bu iki problemi birdən həll edir:

- **Trafik** — io oyunlarının ən böyük problemi. 110 qida topunun hamısını
  saniyədə 30 dəfə göndərmək mobil şəbəkəni doldurar.
- **Cheat** — uzaqdakı rəqiblərin yeri client-ə ümumiyyətlə çatmır, ona görə
  "divar arxasını görmək" mümkün deyil. Mini xəritə də yalnız gördüklərini göstərir.

Sahənin radiusu tutumla böyüyür: böyük mikrob kamerada daha geniş görür, ona görə
daha çox məlumat alır. İki rəqəm eyni funksiyadan gəlir
([`Const.view_width` / `Const.aoi_radius`](game/scripts/shared/constants.gd)) —
əks halda ekranın kənarında obyektlər kəsilərdi.

Qida snapshot-un ən ağır hissəsidir, ona görə massiv-içində-massiv yox,
düz `PackedFloat32Array` göndərilir: ədəd başına 9 bayt əvəzinə 4.

### İki nəqliyyat

| Nəqliyyat | Nə vaxt | Qeyd |
|---|---|---|
| **ENet (UDP)** | Öz VPS-ində | Ən aşağı gecikmə — oyun üçün ideal |
| **WebSocket (TCP)** | Railway və bənzər PaaS | Bir az yavaş, amma hər yerdən keçir |

Seçim avtomatikdir: **ünvan `wss://` və ya `ws://` ilə başlayırsa WebSocket**, əks halda ENet.
Serverdə `PORT` mühit dəyişəni varsa (Railway onu verir) WebSocket-ə keçilir.

### Bağlantı kəsiləndə

Mobil şəbəkədə düşmək adi haldır, ona görə mikrob dərhal itmir:

1. Server mikrobu **20 saniyə** dünyada saxlayır. Mikrob hərəkət etmir, amma
   **vurula bilir** və metabolizmi işləyir (bağlantını kəsmək qorunma üsulu olmamalıdır).
2. Client 3 saniyə aralıqla 5 dəfə qayıtmağa çalışır.
3. Qayıdanda dünyaya girəndə verilmiş **sessiya nişanı** ilə tanınır — yeni peer id
   alır, amma köhnə mikrobuna (mövqe, toplar, tutum, hesab) qayıdır.
4. 20 saniyə keçsə və ya mikrob bu müddətdə partlasa, nişan etibarsız olur.

### Botlar

io oyununun ölüm səbəbi boş dünyadır: ilk oyunçu qoşulanda ortada tək qalsa,
dərhal çıxır. Ona görə **serverdə** bot mikroblar işləyir və əhalini 6-da saxlayır.

Bot heç bir imtiyaza malik deyil — insan oyunçu ilə eyni `Sim.PlayerInput`
strukturunu doldurur və eyni məhdudiyyətlərə tabedir. Davranışı doluluqdan asılıdır:
acdırsa qida axtarır, doludursa rəqibdən qaçır (bir dəymə onu partlada bilər),
ortadadırsa hücuma keçir.

İnsan oyunçu gələndə bot yerini ona verir — dünyada heç vaxt 10-dan çox mikrob olmur.

---

## Serveri Railway-də saxlamaq

Railway **ictimai UDP-ni dəstəkləmir**, ona görə orada WebSocket işlədilir.
Portu Railway `PORT` dəyişəni ilə verir, server onu özü tutur.

### İlk qurulum
```bash
railway login
railway init                      # yeni layihə: germ-arena
railway service create germ-arena
bash tools/deploy_server.sh
railway domain                    # ünvanı götür və constants.gd-də yenilə
```

### Yenidən deploy
```bash
bash tools/deploy_server.sh       # binarı ixrac edir + Railway-ə göndərir
```

Layihədə İKİ servis nəzərdə tutulub və hər biri müstəqil deploy olunur:

| Servis | Nədir |
|---|---|
| `germ-arena` | Oyun serveri (Godot headless, WebSocket) |
| `germ-arena-web` | Brauzer build-ini verən nginx |

### Brauzer versiyası
```bash
RAILWAY_PROJECT_ID=<id> bash tools/deploy_web.sh
```

Skript `Web` presetini `web/public/` qovluğuna ixrac edir, sonra `web/` qovluğunu
`germ-arena-web` servisinə göndərir.

Üç detal brauzerdə vacibdir və `web/default.conf.template` faylında həll olunub:

1. **wasm MIME tipi.** `application/wasm` verilməsə brauzer streaming kompilyasiyadan imtina edir.
2. **gzip.** Sıxılmamış wasm 38 MB-dır; Dockerfile build zamanı `.gz` hazırlayır,
   nginx `gzip_static` ilə onu verir — şəbəkədən ~10 MB keçir.
3. **`Cache-Control: no-cache`.** Fayl adları dəyişmir (`index.wasm`), ona görə keş
   köhnə build-i ilişdirə bilər. `no-cache` = hər dəfə ETag ilə yoxla (dəyişməyibsə 304).

### Diaqnostika
```bash
railway logs --service germ-arena     # server hər 5 saniyədə dünyaların vəziyyətini yazır
bash tools/check_server.sh            # WebSocket əl sıxması ilə sağlamlıq yoxlaması
```

Server `--verbose` ilə işləyir: neçə dünya var, 5 saniyədə neçə giriş paketi gəlib,
hər dünyada kimin harada olduğu, top sayı və tutumu loglarda görünür.

### Öz VPS-ində (ENet, daha aşağı gecikmə)
```bash
./germ_arena_server.x86_64 --headless -- --server --port 27015
```
UDP 27015 portu açıq olmalıdır.

---

## Tələlər — səssiz uğursuzluqlar

> ⚠️ **`multiplayer.multiplayer_peer` heç vaxt `null` olmur — Godot ora
> `OfflineMultiplayerPeer` qoyur.**
>
> O peer heç bir şəbəkəyə toxunmur, amma özünü **QOŞULU** elan edir
> (`get_connection_status() == CONNECTION_CONNECTED`) və `get_unique_id()`
> kimi **1**, yəni "mən serverəm", qaytarır. Yalnız statusa baxan yoxlama
> buna görə oyun açılan kimi "onlayn" deyir:
>
> ```gdscript
> # SƏHV — qoşulmadan da true qaytarır
> return multiplayer.multiplayer_peer != null \
>     and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
> ```
>
> Nəticə tam səssizdir: menyu "artıq qoşuluyuq" deyib `request_join.rpc_id(1, …)`
> göndərir, Godot isə bunu ÖZÜMÜZƏ göndərilmiş sayır və
> `RPC 'request_join' on yourself is not allowed` yazıb çağırışı atır. Serverə
> heç nə getmir, heç bir siqnal gəlmir — **OYNA düyməsi sadəcə işləmir.**
>
> Etibarlı şərt əl sıxışmanın bitməsidir: [`Net.local_id`](game/scripts/shared/net.gd)
> yalnız `connected_to_server` gələndə doldurulur. `sim_test`-də bunun üçün
> ayrıca yoxlama var — qoşulmamış client özünü onlayn saymamalıdır.

> ⚠️ **"Dəyişibmi?" sualına SAYLA cavab vermək olmaz — kimlik dəyişir, say qalır.**
>
> Ad və rəng snapshot-dan çıxarılıb ayrıca reyestrə köçürüləndə köhnəlmə
> yoxlaması belə yazılmışdı:
>
> ```gdscript
> if sim.germs.size() != _roster_n:   # SƏHV
> ```
>
> Amma `Sim.rekey_germ` mikrobu silib yenidən əlavə edir — **id dəyişir, say
> dəyişmir**. Yenidən qoşulma məhz bunu edir. Nəticədə qayıdan oyunçunun
> mikrobu bütün DİGƏR ekranlarda adsız və 0 rəngli qalırdı. Eyni tələ: bir
> tick-də bot doğulub biri partlasa da say dəyişmir.
>
> Səhv oyunçunun ÖZÜNDƏN gizlidir — o, öz ekranında hər şeyi düzgün görür.
> Yalnız başqasının ekranında bilinir, yəni tək client ilə test edəndə heç vaxt
> tapılmır.
>
> Düzgün yol id-lərin ÖZÜNDƏN imza yığmaqdır (`key = key * 31 + gid`).
> `_test_roster_tracks_ids` bunu qoruyur.

> ⚠️ **Variant massivində hər ədəd ~9 bayt tutur — snapshot səssizcə MTU-nu aşırdı.**
>
> Godot bunu yalnız bir sətirlə deyir və o da server logunda itir:
>
> ```
> WARNING: Sending 1448 bytes unreliably which is above the MTU (1392)
> ```
>
> Aşan paket PARÇALANIR, snapshot isə `unreliable_ordered` gedir — yəni bir
> parçanın itməsi **bütün snapshot-u** itirir. Oyunçu üçün bu, təsadüfi
> "ilişmə" kimi görünür və səbəbi heç vaxt aydın olmur.
>
> Ölçüldükdə ən pis hal **2224 bayt** idi. Üç səbəb vardı və üçü də
> "məntiqli görünən" koddan gəlirdi:
>
> | Səbəb | Ölçü |
> |---|---|
> | Ad və rəng hər tick göndərilirdi — halbuki heç vaxt dəyişmir | reyestrə köçdü |
> | Rəqiblərin `ack` və `cooldown`-u da gedirdi — client onları oxumur | [enum SelfF]-ə köçdü |
> | Mikroblar Variant massivi idi (~9 bayt/ədəd) | `PackedFloat32Array` (4 bayt) |
>
> Nəticə: **2224 → 1116 bayt**. Şəbəkəyə sıx gedir, client-də isə
> [`Const.unpack_germs`](game/scripts/shared/constants.gd) köhnə sətir formasına
> açır — belə çəkiliş kodu formatdan xəbərsiz qalır.
>
> `sim_test`-dəki `_test_snapshot_fits_mtu` indi bunu qoruyur və uğursuzluqda
> hansı sahənin şişdiyini bayt-bayt çap edir. Snapshot-a yeni sahə əlavə
> edəndə **əvvəlcə o testi çalışdır**.

> ⚠️ **Bot maneəni ATƏŞ üçün görürdü, HƏRƏKƏT üçün yox — xəritə daralanda donurdu.**
>
> [`Bot.think`](game/scripts/shared/bot.gd) hədəf seçəndə
> `Sim.has_line_of_sight` çağırırdı, amma getdiyi istiqaməti heç yoxlamırdı.
> Açıq qabda bu bilinmirdi: yer çox idi, bot maneəyə sürtünüb yan keçirdi.
>
> TƏK QALAN qabı daraldanda isə hamı mərkəzə sıxıldı və botlar maneəyə
> dirənib **tamamilə donub qaldı**. Diaqnostika birbaşa göstərdi — matçın son
> 60 saniyəsində üç botun mərkəzdən uzaqlığı `177, 177, 154` dəyərlərində
> dəyişmirdi:
>
> ```
> t=176 r= 204 uzaq=181, 183, 184
> t=208 r= 147 uzaq=177, 177, 154   ← donub
> t=240 r=  90 uzaq=177, 177, 154   ← hələ də
> ```
>
> Səssiz uğursuzluq idi: heç bir xəta yox, bütün testlər keçir, sadəcə matç
> **beş dəfədən beşində** döyüşlə yox, 240 saniyəlik vaxt limiti ilə bitirdi.
> Bir neçə saat balans "düzəlişi" (qida sıxlığı, quruma sürəti, botun
> aqressivliyi) heç nəyi dəyişmədi, çünki səbəb balansda deyildi.
>
> Düzəlişdən sonra: **altı matçdan altısı** 2:34–3:34 arasında, tək qalibi ilə.
> Dərs: rejim balansını ölçməzdən əvvəl agentlərin ümumiyyətlə TƏRPƏNDİYİNİ
> yoxla. `sim_test`-dəki `_test_full_solo_match` indi məhz bunu qoruyur.

> ⚠️ **Bir HUD elementinin BİR sahibi olmalıdır — yoxsa sonuncu yazan udur.**
>
> `Hud`-un xəbərdarlıq sətri, mərkəzdəki iri yazı və alt sətri kadr ərzində
> bir neçə yerdən yazılır. Sıra `Arena._apply_local`-dadır və orada
> `set_match` `update_gauge`-dən ƏVVƏL çağırılır:
>
> ```gdscript
> # SƏHV — set_match mətni yazır, update_gauge dərhal üstündən silir
> func set_match(...) -> void:
>     if drying:
>         _warn_lbl.text = "QURUYUR — mərkəzə get"
>         _warn_lbl.visible = true      # növbəti sətirdə itir
> ```
>
> `update_gauge` sonra gəlib `_set_warning("")` çağırır və sətri gizlədir.
> Nəticə səssizdir: kod işləyir, test yoxdur, sadəcə TƏK QALAN rejiminin ən
> ölümcül xəbərdarlığı **heç vaxt ekrana çıxmır**. Eyni səbəbdən sayımın alt
> sətrində doğuş anındakı "GİZLƏNDİN" yazısı donub qalırdı.
>
> Qayda: mətni yazan **bir** funksiya olsun, qalanları yalnız bayraq qoysun
> (`_drying`), yazan funksiya isə prioriteti özü həll etsin. Sayım gedərkən
> mərkəzdəki hər iki sətrin sahibi [`Hud.set_match`](game/scripts/client/hud.gd)-dir.

> ⚠️ **Şrift seçəndə Azərbaycan hərflərini YOXLA — xüsusən `Ə` və `ə`.**
>
> Oyun şrifti kimi ilk ağla gələnlərin çoxunda şva **yoxdur**: Fredoka, Titan
> One, Lilita One, Archivo Black, Rubik, Sora, Gabarito, Russo One — hamısında
> `Ə`/`ə` çatışmır (bəzilərində `Ğ ğ İ Ş ş` də). Şrift qalan hər şeyi düzgün
> göstərir, ona görə səhv gec görünür: menyuda "MƏŞQ" **"M□ŞQ"**, HUD-da
> "SƏVİYYƏ" **"S□VİYY□"** çıxır.
>
> Layihədə işlənən **Baloo 2** (başlıq) və **Nunito** (mətn) 14 hərfin
> hamısını daşıyır: `Ç ç Ə ə Ğ ğ İ ı Ö ö Ş ş Ü ü`. Yenisini əlavə etməzdən
> əvvəl həmin sətri fontda çap etdirib gözlə yoxla.

> ⚠️ **`_draw` içindəki hər primitiv AYRICA çəkiliş çağırışıdır.**
>
> Sprite-lar batch olunur, `draw_circle`/`draw_arc` isə yox. Xəritəyə dərinlik
> verəndə əvvəlcə hər şey `_draw`-a yazılmışdı — döşəmə 14 konsentrik disk,
> hər bərk maneəyə iki kölgə dairəsi, şüşə kənara dörd qövs. Ölçmə:
>
> | | Çəkiliş çağ. | Orta kadr | 1% ən pis |
> |---|---|---|---|
> | Əvvəl | 237 | 4.17 ms | 4.26 ms |
> | Hamısı `_draw`-da | **293** | 4.18 ms | 4.55 ms |
> | Döşəmə teksturaya, kölgə sprite-a | **207** | 4.17 ms | 4.17 ms |
>
> Yəni 14 disk = 14 çağırış, 15 maneənin kölgəsi = 30 çağırış. Teksturaya
> köçürüləndə isə **pulsuzdur**: sprite onsuz da çəkilir, kölgə onun bir
> hissəsidir. Nəticədə xəritə ƏVVƏLKİNDƏN də ucuz oldu — köhnə kod da
> kölgələri hər kadr `_draw`-da çəkirdi.
>
> Qayda: `_draw` yalnız **azsaylı və qat boyu ortaq** şeylər üçündür (şəbəkə
> bir `draw_multiline`, şüşə kənar bir neçə qövs). Obyekt başına təkrarlanan
> hər şey teksturaya bişirilməlidir.

> ⚠️ **Sprite-lara AYRI-AYRI `modulate` vermə.**
> 
> `gl_compatibility` batch-i yalnız ardıcıl, eyni teksturalı VƏ **eyni
> `modulate`-lı** elementləri bir çağırışa yığır. Hər maneəyə ±6% parlaqlıq
> fərqi verilmişdi — nəticə ölçüldü:
> 
> | | Çəkiliş çağ. | Ən pis kadr | 1% ən pis |
> |---|---|---|---|
> | Hər sprite-a ayrı `modulate` | 242 | **70.7 ms** (14 FPS) | 50% büdcə |
> | `modulate` çıxarılıb | **131** | 11.3 ms | 25% büdcə |
> 
> Xəta yoxdur, xəbərdarlıq yoxdur — sadəcə oyun telefonda ilişir. Rəng
> fərqi lazımdırsa **teksturaya bişir**, kodda modulate ilə vermə.

> ⚠️ **Yeni `class_name` skript yaradandan sonra MÜTLƏQ `--import` işlət.**
> 
> ```bash
> GODOT --headless --path game --import
> ```
> 
> Godot qlobal sinif adlarını `.godot/global_script_class_cache.cfg`-də saxlayır
> və onu YALNIZ redaktor (və ya `--import`) yeniləyir. Fayl diskdə olsa da,
> keşdə olmasa `class_name` tapılmır:
> 
> ```
> Parse Error: Could not find type "ShotTrails" in the current scope.
> Compile Error: Failed to compile depended scripts. (boot.gd)
> ```
> 
> Nəticə isə xətaya BƏNZƏMİR: `boot.gd` kompilyasiya olunmur, əsas səhnə heç
> vaxt yüklənmir, pəncərə açıq qalır və oyun sadəcə **donur**. Skript düzgün
> yazılıb, sınaqlar keçir, amma oyun işləmir — sanki dəyişiklik "alınmayıb".
> 
> `.uid` faylı da elə `--import` zamanı yaranır; onsuz commit etsən başqa
> maşında eyni hal təkrarlanır.

## Assetlər — bir vacib məhdudiyyət

> ⚠️ **SVG-də `<text>` elementi işlətmə.** Godot SVG-ni ThorVG ilə rasterləşdirir,
> ThorVG isə mətn elementlərini **sükutla atır** — heç bir xəta vermir, sadəcə
> yazı görünmür.
>
> Loqodakı "GERM ARENA" yazısı məhz buna görə SVG-də yox, Godot `Label`-ı ilə
> çəkilirdi (`main_menu.gd → _make_logo`). Yatay menyuda söz nişanı yoxdur —
> yuxarı sol küncdə oyunçunun öz nişanı dayanır, Brawl Stars ana ekranında
> olduğu kimi.

### Şriftlər

İki rol var və hər ikisi [`assets/ui/theme.tres`](game/assets/ui/theme.tres)-dən
gəlir — kodda hər `Label` üçün ayrıca şrift təyin edilmir:

| Rol | Şrift | Harada |
|---|---|---|
| Başlıq | **Baloo 2** (dəyişkən, 800) | Düymələr, növün adı, doluluq rəqəmi, mərkəzi mesajlar |
| Mətn | **Nunito** (dəyişkən, 600) | Liderlər, izahlar, ad qutusu, ipucları |

Başlıq rolu `Label`-a `theme_type_variation = "Heading"` ilə verilir (ayrıca
tip yoxdur — başlıq da `Label`-dir). Şrift dəyişdirməzdən əvvəl yuxarıdakı
Azərbaycan hərfləri tələsini oxu.

Dünyada **üç mikrob növü** var və hamısı tamamilə kodla çəkilir:

- **Kirpikli** — paramesium modeli. Kirpikləri metaxronal dalğa ilə döyünür,
  arxasında qamçı var, suda **üzür**.
- **Ayaqlı** — "günəş heyvancığı". Şüa kimi çıxan aksopodiyaları növbə ilə
  yığılıb-uzanır, dibdə **yeriyir**; sitoplazması öndəki ayağa axır.
- **Amöb** — hərəkət orqanı yoxdur, kənarın ÖZÜ hərəkət edir. İki qatlı gövdə
  (jel qabıq + axıcı iç) önə uzanıb arxadan yığılır və sahəsini saxlayaraq
  irəli axır — **sürünür**.

Növü **menyudan sən seçirsən** (üç kart). Seçim oyunun gedişinə **təsir edir**
(aşağıdakı bölmə) və buna baxmayaraq şəbəkəyə **bir bayt da** əlavə etmir:
növ də, superin doluluğu da toxunulmazlıq bayrağının boş bitlərində daşınır.

### Növün özəlliyi və superi

Hər növün **mühitlə münasibəti** başqadır — bu, üç orqanizmin əsl
ekologiyasıdır: planktonik üzgüçü, bentik yeriyən, substrat sürünəni.

| | Passiv | Super | Superin qiyməti |
|---|---|---|---|
| **Kirpikli** | ən cəld: tez qopur, uzun sürüşür · axın onu daha çox aparır | **TRİXOSİST** — yaxındakı rəqib topları dağılıb qidaya çevrilir, mikroblar itələnir, özü geri sıçrayır | −2 top; dağılan toplar yerə düşür və rəqib onları geri yeyə bilər |
| **Ayaqlı** | axına dirənir (pəncələr yapışır) · ən yavaş növ | **AKSOPODİYA TORU** — 4 saniyə: qida ona axır, tora düşən rəqib 40% yavaşlayır | tutumu aşarsa **öz superi onu partladır** — dolu ikən açmaq olmaz |
| **Amöb** | maneə radiusu kiçikdir: başqasının sığmadığı aralıqdan keçir | **SİSTLƏŞMƏ** — 2.5 saniyə qabıq: top **səkir**, metabolizm dayanır | tam hərəkətsizsən: nə qaçırsan, nə atırsan, nə yeyirsən |

Super **döyüşərək** dolur (Brawl Stars məntiqi): dəymə +3, qida +1/3 top,
sənə dəyəndə +1, partlatma isə tam doldurur. Hədd **15**-dir və bu rəqəm
təsadüfi deyil — dörd bitə tam sığır.

> **Heç bir super rəqibin top sayına toxunmur.** Zərər verən super
> `SHOT_PAYLOAD` riyaziyyatını yan yoldan pozardı, ona görə üçü də **mövqe,
> qida və vaxt** üzərində işləyir. Atəş dövrü, topun qiyməti və tutum artımı
> üç növdə də eynidir — bunu sənəd yox, `sim_test` saxlayır.

Botlar da superini işlədir və bu, məcburidir: dünyanın əhalisinin çoxu botdur,
super yalnız onlar da işlədəndə oyunun bir hissəsinə çevrilir.

Mikrobun ətrafında **halqa yoxdur**. Əvvəl iki halqa vardı (doluluq və fokus);
ikisi də çıxarıldı, çünki mikrobu konsentrik dairələrin içinə salırdı. Doluluq
indi membranın öz gərginliyindən oxunur, "bu, mənəm" sualına isə kamera cavab
verir — öz mikrobun həmişə ekranın mərkəzindədir.

Mikrob sprite DEYİL: ölçüsü tutumdan, içindəki topların sayı isə mövcud
saydan asılıdır, ikisi də oyun boyu dəyişir. Tam kodla çəkilir —
[`germ_visual.gd`](game/scripts/client/germ_visual.gd). Eyni səbəbdən partlayış
([`burst_fx.gd`](game/scripts/client/burst_fx.gd)) da kodla çəkilir: dalğaların
ölçüsü partlayan mikrobun radiusundan, damcıların sayı isə içindəki top
sayından asılıdır.

Təfərrüat: [`design/ART_BIBLE.md`](design/ART_BIBLE.md).

## Səslər

9 səs effekti [`design/tools/gen_audio.js`](design/tools/gen_audio.js) skripti ilə
**sintez olunur** — hazır sample yoxdur:

```bash
node design/tools/gen_audio.js   # design/audio/ qovluğuna yazır
cp design/audio/*.wav game/assets/sfx/
```

Skript yazdığı faylı geri oxuyub yoxlayır (format, müddət həddi, pik səviyyə,
kənar fade-lər) — pozuq klip layihəyə düşə bilmir.

`eject` və `hit` qəsdən fərqli tezlik sahələrindədir: oyunçu ekrana baxmadan
atışının canlı hədəfə dəydiyini eşitməlidir. Təfərrüat:
[design/AUDIO_BIBLE.md](design/AUDIO_BIBLE.md)
