class_name ColonyTest
extends RefCounted
## SONSUZ ARENA-nın qida koloniyaları (design/MODES.md §18) — headless testlər. [SimTest]-in
## içindən işləyir, eyni sayğacla.
##
## Koloniya ətrafına adi +1 qida çıxarır: bol olan 20 ehtiyatla hər 0.45 s, zəif olan 12
## ehtiyatla hər 0.8 s; tükənəndə 24 / 30 s sonra bərpa olunur. Dünyada mənşəyinə görə ən
## çoxu 8 udulmamış qidası olur. Səpələnmiş qidanın ayrıca canlı minimumu 32-dir.

const DT := Const.TICK_DELTA
const SEED := 4242
const A_ID := 101
const B_ID := 202


static func run() -> int:
	var fail0 := SimTest._fail
	print("\n----- Qida koloniyaları -----")
	_test_placement_layouts()
	_test_same_seed()
	_test_only_endless()
	_test_depletion_and_regen()
	_test_regen_keeps_old_food()
	_test_rhythm()
	_test_out_cap()
	_test_drift_keeps_origin()
	_test_eaten_frees_slot()
	_test_no_burst_after_pause()
	_test_big_step_bounded()
	_test_scatter_minimum()
	_test_loose_food_not_scatter()
	_test_total_target_pauses_colonies()
	_test_food_spawn_valid()
	_test_net_pull_no_dup()
	_test_join_and_snapshot()
	_test_late_join_and_loss()
	_test_bot_picks_colony()
	_test_bot_leaves_depleted()
	_test_bot_threat_visible_only()
	_test_bot_avoids_threat()
	_test_full_bot_not_sent()
	return SimTest._fail - fail0


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


## Koloniyalı, mikrobsuz SONSUZ ARENA.
static func _endless(seed := SEED) -> Sim:
	var s := Sim.new()
	s.rng.seed = seed
	s.set_mode(Const.Mode.ENDLESS)
	s.setup_colonies(seed)
	return s


## Mənşəyi [param origin] olan qidanın sayı.
static func _count(s: Sim, origin: int) -> int:
	var n := 0
	for f in s.food:
		if f.origin == origin:
			n += 1
	return n


## Koloniyanın qidasını yeyilmiş kimi silir (həqiqi udma ayrıca testdədir); neçəsi silindi.
static func _take(s: Sim, origin: int) -> int:
	var kept: Array[Sim.FoodState] = []
	var n := 0
	for f in s.food:
		if f.origin == origin:
			n += 1
		else:
			kept.append(f)
	s.food = kept
	return n


static func _steps(s: Sim, secs: float) -> void:
	for _i in int(round(secs / DT)):
		s.step({}, DT)


# ---------------------------------------------------------------- yerləşmə

## Üç ümumi düzümün hər birində, 40 toxumda dörd koloniyanın dördü də qoyulur: məsafə
## növünə uyğundur, sahəsi şüşənin içində və hər maneədən aralıdır, koloniyalar bir-birindən
## aralıdır, ən azı iki ayrı tərəfdən yaxınlaşmaq olur.
static func _test_placement_layouts() -> void:
	var keep := DishMap.layout
	for layout in 3:
		DishMap.layout = layout
		var list := DishMap.obstacles()
		var bad := 0
		var missing := 0
		var fewest := 8
		for k in 40:
			var spots := DishMap.colony_spots(list, Const.WORLD_RADIUS, k * 7919 + 13)
			if spots.size() != Const.COLONY_KINDS.size():
				missing += 1
				continue
			for i in spots.size():
				var p := Vector2(spots[i].x, spots[i].y)
				var kind := int(spots[i].z)
				var span: Vector2 = Const.COLONY_DIST[kind]
				var ok := kind == int(Const.COLONY_KINDS[i]) \
					and p.length() >= span.x - 0.5 and p.length() <= span.y + 0.5 \
					and p.length() <= Const.WORLD_RADIUS - Const.COLONY_CLEAR
				for o in list:
					if p.distance_to(Vector2(o.x, o.y)) < o.z + Const.COLONY_CLEAR:
						ok = false
				for j in i:
					if p.distance_to(Vector2(spots[j].x, spots[j].y)) < Const.COLONY_GAP:
						ok = false
				var sides := DishMap.colony_sides(list, Const.WORLD_RADIUS, p)
				fewest = mini(fewest, sides)
				if not ok or sides < 2:
					bad += 1
		_check(missing == 0 and bad == 0,
			"%s: 40 toxumda dörd koloniya da etibarlı yerdədir (səhv %d, çatışmayan %d, ən az %d tərəf)"
				% [DishMap.layout_name(layout), bad, missing, fewest])
	DishMap.layout = keep
	DishMap.obstacles()


