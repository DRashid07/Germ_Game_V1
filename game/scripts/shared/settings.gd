extends Node
## Oyunçunun bütün ayarları — TƏK mənbə (autoload `Settings`).
##
## ── Niyə ayrıca autoload ────────────────────────────────────────────────
##
## Əvvəl ayarlar [MenuV2]-nin öz metodları idi (`_load_settings` /
## `_save_settings`). Nəticə: ayarı YALNIZ menyu bilirdi. Səs səviyyəsi,
## silkələnmə gücü, sol əl düzümü və titrəmə isə məhz OYUNUN İÇİNDƏ işləməli
## olan şeylərdir — arena, [Hud] və [Sfx] onları oxuya bilmirdi.
##
## İndi ayarlar üç işi bir yerdə görür:
##   1. `user://settings.cfg` faylını oxuyur və yazır;
##   2. dəyəri MOTORA tətbiq edir (səs şinləri, kadr həddi);
##   3. dəyişəndə [signal changed] atır — açıq ekranlar özlərini yeniləyir.
##
## ── Niyə musiqi sürgüsü yoxdur ──────────────────────────────────────────
##
## Oyunda musiqi TREKİ YOXDUR (bax `design/AUDIO_BIBLE.md` — yalnız 10 qısa
## effekt var). "Musiqi" sürgüsü qoysaydıq, o, heç nəyi idarə etməzdi. Menyunun
## öz qaydasıdır: boş idarə heç bir idarədən pisdir — oyunçu onu çəkir, heç nə
## dəyişmir, bütün ayarlar ekranına etibar itir. Trek gələndə burada bir sətir,
## şin isə hazırdır.

signal changed()

const PATH := "user://settings.cfg"

## Səs şinləri. `Master` motorun özünündür, qalan ikisi burada yaradılır
## (bax [method _ensure_buses]).
const BUS_SFX := "SFX"
const BUS_UI := "UI"

## Kadr həddi seçimləri; 0 = sərbəst (vsync nə deyirsə).
##
## Telefonda bu, BATAREYA ayarıdır: 120 Hz ekranda oyun 120 kadr çəkməyə
## çalışır, halbuki simulyasiya saniyədə 30 tick-dir — qalanı sırf istilikdir.
const FPS_CAPS := [30, 60, 120, 0]
const FPS_NAMES := ["30", "60", "120", "SƏRBƏST"]

## Silkələnmə gücü — kameranın zərbə cavabı ([method Arena._add_shake]).
##
## Tam söndürmək YALNIZ görüntüyə təsir edir, oyuna yox. Ayar əlçatanlıq
## üçündür: silkələnmə bəzi oyunçularda ürəkbulanma yaradır və bu, mobil
## oyunlarda standart ayardır.
const SHAKE_LEVELS := [0.0, 0.5, 1.0]
const SHAKE_NAMES := ["QAPALI", "AZ", "NORMAL"]

## Brauzerdə kətanın piksel sıxlığı (CSS pikseli başına): adi hal və MİNİMUM.
## 2 — `web/shell.html`-in öz həddidir. 1.25 zəif GPU-da kadrın işini 2-3 dəfə
## azaldır, yazılar isə hələ oxunaqlı qalır (bax [method _apply_render_scale]).
const WEB_MAX_DPR := 2.0
const WEB_MIN_DPR := 1.25
## Dinamik sıxlığın alt həddi (bax [member auto_dpr]). Bundan aşağıda yazılar
## artıq oxunmur; oyun isə hələ oynanır (915 CSS px enli ekranda 686 px).
const WEB_FLOOR_DPR := 0.75

# ---------- səs ----------
## Hamısı 0..1 xətti amplitudadır; şinə `linear_to_db` ilə verilir.
var master := 0.9
var sfx := 1.0
var ui := 0.8
var muted := false

