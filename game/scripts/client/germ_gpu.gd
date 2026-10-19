class_name GermGPU
extends RefCounted
## Mikrobun GPU çəkilişi — paylaşılan resurslar (bax design/PERF_PLAN.md, F1).
##
## ── Niyə ─────────────────────────────────────────────────────────────────
## [GermVisual] mikrobu hər kadr GDScript-də çəkirdi: kölgə, iki tonlu dəri, işıq,
## 40-a qədər top, kontur, 30 kirpik, ayaqlar, rim, çatlar — onlarla `draw_*`
## çağırışı və onların hər nöqtəsi GDScript-də hesablanırdı. Zəif telefonda kadrın
## ən böyük xərci məhz bu idi (masaüstündə belə mikrob başına 0.3–0.5 ms).
##
## Müasir oyunlar belə obyekti CPU-da çəkmir: həndəsə SABİT mesh-dir, hər kadr
## GPU-ya yalnız vəziyyət gedir, formanı isə shader qurur. Burada da elədir: hər
## növün iki sabit mesh-i var, mikrobun vəziyyəti ümumi float teksturasında BİR
## SƏTİRDİR — ~80 ədəd (bax [method GermVisual.gpu_row_bytes]). Kadrda iki GPU
## keçidi var:
##   1. kontur keçidi (shaders/germ_shape.gdshader) — kiçik RGBA8 render hədəfində
##      hər mikrobun membranını, kölgəsini və mərkəzlərini qurur (GPU skinning kimi:
##      CPU yalnız parametr verir);
##   2. əsas keçid (shaders/germ.gdshader) — o konturdan bütün qatları çəkir.
## Kadrda mikrob başına CPU-da qalan iş: sətrin ədədləri + iki mesh çağırışı.
## Görüntü itmir — shader-lər GDScript yolunun formullarını bir-bir təkrarlayır;
## `--germ-bench --bench-render pair` ikisini yan-yana göstərir, `--bench-verify`
## isə konturları nöqtə-nöqtə müqayisə edir.
##
## ── Quruluş ───────────────────────────────────────────────────────────────
##   • gövdə qatı ([method body_mesh]) — mikrob node-unun ARXASINDA
##     (`show_behind_parent`): kölgədən çatlara qədər hər şey;
##   • ön qat ([method front_mesh]) — super (amöbün qabığı, ayaqlının toru),
##     yoldaş və doğuş halqaları, qığılcımlar, zərbə parıltısı; adın ARXASINDA.
## Sıra GDScript yolu ilə eynidir, ona görə qatların üst-üstə düşməsi dəyişmir.
## Node-un öz `_draw`-ı GPU yolunda heç nə çəkmir.
##
## Sətirlər kadrın SONUNDA yazılır (`frame_pre_draw`): [method _draw] də kadrın
## sonunda çağırılırdı, yəni arena hadisəni mikrobun `_process`-indən sonra
## versə belə, o elə həmin kadrda görünür.

const SHADER := preload("res://shaders/germ.gdshader")
const SHAPE_SHADER := preload("res://shaders/germ_shape.gdshader")

## Məlumat sətri (texel; bir texel 4 float, 16 bayt): başlıq və konturun
## ədədləri 20 texel ([method GermVisual.gpu_row_bytes]), sonra 13 ayaq.
## shader-lərdəki LEGS0 ilə EYNİ.
const TEXEL := 16
const LEGS0 := 20
const WIDTH := 36

## Kontur hədəfinin sütunları (bax shaders/germ_shape.gdshader): son kontur,
## kölgənin konturu, iki mərkəz. Hər iki shader-dəki adlarla EYNİ.
const RING0 := 0
const SRING0 := 44
const COL_MID := 88
const COL_SMID := 89
const OUT_WIDTH := 90

