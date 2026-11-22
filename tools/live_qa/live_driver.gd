extends Node
## Canlı QA sürücüsü (YALNIZ scratch nüsxədə). `--live <port>` ilə açılır.
## TCP üzərindən bir sətir JSON əmr alır, bir sətir JSON cavab qaytarır.
## Addım rejimində arena əmrlər arasında DONUR (get_tree().paused) — oyunu
## yavaş düşünən oyunçu kimi oynamaq üçün. Onlayn oyunda addım rejimi söndürülür.

var _srv := TCPServer.new()
var _peer: StreamPeerTCP = null
var _buf := PackedByteArray()
var _busy := false
var step_mode := true
var _t := 0.0
var _catcher: ErrorCatcher
var _errors := PackedStringArray()
var _all_errors := 0
var _stick_down := false
var _stick_origin := Vector2.ZERO
var _stick_dir := Vector2.ZERO
var _frame_ms_max := 0.0
var _frames := 0
var _spikes := 0
var _shot_n := 0
var out_dir := ""


class ErrorCatcher extends Logger:
	var _lines := PackedStringArray()
	var _mutex := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		var msg := rationale if not rationale.is_empty() else code
		var kind := "WARN" if error_type == Logger.ERROR_TYPE_WARNING else "ERR"
		_mutex.lock()
		_lines.append("%s: %s (%s:%d)" % [kind, msg, file.get_file(), line])
		_mutex.unlock()

	func drain() -> PackedStringArray:
		_mutex.lock()
		var out := _lines
		_lines = PackedStringArray()
		_mutex.unlock()
		return out


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--live")
	if i < 0:
		queue_free()
		return
	var port := 7777
	if i + 1 < args.size() and args[i + 1].is_valid_int():
		port = int(args[i + 1])
	var od := args.find("--live-out")
	out_dir = args[od + 1] if od >= 0 and od + 1 < args.size() else OS.get_user_data_dir().path_join("live")
	DirAccess.make_dir_recursive_absolute(out_dir)
	if args.has("--live-realtime"):
		step_mode = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var err := _srv.listen(port, "127.0.0.1")
	_catcher = ErrorCatcher.new()
	OS.add_logger(_catcher)
	print("[live] port %d listen=%d out=%s" % [port, err, out_dir])


func _process(delta: float) -> void:
	_t += delta
	if not get_tree().paused:
		_frames += 1
		var ms := delta * 1000.0
		if ms > 50.0:
			_spikes += 1
		_frame_ms_max = maxf(_frame_ms_max, ms)
	for l in _catcher.drain():
		_all_errors += 1
		if _errors.size() < 200:
			_errors.append("[%.1f] %s" % [_t, l])
	if _peer == null and _srv.is_connection_available():
		_peer = _srv.take_connection()
		_buf = PackedByteArray()
	if _peer == null:
		return
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_peer = null
		return
	var n := _peer.get_available_bytes()
	if n > 0:
		var got := _peer.get_data(n)
		if got[0] == OK:
			_buf.append_array(got[1])
	if not _busy:
		var nl := _buf.find(10)
		if nl >= 0:
			var line := _buf.slice(0, nl).get_string_from_utf8()
			_buf = _buf.slice(nl + 1)
			_busy = true
			_handle(line)


func _reply(d: Dictionary) -> void:
	if _peer != null:
		_peer.put_data((JSON.stringify(d) + "\n").to_utf8_buffer())
	_busy = false


