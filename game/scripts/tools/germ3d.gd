class_name Germ3D
extends Node3D
## Kirpiklinin 3D vizual PROTOTİPİ — bir mikrob (design/proto3d/README.md, eksperiment).
##
## Oyunun qaydalarına toxunmur və adi açılışda yüklənmir: yalnız `--germ3d` stendi
## ([code]tools/germ3d_stand.gd[/code]) yaradır. Model Blender skriptindən gəlir
## (design/proto3d/build_ciliate3d.py → assets/proto3d/ciliate3d.glb) — prosedur modeldir,
## rəssam asset-i deyil.
##
## Vəziyyət MÖVCUD simulyasiyadan gəlir ([method sync]): mövqe, radius, sürət, nişan, top sayı;
## hadisələr (atəş, zərbə, super, doğuş, partlama) ayrıca çağırışlardır. 3D fizika, ayrıca döyüş
## və ya protokol yoxdur.
##
## Koordinat: 2D dünya (x, y) → 3D (x, 0, y), kamera yuxarıdan ortoqrafik baxır. Görünən
## membran 2D dəymə həndəsəsinə uyğundur: [b]Deform[/b] node-u [method Sim.hit_shape]-in
## ellipsini (radius, sürət boyu dartılma, yana sıxılma) affin çevirmə kimi verir, gövdə isə
## onun içində nişana dönür — məsamə, kirpiklər və qamçı nişanı izləyir, silüet ellipsi.
##
## Animasiyalar prosedurdur (vəziyyətdən hesablanır): nəfəs və maye yellənməsi, sürətə görə
## kirpik ritmi (metaxron dalğa), qamçının gecikən dalğası (5 sümüklü armatura), yumşaq dönmə,
## atəşdə məsamənin açılması və qısa geri təpmə, zərbə istiqamətində sıxılma, doğuş, dolu
## membranın gərginliyi və partlama, superdə (trixosist) kirpiklərin atılması.

const SCENE := preload("res://assets/proto3d/ciliate3d.glb")
const JELLY := preload("res://shaders/proto3d_jelly.gdshader")
const CILIA := 36
const BALLS_MAX := 40
## Atəşdə məsamənin açılma müddəti — topun özü serverin hadisəsi ilə ANINDA yaranır.
const FIRE_TIME := 0.18
const HIT_TIME := 0.26
const SPAWN_TIME := 0.40
const BURST_TIME := 0.45
const SUPER_TIME := 0.35

var radius := 28.0
var _deform: Node3D
var _turn: Node3D
var _body: MeshInstance3D
var _mat: ShaderMaterial
var _cilia: MultiMeshInstance3D
var _balls: MultiMeshInstance3D
var _skel: Skeleton3D
var _shadow: MeshInstance3D
var _bones := PackedInt32Array()
var _up_axes: Array[Vector3] = []
var _keys := {}

var _vel := Vector2.ZERO
var _aim := 0.0
var _yaw := 0.0
var _speed_k := 0.0
var _balls_n := 0
var _cap := 10
var _t := 0.0
var _beat := 0.0
var _fire_t := 10.0
var _fire_dir := 0.0
var _hit_t := 10.0
var _hit_dir := 0.0
var _spawn_t := 10.0
var _burst_t := -1.0
var _super_t := 10.0
var _flag_phase := 0.0
var _seed := 0.0


func _init() -> void:
	_seed = randf() * 10.0