## Qatlar — shader-dəki L_* ilə EYNİ (sıra çəkiliş sırasıdır).
const L_SHADOW_OUT := 1
const L_SHADOW_IN := 2
const L_BIRTH := 3
const L_HALO := 4
const L_AURA := 5
const L_SKIN := 6
const L_LIT := 7
const L_SKIN2 := 8
const L_LIT2 := 9
const L_SPEC := 10
const L_CORE := 11
const L_BALL := 12
const L_EMERGE := 13
const L_OUTLINE := 14
const L_OUTLINE2 := 15
const L_LEG_DARK := 16
const L_LEG_COL := 17
const L_LEG_TIP := 18
const L_SKELETON := 19
const L_CILIA := 20
const L_TAIL_OUT := 21
const L_TAIL_IN := 22
const L_RIM := 23
const L_CRACK := 24
const L_CYST_DISC := 30
const L_CYST_SHELL := 31
const L_CYST_INNER := 32
const L_CYST_GLINT := 33
const L_CYST_SEAM := 34
const L_NET_FILL := 35
const L_NET_EDGE_DARK := 36
const L_NET_EDGE := 37
const L_NET_INNER := 38
const L_NET_RAY := 39
const L_NET_TIP := 40
const L_ALLY := 41
const L_SAFE := 42
const L_SPARK := 43
const L_FLASH := 44

## Toplar: [method GermVisual._draw_inner_balls] 40-dan çoxunu çəkmir.
const MAX_BALLS := 40
## Təhlükə çatları ən çox 5-dir (3 + rəng % 3), hərəsi 3 nöqtə.
const MAX_CRACKS := 5
## draw_arc nöqtə sayları — GermVisual-dakı çağırışlarla EYNİ.
const BIRTH_POINTS := 36
const SKELETON_POINTS := 28
const ALLY_POINTS := 40
const SAFE_POINTS := 24
const SPARK_LINES := 6

## `--germ-cpu` söndürür — onda hər mikrob GDScript yolu ilə çəkilir (müqayisə və
## ehtiyat). Bayraq burada oxunur, boot.gd-də yox: oradakı istinad bu skripti və
## onunla [GermVisual]-ı menyunun açılışında kompilyasiya etdirərdi.
static var enabled := not OS.get_cmdline_user_args().has("--germ-cpu")

static var _material: ShaderMaterial
## Sətir başına material nüsxəsi (bax [method _row_material]).
static var _row_materials: Array[ShaderMaterial] = []
static var _image: Image
static var _texture: ImageTexture
## Kontur keçidi: kiçik render hədəfi, hər sətri bir mikrob (bax germ_shape.gdshader).
## Kökdə yaşayır və oyun boyu qalır; mikrob yoxdursa çəkilmir.
static var _shape_pass: SubViewport
static var _shape_rect: ColorRect
static var _shape_material: ShaderMaterial
static var _used := 0
static var _cap := 0
static var _rows: Array[PackedByteArray] = []
static var _owners: Array = []
static var _queued := PackedByteArray()
static var _free: Array[int] = []
static var _pending: Array[int] = []
static var _dirty := false
static var _blank := PackedByteArray()
static var _meshes := {}
static var _driver: Driver
static var _warmed := false
## Sətirlərin qurulmasına və yüklənməyə gedən vaxt (mikrosaniyə, yığılır) —
## ölçmə stendi oxuyub sıfırlayır (bax `tools/germ_bench.gd`).
static var spent_rows_usec := 0
static var spent_upload_usec := 0


## GPU yolu bu prosesdə işləyirmi. Başsız rejimdə (server, testlər) çəkiliş yoxdur.
static func supported() -> bool:
	return enabled and DisplayServer.get_name() != "headless"


## Shader-lər ilk çəkilişdə kompilyasiya olunur — zəif telefonda bu, yüzlərlə ms-lik
## donmadır və arenanın ilk anına düşürdü. Müasir oyunlar bunu yükləmə zamanı edir
## (shader / PSO precache): burada [param host] altında üç kadr boyunca demək olar
## şəffaf iki qat və kontur keçidi çəkilir, sonra silinir. Tam şəffaf olmur, çünki
## Godot `modulate.a < 0.007` olan elementi heç çəkmir (deməli kompilyasiya da olmaz).
## Sətir boşdur (radius 0), yəni həndəsə də demək olar yoxdur.
static func warm_up(host: CanvasItem) -> void:
	if _warmed or not supported() or not host.is_inside_tree():
		return
	_warmed = true
	var row := acquire(null)
	var layers: Array[Node2D] = [
		layer(body_mesh(Const.Species.AMOEBA), false, row),
		layer(front_mesh(Const.Species.HELIOZOAN), false, row),
	]
	for l in layers:
		l.modulate = Color(1.0, 1.0, 1.0, 0.01)
		set_extent(l, 100000.0)
		host.add_child(l)
	_dirty = true
	var tree := host.get_tree()
	for i in 3:
		await tree.process_frame
	for l in layers:
		if is_instance_valid(l):
			l.queue_free()
	release(row)


