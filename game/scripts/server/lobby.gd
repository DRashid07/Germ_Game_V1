class_name Lobby
extends Node
## Serverin beyni: dünyaları saxlayır, oyunçuları yerləşdirir və hamısını addımlayır.
##
## Matçmeykinq növbəsi YOXDUR — io tipli oyunda oyunçu düyməni basan kimi
## açıq dünyaya girir. Lobby yalnız hansı dünyada yer olduğuna baxır;
## hamısı dolubsa yenisini açır.
##
## Dünyalar node ağacında deyil — sadə obyektlərdir, ona görə ucuzdur.

## Uzun donmadan sonra "ölüm spiralı"na düşməmək üçün bir kadrda maksimum tick sayı.
const MAX_CATCHUP_TICKS := 5

## Bağlantısı kəsilən oyunçunun mikrobu bu qədər saniyə dünyada saxlanılır.
## Mobil şəbəkədə tunel, lift, şəbəkə dəyişimi adi haldır — oyunçu mikrobunu
## itirməməlidir. Çox uzun da olmamalıdır: mikrob bu müddətdə tərpənmir,
## amma vurula bilir.
const REJOIN_GRACE := 20.0

var worlds := {}                ## world_id -> World
var peer_world := {}            ## peer_id -> world_id
var names := {}                 ## peer_id -> ad

var _next_world_id := 1
var _accum := 0.0
var _clock := 0.0

## nişan -> {"world": dünya id, "peer": köhnə peer id, "left_at": vaxt}
var _orphans := {}

## Hər dünyaya son göndərilmiş reyestrin versiyası (bax [member World.roster_rev]).
var _roster_sent := {}

## `--verbose` ilə açılır: hər 5 saniyədən bir dünyaların vəziyyətini yazır.
var verbose := false
var _inputs_seen := 0
var _report_accum := 0.0

## Tick-in öz qiyməti — status sətri üçün (bax [method _report]).
##
## Pulsuz serverdə CPU payı kiçikdir: tick büdcəni aşanda
## [constant MAX_CATCHUP_TICKS] geridə qalan tick-ləri SƏSSİZ atırdı — oyun
## yavaşıyırdı, logda isə heç nə görünmürdü. `Time.get_ticks_usec` ucuzdur.
var _tick_us := 0
var _tick_max_us := 0
var _tick_count := 0
var _dropped_ticks := 0


func _ready() -> void:
	Net.lobby = self
	print("[lobby] hazırdır — dünya tutumu %d, minimum əhali %d" % [
		Const.WORLD_CAPACITY, Const.MIN_POPULATION])


func _process(delta: float) -> void:
	_clock += delta
	_accum += delta
	var steps := 0
	while _accum >= Const.TICK_DELTA and steps < MAX_CATCHUP_TICKS:
		_accum -= Const.TICK_DELTA
		steps += 1
		var t0 := Time.get_ticks_usec()
		_tick_worlds(Const.TICK_DELTA)
		var cost := Time.get_ticks_usec() - t0
		_tick_us += cost
		_tick_max_us = maxi(_tick_max_us, cost)
		_tick_count += 1
	if steps == MAX_CATCHUP_TICKS:
		# Silinən borc sayılır ki, status sətrində görünsün.
		_dropped_ticks += int(_accum / Const.TICK_DELTA)
		_accum = 0.0     # geri qalmışıq, borcu silirik

	# Status sətri tick-dən KƏNARDA yazılır — onun öz qiyməti (bütün mikrobların
	# siyahısı) tick ölçüsünə düşməsin.
	if verbose and _report_accum >= 5.0:
		_report_accum = 0.0
		_report()


# ---------------------------------------------------------------- giriş/çıxış

func join(peer: int, player_name: String, species := 0, mode := 0) -> void:
	if peer_world.has(peer):
		return                      # artıq dünyadadır
	names[peer] = _sanitize(player_name)

	# Rejim də client-dən gəlir, yəni ETİBARSIZ ola bilər — növ kimi çərçivəyə salınır.
	var world := _open_world(Const.mode_from(mode))
	# Növ client-dən gəlir, yəni ETİBARSIZ ola bilər (bax [method Const.species_from]).
	world.add_player(peer, names[peer], Const.species_from(species))
	peer_world[peer] = world.id
	Net.on_world_join.rpc_id(peer, world.join_info_for(peer))
	print("[lobby] %s dünya #%d-ə girdi (%d insan)" % [
		names[peer], world.id, world.human_count()])


