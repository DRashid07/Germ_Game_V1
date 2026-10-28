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
##   1. Nə qədər doluyam        → membranın gərginliyi + altındakı top zolağı ([AmmoBar])
##   2. Rəqib partlamağa yaxındırmı → arxasında qırmızı ürək döyüntüsü ([constant RIPE_FILL]),
##                                 lap dolanda membranı bərk titrəyir və qırmızıya çalır
##   3. Kim mənəm               → kamera HƏMİŞƏ sənin mikrobunun üstündədir
##
## Mikrobun ətrafında HALQA YOXDUR — nə doluluq, nə fokus halqası. Hər ikisi
## vardı və hər ikisi çıxarıldı: mikrobu konsentrik halqaların içinə salırdılar
## və kirpiklər, ayaqlar, qamçı onlarla yarışırdı.
##
## Əvəzinə hər ikisinin işini onsuz da mövcud olan bir şey görür:
##   • doluluq → membranın öz gərginliyi (dəqiq rəqəm HUD-dadır);
##   • "bu, mənəm" → kamera. Öz mikrobun həmişə ekranın mərkəzindədir, ona
##     görə adı da yazılmır ([member show_name]); rəqiblərin adı sönükdür.

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

## Sel qatının əvvəlki 0.10 / 0.14 cütü gövdənin çoxunu örtür, üstəlik sürüşmüş
## çoxbucaqlının ucu siluetdən çıxırdı. Nazik inset və böyük sürüşmə tünd tonu
## aşağı-sağda geniş aypara kimi saxlayır; kəsmə isə işığı həmişə gövdədə tutur.
const LIT_INSET := 0.06
const LIT_SHIFT := 0.30
## Spekulyarın ölçüsü tam en/hündürlükdür; kiçik qalır ki, orqanella sanılmasın.
const SPECULAR_SIZE := Vector2(0.22, 0.12)
const SPECULAR_OFFSET := 0.45
const SPECULAR_ALPHA := 0.55
## Yumşaq halo qalxan boşluğunun hamısına yayılmır: böyük radius əvvəlki tünd
## diskin sahəsini yenidən yaradardı.
const HALO_GAP_SCALE := 0.90
## Rim yalnız həqiqi çıxış normalı işığın əksinə kifayət qədər baxanda seçilir.
const RIM_NORMAL_CUTOFF := 0.35

## Sürətə görə dartılma həddi. 0.16 = ən sürətli halda 16% uzanır.
## Daha çox olsa mikrob damcıya dönür və toqquşma radiusu ilə uyğunsuzluq
## gözə çarpır — membran gerçək radiusdan uzaqda görünür.
const STRETCH_MAX := 0.16
## Gövdə toqquşma ellipsinin bu hissəsinə qədər sərbəstdir, ondan o yana ellipsə
## doğru hamar sıxılır (bax [method _fit_hit]). 1-ə yaxın olsa uc qəfil
## yastılanar, kiçik olsa gövdə ehtiyacsız yerdə də kiçilər.
const HIT_FIT_KNEE := 0.94
## Keçici squash & stretch sabit dartılmanın üstünə gəlsə də bu həddi keçmir.
## 0.26-dan yuxarı variantda siluet artıq toqquşma dairəsindən qopmuş görünürdü.
const TOTAL_STRETCH_MAX := 0.26
## Sürətlənmənin əlavə dartılması 0.10-dur: sabit 0.16 ilə birlikdə dəqiq
## yuxarı həddə çatır. 0.18 saniyə hərəkətin başlanğıcını göstərir, amma ayrıca
## animasiya kimi ilişib qalmır.
const ACCEL_STRETCH := 0.10
const ACCEL_TIME := 0.18
## Zərbə membranı gələn ox boyunca əzir, ona dik istiqamətdə genişləndirir.
## Elastik sönmə 0.14 saniyədir; daha uzunu zərbədən sonra idarə gecikməsi kimi
## oxunurdu, daha qısası isə 60 Hz-də cəmi bir neçə kadr qalırdı.
const HIT_SQUASH := 0.12
const HIT_STRETCH := 0.14
const HIT_SQUASH_TIME := 0.14
## Atəş bütün gövdəni azca sıxır və topun əksinə geri çəkir. Yerli membran
## qabarması ayrıca [method _strain]-də qalır; bu qat yalnız bədənin reaksiyasıdır.
const FIRE_SQUASH := 0.06
const FIRE_RECOIL := 0.06
const FIRE_SQUASH_TIME := 0.12
## Doğuş pop-u Node2D miqyası deyil: kölgə, ad və hərəkət orqanları sabit
## qalır, yalnız membran 0-dan 1.12-yə aşıb öz ölçüsünə oturur.
const BIRTH_TIME := 0.35
const BIRTH_OVERSHOOT := 1.90
## Dayanan membranın zəif nəfəsi və yellənməsi. Rəqəmlər qəsdən xırdadır:
## ikiqat dəyərlər dayanan mikrobu jelatin kimi əsdirirdi.
const IDLE_BREATH := 0.018
const IDLE_TURN := deg_to_rad(1.5)

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
## Arxadakı uroid ayrıca quyruq qabarması kimi oxunur. Disk radiusunu böyütmək
## sınandı, amma bütün arxa yarını enləndirib konus fərqini silirdi; dar altıncı
## dərəcəli qabarıq yalnız ucda işləyir və sahə sonra yenə dəqiq normallaşır.
const UROID_BULGE := 0.16
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
## 0.30 saniyəlik əvvəlki sönmə keçici reaksiyanın 0.2 saniyə həddini aşırdı.
## 0.18 saniyə 60 Hz-də yenə oxunaqlı follow-through verir, amma yapışmır.
const EJECT_SNAP := 0.18

const STAR_POINTS := 7
const STAR_INNER := 0.50
const STAR_MAX := 14

var color_index := 0
var germ_name := ""
var is_local := false
## Ad yazılsınmı — [method setup]-dan ƏVVƏL qoyulur.
##
## Oyunda öz mikrobunun adı YAZILMIR ([method Arena._ensure_germ]): sən həmişə
## ekranın mərkəzindəsən, adı isə məhz orada sayım və mesaj yazıları ilə
## üst-üstə yığılırdı ("2", "TƏK QALAN · 10 mikrob", "Mikrob" — üç sətir bir
## yerdə) və maneələrin üstünə düşürdü. Komandalı rejimdə yoldaşların adı qalır.
## Stendlər (`--preview`, müqayisə stendi) adı başlıq kimi işlədir — onlarda qalır.
var show_name := true
var species := Const.Species.CILIATE

var balls := Const.START_BALLS
var capacity := Const.START_CAPACITY
var aim := 0.0
## Aktiv mutasiyalar ([enum Const.Mut] bitləri) — anatomiyada görünür ([MutationAnatomy]).
## Rəqibinki bayraqdan, öz mikrobununku proqnozdan gəlir ([method Arena._render_germs]).
var muts := 0
var _anatomy: MutationAnatomy = null
## Membranın fazası ([enum Const.MemPhase]) və kilidli istiqaməti — [MembraneArc] çəkir.
var mem_phase := 0
var mem_dir := 0.0
var _arc: MembraneArc = null
## Super İNDİ işləyirmi — ayaqlıda tor açıqdır, amöbdə qabıq bağlıdır.
## Serverin bayrağından gəlir (bax [enum Const.GFlag]); görüntü qatı onu
## özü hesablamır, çünki rəqibin superini yalnız server bilir.
var super_on := false

## Ulti HAZIRDIR — doluluq tam və qiyməti ödənir. Arena hər kadr yazır:
## öz mikrobu üçün proqnozdan, rəqib üçün snapshot bayrağından.
##
## Əvvəl rəqibin doluluğu şəbəkədə gəlirdi, amma ekranda HEÇ YERDƏ
## görünmürdü. Brawl Stars-da ultisi hazır rəqib uzaqdan tanınır və bu,
## oyunun əsas taktiki məlumatıdır: "ona indi yaxınlaşma".
var super_ready := false
## Auranın görüntü ağırlığı — [member _super_fade] ilə eyni səbəbdən sürünür.
var _ready_fade := 0.0
## Hazır auranın fırlanan qığılcımları. Say qəsdən kiçikdir: qığılcım
## işarədir, bəzək deyil — çox olsa kirpik və ayaqlarla yarışar.
const READY_SPARKS := 3

## Rəqib PARTLAMAĞA YAXINDIR — "indi vur" (yalnız rəqibdə).
##
## Oyunun ən çaşdıran qaydası budur: dəyən top mikroba +2 top verir, yəni zəifi
## vurmaq onu yedizdirməkdir. Doğru hədəf DOLU rəqibdir, bunu isə ekranda heç
## nə demirdi: membranın gərginliyi 60%-dən yavaş-yavaş artır və yalnız 90%-də
## (çatlar, qırmızı kontur) seçilir — o da yaxından.
##
## Doluluq bu həddi keçəndə rəqibin ARXASINDA qırmızı işıq ürək kimi döyünür
## ("lub-dub"), dolduqca tezləşir. Ad yox, gövdə dəyişir: döyüşdə göz
## gövdələrə baxır, adlara yox (bax [member is_ally]). Halqa deyil, yumşaq
## işıqdır — mikrobun ətrafına halqa qoymamaq qaydası burada da qüvvədədir.
##
## Öz mikrobun və yoldaşların döyünmür: onlar hədəf deyil. Öz doluluğun
## altındakı zolaqdadır ([AmmoBar]).
const RIPE_FILL := 0.8
## Döyüntünün tezliyi (Hz): həddə sakit nəbz, tam doluda təşviş.
const RIPE_RATE_MIN := 1.3
const RIPE_RATE_MAX := 2.6
var _ripe: Sprite2D
var _ripe_fade := 0.0
var _ripe_phase := 0.0
static var _ripe_material: CanvasItemMaterial
static var _ripe_texture: GradientTexture2D

## Superin görüntü ağırlığı 0..1 — bayrağın ARDINCA sürünür.
##
## Bayraq ikilidir və başqa cür ola da bilməz: qalan vaxt şəbəkəyə çıxmır,
## cəmi bir bit gedir. Amma ikili bayrağı birbaşa çəkəndə 4 saniyəlik tor və
## 2.5 saniyəlik qabıq tam gücdə PEYDA OLUR və tam gücdə YOX OLUR — ekranda
## bu, effektin sınması kimi oxunur.
##
## Ona görə bit hədəfdir, çəkilən isə ona doğru sürünən ədəddir. Şəbəkəyə
## sıfır bayt əlavə olunur.
var _super_fade := 0.0

## Sönmə açılmadan yavaşdır: açılış hadisədir (dərhal görünməlidir), bağlanma
## isə keçiddir.
const SUPER_FADE_IN := 9.0
const SUPER_FADE_OUT := 4.5
var alive := true
var safe := false
## Partladı. [method apply] bundan sonra görüntünü geri qaytarmır — öz
## mikrobun hər kadr proqnozdan yenilənir, ona görə tək `visible = false`
## növbəti kadrda geri açılardı.
var burst := false

var _base := Palette.BODY_LIGHT
var _light := Palette.BODY_LIGHT
var _shadow := Palette.OUTLINE
var _label: Label
var _t := 0.0

## Ağ radial tekstura sinif səviyyəsində birdəfəlik yaranır və bütün mikroblar
## arasında paylaşılır; hər node üçün ayrıca GradientTexture2D həm yaddaşı, həm
## də resurs yenilənməsini boş yerə təkrarlayardı.
static var _halo_texture: GradientTexture2D
## Hazır ultinin aurası — halo ilə eyni forma, amma xeyli sıx.
##
## Əvvəl halo teksturası `modulate` alfası 2.6 ilə gücləndirilirdi. Kadrda
## aura demək olar görünmədi: rəng alfası 1-də kəsilir, yəni mərkəz yenə
## halonun öz 0.22-si idi. Ayrı tekstura bir çəkiliş çağırışıdır, eynisi kimi.
static var _aura_texture: GradientTexture2D

