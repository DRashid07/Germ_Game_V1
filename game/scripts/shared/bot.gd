class_name Bot
extends RefCounted
## Bot mikrob — dünyanı canlı saxlayır.
##
## io tipli oyunda boş dünya ölü dünyadır: ilk oyunçu qoşulanda ortada tək
## qalmamalıdır. Ona görə botlar SERVERDƏ işləyir və dünyanın əhalisini
## [constant Const.MIN_POPULATION] səviyyəsində saxlayır.
##
## Bot heç bir imtiyaza malik deyil — insan oyunçu ilə eyni [Sim.PlayerInput]
## strukturunu doldurur və eyni məhdudiyyətlərə tabedir.

## Adlar OYUNDAKI OBYEKTLƏRİN adları ilə üst-üstə düşməməlidir.
##
## Siyahıda "Spor" vardı, meydanda isə həqiqi Spor pikapı gəzir (TƏK QALAN və
## CÜT rejimlərində) — liderlər cədvəlindəki "Spor" ilə yerdəki spor eyni söz
## idi və nəticə ekranı "Səni partladan: Spor" yazanda cümlə iki cür oxunurdu.
## Yerinə "Sitoz" qoyulub.
const BOT_NAMES := [
	"Amöb", "Koks", "Basil", "Spiral", "Vibrio", "Sitoz", "Nüvə", "Plazma",
	"Toksin", "Mikoz", "Virion", "Koloniya", "Flagel", "Zülal", "Bakter",
]

## Botun saxlamağa çalışdığı döyüş məsafəsi (obyekt rejimlərinin planları və super üçün).
const IDEAL_RANGE := 380.0
## Növün öz döyüş məsafəsi — atəşinin formasından: kirpikli uzaqdan vurur (oxu ~900 px
## uçur), ayaqlı yaxınlaşır (iynələr 350 px uçur və yelpik kimi açılır — iki iynənin də
## çatması üçün yaxın olmalıdır), amöb damcının orta məsafəsindədir.
const SPECIES_RANGE: Array[float] = [470.0, 190.0, 320.0]
## Bu məsafədən uzaq rəqib bota maraqlı deyil.
## Ac bot quru zonada bu qədər piksel dərinliyə qədər qala bilər.
##
## Sıfır olsaydı, bot kənara heç toxunmazdı və oyunçu quru zonanın yem
## olduğunu heç vaxt görməzdi — mexanika yalnız sənəddə qalardı.
const DRY_TOLERANCE := 140.0

## Maneə yoxlaması gövdədən bu qədər irəlidə aparılır.
const PROBE_AHEAD := 34.0
const AGGRO_RANGE := 720.0
## Nişan səhvi (radian) — bot mükəmməl atıcı olmamalıdır.
const AIM_ERROR := 0.09

var id: int
var difficulty := 1.0       ## 0.5 asan, 1.0 normal, 1.5 çətin

var _seq := 0
var _strafe := 1.0
var _switch_timer := 0.0
var _rng := RandomNumberGenerator.new()


## [param p_seed] mənfi deyilsə botun qərarları təkrarlana biləndir: [World] onu
## öz [member Sim.rng]-indən verir, yəni dünyanın bir toxumu bütün botları da
## sabitləyir (testlər və balans ölçüsü bunu işlədir).
func _init(p_id: int, p_difficulty := 1.0, p_seed := -1) -> void:
	id = p_id
	difficulty = p_difficulty
	if p_seed >= 0:
		_rng.seed = p_seed
	else:
		_rng.randomize()


static func random_name(index: int) -> String:
	return BOT_NAMES[index % BOT_NAMES.size()]


