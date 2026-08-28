class_name GermVisual
extends Node2D

## Top membranı YARDI. Səs məhz bu anda çalınmalıdır, atəş anında yox —
## gecikmə mikrobun ölçüsündən asılıdır (bax [method eject]).
signal broke_through(local: bool)

## Ekranda bir mikrob. ÜÇ NÖV var — hamısı eyni gövdəni bölüşür,
## fərq yalnız HƏRƏKƏT ORQANINDADIR.
##
## Burada heç bir oyun məntiqi yoxdur — yalnız verilən vəziyyəti çəkir.
## Bütün qərarlar serverdə, bütün proqnoz [Sim]-dədir. Növ oyuna TƏSİR ETMİR:
## iki mikrob eyni sürətlə gedir, eyni radiusa malikdir. Fərq yalnız gözdədir.
##
## ── Niyə sprite deyil ────────────────────────────────────────────────────
## Mikrobun ölçüsü TUTUMDAN, içindəki topların sayı isə MÖVCUD SAYDAN asılıdır.
## İkisi də oyun boyu dəyişir (tutum 10 → 60, top 0 → 60), ona görə hazır şəkil
## uyğun deyil. Növlər də hazır kadr ardıcıllığı ilə çəkilə bilməzdi: ayaqların
## addımı mikrobun HƏQİQİ sürətindən özü çıxır (bax [method _walk]).
##
## ── Üç növ ───────────────────────────────────────────────────────────────
##
## **CILIATE — kirpikli** (paramesium modeli). Bədəni yumşaq kisədir, suda
## ÜZÜR: perimetr boyu kirpiklər metaxronal dalğa ilə döyünür, arxada qamçı
## qamçılanır, gövdə sürətə görə dartılır. İçindəki maye hərəkətdən GERİ
## QALIR — ətalət.
##
## **HELIOZOAN — ayaqlı** ("günəş heyvancığı"). Bədəni bərkdir, YERİYİR:
## gövdədən şüa kimi çıxan **aksopodiyalar** (mikroborucuq özəkli sərt
## ayaqlar) növbə ilə yığılıb-uzanır. Heliozoa məhz belə hərəkət edir —
## aksopodların uzunluğunun idarə olunan dəyişməsi ilə. İçindəki maye isə
## ÖNƏ AXIR (*fəvvarə axını*): sitoplazma öndəki ayağa tökülür və gövdəni
## dalınca çəkir.
##
## **AMOEBA — sürünən**. Sabit forması YOXDUR: kənarın özü hərəkət orqanıdır.
## İki qatlı gövdə (jel qabıq + axıcı iç) ön tərəfə uzanır, arxadan yığılır və
## sahəsini saxlayaraq irəli axır (bax [method _crawl_body]). Nə kirpiyi var,
## nə ayağı — yalnız kənarı.
##
## Daxili axının istiqaməti QƏSDƏN fərqlidir: kirpikli sürüklənir, ayaqlı
## özünü çəkir, amöbdə isə axının özü hərəkətin mexanizmidir. Ən incə,
## amma ən güclü fərqləndirici işarə budur.
##
## Növ RƏNGDƏN çıxarılır (bax [method species_of]) — snapshot-a bir bayt da
## əlavə olunmur.
##
## Oyunçu bir baxışda üç şeyi görməlidir:
##   1. Nə qədər doluyam        → membranın gərginliyi (öz dəqiq sayın HUD-dadır)
##   2. Rəqib partlamağa yaxındırmı → membranı bərk titrəyir və qırmızıya çalır
##   3. Kim mənəm               → kamera HƏMİŞƏ sənin mikrobunun üstündədir
##
## Mikrobun ətrafında HALQA YOXDUR — nə doluluq, nə fokus halqası. Hər ikisi
## vardı və hər ikisi çıxarıldı: mikrobu konsentrik halqaların içinə salırdılar
## və kirpiklər, ayaqlar, qamçı onlarla yarışırdı.
##
## Əvəzinə hər ikisinin işini onsuz da mövcud olan bir şey görür:
##   • doluluq → membranın öz gərginliyi (dəqiq rəqəm HUD-dadır);
##   • "bu, mənəm" → kamera. Öz mikrobun həmişə ekranın mərkəzindədir,
##     adı da parlaq yazılır (rəqiblərinki sönükdür).

## Membran çoxbucaqlısının nöqtə sayı. 24 kifayətdir: kiçik ekranda fərq
## görünmür, amma çəkiliş yükü iki dəfə azdır.
const MEMBRANE_POINTS := 24
const NAME_OFFSET := 22.0

## Halqaların membrandan uzaqlığı.
##
## Rəqəmlər kirpiklərin uzunluğundan (≈ r × 0.20, ən çoxu 10 px) BÖYÜK
## seçilib. Əks halda halqa kirpiklərin düz ortasından keçir və ikisi də
## oxunmaz olur — ilk versiyanın səhvi məhz bu idi.
##
## Yalnız BİR halqa qalıb və o da nadirdir: doğuş qalxanı yalnız ilk bir
## neçə saniyədə görünür. Ona görə mikrobun ətrafı təmizdir.
const SHIELD_GAP := 25.0            ## doğuş qalxanı

## Sürətə görə dartılma həddi. 0.16 = ən sürətli halda 16% uzanır.
## Daha çox olsa mikrob damcıya dönür və toqquşma radiusu ilə uyğunsuzluq
## gözə çarpır — membran gerçək radiusdan uzaqda görünür.
const STRETCH_MAX := 0.16

# ---------------------------------------------------------------- CILIATE
## Kirpiklər. Say radiusdan asılıdır, amma hədlər var: azı oxunmaz,
## çoxu isə telefonda bir-birinə qarışıb tük yumağına dönür.
const CILIA_MIN := 18
const CILIA_MAX := 30
## Halqa boyunca neçə tam dalğa qaçır. 3 seçilib: 1 çox yavaş görünür,
## 5-də qonşu kirpiklər əks istiqamətə baxıb titrəyiş kimi oxunur.
const CILIA_WAVES := 3.0
const CILIA_BEAT := 7.0             ## döyüntü tezliyi (rad/saniyə)
## Qamçının nöqtə sayı və uzunluğu (radiusa nisbətdə).
const TAIL_POINTS := 9
const TAIL_LENGTH := 1.5

# ---------------------------------------------------------------- HELIOZOAN
## Ayaq sayı. Kirpikdən qat-qat azdır: ayaq AYRICA oxunmalıdır, kirpik isə
## kütlə kimi. 13-dən çoxunda gövdə ulduza dönür və addım seçilmir.
const LEGS_MIN := 7
const LEGS_MAX := 13
## Ayağın normal uzaqlığı (radiusa nisbətdə).
##
## Halqalardan (ən uzağı r + 25) KƏNARDA olmalıdır — ilk versiyada 1.55 idi
## və kiçik mikrobda pəncələr düz halqaların üstünə düşürdü.
##
## 2.15 də çox oldu: ayaqlar qonşu mikrobun üstünə uzanırdı (mikroblar
## bir-birindən yalnız radiusları qədər aralanır) və "başqasına ilişmiş"
## kimi görünürdü. 1.75 həm gövdədən aydın kənardadır, həm qonşuya çatmır.
const LEG_REACH := 1.75
## Bir ayaq ən çox bu qədər saniyə yerində qala bilər.
##
## Bu olmadan yavaş gedən (və ya dayanan) mikrobun ayaqları HEÇ VAXT
## addımlamırdı: gövdə addım məsafəsini keçmirdi, ayaqlar isə donmuş ulduz
## kimi qalırdı. Real aksopod fasiləsiz yenidən qurulur — dayanan heliozoa da
## ayaqlarını dəyişir. Hədd keçiləndə ayaq növbəyə düşür, təzədən basılır.
const LEG_HOLD_MAX := 1.1
## Yerə basılı ayağın ortasındakı yüngül əyilmə (radiusa nisbətdə).
## Pəncə TƏRPƏNMİR — yalnız ayağın gövdəsi dalğalanır, ona görə bu, sürüşmə
## yaratmır, sadəcə donmuş çubuq təsirini aradan qaldırır.
const LEG_SWAY := 0.07
## Pəncə "ev" nöqtəsindən bu qədər (radiusa nisbətdə) uzaqlaşanda yeni addım
## atılır. Kiçik olsa mikrob titrəyir, böyük olsa ayaqlar dartılıb qopmuş görünür.
const LEG_STRIDE := 0.85
## Havadakı ayağın sürəti — mikrobun TEMPİNƏ görə (1 / gedilən radius).
##
## ── Niyə saniyə ilə ölçülə bilməz ────────────────────────────────────────
## Əvvəl sabit 12 / saniyə idi və böyük mikrobda yeriş donurdu. Səbəb: addımın
## uzunluğu radiusla böyüyür, yellənmənin müddəti isə sabit qalırdı. Tutum
## 60-da hər ayaq vaxtının **91%-ni yerdə** keçirirdi və qalan 9%-də 73 pikseli
## bir göz qırpımında qət edirdi — ekranda donmuş ulduz, arada bir çırpınma.
##
## Templə ölçüləndə yük dövrü (duty cycle) ölçüdən ASILI OLMUR: hər ayaq həm
## kiçik, həm böyük mikrobda vaxtının təxminən 40%-ni havada keçirir.
## Qoruyucu: `SimTest._check_gait` (hər ayağın ayrıca yük dövrünü ölçür).
const LEG_SWING_PACE := 3.3
## Dayanan mikrobda temp sıfırdır — yellənmə bu sürətlə tamamlanır (1/saniyə).
const LEG_SWING := 4.0
## Addımın ortasında ayaq bu nisbətdə YIĞILIR. Heliozoa məhz belə yeriyir:
## aksopod qısalır, yeni yerə uzanır. Yana əyilmə DEYİL, uzunluq dəyişməsi —
## üstdən baxışda "sürünmə" yox, "addım" oxunur.
const LEG_TUCK := 0.55

