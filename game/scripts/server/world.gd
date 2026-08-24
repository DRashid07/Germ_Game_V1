class_name World
extends RefCounted
## Bir petri qabı — sonsuz işləyən dünya.
##
## Serverdə yaşayır, öz [Sim] nüsxəsini 30 Hz ilə addımlayır və hər tick-də
## iştirakçılara snapshot göndərir. Matç yoxdur: oyunçular istənilən anda
## girir, mikrobları partlayanda çıxırlar.
##
## Bir server prosesi onlarla belə dünyanı paralel aparır — hər dünya
## tamamilə müstəqildir, node ağacına toxunmur.
##
## Bot idarəsi də buradadır: dünya heç vaxt boş qalmır, çatmayan yer
## [Bot] mikroblarla doldurulur.

## Bot id-ləri peer id-lərindən uzaqda saxlanılır ki, heç vaxt toqquşmasınlar.
const BOT_ID_BASE := 1_000_000
## Bot partlayandan sonra yerinə yenisi bu qədər saniyəyə gəlir.
const BOT_RESPAWN := 2.0

var id: int
var sim: Sim
var peers: Array[int] = []      ## Bu dünyadakı insan oyunçular

## peer_id -> sessiya nişanı. Bağlantı kəsiləndə oyunçu bu nişanla geri qayıdır:
## yeni peer id alır, amma nişan onu köhnə mikrobu ilə birləşdirir.
var tokens := {}
## Bağlantısı kəsilmiş, amma mikrobu hələ dünyada qalan oyunçular. peer_id -> true
var suspended := {}

var _inputs := {}               ## germ_id -> Sim.PlayerInput (ən son gələn)
var _last_seq := {}             ## peer_id -> emal edilmiş son seq
var _bots := {}                 ## bot_id -> Bot
var _next_bot_id := BOT_ID_BASE
var _bot_timer := 0.0
var _seeded := false
var _bot_name_no := 0

## Bu tick üçün hazırlanmış sətirlər — hər peer üçün yenidən qurulmasın deyə
## bir dəfə yığılır, sonra görüş sahəsinə görə süzülür.
var _frame_germs: Array = []    ## [Vector2 pos, Array row]
var _frame_shots: Array = []
var _frame_food: Array = []
var _frame_events: Array = []
var _frame_board: Array = []


func _init(p_id: int) -> void:
	id = p_id
	sim = Sim.new()


# ---------------------------------------------------------------- iştirakçılar

func human_count() -> int:
	return peers.size()


func has_room() -> bool:
	return peers.size() < Const.WORLD_CAPACITY


## Oyunçunu dünyaya salır və mikrobunu doğurur.
func add_player(peer: int, player_name: String) -> Sim.GermState:
	# İnsan gələndə bot yerini ona verir — dünya heç vaxt hədddən çox olmur.
	if sim.germs.size() >= Const.WORLD_CAPACITY:
		_remove_one_bot()
	peers.append(peer)
	_last_seq[peer] = 0
	tokens[peer] = _new_token()
	return sim.add_germ(peer, player_name, _free_color())


## Dünyaya girəndə oyunçuya göndərilən məlumat.
func join_info_for(peer: int) -> Dictionary:
	var g: Sim.GermState = sim.germs.get(peer)
	return {
		"world": id,
		"you": peer,
		"color": g.color if g != null else 0,
		"name": g.name if g != null else "",
		"tick_rate": Const.TICK_RATE,
		"token": str(tokens.get(peer, "")),
	}


static func _new_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## Ən kiçik boş rəng yuvası. 10 rəng var, dünyada da maksimum 10 mikrob —
## ona görə rəng həmişə tapılır və heç iki mikrob eyni rəngdə olmur.
func _free_color() -> int:
	var used := {}
	for gid in sim.germs:
		used[sim.germs[gid].color] = true
	for i in Palette.GERM_COLORS.size():
		if not used.has(i):
			return i
	return sim.germs.size() % Palette.GERM_COLORS.size()


# ---------------------------------------------------------------- botlar

