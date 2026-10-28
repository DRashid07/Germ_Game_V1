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

## Görüş sahəsinin ETALON nisbəti — 16:9.
##
## Oyunçunun gördüyü dünya SAHƏSİ bütün ekranlarda eynidir və bu nisbətdən
## çıxır: 620 × (620 × 16/9). Geniş ekran daha enli, amma daha alçaq görür.
##
## Səbəb rəqabətdir. Miqyas yalnız qısa kənardan çıxsaydı (əvvəl belə idi),
## ekranın forması üstünlük verərdi — ölçülüb:
##
##   4:3    513k sahə   (−25%)
##   16:9   683k        (etalon)
##   20:9   854k        (+25%)
##   21:9   897k        (+31%)
##
## Yəni ən yaxşı və ən pis telefon arasında 56 faiz fərq vardı. Mobil
## rəqabət oyunları (Brawl Stars və bənzərləri) məhz bunu bağlayır: ekran
## nə qədər geniş olsa da, oyunçu eyni qədər məlumat görür.
const VIEW_ASPECT_REF := 16.0 / 9.0
## Client-ə göndərilən sahə ekrandan bir qədər genişdir ki, obyektlər
## kənarda "peyda olmasın".
##
## Bərabər sahə qaydası ([constant VIEW_ASPECT_REF]) bu ədədin işini
## asanlaşdırır: ekran nə qədər geniş olsa da, sahə sabit qaldığı üçün kadrın
## küncü sonsuz uzaqlaşmır. Ən pis hal 21:9-dur və orada künc `1.11 × span`
## məsafədədir, yəni 1.35 rahat örtür (əvvəl, sahə hədsiz böyüyəndə, ehtiyat
## cəmi 6% idi). `_test_aoi_covers_screen` bunu qoruyur.
const AOI_FACTOR := 1.35

# ---------- Şəbəkə ----------
const TICK_RATE := 30
const TICK_DELTA := 1.0 / float(TICK_RATE)
const INTERP_DELAY := 0.1       ## Rəqiblər 100 ms geridə interpolate olunur
## Server topu ən çox bu qədər saniyə KEÇMİŞƏ sararaq yoxlayır (bax [member Sim.lag_comp]).
##
## Atıcının ekranı serverdən `RTT + interpolyasiya (100 ms) + tick gözləməsi
## (0–33 ms) + jitter` qədər geridədir. Ölçülüb: RTT 120 ms-də 267–283 ms, RTT
## 180 ms-də 300–367 ms. Əvvəlki 300 ms həddi RTT 180-də topların 84%-ni kəsirdi:
## server qurbanı atıcının gördüyündən 1–2 tick SONRAKI yerində yoxlayırdı və
## kənara yaxın dəymələr boşa çıxırdı. 400 ms RTT ~230 ms-ə qədər örtür (mobil
## şəbəkənin adi halı); daha böyük pinqdə atıcı qabağa nişan almalıdır — yoxsa
## pis bağlantı qurbanı divar arxasında vurmağa icazə verərdi. Tarixçə
## ([constant Sim.HISTORY], 16 tick = 533 ms) buna yetir.
const REWIND_MAX := 0.40
const DEFAULT_PORT := 27015
## Telefon və masaüstü build-lərinin ilkin server ünvanı (Render, bax `deploy/render/`).
## `wss://` olduğuna görə client avtomatik WebSocket nəqliyyatını seçir.
## Brauzer versiyası bunu İŞLƏTMİR — bax [method default_server].
const DEFAULT_SERVER := "wss://germ-arena.onrender.com/ws"
## Əvvəlki buraxılışların ilkin ünvanları. Oyunçunun `settings.cfg`-sində bunlardan
## biri qalıbsa, o, ünvanı özü yazmayıb — yeni ilkin ünvana keçirilir (bax [Settings]).
const OLD_DEFAULT_SERVERS := ["wss://germ-arena-production.up.railway.app"]
const MAX_CLIENTS := 256
## Client-də reconciliation üçün saxlanan input sayı. 64 (2.1 s) Wi-Fi donmasından qısa idi:
## yuxarı istiqamət 3–4 s ilişəndə ən köhnə girişlər atılırdı və donmadan sonra barışıq
## yarımçıq qalırdı. 160 = 5.3 s; barışıq kadrda bir dəfə işləyir (bax [method Arena._drain_inbox]).
const INPUT_BUFFER_MAX := 160

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
## 3 saniyəyə keçir. Sürətli hərəkət bu oyuna uyğun deyil: avtomatik nişan
## rəqibin getdiyi yeri qabaqlamır ([AutoAim]), dəqiq nişan isə vaxt istəyir —
## dəymə bacarığı MÖVQE tutmaqdan və nişandan asılıdır.
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

## ── Yeni oyunçunun qoruması ────────────────────────────────────────────────
## Ölçülüb (2026-10-21, 160 simulyasiya oyunu, real botlarla): yeni oyunçunun sadə
## davranışları — yalnız yemək, durmadan atmaq, yalnız doluya atmaq — median
## 16–24 saniyə yaşayırdı, ilk zərbəni qalxan bitən kimi (5–9 s) alırdı və 160
## oyunun HEÇ BİRİNDƏ kimisə partlatmadı. 5/10 ilə doğulan mikrobu üç zərbə
## partladır, botlar isə ən yaxındakına atır. Yəni oyunçu qaydanı anlamağa
## macal tapmadan ölürdü.
##
## Ona görə ilk [constant NEWBIE_MATCHES] matçda oyunçu "yeni" sayılır: client
## bunu girişin bayraq bitində deyir ([member Sim.PlayerInput.newbie]), server
## mikroba [member Sim.GermState.newbie] yazır. Qayda botlara və qalxana aiddir —
## top, tutum, zərbə riyaziyyatı HƏR KƏS üçün eynidir.
const NEWBIE_MATCHES := 10
## Yeninin doğuş qalxanı. Adi qalxandan iki dəfə uzundur və atəşlə SÖNMÜR:
## yeni oyunçu ilk refleksi ilə atəş açır və adi qalxan elə o an itirdi.
## Matçlı rejimdə geri sayımdan sonra, ilk qəbul olunan girişlə başlayır —
## adi qalxan sayım boyu əriyir (3 saniyəsi oyundan əvvəl gedir).
const NEWBIE_SAFE_TIME := 8.0
## Botlar yeni mikrobu doğuşundan bu qədər saniyə HƏDƏF SEÇMİR (qalxan bitəndən
## sonra da). Başqasına atılan top ona təsadüfən dəyə bilər — bu, qorumadır, toxunulmazlıq yox.
const NEWBIE_GRACE := 20.0
## Bot yeni mikroba nişan alanda bacarığı bundan yuxarı olmur (adi bot 0.7–1.3)
## və onun getdiyi yeri QABAQLAMIR — indiki yerinə atır, oyunçunun avtomatik
## nişanı kimi (bax [AutoAim]). Hərəkət edən yeni oyunçu topdan çəkilə bilir.
const NEWBIE_BOT_SKILL := 0.5

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
## Topun radiusu, sürəti və ömrü — amöbün MİNİQANININ topudur ([constant Shot.MINIGUN]).
## Adi atəşin topları növdən asılıdır ([constant SHOT_PROFILE_SPEED]); bu üç ədəd həm də
## görmə xətti, nişan zolağı və toqquşma ellipsinin İSTİNAD ölçüsüdür.
const SHOT_RADIUS := 9.0
const SHOT_LIFETIME := 2.2       ## × sürət ≈ 920 px məsafə (ekran eninin 1.5 misli)
const SHOT_BOUNCES := 2         ## Divardan/maneədən neçə dəfə sıçraya bilər
const SHOT_RECOIL := 90.0       ## Top atanda mikrobun geri təpməsi (sürətə nisbətdə hiss olunur)

