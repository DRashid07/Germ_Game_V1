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

## Mikrobun komandası — mikrob ÖLƏNDƏN SONRA da qalır.
##
## Nəticə ekranı ölmüş oyunçuya da göndərilir və orada "hansı komanda idin"
## sualı hələ də mənalıdır. [member Sim.germs] isə ölənləri saxlamır.
var teams := {}

## ÜÇLÜK: hər komandanın udduğu raund sayı.
var round_wins := PackedInt32Array()
## ÜÇLÜK: neçənci raunddur (1-dən başlayır).
var round_no := 1

## CÜT: dirilməni gözləyən mikroblar — `id -> qalan saniyə`.
##
## Ölən mikrob dünyadan çıxır, amma yeri komandaya SAXLANILIR. Yoldaşı da
## ölsə, növbə təmizlənir və cüt matçdan çıxır.
var _revive := {}

var _frame_germs: Array = []    ## [Vector2 pos, Array row]
var _frame_shots: Array = []
var _frame_food: Array = []
var _frame_events: Array = []
var _frame_board := PackedInt32Array()


func _init(p_id: int, p_mode := Const.Mode.ENDLESS) -> void:
	id = p_id
	mode = p_mode
	sim = Sim.new()
	# Qabın kənarı elə İNDİ qurulur, ilk tick-i gözləmədən.
	#
	# Oyunçu [method add_player] ilə tick-dən ƏVVƏL doğulur və
	# [method Sim.find_spawn] məhz bu radiusdan istifadə edir. İlkin dəyər
	# `WORLD_RADIUS` (1200) idi, ÜÇLÜK-ün yaş radiusu isə 700 — yəni doğuş
	# dairəsinin üçdə ikisi QURU zonaya düşürdü. Oyunçu geriyə sayımda,
	# tərpənə bilmədən top yığmağa başlayırdı: doqquz çalışmanın altısı
	# birinci saniyədə "QURUYUR — mərkəzə get" xəbərdarlığı ilə açılırdı.
	sim.dish_radius = Const.dish_radius(int(mode), 0.0)
	# Matçlı rejim oyunçu gözləyir; sonsuz arena isə həmişə açıqdır.
	phase = Const.Phase.PLAYING if mode == Const.Mode.ENDLESS else Const.Phase.WAITING


# ---------------------------------------------------------------- iştirakçılar

func human_count() -> int:
	return peers.size()


func has_room() -> bool:
	# Tutum REJİMDƏN çıxır: ÜÇLÜK altı mikrobludur, sabit 10 işlətsəydik
	# yeddinci oyunçu dolu dünyaya girməyə çalışardı.
	return peers.size() < Const.mode_capacity(int(mode))


## Oyunçunu dünyaya salır və mikrobunu doğurur.
func add_player(peer: int, player_name: String,
		species := Const.Species.CILIATE) -> Sim.GermState:
	# İnsan gələndə bot yerini ona verir — dünya heç vaxt hədddən çox olmur.
	if sim.germs.size() >= Const.mode_capacity(int(mode)):
		_remove_one_bot()
	peers.append(peer)
	_last_seq[peer] = 0
	tokens[peer] = _new_token()
	var g := sim.add_germ(peer, player_name, _free_color(), false, species)
	g.team = _free_team()
	teams[peer] = g.team
	return g


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
			# ÜÇLÜK vaxt həddi matçın deyil, RAUNDUN həddidir.
			if mode == Const.Mode.TRIO and match_t >= Const.TRIO_ROUND:
				_end_round()
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


