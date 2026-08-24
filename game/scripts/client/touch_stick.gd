class_name TouchStick
extends Control
## Üzən (floating) virtual joystick.
##
## Sabit joystick-dən fərqli olaraq baza barmağın toxunduğu yerdə yaranır —
## oyunçu ekrana baxmadan, baş barmağını hara qoysa ora idarə mərkəzi olur.
## Mobil atıcı oyunlarda standart həll budur.
##
## Oyunda yalnız hərəkət üçün işlənir (sol yarı) — top atmaq ayrıca düymədədir,
## bax: [FireButton]. [signal released] siqnalı hazırda istifadə olunmur.

signal moved(value: Vector2)
signal released(value: Vector2)

@export var max_radius := 110.0
@export var dead_zone := 0.18
@export var base_texture: Texture2D
@export var knob_texture: Texture2D
@export var tint := Color(1, 1, 1, 0.85)

var value := Vector2.ZERO
var active := false

var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1:
			_begin(t.index, t.position)
			accept_event()
		elif not t.pressed and t.index == _touch_index:
			_end()
			accept_event()

	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			_update(d.position)
			accept_event()


func _begin(index: int, pos: Vector2) -> void:
	_touch_index = index
	_origin = pos
	_knob = pos
	active = true
	value = Vector2.ZERO
	queue_redraw()


func _update(pos: Vector2) -> void:
	var delta := pos - _origin
	# Barmaq bazadan uzağa gedəndə bazanı özü ilə sürüyür — uzun sürüşmələrdə
	# idarə itmir, bu da kiçik ekranda vacibdir.
	if delta.length() > max_radius:
		_origin = pos - delta.normalized() * max_radius
		delta = pos - _origin
	_knob = pos

	var raw := delta / max_radius
	var mag := raw.length()
	if mag < dead_zone:
		value = Vector2.ZERO
	else:
		# Ölü zonanı çıxıb qalan hissəni 0..1-ə yenidən paylayırıq ki,
		# ölü zonanın kənarında sürət sıçramasın.
		value = raw.normalized() * minf((mag - dead_zone) / (1.0 - dead_zone), 1.0)

	moved.emit(value)
	queue_redraw()


func _end() -> void:
	var final := value
	_touch_index = -1
	active = false
	value = Vector2.ZERO
	released.emit(final)
	moved.emit(Vector2.ZERO)
	queue_redraw()


## Xarici səbəbdən (matç bitdi, pauza) idarəni buraxmaq lazım olanda.
func cancel() -> void:
	_touch_index = -1
	active = false
	value = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	if base_texture != null:
		var bs := base_texture.get_size()
		draw_texture_rect(base_texture, Rect2(_origin - bs * 0.5, bs), false, tint)
	else:
		draw_circle(_origin, max_radius, Color(1, 1, 1, 0.10))
		draw_arc(_origin, max_radius, 0, TAU, 48, Color(1, 1, 1, 0.30), 3.0, true)

	if knob_texture != null:
		var ks := knob_texture.get_size()
		draw_texture_rect(knob_texture, Rect2(_knob - ks * 0.5, ks), false, tint)
	else:
		draw_circle(_knob, max_radius * 0.38, Color(1, 1, 1, 0.35))
