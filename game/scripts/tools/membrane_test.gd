class_name MembraneTest
extends RefCounted
## Vaxtlı, istiqamətli membran müdafiəsi (eksperimental profil, design/MODES.md §20) —
## headless testlər. [SimTest]-in içindən işləyir, eyni sayğacla.
##
## 0.18 s aktiv pəncərə öndən (±60°) gələn İLK düşmən mərmisini səth normalı ilə geri qaytarır;
## sonra 0.35 s bərpa (atəş və super bloklu), 7 s soyuma, qiyməti 1 top. Damcı qayıtmır.

const DT := Const.TICK_DELTA
const A_ID := AttackTest.A_ID
const B_ID := AttackTest.B_ID
const C_ID := AttackTest.C_ID


static func run() -> int:
	var fail0 := SimTest._fail
	print("\n----- Membran müdafiəsi (eksperimental profil) -----")
	var keep := World.default_profile
	_test_numbers()
	_test_activation_and_cost()
	_test_illegal_requests_free()
	_test_same_tick_priority()
	_test_held_button_one_attempt()
	_test_window_inside_outside()
	_test_sector_boundaries()
	_test_reflection_geometry()
	_test_first_only_second_passes()
	_test_needles_one_plus_one()
	_test_ownership_and_reward()
	_test_life_and_once()
	_test_lob_passes()
	_test_rewind_uses_history()
	_test_roundtrips()
	_test_standard_and_supers()
	_test_bot_visible_threat()
	_test_prediction_matches()
	_test_ui_nodes()
	_test_snapshot_size()
	World.default_profile = keep
	return SimTest._fail - fail0


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


## Maneəsiz duel, membran açıq: A solda (atır), B sağda (müdafiə edir), aralarında [param gap].
static func _duel(gap := 220.0, a_species := Const.Species.CILIATE) -> Sim:
	var s := AttackTest._duel(int(a_species), gap)
	s.membrane_on = true
	var b: Sim.GermState = s.germs[B_ID]
	b.aim = PI
	b.balls = 6
	s.germs[A_ID].balls = 6
	return s


## B-nin membranını [param left] qalan vaxtla, [param facing] istiqamətinə qurur.
static func _guard(g: Sim.GermState, facing: float, left := Const.MEMBRANE_ACTIVE + Const.MEMBRANE_RECOVER) -> void:
	g.mem_dir = Const.dir_unquant(Const.dir_quant(facing))
	g.mem_left = left
	g.mem_cd = Const.MEMBRANE_COOLDOWN
	g.mem_used = false


static func _press(s: Sim, id: int, aim: float, fire := false, sup := false) -> void:
	var inp := Sim.PlayerInput.make(1, Vector2.ZERO, aim, fire, sup)
	inp.membrane = true
	s._step_germs({id: inp}, DT)


# ---------------------------------------------------------------- qayda

static func _test_numbers() -> void:
	_check(Const.MEMBRANE_ACTIVE == 0.18 and Const.MEMBRANE_RECOVER == 0.35
			and Const.MEMBRANE_COOLDOWN == 7.0 and Const.MEMBRANE_COST == 1
			and absf(rad_to_deg(Const.MEMBRANE_HALF) * 2.0 - 120.0) < 0.001
			and Const.membrane_floor() == Const.FIRE_MIN_BALLS,
		"rəqəmlər: pəncərə 0.18 s, bərpa 0.35 s, soyuma 7 s, 1 top, 120°; döşəmə atəşinki (%d)"
			% Const.membrane_floor())


