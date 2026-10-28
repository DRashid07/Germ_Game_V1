class_name AttackTest
extends RefCounted
## Növlərin fərqli adi atəşi ([enum Const.Shot]) — headless testlər. [SimTest]-in içindən
## işləyir, eyni sayğacla.
##
## İqtisadiyyat bütün profillərdə eynidir: hərəkət −1 top, hərəkətin mərmiləri mikroblara
## cəmi ən çoxu +2. Hər qrup mükafatı (super, qida, kövrək qabıq, Ana, Nüvə) hərəkət başına
## bir dəfədir ([member Sim._volleys]). Damcı maneənin üstündən keçir, havada zərər vermir,
## düşəndə tək rəqibə +2 verir və xəbərdarlığı atıcını açmır.

const A_ID := 101
const B_ID := 202
const C_ID := 303
const DT := Const.TICK_DELTA


static func run() -> int:
	var fail0 := SimTest._fail
	print("\n----- Adi atəşin profilləri -----")
	_test_profile_table()
	_test_cost_one_per_action()
	_test_needle_pair()
	_test_needle_payloads()
	_test_volley_one_food()
	_test_volley_one_crack()
	_test_volley_mother_budget()
	_test_volley_ball_budget()
	_test_tricho_pops_needles_once()
	_test_dead_shooter_keeps_team()
	_test_lob_flies_over_cover()
	_test_lob_harmless_in_flight()
	_test_lob_single_target()
	_test_lob_friendly_and_shield()
	_test_lob_invalid_costs_nothing()
	_test_lob_objects()
	_test_lob_no_rewind()
	_test_minigun_profile()
	_test_input_range()
	_test_merge_keeps_range()
	_test_prediction_profiles()
	_test_prediction_lob()
	_test_prediction_volley()
	_test_own_lob_hit_shown()
	_test_lob_row_privacy()
	_test_snapshot_with_lobs()
	_test_hit_arg_payload()
	_test_rules_version()
	_test_bot_ranges()
	_test_bot_lob_cover()
	return SimTest._fail - fail0


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


## Maneəsiz, qalxansız dünya: A ([param a_species]) solda, B sağda, aralarında [param gap].
## Metabolizm və qida işə düşmür — testlər yalnız [method Sim._fire] və
## [method Sim._step_shots]-u addımlayır.
static func _duel(a_species: int, gap: float) -> Sim:
	var s := Sim.new()
	s.obstacles.clear()
	s._reset_walls()
	var a := s.add_germ(A_ID, "A", 0, false, Const.species_from(a_species))
	var b := s.add_germ(B_ID, "B", 1)
	for g: Sim.GermState in [a, b]:
		g.safe_t = 0.0
		g.vel = Vector2.ZERO
		g.drain_t = 1.0e9
	a.pos = Vector2(-gap * 0.5, 0.0)
	b.pos = Vector2(gap * 0.5, 0.0)
	a.aim = 0.0
	s.food.clear()
	return s


## Mərmilər bitənə qədər addımlayır (ən çoxu [param ticks]).
static func _fly(s: Sim, ticks := 120) -> void:
	for i in ticks:
		if s.shots.is_empty():
			return
		s._step_shots(DT)


static func _test_profile_table() -> void:
	_check(Const.shot_profile(int(Const.Species.CILIATE)) == Const.Shot.DART
		and Const.shot_profile(int(Const.Species.HELIOZOAN)) == Const.Shot.NEEDLE
		and Const.shot_profile(int(Const.Species.AMOEBA)) == Const.Shot.LOB
		and Const.shot_profile(int(Const.Species.AMOEBA), true) == Const.Shot.MINIGUN,
		"profillər: kirpikli ox, ayaqlı iynə, amöb damcı, superdə miniqan")
	var worst := 0
	for p in Const.SHOT_PROFILE_PAYLOAD.size():
		var count := Const.NEEDLE_COUNT if p == Const.Shot.NEEDLE else 1
		worst = maxi(worst, Const.SHOT_PROFILE_PAYLOAD[p] * count)
	_check(worst == Const.SHOT_PAYLOAD,
		"bir hərəkətin mərmiləri mikroblara cəmi ən çoxu +%d verir (%d)" % [Const.SHOT_PAYLOAD, worst])
	_check(is_equal_approx(Const.SHOT_PROFILE_SPEED[Const.Shot.DART], 560.0)
		and is_equal_approx(Const.SHOT_PROFILE_LIFE[Const.Shot.DART], 1.6)
		and is_equal_approx(Const.SHOT_PROFILE_RADIUS[Const.Shot.DART], 6.0)
		and is_equal_approx(Const.SHOT_PROFILE_SPEED[Const.Shot.NEEDLE], 390.0)
		and is_equal_approx(Const.SHOT_PROFILE_LIFE[Const.Shot.NEEDLE], 0.9),
		"prototip rəqəmləri ortaq sabitlərdədir (ox 560/6/1.6, iynə 390/6/0.9)")