## Beş squash & stretch hadisəsinin saatları bir-birindən ayrıdır. Node2D
## miqyası qəsdən işlədilmir: o, membranla yanaşı kölgəni, adı, kirpikləri və
## ayaqları da dartıb toqquşma siluetini anlaşılmaz edirdi.
var _accel_t := 0.0
var _accelerating := false
var _hit_squash_t := 0.0
var _hit_dir := 0.0
var _fire_squash_t := 0.0
## Testlər ağaca əlavə edilməyən node işlədir, ona görə başlanğıcda tamamlanmış
## sayılır; həqiqi səhnədə [method _ready] onu sıfırlayıb pop-u başladır.
var _birth_t := BIRTH_TIME

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

## Zərbə donması (hit-stop) — YALNIZ vurulan mikrobda.
##
## Bütün ekranı dondurmaq öldürmə üçün saxlanılıb ([member Arena._freeze]):
## hər adi zərbədə donsaydı, saniyədə bir atəşlə oyun kəkələyərdi. Burada isə
## yalnız qurbanın öz animasiyası 50 ms dayanır — parıltı həmin müddətdə TAM
## ağ qalır və zərbə "oturur". Mövqe dayanmır: onu şəbəkə sürür.
const HITSTOP_TIME := 0.05
var _hitstop := 0.0

## Proqnozun vəd etdiyi top sayı — serverin rəqəmi gələnə qədər.
##
## Öz topun rəqibə dəyəndə +2 dərhal görünməlidir, amma serverin sözü
## RTT + interpolyasiya qədər sonra gəlir. O vaxta qədər göstərilən say vəddən
## aşağı düşmür; server çatanda vəd özü silinir. Server dəyməni qəbul etməsə
## vəd [member _promise_t] bitəndə sönür — yalan top sayı ilişib qalmır.
var _promise := -1
var _promise_t := 0.0

## Donmuş kadr — öldürmə anında [Arena] qoyur (bax [method Arena._freeze]).
##
## YALNIZ animasiyanı dayandırır. Simulyasiya, proqnoz və şəbəkə işləməyə
## davam edir: `Engine.time_scale` ilə donduran variant client-i serverdən
## geri salardı, sonra isə düzəliş mikrobu sıçradardı.
var frozen := false

## Mikrob EKRANDADIRMI — [Arena] hər kadr yazır (bax [method Arena._render_germs]).
##
## Ekrandan kənarda vəziyyət yenilənir (saatlar, sürət, zərbə), amma gövdə
## YENİDƏN ÇƏKİLMİR. Server hər oyunçuya ekrandan ~3 dəfə böyük sahəni
## göndərir, yəni görünən mikrobların təxminən üçdə ikisi kadrdan kənarda olur.
## Onların hər kadr GDScript-də çəkilməsi brauzerdə kadr işinin ən böyük
## payı idi (ölçülüb: 4× yavaş CPU-da kadr başına 10–16 ms). Ekrana qayıdan
## mikrob elə həmin kadrda yenidən çəkilir — [Arena] bayrağı onun [method _process]-indən
## ƏVVƏL yazır.
var on_screen := true:
	set(value):
		# Ekrana QAYIDAN mikrob elə həmin kadr çəkilməlidir — kətanda onun çoxdan
		# qalmış köhnə şəkli (bəlkə köhnə ölçüdə) durur və yarım tezlikdə növbəsi
		# bir kadr gecikə bilərdi.
		if value and not on_screen:
			_stale = true
		on_screen = value
var _stale := false

## Gövdə neçə kadrdan bir yenidən çəkilir — [Arena] yazır.
##
## AŞAĞI keyfiyyətdə (telefonun ilkini) rəqib mikrobların FORMASI saniyədə 30
## dəfə yenilənir. Hərəkət hamar qalır: mövqe node-un transformudur və hər kadr
## yenilənir, yalnız membranın dalğası, kirpik və ayaqların şəkli iki kadrda bir
## təzələnir. Öz mikrobun və qısa hadisələr (parıltı, atəş, əzilmə, doğuş) həmişə
## hər kadr çəkilir — zərbə anı kəskin qalmalıdır. Faza rəngdən gəlir ki,
## mikrobların yarısı bir kadrda, yarısı o birində çəkilsin — yük bərabər paylanır.
var redraw_step := 1
## Detal səviyyəsi: 0 = tam, 1 = MİNİMUM keyfiyyət ([Arena] yazır).
##
## Zəif telefonda mikrobun çəkilişi kadrın ən böyük xərcidir: kirpiklərin hər
## biri ayrıca poliqondur (18–30 çağırış), kölgə iki, işıqlandırma üç poliqon.
## 1-də gövdə düz rənglə, kölgə bir poliqonla, kirpiklər yarı sayda və BİR
## çağırışla çəkilir; işıq ləkəsi, parıltı və kənar xətti çəkilmir. Forma,
## ölçü, rəng, içindəki toplar və təhlükə çatları QALIR — oyun məlumatı itmir.
var lod := 0
## Serverin dediyi sürət (snapshot-dan, interpolyasiya ilə) — [Arena] yazır.
## Toqquşma ellipsi ondan qurulur ([method Sim.hit_shape]); görüntünün öz
## `_vel`-i mövqedən çıxır və axını da daşıyır, server isə suya nisbi sürəti bilir.
var net_vel := Vector2.ZERO
## Gövdə toqquşma ellipsinin İÇİNDƏ saxlanılsınmı (bax [method _fit_hit]).
##
## Yalnız oyunda açılır ([method Arena._ensure_germ]): menyu və stendlərdə
## server qaydası yoxdur və [member net_vel] də yazılmır.
var hit_fit := false
## GPU yolu (bax [GermGPU]) — mikrob ağaca girəndə açılır, əgər mümkündürsə.
##
## Müqayisə stendi bir nüsxəni qəsdən GDScript yolunda saxlayır (`false`), ikisi
## yan-yana çəkilir. `--germ-cpu` isə hamısını GDScript yoluna qaytarır.
var gpu_allowed := true
## Mikrobun GPU sətri; −1 = GDScript yolu (testlər, başsız rejim, `--germ-cpu`).
var _gpu_row := -1
## Gövdə qatı node-un ARXASINDA, ön qat (halqalar, qığılcım, parıltı) adın
## arxasında; aralarında node-un öz `_draw`-ı — super.
var _gpu_body: Node2D
var _gpu_front: Node2D
var _gpu_cap := -1
var _redraw_phase := 0
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


func _ready() -> void:
	# `setup` node ağaca salınmazdan əvvəl çağırılır. Pop-u burada başlatmaq həm
	# həqiqi doğuşu tutur, həm də ağacsız həndəsə testlərini dəyişməz saxlayır.
	_birth_t = 0.0
	# İçindəki toplar və dairələr disk teksturası ilə çəkilir (bax [BatchDraw]).
	BatchDraw.use_mipmaps(self)
	if gpu_allowed and GermGPU.supported():
		_gpu_attach()
	_refresh()


## Gövdə GPU-da çəkilir (bax [GermGPU]): iki sabit mesh qatı və mikrobun sətri.
func _gpu_attach() -> void:
	_gpu_row = GermGPU.acquire(self)
	_gpu_body = GermGPU.layer(GermGPU.body_mesh(species), true, _gpu_row)
	_gpu_front = GermGPU.layer(GermGPU.front_mesh(species), false, _gpu_row)
	add_child(_gpu_body)
	add_child(_gpu_front)
	# Ad hər şeyin ÜSTÜNDƏ qalır — GDScript yolunda olduğu kimi.
	if _label != null:
		move_child(_gpu_front, _label.get_index())


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _gpu_row >= 0:
		GermGPU.release(_gpu_row)
		_gpu_row = -1


## Gövdəni bu kadr yeniləyir. GDScript yolunda `_draw` növbəyə düşür; GPU yolunda
## yalnız mikrobun sətri kadrın sonunda yazılır ([method gpu_row_bytes]) — superdə də.
func _refresh() -> void:
	if _gpu_row < 0:
		queue_redraw()
		return
	GermGPU.submit(_gpu_row)
	# Ön qat yalnız işi olanda çəkilir — boş mesh-in də öz çağırışı var.
	_gpu_front.visible = is_ally or safe or _ready_fade > 0.004 or _flash > 0.0 \
		or _super_fade > 0.004
	if capacity != _gpu_cap:
		_gpu_cap = capacity
		var r := Const.germ_radius(capacity)
		# Ən uzaq çıxan şey qamçı (2.4 r) və ayaqlardır; aura 1.25 × halo. Ayaqlının
		# toru isə 4 r-ə qədər uzanır (bax [method _draw_net]).
		GermGPU.set_extent(_gpu_body, r * 3.2 + 30.0)
		GermGPU.set_extent(_gpu_front, r * (Const.NET_RADIUS
			if species == Const.Species.HELIOZOAN else 3.2) + 30.0)


## [param p_species] snapshot-dan gəlir ([constant Const.GFlag.HELIOZOAN]),
## öz mikrobun üçün isə menyudakı seçimdən. Rəngdən ÇIXARILMIR: növ artıq
## oyunçunun seçimidir, rənglə əlaqəsi yoxdur.
## Adı və rəngi sonradan dəyişir — reyestr snapshot-dan GEC gələ bilər.
##
## [method setup] mikrobu bir dəfə qurur, ona görə reyestr sonra çatanda ad
## birdəfəlik boş qalardı (bax [method Arena._on_roster]).
## Yoldaşdırmı — komandalı rejimdə ad rəngini və halqanı dəyişir.
##
## Rəng DƏYİŞMİR: rəng "kim" sualına cavab verir, komanda isə "dost ya
## düşmən" sualına. İkisini bir kanalda birləşdirsək, on mikrobun
## bir-birindən seçilməsi itər (bax design/MODES.md §4).
var is_ally := false:
	set(value):
		if is_ally == value:
			return
		is_ally = value
		if _label != null and not is_local:
			_label.add_theme_color_override("font_color",
				Palette.ALLY if value else Palette.TEXT_MUTED)
		_refresh()


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
	_refresh()


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

	# Döyüntü hər şeyin ARXASINDADIR — gövdə qatından da əvvəl (bax [method _beat_ripe]).
	# Yalnız rəqib ola biləndə qurulur: öz mikrobun heç vaxt "hədəf" deyil.
	if not p_is_local:
		_ripe = Sprite2D.new()
		_ripe.texture = _shared_ripe_texture()
		_ripe.material = _ripe_blend()
		_ripe.show_behind_parent = true
		_ripe.visible = false
		add_child(_ripe)

	if show_name:
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


## Mutasiyanın anatomiyası — İLK uşaqdır və node-un ARXASINDA çəkilir: həm GDScript yolunun
## gövdəsi, həm GPU gövdə qatı onun köklərini örtür. Yalnız mutasiyalı mikrobda yaranır.
func _update_anatomy(delta: float) -> void:
	if _anatomy == null:
		_anatomy = MutationAnatomy.new()
		add_child(_anatomy)
		move_child(_anatomy, 0)
	_anatomy.visible = muts != 0 and alive
	if muts != 0:
		_anatomy.setup(muts, Const.germ_radius(capacity), _base, _light, _shadow)
		_anatomy.set_aim(aim, delta)


## Mikrob partladı: görüntü [BurstFx]-ə ötürülür və bu node susur.
func kill() -> void:
	burst = true
	alive = false
	visible = false


## Bir zərbə yedi — silueti ağardır və dəymə oxuna DİK genişləndirir.
##
## Vaxt SIFIRLANIR, üstünə gəlmir: ardıcıl iki zərbədə parıltı uzanmamalıdır,
## yoxsa sıx atəş altında mikrob daimi ağ ləkəyə dönür və rəngi — yəni kim
## olduğu — itir.
## [param incoming] qurbanın mərkəzindən dəymə nöqtəsinə baxan bucaqdır. Köhnə
## çağıran bucağı verməsə, hərəkətin əksi götürülür; bu ehtiyat yol test və
## alət üçündür, oyun isə həqiqi dəymə nöqtəsini ötürür.
func flash(incoming := NAN) -> void:
	_flash = FLASH_TIME
	_hit_squash_t = HIT_SQUASH_TIME
	_hit_dir = (_heading() + PI) if is_nan(incoming) else incoming
	_hitstop = HITSTOP_TIME