func _add_bot() -> void:
	var bid := _next_bot_id
	_next_bot_id += 1
	_bot_name_no += 1
	# Çətinlik təsadüfidir: dünyada həm asan, həm təhlükəli mikroblar olsun.
	var bot := Bot.new(bid, randf_range(0.7, 1.3))
	_bots[bid] = bot
	sim.add_germ(bid, Bot.random_name(_bot_name_no), _free_color(), true)


func _remove_one_bot() -> void:
	for bid in _bots:
		_bots.erase(bid)
		sim.remove_germ(bid)
		_inputs.erase(bid)
		return


## Əhalini [constant Const.MIN_POPULATION] səviyyəsində saxlayır.
##
## İlk doldurma DƏRHAL olur: oyunçu düyməni basandan sonra boş qaba düşməməlidir.
## Sonrakı itkilər isə gecikmə ilə əvəzlənir — mikroblar bir anda "peyda olmur".
func _keep_population(dt: float) -> void:
	var target: int = mini(Const.MIN_POPULATION, Const.WORLD_CAPACITY)
	if not _seeded:
		_seeded = true
		while sim.germs.size() < target:
			_add_bot()
		return
	if sim.germs.size() >= target:
		return
	_bot_timer -= dt
	if _bot_timer > 0.0:
		return
	_bot_timer = BOT_RESPAWN
	_add_bot()


# ---------------------------------------------------------------- axın

## Client-dən gələn giriş paketi.
func accept_input(peer: int, packed: Array) -> void:
	if not sim.germs.has(peer):
		return
	if packed.size() < 5:
		return
	var inp := Sim.PlayerInput.from_array(packed)
	# Köhnəlmiş paketi atırıq — UDP-də sıra pozula bilər.
	if inp.seq <= int(_last_seq.get(peer, 0)):
		return
	_inputs[peer] = inp


## Bir tick. Partlayan oyunçuların siyahısını qaytarır — [Lobby] onlara
## nəticə göndərib dünyadan çıxarır.
func tick(dt: float) -> Array:
	_keep_population(dt)

	for bid in _bots:
		var bot: Bot = _bots[bid]
		_inputs[bid] = bot.think(sim, dt)

	sim.step(_inputs, dt)

	# Atəş bir dəfəlik hadisədir. Paket itsə, saxlanan giriş təkrar oxunar və
	# oyunçu istəmədən yenidən atəş açar — ona görə emaldan sonra sıfırlayırıq.
	for gid in _inputs:
		var inp: Sim.PlayerInput = _inputs[gid]
		if sim.germs.has(gid):
			_last_seq[gid] = inp.seq
		inp.fire = false

	var out := []
	for entry in sim.burst_log:
		var gid := int(entry["id"])
		_inputs.erase(gid)
		if _bots.has(gid):
			_bots.erase(gid)
			continue
		out.append(entry)

	_build_frame()
	return out


# ---------------------------------------------------------------- snapshot

## Şəbəkəyə gedən kompakt state. Dictionary yox, Array — 30 Hz-də hər bayt sayılır.
##
## Sətirlər bir dəfə qurulur, sonra hər oyunçu üçün YALNIZ görüş sahəsindəkilər
## süzülür. Dünya ekrandan böyükdür: hər kəsə hər şeyi göndərmək həm trafik
## israfıdır, həm də "divar arxasını görmək" kimi bir üstünlük verərdi.
func _build_frame() -> void:
	_frame_germs.clear()
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		_frame_germs.append([g.pos, [
			g.id, g.name, g.color,
			g.pos.x, g.pos.y,
			g.vel.x, g.vel.y,
			g.aim, g.balls, g.capacity,
			1 if g.safe_t > 0.0 else 0,
			int(_last_seq.get(g.id, 0)),
			g.cooldown,
		]])

	_frame_shots.clear()
	for s in sim.shots:
		_frame_shots.append([s.pos, [s.id, s.color, s.pos.x, s.pos.y, s.dir.x, s.dir.y]])

	# Qida düz ədəd axını kimi paketlənir (bax [constant Const.FOOD_STRIDE]).
	_frame_food.clear()
	for f in sim.food:
		_frame_food.append([f.pos, f.id])

	# Hadisələr (top atma, udma, partlama) yalnız bu tick üçün gedir.
	# Sıra [enum Const.EF] ilə eynidir: KIND, X, Y, ARG, COLOR.
	_frame_events.clear()
	for e in sim.events:
		var kind := Const.EvKind.FIRE
		match e.get("t"):
			"fire": kind = Const.EvKind.FIRE
			"absorb": kind = Const.EvKind.ABSORB
			"hit": kind = Const.EvKind.HIT
			"burst": kind = Const.EvKind.BURST
		var pos: Vector2 = e["pos"]
		_frame_events.append([pos, [kind, pos.x, pos.y, float(e["arg"]), int(e["color"])]])

	_frame_board = sim.leaderboard(5)


