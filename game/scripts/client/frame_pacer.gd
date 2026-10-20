class_name FramePacer
extends Node
## Android-də kadr ritmi və enerji siyasəti. YALNIZ kadr tezliyini idarə edir —
## qrafikaya heç vaxt toxunmur (bax `design/PERF_PLAN.md`, F5).
##
## ── Niyə lazımdır ───────────────────────────────────────────────────────
##
## Godot-un GLES3 yolunda Android üçün kadr ritmi kitabxanası (Swappy) yoxdur —
## o, yalnız Vulkan render-dədir. `Engine.max_fps` kadrlar arasını öz saatı ilə
## yuxu ilə doldurur, ekranın vsync-i isə ayrı saatdır. Emulyatorda ölçülüb
## (SurfaceFlinger-in ekrana çıxış vaxtları, A04s ekranı, TƏK QALAN):
##
##   - 90 Hz ekranda 60 həddi: kadrların YARISI 11 ms, yarısı 22 ms ekranda qalır
##     — titrəmə. Oyunun öz ölçüsü bunu görmür (ona "60 FPS, 16.67 ms" görünür);
##   - 90 Hz ekranda 30 həddi: 5 qaçışdan birində kadrların 48%-i ritmdən çıxır;
##   - `Surface.setFrameRate` ilə tezliyi SİSTEMDƏN istəyəndə: 30 → 99.4%,
##     45 → 99.8% bərabər. 60 istəniləndə, 60 Hz rejimi olmayan ekranda sistem
##     özü bərabər 45 verdi.
##
## Galaxy A04s-in ekranı 90 Hz-dir. Android 15 oyunları özü 60 Hz-ə keçirir;
## problem 90/120 Hz ekranlı Android 11–14 telefonlarındadır.
##
## ── Necə işləyir ────────────────────────────────────────────────────────
##
## 1. Kadr həddi sistemdən İSTƏNİLİR (`Surface.setFrameRate`, Android 11+). Sistem
##    ekranı ona uyğun rejimə keçirir (90 → 60 Hz) və ya oyuna öz vsync-ini o
##    tezlikdə verir (Android 12+, "frame rate override": 60 Hz ekranda 30).
## 2. Ekranın oyuna verdiyi tezlik hər saniyə oxunur. Sistem oyuna ekranın öz
##    tezliyindən AŞAĞI vsync veribsə və o, hədlə eynidirsə, ritmi vsync saxlayır
##    (`Engine.max_fps = 0` — ikinci saat yoxdur). Qalan hallarda köhnə yol,
##    `Engine.max_fps`, amma ekrana BÖLÜNƏN həddlə ([method even_rate]: 90 Hz-də
##    60 → 45). 60 Hz ekranda 60 həddi əvvəlki kimidir: orada vsync ritmi
##    emulyatorda yuxu ilə həddən bir az PİS çıxdı (vsync-i qaçıran kadr 14.1% və
##    12.2%, 8+8 növbəli qaçış).
## 3. Enerji siyasəti — Brawl Stars kimi, kadr 30-a enir: batareya qənaəti,
##    Game Mode "batareya", telefon qızanda ([method thermal_step]). Qızma
##    ehtiyatı (thermal headroom) 10 saniyəlik PROQNOZDUR — kadr boğulmadan ƏVVƏL
##    enir.
##
## ADPF Performance Hint (hər kadrın işini sistemə bildirmək) burada YOXDUR: işləyir,
## amma emulyatorda kadra ~0.3 ms əlavə etdi, faydası isə yalnız real telefonda
## ölçülə bilər (README, «Kadr ritmi və enerji siyasəti»).
##
## Plugin, Kotlin və NDK lazım deyil: Godot 4.7-nin `AndroidRuntime` və
## [JavaClassWrapper]-i bu API-ləri birbaşa GDScript-dən çağırır. Bütün
## çağırışlar Godot axınındadır (UI axınında GDScript işləmir). Hər addımın
## uğursuzluğu yalnız həmin addımı söndürür — oyun köhnə yola düşür.

## Enerji siyasətinin kadrı (Brawl Stars batareyada və qızanda 30-a keçir).
const LOW_POWER_FPS := 30
## Bərabər ritm naminə bundan aşağı enilmir (30 həddi ilə 45 Hz-lik ekranda 22.5 FPS
## olmasın) — onda köhnə yol, hədd olduğu kimi qalır.
const EVEN_FLOOR := 30

