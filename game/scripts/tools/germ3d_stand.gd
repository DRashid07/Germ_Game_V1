extends Node2D
## Kirpiklinin 3D prototipinin MÜQAYİSƏ və ÖLÇÜ stendi (design/proto3d/README.md).
##
## Yalnız `--germ3d` ilə açılır (boot.gd) — adi açılış 3D resursu yükləmir. Oyunun qaydaları,
## serveri, protokolu dəyişmir: mikrob MÖVCUD [Sim]-də yaşayır, iki görüntü (indiki GPU 2D yolu
## — [GermVisual] və 3D prototip — [Germ3D]) eyni vəziyyəti oxuyur.
##
## Rejimlər:
##   müqayisə (susmaya görə) — solda 2D, sağda 3D (SubViewport, ortoqrafik kamera). Zaman xətti:
##     dayanma → üzmə → atəş → zərbə → aşağı ehtiyat → dolu → super → partlama → doğuş.
##     `--shot <prefiks>` hər mərhələdə şəkil saxlayır, `--germ3d-overlay` dəymə ellipsini çəkir.
##   ölçü — `--germ3d-bench N --germ3d-mode 2d|3d|3d-each [--germ3d-secs S]`: N mikrob, kadr,
##     proses və render vaxtı, çəkiliş çağırışı, yaddaş, ilk kadrın (shader) xərci, GPU vaxtı
##     (renderer dəstəkləyirsə). `3d` — hamısı BİR ortaq SubViewport-da, `3d-each` — hər mikroba
##     ayrıca SubViewport.
##
## Niyə ayrıca stend, arenaya qoşulma yox: prototip oyunun yükləmə və kadr yoluna heç nə
## əlavə etmir, eyni simulyasiya məlumatını oxuyur və iki görüntünü eyni kadrda yan-yana
## göstərir. Arenaya keçid yalnız ölçü və görüntü qəbul olunarsa düşünülməlidir.

const W := 1280
const H := 720
const SPECIES := Const.Species.CILIATE

var bench_n := 0
var bench_mode := "3d"
var bench_secs := 8.0
var shot_prefix := ""
var overlay := false

var _sim: Sim
var _ids: Array[int] = []
var _v2d: Array[GermVisual] = []
var _v3d: Array[Germ3D] = []
var _vps: Array[SubViewport] = []
var _rects: Array[TextureRect] = []
var _cam: Camera3D
var _vp: SubViewport
var _t := 0.0
var _focus := Vector2.ZERO
var _stage := ""
var _shots_done := {}
var _overlay_layer: Node2D

# ölçü
var _frames := PackedFloat32Array()
var _proc := PackedFloat32Array()
var _render := PackedFloat32Array()
var _draws := PackedInt32Array()
var _gpu := PackedFloat32Array()
var _first_ms := -1.0
var _t0_us := 0
var _built_us := 0
## Görüntünün kadr başına CPU işi (sinxronizasiya + animasiya node-ları), öz ölçümüz.
var _vis := PackedFloat32Array()


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	bench_n = int(_arg(args, "--germ3d-bench", "0"))
	bench_mode = _arg(args, "--germ3d-mode", "3d")
	bench_secs = float(_arg(args, "--germ3d-secs", "8"))
	shot_prefix = _arg(args, "--shot", "")
	overlay = args.has("--germ3d-overlay")
	RenderingServer.set_default_clear_color(Palette.DISH)
	_sim = Sim.new()
	_sim.obstacles.clear()
	_sim._reset_walls()
	var n := maxi(bench_n, 1)
	for i in n:
		var g := _sim.add_germ(100 + i, "G%d" % i, i % 10, false, SPECIES)
		g.safe_t = 0.0
		g.drain_t = 1.0e9
		g.balls = 7
		g.pos = _grid_pos(i, n)
		_ids.append(g.id)
	if bench_n > 0:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		# Görüntü 1 s sonra əlavə olunur: ondan sonrakı İLK kadr shader-lərin və resursların
		# ilk istifadəsinin xərcidir (mühərrikin açılışı ona qarışmır).
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			_build_bench()
			_built_us = Time.get_ticks_usec())
	else:
		_build_compare()
	_t0_us = Time.get_ticks_usec()