# ---------------------------------------------------------------- AMOEBA
## Amöbin konturunun nöqtə sayı. Digər növlərdən İKİ DƏFƏ ÇOXDUR və bu,
## səliqə məsələsi deyil: onlarda kənar yalnız yüngül titrəyir, burada isə
## kənarın ÖZÜ hərəkət orqanıdır — 24 nöqtə ilə ön uc kəsik-kəsik uzanır və
## gövdə yumşaq kisə yox, çoxbucaqlı daş kimi oxunur. Referansdakı silueti
## verən şey məhz kənarın hamarlığıdır.
const CRAWL_POINTS := 44
## Ləçəklərin dərinliyi. Böyük olsa gövdə ulduza dönür, kiçik olsa dairəyə.
const CRAWL_LOBE := 0.115
## Kənar boyunca ARXADAN ÖNƏ qaçan dalğanın dərinliyi və perimetr boyu
## neçə dalğa yerləşdiyi.
##
## Bu, sürünmənin gözlə görünən hissəsidir: ön ucun uzanması hərəkəti yaradır,
## bu dalğa isə onu oxunaqlı edir — kənar "yaxıla-yaxıla" irəli axır. Olmasa
## amöb sadəcə uzanıb-yığılan ləkədir.
const CRAWL_FLOW_DEPTH := 0.10
const CRAWL_WAVES := 2.5
## Nişan istiqamətindəki daimi çıxıntı (psevdopodiya). Sürətdən ASILI DEYİL:
## amöb atəş açacağı tərəfə həmişə bir ayaqcıq uzadır, ona görə hədəf
## istiqaməti dayananda da oxunur.
##
## Bu çıxıntı gövdənin ÖZ silueti ilə verilir, kənarda ayrıca nöqtə ilə yox:
## digər iki növdə istiqaməti göstərən parlaq düymə var, amöbdə isə o düymə
## gövdədən qopmuş ləkə kimi oxunurdu (referansda belə bir şey yoxdur).
const CRAWL_AIM_BULGE := 0.10
## Eyni çıxıntı, YUMŞAQ gövdə üçün (kirpikli).
##
## Amöbdəki [constant CRAWL_AIM_BULGE] ilə eyni işi görür və eyni səbəbdən
## siluetlə verilir: kənardakı parlaq düymə "gövdəyə ilişmiş top" kimi oxunurdu.
## Daha kiçikdir (0.07), çünki kirpiklinin membranı onsuz da titrəyir — böyük
## çıxıntı titrəyişlə qarışıb formanı dalğalı göstərirdi.
##
## AYAQLIDA YOXDUR və bu, unudulma deyil: onun gövdəsi mineral skeletlidir
## (bax `ART_BIBLE` §2) — bərk qabıq nişan tərəfinə uzana bilməz. Orada
## istiqaməti yalnız atəş anındakı dartılma göstərir.
const SOFT_AIM_BULGE := 0.07
## Tam sürətdə saniyədə neçə sürünmə dövrü tamamlanır.
## Bir addım ≈ 1 saniyə: amöb tələsmir, uzanma-yığılma gözlə izlənə bilməlidir.
const CRAWL_RATE := 0.75
## Dövr dayananda nə qədər yavaşıyır və gedəndə nə qədər sürətlənir
## (bax [member _crawl_t]). Dayanan amöb tam donmur — sitoplazma axmaqda
## davam edir — amma dövr hərəkətin sürətindən çıxır.
const CRAWL_IDLE_RATE := 0.35
const CRAWL_MOVE_RATE := 1.0
## Arxa uc (uropod) yerə basılandan sonra gövdə ondan nə qədər uzaqlaşanda
## buraxılır — RADİUSA nisbətdə. Bir sürünmə addımının uzunluğu budur.
##
## ── Bütün məsələnin düyünü buradadır ─────────────────────────────────────
## Dövr əvvəl VAXTLA sürülürdü (saniyədə ~1 dövr). Mikrob isə saniyədə 3.4
## gövdə uzunluğu qət edir — yəni bir "addımda" 3.4 gövdə boyu sürüşürdü.
## Forma nə qədər düzgün deformasiya etsə də nəticə sürünmə yox, SÜRÜŞMƏ
## oxunurdu: deformasiya yerdəyişmə ilə sinxron deyildi.
##
## Animasiyada bunun adı var — *foot sliding*. Ayaqlı növdə həmin nasazlıq
## həndəsə ilə həll olunub (bax [method _walk]): pəncə yerə basılır və gövdə
## ondan uzaqlaşana qədər tərpənmir, ona görə addımın tezliyi HƏQİQİ sürətdən
## özü çıxır. Amöbdə də eyni prinsip işlədilir: uropod yerə basılır, gövdə
## ondan bu qədər uzaqlaşanda buraxılır. Nəticədə dövrün tezliyi heç yerdə
## yazılmır — sürətdən özü çıxır.
## Qoruyucu: `SimTest._test_amoeba_crawl`.
const CRAWL_RELEASE := 2.30
## Buraxılandan sonra uropod gövdənin bu qədər arxasına basılır.
const CRAWL_SEAT := 0.30
## Psevdopodiyanın uzanması dartılmanı nə qədər tez izləyir və buraxılanda nə
## qədər tez yığılır — vahid **1 / gedilən radius**, saniyə YOX.
##
## Yığılma uzanmadan XEYLİ TEZ olmalıdır: uzanma bütün dövrə yayılır, yığılma
## isə bir anda baş verir. Gözlə görünən "atılma" məhz bu fərqdir — bərabər
## olsaydı dövr sinusa çevrilərdi, sinus isə həmişə nəfəs alma kimi oxunur.
##
## ── Niyə saniyə ilə ölçülmür ─────────────────────────────────────────────
## Sürünmədə qalan SON vaxt sabiti bunlar idi və ölçüləndə üzə çıxdı: böyük
## mikrob yavaş gedir, həndəsə isə sabit templə dəyişirdi, yəni forma
## yerdəyişmədən tez dəyişirdi. Nəticədə buraxılış anında gövdə bir kadrda
## azacıq GERİ sürüşürdü (−0.11 px). Gözlə görünmürdü, amma sürünən heç nə
## geri getməməlidir. Qoruyucu: `SimTest._check_crawl`.
const CRAWL_PUSH := 0.45
const CRAWL_PULL := 1.6
## Dayanan mikrobda temp sıfırdır — forma bu ən aşağı sürətlə sakitləşir.
const CRAWL_SETTLE := 0.8
## Sürətə uyğunlaşma templəri — dayanan amöb yerində addımlamamalıdır.
const CRAWL_FLOW_RATE := 5.0
## Ön psevdopodiyanın və arxa ucun (uropod) gövdə mərkəzindən ən çox
## uzaqlaşması — radiusa nisbətdə. Disklərin ARASINDAKI məsafədir,
## kənarın deformasiyası deyil (bax [method _crawl_body]).
const CRAWL_REACH := 0.88
const CRAWL_DRAG := 0.58
## Disklərin əsas radiusları (gövdə radiusuna nisbətdə): ön, orta, arxa.
## Orta disk ƏN BÖYÜKDÜR — kontur ondan çəkilir, ona görə mərkəz həmişə
## gövdənin içində qalmalıdır.
const CRAWL_HEAD := 0.86
const CRAWL_BODY := 0.94
const CRAWL_TAIL := 0.86
## Diskləri ayıranda hər birinin radiusu bu nisbətdə kiçilir.
##
## Uzanan gövdə nazilir — bu, artıq sahəni QORUMAQ üçün deyil (onu
## [constant CRAWL_AREA] normallaşdırması dəqiq həll edir), sadəcə formanın
## bir hissəsidir: ayrılan disklər nazik boyun verir.
const CRAWL_SLIM := 0.25
## Gövdənin sahəsi — toqquşma dairəsinin (`PI·r²`) bu qədər hissəsi.
##
## Bir azca kiçikdir: görünən gövdə toqquşma dairəsindən bayıra çıxmamalıdır,
## yoxsa oyunçu dəymədiyi yerdə dəyəcəyini gözləyir.
const CRAWL_AREA := 0.86

## Konusun dərəcəsi — "enli baş, nazik quyruq".
##
## Bu xassə uzun müddət YOX idi və iki cəhd nəyə görə alınmadığını burada
## saxlamağa dəyər, çünki hər ikisi məntiqli görünür:
##
## **1. Disklərin radiusları (0.86/0.86 → 0.98/0.66) — TƏSİRSİZ.**
## Gövdə TƏK mərkəzdən şüalarla qurulur: nöqtə `a` bucağında `rays[a]`
## radiusundadır, eni isə `rays[a]·sin a`. Bu ifadə maksimumunu həmişə
## mərkəzin yanında alır, disklərin radiusu nə olursa olsun. Disklər yalnız
## UZUNLUĞA təsir edir. Ölçüldü: ən enli kəsik −6%-dən −5%-ə tərpəndi.
## Orta diski önə sürmək (radiusun 45%-i qədər) da ancaq −1% verdi.
##
## **2. Şüaya `cos` əlavə etmək — TƏSİRSİZ.** `cos` maksimumunu burun
## ucunda (`a` = 0) alır, yəni burnu UZADIR, eni dəyişmir. Nisbət 1.06-dan
## 1.07-yə qalxdı; gücləndirəndə isə PİSLƏŞDİ (0.60-da 1.00), çünki uzanan
## burun gövdəni daha da nazik göstərir.
##
## **İşləyən: `cos·sin²`.** Maksimumu `a` ≈ ±55°-dədir — yəni ön YANLARDA.
## Ön yanlar şişir, arxa yanlar yığılır, burun və quyruq UCLARI isə
## toxunulmaz qalır (ikisində də `sin` sıfırdır). Konus məhz budur: en
## profili dəyişir, uzunluq yox. Nəticə: ön/arxa en nisbəti 1.39, ən enli
## kəsik mərkəzdən 6-8% ÖNDƏ.
##
## 0.45 seçilib. 0.65-də gövdə artıq uzana bilmir (en/boy 1.86) — ön yanlar
## o qədər şişir ki, uzanma oxunmaz olur. Qoruyucu: `SimTest._check_crawl`.
##
## YALNIZ hərəkətdə (`rush` ilə): dayanan amöbin qütbü yoxdur — real hüceyrə
## də dayananda polyarlığını itirir. Dayanan gövdənin ön-arxa fərqi həm də
## ayrıca testlə qadağandır: kamera öz mikrobunu mərkəzə mismarlayır, ona
## görə dayanan qeyri-simmetrik gövdə "yana yatıb" kimi oxunur.
##
## Sahəyə toxunmur — sonrakı normallaşdırma onu dəqiq oturdur. Məhz o
## normallaşdırma bu dəyişikliyi mümkün edib: ondan əvvəl siluetə toxunan
## hər cəhd sahənin qorunmasını pozurdu (6% → 29%).
const CRAWL_CONE := 0.45
## Dövr boyu arxa diskdən ön diskə keçən kütlə (radiusa nisbətdə).
## Sitoplazma axını budur: ön uc dolur, arxa uc boşalır.
const CRAWL_MASS := 0.13
## Disklərin birləşmə tikişi neçə dəfə hamarlanır. İki dairənin birləşməsi
## kəskin künc verir, canlı hüceyrədə isə belə künc olmur.
const CRAWL_SMOOTH := 3
## Uzananda gövdə getdiyi ox boyunca bu qədər dartılır və ona DİK istiqamətdə
## eyni əmsalla yastılaşır (sahə qorunur).
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Disklərin hərəkəti düzgün RİTM verir, amma tək başına düzgün SİLUET vermir:
## oyunda ölçdükdə gövdə ən çox uzananda belə eninə görə cəmi 1.6 dəfə uzun
## idi — yəni armud, sürünən hüceyrə yox. Diskləri daha da uzağa atmaq həlli
## deyildi: gövdə mərkəzdən (toqquşma dairəsindən) həddən artıq qopurdu.
##
## Dartılma isə eni AZALDIR, ona görə nisbəti ödəyir, mərkəzi qorumur —
## sadə miqyaslamadır. Bu, animasiyanın öz prinsipidir (*squash & stretch*);
## kirpikli növ onu artıq işlədir ([constant STRETCH_MAX]).
## Qoruyucu: `SimTest._check_crawl` (siluetin en/boy nisbətini ölçür).
const CRAWL_STRETCH := 0.24
## Gövdənin kütlə mərkəzi node-a nə qədər bərk bağlanır (0 = sərbəst, 1 = tam).
##
## ── Niyə lazımdır: kamera öz mikrobunu MİSMARLAYIR ───────────────────────
## Rəqiblər ekranda hərəkət edir, ona görə gövdənin salınması onların
## yerdəyişməsinə qarışır və sürünmə kimi oxunur. Öz mikrobun isə kameranın
## tam mərkəzindədir — onun ekranda YERDƏYİŞMƏSİ YOXDUR. Deməli görünən
## yeganə hərəkət gövdənin öz salınmasıdır.
##
## Ölçüldükdə mərkəz radiusun **60%-i** qədər (böyük mikrobda 49 piksel)
## irəli-geri sürüşürdü. Nəticə: mikrob irəli getmirdi, yerində ora-bura
## sürüşürdü — ekranda məhz "ilişib qalmaq" kimi. Səhv botlarda görünmürdü,
## ona görə uzun müddət gizli qaldı.
##
## Forma sərbəst qalır (siluetin en/boy nisbəti dəyişmir), yalnız mərkəz
## sabitlənir: sürünmə artıq gövdənin UCLARININ hərəkəti ilə oxunur — ön uc
## irəli atılır, arxa uc dartılır — kökün silkələnməsi ilə yox. Personaj
## animasiyasında qayda budur: kamera izləyəndə kök sakit, uclar işləkdir.
## Qoruyucu: `SimTest._check_crawl`.
const CRAWL_ANCHOR := 0.78
## Xarici jel zolağının (plazmagel) ENİ — radiusa nisbətdə, ən azı piksellə.
##
## En, nisbət deyil. Fərq gözlə görünür: daxili konturu sadəcə `r × 0.78` ilə
## çəkəndə zolaq ön ucda qalınlaşır, arxada nazilir (radius orada böyük,
## burada kiçikdir) və nəticə "qalınlığı gəzən haşiyə" olur. Referansdakı
## sarı zolaq isə hər yerdə eyni enlidədir — ona görə daxili kontur hər
## nöqtənin ÖZ normalı boyunca sürüşdürülür (bax [method _inset]).
const CRAWL_BAND := 0.24
const CRAWL_BAND_MIN := 6.5
## Orqanellaların yerləşdiyi dairənin radiusu (gövdəyə nisbətdə). Jel
## zolağının altından çıxmamalıdır — çıxan ulduz "içindəki top" oxunuşunu itirir.
const CRAWL_CORE := 0.56
## Qatların tünd konturu radiusa nisbətdə bu qədər qalındır (ən azı piksellə).
## Referansın oxunuşu bu xəttdən asılıdır: onsuz iki qat bir-birinə keçir.
const CRAWL_EDGE := 0.085
const CRAWL_EDGE_MIN := 2.6
## Ulduz orqanellaların uc sayı, iç radiusu və hansı saya qədər çəkilməsi.
## Hədd çəkiliş çağırışına görədir: hər ulduz konturu ilə birlikdə İKİ ayrıca
## çoxbucaqlıdır, dairələr isə bir yığına düşür.
# ---------------------------------------------------------------- ATƏŞ
## Topun membranı yardığı yerdə gövdənin nə qədər qabarması (radiusa nisbətdə).
const EJECT_DEPTH := 0.55
## Nübün yarım eni — TOPUN radiusuna nisbətdə.
##
## ── Niyə bucaqla yox, pikselə bağlıdır ───────────────────────────────────
## Əvvəl qabarma bucaq pəncərəsi ilə (`cos` üstlüyü) verilirdi və konturun
## radiusuna VURULURDU. Yumru gövdədə bu işləyir, uzun gövdədə isə yox:
## amöbin ön ləçəyi onsuz da uzundur, ona görə eyni nisbət nüb yaratmır,
## sadəcə ləçəyi bir az da böyüdür. Ölçüldükdə fərq açıq idi —
## kirpikli +18%, ayaqlı +27%, amöb cəmi +13%.
##
## Topun ölçüsü isə gövdədən ASILI DEYİL: 9 piksel radiuslu top hər hansı
## mikrobda eyni enində nüb açır. İtələmə də mütləqdir (radiusun payı),
## konturun yerli radiusuna vurulmur — nəticədə effekt hər üç növdə eynidir.
const EJECT_WIDTH := 1.7
## Pərdə yarıldıqdan sonra sakitləşmə müddəti (saniyə).
##
## ── Niyə uzundur ─────────────────────────────────────────────────────────
## Topun mərkəzdən divara qədər getdiyi vaxt cəmi 67 ms-dir (radius / SHOT_SPEED),
## yəni 60 kadrda 4 kadr. Ölçüldükdə zirvə cəmi İKİ kadr sürürdü — real oyun
## ölçüsündə (28 px radius) belə bir hadisə sadəcə görünmür.
##
## Yol vaxtını uzatmaq olmaz (oyun məntiqidir), ona görə oxunuşu SONRAKI
## hissə daşıyır: buraxılan pərdə geri çırpılır və sönən dalğa ilə sakitləşir.
## Animasiyada bu, *follow-through* prinsipidir — gözün tutduğu hissə odur.
const EJECT_SNAP := 0.30

