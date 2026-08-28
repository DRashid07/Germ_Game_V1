extends Node
## Oyunun bütün paylaşılan sabitləri.
## Client və server EYNİ dəyərləri oxuyur — simulyasiya uyğunluğu buradan başlayır.

# ---------- Petri qabı (dünya) ----------
## Dünya dairəvidir və mərkəzi (0,0)-dır. Ekran dünyadan kiçikdir —
## kamera oyunçunu izləyir (io tipli oyunlarda standart həll).
const WORLD_RADIUS := 1200.0

## Kameranın göstərdiyi dünya sahəsi — ekranın QISA kənarı boyunca.
##
## Ölçü qısa kənara bağlanıb, enə YOX. Oyun yatay oynanır (1280×720), amma
## cihazların nisbəti müxtəlifdir və miqyas endən çıxarılsaydı, eyni dəyər
## hər nisbətdə başqa sahə verərdi: portretdə 620×1102, yatayda isə 620×349 —
## üç dəfə dar, yəni oyunçu qarşısındakı təhlükəni görməzdən ölərdi.
## Qısa kənardan çıxarılan miqyas nisbətdən asılı deyil: görünən sahə eyni
## qalır, sadəcə çevrilir (bax [method Arena._update_camera]).
##
## Böyük mikrob daha geniş sahə görür — həm ədalətlidir, həm böyüməni hiss etdirir.
const VIEW_SPAN_BASE := 620.0
const VIEW_SPAN_PER_RADIUS := 8.0
## Client-ə göndərilən sahə ekrandan bir qədər genişdir ki, obyektlər
## kənarda "peyda olmasın". 1.35 istənilən oriyentasiyada 20:9-a qədər bütün
## nisbətləri örtür (kadrın küncü mərkəzdən ən çox 1.22 × qısa kənar
## məsafədədir). Ölçü qısa kənara bağlı olduğuna görə yatay və portret üçün
## eyni ədəd işləyir — kadrın küncü hər iki halda eyni uzaqlıqdadır.
const AOI_FACTOR := 1.35

# ---------- Şəbəkə ----------
const TICK_RATE := 30
const TICK_DELTA := 1.0 / float(TICK_RATE)
const INTERP_DELAY := 0.1       ## Rəqiblər 100 ms geridə interpolate olunur
const DEFAULT_PORT := 27015
## Menyuda əvvəlcədən doldurulan server ünvanı.
## `wss://` olduğuna görə client avtomatik WebSocket nəqliyyatını seçir.
const DEFAULT_SERVER := "wss://germ-arena-production.up.railway.app"
const MAX_CLIENTS := 256
const INPUT_BUFFER_MAX := 64    ## Client-də reconciliation üçün saxlanan input sayı

## Bir dünyada maksimum CANLI oyunçu. Dolanda lobby yeni dünya açır.
const WORLD_CAPACITY := 10
## Dünya heç vaxt boş görünməməlidir — çatmayan yer bot mikroblarla doldurulur.
const MIN_POPULATION := 6

# ---------- Mikrob ----------
const START_BALLS := 5          ## Doğulanda içindəki top sayı
const START_CAPACITY := 10      ## İlk səviyyənin tutumu
const MIN_BALLS := 2            ## Bundan AZ olsa mikrob acından partlayır
const CAPACITY_STEP := 5        ## Hər partlatmaya görə tutum artımı
const MAX_CAPACITY := 60

const BASE_RADIUS := 28.0       ## START_CAPACITY tutumunda radius
const RADIUS_PER_CAPACITY := 1.15
## Hərəkət sürəti. Mikrob üzür, qaçmır — ekranın enini (620 px) təxminən
## 3 saniyəyə keçir. Sürətli hərəkət bu oyuna uyğun deyil: nişan almaq yoxdur,
## ona görə dəymə bacarığı MÖVQE tutmaqdan asılıdır, mövqe isə vaxt istəyir.
const BASE_SPEED := 190.0       ## piksel/saniyə

# ---------- Maye (qabın içindəki su) ----------
## Mikrob qatı bir mayenin içində üzür. Bu, yalnız görünüş deyil — hərəkətin
## ÖZÜ maye modelidir və simulyasiyanın bir hissəsidir (bax [method Sim._step_germs]).
##
## Sürətlənmə və sönmə QƏSDƏN iki ayrı əmsaldır:
##   • [constant FLUID_THRUST] — barmağını basanda nə qədər tez cavab verir (idarəetmə)
##   • [constant FLUID_DRAG]   — barmağını qaldıranda nə qədər sürüşür (maye hissi)
## Bir əmsal olsaydı, ikisindən biri həmişə yanlış olardı: tez cavab verən
## mikrob dərhal da dayanır, yumşaq sürüşən isə idarəolunmaz olur.
##
## Hər ikisi eksponensial sönmədir (`exp(-k·dt)`), addım ölçüsündən asılı deyil —
## server 30 Hz, client isə dəyişkən kadr sürəti ilə EYNİ nəticəni alır.
## Prediction üçün bu məcburidir.
const FLUID_THRUST := 5.5       ## 1/saniyə — hədəf sürətə yaxınlaşma tempi
const FLUID_DRAG := 2.6         ## 1/saniyə — itələmə kəsiləndə sönmə tempi