## Proqnozlaşdırılmış dəymə: göstərilən top sayı [param total]-dan aşağı
## düşmür, ta ki server təsdiqləyənə və ya [param hold] saniyə keçənə qədər.
func promise_balls(total: int, hold: float) -> void:
	_promise = maxi(_promise, total)
	_promise_t = hold
	balls = maxi(balls, total)


func apply(p_pos: Vector2, p_aim: float, p_balls: int, p_capacity: int,
		p_safe: bool, p_alive: bool, p_super := false) -> void:
	if burst:
		return
	position = p_pos
	aim = p_aim
	if _promise >= 0 and (p_balls >= _promise or _promise_t <= 0.0):
		_promise = -1
	balls = maxi(p_balls, _promise)
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
	_fire_squash_t = FIRE_SQUASH_TIME


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
	BatchDraw.disc(self, at, Const.SHOT_RADIUS * 1.35, Color(Palette.OUTLINE, 0.30 + 0.45 * lit))
	BatchDraw.disc(self, at, Const.SHOT_RADIUS, Color(_light, 0.45 + 0.5 * lit))
	# Divara çatmaqda olan top ağarır — "indi çıxır" işarəsi.
	if lit > 0.45:
		var k := (lit - 0.45) / 0.55
		BatchDraw.disc(self, at, Const.SHOT_RADIUS * 0.55, Color(Palette.TEXT, 0.75 * k))


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
	var ring := _shape_ring(r, true)
	# Atəş anında gövdə topun çıxdığı yerdə dartılır — növdən ASILI OLMAYARAQ,
	# çünki hazır konturun üzərində işləyir (bax [method _strain]).
	ring = _strain(ring)
	return _fit_hit(_event_deform(ring, r))


## Gövdənin hadisəsiz əsas silueti. Kölgə bu yolu `false` ilə çağırır ki,
## squash & stretch yalnız membranda qalsın; Node2D miqyası işlədilsəydi kölgə
## də eyni istiqamətdə uzanıb yerə təmas oxunuşunu itirərdi.
func _shape_ring(r: float, transient: bool) -> PackedVector2Array:
	var bonus := _accel_bonus() if transient else 0.0
	var cap := _base_stretch_cap() if transient else TOTAL_STRETCH_MAX
	if species == Const.Species.AMOEBA:
		return _fit_hit(_crawl_body(r, _heading(), _rush(), 1.0, bonus, cap))
	var m := _membrane_args()
	return _fit_hit(_membrane(r, m[0], m[1], _heading(), m[2], m[3], bonus, cap))


## Membranın titrəmə və dartılma ədədləri: `[titrəmə, tezlik, sürət payı, nişan
## qabarığı]`. Ayaqlının gövdəsi bərkdir — az və yavaş titrəyir, sürətdə demək olar
## dartılmır. GPU sətri də EYNİ ədədləri işlədir ([method gpu_row_bytes]).
func _membrane_args() -> Array:
	var tension := clampf((_shown_fill - 0.6) / 0.4, 0.0, 1.0)
	var rigid := species == Const.Species.HELIOZOAN
	return [
		(0.018 if rigid else 0.030) + (0.030 if rigid else 0.055) * tension,
		(1.6 if rigid else 2.2) + (2.4 if rigid else 3.4) * tension,
		_rush() * (0.3 if rigid else 1.0),
		0.0 if rigid else SOFT_AIM_BULGE,
	]


## Görünən gövdə toqquşma ellipsinin İÇİNDƏ qalır ([method Sim.hit_shape]).
##
## Top mərkəzi ellipsə girəndə dəyir. Gövdə ellipsdən bayıra çıxsa, mərkəzi
## gövdədən keçən top dəymədən keçərdi — oyunçunun ən çox hiss etdiyi səhv
## budur. Ellipsi görüntüyə görə böyütmək isə olmaz: onun ölçüsü balansdan
## gəlir (orta eni dayanan mikrobun dairəsi qədərdir), böyüsə mikrob asan
## vurulardı. Ona görə uyğunlaşan tərəf görüntüdür.
##
## Ölçülüb (tam sürət, hər tutumda 240 kadr): kirpikli, ayaqlı və kiçik amöb
## ellipsin içindədir; böyük amöbün sürünmə zirvələri isə 60 tutumda 15%-ə
## qədər bayıra çıxırdı. Sıxılma yumşaqdır: sərhədin [constant HIT_FIT_KNEE]
## hissəsinə qədər gövdə toxunulmazdır, ondan o yana nöqtə mərkəzə doğru hamar
## sıxılır — uc kəsilmir, yumrulanır.
func _fit_hit(ring: PackedVector2Array) -> PackedVector2Array:
	if not hit_fit:
		return ring
	var shape := Sim.hit_shape(int(species), capacity, net_vel)
	var inv := Vector2(1.0 / shape.x, 1.0 / shape.y)
	var soft := 1.0 - HIT_FIT_KNEE
	var out := PackedVector2Array(ring)
	for i in out.size():
		var q := (out[i].rotated(-shape.z) * inv).length()
		if q <= HIT_FIT_KNEE:
			continue
		out[i] *= (HIT_FIT_KNEE + soft * tanh((q - HIT_FIT_KNEE) / soft)) / q
	return out


## Sürətlənmənin ease-out payı. Zərbə və atəş daha güclü, istiqamətli hadisədir;
## onlar işləyərkən bu əlavə sönür ki, üst-üstə yığılıb 0.26 həddini aşmasın.
func _accel_bonus() -> float:
	if _accel_t <= 0.0 or _hit_squash_t > 0.0 or _fire_squash_t > 0.0:
		return 0.0
	var left := _accel_t / ACCEL_TIME
	return ACCEL_STRETCH * left * left


## Kölgənin hadisəsiz forması indiki forma ilə eynidirmi.
##
## [method _shape_ring] yalnız bu iki dəyərlə fərqlənir; ikisi də adi haldadırsa,
## `transient` bayrağı nəticəni dəyişmir və forma təkrar qurulmur.
func _shape_steady() -> bool:
	return _accel_bonus() == 0.0 and _base_stretch_cap() == TOTAL_STRETCH_MAX


## İstiqamətli hadisə üçün əsas hərəkət dartılmasına qalan yer. Zərbədə əsas
## dartılma sıfırlanır ki, 0.88 / 1.14 silueti olduğu kimi oxunsun. Atəşdə isə
## 1.06-lıq enlənmə ilə hasil də 1.26-dan böyük olmur.
func _base_stretch_cap() -> float:
	if _hit_squash_t > 0.0:
		return 0.0
	if _fire_squash_t > 0.0:
		return TOTAL_STRETCH_MAX - FIRE_SQUASH
	return TOTAL_STRETCH_MAX


## Beş hadisənin membran səviyyəsində birləşdiyi YEGANƏ yer. Beləliklə xarici
## kontur, sel-shading və təhlükə çatları həmişə eyni son çoxbucaqlını izləyir;
## kölgə, ad və hərəkət orqanları isə qəsdən bu transformdan kənarda qalır.
func _event_deform(source: PackedVector2Array, r: float) -> PackedVector2Array:
	var e := _event_params(r)
	var ring := PackedVector2Array(source)
	if e[0] != Vector2.ZERO:
		ring = _axis_transform(ring, e[0], e[1], e[2], e[3])
	if e[4] != 1.0 or e[5] != 0.0:
		ring = _uniform_transform(ring, e[4], e[5])
	if e[6] != Vector2.ZERO:
		ring = _shift(ring, e[6])
	return ring


## [method _event_deform]-in ədədləri: `[ox, boyuna, eninə, sürüşmə, miqyas,
## dönmə, titrəyiş]`. Ox sıfırdırsa ox transformu yoxdur. GPU sətri də EYNİ
## ədədləri işlədir ([method gpu_row_bytes]) — hadisə qaydası bir yerdədir.
func _event_params(r: float) -> Array:
	var axis := Vector2.ZERO
	var along := 1.0
	var across := 1.0
	var shift := Vector2.ZERO
	if _hit_squash_t > 0.0:
		var left := _hit_squash_t / HIT_SQUASH_TIME
		# İlk kadrda tam əzilir, sonra kiçik əks salınma ilə sönür — elastic-out.
		var wave := left * left * cos((1.0 - left) * PI * 2.5)
		axis = Vector2.from_angle(_hit_dir)
		along = lerpf(1.0, 1.0 - HIT_SQUASH, wave)
		across = lerpf(1.0, 1.0 + HIT_STRETCH, wave)
	elif _fire_squash_t > 0.0:
		var left := _fire_squash_t / FIRE_SQUASH_TIME
		var k := left * left                 # ease-out: güc tez itir
		axis = Vector2.from_angle(_eject_dir)
		along = 1.0 - FIRE_SQUASH * k
		across = 1.0 + FIRE_SQUASH * k
		shift = -axis * (r * FIRE_RECOIL * k)

	# Boşdayanma yalnız həqiqətən sakit gövdədə işləyir. İstiqamətli hadisə ilə
	# üst-üstə düşsəydi, zərbə oxu yellənmə içində itib gedərdi. Doğuş pop-u ilə
	# heç vaxt üst-üstə düşmür (biri doğuşdan SONRA, o biri doğuşda işləyir).
	var scale := 1.0
	var turn := 0.0
	if axis == Vector2.ZERO and _birth_t >= BIRTH_TIME and _rush() < 0.05:
		scale = 1.0 + IDLE_BREATH * sin(_t * 2.1)
		turn = IDLE_TURN * sin(_t * 1.7)
	if _birth_t < BIRTH_TIME:
		scale = _birth_scale()

	# Təhlükə titrəyişi rush-dan ASILI DEYİL. Sürətə bağlanan əvvəlki titrəmə
	# dayanan dolu rəqibi sakit göstərirdi; iki qeyri-bərabər sinus bunu pozur.
	var jitter := Vector2.ZERO
	if clampf((_shown_fill - 0.6) / 0.4, 0.0, 1.0) >= 0.75:
		jitter = Vector2(sin(_t * 31.0), sin(_t * 37.0 + 1.4)) * (r * 0.015)
	return [axis, along, across, shift, scale, turn, jitter]


## Back-out əyrisi 0 → 1.12 → 1. Standart 1.70 əmsalı cəmi ~1.10 verirdi;
## 1.90 böyük ekranda ölçüləndə 1.12-yə çatır, amma toqquşma həddini aşmır.
func _birth_scale() -> float:
	var p := clampf(_birth_t / BIRTH_TIME, 0.0, 1.0)
	var x := p - 1.0
	return 1.0 + (BIRTH_OVERSHOOT + 1.0) * x * x * x + BIRTH_OVERSHOOT * x * x


## Çoxbucaqlını öz kütlə mərkəzi ətrafında verilən ox üzrə miqyaslayır.
## [param shift] də yalnız membrana tətbiq olunur — atəş geri təpməsi node-u və
## onun üstündəki adı hərəkət etdirməməlidir.
static func _axis_transform(ring: PackedVector2Array, axis: Vector2,
		along: float, across: float, shift := Vector2.ZERO) -> PackedVector2Array:
	var mid := _ring_centre(ring)
	var forward := axis.normalized()
	var side := Vector2(-forward.y, forward.x)
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		var v := ring[i] - mid
		out[i] = mid + forward * (v.dot(forward) * along) \
			+ side * (v.dot(side) * across) + shift
	return out


static func _uniform_transform(ring: PackedVector2Array, scale: float,
		turn: float) -> PackedVector2Array:
	var mid := _ring_centre(ring)
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		out[i] = mid + (ring[i] - mid).rotated(turn) * scale
	return out


