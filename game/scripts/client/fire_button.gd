class_name FireButton
extends Control
## Top atma düyməsi — sağ baş barmaq üçün. Brawl Stars-ın atəş joystickidir.
##
## İki atəş yolu var:
##   • QISA TOXUNUŞ — [signal tapped]: avtomatik nişan, top ən yaxın rəqibə
##     gedir, amma dəqiq deyil (bax [AutoAim]).
##   • BASILI SAXLA və SÜRÜŞDÜR — düymə joystickə çevrilir, dünyada nişan xətti
##     çəkilir ([AimGuide]); barmaq qalxanda [signal aimed] həmin bucaqla atır.
##     Barmaq ölü zonaya QAYIDIB qalxsa, atəş LƏĞV olunur — Brawl Stars-dakı
##     kimi, fikrini dəyişən oyunçunun çıxış yolu budur.
##
## Atəş barmaq QALXANDA açılır, basılanda yox: basılan anda oyunçunun
## toxunmaq, yoxsa nişan almaq istədiyi hələ bilinmir. Basılı saxlamaq artıq
## dayanmadan atəş DEYİL — əvvəlki "basılı saxla, saniyədə bir at" qaydası
## nişanla toqquşurdu (BOŞLUQ düyməsi masaüstündə hələ belə işləyir).
##
## Düymə İKİ vəziyyəti göstərir və hər ikisi oyunçu üçün həyatidir:
##   • halqa — növbəti topun hazır olmasına qalan vaxt
##   • sönük hal — top sayı [constant Const.FIRE_MIN_BALLS]-dan azdır, atmaq olmaz
##     (əks halda oyunçu öz atəşi ilə özünü acından partladardı)
##
## Toxunuşun BAŞLANĞICI [method _gui_input] ilə tutulur (yalnız düymənin üstündə),
## SÜRÜŞMƏSİ və BURAXILMASI isə [method _input] ilə (barmaq düymədən kənara
## çıxsa belə). Əks halda buraxılma hadisəsi itə bilər və düymə "basılı"
## ilişib qalar.

signal tapped                  ## Nişansız buraxıldı — avtomatik nişanla at
signal aimed(angle: float)     ## Nişanla buraxıldı — bu bucaqla at

## Ölü zona, radiusun payı. Ondan qısa sürüşmə toxunuşdur: baş barmaq
## toxunanda da bir neçə piksel titrəyir və o, nişan sayılmamalıdır.
const DEAD := 0.28
## Düymənin başı mərkəzdən ən çox bu qədər (radiusun payı) uzaqlaşır.
const TRAVEL := 0.50
## Nişan başı və atəş ikonu — Codex ilə çəkilib, AĞ-BOZ: oyunçunun rəngi ilə
## vurularaq boyanır (bax design/menu_art/README.md).
const ICON := preload("res://assets/ui/hud_fire.png")
const KNOB := preload("res://assets/ui/hud_aim_knob.png")

@export var radius := 84.0

## Barmaq düymənin üstündədir (toxunuş başlayıb, hələ qalxmayıb).
var held := false
## Barmaq indi ölü zonadan KƏNARDADIR — buraxılsa nişanla atılacaq.
var aiming := false
## Nişanın istiqaməti (vahid vektor); yalnız [member aiming] ikən mənalıdır.
var aim_dir := Vector2.RIGHT

var _touch_index := -1
## Toxunuşun başladığı yer (yerli koordinat). Nişan ondan ölçülür, düymənin
## mərkəzindən yox: kənara toxunan barmaq dərhal "nişan" saymasın.
var _origin := Vector2.ZERO
var _drag := Vector2.ZERO
## Bu toxunuşda barmaq ölü zonadan ən azı bir dəfə çıxıb.
var _armed := false
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
	# Ikonlar 256 px-dir, ekranda ~90 px: mipmap-sız kiçiltmə konturu dişləyir.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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


## Barmaq nişandan sonra ölü zonaya qayıdıb — buraxılsa heç nə atılmayacaq.
func is_cancelling() -> bool:
	return held and _armed and not aiming


## Xarici səbəbdən (mikrob partladı, bağlantı kəsildi) idarəni buraxmaq lazım olanda.
## Heç nə atılmır.
func cancel() -> void:
	_touch_index = -1
	held = false
	aiming = false
	_armed = false
	_drag = Vector2.ZERO
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
			_origin = t.position
			_drag = Vector2.ZERO
			_animate_press(true)
			queue_redraw()
			accept_event()


func _input(event: InputEvent) -> void:
	if _touch_index == -1:
		return
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_index:
			# `_input` hadisəsi ekran koordinatındadır; HUD isə miqyaslı qatdadır.
			# Ağacdan kənarda (testlərdə) hadisə onsuz da yerlidir.
			if is_inside_tree():
				d = make_input_local(d) as InputEventScreenDrag
			_drag_to(d.position)
	elif event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if not t.pressed and t.index == _touch_index:
			_release()


