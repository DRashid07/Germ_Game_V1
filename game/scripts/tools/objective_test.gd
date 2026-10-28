class_name ObjectiveTest
extends RefCounted
## Obyekt rejimlərinin (ANA HÜCEYRƏ, YAŞ ADA, NÜVƏ TOPU) headless testləri — [SimTest]-in
## içindən işləyir, eyni sayğacla. Tək başına:
##
##   Godot_v4.7.2.exe --headless --path game -- --objtest
##
## Qaydalar design/MODES.md §16-dadır. Hər test bir qaydanı yoxlayır; tam matçlar isə
## botların obyektə xidmət etdiyini ölçür — matç obyektlə bitirmi, vaxtla yox.

const A_ID := 101
const B_ID := 202
const DT := Const.TICK_DELTA
const MODES := [Const.Mode.MOTHER, Const.Mode.ISLAND, Const.Mode.BALL]


static func run() -> int:
	var fail0 := SimTest._fail
	# `--objtest --probe [--mode N] [--seeds K]` — balans ölçüsü, testsiz.
	var args := OS.get_cmdline_user_args()
	if args.has("--probe"):
		probe(args)
		return 0
	print("\n----- Obyekt rejimləri -----")
	_test_mode_table()
	_test_old_modes_untouched()
	_test_maps_fit()
	_test_mother_nest()
	_test_spawn_bases()
	_test_mother_feed()
	_test_mother_suck()
	_test_mother_burst_ends()
	_test_mother_overtime()
	_test_island_path()
	_test_island_scoring()
	_test_island_dry_arsenal()
	_test_island_food_dries()
	_test_ball_one_way_push()
	_test_ball_squeeze()
	_test_ball_shot_and_pop()
	_test_ball_goal_and_wall()
	_test_ball_match_flow()
	_test_respawn()
	_test_match_row()
	_test_prediction_geometry()
	_test_aim_path_objects()
	_test_snapshot_fits()
	_test_client_rows()
	_test_team_result()
	_test_team_bots()
	# `--quick` — tam botlu matçlar (testin ən uzun hissəsi) atlanır.
	if not args.has("--quick"):
		_test_full_matches()
	return SimTest._fail - fail0


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


## Dünya qurulur, insan girir, sayım keçir — matç oynanır.
static func _playing(mode: int, seed := 7) -> World:
	var w := World.new(500 + mode, mode)
	w.sim.rng.seed = seed
	w.add_player(A_ID, "A")
	var guard := 0
	while w.phase != Const.Phase.PLAYING and guard < 400:
		w.tick(DT)
		guard += 1
	return w


## Botları dayandırır və hamını meydanın kənarına düzür — qayda testi təmiz getsin.
static func _freeze(w: World, y := -560.0) -> void:
	w._bots.clear()
	w._inputs.clear()
	w.sim.shots.clear()
	var xs := [-300.0, -200.0, -100.0, 100.0, 200.0, 300.0]
	var i := 0
	for gid in w.sim.germs:
		var g: Sim.GermState = w.sim.germs[gid]
		g.pos = Vector2(xs[i % xs.size()], y)
		g.vel = Vector2.ZERO
		g.safe_t = 999.0
		i += 1


static func _shot(sim: Sim, owner: int, team: int, at: Vector2, dir: Vector2) -> Sim.ShotState:
	var s := Sim.ShotState.new()
	s.id = 900000 + sim.shots.size()
	s.owner_id = owner
	s.team = team
	s.color = 3
	s.pos = at
	s.dir = dir.normalized()
	s.life = Const.SHOT_LIFETIME
	sim.shots.append(s)
	return s


static func _test_mode_table() -> void:
	_check(Const.team_size(Const.Mode.MOTHER) == 3 and Const.mode_capacity(Const.Mode.MOTHER) == 6,
		"ANA HÜCEYRƏ 3v3")
	_check(Const.team_size(Const.Mode.ISLAND) == 3 and Const.mode_capacity(Const.Mode.ISLAND) == 6,
		"YAŞ ADA 3v3")
	_check(Const.team_size(Const.Mode.BALL) == 2 and Const.mode_capacity(Const.Mode.BALL) == 4,
		"NÜVƏ TOPU 2v2")
	var ok := true
	for m in MODES:
		ok = ok and Const.is_team_mode(m) and Const.is_objective_mode(m) \
			and Const.mode_from(int(m)) == m and not Const.mode_name(m).is_empty()
	_check(ok, "obyekt rejimləri komandalıdır, adı var, şəbəkədən oxunur")
	_check(not Const.is_objective_mode(Const.Mode.DUO) and not Const.is_objective_mode(Const.Mode.TRIO),
		"CÜT və ÜÇLÜK obyekt rejimi deyil")


## Köhnə rejimlər yeni sistemin altında eyni qalır: qab, xəritə, matç sətri.
static func _test_old_modes_untouched() -> void:
	var s := Sim.new()
	_check(s.wall_radius == Const.WORLD_RADIUS and s.ball == null and s.mother_index[0] < 0,
		"standart Sim: 1200-lük qab, Nüvə və Ana yoxdur")
	var ok := true
	for m in [Const.Mode.ENDLESS, Const.Mode.SOLO, Const.Mode.DUO, Const.Mode.TRIO]:
		var t := Sim.new()
		t.set_mode(m)
		ok = ok and t.wall_radius == Const.WORLD_RADIUS and t.obstacles == DishMap.obstacles() \
			and Const.wet_circle(m, 100.0) == Vector3(0.0, 0.0, Const.dish_radius(m, 100.0))
	_check(ok, "köhnə rejimlərin qabı, xəritəsi və yaş sahəsi dəyişmir")
	var w := World.new(77, Const.Mode.SOLO)
	w.add_player(A_ID, "A")
	w.tick(DT)
	_check((w.snapshot_for(A_ID)[Const.Snap.MATCH] as Array).size() == Const.MF_BASE,
		"köhnə rejimin matç sətri %d sahədir (köhnə client üçün)" % Const.MF_BASE)


static func _test_maps_fit() -> void:
	for m in MODES:
		var s := Sim.new()
		s.set_mode(m)
		var wall := Const.wall_radius(m)
		var outside := 0
		var overlap := 0
		for i in s.obstacles.size():
			var o := s.obstacles[i]
			if Vector2(o.x, o.y).length() + o.z > wall + 0.5:
				outside += 1
			for j in range(i + 1, s.obstacles.size()):
				var p := s.obstacles[j]
				if Vector2(o.x, o.y).distance_to(Vector2(p.x, p.y)) < o.z + p.z:
					overlap += 1
		_check(not s.obstacles.is_empty() and outside == 0 and overlap == 0,
			"%s: %d maneə, hamısı şüşənin içində, üst-üstə düşmür" % [Const.mode_name(m), s.obstacles.size()])
		# Qabın ortası açıqdır — Nüvə və ada oradan başlayır.
		_check(DishMap.is_free_in(s.obstacles, wall, Vector2.ZERO, 60.0),
			"%s: qabın mərkəzi boşdur" % Const.mode_name(m))
	# Rejim düzümü qlobal düzümə toxunmur.
	var keep := DishMap.obstacles().duplicate()
	DishMap.obstacles_for(Const.LAYOUT_BALL)
	_check(DishMap.obstacles() == keep, "rejim düzümü ümumi xəritə keşini pozmur")


