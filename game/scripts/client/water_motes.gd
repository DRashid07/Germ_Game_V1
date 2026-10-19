class_name WaterMotes
extends Node2D
## Suda asılı qalmış zərrəciklər — qabın MAYE olduğunu göstərən qat.
##
## Oyunçu axını mikrobun sürüşməsindən hiss edir, amma GÖRMÜR: özü də,
## rəqib də hərəkət edir, ona görə sürüşməni idarəetmə xətası kimi oxumaq
## olar. Sərbəst zərrəciklər bu şübhəni aradan qaldırır — onların heç bir
## iradəsi yoxdur, yalnız su onları aparır.
##
## Zərrəciklər NÖQTƏ yox, CIZGI kimi çəkilir və cizgi məhz axının istiqaməti
## boyunca uzanır. Beləliklə qat eyni zamanda axın sahəsinin özünü çəkir:
## oyunçu burulğanı görür və ondan istifadə etməyi öyrənir.
##
## Bütün qat BİR [method CanvasItem.draw_multiline] çağırışıdır.
##
## Zərrəciklər GPU-da hərəkət edir ([GPUParticles2D], `shaders/water_motes.gdshader`):
## hər kadr 110 zərrəciyin axın sahəsini GDScript-də iki dəfə hesablamaq Android-də
## kadrın ən böyük tək skript xərci idi (emulyatorda ~1.1 ms). Formul, addım, kənardan
## keçmə və cizginin həndəsəsi eynidir; `--motes-cpu` köhnə yola qaytarır. İki yol
## eyni toxumla eyni düzümü qurur (bax [method _rand01]) — stend onları yan-yana
## müqayisə edə bilsin (`--germ-bench --bench-motes`).

## Zərrəciklər GPU-da. `--motes-cpu` — köhnə GDScript yolu (müqayisə və ehtiyat).
static var gpu := not OS.get_cmdline_user_args().has("--motes-cpu")

## Zərrəcik sayı. Kadr yükü deyil (bir çağırışdır), amma çoxu fonu
## "qar" kimi göstərir və mikrobların oxunmasına mane olur.
##
## İki qat arasında bölünür (bax [member depth]): 80 dərin, 30 səthə yaxın.
const COUNT := 110

## Zərrəciklər kameranın ətrafındakı bu kvadratda saxlanılır (yarı-en, ekran
## eninə nisbətdə). Kənara çıxan zərrəcik əks tərəfə keçir — dünyanın hər
## yerində eyni sıxlıq, sabit yaddaş.
const FIELD_FACTOR := 0.8
## Cizginin uzunluğu = axın sürəti × bu (saniyə). 0.85 seçilib: qısa cizgi
## nöqtəyə bənzəyir, uzunu isə yağış kimi görünür.
const STREAK := 0.85

## Kameranın mərkəzi və görünən sahənin UZUN kənarı — [Arena] hər kadr
## yeniləyir. Uzun kənar, çünki sahə kvadratdır: qısa kənarla ölçülsəydi,
## yatayda ekranın sol və sağ hissəsi zərrəciksiz qalardı.
var focus := Vector2.ZERO
var span := Const.VIEW_SPAN_BASE

## Bu qat nə qədər DƏRİNDƏDİR: 0 = səth, 1 = dib.
##
## Su bir qat deyil, SÜTUNDUR. Bütün zərrəciklər eyni parlaqlıqda və eyni
## sürətlə süzüləndə qat yastı bir "qar" kimi oxunur. İki dərinlik isə
## parallaks verir: dərindəkilər sönük, nazik və yavaş, səthdəkilər parlaq
## və sürətlidir. Göz fərqi ölçmür — DƏRİNLİK kimi oxuyur.
##
## Fərq qəsdən kiçikdir: yuxarıdan baxışda böyük parallaks "kamera səhv
## işləyir" hissi verir.
var depth := 0.0

## Neçə zərrəcik. İki qat arasında bölünür (bax [method Arena._build_world]).
var count := COUNT

## Cərəyan deşikləri `(x, y, radius)` — yalnız HIGH keyfiyyətdə Arena doldurur.
##
## Ayrı zərrəcik node-u qurulmur: sorulan cizgilər aşağıdakı mövcud su batch-inə
## əlavə olunur. LOW-da massiv boş qalır və həm hesab, həm görüntü tam sönür.
var sinks := PackedVector3Array()

## Düzümün toxumu: hər [method rebuild] yenisini seçir. Stend sabit verir
## ([member fixed_seed] ≥ 0) ki, iki yol eyni zərrəciklərlə başlasın.
var fixed_seed := -1
## Bu qat GPU-dadırmı — [method _ready]-dən əvvəl dəyişdirilə bilər (stend iki
## yolu yan-yana qoyur).
var use_gpu: bool = gpu

var _pos := PackedVector2Array()
var _seed := PackedFloat32Array()
var _ready_field := 0.0
var _flow_t := 0.0
var _seed_n := 0

