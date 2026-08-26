class_name Arena
extends Node2D
## Oyun ekranı: girişi toplayır, proqnoz qurur, serverin sözünü qəbul edir və çəkir.
##
## Üç fərqli zaman xətti burada birləşir:
##   1. İndi         — öz mikrobun. Girişi dərhal tətbiq olunur (prediction).
##   2. 100 ms əvvəl — rəqiblər, toplar və qida. Snapshot-lar arasında interpolyasiya.
##   3. Serverin sözü — snapshot gələndə öz vəziyyətin düzəldilir (reconciliation).
##
## Rəqibləri qəsdən 100 ms geridə göstəririk: paket itsə belə interpolyasiya üçün
## əlimizdə həmişə iki snapshot olur, hərəkət titrəmir.
##
## Dünya ekrandan böyükdür, ona görə kamera mikrobu izləyir və tutum böyüdükcə
## uzaqlaşır — böyük mikrob daha geniş sahə görür.

const SNAP_BUFFER_MAX := 24
const FX_LIFETIME := 0.26

## Bağlantı kəsiləndə neçə dəfə və hansı aralıqla qayıtmağa çalışırıq.
## Serverin saxladığı müddətə (Lobby.REJOIN_GRACE = 20 s) sığmalıdır.
const REJOIN_ATTEMPTS := 5
const REJOIN_INTERVAL := 3.0

## Qida sprite-ının miqyası — 32 px-lik şəkil FOOD_RADIUS ilə uyğunlaşdırılır.
const FOOD_SCALE := 0.85

## Serverin artıq bildirmədiyi obyektin görüntüsü bu qədər saniyə saxlanılır.
##
## Rəqəm təsadüfi deyil: biz keçmişi göstəririk (INTERP_DELAY = 100 ms), ona görə
## obyekt son görüldüyü andan düz bir interpolyasiya gecikməsi sonra ekrandan
## çıxmalıdır — nə tez (udulan qida qığılcımdan əvvəl yox olar), nə gec
## (udulmuş qida ekranda qalar). Üstünə bir tick əlavə olunur ki, itən bir
## paket obyekti yanıb-söndürməsin.
const VIEW_GRACE := Const.INTERP_DELAY + Const.TICK_DELTA

## Yerli doğuş nöqtəsi bu qədər saniyə gözləyir (bax [method _remember_muzzle]).
##
## Atəş fasiləsindən (FIRE_COOLDOWN = 1 s) KİÇİK olmalıdır: belə olanda
## növbədə heç vaxt iki gözləyən atəş qalmır, yəni səhv uyğunlaşma mümkün
## deyil. Serverin qəbul etmədiyi atəş isə özü düşüb gedir.
const MUZZLE_GRACE := 0.6

# ---------------------------------------------------------------- vəziyyət

var my_id := 0
var my_color := 0
var practice := false

var pred: Sim                       ## Yalnız lokal mikrobu saxlayan proqnoz
var me: Sim.GermState
var pending: Array[Sim.PlayerInput] = []

## Şəbəkə testi üçün: joystick əvəzinə avtomatik giriş üretilir.
var auto_input := false

var _seq := 0
var _tick_accum := 0.0
var _clock := 0.0
var _snaps: Array[Dictionary] = []  ## {"t": lokal vaxt, "d": snapshot}
var _last_snap: Array = []
var _finished := false

## Mikroba qayıtmaq üçün sessiya nişanı — serverdən dünyaya girəndə gəlir.
var _token := ""
var _reconnecting := false
var _rejoin_left := 0

var _local_world: World = null      ## Yalnız məşq rejimində

# ---------------------------------------------------------------- vizual

var _cam: Camera2D
var _blobs: Node2D
var _food_layer: Node2D
var _shot_layer: Node2D
var _entities: Node2D
var _fx: Node2D
var _motes: WaterMotes
var _hud: Hud

var _visuals := {}                  ## germ id -> {"node": GermVisual, "seen": float}
var _food_views := {}               ## food id -> {"node": Sprite2D, "seen": float}
var _shot_views := {}               ## shot id -> Dictionary
## Öz atəşlərinin doğuş nöqtələri — serverin topu təsdiqləməsini gözləyir
## (bax [method _remember_muzzle]).
var _muzzles: Array[Dictionary] = []
var _fx_queue: Array[Dictionary] = []
var _tex := {}
var _view_w := Const.VIEW_WIDTH_BASE
var _shake := 0.0


# ================================================================ quraşdırma

## Serverdən "dünyaya girdin" mesajı gələndə çağırılır. add_child-dan ƏVVƏL.
func configure_online(info: Dictionary) -> void:
	practice = false
	my_id = int(info["you"])
	my_color = int(info.get("color", 0))
	Net.species = _species_from(info)
	_token = str(info.get("token", ""))


## Serverin təsdiqlədiyi növ.
##
## Menyudakı seçim TƏKLİFDİR, son söz serverindir: yenidən qoşulanda oyunçu
## köhnə mikrobuna qayıdır və onun növü artıq dünyada qeydə alınıb.
## Etibarsız dəyər gəlsə kirpikliyə düşür.
static func _species_from(info: Dictionary) -> Const.Species:
	return Const.species_from(int(info.get("species", 0)))


