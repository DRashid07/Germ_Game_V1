extends Node
## Super probe — superi HƏQİQİ düymə ilə basır və zəncirin hər halqasını yoxlayır.
##
##   Məşq:   Godot_v4.7.2.exe --path game --resolution 1280x720 -- --practice --species 1 \
##               --super-probe 6 [--super-probe-shots C:/yol/qovluq]
##   Onlayn: Godot_v4.7.2.exe --headless --max-fps 60 --path game -- --autoclient \
##               --host ws://127.0.0.1:27015 --species 1 --super-probe 6 --quit-after 240
##
## Düyməyə [method Viewport.push_input] ilə toxunur — telefondakı barmaq kimi.
## MƏŞQDƏ doluluğu yerli dünyada (serverdə) özü doldurur. ONLAYN rejimdə avtomatik
## oyunçu oynayır ([member Arena.auto_input]), amma superi özü işlətmir
## ([member Arena.auto_super]) — düymə yananda probe basır və cavabı SERVERİN
## snapshot-undan ölçür (proqnozdan yox: proqnoz superi həmişə "işlədir").
##
## Hər cəhd üçün: server superi işə saldımı və nə vaxt, "super işləyir" biti, proqnoz
## və mikrobun görüntüsü onu nə qədər göstərdi, görüntü yanıb-söndümü, açılış
## effekti çıxdımı, düymə yenidən yandımı. Çıxış kodu: 0 = hamısı işlədi,
## 3 = ən azı bir cəhd alınmadı.

var trials := 6
var shots_dir := ""

const WAIT_READY := 1.0
const OBSERVE := 1.5

var _arena: Arena = null
var _trial := 0
var _state := 0
var _t := 0.0
var _st_t := 0.0
var _rec := {}
var _fails := 0
var _fx_before := {}
var _vis_prev := false
## Amöbün kisti: proqnozun top id-ləri və serverin öz topları — basılışdan əvvəl görünənlər.
var _ghost_seen := {}
var _shot_seen := {}
var _press_clock := 0.0
var _fire_tap_t := 0.0


func _ready() -> void:
	process_priority = 1000


func _process(delta: float) -> void:
	_t += delta
	if _arena == null or not is_instance_valid(_arena):
		_arena = get_tree().current_scene as Arena
		_st_t = _t
		if _arena != null:
			_arena.auto_super = false
		return
	if _arena.me == null or _arena._hud == null:
		return
	if _arena._local_world != null:
		_practice(delta)
	else:
		_online(delta)


# ---------------------------------------------------------------- məşq

func _practice(delta: float) -> void:
	var w: World = _arena._local_world
	var g: Sim.GermState = w.sim.germs.get(_arena.my_id)
	if g == null:
		_line({"trial": _trial, "error": "mikrob yoxdur (partladı?)"})
		_finish()
		return
	# Cəhdlər arasında mikrob ölməsin — doğuş qalxanı dəymələri udur.
	g.safe_t = maxf(g.safe_t, 2.0)
	var btn := _arena._hud.super_button
	match _state:
		0:
			if _t - _st_t > 1.5:
				_state = 1
		1:
			g.charge = Const.SUPER_MAX
			g.balls = clampi(g.balls, mini(7, g.capacity - 2), g.capacity - 2)
			_st_t = _t
			_state = 2
		2:
			if btn._ready_now:
				_press(int(g.species), g.balls)
			elif _t - _st_t > WAIT_READY:
				_fails += 1
				_line({"trial": _trial, "error": "düymə yanmadı",
					"charge": _arena.me.charge, "balls": _arena.me.balls,
					"ready": _arena.me.super_ready()})
				_next()
		3:
			_observe(delta, g.charge < Const.SUPER_MAX, g.super_t > 0.0, int(g.species))


# ---------------------------------------------------------------- onlayn

