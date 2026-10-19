extends Node
## Kadr probu — kadrın işini hissələrə bölür və qatları növbə ilə gizlədib
## hər birinin payını ölçür (PERF_PLAN, F0).
##
##   GermArena.console.exe --resolution 1600x720 --disable-vsync --max-fps 0 \
##       -- --practice --mode 1 --quality 0 --auto --frame-probe 72 --probe-phases
##
## Hər kadr üçün: MƏŞĞULLUQ — kadrın ilk fizika/proses anından `frame_post_draw`-a
## qədər, yəni ana axının bu kadra sərf etdiyi bütün vaxt. O üç hissəyə bölünür:
## fizika, proses (skriptlər və `_draw`) və render (mühərrikin CPU işi). Kadr
## aralığından fərqli olaraq vsync və kadr həddindən asılı deyil — telefonda da
## yükü düz göstərir (Android-də kadrın dəyişdirilməsi `onDrawFrame`-dən sonradır).
## Videokartın vaxtı Godot-un ölçüsüdür; Android GLES3-də adətən 0 qalır.
##
## `--probe-phases`: ölçmə fazalara bölünür, hər fazada bir qrup qat gizlədilir.
## Gizli qatın `_draw`-ı və render-i getmir, `_process`-i isə qalır — fərq həmin
## qatın ÇƏKİLİŞ qiymətidir. Səhnə canlıdır (mikroblar kadra girib-çıxır), ona görə
## fazalar dövr-dövr təkrarlanır və orta götürülür; "base" hər dövrdə ölçülür.
##
## Yalnız matçın CANLI kadrları sayılır. Oyunçu partlayanda (və ya qalib gələndə)
## nəticə ekranı və menyu ölçüyə düşmür: prob arenanı bağlayıb yenisini açır və
## ölçmə növbəti canda davam edir — `duration` canlar üzrə cəmdir.
##
## 50 ms-dən uzun kadr ilişmə kimi ayrıca yazılır — hissələri ilə birlikdə: render
## hissəsindədirsə, adətən ilk dəfə görünən materialın shader kompilyasiyasıdır.
## Ölüm kadrı da (nəticə ekranı, böyük partlayış) ilişmə siyahısına düşür, ortaya yox.

## Ölçmə müddəti (s) — yalnız matçın canlı kadrları sayılır.
var duration := 40.0
## Arena açılandan sonra ölçülməyən müddət: yükləmə və ilk kadrlar.
var warmup := 3.0
var phases := false
## Yeni məşq arenası açan funksiya (boot.gd verir). Avtomatik oyunçu TƏK QALAN-da
## çox vaxt 15–25 saniyə yaşayır; matç bitəndə arena menyuya qayıdardı. Bu varsa,
## prob köhnə arenanı bağlayıb yenisini açır və ölçmə növbəti canda davam edir.
var respawn := Callable()

## [ad, gizlədilən qatlar]. "@glow" — arenanın parlaması (glow + HDR bufer, F2).
const PHASES := [
	["base", []],
	["no_germs", ["_entities"]],
	["no_glow", ["@glow"]],
	["no_hud", ["_hud"]],
	["no_motes", ["_motes", "_motes_deep"]],
	["no_food", ["_food_layer", "_shot_layer", "_trails"]],
	# Xəritə: maneələr, kolların üst yarpaqları və (V1 xəritəsindən) döşəmə, şəbəkə,
	# quruyan zona, şüşə divar, dalğalar, ön kənar. Arenada olmayan ad ötürülür.
	["no_map", ["_blobs", "_canopy", "_ground", "_grid", "_dry", "_rim", "_ripples", "_lip"]],
	["no_fx", ["_fx", "_aim_guide"]],
]
const PHASE_SECS := 4.0
## Qat dəyişəndən sonra ölçülməyən hissə (HDR buferinin yenidən qurulması və s.).
const PHASE_SETTLE := 0.5
const HITCH_MS := 50.0

var _arena: Node = null
var _found := false
var _elapsed := 0.0
var _done := false
var _lives := 0
## Ölçmədən əvvəlki HDR bufer və parlama — "no_glow" fazası bunları dəyişir.
var _hdr0 := true
var _glow0 := true

var _t0 := -1
var _t_proc := -1
var _t_pre := -1
var _last_post := -1

var _busy := PackedFloat32Array()
var _phys := PackedFloat32Array()
var _proc := PackedFloat32Array()
var _rend := PackedFloat32Array()
var _gpu := PackedFloat32Array()
var _dt := PackedFloat32Array()
var _draws := PackedInt32Array()
var _hitches: Array[String] = []