# ---------------------------------------------------------------- qurulma

func _build_compare() -> void:
	var g: Sim.GermState = _sim.germs[_ids[0]]
	_focus = g.pos
	# Sol: indiki 2D GPU yolu (arenadakı ilə eyni GermVisual).
	var v := GermVisual.new()
	v.setup(g.color, "", false, SPECIES)
	add_child(v)
	_v2d.append(v)
	# Sağ: 3D — ortaq SubViewport, ortoqrafik kamera mikrobu izləyir.
	_vp = _make_viewport(Vector2i(W / 2, H), W / 2)
	var rect := TextureRect.new()
	rect.texture = _vp.get_texture()
	rect.position = Vector2(W / 2, 0)
	add_child(rect)
	var g3 := Germ3D.new()
	_vp.add_child(g3)
	_v3d.append(g3)
	_add_props(_vp)
	var line := Line2D.new()
	line.points = PackedVector2Array([Vector2(W / 2, 0), Vector2(W / 2, H)])
	line.width = 2.0
	line.default_color = Palette.PANEL_BORDER
	add_child(line)
	for t in [["İNDİKİ 2D (GPU yolu)", 24.0], ["3D PROTOTİP (SubViewport)", W / 2 + 24.0]]:
		var l := Label.new()
		l.text = t[0]
		l.position = Vector2(t[1], 16.0)
		l.add_theme_font_size_override("font_size", 20)
		add_child(l)
	_overlay_layer = Node2D.new()
	_overlay_layer.z_index = 10
	_overlay_layer.draw.connect(_draw_overlay)
	add_child(_overlay_layer)


func _build_bench() -> void:
	var n := _ids.size()
	match bench_mode:
		"2d":
			for i in n:
				var g: Sim.GermState = _sim.germs[_ids[i]]
				var v := GermVisual.new()
				v.setup(g.color, "", false, SPECIES)
				add_child(v)
				_v2d.append(v)
		"3d-each":
			var side := 200
			for i in n:
				var vp := _make_viewport(Vector2i(side, side), side)
				var rect := TextureRect.new()
				rect.texture = vp.get_texture()
				add_child(rect)
				var g3 := Germ3D.new()
				vp.add_child(g3)
				_vps.append(vp)
				_rects.append(rect)
				_v3d.append(g3)
		_:
			_vp = _make_viewport(Vector2i(W, H), W)
			var rect := TextureRect.new()
			rect.texture = _vp.get_texture()
			add_child(rect)
			for i in n:
				var g3 := Germ3D.new()
				_vp.add_child(g3)
				_v3d.append(g3)
	for vp in _vps:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	if _vp != null:
		RenderingServer.viewport_set_measure_render_time(_vp.get_viewport_rid(), true)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


## 3D səhnə: öz dünyası, şəffaf fon (petri döşəməsi 2D-dədir), yuxarı-soldan işıq,
## ortoqrafik kamera ([param world_w] piksel en).
func _make_viewport(size: Vector2i, world_w: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = float(size.y) * float(world_w) / float(size.x)
	cam.near = 1.0
	cam.far = 2000.0
	cam.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	cam.position = Vector3(0.0, 600.0, 0.0)
	vp.add_child(cam)
	if _cam == null:
		_cam = cam
	vp.set_meta("cam", cam)
	var sun := DirectionalLight3D.new()
	# Yuxarı-soldan: işıq ekranın sağına (+X) və aşağısına (+Z) düşür.
	sun.rotation = Vector3(deg_to_rad(-62.0), deg_to_rad(-135.0), 0.0)
	sun.light_energy = 1.15
	vp.add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.75, 0.78)
	e.ambient_light_energy = 0.55
	env.environment = e
	vp.add_child(env)
	return vp