## ANA-nın yuvası: ağızlar açıqdır, arxa qapıdan yalnız amöb keçir.
static func _test_mother_nest() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.MOTHER)
	_check(s.mother_index[0] >= 0 and s.mother_index[1] >= 0
			and s.mother_team(s.mother_index[0]) == 0 and s.mother_team(s.mother_index[1]) == 1,
		"iki Ana var, qərbdəki komanda 0-ındır")
	_check(s.mother_balls[0] == Const.MOTHER_START and s.mother_balls[1] == Const.MOTHER_START,
		"Analar %d topla başlayır" % Const.MOTHER_START)
	# Ağız: tıxac ilə yan selik arasındakı boşluq.
	var plug := Vector4(420.0, 0.0, 72.0, 0.0)
	var cheek := Vector4(480.0, 215.0, 64.0, 0.0)
	var mouth := Vector2(plug.x, plug.y).distance_to(Vector2(cheek.x, cheek.y)) - plug.z - cheek.z
	var big := Const.germ_radius(Const.MAX_CAPACITY) * 2.0
	_check(mouth > Const.BASE_RADIUS * 2.0 + 20.0,
		"yuvanın ağzı %.0f px — başlanğıc mikrob rahat keçir" % mouth)
	# Arxa qapı: arxa selik ilə şüşə arasında.
	var back := Const.MOTHER_WALL - (Vector2(590.0, 328.0).length() + 75.0)
	var amoeba := Const.germ_radius(13) * 2.0 * Const.SPECIES_BODY[Const.Species.AMOEBA]
	var ciliate := Const.germ_radius(Const.START_CAPACITY) * 2.0 * Const.SPECIES_BODY[Const.Species.CILIATE]
	_check(back >= amoeba and back < ciliate,
		"arxa qapı %.0f px: amöb (%.0f) keçir, kirpikli (%.0f) keçmir" % [back, amoeba, ciliate])
	_check(mouth < big, "ağız ən iri mikrob üçün dardır (%.0f < %.0f)" % [mouth, big])


static func _test_spawn_bases() -> void:
	for m in MODES:
		var bad_side := 0
		var stuck := 0
		var counts := [0, 0]
		var w := World.new(600 + m, m)
		w.sim.rng.seed = 11
		w.add_player(A_ID, "A")
		w.tick(DT)
		for gid in w.sim.germs:
			var g: Sim.GermState = w.sim.germs[gid]
			if g.team == 0 or g.team == 1:
				counts[g.team] += 1
			if (g.team == 0) != (g.pos.x < 0.0):
				bad_side += 1
			if not DishMap.is_free_in(w.sim.obstacles, w.sim.wall_radius, g.pos, g.radius() * 0.9):
				stuck += 1
		_check(w.sim.germs.size() == Const.mode_capacity(m)
				and counts[0] == Const.team_size(m) and counts[1] == Const.team_size(m),
			"%s: %d+%d mikrob, komandalar bərabər" % [Const.mode_name(m), counts[0], counts[1]])
		_check(bad_side == 0 and stuck == 0,
			"%s: hamı öz yarısında, maneədən kənarda doğulur (yan %d, ilişən %d)"
				% [Const.mode_name(m), bad_side, stuck])


static func _test_mother_feed() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.MOTHER)
	var g := s.add_germ(A_ID, "A", 0)
	g.team = 0
	g.pos = Vector2(-300.0, -560.0)
	var charge0 := g.charge
	# Komanda 0-ın topu komanda 1-in Anasına (x = +650): tıxacla Ananın arasından.
	_shot(s, A_ID, 0, Vector2(520.0, 0.0), Vector2.RIGHT)
	for i in 10:
		s.step({}, DT)
	_check(s.mother_balls[1] == Const.MOTHER_START + Const.MOTHER_FEED and s.shots.is_empty(),
		"rəqibin Anası topu udur: %d → %d" % [Const.MOTHER_START, s.mother_balls[1]])
	_check(g.charge > charge0, "Anaya dəymə atana super doldurur")
	# Öz Anası topu sıçradır (iki tick: geri dönən top tıxaca çatmamış yoxlanılır).
	var own := _shot(s, A_ID, 1, Vector2(530.0, 0.0), Vector2.RIGHT)
	for i in 2:
		s.step({}, DT)
	_check(s.mother_balls[1] == Const.MOTHER_START + Const.MOTHER_FEED and s.shots.has(own)
			and own.dir.x < 0.0,
		"öz Anan topu udmur, sıçradır (dost atəşi yoxdur)")


static func _test_mother_suck() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.MOTHER)
	var g := s.add_germ(A_ID, "A", 0)
	g.team = 0
	g.safe_t = 0.0
	var mo := s.obstacles[s.mother_index[0]]
	g.pos = Vector2(mo.x + mo.z + g.radius() + 4.0, 0.0)
	g.balls = 4
	var before := s.mother_balls[0]
	for i in int(1.0 / DT):
		s.step({}, DT)
	var took := before - s.mother_balls[0]
	_check(took >= 2 and took <= 3, "öz Anana toxunanda ondan top əmirsən (1 s-də %d)" % took)

	# Ana 30%-dən boşdursa əmmək olmur.
	s.mother_balls[0] = int(Const.MOTHER_CAP * Const.MOTHER_SUCK_MIN)
	g.balls = 4
	for i in int(1.0 / DT):
		s.step({}, DT)
	_check(s.mother_balls[0] == int(Const.MOTHER_CAP * Const.MOTHER_SUCK_MIN),
		"boş Anadan əmmək olmur")

	# Əmmək heç vaxt partlatmır — tutumun bir topundan aşağıda dayanır.
	s.mother_balls[0] = Const.MOTHER_START
	g.balls = g.capacity - 1
	for i in int(2.0 / DT):
		s.step({}, DT)
	_check(s.germs.has(A_ID) and g.balls <= g.capacity - 1, "əmmək tutumu keçmir")

	# Rəqibin Anasından əmmək olmur.
	var e := s.add_germ(B_ID, "B", 1)
	e.team = 1
	e.safe_t = 0.0
	e.pos = Vector2(mo.x, mo.z + e.radius() + 4.0)
	e.balls = 4
	var m0 := s.mother_balls[0]
	for i in int(1.0 / DT):
		s.step({}, DT)
	_check(s.mother_balls[0] >= m0 - 3 and e.balls <= 4, "rəqibin Anasından əmmək olmur")

	# Proqnoz əmmir — top sayı serverin sözüdür.
	var p := Sim.new()
	p.set_mode(Const.Mode.MOTHER)
	var q := p.add_germ(A_ID, "A", 0)
	q.team = 0
	q.pos = g.pos
	q.balls = 4
	for i in 30:
		p.step_movement({}, DT)
	_check(p.mother_balls[0] == Const.MOTHER_START and q.balls == 4, "proqnoz Anadan əmmir")