static func _test_activation_and_cost() -> void:
	var s := _duel()
	var b: Sim.GermState = s.germs[B_ID]
	_press(s, B_ID, 2.0)
	_check(b.balls == 5 and Const.membrane_phase(b.mem_left) == Const.MemPhase.ACTIVE
			and is_equal_approx(b.mem_cd, Const.MEMBRANE_COOLDOWN)
			and is_equal_approx(b.mem_dir, Const.dir_unquant(Const.dir_quant(2.0))),
		"membran: −1 top, aktiv, soyuma 7 s, istiqamət nişandan kilidlənir (64 addım)")
	for i in 30:
		s._step_germs({B_ID: Sim.PlayerInput.make(i, Vector2.ZERO, -1.0, false)}, DT)
	_check(is_equal_approx(b.mem_dir, Const.dir_unquant(Const.dir_quant(2.0))),
		"nişan dəyişsə də istiqamət bu istifadə üçün kilidli qalır")


## Qanunsuz istək heç nə xərcləmir.
static func _test_illegal_requests_free() -> void:
	var cases := []
	var s := _duel()
	var b: Sim.GermState = s.germs[B_ID]
	b.balls = Const.membrane_floor() - 1
	_press(s, B_ID, PI)
	cases.append(b.mem_left == 0.0 and b.balls == Const.membrane_floor() - 1)
	b.balls = 8
	b.super_t = 1.0
	_press(s, B_ID, PI)
	cases.append(b.mem_left == 0.0 and b.balls == 8)
	b.super_t = 0.0
	b.safe_t = 2.0
	_press(s, B_ID, PI)
	cases.append(b.mem_left == 0.0 and b.balls == 8)
	b.safe_t = 0.0
	b.mem_cd = 0.5
	_press(s, B_ID, PI)
	cases.append(b.mem_left == 0.0 and b.balls == 8)
	b.mem_cd = 0.0
	s.membrane_on = false
	_press(s, B_ID, PI)
	cases.append(b.mem_left == 0.0 and b.balls == 8)
	_check(not cases.has(false),
		"rədd: top az, super işləyir, doğuş qalxanı, soyuma, profil yox — heç nə xərclənmir %s" % [cases])
	s.membrane_on = true
	b.balls = Const.membrane_floor()
	_press(s, B_ID, PI)
	_check(b.balls == Const.membrane_floor() - Const.MEMBRANE_COST and b.balls >= Const.MIN_BALLS,
		"döşəmədə qanuni membran mikrobu aclıqdan öldürmür (%d top qalır)" % b.balls)


## Eyni tick: əvvəl membran; qəbul olunubsa atəş və super atılır; bərpa bitənə qədər bloklu.
static func _test_same_tick_priority() -> void:
	var s := _duel()
	var b: Sim.GermState = s.germs[B_ID]
	b.charge = Const.SUPER_MAX
	b.balls = 8
	_press(s, B_ID, PI, true, true)
	var blocked := s.shots.is_empty() and b.charge == Const.SUPER_MAX and b.super_t == 0.0
	var fired_during := false
	for i in int((Const.MEMBRANE_ACTIVE + Const.MEMBRANE_RECOVER) / DT) - 1:
		s._step_germs({B_ID: Sim.PlayerInput.make(i, Vector2.ZERO, PI, true)}, DT)
		if not s.shots.is_empty():
			fired_during = true
	for i in 3:
		s._step_germs({B_ID: Sim.PlayerInput.make(100 + i, Vector2.ZERO, PI, true)}, DT)
	_check(blocked and not fired_during and not s.shots.is_empty() and b.mem_left == 0.0,
		"eyni tick: membran qəbul olunur, atəş və super atılır; aktiv+bərpa boyu atəş yoxdur, sonra var")