func _handle(line: String) -> void:
	var cmd = JSON.parse_string(line)
	if typeof(cmd) != TYPE_DICTIONARY:
		_reply({"error": "bad json"})
		return
	var res := {}
	match String(cmd.get("cmd", "")):
		"state":
			res = _state()
		"ui":
			res = {"ui": _ui(String(cmd.get("filter", "")))}
		"shot":
			res = await _shot(String(cmd.get("name", "")), float(cmd.get("scale", 0.75)))
		"click":
			res = await _click(cmd)
		"tap":
			res = await _tap_cmd(cmd)
		"key":
			res = await _key_cmd(cmd)
		"type":
			res = await _type_cmd(cmd)
		"run":
			res = await _run(cmd)
		"wait":
			res = await _wait_real(float(cmd.get("secs", 1.0)))
		"step":
			step_mode = bool(cmd.get("on", true))
			_settle_pause()
			res = {"step": step_mode}
		"errors":
			res = {"errors": _errors, "total": _all_errors}
			if bool(cmd.get("clear", false)):
				_errors = PackedStringArray()
		"eval":
			res = _eval(String(cmd.get("expr", "")))
		"quit":
			_reply({"ok": true})
			get_tree().quit()
			return
		_:
			res = {"error": "unknown cmd"}
	if bool(cmd.get("with_shot", false)) and not res.has("shot"):
		var s := await _shot(String(cmd.get("name", "")), float(cmd.get("scale", 0.75)))
		res["shot"] = s.get("shot", "")
	if bool(cmd.get("with_state", false)) and not res.has("state"):
		res["state"] = _state()
	_reply(res)


# ------------------------------------------------------------ helpers

func _arena() -> Arena:
	return get_tree().current_scene as Arena


func _in_arena() -> bool:
	return _arena() != null


func _settle_pause() -> void:
	get_tree().paused = step_mode and _in_arena() and not bool(_arena()._finished)


func _resume() -> void:
	get_tree().paused = false


func _frames_wait(sec: float) -> void:
	var end := _t + sec
	while _t < end:
		await get_tree().process_frame


func _wait_real(sec: float) -> Dictionary:
	_resume()
	await _frames_wait(sec)
	_settle_pause()
	return {"ok": true, "state": _state()}


func _push(ev: InputEvent) -> void:
	get_viewport().push_input(ev, true)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	_push(ev)