func think(sim: Sim, dt: float) -> Sim.PlayerInput:
	_seq += 1
	_lob_range = NAN
	var me: Sim.GermState = sim.germs.get(id)
	if me == null or not me.alive:
		return Sim.PlayerInput.make(_seq, Vector2.ZERO, 0.0, false)

	_switch_timer -= dt
	if _switch_timer <= 0.0:
		_switch_timer = _rng.randf_range(0.6, 1.6)
		_strafe = [-1.0, 1.0, 1.0, -1.0, 0.0][_rng.randi() % 5]

	var target := _nearest_enemy(sim, me)
	var meal := _nearest_food(sim, me)

	# Doluluq botun bütün qərarlarını idarə edir:
	#   • aşağıdırsa yemək axtarır (yoxsa acından partlayacaq)
	#   • yuxarıdırsa rəqibdən qaçır (bir dəymə ilə partlaya bilər)
	var fill := me.fill()
	var hungry := me.balls < Const.FIRE_MIN_BALLS + 1 or fill < 0.45
	# Bir dəymə iki top gətirir, ona görə "təhlükəli zona" tutumdan xeyli aşağıdır.
	var bloated := fill > 0.70

	var move := Vector2.ZERO
	var aim := me.aim
	var fire := false

	# QURU ZONA hər şeydən üstündür.
	#
	# Quru zonada top ARTIR (bax [method Sim._step_germs]) — yəni kənar ac bot
	# üçün YEMDİR, dolu bot üçün ÖLÜMDÜR. Bot da oyunçu ilə eyni qərarı verir:
	# acdırsa bir az qalır, doludursa dərhal qaçır.
	#
	# Bu yoxlama olmasaydı, TƏK QALAN-da botların hamısı daralan qabın çölündə
	# qalıb bir-bir partlayardı və insan oyunçu heç nə etmədən udardı. Rejimin
	# bütün gərginliyi buradan asılıdır.
	#
	# Sərhəd radiusun 92%-idir, tam kənarı yox: tam kənarda dönsəydi, bot orada
	# titrəyərdi — bir kadr içəri, bir kadr çölə.
	# Yaş sahənin mərkəzi YAŞ ADA-da gəzən adadır, qalan rejimlərdə qabın mərkəzi.
	var out_by := me.pos.distance_to(sim.wet_center) - sim.dish_radius * 0.92

	# Tolerans QABLA birlikdə kiçilir.
	#
	# Mütləq ədəd olsaydı, 1200 px-lik qabda düzgün, 90 px-lik qabda isə absurd
	# olardı: bot qabın 2.5 misli uzağında dayanıb "bir az kənardayam" sayardı.
	# Ölçülüb — matçın sonunda iki bot 165 və 225 px-də dayanırdı, yəni
	# bir-birindən o qədər uzaq idi ki, heç görmürdülər və matç döyüşlə yox,
	# vaxt limiti ilə bitirdi.
	var tolerance := minf(DRY_TOLERANCE, sim.dish_radius * 0.25)
	var must_flee := out_by > 0.0 and (bloated or out_by > tolerance)

	# Ac bot adətən döyüşdən yayınır — bir dəymə onu partlada bilər. Amma rəqib
	# qidadan YAXINDIRSA, qaçmağın mənası yoxdur: rəqib onu qidaya çatana qədər
	# vurar, üstəlik gözləmək aclıqla onsuz da öldürür.
	#
	# Bu şərt olmasaydı, matçın sonu ilişirdi: qab daraldıqca qida azalır, hər
	# iki mikrob daimi ac olur və heç biri atəş açmır. Ölçülüb — beş matçın
	# BEŞİ döyüşlə yox, 240 saniyəlik vaxt limiti ilə bitirdi.
	var enemy_d := target.pos.distance_to(me.pos) if target != null else INF
	var food_d := meal.pos.distance_to(me.pos) if meal != null else INF
	var can_fight := not hungry or enemy_d < food_d

	if must_flee:
		var inward := (sim.wet_center - me.pos).normalized()
		move = inward
		aim = inward.angle()
		# Qaçarkən də boşalır: dolu olduğu üçün qaçır, top atmaq onu xilas edir.
		fire = bloated and me.balls > Const.FIRE_MIN_BALLS

	elif Const.is_objective_mode(sim.mode) \
			and _objective(sim, me, target, meal, hungry, bloated, can_fight):
		move = _o_move
		aim = _o_aim
		fire = _o_fire

	elif target != null and target.pos.distance_to(me.pos) < AGGRO_RANGE and can_fight:
		var to_target := target.pos - me.pos
		var dist := to_target.length()
		var forward := to_target.normalized()
		var side := Vector2(-forward.y, forward.x) * _strafe

		# Dolu botun məsafəsi daha uzaqdır — rəqibin bir topu onu partlada bilər.
		var want := SPECIES_RANGE[int(me.species)] * (1.6 if bloated else 1.0) \
			* (Const.MUT_LONG_RANGE if Const.has_mut(me.mutations, Const.Mut.LONG) else 1.0)
		var radial := signf(dist - want)
		move = (forward * radial * 0.9 + side * 0.7).limit_length(1.0)

		aim = _aim_at(me, target)
		# Yalnız açıq xətt olanda atır — maneəyə atmağın mənası yoxdur. Amöbün damcısı
		# isə örtüyün ÜSTÜNDƏN keçir: ona xətt yox, məsafə və görünən hədəf lazımdır.
		# Özünü acdan qorumaq üçün ehtiyat saxlayır.
		fire = me.balls > Const.FIRE_MIN_BALLS and _can_hit(sim, me, target, dist)
	elif hungry and not sim.colonies.is_empty() and _pick_colony(sim, me, meal, dt):
		# Ac bot qida mənbəyinə gedir; sahəsinə çatanda oradakı qida ən yaxın olur və
		# aşağıdakı adi "qidaya get" yolu işləyir.
		var to_c := _colony_goal - me.pos
		move = to_c.normalized()
		aim = to_c.angle()
	elif meal != null:
		var to_food := meal.pos - me.pos
		move = to_food.normalized()
		aim = to_food.angle()
		# Dolu botun tək çarəsi top atmaqdır: atəş həm də boşalma üsuludur.
		fire = bloated and me.balls > Const.FIRE_MIN_BALLS
	else:
		# Qida da, rəqib də yoxdur — mərkəzə doğru gəzir.
		var wander := (sim.wet_center - me.pos).normalized().rotated(_rng.randf_range(-0.8, 0.8))
		move = wander
		aim = wander.angle()

	# Amöbün miniqanı: top pulsuzdur, ehtiyat saxlamağa ehtiyac yoxdur — hədəf
	# açıq xətdədirsə, hər dövrdə atır (aclıq da, qida da onu yayındırmır).
	if me.in_cyst() and target != null and sim.has_line_of_sight(me.pos, target.pos):
		aim = _aim_at(me, target)
		fire = true

	move = _avoid(sim, me, move)

	var use_super := me.super_ready() and _wants_super(sim, me, target, meal, hungry)
	var inp := Sim.PlayerInput.make(_seq, move, aim, fire, use_super)
	# Damcının məsafəsi — nişan alınan nöqtəyə qədər (bax [method _aim_at]); hədəfsiz
	# atəşdə NAN qalır və server sabit məsafə götürür ([constant Const.LOB_AUTO]).
	if fire and me.species == Const.Species.AMOEBA:
		inp.fire_range = _lob_range
	return inp


## Damcının bu atəşdəki məsafəsi; NAN = sabit məsafə.
var _lob_range := NAN


## Botun mutasiya seçimi (eksperimental profil, design/MODES.md §19): növünün oyun tərzinə
## uyğun ilk seçilməmiş mutasiya. Seçim [method World.choose_mutation]-dan — insanınkı ilə
## eyni yoxlamadan — keçir, yəni bot vaxtından əvvəl və ya ikidən çox seçə bilmir.
## Kirpikli uzaqdan vurur (çıxıntı, sonra qamçı); ayaqlı yavaşdır və axın onu aparır
## (yapışqan ayaqlar); amöbün damcısı məsafə sevir (çıxıntı, sonra ayaqlar).
const MUT_PLAN := [
	[Const.Mut.LONG, Const.Mut.WHIP, Const.Mut.STICKY],
	[Const.Mut.STICKY, Const.Mut.WHIP, Const.Mut.LONG],
	[Const.Mut.LONG, Const.Mut.STICKY, Const.Mut.WHIP],
]


static func pick_mutation(g: Sim.GermState) -> int:
	for m in MUT_PLAN[int(g.species)]:
		if not Const.has_mut(g.mutations, m):
			return m
	return -1


# ---------------------------------------------------------------- qida koloniyaları

## Ən yaxın qida bundan yaxındırsa mənbə axtarılmır — əvvəl onu ye.
const COLONY_NEAR_MEAL := 200.0
## Sahəsinə çatıb qida tapmadığı koloniyanı bot bu qədər saniyə saymır.
const COLONY_SKIP := 8.0
## Koloniyanın yanında görünən rəqib onu bu qədər "uzaqlaşdırır" (px).
const COLONY_THREAT := 300.0
## Rəqib koloniyadan bu qədər yaxındırsa təhlükə sayılır.
const COLONY_THREAT_R := 320.0
## Koloniyadakı hər qida (ən çox 12) onu bu qədər "yaxınlaşdırır" (px).
const COLONY_FOOD_PULL := 14.0
## Seçilmiş koloniyaya bağlılıq — hər tick fikir dəyişməsin.
const COLONY_STICK := 120.0

## Seçilmiş koloniyanın mərkəzi ([method _pick_colony]-in cavabı).
var _colony_goal := Vector2.INF
var _colony_pick := -1
## Koloniyanın id-si → onu saymamağa qalan vaxt.
var _colony_skip := {}