## Şəbəkəsiz məşq. Eyni [World] və [Sim] kodu yerli işləyir — fərq yalnız
## snapshot-ların şəbəkədən yox, yaddaşdan gəlməsidir.
func configure_practice() -> void:
	practice = true
	my_id = 1000
	_local_world = World.new(1)
	var g := _local_world.add_player(my_id, Net.nickname, Net.species)
	my_color = g.color


func _ready() -> void:
	_load_textures()
	_build_world()
	_build_hud()
	_init_prediction()

	Net.snapshot_arrived.connect(_on_snapshot)
	Net.you_burst.connect(_on_you_burst)
	Net.server_disconnected.connect(_on_server_lost)
	Net.connected_to_server.connect(_on_reconnected)
	Net.world_joined.connect(_on_rejoin_accepted)
	Net.rejoin_failed.connect(_on_rejoin_rejected)

	_hud.show_message("DÜNYAYA GİRDİN", "Qida ye, rəqibi doldur, partlat")
	get_tree().create_timer(2.0).timeout.connect(_hud.hide_message)
	Sfx.play("spawn")


func _load_textures() -> void:
	_tex = {
		"food": load("res://assets/sprites/food_ball.svg"),
		"blob": load("res://assets/sprites/mucus_blob.svg"),
		"shot": load("res://assets/sprites/shot_ball.svg"),
		"spark": load("res://assets/sprites/spark.svg"),
		"burst": load("res://assets/sprites/burst.svg"),
		"stick_base": load("res://assets/ui/joystick_base.svg"),
		"stick_knob": load("res://assets/ui/joystick_knob.svg"),
	}


## Səhnə qatları QƏSDƏN növlərə ayrılıb: bütün qida sprite-ları bir qatda,
## bütün toplar başqasında, mikroblar üçüncüsündə.
##
## Səbəb çəkiliş çağırışıdır: Godot yalnız ARDICIL və eyni teksturalı
## elementləri bir çağırışa yığır. Hamısı bir node-un altında qarışıq
## dursaydı, hər qida topu ayrıca çağırış olardı.
func _build_world() -> void:
	# Qab və şəbəkə bu node-un öz `_draw`-ında çəkilir (bax [method _draw]):
	# statik məzmundur və uşaqların arxasında qalır.
	_blobs = Node2D.new()
	add_child(_blobs)
	_spawn_obstacles()

	# Suda asılı zərrəciklər — qabın döşəməsi ilə oyun obyektləri arasındakı
	# "su" qatı. Sırası MƏHZ buradadır: bu node-un öz `_draw`-ı (döşəmə) və
	# maneələr artıq çəkilib, qida ilə mikroblar isə sonra əlavə olunur.
	_motes = WaterMotes.new()
	add_child(_motes)

	_food_layer = Node2D.new()
	add_child(_food_layer)

	_shot_layer = Node2D.new()
	add_child(_shot_layer)

	_entities = Node2D.new()
	add_child(_entities)

	_fx = Node2D.new()
	add_child(_fx)

	_cam = Camera2D.new()
	_cam.enabled = true
	add_child(_cam)


## Maneələr sprite kimi çəkilir: 22 ləkənin hamısı eyni teksturadadır,
## ona görə bir neçə çağırışa yığılır. Kodla çəkilsəydi hər biri ayrıca
## dairə + kontur, yəni 44 çağırış olardı.
func _spawn_obstacles() -> void:
	var tex: Texture2D = _tex["blob"]
	# Sprite-dakı ləkənin radiusu 120 px-dir (bax mucus_blob.svg).
	const SPRITE_RADIUS := 120.0
	for o in DishMap.obstacles():
		var spr := Sprite2D.new()
		spr.texture = tex
		spr.position = Vector2(o.x, o.y)
		spr.scale = Vector2.ONE * (o.z / SPRITE_RADIUS)
		# Hər ləkə bir az fırlanıb: eyni şəkil təkrarlandığı bilinməsin.
		spr.rotation = float(o.x + o.y) * 0.01
		_blobs.add_child(spr)


func _build_hud() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_hud.build(_tex["stick_base"], _tex["stick_knob"])
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.fire_button.fired.connect(_on_fire_pressed)


func _init_prediction() -> void:
	pred = Sim.new()
	me = pred.add_germ(my_id, Net.nickname, my_color)


# ================================================================ dövr

func _process(delta: float) -> void:
	_clock += delta

	_tick_accum += delta
	var steps := 0
	while _tick_accum >= Const.TICK_DELTA and steps < 5:
		_tick_accum -= Const.TICK_DELTA
		steps += 1
		_do_tick()
	if steps == 5:
		_tick_accum = 0.0

	_render(delta)