## Yer toxumdan deterministik çıxır; bütün iqtisadiyyat da eyni toxumla təkrarlanır.
static func _test_same_seed() -> void:
	var list := DishMap.obstacles()
	var a := DishMap.colony_spots(list, Const.WORLD_RADIUS, 99)
	var b := DishMap.colony_spots(list, Const.WORLD_RADIUS, 99)
	var c := DishMap.colony_spots(list, Const.WORLD_RADIUS, 100)
	_check(a == b and a != c, "eyni toxum eyni yerləri verir, başqa toxum başqa yerləri")

	var w1 := World.new(1)
	var w2 := World.new(2)
	w2.sim.setup_colonies(w1.sim.colony_seed)
	_check(w1.sim.colonies.size() == 4 and w1.sim.colony_flat() == w2.sim.colony_flat(),
		"SONSUZ ARENA dünyasında dörd koloniya var; eyni toxumlu iki dünyada yerlər eynidir")

	var s1 := _endless(5)
	var s2 := _endless(5)
	_steps(s1, 20.0)
	_steps(s2, 20.0)
	var same := s1.food.size() == s2.food.size() and s1.colony_bytes() == s2.colony_bytes()
	if same:
		for k in s1.food.size():
			if s1.food[k].pos != s2.food[k].pos or s1.food[k].origin != s2.food[k].origin:
				same = false
				break
	_check(same, "eyni toxumla qida iqtisadiyyatı təkrarlanır (%d qida)" % s1.food.size())


## Digər altı rejimdə koloniya yoxdur, qida köhnə qayda ilə doğulur; client-in proqnozu da
## koloniyasızdır.
static func _test_only_endless() -> void:
	var clean := true
	for m in [Const.Mode.SOLO, Const.Mode.DUO, Const.Mode.TRIO, Const.Mode.MOTHER,
			Const.Mode.ISLAND, Const.Mode.BALL]:
		var w := World.new(1, m)
		w.add_player(A_ID, "A")
		w.tick(DT)
		var snap := w.snapshot_for(A_ID)
		if not w.sim.colonies.is_empty() or not (w.join_info_for(A_ID)["colonies"] as PackedFloat32Array).is_empty() \
				or not (snap[Const.Snap.COLONY] as PackedByteArray).is_empty():
			clean = false
	_check(clean, "digər altı rejimdə koloniya yoxdur — join info və snapshot-da boşdur")

	var p := Sim.new()
	p.set_mode(Const.Mode.ENDLESS)
	_check(p.colonies.is_empty(), "client-in proqnoz simulyasiyası koloniyasızdır")

	var s := Sim.new()
	s.rng.seed = 3
	s.set_mode(Const.Mode.SOLO)
	_steps(s, 20.0)
	var scattered := _count(s, Const.ORIGIN_SCATTER)
	_check(s.food.size() == s._food_target() and scattered == s.food.size(),
		"TƏK QALAN-da qida köhnə hədəfə dolur (%d / %d)" % [s.food.size(), s._food_target()])


# ---------------------------------------------------------------- ehtiyat və ritm

