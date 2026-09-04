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
	_test_endless_untouched()
	_test_match_phases()
	_test_dish_shrinks_by_clock()
	_test_dry_zone_fills()
	_test_dry_zone_not_predicted()
	_test_bot_flees_dry_zone()
	_test_full_solo_match()
	_test_ordinals()
	_test_solo_ends_and_ranks()
	_test_aoi_covers_screen()
	_test_team_bits_roundtrip()
	_test_duo_teams()
	_test_duo_revive()
	_test_super_survives_packet_pileup()
	_test_spawn_inside_wet_zone()
	_test_trio_rounds()
	_test_ranking_matches_board()
	_test_super_consumed_once()
	_test_world_frozen_after_over()
	_test_roster_tracks_ids()
	_test_places_unique()
	_test_snapshot_worst_case()
	_test_snapshot_fits_mtu()
	_test_timeout_survivors()
	_test_spore()
	_test_wall_damage_bits()
	_test_bots_use_supers()
	_test_every_species_uses_super()
	_test_super_flag_carries_duration()
	_test_species_share_combat_math()
	_test_species_movement()
	_test_amoeba_squeezes()
	_test_super_charge()
	_test_super_no_damage()
	_test_trichocyst()
	_test_cyst_bounces()
	_test_net_pulls_food()
	_test_shot_injects()
	_test_overfill_bursts()
	_test_starvation_bursts()
	_test_fire_floor()
	_test_no_self_hit()
	_test_shot_starts_inside()
	_test_obstacle_blocks_shot()
	_test_map_layouts()
	_test_arena_core_is_free()
	_test_bush_hides()
	_test_brittle_breaks()
	_test_vent_pushes()
	_test_blob_textures()
	_test_germ_flash()
	_test_germ_freeze()
	_test_shot_trails()
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
	_test_world_bush_filter()
	_test_wall_sync()
	_test_world_keeps_population()
	_test_address_parsing()
	_test_fire_button()
	_test_germ_species()
	_test_heliozoan_gait()
	_test_amoeba_crawl()
	_test_eject_strain()
	print("===== %d keçdi, %d uğursuz =====\n" % [_pass, _fail])
	return _fail






## Hər maneə MÖVCUD sprite alır — və eyni maneə həmişə eynisini alır.
##
## Səhv olsaydı oyun XƏTA VERMİRDİ: `_tex[name]` yoxdursa Sprite2D teksturasız
## qalır, yəni maneə sadəcə GÖRÜNMÜR. Oyunçu isə görünməyən divara dəyir.
static func _test_blob_textures() -> void:
	var keep := DishMap.layout
	for which in 3:
		DishMap.layout = which
		var bad := 0
		var unstable := 0
		for o in DishMap.obstacles():
			var name := Arena._blob_texture(o)
			if not Arena.BLOB_ORDER.has(name):
				bad += 1
			# Seçim MÖVQEDƏN çıxır: iki çağırış eyni cavabı verməlidir,
			# yoxsa xəritə hər açılışda başqa cür görünər.
			if Arena._blob_texture(o) != name:
				unstable += 1
		_check(bad == 0, "%s: hər maneənin sprite-ı var (%d naməlum)"
			% [DishMap.layout_name(which), bad])
		_check(unstable == 0, "%s: sprite seçimi sabitdir" % DishMap.layout_name(which))
	DishMap.layout = keep

	# Keçilə bilən növlərin sprite-ı BƏRK növlərinkindən fərqli olmalıdır:
	# forma dili qaydanı deyir (bax ART_BIBLE §4).
	var solid := Arena._blob_texture(Vector4(0, 0, 100, DishMap.Kind.MUCUS))
	var bush := Arena._blob_texture(Vector4(0, 0, 100, DishMap.Kind.BUSH))
	var vent := Arena._blob_texture(Vector4(0, 0, 100, DishMap.Kind.VENT))
	var brittle := Arena._blob_texture(Vector4(0, 0, 100, DishMap.Kind.BRITTLE))
	_check(bush != solid and vent != solid and brittle != solid
			and bush != vent and bush != brittle and vent != brittle,
		"dörd növün dördü də ayrı sprite ilə çəkilir")


## Zərbə parıltısı: yanır, sönür, və TƏKRAR zərbədə uzanmır.
static func _test_germ_flash() -> void:
	var g := GermVisual.new()
	g.setup(0, "A", false, Const.Species.CILIATE)
	_check(g._flash == 0.0, "yeni mikrob parıldamır")

	g.flash()
	_check(g._flash == GermVisual.FLASH_TIME, "zərbə parıltını yandırır")

	g._process(GermVisual.FLASH_TIME * 0.5)
	_check(g._flash > 0.0 and g._flash < GermVisual.FLASH_TIME,
		"parıltı sönməyə başlayır (%.3f s qalıb)" % g._flash)

	# Ardıcıl zərbədə vaxt SIFIRLANIR, üstünə gəlmir: yığılsaydı sıx atəş
	# altında mikrob daimi ağ ləkəyə dönər və rəngi — kimliyi — itərdi.
	g.flash()
	g.flash()
	_check(g._flash == GermVisual.FLASH_TIME, "təkrar zərbə parıltını uzatmır")

	g._process(GermVisual.FLASH_TIME + 0.01)
	_check(g._flash == 0.0, "parıltı tam sönür")
	# `setup` Label yaradır; ağacda olmayan node özü silinmir və Godot çıxışda
	# sızma xəbərdarlığı yazır. Xəbərdarlıq real xətaları gizlədə bilər.
	g.free()


## Donmuş kadr: animasiya dayanır, amma vəziyyət pozulmur.
##
## Donma YALNIZ görüntüyə toxunmalıdır — simulyasiya davam edir (bax
## [member Arena.FREEZE_TIME]). Burada yoxlanılan budur ki, donmuş mikrobun
## öz saatı dayanır və oyananda kaldığı yerdən davam edir.
static func _test_germ_freeze() -> void:
	var g := GermVisual.new()
	g.setup(0, "A", false, Const.Species.AMOEBA)
	g.apply(Vector2.ZERO, 0.0, 6, Const.START_CAPACITY, false, true)
	for i in 10:
		g._process(1.0 / 60.0)
	var t_before := g._t
	var crawl_before := g._crawl_t

	g.frozen = true
	for i in 30:
		g._process(1.0 / 60.0)
	_check(is_equal_approx(g._t, t_before), "donmuş mikrobun saatı dayanır")
	_check(is_equal_approx(g._crawl_t, crawl_before),
		"donmuş amöbin sürünmə dövrü dayanır")

	g.frozen = false
	g._process(1.0 / 60.0)
	_check(g._t > t_before, "donma bitəndə mikrob oyanır")
	g.free()


## Topun izi: uzunluğu məhduddur, ölən top izini aparır.
static func _test_shot_trails() -> void:
	var tr := ShotTrails.new()
	for i in ShotTrails.SPAN * 3:
		tr.push(1, Vector2(float(i) * 20.0, 0.0), Color.RED)
	var pts: PackedVector2Array = tr._tracks[1]["pts"]
	_check(pts.size() == ShotTrails.SPAN,
		"iz ən çoxu %d nöqtə saxlayır (%d)" % [ShotTrails.SPAN, pts.size()])
	# Ən son nöqtə ƏN TƏZƏ olmalıdır: sıra pozulsa iz topun qabağına düşərdi.
	_check(pts[pts.size() - 1].x > pts[0].x, "izin sonu topun indiki yeridir")

	# Yerində duran top iz uzatmır: sıfır uzunluqlu seqment `draw_multiline`-da
	# nöqtə kimi görünüb izin ucunda ləkə qoyurdu.
	var was := pts.size()
	tr.push(1, pts[pts.size() - 1], Color.RED)
	_check((tr._tracks[1]["pts"] as PackedVector2Array).size() == was,
		"tərpənməyən top izə nöqtə əlavə etmir")

	tr.push(2, Vector2.ZERO, Color.BLUE)
	_check(tr._tracks.size() == 2, "hər topun öz izi var")
	tr.drop(1)
	_check(not tr._tracks.has(1) and tr._tracks.has(2),
		"ölən topun izi silinir, qonşununku qalır")
	tr.free()


## Xəritə düzümünün pozula bilməyən qaydaları — ÜÇ düzümün hamısı üçün.
##
## Ən vacibi birincisidir: İKİ KOL ÜST-ÜSTƏ DÜŞMƏMƏLİDİR.
## [method Sim.bush_of] tapdığı İLK kolun indeksini qaytarır, görünmə isə
## indekslərin bərabərliyi ilə qərar verilir ([method World._near_germs]).
## İki kol örtüşsəydi, örtüşən sahədə duran iki oyunçu fərqli indeksə düşüb
## bir-birini GÖRMƏZDİ — yan-yana durub bir-birindən gizli. Bu, oyunçunun
## heç cür izah edə bilməyəcəyi haldır.
static func _test_map_layouts() -> void:
	var keep := DishMap.layout
	for which in 3:
		DishMap.layout = which
		var list := DishMap.obstacles()
		var label := DishMap.layout_name(which)

		# INF-dən başlayır, sıfırdan yox: sıfırdan başlasaydı örtüşmə olmayanda
		# da "0 px" yazardı və rəqəm heç nə demədən keçərdi.
		var worst := INF
		for i in list.size():
			if int(list[i].w) != DishMap.Kind.BUSH:
				continue
			for j in range(i + 1, list.size()):
				if int(list[j].w) != DishMap.Kind.BUSH:
					continue
				var gap := Vector2(list[i].x, list[i].y).distance_to(
					Vector2(list[j].x, list[j].y)) - list[i].z - list[j].z
				worst = minf(worst, gap)
		_check(worst >= 0.0 or is_inf(worst),
			"%s: kollar üst-üstə düşmür (ən pis boşluq %.0f px)" % [label, worst])

		# Hər maneə tam qabın içində olmalıdır: yarısı bayırda qalan maneə
		# oyunçunu görünməyən divara sıxışdırır.
		var outside := 0
		for o in list:
			if Vector2(o.x, o.y).length() + o.z > Const.WORLD_RADIUS:
				outside += 1
		_check(outside == 0, "%s: hər maneə qabın içindədir (%d kənarda)"
			% [label, outside])

		# Cərəyan deşiyi BƏRK maneənin içində qala bilməz — ora çatmaq
		# mümkün olmazdı, yəni deşik oyunda mövcud olmazdı.
		var buried := 0
		for i in list.size():
			if int(list[i].w) != DishMap.Kind.VENT:
				continue
			for j in list.size():
				if i == j or not DishMap.blocks_germ(int(list[j].w)):
					continue
				var d := Vector2(list[i].x, list[i].y).distance_to(
					Vector2(list[j].x, list[j].y))
				if d < list[j].z:
					buried += 1
					break
		_check(buried == 0, "%s: cərəyan deşikləri əlçatandır (%d basdırılıb)"
			% [label, buried])
	DishMap.layout = keep


## Qabın MƏRKƏZİ bloklayan maneədən azaddır — quruyan rejimlərin son arenası.
##
## Ən bahalı səhvlərdən biri məhz burada gizlənmişdi: hər düzümün mərkəzində
## iri SELİK ləkəsi vardı (120–150 px), TƏK QALAN və CÜT-ün son yaş radiusu isə
## 90 px-dir. Yəni matçın son mərhələsində oyun sahəsinin İÇİ bütövlükdə bərk
## maneə olurdu və sağ qalanlar döyüşmək əvəzinə quru zonaya sıxılıb dolurdu.
##
## Test hər ÜÇ düzümü yoxlayır, təkcə işlədiləni yox: düzüm dəyişəndə səhv
## səssizcə geri qayıtmamalıdır.
static func _test_arena_core_is_free() -> void:
	var keep := DishMap.layout
	for which in 3:
		DishMap.layout = which
		var label := DishMap.layout_name(which)
		var worst := INF
		var guilty := ""
		for o in DishMap.obstacles():
			if not DishMap.blocks_germ(int(o.w)):
				continue
			# Maneənin kənarı ilə mərkəzi dairənin kənarı arasındakı boşluq.
			var gap := Vector2(o.x, o.y).length() - o.z - DishMap.CORE_CLEAR
			if gap < worst:
				worst = gap
				guilty = DishMap.kind_name(int(o.w))
		_check(worst >= 0.0,
			"%s: mərkəzi %.0f px bloklayan maneədən azaddır (ən yaxın %s, boşluq %.0f px)"
				% [label, DishMap.CORE_CLEAR, guilty, worst])
	DishMap.layout = keep

	# Son yaş radius mərkəzi azad sahədən BÖYÜK ola bilməz, yoxsa qayda
	# yuxarıdakı testdə deyil, oyunun içində pozulur.
	_check(Const.SOLO_MIN_RADIUS <= DishMap.CORE_CLEAR,
		"son yaş radius azad mərkəzə sığır (%.0f ≤ %.0f)"
			% [Const.SOLO_MIN_RADIUS, DishMap.CORE_CLEAR])

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