func _do_tick() -> void:
	if _finished or _reconnecting:
		return

	var inp := _sample_input()

	if _local_world != null:
		_local_world.accept_input(my_id, inp.to_array())
		var bursts := _local_world.tick(Const.TICK_DELTA)
		_on_snapshot(_local_world.snapshot_for(my_id))
		for entry in bursts:
			if int(entry["id"]) == my_id:
				_on_you_burst({
					"pops": entry["pops"], "cap": entry["cap"],
					"level": Const.level_of(int(entry["cap"])),
					"age": entry["age"], "killer": entry["killer_name"],
				})
	else:
		Net.send_input.rpc_id(1, inp.to_array())

	pending.append(inp)
	while pending.size() > Const.INPUT_BUFFER_MAX:
		pending.pop_front()

	# Öz hərəkətini dərhal göstəririk — server cavabını gözləsək, idarə ağır hiss olunardı.
	pred.step_movement({my_id: inp}, Const.TICK_DELTA, true)
	for e in pred.events:
		if e.get("t") == "fire":
			_spawn_fx("spark", e["pos"], 0.5, Palette.germ_color(my_color))
			Sfx.play("eject", 0.06)
			_eject_from(my_color, float(e["arg"]))
			_remember_muzzle(Vector2(e["pos"]), float(e["arg"]))

	_hud.set_fire_state(me.cooldown / Const.FIRE_COOLDOWN, me.balls >= Const.FIRE_MIN_BALLS)
	_hud.update_gauge(me.balls, me.capacity)


## Joystick-dən bir tick-lik giriş yığır.
func _sample_input() -> Sim.PlayerInput:
	_seq += 1
	if auto_input:
		return _auto_sample()

	var move := _hud.move_stick.value

	# Masaüstündə klaviatura joysticki əvəz edir. Bu, yalnız rahatlıq deyil:
	# siçan bir toxunuş kimi emulyasiya olunur, yəni eyni anda həm hərəkət,
	# həm atəş mümkün olmur — PC-də oyunu sınamağın yeganə düzgün yolu budur.
	if move == Vector2.ZERO:
		move = _keyboard_move()

	# Nişan almaq yoxdur — getdiyin tərəfə atırsan. Dayanmısansa, son baxdığın
	# tərəf qalır ki, yerində durub atmaq da mümkün olsun.
	var aim := me.aim
	if move.length() > 0.01:
		aim = move.angle()

	return Sim.PlayerInput.make(_seq, move, aim, _fire_requested())


## WASD / ox düymələri. Diaqonal da normallaşdırılır ki, çəp getmək
## sürət qazandırmasın.
static func _keyboard_move() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	return v.limit_length(1.0)


var _fire_flag := false


## Düymə basılı saxlanılanda atəş davam edir; bayraq isə bir kadrdan qısa
## toxunuşun itməməsi üçündür. İkisi də sürəti təyin etmir — onu serverdəki
## `FIRE_COOLDOWN` müəyyən edir, ona görə döyəcləmək heç nə qazandırmır.
## Boşluq düyməsi masaüstü üçündür (bax [method _keyboard_move]).
## Siçanın sol düyməsi QƏSDƏN buraya qoşulmayıb: o, ekran joystickini idarə edir,
## atəşə də bağlansaydı sürüşdürərək hərəkət edən oyunçu fasiləsiz atardı.
func _fire_requested() -> bool:
	var f := _fire_flag
	_fire_flag = false
	return f or _hud.fire_button.held \
		or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)


func _on_fire_pressed() -> void:
	_fire_flag = true


## Avtomatik giriş — şəbəkə testində insansız client üçün.
##
## Sadə olsa da acından ölməməlidir: topu azalanda qidaya gedir, çox olanda
## rəqibə. Əks halda test client-i bir neçə saniyəyə partlayır və şəbəkə
## axını heç sınaqdan keçmir.
func _auto_sample() -> Sim.PlayerInput:
	var move := Vector2(sin(_clock * 1.3), cos(_clock * 0.9))
	var aim := me.aim
	var hungry := me.balls <= Const.FIRE_MIN_BALLS + 2

	var meal := _nearest_food()
	var target := _nearest_enemy()

	if hungry and not meal.is_empty():
		var to_food: Vector2 = Vector2(meal["pos"]) - me.pos
		move = to_food.normalized()
		aim = to_food.angle()
	elif not target.is_empty():
		var to: Vector2 = Vector2(target["pos"]) - me.pos
		aim = to.angle()
		move = to.normalized() if to.length() > 320.0 else -to.normalized()

	var fire := me.balls > Const.FIRE_MIN_BALLS and _seq % 8 == 0
	return Sim.PlayerInput.make(_seq, move, aim, fire)


func _nearest_food() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var best := {}
	var best_d := INF
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var p := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


func _nearest_enemy() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var best := {}
	var best_d := INF
	for e in _last_snap[Const.Snap.GERMS]:
		if int(e[Const.GF.ID]) == my_id:
			continue
		var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


# ================================================================ server sözü

func _on_snapshot(data: Array) -> void:
	if data.size() < 7:
		return
	_last_snap = data
	_snaps.append({"t": _clock, "d": data})
	while _snaps.size() > SNAP_BUFFER_MAX:
		_snaps.pop_front()

	for entry in data[Const.Snap.GERMS]:
		if int(entry[Const.GF.ID]) == my_id:
			_reconcile(entry)
			break

	_queue_events(data[Const.Snap.EVENTS], _clock)
	_hud.update_board(data[Const.Snap.BOARD], int(data[Const.Snap.POP]))