# ---------- Adi atəşin profilləri ----------
## Üç növün adi atəşi məsafə, nişan və maneə baxımından fərqlənir, İQTİSADİYYAT isə eynidir:
## bir atəş hərəkəti atıcıdan BİR top götürür, hərəkətin bütün mərmiləri birlikdə
## mikroblara ən çoxu [constant SHOT_PAYLOAD] top verir (bax [method Sim._fire]).
##
##   • KİRPİKLİ — tək, sürətli, dəqiq ox: uzaqdan vurur, divardan sıçrayır.
##   • AYAQLI — eyni anda ±7° iki iynə, hərəsi +1: yaxında ikisi də çatır, uzaqda biri.
##   • AMÖB — qövslə uçan damcı: maneənin üstündən keçir, düşdüyü yerdə tək rəqibə +2.
##   • MİNİQAN — amöbün superi; əvvəlki düz top, öz profili var ki, super təsadüfən
##     damcı və ya iynə atmasın.
##
## İndeks profil nömrəsidir; snapshot-da topun sətrində gedir ([enum SF] `META`).
enum Shot { DART = 0, NEEDLE = 1, LOB = 2, MINIGUN = 3 }
## İynələrin nişan oxundan sapması (radian, 7°) və sayı.
const NEEDLE_SPREAD := 0.12217305
const NEEDLE_COUNT := 2
## DAMCI: atəş məsafəsi, uçuş müddəti və düşmə sahəsinin radiusu.
const LOB_MIN := 180.0
const LOB_MAX := 460.0
const LOB_FLIGHT := 0.85
const LOB_AREA := 36.0
## Hədəfsiz avtomatik atəşin damcı məsafəsi — həmişə eyni, oyunçu onu öyrənə bilsin.
const LOB_AUTO := 320.0
## Düşmə nöqtəsi qabın şüşəsindən ən azı bu qədər içəridə olmalıdır.
const LOB_EDGE := 12.0
const SHOT_PROFILE_SPEED: Array[float] = [560.0, 390.0, 0.0, SHOT_SPEED]
const SHOT_PROFILE_RADIUS: Array[float] = [6.0, 6.0, 9.0, SHOT_RADIUS]
## Ömür (s). Damcıda bu, uçuşun özüdür: məsafədən asılı olmayaraq [constant LOB_FLIGHT].
const SHOT_PROFILE_LIFE: Array[float] = [1.6, 0.9, LOB_FLIGHT, SHOT_LIFETIME]
## Bir mərminin mikroba verdiyi top. İynə +1-dir: bir hərəkət iki iynədir, cəmi +2.
const SHOT_PROFILE_PAYLOAD: Array[int] = [2, 1, 2, SHOT_PAYLOAD]


## Növün adi atəşinin profili; [param minigun] — amöbün superi işləyir.
static func shot_profile(species: int, minigun := false) -> int:
	if minigun:
		return Shot.MINIGUN
	match species:
		int(Species.HELIOZOAN): return Shot.NEEDLE
		int(Species.AMOEBA): return Shot.LOB
		_: return Shot.DART


## Profil nömrəsi etibarlı aralığa salınır — dəyər şəbəkədən gəlir.
static func profile_from(value: int) -> int:
	return clampi(value, 0, SHOT_PROFILE_SPEED.size() - 1)


## Bir növün düz atəşinin çatdığı məsafə (sıçrayışsız) — nişan xətti və botlar üçün.
static func shot_reach(profile: int) -> float:
	var p := profile_from(profile)
	if p == Shot.LOB:
		return LOB_MAX
	return SHOT_PROFILE_SPEED[p] * SHOT_PROFILE_LIFE[p]

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
## Səkkiz `float32` ([constant SHOT_STRIDE]). Əvvəl yeddi idi (28): profil sahəsi əlavə
## olunanda 10 mikrobluq ən pis paketdə toplara düşən pay 10 topdan 8-ə endi
## ([method World.snapshot_for]); təhlükəli olanlar (sənə düşən damcı) önə keçir.
const SHOT_BYTES := 32
const EVENT_BYTES := 20
const FOOD_BYTES := 12

## Dəyişməyən sahələr + massiv başlıqları + ehtiyat. Koloniyaların sətri (dörd × 2 bayt
## + başlıq = 16 bayt) daxildir.
const SNAP_FIXED := 346
## Obyekt rejiminin matç sətrinə əlavəsi (`MF.OBJ` ≤ 7 float + `MF.RESPAWN`) və ehtiyat.
const SNAP_OBJ := 48
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
	DUO = 2,       ## CÜT — 5 komanda × 2, TƏK QALAN-ın qabı, dirilmə var.
	TRIO = 3,      ## ÜÇLÜK — 3v3, dar qab, üç raundun ikisini udan qalib.
	## ANA HÜCEYRƏ — 3v3, rəqibin Anasını toplarla doldurub partlat (design/MODES.md §16.2).
	MOTHER = 4,
	## YAŞ ADA — 3v3, qab quruyur, gəzən adanı tutan xal qazanır (§16.3).
	ISLAND = 5,
	## NÜVƏ TOPU — 2v2, ağır Nüvəni rəqibin məsaməsinə sal (§16.4).
	BALL = 6,
}


## Rejim komandalıdırmı?
##
## Bir yerdə cavab verilir, çünki sual koda ONLARLA yerdə düşür: dost atəşi,
## rəng, yer paylanması, bot doldurma. Hər yerdə `mode == DUO or mode == TRIO`
## yazsaydıq, beşinci rejim gələndə biri mütləq unudulardı.
static func is_team_mode(mode: int) -> bool:
	return mode == Mode.DUO or mode == Mode.TRIO or is_objective_mode(mode)


## OBYEKT rejimi: iki komanda, ölən dirilir, matçı obyekt həll edir (Ana, ada, Nüvə).
##
## Sona qalan komanda burada qalib DEYİL — hamı dirilir, ona görə "komanda qırıldı"
## şərti heç vaxt işləmir və matçı yalnız obyekt və vaxt bitirir.
static func is_objective_mode(mode: int) -> bool:
	return mode == Mode.MOTHER or mode == Mode.ISLAND or mode == Mode.BALL


## Rejimdə bir komandada neçə mikrob var (komandasızda 1).
static func team_size(mode: int) -> int:
	match mode:
		Mode.DUO, Mode.BALL: return 2
		Mode.TRIO, Mode.MOTHER, Mode.ISLAND: return 3
		_: return 1