## KOL: mikrob da, top da keçir — amma içindəki GİZLƏNİR.
##
## Gizlənmə serverin göndərmə qərarıdır ([method World._near_germs]), ona
## görə test snapshot-a baxır, simulyasiyaya yox: qayda YALNIZ paketdə
## mövcuddur. Mövqeyi göndərib client-də gizlətmək gizlənmə DEYİL.
static func _test_bush_hides() -> void:
	var s := Sim.new()
	var bush := _first_of(s, DishMap.Kind.BUSH)
	_check(bush.w >= 0.0, "düzümdə ən azı bir kol var")
	var at := Vector2(bush.x, bush.y)

	var a := s.add_germ(A_ID, "A", 0)
	a.pos = at
	_check(s.bush_of(a) >= 0, "kolun mərkəzindəki mikrob kolun içində sayılır")

	# Kol mikrobu BLOKLAMIR: içinə girmək mümkün olmalıdır.
	a.pos = at
	a.vel = Vector2.ZERO
	s.step_movement({}, Const.TICK_DELTA)
	_check(a.pos.distance_to(at) < 40.0,
		"kol mikrobu itələmir (yerdəyişmə %.1f px)" % a.pos.distance_to(at))

	# Böyük mikrob kiçik kola sığmır — böyümənin qiyməti.
	a.capacity = Const.MAX_CAPACITY
	var fits := bush.z >= a.radius()
	_check(s.bush_of(a) >= 0 if fits else s.bush_of(a) < 0,
		"böyük mikrob yalnız kifayət qədər iri kolda gizlənir (r=%.0f, kol=%.0f)"
			% [a.radius(), bush.z])


## KÖVRƏK QABIQ: zərbələr onu sındırır, sındıqdan sonra yol AÇILIR.
static func _test_brittle_breaks() -> void:
	var s := Sim.new()
	var idx := -1
	for i in s.obstacles.size():
		if int(s.obstacles[i].w) == DishMap.Kind.BRITTLE:
			idx = i
			break
	_check(idx >= 0, "düzümdə ən azı bir kövrək qabıq var")
	if idx < 0:
		return

	var o := s.obstacles[idx]
	var at := Vector2(o.x, o.y)
	var dir := at.normalized()

	var g := s.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	# Qabığın xaricindən, düz mərkəzinə nişan alırıq.
	var from := at + dir * (o.z + 90.0)

	var hp := DishMap.BRITTLE_HP
	for shot in hp:
		g.pos = from
		g.vel = Vector2.ZERO
		g.balls = Const.START_CAPACITY
		g.cooldown = 0.0
		_fire_once(s, g, (at - from).angle(), 14)
	_check(DishMap.wall_gone(s.broken[idx]),
		"%d zərbədən sonra qabıq dağılır" % hp)

	# Dağılan qabıq artıq bloklamır: mikrob onun mərkəzindən keçə bilir.
	g.pos = at
	g.vel = Vector2.ZERO
	s.step_movement({}, Const.TICK_DELTA)
	_check(g.pos.distance_to(at) < 40.0,
		"dağılan qabıq yolu açır (yerdəyişmə %.1f px)" % g.pos.distance_to(at))


## CƏRƏYAN DEŞİYİ: içindən keçəni MƏRKƏZƏ doğru itələyir.
static func _test_vent_pushes() -> void:
	var s := Sim.new()
	var vent := _first_of(s, DishMap.Kind.VENT)
	_check(vent.w >= 0.0, "düzümdə ən azı bir cərəyan deşiyi var")
	var at := Vector2(vent.x, vent.y)

	var g := s.add_germ(A_ID, "A", 0)
	g.pos = at
	g.vel = Vector2.ZERO
	var before := g.pos.length()
	for i in 10:
		s.step_movement({}, Const.TICK_DELTA)
	var moved := before - g.pos.length()
	# Mərkəzə YAXINLAŞMALIDIR. Hədd axının öz təsirindən böyükdür: qabın
	# burulğanı da mikrobu tərpədir, amma o, radial deyil.
	_check(moved > 20.0,
		"cərəyan mikrobu mərkəzə doğru itələyir (%.0f px yaxınlaşdı)" % moved)

	# Deşikdən KƏNARDA itələmə olmamalıdır.
	g.pos = at + at.normalized() * (vent.z + 60.0)
	g.vel = Vector2.ZERO
	var out_before := g.pos.length()
	for i in 10:
		s.step_movement({}, Const.TICK_DELTA)
	_check(absf(out_before - g.pos.length()) < 12.0,
		"deşikdən kənarda itələmə yoxdur (%.1f px)"
			% absf(out_before - g.pos.length()))


## Düzümdəki ilk verilmiş növ. Tapılmasa `w` mənfi olan Vector4 qaytarır.
static func _first_of(s: Sim, kind: int) -> Vector4:
	for o in s.obstacles:
		if int(o.w) == kind:
			return o
	return Vector4(0.0, 0.0, 0.0, -1.0)


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
	_check(Const.CURRENT_SCALE < Const.VIEW_SPAN_BASE,
		"burulğan ekrana sığır (dalğa uzunluğu %.0f < ekran %.0f px)"
			% [Const.CURRENT_SCALE, Const.VIEW_SPAN_BASE])
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
	# Sehrli rəqəm YOX: enum-un özü ölçünü deyir, ona görə sahə əlavə olunanda
	# test öz-özünə uyğunlaşır və yalnız HƏQİQİ uyğunsuzluqda sınır.
	_check(snap.size() == Const.Snap.size(),
		"snapshot quruluşu düzgündür (%d sahə, gözlənilən %d)" % [snap.size(), Const.Snap.size()])
	# Divar vəziyyəti hər snapshot ilə gedir: maneə başına bir bayt.
	_check(snap[Const.Snap.WALLS].size() == DishMap.obstacles().size(),
		"snapshot divar vəziyyətini daşıyır (%d maneə)" % snap[Const.Snap.WALLS].size())
	# Mikroblar sıx formatdadır — açılmadan sayıla bilməz
	# (bax [method Const.unpack_germs]).
	var germs := Const.unpack_germs(snap[Const.Snap.GERMS])
	_check(germs.size() >= 2, "snapshot mikrobları daşıyır (%d)" % germs.size())


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




## Gizlənmə YALNIZ snapshot-da mövcuddur — və test məhz oranı yoxlayır.
##
## [method Sim.bush_of] doğru işləsə də, server mövqeyi göndərsə gizlənmə
## YOXDUR: paket şəbəkədədir, onu oxuyan hər kəs mikrobu görür. Ona görə
## qayda "kolda sayılırmı" ilə deyil, "paketdə varmı" ilə yoxlanılır.
static func _test_world_bush_filter() -> void:
	var world := _quiet_world(3)
	var bush := Vector4.ZERO
	for o in world.sim.obstacles:
		if int(o.w) == DishMap.Kind.BUSH:
			bush = o
			break
	var at := Vector2(bush.x, bush.y)

	# A kolun içində, B isə kolun kənarında — amma görüş sahəsi daxilində.
	var a := world.add_player(A_ID, "A")
	var b := world.add_player(B_ID, "B")
	a.safe_t = 0.0
	b.safe_t = 0.0
	a.pos = at
	b.pos = at + Vector2(bush.z + 120.0, 0.0)
	world._build_frame()

	var ids := _germ_ids(world.snapshot_for(B_ID))
	_check(not ids.has(A_ID), "kolun içindəki mikrob RƏQİBƏ göndərilmir")
	_check(ids.has(B_ID), "kolun kənarındakı mikrob görünür")

	# Öz mikrobun həmişə gəlir: sən özünü kolda da görməlisən, yoxsa
	# ekranda mikrobun yox olar.
	_check(_germ_ids(world.snapshot_for(A_ID)).has(A_ID),
		"öz mikrobun kolda da özünə göndərilir")

	# EYNİ kolda duran iki oyunçu bir-birini GÖRÜR — yoxsa kol içində
	# toqquşub bir-birini heç vaxt tapa bilməzdilər.
	b.pos = at + Vector2(bush.z * 0.4, 0.0)
	world._build_frame()
	_check(_germ_ids(world.snapshot_for(B_ID)).has(A_ID),
		"eyni kolun içindəkilər bir-birini görür")


## Snapshot-dakı mikrob id-ləri.
static func _germ_ids(snap: Array) -> Array:
	var out := []
	for row in Const.unpack_germs(snap[Const.Snap.GERMS]):
		out.append(int(row[Const.GF.ID]))
	return out




## Divarın dağılması SERVERDƏN client-ə tam çatır.
##
## Sınmanın özü [method _test_brittle_breaks]-də yoxlanılır; burada yoxlanılan
## ŞƏBƏKƏ MÜQAVİLƏSİDİR: server divarı sındırır → snapshot vəziyyəti daşıyır →
## client onu öz proqnozuna yazanda EYNİ yol açılır.
##
## Bu addım pozulsaydı xəta görünməzdi: oyunçu serverdə keçdiyi yerdən öz
## ekranında keçə bilməzdi, proqnoz onu artıq olmayan divarda saxlayardı və
## hər tick-də düzəliş gələrdi — yəni rezin kimi dartılma. Görüntüdə isə divar
## sadəcə yoxdur, ona görə oyunçu səbəbi heç cür anlaya bilməzdi.
static func _test_wall_sync() -> void:
	var world := _quiet_world(4)
	var idx := -1
	for i in world.sim.obstacles.size():
		if int(world.sim.obstacles[i].w) == DishMap.Kind.BRITTLE:
			idx = i
			break
	if idx < 0:
		_check(false, "düzümdə kövrək qabıq var")
		return
	var o := world.sim.obstacles[idx]
	var at := Vector2(o.x, o.y)

	var a := world.add_player(A_ID, "A")
	a.safe_t = 0.0
	var from := at + at.normalized() * (o.z + 90.0)
	for shot in DishMap.BRITTLE_HP:
		a.pos = from
		a.vel = Vector2.ZERO
		a.balls = Const.START_CAPACITY
		a.cooldown = 0.0
		_fire_once(world.sim, a, (at - from).angle(), 14)

	world._build_frame()
	var walls: PackedByteArray = world.snapshot_for(A_ID)[Const.Snap.WALLS]
	_check(walls.size() == world.sim.obstacles.size(),
		"snapshot bütün divarları daşıyır (%d bayt)" % walls.size())
	_check(DishMap.wall_gone(walls[idx]), "dağılan divar snapshot-da işarələnir")

	# Client tərəfi: serverin massivini olduğu kimi öz proqnozuna yazır
	# (bax [method Arena._apply_walls]).
	var client := Sim.new()
	client.broken = walls
	var g := client.add_germ(B_ID, "B", 1)
	g.pos = at
	g.vel = Vector2.ZERO
	client.step_movement({}, Const.TICK_DELTA)
	_check(g.pos.distance_to(at) < 40.0,
		"client divarı serverin dediyi kimi açır (%.1f px)" % g.pos.distance_to(at))

	# Vəziyyət göndərilməsəydi client divarı BAĞLI saxlayardı — testin özü
	# doğru yeri ölçdüyünü belə sübut edir.
	var blind := Sim.new()
	var b := blind.add_germ(B_ID, "B", 1)
	b.pos = at
	b.vel = Vector2.ZERO
	blind.step_movement({}, Const.TICK_DELTA)
	_check(b.pos.distance_to(at) > 40.0,
		"vəziyyət olmadan client divarı bağlı saxlayır (%.1f px)"
			% b.pos.distance_to(at))


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
		var got: Array = Net.parse_address(c[0])
		if got[0] != c[1] or int(got[1]) != int(c[2]):
			ok = false
			printerr("       '%s' → %s:%s (gözlənilən %s:%s)" % [c[0], got[0], got[1], c[1], c[2]])
	_check(ok, "server ünvanı %d formada düzgün ayrılır" % cases.size())

	# Heç yerə qoşulmamışıq — [method Net.is_connected_to_server] YALAN
	# deməlidir.
	#
	# Bu, nəzəri yoxlama deyil: Godot standart olaraq [OfflineMultiplayerPeer]
	# qoyur, o isə özünü "QOŞULU" elan edir və id kimi 1 (yəni "server")
	# qaytarır. Yalnız nəqliyyat statusuna baxan yoxlama burada YANLIŞ olaraq
	# "onlayn" deyirdi, menyu isə serverə `rpc_id(1, ...)` göndərib "RPC on
	# yourself" xətası alırdı — OYNA düyməsi sükutla işləmirdi.
	_check(not Net.is_connected_to_server(),
		"qoşulmamış client özünü onlayn saymır (standart offline peer tələsi)")