## Ac bot qida mənbəyini seçir (yalnız SONSUZ ARENA): səpələnmiş qida, yoxsa koloniya.
##
## Koloniyanın dəyəri məsafədir, sahəsindəki qida və ehtiyatı onu yaxınlaşdırır, yanında
## GÖRÜNƏN rəqib uzaqlaşdırır. Yaxında qida varsa və ya səpələnmiş qida daha "ucuzdursa"
## koloniya seçilmir. Tükənmiş və sahəsi boş koloniya heç seçilmir — bot orada gözləmir.
## Sahəsinə çatıb qida tapmayan bot (qida axınla getmiş, çıxış dolu) onu
## [constant COLONY_SKIP] saniyə saymır və başqa mənbəyə keçir.
## Rəqib yalnız botun GÖRDÜYÜ kimidir: görüş sahəsindən kənardakı və başqa koldakı sayılmır.
func _pick_colony(sim: Sim, me: Sim.GermState, meal: Sim.FoodState, dt: float) -> bool:
	for cid in _colony_skip.keys():
		_colony_skip[cid] = float(_colony_skip[cid]) - dt
		if float(_colony_skip[cid]) <= 0.0:
			_colony_skip.erase(cid)
	var meal_d := meal.pos.distance_to(me.pos) if meal != null else INF
	if meal_d < COLONY_NEAR_MEAL:
		return false
	var seen_r := Const.aoi_radius(me.capacity)
	var best: Sim.ColonyState = null
	var best_cost := INF
	for c in sim.colonies:
		if _colony_skip.has(c.id):
			continue
		var producing := c.stock > 0 and c.out < Const.COLONY_OUT_MAX
		var there := c.near + (c.stock if producing else 0)
		if there <= 0:
			continue
		var d := me.pos.distance_to(c.pos)
		if d < Const.COLONY_SPREAD + 40.0 and c.near == 0 and not producing:
			_colony_skip[c.id] = COLONY_SKIP
			continue
		var cost := d - COLONY_FOOD_PULL * float(mini(there, 12)) \
			+ COLONY_THREAT * float(_colony_threats(sim, me, c.pos, seen_r))
		if c.id == _colony_pick:
			cost -= COLONY_STICK
		if cost < best_cost:
			best_cost = cost
			best = c
	if best == null or best_cost > meal_d:
		_colony_pick = -1
		return false
	_colony_pick = best.id
	_colony_goal = best.pos
	return true


## Koloniyanın yanında botun gördüyü rəqiblərin sayı.
static func _colony_threats(sim: Sim, me: Sim.GermState, at: Vector2, seen_r: float) -> int:
	var my_bush := sim.bush_of(me)
	var n := 0
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.id == me.id or not g.alive:
			continue
		if me.team >= 0 and g.team == me.team:
			continue
		if g.pos.distance_to(at) > COLONY_THREAT_R or g.pos.distance_to(me.pos) > seen_r:
			continue
		var bush := sim.bush_of(g)
		if bush >= 0 and bush != my_bush:
			continue
		n += 1
	return n


## Bu hədəfə adi atəş çatarmı.
##
## Düz atəş (ox, iynə) açıq xətt və profilin uçuş məsafəsi istəyir. Damcı xətt istəmir —
## maneənin üstündən keçir — amma KOLDA gizlənəni hədəf almır: server onu bota
## göstərməsə də bot simulyasiyanın özündən oxuyur, ona görə gizlənmə qaydası burada da
## saxlanılır (bax [method Sim.bush_of]). Düşmə nöqtəsi etibarsızdırsa atmır.
func _can_hit(sim: Sim, me: Sim.GermState, target: Sim.GermState, dist: float) -> bool:
	var profile := Const.shot_profile(int(me.species), me.in_cyst())
	if profile != Const.Shot.LOB:
		return dist < Const.shot_reach(profile, me.mutations) * 0.9 \
			and sim.has_line_of_sight(me.pos, target.pos)
	if dist > Const.lob_max(me.mutations) + Const.LOB_AREA or dist < Const.LOB_MIN - Const.LOB_AREA:
		return false
	var hide := sim.bush_of(target)
	if hide >= 0 and hide != sim.bush_of(me):
		return false
	return sim.lob_valid(Sim.lob_landing(me.pos, Vector2.from_angle(_aim_at_angle), _lob_range))


## Maneədən yan keçir.
##
## Bot maneəni yalnız ATƏŞ üçün nəzərə alırdı (bax [method Sim.has_line_of_sight]),
## HƏRƏKƏT üçün yox. Açıq qabda bu az bilinirdi, çünki yer çox idi. Amma quru
## zona hamını mərkəzə sıxanda botlar maneəyə dirənib DONURDU: ölçülüb —
## matçın son 60 saniyəsində üç bot 177, 177 və 154 px-də tərpənmədən qalmışdı,
## bir-birini görmürdü və matç döyüşlə yox, vaxt limiti ilə bitirdi.
##
## Düz geri dönmək kifayət etmir: bot maneə ilə hədəf arasında irəli-geri
## titrəyərdi. Ona görə TƏNGƏNS boyunca sürüşür — maneəni dolanır.
static func _avoid(sim: Sim, me: Sim.GermState, move: Vector2) -> Vector2:
	if move == Vector2.ZERO:
		return move
	# Radius tutumdan gəlir və bu funksiyada dəyişmir — maneə başına yenidən
	# hesablanmır. Ucuz məsafə yoxlaması dağılma yoxlamasından ƏVVƏL gedir:
	# ikisi də yan təsirsizdir, yəni tapılan ilk maneə eynidir.
	var rad := me.radius()
	var probe := me.pos + move * (rad + PROBE_AHEAD)
	var obstacles := sim.obstacles
	for i in obstacles.size():
		var o := obstacles[i]
		var c := Vector2(o.x, o.y)
		var r := o.z + rad
		if probe.distance_squared_to(c) > r * r:
			continue
		if DishMap.wall_gone(sim.broken[i]):
			continue
		var away := (me.pos - c).normalized()
		var tangent := Vector2(-away.y, away.x)
		if tangent.dot(move) < 0.0:
			tangent = -tangent
		return (tangent * 0.85 + away * 0.35).normalized()
	return move


