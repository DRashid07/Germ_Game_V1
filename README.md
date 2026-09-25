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
| **Titrəmə** (telefonda) | zərbə 22 ms · super 45 · tutum 60 · ölüm 160 | [`Settings.vibrate`](game/scripts/shared/settings.gd) |

Uçan toplar da iz buraxır — [`ShotTrails`](game/scripts/client/shot_trails.gd).

Titrəmə BEŞİNCİ kanaldır və qalanlarını əvəz etmir: səs kəsilə bilər (səssiz
rejim, qulaqlıqsız oyun), parıltı isə barmağın altında qala bilər. Ayarlardan
söndürülür. Kamera silkələnməsi də ayardadır (QAPALI/AZ/NORMAL) — söndürüləndə
digər kanallar toxunulmaz qalır, yəni məlumat itmir.

Bu dörd kanal SAXLANILIR. Üçüncü vizual mərhələ onların üstünə istiqamət və
material qatını əlavə edir:

| Yeni qat | Hadisə | Oxunuş |
|---|---|---|
| Lülə alovu | atəş | membran yarığında `0.08 s`, nişan oxunda parlaq ləçək |
| İstiqamətli sıçrantı | top mikroba girir | gələn oxun ətrafında dar konus; radial deyil |
| Zərbə dalğası | mikrob partlayır | `0.40 s` genişlənən nazik halqa |
| Qida qövsü | qida udulur | qida membrana qövslə uçur, sonunda kiçik su halqası |
| Tutum aurası | `+5 TUTUM` | `0.62 s` qızılı aura + halqa |
| Kol xışıltısı | kola giriş/çıxış | yalnız toxunulan üst frond `0.52 s` dalğalanır |
| Qabıq qırıntısı | kövrək divara zərbə | adi zərbədə bir tərəfə, üçüncüdə bütün çevrəyə parça + toz |
| Cərəyan axını | fasiləsiz | HIGH-da hər deşiyə sorulan 7 cizgi; LOW-da sönür |
| Doğuş halqası | mikrob ilk görünür | `0 → 1.12 → 1.0`, `0.35 s`; [`GermVisual`](game/scripts/client/germ_visual.gd) |

İlk altı zərrəcikli döyüş effekti və qabıq qırıntıları ayrıca node açmır:
[`JuiceFx`](game/scripts/client/juice_fx.gd) hamısını bir node-da üç qalınlıq
batch-inə yığır. Eyni anda neçə hadisə olmasından asılı olmayaraq qat ən çox
**3** `draw_multiline_colors` çağırışı edir. Zərbə öz mikrobuna dəyəndə kamera
gələn ox boyunca ən çox 16 px təpik alır; yaxın rəqibin ölümü mövcud
`_punch` mexanizmi ilə qısa zoom verir.

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

Dörd rejim var və oyunçu menyuda OYNA düyməsinin üstündəki kartdan seçir.
Qaydalar (top, partlama, növ gücləri) hər ikisində EYNİDİR — fərq yalnız
matçın olub-olmamasındadır.

| | **SONSUZ ARENA** | **TƏK QALAN** | **CÜT** | **ÜÇLÜK** |
|---|---|---|---|---|
| Mikrob | ən azı 6 | 10 | 10 (5×2) | 6 (3v3) |
| Giriş | dərhal | 3 s sayım | 3 s sayım | 3 s sayım |
| Ölüm | menyu, yenidən gir | matç bitir | **yoldaşın diriltir** | raund bitir |
| Qab | sabit 1200 | 1200 → 90 | 1200 → 90 | 700 → 220 |
| Spor | yox | 3 | 3 | yox |
| Bitiş | yoxdur | sonuncu mikrob | sonuncu cüt | 3 raundun 2-si |

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

**Komanda ayrı KANALLA göstərilir, rənglə yox.** On mikrob rəngi qalır, çünki
rəng "kim" sualına cavab verir, komanda isə "dost ya düşmən" sualına — ikisi
ayrı sualdır. Yoldaşın adı **laym**, düşməninki sönük ağdır.

CÜT-də yoldaşın sağ ikən ölüm müvəqqətidir: 15 saniyə sonra qayıdırsan, amma
**tutum sıfırlanır** — dirilmə ikinci şansdır, cəzasız davam deyil. İkiniz də
ölsəniz cüt matçdan çıxır.

