extends Node
## Şəbəkə probe-u — onlayn donmanın SERVERDƏN, YOLDAN, yoxsa CLIENT-dən gəldiyini ölçür.
##
##   GODOT --headless --max-fps 250 --path game -- --autoclient \
##         --host wss://germ-arena.onrender.com/ws --label A --quit-after 240 \
##         --net-probe [--net-probe-csv C:/yol/A.csv]
##
## Yalnız `--autoclient --net-probe` ilə yaranır, oyunun özündə yoxdur.
## Hər client üçün ölçür:
##
##   • snapshot-ların GƏLİŞ aralığı (server 30 Hz göndərir → norma 33 ms);
##     p50/p90/p99/maks və 100/200/500/1000 ms-dən uzun boşluqların sayı, vaxtı ilə;
##   • ardıcıl snapshot-lardakı SERVER TICK fərqi ([constant Const.Snap.TICK]).
##     WebSocket TCP-dir: fərq 1 deyilsə, server tick-i ya özü atıb, ya da
##     göndərmə buferi dolub paketi atıb — yəni boşluq serverin tərəfindədir;
##   • GECİKMƏ (lateness): `gəliş − tick × 33.3 ms`-nin bütün sessiyadakı ən
##     kiçik qiymətdən fərqi. Bu, yolun bir istiqamətli gecikməsinin artımıdır;
##     boşluqdan fərqli olaraq yığılan paketlərin HAMISINDA görünür;
##   • giriş→təsdiq gediş-gəlişi: snapshot-un SELF.ACK-i hansı girişi təsdiqləyir,
##     o giriş [Arena]-nın saatı ilə nə vaxt göndərilib ([member Arena._input_time]).
##     Snapshot-lar vaxtında gəlir, ACK isə yerində sayırsa — YUXARI istiqamət
##     (client→server) ilişib;
##   • client-in öz kadr aralığı: probe-un öz donması şəbəkə donması sayılmasın;
##   • DÜZƏLİŞ: [Arena] snapshot-u emal edəndə öz mikrobun proqnoz mövqeyi nə qədər
##     sıçrayır (px) və bir kadrda snapshot emalına nə qədər vaxt gedir (ms) —
##     şəbəkə donmasından sonra yığılan paketlərin client-də yaratdığı ikinci donma.
##
## Hər 10 s bir sətir, çıxışda tam hesabat. CSV verilibsə hər snapshot bir sətirdir.

const WINDOW := 10.0
const GAP_LIMITS := [100.0, 200.0, 500.0, 1000.0]
## Bundan uzun boşluq/gecikmə hadisə siyahısına vaxtı ilə yazılır.
const EVENT_MS := 200.0
const MAX_EVENTS := 80
## Dünyaya girəndən sonrakı ilk snapshot-lar sayılmır: arena yüklənərkən kadr
## ~150 ms çəkir və yığılmış paketlər bir anda gəlir — bu, şəbəkə deyil.
const WARMUP_SNAPS := 60

var label := "probe"
var csv_path := ""
## [AutoClient] dünyaya girəndə verir; ondan əvvəl RTT ölçülmür.
var arena: Node = null

var _csv: FileAccess = null
var _base_unix := 0.0
var _base_us := 0
var _last_us := 0
var _last_tick := -1
## `gəliş_s − tick × TICK_DELTA`-nın ən kiçiyi — tick sayğacı sıfırlananda (yeni dünya) yenidən başlayır.
var _min_off := INF
var _last_ack := -1
var _ack_run := 0
var _win_t := 0.0
var _started := false
var _done := false

## Pəncərə və bütün sessiya üçün eyni yığım (bax [method _new_acc]).
var _win := {}
var _all := {}
var _events: Array[String] = []
## Gecikmə ilk ölçülən anda bilinmir (ən kiçik ofset sonra azala bilər) — sonda
## sessiyanın ən kiçik ofsetinə görə yenidən hesablanır.
var _offsets: Array = []   ## [seq_no_of_world, offset_s]
var _world_no := 0
## Arenanın snapshot emalından ƏVVƏLKİ an və mövqe (bax [method _after_snapshot]).
var _pre_us := 0
var _pre_pos := Vector2.INF
var _after_hooked := false
var _frame_handle_us := 0
var _warm := 0
## `--stall-probe`: kadr-kadr donma ölçüsü (bax `stall_probe.gd`) — bu probe-un içindən yaranır.
var _stall = null