## Bot superi nə vaxt işlədir.
##
## Botun superi olmasaydı, dünyanın yarısı superini heç vaxt göstərməzdi:
## əhalinin çoxu botdur ([constant Const.MIN_POPULATION]) və insan oyunçu
## rəqibin superini görmədən onun nə olduğunu öyrənə bilməzdi.
##
## Qaydalar QƏSDƏN sadədir — bot mükəmməl oynamamalıdır. Hər növ superini
## öz TƏYİNATINA görə işlədir, amma anı həmişə düzgün seçmir:
##   • kirpikli — üstünə top gələndə (qaçış)
##   • ayaqlı   — yeri boş, yaxınlıqda qida var (yığım). Dolu ikən İŞLƏTMİR:
##     tor onu öz tutumundan keçirib partlada bilər
##   • amöb     — rəqib atəş məsafəsində və açıq xətdədir (miniqan hücumdur,
##     qalxan deyil — ac ikən rəqibin yanında donmaq onu ölümə aparar)
static func _wants_super(sim: Sim, me: Sim.GermState, target: Sim.GermState,
		meal: Sim.FoodState, _hungry: bool) -> bool:
	match me.species:
		Const.Species.CILIATE:
			# Trixosist top xərcləyir — acıqkən qaçış özü ölümə apara bilər.
			if me.balls <= Const.MIN_BALLS + Const.TRICHO_COST:
				return false
			var reach := me.radius() * Const.TRICHO_RADIUS
			for shot in sim.shots:
				if shot.owner_id == me.id:
					continue
				# İnsanın topunu trixosist `rewind` GEC tutur (bax [member Sim._blasts]) —
				# bot da insan qurban kimi topu o qədər qabaqda görür.
				# Damcı havadadır — trixosist ona çatmır.
				if shot.is_lob():
					continue
				var ahead := shot.pos + shot.dir * (shot.speed * shot.rewind * Const.TICK_DELTA)
				if ahead.distance_to(me.pos) < reach:
					return true
			return false
		Const.Species.HELIOZOAN:
			if me.fill() > 0.55 or meal == null:
				return false
			return meal.pos.distance_to(me.pos) < me.radius() * Const.NET_RADIUS
		Const.Species.AMOEBA:
			if target == null:
				return false
			return target.pos.distance_to(me.pos) < Bot.IDEAL_RANGE * 1.2 \
				and sim.has_line_of_sight(me.pos, target.pos)
		_:
			return false

## Topun uçuş müddətində hədəfin gedəcəyi nöqtə.
## İki dəfə hesablanır: birinci təxmin məsafəni, ikinci artıq qabaqlanmış
## nöqtəyə görə uçuş vaxtını dəqiqləşdirir.
##
## [param speed] — mərminin sürəti; sıfırdırsa (damcı) uçuş məsafədən asılı deyil və
## [param lob_t] saniyədir (atıcının mutasiyası ilə, [method Const.lob_flight]).
static func _lead_point(from: Vector2, target: Sim.GermState, speed := Const.SHOT_SPEED,
		lob_t := Const.LOB_FLIGHT) -> Vector2:
	var point := target.pos
	for _i in 2:
		var flight := lob_t + Const.TICK_DELTA if speed <= 0.0 \
			else from.distance_to(point) / speed
		point = target.pos + target.vel * flight
	return point


## Hədəfə nişan bucağı, səhvi ilə birlikdə.
##
## Yeni oyunçuya ([member Sim.GermState.newbie]) bot onun getdiyi yeri QABAQLAMIR
## və bacarığı [constant Const.NEWBIE_BOT_SKILL]-dən yuxarı olmur: səhv ən azı iki
## dəfə böyükdür. Təsadüfi ədəd həmişə BİR dəfə çəkilir — toxumlu dünyada (testlər,
## balans ölçüsü) botun qərarları əvvəlki ardıcıllıqla qalır.
##
## Qabaqlama atəşin öz sürəti ilə hesablanır ([constant Const.SHOT_PROFILE_SPEED]); amöbün
## damcısında məsafə də nişandır — [member _lob_range] nişan nöqtəsinə qədər yazılır.
func _aim_at(me: Sim.GermState, target: Sim.GermState) -> float:
	var profile := Const.shot_profile(int(me.species), me.in_cyst())
	var speed := Const.shot_speed(profile, me.mutations)
	if profile == Const.Shot.LOB:
		speed = 0.0
	var point := target.pos if target.newbie \
		else _lead_point(me.pos, target, speed, Const.lob_flight(me.mutations))
	var skill := minf(difficulty, Const.NEWBIE_BOT_SKILL) if target.newbie else difficulty
	if profile == Const.Shot.LOB:
		_lob_range = me.pos.distance_to(point)
	_aim_at_angle = (point - me.pos).angle() \
		+ _rng.randf_range(-AIM_ERROR, AIM_ERROR) / maxf(skill, 0.1)
	return _aim_at_angle


## Son [method _aim_at]-ın bucağı — damcının düşmə yeri onunla yoxlanılır.
var _aim_at_angle := 0.0


## Yeni oyunçu ilk [constant Const.NEWBIE_GRACE] saniyəsində hədəf seçilmir.
##
## Komandalı rejimdə yoldaş hədəf deyil: top onun içindən keçir ([method Sim._step_shots]),
## yəni atəş boşa gedir. Əvvəl bu yoxlama yox idi və CÜT/ÜÇLÜK botları ən yaxın mikroba —
## çox vaxt yoldaşına — nişan alırdı: ölçülüb, atəşin orta hesabla 21% (CÜT) və 28%
## (ÜÇLÜK) yoldaşa düşürdü. Komandasız rejimdə `team` -1-dir və şərt heç nəyi süzmür.
static func _nearest_enemy(sim: Sim, me: Sim.GermState) -> Sim.GermState:
	var best: Sim.GermState = null
	var best_d := INF
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.id == me.id or not g.alive or g.safe_t > 0.0:
			continue
		if me.team >= 0 and g.team == me.team:
			continue
		if g.newbie and g.age < Const.NEWBIE_GRACE:
			continue
		var d := me.pos.distance_squared_to(g.pos)
		if d < best_d:
			best_d = d
			best = g
	return best


# ---------------------------------------------------------------- obyekt rejimləri

## [method _objective]-in cavabı — hər tick massiv ayırmamaq üçün sahələrdədir.
var _o_move := Vector2.ZERO
var _o_aim := 0.0
var _o_fire := false
## NÜVƏ TOPU: əvvəlki tick vurucu idimi (rolun titrəməməsi üçün).
var _striker := false
## NÜVƏ TOPU: Nüvəyə nə qədərdir boşuna dirənir, yana sürüməyə qalan vaxt və tərəf.
var _stall_t := 0.0
var _dribble_t := 0.0
var _dribble_side := 1.0

## ANA HÜCEYRƏ: Ananın "zolaqları" — Ananın səthinə açıq atəş xətti olan nöqtələr.
## Düzümdə kövrək yoxdur, yəni xətlər matç boyu dəyişmir: rejim, komanda və məsafə
## başına bir dəfə hesablanır.
static var _lanes := {}


