class_name SimTest
extends RefCounted
## [Sim] və [World] üçün headless testlər.
##
##   Godot_v4.7.2.exe --headless --path game -- --simtest
##
## Simulyasiya oyunun yeganə həqiqət mənbəyidir — UI-dan əvvəl onun
## düzgünlüyünü sübut etmək lazımdır. Xüsusilə oyunun İKİ ölüm qaydası
## (dolub partlamaq və acından partlamaq) burada bir-bir yoxlanılır.

const A_ID := 101
const B_ID := 202

## Maneəsiz dəhliz: y = 200 xətti bütün selik ləkələrindən kənardadır
## (bax [DishMap] — mərkəzi ləkə r=120, birinci halqa 400 məsafədə).
const LANE_Y := 200.0

static var _fail := 0
static var _pass := 0


static func run() -> int:
	_fail = 0
	_pass = 0
	print("\n===== Sim testləri =====")
	_test_shot_injects()
	_test_overfill_bursts()
	_test_starvation_bursts()
	_test_fire_floor()
	_test_no_self_hit()
	_test_obstacle_blocks_shot()
	_test_spawn_safety()
	_test_food_absorb()
	_test_food_ignored_when_full()
	_test_burst_scatters_food()
	_test_dish_confines()
	_test_leaderboard()
	_test_world_flow()
	_test_world_view_filter()
	_test_world_keeps_population()
	_test_address_parsing()
	_test_fire_button()
	print("===== %d keçdi, %d uğursuz =====\n" % [_pass, _fail])
	return _fail


# ---------------------------------------------------------------- oyunun qaydası

## Atılan top rəqibin İÇİNƏ keçir və bölünür: atanda −1, dəyəndə +SHOT_PAYLOAD.
static func _test_shot_injects() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]

	_fire_once(s, a, 0.0, 24)

	_check(a.balls == Const.START_BALLS - 1,
		"atan bir top itirir (%d → %d)" % [Const.START_BALLS, a.balls])
	_check(b.balls == Const.START_BALLS + Const.SHOT_PAYLOAD,
		"dəyən top içəridə bölünür: +%d (%d → %d)" % [Const.SHOT_PAYLOAD, Const.START_BALLS, b.balls])


## Tutumu aşan mikrob partlayır, partladan +5 tutum və +1 hesab alır.
static func _test_overfill_bursts() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.balls = b.capacity          # tam dolu — növbəti top onu partladacaq

	# `burst_log` hər tick-də təmizlənir, ona görə uçuş boyu yığılmış qeyd oxunur.
	var bursts := _fire_once(s, a, 0.0, 24)

	_check(not s.germs.has(B_ID), "dolu mikrob partladı (qalan mikrob: %d)" % s.germs.size())
	_check(a.capacity == Const.START_CAPACITY + Const.CAPACITY_STEP,
		"partladanın tutumu artdı (%d → %d)" % [Const.START_CAPACITY, a.capacity])
	_check(a.pops == 1, "partlatma sayı artdı (%d)" % a.pops)
	_check(bursts.size() == 1 and int(bursts[0]["killer"]) == A_ID,
		"partlama qeydində partladan yazılıb (%d qeyd)" % bursts.size())


## Metabolizm top sayını MIN_BALLS-dan aşağı salsa mikrob acından partlayır.
static func _test_starvation_bursts() -> void:
	var s := Sim.new()
	var g := s.add_germ(A_ID, "Ac", 0)
	g.safe_t = 0.0
	g.balls = Const.MIN_BALLS
	g.drain_t = Const.TICK_DELTA * 0.5     # növbəti tick-də bir top yanacaq

	s.step({}, Const.TICK_DELTA)

	_check(not s.germs.has(A_ID), "acından partladı (qalan: %d)" % s.germs.size())
	_check(s.burst_log.size() == 1 and int(s.burst_log[0]["killer"]) == 0,
		"aclıq partlamasının sahibi yoxdur (heç kim hesab almır)")