func _ready() -> void:
	_base_unix = Time.get_unix_time_from_system()
	_base_us = Time.get_ticks_usec()
	_win = _new_acc()
	_all = _new_acc()
	Net.snapshot_arrived.connect(_on_snapshot)
	if not csv_path.is_empty():
		_csv = FileAccess.open(csv_path, FileAccess.WRITE)
		if _csv == null:
			_log("CSV açılmadı: %s" % csv_path)
		else:
			_csv.store_line("utc,t_ms,gap_ms,tick,tick_gap,offset_ms,ack,rtt_ms,unacked_ticks,frame_ms")
	if OS.get_cmdline_user_args().has("--stall-probe"):
		_stall = load("res://scripts/tools/stall_probe.gd").new()
		_stall.label = label
		add_child(_stall)
	_log("NET probe aktivdir (pəncərə %.0f s%s)" % [WINDOW, ", CSV " + csv_path if _csv else ""])


func _new_acc() -> Dictionary:
	return {"gaps": [], "rtt": [], "late": [], "corr": [], "handle_max": 0.0,
		"tick_bad": 0, "tick_lost": 0, "ack_stall": 0, "frame_max": 0.0, "frames_long": 0,
		"snaps": 0}


func _process(delta: float) -> void:
	var handle_ms := float(_frame_handle_us) / 1000.0
	_frame_handle_us = 0
	if not _started or _warm < WARMUP_SNAPS:
		return
	var ms := delta * 1000.0
	if handle_ms > 50.0:
		_event("snapshot emalı bir kadrda %.0f ms çəkdi (yığılmış paketlər)" % handle_ms)
	for acc in [_win, _all]:
		acc["handle_max"] = maxf(float(acc["handle_max"]), handle_ms)
		acc["frame_max"] = maxf(float(acc["frame_max"]), ms)
		if ms > 100.0:
			acc["frames_long"] = int(acc["frames_long"]) + 1
	if ms > EVENT_MS:
		_event("CLIENT KADRI %.0f ms (probe-un öz donması)" % ms)
	_win_t += delta
	if _win_t >= WINDOW:
		_win_t = 0.0
		_log("NET %.0fs: %s" % [WINDOW, _summary(_win, false)])
		_win = _new_acc()