func _place_label() -> void:
	if _label == null:
		return
	var r := Const.germ_radius(capacity)
	_label.position = Vector2(-100.0, -r - NAME_OFFSET - 18.0)


func _process(delta: float) -> void:
	if not visible:
		return
	if muts != 0 or _anatomy != null:
		_update_anatomy(delta)
	if mem_phase != Const.MemPhase.NONE or _arc != null:
		if _arc == null:
			# Gövdənin ÖNÜNDƏ: son uşaq kimi əlavə olunur (GPU qatlarından da sonra).
			_arc = MembraneArc.new()
			add_child(_arc)
		_arc.set_state(mem_phase if alive else Const.MemPhase.NONE, mem_dir, Const.germ_radius(capacity))
	_promise_t = maxf(0.0, _promise_t - delta)
	if frozen:
		return
	# Parıltının saatı donmada da axır: ümumi ömrü uzanmır, sadəcə ilk
	# [constant HITSTOP_TIME] tam ağ çəkilir (bax [method _draw]).
	_flash = maxf(0.0, _flash - delta)
	# Zərbə donması: əzilmə və bütün animasiya ilk kadrdakı kimi SAXLANILIR.
	if _hitstop > 0.0:
		var hold := minf(_hitstop, delta)
		_hitstop -= hold
		delta -= hold
		# Mövqe donmada da dəyişir (onu şəbəkə sürür). İzləmə nöqtəsi onunla
		# sürüşür — yoxsa donma bitəndə yığılmış yerdəyişmə bir kadrın sürəti
		# sayılar və gövdə birdən dartılar.
		if _has_pos:
			_last_pos = position
		if delta <= 0.0:
			if on_screen:
				_refresh()
			return
	_t += delta
	_accel_t = maxf(0.0, _accel_t - delta)
	_hit_squash_t = maxf(0.0, _hit_squash_t - delta)
	_fire_squash_t = maxf(0.0, _fire_squash_t - delta)
	_birth_t = minf(BIRTH_TIME, _birth_t + delta)

	# Superin görüntüsü bayrağın ardınca sürünür — bax [member _super_fade].
	var ready_want := 1.0 if super_ready and not super_on else 0.0
	if not is_equal_approx(_ready_fade, ready_want):
		_ready_fade = move_toward(_ready_fade, ready_want, delta * 5.0)
	var want := 1.0 if super_on else 0.0
	if not is_equal_approx(_super_fade, want):
		var rate := SUPER_FADE_IN if super_on else SUPER_FADE_OUT
		_super_fade = move_toward(_super_fade, want, delta * rate)

	var rush_before := _rush()
	_track_motion(delta)
	var rush_after := _rush()
	# Sürətlənmə hadisəsi yalnız başlanğıc KƏNARINDA doğulur. Taymer hər kadr
	# sıfırlansaydı, yumşaldılmış sürət hədəfə çatanadək 0.18 saniyəlik vurğu
	# bir saniyədən çox uzanardı və keçici yox, daimi forma olardı.
	var accelerating_now := rush_after - rush_before > maxf(delta * 0.12, 0.0015)
	if accelerating_now and not _accelerating:
		_accel_t = ACCEL_TIME
	_accelerating = accelerating_now
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
	_beat_ripe(delta, target)
	if on_screen and _redraw_due():
		_refresh()


## Dolu rəqibin döyüntüsü (bax [constant RIPE_FILL]).
##
## Hədd [member _shown_fill]-dən yox, HƏQİQİ doluluqdan oxunur: yumşaldılmış
## rəqəm zərbədən sonra həddə yarım saniyə gec çatırdı, işarə isə elə zərbə
## anında "bir də vur" deməlidir. Yumşaqlıq sönmə-yanmadadır ([member _ripe_fade]).
func _beat_ripe(delta: float, fill: float) -> void:
	if _ripe == null:
		return
	# Doğuş qalxanındakı mikroba top dəymir — onu hədəf kimi göstərmək yalandır.
	var want := 1.0 if fill >= RIPE_FILL and not is_ally and not safe else 0.0
	_ripe_fade = move_toward(_ripe_fade, want, delta * 5.0)
	_ripe.visible = _ripe_fade > 0.004
	if not _ripe.visible:
		return
	var k := clampf((fill - RIPE_FILL) / (1.0 - RIPE_FILL), 0.0, 1.0)
	_ripe_phase = fposmod(_ripe_phase + delta * lerpf(RIPE_RATE_MIN, RIPE_RATE_MAX, k), 1.0)
	var beat := heartbeat(_ripe_phase)
	var r := Const.germ_radius(capacity)
	# Halodan geniş başlayır və zərbədə şişir — işıq gövdənin kənarından bayıra çıxır.
	var size := (r + SHIELD_GAP * HALO_GAP_SCALE) * (1.25 + 0.20 * beat)
	_ripe.scale = Vector2.ONE * (size * 2.0 / float(_ripe.texture.get_width()))
	_ripe.modulate = Color(Palette.DANGER,
		(0.40 + 0.60 * beat) * lerpf(0.80, 1.0, k) * _ripe_fade)


## Ürək döyüntüsünün forması; [param phase] 0..1 — iki zərbə ("lub-dub") və sükut.
##
## Sinus deyil: sinus nəfəs kimi oxunur və hər mikrobun boşdayanma nəfəsi ilə
## ([constant IDLE_BREATH]) qarışırdı. İki qısa zərbə və ardınca fasilə isə
## həyəcan siqnalıdır.
static func heartbeat(phase: float) -> float:
	var lub := exp(-pow((phase - 0.10) / 0.07, 2.0))
	var dub := 0.65 * exp(-pow((phase - 0.32) / 0.08, 2.0))
	return clampf(lub + dub, 0.0, 1.0)


## Döyüntünün teksturası — hazır ultinin aurasından ([method _shared_aura_texture])
## AYRIDIR. Aura sıxlığı mərkəzə yığır və orası gövdənin altında qalır: eyni
## tekstura ilə döyüntü kadrda demək olar görünmürdü (yoxlanılıb). Burada işıq
## gövdənin KƏNARINDA (radiusun ~35–50%-i) cəmlənir və bayıra sönür.
static func _shared_ripe_texture() -> GradientTexture2D:
	if _ripe_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.32, 0.50, 0.74, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.85),
			Color(1.0, 1.0, 1.0, 1.0),
			Color(1.0, 1.0, 1.0, 0.80),
			Color(1.0, 1.0, 1.0, 0.25),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		_ripe_texture = GradientTexture2D.new()
		_ripe_texture.gradient = gradient
		_ripe_texture.width = 128
		_ripe_texture.height = 128
		_ripe_texture.fill = GradientTexture2D.FILL_RADIAL
		_ripe_texture.fill_from = Vector2(0.5, 0.5)
		_ripe_texture.fill_to = Vector2(1.0, 0.5)
	return _ripe_texture


## Döyüntü İŞIQDIR, boya deyil: rəngi altındakına ƏLAVƏ olunur. Beləcə tünd
## döşəmədə parlaq qırmızı kənar verir və YÜKSƏK-də glow onu götürür.
static func _ripe_blend() -> CanvasItemMaterial:
	if _ripe_material == null:
		_ripe_material = CanvasItemMaterial.new()
		_ripe_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _ripe_material


## Bu kadr gövdə yenidən çəkilməlidirmi (bax [member redraw_step]).
func _redraw_due() -> bool:
	_redraw_phase += 1
	if _stale:
		_stale = false
		return true
	if redraw_step <= 1 or is_local:
		return true
	if _flash > 0.0 or _hit_squash_t > 0.0 or _fire_squash_t > 0.0 \
			or _eject_t >= 0.0 or _birth_t < BIRTH_TIME:
		return true
	return (_redraw_phase + color_index) % redraw_step == 0


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


## Aksopodiyalar iki keçiddir: əvvəl qalın tünd kontur, sonra nazik mineral
## özək. Tək parlaq xətt uzaqdan kirpik kimi görünürdü; tünd xarici keçid onu
## həm fondan ayırır, həm də bərk skelet materialı kimi oxudur.
## Hər keçiddə bütün seqmentlər bir multiline çağırışında qalır.
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
		draw_multiline(pts, Color(Palette.OUTLINE, 0.90), maxf(r * 0.14, 5.4))
		draw_multiline_colors(pts, cols, maxf(r * 0.065, 2.4))

	# Pəncələr — yapışma nöqtələri. Basılmış ucda TÜND yer ləkəsi və onun içində
	# kiçik mineral özək var: yalnız parlaq dairə sınananda ayaq havada bitən
	# tikan kimi görünürdü və hansı ayağın yük daşıdığı oxunmurdu.
	for i in _legs:
		var tip := _leg_tip(i, r)
		if tip == Vector2.ZERO:
			continue
		# Disklər ardıcıldır — bütün pəncələr bir çağırışa yığılır (bax [BatchDraw]).
		if _step[i] >= 1.0:
			BatchDraw.disc(self, tip, maxf(r * 0.14, 4.6), Color(Palette.OUTLINE, 0.78))
			BatchDraw.disc(self, tip, maxf(r * 0.065, 2.0), Color(_light, 0.82))
		else:
			BatchDraw.disc(self, tip, maxf(r * 0.06, 2.0), Color(_light, 0.45))


## İki qatlı kontakt kölgəsi. Dairə əvəzinə gövdənin hadisəsiz silueti işlənir:
## amöbdə dairə ön ləçəyin yanından çıxıb ayrıca ləkə olurdu. Hər iki qat eyni
## 0.62 ellips nisbətindədir və qlobal işığın əksinə, aşağı-sağa düşür.
func _draw_contact_shadow(ring: PackedVector2Array, r: float) -> void:
	var offset := -Palette.LIGHT_DIR * (r * 0.22)
	draw_colored_polygon(_ellipse_ring(ring, Vector2(1.15, 1.15 * 0.62), offset),
		Color(Palette.OUTLINE, 0.18))
	draw_colored_polygon(_ellipse_ring(ring, Vector2(1.0, 0.62), offset),
		Color(Palette.OUTLINE, 0.45))


static func _ellipse_ring(ring: PackedVector2Array, scale: Vector2,
		offset: Vector2) -> PackedVector2Array:
	var mid := _ring_centre(ring)
	var out := PackedVector2Array()
	out.resize(ring.size())
	for i in ring.size():
		out[i] = mid + (ring[i] - mid) * scale + offset
	return out


## Açıq sel-shading qatı əvvəl içəri çəkilir, qlobal işığa sürüşdürülür və sonra
## HƏQİQİ gövdə ilə kəsişdirilir. Əvvəl kəsmə yox idi: yuxarı-sol uc konturdan
## çıxıb çap sürüşməsi kimi görünürdü, kiçik sürüşmə isə tünd tonu nazik zolağa
## sıxırdı. 0.06 / 0.30 cütü tünd aşağı-sağ ayparanı təxminən 35–40% saxlayır.
##
## CPU kəsməsi hər kadrda ən çox on kiçik mikrob halqasında (amöbdə iki qatda)
## işləyir; Geometry2D bunu ucuz Clipper əməliyyatı ilə edir. Shader seçilmir,
## çünki layihənin gl_compatibility mobil yolu və iki tutqun sel tonu qorunmalıdır.
static func _lit_polygon(ring: PackedVector2Array, r: float) -> PackedVector2Array:
	var shifted := _shift(_inset(ring, r * LIT_INSET),
		Palette.LIGHT_DIR * (r * LIT_SHIFT))
	var clipped := Geometry2D.intersect_polygons(ring, shifted)
	var largest := PackedVector2Array()
	var largest_area := 0.0
	for polygon in clipped:
		var area := _ring_area(polygon)
		if area > largest_area:
			largest_area = area
			largest = polygon
	return largest


