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
	_test_fluid_glide()
	_test_current_field()
	_test_leaderboard()
	_test_world_flow()
	_test_world_view_filter()
	_test_world_keeps_population()
	_test_address_parsing()
	_test_fire_button()
	_test_germ_species()
	_test_heliozoan_gait()
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


## Maye hərəkəti: barmaq qalxandan sonra mikrob dərhal dayanmır, sürüşür.
## Bu, oyunun "su" hissinin əsasıdır — sınsa, idarəetmə kərpic kimi olur.
static func _test_fluid_glide() -> void:
	var s := Sim.new()
	var g := s.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	g.pos = Vector2(0.0, LANE_Y)

	# Bir saniyə itələ — sürət hədəfə çatsın.
	for i in Const.TICK_RATE:
		s.step({A_ID: Sim.PlayerInput.make(i + 1, Vector2.RIGHT, 0.0, false)}, Const.TICK_DELTA)
	var moving := g.vel.length()
	_check(moving > Const.germ_speed(g.capacity) * 0.85,
		"itələmə hədəf sürətə çatır (%.0f / %.0f px/s)" % [moving, Const.germ_speed(g.capacity)])

	# İndi burax — yarım saniyəyə hələ də hərəkətdə olmalıdır, amma yavaşımalıdır.
	#
	# Sürüşmə SUYA NİSBƏTƏN ölçülür: xam mövqe fərqinə axının apardığı yol da
	# daxildir və o, mikrobun harada dayandığından asılıdır. Axın gücləndirildikdə
	# bu ölçü 49 px-dən 31-ə düşdü — mikrob pisləşmədi, sadəcə həmin nöqtədə axın
	# ona qarşı idi. Axının payını eyni üsulla (Sim ilə üzbəüz) çıxırıq.
	var at_release := g.pos
	var drift := Vector2.ZERO
	for i in int(Const.TICK_RATE * 0.5):
		drift += Const.current_at(g.pos) * Const.TICK_DELTA
		s.step({}, Const.TICK_DELTA)
	var glided := (g.pos - at_release - drift).length()
	_check(glided > 30.0 and g.vel.length() < moving * 0.5,
		"buraxandan sonra sürüşür (%.0f px, sürət %.0f → %.0f)" % [glided, moving, g.vel.length()])


## Axın sahəsi: sabit, sərhəddə sıfır və divergensiyasız.
##
## Divergensiya vacibdir — sıfır olmasa sərbəst qida burulğanın mərkəzinə
## yığılıb ilişər və dünyanın bir hissəsi qidasız qalar.
static func _test_current_field() -> void:
	var probe := Vector2(180.0, -240.0)
	_check(Const.current_at(probe) == Const.current_at(probe),
		"axın sahəsi sabitdir (eyni nöqtə → eyni sürət)")

	var at_glass := Const.current_at(Vector2(Const.WORLD_RADIUS - 2.0, 0.0))
	_check(at_glass.length() < 0.5, "şüşənin dibində axın dayanır (%.3f px/s)" % at_glass.length())

	var cap := Const.CURRENT_STRENGTH * 2.0 + Const.CURRENT_SWIRL * 2.0
	var peak := 0.0
	var worst_div := 0.0
	var total := 0.0
	var inside := 0
	var h := 4.0
	for i in 60:
		for j in 60:
			var p := Vector2(float(i) - 29.5, float(j) - 29.5) * 38.0
			var speed := Const.current_at(p).length()
			peak = maxf(peak, speed)
			if p.length() <= Const.WORLD_RADIUS:
				total += speed
				inside += 1
			# ∂vx/∂x + ∂vy/∂y — mərkəzi fərqlə hesablanır.
			var dvx := Const.current_at(p + Vector2(h, 0)).x - Const.current_at(p - Vector2(h, 0)).x
			var dvy := Const.current_at(p + Vector2(0, h)).y - Const.current_at(p - Vector2(0, h)).y
			worst_div = maxf(worst_div, absf((dvx + dvy) / (2.0 * h)))

	_check(peak <= cap, "axın sürəti həddi aşmır (%.1f ≤ %.1f px/s)" % [peak, cap])

	# ── Aşağıdakı iki yoxlama axının HİSS OLUNMASINI qoruyur ──
	#
	# İlk versiya riyazi olaraq tamamilə düzgün idi (sabit, divergensiyasız,
	# şüşədə dayanan) və buna baxmayaraq oyunda GÖRÜNMÜRDÜ: orta sürət
	# BASE_SPEED-in cəmi 6.7%-i idi və bir burulğan ekrana sığmırdı.
	# "Düzgün işləyir" ilə "hiss olunur" ayrı şeylərdir — ikincisi də
	# ölçülməlidir, əks halda növbəti tənzimləmə onu yenidən söndürər.

	var mean := total / float(maxi(inside, 1))
	var floor_speed := Const.BASE_SPEED * 0.09
	_check(mean >= floor_speed,
		"axın hiss olunacaq qədər güclüdür (orta %.1f ≥ %.1f px/s, sürətin %.1f%%-i)"
			% [mean, floor_speed, 100.0 * mean / Const.BASE_SPEED])

	# Bir burulğan ekrana SIĞMALIDIR. Sığmasa ekrandakı bütün zərrəciklər eyni
	# tərəfə baxır və oyunçu fırlanmanı görmür — yalnız izahsız sürüşmə qalır.
	_check(Const.CURRENT_SCALE < Const.VIEW_WIDTH_BASE,
		"burulğan ekrana sığır (dalğa uzunluğu %.0f < ekran %.0f px)"
			% [Const.CURRENT_SCALE, Const.VIEW_WIDTH_BASE])
	_check(worst_div < 0.02,
		"axın divergensiyasız — qida burulğanda ilişmir (ən pis %.4f 1/s)" % worst_div)


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


