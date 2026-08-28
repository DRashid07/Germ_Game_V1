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

	_spawn_sprites()


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
	for o in DishMap.obstacles():
		var spr := Sprite2D.new()
		spr.texture = tex[Arena._blob_texture(o)]
		spr.position = Vector2(o.x, o.y)
		spr.scale = Vector2.ONE * (o.z / Arena.BLOB_SPRITE_RADIUS)
		if int(o.w) != DishMap.Kind.VENT:
			spr.rotation = float(o.x + o.y) * 0.01
		add_child(spr)


func _process(_delta: float) -> void:
	var vp := get_viewport_rect().size
	var k := minf(vp.x, vp.y) / (Const.WORLD_RADIUS * 2.0 * MARGIN)
	_cam.zoom = Vector2(k, k)
	queue_redraw()


func _draw() -> void:
	var r := Const.WORLD_RADIUS
	draw_circle(Vector2.ZERO, r, Palette.DISH)

	# Şəbəkə və halqalar — oyundakı ilə eyni ölçüdə.
	var step := 200.0
	var lines := PackedVector2Array()
	var n := int(r / step)
	for i in range(-n, n + 1):
		var x := float(i) * step
		var h := sqrt(maxf(r * r - x * x, 0.0))
		lines.push_back(Vector2(x, -h))
		lines.push_back(Vector2(x, h))
		lines.push_back(Vector2(-h, x))
		lines.push_back(Vector2(h, x))
	draw_multiline(lines, Color(Palette.GRID, 0.55), 3.0)
	for i in 3:
		draw_arc(Vector2.ZERO, r * (0.35 + 0.22 * float(i)), 0.0, TAU, 96,
			Color(Palette.GRID, 0.5), 3.0, true)

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

	draw_arc(Vector2.ZERO, r, 0.0, TAU, 128, Palette.DISH_EDGE, 12.0, true)

	# Oyunçunun BİR ekranda gördüyü sahə — miqyas üçün.
	var w := Const.VIEW_SPAN_BASE
	var h2 := w * 16.0 / 9.0
	draw_rect(Rect2(Vector2(-w * 0.5, -h2 * 0.5), Vector2(w, h2)),
		Color(Palette.TEXT, 0.55), false, 5.0)

	# Başlıq və əfsanənin arxasına panel: maneə sprite-ları düzümdən asılı
	# olaraq bura düşə bilir və yazını oxunmaz edir. Panel düzümdən asılı
	# deyil, ona görə stend HƏR düzümdə oxunaqlı qalır.
	draw_rect(Rect2(Vector2(-r * 1.02, -r * 1.02), Vector2(r * 0.86, r * 0.72)),
		Color(Palette.BG_OUTER, 0.82))

	var label := "%d — %s" % [layout, DishMap.layout_name(layout)]
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-r * 0.95, -r * 0.86), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 120, Palette.TEXT)
	draw_string(font, Vector2(-r * 0.95, -r * 0.72),
		"%d maneə · çərçivə = bir ekran" % DishMap.obstacles().size(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 76, Palette.TEXT_MUTED)

	# Növlərin açarı.
	var y := -r * 0.58
	for kind in [DishMap.Kind.MUCUS, DishMap.Kind.BUSH, DishMap.Kind.BRITTLE,
			DishMap.Kind.VENT]:
		var col := _kind_color(kind)
		draw_circle(Vector2(-r * 0.90, y - 22.0), 26.0, Color(col, 0.35))
		draw_arc(Vector2(-r * 0.90, y - 22.0), 26.0, 0.0, TAU, 24, col, 4.0, true)
		draw_string(font, Vector2(-r * 0.80, y), DishMap.kind_name(kind),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 64, col)
		y += r * 0.11


## Növün rəngi. Oyunun özündə növ FORMA ilə oxunur (bax [const
## Arena.BLOB_TEXTURE]) — burada isə rəng işlədilir, çünki stend yuxarıdan
## baxışdır və orada forma seçilmir.
static func _kind_color(kind: int) -> Color:
	match kind:
		DishMap.Kind.BUSH:
			return Color("3E8A6B")
		DishMap.Kind.BRITTLE:
			return Color("B8763A")
		DishMap.Kind.VENT:
			return Color("E8A845")
		_:
			return Palette.DISH_EDGE