## Hər növün bir hərəkəti: −1 top, bir soyuma, bir geri təpmə — mərmi sayından asılı olmayaraq.
static func _test_cost_one_per_action() -> void:
	var counts := []
	for sp in Const.SPECIES_COUNT:
		var s := _duel(sp, 300.0)
		var a: Sim.GermState = s.germs[A_ID]
		var before := a.balls
		var fired := s._fire(a)
		counts.append(s.shots.size())
		_check(fired and before - a.balls == 1 and is_equal_approx(a.cooldown, Const.FIRE_COOLDOWN)
			and a.vel.is_equal_approx(Vector2.LEFT * Const.SHOT_RECOIL),
			"növ %d: hərəkət −1 top, bir soyuma, bir geri təpmə (%d → %d)" % [sp, before, a.balls])
	_check(counts == [1, 2, 1], "mərmilər: ox 1, iynə 2, damcı 1 (%s)" % [counts])


static func _test_needle_pair() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 300.0)
	s._fire(s.germs[A_ID])
	var a: Sim.ShotState = s.shots[0]
	var b: Sim.ShotState = s.shots[1]
	_check(absf(absf(a.dir.angle_to(b.dir)) - 2.0 * Const.NEEDLE_SPREAD) < 0.0001
		and absf(a.dir.angle() + b.dir.angle()) < 0.0001,
		"iki iynə nişan oxundan −7° və +7°")
	_check(a.volley == b.volley and a.volley > 0 and a.payload == 1 and b.payload == 1
		and is_equal_approx(a.speed, 390.0) and is_equal_approx(a.radius, 6.0),
		"iynələr bir qrupdadır, hərəsi +1, 390 px/s, 6 px")


## Yaxında iki iynə də dəyir (+2), uzaqda yan iynə biri (+1). Super payları hərəkət başına bir.
static func _test_needle_payloads() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 100.0)
	var b: Sim.GermState = s.germs[B_ID]
	var a: Sim.GermState = s.germs[A_ID]
	var before := b.balls
	s._fire(a)
	_fly(s)
	_check(b.balls == before + 2, "yaxın: iki iynə eyni hədəfə — cəmi +2 (%d → %d)" % [before, b.balls])
	_check(a.charge == Const.SUPER_ON_HIT and b.charge == Const.SUPER_ON_TAKEN,
		"iki iynə: atıcının superi +%d, qurbanınkı +%d — bir dəfə (%d, %d)"
			% [Const.SUPER_ON_HIT, Const.SUPER_ON_TAKEN, a.charge, b.charge])
	var hits := 0
	for e in s.events:
		if e.get("t") == "hit" and float(e["arg"]) > 0.5:
			hits += 1
			_check(Const.hit_payload(float(e["arg"])) == 1, "iynənin zərbə hadisəsi +1 deyir")
	_check(hits == 2, "iki iynə iki zərbə hadisəsi verir (%d)" % hits)

	# Uzaqda yalnız yuxarı iynə hədəfin mərkəzindən keçir.
	s = _duel(int(Const.Species.HELIOZOAN), 300.0)
	b = s.germs[B_ID]
	a = s.germs[A_ID]
	b.pos = a.pos + Vector2.from_angle(Const.NEEDLE_SPREAD) * 300.0
	before = b.balls
	var food0 := s.food.size()
	s._fire(a)
	_fly(s)
	_check(b.balls == before + 1, "uzaq: bir iynə dəyir — +1 (%d → %d)" % [before, b.balls])
	_check(s.food.size() == food0, "bir iynə dəyibsə, boşa çıxan ikinci qida YARATMIR")


## Hərəkətdən ən çoxu bir qida: iki iynə də boşa çıxsa (ömür, sıçrayış haqqı) qida birdir.
static func _test_volley_one_food() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 300.0)
	s.germs[B_ID].pos = Vector2(0.0, 900.0)
	s._fire(s.germs[A_ID])
	_fly(s)
	_check(s.food.size() == 1, "iki iynə boşa çıxdı — bir qida (%d)" % s.food.size())
	_check(s._volleys.is_empty(), "mərmilər bitəndə qrup silinir")
	# Şüşəyə yaxın: iynələr sıçrayış haqqını bitirir.
	s = _duel(int(Const.Species.HELIOZOAN), 300.0)
	var a: Sim.GermState = s.germs[A_ID]
	s.germs[B_ID].pos = Vector2(0.0, 900.0)
	a.pos = Vector2(Const.WORLD_RADIUS - 60.0, 0.0)
	s._fire(a)
	_fly(s)
	_check(s.food.size() == 1, "şüşədən sıçrayan iki iynə də bir qida verir (%d)" % s.food.size())


## Kövrək qabıq: iki iynə bir zərbə vurur.
static func _test_volley_one_crack() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 300.0)
	s.germs[B_ID].pos = Vector2(0.0, 900.0)
	var a: Sim.GermState = s.germs[A_ID]
	s.obstacles.append(Vector4(a.pos.x + 110.0, 0.0, 40.0, DishMap.Kind.BRITTLE))
	s._reset_walls()
	s._fire(a)
	_fly(s)
	_check(s.brittle_hp[0] == DishMap.BRITTLE_HP - 1,
		"iki iynə kövrək qabığa BİR zərbə vurur (can %d → %d)" % [DishMap.BRITTLE_HP, s.brittle_hp[0]])
	_check(s.food.size() == 1, "qabıqda qalan iki iynədən bir qida (%d)" % s.food.size())