## Yaş material oxunuşu üçün tək, ağa yaxın spekulyar. Uzun ox işıq istiqamətinə
## dikdir və bütün ellips 0.56r daxilində qaldığı üçün ən dərin amöb ləçəyində də
## siluetin içindədir; ayrıca ikinci Clipper keçidinə ehtiyac yoxdur.
static func _specular_polygon(r: float) -> PackedVector2Array:
	var centre := Palette.LIGHT_DIR * (r * SPECULAR_OFFSET)
	var tangent := Vector2(-Palette.LIGHT_DIR.y, Palette.LIGHT_DIR.x)
	var half_size := SPECULAR_SIZE * (r * 0.5)
	var out := PackedVector2Array()
	for i in 14:
		var angle := TAU * float(i) / 14.0
		out.push_back(centre
			+ tangent * (cos(angle) * half_size.x)
			+ Palette.LIGHT_DIR * (sin(angle) * half_size.y))
	return out


## Aşağı-sağ kənarın həqiqi siluetini izləyən rim. İndeksdən bucaq çıxarmaq
## amöbdə səhv idi: onun nöqtə sırası deformasiya ilə dəyişir. İndi hər təpənin
## iki qonşu kənarından həqiqi çıxış normalı alınır və uyğun qövslərin ən uzunu
## seçilir; halqanın sonu ilə əvvəlinin birləşməsi ayrıca nəzərə alınır.
## Nöqtələr kontur və rim yarı-enlərinin cəmi qədər içəri çəkilir ki, parlaq
## xəttin heç bir yarısı siluetin bayırında ikinci kənar yaratmasın.
static func _rim_segment(ring: PackedVector2Array, inset_width: float) -> PackedVector2Array:
	var n := ring.size()
	if n < 3:
		return PackedVector2Array()

	var inside := _inset(ring, inset_width)
	var twice_area := 0.0
	for i in n:
		twice_area += ring[i].cross(ring[(i + 1) % n])
	var winding := 1.0 if twice_area >= 0.0 else -1.0

	var eligible := PackedByteArray()
	eligible.resize(n)
	for i in n:
		var incoming := (ring[i] - ring[(i - 1 + n) % n]).normalized()
		var outgoing := (ring[(i + 1) % n] - ring[i]).normalized()
		var normal_a := Vector2(incoming.y, -incoming.x) * winding
		var normal_b := Vector2(outgoing.y, -outgoing.x) * winding
		var normal := (normal_a + normal_b).normalized()
		eligible[i] = 1 if normal.dot(-Palette.LIGHT_DIR) > RIM_NORMAL_CUTOFF else 0

	var best_start := -1
	var best_count := 0
	for i in n:
		if eligible[i] == 0 or eligible[(i - 1 + n) % n] != 0:
			continue
		var count := 0
		while count < n and eligible[(i + count) % n] != 0:
			count += 1
		if count > best_count:
			best_start = i
			best_count = count

	var out := PackedVector2Array()
	if best_start < 0:
		return out
	for step in best_count:
		out.push_back(inside[(best_start + step) % n])
	return out


## Disk əvəzinə kənara doğru sıfıra sönən radial işıq. Teksturanın özü ağdır;
## mikrob rəngi və gərginlik alfası draw_texture_rect modulate-dan gəlir.
static func _shared_halo_texture() -> GradientTexture2D:
	if _halo_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.52, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.22),
			Color(1.0, 1.0, 1.0, 0.08),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		_halo_texture = GradientTexture2D.new()
		_halo_texture.gradient = gradient
		_halo_texture.width = 128
		_halo_texture.height = 128
		_halo_texture.fill = GradientTexture2D.FILL_RADIAL
		_halo_texture.fill_from = Vector2(0.5, 0.5)
		_halo_texture.fill_to = Vector2(1.0, 0.5)
	return _halo_texture


static func _shared_aura_texture() -> GradientTexture2D:
	if _aura_texture == null:
		var gradient := Gradient.new()
		# Mərkəz gövdənin altında qalır, ona görə sıxlıq ORTADA toplanıb —
		# işıq gövdənin kənarından bayıra "sızır".
		gradient.offsets = PackedFloat32Array([0.0, 0.40, 0.62, 1.0])
		gradient.colors = PackedColorArray([
			Color(1.0, 1.0, 1.0, 0.70),
			Color(1.0, 1.0, 1.0, 0.55),
			Color(1.0, 1.0, 1.0, 0.20),
			Color(1.0, 1.0, 1.0, 0.0),
		])
		_aura_texture = GradientTexture2D.new()
		_aura_texture.gradient = gradient
		_aura_texture.width = 128
		_aura_texture.height = 128
		_aura_texture.fill = GradientTexture2D.FILL_RADIAL
		_aura_texture.fill_from = Vector2(0.5, 0.5)
		_aura_texture.fill_to = Vector2(1.0, 0.5)
	return _aura_texture


## Doğuş halqası yerdə qalır; membran pop-u ilə birlikdə miqyaslanmır. Dairə
## yox, 0.62 ellips seçilib ki, kontakt kölgəsinin müstəvisində oxunsun.
func _draw_birth_ring(r: float) -> void:
	if _birth_t >= BIRTH_TIME:
		return
	var p := clampf(_birth_t / BIRTH_TIME, 0.0, 1.0)
	var radius := r * lerpf(0.45, 1.55, 1.0 - (1.0 - p) * (1.0 - p))
	var at := -Palette.LIGHT_DIR * (r * 0.22)
	draw_set_transform(at, 0.0, Vector2(1.0, 0.62))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36,
		Color(_light, 0.62 * (1.0 - p)), maxf(1.4, r * 0.045), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Təhlükə çatları 3–5 ədəddir və siluetin içinə doğru qısa qövslərdir. Say
## rəng indeksindən deterministik çıxır: təsadüfi seçim hər redraw-da çatları
## hoppadardı. Alfa konturla eyni 6 Hz nəbzi izləyir.
func _draw_danger_cracks(ring: PackedVector2Array, r: float, pulse: float) -> void:
	var count := 3 + posmod(color_index, 3)
	var mid := _ring_centre(ring)
	var hot := Palette.DANGER.lerp(Palette.WARNING, 0.38)
	for j in count:
		var idx := posmod(int(round(float(j) * float(ring.size()) / float(count))) + 2,
			ring.size())
		var outer := ring[idx].lerp(mid, 0.18)
		var inner := ring[idx].lerp(mid, 0.55)
		var normal := (ring[idx] - mid).normalized()
		var side := Vector2(-normal.y, normal.x)
		var kink := outer.lerp(inner, 0.48) + side * (r * (0.045 if j % 2 == 0 else -0.045))
		draw_polyline(PackedVector2Array([outer, kink, inner]),
			Color(hot, 0.42 + 0.48 * pulse), maxf(1.2, r * 0.035), true)


# ================================================================ çəkiliş

## Çəkiliş sırası qəsdən "əvvəlcə bütün dolu formalar, sonra bütün xətlər"
## şəklindədir. Godot kanvası eyni növ ardıcıl əmrləri bir çəkiliş çağırışına
## yığır — sıra qarışsa, hər mikrob 15-20 ayrıca çağırış olur və mobil GPU-da
## əsas məhdudiyyət məhz çağırış sayıdır.
func _draw() -> void:
	# GPU yolunda hər şey — super də — iki mesh qatındadır (bax [GermGPU]).
	if not alive or _gpu_row >= 0:
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

	# [method _body_ring]-in açılmış halı: forma BİR dəfə hesablanır. Kölgə
	# hadisəsiz formadan çəkilir və hadisə yoxdursa ikisi EYNİDİR — əvvəl hər
	# kadr iki dəfə qurulurdu, amöbün sürünən gövdəsi isə mikrobun ən bahalı
	# formasıdır (ölçülüb: brauzerdə çəkilişin ~15%-i).
	var shape := _shape_ring(r, true)
	var shadow_ring := shape if _shape_steady() else _shape_ring(r, false)
	var ring := _fit_hit(_event_deform(_strain(shape), r))
	var inner_ring := _inset(ring, maxf(r * CRAWL_BAND, CRAWL_BAND_MIN)) \
		if crawler else PackedVector2Array()
	var outline_w := clampf(r * 0.10, 2.4, 6.0)
	var danger_on := strain >= 0.75
	var danger_pulse := 0.5 + 0.5 * sin(_t * TAU * 6.0)
	var outline_tint := Palette.OUTLINE
	if danger_on:
		outline_tint = Palette.OUTLINE.lerp(Palette.DANGER, 0.45 + 0.50 * danger_pulse)

	# ---- dolu formalar ----
	if lod >= 1:
		draw_colored_polygon(_ellipse_ring(shadow_ring, Vector2(1.0, 0.62),
			-Palette.LIGHT_DIR * (r * 0.22)), Color(Palette.OUTLINE, 0.45))
	else:
		_draw_contact_shadow(shadow_ring, r)
	_draw_birth_ring(r)
	## Bioluminessensiya halosu: yastı disk yox, mərkəzdən kənara yumşaq sönən
	## paylaşılmış radial teksturadır. Gərginlik əvvəlki kimi işığı artırır.
	var halo_r := r + SHIELD_GAP * HALO_GAP_SCALE
	draw_texture_rect(_shared_halo_texture(),
		Rect2(-Vector2.ONE * halo_r, Vector2.ONE * (halo_r * 2.0)), false,
		Color(_base, 0.75 + 0.25 * strain))
	# Ulti hazırdır — EYNİ tekstura, qızılı və daha geniş. Disk DEYİL:
	# mikrobun ətrafına halqa qoymamaq qaydası burada da qüvvədədir (kirpik və
	# ayaqlar onunla yarışardı), ona görə hazır olmaq yumşaq işıqla deyilir,
	# üstündəki üç fırlanan qığılcım isə onu adi halodan ayırır.
	if _ready_fade > 0.004:
		var glow := 0.70 + 0.30 * sin(_t * 5.0)
		var aura_r := halo_r * 1.25
		draw_texture_rect(_shared_aura_texture(),
			Rect2(-Vector2.ONE * aura_r, Vector2.ONE * (aura_r * 2.0)), false,
			Color(Palette.SUPER_READY, glow * _ready_fade))
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
		# Qatlar TAM TUTQUNDUR. Şəffaf çəkiləndə ikisi bir-birini bulandırır
		# və nəticə iki material yox, bir palçıq ləkəsi olur. Eyni iki-tonlu
		# işıq hər qata ayrıca verilir ki, mexanizm itirmədən həcm qazansın.
		#
		# Rəng fərqi də QƏSDƏN böyükdür: zolaq oyunçunun rənginin AÇIQ,
		# iç isə TÜND variantıdır. Əvvəl ikisi də əsas rəngə yaxın idi və
		# gövdə tək rəngli ləkə kimi oxunurdu — referansdakı oxunuş (qalın
		# açıq zolaq + dolğun tünd iç) məhz bu addımdan asılıdır.
		var gel_dark := _light.lerp(Palette.OUTLINE, 0.30).lerp(Palette.DANGER, strain * 0.26)
		var gel_lit := _light.lerp(Palette.BODY_LIGHT, 0.28).lerp(Palette.DANGER, strain * 0.18)
		var sol_dark := _base.lerp(Palette.OUTLINE, 0.30).lerp(Palette.DANGER, strain * 0.30)
		var sol_lit := _base.lerp(Palette.BODY_LIGHT, 0.28).lerp(Palette.DANGER, strain * 0.20)
		_draw_skin(ring, r, gel_dark, gel_lit)
		_draw_skin(inner_ring, r, sol_dark, sol_lit)
	else:
		# Əvvəlki 0.30 alfa fonu gövdənin içindən göstərir və silueti öldürürdü.
		# İndi iki qat da TAM TUTQUNDUR: tünd baza + yuxarı-sola sürüşmüş açıq qat.
		var dark_skin := _base.lerp(Palette.OUTLINE, 0.30).lerp(Palette.DANGER, strain * 0.30)
		var lit_skin := _base.lerp(Palette.BODY_LIGHT, 0.28).lerp(Palette.DANGER, strain * 0.20)
		_draw_skin(ring, r, dark_skin, lit_skin)
	## Spekulyar hər üç növdə, amöbin iki material qatının isə yalnız üstündədir;
	## beləliklə yaş səth oxunur, daxildə əlavə “top” yaranmır.
	if lod < 1:
		draw_colored_polygon(_specular_polygon(r), Color(Palette.BODY_LIGHT, SPECULAR_ALPHA))
	# Daxili kölgə həcm üçündür, amöbdə isə həcmi ARTIQ iki qat verir —
	# üçüncü ləkə onların sərhədini bulandırır və "qalın zolaq + dolğun iç"
	# oxunuşunu itirir. Ona görə yalnız digər növlərdə çəkilir.
	var born_enough := _birth_t >= BIRTH_TIME or _birth_scale() > 0.42
	if not crawler and born_enough:
		_draw_core(r, strain)
	if born_enough:
		_draw_inner_balls(r)
		_draw_emerging_ball()

	# ---- qalın xarici kontur ----
	if crawler:
		# Amöbin konturu TÜNDDÜR və qalındır — həm bayırda, həm iki qatın
		# arasında. Bu xətt olmasa parlaq zolaq fona, iç isə zolağa qarışır.
		# Digər növlərdəki açıq membran xətti burada ÇƏKİLMİR: parlaq jel
		# zolağı onsuz da işıqlı haşiyə işini görür, üstünə ikinci açıq xətt
		# qoyulanda kənar ikiqat olur.
		draw_polyline(_closed(ring), Color(outline_tint, 0.95), outline_w, true)
		draw_polyline(_closed(inner_ring), Color(outline_tint, 0.95), outline_w * 0.58, true)
	else:
		draw_polyline(_closed(ring), Color(outline_tint, 0.95), outline_w, true)

	# ---- xətlər və hərəkət orqanları ----
	if born_enough:
		if rigid:
			_draw_legs(r)
			# Mineral skelet — bərk gövdənin daxili konturu. Yumşaq gövdələrdə
			# yoxdur, çünki onlarda belə bir sərhəd olmazdı.
			draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 28, Color(_light, 0.30), 1.6, true)
		elif not crawler:
			if lod >= 1:
				_draw_cilia_lite(r, rush, heading)
			else:
				_draw_cilia(r, rush, heading)
			_draw_tail(r, heading, rush)

	# Rim HƏR ŞEYDƏN sonra siluetin aşağı-sağ qövsünü geri çıxarır. Cilia və
	# ayaqlar onun üstünə düşsəydi gövdə ilə hərəkət orqanının sərhədi itərdi.
	var rim_w := maxf(1.4, r * 0.06)
	var rim := _rim_segment(ring, outline_w * 0.5 + rim_w * 0.5) if lod < 1 \
		else PackedVector2Array()
	if rim.size() >= 2:
		draw_polyline(rim, Color(_light, 0.55), rim_w, true)

	if danger_on:
		_draw_danger_cracks(ring, r, danger_pulse)

	# ---- super ----
	if _super_fade > 0.004:
		_draw_super(r)

	# ---- yoldaş nişanı ----
	#
	# Ad rəngi TƏK BAŞINA bəs etmir: döyüşdə göz gövdələrə baxır, adlara yox,
	# üstəlik ad mikrobun üstündə kiçik yazıdır və dolu ekranda itir. Halqa isə
	# siluetin öz kənarındadır — "bura atma" mesajı gövdənin özündən gəlir.
	#
	# Doğuş qalxanından ayrılır: qalxan KƏSİK və fırlanır, yoldaş halqası isə
	# bütöv və sakitdir. Rəng də heç bir oyunçunun rəngi deyil
	# ([constant Palette.ALLY]).
	if is_ally:
		draw_arc(Vector2.ZERO, r + SHIELD_GAP * 0.55, 0.0, TAU, 40,
			Color(Palette.ALLY, 0.72), 2.6, true)

	if safe:
		# Doğuş qalxanı — fırlanan kəsik halqa. Atəş açan kimi sönür.
		draw_arc(Vector2.ZERO, r + SHIELD_GAP, _t * 2.0, _t * 2.0 + PI * 1.4, 24,
			Color(Palette.TEXT, 0.55), 3.0, true)

	# ---- zərbə parıltısı ----
	# ƏN SONDA çəkilir: siluetin İÇİNDƏKİ hər şeyi (toplar, kirpik kökləri,
	# nüvə) örtməlidir, yoxsa parıltı yarımçıq qalır və zərbə oxunmur.
	# Kvadrat sönmə seçilib — xətti sönmə "ağ mikrob" kimi ilişib qalır.
	if _ready_fade > 0.004:
		_draw_ready_sparks(r)

	if _flash > 0.0:
		var f := 1.0 if _hitstop > 0.0 else _flash / FLASH_TIME
		draw_colored_polygon(ring, Color(Palette.HIT_FLASH, 0.92 * f * f))


