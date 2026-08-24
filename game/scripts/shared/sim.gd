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

	func radius() -> float:
		return Const.germ_radius(capacity)

	func speed() -> float:
		return Const.germ_speed(capacity)

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
		return c


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

	static func make(p_seq: int, p_move: Vector2, p_aim: float, p_fire: bool) -> PlayerInput:
		var i := PlayerInput.new()
		i.seq = p_seq
		i.move = p_move.limit_length(1.0)
		i.aim = p_aim
		i.fire = p_fire
		return i

	func to_array() -> Array:
		return [seq, move.x, move.y, aim, fire]

	static func from_array(a: Array) -> PlayerInput:
		return PlayerInput.make(int(a[0]), Vector2(a[1], a[2]), float(a[3]), bool(a[4]))


var tick := 0
var germs := {}                         ## id -> GermState
var shots: Array[ShotState] = []
var food: Array[FoodState] = []
var obstacles: Array[Vector3] = []

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
## Prediction rejimi: metabolizm və acından partlama işlədilmir
## (bax [method step_movement]).
var _no_metabolism := false


func _init() -> void:
	obstacles = DishMap.obstacles()
	rng.randomize()


# ---------------------------------------------------------------- mikroblar

func add_germ(id: int, germ_name: String, color: int, bot := false) -> GermState:
	var g := GermState.new()
	g.id = id
	g.name = germ_name
	g.color = color
	g.is_bot = bot
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
func find_spawn(radius: float) -> Vector2:
	var pad := radius + 40.0
	var pos := Vector2.ZERO
	for _attempt in 40:
		var a := rng.randf() * TAU
		# sqrt — dairə üzrə BƏRABƏR paylanma (əks halda hamı mərkəzdə doğulur)
		var d := sqrt(rng.randf()) * (Const.WORLD_RADIUS - pad)
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
		rows.append([g.name, g.pops, g.capacity])
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

	for id in germs:
		var g: GermState = germs[id]
		if not g.alive:
			continue

		var inp: PlayerInput = inputs.get(id)
		var wish := Vector2.ZERO
		if inp != null:
			wish = inp.move
			g.aim = inp.aim

		g.vel = g.vel.move_toward(wish * g.speed(), Const.ACCEL * dt)
		g.pos += g.vel * dt
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

		if inp != null and inp.fire and g.cooldown <= 0.0 and g.balls >= Const.FIRE_MIN_BALLS:
			_fire(g)

		if g.balls < Const.MIN_BALLS and not _no_metabolism:
			starved.append(g)

	# Partlama dictionary-ni dəyişdiyi üçün gəzinti bitəndən sonra icra olunur.
	for g in starved:
		_burst(g, 0)


## Mikrobu qabın içində və maneələrdən kənarda saxlayır.
func _confine(g: GermState) -> void:
	var r := g.radius()
	for o in obstacles:
		var c := Vector2(o.x, o.y)
		var min_d := o.z + r
		var delta := g.pos - c
		var d := delta.length()
		if d < min_d:
			var n := (delta / d) if d > 0.001 else Vector2.RIGHT
			g.pos = c + n * min_d
			# Maneəyə dik gələn sürət söndürülür, yan sürət qalır — mikrob sürüşür.
			g.vel -= n * minf(g.vel.dot(n), 0.0)

	var limit := Const.WORLD_RADIUS - r
	if g.pos.length() > limit:
		var n := g.pos.normalized()
		g.pos = n * limit
		g.vel -= n * maxf(g.vel.dot(n), 0.0)