## Həmin REJİMDƏ yeri olan ilk dünyanı qaytarır; yoxdursa yenisini açır.
##
## Matçlı rejimdə "yer var" şərti ikiqatdır: dünyada boş yuva olmalıdır VƏ
## matç hələ başlamamalıdır. Yarımçıq matça düşmək pisdir — gec gələn
## oyunçu yeni dünyaya düşür və orada sıfırdan başlayır.
func _open_world(mode: Const.Mode) -> World:
	for wid in worlds:
		var w: World = worlds[wid]
		if w.mode != mode:
			continue
		if not w.has_room():
			continue
		if mode != Const.Mode.ENDLESS and w.phase != Const.Phase.WAITING \
				and w.phase != Const.Phase.COUNTDOWN:
			continue
		return w
	var world := World.new(_next_world_id, mode)
	_next_world_id += 1
	worlds[world.id] = world
	print("[lobby] dünya #%d açıldı (%s)" % [world.id, Const.mode_name(mode)])
	return world


## Oyunçu könüllü çıxır və ya mikrobu partlayır.
func leave(peer: int) -> void:
	var world := _world_of(peer)
	peer_world.erase(peer)
	names.erase(peer)
	if world == null:
		return
	world.drop_peer(peer)
	_close_if_empty(world)


func _world_of(peer: int) -> World:
	var wid: int = peer_world.get(peer, 0)
	return worlds.get(wid)


func _close_if_empty(world: World) -> void:
	if not world.is_empty():
		return
	# İnsansız dünyanı işlətməyin mənası yoxdur — botlar boş yerə CPU yeyər.
	worlds.erase(world.id)
	print("[lobby] dünya #%d boşaldı, bağlandı" % world.id)


# ---------------------------------------------------------------- axın

func route_input(peer: int, packed: Array) -> void:
	var world := _world_of(peer)
	if world != null:
		world.accept_input(peer, packed)
		_inputs_seen += 1


func _tick_worlds(dt: float) -> void:
	_expire_orphans()

	var empty: Array[int] = []
	for wid in worlds:
		var world: World = worlds[wid]
		# Matç bitib nəticə göstərilibsə, dünya bağlanır. Oyunçular onsuz da
		# nəticə ekranındadır və menyuya qayıdırlar.
		if world.phase == Const.Phase.OVER and world.phase_t >= Const.RESULT_TIME:
			empty.append(wid)
			continue
		var bursts := world.tick(dt)

		# Partlayanlar əvvəlcə emal olunur: onlara nəticə gedir və dünyadan çıxırlar.
		for entry in bursts:
			_on_player_burst(world, entry)

		# Matç bitdi — sağ qalanlara da nəticə gedir.
		#
		# Ayrı yoldur, çünki qalib PARTLAMIR: nişanı ölmür, "partladı" logu
		# yazılmır, dünyadan çıxarılmır. Yalnız ekranını görür.
		if not world.pending_results.is_empty():
			for res in world.pending_results:
				_on_match_end(world, res)
			world.pending_results.clear()

		# Reyestr yalnız DƏYİŞƏNDƏ gedir — hər tick yox.
		#
		# Ad və rəng mikrobun ömrü boyu sabitdir; onları snapshot-da daşımaq
		# saniyədə 30 dəfə eyni baytları göndərmək demək idi və paketi MTU-dan
		# yuxarı qaldıran səbəblərdən biri məhz bu idi.
		var send_roster: bool = world.roster_rev != _roster_sent.get(wid, -1)
		var table := world.roster() if send_roster else {}
		if send_roster:
			_roster_sent[wid] = world.roster_rev

		for peer in world.peers:
			# Bağlantısı kəsilmiş oyunçuya snapshot göndərmək mənasızdır.
			if world.is_suspended(peer):
				continue
			if send_roster:
				Net.on_roster.rpc_id(peer, table)
			Net.on_snapshot.rpc_id(peer, world.snapshot_for(peer))

		if world.is_empty():
			empty.append(wid)

	for wid in empty:
		worlds.erase(wid)
		print("[lobby] dünya #%d boşaldı, bağlandı" % wid)

	if verbose:
		_report_accum += dt


## Matç bitdi və oyunçu SAĞ QALDI — nəticə göndərilir.
##
## Partlama yolundan (bax [method _on_player_burst]) iki fərqi var: nişan
## silinmir (silinəcək bir mikrob yoxdur) və log "udu" yazır.
func _on_match_end(world: World, res: Dictionary) -> void:
	var peer := int(res["id"])
	if world.is_suspended(peer):
		return
	var result := {
		"pops": int(res["pops"]),
		"cap": int(res["cap"]),
		"level": Const.level_of(int(res["cap"])),
		"age": float(res["age"]),
		"killer": "",
		"won": bool(res["won"]),
		"survived": true,
		"timed_out": bool(res["timed_out"]),
	}
	Net.on_burst.rpc_id(peer, result)
	print("[lobby] %s matçı bitirdi (dünya #%d) — %s, %d partlatma, %.0f s" % [
		names.get(peer, peer), world.id,
		"QALİB" if result["won"] else "sağ qaldı", result["pops"], result["age"]])