## Bol koloniya 20 qida verib tükənir, 24 s heç nə vermir, sonra dolu bərpa olunur.
static func _test_depletion_and_regen() -> void:
	var s := _endless()
	var c := s.colonies[0]
	var made := 0
	var t := 0.0
	var empty_at := -1.0
	while t < 12.0:
		s.step({}, DT)
		t += DT
		made += _take(s, 0)
		if c.stock == 0 and empty_at < 0.0:
			empty_at = t
	var want_empty := DT + 19.0 * float(Const.COLONY_PERIOD[0])
	_check(c.kind == Const.ColonyKind.RICH and made == Const.COLONY_STOCK[0]
			and absf(empty_at - want_empty) < DT * 2.0,
		"bol koloniya %d qida verib tükənir (%d qida, %.2f s; gözlənilən %.2f s)"
			% [Const.COLONY_STOCK[0], made, empty_at, want_empty])

	var back_at := -1.0
	var silent := true
	while t < empty_at + 27.0:
		s.step({}, DT)
		t += DT
		var n := _take(s, 0)
		if back_at < 0.0:
			if n > 0:
				back_at = t
			elif c.stock != 0:
				silent = false
	_check(silent and absf(back_at - empty_at - Const.COLONY_REGEN[0]) < DT * 2.0,
		"tükənmiş koloniya %.0f s susur, sonra bərpa olunur (%.2f s)"
			% [Const.COLONY_REGEN[0], back_at - empty_at])
	_check(c.stock == Const.COLONY_STOCK[0] - 1 - int((t - back_at) / Const.COLONY_PERIOD[0] + 0.0001),
		"bərpadan sonra ehtiyat yenə dolu sayılır və ritm davam edir (ehtiyat %d)" % c.stock)


## Bərpa əvvəlki qidanı silmir və çıxış həddi bərpadan sonra da işləyir.
static func _test_regen_keeps_old_food() -> void:
	var s := _endless()
	var cid := 2
	var c := s.colonies[cid]
	var kept := {}
	while c.stock > 0:
		s.step({}, DT)
		var rest: Array[Sim.FoodState] = []
		for f in s.food:
			if f.origin == cid and kept.size() < 3 and not kept.has(f.id):
				kept[f.id] = true
			if f.origin != cid or kept.has(f.id):
				rest.append(f)
		s.food = rest
	_steps(s, Const.COLONY_REGEN[c.kind] + 10.0)
	var still := 0
	for f in s.food:
		if kept.has(f.id):
			still += 1
	_check(c.kind == Const.ColonyKind.POOR and still == 3 and _count(s, cid) == Const.COLONY_OUT_MAX
			and c.stock == Const.COLONY_STOCK[1] - (Const.COLONY_OUT_MAX - 3),
		"bərpa köhnə qidanı silmir (%d/3 qalıb), çıxış həddi işləyir (çıxış %d, ehtiyat %d)"
			% [still, _count(s, cid), c.stock])


## İstehsal ritmi: bol 0.45 s, zəif 0.8 s.
static func _test_rhythm() -> void:
	var s := _endless()
	var rich := 0
	var poor := 0
	var t := 0.0
	while t < 8.0 - DT * 0.5:
		s.step({}, DT)
		t += DT
		if t <= 4.5 - DT * 0.5:
			rich += _take(s, 0)
		else:
			_take(s, 0)
		poor += _take(s, 2)
	_check(rich == 10 and poor == 10,
		"ritm: bol koloniya 4.5 s-də %d qida (10), zəif 8 s-də %d (10)" % [rich, poor])


## Udulmayan qida 8-ə çatanda istehsal dayanır.
static func _test_out_cap() -> void:
	var s := _endless()
	_steps(s, 10.0)
	var ok := true
	for c in s.colonies:
		if _count(s, c.id) != Const.COLONY_OUT_MAX \
				or c.stock != Const.COLONY_STOCK[c.kind] - Const.COLONY_OUT_MAX:
			ok = false
	var before := s.colony_bytes()
	_steps(s, 5.0)
	_check(ok and s.colony_bytes() == before,
		"hər koloniyanın dünyada ən çoxu %d udulmamış qidası olur — sonra istehsal dayanır"
			% Const.COLONY_OUT_MAX)


