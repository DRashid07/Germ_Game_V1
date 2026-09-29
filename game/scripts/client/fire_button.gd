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
var _press_scale := 1.0
var _press_tween: Tween = null
## Atəş dövrünün halqası — AYRI canvas item-dir (bax [method _draw_ring]).
var _ring: Control


# Halqa `_init`-də yaranır, `_ready`-də yox: testlər düyməni ağaca qoşmadan
# işlədir və [method cancel] halqanı da yeniləyir.
func _init() -> void:
	_ring = Control.new()
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ring.draw.connect(_draw_ring)
	add_child(_ring)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


## Mikrobun rəngi — düymə oyunçunun öz rəngini daşıyır.
func set_germ_color(c: Color) -> void:
	_color = c
	queue_redraw()


## [param ratio] atəş dövrünün qalan hissəsi (0..1).
## [param has_ammo] top sayı atmağa yetirmi?
##
## Atəşdən sonra dövr bir saniyə boyu HƏR TICK dəyişir. Əvvəl bu, bütün
## düyməni (kölgə, üç disk, halqa, nişan) təzədən çəkdirirdi — zəif telefonda
## (6.5× yavaş CPU) kadra ~0.8 ms. İndi yalnız halqa yenilənir; düymənin
## qalanı nişanın parlaqlığı (hazır/deyil) və ya sursat dəyişəndə çəkilir.
func set_state(ratio: float, has_ammo: bool) -> void:
	var v := clampf(ratio, 0.0, 1.0)
	var was_ready := _is_ready()
	var had_ammo := _has_ammo
	if not is_equal_approx(v, _cooldown_ratio):
		_cooldown_ratio = v
		_ring.queue_redraw()
	_has_ammo = has_ammo
	if has_ammo != had_ammo or _is_ready() != was_ready:
		queue_redraw()


func _is_ready() -> bool:
	return _cooldown_ratio <= 0.001 and _has_ammo


## Xarici səbəbdən (mikrob partladı, bağlantı kəsildi) idarəni buraxmaq lazım olanda.
func cancel() -> void:
	_touch_index = -1
	held = false
	_animate_press(false)
	queue_redraw()
	_ring.queue_redraw()


# ---------------------------------------------------------------- giriş

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed and _touch_index == -1:
			_touch_index = t.index
			held = true
			_animate_press(true)
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


## Basış 0.94-ə tez oturur, buraxılış back-out ilə bir az aşırıb yerinə gəlir.
## Rəng dəyişməsi tək qalsaydı barmağın altındakı cavab görünmürdü; node-un
## öz `scale`-ı isə anchor/pivot səbəbindən düyməni küncə sürüşdürürdü, ona görə
## yalnız çəkilən radius miqyaslanır.
func _animate_press(down: bool) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	var step := _press_tween.tween_method(func(v: float) -> void:
		_press_scale = v
		queue_redraw()
		_ring.queue_redraw(), _press_scale, 0.94 if down else 1.0, 0.06 if down else 0.16)
	if not down:
		step.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- görüntü

func _draw() -> void:
	var c := size * 0.5
	var r := radius * _press_scale
	var ready := _is_ready()
	var accent := _color if _has_ammo else Palette.DANGER

	# Kölgə — düymə səthdən qalxıq görünsün.
	draw_circle(c + Vector2(0, 5), r, Color(Palette.OUTLINE, 0.45))

	# Baza: joystick sprite-ı ilə eyni məntiq — tünd disk, canlı halqa.
	draw_circle(c, r, Color(Palette.BG_OUTER, 0.72))
	draw_arc(c, r, 0, TAU, 48, Color(accent, 0.95 if held else 0.6), 5.0, true)

	draw_circle(c, r * 0.72, Color(Palette.PANEL, 0.62 if held else 0.45))

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


## Atəş dövrü: halqa boşaldıqca növbəti top hazırlanır.
##
## Düymənin üstündə ayrı qatda çəkilir, amma heç nəyi örtmür: halqa 0.85–0.91 r
## aralığındadır, daxili disk 0.72 r-ə, nişanın izi 0.70 r-ə qədərdir.
func _draw_ring() -> void:
	if _cooldown_ratio <= 0.001:
		return
	var c := size * 0.5
	var r := radius * _press_scale
	_ring.draw_arc(c, r * 0.88, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _cooldown_ratio),
		32, Color(Palette.WARNING, 0.85), 5.0, true)
