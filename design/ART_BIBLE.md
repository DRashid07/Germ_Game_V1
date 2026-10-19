# Germ Arena — Art Bible

**Üslub:** *Bioluminescent petri dish* — qaranlıq laboratoriya qabında öz-özünə
işıq saçan mikroblar. Heç bir metal, heç bir künc; hər şey yumşaq, yaş və canlıdır.

---

## 1. Palitra

Kodda tək mənbə: [`game/scripts/shared/palette.gd`](../game/scripts/shared/palette.gd).
Rəngi dəyişəndə həm oradakı sabit, həm bu sənəd yenilənməlidir.

### Qab (fon)

| Ad | Kod | İşlədilir |
|---|---|---|
| `BG_OUTER` | `#071012` | Qabın kənarından bayır — dünyanın sərhədi |
| `BG_VIGNETTE` | `#020708` | Qabdan uzaqdakı bayır vinyeti |
| `DISH` | `#12262C` | Qabın döşəməsi — qaranlıq orta ton |
| `DISH_EDGE` | `#2B5963` | Qalxmış şüşə dodağın gövdəsi |
| `GRID` | `#1A3942` | Döşəmə şəbəkəsi və 400 px-lik bevel işığı |
| `MUCUS` / `MUCUS_EDGE` | `#16333B` / `#245562` | Selik ləkələri (maneə) |
| `BUSH` / `BRITTLE` / `VENT` | `#3E9068` / `#D09345` / `#F0B94E` | Xəritə növlərinin ikinci rəng kanalı (kol V1 dəstinin rəngidir, §4c) |
| `RIM_LINE` | `#8FD3D6` | Şüşə divarın işıq xətti — cənub dodağı və parıltılar |
| `DRY_CRACK` / `STEAM` | `#81785C` / `#B9D8D0` | Quru çat və yalnız HIGH-da buxar |

Fon QƏSDƏN aşağı kontrastdır: ekranda 10 mikrob, 50 qida topu və uçan toplar var —
oxunaqlıq yalnız ön planın parlaq olması ilə qazanılır.

### Mikrob rəngləri (10 ədəd)

`7CFF5B` laym · `2FE8E0` firuzəyi · `FF5BC8` magenta · `FFB43D` kəhrəba ·
`A96BFF` bənövşəyi · `FF6B5B` mərcan · `4D9BFF` göy · `4BFFA5` nanə ·
`FF87A8` çəhrayı · `F2E14C` qızılı

Bir dünyada maksimum 10 mikrob var və hər birinə AYRI rəng düşür
([`World._free_color`](../game/scripts/server/world.gd)) — iki eyni rəngli mikrob
heç vaxt görünmür. Rənglər həm tondan, həm parlaqlıqdan fərqlənir ki, rəng
korluğunda da ayırd edilsin; forma dili isə rəngdən asılı deyil (bax §4).

### Vəziyyət rəngləri

| Ad | Kod | Mənası |
|---|---|---|
| `SAFE` | `#52E08A` | Doluluq 30–85% — sağlam |
| `WARNING` | `#FFB020` | Doluluq ≤30% — ac qalırsan |
| `DANGER` | `#FF4757` | Doluluq ≥85% — partlamağa yaxınsan |
| `FOOD` | `#D9FFC0` | Yerdəki sərbəst top |
| `FOCUS` | `#FFD166` | Xəritədə öz mikrobunun nöqtəsi |

Bu üç rəng oyunun bütün qaydasını izah edir: **sarı = az, yaşıl = yaxşı, qırmızı = çox**.

Rəng şkalası **yalnız HUD göstəricisindədir** — öz dəqiq sayın oradadır.
Mikrobun özündə rəqəm yoxdur: doluluq membranın gərginliyindən oxunur
(bax §2). Əvvəl hər mikrobun ətrafında dolan bir halqa da vardı və eyni
rəng şkalasını işlədirdi; çıxarıldı, çünki mikrobu konsentrik halqaların
içinə salırdı.

---

## 2. Üç mikrob növü

Dünyada **üç növ** var. Hamısı eyni gövdəni bölüşür; fərq yalnız
**hərəkət orqanındadır** — və hər üçü real protist anatomiyasından götürülüb.

| | **Kirpikli** (CILIATE) | **Ayaqlı** (HELIOZOAN) | **Amöb** (AMOEBA) |
|---|---|---|---|
| Model | paramesium | "günəş heyvancığı" | amöb |
| Hərəkət orqanı | **kirpiklər** + arxada **qamçı** | şüa kimi **aksopodiyalar** | orqan yoxdur — **kənarın özü** |
| Necə gedir | suda **üzür** | dibdə **yeriyir** | dibdə **sürünür** |
| Gövdə | yumşaq kisə — çox titrəyir, sürətdə dartılır | bərk, mineral skeletli — az titrəyir | yumrulanmış üçbucaq, iki qatlı, sabit forması yoxdur |
| Daxili maye | hərəkətdən **geri qalır** (ətalət) | öndəki ayağa **axır** | axının özü **hərəkətin mexanizmidir** |

Daxili axının istiqaməti hər üçündə fərqlidir: biri sürüklənir, biri özünü
çəkir, biri isə axaraq gedir. Ən incə, amma növləri ən güclü ayıran işarə budur.

> **Növ oyuna TƏSİR EDİR — amma güc fərqi kimi yox.** Hər növün mühitlə
> münasibəti başqadır və hər birinin öz **superi** var (bax §2b). Toxunulmaz
> qalan yalnız **döyüş riyaziyyatıdır**: atəş dövrü, topun qiyməti və tutum
> artımı üç növdə də eynidir. Bunu sənəd yox, `sim_test` saxlayır — "bir növü
> bir az güclü etmək" ən asan səhvdir və oyunçunu menyuda "hansı daha
> güclüdür" sualına məcbur edər.

### 2b. Növün özəlliyi və superi

Növ artıq yalnız görüntü deyil. Fikir bir cümlədədir: **hər növün mühitlə
münasibəti başqadır** — biri suda üzür (su onu həm daşıyır, həm aparır), biri
dibdə yeriyir (yerə yapışır), biri sürünür (divarlar onu saxlamır). Bu, həm də
üç orqanizmin əsl ekologiyasıdır.

**Passiv** — həmişə işləyir. Sabitlər: [`Const.SPECIES_THRUST`](../game/scripts/shared/constants.gd) və qonşuları.

| | Passiv | Qiyməti |
|---|---|---|
| **Kirpikli** | tez sürətlənir, buraxanda sürüşür (×1.35 / ×0.85) | axın və cərəyan deşiyi onu ×1.15 gücü ilə aparır |
| **Ayaqlı** | axına dirənir (×0.55) — deşiyin yanından keçən yeganə növ | ən yavaş (×0.95), qovmaqda da, qaçmaqda da sonuncu |
| **Amöb** | maneə radiusu ×0.78 — dar aralıqdan keçir | ağır qopur (×0.85); topa hədəf kimi ölçüsü **dəyişmir** |

Sonuncu sətir vacibdir: kiçilən radius **yalnız maneələr üçündür**. Topa dəymə,
kamera və membranın çəkilişi tam radiusla işləyir — bu, ərazi özəlliyidir,
döyüş özəlliyi yox.

**Super** — döyüşərək dolur, düymə ilə işə düşür (Brawl Stars quruluşu).
Doluluq: dəymə +3, qida +1/3 top, sənə dəyəndə +1, partlatma tam doldurur.
Hədd 15-dir — dörd bitə sığdığı üçün.

| | Super | Nə edir | Qiyməti |
|---|---|---|---|
| **Kirpikli** | **TRİXOSİST** | r×3.5 zolağındakı rəqib topları dağılıb **qidaya** çevrilir, mikroblar itələnir, özü geri sıçrayır | −2 top; dağılan toplar yerdə qalır və rəqib onları geri yeyə bilər |
| **Ayaqlı** | **AKSOPODİYA TORU** | 4 saniyə: r×4 zolağındakı qida ona axır, tora düşən rəqib 40% yavaşlayır | dolu ikən açsa **öz superi onu partladır** |
| **Amöb** | **MİNİQAN** | 2.5 saniyə yerində donub fasiləsiz atəş açır, toplar pulsuzdur, metabolizm dayanır | qalxan yoxdur, qaça bilmir |

Üçü də real biologiyadandır: paramesium yırtıcı toxunanda trixosistlərini
partladıb geri üzür (bu qabiliyyəti olmayan mutantlar 9–45 dəfə tez yeyilir);
heliozoanın aksopodiyalarındakı *kinetosistlər* yemi şüaya yapışdırır; amöb
şərait pisləşəndə sistləşib mübadiləsini dayandırır.

> **Heç bir super rəqibin TOP SAYINA toxunmur.** Bu oyunda "zərər" yoxdur —
> top var, və o həm sursat, həm candır. Zərər verən super `SHOT_PAYLOAD`
> riyaziyyatını yan yoldan pozardı, ona görə üçü də **mövqe, qida və vaxt**
> üzərində işləyir.

**Çəkiliş.** Sist gövdənin öz konturunu təkrarlamır: üstünə düzgün, sərt bir
halqa oturur və rəng tündləşir — oyunçu bir baxışda "bura top girmir"
deməlidir, forma oxumağa vaxt sərf etməməlidir. Tor isə öz **sərhədini** çəkir:
görünməyən sahə ədalətsiz olardı, rəqib hara girməli olmadığını görməlidir.

**Düymə** [`SuperButton`](../game/scripts/client/super_button.gd)-dadır: atəş
düyməsinin üstündə, ondan kiçik. Atəş saniyədə basılır, super 20–30 saniyədən
bir — böyük və əlaltı olan tez-tez basılan olmalıdır. Üç vəziyyət göstərir:
sönük halqa, dolan qövs, yanıb-sönən dolu halqa (oyunçunun öz rəngində).

### Növü oyunçu seçir

Menyuda üç **kart** yan-yanadır və hər birində növün silueti var; seçim
`settings.cfg`-də saxlanılır və dünyaya girərkən bir dəfə serverə göndərilir.
Kartın altında superin adı yazılır — seçim məna daşıdığına görə oyunçu nə
seçdiyini bilməlidir. Botların növü
təsadüfidir, ona görə dünyada hər üçü görünür.

Seçim şəbəkəyə **bir bayt da** əlavə etmir. Səbəb: növ ayrıca sahə kimi yox,
toxunulmazlıq bayrağının **boş bitinə** yerləşdirilib.

| Bit | Məna |
|---|---|
| 0 | doğuş qalxanı aktivdir |
| 1–2 | növün nömrəsi (0..3) |
| 3–6 | superin doluluğu (0..15) |
| 7 | super indi işləyir |

Həmin sahə əvvəl yalnız 0/1 daşıyırdı, yəni qalan bitləri boş yatırdı. Sətir
hər mikrob üçün saniyədə 30 dəfə gedir və Variant massivində hər ədəd 9 bayt
tutur — ayrıca sahə açmaq real qiymətdir, boş bit isə pulsuzdur.

Növə **iki** bit ayrılıb, biri yox: üçüncü növ (amöb) əlavə olunanda bir bit
çatmadı. İki bit dördüncü növə də yer saxlayır.

> **Növ görüntü qatının öz işi ola bilməz.** Əvvəlki versiyada rəngdən
> çıxarılırdı (`color % 2`) və heç nə göndərilmirdi. Oyunçu seçim edə
> bilmirdi — məhz ona görə [Sim]-ə köçürüldü: seçim oyunçunundur, deməli
> bütün client-lərə eyni çatmalıdır.

Client-in göndərdiyi dəyər, serverin qaytardığı dəyər və diskdən oxunan ayar —
üçü də etibarsız ola bilər, ona görə hamısı bir funksiyadan keçir
([`Const.species_from`](../game/scripts/shared/constants.gd)): tanınmayan hər
şey kirpikliyə düşür.

### Niyə sprite deyil

Mikrobun **ölçüsü tutumdan**, **içindəki topların sayı isə mövcud saydan** asılıdır.
İkisi də oyun boyu dəyişir (tutum 10 → 60, top sayı 0 → 60), ona görə hazır şəkil
uyğun gəlmir. Mikrob tamamilə kodla çəkilir:
[`game/scripts/client/germ_visual.gd`](../game/scripts/client/germ_visual.gd).

Ayaqlı növ üçün ikinci bir səbəb var: **addımın tezliyi heç bir yerdə
yazılmayıb** — o, mikrobun həqiqi sürətindən özü çıxır (bax §3). Hazır kadr
ardıcıllığı bunu edə bilməzdi.

Ümumi quruluş (içəridən çölə):

1. **Daxili kölgə** — sitoplazmanın dərin qatı. Toplar bunun üstündə oturur,
   ona görə mikrob yastı disk yox, həcmli kisə kimi oxunur. Hərəkətdə
   bədəndən GERİ QALIR: dönəndə içindəki maye sonra çatır.
   *Parlaq nüvəcik qəsdən yoxdur* — mərkəzdəki ikinci işıqlı nöqtə topla
   qarışırdı, top sayı isə oyunun əsas göstəricisidir.
