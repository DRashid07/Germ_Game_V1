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

const BOT_NAMES := [
	"Amöb", "Koks", "Basil", "Spiral", "Vibrio", "Spor", "Nüvə", "Plazma",
	"Toksin", "Mikoz", "Virion", "Koloniya", "Flagel", "Zülal", "Bakter",
]

## Botun saxlamağa çalışdığı döyüş məsafəsi.
const IDEAL_RANGE := 380.0
## Bu məsafədən uzaq rəqib bota maraqlı deyil.
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

	if target != null and target.pos.distance_to(me.pos) < AGGRO_RANGE and not hungry:
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

	return Sim.PlayerInput.make(_seq, move, aim, fire)


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


static func _nearest_food(sim: Sim, me: Sim.GermState) -> Sim.FoodState:
	var best: Sim.FoodState = null
	var best_d := INF
	for f in sim.food:
		if f.lock_id == me.id and f.lock_t > 0.0:
			continue
		var d := me.pos.distance_squared_to(f.pos)
		if d < best_d:
			best_d = d
			best = f
	return best