## Xəritə nümunələri: selik, kol (mikrobun üstündən örtür), kövrək qabıq.
func _add_props(vp: SubViewport) -> void:
	var src: Node = Germ3D.SCENE.instantiate()
	# Kol "bush" mərhələsində mikrobun üstünə düşür — örtülmə sırası yoxlanır (yarpaqlar ÜSTDƏ).
	var spots := {"Mucus": [Vector2(-170, 150), 70.0, 0.0], "Bush": [Vector2(70, -40), 62.0, 60.0],
		"Brittle": [Vector2(-160, -170), 55.0, 0.0]}
	for name in spots:
		var n := src.find_child(name, true, false) as MeshInstance3D
		if n == null:
			continue
		var mi := MeshInstance3D.new()
		mi.mesh = n.mesh
		for s in n.get_surface_override_material_count():
			mi.set_surface_override_material(s, n.get_active_material(s))
		var at: Vector2 = spots[name][0]
		var r: float = spots[name][1]
		mi.position = Vector3(_focus.x + at.x, float(spots[name][2]), _focus.y + at.y)
		mi.scale = Vector3(r, r, r)
		mi.set_meta("world", Vector2(_focus.x + at.x, _focus.y + at.y))
		vp.add_child(mi)
	src.free()


# ---------------------------------------------------------------- kadr

func _process(delta: float) -> void:
	if _finishing:
		return
	_t += delta
	var inputs := {}
	for i in _ids.size():
		inputs[_ids[i]] = _input_for(i)
	_sim.step(inputs, delta if delta < 0.1 else 0.1)
	_apply_events()
	if bench_n > 0:
		if _built_us == 0:
			return
		var t0 := Time.get_ticks_usec()
		_sync_bench()
		for v3 in _v3d:
			v3._process(0.0)
		for v in _v2d:
			v._process(0.0)
		_vis.append((Time.get_ticks_usec() - t0) / 1000.0)
		_measure(delta)
	else:
		_sync_compare()
		_compare_timeline()


## Zaman xətti (müqayisə rejimi) — mərhələlər və hərəkət.
func _input_for(i: int) -> Sim.PlayerInput:
	var g: Sim.GermState = _sim.germs.get(_ids[i])
	if g == null:
		return Sim.PlayerInput.make(0, Vector2.ZERO, 0.0, false)
	if bench_n > 0:
		var a := _t * 0.9 + float(i)
		var fire := fmod(_t + float(i) * 0.37, 1.6) < 0.05
		g.balls = 7
		return Sim.PlayerInput.make(0, Vector2.from_angle(a), a, fire)
	var move := Vector2.ZERO
	var aim := 0.3
	var fire := false
	match _stage:
		"swim":
			move = Vector2.from_angle(_t * 1.2)
			aim = _t * 1.2
		"fire":
			fire = true
			aim = 0.0
	return Sim.PlayerInput.make(0, move, aim, fire)


func _compare_timeline() -> void:
	var g: Sim.GermState = _sim.germs.get(_ids[0])
	var stages := [["idle", 2.0], ["swim", 3.0], ["fire", 1.2], ["hit", 1.0], ["low", 1.2],
		["full", 1.5], ["super", 1.0], ["bush", 1.2], ["burst", 1.0], ["spawn", 1.2]]
	var acc := 0.0
	var now := ""
	for s in stages:
		acc += float(s[1])
		if _t < acc:
			now = s[0]
			break
	if now == "":
		_finish()
		return
	if now != _stage:
		_stage = now
		_enter(now, g)
	# Davamlı halın şəkli mərhələnin ortasında, qısa hadisəninki (atəş, zərbə, super, partlama,
	# doğuş) ondan 0.1 s sonra — animasiya o vaxt görünür.
	var start := acc - _stage_len(now)
	var when := 0.10 if ["fire", "hit", "super", "burst", "spawn"].has(now) else _stage_len(now) * 0.55
	if now == "fire":
		when = 0.45
	if shot_prefix != "" and not _shots_done.has(now) and _t > start + when:
		_shots_done[now] = true
		get_viewport().get_texture().get_image().save_png("%s_%s.png" % [shot_prefix, now])
		print("[germ3d] şəkil: %s_%s.png" % [shot_prefix, now])


func _stage_len(name: String) -> float:
	return {"idle": 2.0, "swim": 3.0, "fire": 1.2, "hit": 1.0, "low": 1.2, "full": 1.5,
		"super": 1.0, "bush": 1.2, "burst": 1.0, "spawn": 1.2}[name]