## Qabın içindəki axın. Su tam sakit deyil — yavaş burulğanlar var və
## hər şey (mikroblar, sərbəst qida) onlarla birlikdə sürüşür.
##
## Sahə YALNIZ MÖVQEDƏN asılıdır, vaxtdan yox. Bu, təsadüfi seçim deyil:
## client-in proqnoz [Sim]-i ilə serverin [Sim]-i ayrı tick sayğacları saxlayır,
## ona görə vaxtdan asılı axın iki tərəfdə fərqli çıxar və proqnoz titrəyərdi.
## Mövqedən asılı sahə isə hər iki tərəfdə eynidir.
const CURRENT_STRENGTH := 38.0  ## piksel/saniyə — burulğanın ən güclü nöqtəsi
## Burulğanın dalğa uzunluğu (piksel).
##
## Bu rəqəm EKRANIN ENİ ilə müqayisədə seçilir, dünyanın ölçüsü ilə yox.
## Əvvəl 760 idi — başlanğıc ekranından (620 px) BÖYÜK. Nəticədə ekrandakı
## bütün zərrəciklər eyni tərəfə baxırdı və oyunçu burulğanı heç vaxt görmürdü;
## axın "hiss olunmayan yüngül sürüşmə" kimi qalırdı.
##
## 430 px-də ekrana təxminən 1.5 burulğan sığır: zərrəciklərin cizgiləri
## əyilir, fırlanma gözlə oxunur. Daha kiçik etmək olmaz — mikrob saniyədə
## bir neçə burulğan keçər və axın nizam yox, səs-küy kimi görünər.
const CURRENT_SCALE := 430.0
const CURRENT_SWIRL := 18.0     ## piksel/saniyə — qabın ümumi fırlanması
## Şüşəyə yaxın maye dayanır (yapışma qatı). Bu, həm fizikadır, həm zərurət:
## kənarda sıfırlanmasa axın hər şeyi divara sıxardı.
## Zolaq geniş saxlanılır — dar keçid sərhəddə güclü yan axın yaradır.
const CURRENT_EDGE := 0.70      ## bu nisbətdən sonra axın sıfıra enməyə başlayır
## Doğulanda toxunulmazlıq (atəş açanda dərhal bitir). Uzun olmalıdır:
## 10 nəfərlik dünyada oyunçu izdihamın ortasında doğula bilər.
const SPAWN_SAFE_TIME := 4.0

## Metabolizm: mikrob vaxt keçdikcə top itirir — yemək məcburidir.
## Böyük mikrob daha tez yanır, bu da liderin sonsuz böyüməsinin qarşısını alır.
const DRAIN_PERIOD := 6.0       ## START_CAPACITY tutumunda bir topun yanma müddəti
const DRAIN_PER_CAPACITY := 0.22
const DRAIN_MIN_PERIOD := 2.2

# ---------- Atəş (top atmaq) ----------
## Saniyədə bir top. Rəqəm oyunun bütün gərginliyini müəyyən edir:
## dolu mikrob da saniyədə yalnız bir top boşalda bilir, ona görə
## 10/10 vəziyyətdə gəzmək ölümcüldür — bir dəymə bəs edir.
const FIRE_COOLDOWN := 1.0
## Atəş üçün lazımi minimum top.
##
## MIN_BALLS-dan İKİ çoxdur, təsadüfən deyil: atəşdən sonra oyunçuda ən azı
## MIN_BALLS + 1 top qalır, yəni ölümə bir yox, iki metabolizm dövrü qalır.
## Bir dövr qalsaydı, qanuni atəş oyunçunu dərhal ölüm həddinə salardı —
## sınaqda insansız client məhz belə 6 saniyəyə acından partlayırdı.
const FIRE_MIN_BALLS := 4
## Dəyən top rəqibin içində NEÇƏ topa çevrilir (bölünmə).
##
## Bu rəqəm 1 saniyəlik atəş dövrünün nəticəsidir və oyunun işləməsi üçün
## MƏCBURİDİR. Hesab sadədir: sən saniyədə 1 top göndərirsən, rəqib də
## saniyədə 1 top ataraq boşalır — 1:1 olsaydı, rəqib heç vaxt dolmazdı və
## diqqətli oyunçunu partlatmaq riyazi olaraq mümkün olmazdı (45 saniyəlik
## sınaqda bir dənə də partlama olmadı). 2 ilə hücum edən saniyədə +1 qazanır.
##
## Oyun dünyasında izahı var: mikrob topu düşmənin içinə girib BÖLÜNÜR.
const SHOT_PAYLOAD := 2
## Topun sürəti mikrobun sürəti ilə BİRLİKDƏ tənzimlənməlidir. Nisbət ~2.2-dir:
## bu qədər olanda topu görüb yana çəkilmək mümkündür, amma nişan almaq da
## çətin deyil. Mikrob yavaşlayıb top eyni qalsaydı, qaçmaq mümkünsüz olardı
## (sınaqda oyunçu doğuşdan 2.5 saniyə sonra partlayırdı).
const SHOT_SPEED := 420.0