2. **Toplar (orqanellalar)** — "günəbaxan" (phyllotaxis) düzümü: qızıl bucaq
   `2.39996` rad. Say dəyişəndə düzüm sıçramır, sadəcə bir top artır.
3. **Membran** — 24 nöqtəli çoxbucaqlı, radiusu iki fərqli tezlikli sinusla
   modullaşdırılır. Doluluq artdıqca titrəmə həm güclənir, həm sürətlənir:
   *gərginlik* budur. Üstəlik sürətə görə **dartılır**: getdiyi ox boyunca
   16%-ə qədər uzanır, ona dik istiqamətdə isə eyni əmsalla yastılaşır
   (həcm qorunur — maye içindəki cismin forması belədir).
4. **Nişan çıxıntısı** — mikrobun hansı tərəfə atacağını göstərir. **Siluetin
   ÖZ qabarığıdır**, kənarda ayrıca düymə deyil: əvvəl kirpikli və ayaqlıda
   membrandan bir az kənarda parlaq bir dairə çəkilirdi və o, "atılmış top
   gövdənin kənarında ilişib" kimi oxunurdu (amöbdə eyni səbəbdən artıq
   çıxarılmışdı). Yalnız **yumşaq** gövdələrdə var — kirpikli və amöb;
   **ayaqlıda yoxdur**, çünki mineral skelet uzana bilməz. Orada istiqaməti
   yalnız atəş anındakı dartılma göstərir.
5. **Kirpiklər (cilia)** — YALNIZ kirpiklidə. Perimetr boyu döyünən tüklər.
   **Metaxronal dalğa** ilə hərəkət edir: qonşu kirpiyin fazası bir az geridədir,
   ona görə halqa boyunca dalğa qaçır. Hamısı eyni anda döysəydi nəticə
   *titrəyiş* kimi oxunardı, *üzmə* kimi yox. Dalğa getdiyi istiqamətin əksinə
   qaçır — mikrob suyu geri itələyir.
6. **Qamçı (flagellum)** — YALNIZ kirpiklidə. Arxada qamçılanan quyruq;
   uzunluğu boyunca sinus dalğası qaçır və uca doğru həm nazilir, həm daha
   çox yellənir.
   **Aksopodiyalar** — YALNIZ ayaqlıda; onların yeri §3-dədir.
7. **Doğuş qalxanı** — **25 px** kənarda fırlanan kəsik halqa. Mikrobun
   ətrafındakı YEGANƏ halqadır və yalnız ilk saniyələrdə görünür.

> **İki halqa vardı, ikisi də çıxarıldı.** Biri doluluq halqası idi
> (membranın 13 px kənarında dolan qövs), biri fokus halqası ("bu, sənsən").
> İkisi də rəqəmi düzgün göstərirdi, amma mikrobu konsentrik halqaların içinə
> salırdı — kirpiklər, ayaqlar və qamçı onlarla yarışırdı.
>
> Hər ikisinin işini onsuz da mövcud olan bir şey görür:
>
> | Nə lazımdır | Kim göstərir |
> |---|---|
> | Nə qədər doluyam | Membranın öz gərginliyi; dəqiq rəqəm HUD-dadır |
> | Rəqib partlamağa yaxındırmı | Onun membranı bərk titrəyir və qırmızıya çalır |
> | Hansı mikrob mənəm | Kamera — öz mikrobun HƏMİŞƏ ekranın mərkəzindədir; adı da parlaq yazılır |
>
> Prinsip: **canlının özü göstərici olsun, üstünə taxılmış cihaz yox.**

> **Halqalar niyə məhz bu məsafələrdədir.** Kirpiklərin uzunluğu ≈ r × 0.20
> (ən çoxu 10 px). İlk versiyada halqa 5 px-də idi və kirpiklərin düz
> ortasından keçirdi — ikisi də oxunmaz olurdu. Halqa kirpiklərin
> uzunluğundan KƏNARDA olmalıdır.

> **Çəkiliş sırası vacibdir.** Əvvəlcə bütün DOLU formalar, sonra bütün XƏTLƏR.
> Qarışsa, hər mikrob 15-20 ayrıca çəkiliş çağırışı olur — mobil GPU-da əsas
> məhdudiyyət məhz çağırış sayıdır.

### Siluet, işıq və squash & stretch kontraktı

Gövdə üç növdə də **tam tutqundur**. Kirpikli və ayaqlı əvvəl `0.30` alfa ilə
çəkilirdi; döşəmə gövdənin içindən göründüyünə görə rəng parlaq olsa da siluet
itirirdi. İndi xarici kontur həqiqi membranı — atəş qabarması və amöb ləçəkləri
daxil — izləyir: eni `clamp(r × 0.10, 2.4, 6.0)`, rəngi `OUTLINE`, alfa `0.95`.

İşıq bütün kodla çəkilən həcmlərdə `Palette.LIGHT_DIR = (-0.45, -0.89)`-dur.
Gövdənin tünd tonu `base → OUTLINE 30%`, açıq tonu `base → ağ 28%`-dir. Açıq
çoxbucaqlı `r × 0.10` içəri çəkilib işığa `r × 0.14` sürüşür; beləliklə ayrıca
shader olmadan yuxarı-solda işıq bandı qalır. Aşağı-sağ rim həqiqi siluetin
qövsünü izləyir: en `r × 0.06`, alfa `0.55`. Amöbin plazmagel və plazmazol
qatları eyni iki-ton hesabını ayrı-ayrılıqda alır; iki material buna görə itməz.

Kontakt kölgəsi gövdə siluetinin ellipsidir: `y × 0.62`, istiqamət
`-LIGHT_DIR × r × 0.22`. Yumşaq qat `×1.15 / alfa 0.18`, sıx qat
`×1.00 / alfa 0.45`-dir. Kölgə squash & stretch almır — node miqyası işlədilsə
ad, kirpik və kölgə də uzanardı.

| Hadisə | Membran reaksiyası | Müddət |
|---|---|---|
| Sürətlənmə | sabit `0.16` dartılmaya `+0.10`, cəm ən çox `0.26` | `0.18 s`, ease-out |
| Zərbə | gələn ox üzrə `0.88`, ona dik `1.14` | `0.14 s`, elastic-out |
| Atəş | nişan oxunda `0.94 / 1.06`, əksə `r × 0.06` geri təpmə | `0.12 s`, ease-out |
| Doğuş | `0 → 1.12 → 1.0`, yerdə ellips halqa | `0.35 s`, back-out |
| Boşdayanma | radius `1 + 0.018·sin(2.1t)`, yellənmə `±1.5°` | fasiləsiz, yalnız `rush < 0.05` |

Keçici dartılma ilə sabit dartılmanın cəmi `0.26`-nı keçmir və istiqamətli
hadisə `0.2 s`-dən uzun yaşamır. Topun membranı yerli yarmasının follow-through-u
da əvvəlki `0.30 s`-dən `0.18 s`-ə endirilib; bu, squash deyil, yalnız dar çıxış
nöqtəsinin sönən dalğasıdır.

Növ fərqi xırda miqyasda ayrıca materialla oxunur: kirpik dibi `max(r × 0.040,
1.15 px)`, ucu onun `15%`-i olan konusvari lentdir; ayaq əvvəl tünd
`max(r × 0.14, 5.4 px)`, sonra parlaq `max(r × 0.065, 2.4 px)` keçiddir və basılı
ucda tünd pəncə ləkəsi var; amöbin dar arxa uroid qabarması `0.16`-dır.

Gərginlik `0.75`-ə çatanda kontur `DANGER`-ə doğru `6 Hz` nəbz vurur, rəng
indeksindən çıxan `3–5` isti çat görünür və membran sürətdən asılı olmadan
`±r × 0.015` titrəyir. Əvvəlki yalnız rəngə çalan titrəyiş dayanan rəqibi
uzaqdan təhlükəsiz göstərirdi.

---

## 3. Yeriş — ayaqlar necə işləyir

Aksopodiyalar animasiya DEYİL, həndəsədir. Model bir cümlədədir:

> Pəncənin dünya koordinatındakı yeri saxlanılır və gövdə ondan uzaqlaşana
> qədər pəncə **tərpənmir**.

Bütün "yeriyir" hissi bundan ibarətdir. Pəncə yerli koordinatda saxlansaydı
gövdə ilə birlikdə sürüşərdi və nəticə yeriş yox, titrəyiş olardı.

Gövdə uzaqlıq həddini keçəndə ayaq **yığılır** (aksopod qısalır), irəli atılır
və yenidən basılır — heliozoa məhz belə hərəkət edir: *aksopodların uzunluğunun
idarə olunan dəyişməsi ilə*. Yana əyilmə yoxdur; üstdən baxışda uzunluq
dəyişməsi "sürünmə" yox, "addım" kimi oxunur.

Nəticə: **addımın tezliyi heç bir yerdə yazılmayıb.** Dayanan mikrob sadəcə
ayaqları üstündə durur; axının sürüklədiyi mikrob addımlamağa başlayır; sürətli
mikrob tez-tez addımlayır. Sabit sürətli animasiyada isə yavaş gedən mikrobun
ayaqları yerdə sürüşərdi (animasiyada "foot sliding" deyilən nasazlıq).

### Üç qayda ki, olmasa yeriş dağılır

**1. Ayaqların çoxu hər an yerdə olmalıdır.** Əks halda hərəkət yeriş yox,
sıçrayışdır. Bu, ümid deyil — `lift_budget()` eyni anda havada ola bilən
ayaqların sayını məhdudlaşdırır (sayın yarısından bir az az).

**2. Növbə ən GECİKMİŞ ayağa verilir.** İndeks sırası ilə verilsəydi birinci
ayaq həmişə qabağa keçər, sonuncu isə gözləyə-gözləyə həddindən artıq dartılardı.

**3. Ayaq ƏBƏDİ yerində qala bilməz.** Yalnız məsafəyə baxsaq, yavaş gedən və
ya dayanan mikrobun ayaqları heç vaxt addımlamır — nəticə gövdəyə yapışmış
donmuş ulduzdur. Real aksopod fasiləsiz yenidən qurulur, ona görə bir ayaq
ən çoxu `LEG_HOLD_MAX` (1.1 s) yerində qalır, sonra növbəyə düşür. Dayanan
mikrobda ayaq demək olar eyni nöqtəyə qayıdır; görünən dəyişiklik qalxma
anındadır — aksopod yığılıb yenidən uzanır.

> **Ayaqların uzunluğu qonşuya çatmamalıdır.** 2.15 r sınandı və atıldı:
> mikroblar bir-birindən yalnız radiusları qədər aralanır, ona görə o
> uzunluqda ayaqlar qonşu mikrobun üstünə uzanır və "başqasına ilişmiş"
> kimi görünür. 1.75 r həm gövdədən aydın kənardadır, həm qonşuya çatmır.

Hər iki qayda [`SimTest._test_heliozoan_gait`](../game/scripts/tools/sim_test.gd)
ilə qorunur. Test təsadüfi deyil: **birinci qaydanın pozulmasını ekran görüntüsü
tapa bilmir** — mikrob yerindən tərpənəndə bütün ayaqların bir anda qalxması bir
kadrlıq hadisədir. Səhv məhz testlə tapıldı.

---

## 3b. Sürünmə — amöb necə gedir

Amöbin sabit forması yoxdur: **kənarın özü hərəkət orqanıdır**. Ona görə forma
dairənin bəzədilməsi kimi yox, sürünmə dövrünün nəticəsi kimi qurulur.

> **Ən bahalı dərs: polar düsturla sürünmə ALINMIR.**
>
> Digər iki növ dairədən başlayır və üstünə titrəyiş əlavə edir:
> `nöqtə = mərkəz + istiqamət(a) × radius(a)`. Amöb də uzun müddət belə
> qurulmuşdu və nə qədər tənzimlənsə də sürünmürdü — çünki o düsturda **mərkəz
> sabitdir**, sürünmə isə kütlə mərkəzinin yerdəyişməsidir. Radiusu nə qədər
> dəyişsən, nəticə yerində nəfəs alan ləkə olur; amplitudanı artırmaq da kömək
> etmir, sadəcə daha güclü nəfəs alır. Üstəlik polar düsturda bir bucağa bir
> radius düşür, yəni **boynu olan çıxıntı** — psevdopodiyanın tərifi — ifadə
> oluna bilmir.

Ona görə gövdə üç **diskin birləşməsidir**: ön psevdopodiya, orta kütlə, arxa
uropod. Kontur hər bucaq üçün şüanın disklərdən ən uzaq çıxış nöqtəsidir.
Sürünmə kənarın bəzədilməsi deyil, disklərin öz hərəkətidir — sitoplazmanın iki
halı (axıcı **plazmazol**, jel halında **plazmagel**) elə bu hərəkətdir:

1. ön disk irəli atılır — **protruziya**, dövrün ~3-də biri, tez;
2. sitoplazma ona axır: ön disk dolur, arxa boşalır;
3. arxa uc yığılıb gövdəyə qovuşur — **retraksiya**, yavaş.