func _on_snapshot(data: Array) -> void:
	if _done or data.size() <= Const.Snap.SELF:
		return
	_started = true
	var now := Time.get_ticks_usec()
	# Arenanın öz qəbuledicisindən SONRA çağırılan ikinci qəbuledici: arena onu
	# _ready-də bağlayır, biz isə ilk snapshot-da — siqnal sırası ilə çağırır.
	# Arena snapshot-ları növbəyə yığır və kadrın əvvəlində BİRLİKDƏ emal edir — düzəliş
	# və emal vaxtı onun `drained` siqnalından gəlir (köhnə arenada siqnal yoxdur: onda
	# emal elə bu siqnalın içindədir və ikinci qəbuledici ölçür).
	if arena != null and is_instance_valid(arena) and not _after_hooked and arena.is_inside_tree():
		_after_hooked = true
		if arena.has_signal("drained"):
			arena.connect("drained", _on_drained)
		else:
			Net.snapshot_arrived.connect(_after_snapshot)
	_pre_us = now
	_pre_pos = Vector2.INF
	if arena != null and is_instance_valid(arena) and arena.get("me") != null:
		_pre_pos = arena.get("me").pos
	var tick := int(data[Const.Snap.TICK])
	var gap := -1.0
	if _last_us > 0:
		gap = float(now - _last_us) / 1000.0
	var tick_gap := tick - _last_tick if _last_tick >= 0 else 1
	# Yeni dünya: tick sayğacı sıfırdan başlayır — baza yenidən qurulur.
	if _last_tick >= 0 and (tick_gap <= 0 or tick_gap > 300):
		_event("tick sayğacı dəyişdi %d → %d (yeni dünya / yenidən qoşulma)" % [_last_tick, tick])
		_min_off = INF
		_world_no += 1
		_warm = 0
		tick_gap = 1
	var off := float(now - _base_us) / 1e6 - float(tick) * Const.TICK_DELTA
	_min_off = minf(_min_off, off)
	var late := (off - _min_off) * 1000.0
	_warm += 1
	var measuring := _warm > WARMUP_SNAPS
	if measuring:
		_offsets.append([_world_no, off])

	# Giriş→təsdiq: SELF = [ack, cooldown].
	var rtt := -1.0
	var unacked := -1
	var ack := -1
	var me_self = data[Const.Snap.SELF]
	if me_self is Array and (me_self as Array).size() > Const.SelfF.ACK:
		ack = int(me_self[Const.SelfF.ACK])
	if arena != null and is_instance_valid(arena) and ack > 0:
		var times: Dictionary = arena.get("_input_time")
		if times != null and times.has(ack):
			rtt = (float(arena.get("_clock")) - float(times[ack])) * 1000.0
		unacked = int(arena.get("_seq")) - ack
	if ack > 0 and measuring:
		if ack == _last_ack:
			_ack_run += 1
		else:
			if _ack_run >= 6:
				_event("ACK %d snapshot boyunca yerində saydı (~%.0f ms) — yuxarı istiqamət ilişib" % [
					_ack_run, _ack_run * Const.TICK_DELTA * 1000.0])
			for acc in [_win, _all]:
				acc["ack_stall"] = maxi(int(acc["ack_stall"]), _ack_run)
			_ack_run = 0
		_last_ack = ack

	for acc in ([_win, _all] if measuring else []):
		acc["snaps"] = int(acc["snaps"]) + 1
		if gap >= 0.0:
			(acc["gaps"] as Array).append(gap)
		(acc["late"] as Array).append(late)
		if rtt >= 0.0:
			(acc["rtt"] as Array).append(rtt)
		if tick_gap != 1:
			acc["tick_bad"] = int(acc["tick_bad"]) + 1
			acc["tick_lost"] = int(acc["tick_lost"]) + maxi(tick_gap - 1, 0)
	if measuring and gap > EVENT_MS:
		_event("snapshot boşluğu %.0f ms (tick +%d, gecikmə %.0f ms)" % [gap, tick_gap, late])
	if measuring and tick_gap > 1:
		_event("server tick-i atlandı: +%d" % tick_gap)

	if _csv != null:
		_csv.store_line("%s,%.1f,%.1f,%d,%d,%.1f,%d,%.1f,%d,%.1f" % [
			_utc(now), float(now - _base_us) / 1000.0, gap, tick, tick_gap, off * 1000.0,
			ack, rtt, unacked, get_process_delta_time() * 1000.0])
	_last_us = now
	_last_tick = tick


## Yeni arena kadrda yığılan snapshot-ları emal etdi (bax `Arena.drained`).
func _on_drained(corr: float, ms: float, _count: int) -> void:
	_frame_handle_us += int(ms * 1000.0)
	if _done or _warm <= WARMUP_SNAPS:
		return
	for acc in [_win, _all]:
		(acc["corr"] as Array).append(corr)
	if corr > 30.0:
		_event("öz mikrobun düzəlişi %.0f px (ACK %d, gözləyən giriş %d)" % [
			corr, _last_ack, (arena.get("pending") as Array).size()])


## Köhnə arena snapshot-u emal etdi: proqnozun sıçrayışı və emalın qiyməti.
func _after_snapshot(_data: Array) -> void:
	var now := Time.get_ticks_usec()
	_frame_handle_us += now - _pre_us
	if _done or _warm <= WARMUP_SNAPS or _pre_pos == Vector2.INF:
		return
	if arena == null or not is_instance_valid(arena) or arena.get("me") == null:
		return
	var corr: float = (arena.get("me").pos - _pre_pos).length()
	for acc in [_win, _all]:
		(acc["corr"] as Array).append(corr)
	if corr > 30.0:
		_event("öz mikrobun düzəlişi %.0f px (ACK %d, gözləyən giriş %d)" % [
			corr, _last_ack, (arena.get("pending") as Array).size()])