## Serverin dediyi vəziyyəti qəbul edir, sonra hələ təsdiqlənməmiş
## girişləri yenidən oynadır — belə öz hərəkətin geri sıçramır.
func _reconcile(entry: Array) -> void:
	me.pos = Vector2(float(entry[Const.GF.X]), float(entry[Const.GF.Y]))
	me.vel = Vector2(float(entry[Const.GF.VX]), float(entry[Const.GF.VY]))
	me.aim = float(entry[Const.GF.AIM])
	me.cooldown = float(entry[Const.GF.CD])
	me.safe_t = 1.0 if int(entry[Const.GF.FLAGS]) & Const.GFlag.SAFE else 0.0

	var balls_before := me.balls
	var cap_before := me.capacity
	me.balls = int(entry[Const.GF.BALLS])
	me.capacity = int(entry[Const.GF.CAP])

	# Rəqib partladı → tutum artdı. Bu, oyunun yeganə mükafatıdır, eşidilməlidir.
	if me.capacity > cap_before:
		Sfx.play("level_up")
		_add_shake(6.0)

	# Kimsə sənə top vurdu: doluluq artdı, amma sən yemədin.
	if me.balls > balls_before + 1:
		_add_shake(4.0)

	if me.balls >= me.capacity - 1 or me.balls <= Const.MIN_BALLS:
		Sfx.play_danger()

	var acked := int(entry[Const.GF.ACK])
	while not pending.is_empty() and pending[0].seq <= acked:
		pending.pop_front()

	# Hadisələr saxlanmır: eyni atəş səsi hər düzəlişdə təkrar çalınmamalıdır.
	for inp in pending:
		pred.step_movement({my_id: inp}, Const.TICK_DELTA, false)


## Mikrobun partladı — oyun bitdi, menyuya qayıdırıq.
func _on_you_burst(result: Dictionary) -> void:
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_result(result)
	# Öz partlayışın daha böyük çəkilir — kamera onun üstündədir və oyun bitir.
	_explode(me.pos, Const.germ_radius(me.capacity), my_color, true)
	Sfx.play("you_burst")
	_add_shake(18.0)
	get_tree().create_timer(4.0).timeout.connect(_return_to_menu)


## Bağlantı kəsildi. Nişanımız varsa oyunu tərk etmirik — server mikrobumuzu
## bir müddət saxlayır, biz isə arxa planda qayıtmağa çalışırıq.
func _on_server_lost() -> void:
	if _finished or _reconnecting or practice:
		return
	if _token.is_empty():
		_give_up("BAĞLANTI KƏSİLDİ")
		return
	_reconnecting = true
	_rejoin_left = REJOIN_ATTEMPTS
	_hud.release_sticks()
	_try_reconnect()


func _try_reconnect() -> void:
	if not _reconnecting:
		return                      # artıq qayıtmışıq
	if _rejoin_left <= 0:
		_reconnecting = false
		_give_up("BAĞLANTI BƏRPA OLUNMADI")
		return

	_rejoin_left -= 1
	_hud.show_message("BAĞLANTI BƏRPA OLUNUR",
		"Cəhd %d / %d" % [REJOIN_ATTEMPTS - _rejoin_left, REJOIN_ATTEMPTS])

	Net.disconnect_from_server()
	Net.join_server(Net.last_address, Net.last_port)

	# Növbəti cəhd nəticədən asılı olmayaraq planlaşdırılır. Uğur olsa
	# `_reconnecting` sönür və bu çağırış yuxarıdakı yoxlamada dayanır.
	# Bu, `connection_failed` siqnalını gözləməkdən daha etibarlıdır:
	# WebSocket-də uğursuz cəhd bəzən heç bir siqnal vermədən asılı qalır.
	get_tree().create_timer(REJOIN_INTERVAL).timeout.connect(_try_reconnect)


func _on_reconnected() -> void:
	if not _reconnecting:
		return
	Net.request_rejoin.rpc_id(1, _token)


## Server nişanı qəbul etdi — eyni mikrobla dünyaya qayıdırıq.
func _on_rejoin_accepted(info: Dictionary) -> void:
	if not _reconnecting:
		return
	_reconnecting = false

	my_id = int(info["you"])
	my_color = int(info.get("color", my_color))
	# Yenidən qoşulanda köhnə mikrobuna qayıdırsan — onun növü serverdəki
	# qeyddir, menyudakı seçim yox.
	Net.species = _species_from(info)
	_token = str(info.get("token", _token))

	# Proqnoz sıfırdan qurulur; ilk snapshot onu dərhal serverin sözünə çəkəcək.
	pending.clear()
	_snaps.clear()
	_init_prediction()
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.hide_message()


## Nişan artıq keçərli deyil: mikrob partlayıb və ya gözləmə vaxtı dolub.
func _on_rejoin_rejected() -> void:
	_reconnecting = false
	_give_up("MİKROBUNA QAYITMAQ MÜMKÜN OLMADI")


func _give_up(title: String) -> void:
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_message(title, "Menyuya qayıdılır...")
	get_tree().create_timer(2.5).timeout.connect(_return_to_menu)