### Dövrün saatı — vaxt yox, MƏSAFƏ

> **İkinci bahalı dərs.** Disk modeli formanı düzəltdi, hərəkət isə hələ də
> sürüşmə kimi oxunurdu. Səbəb formada deyil, **ritmdə** idi: dövr vaxtla
> sürülürdü (saniyədə ~1), mikrob isə saniyədə **3.4 gövdə uzunluğu** qət edir
> (190 px/san ÷ 56 px). Yəni bir "addımda" gövdə 3.4 boy sürüşürdü —
> deformasiya yerdəyişmə ilə sinxron deyildi.
>
> Animasiyada bunun adı var: *foot sliding*. Ayaqlı növdə həmin nasazlıq
> əvvəldən həndəsə ilə həll olunmuşdu — amöbdə isə diqqətdən qaçmışdı.

Ona görə sürünmənin saatı da pəncə ilə eyni prinsipdədir: **uropod valideyn
fəzasında yerə basılır**, gövdə ondan `CRAWL_RELEASE = 2.3` radius uzaqlaşanda
buraxılır və gövdənin dibinə yenidən basılır. Dövrün yeganə hadisəsi budur;
psevdopodiyanın uzanması, sitoplazmanın axını və gövdənin nazilməsi — hamısı
həmin dartılmadan çıxır. Nəticədə **sürünmənin tezliyi heç bir yerdə
yazılmayıb**: sürətlə gedən tez, yavaş gedən yavaş sürünür, dayanan isə
ümumiyyətlə sürünmür.

Uzanma bütün dövrə yayılır (`CRAWL_PUSH = 3`), yığılma isə bir anda olur
(`CRAWL_PULL = 11`). Gözlə görünən "atılma" məhz bu asimmetriyadır — bərabər
olsaydı dövr sinusa çevrilərdi, sinus isə həmişə nəfəs alma kimi oxunur.

Sahə qorunur: disklər ayrılanda gövdə uzanır, ona görə radiusları
`CRAWL_SLIM = 0.25` nisbətində kiçilir — uzanan hüceyrə nazilir.

> [`SimTest._test_amoeba_crawl`](../game/scripts/tools/sim_test.gd) mikrobu düz
> xətt üzrə sürür və **ekranda görünən gövdəni** ölçür: sahə 10%-dən çox
> dəyişməməlidir (hazırda 7.1%); forma istiqamətli olmalıdır; və **gövdənin bir
> kadrdakı irəliləyişi qeyri-bərabər olmalıdır** — ən tez kadr ən yavaşdan ən
> azı 1.8 dəfə uzun (hazırda **3.7 dəfə**: 3.84 / 1.03 px).
>
> Sonuncu ölçü hər şeyi həll etdi. Ondan əvvəlki yoxlamalar formanı ölçürdü,
> forma isə düzgün ola-ola hərəkət səhv qala bilir. Bərabər irəliləyiş =
> sürüşmə, qeyri-bərabər irəliləyiş = sürünmə. **Ölçülməli olan şey deformasiya
> deyil, hərəkətin ritmidir.**

### Üçüncü dərs: "botlarda işləyir, oyunçuda yox"

Bu cümlə səhvin yerini dəqiq göstərdi. Bot və oyunçu eyni kodu icra edir —
fərq yeganə şeydədir: **botlar kiçik qalır, oyunçu böyüyür.** Tutum 60-da:

| | Bot (tutum 10) | Oyunçu (tutum 60) |
|---|---|---|
| Radius | 28 px | 85.5 px |
| Öz tavan sürəti | 190 px/san | 115 px/san |
| `rush` | 1.00 | **0.61** |
| Sürünmə tezliyi | 3.4 Hz | **0.67 Hz** |

İki ayrı qüsur üst-üstə düşürdü:

1. `rush` **mütləq** ölçüyə (`BASE_SPEED`) bölünürdü. Sona qədər sürən böyük
   mikrob 0.61 "səy" göstərirdi, yəni bütün sürətə bağlı animasiya sönürdü.
   Düzgün ölçü mikrobun **öz** tavan sürətidir (`Const.germ_speed`).
2. Addımın uzunluğu birbaşa radiusa bağlı idi. Radius 3 dəfə artır, sürət 1.7
   dəfə azalır — tezlik 5 dəfə çökür. İndi saat **rəqqas qanunu** ilə
   miqyaslanır (`√(r · BASE_RADIUS)`), tezlik 2.9 dəfə düşür.

> **Qayda:** sürətə bağlı hər əmsal mikrobun ÖZ tavan sürətinə bölünməlidir.
> `BASE_SPEED` yalnız mütləq həddlər üçündür (məsələn teleport aşkarlaması).
> Testlər ona görə həm ən kiçik, həm ən böyük tutumda işləyir — oyunçunun ən
> çox vaxt keçirdiyi hal ikincisidir.

### Eyni səhv AYAQLI növdə də vardı

"Botlarda gedir, oyunçuda ayaqlar donur" — eyni cümlə, eyni kök. Tutum 60-da
hər ayaq vaxtının **91%-ni yerdə** keçirirdi və qalan 9%-də 73 pikseli bir göz
qırpımında qət edirdi: ekranda donmuş ulduz, arada bir çırpınma.

Səbəb: addımın uzunluğu radiusla böyüyürdü, yellənmənin müddəti isə sabit
`12 / saniyə` idi. İkisi bir yerdə yük dövrünü (duty cycle) ölçüdən asılı
edirdi. İndi hər ikisi tempə bağlıdır — `LEG_SWING_PACE` yellənməni gedilən
məsafə ilə ölçür, addımın uzunluğu isə rəqqas qanunu ilə miqyaslanır:

| | Kiçik | Böyük |
|---|---|---|
| Əvvəl (havada keçən vaxt) | 41% | **9%** |
| İndi | 26% | **24%** |

> **Ölçünün özü də dəyişdi.** Əvvəl "ən azı bir ayaq havadadır" ölçülürdü və o,
> aldadıcıdır: 13 ayaqda həmişə yüksək çıxır, hər ayaq isə ayrılıqda donmuş
> görünə bilər. Doğru ölçü BİR ayağın yük dövrüdür.

## 3c. Top gövdədən necə çıxır

Top mikrobun **içindən** doğulur (`Sim._fire`) və atəş qatı mikroblardan
əvvəlki qatda çəkildiyinə görə gövdənin altında qalır — membrandan keçəndə üzə
çıxır. Bura yeni deyil; çatışmayan şey **çıxışın zorakılığı** idi.

İndi gövdə topun çıxdığı nöqtədə bayıra dartılır: dar bir çıxıntı (`cos` üstlüyü
12) radiusun ~34%-i qədər qabarır, pərdə yarılanda isə buraxılıb bir dəfə içəri
çırpılır. Effekt hazır konturun **üzərində** işləyir, ona görə hər üç növ üçün
eynidir — kirpiklinin membranı da, amöbin iki qatı da eyni cür qabarır.

Qabarma dar olmalıdır. Geniş olsa mikrob bütövlükdə şişər və oxunuş
"zorlayaraq çıxarır"dan "nəfəs alır"a çevrilər. `SimTest._test_eject_strain`
məhz bunu qoruyur: çıxış istiqamətində ən azı 18% qabarma, yan tərəfdə isə
3%-dən az dəyişmə (hazırda **34% / 0.0%**).

Səs `AUDIO_BIBLE`-dədir: `eject` təzyiq, `blunk` isə yarılma anıdır.

### Dördüncü dərs: RİTM düzgün ola-ola SİLUET səhv qala bilər

Disklərin hərəkəti, məsafə ilə sürülən saat, asimmetrik addım — hamısı doğru
idi və testlər keçirdi. Oyunda isə gövdə hələ də **yumru ləkə** kimi görünürdü.

Səbəb ölçüdə idi: ən çox uzananda gövdə eninə görə cəmi **1.6 dəfə** uzun idi.
Bu, armuddur, sürünən hüceyrə deyil. Diskləri daha uzağa atmaq həll deyildi —
gövdə toqquşma dairəsindən qoparddı. Həll animasiyanın öz prinsipidir:
**squash & stretch** (`CRAWL_STRETCH`) — gövdə ox boyunca dartılır, ona dik
istiqamətdə eyni əmsalla yastılaşır. Sahə qorunur, mərkəz yerində qalır,
nisbət isə **2.2–2.3**-ə qalxır.

> **Bunu tapmaq üçün ölçünü DƏYİŞMƏK lazım gəldi.** Əvvəlki testlər ritmi
> ölçürdü (kadr başına irəliləyiş) və ritm doğru idi. Siluet ölçülmürdü, ona
> görə səhv görünmürdü. İndi `SimTest._check_crawl` hər ikisini ölçür:
> uzananda en/boy > 1.9, yığılanda < 1.35.

> **Prosesə dair dərs (ən bahalısı).** Forma üzərində işləyərkən görüntü stendi
> 3.4 dəfə böyüdür — orada hər şey oxunaqlı görünür. Oyunda isə mikrob ekran
> eninin ~9%-ni tutur. Dörd dəfə "düzəldi" deyildi, çünki qərar HƏMİŞƏ
> böyüdülmüş stenddə verilmişdi. **Son qərar həmişə `--practice` kadrında,
> həqiqi miqyasda verilməlidir**; stend yalnız detala baxmaq üçündür.

### Beşinci dərs: kamera öz mikrobunu MİSMARLAYIR

"Botlarda düzgündür, mənimki ilişib qalır." Bu cümlə ən dərin səhvi açdı.

Rəqiblər ekranda hərəkət edir, ona görə gövdənin kütlə mərkəzinin salınması
onların yerdəyişməsinə qarışır və **sürünmə** kimi oxunur. Öz mikrobun isə
kameranın tam mərkəzindədir — ekranda **heç bir yerdəyişməsi yoxdur**. Deməli
görünən yeganə hərəkət salınmanın özüdür.

Ölçüldükdə mərkəz radiusun **60%-i** qədər (böyük mikrobda 49 px) irəli-geri
sürüşürdü. Nəticə: mikrob irəli getmir, yerində ora-bura sürüşür.

> **Ən pisi:** testlərdən biri məhz bu salınmanı **mükafatlandırırdı**
> ("irəliləyiş qeyri-bərabər olmalıdır"). Yəni hər "düzəliş" salınmanı
> artırırdı və oyunçunun mikrobu getdikcə daha çox ilişirdi. Test silinib —
> hədəfin özü səhv idi.

İndi kök `CRAWL_ANCHOR` ilə node-a bağlanır: **salınma 60% → 13%**. Forma
sərbəst qalır (en/boy nisbəti 2.30), sürünmə isə gövdənin **uclarının**
hərəkəti ilə oxunur. Personaj animasiyasının qaydası budur: kamera izləyəndə
kök sakit, uclar işlək olmalıdır.

| Ölçü | Əvvəl | İndi |
|---|---|---|
| Kütlə mərkəzinin salınması | 60% r | **13% r** |
| Siluetin en/boy nisbəti (uzananda) | 1.60 | **2.30** |
| Sahənin dəyişməsi | 6.2% | 6.2% |

### Sahə artıq TƏXMİN edilmir, dəqiq oturdulur

Əvvəl sahə disklərin radiuslarını əl ilə kiçiltməklə (`CRAWL_SLIM`) təxmin
edilirdi. Nəticə: siluetə toxunan hər addım sahəni pozurdu — konus cəhdi məhz
buna görə geri qaytarılmışdı (6% → 29%).

İndi çoxbucaqlı öz mərkəzi ətrafında bir dəfə miqyaslanır və hədəf sahəyə
**dəqiq** oturur (`CRAWL_AREA`). Ölçü: **6.2% → 0.0%**. Bu, disklərin
ölçülərini sərbəst buraxır: hüceyrə həcmini saxlayır, siluet isə istənilən
ola bilər.

### Konus: enli baş, nazik quyruq

Həqiqi amöbin ön ucu enli (lamellipodium), arxa ucu nazikdir (uropod).
Uzun müddət bizim gövdədə ön və arxa en demək olar bərabər idi (18 / 17 px).
İndi nisbət **1.39-1.42**-dir, ən enli kəsik isə mərkəzdən **6-8% öndədir**.

Bura gedən yol üç səhv cəhddən keçir və hər üçü məntiqli görünür — ona görə
yazılıb:

| Cəhd | Nəticə | Səbəb |
|---|---|---|
| Disk radiusları (0.86/0.86 → 0.98/0.66) | −6% → −5%, **heç** | gövdə tək mərkəzdən şüalarla qurulur: en `rays[a]·sin a`-dır və maksimumunu həmişə mərkəzin yanında alır. Disklər yalnız UZUNLUĞA təsir edir |
| Orta diski önə sürmək (45%-ə qədər) | −6% → −1% | eyni səbəb |
| Şüaya `cos` əlavə etmək | 1.06 → 1.07, gücləndirəndə **pisləşdi** | `cos` maksimumunu burun ucunda alır, yəni burnu UZADIR; uzanan burun gövdəni daha da nazik göstərir |