func _ready() -> void:
	var src: Node = SCENE.instantiate()
	_deform = Node3D.new()
	add_child(_deform)
	_turn = Node3D.new()
	_deform.add_child(_turn)
	_body = _take(src, "Body")
	_mat = ShaderMaterial.new()
	_mat.shader = JELLY
	_body.material_override = _mat
	_turn.add_child(_body)
	for i in _body.mesh.get_blend_shape_count():
		_keys[String(_body.mesh.get_blend_shape_name(i))] = i
	var pore := _take(src, "Pore")
	_turn.add_child(pore)
	var nucleus := _take(src, "Nucleus")
	_turn.add_child(nucleus)
	var rig: Node3D = src.find_child("FlagellumRig", true, false)
	if rig != null:
		_unown(rig)
		rig.get_parent().remove_child(rig)
		rig.transform = Transform3D.IDENTITY
		rig.position = Vector3(-1.02, 0.0, 0.0)
		_turn.add_child(rig)
		_skel = rig.find_child("*", true, false) as Skeleton3D
		if _skel == null:
			for c in rig.get_children():
				if c is Skeleton3D:
					_skel = c
		if _skel != null:
			for i in 5:
				var bi := _skel.find_bone("seg%d" % i)
				_bones.append(bi)
				var axis := Vector3.UP
				if bi >= 0:
					axis = (_skel.get_bone_global_rest(bi).basis.inverse() * Vector3.UP).normalized()
				_up_axes.append(axis)
	var cil := _take(src, "Cilium")
	_cilia = _multi(cil.mesh, CILIA)
	cil.free()
	_turn.add_child(_cilia)
	var bl := _take(src, "Ball")
	_balls = _multi(bl.mesh, BALLS_MAX)
	bl.free()
	_turn.add_child(_balls)
	src.free()
	# Kölgə: aşağı-sağa yumşaq ləkə — yuxarı-soldan gələn işığın kölgəsi (2D yol da belədir).
	_shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(2.4, 2.4)
	quad.orientation = PlaneMesh.FACE_Y
	_shadow.mesh = quad
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_texture = _shadow_texture()
	sm.albedo_color = Color(0.0, 0.0, 0.0, 0.42)
	_shadow.material_override = sm
	add_child(_shadow)
	_place_cilia(0.0)
	spawn()


## Vəziyyət simulyasiyadan: [param pos] dünya mövqeyi, [param vel], [param aim] (radian, 2D),
## top sayı və tutum.
func sync(pos: Vector2, vel: Vector2, aim: float, balls: int, capacity: int) -> void:
	position = Vector3(pos.x, 0.0, pos.y)
	_vel = vel
	_aim = aim
	_balls_n = balls
	_cap = maxi(capacity, 1)
	radius = Const.germ_radius(capacity)
	_speed_k = clampf(vel.length() / maxf(Const.germ_speed(capacity), 1.0), 0.0, 1.0)


## Atəş: məsamə açılır, gövdə qısa geri təpir. Top ANINDA yaranır — hazırlıq gecikməsi yoxdur.
func fire(angle: float) -> void:
	_fire_t = 0.0
	_fire_dir = angle


## Zərbə: gələn istiqamət boyu sıxılma və parıltı. [param from] — topun gəldiyi tərəf (radian).
func hit(from: float) -> void:
	_hit_t = 0.0
	_hit_dir = from


func spawn() -> void:
	_spawn_t = 0.0
	_burst_t = -1.0
	visible = true


func burst() -> void:
	_burst_t = 0.0


## Kirpiklinin superi (trixosist): kirpiklər iynə kimi atılır, ağ parıltı.
func super_fx() -> void:
	_super_t = 0.0