## Barmaq [param at]-dadır (yerli koordinat).
func _drag_to(at: Vector2) -> void:
	_drag = at - _origin
	aiming = _drag.length() > radius * DEAD
	if aiming:
		_armed = true
		aim_dir = _drag.normalized()
	queue_redraw()


func _release() -> void:
	var shot := aiming
	var dir := aim_dir
	var tap := not _armed
	cancel()
	if shot:
		aimed.emit(dir.angle())
	elif tap:
		tapped.emit()


## Basış 0.94-ə tez oturur, buraxılış back-out ilə bir az aşırıb yerinə gəlir.
## Rəng dəyişməsi tək qalsaydı barmağın altındakı cavab görünmürdü; node-un
## öz `scale`-ı isə anchor/pivot səbəbindən düyməni küncə sürüşdürürdü, ona görə
## yalnız çəkilən radius miqyaslanır.
func _animate_press(down: bool) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	if not is_inside_tree():
		_press_scale = 0.94 if down else 1.0
		return
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
	#
	# Üç disk ardıcıl çəkilir — bir çəkiliş çağırışıdır (bax [BatchDraw]). Daxili
	# disk (0.72 r) halqaya (r ± 2.5) toxunmur, ona görə halqadan ƏVVƏL çəkilməsi
	# görüntünü dəyişmir.
	BatchDraw.disc(self, c + Vector2(0, 5), r, Color(Palette.OUTLINE, 0.45))

	# Baza: joystick sprite-ı ilə eyni məntiq — tünd disk, canlı halqa.
	BatchDraw.disc(self, c, r, Color(Palette.BG_OUTER, 0.72))
	BatchDraw.disc(self, c, r * 0.72, Color(Palette.PANEL, 0.62 if held else 0.45))

	# Ləğv halında halqa da solur — yalnız baş solanda QA onu gözdən qaçırdı.
	var rim := Color(Palette.TEXT_MUTED, 0.5) if is_cancelling() \
		else Color(accent, 0.95 if held else 0.6)
	draw_arc(c, r, 0, TAU, 48, rim, 5.0, true)

	if held:
		_draw_knob(c, r, accent, ready)
	else:
		# Nişan: Codex-in ikonu — uçan top və onun izi. Ağ-boz çəkilib, burada
		# oyunçunun rəngi ilə boyanır; hazır deyilsə sönür.
		_draw_fit(ICON, c, r * 1.04, Color(accent, 0.95 if ready else 0.4))

	# Sursat bitibsə üstündən xətt: "hazırda atmaq olmaz".
	if not _has_ammo:
		var d := Vector2(r * 0.5, r * 0.5)
		draw_line(c - d, c + d, Color(Palette.DANGER, 0.9), 7.0, true)


## Basılı düymənin başı — barmağın ardınca gedir.
##
## Nişan alanda halqanın o tərəfi parlayır: baş barmağın altında itən başın
## əvəzinə istiqaməti kənardan da oxumaq olur. Ləğv halında baş solğundur və
## mərkəzdədir — "buraxsan, heç nə olmayacaq".
func _draw_knob(c: Vector2, r: float, accent: Color, ready: bool) -> void:
	var off := Vector2.ZERO
	var tint := Color(accent, 0.95 if ready else 0.55)
	if aiming:
		off = _drag.limit_length(r * TRAVEL)
		var a := aim_dir.angle()
		draw_arc(c, r, a - 0.42, a + 0.42, 14, Color(Color.WHITE, 0.85), 7.0, true)
	elif is_cancelling():
		tint = Color(Palette.TEXT_MUTED, 0.6)
	_draw_fit(KNOB, c + off, r * 0.86, tint)


## Teksturanı [param at] mərkəzində, uzun tərəfi [param side] olmaqla, nisbətini
## saxlayaraq çəkir — Codex-in şəkilləri kəsiləndən sonra kvadrat deyil.
func _draw_fit(tex: Texture2D, at: Vector2, side: float, tint: Color) -> void:
	var ts := tex.get_size()
	var sz := ts * (side / maxf(ts.x, ts.y))
	draw_texture_rect(tex, Rect2(at - sz * 0.5, sz), false, tint)


## Atəş dövrü: halqa boşaldıqca növbəti top hazırlanır.
##
## Düymənin üstündə ayrı qatda çəkilir, amma heç nəyi örtmür: halqa 0.85–0.91 r
## aralığındadır, daxili disk 0.72 r-ə, ikon 0.52 r-ə qədərdir.
func _draw_ring() -> void:
	if _cooldown_ratio <= 0.001:
		return
	var c := size * 0.5
	var r := radius * _press_scale
	_ring.draw_arc(c, r * 0.88, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _cooldown_ratio),
		32, Color(Palette.WARNING, 0.85), 5.0, true)