## Növ özəllikləri döyüş riyaziyyatına TOXUNMUR.
##
## Bu, sənədin yox, KODUN saxladığı qaydadır və qalan hər şeydən vacibdir:
## passivlər və superlər əlavə olunandan sonra ən asan səhv "bir növü bir az
## güclü etmək"dir. Həmin an oyunçu menyuda "hansı daha güclüdür" soruşmağa
## başlayır və seçim zövq deyil, məcburiyyət olur.
static func _test_species_share_combat_math() -> void:
	var costs := []
	var cds := []
	var caps := []
	for i in Const.SPECIES_COUNT:
		var s := Sim.new()
		var g := s.add_germ(A_ID, "A", 0, false, Const.species_from(i))
		g.safe_t = 0.0
		g.pos = Vector2.ZERO
		var before := g.balls
		s._fire(g)
		costs.append(before - g.balls)
		cds.append(g.cooldown)
		var victim := s.add_germ(B_ID, "B", 1)
		s._burst(victim, A_ID)
		caps.append(g.capacity)

	_check(costs[0] == costs[1] and costs[1] == costs[2],
		"üç növ atəşə eyni qiymət verir (%s)" % [costs])
	_check(is_equal_approx(cds[0], cds[1]) and is_equal_approx(cds[1], cds[2]),
		"üç növün atəş dövrü eynidir (%.2f s)" % cds[0])
	_check(caps[0] == caps[1] and caps[1] == caps[2],
		"üç növ partlatmadan eyni tutum alır (%s)" % [caps])


## Passivlər həqiqətən işləyir — əmsallar yazılıb, amma tətbiq olunmaya bilər.
static func _test_species_movement() -> void:
	var reached := []
	for i in Const.SPECIES_COUNT:
		var s := Sim.new()
		var g := s.add_germ(A_ID, "A", 0, false, Const.species_from(i))
		g.pos = Vector2(0.0, LANE_Y)
		var inp := Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false)
		for t in 12:
			s.step_movement({A_ID: inp}, Const.TICK_DELTA)
		reached.append(g.vel.length())

	_check(reached[0] > reached[2],
		"kirpikli amöbdən tez sürətlənir (%.0f > %.0f px/s)" % [reached[0], reached[2]])

	# Axına tabelik: eyni nöqtədə, itələməsiz — kim daha çox sürüklənir.
	var drift := []
	for i in Const.SPECIES_COUNT:
		var s2 := Sim.new()
		var g2 := s2.add_germ(A_ID, "A", 0, false, Const.species_from(i))
		g2.pos = Vector2(300.0, 300.0)
		var idle := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)
		for t in 30:
			s2.step_movement({A_ID: idle}, Const.TICK_DELTA)
		drift.append(g2.pos.distance_to(Vector2(300.0, 300.0)))

	_check(drift[1] < drift[0],
		"ayaqlı axına dirənir, kirpikli sürüklənir (%.1f < %.1f px)" % [drift[1], drift[0]])


## Amöb başqasının sığmadığı aralıqdan keçir.
##
## Yoxlama SÜNİ maneə ilə aparılır, xəritənin öz düzümü ilə yox: düzüm
## dəyişəndə test "aralıq qalmadı" deyə sınmamalıdır — yoxlanan qayda
## radiusun kiçilməsidir, konkret xəritə deyil.
static func _test_amoeba_squeezes() -> void:
	var pushed := []
	for i in Const.SPECIES_COUNT:
		var s := Sim.new()
		var g := s.add_germ(A_ID, "A", 0, false, Const.species_from(i))
		var r := g.radius()
		# Maneənin kənarı mikrobun tam radiusuna toxunur, kiçildilmişinə yox.
		s.obstacles = [Vector4(0.0, 0.0, r * 0.90, float(DishMap.Kind.MUCUS))]
		s.broken = PackedByteArray([0])
		var start := Vector2(r * 1.80, 0.0)
		g.pos = start
		s._confine(g)
		pushed.append(g.pos.x > start.x + 0.01)

	_check(pushed[0] and not pushed[2],
		"amöb dar aralıqdan keçir, kirpikli itələnir (kirpikli=%s amöb=%s)"
			% [pushed[0], pushed[2]])