## Rejimdə dünyanın tam əhalisi.
static func mode_capacity(mode: int) -> int:
	match mode:
		Mode.TRIO, Mode.MOTHER, Mode.ISLAND: return TRIO_GERMS
		Mode.BALL: return 4
		_: return WORLD_CAPACITY


## Qabın ŞÜŞƏSİ — mikrobu, topu və qidanı saxlayan divarın radiusu.
##
## Köhnə rejimlərin hamısı 1200-lük qabdadır (ÜÇLÜK də — onun dar sahəsi QURU zona ilə
## çəkilir). Obyekt rejimləri isə öz qabında oynanır: 4–6 mikrob 1200-lük qabda bir-birini
## axtarardı, NÜVƏ TOPU-nun qapısı isə məhz şüşənin üstündədir (bax design/MODES.md §16.1).
static func wall_radius(mode: int) -> float:
	match mode:
		Mode.MOTHER: return MOTHER_WALL
		Mode.ISLAND: return ISLAND_WALL
		Mode.BALL: return BALL_WALL
		_: return WORLD_RADIUS


## Obyekt rejimlərinin öz xəritə düzümləri ([method DishMap.obstacles_for]).
## Nömrələr [member DishMap.layout]-un ümumi düzümlərindən (0–2) sonra gəlir.
const LAYOUT_MOTHER := 3
const LAYOUT_ISLAND := 4
const LAYOUT_BALL := 5


## Rejimin xəritə düzümü. -1 = ümumi düzüm ([member DishMap.layout]) — köhnə
## rejimlər onu bölüşür.
static func mode_layout(mode: int) -> int:
	match mode:
		Mode.MOTHER: return LAYOUT_MOTHER
		Mode.ISLAND: return LAYOUT_ISLAND
		Mode.BALL: return LAYOUT_BALL
		_: return -1


## Komandanın bazası — doğuşun mərkəzi. Komanda 0 qərbdə, 1 şərqdədir.
static func team_base(mode: int, team: int) -> Vector2:
	var side := -1.0 if team == 0 else 1.0
	match mode:
		Mode.MOTHER: return Vector2(side * 545.0, 0.0)
		Mode.ISLAND: return Vector2(side * 610.0, 0.0)
		Mode.BALL: return Vector2(side * 430.0, 0.0)
		_: return Vector2.ZERO


## Ölən mikrob bu qədər saniyə sonra öz bazasında doğulur (obyekt rejimləri).
static func respawn_time(mode: int) -> float:
	return BALL_RESPAWN if mode == Mode.BALL else OBJ_RESPAWN

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

## ÜÇLÜK dar qabda oynanır: altı mikrob, qısa raund, dərhal təmas.
## Böyük qabda üç nəfər bir-birini axtarmaqla vaxtı yeyərdi.
const TRIO_GERMS := 6
const TRIO_RADIUS := 700.0
const TRIO_END_RADIUS := 220.0
const TRIO_DRY_DELAY := 40.0
const TRIO_DRY_TIME := 45.0
const TRIO_ROUND := 60.0        ## Bir raundun uzunluğu
const TRIO_ROUNDS_WIN := 2      ## Neçə raund udan matçı udur
const ROUND_BREAK := 3.0        ## Raund arası hesab ekranı

## CÜT-də ölən yoldaş bu qədər saniyə sonra qayıdır (yoldaşı sağdırsa).
##
## Tutum və super doluluğu SIFIRLANIR: dirilmə ikinci şans olmalıdır,
## cəzasız davam deyil — yoxsa cüt qəsdən ölüb yenidən doğula bilər.
const REVIVE_TIME := 15.0

# ---------- Obyekt rejimləri (design/MODES.md §16) ----------
## Ölən mikrob bu qədər saniyə sonra öz bazasında doğulur. Tutum 10-a qayıdır —
## ölüm yenə cəzadır, sadəcə matçdan çıxarmır.
const OBJ_RESPAWN := 5.0
const BALL_RESPAWN := 4.0

## ANA HÜCEYRƏ. Ana hərəkətsiz maneədir ([constant DishMap.Kind.MOTHER]): rəqibin
## topu ona adi zərbə kimi +2 verir, tutumu keçəndə partlayır və matç bitir.
const MOTHER_WALL := 800.0
const MOTHER_CAP := 140
const MOTHER_START := 70
## Anaya dəyən top onu bu qədər doldurur. Mikroba dəyən top +2-dir, Anaya isə +1: +2 ilə
## botlu matçların üçdə biri 60 s-dən tez bitirdi — partlatmalarla böyüyən bir hücumçu
## yuvanın ağzında dirilənləri vurur, yoldaşları isə Ananı 35 s-də doldururdu.
const MOTHER_FEED := 1
const MOTHER_RADIUS := 100.0
## Ananın mərkəzi bazanın şüşəyə yaxın tərəfindədir: arxasında 50 px qalır —
## yalnız amöbün sığdığı arxa qapı (bax [method DishMap._build_mother]).
const MOTHER_X := 650.0
## Öz Anana toxunanda hər bu qədər saniyədə bir top Anadan sənə keçir.
const MOTHER_SUCK := 0.4
## Ana [constant MOTHER_HOT]-u keçibsə əmmə iki qat tezdir — geridə qalanın şansı.
const MOTHER_SUCK_FAST := 0.2
const MOTHER_HOT := 0.80
## Ana bundan boşdursa əmmək olmur — yuvada oturub Ananı sıfıra endirmək olmasın.
const MOTHER_SUCK_MIN := 0.30
## Toxunma: iki gövdənin cəmindən bu qədər piksel uzaqlığa qədər.
const MOTHER_REACH := 12.0
const MOTHER_TIME := 150.0
const MOTHER_OT := 30.0
## Vaxt bitəndə Analar bundan az fərqlənirsə əlavə vaxt oynanır.
const MOTHER_TIE := 6
## Əlavə vaxtda hər Ana saniyədə bu qədər top dolur, əmmək dayanır.
const MOTHER_OT_FILL := 1.0

## YAŞ ADA. Qab [constant ISLAND_START]-da quruyur, yalnız gəzən ada yaş qalır.
const ISLAND_WALL := 720.0
const ISLAND_START := 20.0
const ISLAND_SHRINK := 5.0
const ISLAND_RADIUS := 220.0
## Adanın yolu — orta xətt boyunca şimal–cənub, mərkəzdən bu qədər uzağa gedir.
const ISLAND_A := 340.0
const ISLAND_PERIOD := 64.0
## Quru zona bu rejimdə CƏBBƏXANADIR: dərinlikdən asılı olmayan sabit dövr və doğuş
## qalxanında yığılmır. Qanunun dərinlik pilləsi burada doğulan kimi öldürərdi —
## baza adadan 400-600 px aralıdır.
const ISLAND_DRY_PERIOD := 2.0
const ISLAND_WIN := 70
const ISLAND_TIME := 180.0
## Xal fərqi bundan çoxdursa adadakı bərabərlik geridə qalana yazılır.
const ISLAND_CATCHUP := 25