func _return_to_menu() -> void:
	if not practice:
		# Serverə "çıxıram" deyirik: mikrob dərhal silinir, 20 saniyəlik
		# yenidən qoşulma möhləti boş yerə gözlənilmir.
		if Net.is_connected_to_server():
			Net.request_leave.rpc_id(1)
		Net.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


# ================================================================ render

func _render(delta: float) -> void:
	var render_time := _clock - Const.INTERP_DELAY
	_render_germs(render_time)
	_render_shots(render_time)
	_render_food(render_time)
	_flush_fx(render_time)
	_sweep_views()
	_update_camera(delta)
	_update_minimap()


func _update_camera(delta: float) -> void:
	# Böyük mikrob daha geniş sahə görür: bu, həm ədalətlidir (böyük hədəfə
	# uzaqdan da dəyirlər), həm də böyüməni hiss etdirir.
	var want := Const.view_width(me.capacity)
	_view_w = lerpf(_view_w, want, clampf(delta * 2.0, 0.0, 1.0))

	var vp := get_viewport_rect().size
	var k := vp.x / maxf(_view_w, 1.0)
	_cam.zoom = Vector2(k, k)

	var shake := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - 46.0 * delta)
		shake = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_cam.position = me.pos + shake

	# Zərrəciklər kameranı izləyir: dünyanın hamısını doldurmaq əvəzinə
	# yalnız görünən sahədə saxlanılır (bax [WaterMotes]).
	_motes.focus = me.pos
	_motes.span = _view_w


func _add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 20.0)


func _update_minimap() -> void:
	var dots := []
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible:
			continue
		dots.append([v.position, Palette.germ_color(v.color_index), gid == my_id])
	_hud.minimap.set_dots(dots)


# ---------------------------------------------------------------- mikroblar

func _render_germs(render_time: float) -> void:
	# Öz mikrobun proqnozdan gəlir — gecikmə olmadan.
	var mine := _ensure_germ(my_id, Net.nickname, my_color, Net.species)
	mine.apply(me.pos, me.aim, me.balls, me.capacity, me.safe_t > 0.0, true)
	_visuals[my_id]["seen"] = _clock

	var pair := _bracket(render_time)
	if pair.is_empty():
		return
	var older := _index_germs(pair["a"])
	var newer := _index_germs(pair["b"])
	var alpha: float = pair["alpha"]

	for gid in newer:
		if gid == my_id:
			continue
		var n: Array = newer[gid]
		var o: Array = older.get(gid, n)
		# Növ bayraq bitlərindən gəlir — ayrıca sahə göndərilmir (bax [enum Const.GFlag]).
		var kind := Const.species_from(
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)
		var v := _ensure_germ(gid, String(n[Const.GF.NAME]), int(n[Const.GF.COLOR]), kind)

		var pos := Vector2(float(o[Const.GF.X]), float(o[Const.GF.Y])).lerp(
			Vector2(float(n[Const.GF.X]), float(n[Const.GF.Y])), alpha)
		var aim := lerp_angle(float(o[Const.GF.AIM]), float(n[Const.GF.AIM]), alpha)
		v.apply(pos, aim, int(n[Const.GF.BALLS]), int(n[Const.GF.CAP]),
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SAFE) != 0, true)
		_visuals[gid]["seen"] = _clock


func _ensure_germ(gid: int, germ_name: String, color: int,
		species: Const.Species) -> GermVisual:
	var entry: Dictionary = _visuals.get(gid, {})
	if not entry.is_empty():
		return entry["node"]
	var v := GermVisual.new()
	v.setup(color, germ_name, gid == my_id, species)
	# "Blunk" atəş anında yox, topun membranı YARDIĞI anda çalınır. Gecikmə
	# mikrobun ölçüsündən asılıdır, ona görə vaxtı görüntü node-u özü bilir.
	v.broke_through.connect(_on_broke_through)
	_entities.add_child(v)
	_visuals[gid] = {"node": v, "seen": _clock}
	return v


## Top gövdəni tərk etdi. Öz mikrobun tam səslə, başqaları sönük eşidilir —
## eyni qayda [method _flush_fx]-dəki `eject` üçün də keçərlidir.
func _on_broke_through(local: bool) -> void:
	Sfx.play("blunk", 0.05, 0.0 if local else -6.0)


## Rənginə görə mikrobun görüntüsünü tapır. Bir dünyada iki eyni rəngli mikrob
## olmur ([method World._free_color]), ona görə rəng kimlikdir — hadisələrdə
## ayrıca id sahəsi göndərilmir.
## Mikrobun gövdəsini atəş istiqamətində dartır — top içəridən zorlayaraq
## çıxır (bax [method GermVisual.eject]). "Blunk" səsi buradan YOX, gövdə
## pərdəni yaranda siqnalla gəlir.
func _eject_from(color_index: int, angle: float) -> void:
	var v := _germ_by_color(color_index)
	if v != null:
		v.eject(angle)


func _germ_by_color(color_index: int) -> GermVisual:
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.burst and v.color_index == color_index:
			return v
	return null