# ---------- görüntü ----------
var fps_cap := default_fps_cap()
## Keyfiyyəti və kadr həddini oyunçu ÖZÜ seçibmi (ayarlar ekranında).
##
## Seçməyibsə fayldakı rəqəm OXUNMUR — cihazın ilkin dəyəri götürülür. Səbəb:
## menyu OYNA basılanda bütün ayarları yazır ([method MenuV2._save_settings]),
## yəni seçilməmiş ilkin dəyər də diskə düşür. Telefon brauzeri əvvəl masaüstü
## sayılırdı ([method Const.is_handheld]) və orada YÜKSƏK + həddsiz kadr
## yazılmışdı; bayraq olmasa düzəlişdən sonra da həmin oyunçular yazılmış
## dəyərlə qalardı. Bayraq yalnız oyunçu ayarı əli ilə dəyişəndə qalxır.
var quality_chosen := false
var fps_chosen := false
## Avtomatik tənzimləyicinin BU cihazda öyrəndiyi keyfiyyət; -1 = hələ yoxdur
## (bax [method Arena._watch_performance]). Oyunçu özü seçməyibsə, növbəti
## açılış elə bu səviyyədən başlayır — hər dəfə yenidən kəsilib öyrənməsin.
var auto_quality := -1
## Tənzimləyicinin BU cihazda öyrəndiyi kətan sıxlığı (brauzer); 0 = səviyyənin
## öz həddi (bax [method Arena._watch_resolution]).
##
## Keyfiyyət səviyyəsi ilk addımdır, sıxlıq isə onun altında işləyən ikincidir:
## MİNİMUM-da da kadrlar büdcəni aşırsa, kətan daha da kiçilir, ehtiyat
## yarananda isə geri böyüyür. Beləliklə oyun GPU-nun mütləq sürətindən asılı
## olmur — Mali-G52 və ya Adreno 610-un millisaniyəsi nə olursa olsun, sıxlıq
## həmin telefonda büdcəni tutan yerə gəlir.
var auto_dpr := 0.0
var shake := 1.0
var show_fps := false

# ---------- idarə ----------
## Sol əl düzümü: joystick SAĞ yarıda, atəş və super SOL aşağıda.
var left_handed := false
## Titrəmə (haptika) — yalnız telefonda mövcuddur, masaüstündə səssiz keçir.
var haptics := true

# ---------- şəbəkə ----------
var address := Const.default_server()

## Headless (server, `--simtest`, `--autoclient`) — səs və kadr həddi
## tətbiq olunmur: o proseslərin nə audio cihazı var, nə də ekranı.
var _silent := false
## Kadr həddini ƏMR SƏTRİ verib. Onda ayar ona toxunmur — `--max-fps 60` ilə
## çəkilən ölçmələr və kadrlar təkrarlana bilən qalmalıdır (bax `README`).
var _fps_locked := false
## Android-də kadr ritmi və enerji siyasəti (bax [FramePacer]); başqa yerdə `null`.
var _pacer: Node = null


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	var argv := OS.get_cmdline_args()
	_fps_locked = argv.has("--max-fps") or argv.has("--fixed-fps")
	load_from_disk()
	if OS.has_feature("android") and not _silent and not _fps_locked:
		# `load` ilə: server, masaüstü və brauzer bu skripti kompilyasiya etmir.
		_pacer = load("res://scripts/client/frame_pacer.gd").new()
		add_child(_pacer)
	set_process(OS.has_feature("web") and not _silent)
	apply()


## Cihaza görə ilkin kadr həddi.
##
## Telefonda 60: simulyasiya 30 tick-dir, 120 kadr heç nə əlavə etmir, amma
## batareyanı və istiliyi iki dəfə artırır. Masaüstündə 0 — orada qərar
## vsync-indir və oyunçu onu sürücüdən idarə edir.
static func default_fps_cap() -> int:
	# Brauzerdə də: telefonun brauzeri 90/120 Hz ekranda requestAnimationFrame-i
	# o tezlikdə çağırır və həddsiz oyun hər kadrı çəkirdi (bax [method Const.is_handheld]).
	return 60 if Const.is_handheld() else 0


# ---------------------------------------------------------------- fayl