## Bir dəfə atəş açır və topun uçuşunu izləyir.
##
## BÜTÜN mikroblar yerində saxlanılır: atıcını geri təpmə, hədəfi isə mayenin
## axını ([method Const.current_at]) hədəf xəttindən çıxarardı. Bu testlərin
## mövzusu topun yolu, hərəkət deyil — hərəkət ayrıca yoxlanılır
## (bax [method _test_fluid_glide]).
static func _fire_once(s: Sim, shooter: Sim.GermState, aim: float, ticks: int) -> Array:
	var bursts := []
	var anchor := {}
	for id in s.germs:
		anchor[id] = (s.germs[id] as Sim.GermState).pos
	for i in ticks:
		for id in anchor:
			if s.germs.has(id):
				var g: Sim.GermState = s.germs[id]
				g.pos = anchor[id]
				g.vel = Vector2.ZERO
		var inputs := {}
		if i == 0:
			inputs[shooter.id] = Sim.PlayerInput.make(1, Vector2.ZERO, aim, true)
		s.step(inputs, Const.TICK_DELTA)
		bursts.append_array(s.burst_log)
	return bursts


## Oyunçunun seçdiyi növ dünyaya girib snapshot-la geri qayıtmalıdır.
##
## Növ AYRICA sahə kimi göndərilmir — toxunulmazlıq bayrağının boş bitinə
## yerləşdirilib ([enum Const.GFlag]). Ona görə iki dəyər BİR ədədə yığılır
## və səhv paketlənsə nəticə səssiz olur: ya rəqib yanlış növdə görünər,
## ya da doğuş qalxanı işləməz. İkisi də burada yoxlanılır.
static func _test_germ_species() -> void:
	var world := World.new(9)
	world._seeded = true                  # botlar qarışmasın
	var walker := world.add_player(A_ID, "Ayaqlı", Const.Species.HELIOZOAN)
	var swimmer := world.add_player(B_ID, "Kirpikli", Const.Species.CILIATE)

	_check(walker.species == Const.Species.HELIOZOAN
			and swimmer.species == Const.Species.CILIATE,
		"seçilən növ mikroba yazılır")

	# Doğuş qalxanı ilə növ EYNİ ədədin içindədir — birlikdə yoxlanılır.
	walker.safe_t = Const.SPAWN_SAFE_TIME
	swimmer.safe_t = 0.0
	world._build_frame()
	var rows := {}
	for e in world.snapshot_for(A_ID)[Const.Snap.GERMS]:
		rows[int(e[Const.GF.ID])] = int(e[Const.GF.FLAGS])

	var wf: int = rows.get(A_ID, 0)
	var sf: int = rows.get(B_ID, 0)
	_check(wf & Const.GFlag.HELIOZOAN and not (sf & Const.GFlag.HELIOZOAN),
		"növ snapshot-dan düzgün oxunur (bayraqlar %d / %d)" % [wf, sf])
	_check(wf & Const.GFlag.SAFE and not (sf & Const.GFlag.SAFE),
		"toxunulmazlıq eyni ədəddə növü pozmur")

	# Növ üç ayrı ETİBARSIZ mənbədən gəlir: client-in paketi, serverin cavabı
	# və diskdəki ayar faylı. Üçü də eyni funksiyadan keçir, ona görə yad
	# dəyərin nəticəsi bir yerdə yoxlanılır.
	_check(Const.species_from(99) == Const.Species.CILIATE
			and Const.species_from(-3) == Const.Species.CILIATE
			and Const.species_from(1) == Const.Species.HELIOZOAN,
		"yad növ dəyəri kirpikliyə düşür")