## Superin doluluğu: dəymə doldurur, hədd keçilmir, bayraq pozulmur.
static func _test_super_charge() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]

	_fire_once(s, a, 0.0, 24)
	_check(a.charge == Const.SUPER_ON_HIT,
		"dəymə atana doluluq verir (%d)" % a.charge)
	_check(b.charge == Const.SUPER_ON_TAKEN,
		"dəyən tərəf də bir az alır (%d)" % b.charge)

	s._charge(a, 999)
	_check(a.charge == Const.SUPER_MAX, "doluluq həddi keçmir (%d)" % a.charge)

	# Bayraq yığımı: doluluq nə növü, nə qalxanı pozmalıdır.
	a.species = Const.Species.AMOEBA
	a.safe_t = 1.0
	var flags := World._flags_of(a)
	var back := (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
	var sp := (flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT
	_check(back == Const.SUPER_MAX and sp == int(Const.Species.AMOEBA)
			and (flags & Const.GFlag.SAFE) != 0,
		"bayraqda doluluq, növ və qalxan yan-yana durur (doluluq=%d növ=%d)" % [back, sp])


## Heç bir super rəqibin TOP SAYINA toxunmur.
## "Zərər verən super yoxdur" qaydasının kodda saxlanan variantı.
static func _test_super_no_damage() -> void:
	for i in Const.SPECIES_COUNT:
		var s := Sim.new()
		var a := s.add_germ(A_ID, "A", 0, false, Const.species_from(i))
		var b := s.add_germ(B_ID, "B", 1)
		a.safe_t = 0.0
		b.safe_t = 0.0
		a.pos = Vector2.ZERO
		b.pos = Vector2(a.radius() * 1.5, 0.0)
		var before := b.balls
		a.charge = Const.SUPER_MAX
		s._use_super(a)
		_check(b.balls == before,
			"%d nömrəli növün superi rəqibin topuna toxunmur (%d → %d)"
				% [i, before, b.balls])


## Trixosist: yaxındakı rəqib topu dağılır və QİDA olur — maddə itmir.
static func _test_trichocyst() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	a.species = Const.Species.CILIATE
	a.charge = Const.SUPER_MAX

	s._fire(b)
	var shots_before := s.shots.size()
	for shot in s.shots:
		shot.pos = a.pos + Vector2(a.radius() * 1.5, 0.0)
	var food_before := s.food.size()
	var balls_before := a.balls

	s._use_super(a)

	_check(shots_before == 1 and s.shots.is_empty(),
		"yaxındakı rəqib topu dağıldı (%d → %d)" % [shots_before, s.shots.size()])
	_check(s.food.size() == food_before + 1,
		"dağılan top qida oldu — maddə itmir (%d → %d)" % [food_before, s.food.size()])
	_check(a.balls == balls_before - Const.TRICHO_COST,
		"trixosist top xərcləyir (%d → %d)" % [balls_before, a.balls])


## Sistləşmiş amöba top GİRMİR, səkir; qabıq açılanda yenidən dəyir.
static func _test_cyst_bounces() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.species = Const.Species.AMOEBA
	b.charge = Const.SUPER_MAX
	s._use_super(b)
	_check(b.in_cyst(), "amöb qabığa girdi (%.1f s qaldı)" % b.super_t)

	var before := b.balls
	_fire_once(s, a, 0.0, 24)
	_check(b.balls == before, "qabığa top girmir (%d → %d)" % [before, b.balls])

	# Qabıq açılır. Atəş dövrü də sıfırlanır — yoxsa ikinci atəş soyuma
	# ucbatından ümumiyyətlə baş vermir və test qabığı yox, dövrü ölçər.
	b.super_t = 0.0
	a.cooldown = 0.0
	_fire_once(s, a, 0.0, 24)
	_check(b.balls == before + Const.SHOT_PAYLOAD,
		"qabıq açılanda top yenidən dəyir (%d → %d)" % [before, b.balls])


## Ayaqlının toru qidanı özünə çəkir.
static func _test_net_pulls_food() -> void:
	var s := _fresh()
	var h: Sim.GermState = s.germs[A_ID]
	h.species = Const.Species.HELIOZOAN
	h.charge = Const.SUPER_MAX
	h.balls = h.capacity          # dolu: qidanı udmasın, yalnız CƏZBİ ölçülsün
	s.germs.erase(B_ID)

	var reach := h.radius() * Const.NET_RADIUS
	s._drop_food(h.pos + Vector2(reach * 0.8, 0.0), Vector2.ZERO, 0)
	var before := s.food[0].pos.distance_to(h.pos)

	s._use_super(h)
	s._step_food(Const.TICK_DELTA)
	var after := s.food[0].pos.distance_to(h.pos)
	_check(after < before - 1.0,
		"tor qidanı özünə çəkir (%.0f → %.0f px)" % [before, after])

	# Tor bağlı olanda çəkim də bitir.
	h.super_t = 0.0
	var mid := s.food[0].pos.distance_to(h.pos)
	s._step_food(Const.TICK_DELTA)
	_check(is_equal_approx(s.food[0].pos.distance_to(h.pos), mid)
			or absf(s.food[0].pos.distance_to(h.pos) - mid) < 2.0,
		"tor bağlananda qida sərbəst qalır")

## Botlar superini HƏQİQƏTƏN işlədir.
##
## Bu, "bot koduna bir sətir əlavə etdim" yoxlaması deyil: dünyanın əhalisinin
## çoxu botdur, ona görə super yalnız botlar onu işlədəndə OYUNUN bir hissəsinə
## çevrilir. İnsan oyunçu rəqibin superini görməsə, öz superinin nə olduğunu da
## öyrənə bilmir.
##
## Dünya 40 saniyə öz-özünə işləyir və super hadisələri sayılır.
static func _test_bots_use_supers() -> void:
	var world := World.new(1)
	var supers := 0
	var ticks := int(40.0 / Const.TICK_DELTA)
	for i in ticks:
		world.tick(Const.TICK_DELTA)
		for e in world.sim.events:
			if String(e.get("t", "")) == "super":
				supers += 1

	_check(supers > 0, "botlar 40 saniyədə superi işlətdi (%d dəfə)" % supers)


## HƏR NÖVÜN superi həqiqətən işə düşür.
##
## Ümumi say kifayət etmir: bir növün superi tamamilə ölü ola bilər, qalan
## ikisi isə sayı doldurar. Kirpiklidə məhz belə idi — trixosist iki top
## xərcləyir və [method Sim.GermState.super_ready] ən azı beş top tələb edir,
## ona görə aşağı topda oynayan mikrob super düyməsini heç vaxt yandıra
## bilmirdi. Vizual testdə 11 cəhdin heç birində ekrana düşməmişdi.
static func _test_every_species_uses_super() -> void:
	const NAMES := ["kirpikli", "ayaqlı", "amöb"]
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		var world := World.new(1)
		# Bütün dünya bir növdən: qarışıq dünyada bir növ təsadüfən heç vaxt
		# doğulmaya bilər və test səbəbsiz yanıb-sönərdi.
		for gid in world.sim.germs:
			world.sim.germs[gid].species = kind

		var supers := 0
		var ticks := int(60.0 / Const.TICK_DELTA)
		for i in ticks:
			world.tick(Const.TICK_DELTA)
			for gid in world.sim.germs:
				world.sim.germs[gid].species = kind
			for e in world.sim.events:
				if String(e.get("t", "")) == "super":
					supers += 1

		_check(supers > 0, "%s superi işə düşür (%d dəfə)" % [
			NAMES[int(kind)], supers])


## Snapshot-dakı "super işləyir" biti öz mikrobunun vəziyyətini QURA bilməlidir.
##
## Client öz superini adətən proqnozda özü işə salır. MƏŞQ rejimində isə yerli
## dünya girişi proqnoz addımından ƏVVƏL emal edir: doluluq proqnoza çatanda
## artıq sıfırdır, [method Sim.GermState.super_ready] "yox" deyir və proqnozun
## sayğacı heç vaxt qalxmır. Ona görə ayaqlının toru və amöbin qabığı ÖZ
## mikrobunda heç vaxt çəkilmirdi — botlarda görünürdü, çünki onlar snapshot
## bayrağından gəlir.
##
## Düzəliş bayrağa söykənir (bax [method Arena._reconcile]), yəni yoxlanan şey
## bayrağın MÜQAVİLƏSİDİR: super işləyəndə bit qalxır və nə qədər qalxılı
## qalırsa, [method Const.super_time] də client-ə o qədər deyir.
static func _test_super_flag_carries_duration() -> void:
	const NAMES := ["kirpikli", "ayaqlı", "amöb"]
	for kind in [Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		var world := _quiet_world(41)
		var g := world.sim.add_germ(A_ID, "A", 0, false, kind)
		g.safe_t = 0.0
		g.charge = Const.SUPER_MAX
		# İkinci mikrob dünyanı AÇIQ saxlayır: tək mikrob qalanda dünya bitmiş
		# sayılır və donur (bax [method World._match_over]).
		world.sim.add_germ(B_ID, "B", 1).safe_t = 0.0

		world.accept_input(A_ID,
			Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false, true).to_array())
		world.tick(Const.TICK_DELTA)

		_check(_super_bit(world, A_ID),
			"%s: snapshot 'super işləyir' bitini daşıyır" % NAMES[int(kind)])

		# Bit nə qədər qalxılı qalır: client sayğacını məhz bundan qurur, yəni
		# ikisi bir-birindən bir neçə tick-dən çox ayrılmamalıdır.
		var ticks := 1
		while _super_bit(world, A_ID) and ticks < 600:
			world.tick(Const.TICK_DELTA)
			ticks += 1
		var lived := float(ticks) * Const.TICK_DELTA
		var want := Const.super_time(int(kind))
		_check(absf(lived - want) <= Const.TICK_DELTA * 3.0,
			"%s: bit superin öz müddəti qədər qalır (%.2f ≈ %.2f s)"
				% [NAMES[int(kind)], lived, want])


## Snapshot-dakı mikrobun "super işləyir" biti — client-in etdiyi işin eynisi.
static func _super_bit(world: World, gid: int) -> bool:
	for row in Const.unpack_germs(world.snapshot_for(gid)[Const.Snap.GERMS]):
		if int(row[Const.GF.ID]) == gid:
			return (int(row[Const.GF.FLAGS]) & Const.GFlag.SUPER) != 0
	return false


## Qabığın zədəsi BAYTDA daşınır və növü/dağılma bitini pozmur.
##
## Sayğac oyunçuya lazımdır: qabıq üç zərbədən sonra dağılır, amma sprite
## dəyişməsə oyunçu neçə zərbə qaldığını bilmir. Bayt paketlənməsi isə asan
## pozulan şeydir — dağılma biti ilə zərbə sayı eyni ədəddə yaşayır.
static func _test_wall_damage_bits() -> void:
	# Bit riyaziyyatı — Sim-dən asılı olmadan.
	var packed := (2 << DishMap.Wall.HITS_SHIFT) & DishMap.Wall.HITS_MASK
	_check(not DishMap.wall_gone(packed) and DishMap.wall_hits(packed) == 2,
		"zədə yazılır, dağılma biti təmiz qalır (bayt=%d)" % packed)

	packed |= DishMap.Wall.GONE
	_check(DishMap.wall_gone(packed) and DishMap.wall_hits(packed) == 2,
		"dağılma biti zədə sayını pozmur (bayt=%d)" % packed)

	# İndi həqiqi qabıqda: hər zərbədən sonra sayğac artmalıdır.
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var idx := -1
	for i in s.obstacles.size():
		if int(s.obstacles[i].w) == DishMap.Kind.BRITTLE:
			idx = i
			break
	if idx < 0:
		_check(false, "düzümdə kövrək qabıq tapılmadı")
		return

	var o := s.obstacles[idx]
	var at := Vector2(o.x, o.y)
	var from := at - Vector2(o.z + 140.0, 0.0)
	var seen := []
	for hit in DishMap.BRITTLE_HP:
		a.pos = from
		a.balls = Const.START_CAPACITY
		a.cooldown = 0.0
		_fire_once(s, a, 0.0, 14)
		seen.append(DishMap.wall_hits(s.broken[idx]))

	_check(seen == [1, 2, 3],
		"hər zərbə baytdakı sayğacı artırır (%s)" % [seen])
	_check(DishMap.wall_gone(s.broken[idx]),
		"sonuncu zərbə qabığı dağıdır")

## SONSUZ ARENA yeni matç sistemindən TƏSİRLƏNMİR.
##
## Ən vacib rejim testi budur: matç maşını əlavə olunanda ən asan səhv köhnə
## rejimi də onun içinə salmaqdır. Sonsuz arena həmişə PLAYING-dədir və
## qabı sabitdir — oyunçu düyməni basıb dərhal oynayır, əvvəlki kimi.
static func _test_endless_untouched() -> void:
	var world := World.new(1, Const.Mode.ENDLESS)
	_check(world.phase == Const.Phase.PLAYING,
		"sonsuz arena dərhal PLAYING-dədir")
	_check(world.inputs_open(), "sonsuz arenada giriş həmişə açıqdır")

	for i in 200:
		world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.PLAYING,
		"sonsuz arena fazadan çıxmır")
	_check(is_equal_approx(world.sim.dish_radius, Const.WORLD_RADIUS),
		"sonsuz arenada qab daralmır (%.0f)" % world.sim.dish_radius)
	_check(world.sim.germs.size() >= Const.MIN_POPULATION,
		"sonsuz arenada əhali saxlanılır (%d)" % world.sim.germs.size())


## Matçın fazaları düzgün ardıcıllıqla keçir.
static func _test_match_phases() -> void:
	var world := World.new(2, Const.Mode.SOLO)
	_check(world.phase == Const.Phase.WAITING, "matçlı dünya gözləyir")
	_check(not world.inputs_open(), "gözləyəndə giriş bağlıdır")

	# İnsan gələn kimi sayım başlayır — NÖVBƏ YOXDUR.
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.COUNTDOWN,
		"insan gələn kimi geriyə sayım başlayır")
	_check(not world.inputs_open(), "sayımda giriş bağlıdır")
	_check(world.sim.germs.size() == Const.WORLD_CAPACITY,
		"boş yerlər botla dolur (%d)" % world.sim.germs.size())

	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.PLAYING, "sayım bitəndə matç başlayır")
	_check(world.inputs_open(), "matçda giriş açıqdır")


## Qabın kənarı YALNIZ matç saatından asılıdır.
##
## Prediction müqaviləsi budur (bax design/MODES.md §8): client eyni düsturu
## işlədir. Radius mövqedən, təsadüfdən və ya oyun vəziyyətindən asılı olsaydı,
## iki tərəf ayrılar və mikrob hər snapshot-da geri sıçrayardı.
static func _test_dish_shrinks_by_clock() -> void:
	_check(is_equal_approx(Const.dish_radius(int(Const.Mode.ENDLESS), 999.0),
			Const.WORLD_RADIUS),
		"sonsuz arenada radius sabitdir")
	_check(is_equal_approx(Const.dish_radius(int(Const.Mode.SOLO), 0.0),
			Const.WORLD_RADIUS),
		"matçın başında qab tam açıqdır")
	_check(is_equal_approx(Const.dish_radius(int(Const.Mode.SOLO), Const.DRY_DELAY),
			Const.WORLD_RADIUS),
		"quruma gecikmə bitənə qədər başlamır")

	var mid := Const.dish_radius(int(Const.Mode.SOLO), Const.DRY_DELAY + Const.DRY_TIME * 0.5)
	_check(mid < Const.WORLD_RADIUS and mid > Const.SOLO_END_RADIUS,
		"ortada qab daralıb, amma sona çatmayıb (%.0f)" % mid)

	var main_end := Const.dish_radius(int(Const.Mode.SOLO), Const.DRY_DELAY + Const.DRY_TIME)
	_check(is_equal_approx(main_end, Const.SOLO_END_RADIUS),
		"əsas quruma SOLO_END_RADIUS-da bitir (%.0f)" % main_end)

	# SON SIXILMA — əsas quruma bitəndən sonra qab DAYANMIR, yavaş-yavaş daha da
	# daralır. Dayansaydı, matçın son dəqiqəsində heç nə dəyişməzdi.
	var late := Const.dish_radius(int(Const.Mode.SOLO), Const.DRY_DELAY + Const.DRY_TIME + 40.0)
	_check(late < Const.SOLO_END_RADIUS and late > Const.SOLO_MIN_RADIUS,
		"son sıxılma davam edir (%.0f)" % late)

	var end := Const.dish_radius(int(Const.Mode.SOLO), Const.MATCH_MAX * 2.0)
	_check(is_equal_approx(end, Const.SOLO_MIN_RADIUS),
		"quruma ən kiçik radiusda dayanır (%.0f)" % end)

	# Eyni saat → eyni radius. Təsadüf və ya vəziyyət qarışsaydı, iki çağırış
	# fərqli cavab verərdi.
	var t := Const.DRY_DELAY + 30.0
	_check(is_equal_approx(Const.dish_radius(int(Const.Mode.SOLO), t),
			Const.dish_radius(int(Const.Mode.SOLO), t)),
		"eyni saat həmişə eyni radius verir")


## Quru zonada mikrob top QAZANIR — itirmir.
##
## Dizaynın açar qərarı budur (bax design/MODES.md §3): oyunun imza ölümü
## partlamaqdır, aclıqla sönmək deyil. Üstəlik kənar həm təhlükə, həm YEM
## olur və oyunçuya real qərar verir.
static func _test_dry_zone_fills() -> void:
	var s := Sim.new()
	s.dish_radius = 400.0
	var g := s.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	g.pos = Vector2(600.0, 0.0)      # kənardan 200 px kənarda
	var before := g.balls
	var inp := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)
	for i in 60:                     # 2 saniyə
		g.pos = Vector2(600.0, 0.0)
		s.step({A_ID: inp}, Const.TICK_DELTA)
		if not s.germs.has(A_ID):
			break
	var after: int = s.germs[A_ID].balls if s.germs.has(A_ID) else 99
	_check(after > before,
		"quru zonada top ARTIR (%d → %d)" % [before, after])

	# Yaş zonada isə metabolizm işləyir: top azalır.
	var s2 := Sim.new()
	var g2 := s2.add_germ(A_ID, "A", 0)
	g2.safe_t = 0.0
	g2.pos = Vector2.ZERO
	g2.balls = 20
	g2.capacity = 40
	var b2 := g2.balls
	for i in 240:                    # 8 saniyə — bir metabolizm dövründən çox
		g2.pos = Vector2.ZERO
		s2.step({A_ID: inp}, Const.TICK_DELTA)
	_check(s2.germs[A_ID].balls < b2,
		"yaş zonada metabolizm topu yandırır (%d → %d)" % [b2, s2.germs[A_ID].balls])