## Oyunçu ÖZ atəşi ilə özünü acından partlada bilməməlidir:
## FIRE_MIN_BALLS-dan az topla atəş açılmır.
static func _test_fire_floor() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	a.balls = Const.FIRE_MIN_BALLS - 1

	_fire_once(s, a, 0.0, 3)

	_check(s.shots.is_empty(), "az topla atəş açılmır (top sayı: %d)" % s.shots.size())
	_check(a.balls == Const.FIRE_MIN_BALLS - 1, "top sayı dəyişmədi (%d)" % a.balls)


## Öz atdığın top sənə dəymir.
static func _test_no_self_hit() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	s.germs.erase(B_ID)           # tək qalsın, qarşısında heç nə olmasın

	_fire_once(s, a, 0.0, 6)

	_check(a.balls == Const.START_BALLS - 1,
		"atıcıya öz topu dəymir (top sayı: %d)" % a.balls)


## Selik ləkəsi topu saxlayır — arxasındakı mikrob toxunulmazdır.
static func _test_obstacle_blocks_shot() -> void:
	var s := Sim.new()
	var a := s.add_germ(A_ID, "A", 0)
	var b := s.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	b.safe_t = 0.0
	# Mərkəzi ləkə (0,0,r=120) tam aralarındadır.
	a.pos = Vector2(-260.0, 0.0)
	b.pos = Vector2(260.0, 0.0)

	_fire_once(s, a, 0.0, 12)

	_check(b.balls == Const.START_BALLS,
		"maneə topu saxladı (hədəfin top sayı: %d)" % b.balls)


## Doğuş qalxanı: yeni doğulmuş mikroba top dəymir.
static func _test_spawn_safety() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.safe_t = Const.SPAWN_SAFE_TIME

	_fire_once(s, a, 0.0, 24)

	_check(b.balls == Const.START_BALLS,
		"qalxanlı mikroba top dəymir (top sayı: %d)" % b.balls)


# ---------------------------------------------------------------- qida

static func _test_food_absorb() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	s._drop_food(a.pos, Vector2.ZERO, 0)

	s.step({}, Const.TICK_DELTA)

	_check(a.balls == Const.START_BALLS + 1,
		"qida udmaq top sayını artırdı (%d)" % a.balls)


## Tutumu dolu mikrob yerdəki qidanı YEMİR — əks halda özünü partladardı.
static func _test_food_ignored_when_full() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	a.balls = a.capacity
	s._drop_food(a.pos, Vector2.ZERO, 0)

	s.step({}, Const.TICK_DELTA)

	_check(a.balls == a.capacity, "dolu mikrob qida udmur (%d/%d)" % [a.balls, a.capacity])


## Partlayan mikrobun içindəki toplar dünyaya səpilir — mükafat elə odur.
static func _test_burst_scatters_food() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.balls = b.capacity
	var before := s.food.size()

	_fire_once(s, a, 0.0, 24)

	_check(s.food.size() >= before + 3,
		"partlayışdan qida səpildi (%d → %d)" % [before, s.food.size()])


# ---------------------------------------------------------------- həndəsə

## Mikrob qabdan çıxa bilmir.
static func _test_dish_confines() -> void:
	var s := Sim.new()
	var g := s.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	g.pos = Vector2(Const.WORLD_RADIUS - 60.0, 0.0)

	for i in 90:
		s.step({A_ID: Sim.PlayerInput.make(i + 1, Vector2.RIGHT, 0.0, false)}, Const.TICK_DELTA)

	var limit := Const.WORLD_RADIUS - g.radius() + 0.5
	_check(g.pos.length() <= limit,
		"qabın kənarı saxlayır (məsafə %.1f, hədd %.1f)" % [g.pos.length(), limit])


