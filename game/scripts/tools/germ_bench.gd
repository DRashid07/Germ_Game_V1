extends Node2D
## Mikrob stendi — çəkilişin qiymətini və görüntüsünü TƏKRARLANAN şəkildə ölçür.
##
##   Godot_v4.7.2.exe --path game --resolution 1280x720 --disable-vsync -- \
##       --germ-bench [--bench-species 0|1|2|mix] [--bench-count 10] \
##       [--bench-lod 0|1] [--bench-secs 8] [--bench-render gpu|cpu|pair]
##
## `gpu` oyunun öz yoludur ([GermGPU]), `cpu` köhnə GDScript çəkilişi
## (`--germ-cpu` ilə oyunda da belədir), `--bench-lod` yalnız ona aiddir.
##
## Oyunda mikrobun ölçüsü, sürəti, top sayı və hadisələri (atəş, zərbə,
## doğuş, təhlükə, hazır super) hər an dəyişir; məşq ssenarisində isə ekrana
## düşən mikrob sayı təsadüfidir. Bu stend eyni dəstəni HƏR DƏFƏ eyni cür
## qurur: N mikrob ekranda dairə üzrə gedir (sürət 0-dan tam sürətə qədər
## paylanır), növbə ilə atəş açır, zərbə yeyir, bəziləri dolub təhlükəyə
## düşür, bəzilərinin superi hazırdır.
##
## Sonda kadrın işi yazılır: məntiq (`_process` + `_draw`) və mühərrikin
## render-i ayrıca. `--fixed-fps 60` ilə kadr deterministik olur — eyni kadr
## nömrəsi hər dəfə eyni şəkli verir (`--shot` ilə görüntü müqayisəsi).
##
## `--bench-render pair`: hər mikrob iki dəfə çəkilir — solda bugünkü yol
## (GDScript `_draw`), sağda GPU yolu — eyni vəziyyətdə, eyni anda. Görüntü
## bərabərliyi məhz belə yoxlanılır (bax design/PERF_PLAN.md, F1).

var species_arg := "mix"
var count := 10
var lod := 0
var secs := 8.0
var render_mode := "gpu"
## Hər kadr GPU-nun qurduğu konturları GDScript yolunun konturları ilə müqayisə et
## (`--bench-verify`). Geri oxuma kadrı yavaşladır — ölçmə ilə birlikdə işlətmə.
var verify := false
var _err := {}
## Mikroblar bu qədər saniyə gec yaradılır (`--bench-delay`), əvvəlcə isə shader-lər
## isidilir (`--bench-warm`) — ilk kompilyasiyanın donmasını ayrıca görmək üçün.
var delay := 0.0
var warm := false
## Mikrob əvəzinə su zərrəcikləri — iki yol yan-yana (`--bench-motes`).
var motes := false
## Mikrob əvəzinə superin açılış effekti (`--bench-superfx`): `pair` — solda
## GDScript, sağda GPU, hər növdən biri; `cpu` / `gpu` — ekranda 12 effekt hər
## 0.3 saniyədə yenidən doğulur (eyni anda ~36), qiyməti ölçmək üçün.
## `--bench-light` — aşağı keyfiyyətin 12 iynəsi (telefonun ilkin keyfiyyəti budur).
var superfx := false
var superfx_light := false
var _fx_left := 0.0
var _fx_k := 0
var _born_frame := -1
var _born_worst := 0.0

const WARMUP := 1.5

var _germs: Array = []          ## [GermVisual, faza, orbit radiusu, sürət payı]
var _twins: Array = []          ## pair rejimində sağdakı nüsxələr
var _t := 0.0
var _measured := 0.0
var _frames := 0
var _busy := 0.0
var _proc := 0.0
var _rend := 0.0
var _worst := 0.0
var _draws_peak := 0
## Videokartın kadr vaxtı (Godot-un ölçüsü; dəstəklənmirsə 0 qalır).
var _gpu := 0.0
## İsinmədəki ən pis kadr (ms) — shader-lərin ilk kompilyasiyası məhz orada olur.
var _warm_worst := 0.0
var _warm_worst_at := 0
var _t0 := -1
var _t_proc := -1
var _t_pre := -1


