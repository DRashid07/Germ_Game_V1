class_name MutationTest
extends RefCounted
## Matç içi mutasiyalar (eksperimental profil, design/MODES.md §19) — headless testlər.
## [SimTest]-in içindən işləyir, eyni sayğacla.
##
## Mikrob bir həyatda 45 və 90 saniyədə bir seçim qazanır, ən çox iki mutasiya. Seçimi
## yalnız server tətbiq edir ([method World.choose_mutation]); təsirlər paylaşılan
## əmsallardır ([method Const.shot_speed], [method Const.recoil] ...) və həm server, həm
## proqnoz eyni funksiyanı işlədir.

const DT := Const.TICK_DELTA
const A_ID := 101
const B_ID := 202
const LONG := 1 << Const.Mut.LONG
const WHIP := 1 << Const.Mut.WHIP
const STICKY := 1 << Const.Mut.STICKY


static func run() -> int:
	var fail0 := SimTest._fail
	print("\n----- Mutasiyalar (eksperimental profil) -----")
	var keep := World.default_profile
	_test_effect_numbers()
	_test_shot_economy_unchanged()
	_test_unlock_ages()
	_test_both_thresholds_at_once()
	_test_rejects()
	_test_duplicate_packets()
	_test_two_combine()
	_test_death_resets()
	_test_roundtrips()
	_test_rejoin_keeps()
	_test_prediction_matches_server()
	_test_shot_keeps_rule_midair()
	_test_standard_unchanged()
	_test_bots_choose_legally()
	_test_cards_ui()
	_test_snapshot_size()
	World.default_profile = keep
	return SimTest._fail - fail0


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


## Mutasiya profilli sakit SONSUZ ARENA dünyası və onda bir oyunçu.
static func _world(id: int) -> World:
	World.default_profile = Const.Profile.MUTATIONS
	var w := SimTest._quiet_world(id)
	World.default_profile = Const.Profile.STANDARD
	w.add_player(A_ID, "A")
	return w


static func _germ(w: World) -> Sim.GermState:
	return w.sim.germs[A_ID]


# ---------------------------------------------------------------- rəqəmlər

static func _test_effect_numbers() -> void:
	var ok := true
	for p in [Const.Shot.DART, Const.Shot.NEEDLE, Const.Shot.MINIGUN]:
		var reach0 := Const.shot_reach(p)
		var reach1 := Const.shot_reach(p, LONG)
		ok = ok and absf(reach1 / reach0 - Const.MUT_LONG_RANGE) < 0.0001 \
			and absf(Const.shot_speed(p, LONG) / Const.shot_speed(p) - Const.MUT_LONG_SPEED) < 0.0001
	_check(ok, "UZUN ÇIXINTI: düz atəşdə məsafə ×1.20, sürət ×0.85 — ömür ikisindən (×1.41)")
	_check(absf(Const.lob_max(LONG) - Const.LOB_MAX * 1.2) < 0.001
			and absf(Const.lob_flight(LONG) - Const.LOB_FLIGHT / 0.85) < 0.0001
			and Const.shot_reach(Const.Shot.LOB, LONG) == Const.lob_max(LONG),
		"UZUN ÇIXINTI: damcının ən uzaq məsafəsi %.0f px, uçuşu %.2f s (xəbərdarlıq eyni hesabla)"
			% [Const.lob_max(LONG), Const.lob_flight(LONG)])
	_check(absf(Const.recoil(WHIP) - Const.SHOT_RECOIL * 1.3) < 0.001 and Const.mut_brake(WHIP) == 0.8
			and Const.mut_brake(0) == 1.0,
		"İMPULS QAMÇISI: geri təpmə ×1.30, əyləc əmsalı ×0.80")
	_check(Const.mut_flow(STICKY) == 0.75 and Const.mut_speed(STICKY) == 0.95
			and Const.mut_flow(LONG | WHIP) == 1.0,
		"YAPIŞQAN AYAQLAR: axın ×0.75, öz sürəti ×0.95; başqa mutasiyalar axına toxunmur")


