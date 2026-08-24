class_name GermVisual
extends Node2D
## Ekranda bir mikrob: membran, içindəki toplar, doluluq halqası, ad.
##
## Burada heç bir oyun məntiqi yoxdur — yalnız verilən vəziyyəti çəkir.
## Bütün qərarlar serverdə, bütün proqnoz [Sim]-dədir.
##
## Niyə sprite deyil, kodla çəkilir: mikrobun ölçüsü TUTUMDAN, içindəki
## topların sayı isə MÖVCUD SAYDAN asılıdır. İkisi də oyun boyu dəyişir,
## ona görə hazır şəkil uyğun deyil — hər kadr yenidən qurulur.
##
## Oyunçu bir baxışda üç şeyi görməlidir:
##   1. Nə qədər doluyam        → halqa və membranın rəngi
##   2. Rəqib partlamağa yaxındırmı → onun halqası qırmızıya keçir
##   3. Kim mənəm               → öz mikrobunun altında fokus halqası

## Membran çoxbucaqlısının nöqtə sayı. 24 kifayətdir: kiçik ekranda fərq
## görünmür, amma çəkiliş yükü iki dəfə azdır.
const MEMBRANE_POINTS := 24
const NAME_OFFSET := 22.0

var color_index := 0
var germ_name := ""
var is_local := false

var balls := Const.START_BALLS
var capacity := Const.START_CAPACITY
var aim := 0.0
var alive := true
var safe := false

var _base := Color.WHITE
var _light := Color.WHITE
var _shadow := Color.BLACK
var _label: Label
var _t := 0.0
## Doluluq göstəricisi ani sıçramır — göz üçün yumşaq keçid.
var _shown_fill := 0.0


func setup(p_color: int, p_name: String, p_is_local: bool) -> void:
	color_index = p_color
	germ_name = p_name
	is_local = p_is_local
	_base = Palette.germ_color(p_color)
	_light = Palette.germ_light(p_color)
	_shadow = Palette.germ_shadow(p_color)

	_label = Label.new()
	_label.text = p_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 24)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Palette.TEXT if p_is_local else Palette.TEXT_MUTED)
	_label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# Öz mikrobun həmişə başqalarının üstündə çəkilir — itirməmək üçün.
	z_index = 2 if is_local else 1
	# Hər mikrob öz fazasından başlayır ki, hamısı eyni ritmdə titrəməsin.
	_t = float(p_color) * 1.37


func apply(p_pos: Vector2, p_aim: float, p_balls: int, p_capacity: int,
		p_safe: bool, p_alive: bool) -> void:
	position = p_pos
	aim = p_aim
	balls = p_balls
	capacity = p_capacity
	safe = p_safe
	if p_alive != alive:
		alive = p_alive
		visible = alive
	_place_label()


