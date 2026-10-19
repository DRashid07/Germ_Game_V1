class_name SuperFx
extends Node2D
## Superin İŞƏ DÜŞMƏ anı — hər üç növ üçün.
##
## ── Niyə ayrıca effekt ──────────────────────────────────────────────────
## Əvvəl super yalnız iki şeylə deyilirdi: qığılcım və (kirpiklidə) `burst.svg`
## buludu. Bulud [constant Arena.FX_LIFETIME] = 0.26 saniyə yaşayırdı və İLK
## kadrdan sönürdü — yumşaq, mərkəzdə 0.85, kənarda 0 alfalı ağ ləkə qaranlıq
## döşəmədə, mikrobun öz rənginə boyanmış halda. Kadr ardıcıllığı ilə ölçüldü:
## 12 kadrın yalnız BİRİNDƏ zəif yaşıl ləkə seçilirdi. Kirpikli standart növdür,
## yəni oyunçuların çoxu öz ultisini ümumiyyətlə görmürdü.
##
## Tor və kist davam edən vəziyyətdir və onları [GermVisual] özü çəkir, amma
## onların da AÇILIŞ anı yox idi — tor birdən "yanırdı". Brawl Stars-da ulti
## hər zaman ayrıca, səs-küylü bir andır: oyunçu onu basdığını HİSS etməlidir.
##
## ── Nə çəkilir ──────────────────────────────────────────────────────────
##   KİRPİKLİ — sahə diski + həqiqi radiusa qədər açılan zərbə dalğası +
##              membrandan atılan trixosist iynələri
##   AYAQLI   — torun sərhədinə qədər açılan halqa
##   AMÖB     — içəri çırpılan qabıq halqası və lövhə qırıntıları
##   hamısı   — gövdənin üstündə ağ parıltı
##
## Dalğa HƏQİQİ təsir radiusunda dayanır ([method Sim._use_super] onu hadisə
## ilə göndərir) — oyunçu sahənin ölçüsünü yalnız effektdən öyrənir.
##
## Hamısı bir node-un öz `_draw`-ındadır: 4–5 çəkiliş çağırışı, 0.85 saniyə.
##
## Effekt GPU-da çəkilir (`shaders/super_fx.gdshader`): mesh növ başına bir dəfə
## qurulur, hər kadr yalnız `age` yazılır. Əvvəl hər kadr GDScript-də iynələr və
## iki antialias-lı halqa yenidən qurulurdu — emulyatorda median kadrda 0.35 ms,
## ən yavaş kadrlarda 2.3 ms. Aşağıdakı `_draw_*` funksiyaları köhnə yoldur
## (`--fx-cpu`) və shader onların surətidir — dəyişsələr shader-i də yenilə
## (`_test_super_fx_gpu` xatırladır, `--germ-bench --bench-superfx` yan-yana göstərir).

## GPU yolu. `--fx-cpu` — köhnə GDScript çəkilişi (müqayisə və ehtiyat).
static var gpu := not OS.get_cmdline_user_args().has("--fx-cpu")

const SHADER := preload("res://shaders/super_fx.gdshader")
## Mesh-in qatları — shader-dəki L_* ilə eyni.
const L_DISC := 1
const L_NEEDLE := 2
const L_RING_DARK := 3
const L_RING := 4
const L_PLATE := 5
const L_FLASH := 6
## draw_circle və draw_arc-ın nöqtə sayları (Godot və aşağıdakı çağırışlar).
const CIRCLE_SEGMENTS := 64
const RING_POINTS := 64

const LIFETIME := 0.85
## Dalğanın açılma müddəti. İynələrdən YAVAŞDIR: iynələr qabaqda uçur,
## dalğa onların ardınca gəlir — "atəş, sonra zərbə" ardıcıllığı oxunur.
const WAVE_TIME := 0.30
const NEEDLE_TIME := 0.18
## Kist halqasının çırpılma müddəti. Qısadır: qabıq "bağlanır", açılmır.
const SNAP_TIME := 0.22
const NEEDLES_HIGH := 24
const NEEDLES_LOW := 12
const PLATES := 8