## Rejimin obyekti üçün qərar. false — adi davranış (qida, döyüş) işləsin.
##
## Bot obyektə insan kimi xidmət edir, imtiyazsız: ANA-da yuvanın ağzından rəqibin
## Anasına atır və ac olanda öz Anasından əmir, ADA-da adaya gedir və orada qalır,
## NÜVƏ TOPU-nda Nüvənin arxasına keçib onu qapıya itələyir.
func _objective(sim: Sim, me: Sim.GermState, target: Sim.GermState, meal: Sim.FoodState,
		hungry: bool, bloated: bool, can_fight: bool) -> bool:
	if me.team != 0 and me.team != 1:
		return false
	match sim.mode:
		Const.Mode.MOTHER:
			return _mother_plan(sim, me, target, meal, hungry, bloated, can_fight)
		Const.Mode.ISLAND:
			return _island_plan(sim, me, target, meal, hungry, can_fight)
		Const.Mode.BALL:
			return _ball_plan(sim, me, target, meal, hungry, bloated, can_fight)
	return false


func _mother_plan(sim: Sim, me: Sim.GermState, target: Sim.GermState, meal: Sim.FoodState,
		hungry: bool, bloated: bool, can_fight: bool) -> bool:
	var t := me.team
	var own_i := sim.mother_index[t]
	var foe_i := sim.mother_index[1 - t]
	if own_i < 0 or foe_i < 0:
		return false
	var own := sim.obstacles[own_i]
	var foe := sim.obstacles[foe_i]
	var own_c := Vector2(own.x, own.y)
	var foe_c := Vector2(foe.x, foe.y)
	var enemy_d := target.pos.distance_to(me.pos) if target != null else INF
	# Komandanın bir botu müdafiəçidir — id-si ən kiçik olan. Rol vəziyyətdən çıxır,
	# təsadüfdən yox: toxumlu dünyada botların qərar ardıcıllığı dəyişməsin. Əvvəl
	# `id % 3` idi və bir komandaya üç hücumçu düşürdü — ölçülüb, o komanda altı
	# matçın altısını udurdu.
	var defender := _first_bot(sim, me)

	# Ac — öz Anasından əmir (yaxında qida yoxdursa). Ana boşdursa adi qida yolu.
	var can_suck := not sim.mother_ot \
		and float(sim.mother_balls[t]) > float(Const.MOTHER_CAP) * Const.MOTHER_SUCK_MIN + 2.0
	if hungry and can_suck and (meal == null or meal.pos.distance_to(me.pos) > 160.0):
		_go_to_mother(sim, me, own_c, own.z, t)
		_o_aim = (foe_c - me.pos).angle()
		_o_fire = false
		return true
	if hungry:
		return false
	# Ana partlamağa yaxındır — boş olan müdafiəçi onu boşaltmağa gedir (əmmək ən güclü
	# müdafiədir və əmilən top elə hücumun sursatıdır).
	var full := float(sim.mother_balls[t]) / float(Const.MOTHER_CAP)
	if not sim.mother_ot and full > 0.75 and me.fill() < 0.6 and (defender or full > 0.88):
		_go_to_mother(sim, me, own_c, own.z, t)
		_o_aim = ((target.pos if target != null else foe_c) - me.pos).angle()
		_o_fire = target != null and enemy_d < IDEAL_RANGE and me.balls > Const.FIRE_MIN_BALLS \
			and sim.has_line_of_sight(me.pos, target.pos)
		return true

	# Yaxın rəqib — adi döyüş. Müdafiəçi Anasına yaxınlaşanı uzaqdan da qovur.
	var guard := defender and target != null and target.pos.distance_to(own_c) < 520.0
	if can_fight and (enemy_d < 300.0 or guard):
		return false

	# Rəqibin Anasına açıq xətt varsa — Ananın səthinə atır.
	var dist := me.pos.distance_to(foe_c)
	var surface := foe_c + (me.pos - foe_c).normalized() * (foe.z + Const.SHOT_RADIUS + 4.0)
	var aim_pt := _mother_aim_point(sim, me, foe_c, foe.z, surface)
	if not defender and dist < 520.0 and aim_pt.is_finite():
		_o_aim = (aim_pt - me.pos).angle() \
			+ _rng.randf_range(-AIM_ERROR, AIM_ERROR) / maxf(difficulty, 0.1)
		# Amöbün damcısı Ananın kənarına düşür — oradan Ana onu udur ([method Sim._land_lob]).
		_lob_range = me.pos.distance_to(aim_pt)
		_o_fire = me.balls > Const.FIRE_MIN_BALLS
		# Atəş məsafəsində yan-yana addımlayır — sabit hədəf olmasın.
		var to := (foe_c - me.pos).normalized()
		_o_move = (to * signf(dist - 360.0) * 0.6 + Vector2(-to.y, to.x) * _strafe * 0.6) \
			.limit_length(1.0)
		return true
	var shoot := target != null and enemy_d < IDEAL_RANGE and me.balls > Const.FIRE_MIN_BALLS \
		and sim.has_line_of_sight(me.pos, target.pos)
	if defender and not bloated:
		# Yuvanın ağzında gözləyir, meydana baxaraq.
		_o_move = _steer(me.pos, _lane_point(sim, t, me.pos, 260.0), 30.0)
		_o_aim = ((target.pos if target != null else foe_c) - me.pos).angle()
		_o_fire = false
		return true

	# Hücum: rəqibin Anasının zolağına gedir (yuvanın ağzının qarşısı). DOLU bot da bura
	# gəlir — əmilən top rəqibin Anasına atılmalıdır. Əvvəl dolu bot adi davranışa
	# qayıdırdı: Anası hücuma məruz qalan komanda əmirdi, dolurdu və yuvasının yanında
	# rəqib mikroblara atırdı — ölçülüb, iyirmi matçın on dördündə bir komanda rəqibin
	# Anasına heç atmırdı (+0..+18).
	_o_move = _steer(me.pos, _lane_point(sim, 1 - t, me.pos, 380.0), 20.0)
	_o_aim = _o_move.angle() if _o_move != Vector2.ZERO else me.aim
	_o_fire = false
	if bloated and shoot:
		_o_aim = _aim_at(me, target)
		_o_fire = true
	return true


