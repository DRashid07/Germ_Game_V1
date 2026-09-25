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

## Botun saxlamağa çalışdığı döyüş məsafəsi.
const IDEAL_RANGE := 380.0
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


func _init(p_id: int, p_difficulty := 1.0) -> void:
	id = p_id
	difficulty = p_difficulty
	_rng.randomize()


static func random_name(index: int) -> String:
	return BOT_NAMES[index % BOT_NAMES.size()]


func think(sim: Sim, dt: float) -> Sim.PlayerInput:
	_seq += 1
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
	var out_by := me.pos.length() - sim.dish_radius * 0.92

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
		var inward := (-me.pos).normalized()
		move = inward
		aim = inward.angle()
		# Qaçarkən də boşalır: dolu olduğu üçün qaçır, top atmaq onu xilas edir.
		fire = bloated and me.balls > Const.FIRE_MIN_BALLS

	elif target != null and target.pos.distance_to(me.pos) < AGGRO_RANGE and can_fight:
		var to_target := target.pos - me.pos
		var dist := to_target.length()
		var forward := to_target.normalized()
		var side := Vector2(-forward.y, forward.x) * _strafe

		# Dolu botun məsafəsi daha uzaqdır — rəqibin bir topu onu partlada bilər.
		var want := IDEAL_RANGE * (1.6 if bloated else 1.0)
		var radial := signf(dist - want)
		move = (forward * radial * 0.9 + side * 0.7).limit_length(1.0)

		var lead := _lead_point(me.pos, target)
		aim = (lead - me.pos).angle()
		aim += _rng.randf_range(-AIM_ERROR, AIM_ERROR) / maxf(difficulty, 0.1)
		# Yalnız açıq xətt olanda atır — maneəyə atmağın mənası yoxdur.
		# Özünü acdan qorumaq üçün ehtiyat saxlayır.
		fire = me.balls > Const.FIRE_MIN_BALLS and sim.has_line_of_sight(me.pos, target.pos)
	elif meal != null:
		var to_food := meal.pos - me.pos
		move = to_food.normalized()
		aim = to_food.angle()
		# Dolu botun tək çarəsi top atmaqdır: atəş həm də boşalma üsuludur.
		fire = bloated and me.balls > Const.FIRE_MIN_BALLS
	else:
		# Qida da, rəqib də yoxdur — mərkəzə doğru gəzir.
		var wander := (-me.pos).normalized().rotated(_rng.randf_range(-0.8, 0.8))
		move = wander
		aim = wander.angle()

	move = _avoid(sim, me, move)

	var use_super := me.super_ready() and _wants_super(sim, me, target, meal, hungry)
	return Sim.PlayerInput.make(_seq, move, aim, fire, use_super)


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
##   • amöb     — sıxılanda: ya acdır, ya rəqib top atmağa hazırdır (möhlət)
static func _wants_super(sim: Sim, me: Sim.GermState, target: Sim.GermState,
		meal: Sim.FoodState, hungry: bool) -> bool:
	match me.species:
		Const.Species.CILIATE:
			# Trixosist top xərcləyir — acıqkən qaçış özü ölümə apara bilər.
			if me.balls <= Const.MIN_BALLS + Const.TRICHO_COST:
				return false
			var reach := me.radius() * Const.TRICHO_RADIUS
			for shot in sim.shots:
				if shot.owner_id != me.id and shot.pos.distance_to(me.pos) < reach:
					return true
			return false
		Const.Species.HELIOZOAN:
			if me.fill() > 0.55 or meal == null:
				return false
			return meal.pos.distance_to(me.pos) < me.radius() * Const.NET_RADIUS
		Const.Species.AMOEBA:
			if hungry and me.balls <= Const.MIN_BALLS + 1:
				return true
			if target == null:
				return false
			return target.pos.distance_to(me.pos) < Bot.IDEAL_RANGE * 0.7
		_:
			return false

## Topun uçuş müddətində hədəfin gedəcəyi nöqtə.
## İki dəfə hesablanır: birinci təxmin məsafəni, ikinci artıq qabaqlanmış
## nöqtəyə görə uçuş vaxtını dəqiqləşdirir.
static func _lead_point(from: Vector2, target: Sim.GermState) -> Vector2:
	var point := target.pos
	for _i in 2:
		var flight := from.distance_to(point) / Const.SHOT_SPEED
		point = target.pos + target.vel * flight
	return point


static func _nearest_enemy(sim: Sim, me: Sim.GermState) -> Sim.GermState:
	var best: Sim.GermState = null
	var best_d := INF
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.id == me.id or not g.alive or g.safe_t > 0.0:
			continue
		var d := me.pos.distance_squared_to(g.pos)
		if d < best_d:
			best_d = d
			best = g
	return best


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