## Kontur keçidinin bu kadrkı nəticəsi (GPU-dan geri oxunur — YAVAŞDIR, yalnız
## yoxlama üçündür, bax `tools/germ_bench.gd --bench-verify`).
static func shape_image() -> Image:
	return _shape_pass.get_texture().get_image() if _shape_pass != null else null


## [method shape_image]-dəki bir texeli koordinata açır (germ_shape.gdshader, `encode`).
static func decode_point(c: Color) -> Vector2:
	var b := [roundi(c.r * 255.0), roundi(c.g * 255.0), roundi(c.b * 255.0), roundi(c.a * 255.0)]
	return Vector2(float(b[0] * 256 + b[1]), float(b[2] * 256 + b[3])) / 128.0 - Vector2(256.0, 256.0)


## Mikroba sətir ayırır. Sətir mikrob silinənə qədər onundur ([method release]).
static func acquire(owner: Object) -> int:
	_ensure()
	var row: int
	if _free.is_empty():
		row = _rows.size()
		_rows.append(_blank)
		_owners.append(owner)
		_queued.append(0)
		if _rows.size() > _cap:
			_grow()
	else:
		row = _free.pop_back()
		_owners[row] = owner
	_used += 1
	_shape_pass.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	return row


static func release(row: int) -> void:
	if row < 0 or row >= _rows.size():
		return
	_rows[row] = _blank
	_owners[row] = null
	_free.append(row)
	_dirty = true
	_used -= 1
	if _used <= 0 and _shape_pass != null:
		_shape_pass.render_target_update_mode = SubViewport.UPDATE_DISABLED


## Sətir bu kadr yenidən yazılsın — baytlar kadrın sonunda alınır ([method _flush]).
static func submit(row: int) -> void:
	if _queued[row] == 0:
		_queued[row] = 1
		_pending.append(row)


## Mesh-i bir dəfə çəkən qat. Mesh dəyişmir, hərəkət edən hər şey shader-dədir,
## ona görə `_draw` yalnız qat ağaca girəndə işləyir.
static func layer(mesh: Mesh, behind: bool, row: int) -> Node2D:
	var l := Layer.new()
	l.mesh = mesh
	l.material = _row_material(row)
	l.show_behind_parent = behind
	return l


## Sətrin öz materialı — sətir nömrəsi orada ADİ uniform-dur.
##
## Əvvəl bütün qatlar bir materialı bölüşürdü və nömrə `instance uniform` idi.
## Brauzerdə (Godot 4.7 web, Chrome və WebKit) bəzi qatlarda o dəyər tətbiq
## olunmurdu: qat susmaya görə 0-cı sətri oxuyurdu, yəni ikinci mikrob birincinin
## formasını və rəngini çəkirdi (masaüstündə və emulyatorda belə olmurdu). Qatlar
## onsuz da ayrı çəkiliş çağırışlarıdır — material nüsxəsi çağırış artırmır.
## Nüsxə sətirlə birlikdə qalır: sətir başqa mikroba keçəndə də yenisi yaranmır.
static func _row_material(row: int) -> ShaderMaterial:
	while _row_materials.size() <= row:
		var m := _material.duplicate() as ShaderMaterial
		m.set_shader_parameter("row", float(_row_materials.size()))
		_row_materials.append(m)
	return _row_materials[row]


## Mesh-in təpələri kod olduğuna görə Godot qatın sərhədini özü bilmir —
## ekrandan kənarda kəsilmə üçün düzbucaqlı əl ilə verilir.
static func set_extent(l: CanvasItem, ext: float) -> void:
	RenderingServer.canvas_item_set_custom_rect(l.get_canvas_item(), true,
		Rect2(-ext, -ext, ext * 2.0, ext * 2.0))


## Superdən ƏVVƏL çəkilən hər şey: kölgədən təhlükə çatlarına qədər.
static func body_mesh(kind: int) -> ArrayMesh:
	return _mesh("body%d" % kind, body_arrays(kind))


## Superdən SONRA çəkilənlər: yoldaş və doğuş halqaları, qığılcımlar, parıltı.
static func front_mesh(kind: int) -> ArrayMesh:
	return _mesh("front%d" % kind, front_arrays(kind))