var _particles: GPUParticles2D = null
var _mat: ShaderMaterial = null
static var _white: ImageTexture = null


func _ready() -> void:
	# `z_index` QƏSDƏN sıfır qalır. Mənfi qoysaq, zərrəciklər valideynin öz
	# `_draw`-ının — yəni qabın döşəməsinin — ALTINA düşər və tamamilə
	# görünməz olar (Godot-da uşağın z-i valideynin çəkilişinə nisbətdədir).
	# Sıfırda isə ağac sırası işləyir: döşəmə və maneələr altda, zərrəciklər
	# onların üstündə, qida və mikroblar isə sonrakı qatlarda.
	if use_gpu:
		_build_particles()
	rebuild()


## Sayı dəyişdikdən SONRA sahəni yenidən qurur.
##
## [member count] yalnız [method _ready]-də oxunur, ona görə ağaca girmiş
## node-da onu dəyişmək tək başına heç nə etmir. Keyfiyyət ayarı isə düymə ilə
## işlək vaxtı dəyişir (bax [method MenuV2._apply_quality]) və oyunçu fərqi
## elə həmin kadrda görməlidir — yoxsa düymə ölü sayılır.
func rebuild() -> void:
	_seed_n = fixed_seed if fixed_seed >= 0 else randi() % 100000
	_ready_field = span * FIELD_FACTOR
	if _particles != null:
		_mat.set_shader_parameter("seed", _seed_n)
		_mat.set_shader_parameter("focus", focus)
		_mat.set_shader_parameter("half_size", _ready_field)
		_particles.amount = count
		_particles.restart()
	else:
		_scatter()
	queue_redraw()


## Zərrəcikləri görüş sahəsinə bərabər səpir. Toxum və mövqe shader-in `start()`
## funksiyası ilə EYNİ heşdəndir (bax [method _rand01]).
func _scatter() -> void:
	var half := _ready_field
	_pos.resize(count)
	_seed.resize(count)
	for i in count:
		var base := i * 3 + _seed_n * 7919
		var r := Vector2(_rand01(base), _rand01(base + 1)) * 2.0 - Vector2.ONE
		_pos[i] = focus + r * half
		# Hər zərrəciyin öz fazası — hamısı eyni ritmdə titrəməsin.
		_seed[i] = _rand01(base + 2) * TAU


## 0..1 — PCG heşi, 32 bitlik tam ədəd hesabı ilə: shader-dəki `rand01` ilə eyni.
static func _rand01(x: int) -> float:
	var s := (x * 747796405 + 2891336453) & 0xFFFFFFFF
	var w := (((s >> ((s >> 28) + 4)) ^ s) * 277803737) & 0xFFFFFFFF
	w = (w >> 22) ^ w
	return float(w) / 4294967295.0


func _build_particles() -> void:
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/water_motes.gdshader")
	# Axının formulu `Const.current_at`-dır — shader onun sabitlərini buradan alır.
	_mat.set_shader_parameter("world_radius", Const.WORLD_RADIUS)
	_mat.set_shader_parameter("current_edge", Const.CURRENT_EDGE)
	_mat.set_shader_parameter("current_scale", Const.CURRENT_SCALE)
	_mat.set_shader_parameter("current_strength", Const.CURRENT_STRENGTH)
	_mat.set_shader_parameter("current_swirl", Const.CURRENT_SWIRL)
	_mat.set_shader_parameter("depth", depth)
	_mat.set_shader_parameter("streak", STREAK)
	_mat.set_shader_parameter("line_width", _line_width())
	_mat.set_shader_parameter("mote_color", _mote_color())
	if _white == null:
		var img := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white = ImageTexture.create_from_image(img)
	_particles = GPUParticles2D.new()
	_particles.process_material = _mat
	# 1×1 ağ tekstura — shader onu cizginin düzbucaqlısına uzadır.
	_particles.texture = _white
	_particles.amount = count
	# Zərrəcik ölmür: hamısı bir anda doğulur, sonra yalnız axınla gəzir.
	_particles.lifetime = 3600.0
	_particles.explosiveness = 1.0
	# Hər kadr, kadrın öz addımı ilə — GDScript yolu kimi. 30 Hz + interpolyasiya
	# cizginin uzunluğunu iki vəziyyət arasında qarışdırardı.
	_particles.fixed_fps = 0
	_particles.interpolate = false
	# Node-a nisbətən: arenada node mərkəzdədir (dünya = yerli), stend isə iki
	# yolu yan-yana qoymaq üçün node-u sürüşdürür.
	_particles.local_coords = true
	_particles.draw_order = GPUParticles2D.DRAW_ORDER_INDEX
	# Sahə kameranı izləyir, ona görə kəsmə düzbucaqlısı bütün dünyanı örtür.
	_particles.visibility_rect = Rect2(-100000.0, -100000.0, 200000.0, 200000.0)
	# Zərrəciklər node-un öz `_draw`-ından (deşik axını) ƏVVƏL çəkilir — köhnə
	# yolda da eyni batch-də əvvəl gəlirdilər.
	_particles.show_behind_parent = true
	add_child(_particles)