## Mutasiya iqtisadiyyata toxunmur: −1 top, iynələrin hər biri +1, hərəkət ən çox +2.
static func _test_shot_economy_unchanged() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ENDLESS)
	var g := s.add_germ(A_ID, "A", 0, false, Const.Species.HELIOZOAN)
	g.mutations = LONG | WHIP
	g.balls = 8
	g.pos = Vector2(0.0, -300.0)
	s._fire(g)
	var payload := 0
	for sh in s.shots:
		payload += sh.payload
	_check(g.balls == 7 and s.shots.size() == 2 and payload == 2 and s.shots[0].payload == 1,
		"mutasiyalı ayaqlının atəşi: −1 top, iki iynə hərəsi +1 (cəmi +%d)" % payload)


# ---------------------------------------------------------------- açılma

static func _test_unlock_ages() -> void:
	var w := _world(81)
	var g := _germ(w)
	g.age = 44.9
	var early := w.choose_mutation(A_ID, Const.Mut.LONG)
	g.age = 45.0
	var first := w.choose_mutation(A_ID, Const.Mut.LONG)
	var second_early := w.choose_mutation(A_ID, Const.Mut.WHIP)
	g.age = 89.9
	var still := w.choose_mutation(A_ID, Const.Mut.WHIP)
	g.age = 90.0
	var second := w.choose_mutation(A_ID, Const.Mut.WHIP)
	g.age = 500.0
	var third := w.choose_mutation(A_ID, Const.Mut.STICKY)
	_check(early == "early" and first == "" and second_early == "early" and still == "early"
			and second == "" and third == "full" and g.mutations == LONG | WHIP,
		"45 s-də birinci, 90 s-də ikinci seçim açılır; hər mərhələ bir dəfə, üçüncü yoxdur (%s/%s/%s/%s/%s/%s)"
			% [early, first, second_early, still, second, third])


## İki hədd bir tick-də keçilsə də iki seçim də qalır; snapshot bunu deyir.
static func _test_both_thresholds_at_once() -> void:
	var w := _world(82)
	var g := _germ(w)
	g.age = 10.0
	w.tick(DT)
	var before := int(w.snapshot_for(A_ID)[Const.Snap.EVO])
	g.age = 95.0
	w.tick(DT)
	var after := int(w.snapshot_for(A_ID)[Const.Snap.EVO])
	var a := w.choose_mutation(A_ID, Const.Mut.STICKY)
	var b := w.choose_mutation(A_ID, Const.Mut.LONG)
	_check(before == 0 and after == 2 and a == "" and b == "",
		"iki hədd bir snapshot-da keçiləndə iki seçim də qalır (EVO %d → %d)" % [before, after])


static func _test_rejects() -> void:
	var w := _world(83)
	var g := _germ(w)
	g.age = 100.0
	var bad := [w.choose_mutation(A_ID, 3), w.choose_mutation(A_ID, -1),
		w.choose_mutation(999, Const.Mut.LONG)]
	var ok := w.choose_mutation(A_ID, Const.Mut.LONG)
	var dup := w.choose_mutation(A_ID, Const.Mut.LONG)
	_check(bad == ["unknown", "unknown", "dead"] and ok == "" and dup == "taken"
			and g.mutations == LONG,
		"saxta id, yox mikrob və təkrar seçim rədd olunur (%s, %s)" % [str(bad), dup])

	var std := SimTest._quiet_world(84)
	std.add_player(A_ID, "A")
	std.sim.germs[A_ID].age = 100.0
	World.default_profile = Const.Profile.MUTATIONS
	var solo := World.new(85, Const.Mode.SOLO)
	World.default_profile = Const.Profile.STANDARD
	solo.add_player(A_ID, "A")
	solo.sim.germs[A_ID].age = 100.0
	_check(std.choose_mutation(A_ID, Const.Mut.LONG) == "profile"
			and solo.choose_mutation(A_ID, Const.Mut.LONG) == "profile"
			and solo.profile == Const.Profile.STANDARD,
		"standart profildə və SONSUZ ARENA-dan kənarda seçim rədd olunur")