## Gövdə mesh-inin massivləri (testlər mesh-siz yoxlayır — başsız rejimdə
## RenderingServer mesh saxlamır).
static func body_arrays(kind: int) -> Array:
	var amoeba := kind == Const.Species.AMOEBA
	var n := _points(kind)
	var b := Builder.new()
	b.fan(L_SHADOW_OUT, n)
	b.fan(L_SHADOW_IN, n)
	b.aa_loop(L_BIRTH, BIRTH_POINTS)
	b.quad(L_HALO, 0, 0)
	b.quad(L_AURA, 0, 0)
	b.fan(L_SKIN, n)
	b.fan(L_LIT, n)
	if amoeba:
		b.fan(L_SKIN2, n)
		b.fan(L_LIT2, n)
	b.quad(L_SPEC, 0, 0)
	if not amoeba:
		b.quad(L_CORE, 0, 0)
	for i in MAX_BALLS:
		for sub in 3:
			b.quad(L_BALL, i, sub * 4)
	for sub in 3:
		b.quad(L_EMERGE, 0, sub * 4)
	# Qapalı kontur: n+1 stansiya, `_closed(ring)` kimi.
	b.aa_loop(L_OUTLINE, n + 1)
	if amoeba:
		b.aa_loop(L_OUTLINE2, n + 1)
	match kind:
		Const.Species.HELIOZOAN:
			for l in [L_LEG_DARK, L_LEG_COL, L_LEG_TIP]:
				for i in GermVisual.LEGS_MAX * 2:
					b.quad(l, i, 0)
			b.aa_loop(L_SKELETON, SKELETON_POINTS)
		Const.Species.CILIATE:
			for i in GermVisual.CILIA_MAX:
				b.ribbon(L_CILIA, i)
			b.strip(L_TAIL_OUT, GermVisual.TAIL_POINTS)
			b.strip(L_TAIL_IN, GermVisual.TAIL_POINTS)
	# Rim ən çox n-1 nöqtədir: ən uzun qövsün qabağında uyğun olmayan təpə var.
	b.aa_open_tail(L_RIM, n - 1)
	for c in MAX_CRACKS:
		b.aa_open(L_CRACK, c * 3, 3)
	return b.arrays()


static func front_arrays(kind: int) -> Array:
	var b := Builder.new()
	# Super — GermVisual._draw_cyst / _draw_net, eyni nöqtə sayları ilə.
	match kind:
		Const.Species.AMOEBA:
			b.quad(L_CYST_DISC, 0, 0)
			b.aa_loop(L_CYST_SHELL, 40)
			b.aa_loop(L_CYST_INNER, 36)
			b.aa_open(L_CYST_GLINT, 0, 20)
			for i in 8:
				b.quad(L_CYST_SEAM, i, 0)
		Const.Species.HELIOZOAN:
			b.quad(L_NET_FILL, 0, 0)
			b.aa_loop(L_NET_EDGE_DARK, 72)
			b.aa_loop(L_NET_EDGE, 72)
			b.aa_loop(L_NET_INNER, 56)
			for i in 16:
				b.quad(L_NET_RAY, i, 0)
			for i in 16:
				b.quad(L_NET_TIP, i, 0)
	b.aa_loop(L_ALLY, ALLY_POINTS)
	b.aa_open(L_SAFE, 0, SAFE_POINTS)
	for i in SPARK_LINES:
		b.quad(L_SPARK, i, 0)
	b.fan(L_FLASH, _points(kind))
	return b.arrays()


static func _points(kind: int) -> int:
	return GermVisual.CRAWL_POINTS if kind == Const.Species.AMOEBA \
		else GermVisual.MEMBRANE_POINTS


static func _mesh(key: String, arrays: Array) -> ArrayMesh:
	if not _meshes.has(key):
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_meshes[key] = mesh
	return _meshes[key]