## Ana hərəkət başına [constant Const.MOTHER_FEED] dolur — iki iynə də, damcı da.
static func _test_volley_mother_budget() -> void:
	for sp in [int(Const.Species.HELIOZOAN), int(Const.Species.AMOEBA)]:
		var s := _mothers_only()
		var i0 := s.mother_index[0]
		var o := s.obstacles[i0]
		var a := s.add_germ(A_ID, "A", 0, false, Const.species_from(sp))
		a.team = 1
		a.safe_t = 0.0
		a.drain_t = 1.0e9
		a.vel = Vector2.ZERO
		a.pos = Vector2(o.x, o.y) + Vector2(o.z + 230.0, 0.0)
		a.aim = PI
		var before := s.mother_balls[0]
		var fired := s._fire(a, -1.0, NAN, false, Vector2.INF, 230.0 - Const.LOB_AREA * 0.5)
		_fly(s)
		_check(fired and s.mother_balls[0] - before == Const.MOTHER_FEED and a.charge == Const.SUPER_ON_HIT,
			"növ %d: Ana hərəkətdən +%d alır, atıcı super payını bir dəfə (%d → %d)"
				% [sp, Const.MOTHER_FEED, before, s.mother_balls[0]])
		_check(s.food.is_empty(), "növ %d: Anaya girən hərəkət qida yaratmır" % sp)


## ANA HÜCEYRƏ dünyası, xəritədən yalnız iki Ana qalır — yuvanın divarları atəşi kəsməsin.
static func _mothers_only() -> Sim:
	var s := Sim.new()
	s.set_mode(Const.Mode.MOTHER)
	var keep: Array[Vector4] = []
	for o in s.obstacles:
		if int(o.w) == DishMap.Kind.MOTHER:
			keep.append(o)
	s.obstacles = keep
	s._reset_walls()
	for i in keep.size():
		s.mother_index[s.mother_team(i)] = i
	return s


## Nüvə hərəkət başına cəmi +2 çəki və bir təkan alır — iki iynə də, damcı da.
static func _test_volley_ball_budget() -> void:
	for sp in [int(Const.Species.HELIOZOAN), int(Const.Species.AMOEBA)]:
		var s := Sim.new()
		s.set_mode(Const.Mode.BALL)
		s.obstacles.clear()
		s._reset_walls()
		var a := s.add_germ(A_ID, "A", 0, false, Const.species_from(sp))
		a.team = 0
		a.safe_t = 0.0
		a.drain_t = 1.0e9
		a.vel = Vector2.ZERO
		var gap := 110.0 if sp == int(Const.Species.HELIOZOAN) else 240.0
		a.pos = Vector2(-gap, 0.0)
		a.aim = 0.0
		var fired := s._fire(a, -1.0, NAN, false, Vector2.INF, gap)
		_fly(s)
		var push := Const.BALL_SHOT_PUSH
		_check(fired and is_equal_approx(s.ball.weight, float(Const.BALL_WEIGHT + Const.SHOT_PAYLOAD))
			and absf(s.ball.vel.length() - push) < 1.0 and a.charge == Const.SUPER_ON_HIT,
			"növ %d: Nüvə hərəkətdən +%d çəki və bir təkan alır (çəki %.0f, sürət %.0f)"
				% [sp, Const.SHOT_PAYLOAD, s.ball.weight, s.ball.vel.length()])


## Trixosist iki iynəni dağıdır — qida birdir. Damcıya çatmır.
static func _test_tricho_pops_needles_once() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 60.0)
	var b: Sim.GermState = s.germs[B_ID]
	s._fire(s.germs[A_ID])
	s._super_trichocyst(b)
	_check(s.shots.is_empty() and s.food.size() == 1,
		"trixosist iki iynəni dağıdır — bir qida (%d qida, %d top)" % [s.food.size(), s.shots.size()])
	s = _duel(int(Const.Species.AMOEBA), 60.0)
	b = s.germs[B_ID]
	s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 300.0)
	s._super_trichocyst(b)
	_check(s.shots.size() == 1 and s.food.is_empty(), "havadakı damcıya trixosist çatmır")


## Atıcı partlasa da iynələr komandasını saxlayır: yoldaşdan keçir, rəqibə dəyir.
static func _test_dead_shooter_keeps_team() -> void:
	var s := _duel(int(Const.Species.HELIOZOAN), 200.0)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	a.team = 0
	b.team = 1
	var mate := s.add_germ(C_ID, "C", 2)
	mate.team = 0
	mate.safe_t = 0.0
	mate.vel = Vector2.ZERO
	mate.pos = Vector2(0.0, 0.0)
	var mate0 := mate.balls
	var before := b.balls
	s._fire(a)
	s.remove_germ(A_ID)
	_fly(s)
	_check(mate.balls == mate0 and b.balls == before + 2,
		"partlamış atıcının iynələri yoldaşdan keçir, rəqibə +2 (yoldaş %d, rəqib %d → %d)"
			% [mate.balls, before, b.balls])