## Basılı düymə hər tick yeni cəhd yaratmır; birləşən girişdə istək itmir.
static func _test_held_button_one_attempt() -> void:
	World.default_profile = Const.Profile.MEMBRANE
	var w := SimTest._quiet_world(120)
	World.default_profile = Const.Profile.STANDARD
	w.add_player(A_ID, "A")
	var g: Sim.GermState = w.sim.germs[A_ID]
	g.safe_t = 0.0
	g.balls = 8
	g.drain_t = 1.0e9
	var cds := 0
	var last := 0.0
	for seq in range(1, 91):
		var inp := Sim.PlayerInput.make(seq, Vector2.ZERO, 0.0, false)
		inp.membrane = true
		w.accept_input(A_ID, inp.to_array())
		w.tick(DT)
		if g.mem_cd > last + 1.0:
			cds += 1
		last = g.mem_cd
	_check(cds == 1 and g.balls == 7, "3 s basılı düymə — bir aktivləşmə, bir top (%d, %d top)" % [cds, g.balls])

	World.default_profile = Const.Profile.MEMBRANE
	var w2 := SimTest._quiet_world(121)
	World.default_profile = Const.Profile.STANDARD
	w2.add_player(A_ID, "A")
	var g2: Sim.GermState = w2.sim.germs[A_ID]
	g2.safe_t = 0.0
	g2.balls = 8
	var one := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)
	one.membrane = true
	w2.accept_input(A_ID, one.to_array())
	w2.accept_input(A_ID, Sim.PlayerInput.make(2, Vector2.ZERO, 0.0, false).to_array())
	w2.tick(DT)
	var on := g2.mem_left > 0.0
	for i in 5:
		w2.tick(DT)
	_check(on and g2.balls == 7 and w2._inputs[A_ID].membrane == false,
		"bir tick-ə düşən iki girişdə membran itmir və saxlanan girişdə təkrarlanmır")


# ---------------------------------------------------------------- geri qaytarma

static func _test_window_inside_outside() -> void:
	var out := []
	for left in [Const.MEMBRANE_RECOVER + 0.01, Const.MEMBRANE_RECOVER - 0.01, 0.0]:
		var s := _duel()
		var a: Sim.GermState = s.germs[A_ID]
		var b: Sim.GermState = s.germs[B_ID]
		_guard(b, PI, left)
		s._fire(a)
		var b0 := b.balls
		var turned := false
		for i in 200:
			s._step_shots(DT)
			for sh in s.shots:
				if sh.parried and sh.owner_id == B_ID:
					turned = true
			if s.shots.is_empty():
				break
		out.append([b.balls - b0, turned])
	_check(out[0] == [0, true] and out[1][0] == 2 and out[2][0] == 2,
		"aktiv pəncərənin içində qaytarır, bərpada və membransız dəyir (+2) %s" % [out])


## Ön sektor ±60° (64 addımlı istiqamət): içəri qaytarır, kənar və arxa dəyir.
static func _test_sector_boundaries() -> void:
	var res := {}
	for deg in [0.0, 56.25, 61.875, 120.0, 180.0]:
		var s := _duel()
		var b: Sim.GermState = s.germs[B_ID]
		_guard(b, PI + deg_to_rad(deg))
		var b0 := b.balls
		s._fire(s.germs[A_ID])
		AttackTest._fly(s, 200)
		res[deg] = b.balls == b0
	_check(res[0.0] and res[56.25] and not res[61.875] and not res[120.0] and not res[180.0],
		"sektor: 0° və 56° qaytarır, 62°, 120° və arxa (180°) dəyir %s" % [res])


## Qayıtma səth normalı ilə: v − 2(v·n)n; mərkəzə dəyən top düz geri qayıdır.
static func _test_reflection_geometry() -> void:
	var s := _duel()
	var b: Sim.GermState = s.germs[B_ID]
	_guard(b, PI)
	s._fire(s.germs[A_ID])
	for i in 60:
		s._step_shots(DT)
		if not s.shots.is_empty() and s.shots[0].parried:
			break
	var sh := s.shots[0]
	var straight := sh.dir.dot(Vector2.LEFT) > 0.999
	var s2 := _duel()
	var b2: Sim.GermState = s2.germs[B_ID]
	b2.pos.y = 14.0
	_guard(b2, PI)
	s2._fire(s2.germs[A_ID])
	for i in 60:
		s2._step_shots(DT)
		if not s2.shots.is_empty() and s2.shots[0].parried:
			break
	var sh2 := s2.shots[0]
	var n := (sh2.pos - b2.pos).normalized()
	var want := (Vector2.RIGHT - 2.0 * Vector2.RIGHT.dot(n) * n).normalized()
	_check(straight and sh2.dir.dot(want) > 0.999 and sh2.dir.y < 0.0
			and sh.pos.distance_to(b.pos) > b.radius(),
		"mərkəzi zərbə düz geri, yan zərbə normalla əks olunur; top membranın ÇÖLÜNDƏ başlayır")