## Rəqibin Anasına bu yerdən atəşin nişan nöqtəsi; çatmırsa INF.
##
## Düz atəş Ananın mərkəzinə atılır və səthinə açıq xətt istəyir. İynələr isə 0.9 s
## yaşayır (~350 px): 520 px-dən atılan iynə Anaya çatmadan sönürdü — ölçülüb (14 matç),
## ayaqlının Anaya dəyən hərəkəti 21%-dən 15%-ə düşmüşdü.
##
## Damcıya xətt lazım deyil — yuvanın divarının üstündən keçir. O, Ananın kənarına, sahəsi
## Anaya toxunan nöqtəyə düşür ([method Sim._land_lob]) və bu nöqtə mikroblardan ən uzaq
## yer seçilir: müdafiəçilər Anaya toxunub əmir və onların üstünə düşən damcı Ananı yox,
## onları doldurur (ölçülüb: Anaya atılan damcıların 31%-i mikroba düşürdü).
func _mother_aim_point(sim: Sim, me: Sim.GermState, foe_c: Vector2, foe_r: float,
		surface: Vector2) -> Vector2:
	match Const.shot_profile(int(me.species), me.in_cyst()):
		Const.Shot.LOB:
			return _lob_mother_point(sim, me, foe_c, foe_r)
		Const.Shot.NEEDLE:
			if me.pos.distance_to(surface) < Const.shot_reach(Const.Shot.NEEDLE, me.mutations) * 0.85 \
					and sim.has_line_of_sight(me.pos, surface):
				return foe_c
		_:
			if sim.has_line_of_sight(me.pos, surface):
				return foe_c
	return Vector2.INF


## Damcının Anaya düşəcəyi nöqtə — Ananın kənarında, bota baxan tərəfdə (±0.8 rad),
## damcının aralığında, etibarlı və rəqib mikroblardan ən uzaq. Yoxdursa INF.
func _lob_mother_point(sim: Sim, me: Sim.GermState, foe_c: Vector2, foe_r: float) -> Vector2:
	var best := Vector2.INF
	var best_score := -INF
	var base := (me.pos - foe_c).angle()
	for k in range(-4, 5):
		var p := foe_c + Vector2.from_angle(base + float(k) * 0.2) * (foe_r + 14.0)
		var d := me.pos.distance_to(p)
		if d < Const.LOB_MIN or d > Const.lob_max(me.mutations) or not sim.lob_valid(p):
			continue
		# Damcı yoldaşa dəymir — yalnız rəqiblərdən uzaqlıq sayılır.
		var clear := 120.0
		for gid in sim.germs:
			var g: Sim.GermState = sim.germs[gid]
			if g.id == me.id or not g.alive or (me.team >= 0 and g.team == me.team):
				continue
			clear = minf(clear, p.distance_to(g.pos) - g.radius())
		var score := clear - absf(float(k)) * 4.0
		if score > best_score:
			best_score = score
			best = p
	return best


## Komandanın sağ botları arasında id-si ən kiçik olan mənəmmi.
static func _first_bot(sim: Sim, me: Sim.GermState) -> bool:
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.is_bot and g.alive and g.team == me.team and g.id < me.id:
			return false
	return true


## Öz Anasına toxunmağa gedir: açıq yol varsa düz, yoxsa əvvəlcə yuvanın ağzına.
func _go_to_mother(sim: Sim, me: Sim.GermState, c: Vector2, r: float, team: int) -> void:
	var touch := c + (me.pos - c).normalized() * (r + me.radius())
	if sim.has_line_of_sight(me.pos, touch):
		_o_move = (c - me.pos).normalized()
	else:
		_o_move = _steer(me.pos, _lane_point(sim, team, me.pos, 300.0), 10.0)
		if _o_move == Vector2.ZERO:
			_o_move = (c - me.pos).normalized()


## [param team]-in Anasının ən yaxın zolaq nöqtəsi ([param radius] məsafəsində).
static func _lane_point(sim: Sim, team: int, from: Vector2, radius: float) -> Vector2:
	var pts := _lane_points(sim, team, radius)
	var i := sim.mother_index[team]
	var c := Vector2(sim.obstacles[i].x, sim.obstacles[i].y) if i >= 0 else Vector2.ZERO
	var best := c + (-c).normalized() * radius
	var best_d := INF
	for p in pts:
		var d := from.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = p
	return best


static func _lane_points(sim: Sim, team: int, radius: float) -> PackedVector2Array:
	var key := "%d|%d|%d" % [sim.mode, team, int(radius)]
	if _lanes.has(key):
		return _lanes[key]
	var pts := PackedVector2Array()
	var i := sim.mother_index[team]
	if i >= 0:
		var o := sim.obstacles[i]
		var c := Vector2(o.x, o.y)
		# Meydana — qabın mərkəzinə — baxan ±80°.
		var base := (-c).angle()
		for k in range(-16, 17):
			var dir := Vector2.from_angle(base + deg_to_rad(5.0 * k))
			var p := c + dir * radius
			if not DishMap.is_free_in(sim.obstacles, sim.wall_radius, p, 34.0):
				continue
			if sim.has_line_of_sight(p, c + dir * (o.z + Const.SHOT_RADIUS + 4.0)):
				pts.append(p)
	_lanes[key] = pts
	return pts


## Nöqtəyə istiqamət; [param stop] radiusunda dayanır.
static func _steer(from: Vector2, to: Vector2, stop: float) -> Vector2:
	if from.distance_to(to) <= stop:
		return Vector2.ZERO
	return (to - from).normalized()


func _island_plan(sim: Sim, me: Sim.GermState, target: Sim.GermState, meal: Sim.FoodState,
		hungry: bool, can_fight: bool) -> bool:
	# Ada hələ yığılmayıb — bütün qab yaşdır, adi oyun.
	if sim.dish_radius >= sim.wall_radius - 1.0:
		return false
	var c := sim.wet_center
	var r := sim.dish_radius
	var to_c := c - me.pos
	var shoot := target != null and me.balls > Const.FIRE_MIN_BALLS \
		and target.pos.distance_to(me.pos) < IDEAL_RANGE * 1.2 \
		and sim.has_line_of_sight(me.pos, target.pos)
	if to_c.length() > r * 0.75:
		# Adaya gedir, yolda yaxın rəqibə atır.
		_o_move = to_c.normalized()
		_o_aim = _aim_at(me, target) if shoot else _o_move.angle()
		_o_fire = shoot
		return true
	if hungry and meal != null and meal.pos.distance_to(c) < r * 0.9:
		return false
	# Adadadır: döyüşür, amma kənara çəkildikcə mərkəzə dartılır.
	var home := to_c / maxf(r, 1.0)
	if target != null and can_fight and target.pos.distance_to(me.pos) < AGGRO_RANGE:
		var to := (target.pos - me.pos).normalized()
		_o_move = (Vector2(-to.y, to.x) * _strafe * 0.7 + home * 1.4).limit_length(1.0)
		_o_aim = _aim_at(me, target) if shoot else to.angle()
		_o_fire = shoot
		return true
	var around := Vector2(-to_c.y, to_c.x).normalized() * 0.3 * _strafe
	_o_move = (home + around).limit_length(1.0)
	_o_aim = _o_move.angle() if _o_move != Vector2.ZERO else me.aim
	_o_fire = false
	return true