static func _test_leaderboard() -> void:
	var s := Sim.new()
	for i in 3:
		var g := s.add_germ(100 + i, "M%d" % i, i)
		g.pops = i                       # M2 ən yaxşısı
	var board := s.leaderboard(5)
	_check(board.size() == 3 and String(board[0][Const.LF.NAME]) == "M2",
		"liderlər cədvəli partlatmaya görə sıralanır (birinci: %s)" % board[0][Const.LF.NAME])


# ---------------------------------------------------------------- server qatı

## Serverin [World] qatı: paketlənmiş giriş massivi → atəş → dəymə.
## [Sim] testləri keçsə də bu qat sınmış ola bilər, ona görə ayrıca yoxlanılır.
static func _test_world_flow() -> void:
	var world := World.new(1)
	# Botsuz dünya: bu test yalnız paket → atəş yolunu yoxlayır, botların
	# atdığı toplar nəticəni korlayardı.
	world._seeded = true
	var a := world.add_player(A_ID, "A")
	var b := world.add_player(B_ID, "B")
	a.safe_t = 0.0
	b.safe_t = 0.0

	var seq := 0
	for i in 30:
		# Açıq dəhlizdə sabit saxlayırıq ki, yalnız atəş yolu yoxlansın.
		a.pos = Vector2(-200.0, LANE_Y)
		a.vel = Vector2.ZERO
		b.pos = Vector2(100.0, LANE_Y)
		b.vel = Vector2.ZERO
		seq += 1
		if i == 0:
			world.accept_input(A_ID, Sim.PlayerInput.make(seq, Vector2.ZERO, 0.0, true).to_array())
		world.tick(Const.TICK_DELTA)

	_check(b.balls == Const.START_BALLS + Const.SHOT_PAYLOAD,
		"World: paket → atəş → dəymə (hədəfin top sayı: %d)" % b.balls)

	var snap := world.snapshot_for(A_ID)
	_check(snap.size() == 7, "snapshot quruluşu düzgündür (%d sahə)" % snap.size())
	_check(snap[Const.Snap.GERMS].size() >= 2,
		"snapshot mikrobları daşıyır (%d)" % snap[Const.Snap.GERMS].size())


## Görüş sahəsi süzgəci: uzaqdakı obyektlər şəbəkəyə düşmür.
static func _test_world_view_filter() -> void:
	var world := World.new(2)
	world._seeded = true
	var a := world.add_player(A_ID, "A")
	a.safe_t = 0.0
	a.pos = Vector2(0.0, LANE_Y)

	world.sim.food.clear()
	world.sim._drop_food(a.pos + Vector2(100.0, 0.0), Vector2.ZERO, 0)          # yaxın
	world.sim._drop_food(Vector2(0.0, -Const.WORLD_RADIUS + 50.0), Vector2.ZERO, 0)  # uzaq
	world._build_frame()

	var snap := world.snapshot_for(A_ID)
	# Qida sıx ədəd axınıdır: hər qida üçün FOOD_STRIDE ədəd.
	var seen: int = snap[Const.Snap.FOOD].size() / Const.FOOD_STRIDE
	_check(seen == 1, "uzaqdakı qida göndərilmir (görünən: %d)" % seen)


## Dünya boş qalmır: çatmayan yer botlarla doldurulur.
static func _test_world_keeps_population() -> void:
	var world := World.new(3)
	world.add_player(A_ID, "A")
	# Hər bot BOT_RESPAWN saniyədən bir gəlir.
	var ticks := int((Const.MIN_POPULATION + 1) * World.BOT_RESPAWN / Const.TICK_DELTA)
	for i in ticks:
		world.tick(Const.TICK_DELTA)

	_check(world.sim.germs.size() >= Const.MIN_POPULATION,
		"botlar əhalini saxlayır (%d / %d)" % [world.sim.germs.size(), Const.MIN_POPULATION])


# ---------------------------------------------------------------- client qatı