## [param path] yalnız test üçündür — oyun həmişə [constant PATH]-i oxuyur.
func load_from_disk(path := PATH) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return

	# Oyunçu kimliyi və seçimləri [Net]-də yaşayır: onları şəbəkə təbəqəsi
	# dünyaya girərkən göndərir. Ayar faylı yalnız onların DİSKDƏKİ nüsxəsidir.
	Net.nickname = str(cfg.get_value("player", "nickname", Net.nickname))
	# Fayl əl ilə redaktə oluna bilər — hər dəyər çərçivəyə salınır.
	Net.species = Const.species_from(int(cfg.get_value("player", "species", 0)))
	Net.mode = Const.mode_from(int(cfg.get_value("player", "mode", 0)))
	quality_chosen = bool(cfg.get_value("video", "quality_chosen", false))
	fps_chosen = bool(cfg.get_value("video", "fps_chosen", false))
	Net.quality = Const.default_quality()
	auto_quality = int(cfg.get_value("video", "auto_quality", -1))
	if not quality_chosen and auto_quality >= 0:
		# İlk təxmin ilə öyrənilən səviyyədən AŞAĞI olanı götürülür.
		Net.quality = Const.quality_from(maxi(int(Net.quality), auto_quality))
	if quality_chosen:
		Net.quality = Const.quality_from(int(cfg.get_value(
			"video", "quality", int(Net.quality))))
	auto_dpr = clampf(float(cfg.get_value("video", "auto_dpr", 0.0)), 0.0, WEB_MAX_DPR)

	master = clampf(float(cfg.get_value("audio", "master", master)), 0.0, 1.0)
	sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	ui = clampf(float(cfg.get_value("audio", "ui", ui)), 0.0, 1.0)
	muted = bool(cfg.get_value("audio", "muted", muted))

	fps_cap = default_fps_cap()
	if fps_chosen:
		fps_cap = int(cfg.get_value("video", "fps_cap", fps_cap))
	if not FPS_CAPS.has(fps_cap):
		fps_cap = default_fps_cap()
	shake = clampf(float(cfg.get_value("video", "shake", shake)), 0.0, 1.0)
	show_fps = bool(cfg.get_value("video", "show_fps", show_fps))

	left_handed = bool(cfg.get_value("controls", "left_handed", left_handed))
	haptics = bool(cfg.get_value("controls", "haptics", haptics))

	address = str(cfg.get_value("net", "address", address))
	# Köhnə buraxılışın ilkin ünvanı yazılıb qalıbsa, oyunçu onu seçməyib —
	# saxlasaq, yeni build heç vaxt mövcud olmayan serverə qoşulmağa çalışardı.
	if Const.OLD_DEFAULT_SERVERS.has(address.strip_edges()):
		address = Const.default_server()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "nickname", Net.nickname)
	cfg.set_value("player", "species", int(Net.species))
	cfg.set_value("player", "mode", int(Net.mode))

	cfg.set_value("audio", "master", master)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "ui", ui)
	cfg.set_value("audio", "muted", muted)

	cfg.set_value("video", "quality", int(Net.quality))
	cfg.set_value("video", "quality_chosen", quality_chosen)
	cfg.set_value("video", "auto_quality", auto_quality)
	cfg.set_value("video", "auto_dpr", auto_dpr)
	cfg.set_value("video", "fps_cap", fps_cap)
	cfg.set_value("video", "fps_chosen", fps_chosen)
	cfg.set_value("video", "shake", shake)
	cfg.set_value("video", "show_fps", show_fps)

	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "haptics", haptics)

	cfg.set_value("net", "address", address.strip_edges())
	cfg.save(PATH)


## Dəyər dəyişəndən SONRA çağırılır: motora tətbiq et, diskə yaz, xəbər ver.
##
## Üçü bir yerdədir, çünki üçü də hər dəfə lazımdır. Ayrı qalsaydı, kimsə
## birini unudardı və ayar ya işləməz, ya da oyun yenidən açılanda itərdi.
func commit() -> void:
	apply()
	save()
	changed.emit()


## Hər şeyi ilkin dəyərlərə qaytarır.
func reset() -> void:
	master = 0.9
	sfx = 1.0
	ui = 0.8
	muted = false
	fps_cap = default_fps_cap()
	shake = 1.0
	show_fps = false
	left_handed = false
	haptics = true
	address = Const.default_server()
	Net.quality = Const.default_quality()
	quality_chosen = false
	fps_chosen = false
	auto_quality = -1
	auto_dpr = 0.0
	commit()


# ---------------------------------------------------------------- tətbiq

func apply() -> void:
	if _silent:
		return
	_apply_audio()
	if not _fps_locked:
		_apply_frame_cap(effective_fps_cap())
	_apply_render_scale()