func _ready() -> void:
	# Brauzerdə "Oyun hazırlanır…" örtüyü stendi örtməsin (bax [method Settings.web_page_ready]).
	Settings.web_page_ready()
	var bg := ColorRect.new()
	bg.color = Palette.DISH
	bg.size = Vector2(8000, 8000)
	bg.position = Vector2(-4000, -4000)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var cam := Camera2D.new()
	add_child(cam)
	cam.make_current()

	# Arenanın glow mühiti (bax [method Arena._build_glow]) — həm görüntü oyundakı
	# kimi olsun, həm də mühit GPU-nun kontur keçidinə sızsa `--bench-verify` bunu
	# tutsun: bir dəfə məhz belə olmuşdu və stend onu görməmişdi.
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.62
	env.glow_intensity = 1.15
	env.glow_strength = 1.20
	env.glow_bloom = 0.14
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)

	# Shader-lərin ilk kompilyasiyasını ölçmək: mikroblar gec yaradılır, isinmə isə
	# (bax [method GermGPU.warm_up]) ondan əvvəl — menyudan arenaya keçid kimi.
	if warm:
		GermGPU.warm_up(self)
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
		_born_frame = Engine.get_frames_drawn()

	var vp := get_viewport_rect().size
	if motes:
		_build_motes(vp)
	if superfx:
		count = 0
	var cols := maxi(1, int(ceil(sqrt(float(count) * vp.x / vp.y))))
	var rows := int(ceil(float(count) / float(cols)))
	var pair := render_mode == "pair"
	# Pair rejimində ekran iki yarıdır: sol — bugünkü yol, sağ — GPU yolu.
	var area := Vector2(vp.x * (0.5 if pair else 1.0), vp.y)
	var cell := Vector2(area.x / float(cols), area.y / float(rows))
	for i in count:
		var kind := _species_for(i)
		var cap: int = [10, 14, 18, 24, 30, 38, 46, 60][i % 8]
		# Sahə ekranın SOL kənarından başlayır: pair rejimində sol yarım köhnə yol,
		# ikizlər isə düz yarım ekran sağda.
		var cr := Vector2(float(i % cols) + 0.5, float(i / cols) + 0.5) * cell - vp * 0.5
		var g := _make(i, kind, cap, render_mode == "gpu")
		g.position = cr
		add_child(g)
		_germs.append([g, cr, float(i) * 0.77, minf(cell.x, cell.y) * 0.16,
			fposmod(float(i) * 0.37, 1.0)])
		if pair:
			var twin := _make(i, kind, cap, true)
			twin.position = cr + Vector2(vp.x * 0.5, 0.0)
			add_child(twin)
			_twins.append(twin)

	get_tree().physics_frame.connect(_on_phys)
	get_tree().process_frame.connect(_on_proc)
	RenderingServer.frame_pre_draw.connect(_on_pre)
	RenderingServer.frame_post_draw.connect(_on_post)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	print("[bench] %d mikrob, növ %s, lod %d, render %s (GPU yolu %s)" % [count, species_arg,
		lod, render_mode, "açıq" if GermGPU.supported() else "bağlı"])


## `--bench-motes`: su zərrəcikləri yan-yana — solda GDScript yolu, sağda GPU
## (bax [WaterMotes]). Arenadakı kimi iki qat (dərin 80, səth 30 + deşik axını),
## eyni toxum və eyni addım: `--fixed-fps 60` ilə iki yarım eyni kadrı verməlidir.
## Mikroblar əlavə olunmur (`--bench-count 0` mənasında).
func _build_motes(vp: Vector2) -> void:
	count = 0
	var half := minf(vp.x * 0.25, vp.y * 0.5) - 8.0
	for side in 2:
		for deep in [true, false]:
			var m := WaterMotes.new()
			m.use_gpu = side == 1
			m.depth = 1.0 if deep else 0.0
			m.count = 80 if deep else 30
			m.fixed_seed = 11 if deep else 23
			m.span = half / WaterMotes.FIELD_FACTOR
			m.position = Vector2(vp.x * (0.25 if side == 1 else -0.25), 0.0)
			if not deep:
				m.sinks = PackedVector3Array([Vector3(half * 0.3, half * 0.2, 60.0)])
			add_child(m)