**İşləyən: `cos·sin²`** ([`GermVisual.CRAWL_CONE`](../game/scripts/client/germ_visual.gd)).
Maksimumu `a` ≈ ±55°-dədir — yəni ön YANLARDA. Ön yanlar şişir, arxa yanlar
yığılır, burun və quyruq UCLARI isə toxunulmaz qalır (ikisində də `sin`
sıfırdır). Konusun tərifi elə budur: **en profili dəyişir, uzunluq yox.**

Yuxarı hədd 0.65-dir: orada ön yanlar o qədər şişir ki, gövdə artıq uzana
bilmir (en/boy 1.86) və sürünmə oxunmur. 0.45 seçilib.

Konus **yalnız hərəkətdə** var. Dayanan amöbin qütbü yoxdur — real hüceyrə də
dayananda polyarlığını itirir; həm də kamera öz mikrobunu mərkəzə mismarladığı
üçün dayanan qeyri-simmetrik gövdə "yana yatıb" kimi oxunur.

> Bunu mümkün edən şey sahənin dəqiq normallaşdırılmasıdır. Ondan əvvəl
> siluetə toxunan hər cəhd sahənin qorunmasını pozurdu (6% → 29%) və geri
> qaytarılırdı. Maneə aradan qalxandan sonra isə cəhd yenilənmədi —
> boşluğun yeganə qeydi test çıxışındakı bir `[qeyd]` sətri idi, uğursuzluq
> deyil, ona görə "108 keçdi, 0 uğursuz" yazısı onu tamamilə örtürdü. İndi
> onun yerində dörd əsl yoxlama var.

### Ölçü səhv olanda forma günahsızdır

Konus üzərində işləyərkən ölçü **üç dəfə** yanlış nəticə verdi və hər dəfə
"forma dəyişmir" dedi, halbuki forma dəyişirdi:

1. **Zolağın ən enli yeri.** `max |y|` həmişə zolağın MƏRKƏZƏ ƏN YAXIN
   kənarına düşür, ona görə ön və arxa ölçü hər ikisi gövdənin ortasını
   göstərirdi.
2. **Ümumi uzunluğun sabit faizində en.** Burun uzananda `half` böyüyür və
   nümunə nöqtəsi burnun daralan yerinə sürüşür — konus GÜCLƏNDİKCƏ rəqəm
   PİSLƏŞİRDİ.
3. **Hər tərəfi öz uzunluğuna görə normallaşdırmaq.** Bu, ölçülmək istənən
   asimmetriyanın özünü silirdi.

Düzgün ölçü: şaquli xətti kəsən kənarları tapıb kəsişməni interpolyasiya
etmək, ön və arxanı isə EYNİ MÜTLƏQ məsafədə müqayisə etmək.

Dərs bundan ibarətdir: **rəqəm "dəyişmədi" deyəndə əvvəlcə rəqəmə şübhə et.**
Bu formanın bir illik "alınmır" tarixçəsinin bir hissəsi elə buradan gəlir.

### Altıncı dərs: problem ANİMASİYADA deyildi

"Ayaqlarda da ilişir." Bu cümlə həlledici oldu: ayaqlar və sürünmə tamam ayrı
kodlardır, ortaq nöqtələri yalnız **öz mikrobunun mövqeyidir**. Ölçüldükdə:

```
60 kadr çəkildi, öz mövqeyim yalnız 30 dəfə dəyişdi
```

Proqnoz server tick-i ilə addımlayır (`TICK_RATE = 30`), ekran isə 60 kadr
çəkir. Kamera da həmin mövqeyə bağlıdır, ona görə nəticə yalnız mikrobun yox,
**bütün dünyanın 30 Hz-lə pilləli sürüşməsi** idi. Rəqiblər bundan əziyyət
çəkmirdi: onlar hər kadrda snapshot-lar arasında interpolyasiya olunur.

> Yəni "botlarda düzgündür, mənimki ilişir" şikayətinin əsl səbəbi animasiya
> deyil, **kadr sürəti uyğunsuzluğu** idi. Neçə raund forma və ritm
> tənzimləndi, halbuki heç biri kömək edə bilməzdi.

Həll: `Arena` tick-dən əvvəlki və sonrakı vəziyyəti saxlayır, çəkiliş isə
aradakı nisbətə görə qarışdırılır (`_shown_pos`). Simulyasiya toxunulmaz qalır.
Ölçü: **60 kadr → çəkilən mövqe 60 dəfə dəyişir.**

Düzəliş yalnız HƏQİQİ mispredikt olanda sıçrayır (divar, geri təpmə): hər
snapshot-da sıçratsaydıq, titrəmə geri qayıdardı.

### Geri sıçrayış qadağandır

Fazaları düzəldəndə ölçülən bir qüsur da tapıldı: buraxılış anında gövdə bir
kadrda **geri** sıçrayırdı (böyük mikrobda −5.6 px). Səbəb ön və arxa ucun eyni
fazada olması idi. İndi psevdopodiya addımın **əvvəlində** atılır və gövdə ona
axdıqca yerli koordinatda kiçilir — yəni ucu dünyada yerində qalır. Buraxılışda
hər iki uc önə gedir.

`SimTest._check_crawl` bunu ayrıca yoxlayır: **ən yavaş kadr da müsbət
olmalıdır.** Sürünən heç bir şey geri sıçramır.

Dövrün öz saatı var və o, **məsafə ilə** sürülür: mikrob sürətlə gedəndə dövr
sürətlə, yavaş gedəndə yavaş dönür, dayananda isə tam donmur (sitoplazma axmaqda
davam edir). Ayaqlı növdə eyni prinsip həndəsə ilə alınır — heç bir növdə addım
və ya dövr tezliyi sabit yazılmayıb.

### Nə görünür

| Qat | Nə ilə çəkilir |
|---|---|
| Kontur | qalın tünd xətt — həm bayırda, həm iki qatın arasında |
| Jel zolağı (plazmagel) | oyunçu rənginin **açıq** variantı, hər yerdə **eyni enlidə** |
| Axıcı iç (plazmazol) | oyunçu rənginin **tünd** variantı |
| Orqanellalar | sivri uclu ulduzlar, iki tonda növbələşir, tünd konturlu |

Zolaq radiusa vurmaqla yox, hər nöqtəni **öz normalı boyunca** çəkməklə alınır
(`GermVisual._inset`). Sadəcə `r × 0.78` deyiləndə zolaq ön ucda qalınlaşır,
arxada nazilir — çünki radius orada böyük, burada kiçikdir — və nəticə
"qalınlığı gəzən haşiyə" olur.

> Nöqtə radius boyunca çəkilir, addım isə bucağa görə uzadılır. Normal boyunca
> sürüşdürəndə çökək yerlərdə qonşu nöqtələr bir-birindən keçir, kontur özünü
> kəsir və Godot çoxbucaqlını bölə bilmir — gövdə o kadrda yoxa çıxır.

Amöbdə **kirpik, ayaq və kənarda heç bir çıxıntı yoxdur**. Nişan istiqaməti
gövdənin öz silueti ilə verilir — o tərəfə bir qabarıq düşür. Kənarda çəkilən
parlaq düymə gövdədən qopmuş ləkə kimi oxunurdu və istəmədən "ayaq" təsiri
yaradırdı; **sonradan həmin düymə qalan iki növdən də çıxarıldı** və eyni həll
kirpikliyə verildi (bax §2, "Nişan çıxıntısı").

Qatlar digər növlərdən **tam tutqun** çəkilir: şəffaf olanda ikisi bir-birini
bulandırır və nəticə iki material yox, bir palçıq ləkəsi olur. Rəng fərqi də
qəsdən böyükdür — ikisi də əsas rəngə yaxın olanda gövdə tək rəngli ləkəyə dönür.

> Kənarın nöqtə sayı digər növlərin **iki misli**dir (44 / 24). Onlarda kənar
> yalnız yüngül titrəyir; burada kənarın özü hərəkət orqanıdır və 24 nöqtə ilə
> ön uc kəsik-kəsik uzanır.

---

## 4. Forma dili

| Obyekt | Forma | Niyə |
|---|---|---|
| Kirpikli mikrob | titrəyən dairə + tük haşiyəsi | yumşaq, suda üzür |
| Ayaqlı mikrob | sakit dairə + şüa ayaqlar | bərk, dibdə yeriyir |
| Amöb | yumrulanmış üçbucaq, qalın kontur, iki qat, çıxıntısız | formasız, kənarı ilə sürünür |
| Qida | kiçik hamar top, parlaq nüvə | hərəkətsiz, "yem" |
| Atılan top | eyni top + rəng + iz | qidadan RƏNGİ ilə ayrılır |
| Maneə | böyük dairə, DÖRD növdən biri (bax aşağı) | haşiyəsi qaydanı deyir |
| Partlama | bulud + üç dalğa + damcılar + membran parçaları | maddə itmir, ətrafa yayılır |
| Suda zərrəcik | qısa cizgi, axın istiqamətində | qab MAYE ilə doludur |

Rəng korluğu üçün əsas ayırd etmə formadadır: qida HƏMİŞƏ kiçik və solğun-yaşıl,
mikrob HƏMİŞƏ böyük və titrəyən, maneə HƏMİŞƏ hərəkətsiz və tünddür.

---



### Maneənin dörd növü, beş sprite-ı

Dünyada 22-26 maneə var və əvvəl hamısı EYNİ şəkil idi. Dünya ekrandan ~4 dəfə
enlidir, ona görə oyunçunun harada olduğunu ayırd edə biləcəyi heç bir
oriyentir qalmırdı.

| Növ | Atlas hüceyrəsi (V1, §4c) | Forma dili | Qayda |
|---|---|---|---|
| **SELİK** | `mucus_blob` · `mucus_bloom` | hamar gel / vezikullu gel, bütöv haşiyə | bloklayır |
| **KÖVRƏK** | `brittle_s0` → `s1` → `s2` → `brittle_rubble` | **kəhrəba çatlar**, kömür qabıq | topla sınır, sınıq qalır |
| **KOL** | `bush_base` + `bush_canopy` | **haşiyəsiz**, yarpaqlı, yaşıl | keçilir, gizlədir |
| **CƏRƏYAN** | `vent_base` + `vent_swirl` | **9 kəhrəba kəsik**, qara dəlik, fırlanan burulğan | keçilir, itələyir |

Hamısının **ayaq izi eynidir** (master-də r 384, atlasda L 192 / S 96 tekstel)
və bu, məcburidir: toqquşma həndəsəsi `Vector4(x, y, radius, kind)`-dır, yəni
siluet dəyişsəydi oyunçu "hara dəyəcəyəm" sualında yanılardı. Atlas bunu
zəmanətləyir: bərk maneənin alfası Codex-in kənarı yox, dairənin özüdür
(`SimTest._test_map_atlas`).

**Forma dili qaydanı deməlidir.** Keçilə bilən iki növ bərk növlərdən
HAŞİYƏSİ ilə ayrılır: bərk maneənin konturu bütövdür, kolun konturu yoxdur
(kənarı tükdür), cərəyanınkı isə kəsikdir. Oyunçu rəngə baxmadan, tək
siluetlə "buradan keçə bilərəm" deyə bilməlidir — rəng korluğunda da işləyən
yeganə kanal budur.

Rəng ikinci kanaldır: qabın hər yeri soyuq firuzəyidir, kol **yaşıla**,
kövrək qabığın ÇATLARI və cərəyan isə **kəhrəbaya** çalır. Kəhrəba onsuz da
"diqqət" mənasını daşıyır (bax §1, `WARNING`).

Çatların kəhrəba olması sonradan gəldi və ölçülə bilən səbəbi var: tünd
çatlarla kövrək qabıq uzaqdan adi selik ləkəsindən SEÇİLMİRDİ. Forma dili
işləyirdi (çatlar bucaqlıdır, ləkə hamardır), amma yalnız yaxından — oyunçu
isə qərarı ekranın o biri başından verir.

SELİK iki naxışa bölünür, çünki o, ən çox təkrarlanan növdür. Qalan üçünün
TƏK şəkli var — onlar qaydadır, bəzək deyil, və qaydanın iki görkəmi
olmamalıdır.

Naxış maneənin MÖVQEYİNDƏN çıxır, təsadüfdən yox — eyni maneə hər açılışda
eyni görünür, yəni xəritə yadda saxlanıla bilir.

Bərk maneələrin altında kölgə var: maneə döşəmənin İÇİNDƏ deyil, ÜSTÜNDƏ
oturur. V1-də bu, ayrıca atlas hüceyrəsidir (§4c) — aşağı-sağa düşən yumşaq
ellips və ayaq izinin dərhal xaricində nazik təmas halqası. **Kolun və
cərəyanın kölgəsi yoxdur** — kölgə "bu, döşəmənin üstündə duran cisimdir"
deməkdir, onlar isə keçilə biləndir; kölgə qoysaydıq forma dili özü-özünü
təkzib edərdi. Dağılmış kövrək də kölgəsizdir: qırıntısı yastıdır.

