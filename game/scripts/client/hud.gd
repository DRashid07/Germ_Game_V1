class_name Hud
extends CanvasLayer
## Oyun içi interfeys: doluluq göstəricisi, liderlər, xəritə, idarəetmə.
##
## Ekran koordinatlarında yaşayır (CanvasLayer), ona görə kamera yaxınlaşıb
## uzaqlaşsa da HUD həmişə eyni fiziki ölçüdə qalır — baş barmaq üçün bu vacibdir.
##
## Sol yarı hərəkət joystickinin zonasıdır — barmağı hara qoysan, idarə orada
## yaranır. Sağ aşağı küncdə top atma düyməsi dayanır.
##
## HUD-un ƏSAS işi bir rəqəmi göstərməkdir: neçə topun var və tutumun nə qədərdir.
## Oyunun bütün qərarları bu rəqəmdən asılıdır, ona görə o, ekranın ən görünən
## yerindədir və rəngi vəziyyəti özü izah edir.

const STICK_ZONE_TOP := 0.34     ## Hərəkət zonası ekranın bu hündürlüyündən aşağı başlayır

const FIRE_BOX := 200.0
const FIRE_MARGIN_RIGHT := 40.0
const FIRE_MARGIN_BOTTOM := 68.0

const GAUGE_W := 250.0
const BAR_H := 16.0
const MAP_SIZE := 132.0

var move_stick: TouchStick
var fire_button: FireButton
var minimap: Minimap

var _root: Control
var _gauge_lbl: Label
var _level_lbl: Label
var _bar: ColorRect
var _bar_bg: ColorRect
var _warn_lbl: Label
var _board_lbl: Label
var _pop_lbl: Label
var _center_lbl: Label
var _sub_lbl: Label
var _result: Control
var _result_title: Label
var _result_body: Label

var _local_color := Palette.TEXT
var _warn_t := 0.0


func build(base_tex: Texture2D, knob_tex: Texture2D) -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_build_gauge()
	_build_board()
	_build_minimap()
	_build_center()
	_build_result()
	_build_controls(base_tex, knob_tex)


# ---------------------------------------------------------------- qurulma

## Sol yuxarı: "top / tutum" — oyunun bütün məntiqi bu rəqəmdədir.
func _build_gauge() -> void:
	_gauge_lbl = _make_label(46, Palette.TEXT)
	_gauge_lbl.position = Vector2(20, 12)
	_gauge_lbl.size = Vector2(GAUGE_W, 56)
	_root.add_child(_gauge_lbl)

	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(Palette.PANEL, 0.9)
	_bar_bg.position = Vector2(22, 70)
	_bar_bg.size = Vector2(GAUGE_W, BAR_H)
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar_bg)

	_bar = ColorRect.new()
	_bar.color = Palette.SAFE
	_bar.position = _bar_bg.position
	_bar.size = Vector2(0, BAR_H)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_bar)

	_level_lbl = _make_label(20, Palette.TEXT_MUTED)
	_level_lbl.position = Vector2(22, 92)
	_level_lbl.size = Vector2(GAUGE_W, 28)
	_root.add_child(_level_lbl)

	# Xəbərdarlıq zolağı — yalnız təhlükə anında görünür.
	_warn_lbl = _make_label(24, Palette.DANGER)
	_warn_lbl.position = Vector2(22, 118)
	_warn_lbl.size = Vector2(420, 32)
	_warn_lbl.visible = false
	_root.add_child(_warn_lbl)


func _build_board() -> void:
	_pop_lbl = _make_label(20, Palette.TEXT_MUTED)
	_pop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pop_lbl.anchor_left = 1.0
	_pop_lbl.anchor_right = 1.0
	_pop_lbl.offset_left = -260
	_pop_lbl.offset_right = -20
	_pop_lbl.offset_top = 14
	_pop_lbl.offset_bottom = 40
	_root.add_child(_pop_lbl)

	_board_lbl = _make_label(21, Palette.TEXT)
	_board_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_board_lbl.anchor_left = 1.0
	_board_lbl.anchor_right = 1.0
	_board_lbl.offset_left = -260
	_board_lbl.offset_right = -20
	_board_lbl.offset_top = 42
	_board_lbl.offset_bottom = 190
	_root.add_child(_board_lbl)


func _build_minimap() -> void:
	minimap = Minimap.new()
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -(MAP_SIZE + 18.0)
	minimap.offset_right = -18.0
	minimap.offset_top = 200.0
	minimap.offset_bottom = 200.0 + MAP_SIZE
	_root.add_child(minimap)


func _build_center() -> void:
	_center_lbl = _make_label(54, Palette.TEXT)
	_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_lbl.anchor_left = 0.0
	_center_lbl.anchor_right = 1.0
	_center_lbl.anchor_top = 0.30
	_center_lbl.anchor_bottom = 0.30
	_center_lbl.offset_bottom = 72
	_root.add_child(_center_lbl)

	_sub_lbl = _make_label(26, Palette.TEXT_MUTED)
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.anchor_left = 0.0
	_sub_lbl.anchor_right = 1.0
	_sub_lbl.anchor_top = 0.30
	_sub_lbl.anchor_bottom = 0.30
	_sub_lbl.offset_top = 70
	_sub_lbl.offset_bottom = 112
	_root.add_child(_sub_lbl)

	hide_message()