## Cərəyan deşiyinin ən güclü nöqtəsindəki itələmə (piksel/saniyə).
##
## BASE_SPEED-in ~2.2 mislidir: deşik oyunçunu ÖZ sürətindən aydın şəkildə
## tez aparmalıdır, yoxsa "keçdim və heç nə olmadı" hissi qalır. Daha güclüsü
## isə idarəni tam əlindən alır — mikrob deşikdən çıxana qədər oyunçu
## seyrçiyə çevrilir.
const VENT_SPEED := 420.0
const SHOT_RADIUS := 9.0
const SHOT_LIFETIME := 2.2       ## × sürət ≈ 920 px məsafə (ekran eninin 1.5 misli)
const SHOT_BOUNCES := 2         ## Divardan/maneədən neçə dəfə sıçraya bilər
const SHOT_RECOIL := 90.0       ## Top atanda mikrobun geri təpməsi (sürətə nisbətdə hiss olunur)

# ---------- Qida ----------
const FOOD_RADIUS := 10.0
const FOOD_TARGET := 110        ## Dünyada saxlanılan qida sayı
const FOOD_SPAWN_RATE := 8.0    ## saniyədə neçə ədəd doğulur (hədəfə çatana qədər)
const FOOD_MIN := 8            ## Qab nə qədər darsa da, bundan az qida qalmır

## Bir snapshot-da göndərilən ƏN ÇOX qida sayı.
##
## Ekranı doldurmağa bəs edir: ən iri mikrobun görüş sahəsində belə 20:9
## nisbətdə ekranın kənarlarına qədər çatır. Qalanı kadrdan onsuz da kənardadır.
const FOOD_SEND_MAX := 32

## Bir snapshot-da göndərilən ən çox TOP və HADİSƏ sayı.
##
## Snapshot-un dəyişkən hissəsi budur: qida hədləndikdən sonra da paket
## bəzən MTU-nu aşırdı (13 çalışmadan birində 1420 bayt), çünki döyüş
## qızışanda uçan topların və hadisələrin sayının YUXARI HƏDDİ yox idi.
##
## Ən uzaqdakılar atılır: ekranın kənarındakı top onsuz da bir neçə kadr
## sonra görünəcək, itən snapshot isə HAMISINI aparır.
const SHOT_SEND_MAX := 16
const EVENT_SEND_MAX := 12

## ENet-in bir paketə sığdırdığı ən çox bayt.
##
## Bundan böyük paket PARÇALANIR, snapshot isə `unreliable_ordered` gedir —
## bir parçanın itməsi bütün snapshot-u itirir. Godot xəbərdarlığı budur:
## "Sending 1448 bytes unreliably which is above the MTU (1392)".
const MTU_SAFE := 1392

## Bir elementin snapshot-dakı bayt qiyməti (sıx massivlərdə sabitdir).
##
## Büdcə hesabı bunlarla aparılır (bax [method World.snapshot_for]): sabit
## hədlər KİFAYƏT ETMİR, çünki hər hədd ayrılıqda məqbul görünür, birlikdə isə
## paket MTU-nu aşır — ölçülüb, 10 mikrob + 16 top + 12 hadisə + 32 qida
## birlikdə 1604 bayt verirdi.
const GERM_BYTES := 36
const SHOT_BYTES := 24
const EVENT_BYTES := 20
const FOOD_BYTES := 12

## Dəyişməyən sahələr + massiv başlıqları + ehtiyat.
const SNAP_FIXED := 330
const FOOD_FRICTION := 1.8      ## Səpilən topların sürtünməsi (1/saniyə)
## Atılan top qidaya çevriləndən sonra sahibi onu bu qədər müddət yeyə bilmir —
## əks halda öz atdığını dərhal geri udardı.
const FOOD_ARM_TIME := 0.7

enum EvKind { FIRE = 0, ABSORB = 1, HIT = 2, BURST = 3, BREAK = 4, SUPER = 5, SPORE = 6 }

## Mikrobun növü. Həm görüntü, həm OYNANIŞ — hər növün mühitlə münasibəti
## başqadır (bax [constant SPECIES_THRUST]) və hər birinin öz superi var.
## Döyüş riyaziyyatı isə üçündə də eynidir
## (bax [GermVisual]). Buna baxmayaraq [Sim]-də saxlanılır, çünki oyunçunun
## seçimidir və bütün client-lərə eyni çatmalıdır: hər kəs eyni mikrobu eyni
## növdə görməlidir.
enum Species { CILIATE = 0, HELIOZOAN = 1, AMOEBA = 2 }

# ---------- Oyun rejimləri ----------
## Rejim DÜNYANIN xassəsidir, oyunçunun yox: bir dünyada hamı eyni qaydada
## oynayır. Lobby oyunçunu istədiyi rejimə uyğun dünyaya yerləşdirir.
##
## Tam qaydalar `design/MODES.md`-dədir — rəqəm dəyişəndə hər ikisi yenilənməlidir.
enum Mode {
	ENDLESS = 0,   ## SONSUZ ARENA — matç yoxdur, qab sabitdir. Standart rejim.
	SOLO = 1,      ## TƏK QALAN — 10 mikrob, qab quruyur, sona qalan udur.
}