## ÜÇLÜK: raundu bitirir və ya matçı yekunlaşdırır.
##
## Raund qalibi: sağ mikrobu çox olan komanda; bərabərdirsə TOP CƏMİ çox olan
## (bax design/MODES.md §6.4). Bərabərlik qaydası lazımdır, çünki 60 saniyə
## heç kimin ölmədiyi raund tamamilə mümkündür.
func _end_round() -> void:
	if round_wins.size() < 2:
		round_wins.resize(2)

	var alive := [_team_alive(0), _team_alive(1)]
	var balls := [0, 0]
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.team == 0 or g.team == 1:
			balls[g.team] += g.balls

	var winner := -1
	if alive[0] != alive[1]:
		winner = 0 if alive[0] > alive[1] else 1
	elif balls[0] != balls[1]:
		winner = 0 if balls[0] > balls[1] else 1
	if winner >= 0:
		round_wins[winner] += 1

	# Matç bitdimi?
	if winner >= 0 and round_wins[winner] >= Const.TRIO_ROUNDS_WIN:
		_set_phase(Const.Phase.OVER)
		return

	# Yeni raund: HAMI eyni şərtlərlə doğulur.
	#
	# Tutum raunddan raunda KEÇMİR — keçsəydi, birinci raundu udan komanda
	# ikincidə də üstün başlayardı və matç faktiki olaraq bir raundda həll
	# olunardı.
	round_no += 1
	_revive.clear()
	# `match_t` və qabın radiusu [method _reset_round]-un içində sıfırlanır —
	# doğuş yeri onlardan asılıdır, ona görə bir sahibi olmalıdır.
	_reset_round()
	_set_phase(Const.Phase.COUNTDOWN)


## Raund üçün dünyanı təzələyir: hamı diri, tam əhali, başlanğıc tutumu.
func _reset_round() -> void:
	# Qab ƏVVƏLCƏ genişlənir, sonra hamı doğulur.
	#
	# `_end_round` [method tick]-in İÇİNDƏ, `sim.dish_radius` yenilənməsindən
	# ƏVVƏL çağırılır, yəni bura gələndə radius hələ də bitən raundun SON
	# dəyəridir (ÜÇLÜK-də 220 px). Onsuz altı mikrob quruyub kiçilmiş qabın
	# mərkəzinə — üstəlik maneənin üstünə — yığılırdı.
	match_t = 0.0
	sim.dish_radius = Const.dish_radius(int(mode), 0.0)
	for gid in sim.germs.keys():
		var g: Sim.GermState = sim.germs[gid]
		g.balls = Const.START_BALLS
		g.capacity = Const.START_CAPACITY
		g.charge = 0
		g.super_t = 0.0
		g.dry_t = 0.0
		g.safe_t = Const.SPAWN_SAFE_TIME
		g.vel = Vector2.ZERO
		g.pos = sim.find_spawn(g.radius())
	sim.shots.clear()


## CÜT: dirilmə növbəsini işlədir.
##
## Tutum və super doluluğu SIFIRDAN başlayır — dirilmə ikinci şansdır,
## cəzasız davam deyil. Əks halda dolu cüt qəsdən ölüb təzələnərdi.
func _step_revive(dt: float) -> void:
	if _revive.is_empty():
		return
	for gid in _revive.keys():
		var r: Dictionary = _revive[gid]
		# Yoldaşı da ölübsə dirilmə ləğv olunur — cüt matçdan çıxır.
		if _team_alive(int(r["team"])) <= 0:
			_revive.erase(gid)
			places[gid] = _teams_standing() + 1
			continue
		r["left"] = float(r["left"]) - dt
		if float(r["left"]) > 0.0:
			continue
		_revive.erase(gid)
		var g := sim.add_germ(gid, String(r["name"]), int(r["color"]),
			bool(r["bot"]), Const.species_from(int(r["species"])))
		g.team = int(r["team"])
		if bool(r["bot"]):
			_bots[gid] = Bot.new(gid, randf_range(0.7, 1.3))
		sim.events.append({
			"t": "super", "pos": g.pos, "arg": 0.0, "color": g.color})


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
	#
	# KOMANDALI rejimdə şərt "bir mikrob" yox, "bir KOMANDA" qalmasıdır:
	# CÜT-də sona iki mikrob qalır və matç onda bitir.
	if Const.is_team_mode(int(mode)):
		if _teams_standing() <= 1:
			return true
	elif sim.germs.size() <= 1:
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
	var team: int = int(teams.get(peer, -1))
	var us := 0
	var them := 0
	if mode == Const.Mode.TRIO and team >= 0 and round_wins.size() >= 2:
		us = round_wins[team]
		them = round_wins[1 - team]
	return [
		int(mode),
		int(phase),
		phase_t,
		sim.dish_radius,
		_alive_count(),
		int(places.get(peer, 0)),
		team,
		us,
		them,
	]


