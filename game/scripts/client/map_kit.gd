class_name MapKit
extends RefCounted
## Xəritənin V1 "Damla" dəsti — atlas manifesti, hüceyrə seçimi, sprite və
## halqa mesh-ləri. Arena da, xəritə stendi də ([MapPreview]) maneəni BURADAN
## qurur: seçim iki yerdə ayrı yazılsaydı biri dəyişəndə o biri səssizcə
## köhnələrdi və stend oyunu yanlış göstərərdi.
##
## Assetlər `design/map_art/build_map.gd` ilə Codex-in xam şəklindən qurulur
## (bax design/MAP_25D.md §7). Manifest hər hüceyrənin atlasdakı kəsilmiş
## bölgəsini, pivotun ofsetini və ayaq izinin teksteldəki radiusunu saxlayır.
##
## ── Niyə BİR atlas ──────────────────────────────────────────────────────
## Godot yalnız ARDICIL və eyni teksturalı elementləri bir çağırışa yığır.
## Əvvəl beş SVG beş baza çağırışı, zədəli qabıq daha iki, burulğan bir, tac
## bir idi. İndi bütün maneələr, kölgələr və burulğanlar bir səhifədədir:
## baza qatı BİR çağırış, tac qatı BİR çağırış. Zədə mərhələsi isə
## tekstura deyil, bölgə dəyişməsidir — batch bölünmür.

const MANIFEST := "res://assets/map/map_atlas.json"
const ATLAS_PATH := "res://assets/map/map_atlas.png"
const FLOOR_PATH := "res://assets/map/map_floor.png"
const DETAIL_PATH := "res://assets/map/map_floor_detail.png"
const RIM_PATH := "res://assets/map/map_rim.png"
## Qabın bayırındakı bulanıq koloniyalar: 512² səhifədə dörd 256² hüceyrə
## (selik, kövrək, kol tacı, damla), diskin radiusu hüceyrədə PROP_R tekstel.
const PROPS_PATH := "res://assets/map/map_props.png"
const PROP_R := 77.0

## L / S sərhədi. Kiçik maneənin hüceyrəsi 256²-dir və konturu NİSBƏTƏN
## qalındır (6% R): R 34-lük daşda L-in 3.5%-i 1.2 dünya px olardı və itərdi.
const SMALL_MAX := 60.0

## Qabın şimal divarının hündürlüyü (ekranda yuxarı). Divar dodağın xarici
## tərəfinə, qabın BAYIRINA çəkilir — oyun sahəsindən heç nə yemir.
## W(θ) = WALL_MIN + WALL_RISE · max(0, −sin θ)^1.5: şimalda 70 px, şərq və
## qərbdə 8 px (divar yandan görünür), cənub yarısında 8 px.
const WALL_MIN := 8.0
const WALL_RISE := 62.0
## Cənub dodağı: içəriyə 6 + 22 · max(0, sin θ)^1.5 px, cənubda 28 px.
const LIP_MIN := 6.0
const LIP_RISE := 22.0
## Divar zolağının bir kafelinin təbii uzunluğu (1024×256 tekstura 70 px
## hündürlükdə). Çevrəyə tam sayda kafel düşür — tikiş görünmür.
const WALL_TILE := 280.0

static var _cells := {}
static var _detail_world := 400.0
## Teksturaların keşi — proses boyu yaşayır, arena bağlananda buraxılmır.
##
## Əvvəl arena bağlananda buraxılırdı (bax [method release]) və hər matç onları
## yenidən açırdı. Axınsız brauzerdə bu, ana axında itkisiz PNG-lərin açılması idi:
## A04s modelində (Chrome, CPU 6×) hər matçın başında arenanın `_ready`-si ~0.9 s
## donurdu, keşlə ~0.1 s-dir. APK-da menyu onları onsuz da fonda yenidən tuturdu
## (bax `MenuV2._preload_map`), yəni menyuda tutulan ~34 MB əvvəl də var idi.
##
## Keş TƏK sahib deyil. `load()` resursu Godot-un keşindən qaytarır, amma o keş
## onu tutmur: `_draw`-da `draw_texture_rect(load(...))` çağırılıb istinad
## buraxılanda tekstura azad olunur, çəkiliş əmri isə yalnız RID saxlayır — GPU
## ağ standart teksturanı çəkirdi (döşəmə və divar ağ çıxırdı; Sprite2D
## teksturanı özü tutduğu üçün atlas sağ qalırdı). Ona görə `_draw`-da tekstura
## çəkən hər node onu öz dəyişənində tutur.
static var _textures := {}
## Qabın sabit meşləri (fon, divar, dodaq) — bir dəfə qurulur, hər matç yox.
static var _meshes := {}


