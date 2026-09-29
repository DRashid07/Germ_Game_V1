class_name HitProbe
extends Node
## Vuruşun EKRANDA necə göründüyünü ölçür — oyunçunun gözü ilə.
##
## Yalnız səhnəni OXUYUR, oyuna toxunmur və [Arena]-nın daxili məntiqindən
## asılı deyil: öz topunu sprite-ın rəngindən, rəqibi [GermVisual] node-undan,
## zərbəni isə parıltının yanmasından tanıyır. Ona görə eyni probe köhnə və
## yeni kodda EYNİ şeyi ölçür və müqayisə ədalətli olur.
##
## Üç rəqəm:
##   • toxunuş → parıltı: çəkilən top rəqibin səthinə çatdığı kadrdan
##     rəqibin parıldadığı kadra qədər keçən vaxt;
##   • toxunuşdan sonra uçuş: top rəqibə çatandan sonra ekranda nə qədər
##     görünməyə davam edir — rəqibin içindən keçib o biri tərəfdən çıxmaq;
##   • cavabsız toxunuş: top rəqibə çatıb, [constant NO_REPLY] ərzində heç
##     bir zərbə görünməyib.
##
## [AutoClient] onu hər dəfə qoşur və çıxışda [method report] çağırır.

const NO_REPLY := 0.8
## Parıltı topun çəkilən gövdəyə toxunmasından bu qədər ƏVVƏL yanıbsa da cavabdır:
## 1–3 kadr fərqi göz ayırmır. Belə hallar ayrıca sayılır ("erkən").
const EARLY_FLASH := 0.05
## Kadrların çəkildiyi anlar (saniyə) — toxunuşdan sonra.
const SHOT_OFFSETS := [0.0, 0.05, 0.10, 0.15, 0.20, 0.30]
const CROP := 300

var label := ""
## Boş deyilsə, ilk [member shot_limit] toxunuşun kadr ardıcıllığı buraya yazılır.
var shots_dir := ""
var shot_limit := 3

var _arena: Arena = null
## sprite iid -> {"live", "pos", "dir", "touched": {victim iid -> touch}}
var _tracks := {}
## {"t", "victim", "flash", "gone"}
var _touches: Array[Dictionary] = []
## Topun MƏRKƏZİ çəkilən gövdənin içinə girdi — oyunçunun gözündə "dəyməli idi".
## {"t", "victim", "flash", "circle": toqquşma dairəsinə də girdimi, "why", "species"}
var _vtouches: Array[Dictionary] = []
## Başqalarının topları: sprite iid -> {"live", "pos", "col", "vtouched"}.
var _etracks := {}
var _flash_prev := {}
## Mikrobun son parıltısının anı və o parıltının artıq bir toxunuşa yazılıb-yazılmadığı.
var _flash_at := {}
var _flash_used := {}
var _captures: Array[Dictionary] = []
var _grab_pending := false
var _sequences := 0


func _ready() -> void:
	# Arena və mikrobların öz `_process`-i bu kadrda ƏVVƏL işləməlidir:
	# probe yalnız həmin kadrda ekrana gedən vəziyyəti oxuyur.
	process_priority = 1000


func _process(delta: float) -> void:
	if _arena == null or not is_instance_valid(_arena):
		_arena = get_tree().current_scene as Arena
		if _arena == null:
			return
	var now := Time.get_ticks_usec() / 1_000_000.0
	var victims := _victims()
	_scan_shots(now, delta, victims)
	_scan_enemy_shots(now, delta)
	_scan_flashes(now)
	_queue_captures(now)


## Ekranda görünən, vurula bilən rəqiblər (yoldaş, öz mikrobun, ölü deyil).
func _victims() -> Array:
	var out := []
	for c in _arena._entities.get_children():
		var v := c as GermVisual
		if v == null or v.is_local or not v.visible or v.burst or v.is_ally:
			continue
		if v.color_index == _arena.my_color:
			continue
		out.append(v)
	return out


