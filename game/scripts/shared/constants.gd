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
## Sürətlənmə də yumşaqdır — mikrob dayanan kimi dayanmır, azca sürüşür.
const ACCEL := 1200.0
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
const MUZZLE_GAP := 6.0         ## Top membrandan bu qədər kənarda doğulur

# ---------- Qida ----------
const FOOD_RADIUS := 10.0
const FOOD_TARGET := 110        ## Dünyada saxlanılan qida sayı
const FOOD_SPAWN_RATE := 8.0    ## saniyədə neçə ədəd doğulur (hədəfə çatana qədər)
const FOOD_FRICTION := 1.8      ## Səpilən topların sürtünməsi (1/saniyə)
## Atılan top qidaya çevriləndən sonra sahibi onu bu qədər müddət yeyə bilmir —
## əks halda öz atdığını dərhal geri udardı.
const FOOD_ARM_TIME := 0.7

enum EvKind { FIRE = 0, ABSORB = 1, HIT = 2, BURST = 3 }

# ---------- Snapshot sahə indeksləri ----------
## Snapshot Dictionary yox, Array-dir — 30 Hz-də hər bayt sayılır.
## Bu enum-lar həmin massivlərə ad verir ki, kod oxunaqlı qalsın.
## Server tərəfdə [method World.snapshot_for] eyni sıranı qurur.

enum Snap { TICK, GERMS, SHOTS, FOOD, EVENTS, BOARD, POP }
enum GF { ID, NAME, COLOR, X, Y, VX, VY, AIM, BALLS, CAP, SAFE, ACK, CD }
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