const STAR_POINTS := 7
const STAR_INNER := 0.50
const STAR_MAX := 14

var color_index := 0
var germ_name := ""
var is_local := false
var species := Const.Species.CILIATE

var balls := Const.START_BALLS
var capacity := Const.START_CAPACITY
var aim := 0.0
## Super İNDİ işləyirmi — ayaqlıda tor açıqdır, amöbdə qabıq bağlıdır.
## Serverin bayrağından gəlir (bax [enum Const.GFlag]); görüntü qatı onu
## özü hesablamır, çünki rəqibin superini yalnız server bilir.
var super_on := false
var alive := true
var safe := false
## Partladı. [method apply] bundan sonra görüntünü geri qaytarmır — öz
## mikrobun hər kadr proqnozdan yenilənir, ona görə tək `visible = false`
## növbəti kadrda geri açılardı.
var burst := false

var _base := Color.WHITE
var _light := Color.WHITE
var _shadow := Color.BLACK
var _label: Label
var _t := 0.0

## Zərbə parıltısı — vurulan mikrob bir anlıq AĞARIR.
##
## Rəng qarışdırılmır, siluetin ÜSTÜNƏ ağ örtük çəkilir: belə gövdə,
## kirpik və içindəki toplar eyni anda itir, zərbə isə TƏK kadrda oxunur.
## Yarımşəffaf qarışdırma bunu bacarmır — dolu mikrobda içəridəki toplar
## ağın altından görünür və parıltı "duman" kimi oxunur.
##
## Örtük 1.0-dan PARLAQDIR (HDR): glow keçidi onu götürür və zərbə anında
## mikrob həqiqətən işıq saçır (bax [method Arena._build_glow]).
const FLASH_TIME := 0.18
var _flash := 0.0

## Donmuş kadr — öldürmə anında [Arena] qoyur (bax [method Arena._freeze]).
##
## YALNIZ animasiyanı dayandırır. Simulyasiya, proqnoz və şəbəkə işləməyə
## davam edir: `Engine.time_scale` ilə donduran variant client-i serverdən
## geri salardı, sonra isə düzəliş mikrobu sıçradardı.
var frozen := false
## Doluluq göstəricisi ani sıçramır — göz üçün yumşaq keçid.
var _shown_fill := 0.0

## Hərəkət yalnız MÖVQEDƏN çıxarılır — nə serverdən, nə proqnozdan sürət
## istənilmir. Səbəb: eyni node həm proqnozla (öz mikrobun), həm
## interpolyasiya ilə (rəqiblər) sürülür, mövqe fərqi isə hər ikisində
## eyni mənanı verir. Nəticədə görüntü qatı şəbəkə qatından tam ayrıdır.
var _last_pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _has_pos := false
## Daxili mayenin sürüşməsi. İstiqaməti NÖVDƏN asılıdır (bax [method _track_motion]).
var _core := Vector2.ZERO
## Sürünmə dövrünün öz saatı (yalnız AMOEBA).
##
## [member _t]-dən AYRIDIR, çünki o, divar saatıdır — sabit templə axır.
## Yalnız KƏNARIN öz dalğalanmasını sürür — sürünmə dövrünü YOX.
## Sürünmənin saatı həndəsədədir (bax [member _uropod]).
var _crawl_t := 0.0

## Arxa ucun (uropod) yerə basıldığı nöqtə — VALİDEYN fəzasında, ayaqlı növün
## pəncələri kimi (bax [member _foot]). Sürünmə dövrünün saatı elə budur:
## gövdə ondan [constant CRAWL_RELEASE] qədər uzaqlaşanda addım tamamlanır.
##
## Yerli koordinatda saxlansaydı gövdə ilə birlikdə sürüşərdi və dövr
## məsafəyə yox, vaxta bağlanardı — bütün problem məhz o idi.
## Atəşin yaşı (saniyə); mənfi = atəş yoxdur. [member _eject_span] topun
## mərkəzdən membrana qədər getdiyi ƏSL vaxtdır (bax [method eject]).
var _eject_t := -1.0
var _eject_span := 0.0
var _eject_dir := 0.0

var _uropod := Vector2.ZERO
var _uropod_set := false
## Uropodun istiqaməti, yumşaldılmış — buraxılış anında sıçramasın deyə.
var _tail_dir := Vector2.LEFT
## Psevdopodiyanın uzanması, 0..1. Dartılmanı yavaş izləyir, buraxılanda
## isə TEZ yığılır (bax [constant CRAWL_PUSH], [constant CRAWL_PULL]).
var _reach_out := 0.0
## Yumşaldılmış sürət, 0..1 — dayanan amöbin gövdəsi yumru qalsın deyə.
var _flow := 0.0

# ---------- ayaqların vəziyyəti (yalnız HELIOZOAN) ----------
## Pəncələr VALİDEYN fəzasında saxlanılır — [member Node2D.position] ilə eyni
## fəzada. Bu, təsadüfi deyil: yerə basılmış pəncə gövdə hərəkət edərkən
## OLDUĞU YERDƏ qalmalıdır. Bütün "yeriyir" hissi elə bundan ibarətdir —
## pəncə yerli koordinatda saxlansaydı gövdə ilə birlikdə sürüşərdi və
## nəticə yeriş yox, titrəyiş olardı.
var _foot := PackedVector2Array()
var _swing_from := PackedVector2Array()
var _swing_to := PackedVector2Array()
## 1.0 = yerə basılıb, 0..1 = havadadır.
var _step := PackedFloat32Array()
## Ayaq neçə saniyədir yerində durur (bax [constant LEG_HOLD_MAX]).
var _hold := PackedFloat32Array()
var _legs := LEGS_MIN
var _planted := false


## Eyni anda havada ola bilən ən çox ayaq — sayın yarısından BİR AZ AZ.
##
## Bu, bəzək deyil, yerişin TƏRİFİDİR: ayaqların çoxu hər an yerdə olmalıdır,
## əks halda hərəkət yeriş yox, sıçrayışdır. Budcə dolu olanda ayaq növbəsini
## gözləyir — bir az dartılır, sonra daha uzun addım atır.
##
## Yalnız faza yayımına güvənmək kifayət deyildi: mikrob yerindən tərpənəndə
## bütün ayaqlar hələ də eyni anda qalxa bilirdi. Budcə bu xassəni artıq
## TƏMİN EDİR, gözləmir. Qoruyucu: `SimTest._test_heliozoan_gait`.
static func lift_budget(legs: int) -> int:
	return maxi(1, (legs - 1) / 2)


## [param p_species] snapshot-dan gəlir ([constant Const.GFlag.HELIOZOAN]),
## öz mikrobun üçün isə menyudakı seçimdən. Rəngdən ÇIXARILMIR: növ artıq
## oyunçunun seçimidir, rənglə əlaqəsi yoxdur.
## Adı və rəngi sonradan dəyişir — reyestr snapshot-dan GEC gələ bilər.
##
## [method setup] mikrobu bir dəfə qurur, ona görə reyestr sonra çatanda ad
## birdəfəlik boş qalardı (bax [method Arena._on_roster]).
func set_identity(p_name: String, p_color: int) -> void:
	if p_name.is_empty():
		return
	germ_name = p_name
	if _label != null:
		_label.text = p_name
	if p_color == color_index:
		return
	color_index = p_color
	_base = Palette.germ_color(p_color)
	_light = Palette.germ_light(p_color)
	_shadow = Palette.germ_shadow(p_color)
	queue_redraw()


func setup(p_color: int, p_name: String, p_is_local: bool,
		p_species := Const.Species.CILIATE) -> void:
	color_index = p_color
	germ_name = p_name
	is_local = p_is_local
	species = p_species
	_base = Palette.germ_color(p_color)
	_light = Palette.germ_light(p_color)
	_shadow = Palette.germ_shadow(p_color)

	if species == Const.Species.HELIOZOAN:
		# Ən böyük ölçüyə görə bir dəfə ayrılır: mikrob böyüdükcə ayaq sayı
		# artır, massivi hər dəfə ölçüləndirmək isə lüzumsuz yaddaş hərəkətidir.
		_foot.resize(LEGS_MAX)
		_swing_from.resize(LEGS_MAX)
		_swing_to.resize(LEGS_MAX)
		_step.resize(LEGS_MAX)
		_hold.resize(LEGS_MAX)

	_label = Label.new()
	_label.text = p_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 24)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Palette.TEXT if p_is_local else Palette.TEXT_MUTED)
	_label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# Öz mikrobun həmişə başqalarının üstündə çəkilir — itirməmək üçün.
	z_index = 2 if is_local else 1
	# Hər mikrob öz fazasından başlayır ki, hamısı eyni ritmdə titrəməsin.
	_t = float(p_color) * 1.37


## Mikrob partladı: görüntü [BurstFx]-ə ötürülür və bu node susur.
func kill() -> void:
	burst = true
	alive = false
	visible = false


## Bir zərbə yedi — silueti ağardır (bax [constant FLASH_TIME]).
##
## Vaxt SIFIRLANIR, üstünə gəlmir: ardıcıl iki zərbədə parıltı uzanmamalıdır,
## yoxsa sıx atəş altında mikrob daimi ağ ləkəyə dönür və rəngi — yəni kim
## olduğu — itir.
func flash() -> void:
	_flash = FLASH_TIME


func apply(p_pos: Vector2, p_aim: float, p_balls: int, p_capacity: int,
		p_safe: bool, p_alive: bool, p_super := false) -> void:
	if burst:
		return
	position = p_pos
	aim = p_aim
	balls = p_balls
	capacity = p_capacity
	safe = p_safe
	super_on = p_super
	if p_alive != alive:
		alive = p_alive
		visible = alive
	_place_label()


## Mikrob atəş açdı: top gövdənin İÇİNDƏN doğulur ([method Sim._fire]) və
## membranı yararaq çıxır. Burada həmin keçidin görüntüsü başlayır.
##
## Müddət uydurma deyil, topun mərkəzdən divara qədər getdiyi ƏSL vaxtdır.
## Sabit müddət qoyulsaydı, böyük mikrobda pərdə top hələ yolun yarısındaykən
## buraxılardı — böyük mikrobda bu, 200 ms fərq deməkdir.
func eject(angle: float) -> void:
	_eject_dir = angle
	_eject_span = maxf(Const.germ_radius(capacity) / Const.SHOT_SPEED, 0.04)
	_eject_t = 0.0