## Sağ sayılan mikroblar — CÜT-də dirilmə gözləyən də SAĞ sayılır.
##
## Yoxsa HUD-dakı "SAĞ: N" yoldaş öləndə düşür, 15 saniyə sonra qalxır və
## oyunçu kiminsə matçdan çıxdığını sanır.
func _alive_count() -> int:
	return sim.germs.size() + _revive.size()


## Komandada neçə mikrob sağdır (dirilmə gözləyənlər DAXİL DEYİL).
func _team_alive(team: int) -> int:
	if team < 0:
		return 0
	var n := 0
	for gid in sim.germs:
		if sim.germs[gid].team == team:
			n += 1
	return n


## Neçə komandanın sağ mikrobu var.
func _teams_standing() -> int:
	var seen := {}
	for gid in sim.germs:
		seen[sim.germs[gid].team] = true
	for gid in _revive:
		seen[int(_revive[gid]["team"])] = true
	return seen.size()


# ---------------------------------------------------------------- botlar

## Ən boş komandanın nömrəsi (komandasız rejimdə -1).
##
## Ən azı olana verilir ki, komandalar bərabər dolsun. İnsanlar ayrı-ayrı
## vaxtlarda gəlir və botlar aradakı boşluqları tutur — sadə növbə ilə
## paylasaydıq, bir komanda iki insanla, digəri iki botla qalardı.
func _free_team() -> int:
	if not Const.is_team_mode(int(mode)):
		return -1
	var size := Const.team_size(int(mode))
	var teams := Const.mode_capacity(int(mode)) / size
	var count := PackedInt32Array()
	count.resize(teams)
	for gid in sim.germs:
		var t: int = sim.germs[gid].team
		if t >= 0 and t < teams:
			count[t] += 1

	var best := 0
	for i in teams:
		if count[i] < count[best]:
			best = i
	return best


func _add_bot() -> void:
	var bid := _next_bot_id
	_next_bot_id += 1
	_bot_name_no += 1
	# Çətinlik təsadüfidir: dünyada həm asan, həm təhlükəli mikroblar olsun.
	var bot := Bot.new(bid, randf_range(0.7, 1.3))
	_bots[bid] = bot
	# Botların növü təsadüfidir ki, dünyada hər üç növ görünsün.
	var species := Const.species_from(randi() % Const.SPECIES_COUNT)
	var g := sim.add_germ(bid, Bot.random_name(_bot_name_no), _free_color(), true, species)
	g.team = _free_team()
	teams[bid] = g.team


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
		while sim.germs.size() < Const.mode_capacity(int(mode)):
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
	# BİR DƏFƏLİK bayraqlar köhnə paketdən yenisinə KEÇİR, onunla birlikdə
	# atılmır.
	#
	# Növbədə oyunçu başına yalnız SON giriş saxlanılır, iki paketin bir tick
	# aralığında gəlməsi isə adi haldır: client kadr sıçrayanda iki tick-i bir
	# kadrda göndərir ([method Arena._process] beş tick-ə qədər bərabərləşdirir),
	# WebSocket isə paketləri onsuz da yığır.
	#
	# Hərəkət üçün bunun əhəmiyyəti yoxdur — sonuncu mövqe onsuz da doğrudur.
	# Atəş də bilinmirdi, çünki düymə basılı saxlanılır və növbəti tick onu
	# təkrar göndərir. SUPER isə CƏMİ BİR tick göndərilir
	# ([method Arena._super_requested]), ona görə üstündən yazılan paket onu
	# tamamilə udurdu: oyunçu yanan düyməyə basırdı, proqnoz effekti bir kadr
	# göstərirdi, növbəti snapshot onu ləğv edirdi və doluluq yerində qalırdı.
	#
	# Ölçülüb: LOKAL WebSocket bağlantısında (itkisiz şəbəkə, sıfır gecikmə)
	# 50 saniyədə 1761 girişin 62-si belə atılırdı — 3.4%. Şəbəkə jitter-i ilə
	# rəqəm yalnız böyüyür, yəni onlayn oyunda superin "işləməməsi" məhz burada
	# doğulurdu.
	var queued: Sim.PlayerInput = _inputs.get(peer)
	if queued != null:
		inp.fire = inp.fire or queued.fire
		inp.use_super = inp.use_super or queued.use_super
	_inputs[peer] = inp