> Rəng fərqi kodda `modulate` ilə verilmir, teksturaya bişirilir. Köhnə səbəb
> ("batch-i qırır, 131 → 242 çağırış") Godot 4.7.2-nin GLES3 mənbəyi ilə
> təsdiqlənmir — modulate orada instansiya başına saxlanılır (MAP_25D F2) —
> amma ehtiyac da yoxdur: atlasın hüceyrələri rəngi özü daşıyır.

### Gizlənməni oyunçu GÖRMƏLİDİR

Kolda gizlənmək server tərəfdə görünməyən qaydadır: paket sadəcə
göndərilmir. Oyunçunun ekranında isə heç nə dəyişmir — geribildirim olmasa
xüsusiyyət praktiki olaraq YOXDUR, çünki oyunçu ondan istifadə etməyi ağlına
gətirmir.

Ona görə öz mikrobun kola girəndə **sönükləşir**. Mikrobun ÖZÜ dəyişir, yəni
mesaj oyunçunun baxdığı yerdədir; HUD-dakı ikonu döyüş vaxtı heç kim görmür.

V1-dən bəri yarpaqlar həqiqətən mikrobun ÜSTÜNDƏDİR (§4c), ona görə iki şey
birlikdə dəyişir: mikrob 0.45 yox, **0.70**-ə sönür (yarpaq altında 0.45 demək
olar görünməzdi), içində olduğun kolun tacı isə **0.45**-ə şəffaflaşır — Brawl
Stars-da kol öz oyunçusunun ətrafında şəffaflaşdığı kimi. Başqa kolların tacı
tutqun qalır: gizli rəqib orada gizli qalır.

---

### 4b. Xəritənin dərinliyi

> Bu bölmə SVG dövrünün dərsləridir. Qaydaları (siluet = toqquşma izi, vahid
> işıq, maneəni fırlatmamaq, kol iki qat, qabığın üç mərhələsi) V1 «Damla» dəsti
> olduğu kimi saxlayır; sprite, döşəmə və divarın konkret təsviri isə §4c ilə
> əvəz olunub.

Xəritə əvvəl yastı idi: düz rəngli döşəmə, bərabər şəbəkə, nazik halqalar və
maneə şəkilləri. Maneələr döşəmənin **üstündə** yox, **üzərinə çəkilmiş** kimi
oxunurdu. Dərinlik Brawl Stars üsulları ilə qazanılır — amma bir sərt
məhdudiyyətlə.

> **Siluet = toqquşma izi.** Brawl Stars obyekti toqquşma izindən yuxarı
> qaldırır və kölgəni yerdə saxlayır. Bizdə bu QADAĞANDIR: amöbin dar keçidi
> ([`Const.SPECIES_BODY`](../game/scripts/shared/constants.gd)) oyunçunun
> aralığı dəqiq oxumasını tələb edir. Sprite qaldırılsa, amöb "keçirəm" deyib
> görünməyən kənara dəyər. Dərinlik siluetin **içində** (kölgələmə) və
> **çölündə** (təmas kölgəsi) qazanılır, sürüşdürmə ilə heç vaxt.
>
> Bu məhdudiyyət üsluba uyğundur: selik damcı kimi qabarmalıdır, kub kimi
> qalxmamalı. Petri qabında düz künc yoxdur.

**Vahid işıq.** Bütün xəritə üçün bir açar işıq: `L = (-0.45, -0.89)` —
yuxarı-sol. Kölgə aşağı-sağa düşür.

Maneələr artıq **fırladılmır**. Əvvəl hər ləkə `(o.x + o.y) * 0.01` radian
fırladılırdı ki, eyni şəklin təkrarı bilinməsin — ölçü isə yüzlərlədir, yəni
bucaq faktiki təsadüfi idi. Sprite-ın qradiyenti yuxarı-soldan işıqlanıb, ona
görə fırlanma **işığı da fırladırdı**: 26 maneənin hər birində işıq başqa
tərəfdən gəlirdi və qradiyent həcm yox, rəng ləkəsi kimi oxunurdu. Naxış
variasiyası lazımdırsa, eyni istiqamətdə işıqlandırılmış ayrı sprite seçilir.

**Bərk maneənin üç üzü sprite-a bişirilib**, kodda çəkilmir — səbəb ölçmədir
(bax README, "Tələlər"). Düşən kölgə `-LIGHT_DIR` ilə aşağı-sağa gedir; r=120
yan üz aşağı-sağa tündləşir; ellipsvari üst üz `(151,145)` mərkəzində
`108×106` radiusla oturur. Beləliklə aşağı-sağda təxminən 26 px (radiusun
22%-i) yan bant açılır, amma xarici toqquşma silueti yerindən tərpənmir.
Kölgə və hündürlük radiusla birlikdə miqyaslanır; əvvəl sabit 10 piksel idi və
40 px-lik ləkə ilə 250 px-lik ləkə eyni kölgəni alırdı.

**Kol iki qatdır.** Baza mikrobun altında, **frondlar üstündə**
([`Arena._canopy`](../game/scripts/client/arena.gd)). Gizlənmə qaydası əvvəl
yalnız serverdə mövcud idi — ekranda kolun içindəki mikrob kolun üstündə
dayanırdı. İndi yarpaqlar onun üstündən keçir və "nəyinsə altındayam" izahsız
oxunur. Üst sprite-ın **içi boşdur**: dolu qat gizlənəni tamamilə örtərdi.
Kol yastı qalır — kölgə və yan üz almır — amma `BUSH=#4FCB72` doymuş yaşılı ilə
döşəmədən ayrılır. Üst qat 16 yox, 28 əyri fronddur; `_process` onları
`±0.030 rad` rotation və `±0.018` skew ilə yırğalayır. Baza sabitdir, ona görə
keçilən sahənin özü sürüşmür.

**Qabığın üç zədə vəziyyəti.** `BRITTLE_HP = 3` həmişə var idi, amma sprite heç
vaxt dəyişmirdi — oyunçu neçə zərbə qaldığını bilmirdi. İndi zərbə sayı divar
baytının boş bitlərində daşınır ([`DishMap.Wall`](../game/scripts/shared/dish_map.gd))
və şəkil dəyişir: çatlar dərinləşir, kəhrəba genişlənir. Şəbəkəyə sıfır bayt.

**Cərəyan deşiyi mənfi hündürlükdür.** Sabit bazada yuxarı-sol daxili divar
kölgədə, aşağı-sağ daxili divar işıqdadır — qalxmış maneənin tərsi. Baza daha
qabın mərkəzinə döndərilmir, çünki bu, daxili işığı da fırladıb qlobal
`LIGHT_DIR`-i pozurdu. Cərəyan ayrıca `mucus_vent_swirl.svg` qatındadır və
`0.72 rad/san` fırlanır; ventlər azdır və eyni teksturada ardıcıl olduqları
üçün bu, maneə başına yox, cəmi bir əlavə çəkiliş çağırışıdır. Simulyasiyadakı
itələmə yenə qabın mərkəzinə doğrudur (`Sim._vent_push` toxunulmayıb).

**Su iki dərinlikdədir.** 110 zərrəcik `80 + 30` kimi bölünür: dərin qat sönük,
nazik və yavaş; səth qatı parlaq və sürətli. Göz fərqi ölçmür — dərinlik kimi
oxuyur ([`WaterMotes.depth`](../game/scripts/client/water_motes.gd)).

**Döşəmə** tək teksturadır (`dish_floor.svg`): mərkəz `#19363F`-dən kənarda
`#071012`-yə düşür, üstündə yumşaq və təkrarlanmayan yeddi agar ləkəsi, ən
üstdə bişmiş vinyet var. Şəbəkə kənara doğru sönür; hər 400 px-də yuxarı-sol
işıq + aşağı-sağ kölgə eyni `draw_multiline_colors` batch-inə əlavə olunur.
Məsafə halqaları nazik xətt yox, enli və qırıq sediment zolağıdır (nazik tam
halqa döşəmənin üstünə çəkilmiş UI elementi kimi oxunurdu).

**Şüşə divar** dörd hissədir: 34 px daxili kölgə, 17 px gövdə, yuxarı-solda
5 px işıq qövsü, aşağı-sağda 9 px tünd dodaq. Qövslər əl bucağından yox,
`Palette.LIGHT_DIR`-dən çıxır; simmetrik halqa həmişə yastı qalır. Bayırda
`BG_OUTER`-dən `BG_VIGNETTE=#020708`-ə iki pilləli düşmə gözü qaba çəkir.

**Quruyan zona** kəhrəba örtükdən əlavə çat naxışıdır: HIGH-da 18, LOW-da 10
deterministik çat eyni multiline çağırışında çəkilir. Nəbz yaş radius daraldıqca
`2.2 → 7.0 rad/san` sürətlənir. Səkkiz buxar kəkili yalnız HIGH keyfiyyətdədir
və hamısı bir əlavə multiline çağırışıdır; LOW-da massiv belə qurulmur.

### 4c. V1 «Damla» — oyundakı xəritə (2026-10-19)

Dörd versiyadan sahib birincini seçdi ([MAP_25D.md](MAP_25D.md)): hündürlük
ayaq izinin içindədir, yəni §4b-nin sərt qaydası qalır. Rəsmlər Codex ilə
çəkilib (`map_art/raw/v1/`, `raw/shared/`) və oyuna `map_art/build_map.gd`
vasitəsilə girir — README, «Xəritə — V1 Damla».

**Maneə.** Gel günbəzi: üst üz yuxarı-soldan işıqlanıb, cənub bandı tündləşir
(kamera cənubdadır və hər qalxan şeyin cənub üzünü görür), haşiyə `#081A20` —
mikrobların `#04090B`-sindən qəsdən zəif. Selik iki naxışdır (hamar damla və
yastı vezikullu "bloom"), kövrək kömür qabıqdır: s0-da nazik kəhrəba çatlar,
s1-də bir çat bütün qapağı kəsir, s2-də qabıq közərir — HIGH-ın parlamasında
"dağılmaq üzrədir" uzaqdan oxunur. Dağılan kövrək **sınıq qalır**: yastı,
konturu və kölgəsi olmayan qırıntı yığını, keçid artıq açıqdır.

**Kölgə pipeline-dandır**, Codex-dən yox: bütün bərk siluetlər eyni dairədir,
ona görə bir hüceyrə hamısına yarayır və işıq kodda dəqiq qalır — ellips
`1.05 × 0.80 R`, `+0.11 R / +0.22 R` aşağı-sağa, alfa 0.36 (Brawl Stars-da kölgə
pikseli cəmi ×0.75 tündləşir), kənarı σ 0.06 R; ayaq izinin dərhal xaricində
0.04 R-lik təmas halqası, alfa 0.28. Bütün kölgələr gövdələrdən ƏVVƏL çəkilir,
gövdələr isə şimaldan cənuba — cənubdakı gövdə şimaldakını örtür.

**Kol iki qatdır və indi həqiqətən iki qatdır.** Döşək (`bush_base`, 0.95 R)
mikrobun altında, tac (`bush_canopy`, boş mərkəzi r 0.35 R) z 2-də — mikrobların
üstündə. Əvvəlki "frondlar mikrobun üstündən keçir" sözü ekranda heç vaxt doğru
olmamışdı: tac z 0-da idi, mikrob özünə 1/2 yazırdı. Kolun rəngi `#3E9068`-dir:
əvvəlki `#4FCB72` laym, nanə və yoldaş halqası ilə eyni yaşıl ailədə idi və
HIGH-da saçırdı; yeni ton nanənin tonudur, amma xeyli tünd və solğundur (V 0.56).

**Top kolun üstündə.** Yarpaq mikrobun üstündə olanda kola girən top yarpaq
altında itərdi. Top və izi kolun içində yarpağın üstünə çıxır, amma yalnız
heç bir mikrobun gövdəsində olmayanda — §3c-nin "top gövdədən membranı yararaq
çıxır" görüntüsü pozulmur. Nişanın səkmə halqaları, oxu və kilidi də yuxarıdadır.

**Cərəyan.** Dəliyin dodağında 9 kəhrəba kəsik, içində qaranlıq; burulğan ayrı
hüceyrədir, üç qollu, kəhrəbaya boyanmış və TAM fırlanma oxundadır — Codex onu
48 px mərkəzdən kənarda çəkmişdi, fırlananda yırğalanardı.

**Döşəmə** iki qatdır, bir keçiddə: makro ton (1024², bütün qab — mərkəz açıq,
kənar qaralır, yumşaq agar zonaları, sediment zolaqları bişib) × 400 px-lik
tikişsiz detal (agar dənəsi, mikro baloncuq halqaları, liflər; orta 0.5,
±6%). Detal ±12% həm açır, həm qaraldır — MUL qarışdırma yalnız qaraldardı.