## Oyunçunun mikrobu partladı — oyunu bitir, nəticə göndərilir və menyuya qayıdır.
func _on_player_burst(world: World, entry: Dictionary) -> void:
	var peer := int(entry["id"])
	var suspended := world.is_suspended(peer)
	var result := {
		"pops": int(entry["pops"]),
		"cap": int(entry["cap"]),
		"level": Const.level_of(int(entry["cap"])),
		"age": float(entry["age"]),
		"killer": str(entry["killer_name"]),
	}
	if not suspended:
		Net.on_burst.rpc_id(peer, result)

	print("[lobby] %s partladı (dünya #%d) — %d partlatma, tutum %d, %.0f s" % [
		names.get(peer, peer), world.id, result["pops"], result["cap"], result["age"]])

	# Nişan da ölür: partlamış mikroba qayıtmaq olmaz.
	var token := world.token_of(peer)
	if not token.is_empty():
		_orphans.erase(token)

	world.drop_peer(peer)
	peer_world.erase(peer)
	names.erase(peer)


func _report() -> void:
	# Tick büdcəsi 1000/TICK_RATE ms-dir; "atılan" sıfırdan böyükdürsə server
	# real vaxtdan geri qalıb və oyun yavaşıyıb.
	var avg_ms := float(_tick_us) / float(maxi(_tick_count, 1)) / 1000.0
	print("[lobby] %d dünya · son 5 s-də %d giriş paketi · tick orta %.2f ms, maks %.2f ms · atılan tick %d" % [
		worlds.size(), _inputs_seen, avg_ms, _tick_max_us / 1000.0, _dropped_ticks])
	_inputs_seen = 0
	_tick_us = 0
	_tick_max_us = 0
	_tick_count = 0
	_dropped_ticks = 0
	for wid in worlds:
		var world: World = worlds[wid]
		var parts := PackedStringArray()
		for gid in world.sim.germs:
			var g: Sim.GermState = world.sim.germs[gid]
			parts.append("%s%s(%d/%d @%d,%d)" % [
				g.name, "*" if g.is_bot else "", g.balls, g.capacity,
				int(g.pos.x), int(g.pos.y)])
		print("   #%d insan %d · mikrob %d · qida %d · top %d · %s" % [
			wid, world.human_count(), world.sim.germs.size(),
			world.sim.food.size(), world.sim.shots.size(), " ".join(parts)])


# ---------------------------------------------------------------- bağlantı

## Bağlantı kəsiləndə çağırılır ([Net] tərəfindən).
##
## Oyunçu dərhal atılmır — mikrobu [constant REJOIN_GRACE] saniyə dünyada
## saxlanılır ki, qayıda bilsin.
func remove_peer(peer: int) -> void:
	var world := _world_of(peer)
	if world == null:
		names.erase(peer)
		return

	var token := world.token_of(peer)
	if token.is_empty():
		leave(peer)
		return

	world.suspend_peer(peer)
	peer_world.erase(peer)
	_orphans[token] = {"world": world.id, "peer": peer, "left_at": _clock}
	print("[lobby] %s bağlantını itirdi — mikrobu %.0f s saxlanılır (dünya #%d)" % [
		names.get(peer, peer), REJOIN_GRACE, world.id])


## Oyunçu nişanı ilə mikrobuna qayıdır.
func rejoin(peer: int, token: String) -> void:
	var orphan: Dictionary = _orphans.get(token, {})
	if orphan.is_empty():
		Net.on_rejoin_failed.rpc_id(peer)
		return

	var world: World = worlds.get(int(orphan["world"]))
	if world == null:
		_orphans.erase(token)
		Net.on_rejoin_failed.rpc_id(peer)
		return

	var old_peer := int(orphan["peer"])
	if not world.sim.germs.has(old_peer):
		# Gözləmə müddətində partladı.
		_orphans.erase(token)
		Net.on_rejoin_failed.rpc_id(peer)
		return

	_orphans.erase(token)
	world.resume_peer(old_peer, peer)
	peer_world.erase(old_peer)
	peer_world[peer] = world.id
	names[peer] = names.get(old_peer, "Mikrob")
	names.erase(old_peer)

	Net.on_world_join.rpc_id(peer, world.join_info_for(peer))
	print("[lobby] %s dünya #%d-ə qayıtdı" % [names[peer], world.id])


## Vaxtı bitən gözləmələr: oyunçu qayıtmadı, mikrobu dünyadan silinir.
func _expire_orphans() -> void:
	var dead: Array = []
	for token in _orphans:
		if _clock - float(_orphans[token]["left_at"]) < REJOIN_GRACE:
			continue
		dead.append(token)

	for token in dead:
		var orphan: Dictionary = _orphans[token]
		_orphans.erase(token)
		var world: World = worlds.get(int(orphan["world"]))
		if world == null:
			continue
		var peer := int(orphan["peer"])
		print("[lobby] %s qayıtmadı — mikrobu dünya #%d-dən silindi" % [
			names.get(peer, peer), world.id])
		names.erase(peer)
		world.drop_peer(peer)
		_close_if_empty(world)


static func _sanitize(raw: String) -> String:
	var s := raw.strip_edges()
	if s.is_empty():
		return "Mikrob"
	return s.substr(0, 16)