## Bir tick. Partlayan oyunçuların siyahısını qaytarır — [Lobby] onlara
## nəticə göndərib dünyadan çıxarır.
func tick(dt: float) -> Array:
	_step_phase(dt)
	# Qabın kənarı YALNIZ rejimdən və matç saatından çıxır — prediction şərti
	# (bax [method Const.dish_radius]).
	sim.dish_radius = Const.dish_radius(int(mode), match_t)
	_keep_population(dt)
	# Spor TƏK QALAN və CÜT-dədir. ÜÇLÜK-də yoxdur: raund 60 saniyədir və
	# tutum artımı o qədər qısa oyunda balansı pozur (bax design/MODES.md §6.4).
	if phase == Const.Phase.PLAYING \
			and (mode == Const.Mode.SOLO or mode == Const.Mode.DUO):
		sim.keep_spores(dt)
	if phase == Const.Phase.PLAYING:
		_step_revive(dt)

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

		# CÜT — yoldaşı sağ ikən ölüm MÜVƏQQƏTİDİR.
		#
		# Yer verilmir, nəticə ekranı göndərilmir, mikrob dünyaya qayıdır
		# (bax [method _step_revive]). Yoldaşı da ölübsə, cüt matçdan çıxır və
		# adi ölüm yolu işləyir.
		var t: int = int(teams.get(gid, -1))
		if mode == Const.Mode.DUO and phase == Const.Phase.PLAYING \
				and _team_alive(t) > 0:
			_revive[gid] = {
				"left": Const.REVIVE_TIME,
				"team": t,
				"bot": _bots.has(gid),
				"name": String(entry.get("name", "Mikrob")),
				"color": int(entry.get("color", 0)),
				"species": int(entry.get("species", 0)),
			}
			if _bots.has(gid):
				_bots.erase(gid)
			continue

		if mode != Const.Mode.ENDLESS:
			places[gid] = place
			place += 1
		if _bots.has(gid):
			_bots.erase(gid)
			continue
		out.append(entry)

	if phase == Const.Phase.PLAYING and _match_over():
		# ÜÇLÜK-də bir komandanın qırılması RAUNDU bitirir, matçı yox.
		if mode == Const.Mode.TRIO:
			_end_round()
		else:
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
	# Komanda `team + 1` kimi yazılır ki, SIFIR "komandasız" qalsın
	# (bax [enum Const.GFlag]).
	if g.team >= 0:
		f |= ((g.team + 1) << Const.GFlag.TEAM_SHIFT) & Const.GFlag.TEAM_MASK
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
		# ƏHALİ və SAĞ SAY eyni tərifdən çıxır ([method _alive_count]).
		#
		# Əvvəl bura `sim.germs.size()` gedirdi, matç sətrinə isə dirilmə
		# gözləyənlər DAXİL olan say — nəticədə HUD-un iki qonşu sətri
		# ziddiyyət yazırdı: "Dünyada 8 mikrob" və altında "SAĞ: 10".
		# CÜT-də yoldaş öləndən dirilənə qədər 15 saniyə belə görünürdü.
		_alive_count(),
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
##
## Hədd aşılanda ƏN YAXINLAR seçilir, ilk gələnlər yox — top və qida ilə eyni
## qayda ([method _near_shots], [method _near_food]).
##
## Əvvəl sadəcə `break` idi və sıra `sim.events`-in doğulma sırası idi: bir
## tick-də neçə hadisə varsa, ilk üçü keçirdi. Büdcə sıxılanda `event_n`
## cəmi 3 ola bilir (bax [method snapshot_for]), yəni uzaqda partlayan üç
## mikrob OYUNÇUNUN ÖZ SUPERİNİ paketdən çıxarırdı — basırdın, doluluq
## sıfırlanırdı, amma ekranda heç nə olmurdu.
static func _near_flat(rows: Array, eye: Vector2, r2: float, limit: int) -> PackedFloat32Array:
	var near: Array = []
	for row in rows:
		var d := eye.distance_squared_to(row[0])
		if d > r2:
			continue
		near.append([d, row])

	if limit > 0 and near.size() > limit:
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		near.resize(limit)

	var out := PackedFloat32Array()
	for e in near:
		var row: Array = e[1]
		for i in range(1, row.size()):
			out.push_back(float(row[i]))
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