func _species_for(i: int) -> Const.Species:
	match species_arg:
		"0":
			return Const.Species.CILIATE
		"1":
			return Const.Species.HELIOZOAN
		"2":
			return Const.Species.AMOEBA
	return Const.species_from(i % 3)


func _make(i: int, kind: Const.Species, cap: int, gpu: bool) -> GermVisual:
	var g := GermVisual.new()
	g.setup(i % 10, "Mikrob %d" % i, i == 0, kind)
	g.gpu_allowed = gpu
	# Arenadakı kimi: gövdə toqquşma ellipsinin içində saxlanılır (bax [method _apply]).
	g.hit_fit = true
	g.lod = lod
	g.is_ally = i % 7 == 3
	g.super_ready = i % 5 == 2
	return g


## Superin açılış effektlərini doğurur (bax [member superfx]).
func _spawn_superfx(vp: Vector2) -> void:
	var kinds := [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]
	var pair := render_mode == "pair"
	var copies := 1 if pair else 4
	for c in copies:
		for k in 3:
			for side in (2 if pair else 1):
				var kind: Const.Species = kinds[k]
				var fx := SuperFx.new()
				fx.use_gpu = side == 1 if pair else render_mode == "gpu"
				var body := 24.0 + 6.0 * float(k)
				# Ayaqlıda torun sərhədi, amöbdə qabıq (bax [method Arena._play_super]).
				var reach := 104.0
				if kind == Const.Species.AMOEBA:
					reach = body + GermVisual.SHIELD_GAP * 0.5
				fx.setup(kind, Palette.germ_color(k * 3 + 1), body, reach, superfx_light)
				fx.set_turn(0.61 * float(_fx_k * 3 + k))
				var cell := Vector2(vp.x / (6.0 if pair else 3.0), vp.y / (1.0 if pair else 4.0))
				var at := Vector2((float(k) + 0.5) * cell.x, (float(c) + 0.5) * cell.y) - vp * 0.5
				fx.position = at + Vector2(vp.x * 0.5 * float(side), 0.0)
				add_child(fx)
	_fx_k += 1