static func _ensure() -> void:
	if _material != null:
		return
	_cap = 32
	_blank.resize(WIDTH * TEXEL)
	_blank.fill(0)
	_image = Image.create_empty(WIDTH, _cap, false, Image.FORMAT_RGBAF)
	_texture = ImageTexture.create_from_image(_image)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("data", _texture)
	m.set_shader_parameter("c_outline", _rgb(Palette.OUTLINE))
	m.set_shader_parameter("c_body_light", _rgb(Palette.BODY_LIGHT))
	m.set_shader_parameter("c_danger", _rgb(Palette.DANGER))
	m.set_shader_parameter("c_warning", _rgb(Palette.WARNING))
	m.set_shader_parameter("c_text", _rgb(Palette.TEXT))
	m.set_shader_parameter("c_hit_flash", _rgb(Palette.HIT_FLASH))
	m.set_shader_parameter("c_ally", _rgb(Palette.ALLY))
	m.set_shader_parameter("c_super_ready", _rgb(Palette.SUPER_READY))
	m.set_shader_parameter("light_dir", Palette.LIGHT_DIR)
	m.set_shader_parameter("shot_radius", Const.SHOT_RADIUS)
	m.set_shader_parameter("shot_speed", Const.SHOT_SPEED)
	m.set_shader_parameter("net_radius", Const.NET_RADIUS)
	m.set_shader_parameter("shield_gap", GermVisual.SHIELD_GAP)
	m.set_shader_parameter("halo_gap_scale", GermVisual.HALO_GAP_SCALE)
	m.set_shader_parameter("lit_inset", GermVisual.LIT_INSET)
	m.set_shader_parameter("lit_shift", GermVisual.LIT_SHIFT)
	m.set_shader_parameter("specular_size", GermVisual.SPECULAR_SIZE)
	m.set_shader_parameter("specular_offset", GermVisual.SPECULAR_OFFSET)
	m.set_shader_parameter("specular_alpha", GermVisual.SPECULAR_ALPHA)
	m.set_shader_parameter("rim_normal_cutoff", GermVisual.RIM_NORMAL_CUTOFF)
	m.set_shader_parameter("crawl_band", GermVisual.CRAWL_BAND)
	m.set_shader_parameter("crawl_band_min", GermVisual.CRAWL_BAND_MIN)
	m.set_shader_parameter("crawl_core", GermVisual.CRAWL_CORE)
	m.set_shader_parameter("leg_sway", GermVisual.LEG_SWAY)
	m.set_shader_parameter("cilia_beat", GermVisual.CILIA_BEAT)
	m.set_shader_parameter("cilia_waves", GermVisual.CILIA_WAVES)
	m.set_shader_parameter("stretch_max", GermVisual.STRETCH_MAX)
	m.set_shader_parameter("tail_length", GermVisual.TAIL_LENGTH)
	m.set_shader_parameter("tail_points", GermVisual.TAIL_POINTS)
	m.set_shader_parameter("cilia_min", GermVisual.CILIA_MIN)
	m.set_shader_parameter("cilia_max", GermVisual.CILIA_MAX)
	_material = m

	# Kontur keçidi. RGBA8 hədəf (HDR yox): koordinatlar baytlara bölünür, float
	# render hədəfi isə hər yerdə yoxdur. Kökün övladı olduğu üçün Godot onu
	# əsas pəncərədən ƏVVƏL çəkir — eyni kadrda hazır olur.
	var s := ShaderMaterial.new()
	s.shader = SHAPE_SHADER
	s.set_shader_parameter("data", _texture)
	s.set_shader_parameter("hit_knee", GermVisual.HIT_FIT_KNEE)
	s.set_shader_parameter("eject_half", Const.SHOT_RADIUS * GermVisual.EJECT_WIDTH)
	s.set_shader_parameter("crawl_lobe", GermVisual.CRAWL_LOBE)
	s.set_shader_parameter("uroid_bulge", GermVisual.UROID_BULGE)
	s.set_shader_parameter("crawl_waves", GermVisual.CRAWL_WAVES)
	s.set_shader_parameter("crawl_aim_bulge", GermVisual.CRAWL_AIM_BULGE)
	s.set_shader_parameter("crawl_area", GermVisual.CRAWL_AREA)
	s.set_shader_parameter("crawl_anchor", GermVisual.CRAWL_ANCHOR)
	s.set_shader_parameter("crawl_smooth", GermVisual.CRAWL_SMOOTH)
	_shape_material = s
	_shape_pass = SubViewport.new()
	_shape_pass.name = "GermShapePass"
	_shape_pass.use_hdr_2d = false
	_shape_pass.transparent_bg = true
	_shape_pass.disable_3d = true
	# Öz dünyası MƏCBURİDİR: SubViewport standart olaraq kökün World3D-sini bölüşür
	# və arenanın WorldEnvironment-i (canvas fonu + glow + tonemap) onun baytlarına
	# da tətbiq olunurdu — kodlanmış koordinatlar zibilə dönürdü (stenddə mühit yoxdur).
	_shape_pass.own_world_3d = true
	# Hər texel hər kadr yenidən yazılır — təmizləmə boş işdir.
	_shape_pass.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	_shape_pass.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_shape_rect = ColorRect.new()
	_shape_rect.material = s
	_shape_pass.add_child(_shape_rect)
	_resize_shape_pass()
	m.set_shader_parameter("ring_tex", _shape_pass.get_texture())
	# Ağac bu an məşğul ola bilər (mikrobun `_ready`-si) — kadrın sonunda, çəkilişdən
	# əvvəl əlavə olunur.
	(Engine.get_main_loop() as SceneTree).root.add_child.call_deferred(_shape_pass)

	_driver = Driver.new()
	RenderingServer.frame_pre_draw.connect(_driver.flush)


