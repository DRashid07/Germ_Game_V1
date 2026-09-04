class_name MainMenu
extends Control
## Baş menyu: ad, server ünvanı, dünyaya giriş.
##
## Şəbəkə axını burada başlayır və qısadır — io tipli oyunda növbə yoxdur:
##   düymə → serverə qoşul → dünyaya gir → arena
##
## "Məşq" düyməsi şəbəkəyə heç toxunmur: eyni [World] və [Sim] kodu
## yerli işə düşür, botlarla. Server yatmış olsa da oyun oynanır.

const SETTINGS_PATH := "user://settings.cfg"
const ARENA_SCENE := "res://scenes/game/arena.tscn"

var _nick: LineEdit
var _addr: LineEdit
var _status: Label
var _buttons: VBoxContainer
var _cancel: Button
var _species_btn: Button

var _joining := false


func _ready() -> void:
	_build()
	_load_settings()

	Net.connected_to_server.connect(_on_connected)
	Net.connection_failed.connect(_on_connect_failed)
	Net.server_disconnected.connect(_on_disconnected)
	Net.world_joined.connect(_on_world_joined)
	Net.join_rejected.connect(_on_join_rejected)


# ---------------------------------------------------------------- interfeys

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Palette.BG_OUTER
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	col.custom_minimum_size = Vector2(520, 0)
	center.add_child(col)

	col.add_child(_make_logo())

	_nick = _make_field("Adın", "Mikrob")
	col.add_child(_nick)

	_addr = _make_field("Server", Const.DEFAULT_SERVER)
	col.add_child(_addr)

	# Növ seçimi. Düymənin öz mətni seçimi göstərir — ayrıca "seçilib" nişanı
	# lazım deyil və menyuda bir sətir yer tutur.
	_species_btn = _make_button(_species_text(), false, _toggle_species)
	col.add_child(_species_btn)

	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 14)
	col.add_child(_buttons)

	_buttons.add_child(_make_button("OYNA", true, _play))
	_buttons.add_child(_make_button("MƏŞQ (offline)", false, _practice))

	_cancel = _make_button("LƏĞV ET", false, _cancel_join)
	_cancel.visible = false
	col.add_child(_cancel)

	_status = Hud._make_label(23, Palette.TEXT_MUTED)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.custom_minimum_size = Vector2(0, 40)
	col.add_child(_status)

	col.add_child(_make_rules())
	col.add_child(_make_controls_hint())


## Loqo: SVG-dən gələn nişan + üstündən əsl şriftlə söz nişanı.
##
## Söz nişanı niyə koddadır: Godot SVG-ni ThorVG ilə rasterləşdirir, ThorVG isə
## `<text>` elementlərini SÜKUTLA ATIR. SVG-yə yazılan mətn oyunda ümumiyyətlə
## görünmür. Şriftlə yazmaq həm həll edir, həm hər ölçüdə kəskin qalır.
func _make_logo() -> Control:
	const LOGO_W := 520.0
	var k := LOGO_W / 600.0                     # SVG viewBox → ekran miqyası
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(LOGO_W, 220.0 * k)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var img := TextureRect.new()
	img.texture = load("res://assets/ui/logo.svg")
	img.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(img)

	wrap.add_child(_logo_word("GERM", 232.0 * k, 34.0 * k, 62.0 * k, Palette.TEXT))
	wrap.add_child(_logo_word("ARENA", 232.0 * k, 104.0 * k, 62.0 * k, Palette.GERM_COLORS[0]))
	return wrap


static func _logo_word(text: String, x: float, y: float, size: float, color: Color) -> Label:
	var l := Label.new()
	l.theme_type_variation = "Heading"
	l.text = text
	l.position = Vector2(x, y)
	l.add_theme_font_size_override("font_size", int(size))
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	l.add_theme_constant_override("outline_size", 8)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Qaydalar üç sətirdə. Oyun tanış deyil, ona görə menyu onu izah edir.
static func _make_rules() -> Label:
	var l := Hud._make_label(20, Palette.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.text = "Qida ye — böyü.  Atdığın top rəqibin içində İKİYƏ bölünür.\n" \
		+ "Tutumu (%d) aşan mikrob PARTLAYIR, partladan +%d tutum alır.\n" \
		+ "Topun %d-dən aşağı düşsə acından partlayırsan."
	l.text = l.text % [Const.START_CAPACITY, Const.CAPACITY_STEP, Const.MIN_BALLS]
	return l


## İdarəetmə ipucu. Masaüstündə klaviatura yazılır, telefonda barmaq —
## çünki siçan bir toxunuş kimi emulyasiya olunur və eyni anda həm hərəkət,
## həm atəş vermir.
## Platformanı `DisplayServer.is_touchscreen_available()` ilə soruşmaq OLMAZ:
## layihədə `emulate_touch_from_mouse` açıqdır, ona görə həmin funksiya
## masaüstündə də `true` qaytarır. Ona görə birbaşa əməliyyat sistemi soruşulur.
static func _make_controls_hint() -> Label:
	var l := Hud._make_label(19, Palette.TEXT_MUTED)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	match OS.get_name():
		"Android", "iOS":
			l.text = "Sol yarı hərəkət · sağ aşağı düymə top atır"
		"Web":
			# Brauzer həm telefonda, həm masaüstündə ola bilər.
			l.text = "Barmaq: sol yarı hərəkət, sağ düymə atır\nPC: WASD / oxlar · BOŞLUQ atır"
		_:
			l.text = "WASD / oxlar hərəkət · BOŞLUQ top atır"
	return l


static func _make_field(placeholder: String, default_text: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = default_text
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.custom_minimum_size = Vector2(0, 58)
	e.add_theme_font_size_override("font_size", 26)
	e.add_theme_color_override("font_color", Palette.TEXT)
	return e


## Düymə: fon SVG-dən gəlir, mətn üstünə yazılır (SVG-lərdə mətn yoxdur,
## ona görə eyni çərçivə bütün dillərdə işlədilə bilir).
static func _make_button(text: String, primary: bool, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 92)
	b.add_theme_font_size_override("font_size", 30)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Palette.TEXT)
	b.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	b.add_theme_constant_override("outline_size", 6)

	var path := "res://assets/ui/button_primary.svg" if primary else "res://assets/ui/button_secondary.svg"
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var pressed := StyleBoxTexture.new()
	pressed.texture = sb.texture
	pressed.modulate_color = Color(0.85, 0.85, 0.85)
	b.add_theme_stylebox_override("pressed", pressed)

	b.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		on_press.call())
	return b