## Öz toplarını izləyir və hər kadrın YOLUNU rəqiblərlə kəsişdirir.
##
## Yol ilə yoxlanır, nöqtə ilə yox: yeni kodda top rəqibə dəyən kadrda elə
## həmin kadr gizlənir, yəni heç vaxt rəqibin üstündə çəkilmir. Gizlənən topun
## yolu bir kadrlıq uçuşla uzadılır — dəymə məhz o parçadadır.
func _scan_shots(now: float, delta: float, victims: Array) -> void:
	var mine := Palette.germ_color(_arena.my_color)
	for c in _arena._shot_layer.get_children():
		var s := c as Sprite2D
		if s == null:
			continue
		var iid := s.get_instance_id()
		var tr: Dictionary = _tracks.get(iid, {})
		var is_mine := s.visible and s.modulate.is_equal_approx(mine)
		if not tr.is_empty() and bool(tr["live"]):
			if not is_mine:
				var from: Vector2 = tr["pos"]
				_test(tr, from, from + Vector2(tr["dir"]) * Const.SHOT_SPEED * delta, now, victims)
				_end(tr, now)
				continue
			var jump := s.position.distance_to(tr["pos"])
			# Hovuzdan təkrar götürülmüş sprite — başqa top.
			if jump > Const.SHOT_SPEED * maxf(delta, 1.0 / 30.0) * 3.0 + 20.0:
				_end(tr, now)
			else:
				_test(tr, tr["pos"], s.position, now, victims)
				if jump > 0.01:
					tr["dir"] = (s.position - Vector2(tr["pos"])).normalized()
				tr["pos"] = s.position
				continue
		if is_mine:
			_tracks[iid] = {"live": true, "pos": s.position, "dir": Vector2.ZERO, "touched": {},
				"vtouched": {}}


func _test(tr: Dictionary, from: Vector2, to: Vector2, now: float, victims: Array) -> void:
	_test_silhouette(tr, from, to, now, victims)
	var touched: Dictionary = tr["touched"]
	for v: GermVisual in victims:
		var vid := v.get_instance_id()
		if touched.has(vid):
			continue
		var reach := Const.germ_radius(v.capacity) + Const.SHOT_RADIUS
		if Sim._seg_circle_t(from, to, v.position, reach) < 0.0:
			continue
		# Qayda ilə dəyməyən hədəflər ayrıca qeyd olunur: doğuş qalxanı topu
		# buraxır, amöbün qabığı sıçradır — bunlar "cavabsız" deyil, oyunun qaydasıdır.
		var why := ""
		if v.safe:
			why = "qalxan"
		elif v.super_on and v.species == Const.Species.AMOEBA:
			why = "qabıq"
		var touch := {"t": now, "victim": vid, "flash": -1.0, "gone": -1.0,
			"reach": reach, "node": v, "why": why}
		touched[vid] = touch
		_touches.append(touch)
		if not shots_dir.is_empty() and _sequences < shot_limit \
				and DisplayServer.get_name() != "headless":
			_sequences += 1
			for off in SHOT_OFFSETS:
				_captures.append({"at": now + float(off), "touch": touch,
					"name": "%s_%d_%03d" % [label, _sequences, int(round(float(off) * 1000.0))]})


## Başqalarının topları — rəqibin topu SƏNİN və ya başqasının gövdəsinə girəndə.
##
## Rəqibin topu interpolyasiya ilə keçmişdə, öz mikrobun isə proqnozla
## İNDİDƏ çəkilir. Top ekranda gövdəyə girib zərbəsiz çıxırsa, oyunçu üçün
## bu da "içindən keçdi"dir — atanın kim olmasından asılı olmayaraq.
func _scan_enemy_shots(now: float, delta: float) -> void:
	var mine := Palette.germ_color(_arena.my_color)
	# Hansı top sənin zaman xəttinə köçürülüb (bax [method Arena._remote_shot_pos]).
	var shifted := {}
	for sid in _arena._shot_views:
		var view: Dictionary = _arena._shot_views[sid]
		var node = view.get("node")
		if is_instance_valid(node) and float(view.get("k", 0.0)) > 0.01:
			shifted[node.get_instance_id()] = true
	for c in _arena._shot_layer.get_children():
		var s := c as Sprite2D
		if s == null:
			continue
		var iid := s.get_instance_id()
		var tr: Dictionary = _etracks.get(iid, {})
		var live := s.visible and not s.modulate.is_equal_approx(mine)
		if not tr.is_empty() and bool(tr["live"]):
			var same: bool = live and s.modulate.is_equal_approx(Color(tr["col"]))
			var jump := s.position.distance_to(tr["pos"])
			if same and jump <= Const.SHOT_SPEED * maxf(delta, 1.0 / 30.0) * 3.0 + 20.0:
				tr["shifted"] = shifted.has(iid)
				_test_silhouette(tr, tr["pos"], s.position, now, _others_of(Color(tr["col"])), "enemy")
				tr["pos"] = s.position
				continue
			tr["live"] = false
			for vid in tr["vtouched"]:
				var vt: Dictionary = tr["vtouched"][vid]
				if float(vt.get("gone", -1.0)) < 0.0:
					vt["gone"] = now
		if live:
			_etracks[iid] = {"live": true, "pos": s.position, "col": s.modulate, "vtouched": {},
				"bot": _is_bot_color(s.modulate)}