func _drag(index: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = rel
	_push(ev)


func _centre(c: Control) -> Vector2:
	return c.get_global_transform_with_canvas() * (c.size * 0.5)


func _rect(c: Control) -> Rect2:
	var xf := c.get_global_transform_with_canvas()
	var p0 := xf * Vector2.ZERO
	var p1 := xf * c.size
	return Rect2(p0, p1 - p0)


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		var kids := n.get_children()
		kids.reverse()
		stack.append_array(kids)
	return out


func _text_of(c: Control) -> String:
	var t := ""
	if c is Label:
		t = (c as Label).text
	elif c is Button:
		t = (c as Button).text
	elif c is LineEdit:
		t = "[edit] " + (c as LineEdit).text + " | " + (c as LineEdit).placeholder_text
	elif c is RichTextLabel:
		t = (c as RichTextLabel).get_parsed_text()
	if c is BaseButton and t.strip_edges().is_empty():
		var parts := PackedStringArray()
		for k in _descendants(c):
			if k != c and k is Label and (k as Label).is_visible_in_tree():
				parts.append((k as Label).text)
		t = " / ".join(parts)
	return t.replace("\n", " ⏎ ")


func _ui(filter: String) -> Array:
	var out := []
	var vr := get_viewport().get_visible_rect()
	for n in _descendants(get_tree().root):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		var is_btn := c is BaseButton or c is FireButton or c is SuperButton \
				or c is MembraneButton or c is LineEdit or c is TouchStick
		var t := _text_of(c)
		if not is_btn and t.strip_edges().is_empty():
			continue
		if c.modulate.a < 0.05:
			continue
		var r := _rect(c)
		if r.size.x < 1 or r.size.y < 1:
			continue
		if not filter.is_empty() and not t.to_lower().contains(filter.to_lower()) \
				and not c.get_class().to_lower().contains(filter.to_lower()):
			continue
		var e := {"cls": c.get_class() if c.get_script() == null else str(c.get_script().get_global_name()),
			"text": t.substr(0, 90), "r": [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]}
		if c is BaseButton:
			e["btn"] = true
			if (c as BaseButton).disabled:
				e["disabled"] = true
		elif is_btn:
			e["btn"] = true
		if not vr.grow(2).encloses(r):
			e["offscreen"] = true
		out.append(e)
		if out.size() >= 160:
			break
	return out


func _find_ctrl(text: String, nth: int) -> Control:
	var hits: Array[Control] = []
	for n in _descendants(get_tree().root):
		var c := n as Control
		if c == null or not c.is_visible_in_tree():
			continue
		if not (c is BaseButton or c is LineEdit or c is FireButton or c is SuperButton or c is MembraneButton):
			continue
		var t := _text_of(c)
		if t.to_lower().contains(text.to_lower()) or c.name.to_lower() == text.to_lower():
			hits.append(c)
	if hits.is_empty():
		return null
	return hits[clampi(nth, 0, hits.size() - 1)]


# ------------------------------------------------------------ commands

func _shot(name: String, scale: float) -> Dictionary:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if scale > 0.0 and scale < 0.999:
		img.resize(int(img.get_width() * scale), int(img.get_height() * scale), Image.INTERPOLATE_BILINEAR)
	_shot_n += 1
	var fn := "%03d_%s.png" % [_shot_n, name if not name.is_empty() else "shot"]
	var path := out_dir.path_join(fn)
	img.save_png(path)
	return {"shot": path}


func _mouse_click(p: Vector2, hold: float) -> void:
	var move := InputEventMouseMotion.new()
	move.position = p
	move.global_position = p
	_push(move)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	_push(down)
	await _frames_wait(hold)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	_push(up)
	await get_tree().process_frame


func _click(cmd: Dictionary) -> Dictionary:
	var p := Vector2.INF
	var what := ""
	if cmd.has("text"):
		var c := _find_ctrl(String(cmd["text"]), int(cmd.get("nth", 0)))
		if c == null:
			return {"error": "not found: " + String(cmd["text"])}
		p = _centre(c)
		what = _text_of(c)
		if c is BaseButton and (c as BaseButton).disabled:
			what += " (DISABLED)"
	else:
		p = Vector2(float(cmd.get("x", 0)), float(cmd.get("y", 0)))
	_resume()
	if bool(cmd.get("touch", false)):
		_touch(5, p, true)
		await _frames_wait(float(cmd.get("hold", 0.06)))
		_touch(5, p, false)
	else:
		await _mouse_click(p, float(cmd.get("hold", 0.0)))
	await _frames_wait(float(cmd.get("wait", 0.5)))
	_settle_pause()
	return {"ok": true, "at": [p.x, p.y], "what": what, "state": _state()}


func _tap_cmd(cmd: Dictionary) -> Dictionary:
	var p := Vector2(float(cmd.get("x", 0)), float(cmd.get("y", 0)))
	_resume()
	_touch(int(cmd.get("index", 5)), p, true)
	await _frames_wait(float(cmd.get("hold", 0.07)))
	_touch(int(cmd.get("index", 5)), p, false)
	await _frames_wait(float(cmd.get("wait", 0.3)))
	_settle_pause()
	return {"ok": true, "state": _state()}


func _keycode(k: String) -> int:
	match k.to_upper():
		"ESC", "ESCAPE": return KEY_ESCAPE
		"SPACE": return KEY_SPACE
		"ENTER": return KEY_ENTER
		"SHIFT": return KEY_SHIFT
		"LEFT": return KEY_LEFT
		"RIGHT": return KEY_RIGHT
		"UP": return KEY_UP
		"DOWN": return KEY_DOWN
		"BACKSPACE": return KEY_BACKSPACE
		"TAB": return KEY_TAB
	return OS.find_keycode_from_string(k.to_upper())


func _key_ev(code: int, pressed: bool, ch := "") -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	if not ch.is_empty():
		ev.unicode = ch.unicode_at(0)
	Input.parse_input_event(ev)


func _key_cmd(cmd: Dictionary) -> Dictionary:
	var code := _keycode(String(cmd.get("key", "")))
	_resume()
	_key_ev(code, true)
	await _frames_wait(float(cmd.get("hold", 0.08)))
	_key_ev(code, false)
	await _frames_wait(float(cmd.get("wait", 0.3)))
	_settle_pause()
	return {"ok": true, "state": _state()}


func _type_cmd(cmd: Dictionary) -> Dictionary:
	var s := String(cmd.get("text", ""))
	_resume()
	var f := get_viewport().gui_get_focus_owner()
	if f is LineEdit and bool(cmd.get("direct", false)):
		(f as LineEdit).insert_text_at_caret(s)
	else:
		for ch in s:
			var code := OS.find_keycode_from_string(ch.to_upper())
			_key_ev(code, true, ch)
			await get_tree().process_frame
			_key_ev(code, false, ch)
			await get_tree().process_frame
	await _frames_wait(0.2)
	_settle_pause()
	return {"ok": true, "focus": str(f), "state": _state()}


var _stick_arena := 0


func _steer(a: Arena, dir: Vector2) -> void:
	var stick := a._hud.move_stick
	if _stick_arena != a.get_instance_id():
		_stick_arena = a.get_instance_id()
		_stick_down = false
		_stick_dir = Vector2.ZERO
	if dir.length() < 0.05:
		if _stick_down:
			_touch(0, _stick_origin + _stick_dir * stick.max_radius * 0.85, false)
			_stick_down = false
			_stick_dir = Vector2.ZERO
		return
	var n := dir.normalized() * minf(dir.length(), 1.0)
	if not _stick_down:
		var r := _rect(stick)
		_stick_origin = r.position + r.size * Vector2(0.32, 0.62)
		_touch(0, _stick_origin, true)
		_stick_down = true
		_stick_dir = Vector2.ZERO
	if n.distance_to(_stick_dir) > 0.02:
		var from := _stick_origin + _stick_dir * stick.max_radius * 0.85
		var to := _stick_origin + n * stick.max_radius * 0.85
		_drag(0, to, to - from)
		_stick_dir = n


## Atəş: tap (avtomatik nişan) və ya aim (istiqamət + güc).
func _fire(a: Arena, aim, power: float) -> void:
	var b := a._hud.fire_button
	var c := _centre(b)
	_touch(1, c, true)
	await get_tree().process_frame
	if aim != null:
		var d := Vector2(float(aim[0]), float(aim[1])).normalized()
		var rad: float = b.radius * (b.DEAD + (1.0 - b.DEAD) * clampf(power, 0.0, 1.0)) + 4.0
		var scale := _rect(b).size.x / maxf(b.size.x, 1.0)
		var to := c + d * rad * scale
		_drag(1, c + d * 8.0, d * 8.0)
		await get_tree().process_frame
		_drag(1, to, to - c)
		await get_tree().process_frame
		await get_tree().process_frame
		_touch(1, to, false)
	else:
		await get_tree().process_frame
		_touch(1, c, false)


func _run(cmd: Dictionary) -> Dictionary:
	var a := _arena()
	var secs := float(cmd.get("secs", 1.0))
	if a == null:
		return await _wait_real(secs)
	var mv = cmd.get("move", null)
	var dir := Vector2.ZERO
	if mv is Array and mv.size() == 2:
		dir = Vector2(float(mv[0]), float(mv[1]))
	var target = cmd.get("toward", null)   # dünyada nöqtə — hər kadr ona tərəf
	var fire := String(cmd.get("fire", ""))
	var aim = cmd.get("aim", null)
	var aim_enemy := bool(cmd.get("aim_enemy", false))
	var power := float(cmd.get("power", 0.6))
	var every := float(cmd.get("fire_every", 0.0))
	var use_super := bool(cmd.get("super", false))
	var super_aim = cmd.get("super_aim", null)
	var membrane_at := float(cmd.get("membrane_at", -1.0))
	var keys: Array = cmd.get("keys", [])
	var before := _me_brief(a)
	var log := []
	_resume()
	var t0 := _t
	var end := _t + secs
	var fire_next := _t if not fire.is_empty() else INF
	var did_super := false
	var did_mem := false
	for k in keys:
		_key_ev(_keycode(String(k)), true)
	var last_balls := a.me.balls if a.me != null else 0
	var last_cap := a.me.capacity if a.me != null else 0
	var last_phase := a._phase
	var hud_prev := _hud_texts(a)
	var last_bursts := 0
	var last_flash := false
	var last_dead: bool = a._own_dead()
	var shot_every := float(cmd.get("shot_every", 0.0))
	var next_shot := _t + shot_every
	var shots := []
	while _t < end:
		if not is_instance_valid(a) or get_tree().current_scene != a:
			log.append("[%.2f] arena closed" % (_t - t0))
			break
		if a._finished:
			log.append("[%.2f] finished" % (_t - t0))
			# Nəticə ekranı öz taymeri ilə keçir — dərhal və bir neçə dəfə çək.
			for k in int(cmd.get("finish_shots", 3)):
				var fs := await _shot("finish", 0.6)
				shots.append(fs["shot"].get_file())
				log.append("[%.2f] finish shot %s scene=%s" % [_t - t0, fs["shot"].get_file(),
					str(get_tree().current_scene.name) if get_tree().current_scene else "?"])
				await _frames_wait(1.3)
			break
		var hud_now := _hud_texts(a)
		for k in hud_now:
			if String(hud_prev.get(k, "")) != String(hud_now[k]):
				log.append("[%.2f] hud.%s=%s" % [_t - t0, k, hud_now[k]])
		for k in hud_prev:
			if not hud_now.has(k):
				log.append("[%.2f] hud.%s hidden" % [_t - t0, k])
		hud_prev = hud_now
		if a.me != null:
			var d := dir
			if target is Array and target.size() == 2:
				var tp := Vector2(float(target[0]), float(target[1]))
				d = (tp - a.me.pos)
				d = d.normalized() if d.length() > 30.0 else Vector2.ZERO
			elif target is String:
				var tp2 := Vector2.INF
				match String(target):
					"food":
						var fd: Dictionary = a._nearest_food()
						if not fd.is_empty():
							tp2 = fd["pos"]
					"enemy":
						var en := _nearest_enemy(a)
						if not en.is_empty():
							tp2 = en["pos"]
					"center":
						tp2 = Vector2.ZERO
				if tp2.is_finite():
					d = (tp2 - a.me.pos)
					var keep := float(cmd.get("keep", 0.0))
					if keep > 0.0 and String(target) == "enemy":
						var dist := d.length()
						var radial := d.normalized() * clampf((dist - keep) / 120.0, -1.0, 1.0)
						var tang := d.normalized().orthogonal() * float(cmd.get("orbit", 0.0))
						d = radial + tang
						d = d.normalized() if d.length() > 0.15 else Vector2.ZERO
					else:
						d = d.normalized() if d.length() > 20.0 else Vector2.ZERO
				else:
					d = dir
			if bool(cmd.get("flee", false)):
				var en2 := _nearest_enemy(a)
				if not en2.is_empty():
					d = (a.me.pos - Vector2(en2["pos"])).normalized()
			if a._mode != Const.Mode.ENDLESS and bool(cmd.get("stay_wet", true)) \
					and a.me.pos.distance_to(a._wet_center) > a._wet_radius * 0.8:
				d = (a._wet_center - a.me.pos).normalized()
			_steer(a, d)
			var bursts := 0
			for c in a._fx.get_children():
				if c is BurstFx:
					bursts += 1
			if bursts > last_bursts:
				log.append("[%.2f] BURST fx (+%d)" % [_t - t0, bursts - last_bursts])
			last_bursts = bursts
			var v: GermVisual = a._visuals.get(a.my_id, {}).get("node")
			var flash := v != null and v._flash > 0.05
			if flash and not last_flash:
				log.append("[%.2f] hit taken" % (_t - t0))
			last_flash = flash
		if String(fire) == "auto" and a.me != null and _t >= fire_next:
			var ea := _nearest_enemy(a)
			if not ea.is_empty() and float(ea["d"]) < float(cmd.get("range", 520.0)) \
					and a.me.cooldown <= 0.0 and a.me.balls > Const.FIRE_MIN_BALLS + int(cmd.get("reserve", 0)):
				var epa: Vector2 = ea["pos"]
				var pw := clampf((float(ea["d"]) - 180.0) / 280.0, 0.0, 1.0)
				await _fire(a, [epa.x - a.me.pos.x, epa.y - a.me.pos.y] if bool(cmd.get("aimed", true)) else null, pw)
				log.append("[%.2f] autofire d=%d balls=%d" % [_t - t0, int(ea["d"]), a.me.balls])
				fire_next = _t + maxf(every, 0.35)
			if not is_instance_valid(a):
				break
		var dead_now: bool = a._own_dead()
		if dead_now != last_dead:
			log.append("[%.2f] OWN_DEAD=%s clock=%.2f balls=%d" % [_t - t0, str(dead_now), a._clock,
				a.me.balls if a.me != null else -1])
			last_dead = dead_now
		if a.me != null:
			if a.me.balls != last_balls:
				log.append("[%.2f] balls %d→%d" % [_t - t0, last_balls, a.me.balls])
				last_balls = a.me.balls
			if a.me.capacity != last_cap:
				log.append("[%.2f] cap %d→%d" % [_t - t0, last_cap, a.me.capacity])
				last_cap = a.me.capacity
		if a._phase != last_phase:
			log.append("[%.2f] phase %d→%d" % [_t - t0, last_phase, a._phase])
			last_phase = a._phase
		if _t >= fire_next and fire != "auto":
			var aim_v = aim
			if aim_enemy:
				var e := _nearest_enemy(a)
				if not e.is_empty():
					var ep: Vector2 = e["pos"]
					aim_v = [ep.x - a.me.pos.x, ep.y - a.me.pos.y]
					power = clampf((ep.distance_to(a.me.pos) - 180.0) / 280.0, 0.0, 1.0) if a.me.species == Const.Species.AMOEBA else power
			await _fire(a, aim_v if fire == "aim" or aim_enemy else null, power)
			log.append("[%.2f] fire %s" % [_t - t0, str(aim_v) if aim_v != null else "tap"])
			fire_next = _t + every if every > 0.0 else INF
		if use_super and not did_super:
			did_super = true
			var sb := a._hud.super_button
			if super_aim != null:
				var c := _centre(sb)
				var dd := Vector2(float(super_aim[0]), float(super_aim[1])).normalized()
				_touch(2, c, true)
				await get_tree().process_frame
				_drag(2, c + dd * 60.0, dd * 60.0)
				await get_tree().process_frame
				await get_tree().process_frame
				_touch(2, c + dd * 60.0, false)
			else:
				var c2 := _centre(sb)
				_touch(2, c2, true)
				var hold := float(cmd.get("super_hold", 0.07))
				get_tree().create_timer(hold).timeout.connect(_touch.bind(2, c2, false))
			log.append("[%.2f] super tap ready=%s" % [_t - t0, str(a.me.super_ready() if a.me else false)])
		if membrane_at >= 0.0 and not did_mem and _t - t0 >= membrane_at:
			did_mem = true
			_touch(3, _centre(a._hud.membrane_button), true)
			get_tree().create_timer(0.06).timeout.connect(_touch.bind(3, _centre(a._hud.membrane_button), false))
			log.append("[%.2f] membrane tap ready=%s" % [_t - t0, str(a.me.membrane_ready() if a.me else false)])
		if shot_every > 0.0 and _t >= next_shot:
			next_shot = _t + shot_every
			var sh := await _shot(String(cmd.get("name", "run")), float(cmd.get("scale", 0.6)))
			shots.append(sh["shot"].get_file())
			continue
		await get_tree().process_frame
	for k in keys:
		_key_ev(_keycode(String(k)), false)
	if bool(cmd.get("release", false)) and is_instance_valid(a):
		_steer(a, Vector2.ZERO)
	_settle_pause()
	var res := {"ok": true, "before": before, "log": log, "state": _state()}
	if not shots.is_empty():
		res["shots"] = shots
	return res


func _hud_texts(a: Arena) -> Dictionary:
	var out := {}
	var h := a._hud
	if h == null:
		return out
	for k in ["_warn_lbl", "_center_lbl", "_sub_lbl", "_result_title", "_result_body", "_level_lbl", "_obj_mid", "_alive_lbl", "_score_lbl"]:
		var l = h.get(k)
		if l is Label and (l as Label).is_visible_in_tree() and not (l as Label).text.is_empty() \
				and (l as Label).modulate.a > 0.05:
			out[k.trim_prefix("_")] = (l as Label).text.replace("\n", " | ")
	return out


func _nearest_enemy(a: Arena) -> Dictionary:
	if a._last_snap.is_empty() or a.me == null:
		return {}
	var best := {}
	var best_d := INF
	for e in a._last_snap[Const.Snap.GERMS]:
		if int(e[Const.GF.ID]) == a.my_id:
			continue
		var flags := int(e[Const.GF.FLAGS])
		var team := ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) - 1
		if a._my_team >= 0 and team == a._my_team:
			continue
		var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
		var d := a.me.pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p, "d": d}
	return best


