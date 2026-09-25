class_name Sim
extends RefCounted
## Oyunun bütün məntiqi — səhnə node-ları olmadan, saf məlumat üzərində.
##
## Bu sinif EYNİ ilə üç yerdə işləyir:
##   1. Serverdə — həqiqət mənbəyi (authoritative)
##   2. Client-də — öz mikrobun üçün prediction
##   3. Client-də — server düzəlişi gələndə reconciliation (geri sar, yenidən oynat)
##
## Məhz buna görə Godot fizikası istifadə olunmur: fizika mühərriki geri sarılıb
## yenidən oynadıla bilmir, bu isə prediction-u qeyri-mümkün edir.
##
## ── Oyunun qaydası bir cümlədə ───────────────────────────────────────────
## Mikrobun içindəki top sayı həm sursat, həm candır:
##   • Atəş = öz içindən bir top atmaq (səndə −1, dəydiyi rəqibdə +2: top bölünür)
##   • Rəqibin sayı TUTUMU aşsa → partlayır, partladan tutum +5 alır
##   • Öz sayın MIN_BALLS-dan aşağı düşsə → acından partlayırsan
##   • Metabolizm vaxt keçdikcə top yandırır → yemək məcburidir


class GermState:
	var id: int
	var name := "Mikrob"
	var color := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var aim := 0.0
	var balls := Const.START_BALLS
	var capacity := Const.START_CAPACITY
	var cooldown := 0.0
	var safe_t := 0.0           ## Doğuş toxunulmazlığı
	var drain_t := 0.0          ## Növbəti topun yanmasına qalan vaxt
	var pops := 0               ## Neçə rəqib partladıb
	var age := 0.0              ## Neçə saniyədir yaşayır
	var is_bot := false
	var alive := true           ## false = bu tick partladı, indi silinəcək
	## Superin doluluğu 0..[constant Const.SUPER_MAX]. Snapshot-da bayrağın
	## boş bitlərində gedir (bax [enum Const.GFlag]) — ayrıca sahə deyil.
	var charge := 0
	## Super İNDİ nə qədər davam edir. Kirpiklinin superi anidir (0 qalır),
	## ayaqlının toru və amöbin qabığı isə vaxt tutur.
	var super_t := 0.0
	## Doluluğa doğru yeyilmiş qida sayğacı — hər [constant Const.SUPER_FOOD_PER]
	## qidadan bir doluluq artır. Vəziyyətdədir ki, reconciliation zamanı
	## itməsin.
	var food_acc := 0
	## Quru zonada növbəti topun yığılmasına qalan vaxt (bax [method Sim._step_germs]).
	var dry_t := 0.0
	## Görüntü növü — oyunçunun menyuda seçdiyi (bax [enum Const.Species]).
	## Simulyasiyaya TƏSİR EDİR: sürətlənmə, sönmə, axına tabelik və maneə
	## radiusu növdən çıxır ([constant Const.SPECIES_THRUST]), üstəlik hər növün
	## öz superi var ([method _use_super]). Döyüş riyaziyyatı — atəş dövrü,
	## topun qiyməti, tutum artımı — üç növdə də EYNİDİR və bu, testlə saxlanılır.
	var species := Const.Species.CILIATE
	## Komanda nömrəsi, -1 = komandasız (SONSUZ ARENA, TƏK QALAN).
	##
	## Simulyasiyaya təsir edir: yoldaşa top dəymir və tor yoldaşı yavaşlatmır.
	## İTƏLƏMƏ isə komandaya baxmır — üst-üstə düşən iki yoldaş ekranda
	## oxunmaz bir ləkəyə çevrilərdi.
	var team := -1

	func radius() -> float:
		return Const.germ_radius(capacity)

	func speed() -> float:
		return Const.germ_speed(capacity) * Const.SPECIES_SPEED[int(species)]

	## Doluluq 0..1 — HUD-dakı zolaq və membranın gərginliyi bundan gəlir.
	func fill() -> float:
		return clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)

	func clone() -> GermState:
		var c := GermState.new()
		c.id = id; c.name = name; c.color = color
		c.pos = pos; c.vel = vel; c.aim = aim
		c.balls = balls; c.capacity = capacity
		c.cooldown = cooldown; c.safe_t = safe_t; c.drain_t = drain_t
		c.pops = pops; c.age = age; c.is_bot = is_bot; c.alive = alive
		c.species = species
		c.team = team
		c.charge = charge; c.super_t = super_t; c.food_acc = food_acc
		c.dry_t = dry_t
		return c


	## Superi işlətməyə hazırdırmı — doluluq DA, qiyməti də.
	##
	## Trixosist top xərcləyir, ona görə burada da DÖŞƏMƏ var — eynilə atəşdəki
	## [constant Const.FIRE_MIN_BALLS] kimi və eyni səbəbdən: qanuni bir hərəkət
	## oyunçunu öldürməməlidir. Döşəmə olmasaydı, üç toplu oyunçu yanan düyməni
	## basıb dərhal acından partlayardı — düymə ona xilas vəd edib öldürərdi.
	##
	## Qalan iki superin top qiyməti yoxdur (onların qiyməti vaxt və riskdir),
	## ona görə şərt praktikada yalnız kirpikliyə aiddir.
	##
	## Döşəmənin ÖZÜ [method Const.super_min_balls]-dadır: HUD həmin rəqəmi
	## oyunçuya yazmalıdır ([method Const.super_block_reason]) və iki yerdə
	## saxlanılsaydı, biri dəyişəndə düymə yenidən səbəbsiz susardı.
	func super_ready() -> bool:
		if charge < Const.SUPER_MAX or super_t > 0.0:
			return false
		return balls >= Const.super_min_balls(int(species))

	## Amöb qabığın içindədir: top səkir, metabolizm dayanır, tərpənmir.
	func in_cyst() -> bool:
		return species == Const.Species.AMOEBA and super_t > 0.0

	## Ayaqlının toru açıqdır: qida axır, yaxındakı rəqib yavaşıyır.
	func in_net() -> bool:
		return species == Const.Species.HELIOZOAN and super_t > 0.0


## Uçan top — atılmış, hələ heç kimə dəyməmiş mikrob topu.
class ShotState:
	var id: int
	var owner_id: int
	var color := 0
	var pos := Vector2.ZERO
	var dir := Vector2.RIGHT
	var life := 0.0
	var bounces := 0


## Yerdəki sərbəst top (qida). Atılıb boşa gedən toplar da buna çevrilir —
## dünyada maddə itmir, sadəcə sahib dəyişir.
class FoodState:
	## Müsbət — adi qida, MƏNFİ — spor.
	##
	## Bayraq id-nin İŞARƏSİNDƏ daşınır, ayrıca sahədə yox. Qida axını
	## snapshot-un ən ağır hissəsidir və [constant Const.FOOD_STRIDE] üç ədəddir;
	## dördüncü sahə axını 33% ağırlaşdırardı. İşarə isə pulsuzdur.
	var id: int
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var lock_id := 0            ## Bu mikrob onu hələ uda bilməz
	var lock_t := 0.0