var _phase_i := -1
var _phase_left := 0.0
var _settle_left := 0.0
## faza adı -> [kadr, məşğulluq, proses, render, gpu, çağırış] cəmləri
var _phase_acc := {}


func _ready() -> void:
	process_priority = -100000
	# Matç bitəndə ağac dayandırıla bilər; prob bunu görüb hesabat yazmalıdır.
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().physics_frame.connect(_on_phys)
	get_tree().process_frame.connect(_on_proc)
	RenderingServer.frame_pre_draw.connect(_on_pre)
	RenderingServer.frame_post_draw.connect(_on_post)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)


func _process(delta: float) -> void:
	if _done:
		return
	# Godot 4-də silinmiş obyekt `null`-a BƏRABƏRDİR — "hələ tapılmayıb" ilə
	# "bağlanıb" ayrıca bayraqla seçilir, yoxsa prob menyuda arenanı əbədi gözləyir.
	if not _found:
		_arena = _find_arena()
		if _arena == null:
			return
		_found = true
		_lives += 1
		if _lives == 1:
			_hdr0 = get_viewport().use_hdr_2d
			var glow = _arena.get("_glow")
			_glow0 = glow != null and glow.environment != null and glow.environment.glow_enabled
			print("[frame] arena tapıldı; isinmə %.1f s, ölçmə %.0f s%s" % [warmup, duration,
				" (fazalarla)" if phases else ""])
	if _elapsed >= duration:
		_finish()
		return
	# Matç bitdi (oyunçu partladı və ya qalib gəldi): ölüm kadrından sonrakı nəticə
	# ekranı və menyu ölçüyə düşməsin.
	if not _alive():
		if respawn.is_valid():
			_next_life()
		else:
			print("[frame] matç %.1f-ci saniyədə bitdi — ölçmə orada dayandı" % _elapsed)
			_finish()
		return
	if warmup > 0.0:
		warmup -= delta
		if warmup <= 0.0 and phases and _phase_i >= 0:
			_apply_phase()   # yeni arenanın qatları hələ görünür
		return
	_elapsed += delta
	if phases:
		_phase_left -= delta
		_settle_left -= delta
		if _phase_left <= 0.0:
			_next_phase()


func _alive() -> bool:
	return is_instance_valid(_arena) and not bool(_arena.get("_finished")) \
		and not get_tree().paused


func _next_life() -> void:
	print("[frame] %d-ci can bitdi (ölçülüb %.1f s) — yeni məşq arenası" % [_lives, _elapsed])
	_show_all()
	if is_instance_valid(_arena):
		# Arenanın menyuya qayıtma taymeri onunla birlikdə ölür.
		_arena.queue_free()
	_arena = null
	_found = false
	warmup = 2.0
	respawn.call()


func _finish() -> void:
	_done = true
	_show_all()
	_report()
	if not OS.has_feature("web"):
		get_tree().quit.call_deferred(0)


func _find_arena() -> Node:
	var scene := get_tree().current_scene
	if scene != null and scene.get("_entities") != null:
		return scene
	for n in get_tree().root.get_children():
		if n.get("_entities") != null:
			return n
	return null


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
	var measuring := _found and is_instance_valid(_arena) and warmup <= 0.0 and not _done
	if measuring and _t0 >= 0 and _t_proc >= 0 and _t_pre >= 0:
		# Ölüm kadrı: nəticə ekranı və partlayış elə bu kadrda başlayır. İlişmə
		# kimi yazılır, ortalamaya isə düşmür — o, matçın sabit qiyməti deyil.
		var last := not _alive()
		var busy := float(now - _t0) / 1000.0
		var phys := float(_t_proc - _t0) / 1000.0
		var proc := float(_t_pre - _t_proc) / 1000.0
		var rend := float(now - _t_pre) / 1000.0
		var gpu := RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid())
		var draws := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var dt := float(now - _last_post) / 1000.0 if _last_post >= 0 else 0.0
		if busy > HITCH_MS:
			_hitches.append("%.0f ms (fizika %.0f, proses %.0f, render %.0f) %.1f-ci saniyədə%s" % [
				busy, phys, proc, rend, _elapsed, " — matçın sonu" if last else ""])
		if last:
			pass
		elif phases:
			if _phase_i >= 0 and _settle_left <= 0.0:
				var key: String = PHASES[_phase_i % PHASES.size()][0]
				var acc: Array = _phase_acc.get(key, [0, 0.0, 0.0, 0.0, 0.0, 0])
				acc[0] += 1
				acc[1] += busy
				acc[2] += proc
				acc[3] += rend
				acc[4] += gpu
				acc[5] = maxi(acc[5], draws)
				_phase_acc[key] = acc
		else:
			_busy.append(busy)
			_phys.append(phys)
			_proc.append(proc)
			_rend.append(rend)
			_gpu.append(gpu)
			_dt.append(dt)
			_draws.append(draws)
	_last_post = now
	_t0 = -1
	_t_proc = -1
	_t_pre = -1