## Top botundurmu — insanın topu serverdə geri sarma ilə yoxlanılır (bax [member Sim.lag_comp]).
func _is_bot_color(col: Color) -> bool:
	for k in _arena._bot_colors:
		if Palette.germ_color(int(k)).is_equal_approx(col):
			return true
	return false


## Atanın rəngindən başqa bütün görünən mikroblar — öz mikrobun da daxil.
func _others_of(shooter: Color) -> Array:
	var out := []
	for c in _arena._entities.get_children():
		var v := c as GermVisual
		if v == null or not v.visible or v.burst:
			continue
		if Palette.germ_color(v.color_index).is_equal_approx(shooter):
			continue
		out.append(v)
	return out


## Görünən gövdə ilə toxunuş: yol boyu 4 px-dən bir nöqtə gövdənin çoxbucaqlısının
## içindədirmi. Toqquşma dairəsi ayrıca yoxlanılır — gövdəyə girib dairəyə heç
## girməyən top oyunçu üçün "içindən keçdi"dir.
func _test_silhouette(tr: Dictionary, from: Vector2, to: Vector2, now: float,
		victims: Array, cat := "own") -> void:
	var vt: Dictionary = tr["vtouched"]
	var steps := maxi(1, int(ceil(from.distance_to(to) / 4.0)))
	for v: GermVisual in victims:
		var vid := v.get_instance_id()
		var r := Const.germ_radius(v.capacity)
		var reach := r + Const.SHOT_RADIUS
		var entry: Dictionary = vt.get(vid, {})
		if not entry.is_empty():
			if not bool(entry["circle"]) and _near(from, to, v.position, reach):
				entry["circle"] = true
			if not bool(entry["ellipse"]) and _near_ellipse(from, to, v):
				entry["ellipse"] = true
			entry["depth"] = minf(float(entry.get("depth", 9.0)), _ellipse_depth(from, to, v))
			continue
		# Ucuz ilk süzgəc: gövdə radiusun 2 mislindən böyük olmur.
		if not _near(from, to, v.position, r * 2.0):
			continue
		var ring := v._body_ring(r)
		var inside := false
		for i in steps + 1:
			var p := from.lerp(to, float(i) / float(steps)) - v.position
			if Geometry2D.is_point_in_polygon(p, ring):
				inside = true
				break
		if not inside:
			continue
		var why := ""
		if v.safe:
			why = "qalxan"
		elif v.super_on and v.species == Const.Species.AMOEBA:
			why = "qabıq"
		var touch := {"t": now, "victim": vid, "flash": -1.0, "why": why,
			"circle": _near(from, to, v.position, reach),
			"ellipse": _near_ellipse(from, to, v), "depth": _ellipse_depth(from, to, v), "gone": -1.0,
			"species": int(v.species), "cat": cat, "bot": bool(tr.get("bot", false)),
			"shifted": bool(tr.get("shifted", false)), "on_screen": v.is_local or v.on_screen}
		if cat == "enemy":
			touch["cat"] = "me" if v.is_local else "other"
		# Parıltı toxunuşdan azca əvvəl yanıbsa, o da bu toxunuşun cavabıdır.
		var lit := float(_flash_at.get(vid, -INF))
		if now - lit <= EARLY_FLASH and float(_flash_used.get(vid, -INF)) < lit:
			touch["flash"] = lit
			touch["early"] = true
			_flash_used[vid] = lit
		vt[vid] = touch
		_vtouches.append(touch)


## Parça dairəyə DƏYİR və ya tamamilə İÇİNDƏDİR.
##
## `Sim._seg_circle_t` yalnız sərhədi kəsən anı qaytarır — içəridə uçan qısa
## parça (bir kadrın yolu) üçün "yoxdur" deyir. Oyunda top hədəfə həmişə
## kənardan girir, ona görə orada bu fərq yoxdur; probe isə gövdənin İÇİNDƏ
## uçan topu tutmalıdır.
static func _near(from: Vector2, to: Vector2, at: Vector2, radius: float) -> bool:
	return Geometry2D.get_closest_point_to_segment(at, from, to).distance_squared_to(at) \
		<= radius * radius