ÜÇLÜK-də tutum raunddan raunda **keçmir**: keçsəydi, birinci raundu udan
komanda ikincidə də üstün başlayardı və matç faktiki olaraq bir raundda
həll olunardı.

Tam quruluş: [design/MODES.md](design/MODES.md).

## Ekranlar

[Baş menyu](docs/screenshot_menu.png) · [Oyun ekranı](docs/screenshot_world.png)

### Menyunun quruluşu

Zonalar Brawl Stars-ın **bugünkü (2026)** ana ekranından götürülüb — hər
birinin bir işi var (araşdırma: [ART_BIBLE § 6b](design/ART_BIBLE.md)):

| Zona | Nə var | Niyə |
|---|---|---|
| Mərkəz | podiumda növün qəhrəmanı, adı başının üstündə | Kimlik OBYEKTƏ bağlıdır; toxunmaq titrədir, çəkmək dartır |
| Aşağı-sağ | [rejim kartı][sarı **OYNA**] | «Nə oynayıram» və «başla» bir qərardır — yan-yana |
| Sol lent | MAĞAZA\*, MİKROBLAR, MƏŞQ | Brawl Stars-da Shop, Brawlers |
| Yuxarı-sol | profil: növün avatarı + ad | Sabit konvensiya |
| Yuxarı-sağ | QİDA\*, DNT\* valyutaları + dişli (AYARLAR) | Ayarların YEGANƏ qapısı |
| Aşağı-sol | MİKRO PASS\*, TAPŞIRIQLAR\* | Brawl Pass və Quests |

\* **Görünüş üçündür** — arxalarında hələ sistem yoxdur: valyutalar `0`-dır,
basanda «… — TEZLİKLƏ!» bildirişi çıxır. Cavabsız düymə etibarı aparır, ona
görə hər biri nə gəlmədiyini açıq deyir.

Düymələrin dili də Brawl Stars-dandır: qalın qara kontur, altda tünd dodaq,
konturlu ağ yazı ([`ChunkyBox`](game/scripts/client/chunky_box.gd)). İkonlar
və illüstrasiyalar Codex ilə çəkilib ([design/menu_art/](design/menu_art/)).

**MİKROBLAR** — Brawl Stars-ın Brawlers kolleksiyası: hər növ sinfinin rəngində
portret kartdır (KİRPİKLİ — CƏLD, AYAQLI — NƏZARƏTÇİ, AMÖB — MÜDAFİƏÇİ). Karta
toxunmaq növün **səhifəsini** açır: böyük portret, «OYUNDA» pəncərəsində canlı
oyun mikrobu, `Const`-dan gələn dörd göstərici, super və sarı **SEÇ** düyməsi.
Ətraflı: [ART_BIBLE § 6d](design/ART_BIBLE.md).

Növ və rejim seçimi ANA EKRANDA deyil, ayrı vərəqlərdədir
([design/menu/](design/menu/)). Səbəb sayğacdır: əvvəl ana ekranda on yeddi
zona və altı cümlə vardı, oyunçu OYNA-ya çatana qədər hamısının arasından
keçirdi. İndi səkkiz zona və bir sətir qeyd var.

> Sağ lent QƏSDƏN boşdur. Brawl Stars-da orada Battle Log, liderlər və
> xəbərlər var; bizdə hələ yoxdur və boş düymə qoymaqdansa yeri saxlamaq
> daha düzgündür.

### Ayarlar

Menyudakı dişli → tam ekran **AYARLAR**. **Matçın içində ayarlar yoxdur** —
Brawl Stars-da olduğu kimi, döyüş ekranında sistem düyməsi yoxdur. Matçdan
çıxmaq üçün Android-in **GERİ** jesti və ya **ESC**: kiçik təsdiq açılır
(DAVAM ET / ÇIX). Sonsuz arenada matç bitmədiyi üçün bu çıxış qalmalıdır.

Üç sütun, çünki ekran yatay 1280×720-dir: bir sütunluq siyahı eni boş qoyub
oyunçunu sürüşdürməyə məcbur edərdi.

