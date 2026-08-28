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
## Bu dünyanın rejimi. Dünya boyu dəyişmir — bir dünyada hamı eyni qaydada
## oynayır (bax `design/MODES.md`).
var mode := Const.Mode.ENDLESS
## Matçın fazası. SONSUZ ARENA həmişə PLAYING-dədir və oradan çıxmır.
var phase := Const.Phase.PLAYING
## Hazırkı fazanın öz saatı (saniyə). Faza dəyişəndə sıfırlanır.
var phase_t := 0.0
## Matçın başlanğıcından keçən vaxt — qabın qurumasını bu idarə edir.
var match_t := 0.0
## Partlayan oyunçuların yeri: peer -> yer (1 = qalib).
var places := {}

## Matç bitəndə sağ qalan İNSANLARIN nəticələri. [Lobby] bir dəfə boşaldır.
##
## Ölənlərin nəticəsi `tick`-in qaytardığı siyahı ilə gedir, sağ qalanlarınkı
## isə heç bir hadisəyə bağlı deyil — matçın bitməsi onların tərəfindən
## baxanda heç nə "baş vermir". Ona görə ayrıca növbə lazımdır.
var pending_results: Array = []

## Matç VAXT LİMİTİ ilə bitdi (yəni sonuncu mikrob qalmadı).
##
## Nəticə ekranı üçün lazımdır: vaxt limitində bir neçə mikrob sağ qalır, yəni
## qalibə "sonuncu mikrob sənsən" yazmaq YALAN olardı.
var timed_out := false

var _frame_germs: Array = []    ## [Vector2 pos, Array row]
var _frame_shots: Array = []
var _frame_food: Array = []
var _frame_events: Array = []
var _frame_board := PackedInt32Array()


func _init(p_id: int, p_mode := Const.Mode.ENDLESS) -> void:
	id = p_id
	mode = p_mode
	sim = Sim.new()
	# Matçlı rejim oyunçu gözləyir; sonsuz arena isə həmişə açıqdır.
	phase = Const.Phase.PLAYING if mode == Const.Mode.ENDLESS else Const.Phase.WAITING


# ---------------------------------------------------------------- iştirakçılar

func human_count() -> int:
	return peers.size()


func has_room() -> bool:
	return peers.size() < Const.WORLD_CAPACITY


## Oyunçunu dünyaya salır və mikrobunu doğurur.
func add_player(peer: int, player_name: String,
		species := Const.Species.CILIATE) -> Sim.GermState:
	# İnsan gələndə bot yerini ona verir — dünya heç vaxt hədddən çox olmur.
	if sim.germs.size() >= Const.WORLD_CAPACITY:
		_remove_one_bot()
	peers.append(peer)
	_last_seq[peer] = 0
	tokens[peer] = _new_token()
	return sim.add_germ(peer, player_name, _free_color(), false, species)