## Membranın dartılması: top divara çatana qədər qabarır, keçəndən sonra
## buraxılıb bir dəfə içəri çırpılır və sakitləşir.
##
## Qabarma topun YOLUNUN yalnız son hissəsində başlayır — mərkəzdəki top
## hələ membrana toxunmur, ona görə divarı da dartmamalıdır.
func _eject_strain() -> float:
	if _eject_t < 0.0:
		return 0.0
	if _eject_t < _eject_span:
		# Qabarma topun yolunun ƏVVƏLİNDƏN başlayır. Əvvəl son 65%-də başlayırdı
		# və 4 kadrlıq pəncərədən 2 kadr itirdi — effekt görünmürdü.
		return smoothstep(0.0, 1.0, _eject_t / _eject_span)
	# Topun ÖZ DİAMETRİ də divardan keçməlidir və bu müddətdə pərdə ən gərgin
	# haldadır. Uydurma gözləmə deyil, sabitlərdən çıxır: 2·SHOT_RADIUS / SHOT_SPEED
	# (43 ms). Zirvənin oxunacaq qədər davam etməsi məhz buradan gəlir.
	if _eject_t < _eject_span + _eject_cross():
		return 1.0
	# Buraxılan gərilmiş pərdə — sönən rəqs. Gözün tutduğu hissə budur.
	var w := (_eject_t - _eject_span - _eject_cross()) / EJECT_SNAP
	return exp(-2.0 * w) * cos(w * PI * 1.2)


## Topun diametrinin membrandan keçmə müddəti.
static func _eject_cross() -> float:
	return 2.0 * Const.SHOT_RADIUS / Const.SHOT_SPEED


## Konturu topun çıxdığı nöqtədə bayıra dartır.
##
## Hazır konturun ÜZƏRİNDƏ işləyir, ona görə hər üç növ üçün eynidir: kirpikli
## və ayaqlının membranı da, amöbin iki qatı da eyni cür qabarır (daxili qat
## bayırdan [method _inset] ilə çıxarıldığına görə dartılmanı özü daşıyır).
func _strain(ring: PackedVector2Array) -> PackedVector2Array:
	var amp := _eject_strain()
	if absf(amp) < 0.002:
		return ring
	var axis := Vector2.from_angle(_eject_dir)
	# Gövdənin öz mərkəzindən ölçülür — amöbdə kontur node-un üstündə oturmur.
	var mid := _ring_centre(ring)
	# Nübün yarım eni TOPUN ölçüsünə bağlıdır, gövdənin formasına yox.
	var half := Const.SHOT_RADIUS * EJECT_WIDTH
	var push := Const.germ_radius(capacity) * EJECT_DEPTH * amp
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		var v := ring[i] - mid
		var along := v.dot(axis)
		if along <= 0.0:
			out[i] = ring[i]
			continue
		# Çıxış oxundan YAN məsafə — bucaq deyil, piksel.
		var lateral := absf(v.cross(axis))
		var k := clampf(1.0 - lateral / half, 0.0, 1.0)
		out[i] = ring[i] + axis * (push * k * k * (3.0 - 2.0 * k))
	return out


## Gövdəni tərk etməkdə olan top — HƏLƏ İÇƏRİDƏ olduğu müddətdə.
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Top mikrobun mərkəzində doğulur ([method Sim._fire]) və atəş qatı
## mikroblardan əvvəl çəkildiyi üçün gövdənin ALTINDA qalır. Kirpiklinin dərisi
## yarımşəffafdır, ona görə orada top içəridən görünür və "zorlayıb çıxır"
## oxunuşu tam alınır. Amöbin iki qatı isə TUTQUNDUR — top tamamilə gizlənir və
## geriyə yalnız kənarın yüngül qabarması qalır, yəni effekt itir.
##
## Ona görə top burada, gövdənin ÜSTÜNDƏ, öz HƏQİQİ mövqeyində bir daha
## çəkilir: uydurma bəzək deyil, elə həmin topun harada olduğudur
## (mərkəzdən `SHOT_SPEED × keçən vaxt` qədər aralı). Membrandan keçəndən
## sonra dayanır — oradan sonra əsl top onsuz da görünür.
func _draw_emerging_ball() -> void:
	if _eject_t < 0.0 or _eject_t > _eject_span + _eject_cross():
		return
	var travelled := Const.SHOT_SPEED * _eject_t
	var at := Vector2.from_angle(_eject_dir) * travelled
	# Divara yaxınlaşdıqca aydınlaşır: dərinlikdə qalan top solğun görünməlidir.
	var lit := clampf(travelled / maxf(Const.germ_radius(capacity), 1.0), 0.0, 1.0)

	# Tünd halqa — topu ORQANELLALARDAN ayırır.
	#
	# Onsuz effekt praktik olaraq görünmürdü: çıxan top da, içəridəki toplar da
	# eyni açıq rəngdədir və eyni ölçüdədir, ona görə hərəkət edən ləkə sadəcə
	# "bir top da var" kimi oxunurdu. Kontur onu qabağa çıxarır və gözün
	# izlədiyi TƏK hərəkətli obyekt edir.
	draw_circle(at, Const.SHOT_RADIUS * 1.35, Color(Palette.OUTLINE, 0.30 + 0.45 * lit))
	draw_circle(at, Const.SHOT_RADIUS, Color(_light, 0.45 + 0.5 * lit))
	# Divara çatmaqda olan top ağarır — "indi çıxır" işarəsi.
	if lit > 0.45:
		var k := (lit - 0.45) / 0.55
		draw_circle(at, Const.SHOT_RADIUS * 0.55, Color(Palette.TEXT, 0.75 * k))


## Gövdənin SON konturu — atəş dartılması da daxil olmaqla.
##
## Ayrıca metoddur ki, çəkiliş və testlər EYNİ yoldan keçsin. Əvvəl kontur
## [method _draw]-ın içində qurulurdu və testlər ona çata bilmirdi: nəticədə
## atəş effekti yalnız təmiz dairə üzərində yoxlanılırdı və gövdənin öz
## formasının onu udduğu hal gözdən qaçmışdı.
##
## Ayaqlı mikrobun gövdəsi BƏRKDİR (mineral skeleti var): daha az və daha yavaş
## titrəyir, sürətdə demək olar dartılmır. Kirpiklininki yumşaq kisədir. Amöbin
## forması tamamilə ayrı qanunla qurulur (bax [method _crawl_body]). Forma dili
## hər üçündə eynidir, yalnız rəqəmlər fərqlənir.
func _body_ring(r: float) -> PackedVector2Array:
	var tension := clampf((_shown_fill - 0.6) / 0.4, 0.0, 1.0)
	var rush := _rush()
	var heading := _heading()
	var rigid := species == Const.Species.HELIOZOAN
	var ring: PackedVector2Array
	if species == Const.Species.AMOEBA:
		ring = _crawl_body(r, heading, rush, 1.0)
	else:
		ring = _membrane(r,
			(0.018 if rigid else 0.030) + (0.030 if rigid else 0.055) * tension,
			(1.6 if rigid else 2.2) + (2.4 if rigid else 3.4) * tension,
			heading, rush * (0.3 if rigid else 1.0),
			0.0 if rigid else SOFT_AIM_BULGE)
	# Atəş anında gövdə topun çıxdığı yerdə dartılır — növdən ASILI OLMAYARAQ,
	# çünki hazır konturun üzərində işləyir (bax [method _strain]).
	return _strain(ring)


func _place_label() -> void:
	if _label == null:
		return
	var r := Const.germ_radius(capacity)
	_label.position = Vector2(-100.0, -r - NAME_OFFSET - 18.0)


func _process(delta: float) -> void:
	if not visible:
		return
	if frozen:
		return
	_t += delta
	_flash = maxf(0.0, _flash - delta)
	_track_motion(delta)
	match species:
		Const.Species.HELIOZOAN:
			_walk(delta)
		Const.Species.AMOEBA:
			_crawl(delta)

	if _eject_t >= 0.0:
		var before := _eject_t
		_eject_t += delta
		# Pərdənin yarıldığı KADR — səs siqnalı buradan gedir.
		if before < _eject_span and _eject_t >= _eject_span:
			broke_through.emit(is_local)
		if _eject_t > _eject_span + _eject_cross() + EJECT_SNAP:
			_eject_t = -1.0

	var target := clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	_shown_fill = move_toward(_shown_fill, target, delta * 2.5)
	queue_redraw()


## Getdiyi istiqamət. Dayanmışsa nişan istiqaməti götürülür ki, yerində
## fırlanan mikrob da düzgün baxsın (və ayaqları ona görə yerini dəyişsin).
func _heading() -> float:
	return _vel.angle() if _vel.length_squared() > 25.0 else aim


## Mövqe fərqindən sürət çıxarır və daxili mayeni sürüşdürür.
##
## Sürət YUMŞALDILIR: rəqiblərin mövqeyi 100 ms-lik interpolyasiya ilə gəlir,
## ona görə xam fərq snapshot sərhədlərində sıçrayır. Yumşaltmadan
## dartılma effekti hər paketdə çırpınardı.
func _track_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	if not _has_pos:
		_last_pos = position
		_has_pos = true
		return

	var raw := (position - _last_pos) / delta
	_last_pos = position
	# Doğuş və yenidən qoşulma mövqeyi bir kadrda dəyişir — o sıçrayış sürət
	# deyil, ona görə atılır. Eyni siqnal yerə basılmış nöqtələri də sıfırlayır:
	# gövdə teleport olunanda nə pəncələr, nə də uropod köhnə yerdə qalmamalıdır.
	if raw.length() > Const.BASE_SPEED * 4.0:
		raw = Vector2.ZERO
		_planted = false
		_uropod_set = false
	_vel = _vel.lerp(raw, clampf(delta * 9.0, 0.0, 1.0))

	# Daxili mayenin sürüşməsi — İKİ NÖVDƏ ƏKS İSTİQAMƏTDƏ:
	#   • kirpikli (müsbət): geri qalır. Sürətlənəndə içindəki maye arxada
	#     qalır — üzən yumşaq kisənin ətaləti.
	#   • ayaqlı (mənfi): irəli axır. Sitoplazma öndəki aksopoda tökülür və
	#     gövdəni dalınca çəkir — heliozoa hərəkətinin *fəvvarə axını*.
	#   • kirpikli (müsbət): geri qalır — üzən yumşaq kisənin ətaləti.
	#   • ayaqlı:  irəli axır — öndəki aksopoda tökülür.
	#   • amöb:    ƏN ÇOX irəli axır. Onda bu, yan təsir deyil, hərəkətin
	#     mexanizminin özüdür: plazmazol önə axmasa amöb yerindən tərpənməz.
	var r := Const.germ_radius(capacity)
	var pull := 0.16
	match species:
		Const.Species.HELIOZOAN:
			pull = -0.20
		Const.Species.AMOEBA:
			pull = -0.30
	var lag := -_vel / maxf(Const.germ_speed(capacity), 1.0) * (r * pull)
	_core = _core.lerp(lag.limit_length(r * 0.22), clampf(delta * 6.0, 0.0, 1.0))


## Mikrobun ÖZ maksimal sürətinə görə nə qədər sürətlə getdiyi, 0..1.
##
## Ölçü [constant Const.BASE_SPEED] OLA BİLMƏZ və bu, incə, amma ağır səhv idi.
## Mikrob böyüdükcə onun tavan sürəti düşür ([method Const.germ_speed]):
## tutum 60-da 190 yerinə 115 piksel/saniyə. Mütləq ölçü ilə hesablananda
## SONA QƏDƏR sürən böyük mikrob 0.61 "səy" göstərirdi — halbuki o, tam
## qazdadır. Nəticədə bütün sürətə bağlı animasiya (sürünmə, dartılma, kirpik
## döyüntüsü) mikrob böyüdükcə sönürdü.
##
## Səhv məhz belə tapıldı: BOTLAR düzgün sürünürdü, oyunçunun mikrobu yox —
## çünki botlar kiçik qalır, oyunçu isə böyüyür.
## Qoruyucu: `SimTest._test_amoeba_crawl` (ən böyük tutumda da yoxlayır).
func _rush() -> float:
	return clampf(_vel.length() / maxf(Const.germ_speed(capacity), 1.0), 0.0, 1.0)