## Bir tick üçün oyunçu girişi.
class PlayerInput:
	var seq := 0
	var move := Vector2.ZERO
	var aim := 0.0
	var fire := false
	var use_super := false

	static func make(p_seq: int, p_move: Vector2, p_aim: float, p_fire: bool,
			p_super := false) -> PlayerInput:
		var i := PlayerInput.new()
		i.seq = p_seq
		i.move = p_move.limit_length(1.0)
		i.aim = p_aim
		i.fire = p_fire
		i.use_super = p_super
		return i

	## İki bayraq BİR ədəddə gedir, ayrı-ayrı sahələrdə yox.
	##
	## Giriş paketi saniyədə 30 dəfə göndərilir və Variant massivində hər ədəd
	## 9 bayt tutur. Atəş onsuz da 0/1 idi — super onun yanındakı bitə girir və
	## massivin uzunluğu DƏYİŞMİR.
	func to_array() -> Array:
		return [seq, move.x, move.y, aim, (1 if fire else 0) | (2 if use_super else 0)]

	static func from_array(a: Array) -> PlayerInput:
		var bits := int(a[4])
		return PlayerInput.make(int(a[0]), Vector2(a[1], a[2]), float(a[3]),
			(bits & 1) != 0, (bits & 2) != 0)


var tick := 0

## Qabın hazırkı işlək radiusu — YAŞ RADİUS.
##
## [World] hər tick-dən əvvəl [method Const.dish_radius] ilə doldurur.
## [Sim] onu özü hesablamır: rejim və matç saatı dünyanın işidir, simulyasiya
## isə yalnız "kənar buradadır" bilməlidir. Client-in proqnozu eyni dəyəri
## snapshot-dan alır (bax [enum Const.MF]).
##
## Bu radius DİVAR DEYİL — [method _confine] yenə [constant Const.WORLD_RADIUS]
## işlədir. Quru zona keçilə biləndir və oyunçu ora ÖZ SEÇİMİ ilə girir.
var dish_radius := Const.WORLD_RADIUS

var germs := {}                         ## id -> GermState
var shots: Array[ShotState] = []
var food: Array[FoodState] = []
var obstacles: Array[Vector4] = []

## Dağılmış maneələr — 1 = artıq yoxdur. İndeks [member obstacles] ilə eynidir.
##
## `PackedByteArray` seçilib, Dictionary yox: bu massiv hər tick-də hər mikrob
## və hər top üçün oxunur. Paketlənmiş massivdə yoxlama sadə indeksləmədir,
## Dictionary-də isə hash hesablanması — sıx yolda fərq ölçüləndir.
##
## Şəbəkəyə MƏHZ bu massiv gedir (bax [constant Const.Snap.WALLS]): mövqe və
## radius onsuz da hər iki tərəfdə var ([DishMap] paylaşılan koddadır), ona
## görə 22 baytla bütün dağıntı vəziyyəti köçürülür.
var broken := PackedByteArray()

## Kövrək qabıqların qalan canı. İndeks [member obstacles] ilə eynidir.
## Yalnız [constant DishMap.Kind.BRITTLE] üçün mənalıdır.
var brittle_hp := PackedByteArray()

## Yalnız təqdimat üçün (səs, partikullar). Simulyasiyaya təsir etmir,
## ona görə reconciliation zamanı təhlükəsiz şəkildə atılır.
var events: Array[Dictionary] = []

## Bu tick-də partlayan mikroblar: {"id", "killer", "pops", "cap", "age"}.
## Server bunu oxuyub oyunçuya nəticə ekranını göndərir və onu dünyadan çıxarır.
var burst_log: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()

var _next_shot_id := 1
var _next_food_id := 1
var _food_budget := 0.0
var _spore_timer := 0.0
## Prediction rejimi: metabolizm və acından partlama işlədilmir
## (bax [method step_movement]).
var _no_metabolism := false


func _init() -> void:
	obstacles = DishMap.obstacles()
	_reset_walls()
	rng.randomize()


## Divar vəziyyətini başlanğıc halına qaytarır — bütün qabıqlar bütövdür.
func _reset_walls() -> void:
	broken.resize(obstacles.size())
	brittle_hp.resize(obstacles.size())
	for i in obstacles.size():
		broken[i] = 0
		brittle_hp[i] = DishMap.BRITTLE_HP if int(obstacles[i].w) == DishMap.Kind.BRITTLE else 0


# ---------------------------------------------------------------- mikroblar

func add_germ(id: int, germ_name: String, color: int, bot := false,
		species := Const.Species.CILIATE) -> GermState:
	var g := GermState.new()
	g.id = id
	g.name = germ_name
	g.color = color
	g.is_bot = bot
	g.species = species
	g.balls = Const.START_BALLS
	g.capacity = Const.START_CAPACITY
	g.safe_t = Const.SPAWN_SAFE_TIME
	g.drain_t = Const.drain_period(g.capacity)
	g.pos = find_spawn(g.radius())
	# Neytral halda mərkəzə baxır — doğulan kimi divara atəş açmasın.
	g.aim = (-g.pos).angle() if g.pos.length() > 1.0 else 0.0
	germs[id] = g
	return g


func remove_germ(id: int) -> void:
	germs.erase(id)
	for i in range(shots.size() - 1, -1, -1):
		if shots[i].owner_id == id:
			shots.remove_at(i)


## Mikrobun açarını dəyişir.
##
## Yenidən qoşulanda peer id dəyişir, amma mikrobun özü — mövqeyi, topları,
## hesabı — eyni qalmalıdır. Ona görə silib yenidən yaratmaq olmaz.
func rekey_germ(old_id: int, new_id: int) -> void:
	if old_id == new_id or not germs.has(old_id):
		return
	var g: GermState = germs[old_id]
	germs.erase(old_id)
	g.id = new_id
	germs[new_id] = g
	for s in shots:
		if s.owner_id == old_id:
			s.owner_id = new_id
	for f in food:
		if f.lock_id == old_id:
			f.lock_id = new_id


## Maneədən və başqa mikroblardan uzaq boş yer tapır.
## Tapılmasa (dünya çox sıxdırsa) ən son namizədi qaytarır — oyun dayanmamalıdır.
## Boş yer YAŞ radiusun içində axtarılır — quru zonada doğulan qida və mikrob
## oyunçunu ora çəkərdi, halbuki ora təhlükə sahəsidir.
func find_spawn(radius: float) -> Vector2:
	var pad := radius + 40.0
	var pos := Vector2.ZERO
	for _attempt in 40:
		var a := rng.randf() * TAU
		# sqrt — dairə üzrə BƏRABƏR paylanma (əks halda hamı mərkəzdə doğulur)
		var d := sqrt(rng.randf()) * maxf(dish_radius - pad, 40.0)
		pos = Vector2.from_angle(a) * d
		if not DishMap.is_free(pos, pad):
			continue
		var clear := true
		for gid in germs:
			var other: GermState = germs[gid]
			# Doğuş yeri rəqiblərdən UZAQ olmalıdır — 320 px atəş məsafəsinin üçdə biridir,
			# yəni yeni oyunçu heç olmasa yerini seçməyə vaxt tapır.
			if pos.distance_to(other.pos) < other.radius() + pad + 320.0:
				clear = false
				break
		if clear:
			return pos
	return pos