## Axın qidanı uzağa aparsa da mənşəyi dəyişmir: koloniya yaxın radiusu boşaldıb sonsuz
## istehsal etmir.
static func _test_drift_keeps_origin() -> void:
	var s := _endless()
	_steps(s, 6.0)
	var c := s.colonies[0]
	for f in s.food:
		if f.origin == 0:
			f.pos = -c.pos.normalized() * 300.0 + Vector2(s.rng.randf_range(-40, 40), 0.0)
	var stock := c.stock
	_steps(s, 4.0)
	_check(_count(s, 0) == Const.COLONY_OUT_MAX and c.stock == stock and c.near == 0,
		"uzağa sürüşən qida hələ də koloniyanındır — istehsal yenidən başlamır (ehtiyat %d)" % c.stock)


## Həqiqi udma: koloniyanın yanında dayanan mikrob yedikcə yer açılır və istehsal davam edir.
static func _test_eaten_frees_slot() -> void:
	var s := _endless()
	var c := s.colonies[0]
	var g := s.add_germ(A_ID, "A", 0)
	g.capacity = Const.MAX_CAPACITY
	g.balls = 2
	g.pos = c.pos
	g.vel = Vector2.ZERO
	var balls0 := g.balls
	_steps(s, 6.0)
	var made := Const.COLONY_STOCK[0] - c.stock
	_check(made > Const.COLONY_OUT_MAX and g.balls > balls0 and _count(s, 0) <= Const.COLONY_OUT_MAX,
		"yeyilən qida yer açır: 6 s-də %d qida çıxdı, mikrob %d → %d top" % [made, balls0, g.balls])


## Gözləmə borc yığmır: uzun dayanmadan sonra yer açılsa da bir tick-də bir qida çıxır.
static func _test_no_burst_after_pause() -> void:
	var s := _endless()
	_steps(s, 25.0)
	_take(s, 0)
	s.step({}, DT)
	var first := _count(s, 0)
	_steps(s, 0.2)
	var later := _count(s, 0)
	_steps(s, 0.4)
	_check(first == 1 and later == 1 and _count(s, 0) == 2,
		"25 s gözləmədən sonra 8 yer açılır: əvvəl 1 qida (%d), 0.2 s sonra yenə 1 (%d), ritmlə 2 (%d)"
			% [first, later, _count(s, 0)])


## Böyük addımda da hədlər qalır: koloniya başına ən çoxu 8, səpələnmiş 32, büdcə yığılmır.
static func _test_big_step_bounded() -> void:
	var s := _endless()
	s.step({}, 5.0)
	s.step({}, 60.0)
	var ok := _count(s, Const.ORIGIN_SCATTER) <= Const.SCATTER_TARGET and s._food_budget <= 1.0
	for c in s.colonies:
		ok = ok and _count(s, c.id) <= Const.COLONY_OUT_MAX
	_check(ok and s.food.size() <= Const.SCATTER_TARGET + 4 * Const.COLONY_OUT_MAX,
		"5 və 60 saniyəlik addımda borc yığılmır (%d qida)" % s.food.size())


# ---------------------------------------------------------------- səpələnmiş minimum

## Səpələnmiş qida 32-yə adi doğuş sürəti ilə qayıdır — bir tick-də yox.
static func _test_scatter_minimum() -> void:
	var s := _endless()
	_steps(s, 6.0)
	var full := _count(s, Const.ORIGIN_SCATTER)
	var gone := 0
	var rest: Array[Sim.FoodState] = []
	for f in s.food:
		if f.origin == Const.ORIGIN_SCATTER and gone < 10:
			gone += 1
		else:
			rest.append(f)
	s.food = rest
	_steps(s, 0.25)
	var soon := _count(s, Const.ORIGIN_SCATTER)
	_steps(s, 2.0)
	_check(full == Const.SCATTER_TARGET and soon < Const.SCATTER_TARGET
			and _count(s, Const.ORIGIN_SCATTER) == Const.SCATTER_TARGET,
		"səpələnmiş qida %d-yə dolur, yeyiləndə sürətlə hədlənmiş bərpa olunur (0.25 s sonra %d, 2 s sonra %d)"
			% [full, soon, _count(s, Const.ORIGIN_SCATTER)])


