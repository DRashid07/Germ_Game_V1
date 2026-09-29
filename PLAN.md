# Germ Arena — Texniki Plan

**Tarix:** 2026-08-24
**Platforma:** Android (birinci), brauzer (test üçün), iOS (sonra, Mac tələb olunur)
**Ekran:** Portrait 9:16, kamera oyunçunu izləyir — dünya ekrandan böyükdür

Bu layihə [`New game V1`](../New%20game%20V1) (Arena Duel) strukturunun üzərində qurulub:
eyni motor, eyni qovluq düzümü, eyni server-authoritative model. Oyun məntiqi isə
tamamilə fərqlidir — matç yox, **sonsuz io dünyası**.

## 1. Texnologiya seçimi

| Təbəqə | Texnologiya | Səbəb |
|---|---|---|
| Oyun motoru | **Godot 4.7.2-stable** | 2D-də ən güclü, pulsuz/royalty-siz, APK bazası ~25 MB |
| Dil | **GDScript** | Mobildə C#-dan stabil, sürətli iterasiya, headless serverdə eyni kod |
| Şəbəkə | `ENetMultiplayerPeer` (UDP) **və** `WebSocketMultiplayerPeer` (TCP) | UDP ən sürətlidir; Railway ictimai UDP vermir, ona görə WebSocket də lazımdır |
| Server | **Headless Godot** (`--headless -- --server`) | Client ilə EYNİ kod bazası → simulyasiya bir dəfə yazılır |
| Build | JDK 17 + Android SDK 36 (sistemdə mövcuddur) | Əlavə quraşdırma yoxdur |
| Dizayn/art | Müvəqqəti SVG-lər, sonra **Codex** | Bax [design/BRIEF.md](design/BRIEF.md) |

## 2. Oyun dizaynı (qərarlar)

### Əsas qayda

Mikrobun içindəki top sayı həm **sursat**, həm **candır**:

| Hadisə | Nəticə |
|---|---|
| Top atırsan | səndə −1, dəydiyi rəqibdə **+2** (top içəridə bölünür) |
| Rəqibin sayı TUTUMU aşır | rəqib partlayır, sən **+5 tutum** alırsan |
| Sənin sayın 2-dən aşağı düşür | **acından partlayırsan** (heç kim hesab almır) |
| Qida yeyirsən | +1 (tutum dolu olsa yemirsən) |
| Metabolizm | hər ~6 saniyəyə bir top yanır |
| Atəş dövrü | saniyədə bir top — həm hücum, həm boşalma sürəti budur |

Bir mexanika istifadəçinin verdiyi hər iki qaydanı (minimum 2, maksimum 10)
eyni anda işlədir: **rəqibi doldurub partladırsan, özün isə boşalıb ölə bilərsən.**

### Niyə məhz belə

- **Hücum risklidir.** Hər atəş səni ölüm həddinə yaxınlaşdırır — "sonsuz atəş" yoxdur.
- **Müdafiə var.** Dolan oyunçu top ataraq boşala bilər. Yəni partlatmaq üçün
  rəqibi onun boşalma sürətindən tez doldurmalısan → dəqiqlik və mövqe həll edir.
- **Zəifi vurmaq mənasızdır.** Ona top versən, o toplar onun sursatına çevrilir.
  Doğru hədəf **dolu** rəqibdir.
- **Maddə itmir.** Boşa gedən top qidaya çevrilir, partlayan mikrobun bütün topları
  ətrafa səpilir — mükafat elə həmin toplardır.

### Dünya