## Dünyanın liderləri — ən çox partlatmaya görə. Bərabərlikdə tutum həll edir.
func leaderboard(limit := 5) -> Array:
	var rows := []
	for id in germs:
		var g: GermState = germs[id]
		rows.append([g.id, g.name, g.pops, g.capacity])
	rows.sort_custom(func(a, b):
		if int(a[Const.LF.POPS]) != int(b[Const.LF.POPS]):
			return int(a[Const.LF.POPS]) > int(b[Const.LF.POPS])
		return int(a[Const.LF.CAP]) > int(b[Const.LF.CAP]))
	return rows.slice(0, limit)


# ---------------------------------------------------------------- addım

## Simulyasiyanı bir tick irəli aparır.
## [param inputs]: {germ_id: PlayerInput}
func step(inputs: Dictionary, dt: float) -> void:
	events.clear()
	burst_log.clear()
	tick += 1

	_step_germs(inputs, dt)
	_separate_germs()
	_step_shots(dt)
	_step_food(dt)
	_dry_food()
	_spawn_food(dt)
	_reap()


## Yalnız öz mikrobunun hərəkətini addımlayır — client-də prediction və
## reconciliation üçün.
##
## Toplar, qida və ölüm serverin sözüdür, ona görə burada emal olunmur.
## Ancaq atəşin özü işlənir: client belə öz cooldown-unu düzgün bilir və
## atəş effektini dərhal oynada bilir. Reconciliation zamanı
## ([param keep_events] = false) hadisələr atılır — əks halda həmin
## atəş səsi hər düzəlişdə təkrar çalınardı.
func step_movement(inputs: Dictionary, dt: float, keep_events := true) -> void:
	events.clear()
	tick += 1
	# Metabolizm və acından partlama serverin sözüdür. Client-də təkrar
	# hesablansaydı, proqnozdakı top sayı hər snapshot arasında yanıb-sönərdi.
	_no_metabolism = true
	_step_germs(inputs, dt)
	_no_metabolism = false
	shots.clear()
	if not keep_events:
		events.clear()


func _step_germs(inputs: Dictionary, dt: float) -> void:
	var starved: Array[GermState] = []

	# Tor yalnız AYAQLIDA olur, növ isə tick boyu dəyişmir. [method _net_slow]
	# hər mikrob üçün bütün dünyanı gəzməsin deyə ayaqlılar əvvəlcədən
	# seçilir (sıra `germs`-in sırasıdır). Tor açılıb-bağlanması tick-in
	# İÇİNDƏ baş verir, ona görə `in_net()` yenə canlı yoxlanılır.
	var helios: Array[GermState] = []
	for id in germs:
		var h: GermState = germs[id]
		if h.species == Const.Species.HELIOZOAN:
			helios.append(h)

	for id in germs:
		var g: GermState = germs[id]
		if not g.alive:
			continue

		var inp: PlayerInput = inputs.get(id)
		var wish := Vector2.ZERO
		if inp != null:
			wish = inp.move
			g.aim = inp.aim

		# ── Maye hərəkəti ────────────────────────────────────────────────
		# Mikrob suyu itələyərək gedir, ona görə sürət birbaşa təyin olunmur:
		# itələmə var → hədəf sürətə yaxınlaşır, itələmə yox → müqavimət söndürür.
		# Sönmə eksponensialdır, yəni addım ölçüsündən asılı deyil — 30 Hz server
		# ilə dəyişkən kadrlı client eyni nəticəni alır (prediction üçün şərtdir).
		#
		# Sürət SUYA NİSBƏTƏN saxlanılır: axın ayrıca əlavə olunur. Belə olanda
		# axına qarşı üzmək onu tam ləğv etmir — mikrob yenə də sürüklənir,
		# maye hissi məhz buradan gəlir.
		#
		# Əmsallar NÖVDƏN gəlir (bax [constant Const.SPECIES_THRUST]): kirpikli
		# tez qopub uzun sürüşür, amöb ağır qopur, ayaqlı isə suya az tabedir.
		var sp := int(g.species)
		g.super_t = maxf(0.0, g.super_t - dt)

		if g.in_cyst():
			# Qabıq bağlıdır: nə hərəkət, nə axın, nə metabolizm, nə atəş.
			# Sist YATMIŞ haldır — canlı öz həyatını müvəqqəti dayandırır.
			g.vel = Vector2.ZERO
			g.age += dt
			g.cooldown = maxf(0.0, g.cooldown - dt)
			g.safe_t = maxf(0.0, g.safe_t - dt)
			continue

		if wish.length_squared() > 0.0001:
			# Tora düşən rəqib yavaşıyır — şüalara yapışır.
			var target := wish * g.speed() * _net_slow(g, helios)
			g.vel = g.vel.lerp(target,
				1.0 - exp(-Const.FLUID_THRUST * Const.SPECIES_THRUST[sp] * dt))
		else:
			g.vel *= exp(-Const.FLUID_DRAG * Const.SPECIES_DRAG[sp] * dt)

		var flow := (Const.current_at(g.pos) + _vent_push(g.pos)) * Const.SPECIES_FLOW[sp]
		g.pos += (g.vel + flow) * dt
		_confine(g)

		g.age += dt
		g.cooldown = maxf(0.0, g.cooldown - dt)
		g.safe_t = maxf(0.0, g.safe_t - dt)

		# Metabolizm: vaxt keçdikcə bir top yanır.
		if not _no_metabolism:
			g.drain_t -= dt
			if g.drain_t <= 0.0:
				g.drain_t += Const.drain_period(g.capacity)
				g.balls -= 1

			# QURU ZONA — qab quruyub, mühit qatılaşıb: mikrob top QAZANIR.
			#
			# Top itirmir, çünki aclıqdan ölmək sönükdür və kənarı sadəcə "pis"
			# edir. Qazanmaq isə dilemma yaradır: kənar həm təhlükə, həm YEMDİR —
			# boşalmış oyunçu qəsdən ora çıxıb doldura bilər. Üstəlik dolu
			# oyunçunu mərkəzə sıxır, ac oyunçu isə orada nəfəs alır.
			#
			# Metabolizmlə EYNİ şərtin altındadır və bu, məcburidir: client
			# top sayını proqnozlaşdırmır, yoxsa HUD-dakı rəqəm hər snapshot
			# arasında yanıb-sönərdi.
			var depth := g.pos.length() - dish_radius
			if depth > 0.0:
				g.dry_t -= dt
				if g.dry_t <= 0.0:
					g.dry_t += Const.dry_period(depth)
					g.balls += 1
					if g.balls > g.capacity:
						_burst(g, 0)
						continue
			else:
				g.dry_t = 0.0

		# Super atəşdən ƏVVƏL yoxlanılır: eyni kadrda ikisi də basılsa,
		# oyunçunun niyyəti böyük olandır.
		if inp != null and inp.use_super and g.super_ready():
			_use_super(g)

		if inp != null and inp.fire and g.cooldown <= 0.0 and g.balls >= Const.FIRE_MIN_BALLS:
			_fire(g)

		if g.balls < Const.MIN_BALLS and not _no_metabolism:
			starved.append(g)

	# Partlama dictionary-ni dəyişdiyi üçün gəzinti bitəndən sonra icra olunur.
	for g in starved:
		_burst(g, 0)