## Kadr həddini tətbiq edir. Brauzerdə Godot-un öz həddi İŞLƏDİLMİR.
##
## Godot 4.7-nin thread-siz veb build-ində (bizimki, `variant/thread_support=false`)
## `Engine.max_fps` kadrlar arasındakı boşluğu `OS::add_frame_delay` → `usleep` ilə
## doldurur, emscripten-də isə əsas axında `usleep` gözləmə deyil, BOŞ DÖVRDÜR.
## Ölçülüb (masaüstü Chrome, MİNİMUM, 30 kadr): kadrın işi 4.4 ms, brauzerin kadr
## çağırışı isə 32.8 ms çəkirdi — renderer prosesi kadr başına 33.8 ms CPU yeyirdi,
## yəni bir nüvə oyun boyu 100% fırlanırdı. Telefonda bu, istilik və batareyadır,
## həm də brauzerin öz işinə (GPU prosesi, kompozitor, şəbəkə) vaxt qalmır.
##
## Ona görə brauzerdə `Engine.max_fps = 0` qalır, hədd isə `web/shell.html`-də
## (`germSetFrameCap`) brauzerin kadr ritmindən — requestAnimationFrame-dən —
## kadr buraxmaqla tətbiq olunur: arada əsas axın BOŞDUR.
##
## Köhnə səhifə (funksiyası olmayan qabıq) gəlsə, köhnə yol işləyir.
##
## Android-də həddi [FramePacer] tətbiq edir: tezliyi sistemdən istəyir, ekrana
## bölünməyən həddi bərabər ritmə endirir, sistem oyuna aşağı vsync veribsə
## ritmi vsync-ə verir (bax orada).
func _apply_frame_cap(cap: int) -> void:
	if OS.has_feature("web") and _web_pacing():
		Engine.max_fps = 0
		JavaScriptBridge.eval("window.germSetFrameCap(%d)" % cap)
		_web_cap = cap
		_web_rate = 0
		_web_poll = 0.0
		return
	if _pacer != null:
		_pacer.request(cap)
		return
	Engine.max_fps = cap


## Oyunun HƏQİQƏTƏN işlədiyi kadr həddi (0 = həddsiz) — kadr büdcəsini hesablayan
## kod `Engine.max_fps`-i yox, bunu oxumalıdır: brauzerdə orada 0 durur (bax
## [method _apply_frame_cap]), Android-də isə vsync ritmi saxlayanda da 0-dır.
##
## Bu, oyunçunun seçdiyi rəqəm olmaya bilər: 90 Hz ekranda 60 həddi 45 olur
## (bərabər ritm), telefon qızanda və ya batareya qənaətində 30 (bax [FramePacer]).
## Büdcə bundan hesablanmasa, arena 45 kadrı "yavaş" sayıb keyfiyyəti endirərdi.
func frame_cap() -> int:
	if OS.has_feature("web") and _web_cap >= 0:
		return _web_rate if _web_cap > 0 and _web_rate > 0 else _web_cap
	if _pacer != null:
		return _pacer.rate()
	return Engine.max_fps


## Brauzerdə səhifənin hesabladığı HƏQİQİ kadr tezliyi (bax `web/shell.html`,
## `germFrameRate`). Kadr büdcəsi ([method frame_cap]) kadrda dəfələrlə oxunur,
## ona görə JavaScript-ə hər dəfə yox, [constant WEB_RATE_POLL] saniyədən bir müraciət olunur.
func _process(delta: float) -> void:
	_web_poll -= delta
	if _web_poll > 0.0:
		return
	_web_poll = WEB_RATE_POLL
	var v = JavaScriptBridge.eval("window.germFrameRate ? window.germFrameRate() : 0", true)
	_web_rate = int(round(float(v))) if (v is int or v is float) else 0


const WEB_RATE_POLL := 2.0
var _web_rate := 0
var _web_poll := 0.0


## Səhifə kadr həddini özü tətbiq edə bilirmi — bir dəfə soruşulur.
##
## Cavab ədəd kimi alınır: Godot 4.7-də `JavaScriptBridge.eval` JS-in `true`-sunu
## bool yox, int 1 qaytarır və `== true` müqayisəsi xəta verib funksiyanı
## dayandırırdı — hədd səssizcə köhnə (boş dövrlü) yola düşürdü.
func _web_pacing() -> bool:
	if _web_paced < 0:
		var ok = JavaScriptBridge.eval(
			"typeof window.germSetFrameCap === 'function' ? 1 : 0", true)
		_web_paced = 1 if (ok is int or ok is float or ok is bool) and float(ok) >= 1.0 else 0
	return _web_paced == 1


var _web_paced := -1
var _web_cap := -1