## Ölüm səpintisi və boşa çıxan top minimumun əvəzi sayılmır və limit üçün silinmir.
static func _test_loose_food_not_scatter() -> void:
	var s := _endless()
	_steps(s, 6.0)
	for i in 50:
		s._drop_food(Vector2.from_angle(float(i)) * 600.0, Vector2.ZERO, 0)
	var rest: Array[Sim.FoodState] = []
	var gone := 0
	for f in s.food:
		if f.origin == Const.ORIGIN_SCATTER and gone < 5:
			gone += 1
		else:
			rest.append(f)
	s.food = rest
	_steps(s, 2.0)
	_check(_count(s, Const.ORIGIN_LOOSE) == 50 and _count(s, Const.ORIGIN_SCATTER) == Const.SCATTER_TARGET
			and s.food.size() > s._food_target(),
		"səpinti minimuma sayılmır: %d səpinti qalıb, səpələnmiş yenə %d, ümumi %d > hədəf %d"
			% [_count(s, Const.ORIGIN_LOOSE), _count(s, Const.ORIGIN_SCATTER), s.food.size(), s._food_target()])


## Ümumi hədəf keçilibsə koloniyalar dayanır, səpələnmiş minimum isə ayrıca dolur.
static func _test_total_target_pauses_colonies() -> void:
	var s := _endless()
	for i in s._food_target() + 10:
		s._drop_food(s.find_spawn(Const.FOOD_RADIUS), Vector2.ZERO, 0)
	_steps(s, 5.0)
	var made := 0
	for c in s.colonies:
		made += Const.COLONY_STOCK[c.kind] - c.stock
	_check(made == 0 and _count(s, Const.ORIGIN_SCATTER) == Const.SCATTER_TARGET
			and _count(s, Const.ORIGIN_LOOSE) == s._food_target() + 10,
		"ümumi hədəf keçiləndə koloniyalar dayanır (%d qida çıxdı), səpələnmiş minimum yenə %d olur"
			% [made, _count(s, Const.ORIGIN_SCATTER)])


## Koloniyanın qidası şüşənin içində və maneədən kənarda, sahəsinin içində çıxır — üç
## düzümdə də.
static func _test_food_spawn_valid() -> void:
	var keep := DishMap.layout
	var bad := 0
	var made := 0
	for layout in 3:
		DishMap.layout = layout
		for k in 3:
			var s := _endless(1000 + k)
			var last := 0
			for _i in int(30.0 / DT):
				s.step({}, DT)
				for f in s.food:
					if f.id <= last or f.origin < 0:
						continue
					made += 1
					var c := s.colonies[f.origin]
					if not DishMap.is_free_in(s.obstacles, s.wall_radius, f.pos, Const.FOOD_RADIUS) \
							or f.pos.distance_to(c.pos) > Const.COLONY_SPREAD + 0.01:
						bad += 1
				for f in s.food:
					last = maxi(last, f.id)
				for c in s.colonies:
					_take(s, c.id)
	DishMap.layout = keep
	DishMap.obstacles()
	_check(made > 300 and bad == 0, "koloniyanın %d qidasının hamısı etibarlı yerdə çıxdı (səhv %d)" % [made, bad])


## Ayaqlının toru koloniyanın qidasını adi qida kimi çəkir: mənşə qalır, ehtiyat təkrarlanmır.
static func _test_net_pull_no_dup() -> void:
	var s := _endless()
	_steps(s, 2.0)
	var c := s.colonies[0]
	var g := s.add_germ(A_ID, "A", 0, false, Const.Species.HELIOZOAN)
	g.capacity = Const.MAX_CAPACITY
	g.balls = 30
	g.pos = c.pos + c.pos.normalized() * 110.0
	g.super_t = 6.0
	var ok := true
	var prev := c.stock
	var ids := {}
	for _i in int(4.0 / DT):
		s.step({}, DT)
		if _count(s, 0) > Const.COLONY_OUT_MAX or c.stock > prev:
			ok = false
		prev = c.stock
		ids.clear()
		for f in s.food:
			if ids.has(f.id):
				ok = false
			ids[f.id] = true
	_check(ok and g.in_net(), "ayaqlının toru koloniya qidasını çəkir, ehtiyat və çıxış təkrarlanmır")


# ---------------------------------------------------------------- şəbəkə