## Damcı selik və kövrək qabığın üstündən keçir, qabığa toxunmur.
static func _test_lob_flies_over_cover() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	s.obstacles.append(Vector4(-30.0, 0.0, 60.0, DishMap.Kind.MUCUS))
	s.obstacles.append(Vector4(60.0, 0.0, 30.0, DishMap.Kind.BRITTLE))
	s._reset_walls()
	var b: Sim.GermState = s.germs[B_ID]
	var before := b.balls
	var fired := s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 400.0)
	_fly(s)
	_check(fired and b.balls == before + 2, "damcı örtüyün üstündən keçib +2 verir (%d → %d)" % [before, b.balls])
	_check(s.brittle_hp[1] == DishMap.BRITTLE_HP, "damcı kövrək qabığa toxunmur")


## Uçuşda yolundakı mikroba dəymir; düşmə anında oradan çəkilən də vurulmur (geri sarma yoxdur).
static func _test_lob_harmless_in_flight() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	var c := s.add_germ(C_ID, "C", 2)
	c.safe_t = 0.0
	c.vel = Vector2.ZERO
	c.pos = Vector2(0.0, 0.0)
	var c0 := c.balls
	var b: Sim.GermState = s.germs[B_ID]
	var b0 := b.balls
	s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 400.0)
	var ticks := 0
	while not s.shots.is_empty() and ticks < 60:
		# B xəbərdarlığı görüb düşmədən bir tick əvvəl sahədən çıxır.
		if s.shots[0].life <= DT * 1.5:
			b.pos = Vector2(200.0, 200.0)
		s._step_shots(DT)
		ticks += 1
	_check(c.balls == c0, "damcı uçuşda yolundakı mikroba dəymir")
	_check(b.balls == b0 and s.food.size() == 1,
		"xəbərdarlıqdan çəkilən vurulmur — damcı qidaya çevrilir (%d qida)" % s.food.size())
	_check(ticks == int(ceil(Const.LOB_FLIGHT / DT)),
		"damcı %.2f s-də düşür (%d tick)" % [Const.LOB_FLIGHT, ticks])


## Sahədə iki rəqib: yalnız biri — düşmə nöqtəsinə ən yaxın, bərabərdə kiçik id.
static func _test_lob_single_target() -> void:
	for tie in [false, true]:
		var s := _duel(int(Const.Species.AMOEBA), 400.0)
		var b: Sim.GermState = s.germs[B_ID]
		var c := s.add_germ(C_ID, "C", 2)
		c.safe_t = 0.0
		c.vel = Vector2.ZERO
		var land := Vector2(200.0, 0.0)
		b.pos = land + Vector2(0.0, -15.0 if tie else -10.0)
		c.pos = land + Vector2(0.0, 15.0 if tie else 20.0)
		var b0 := b.balls
		var c0 := c.balls
		s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 400.0)
		_fly(s)
		_check(b.balls == b0 + 2 and c.balls == c0,
			"damcı sahədəki TƏK rəqibə +2 (%s): B %d → %d, C %d → %d"
				% ["bərabər məsafə, kiçik id" if tie else "ən yaxın", b0, b.balls, c0, c.balls])


static func _test_lob_friendly_and_shield() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	a.team = 0
	b.team = 0
	var b0 := b.balls
	s._fire(a, -1.0, NAN, false, Vector2.INF, 400.0)
	_fly(s)
	_check(b.balls == b0 and s.food.size() == 1, "damcı yoldaşa dəymir")
	s = _duel(int(Const.Species.AMOEBA), 400.0)
	b = s.germs[B_ID]
	b.safe_t = 1.0
	b0 = b.balls
	s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 400.0)
	_fly(s)
	_check(b.balls == b0, "damcı doğuş qalxanlıya dəymir")


## Etibarsız düşmə yeri: atəş açılmır, top xərclənmir, soyuma başlamır.
static func _test_lob_invalid_costs_nothing() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	var a: Sim.GermState = s.germs[A_ID]
	a.pos = Vector2(Const.WORLD_RADIUS - 150.0, 0.0)
	var before := a.balls
	var fired := s._fire(a, -1.0, NAN, false, Vector2.INF, 300.0)
	_check(not fired and a.balls == before and a.cooldown == 0.0 and s.shots.is_empty(),
		"şüşədən kənara düşən damcı atılmır — top və soyuma qalır")
	s.obstacles.append(Vector4(0.0, 0.0, 60.0, DishMap.Kind.MUCUS))
	s.obstacles.append(Vector4(0.0, 300.0, 60.0, DishMap.Kind.BUSH))
	s._reset_walls()
	a.pos = Vector2(-300.0, 0.0)
	a.aim = 0.0
	fired = s._fire(a, -1.0, NAN, false, Vector2.INF, 300.0)
	_check(not fired and a.balls == before, "seliyin içinə düşən damcı atılmır")
	_check(s.lob_valid(Vector2(0.0, 300.0)), "kola düşmək olar — o, bərk maneə deyil")
	s.broken[0] = DishMap.Wall.GONE
	_check(s.lob_valid(Vector2.ZERO), "dağılmış maneənin yerinə düşmək olar")