## Brauzerdə yükləmə örtüyünü götürür — oyunun ilk ekranı ÇƏKİLƏNDƏN sonra.
##
## Menyu və arena `_ready`-nin sonunda çağırır; ikinci çağırış heç nə etmir.
## Örtük ("Oyun hazırlanır…", bax `web/shell.html`) əvvəl mühərrik işə düşən kimi
## götürülürdü, zəif telefonda isə menyunun qurulması ondan sonra da 15+ saniyə
## çəkir (ölçülüb: 13× yavaş CPU-da yükləmə 2 s-də bitir, menyu 24 s-də çıxır) —
## bu arada ekranda donmuş kətan qalırdı və oyun "dondu" sanılırdı.
func web_page_ready() -> void:
	if not OS.has_feature("web") or _page_shown:
		return
	_page_shown = true
	RenderingServer.frame_post_draw.connect(_hide_web_status, CONNECT_ONE_SHOT)


func _hide_web_status() -> void:
	JavaScriptBridge.eval("window.germHideStatus && window.germHideStatus()", true)


var _page_shown := false


## Brauzerdə arenaya keçid örtüyünü ("Matç hazırlanır…") açır; açıldısa `true`.
##
## Yalnız axınsız build-də: orada arena ana axında yüklənir və ekran saniyələrlə
## donur (bax [method MenuV2._enter_arena]). Axınlı build-də və telefon tətbiqində
## arena fonda yüklənir — örtük lazım deyil. Köhnə səhifə funksiyanı bilmirsə,
## keçid əvvəlki kimi örtüksüz gedir.
func web_show_prep() -> bool:
	if not OS.has_feature("web") or OS.has_feature("threads"):
		return false
	var ok = JavaScriptBridge.eval(
		"typeof window.germShowPrep === 'function' ? (window.germShowPrep(), 1) : 0", true)
	return (ok is int or ok is float or ok is bool) and float(ok) >= 1.0


## Keçid örtüyünü arenanın İLK kadrı çəkiləndən sonra götürür (arena `_ready`-də
## çağırır; örtük açıq deyilsə heç nə etmir).
func web_hide_prep() -> void:
	if not OS.has_feature("web") or RenderingServer.frame_post_draw.is_connected(_hide_web_prep):
		return
	RenderingServer.frame_post_draw.connect(_hide_web_prep, CONNECT_ONE_SHOT)


func _hide_web_prep() -> void:
	JavaScriptBridge.eval("window.germHidePrep && window.germHidePrep()", true)


## İşlək kadr həddi. MİNİMUM-da oyunçu özü seçməyibsə 30: simulyasiya onsuz
## da saniyədə 30 tick-dir, zəif telefonda isə sabit 30 kadr "gah 60, gah 35"
## kadrdan daha hamar görünür və telefonu qızdırmır.
func effective_fps_cap() -> int:
	if not fps_chosen and Net.quality == Const.Quality.MINIMUM:
		return 30
	return fps_cap


## MİNİMUM-da kadr daha az pikseldə çəkilir.
##
## `canvas_items` rejimi hər şeyi pəncərənin ÖZ ölçüsündə çəkir, kadr başına
## bir neçə qat (fon, maneələr, mikroblar üst-üstə). Zəif GPU-da (Mali-G52 MC2,
## PowerVR GE8320) əsas məhdudiyyət məhz piksel sayıdır.
##
## BRAUZERDƏ kətanın özü kiçilir ([constant WEB_MIN_DPR], bax `web/shell.html`
## `germSetMaxDpr`): Godot kiçik pəncərə görür, ekrana böyütməni isə brauzerin
## kompozitoru onsuz da edir. Əvvəl burada `viewport` rejimi idi — səhnə
## 1280×720-də çəkilir, sonra ayrıca keçidlə kətana böyüdülürdü. Brauzerdə
## kətan onsuz da DPR 2 ilə məhduddur (~1.5 milyon piksel), yəni `viewport`
## cəmi ~40% qənaət edib üstəlik bir keçid əlavə edirdi. Ölçülüb (SwiftShader,
## doldurmaya həssas): kadrın işi DPR 2-də 27–30 ms, `viewport`-da 24–29 ms,
## DPR 1.25-də 8–13 ms.
##
## Telefon tətbiqində (APK) pəncərə ekranın tam ölçüsündədir (2400×1080 =
## 2.6 milyon piksel) və kətan yoxdur — orada `viewport` rejimi qalır.
func _apply_render_scale() -> void:
	if not is_inside_tree():
		return
	var minimum := Net.quality == Const.Quality.MINIMUM
	var want := Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	if minimum and not OS.has_feature("web"):
		want = Window.CONTENT_SCALE_MODE_VIEWPORT
	var root := get_tree().root
	if root.content_scale_mode != want:
		root.content_scale_mode = want
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.germSetMaxDpr && window.germSetMaxDpr(%s)"
			% str(web_dpr()))