**Şüşə divar** artıq dörd qövs deyil. **Şimal divarı** şüşənin daxili üzüdür və
dodaqdan BAYIRA uzanır: şimalda 70 px, yanlarda 8 px (divar yandan görünür),
üzündə kondensasiya halqaları (içi boş — dolu açıq kürə qida kimi oxunardı).
Kafellərin bəziləri güzgü kimi çevrilir: eyni üç halqa hər 280 px-də eyni
sırada təkrarlananda divar divar kağızı kimi görünürdü. **Cənub dodağı** yaxın
divarın üstüdür: içəriyə 6–28 px, yarımşəffaf şüşə və nazik `RIM_LINE` xətti,
mikrobların ÜSTÜNDƏ — kənara sıxılan mikrob "şüşənin arxasında" görünür.

**Qabın bayırı** halqa mesh-idir (`BG_OUTER` → `BG_VIGNETTE`), üstündə
fokusdan kənar, tünd "başqa koloniyalar" — maneə şəkillərinin bulanıq
nüsxələri. Mikrob formalı heç nə yoxdur: bayırdakı mikrob silueti rəqib kimi
oxunardı.

**Toxunuş.** Divar vurulanda titrəyir (yalnız şəkil, dairə yox), şüşə
parıldayır, suda dalğa və sıçrantı qalır, koldan keçən top yarpağı silkələyir,
döşəmə bəzəyi (46 yastı, konturu yox, döşəmədən ±0.08 fərqli parça) top
üstündən keçəndə sıçrayır, dağılan qabıq öz parçalarını səpir.

---

## 5. Maye qatı

Qab su ilə doludur və bu, **həm simulyasiyada, həm görüntüdə** var. Görüntü
tərəfi bir qatdan ibarətdir: [`water_motes.gd`](../game/scripts/client/water_motes.gd).

Zərrəciklər **nöqtə yox, CIZGI** kimi çəkilir və cizgi məhz axının istiqaməti
boyunca uzanır. Beləliklə qat eyni zamanda axın sahəsinin özünü çəkir — oyunçu
burulğanı **görür** və ondan istifadə etməyi öyrənir.

Niyə bu qat lazımdır: oyunçu axını mikrobunun sürüşməsindən hiss edir, amma
görmür — özü də, rəqib də hərəkət edir, ona görə sürüşməni **idarəetmə xətası**
kimi oxumaq olar. Sərbəst zərrəciklərin heç bir iradəsi yoxdur; onlar sürüşürsə,
deməli su sürüşdürür.

| Parametr | Dəyər | Niyə |
|---|---|---|
| Say | HIGH `80 + 30`, LOW `34 + 14` | Çoxu fonu "qar" kimi göstərir və mikrobların oxunmasına mane olur |
| Rəng | `DISH_EDGE` → `TEXT` 30%, alfa səthdə `0.40`, dərində `0.24` | Sönük olsa qat boş yerə hesablanır, parlaq olsa mikroblarla yarışır |
| Cizgi | axın sürəti × 0.85 s | Qısası nöqtəyə bənzəyir, uzunu yağış kimi görünür |
| Sahə | kameranın ətrafında ± 0.8 × ekran eni | Kənara çıxan zərrəcik əks tərəfdən qayıdır: sabit sıxlıq, sabit yaddaş |

Bütün qat **bir** `draw_multiline_colors` çağırışıdır. HIGH-da hər cərəyan
deşiyinə radial + spiral oxla sorulan **7** əlavə cizgi həmin batch-ə qoşulur;
ayrıca node və çağırış açılmır. LOW-da sink massivi boşdur, yəni bu material
işarəsi həm hesabdan, həm görüntüdən tam çıxır.

### Burulğan EKRANA SIĞMALIDIR

Bu, qatın işləyib-işləməməsini təyin edən yeganə ən vacib rəqəmdir və
dünyanın ölçüsü ilə yox, **ekranın eni** ilə müqayisə olunur.

İlk versiyada burulğanın dalğa uzunluğu 760 px idi — başlanğıc ekranından
(620 px) böyük. Riyaziyyat tamamilə düzgün işləyirdi, amma nəticə görünmürdü:
ekrandakı bütün zərrəciklər təxminən eyni tərəfə baxırdı, yəni oyunçu
fırlanmanı yox, sadəcə izahsız bir sürüşməni görürdü.

430 px-də ekrana ~1.5 burulğan sığır: cizgilər əyilir, fırlanma oxunur.
Daha kiçik etmək olmaz — mikrob saniyədə bir neçə burulğan keçər və axın
nizam yox, səs-küy kimi görünər.

| | Əvvəl | İndi |
|---|---|---|
| Dalğa uzunluğu | 760 px | **430 px** (ekranın 0.69-u) |
| Orta axın sürəti | 12.6 px/s (sürətin 6.7%-i) | **20.9 px/s (11.0%)** |
| Axının hiss olunmadığı sahə | 32% | **22%** |

Hər iki xassə — orta sürət və ekrana sığma —
[`SimTest._test_current_field`](../game/scripts/tools/sim_test.gd) ilə qorunur.
"Düzgün işləyir" ilə "hiss olunur" ayrı şeylərdir; ikincisi də ölçülməlidir,
əks halda növbəti tənzimləmə onu yenidən söndürər.

> `z_index` **sıfır qalmalıdır.** Mənfi qoyulsa zərrəciklər valideynin öz
> `_draw`-ının — yəni qabın döşəməsinin — altına düşür və tamamilə görünməz
> olur. (Godot-da uşağın z-i valideynin çəkilişinə nisbətdədir.)

---

## 6. Partlayış

Ölüm oyunun ən vacib hadisəsidir və ekranda eyni anda başqa 9 mikrob var.
Bir ağ ləkə kifayət etmir: hadisə üç ayrı kanaldan oxunmalıdır —
**ANİ** (parıltı), **YAYILAN** (bulud və dalğalar), **QALAN** (damcılar və
membran parçaları). Kod: [`burst_fx.gd`](../game/scripts/client/burst_fx.gd).

| Qat | Müddət | Nədir |
|---|---|---|
| Parıltı | 75 ms | Membranın qopduğu an — "zərbə" hissi |
| Bulud | 1.15 s | `burst.svg` radial qradiyenti; mikrobun ölçüsündən 3.5 misline açılır |
| Üç dalğa | 0.7 s | 75 ms fasilə ilə; genişləndikcə həm sönür, həm nazilir |
| Zərbə halqası | 0.40 s | Bütün partlayışları bir batch-də birləşdirən nazik geniş halqa |
| Damcılar | 1.15 s | Sayı **top sayına** bərabərdir; hər biri qısa iz buraxır |
| Membran parçaları | 1.15 s | 9 qövs, fırlanaraq uçur — bir `draw_multiline` |

İki qayda:

- **Heç nə düz xətlə uçmur.** Damcılar da, parçalar da eksponensial
  sürtünmə ilə yavaşıyır (`exp(-3.4·t)`) — suyun içində partlayış belə görünür.
  Sabit sürətlə genişlənən halqa "partlayış" yox, "animasiya" kimi oxunur.
- **Mikrobun görüntüsü DƏRHAL susdurulur** ([`GermVisual.kill()`](../game/scripts/client/germ_visual.gd)).
  Server partlayan mikrobu artıq göndərmir, amma görüntüsü bir interpolyasiya
  gecikməsi qədər saxlanılır — susdurulmasa partlayışın ortasında sağ-salamat
  mikrob dayanardı.

Partlayan mikrob **rənginə görə** tapılır: bir dünyada iki eyni rəngli mikrob
olmur ([`World._free_color`](../game/scripts/server/world.gd)), ona görə rəng
mikrobun kimliyidir və partlama hadisəsinə ayrıca id sahəsi əlavə etmək lazım
deyil — snapshot-da hər bayt sayılır.

### 6a. Döyüş VFX-i, kamera və UI juice

Doqquz hadisə bir vizual dilə bağlanır. Doğuş pop-u Mərhələ 1-də membranın
özündədir; qalan qısa döyüş effektləri
[`JuiceFx`](../game/scripts/client/juice_fx.gd) içindədir:

| Effekt | Müddət / say (HIGH → LOW) | Forma qərarı |
|---|---|---|
| Lülə alovu | `0.08 s`, `3 → 1` ləçək | membran yarığında, nişan oxunda |
| Zərbə sıçrantısı | `0.22 s`, `8 → 4` qığılcım | gələn top oxunda `±0.58 rad` konus; radial deyil |
| Partlayış halqası | `0.40 s`, `40 → 20` seqment | radius `0.82r → 3.07r`, cubic ease-out |
| Qida udulması | `0.30 s`, `4 → 2` iz | kvadratik Bezier qövsü + membranda dalğa |
| Tutum mükafatı | `0.62 s`, `12 → 6` şüa | `SUPER_READY` qızılı aura və halqa |
| Kol xışıltısı | `0.52 s` | girişdə və çıxışda yalnız toxunulan üst frond; `sin(31t)·exp(-5.8t)` |
| Qabıq qırıntısı | `0.52 s`, `6/12 → 3/6` parça | adi zərbədə konus, üçüncü zərbədə tam çevrə + qırıq toz halqası |
| Cərəyan axını | fasiləsiz, vent başına `7 → 0` | mövcud su batch-ində deşiyə daralan spiral |
| Doğuş | `0.35 s` | membran `0 → 1.12 → 1.0`, yerdə halqa; `GermVisual` |

`JuiceFx` hadisə başına node yaratmır. Bütün aktiv hadisələri qalın alov/udulma,
incə qığılcım və halqa olmaqla **üç** multiline massivinə yığır; deməli effekt
sayı artsa da bu qatın pik çağırışı `≤3` qalır. `draw_circle` ilə hər zərrəciyi
ayrıca çəkmək sınanmadı: bu layihədə hər primitiv ayrıca çağırışdır və 10
mikroblu döyüşdə 350 həddini keçmək riski daşıyır.

Kamera kanalları ayrıdır: `_shake` təsadüfi mövqe titrəyişidir, `_kick` isə
topun səth nöqtəsindən qurbanın mərkəzinə gedən ox boyunca yönlü təpikdir.
Təpik `16 px`-də məhdudlaşır və `70 px/san` sürətlə sönür. Yaxın rəqib
partlayanda mövcud `_punch=0.07` qısa zoom verir. Ağ parıltı, `75 ms` vizual
donma və uçan rəqəm toxunulmaz qalır; `Engine.time_scale` yenə işlədilmir.

UI zamanları:

| Element | Hərəkət |
|---|---|
| Atəş və menyu düymələri | basış `0.94` (60 ms), buraxılış `1.0` (160 ms, back-out) |
| Super düyməsi | mövcud aşağıdan dolum + hazır nəbzi + halqa boyu işıq zolağı qorunur |
| HUD doluluğu | hədəfə `1-exp(-10t)` ilə yaxınlaşır; `fill ≥ 0.85` olanda `±1.9 px` titrəyir |
| Uçan rəqəm | `0.52 → 1.0`, `0.26 s` back-out; əvvəl oxunur, sonra sönür |
| Mərkəz bildirişi | `0.72 → 1.0`, `0.24 s` back-out |
| Növ kartı | basışda `0.94`; seçiləndə istirahət miqyası `1.035` |

Yekun RTX 5050 ölçməsi (`1280×720`, vsync sönük, 12 s):

| Rejim | Əvvəl / M2 / M3 orta | M3 1% ən pis | Çağırış piki əvvəl / M2 / M3 |
|---|---:|---:|---:|
| SONSUZ ARENA | `1.85 / 2.15 / 2.48 ms` | `3.70 ms` | `~230 / 188 / 196` |
| TƏK QALAN | `2.82 / 2.93 / 2.35 ms` | `4.03 ms` | `~212 / 249 / 202` |

Hər iki rejimdə `>16.7 ms` kadr sıfırdır və 350 çağırış həddi qorunur. Təsadüfi
daha sıx TƏK QALAN çalışmasında eyni reviziya `263` pik göstərib; sənədləşən
konservativ yuxarı ölçü budur və limitdən 87 çağırış aşağıdır.

---

## 6b. Menyu — yatay

Oyun **yalnız yatay** oynanır (1280×720 baza). Menyu forma deyil, **vitrindir**:
düzülüş Brawl Stars-ın **bugünkü (2026)** ana ekranından götürülüb,
iqtisadiyyatı isə qəsdən götürülməyib.

### Brawl Stars 2026 — nəyə baxılıb

Supercell-in 2026 buraxılış qeydləri ana ekranı sadələşdirir: avqust
yeniləməsində Starr Road və Fame düymələri ana ekrandan çıxarılıb, Brawler
kolleksiyasının içinə köçüb; lobbidə isə toxunmaq, çəkmək, sıxmaq və atmaq
olan canlı personaj (Loony) var. Düzümün qalanı illərdir sabitdir:

| Brawl Stars | Bizdə |
|---|---|
| Yuxarı-sol: profil (ikon + ad + kubok) | Profil: seçilmiş növün avatarı + ad (yazılır) |
| Yuxarı-sağ: valyutalar + menyu düyməsi | QİDA, DNT (görünüş üçün) + dişli → AYARLAR |
| Sol lent: Shop, Brawlers | MAĞAZA (görünüş üçün), MİKROBLAR, MƏŞQ |
| Mərkəz: brawler 3D modeli, adı üstündə | Qəhrəman podiumda, adı və superi başının üstündə |
| Aşağı-sağ: [hadisə yuvası][sarı PLAY] | [rejim kartı — rejimin rəngində][sarı OYNA] |
| Aşağı-sol: Brawl Pass, tapşırıqlar | MİKRO PASS, TAPŞIRIQLAR (görünüş üçün) |
| Lobbidə oynanan personaj (Loony) | Qəhrəmana toxunmaq titrədir, çəkmək dartır/əyir |
| Döyüşdə sistem düyməsi yoxdur | Matçda dişli YOXDUR, ayarlar yalnız menyuda (bax § 6c) |

Mənbə: [Release Notes August 2026](https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-august-2026/)
və əvvəlki 2026 qeydləri (fevral — Ranked ana ekranda, iyun — Rush düyməsi).

### Zonalar (1280×720)

| | Yer | Ölçü | Nə edir |
|---|---|---|---|
| A | 30, 20 | 330×70 | Profil: 56 px avatar-kafel + ad (birbaşa yazılır) |
| B | sağ 30, 20 | 70×70 dişli + 2 × 150×44 zolaq | QİDA və DNT valyutaları (görünüş üçün) və dişli — TAM EKRAN ayarlar (§ 6c) |
| C | ayaq nöqtəsi `0.5w, 0.61h` | qəhrəman `0.70h × 0.45h` qutuya sığır, podium eni `0.80h` | Şüşə podium + növün **qəhrəman illüstrasiyası**; ad lövhəsi (300×64) başının üstündə |
| D | sol, mərkəzdən yuxarı | 3 × 112×112, ara 18 | MAĞAZA, MİKROBLAR, MƏŞQ — ikon üstdə, ad altda |
| F | sol aşağı | 250×112 + 112×112, ara 16 | MİKRO PASS və TAPŞIRIQLAR (görünüş üçün) |
| E | sağ aşağı | 330×112 + 290×112, ara 16 | Rejim kartı + **OYNA** |

Aşağı zolaq **aşağıya** bağlanıb, yuxarıya yox: OYNA baş barmağın çatdığı
yerdə qalmalıdır, ekran nə qədər hündür olsa da.

### Düymə dili — [`ChunkyBox`](../game/scripts/client/chunky_box.gd)

Brawl Stars düyməsinin dörd qatı: **qara kontur** (3 px) → **dodaq** (üzün
rənginin 38% tünd variantı, 7 px) → **üz** → **parıltı** (üst 45%, ən çox 24 px,
ağ 16%). Basılanda dodaq 2 px-ə düşür, üz və mətn aşağı enir.

`StyleBoxFlat` işlədilmir, çünki onun BİR sərhəd rəngi var — dodaqsız düymə
yastı, qara dodaqlı isə "qara ayaqqabılı" görünürdü. Button-un öz `_draw`-ı
mətndən sonra çağırılır, yəni fon orada çəkilə bilməz; StyleBox isə mətndən
əvvəl çəkilir.

| Element | Üz | Niyə |
|---|---|---|
| OYNA | `MENU_PLAY` `#FFD83B` | Ekranın yeganə sarı ləkəsi. `SUPER_READY`-dən qəsdən ayrıdır |
| Sol lent, dişli, GERİ | `MENU_BLUE` `#1F95D6` | Brawl Stars mavisi, firuzəyi qaba doğru çəkilib |
| Rejim kartı | rejimin rəngi, 45% tünd | Rejim adından əvvəl rəngindən tanınır |
| Profil, nişan, ad lövhəsi | `MENU_PANEL` `#0E3346`, dodaqsız, parıltısız | Basılmır — basılası kimi görünməməlidir |
| Seçilmiş kart | sarı kontur, 5 px | Ana ekrandakı sarı OYNA ilə eyni dil |

**Yazı:** ağ, qara kontur (4–9 px) və altda kölgə. Başlıqlar üçün Baloo 2 800
əlavə qalınlaşdırılır (`variation_embolden 0.55`, bax [`ChunkyBox.heavy_font`](../game/scripts/client/chunky_box.gd)) —
Brawl Stars-ın Lilita One şriftinə yaxınlaşmaq üçün; Lilita-nın özündə `Ə/ə` yoxdur.

### Qaydalar

1. **Mikrob qəhrəmandır.** Ana ekranda hər növün öz illüstrasiyası var və o,
   fon şəklinin üstündə, şüşə podiumda durur — Brawl Stars lobbisindəki
   brawler kimi. Əvvəl burada oyunun öz [`GermVisual`]-ı 4.2× böyüdülürdü:
   oyunla eyni idi, amma boş qara fonda kiçik bir ləkə kimi oxunurdu.
   Qəhrəman nəfəs alır (en və hündürlük ƏKS fazada, həcm saxlanılır), suda
   yüngül qalxıb-enir (kölgəsi onunla kiçilir). Toxunanda jele kimi
   titrəyir, çəkəndə dartılır (≤ 0.30) və əyilir (≤ 20°), buraxanda yay onu
   titrədərək qaytarır. Hamısı bir node-un transformudur — çəkiliş çağırışı
   artmır. Oyundakı görünüş itmir: növün səhifəsindəki «OYUNDA» pəncərəsi
   canlı [`GermVisual`]-dır (bax § 6d).

   **Illüstrasiyalar və ikonlar kodla yox, Codex ilə çəkilib** — xam fayllar,
   emal olunmuş variantlar və promptlar [`design/menu_art/`](menu_art/)-dadır.
   Sərt qaydalar orada da eynidir: **simasız**, qalın tünd kontur, işıq
   yuxarı-soldan, içində oyunun topları görünür. Yeni növ və ya rejim əlavə
   olunanda eyni brif ilə onun qəhrəmanı/ikonu da çəkilməlidir.
2. **Ekranda BİR sarı ləkə var** — OYNA. Rejim kartı onun solundadır və
   rejimin rəngindədir: «nə oynayıram» və «başla» bir baxışda oxunur.
3. **Basılan hər şey əzilir** (`0.94` miqyas, 60 ms) və `ui_click` səsi verir;
   buraxılış `0.16 s` back-out-dur. Növ kartı seçiləndə `1.035` miqyasda qalxır.
4. **Vərəq açılanda ana ekran gizlənir** (fon qalır). Brawl Stars-da Brawlers
   ayrı ekrandır; 14% şəffaflıqdan arxadakı ad lövhəsi vərəqin başlığının
   altına düşürdü.
5. **GERİ jesti** (Android) açıq vərəqi/ayarları bağlayır, ana ekranda isə
   oyundan çıxır. `quit_on_go_back` söndürülüb, yoxsa jest vərəq açıq ikən
   bütün tətbiqi bağlayırdı.

### Mağaza, valyuta, MİKRO PASS və tapşırıqlar — GÖRÜNÜŞ ÜÇÜN

Brawl Stars ana ekranının təxminən yarısı iqtisadiyyata gedir və onsuz ana
ekran yarımçıq görünür. Ona görə düymələr Brawl Stars-dakı yerlərindədir,
ikonları Codex ilə çəkilib. Arxalarında isə **hələ sistem YOXDUR**:

| Düymə | Yeri | İndi nə edir |
|---|---|---|
| QİDA (yumşaq valyuta), DNT (premium, yaşıl "+") | Yuxarı sağ, dişlinin solu | Sayı `0`; basanda «QİDA — TEZLİKLƏ!» |
| MAĞAZA | Sol lentin ən üstü, çəhrayı | «MAĞAZA — TEZLİKLƏ!» |
| MİKRO PASS | Aşağı-sol, 250×112 | «Səviyyə 1», boş zolaq; «TEZLİKLƏ!» |
| TAPŞIRIQLAR | Pass-ın sağı, 112×112 | «TEZLİKLƏ!» |

Basılıb heç nə olmayan düymə etibarı aparır — oyunçu oyunun sınıq olduğunu
düşünür. Ona görə hər biri əzilir, səs verir və ekranın yuxarısında sarı
**«… — TEZLİKLƏ!»** bildirişi çıxarır ([`MenuV2._coming_soon`](../game/scripts/client/menu_v2.gd)).
Nə gəlmədiyini açıq deyir, oyunçunu aldatmır. QA agenti bunu yoxlayır: MAĞAZA
bildiriş verməli və heç bir ekranı/qoşulmanı işə salmamalıdır.

### Server vəziyyəti ekranda YOXDUR

Əvvəl yuxarı-sağda, sonra profilin altında «server yatıb», «server
yoxlanılır…» yazılırdı. Bu, oyunçunun işi deyil — texniki daxili vəziyyətdir
və oyunçu heç nə etməmiş oyunu sınıq göstərir. İndi:

- Menyu açılan kimi serverə **səssiz** qoşulur (yatmış Railway serveri oyanana
  qədər vaxt qazanılır, OYNA basılanda bağlantı çox vaxt hazırdır). Nəticə yalnız
  `MenuV2._net_state`-dədir — QA agenti və diaqnostika üçün.
- Oyunçu **özü OYNA basıb** qoşula bilməyəndə (bağlantı alınmadı, kəsildi və ya
  12 s cavab yoxdur) bildiriş çıxır, texniki sözsüz: **«ONLAYN OYUN HAZIRDA
  ƏLÇATMAZDIR»** + «Botlarla MƏŞQ oynaya bilərsən.» — nə baş verdiyini və nə
  edə biləcəyini deyir.
- QA agenti ana ekranın görünən yazılarında «server» sözünü axtarır; tapsa,
  problem yazır. Ayarlar ekranı istisnadır — orada server ünvanı sahəsi var.

Sistemlər gələndə yalnız düymənin cavabı dəyişəcək — qəhrəman, rejim kartı və
OYNA, yəni ekranın ürəyi, yerini dəyişmir.

### Tipoqrafiya

| Rol | Şrift | Harada |
|---|---|---|
| Başlıq | **Baloo 2** 800 | Düymələr, növün adı, doluluq rəqəmi, mərkəzi mesajlar |
| Mətn | **Nunito** 600 | Liderlər, izahlar, ad, ipucları |

İkisi də yumru terminallıdır — üslubun *"heç bir metal, heç bir künc"* qaydasına
oturur. Seçimin ikinci və daha sərt şərti: **Azərbaycan hərflərinin hamısı**
(`Ç ç Ə ə Ğ ğ İ ı Ö ö Ş ş Ü ü`). Populyar oyun şriftlərinin çoxunda `Ə`/`ə`
yoxdur və "MƏŞQ" sözü "M□ŞQ" çıxır — bax README, «Tələlər».

Rollar [`assets/ui/theme.tres`](../game/assets/ui/theme.tres)-də bağlanıb;
başlıq `Label`-a `theme_type_variation = "Heading"` ilə verilir.

---

## 6c. Ayarlar ekranı — YALNIZ menyuda

Dişli (zona B) **tam ekran** açır — düşən panel deyil. Kod:
[`SettingsView`](../game/scripts/client/settings_view.gd).

**Matçın içində ayarlar YOXDUR.** Əvvəl HUD-un yuxarı-mərkəzində dişli vardı
və eyni ekranı "MATÇI TƏRK ET" ilə açırdı. Brawl Stars döyüşdə heç bir sistem
düyməsi göstərmir — səs və qrafika döyüşdən ƏVVƏL qurulur, dişli isə hər
matçda ekranın bir parçasını tuturdu.

### Düzülüş (1280×720)

| | Yer | Ölçü | Nə var |
|---|---|---|---|
| Başlıq | mərkəz, y 26 | 52 h | «AYARLAR», qalın Baloo, 40 px, qara kontur |
| Sütunlar | 34 … −34, y 90 … −100 | 3 × bərabər, ara 22 | SƏS · QRAFİKA · İDARƏ — tünd `MENU_PANEL`, qalın kontur |
| Alt-sol | 34, aşağı 34 | 170×52 | «‹ GERİ» — menyunun vərəqlərindəki ilə eyni mavi düymə |

**Niyə üç sütun:** ekran yatay 1280×720-dir. Bir sütunluq siyahı eninin üçdə
ikisini boş qoyub oyunçunu sürüşdürməyə məcbur edərdi; üç sütun hamısını bir
kadra yığır. Sütunların özündə `ScrollContainer` var — ehtiyat üçün, alçaq
pəncərədə sonuncu sətir kəsilməsin.

### İdarə elementləri