## Sürünmə SAATININ miqyası — gövdə radiusundan yavaş böyüyür.
##
## Addımın uzunluğu birbaşa radiusa bağlansaydı, böyük mikrobda dövr çökərdi:
## radius 3 dəfə artır, tavan sürət isə 1.7 dəfə AZALIR — yəni tezlik 5 dəfə
## düşür (3.4 → 0.67 Hz) və sürünmə yenidən sürüşmə kimi oxunur.
##
## Kvadrat kök uydurma rəqəm deyil, rəqqas qanunudur (f ∝ 1/√L) — təbiətdə iri
## canlılar da məhz belə, uzun və seyrək addımlayır. Onunla tezlik 5 dəfə yox,
## 2.9 dəfə düşür: böyük amöb ağır, amma hələ də oxunaqlı sürünür.
##
## Yalnız SAATA aiddir. Uzanmanın və dartılmanın ölçüsü gövdənin öz nisbətidir,
## ona görə onlar radiusla birlikdə böyüyür.
func _gait_radius() -> float:
	return sqrt(Const.germ_radius(capacity) * Const.BASE_RADIUS)


# ================================================================ ayaqlar

## Aksopodiyaların addım dövrü.
##
## Model animasiyadan yox, HƏNDƏSƏDƏN gəlir: pəncənin dünya koordinatındakı
## yeri saxlanılır və gövdə ondan uzaqlaşana qədər pəncə TƏRPƏNMİR. Hədd
## keçiləndə ayaq yığılır, irəli atılır və yenidən basılır.
##
## Nəticə budur ki, addımın tezliyi HEÇ BİR YERDƏ yazılmayıb — o, mikrobun
## həqiqi sürətindən özü çıxır. Sabit sürətli animasiya olsaydı, yavaş gedən
## mikrobun ayaqları yerdə sürüşərdi (animasiyada "foot sliding" deyilən
## nasazlıq); burada isə dayanan mikrob sadəcə ayaqları üstündə DURUR, axının
## sürüklədiyi mikrob isə addımlamağa başlayır.
func _walk(delta: float) -> void:
	var r := Const.germ_radius(capacity)
	# Böyüyən mikrobda ayaq sayı artır. Say dəyişəndə "ev" nöqtələri sürüşür,
	# ayaqlar isə onsuz da uzaqlığa görə yenidən basılır — özü düzəlir.
	_legs = clampi(int(r * 0.14) + 4, LEGS_MIN, LEGS_MAX)

	var dir := Vector2.from_angle(_heading())
	var reach := r * LEG_REACH
	# Ayağın UZANMASI gövdə ilə birlikdə böyüyür (yuxarıdakı `reach`), ADDIMIN
	# uzunluğu isə daha yavaş — rəqqas qanunu (bax [method _gait_radius]).
	# Birbaşa radiusa bağlı olsaydı, böyük mikrob saniyədə cəmi bir dəfə
	# addımlayardı və yeriş donardı.
	var gait := _gait_radius()
	var stride := gait * LEG_STRIDE
	# Yellənmənin sürəti də templə ölçülür — bax [constant LEG_SWING_PACE].
	var swing := maxf(LEG_SWING, _vel.length() / gait * LEG_SWING_PACE)

	if not _planted:
		_planted = true
		for i in LEGS_MAX:
			# Hər ayaq dövrün BAŞQA nöqtəsindən başlayır: pəncə geriyə doğru
			# müxtəlif qədər sürüşdürülür, ona görə birincidən sonuncuya qədər
			# addım növbəsi onsuz da yayılmış olur.
			#
			# Bu olmadan hamısı eyni məsafədən başlayır və mikrob yerindən
			# tərpənən kimi BÜTÜN ayaqlar bir anda qalxır — yeriş yox, sıçrayış.
			# Səhv gözlə görünmür (bir kadrlıq hadisədir), ona görə testlə tutulub.
			var phase := fposmod(float(i) * 0.381966, 1.0)
			var seat := Vector2.from_angle(TAU * float(i) / float(_legs)) * reach
			_foot[i] = position + seat - dir * (stride * phase)
			_step[i] = 1.0

	# ---- 1. Havadakı ayaqları irəli aparırıq ----
	var lifted := 0
	for i in _legs:
		if _step[i] >= 1.0:
			_hold[i] += delta
			continue
		_step[i] = minf(1.0, _step[i] + delta * swing)
		var k: float = _step[i]
		_foot[i] = _swing_from[i].lerp(_swing_to[i], k * k * (3.0 - 2.0 * k))
		if _step[i] < 1.0:
			lifted += 1

	# ---- 2. Budcə imkan verdikcə ƏN GECİKMİŞ ayağı qaldırırıq ----
	#
	# Növbə indeks sırası ilə verilsəydi, hər zaman birinci ayaq qabağa
	# keçərdi və sonuncu ayaq gözləyə-gözləyə həddindən artıq dartılardı
	# (sınaqda 102 px — həddən bir piksel çox). Ən gecikmişi seçmək həm
	# ədalətlidir, həm də dartılmanı özü məhdudlaşdırır.
	var budget := lift_budget(_legs)
	while lifted < budget:
		var worst := -1
		var worst_over := 0.0
		for i in _legs:
			if _step[i] < 1.0:
				continue
			var over := _foot[i].distance_to(_leg_home(i, r, dir)) - _leg_trip(i, stride)
			# Çoxdan tərpənməyən ayaq da növbəyə düşür: gövdə yerindən
			# tərpənməsə belə aksopod yenilənməlidir, yoxsa mikrob donmuş
			# ulduza dönür (bax [constant LEG_HOLD_MAX]).
			if _hold[i] > LEG_HOLD_MAX:
				over = maxf(over, (_hold[i] - LEG_HOLD_MAX) * stride)
			if over > worst_over:
				worst_over = over
				worst = i
		if worst < 0:
			break                       # gecikmiş ayaq yoxdur

		_step[worst] = 0.0
		_hold[worst] = 0.0
		_swing_from[worst] = _foot[worst]
		# Yeni yer evdən bir az İRƏLİDƏ seçilir: ayaq gövdəni qabaqlayır,
		# növbəti addıma qədər isə gövdə ona çatır.
		_swing_to[worst] = _leg_home(worst, r, dir) + dir * (stride * 0.5)
		lifted += 1


## Ayağın olmaq İSTƏDİYİ yer: gövdənin ətrafında, amma getdiyi tərəfə
## sürüşmüş, çünki mikrob ayağı irəliyə uzadır, geriyə yox.
## Ayağın uzanması gövdə ilə böyüyür (`r`), getdiyi tərəfə sürüşməsi isə
## ADDIMLA (bax [method _gait_radius]). Sürüşmə də radiusa bağlı olsaydı, böyük
## mikrobda o sabit meyl addımın uzunluğunu keçərdi — ayaqlar dayanan mikrobda
## da fasiləsiz addımlayardı, yəni pəncə yerdə sürüşərdi.
func _leg_home(i: int, r: float, dir: Vector2) -> Vector2:
	return position \
		+ Vector2.from_angle(TAU * float(i) / float(_legs)) * (r * LEG_REACH) \
		+ dir * (_gait_radius() * 0.35)


## Ayağın "evindən" bu qədər uzaqlaşması yeni addım tələb edir.
##
## Hədd hər ayaq üçün FƏRQLİDİR — qızıl nisbətin kəsr hissəsi ardıcıllığı
## bərabər paylayır, ona görə ayaqların dövrü heç vaxt tam üst-üstə düşmür.
func _leg_trip(i: int, stride: float) -> float:
	return stride * (0.65 + 0.7 * fposmod(float(i) * 0.618034, 1.0))


## Pəncənin yerli koordinatı. Addımın ortasında ayaq yığılmış olur, ona görə
## uc nöqtəsi gövdəyə doğru dartılır — çəkiliş və pəncə eyni hesabı görməlidir.
func _leg_tip(i: int, r: float) -> Vector2:
	# Bu node fırlanmır və miqyaslanmır, ona görə valideyn fəzasından yerli
	# fəzaya keçid sadə çıxmadır.
	var tip: Vector2 = _foot[i] - position
	var d := tip.length()
	if d < 1.0:
		return Vector2.ZERO
	var k: float = _step[i]
	if k >= 1.0:
		return tip
	return tip.lerp(tip / d * (r * 1.02), sin(PI * k) * LEG_TUCK)


## Aksopodiyalar. Hər ayaq iki seqmentdir və hamısı BİR çəkiliş çağırışıdır:
## [method CanvasItem.draw_multiline_colors] hər seqmentə ayrıca rəng verə
## bilir, ona görə havadakı ayaq sönük çəkilsə də çağırış sayı artmır.
func _draw_legs(r: float) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var planted := Color(_light, 0.88)
	var lifted := Color(_light, 0.40)

	for i in _legs:
		var tip := _leg_tip(i, r)
		if tip == Vector2.ZERO:
			continue
		var root := tip.normalized() * (r * 0.94)
		# Ayağın ORTASI yüngül dalğalanır — pəncə yerindən tərpənmir, ona görə
		# bu, sürüşmə yaratmır. Olmasa basılı ayaq tam düz çubuqdur və mikrob
		# canlı yox, sxem kimi görünür.
		var side := Vector2(-tip.y, tip.x).normalized()
		var mid := root.lerp(tip, 0.5) \
			+ side * (sin(_t * 2.4 + float(i) * 1.7) * r * LEG_SWAY)
		var col: Color = planted if _step[i] >= 1.0 else lifted
		pts.push_back(root); pts.push_back(mid)
		cols.push_back(col)
		# Uca doğru sönür — aksopod nazilir.
		pts.push_back(mid); pts.push_back(tip)
		cols.push_back(Color(col, col.a * 0.7))

	if not pts.is_empty():
		draw_multiline_colors(pts, cols, 3.0)

	# Pəncələr — yapışma nöqtələri. Basılmış pəncə şüadan GÖZƏ ÇARPACAQ QƏDƏR
	# yoğundur (şüa 3 px, pəncə ən azı 4.2 px): fərq kiçik olsa ayaq sadəcə
	# uzun tikan kimi oxunur. Havadakı pəncə isə xırda və sönükdür —
	# oyunçu bir baxışda hansı ayağın YÜK DAŞIDIĞINI görür.
	for i in _legs:
		var tip := _leg_tip(i, r)
		if tip == Vector2.ZERO:
			continue
		if _step[i] >= 1.0:
			draw_circle(tip, maxf(r * 0.13, 4.2), Color(_light, 0.92))
		else:
			draw_circle(tip, maxf(r * 0.06, 2.0), Color(_light, 0.45))


# ================================================================ çəkiliş