## Keyfiyyət səviyyəsinin kətan sıxlığı həddi (brauzer).
static func tier_dpr(quality: int) -> float:
	return WEB_MIN_DPR if quality == int(Const.Quality.MINIMUM) else WEB_MAX_DPR


## Brauzerdə kətanın indiki sıxlıq həddi: səviyyənin öz həddi, tənzimləyici
## daha aşağı öyrənibsə o ([member auto_dpr]).
func web_dpr() -> float:
	var cap := tier_dpr(int(Net.quality))
	return clampf(auto_dpr, WEB_FLOOR_DPR, cap) if auto_dpr > 0.0 else cap


## Ekranın öz sıxlığı (`window.devicePixelRatio`); brauzer deyilsə 1.
##
## Kətan ondan sıx olmur (bax `web/shell.html` `fitCanvas`): masaüstü ekranda
## (1.0) 1.25 həddi heç nəyi dəyişmir və tənzimləyici bunu bilməlidir — yoxsa
## "kiçildir", kadr isə dəyişmir.
static func device_dpr() -> float:
	if not OS.has_feature("web"):
		return 1.0
	var v: Variant = JavaScriptBridge.eval("window.devicePixelRatio || 1", true)
	return maxf(float(v), 0.5) if v != null else WEB_MAX_DPR


## Səs şinləri motorda YARADILIR, `default_bus_layout.tres` faylı ilə yox.
##
## Səbəb: layout resursu redaktordan asılıdır və faylı əl ilə düzəltmək
## lazım gəlirdi. Şinlərin qurulması cəmi bir neçə sətirdir, kodda isə həm
## görünür, həm də şərh oluna bilir.
func _ensure_buses() -> void:
	for bus_name in [BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(bus_name) >= 0:
			continue
		var i := AudioServer.get_bus_count()
		AudioServer.add_bus(i)
		AudioServer.set_bus_name(i, bus_name)
		AudioServer.set_bus_send(i, "Master")


## İki ayrı şin lazımdır, çünki kliplər ARTIQ tarazlanıb.
##
## `AUDIO_BIBLE` iyerarxiyası hər klipin öz səviyyəsini təyin edir və [Sfx]
## bəzilərini üstəlik −6 dB ilə çalır. Sürgü hər klipə ayrıca dəyər versəydi,
## o tarazlıq pozulardı. Şin isə HAMISINI eyni nisbətdə çəkir: menyu toxunuşu
## ilə partlayış arasındakı fərq olduğu kimi qalır.
func _apply_audio() -> void:
	_ensure_buses()
	# Səssiz rejim = Master şini sıfırda. Ayrıca yol saxlamaqdansa bir yoldur:
	# səviyyə geri qaldırılanda oyunçunun köhnə dəyəri itmir.
	_set_bus("Master", 0.0 if muted else master)
	_set_bus(BUS_SFX, sfx)
	_set_bus(BUS_UI, ui)


static func _set_bus(bus: String, level: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i < 0:
		return
	# Sıfır `linear_to_db`-də −inf verir; şini susdurmaq həm dəqiq, həm ucuzdur.
	AudioServer.set_bus_mute(i, level <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(level, 0.001)))


# ---------------------------------------------------------------- haptika

## Qısa titrəmə. Telefonda hiss olunur, masaüstündə və brauzerdə səssiz keçir.
##
## Səs KƏSİLƏ bilər (oyunçu səssiz rejimdədir və ya qulaqlıq yoxdur), ekran
## isə ən gərgin anda barmağın altındadır. Titrəmə həmin anları üçüncü kanaldan
## deyir — oyunun "dörd kanal" qaydasının davamıdır (bax `README` § Zərbə hissi).
func vibrate(ms := 30) -> void:
	if _silent or not haptics:
		return
	Input.vibrate_handheld(ms)