func _enter(stage: String, g: Sim.GermState) -> void:
	if g == null:
		return
	match stage:
		"idle":
			g.balls = 7
		"hit":
			g.balls = 7
			# Həqiqi top: sağdan gəlir və serverin qaydası ilə dəyir (+2).
			var s := Sim.ShotState.new()
			s.id = 9000
			s.owner_id = -1
			s.color = 3
			s.pos = g.pos + Vector2(60.0, -8.0)
			s.dir = Vector2.LEFT
			s.life = 1.0
			s.payload = Const.SHOT_PAYLOAD
			_sim.shots.append(s)
		"low":
			g.balls = Const.FIRE_MIN_BALLS
		"full":
			g.balls = g.capacity - 1
		"super":
			g.balls = 8
			g.charge = Const.SUPER_MAX
			_sim._use_super(g)
		"bush":
			# Kolun altına: 3D-də yarpaqlar mikrobun ÜSTÜNDƏ olmalıdır (örtülmə sırası).
			g.balls = 7
			g.vel = Vector2.ZERO
			for c in _vp.get_children():
				if c is MeshInstance3D and c.has_meta("world") and c.mesh != null \
						and String(c.mesh.resource_name).to_lower().contains("bush"):
					g.pos = c.get_meta("world")
		"burst":
			for v in _v2d:
				v.flash()
			for v3 in _v3d:
				v3.burst()
		"spawn":
			g.balls = Const.START_BALLS
			for v3 in _v3d:
				v3.spawn()


## Simulyasiyanın hadisələri iki görüntüyə də ötürülür (atəş, zərbə, super).
func _apply_events() -> void:
	for e in _sim.events:
		var t: String = e.get("t", "")
		var pos: Vector2 = e.get("pos", Vector2.ZERO)
		var idx := _nearest_index(pos)
		if idx < 0:
			continue
		match t:
			"fire":
				if idx < _v3d.size():
					_v3d[idx].fire(float(e["arg"]))
				if idx < _v2d.size():
					_v2d[idx].eject(float(e["arg"]))
			"hit":
				if float(e.get("arg", 0.0)) > 0.5:
					var g: Sim.GermState = _sim.germs[_ids[idx]]
					if idx < _v3d.size():
						_v3d[idx].hit((pos - g.pos).angle())
					if idx < _v2d.size():
						_v2d[idx].flash((pos - g.pos).angle())
			"super":
				if idx < _v3d.size():
					_v3d[idx].super_fx()


func _nearest_index(pos: Vector2) -> int:
	var best := -1
	var bd := INF
	for i in _ids.size():
		var g: Sim.GermState = _sim.germs.get(_ids[i])
		if g == null:
			continue
		var d := g.pos.distance_to(pos)
		if d < bd:
			bd = d
			best = i
	return best


func _sync_compare() -> void:
	var g: Sim.GermState = _sim.germs.get(_ids[0])
	if g == null:
		return
	_focus = _focus.lerp(g.pos, 0.2)
	var left := Vector2(W / 4, H / 2)
	for v in _v2d:
		v.apply(left + g.pos - _focus, g.aim, g.balls, g.capacity, false, true, g.super_t > 0.0)
		v.net_vel = g.vel
	for v3 in _v3d:
		v3.sync(g.pos, g.vel, g.aim, g.balls, g.capacity)
	_cam.position = Vector3(_focus.x, 600.0, _focus.y)
	_overlay_layer.queue_redraw()


func _sync_bench() -> void:
	for i in _ids.size():
		var g: Sim.GermState = _sim.germs.get(_ids[i])
		if g == null:
			continue
		if i < _v2d.size():
			_v2d[i].apply(g.pos, g.aim, g.balls, g.capacity, false, true, false)
			_v2d[i].net_vel = g.vel
		if i < _v3d.size():
			_v3d[i].sync(g.pos if _vps.is_empty() else Vector2.ZERO, g.vel, g.aim, g.balls, g.capacity)
		if i < _rects.size():
			_rects[i].position = g.pos - Vector2(100, 100)
	if _cam != null and _vps.is_empty():
		_cam.position = Vector3(W * 0.5, 600.0, H * 0.5)