## İlk mərmi qayıdır, ikincisi (eyni pəncərədə) adi dəyir.
static func _test_first_only_second_passes() -> void:
	var s := _duel(300.0)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	_guard(b, PI)
	s._fire(a)
	a.cooldown = 0.0
	a.pos.x -= 40.0
	s._fire(a)
	var b0 := b.balls
	AttackTest._fly(s, 200)
	var a0 := 6 - 2
	_check(b.mem_used and b.balls == b0 + 2 and Const.membrane_phase(b.mem_left) != Const.MemPhase.ACTIVE,
		"birinci top qayıdır, ikincisi dəyir (+2); pəncərə dərhal bitir (B %d → %d)" % [b0, b.balls])
	_check(a.balls >= a0 + 2, "qayıdan top atıcıya dəyir (A %d top)" % a.balls)


## Ayaqlının iki iynəsi eyni tick-də dəyir: TƏMAS ANI erkən olan qayıdır (yükü +1 qalır),
## ikincisi +1 verir — +2 yox.
static func _test_needles_one_plus_one() -> void:
	var s := _duel(160.0, Const.Species.HELIOZOAN)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.pos.y = 6.0
	_guard(b, PI)
	s._fire(a)
	var b0 := b.balls
	var reflected: Sim.ShotState = null
	for i in 200:
		s._step_shots(DT)
		for sh in s.shots:
			if sh.parried and reflected == null:
				reflected = sh
		if s.shots.is_empty():
			break
	_check(reflected != null and reflected.payload == 1 and reflected.owner_id == B_ID
			and b.balls == b0 + 1,
		"iynələr: biri qayıdır (yük +1 qalır), digəri +1 verir — cəmi +%d" % (b.balls - b0))
	# Təmas anı: B aşağı sürüşüb — aşağı iynə (dir.y > 0) əvvəl çatır; siyahı sırası dəyişsə də o qayıdır.
	var s2 := _duel(160.0, Const.Species.HELIOZOAN)
	var b2: Sim.GermState = s2.germs[B_ID]
	b2.pos.y = 6.0
	_guard(b2, PI)
	s2._fire(s2.germs[A_ID])
	s2.shots.reverse()
	var r2: Sim.ShotState = null
	for i in 40:
		s2._step_shots(DT)
		for sh in s2.shots:
			if sh.parried:
				r2 = sh
		if r2 != null:
			break
	_check(r2 != null and reflected != null and r2.id == reflected.id,
		"qayıdan iynə təmas anına görə seçilir, siyahı sırasına görə yox")


## Sahib, komanda, rəng və partlatmanın mükafatı müdafiəçiyə keçir; qaytarma super vermir.
static func _test_ownership_and_reward() -> void:
	var s := _duel()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	_guard(b, PI)
	a.capacity = 10
	b.charge = 0
	a.charge = 0
	s._fire(a)
	a.balls = a.capacity - 1
	var hits := 0
	var parries := 0
	var charge_after_parry := -1
	for i in 120:
		s.events.clear()
		s._step_shots(DT)
		for e in s.events:
			if e["t"] == "hit" and float(e["arg"]) > 0.5:
				hits += 1
			if e["t"] == "parry":
				parries += 1
				charge_after_parry = b.charge
		if s.shots.is_empty():
			break
	var killer := -1
	for e in s.burst_log:
		if int(e["id"]) == A_ID:
			killer = int(e["killer"])
	_check(parries == 1 and charge_after_parry == 0 and killer == B_ID and hits == 1,
		"qaytarma super vermir və HIT yaratmır; qayıdan top A-nı partladır, partlatma B-nindir")


