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

## 2. İki mikrob növü

Dünyada **iki növ** var. İkisi eyni gövdəni bölüşür; fərq yalnız
**hərəkət orqanındadır** — və hər ikisi real protist anatomiyasından götürülüb.

| | **Kirpikli** (CILIATE) | **Ayaqlı** (HELIOZOAN) |
|---|---|---|
| Model | paramesium | "günəş heyvancığı" |
| Hərəkət orqanı | perimetr boyu **kirpiklər** + arxada **qamçı** | şüa kimi çıxan **aksopodiyalar** |
| Necə gedir | suda **üzür** | dibdə **yeriyir** |
| Gövdə | yumşaq kisə — çox titrəyir, sürətdə dartılır | bərk, mineral skeletli — az titrəyir, dartılmır |
| Daxili maye | hərəkətdən **geri qalır** (ətalət) | öndəki ayağa **axır** (*fəvvarə axını*) |

Daxili axının istiqaməti QƏSDƏN əksdir: biri sürüklənir, digəri özünü çəkir.
Ən incə, amma iki növü ən güclü ayıran işarə budur.

> **Növ oyuna təsir etmir.** İki mikrob eyni sürətlə gedir, eyni radiusa
> malikdir, eyni qaydalarla ölür. Fərq yalnız gözdədir.

### Növü oyunçu seçir

Menyudakı **NÖV** düyməsi iki növ arasında keçir; seçim `settings.cfg`-də
saxlanılır və dünyaya girərkən bir dəfə serverə göndərilir. Botların növü
təsadüfidir, ona görə dünyada hər ikisi görünür.

Seçim şəbəkəyə **bir bayt da** əlavə etmir. Səbəb: növ ayrıca sahə kimi yox,
toxunulmazlıq bayrağının **boş bitinə** yerləşdirilib.

| Bit | Məna |
|---|---|
| 1 | doğuş qalxanı aktivdir |
| 2 | mikrob ayaqlı növdəndir |

Həmin sahə əvvəl yalnız 0/1 daşıyırdı, yəni qalan bitləri boş yatırdı. Sətir
hər mikrob üçün saniyədə 30 dəfə gedir və Variant massivində hər ədəd 9 bayt
tutur — ayrıca sahə açmaq real qiymətdir, boş bit isə pulsuzdur.

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

### İki qayda ki, olmasa yeriş dağılır

**1. Ayaqların çoxu hər an yerdə olmalıdır.** Əks halda hərəkət yeriş yox,
sıçrayışdır. Bu, ümid deyil — `lift_budget()` eyni anda havada ola bilən
ayaqların sayını məhdudlaşdırır (sayın yarısından bir az az).

**2. Növbə ən GECİKMİŞ ayağa verilir.** İndeks sırası ilə verilsəydi birinci
ayaq həmişə qabağa keçər, sonuncu isə gözləyə-gözləyə həddindən artıq dartılardı.

Hər iki qayda [`SimTest._test_heliozoan_gait`](../game/scripts/tools/sim_test.gd)
ilə qorunur. Test təsadüfi deyil: **birinci qaydanın pozulmasını ekran görüntüsü
tapa bilmir** — mikrob yerindən tərpənəndə bütün ayaqların bir anda qalxması bir
kadrlıq hadisədir. Səhv məhz testlə tapıldı.

---

## 4. Forma dili

| Obyekt | Forma | Niyə |
|---|---|---|
| Kirpikli mikrob | titrəyən dairə + tük haşiyəsi | yumşaq, suda üzür |
| Ayaqlı mikrob | sakit dairə + şüa ayaqlar | bərk, dibdə yeriyir |
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