static func _test_mother_burst_ends() -> void:
	var w := _playing(Const.Mode.MOTHER)
	_freeze(w)
	w.sim.mother_balls[1] = Const.MOTHER_CAP
	_shot(w.sim, A_ID, 0, Vector2(520.0, 0.0), Vector2.RIGHT)
	var guard := 0
	while w.phase == Const.Phase.PLAYING and guard < 30:
		w.tick(DT)
		guard += 1
	_check(w.phase == Const.Phase.OVER and w.obj_winner == 0 and not w.timed_out,
		"rəqibin Anası partlayanda matç dərhal bitir, qalib komanda 0")
	var res: Dictionary = {}
	for r in w.pending_results:
		if int(r["id"]) == A_ID:
			res = r
	var mine := int(w.teams[A_ID])
	_check(not res.is_empty() and bool(res["won"]) == (mine == 0) and not bool(res["draw"])
			and res.has("score_us"),
		"insan nəticəni alır: qalib %s, hesab %s:%s" % [res.get("won"), res.get("score_us"), res.get("score_them")])
	_check(w.places.get(A_ID, 0) == (1 if mine == 0 else 2), "yer komandanın nəticəsidir")


static func _test_mother_overtime() -> void:
	var w := _playing(Const.Mode.MOTHER)
	_freeze(w)
	w.sim.mother_balls[0] = 70
	w.sim.mother_balls[1] = 72
	w.match_t = Const.MOTHER_TIME - 0.05
	for i in 3:
		w.tick(DT)
	_check(w.phase == Const.Phase.PLAYING and w.mother_ot and w.sim.mother_ot,
		"2:30-da Analar yaxındırsa əlavə vaxt başlayır")
	var a := w.sim.mother_balls[0]
	for i in int(2.0 / DT) + 1:
		w.tick(DT)
	_check(w.sim.mother_balls[0] - a == 2, "əlavə vaxtda Ana saniyədə 1 top dolur")
	w.match_t = Const.MOTHER_TIME + Const.MOTHER_OT - 0.05
	for i in 3:
		w.tick(DT)
	_check(w.phase == Const.Phase.OVER and w.obj_winner == 0 and w.timed_out,
		"əlavə vaxtın sonunda daha boş Ana udur")

	var v := _playing(Const.Mode.MOTHER)
	_freeze(v)
	v.sim.mother_balls[0] = 90
	v.sim.mother_balls[1] = 60
	v.match_t = Const.MOTHER_TIME - 0.05
	for i in 3:
		v.tick(DT)
	_check(v.phase == Const.Phase.OVER and v.obj_winner == 1 and not v.mother_ot,
		"fərq %d-dən çoxdursa 2:30-da boş Ana dərhal udur" % Const.MOTHER_TIE)

	var d := _playing(Const.Mode.MOTHER)
	_freeze(d)
	d.sim.mother_balls[0] = 80
	d.sim.mother_balls[1] = 80
	d.match_t = Const.MOTHER_TIME + Const.MOTHER_OT - 0.05
	d.mother_ot = true
	d.sim.mother_ot = true
	for i in 3:
		d.tick(DT)
	_check(d.phase == Const.Phase.OVER and d.obj_winner == -2 and bool(d.pending_results[0]["draw"]),
		"bərabər Analar — heç-heçə")


static func _test_island_path() -> void:
	var m := Const.Mode.ISLAND
	_check(Const.wet_circle(m, 0.0) == Vector3(0.0, 0.0, Const.ISLAND_WALL)
			and Const.wet_circle(m, Const.ISLAND_START) == Vector3(0.0, 0.0, Const.ISLAND_WALL),
		"0:20-yə qədər bütün qab yaşdır")
	_check(is_equal_approx(Const.wet_circle(m, Const.ISLAND_START + Const.ISLAND_SHRINK).z,
			Const.ISLAND_RADIUS), "0:25-də yalnız r %.0f-luq ada qalır" % Const.ISLAND_RADIUS)
	var s := Sim.new()
	s.set_mode(m)
	var max_step := 0.0
	var worst_edge := INF
	var on_wall := 0
	var prev := Const.wet_circle(m, Const.ISLAND_START)
	var t := Const.ISLAND_START
	while t < Const.MATCH_MAX:
		t += DT
		var c := Const.wet_circle(m, t)
		max_step = maxf(max_step, Vector2(c.x, c.y).distance_to(Vector2(prev.x, prev.y)))
		# Yığılma bitəndən sonra (yığılarkən yaş dairə şüşədən böyükdür — fərqi yoxdur).
		if t >= Const.ISLAND_START + Const.ISLAND_SHRINK:
			worst_edge = minf(worst_edge, Const.ISLAND_WALL - (Vector2(c.x, c.y).length() + c.z))
		for o in s.obstacles:
			if DishMap.blocks_germ(int(o.w)) and Vector2(c.x, c.y).distance_to(Vector2(o.x, o.y)) < o.z + 60.0:
				on_wall += 1
				break
		prev = c
	_check(max_step < 2.0, "ada sıçramır: tick-də ən çox %.2f px" % max_step)
	_check(worst_edge > 0.0, "ada həmişə şüşənin içindədir (ən az %.0f px)" % worst_edge)
	_check(on_wall == 0, "adanın mərkəzi selik üstünə düşmür")


static func _test_island_scoring() -> void:
	var w := _playing(Const.Mode.ISLAND)
	_freeze(w)
	w.match_t = 40.0
	w.tick(DT)
	var c := w.sim.wet_center
	var ids := w.sim.germs.keys()
	var zero: Array = []
	var one: Array = []
	for gid in ids:
		(zero if w.sim.germs[gid].team == 0 else one).append(gid)
	w.sim.germs[zero[0]].pos = c + Vector2(-40.0, 0.0)
	w.sim.germs[zero[1]].pos = c + Vector2(40.0, 0.0)
	w.sim.germs[one[0]].pos = c + Vector2(0.0, 60.0)
	var s0 := w.obj_score.duplicate()
	for i in int(2.0 / DT) + 2:
		for gid in [zero[0], zero[1], one[0]]:
			w.sim.germs[gid].pos = w.sim.wet_center + (w.sim.germs[gid].pos - c)
		c = w.sim.wet_center
		w.tick(DT)
	_check(w.obj_score[0] - s0[0] >= 2 and w.obj_score[1] == s0[1],
		"adada çox olan komanda saniyədə +1 xal (%d:%d)" % [w.obj_score[0], w.obj_score[1]])

	# Bərabərlik geridə qalanındır — fərq 25+ olanda.
	w.sim.germs[zero[1]].pos = Vector2(-300.0, -560.0)
	w.obj_score = PackedInt32Array([10, 40])
	for i in int(1.0 / DT) + 2:
		for gid in [zero[0], one[0]]:
			w.sim.germs[gid].pos = w.sim.wet_center + (w.sim.germs[gid].pos - c)
		c = w.sim.wet_center
		w.tick(DT)
	_check(w.obj_score[0] >= 11 and w.obj_score[1] == 40,
		"adada bərabərlik 25+ geridə qalana yazılır (%d:%d)" % [w.obj_score[0], w.obj_score[1]])

	w.obj_score = PackedInt32Array([Const.ISLAND_WIN - 1, 40])
	w.sim.germs[zero[1]].pos = w.sim.wet_center
	for i in int(1.2 / DT):
		w.tick(DT)
	_check(w.phase == Const.Phase.OVER and w.obj_winner == 0, "%d xal matçı bitirir" % Const.ISLAND_WIN)

	var v := _playing(Const.Mode.ISLAND)
	_freeze(v)
	v.obj_score = PackedInt32Array([30, 31])
	v.match_t = Const.ISLAND_TIME - 0.05
	for i in 3:
		v.tick(DT)
	_check(v.phase == Const.Phase.OVER and v.obj_winner == 1 and v.timed_out,
		"3:00-da çox xalı olan udur")