# ---------------------------------------------------------------- super

## Tora düşən mikrobun sürət əmsalı.
##
## Yalnız BAŞQASININ toru yavaşladır — öz torun səni saxlamır. Client-in
## proqnoz simulyasiyasında yalnız öz mikrobun var, ona görə rəqibin toru
## proqnozda görünmür və düzəlişlə gəlir. Bu, dəymə ilə eyni davranışdır:
## rəqibin sənə etdiyi hər şey serverin sözüdür.
##
## [param helios] — dünyadakı ayaqlılar, `germs` sırası ilə (bax
## [method _step_germs]). Başqa növün toru olmur, yəni nəticə eynidir.
func _net_slow(g: GermState, helios: Array[GermState]) -> float:
	for o in helios:
		if o.id == g.id or not o.alive or not o.in_net():
			continue
		# Tor YOLDAŞI yavaşlatmır — yoxsa ayaqlı öz komandasını tələyə salır və
		# super komanda rejimində cəzaya çevrilir.
		if o.team >= 0 and o.team == g.team:
			continue
		var reach := o.radius() * Const.NET_RADIUS
		if g.pos.distance_squared_to(o.pos) <= reach * reach:
			return Const.NET_SLOW
	return 1.0


## Super işə düşdü. Doluluq sıfırlanır və növün öz effekti başlayır.
##
## Üç super da rəqibin TOP SAYINA toxunmur: biri mövqe, biri qida, biri vaxt
## üzərində işləyir. Zərər verən super [constant Const.SHOT_PAYLOAD]
## riyaziyyatını yan yoldan pozardı (bax həmin sabitin izahı).
func _use_super(g: GermState) -> void:
	g.charge = 0
	# Hadisənin arg sahəsi trixosistin TƏSİR RADİUSUNU daşıyır (qalan iki
	# superdə sıfır). Səbəb: partlayışın görüntüsü həqiqi sahə ilə eyni
	# böyüklükdə olmalıdır — oyunçu radiusu yalnız effektdən öyrənir.
	#
	# Tor və qabıq isə DAVAM EDƏN vəziyyətdir və onları [GermVisual] özü
	# çəkir, ona görə hadisəyə yalnız səs və qığılcım qalır.
	var reach := 0.0
	if g.species == Const.Species.CILIATE:
		reach = g.radius() * Const.TRICHO_RADIUS
	events.append({
		"t": "super",
		"pos": g.pos,
		"arg": reach,
		"color": g.color,
	})
	# Davametmə [method Const.super_time]-dan gəlir: client eyni cədvəldən
	# oxuyur (bax [method Arena._reconcile]), yəni müddət BİR yerdə yazılır.
	match g.species:
		Const.Species.CILIATE:
			_super_trichocyst(g)
		_:
			g.super_t = Const.super_time(int(g.species))


## KİRPİKLİ — trixosist partlayışı.
##
## Paramesium yırtıcı toxunanda dərisindəki trixosistləri partladır və eyni
## anda kirpiklərini tərsinə döyüb geri üzür. Ölçülüb: bu qabiliyyəti olmayan
## mutantlar 9–45 dəfə tez yeyilir.
##
## Oyunda: yaxındakı RƏQİB topları dağılır — amma yox olmur, qida kimi yerə
## tökülür. Dünyada maddə itmir ([method _burst] da eyni qanunla işləyir), ona
## görə səni vuran öz topunu geri yeyə bilər. Qaçmaq pulsuz deyil.
func _super_trichocyst(g: GermState) -> void:
	var reach := g.radius() * Const.TRICHO_RADIUS
	var reach2 := reach * reach

	var survivors: Array[ShotState] = []
	for shot in shots:
		if shot.owner_id != g.id and shot.pos.distance_squared_to(g.pos) <= reach2:
			# Sahib SIFIR verilir: dağılan top artıq heç kimin deyil, hamı
			# eyni anda yeyə bilər.
			_drop_food(shot.pos, shot.dir * 60.0, 0)
			continue
		survivors.append(shot)
	shots = survivors

	# Yaxındakı mikroblar itələnir — mərkəzdə güclü, kənarda sıfır.
	for id in germs:
		var o: GermState = germs[id]
		if o.id == g.id or not o.alive or o.in_cyst():
			continue
		var delta := o.pos - g.pos
		var d := delta.length()
		if d > reach or d < 0.001:
			continue
		o.vel += (delta / d) * Const.TRICHO_PUSH * (1.0 - d / reach)

	# Kirpiklərin tərsinə döyüntüsü — özü geri sıçrayır.
	g.vel -= Vector2.from_angle(g.aim) * Const.TRICHO_DASH
	# Trixosist maddədir. Bu oyunda maddə = top = həm sursat, həm can.
	g.balls -= Const.TRICHO_COST


## Superin doluluğunu artırır. Həddi keçmir — dörd bitə sığmalıdır.
func _charge(g: GermState, amount: int) -> void:
	if g == null or not g.alive:
		return
	g.charge = clampi(g.charge + amount, 0, Const.SUPER_MAX)