static func _resize_shape_pass() -> void:
	_shape_pass.size = Vector2i(OUT_WIDTH, _cap)
	_shape_rect.size = Vector2(OUT_WIDTH, _cap)
	_shape_material.set_shader_parameter("grid", Vector2(OUT_WIDTH, _cap))


static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


## Mikrob sayı tutumu keçəndə tekstura iki dəfə böyüyür (material eyni qalır).
static func _grow() -> void:
	_cap *= 2
	_image = Image.create_empty(WIDTH, _cap, false, Image.FORMAT_RGBAF)
	_texture.set_image(_image)
	_resize_shape_pass()
	_dirty = true


## Növbədəki sətirləri yazır və teksturanı BİR dəfə yükləyir.
static func _flush() -> void:
	if _pending.is_empty() and not _dirty:
		return
	var t0 := Time.get_ticks_usec()
	for row in _pending:
		_queued[row] = 0
		var g: Object = _owners[row]
		if g != null and is_instance_valid(g):
			_rows[row] = g.gpu_row_bytes()
	_pending.clear()
	_dirty = false
	var t1 := Time.get_ticks_usec()
	var buf := PackedByteArray()
	for bytes in _rows:
		buf.append_array(bytes)
	buf.resize(WIDTH * TEXEL * _cap)
	_image.set_data(WIDTH, _cap, false, Image.FORMAT_RGBAF, buf)
	_texture.update(_image)
	spent_rows_usec += t1 - t0
	spent_upload_usec += Time.get_ticks_usec() - t1


## `frame_pre_draw` siqnalı statik funksiyaya birbaşa bağlanmır — bu kiçik obyekt
## onu ötürür.
class Driver extends RefCounted:
	func flush() -> void:
		GermGPU._flush()


class Layer extends Node2D:
	var mesh: Mesh

	func _draw() -> void:
		draw_mesh(mesh, null)