## NÜVƏ TOPU. Nüvə neytral ağır kürədir; qapı (məsamə) şüşənin üstündədir.
const BALL_WALL := 640.0
## Qapının yarım eni (şüşə boyunca piksel). Komanda 0-ın qapısı qərbdə, 1-inki şərqdə.
const BALL_GOAL_HALF := 118.0
const BALL_WEIGHT := 20
const BALL_WEIGHT_MAX := 40
const BALL_R0 := 30.0
const BALL_R_PER_W := 0.8
## Suyun müqaviməti (1/s): Nüvə ~3 saniyə sürüşür.
const BALL_DRAG := 0.8
## Şüşədən, maneədən və mikrobdan sıçrayanda sürətin qalan payı. Mikrobdan sıçrayış da
## elastik deyil — elastik olanda iki mikrobun arasında Nüvə sürət yığırdı ([method Sim._step_ball]).
const BALL_BOUNCE := 0.6
## Topla vurmaq: `BALL_SHOT_PUSH × BALL_WEIGHT / çəki` px/s.
const BALL_SHOT_PUSH := 200.0
## Çəki hər bu qədər saniyədə 1 azalır, [constant BALL_WEIGHT]-ə qədər.
const BALL_DECAY := 1.5
## Gövdə təkanı: mikrobun normal sürətinin bu qədər misli Nüvəyə keçir.
const BALL_KICK := 2.0
## Partlayan Nüvə bu qədər saniyə sonra mərkəzdə yenidən doğulur.
const BALL_REBORN := 2.0
## Suyun axını ağır Nüvəni bu qədər aparır (mikrobu 1.0). Tam axında Nüvə burulğanla
## şüşəyə sıxılıb orada qalırdı — ölçülüb, matçın yarısını cənub şüşəsinin yanında keçirirdi.
const BALL_FLOW := 0.35
## Şüşənin menisküsü: kənardan bu qədər piksel yaxın Nüvə içəri yuvarlanır (px/s²).
## Onsuz şüşəyə sıxılmış Nüvənin arxasına keçmək olmurdu — mikrob şüşə ilə Nüvə
## arasına sığmır və Nüvə orada əbədi ilişirdi.
const BALL_EDGE := 40.0
const BALL_EDGE_PUSH := 90.0
const BALL_GOALS := 2
const BALL_TIME := 150.0
## 2:30-da hesab bərabərdirsə ilk qol udur — ən çox bu qədər saniyə, sonra heç-heçə.
const BALL_OT := 45.0

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


# ---------- Qida koloniyaları (yalnız SONSUZ ARENA, design/MODES.md §18) ----------
## Neytral qida mənbəyi: ətrafına adi +1 qida çıxarır, ehtiyatı tükənir və bərpa olunur.
## Tutmaq xal vermir, komanda sahibliyi və qoruma yaratmır. Seçim üçündür: mərkəzə yaxın
## BOL mənbə (döyüş orada olur), kənarda ZƏİF mənbə və səpələnmiş qida. Rəqəmlər prototipdir.
enum ColonyKind { RICH = 0, POOR = 1 }
## Koloniyaların növü və sırası: iki bol, iki zəif (bax [method DishMap.colony_spots]).
const COLONY_KINDS := [ColonyKind.RICH, ColonyKind.RICH, ColonyKind.POOR, ColonyKind.POOR]
## Mərkəzdən məsafə (px), növə görə: x — ən az, y — ən çox.
const COLONY_DIST := [Vector2(350.0, 500.0), Vector2(750.0, 900.0)]
const COLONY_STOCK := [20, 12]           ## ehtiyat
const COLONY_PERIOD := [0.45, 0.8]       ## istehsal dövrü (s)
const COLONY_REGEN := [24.0, 30.0]       ## tükənəndən sonra bərpa (s)
## Bir koloniyanın dünyadakı udulmamış qidası ən çox bu qədər olur. Qida MƏNŞƏYƏ görə
## sayılır, yerinə görə yox: axın onu uzağa aparsa da sayılır — yoxsa koloniya yaxın
## radiusu boşaldıb sonsuz istehsal edərdi.
const COLONY_OUT_MAX := 8
## Koloniyanın gövdəsi (görüntü).
const COLONY_RADIUS := [30.0, 24.0]
## Qida mərkəzdən bu qədər uzağa qədər çıxır.
const COLONY_SPREAD := 56.0
## Koloniyanın sahəsi istənilən maneədən bu qədər aralıdır: qida halqası, tumurcuğun
## sürüşməsi və bir qida radiusu. Koloniya bərk deyil — heç bir dəhlizi bağlamır.
const COLONY_CLEAR := 90.0
## İki koloniyanın mərkəzləri arasında ən az məsafə — qida sahələri birləşməsin.
const COLONY_GAP := 420.0
## Çıxan qida mərkəzdən kənara bu sürətlə itələnir (px/s) — "tumurcuqlanma".
const COLONY_BUD_SPEED := 30.0
## Snapshot-da bərpa sayğacının vahidi (s) — bir bayta 63 saniyəyə qədər sığır.
const COLONY_REGEN_STEP := 0.25
## SONSUZ ARENA-da səpələnmiş (ekoloji) qidanın canlı hədəfi — koloniyalardan AYRI.
## Bu, ümumi hədəfin içində bilərəkdən qorunan MİNİMUMDUR: ölüm səpintisi və boşa çıxan
## top onun əvəzi sayılmır. Sərt maksimum deyil (bax [method Sim._spawn_ecology]).
const SCATTER_TARGET := 32
## Qidanın mənşəyi ([member Sim.FoodState.origin]) — yalnız serverdə, şəbəkəyə getmir.
## 0 və yuxarı — koloniyanın indeksi.
const ORIGIN_LOOSE := -1     ## ölüm səpintisi, boşa çıxan top, Nüvənin qidası
const ORIGIN_SCATTER := -2   ## səpələnmiş ekoloji qida


# ---------- Növ özəllikləri ----------
## Hər növün MÜHİTLƏ münasibəti başqadır — güc fərqi yox, münasibət fərqi.
##
## Biri suda üzür: su onu həm daşıyır, həm aparır. Biri dibdə yeriyir: pəncələri
## yapışır, axın onu tərpədə bilmir. Biri sürünür: divarlar onu saxlamır.
## Üç orqanizmin əsl ekologiyası da elə budur (planktonik, bentik, substrat).
##
## QAYDA: bu əmsalların heç biri döyüş riyaziyyatına toxunmur —
## [constant FIRE_COOLDOWN], [constant CAPACITY_STEP], [constant MIN_BALLS], atəşin
## qiyməti (bir top) və hərəkətin ən çox verdiyi top ([constant SHOT_PAYLOAD]) hər üç
## növdə eynidir. Onlar dəyişsə oyun sınır (bax həmin sabitlərin öz izahına) və
## "güclü növ" yaranar. Növlər yalnız atəşin FORMASI ilə fərqlənir ([enum Shot]).
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

