extends Node
## Donma (stall) probe-u — şəbəkə paketləri GEC və ya DƏSTƏ ilə gələndə ekranda nə görünür.
##
## Yalnız `--autoclient --net-probe --stall-probe` ilə yaranır ([code]net_probe.gd[/code] yükləyir),
## oyunun özündə yoxdur. Arenaya toxunmur, yalnız oxuyur (skriptli hərəkət istisna — aşağıda).
##
## Hər KADR bir CSV sətri (`--stall-probe-csv <mütləq yol>`):
##   • over_ms   — render vaxtı ən təzə snapshot-un anından nə qədər QABAQDADIR. Müsbətdirsə
##                 bufer boşdur: [method Arena._bracket] ən təzə snapshot-u göstərir, rəqiblər DONUR;
##   • vt, vt_step — ekrandakı server tick-i ([method Arena._view_tick]) və kadrlıq addımı.
##                 Norma 60 FPS-də +0.5 tick; mənfi addım = rəqiblər GERİYƏ sıçrayır (rubber band);
##   • rjump_px  — rəqib mikrobların kadrlıq yerdəyişməsinin fiziki həddən (700 px/s) artığı, ən böyüyü;
##   • own_jump_px — öz mikrobunun ÇƏKİLƏN yerinin eyni həddən artığı (görünən geri sıçrayış);
##   • corr_px   — bu kadrda snapshot-ların proqnozu nə qədər sürüşdürdüyü (cəm);
##   • ack_age_ms — son təsdiqlənmiş girişin yaşı (yuxarı istiqamət ilişəndə böyüyür);
##   • shots     — ekranda görünən YAD topların sayı.
## Hər 10 s yaddaş/massiv ölçüləri (sızma yoxlaması), çıxışda yekun.
##
## `--stall-move flip:P` / `circle:P` — avtomatik giriş söndürülür və joystik P saniyəlik dövrlə
## sağa-sola (və ya dairəvi) çəkilir: donma ərzində istiqamət dəyişəndə geri sıçrayışı ölçmək üçün.
## `--stall-hitch E:MS` — hər E saniyədən bir əsas axın MS ms BLOKLANIR (telefonun uzun kadrı,
## GC). Hər blok `STALLP HITCH <unix ms> <ms>` sətri ilə yazılır.

const VMAX := 700.0
const MEM_EVERY := 10.0

var label := "probe"
var csv_path := ""
var move_mode := ""
var move_period := 1.0
var hitch_every := 0.0
var hitch_ms := 0
var _hitch_t := 0.0

var arena: Node = null
var _csv: FileAccess = null
var _base_unix := 0.0
var _base_us := 0
var _prev_vt := NAN
var _prev_pos := {}
var _prev_own := Vector2.INF
var _snaps_in_frame := 0
var _corr_frame := 0.0
var _pre_pos := Vector2.INF
var _hooked := false
var _mem_t := 0.0
var _t := 0.0
## Yekun: kadr sayı, donmuş kadrların cəmi və s.
var _sum := {"frames": 0, "dry_s": 0.0, "dry_max_s": 0.0, "back_ticks": 0.0, "back_max": 0.0,
	"rjump_max": 0.0, "rjump_n": 0, "own_jump_max": 0.0, "own_jump_n": 0, "corr_max": 0.0}
var _dry_run := 0.0
var _mem_first := {}


func _ready() -> void:
	process_priority = 1001
	_base_unix = Time.get_unix_time_from_system()
	_base_us = Time.get_ticks_usec()
	var args := OS.get_cmdline_user_args()
	var i := args.find("--stall-probe-csv")
	if i >= 0 and i + 1 < args.size():
		csv_path = args[i + 1]
	i = args.find("--stall-hitch")
	if i >= 0 and i + 1 < args.size():
		var hp := args[i + 1].split(":")
		hitch_every = float(hp[0])
		hitch_ms = int(hp[1]) if hp.size() > 1 else 400
	i = args.find("--stall-move")
	if i >= 0 and i + 1 < args.size():
		var parts := args[i + 1].split(":")
		move_mode = parts[0]
		move_period = float(parts[1]) if parts.size() > 1 else 1.0
	if not csv_path.is_empty():
		_csv = FileAccess.open(csv_path, FileAccess.WRITE)
		if _csv != null:
			_csv.store_line("unix_ms,clock,frame_ms,snaps,over_ms,vt,vt_step,rjump_px,own_jump_px,corr_px,ack_age_ms,pending,shots,ghosts,extra")
	Net.snapshot_arrived.connect(_pre_snapshot)
	_log("STALL probe aktivdir (csv %s, hərəkət %s)" % [csv_path, move_mode if move_mode else "avtomatik"])