func _process(delta: float) -> void:
	_t += delta
	# Effektlər də `--bench-delay`-i gözləyir — ilk kompilyasiya "yarandıqdan sonrakı
	# 10 kadra" düşsün (bax `_born_worst`).
	if superfx and (delay <= 0.0 or _born_frame >= 0):
		_fx_left -= delta
		if _fx_left <= 0.0:
			_fx_left = 1.0 if render_mode == "pair" else 0.3
			_spawn_superfx(get_viewport_rect().size)
	# Pəncərə bəzən MİNİMALLAŞDIRILMIŞ açılır (başqa pəncərə fokusdadırsa). Onda
	# Godot heç nə çəkmir, `frame_post_draw` gəlmir və stend əbədi gözləyir — FPS
	# isə 145-də dayanır (`low_processor_usage_mode_sleep_usec` = 6.9 ms).
	# Bərpadan sonra isinmə yenidən başlayır: ilk çəkilən kadrlar shader-in
	# kompilyasiyasını daşıyır və ölçməyə düşməməlidir.
	if _frames == 0 and _t > 3.0 and get_window().mode == Window.MODE_MINIMIZED:
		print("[bench] pəncərə minimallaşdırılıb — bərpa edilir")
		get_window().mode = Window.MODE_WINDOWED
		get_window().move_to_foreground()
		_t = 0.0
	for k in _germs.size():
		var e: Array = _germs[k]
		var g: GermVisual = e[0]
		var phase: float = e[2]
		var orbit: float = e[3]
		var pace: float = e[4]
		var cap := g.capacity if g.capacity > 0 else 10
		# Dairə üzrə hərəkət: bucaq sürəti elə seçilir ki, xətti sürət mikrobun öz
		# tavanının `pace` payı olsun — rush 0-dan 1-ə qədər paylanır.
		var speed := Const.germ_speed(cap) * pace
		var ang := phase + _t * speed / maxf(orbit, 1.0)
		var pos: Vector2 = e[1] + Vector2(cos(ang), sin(ang)) * orbit
		var cap_now: int = [10, 14, 18, 24, 30, 38, 46, 60][k % 8]
		# Doluluq: biri boş, biri yarı, biri təhlükədə (≥ 90%).
		var fill: float = [0.15, 0.55, 0.95, 0.75, 0.35][k % 5]
		var balls := int(round(fill * float(cap_now)))
		var aim := ang + PI * 0.5
		# Serverin sürəti — toqquşma ellipsi ondan qurulur (arenada snapshot-dan gəlir).
		var vel := Vector2.from_angle(aim) * speed
		g.net_vel = vel
		_apply(g, pos, aim, balls, cap_now, k)
		if k < _twins.size():
			_twins[k].net_vel = vel
			_apply(_twins[k], pos + Vector2(get_viewport_rect().size.x * 0.5, 0.0),
				aim, balls, cap_now, k)
		# Hadisələr — hər mikrobda öz fazası ilə.
		var fire_at := fposmod(_t + phase, 0.9)
		if fire_at < delta:
			g.eject(aim)
			if k < _twins.size():
				_twins[k].eject(aim)
		var hit_at := fposmod(_t * 0.77 + phase, 1.3)
		if hit_at < delta * 0.77:
			g.flash(aim + 2.0)
			if k < _twins.size():
				_twins[k].flash(aim + 2.0)


func _apply(g: GermVisual, pos: Vector2, aim: float, balls: int, cap: int, k: int) -> void:
	# Hər dördüncü mikrobda super 2.5 saniyə açıq, 2.5 saniyə bağlı — açılma və
	# sönmə keçidi də görünsün (amöbdə qabıq, ayaqlıda tor).
	var sup := k % 4 == 1 and fposmod(_t + float(k), 5.0) < 2.5
	g.apply(pos, aim, balls, cap, k == 4 and _t < 3.0, true, sup)


# ---------------------------------------------------------------- ölçü

func _on_phys() -> void:
	if _t0 < 0:
		_t0 = Time.get_ticks_usec()


func _on_proc() -> void:
	var now := Time.get_ticks_usec()
	if _t0 < 0:
		_t0 = now
	_t_proc = now


func _on_pre() -> void:
	_t_pre = Time.get_ticks_usec()