# ---------------------------------------------------------------- növ seçimi

## Növlər arasında növbə ilə keçir. Yalnız GÖRÜNTÜ dəyişir — sürət, ölçü və
## ölüm qaydaları hamısında eynidir, ona görə seçim balansa toxunmur və
## "hansı daha güclüdür" sualı yaranmır.
func _toggle_species() -> void:
	Net.species = Const.species_from((int(Net.species) + 1) % Const.SPECIES_COUNT)
	_species_btn.text = _species_text()
	_save_settings()


## Düymənin mətni. Növün adı ilə yanaşı NƏ ETDİYİ də yazılır — oyunçu
## seçməzdən əvvəl fərqi bilməlidir.
static func _species_text() -> String:
	match Net.species:
		Const.Species.HELIOZOAN:
			return "NÖV: AYAQLI — dibdə yeriyir"
		Const.Species.AMOEBA:
			return "NÖV: AMÖB — sürünərək gedir"
		_:
			return "NÖV: KİRPİKLİ — suda üzür"


# ---------------------------------------------------------------- axın

func _play() -> void:
	if _joining:
		return
	Net.nickname = _clean_nick()
	_save_settings()

	if Net.is_connected_to_server():
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_set_busy(true, "Dünyaya girilir...")
		return

	_set_busy(true, "Serverə qoşulur...")
	var parts := Net.parse_address(_addr.text)
	if Net.join_server(parts[0], parts[1]) != OK:
		_set_busy(false, "Ünvan səhvdir və ya server əlçatmazdır")


func _practice() -> void:
	Net.nickname = _clean_nick()
	_save_settings()
	var arena: Arena = load(ARENA_SCENE).instantiate()
	arena.configure_practice()
	_swap_to(arena)


func _cancel_join() -> void:
	Net.disconnect_from_server()
	_set_busy(false, "Ləğv edildi")


func _on_connected() -> void:
	if _joining:
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_status.text = "Dünyaya girilir..."


func _on_connect_failed() -> void:
	_set_busy(false, "Serverə qoşulmaq alınmadı")


func _on_disconnected() -> void:
	_set_busy(false, "Server bağlantısı kəsildi")


func _on_join_rejected(reason: String) -> void:
	_set_busy(false, reason)


func _on_world_joined(info: Dictionary) -> void:
	var arena: Arena = load(ARENA_SCENE).instantiate()
	arena.configure_online(info)
	_swap_to(arena)


func _swap_to(scene: Node) -> void:
	# configure_* mütləq ağaca əlavə etməzdən ƏVVƏL çağırılmalıdır:
	# arena `_ready`-də həmin məlumatla qurulur.
	var tree := get_tree()
	tree.root.add_child(scene)
	tree.current_scene = scene
	queue_free()


func _set_busy(busy: bool, message: String) -> void:
	_joining = busy
	_buttons.visible = not busy
	_cancel.visible = busy
	_status.text = message


# ---------------------------------------------------------------- ayarlar

func _clean_nick() -> String:
	var s := _nick.text.strip_edges()
	return "Mikrob" if s.is_empty() else s.substr(0, 16)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_nick.text = str(cfg.get_value("player", "nickname", _nick.text))
	# Ayar faylı əl ilə redaktə oluna bilər — dəyər çərçivəyə salınır.
	Net.species = Const.species_from(int(cfg.get_value("player", "species", 0)))
	_species_btn.text = _species_text()
	_addr.text = str(cfg.get_value("net", "address", _addr.text))


## Ayarları yazır — BİLDİYİ açarları, faylın qalanına toxunmadan.
##
## Fayl əvvəlcə OXUNUR, sonra üstünə yazılır. Təzə `ConfigFile` ilə saxlananda
## bu ekranın tanımadığı açarlar — `player/mode` və `video/quality` — səssizcə
## silinirdi: oyunçu bir dəfə köhnə menyudan oynayan kimi seçdiyi rejim
## (məsələn ÜÇLÜK) və qrafika səviyyəsi ilkin dəyərə qayıdırdı.
##
## Bu ekran ehtiyatdır ([MenuV2] əsas girişdir), amma ehtiyat da məlumat
## itirməməlidir.
func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("player", "nickname", _clean_nick())
	cfg.set_value("player", "species", int(Net.species))
	cfg.set_value("net", "address", _addr.text.strip_edges())
	cfg.save(SETTINGS_PATH)