## Ekranın tezliyi bu qədər saniyədən bir oxunur (sistem istəyi gec tətbiq edə bilər).
const DISPLAY_POLL := 1.0
## Batareya qənaəti və Game Mode.
const POWER_POLL := 5.0
## Qızma: `getThermalHeadroom` saniyədə birdən tez çağırılanda NaN qaytarır.
const THERMAL_POLL := 10.0
## Proqnozlaşdırılan ehtiyat bundan çoxdursa — "isti" (1.0 = boğulmanın başlanğıcı).
const HOT_HEADROOM := 0.85
## Soyuma: ehtiyat bundan az və status yüngül olmalıdır...
const COOL_HEADROOM := 0.70
## ...ardıcıl bu qədər saniyə. Sərhəddə titrəməsin (60 ↔ 30 ↔ 60).
const COOL_HOLD := 30.0

## PowerManager.THERMAL_STATUS_*: 1 = yüngül, 2 = orta (UX hələ az təsirlənir).
const THERMAL_LIGHT := 1
const THERMAL_MODERATE := 2
## GameManager.GAME_MODE_BATTERY.
const GAME_MODE_BATTERY := 3
## Surface.FRAME_RATE_COMPATIBILITY_FIXED_SOURCE — oyunun öz sabit ritmi var.
const COMPAT_FIXED_SOURCE := 1

## Oyunçunun (və ya keyfiyyət səviyyəsinin) həddi — [method request] verir.
var _want := 0
## Enerji siyasətinin tavanı; 0 = yoxdur.
var _power := 0
## İkisinin birləşməsi — sistemdən istənən.
var _target := 0
## Oyunun HƏQİQƏTƏN işlədiyi tezlik ([method rate]).
var _rate := 0
## Sistemin OYUNA verdiyi vsync tezliyi (`Display.getRefreshRate`; Android 12+-da
## frame rate override olanda ekranın öz tezliyindən aşağıdır).
var _display_hz := 0.0
## Ekranın fiziki rejiminin tezliyi (`Display.getMode().getRefreshRate()`).
var _mode_hz := 0.0
var _voted := -1

var _sdk := 0
var _activity = null
var _display = null
var _power_manager = null
var _game_manager = null

var _display_wait := 0.0
var _power_wait := 0.0
var _thermal_wait := 0.0
var _revote_wait := -1.0
var _revote_tries := 0
var _saver := false
var _game_mode := 0
var _hot := false
var _thermal := {}
var _clock := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("android"):
		_connect_android()
	_update(true)


## Oyunçunun kadr həddi dəyişdi ([method Settings._apply_frame_cap]); 0 = sərbəst.
func request(cap: int) -> void:
	_want = maxi(cap, 0)
	_update(false)


## Oyunun hədəf kadr tezliyi — kadr büdcəsini bu hesablayır
## ([method Settings.frame_cap]); 0 = hədd yoxdur.
func rate() -> int:
	return _rate


## Kadr tezliyi ekranın tezliyinə BÖLÜNƏN ən böyük qiymət, [param cap]-dən çox deyil.
##
## 90 Hz ekranda 60 kadr bərabər çıxa bilməz (hər kadr ya 1, ya 2 vsync) — 45
## isə həmişə 2 vsync-dir. 60 və 120 Hz-də 60 dəyişmir. Nisbət tam ədədə 0.1-dən
## yaxındırsa (59.94 Hz, 119.8 Hz), o götürülür; yoxsa yuxarı yuvarlaqlaşdırılır —
## hədd aşılmır. [constant EVEN_FLOOR]-dan aşağı enmək lazım gəlirsə, hədd olduğu
## kimi qaytarılır. Brauzer eyni qaydanı `web/shell.html`-də (`evenStep`) tətbiq edir.
static func even_rate(cap: int, display_hz: float) -> int:
	if cap <= 0:
		return 0
	if display_hz <= 1.0:
		return cap
	var r := display_hz / float(cap)
	var step := maxi(1, roundi(r) if absf(r - roundf(r)) < 0.1 else ceili(r))
	var even := mini(cap, roundi(display_hz / float(step)))
	return even if even >= mini(cap, EVEN_FLOOR) else cap


## Ritmi vsync-mi saxlasın ([code]Engine.max_fps = 0[/code]) — yalnız sistem oyuna
## ekranın öz tezliyindən AŞAĞI, məhz [param rate] tezliyində vsync veribsə (frame
## rate override). Ekranın öz tezliyində köhnə yol qalır (bax yuxarıda, 2-ci bənd).
static func vsync_paces(rate: int, display_hz: float, mode_hz: float) -> bool:
	if rate <= 0 or display_hz <= 1.0 or mode_hz <= 1.0:
		return false
	return display_hz < mode_hz - 0.5 and absf(display_hz - float(rate)) <= 0.6