## AMÖB — miniqan. Amöb yerində donur, metabolizm dayanır və fasiləsiz atəş
## açır: top PULSUZDUR (öz sayından getmir). Qalxan YOXDUR — ona top adi kimi
## dəyir (bax [method Sim._step_germs]). Ad (CYST) tarixidir: əvvəl bu,
## toxunulmaz qabıq idi.
const CYST_TIME := 2.5
## Superdə iki atəş arası. Adi dövr 1 s-dir; 0.25 s bir superdə ~10 top verir.
## Daha qısa olmasın: snapshot eyni anda ən çoxu [constant SHOT_SEND_MAX] top
## daşıyır, top isə 2.2 s yaşayır — 0.15 s-də amöbün öz topları (2.2 / 0.15 ≈ 15)
## büdcənin demək olar hamısını tutardı və rəqiblərin ekranında topların bir
## qismi görünməzdi.
const MINIGUN_COOLDOWN := 0.25
## Növ snapshot-da neçə bit tutur — [enum GFlag] bunu istifadə edir.
const SPECIES_COUNT := 3


## Növün superi nə qədər DAVAM edir. Kirpiklininki anidir, ona görə sıfır.
##
## Bir yerdə cavab verilir, çünki sual İKİ tərəfdən düşür: [method Sim._use_super]
## superi işə salanda və client snapshot-dakı "super işləyir" bitindən öz
## sayğacını qurmalı olanda (bax [method Arena._reconcile]). İki yerdə yazılsaydı,
## dördüncü növ gələndə biri mütləq unudulardı və effekt öz mikrobunda yarımçıq
## qalardı.
static func super_time(species: int) -> float:
	match species:
		int(Species.HELIOZOAN): return NET_TIME
		int(Species.AMOEBA): return CYST_TIME
		_: return 0.0


## Superin işlədilməsi üçün lazım olan ƏN AZ top sayı.
##
## Yalnız kirpiklidə mənalıdır: trixosist MADDƏDİR, [constant TRICHO_COST]
## top xərcləyir və [method Sim.GermState.super_ready] oyunçunun öz superi ilə
## acından ölməsinin qarşısını alır. Qalan iki superin top qiyməti yoxdur.
static func super_min_balls(species: int) -> int:
	if species == int(Species.CILIATE):
		return TRICHO_COST + MIN_BALLS + 1
	return MIN_BALLS


## Doluluq TAMDIR, amma super yenə işləmirsə — SƏBƏBİ. İşləyirsə boş sətir.
##
## Qaydanın özü [method Sim.GermState.super_ready]-dədir, burada onun İZAHI
## durur: qaydanı simulyasiya oxuyur, izahı isə HUD, və izah şəbəkəyə çıxmır.
##
## Bu mətn olmadan kirpikli 4 topda ölü düymə ilə qalırdı: doluluq 15/15,
## halqa tam dolu, oyunçu basır və HEÇ NƏ olmur — nə effekt, nə səs, nə səbəb.
## Atəş düyməsi 4 topda hələ işlək olduğuna görə bu, tamamilə adi vəziyyətdir.
static func super_block_reason(species: int, balls: int) -> String:
	var need := super_min_balls(species)
	if balls < need:
		return "SUPER ÜÇÜN %d TOP LAZIMDIR" % need
	return ""


## Xam ədədi rejimə çevirir; tanınmayan hər şey sonsuz arenaya düşür.
##
## Növdəki [method species_from] ilə eyni səbəb: dəyər client-dən gəlir və
## etibarsız ola bilər. Çevirmə BİR yerdə olanda "yad dəyər gələndə nə olur"
## sualının bir cavabı olur.
static func mode_from(value: int) -> Mode:
	# Yuxarı bayt qaydaların versiyasıdır ([method mode_wire]).
	match value & 0xFF:
		int(Mode.SOLO): return Mode.SOLO
		int(Mode.DUO): return Mode.DUO
		int(Mode.TRIO): return Mode.TRIO
		int(Mode.MOTHER): return Mode.MOTHER
		int(Mode.ISLAND): return Mode.ISLAND
		int(Mode.BALL): return Mode.BALL
		_: return Mode.ENDLESS


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
	match mode:
		Mode.SOLO: return "TƏK QALAN"
		Mode.DUO: return "CÜT"
		Mode.TRIO: return "ÜÇLÜK"
		Mode.MOTHER: return "ANA HÜCEYRƏ"
		Mode.ISLAND: return "YAŞ ADA"
		Mode.BALL: return "NÜVƏ TOPU"
		_: return "SONSUZ ARENA"


## Qrafika keyfiyyəti.
##
## Yalnız GÖRÜNTÜYƏ təsir edir — simulyasiyaya yox. Oyun qaydaları, görüş
## sahəsi və şəbəkə hər iki səviyyədə eynidir, yəni aşağı keyfiyyət
## üstünlük də vermir, məhrumiyyət də.
enum Quality {
	HIGH = 0,   ## Glow, HDR kadr buferi, tam zərrəcik sıxlığı
	LOW = 1,    ## Glow və HDR sönülü, zərrəciklər yarıya qədər
	## Zəif telefon: sadə mikrob gövdəsi, 30 FPS, səhnə baza ölçüdə (1280×720)
	## render olunur. Oyun qaydası, görüş sahəsi və şəbəkə EYNİDİR.
	MINIMUM = 2,
}


## HIT hadisəsinin `arg`-ı mikroba dəyəndə: `1 + qurbanın rəngi + 64 × (yük − 1)`.
##
## Sıçrayış və qabıq zərbəsi `0`-dır, yəni köhnə `arg > 0.5` yoxlaması
## ("mikroba dəydimi") dəyişmir. Ayrıca sahə paketi böyüdərdi. Yük də buradadır:
## iynə +1, qalanı +2 verir və client zərbənin rəqəmini ondan yazır.
static func hit_arg(victim_color: int, payload := SHOT_PAYLOAD) -> float:
	return 1.0 + float(posmod(victim_color, 64)) + 64.0 * float(clampi(payload, 1, 8) - 1)


## HIT hadisəsinin qurbanının rəngi; sıçrayışdırsa -1 (bax [method hit_arg]).
static func hit_victim(arg: float) -> int:
	return (int(round(arg)) - 1) % 64 if arg > 0.5 else -1


## HIT hadisəsinin mikroba verdiyi top sayı; sıçrayışdırsa 0.
static func hit_payload(arg: float) -> int:
	return (int(round(arg)) - 1) / 64 + 1 if arg > 0.5 else 0


## Oyun qaydalarının versiyası — server və client EYNİ olmalıdır.
##
## 2: növlərin fərqli adi atəşi ([enum Shot]) və 8 ədədlik top sətri. Köhnə client
## yeni serverin top sətrini yanlış oxuyardı, yeni client köhnəninkini — ona görə
## uyğunsuzluq açıq idarə olunur: client versiyanı rejim ədədinin yuxarı baytında
## göndərir ([method mode_wire]), server uyğun gəlməyəni dünyaya buraxmır
## ([method Lobby.join]), client də serverin dediyini yoxlayır ([method Arena.configure_online]).
## 3: SONSUZ ARENA-nın qida koloniyaları — join info-da yerləri, snapshot-un sonunda
## vəziyyəti ([constant Snap.COLONY]). Köhnə client onları görməzdi və qida "boşluqdan"
## çıxardı, ona görə versiya artırılıb.
const RULES := 3