## Çəkiliş sırası qəsdən "əvvəlcə bütün dolu formalar, sonra bütün xətlər"
## şəklindədir. Godot kanvası eyni növ ardıcıl əmrləri bir çəkiliş çağırışına
## yığır — sıra qarışsa, hər mikrob 15-20 ayrıca çağırış olur və mobil GPU-da
## əsas məhdudiyyət məhz çağırış sayıdır.
func _draw() -> void:
	if not alive:
		return

	var r := Const.germ_radius(capacity)
	var fill := _shown_fill
	# Dolduqca membran daha çox gərilir — partlamağa yaxın olduğu buradan görünür.
	var strain := clampf((fill - 0.6) / 0.4, 0.0, 1.0)
	# Sürət 0..1 — dartılma, kirpik döyüntüsü və quyruq bundan asılıdır.
	var rush := _rush()
	var heading := _heading()
	var rigid := species == Const.Species.HELIOZOAN
	var crawler := species == Const.Species.AMOEBA

	var ring := _body_ring(r)
	var skin := Color(_base.lerp(Palette.DANGER, strain * 0.45), 0.30)

	# ---- dolu formalar ----
	# Kölgə — mikrob döşəmədən qopuq görünsün. Amöbdə dairə YARAMIR: gövdə
	# dairə deyil və kölgə ön ucun yanından çıxıb ayrıca ləkə kimi görünür,
	# ona görə orada gövdənin öz silueti aşağı sürüşdürülüb çəkilir.
	if crawler:
		draw_colored_polygon(_shift(ring, Vector2(0, 5)), Color(Palette.OUTLINE, 0.45))
	else:
		draw_circle(Vector2(0, 4), r * 1.02, Color(Palette.OUTLINE, 0.35))
	# Bioluminessensiya halosu: suyun içində işıq yayılır (bax ART_BIBLE §1).
	draw_circle(Vector2.ZERO, r + SHIELD_GAP + 6.0, Color(_base, 0.055 + 0.05 * strain))
	if species == Const.Species.CILIATE:
		# Quyruq "əvvəlcə formalar, sonra xətlər" qaydasının YEGANƏ istisnasıdır:
		# xətdir, amma bədənin ARXASINDA olmalıdır ki, dibi membranın altında qalsın.
		# Bir çəkiliş çağırışına dəyər — quyruq olmadan mikrob üzmür, sürüşür.
		_draw_tail(r, heading, rush)
	# Kənardakı parlaq düymə ÇIXARILIB — heç bir növdə yoxdur.
	#
	# Əvvəl kirpikli və ayaqlıda nişan istiqamətində membrandan bir az kənarda
	# parlaq bir dairə çəkilirdi. Amöbdə o, artıq çıxarılmışdı, çünki gövdədən
	# QOPMUŞ bir ləkə kimi oxunurdu — eyni səbəb qalan iki növ üçün də keçərli
	# çıxdı: yarısı membranın içində, yarısı çölündə qalan dairə "atılmış top
	# gövdənin kənarında ilişib" kimi görünürdü.
	#
	# İndi atəşi YALNIZ topun özü izah edir: gövdənin içindən doğulur, membranı
	# qabardaraq keçir və çölə çıxır (bax [method _draw_emerging_ball] və
	# [method _strain]). İstiqamət isə yumşaq gövdədə siluetin öz çıxıntısı ilə
	# verilir ([constant SOFT_AIM_BULGE]); ayaqlıda belə bir çıxıntı YOXDUR,
	# çünki onun gövdəsi mineral skeletlidir və əyilməməlidir.

	if crawler:
		# İki qat: kənarda jel (plazmagel), içəridə axıcı maye (plazmazol).
		# Amöbin hərəkəti məhz bu iki halın çevrilməsidir, ona görə qatlar
		# bəzək deyil — mexanizmin özüdür (bax [method _crawl_body]).
		#
		# Qatlar TAM TUTQUNDUR (digər növlərdə 0.30). Şəffaf çəkiləndə ikisi
		# bir-birini bulandırır və nəticə iki material yox, bir palçıq ləkəsi
		# olur.
		#
		# Rəng fərqi də QƏSDƏN böyükdür: zolaq oyunçunun rənginin AÇIQ,
		# iç isə TÜND variantıdır. Əvvəl ikisi də əsas rəngə yaxın idi və
		# gövdə tək rəngli ləkə kimi oxunurdu — referansdakı oxunuş (qalın
		# açıq zolaq + dolğun tünd iç) məhz bu addımdan asılıdır.
		draw_colored_polygon(ring, _light.lerp(Palette.DANGER, strain * 0.40))
		draw_colored_polygon(_inset(ring, maxf(r * CRAWL_BAND, CRAWL_BAND_MIN)),
			_base.lerp(Palette.OUTLINE, 0.24).lerp(Palette.DANGER, strain * 0.45))
	else:
		draw_colored_polygon(ring, skin)
	# Daxili kölgə həcm üçündür, amöbdə isə həcmi ARTIQ iki qat verir —
	# üçüncü ləkə onların sərhədini bulandırır və "qalın zolaq + dolğun iç"
	# oxunuşunu itirir. Ona görə yalnız digər növlərdə çəkilir.
	if not crawler:
		_draw_core(r, strain)
	_draw_inner_balls(r)
	_draw_emerging_ball()

	# ---- xətlər ----
	if rigid:
		_draw_legs(r)
		# Mineral skelet — bərk gövdənin daxili konturu. Yumşaq gövdələrdə
		# yoxdur, çünki onlarda belə bir sərhəd olmazdı.
		draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 28, Color(_light, 0.30), 1.6, true)
	elif not crawler:
		_draw_cilia(r, rush, heading)

	if crawler:
		# Amöbin konturu TÜNDDÜR və qalındır — həm bayırda, həm iki qatın
		# arasında. Bu xətt olmasa parlaq zolaq fona, iç isə zolağa qarışır.
		# Digər növlərdəki açıq membran xətti burada ÇƏKİLMİR: parlaq jel
		# zolağı onsuz da işıqlı haşiyə işini görür, üstünə ikinci açıq xətt
		# qoyulanda kənar ikiqat olur.
		var edge_w := maxf(r * CRAWL_EDGE, CRAWL_EDGE_MIN)
		draw_polyline(_closed(ring), Color(Palette.OUTLINE, 0.95), edge_w, true)
		draw_polyline(_closed(_inset(ring, maxf(r * CRAWL_BAND, CRAWL_BAND_MIN))),
			Color(Palette.OUTLINE, 0.95), edge_w * 0.7, true)
	else:
		draw_polyline(_closed(ring), Color(_light, 0.95), 3.0, true)
		# Yaş səth: sol-yuxarıdan gələn işıq parıltısı. Yalnız bir qövsdür,
		# amma "bu, mayedir" mesajını bütün halodan güclü verir. Amöbdə
		# çəkilmir — tutqun gövdənin üstündə cızıq kimi oxunur.
		draw_arc(Vector2.ZERO, r * 0.80, PI * 1.05, PI * 1.55, 12,
			Color(Palette.TEXT, 0.35), 2.5, true)

	# ---- super ----
	if super_on:
		match species:
			Const.Species.AMOEBA:
				_draw_cyst(r)
			Const.Species.HELIOZOAN:
				_draw_net(r)
			_:
				pass

	if safe:
		# Doğuş qalxanı — fırlanan kəsik halqa. Atəş açan kimi sönür.
		draw_arc(Vector2.ZERO, r + SHIELD_GAP, _t * 2.0, _t * 2.0 + PI * 1.4, 24,
			Color(Palette.TEXT, 0.55), 3.0, true)

	# ---- zərbə parıltısı ----
	# ƏN SONDA çəkilir: siluetin İÇİNDƏKİ hər şeyi (toplar, kirpik kökləri,
	# nüvə) örtməlidir, yoxsa parıltı yarımçıq qalır və zərbə oxunmur.
	# Kvadrat sönmə seçilib — xətti sönmə "ağ mikrob" kimi ilişib qalır.
	if _flash > 0.0:
		var f := _flash / FLASH_TIME
		draw_colored_polygon(ring, Color(1.7, 1.7, 1.7, 0.92 * f * f))


