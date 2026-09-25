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

# ---------- səs ----------
## Hamısı 0..1 xətti amplitudadır; şinə `linear_to_db` ilə verilir.
var master := 0.9
var sfx := 1.0
var ui := 0.8
var muted := false

# ---------- görüntü ----------
var fps_cap := default_fps_cap()
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


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	var argv := OS.get_cmdline_args()
	_fps_locked = argv.has("--max-fps") or argv.has("--fixed-fps")
	load_from_disk()
	apply()


## Cihaza görə ilkin kadr həddi.
##
## Telefonda 60: simulyasiya 30 tick-dir, 120 kadr heç nə əlavə etmir, amma
## batareyanı və istiliyi iki dəfə artırır. Masaüstündə 0 — orada qərar
## vsync-indir və oyunçu onu sürücüdən idarə edir.
static func default_fps_cap() -> int:
	return 60 if OS.has_feature("mobile") else 0


# ---------------------------------------------------------------- fayl

func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return

	# Oyunçu kimliyi və seçimləri [Net]-də yaşayır: onları şəbəkə təbəqəsi
	# dünyaya girərkən göndərir. Ayar faylı yalnız onların DİSKDƏKİ nüsxəsidir.
	Net.nickname = str(cfg.get_value("player", "nickname", Net.nickname))
	# Fayl əl ilə redaktə oluna bilər — hər dəyər çərçivəyə salınır.
	Net.species = Const.species_from(int(cfg.get_value("player", "species", 0)))
	Net.mode = Const.mode_from(int(cfg.get_value("player", "mode", 0)))
	Net.quality = Const.quality_from(int(cfg.get_value(
		"video", "quality", int(Const.default_quality()))))

	master = clampf(float(cfg.get_value("audio", "master", master)), 0.0, 1.0)
	sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
	ui = clampf(float(cfg.get_value("audio", "ui", ui)), 0.0, 1.0)
	muted = bool(cfg.get_value("audio", "muted", muted))

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
	cfg.set_value("video", "fps_cap", fps_cap)
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
	commit()


# ---------------------------------------------------------------- tətbiq

func apply() -> void:
	if _silent:
		return
	_apply_audio()
	if not _fps_locked:
		Engine.max_fps = fps_cap


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