## Damcı Nüvəyə və rəqibin Anasına düşə bilir — [method Sim._land_lob]-un ardıcıllığı.
static func _test_lob_objects() -> void:
	var s := _mothers_only()
	var own := s.obstacles[s.mother_index[0]]
	var a := s.add_germ(A_ID, "A", 0, false, Const.Species.AMOEBA)
	a.team = 0
	a.safe_t = 0.0
	a.drain_t = 1.0e9
	a.vel = Vector2.ZERO
	a.pos = Vector2(own.x, own.y) + Vector2(own.z + 260.0, 0.0)
	a.aim = PI
	var before := s.mother_balls[0]
	s._fire(a, -1.0, NAN, false, Vector2.INF, 260.0 - Const.LOB_AREA * 0.5)
	_fly(s)
	_check(s.mother_balls[0] == before and s.food.size() == 1,
		"öz Anasının yanına düşən damcı onu doldurmur — qida olur")


## Damcı geri sarılmır: zərbə düşmə anındakı mövqelərədir.
static func _test_lob_no_rewind() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	s.lag_comp = true
	s.tick = 100
	s._fire(s.germs[A_ID], 90.0, NAN, false, Vector2.INF, 300.0)
	_check(s.shots[0].rewind == 0.0, "damcının geri sarması sıfırdır")
	s = _duel(int(Const.Species.CILIATE), 400.0)
	s.lag_comp = true
	s.tick = 100
	s._fire(s.germs[A_ID], 90.0)
	_check(s.shots[0].rewind > 0.0, "oxun geri sarması qalır (atıcının xeyrinə)")


## Amöbün superi: miniqan düz top atır, pulsuz — damcı və iynə deyil.
static func _test_minigun_profile() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	var a: Sim.GermState = s.germs[A_ID]
	a.super_t = Const.CYST_TIME
	var before := a.balls
	s._fire(a, -1.0, NAN, true)
	_check(s.shots.size() == 1 and s.shots[0].profile == Const.Shot.MINIGUN
		and not s.shots[0].is_lob() and a.balls == before
		and is_equal_approx(a.cooldown, Const.MINIGUN_COOLDOWN),
		"miniqan: bir düz top, pulsuz, öz dövrü ilə")


## Damcının məsafəsi paketdə gedir, NaN/INF atılır, köhnə paket məsafəsiz oxunur.
static func _test_input_range() -> void:
	var inp := Sim.PlayerInput.make(5, Vector2.ZERO, 0.4, true, false, -1.0)
	inp.fire_range = 333.0
	var back := Sim.PlayerInput.from_array(inp.to_array())
	_check(is_equal_approx(back.fire_range, 333.0) and back.view_tick < 0.0 and not back.fire_from.is_finite(),
		"damcının məsafəsi paketdə gedir (%.1f)" % back.fire_range)
	inp.shot = true
	inp.view_tick = 12.0
	inp.fire_from = Vector2(4.0, -2.0)
	back = Sim.PlayerInput.from_array(inp.to_array())
	_check(is_equal_approx(back.fire_range, 333.0) and back.fire_from.is_equal_approx(Vector2(4.0, -2.0))
		and is_equal_approx(back.view_tick, 12.0), "məsafə başlanğıc və tick ilə birlikdə gedir")
	var plain := Sim.PlayerInput.make(6, Vector2.ZERO, 0.0, true, false, 3.0)
	_check(plain.to_array().size() == 6 and is_nan(Sim.PlayerInput.from_array(plain.to_array()).fire_range),
		"məsafəsiz atəşdə sahə getmir (%d sahə)" % plain.to_array().size())
	_check(is_nan(Sim.PlayerInput.from_array([1, 0.0, 0.0, 0.0, 17, -1.0, NAN, NAN, INF]).fire_range)
		and is_nan(Sim.PlayerInput.from_array([1, 0.0, 0.0, 0.0, 17, -1.0, NAN, NAN, NAN]).fire_range),
		"şəbəkədən gələn NaN/INF məsafə atılır")
	_check(is_nan(Sim.PlayerInput.from_array([1, 0.0, 0.0, 0.0, 1, 2.0]).fire_range),
		"köhnə client-in paketi məsafəsiz oxunur — server sabit məsafə götürür")


## İki paket bir tick-də: məsafə atəşlə köçür; damcı məhz o məsafəyə düşür.
static func _test_merge_keeps_range() -> void:
	var world := SimTest._quiet_world(61)
	var g := world.add_player(A_ID, "A", Const.Species.AMOEBA)
	g.balls = Const.START_BALLS
	g.pos = Vector2(-200.0, SimTest.LANE_Y)
	g.vel = Vector2.ZERO
	var fire := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)
	fire.fire_range = 250.0
	world.accept_input(A_ID, fire.to_array())
	world.accept_input(A_ID, Sim.PlayerInput.make(2, Vector2.ZERO, 0.0, false).to_array())
	world.tick(Const.TICK_DELTA)
	var lob: Sim.ShotState = null
	for s in world.sim.shots:
		if s.owner_id == A_ID:
			lob = s
	_check(lob != null and lob.is_lob() and absf(lob.origin.distance_to(lob.target) - 250.0) < 0.01,
		"paketlər birləşəndə damcının məsafəsi atəşlə köçür (%s)"
			% ("%.1f" % lob.origin.distance_to(lob.target) if lob != null else "atılmadı"))