## Mikrob partlayanda açılan nəticə lövhəsi.
func _build_result() -> void:
	_result = Control.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result.visible = false
	_root.add_child(_result)

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_OUTER, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result.add_child(dim)

	_result_title = _make_label(64, Palette.DANGER)
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.anchor_left = 0.0
	_result_title.anchor_right = 1.0
	_result_title.anchor_top = 0.32
	_result_title.anchor_bottom = 0.32
	_result_title.offset_bottom = 84
	_result.add_child(_result_title)

	_result_body = _make_label(28, Palette.TEXT)
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.anchor_left = 0.0
	_result_body.anchor_right = 1.0
	_result_body.anchor_top = 0.32
	_result_body.anchor_bottom = 0.32
	_result_body.offset_top = 96
	_result_body.offset_bottom = 320
	_result.add_child(_result_body)


func _build_controls(base_tex: Texture2D, knob_tex: Texture2D) -> void:
	move_stick = TouchStick.new()
	move_stick.base_texture = base_tex
	move_stick.knob_texture = knob_tex
	move_stick.anchor_left = 0.0
	move_stick.anchor_right = 0.5
	move_stick.anchor_top = STICK_ZONE_TOP
	move_stick.anchor_bottom = 1.0
	_root.add_child(move_stick)

	fire_button = FireButton.new()
	fire_button.anchor_left = 1.0
	fire_button.anchor_top = 1.0
	fire_button.anchor_right = 1.0
	fire_button.anchor_bottom = 1.0
	fire_button.offset_left = -(FIRE_BOX + FIRE_MARGIN_RIGHT)
	fire_button.offset_right = -FIRE_MARGIN_RIGHT
	fire_button.offset_top = -(FIRE_BOX + FIRE_MARGIN_BOTTOM)
	fire_button.offset_bottom = -FIRE_MARGIN_BOTTOM
	_root.add_child(fire_button)


static func _make_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------------------------------------------------------------- yeniləmə

func set_local_color(c: Color) -> void:
	_local_color = c
	fire_button.set_germ_color(c)


func _process(delta: float) -> void:
	# Xəbərdarlıq yazısı yanıb-sönür: hərəkət diqqəti mətndən tez çəkir.
	if _warn_lbl.visible:
		_warn_t += delta
		_warn_lbl.modulate.a = 0.55 + 0.45 * sin(_warn_t * 9.0)


## Əsas göstərici: neçə top / tutum.
func update_gauge(balls: int, capacity: int) -> void:
	_gauge_lbl.text = "%d / %d" % [balls, capacity]
	var fill := clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	var col := Palette.fill_color(fill)
	_gauge_lbl.add_theme_color_override("font_color", col)
	_bar.color = col
	_bar.size.x = GAUGE_W * fill
	_level_lbl.text = "Səviyyə %d" % Const.level_of(capacity)

	# İki təhlükə var və ikisi də ölümcüldür: dolub partlamaq, acından partlamaq.
	if balls >= capacity - 1:
		_set_warning("DOLURSAN — TOP AT!")
	elif balls <= Const.MIN_BALLS:
		_set_warning("ACSAN — QİDA YE!")
	else:
		_set_warning("")


func _set_warning(text: String) -> void:
	if text.is_empty():
		_warn_lbl.visible = false
		return
	if _warn_lbl.text != text:
		_warn_lbl.text = text
		_warn_t = 0.0
	_warn_lbl.visible = true


func update_board(rows: Array, population: int) -> void:
	_pop_lbl.text = "Dünyada %d mikrob" % population
	var lines := PackedStringArray()
	for i in rows.size():
		var row: Array = rows[i]
		lines.append("%d. %s  %d" % [i + 1, row[Const.LF.NAME], int(row[Const.LF.POPS])])
	_board_lbl.text = "\n".join(lines)


func set_fire_state(ratio: float, has_ammo: bool) -> void:
	fire_button.set_state(ratio, has_ammo)


func show_message(text: String, sub := "") -> void:
	_center_lbl.text = text
	_center_lbl.visible = true
	_sub_lbl.text = sub
	_sub_lbl.visible = not sub.is_empty()


func hide_message() -> void:
	_center_lbl.visible = false
	_sub_lbl.visible = false


## Mikrob partladı — oyun bitdi.
func show_result(result: Dictionary) -> void:
	hide_message()
	_warn_lbl.visible = false
	var killer := str(result.get("killer", ""))
	var age := int(float(result.get("age", 0.0)))
	_result_title.text = "PARTLADIN"
	_result_body.text = "%s\n\nPartlatdığın mikrob: %d\nÇatdığın tutum: %d (səviyyə %d)\nYaşadın: %d:%02d\n\nMenyuya qayıdılır..." % [
		("Səni partladan: " + killer) if not killer.is_empty() else "Acından partladın",
		int(result.get("pops", 0)),
		int(result.get("cap", Const.START_CAPACITY)),
		int(result.get("level", 1)),
		age / 60, age % 60,
	]
	_result.visible = true


func release_sticks() -> void:
	move_stick.cancel()
	fire_button.cancel()