## Ömür və sıçrayış yenilənmir; bir mərmi bir dəfə qayıdır — ikinci müdafiəçi onu qaytarmır.
static func _test_life_and_once() -> void:
	var s := _duel(260.0)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	_guard(b, PI)
	s._fire(a)
	var life_before := 0.0
	var bounces := 0
	for i in 60:
		if not s.shots.is_empty():
			life_before = s.shots[0].life
			bounces = s.shots[0].bounces
		s._step_shots(DT)
		if not s.shots.is_empty() and s.shots[0].parried:
			break
	var sh := s.shots[0]
	_check(sh.life < life_before and sh.bounces == bounces,
		"qayıdan topun ömrü doldurulmur (%.2f s qalıb), sıçrayış sayı eynidir" % sh.life)
	# A da membranlıdır — qayıdan topu ikinci dəfə qaytara bilmir.
	_guard(a, 0.0)
	var a0 := a.balls
	AttackTest._fly(s, 200)
	_check(not a.mem_used and a.balls == a0 + 2, "artıq qaytarılmış top ikinci membrandan qayıtmır, dəyir")


## Damcı (yuxarıdan düşür) membrandan qayıtmır — ilk prototipin açıq istisnası.
static func _test_lob_passes() -> void:
	var s := _duel(300.0, Const.Species.AMOEBA)
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	_guard(b, PI)
	var b0 := b.balls
	s._fire(a, -1.0, 0.0, false, Vector2.INF, 300.0)
	AttackTest._fly(s, 60)
	_check(b.balls == b0 + 2 and not b.mem_used, "damcı membrandan keçir — qayıtmır, +2 dəyir")


## Geri sarılan atəş: keçmişdə membran yox idisə İNDİKİ membran tətbiq olunmur.
static func _test_rewind_uses_history() -> void:
	var s := _duel(220.0)
	s.lag_comp = true
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	for i in 8:
		s.step({}, DT)
	s._fire(a)
	s.shots[0].rewind = 5.0
	var b0 := b.balls
	var guarded := false
	for i in 60:
		# Topa iki tick qalmış membran açılır — atıcının gördüyü (5 tick əvvəlki) anda yox idi.
		if not guarded and not s.shots.is_empty() \
				and s.shots[0].pos.x > b.pos.x - b.radius() - s.shots[0].speed * DT * 2.5:
			_guard(b, PI)
			guarded = true
		s.tick += 1
		s._record_history()
		s._step_shots(DT)
		if s.shots.is_empty():
			break
	_check(guarded and b.balls >= b0 + 2 and not b.mem_used,
		"atıcının gördüyü keçmişdə membran yox idi — top dəyir, indiki membran işlənmir")


# ---------------------------------------------------------------- şəbəkə