static func _test_island_dry_arsenal() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ISLAND)
	s.wet_center = Vector2(300.0, 0.0)
	s.dish_radius = Const.ISLAND_RADIUS
	var near := s.add_germ(A_ID, "A", 0)
	var deep := s.add_germ(B_ID, "B", 1)
	var safe := s.add_germ(303, "C", 2)
	for g in [near, deep, safe]:
		g.balls = 6
		g.safe_t = 0.0
		g.drain_t = 1000.0
	# Kənardan 150 px — su axını onu 3 s-də adaya çatdırmır.
	near.pos = Vector2(300.0 - Const.ISLAND_RADIUS - 150.0, 0.0)
	deep.pos = Vector2(-600.0, 0.0)
	safe.pos = Vector2(-600.0, 200.0)
	safe.safe_t = 999.0
	for i in int(3.1 / DT):
		s.step({}, DT)
	_check(near.balls == deep.balls and near.balls >= 7,
		"ADA-da quru dərinlikdən asılı deyil (%d = %d)" % [near.balls, deep.balls])
	_check(safe.balls == 6, "doğuş qalxanında quruda top yığılmır")


static func _test_island_food_dries() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ISLAND)
	s.wet_center = Vector2(300.0, 0.0)
	s.dish_radius = Const.ISLAND_RADIUS
	s.food.clear()
	s._drop_food(Vector2(300.0, 50.0), Vector2.ZERO, 0)
	s._drop_food(Vector2(-400.0, 0.0), Vector2.ZERO, 0)
	s._dry_food()
	_check(s.food.size() == 1 and s.food[0].pos.x > 0.0, "adanın çölündəki qida quruyur")
	var ok := true
	for i in 40:
		var p := s.find_spawn(Const.FOOD_RADIUS)
		ok = ok and p.distance_to(s.wet_center) <= s.dish_radius
	_check(ok, "qida adada doğulur")


## Nüvə mikrobu itələmir — proqnozun hesabı Nüvəsiz dünyadakı ilə eynidir.
static func _test_ball_one_way_push() -> void:
	var a := Sim.new()
	a.set_mode(Const.Mode.BALL)
	var b := Sim.new()
	b.set_mode(Const.Mode.BALL)
	b.ball.alive = false
	b.ball.reborn_t = 1.0e9
	var ga := a.add_germ(A_ID, "A", 0)
	var gb := b.add_germ(A_ID, "A", 0)
	for g in [ga, gb]:
		g.team = 0
		g.pos = Vector2(-120.0, 0.0)
		g.vel = Vector2.ZERO
	var push := {A_ID: Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false)}
	for i in int(1.0 / DT):
		a.step(push, DT)
		b.step(push, DT)
	_check(ga.pos.is_equal_approx(gb.pos), "Nüvə mikrobu itələmir (%.1f vs %.1f)" % [ga.pos.x, gb.pos.x])
	_check(a.ball.pos.x > 40.0 and a.ball.pos.x > ga.pos.x,
		"mikrob Nüvəni gövdəsi ilə itələyir (x %.0f)" % a.ball.pos.x)


static func _test_ball_shot_and_pop() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.BALL)
	_shot(s, A_ID, 0, Vector2(-100.0, 0.0), Vector2.RIGHT)
	for i in 8:
		s.step({}, DT)
	_check(s.ball.vel.x > 50.0 and is_equal_approx(s.ball.weight, float(Const.BALL_WEIGHT + Const.SHOT_PAYLOAD)),
		"top Nüvəni itələyir və ağırlaşdırır (v %.0f, çəki %.0f)" % [s.ball.vel.x, s.ball.weight])
	var light := s.ball.radius()
	s.ball.weight = float(Const.BALL_WEIGHT_MAX)
	_check(s.ball.radius() > light, "ağır Nüvə böyükdür")
	s.food.clear()
	s.ball.pos = Vector2.ZERO
	s.ball.vel = Vector2.ZERO
	_shot(s, A_ID, 0, Vector2(-120.0, 0.0), Vector2.RIGHT)
	var popped := false
	for i in 10:
		s.step({}, DT)
		popped = popped or not s.ball.alive
	_check(popped and s.food.size() >= 8, "çəki %d-ı keçəndə Nüvə partlayır, qida səpilir" % Const.BALL_WEIGHT_MAX)
	for i in int((Const.BALL_REBORN + 0.2) / DT):
		s.step({}, DT)
	_check(s.ball.alive and s.ball.pos.length() < 40.0
			and is_equal_approx(s.ball.weight, float(Const.BALL_WEIGHT)),
		"%.0f s sonra mərkəzdə yeni Nüvə" % Const.BALL_REBORN)
	# Çəki vaxtla azalır.
	s.ball.weight = 30.0
	for i in int(3.1 / DT):
		s.step({}, DT)
	_check(s.ball.weight <= 28.0 and s.ball.weight >= 27.0, "çəki 1.5 s-də 1 azalır (%.0f)" % s.ball.weight)


## İki rəqib Nüvəni sıxanda o sürət YIĞMIR.
##
## Təmas əvvəl tam elastik idi və mikrobun sürətini üstə gəlirdi: iki mikrobun arasında
## Nüvə hər tick o birindən sıçrayıb sürətlənirdi (ölçülüb: 0.3 s-də 350 → 1436 px/s, 5.9
## s-də iki qol). İndi mikroblar Nüvəni ən güclü tək itələmədən sürətli edə bilmir.
static func _test_ball_squeeze() -> void:
	var top := 0.0
	for offset in [0.0, 6.0, -11.0]:
		var s := Sim.new()
		s.set_mode(Const.Mode.BALL)
		s.obstacles.clear()
		s._reset_walls()
		var a := s.add_germ(A_ID, "A", 0)
		var b := s.add_germ(B_ID, "B", 1)
		a.team = 0
		b.team = 1
		for g in [a, b]:
			g.safe_t = 0.0
			g.drain_t = 1.0e9
			g.vel = Vector2.ZERO
		a.pos = Vector2(-110.0, 0.0)
		b.pos = Vector2(110.0, offset)
		# Nüvə A-dan B-yə doğru uçur, ikisi də onu üz-üzə sıxır.
		s.ball.vel = Vector2(350.0, 0.0)
		var press := {A_ID: Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false),
			B_ID: Sim.PlayerInput.make(1, Vector2.LEFT, 0.0, false)}
		for i in int(1.5 / DT):
			s.step(press, DT)
			if s.ball.alive:
				top = maxf(top, s.ball.vel.length())
	var limit := maxf(350.0, Const.BALL_KICK * Const.germ_speed(Const.START_CAPACITY)) + 1.0
	_check(top <= limit,
		"iki rəqibin sıxdığı Nüvə sürət yığmır (ən çox %.0f px/s, hədd %.0f)" % [top, limit])
	# Dayanan mikroba çırpılan Nüvə şüşədəki kimi sıçrayır — sürət itir, artmır.
	var w := Sim.new()
	w.set_mode(Const.Mode.BALL)
	w.obstacles.clear()
	w._reset_walls()
	var c := w.add_germ(A_ID, "A", 0)
	c.team = 0
	c.safe_t = 0.0
	c.vel = Vector2.ZERO
	c.pos = Vector2(80.0, 0.0)
	w.ball.vel = Vector2(300.0, 0.0)
	for i in int(0.5 / DT):
		w.step({A_ID: Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)}, DT)
	_check(w.ball.vel.x < 0.0 and w.ball.vel.length() <= 300.0 * Const.BALL_BOUNCE + 1.0,
		"dayanan mikroba çırpılan Nüvə sıçrayır, sürəti artmır (%.0f px/s)" % w.ball.vel.length())