## Təkrar paket eyni seçimi iki dəfə tətbiq etmir (client təsdiqə qədər təkrarlayır).
static func _test_duplicate_packets() -> void:
	var w := _world(86)
	var g := _germ(w)
	g.age = 50.0
	for seq in [1, 2, 3, 4]:
		var inp := Sim.PlayerInput.make(seq, Vector2.ZERO, 0.0, false)
		inp.evolve = Const.Mut.WHIP
		w.accept_input(A_ID, inp.to_array())
		w.tick(DT)
	var inp2 := Sim.PlayerInput.make(5, Vector2.ZERO, 0.0, false)
	inp2.evolve = Const.Mut.LONG
	w.accept_input(A_ID, inp2.to_array())
	_check(g.mutations == WHIP and Const.mut_count(g.mutations) == 1,
		"dörd təkrar paketdən sonra bir mutasiya, açılmamış ikincisi rədd (bitlər %d)" % g.mutations)


# ---------------------------------------------------------------- təsir

## İki mutasiya birləşir: hər biri öz əmsalına toxunur, biri digərini ikiqat etmir.
static func _test_two_combine() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ENDLESS)
	var g := s.add_germ(A_ID, "A", 0)
	g.mutations = LONG | WHIP
	g.pos = Vector2(0.0, -300.0)
	g.vel = Vector2.ZERO
	g.balls = 8
	s._fire(g)
	var sh := s.shots[0]
	var ok := absf(sh.speed - Const.SHOT_PROFILE_SPEED[Const.Shot.DART] * 0.85) < 0.001 \
		and absf(sh.speed * sh.life - Const.shot_reach(Const.Shot.DART) * 1.2) < 0.01 \
		and absf(g.vel.length() - Const.SHOT_RECOIL * 1.3) < 0.001 and sh.long
	_check(ok, "UZUN + QAMÇI: top %.0f px/s, %.0f px; geri təpmə %.0f px/s"
		% [sh.speed, sh.speed * sh.life, g.vel.length()])

	# QAMÇI + AYAQLAR: buraxılan hərəkət əmsalla söner, axın 0.75 ilə aparır.
	var a := Sim.new()
	a.set_mode(Const.Mode.ENDLESS)
	var plain := a.add_germ(A_ID, "A", 0)
	var mut := a.add_germ(B_ID, "B", 1)
	mut.mutations = WHIP | STICKY
	for x in [plain, mut]:
		x.pos = Vector2(0.0, -300.0) if x == plain else Vector2(0.0, 300.0)
		x.vel = Vector2(100.0, 0.0)
	var flow_p := Const.current_at(plain.pos) * Const.SPECIES_FLOW[0]
	var flow_m := Const.current_at(mut.pos) * Const.SPECIES_FLOW[0] * 0.75
	var p0 := plain.pos
	var m0 := mut.pos
	a._step_germs({}, DT)
	var dp: Vector2 = (plain.pos - p0) / DT - flow_p
	var dm: Vector2 = (mut.pos - m0) / DT - flow_m
	var want_p := 100.0 * exp(-Const.FLUID_DRAG * Const.SPECIES_DRAG[0] * DT)
	var want_m := 100.0 * exp(-Const.FLUID_DRAG * Const.SPECIES_DRAG[0] * 0.8 * DT)
	_check(absf(dp.x - want_p) < 0.01 and absf(dm.x - want_m) < 0.01 and want_m > want_p
			and is_equal_approx(mut.speed(), plain.speed() * 0.95),
		"QAMÇI + AYAQLAR: sürüşmə əyləci zəif (%.2f > %.2f), axın ×0.75, sürət ×0.95" % [dm.x, dp.x])


