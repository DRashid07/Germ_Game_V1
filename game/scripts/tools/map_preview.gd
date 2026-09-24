class_name MapPreview
extends Node2D
## Bütün Petri qabını yuxarıdan göstərən stend — düzümü tətbiq etmədən ƏVVƏL
## görmək üçün.
##
##   Godot_v4.7.2.exe --path game --resolution 900x900 -- \
##       --map --map-layout 1 --shot kadr.png --shot-delay 20
##
## Oyunda dünyanın yalnız ~1/4 eni görünür ([constant Const.VIEW_SPAN_BASE]),
## ona görə düzümün bütövlükdə necə oxunduğunu oyunun içindən qiymətləndirmək
## mümkün deyil. Burada isə qab tam görünür və üstünə oyunçunun BİR ekranda
## gördüyü sahə çərçivə kimi çəkilir — miqyası unutmamaq üçün.

## Qabın kənarı ilə ekran arasında nə qədər boşluq qalsın.
const MARGIN := 1.08

var layout := 0

var _cam: Camera2D
## Başlıq və əfsanə — AYRICA node-da, maneə sprite-larından yuxarı z-də.
var _legend: Node2D
var _floor: Texture2D
var _canopies: Array[Sprite2D] = []
var _vent_swirls: Array[Sprite2D] = []


func _ready() -> void:
	DishMap.layout = layout
	_floor = load("res://assets/sprites/dish_floor.svg")
	var bg := ColorRect.new()
	bg.color = Palette.BG_OUTER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_cam = Camera2D.new()
	add_child(_cam)
	_cam.make_current()

	_spawn_sprites()

	# Əfsanə sprite-lardan SONRA və daha yüksək z-də qurulur — bax
	# [method _spawn_sprites]-dəki izah.
	_legend = Node2D.new()
	_legend.z_index = 5
	add_child(_legend)
	_legend.draw.connect(_draw_legend)


## Maneələri OYUNDAKI sprite-larla çəkir.
##
## Əvvəl burada rəngli dairələr çəkilirdi. Rəng düzümü oxumağa kifayət edirdi,
## amma stendin ikinci işini görmürdü: sprite-ın ÖZÜNÜ yoxlamaq. İndi stend
## bir kadrda beş sprite-ın da həqiqi görkəmini göstərir — forma dilinin
## işlədiyini (keçilə bilən növ haşiyəsiz, bərk növ bütöv haşiyəli) yalnız
## belə yoxlamaq olar.
##
## Tekstura seçimi [method Arena._blob_texture]-dən gəlir, təkrar yazılmır:
## iki yerdə ayrı-ayrı saxlansaydı, biri dəyişəndə o biri səssizcə köhnəlirdi
## və stend oyunu YANLIŞ göstərərdi — stendin bütün dəyəri isə düz
## göstərməsindədir.
func _spawn_sprites() -> void:
	var tex := {}
	for name in Arena.BLOB_ORDER:
		tex[name] = load("res://assets/sprites/mucus_%s.svg" % name)
	tex["bush_top"] = load("res://assets/sprites/mucus_bush_top.svg")
	tex["vent_swirl"] = load("res://assets/sprites/mucus_vent_swirl.svg")
	for o in DishMap.obstacles():
		var spr := Sprite2D.new()
		spr.texture = tex[Arena._blob_texture(o)]
		spr.position = Vector2(o.x, o.y)
		spr.scale = Vector2.ONE * (o.z / Arena.BLOB_SPRITE_RADIUS)
		# Sprite-lar BAŞLIQ VƏ ƏFSANƏNİN ALTINDA qalır.
		#
		# Godot-da uşaqlar valideynin `_draw`-ından SONRA çəkilir, ona görə
		# `_draw`-dakı panel sprite-ların altında qalırdı: ARXİPELAQ düzümündə
		# "KOL" sözü tamamilə, "KÖVRƏK" isə yarısına qədər örtülürdü — halbuki
		# stendin bütün mənası əfsanəni oxumaqdır. Panel indi ayrıca uşaqdadır
		# (bax [method _build_legend]) və sıfırdan yuxarı z-də durur.
		spr.z_index = 0
		add_child(spr)

		# Oyundakı ikinci qatlar da stenddə olmalıdır: yoxsa kolun örtülməsi və
		# cərəyanın fırlanan içi yalnız practice kadrında yoxlanardı. Baza sprite
		# fırlanmır — işıq yuxarı-solda sabitdir.
		if int(o.w) == DishMap.Kind.BUSH:
			var top := Sprite2D.new()
			top.texture = tex["bush_top"]
			top.position = spr.position
			top.scale = spr.scale
			top.z_index = 1
			add_child(top)
			_canopies.append(top)
		elif int(o.w) == DishMap.Kind.VENT:
			var swirl := Sprite2D.new()
			swirl.texture = tex["vent_swirl"]
			swirl.position = spr.position
			swirl.scale = spr.scale
			swirl.z_index = 1
			swirl.set_meta("phase", fposmod(o.x * 0.013 + o.y * 0.021, TAU))
			add_child(swirl)
			_vent_swirls.append(swirl)