## Server ünvanının ayrılması. Railway URL-i buradan keçir — səhv ayrılsa
## oyun ümumiyyətlə qoşula bilmir, ona görə hər forma ayrıca yoxlanılır.
static func _test_address_parsing() -> void:
	var cases := [
		# [giriş, gözlənilən host, gözlənilən port]
		[Const.DEFAULT_SERVER, Const.DEFAULT_SERVER, 0],
		["ws://127.0.0.1:27015", "ws://127.0.0.1:27015", 0],
		["127.0.0.1:27015", "127.0.0.1", 27015],
		["192.168.1.5", "192.168.1.5", Const.DEFAULT_PORT],
		["  10.0.0.7:9000  ", "10.0.0.7", 9000],
		["", "127.0.0.1", Const.DEFAULT_PORT],
	]
	var ok := true
	for c in cases:
		var got: Array = MainMenu.parse_address(c[0])
		if got[0] != c[1] or int(got[1]) != int(c[2]):
			ok = false
			printerr("       '%s' → %s:%s (gözlənilən %s:%s)" % [c[0], got[0], got[1], c[1], c[2]])
	_check(ok, "server ünvanı %d formada düzgün ayrılır" % cases.size())


## Atəş düyməsi. Ən təhlükəli hal barmağın qalxmasının itməsidir: düymə
## "basılı" ilişər və oyunçu dayanmadan atar. Ona görə buraxılma düymənin
## üstündə yox, qlobal olaraq barmaq indeksinə görə tutulur.
static func _test_fire_button() -> void:
	var btn := FireButton.new()
	btn.size = Vector2(200.0, 200.0)
	var shots := [0]
	btn.fired.connect(func() -> void: shots[0] += 1)

	btn._gui_input(_touch(0, true))
	_check(btn.held and shots[0] == 1, "düymə basıldı (atəş siqnalı=%d)" % shots[0])

	# Başqa barmağın qalxması bu düyməyə aid deyil.
	btn._input(_touch(1, false))
	_check(btn.held, "yad barmaq düyməni buraxmır")

	btn._input(_touch(0, false))
	_check(not btn.held, "barmaq qalxanda düymə buraxılır")

	btn._gui_input(_touch(0, true))
	btn.cancel()
	_check(not btn.held, "cancel() düyməni buraxır")

	btn.free()


# ---------------------------------------------------------------- köməkçilər

## İki mikrob, maneəsiz dəhlizdə üz-üzə. Doğuş qalxanı söndürülür —
## testlərin çoxu məhz dəymə davranışını yoxlayır.
static func _fresh() -> Sim:
	var s := Sim.new()
	var a := s.add_germ(A_ID, "A", 0)
	var b := s.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	b.safe_t = 0.0
	a.pos = Vector2(-200.0, LANE_Y)
	b.pos = Vector2(100.0, LANE_Y)
	a.aim = 0.0
	b.aim = PI
	return s


## Bir dəfə atəş açır və topun uçuşunu izləyir. Atıcı yerində saxlanılır,
## çünki geri təpmə onu sürüşdürər və hədəf xəttindən çıxarardı.
static func _fire_once(s: Sim, shooter: Sim.GermState, aim: float, ticks: int) -> Array:
	var bursts := []
	var pos := shooter.pos
	for i in ticks:
		shooter.pos = pos
		shooter.vel = Vector2.ZERO
		var inputs := {}
		if i == 0:
			inputs[shooter.id] = Sim.PlayerInput.make(1, Vector2.ZERO, aim, true)
		s.step(inputs, Const.TICK_DELTA)
		bursts.append_array(s.burst_log)
	return bursts


static func _touch(index: int, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = Vector2(100.0, 100.0)
	return e


static func _check(ok: bool, label: String) -> void:
	if ok:
		_pass += 1
		print("  [OK]   %s" % label)
	else:
		_fail += 1
		printerr("  [FAIL] %s" % label)