static func _test_death_resets() -> void:
	var w := _world(87)
	var g := _germ(w)
	g.age = 95.0
	w.choose_mutation(A_ID, Const.Mut.LONG)
	w.choose_mutation(A_ID, Const.Mut.STICKY)
	var had := g.mutations
	# Acından partlayır — həqiqi ölüm yolu; SONSUZ ARENA-da oyunçu yenidən girir.
	g.balls = 0
	w.tick(DT)
	var gone := not w.sim.germs.has(A_ID)
	w.drop_peer(A_ID)
	w.add_player(A_ID, "A")
	w.tick(DT)
	var fresh := _germ(w)
	_check(had == LONG | STICKY and gone and fresh.mutations == 0
			and int(w.snapshot_for(A_ID)[Const.Snap.EVO]) == 0
			and w.choose_mutation(A_ID, Const.Mut.LONG) == "early",
		"ölüm mutasiyaları, açılmış seçimləri və yaşı sıfırlayır")


# ---------------------------------------------------------------- şəbəkə

static func _test_roundtrips() -> void:
	var g := Sim.GermState.new()
	g.mutations = WHIP | STICKY
	_check(g.clone().mutations == WHIP | STICKY, "GermState.clone mutasiyaları saxlayır")

	var ok := true
	for ev in [-1, 0, 1, 2]:
		var i := Sim.PlayerInput.make(7, Vector2(0.5, 0.0), 1.0, true)
		i.fire_range = 300.0
		i.newbie = true
		i.evolve = ev
		var back := Sim.PlayerInput.from_array(i.to_array())
		ok = ok and back.evolve == ev and back.fire and back.newbie and back.fire_range == 300.0
	_check(ok, "girişin seçim biti gedib-gəlir, atəş/yeni oyunçu/məsafə bitləri pozulmur")

	var w := _world(88)
	var me := _germ(w)
	me.mutations = LONG | STICKY
	me.charge = Const.SUPER_MAX
	me.team = 3
	var flags := World._flags_of(me)
	_check((flags & Const.GFlag.MUT_MASK) >> Const.GFlag.MUT_SHIFT == LONG | STICKY
			and (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT == Const.SUPER_MAX
			and ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) == 4
			and float(flags) == float(int(float(flags))),
		"bayraq: mutasiya bitləri doluluğu və komandanı pozmur, float32-də dəqiqdir (%d)" % flags)

	var meta := Const.shot_meta(Const.Shot.LOB, 2, 65535, true)
	_check(Const.meta_long(meta) and Const.meta_volley(meta) == 65535 and Const.meta_payload(meta) == 2
			and Const.meta_profile(meta) == Const.Shot.LOB and not Const.meta_long(Const.shot_meta(0, 2, 5)),
		"top META-sının uzun çıxıntı biti qrupu, yükü və profili pozmur")


## Bağlantını bərpa edən sağ mikrob mutasiyalarını və açılmış seçimlərini saxlayır.
static func _test_rejoin_keeps() -> void:
	var w := _world(89)
	var g := _germ(w)
	g.age = 60.0
	w.choose_mutation(A_ID, Const.Mut.WHIP)
	w.suspend_peer(A_ID)
	for _i in 30:
		w.tick(DT)
	w.resume_peer(A_ID, B_ID)
	w.tick(DT)
	var back: Sim.GermState = w.sim.germs.get(B_ID)
	_check(back != null and back.mutations == WHIP and int(w.snapshot_for(B_ID)[Const.Snap.EVO]) == 1
			and (int(w.snapshot_for(B_ID)[Const.Snap.GERMS][1][7]) & Const.GFlag.MUT_MASK) != 0,
		"yenidən qoşulan mikrob mutasiyasını və seçim sayını saxlayır")