## Render vaxtını əhatə edən iki snapshot-u tapır.
func _bracket(render_time: float) -> Dictionary:
	if _snaps.is_empty():
		return {}
	for i in range(_snaps.size() - 1):
		var t0: float = _snaps[i]["t"]
		var t1: float = _snaps[i + 1]["t"]
		if t0 <= render_time and render_time <= t1:
			var span := maxf(t1 - t0, 0.0001)
			return {"a": _snaps[i]["d"], "b": _snaps[i + 1]["d"],
				"alpha": clampf((render_time - t0) / span, 0.0, 1.0)}
	# Buferdən kənardayıq (yenicə başladıq və ya paket axını kəsildi) —
	# ən təzə məlum vəziyyəti göstəririk.
	var last: Array = _snaps[-1]["d"]
	return {"a": last, "b": last, "alpha": 1.0}


static func _index_germs(snap: Array) -> Dictionary:
	var out := {}
	for e in snap[Const.Snap.GERMS]:
		out[int(e[Const.GF.ID])] = e
	return out


# ---------------------------------------------------------------- toplar

## Atılan toplar düz xətlə sabit sürətlə gedir, ona görə interpolyasiya
## əvəzinə sonuncu məlum nöqtədən hesablanır — nəticə tamamilə hamardır.
## Sıçrayanda server yeni istiqamət göndərir və hesablama sıfırlanır.
##
## ── Öz topun BAŞQA zaman xəttindədir ─────────────────────────────────────
## Bu faylın başındakı üç zaman xətti burada toqquşur. Rəqiblər 100 ms geridə
## çəkilir, ÖZ mikrobun isə proqnozdan — yəni İNDİ. Top da rəqiblərlə eyni
## gecikməyə salınsaydı (və salınırdı), öz atdığın top mikrobunun 100 ms
## əvvəlki yerində doğulardı: sürəti 420 px/s olduğuna görə bu, 42 piksel,
## yəni mikrobun radiusundan (28 px) BÖYÜK bir məsafədir. Şəbəkə gecikməsi
## də üstünə gəlir.
##
## Nəticə gözlə belə görünürdü: top mikrobun ARXASINDA peyda olur, gövdənin
## içindən keçir və qabaqdan çıxır — sanki kənardan atılıb. Halbuki oyunun
## qaydası budur ki, mikrob ÖZ İÇİNDƏKİ topu atır (bax README, "Oyunun
## qaydası"), və [method Sim._fire] onu düz mərkəzdə doğurur.
##
## Ona görə öz topun serverin sözünü GÖZLƏMİR: atəş açılan andakı doğuş
## nöqtəsindən uçur (bax [method _remember_muzzle]) — pinq nə olursa olsun
## mərkəzdən başlayır və membranı yararaq çıxır. Sıçrayan kimi serverin
## xəttinə qaytarılır: sıçrayışı proqnoz bilmir, onu yalnız server deyir.
##
## Qalan hər şey (rəqib topları, qida) gecikməli xəttdə qalır — onların
## sahibi də oradadır.
##
## Sahib RƏNGDƏN tanınır: bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color]), ona görə snapshot-a sahib sahəsi əlavə
## etməyə ehtiyac yoxdur — eyni üsul [method _explode]-da da işlənir.
func _render_shots(render_time: float) -> void:
	if _last_snap.is_empty():
		return
	for e in _last_snap[Const.Snap.SHOTS]:
		var sid := int(e[Const.SF.ID])
		var view: Dictionary = _shot_views.get(sid, {})
		if view.is_empty():
			var spr := Sprite2D.new()
			spr.texture = _tex["shot"]
			spr.modulate = Palette.germ_color(int(e[Const.SF.COLOR]))
			_shot_layer.add_child(spr)
			var mine := int(e[Const.SF.COLOR]) == my_color
			view = {"node": spr, "mine": mine}
			if mine:
				var muzzle := _claim_muzzle(
					Vector2(float(e[Const.SF.DX]), float(e[Const.SF.DY])))
				if not muzzle.is_empty():
					view["muzzle"] = muzzle
			_shot_views[sid] = view
		view["base"] = Vector2(float(e[Const.SF.X]), float(e[Const.SF.Y]))
		view["dir"] = Vector2(float(e[Const.SF.DX]), float(e[Const.SF.DY]))
		view["t"] = _clock
		view["seen"] = _clock

	for sid in _shot_views:
		var view: Dictionary = _shot_views[sid]
		var spr: Sprite2D = view["node"]
		var dir: Vector2 = view["dir"]

		var muzzle: Dictionary = view.get("muzzle", {})
		if not muzzle.is_empty():
			if Vector2(muzzle["dir"]).dot(dir) > 0.995:
				spr.position = Vector2(muzzle["pos"]) \
					+ dir * Const.SHOT_SPEED * (_clock - float(muzzle["t"]))
				continue
			# İstiqamət dəyişdi — top divardan sıçradı. Proqnozun sözü bitdi.
			view.erase("muzzle")

		var at: float = _clock if view.get("mine", false) else render_time
		spr.position = Vector2(view["base"]) + dir * Const.SHOT_SPEED * (at - float(view["t"]))