## Çıxışda bir dəfə — [AutoClient] çağırır (və ehtiyat üçün `_exit_tree`).
func report() -> void:
	if _done:
		return
	_done = true
	if _stall != null:
		_stall.report()
	# Gecikmə dünyanın ÖZ ən kiçik ofsetinə görə yenidən hesablanır.
	var mins := {}
	for o in _offsets:
		mins[o[0]] = minf(float(mins.get(o[0], INF)), float(o[1]))
	var late := []
	for o in _offsets:
		late.append((float(o[1]) - float(mins[o[0]])) * 1000.0)
	_all["late"] = late
	_log("NET YEKUN (%.0f s): %s" % [float(Time.get_ticks_usec() - _base_us) / 1e6, _summary(_all, true)])
	if _events.is_empty():
		_log("NET hadisə yoxdur (heç bir boşluq/gecikmə %.0f ms-dən uzun deyil)" % EVENT_MS)
	else:
		_log("NET hadisələr (%d):" % _events.size())
		for e in _events:
			_log("   " + e)
	if _csv != null:
		_csv.flush()
		_csv.close()
		_csv = null


func _exit_tree() -> void:
	report()


func _summary(acc: Dictionary, full: bool) -> String:
	var gaps: Array = acc["gaps"]
	var counts := []
	for lim in GAP_LIMITS:
		var n := 0
		for g in gaps:
			if g > lim:
				n += 1
		counts.append(">%d:%d" % [int(lim), n])
	var s := "snap %d · aralıq p50 %s p90 %s p99 %s maks %s ms [%s] · tick≠1 %d (itən %d) · gecikmə p50 %s p99 %s maks %s ms · RTT p50 %s p90 %s maks %s ms · ACK donma maks %d · kadr maks %.0f ms · düzəliş p50 %s p99 %s maks %s px · emal/kadr maks %.0f ms" % [
		int(acc["snaps"]), _p(gaps, 0.5), _p(gaps, 0.9), _p(gaps, 0.99), _p(gaps, 1.0), " ".join(counts),
		int(acc["tick_bad"]), int(acc["tick_lost"]),
		_p(acc["late"], 0.5), _p(acc["late"], 0.99), _p(acc["late"], 1.0),
		_p(acc["rtt"], 0.5), _p(acc["rtt"], 0.9), _p(acc["rtt"], 1.0),
		int(acc["ack_stall"]), float(acc["frame_max"]),
		_p(acc["corr"], 0.5), _p(acc["corr"], 0.99), _p(acc["corr"], 1.0), float(acc["handle_max"])]
	if full:
		var late: Array = acc["late"]
		var lc := []
		for lim in GAP_LIMITS:
			var n := 0
			for v in late:
				if v > lim:
					n += 1
			lc.append(">%d:%d" % [int(lim), n])
		s += " · gecikmə [%s] · 100 ms+ kadr %d" % [" ".join(lc), int(acc["frames_long"])]
	return s


static func _p(arr: Array, q: float) -> String:
	if arr.is_empty():
		return "-"
	var c := arr.duplicate()
	c.sort()
	return "%.0f" % c[clampi(int(round(q * float(c.size() - 1))), 0, c.size() - 1)]


func _utc(us: int) -> String:
	var t := _base_unix + float(us - _base_us) / 1e6
	var ms := int(fmod(t, 1.0) * 1000.0)
	return "%s.%03d" % [Time.get_datetime_string_from_unix_time(int(t)).substr(11), ms]


func _event(text: String) -> void:
	if _events.size() >= MAX_EVENTS:
		return
	var e := "%s UTC  %s" % [_utc(Time.get_ticks_usec()), text]
	_events.append(e)
	_log("NET ! " + e)


func _log(msg: String) -> void:
	print("[%s] %s" % [label, msg])