func snapshot_for(peer: int) -> Array:
	var g: Sim.GermState = sim.germs.get(peer)
	var eye: Vector2 = g.pos if g != null else Vector2.ZERO
	# Böyük mikrob daha geniş görür, ona görə sahə tutumla birlikdə böyüyür —
	# əks halda ekranın kənarında obyektlər kəsilərdi.
	var cap: int = g.capacity if g != null else Const.START_CAPACITY
	var r2 := pow(Const.aoi_radius(cap), 2.0)

	return [
		sim.tick,
		_near(_frame_germs, eye, r2),
		_near(_frame_shots, eye, r2),
		_near_food(_frame_food, eye, r2),
		_near(_frame_events, eye, r2),
		_frame_board,
		sim.germs.size(),
	]


## Görüş sahəsindəki sətirləri süzür.
static func _near(rows: Array, eye: Vector2, r2: float) -> Array:
	var out := []
	for row in rows:
		if eye.distance_squared_to(row[0]) <= r2:
			out.append(row[1])
	return out


## Qida üçün ayrıca süzgəc: nəticə sıx ədəd axınıdır (id, x, y, id, x, y ...).
static func _near_food(rows: Array, eye: Vector2, r2: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for row in rows:
		var p: Vector2 = row[0]
		if eye.distance_squared_to(p) > r2:
			continue
		out.push_back(float(row[1]))
		out.push_back(p.x)
		out.push_back(p.y)
	return out


# ---------------------------------------------------------------- bağlantı

func token_of(peer: int) -> String:
	return str(tokens.get(peer, ""))


## Bağlantı kəsildi, amma mikrob dünyada qalır.
##
## Mikrob hərəkət etmir və atəş açmır, amma vurula bilir və metabolizmi
## işləyir. Bu qəsdəndir: bağlantını kəsmək qorunma üsuluna çevrilməməlidir.
func suspend_peer(peer: int) -> void:
	if not sim.germs.has(peer):
		return
	suspended[peer] = true
	# Saxlanan giriş silinir, yoxsa mikrob son əmrlə hərəkət etməyə davam edərdi.
	_inputs.erase(peer)


## Oyunçu yeni peer id ilə geri qayıtdı — bütün açarları köçürürük.
func resume_peer(old_peer: int, new_peer: int) -> void:
	if old_peer == new_peer:
		suspended.erase(old_peer)
		return

	sim.rekey_germ(old_peer, new_peer)

	var idx := peers.find(old_peer)
	if idx >= 0:
		peers[idx] = new_peer

	for src in [tokens, _last_seq]:
		if src.has(old_peer):
			src[new_peer] = src[old_peer]
			src.erase(old_peer)

	_inputs.erase(old_peer)
	suspended.erase(old_peer)
	# Nişan dəyişmir: eyni oyunçu, eyni sessiya.


func is_suspended(peer: int) -> bool:
	return suspended.has(peer)


## Oyunçu dünyanı tərk edir (partladı, çıxdı və ya qayıtmadı).
func drop_peer(peer: int) -> void:
	peers.erase(peer)
	_inputs.erase(peer)
	_last_seq.erase(peer)
	tokens.erase(peer)
	suspended.erase(peer)
	sim.remove_germ(peer)


func is_empty() -> bool:
	return peers.is_empty()
