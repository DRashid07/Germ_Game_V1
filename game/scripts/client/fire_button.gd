class_name FireButton
extends Control
## Top atma düyməsi — sağ baş barmaq üçün.
##
## Nişan almaq yoxdur: mikrob getdiyi tərəfə atır ([Arena._sample_input]).
## Düymə yalnız "indi at" deyir, istiqaməti sol joystick müəyyən edir.
##
## Düymə İKİ vəziyyəti göstərir və hər ikisi oyunçu üçün həyatidir:
##   • halqa — növbəti topun hazır olmasına qalan vaxt
##   • sönük hal — top sayı [constant Const.FIRE_MIN_BALLS]-dan azdır, atmaq olmaz
##     (əks halda oyunçu öz atəşi ilə özünü acından partladardı)
##
## Toxunuşun BAŞLANĞICI [method _gui_input] ilə tutulur (yalnız düymənin üstündə),
## BURAXILMASI isə [method _input] ilə (barmaq düymədən kənara sürüşüb qalxsa belə).
## Əks halda buraxılma hadisəsi itə bilər və düymə "basılı" ilişib qalar —
## bu isə dayanmadan atəş deməkdir.

signal fired    ## Basılan an; qısa toxunuş da bir top verməlidir

@export var radius := 84.0

var held := false

var _touch_index := -1
var _cooldown_ratio := 0.0   ## 1 = təzəcə atıb, 0 = növbətiyə hazır
var _has_ammo := true
var _color := Palette.TEXT


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


## Mikrobun rəngi — düymə oyunçunun öz rəngini daşıyır.
func set_germ_color(c: Color) -> void:
	_color = c
	queue_redraw()


## [param ratio] atəş dövrünün qalan hissəsi (0..1).
## [param has_ammo] top sayı atmağa yetirmi?
func set_state(ratio: float, has_ammo: bool) -> void:
	var v := clampf(ratio, 0.0, 1.0)
	if is_equal_approx(v, _cooldown_ratio) and has_ammo == _has_ammo:
		return
	_cooldown_ratio = v
	_has_ammo = has_ammo
	queue_redraw()


## Xarici səbəbdən (mikrob partladı, bağlantı kəsildi) idarəni buraxmaq lazım olanda.
func cancel() -> void:
	_touch_index = -1
	held = false
	queue_redraw()


# ---------------------------------------------------------------- giriş

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1:
			_touch_index = t.index
			held = true
			fired.emit()
			queue_redraw()
			accept_event()


func _input(event: InputEvent) -> void:
	if _touch_index == -1:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if not t.pressed and t.index == _touch_index:
			cancel()


# ---------------------------------------------------------------- görüntü

func _draw() -> void:
	var c := size * 0.5
	var r := radius
	var ready := _cooldown_ratio <= 0.001 and _has_ammo
	var accent := _color if _has_ammo else Palette.DANGER

	# Kölgə — düymə səthdən qalxıq görünsün.
	draw_circle(c + Vector2(0, 5), r, Color(Palette.OUTLINE, 0.45))

	# Baza: joystick sprite-ı ilə eyni məntiq — tünd disk, canlı halqa.
	draw_circle(c, r, Color(Palette.BG_OUTER, 0.72))
	draw_arc(c, r, 0, TAU, 48, Color(accent, 0.95 if held else 0.6), 5.0, true)

	draw_circle(c, r * 0.72, Color(Palette.PANEL, 0.62 if held else 0.45))

	# Atəş dövrü: halqa boşaldıqca növbəti top hazırlanır.
	if _cooldown_ratio > 0.001:
		draw_arc(c, r * 0.88, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _cooldown_ratio),
			32, Color(Palette.WARNING, 0.85), 5.0, true)

	# Nişan: mərkəzdə bir top və onun uçuş izi.
	var glyph := Color(accent, 0.95 if ready else 0.4)
	draw_circle(c, r * 0.20, glyph)
	var trail := PackedVector2Array()
	for i in 3:
		var d := r * (0.34 + 0.16 * float(i))
		trail.push_back(c + Vector2(d, 0))
		trail.push_back(c + Vector2(d + r * 0.10, 0))
	draw_multiline(trail, Color(glyph, glyph.a * 0.7), 6.0)

	# Sursat bitibsə üstündən xətt: "hazırda atmaq olmaz".
	if not _has_ammo:
		var d := Vector2(r * 0.5, r * 0.5)
		draw_line(c - d, c + d, Color(Palette.DANGER, 0.9), 7.0, true)