## Proqnoz və server eyni paylaşılan funksiya ilə hərəkət edir — mutasiya ilə də.
static func _test_prediction_matches_server() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ENDLESS)
	var g := s.add_germ(A_ID, "A", 0)
	g.pos = Vector2(-150.0, 560.0)
	g.vel = Vector2.ZERO
	g.mutations = WHIP | STICKY
	g.balls = 9
	var p := Sim.new()
	p.set_mode(Const.Mode.ENDLESS)
	p.germs[A_ID] = g.clone()
	var worst := 0.0
	for i in 90:
		var inp := Sim.PlayerInput.make(i, Vector2.RIGHT if i < 40 else Vector2.ZERO, 0.4, i == 10)
		s.step({A_ID: inp}, DT)
		var pi := Sim.PlayerInput.make(i, Vector2.RIGHT if i < 40 else Vector2.ZERO, 0.4, i == 10)
		p.step_movement({A_ID: pi}, DT)
		worst = maxf(worst, s.germs[A_ID].pos.distance_to(p.germs[A_ID].pos))
	_check(worst < 0.001, "proqnoz serverlə eyni yolu gedir (QAMÇI + AYAQLAR, atəş və sürüşmə; fərq %.4f px)" % worst)

	var ghost := ShotPrediction.new().spawn(Vector2.ZERO, Vector2.RIGHT, 0.0, -1.0, Const.Shot.DART, LONG)
	var lob := ShotPrediction.new().spawn_lob(Vector2.ZERO, Vector2(500.0, 0.0), 0.0, LONG)
	var srv := Sim.new()
	srv.set_mode(Const.Mode.ENDLESS)
	var sg := srv.add_germ(A_ID, "A", 0, false, Const.Species.AMOEBA)
	sg.mutations = LONG
	sg.pos = Vector2(0.0, -600.0)
	sg.aim = 0.0
	srv._fire(sg, -1.0, 0.0, false, Vector2.INF, 520.0)
	var sl := srv.shots[0] if not srv.shots.is_empty() else null
	_check(is_equal_approx(ghost.speed, Const.shot_speed(Const.Shot.DART, LONG))
			and is_equal_approx(ghost.life, Const.shot_life(Const.Shot.DART, LONG))
			and sl != null and is_equal_approx(lob.flight, sl.flight)
			and sl.target.distance_to(sg.pos) > Const.LOB_MAX + 1.0,
		"öz topunun proqnozu serverlə eyni sürət, ömür və damcı uçuşu (%.2f s), 520 px-ə düşür"
			% (sl.flight if sl != null else -1.0))


## Havadakı top mutasiya sonradan seçilsə də qaydasını dəyişmir.
static func _test_shot_keeps_rule_midair() -> void:
	var s := Sim.new()
	s.set_mode(Const.Mode.ENDLESS)
	var g := s.add_germ(A_ID, "A", 0)
	g.pos = Vector2(0.0, -560.0)
	g.balls = 9
	s._fire(g)
	var sh := s.shots[0]
	var speed0 := sh.speed
	var life0 := sh.life
	g.mutations = LONG
	s._step_shots(DT)
	_check(sh.speed == speed0 and absf(sh.life - (life0 - DT)) < 0.0001 and not sh.long,
		"atılmış top sonradan seçilən UZUN ÇIXINTI ilə dəyişmir")


static func _test_standard_unchanged() -> void:
	var w := SimTest._quiet_world(90)
	w.add_player(A_ID, "A")
	w.sim.germs[A_ID].age = 200.0
	w.tick(DT)
	var snap := w.snapshot_for(A_ID)
	_check(w.profile == Const.Profile.STANDARD and int(w.join_info_for(A_ID)["profile"]) == 0
			and int(snap[Const.Snap.EVO]) == -1 and w.choose_mutation(A_ID, 0) == "profile"
			and World.default_rules() == Const.Profile.STANDARD,
		"standart profil (bayraqsız proses): seçim yoxdur, EVO -1, join info 0")
	var ok := true
	for m in Const.Mode.values():
		World.default_profile = Const.Profile.MUTATIONS
		var x := World.new(91, m)
		World.default_profile = Const.Profile.STANDARD
		if m != Const.Mode.ENDLESS and x.profile != Const.Profile.STANDARD:
			ok = false
	_check(ok, "mutasiya profili yalnız SONSUZ ARENA-ya düşür — altı rejim standart qalır")