## Enerji siyasətinin tavanı: batareya qənaəti, Game Mode "batareya" və ya qızma.
static func power_cap(saver: bool, game_mode: int, hot: bool) -> int:
	if saver or hot or game_mode == GAME_MODE_BATTERY:
		return LOW_POWER_FPS
	return 0


## İki kadr həddinin sərtini; 0 = hədd yoxdur.
static func combine(a: int, b: int) -> int:
	if a <= 0:
		return maxi(b, 0)
	if b <= 0:
		return a
	return mini(a, b)


## Qızma vəziyyəti — "isti"dirmi. [param state] çağırışlar arasında saxlanılır.
##
## İstiləşmə DƏRHAL tutulur: proqnozlaşdırılan ehtiyat [constant HOT_HEADROOM]-u
## keçir və ya status "orta"dır. Soyuma isə yalnız ehtiyat [constant COOL_HEADROOM]-dan
## aşağı və status yüngül olanda, ardıcıl [constant COOL_HOLD] saniyə — yoxsa
## telefon sərhəddə 60 ilə 30 arasında atlanardı. Ehtiyat bilinmirsə (NaN, köhnə
## Android), yalnız status oxunur.
static func thermal_step(state: Dictionary, headroom: float, status: int, now: float) -> bool:
	var known := not is_nan(headroom)
	if (known and headroom >= HOT_HEADROOM) or status >= THERMAL_MODERATE:
		state["hot"] = true
		state.erase("calm_since")
		return true
	if not bool(state.get("hot", false)):
		return false
	if (known and headroom > COOL_HEADROOM) or status > THERMAL_LIGHT:
		state.erase("calm_since")
		return true
	var since := float(state.get("calm_since", now))
	state["calm_since"] = since
	if now - since >= COOL_HOLD:
		state["hot"] = false
		state.erase("calm_since")
		return false
	return true


func _process(delta: float) -> void:
	_clock += delta
	if _activity == null:
		return
	_display_wait -= delta
	if _display_wait <= 0.0:
		_display_wait = DISPLAY_POLL
		if _read_display():
			_update(false)
	if _revote_wait >= 0.0:
		_revote_wait -= delta
		if _revote_wait < 0.0:
			_vote(true)
	_power_wait -= delta
	if _power_wait <= 0.0:
		_power_wait = POWER_POLL
		_read_power()
	_thermal_wait -= delta
	if _thermal_wait <= 0.0:
		_thermal_wait = THERMAL_POLL
		_read_thermal()


func _notification(what: int) -> void:
	# Fondan qayıdanda Surface yenidən yaranır və sistemə verilən tezlik itir.
	if what == NOTIFICATION_APPLICATION_RESUMED and _activity != null:
		_revote_tries = 0
		_revote_wait = 0.3


# ---------------------------------------------------------------- qərar

func _update(force: bool) -> void:
	var target := combine(_want, _power)
	var changed := target != _target
	_target = target
	if changed or force:
		_vote(false)
	var rate := even_rate(_target, _display_hz)
	var vsync := _activity != null and vsync_paces(rate, _display_hz, _mode_hz)
	var fps := 0 if vsync else rate
	if Engine.max_fps != fps:
		Engine.max_fps = fps
	if rate != _rate or changed:
		_rate = rate
		print("[pacer] hədd %d (oyunçu %d, enerji %d) · ekran %.1f Hz (rejim %.1f) · kadr %d · %s" % [
			_target, _want, _power, _display_hz, _mode_hz, _rate,
			"vsync" if vsync else "max_fps %d" % fps])


# ---------------------------------------------------------------- Android

func _connect_android() -> void:
	if not Engine.has_singleton("AndroidRuntime"):
		return
	var runtime = Engine.get_singleton("AndroidRuntime")
	_activity = runtime.getActivity() if runtime != null else null
	if _activity == null or _failed("activity"):
		_activity = null
		return
	var version = JavaClassWrapper.wrap("android.os.Build$VERSION")
	_sdk = int(version.SDK_INT) if version != null else 0
	_display = _activity.getWindowManager().getDefaultDisplay()
	if _failed("getDefaultDisplay"):
		_display = null
	_read_display()
	_power_manager = _activity.getSystemService("power")
	if _failed("PowerManager"):
		_power_manager = null
	if _sdk >= 31:
		_game_manager = _activity.getSystemService("game")
		if _failed("GameManager"):
			_game_manager = null
	_read_power()
	_read_thermal()
	print("[pacer] Android API %d · ekran %.1f Hz (rejim %.1f)" % [_sdk, _display_hz, _mode_hz])