## Join info yerləri, hər snapshot vəziyyəti daşıyır.
static func _test_join_and_snapshot() -> void:
	var w := SimTest._quiet_world(71)
	w.add_player(A_ID, "A")
	var flat: PackedFloat32Array = w.join_info_for(A_ID)["colonies"]
	w.tick(DT)
	var bytes: PackedByteArray = w.snapshot_for(A_ID)[Const.Snap.COLONY]
	_check(flat.size() == 12 and flat == w.sim.colony_flat() and bytes == w.sim.colony_bytes()
			and bytes.size() == 8,
		"join info dörd koloniyanın yerini, snapshot isə vəziyyətini daşıyır (%d bayt)" % bytes.size())
	var c := w.sim.colonies[1]
	c.stock = 0
	c.regen_t = 10.3
	w.tick(DT)
	bytes = w.snapshot_for(A_ID)[Const.Snap.COLONY]
	_check(bytes[2] == 0 and bytes[3] == ceili((10.3 - DT) / Const.COLONY_REGEN_STEP),
		"tükənmiş koloniyanın sətri: ehtiyat 0, bərpaya %d × %.2f s" % [bytes[3], Const.COLONY_REGEN_STEP])
	_check(var_to_bytes(bytes).size() <= 16, "koloniyaların sətri snapshot-da ≤ 16 baytdır (%d)"
		% var_to_bytes(bytes).size())


## Gec qoşulan eyni yerləri və vəziyyəti alır; client paket itkisindən sonra növbəti
## snapshot-la düzəlir (tək hadisədən asılı deyil).
static func _test_late_join_and_loss() -> void:
	var w := SimTest._quiet_world(72)
	w.add_player(A_ID, "A")
	for _i in int(5.0 / DT):
		w.tick(DT)
	var c := w.sim.colonies[2]
	c.stock = 0
	c.regen_t = 10.0
	w.tick(DT)
	w.add_player(B_ID, "B")
	w.tick(DT)
	_check(w.join_info_for(B_ID)["colonies"] == w.join_info_for(A_ID)["colonies"]
			and w.snapshot_for(B_ID)[Const.Snap.COLONY] == w.snapshot_for(A_ID)[Const.Snap.COLONY],
		"gec qoşulan oyunçu eyni yerləri və eyni ehtiyat/vaxtı görür")

	var view := ColonyView.new()
	view.setup(w.sim.colony_flat())
	var full := w.sim.colony_bytes()
	full[4] = Const.COLONY_STOCK[1]
	full[5] = 0
	view.apply(full)
	view._process(0.1)
	# Aradakı snapshot-lar itdi — növbəti gələn tam vəziyyəti verir.
	var now := full.duplicate()
	now[4] = 0
	now[5] = 40
	view.apply(now)
	view._process(1.0)
	var ring := view.regen_progress(2)
	var want := 1.0 - (10.0 - 1.0) / Const.COLONY_REGEN[1]
	_check(view.count() == 4 and view.shown_fill(2) == 0.0 and absf(ring - want) < 0.02,
		"paket itkisindən sonra client düzəlir: doluluq 0, bərpa halqası %.2f (gözlənilən %.2f)" % [ring, want])
	now[5] = 4
	view.apply(now)
	_check(absf(view.regen_progress(2) - (1.0 - 1.0 / Const.COLONY_REGEN[1])) < 0.02,
		"serverin vaxtı fərqlənəndə halqa snapshot-a görə düzəlir")
	view.free()


# ---------------------------------------------------------------- botlar

## Bot üçün hazır vəziyyət: [param balls] / [param cap] toplu mikrob [param at]-da.
static func _bot_germ(s: Sim, at: Vector2, balls: int, cap := 10) -> Sim.GermState:
	var g := s.add_germ(A_ID, "bot", 0, true)
	g.capacity = cap
	g.balls = balls
	g.pos = at
	g.vel = Vector2.ZERO
	g.safe_t = 0.0
	return g