## Mikroblar bir-birinin içinə girmir — üst-üstə yığılma oyunu oxunmaz edir.
## İki tərəf bərabər itələnir, ona görə heç kim divara sıxışdırıla bilmir.
func _separate_germs() -> void:
	var ids := germs.keys()
	for i in range(ids.size()):
		var a: GermState = germs[ids[i]]
		if not a.alive:
			continue
		for j in range(i + 1, ids.size()):
			var b: GermState = germs[ids[j]]
			if not b.alive:
				continue
			var delta := b.pos - a.pos
			var min_d := a.radius() + b.radius()
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
	s.pos = g.pos + dir * (g.radius() + Const.SHOT_RADIUS + Const.MUZZLE_GAP)
	s.dir = dir
	s.life = Const.SHOT_LIFETIME
	shots.append(s)

	g.balls -= 1
	g.cooldown = Const.FIRE_COOLDOWN
	# Geri təpmə: atəş həm də manevr vasitəsidir.
	g.vel -= dir * Const.SHOT_RECOIL
	# Atəş açan toxunulmazlığını itirir — doğuş qorunması hücum qalxanı deyil.
	g.safe_t = 0.0

	events.append({"t": "fire", "pos": s.pos, "arg": g.aim, "color": g.color})


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
		var hit_obstacle := Vector3.ZERO
		var on_obstacle := false

		for o in obstacles:
			var t := _seg_circle_t(from, to, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS)
			if t >= 0.0 and t < best:
				best = t
				victim = null
				hit_obstacle = o
				on_obstacle = true

		for id in germs:
			var g: GermState = germs[id]
			if not g.alive or g.id == s.owner_id or g.safe_t > 0.0:
				continue
			var t := _seg_circle_t(from, to, g.pos, g.radius() + Const.SHOT_RADIUS)
			if t >= 0.0 and t < best:
				best = t
				victim = g
				on_obstacle = false

		if best <= 1.0:
			var hit_pos := from.lerp(to, best)
			if victim != null:
				_inject(victim, hit_pos, s)
				continue
			if on_obstacle:
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


## Top rəqibin içinə keçdi və bölündü. Tutumu aşdısa rəqib partlayır —
## oyunun əsas qaydası. Niyə bir yox, [constant Const.SHOT_PAYLOAD] top:
## atəş dövrü ilə boşalma sürəti eyni olduğuna görə hücumun xalis üstünlüyü
## olmalıdır, əks halda dolu rəqib sadəcə atəş açaraq sonsuza qədər sağ qalır.
func _inject(victim: GermState, at: Vector2, s: ShotState) -> void:
	victim.balls += Const.SHOT_PAYLOAD
	events.append({"t": "hit", "pos": at, "arg": 1.0, "color": s.color})
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

	burst_log.append({
		"id": g.id,
		"killer": killer_id,
		"killer_name": killer.name if killer != null else "",
		"pops": g.pops,
		"cap": g.capacity,
		"age": g.age,
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

	for f in food:
		f.lock_t = maxf(0.0, f.lock_t - dt)
		if f.vel.length_squared() > 1.0:
			f.vel *= damp
			f.pos += f.vel * dt
			var limit := Const.WORLD_RADIUS - Const.FOOD_RADIUS
			if f.pos.length() > limit:
				var n := f.pos.normalized()
				f.pos = n * limit
				f.vel = f.vel.bounce(-n) * 0.5

		var eaten := false
		for id in germs:
			var g: GermState = germs[id]
			if not g.alive or g.balls >= g.capacity:
				continue
			if f.lock_id == g.id and f.lock_t > 0.0:
				continue
			if f.pos.distance_squared_to(g.pos) > pow(g.radius() + Const.FOOD_RADIUS, 2.0):
				continue
			g.balls += 1
			events.append({"t": "absorb", "pos": f.pos, "arg": 0.0, "color": g.color})
			eaten = true
			break

		if not eaten:
			survivors.append(f)

	food = survivors


func _spawn_food(dt: float) -> void:
	if food.size() >= Const.FOOD_TARGET:
		_food_budget = 0.0
		return
	_food_budget += Const.FOOD_SPAWN_RATE * dt
	while _food_budget >= 1.0 and food.size() < Const.FOOD_TARGET:
		_food_budget -= 1.0
		_drop_food(find_spawn(Const.FOOD_RADIUS), Vector2.ZERO, 0)


# ---------------------------------------------------------------- həndəsə

## İki nöqtə arasında maneəsiz atəş xətti varmı?
## Bot hədəf seçərkən istifadə olunur.
func has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	for o in obstacles:
		if _seg_circle_t(a, b, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS) >= 0.0:
			return false
	return true


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