| Sütun | Ayar | Nə edir |
|---|---|---|
| **SƏS** | Ümumi · Effektlər · İnterfeys | Üç şin: `Master`, `SFX`, `UI` |
| | Səssiz rejim | `Master` sıfırda — səviyyələr yadda qalır |
| **QRAFİKA** | Keyfiyyət YÜKSƏK/AŞAĞI | Glow, HDR buferi, zərrəcik sıxlığı |
| | Kadr həddi 30/60/120/SƏRBƏST | `Engine.max_fps` — telefonda batareya ayarıdır |
| | Ekran silkələnməsi QAPALI/AZ/NORMAL | Yalnız kamera; səs, parıltı və donmuş kadr qalır |
| | Kadr sayğacı | HUD-un yuxarı-mərkəzində FPS |
| **İDARƏ** | Sol əl düzümü | Joystick sağ yarıya, atəş və super sol aşağıya |
| | Titrəmə | Zərbə, super, tutum artımı, ölüm (yalnız telefonda) |
| | Server ünvanı · Sıfırla · versiya | |

Hamısı [`Settings`](game/scripts/shared/settings.gd) autoload-undadır və
`user://settings.cfg`-yə yazılır. Autoload olması praktik nəticə verir: menyunu
KEÇƏN yollar da (`--practice`, `--agent`, `--map`) oyunçunun səsi və kadr həddi
ilə başlayır — əvvəl ayarları yalnız menyu oxuyurdu.

**Musiqi sürgüsü QƏSDƏN yoxdur** — oyunda musiqi treki yoxdur (bax
[AUDIO_BIBLE](design/AUDIO_BIBLE.md): cəmi 10 qısa effekt). Heç nəyi idarə
etməyən sürgü bütün ekrana olan etibarı aparır; şin isə hazırdır, trek gələndə
bir sətir əlavə olunacaq.

> **Kadr həddi əmr sətrini POZMUR.** `--max-fps` və ya `--fixed-fps` verilibsə
> ayar `Engine.max_fps`-ə toxunmur — yoxsa oyunçunun 30-luq seçimi `--perf` və
> `--shot` ölçmələrini səssizcə dəyişərdi.

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
| `ESC` | matçdan çıxış təsdiqi · menyuda açıq vərəqi bağlayır |
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

## Canlı server — Render

```
https://germ-arena.onrender.com       brauzer versiyası — linki açıb oyna
wss://germ-arena.onrender.com/ws      oyun serveri (telefon və masaüstü build-ləri)
```