## Manifestin hüceyrələri: ad -> {"rect", "offset", "r", "cell"}.
static func cells() -> Dictionary:
	if _cells.is_empty():
		var json := load(MANIFEST) as JSON
		if json == null or not (json.data is Dictionary):
			push_error("MapKit: manifest açılmadı — " + MANIFEST)
			return _cells
		_cells = json.data["cells"]
		_detail_world = float(json.data.get("detail_world", 400.0))
	return _cells


## Döşəmə detalının bir kafeli neçə dünya px-dir (manifestdən).
static func detail_world() -> float:
	cells()
	return _detail_world


static func atlas() -> Texture2D:
	return _texture(ATLAS_PATH)


static func floor_texture() -> Texture2D:
	return _texture(FLOOR_PATH)


static func detail_texture() -> Texture2D:
	return _texture(DETAIL_PATH)


static func rim_texture() -> Texture2D:
	return _texture(RIM_PATH)


## Bayır dekorunun [param k]-cı parçası (0..3), diskin radiusu [param radius]
## dünya px-də. İşığı bişib — fırladılmır.
static func prop_sprite(k: int, radius: float) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = _texture(PROPS_PATH)
	spr.region_enabled = true
	spr.region_rect = Rect2(float(posmod(k, 2)) * 256.0, float(posmod(k, 4) >> 1) * 256.0,
		256.0, 256.0)
	spr.scale = Vector2.ONE * (radius / PROP_R)
	return spr


## Keşdəki teksturaları buraxır. Oyun bunu çağırmır — keş proses boyu yaşayır
## (bax [member _textures]); alətlər üçündür. Sprite-lar öz istinadlarını özləri
## buraxır; sonuncusu gedəndə tekstura azad olunur.
static func release() -> void:
	_textures.clear()


static func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path)
	return _textures[path]


static func size_class(radius: float) -> String:
	return "L" if radius > SMALL_MAX else "S"


## Maneənin baza hüceyrəsi (sinifsiz ad).
##
## SELİK iki naxış arasında MÖVQEYƏ görə bölünür, təsadüfə görə yox: eyni
## maneə hər açılışda eyni görünməlidir, yoxsa xəritə yadda saxlanıla bilməz.
## Dünyada 12 selik var və eyni qaydanın 12 eyni şəkli oriyentiri öldürürdü.
## Qalan növlərin hər birinin TƏK şəkli var — onlar qaydadır, bəzək deyil.
static func base_name(o: Vector4) -> String:
	match int(o.w):
		DishMap.Kind.BUSH:
			return "bush_base"
		DishMap.Kind.BRITTLE:
			return "brittle_s0"
		DishMap.Kind.VENT:
			return "vent_base"
	var pick := int(absf(o.x) * 0.37 + absf(o.y) * 0.61 + o.z * 1.7)
	return "mucus_bloom" if pick % 2 == 1 else "mucus_blob"


## Ad + ölçü sinfi: "brittle_s1" + R 96 → "brittle_s1_L".
static func cell_name(base: String, radius: float) -> String:
	return "%s_%s" % [base, size_class(radius)]


## Bu obyekt kölgə salırmı? Yalnız qalxan bərk növlər: kol və cərəyan
## keçiləndir və yastıdır (ART_BIBLE §4 — keçilən növün kölgəsi olmur).
static func casts_shadow(kind: int) -> bool:
	return DishMap.blocks_germ(kind)


## Atlasdan sprite: [param cell] hüceyrəsi, ayaq izinin radiusu [param radius]
## dünya px-də; ayaq izinin mərkəzi node-un mənşəyindədir.
static func sprite(cell: String, radius: float) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = atlas()
	spr.region_enabled = true
	apply(spr, cell, radius)
	return spr