- **Format:** io tipli — **10 nəfərlik sonsuz dünya**, növbə yoxdur, matç yoxdur
- **Xəritə:** dairəvi petri qabı, radius 1200 px (dünya ekrandan ~4 dəfə böyükdür)
- **Kamera:** oyunçunu izləyir, tutum böyüdükcə uzaqlaşır
- **Maneə:** 22 selik ləkəsi (mərkəzdə böyük oriyentir + üç halqa)
- **Ölüm:** partlayan oyunçu dünyadan çıxır, nəticə ekranını görür və menyuya qayıdır
- **Bot:** dünya heç vaxt boş qalmır — əhali 6-dan aşağı düşəndə bot mikroblar əlavə olunur
- **İdarəetmə:** sol üzən joystick = hərəkət, sağ aşağıda top atma düyməsi.
  Ayrıca nişan almaq yoxdur — top hərəkət istiqamətinə gedir, dayanmısansa son baxdığın tərəfə

### Anti-snowball

Tutum artdıqca mikrob:

- **böyüyür** → daha böyük hədəf olur
- **yavaşlayır** → `speed = 190 × (10/tutum)^0.28`
- **daha tez acır** → metabolizm dövrü 6 s-dən 2.2 s-ə düşür

Yəni lider sonsuz böyüyə bilmir: böyük mikrob dayanmadan yemək axtarmalıdır.

## 3. Arxitektura

### Server-authoritative model
```
Client (60 FPS)                     Server (30 Hz tick, headless)
  ├─ Input oxu (joystick)  ──────>   ├─ Input buferi
  ├─ Local prediction                 ├─ Simulyasiya (hərəkət, top, udma, partlama)
  ├─ Reconciliation      <──────      ├─ Görüş sahəsinə görə snapshot
  └─ Rəqiblər: 100 ms interpolation
```
- Client **heç vaxt** dəymə/partlama qərarı vermir → cheat qorunması
- Client öz hərəkətini əvvəlcədən oynadır (prediction), server düzəlişi gələndə reconcile edir
- Rəqiblər 100 ms buferlə interpolate olunur → lag-da yumşaq görünüş

### Görüş sahəsi (area of interest)

Dünya ekrandan böyükdür, ona görə hər oyunçuya **yalnız öz ətrafı** göndərilir.
Bu, həm trafik qənaətidir, həm cheat qorunması: uzaqdakı rəqiblərin yeri client-ə
ümumiyyətlə çatmır. Sahənin radiusu tutumla birlikdə böyüyür — böyük mikrob daha
geniş görür, ona görə daha çox məlumat alır.

Qida snapshot-un ən ağır hissəsidir (ekranda 50-dən çox ola bilər), ona görə
`Array` yox, **`PackedFloat32Array`** ilə göndərilir: ədəd başına 9 bayt əvəzinə 4.

### Server strukturu
- Tək Godot prosesi → çoxlu **dünya (world)**
- Hər dünya = sadə obyekt (node ağacına toxunmur) → çox ucuzdur
- `Lobby`: yeri olan dünyanı tapır, yoxdursa yenisini açır; boşalan dünya bağlanır
- Botlar da serverdə işləyir və insan oyunçu ilə eyni `PlayerInput` strukturunu doldurur

### Fizika haqqında qərar
Godot fizika mühərriki **işlədilmir**. Client-side prediction üçün simulyasiyanı
geri sarıb yenidən oynatmaq lazımdır, fizika mühərriki isə bunu deterministik etmir.
Əvəzinə `sim.gd` daxilində saf GDScript toqquşma yazılıb (dairə-dairə itələmə,
parça-dairə kəsişməsi). Nəticədə eyni kod həm serverdə, həm client proqnozunda işləyir.

## 4. Fazalar

### Faza 0 — Mühit
- [x] Godot 4.7.2-stable (win64) + export templates (Arena Duel layihəsindən hazır)
- [x] Layihə skeleti, portret 720x1280, gl_compatibility

### Faza 1 — Dizayn (müvəqqəti)
- [x] Art bible: "bioluminescent petri dish", 10 mikrob rəngi
- [x] 12 SVG sprite + UI elementi
- [x] 9 səs effekti (skriptlə sintez olunur, özünü yoxlayır)
- [x] Codex üçün brif ([design/BRIEF.md](design/BRIEF.md))