# ---------------------------------------------------------------- fazalar

func _next_phase() -> void:
	_phase_i += 1
	_phase_left = PHASE_SECS
	_apply_phase()


func _apply_phase() -> void:
	_settle_left = PHASE_SETTLE
	_show_all()
	for key in PHASES[_phase_i % PHASES.size()][1]:
		_set_layer(String(key), false)


func _show_all() -> void:
	for ph in PHASES:
		for key in ph[1]:
			_set_layer(String(key), true)


## [param on] = false gizlədir, true ölçmədən əvvəlki halına qaytarır.
func _set_layer(key: String, on: bool) -> void:
	if not is_instance_valid(_arena):
		return
	if key == "@glow":
		# Parlama ilə birlikdə HDR kadr buferi də — F2 ikisini birlikdə götürür
		# (bax [method Arena._apply_quality]).
		var glow = _arena.get("_glow")
		if glow != null and glow.environment != null:
			glow.environment.glow_enabled = on and _glow0
		get_viewport().use_hdr_2d = on and _hdr0
		return
	var n = _arena.get(key)
	if n is CanvasItem or n is CanvasLayer:
		n.visible = on


# ---------------------------------------------------------------- hesabat

static func _pct(a: PackedFloat32Array, p: float) -> float:
	if a.is_empty():
		return 0.0
	var s := a.duplicate()
	s.sort()
	return s[mini(int(float(s.size()) * p), s.size() - 1)]


static func _mean(a: PackedFloat32Array) -> float:
	if a.is_empty():
		return 0.0
	var t := 0.0
	for x in a:
		t += x
	return t / float(a.size())


func _report() -> void:
	print("\n===== Kadr probu (%.0f s matç, %d can) =====" % [_elapsed, _lives])
	if phases:
		var base: Array = _phase_acc.get("base", [0, 0.0, 0.0, 0.0, 0.0, 0])
		var bn := float(maxi(base[0], 1))
		print("  faza        kadr   məşğul  proses  render    GPU  çağırış   fərq (base-dən)")
		for ph in PHASES:
			var key: String = ph[0]
			var acc: Array = _phase_acc.get(key, [0, 0.0, 0.0, 0.0, 0.0, 0])
			var n := float(maxi(acc[0], 1))
			print("  %-10s %5d %7.2f %7.2f %7.2f %6.2f %8d   %+.2f ms" % [key, acc[0],
				acc[1] / n, acc[2] / n, acc[3] / n, acc[4] / n, acc[5],
				acc[1] / n - base[1] / bn])
	else:
		var draws := 0
		for d in _draws:
			draws = maxi(draws, d)
		print("  Kadr          : %d, orta aralıq %.2f ms (%.1f FPS), 1%% ən pis %.2f ms, ən pis %.2f ms" % [
			_busy.size(), _mean(_dt), 1000.0 / maxf(_mean(_dt), 0.001), _pct(_dt, 0.99), _pct(_dt, 1.0)])
		print("  Məşğulluq     : orta %.2f ms, p50 %.2f, p90 %.2f, p99 %.2f" % [
			_mean(_busy), _pct(_busy, 0.5), _pct(_busy, 0.9), _pct(_busy, 0.99)])
		print("  Hissələr      : fizika %.2f, proses %.2f (p90 %.2f), render %.2f (p90 %.2f) ms" % [
			_mean(_phys), _mean(_proc), _pct(_proc, 0.9), _mean(_rend), _pct(_rend, 0.9)])
		print("  Videokart     : %.2f ms orta" % _mean(_gpu))
		print("  Çəkiliş çağ.  : %d pik" % draws)
	if _hitches.is_empty():
		print("  İlişmə (> %.0f ms): yoxdur" % HITCH_MS)
	else:
		print("  İlişmə (> %.0f ms): %d" % [HITCH_MS, _hitches.size()])
		for h in _hitches.slice(0, 8):
			print("    " + h)
	print("=====================================\n")