## Botlar eyni hədlərdə, eyni yoxlamadan keçən seçim edir.
static func _test_bots_choose_legally() -> void:
	World.default_profile = Const.Profile.MUTATIONS
	var w := World.new(92, Const.Mode.ENDLESS)
	World.default_profile = Const.Profile.STANDARD
	w.sim.rng.seed = 5
	w.tick(DT)
	var bots := w._bots.keys()
	var young: Sim.GermState = w.sim.germs[bots[0]]
	var mid: Sim.GermState = w.sim.germs[bots[1]]
	var old: Sim.GermState = w.sim.germs[bots[2]]
	young.age = 30.0
	mid.age = 50.0
	old.age = 200.0
	for _i in 3:
		w.tick(DT)
	var plan_ok := Const.has_mut(mid.mutations, Bot.MUT_PLAN[int(mid.species)][0])
	_check(young.mutations == 0 and Const.mut_count(mid.mutations) == 1
			and Const.mut_count(old.mutations) == 2 and plan_ok,
		"botlar yalnız açılan qədər seçir: 30 s → 0, 50 s → 1, 200 s → 2 (növünün planı ilə)")
	var bot: Bot = w._bots[bots[2]]
	var range_long := Bot.SPECIES_RANGE[int(old.species)]
	_check(Const.shot_reach(Const.shot_profile(int(old.species), false), old.mutations)
			>= Const.shot_reach(Const.shot_profile(int(old.species), false)) and bot != null
			and range_long > 0.0,
		"bot öz mutasiyasının məsafəsini hesablayır (paylaşılan funksiya ilə)")


static func _test_cards_ui() -> void:
	var cards := MutationCards.new()
	var got := []
	cards.chosen.connect(func(m: int) -> void: got.append(m))
	cards.set_state(1, 0, -1)
	var opened := cards.is_open()
	cards.key(1)
	var waiting := cards._waiting
	cards.set_state(1, 0, waiting)
	cards.key(0)
	cards.set_state(0, 1 << waiting, -1)
	var closed := not cards.is_open() and not cards._indicator.visible
	cards.set_state(1, 1 << waiting, -1)
	var offers := cards._offers.size()
	cards.toggle()
	var hidden := not cards.is_open() and cards._indicator.visible
	cards.toggle()
	cards.key(0)
	cards.reject()
	var again := cards._waiting == -1 and cards.is_open()
	cards.free()
	_check(opened and got.size() == 2 and got[0] == Const.Mut.WHIP and waiting == Const.Mut.WHIP
			and closed and offers == 2 and hidden and again,
		"kartlar: seçim açılanda açılır, 2-ci kart seçilir, təsdiqə qədər ikinci seçim yoxdur, "
			+ "bağlanıb göstəricidən açılır, rədd olunsa yenə seçilir")


## Ən pis paket: 10 mikrobun hamısı iki mutasiyalı, uçan toplar — MTU-ya sığır.
static func _test_snapshot_size() -> void:
	var w := _world(93)
	w._seeded = false
	w.tick(DT)
	while w.sim.germs.size() < Const.WORLD_CAPACITY:
		w._add_bot()
	var me := _germ(w)
	me.age = 100.0
	var k := 0
	for gid in w.sim.germs:
		var g: Sim.GermState = w.sim.germs[gid]
		g.mutations = LONG | WHIP
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
	_check(size < Const.MTU_SAFE, "mutasiyalı ən pis snapshot MTU-ya sığır: %d bayt" % size)