## Ayaqlı mikrobun yerişi.
##
## Ekran görüntüsü bunu yoxlaya bilmir — kadr donuqdur, yeriş isə zamanla
## yaşayır. Üç xassə var və hər biri pozulanda hərəkət "yeriş" olmaqdan çıxır:
##   1. dayanan mikrob ayaqlarını tərpətməməlidir (yoxsa yerində titrəyir);
##   2. ayaqlar sonsuz dartılmamalıdır (yoxsa gövdədən qopmuş görünür);
##   3. ayaqların çoxu HƏR AN yerdə olmalıdır (yoxsa yeriş yox, sıçrayışdır).
static func _test_heliozoan_gait() -> void:
	var g := GermVisual.new()
	g.setup(1, "Ayaqlı", false, Const.Species.HELIOZOAN)
	_check(g.species == Const.Species.HELIOZOAN, "ayaqlı növ quraşdırılır")

	var dt := 1.0 / 60.0
	var cap := Const.START_CAPACITY
	var r := Const.germ_radius(cap)
	var pos := Vector2(0.0, LANE_Y)

	# ---- 1. Dayanan mikrob addımlamır ----
	for i in 40:
		_gait_step(g, pos, cap, dt)
	var resting := g._foot.duplicate()
	for i in 40:
		_gait_step(g, pos, cap, dt)
	var drift := 0.0
	for i in g._legs:
		drift = maxf(drift, resting[i].distance_to(g._foot[i]))
	_check(drift < 0.5, "dayanan mikrob ayaqlarını tərpətmir (%.2f px sürüşmə)" % drift)

	# ---- 2 və 3. Yeriş ----
	var worst_reach := 0.0
	var worst_lifted := 0
	var stepped := {}
	for i in 300:
		pos += Vector2.RIGHT * Const.BASE_SPEED * dt
		_gait_step(g, pos, cap, dt)
		var lifted := 0
		for j in g._legs:
			worst_reach = maxf(worst_reach, pos.distance_to(g._foot[j]))
			if g._step[j] < 1.0:
				lifted += 1
				stepped[j] = true
		worst_lifted = maxi(worst_lifted, lifted)

	# Ayaq ən çox "normal uzaqlıq + bir addım" qədər uzana bilər.
	var limit := r * (GermVisual.LEG_REACH + GermVisual.LEG_STRIDE + 0.6)
	_check(worst_reach <= limit,
		"ayaqlar dartılıb qopmur (ən uzağı %.0f ≤ %.0f px)" % [worst_reach, limit])
	_check(worst_lifted * 2 < g._legs,
		"hər an ayaqların yarıdan çoxu yerdədir (ən pis hal: %d / %d havada)"
			% [worst_lifted, g._legs])
	_check(stepped.size() == g._legs,
		"bütün ayaqlar addımda iştirak edir (%d / %d)" % [stepped.size(), g._legs])

	g.free()


## Bir kadrlıq yeriş addımı. [method GermVisual._process] səhnə ağacı istəyir,
## ona görə testdə iki iş görən metodu birbaşa çağırırıq.
static func _gait_step(g: GermVisual, pos: Vector2, cap: int, dt: float) -> void:
	g.apply(pos, 0.0, 6, cap, false, true)
	g._track_motion(dt)
	g._walk(dt)


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