## Proqnoz və server eyni profillə uçur: ox və iki iynə şüşədən eyni nöqtədə sıçrayır.
static func _test_prediction_profiles() -> void:
	for sp in [int(Const.Species.CILIATE), int(Const.Species.HELIOZOAN)]:
		var s := _duel(sp, 300.0)
		var a: Sim.GermState = s.germs[A_ID]
		s.germs[B_ID].pos = Vector2(0.0, 900.0)
		a.pos = Vector2(Const.WORLD_RADIUS - 300.0, 40.0)
		s._fire(a)
		var start := s.shots[0].pos
		var profile := s.shots[0].profile
		var server_hits := []
		for i in 60:
			s.events.clear()
			s._step_shots(DT)
			for e in s.events:
				if e.get("t") == "hit":
					server_hits.append(Vector2(e["pos"]))
		var p := ShotPrediction.new()
		p.wall = s.wall_radius
		p.spawn_volley(start, Vector2.RIGHT, 0.0, -1.0, profile)
		var ghost_hits := []
		var now := 0.0
		for i in 150:
			now += 1.0 / 60.0
			for c in p.step(1.0 / 60.0, now, s.obstacles, s.broken, []):
				if int(c["kind"]) == ShotPrediction.Contact.BOUNCE:
					ghost_hits.append(Vector2(c["pos"]))
		var worst := INF if server_hits.size() != ghost_hits.size() or server_hits.is_empty() else 0.0
		if worst == 0.0:
			for h in server_hits:
				var best := INF
				for q in ghost_hits:
					best = minf(best, (h as Vector2).distance_to(q))
				worst = maxf(worst, best)
		_check(worst < 0.5, "növ %d: proqnoz serverlə eyni yerdə sıçrayır (%d/%d, %.3f px)"
			% [sp, ghost_hits.size(), server_hits.size(), worst])


## Proqnozun damcısı serverinki ilə eyni tick-də, eyni nöqtəyə düşür.
static func _test_prediction_lob() -> void:
	var s := _duel(int(Const.Species.AMOEBA), 400.0)
	s.germs[B_ID].pos = Vector2(0.0, 900.0)
	s._fire(s.germs[A_ID], -1.0, NAN, false, Vector2.INF, 300.0)
	var srv: Sim.ShotState = s.shots[0]
	var ticks := 0
	while not s.shots.is_empty() and ticks < 60:
		s._step_shots(DT)
		ticks += 1
	var p := ShotPrediction.new()
	var g := p.spawn_lob(srv.origin, srv.target, 0.0)
	var land := Vector2.INF
	var when := -1.0
	var now := 0.0
	for i in 120:
		now += 1.0 / 60.0
		for c in p.step(1.0 / 60.0, now, s.obstacles, s.broken, []):
			if int(c["kind"]) == ShotPrediction.Contact.LAND:
				land = c["pos"]
				when = now
	_check(land.is_finite() and land.distance_to(srv.target) < 0.01,
		"proqnozun damcısı serverin nöqtəsinə düşür")
	_check(when >= float(ticks) * DT - 0.0001 and when <= float(ticks + 1) * DT,
		"proqnozun damcısı serverlə eyni tick-də düşür (%.3f s, server %d tick)" % [when, ticks])
	# Serverin sətri təsdiq vaxtının içində gəlir ([constant ShotPrediction.CLAIM_GRACE]).
	var q := ShotPrediction.new()
	var h := q.spawn_lob(srv.origin, srv.target, 0.0)
	_check(q.claim(77, (srv.target - srv.origin).normalized(), 0.2) == null
		and q.claim_lob(78, srv.target + Vector2(3.0, 0.0), 0.2) == h and h.sid == 78 and g.alive == false,
		"damcı istiqamətlə yox, düşmə nöqtəsi ilə tanınır")


## Bir atəşin iki iynəsi serverin BİR atəş hadisəsini birlikdə udur.
static func _test_prediction_volley() -> void:
	var p := ShotPrediction.new()
	var pair := p.spawn_volley(Vector2.ZERO, Vector2.RIGHT, 0.0, -1.0, Const.Shot.NEEDLE)
	_check(pair.size() == 2 and pair[0].volley == pair[1].volley, "proqnozda iki iynə bir qrupdadır")
	_check(p.take_unseen_fire(0.1, 0.6) and not p.take_unseen_fire(0.1, 0.6),
		"iki iynə serverin bir atəş hadisəsini udur — növbəti atəşinkini yox")