## Quru zona metabolizmlə EYNİ şərtin altındadır.
##
## `step_movement` client-in proqnozudur və top sayına toxunmamalıdır: toxunsa,
## HUD-dakı rəqəm hər snapshot arasında yanıb-sönərdi.
static func _test_dry_zone_not_predicted() -> void:
	var s := Sim.new()
	s.dish_radius = 400.0
	var g := s.add_germ(A_ID, "A", 0)
	g.pos = Vector2(900.0, 0.0)
	var before := g.balls
	var inp := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false)
	for i in 120:
		g.pos = Vector2(900.0, 0.0)
		s.step_movement({A_ID: inp}, Const.TICK_DELTA)
	_check(g.balls == before,
		"proqnoz quru zonada top saymır (%d → %d)" % [before, g.balls])


## TAM MATÇ — botlar tək başına oynayanda matç çox tez bitmir.
##
## Bu, [method _test_bot_flees_dry_zone]-un davranış tərəfidir: bot qabı
## bilməsə, testlər tək-tək keçər, amma matç 20 saniyəyə bitər, çünki botlar
## kənarda dolub bir-bir partlayar. Yalnız TAM matç bunu tutur.
##
## Hədd qəsdən gevşəkdir (30 s): məqsəd balansı dondurmaq deyil, çökməni
## tutmaqdır.
static func _test_full_solo_match() -> void:
	var world := World.new(9, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	# İnsan oyunçu tərpənmir — yalnız botların özlərini necə apardığı ölçülür.
	var guard := int(Const.MATCH_MAX / Const.TICK_DELTA) + 600
	var i := 0
	while world.phase != Const.Phase.OVER and i < guard:
		world.tick(Const.TICK_DELTA)
		i += 1

	_check(world.phase == Const.Phase.OVER,
		"tam matç bitir (%d tick)" % i)
	_check(world.match_t > 30.0,
		"matç çox tez bitmir (%.0f s, %d sağ)" % [world.match_t, world.sim.germs.size()])
	_check(world.places.size() == Const.WORLD_CAPACITY,
		"matç sonunda hər mikrobun yeri var (%d)" % world.places.size())


## Bot daralan qabdan içəri qaçır.
##
## TƏK QALAN-ın ən böyük sınıq riski budur: bot qabı bilmirsə, botların hamısı
## kənarda dolub partlayır və insan oyunçu heç nə etmədən udur.
static func _test_bot_flees_dry_zone() -> void:
	var s := Sim.new()
	s.dish_radius = 400.0
	var g := s.add_germ(A_ID, "B", 0, true)
	g.safe_t = 0.0
	g.pos = Vector2(600.0, 0.0)      # yaş radiusdan xeyli kənarda
	g.balls = g.capacity - 2         # dolu → dərhal qaçmalıdır
	var bot := Bot.new(A_ID, 1.0)
	var inp := bot.think(s, Const.TICK_DELTA)
	_check(inp.move.x < -0.5,
		"dolu bot quru zonadan MƏRKƏZƏ qaçır (move.x=%.2f)" % inp.move.x)

	# Ac bot isə bir az qalır: orada top ARTIR, yəni kənar onun üçün yemdir.
	var s2 := Sim.new()
	s2.dish_radius = 400.0
	var g2 := s2.add_germ(A_ID, "B", 0, true)
	g2.safe_t = 0.0
	g2.pos = Vector2(400.0, 0.0)     # sərhəddən cəmi ~32 px kənarda
	g2.balls = Const.MIN_BALLS + 1
	var bot2 := Bot.new(A_ID, 1.0)
	var inp2 := bot2.think(s2, Const.TICK_DELTA)
	_check(inp2.move.x > -0.99,
		"ac bot kənarda bir az qala bilir (move.x=%.2f)" % inp2.move.x)

	# Çox dərinə düşəndə isə ac bot da qayıdır — tolerans sonsuz deyil.
	#
	# Bir kadrın vektoru YOX, məsafənin dəyişməsi yoxlanılır: bot maneədən yan
	# keçə bilər (bax [method Bot._avoid]), yəni bir anlıq istiqamət kənara
	# baxa bilər. Vacib olan nəticədir — mərkəzə yaxınlaşırmı.
	var s3 := Sim.new()
	s3.dish_radius = 400.0
	var g3 := s3.add_germ(A_ID, "B", 0, true)
	g3.safe_t = 0.0
	g3.pos = Vector2(400.0 * 0.92 + Bot.DRY_TOLERANCE + 60.0, 0.0)
	g3.balls = Const.MIN_BALLS + 1
	var bot3 := Bot.new(A_ID, 1.0)
	var was := g3.pos.length()
	for i in 90:
		if not s3.germs.has(A_ID):
			break
		s3.step({A_ID: bot3.think(s3, Const.TICK_DELTA)}, Const.TICK_DELTA)
	var now: float = s3.germs[A_ID].pos.length() if s3.germs.has(A_ID) else 0.0
	_check(now < was - 20.0,
		"ac bot da çox dərində mərkəzə qayıdır (%.0f → %.0f)" % [was, now])


## Sıra şəkilçiləri Azərbaycan dilinin ahənginə uyğundur.
##
## Nəticə ekranındakı yeganə iri yazı budur — səhvi hər matçda görünür.
static func _test_ordinals() -> void:
	var want := {1: "1-ci", 3: "3-cü", 4: "4-cü", 6: "6-cı", 9: "9-cu", 10: "10-cu"}
	var bad := ""
	for n in want:
		var got := Const.ordinal(int(n))
		if got != str(want[n]):
			bad += " %s(gözlənilən %s)" % [got, want[n]]
	_check(bad.is_empty(), "sıra şəkilçiləri düzgündür%s" % bad)


## Sonuncu mikrob qalanda matç bitir və yerlər paylanır.
static func _test_solo_ends_and_ranks() -> void:
	var world := World.new(3, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)     # WAITING → COUNTDOWN, botlar dolur
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)

	# Botları bir-bir acından öldürürük — hər biri bir yer almalıdır.
	var ids := world.sim.germs.keys()
	var killed := 0
	for gid in ids:
		if gid == A_ID:
			continue
		var g: Sim.GermState = world.sim.germs[gid]
		g.balls = 0
		world.tick(Const.TICK_DELTA)
		killed += 1
		if world.phase != Const.Phase.PLAYING:
			break

	_check(world.phase == Const.Phase.OVER,
		"sonuncu mikrob qalanda matç bitir (faza=%d)" % world.phase)
	# Yer HƏR mikroba çatır — qalib də daxil. Qalib partlamadığı üçün onun yeri
	# ayrıca verilir (bax [method World._award_survivors]); bu olmasaydı, matçı
	# UDAN oyunçu nəticə ekranında yerini "0" görərdi.
	_check(world.places.size() == Const.WORLD_CAPACITY,
		"hər mikrob yer alır, qalib də (%d ölü, %d yer)" % [killed, world.places.size()])

	_check(int(world.places.get(A_ID, 0)) == 1,
		"sağ qalan BİRİNCİ yeri alır (%d)" % int(world.places.get(A_ID, 0)))

	# Qalibin nəticəsi növbəyə düşür ki, [Lobby] onu göndərə bilsin.
	var mine := []
	for r in world.pending_results:
		if int(r["id"]) == A_ID:
			mine.append(r)
	_check(mine.size() == 1 and bool(mine[0]["won"]),
		"qalibin nəticəsi `won` bayrağı ilə növbəyə düşür (%d nəticə)" % mine.size())

	# İlk ölən ƏN PİS yeri almalıdır.
	var first_dead: int = int(world.places.keys()[0])
	_check(int(world.places[first_dead]) == Const.WORLD_CAPACITY,
		"ilk ölən sonuncu yeri alır (%d)" % int(world.places[first_dead]))


## Göndərilən sahə EKRANIN KÜNCÜNƏ çatır — hər telefon nisbətində.
##
## Kamera miqyası qısa kənardan çıxır ([method Arena._update_camera]), yəni
## ekran nə qədər genişdirsə, küncə qədər olan məsafə o qədər böyükdür.
## [constant Const.AOI_FACTOR] bundan kiçik olsa, obyektlər ekranın
## kənarında GÖZ QARŞISINDA peyda olar — səssiz uyğunluq səhvidir: 16:9
## telefonda düzgün işləyir, 20:9-da isə oyunçu qidanın və rəqiblərin
## havadan çıxdığını görür.
##
## Nisbətlər real telefonlardır: 16:9 (HD), 18:9, 19.5:9 (iPhone X+),
## 20:9 (yaygın Android), 21:9 (oyun telefonları), 4:3 (planşet).
static func _test_aoi_covers_screen() -> void:
	const ASPECTS := [
		[16.0 / 9.0, "16:9"], [2.0, "18:9"], [19.5 / 9.0, "19.5:9"],
		[20.0 / 9.0, "20:9"], [21.0 / 9.0, "21:9"], [4.0 / 3.0, "4:3"],
	]
	var bad := ""
	var worst := 0.0
	for cap in [Const.START_CAPACITY, 30, Const.MAX_CAPACITY]:
		var aoi := Const.aoi_radius(int(cap))
		for pair in ASPECTS:
			var a: float = pair[0]
			# Görünən SAHƏ sabitdir (bax [constant Const.VIEW_ASPECT_REF]), yəni
			# hündürlük nisbətdən çıxır: h = √(sahə / a), en = a × h.
			# Künc yarım-diaqonaldır.
			var area := Const.view_area(int(cap))
			var h := sqrt(area / a)
			var corner := 0.5 * h * sqrt(1.0 + a * a)
			var ratio := corner / aoi
			worst = maxf(worst, ratio)
			if corner > aoi:
				bad += " %s@%d(%.0f>%.0f)" % [pair[1], cap, corner, aoi]

	_check(bad.is_empty(),
		"görüş sahəsi bütün nisbətlərdə küncə çatır (ən dar hal %.0f%%)%s" % [
			worst * 100.0, bad])