func _ball_plan(sim: Sim, me: Sim.GermState, target: Sim.GermState, meal: Sim.FoodState,
		hungry: bool, bloated: bool, can_fight: bool) -> bool:
	var b := sim.ball
	if b == null:
		return false
	var enemy_d := target.pos.distance_to(me.pos) if target != null else INF
	# Komanda 0 şərqdəki qapıya vurur, 1 qərbdəkinə.
	var fwd := 1.0 if me.team == 0 else -1.0
	var own_goal := Vector2(-fwd * Const.BALL_WALL, 0.0)
	var close_enemy := target != null and enemy_d < 200.0 and me.balls > Const.FIRE_MIN_BALLS \
		and sim.has_line_of_sight(me.pos, target.pos)
	if not b.alive:
		# Nüvə partlayıb, mərkəzdə yenisi doğulur — öz yarısında, mərkəzə yaxın gözləyir.
		# Adi davranış burada döyüş olardı və bot Nüvə gələndə meydanın o başında olardı.
		_o_move = _steer(me.pos, Vector2(-fwd * 140.0, -90.0 if id % 2 == 0 else 90.0), 20.0)
		_o_aim = _aim_at(me, target) if close_enemy else (0.0 if fwd > 0.0 else PI)
		_o_fire = close_enemy
		return true
	# Yalnız həqiqətən ac olan qidaya gedir. NÜVƏ TOPU-nda tutum partlatmalarla böyüyür və
	# adi "doluluq 45%-dən az" şərti iri botları Nüvədən qidaya aparırdı.
	if me.balls <= Const.FIRE_MIN_BALLS and meal != null and meal.pos.distance_to(me.pos) < 220.0:
		return false
	# Dolu bot oyundan çıxmır — topları ataraq boşalır (bax aşağıda `dump`). Əvvəl adi
	# davranışa qayıdırdı və rəqibdən 600 px aralı dayanırdı: izləmədə vurucu Nüvədən
	# 540 px uzaqda saniyələrlə gözləyirdi, matçların yarısı 0:0 bitirdi.
	var dump := bloated and me.balls > Const.FIRE_MIN_BALLS
	var br := b.radius()
	# Vurucu yalnız Nüvəni ondan ƏVVƏL tutacaq rəqibə atır. Hər yaxın rəqibə atanda NÜVƏ
	# TOPU ölüm matçına dönürdü: dörd mikrob 3 dəqiqədə 50–80 dəfə ölürdü, Nüvə ortada
	# qalırdı və matçların yarısı 0:0 bitirdi.
	var shoot_enemy := target != null and enemy_d < 240.0 and me.balls > Const.FIRE_MIN_BALLS \
		and target.pos.distance_to(b.pos) < me.pos.distance_to(b.pos) + 30.0 \
		and sim.has_line_of_sight(me.pos, target.pos)

	# Komandanın Nüvəyə ən yaxını vurucudur, o biri qapını qoruyur. Vurucu yerini
	# 60 px fərqlə saxlayır — iki yoldaş eyni məsafədə olanda rollar hər tick dəyişməsin.
	var striker := true
	var my_d := me.pos.distance_to(b.pos) - (60.0 if _striker else 0.0)
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.id != me.id and g.alive and g.team == me.team and g.pos.distance_to(b.pos) < my_d:
			striker = false
			break
	_striker = striker

	if striker:
		var aim_pt := _goal_point(sim, me, b, fwd)
		var to_goal := (aim_pt - b.pos).normalized()
		var reach := br + me.radius()
		var off := me.pos - b.pos
		var lined := (-off).normalized().dot(to_goal) > 0.8
		var touching := off.length() < reach + 50.0
		# Dirənmə: itələyirəm, amma Nüvə yerindən tərpənmir — qarşıdan rəqib də itələyir.
		# Bir az sonra Nüvəni YANA sürüyür (yandan dolanaraq), rəqibin xəttindən çıxarır.
		if lined and touching and b.vel.length() < 30.0:
			_stall_t += Const.TICK_DELTA
		else:
			_stall_t = 0.0
		if _stall_t > 0.8:
			_stall_t = 0.0
			_dribble_t = 0.7
			_dribble_side = 1.0 if _rng.randf() < 0.5 else -1.0
		if _dribble_t > 0.0 and touching:
			_dribble_t -= Const.TICK_DELTA
			var r0 := off.normalized()
			_o_move = (Vector2(-r0.y, r0.x) * _dribble_side - r0 * 0.5).normalized()
		elif lined and touching:
			# Gövdə ilə itələyir: Nüvənin mərkəzindən hədəfə doğru keçən xətt boyu.
			_o_move = (aim_pt - me.pos).normalized()
		elif off.normalized().dot(-to_goal) < 0.5 and off.length() < reach + 120.0:
			# Nüvənin arxa tərəfində deyil — onun ətrafında, arxa tərəfə doğru fırlanır,
			# məsafəni saxlayaraq (Nüvəyə dəysə onu səhv tərəfə itələyərdi). Əvvəl
			# "yana və geri" gedirdi: Nüvədən uzaqlaşıb yenidən yaxınlaşırdı və
			# izləmədə vurucu bu dövrdə saniyələrlə ilişirdi.
			var radial := off.normalized()
			var tangent := Vector2(-radial.y, radial.x)
			if tangent.dot(-to_goal) < 0.0:
				tangent = -tangent
			var err := (reach + 26.0) - off.length()
			_o_move = (tangent + radial * clampf(err / 30.0, -1.0, 1.0)).normalized()
		else:
			# Arxa nöqtə şüşədən kənara düşə bilər (Nüvə şüşəyə yaxındır) — o halda
			# şüşənin içində ən yaxın yerdə gözləyir, menisk Nüvəni içəri gətirir.
			var behind := b.pos - to_goal * (reach + 10.0)
			var room := sim.wall_radius - me.radius() - 4.0
			if behind.length() > room:
				behind = behind.normalized() * room
			_o_move = _steer(me.pos, behind, 4.0)
		_o_aim = to_goal.angle()
		_o_fire = false
		var gap := off.length() - reach
		if shoot_enemy:
			_o_aim = _aim_at(me, target)
			_o_fire = true
		elif lined and gap > 60.0 and gap < 320.0 and b.weight < float(Const.BALL_WEIGHT_MAX) - 10.0 \
				and me.balls > Const.FIRE_MIN_BALLS + 1 and _ball_in_reach(sim, me, b):
			# Düz xətdə, bir az aralıdan — topla vurur (zərbə Nüvəni ağırlaşdırır, ona
			# görə çəki ehtiyatı qalanda).
			_o_aim = (b.pos - me.pos).angle()
			_lob_range = me.pos.distance_to(b.pos)
			_o_fire = true
		elif dump:
			# Dolu vurucu qapıya doğru boşalır — yolda Nüvəyə dəyən top onu da itələyir.
			_o_aim = to_goal.angle()
			_o_fire = true
			# Damcı yolda heç nəyə dəymir — Nüvənin üstündən uçardı. Xətdədirsə ona düşür
			# (uçuş istiqaməti qapıya doğrudur və təkan da oradır).
			if lined and _ball_in_reach(sim, me, b):
				_o_aim = (b.pos - me.pos).angle()
				_lob_range = me.pos.distance_to(b.pos)
		return true

	# İkinci oyunçu. Nüvə qapıya yaxındırsa və o, qapı tərəfindədirsə — Nüvəni gövdəsi ilə
	# qapıdan UZAQLAŞDIRIR. Yaxındırsa, amma qapı tərəfində deyilsə — qapının ağzına
	# qayıdır. Uzaqdadırsa — vurucunun arxasınca, bir az yanda gəlir. Əvvəl qapı ilə Nüvə
	# arasında hərəkətsiz dayanırdı və gövdəsi Nüvəni divar kimi saxlayırdı: ölçülüb, on
	# iki matçın beşi 0:0 bitirdi.
	var to_own := b.pos.distance_to(own_goal)
	if to_own < 330.0 and me.pos.distance_to(own_goal) < to_own:
		var away := (b.pos - own_goal).normalized()
		var reach2 := br + me.radius()
		var off2 := me.pos - b.pos
		if (-off2).normalized().dot(away) > 0.7 and off2.length() < reach2 + 50.0:
			_o_move = away
		else:
			_o_move = _steer(me.pos, b.pos - away * (reach2 + 8.0), 4.0)
	elif to_own < 420.0:
		_o_move = _steer(me.pos, own_goal + (b.pos - own_goal).normalized() * 130.0, 20.0)
	else:
		var lane := 140.0 if b.pos.y < 0.0 else -140.0
		_o_move = _steer(me.pos,
			Vector2(b.pos.x - fwd * 200.0, clampf(b.pos.y + lane, -300.0, 300.0)), 30.0)
	_o_aim = (b.pos - me.pos).angle()
	_o_fire = false
	# Qapıçı da yalnız Nüvəyə yaxın rəqibə atır — Nüvədən uzaqdakı döyüş matçı ölüm
	# matçına çevirirdi (bax yuxarıda `shoot_enemy`).
	if target != null and enemy_d < IDEAL_RANGE and can_fight and me.balls > Const.FIRE_MIN_BALLS \
			and target.pos.distance_to(b.pos) < 260.0 \
			and sim.has_line_of_sight(me.pos, target.pos):
		_o_aim = _aim_at(me, target)
		_o_fire = true
	elif b.pos.distance_to(own_goal) < 320.0 and me.balls > Const.FIRE_MIN_BALLS \
			and me.pos.distance_to(own_goal) < b.pos.distance_to(own_goal) \
			and _ball_in_reach(sim, me, b):
		# Nüvə qapıya yaxınlaşır, qapıçı onun qapı tərəfindədir — topla uzaqlaşdırır.
		_o_fire = true
		_lob_range = me.pos.distance_to(b.pos)
	elif dump:
		# Dolu qapıçı rəqibin tərəfinə boşalır, rəqibə yox — ölüm az olsun.
		_o_aim = 0.0 if fwd > 0.0 else PI
		_o_fire = true
	return true