## Ekranın tezliklərini oxuyur; dəyişibsə `true`.
func _read_display() -> bool:
	if _display == null:
		return false
	var hz := float(_display.getRefreshRate())
	if _failed("getRefreshRate"):
		return false
	var mode_hz := hz
	var mode = _display.getMode()
	if mode != null and not _failed("getMode"):
		mode_hz = float(mode.getRefreshRate())
		if _failed("Mode.getRefreshRate"):
			mode_hz = hz
	var moved := absf(hz - _display_hz) > 0.5 or absf(mode_hz - _mode_hz) > 0.5
	_display_hz = hz
	_mode_hz = mode_hz
	return moved


## Kadr tezliyini sistemdən istəyir (Android 11+, API 30). [param retry] —
## fondan qayıdandan sonrakı təkrar: Surface hələ hazır deyilsə, bir az sonra.
func _vote(retry: bool) -> void:
	if _activity == null or _sdk < 30:
		return
	if _target == _voted and not retry:
		return
	var surface = _surface()
	if surface == null or not bool(surface.isValid()):
		if retry and _revote_tries < 5:
			_revote_tries += 1
			_revote_wait = 0.5
		return
	# 0 — oyunun öz istəyi yoxdur, sistem özü seçir.
	surface.setFrameRate(float(_target), COMPAT_FIXED_SOURCE)
	if _failed("setFrameRate"):
		return
	_voted = _target
	print("[pacer] sistemdən %d kadr istənildi" % _target)


## Godot-un çəkdiyi SurfaceView-un Surface-i — yalnız getter-lərlə, Godot axınında.
func _surface():
	var godot = _activity.getGodot()
	if godot == null or _failed("getGodot"):
		return null
	var view = godot.getRenderView()
	if view == null or _failed("getRenderView"):
		return null
	var surface_view = view.getView()
	if surface_view == null or _failed("getView"):
		return null
	var holder = surface_view.getHolder()
	if holder == null or _failed("getHolder"):
		return null
	var surface = holder.getSurface()
	if surface == null or _failed("getSurface"):
		return null
	return surface


func _read_power() -> void:
	var saver := false
	if _power_manager != null:
		saver = _truthy(_power_manager.isPowerSaveMode())
		if _failed("isPowerSaveMode"):
			saver = false
	var mode := 0
	if _game_manager != null:
		mode = int(_game_manager.getGameMode())
		if _failed("getGameMode"):
			mode = 0
	if saver != _saver or mode != _game_mode:
		_saver = saver
		_game_mode = mode
		print("[pacer] batareya qənaəti %s · Game Mode %d" % ["açıq" if saver else "bağlı", mode])
	_apply_power()


func _read_thermal() -> void:
	if _power_manager == null or _sdk < 29:
		return
	var status := int(_power_manager.getCurrentThermalStatus())
	if _failed("getCurrentThermalStatus"):
		status = 0
	var headroom := NAN
	if _sdk >= 30:
		headroom = float(_power_manager.getThermalHeadroom(int(THERMAL_POLL)))
		if _failed("getThermalHeadroom"):
			headroom = NAN
	var hot := thermal_step(_thermal, headroom, status, _clock)
	if hot != _hot:
		_hot = hot
		print("[pacer] istilik: %s (ehtiyat %.2f, status %d)" % [
			"isti — kadr %d" % LOW_POWER_FPS if hot else "soyudu", headroom, status])
	_apply_power()


func _apply_power() -> void:
	var cap := power_cap(_saver, _game_mode, _hot)
	if cap != _power:
		_power = cap
		_update(false)


# ---------------------------------------------------------------- köməkçilər

## Java istisnası atıldımı — atıldısa, bir dəfə yazılır və addım söndürülür.
func _failed(what: String) -> bool:
	var ex = JavaClassWrapper.get_exception()
	if ex == null:
		return false
	push_warning("[pacer] %s alınmadı: %s" % [what, str(ex)])
	return true


## JavaClassWrapper Java-nın boolean-ını ədəd kimi də qaytara bilir.
static func _truthy(v) -> bool:
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	return false