## Komanda snapshot-dan DÜZGÜN keçir — client yoldaşı tanıya bilir.
##
## Komanda bayrağın 8-10-cu bitlərindədir və `team + 1` kimi yazılır. Səhv
## sürüşmə və ya maska səssiz olur: mikroblar çəkilir, oyun işləyir, sadəcə
## yoldaş düşmən kimi görünür — ekranda heç bir xəta yoxdur.
static func _test_team_bits_roundtrip() -> void:
	var world := World.new(44, Const.Mode.DUO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	world._build_frame()

	var want := {}
	for gid in world.sim.germs:
		want[gid] = world.sim.germs[gid].team

	var bad := ""
	var seen := 0
	for row in Const.unpack_germs(world.snapshot_for(A_ID)[Const.Snap.GERMS]):
		var gid := int(row[Const.GF.ID])
		var got := ((int(row[Const.GF.FLAGS]) & Const.GFlag.TEAM_MASK)
			>> Const.GFlag.TEAM_SHIFT) - 1
		seen += 1
		if got != int(want.get(gid, -99)):
			bad += " %d:%d≠%d" % [gid, got, want.get(gid, -99)]
	_check(seen > 0 and bad.is_empty(),
		"komanda bayraqdan düzgün oxunur (%d mikrob%s)" % [seen, bad])

	# Komandasız rejimdə bit SIFIR olmalıdır, yəni oxunuş -1 verməlidir.
	var solo := World.new(45, Const.Mode.SOLO)
	solo.add_player(A_ID, "A")
	solo.tick(Const.TICK_DELTA)
	solo._build_frame()
	var none := true
	for row in Const.unpack_germs(solo.snapshot_for(A_ID)[Const.Snap.GERMS]):
		var got := ((int(row[Const.GF.FLAGS]) & Const.GFlag.TEAM_MASK)
			>> Const.GFlag.TEAM_SHIFT) - 1
		if got != -1:
			none = false
	_check(none, "komandasız rejimdə komanda biti boşdur")


## CÜT: komandalar bərabər dolur və yoldaşa top dəymir.
static func _test_duo_teams() -> void:
	var world := World.new(41, Const.Mode.DUO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)

	_check(world.sim.germs.size() == Const.WORLD_CAPACITY,
		"CÜT-də dünya dolur (%d)" % world.sim.germs.size())

	var count := {}
	for gid in world.sim.germs:
		var tm: int = world.sim.germs[gid].team
		count[tm] = int(count.get(tm, 0)) + 1
	var bad := ""
	for k in count:
		if int(count[k]) != 2:
			bad += " komanda %d=%d" % [k, count[k]]
	_check(count.size() == 5 and bad.is_empty(),
		"5 komanda × 2 mikrob (%d komanda%s)" % [count.size(), bad])

	# DOST ATƏŞİ: yoldaşa atılan top ona TOP ƏLAVƏ ETMƏMƏLİDİR.
	var mate := -1
	var my_team: int = world.sim.germs[A_ID].team
	for gid in world.sim.germs:
		if gid != A_ID and world.sim.germs[gid].team == my_team:
			mate = gid
			break
	_check(mate != -1, "yoldaş tapıldı")
	if mate == -1:
		return

	var me: Sim.GermState = world.sim.germs[A_ID]
	var buddy: Sim.GermState = world.sim.germs[mate]
	me.safe_t = 0.0
	buddy.safe_t = 0.0
	me.pos = Vector2.ZERO
	buddy.pos = Vector2(150.0, 0.0)
	var before := buddy.balls
	me.aim = 0.0
	me.cooldown = 0.0
	world.sim._fire(me)
	for i in 40:
		buddy.pos = Vector2(150.0, 0.0)
		world.sim.step({}, Const.TICK_DELTA)
		if not world.sim.germs.has(mate):
			break
	var after: int = world.sim.germs[mate].balls if world.sim.germs.has(mate) else -1
	_check(after <= before, "yoldaşa atılan top ona top VERMİR (%d → %d)" % [before, after])


## CÜT: yoldaşı sağ ikən ölüm müvəqqətidir, ikisi də ölsə cüt çıxır.
## Bir tick aralığında gələn İKİ giriş paketi superi UDMUR.
##
## Serverin növbəsində oyunçu başına yalnız son giriş saxlanılır. Super isə
## cəmi BİR tick göndərilir ([method Arena._super_requested]), ona görə
## üstündən yazılan paket onu tamamilə itirirdi: oyunçu yanan düyməyə basırdı,
## proqnoz effekti bir kadr göstərirdi, növbəti snapshot ləğv edirdi və
## doluluq yerində qalırdı. Lokal WebSocket-də girişlərin 3.4%-i belə itirdi —
## onlayn oyunda "ulti işləmir" şikayətinin kök səbəbi.
##
## Paketlərin yığılması normal haldır: client kadr sıçrayanda iki tick-i bir
## kadrda göndərir, WebSocket isə onsuz da paketləri birləşdirir.
static func _test_super_survives_packet_pileup() -> void:
	# Növ AYAQLIDIR: onun superi `super_t` qoyur, yəni işə düşdüyü snapshot
	# bayrağından da görünür — kirpiklidə effekt anidir və izi qalmır.
	var pairs := [
		["super BİRİNCİ paketdə", true, false],
		["super İKİNCİ paketdə", false, true],
	]
	for case in pairs:
		var world := World.new(77, Const.Mode.ENDLESS)
		var g := world.add_player(A_ID, "A", Const.Species.HELIOZOAN)
		g.charge = Const.SUPER_MAX
		g.balls = Const.START_BALLS

		var first := Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false, bool(case[1]))
		var second := Sim.PlayerInput.make(2, Vector2.RIGHT, 0.0, false, bool(case[2]))
		world.accept_input(A_ID, first.to_array())
		world.accept_input(A_ID, second.to_array())
		world.tick(Const.TICK_DELTA)

		_check(g.charge == 0 and g.super_t > 0.0,
			"%s: iki paket bir tick-də gələndə super İŞLƏYİR (doluluq %d, super_t %.1f)"
				% [String(case[0]), g.charge, g.super_t])

	# Əks yoxlama: super basılmayıbsa, yığılan paketlər onu ÖZ-ÖZÜNƏ işə salmır.
	var quiet := World.new(78, Const.Mode.ENDLESS)
	var q := quiet.add_player(A_ID, "A", Const.Species.HELIOZOAN)
	q.charge = Const.SUPER_MAX
	quiet.accept_input(A_ID, Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false, false).to_array())
	quiet.accept_input(A_ID, Sim.PlayerInput.make(2, Vector2.RIGHT, 0.0, false, false).to_array())
	quiet.tick(Const.TICK_DELTA)
	_check(q.charge == Const.SUPER_MAX and q.super_t <= 0.0,
		"basılmayan super öz-özünə işə düşmür (doluluq %d)" % q.charge)

	# Emal olunan bayraq NÖVBƏTİ tick-ə keçmir — yoxsa bir basılış superi
	# təkrar-təkrar işlədərdi.
	var once := World.new(79, Const.Mode.ENDLESS)
	var o := once.add_player(A_ID, "A", Const.Species.HELIOZOAN)
	o.charge = Const.SUPER_MAX
	once.accept_input(A_ID, Sim.PlayerInput.make(1, Vector2.RIGHT, 0.0, false, true).to_array())
	once.tick(Const.TICK_DELTA)
	o.charge = Const.SUPER_MAX
	o.super_t = 0.0
	once.tick(Const.TICK_DELTA)
	_check(o.charge == Const.SUPER_MAX,
		"bir basılış YALNIZ bir dəfə işləyir (doluluq %d)" % o.charge)


## Oyunçu QURU zonada doğulmur — qabın kənarı ilk tick-i gözləmir.
##
## `sim.dish_radius` yalnız [method World.tick]-in içində qoyulurdu, oyunçu isə
## `add_player` ilə ondan ƏVVƏL doğulur. İlkin dəyər `WORLD_RADIUS` (1200)
## olduğuna görə ÜÇLÜK-də (yaş radius 700) doğuş dairəsinin üçdə ikisi quru
## zonaya düşürdü: mikrob geriyə sayımda, tərpənə bilmədən top yığırdı.
static func _test_spawn_inside_wet_zone() -> void:
	for mode in [Const.Mode.SOLO, Const.Mode.DUO, Const.Mode.TRIO]:
		var world := World.new(80, mode)
		var wet := Const.dish_radius(int(mode), 0.0)
		var dry := 0
		var worst := 0.0
		for gid in world.sim.germs:
			var g: Sim.GermState = world.sim.germs[gid]
			var d := g.pos.length()
			if d > wet:
				dry += 1
				worst = maxf(worst, d - wet)
		# Botlar `_keep_population` ilə gəlir, ona görə insanı da əlavə edirik.
		var me := world.add_player(A_ID, "A")
		if me.pos.length() > wet:
			dry += 1
			worst = maxf(worst, me.pos.length() - wet)
		_check(dry == 0, "%s: heç kim quru zonada doğulmur (%d nəfər, ən dərini %.0f px)"
			% [Const.mode_name(int(mode)), dry, worst])


static func _test_duo_revive() -> void:
	var world := World.new(42, Const.Mode.DUO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)

	var my_team: int = world.sim.germs[A_ID].team
	var mate := -1
	for gid in world.sim.germs:
		if gid != A_ID and world.sim.germs[gid].team == my_team:
			mate = gid
			break

	# Yoldaş ölür — YER ALMIR, çünki mən sağam.
	world.sim.germs[mate].balls = 0
	world.tick(Const.TICK_DELTA)
	_check(not world.places.has(mate),
		"yoldaşı sağ ikən ölənə yer VERİLMİR")
	_check(not world.sim.germs.has(mate) and world._revive.has(mate),
		"ölən yoldaş dirilmə növbəsindədir")

	# Vaxt keçir — qayıdır.
	var ticks := int(Const.REVIVE_TIME / Const.TICK_DELTA) + 4
	for i in ticks:
		world.sim.germs[A_ID].balls = Const.START_BALLS
		world.tick(Const.TICK_DELTA)
	_check(world.sim.germs.has(mate), "yoldaş %.0f saniyə sonra dirilir" % Const.REVIVE_TIME)
	if world.sim.germs.has(mate):
		_check(world.sim.germs[mate].capacity == Const.START_CAPACITY,
			"dirilən mikrobun tutumu SIFIRLANIR (%d)" % world.sim.germs[mate].capacity)
		_check(world.sim.germs[mate].team == my_team,
			"dirilən mikrob ÖZ komandasına qayıdır")


## ÜÇLÜK: 3v3, raundlar, üç raundun ikisini udan qalib.
static func _test_trio_rounds() -> void:
	var world := World.new(43, Const.Mode.TRIO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)

	_check(world.sim.germs.size() == Const.TRIO_GERMS,
		"ÜÇLÜK-də %d mikrob (%d)" % [Const.TRIO_GERMS, world.sim.germs.size()])
	_check(is_equal_approx(Const.dish_radius(int(Const.Mode.TRIO), 0.0), Const.TRIO_RADIUS),
		"ÜÇLÜK öz qabında oynanır (%.0f)" % Const.dish_radius(int(Const.Mode.TRIO), 0.0))

	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.PLAYING, "birinci raund başladı")

	# Komanda 1-i qırırıq → raund komanda 0-a gedir.
	for gid in world.sim.germs.keys():
		if world.sim.germs[gid].team == 1:
			world.sim.germs[gid].balls = 0
	world.tick(Const.TICK_DELTA)
	world.tick(Const.TICK_DELTA)

	_check(world.round_wins.size() >= 2 and world.round_wins[0] == 1,
		"raundu udan komandaya xal yazılır (%s)" % str(world.round_wins))
	_check(world.phase == Const.Phase.COUNTDOWN,
		"matç bitmir, yeni raund başlayır (faza=%d)" % world.phase)
	_check(world.sim.germs.size() == Const.TRIO_GERMS,
		"yeni raundda hamı diridir (%d)" % world.sim.germs.size())

	# İkinci raundu da eyni komanda udur → MATÇ bitir.
	for i in steps:
		world.tick(Const.TICK_DELTA)
	for gid in world.sim.germs.keys():
		if world.sim.germs[gid].team == 1:
			world.sim.germs[gid].balls = 0
	world.tick(Const.TICK_DELTA)
	world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.OVER,
		"iki raund udan matçı udur (faza=%d, hesab=%s)" % [world.phase, str(world.round_wins)])


## Matçın son sıralaması liderlər cədvəli ilə EYNİ meyara görə işləyir.
##
## Əvvəl cədvəl partlatma sayına, son sıralama isə TOP sayına baxırdı. Oyunçu
## bütün matç boyu cədvəlin birincisi ola, vaxt bitəndə isə dördüncü çıxa
## bilərdi — ekranla nəticə bir-birini təkzib edirdi. Üstəlik çox top saxlamaq
## bacarıq deyil: dolu mikrob partlamağa yaxın olan mikrobdur.
static func _test_ranking_matches_board() -> void:
	var world := World.new(33, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)

	# A: ÇOX partlatma, AZ top. B: sıfır partlatma, ÇOX top.
	var ids := world.sim.germs.keys()
	var b_id: int = A_ID
	for gid in ids:
		if gid != A_ID:
			b_id = gid
			break
	for gid in ids:
		var g: Sim.GermState = world.sim.germs[gid]
		g.pops = 0
		g.balls = Const.MIN_BALLS + 1
	world.sim.germs[A_ID].pops = 5
	world.sim.germs[A_ID].balls = Const.MIN_BALLS + 1
	world.sim.germs[b_id].pops = 0
	world.sim.germs[b_id].balls = world.sim.germs[b_id].capacity - 1

	world.match_t = Const.MATCH_MAX
	world.tick(Const.TICK_DELTA)

	_check(int(world.places.get(A_ID, 0)) == 1,
		"çox PARTLADAN birinci olur (A=%d, B=%d)" % [
			int(world.places.get(A_ID, 0)), int(world.places.get(b_id, 0))])
	_check(int(world.places.get(b_id, 0)) > 1,
		"çox TOP saxlamaq birincilik vermir (B=%d)" % int(world.places.get(b_id, 0)))