## Dəymə həndəsəsinin örtüyü: membranın ellipsi ([method Sim.hit_shape], top radiusu 0) —
## 2D-də mikrobun üstünə, 3D-də eyni ekran yerinə. Görüntü ondan çıxmamalıdır.
func _draw_overlay() -> void:
	if not overlay:
		return
	var g: Sim.GermState = _sim.germs.get(_ids[0])
	if g == null:
		return
	var shape := Sim.hit_shape(int(SPECIES), g.capacity, g.vel, 0.0)
	for c in [Vector2(W / 4, H / 2) + g.pos - _focus, Vector2(W * 3 / 4, H / 2) + g.pos - _focus]:
		var pts := PackedVector2Array()
		for k in 49:
			var a := TAU * float(k) / 48.0
			pts.append(c + Vector2(cos(a) * shape.x, sin(a) * shape.y).rotated(shape.z))
		_overlay_layer.draw_polyline(pts, Color(1.0, 0.3, 0.9, 0.9), 2.0, true)


func _grid_pos(i: int, n: int) -> Vector2:
	if n <= 1:
		return Vector2(640, 360)
	var cols := 5
	return Vector2(160 + (i % cols) * 240, 200 + (i / cols) * 300)


# ---------------------------------------------------------------- ölçü

func _measure(delta: float) -> void:
	var el := (Time.get_ticks_usec() - _built_us) / 1.0e6
	if _first_ms < 0.0:
		# Görüntü əlavə olunandan sonrakı ilk kadr — ilk shader istifadəsi.
		_first_ms = delta * 1000.0
		return
	if el < 1.0:
		_vis.clear()
		return
	_frames.append(delta * 1000.0)
	_proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	var rcpu := RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid())
	var rgpu := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
	for vp in _vps:
		rcpu += RenderingServer.viewport_get_measured_render_time_cpu(vp.get_viewport_rid())
		rgpu += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
	if _vp != null:
		rcpu += RenderingServer.viewport_get_measured_render_time_cpu(_vp.get_viewport_rid())
		rgpu += RenderingServer.viewport_get_measured_render_time_gpu(_vp.get_viewport_rid())
	_render.append(rcpu)
	_gpu.append(rgpu)
	_draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	if el >= 1.0 + bench_secs:
		_report()
		_finish()


func _report() -> void:
	var f := _frames.duplicate()
	f.sort()
	var gpu := _avg(_gpu)
	print("[germ3d] ölçü: %d mikrob, rejim %s, %d kadr (%s)" % [_ids.size(), bench_mode, f.size(),
		RenderingServer.get_video_adapter_name()])
	print("[germ3d]   kadr: orta %.2f ms (%.0f FPS), p99 %.2f, ən pis %.2f ms" % [_avg(_frames),
		1000.0 / maxf(_avg(_frames), 0.001), f[int(f.size() * 0.99)], f[-1]])
	print("[germ3d]   görüntünün CPU işi %.3f ms · render CPU %.3f ms · çəkiliş çağırışı orta %.1f, pik %d" % [
		_avg(_vis) / 2.0, _avg(_render), _avg_i(_draws), _max_i(_draws)])
	print("[germ3d]   yaddaş: statik %.1f MB · video %.1f MB · ilk istifadə kadrı %.1f ms" % [
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, _first_ms])
	print("[germ3d]   GPU: %s" % ("%.3f ms" % gpu if gpu > 0.0 else "ölçülmür (renderer 0 qaytarır — dəstəklənmir)"))


static func _avg(a: PackedFloat32Array) -> float:
	var s := 0.0
	for x in a:
		s += x
	return s / maxf(float(a.size()), 1.0)


static func _avg_i(a: PackedInt32Array) -> float:
	var s := 0
	for x in a:
		s += x
	return float(s) / maxf(float(a.size()), 1.0)


static func _max_i(a: PackedInt32Array) -> int:
	var m := 0
	for x in a:
		m = maxi(m, x)
	return m


static func _arg(args: PackedStringArray, key: String, fallback: String) -> String:
	var i := args.find(key)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else fallback


## Çıxış: 3D node-lar və paylaşılan kölgə teksturası əvvəl azad edilir — yoxsa mühərrik
## çıxışda "sızma" xəbərdarlıqları yazır və onlar həqiqi xətalarla qarışır.
var _finishing := false


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	for v3 in _v3d:
		v3.queue_free()
	for vp in _vps:
		vp.queue_free()
	if _vp != null:
		_vp.queue_free()
	Germ3D._shadow_tex = null
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0)