## Öz damcının server zərbəsi dərhal göstərilir və "yalnız serverin saydığı" sayılmır.
##
## Proqnoz damcının kimə dəydiyini demir ([constant ShotPrediction.Contact.LAND]); zərbə
## serverin hadisəsi ilə gəlir. O hadisə interpolyasiyanı gözləməməli və ölçüdə proqnozun
## qaçırdığı dəymə kimi görünməməlidir.
static func _test_own_lob_hit_shown() -> void:
	for early in [false, true]:
		var a := Arena.new()
		a.my_color = 3
		var land := Vector2(120.0, 40.0)
		if early:
			# Server proqnozdan TEZ dedi: damcı hələ havadadır.
			a._own_shots.spawn_lob(Vector2(-200.0, 40.0), land, a._clock)
		else:
			a._note_lob_landing(land)
		a._queue_events([[Const.EvKind.HIT, land.x, land.y, Const.hit_arg(5, 2), 3]], 10.0)
		var fx: Dictionary = a._fx_queue[-1] if not a._fx_queue.is_empty() else {}
		_check(not fx.is_empty() and float(fx["at"]) == -INF
			and int(a.hit_stats["lob_hits"]) == 1 and int(a.hit_stats["server_only"]) == 0,
			"öz damcının server zərbəsi dərhal göstərilir, \"yalnız server\" sayılmır (%s)"
				% ("damcı havada" if early else "damcı düşüb"))
		a.free()
	# Başqa yerdəki (damcısız) zərbə əvvəlki kimi "yalnız server"dir.
	var b := Arena.new()
	b.my_color = 3
	b.my_id = A_ID
	b._init_prediction()
	b._note_lob_landing(Vector2(500.0, 0.0))
	b._queue_events([[Const.EvKind.HIT, 120.0, 40.0, Const.hit_arg(5, 2), 3]], 10.0)
	_check(int(b.hit_stats["lob_hits"]) == 0 and int(b.hit_stats["server_only"]) == 1,
		"damcısız yerdəki öz zərbəsi damcı sayılmır")
	b.free()


## Damcının sətri: xəbərdarlıq hamıya gedir, başlanğıc və rəng yalnız atıcını görənə.
static func _test_lob_row_privacy() -> void:
	var world := SimTest._quiet_world(62)
	var a := world.add_player(A_ID, "A", Const.Species.AMOEBA)
	var b := world.add_player(B_ID, "B", Const.Species.CILIATE)
	var bush: Array[Vector4] = [Vector4(-200.0, 0.0, 90.0, DishMap.Kind.BUSH)]
	world.sim.obstacles = bush
	world.sim._reset_walls()
	for g in [a, b]:
		g.safe_t = 0.0
		g.vel = Vector2.ZERO
		g.balls = Const.START_BALLS
	a.pos = Vector2(-200.0, 0.0)
	b.pos = Vector2(100.0, 0.0)
	a.aim = 0.0
	var fire := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)
	fire.fire_range = 300.0
	world.accept_input(A_ID, fire.to_array())
	world.tick(Const.TICK_DELTA)
	var hid := _lob_row(world.snapshot_for(B_ID))
	var own := _lob_row(world.snapshot_for(A_ID))
	_check(not hid.is_empty() and float(hid[Const.SF.LIFE]) > Const.LOB_FLIGHT * 0.8
		and Vector2(float(hid[Const.SF.X]), float(hid[Const.SF.Y])).distance_to(b.pos) < 6.0,
		"damcının düşmə nöqtəsi və vaxtı qurbana əvvəlcədən gedir")
	_check(not hid.is_empty() and int(hid[Const.SF.COLOR]) == -1
		and is_equal_approx(float(hid[Const.SF.DX]), float(hid[Const.SF.X]))
		and is_equal_approx(float(hid[Const.SF.DY]), float(hid[Const.SF.Y])),
		"kolda gizlənən atıcının yeri və rəngi xəbərdarlıqda getmir")
	_check(not own.is_empty() and int(own[Const.SF.COLOR]) == a.color
		and Vector2(float(own[Const.SF.DX]), float(own[Const.SF.DY])).distance_to(a.pos) < 20.0,
		"atıcının öz sətrində başlanğıc və rəng var")
	# Atıcı kolsuz və görünəndə yol açıqdır.
	var none: Array[Vector4] = []
	world.sim.obstacles = none
	world.sim._reset_walls()
	world.sim.clear_shots()
	a.cooldown = 0.0
	fire = Sim.PlayerInput.make(2, Vector2.ZERO, 0.0, true)
	fire.fire_range = 300.0
	world.accept_input(A_ID, fire.to_array())
	world.tick(Const.TICK_DELTA)
	var seen := _lob_row(world.snapshot_for(B_ID))
	_check(not seen.is_empty() and int(seen[Const.SF.COLOR]) == a.color
		and Vector2(float(seen[Const.SF.DX]), float(seen[Const.SF.DY])).distance_to(a.pos) < 20.0,
		"görünən atıcının damcısının yolu göstərilir")


static func _lob_row(snap: Array) -> Array:
	for row in Const.unpack_shots(snap[Const.Snap.SHOTS]):
		if Const.meta_profile(float(row[Const.SF.META])) == Const.Shot.LOB:
			return row
	return []