## Öz atəşinin doğuş nöqtəsini yadda saxlayır — top serverdən gələnə qədər.
##
## [param membrane] atəş hadisəsindəki nöqtədir: membranın deşildiyi yer,
## yəni mərkəzdən düz bir radius aralıda. [method Sim._fire] həm onu, həm
## topun özünü eyni `g.pos`-dan qurur, ona görə mərkəzi geri hesablamaq olur.
func _remember_muzzle(membrane: Vector2, aim: float) -> void:
	_prune_muzzles()
	var dir := Vector2.from_angle(aim)
	_muzzles.append({
		"pos": membrane - dir * Const.germ_radius(me.capacity),
		"dir": dir,
		"t": _clock,
	})


## Serverin təsdiqləmədiyi köhnə doğuş nöqtələrini atır.
func _prune_muzzles() -> void:
	while not _muzzles.is_empty() and _clock - float(_muzzles[0]["t"]) > MUZZLE_GRACE:
		_muzzles.pop_front()


## Yeni gələn öz topunu gözləyən doğuş nöqtəsi ilə uyğunlaşdırır.
##
## Atəşlər növbə ilə açıldığına görə sıra kifayətdir; istiqamət isə yoxlama
## rolunu oynayır. Server atəşi qəbul etməyibsə (məsələn, düzəlişdən sonra
## soyuma fərqi) nöqtə [constant MUZZLE_GRACE] sonra özü düşür — belə olanda
## bir buraxılmış atəş bütün ardıcıllığı sürüşdürmür.
func _claim_muzzle(dir: Vector2) -> Dictionary:
	while not _muzzles.is_empty():
		var m: Dictionary = _muzzles.pop_front()
		if _clock - float(m["t"]) > MUZZLE_GRACE:
			continue
		if Vector2(m["dir"]).dot(dir) > 0.995:
			return m
	return {}


# ---------------------------------------------------------------- qida

## Qida demək olar hərəkətsizdir (yalnız partlayışdan səpiləndə sürüşür),
## ona görə interpolyasiya lazım deyil — mövqe yumşaq şəkildə çəkilir.
func _render_food(_render_time: float) -> void:
	if _last_snap.is_empty():
		return
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var fid := int(flat[i + Const.FF.ID])
		var target := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE

		var view: Dictionary = _food_views.get(fid, {})
		if view.is_empty():
			var spr := Sprite2D.new()
			spr.texture = _tex["food"]
			# Sprite-ın parlaq haşiyəsi var, ona görə görünən top gerçək
			# radiusdan bir az böyükdür — toqquşma ilə uyğunlaşdırılır.
			spr.scale = Vector2(FOOD_SCALE, FOOD_SCALE)
			spr.position = target
			_food_layer.add_child(spr)
			view = {"node": spr}
			_food_views[fid] = view
		var node: Sprite2D = view["node"]
		node.position = node.position.lerp(target, 0.4)
		view["seen"] = _clock


# ---------------------------------------------------------------- təmizlik

## Görüş sahəsindən çıxan obyektlərin görüntüsü silinir.
## Kiçik möhlət verilir, çünki render 100 ms geridədir.
func _sweep_views() -> void:
	var cutoff := _clock - VIEW_GRACE
	for dict in [_visuals, _food_views, _shot_views]:
		var dead := []
		for key in dict:
			if float(dict[key].get("seen", 0.0)) < cutoff:
				dead.append(key)
		for key in dead:
			(dict[key]["node"] as Node).queue_free()
			dict.erase(key)


# ---------------------------------------------------------------- effektlər

func _queue_events(list: Array, at: float) -> void:
	for e in list:
		var kind := int(e[Const.EF.KIND])
		# Öz hadisələrimi artıq oynatmışam, ikinci dəfə göstərmirəm:
		#   • ATƏŞ    — proqnozda, gecikmə olmadan (bax [method _do_tick]);
		#   • PARTLAMA — serverin "sən partladın" mesajında (bax [method _on_you_burst]).
		# Partlama filtri xüsusilə vacibdir: keçsəydi, öz ölümün İKİ dəfə
		# çəkilər (biri böyük, biri normal ölçüdə) və `you_burst` ilə `burst`
		# səsləri üst-üstə düşərdi.
		if int(e[Const.EF.COLOR]) == my_color \
				and (kind == Const.EvKind.FIRE or kind == Const.EvKind.BURST):
			# Atəşi proqnoz HƏMİŞƏ oynatmır. Məşq rejimində yerli dünyanın
			# tick-i proqnozdan ƏVVƏL işləyir və soyuma sayğacını düzəldir,
			# ona görə proqnoz öz atəşini heç görmür — qığılcım da, səs də,
			# topun doğuş nöqtəsi də itir.
			#
			# Gözləyən doğuş nöqtəsi elə bu sualın cavabıdır: varsa, atəş
			# proqnozda oynadılıb; yoxdursa, yalnız server bilir və burada
			# oynadılmalıdır.
			_prune_muzzles()
			if kind == Const.EvKind.FIRE and _muzzles.is_empty():
				var at_pos := Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y]))
				_remember_muzzle(at_pos, float(e[Const.EF.ARG]))
				_spawn_fx("spark", at_pos, 0.5, Palette.germ_color(my_color))
				Sfx.play("eject", 0.06)
				_eject_from(my_color, float(e[Const.EF.ARG]))
			continue
		_fx_queue.append({
			"at": at,
			"kind": kind,
			"pos": Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y])),
			"arg": float(e[Const.EF.ARG]),
			# Xam indeks də saxlanılır: partlayışda mikrobun görüntüsünü
			# tapmaq üçün lazımdır (bax [method _explode]).
			"ci": int(e[Const.EF.COLOR]),
			"color": Palette.germ_color(int(e[Const.EF.COLOR])),
		})