var _species := Const.Species.CILIATE
var _color := Color.WHITE
var _body := 30.0
var _reach := 100.0
var _needles := NEEDLES_HIGH
var _turn := 0.0
var _age := 0.0
## Tor və kist mikrobun ÖZÜNÜN vəziyyətidir — açılış onu izləyir. Trixosist
## isə partlayışdır: yerində qalır, mikrob ondan geri sıçrayır.
##
## İzləmədən ayaqlının açılış halqası hadisənin nöqtəsində qalırdı, tor isə
## mikrobla gedirdi — kadrda iki sürüşmüş halqa görünürdü.
var _follow: Node2D = null

## Bu effekt GPU-dadırmı — [method setup]-dan əvvəl dəyişdirilə bilər (stend iki
## yolu yan-yana qoyur).
var use_gpu: bool = gpu
var _mat: ShaderMaterial = null
var _mesh: ArrayMesh = null
static var _template: ShaderMaterial = null
static var _meshes := {}
## Ağacdakı effektlərin sayı — kadr probu super anlarını ayrıca ölçür.
static var active := 0


## [param body] mikrobun radiusu · [param reach] təsir sahəsinin radiusu
## (kirpiklidə trixosist, ayaqlıda tor; amöbdə qabığın öz radiusu).
func setup(species: Const.Species, color: Color, body: float, reach: float,
		low_quality: bool) -> void:
	_species = species
	_color = color
	_body = maxf(body, 8.0)
	_reach = maxf(reach, _body)
	_needles = NEEDLES_LOW if low_quality else NEEDLES_HIGH
	_turn = randf() * TAU
	z_index = 3
	if use_gpu and DisplayServer.get_name() != "headless":
		_mesh = _mesh_for(_species, _needles)
		# Hər effektin öz materialı: dəyərlər adi uniform-dur (`instance uniform`
		# brauzerdə bəzi elementlərə çatmırdı, bax GermGPU._row_material).
		_mat = _template_material().duplicate() as ShaderMaterial
		_mat.set_shader_parameter("species", int(_species))
		_mat.set_shader_parameter("fx_color", Vector3(_color.r, _color.g, _color.b))
		_mat.set_shader_parameter("body", _body)
		_mat.set_shader_parameter("reach", _reach)
		_mat.set_shader_parameter("needles", _needles)
		_mat.set_shader_parameter("age", 0.0)
		material = _mat
		_sync_turn()


## Açılışın izləyəcəyi mikrob. Trixosistdə verilmir.
func follow(target: Node2D) -> void:
	_follow = target


## İynələrin və lövhələrin başlanğıc bucağı ([method setup] təsadüfi seçir; stend
## iki yolu eyni bucaqla qurmaq üçün sonradan yazır).
func set_turn(value: float) -> void:
	_turn = value
	_sync_turn()


func _sync_turn() -> void:
	if _mat != null:
		_mat.set_shader_parameter("turn", _turn)


func _enter_tree() -> void:
	active += 1


func _exit_tree() -> void:
	active -= 1


func _ready() -> void:
	if _mat != null:
		# Mesh-in təpələri kod olduğuna görə Godot sərhədi özü bilmir — ekrandan
		# kənarda kəsilmə üçün düzbucaqlı əl ilə verilir (halqa + ən qalın xətt).
		var ext := maxf(_reach, _body * 2.3) + 20.0
		RenderingServer.canvas_item_set_custom_rect(get_canvas_item(), true,
			Rect2(-ext, -ext, ext * 2.0, ext * 2.0))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	if _follow != null and is_instance_valid(_follow):
		position = _follow.position
	if _mat != null:
		_mat.set_shader_parameter("age", _age)
	else:
		queue_redraw()