### Faza 2 — Simulyasiya
- [x] Dairəvi dünya, maneələr, mikrobların bir-birini itələməsi
- [x] Top atma, sıçrama, rəqibə keçmə, tutumu aşanda partlama
- [x] Qida: doğulma, səpilmə, udma, sahibinə qarşı qısa kilid
- [x] Metabolizm və acından partlama
- [x] 28 headless test (`--simtest`) — hər iki ölüm qaydası ayrıca yoxlanılır

### Faza 3 — Şəbəkə
- [x] Headless server + ENet/WebSocket seçimi
- [x] Dünyaya giriş (növbəsiz), 10 nəfərlik tutum, avtomatik yeni dünya
- [x] 30 Hz tick + görüş sahəsinə görə snapshot
- [x] Client prediction + reconciliation
- [x] Rəqiblər 100 ms interpolyasiya, toplar xətti hesablama
- [x] Öz topunun proqnozu (dəymə dərhal görünür) + serverdə geri sarma (lag compensation, ≤ 300 ms)
- [x] Bağlantı kəsiləndə mikrob 20 s saxlanılır, sessiya nişanı ilə qayıtma
- [x] İnteqrasiya testi: 1 server + 2 insansız client + qəsdən şəbəkə kəsilməsi

### Faza 4 — Meta və cilalama
- [x] Menyu, ad və server ünvanının yadda saxlanması, qaydaların izahı
- [x] HUD: doluluq göstəricisi, liderlər cədvəli, mini xəritə, xəbərdarlıqlar
- [x] Nəticə ekranı (neçə partlatma, hansı tutum, nə qədər yaşadın, kim partlatdı)
- [x] Botlar dünyanı canlı saxlayır
- [ ] ⏳ AFK idarəsi (hərəkətsiz oyunçunun çıxarılması)

### Faza 5 — Mobil çıxış
- [x] Performans: ~180 çəkiliş çağırışı (pik), 60 FPS büdcəsinin 25%-i (masaüstü)
- [x] Debug APK (55 MB), Windows exe (tək fayl), Linux server binarı, Web build
- [x] PC idarəetməsi (WASD + BOŞLUQ) — siçan tək toxunuş kimi emulyasiya olunduğuna görə lazımdır
- [ ] ⏳ Real cihazda test (adb) — telefon qoşulu deyil
- [ ] ⏳ Release keystore və imzalanmış APK

### Faza 6 — Sonrakı
- Railway-də canlı server, brauzer versiyasının hostinqi
- Codex ilə əsl dizayn
- iOS build (Mac və ya bulud build), leaderboard, skin sistemi

## 5. Server hostinq

- **Prod:** Railway (Docker + WebSocket) — konfiqurasiya hazırdır, deploy edilməyib
- Railway ictimai UDP vermir, ona görə orada WebSocket; öz VPS-ində ENet (UDP) daha sürətlidir
- Test: öz kompüterində headless server (`--server --ws`)
- Bir dünya (10 oyunçu + botlar) ≈ çox az CPU; bir VPS onlarla dünya apara bilər

## 6. Əsas risklər

| Risk | Həll |
|---|---|
| Lag/latency mobil şəbəkədə | Prediction + interpolation + 30 Hz tick; hədəf < 150 ms |
| Trafik (io oyunlarında əsas problem) | Görüş sahəsi süzgəci + qida üçün `PackedFloat32Array` |
| Boş dünya (io oyunlarının ölüm səbəbi) | Serverdə botlar, əhali 6-dan aşağı düşmür |
| Snowball (lider hamını əzir) | Böyük mikrob yavaş, iri hədəf və tez acan olur |
| Cheat | Tam server-authoritative, client yalnız input göndərir |
| iOS build Windows-da mümkün deyil | Android birinci, iOS Faza 6-da |