## Ac bot, yaxında qida yoxdursa, qidası olan koloniyaya gedir.
static func _test_bot_picks_colony() -> void:
	var s := _endless()
	s.step({}, DT)
	_take(s, Const.ORIGIN_SCATTER)
	var g := _bot_germ(s, Vector2(0.0, -40.0), 3)
	var bot := Bot.new(A_ID, 1.0, 1)
	var inp := bot.think(s, DT)
	var to_goal := (bot._colony_goal - g.pos).normalized() if bot._colony_goal.is_finite() else Vector2.ZERO
	_check(bot._colony_pick >= 0 and inp.move.dot(to_goal) > 0.5,
		"ac bot qidası olan koloniyaya gedir (seçim %d)" % bot._colony_pick)


## Tükənmiş koloniyada gözləmir — başqa mənbəyə keçir.
static func _test_bot_leaves_depleted() -> void:
	var s := _endless()
	s.step({}, DT)
	var c := s.colonies[0]
	c.stock = 0
	c.regen_t = 30.0
	_take(s, 0)
	var g := _bot_germ(s, c.pos, 4)
	var bot := Bot.new(A_ID, 1.0, 1)
	for _i in int(4.0 / DT):
		s.step({A_ID: bot.think(s, DT)}, DT)
	var away := g.pos.distance_to(c.pos) if s.germs.has(A_ID) else -1.0
	_check(away > 150.0 and bot._colony_pick != 0,
		"tükənmiş koloniyadakı ac bot 4 s-də uzaqlaşır (%.0f px), onu seçmir" % away)


## Təhlükə yalnız botun GÖRDÜYÜ rəqiblərdir: başqa koldakı və görüş sahəsindən kənardakı sayılmır.
static func _test_bot_threat_visible_only() -> void:
	var keep := DishMap.layout
	DishMap.layout = 0
	var s := Sim.new()
	s.set_mode(Const.Mode.ENDLESS)
	var me := _bot_germ(s, Vector2(-300.0, 0.0), 3)
	var foe := s.add_germ(B_ID, "B", 1)
	var at := Vector2(-500.0, -100.0)
	foe.pos = Vector2(-620.0, -215.0)
	var seen := Const.aoi_radius(me.capacity)
	var hidden := Bot._colony_threats(s, me, at, seen)
	foe.pos = Vector2(-480.0, -250.0)
	var open := Bot._colony_threats(s, me, at, seen)
	me.pos = Vector2(700.0, 400.0)
	var far := Bot._colony_threats(s, me, at, seen)
	DishMap.layout = keep
	DishMap.obstacles()
	_check(s.bush_of(foe) < 0 and hidden == 0 and open == 1 and far == 0,
		"kolda gizlənən rəqib (%d) və görünməyən uzaq rəqib (%d) sayılmır, açıqdakı sayılır (%d)"
			% [hidden, far, open])


## Bərabər iki koloniyadan yanında rəqib görünməyəni seçir.
static func _test_bot_avoids_threat() -> void:
	var s := _endless()
	s.step({}, DT)
	s.food.clear()
	for c in s.colonies:
		c.stock = 0
		c.near = 0
		c.out = 0
	var left := s.colonies[0]
	var right := s.colonies[1]
	left.pos = Vector2(-420.0, 300.0)
	right.pos = Vector2(420.0, 300.0)
	left.stock = 20
	right.stock = 20
	_bot_germ(s, Vector2(0.0, 300.0), 3)
	var foe := s.add_germ(B_ID, "B", 1)
	foe.pos = left.pos + Vector2(0.0, 120.0)
	var bot := Bot.new(A_ID, 1.0, 1)
	var picked := bot._pick_colony(s, s.germs[A_ID], null, DT)
	_check(picked and bot._colony_pick == right.id,
		"ac bot yanında rəqib görünən koloniyanı yox, digərini seçir (seçim %d)" % bot._colony_pick)


## Dolu bot koloniyaya göndərilmir.
static func _test_full_bot_not_sent() -> void:
	var s := _endless()
	s.step({}, DT)
	_take(s, Const.ORIGIN_SCATTER)
	_bot_germ(s, Vector2(0.0, -40.0), 10, 10)
	var bot := Bot.new(A_ID, 1.0, 1)
	bot.think(s, DT)
	_check(bot._colony_pick == -1, "dolu bot koloniyaya göndərilmir")
