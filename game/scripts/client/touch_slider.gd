class_name TouchSlider
extends Control
## Səs sürgüsü — barmaq üçün.
##
## Godot-un `HSlider`-i işlədilmir, çünki onun tutacağı standart mövzuda ~10
## pikseldir: siçanla tutmaq olar, baş barmaqla yox. Oyunun qalan idarələri də
## əl ilə çəkilib ([TouchStick], [FireButton], [SuperButton]) — bu, həmin dilin
## davamıdır.
##
## İKİ hərəkəti də qəbul edir:
##   • zolağa TOXUNMAQ — dəyər dərhal ora atılır (uzun sürüşdürmə lazım deyil);
##   • tutacağı SÜRÜŞDÜRMƏK — barmaq zolaqdan kənara çıxsa da buraxılana qədər izlənir.

signal value_changed(value: float)
## Barmaq qalxanda bir dəfə. Diskə yazmaq və səs nümunəsi çalmaq üçündür:
## sürüşdürmənin hər kadrında fayl yazsaydıq, bir hərəkət yüzlərlə yazı olardı.
signal released(value: float)

## 0..1.
var value := 1.0

const TRACK_H := 10.0
const KNOB_R := 17.0
## Toxunuş sahəsi tutacaqdan BÖYÜKDÜR — çəkilən ölçü barmağın ölçüsü deyil.
const MIN_H := 44.0

var _dragging := false
var _touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.y = MIN_H


func set_value_silent(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1:
			_touch_index = t.index
			_dragging = true
			_set_from_x(t.position.x)
			accept_event()
		elif not t.pressed and t.index == _touch_index:
			_end()
			accept_event()

	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_set_from_x(d.position.x)
			accept_event()


## Barmaq zolaqdan KƏNARA çıxsa da sürüşdürmə davam edir.
##
## `_gui_input` yalnız Control-un üstündəki hadisələri görür; sürgü isə cəmi
## 44 piksel hündürdür və barmaq onu asanlıqla tərk edir. Buraxılış itsəydi,
## sürgü "yapışıb" qalar və növbəti toxunuş dəyəri gözlənilmədən dəyişərdi.
func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			# `_gui_input`-dakı mövqe artıq yerlidir, `_input`-dakı isə
			# viewport koordinatındadır — fərq çıxarılmalıdır.
			_set_from_x(d.position.x - global_position.x)
			accept_event()
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if not t.pressed and t.index == _touch_index:
			_end()
			accept_event()


func _set_from_x(x: float) -> void:
	var span := maxf(size.x - KNOB_R * 2.0, 1.0)
	var v := clampf((x - KNOB_R) / span, 0.0, 1.0)
	if is_equal_approx(v, value):
		return
	value = v
	queue_redraw()
	value_changed.emit(value)


func _end() -> void:
	_touch_index = -1
	_dragging = false
	released.emit(value)
	queue_redraw()


func _draw() -> void:
	var mid := size.y * 0.5
	var x0 := KNOB_R
	var x1 := size.x - KNOB_R
	var kx := lerpf(x0, x1, value)

	# Zolaq — boş hissə sönük, dolu hissə mikrob laymı.
	draw_line(Vector2(x0, mid), Vector2(x1, mid), Palette.PANEL_BORDER, TRACK_H, true)
	if value > 0.001:
		draw_line(Vector2(x0, mid), Vector2(kx, mid), Palette.GERM_COLORS[0], TRACK_H, true)

	# Tutacaq. Basılı olanda bir az böyüyür — toxunuşun cavabsız qalmadığı
	# menyunun hər yerində eyni dildə deyilir (bax [method MenuV2._squash]).
	var r := KNOB_R * (1.12 if _dragging else 1.0)
	draw_circle(Vector2(kx, mid), r + 2.0, Palette.OUTLINE)
	draw_circle(Vector2(kx, mid), r, Palette.GERM_COLORS[0] if value > 0.001 else Palette.TEXT_MUTED)