func _process(delta: float) -> void:
	_t += delta
	_fire_t += delta
	_hit_t += delta
	_spawn_t += delta
	_super_t += delta
	if _burst_t >= 0.0:
		_burst_t += delta
	# Yumşaq dönmə: gövdə nişana gecikmə ilə dönür (anında yox).
	_yaw = lerp_angle(_yaw, _aim, 1.0 - exp(-12.0 * delta))
	# Kirpik ritmi sürətlə artır (2 → 9 Hz).
	_beat += delta * TAU * lerpf(2.0, 9.0, _speed_k)
	_flag_phase += delta * TAU * lerpf(1.2, 5.0, _speed_k)

	var fill := float(_balls_n) / float(_cap)
	var r := radius
	# ── Deform: 2D dəymə ellipsi (sürət boyu) + zərbədə sıxılma ──
	# Membranın özü — dəymə ellipsindən top radiusu çıxılmış (shot_r 0): [method Sim.hit_shape].
	var shape := Sim.hit_shape(int(Const.Species.CILIATE), _cap, _vel, 0.0)
	var m := _ellipse_basis(shape.z, shape.x, r, shape.y)
	if _hit_t < HIT_TIME:
		var k := sin(_hit_t / HIT_TIME * PI) * 0.18
		m = _ellipse_basis(_hit_dir, 1.0 - k, 1.0, 1.0 + k * 0.6) * m
	var grow := 1.0
	if _spawn_t < SPAWN_TIME:
		var u := _spawn_t / SPAWN_TIME
		grow = 1.0 - pow(1.0 - u, 3.0) + sin(u * PI) * 0.12
	if _burst_t >= 0.0:
		var u := clampf(_burst_t / BURST_TIME, 0.0, 1.0)
		grow = 1.0 + u * 0.45
		visible = u < 1.0
	_deform.basis = m.scaled(Vector3(grow, grow, grow))
	# Geri təpmə: atəş istiqamətinin əksinə qısa sürüşmə (yalnız görüntü).
	var kick := 0.0
	if _fire_t < FIRE_TIME:
		kick = sin(_fire_t / FIRE_TIME * PI) * 0.12
	_deform.position = Vector3(-cos(_fire_dir), 0.0, -sin(_fire_dir)) * kick * r
	# ── Gövdə nişana döner; əsas forma dairəyə qaytarılır ki, silüet ellipsi olsun ──
	_turn.rotation = Vector3(0.0, -_yaw, 0.0)
	# Modelin uzunluğu (x 1.12) dairəyə qaytarılır; hündürlük Deform-da r ilə vurulur.
	_turn.scale = Vector3(1.0 / 1.12, 1.0, 1.0)
	# ── Şəkil açarları ──
	_key("Breath", 0.5 + 0.5 * sin(_t * 1.7 + _seed))
	_key("Fire", sin(clampf(_fire_t / FIRE_TIME, 0.0, 1.0) * PI) if _fire_t < FIRE_TIME else 0.0)
	_key("Tension", clampf((fill - 0.5) / 0.5, 0.0, 1.0) * 0.5)
	_key("Squash", 0.0)
	# ── Material: dolu → dartılmış parlaq kənar; az → solğun; partlama həddi → nəbz ──
	_mat.set_shader_parameter("tension", clampf((fill - 0.5) / 0.5, 0.0, 1.0))
	_mat.set_shader_parameter("low", clampf((float(Const.FIRE_MIN_BALLS + 1) - float(_balls_n)) / 3.0, 0.0, 1.0))
	var danger := 0.0
	if fill >= 0.85:
		danger = 0.5 + 0.5 * sin(_t * 12.0)
	_mat.set_shader_parameter("danger", danger)
	var flash := 0.0
	if _hit_t < HIT_TIME:
		flash = (1.0 - _hit_t / HIT_TIME) * 0.6
	if _super_t < SUPER_TIME:
		flash = maxf(flash, (1.0 - _super_t / SUPER_TIME) * 0.8)
	_mat.set_shader_parameter("flash", flash)
	_place_cilia(delta)
	_place_balls(fill)
	_wave_flagellum()
	# Kölgə: yuxarı-soldan işıq → aşağı-sağa.
	_shadow.position = Vector3(0.16 * r, -0.9 * r, 0.20 * r)
	_shadow.scale = Vector3(shape.x / 1.2, 1.0, shape.y / 1.2) * grow
	scale = Vector3(1.0, 1.0, 1.0)