func _place_label() -> void:
	if _label == null:
		return
	var r := Const.germ_radius(capacity)
	_label.position = Vector2(-100.0, -r - NAME_OFFSET - 18.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var target := clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	_shown_fill = move_toward(_shown_fill, target, delta * 2.5)
	queue_redraw()


## Çəkiliş sırası qəsdən "əvvəlcə bütün dolu formalar, sonra bütün xətlər"
## şəklindədir. Godot kanvası eyni növ ardıcıl əmrləri bir çəkiliş çağırışına
## yığır — sıra qarışsa, hər mikrob 15-20 ayrıca çağırış olur və mobil GPU-da
## əsas məhdudiyyət məhz çağırış sayıdır.
func _draw() -> void:
	if not alive:
		return

	var r := Const.germ_radius(capacity)
	var fill := _shown_fill
	# Dolduqca membran daha çox gərilir — partlamağa yaxın olduğu buradan görünür.
	var strain := clampf((fill - 0.6) / 0.4, 0.0, 1.0)
	var ring := _membrane(r, 0.030 + 0.055 * strain, 2.2 + 3.4 * strain)

	# ---- dolu formalar ----
	# Kölgə — mikrob döşəmədən qopuq görünsün.
	draw_circle(Vector2(0, 4), r * 1.02, Color(Palette.OUTLINE, 0.35))
	# Membranın içi: rəngin şəffaf variantı, gərginlikdə qırmızıya çalır.
	draw_colored_polygon(ring, Color(_base.lerp(Palette.DANGER, strain * 0.45), 0.30))
	# İrəli baxan çıxıntı (psevdopodiya) — hansı tərəfə atacağını göstərir.
	draw_circle(Vector2.from_angle(aim) * (r + 5.0), maxf(r * 0.22, 5.0), Color(_light, 0.85))
	_draw_inner_balls(r)

	# ---- xətlər ----
	var edge := PackedVector2Array(ring)
	edge.push_back(ring[0])
	draw_polyline(edge, Color(_light, 0.95), 3.0, true)
	_draw_fill_ring(r, fill)

	if safe:
		# Doğuş qalxanı — fırlanan kəsik halqa. Atəş açan kimi sönür.
		draw_arc(Vector2.ZERO, r + 12.0, _t * 2.0, _t * 2.0 + PI * 1.4, 24,
			Color(Palette.TEXT, 0.55), 3.0, true)

	if is_local:
		draw_arc(Vector2.ZERO, r + 9.0, 0.0, TAU, 36, Color(Palette.FOCUS, 0.85), 2.5, true)


## Titrəyən membran konturu. İki fərqli tezlikli sinus üst-üstə düşür ki,
## hərəkət mexaniki görünməsin — canlı orqanizm hissi buradan gəlir.
func _membrane(r: float, wobble: float, speed: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in MEMBRANE_POINTS:
		var a := TAU * float(i) / float(MEMBRANE_POINTS)
		var m := 1.0 \
			+ wobble * sin(_t * speed + a * 3.0) \
			+ wobble * 0.6 * sin(_t * speed * 0.7 + a * 5.0)
		pts.push_back(Vector2.from_angle(a) * r * m)
	return pts


## İçindəki toplar — oyunun ƏSAS oxunma vasitəsi.
##
## Nöqtələr "günəbaxan" (phyllotaxis) düzümü ilə paylanır: qızıl bucaq
## dairəni bərabər doldurur, ona görə say dəyişəndə düzüm sıçramır,
## sadəcə bir top əlavə olunur.
func _draw_inner_balls(r: float) -> void:
	var n := clampi(balls, 0, 40)
	if n <= 0:
		return
	var inner := r * 0.66
	var dot := clampf(inner / sqrt(float(n)) * 0.72, 2.2, 7.0)

	# İşıq nöqtəsi yalnız top kifayət qədər böyükdürsə çəkilir: kiçik topda
	# onsuz da görünmür, çəkiliş çağırışını isə iki dəfə artırır.
	var lit := dot >= 4.0
	for i in n:
		var a := float(i) * 2.39996 + _t * 0.35
		var d := inner * sqrt((float(i) + 0.5) / float(n))
		var jitter := Vector2.from_angle(_t * 1.8 + float(i)) * (dot * 0.18)
		var p := Vector2.from_angle(a) * d + jitter
		draw_circle(p, dot, Color(_light, 0.95))
		if lit:
			draw_circle(p - Vector2(dot * 0.3, dot * 0.3), dot * 0.35, Color(Palette.TEXT, 0.8))


## Doluluq halqası: membranın ətrafında dolan qövs.
## Rəng qaydanı bir baxışda öyrədir — sarı = ac, yaşıl = sağlam, qırmızı = partlayır.
func _draw_fill_ring(r: float, fill: float) -> void:
	var rr := r + 5.0
	draw_arc(Vector2.ZERO, rr, 0.0, TAU, 32, Color(Palette.OUTLINE, 0.55), 4.0, true)
	if fill <= 0.0:
		return
	var col := Palette.fill_color(fill)
	draw_arc(Vector2.ZERO, rr, -PI * 0.5, -PI * 0.5 + TAU * fill, 32, col, 4.0, true)