## Şəbəkəyə gedən rejim ədədi: aşağı bayt rejim, yuxarı bayt [constant RULES].
## Köhnə server tanımadığı ədədi SONSUZ ARENA sayır, dünyanın qaydaları isə
## join info-da gəlir — client onu yoxlayıb uyğunsuzluğu deyir.
static func mode_wire(mode: int) -> int:
	return (mode & 0xFF) | (RULES << 8)


## [method mode_wire] ədədinin qaydalar versiyası; köhnə client-də 0.
static func wire_rules(value: int) -> int:
	return value >> 8


static func quality_from(value: int) -> Quality:
	match value:
		int(Quality.LOW): return Quality.LOW
		int(Quality.MINIMUM): return Quality.MINIMUM
		_: return Quality.HIGH


static func quality_name(q: int) -> String:
	match q:
		int(Quality.LOW): return "AŞAĞI"
		int(Quality.MINIMUM): return "MİNİMUM"
		_: return "YÜKSƏK"


## Glow, HDR və ağır effektlər sönülüdürmü — AŞAĞI və MİNİMUM-da.
##
## Yoxlama BİR yerdədir: əvvəl hər yerdə `quality == LOW` yazılırdı və üçüncü
## səviyyə gələndə hər biri MİNİMUM-u səhvən YÜKSƏK sayardı.
static func is_light(q: int) -> bool:
	return q != int(Quality.HIGH)


## Cihaza görə ilkin keyfiyyət.
##
## Telefonda AŞAĞI başlayır. Səbəb glow-dur: o, tam ekranı bir neçə dəfə
## bulandıran keçiddir və `hdr_2d` ilə birlikdə kadr buferini RGBA16F-ə
## qaldırır — yəni hər kadr iki dəfə çox yaddaş zolağı yeyir. Masaüstü GPU-da
## bu ölçülə bilmir (fərq çalışmalar arasındakı səpələnmədən kiçikdir),
## mobil GPU-da isə adətən ən böyük tək xərcdir.
##
## Oyunçu istəsə menyudan YÜKSƏK-ə qaldıra bilər — qərar ondadır, sadəcə
## ilkin dəyər təhlükəsiz tərəfə əyilir.
##
## Zəif telefonda isə elə ilk açılışdan MİNİMUM (bax [method is_weak_device]).
## Bu yalnız ilk təxmindir — oyun işləyərkən kadr vaxtı ölçülür və lazım gəlsə
## səviyyə endirilir (bax [method Arena._watch_performance]).
static func default_quality() -> Quality:
	if not is_handheld():
		return Quality.HIGH
	return Quality.MINIMUM if is_weak_device() else Quality.LOW


## Zəif telefondurmu — RAM və GPU-nun adına görə İLK təxmin.
##
## Büdcə telefonlarının prosessoru bu oyunun sınandığı masaüstündən 6–7 dəfə
## yavaşdır (Geekbench 6 tək nüvə: Helio G85 ~420, Unisoc T606 ~377, masaüstü
## ~2 500), ən zəifləri (Helio A22/P35) 15 dəfə. GPU-ları Mali-G52 MC2, Adreno
## 610 və PowerVR GE8320-dir. Siyahı qəsdən qısadır: səhv "güclü" təxmin
## oyunu öldürmür — [method Arena._watch_performance] ilk saniyələrdə endirir.
static func is_weak_device() -> bool:
	if _weak < 0:
		_weak = 1 if _probe_weak() else 0
	return _weak == 1


## Cihaz sorğusu bir dəfə edilir — nəticə dəyişmir, JS və GPU sorğusu isə ucuz deyil.
static var _weak := -1


static func _probe_weak() -> bool:
	var ram_gb := _ram_gb()
	if ram_gb > 0.0 and ram_gb <= 3.0:
		return true
	var gpu := _gpu_name().to_lower()
	for weak in WEAK_GPUS:
		if gpu.contains(weak):
			return true
	return false


## GPU adında bunlardan biri varsa, telefon zəif sayılır (kiçik hərflə).
const WEAK_GPUS := ["mali-g31", "mali-g51", "mali-g52", "mali-t", "powervr",
	"ge8", "adreno (tm) 3", "adreno (tm) 4", "adreno (tm) 50", "adreno (tm) 51",
	"adreno (tm) 60", "adreno (tm) 610"]


## Cihazın RAM-ı (GB); bilinmirsə 0. Brauzerdə `navigator.deviceMemory`.
static func _ram_gb() -> float:
	if OS.has_feature("web"):
		var mem = JavaScriptBridge.eval("navigator.deviceMemory || 0")
		return float(mem) if (mem is float or mem is int) else 0.0
	var info := OS.get_memory_info()
	return float(info.get("physical", 0)) / 1073741824.0


## GPU-nun adı ölçü sətri üçün (bax [method Arena.perf_line]) — bir dəfə sorğulanır.
static func gpu_label() -> String:
	if _gpu_cached.is_empty():
		_gpu_cached = _gpu_name().strip_edges()
		if _gpu_cached.is_empty():
			_gpu_cached = "?"
	return _gpu_cached


static var _gpu_cached := ""


## GPU-nun adı. Brauzerdə Godot yalnız "WebKit WebGL" görür, ona görə həqiqi
## ad `WEBGL_debug_renderer_info` ilə səhifədən oxunur.
static func _gpu_name() -> String:
	if OS.has_feature("web"):
		var js := "(function(){try{var c=document.createElement('canvas');" \
			+ "var g=c.getContext('webgl2')||c.getContext('webgl');" \
			+ "var e=g&&g.getExtension('WEBGL_debug_renderer_info');" \
			+ "return e?String(g.getParameter(e.UNMASKED_RENDERER_WEBGL)):'';" \
			+ "}catch(x){return ''}})()"
		var name = JavaScriptBridge.eval(js)
		return String(name) if name is String else ""
	return RenderingServer.get_video_adapter_name()


## Telefonda (və ya planşetdə) işləyirikmi — tətbiq kimi də, BRAUZERDƏ də.
##
## `mobile` teqi YALNIZ Android/iOS tətbiqində var. Veb build telefonun
## brauzerində açılanda `mobile` YALANDIR — telefon orada `web_android` /
## `web_ios` kimi görünür (Godot sənədi, "Feature tags": "OS.has_feature('mobile')
## will return false when running a project exported to Web on a mobile device").
##
## Əvvəl yalnız `mobile` yoxlanırdı və Android-in brauzeri MASAÜSTÜ sayılırdı:
## oyun telefonda YÜKSƏK keyfiyyətlə (glow + RGBA16F HDR buferi) və kadr
## həddi OLMADAN açılırdı — 120 Hz ekranda saniyədə 120 dəfə. Brauzerdə donma
## və kəsilmənin əsas səbəbi elə bu idi.
static func is_handheld() -> bool:
	return OS.has_feature("mobile") or OS.has_feature("web_android") \
		or OS.has_feature("web_ios")


## Oyunun ilkin server ünvanı.
##
## Brauzer versiyası onu açan saytın ÖZÜNDƏKİ serverə qoşulur: Render-də nginx
## `/ws` yolunu eyni konteynerdəki oyun serverinə ötürür (bax `deploy/render/`).
## Beləcə build hansı domendə açılsa işləyir, və səhifə `https` olanda `ws://`
## seçilib brauzerin qarışıq məzmun qadağasına ilişmir.
static func default_server() -> String:
	if OS.has_feature("web"):
		var origin = JavaScriptBridge.eval("location.protocol + '//' + location.host")
		if origin is String and origin.begins_with("http"):
			return origin.replace("https://", "wss://").replace("http://", "ws://") + "/ws"
	return DEFAULT_SERVER


