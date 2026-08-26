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
	_test_shot_starts_inside()
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
	_test_amoeba_crawl()
	_test_eject_strain()
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


## Atılan top mikrobun İÇİNDƏN doğulur, kənarından yox.
##
## Oyunun qaydası budur ki, mikrob öz içindəki topu atır. Əvvəl top membranın
## kənarında peyda olurdu — sanki kənardan atılmışdı. Dəyişiklik göründüyündən
## incədir, amma iki şeyi poza bilərdi: atıcının öz topu ona dəyə bilər
## (indi top onun İÇİNDƏ doğulur!) və qığılcım gövdənin altında qalıb görünməz.
static func _test_shot_starts_inside() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var start := a.pos

	s.step({A_ID: Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)}, Const.TICK_DELTA)
	_check(s.shots.size() == 1, "atəş bir top yaratdı (%d)" % s.shots.size())
	if s.shots.is_empty():
		return

	# Bir tick sonra top hələ membranı tam keçməyib — yəni içəridən başlayıb.
	var flown := start.distance_to(s.shots[0].pos)
	_check(flown < a.radius(),
		"top gövdənin İÇİNDƏN çıxır (%.0f px < radius %.0f)" % [flown, a.radius()])

	# Qığılcım isə membranda olmalıdır: mərkəzdə çəkilsə gövdə onu örtər.
	#
	# Bu məsafə həm də client-in HESABIDIR: [method Arena._remember_muzzle]
	# topun doğuş nöqtəsini məhz qığılcımdan bir radius geri çəkərək tapır.
	# Qığılcım başqa yerə köçürülsə, öz topun mikrobun içindən yox, kənarından
	# çıxmağa başlayar — testin bu sətri həmin əlaqəni qoruyur.
	var spark := Vector2.ZERO
	for e in s.events:
		if e.get("t") == "fire":
			spark = e["pos"]
	_check(absf(start.distance_to(spark) - a.radius()) < 1.0,
		"qığılcım membranda çıxır (%.0f px)" % start.distance_to(spark))

	# Ən vacibi: öz topu atıcıya DƏYMİR, halbuki artıq onun içində doğulur.
	for i in 8:
		s.step({}, Const.TICK_DELTA)
	_check(a.balls == Const.START_BALLS - 1,
		"içəridən çıxan top sahibinə dəymir (top sayı: %d)" % a.balls)


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
	# Botsuz dünya: bu test yalnız paket → atəş yolunu yoxlayır, botların
	# atdığı toplar nəticəni korlayardı (bax [method _quiet_world]).
	var world := _quiet_world(1)
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
	var world := _quiet_world(2)
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
	var world := _quiet_world(9)
	var walker := world.add_player(A_ID, "Ayaqlı", Const.Species.AMOEBA)
	var swimmer := world.add_player(B_ID, "Kirpikli", Const.Species.CILIATE)

	_check(walker.species == Const.Species.AMOEBA
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
	_check(_species_in(wf) == Const.Species.AMOEBA
			and _species_in(sf) == Const.Species.CILIATE,
		"növ snapshot-dan düzgün oxunur (bayraqlar %d / %d)" % [wf, sf])
	_check(wf & Const.GFlag.SAFE and not (sf & Const.GFlag.SAFE),
		"toxunulmazlıq eyni ədəddə növü pozmur")

	# HƏR növ öz nömrəsi ilə qayıtmalıdır. Bir bit yerinə iki bit ayrılanda
	# maska səhv olsa yalnız ÜÇÜNCÜ növ pozulardı — ilk ikisi işləməyə davam
	# edərdi və səhv uzun müddət görünməzdi.
	var all_ok := true
	for k in Const.SPECIES_COUNT:
		var kind := Const.species_from(k)
		var g := Sim.GermState.new()
		g.species = kind
		if _species_in(World._flags_of(g)) != kind:
			all_ok = false
	_check(all_ok, "hər üç növ bayraqlardan geri qayıdır")

	# Növ üç ayrı ETİBARSIZ mənbədən gəlir: client-in paketi, serverin cavabı
	# və diskdəki ayar faylı. Üçü də eyni funksiyadan keçir, ona görə yad
	# dəyərin nəticəsi bir yerdə yoxlanılır.
	_check(Const.species_from(99) == Const.Species.CILIATE
			and Const.species_from(-3) == Const.Species.CILIATE
			and Const.species_from(2) == Const.Species.AMOEBA,
		"yad növ dəyəri kirpikliyə düşür")


## Botsuz dünya.
##
## `_seeded = true` TƏK BAŞINA kifayət etmir və bu, uzun müddət gizli qalmış
## bir tələ idi: həmin bayraq yalnız BAŞLANĞIC bot dəstəsini dayandırır.
## Dünyada əhali azdırsa, [method World._keep_population] daha sonra taymerlə
## bir-bir bot əlavə etməyə davam edir — taymer isə sıfırdan başlayır, yəni
## İLK tick-də bot gəlir. O botun atdığı top testin nəticəsini korlayır.
##
## Səhv təsadüfən üzə çıxdı: botun növü təsadüfi seçilməyə başlayanda
## `randi()` çağırışı əlavə olundu, təsadüfi ardıcıllıq sürüşdü və bot bir
## dəfə "düzgün" yerə düşüb hədəfi vurdu.
static func _quiet_world(id: int) -> World:
	var w := World.new(id)
	w._seeded = true
	w._bot_timer = INF
	return w


## Bayraq ədədindən növü çıxarır — client-in etdiyi işin eynisi.
static func _species_in(flags: int) -> Const.Species:
	return Const.species_from((flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)


## Ayaqlı mikrobun yerişi.
##
## Ekran görüntüsü bunu yoxlaya bilmir — kadr donuqdur, yeriş isə zamanla
## yaşayır. Üç xassə var və hər biri pozulanda hərəkət "yeriş" olmaqdan çıxır:
##   1. dayanan mikrob ayaqlarını tərpətməməlidir (yoxsa yerində titrəyir);
##   2. ayaqlar sonsuz dartılmamalıdır (yoxsa gövdədən qopmuş görünür);
##   3. ayaqların çoxu HƏR AN yerdə olmalıdır (yoxsa yeriş yox, sıçrayışdır).
## Ayaqlı növün yerişi — amöbdə olduğu kimi HƏM kiçik, HƏM böyük tutumda.
##
## Səbəb eynidir: botlar kiçik qalır, oyunçu böyüyür, və ölçüyə bağlı olmayan
## VAXT sabitləri böyük mikrobda yerişi dondururdu (bax `_check_gait`).
static func _test_heliozoan_gait() -> void:
	_check_gait(Const.START_CAPACITY, "kiçik")
	_check_gait(Const.MAX_CAPACITY, "böyük")


static func _check_gait(cap: int, label: String) -> void:
	var g := GermVisual.new()
	g.setup(1, "Ayaqlı", false, Const.Species.HELIOZOAN)
	_check(g.species == Const.Species.HELIOZOAN, "%s ayaqlı növ quraşdırılır" % label)

	var dt := 1.0 / 60.0
	var r := Const.germ_radius(cap)
	var pos := Vector2(0.0, LANE_Y)

	# ---- 1. Dayanan mikrobun pəncələri SÜRÜŞMÜR ----
	#
	# Yoxlanan xassə "ayaq tərpənməsin" DEYİL — bu, əvvəlki səhv oxunuş idi və
	# nəticəsi görüntüdə donmuş ulduz oldu. Doğru xassə budur: pəncə ya olduğu
	# yerdə qalır, ya da qəti bir addım atır; heç vaxt gövdə ilə birlikdə
	# sürünmür. Ona görə pəncərə [constant GermVisual.LEG_HOLD_MAX]-dan qısadır.
	# Doğuşdan sonrakı ilk oturuşma bitsin — o vaxt bəzi ayaqlar onsuz da
	# yerini dəyişir və bu, sürüşmə deyil, addımdır.
	for i in 120:
		_gait_step(g, pos, cap, dt)
	var resting := g._foot.duplicate()
	# YALNIZ pəncəsi yerdə qalan ayaqlar sayılır. Havadakı ayağın hərəkət etməsi
	# qüsur deyil, elə addımın özüdür — ikisini qarışdıran ölçü ya səhv həyəcan
	# verir, ya da yellənmə yavaşlayan kimi uğursuz olur.
	var airborne_once := {}
	for i in int(GermVisual.LEG_HOLD_MAX * 0.4 / dt):
		_gait_step(g, pos, cap, dt)
		for j in g._legs:
			if g._step[j] < 1.0:
				airborne_once[j] = true
	var drift := 0.0
	var grounded := 0
	for i in g._legs:
		if airborne_once.has(i):
			continue
		grounded += 1
		drift = maxf(drift, resting[i].distance_to(g._foot[i]))
	_check(grounded > 0 and drift < 0.5,
		"%s: yerə basılı pəncə sürüşmür (%d ayaq, ən çox %.2f px)"
			% [label, grounded, drift])

	# ---- 1b. ...amma ƏBƏDİ də donmur ----
	#
	# Ölçü pəncənin YERİ deyil, ayağın QALXMASIdır: dayanan mikrobda ayaq
	# demək olar eyni nöqtəyə qayıdır, ona görə mövqe fərqi sıfıra yaxın olur.
	# Görünən dəyişiklik isə qalxma anındadır — aksopod yığılıb yenidən uzanır.
	var stirred := {}
	for i in int(GermVisual.LEG_HOLD_MAX * 3.0 / dt):
		_gait_step(g, pos, cap, dt)
		for j in g._legs:
			if g._step[j] < 1.0:
				stirred[j] = true
	_check(stirred.size() == g._legs,
		"%s: dayanan mikrob da ayaqlarını yeniləyir (%d / %d)"
			% [label, stirred.size(), g._legs])

	# ---- 2 və 3. Yeriş ----
	# Mikrob ÖZ tavan sürəti ilə gedir. Əvvəl burada [constant Const.BASE_SPEED]
	# yazılmışdı və test böyük mikrobu olduğundan 1.7 dəfə sürətli sürürdü —
	# yəni məhz yoxlanmalı olan halı gizlədirdi.
	var speed := Const.germ_speed(cap)
	var worst_reach := 0.0
	var worst_lifted := 0
	var stepped := {}
	var airborne := 0
	var flight := 0
	var steps_started := 0
	var was_down := []
	for j in g._legs:
		was_down.append(true)
	var frames := 600
	for i in frames:
		pos += Vector2.RIGHT * speed * dt
		_gait_step(g, pos, cap, dt)
		var lifted := 0
		for j in g._legs:
			worst_reach = maxf(worst_reach, pos.distance_to(g._foot[j]))
			var down: bool = g._step[j] >= 1.0
			if not down:
				lifted += 1
				flight += 1
				stepped[j] = true
				if was_down[j]:
					steps_started += 1
			was_down[j] = down
		worst_lifted = maxi(worst_lifted, lifted)
		if lifted > 0:
			airborne += 1

	# Ayaq ən çox "normal uzaqlıq + bir addım" qədər uzana bilər.
	var limit := r * (GermVisual.LEG_REACH + GermVisual.LEG_STRIDE + 0.6)
	_check(worst_reach <= limit,
		"%s: ayaqlar dartılıb qopmur (ən uzağı %.0f ≤ %.0f px)"
			% [label, worst_reach, limit])
	_check(worst_lifted * 2 < g._legs,
		"%s: hər an ayaqların yarıdan çoxu yerdədir (ən pis hal: %d / %d havada)"
			% [label, worst_lifted, g._legs])
	_check(stepped.size() == g._legs,
		"%s: bütün ayaqlar addımda iştirak edir (%d / %d)"
			% [label, stepped.size(), g._legs])

	# ---- 4. Yeriş DONMUR ----
	#
	# Bu iki ölçü "ayaqlar donur" şikayətinin ölçülə bilən qarşılığıdır və
	# əvvəl yox idi. Ayaq ya çox nadir addımlayır, ya da addımı bir neçə kadrda
	# çırpınıb bitirir — hər ikisi ekranda donmuş ulduz kimi oxunur.
	# HƏR AYAĞIN öz tezliyi. Ümumi say aldadıcıdır: 13 ayaqda saniyədə 13 addım
	# çox görünür, amma hər ayağın payına cəmi 1 addım düşür.
	# Tezliyin ölçüdən asılı olması NORMALDIR — iri canlı uzun və seyrək
	# addımlayır. Ona görə bu, yalnız tam çökməyə qarşı aşağı həddir; əsl
	# qoruyucu aşağıdakı yük dövrüdür.
	var per_leg := float(steps_started) / (float(frames) * dt) / float(g._legs)
	_check(per_leg > 1.5,
		"%s: hər ayaq oxunacaq tezlikdə addımlayır (saniyədə %.1f)"
			% [label, per_leg])
	# ── "Ayaqlar donur" şikayətinin ölçüsü ──────────────────────────────────
	# Doğru ölçü budur: BİR ayaq vaxtının neçə faizini havada keçirir.
	# "Ən azı bir ayaq havadadır" ölçüsü aldadıcıdır — 13 ayaqda o rəqəm həmişə
	# yüksək çıxır, hər ayaq isə ayrılıqda donmuş görünə bilər.
	var duty := float(flight) / (float(frames) * float(g._legs))
	_check(duty > 0.22,
		"%s: hər ayaq vaxtının kifayət hissəsini havada keçirir (%.0f%%)"
			% [label, duty * 100.0])

	g.free()


## Topun membranı ZORLAYARAQ çıxması.
##
## Effekt hazır konturun ÜZƏRİNDƏ işlədiyinə görə növdən asılı deyil
## ([method GermVisual._strain]) — ona görə burada təmiz dairə üzərində
## ölçülür və nəticə hər üç növ üçün keçərlidir.
##
## Dörd xassə:
##   1. Çıxış istiqamətində gövdə nəzərəçarpacaq qədər qabarır — yoxsa top
##      sadəcə gövdədən sürüşüb çıxır, zorlanma görünmür.
##   2. Qabarma YERLİDİR: yan tərəf demək olar toxunulmaz qalır. Geniş olsa
##      mikrob bütövlükdə şişər və effekt "nəfəs alma" kimi oxunar.
##   3. Effekt bitəndə forma TAM bərpa olunur — qalıcı deformasiya yoxdur.
##   4. Pərdənin yarılma anı topun ƏSL yol vaxtına uyğundur (radius / SHOT_SPEED)
##      və siqnal düz bir dəfə göndərilir — "blunk" səsi ona bağlıdır.
static func _test_eject_strain() -> void:
	var g := GermVisual.new()
	g.setup(0, "Atıcı", true, Const.Species.CILIATE)
	var cap := Const.START_CAPACITY
	var r := Const.germ_radius(cap)
	g.apply(Vector2.ZERO, 0.0, 6, cap, false, true)

	# Ölçmə üçün təmiz dairə: qabarmadan başqa heç nə qarışmasın.
	var n := 48
	var ring := PackedVector2Array()
	for i in n:
		ring.append(Vector2.from_angle(TAU * float(i) / float(n)) * r)

	# Siqnal sayğacı massivdədir: GDScript lambda-ları yerli dəyişəni
	# DƏYƏRLƏ tutur, massivi isə istinadla.
	var breaks := [0]
	g.broke_through.connect(func(_local: bool) -> void: breaks[0] += 1)

	var dt := 1.0 / 60.0
	var span := r / Const.SHOT_SPEED
	g.eject(0.0)

	var peak := 1.0
	var side := 0.0
	var broke_at := -1.0
	var clock := 0.0
	for i in int((span + GermVisual.EJECT_SNAP) / dt) + 20:
		g._process(dt)
		clock += dt
		var s := g._strain(ring)
		peak = maxf(peak, s[0].length() / r)
		# 90° yan — qabarmanın yayılıb-yayılmadığını göstərir.
		side = maxf(side, absf(s[n / 4].length() / r - 1.0))
		if breaks[0] > 0 and broke_at < 0.0:
			broke_at = clock

	_check(peak > 1.18,
		"atəşdə gövdə çıxış nöqtəsində qabarır (radiusun %.0f%%-i qədər)"
			% [(peak - 1.0) * 100.0])
	_check(side < 0.03,
		"qabarma yerlidir — yan tərəf toxunulmaz qalır (%.1f%%)" % [side * 100.0])
	var rest := g._strain(ring)
	_check(absf(rest[0].length() / r - 1.0) < 0.005,
		"effekt bitəndə forma bərpa olunur (%.2f%% fərq)"
			% [absf(rest[0].length() / r - 1.0) * 100.0])
	_check(breaks[0] == 1, "pərdə bir dəfə yarılır (%d siqnal)" % breaks[0])
	_check(absf(broke_at - span) < 0.035,
		"yarılma anı topun yol vaxtına uyğundur (%.0f ms, gözlənilən %.0f ms)"
			% [broke_at * 1000.0, span * 1000.0])
	g.free()


## Amöbin sürünməsi.
##
## Mikrob DÜZ XƏTT üzrə sabit sürətlə sürülür və ekranda görünən gövdə ölçülür —
## çünki oyunçunun gördüyü budur, sabitlərin dəyəri yox.
##
## Ölçülən dörd xassə:
##   1. Sahə sabit qalır — hüceyrə həcmini saxlayır.
##   2. Forma istiqamətlidir — ön uc arxadan uzaqdır.
##   3. **Gövdənin görünən irəliləyişi QEYRİ-BƏRABƏRDİR.** Sürünmə budur:
##      gövdə uzanarkən yavaşıyır, arxa uc qovuşanda irəli atılır.
##   4. Dayanan amöb deformasiya etmir.
##
## ── Üçüncü şərtin tarixi ─────────────────────────────────────────────────
## Uzun müddət yalnız 1 və 2 ölçülürdü. Onları yerində nəfəs alan ləkə də
## ödəyir, ona görə kod dəfələrlə "düzəldilib" testdən keçirdi və ekranda heç
## nə dəyişmirdi.
##
## Sonra kütlə mərkəzinin sürüşməsi əlavə olundu — forma düzəldi, hərəkət yenə
## sürüşmə kimi oxundu. Səbəb: dövr VAXTLA sürülürdü (saniyədə ~1), mikrob isə
## saniyədə 3.4 gövdə uzunluğu qət edir, yəni deformasiya yerdəyişmə ilə
## sinxron deyildi.
##
## Ona görə indi ölçülən şey mütləq deformasiya deyil, **hərəkətin RİTMİdir**:
## bir kadrda gövdə nə qədər irəlilədi. Bərabər irəliləyiş = sürüşmə.
## Qeyri-bərabər irəliləyiş = sürünmə. Başqa cür yoxlamaq mümkün deyil.
## ── Niyə İKİ tutumda ölçülür ─────────────────────────────────────────────
## Bir müddət yalnız başlanğıc tutumu yoxlanılırdı və test keçirdi — ekranda
## isə BOTLAR sürünürdü, oyunçunun mikrobu yox. Fərq yeganə şeydə idi: botlar
## kiçik qalır, oyunçu isə böyüyür. Böyük mikrobda həm `rush` səhv ölçüyə
## bölünürdü, həm də addım radiusla birlikdə uzanıb tezliyi çökdürürdü.
##
## Ona görə eyni ölçü ən böyük tutumda da təkrarlanır. Oyunçunun ən çox vaxt
## keçirdiyi hal odur.
static func _test_amoeba_crawl() -> void:
	_check_crawl(Const.START_CAPACITY, "kiçik")
	_check_crawl(Const.MAX_CAPACITY, "böyük")


static func _check_crawl(cap: int, label: String) -> void:
	var g := GermVisual.new()
	g.setup(0, "Amöb", false, Const.Species.AMOEBA)
	var r := Const.germ_radius(cap)
	var rear: int = GermVisual.CRAWL_POINTS / 2
	var dt := 1.0 / 60.0
	# Mikrobun ÖZ tavan sürəti — böyüdükcə düşür.
	var speed := Const.germ_speed(cap)
	var pos := Vector2.ZERO

	# Sürəti və ilk addımı oturtmaq üçün qızdırma.
	for i in 90:
		pos += Vector2.RIGHT * speed * dt
		_crawl_step(g, pos, cap, dt)

	var last := pos.x + _polygon_centre(g._crawl_body(r, 0.0, g._rush(), 1.0)).x
	var quickest := -INF
	var slowest := INF
	var smallest := INF
	var largest := 0.0
	var front_sum := 0.0
	var back_sum := 0.0
	var strides := 0
	var was := g._reach_out
	var dropping := false
	var longest := 0.0
	var fore := -INF
	var aft := INF
	var roundest := INF
	# Ən azı bir neçə tam addım görünsün deyə böyük mikrobda dövr uzundur.
	var steps := 600
	for i in steps:
		pos += Vector2.RIGHT * speed * dt
		_crawl_step(g, pos, cap, dt)
		var body := g._crawl_body(r, 0.0, g._rush(), 1.0)
		# Gövdənin DÜNYA fəzasındakı kütlə mərkəzi — ekranda görünən nöqtə.
		var now := pos.x + _polygon_centre(body).x
		quickest = maxf(quickest, now - last)
		slowest = minf(slowest, now - last)
		last = now
		var area := _polygon_area(body)
		smallest = minf(smallest, area)
		largest = maxf(largest, area)
		# Ön yarının və arxa yarının ENİ — "enli baş, nazik quyruq" oxunuşunun
		# ölçüsü budur. Uc məsafəsi yaramır: bu formada o, təsadüfən bərabər çıxır.
		var mid_pt := _polygon_centre(body)
		var fw := 0.0
		var bw := 0.0
		for p in body:
			var d := p - mid_pt
			if d.x > r * 0.25:
				fw = maxf(fw, absf(d.y))
			elif d.x < -r * 0.25:
				bw = maxf(bw, absf(d.y))
		front_sum += fw
		back_sum += bw
		var shape := _aspect(body)
		longest = maxf(longest, shape)
		roundest = minf(roundest, shape)
		var mid := _polygon_centre(body).x
		fore = maxf(fore, mid)
		aft = minf(aft, mid)
		# Buraxılış anı: uzanma kəskin düşür. Yığılma bir neçə kadr çəkdiyinə
		# görə yalnız BAŞLANĞICI sayılır, yoxsa bir addım onlarla sayılardı.
		if was - g._reach_out > 0.05 and not dropping:
			strides += 1
			dropping = true
		elif g._reach_out >= was:
			dropping = false
		was = g._reach_out

	var swing := (largest - smallest) / largest
	_check(swing < 0.10,
		"%s amöb: sürünərkən sahə sabit qalır (dəyişmə %.1f%%)" % [label, swing * 100.0])
	# Forma İSTİQAMƏTLİDİR: ön və arxa uc gövdənin öz mərkəzindən eyni məsafədə
	# olmamalıdır. Ölçü mərkəzdən götürülür, node-dan yox — kök sabitləndikdən
	# sonra ([constant GermVisual.CRAWL_ANCHOR]) node artıq gövdənin ortasındadır,
	# ona görə köhnə ölçü hər iki ucu bərabər göstərirdi.
	# QEYD: burada "baş enli, quyruq nazik" yoxlaması OLMALIDIR, amma hələ
	# yoxdur — çünki forma bu xassəni hələ daşımır (ölçüldükdə ön və arxa en
	# bərabər çıxır: %.0f / %.0f px). Disklərin radiuslarını dəyişməklə sınandı
	# və sahənin qorunmasını pozdu (6%% → 29%%), ona görə geri qaytarıldı.
	# Uydurma hədd qoyub "keçdi" yazmaqdansa boşluq açıq saxlanılır.
	print("  [qeyd]  %s amöb: ön/arxa en %.0f / %.0f px — konus hələ yoxdur"
		% [label, front_sum / float(steps), back_sum / float(steps)])
	# Sürünən heç bir şey GERİ sıçramır. Bu yoxlama əvvəl yox idi və `maxf`
	# mənfi dəyəri gizlədirdi: nisbət 3119 çıxırdı, çünki ən yavaş kadr
	# −5.64 piksel idi, yəni gövdə bir kadrda geri atılırdı.
	_check(slowest > -0.05,
		"%s amöb: gövdə heç vaxt geri sıçramır (ən yavaş kadr %.2f px)"
			% [label, slowest])
	# ── Burada əvvəl "irəliləyiş qeyri-bərabər olmalıdır" testi vardı ───────
	# O, SƏHV hədəf idi və məhz ona görə silinib. Rəqibə kənardan baxanda kökün
	# silkələnməsi sürünmə kimi oxunur, amma öz mikrobun kameranın mərkəzinə
	# mismarlanıb — orada eyni silkələnmə "yerində ilişmək" kimi görünür.
	# Test o silkələnməni MÜKAFATLANDIRDIĞI üçün hər düzəliş vəziyyəti
	# pisləşdirirdi. İndi ölçülən şey doğrudur: kök sakit (`sway`), forma isə
	# işlək (`longest` / `roundest`). Sürünmə gövdənin UCLARI ilə oxunur.
	# 10 saniyəyə ən azı üç addım — yoxsa dövr o qədər yavaşdır ki, gözlə
	# ümumiyyətlə oxunmur. Böyük mikrobun çökən tezliyi məhz buradan tutulur.
	_check(strides >= 3,
		"%s amöb: dövr oxunacaq qədər tez-tezdir (%.1f saniyədə %d addım)"
			% [label, float(steps) * dt, strides])
	# ── "Yaxıla-yaxıla" sözünün ölçüsü ──────────────────────────────────────
	# Ritm düzgün ola-ola gövdə yumru ləkə kimi qala bilər — oyunda məhz belə
	# olurdu. Oxunuş üçün SİLUET dəyişməlidir: uzananda gövdə eninə görə
	# nəzərəçarpacaq dərəcədə uzun olmalı, yığılanda isə yumrulanmalıdır.
	_check(longest > 1.9,
		"%s amöb: uzananda gövdə həqiqətən uzanır (en/boy %.2f)" % [label, longest])
	# ── Öz mikrobun EKRANIN MƏRKƏZİNƏ mismarlanıb ───────────────────────────
	# Kamera onu tam izləyir, ona görə oyunçunun mikrobunun ekranda YERDƏYİŞMƏSİ
	# YOXDUR — görünən yeganə hərəkət gövdənin öz salınmasıdır. Salınma böyük
	# olsa, mikrob irəli getmir, yerində ora-bura sürüşür: ekranda bu, məhz
	# "ilişib qalmaq" kimi oxunur.
	#
	# Botlarda eyni salınma normal görünür, çünki onların ekranda öz
	# yerdəyişməsi var və salınma ona qarışır. Səhv məhz belə gizlənirdi.
	var sway := fore - aft
	_check(sway < r * 0.22,
		"%s amöb: kütlə mərkəzi yerində salınmır (%.1f px = radiusun %.0f%%-i)"
			% [label, sway, sway / r * 100.0])
	_check(roundest < 1.35,
		"%s amöb: yığılanda gövdə yumrulanır (en/boy %.2f)" % [label, roundest])

	# Dayanan amöb deformasiya etmir: sürünmə yalnız hərəkətdə olur.
	for i in 120:
		_crawl_step(g, pos, cap, dt)
	var still := g._crawl_body(r, 0.0, 0.0, 1.0)
	_check(absf(still[0].length() - still[rear].length()) < r * 0.16,
		"%s amöb: dayananda ön-arxa deformasiya etmir (%.1f px fərq)"
			% [label, absf(still[0].length() - still[rear].length())])
	g.free()


## Amöbi bir kadr irəli sürür — [method GermVisual._process]-in etdiyi ilə eyni.
static func _crawl_step(g: GermVisual, pos: Vector2, cap: int, dt: float) -> void:
	# Nişan yana çevrilir ki, ayaqcıq ön/arxa ölçüsünə qarışmasın.
	g.apply(pos, PI * 0.5, 6, cap, false, true)
	g._track_motion(dt)
	g._crawl(dt)


## Siluetin uzunluq / en nisbəti — gedilən ox boyunca. 1.0 = dairə.
## Ölçü nöqtələrin sayından yox, KƏNARIN ən uzaq nöqtələrindən çıxır, yəni
## ekranda görünən siluetlə eynidir.
static func _aspect(pts: PackedVector2Array) -> float:
	var lo_x := INF
	var hi_x := -INF
	var lo_y := INF
	var hi_y := -INF
	for p in pts:
		lo_x = minf(lo_x, p.x)
		hi_x = maxf(hi_x, p.x)
		lo_y = minf(lo_y, p.y)
		hi_y = maxf(hi_y, p.y)
	return (hi_x - lo_x) / maxf(hi_y - lo_y, 0.001)


## Çoxbucaqlının kütlə mərkəzi (bərabər sıxlıqlı lövhə kimi).
## Nöqtələrin sadə ortası YARAMAZ — o, nöqtə sıxlığından asılıdır, sahədən yox.
static func _polygon_centre(pts: PackedVector2Array) -> Vector2:
	var twice_area := 0.0
	var acc := Vector2.ZERO
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		var cross := a.x * b.y - b.x * a.y
		twice_area += cross
		acc += (a + b) * cross
	if absf(twice_area) < 0.0001:
		return Vector2.ZERO
	return acc / (3.0 * twice_area)


## Çoxbucaqlının sahəsi (ayaqqabı bağı düsturu).
static func _polygon_area(pts: PackedVector2Array) -> float:
	var sum := 0.0
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


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