## Matçın fazası.
##
## SONSUZ ARENA həmişə [constant Phase.PLAYING]-dədir və oradan çıxmır —
## belə olanda kod BİR yoldan gedir və köhnə rejim yeni sistemin altında
## toxunulmaz qalır.
enum Phase {
	WAITING = 0,    ## Oyunçu gözlənilir
	COUNTDOWN = 1,  ## Geriyə sayım — mikroblar görünür, giriş bağlıdır
	PLAYING = 2,
	OVER = 3,       ## Qalib bəlli oldu, nəticə göstərilir
}

## Geriyə sayım. NÖVBƏ YOXDUR — oyunçu OYNA basan kimi matç qurulur, boş
## yerləri botlar tutur. Oyunçu bazası kiçikdir: növbə "boş oyun" hissi
## yaradır (gözləyirsən, heç kim gəlmir, çıxırsan).
const COUNTDOWN_TIME := 3.0
## Nəticə ekranı göstərildikdən sonra dünya bağlanır.
const RESULT_TIME := 7.0
## Təhlükəsizlik həddi: heç bir matç bundan uzun sürmür. Bitəndə ən çox topu
## olan udur — qab onsuz da o vaxta kimi tam qurumuş olur.
const MATCH_MAX := 240.0

# ---------- Quruyan qab ----------
## Daralan sahənin çölündə mikrob top İTİRMİR — top QAZANIR.
##
## Qab quruyur, mühit qatılaşır, mikrob dolub partlayır. Üç səbəbdən
## aclıqdan yaxşıdır: oyunun imza ölümünü işlədir; kənarı dilemmaya çevirir
## (həm təhlükə, həm yem); dolu oyunçunu mərkəzə sıxır, ac oyunçu isə orada
## nəfəs ala bilir.
const DRY_DELAY := 45.0          ## Quruma bu qədər saniyədən sonra başlayır
const DRY_TIME := 105.0          ## Tam qurumaya qədər
const SOLO_END_RADIUS := 250.0   ## Əsas qurumanın sonu — 10 mikrob burada rastlaşır

## Matçın son anında qabın radiusu.
##
## Əsas quruma [constant SOLO_END_RADIUS]-də dayanmır, çünki orada DAYANSAYDI,
## matç praktikada həmişə vaxt limiti ilə bitərdi: 250 px-lik qabda son iki
## mikrob bir-birindən qaça bilir və 90 saniyə heç nə baş vermir. Ölçülüb —
## beş matçın beşi 240 saniyəyə, 2 sağ qalanla bitirdi.
##
## Ona görə quruma matçın SONUNA qədər davam edir, sadəcə yavaş. Bu radiusda
## iki mikrobun gövdəsi qaba sığmır — rastlaşma məcburidir.
const SOLO_MIN_RADIUS := 90.0
## Quru zonada bir topun yığılma müddəti. Metabolizm 6 saniyəyə BİR top
## yandırır — quruma ondan 5 dəfə sürətlidir, yəni orada qalmaq real
## qərardır, adət deyil.
const DRY_GAIN_PERIOD := 1.2
## Kənardan uzaqlaşdıqca sürətlənir: bu məsafədə period yarıya düşür.
const DRY_RAMP := 260.0

# ---------- Spor ----------
## Brawl Stars-ın güc kubunun qarşılığı. Bizdə artan şey TUTUMDUR — onsuz da
## partlatmanın mükafatı odur, yəni iki yol bir mükafata aparır.
const SPORE_COUNT := 3           ## Qabda eyni anda
const SPORE_RESPAWN := 20.0      ## Yeyiləndən sonra
const SPORE_RADIUS := 22.0       ## Adi qida 10-dur
const SPORE_CAPACITY := CAPACITY_STEP


# ---------- Növ özəllikləri ----------
## Hər növün MÜHİTLƏ münasibəti başqadır — güc fərqi yox, münasibət fərqi.
##
## Biri suda üzür: su onu həm daşıyır, həm aparır. Biri dibdə yeriyir: pəncələri
## yapışır, axın onu tərpədə bilmir. Biri sürünür: divarlar onu saxlamır.
## Üç orqanizmin əsl ekologiyası da elə budur (planktonik, bentik, substrat).
##
## QAYDA: bu əmsalların heç biri döyüş riyaziyyatına toxunmur —
## [constant SHOT_PAYLOAD], [constant FIRE_COOLDOWN], [constant CAPACITY_STEP]
## və [constant MIN_BALLS] hər üç növdə eynidir. Onlar dəyişsə oyun sınır
## (bax həmin sabitlərin öz izahına) və "güclü növ" yaranar.
##
## İndeks [enum Species] ilə eynidir.