## Şüşə kənarının rəngindən bir az açıq: fonun içində qalmalıdır, amma
## görünməlidir. Dərin qat sönük və nazikdir.
func _mote_color() -> Color:
	var col := Palette.DISH_EDGE.lerp(Palette.TEXT, 0.30 - 0.12 * depth)
	return Color(col, 0.40 - 0.16 * depth)


func _line_width() -> float:
	return 1.8 - 0.5 * depth


func _process(delta: float) -> void:
	_flow_t += delta
	var half := span * FIELD_FACTOR
	# Kamera uzaqlaşanda sahə genişlənir; birdən-birə deyil, tədricən —
	# əks halda böyüyən mikrobun ətrafında zərrəciklər peyda olardı.
	_ready_field = lerpf(_ready_field, half, clampf(delta * 1.5, 0.0, 1.0))
	half = _ready_field
	# Broun hərəkətinin fazası oyun saatından: iki yol eyni kadrda eyni fazanı
	# işlədir (əvvəl divar saatı idi — görüntüdə fərqi yoxdur).
	var jitter_phase := fposmod(_flow_t * 0.4, TAU)

	if _particles != null:
		_mat.set_shader_parameter("focus", focus)
		_mat.set_shader_parameter("half_size", half)
		_mat.set_shader_parameter("jitter_phase", jitter_phase)
		_mat.set_shader_parameter("step_dt", delta)
		# Node-un öz çəkilişində yalnız deşik axını qalıb.
		if not sinks.is_empty():
			queue_redraw()
		return

	for i in _pos.size():
		var p: Vector2 = _pos[i]
		# Broun hərəkəti: su molekullarının təsadüfi zərbələri. Zəifdir, amma
		# olmasa zərrəciklər riyazi düzgünlükdə süzülür və süni görünür.
		var jitter := Vector2.from_angle(_seed[i] + jitter_phase) * 6.0
		# Dərin qat daha yavaş sürüşür — parallaks buradan gəlir.
		p += (Const.current_at(p) * (1.0 - 0.42 * depth) + jitter) * delta

		# Görüş kvadratından çıxan zərrəcik əks kənardan qayıdır.
		var d := p - focus
		if absf(d.x) > half:
			p.x -= signf(d.x) * half * 2.0
		if absf(d.y) > half:
			p.y -= signf(d.y) * half * 2.0
		_pos[i] = p

	queue_redraw()


func _draw() -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var mote_col := _mote_color()
	for i in (_pos.size() if _particles == null else 0):
		var p: Vector2 = _pos[i]
		var flow := Const.current_at(p)
		# Axının dayandığı yerdə (mərkəz, şüşənin dibi) cizgi nöqtəyə enir —
		# orada su sakitdir və bunu göstərmək lazımdır.
		var tail := flow * STREAK
		if tail.length_squared() < 0.25:
			tail = Vector2(0.9, 0.0)
		pts.push_back(p)
		pts.push_back(p - tail)
		cols.push_back(mote_col)

	# Deşiyə sorulma spiral + radial hərəkətdir. Nöqtə deyil, qısa iz çəkilir
	# ki, axının istiqaməti tək kadrda da oxunsun. Hər ventdə yeddi cizgi
	# kifayətdir; daha çoxu burulğan sprite-ını örtüb deşiyi qapadırdı.
	for vi in sinks.size():
		var sink: Vector3 = sinks[vi]
		var centre := Vector2(sink.x, sink.y)
		for j in 7:
			var phase := fposmod(_flow_t * 0.46 + float(j) / 7.0 + float(vi) * 0.13, 1.0)
			var dist := sink.z * lerpf(0.22, 1.08, 1.0 - phase)
			var angle := _flow_t * 0.92 + float(j) * 2.39996 + phase * 2.8
			var radial := Vector2.from_angle(angle)
			var tangent := radial.orthogonal()
			var p := centre + radial * dist
			# Quyruq hərəkətin əksinə — çölə və bir az saat istiqamətinin əksinə.
			var tail := radial * (5.0 + 7.0 * phase) - tangent * 5.0
			pts.push_back(p)
			pts.push_back(p + tail)
			cols.push_back(Color(Palette.VENT.lerp(Palette.TEXT, 0.28),
				0.16 + 0.30 * (1.0 - phase)))

	# Rəng massivinə keçmək əlavə çağırış yaratmır: adi su cizgiləri ilə isti
	# vent axını eyni multiline batch-də qalır (GPU yolunda zərrəciklər ayrıca
	# bir çağırışdır, burada yalnız deşik axını qalır).
	if not pts.is_empty():
		draw_multiline_colors(pts, cols, _line_width())