func _draw() -> void:
	if _mat != null:
		# Mesh bir dəfə verilir; hərəkət edən hər şey shader-dədir.
		draw_mesh(_mesh, null)
		return
	var u := clampf(_age / LIFETIME, 0.0, 1.0)
	match _species:
		Const.Species.HELIOZOAN:
			_draw_opening(u)
		Const.Species.AMOEBA:
			_draw_snap(u)
		_:
			_draw_trichocyst(u)
	_draw_flash()


## Sönmə — açılma bitənə qədər tam, sonra hamar sıfıra.
##
## Xətti sönmə (köhnə bulud kimi) effekti ən böyük olduğu anda yarı şəffaf
## edirdi; burada isə ölçü tam ikən parlaqlıq da tamdır.
func _fade(u: float) -> float:
	return 1.0 - smoothstep(0.38, 1.0, u)


static func _ease_out(p: float) -> float:
	var q := 1.0 - clampf(p, 0.0, 1.0)
	return 1.0 - q * q * q


func _draw_trichocyst(u: float) -> void:
	var a := _fade(u)
	var p := _ease_out(_age / WAVE_TIME)
	var wave := lerpf(_body, _reach, p)

	# Sahə diski — yalnız dalğanın İÇİ. Sönük, çünki içindəki mikroblar və
	# toplar oxunmalıdır; məqsəd sərhədi yox, SAHƏNİ göstərməkdir.
	draw_circle(Vector2.ZERO, wave, Color(_color, 0.20 * a))

	# İynələr — bir çəkiliş çağırışında. Hər iynə iki seqmentdir: rəngli gövdə
	# və ağ uc. Uc ayrıca `draw_circle` ilə çəkilsəydi, 24 iynə 24 çağırış olardı.
	var reach_p := _ease_out(_age / NEEDLE_TIME)
	var tip_r := lerpf(_body, _reach * 0.94, reach_p)
	var length := lerpf(_body * 0.55, _body * 0.30, u)
	var lines := PackedVector2Array()
	var cols := PackedColorArray()
	var body_col := Color(_color.lerp(Color.WHITE, 0.35), 0.95 * a)
	var tip_col := Color(Palette.TEXT, a)
	for i in _needles:
		var dir := Vector2.from_angle(_turn + TAU * float(i) / float(_needles))
		# Uzunluq növbələnir: bərabər iynələr diş çarxı kimi görünür.
		var k := 1.0 if i % 2 == 0 else 0.78
		var tip := dir * (tip_r * k)
		var mid := tip - dir * (length * 0.35)
		var tail := tip - dir * length
		lines.push_back(tail); lines.push_back(mid)
		cols.push_back(body_col)
		lines.push_back(mid); lines.push_back(tip)
		cols.push_back(tip_col)
	draw_multiline_colors(lines, cols, maxf(2.5, _body * 0.09))

	# Zərbə dalğası — tünd altlıq + parlaq halqa. Altlıq açıq döşəmədə də
	# (kol, qabıq) halqanın oxunması üçündür.
	var w := lerpf(10.0, 3.5, p)
	draw_arc(Vector2.ZERO, wave, 0.0, TAU, 64, Color(Palette.OUTLINE, 0.45 * a), w + 5.0, true)
	draw_arc(Vector2.ZERO, wave, 0.0, TAU, 64,
		Color(_color.lerp(Color.WHITE, 0.55), a), w, true)


func _draw_opening(u: float) -> void:
	var a := _fade(u)
	var p := _ease_out(_age / (WAVE_TIME * 1.2))
	var ring := lerpf(_body, _reach, p)
	draw_circle(Vector2.ZERO, ring, Color(_color, 0.12 * a))
	var w := lerpf(9.0, 3.0, p)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64, Color(Palette.OUTLINE, 0.40 * a), w + 5.0, true)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64,
		Color(_color.lerp(Color.WHITE, 0.55), a), w, true)