func _flush_fx(render_time: float) -> void:
	var i := 0
	while i < _fx_queue.size():
		var e: Dictionary = _fx_queue[i]
		if float(e["at"]) > render_time:
			i += 1
			continue
		var pos: Vector2 = e["pos"]
		var col: Color = e["color"]
		match int(e["kind"]):
			Const.EvKind.FIRE:
				_spawn_fx("spark", pos, 0.4, col)
				Sfx.play("eject", 0.06, -6.0)
				_eject_from(int(e["ci"]), float(e["arg"]))
			Const.EvKind.ABSORB:
				_spawn_fx("spark", pos, 0.28, Palette.FOOD)
				# Yalnız ÖZ udmağın eşidilir: 10 mikrobun hamısının səsi
				# eşidilsəydi, arxa fon fasiləsiz xışıltı olardı.
				if col == Palette.germ_color(my_color):
					Sfx.play("absorb", 0.08)
			Const.EvKind.HIT:
				_spawn_fx("spark", pos, 0.55, col)
				Sfx.play("hit", 0.05)
			Const.EvKind.BURST:
				_explode(pos, maxf(float(e["arg"]), 12.0), int(e["ci"]), false)
				Sfx.play("burst", 0.05)
				if pos.distance_to(me.pos) < 500.0:
					_add_shake(10.0)
		_fx_queue.remove_at(i)


## Partlayan mikrobun görüntüsünü partlayışla ƏVƏZ edir.
##
## Mikrobun özünü DƏRHAL susdurmaq şərtdir: server onu artıq göndərmir, amma
## görüntüsü [constant VIEW_GRACE] müddətincə saxlanılır (bax [method _sweep_views]) —
## susdurmasaq partlayışın ortasında sağ-salamat mikrob dayanardı.
##
## Mikrob RƏNGƏ görə tapılır. Bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color] bunu təmin edir), ona görə rəng mikrobun
## kimliyidir və partlama hadisəsinə ayrıca id sahəsi əlavə etmək lazım deyil —
## snapshot-da hər bayt sayılır.
func _explode(pos: Vector2, radius: float, color_index: int, mine: bool) -> void:
	var balls := -1
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if v.burst or v.color_index != color_index:
			continue
		# Son bilinən top sayı səpilən damcıların sayını təyin edir: dolu
		# mikrob partlayanda ekran daha çox dağılır.
		balls = v.balls
		v.kill()
		break

	var fx := BurstFx.new()
	fx.position = pos
	fx.setup(Palette.germ_color(color_index), radius, balls, mine, _tex["burst"])
	_fx.add_child(fx)


func _spawn_fx(kind: String, pos: Vector2, scale: float, color: Color) -> void:
	var spr := Sprite2D.new()
	spr.texture = _tex[kind]
	spr.position = pos
	spr.scale = Vector2(scale, scale)
	spr.modulate = color
	_fx.add_child(spr)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "modulate:a", 0.0, FX_LIFETIME)
	tw.tween_property(spr, "scale", Vector2(scale * 1.7, scale * 1.7), FX_LIFETIME)
	tw.chain().tween_callback(spr.queue_free)


# ---------------------------------------------------------------- fon

## Petri qabı və maneələr. Statikdir — bir dəfə çəkilir və heç vaxt yenilənmir.
func _draw() -> void:
	var r := Const.WORLD_RADIUS

	# Qabın kənarından bayır — oyunçu sərhədi aydın görməlidir.
	draw_circle(Vector2.ZERO, r + 600.0, Palette.BG_OUTER)
	draw_circle(Vector2.ZERO, r, Palette.DISH)

	# Şəbəkə: dairəvi dünyada məsafə hissi verir.
	var step := 200.0
	var lines := PackedVector2Array()
	var n := int(r / step)
	for i in range(-n, n + 1):
		var x := float(i) * step
		var h := sqrt(maxf(r * r - x * x, 0.0))
		lines.push_back(Vector2(x, -h))
		lines.push_back(Vector2(x, h))
		lines.push_back(Vector2(-h, x))
		lines.push_back(Vector2(h, x))
	draw_multiline(lines, Color(Palette.GRID, 0.55), 2.0)

	# Halqalar — mərkəzdən nə qədər uzaqdasan.
	for i in 3:
		draw_arc(Vector2.ZERO, r * (0.35 + 0.22 * float(i)), 0.0, TAU, 64,
			Color(Palette.GRID, 0.5), 2.0, true)

	# Şüşə kənar. Maneələr burada YOX, sprite kimi çəkilir —
	# bax [method _spawn_obstacles].
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Palette.DISH_EDGE, 8.0, true)