## Sıx döyüş: 10 mikrob, onlarla top və damcı — paket MTU-ya sığır, qurbana düşən damcı
## büdcə kəsiləndə də paketdədir.
static func _test_snapshot_with_lobs() -> void:
	var world := World.new(80, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var me: Sim.GermState = world.sim.germs[A_ID]
	me.capacity = Const.MAX_CAPACITY
	me.pos = Vector2.ZERO
	for gid in world.sim.germs:
		if gid != A_ID:
			world.sim.germs[gid].pos = Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
	world.sim.clear_shots()
	for i in Const.SHOT_SEND_MAX * 3:
		var s := Sim.ShotState.new()
		s.id = 10000 + i
		s.owner_id = A_ID + 1
		s.color = i % 8
		s.profile = Const.Shot.NEEDLE if i % 2 == 0 else Const.Shot.DART
		s.pos = Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
		s.dir = Vector2.RIGHT
		world.sim.shots.append(s)
	# Qurbana (baxana) düşən damcı — ən uzaqda başlayıb, ən sonda siyahıda.
	var lob := Sim.ShotState.new()
	lob.id = 99999
	lob.owner_id = 12345
	lob.profile = Const.Shot.LOB
	lob.origin = Vector2(900.0, 0.0)
	lob.target = Vector2(10.0, 0.0)
	lob.pos = Vector2(880.0, 0.0)
	lob.life = Const.LOB_FLIGHT
	lob.flight = Const.LOB_FLIGHT
	world.sim.shots.append(lob)
	world.sim.events.clear()
	for i in Const.EVENT_SEND_MAX * 3:
		world.sim.events.append({"t": "hit", "pos": Vector2(float(i), 0.0), "arg": 65.0, "color": 0})
	world._build_frame()
	var snap := world.snapshot_for(A_ID)
	var size := var_to_bytes(snap).size()
	_check(size < Const.MTU_SAFE, "damcılı ən pis snapshot MTU-ya sığır: %d bayt (hədd %d)" % [size, Const.MTU_SAFE])
	var found := false
	for row in Const.unpack_shots(snap[Const.Snap.SHOTS]):
		found = found or int(row[Const.SF.ID]) == 99999
	_check(found and world.shots_cut > 0,
		"büdcə kəsiləndə də baxana düşən damcı paketdədir (%d top atıldı)" % world.shots_cut)


static func _test_hit_arg_payload() -> void:
	var ok := true
	for c in 12:
		for p in [1, 2]:
			var arg := Const.hit_arg(c, p)
			ok = ok and Const.hit_victim(arg) == c and Const.hit_payload(arg) == p and arg > 0.5
	_check(ok and Const.hit_victim(0.0) == -1 and Const.hit_payload(0.0) == 0,
		"zərbə hadisəsi qurbanı və yükü (+1/+2) daşıyır, sıçrayış 0 qalır")


## Qaydaların versiyası: client rejim ədədində göndərir, server join info-da qaytarır.
static func _test_rules_version() -> void:
	var wire := Const.mode_wire(int(Const.Mode.BALL))
	_check(Const.mode_from(wire) == Const.Mode.BALL and Const.wire_rules(wire) == Const.RULES
		and Const.wire_rules(int(Const.Mode.BALL)) == 0,
		"rejim ədədi qaydalar versiyasını daşıyır, köhnə client-də 0")
	var world := SimTest._quiet_world(63)
	world.add_player(A_ID, "A")
	_check(int(world.join_info_for(A_ID).get("rules", 0)) == Const.RULES,
		"server join info-da qaydalar versiyasını deyir")
	_check(Const.SHOT_STRIDE * 4 == Const.SHOT_BYTES, "top sətrinin bayt qiyməti stride ilə uyğundur")


## Botların döyüş məsafəsi növdən: kirpikli uzaq, ayaqlı yaxın, amöb ortada.
static func _test_bot_ranges() -> void:
	var r := Bot.SPECIES_RANGE
	_check(r[int(Const.Species.CILIATE)] > r[int(Const.Species.AMOEBA)]
		and r[int(Const.Species.AMOEBA)] > r[int(Const.Species.HELIOZOAN)]
		and r[int(Const.Species.HELIOZOAN)] < Const.shot_reach(Const.Shot.NEEDLE)
		and r[int(Const.Species.AMOEBA)] >= Const.LOB_MIN and r[int(Const.Species.AMOEBA)] <= Const.LOB_MAX,
		"botun məsafəsi: kirpikli %.0f > amöb %.0f > ayaqlı %.0f, hər biri öz atəşinin çatdığı yerdə"
			% [r[0], r[2], r[1]])


## Amöb botu selik arxasındakı rəqibə damcı atır (xətt lazım deyil), koldakına atmır.
static func _test_bot_lob_cover() -> void:
	var s := Sim.new()
	var wall: Array[Vector4] = [Vector4(0.0, 0.0, 50.0, DishMap.Kind.MUCUS)]
	s.obstacles = wall
	s._reset_walls()
	var me := s.add_germ(A_ID, "A", 0, true, Const.Species.AMOEBA)
	var foe := s.add_germ(B_ID, "B", 1)
	for g in [me, foe]:
		g.safe_t = 0.0
		g.vel = Vector2.ZERO
		g.age = 100.0
	me.pos = Vector2(-150.0, 0.0)
	foe.pos = Vector2(150.0, 0.0)
	me.balls = 8
	var bot := Bot.new(A_ID, 1.0, 5)
	var inp := bot.think(s, DT)
	_check(inp.fire and not s.has_line_of_sight(me.pos, foe.pos)
		and absf(inp.fire_range - 300.0) < 40.0,
		"amöb botu selik arxasına damcı atır (məsafə %.0f)" % inp.fire_range)
	s.obstacles.append(Vector4(150.0, 0.0, 80.0, DishMap.Kind.BUSH))
	s._reset_walls()
	inp = bot.think(s, DT)
	_check(not inp.fire, "amöb botu kolda gizlənənə damcı atmır")
