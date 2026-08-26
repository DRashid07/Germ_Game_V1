extends Node
## Oyunun bütün paylaşılan sabitləri.
## Client və server EYNİ dəyərləri oxuyur — simulyasiya uyğunluğu buradan başlayır.

# ---------- Petri qabı (dünya) ----------
## Dünya dairəvidir və mərkəzi (0,0)-dır. Ekran dünyadan kiçikdir —
## kamera oyunçunu izləyir (io tipli oyunlarda standart həll).
const WORLD_RADIUS := 1200.0

## Kameranın göstərdiyi dünya eni (720 vahidlik ekranın eni qədər).
## Böyük mikrob daha geniş sahə görür — həm ədalətlidir, həm böyüməni hiss etdirir.
const VIEW_WIDTH_BASE := 620.0
const VIEW_WIDTH_PER_RADIUS := 8.0
## Client-ə göndərilən sahə ekrandan bir qədər genişdir ki, obyektlər
## kənarda "peyda olmasın". 1.35 portret 20:9-a qədər bütün nisbətləri örtür
## (kadrın küncü mərkəzdən ən çox 1.22 × en məsafədədir).
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
const SHOT_RADIUS := 9.0
const SHOT_LIFETIME := 2.2       ## × sürət ≈ 920 px məsafə (ekran eninin 1.5 misli)
const SHOT_BOUNCES := 2         ## Divardan/maneədən neçə dəfə sıçraya bilər
const SHOT_RECOIL := 90.0       ## Top atanda mikrobun geri təpməsi (sürətə nisbətdə hiss olunur)

# ---------- Qida ----------
const FOOD_RADIUS := 10.0
const FOOD_TARGET := 110        ## Dünyada saxlanılan qida sayı
const FOOD_SPAWN_RATE := 8.0    ## saniyədə neçə ədəd doğulur (hədəfə çatana qədər)
const FOOD_FRICTION := 1.8      ## Səpilən topların sürtünməsi (1/saniyə)
## Atılan top qidaya çevriləndən sonra sahibi onu bu qədər müddət yeyə bilmir —
## əks halda öz atdığını dərhal geri udardı.
const FOOD_ARM_TIME := 0.7

enum EvKind { FIRE = 0, ABSORB = 1, HIT = 2, BURST = 3 }

## Mikrobun növü. YALNIZ görüntüdür — sürət, radius, ölüm qaydaları eynidir
## (bax [GermVisual]). Buna baxmayaraq [Sim]-də saxlanılır, çünki oyunçunun
## seçimidir və bütün client-lərə eyni çatmalıdır: hər kəs eyni mikrobu eyni
## növdə görməlidir.
enum Species { CILIATE = 0, HELIOZOAN = 1, AMOEBA = 2 }
## Növ snapshot-da neçə bit tutur — [enum GFlag] bunu istifadə edir.
const SPECIES_COUNT := 3


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

enum Snap { TICK, GERMS, SHOTS, FOOD, EVENTS, BOARD, POP }
enum GF { ID, NAME, COLOR, X, Y, VX, VY, AIM, BALLS, CAP, FLAGS, ACK, CD }

## [constant GF.FLAGS] sahəsinin bitləri.
##
## Növ AYRICA sahə kimi göndərilmir: bu sətir hər mikrob üçün saniyədə
## 30 dəfə gedir və Variant massivində hər ədəd 9 bayt tutur. Toxunulmazlıq
## onsuz da 0/1 idi, yəni sahənin qalan bitləri boş yatırdı — növ oraya
## girir və şəbəkəyə SIFIR bayt əlavə olunur.
##
##   bit 0      → doğuş qalxanı
##   bit 1-2    → növün nömrəsi (0..3)
##
## Növə İKİ bit ayrılıb, biri yox: üçüncü növ (amöb) əlavə olunanda bir bit
## çatmadı. İki bit dördüncü növə də yer saxlayır.
enum GFlag { SAFE = 1, SPECIES_SHIFT = 1, SPECIES_MASK = 6 }
enum SF { ID, COLOR, X, Y, DX, DY }
enum EF { KIND, X, Y, ARG, COLOR }
## Liderlər cədvəlinin bir sətri.
enum LF { NAME, POPS, CAP }

## Qida snapshot-un ən ağır hissəsidir (ekranda 50-dən çox ola bilər), ona görə
## massiv-içində-massiv YOX, düz [PackedFloat32Array] göndərilir: hər qida üçün
## üç ədəd. Variant massivində hər ədəd 9 bayt tutur, burada 4 —
## 30 Hz-də bu, saniyədə onlarla kilobayt fərq deməkdir.
const FOOD_STRIDE := 3
enum FF { ID, X, Y }


## Kameranın göstərdiyi dünya eni.
static func view_width(capacity: int) -> float:
	return VIEW_WIDTH_BASE + (germ_radius(capacity) - BASE_RADIUS) * VIEW_WIDTH_PER_RADIUS


## Oyunçuya göndərilən sahənin radiusu (area of interest).
static func aoi_radius(capacity: int) -> float:
	return view_width(capacity) * AOI_FACTOR


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