## Mikrobu qabın içində və maneələrdən kənarda saxlayır.
func _confine(g: GermState) -> void:
	var r := g.radius()
	# Maneə üçün radius NÖVƏ görə kiçilir: amöbin sabit forması yoxdur, ona
	# görə başqasının sığmadığı aralıqdan sızır (bax [constant
	# Const.SPECIES_BODY]). Qabın şüşə kənarı isə hamı üçün eynidir — dünyanın
	# sərhədi forma məsələsi deyil.
	var rb := r * Const.SPECIES_BODY[int(g.species)]
	# Yalnız BLOKLAYAN və hələ DAĞILMAMIŞ maneələr saxlayır. Kol və cərəyan
	# deşiyi mikrobu buraxır (bax [method DishMap.blocks_germ]).
	#
	# Məsafə İLK yoxlanılır: mikrob adətən heç bir maneəyə toxunmur və iki
	# statik çağırış yalnız toxunan maneəyə qalır. Şərtlər yan təsirsizdir.
	for i in obstacles.size():
		var o := obstacles[i]
		var c := Vector2(o.x, o.y)
		var min_d := o.z + rb
		var delta := g.pos - c
		var d := delta.length()
		if not (d < min_d):
			continue
		if DishMap.wall_gone(broken[i]) or not DishMap.blocks_germ(int(o.w)):
			continue
		var n := (delta / d) if d > 0.001 else Vector2.RIGHT
		g.pos = c + n * min_d
		# Maneəyə dik gələn sürət söndürülür, yan sürət qalır — mikrob sürüşür.
		g.vel -= n * minf(g.vel.dot(n), 0.0)


	var limit := Const.WORLD_RADIUS - r
	if g.pos.length() > limit:
		var n := g.pos.normalized()
		g.pos = n * limit
		g.vel -= n * maxf(g.vel.dot(n), 0.0)