## Parça mikrobun DƏYMƏ ellipsinə (bax [method Sim.hit_shape]) toxunurmu.
##
## Ellipsə heç girməyən keçid gövdənin kənarından sürtünmədir — server orada
## dəymə saymır. Girən, amma zərbəsiz qalan isə həqiqi uyğunsuzluqdur.
## Parçanın ellipsə ən dərin nöqtəsi: 0 = mərkəz, 1 = kənar, >1 = çöldə.
func _ellipse_depth(from: Vector2, to: Vector2, v: GermVisual) -> float:
	var vel := _arena.me.vel if v.is_local else v.net_vel
	var shape := Sim.hit_shape(int(v.species), v.capacity, vel)
	var k := Vector2(1.0 / shape.x, 1.0 / shape.y)
	var a := (from - v.position).rotated(-shape.z) * k
	var b := (to - v.position).rotated(-shape.z) * k
	return Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b).length()


func _near_ellipse(from: Vector2, to: Vector2, v: GermVisual) -> bool:
	# Öz mikrobunun sürəti snapshot-dan yox, proqnozdan gəlir (bax [method Arena._remote_shot_pos]).
	var vel := _arena.me.vel if v.is_local else v.net_vel
	var shape := Sim.hit_shape(int(v.species), v.capacity, vel)
	var k := Vector2(1.0 / shape.x, 1.0 / shape.y)
	return _near((from - v.position).rotated(-shape.z) * k,
		(to - v.position).rotated(-shape.z) * k, Vector2.ZERO, 1.0)


func _end(tr: Dictionary, now: float) -> void:
	tr["live"] = false
	for vid in tr["touched"]:
		var touch: Dictionary = tr["touched"][vid]
		if float(touch["gone"]) < 0.0:
			touch["gone"] = now


## Parıltının YANDIĞI kadr — `_flash` artdısa, yeni zərbədir.
func _scan_flashes(now: float) -> void:
	for c in _arena._entities.get_children():
		var v := c as GermVisual
		if v == null:
			continue
		var vid := v.get_instance_id()
		var f := v._flash
		var prev := float(_flash_prev.get(vid, 0.0))
		_flash_prev[vid] = f
		if f <= prev + 0.0001:
			continue
		_flash_at[vid] = now
		for touch in _touches:
			if int(touch["victim"]) == vid and float(touch["flash"]) < 0.0 \
					and now - float(touch["t"]) <= NO_REPLY:
				touch["flash"] = now
				break
		for touch in _vtouches:
			if int(touch["victim"]) == vid and float(touch["flash"]) < 0.0 \
					and now - float(touch["t"]) <= NO_REPLY:
				touch["flash"] = now
				_flash_used[vid] = now
				break


func _queue_captures(now: float) -> void:
	if _captures.is_empty() or _grab_pending:
		return
	if now < float(_captures[0]["at"]):
		return
	_grab_pending = true
	RenderingServer.frame_post_draw.connect(_grab, CONNECT_ONE_SHOT)


func _grab() -> void:
	_grab_pending = false
	if _captures.is_empty():
		return
	var cap: Dictionary = _captures.pop_front()
	var img := get_viewport().get_texture().get_image()
	var touch: Dictionary = cap["touch"]
	var node: GermVisual = touch["node"]
	var at := Vector2(img.get_width(), img.get_height()) * 0.5
	if is_instance_valid(node):
		at = node.get_global_transform_with_canvas().origin
		touch["screen"] = at
	elif touch.has("screen"):
		at = touch["screen"]
	var x := clampi(int(at.x) - CROP / 2, 0, maxi(img.get_width() - CROP, 0))
	var y := clampi(int(at.y) - CROP / 2, 0, maxi(img.get_height() - CROP, 0))
	var crop := img.get_region(Rect2i(x, y, mini(CROP, img.get_width()), mini(CROP, img.get_height())))
	crop.save_png(shots_dir.path_join(String(cap["name"]) + ".png"))