## Mesh-in təpələri (qat, indeks, rol) və üçbucaqları. Rolların mənası
## shaders/germ.gdshader-dədir; üçbucaqların SIRASI çəkiliş sırasıdır.
class Builder extends RefCounted:
	var verts := PackedVector2Array()
	var roles := PackedVector2Array()
	var tris := PackedInt32Array()

	func vert(layer: int, i: int, role: int) -> int:
		verts.append(Vector2(layer, i))
		roles.append(Vector2(role, 0.0))
		return verts.size() - 1

	func tri(a: int, b: int, c: int) -> void:
		tris.append(a)
		tris.append(b)
		tris.append(c)

	## Dörd künc (rollar `role0 .. role0 + 3`): SDF kvadratı və ya qalın xətt.
	func quad(layer: int, i: int, role0: int) -> void:
		var v := verts.size()
		for k in 4:
			vert(layer, i, role0 + k)
		tri(v, v + 1, v + 2)
		tri(v, v + 2, v + 3)

	## Mərkəzdən yelpik: rol 0 mərkəz, rol 1 konturun i-ci nöqtəsi.
	func fan(layer: int, n: int) -> void:
		var c := vert(layer, 0, 0)
		for i in n:
			vert(layer, i, 1)
		for i in n:
			tri(c, c + 1 + i, c + 1 + (i + 1) % n)

	## Kirpik — 6 nöqtəli lent: kök−, kök+, orta+, uc+, uc−, orta−.
	func ribbon(layer: int, i: int) -> void:
		var v := verts.size()
		for role in 6:
			vert(layer, i, role)
		tri(v, v + 1, v + 2)
		tri(v, v + 2, v + 5)
		tri(v + 5, v + 2, v + 3)
		tri(v + 5, v + 3, v + 4)

	## Qamçı — stansiya başına iki kənar (rol 0 sol, 1 sağ).
	func strip(layer: int, stations: int) -> void:
		var v := verts.size()
		for k in stations:
			vert(layer, k, 0)
			vert(layer, k, 1)
		for k in stations - 1:
			var p := v + k * 2
			tri(p, p + 1, p + 2)
			tri(p + 1, p + 2, p + 3)

	## Qapalı antialias-lı xətt (`stations` nöqtə, sonuncusu birincinin üstündə).
	## Godot-un üç zolağı ardıcıl: özək (0, 1), sol kənar (0, 2), sağ kənar (1, 3).
	func aa_loop(layer: int, stations: int) -> void:
		var v := verts.size()
		for k in stations:
			for role in 4:
				vert(layer, k, role)
		for pair in [[0, 1], [0, 2], [1, 3]]:
			_segments(v, 4, stations, pair[0], pair[1])

	## Açıq antialias-lı xətt — uclarında qapaq və künc kvadratları var
	## (stansiya başına 8 təpə; 4..7 yalnız birinci və sonuncuda işlənir).
	func aa_open(layer: int, i0: int, stations: int) -> void:
		var v := verts.size()
		var at := PackedInt32Array()
		for k in stations:
			at.append(verts.size())
			for role in 8:
				vert(layer, i0 + k, role)
		_open_strips(at, v, v + (stations - 1) * 8)

	## Uzunluğu dəyişən açıq xətt (rim). Adi stansiyalar yalnız dörd təpədir;
	## son qapaq isə AYRICA stansiyadır (indeks `stations`): shader onu qövsün
	## həqiqi sonuncusunun yerinə qoyur. Belə hər kadr bütün konturu gəzən təpə
	## sayı iki dəfə azdır.
	func aa_open_tail(layer: int, stations: int) -> void:
		var v := verts.size()
		var at := PackedInt32Array([v])
		for role in 8:
			vert(layer, 0, role)
		for k in range(1, stations):
			at.append(verts.size())
			for role in 4:
				vert(layer, k, role)
		var tail := verts.size()
		for role in 8:
			vert(layer, stations, role)
		_open_strips(at, v, tail)

	## Godot-un üç zolağı ardıcıl: özək (başlanğıc qapağı, seqmentlər, son qapaq),
	## sol kənar (başlanğıc küncü, seqmentlər, son künc), sağ kənar. `at` hər
	## stansiyanın rol 0 təpəsidir; `head` və `tail` qapaqlı stansiyalardır.
	func _open_strips(at: PackedInt32Array, head: int, tail: int) -> void:
		tri(head + 4, head + 5, head + 0)
		tri(head + 5, head + 0, head + 1)
		_strip(at, 0, 1)
		tri(tail + 0, tail + 1, tail + 4)
		tri(tail + 1, tail + 4, tail + 5)
		tri(head + 4, head + 6, head + 0)
		tri(head + 6, head + 0, head + 2)
		_strip(at, 0, 2)
		tri(tail + 2, tail + 0, tail + 6)
		tri(tail + 0, tail + 6, tail + 4)
		tri(head + 5, head + 7, head + 1)
		tri(head + 7, head + 1, head + 3)
		_strip(at, 1, 3)
		tri(tail + 3, tail + 1, tail + 7)
		tri(tail + 1, tail + 7, tail + 5)

	## Godot-un üçbucaq zolağı ilə eyni diaqonal: (a, b, a'), (b, a', b').
	func _strip(at: PackedInt32Array, a: int, b: int) -> void:
		for k in at.size() - 1:
			tri(at[k] + a, at[k] + b, at[k + 1] + a)
			tri(at[k] + b, at[k + 1] + a, at[k + 1] + b)

	func _segments(v: int, stride: int, stations: int, a: int, b: int) -> void:
		for k in stations - 1:
			var p := v + k * stride
			var q := p + stride
			tri(p + a, p + b, q + a)
			tri(p + b, q + a, q + b)

	func arrays() -> Array:
		var out := []
		out.resize(Mesh.ARRAY_MAX)
		out[Mesh.ARRAY_VERTEX] = verts
		out[Mesh.ARRAY_TEX_UV] = roles
		# Rəng massivi ağdır: shader öz rəngini mesh-in rənginə (yəni node-un
		# `modulate`-inə) vurur.
		var white := PackedColorArray()
		white.resize(verts.size())
		white.fill(Color.WHITE)
		out[Mesh.ARRAY_COLOR] = white
		out[Mesh.ARRAY_INDEX] = tris
		return out