func _find_arena() -> bool:
	if arena != null and is_instance_valid(arena) and arena.is_inside_tree():
		return true
	var cs := get_tree().current_scene
	if cs != null and cs.has_method("_bracket"):
		arena = cs
		_prev_vt = NAN
		_prev_pos.clear()
		_prev_own = Vector2.INF
		if move_mode != "":
			arena.set("auto_input", false)
		return true
	return false


func _pre_snapshot(_data: Array) -> void:
	_snaps_in_frame += 1
	if not _find_arena():
		return
	if not _hooked:
		_hooked = true
		# Yeni arena snapshot-ları kadrın əvvəlində BİRLİKDƏ emal edir — düzəliş `drained`
		# siqnalından gəlir. Köhnədə emal bu siqnalın içindədir: arenanın qəbuledicisindən
		# SONRA çağırılan ikinci qəbuledici ölçür (o, _ready-də bağlanıb).
		if arena.has_signal("drained"):
			arena.connect("drained", func(corr: float, _ms: float, _n: int) -> void:
				_corr_frame += corr)
		else:
			Net.snapshot_arrived.connect(_post_snapshot)
	var m = arena.get("me")
	_pre_pos = m.pos if m != null else Vector2.INF


func _post_snapshot(_data: Array) -> void:
	if arena == null or not is_instance_valid(arena) or _pre_pos == Vector2.INF:
		return
	var m = arena.get("me")
	if m == null:
		return
	_corr_frame += (m.pos - _pre_pos).length()


func _process(delta: float) -> void:
	_t += delta
	if not _find_arena():
		_snaps_in_frame = 0
		_corr_frame = 0.0
		return
	_drive_move()
	if hitch_every > 0.0:
		_hitch_t += delta
		if _t > 5.0 and _hitch_t >= hitch_every:
			_hitch_t = 0.0
			_log("STALLP HITCH %d %d" % [_unix_ms(), hitch_ms])
			OS.delay_msec(hitch_ms)
	var clock := float(arena.get("_clock"))
	var snaps: Array = arena.get("_snaps")
	var rt := clock - Const.INTERP_DELAY
	if arena.has_method("_render_time"):
		rt = float(arena.call("_render_time"))
	var over := NAN
	if not snaps.is_empty():
		over = (rt - float(snaps[-1]["t"])) * 1000.0
	# Göstərilən tick: yeni kodda ekstrapolyasiya ilə birlikdə ([method Arena._render_tick]),
	# köhnədə [method Arena._view_tick] (orada ekstrapolyasiya yoxdur — eyni şeydir).
	var vt := float(arena.call("_render_tick")) if arena.has_method("_render_tick") \
		else float(arena.call("_view_tick"))
	var vt_step := vt - _prev_vt if not is_nan(_prev_vt) and vt >= 0.0 else 0.0
	# Yeni dünya / tick sayğacı sıfırlandı — addım sayılmır.
	if absf(vt_step) > 300.0:
		vt_step = 0.0
	_prev_vt = vt
	var my_id := int(arena.get("my_id"))
	var visuals: Dictionary = arena.get("_visuals")
	var rjump := 0.0
	var seen := {}
	for gid in visuals:
		if int(gid) == my_id:
			continue
		var node: Node2D = visuals[gid]["node"]
		if not is_instance_valid(node) or not node.visible:
			continue
		seen[gid] = true
		if _prev_pos.has(gid):
			rjump = maxf(rjump, Vector2(_prev_pos[gid]).distance_to(node.position) - VMAX * delta)
		_prev_pos[gid] = node.position
	for gid in _prev_pos.keys():
		if not seen.has(gid):
			_prev_pos.erase(gid)
	var own: Vector2 = arena.call("_shown_pos")
	var own_jump := 0.0
	if _prev_own != Vector2.INF:
		own_jump = maxf(0.0, _prev_own.distance_to(own) - VMAX * delta)
	_prev_own = own
	var ack_age := -1.0
	var times: Dictionary = arena.get("_input_time")
	var ack := int(arena.get("_last_ack"))
	if times.has(ack):
		ack_age = (clock - float(times[ack])) * 1000.0
	var shots := 0
	var views: Dictionary = arena.get("_shot_views")
	for sid in views:
		var spr = views[sid].get("node")
		if spr != null and is_instance_valid(spr) and spr.visible:
			shots += 1
	var ghosts := 0
	var own_shots = arena.get("_own_shots")
	if own_shots != null:
		for g in own_shots.ghosts:
			if g.alive:
				ghosts += 1
	var extra := ""
	if arena.has_method("_probe_extra"):
		extra = str(arena.call("_probe_extra"))

	# Yekun.
	if _t > 3.0:
		_sum["frames"] += 1
		if not is_nan(over) and over > 0.0:
			_dry_run += delta
			_sum["dry_s"] += delta
			_sum["dry_max_s"] = maxf(_sum["dry_max_s"], _dry_run)
		else:
			_dry_run = 0.0
		if vt_step < -0.05:
			_sum["back_ticks"] += -vt_step
			_sum["back_max"] = maxf(_sum["back_max"], -vt_step)
		_sum["rjump_max"] = maxf(_sum["rjump_max"], rjump)
		if rjump > 15.0:
			_sum["rjump_n"] += 1
		_sum["own_jump_max"] = maxf(_sum["own_jump_max"], own_jump)
		if own_jump > 15.0:
			_sum["own_jump_n"] += 1
		_sum["corr_max"] = maxf(_sum["corr_max"], _corr_frame)

	if _csv != null:
		_csv.store_line("%d,%.4f,%.1f,%d,%.1f,%.2f,%.3f,%.1f,%.1f,%.1f,%.0f,%d,%d,%d,%s" % [
			_unix_ms(), clock, delta * 1000.0, _snaps_in_frame, over, vt, vt_step, rjump, own_jump,
			_corr_frame, ack_age, (arena.get("pending") as Array).size(), shots, ghosts, extra])
	_snaps_in_frame = 0
	_corr_frame = 0.0

	_mem_t += delta
	if _mem_t >= MEM_EVERY:
		_mem_t = 0.0
		_log("STALLP MEM " + _mem_line())