## Barmağı basanda hədəf sürətə nə qədər tez çatır.
const SPECIES_THRUST: Array[float] = [1.35, 1.00, 0.85]
## Barmağı buraxanda nə qədər tez dayanır. Kirpikli sürüşməyə davam edir.
const SPECIES_DRAG: Array[float] = [0.85, 1.00, 1.00]
## Axın və cərəyan deşiyi onu nə qədər aparır. Ayaqlının pəncələri yapışır.
const SPECIES_FLOW: Array[float] = [1.15, 0.55, 1.00]
## Üst sürət. Ayaqlı yeriyir, üzmür.
const SPECIES_SPEED: Array[float] = [1.00, 0.95, 1.00]
## MANEƏ ilə toqquşma radiusu — amöb sabit formasız olduğu üçün dar yerdən keçir.
##
## YALNIZ maneələr üçündür. Topa hədəf kimi, kamera üçün və membranın
## çəkilişində radius DƏYİŞMİR: bu, ərazi özəlliyidir, döyüş özəlliyi yox.
const SPECIES_BODY: Array[float] = [1.00, 1.00, 0.78]

# ---------- Super ----------
## Doluluq 0..15 — dörd bit. Rəqəm təsadüfi deyil: bayraq sahəsinin boş
## bitlərinə (3–6) tam sığır, yəni snapshot bir bayt da böyümür
## (bax [enum GFlag]).
const SUPER_MAX := 15
## Atdığın top rəqibə dəydi. Əsas yol — super hücum edəni mükafatlandırır.
const SUPER_ON_HIT := 3
## Sənə top dəydi. Sıxılan oyunçuya çıxış yolu: üç superdən ikisi qaçış
## vasitəsidir və məhz o an lazım olur.
const SUPER_ON_TAKEN := 1
## Neçə qidadan bir doluluq artır. Dinc oyunçu da doldurur, sadəcə yavaş.
const SUPER_FOOD_PER := 3

## KİRPİKLİ — trixosist partlayışı.
## Gövdənin hər tərəfindən iynələr atılır: yaxındakı rəqib topları dağılır,
## mikroblar itələnir, özü geriyə sıçrayır.
const TRICHO_RADIUS := 3.5      ## öz radiusuna nisbətdə
const TRICHO_COST := 2          ## top — trixosist maddədir, boşuna atılmır
const TRICHO_PUSH := 520.0      ## piksel/saniyə, mərkəzdə
const TRICHO_DASH := 260.0      ## öz geri sıçrayışı

## AYAQLI — aksopodiya toru.
const NET_TIME := 4.0
const NET_RADIUS := 4.0         ## öz radiusuna nisbətdə
const NET_PULL := 420.0         ## qida bu sürətlə axır
const NET_SLOW := 0.60          ## tora düşən rəqibin sürət əmsalı

## AMÖB — sistləşmə. Qabıq bağlıdır: top səkir, metabolizm dayanır,
## amma nə hərəkət var, nə atəş.
const CYST_TIME := 2.5
## Növ snapshot-da neçə bit tutur — [enum GFlag] bunu istifadə edir.
const SPECIES_COUNT := 3


## Xam ədədi rejimə çevirir; tanınmayan hər şey sonsuz arenaya düşür.
##
## Növdəki [method species_from] ilə eyni səbəb: dəyər client-dən gəlir və
## etibarsız ola bilər. Çevirmə BİR yerdə olanda "yad dəyər gələndə nə olur"
## sualının bir cavabı olur.
static func mode_from(value: int) -> Mode:
	if value == int(Mode.SOLO):
		return Mode.SOLO
	return Mode.ENDLESS


## Sıra sayının Azərbaycanca şəkilçisi: 1-ci, 3-cü, 6-cı, 9-cu.
##
## Şəkilçi RƏQƏMDƏN deyil, onun OXUNUŞUNDAN asılıdır — saitlərin ahəngi
## şəkilçini dəyişir: doqquz → doqquzuncu, ona görə "9-cu"; altı → altıncı,
## ona görə "6-cı". Sadə "%d-ci" şablonu bu iki yerdə səhv yazır və matçın
## nəticə ekranı oyunçunun ən çox baxdığı yazıdır.
##
## Cədvəl 1..10 üçündür: yerlərin sayı [constant WORLD_CAPACITY]-dən çox
## ola bilməz, çünki hər yer bir mikroba verilir.
static func ordinal(n: int) -> String:
	const SUFFIX := ["", "-ci", "-ci", "-cü", "-cü", "-ci", "-cı", "-ci", "-ci", "-cu", "-cu"]
	if n >= 1 and n < SUFFIX.size():
		return "%d%s" % [n, SUFFIX[n]]
	return "%d-ci" % n


static func mode_name(mode: int) -> String:
	return "TƏK QALAN" if mode == int(Mode.SOLO) else "SONSUZ ARENA"


## Xam ədədi növə çevirir; tanınmayan hər şey kirpikliyə düşür.
##
## Bu funksiya BİR yerdədir və üç ayrı giriş nöqtəsi onu işlədir: serverdə
## client-in göndərdiyi dəyər ([method Lobby.join]), client-də serverin
## qaytardığı dəyər ([method Arena._species_from]) və diskdən oxunan ayar.
## Üçü də ETİBARSIZ ola bilər — client mesaj uydura bilər, ayar faylı isə
## əl ilə redaktə oluna bilər. Çevirmə bir yerdə olanda "yad dəyər gələndə
## nə olur" sualının bir cavabı olur.
static func species_from(value: int) -> Species:
	if value < 0 or value >= SPECIES_COUNT:
		return Species.CILIATE
	return value as Species