func _me_brief(a: Arena) -> Dictionary:
	if a == null or a.me == null:
		return {}
	var m := a.me
	return {"pos": [int(m.pos.x), int(m.pos.y)], "balls": m.balls, "cap": m.capacity, "charge": m.charge}


func _state() -> Dictionary:
	var s := {"t": snappedf(_t, 0.01), "paused": get_tree().paused, "step": step_mode,
		"errors_new": _errors.size(), "errors_total": _all_errors,
		"fps": Engine.get_frames_per_second(), "spikes": _spikes, "frame_ms_max": snappedf(_frame_ms_max, 0.1)}
	var sc := get_tree().current_scene
	s["scene"] = "" if sc == null else (sc.get_script().get_global_name() if sc.get_script() != null else sc.name)
	var a := sc as Arena
	if a == null:
		return s
	s["mode"] = int(a._mode)
	s["phase"] = int(a._phase)
	s["phase_t"] = snappedf(a._phase_t, 0.1)
	s["finished"] = a._finished
	s["practice"] = a.practice
	s["wet_r"] = int(a._wet_radius)
	s["hidden"] = a._hidden
	s["my_team"] = a._my_team
	if a.me != null:
		var m := a.me
		s["me"] = {"id": a.my_id, "pos": [int(m.pos.x), int(m.pos.y)], "vel": [int(m.vel.x), int(m.vel.y)],
			"balls": m.balls, "cap": m.capacity, "charge": m.charge, "super_ready": m.super_ready(),
			"super_t": snappedf(m.super_t, 0.01), "cd": snappedf(m.cooldown, 0.01), "safe": snappedf(m.safe_t, 0.1),
			"species": int(m.species), "mem_cd": snappedf(m.mem_cd, 0.1), "mem_ready": m.membrane_ready(),
			"pops": m.pops, "age": snappedf(m.age, 0.1), "mut": m.mutations, "alive": m.alive, "dead_wait": a._own_dead()}
	var ens := []
	if not a._last_snap.is_empty() and a.me != null:
		for e in a._last_snap[Const.Snap.GERMS]:
			if int(e[Const.GF.ID]) == a.my_id:
				continue
			var flags := int(e[Const.GF.FLAGS])
			var team := ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) - 1
			var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
			var off := p - a.me.pos
			ens.append({"id": int(e[Const.GF.ID]), "d": int(off.length()), "dir": [snappedf(off.normalized().x, 0.01), snappedf(off.normalized().y, 0.01)],
				"balls": int(e[Const.GF.BALLS]), "cap": int(e[Const.GF.CAP]), "team": team,
				"mate": a._my_team >= 0 and team == a._my_team})
		ens.sort_custom(func(x, y): return x["d"] < y["d"])
	s["germs"] = ens.slice(0, 8)
	var f: Dictionary = a._nearest_food() if a.me != null else {}
	if not f.is_empty():
		var fp: Vector2 = f["pos"]
		s["food"] = {"pos": [int(fp.x), int(fp.y)], "d": int(fp.distance_to(a.me.pos))}
	var h := a._hud
	if h != null:
		var hud := {}
		for k in ["_gauge_lbl", "_level_lbl", "_warn_lbl", "_board_lbl", "_pop_lbl", "_alive_lbl", "_score_lbl",
				"_obj_us", "_obj_mid", "_obj_them", "_center_lbl", "_sub_lbl", "_result_title", "_result_body", "_net_lbl"]:
			var l = h.get(k)
			if l is Label and (l as Label).is_visible_in_tree() and not (l as Label).text.is_empty():
				hud[k.trim_prefix("_")] = (l as Label).text.replace("\n", " | ")
		hud["leave_prompt"] = h.is_leave_prompt_open()
		hud["hint"] = h._hint
		s["hud"] = hud
	return s


func _eval(expr: String) -> Dictionary:
	var e := Expression.new()
	if e.parse(expr, ["tree", "arena", "menu"]) != OK:
		return {"error": e.get_error_text()}
	var sc := get_tree().current_scene
	var v = e.execute([get_tree(), sc as Arena, sc as MenuV2], self)
	if e.has_execute_failed():
		return {"error": e.get_error_text()}
	return {"value": str(v)}