func _online(delta: float) -> void:
	var row := _own_row()
	if row.is_empty():
		return
	var flags := int(row[Const.GF.FLAGS])
	var charge := (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
	var on := (flags & Const.GFlag.SUPER) != 0
	var kind := (flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT
	match _state:
		0:
			if _arena._hud.super_button._ready_now and _arena.me.super_ready():
				_press(kind, int(row[Const.GF.BALLS]))
				_rec["srv_charge"] = charge
		3:
			_observe(delta, charge < Const.SUPER_MAX, on, kind)


## Öz mikrobun ən təzə snapshot-dakı sətri (serverin sözü).
func _own_row() -> Array:
	var snap: Array = _arena._last_snap
	if snap.is_empty():
		return []
	for row in snap[Const.Snap.GERMS]:
		if int(row[Const.GF.ID]) == _arena.my_id:
			return row
	return []


# ---------------------------------------------------------------- ümumi

func _press(kind: int, balls: int) -> void:
	_rec = {"trial": _trial, "species": kind, "balls": balls,
		"srv_used": -1.0, "srv_on": 0.0, "pred_on": 0.0, "vis_on": 0.0,
		"vis_flicker": 0, "fx": false, "fx_t": -1.0, "fx_n": 0, "btn_off": -1.0, "btn_again": false}
	_fx_before = {}
	for c in _arena._fx.get_children():
		_fx_before[c.get_instance_id()] = true
	_vis_prev = false
	if kind == Const.Species.AMOEBA:
		# Kist yerində donmuş qüllədir — içindən atəş açılır (bax [method
		# Sim._step_germs]). Düyməyə basılır və sayılır: ekranda uçan top
		# (proqnoz) və serverin həqiqətən atdığı top. İkisi uyğun gəlməlidir:
		# ekrandakı top serverdə yoxdursa, o, heç kimə dəymir.
		_rec["cyst_taps"] = 0
		_rec["cyst_screen_shots"] = 0
		_rec["cyst_srv_shots"] = 0
		_ghost_seen = {}
		for g in _arena._own_shots.ghosts:
			_ghost_seen[g.id] = true
		_shot_seen = {}
		_own_shot_ids(false)
		_press_clock = _arena._clock
		_fire_tap_t = _t + 0.15
	_tap(_arena._hud.super_button)
	_st_t = _t
	_state = 3


## Ekrandakı (proqnoz) və serverdəki öz topları kist ərzində sayır.
func _watch_cyst_fire(dt: float, on: bool) -> void:
	var need := Const.CYST_TIME
	# Miniqan: atəş düyməsi BASILI saxlanılır (barmaq qaldırılmır) — fasiləsiz
	# atəş məhz bu yoldan gəlir ([method Arena._sample_input]).
	var fire_at := _arena._hud.fire_button.get_global_rect().get_center()
	if int(_rec["cyst_taps"]) == 0 and _t >= _fire_tap_t:
		_rec["cyst_taps"] = 1
		_touch(fire_at, true, 1)
	elif int(_rec["cyst_taps"]) == 1 and dt >= need - 0.2:
		_rec["cyst_taps"] = 2
		_touch(fire_at, false, 1)
	# Top sayı serverdə superin BAŞLADIĞI andan ölçülür, basılışdan yox: basılış
	# anındakı snapshot gediş-gəliş qədər köhnədir və arada adi atəş və ya aclıq
	# bir top apara bilər — bu, miniqanın qiyməti deyil.
	if on and not _rec.has("balls_start"):
		_rec["balls_start"] = _arena.me.balls
	# Superin sonunda öz top sayı — miniqanın topu pulsuzdur, say AZALMAMALIDIR.
	if dt >= need - 0.1 and not _rec.has("balls_end"):
		_rec["balls_end"] = _arena.me.balls
	for g in _arena._own_shots.ghosts:
		if _ghost_seen.has(g.id):
			continue
		_ghost_seen[g.id] = true
		# Proqnozun saatı ilə kist basılışdan [constant Const.CYST_TIME] sonra bitir.
		if g.born >= _press_clock and g.born <= _press_clock + need - 0.05:
			_rec["cyst_screen_shots"] = int(_rec["cyst_screen_shots"]) + 1
	_own_shot_ids(on)


## Serverin snapshot-undakı öz toplarım. [param count] — yeni id-lər kist topu sayılır.
func _own_shot_ids(count: bool) -> void:
	var snap: Array = _arena._last_snap
	if snap.is_empty() or not (snap[Const.Snap.SHOTS] is Array):
		return
	for row in snap[Const.Snap.SHOTS]:
		if int(row[Const.SF.COLOR]) != _arena.my_color:
			continue
		var sid := int(row[Const.SF.ID])
		if _shot_seen.has(sid):
			continue
		_shot_seen[sid] = true
		if count:
			_rec["cyst_srv_shots"] = int(_rec["cyst_srv_shots"]) + 1


func _observe(delta: float, used: bool, on: bool, kind: int) -> void:
	var dt := _t - _st_t
	var btn := _arena._hud.super_button
	var vis: GermVisual = _arena._visuals.get(_arena.my_id, {}).get("node")
	if float(_rec["srv_used"]) < 0.0 and used:
		_rec["srv_used"] = snappedf(dt, 0.001)
	if on:
		_rec["srv_on"] = float(_rec["srv_on"]) + delta
	if _arena.me.super_t > 0.0:
		_rec["pred_on"] = float(_rec["pred_on"]) + delta
	var vis_now := vis != null and vis.super_on
	if vis_now:
		_rec["vis_on"] = float(_rec["vis_on"]) + delta
	# Görüntü sönüb yenidən yandı — proqnozla server bir-birini düzəldir.
	if vis_now and not _vis_prev and float(_rec["vis_on"]) > delta * 1.5:
		_rec["vis_flicker"] = int(_rec["vis_flicker"]) + 1
	_vis_prev = vis_now
	if float(_rec["btn_off"]) < 0.0 and not btn._ready_now:
		_rec["btn_off"] = snappedf(dt, 0.001)
	elif float(_rec["btn_off"]) >= 0.0 and btn._ready_now and float(_rec["srv_used"]) < 0.0:
		_rec["btn_again"] = true
	for c in _arena._fx.get_children():
		# Yalnız ÖZ rəngindəki effekt sayılır — yaxındakı botun superi qarışmasın.
		# Sayı 1 olmalıdır: proqnoz da, server də oynatsa effekt İKİ dəfə çıxır.
		if c is SuperFx and not _fx_before.has(c.get_instance_id()) \
				and (c as SuperFx)._color.is_equal_approx(Palette.germ_color(_arena.my_color)):
			_fx_before[c.get_instance_id()] = true
			if not bool(_rec["fx"]):
				_rec["fx_t"] = snappedf(dt, 0.001)
			_rec["fx"] = true
			_rec["fx_n"] = int(_rec["fx_n"]) + 1
	if _rec.has("cyst_taps"):
		_watch_cyst_fire(dt, on)
	if not shots_dir.is_empty() and _trial == 0:
		for at in [0.1, 0.5, 1.2]:
			var key := "shot_%s" % at
			if dt >= at and not _rec.has(key):
				_rec[key] = true
				_shot("s%d_t%02d" % [kind, int(at * 10.0)])
	if dt <= OBSERVE + Const.super_time(kind):
		return
	for k in ["srv_on", "pred_on", "vis_on"]:
		_rec[k] = snappedf(float(_rec[k]), 0.01)
	var ok := float(_rec["srv_used"]) >= 0.0 and int(_rec["fx_n"]) == 1 \
		and int(_rec["vis_flicker"]) == 0
	var need := Const.super_time(kind)
	if need > 0.0:
		ok = ok and float(_rec["srv_on"]) > need * 0.9 \
			and float(_rec["pred_on"]) > need * 0.9 \
			and float(_rec["vis_on"]) > need * 0.9
	if _rec.has("cyst_taps"):
		# Miniqan fasiləsiz atmalıdır — basılı düymə ilə (super boyu düymə ~2.2 s
		# basılıdır) ən azı [constant Const.MINIGUN_COOLDOWN]-dan bir top çıxır.
		# Ekrandakı hər top serverdə də olmalıdır; bir topluq fərq pəncərənin
		# kənarıdır: son top serverin snapshot-unda bayraq sönəndən sonra görünə
		# bilər. Toplar pulsuzdur — superin sonunda say AZALMAMALIDIR.
		var screen := int(_rec["cyst_screen_shots"])
		var srv := int(_rec["cyst_srv_shots"])
		var want := floori((need - 0.6) / Const.MINIGUN_COOLDOWN)
		ok = ok and srv >= want and absi(screen - srv) <= 1 \
			and int(_rec.get("balls_end", -1)) >= int(_rec.get("balls_start", 999))
	_rec["ok"] = ok
	for k in _rec.keys():
		if str(k).begins_with("shot_"):
			_rec.erase(k)
	if not ok:
		_fails += 1
	_line(_rec)
	_next()


func _next() -> void:
	_trial += 1
	_st_t = _t
	_state = 0
	if _trial >= trials:
		_finish()


func _finish() -> void:
	set_process(false)
	print("[super_probe] YEKUN: %d cəhd, %d alınmadı" % [_trial, _fails])
	get_tree().quit(3 if _fails > 0 else 0)


## [param finger] — barmaq indeksi: super 2, atəş 1 (telefondakı kimi ayrı barmaqlar).
func _tap(ctrl: Control, finger := 2) -> void:
	var p := ctrl.get_global_rect().get_center()
	_touch(p, true, finger)
	get_tree().create_timer(0.07).timeout.connect(_touch.bind(p, false, finger))


func _touch(pos: Vector2, pressed: bool, finger := 2) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = finger
	ev.position = pos
	ev.pressed = pressed
	get_viewport().push_input(ev, true)


func _shot(tag: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shots_dir.path_join(tag + ".png"))


func _line(d: Dictionary) -> void:
	print("[super_probe] " + JSON.stringify(d))