static func _test_ball_goal_and_wall() -> void:
	for side in [1.0, -1.0]:
		var s := Sim.new()
		s.set_mode(Const.Mode.BALL)
		s.ball.pos = Vector2(side * 520.0, 0.0)
		s.ball.vel = Vector2(side * 500.0, 0.0)
		var goal := -1
		for i in 30:
			s.step({}, DT)
			if s.ball_goal >= 0:
				goal = s.ball_goal
				break
		var want := 0 if side > 0.0 else 1
		_check(goal == want, "Nüvə %s qapıya girəndə qolu komanda %d vurur" % ["şərq" if side > 0.0 else "qərb", want])
	var t := Sim.new()
	t.set_mode(Const.Mode.BALL)
	t.ball.pos = Vector2(0.0, 520.0)
	t.ball.vel = Vector2(0.0, 500.0)
	var scored := false
	for i in 30:
		t.step({}, DT)
		scored = scored or t.ball_goal >= 0
	_check(not scored and t.ball.vel.y < 0.0 and t.ball.pos.length() <= Const.BALL_WALL,
		"qapıdan kənarda Nüvə şüşədən sıçrayır")


static func _test_ball_match_flow() -> void:
	var w := _playing(Const.Mode.BALL)
	_freeze(w)
	w.sim.ball.pos = Vector2(540.0, 0.0)
	w.sim.ball.vel = Vector2(500.0, 0.0)
	var guard := 0
	while w.phase == Const.Phase.PLAYING and guard < 40:
		w.tick(DT)
		guard += 1
	var halves := true
	for gid in w.sim.germs:
		var g: Sim.GermState = w.sim.germs[gid]
		halves = halves and (g.team == 0) == (g.pos.x < 0.0)
	_check(w.obj_score[0] == 1 and w.phase == Const.Phase.COUNTDOWN,
		"qol: hesab 1:0, 3 s sayım")
	_check(halves and w.sim.ball.alive and w.sim.ball.pos == Vector2.ZERO,
		"qoldan sonra hamı öz yarısında, Nüvə mərkəzdə")
	var t0 := w.match_t
	for i in int(Const.COUNTDOWN_TIME / DT) + 2:
		w.tick(DT)
	_check(w.phase == Const.Phase.PLAYING and w.match_t - t0 < 0.2, "sayımda matçın saatı dayanır")
	_freeze(w)
	w.sim.ball.pos = Vector2(540.0, 0.0)
	w.sim.ball.vel = Vector2(500.0, 0.0)
	guard = 0
	while w.phase == Const.Phase.PLAYING and guard < 40:
		w.tick(DT)
		guard += 1
	_check(w.phase == Const.Phase.OVER and w.obj_winner == 0 and w.obj_score[0] == Const.BALL_GOALS,
		"%d qol matçı bitirir" % Const.BALL_GOALS)

	# 2:30-da bərabərdirsə ilk qol udur.
	var v := _playing(Const.Mode.BALL)
	_freeze(v)
	v.obj_score = PackedInt32Array([1, 1])
	v.match_t = Const.BALL_TIME + 1.0
	v.tick(DT)
	_check(v.phase == Const.Phase.PLAYING, "2:30-dan sonra bərabər hesabda matç davam edir")
	v.sim.ball.pos = Vector2(-540.0, 0.0)
	v.sim.ball.vel = Vector2(-500.0, 0.0)
	guard = 0
	while v.phase == Const.Phase.PLAYING and guard < 40:
		v.tick(DT)
		guard += 1
	_check(v.phase == Const.Phase.OVER and v.obj_winner == 1, "əlavə vaxtda ilk qol udur")


static func _test_respawn() -> void:
	var w := _playing(Const.Mode.MOTHER)
	var g: Sim.GermState = w.sim.germs[A_ID]
	var team := g.team
	g.charge = 7
	# Acından partlayır — adi ölüm yolu ([method Sim._step_germs]).
	g.balls = 0
	var out := w.tick(DT)
	var me_out := false
	for e in out:
		me_out = me_out or int(e["id"]) == A_ID
	_check(not me_out and w.peers.has(A_ID) and w.holds(A_ID) and not w.sim.germs.has(A_ID),
		"obyekt rejimində ölüm nəticə açmır, oyunçu matçda qalır")
	var row: Array = w.snapshot_for(A_ID)[Const.Snap.MATCH]
	_check(float(row[Const.MF.RESPAWN]) > 4.0, "snapshot doğuşa qalan vaxtı göndərir (%.1f s)" % float(row[Const.MF.RESPAWN]))
	_check(int(row[Const.MF.ALIVE]) == Const.mode_capacity(Const.Mode.MOTHER), "doğulmağı gözləyən sağ sayılır")
	for i in int((Const.OBJ_RESPAWN + 0.1) / DT):
		w.tick(DT)
	var back: Sim.GermState = w.sim.germs.get(A_ID)
	_check(back != null and back.team == team and back.charge == 7
			and back.capacity == Const.START_CAPACITY and (back.pos.x < 0.0) == (team == 0),
		"%.0f s sonra öz bazasında doğulur, super doluluğu qalır" % Const.OBJ_RESPAWN)
	# Doğulmağı gözləyən tərk edirsə dirilmir.
	var w2 := _playing(Const.Mode.BALL)
	w2.sim.germs[A_ID].balls = 0
	w2.tick(DT)
	w2.drop_peer(A_ID)
	for i in int((Const.BALL_RESPAWN + 0.5) / DT):
		w2.tick(DT)
	_check(not w2.sim.germs.has(A_ID), "matçı tərk edən dirilmir")


static func _test_match_row() -> void:
	for m in MODES:
		var w := _playing(m)
		for i in 10:
			w.tick(DT)
		var row: Array = w.snapshot_for(A_ID)[Const.Snap.MATCH]
		var obj: PackedFloat32Array = row[Const.MF.OBJ] if row.size() > Const.MF.OBJ else PackedFloat32Array()
		_check(row.size() == Const.MF.size() and obj.size() >= 1 and is_equal_approx(obj[0], w.match_t),
			"%s: matç sətri %d sahə, OBJ[0] matçın saatıdır" % [Const.mode_name(m), row.size()])
	var b := _playing(Const.Mode.BALL)
	var brow: Array = b.snapshot_for(A_ID)[Const.Snap.MATCH]
	_check((brow[Const.MF.OBJ] as PackedFloat32Array).size() == 7, "NÜVƏ TOPU: OBJ Nüvənin halını daşıyır")
	var isl := _playing(Const.Mode.ISLAND)
	isl.match_t = 60.0
	isl.tick(DT)
	var irow: Array = isl.snapshot_for(A_ID)[Const.Snap.MATCH]
	var io: PackedFloat32Array = irow[Const.MF.OBJ]
	var want := Const.wet_circle(Const.Mode.ISLAND, isl.match_t)
	_check(io.size() == 4 and is_equal_approx(io[3], want.z) and absf(io[1] - want.x) < 0.01,
		"YAŞ ADA: OBJ adanın yeridir və düsturla eynidir")