# ---------- Snapshot sahə indeksləri ----------
## Snapshot Dictionary yox, Array-dir — 30 Hz-də hər bayt sayılır.
## Bu enum-lar həmin massivlərə ad verir ki, kod oxunaqlı qalsın.
## Server tərəfdə [method World.snapshot_for] eyni sıranı qurur.

## WALLS sonda əlavə olunub, ortada yox: client sahələri İNDEKSLƏ oxuyur,
## ona görə mövcud indeksləri sürüşdürmək bütün oxumaları sındırardı.
## MATCH də sonda əlavə olunub, eyni səbəbdən (bax yuxarı).
enum Snap { TICK, GERMS, SHOTS, FOOD, EVENTS, BOARD, POP, WALLS, MATCH, SELF }

## [constant Snap.SELF] sahəsi — YALNIZ qəbul edən oyunçunun öz mikrobuna aid.
##
## Bu iki ədəd əvvəl HƏR mikrobun sətrində gedirdi, halbuki heç bir oyunçu
## rəqibinin təsdiqlənmiş giriş nömrəsini və ya atəş soyumasını istifadə etmir:
## client kodunda ikisinin də CƏMİ BİR oxunuşu var və o da öz mikrobunadır.
## On mikrobluq dünyada bu, hər tick-də doqquz dəfə boş yerə göndərilirdi.
enum SelfF { ACK, CD }

## [constant Snap.MATCH] massivinin sahələri.
##
## Dünya başına BİR dəfə gedir, mikrob başına yox — ona görə qiyməti mikrob
## sayından asılı deyil: 6 ədəd × 9 bayt = 54 bayt/snapshot.
enum MF {
	MODE,     ## int   — [enum Mode]
	PHASE,    ## int   — [enum Phase]
	CLOCK,    ## float — fazanın öz saatı (saniyə)
	RADIUS,   ## float — yaş radius. Client düsturla da hesablaya bilər, amma
	          ##         bir float göndərmək faza keçidlərində səhv riskini silir
	ALIVE,    ## int   — sağ qalan mikrob sayı
	PLACE,    ## int   — baxanın yeri (0 = hələ sağdır)
}
## Snapshot-dakı mikrob sətri.
##
## Sətir SANİYƏDƏ 30 DƏFƏ, görünən hər mikrob üçün gedir — ona görə burada
## yalnız hər kadr DƏYİŞƏN və HƏR KƏSƏ lazım olan sahələr qalır:
##
##   • ad və rəng SABİTDİR — [method Net.on_roster] ilə bir dəfə göndərilir;
##   • təsdiq nömrəsi və atəş soyuması yalnız ÖZ mikrobuna lazımdır —
##     [enum SelfF]-ə köçürülüb.
##
## Səbəb ölçülüb: on mikrobla ən pis snapshot 2224 bayt idi, ENet-in MTU-su
## isə 1392. Aşan paket parçalanır və `unreliable_ordered` olduğuna görə bir
## parçanın itməsi BÜTÜN snapshot-u itirir.
enum GF { ID, X, Y, VX, VY, AIM, BALLS, CAP, FLAGS }

## Bir mikrobun sıx axındakı ədəd sayı — [enum GF]-dən ID-siz.
##
## ID ayrıca [PackedInt32Array]-dədir: peer nömrələri 32 bitlik təsadüfi
## ədədlərdir və `float32`-nin 24 bitlik mantissası onları POZARDI.
const GERM_STRIDE := 8


## Sıx mikrob axınını oxunaqlı sətirlərə açır: `[id, x, y, vx, vy, aim, ...]`.
##
## Şəbəkəyə sıx gedir, client-də isə sətirlərə açılır. Səbəb ölçülüb: Variant
## massivində hər ədəd ~9 bayt tutur, `PackedFloat32Array`-də 4 — səkkiz
## mikrobluq sahə 668 baytdan 304-ə düşür. Açma client tərəfdə pulsuzdur,
## çünki onsuz da hər snapshot bir dəfə gəzilir.
static func unpack_germs(field: Array) -> Array:
	var ids: PackedInt32Array = field[0]
	var d: PackedFloat32Array = field[1]
	var out := []
	for i in ids.size():
		var b := i * GERM_STRIDE
		out.append([ids[i], d[b], d[b + 1], d[b + 2], d[b + 3],
			d[b + 4], d[b + 5], d[b + 6], d[b + 7]])
	return out