## Yekun sətir. [param now] olmadan indiki an götürülür.
func report() -> String:
	var now := Time.get_ticks_usec() / 1_000_000.0
	var lat := PackedFloat64Array()
	var after := PackedFloat64Array()
	var silent := 0
	var ruled := 0
	var through := 0
	var counted := 0
	for touch in _touches:
		# Çox təzə toxunuş hələ cavab gözləyir — sayılmır.
		if now - float(touch["t"]) < NO_REPLY:
			continue
		counted += 1
		if float(touch["flash"]) >= 0.0:
			lat.append((float(touch["flash"]) - float(touch["t"])) * 1000.0)
		elif String(touch["why"]).is_empty():
			silent += 1
		else:
			ruled += 1
		if float(touch["gone"]) >= 0.0:
			var shown := float(touch["gone"]) - float(touch["t"])
			after.append(shown * 1000.0)
			# Top rəqibin bütün diametrini keçəcək qədər görünüb.
			if shown * Const.SHOT_SPEED > 2.0 * float(touch["reach"]):
				through += 1
	lat.sort()
	after.sort()
	var line := "PROBE: toxunuş %d · zərbə göründü %d (median %s, p90 %s, maks %s) · cavabsız %d (+%d qayda: qalxan/qabıq) · toxunuşdan sonra top görünür: median %s (%s px) · rəqibdən keçdi %d" % [
		counted, lat.size(), _ms(lat, 0.5), _ms(lat, 0.9), _ms(lat, 1.0), silent, ruled,
		_ms(after, 0.5), _px(after, 0.5), through]
	return line + "\n" + _silhouette_report(now)


## Görünən gövdəyə girən, amma zərbə verməyən toplar — növə və səbəbə görə.
func _silhouette_report(now: float) -> String:
	var parts := []
	for cat in ["own", "me", "other"]:
		var n := 0
		var miss := 0
		var graze := 0
		var human := 0
		var shift := 0
		var seen := 0
		var early := 0
		for t in _vtouches:
			if String(t.get("cat", "own")) != cat or now - float(t["t"]) < NO_REPLY:
				continue
			if not String(t["why"]).is_empty():
				continue
			n += 1
			if bool(t.get("early", false)):
				early += 1
			if float(t["flash"]) < 0.0:
				miss += 1
				if not bool(t["ellipse"]):
					graze += 1
				elif not bool(t.get("bot", false)):
					human += 1
				if bool(t.get("shifted", false)):
					shift += 1
				if bool(t.get("on_screen", true)):
					seen += 1
		parts.append("%s %d/%d (sürtünmə %d, insanın topu %d, sənin zamanında %d, ekranda %d; erkən parıltı %d)" % [
			{"own": "sənin topun→rəqib", "me": "rəqibin topu→sən",
			"other": "rəqibin topu→başqası"}[cat], miss, n, graze, human, shift, seen, early])
	var details := PackedStringArray()
	for t in _vtouches:
		var cat := String(t.get("cat", "own"))
		if cat == "own" or now - float(t["t"]) < NO_REPLY or not String(t["why"]).is_empty():
			continue
		if float(t["flash"]) >= 0.0:
			continue
		var after := (float(t["gone"]) - float(t["t"])) * 1000.0 if float(t["gone"]) >= 0.0 else -1.0
		details.append("%s d=%.2f sonra=%.0fms%s%s" % [cat, float(t.get("depth", 9.0)), after,
			" köç" if bool(t.get("shifted", false)) else "", " ekran" if bool(t.get("on_screen", true)) else ""])
	return "KEÇİD (zərbəsiz / gövdəyə girən; sürtünmə = dəymə ellipsinə girmədi): " \
		+ " · ".join(parts) + "\n" + ("KEÇİD-DETAL: " + " | ".join(details) + "\n" if not details.is_empty() else "") \
		+ _own_silhouette(now)


func _own_silhouette(now: float) -> String:
	var total := 0
	var silent := 0
	var ruled := 0
	var no_circle := 0
	var by_species := [0, 0, 0]
	for t in _vtouches:
		if now - float(t["t"]) < NO_REPLY or String(t.get("cat", "own")) != "own":
			continue
		total += 1
		if float(t["flash"]) >= 0.0:
			continue
		if not String(t["why"]).is_empty():
			ruled += 1
			continue
		silent += 1
		by_species[int(t["species"])] += 1
		if not bool(t["circle"]):
			no_circle += 1
	return "GÖVDƏ: top gövdəyə girdi %d · zərbəsiz %d (kirpikli %d, ayaqlı %d, amöb %d; dairəyə heç girmədi %d) · qayda %d" % [
		total, silent, by_species[0], by_species[1], by_species[2], no_circle, ruled]


static func _ms(v: PackedFloat64Array, q: float) -> String:
	if v.is_empty():
		return "-"
	return "%.0f ms" % v[clampi(int(ceil(q * float(v.size()))) - 1, 0, v.size() - 1)]


static func _px(v: PackedFloat64Array, q: float) -> String:
	if v.is_empty():
		return "-"
	return "%.0f" % (v[clampi(int(ceil(q * float(v.size()))) - 1, 0, v.size() - 1)] \
		/ 1000.0 * Const.SHOT_SPEED)