## Super İŞLƏYƏRKƏN: amöbdə qabıq, ayaqlıda tor. Hər iki yol (GDScript və GPU)
## onu buradan çəkir.
func _draw_super(r: float) -> void:
	match species:
		Const.Species.AMOEBA:
			_draw_cyst(r, _super_fade)
		Const.Species.HELIOZOAN:
			_draw_net(r, _super_fade)
		_:
			pass


## Mikrobun GPU sətri — shader-in oxuduğu hər şey (bax [GermGPU], shaders/germ.gdshader).
##
## Dəyərlər [method _draw]-dakı ilə EYNİDİR və eyni funksiyalardan gəlir: kontur
## və kölgə konturu, mərkəzlər, rənglər, saatlar, ayaqların ucları. Kirpik, top,
## rim, çat, işıq qatı isə bu ədədlərdən shader-də qurulur.
func gpu_row_bytes() -> PackedByteArray:
	var r := Const.germ_radius(capacity)
	var strain := clampf((_shown_fill - 0.6) / 0.4, 0.0, 1.0)
	var rush := _rush()
	var heading := _heading()
	var danger_on := strain >= 0.75
	var pulse := 0.5 + 0.5 * sin(_t * TAU * 6.0)
	var tint := Palette.OUTLINE
	if danger_on:
		tint = Palette.OUTLINE.lerp(Palette.DANGER, 0.45 + 0.50 * pulse)
	var born := _birth_t >= BIRTH_TIME or _birth_scale() > 0.42
	var flash := 0.0
	if _flash > 0.0:
		flash = 1.0 if _hitstop > 0.0 else _flash / FLASH_TIME
	var legs := _legs if species == Const.Species.HELIOZOAN and born else 0
	var n := CRAWL_POINTS if species == Const.Species.AMOEBA else MEMBRANE_POINTS

	# ---- konturun ədədləri — konturun özü GPU-da qurulur (germ_shape.gdshader) ----
	# Hamısı köhnə yolun ÖZ funksiyalarından gəlir: forma (_membrane_args,
	# _crawl_scalars), toqquşma ellipsi, atəş dartılması (_eject_strain) və
	# hadisə deformasiyası (_event_params). Kölgə hadisəsiz formadır: dartılma
	# əlavəsi və hədd onda "transient = false" ilə hesablanır.
	var bonus := _accel_bonus()
	var cap := _base_stretch_cap()
	var hit := Sim.hit_shape(int(species), capacity, net_vel) if hit_fit else Vector3.ONE
	var amp := _eject_strain()
	var push := r * EJECT_DEPTH * amp if absf(amp) >= 0.002 else 0.0
	var e := _event_params(r)
	var axis: Vector2 = e[0]
	var shift: Vector2 = e[3]
	var jitter: Vector2 = e[6]
	var stretch := Vector2.ONE
	var shape: PackedFloat32Array
	if species == Const.Species.AMOEBA:
		var c := _crawl_scalars(r, heading, rush, 1.0, bonus, cap)
		var plain := _crawl_scalars(r, heading, rush, 1.0, 0.0, TOTAL_STRETCH_MAX)
		stretch = Vector2(c["pull"], plain["pull"])
		var head_c: Vector2 = c["head_c"]
		var tail_c: Vector2 = c["tail_c"]
		shape = PackedFloat32Array([
			head_c.x, head_c.y, tail_c.x, tail_c.y,
			c["head_r"], c["body_r"], c["tail_r"], c["spread"],
			fposmod(_crawl_t * 4.7, TAU), fposmod(_crawl_t * 3.1, TAU),
			fposmod(c["phase"], TAU), c["flow"],
			c["flow_mean"], CRAWL_CONE * rush, 0.0, 0.0,
		])
	else:
		var m := _membrane_args()
		stretch = Vector2(_stretch(m[2], bonus, cap), _stretch(m[2], 0.0, TOTAL_STRETCH_MAX))
		# Fazalar 2π-yə endirilir: GPU float32-dir, vaxt isə matç boyu böyüyür.
		shape = PackedFloat32Array([m[0], fposmod(_t * m[1], TAU),
			fposmod(_t * m[1] * 0.7, TAU), m[3]])

	var head := PackedFloat32Array([
		r, _t, rush, heading,
		strain, 1.0 if danger_on else 0.0, pulse, 1.0 if born else 0.0,
		float(n), 0.0, 0.0, clampf(r * 0.10, 2.4, 6.0),
		0.0, 0.0, aim, float(species),
		_base.r, _base.g, _base.b, 1.0,
		_light.r, _light.g, _light.b, 1.0,
		_shadow.r, _shadow.g, _shadow.b, 1.0,
		tint.r, tint.g, tint.b, 1.0,
		_core.x, _core.y, float(clampi(balls, 0, GermGPU.MAX_BALLS)), _ready_fade,
		_eject_t, _eject_span, _eject_dir, _eject_cross(),
		flash, 1.0 if _birth_t >= BIRTH_TIME else _birth_t / BIRTH_TIME,
		1.0 if safe else 0.0, 1.0 if is_ally else 0.0,
		float(legs), float(color_index), 1.0 if hit_fit else 0.0, _super_fade,
		hit.x, hit.y, hit.z, push,
		axis.x, axis.y, e[1], e[2],
		shift.x, shift.y, e[4], e[5],
		jitter.x, jitter.y, stretch.x, stretch.y,
	])
	head.append_array(shape)
	var out := head.to_byte_array()
	out.resize(GermGPU.LEGS0 * GermGPU.TEXEL)
	if legs > 0:
		# Ucun yeri, basılıbmı, varmı — [method _draw_legs]-in oxuduğu üç şey.
		var feet := PackedFloat32Array()
		feet.resize(legs * 4)
		for i in legs:
			var tip := _leg_tip(i, r)
			feet[i * 4] = tip.x
			feet[i * 4 + 1] = tip.y
			feet[i * 4 + 2] = 1.0 if _step[i] >= 1.0 else 0.0
			feet[i * 4 + 3] = 0.0 if tip == Vector2.ZERO else 1.0
		out.append_array(feet.to_byte_array())
	out.resize(GermGPU.WIDTH * GermGPU.TEXEL)
	return out


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