## [constant GF.FLAGS] sahəsinin bitləri.
##
## Növ AYRICA sahə kimi göndərilmir: bu sətir hər mikrob üçün saniyədə
## 30 dəfə gedir və Variant massivində hər ədəd 9 bayt tutur. Toxunulmazlıq
## onsuz da 0/1 idi, yəni sahənin qalan bitləri boş yatırdı — növ oraya
## girir və şəbəkəyə SIFIR bayt əlavə olunur.
##
##   bit 0      → doğuş qalxanı
##   bit 1-2    → növün nömrəsi (0..3)
##   bit 3-6    → superin doluluğu (0..15)
##   bit 7      → super İNDİ işləyir (tor açıqdır / qabıq bağlıdır)
##
## Növə İKİ bit ayrılıb, biri yox: üçüncü növ (amöb) əlavə olunanda bir bit
## çatmadı. İki bit dördüncü növə də yer saxlayır.
##
## Doluluq da eyni sahəyə girir və [constant SUPER_MAX] məhz buna görə 15-dir —
## dörd bitin tuta bildiyi ən böyük ədəd. Beləliklə RƏQİBİN superinin hazır
## olduğu da görünür (gərginlik oradan gəlir) və şəbəkəyə yenə sıfır bayt düşür.
enum GFlag {
	SAFE = 1,
	SPECIES_SHIFT = 1, SPECIES_MASK = 6,
	CHARGE_SHIFT = 3, CHARGE_MASK = 120,
	SUPER = 128,
}
enum SF { ID, COLOR, X, Y, DX, DY }

## Bir topun sıx axındakı ədəd sayı — [enum SF] ilə eyni.
##
## Topun id-si ardıcıl sayğacdır (peer nömrəsi deyil), ona görə mikrobdan
## fərqli olaraq `float32`-də təhlükəsiz saxlanılır.
const SHOT_STRIDE := 6


## Sıx top axınını sətirlərə açır — [method unpack_germs] ilə eyni səbəbdən.
static func unpack_shots(d: PackedFloat32Array) -> Array:
	var out := []
	var n := d.size() / SHOT_STRIDE
	for i in n:
		var b := i * SHOT_STRIDE
		out.append([d[b], d[b + 1], d[b + 2], d[b + 3], d[b + 4], d[b + 5]])
	return out
enum EF { KIND, X, Y, ARG, COLOR }

## Bir hadisənin sıx axındakı ədəd sayı — [enum EF] ilə eyni.
const EVENT_STRIDE := 5


## Sıx hadisə axınını sətirlərə açır — [method unpack_germs] ilə eyni səbəbdən.
##
## Hadisələr Dictionary kimi getsəydi (və gedirdi), 12 hadisə 584 bayt tutardı;
## sıx axında isə 248. Toplu partlama anında snapshot məhz bu sahədən şişirdi.
static func unpack_events(d: PackedFloat32Array) -> Array:
	var out := []
	var n := d.size() / EVENT_STRIDE
	for i in n:
		var b := i * EVENT_STRIDE
		out.append([d[b], d[b + 1], d[b + 2], d[b + 3], d[b + 4]])
	return out
## Liderlər cədvəlinin bir sətri.
## Liderlər cədvəlinin sətri ([method Sim.leaderboard]).
##
## `ID` var, çünki şəbəkəyə AD yox, id gedir — adlar reyestrdədir
## (bax [method Net.on_roster]). Ad yalnız serverin öz loglarında lazımdır.
enum LF { ID, NAME, POPS, CAP }

## Qida snapshot-un ən ağır hissəsidir (ekranda 50-dən çox ola bilər), ona görə
## massiv-içində-massiv YOX, düz [PackedFloat32Array] göndərilir: hər qida üçün
## üç ədəd. Variant massivində hər ədəd 9 bayt tutur, burada 4 —
## 30 Hz-də bu, saniyədə onlarla kilobayt fərq deməkdir.
const FOOD_STRIDE := 3
enum FF { ID, X, Y }


## Qabın hazırkı işlək radiusu — YAŞ RADİUS.
##
## YALNIZ rejimdən və matç saatından çıxır: mövqedən, təsadüfdən və oyun
## vəziyyətindən asılı deyil. Bu, prediction şərtidir — client öz mikrobunu
## özü hesablayır və qabın kənarı iki tərəfdə eyni olmalıdır, yoxsa mikrob
## hər snapshot-da geri sıçrayar. Eyni səbəbdən axın sahəsi də yalnız
## mövqedən asılıdır (bax [method current_at]).
static func dish_radius(mode: int, t: float) -> float:
	if mode != Mode.SOLO:
		return WORLD_RADIUS
	if t <= DRY_DELAY:
		return WORLD_RADIUS
	var k := clampf((t - DRY_DELAY) / DRY_TIME, 0.0, 1.0)
	var r := lerpf(WORLD_RADIUS, SOLO_END_RADIUS, smoothstep(0.0, 1.0, k))
	if k < 1.0:
		return r

	# SON SIXILMA — əsas quruma bitəndən matçın sonuna qədər.
	#
	# Yavaşdır və gözə az dəyir, amma məhz bu, matçın vaxt limiti ilə deyil,
	# döyüşlə bitməsini təmin edir (bax [constant SOLO_MIN_RADIUS]).
	var rest := maxf(MATCH_MAX - DRY_DELAY - DRY_TIME, 1.0)
	var k2 := clampf((t - DRY_DELAY - DRY_TIME) / rest, 0.0, 1.0)
	return lerpf(SOLO_END_RADIUS, SOLO_MIN_RADIUS, k2)