## Proqnoz eyni şüşəni və maneələri görür: Anaya dirənən mikrob iki tərəfdə eyni yerdə qalır.
static func _test_prediction_geometry() -> void:
	for m in MODES:
		var srv := Sim.new()
		srv.set_mode(m)
		var pred := Sim.new()
		pred.set_mode(m)
		var a := srv.add_germ(A_ID, "A", 0)
		var b := pred.add_germ(A_ID, "A", 0)
		for g in [a, b]:
			g.team = 0
			g.pos = Vector2(-300.0, 20.0)
			g.vel = Vector2.ZERO
			g.drain_t = 1000.0
		var go := {A_ID: Sim.PlayerInput.make(1, Vector2(-1.0, 0.05).normalized(), PI, false)}
		for i in int(3.0 / DT):
			srv.step(go, DT)
			pred.step_movement(go, DT)
		_check(a.pos.distance_to(b.pos) < 0.5 and a.pos.length() <= srv.wall_radius,
			"%s: proqnoz serverlə eyni yerdədir (%.2f px)" % [Const.mode_name(m), a.pos.distance_to(b.pos)])


static func _test_aim_path_objects() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.MOTHER)
	var p := s.aim_path(Vector2(520.0, 0.0), Vector2.RIGHT, 400.0, 1, 0)
	_check(p.size() == 2 and p[1].x < 560.0, "nişan xətti rəqibin Anasında bitir")
	p = s.aim_path(Vector2(520.0, 0.0), Vector2.RIGHT, 400.0, 1, 1)
	_check(p.size() == 3 and p[2].x < p[1].x, "nişan xətti öz Anandan sıçrayır")
	var b := Sim.new()
	b.set_mode(Const.Mode.BALL)
	p = b.aim_path(Vector2(-200.0, 0.0), Vector2.RIGHT, 500.0, 1, 0)
	_check(p.size() == 2 and p[1].x < 0.0, "nişan xətti Nüvədə bitir")
	p = b.aim_path(Vector2(0.0, 200.0), Vector2.DOWN, 800.0, 1, 0)
	_check(p.size() == 3 and absf(p[1].y - (Const.BALL_WALL - Const.SHOT_RADIUS)) < 1.0,
		"nişan xətti rejimin şüşəsindən sıçrayır")


static func _test_snapshot_fits() -> void:
	for m in MODES:
		var w := _playing(m)
		var me: Sim.GermState = w.sim.germs[A_ID]
		me.capacity = Const.MAX_CAPACITY
		me.pos = Vector2.ZERO
		for gid in w.sim.germs:
			w.sim.germs[gid].pos = Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		for i in Const.SHOT_SEND_MAX * 3:
			_shot(w.sim, A_ID, 0, Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0)), Vector2.RIGHT)
		for i in Const.FOOD_SEND_MAX * 4:
			w.sim._drop_food(Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0)), Vector2.ZERO, 0)
		for i in Const.EVENT_SEND_MAX * 3:
			w.sim.events.append({"t": "hit", "pos": Vector2(float(i), 0.0), "arg": 1.0, "color": 0})
		w._respawn[B_ID] = {"left": 3.0, "team": 0, "eye": Vector2.ZERO}
		w._build_frame()
		var size := var_to_bytes(w.snapshot_for(A_ID)).size()
		w._respawn.erase(B_ID)
		_check(size < Const.MTU_SAFE, "%s: ƏN PİS snapshot MTU-ya sığır: %d bayt" % [Const.mode_name(m), size])