func _crawl_body(r: float, heading: float, rush: float, scale: float,
		extra_stretch := 0.0, stretch_cap := TOTAL_STRETCH_MAX) -> PackedVector2Array:
	var c := _crawl_scalars(r, heading, rush, scale, extra_stretch, stretch_cap)
	var axis: Vector2 = c["axis"]
	var side := Vector2(-axis.y, axis.x)
	var pull: float = c["pull"]
	var squash := 1.0 / pull
	var spread: float = c["spread"]
	var head_c: Vector2 = c["head_c"]
	var tail_c: Vector2 = c["tail_c"]
	var head_r: float = c["head_r"]
	var body_r: float = c["body_r"]
	var tail_r: float = c["tail_r"]
	var phase: float = c["phase"]
	var flow: float = c["flow"]
	var flow_mean: float = c["flow_mean"]

	# ---- disklərin birləşməsi ----
	# Orta disk mərkəzdə olduğu üçün onun çıxış məsafəsi elə öz radiusudur;
	# bu həm də mərkəzin HƏMİŞƏ gövdənin içində qalmasına zəmanət verir, yəni
	# kontur bucaq sırası ilə çəkilə bilir.
	var rays := PackedFloat32Array()
	rays.resize(CRAWL_POINTS)
	for i in CRAWL_POINTS:
		var dir := Vector2.from_angle(TAU * float(i) / float(CRAWL_POINTS))
		rays[i] = maxf(_reach(dir, Vector2.ZERO, body_r), maxf(_reach(dir, head_c, head_r),
			_reach(dir, tail_c, tail_r)))
	# İki dairənin kəsişməsi kəskin künc verir, canlı hüceyrədə isə belə künc
	# olmur — tikiş hamarlanır.
	rays = _smooth_ring(rays, CRAWL_SMOOTH)

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
		# Uroid arxa UCDA dar qabarıqdır. `sin` əsaslı konus kimi yanları yox,
		# altıncı dərəcə sayəsində yalnız quyruğun özünü böyüdür. Tam 0.16 yalnız
		# gövdə dartılanda açılır; yığılanda 0.08-ə qayıtmasa amöb yumrulanmırdı
		# (en/boy 1.37, qoruyucu hədd 1.35). Rush yox, məhz həndəsi `spread`
		# işlədilir: sürətli mikrobun yığılma kadrında rush hələ 1.0 qalır.
		var rear := maxf(cos(a - heading - PI), 0.0)
		m += UROID_BULGE * lerpf(0.50, 1.0, clampf(spread, 0.0, 1.0)) \
			* pow(rear, 6.0)

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


## Amöb gövdəsinin nöqtədən asılı OLMAYAN ədədləri — addımın vəziyyətindən çıxır:
## disklərin yeri və ölçüsü, dartılma, axın dalğası. [method _crawl_body] və GPU
## sətri ([method gpu_row_bytes]) eyni ədədləri işlədir — qayda bir yerdədir.
func _crawl_scalars(r: float, heading: float, rush: float, scale: float,
		extra_stretch: float, stretch_cap: float) -> Dictionary:
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
	# Sürünmənin öz dartılması ilə sürətlənmə eyni oxdadır və birlikdə 0.26-dan
	# yuxarı çıxmır. Zərbə/atəş vaxtı `stretch_cap` onlara yer saxlayır.
	var pull := 1.0 + minf(CRAWL_STRETCH * spread + extra_stretch, stretch_cap)
	# Sitoplazmanın axını — atılan psevdopodiya əvvəlcə nazikdir, sonra dolur.
	var mass := CRAWL_MASS * hauled
	# ---- kənarın öz həyatı ----
	# Perimetr dalğasının ORTA dəyəri fazadan asılıdır və çıxarılmasa gövdə
	# dövr boyu bütövlükdə şişib-büzülür. Aşağıdakı ifadə həmin ortanın dəqiq
	# həllidir: (1/PI)·∫₀^PI sin(u·k + p) du = [cos(p) − cos(PI·k + p)] / (PI·k)
	var phase := _crawl_t * TAU * 1.4
	return {
		"axis": axis,
		"spread": spread,
		"pull": pull,
		# Ön disk — psevdopodiya. Orta disk node-un üstündədir (sıfır nöqtəsi
		# həmişə gövdənin içində qalır, yəni kontur bucaq sırası ilə çəkilə bilir).
		"head_c": axis * lead,
		# Arxa uc yerə basılmış nöqtəyə DOĞRU dartılır — istiqamət dünyadan gəlir,
		# uzunluq isə gövdənin sərhədləri daxilində saxlanılır.
		"tail_c": _tail_dir * drag,
		"head_r": rad * (CRAWL_HEAD + mass),
		"body_r": rad * CRAWL_BODY,
		"tail_r": rad * (CRAWL_TAIL - mass),
		"phase": phase,
		"flow": CRAWL_FLOW_DEPTH * (0.35 + 0.65 * rush),
		"flow_mean": (cos(phase) - cos(PI * CRAWL_WAVES + phase)) / (PI * CRAWL_WAVES),
	}


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
		rush: float, bulge := 0.0, extra_stretch := 0.0,
		stretch_cap := TOTAL_STRETCH_MAX) -> PackedVector2Array:
	var stretch := _stretch(rush, extra_stretch, stretch_cap)
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


## Membranın ox boyunca dartılması. Sürətlənmə mövcud dartılmanın üstünə gəlir,
## amma cəmi heç vaxt 0.26-nı keçmir; `cap` zərbə və atəş kimi istiqamətli
## hadisələrə yer saxlayır. GPU sətri də bunu işlədir ([method gpu_row_bytes]).
static func _stretch(rush: float, extra: float, cap: float) -> float:
	return 1.0 + minf(STRETCH_MAX * rush + extra, cap)


## Kirpiklər — perimetr boyu döyünən tüklər (paramesium modeli).
##
## Hər kirpik iki parçadan ibarətdir: dibi membrana dik çıxır, ucu isə
## dalğaya görə yana əyilir. Faza bucaqla birlikdə sürüşür (metaxronal dalğa),
## ona görə halqa boyunca dalğa qaçır — bütün tüklər eyni anda döysəydi
## nəticə titrəyiş kimi görünərdi, üzmə kimi yox.
##
## Kirpik əvvəl dörd nöqtəli düz konus idi və uzaqdan tikan kimi görünürdü. İndi
## 1.30 dəfə uzun, ortası döyüntü fazası ilə yana qaçan altı nöqtəli lentdir;
## qırıq xətt yox, yumşaq əyilən tük kimi oxunur. Ayrı lentləri bir poliqonda
## birləşdirmək aralarını da doldurardı, ona görə çağırış sayı əvvəlki kimi
## kirpik başına birdir — artmır.
func _draw_cilia(r: float, rush: float, heading: float) -> void:
	var n := clampi(int(r * 0.42), CILIA_MIN, CILIA_MAX)
	var length := clampf(r * 0.26, 7.15, 13.0)
	# Hərəkətdə həm daha sürətli, həm daha geniş döyünür.
	var beat := CILIA_BEAT * (0.55 + 0.9 * rush)
	var sweep := 0.35 + 0.55 * rush
	# Dalğa getdiyi istiqamətin əksinə qaçır — mikrob suyu geri itələyir.
	var flow := heading + PI

	# Köklər MEMBRANIN üstündə oturur, təsəvvüri dairənin yox.
	#
	# Gövdə hərəkətdə ellipsə çevrilir ([method _membrane] eyni `stretch`/
	# `squash` cütünü tətbiq edir), köklər isə dairədə qalırdı: ellipsin en
	# kəsiyində kirpiklər membrandan qopub havada üzürdü, uzun uclarında isə
	# gövdənin İÇİNƏ girib itirdi. Ekranda "mikrob tük tökür" kimi oxunurdu.
	var stretch := 1.0 + STRETCH_MAX * rush
	var squash := 1.0 / stretch
	var axis := Vector2.from_angle(heading)
	var side := Vector2(-axis.y, axis.x)

	## Açıq gövdə tonuna yaxın sabit 0.85 alfa tükü gövdəyə bağlayır; dibdə ayrıca
	## tünd keçid yoxdur, çünki mövcud siluet konturu həmin işi artıq görür.
	var col := Color(_light.lerp(Palette.BODY_LIGHT, 0.18), 0.85)
	## Əvvəlki 0.040r kök qısa konusla birləşəndə kaktus tikanı yaradırdı.
	## Nazik, amma ucu sıfıra düşməyən lent yumşaq tük siluetini saxlayır.
	var root_half := maxf(r * 0.026, 0.85)
	var mid_half := root_half * 0.72
	var tip_half := maxf(root_half * 0.28, 0.24)
	for i in n:
		var a := TAU * float(i) / float(n)
		var phase := _t * beat - a * CILIA_WAVES
		var circle := Vector2.from_angle(a)
		# Çölə istiqamət ellipsin NORMALIDIR: dairənin normalı eyni əmsalların
		# TƏRSİ ilə miqyaslanır, yoxsa kirpik səthə dik çıxmır.
		var out := (axis * (circle.dot(axis) / stretch)
			+ side * (circle.dot(side) / squash)).normalized()
		var tangent := Vector2(-out.y, out.x)

		var base := circle * (r * 0.97)
		var root := axis * (base.dot(axis) * stretch) + side * (base.dot(side) * squash)
		var bend := sin(phase) * sweep
		# Ön tərəfdəki kirpiklər arxadakılardan daha az açılır: axın oradan gəlir.
		var lean := 0.45 + 0.55 * (0.5 - 0.5 * cos(a - flow))
		var mid := root + (out * 0.75 + tangent * bend).normalized() * (length * 0.55)
		var tip := mid + (out * 0.35 + tangent * (bend * 1.6)).normalized() * (length * 0.65 * lean)

		var first := mid - root
		var last := tip - mid
		if first.length_squared() < 0.001 or last.length_squared() < 0.001:
			continue
		var root_edge := Vector2(-first.y, first.x).normalized()
		var mid_axis := (tip - root).normalized()
		var mid_edge := Vector2(-mid_axis.y, mid_axis.x)
		var tip_edge := Vector2(-last.y, last.x).normalized()
		## Sol və sağ kənarlar kök–orta–uc yolunu ayrıca izləyir; orta enin 0.72
		## seçilməsi düyünü gizlədir, 0.28 ucluq isə iynə kimi sıfıra yığılmır.
		var ribbon := PackedVector2Array([
			root - root_edge * root_half,
			root + root_edge * root_half,
			mid + mid_edge * mid_half,
			tip + tip_edge * tip_half,
			tip - tip_edge * tip_half,
			mid - mid_edge * mid_half,
		])
		draw_colored_polygon(ribbon, col)


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
		# Quyruq konturdan SONRA çəkilir, ona görə kök 0.92 r-də başlayır:
		# əvvəlki 0.75 r kökü gövdənin içindən keçirib sel bandını örtərdi.
		pts.push_back(back * (r * 0.92 + span * u) + side * swing)

	# Sürət artdıqca bir az sönür: sürətli mikrobda diqqət bədənə və
	# kirpiklərə düşməlidir, quyruq isə hərəkət cizgisinə qarışır.
	var col := Color(_base, 0.60 - 0.20 * rush * rush)
	var wide := maxf(r * 0.10, 2.2)
	# İki qalınlıqlı xətt ucdakı keçidi pilləli edirdi. Bütöv lentdə en hər
	# nöqtədə azalır: kök enli və ağır, uc isə qamçı kimi nazikdir.
	draw_colored_polygon(_tapered_ribbon(pts, wide * 0.72, maxf(0.36, wide * 0.14)),
		Color(Palette.OUTLINE, 0.82))
	draw_colored_polygon(_tapered_ribbon(pts, wide * 0.48, maxf(0.18, wide * 0.055)), col)