## Kirpiklər gövdənin kənarında, nişana görə sabit: hər biri öz fazası ilə döyünür
## (metaxron dalğa). Superdə iynə kimi uzanır.
func _place_cilia(_delta: float) -> void:
	var mm := _cilia.multimesh
	var shoot := 0.0
	if _super_t < SUPER_TIME:
		shoot = sin(_super_t / SUPER_TIME * PI)
	for i in CILIA:
		var a := TAU * float(i) / float(CILIA)
		var out := Vector3(cos(a) * 1.10, 0.0, sin(a))
		var swing := sin(_beat - a * 3.0) * lerpf(0.25, 0.75, _speed_k)
		# Kirpik +Y boyu modellənib (glTF-də yuxarı) — əvvəl çölə yatırılır, sonra döyünür.
		# Kirpik glTF-də +Y boyudur: əvvəl +X-ə yatırılır, sonra kənara çevrilir və döyünür.
		var b := Basis(Vector3.BACK, -PI * 0.5)
		b = Basis(Vector3.UP, -a) * b
		b = Basis(Vector3(-sin(a), 0.0, cos(a)), swing) * b
		var length := 1.0 + shoot * 1.6
		mm.set_instance_transform(i, Transform3D(b * Basis.from_scale(Vector3(1.0, length, 1.0)), out))


## Daxili toplar: top sayı qədər, gövdənin içində spiral düzümlə; dolduqca sıxlaşır.
func _place_balls(fill: float) -> void:
	var mm := _balls.multimesh
	var n := mini(_balls_n, BALLS_MAX)
	mm.visible_instance_count = n
	for i in n:
		var u := (float(i) + 0.5) / float(maxi(n, 1))
		var rr := sqrt(u) * lerpf(0.55, 0.78, fill)
		var a := float(i) * 2.39996 + _t * 0.4
		var p := Vector3(cos(a) * rr + 0.1, 0.05 * sin(_t * 2.0 + float(i)), sin(a) * rr)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))


## Qamçı: gecikən dalğa — hər sümük bir az gec yellənir, amplituda sürətlə böyüyür.
func _wave_flagellum() -> void:
	if _skel == null:
		return
	var amp := lerpf(0.12, 0.45, _speed_k)
	for i in _bones.size():
		if _bones[i] < 0:
			continue
		var ang := sin(_flag_phase - float(i) * 0.9) * amp * (0.5 + 0.5 * float(i) / 4.0)
		# Dünyanın "yuxarı"sı sümüyün öz rest fəzasında — dalğa kamera müstəvisində qalır.
		var rest := _skel.get_bone_rest(_bones[i])
		_skel.set_bone_pose_rotation(_bones[i], rest.basis.get_rotation_quaternion()
			* Quaternion(_up_axes[i], ang))


func _key(name: String, w: float) -> void:
	if _keys.has(name):
		_body.set_blend_shape_value(_keys[name], w)


## Sürət istiqamətində [param a], ona dik [param b], hündürlük [param h] — XZ müstəvisində
## affin ellips (2D bucaq [param angle] → 3D-də Y ətrafında −angle).
static func _ellipse_basis(angle: float, a: float, h: float, b: float) -> Basis:
	var rot := Basis(Vector3.UP, -angle)
	return rot * Basis.from_scale(Vector3(a, h, b)) * rot.inverse()


## Başqa səhnədən köçürülən node-un sahibi sıfırlanır (Godot-un "owner inconsistent" xəbərdarlığı).
static func _unown(n: Node) -> void:
	n.owner = null
	for c in n.get_children():
		_unown(c)


static func _take(src: Node, name: String) -> MeshInstance3D:
	var n := src.find_child(name, true, false) as MeshInstance3D
	var mi := MeshInstance3D.new()
	mi.name = name
	if n != null:
		mi.mesh = n.mesh
		mi.transform = n.transform
		for s in n.get_surface_override_material_count():
			mi.set_surface_override_material(s, n.get_active_material(s))
		if n.skin != null:
			mi.skin = n.skin
	return mi


static func _multi(mesh: Mesh, count: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	return mi


static var _shadow_tex: Texture2D = null


static func _shadow_texture() -> Texture2D:
	if _shadow_tex == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_shadow_tex = t
	return _shadow_tex