func _drive_move() -> void:
	if move_mode == "":
		return
	var hud = arena.get("_hud")
	if hud == null:
		return
	var clock := float(arena.get("_clock"))
	var v := Vector2.ZERO
	if move_mode == "flip":
		v = Vector2.RIGHT if int(floor(clock / move_period)) % 2 == 0 else Vector2.LEFT
	elif move_mode == "circle":
		v = Vector2.from_angle(TAU * clock / move_period)
	hud.move_stick.value = v


func _mem_line() -> String:
	var parts := PackedStringArray()
	parts.append("obj %d node %d orphan %d static %.1fMB" % [
		Performance.get_monitor(Performance.OBJECT_COUNT),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0])
	for key in ["_snaps", "_input_time", "_claims", "_self_claims", "_early_hits", "_fx_queue",
			"_visuals", "_food_views", "_shot_views", "_food_pool", "_shot_pool", "_own_sids",
			"_ghost_nodes", "pending", "_proxy_inputs", "_bush_rustles", "_germ_bushes", "_tick_targets"]:
		var v = arena.get(key)
		if v is Array or v is Dictionary:
			parts.append("%s %d" % [key.trim_prefix("_"), v.size()])
	var fx = arena.get("_fx")
	if fx != null:
		parts.append("fx_children %d" % fx.get_child_count())
	var ent = arena.get("_entities")
	if ent != null:
		parts.append("entities %d" % ent.get_child_count())
	var sl = arena.get("_shot_layer")
	if sl != null:
		parts.append("shot_layer %d" % sl.get_child_count())
	var fl = arena.get("_food_layer")
	if fl != null:
		parts.append("food_layer %d" % fl.get_child_count())
	var own_shots = arena.get("_own_shots")
	if own_shots != null:
		parts.append("ghosts %d" % own_shots.ghosts.size())
	var tr = arena.get("_trails")
	if tr != null and tr.get("_tracks") != null:
		parts.append("trails %d" % (tr.get("_tracks") as Dictionary).size())
	return " · ".join(parts)


func report() -> void:
	var s := _sum
	_log("STALLP YEKUN: kadr %d · bufer boş (rəqiblər donur) cəmi %.2f s, ən uzun %.2f s · geri sıçrayış cəmi %.1f tick, ən böyük %.2f tick · rəqib sıçrayışı maks %.0f px (%d kadr >15) · öz sıçrayış maks %.0f px (%d kadr >15) · proqnoz düzəlişi kadrda maks %.0f px" % [
		s["frames"], s["dry_s"], s["dry_max_s"], s["back_ticks"], s["back_max"], s["rjump_max"],
		s["rjump_n"], s["own_jump_max"], s["own_jump_n"], s["corr_max"]])
	if arena != null and is_instance_valid(arena):
		_log("STALLP MEM " + _mem_line())
	if _csv != null:
		_csv.flush()
		_csv.close()
		_csv = null


func _unix_ms() -> int:
	return int(_base_unix * 1000.0) + (Time.get_ticks_usec() - _base_us) / 1000


func _log(msg: String) -> void:
	print("[%s] %s" % [label, msg])