func _process(_delta: float) -> void:
	var vp := get_viewport_rect().size
	var k := minf(vp.x, vp.y) / (Const.WORLD_RADIUS * 2.0 * MARGIN)
	_cam.zoom = Vector2(k, k)
	var clock := Time.get_ticks_msec() * 0.001
	for i in _canopies.size():
		_canopies[i].rotation = sin(clock * 1.15 + float(i) * 1.73) * 0.030
		_canopies[i].skew = sin(clock * 0.83 + float(i) * 1.21) * 0.018
	for swirl in _vent_swirls:
		swirl.rotation = float(swirl.get_meta("phase", 0.0)) + clock * 0.72
	queue_redraw()
	if _legend != null:
		_legend.queue_redraw()


func _draw() -> void:
	var r := Const.WORLD_RADIUS
	draw_circle(Vector2.ZERO, r + 500.0, Palette.BG_VIGNETTE)
	draw_circle(Vector2.ZERO, r + 260.0, Palette.BG_OUTER)
	draw_texture_rect(_floor, Rect2(-r, -r, r * 2.0, r * 2.0), false)

	# Şəbəkə və 400 px-lik bevel — oyundakı eyni tək-batch quruluşu.
	var step := 200.0
	var lines := PackedVector2Array()
	var cols := PackedColorArray()
	var n := int(r / step)
	for i in range(-n, n + 1):
		var x := float(i) * step
		var h := sqrt(maxf(r * r - x * x, 0.0))
		var fade := 1.0 - pow(absf(x) / r, 1.6)
		var base := Color(Palette.GRID, 0.38 * fade)
		lines.append_array(PackedVector2Array([
			Vector2(x, -h), Vector2(x, h), Vector2(-h, x), Vector2(h, x)]))
		cols.append_array(PackedColorArray([base, base]))
		if i % 2 == 0:
			var hi := Color(Palette.DISH_EDGE, 0.20 * fade)
			var lo := Color(Palette.OUTLINE, 0.24 * fade)
			lines.append_array(PackedVector2Array([
				Vector2(x - 2.5, -h), Vector2(x - 2.5, h),
				Vector2(x + 2.5, -h), Vector2(x + 2.5, h),
				Vector2(-h, x - 2.5), Vector2(h, x - 2.5),
				Vector2(-h, x + 2.5), Vector2(h, x + 2.5)]))
			cols.append_array(PackedColorArray([hi, lo, hi, lo]))
	draw_multiline_colors(lines, cols, 3.0)
	for i in 3:
		draw_arc(Vector2.ZERO, r * (0.35 + 0.22 * float(i)), 0.0, TAU, 96,
			Color(Palette.GRID, 0.30), 26.0, true)

	# Maneələr — NÖVƏ görə rənglənir. Stendin bütün mənası budur: düzümə
	# baxanda "harada gizlənmək olar, harada divar sındırmaq olar" sualı
	# bir baxışda cavablanmalıdır.
	for o in DishMap.obstacles():
		var at := Vector2(o.x, o.y)
		var col := _kind_color(int(o.w))
		# Sprite-ın altındakı halqa: sprite-lar bir-birini örtəndə düzümün
		# həndəsəsi itir, halqa isə hər maneənin SƏRHƏDİNİ saxlayır.
		draw_circle(at, o.z, Color(col, 0.12))
		draw_arc(at, o.z, 0.0, TAU, 48, Color(col, 0.95), 4.0, true)

	# Qalxmış dodaq oyundakı eyni işıq oxu ilə göstərilir.
	draw_arc(Vector2.ZERO, r - 18.0, 0.0, TAU, 128,
		Color(Palette.OUTLINE, 0.48), 34.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 128, Palette.DISH_EDGE, 17.0, true)
	var light_a := Palette.LIGHT_DIR.angle()
	var shadow_a := (-Palette.LIGHT_DIR).angle()
	draw_arc(Vector2.ZERO, r - 4.0, light_a - 0.92, light_a + 0.92, 48,
		Color(Palette.TEXT, 0.38), 5.0, true)
	draw_arc(Vector2.ZERO, r + 5.0, shadow_a - 0.92, shadow_a + 0.92, 48,
		Color(Palette.OUTLINE, 0.78), 9.0, true)

	# Oyunçunun BİR ekranda gördüyü sahə — miqyas üçün.
	var w := Const.VIEW_SPAN_BASE
	var h2 := w * 16.0 / 9.0
	draw_rect(Rect2(Vector2(-w * 0.5, -h2 * 0.5), Vector2(w, h2)),
		Color(Palette.TEXT, 0.55), false, 5.0)