static func _test_roundtrips() -> void:
	var g := Sim.GermState.new()
	_guard(g, 1.0, 0.3)
	g.mem_used = true
	var c := g.clone()
	_check(c.mem_left == g.mem_left and c.mem_cd == g.mem_cd and c.mem_dir == g.mem_dir and c.mem_used,
		"GermState.clone membran halını saxlayır")
	var ok := true
	for m in [false, true]:
		for ev in [-1, 2]:
			var i := Sim.PlayerInput.make(3, Vector2.ZERO, 0.0, true, true)
			i.membrane = m
			i.evolve = ev
			i.fire_range = 250.0
			var back := Sim.PlayerInput.from_array(i.to_array())
			ok = ok and back.membrane == m and back.evolve == ev and back.use_super and back.fire_range == 250.0
	_check(ok, "girişin membran biti gedib-gəlir, seçim/super/məsafə bitlərini pozmur")
	World.default_profile = Const.Profile.MEMBRANE | Const.Profile.MUTATIONS
	var w := SimTest._quiet_world(122)
	World.default_profile = Const.Profile.STANDARD
	w.add_player(A_ID, "A")
	var me: Sim.GermState = w.sim.germs[A_ID]
	me.mutations = 5
	me.team = 4
	me.charge = Const.SUPER_MAX
	_guard(me, -2.5)
	var f := World._flags_of(me)
	var ph := (f & Const.GFlag.MEM_MASK) >> Const.GFlag.MEM_SHIFT
	var q := (f & Const.GFlag.MEMDIR_MASK) >> Const.GFlag.MEMDIR_SHIFT
	_check(ph == Const.MemPhase.ACTIVE and is_equal_approx(Const.dir_unquant(q), me.mem_dir)
			and (f & Const.GFlag.MUT_MASK) >> Const.GFlag.MUT_SHIFT == 5
			and (f & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT == Const.SUPER_MAX
			and float(f) == float(int(float(f))) and f < (1 << 22),
		"bayraq: faza və istiqamət digər bitləri pozmur, float32-də dəqiqdir (%d)" % f)
	w.tick(DT)
	var snap := w.snapshot_for(A_ID)
	_check(float(snap[Const.Snap.MEM]) > 6.0 and int(w.join_info_for(A_ID)["profile"]) == 3,
		"snapshot öz soyumanı, join info profili (3 = mutasiya + membran) daşıyır")


static func _test_standard_and_supers() -> void:
	var w := SimTest._quiet_world(123)
	w.add_player(A_ID, "A")
	var g: Sim.GermState = w.sim.germs[A_ID]
	g.safe_t = 0.0
	g.balls = 8
	var inp := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)
	inp.membrane = true
	w.accept_input(A_ID, inp.to_array())
	w.tick(DT)
	_check(not w.sim.membrane_on and g.mem_left == 0.0 and g.balls == 8
			and float(w.snapshot_for(A_ID)[Const.Snap.MEM]) < 0.0,
		"standart profil: membran istəyi heç nə etmir, MEM -1")
	var ok := true
	for m in Const.Mode.values():
		World.default_profile = Const.Profile.MEMBRANE
		var x := World.new(124, m)
		World.default_profile = Const.Profile.STANDARD
		if m != Const.Mode.ENDLESS and x.sim.membrane_on:
			ok = false
	_check(ok, "membran yalnız SONSUZ ARENA-ya düşür — altı rejimin döyüşü dəyişmir")
	# Kirpiklinin trixosisti hələ də topları qidaya çevirir; amöbün miniqanı qalxan deyil.
	var s := _duel()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.species = Const.Species.AMOEBA
	b.super_t = 2.0
	_press(s, B_ID, PI)
	var b0 := b.balls
	s._fire(a)
	AttackTest._fly(s, 200)
	_check(b.mem_left == 0.0 and b.balls == b0 + 2,
		"amöbün superi qalxan vermir və super vaxtı membran açılmır")


## Bot yalnız GÖRÜNƏN qanuni təhlükəyə (üzünə uçan düz mərmiyə) membran açır.
static func _test_bot_visible_threat() -> void:
	var used := 0
	var faced := 0
	for k in 20:
		var s := _duel(260.0)
		var a: Sim.GermState = s.germs[A_ID]
		var b: Sim.GermState = s.germs[B_ID]
		b.is_bot = true
		var bot := Bot.new(B_ID, 1.0, 100 + k)
		s._fire(a)
		for i in 30:
			var inp := bot.think(s, DT)
			if inp.membrane:
				used += 1
				if absf(angle_difference(inp.aim, PI)) < 0.2:
					faced += 1
				break
			s._step_shots(DT)
			if s.shots.is_empty():
				break
	var quiet := 0
	for k in 10:
		var s := _duel(260.0, Const.Species.AMOEBA)
		var b: Sim.GermState = s.germs[B_ID]
		var bot := Bot.new(B_ID, 1.0, 200 + k)
		s._fire(s.germs[A_ID], -1.0, 0.0, false, Vector2.INF, 260.0)
		for i in 30:
			if bot.think(s, DT).membrane:
				quiet += 1
				break
			s._step_shots(DT)
	_check(used >= 5 and faced == used and quiet == 0,
		"bot üzünə uçan topa membran açır (%d/20, hamısı topa dönüb), damcıya açmır (%d)" % [used, quiet])