## Cərəyan deşiklərinin itələməsi. Verilmiş nöqtədə əlavə sürət qaytarır.
##
## İstiqamət MƏRKƏZƏ doğrudur və mövqedən çıxarılır — snapshot-a bir bayt da
## əlavə olunmur, `Vector4`-ün dördü də doludur. Bu, həm də oyun qaydasıdır:
## deşiklər xarici halqadadır ([method DishMap._build_rings]), yəni kənara
## sıxışdırılan oyunçuya mərkəzə qayıtmaq üçün bir yol verirlər.
##
## Güc kənara doğru SÖNÜR (kvadratik): deşiyin sərhədində sıfırdır. Kəskin
## keçid olsaydı, sərhəddə dayanan mikrob kadr-kadr içəri-bayıra atılıb
## titrəyərdi — proqnozla server arasında ən pis fərq növü budur.
##
## Axın kimi davranır, təkan kimi yox: [member GermState.vel]-ə toxunmur,
## yalnız mövqeyə əlavə olunur. Səbəb determinizmdir — sürətə yazsaydıq,
## client-in düzəlişi (bax [method Arena._reconcile]) itələməni İKİ dəfə
## saymış olardı.
func _vent_push(at: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for i in obstacles.size():
		# Növ əvvəl yoxlanılır: deşik azdır, statik çağırış yalnız onlara gedir.
		var o := obstacles[i]
		if int(o.w) != DishMap.Kind.VENT or DishMap.wall_gone(broken[i]):
			continue
		var c := Vector2(o.x, o.y)
		var d := at.distance_to(c)
		if d >= o.z:
			continue
		var u := 1.0 - d / o.z
		# Mərkəzə doğru. Deşiyin özü mərkəzdədirsə istiqamət yoxdur — belə
		# hal düzümdə olmamalıdır, amma sıfıra bölmə qadağandır.
		var dir := (-c).normalized() if c.length() > 0.001 else Vector2.ZERO
		push += dir * (Const.VENT_SPEED * u * u)
	return push


## Mikroblar bir-birinin içinə girmir — üst-üstə yığılma oyunu oxunmaz edir.
## İki tərəf bərabər itələnir, ona görə heç kim divara sıxışdırıla bilmir.
func _separate_germs() -> void:
	# Cüt döngüsüdür, ona görə radius hər mikrob üçün BİR dəfə hesablanır —
	# itələmə yalnız mövqeni dəyişir, tutumu yox.
	var list := germs.values()
	var radii := PackedFloat64Array()
	for g: GermState in list:
		radii.append(g.radius())
	for i in range(list.size()):
		var a: GermState = list[i]
		if not a.alive:
			continue
		for j in range(i + 1, list.size()):
			var b: GermState = list[j]
			if not b.alive:
				continue
			var delta := b.pos - a.pos
			var min_d := radii[i] + radii[j]
			var d := delta.length()
			if d >= min_d:
				continue
			var n := (delta / d) if d > 0.001 else Vector2.from_angle(float(a.id) * 0.37)
			var push := (min_d - d) * 0.5
			a.pos -= n * push
			b.pos += n * push


func _fire(g: GermState) -> void:
	var dir := Vector2.from_angle(g.aim)
	var s := ShotState.new()
	s.id = _next_shot_id
	_next_shot_id += 1
	s.owner_id = g.id
	s.color = g.color
	# Top mikrobun İÇİNDƏN doğulur və membranı yararaq çıxır.
	#
	# Əvvəl membranın kənarında, bir neçə piksel ARALIDA
	# doğulurdu — top mikrobun yanında birdən peyda olurdu, sanki kənardan
	# atılmışdı. Halbuki oyunun qaydası budur ki, mikrob öz içindəki topu atır
	# (bax README, "Oyunun qaydası"), ona görə top orada da başlamalıdır.
	#
	# Görüntü qatı bunu pulsuz düzgün çəkir: toplar mikroblardan ƏVVƏLKİ
	# qatdadır ([method Arena._build_world]), yəni gövdənin içindəki top
	# görünmür və membrandan keçəndə üzə çıxır.
	#
	# Toqquşmaya təsiri yoxdur: [method _step_shots] atıcının özünü onsuz da
	# keçir, başqa mikroblar isə bir-birinin içinə girə bilmir ([method _separate_germs]).
	s.pos = g.pos
	s.dir = dir
	s.life = Const.SHOT_LIFETIME
	shots.append(s)

	g.balls -= 1
	g.cooldown = Const.FIRE_COOLDOWN
	# Geri təpmə: atəş həm də manevr vasitəsidir.
	g.vel -= dir * Const.SHOT_RECOIL
	# Atəş açan toxunulmazlığını itirir — doğuş qorunması hücum qalxanı deyil.
	g.safe_t = 0.0

	# Qığılcım topun doğulduğu yerdə YOX, membranı yardığı yerdə çıxır —
	# mərkəzdə çəkilsə gövdənin altında qalıb heç görünməzdi.
	events.append({
		"t": "fire",
		"pos": g.pos + dir * g.radius(),
		"arg": g.aim,
		"color": g.color,
	})


func _step_shots(dt: float) -> void:
	var survivors: Array[ShotState] = []

	for s in shots:
		s.life -= dt
		if s.life <= 0.0:
			_drop_food(s.pos, Vector2.ZERO, s.owner_id)
			continue

		var from := s.pos
		var to := s.pos + s.dir * Const.SHOT_SPEED * dt

		# Ən yaxın toqquşmanı tapırıq: maneə mikrobdan öndədirsə, top ona dəyir.
		var best := 2.0
		var victim: Sim.GermState = null
		var hit_obstacle := Vector4.ZERO
		var hit_index := -1

		# Kol və cərəyan deşiyi topu BURAXIR (bax [method DishMap.blocks_shot]).
		# Kolun içindən atəş açmaq mümkündür — gizlənən oyunçunun yeganə
		# üstünlüyü elə budur.
		#
		# Kəsişmə İLK hesablanır: top adətən heç bir maneəyə dəymir və iki
		# statik çağırış yalnız dəyən maneəyə qalır. Şərtlər yan təsirsizdir.
		for i in obstacles.size():
			var o := obstacles[i]
			var t := _seg_circle_t(from, to, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS)
			if not (t >= 0.0 and t < best):
				continue
			if DishMap.wall_gone(broken[i]) or not DishMap.blocks_shot(int(o.w)):
				continue
			best = t
			victim = null
			hit_obstacle = o
			hit_index = i

		var owner: GermState = germs.get(s.owner_id)
		for id in germs:
			var g: GermState = germs[id]
			if not g.alive or g.id == s.owner_id or g.safe_t > 0.0:
				continue
			# DOST ATƏŞİ YOXDUR — top yoldaşın içindən keçir.
			#
			# Top rəqibə +2 verir, yəni yoldaşa dəyməsi ona KÖMƏK deyil, zərərdir:
			# onu partlama həddinə yaxınlaşdırır. Komandalı rejimdə bu, oyunçunu
			# yoldaşından qaçmağa məcbur edərdi.
			if owner != null and owner.team >= 0 and g.team == owner.team:
				continue
			var t := _seg_circle_t(from, to, g.pos, g.radius() + Const.SHOT_RADIUS)
			if t >= 0.0 and t < best:
				best = t
				victim = g
				hit_index = -1

		if best <= 1.0:
			var hit_pos := from.lerp(to, best)
			if victim != null:
				# Sistləşmiş amöb müvəqqəti QABIQDIR: top içəri girmir, səkir.
				# Səkən top başqasına dəyə bilər — səni vuran öz topunu geri
				# ala bilər.
				if victim.in_cyst():
					var cn := (hit_pos - victim.pos).normalized()
					if _bounce(s, hit_pos, cn):
						survivors.append(s)
					continue
				_inject(victim, hit_pos, s)
				continue
			if hit_index >= 0:
				# Kövrək qabıq topu UDUR, sıçratmır (bax [method _crack]).
				if int(hit_obstacle.w) == DishMap.Kind.BRITTLE:
					_crack(hit_index, hit_pos, s)
					continue
				var n := (hit_pos - Vector2(hit_obstacle.x, hit_obstacle.y)).normalized()
				if _bounce(s, hit_pos, n):
					survivors.append(s)
				continue

		s.pos = to

		# Qabın şüşə kənarı.
		var limit := Const.WORLD_RADIUS - Const.SHOT_RADIUS
		if s.pos.length() > limit:
			var n := -s.pos.normalized()
			s.pos = -n * limit
			if not _bounce(s, s.pos, n):
				continue

		survivors.append(s)

	shots = survivors


## Topu səthdən sıçradır. Sıçrama haqqı bitibsə topu qidaya çevirir və
## [code]false[/code] qaytarır — çağıran onu siyahıdan çıxarmalıdır.
func _bounce(s: ShotState, at: Vector2, normal: Vector2) -> bool:
	s.bounces += 1
	if s.bounces > Const.SHOT_BOUNCES:
		_drop_food(at, Vector2.ZERO, s.owner_id)
		return false
	s.pos = at + normal * 0.5
	s.dir = s.dir.bounce(normal).normalized()
	events.append({"t": "hit", "pos": at, "arg": 0.0, "color": s.color})
	return true


## Kövrək qabığa zərbə. Canı bitəndə qabıq DAĞILIR və yol açılır.
##
## Top SIÇRAMIR — qabığı yarır və içində qalıb qidaya çevrilir. Sıçrasaydı,
## divar sındırmaq üçün atılan top geri qayıdıb atanın özünü vurardı: qapı
## açmaq özünə zərbə olmazdı. Qida isə maddənin itmədiyini saxlayır — oyunun
## bütün qalan hissəsində olduğu kimi.
##
## Dağılan qabıq BƏRPA OLUNMUR: dünya oyun getdikcə açılır və bu, qəsdəndir.
## Bərpa olunsaydı, sındırmağa sərf olunan üç top boşa gedərdi.
func _crack(i: int, at: Vector2, s: ShotState) -> void:
	# Qığılcım adi sıçrayış kimi yazılır (`arg` = 0): client burada mikrob
	# axtarmamalıdır, çünki vurulan mikrob yoxdur (bax [method Arena._on_impact]).
	events.append({"t": "hit", "pos": at, "arg": 0.0, "color": s.color})
	if brittle_hp[i] > 0:
		brittle_hp[i] -= 1
	# Zədə sayı BAYTA yazılır ki, client onu görsün və qabığın şəklini
	# dəyişsin (bax [enum DishMap.Wall]). Ayrıca sahə göndərilmir.
	var hits := DishMap.BRITTLE_HP - brittle_hp[i]
	broken[i] = (hits << DishMap.Wall.HITS_SHIFT) & DishMap.Wall.HITS_MASK
	if brittle_hp[i] == 0:
		broken[i] |= DishMap.Wall.GONE
		var o := obstacles[i]
		events.append({"t": "break", "pos": Vector2(o.x, o.y),
			"arg": o.z, "color": s.color})
	_drop_food(at, Vector2.ZERO, s.owner_id)


## Top rəqibin içinə keçdi və bölündü. Tutumu aşdısa rəqib partlayır —
## oyunun əsas qaydası. Niyə bir yox, [constant Const.SHOT_PAYLOAD] top:
## atəş dövrü ilə boşalma sürəti eyni olduğuna görə hücumun xalis üstünlüyü
## olmalıdır, əks halda dolu rəqib sadəcə atəş açaraq sonsuza qədər sağ qalır.
func _inject(victim: GermState, at: Vector2, s: ShotState) -> void:
	victim.balls += Const.SHOT_PAYLOAD
	events.append({"t": "hit", "pos": at, "arg": 1.0, "color": s.color})
	# Super hücum edəni mükafatlandırır — Brawl Stars-dakı məntiq. Dəyən
	# tərəf də bir az alır: üç superdən ikisi qaçış vasitəsidir və məhz
	# sıxılan oyunçuya lazım olur.
	_charge(germs.get(s.owner_id), Const.SUPER_ON_HIT)
	_charge(victim, Const.SUPER_ON_TAKEN)
	if victim.balls > victim.capacity:
		_burst(victim, s.owner_id)


## Mikrob partladı. İçindəki toplar qida kimi ətrafa səpilir —
## dünyada maddə itmir, partlatmanın mükafatı elə həmin topların özüdür.
func _burst(g: GermState, killer_id: int) -> void:
	if not g.alive:
		return
	g.alive = false
	events.append({"t": "burst", "pos": g.pos, "arg": g.radius(), "color": g.color})

	var scatter := clampi(g.balls, 3, 24)
	for i in scatter:
		var a := TAU * float(i) / float(scatter) + rng.randf() * 0.6
		var dir := Vector2.from_angle(a)
		_drop_food(g.pos + dir * (g.radius() * 0.4), dir * rng.randf_range(90.0, 240.0), 0)

	var killer: GermState = germs.get(killer_id)
	if killer != null and killer.id != g.id and killer.alive:
		killer.pops += 1
		killer.capacity = mini(killer.capacity + Const.CAPACITY_STEP, Const.MAX_CAPACITY)
		# Partlatma onsuz da +5 tutum verir; superin də açılması həmin anı
		# oyunun ən böyük anına çevirir.
		killer.charge = Const.SUPER_MAX

	# Ad, rəng, növ və komanda da yazılır: CÜT-də ölüm müvəqqətidir və mikrob
	# eyni kimliklə qayıdır (bax [method World._step_revive]). Bunlar yalnız
	# serverdə qalır — şəbəkəyə getmir.
	burst_log.append({
		"id": g.id,
		"killer": killer_id,
		"killer_name": killer.name if killer != null else "",
		"pops": g.pops,
		"cap": g.capacity,
		"age": g.age,
		"name": g.name,
		"color": g.color,
		"species": int(g.species),
		"team": g.team,
	})


func _reap() -> void:
	for entry in burst_log:
		remove_germ(int(entry["id"]))


# ---------------------------------------------------------------- qida

func _drop_food(at: Vector2, vel: Vector2, lock_id: int) -> void:
	var f := FoodState.new()
	f.id = _next_food_id
	_next_food_id += 1
	f.pos = at
	f.vel = vel
	f.lock_id = lock_id
	f.lock_t = Const.FOOD_ARM_TIME if lock_id != 0 else 0.0
	food.append(f)


func _step_food(dt: float) -> void:
	var damp := 1.0 / (1.0 + Const.FOOD_FRICTION * dt)
	var survivors: Array[FoodState] = []

	# Mikrobların siyahısı qida döngüsündən ƏVVƏL bir dəfə yığılır.
	#
	# Bu döngü tick-in ən ağır yeridir (qida × mikrob): hər cüt üçün Dictionary
	# axtarışı, `in_net()`, `radius()` və `pow` çağırılırdı. Mövqe, `alive` və
	# `in_net()` bu funksiyanın içində DƏYİŞMİR. Dəyişən iki şeydir — top sayı
	# (canlı oxunur) və spordan sonra tutum, yəni radius (həmin mikrobun həddi
	# yenidən hesablanır). Sıra `germs`-in sırasıdır, yəni nəticə eynidir.
	var nets: Array[GermState] = []
	var eaters: Array[GermState] = []
	var eat_pos := PackedVector2Array()
	var reach_food := PackedFloat64Array()
	var reach_spore := PackedFloat64Array()
	for id in germs:
		var g: GermState = germs[id]
		if not g.alive:
			continue
		if g.in_net():
			nets.append(g)
		eaters.append(g)
		eat_pos.append(g.pos)
		reach_food.append(pow(g.radius() + Const.FOOD_RADIUS, 2.0))
		reach_spore.append(pow(g.radius() + Const.SPORE_RADIUS, 2.0))
	var n_eaters := eaters.size()
	var limit := Const.WORLD_RADIUS - Const.FOOD_RADIUS

	for f in food:
		# Qidanın çoxu kilidsiz və SAKİTDİR (öz sürəti yoxdur) — onlar üçün boş
		# iş görülmür: sıfır kilid `maxf`-dən yenə sıfır çıxırdı, sıfır sürət də
		# dəyişmirdi.
		if f.lock_t > 0.0:
			f.lock_t = maxf(0.0, f.lock_t - dt)

		# Sürət və mövqe bir dəfə oxunur, sonda yazılır — əməliyyatlar və
		# onların sırası eynidir, sadəcə sahəyə hər dəfə müraciət olunmur.
		var v := f.vel
		var at := f.pos

		# Sərbəst top suda asılıdır: öz sürəti sönür, amma su onu heç vaxt
		# buraxmır — sakit qida da axınla birlikdə sürüşür. Ekranda 50-dən çox
		# qida topu var və hamısının eyni burulğanda süzülməsi "bu, mayedir"
		# mesajını hər şeydən yaxşı verir.
		if v != Vector2.ZERO:
			if v.length_squared() > 1.0:
				v *= damp
			else:
				v = Vector2.ZERO

		var flow := Const.current_at(at)
		if v != Vector2.ZERO or flow != Vector2.ZERO:
			at += (v + flow) * dt
			if at.length() > limit:
				var n := at.normalized()
				at = n * limit
				v = v.bounce(-n) * 0.5
		f.vel = v

		# Aksopodiya toru: açıq torun zolağındakı qida ona doğru axır.
		#
		# Kinetosistlər — şüaların üzərindəki qranullar — yem toxunan kimi
		# partlayıb onu şüaya yapışdırır. Heliozoa məhz belə yeyir: qovmadan,
		# gözləyərək.
		for h in nets:
			var pull_r := h.radius() * Const.NET_RADIUS
			var to_h := h.pos - at
			var pd := to_h.length()
			if pd > pull_r or pd < 0.001:
				continue
			at += (to_h / pd) * Const.NET_PULL * dt
			break
		f.pos = at

		var eaten := false
		var spore := f.id < 0
		for i in n_eaters:
			# Spor iri olduğuna görə udma məsafəsi də böyükdür — gözlə görünən
			# ölçü ilə oyun qaydası uyğun olmalıdır.
			#
			# Məsafə İLK yoxlanılır: qidanın çoxu hər mikrobdan uzaqdadır, qalan
			# şərtlər isə yan təsirsizdir — sıraları nəticəni dəyişmir.
			if at.distance_squared_to(eat_pos[i]) > (reach_spore[i] if spore else reach_food[i]):
				continue
			var g := eaters[i]
			if g.balls >= g.capacity:
				continue
			if f.lock_id == g.id and f.lock_t > 0.0:
				continue
			g.balls += 1
			if spore:
				# SPOR — tutum artır. Partlatma ilə EYNİ mükafat, başqa yolla.
				g.capacity = mini(g.capacity + Const.SPORE_CAPACITY, Const.MAX_CAPACITY)
				# Radius tutumdan gəlir — bu mikrobun udma həddi də yenilənir.
				reach_food[i] = pow(g.radius() + Const.FOOD_RADIUS, 2.0)
				reach_spore[i] = pow(g.radius() + Const.SPORE_RADIUS, 2.0)
				events.append({"t": "spore", "pos": f.pos, "arg": 0.0, "color": g.color})
			# Dinc oyunçu da super doldurur, sadəcə yavaş — kimsə tapmadan da
			# irəliləyiş var.
			g.food_acc += 1
			if g.food_acc >= Const.SUPER_FOOD_PER:
				g.food_acc = 0
				_charge(g, 1)
			events.append({"t": "absorb", "pos": f.pos, "arg": 0.0, "color": g.color})
			eaten = true
			break

		if not eaten:
			survivors.append(f)

	food = survivors


## Spor — iri qida yığını, yeyənə TUTUM verir.
##
## Brawl Stars-ın güc kubunun qarşılığı. Bizdə artan şey tutumdur — onsuz da
## partlatmanın mükafatı odur, yəni iki yol bir mükafata aparır və oyunçu
## döyüşməyi seçə də bilər, yığmağı da.
##
## Yaş radiusun İÇİNDƏ, mərkəzdən aralı doğulur: quru zonada doğulan spor
## oyunçunu ölümə çəkərdi, mərkəzdəki isə heç bir seçim tələb etməzdi.
func _drop_spore() -> void:
	var a := rng.randf() * TAU
	var d := dish_radius * rng.randf_range(0.40, 0.85)
	var f := FoodState.new()
	f.id = -_next_food_id
	_next_food_id += 1
	f.pos = Vector2.from_angle(a) * d
	food.append(f)


## Sporların sayını saxlayır (yalnız [constant Const.Mode.SOLO]-da işlədilir).
func keep_spores(dt: float) -> void:
	var have := 0
	for f in food:
		if f.id < 0:
			have += 1
	if have >= Const.SPORE_COUNT:
		_spore_timer = Const.SPORE_RESPAWN
		return
	_spore_timer -= dt
	if _spore_timer > 0.0:
		return
	_spore_timer = Const.SPORE_RESPAWN
	_drop_spore()


## Quru zonada qalan qida QURUYUR.
##
## Qab daralanda qida onunla daralmır: doğuş hədəfi sabitdir, üstəlik hər
## partlayan mikrob öz toplarını qida kimi yerə tökür. Ölçülüb — matçın
## sonunda 90 px-lik qabda 293 qida yığılmışdı (hədəf 110-dur). Nəticədə son
## iki mikrob heç vaxt acmırdı, heç vaxt hücum etmirdi və matç BEŞ dəfədən
## BEŞİNDƏ döyüşlə yox, vaxt limiti ilə bitirdi.
##
## Quru zonanın mənası da elə budur: orada TOP var, QİDA yoxdur.
func _dry_food() -> void:
	if dish_radius >= Const.WORLD_RADIUS:
		return
	# Sondan gedirik ki, silmək qalan indeksləri sürüşdürməsin.
	var i := food.size() - 1
	while i >= 0:
		if food[i].pos.length() > dish_radius:
			food.remove_at(i)
		i -= 1


## Hədəf qida sayı — qabın ölçüsünə görə.
##
## Sabit say olsaydı, qab daralanda sıxlıq partlayardı. Sahə ilə (r²) deyil,
## RADİUSLA (r) miqyaslanır: sahə ilə olsa, 250 px-lik qabda cəmi 5 qida
## qalardı və matçın sonu döyüş yox, aclıq yarışına çevrilərdi.
func _food_target() -> int:
	var k := dish_radius / Const.WORLD_RADIUS
	return maxi(int(round(float(Const.FOOD_TARGET) * k)), Const.FOOD_MIN)


func _spawn_food(dt: float) -> void:
	var target := _food_target()
	if food.size() >= target:
		_food_budget = 0.0
		return
	_food_budget += Const.FOOD_SPAWN_RATE * dt
	while _food_budget >= 1.0 and food.size() < target:
		_food_budget -= 1.0
		_drop_food(find_spawn(Const.FOOD_RADIUS), Vector2.ZERO, 0)


# ---------------------------------------------------------------- həndəsə

## İki nöqtə arasında maneəsiz atəş xətti varmı?
## Bot hədəf seçərkən istifadə olunur.
##
## Kəsişmə növdən və dağılmadan ƏVVƏL yoxlanılır — xətt adətən maneələrin
## çoxuna toxunmur. Hər üç şərt yan təsirsizdir, cavab eynidir.
func has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	for i in obstacles.size():
		var o := obstacles[i]
		if not (_seg_circle_t(a, b, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS) >= 0.0):
			continue
		if DishMap.wall_gone(broken[i]) or not DishMap.blocks_sight(int(o.w)):
			continue
		return false
	return true


## Mikrob hansı kolun içindədir? Kolun indeksi, yoxdursa -1.
##
## ── Gizlənmə qaydası ────────────────────────────────────────────────────
## Kolun içindəki mikrobu YALNIZ eyni kolun içindəki görür. "Yaxınlıq"
## ölçüsü işlədilmir: sərhəddə duran iki oyunçu üçün nəticə kadr-kadr
## dəyişər və mikrob yanıb-sönərdi. Kol indeksi isə kəskin cavabdır.
##
## Mərkəz əsas götürülür, örtüşmə yox — oyunçu "içindəyəmmi" sualına baxıb
## cavab verə bilməlidir, örtüşmə isə gözlə ölçülmür.
##
## BÖYÜK mikrob kiçik kola sığmır (`o.z < g.radius()`). Bu, oyunun öz
## qaydasının davamıdır: böyümənin qiyməti var — iri hədəf, yavaş hərəkət,
## tez acma, və indi bir də GİZLƏNƏ BİLMƏMƏK. Lider kolda oturub oyunu
## dondura bilməz.
func bush_of(g: GermState) -> int:
	# Hər tick hər mikrob üçün çağırılır (bax [method World._build_frame]).
	# Növ İLK yoxlanılır — maneələrin çoxu kol deyil və statik çağırışa
	# ehtiyac qalmır. Şərtlər yan təsirsizdir, tapılan ilk kol eynidir.
	var r := g.radius()
	for i in obstacles.size():
		var o := obstacles[i]
		if int(o.w) != DishMap.Kind.BUSH or o.z < r:
			continue
		if DishMap.wall_gone(broken[i]):
			continue
		if g.pos.distance_squared_to(Vector2(o.x, o.y)) <= o.z * o.z:
			return i
	return -1


## Parça-dairə kəsişməsi. Kəsişmə anını [0,1] qaytarır, yoxdursa -1.
static func _seg_circle_t(a: Vector2, b: Vector2, c: Vector2, radius: float) -> float:
	var d := b - a
	var f := a - c
	var aa := d.dot(d)
	if aa < 0.000001:
		return 0.0 if f.length_squared() <= radius * radius else -1.0
	var bb := 2.0 * f.dot(d)
	var cc := f.dot(f) - radius * radius
	var disc := bb * bb - 4.0 * aa * cc
	if disc < 0.0:
		return -1.0
	disc = sqrt(disc)
	var t1 := (-bb - disc) / (2.0 * aa)
	if t1 >= 0.0 and t1 <= 1.0:
		return t1
	var t2 := (-bb + disc) / (2.0 * aa)
	if t2 >= 0.0 and t2 <= 1.0:
		return t2
	return -1.0