static func _tapered_ribbon(path: PackedVector2Array, root_half: float,
		tip_half: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in path.size():
		var prev := path[maxi(0, i - 1)]
		var next := path[mini(path.size() - 1, i + 1)]
		var tangent := (next - prev).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		var u := float(i) / float(maxi(path.size() - 1, 1))
		var half := lerpf(root_half, tip_half, u)
		left.push_back(path[i] + normal * half)
		right.push_back(path[i] - normal * half)
	var out := PackedVector2Array(left)
	for i in range(right.size() - 1, -1, -1):
		out.push_back(right[i])
	return out


## Daxili kölgə — sitoplazmanın dərin qatı. Toplar bunun ÜSTÜNDƏ oturur,
## ona görə mikrob yastı disk yox, həcmli kisə kimi oxunur.
##
## Parlaq nüvəcik QƏSDƏN yoxdur: mərkəzdə ikinci bir işıqlı nöqtə topla
## qarışardı, top sayı isə oyunun əsas göstəricisidir — onu heç nə təqlid
## etməməlidir. İlk versiyada nüvəcik vardı və məhz belə oxunurdu.
##
## Kölgənin sürüşməsi daxili axını göstərir (bax [method _track_motion]):
## kirpiklidə geri qalır, ayaqlıda öndəki ayağa doğru axır.
## Gövdənin dərisi: tam detalda tünd rəng + işıqlı ləkə, MİNİMUM-da düz orta rəng.
func _draw_skin(ring: PackedVector2Array, r: float, dark: Color, lit: Color) -> void:
	if lod >= 1:
		draw_colored_polygon(ring, dark.lerp(lit, 0.45))
		return
	draw_colored_polygon(ring, dark)
	var shape := _lit_polygon(ring, r)
	if shape.size() >= 3:
		draw_colored_polygon(shape, lit)


## Kirpiklərin sadə halı — yarı sayda, iki seqmentli xətt, HAMISI bir çağırışda.
##
## Tam halda hər kirpik ayrıca lent poliqonudur və 18–30 çəkiliş çağırışı
## edir. Döyüntü, əyilmə və hərəkət istiqaməti eynidir — kirpikli yenə
## kirpikli kimi oxunur, sadəcə nazik cizgilərlə.
func _draw_cilia_lite(r: float, rush: float, heading: float) -> void:
	var n := clampi(int(r * 0.42), CILIA_MIN, CILIA_MAX) / 2
	var length := clampf(r * 0.26, 7.15, 13.0)
	var beat := CILIA_BEAT * (0.55 + 0.9 * rush)
	var sweep := 0.35 + 0.55 * rush
	var stretch := 1.0 + STRETCH_MAX * rush
	var squash := 1.0 / stretch
	var axis := Vector2.from_angle(heading)
	var side := Vector2(-axis.y, axis.x)
	var col := Color(_light.lerp(Palette.BODY_LIGHT, 0.18), 0.85)
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in n:
		var a := TAU * float(i) / float(n)
		var circle := Vector2.from_angle(a)
		var out := (axis * (circle.dot(axis) / stretch)
			+ side * (circle.dot(side) / squash)).normalized()
		var tangent := Vector2(-out.y, out.x)
		var base := circle * (r * 0.97)
		var root := axis * (base.dot(axis) * stretch) + side * (base.dot(side) * squash)
		var bend := sin(_t * beat - a * CILIA_WAVES) * sweep
		var mid := root + (out * 0.75 + tangent * bend).normalized() * (length * 0.55)
		var tip := mid + (out * 0.35 + tangent * (bend * 1.6)).normalized() * (length * 0.6)
		pts.append_array(PackedVector2Array([root, mid, mid, tip]))
		cols.append_array(PackedColorArray([col, col]))
	if not pts.is_empty():
		draw_multiline_colors(pts, cols, maxf(r * 0.04, 1.2))


func _draw_core(r: float, strain: float) -> void:
	BatchDraw.disc(self, _core, r * 0.62, Color(_shadow.lerp(Palette.DANGER, strain * 0.35), 0.45))


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
			#
			# Əmsallar 1.58 / 1.25 idi, yəni tünd halqa topun öz enindən qalın
			# çıxırdı: oyun içi ölçüdə (r ≈ 30 px) amöbin topları tutqun ləkəyə
			# dönürdü və SAYILA BİLMİRDİ — halbuki say həm sursat, həm candır.
			# Sistin içində, gövdə tündləşəndə vəziyyət daha da pisləşirdi.
			# İndi kontur nazik haşiyədir, parlaq hissə isə böyükdür.
			if lod >= 1:
				draw_colored_polygon(_star(p, dot * 1.36, a), tint if i % 2 == 0 else _light)
				continue
			draw_colored_polygon(_star(p, dot * 1.42, a), Palette.OUTLINE)
			draw_colored_polygon(_star(p, dot * 1.30, a), tint if i % 2 == 0 else _light)
			# İşıq nöqtəsi dairələrdəki ilə eyni səbəbdəndir: forma yox, PARLAQ
			# NÖQTƏ sayılır. Ulduzda yoxdur idi.
			if lit:
				BatchDraw.disc(self, p - Vector2(dot * 0.26, dot * 0.26), dot * 0.30,
					Color(Palette.TEXT, 0.75))
			continue
		# Toplar disk teksturası ilə çəkilir: hamısı (nüvə ilə birlikdə) BİR
		# çəkiliş çağırışıdır. Əvvəl hər top ayrıca `draw_circle` poliqonu idi və
		# 15 toplu mikrob kadrda 15–30 çağırış edirdi (bax [BatchDraw]).
		BatchDraw.disc(self, p, dot, Color(_light, 0.95))
		if lit and lod < 1:
			BatchDraw.disc(self, p - Vector2(dot * 0.3, dot * 0.3), dot * 0.35, Color(Palette.TEXT, 0.8))


## Amöbün superi — bağlı qabıq görüntüsü.
##
## Görüntü əvvəlki kistdəndir və oyunçunun istəyi ilə saxlanılıb: super artıq
## qalxan deyil (miniqandır, top ona adi kimi dəyir, bax [method
## Sim._step_germs]), amma görünüşü dəyişməyib.
##
## Gövdə artıq yumşaq deyil, ona görə qabıq gövdənin öz konturunu TƏKRARLAMIR:
## üstünə düzgün, sərt bir halqa oturur. Rəng mikrobun öz rəngindən çıxarılır,
## amma TÜNDLƏŞDİRİLİR.
## [param fade] 0..1 — qabıq bağlanarkən və açılarkən keçid (bax [member _super_fade]).
func _draw_cyst(r: float, fade := 1.0) -> void:
	# Qabıq həm SOLUR, həm də QAPANIR: açılan sist gövdəyə yaxınlaşıb itir.
	# Tək alfa ilə o, sadəcə şəffaflaşardı və "açıldı" hissi verməzdi.
	var shell := r + SHIELD_GAP * 0.5 * fade
	BatchDraw.disc(self, Vector2.ZERO, shell + 3.0, Color(Palette.OUTLINE, 0.55 * fade))
	# Qabıq qalınlaşdırılıb (7 → 10) və işıq tərəfində parıltı alıb: yeni
	# qalın konturlu gövdənin yanında köhnə qabıq gövdənin öz haşiyəsi kimi
	# oxunurdu, "üstünə bağlanmış zireh" kimi yox.
	draw_arc(Vector2.ZERO, shell, 0.0, TAU, 40,
		Color(_shadow.lerp(Palette.TEXT, 0.30), fade), 10.0, true)
	draw_arc(Vector2.ZERO, shell - 6.0, 0.0, TAU, 36, Color(_light, 0.40 * fade), 2.4, true)
	var lit := Palette.LIGHT_DIR.angle()
	draw_arc(Vector2.ZERO, shell + 1.0, lit - 0.9, lit + 0.9, 20,
		Color(Palette.TEXT, 0.70 * fade), 3.0, true)
	# Qabığın "tikişləri" — mineral lövhələr. Fırlanmır: sist tərpənmir.
	for i in 8:
		var ang := TAU * float(i) / 8.0
		var from := Vector2.from_angle(ang) * (shell - 6.0)
		var to := Vector2.from_angle(ang) * (shell + 2.0)
		draw_line(from, to, Color(Palette.OUTLINE, 0.7 * fade), 3.0)


## Hazır ultinin qığılcımları — gövdənin ətrafında fırlanan dörd ucu ulduzlar.
##
## Hamısı BİR `draw_multiline` çağırışıdır (hər ulduz iki xətt). Ayrıca
## çoxbucaqlı olsaydı, 10 mikrobun hər biri üçün üç çağırış olardı.
func _draw_ready_sparks(r: float) -> void:
	var orbit := r + SHIELD_GAP * 0.55
	var lines := PackedVector2Array()
	for i in READY_SPARKS:
		var ang := _t * 1.6 + TAU * float(i) / float(READY_SPARKS)
		var at := Vector2.from_angle(ang) * orbit
		# Hər qığılcım öz fazası ilə böyüyüb-kiçilir — üçü eyni anda
		# döyünəndə çarx kimi görünür.
		var s := maxf(7.0, r * 0.30) * (0.65 + 0.35 * sin(_t * 6.0 + float(i) * 2.1))
		lines.push_back(at + Vector2(-s, 0.0)); lines.push_back(at + Vector2(s, 0.0))
		lines.push_back(at + Vector2(0.0, -s)); lines.push_back(at + Vector2(0.0, s))
	draw_multiline(lines, Color(Palette.SUPER_READY.lerp(Color.WHITE, 0.3), _ready_fade),
		maxf(3.0, r * 0.09))


## Aksopodiya toru — ayaqlının superi.
##
## Şüalar uzanır, uclarındakı kinetosistlər parlayır. Torun SƏRHƏDİ də
## çəkilir: oyunçu qidanın hansı məsafədən axdığını, rəqib isə hara girməli
## OLMADIĞINI görməlidir — görünməyən sahə ədalətsiz olardı.
## [param fade] 0..1 — tor açılarkən və yığılarkən keçid (bax [member _super_fade]).
func _draw_net(r: float, fade := 1.0) -> void:
	var reach := r * Const.NET_RADIUS
	# Sərhəd — nəbz vuran halqa. Doldurulmur: içəridəki hər şeyi örtərdi.
	#
	# Alfa 0.14–0.24-dən 0.34–0.50-yə qaldırılıb və qalınlıq 2.5 → 3.5.
	# Əvvəlki dəyərlərdə sərhəd ekranda praktiki olaraq görünmürdü — yalnız
	# 3× böyüdülmüş şəkildə seçilirdi. Halqa isə torun ƏN VACİB hissəsidir:
	# rəqib hara girməli OLMADIĞINI ondan öyrənir, görünməyən sahə isə tələdir.
	#
	# İkinci dəfə gücləndirilib (kadr ardıcıllığı ilə yoxlanılıb): yeni tutqun
	# gövdə və parlaq döşəmə yanında 3.5 px-lik halqa yenə itirdi. İndi sahə
	# çox sönük DOLDURULUR — içəridəki hər şey oxunur, amma sahənin özü
	# "yer" kimi görünür — və sərhədin altında tünd altlıq var.
	var pulse := 0.5 + 0.5 * sin(_t * 3.4)
	BatchDraw.disc(self, Vector2.ZERO, reach, Color(_light, 0.07 * fade))
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 72,
		Color(Palette.OUTLINE, 0.35 * fade), 8.0, true)
	draw_arc(Vector2.ZERO, reach, 0.0, TAU, 72,
		Color(_light, (0.55 + 0.25 * pulse) * fade), 4.5, true)
	draw_arc(Vector2.ZERO, reach * 0.66, 0.0, TAU, 56,
		Color(_light, (0.18 + 0.10 * pulse) * fade), 2.2, true)

	# Uzanan şüalar. Ayaqların ÖZÜ deyil — onlar yerdə qalır; bunlar tordur.
	# Yığılanda şüalar da GERİ ÇƏKİLİR: tor sadəcə şəffaflaşmır, bağlanır.
	#
	# Əvvəl BÜTÜN şüalar, sonra uclar: xətt və disk növbələşsəydi, hər şüa iki
	# ayrı çəkiliş çağırışı olardı (bax [BatchDraw]).
	var n := 16
	var rays := PackedVector2Array()
	var tips := PackedVector2Array()
	for i in n:
		var ang := TAU * float(i) / float(n) + _t * 0.20
		var dir := Vector2.from_angle(ang)
		# Uzunluq növbə ilə dəyişir: bərabər uzunluqlu şüalar çarx kimi görünür.
		var len := reach * (0.72 + 0.28 * sin(_t * 2.2 + float(i) * 1.3))
		len = lerpf(r * 0.98, len, fade)
		rays.push_back(dir * (r * 0.98))
		rays.push_back(dir * len)
		tips.push_back(dir * len)
	draw_multiline(rays, Color(_light, 0.62 * fade), 2.6)
	for tip in tips:
		BatchDraw.disc(self, tip, 3.8, Color(Palette.TEXT, 0.75 * fade))


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