## Proqnoz serverlə eyni: aktivləşmə, qiymət, soyuma, bloklu atəş.
static func _test_prediction_matches() -> void:
	var s := _duel()
	var p := Sim.new()
	p.obstacles.clear()
	p._reset_walls()
	p.membrane_on = true
	p.germs[B_ID] = s.germs[B_ID].clone()
	var same := true
	for i in 40:
		var inp := Sim.PlayerInput.make(i, Vector2.UP, PI, i > 2, false)
		inp.membrane = i == 3
		var pi := Sim.PlayerInput.make(i, Vector2.UP, PI, i > 2, false)
		pi.membrane = i == 3
		s.step({B_ID: inp}, DT)
		p.step_movement({B_ID: pi}, DT)
		var g: Sim.GermState = s.germs[B_ID]
		var q: Sim.GermState = p.germs[B_ID]
		same = same and is_equal_approx(g.mem_left, q.mem_left) and is_equal_approx(g.mem_cd, q.mem_cd) \
			and g.cooldown == q.cooldown and g.pos.distance_to(q.pos) < 0.001
	_check(same, "proqnoz serverlə eyni membran fazası, soyuma, atəş bloku və yol")


static func _test_ui_nodes() -> void:
	var btn := MembraneButton.new()
	btn.set_state(Const.MemPhase.RECOVER, 0.5, false)
	var arc := MembraneArc.new()
	arc.set_state(Const.MemPhase.ACTIVE, 1.0, 30.0)
	var ok := arc.visible
	arc.set_state(Const.MemPhase.NONE, 1.0, 30.0)
	ok = ok and not arc.visible
	var marks := LobMarks.new()
	marks.membrane = true
	btn.free()
	arc.free()
	marks.free()
	_check(ok, "membran düyməsi, ön qövs və damcı işarəsi qurulur; NONE fazada qövs görünmür")


## Ən pis snapshot: hamısı membranlı və mutasiyalı, uçan toplar — MTU-ya sığır.
static func _test_snapshot_size() -> void:
	World.default_profile = Const.Profile.MEMBRANE | Const.Profile.MUTATIONS
	var w := SimTest._quiet_world(125)
	World.default_profile = Const.Profile.STANDARD
	w.add_player(A_ID, "A")
	w._seeded = false
	w.tick(DT)
	while w.sim.germs.size() < Const.WORLD_CAPACITY:
		w._add_bot()
	var me: Sim.GermState = w.sim.germs[A_ID]
	var k := 0
	for gid in w.sim.germs:
		var g: Sim.GermState = w.sim.germs[gid]
		g.mutations = 3
		_guard(g, float(k))
		g.pos = me.pos + Vector2.from_angle(float(k)) * 120.0
		g.balls = 12
		g.capacity = 20
		k += 1
	for gid in w.sim.germs:
		w.sim._fire(w.sim.germs[gid])
	for i in Const.FOOD_SEND_MAX * 3:
		w.sim._drop_food(me.pos + Vector2.from_angle(float(i)) * 200.0, Vector2.ZERO, 0)
	w.tick(DT)
	var size := var_to_bytes(w.snapshot_for(A_ID)).size()
	_check(size < Const.MTU_SAFE, "membranlı ən pis snapshot MTU-ya sığır: %d bayt" % size)