## Quru zonada bir topun yığılma müddəti. Kənardan nə qədər uzaqsa, o qədər tez.
static func dry_period(depth: float) -> float:
	return DRY_GAIN_PERIOD / (1.0 + maxf(depth, 0.0) / DRY_RAMP)


## Kameranın göstərdiyi dünya sahəsi — ekranın qısa kənarı boyunca.
static func view_span(capacity: int) -> float:
	return VIEW_SPAN_BASE + (germ_radius(capacity) - BASE_RADIUS) * VIEW_SPAN_PER_RADIUS


## Oyunçuya göndərilən sahənin radiusu (area of interest).
static func aoi_radius(capacity: int) -> float:
	return view_span(capacity) * AOI_FACTOR


## Tutuma görə mikrobun radiusu. Membran tutumu göstərir, içindəki toplar
## isə mövcud sayı — ona görə radius top sayından ASILI DEYİL.
static func germ_radius(capacity: int) -> float:
	return BASE_RADIUS + float(capacity - START_CAPACITY) * RADIUS_PER_CAPACITY


## Verilmiş nöqtədə mayenin axın sürəti (piksel/saniyə).
##
## İki qat üst-üstə düşür:
##   1. BURULĞANLAR — `ψ = A·sin(kx)·sin(ky)` axın funksiyasının qradiyenti.
##      Sahə bu formada qurulur ki, DİVERGENSİYASI SIFIR olsun: maye heç bir
##      nöqtədə yığılmır və heç bir nöqtədən yox olmur. Praktik nəticəsi budur —
##      sərbəst qida burulğanın mərkəzinə toplanıb ora ilişmir, dövr edir.
##   2. FIRLANMA — qabın ümumi hərəkəti. Mərkəzdə və şüşədə sıfır, aralıqda ən güclü.
##
## Vaxt parametri YOXDUR: sahə sabitdir. Client və server ayrı tick sayğacları
## saxlayır, ona görə vaxtdan asılı axın proqnozu pozardı (bax [constant CURRENT_STRENGTH]).
static func current_at(pos: Vector2) -> Vector2:
	var d := pos.length()
	var q := d / WORLD_RADIUS

	# Şüşəyə yaxın yapışma qatı. `u` zolağın içindəki mövqedir: 1 = sərbəst maye,
	# 0 = şüşənin dibi. Yumşaq keçid (`smoothstep`) seçilib ki, kənarda
	# sürətdə pillə olmasın.
	var u := clampf((1.0 - q) / (1.0 - CURRENT_EDGE), 0.0, 1.0)
	if u <= 0.0:
		return Vector2.ZERO
	var fade := u * u * (3.0 - 2.0 * u)

	var k := TAU / CURRENT_SCALE
	var sx := sin(pos.x * k)
	var cx := cos(pos.x * k)
	var sy := sin(pos.y * k)
	var cy := cos(pos.y * k)

	# Burulğanlar sönmənin İÇİNƏ salınır, üstünə vurulmur.
	# Fərq incə, amma həlledicidir: hazır sürəti bir əmsala vursaq, divergensiya
	# sıfır olmaqdan çıxır və qida sönmə zolağında yığılıb ilişər. Ona görə
	# əmsal axın funksiyasına (ψ = fade · A·sin(kx)·sin(ky)) tətbiq olunur və
	# sürət ONUN qradiyentindən alınır — nəticədə sərhəd zolağında maye
	# sıxılmır, şüşə boyunca yan keçidə dönür.
	var flow := Vector2(sx * cy, -cx * sy) * (CURRENT_STRENGTH * fade)

	if d > 1.0:
		var n := pos / d
		# ψ-nin radial törəməsindən gələn hədd — sərhəd boyu qayıdan axın.
		var d_fade := 6.0 * u * (1.0 - u) / ((CURRENT_EDGE - 1.0) * WORLD_RADIUS)
		flow += Vector2(n.y, -n.x) * (d_fade * (CURRENT_STRENGTH / k) * sx * sy)

		# Qabın ümumi fırlanması. Yalnız radiusdan asılı olduğuna görə
		# divergensiyası onsuz da sıfırdır — sönməyə birbaşa vurulur.
		flow += Vector2(-n.y, n.x) * (CURRENT_SWIRL * sin(PI * q) * fade)

	return flow


## Tutuma görə sürət. Böyük mikrob ağırdır — böyümənin qiyməti budur.
static func germ_speed(capacity: int) -> float:
	return BASE_SPEED * pow(float(START_CAPACITY) / float(maxi(capacity, 1)), 0.28)


## Bir topun metabolizmdə yanma müddəti (saniyə).
static func drain_period(capacity: int) -> float:
	return maxf(DRAIN_MIN_PERIOD,
		DRAIN_PERIOD - DRAIN_PER_CAPACITY * float(capacity - START_CAPACITY))


## Tutumdan səviyyə: 10 → 1, 15 → 2, 20 → 3 ...
static func level_of(capacity: int) -> int:
	return 1 + (capacity - START_CAPACITY) / CAPACITY_STEP