## Super emaldan sonra SIFIRLANIR — saxlanan giriş onu təkrar işə salmır.
##
## Giriş `unreliable_ordered` gedir: paket itsə, server sonuncu saxlanan girişi
## təkrar oxuyur. Atəş üçün bu bilinirdi və sıfırlanırdı, super isə unudulmuşdu
## — oyunçu basmadan super yenidən işə düşürdü, kirpiklidə üstəlik iki top
## xərcləyərək.
static func _test_super_consumed_once() -> void:
	var world := World.new(31)
	var g := world.sim.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	g.species = Const.Species.AMOEBA      # kist top xərcləmir, sayğac təmiz qalır
	g.charge = Const.SUPER_MAX

	world.accept_input(A_ID, Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, false, true).to_array())
	world.tick(Const.TICK_DELTA)
	var first := 0
	for e in world.sim.events:
		if String(e.get("t", "")) == "super":
			first += 1
	_check(first == 1, "super bir dəfə işə düşdü (%d)" % first)

	# YENİ giriş göndərilmir — server köhnəni saxlayır. Super TƏKRARLANMAMALIDIR.
	world.sim.germs[A_ID].charge = Const.SUPER_MAX
	world.sim.germs[A_ID].super_t = 0.0
	var again := 0
	for i in 30:
		world.tick(Const.TICK_DELTA)
		for e in world.sim.events:
			if String(e.get("t", "")) == "super":
				again += 1
	_check(again == 0, "saxlanan giriş superi TƏKRAR işə salmır (%d)" % again)


## Matç bitəndən sonra dünya DONUR.
##
## Yoxsa nəticə ekranının arxasında botlar döyüşməyə və yer dəyişməyə davam
## edir: oyunçu bitmiş matçın davam etdiyini görür.
static func _test_world_frozen_after_over() -> void:
	var world := World.new(32, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)
	world.match_t = Const.MATCH_MAX
	world.tick(Const.TICK_DELTA)
	_check(world.phase == Const.Phase.OVER, "matç bitdi (faza=%d)" % world.phase)

	var before := {}
	for gid in world.sim.germs:
		before[gid] = world.sim.germs[gid].pos
	for i in 60:
		world.tick(Const.TICK_DELTA)

	var moved := 0
	for gid in before:
		if not world.sim.germs.has(gid):
			moved += 1
		elif world.sim.germs[gid].pos.distance_to(before[gid]) > 0.01:
			moved += 1
	_check(moved == 0, "OVER fazasında heç bir mikrob tərpənmir (%d tərpəndi)" % moved)


## Reyestr id DƏYİŞƏNDƏ də yenilənir, təkcə say dəyişəndə yox.
##
## [method Sim.rekey_germ] mikrobu silib yenidən əlavə edir: id dəyişir, say
## qalır. Yenidən qoşulma məhz bunu edir. Say yoxlaması ilə qayıdan oyunçu
## bütün digər ekranlarda ADSIZ və 0 rəngli qalırdı — özü isə heç nə görmürdü,
## ona görə səhv oyunçudan gizli idi.
static func _test_roster_tracks_ids() -> void:
	var world := World.new(21)
	world.add_player(A_ID, "A")
	world._build_frame()
	var before := world.roster_rev

	# Say DƏYİŞMİR, yalnız id dəyişir — köhnə yoxlama bunu görmürdü.
	var n := world.sim.germs.size()
	world.sim.rekey_germ(A_ID, A_ID + 7777)
	world._build_frame()
	_check(world.sim.germs.size() == n, "rekey sayı dəyişmir (%d)" % world.sim.germs.size())
	_check(world.roster_rev != before,
		"id dəyişəndə reyestr yenilənir (%d → %d)" % [before, world.roster_rev])

	var table := world.roster()
	_check(table.has(A_ID + 7777) and String(table[A_ID + 7777][0]) == "A",
		"yeni id reyestrdə düzgün adla var")


## Eyni tick-də bir neçə mikrob partlasa yerlər TƏKRARLANMIR.
##
## Sayğac geri getsəydi, üç mikrob eyni anda öləndə onlar 6, 5, 4 yerlərini
## alardı — halbuki 5 və 4 sonra sağ qalanlara veriləcək və iki oyunçu eyni
## "N-ci YER"-i görərdi. Quruma fazasında toplu ölüm adi haldır.
static func _test_places_unique() -> void:
	var world := World.new(22, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)

	# Üç botu EYNİ tick-də acından öldürürük.
	var killed := 0
	for gid in world.sim.germs.keys():
		if gid == A_ID or killed >= 3:
			continue
		world.sim.germs[gid].balls = 0
		killed += 1
	world.tick(Const.TICK_DELTA)

	# Matçı bitiririk ki, SAĞ QALANLAR da yer alsın.
	#
	# Toqquşma məhz burada olur: ölənlər geri sayılsaydı (8, 7, 6), sağ qalanlar
	# isə 1..7 alsaydı, 7 və 6 İKİ dəfə paylanardı. Yalnız ölənlərə baxan test
	# bunu görmür — onların arasında təkrar yoxdur.
	world.match_t = Const.MATCH_MAX
	world.tick(Const.TICK_DELTA)

	var seen := {}
	var dup := ""
	for gid in world.places:
		var p: int = world.places[gid]
		if seen.has(p):
			dup += " %d" % p
		seen[p] = true

	_check(dup.is_empty(),
		"yerlər təkrarlanmır (%d yer, təkrar:%s)" % [
			world.places.size(), dup if not dup.is_empty() else " yox"])
	_check(world.places.size() == Const.WORLD_CAPACITY and seen.size() == Const.WORLD_CAPACITY,
		"yerlər 1..%d aralığını tam doldurur (%d fərqli)" % [
			Const.WORLD_CAPACITY, seen.size()])


## Snapshot ENet-in MTU-suna SIĞIR.
##
## Sığmayan paket parçalanır, snapshot isə `unreliable_ordered` ilə gedir —
## yəni bir parçanın itməsi BÜTÜN snapshot-u itirir. Ölçülüb: format
## daraldılmazdan əvvəl ən pis hal 2224 bayt idi.
##
## Ən böyük tutum ən pis haldır: görüş sahəsi tutumla böyüyür, yəni iri
## mikrob daha çox qida və daha çox rəqib görür.
## ƏN PİS HAL süni qurulur — təsadüfə buraxılmır.
##
## Əvvəl test sadəcə oynanan dünyanı ölçürdü və nəticə hər çalışmada dəyişirdi:
## 13 çalışmadan birində 1420 bayt çıxırdı, qalanlarında sığırdı. Belə test
## regresiyanı gizlədir — "keçdi" heç nə sübut etmir.
##
## İndi hər sahə hədlənə qədər doldurulur: maksimum tutum (ən geniş görüş
## sahəsi), tam əhali, hədddən çox top, qida və hadisə. Nəticə həqiqi YUXARI
## HƏDDİR, ona görə keçirsə həmişə keçir.
static func _test_snapshot_worst_case() -> void:
	var world := World.new(79, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)

	var me: Sim.GermState = world.sim.germs[A_ID]
	me.capacity = Const.MAX_CAPACITY
	me.pos = Vector2.ZERO
	# Bütün mikroblar görüş sahəsinin İÇİNDƏ — heç biri süzülüb atılmasın.
	for gid in world.sim.germs:
		var g: Sim.GermState = world.sim.germs[gid]
		g.pos = Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		g.name = "MMMMMMMMMMMM"   # uzun ad: reyestrdə yox, amma cədvəldə id gedir

	# Hədddən ÇOX top, qida və hadisə: kəsmə işləməsə paket şişəcək.
	world.sim.shots.clear()
	for i in Const.SHOT_SEND_MAX * 3:
		var s := Sim.ShotState.new()
		s.id = 10000 + i
		s.owner_id = A_ID
		s.color = i % 8
		s.pos = Vector2(randf_range(-80.0, 80.0), randf_range(-80.0, 80.0))
		s.dir = Vector2.RIGHT
		world.sim.shots.append(s)

	world.sim.food.clear()
	for i in Const.FOOD_SEND_MAX * 4:
		var f := Sim.FoodState.new()
		f.id = 20000 + i
		f.pos = Vector2(randf_range(-100.0, 100.0), randf_range(-100.0, 100.0))
		world.sim.food.append(f)

	world.sim.events.clear()
	for i in Const.EVENT_SEND_MAX * 3:
		world.sim.events.append({
			"t": "hit", "pos": Vector2(float(i), 0.0), "arg": 1.0, "color": 0})

	world._build_frame()
	var snap := world.snapshot_for(A_ID)
	var size := var_to_bytes(snap).size()
	var ok := size < Const.MTU_SAFE
	_check(ok, "ƏN PİS snapshot MTU-ya sığır: %d bayt (hədd %d)" % [size, Const.MTU_SAFE])
	if not ok:
		var nm := ["TICK", "GERMS", "SHOTS", "FOOD", "EVENTS",
			"BOARD", "POP", "WALLS", "MATCH", "SELF"]
		var parts := PackedStringArray()
		for i in snap.size():
			parts.append("%s=%d" % [nm[i], var_to_bytes(snap[i]).size()])
		print("         %s · mikrob=%d" % [" ".join(parts), world.sim.germs.size()])


static func _test_snapshot_fits_mtu() -> void:
	for cap in [Const.START_CAPACITY, 35, Const.MAX_CAPACITY]:
		var world := World.new(78, Const.Mode.SOLO)
		world.add_player(A_ID, "A")
		world.tick(Const.TICK_DELTA)
		var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
		for i in steps:
			world.tick(Const.TICK_DELTA)
		# Mikrob DİRİ saxlanılır: idarə olunmadığı üçün acından partlayardı və
		# test o halı atlayaraq hər dəfə fərqli sayda yoxlama edərdi. Sabit say
		# olmasa, "207 keçdi" ilə "205 keçdi" arasındakı fərqin regresiya olub
		# olmadığını demək mümkün deyil.
		for i in 600:
			var g: Sim.GermState = world.sim.germs.get(A_ID)
			if g == null:
				break
			g.capacity = int(cap)
			# Həm aclıqdan, həm də botların atəşindən qorunur: ölçülən şey
			# snapshot-un ÖLÇÜSÜDÜR, mikrobun sağ qalma bacarığı deyil.
			g.balls = clampi(g.balls, Const.MIN_BALLS + 2, int(cap) - 2)
			g.safe_t = 999.0
			world.tick(Const.TICK_DELTA)

		_check(world.sim.germs.has(A_ID),
			"MTU ölçüsü üçün mikrob diri qaldı (tutum %d)" % cap)
		if not world.sim.germs.has(A_ID):
			continue
		world.sim.germs[A_ID].capacity = int(cap)
		var size := var_to_bytes(world.snapshot_for(A_ID)).size()
		var ok := size < Const.MTU_SAFE
		_check(ok, "snapshot MTU-ya sığır: tutum %d → %d bayt (hədd %d)" % [
				cap, size, Const.MTU_SAFE])
		if not ok:
			# Uğursuzluqda hansı sahənin şişdiyini göstərir — MTU səhvini
			# tapmağın yeganə praktik yolu budur.
			var snap := world.snapshot_for(A_ID)
			var nm := ["TICK", "GERMS", "SHOTS", "FOOD", "EVENTS",
				"BOARD", "POP", "WALLS", "MATCH", "SELF"]
			var parts := PackedStringArray()
			for i in snap.size():
				parts.append("%s=%d" % [nm[i], var_to_bytes(snap[i]).size()])
			print("         %s · mikrob=%d top=%d" % [
				" ".join(parts), world.sim.germs.size(), world.sim.shots.size()])