Sayt və oyun serveri **bir** Render servisidir: nginx `/` ünvanında brauzer
build-ini verir, `/ws`-i isə eyni konteynerdəki Godot serverinə ötürür (bax
["Render-də saxlamaq"](#render-də-saxlamaq)). Brauzer versiyası server ünvanını
səhifənin ÖZ ünvanından götürür ([`Const.default_server`](game/scripts/shared/constants.gd)),
telefon və masaüstü build-ləri isə `DEFAULT_SERVER`-i işlədir.

> ⏳ **Pulsuz plan 15 dəqiqə boş qalanda yatır.** Yatmış servisin ilk açılışı
> ~1 dəqiqə çəkir — Render konteyneri oyadır. Brauzerdə bu, sadəcə uzun
> yüklənmədir: səhifə açılanda server artıq oyaqdır. Telefonda isə OYNA-nın
> 12 saniyəlik həddi oyanmadan qısadır — "cavab yoxdur" görünsə, bir dəqiqə
> sonra yenidən bas.

Serverə oynamadan baxmaq:
```bash
bash tools/check_server.sh                            # Render
bash tools/check_server.sh ws://127.0.0.1:27015       # lokal server
```

Şəbəkəsiz oynamaq həmişə mümkündür: **MƏŞQ (offline)** — eyni dünya kodu
botlarla yerli işləyir.

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
      settings.gd        Oyunçunun bütün ayarları, `settings.cfg` (autoload: Settings)
    server/
      lobby.gd           Dünyalar, giriş/çıxış, yenidən qoşulma
      world.gd           Bir petri qabı: Sim + oyunçular + botlar + snapshot
    client/
      arena.gd           ★ Oyun ekranı: prediction, interpolyasiya, kamera, reconnect
      menu_v2.gd         ★ Baş menyu: fon + podiumda qəhrəman, növ kartları, qoşulma
      main_menu.gd       KÖHNƏ şaquli menyu — ehtiyat (`--menu1`), sonra silinir
      hud.gd             Doluluq göstəricisi, liderlər, xəbərdarlıqlar, nəticə
      germ_visual.gd     Bir mikrobun görüntüsü — ÜÇ NÖV (üzür, yeriyir, sürünür)
      burst_fx.gd        Partlayaraq ölmə effekti (dalğa, damcı, membran parçaları)
      juice_fx.gd        Qısa VFX-lər — bütün hadisələr bir node-da, ən çox 3 batch
      shot_trails.gd     Uçan topların izi — hamısı BİR çəkiliş çağırışında
      water_motes.gd     Suda asılı zərrəciklər — axını gözlə görünən edir
      minimap.gd         Petri qabının kiçik xəritəsi
      touch_stick.gd     Üzən virtual joystick (hərəkət)
      fire_button.gd     Top atma düyməsi (basılı saxlananda davamlı atəş)
      super_button.gd    Super düyməsi — maye dolumu, hazır nəbzi və işıq zolağı
      sfx.gd             Səs effektləri (autoload: Sfx)
      settings_view.gd   AYARLAR ekranı — yalnız menyuda (matçda ayar yoxdur)
      chunky_box.gd      Brawl Stars düymə dili: kontur + dodaq + parıltı, konturlu yazı
      touch_slider.gd    Səs sürgüsü — barmaq üçün (Godot-un HSlider-i çox kiçikdir)
    tools/
      sim_test.gd        260 headless test
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
    menu/                ana ekranın illüstrasiyaları (Codex): fon, podium, üç
                         növün qəhrəmanı — mənbə və promptlar design/menu_art/-da
  web/shell.html         Brauzer versiyasının HTML qabığı
design/                  Dizayn mənbəyi (art/audio bible, brif, sprite, səs generatoru)
tools/                   Build və deploy skriptləri
build/                   Hazır APK və Linux server binarı
deploy/render/           Render: sayt + oyun serveri bir konteynerdə (mənbədən build)
render.yaml              Render servisinin tərifi
web/                     Railway: brauzer versiyasının hostinqi (nginx konteyneri)
Dockerfile               Railway: hədəf serverin konteyner tərifi
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

# Rejimi seçərək (0 sonsuz · 1 TƏK QALAN · 2 CÜT · 3 ÜÇLÜK):
GODOT --path game -- --practice --mode 3

# Qrafika səviyyəsi (0 yüksək · 1 aşağı):
GODOT --path game -- --practice --quality 1
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
# Simulyasiya + World testləri (260 test)
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
Masaüstü nəticəsi (RTX 5050), `--disable-vsync` ilə. “Əvvəl” bu sənəddəki ilkin
ölçüdür; “M2” xəritə redizaynından sonrakı ağacdır; “M3” animasiya/VFX/UI
qatının 2026-09-17 yekun ölçüsüdür:

| Rejim | Əvvəl orta | M2 orta | **M3 orta** | **M3 1% ən pis** | M3 büdcə | Çəkiliş çağ. pik (əvvəl → M2 → M3) |
|---|---:|---:|---:|---:|---:|---:|
| SONSUZ ARENA (6 mikrob) | 1.85 ms | 2.15 ms | **2.48 ms** | **3.70 ms** | **15% / 22%** | ~230 → 188 → **196** |
| TƏK QALAN (10 mikrob) | 2.82 ms | 2.93 ms | **2.35 ms** | **4.03 ms** | **14% / 24%** | ~212 → 249 → **202** |

Hər iki rejimdə 16.7 ms-i aşan kadr **0**-dır. Pik çağırışlar 350 həddindən
müvafiq 154 və 148 aşağıdır. Eyni M3 reviziyasının daha sıx TƏK QALAN
çalışmasında **263** pik də müşahidə olunub; konservativ ehtiyat yenə 87-dir.
Səhnə təsadüfi olduğuna görə çağırış sayı görünən mikrob/top/qida ilə dəyişir.
Hadisə sayı artmasına baxmayaraq limitin qorunmasının səbəbi yeni VFX-in hadisə
başına node yox, ortaq batch olmasıdır. TƏK QALAN-da dörd əlavə mikrob və quruma
materialı ən bahalı kombinasiyadır, ona görə mikrob sayını artıran hər rejim bu
cədvəldə ayrıca ölçülməlidir.

> Çəkiliş çağırışının 280-dən ~170-ə düşməsi bir dəyişiklikdən gəlir: səhnə
> qatları növlərə bölündü (bütün qida bir qatda, bütün toplar başqasında) və
> maneələr sprite-a keçirildi. Godot yalnız ARDICIL və eyni teksturalı elementləri
> bir çağırışa yığır — qarışıq düzülsə, hər qida topu ayrıca çağırış olur.

### Telefon uyğunluğu — ölçülmüş vəziyyət

| Yoxlanan | Nəticə |
|---|---|
| Nisbətlər 16:9 … 21:9 və 4:3 | HUD bütöv, kəsilmə yoxdur |
| Görüş sahəsi ekranın küncünə çatır | bəli, ehtiyat **18%** (ən dar hal 21:9) |
| Ekran forması üstünlük verirmi | **yox** — görünən sahə hər ekranda eynidir |
| Qrafika səviyyəsi | YÜKSƏK / AŞAĞI, telefonda ilkin dəyər AŞAĞI |
| Çox toxunuş (hərəkət + atəş + super) | hər idarə öz `_touch_index`-ini izləyir |
| Safe area (çıxıntı/notch) | `DisplayServer.get_display_safe_area()` tətbiq olunur |
| Portret pəncərə | yatay kadra letterbox olunur (bax [boot.gd](game/scripts/boot.gd)) |
| Renderer | `gl_compatibility`, arm64 + x86_64, ETC2/ASTC |
| Yaddaş | 42–54 MB |
| Çəkiliş çağırışı | yekun çalışmada 196 / 202; müşahidə edilən pik 263; sərt hədd 350 |

### Ekran forması üstünlük VERMİR

Kameranın miqyası qısa kənardan yox, **SAHƏDƏN** çıxır: oyunçunun gördüyü
dünya sahəsi bütün ekranlarda eynidir (`620 × 620 × 16/9`). Geniş ekran daha
enli, amma daha alçaq görür.

Əvvəl miqyas qısa kənardan çıxırdı və ekranın forması oyun üstünlüyü verirdi:

| Nisbət | Əvvəl | İndi |
|---|---|---|
| 4:3 | 513k sahə (−25%) | 683k |
| 16:9 | 683k (etalon) | 683k |
| 20:9 | 854k (+25%) | 683k |
| 21:9 | 897k (**+31%**) | 683k |

Yəni ən yaxşı və ən pis telefon arasında **56 faiz** fərq vardı. Mobil rəqabət
oyunları (Brawl Stars və bənzərləri) məhz bunu bağlayır. Bonus olaraq görüş
sahəsinin ehtiyatı da 6%-dən **18%**-ə qalxdı: sahə sabit olanda kadrın küncü
sonsuz uzaqlaşmır. `_test_aoi_covers_screen` altı real telefon nisbətini yoxlayır.

### Qrafika səviyyəsi

Dişli → AYARLAR → QRAFİKA → **Keyfiyyət: YÜKSƏK / AŞAĞI**. Telefonda ilkin
dəyər AŞAĞI-dır. Seçim MATÇIN ORTASINDA da işləyir (bax [`Arena._apply_quality`](game/scripts/client/arena.gd)):
mühit həmişə qurulur, glow isə yandırılıb-söndürülür — əvvəl `WorldEnvironment`
AŞAĞI-da ümumiyyətlə yaradılmırdı və oyunçu ayarı dəyişəndə növbəti matça qədər
heç nə dəyişmirdi.

AŞAĞI-da glow və `hdr_2d` sönür; əsas su zərrəcikləri `80+30`-dan `34+14`-ə
enir; cərəyan axını və quru sərhəd buxarı tam sönür. Yeni döyüş zərrəcikləri
yarıya enir (lülə ləçəyi `3→1`, sıçrantı `8→4`, udulma izi `4→2`, qabıq
qırıntısı `6/12→3/6`, aura şüası `12→6`), halqa seqmentləri də `40→20` olur.
Glow tam ekranı bir neçə dəfə bulandıran keçiddir və HDR ilə birlikdə kadr
buferini RGBA16F-ə qaldırır — mobil GPU-da hər kadr iki dəfə çox yaddaş zolağı.

> Bu fərq masaüstündə **ölçülə bilmir**: eyni konfiqurasiyanın iki çalışması
> arasındakı səpələnmə (2.0 ms və 3.3 ms) konfiqurasiyalar arasındakı fərqdən
> böyükdür. Ona görə seçim oyunçuya verilib — telefonda ölçmək lazımdır.

Səviyyə YALNIZ görüntüyə təsir edir: qaydalar, görüş sahəsi və şəbəkə eynidir,
yəni aşağı keyfiyyət nə üstünlük verir, nə də məhrum edir.

### Ekran görüntüsü almaq
```bash
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --shot C:/yol/kadr.png --shot-delay 500
```

Ani hadisələr (super, partlayış, doğuş) tək kadra düşmür — ardıcıllıq çək.
`--charge` superi dolu başladır, `--idle` avtomatik oyunçunu söndürür (HAZIR
vəziyyətin şəkli üçün):
```bash
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --species 0 --charge --shot C:/yol/s.png \
         --shot-delay 4 --shot-count 12 --shot-every 4      # s_00.png … s_11.png
```

### Oyunu agentlə oynamaq (vizual QA)

[`PlayAgent`](game/scripts/tools/play_agent.gd) oyunu menyudan başlayıb **real
girişlə** oynayır: düymələrə basır, ünvan sahəsinə yazır, joysticki barmaqla
sürüşdürür, atəş və super düymələrinə toxunur. `--practice --shot`-dakı
avtomatik oyunçu isə girişi tamamilə keçir — joystik, düymələr, menyu və
ölümdən sonra menyuya qayıdış onunla heç vaxt sınanmır.

```bash
GODOT --path game --resolution 1280x720 --max-fps 60 -- --agent \
      --agent-out C:/yol/qovluq --agent-species 1 --agent-mode 2 --agent-time 90
```

| Bayraq | Mənası |
|---|---|
| `--agent-species`, `--agent-mode`, `--agent-quality` | menyunun öz düymələri ilə seçilir |
| `--agent-server ws://127.0.0.1:27015` | ünvan AYARLAR ekranına yazılır, OYNA ilə onlayn |
| `--agent-dead-server` | OYNA-nı yatmış serverlə sına: düymə ilişməməli, səbəb yazılmalıdır |
| `--agent-rounds N` | ölüm → nəticə → menyu → yenidən oyun dövrü; ölməsə **MATÇI TƏRK ET** ilə çıxır |
| `--agent-noshots` | kadr çəkmə — yalnız ölçü (PNG yazmaq 50–150 ms sıçrayış verir) |
| `--agent-no-keys`, `--agent-limit S` | klaviatura sınağını keç; sərt vaxt həddi |

Qovluğa `NNN_ad.png` (dövri və hadisə anında), `log.jsonl`, `issues.txt` və
`summary.json` yazılır; çıxış kodu 3 = problem tapılıb. Avtomatik yoxlamalar:
joystik/atəş/super cavabı, kamera, kadr sıçrayışı, node sızması, ekrandan
çıxan və üst-üstə düşən düymələr, menyu axını, AYARLAR ekranı (menyuda və
matçın içində — açılır, bağlananda matç davam edir), mühərrik xətaları.

> Oyunçunun `settings.cfg`-si agentin menyu seçimləri ilə dəyişir — agent onu
> başlanğıcda saxlayıb sonda geri yazır. Xarici `timeout` agenti öldürsə, bu
> addım icra olunmur, ona görə `--agent-limit` həmişə `timeout`-dan qısa olmalıdır.
> Pəncərəni kiçiltmə: Godot kiçildilmiş pəncərəni çəkmir və kadr çəkilmir.

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

## Render-də saxlamaq

Hər şey TƏK servisdir (`germ-arena`, pulsuz plan, Frankfurt):

| Yol | Nə verir |
|---|---|
| `/` | Brauzer build-i — nginx, `.wasm`/`.pck`/`.js` əvvəlcədən gzip-lənib |
| `/ws` | Oyun serveri — nginx → `127.0.0.1:27015` (Godot headless, WebSocket) |
| `/healthz` | Render-in sağlamlıq yoxlaması (oyun serveri adi HTTP-yə cavab vermir) |

**Niyə bir servis:** pulsuz planda hər servis ayrıca yatır. İki servis olsaydı,
oyunçu əvvəl saytın, sonra serverin oyanmasını gözləyərdi. Domen eyni olduğuna
görə brauzer build-inə ünvan yazmaq da lazım deyil.

| Fayl | Nədir |
|---|---|
| [`render.yaml`](render.yaml) | Servisin tərifi (Blueprint) |
| [`deploy/render/Dockerfile`](deploy/render/Dockerfile) | Oyunu MƏNBƏDƏN qurur: Godot 4.7.2-ni yükləyir, Web və Linux Server presetlərini ixrac edir |
| [`deploy/render/fetch_templates.py`](deploy/render/fetch_templates.py) | 1.28 GB-lıq şablon arxivindən HTTP Range ilə yalnız 2 faylı (~84 MB) çəkir |
| [`deploy/render/start.sh`](deploy/render/start.sh) | Serveri və nginx-i qaldırır; biri düşsə konteyner də düşür və Render onu yenidən başladır |
| [`deploy/render/nginx.conf.template`](deploy/render/nginx.conf.template) | Statik fayllar, `/ws` proksisi, wasm MIME tipi |

Repoda hazır binar saxlanmır — build hər dəfə mənbədən gedir (~2 dəqiqə).

### Yenidən deploy

`main`-ə push kifayətdir: Render avtomatik build edir. Yalnız `game/`,
`deploy/render/` və `.dockerignore` dəyişəndə — README-yə görə build getmir.

```bash
render login                                        # brauzerdə təsdiq
render services                                     # servis id-si (srv-...)
render logs --resources <srv-id> --tail             # server hər 5 s status yazır
render deploys create <srv-id> --wait               # əl ilə yenidən deploy
```

### Lokal sınaq — Render şərtləri ilə
```bash
docker build -f deploy/render/Dockerfile -t germ-arena .
docker run --rm --cpus=0.1 --memory=512m -p 10000:10000 germ-arena
# brauzer: http://127.0.0.1:10000 · server: ws://127.0.0.1:10000/ws
```
`--cpus=0.1 --memory=512m` pulsuz planın limitləridir.

### Pulsuz planın CPU-su (0.1)

Server 30 Hz-də işləyir, yəni 0.1 CPU ilə bir tick-ə ~3.3 ms CPU düşür.
Status sətri bunu birbaşa göstərir:

```
[lobby] 1 dünya · son 5 s-də 302 giriş paketi · tick orta 0.83 ms, maks 1.50 ms · atılan tick 0
```

**`atılan tick` sıfırdan böyükdürsə**, server real vaxtdan geri qalır və oyun
yavaşıyır — o zaman Starter plan (0.5 CPU) lazımdır.

Ölçü (2026-09-25, konteyner `--cpus=0.1 --memory=512m`, 2 oyunçu + botlar):

| | Tick orta / maks | Atılan tick | CPU | RAM |
|---|---:|---:|---:|---:|
| Optimallaşdırmadan əvvəl | — | ölçülüb: oyun 18–24 Hz-ə düşürdü | — | — |
| 1 dünya (SONSUZ ARENA) | 0.8–1.0 / 1.9 ms | 0 | ~5% | 79 MB |
| 2 dünya (+ TƏK QALAN) | 1.5 / 2.8 ms | 0 | ~5.6% | 79 MB |

Tick-in ən bahalı yeri qida döngüsü idi (qida × mikrob, tick-in ~45%-i).
Mikrob siyahısı döngüdən əvvəl bir dəfə yığılır, ucuz məsafə yoxlaması
statik çağırışlardan əvvəl gedir; nəticə **bit-bit eynidir** (8 ssenarinin
hər tick-dəki SHA-256 izi əvvəl/sonra üst-üstə düşür). Tick ~2.3x ucuzlaşıb.

---

## Serveri Railway-də saxlamaq (alternativ, qurulmayıb)

> Əsas host Render-dir (yuxarıya bax). Bu bölmə iki servisli köhnə sxemi
> alternativ kimi saxlayır — kök `Dockerfile` və `web/` ona aiddir.

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

### Şinlər

Üç şin var: `Master` → `SFX` və `UI`. Sürgülər yalnız şini çəkir, klipin öz
səviyyəsini yox — `AUDIO_BIBLE`-ın üçpilləli tarazlığı (səviyyə 3 səsləri
−6 dB ilə çalınır) olduğu kimi qalır.

`UI` ayrıdır, çünki menyu toxunuşu ilə oyunun səsi bir-birinin işi deyil:
oyunçu arenada effektləri qısıb düymə cavabını saxlaya bilər, ya da əksinə.
Şinlər `default_bus_layout.tres` faylı ilə yox, kodda qurulur —
[`Settings._ensure_buses`](game/scripts/shared/settings.gd).