func _on_post() -> void:
	var now := Time.get_ticks_usec()
	if _t0 >= 0 and _t < WARMUP:
		var busy := float(now - _t0) / 1000.0
		if busy > _warm_worst:
			_warm_worst = busy
			_warm_worst_at = Engine.get_frames_drawn()
		# Mikroblar yarandıqdan sonrakı ilk 10 kadr — isinmə işləyibsə, burada
		# kompilyasiya donması olmamalıdır.
		if _born_frame >= 0 and Engine.get_frames_drawn() - _born_frame < 10:
			_born_worst = maxf(_born_worst, busy)
	if _t0 >= 0 and _t_proc >= 0 and _t_pre >= 0 and _t >= WARMUP:
		if _frames == 0:
			GermGPU.spent_rows_usec = 0
			GermGPU.spent_upload_usec = 0
		var busy := float(now - _t0) / 1000.0
		_busy += busy
		_proc += float(_t_pre - _t_proc) / 1000.0
		_rend += float(now - _t_pre) / 1000.0
		_worst = maxf(_worst, busy)
		_draws_peak = maxi(_draws_peak,
			int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		_gpu += RenderingServer.viewport_get_measured_render_time_gpu(
			get_viewport().get_viewport_rid())
		if verify:
			_verify()
		_frames += 1
		_measured = _t - WARMUP
	_t0 = -1
	_t_proc = -1
	_t_pre = -1
	if secs > 0.0 and _measured >= secs and _frames > 0:
		_report()


## GPU-nun bu kadr qurduğu konturlar GDScript yolunun EYNİ vəziyyətdəki konturları
## ilə nöqtə-nöqtə müqayisə olunur: son kontur, kölgənin konturu, iki mərkəz.
## Kadrın çəkilişi ilə bu an arasında mikrobun vəziyyəti dəyişmir.
func _verify() -> void:
	var img := GermGPU.shape_image()
	if img == null:
		return
	var all: Array = _twins if render_mode == "pair" else _germs.map(func(e): return e[0])
	for g: GermVisual in all:
		if g._gpu_row < 0:
			continue
		var r := Const.germ_radius(g.capacity)
		var shape := g._shape_ring(r, true)
		var ring := g._fit_hit(g._event_deform(g._strain(shape), r))
		var shadow := g._shape_ring(r, false)
		var row := g._gpu_row
		var worst := Vector4.ZERO
		for i in ring.size():
			worst.x = maxf(worst.x, GermGPU.decode_point(img.get_pixel(GermGPU.RING0 + i, row)).distance_to(ring[i]))
			worst.y = maxf(worst.y, GermGPU.decode_point(img.get_pixel(GermGPU.SRING0 + i, row)).distance_to(shadow[i]))
		worst.z = GermGPU.decode_point(img.get_pixel(GermGPU.COL_MID, row)).distance_to(GermVisual._ring_centre(ring))
		worst.w = GermGPU.decode_point(img.get_pixel(GermGPU.COL_SMID, row)).distance_to(GermVisual._ring_centre(shadow))
		var key := int(g.species)
		var acc: Vector4 = _err.get(key, Vector4.ZERO)
		_err[key] = Vector4(maxf(acc.x, worst.x), maxf(acc.y, worst.y), maxf(acc.z, worst.z), maxf(acc.w, worst.w))


func _report() -> void:
	set_process(false)
	RenderingServer.frame_post_draw.disconnect(_on_post)
	for key in _err:
		var e: Vector4 = _err[key]
		print("[bench] YOXLAMA növ %d: GPU ilə GDScript arasında ən böyük fərq — kontur %.4f px, kölgə %.4f px, mərkəz %.4f px, kölgə mərkəzi %.4f px" % [
			key, e.x, e.y, e.z, e.w])
	var f := float(_frames)
	print("[bench] NƏTİCƏ %d kadr · kadrın işi %.3f ms (məntiq+çəkiliş %.3f, render %.3f) · ən pis %.2f ms · çağırış pik %d · mikrob başına %.3f ms · GPU %.3f ms" % [
		_frames, _busy / f, _proc / f, _rend / f, _worst, _draws_peak,
		(_busy / f) / float(count * (2 if render_mode == "pair" else 1)), _gpu / f])
	print("[bench] isinmə: ən pis kadr %.1f ms (%d-ci kadr) — shader-lərin ilk kompilyasiyası" % [
		_warm_worst, _warm_worst_at])
	if _born_frame >= 0:
		print("[bench] mikroblar yarandıqdan sonrakı 10 kadrın ən pisi: %.1f ms (isinmə %s)" % [
			_born_worst, "var" if warm else "yox"])
	# GPU yolunda məntiq+çəkilişin içindən: sətirlərin qurulması (membranın konturu
	# daxil) və teksturanın yüklənməsi — kadr başına, ms.
	if render_mode != "cpu":
		print("[bench] GPU yolu: sətirlər %.3f ms, yükləmə %.3f ms (kadr başına)" % [
			float(GermGPU.spent_rows_usec) / 1000.0 / f, float(GermGPU.spent_upload_usec) / 1000.0 / f])
	get_tree().quit.call_deferred(0)