## Mövcud sprite-ın hüceyrəsini dəyişir (zədə mərhələsi, qırıntı). Tekstura
## eyni qalır — yalnız bölgə, ofset və miqyas.
static func apply(spr: Sprite2D, cell: String, radius: float) -> void:
	var all := cells()
	if not all.has(cell):
		push_error("MapKit: atlasda hüceyrə yoxdur — " + cell)
		return
	var c: Dictionary = all[cell]
	var r: Array = c["rect"]
	spr.region_rect = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
	var off: Array = c["offset"]
	spr.offset = Vector2(float(off[0]), float(off[1]))
	spr.scale = Vector2.ONE * (radius / float(c["r"]))


## Şimal divarının eni bu bucaqda (bax [constant WALL_RISE]).
static func wall_width(angle: float) -> float:
	return WALL_MIN + WALL_RISE * pow(maxf(0.0, -sin(angle)), 1.5)


## Cənub dodağının eni bu bucaqda (bax [constant LIP_RISE]).
static func lip_width(angle: float) -> float:
	return LIP_MIN + LIP_RISE * pow(maxf(0.0, sin(angle)), 1.5)


## Qabın bayırı: dodaqda `BG_OUTER`, 600 px-də `BG_VIGNETTE`, sonra düz —
## bişməmiş radial vinyet, göz qaba yığılır. Xarici radius kameranın ən geniş
## baxışından böyükdür: halqanın kənarı heç vaxt ekrana düşmür.
static func backdrop_mesh() -> ArrayMesh:
	if _meshes.has("backdrop"):
		return _meshes["backdrop"]
	var r := Const.WORLD_RADIUS
	var near := func(_a: float) -> float: return r - 2.0
	var mid := func(_a: float) -> float: return r + 600.0
	var far := func(_a: float) -> float: return r + 2600.0
	var outer := func(_a: float) -> Color: return Palette.BG_OUTER
	var dark := func(_a: float) -> Color: return Palette.BG_VIGNETTE
	_meshes["backdrop"] = ring_mesh([[128, near, mid, outer, dark], [64, mid, far, dark, dark]])
	return _meshes["backdrop"]


## Şimal divarı: ayağı dodaqda (V = 1), üstü bayırda (V = 0), eni
## [method wall_width]. Çevrəyə tam sayda kafel düşür — tikiş yoxdur. Çəkən
## node-da tekstura təkrarı açıq olmalıdır.
##
## Kafellərin bəziləri GÜZGÜ kimi çevrilir (U 1 → 0). Divar zolağında üç
## kondensasiya halqası var və eyni sırada hər 280 px-də təkrarlananda divar
## divar kağızı kimi oxunurdu. Çevrilmiş kafelin kənarı qonşusunun eyni kənarı
## ilə görüşür (güzgü), çevrilməmişlə çevrilmiş də, iki çevrilmiş də tikişsizdir —
## zolaq özü üfüqi tikişsizdir. Seçim indeksdən deterministik çıxır.
static func rim_mesh() -> ArrayMesh:
	if _meshes.has("rim"):
		return _meshes["rim"]
	var r := Const.WORLD_RADIUS
	var tiles := maxi(1, roundi(TAU * r / WALL_TILE))
	var sub := 10
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	for k in tiles:
		var flip := wall_tile_flipped(k)
		for s in sub:
			var t0 := float(s) / float(sub)
			var t1 := float(s + 1) / float(sub)
			var a0 := TAU * (float(k) + t0) / float(tiles)
			var a1 := TAU * (float(k) + t1) / float(tiles)
			var u0 := 1.0 - t0 if flip else t0
			var u1 := 1.0 - t1 if flip else t1
			var d0 := Vector2.from_angle(a0)
			var d1 := Vector2.from_angle(a1)
			var p0i := d0 * (r - 1.0)
			var p0o := d0 * (r + wall_width(a0))
			var p1i := d1 * (r - 1.0)
			var p1o := d1 * (r + wall_width(a1))
			verts.append_array(PackedVector2Array([p0i, p0o, p1o, p0i, p1o, p1i]))
			uvs.append_array(PackedVector2Array([Vector2(u0, 1.0), Vector2(u0, 0.0),
				Vector2(u1, 0.0), Vector2(u0, 1.0), Vector2(u1, 0.0), Vector2(u1, 1.0)]))
	cols.resize(verts.size())
	cols.fill(Color.WHITE)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes["rim"] = mesh
	return mesh