## Başlıq və əfsanə. Sprite-lardan yuxarı z-də olan AYRI node çəkir, ona görə
## düzüm nə olursa olsun yazı örtülmür (bax [method _spawn_sprites]).
func _draw_legend() -> void:
	var r := Const.WORLD_RADIUS
	# Yazıların arxasına panel — maneələr düzümdən asılı olaraq bura düşür.
	_legend.draw_rect(Rect2(Vector2(-r * 1.02, -r * 1.02), Vector2(r * 0.86, r * 0.72)),
		Color(Palette.BG_OUTER, 0.92))

	var label := "%d — %s" % [layout, DishMap.layout_name(layout)]
	var font := ThemeDB.fallback_font
	_legend.draw_string(font, Vector2(-r * 0.95, -r * 0.86), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 120, Palette.TEXT)
	_legend.draw_string(font, Vector2(-r * 0.95, -r * 0.72),
		"%d maneə · çərçivə = bir ekran" % DishMap.obstacles().size(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Palette.TEXT_MUTED)

	# Növlərin açarı.
	var y := -r * 0.58
	for kind in [DishMap.Kind.MUCUS, DishMap.Kind.BUSH, DishMap.Kind.BRITTLE,
			DishMap.Kind.VENT]:
		var col := _kind_color(kind)
		_legend.draw_circle(Vector2(-r * 0.90, y - 22.0), 26.0, Color(col, 0.35))
		_legend.draw_arc(Vector2(-r * 0.90, y - 22.0), 26.0, 0.0, TAU, 24, col, 4.0, true)
		_legend.draw_string(font, Vector2(-r * 0.80, y), DishMap.kind_name(kind),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 64, col)
		y += r * 0.11


## Növün rəngi. Oyunun özündə növ FORMA ilə oxunur (bax [const
## Arena.BLOB_TEXTURE]) — burada isə rəng işlədilir, çünki stend yuxarıdan
## baxışdır və orada forma seçilmir.
static func _kind_color(kind: int) -> Color:
	match kind:
		DishMap.Kind.BUSH:
			return Palette.BUSH
		DishMap.Kind.BRITTLE:
			return Palette.BRITTLE
		DishMap.Kind.VENT:
			return Palette.VENT
		_:
			return Palette.DISH_EDGE