## Konturu qapayır — [method CanvasItem.draw_polyline] halqanı özü bağlamır.
static func _closed(ring: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(ring)
	out.push_back(ring[0])
	return out


## Konturu bərabər ENDƏ içəri çəkir: hər nöqtənin radiusundan EYNİ ədəd çıxılır.
##
## Niyə nisbətlə (`r × 0.78`) olmur — bax [constant CRAWL_BAND].
##
## Niyə normal boyunca da olmur: həqiqi ofset çökək yerlərdə qonşu nöqtələri
## bir-birindən KEÇİRİR, kontur özünü kəsir və Godot çoxbucaqlını üçbucaqlara
## böləbilmir ("Invalid polygon data") — gövdə o kadrda yoxa çıxır. Bucağa görə
## düzəliş (`1 / cos φ`) də kömək etmir: o, kiçik bir çuxuru dərin çapığa
## çevirir, çünki düzəliş məhz orada ən böyükdür.
##
## Radiusdan sabit çıxmaq isə bucaq sırasını olduğu kimi saxlayır — nəticə
## həmişə sadə çoxbucaqlıdır və içəri kontur bayırın hamar surətidir.
## Dik en `width × cos φ` olur; bu gövdədə φ heç vaxt böyük deyil, yəni
## fərq 15%-i keçmir və gözlə seçilmir.
static func _inset(ring: PackedVector2Array, width: float) -> PackedVector2Array:
	# Konturun ÖZ mərkəzinə doğru çəkilir, node-un mərkəzinə yox: amöbin gövdəsi
	# kök sabitləndikdən sonra node-un üstündə OTURMUR (bax [constant CRAWL_ANCHOR]),
	# ona görə sıfır nöqtəsi işlədilsəydi zolaq bir tərəfdə qalınlaşardı.
	var mid := _ring_centre(ring)
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		var v := ring[i] - mid
		var d := v.length()
		if d < 0.001:
			out[i] = ring[i]
			continue
		# Hədd yalnız nəzəri haldır (zolaq gövdədən enli olsa) — çoxbucaqlı
		# heç vaxt içəri çevrilməməlidir.
		out[i] = mid + v / d * maxf(d - width, d * 0.18)
	return out


## Bütün nöqtələri sürüşdürür (kölgə üçün).
static func _shift(ring: PackedVector2Array, by: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		out[i] = ring[i] + by
	return out




## Amöbin gövdəsi — POLAR DEYİL, HƏRƏKƏT EDƏN DİSKLƏRDƏN qurulur.
##
## ── Niyə əvvəlki model heç cür sürünmürdü ────────────────────────────────
## Digər iki növ dairədən başlayır və üstünə titrəyiş əlavə edir:
## `nöqtə = mərkəz + istiqamət(a) × radius(a)`. Amöb də əvvəl belə qurulmuşdu
## və NƏ QƏDƏR TƏNZİMLƏNSƏ DƏ sürünmürdü. Səbəb düsturun özündədir: orada
## mərkəz SABİTDİR, sürünmə isə kütlənin mərkəzinin yerdəyişməsidir. Radiusu
## nə qədər dəyişsən, nəticə yerində nəfəs alan ləkə olur — amplitudanı
## artırmaq da kömək etmir, sadəcə daha güclü nəfəs alır.
##
## İkinci məhdudiyyət: polar düsturda bir bucağa yalnız BİR radius düşür,
## yəni boynu olan çıxıntı — psevdopodiyanın tərifi — ifadə oluna bilmir.
##
## ── İndiki model ─────────────────────────────────────────────────────────
## Gövdə üç diskin BİRLƏŞMƏSİDİR: ön psevdopodiya, orta kütlə, arxa uropod.
## Sürünmə kənarın bəzədilməsi yox, disklərin ÖZ hərəkətidir:
##   1. ön disk irəli atılır — protruziya (tez, dövrün ~3-də biri);
##   2. sitoplazma ona axır: ön disk dolur, arxa boşalır;
##   3. arxa uc yığılıb gövdəyə qovuşur — retraksiya (yavaş).
##
## Kontur hər bucaq üçün şüanın disklərdən ƏN UZAQ çıxış nöqtəsidir
## (bax [method _reach]); nəticə dövrün ortasında boynu olan damcı, sonunda
## isə yumru gövdədir. Gövdənin kütlə mərkəzi bu dövr boyu irəli-geri sürüşür —
## "yaxıla-yaxıla getmək" elə budur və ölçülə bilən əlaməti də məhz odur.
## Qoruyucu: `SimTest._test_amoeba_crawl`.
##
## Sahə qorunur: disklər ayrılanda gövdə uzanır, ona görə radiusları
## [constant CRAWL_SLIM] nisbətində kiçilir — uzanan hüceyrə nazilir.
##
## [param scale] konturun ümumi miqyası (1.0 = xarici jel qatı).
## Sürünmə dövrü — MƏSAFƏ ilə sürülür, vaxtla yox.
##
## Bu funksiya animasiya oxutmur, sadəcə bir həndəsi sual verir: gövdə yerə
## basılmış arxa ucdan nə qədər uzaqlaşıb? Cavab addımın harasında olduğumuzu
## deyir. Ona görə sürünmənin tezliyi heç bir yerdə yazılmayıb — mikrob sürətlə
## gedəndə tez, yavaş gedəndə yavaş sürünür, dayananda isə ümumiyyətlə sürünmür.
##
## Vaxtla sürülən dövrün nəyə görə işləmədiyi [constant CRAWL_RELEASE]-də yazılıb.
func _crawl(delta: float) -> void:
	# Addımın uzunluğu gövdə radiusundan YAVAŞ böyüyür (bax [method _gait_radius]).
	var gait := _gait_radius()
	var axis := Vector2.from_angle(_heading())

	if not _uropod_set:
		_uropod = position - axis * (gait * CRAWL_SEAT)
		_tail_dir = -axis
		_uropod_set = true

	var lag := _uropod - position
	# Gövdə yetərincə uzaqlaşıb: arxa uc buraxılır və önə, gövdənin dibinə
	# basılır. Dövrün YEGANƏ hadisəsi budur; qalan hər şey ondan çıxır.
	if lag.length() > gait * CRAWL_RELEASE:
		_uropod = position - axis * (gait * CRAWL_SEAT)
		lag = _uropod - position

	var span := maxf(CRAWL_RELEASE - CRAWL_SEAT, 0.001)
	var stretch := clampf((lag.length() / gait - CRAWL_SEAT) / span, 0.0, 1.0)
	# Uzanma bütün dövrə yayılır, yığılma isə bir anda olur — "atılma" hissi
	# məhz bu asimmetriyadandır. Templə ölçülür ki, forma yerdəyişmədən tez
	# dəyişməsin (bax [constant CRAWL_PULL]).
	var pace := _vel.length() / gait
	var rate := pace * (CRAWL_PUSH if stretch > _reach_out else CRAWL_PULL)
	_reach_out = move_toward(_reach_out, stretch, delta * maxf(rate, CRAWL_SETTLE))

	if lag.length_squared() > 0.0001:
		_tail_dir = _tail_dir.lerp(lag.normalized(),
			clampf(delta * 8.0, 0.0, 1.0)).normalized()

	var rush := _rush()
	_flow = move_toward(_flow, rush, delta * CRAWL_FLOW_RATE)
	# Kənarın öz dalğalanması — sürünmədən ayrı, dayananda da davam edir.
	_crawl_t += delta * CRAWL_RATE * (CRAWL_IDLE_RATE + CRAWL_MOVE_RATE * rush)


func _crawl_body(r: float, heading: float, rush: float, scale: float) -> PackedVector2Array:
	var axis := Vector2.from_angle(heading)
	# Addımın harasındayıq — cavab [method _crawl]-dan, yəni HƏNDƏSƏDƏN gəlir.
	# Uzanma həm də sürətlə süzülür: dayanan amöb yerində addımlamamalıdır,
	# onu canlı saxlayan şey aşağıdakı ləçəklər və axın dalğasıdır.
	# ── Fazalar ƏKSDİR və bu, məcburidir ────────────────────────────────────
	# Psevdopodiya addımın ƏVVƏLİNDƏ atılır, sonra gövdə ona doğru axdıqca
	# yerli koordinatda kiçilir — yəni ucu dünyada demək olar YERİNDƏ QALIR,
	# gövdə isə ona çatır. Arxa uc bunun tam əksidir: dövr boyu dala dartılır,
	# buraxılanda önə qovuşur.
	#
	# Əvvəl ikisi də EYNİ fazada idi (uzanma sonda, yığılma buraxılışda) və
	# nəticə görünən qüsur verirdi: buraxılış anında gövdə bir kadrda GERİ
	# sıçrayırdı (böyük mikrobda kadr başına −5.6 piksel). Sürünən heç bir şey
	# geri sıçramır. İndi hər iki uc buraxılışda ÖNƏ gedir, ona görə sıçrayış
	# irəlidir — sürünmənin özü elə odur.
	# Qoruyucu: `SimTest._check_crawl` (geri sıçrayışı ayrıca yoxlayır).
	var thrown := (1.0 - _reach_out) * _flow   # psevdopodiya nə qədər öndədir
	var hauled := _reach_out * _flow           # arxa uc nə qədər dala dartılıb

	var lead := r * CRAWL_REACH * thrown
	var drag := r * CRAWL_DRAG * hauled
	# Ümumi uzanma — həm gövdənin nazilməsini, həm dartılmasını sürür.
	# Keçid anında hər ikisi kiçik olur və gövdə yumrulanır: siluetin
	# "uzanır → yumrulanır → uzanır" dövrü elə buradan çıxır.
	var spread := (lead + drag) / r
	var rad := r * scale * (1.0 - CRAWL_SLIM * spread)
	var pull := 1.0 + CRAWL_STRETCH * spread
	var squash := 1.0 / pull
	var side := Vector2(-axis.y, axis.x)
	# Sitoplazmanın axını — atılan psevdopodiya əvvəlcə nazikdir, sonra dolur.
	var mass := CRAWL_MASS * hauled

	var head_c := axis * lead
	# Orta disk MƏRKƏZDƏ DEYİL, bir az öndədir.
	#
	# Səbəb ölçüldü: mərkəzdə duranda o, arxanı da doldururdu və nazik quyruq
	# diski heç vaxt siluetə çıxmırdı — "enli baş, nazik quyruq" cəhdi buna
	# görə alınmırdı (ölçü: ön/arxa en 19 / 18 px, yəni konus yoxdur).
	# Sıfır nöqtəsi yenə diskin İÇİNDƏ qalır, yəni kontur bucaq sırası ilə
	# çəkilə bilir.
	var body_c := Vector2.ZERO
	# Arxa uc yerə basılmış nöqtəyə DOĞRU dartılır — istiqamət dünyadan gəlir,
	# uzunluq isə gövdənin sərhədləri daxilində saxlanılır.
	var tail_c := _tail_dir * drag
	var head_r := rad * (CRAWL_HEAD + mass)
	var body_r := rad * CRAWL_BODY
	var tail_r := rad * (CRAWL_TAIL - mass)

	# ---- disklərin birləşməsi ----
	# Orta disk mərkəzdə olduğu üçün onun çıxış məsafəsi elə öz radiusudur;
	# bu həm də mərkəzin HƏMİŞƏ gövdənin içində qalmasına zəmanət verir, yəni
	# kontur bucaq sırası ilə çəkilə bilir.
	var rays := PackedFloat32Array()
	rays.resize(CRAWL_POINTS)
	for i in CRAWL_POINTS:
		var dir := Vector2.from_angle(TAU * float(i) / float(CRAWL_POINTS))
		rays[i] = maxf(_reach(dir, body_c, body_r), maxf(_reach(dir, head_c, head_r),
			_reach(dir, tail_c, tail_r)))
	# İki dairənin kəsişməsi kəskin künc verir, canlı hüceyrədə isə belə künc
	# olmur — tikiş hamarlanır.
	rays = _smooth_ring(rays, CRAWL_SMOOTH)

	# ---- kənarın öz həyatı ----
	# Perimetr dalğasının ORTA dəyəri fazadan asılıdır və çıxarılmasa gövdə
	# dövr boyu bütövlükdə şişib-büzülür. Aşağıdakı ifadə həmin ortanın dəqiq
	# həllidir: (1/PI)·∫₀^PI sin(u·k + p) du = [cos(p) − cos(PI·k + p)] / (PI·k)
	var phase := _crawl_t * TAU * 1.4
	var flow := CRAWL_FLOW_DEPTH * (0.35 + 0.65 * rush)
	var flow_mean := (cos(phase) - cos(PI * CRAWL_WAVES + phase)) / (PI * CRAWL_WAVES)

	var pts := PackedVector2Array()
	pts.resize(CRAWL_POINTS)
	for i in CRAWL_POINTS:
		var a := TAU * float(i) / float(CRAWL_POINTS)
		# Ləçəklər — kənar heç vaxt tam dairə olmur, amöb dayananda da canlıdır.
		var m := 1.0 \
			+ CRAWL_LOBE * sin(a * 3.0 + _crawl_t * 4.7) \
			+ CRAWL_LOBE * 0.20 * sin(a * 5.0 - _crawl_t * 3.1)

		# Kənar boyunca ARXADAN ÖNƏ qaçan dalğa. `u` ön uca qədər olan bucaq
		# məsafəsidir (0 öndə, PI arxada); faza artdıqca dalğa kiçilən `u`-ya,
		# yəni önə sürüşür. Dalğa YANLARDA ən güclüdür (`sin u`), uclarda isə
		# sönür — orada disklərin hərəkəti onsuz da işləyir və dalğa onunla
		# toqquşub kənarda diş açırdı.
		# Konus — bax [constant CRAWL_CONE].
		var cd := a - heading
		m += CRAWL_CONE * rush * cos(cd) * sin(cd) * sin(cd)

		var u := absf(wrapf(a - heading, -PI, PI))
		m += flow * (0.30 + 0.70 * sin(u)) * (sin(u * CRAWL_WAVES + phase) - flow_mean)

		# Nişan tərəfindəki daimi ayaqcıq. Dar saxlanılır (dördüncü dərəcə):
		# geniş olsa sürünmə deformasiyası ilə qarışar və istiqamət itər.
		var t := maxf(cos(a - aim), 0.0)
		m += CRAWL_AIM_BULGE * t * t * t * t

		var v := Vector2.from_angle(a) * (rays[i] * m)
		# Ox boyunca dartılır, ona dik istiqamətdə yastılaşır — sahə qorunur.
		pts[i] = axis * (v.dot(axis) * pull) + side * (v.dot(side) * squash)

	# ── Sahə DƏQİQ qorunur ──────────────────────────────────────────────────
	# Əvvəl sahə disklərin radiuslarını əl ilə kiçiltməklə TƏXMİN edilirdi və
	# nəticədə siluetə toxunan hər addım onu pozurdu: "enli baş, nazik quyruq"
	# cəhdi məhz buna görə geri qaytarılmışdı (6% → 29% dəyişmə).
	#
	# Çoxbucaqlını öz mərkəzi ətrafında miqyaslamaq isə sahəni bir addımda və
	# DƏQİQ oturdur — forma nə olursa olsun. Bu, disklərin ölçülərini sərbəst
	# buraxır: hüceyrə həcmini saxlayır, siluet isə istənilən ola bilər.
	var want := PI * (r * scale) * (r * scale) * CRAWL_AREA
	var have := _ring_area(pts)
	if have > 0.001:
		var mid := _ring_centre(pts)
		var k := sqrt(want / have)
		for i in CRAWL_POINTS:
			pts[i] = mid + (pts[i] - mid) * k

	# Kök sabitlənir: forma dəyişməyə davam edir, kütlə mərkəzi isə node-un
	# üstündə qalır (bax [constant CRAWL_ANCHOR]).
	var drift := _ring_centre(pts) * CRAWL_ANCHOR
	for i in CRAWL_POINTS:
		pts[i] -= drift
	return pts


## Çoxbucaqlının sahəsi (ayaqqabı bağı düsturu).
static func _ring_area(pts: PackedVector2Array) -> float:
	var sum := 0.0
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


## Çoxbucaqlının kütlə mərkəzi — bərabər sıxlıqlı lövhə kimi.
## Nöqtələrin sadə ortası YARAMAZ: o, nöqtə sıxlığından asılıdır, sahədən yox.
static func _ring_centre(pts: PackedVector2Array) -> Vector2:
	var twice_area := 0.0
	var acc := Vector2.ZERO
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var cross := a.x * b.y - b.x * a.y
		twice_area += cross
		acc += (a + b) * cross
	if absf(twice_area) < 0.0001:
		return Vector2.ZERO
	return acc / (3.0 * twice_area)


## Sıfır nöqtəsindən [param dir] boyunca gedən şüanın diskdən ÇIXMA məsafəsi.
## Şüa diski kəsmirsə 0 — belə halda bu disk birləşmədə söz demir.
static func _reach(dir: Vector2, centre: Vector2, radius: float) -> float:
	var b := dir.dot(centre)
	var h := radius * radius - (centre.length_squared() - b * b)
	return b + sqrt(h) if h > 0.0 else 0.0


## Halqa boyunca radiusları hamarlayır — dövri, [0.25 0.5 0.25] nüvəsi ilə.
static func _smooth_ring(rays: PackedFloat32Array, passes: int) -> PackedFloat32Array:
	var n := rays.size()
	var src := rays
	for _p in passes:
		var out := PackedFloat32Array()
		out.resize(n)
		for i in n:
			out[i] = src[(i - 1 + n) % n] * 0.25 + src[i] * 0.5 + src[(i + 1) % n] * 0.25
		src = out
	return src


## Titrəyən membran konturu.
##
## Üç təsir üst-üstə düşür:
##   • iki fərqli tezlikli sinus — mexaniki görünməsin, canlı orqanizm olsun;
##   • doluluq gərginliyi — dolduqca titrəmə güclənir və sürətlənir;
##   • sürətə görə dartılma — getdiyi ox boyunca uzanır, ona dik istiqamətdə
##     yastılaşır. Maye içində üzən cismin forması budur; həcm qorunur, ona
##     görə uzanma və yastılaşma eyni əmsalın tərs cütüdür.
func _membrane(r: float, wobble: float, speed: float, heading: float,
		rush: float, bulge := 0.0) -> PackedVector2Array:
	var stretch := 1.0 + STRETCH_MAX * rush
	var squash := 1.0 / stretch
	var axis := Vector2.from_angle(heading)
	var side := Vector2(-axis.y, axis.x)

	var pts := PackedVector2Array()
	for i in MEMBRANE_POINTS:
		var a := TAU * float(i) / float(MEMBRANE_POINTS)
		var m := 1.0 \
			+ wobble * sin(_t * speed + a * 3.0) \
			+ wobble * 0.6 * sin(_t * speed * 0.7 + a * 5.0)
		# Nişan tərəfindəki daimi çıxıntı — hansı tərəfə atacağını göstərir.
		# Dar saxlanılır (dördüncü dərəcə), yoxsa titrəyişlə qarışıb bütün
		# gövdəni dalğalı göstərir (bax [constant SOFT_AIM_BULGE]).
		if bulge > 0.0:
			var t := maxf(cos(a - aim), 0.0)
			m += bulge * t * t * t * t
		var v := Vector2.from_angle(a) * r * m
		pts.push_back(axis * (v.dot(axis) * stretch) + side * (v.dot(side) * squash))
	return pts


## Kirpiklər — perimetr boyu döyünən tüklər (paramesium modeli).
##
## Hər kirpik iki parçadan ibarətdir: dibi membrana dik çıxır, ucu isə
## dalğaya görə yana əyilir. Faza bucaqla birlikdə sürüşür (metaxronal dalğa),
## ona görə halqa boyunca dalğa qaçır — bütün tüklər eyni anda döysəydi
## nəticə titrəyiş kimi görünərdi, üzmə kimi yox.
##
## Hamısı BİR [method CanvasItem.draw_multiline] çağırışıdır: 30 kirpik
## ayrıca xətt olsaydı, tək mikrob 30 çəkiliş çağırışı yeyərdi.
func _draw_cilia(r: float, rush: float, heading: float) -> void:
	var n := clampi(int(r * 0.42), CILIA_MIN, CILIA_MAX)
	var length := clampf(r * 0.20, 5.5, 10.0)
	# Hərəkətdə həm daha sürətli, həm daha geniş döyünür.
	var beat := CILIA_BEAT * (0.55 + 0.9 * rush)
	var sweep := 0.35 + 0.55 * rush
	# Dalğa getdiyi istiqamətin əksinə qaçır — mikrob suyu geri itələyir.
	var flow := heading + PI

	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var phase := _t * beat - a * CILIA_WAVES
		var out := Vector2.from_angle(a)
		var tangent := Vector2(-out.y, out.x)

		var root := out * (r * 0.97)
		var bend := sin(phase) * sweep
		# Ön tərəfdəki kirpiklər arxadakılardan daha az açılır: axın oradan gəlir.
		var lean := 0.45 + 0.55 * (0.5 - 0.5 * cos(a - flow))
		var mid := root + (out * 0.75 + tangent * bend).normalized() * (length * 0.55)
		var tip := mid + (out * 0.35 + tangent * (bend * 1.6)).normalized() * (length * 0.65 * lean)

		pts.push_back(root)
		pts.push_back(mid)
		pts.push_back(mid)
		pts.push_back(tip)

	draw_multiline(pts, Color(_light, 0.50 + 0.28 * rush), 1.8)


## Qamçı — arxada qamçılanan quyruq. Uzunluğu boyunca sinus dalğası qaçır,
## amplitudası uca doğru artır: real qamçının hərəkəti belədir və gözə
## "bu, öz-özünə üzür" mesajını verir.
##
## Dayanan mikrobda da yavaş yellənir — ölü görünməsin.
func _draw_tail(r: float, heading: float, rush: float) -> void:
	var back := Vector2.from_angle(heading + PI)
	var side := Vector2(-back.y, back.x)
	var span := r * TAIL_LENGTH
	var wave := 2.6 + 5.4 * rush
	var amp := r * (0.13 + 0.16 * rush)

	var pts := PackedVector2Array()
	for i in TAIL_POINTS:
		var u := float(i) / float(TAIL_POINTS - 1)
		# Uca doğru həm nazikləşir, həm daha çox yellənir.
		var swing := sin(_t * wave - u * 5.0) * amp * u
		pts.push_back(back * (r * 0.75 + span * u) + side * swing)

	# Sürət artdıqca bir az sönür: sürətli mikrobda diqqət bədənə və
	# kirpiklərə düşməlidir, quyruq isə hərəkət cizgisinə qarışır.
	var col := Color(_base, 0.60 - 0.20 * rush * rush)
	var wide := maxf(r * 0.10, 2.2)
	# İki hissəyə bölünür ki, dibdən uca doğru NAZİLSİN. Godot-un
	# `draw_polyline`-ı dəyişkən qalınlıq bilmir; iki çağırış isə tək
	# çağırışla çəkilmiş "kabel"dən qat-qat canlı görünür.
	var half := (TAIL_POINTS + 1) / 2
	draw_polyline(pts.slice(0, half + 1), col, wide, true)
	draw_polyline(pts.slice(half), Color(col, col.a * 0.75), wide * 0.5, true)


## Daxili kölgə — sitoplazmanın dərin qatı. Toplar bunun ÜSTÜNDƏ oturur,
## ona görə mikrob yastı disk yox, həcmli kisə kimi oxunur.
##
## Parlaq nüvəcik QƏSDƏN yoxdur: mərkəzdə ikinci bir işıqlı nöqtə topla
## qarışardı, top sayı isə oyunun əsas göstəricisidir — onu heç nə təqlid
## etməməlidir. İlk versiyada nüvəcik vardı və məhz belə oxunurdu.
##
## Kölgənin sürüşməsi daxili axını göstərir (bax [method _track_motion]):
## kirpiklidə geri qalır, ayaqlıda öndəki ayağa doğru axır.
func _draw_core(r: float, strain: float) -> void:
	draw_circle(_core, r * 0.62, Color(_shadow.lerp(Palette.DANGER, strain * 0.35), 0.45))


## Orqanellalar — mikrobun içindəki toplar. Oyunun ƏSAS oxunma vasitəsi:
## say həm sursat, həm candır.
##
## Nöqtələr "günəbaxan" (phyllotaxis) düzümü ilə paylanır: qızıl bucaq
## dairəni bərabər doldurur, ona görə say dəyişəndə düzüm sıçramır,
## sadəcə bir top əlavə olunur.
func _draw_inner_balls(r: float) -> void:
	var n := clampi(balls, 0, 40)
	if n <= 0:
		return
	# Amöbin orqanellaları ulduz formasındadır (referans şəkli). Yalnız say
	# az olanda: çoxaldıqca nöqtələr xırdalanır, ulduzun uçları onsuz da
	# görünmür, hər biri isə ayrıca çəkiliş çağırışı olardı.
	#
	# Onlar həm də TÜND İÇ QATIN içində qalmalıdır ([constant CRAWL_CORE]):
	# jel zolağının üstünə düşən ulduz "içindəki top" oxunuşunu itirir.
	# Digər növlərdə belə bir sərhəd yoxdur — orada gövdə tək qatdır.
	var starry := species == Const.Species.AMOEBA and n <= STAR_MAX
	var inner := (r * CRAWL_CORE) if species == Const.Species.AMOEBA else (r * 0.66)
	# Ulduz eyni "radiusda" dairədən enli görünür (uclar kənara çıxır), ona
	# görə daha seyrək yığılır — yoxsa qonşu uclar bir-birinə keçib ağ ləkəyə
	# dönür və topları saymaq mümkün olmur.
	var dot := clampf(inner / sqrt(float(n)) * (0.50 if starry else 0.72), 2.0, 7.0)

	# İşıq nöqtəsi yalnız top kifayət qədər böyükdürsə çəkilir: kiçik topda
	# onsuz da görünmür, çəkiliş çağırışını isə iki dəfə artırır.
	var lit := dot >= 4.0
	# Ulduzlar İKİ tonda növbələşir (referansda çəhrayı və sarı orqanellalar).
	# Tək tonda çəkiləndə iç bir ovuc eyni ləkəyə dönür; iki ton isə sayı
	# gözlə saymağı asanlaşdırır — say oyunun əsas göstəricisidir.
	var tint := _base.lerp(Palette.TEXT, 0.25)
	# Toplar daxili axınla birlikdə sürüşür. Amöbdə sürüşmə TAM götürülür:
	# orada gövdənin özü önə uzanır, yəni görünən için mərkəzi də irəli
	# sürüşür. Yarısı götürüləndə ulduzlar arxada qalıb tünd qatın kənarından
	# çıxırdı — parlaq zolağın üstündəki ulduz "içindəki top" oxunmur.
	var drift := 1.0 if species == Const.Species.AMOEBA else 0.6
	for i in n:
		var a := float(i) * 2.39996 + _t * 0.35
		var d := inner * sqrt((float(i) + 0.5) / float(n))
		var jitter := Vector2.from_angle(_t * 1.8 + float(i)) * (dot * 0.18)
		# Toplar da daxili kölgə ilə birlikdə sürüşür — bütün daxili maye
		# bir yerdə axır.
		var p := Vector2.from_angle(a) * d + jitter + _core * drift
		if starry:
			# Tünd kontur ulduzun BÖYÜDÜLMÜŞ nüsxəsi ilə verilir, xətlə yox:
			# dolğun forma kənar yumşaltmadan da təmiz çıxır və çəkiliş
			# çağırışı baxımından xətdən ucuzdur.
			draw_colored_polygon(_star(p, dot * 1.58, a), Palette.OUTLINE)
			draw_colored_polygon(_star(p, dot * 1.25, a), tint if i % 2 == 0 else _light)
			continue
		draw_circle(p, dot, Color(_light, 0.95))
		if lit:
			draw_circle(p - Vector2(dot * 0.3, dot * 0.3), dot * 0.35, Color(Palette.TEXT, 0.8))


## Sistləşmiş amöb — bağlı qabıq.
##
## Gövdə artıq yumşaq deyil, ona görə qabıq gövdənin öz konturunu TƏKRARLAMIR:
## üstünə düzgün, sərt bir halqa oturur. Fərq qəsdən kobuddur — oyunçu bir
## baxışda "bura top girmir" deməlidir, forma oxumağa vaxt sərf etməməlidir.
##
## Rəng mikrobun öz rəngindən çıxarılır, amma TÜNDLƏŞDİRİLİR: sist yatmış
## haldır, işıq saçmır. Bütün oyunda yeganə "sönmüş" mikrob budur.
func _draw_cyst(r: float) -> void:
	var shell := r + SHIELD_GAP * 0.5
	# İki qat: bayırda tünd mineral, içəridə solğun işıq — qabıq qalın oxunmalıdır.
	draw_circle(Vector2.ZERO, shell + 3.0, Color(Palette.OUTLINE, 0.55))
	draw_arc(Vector2.ZERO, shell, 0.0, TAU, 40, _shadow.lerp(Palette.TEXT, 0.30), 7.0, true)
	draw_arc(Vector2.ZERO, shell - 5.0, 0.0, TAU, 36, Color(_light, 0.30), 2.0, true)
	# Qabığın "tikişləri" — mineral lövhələr. Fırlanmır: sist tərpənmir.
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var from := Vector2.from_angle(ang) * (shell - 6.0)
		var to := Vector2.from_angle(ang) * (shell + 2.0)
		draw_line(from, to, Color(Palette.OUTLINE, 0.7), 3.0)


## Aksopodiya toru — ayaqlının superi.
##
## Şüalar uzanır, uclarındakı kinetosistlər parlayır. Torun SƏRHƏDİ də
## çəkilir: oyunçu qidanın hansı məsafədən axdığını, rəqib isə hara girməli
## OLMADIĞINI görməlidir — görünməyən sahə ədalətsiz olardı.
func _draw_net(r: float) -> void:
	var reach := r * Const.NET_RADIUS
	# Sərhəd — nazik, nəbz vuran halqa. Doldurulmur: içəridəki hər şeyi örtərdi.
	var pulse := 0.5 + 0.5 * sin(_t * 3.4)
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 72, Color(_light, 0.14 + 0.10 * pulse), 2.5, true)
	draw_arc(Vector2.ZERO, reach * 0.66, 0.0, TAU, 56, Color(_light, 0.07 + 0.05 * pulse), 1.6, true)

	# Uzanan şüalar. Ayaqların ÖZÜ deyil — onlar yerdə qalır; bunlar tordur.
	var n := 16
	for i in n:
		var ang := TAU * float(i) / float(n) + _t * 0.20
		var dir := Vector2.from_angle(ang)
		# Uzunluq növbə ilə dəyişir: bərabər uzunluqlu şüalar çarx kimi görünür.
		var len := reach * (0.72 + 0.28 * sin(_t * 2.2 + float(i) * 1.3))
		draw_line(dir * (r * 0.98), dir * len, Color(_light, 0.42), 2.0)
		draw_circle(dir * len, 3.2, Color(Palette.TEXT, 0.55))


## Sivri uclu orqanella. Uc sayı tək deyil, CÜTDÜR (14 nöqtə = 7 uc) və
## hər biri öz bucağından başlayır — eyni istiqamətə baxan ulduzlar sıra
## kimi görünür, təsadüfi dönmüş olanlar isə canlı.
func _star(centre: Vector2, size: float, turn: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in STAR_POINTS * 2:
		var a := turn + PI * float(i) / float(STAR_POINTS)
		var rr := size if i % 2 == 0 else size * STAR_INNER
		pts.push_back(centre + Vector2.from_angle(a) * rr)
	return pts