## Divarın [param k]-cı kafeli güzgü kimi çevrilibmi? Əl ilə yazılmış ardıcıllıq
## (27 kafel = çevrə): heç yerdə ikidən çox eyni qonşu yoxdur, çevrənin
## bağlandığı yerdə də. Hash sınanmışdı — şimalda, ekranın ən çox gördüyü
## yerdə beş çevrilməmiş kafel ardıcıl düşürdü.
const WALL_FLIPS := "TFFTFTTFTFFTFTFFTTFTFFTFTTF"


static func wall_tile_flipped(k: int) -> bool:
	return WALL_FLIPS[posmod(k, WALL_FLIPS.length())] == "T"


## Cənub dodağı: şüşənin gövdəsi dərinə doğru sönür, kənarında nazik işıq
## xətti var. Cənubda (yaxın divar) daha sıxdır — kamera oradan şüşənin
## qalınlığına baxır.
static func lip_mesh() -> ArrayMesh:
	if _meshes.has("lip"):
		return _meshes["lip"]
	var r := Const.WORLD_RADIUS
	var body_in := func(a: float) -> float: return r - lip_width(a)
	var body_out := func(_a: float) -> float: return r - 2.5
	var edge_out := func(_a: float) -> float: return r + 0.5
	var clear := func(_a: float) -> Color: return Color(Palette.DISH_EDGE, 0.0)
	var glass := func(a: float) -> Color:
		return Color(Palette.DISH_EDGE, 0.16 + 0.16 * pow(maxf(0.0, sin(a)), 1.5))
	var shine := func(a: float) -> Color:
		return Color(Palette.RIM_LINE, 0.40 + 0.25 * maxf(0.0, sin(a)))
	_meshes["lip"] = ring_mesh([[192, body_in, body_out, clear, glass],
		[192, body_out, edge_out, shine, shine]])
	return _meshes["lip"]


## Qapalı halqalardan BİR səthli mesh (bir çəkiliş çağırışı). Hər element:
## [steps, inner, outer, col_in, col_out, u_span] — bax [method _ring].
static func ring_mesh(parts: Array) -> ArrayMesh:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	for p in parts:
		_ring(verts, cols, uvs, int(p[0]), p[1], p[2], p[3], p[4],
			float(p[5]) if p.size() > 5 else 0.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Qapalı halqa zolağı — hər addımda daxili və xarici nöqtə, rəng və UV.
## Hər seqment öz U-sunu daşıyır, ona görə tikişdə U kəsilmədən [param u_span]-ə
## çatır (tekstura təkrarı açıqdırsa u_span ≡ 0 — tam sayda kafel).
##
## [param inner]/[param outer] Callable(bucaq) -> radius; [param col_in]/
## [param col_out] Callable(bucaq) -> Color.
static func _ring(verts: PackedVector2Array, cols: PackedColorArray,
		uvs: PackedVector2Array, steps: int, inner: Callable, outer: Callable,
		col_in: Callable, col_out: Callable, u_span: float) -> void:
	for i in steps:
		var a0 := TAU * float(i) / float(steps)
		var a1 := TAU * float(i + 1) / float(steps)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		var p0i: Vector2 = d0 * float(inner.call(a0))
		var p0o: Vector2 = d0 * float(outer.call(a0))
		var p1i: Vector2 = d1 * float(inner.call(a1))
		var p1o: Vector2 = d1 * float(outer.call(a1))
		var c0i: Color = col_in.call(a0)
		var c0o: Color = col_out.call(a0)
		var c1i: Color = col_in.call(a1)
		var c1o: Color = col_out.call(a1)
		var u0 := u_span * float(i) / float(steps)
		var u1 := u_span * float(i + 1) / float(steps)
		# Daxili kənar V = 1 (zolağın dibi), xarici V = 0 (üstü): divarın
		# ayağı qabın döşəməsinə, dodağı bayıra baxır.
		verts.append_array(PackedVector2Array([p0i, p0o, p1o, p0i, p1o, p1i]))
		cols.append_array(PackedColorArray([c0i, c0o, c1o, c0i, c1o, c1i]))
		uvs.append_array(PackedVector2Array([Vector2(u0, 1.0), Vector2(u0, 0.0),
			Vector2(u1, 0.0), Vector2(u0, 1.0), Vector2(u1, 0.0), Vector2(u1, 1.0)]))