## Balans ölçüsü: hər matçın gedişi bir sətirdə. NÜVƏ TOPU üçün Nüvənin harada
## dolaşdığı (|x| zolaqları), partlamalar və qapıya yaxınlaşmalar da sayılır.
static func probe(args: PackedStringArray) -> void:
	var modes: Array = MODES
	var seeds := 6
	var first := 0
	var team := -2
	var species := 0
	var skill := 1.0
	var human := true
	if args.has("--no-human"):
		human = false
	for i in args.size() - 1:
		if args[i] == "--mode":
			modes = [int(args[i + 1])]
		if args[i] == "--from":
			first = int(args[i + 1])
		if args[i] == "--seeds":
			seeds = int(args[i + 1])
		if args[i] == "--team":
			team = int(args[i + 1])
		if args[i] == "--species":
			species = int(args[i + 1])
		if args[i] == "--skill":
			skill = float(args[i + 1])
		if args[i] == "--no-human":
			human = false
	for m in modes:
		print("== %s" % Const.mode_name(m))
		for seed in range(first, seeds):
			var w := World.new(700 + seed, m)
			w.sim.rng.seed = 1000 + seed * 17
			w.add_player(A_ID, "A", Const.species_from(species), team)
			w.tick(DT)
			var me := Bot.new(A_ID, skill, 5000 + seed)
			# İnsansız ölçü: insan matçı başladır, sonra dünyadan çıxır və yerini YENİ bota
			# verir — dünyada heç bir insan izi qalmır.
			if not human:
				w.drop_peer(A_ID)
				w.peers.append(B_ID)    # dünya boş sayılıb bağlanmasın
				w._add_bot()
				me = null
			# Asimmetriya axtarışı: insanın mikrobu siyahının SONUNA köçür / peer olmaqdan çıxır.
			if args.has("--a-last") and w.sim.germs.has(A_ID):
				var ag: Sim.GermState = w.sim.germs[A_ID]
				w.sim.germs.erase(A_ID)
				w.sim.germs[A_ID] = ag
			if args.has("--a-nopeer") and me != null:
				w.peers.erase(A_ID)
				w.peers.append(B_ID)
				w.sim.germs[A_ID].is_bot = true
				w._bots[A_ID] = me
				me = null
			var guard := int((Const.MATCH_MAX + 30.0) / DT)
			var bands := PackedInt32Array([0, 0, 0, 0])   # |x| < 160, < 320, < 480, kənar
			var near_goal := 0
			var pops := 0
			var deaths := 0
			var dry := 0       # partladan yoxdur: quru zonada dolub və ya acından
			var fed := PackedInt32Array([0, 0])
			var isl := PackedInt32Array([0, 0])
			# Hər rejim üçün: atəş, mikroba dəymə, nişanın yoldaşa düşməsi və geri sayımda
			# mikrobların yerdəyişməsi (sayımda heç kim tərpənməməlidir).
			var fires := 0
			var hits := 0
			var mate_aim := 0
			var cd_move := 0.0
			var i := 0
			while w.phase != Const.Phase.OVER and i < guard:
				if me != null and w.sim.germs.has(A_ID):
					# Botun idarə etdiyi insan bot kimi sayılır (müdafiəçi seçimi, bax
					# [method Bot._first_bot]).
					w.sim.germs[A_ID].is_bot = true
					w._inputs[A_ID] = me.think(w.sim, DT)
				var before := w.sim.mother_balls.duplicate()
				var alive_before := w.sim.ball != null and w.sim.ball.alive
				var was_cd := w.phase == Const.Phase.COUNTDOWN
				var at := {}
				if was_cd:
					for gid in w.sim.germs:
						at[gid] = w.sim.germs[gid].pos
				w.tick(DT)
				i += 1
				if was_cd and w.phase == Const.Phase.COUNTDOWN:
					for gid in at:
						if w.sim.germs.has(gid):
							cd_move += w.sim.germs[gid].pos.distance_to(at[gid])
				for e in w.sim.events:
					if e["t"] == "hit" and float(e["arg"]) > 0.5:
						hits += 1
					elif e["t"] == "fire":
						fires += 1
						if _aims_at_mate(w.sim, e):
							mate_aim += 1
				deaths += w.sim.burst_log.size()
				for e in w.sim.burst_log:
					if int(e["killer"]) == 0:
						dry += 1
				if m == Const.Mode.BALL and w.sim.ball.alive:
					var ax := absf(w.sim.ball.pos.x)
					bands[mini(int(ax / 160.0), 3)] += 1
					if ax > 480.0 and absf(w.sim.ball.pos.y) < 140.0:
						near_goal += 1
				if m == Const.Mode.BALL and alive_before and not w.sim.ball.alive and w.sim.ball_goal < 0:
					pops += 1
				if m == Const.Mode.MOTHER:
					for t in 2:
						if w.sim.mother_balls[t] > before[t] and not w.mother_ot:
							fed[t] += w.sim.mother_balls[t] - before[t]
				if m == Const.Mode.ISLAND and i % 30 == 0:
					var n := w.island_counts()
					isl[0] += n[0]
					isl[1] += n[1]
				# `--trace`: hər saniyə Nüvə və mikrobların yeri (NÜVƏ TOPU-nun ilişməsini görmək üçün).
				if args.has("--trace") and i % 30 == 0:
					var row := "    t%3d" % int(w.match_t)
					var b := w.sim.ball
					if b != null:
						row += " N(%4.0f,%4.0f) v%3.0f w%2.0f%s" % [b.pos.x, b.pos.y,
							b.vel.length(), b.weight, "" if b.alive else " ölü"]
					if m == Const.Mode.MOTHER:
						row += " Ana %d:%d" % [w.sim.mother_balls[0], w.sim.mother_balls[1]]
					row += " |"
					for gid in w.sim.germs:
						var g: Sim.GermState = w.sim.germs[gid]
						row += " %d(%4.0f,%4.0f)b%d/%d" % [g.team, g.pos.x, g.pos.y, g.balls, g.capacity]
					print(row)
			var sc := w.team_scores()
			var line := "  #%d %5.1fs %s %d:%d win %d ölüm %d (özbaşına %d)" % [seed, w.match_t,
				"⏱" if w.timed_out else "★", sc[0], sc[1], w.obj_winner, deaths, dry]
			match m:
				Const.Mode.BALL:
					var tot := maxf(float(bands[0] + bands[1] + bands[2] + bands[3]), 1.0)
					line += " | x-zolaq %d%% %d%% %d%% %d%% · qapı yanı %.1fs · partlama %d" % [
						int(100.0 * bands[0] / tot), int(100.0 * bands[1] / tot),
						int(100.0 * bands[2] / tot), int(100.0 * bands[3] / tot),
						near_goal * DT, pops]
				Const.Mode.MOTHER:
					line += " | Anaya atılan +%d / +%d" % [fed[0], fed[1]]
				Const.Mode.ISLAND:
					line += " | adada (orta) %.1f / %.1f" % [isl[0] / maxf(i / 30.0, 1.0), isl[1] / maxf(i / 30.0, 1.0)]
				Const.Mode.TRIO:
					line += " | raund %d:%d" % [w.round_wins[0] if w.round_wins.size() > 1 else 0,
						w.round_wins[1] if w.round_wins.size() > 1 else 0]
			line += " | atəş %d · dəymə %d (%.0f%%) · yoldaşa nişan %.0f%% · sayımda yerdəyişmə %.0f px" % [
				fires, hits, 100.0 * hits / maxf(fires, 1.0), 100.0 * mate_aim / maxf(fires, 1.0), cd_move]
			print(line)


## Atəşin nişanı yoldaşa düşürmü: atıcının nişan xəttinə (±0.25 rad, 700 px) ən yaxın
## mikrob onun yoldaşıdırsa — top onun içindən keçəcək, yəni atəş boşa gedir.
static func _aims_at_mate(sim: Sim, e: Dictionary) -> bool:
	var shooter: Sim.GermState = null
	for gid in sim.germs:
		if sim.germs[gid].color == int(e["color"]):
			shooter = sim.germs[gid]
	if shooter == null or shooter.team < 0:
		return false
	var dir := Vector2.from_angle(float(e["arg"]))
	var best: Sim.GermState = null
	var best_d := INF
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g == shooter:
			continue
		var to := g.pos - shooter.pos
		var d := to.length()
		if d > 700.0 or d < 1.0 or absf(dir.angle_to(to)) > 0.25:
			continue
		if d < best_d:
			best_d = d
			best = g
	return best != null and best.team == shooter.team


## Client tərəfi: rejimin qabı proqnoza düşür, köhnə rejimin 9 sahəli sətri oxunur
## (sahələr artanda `MF.size()` şərti onları atırdı), obyekt sətri və dirilmə vaxtı oxunur.
static func _test_client_rows() -> void:
	var a := Arena.new()
	a.my_id = A_ID
	a._set_mode(Const.Mode.SOLO)
	a._init_prediction()
	a._dry = Node2D.new()
	var w := World.new(91, Const.Mode.SOLO)
	w.sim.rng.seed = 3
	w.add_player(A_ID, "A")
	w.tick(DT)
	var row: Array = w.snapshot_for(A_ID)[Const.Snap.MATCH]
	a._apply_match(row)
	_check(row.size() == Const.MF_BASE and a._phase == w.phase and a._alive == w._alive_count(),
		"client köhnə rejimin %d sahəli matç sətrini oxuyur" % Const.MF_BASE)
	_check(a.pred.wall_radius == Const.WORLD_RADIUS and not a._own_dead(),
		"köhnə rejimdə proqnozun qabı 1200-dür, dirilmə yoxdur")
	a._dry.free()
	a.free()

	for m in MODES:
		var b := Arena.new()
		b.my_id = A_ID
		b._set_mode(m)
		b._init_prediction()
		b._dry = Node2D.new()
		_check(b.pred.wall_radius == Const.wall_radius(m)
				and b.pred.obstacles == DishMap.obstacles_for(Const.mode_layout(m))
				and b._own_shots.wall == Const.wall_radius(m),
			"%s: client-in proqnozu və top proqnozu rejimin qabındadır" % Const.mode_name(m))
		var wb := _playing(m)
		wb.sim.germs[A_ID].balls = 0
		wb.tick(DT)
		b._apply_match(wb.snapshot_for(A_ID)[Const.Snap.MATCH])
		_check(b._own_dead() and b._respawn_left > 3.0 and not b._obj.is_empty()
				and is_equal_approx(b._obj[0], wb.match_t),
			"%s: client ölümü (%.1f s doğuş) və matçın saatını oxuyur" % [Const.mode_name(m), b._respawn_left])
		b._dry.free()
		b.free()


