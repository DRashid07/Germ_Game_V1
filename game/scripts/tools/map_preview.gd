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
var _canopies: Array[Sprite2D] = []
var _vent_swirls: Array[Sprite2D] = []
var _backdrop: ArrayMesh


## Qatlar oyundakı kimidir (bax [method Arena._build_world]): qabın bayırı bu
## node-un öz `_draw`-ında, sonra şeyderli döşəmə, şəbəkə və növ halqaları,
## şimal divarı, maneələr, tac və burulğan, cənub dodağı, ən üstdə əfsanə.
func _ready() -> void:
	DishMap.layout = layout
	var bg := ColorRect.new()
	bg.color = Palette.BG_OUTER
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_cam = Camera2D.new()
	add_child(_cam)
	_cam.make_current()

	_backdrop = MapKit.backdrop_mesh()

	var ground := Node2D.new()
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/map_floor.gdshader")
	mat.set_shader_parameter("detail", MapKit.detail_texture())
	mat.set_shader_parameter("detail_world", MapKit.detail_world())
	ground.material = mat
	add_child(ground)
	# Teksturalar lambdada tutulur: çəkiliş əmri yalnız RID saxlayır, istinadı
	# heç kim tutmasa tekstura azad olunur və ağ çıxır (bax [method MapKit.release]).
	var floor_tex := MapKit.floor_texture()
	ground.draw.connect(func() -> void:
		var r := Const.WORLD_RADIUS
		ground.draw_texture_rect(floor_tex, Rect2(-r, -r, r * 2.0, r * 2.0), false))

	var marks := Node2D.new()
	add_child(marks)
	marks.draw.connect(_draw_marks.bind(marks))

	var rim := Node2D.new()
	rim.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(rim)
	var rim_mesh := MapKit.rim_mesh()
	var rim_tex := MapKit.rim_texture()
	rim.draw.connect(func() -> void: rim.draw_mesh(rim_mesh, rim_tex))

	_spawn_sprites()

	var lip := Node2D.new()
	lip.z_index = 2
	add_child(lip)
	var lip_mesh := MapKit.lip_mesh()
	lip.draw.connect(func() -> void: lip.draw_mesh(lip_mesh, null))

	# Əfsanə sprite-lardan SONRA və daha yüksək z-də qurulur — bax
	# [method _spawn_sprites]-dəki izah.
	_legend = Node2D.new()
	_legend.z_index = 5
	add_child(_legend)
	_legend.draw.connect(_draw_legend)


## Maneələri OYUNDAKI atlas hüceyrələri ilə çəkir.
##
## Əvvəl burada rəngli dairələr çəkilirdi. Rəng düzümü oxumağa kifayət edirdi,
## amma stendin ikinci işini görmürdü: sprite-ın ÖZÜNÜ yoxlamaq. İndi stend
## bir kadrda bütün hüceyrələrin həqiqi görkəmini göstərir — forma dilinin
## işlədiyini (keçilə bilən növ haşiyəsiz, bərk növ bütöv haşiyəli) yalnız
## belə yoxlamaq olar.
##
## Hüceyrə seçimi [method MapKit.base_name]-dən gəlir, təkrar yazılmır: iki
## yerdə ayrı-ayrı saxlansaydı, biri dəyişəndə o biri səssizcə köhnəlirdi və
## stend oyunu YANLIŞ göstərərdi — stendin bütün dəyəri isə düz göstərməsindədir.
func _spawn_sprites() -> void:
	var list := DishMap.obstacles()
	var holder := Node2D.new()
	holder.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(holder)
	# Oyundakı sıra: kölgələr, yastı növlər, burulğan, sonra qalxan gövdələr
	# şimaldan cənuba (bax [method Arena._spawn_obstacles]).
	for o in list:
		if MapKit.casts_shadow(int(o.w)):
			_add(holder, MapKit.cell_name("shadow", o.z), o)
	for o in list:
		if not DishMap.blocks_germ(int(o.w)):
			_add(holder, MapKit.cell_name(MapKit.base_name(o), o.z), o)
	for o in list:
		if int(o.w) == DishMap.Kind.VENT:
			var swirl := _add(holder, MapKit.cell_name("vent_swirl", o.z), o)
			swirl.set_meta("phase", fposmod(o.x * 0.013 + o.y * 0.021, TAU))
			_vent_swirls.append(swirl)
	var raised := []
	for o in list:
		if DishMap.blocks_germ(int(o.w)):
			raised.append(o)
	raised.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.y < b.y)
	for o in raised:
		_add(holder, MapKit.cell_name(MapKit.base_name(o), o.z), o)

	# Oyundakı ikinci qat — kolun tacı — stenddə də olmalıdır: yoxsa kolun
	# örtülməsi yalnız practice kadrında yoxlanardı. Sprite-lar BAŞLIQ VƏ
	# ƏFSANƏNİN ALTINDA qalır: əvvəl `_draw`-dakı panel sprite-ların altında
	# qalırdı və ARXİPELAQ-da "KOL" sözü tamamilə örtülürdü.
	var tops := Node2D.new()
	tops.z_index = 1
	tops.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(tops)
	for o in list:
		if int(o.w) == DishMap.Kind.BUSH:
			_canopies.append(_add(tops, MapKit.cell_name("bush_canopy", o.z), o))


func _add(parent: Node, cell: String, o: Vector4) -> Sprite2D:
	var spr := MapKit.sprite(cell, o.z)
	spr.position = Vector2(o.x, o.y)
	parent.add_child(spr)
	return spr


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
	if _legend != null:
		_legend.queue_redraw()


## Qabın bayırı — oyundakı eyni halqa mesh-i.
func _draw() -> void:
	draw_mesh(_backdrop, null)


## Şəbəkə, növ halqaları və bir ekranın çərçivəsi — döşəmənin üstündə,
## sprite-ların altında. Sediment zolaqları döşəmənin teksturasına bişib.
func _draw_marks(ci: Node2D) -> void:
	var r := Const.WORLD_RADIUS
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
	ci.draw_multiline_colors(lines, cols, 3.0)

	# Maneələr — NÖVƏ görə rənglənir. Stendin bütün mənası budur: düzümə
	# baxanda "harada gizlənmək olar, harada divar sındırmaq olar" sualı
	# bir baxışda cavablanmalıdır.
	for o in DishMap.obstacles():
		var at := Vector2(o.x, o.y)
		var col := _kind_color(int(o.w))
		# Sprite-ın altındakı halqa: sprite-lar bir-birini örtəndə düzümün
		# həndəsəsi itir, halqa isə hər maneənin SƏRHƏDİNİ saxlayır.
		ci.draw_circle(at, o.z, Color(col, 0.12))
		ci.draw_arc(at, o.z, 0.0, TAU, 48, Color(col, 0.95), 4.0, true)

	# Oyunçunun BİR ekranda gördüyü sahə — miqyas üçün.
	var w := Const.VIEW_SPAN_BASE
	var h2 := w * 16.0 / 9.0
	ci.draw_rect(Rect2(Vector2(-w * 0.5, -h2 * 0.5), Vector2(w, h2)),
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


## Növün rəngi. Oyunun özündə növ FORMA ilə oxunur (bax [method
## MapKit.base_name]) — burada isə rəng işlədilir, çünki stend yuxarıdan
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