func _draw_snap(u: float) -> void:
	var a := _fade(u)
	var p := _ease_out(_age / SNAP_TIME)
	# Qabıq BAYIRDAN içəri gəlir — tor açılır, kist isə bağlanır; iki effekt
	# bir-birinin əksidir və növlər hərəkət istiqamətindən də ayrılır.
	var ring := lerpf(_body * 2.3, _reach, p)
	var w := lerpf(3.0, 9.0, p)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64, Color(Palette.OUTLINE, 0.45 * a), w + 5.0, true)
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 64,
		Color(_color.lerp(Color.WHITE, 0.45), a), w, true)

	# Lövhə qırıntıları qabığa doğru çəkilir və onunla birləşir.
	var lines := PackedVector2Array()
	var half := TAU / float(PLATES) * 0.28
	var from := ring + lerpf(_body * 0.9, 0.0, p)
	for i in PLATES:
		var ang := _turn + TAU * float(i) / float(PLATES)
		lines.push_back(Vector2.from_angle(ang - half) * from)
		lines.push_back(Vector2.from_angle(ang + half) * from)
	draw_multiline(lines, Color(Palette.TEXT, 0.85 * a), maxf(3.0, _body * 0.10))


## Gövdənin üstündə ani ağ parıltı — ilk 0.2 saniyə.
func _draw_flash() -> void:
	var k := 1.0 - clampf(_age / 0.2, 0.0, 1.0)
	if k <= 0.0:
		return
	draw_circle(Vector2.ZERO, _body * (1.0 + 0.35 * (1.0 - k)), Color(Palette.TEXT, 0.65 * k * k))


# ---------------------------------------------------------------- GPU yolu

## Sabitləri bir dəfə yazılmış material — hər effekt onun nüsxəsini götürür.
static func _template_material() -> ShaderMaterial:
	if _template == null:
		var m := ShaderMaterial.new()
		m.shader = SHADER
		m.set_shader_parameter("lifetime", LIFETIME)
		m.set_shader_parameter("wave_time", WAVE_TIME)
		m.set_shader_parameter("needle_time", NEEDLE_TIME)
		m.set_shader_parameter("snap_time", SNAP_TIME)
		m.set_shader_parameter("plates", PLATES)
		m.set_shader_parameter("c_outline", Vector3(Palette.OUTLINE.r, Palette.OUTLINE.g, Palette.OUTLINE.b))
		m.set_shader_parameter("c_text", Vector3(Palette.TEXT.r, Palette.TEXT.g, Palette.TEXT.b))
		_template = m
	return _template


## Növün mesh-i — qatlar `_draw`-dakı SIRA ilə: kirpiklidə disk, iynələr, iki
## halqa; ayaqlıda disk, iki halqa; amöbdə iki halqa, lövhələr; sonda parıltı.
static func _mesh_for(species: Const.Species, needles: int) -> ArrayMesh:
	var key := "%d:%d" % [int(species), needles if species == Const.Species.CILIATE else 0]
	if _meshes.has(key):
		return _meshes[key]
	var b := GermGPU.Builder.new()
	if species != Const.Species.AMOEBA:
		b.fan(L_DISC, CIRCLE_SEGMENTS)
	if species == Const.Species.CILIATE:
		# Hər iynə iki seqmentdir (gövdə, uc) — draw_multiline-ın sırası.
		for i in needles * 2:
			b.quad(L_NEEDLE, i, 0)
	b.aa_loop(L_RING_DARK, RING_POINTS)
	b.aa_loop(L_RING, RING_POINTS)
	if species == Const.Species.AMOEBA:
		for i in PLATES:
			b.quad(L_PLATE, i, 0)
	b.fan(L_FLASH, CIRCLE_SEGMENTS)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, b.arrays())
	_meshes[key] = mesh
	return mesh