## Rejimin ƏN QISA təsviri — ana ekrandakı dar kart üçün.
##
## [method mode_note] tam qaydadır və vərəqin geniş sətrinə sığır; ana
## ekranın rejim kartı isə cəmi 300 px enindədir və uzun mətn orada kəsilir.
static func mode_brief(mode: int) -> String:
	match mode:
		Mode.SOLO: return "10 mikrob · sona qalan udur"
		Mode.DUO: return "5 cüt · dirilmə var"
		Mode.TRIO: return "3v3 · üç raund"
		Mode.MOTHER: return "3v3 · rəqibin Anasını partlat"
		Mode.ISLAND: return "3v3 · gəzən adanı tut"
		Mode.BALL: return "2v2 · Nüvəni qapıya sal"
		# Sayı [method mode_capacity]-dən çıxır: burada "6 mikrob" yazılırdı —
		# o, TRIO_GERMS-in rəqəmidir, səhvən köçürülmüşdü. Sonsuz arenanın
		# tutumu WORLD_CAPACITY-dir və REJİMLƏR vərəqi ilə ziddiyyət yaranırdı.
		_: return "%d mikrob · matç yoxdur" % WORLD_CAPACITY


## Matç başlayanda ekrana çıxan QALİBİYYƏT şərti.
##
## Rejimə görə fərqlənməlidir: "sona qalan udur" ÜÇLÜK-də sadəcə yalandır
## (orada raund hesabı həll edir), CÜT-də isə qalib tək mikrob yox, CÜTDÜR.
## Əvvəl üç rejimdə də eyni sətir yazılırdı.
static func mode_goal(mode: int) -> String:
	match mode:
		Mode.DUO: return "Sona qalan cüt udur"
		Mode.TRIO: return "Üç raundun ikisini udan qalib"
		Mode.MOTHER: return "Rəqibin Anasını doldur, öz Ananı əm"
		Mode.ISLAND: return "Adada çox ol — 100 xal udur"
		Mode.BALL: return "Nüvəni rəqibin qapısına sal — 2 qol udur"
		_: return "Sona qalan udur"


## Rejimin bir sətirlik qaydası — menyu kartında göstərilir.
static func mode_note(mode: int) -> String:
	match mode:
		Mode.SOLO: return "10 mikrob · qab quruyur · sona qalan udur"
		Mode.DUO: return "5 cüt · yoldaşın səni dirildir · sona qalan cüt udur"
		Mode.TRIO: return "3v3 · dar qab · üç raundun ikisini udan qalib"
		Mode.MOTHER: return "3v3 · rəqibin Anasını toplarla doldurub partlat, öz Ananı əm"
		Mode.ISLAND: return "3v3 · qab quruyur · gəzən adada çox olan xal qazanır"
		Mode.BALL: return "2v2 · ağır Nüvəni rəqibin məsaməsinə sal · 2 qol udur"
		_: return "matç yoxdur · girdin, oynadın · gözləmə yoxdur"


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
## COLONY — qida koloniyalarının vəziyyəti ([method Sim.colony_bytes]); koloniyasız
## rejimdə boşdur. Hər snapshot-da TAM gedir: paket itsə də növbəti onu bərpa edir.
enum Snap { TICK, GERMS, SHOTS, FOOD, EVENTS, BOARD, POP, WALLS, MATCH, SELF, COLONY }

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
	TEAM,     ## int   — baxanın komandası (-1 komandasız)
	SCORE_US, ## int   — ÜÇLÜK: baxanın komandasının udduğu raund sayı; ANA HÜCEYRƏ:
	          ##         öz Ananın top sayı; YAŞ ADA: xal; NÜVƏ TOPU: qol
	SCORE_EM, ## int   — eyni rəqəm rəqib üçün
	## Rejimin obyekti, `PackedFloat32Array`, yalnız obyekt rejimlərində. Birinci ədəd
	## həmişə MATÇIN saatıdır ([constant CLOCK] fazanınkıdır və qoldan sonrakı sayım onu
	## sıfırlayır); sonra ANA HÜCEYRƏ — `[əlavə vaxt 0/1]`, YAŞ ADA — `[x, y, r]`, NÜVƏ
	## TOPU — `[x, y, vx, vy, çəki, sağ 0/1]`. SONDA əlavə olunub: köhnə client sahəni
	## oxumur, yeni client köhnə serverdə onu sadəcə tapmır.
	OBJ,
	## float — baxanın dirilməsinə qalan saniyə (0 = sağdır və ya dirilmə yoxdur).
	RESPAWN,
}
## Köhnə serverin matç sətrinin uzunluğu — [constant MF.OBJ]-dan əvvəlki sahələr.
const MF_BASE := 9
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
	## Komanda nömrəsi — bit 8-10, yəni 0..7. SIFIR "komandasız" deməkdir,
	## komanda isə `team + 1` kimi yazılır.
	##
	## İKİ bit BƏS ETMİR: CÜT-də beş komanda var (5 × 2 = 10 mikrob), iki bit
	## isə cəmi dördünü daşıyır. design/MODES.md §4 iki bit deyirdi — səhvdir.
	TEAM_SHIFT = 8, TEAM_MASK = 1792,
}
## `REWIND` — server bu topu qurbanlarının neçə saniyə ƏVVƏLKİ yerinə qarşı
## yoxlayır (bax [member Sim.lag_comp]); botun topunda 0. `META` — profil, bir
## mərminin yükü və atəş qrupu ([method shot_meta]). `LIFE` şəbəkədə ayrıca
## getmir — [method unpack_shots] onu istiqamətdən açır.
##
## DAMCININ sətri başqa cür oxunur ([constant Shot.LOB]): `X, Y` — DÜŞMƏ nöqtəsi,
## `DX, DY` — başlanğıc (baxan atıcını görmürsə düşmə nöqtəsinin özü, yəni yol
## yoxdur), `REWIND` — düşməyə qalan saniyə; `COLOR` atıcı görünmürsə -1-dir.
## Xəbərdarlıq beləcə gizlənən atıcının yerini və kimliyini açmır (bax
## [method World._lob_row]).
enum SF { ID, COLOR, X, Y, DX, DY, REWIND, META, LIFE }

## Bir topun sıx axındakı ədəd sayı — [enum SF]-dən `LIFE`-sız.
##
## Topun id-si ardıcıl sayğacdır (peer nömrəsi deyil), ona görə mikrobdan
## fərqli olaraq `float32`-də təhlükəsiz saxlanılır. `META` də tam ədəddir və
## 2^24-dən kiçikdir (qrup 2^16-ya bölünür).
const SHOT_STRIDE := 8


## `META`: `profil + 4 × yük + 64 × (qrup mod 65536)`.
static func shot_meta(profile: int, payload: int, volley: int) -> float:
	return float(profile_from(profile) + 4 * clampi(payload, 0, 15) + 64 * posmod(volley, 65536))


