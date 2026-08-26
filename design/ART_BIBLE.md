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
| `DISH` | `#0C1A1E` | Qabın döşəməsi |
| `DISH_EDGE` | `#1E4650` | Şüşə kənar (8 px qalınlıqda halqa) |
| `GRID` | `#122A31` | Döşəmə şəbəkəsi və məsafə halqaları |
| `MUCUS` / `MUCUS_EDGE` | `#16333B` / `#245562` | Selik ləkələri (maneə) |

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

> **Növ oyuna təsir etmir.** Üç mikrob eyni sürətlə gedir, eyni radiusa
> malikdir, eyni qaydalarla ölür. Fərq yalnız gözdədir.

### Növü oyunçu seçir

Menyudakı **NÖV** düyməsi növlər arasında növbə ilə keçir; seçim `settings.cfg`-də
saxlanılır və dünyaya girərkən bir dəfə serverə göndərilir. Botların növü
təsadüfidir, ona görə dünyada hər üçü görünür.

Seçim şəbəkəyə **bir bayt da** əlavə etmir. Səbəb: növ ayrıca sahə kimi yox,
toxunulmazlıq bayrağının **boş bitinə** yerləşdirilib.

| Bit | Məna |
|---|---|
| 0 | doğuş qalxanı aktivdir |
| 1–2 | növün nömrəsi (0..3) |

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
4. **Psevdopodiya** — nişan istiqamətindəki kiçik çıxıntı: mikrobun hansı tərəfə
   atacağını göstərir.
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

### Hələ yoxdur: konus (enli baş, nazik quyruq)

Həqiqi amöbin ön ucu enli (lamellipodium), arxa ucu nazikdir (uropod). Bizim
gövdədə ön və arxa en **bərabərdir** (20 / 20 px). Disklərin radiuslarını
dəyişməklə sınandı — siluet yaxşılaşdı, amma sahənin qorunması pozuldu
(6% → 29%), ona görə geri qaytarıldı. `SimTest._check_crawl` bu boşluğu
`[qeyd]` sətri ilə açıq saxlayır: uydurma hədd qoyub "keçdi" yazmaqdansa
çatışmazlıq görünsün.

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

Amöbdə **kirpik, ayaq və kənarda heç bir çıxıntı yoxdur**. Nişan istiqaməti də
ayrıca parlaq düymə ilə göstərilmir (digər iki növdə göstərilir): gövdənin öz
silueti o tərəfə bir qabarıq verir. Kənarda çəkilən düymə gövdədən qopmuş ləkə
kimi oxunurdu və istəmədən "ayaq" təsiri yaradırdı.

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
| Maneə | böyük tünd ləkə, ləkəli səth | fon qatındandır, ön plana çıxmır |
| Partlama | bulud + üç dalğa + damcılar + membran parçaları | maddə itmir, ətrafa yayılır |
| Suda zərrəcik | qısa cizgi, axın istiqamətində | qab MAYE ilə doludur |

Rəng korluğu üçün əsas ayırd etmə formadadır: qida HƏMİŞƏ kiçik və solğun-yaşıl,
mikrob HƏMİŞƏ böyük və titrəyən, maneə HƏMİŞƏ hərəkətsiz və tünddür.

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
| Say | 110 | Çoxu fonu "qar" kimi göstərir və mikrobların oxunmasına mane olur |
| Rəng | `DISH_EDGE` → `TEXT` 30%, alfa 0.55 | Sönük olsa qat boş yerə hesablanır, parlaq olsa mikroblarla yarışır |
| Cizgi | axın sürəti × 0.85 s | Qısası nöqtəyə bənzəyir, uzunu yağış kimi görünür |
| Sahə | kameranın ətrafında ± 0.8 × ekran eni | Kənara çıxan zərrəcik əks tərəfdən qayıdır: sabit sıxlıq, sabit yaddaş |

Bütün qat **bir** `draw_multiline` çağırışıdır.

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

| Fayl | Ölçü | Qeyd |
|---|---|---|
| `sprites/food_ball.svg` | 32² | Kodda `scale 0.85` |
| `sprites/shot_ball.svg` | 36² | `modulate` ilə rənglənir |
| `sprites/mucus_blob.svg` | 256² | Ləkə radiusu 120 |
| `sprites/spark.svg` | 64² | Dəymə/udma qığılcımı |
| `sprites/burst.svg` | 256² | Partlayış BULUDU (yalnız yumşaq qradiyent), `modulate` ilə rənglənir |
| `ui/joystick_base.svg` | 220² | Üzən joystickin bazası |
| `ui/joystick_knob.svg` | 96² | Joystickin başlığı |
| `ui/button_primary.svg` | 480×110 | İçi tünd — mətn kodla üstünə yazılır |
| `ui/button_secondary.svg` | 480×110 | Eyni, sönük variant |
| `ui/panel.svg` | 480×300 | Nəticə lövhəsi üçün çərçivə |
| `ui/logo.svg` | 600×220 | YALNIZ nişan, yazısız |
| `ui/app_icon.svg` | 512² | `game/icon.svg` ilə eynidir |

Top atma düyməsi ([`fire_button.gd`](../game/scripts/client/fire_button.gd)) hazırda
kodla çəkilir — oyunçunun rəngini və sursat vəziyyətini göstərməli olduğu üçün.
Sprite-a keçirilsə, rəng `modulate` ilə verilməlidir.