## Dünyaya girəndə oyunçuya göndərilən məlumat.
func join_info_for(peer: int) -> Dictionary:
	var g: Sim.GermState = sim.germs.get(peer)
	return {
		"world": id,
		"you": peer,
		"color": g.color if g != null else 0,
		# Növ serverdən geri qaytarılır: yenidən qoşulanda oyunçu köhnə mikrobuna
		# qayıdır və onun növü serverdəki qeyddir, menyudakı seçim deyil.
		"species": int(g.species) if g != null else int(Const.Species.CILIATE),
		"name": g.name if g != null else "",
		"mode": int(mode),
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


# ---------------------------------------------------------------- matç

## Fazanı irəli aparır.
##
## SONSUZ ARENA bu funksiyadan DƏRHAL çıxır: onun fazası həmişə PLAYING-dir.
## Belə olanda köhnə rejim yeni sistemin altında toxunulmaz qalır — kod bir
## yoldan gedir, amma davranış iki cürdür.
func _step_phase(dt: float) -> void:
	if mode == Const.Mode.ENDLESS:
		return

	phase_t += dt
	match phase:
		Const.Phase.WAITING:
			# İnsan gələn kimi matç qurulur. NÖVBƏ YOXDUR: boş yerləri botlar
			# tutur, çünki oyunçu bazası kiçikdir və növbə "boş oyun" hissi verir.
			if human_count() > 0:
				_set_phase(Const.Phase.COUNTDOWN)
		Const.Phase.COUNTDOWN:
			if phase_t >= Const.COUNTDOWN_TIME:
				_set_phase(Const.Phase.PLAYING)
		Const.Phase.PLAYING:
			match_t += dt
			# Bitmə şərti burada YOX, addımdan SONRA yoxlanılır: sonuncu mikrob
			# məhz `sim.step` içində partlayır və matç o anda bitməlidir,
			# növbəti tick-də yox. Bir tick gecikmə oyunçuya ölü dünyada bir
			# kadr göstərərdi.
		Const.Phase.OVER:
			pass    # Lobby bağlayır (bax [method Lobby._tick_worlds])


func _set_phase(next: Const.Phase) -> void:
	phase = next
	phase_t = 0.0
	if next == Const.Phase.OVER:
		_award_survivors()


## Sağ qalanlara yer verir və insanların nəticəsini hazırlayır.
##
## [member places] yalnız PARTLAYANLAR üçün doldurulur (bax [method tick]) —
## qalib isə tərifinə görə partlamır. Bu funksiya olmasaydı, matçı UDAN oyunçu
## nəticə ekranında yerini "0" görərdi: sıralamanın yeganə boşluğu budur.
##
## Vaxt həddi ilə bitən matçda bir neçə mikrob sağ qala bilər. Onlar liderlər
## cədvəli ilə EYNİ meyara görə sıralanır: partlatma sayı, bərabərlikdə tutum
## (bax [method Sim.leaderboard]).
##
## Əvvəl top sayına görə sıralanırdı və bu, ekranla ziddiyyət yaradırdı:
## oyunçu bütün matç boyu cədvəlin birincisi ola, sonda isə dördüncü çıxa
## bilərdi. Üstəlik çox top saxlamaq bacarıq deyil — partlamağa yaxın olmaqdır.
func _award_survivors() -> void:
	var ids := sim.germs.keys()
	ids.sort_custom(func(a, b) -> bool:
		var ga: Sim.GermState = sim.germs[a]
		var gb: Sim.GermState = sim.germs[b]
		if ga.pops != gb.pops:
			return ga.pops > gb.pops
		return ga.capacity > gb.capacity)

	var place := 1
	for gid in ids:
		places[gid] = place
		if not _bots.has(gid):
			var g: Sim.GermState = sim.germs[gid]
			# Ölüm nəticəsi ilə EYNİ formadır ki, client tək yolla işləsin —
			# fərq yalnız `won` bayrağındadır.
			pending_results.append({
				"id": gid,
				"killer_name": "",
				"pops": g.pops,
				"cap": g.capacity,
				"age": g.age,
				"won": place == 1,
				# `survived` OLMASAYDI, client sağ oyunçunu partlamış sayardı:
				# partladan adı boşdur, boş ad isə "acından partladın" deməkdir.
				"survived": true,
				"timed_out": timed_out,
			})
		place += 1


## Matç bitdimi?
##
## TƏK QALAN: bir mikrob qalanda. Vaxt həddi keçilsə də bitir — o vaxta qədər
## qab onsuz da tam qurumuş olur, yəni matç uzana bilməz.
func _match_over() -> bool:
	# Sıra VACİBDİR: hər iki şərt eyni tick-də ödənə bilər və o halda matç
	# "sonuncu qaldı" ilə bitməlidir, "vaxt bitdi" ilə yox — nəticə ekranındakı
	# cümlə bundan asılıdır.
	if sim.germs.size() <= 1:
		return true
	if match_t >= Const.MATCH_MAX:
		timed_out = true
		return true
	return false


## Giriş qəbul edilirmi? Geriyə sayımda mikroblar görünür, amma tərpənmir —
## oyunçu kimlə oynadığını görür və hamı eyni anda başlayır.
func inputs_open() -> bool:
	return phase == Const.Phase.PLAYING


## Snapshot-un matç sahəsi (bax [enum Const.MF]).
func _match_row(peer: int) -> Array:
	return [
		int(mode),
		int(phase),
		phase_t,
		sim.dish_radius,
		sim.germs.size(),
		int(places.get(peer, 0)),
	]


# ---------------------------------------------------------------- botlar

func _add_bot() -> void:
	var bid := _next_bot_id
	_next_bot_id += 1
	_bot_name_no += 1
	# Çətinlik təsadüfidir: dünyada həm asan, həm təhlükəli mikroblar olsun.
	var bot := Bot.new(bid, randf_range(0.7, 1.3))
	_bots[bid] = bot
	# Botların növü təsadüfidir ki, dünyada hər üç növ görünsün.
	var species := Const.species_from(randi() % Const.SPECIES_COUNT)
	sim.add_germ(bid, Bot.random_name(_bot_name_no), _free_color(), true, species)


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
	# Matçlı rejimdə ölən ÖLÜR — əhali bərpa olunmur, yoxsa "sona qalan udur"
	# qaydası mənasız olur. Doldurma yalnız matç başlamazdan əvvəl işləyir.
	if mode != Const.Mode.ENDLESS:
		if phase != Const.Phase.WAITING and phase != Const.Phase.COUNTDOWN:
			return
		while sim.germs.size() < Const.WORLD_CAPACITY:
			_add_bot()
		return

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
	# Geriyə sayımda giriş qəbul edilmir: mikroblar görünür, amma tərpənmir.
	# Client də eyni qaydanı tətbiq edir, yoxsa proqnoz serverdən qabağa düşür
	# və sayım bitəndə mikrob geri sıçrayır.
	if not inputs_open():
		return
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
	_step_phase(dt)
	# Qabın kənarı YALNIZ rejimdən və matç saatından çıxır — prediction şərti
	# (bax [method Const.dish_radius]).
	sim.dish_radius = Const.dish_radius(int(mode), match_t)
	_keep_population(dt)
	if mode == Const.Mode.SOLO and phase == Const.Phase.PLAYING:
		sim.keep_spores(dt)

	for bid in _bots:
		var bot: Bot = _bots[bid]
		_inputs[bid] = bot.think(sim, dt)

	# Matç bitibsə dünya DONUR.
	#
	# Yoxsa nəticə ekranının arxasında botlar döyüşməyə, partlamağa və yer
	# dəyişməyə davam edir: oyunçu "bitmiş" matçın davam etdiyini görür və
	# server nəticə ekranı boyu boş yerə hesablayır.
	if phase != Const.Phase.OVER:
		sim.step(_inputs, dt)

	# Atəş və super BİR DƏFƏLİK hadisələrdir. Paket itsə, saxlanan giriş təkrar
	# oxunar və oyunçu istəmədən yenidən atəş açar (super isə kirpiklidə üstəlik
	# iki top xərcləyər) — ona görə emaldan sonra ikisi də sıfırlanır.
	for gid in _inputs:
		var inp: Sim.PlayerInput = _inputs[gid]
		if sim.germs.has(gid):
			_last_seq[gid] = inp.seq
		inp.fire = false
		inp.use_super = false

	# YER — matçlı rejimdə partlayan mikrob o anda sağ qalanların sayı + 1
	# yerini alır. Yəni ilk ölən sonuncu, sona qalan birincidir.
	#
	# `sim.burst_log` `_reap`-dən SONRA oxunur, yəni `sim.germs.size()` artıq
	# ölənləri saymır — ona görə düstur sadədir.
	# Sayğac İRƏLİ gedir, geri yox.
	#
	# Geri getsəydi, eyni tick-də üç mikrob partlayanda onlar 6, 5, 4 yerlərini
	# alardı — halbuki 5 və 4 sonra SAĞ QALANLARA veriləcək və iki oyunçu eyni
	# "N-ci YER"-i görərdi. Quruma fazasında bir neçə mikrobun eyni anda dolub
	# partlaması adi haldır.
	var place := sim.germs.size() + 1

	var out := []
	for entry in sim.burst_log:
		var gid := int(entry["id"])
		_inputs.erase(gid)
		if mode != Const.Mode.ENDLESS:
			places[gid] = place
			place += 1
		if _bots.has(gid):
			_bots.erase(gid)
			continue
		out.append(entry)

	if phase == Const.Phase.PLAYING and _match_over():
		_set_phase(Const.Phase.OVER)

	_build_frame()
	return out


# ---------------------------------------------------------------- snapshot

## Şəbəkəyə gedən kompakt state. Dictionary yox, Array — 30 Hz-də hər bayt sayılır.
##
## Sətirlər bir dəfə qurulur, sonra hər oyunçu üçün YALNIZ görüş sahəsindəkilər
## süzülür. Dünya ekrandan böyükdür: hər kəsə hər şeyi göndərmək həm trafik
## israfıdır, həm də "divar arxasını görmək" kimi bir üstünlük verərdi.
## Ad və rəng cədvəli: `{id: [ad, rəng]}`.
##
## Bunlar mikrobun ömrü boyu DƏYİŞMİR, ona görə snapshot-da yeri yoxdur —
## ora yalnız hər kadr dəyişən şeylər gedir (bax [enum Const.GF]). Cədvəl
## etibarlı kanalla, yalnız mikrobların dəsti dəyişəndə göndərilir.
func roster() -> Dictionary:
	var out := {}
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		out[gid] = [g.name, g.color]
	return out


## Mikrobların dəsti dəyişdikcə artır — [Lobby] bununla nə vaxt göndərəcəyini bilir.
var roster_rev := 0
var _roster_key := 0


func _build_frame() -> void:
	# Dəst dəyişibsə reyestr köhnəlib.
	#
	# SAYI müqayisə etmək BƏS ETMİR: [method Sim.rekey_germ] mikrobu silib
	# yenidən əlavə edir, yəni id DƏYİŞİR, say isə qalır. Yenidən qoşulma məhz
	# bunu edir — say yoxlaması ilə qayıdan oyunçu bütün digər ekranlarda
	# adsız və 0 rəngli qalırdı. Eyni tələ: bir tick-də bot doğulub biri
	# partlasa da say dəyişmir.
	#
	# Ona görə id-lərin ÖZÜNDƏN sadə imza yığılır. On mikrob üçün pulsuzdur.
	var key := sim.germs.size()
	for gid in sim.germs:
		key = key * 31 + gid
	if key != _roster_key:
		_roster_key = key
		roster_rev += 1

	_frame_germs.clear()
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		# Üçüncü sahə: hansı kolun içindədir (bax [method _near_germs]).
		_frame_germs.append([g.pos, sim.bush_of(g), g.id,
			g.pos.x, g.pos.y,
			g.vel.x, g.vel.y,
			g.aim, g.balls, g.capacity,
			_flags_of(g)])

	_frame_shots.clear()
	for s in sim.shots:
		_frame_shots.append([s.pos, s.id, s.color, s.pos.x, s.pos.y, s.dir.x, s.dir.y])

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
			"super": kind = Const.EvKind.SUPER
			"spore": kind = Const.EvKind.SPORE
			"hit": kind = Const.EvKind.HIT
			"burst": kind = Const.EvKind.BURST
			"break": kind = Const.EvKind.BREAK
		var pos: Vector2 = e["pos"]
		_frame_events.append([pos, kind, pos.x, pos.y, float(e["arg"]), int(e["color"])])

	# Cədvəldə AD yox, ID gedir: adlar onsuz da reyestrdədir (bax [method roster]).
	# Adları hər tick təkrar göndərmək cəmi beş sətir üçün ~200 bayt yeyirdi.
	_frame_board = PackedInt32Array()
	for row in sim.leaderboard(5):
		_frame_board.push_back(int(row[Const.LF.ID]))
		_frame_board.push_back(int(row[Const.LF.POPS]))


## Mikrobun bayraqları bir ədəddə (bax [enum Const.GFlag]).
static func _flags_of(g: Sim.GermState) -> int:
	var f := (int(g.species) << Const.GFlag.SPECIES_SHIFT) & Const.GFlag.SPECIES_MASK
	if g.safe_t > 0.0:
		f |= Const.GFlag.SAFE
	# Superin doluluğu və işlək olması — ikisi də bayrağın boş bitlərində.
	# Rəqibin superinin hazır olduğu görünür: gərginlik oradan gəlir.
	f |= (g.charge << Const.GFlag.CHARGE_SHIFT) & Const.GFlag.CHARGE_MASK
	if g.super_t > 0.0:
		f |= Const.GFlag.SUPER
	return f


func snapshot_for(peer: int) -> Array:
	var g: Sim.GermState = sim.germs.get(peer)
	var eye: Vector2 = g.pos if g != null else Vector2.ZERO
	# Böyük mikrob daha geniş görür, ona görə sahə tutumla birlikdə böyüyür —
	# əks halda ekranın kənarında obyektlər kəsilərdi.
	var cap: int = g.capacity if g != null else Const.START_CAPACITY
	var r2 := pow(Const.aoi_radius(cap), 2.0)
	# Baxan özü hansı koldadır — gizlənənləri yalnız o görür.
	var eye_bush := sim.bush_of(g) if g != null else -1

	# BÜDCƏ — paket MTU-ya sığmalıdır və sabit hədlər bunu təmin etmir.
	#
	# Hər hədd ayrılıqda məqbul görünür, birlikdə isə aşır: ölçülüb, 10 mikrob
	# + 16 top + 12 hadisə + 32 qida birlikdə 1604 bayt verirdi (hədd 1392).
	# Ona görə qalan sahələr MİKROBLARDAN SONRA qalan yeri bölüşür.
	#
	# Prioritet sırası oyundan çıxır: mikrob (kimə qarşı oynayıram) → top
	# (nədən qaçıram) → hadisə (nə baş verdi) → qida (sonra yeyərəm).
	var germs := _near_germs(_frame_germs, eye, r2, eye_bush, peer)
	var n_germs: int = (germs[0] as PackedInt32Array).size()
	var left: int = maxi(Const.MTU_SAFE - Const.SNAP_FIXED - n_germs * Const.GERM_BYTES, 120)

	var shot_n: int = clampi(left * 40 / 100 / Const.SHOT_BYTES, 4, Const.SHOT_SEND_MAX)
	left -= shot_n * Const.SHOT_BYTES
	var event_n: int = clampi(left * 35 / 100 / Const.EVENT_BYTES, 3, Const.EVENT_SEND_MAX)
	left -= event_n * Const.EVENT_BYTES
	var food_n: int = clampi(left / Const.FOOD_BYTES, 6, Const.FOOD_SEND_MAX)

	return [
		sim.tick,
		germs,
		_near_shots(_frame_shots, eye, r2, shot_n),
		_near_food(_frame_food, eye, r2, food_n),
		_near_flat(_frame_events, eye, r2, event_n),
		_frame_board,
		sim.germs.size(),
		sim.broken,
		_match_row(peer),
		[int(_last_seq.get(peer, 0)), g.cooldown if g != null else 0.0],
	]


## Mikroblar üçün ayrıca süzgəc: məsafədən ƏLAVƏ gizlənmə qaydası var.
##
## Kolun içindəki mikrob yalnız EYNİ kolun içindəkinə görünür. Qayda
## serverdədir və başqa yerdə ola da bilməzdi: client-də olsaydı, gizlənən
## oyunçunun mövqeyi onsuz da şəbəkə ilə gedərdi və paketə baxan hər kəs onu
## görərdi. Gizlənmə YALNIZ göndərilməyəndə həqiqidir.
##
## Öz mikrobun həmişə göndərilir: sən özünü kolda da görməlisən.
## Nəticə İKİ sıx massivdir: id-lər və qalan ədədlər
## (bax [method Const.unpack_germs]).
static func _near_germs(rows: Array, eye: Vector2, r2: float,
		eye_bush: int, peer: int) -> Array:
	var ids := PackedInt32Array()
	var data := PackedFloat32Array()
	for row in rows:
		if eye.distance_squared_to(row[0]) > r2:
			continue
		var bush: int = row[1]
		var gid: int = row[2]
		if bush >= 0 and bush != eye_bush and gid != peer:
			continue
		ids.push_back(gid)
		for i in range(3, row.size()):
			data.push_back(float(row[i]))
	return [ids, data]


## Toplar üçün süzgəc — qida ilə eyni səbəbdən sıx ədəd axınıdır.
##
## Variant massivində hər ədəd ~9 bayt tutur, `PackedFloat32Array`-də isə 4.
## Döyüş qızışanda ekranda 15-ə qədər top olur; köhnə format o anda tək
## başına ~690 bayt yeyirdi və snapshot MTU-nu aşırdı.
static func _near_shots(rows: Array, eye: Vector2, r2: float, limit: int) -> PackedFloat32Array:
	var near: Array = []
	for row in rows:
		var d := eye.distance_squared_to(row[0])
		if d > r2:
			continue
		near.append([d, row])

	if near.size() > limit:
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		near.resize(limit)

	var out := PackedFloat32Array()
	for e in near:
		var row: Array = e[1]
		for i in range(1, row.size()):
			out.push_back(float(row[i]))
	return out


## Görüş sahəsindəki sətirləri süzür.
## Sıx ədəd axını kimi süzür — sətrin BİRİNCİ elementi mövqe, qalanı ədədlərdir.
static func _near_flat(rows: Array, eye: Vector2, r2: float, limit: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := 0
	for row in rows:
		if eye.distance_squared_to(row[0]) > r2:
			continue
		for i in range(1, row.size()):
			out.push_back(float(row[i]))
		n += 1
		if limit > 0 and n >= limit:
			break
	return out


## [param limit] 0-dan böyükdürsə, ən çox o qədər sətir qaytarılır.
static func _near(rows: Array, eye: Vector2, r2: float, limit := 0) -> Array:
	var out := []
	for row in rows:
		if eye.distance_squared_to(row[0]) <= r2:
			out.append(row[1])
			if limit > 0 and out.size() >= limit:
				break
	return out


## Qida üçün ayrıca süzgəc: nəticə sıx ədəd axınıdır (id, x, y, id, x, y ...).
##
## Say [constant Const.FOOD_SEND_MAX] ilə məhdudlaşır və ƏN YAXINLAR seçilir.
##
## Hədd olmasaydı, iri mikrobun görüş sahəsi (tutumla böyüyür) bütün qabı
## örtərdi və snapshot-a 110-dan çox qida düşərdi — ölçülüb, tək bu sahə
## 1292 bayt tuturdu, ENet-in MTU-su isə 1392-dir. Uzaqdakı qida onsuz da
## ekrandan kənardadır, yəni itən heç nə yoxdur.
static func _near_food(rows: Array, eye: Vector2, r2: float, limit: int) -> PackedFloat32Array:
	var near: Array = []
	for row in rows:
		var p: Vector2 = row[0]
		var d := eye.distance_squared_to(p)
		if d > r2:
			continue
		near.append([d, row[1], p.x, p.y])

	if near.size() > limit:
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		near.resize(limit)

	var out := PackedFloat32Array()
	for e in near:
		out.push_back(float(e[1]))
		out.push_back(e[2])
		out.push_back(e[3])
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