static func meta_profile(meta: float) -> int:
	return profile_from(int(meta) & 3)


static func meta_payload(meta: float) -> int:
	return (int(meta) >> 2) & 15


static func meta_volley(meta: float) -> int:
	return int(meta) >> 6


## Sıx top axınını sətirlərə açır — [method unpack_germs] ilə eyni səbəbdən.
static func unpack_shots(d: PackedFloat32Array) -> Array:
	var out := []
	var n := d.size() / SHOT_STRIDE
	for i in n:
		var b := i * SHOT_STRIDE
		if meta_profile(d[b + 7]) == Shot.LOB:
			# Damcı: başlanğıc vektor deyil, nöqtədir; ömür düşməyə qalan vaxtdır.
			out.append([d[b], d[b + 1], d[b + 2], d[b + 3], d[b + 4], d[b + 5], d[b + 6],
				d[b + 7], maxf(d[b + 6], 0.0)])
			continue
		# İstiqamətin uzunluğu `1 + qalan ömür`-dür (bax [method World._build_frame]):
		# client topu ömrünün sonundan o yana çəkməsin və ona "dəydi" deməsin.
		var dir := Vector2(d[b + 4], d[b + 5])
		var len := dir.length()
		var unit := dir / len if len > 0.0001 else Vector2.RIGHT
		out.append([d[b], d[b + 1], d[b + 2], d[b + 3], unit.x, unit.y, d[b + 6], d[b + 7],
			maxf(len - 1.0, 0.0)])
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
	# Obyekt rejimlərində qab qurumur (ANA, NÜVƏ TOPU), YAŞ ADA-da isə yaş sahə
	# qabın mərkəzində deyil — gəzən adadır (bax [method wet_circle]).
	if mode == Mode.ISLAND:
		return wet_circle(mode, t).z
	if mode == Mode.MOTHER or mode == Mode.BALL:
		return wall_radius(mode)
	# ÜÇLÜK öz ölçüləri ilə işləyir: dar qab, tez quruma, qısa raund.
	# Böyük qabda üç nəfər bir-birini axtarmaqla raundu bitirərdi.
	if mode == Mode.TRIO:
		if t <= TRIO_DRY_DELAY:
			return TRIO_RADIUS
		var kt := clampf((t - TRIO_DRY_DELAY) / TRIO_DRY_TIME, 0.0, 1.0)
		return lerpf(TRIO_RADIUS, TRIO_END_RADIUS, smoothstep(0.0, 1.0, kt))

	# CÜT eyni qabı TƏK QALAN ilə bölüşür — ayrı arena deyil, ayrı QAYDADIR.
	if mode != Mode.SOLO and mode != Mode.DUO:
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


## Yaş sahə — `Vector3(mərkəz x, mərkəz y, radius)`.
##
## YAŞ ADA-da mərkəz gəzir, qalan rejimlərdə qabın mərkəzidir. [method dish_radius]
## kimi YALNIZ rejimdən və matç saatından çıxır (prediction şərti).
##
## Ada [constant ISLAND_START]-a qədər bütün qabdır, sonra [constant ISLAND_SHRINK]
## saniyədə [constant ISLAND_RADIUS]-a yığılır və "səkkiz" yolu ilə gəzir. Yolun
## başlanğıcı lemniskatın düyünüdür — qabın mərkəzi, yəni yığılma sıçrayışsızdır.
static func wet_circle(mode: int, t: float) -> Vector3:
	if mode != Mode.ISLAND:
		return Vector3(0.0, 0.0, dish_radius(mode, t))
	if t <= ISLAND_START:
		return Vector3(0.0, 0.0, ISLAND_WALL)
	var c := island_center(t)
	var k := clampf((t - ISLAND_START) / ISLAND_SHRINK, 0.0, 1.0)
	return Vector3(c.x, c.y, lerpf(ISLAND_WALL, ISLAND_RADIUS, smoothstep(0.0, 1.0, k)))


## Adanın mərkəzi — orta xətt (x = 0) boyunca şimal–cənub yırğalanır, dövrü
## [constant ISLAND_PERIOD], yarımoxu [constant ISLAND_A].
##
## Bazalar qərbdə və şərqdədir, yəni ada hər an iki bazadan EYNİ uzaqlıqdadır. Əvvəl
## yol "səkkiz" idi və ilk ilmədə ada qərbə — komanda 0-ın bazasına — gedirdi: şərq–qərb
## oxunda komanda 0 səkkiz matçın yeddisini, şimal–cənub "səkkizində" isə ondan yeddisini
## udurdu (səkkizin hər rübü bir tərəfə 113 px əyilir, birinci rüb qərbədir).
static func island_center(t: float) -> Vector2:
	if t <= ISLAND_START:
		return Vector2.ZERO
	return Vector2(0.0, ISLAND_A * sin(TAU * (t - ISLAND_START) / ISLAND_PERIOD))


## NÜVƏ TOPU: Nüvənin radiusu çəkiyə görə — ağır Nüvə böyük və yavaşdır.
static func ball_radius(weight: float) -> float:
	return BALL_R0 + maxf(weight - float(BALL_WEIGHT), 0.0) * BALL_R_PER_W


## NÜVƏ TOPU: [param pos] hansı komandanın qapısının içindədir (-1 heç birinin).
##
## Qapı şüşənin üstündəki yarıqdır: Nüvənin kənarı şüşəyə çatanda və mərkəzi qapının
## eni boyunca olanda qol sayılır. Komanda 0-ın qapısı qərbdə (bucaq π), 1-inki şərqdə.
static func goal_at(pos: Vector2, radius: float) -> int:
	if pos.length() < BALL_WALL - radius - 4.0:
		return -1
	if absf(pos.y) > BALL_GOAL_HALF:
		return -1
	return 0 if pos.x < 0.0 else 1


## Kameranın göstərdiyi dünya sahəsi — 16:9 ekranın qısa kənarı boyunca.
static func view_span(capacity: int) -> float:
	return VIEW_SPAN_BASE + (germ_radius(capacity) - BASE_RADIUS) * VIEW_SPAN_PER_RADIUS


## Oyunçunun gördüyü dünya SAHƏSİ (kvadrat piksel) — hər ekranda eyni.
static func view_area(capacity: int) -> float:
	var s := view_span(capacity)
	return s * s * VIEW_ASPECT_REF


## Kameranın miqyası: sahəni sabit saxlayan zoom.
##
## Ekranın forması yalnız sahənin FORMASINI dəyişir, ölçüsünü yox: geniş
## ekran enli və alçaq, kvadrata yaxın ekran dar və hündür görür.
static func camera_zoom(capacity: int, viewport: Vector2) -> float:
	return camera_zoom_span(view_span(capacity), viewport)


## Eyni hesab, amma hazır `span` ilə — kamera yumşaq keçid üçün onu
## interpolyasiya edir (bax [method Arena._update_camera]).
static func camera_zoom_span(span: float, viewport: Vector2) -> float:
	var px := maxf(viewport.x * viewport.y, 1.0)
	var area := maxf(span * span * VIEW_ASPECT_REF, 1.0)
	return sqrt(px / area)


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