## Nəticə ekranı komandanın hesabını deyir: QALİB / MƏĞLUBİYYƏT / HEÇ-HEÇƏ və matçı nə
## bitirdi. Köhnə yol ("Sonuncu mikrob sənsən", "N-ci YER") obyekt rejimində yalan olardı.
static func _test_team_result() -> void:
	# Ağacdan kənarda qurulur: testlər açılış skriptinin `_ready`-sindədir və kök o an
	# uşaq qəbul etmir. HUD kənar boşluğunu yalnız ağacda qurur (bax [method Hud.build]).
	var h := Hud.new()
	h.build(load("res://assets/ui/joystick_base.svg"), load("res://assets/ui/joystick_knob.svg"))
	h.show_result({"won": true, "survived": true, "timed_out": false, "draw": false,
		"mode": Const.Mode.BALL, "score_us": 2, "score_them": 1, "pops": 3, "age": 95.0})
	var body := h._result_body.text
	_check(h._result_title.text == "QALİB!" and body.contains("QOL  2 — 1")
			and not body.contains("YER") and not body.contains("Sonuncu"),
		"NÜVƏ TOPU qələbəsi: başlıq QALİB!, hesab 2 — 1")
	h.show_result({"won": false, "survived": true, "timed_out": true, "draw": true,
		"mode": Const.Mode.MOTHER, "score_us": 90, "score_them": 90, "pops": 0, "age": 180.0})
	_check(h._result_title.text == "HEÇ-HEÇƏ" and h._result_body.text.contains("bərabərdir"),
		"bərabər Analar: başlıq HEÇ-HEÇƏ")
	h.show_result({"won": false, "survived": true, "timed_out": false, "draw": false,
		"mode": Const.Mode.MOTHER, "score_us": 141, "score_them": 60, "pops": 1, "age": 80.0})
	_check(h._result_title.text == "MƏĞLUBİYYƏT" and h._result_body.text.contains("Ananız partladı"),
		"Anası partlayan komanda: MƏĞLUBİYYƏT, səbəb yazılır")
	h.free()


## Komandalı rejimlərin botları (CÜT və ÜÇLÜK də): yoldaş hədəf deyil və geri sayımda
## heç bir bot tərpənmir — insanın girişi o vaxt bağlıdır.
static func _test_team_bots() -> void:
	for m in [Const.Mode.DUO, Const.Mode.TRIO]:
		var s := Sim.new()
		s.set_mode(m)
		var me := s.add_germ(A_ID, "A", 0, true)
		var mate := s.add_germ(B_ID, "B", 1, true)
		var foe := s.add_germ(303, "C", 2, true)
		me.team = 0
		mate.team = 0
		foe.team = 1
		for g in [me, mate, foe]:
			g.safe_t = 0.0
		me.pos = Vector2(-300.0, 200.0)
		mate.pos = Vector2(-200.0, 200.0)      # yoldaş yanındadır
		foe.pos = Vector2(200.0, 200.0)        # rəqib uzaqdadır
		_check(Bot._nearest_enemy(s, me) == foe,
			"%s: bot yanındakı yoldaşı yox, uzaqdakı rəqibi hədəf seçir" % Const.mode_name(m))

		var w := World.new(560 + m, m)
		w.sim.rng.seed = 21
		w.add_player(A_ID, "A")
		w.tick(DT)
		_check(w.phase == Const.Phase.COUNTDOWN, "%s: matç sayımla başlayır" % Const.mode_name(m))
		var moving := 0
		for i in 20:
			w.tick(DT)
			for bid in w._bots:
				var inp: Sim.PlayerInput = w._inputs.get(bid)
				if inp != null and (inp.move != Vector2.ZERO or inp.fire):
					moving += 1
		_check(w.phase == Const.Phase.COUNTDOWN and moving == 0,
			"%s: geri sayımda botların girişi boşdur (%d tərpənən giriş)" % [Const.mode_name(m), moving])


## Yalnız botların oynadığı tam matç: insan matçı başladır, sonra dünyadan çıxır və yerini
## adi bota verir. Komandalar simmetrik olsun deyə belədir — insanın yerini sabit botla
## idarə etmək ölçünü o komandanın xeyrinə əyirdi (ölçülüb: 10 matçdan 8–9).
static func play_match(m: int, seed: int) -> World:
	var w := World.new(700 + seed, m)
	w.sim.rng.seed = 1000 + seed * 17
	w.add_player(A_ID, "A")
	w.tick(DT)
	w.drop_peer(A_ID)
	w.peers.append(B_ID)    # dünya boş sayılıb bağlanmasın
	w._add_bot()
	var guard := int((Const.MATCH_MAX + 30.0) / DT)
	var i := 0
	while w.phase != Const.Phase.OVER and i < guard:
		w.tick(DT)
		i += 1
	return w


## Tam matçlar: hamısı bitir, çoxunun qalibi var və hər rejim öz məqsədi ilə oynanır —
## ANA tez partlamır, ADA-nın yarısı xalla bitir, NÜVƏ TOPU-nda qol vurulur.
static func _test_full_matches() -> void:
	const SEEDS := 8
	for m in MODES:
		var by_obj := 0
		var decided := 0
		var goals := 0
		var shortest := INF
		var notes := PackedStringArray()
		var stuck := 0
		for seed in SEEDS:
			var w := play_match(m, seed)
			if w.phase != Const.Phase.OVER:
				stuck += 1
				continue
			shortest = minf(shortest, w.match_t)
			by_obj += 0 if w.timed_out else 1
			decided += 1 if w.obj_winner >= 0 else 0
			var sc := w.team_scores()
			goals += sc[0] + sc[1]
			notes.append("%.0fs %d:%d%s" % [w.match_t, sc[0], sc[1], "⏱" if w.timed_out else ""])
		var name := Const.mode_name(m)
		_check(stuck == 0, "%s: %d matçın hamısı bitir — %s" % [name, SEEDS, ", ".join(notes)])
		# Hədlər botların 20 toxumluq ölçüsündən çıxır (`--objtest --probe --no-human`):
		# ANA 30-dan 30, ADA 16-dan 16, NÜVƏ 20-dən 14 qaliblə bitirdi; NÜVƏ-də matç başına
		# 1.1 qol. Ehtiyatla qoyulub — məqsəd çöküşü tutmaqdır, balansı dondurmaq yox.
		_check(decided * 2 >= SEEDS, "%s: matçların çoxunun qalibi var (%d/%d)" % [name, decided, SEEDS])
		match m:
			Const.Mode.MOTHER:
				_check(shortest >= 60.0, "%s: Ana birinci dəqiqədə partlamır (ən qısa %.0f s)" % [name, shortest])
			Const.Mode.ISLAND:
				_check(by_obj * 8 >= SEEDS * 3, "%s: matçların çoxu %d xalla bitir (%d/%d)"
					% [name, Const.ISLAND_WIN, by_obj, SEEDS])
			Const.Mode.BALL:
				_check(goals * 4 >= SEEDS * 3, "%s: qol vurulur (%d matçda %d qol)" % [name, SEEDS, goals])