| Element | Ölçü | Qayda |
|---|---|---|
| Sürgü ([`TouchSlider`](../game/scripts/client/touch_slider.gd)) | toxunuş 44 h, tutacaq r 17 | Godot-un `HSlider`-i işlədilmir: standart tutacağı ~10 px-dir, baş barmaqla tutulmur. Zolağa toxunmaq dəyəri ora atır |
| Seçim zolağı (segment) | 42 h, ara 6 | 2–4 variant YAN-YANA. Növbə ilə keçən tək düymə deyil: orada oyunçu qalan variantları görmür |
| Açar (switch) | 76×40, tutacaq 30 | Sürüşür (`0.16 s` back-out). AÇIQ/QAPALI yazısı yoxdur — yeri və rəngi kifayətdir, yazı isə sütunu dartır |
| Seçilmiş pillə | `MENU_BLUE` üz, 6 px dodaq, konturlu ağ yazı | Seçilməyənlər tünd və 3 px dodaqlıdır — seçim həm rəngdən, həm "qalxmaqdan" oxunur |
| AYARLARI SIFIRLA | narıncı `ChunkyBox`, ağ yazı | Geri qaytarılmayan əməlin rəngi |

Örtük menyuda **tam tutqundur** (`1.0`): `0.97` sınandı və az idi — OYNA-nın
doymuş rəngi, qəhrəman və dişli 3 faizdən keçib oxunurdu.

### Matçdan çıxış — ayarsız

Sonsuz arenada matç bitmir, ona görə çıxış qalmalıdır: dişlidən əvvəl
oyunçunun yeganə yolu ölmək idi. Çıxış **düymə deyil, sistem jestidir**:
Android-in GERİ jesti və ya ESC HUD-da kiçik təsdiq açır
([`Hud.toggle_leave_prompt`](../game/scripts/client/hud.gd)):

| | |
|---|---|
| Başlıq | «MATÇDAN ÇIXIRSAN?» + «Mikrobun dünyadan silinir, qazandığın tutum itir.» |
| Sol | **DAVAM ET** — mavi; ilk refleks geri qayıtmaqdır |
| Sağ | **ÇIX** — `DANGER` |
| Örtük | `0.72` — oyun DAYANMIR (server-authoritative dünyada pauza yoxdur) |

Təsdiq açıq ikən toxunuş idarələri buraxılır və klaviatura girişi də sıfırlanır
— yoxsa WASD basılı qalan oyunçu "çıxım, ya yox" düşünərkən mikrob divara üzərdi.
Təsdiq ona görədir ki, GERİ jesti ekranın kənarından sürüşdürməklə edilir və
döyüşdə barmaq ora təsadüfən gedir.

---

## 6d. MİKROBLAR — Brawl Stars-ın Brawlers kolleksiyası

Brawl Stars-ın 2026 kolleksiyası: kiçik **portret kartlar** üfüqi sırada, axtarış,
solda Brawler Blast, sağda Fame ([Release Notes August 2026](https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-august-2026/)).
Karta toxunmaq brawler-i SEÇMİR — onun **səhifəsini** açır; seçim oradakı sarı
düymə ilədir. Bizdə üç növ var, ona görə axtarış və sürüşdürmə lazım deyil;
Brawler Blast və Fame-in arxasında sistem yoxdur, ona görə onlar da yoxdur.

### Kolleksiya (1280×720)

| | Ölçü | Nə var |
|---|---|---|
| Kart | 280×400, ara 30, ortada | Codex portreti kartın bütün üzündə; sol yuxarıda **sinif nişanı** (ikon + ad); altda ad (32 px) və «SUPER · …» |
| Seçilmiş kart | sarı kontur 5 px, `1.035` miqyas | Yuxarı-sağda sarı **SEÇİLİB** etiketi — rəng tək başına kifayət etmir |
| GERİ | sol aşağı | Səhifədən kolleksiyaya, kolleksiyadan ana ekrana — pillə-pillə |

**Kartın rəngi SİNFİN rəngidir.** Brawl Stars-da rəng nadirliyi deyir; bizdə
nadirlik yoxdur (hər növ əvvəldən açıqdır), ona görə rəng oyun tərzini deyir:

| Növ | Sinif | Rəng | İkon |
|---|---|---|---|
| KİRPİKLİ | **CƏLD** | kəhrəba `GERM_COLORS[3]` | sürət oxu |
| AYAQLI | **NƏZARƏTÇİ** | bənövşəyi `GERM_COLORS[4]` | tor |
| AMÖB | **MÜDAFİƏÇİ** | göy `GERM_COLORS[6]` | qalxan |

Portretin künclərini şəklin özü kəsir (`process.gd`, `card` rejimi): TextureRect
künc kəsə bilmir, `clip_children` isə mobil (Compatibility) renderdə etibarsızdır.
Portret kartın üzünün dəqiq nisbətindədir — `274:387` (bax `MenuV2.CARD_ASPECT`).

### Növün səhifəsi

| Zona | Nə var |
|---|---|
| Sol | Böyük portret (360 en) + aşağı-sağ küncündə **«OYUNDA»** pəncərəsi — canlı `GermVisual`. İllüstrasiya oyundakı görünüşü əvəz etməsin: oyunçu matçda nəyi idarə edəcəyini seçmədən görür |
| Sağ yuxarı | Ad (54 px), sinif nişanı, bir cümləlik təsvir |
| Sağ orta | **Dörd göstərici** — zolaq + faiz |
| Sağ aşağı | Super bloku: Codex ikonu, «SUPER · AD», nə etdiyi |
| Sağ-aşağı künc | Sarı **SEÇ** (OYNA-nın yeri və rəngi); artıq seçilibsə yaşıl, sönük **SEÇİLİB** |

**Göstəricilər uydurulmur** — hamısı `Const`-un növ əmsallarındandır, əmsal
dəyişəndə səhifə özü dəyişir. Brawl Stars-da can, zərər, super rəqəmləri var;
bizdə DÖYÜŞ riyaziyyatı hər növdə eynidir, fərq mühitlədir:

| Göstərici | Mənbə | Kirpikli | Ayaqlı | Amöb |
|---|---|---|---|---|
| SÜRƏTLƏNMƏ | `SPECIES_THRUST` | 135% | 100% | 85% |
| ÜST SÜRƏT | `SPECIES_SPEED` | 100% | 95% | 100% |
| AXINA DÖZÜM | `1 / SPECIES_FLOW` | 87% | 182% | 100% |
| DAR YERDƏN KEÇİD | `1 / SPECIES_BODY` | 100% | 100% | 128% |

100% zolağın **yarısıdır**: yarıdan uzun zolaq "orta mikrobdan yaxşı", qısa
zolaq "ondan zəif" oxunur. Superin mətni də rəqəmləri `Const`-dan götürür
(`NET_TIME`, `NET_SLOW`, `CYST_TIME`, `TRICHO_COST`).

---

## 7. SVG qaydaları

> ⚠️ **SVG-də `<text>` elementi işlətmə.** Godot SVG-ni ThorVG ilə rasterləşdirir,
> ThorVG isə mətn elementlərini **sükutla atır** — heç bir xəta vermir, sadəcə
> yazı görünmür.
>
> Loqodakı "GERM ARENA" yazısı məhz buna görə SVG-də yox, kodda çəkilir:
> [`main_menu.gd → _make_logo()`](../game/scripts/client/main_menu.gd).

Digər qaydalar:

- **Tək rəngli sprite + `modulate`.** Atılan top (`shot_ball.svg`) və partlama
  (`burst.svg`) ağ-boz çəkilib, rəngi kodda verilir. Belə olanda 10 rəng üçün
  bir tekstura bəs edir və hamısı bir çəkiliş çağırışına yığılır.
- **Radius sprite-da sabit.** `mucus_blob.svg`-də ləkənin radiusu 120 px-dir;
  kod `scale = radius / 120` ilə ölçüləndirir. Bu rəqəm dəyişsə kod da dəyişməlidir.
- **Haşiyə üçün yer saxla.** Parlaq haşiyə sprite-ın kənarına toxunmamalıdır,
  əks halda miqyaslananda kəsilir.
- **Kəskin kənar sprite-da, yumşaq kənar kodda ALINMIR.** `draw_circle` həmişə
  kəskin kənar verir; buluda oxşayan hər şey qradiyentli sprite olmalıdır.
  Əksinə, sayı və sürəti oyun vəziyyətindən asılı olan hər şey (damcılar,
  dalğalar) kodda çəkilməlidir. `burst.svg` məhz bu bölgüyə görə yalnız
  buluddan ibarətdir.

---

## 8. Assetlərin siyahısı

Hamısı `design/` altındadır və oradan `game/assets/`-ə kopyalanır.

> **Xəritə V1-dən bəri SVG deyil** — `map/` atlası (§4c). Aşağıdakı `mucus_*` və
> `dish_floor` SVG-ləri oyunda işlənmir; SVG dövründə kətan 320², ləkənin
> radiusu 120 idi və aradakı boşluq bişmiş kölgə üçün idi.

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `map/map_atlas.png` + `.json` | 2048² | Bütün maneələr (L 512² / S 256² hüceyrə), kölgə, burulğan, qırıntı, dalğa, sıçrantı, bəzək; mipmap-lı, itkisiz |
| `map/map_floor.png` | 1024² | Döşəmənin makro tonu, künclər şəffaf, sediment zolaqları bişib |
| `map/map_floor_detail.png` | 1024² | 400 dünya px-lik tikişsiz detal, boz, orta 0.5 |
| `map/map_rim.png` | 1024×256 | Şimal şüşə divarının zolağı, üfüqi tikişsiz |
| `map/map_props.png` | 512² | Qabın bayırındakı bulanıq koloniyalar (4 hüceyrə) |

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `sprites/food_ball.svg` | 32² | Kodda `scale 0.85` |
| `sprites/shot_ball.svg` | 36² | `modulate` ilə rənglənir |
| `sprites/mucus_blob.svg` | 320² | İşlənmir (V1-dən əvvəlki selik) |
| `sprites/spark.svg` | 64² | Dəymə/udma qığılcımı |
| `sprites/burst.svg` | 256² | Partlayış BULUDU (yalnız yumşaq qradiyent), `modulate` ilə rənglənir |
| `ui/joystick_base.svg` | 220² | Üzən joystickin bazası |
| `ui/joystick_knob.svg` | 96² | Joystickin başlığı |
| `ui/button_primary.svg` | 480×110 | İçi tünd — mətn kodla üstünə yazılır |
| `ui/button_secondary.svg` | 480×110 | Eyni, sönük variant |
| `ui/panel.svg` | 480×300 | Nəticə lövhəsi üçün çərçivə |
| `ui/logo.svg` | 600×220 | YALNIZ nişan, yazısız |
| `ui/app_icon.svg` | 512² | `game/icon.svg` ilə eynidir; menyuda oyunçu nişanının avatarıdır |
| `sprites/dish_floor.svg`, `mucus_crust2/3.svg`, `mucus_bush_top.svg`, `mucus_vent_swirl.svg` | 320–512² | İşlənmir (V1-dən əvvəlki döşəmə, qabıq mərhələləri, tac, burulğan) |
| `ui/gear.svg` | 32² | Ayarlar. Simvol (`⚙`) DEYİL — o, şriftdə yoxdur |
| `ui/species_ciliate.svg` | 64² | Növ kartının silueti — yatıq oval + kirpik + qamçı |
| `ui/species_heliozoan.svg` | 64² | Növ kartının silueti — radial şüalar |
| `ui/species_amoeba.svg` | 64² | Növ kartının silueti — yumrulanmış üçbucaq |

> Üç siluet **ağ** çəkilib və kartda `modulate` ilə boyanır: seçilən laym,
> qalanları sönük. Formaları qəsdən bir-birindən uzaqdır — 36 pikseldə oxşar
> iki nişan eyni ləkəyə dönür (ilk variantda kirpikli də radial idi və
> ayaqlıdan seçilmirdi).

Top atma düyməsinin ([`fire_button.gd`](../game/scripts/client/fire_button.gd))
diski, halqası və soyuma qövsü kodla çəkilir — oyunçunun rəngini və sursat
vəziyyətini göstərməli olduğu üçün. Ortadakı ikon və nişan alanda barmağın
altındakı baş isə **Codex ilə çəkilib** (PNG), dünyadakı nişan xəttinin oxu və
avtomatik nişanın kilid çərçivəsi də ([`aim_guide.gd`](../game/scripts/client/aim_guide.gd)).
Dördü də **ağ-boz** çəkilib və `modulate` ilə oyunçunun rənginə boyanır — yuxarıdakı
növ siluetləri kimi. Rəngli çəkilsəydilər, hər oyunçu rəngi üçün ayrı fayl lazım olardı.

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `ui/hud_fire.png` | 256² | Atəş düyməsinin ikonu — uçan top və üç sürət cizgisi |
| `ui/hud_aim_knob.png` | 256² | Nişan başı — nişangahlı disk, barmağın ardınca gedir |
| `ui/hud_target.png` | 256² | Kilid çərçivəsi — dörd künc, ortası BOŞ (rəqib görünür) |
| `ui/hud_aim_arrow.png` | 256² | Nişan xəttinin ucu — sağa baxan şevron |

Mənbə və promptlar: [`menu_art/`](menu_art/) (`brief/BRIEF_AIM.md`, `brief/PROMPTS_AIM.md`).
