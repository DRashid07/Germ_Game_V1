# Germ Arena

Onlayn **io tipli** mikrob arenası. Mobil (Android) üçün, portret ekranda.
10 nəfərlik sonsuz petri qabı: girirsən, yeyirsən, böyüyürsən — partlayanda çıxırsan.

- **Format:** matç yoxdur, növbə yoxdur. Düyməni basan kimi dünyadasan.
- **Hərəkət:** telefonda sol barmaq üzən joystick, sağ aşağıda top atma düyməsi
- **PC-də:** `WASD` / ox düymələri hərəkət, `BOŞLUQ` top atır
- **Nişan:** yoxdur — top getdiyin tərəfə gedir, dayanmısansa son baxdığın tərəfə
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
      main_menu.gd       Menyu, qoşulma, qaydaların izahı
      hud.gd             Doluluq göstəricisi, liderlər, xəbərdarlıqlar, nəticə
      germ_visual.gd     Bir mikrobun görüntüsü (membran + içindəki toplar)
      minimap.gd         Petri qabının kiçik xəritəsi
      touch_stick.gd     Üzən virtual joystick (hərəkət)
      fire_button.gd     Top atma düyməsi (basılı saxlananda davamlı atəş)
      sfx.gd             Səs effektləri (autoload: Sfx)
    tools/
      sim_test.gd        28 headless test
      auto_client.gd     Şəbəkə testi üçün insansız client
      screenshot.gd      Redaktorsuz ekran görüntüsü
      perf_probe.gd      Kadr vaxtı və çəkiliş çağırışı ölçmə
  assets/                SVG sprite-lar, UI, WAV səslər
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
```
Eyni `World` və `Sim` kodu yerli işləyir; fərq yalnız snapshot-ların şəbəkədən
yox, yaddaşdan gəlməsidir. Server yatmış olsa da oyun oynanır.

### Serveri lokal qaldırmaq
```bash
GODOT --headless --path game -- --server --port 27015            # ENet (UDP)
GODOT --headless --path game -- --server --ws --verbose          # WebSocket + diaqnostika
```
Sonra menyuda server sahəsinə `ws://127.0.0.1:27015` yaz.
Server və oyun EYNİ build-dir — simulyasiya kodu ikisində eynidir.

### Testlər
```bash
# Simulyasiya + World testləri (28 test)
GODOT --headless --path game -- --simtest

# Şəbəkə inteqrasiya testi: 1 server + 2 insansız client
GODOT --headless --path game -- --server --ws --verbose &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label A --quit-after 30 &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --quit-after 30 &

# Yenidən qoşulma testi: B 10 saniyə sonra qəsdən düşür və nişanla qayıdır
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --drop-after 10 --quit-after 30 &
```

Testlər oyunun HƏR İKİ ölüm qaydasını ayrıca yoxlayır: tutumu aşıb partlamaq
və acından partlamaq. Bunlar oyunun bütün balansının dayandığı iki qaydadır.

### Performans ölçmək
```bash
GODOT --path game --resolution 720x1600 -- --practice --perf 12
```
Orta, **1% ən pis** kadr, çəkiliş çağırışı və yaddaş yazılır.
Masaüstü nəticəsi (RTX 5050): **~180 çəkiliş çağırışı (pik), 60 FPS büdcəsinin 25%-i**.

> Çəkiliş çağırışının 280-dən ~170-ə düşməsi bir dəyişiklikdən gəlir: səhnə
> qatları növlərə bölündü (bütün qida bir qatda, bütün toplar başqasında) və
> maneələr sprite-a keçirildi. Godot yalnız ARDICIL və eyni teksturalı elementləri
> bir çağırışa yığır — qarışıq düzülsə, hər qida topu ayrıca çağırış olur.

### Ekran görüntüsü almaq
```bash
GODOT --path game --resolution 720x1560 --max-fps 60 \
      -- --practice --shot C:/yol/kadr.png --shot-delay 500
```

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

## Assetlər — bir vacib məhdudiyyət

> ⚠️ **SVG-də `<text>` elementi işlətmə.** Godot SVG-ni ThorVG ilə rasterləşdirir,
> ThorVG isə mətn elementlərini **sükutla atır** — heç bir xəta vermir, sadəcə
> yazı görünmür.
>
> Loqodakı "GERM ARENA" yazısı məhz buna görə SVG-də yox, Godot `Label`-ı ilə
> çəkilir (`main_menu.gd → _make_logo`).

Mikrobun özü sprite DEYİL: ölçüsü tutumdan, içindəki topların sayı isə mövcud
saydan asılıdır, ikisi də oyun boyu dəyişir. Tam kodla çəkilir —
[`germ_visual.gd`](game/scripts/client/germ_visual.gd).

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