## Nüvəyə atılan atəş ona çatar və dəyərmi — profilə görə.
##
## Düz atəş açıq xətt istəyir; iynələr isə ±7° açılır: 320 px-də ikisi də Nüvənin
## yanından keçirdi (sapma ±39 px, Nüvə 30 px) və ayaqlı vurucu Nüvəni heç itələyə
## bilmirdi. Damcı xətt istəmir, amma ən azı [constant Const.LOB_MIN] məsafə istəyir.
func _ball_in_reach(sim: Sim, me: Sim.GermState, b: Sim.BallState) -> bool:
	var d := me.pos.distance_to(b.pos)
	match Const.shot_profile(int(me.species), me.in_cyst()):
		Const.Shot.LOB:
			return d >= Const.LOB_MIN - Const.LOB_AREA and d <= Const.lob_max(me.mutations)
		Const.Shot.NEEDLE:
			# Yan sapma Nüvənin radiusundan az olsun — ikisi də dəysin.
			return d * tan(Const.NEEDLE_SPREAD) < b.radius() and sim.has_line_of_sight(me.pos, b.pos)
		_:
			return sim.has_line_of_sight(me.pos, b.pos)


## Vurucunun hədəfi: rəqib qapıçının OLMADIĞI yarıq tərəfi. Nüvə qapının yanındakı
## küncdədirsə, əvvəlcə qapının qarşısına çıxarılır — küncdən birbaşa qapıya yol
## dirəkdən keçir.
static func _goal_point(sim: Sim, me: Sim.GermState, b: Sim.BallState, fwd: float) -> Vector2:
	var goal := Vector2(fwd * Const.BALL_WALL, 0.0)
	if absf(b.pos.y) > 130.0 and b.pos.x * fwd > 360.0:
		return Vector2(fwd * 430.0, 0.0)
	var keeper_y := 0.0
	var best := INF
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.alive and g.team != me.team and g.team >= 0:
			var d := g.pos.distance_to(goal)
			if d < best:
				best = d
				keeper_y = g.pos.y
	var side := Const.BALL_GOAL_HALF * 0.55
	return Vector2(goal.x, -side if keeper_y > 0.0 else side) if best < 260.0 else goal


## Hər bot hər tick BÜTÜN qidanı gəzir, ona görə döngü mümkün qədər yüngüldür:
## mövqe və id bir dəfə oxunur, kilid isə yalnız daha yaxın namizəddə
## yoxlanılır. Şərtlər yan təsirsizdir — seçilən qida (bərabərlikdə də) eynidir.
static func _nearest_food(sim: Sim, me: Sim.GermState) -> Sim.FoodState:
	var best: Sim.FoodState = null
	var best_d := INF
	var at := me.pos
	var my_id := me.id
	for f in sim.food:
		var d := at.distance_squared_to(f.pos)
		if d < best_d and not (f.lock_id == my_id and f.lock_t > 0.0):
			best_d = d
			best = f
	return best