## Vaxt limiti ilə bitən matç SAĞ qalanları partlamış saymır.
##
## Nəticə ekranı partladanın adı boş olanda "Acından partladın" yazır. Sağ
## qalanın da adı boşdur, ona görə `survived` bayrağı olmasaydı, matçı sağ
## bitirən oyunçu ekranda öz ölümünü oxuyardı — həm də 7/10 topla.
static func _test_timeout_survivors() -> void:
	var world := World.new(11, Const.Mode.SOLO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)

	# Vaxtı süni olaraq limitə çatdırırıq — botların oynamasını gözləmirik.
	world.match_t = Const.MATCH_MAX
	world.tick(Const.TICK_DELTA)

	_check(world.phase == Const.Phase.OVER,
		"vaxt limiti matçı bitirir (faza=%d)" % world.phase)
	_check(world.timed_out, "vaxt limiti `timed_out` qoyur")

	var mine := {}
	for r in world.pending_results:
		if int(r["id"]) == A_ID:
			mine = r
	_check(not mine.is_empty() and bool(mine["survived"]),
		"sağ qalan `survived` bayrağı ilə işarələnir")
	_check(not mine.is_empty() and bool(mine["timed_out"]),
		"nəticədə `timed_out` ötürülür")

	# Sonuncu qalma vaxt limitindən ÜSTÜNDÜR: hər iki şərt eyni tick-də ödənsə,
	# matç "sonuncu qaldı" sayılmalıdır, yoxsa qalibə yanlış cümlə çıxar.
	var w2 := World.new(12, Const.Mode.SOLO)
	w2.add_player(A_ID, "A")
	w2.tick(Const.TICK_DELTA)
	for i in steps:
		w2.tick(Const.TICK_DELTA)
	for gid in w2.sim.germs.keys():
		if gid != A_ID:
			w2.sim.germs[gid].balls = 0
	w2.match_t = Const.MATCH_MAX
	w2.tick(Const.TICK_DELTA)
	w2.tick(Const.TICK_DELTA)
	_check(not w2.timed_out,
		"sonuncu qalma vaxt limitindən üstündür (timed_out=%s)" % w2.timed_out)


## Spor tutum verir və şəbəkəyə sahə əlavə etmir.
static func _test_spore() -> void:
	var s := Sim.new()
	var g := s.add_germ(A_ID, "A", 0)
	g.safe_t = 0.0
	g.pos = Vector2.ZERO
	var cap := g.capacity

	s._drop_spore()
	_check(s.food.size() == 1 and s.food[0].id < 0,
		"spor MƏNFİ id ilə işarələnir (id=%d)" % s.food[0].id)

	s.food[0].pos = g.pos
	s._step_food(Const.TICK_DELTA)
	_check(g.capacity == cap + Const.SPORE_CAPACITY,
		"spor tutum verir (%d → %d)" % [cap, g.capacity])

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
	for e in Const.unpack_germs(world.snapshot_for(A_ID)[Const.Snap.GERMS]):
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
	var seen := 0
	for i in int((span + GermVisual.EJECT_SNAP) / dt) + 20:
		g._process(dt)
		clock += dt
		var s := g._strain(ring)
		peak = maxf(peak, s[0].length() / r)
		# 90° yan — qabarmanın yayılıb-yayılmadığını göstərir.
		side = maxf(side, absf(s[n / 4].length() / r - 1.0))
		if absf(g._eject_strain()) >= 0.35:
			seen += 1
		if breaks[0] > 0 and broke_at < 0.0:
			broke_at = clock

	_check(peak > 1.18,
		"atəşdə gövdə çıxış nöqtəsində qabarır (radiusun %.0f%%-i qədər)"
			% [(peak - 1.0) * 100.0])
	_check(side < 0.03,
		"qabarma yerlidir — yan tərəf toxunulmaz qalır (%.1f%%)" % [side * 100.0])
	# ── Effekt GÖRÜNƏCƏK qədər uzun olmalıdır ───────────────────────────────
	# Yalnız zirvəni ölçmək kifayət deyildi: zirvə cəmi İKİ kadr sürürdü və
	# real oyun ölçüsündə effekt ümumiyyətlə seçilmirdi. Topun yol vaxtı
	# qısadır (67 ms) və uzadıla bilməz, ona görə oxunuşu buraxılışdan sonrakı
	# geri çırpılma daşıyır (bax [constant GermVisual.EJECT_SNAP]).
	_check(seen >= 8,
		"effekt görünəcək qədər uzundur (%d kadr, %.0f ms)" % [seen, float(seen) / 60.0 * 1000.0])
	var rest := g._strain(ring)
	_check(absf(rest[0].length() / r - 1.0) < 0.005,
		"effekt bitəndə forma bərpa olunur (%.2f%% fərq)"
			% [absf(rest[0].length() / r - 1.0) * 100.0])
	_check(breaks[0] == 1, "pərdə bir dəfə yarılır (%d siqnal)" % breaks[0])
	_check(absf(broke_at - span) < 0.035,
		"yarılma anı topun yol vaxtına uyğundur (%.0f ms, gözlənilən %.0f ms)"
			% [broke_at * 1000.0, span * 1000.0])
	g.free()

	# ── Effekt HƏQİQİ gövdələrdə də görünməlidir ────────────────────────────
	# Dairə üzərində ölçmək effektin özünü sübut edir, amma gövdənin öz forması
	# onu udabilər. Amöb ən çətin haldır: gövdə onsuz da getdiyi ox boyunca
	# dartılıb, yəni eyni istiqamətdəki qabarma silinib gedə bilər.
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		_check_eject_on_body(kind)


static func _check_eject_on_body(kind: Const.Species) -> void:
	var g := GermVisual.new()
	g.setup(0, "Atıcı", true, kind)
	var cap := Const.START_CAPACITY
	var r := Const.germ_radius(cap)
	var dt := 1.0 / 60.0
	var speed := Const.germ_speed(cap)
	var pos := Vector2.ZERO
	# Hərəkətdə olsun: amöbin gövdəsi yalnız gedəndə uzanır.
	for i in 90:
		pos += Vector2.RIGHT * speed * dt
		g.apply(pos, 0.0, 6, cap, false, true)
		g._track_motion(dt)
		if kind == Const.Species.AMOEBA:
			g._crawl(dt)
		elif kind == Const.Species.HELIOZOAN:
			g._walk(dt)

	var calm := g._body_ring(r)
	# HƏR İKİ ölçü eyni mərkəzdən götürülür. Hər konturun öz mərkəzini
	# işlətmək səhv idi: itələmə kütlə mərkəzini də önə aparır və artım
	# olduğundan az görünürdü.
	var mid := _polygon_centre(calm)
	var reach_calm := _extent_along(calm, mid, Vector2.RIGHT)

	# Atəş getdiyi İSTİQAMƏTƏ — ən çətin hal.
	g.eject(0.0)
	for i in 8:
		g._process(dt)
	var pushed := g._body_ring(r)
	var reach_push := _extent_along(pushed, mid, Vector2.RIGHT)

	var gain := reach_push / maxf(reach_calm, 0.001) - 1.0
	_check(gain > 0.20,
		"%s: atəşdə çıxış nöqtəsi gövdədən kənara çıxır (+%.0f%%)"
			% [_species_name(kind), gain * 100.0])
	g.free()


## Konturun verilən istiqamətdəki ən uzaq nöqtəsi — VERİLƏN mərkəzdən ölçülür.
static func _extent_along(ring: PackedVector2Array, mid: Vector2, dir: Vector2) -> float:
	var best := -INF
	for p in ring:
		best = maxf(best, (p - mid).dot(dir))
	return best


static func _species_name(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "ayaqlı"
		Const.Species.AMOEBA:
			return "amöb"
		_:
			return "kirpikli"


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
	var wide_sum := 0.0
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
		# ── "Enli baş, nazik quyruq" necə ölçülür ───────────────────────
		# İki cəhd səhv çıxdı və hər ikisi eyni səbəbdən — ÖLÇÜ uzunluğa
		# qarışırdı:
		#   1. Zolağın ən enli yeri: konusda hər iki zolağın ən enli nöqtəsi
		#      gövdənin ortasına düşür, iki rəqəm bərabər çıxır.
		#   2. Ümumi uzunluğun sabit faizində en: burun uzananda `half`
		#      böyüyür və nümunə nöqtəsi burnun daralan yerinə sürüşür,
		#      yəni konus GÜCLƏNDİKCƏ rəqəm PİSLƏŞİR.
		#
		# Ona görə ön və arxa AYRI-AYRI normallaşdırılır: hər tərəf öz
		# uzunluğunun yarısında ölçülür. Belə olanda rəqəm yalnız ENİ
		# göstərir, uzunluğu yox.
		var mid_pt := _polygon_centre(body)
		var fore_len := 0.0
		var aft_len := 0.0
		for p in body:
			fore_len = maxf(fore_len, p.x - mid_pt.x)
			aft_len = maxf(aft_len, mid_pt.x - p.x)
		var half := maxf(fore_len, aft_len)
		var widest := 0.0
		var widest_x := 0.0
		for p in body:
			if absf(p.y - mid_pt.y) > widest:
				widest = absf(p.y - mid_pt.y)
				widest_x = p.x - mid_pt.x
		if half > 0.001:
			wide_sum += widest_x / half
		# Ön və arxa EYNİ MÜTLƏQ məsafədə ölçülür. Hər tərəfi öz uzunluğuna
		# görə normallaşdırmaq da səhv idi: konus güclənəndə burun uzanır,
		# nümunə nöqtəsi daralan yerə sürüşür və rəqəm ƏKSİNƏ hərəkət edir
		# (ölçüldü: CONE 0.22 → 0.60 nisbəti 1.07-dən 1.01-ə saldı).
		var reach := minf(fore_len, aft_len) * 0.60
		front_sum += _width_at(body, mid_pt, reach)
		back_sum += _width_at(body, mid_pt, -reach)
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
	var wide_avg := wide_sum / float(steps)
	var cone := front_sum / maxf(back_sum, 0.001)
	# ── "Enli baş, nazik quyruq" ────────────────────────────────────────────
	# Bu yoxlama uzun müddət YOX idi: forma xassəni daşımırdı və uydurma hədd
	# qoyub "keçdi" yazmaqdansa boşluq açıq saxlanılırdı. İndi forma onu
	# daşıyır (bax [constant GermVisual.CRAWL_CONE]), ona görə hədd real
	# ölçmədən götürülüb: nisbət 1.39-1.42, ən enli kəsik +6-8%.
	_check(wide_avg > 0.04,
		"%s amöb: ən enli kəsik ÖNDƏDİR (mərkəzdən %+.0f%%)"
			% [label, wide_avg * 100.0])
	_check(cone > 1.20,
		"%s amöb: baş quyruqdan enlidir (ön/arxa %.0f / %.0f px = %.2f)"
			% [label, front_sum / float(steps), back_sum / float(steps), cone])
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


## Gövdənin verilmiş uzununa mövqedəki ENİ — dəqiq, zolaqsız.
##
## Zolaq içində `max |y|` götürmək YARAMIR və bu səhv iki dəfə edildi:
## maksimum həmişə zolağın MƏRKƏZƏ ƏN YAXIN kənarına düşür, ona görə ön və
## arxa ölçü hər ikisi gövdənin ortasını göstərir və konus görünmür. Rəqəm
## hər dəfə 1.00-ə yaxın çıxırdı, forma isə dəyişirdi.
##
## Doğru yol: şaquli xətti kəsən KƏNARLARI tapıb kəsişməni interpolyasiya
## etmək. Nəticə həmin nöqtədəki həqiqi endir, təxmin deyil.
static func _width_at(body: PackedVector2Array, mid: Vector2,
		x_off: float) -> float:
	var x := mid.x + x_off
	var lo := INF
	var hi := -INF
	var n := body.size()
	for i in n:
		var a := body[i]
		var b := body[(i + 1) % n]
		# Kənar şaquli xətti kəsirmi? (uclar xəttin əks tərəflərindədir)
		if (a.x - x) * (b.x - x) > 0.0 or absf(b.x - a.x) < 0.0001:
			continue
		var y := a.y + (b.y - a.y) * (x - a.x) / (b.x - a.x)
		lo = minf(lo, y)
		hi = maxf(hi, y)
	return (hi - lo) if hi > lo else 0.0
