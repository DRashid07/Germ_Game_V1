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
	_test_duo_revive_disconnect()
	_test_duo_revive_cancel_result()
	_test_super_survives_packet_pileup()
	_test_super_timer_survives_reconcile()
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
	_test_minigun_no_shield()
	_test_minigun_fires()
	_test_net_pulls_food()
	_test_shot_injects()
	_test_overfill_bursts()
	_test_starvation_bursts()
	_test_fire_floor()
	_test_no_self_hit()
	_test_shot_starts_inside()
	_test_obstacle_blocks_shot()
	_test_input_view_tick()
	_test_lag_comp_rewinds()
	_test_lag_comp_capped()
	_test_lag_comp_survives_pileup()
	_test_prediction_matches_sim()
	_test_prediction_hits_target()
	_test_hit_ellipse()
	_test_hit_shape_even_width()
	_test_hit_chance_even()
	_test_body_fits_hit_shape()
	_test_input_shot_bit()
	_test_merged_fire_keeps_aim()
	_test_predicted_fire_waits()
	_test_trichocyst_waits_for_rewind()
	_test_bot_sees_rewound_shot()
	_test_prediction_blast()
	_test_rewound_safe()
	_test_world_seed_repeats()
	_test_prediction_separates()
	_test_prediction_edge_bounce()
	_test_prediction_tick_targets()
	_test_shot_inside_start_hits()
	_test_hit_event_victim()
	_test_roster_marks_bots()
	_test_shot_life_in_snapshot()
	_test_event_budget_keeps_hits()
	_test_prediction_claims()
	_test_prediction_catch_up()
	_test_prediction_aligns_to_server()
	_test_self_claim_shooter()
	_test_self_claim_undo()
	_test_prediction_life_matches_server()
	_test_early_server_hit()
	_test_bot_shot_aimed()
	_test_shot_release()
	_test_own_soft_hit()
	_test_germ_promise()
	_test_germ_hitstop()
	_test_settings_device_defaults()
	_test_quality_tiers()
	_test_render_scale_native()
	_test_perf_governor()
	_test_resolution_verdict()
	_test_resolution_converges()
	_test_web_dpr_limits()
	_test_germ_shape_reuse()
	_test_germ_redraw_rate()
	_test_batch_draw()
	_test_frame_cap()
	_test_germ_gpu_contract()
	_test_germ_gpu_rows()
	_test_germ_gpu_shape_sync()
	_test_germ_gpu_mesh()
	_test_germ_gpu_fans()
	_test_water_motes_gpu()
	_test_water_motes_cpu()
	_test_super_fx_gpu()
	_test_map_layouts()
	_test_arena_core_is_free()
	_test_bush_hides()
	_test_brittle_breaks()
	_test_vent_pushes()
	_test_blob_textures()
	_test_map_atlas()
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
	_test_auto_aim()
	_test_aim_path()
	_test_germ_species()
	_test_heliozoan_gait()
	_test_amoeba_crawl()
	_test_eject_strain()
	_test_late_inputs_replayed()
	_test_guess_counter_resets()
	_test_guess_debt_clears_under_jitter()
	_test_round_reset_forgets_replay()
	_test_render_clock_stall()
	_test_render_clock_shift()
	_test_replay_keeps_pushes()
	# Dostluq və komanda — ayrıca faylda, amma eyni sayğacla (bax [SocialTest]).
	SocialTest.run()
	print("===== %d keçdi, %d uğursuz =====\n" % [_pass, _fail])
	return _fail






## Hər maneə atlasda MÖVCUD hüceyrə alır — və eyni maneə həmişə eynisini alır.
##
## Səhv olsaydı oyun XƏTA VERMİRDİ: hüceyrə yoxdursa sprite boş qalır, yəni
## maneə sadəcə GÖRÜNMÜR. Oyunçu isə görünməyən divara dəyir.
static func _test_blob_textures() -> void:
	var cells := MapKit.cells()
	_check(not cells.is_empty(), "xəritə atlasının manifesti açılır")
	var keep := DishMap.layout
	for which in 3:
		DishMap.layout = which
		var bad := 0
		var unstable := 0
		for o in DishMap.obstacles():
			var name := MapKit.cell_name(MapKit.base_name(o), o.z)
			if not cells.has(name):
				bad += 1
			# Seçim MÖVQEDƏN çıxır: iki çağırış eyni cavabı verməlidir,
			# yoxsa xəritə hər açılışda başqa cür görünər.
			if MapKit.cell_name(MapKit.base_name(o), o.z) != name:
				unstable += 1
		_check(bad == 0, "%s: hər maneənin atlasda hüceyrəsi var (%d naməlum)"
			% [DishMap.layout_name(which), bad])
		_check(unstable == 0, "%s: hüceyrə seçimi sabitdir" % DishMap.layout_name(which))
	DishMap.layout = keep

	# Hər növün HƏR İKİ ölçü sinfində hüceyrəsi var: L böyük, S kiçik (R ≤ 60)
	# maneələr üçündür — kövrəyin üç mərhələsi və qırıntısı, kolun tacı,
	# cərəyanın burulğanı, bərk növlərin kölgəsi də (critique §5).
	var missing := []
	for base in ["mucus_blob", "mucus_bloom", "brittle_s0", "brittle_s1", "brittle_s2",
			"brittle_rubble", "bush_base", "bush_canopy", "vent_base", "vent_swirl", "shadow"]:
		for cls in ["L", "S"]:
			if not cells.has("%s_%s" % [base, cls]):
				missing.append("%s_%s" % [base, cls])
	_check(missing.is_empty(), "hər növün L və S hüceyrəsi var %s" % [missing])
	_check(MapKit.size_class(60.0) == "S" and MapKit.size_class(61.0) == "L",
		"ölçü sinfi R 60-dan sonra dəyişir")

	# Keçilə bilən növlərin hüceyrəsi BƏRK növlərinkindən fərqli olmalıdır:
	# forma dili qaydanı deyir (bax ART_BIBLE §4).
	var solid := MapKit.base_name(Vector4(0, 0, 100, DishMap.Kind.MUCUS))
	var bush := MapKit.base_name(Vector4(0, 0, 100, DishMap.Kind.BUSH))
	var vent := MapKit.base_name(Vector4(0, 0, 100, DishMap.Kind.VENT))
	var brittle := MapKit.base_name(Vector4(0, 0, 100, DishMap.Kind.BRITTLE))
	_check(bush != solid and vent != solid and brittle != solid
			and bush != vent and bush != brittle and vent != brittle,
		"dörd növün dördü də ayrı hüceyrə ilə çəkilir")


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
	# Bu məsafə həm də client-in HESABIDIR: [method Arena._spawn_own_shot]
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


## Görünən tick YALNIZ atəşli paketdə gedir və geri eyni oxunur.
##
## Qalan 29 paket əvvəlki kimi beş ədəddir — köhnə server də, köhnə client də
## yeni formatı başa düşür (altıncı sahə yoxdursa -1 = geri sarma yoxdur).
static func _test_input_view_tick() -> void:
	var shot := Sim.PlayerInput.make(3, Vector2.RIGHT, 0.5, true, false, 41.25)
	var arr := shot.to_array()
	var back := Sim.PlayerInput.from_array(arr)
	_check(arr.size() == 6 and back.fire and is_equal_approx(back.view_tick, 41.25),
		"atəşli paket görünən tick-i daşıyır (%d sahə, tick %.2f)" % [arr.size(), back.view_tick])

	var idle := Sim.PlayerInput.make(4, Vector2.RIGHT, 0.5, false, false, 41.25)
	_check(idle.to_array().size() == 5,
		"atəşsiz paket beş sahədə qalır (%d)" % idle.to_array().size())
	_check(Sim.PlayerInput.from_array([1, 0.0, 0.0, 0.0, 1]).view_tick < 0.0,
		"köhnə formatlı paket geri sarmasız oxunur")


## Geri sarma: top rəqibin atıcının GÖRDÜYÜ yerinə qarşı yoxlanılır.
##
## Hədəf atəş anında xəttin üstündədir, sonra aşağı qaçır. Top ona çatanda
## rəqib artıq 54 px aşağıdadır — geri sarmasız top keçib gedir. Atıcı isə
## ekranında onu hələ xəttin üstündə görürdü (8 tick = 267 ms geridə) və
## dəymə sayılmalıdır. Test hər iki yolu yoxlayır: səhv yolda da düz nəticə
## çıxsaydı, test heç nə sübut etməzdi.
static func _test_lag_comp_rewinds() -> void:
	var with_rewind := _lag_comp_case(8.0)
	var without := _lag_comp_case(-1.0)
	_check(with_rewind == Const.START_BALLS + Const.SHOT_PAYLOAD,
		"geri sarma: ekranda dəyən top serverdə də dəyir (hədəf %d top)" % with_rewind)
	_check(without == Const.START_BALLS,
		"geri sarmasız eyni top qaçan hədəfdən keçir (hədəf %d top)" % without)


## Hədəf 12 tick xəttin üstündə durur (tarixçə dolsun), sonra tick-də 6 px
## aşağı qaçır. [param back] — atıcının ekranı neçə tick geridə idi (-1 = bilinmir).
static func _lag_comp_case(back: float) -> int:
	var s := Sim.new()
	s.lag_comp = true
	var a := s.add_germ(A_ID, "A", 0)
	var b := s.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	b.safe_t = 0.0
	var a_at := Vector2(-60.0, LANE_Y)
	var b_at := Vector2(100.0, LANE_Y)
	for i in 12:
		a.pos = a_at
		a.vel = Vector2.ZERO
		b.pos = b_at
		b.vel = Vector2.ZERO
		s.step({}, Const.TICK_DELTA)
	# `step` tick-i ƏVVƏLCƏ artırır, yəni atəş `tick + 1`-də doğulur.
	var view := -1.0 if back < 0.0 else float(s.tick + 1) - back
	for i in 20:
		a.pos = a_at
		a.vel = Vector2.ZERO
		b.pos = b_at + Vector2(0.0, 6.0 * float(i))
		b.vel = Vector2.ZERO
		var inputs := {}
		if i == 0:
			inputs[A_ID] = Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, view)
		s.step(inputs, Const.TICK_DELTA)
	return b.balls


## Geri sarma HƏDLƏNİR: uydurma köhnə tick serverə "keçmişə atəş" imkanı vermir.
static func _test_lag_comp_capped() -> void:
	var s := _fresh()
	s.lag_comp = true
	var a: Sim.GermState = s.germs[A_ID]
	a.balls = a.capacity             # üç atəşə bəs etsin
	# Atəş tick 1-də doğulur; tick 5 serverin hələ göndərmədiyi GƏLƏCƏKDİR.
	s.step({A_ID: Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, 5.0)},
		Const.TICK_DELTA)
	var cap := Const.REWIND_MAX * float(Const.TICK_RATE)
	_check(s.shots.size() == 1, "atəş açıldı (%d top)" % s.shots.size())
	if s.shots.is_empty():
		return
	_check(is_equal_approx(s.shots[0].rewind, 0.0),
		"gələcəyə baxan tick geri sarmır (%.2f)" % s.shots[0].rewind)

	a.cooldown = 0.0
	s.step({A_ID: Sim.PlayerInput.make(2, Vector2.ZERO, 0.0, true, false, 0.0)},
		Const.TICK_DELTA)
	a.cooldown = 0.0
	s.tick += 200
	s.step({A_ID: Sim.PlayerInput.make(3, Vector2.ZERO, 0.0, true, false, 0.0)},
		Const.TICK_DELTA)
	var last: Sim.ShotState = s.shots[s.shots.size() - 1]
	_check(is_equal_approx(last.rewind, cap),
		"çox köhnə tick %.0f tick-ə hədlənir (%.2f)" % [cap, last.rewind])

	# Bot və proqnoz: tick yoxdur — geri sarma yoxdur.
	var bots := _fresh()
	bots.lag_comp = true
	bots.step({A_ID: Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)}, Const.TICK_DELTA)
	_check(bots.shots.size() == 1 and bots.shots[0].rewind == 0.0,
		"tick-siz atəş (bot) indiki mövqeyə qarşı yoxlanılır")


## Bir tick-də iki paket gələndə görünən tick atəşlə BİRLİKDƏ köçür.
##
## Server oyunçu başına yalnız son girişi saxlayır və atəş bayrağını köhnə
## paketdən yenisinə keçirir ([method World.accept_input]). Tick köçməsəydi,
## WebSocket-in paketləri yığdığı hər tick-də geri sarma səssizcə itərdi.
static func _test_lag_comp_survives_pileup() -> void:
	var world := _quiet_world(31)
	var g := world.add_player(A_ID, "A", Const.Species.CILIATE)
	g.balls = Const.START_BALLS
	world.accept_input(A_ID,
		Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, 0.0).to_array())
	world.accept_input(A_ID,
		Sim.PlayerInput.make(2, Vector2.ZERO, 0.0, false, false, -1.0).to_array())
	world.tick(Const.TICK_DELTA)
	var mine: Array[Sim.ShotState] = []
	for s in world.sim.shots:
		if s.owner_id == A_ID:
			mine.append(s)
	_check(mine.size() == 1 and mine[0].rewind > 0.0,
		"yığılan paketlərdə atəşin tick-i itmir (geri sarma %.2f)"
			% (mine[0].rewind if not mine.is_empty() else -1.0))


## Proqnoz topu SERVERİN topu ilə eyni yerdə sıçrayır və eyni istiqamətə gedir.
##
## Client kadrla (60 Hz), server tick-lə (30 Hz) addımlayır. Kəsişmə süpürülən
## parça ilə hesablandığı üçün addım ölçüsü nəticəni dəyişməməlidir — yoxsa
## proqnozun sıçradığı yer ilə serverinki ayrılar, və sıçrayışdan sonrakı
## dəymələr də.
static func _test_prediction_matches_sim() -> void:
	var s := Sim.new()
	# Düzümdən HƏQİQİ selik ləkəsi götürülür — mərkəzdə nə olduğu düzümə görə dəyişir.
	var blob := _first_of(s, DishMap.Kind.MUCUS)
	var centre := Vector2(blob.x, blob.y)
	var out := centre.normalized() if centre.length() > 1.0 else Vector2.RIGHT
	# Ləkənin xaricindən, mərkəzdən bir az yan — maili dəymə sıçrayışı sınayır.
	var from := centre + out * (blob.z + 80.0)
	var dir := (-out).rotated(0.12)

	var shot := Sim.ShotState.new()
	shot.id = 1
	shot.owner_id = 0
	shot.pos = from
	shot.dir = dir
	shot.life = Const.SHOT_LIFETIME
	s.shots.append(shot)
	var server_hit := Vector2.INF
	var server_dir := Vector2.ZERO
	for i in 30:
		s.step({}, Const.TICK_DELTA)
		for e in s.events:
			if e.get("t") == "hit" and server_hit == Vector2.INF:
				server_hit = e["pos"]
				server_dir = s.shots[0].dir if not s.shots.is_empty() else Vector2.ZERO

	var p := ShotPrediction.new()
	p.spawn(from, dir, 0.0)
	var ghost_hit := Vector2.INF
	var ghost_dir := Vector2.ZERO
	var now := 0.0
	for i in 60:
		now += 1.0 / 60.0
		for c in p.step(1.0 / 60.0, now, s.obstacles, s.broken, []):
			if int(c["kind"]) == ShotPrediction.Contact.BOUNCE and ghost_hit == Vector2.INF:
				ghost_hit = c["pos"]
				ghost_dir = p.ghosts[0].dir

	_check(server_hit != Vector2.INF and ghost_hit != Vector2.INF,
		"server də, proqnoz da ləkədən sıçradı")
	_check(server_hit.distance_to(ghost_hit) < 0.5,
		"sıçrayış nöqtəsi eynidir (%.2f px fərq)" % server_hit.distance_to(ghost_hit))
	_check(server_dir.dot(ghost_dir) > 0.9999,
		"sıçrayışdan sonrakı istiqamət eynidir")

	# Kövrək qabıq topu UDUR — proqnoz da orada dayanır.
	var idx := -1
	for i in s.obstacles.size():
		if int(s.obstacles[i].w) == DishMap.Kind.BRITTLE:
			idx = i
			break
	if idx >= 0:
		var o := s.obstacles[idx]
		var at := Vector2(o.x, o.y)
		var cp := ShotPrediction.new()
		cp.spawn(at + at.normalized() * (o.z + 60.0), -at.normalized(), 0.0)
		var cracked := -1
		for i in 30:
			for c in cp.step(1.0 / 60.0, float(i) / 60.0, s.obstacles, s.broken, []):
				if int(c["kind"]) == ShotPrediction.Contact.CRACK:
					cracked = int(c["key"])
		_check(cracked == idx and not cp.ghosts[0].alive,
			"proqnoz kövrək qabıqda dayanır (maneə %d)" % cracked)


## Botun sənə proqnozlaşdırılmış dəyməsini yalnız HƏMİN botun HIT-i təsdiqləyir.
##
## Hadisə qurbanı demir, yalnız atanın rəngini. Əvvəl yalnız məsafə yoxlanırdı:
## yanındakı mikroba dəyən başqa botun topu proqnozu "təsdiqləyir", öz zərbəsi
## isə ekranda göstərilmirdi.
static func _test_self_claim_shooter() -> void:
	var a := Arena.new()
	a._self_claims.append({"pos": Vector2(100.0, 0.0), "t": 0.0, "color": 3})
	_check(not a._match_self_claim(Vector2(130.0, 0.0), 5),
		"başqa botun yaxındakı dəyməsi proqnozu təsdiqləmir")
	_check(a._self_claims.size() == 1, "proqnoz öz təsdiqini gözləyir")
	_check(a._match_self_claim(Vector2(130.0, 0.0), 3), "eyni botun dəyməsi təsdiqləyir")
	_check(a._self_claims.is_empty() and int(a.hit_stats["self_conf"]) == 1,
		"təsdiqlənən proqnoz siyahıdan çıxır")
	# Eyni bot ardıcıl iki top atıb — server İKİNCİNİN dəyməsini deyir.
	a._self_claims.append({"pos": Vector2(0.0, 0.0), "t": 0.0, "color": 3})
	a._self_claims.append({"pos": Vector2(60.0, 0.0), "t": 0.1, "color": 3})
	a._match_self_claim(Vector2(62.0, 0.0), 3)
	_check(a._self_claims.size() == 1 and Vector2(a._self_claims[0]["pos"]) == Vector2.ZERO,
		"təsdiq ən YAXIN proqnoza yazılır, ilkinə yox")
	a._claims.append({"pos": Vector2(0.0, 0.0), "t": 0.0, "hit": true, "vcol": 4})
	a._claims.append({"pos": Vector2(50.0, 0.0), "t": 0.1, "hit": true, "vcol": 5})
	a._match_claim(Vector2(30.0, 0.0), true, 4)
	_check(a._claims.size() == 1 and int(a._claims[0]["vcol"]) == 5,
		"öz topunun təsdiqi qurbanı da yoxlayır")
	a.free()


## Proqnoz topu serverinki ilə EYNİ yolu uçub eyni yerdə ölür.
##
## Server topu atəş tick-ində artıq bir dəfə azaldır və ömrü bitən tick-də
## hərəkətsiz silir: 65 tick. Proqnoz tam 2.2 s uçanda son 14 px-də rəqibə
## "dəyirdi", server isə topu artıq silmişdi.
static func _test_prediction_life_matches_server() -> void:
	var s := _fresh()
	s.obstacles.clear()
	for id in s.germs.keys():
		s.germs.erase(id)
	var shot := Sim.ShotState.new()
	shot.owner_id = A_ID
	shot.pos = Vector2.ZERO
	shot.dir = Vector2.RIGHT
	shot.life = Const.SHOT_LIFETIME
	s.shots.append(shot)
	var last := shot.pos
	for i in 200:
		if s.shots.is_empty():
			break
		last = s.shots[0].pos
		s._step_shots(Const.TICK_DELTA)
	var p := ShotPrediction.new()
	var g := p.spawn(Vector2.ZERO, Vector2.RIGHT, 0.0)
	g.sid = 1
	var now := 0.0
	var ghost_last := g.pos
	for i in 200:
		if not g.alive:
			break
		ghost_last = g.pos
		now += Const.TICK_DELTA
		p.step(Const.TICK_DELTA, now, [] as Array[Vector4], PackedByteArray(), [])
	_check(absf(ghost_last.x - last.x) < 1.0,
		"proqnoz topu serverinki ilə eyni yerdə ölür (%.0f / %.0f px)" % [ghost_last.x, last.x])
	# Ekran 60 kadrla addımlayır — son addım qısalır, yol yenə eynidir.
	var g60 := p.spawn(Vector2.ZERO, Vector2.RIGHT, now)
	g60.sid = 2
	for i in 400:
		if not g60.alive:
			break
		now += 1.0 / 60.0
		p.step(1.0 / 60.0, now, [] as Array[Vector4], PackedByteArray(), [])
	_check(absf(g60.pos.x - last.x) < 1.0,
		"60 kadrda da proqnoz topu eyni yerdə ölür (%.0f / %.0f px)" % [g60.pos.x, last.x])


## Öz topunun serverdəki dəyməsi proqnozdan ƏVVƏL gələ bilər — gecikən proqnoz
## onda ikinci zərbə göstərmir və "boş" sayılmır.
static func _test_early_server_hit() -> void:
	var a := Arena.new()
	a._early_hits.append({"pos": Vector2(100.0, 0.0), "t": 0.0, "victim": 4})
	_check(not a._take_early_hit(Vector2(110.0, 0.0), 5), "başqa qurbanın dəyməsi təsdiq etmir")
	_check(a._take_early_hit(Vector2(110.0, 0.0), 4) and a._early_hits.is_empty(),
		"eyni qurbanın tez gələn dəyməsi gecikən proqnozu təsdiqləyir")
	a.free()


## Sərhəddəki proqnoz serveri gözləyir; server topu göndərməyə davam edirsə, top geri qaytarılır.
##
## Yalançı "sənə dəydi"-lərin yarısı gövdədən 5–7 px kənardan keçən toplar idi:
## proqnozun bir neçə piksellik xətası sərhəddə nəticəni dəyişir.
static func _test_self_claim_undo() -> void:
	var shape := Vector3(40.0, 40.0, 0.0)
	_check(Arena._line_depth(Vector2(-100.0, 0.0), Vector2.RIGHT, Vector2.ZERO, shape) < 0.01,
		"mərkəzdən keçən xəttin dərinliyi 0-dır")
	_check(absf(Arena._line_depth(Vector2(-100.0, 38.0), Vector2.RIGHT, Vector2.ZERO, shape) - 0.95) < 0.01,
		"sərhədə yaxın xətt 0.95-dir — əmin sayılmır")
	# Topun yoluna dik qaçan mikrobun yeri daha az dəqiqdir — əmin hədd dərinləşir.
	var round_shape := Vector3(40.0, 40.0, 0.0)
	var still := Arena.self_sure_depth(Vector2.ZERO, Vector2.RIGHT, round_shape)
	var along := Arena.self_sure_depth(Vector2(150.0, 0.0), Vector2.RIGHT, round_shape)
	var across := Arena.self_sure_depth(Vector2(0.0, 150.0), Vector2.RIGHT, round_shape)
	_check(is_equal_approx(still, Arena.SELF_SURE_DEPTH) and is_equal_approx(along, Arena.SELF_SURE_DEPTH),
		"dayanan və topa tərəf gedən mikrobda əmin hədd sabitdir (%.2f)" % still)
	_check(absf(across - (1.0 - (Arena.SELF_POS_ERR + 150.0 * Arena.SELF_TIME_ERR) / 40.0)) < 0.001
		and across < 0.59,
		"topun yoluna 150 px/s dik qaçanda 0.59 dərinlik artıq əmin deyil (hədd %.2f)" % across)
	# Şəbəkə sıxılanda (gediş-gəliş ən aşağısından xeyli uzun) heç bir dəymə əmin deyil.
	var net := Arena.new()
	_check(not net._congested(), "ölçü olmayanda şəbəkə sıxılmış sayılmır")
	net._rtt_floor = 0.18
	net._rtt = 0.21
	var calm_net := not net._congested()
	net._rtt = 0.443
	_check(calm_net and net._congested(),
		"RTT 180 ms-lik şəbəkədə 210 ms adi, 443 ms sıxılmadır (ölçülən hal)")
	net.free()
	# Geri qaytarma serverin snapshot-undakı YERLƏRƏ baxır: top sənin (serverin onu
	# yoxladığı) yerinin yanından keçib uzaqlaşırsa, dəymə olmayıb. Vaxtla və ya
	# təsdiqlənən girişlə ölçü şəbəkə sıxılanda düzgün dəymələri də qaytarırdı.
	var r := Const.germ_radius(Const.START_CAPACITY)
	_check(Arena.shot_gone_past(Vector2(200.0, 0.0), Vector2.RIGHT, Vector2.ZERO, r),
		"top səndən 200 px o yana uçur — dəymə olmayıb")
	_check(not Arena.shot_gone_past(Vector2(-200.0, 0.0), Vector2.RIGHT, Vector2.ZERO, r),
		"top sənə hələ çatmayıb — gözlənilir, nə qədər gecikirsə-gecikisin")
	_check(not Arena.shot_gone_past(Vector2(20.0, 0.0), Vector2.RIGHT, Vector2.ZERO, r),
		"top gövdənin əhatəsindədir — hələ qərar yoxdur")
	var a := Arena.new()
	a.my_id = 1
	a._last_snap_t = 1.0
	var me_row := [1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	me_row[Const.GF.CAP] = Const.START_CAPACITY
	var snap := []
	snap.resize(Const.Snap.EVENTS + 1)
	snap[Const.Snap.TICK] = 100
	snap[Const.Snap.GERMS] = [me_row]
	a._snaps.append({"t": 1.0, "d": snap})
	var gone := {"node": null, "seen": 1.0, "absorbed": true, "base": Vector2(200.0, 0.0),
		"dir": Vector2.RIGHT}
	var coming := {"node": null, "seen": 1.0, "absorbed": true, "base": Vector2(-200.0, 0.0),
		"dir": Vector2.RIGHT}
	a._shot_views[5] = gone
	a._shot_views[7] = coming
	a._self_claims.append({"pos": Vector2.ZERO, "t": 0.5, "color": 1, "sid": 5, "soft": true})
	a._self_claims.append({"pos": Vector2.ZERO, "t": 0.5, "color": 1, "sid": 6, "soft": false})
	a._self_claims.append({"pos": Vector2.ZERO, "t": 0.5, "color": 1, "sid": 7, "soft": false})
	a._undo_self_claims()
	_check(not bool(gone["absorbed"]) and gone.has("no_claim"),
		"serverdə top səndən keçib gedir — geri qaytarılır və bir də proqnozlanmır")
	_check(bool(coming["absorbed"]) and a._self_claims.size() == 2
		and int(a.hit_stats["self_soft_miss"]) == 1,
		"serverdə top sənə hələ çatmayıb, serverdə itən top da — ikisi gözləyir (qalan %d)"
			% a._self_claims.size())
	a.free()


## Botun topu yalnız SƏNƏ tərəf uçanda sənin zaman xəttinə köçürülür.
##
## Yanından keçən top başqasına gedir, o başqası isə keçmişdə çəkilir: köçürülən
## top hədəfindən irəli qaçıb onun içindən zərbəsiz keçirdi (probe ilə ölçülüb).
static func _test_bot_shot_aimed() -> void:
	var a := Arena.new()
	a.me = Sim.GermState.new()
	var r := Const.germ_radius(a.me.capacity)
	_check(a._aimed_at_me(Vector2(-300.0, 0.0), Vector2.RIGHT, Vector2.ZERO), "düz sənə uçan top köçürülür")
	_check(a._aimed_at_me(Vector2(-300.0, r), Vector2.RIGHT, Vector2.ZERO),
		"gövdənin kənarına gedən top da köçürülür")
	_check(not a._aimed_at_me(Vector2(-300.0, r * 3.0 + 60.0), Vector2.RIGHT, Vector2.ZERO),
		"yanından keçən top köçürülmür")
	_check(not a._aimed_at_me(Vector2(300.0, 0.0), Vector2.RIGHT, Vector2.ZERO),
		"səndən uzaqlaşan top köçürülmür")
	a.free()


## Sərhəddəki öz dəyməsi serverin təsdiqini gözləyir.
##
## Təsdiqlənməyən öz dəymələrinin hamısı qurbanın kənarına sürtünmə idi (xətt
## ellipsin 0.99+ dərinliyindən keçirdi): atəş nöqtəsinin bir neçə piksellik
## fərqi sərhəddə nəticəni dəyişir. Dərin dəymə dərhal göstərilir.
static func _test_own_soft_hit() -> void:
	var p := ShotPrediction.new()
	var targets := [{"pos": Vector2(200.0, 0.0), "radius": 31.0, "shape": Vector3(40.0, 40.0, 0.0),
		"key": 7}]
	var deep := p.spawn(Vector2.ZERO, Vector2.RIGHT, 0.0)
	var graze := p.spawn(Vector2(0.0, 38.5), Vector2.RIGHT, 0.0)
	var depth := {}
	var near_late := {}
	var now := 0.0
	for i in 60:
		now += Const.TICK_DELTA
		for c in p.step(Const.TICK_DELTA, now, [] as Array[Vector4], PackedByteArray(), targets):
			if int(c["kind"]) == ShotPrediction.Contact.HIT:
				depth[(c["ghost"] as ShotPrediction.Ghost).id] = float(c["depth"])
				near_late[(c["ghost"] as ShotPrediction.Ghost).id] = bool(c.get("late", false))
	_check(depth.has(deep.id) and float(depth[deep.id]) < 0.01, "mərkəzdən keçən topun dərinliyi 0-dır")
	# Ömrünün sonunda dəyən top "gec"dir — atəş nöqtəsinin xətt boyu fərqi həll edir.
	var far := ShotPrediction.new()
	# Top 65 parça uçur (910 px); qurbanın kənarı sonuncu parçanın ortasındadır.
	var reach_end := Const.SHOT_SPEED * Const.TICK_DELTA * 64.5
	var end_target := [{"pos": Vector2(reach_end + 40.0, 0.0), "radius": 31.0,
		"shape": Vector3(40.0, 40.0, 0.0), "key": 9}]
	var ghost_late := far.spawn(Vector2.ZERO, Vector2.RIGHT, 0.0)
	# Server təsdiqləyib — yoxsa proqnoz 1 s sonra səssizcə dayanır (CLAIM_GRACE).
	ghost_late.sid = 1
	var late := {}
	var t_far := 0.0
	for i in 90:
		t_far += Const.TICK_DELTA
		for c in far.step(Const.TICK_DELTA, t_far, [] as Array[Vector4], PackedByteArray(), end_target):
			if int(c["kind"]) == ShotPrediction.Contact.HIT:
				late[(c["ghost"] as ShotPrediction.Ghost).id] = bool(c.get("late", false))
	_check(late.has(ghost_late.id) and bool(late[ghost_late.id])
		and near_late.has(deep.id) and not bool(near_late[deep.id]),
		"ömrünün son tick-lərində dəyən top gecdir, yaxındakı yox")
	_check(depth.has(graze.id) and float(depth[graze.id]) > Arena.OWN_SURE_DEPTH,
		"kənara sürtünən top sərhəddədir (%.2f)" % float(depth.get(graze.id, -1.0)))
	var a := Arena.new()
	var v := GermVisual.new()
	v.setup(3, "B", false, Const.Species.CILIATE)
	a._visuals[7] = {"node": v}
	a._on_own_contact({"kind": ShotPrediction.Contact.HIT, "pos": Vector2(165.0, 38.0),
		"dir": Vector2.RIGHT, "key": 7, "ghost": graze, "depth": 0.96})
	_check(a._claims.size() == 1 and bool(a._claims[0].get("soft", false))
		and int(a.hit_stats["predicted"]) == 0 and int(a.hit_stats["own_soft"]) == 1,
		"sərhəddəki dəymə göstərilmir, serveri gözləyir")
	# Server atəşi təsdiqləyib, amma geri sarmanı həddə kəsib: dərin dəymə də gözləyir.
	var capped := p.spawn(Vector2.ZERO, Vector2.RIGHT, 0.0)
	capped.sid = 44
	capped.rewind = Const.REWIND_MAX
	a._on_own_contact({"kind": ShotPrediction.Contact.HIT, "pos": Vector2(160.0, 0.0),
		"dir": Vector2.RIGHT, "key": 7, "ghost": capped, "depth": 0.2})
	_check(a._claims.size() == 2 and bool(a._claims[1].get("soft", false))
		and int(a.hit_stats["predicted"]) == 0,
		"geri sarma həddə dirənib — dərin dəymə də serveri gözləyir")
	a._claims.pop_back()
	# Qurbanın görüntüsü yoxdur — zərbənin effekti testdə çəkilmir.
	a._visuals.erase(7)
	_check(a._match_claim(Vector2(168.0, 38.0), true, 3) and int(a.hit_stats["own_soft_conf"]) == 1
		and int(a.hit_stats["confirmed"]) == 0 and a._claims.is_empty(),
		"serverin HIT-i sərhəddəki dəyməni təsdiqləyir — zərbə elə o an oynanır")
	v.free()
	a.free()


## Səndən yayınan top qabağındakı qonşunun gövdəsindən keçməsin — keçmişə qayıdır.
##
## Qonşu keçmişdə çəkilir; sənin zaman xəttində qalan top ona tez çatıb içindən
## keçirdi, serverdə isə heç kimə dəymirdi (probe ilə tutulub, RTT 120).
static func _test_shot_release() -> void:
	var a := Arena.new()
	a.me = Sim.GermState.new()
	a.my_id = 1
	var v := GermVisual.new()
	v.setup(2, "B", false, Const.Species.CILIATE)
	v.position = Vector2(200.0, 0.0)
	a._visuals[7] = {"node": v}
	var room := a._release_room(Vector2.ZERO, Vector2.RIGHT, 5)
	_check(room > 100.0 and room < 200.0, "qabaqda qonşu var — top keçmişə qayıdır (%.0f px qalıb)" % room)
	_check(a._release_room(Vector2.ZERO, Vector2.LEFT, 5) < 0.0, "qabaq boşdur — top indidə qalır")
	_check(a._release_room(Vector2.ZERO, Vector2.RIGHT, 2) < 0.0, "atanın özü maneə sayılmır")
	# Qonşu yola qəfil girir (ölçülən hal: 27 px qalmış, top 0.82 payla, zaman
	# xətləri arası 137 px). Top geri getmir və qonşuya çatmamış keçmişə düşür.
	for start_room in [27.0, 80.0, 200.0]:
		var k := 0.82
		var left: float = start_room
		var backwards := false
		var dt := 1.0 / 60.0
		while k > 0.0 and left > 0.0:
			var rate := Arena.release_rate(k, 137.0, left)
			var step := (Const.SHOT_SPEED - rate * 137.0) * dt
			backwards = backwards or step < 0.0
			k = maxf(0.0, k - rate * dt)
			left -= step
		_check(k <= 0.0 and left > -2.0 and not backwards,
			"qonşuya %.0f px qalmış: top ona çatmamış keçmişə qayıdır (qalan yol %.0f px), geri getmir"
				% [start_room, left])
	v.free()
	a.free()


## Reyestr botu DEYİR — id-dən çıxarılmır.
##
## İnsanın peer nömrəsi təsadüfi 32 bitlik ədəddir və adətən
## [constant World.BOT_ID_BASE]-dən böyükdür. Əvvəl client botu `id >= BOT_ID_BASE`
## ilə tanıyırdı: o biri oyunçunun topu bot topu sayılır, sənin zamanına
## köçürülür və yalançı "sənə dəydi" alırdı.
static func _test_roster_marks_bots() -> void:
	var world := World.new(31, Const.Mode.ENDLESS)
	var human := 1_411_290_326
	world.add_player(human, "İnsan")
	world.tick(Const.TICK_DELTA)
	var table := world.roster()
	var bots := 0
	for gid in table:
		if bool((table[gid] as Array)[2]):
			bots += 1
	_check(not bool((table[human] as Array)[2]) and bots == table.size() - 1,
		"böyük id-li insan bot sayılmır, qalanlar botdur (%d / %d)" % [bots, table.size()])
	var a := Arena.new()
	a._on_roster(table)
	_check(not a._bot_colors.has(int((table[human] as Array)[1])) and a._bot_colors.size() == bots,
		"client insanın rəngini bot rəngləri arasına qatmır")
	a.free()


## Snapshot-dakı top qalan ÖMRÜNÜ daşıyır — əlavə baytsız, istiqamətin uzunluğunda.
static func _test_shot_life_in_snapshot() -> void:
	var world := World.new(32, Const.Mode.ENDLESS)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var g: Sim.GermState = world.sim.germs[A_ID]
	var lives := [2.2, 0.7, 0.0]
	for i in lives.size():
		var shot := Sim.ShotState.new()
		shot.id = 900 + i
		shot.owner_id = A_ID
		shot.pos = g.pos + Vector2(60.0 * (i + 1), 0.0)
		shot.dir = Vector2.from_angle(0.3 * i)
		shot.life = float(lives[i])
		shot.rewind = 3.0 * i
		world.sim.shots.append(shot)
	world._build_frame()
	var rows := Const.unpack_shots(world.snapshot_for(A_ID)[Const.Snap.SHOTS])
	var ok := 0
	for row in rows:
		var i := int(row[Const.SF.ID]) - 900
		if i < 0 or i >= lives.size():
			continue
		var dir := Vector2(float(row[Const.SF.DX]), float(row[Const.SF.DY]))
		if absf(float(row[Const.SF.LIFE]) - float(lives[i])) < 0.001 \
				and absf(float(row[Const.SF.REWIND]) - 3.0 * i * Const.TICK_DELTA) < 0.0001 \
				and dir.is_equal_approx(Vector2.from_angle(0.3 * i)):
			ok += 1
	_check(ok == lives.size(),
		"ömür, geri sarma (s) və vahid istiqamət snapshot-dan açılır (%d / %d)" % [ok, lives.size()])


## Tick-i mikrobun İÇİNDƏ başlayan top da dəyir.
##
## Mikroblar toplardan əvvəl yeriyir: topa doğru gedən mikrob onun üstünə
## çıxanda topun bütün parçası gövdənin içində qalırdı və server dəyməni
## saymırdı. Ölçülüb — top gövdənin 8–29 px içindən keçib uçmağa davam edirdi.
static func _test_shot_inside_start_hits() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	var shot := Sim.ShotState.new()
	shot.owner_id = A_ID
	shot.color = a.color
	shot.pos = b.pos + Vector2(-4.0, 3.0)
	shot.dir = Vector2.RIGHT
	shot.life = 1.0
	s.shots.append(shot)
	var before := b.balls
	s._step_shots(Const.TICK_DELTA)
	_check(b.balls == before + Const.SHOT_PAYLOAD and s.shots.is_empty(),
		"gövdənin içində başlayan top dəyir (top %d → %d, qalan top %d)" % [before, b.balls, s.shots.size()])
	_check(Sim.seg_ellipse_t(b.pos, b.pos + Vector2(10.0, 0.0), b.pos,
		Sim.hit_shape(int(b.species), b.capacity, Vector2.ZERO)) < 0.0,
		"köhnə sərhəd yoxlaması içəridəki parçanı görmür — səbəb budur")


## HIT hadisəsi qurbanı da daşıyır, köhnə "mikroba dəydimi" yoxlaması dəyişmir.
static func _test_hit_event_victim() -> void:
	for c in [0, 3, 7]:
		var arg := Const.hit_arg(c)
		_check(arg > 0.5 and Const.hit_victim(arg) == c, "qurbanın rəngi %d geri oxunur" % c)
	_check(Const.hit_victim(0.0) == -1, "divardan sıçrayışın qurbanı yoxdur")
	var s := _fresh()
	var b: Sim.GermState = s.germs[B_ID]
	var shot := Sim.ShotState.new()
	shot.owner_id = A_ID
	shot.color = (s.germs[A_ID] as Sim.GermState).color
	shot.pos = b.pos + Vector2(-Const.germ_radius(b.capacity) - 20.0, 0.0)
	shot.dir = Vector2.RIGHT
	shot.life = 1.0
	s.shots.append(shot)
	s.events.clear()
	for i in 4:
		s._step_shots(Const.TICK_DELTA)
	var victim := -2
	for e in s.events:
		if e.get("t") == "hit":
			victim = Const.hit_victim(float(e["arg"]))
	_check(victim == b.color, "serverin HIT-i qurbanı deyir (%d, gözlənən %d)" % [victim, b.color])


## Büdcə sıxılanda ilk başqasının QİDA UDMASI düşür, zərbə yox.
##
## Snapshot-a 10 mikrobla tick başına ~7 hadisə sığır; seçim yalnız məsafəyə görə
## olanda yaxındakı udmalar uzaqdakı zərbəni itirirdi. Baxana dəyən top isə
## atan başqası olsa da onun ÖZ hadisəsidir.
static func _test_event_budget_keeps_hits() -> void:
	var rows := []
	for i in 8:
		var p := Vector2(10.0 + i, 0.0)
		rows.append([p, Const.EvKind.ABSORB, p.x, p.y, 0.0, 5])
	var far := Vector2(600.0, 0.0)
	rows.append([far, Const.EvKind.HIT, far.x, far.y, Const.hit_arg(6), 5])
	var mine := Vector2(700.0, 0.0)
	rows.append([mine, Const.EvKind.HIT, mine.x, mine.y, Const.hit_arg(2), 5])
	var out := World._near_flat(rows, Vector2.ZERO, 900.0 * 900.0, 3, 2)
	var kinds := []
	for i in range(0, out.size(), 5):
		kinds.append([int(out[i]), Const.hit_victim(out[i + 3]) if int(out[i]) == Const.EvKind.HIT else -1])
	_check(kinds.size() == 3 and kinds[0] == [Const.EvKind.HIT, 2] and kinds[1] == [Const.EvKind.HIT, 6],
		"sənə dəyən və uzaqdakı zərbə udmalardan öndədir: %s" % [kinds])

	# Baxanın ÖZ udmaları da sənə dəyən topu sıxışdırmır.
	var busy := []
	for i in 5:
		var p := Vector2(5.0 + i, 0.0)
		busy.append([p, Const.EvKind.ABSORB, p.x, p.y, 0.0, 2])
	busy.append([mine, Const.EvKind.HIT, mine.x, mine.y, Const.hit_arg(2), 5])
	var kept := World._near_flat(busy, Vector2.ZERO, 900.0 * 900.0, 3, 2)
	_check(int(kept[0]) == Const.EvKind.HIT and Const.hit_victim(kept[3]) == 2,
		"üç öz udmasından çoxu olan tick-də də sənə dəyən top paketdə qalır")


## Toqquşma forması görünən gövdəni izləyir — hərəkətdəki amöb ellipsdir.
##
## Amöb sürətlə sürünəndə gövdəsi sürət boyu uzanır, yanları daralır. Burnundan
## keçən top əvvəl dairəyə çatmırdı ("içindən keçdi"), yandan gələn top isə
## gövdəyə çatmamış dəyirdi. Dayanan mikrobda forma yenə dairədir.
static func _test_hit_ellipse() -> void:
	var cap := 30
	var r := Const.germ_radius(cap)
	var top := Const.germ_speed(cap)
	# [ad, topun başlanğıcı (mikroba nisbi), istiqamət, hərəkətdə dəyməli, dayananda dəyməli]
	var cases := [
		["burun", Vector2(r * 1.35, -220.0), Vector2.DOWN, true, false],
		["yan", Vector2(-220.0, r * 0.98), Vector2.RIGHT, false, true],
	]
	for c in cases:
		for moving in [true, false]:
			var sim := Sim.new()
			sim.obstacles = [] as Array[Vector4]
			var g := sim.add_germ(A_ID, "A", 0, false, Const.Species.AMOEBA)
			g.capacity = cap
			g.safe_t = 0.0
			g.pos = Vector2(0.0, 0.0)
			g.vel = Vector2(top, 0.0) if moving else Vector2.ZERO
			var shot := Sim.ShotState.new()
			shot.pos = g.pos + Vector2(c[1])
			shot.dir = Vector2(c[2])
			shot.life = Const.SHOT_LIFETIME
			sim.shots.append(shot)
			for i in 40:
				sim._step_shots(Const.TICK_DELTA)
			var hit := g.balls > Const.START_BALLS
			var want: bool = c[3] if moving else c[4]
			_check(hit == want, "amöb %s, %s: top %s" % [String(c[0]),
				"hərəkətdə" if moving else "dayanıb", "dəydi" if hit else "keçdi"])

	# Proqnoz serverlə EYNİ nöqtədə dəyir — eyni ellipslə.
	var sim2 := Sim.new()
	sim2.obstacles = [] as Array[Vector4]
	var h := sim2.add_germ(B_ID, "B", 1, false, Const.Species.AMOEBA)
	h.capacity = cap
	h.safe_t = 0.0
	h.pos = Vector2.ZERO
	h.vel = Vector2(top * 0.7, top * 0.7).limit_length(top)
	var start := Vector2(-160.0, -30.0)
	var sh := Sim.ShotState.new()
	sh.pos = start
	sh.dir = Vector2.RIGHT
	sh.life = Const.SHOT_LIFETIME
	sim2.shots.append(sh)
	var server_at := Vector2.INF
	for i in 30:
		sim2._step_shots(Const.TICK_DELTA)
		for e in sim2.events:
			if e.get("t") == "hit" and float(e["arg"]) > 0.5:
				server_at = e["pos"]
	var p := ShotPrediction.new()
	p.spawn(start, Vector2.RIGHT, 0.0)
	var target := {"pos": Vector2.ZERO, "radius": r, "key": 5,
		"shape": Sim.hit_shape(int(Const.Species.AMOEBA), cap, h.vel)}
	var ghost_at := Vector2.INF
	for i in 60:
		for ct in p.step(1.0 / 60.0, float(i) / 60.0, [] as Array[Vector4], PackedByteArray(), [target]):
			if int(ct["kind"]) == ShotPrediction.Contact.HIT:
				ghost_at = ct["pos"]
	_check(server_at.is_finite() and ghost_at.is_finite() and server_at.distance_to(ghost_at) < 1.0,
		"proqnoz serverlə eyni ellips nöqtəsində dəyir (%.2f px)" % (server_at.distance_to(ghost_at)
			if server_at.is_finite() and ghost_at.is_finite() else -1.0))


## Toqquşma ellipsinin ORTA ENİ dayanan mikrobun dairəsinə bərabərdir — hər
## növ, tutum və sürətdə.
##
## Balansın özü budur: top hər tərəfdən gəlir, dəymə ehtimalı isə formanın topun
## yoluna dik enindən asılıdır. Köhnə ellipsdə (topun radiusu sadəcə əlavə
## olunurdu) amöbün orta eni 8–10% böyük idi — hərəkətdəki amöb asan vurulurdu,
## çox ölür və superini az işlədirdi (bax [method Sim.hit_shape]).
static func _test_hit_shape_even_width() -> void:
	var worst := 0.0
	var reach_ok := true
	var circle_ok := true
	for sp in [0, 1, 2]:
		for cap in [10, 20, 35, 60]:
			var r := Const.germ_radius(cap)
			var top := Const.germ_speed(cap)
			for k in [0.0, 0.25, 0.5, 0.75, 1.0, 1.5]:
				var shape := Sim.hit_shape(sp, cap, Vector2(top * float(k), 0.0).rotated(0.7))
				var mean := Sim.ellipse_perimeter(shape.x, shape.y) / PI
				worst = maxf(worst, absf(mean / (2.0 * (r + Const.SHOT_RADIUS)) - 1.0))
				if maxf(shape.x, shape.y) > Sim.hit_reach(cap):
					reach_ok = false
				if float(k) == 0.0 and not (is_equal_approx(shape.x, r + Const.SHOT_RADIUS)
						and is_equal_approx(shape.y, r + Const.SHOT_RADIUS)):
					circle_ok = false
	_check(worst < 0.001, "toqquşma formasının orta eni dairəninkidir (ən böyük fərq %.4f%%)"
		% (worst * 100.0))
	_check(reach_ok, "forma heç vaxt ucuz süzgəcin radiusundan çıxmır (bax Sim.hit_reach)")
	_check(circle_ok, "dayanan mikrobun forması dairədir: r + topun radiusu")


## Vurulma EHTİMALI hərəkətdə də dayanandakı ilə eynidir — həqiqi kəsişmə
## funksiyası ilə, hər tərəfdən gələn xətlərlə (Monte-Karlo, sabit toxum).
##
## Orta en nəzəriyyədir; bu test onu oyunun öz toqquşma kodu ilə yoxlayır.
## Köhnə ellipsdə amöb üçün nisbət ~1.08 çıxırdı.
static func _test_hit_chance_even() -> void:
	const NAMES := ["kirpikli", "ayaqlı", "amöb"]
	var rng := RandomNumberGenerator.new()
	for sp in [0, 1, 2]:
		rng.seed = 4242 + sp
		var cap := 20
		var r := Const.germ_radius(cap)
		var still := Sim.hit_shape(sp, cap, Vector2.ZERO)
		var moving := Sim.hit_shape(sp, cap, Vector2(Const.germ_speed(cap), 0.0))
		var span := (r + Const.SHOT_RADIUS) * 2.5
		var hit_still := 0
		var hit_moving := 0
		for i in 20000:
			var dir := Vector2.from_angle(rng.randf() * TAU)
			var off := dir.orthogonal() * rng.randf_range(-span, span)
			var a := off - dir * 400.0
			var b := off + dir * 400.0
			if Sim.seg_ellipse_t(a, b, Vector2.ZERO, still) >= 0.0:
				hit_still += 1
			if Sim.seg_ellipse_t(a, b, Vector2.ZERO, moving) >= 0.0:
				hit_moving += 1
		var ratio := float(hit_moving) / float(maxi(hit_still, 1))
		_check(absf(ratio - 1.0) < 0.015,
			"%s: hərəkətdə vurulma ehtimalı dayanandakı ilə eynidir (%.3f)" % [NAMES[sp], ratio])


## Görünən gövdə toqquşma ellipsindən bayıra çıxmır — mərkəzi gövdədən keçən
## top həmişə dəyir (bax [method GermVisual._fit_hit]).
##
## Ellips balans üçün dairə enindədir və görüntüyə görə böyüdülə bilməz; böyük
## amöbün sürünmə zirvələri isə ondan 15%-ə qədər çıxırdı. Ölçü tam sürətdə,
## ən kiçik və ən böyük tutumda, 5 saniyəlik sürünmə boyu aparılır.
static func _test_body_fits_hit_shape() -> void:
	const NAMES := ["kirpikli", "ayaqlı", "amöb"]
	for sp in [0, 1, 2]:
		for cap in [Const.START_CAPACITY, 35, Const.MAX_CAPACITY]:
			var v := GermVisual.new()
			v.setup(1, "x", false, sp)
			v.hit_fit = true
			var r := Const.germ_radius(cap)
			var vel := Vector2(Const.germ_speed(cap) * Const.SPECIES_SPEED[sp], 0.0).rotated(0.4)
			v.net_vel = vel
			var shape := Sim.hit_shape(sp, cap, vel)
			var inv := Vector2(1.0 / shape.x, 1.0 / shape.y)
			var pos := Vector2.ZERO
			var worst := 0.0
			for f in 300:
				pos += vel / 60.0
				v.apply(pos, vel.angle(), 5, cap, false, true, false)
				v._process(1.0 / 60.0)
				if f < 60:
					continue
				for p in v._body_ring(r):
					worst = maxf(worst, (p.rotated(-shape.z) * inv).length())
			v.free()
			_check(worst <= 1.0005, "%s, tutum %d: görünən gövdə toqquşma ellipsinin içindədir (%.3f)"
				% [NAMES[sp], cap, worst])


## "Proqnoz atəşi bu paketdə açdı" biti gedib-gəlir, atəşsiz paketdə isə olmur.
static func _test_input_shot_bit() -> void:
	var inp := Sim.PlayerInput.make(7, Vector2.RIGHT, 0.3, true, false, 12.5)
	inp.shot = true
	var back := Sim.PlayerInput.from_array(inp.to_array())
	_check(back.shot and back.fire and is_equal_approx(back.view_tick, 12.5),
		"proqnoz atəşinin biti paketdə gedir")
	var idle := Sim.PlayerInput.make(8, Vector2.RIGHT, 0.3, false)
	idle.shot = true
	_check(not Sim.PlayerInput.from_array(idle.to_array()).shot,
		"atəşsiz paketdə bit oxunmur")
	# Köhnə client biti göndərmir — beş sahəli paket əvvəlki kimi oxunur.
	_check(not Sim.PlayerInput.from_array([1, 0.0, 0.0, 0.0, 1]).shot,
		"köhnə formatlı atəş işarəsiz oxunur")


## İki paket bir tick-də gələndə atəş ÖZ nişanı və görünən tick-i ilə açılır.
##
## Server oyunçu başına yalnız son paketi saxlayır. Əvvəl atəş yeni paketin
## nişanı ilə açılırdı, proqnoz isə köhnəsininki ilə — ölçülüb, RTT 120–180
## ms-də atəşlərin 12–19%-i birləşirdi və top başqa xətlə uçurdu.
static func _test_merged_fire_keeps_aim() -> void:
	# [birinci atəş, birinci bit, ikinci atəş, ikinci bit, gözlənilən nişan, geri sarma, ad]
	var cases := [
		[true, true, false, false, 0.0, 11.0, "atəşli paket yenisinə birləşəndə nişanı və tick-i itmir"],
		[true, false, false, false, 0.0, 11.0, "köhnə client: atəşin nişanı birləşmədə qalır"],
		[true, false, true, false, 0.0, 11.0, "köhnə client, basılı düymə: ilk basılışın nişanı"],
		[true, true, true, false, 0.0, 11.0, "proqnoz atəşi köhnə paketdə açıb — onun nişanı"],
		[true, false, true, true, PI * 0.5, 6.0, "proqnoz atəşi yeni paketdə açıb — yeninin nişanı"],
	]
	for c in cases:
		var world := _quiet_world(51)
		var g := world.add_player(A_ID, "A", Const.Species.CILIATE)
		g.balls = Const.START_BALLS
		world.sim.tick = 100
		var first := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, bool(c[0]), false, 90.0)
		first.shot = bool(c[1])
		var second := Sim.PlayerInput.make(2, Vector2.ZERO, PI * 0.5, bool(c[2]), false,
			95.0 if bool(c[2]) else -1.0)
		second.shot = bool(c[3])
		world.accept_input(A_ID, first.to_array())
		world.accept_input(A_ID, second.to_array())
		world.tick(Const.TICK_DELTA)
		var shot: Sim.ShotState = null
		for s in world.sim.shots:
			if s.owner_id == A_ID:
				shot = s
		_check(shot != null and absf(angle_difference(shot.dir.angle(), float(c[4]))) < 0.001
				and is_equal_approx(shot.rewind, float(c[5])),
			"%s (bucaq %.2f, geri sarma %.1f)" % [String(c[6]),
				shot.dir.angle() if shot != null else NAN, shot.rewind if shot != null else NAN])


## Proqnozun açdığı atəş serverdə soyuma bir-iki tick gecikəndə itmir.
##
## Soyumanı iki tərəf eyni saxlayır, amma girişlər birləşəndə server onu bir
## tick gec başlayır: proqnoz atəşi açırdı, server isə "hələ tezdir" deyib
## atırdı — ekranda uçan top serverdə heç olmurdu.
static func _test_predicted_fire_waits() -> void:
	for marked in [true, false]:
		var world := _quiet_world(52)
		var g := world.add_player(A_ID, "A", Const.Species.CILIATE)
		# İkinci mikrob dünyanı AÇIQ saxlayır: tək mikrob qalanda dünya bitmiş
		# sayılır və donur (bax [method World._match_over]).
		world.sim.add_germ(B_ID, "B", 1).safe_t = 0.0
		g.balls = Const.START_BALLS
		# Soyuma birinci tick-də hələ bitmir, ikincidə bitir.
		g.cooldown = Const.TICK_DELTA * 1.5
		var inp := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)
		inp.shot = marked
		world.accept_input(A_ID, inp.to_array())
		var fired_at := -1
		for i in 5:
			world.tick(Const.TICK_DELTA)
			if fired_at < 0 and _shots_of(world.sim, A_ID) > 0:
				fired_at = i
		if marked:
			_check(fired_at == 1, "proqnozun atəşi soyuma bitən tick-də açılır (tick %d)" % fired_at)
		else:
			_check(fired_at < 0, "işarəsiz atəş gözləmir — köhnə qayda (%d)" % fired_at)

	# Gözləmə hədlidir: soyuma çox uzaqdırsa atəş atılır, "yığılıb" sonra açılmır.
	var world := _quiet_world(53)
	var g := world.add_player(A_ID, "A", Const.Species.CILIATE)
	world.sim.add_germ(B_ID, "B", 1).safe_t = 0.0
	g.balls = Const.START_BALLS
	g.cooldown = Const.TICK_DELTA * float(World.FIRE_WAIT + 3)
	var inp := Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)
	inp.shot = true
	world.accept_input(A_ID, inp.to_array())
	for i in World.FIRE_WAIT + 6:
		world.tick(Const.TICK_DELTA)
	_check(_shots_of(world.sim, A_ID) == 0,
		"gözləmə %d tick-dən uzun çəkmir — sonradan atəş açılmır" % World.FIRE_WAIT)


static func _shots_of(s: Sim, owner: int) -> int:
	var n := 0
	for shot in s.shots:
		if shot.owner_id == owner:
			n += 1
	return n


## İnsanın topunu trixosist atıcının GÖRDÜYÜ anda dağıdır — `rewind` qədər gec.
##
## Atıcı qurbanı `rewind` geridə görür: partlayış onun ekranına o qədər gec
## çatır. Partlayışdan ƏVVƏL qurbanın gövdəsinə çatan top dəyir (atıcı da,
## qurban da onu belə görüb), sonra çatan dağılır. Əvvəl top dərhal dağılırdı
## və atıcının ekranındakı zərbə serverdə heç olmurdu.
static func _test_trichocyst_waits_for_rewind() -> void:
	# [top qurbanın mərkəzinə bu qədər qalanda super açılır, gözlənilən, ad]
	var cases := [
		[60.0, true, "top qurbana partlayışdan əvvəl çatır — dəyir"],
		[170.0, false, "top partlayış anında radiusdadır — dağılır, qida olur"],
	]
	for c in cases:
		var s := Sim.new()
		s.obstacles = [] as Array[Vector4]
		s.lag_comp = true
		var a := s.add_germ(A_ID, "A", 0)
		var b := s.add_germ(B_ID, "B", 1, false, Const.Species.CILIATE)
		a.safe_t = 0.0
		b.safe_t = 0.0
		b.charge = Const.SUPER_MAX
		b.balls = 8
		var a_at := Vector2(-300.0, LANE_Y)
		var b_at := Vector2(100.0, LANE_Y)
		for i in 12:
			a.pos = a_at
			b.pos = b_at
			a.vel = Vector2.ZERO
			b.vel = Vector2.ZERO
			s.step({}, Const.TICK_DELTA)
		var view := float(s.tick + 1) - 6.0
		var used := false
		var balls_before := b.balls
		for i in 40:
			a.pos = a_at
			b.pos = b_at
			a.vel = Vector2.ZERO
			b.vel = Vector2.ZERO
			var inputs := {}
			if i == 0:
				inputs[A_ID] = Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, view)
			elif not used and not s.shots.is_empty() \
					and s.shots[0].pos.distance_to(b_at) <= float(c[0]):
				inputs[B_ID] = Sim.PlayerInput.make(1, Vector2.ZERO, PI, false, true)
				used = true
			s.step(inputs, Const.TICK_DELTA)
		# Top qurbanın mərkəzinə nişanlanıb: dağılmasa mütləq dəyərdi.
		var hit := b.balls > balls_before - Const.TRICHO_COST
		_check(used and hit == bool(c[1]),
			"trixosist, geri sarılan top: %s (%s)" % [String(c[2]), "dəydi" if hit else "dağıldı"])


## Bot trixosisti insanın topuna qarşı da vaxtında açır — topu `rewind`
## qədər qabaqda görür (bax [method Bot._wants_super]).
static func _test_bot_sees_rewound_shot() -> void:
	var s := Sim.new()
	s.obstacles = [] as Array[Vector4]
	var me := s.add_germ(A_ID, "A", 0, true, Const.Species.CILIATE)
	me.safe_t = 0.0
	me.charge = Const.SUPER_MAX
	me.balls = 8
	var reach := me.radius() * Const.TRICHO_RADIUS
	var shot := Sim.ShotState.new()
	shot.owner_id = B_ID
	shot.dir = Vector2.LEFT
	shot.life = Const.SHOT_LIFETIME
	# Top indi radiusdan kənardadır, 6 tick sonra isə içində olacaq.
	shot.pos = me.pos + Vector2(reach + 40.0, 0.0)
	shot.rewind = 6.0
	s.shots.append(shot)
	_check(Bot._wants_super(s, me, null, null, false),
		"bot geri sarılan topu qabaqda görüb trixosist açır")
	shot.rewind = 0.0
	_check(not Bot._wants_super(s, me, null, null, false),
		"botun topunu (geri sarmasız) indiki yerində görür — hələ tezdir")


## Rəqibin trixosisti ekranda görünəndə öz UÇAN proqnoz topların dağılır.
static func _test_prediction_blast() -> void:
	var p := ShotPrediction.new()
	var near := p.spawn(Vector2(50.0, 0.0), Vector2.RIGHT, 0.0)
	var far := p.spawn(Vector2(400.0, 0.0), Vector2.RIGHT, 0.0)
	var gone := p.blast(Vector2.ZERO, 100.0, 1.0)
	_check(gone.size() == 1 and not near.alive and far.alive,
		"partlayış radiusundakı proqnoz topu dayanır, uzaqdakı uçur")


## Doğuş qalxanı da keçmişdən oxunur: atıcı qalxanı görürdüsə, top keçir.
static func _test_rewound_safe() -> void:
	var s := Sim.new()
	s.obstacles = [] as Array[Vector4]
	s.lag_comp = true
	var a := s.add_germ(A_ID, "A", 0)
	var b := s.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	var a_at := Vector2(-150.0, LANE_Y)
	var b_at := Vector2(100.0, LANE_Y)
	# Qalxan tick 27-də bitir. Top gövdəyə tick 28-də girir, 33-də çıxır —
	# atıcının ekranında (8 tick geridə, 20–25) qalxan hələ var, serverin
	# İNDİSİNDƏ isə yoxdur: köhnə qayda burada dəyərdi.
	b.safe_t = Const.TICK_DELTA * 26.5
	for i in 12:
		a.pos = a_at
		b.pos = b_at
		a.vel = Vector2.ZERO
		b.vel = Vector2.ZERO
		s.step({}, Const.TICK_DELTA)
	var view := float(s.tick + 1) - 8.0
	var before := b.balls
	for i in 30:
		a.pos = a_at
		b.pos = b_at
		a.vel = Vector2.ZERO
		b.vel = Vector2.ZERO
		var inputs := {}
		if i == 0:
			inputs[A_ID] = Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, view)
		s.step(inputs, Const.TICK_DELTA)
	_check(b.safe_t <= 0.0 and b.balls == before,
		"atıcının gördüyü qalxan topu buraxır — serverdə bitmiş olsa da")


## Proqnoz rəqibə sıxılanda serverlə eyni yerdə qalır — kölgə rəqib server kimi
## itələnir (bax [method Arena._sync_proxies]).
##
## Kölgəsiz köhnə proqnoz rəqibin içindən keçirdi: server mikrobu hər tick geri
## itələyirdi, proqnoz isə bilmirdi. Nöqtə-nöqtə atəşdə başlanğıc 12–24 px fərqlənirdi.
static func _test_prediction_separates() -> void:
	var srv := Sim.new()
	srv.obstacles = [] as Array[Vector4]
	var a := srv.add_germ(A_ID, "A", 0)
	var b := srv.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	b.safe_t = 0.0
	a.pos = Vector2(-70.0, LANE_Y)
	b.pos = Vector2(0.0, LANE_Y)
	a.vel = Vector2.ZERO
	b.vel = Vector2.ZERO

	var pred := Sim.new()
	pred.obstacles = [] as Array[Vector4]
	var me := pred.add_germ(A_ID, "A", 0)
	me.pos = a.pos
	me.vel = Vector2.ZERO
	var shadow := Sim.GermState.new()
	shadow.id = B_ID
	shadow.pos = b.pos
	pred.germs[B_ID] = shadow

	var alone := Sim.new()
	alone.obstacles = [] as Array[Vector4]
	var solo := alone.add_germ(A_ID, "A", 0)
	solo.pos = a.pos
	solo.vel = Vector2.ZERO

	var worst_new := 0.0
	var worst_old := 0.0
	var still := Sim.PlayerInput.make(0, Vector2.ZERO, 0.0, false)
	for i in 30:
		var inp := Sim.PlayerInput.make(i + 1, Vector2.RIGHT, 0.0, false)
		srv.step({A_ID: inp}, Const.TICK_DELTA)
		pred.step_movement({A_ID: inp, B_ID: still}, Const.TICK_DELTA, false)
		alone.step_movement({A_ID: inp}, Const.TICK_DELTA, false)
		worst_new = maxf(worst_new, me.pos.distance_to(a.pos))
		worst_old = maxf(worst_old, solo.pos.distance_to(a.pos))
	_check(worst_new < 0.01, "proqnoz rəqibə sıxılanda serverlə üst-üstə düşür (%.3f px)" % worst_new)
	_check(worst_old > 10.0, "kölgəsiz proqnoz eyni halda ayrılırdı (%.1f px)" % worst_old)


## Proqnoz topu qabın kənarından serverlə EYNİ nöqtədə sıçrayır və sonra eyni yolu gedir.
##
## Kənar sıçrayışı addımın sonundan radial proyeksiyadır, yəni addımın
## uzunluğundan asılıdır. Proqnoz əvvəl kadrla (7 px), server tick-lə (14 px)
## addımlayırdı: sıçrayış nöqtəsi fərqlənirdi və 500 px sonra top 18 px aralı
## uçurdu — ekranda dəyən top serverdə rəqibin yanından keçirdi.
static func _test_prediction_edge_bounce() -> void:
	var s := Sim.new()
	s.obstacles = [] as Array[Vector4]
	var from := Vector2(0.0, 1000.0)
	var dir := Vector2(0.8, 0.6).normalized()
	var shot := Sim.ShotState.new()
	shot.id = 1
	shot.pos = from
	shot.dir = dir
	shot.life = Const.SHOT_LIFETIME
	s.shots.append(shot)
	var server_bounce := Vector2.INF
	for i in 40:
		s.events.clear()
		s._step_shots(Const.TICK_DELTA)
		for e in s.events:
			if e.get("t") == "hit" and float(e["arg"]) < 0.5 and not server_bounce.is_finite():
				server_bounce = e["pos"]
	var server_after := s.shots[0].pos

	var p := ShotPrediction.new()
	var g := p.spawn(from, dir, 0.0)
	g.sid = 1
	var ghost_bounce := Vector2.INF
	var i := 0
	while float(i) / 60.0 < 40.0 * Const.TICK_DELTA - 0.000001:
		i += 1
		for c in p.step(1.0 / 60.0, float(i) / 60.0, [] as Array[Vector4], PackedByteArray(), []):
			if int(c["kind"]) == ShotPrediction.Contact.BOUNCE and not ghost_bounce.is_finite():
				ghost_bounce = c["pos"]
	_check(server_bounce.is_finite() and ghost_bounce.is_finite()
			and server_bounce.distance_to(ghost_bounce) < 0.01,
		"proqnoz qabın kənarından serverlə eyni nöqtədə sıçrayır (%.3f px)"
			% (server_bounce.distance_to(ghost_bounce) if ghost_bounce.is_finite() else -1.0))
	_check(g.pos.distance_to(server_after) < 0.01,
		"sıçrayışdan sonra eyni yolu gedir (%.3f px)" % g.pos.distance_to(server_after))


## Proqnoz topu rəqibi serverin yoxladığı TICK-də görür — hərəkətdəki hədəfə
## geri sarma ilə serverlə EYNİ nöqtədə dəyir (bax [method Arena._ghost_targets]).
static func _test_prediction_tick_targets() -> void:
	var s := Sim.new()
	s.obstacles = [] as Array[Vector4]
	s.lag_comp = true
	var a := s.add_germ(A_ID, "A", 0)
	var b := s.add_germ(B_ID, "B", 1)
	a.safe_t = 0.0
	b.safe_t = 0.0
	var a_at := Vector2(-60.0, LANE_Y)
	var b_at := Vector2(100.0, LANE_Y - 30.0)
	var record := {}
	for i in 12:
		a.pos = a_at
		a.vel = Vector2.ZERO
		b.pos = b_at
		b.vel = Vector2(0.0, 150.0)
		s.step({}, Const.TICK_DELTA)
		record[s.tick] = s._hist_at(s.tick, B_ID)
	var view := float(s.tick + 1) - 7.5
	var origin := Vector2.INF
	var server_hit := Vector2.INF
	for i in 30:
		a.pos = a_at
		a.vel = Vector2.ZERO
		b.pos = b_at + Vector2(0.0, 5.0 * float(i))
		b.vel = Vector2(0.0, 150.0)
		var inputs := {}
		if i == 0:
			inputs[A_ID] = Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true, false, view)
		s.step(inputs, Const.TICK_DELTA)
		record[s.tick] = s._hist_at(s.tick, B_ID)
		if i == 0 and not s.shots.is_empty():
			origin = s.shots[0].pos - s.shots[0].dir * Const.SHOT_SPEED * Const.TICK_DELTA
		for e in s.events:
			if e.get("t") == "hit" and float(e["arg"]) > 0.5:
				server_hit = e["pos"]
	# Hədəf serverin öz tarixçəsindən, tick-ə görə — client-də bu, snapshot buferidir.
	var cap := b.capacity
	var targets := func(t: float) -> Array:
		var t0 := floori(t)
		var p0: Variant = record.get(t0)
		var p1: Variant = record.get(t0 + 1)
		if p0 == null or p1 == null:
			return []
		var st := (p0 as Vector4).lerp(p1 as Vector4, t - float(t0))
		return [{"pos": Vector2(st.x, st.y), "radius": Const.germ_radius(cap),
			"shape": Sim.hit_shape(int(Const.Species.CILIATE), cap, Vector2(st.z, st.w)),
			"key": B_ID}]
	var p := ShotPrediction.new()
	p.spawn(origin, Vector2.RIGHT, 0.0, view)
	var ghost_hit := Vector2.INF
	for i in 90:
		for c in p.step(1.0 / 60.0, float(i) / 60.0, [] as Array[Vector4], PackedByteArray(), targets):
			if int(c["kind"]) == ShotPrediction.Contact.HIT:
				ghost_hit = c["pos"]
	_check(server_hit.is_finite() and ghost_hit.is_finite()
			and server_hit.distance_to(ghost_hit) < 0.01,
		"proqnoz hərəkətdəki hədəfə serverlə eyni nöqtədə dəyir (%.3f px)"
			% (server_hit.distance_to(ghost_hit) if ghost_hit.is_finite() and server_hit.is_finite() else -1.0))


## Eyni toxumlu iki dünya eyni gedir — botlar da daxil (bax [method World._add_bot]).
static func _test_world_seed_repeats() -> void:
	var one := World.new(1)
	var two := World.new(1)
	one.sim.rng.seed = 77
	two.sim.rng.seed = 77
	for i in 300:
		one.tick(Const.TICK_DELTA)
		two.tick(Const.TICK_DELTA)
	var same := one.sim.germs.size() == two.sim.germs.size() \
		and one.sim.shots.size() == two.sim.shots.size() \
		and one.sim.food.size() == two.sim.food.size()
	if same:
		for gid in one.sim.germs:
			var g1: Sim.GermState = one.sim.germs[gid]
			var g2: Sim.GermState = two.sim.germs.get(gid)
			if g2 == null or g1.pos != g2.pos or g1.balls != g2.balls or g1.species != g2.species:
				same = false
				break
	_check(same, "eyni toxumlu iki bot dünyası 10 saniyədə eyni qalır")


## Proqnoz topu ekrandakı rəqibə dəyir.
static func _test_prediction_hits_target() -> void:
	var target := {"pos": Vector2(100.0, LANE_Y), "radius": 28.0, "key": 7}
	var p := ShotPrediction.new()
	p.spawn(Vector2(-100.0, LANE_Y), Vector2.RIGHT, 0.0)
	var hit: Dictionary = {}
	for i in 60:
		for c in p.step(1.0 / 60.0, float(i) / 60.0, [] as Array[Vector4],
				PackedByteArray(), [target]):
			if int(c["kind"]) == ShotPrediction.Contact.HIT:
				hit = c
	_check(not hit.is_empty() and int(hit["key"]) == 7,
		"proqnoz topu rəqibə dəydi (açar %s)" % str(hit.get("key", "-")))
	if not hit.is_empty():
		var edge := 100.0 - 28.0 - Const.SHOT_RADIUS
		_check(absf(Vector2(hit["pos"]).x - edge) < 1.0,
			"dəymə nöqtəsi membranın üstündədir (x=%.1f, gözlənilən %.1f)"
				% [Vector2(hit["pos"]).x, edge])
		_check(not p.ghosts[0].alive, "dəyən top dayanır — rəqibin içindən keçmir")



## Server topu proqnozla BİR dəfə birləşir; təsdiqsiz top özü sönür.
static func _test_prediction_claims() -> void:
	var p := ShotPrediction.new()
	var g := p.spawn(Vector2.ZERO, Vector2.RIGHT, 0.0)
	_check(p.take_unseen_fire(0.1, 0.6), "serverin atəş hadisəsi proqnozu tapır")
	_check(not p.take_unseen_fire(0.1, 0.6), "eyni proqnoz ikinci hadisəyə uyğun gəlmir")
	_check(p.claim(5, Vector2.RIGHT, 0.2) == g, "serverin topu proqnozla birləşdi")
	_check(p.claim(6, Vector2.RIGHT, 0.2) == null, "birləşmiş proqnoz ikinci topa verilmir")
	_check(p.claim(7, Vector2.UP, 0.2) == null, "başqa istiqamətli top birləşmir")

	# Dəymiş (ölü) proqnoz da tutulur — yoxsa serverin topu ekranda peyda olardı.
	var q := ShotPrediction.new()
	var dead := q.spawn(Vector2.ZERO, Vector2.LEFT, 0.0)
	dead.alive = false
	dead.ended = 0.05
	q.step(1.0 / 60.0, 0.1, [] as Array[Vector4], PackedByteArray(), [])
	_check(q.claim(9, Vector2.LEFT, 0.15) == dead,
		"artıq dəymiş proqnoz da serverin topunu udur")

	# Server heç vaxt təsdiqləməsə, top səssizcə gedir.
	var r := ShotPrediction.new()
	r.spawn(Vector2.ZERO, Vector2.DOWN, 0.0)
	var contacts := r.step(1.0 / 60.0, ShotPrediction.CLAIM_GRACE + 0.1,
		[] as Array[Vector4], PackedByteArray(), [])
	_check(contacts.is_empty() and r.ghosts.is_empty(),
		"təsdiqlənməyən top təmas vermədən silinir")


## Server topu gələndə proqnoz onun XƏTTİNƏ yana çəkilir, xətt boyu isə yerində qalır.
static func _test_prediction_aligns_to_server() -> void:
	var p := ShotPrediction.new()
	var g := p.spawn(Vector2(0.0, LANE_Y + 30.0), Vector2.RIGHT, 0.0)
	p.claim(4, Vector2.RIGHT, 0.05, Vector2(-40.0, LANE_Y))
	var now := 0.05
	for i in 18:
		now += 1.0 / 60.0
		p.step(1.0 / 60.0, now, [] as Array[Vector4], PackedByteArray(), [])
	_check(absf(g.pos.y - LANE_Y) < 1.0,
		"proqnoz serverin xəttinə çəkildi (yan fərq %.1f px)" % absf(g.pos.y - LANE_Y))
	# Top YAŞA görə uçur (atəşdən bəri keçən vaxt), çağırışların sayına görə yox.
	_check(absf(g.pos.x - Const.SHOT_SPEED * now) < 1.0,
		"xətt boyu vaxt dəyişmədi (x=%.1f, gözlənilən %.1f)" % [g.pos.x, Const.SHOT_SPEED * now])


## Gec tapılmış atəş indiyə çatdırılır — divardan sıçrayaraq, serverin topu kimi.
##
## Top düz xətdə yalnız yolun uzunluğu qədər irəli gedir; yolda maneə varsa
## server də, proqnoz da eyni nöqtədə sıçrayır. Keçmişdə rəqibə dəyməni isə
## proqnoz yoxlamır — onu serverin hadisəsi deyir.
static func _test_prediction_catch_up() -> void:
	var p := ShotPrediction.new()
	var g := p.spawn(Vector2(-100.0, LANE_Y), Vector2.RIGHT, 0.0)
	p.catch_up(g, 0.25, 0.25, [] as Array[Vector4], PackedByteArray())
	_check(absf(g.pos.x - (-100.0 + Const.SHOT_SPEED * 0.25)) < 0.5 and g.alive,
		"gec top keçən vaxt qədər irəli çəkilir (x=%.1f)" % g.pos.x)

	var s := Sim.new()
	var blob := _first_of(s, DishMap.Kind.MUCUS)
	var centre := Vector2(blob.x, blob.y)
	var out := centre.normalized() if centre.length() > 1.0 else Vector2.RIGHT
	var start := centre + out * (blob.z + 40.0)
	var q := ShotPrediction.new()
	var h := q.spawn(start, -out, 0.0)
	q.catch_up(h, 0.3, 0.3, s.obstacles, s.broken)
	_check(h.bounces == 1 and h.dir.dot(-out) < 0.0,
		"yolda maneə varsa gec top ondan sıçrayır (%d sıçrayış)" % h.bounces)


## Proqnozun vəd etdiyi top sayı serverin köhnə rəqəmindən üstündür, amma ilişmir.
static func _test_germ_promise() -> void:
	var g := GermVisual.new()
	g.setup(0, "A", false, Const.Species.CILIATE)
	g.apply(Vector2.ZERO, 0.0, 5, 10, false, true)
	g.promise_balls(7, 0.6)
	_check(g.balls == 7, "vəd dərhal görünür (%d)" % g.balls)
	g.apply(Vector2.ZERO, 0.0, 5, 10, false, true)
	_check(g.balls == 7, "serverin köhnə rəqəmi vədi silmir (%d)" % g.balls)
	g.apply(Vector2.ZERO, 0.0, 7, 10, false, true)
	g.apply(Vector2.ZERO, 0.0, 6, 10, false, true)
	_check(g.balls == 6, "server çatandan sonra vəd sönür (%d)" % g.balls)

	g.promise_balls(9, 0.2)
	g._process(0.25)
	g.apply(Vector2.ZERO, 0.0, 6, 10, false, true)
	_check(g.balls == 6, "təsdiqlənməyən vəd vaxtı bitəndə sönür (%d)" % g.balls)
	g.free()


## Seçilməmiş keyfiyyət və kadr həddi fayldan OXUNMUR — cihazın ilkin dəyəri qalır.
##
## Menyu OYNA basılanda bütün ayarları yazır. Telefon brauzeri əvvəl masaüstü
## sayıldığına görə orada YÜKSƏK və həddsiz kadr yazılıb qalmışdı; bu test
## yazılmış, amma SEÇİLMƏMİŞ dəyərin düzəlişi ləğv etmədiyini yoxlayır. Test
## masaüstündə işləyir, ona görə tərsinə yoxlanır: yazılmış AŞAĞI + 30 kadr
## seçilməyibsə, cihazın ilkini (YÜKSƏK, həddsiz) qalır.
static func _test_settings_device_defaults() -> void:
	var path := "user://_test_settings.cfg"
	var keep := [Net.quality, Settings.fps_cap, Settings.quality_chosen, Settings.fps_chosen,
		Net.nickname, int(Net.species), int(Net.mode)]
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", int(Const.Quality.LOW))
	cfg.set_value("video", "fps_cap", 30)
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(Net.quality == Const.default_quality() and Settings.fps_cap == Settings.default_fps_cap(),
		"seçilməmiş keyfiyyət və kadr həddi cihazın ilkinindən gəlir (%d, %d)"
			% [int(Net.quality), Settings.fps_cap])

	cfg.set_value("video", "quality_chosen", true)
	cfg.set_value("video", "fps_chosen", true)
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(Net.quality == Const.Quality.LOW and Settings.fps_cap == 30,
		"oyunçunun ÖZ seçimi saxlanılır (%d, %d)" % [int(Net.quality), Settings.fps_cap])
	_check(not Const.is_handheld(), "masaüstü telefon sayılmır")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Net.quality = keep[0]
	Settings.fps_cap = keep[1]
	Settings.quality_chosen = keep[2]
	Settings.fps_chosen = keep[3]
	Net.nickname = keep[4]
	Net.species = Const.species_from(keep[5])
	Net.mode = Const.mode_from(keep[6])


## Telefon tətbiqində (brauzer yox) MİNİMUM səhnəni baza ölçüdə çəkib böyüdür.
##
## Brauzerdə isə bu iş kətanın piksel sıxlığına keçib (bax
## [method Settings._apply_render_scale]) — orada `viewport` rejimi ayrıca
## böyütmə keçidi əlavə edirdi. Headless test brauzer deyil, yəni burada
## yerli yol yoxlanılır.
static func _test_render_scale_native() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var keep := Net.quality
	var root := tree.root
	var was := root.content_scale_mode
	Net.quality = Const.Quality.MINIMUM
	Settings._apply_render_scale()
	var minimum := root.content_scale_mode
	Net.quality = Const.Quality.LOW
	Settings._apply_render_scale()
	var low := root.content_scale_mode
	_check(minimum == Window.CONTENT_SCALE_MODE_VIEWPORT and low == Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		"tətbiqdə MİNİMUM baza ölçüdə çəkir, AŞAĞI isə ekranın öz ölçüsündə")
	_check(Settings.WEB_MIN_DPR < Settings.WEB_MAX_DPR and Settings.WEB_MIN_DPR >= 1.0,
		"brauzerdə MİNİMUM kətanın sıxlığını endirir (%.2f < %.2f)" % [Settings.WEB_MIN_DPR, Settings.WEB_MAX_DPR])
	Net.quality = keep
	root.content_scale_mode = was


## Üç keyfiyyət səviyyəsi: çevirmə, ad, "yüngül" yoxlaması və öyrənilmiş səviyyə.
static func _test_quality_tiers() -> void:
	_check(Const.quality_from(2) == Const.Quality.MINIMUM and Const.quality_from(7) == Const.Quality.HIGH,
		"MİNİMUM oxunur, yad dəyər YÜKSƏK-ə düşür")
	_check(Const.is_light(int(Const.Quality.MINIMUM)) and Const.is_light(int(Const.Quality.LOW))
		and not Const.is_light(int(Const.Quality.HIGH)), "glow AŞAĞI və MİNİMUM-da sönülüdür")
	_check(Const.quality_name(2) == "MİNİMUM", "üçüncü səviyyənin adı")

	var path := "user://_test_tiers.cfg"
	var keep := [Net.quality, Settings.fps_cap, Settings.quality_chosen, Settings.fps_chosen,
		Settings.auto_quality, Net.nickname, int(Net.species), int(Net.mode)]
	var cfg := ConfigFile.new()
	cfg.set_value("video", "auto_quality", int(Const.Quality.MINIMUM))
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(Net.quality == Const.Quality.MINIMUM,
		"tənzimləyicinin öyrəndiyi səviyyə növbəti açılışda qalır (%d)" % int(Net.quality))
	_check(Settings.effective_fps_cap() == 30, "MİNİMUM-da kadr həddi 30 (%d)" % Settings.effective_fps_cap())
	cfg.set_value("video", "quality_chosen", true)
	cfg.set_value("video", "quality", int(Const.Quality.HIGH))
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(Net.quality == Const.Quality.HIGH, "oyunçunun öz seçimi öyrənilən səviyyədən üstündür")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Net.quality = keep[0]
	Settings.fps_cap = keep[1]
	Settings.quality_chosen = keep[2]
	Settings.fps_chosen = keep[3]
	Settings.auto_quality = keep[4]
	Net.nickname = keep[5]
	Net.species = Const.species_from(keep[6])
	Net.mode = Const.mode_from(keep[7])


## Tənzimləyici ardıcıl yavaşlığı tutur, tək-tük sıçrayışı isə saymır.
static func _test_perf_governor() -> void:
	var smooth := PackedFloat32Array()
	var heavy := PackedFloat32Array()
	var spiky := PackedFloat32Array()
	var rare := PackedFloat32Array()
	for i in 300:
		smooth.append(1.0 / 60.0)
		heavy.append(0.026)
		spiky.append(0.045 if i % 6 == 0 else 1.0 / 60.0)
		rare.append(0.080 if i % 40 == 0 else 1.0 / 60.0)
	_check(not Arena.too_slow(smooth, 60), "sabit 60 kadr — endirmə yoxdur")
	_check(Arena.too_slow(heavy, 60), "26 ms kadrlar (~38 FPS) — endirilir")
	_check(Arena.too_slow(spiky, 60), "hər altıncı kadr 45 ms — endirilir")
	_check(not Arena.too_slow(rare, 60), "40 kadrda bir sıçrayış — endirilmir")
	_check(not Arena.too_slow(heavy, 30), "30 kadr həddində 26 ms büdcənin içindədir")


## Kətan sıxlığının hökmü: yükün GPU-da olduğunu CPU işindən ayırır.
static func _test_resolution_verdict() -> void:
	var budget := 1.0 / 30.0
	var calm := PackedFloat32Array()
	var gpu := PackedFloat32Array()
	var cpu_bound := PackedFloat32Array()
	var judder := PackedFloat32Array()
	var hitch := PackedFloat32Array()
	var low := PackedFloat32Array()
	var high := PackedFloat32Array()
	for i in 90:
		calm.append(budget)
		gpu.append(0.050)
		cpu_bound.append(0.050)
		# 60 Hz ekranda 30 kadr: hər beşinci kadr bir vsync gecikir.
		judder.append(0.050 if i % 5 == 0 else budget)
		# Üç saniyədə iki böyük sıçrayış — şəbəkə, şeyder yüklənməsi.
		hitch.append(0.120 if i % 45 == 0 else budget)
		low.append(0.006)
		high.append(0.045)
	_check(Arena.resolution_verdict(calm, low, budget) == 1, "sabit 30 kadr — rahatdır, sıxlıq böyüyə bilər")
	_check(Arena.resolution_verdict(gpu, low, budget) == -1, "50 ms kadr — yavaşdır, kiçilir")
	# Oyun işinin vaxtı hökmə təsir etmir: brauzerdə GPU-nun gözləməsi də oraya
	# düşür. Kiçiltmənin kömək edib-etmədiyini [method Arena.resolution_step] yoxlayır.
	_check(Arena.resolution_verdict(cpu_bound, high, budget) == -1,
		"50 ms kadr, oyun işi 45 ms — hökm yenə 'yavaş'dır (CPU-nu brauzerdə ayırmaq olmur)")
	_check(Arena.resolution_verdict(judder, low, budget) == -1, "kadrların beşdə biri gecikir — kiçilir")
	_check(Arena.resolution_verdict(hitch, low, budget) == 1, "tək-tük sıçrayış sayılmır")
	_check(Arena.resolution_verdict(gpu.slice(0, 10), low, budget) == 0, "az kadrla hökm verilmir")
	var st := Arena.frame_stats(judder, low)
	_check(is_equal_approx(st.x, budget * 1000.0) and is_equal_approx(st.y, 50.0)
		and is_equal_approx(st.z, 6.0) and absf(st.w - (budget * 800.0 + 10.0)) < 0.01,
		"kadr statistikası: p50 %.1f, p90 %.1f, CPU %.1f, orta %.1f ms" % [st.x, st.y, st.z, st.w])


## Brauzer kadrlarının modeli: GPU işi piksel sayı ilə (sıxlığın kvadratı) artır,
## CPU-dan ayrı gedir; kadr ekranın vsync-inə yuvarlanır, 30 kadr həddi isə
## `min_vsyncs`-dan az buraxmır.
static func _res_window(dpr: float, gpu_at_1: float, cpu: float, rng: RandomNumberGenerator,
		frames: PackedFloat32Array, cpus: PackedFloat32Array, opts: Dictionary) -> void:
	frames.clear()
	cpus.clear()
	var vsync := 1.0 / float(opts.get("refresh", 60.0))
	var hitches := int(opts.get("hitches", 0))
	var t := 0.0
	var i := 0
	while t < Arena.RES_WINDOW:
		var g := gpu_at_1 * dpr * dpr * rng.randf_range(0.92, 1.08)
		var c := cpu * rng.randf_range(0.9, 1.1)
		var n := maxi(int(opts.get("min_vsyncs", 2)), ceili(maxf(g, c) / vsync - 1e-6))
		var ft := float(n) * vsync
		if hitches > 0 and i % (90 / hitches) == 0:
			ft = 0.12
		frames.append(ft)
		cpus.append(c)
		t += ft
		i += 1


## Tənzimləyicini modeldə işlədir: `{"dpr", "changes", "late", "p90", "fps"}`.
## `late` — son 20 pəncərədəki dəyişiklik (titrəmə), `p90`/`fps` — son pəncərə.
static func _res_run(start: float, cap: float, gpu_at_1: float, cpu: float,
		opts := {}, windows := 80) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var state := {}
	var dpr := start
	var changes := 0
	var late := 0
	var st := Vector4.ZERO
	var frames := PackedFloat32Array()
	var cpus := PackedFloat32Array()
	for w in windows:
		_res_window(dpr, gpu_at_1, cpu, rng, frames, cpus, opts)
		var verdict := Arena.resolution_verdict(frames, cpus, 1.0 / float(Arena.RES_FPS))
		st = Arena.frame_stats(frames, cpus)
		var next := Arena.resolution_step(dpr, verdict, st.w, true, cap, state)
		if absf(next - dpr) > 0.001:
			changes += 1
			if w >= windows - 20:
				late += 1
		dpr = next
	# Son sıxlıqda ölçü.
	_res_window(dpr, gpu_at_1, cpu, rng, frames, cpus, opts)
	st = Arena.frame_stats(frames, cpus)
	return {"dpr": dpr, "changes": changes, "late": late, "p90": st.y, "fps": 1000.0 / st.w}


## Dinamik kətan sıxlığı GPU-nun MÜTLƏQ sürətindən asılı olmadan büdcəni tutur.
##
## Real Mali/Adreno-nun millisaniyəsi bilinmir, ona görə burada geniş aralıq
## yoxlanılır: 1.25 sıxlıqda kadrın GPU işi 12 ms-dən 150 ms-ə qədər. Hər
## halda tənzimləyici ya büdcəni tutan ən böyük sıxlığa (bir addım dəqiqliklə)
## gəlib orada qalır, ya da (çox zəif GPU) aşağı həddə enir. Yük CPU-dadırsa və
## ya kiçiltmə kömək etmirsə, şəkil boş yerə bulanıqlaşmır.
static func _test_resolution_converges() -> void:
	var top := Settings.WEB_MIN_DPR
	var floor_dpr := Settings.WEB_FLOOR_DPR
	var budget_ms := 1000.0 / float(Arena.RES_FPS)
	for gpu_ms in [12.0, 30.0, 45.0, 60.0, 80.0]:
		var gpu_at_1: float = gpu_ms / 1000.0 / (top * top)
		var r := _res_run(top, top, gpu_at_1, 0.006)
		# Ən böyük uyğun sıxlıq: kadrların 90%-i büdcəyə sığır (GPU səs-küyü ±8%).
		var best := minf(top, sqrt(budget_ms / 1000.0 / (gpu_at_1 * 1.064)))
		var fits: bool = r["p90"] <= budget_ms * 1.2
		_check(fits and r["dpr"] >= best / Arena.RES_UP - 0.001 and r["late"] == 0,
			"GPU 1.25-də %.0f ms: sıxlıq %.2f (ən yaxşı %.2f), kadr p90 %.1f ms, %.0f FPS, %d dəyişiklik"
				% [gpu_ms, r["dpr"], best, r["p90"], r["fps"], r["changes"]])
	for gpu_ms in [110.0, 150.0]:
		var weak := _res_run(top, top, gpu_ms / 1000.0 / (top * top), 0.006)
		_check(is_equal_approx(weak["dpr"], floor_dpr) and weak["late"] == 0,
			"çox zəif GPU (1.25-də %.0f ms): aşağı həddə enir (%.2f), %.0f FPS"
				% [gpu_ms, weak["dpr"], weak["fps"]])
	var cpu_bound := _res_run(top, top, 0.010, 0.045)
	_check(is_equal_approx(cpu_bound["dpr"], top) and cpu_bound["late"] == 0 and cpu_bound["changes"] <= 3,
		"yük CPU-dadır (45 ms): kiçiltmə kömək etmir — sıxlıq geri qaytarılır (%.2f, %d dəyişiklik)"
			% [cpu_bound["dpr"], cpu_bound["changes"]])
	# CPU da, GPU da yüklüdür: kiçiltmə GPU hissəsini qısaldır, kadr CPU-ya qədər enir.
	var both := _res_run(top, top, 0.080 / (top * top), 0.030)
	_check(both["dpr"] < top and both["p90"] <= budget_ms * 1.2 and both["late"] == 0,
		"GPU 80 ms + CPU 30 ms: sıxlıq %.2f-ə enir, kadr p90 %.1f ms" % [both["dpr"], both["p90"]])
	var saver := _res_run(top, top, 0.010, 0.006, {"refresh": 30.0, "min_vsyncs": 1})
	_check(is_equal_approx(saver["dpr"], top) and saver["changes"] == 0,
		"enerjiyə qənaət (brauzer 30 kadr verir): sıxlıq dəyişmir")
	var hitches := _res_run(top, top, 0.010, 0.006, {"hitches": 3})
	_check(is_equal_approx(hitches["dpr"], top) and hitches["changes"] == 0,
		"tək-tük sıçrayışlar sıxlığı dəyişmir")
	var recover := _res_run(floor_dpr, top, 0.008 / (top * top), 0.006)
	_check(is_equal_approx(recover["dpr"], top),
		"yadda qalmış aşağı sıxlıq, GPU isə rahatdır: geri həddə qalxır (%.2f)" % recover["dpr"])
	var chosen := _res_run(Settings.WEB_MAX_DPR, Settings.WEB_MAX_DPR, 0.060 / 4.0, 0.006)
	var chosen_best := sqrt(budget_ms / 1000.0 / (0.060 / 4.0 * 1.064))
	_check(chosen["p90"] <= budget_ms * 1.2 and chosen["dpr"] >= chosen_best / Arena.RES_UP - 0.001
		and chosen["late"] == 0,
		"oyunçu YÜKSƏK seçib (hədd 2.0, GPU 2.0-da 60 ms): sıxlıq %.2f (ən yaxşı %.2f)"
			% [chosen["dpr"], chosen_best])


## Kətanın sıxlıq həddi: səviyyənin öz həddi, öyrənilən sıxlıq, aşağı hədd və yaddaş.
static func _test_web_dpr_limits() -> void:
	var keep := [Net.quality, Settings.auto_dpr, Settings.quality_chosen, Settings.fps_cap,
		Settings.fps_chosen, Settings.auto_quality, Net.nickname, int(Net.species), int(Net.mode)]
	Net.quality = Const.Quality.MINIMUM
	Settings.auto_dpr = 0.0
	_check(is_equal_approx(Settings.web_dpr(), Settings.WEB_MIN_DPR), "MİNİMUM: öyrənilmə yoxdursa 1.25")
	Settings.auto_dpr = 0.9
	_check(is_equal_approx(Settings.web_dpr(), 0.9), "MİNİMUM: öyrənilən 0.90 işlədilir")
	Settings.auto_dpr = 0.3
	_check(is_equal_approx(Settings.web_dpr(), Settings.WEB_FLOOR_DPR), "aşağı həddən (0.75) aşağı enmir")
	Settings.auto_dpr = 1.8
	_check(is_equal_approx(Settings.web_dpr(), Settings.WEB_MIN_DPR), "səviyyənin həddindən yuxarı qalxmır")
	Net.quality = Const.Quality.HIGH
	_check(is_equal_approx(Settings.web_dpr(), 1.8), "YÜKSƏK: öyrənilən 1.80 işlədilir")
	Settings.auto_dpr = 0.0
	_check(is_equal_approx(Settings.web_dpr(), Settings.WEB_MAX_DPR), "YÜKSƏK: öyrənilmə yoxdursa 2.0")
	_check(is_equal_approx(Settings.device_dpr(), 1.0), "brauzer deyil — ekran sıxlığı 1")

	var path := "user://_test_dpr.cfg"
	var cfg := ConfigFile.new()
	cfg.set_value("video", "auto_dpr", 0.9)
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(is_equal_approx(Settings.auto_dpr, 0.9), "öyrənilən sıxlıq növbəti açılışda qalır")
	cfg.set_value("video", "auto_dpr", 7.0)
	cfg.save(path)
	Settings.load_from_disk(path)
	_check(Settings.auto_dpr <= Settings.WEB_MAX_DPR, "fayldakı yad dəyər həddə kəsilir (%.2f)" % Settings.auto_dpr)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Net.quality = keep[0]
	Settings.auto_dpr = keep[1]
	Settings.quality_chosen = keep[2]
	Settings.fps_cap = keep[3]
	Settings.fps_chosen = keep[4]
	Settings.auto_quality = keep[5]
	Net.nickname = keep[6]
	Net.species = Const.species_from(keep[7])
	Net.mode = Const.mode_from(keep[8])


## Kölgə formanı TƏKRAR qurmur — hadisəsiz kadrda gövdə ilə eyni formadır.
##
## [method GermVisual._draw] formanı bir dəfə hesablayır və hadisə yoxdursa
## kölgə üçün də onu işlədir. Test bunun görüntünü DƏYİŞMƏDİYİNİ yoxlayır: hər
## növdə iki forma nöqtə-nöqtə eynidir; zərbə anında isə fərqlidir və kölgə
## öz formasını alır.
static func _test_germ_shape_reuse() -> void:
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		var g := GermVisual.new()
		g.setup(0, "A", false, kind)
		for i in 20:
			g.apply(Vector2(float(i) * 2.0, 0.0), 0.0, 6, 12, false, true)
			g._process(1.0 / 60.0)
		var r := Const.germ_radius(12)
		var same := g._shape_ring(r, true) == g._shape_ring(r, false)
		_check(g._shape_steady() and same,
			"növ %d: sakit formada kölgə gövdə ilə eynidir" % int(kind))
		g.flash(0.0)
		_check(not g._shape_steady(), "növ %d: zərbə anında kölgə ayrıca qurulur" % int(kind))
		g.free()


## AŞAĞI keyfiyyətdə rəqib iki kadrda bir çəkilir; öz mikrobun və zərbə — hər kadr.
static func _test_germ_redraw_rate() -> void:
	var g := GermVisual.new()
	g.setup(1, "B", false, Const.Species.CILIATE)
	g.redraw_step = 2
	var due := 0
	for i in 10:
		if g._redraw_due():
			due += 1
	_check(due == 5, "rəqib iki kadrda bir çəkilir (10 kadrda %d)" % due)
	g.flash(0.0)
	due = 0
	for i in 4:
		if g._redraw_due():
			due += 1
	_check(due == 4, "zərbə anında hər kadr çəkilir (%d / 4)" % due)
	# Ekrana qayıdan mikrob növbəsini gözləmədən çəkilir.
	g._flash = 0.0
	g._hit_squash_t = 0.0
	g.on_screen = false
	g.on_screen = true
	_check(g._redraw_due(), "ekrana qayıdan mikrob elə həmin kadr çəkilir")
	g.free()

	var me := GermVisual.new()
	me.setup(0, "Sən", true, Const.Species.CILIATE)
	me.redraw_step = 2
	due = 0
	for i in 6:
		if me._redraw_due():
			due += 1
	_check(due == 6, "öz mikrobun həmişə hər kadr çəkilir (%d / 6)" % due)
	me.free()


## Dairələr bir çəkiliş çağırışına yığılır (bax [BatchDraw]).
##
## Zəif telefonda brauzerin ən böyük xərci çəkiliş çağırışlarıdır: hər
## `draw_circle` ayrıca poliqon, buferi və çağırışıdır. Kadrda ən çox çəkilən
## yerlərə (mikrob, minimap, partlayış damcıları, nişan nöqtələri) yenidən
## `draw_circle` yazılsa, bu test xəbər verir.
static func _test_batch_draw() -> void:
	var pts := BatchDraw.ring_points(Vector2(10, -4), 7.0, 0.0, TAU, 16)
	_check(pts.size() == 30, "halqa: 16 nöqtə = 15 seqment (%d nöqtə)" % pts.size())
	var on_circle := true
	var joined := true
	for i in pts.size():
		on_circle = on_circle and absf(pts[i].distance_to(Vector2(10, -4)) - 7.0) < 0.001
		if i % 2 == 1 and i + 1 < pts.size():
			joined = joined and pts[i].is_equal_approx(pts[i + 1])
	_check(on_circle and joined and pts[0].is_equal_approx(pts[pts.size() - 1]),
		"halqa: seqmentlər dairənin üstündədir, bitişikdir və qapanır")
	var arc := BatchDraw.ring_points(Vector2.ZERO, 5.0, 0.0, PI * 0.5, 3)
	_check(arc.size() == 4 and arc[3].is_equal_approx(Vector2(0, 5)),
		"qövs: son nöqtə bucağın sonundadır")

	var imp := ConfigFile.new()
	_check(imp.load("res://assets/sprites/disc.png.import") == OK
		and bool(imp.get_value("params", "mipmaps/generate", false)),
		"disk teksturası mipmap ilə idxal olunur — 3 piksellik nöqtə pilləsiz çıxsın")

	for path in ["res://scripts/client/germ_visual.gd", "res://scripts/client/minimap.gd",
			"res://scripts/client/burst_fx.gd", "res://scripts/client/aim_guide.gd"]:
		var src := FileAccess.get_file_as_string(path)
		_check(not src.is_empty() and not src.contains("draw_circle("),
			"%s: kadrda çəkilən dairələr BatchDraw ilədir, `draw_circle` yoxdur" % path.get_file())


## Kadr həddi: kadr büdcəsini hesablayan kod `Engine.max_fps`-i yox,
## [method Settings.frame_cap]-i oxuyur — brauzerdə `Engine.max_fps` 0-dır və
## hədd səhifədədir (bax [method Settings._apply_frame_cap]).
static func _test_frame_cap() -> void:
	var keep := Engine.max_fps
	Settings._apply_frame_cap(30)
	_check(Engine.max_fps == 30 and Settings.frame_cap() == 30,
		"brauzer deyil: hədd Godot-un özündədir (%d / %d)" % [Engine.max_fps, Settings.frame_cap()])
	Settings._apply_frame_cap(0)
	_check(Settings.frame_cap() == 0, "həddsiz: 0")
	Engine.max_fps = keep
	var src := FileAccess.get_file_as_string("res://scripts/client/arena.gd")
	_check(not src.is_empty() and not src.contains("Engine.max_fps"),
		"arena kadr büdcəsini Settings.frame_cap()-dan oxuyur, Engine.max_fps-dən yox")


## Mikrobun GPU yolu (bax [GermGPU]): shader və skript EYNİ sətir quruluşunu,
## eyni qat nömrələrini və eyni uniform adlarını işlədir. Biri dəyişib o biri
## unudulsa, shader səhv texeli oxuyur və ya uniform sıfır qalır — xəta yox,
## sadəcə yanlış şəkil çıxır, ona görə tutmaq lazımdır.
static func _test_germ_gpu_contract() -> void:
	var src := FileAccess.get_file_as_string("res://shaders/germ.gdshader")
	var shape := FileAccess.get_file_as_string("res://shaders/germ_shape.gdshader")
	var consts := (GermGPU as Script).get_script_constant_map()
	var differ := []
	for key: String in consts:
		if key.begins_with("L_") or key in ["RING0", "SRING0", "LEGS0", "COL_MID", "COL_SMID"]:
			if not src.contains("const int %s = %d;" % [key, consts[key]]):
				differ.append(key)
	# Kontur keçidi eyni sütunlara yazır və eyni sabit nöqtə kodunu işlədir.
	for pair in [["COL_SHADOW", GermGPU.SRING0], ["COL_MID", GermGPU.COL_MID],
			["COL_SMID", GermGPU.COL_SMID]]:
		if not shape.contains("const int %s = %d;" % pair):
			differ.append("germ_shape:" + str(pair[0]))
	for line in ["const float RANGE = 256.0;", "const float STEPS = 128.0;"]:
		if not src.contains(line) or not shape.contains(line):
			differ.append(line)
	_check(not src.is_empty() and not shape.is_empty() and differ.is_empty(),
		"shader-lər və GermGPU eyni sütunları, qat nömrələrini və kodu işlədir (fərqli: %s)" % str(differ))

	var gd := FileAccess.get_file_as_string("res://scripts/client/germ_gpu.gd")
	var written := {}
	for m in RegEx.create_from_string("set_shader_parameter\\(\"(\\w+)\"").search_all(gd):
		written[m.get_string(1)] = true
	var unset := []
	for code: String in [src, shape]:
		for m in RegEx.create_from_string("\\nuniform \\w+ (\\w+)").search_all(code):
			if not written.has(m.get_string(1)):
				unset.append(m.get_string(1))
	var unknown := []
	for name: String in written:
		var known := false
		for code: String in [src, shape]:
			known = known or code.contains(" %s;" % name) or code.contains(" %s :" % name) \
				or code.contains(" %s =" % name)
		if not known:
			unknown.append(name)
	_check(unset.is_empty() and unknown.is_empty() and written.size() > 20,
		"hər uniform yazılır və yazılan hər ad shader-də var (yazılmayan %s, naməlum %s)"
			% [str(unset), str(unknown)])
	# Kontur keçidinin öz dünyası olmalıdır: yoxsa arenanın WorldEnvironment-i (glow,
	# tonemap) onun kodlanmış baytlarına tətbiq olunur və bütün konturlar zibilə dönür.
	_check(gd.contains("_shape_pass.own_world_3d = true") and gd.contains("_shape_pass.use_hdr_2d = false"),
		"kontur keçidi öz dünyasındadır və 8 bitlik hədəfdir (mühit ona sızmır)")

	# Sığır: kontur ən çox 44 nöqtə (hədəfdə bir texel bir nöqtə), ayaqlar ən çox 13.
	_check(GermVisual.CRAWL_POINTS <= GermGPU.SRING0 - GermGPU.RING0
		and GermVisual.MEMBRANE_POINTS <= GermGPU.SRING0 - GermGPU.RING0
		and GermGPU.SRING0 + GermVisual.CRAWL_POINTS <= GermGPU.COL_MID
		and GermGPU.COL_SMID < GermGPU.OUT_WIDTH
		and GermGPU.LEGS0 + GermVisual.LEGS_MAX <= GermGPU.WIDTH,
		"kontur, kölgə konturu, mərkəzlər və ayaqlar yerinə sığır")


## Sətir GDScript yolunun EYNİ vəziyyətidir: konturun ədədləri köhnə yolun öz
## funksiyalarından gəlir (_membrane_args, _crawl_scalars, _event_params,
## Sim.hit_shape, _eject_strain), ayaqların ucları eyni addımdan. Konturun özünü
## GPU qurur — onun GDScript konturu ilə fərqi `--germ-bench --bench-verify` ilə
## ölçülür (2026-10-18: hər növdə ≤ 0.006 px, yəni sabit nöqtə addımının yarısı).
static func _test_germ_gpu_rows() -> void:
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		var g := GermVisual.new()
		g.setup(3, "A", false, kind)
		g.hit_fit = true
		var cap := 30
		var r := Const.germ_radius(cap)
		for i in 50:
			g.net_vel = Vector2(Const.germ_speed(cap), 0.0)
			g.apply(Vector2(float(i) * 2.5, 0.0), 0.4, 9, cap, false, true)
			g._process(1.0 / 60.0)
		# Atəşin ilk kadrı: həm membranın dartılması, həm gövdənin sıxılması işləyir.
		g.eject(0.4)
		g._process(1.0 / 60.0)
		g.is_ally = true

		var bytes := g.gpu_row_bytes()
		var f := bytes.to_float32_array()
		var amoeba: bool = kind == Const.Species.AMOEBA
		var e := g._event_params(r)
		var hit := Sim.hit_shape(int(kind), cap, g.net_vel)
		var push := r * GermVisual.EJECT_DEPTH * g._eject_strain()
		var head := bytes.size() == GermGPU.WIDTH * GermGPU.TEXEL and is_equal_approx(f[0], r) \
			and int(f[8]) == (GermVisual.CRAWL_POINTS if amoeba else GermVisual.MEMBRANE_POINTS) \
			and _near(f[14], g.aim) and int(f[15]) == int(kind) and f[43] == 1.0 and f[46] == 1.0 \
			and _near(f[47], g._super_fade)
		_check(head, "növ %d: sətir — radius, nöqtə sayı, nişan, növ, yoldaş və ellips bayrağı" % int(kind))
		var events: bool = _near(f[48], hit.x) and _near(f[49], hit.y) and _near(f[50], hit.z) \
			and push != 0.0 and _near(f[51], push) \
			and e[0] != Vector2.ZERO and _near(f[52], e[0].x) and _near(f[53], e[0].y) \
			and _near(f[54], e[1]) and _near(f[55], e[2]) \
			and _near(f[56], e[3].x) and _near(f[57], e[3].y) and _near(f[58], e[4]) \
			and _near(f[59], e[5]) and _near(f[60], e[6].x) and _near(f[61], e[6].y)
		_check(events, "növ %d: sətir — toqquşma ellipsi, atəş dartılması, hadisə deformasiyası" % int(kind))
		var form := false
		if amoeba:
			var c := g._crawl_scalars(r, g._heading(), g._rush(), 1.0, g._accel_bonus(), g._base_stretch_cap())
			var plain := g._crawl_scalars(r, g._heading(), g._rush(), 1.0, 0.0, GermVisual.TOTAL_STRETCH_MAX)
			var head_c: Vector2 = c["head_c"]
			var tail_c: Vector2 = c["tail_c"]
			form = _near(f[62], c["pull"]) and _near(f[63], plain["pull"]) \
				and _near(f[64], head_c.x) and _near(f[65], head_c.y) \
				and _near(f[66], tail_c.x) and _near(f[67], tail_c.y) \
				and _near(f[68], c["head_r"]) and _near(f[69], c["body_r"]) \
				and _near(f[70], c["tail_r"]) and _near(f[71], c["spread"]) \
				and _near(f[75], c["flow"]) and _near(f[76], c["flow_mean"])
		else:
			var m := g._membrane_args()
			form = _near(f[62], GermVisual._stretch(m[2], g._accel_bonus(), g._base_stretch_cap())) \
				and _near(f[63], GermVisual._stretch(m[2], 0.0, GermVisual.TOTAL_STRETCH_MAX)) \
				and _near(f[64], m[0]) and _near(f[65], fposmod(g._t * m[1], TAU)) \
				and _near(f[66], fposmod(g._t * m[1] * 0.7, TAU)) and _near(f[67], m[3])
		_check(form, "növ %d: sətir — formanın ədədləri köhnə yolun funksiyalarındandır" % int(kind))
		if kind == Const.Species.HELIOZOAN:
			var legs := int(f[44])
			var feet := legs == g._legs and legs >= GermVisual.LEGS_MIN
			for i in legs:
				var o := GermGPU.LEGS0 * 4 + i * 4
				feet = feet and Vector2(f[o], f[o + 1]).distance_to(g._leg_tip(i, r)) < 0.001 \
					and (f[o + 2] == 1.0) == (g._step[i] >= 1.0)
			_check(feet, "ayaqlı: %d ayağın ucu və addım vəziyyəti sətirdədir" % legs)
		g.free()


static func _near(a: float, b: float) -> bool:
	return absf(a - b) <= 0.0001 * maxf(1.0, absf(b))


## Konturun GDScript riyaziyyatı dəyişsə, GPU onu özü bilmir — shaders/germ_shape.gdshader
## həmin formulların əl ilə yazılmış surətidir və səssizcə KÖHNƏ formanı çəkərdi.
## Test həmin funksiyaların mətninin (şərhsiz) izini saxlayır: iz dəyişəndə düşür.
## Onda: shader-i də uyğunlaşdır, `--germ-bench --bench-verify` ilə fərqin 0.01 px-dən
## az olduğunu yoxla, sonra buradakı izi yenilə.
const GPU_SHAPE_SOURCE_MD5 := "e194d36be89bdb4148fe9cb72d341fed"
## Superin görünüşü də eyni qaydadadır: _draw_cyst / _draw_net dəyişsə, shaders/germ.gdshader-in
## L_CYST_* / L_NET_* qatlarını da uyğunlaşdır, `--bench-render pair` ilə yan-yana yoxla.
const GPU_SUPER_SOURCE_MD5 := "83921676b8ed134913734599216fe666"


static func _test_germ_gpu_shape_sync() -> void:
	var shape := _source_md5(["_membrane_args", "_membrane", "_stretch", "_crawl_body",
		"_crawl_scalars", "_smooth_ring", "_reach", "_fit_hit", "_strain", "_eject_strain",
		"_eject_cross", "_event_deform", "_event_params", "_axis_transform",
		"_uniform_transform", "_shift", "_ring_centre", "_ring_area", "_birth_scale",
		"_shape_ring", "_accel_bonus", "_base_stretch_cap"])
	_check(shape[1].is_empty() and shape[0] == GPU_SHAPE_SOURCE_MD5,
		"konturun GDScript kodu GPU surəti ilə uyğundur (iz %s; tapılmayan %s) — dəyişibsə germ_shape.gdshader-i yenilə, --bench-verify ilə yoxla, izi dəyiş"
			% [shape[0], str(shape[1])])
	var sup := _source_md5(["_draw_super", "_draw_cyst", "_draw_net"])
	_check(sup[1].is_empty() and sup[0] == GPU_SUPER_SOURCE_MD5,
		"superin GDScript görünüşü GPU surəti ilə uyğundur (iz %s; tapılmayan %s) — dəyişibsə germ.gdshader-in super qatlarını yenilə, --bench-render pair ilə yoxla, izi dəyiş"
			% [sup[0], str(sup[1])])


## Su zərrəciklərinin hərəkəti GPU-dadır (shaders/water_motes.gdshader) — axın sahəsi
## (`Const.current_at`), Eyler addımı, kənardan keçmə, toxum heşi və cizginin
## həndəsəsi GDScript yolunun əl ilə yazılmış surətidir. Onlardan biri dəyişsə iz
## düşür: shader-i də uyğunlaşdır, `--germ-bench --bench-motes` ilə iki yarımın
## eyni olduğunu yoxla (2026-10-19: GL-də ən böyük fərq 1/255, ANGLE-də 0 — həm
## `--fixed-fps` ilə, həm dəyişkən kadrlarla; brauzerdə də), izi dəyiş.
const MOTES_SOURCE_MD5 := "cafcae5d2312a0b9c6c4b8e770f5fb58"


static func _test_water_motes_gpu() -> void:
	var src := FileAccess.get_file_as_string("res://shaders/water_motes.gdshader")
	var gd := FileAccess.get_file_as_string("res://scripts/client/water_motes.gd")
	var written := {}
	for m in RegEx.create_from_string("set_shader_parameter\\(\"(\\w+)\"").search_all(gd):
		written[m.get_string(1)] = true
	var unset := []
	for m in RegEx.create_from_string("\\nuniform \\w+ (\\w+)").search_all(src):
		if not written.has(m.get_string(1)):
			unset.append(m.get_string(1))
	var unknown := []
	for name: String in written:
		if not src.contains(" %s;" % name) and not src.contains(" %s :" % name):
			unknown.append(name)
	_check(src.contains("shader_type particles;") and unset.is_empty() and unknown.is_empty()
			and written.size() >= 12,
		"su zərrəciklərinin shader-i: hər uniform yazılır, yazılan hər ad shader-dədir (yazılmayan %s, naməlum %s)"
			% [str(unset), str(unknown)])
	var flow := _source_md5(["current_at"], "res://scripts/shared/constants.gd")
	var motes := _source_md5(["_process", "_draw", "_scatter", "_rand01", "_mote_color",
		"_line_width"], "res://scripts/client/water_motes.gd")
	var print_md5: String = (str(flow[0]) + str(motes[0])).md5_text()
	_check(flow[1].is_empty() and motes[1].is_empty() and print_md5 == MOTES_SOURCE_MD5,
		"su zərrəciklərinin GDScript qaydası GPU surəti ilə uyğundur (iz %s; tapılmayan %s) — dəyişibsə water_motes.gdshader-i yenilə, --bench-motes ilə yoxla, izi dəyiş"
			% [print_md5, str(flow[1] + motes[1])])


## GDScript yolu (`--motes-cpu`, stendin sol yarısı): heş 0..1 aralığında bərabər
## paylanır, zərrəciklər kamera hərəkət etsə də görüş kvadratından çıxmır.
static func _test_water_motes_cpu() -> void:
	var sum := 0.0
	var inside := true
	for i in 2000:
		var v := WaterMotes._rand01(i)
		inside = inside and v >= 0.0 and v <= 1.0
		sum += v
	_check(inside and absf(sum / 2000.0 - 0.5) < 0.03,
		"zərrəcik heşi 0..1 aralığındadır və bərabər paylanır (orta %.3f)" % (sum / 2000.0))
	var m := WaterMotes.new()
	m.use_gpu = false
	m.count = 60
	m.fixed_seed = 5
	m.span = 500.0
	m.rebuild()
	var half := m.span * WaterMotes.FIELD_FACTOR
	var kept := m._pos.size() == 60
	for step in 240:
		m.focus = Vector2(float(step) * 6.0, sin(float(step) * 0.05) * 300.0)
		m._process(1.0 / 60.0)
		for p in m._pos:
			var d: Vector2 = p - m.focus
			kept = kept and absf(d.x) <= half + 0.001 and absf(d.y) <= half + 0.001
	var twin := WaterMotes.new()
	twin.use_gpu = false
	twin.count = 60
	twin.fixed_seed = 5
	twin.span = 500.0
	twin.rebuild()
	var same := twin._pos.size() == 60
	var fresh := WaterMotes.new()
	fresh.use_gpu = false
	fresh.count = 60
	fresh.fixed_seed = 5
	fresh.span = 500.0
	fresh.rebuild()
	for i in 60:
		same = same and twin._pos[i] == fresh._pos[i] and twin._seed[i] == fresh._seed[i]
	_check(kept and same,
		"GDScript zərrəcikləri görüş kvadratında qalır, eyni toxum eyni düzümü verir")
	m.free()
	twin.free()
	fresh.free()


## Superin açılış effekti GPU-dadır (shaders/super_fx.gdshader) — disk, iynələr,
## halqalar, lövhələr və parıltı super_fx.gd-dəki `_draw_*` funksiyalarının əl ilə
## yazılmış surətidir. Onlardan biri dəyişsə iz düşür: shader-i də uyğunlaşdır,
## `--germ-bench --bench-superfx --bench-render pair` ilə yarımları müqayisə et
## (2026-10-19: yalnız böyük halqanın 0° tikişində 2 sətir piksel fərqli), izi dəyiş.
const SUPER_FX_SOURCE_MD5 := "387e29cefafe0be0a296a46c9841dfab"


static func _test_super_fx_gpu() -> void:
	var src := FileAccess.get_file_as_string("res://shaders/super_fx.gdshader")
	var gd := FileAccess.get_file_as_string("res://scripts/client/super_fx.gd")
	var written := {}
	for m in RegEx.create_from_string("set_shader_parameter\\(\"(\\w+)\"").search_all(gd):
		written[m.get_string(1)] = true
	var unset := []
	for m in RegEx.create_from_string("\\nuniform \\w+ (\\w+)").search_all(src):
		if not written.has(m.get_string(1)):
			unset.append(m.get_string(1))
	var unknown := []
	for name: String in written:
		if not src.contains(" %s;" % name):
			unknown.append(name)
	var consts := (SuperFx as Script).get_script_constant_map()
	var differ := []
	for key: String in consts:
		if key.begins_with("L_") or key in ["CIRCLE_SEGMENTS", "RING_POINTS"]:
			if not src.contains("const int %s = %d;" % [key, consts[key]]):
				differ.append(key)
	_check(unset.is_empty() and unknown.is_empty() and differ.is_empty() and written.size() >= 13,
		"super effektinin shader-i: uniform-lar və qat nömrələri skriptlə eynidir (yazılmayan %s, naməlum %s, fərqli %s)"
			% [str(unset), str(unknown), str(differ)])
	var draw := _source_md5(["_fade", "_ease_out", "_draw_trichocyst", "_draw_opening",
		"_draw_snap", "_draw_flash"], "res://scripts/client/super_fx.gd")
	_check(draw[1].is_empty() and draw[0] == SUPER_FX_SOURCE_MD5,
		"super effektinin GDScript görünüşü GPU surəti ilə uyğundur (iz %s; tapılmayan %s) — dəyişibsə super_fx.gdshader-i yenilə, --bench-superfx ilə yoxla, izi dəyiş"
			% [draw[0], str(draw[1])])
	# Mesh-in qatları `_draw`-dakı sıradadır (GPU üçbucaqları sıra ilə çəkir).
	var ordered := true
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		var arrays := SuperFx._mesh_for(kind, SuperFx.NEEDLES_HIGH).surface_get_arrays(0)
		var verts: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
		var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var last := 0
		for i in range(0, tris.size(), 3):
			var layer := int(verts[tris[i]].x)
			ordered = ordered and layer >= last and layer == int(verts[tris[i + 1]].x) \
				and layer == int(verts[tris[i + 2]].x)
			last = layer
	_check(ordered, "super effektinin mesh-i: hər üçbucaq bir qatdadır, qatlar çəkiliş sırasındadır")


## Faylın funksiyalarının şərhsiz mətninin izi: `[md5, tapılmayanlar]`.
static func _source_md5(names: Array, path := "res://scripts/client/germ_visual.gd") -> Array:
	var lines := FileAccess.get_file_as_string(path).split("\n")
	var code := ""
	var missing := []
	for name: String in names:
		var start := -1
		for i in lines.size():
			if lines[i].begins_with("func %s(" % name) or lines[i].begins_with("static func %s(" % name):
				start = i
				break
		if start < 0:
			missing.append(name)
			continue
		var i := start
		while i < lines.size():
			var line := lines[i].strip_edges(false, true)
			if i > start and not line.is_empty() and not line.begins_with("\t") \
					and not line.begins_with("#"):
				break
			var bare := line.strip_edges()
			if not bare.is_empty() and not bare.begins_with("#"):
				code += line + "\n"
			i += 1
	return [code.md5_text(), missing]


## Mesh-lərin üçbucaqları düzgündür: indekslər hədd daxilində, hər üçbucaq TƏK
## qatdadır və qatlar artan sırada gəlir — GPU üçbucaqları sıra ilə çəkir, yəni
## bu, GDScript yolundakı çəkiliş sırasının özüdür.
static func _test_germ_gpu_mesh() -> void:
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		for front in [false, true]:
			var arrays: Array = GermGPU.front_arrays(kind) if front else GermGPU.body_arrays(kind)
			var verts: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX]
			var tris: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var valid := tris.size() > 0 and tris.size() % 3 == 0 and verts.size() < 65536
			var single := true
			var ordered := true
			var layers := {}
			var last := 0
			for t in tris.size() / 3:
				var a := tris[t * 3]
				var b := tris[t * 3 + 1]
				var c := tris[t * 3 + 2]
				if mini(a, mini(b, c)) < 0 or maxi(a, maxi(b, c)) >= verts.size():
					valid = false
					break
				var layer := int(verts[a].x)
				single = single and int(verts[b].x) == layer and int(verts[c].x) == layer
				ordered = ordered and layer >= last
				last = layer
				layers[layer] = true
			_check(valid and single and ordered,
				"növ %d, %s mesh: %d təpə, üçbucaqlar tək qatda və çəkiliş sırası ilə"
					% [int(kind), "ön" if front else "gövdə", verts.size()])
			if not front:
				var cilia := layers.has(GermGPU.L_CILIA)
				var legs := layers.has(GermGPU.L_LEG_DARK) and layers.has(GermGPU.L_SKELETON)
				var gel := layers.has(GermGPU.L_SKIN2) and layers.has(GermGPU.L_OUTLINE2)
				_check(cilia == (kind == Const.Species.CILIATE)
					and legs == (kind == Const.Species.HELIOZOAN)
					and gel == (kind == Const.Species.AMOEBA)
					and layers.has(GermGPU.L_CORE) != (kind == Const.Species.AMOEBA),
					"növ %d: hərəkət orqanı və qatlar yalnız öz növündədir" % int(kind))
			else:
				var cyst := layers.has(GermGPU.L_CYST_SHELL) and layers.has(GermGPU.L_CYST_SEAM)
				var net := layers.has(GermGPU.L_NET_EDGE) and layers.has(GermGPU.L_NET_TIP)
				_check(cyst == (kind == Const.Species.AMOEBA)
					and net == (kind == Const.Species.HELIOZOAN)
					and layers.has(GermGPU.L_ALLY) and layers.has(GermGPU.L_FLASH),
					"növ %d: ön qatda super yalnız öz növündədir (qabıq / tor)" % int(kind))


## GPU gövdəni öz mərkəzindən YELPİKLƏ doldurur, Godot isə çoxbucaqlını
## üçbucaqlara bölürdü. İkisi yalnız forma o mərkəzə görə ULDUZVARİ olanda eynidir:
## yoxsa yelpiyin bəzi üçbucaqları tərsinə çevrilir və siluetdən bayıra rəng
## tökülür. Hər üç növ sürətlənmə, döngə, dayanma, zərbə, atəş, doluluq və doğuş
## zamanı yoxlanılır — gövdə, kölgə, amöbün iç qatı və işıq qatı.
static func _test_germ_gpu_fans() -> void:
	for kind in [Const.Species.CILIATE, Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
		for cap in [10, 30, 60]:
			var g := GermVisual.new()
			g.setup(2, "A", false, kind)
			g.hit_fit = true
			g._birth_t = 0.0
			var r := Const.germ_radius(cap)
			var top := Const.germ_speed(cap)
			var dt := 1.0 / 60.0
			var pos := Vector2.ZERO
			var heading := 0.0
			var bad := 0
			var first := ""
			var frames := 420
			for i in frames:
				# Dayanma → sürətlənmə → döngələr → tam sürət → yavaş geri dönüş.
				var pace := clampf(float(i) * dt - 0.5, 0.0, 1.0) if i < 300 else 0.25
				heading += 0.09 if i % 90 < 30 else -0.025
				var vel := Vector2.from_angle(heading) * top * pace
				pos += vel * dt
				g.net_vel = vel
				var fill := 0.1 + 0.9 * float(i % 140) / 139.0
				g.apply(pos, heading + 1.1, int(round(fill * float(cap))), cap, false, true)
				if i % 23 == 7:
					g.flash(heading + 2.0)
				if i % 31 == 11:
					g.eject(heading + 0.6)
				g._process(dt)
				var broken := _gpu_fans_broken(g, r)
				if not broken.is_empty():
					bad += 1
					if first.is_empty():
						first = " — ilki kadr %d: %s (doğuş %.2f, zərbə %.2f, atəş %.2f, sürət %.2f)" % [
							i, broken, g._birth_t, g._hit_squash_t, g._eject_t, g._rush()]
			_check(bad == 0, "GPU yelpiyi: növ %d, tutum %d — gövdə hər kadr öz mərkəzinə görə ulduzvaridir (%d / %d kadr pozuldu%s)"
				% [int(kind), cap, bad, frames, first])
			g.free()


## Yelpiyi pozulan qatların adları; boşdursa hamısı düzgündür.
static func _gpu_fans_broken(g: GermVisual, r: float) -> String:
	var shape := g._shape_ring(r, true)
	var shadow := shape if g._shape_steady() else g._shape_ring(r, false)
	var ring := g._fit_hit(g._event_deform(g._strain(shape), r))
	var mid := GermVisual._ring_centre(ring)
	var out := []
	if not _star_shaped(ring, mid):
		out.append("gövdə")
	if not _star_shaped(shadow, GermVisual._ring_centre(shadow)):
		out.append("kölgə")
	var lit := _lit_fan_broken(ring, mid, r)
	if not lit.is_empty():
		out.append("işıq " + lit)
	if g.species == Const.Species.AMOEBA:
		var inner := GermVisual._inset(ring,
			maxf(r * GermVisual.CRAWL_BAND, GermVisual.CRAWL_BAND_MIN))
		if not _star_shaped(inner, mid):
			out.append("iç qat")
		lit = _lit_fan_broken(inner, GermVisual._ring_centre(inner), r)
		if not lit.is_empty():
			out.append("iç işıq " + lit)
	return ", ".join(out)


## İşıq qatı: shader hər sürüşdürülmüş nöqtəni yelpiyin mərkəzindən çıxan şüa
## boyunca gövdəyə sıxır, ona görə mərkəz HƏR İKİ konturun içində olmalı, iki
## kontur da ona görə ulduzvari olmalıdır. Mərkəz konturlardan birinin xaricinə
## düşəndə shader qatı çəkmir — onda CPU-nun kəsişməsi də boş (və ya bir-iki
## piksel) olmalıdır.
## shader-dəki `lit_centre`: namizədlər arasından iki konturun da bütöv göründüyü
## ilk nöqtə (z = 1), yoxsa ikisinin də içində olan ilk nöqtə (z = 0.5), yoxsa heç
## nə (z = 0). Namizədlər shader-in öz mətnindən oxunur — iki siyahı ayrıla bilməz.
static func _gpu_lit_centre(ring: PackedVector2Array, shifted: PackedVector2Array,
		cen: Vector2, r: float) -> Vector3:
	var side := Vector2(-Palette.LIGHT_DIR.y, Palette.LIGHT_DIR.x)
	var lens := cen + Palette.LIGHT_DIR * (r * (GermVisual.LIT_SHIFT + GermVisual.LIT_INSET) * 0.5)
	var fallback := Vector3(lens.x, lens.y, 0.0)
	for off: Vector2 in _lit_candidates():
		var c := lens + (Palette.LIGHT_DIR * off.x + side * off.y) * r
		if not Geometry2D.is_point_in_polygon(c, ring) or not Geometry2D.is_point_in_polygon(c, shifted):
			continue
		if _star_shaped(ring, c) and _star_shaped(shifted, c):
			return Vector3(c.x, c.y, 1.0)
		if fallback.z == 0.0:
			fallback = Vector3(c.x, c.y, 0.5)
	return fallback


static var _candidates := PackedVector2Array()


static func _lit_candidates() -> PackedVector2Array:
	if _candidates.is_empty():
		var src := FileAccess.get_file_as_string("res://shaders/germ.gdshader")
		var from := src.find("LIT_CANDIDATES[")
		var block := src.substr(from, src.find(");", from) - from)
		for m in RegEx.create_from_string("vec2\\((-?[0-9.]+), (-?[0-9.]+)\\)").search_all(block):
			_candidates.append(Vector2(float(m.get_string(1)), float(m.get_string(2))))
	return _candidates


static func _lit_fan_broken(ring: PackedVector2Array, cen: Vector2, r: float) -> String:
	var shift := Palette.LIGHT_DIR * (r * GermVisual.LIT_SHIFT)
	var shifted := GermVisual._shift(GermVisual._inset(ring, r * GermVisual.LIT_INSET), shift)
	var c0 := _gpu_lit_centre(ring, shifted, cen, r)
	var cpu := GermVisual._lit_polygon(ring, r)
	var cpu_area := GermVisual._ring_area(cpu) if cpu.size() >= 3 else 0.0
	if c0.z == 0.0:
		# shader qatı çəkmir — CPU-nun kəsişməsi də boş (və ya bir-iki piksel) olmalıdır.
		return "" if cpu_area < 3.0 else "(linza tapılmadı, CPU %.0f px² çəkir)" % cpu_area
	if c0.z == 1.0:
		return ""
	# Ehtiyat mərkəz: şüa gövdədən ilk çıxışda kəsilir, yəni GPU çökəkliyin
	# arxasını bir az az örtür. Fərq CPU-nun dəqiq kəsişməsi ilə ölçülür.
	var gpu := _gpu_lit_emulated(ring, shifted, Vector2(c0.x, c0.y))
	var miss := 0.0
	for p in Geometry2D.clip_polygons(cpu, gpu):
		miss += GermVisual._ring_area(p)
	var spill := 0.0
	for p in Geometry2D.clip_polygons(gpu, cpu):
		spill += GermVisual._ring_area(p)
	return "" if miss < 2.0 and spill < 2.0 \
		else "(heç bir namizəd bütöv görmür: GPU %.1f px² az, %.1f px² artıq örtür)" % [miss, spill]


## shader-dəki `lit_pt`-in GDScript surəti: hər sürüşdürülmüş nöqtə c0-dan çıxan
## şüa boyunca gövdədən İLK çıxışa sıxılır.
static func _gpu_lit_emulated(ring: PackedVector2Array, shifted: PackedVector2Array,
		c0: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := ring.size()
	for s in shifted:
		var d := s - c0
		var ds := d.length()
		if ds < 0.0001:
			out.append(s)
			continue
		d /= ds
		var best := INF
		for j in n:
			var a := ring[j]
			var e := ring[(j + 1) % n] - a
			var den := d.cross(e)
			if absf(den) <= 0.000001:
				continue
			var w := a - c0
			var tt := w.cross(e) / den
			var u := w.cross(d) / den
			if tt > 0.0 and u >= 0.0 and u <= 1.0:
				best = minf(best, tt)
		out.append(c0 + d * minf(ds, best))
	return out


## Bütün (c, p_i, p_i+1) üçbucaqları eyni istiqamətdə fırlanır — yelpik
## çoxbucaqlını dəqiq örtür, heç yerdə ikiqat və ya bayıra çıxmır.
static func _star_shaped(pts: PackedVector2Array, c: Vector2) -> bool:
	var n := pts.size()
	var turn := 0.0
	for i in n:
		var cr := (pts[i] - c).cross(pts[(i + 1) % n] - c)
		if absf(cr) < 0.0001:
			continue
		if turn == 0.0:
			turn = signf(cr)
		elif signf(cr) != turn:
			return false
	return true


## Zərbə donması: animasiya dayanır, parıltının ömrü isə uzanmır.
static func _test_germ_hitstop() -> void:
	var g := GermVisual.new()
	g.setup(0, "A", false, Const.Species.CILIATE)
	g.apply(Vector2.ZERO, 0.0, 5, 10, false, true)
	g._process(1.0 / 60.0)
	var t0 := g._t
	g.flash()
	g._process(0.03)
	_check(is_equal_approx(g._t, t0), "zərbə donmasında animasiya dayanır")
	_check(g._flash < GermVisual.FLASH_TIME, "parıltının saatı donmada da axır")
	g._process(0.05)
	_check(g._t > t0 and g._hitstop == 0.0, "donma bitir, animasiya davam edir")
	g.free()




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
##
## Generator toxumlanır: botlar döyüşür və yoxlama anında biri təzəcə partlamış
## ola bilərdi — yeri növbəti [constant World.BOT_RESPAWN]-da dolur, amma yoxlama
## onu gözləmirdi və 6 çalışmanın birində "5 / 6" ilə düşdü.
static func _test_world_keeps_population() -> void:
	var world := World.new(3)
	world.sim.rng.seed = 3
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


## Amöbün superində QALXAN YOXDUR: ona top adi kimi dəyir.
##
## Əvvəl super toxunulmaz qabıq (kist) idi və top ondan səkirdi. Oyunçunun
## istəyi ilə indi miniqandır — yerində donub atır, amma qorunmur.
static func _test_minigun_no_shield() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	b.species = Const.Species.AMOEBA
	b.charge = Const.SUPER_MAX
	s._use_super(b)
	_check(b.in_cyst(), "amöbün superi işləyir (%.1f s qaldı)" % b.super_t)
	var before := b.balls
	_fire_once(s, a, 0.0, 24)
	_check(b.balls == before + Const.SHOT_PAYLOAD,
		"superdəki amöbə top dəyir — qalxan yoxdur (%d → %d)" % [before, b.balls])


## Amöbün superi — yerində donmuş MİNİQAN: atəş basılı qaldıqca
## [constant Const.MINIGUN_COOLDOWN]-da bir, toplar amöbün öz sayından GETMİR,
## geri təpmə onu tərpətmir. Super bitəndə adi atəş qaydası qayıdır.
static func _test_minigun_fires() -> void:
	var s := _fresh()
	var a: Sim.GermState = s.germs[A_ID]
	var b: Sim.GermState = s.germs[B_ID]
	a.species = Const.Species.AMOEBA
	a.charge = Const.SUPER_MAX
	a.balls = Const.MIN_BALLS        # ac amöb də atır — top pulsuzdur
	a.cooldown = 0.0
	s._use_super(a)
	# Hədəf partlamasın — yoxsa sayım yarıda kəsilərdi.
	b.capacity = 80
	var at := a.pos
	var b_at := b.pos
	var b_before := b.balls
	var fires := 0
	var drift := 0.0
	var ticks := roundi(Const.CYST_TIME / Const.TICK_DELTA)
	for i in ticks:
		# Hədəf yerində saxlanılır — axın onu atəş xəttindən çıxarmasın.
		b.pos = b_at
		b.vel = Vector2.ZERO
		# Həm hərəkət, həm atəş istənir: amöb yerində qalmalıdır.
		s.step({A_ID: Sim.PlayerInput.make(i + 1, Vector2.RIGHT, 0.0, true)}, Const.TICK_DELTA)
		for e in s.events:
			if String(e.get("t", "")) == "fire" and int(e["color"]) == a.color:
				fires += 1
		# Yalnız super işləyən tick-lər: son tick-də super bitir və hərəkət qayıdır.
		if a.in_cyst():
			drift = maxf(drift, a.pos.distance_to(at))
	var want := floori(Const.CYST_TIME / Const.MINIGUN_COOLDOWN)
	_check(fires >= want and fires <= want + 1,
		"miniqan fasiləsiz atır: %d atəş / %.1f s (gözlənilən ~%d)" % [fires, Const.CYST_TIME, want])
	_check(a.balls == Const.MIN_BALLS,
		"miniqanın topu öz sayından getmir (%d top)" % a.balls)
	_check(drift < 0.01,
		"amöb yerində qalır: nə hərəkət, nə geri təpmə (%.2f px)" % drift)
	_check(b.balls > b_before,
		"miniqanın topları rəqibə dəyir (%d → %d)" % [b_before, b.balls])

	# Superdən təzəcə adi atəş açılıb (soyuma 1 s): miniqan onu gözləmir.
	var s3 := _fresh()
	var d: Sim.GermState = s3.germs[A_ID]
	d.species = Const.Species.AMOEBA
	d.charge = Const.SUPER_MAX
	d.cooldown = Const.FIRE_COOLDOWN
	s3._use_super(d)
	var late := 0
	for i in ticks:
		s3.step({A_ID: Sim.PlayerInput.make(i + 1, Vector2.ZERO, 0.0, true)}, Const.TICK_DELTA)
		for e in s3.events:
			if String(e.get("t", "")) == "fire" and int(e["color"]) == d.color:
				late += 1
	_check(late >= want - 1,
		"adi atəşdən qalan soyuma miniqanı gecikdirmir (%d atəş, gözlənilən ~%d)" % [late, want])

	# Super bitdi — adi atəş: top xərclənir, dövr 1 s.
	var s2 := _fresh()
	var c: Sim.GermState = s2.germs[A_ID]
	c.species = Const.Species.AMOEBA
	c.balls = 7
	c.cooldown = 0.0
	s2.step({A_ID: Sim.PlayerInput.make(1, Vector2.ZERO, 0.0, true)}, Const.TICK_DELTA)
	_check(c.balls == 6 and is_equal_approx(c.cooldown, Const.FIRE_COOLDOWN),
		"supersiz amöbün atəşi adidir (top %d, dövr %.2f s)" % [c.balls, c.cooldown])


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
		var supers := 0
		# İki SABİT toxumlu dünya × 60 s: nəticə hər çalışmada eynidir.
		#
		# Əvvəl dünya təsadüfi idi və test bəzən səbəbsiz yanırdı. Ölçülüb (300
		# dünya × 60 s): bütün-amöb dünyasında super orta hesabla 4.4 dəfə olur,
		# amma 1.7% dünyada heç olmur — dəymə forması dəyişməzdən ƏVVƏL də belə
		# idi. Toxum dünyanın generatorundadır ([member Sim.rng]) və botları da
		# sabitləyir ([method World._add_bot]). İki dünya ona görədir ki, kodun
		# başqa yerindəki dəyişiklik trayektoriyanı dəyişəndə nadir "sıfır"
		# dünyası tək başına testi yandırmasın.
		for seed_no in [1, 2]:
			var world := World.new(1)
			world.sim.rng.seed = 1000 * seed_no + int(kind)
			for i in int(60.0 / Const.TICK_DELTA):
				world.tick(Const.TICK_DELTA)
				# Bütün dünya bir növdən: qarışıq dünyada bir növ təsadüfən heç
				# vaxt doğulmaya bilər.
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


## Ayaqlının toru və amöbün kisti ÖZ ekranında superin bütün müddəti qalır —
## gecikmə ilə də.
##
## [method Arena._reconcile] hər snapshot-da təsdiqlənməmiş girişləri yenidən
## oynadır. Canlı proqnoz həmin tick-lərin super sayğacını artıq azaltmışdı,
## yenidən oynatma isə onu İKİNCİ dəfə azaldırdı: ~200 ms gediş-gəlişdə hər
## snapshot sayğacdan 0.2 s yeyirdi və 4 saniyəlik tor ekranda ~0.7 s yaşayırdı
## (onlayn ölçülüb, bax `tools/super_probe.gd`). Server superi tam müddət
## işlədirdi, oyunçu isə effektin dərhal sönməsini görürdü — "ulti işləmir".
## Kist üstəlik proqnozda vaxtından əvvəl açılırdı: mikrob ekranda yeriyib geri
## dartılırdı. Kirpiklinin superi anidir, ona görə ona toxunmurdu.
static func _test_super_timer_survives_reconcile() -> void:
	# Gecikmə tick-lə, bir istiqamətdə: gediş-gəliş ~200 və ~530 ms.
	for lag in [3, 8]:
		for kind in [Const.Species.HELIOZOAN, Const.Species.AMOEBA]:
			_check_super_timer_online(kind, lag)


static func _check_super_timer_online(kind: Const.Species, lag: int) -> void:
	const PRESS := 30
	var saved := Net.species
	var world := World.new(81, Const.Mode.ENDLESS)
	var g := world.add_player(A_ID, "A", kind)
	g.balls = Const.START_BALLS
	g.charge = Const.SUPER_MAX
	Net.species = kind
	var a := Arena.new()
	a.my_id = A_ID
	a._init_prediction()
	var up := []          # [çatma tick-i, giriş]
	var down := []        # [çatma tick-i, snapshot]
	var srv_on := 0
	var cli_on := 0
	var cli_gaps := 0
	var was_on := false
	for t in 300:
		g.safe_t = 5.0    # botların topu testi pozmasın
		# Əvvəl çatan snapshot-lar — client kadrın əvvəlində barışır.
		var newest: Array = []
		while not down.is_empty() and int(down[0][0]) <= t:
			newest = down.pop_front()[1]
		if not newest.is_empty():
			newest[Const.Snap.GERMS] = Const.unpack_germs(newest[Const.Snap.GERMS])
			var me_self: Array = newest[Const.Snap.SELF]
			a._srv_rep = int(me_self[2]) if me_self.size() > 2 else -1
			a._anchor = Vector4(float(me_self[3]), float(me_self[4]),
				float(me_self[5]), float(me_self[6])) if me_self.size() > 6 else Vector4.INF
			a._last_snap = newest
			a._snap_tick = int(newest[Const.Snap.TICK])
			if int(me_self[Const.SelfF.ACK]) != a._ack_seen:
				a._ack_seen = int(me_self[Const.SelfF.ACK])
				a._ack_tick = a._snap_tick
			for row in newest[Const.Snap.GERMS]:
				if int(row[Const.GF.ID]) == A_ID:
					a._reconcile(row, me_self)
		# Client-in tick-i ([method Arena._do_tick]): giriş, proqnoz, göndəriş.
		a._seq += 1
		var inp := Sim.PlayerInput.make(a._seq, Vector2.RIGHT, 0.0, false, t == PRESS)
		a.pending.append(inp)
		a.pred.step_movement(a._pred_inputs(inp), Const.TICK_DELTA, true)
		up.append([t + lag, inp.to_array()])
		# Serverin tick-i.
		while not up.is_empty() and int(up[0][0]) <= t:
			world.accept_input(A_ID, up.pop_front()[1])
		world.tick(Const.TICK_DELTA)
		down.append([t + lag, world.snapshot_for(A_ID)])
		if g.super_t > 0.0:
			srv_on += 1
		var on := a.me.super_t > 0.0
		if was_on and not on and g.super_t > 0.0:
			cli_gaps += 1
		was_on = on
		if on:
			cli_on += 1
	var name := "ayaqlının toru" if kind == Const.Species.HELIOZOAN else "amöbün kisti"
	var need := roundi(Const.super_time(int(kind)) / Const.TICK_DELTA)
	var rtt := roundi(2.0 * lag * Const.TICK_DELTA * 1000.0)
	_check(srv_on >= need - 1, "%s serverdə tam müddət işləyir, %d ms (%d / %d tick)"
		% [name, rtt, srv_on, need])
	# Yuxarı hədd də var: görüntü serverin bayrağı sönənə qədər qalır, yəni ən
	# çoxu bir gediş-gəliş və quyruq qədər uzun (bax [constant Arena.SUPER_TAIL]).
	_check(cli_on >= need - 1 and cli_on <= need + 2 * lag + 4 and cli_gaps == 0,
		"%s ÖZ ekranında da tam müddət qalır, %d ms gecikmə ilə (%d / %d tick, %d qırılma)"
			% [name, rtt, cli_on, need, cli_gaps])
	a.free()
	Net.species = saved


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


## CÜT-ü geriyə sayımdan keçirib PLAYING-ə çatdırır; A və B bir komandadadır.
static func _duo_pair(seed_id: int) -> World:
	var world := World.new(seed_id, Const.Mode.DUO)
	world.add_party([[A_ID, "A", 0], [B_ID, "B", 1]])
	world.tick(Const.TICK_DELTA)
	for i in int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2:
		world.tick(Const.TICK_DELTA)
	return world


## CÜT: dirilməni gözləyən oyunçunun bağlantısı kəsilir.
##
## Ölü mikrob `sim.germs`-də yoxdur, oyunçu isə hələ dünyadadır (yoldaşı onu
## diriltməlidir). Əvvəl [method World.suspend_peer] belə oyunçunu tanımırdı:
## "dayandırılmış" sayılmırdı və server 20 saniyə boyu qopmuş peer-ə 30 Hz-lə
## snapshot göndərməyə çalışırdı ("unknown peer ID" xətası). Qayıtmaq da
## alınmırdı — server ölü mikrobu "gözləmədə partladı" sayırdı. Tərk edən
## oyunçunun növbəsi isə qalırdı və 15 s sonra sahibsiz mikrob dirilirdi.
static func _test_duo_revive_disconnect() -> void:
	var world := _duo_pair(48)
	var team: int = world.sim.germs[A_ID].team
	world.sim.germs[A_ID].balls = 0
	world.tick(Const.TICK_DELTA)
	_check(world._revive.has(A_ID), "qopma testi: A dirilmə növbəsindədir")
	var color := int(world._revive[A_ID]["color"])

	world.suspend_peer(A_ID)
	_check(world.is_suspended(A_ID),
		"dirilmə gözləyən oyunçu qopanda 'dayandırılmış' sayılır — ona snapshot getmir")
	_check(world.holds(A_ID), "dirilmə gözləyənin matçda yeri var — qayıda bilər")

	world.resume_peer(A_ID, 303)
	_check(world._revive.has(303) and not world._revive.has(A_ID) and not world.is_suspended(303),
		"qayıdanda dirilmə növbəsi yeni peer-ə keçir")
	var info := world.join_info_for(303)
	_check(int(info["species"]) == 0 and str(info["name"]) == "A" and int(info["color"]) == color,
		"ölü ikən qayıdana öz adı, növü və rəngi gedir (%s)" % str(info))

	for i in int(Const.REVIVE_TIME / Const.TICK_DELTA) + 4:
		if world.sim.germs.has(B_ID):
			world.sim.germs[B_ID].balls = Const.START_BALLS
		world.tick(Const.TICK_DELTA)
	_check(world.sim.germs.has(303) and world.sim.germs[303].team == team,
		"qayıdan oyunçu yeni id ilə öz komandasında dirilir")

	# Tərk etmə dirilməni gözləyərkən (ayrı dünya — yuxarıdakının nəticəsindən
	# asılı olmasın): növbə də silinməlidir.
	var left := _duo_pair(50)
	left.sim.germs[B_ID].balls = 0
	left.tick(Const.TICK_DELTA)
	_check(left._revive.has(B_ID), "B dirilmə növbəsindədir")
	left.drop_peer(B_ID)
	for i in int(Const.REVIVE_TIME / Const.TICK_DELTA) + 4:
		if left.sim.germs.has(A_ID):
			left.sim.germs[A_ID].balls = Const.START_BALLS
		left.tick(Const.TICK_DELTA)
	_check(left.sim.germs.has(A_ID), "yoldaş (A) sağ qalıb — dirilmə şərti ödənir")
	_check(not left.sim.germs.has(B_ID) and not left._revive.has(B_ID),
		"tərk edən oyunçu dirilmir — dünyada sahibsiz mikrob qalmır")


## CÜT: yoldaşı da ölüb dirilmə LƏĞV olunanda gözləyən insan NƏTİCƏ alır.
##
## Əvvəl ona yer yazılırdı, amma nəticə göndərilmirdi: cüt matçdan çıxmışdı,
## oyunçu isə matç bitənə qədər nəticəsiz izləyici qalırdı.
static func _test_duo_revive_cancel_result() -> void:
	var world := _duo_pair(49)
	world.sim.germs[A_ID].balls = 0
	var out: Array = world.tick(Const.TICK_DELTA)
	_check(world._revive.has(A_ID) and out.is_empty(), "ləğv testi: A dirilmə növbəsindədir, nəticə yoxdur")
	world.sim.germs[B_ID].balls = 0
	var ids := []
	for i in 3:
		for entry in world.tick(Const.TICK_DELTA):
			ids.append(int(entry["id"]))
	_check(ids.has(B_ID), "yoldaşı olmayan B adi ölümlə nəticə alır")
	_check(ids.has(A_ID) and not world._revive.has(A_ID),
		"dirilməsi ləğv olunan A da nəticə alır (%s)" % str(ids))
	_check(world.places.has(A_ID) and world.places.has(B_ID) and world.places[A_ID] != world.places[B_ID],
		"ikisinin də ayrı yeri var")


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

## Atəş düyməsi — Brawl Stars-ın atəş joystickidir: qısa toxunuş avtomatik
## nişandır, sürüşdürüb buraxmaq nişanla atəşdir, mərkəzə qaytarıb buraxmaq
## ləğvdir. Ən təhlükəli hal barmağın qalxmasının itməsidir: düymə "basılı"
## ilişər. Ona görə buraxılma düymənin üstündə yox, qlobal olaraq barmaq
## indeksinə görə tutulur.
static func _test_fire_button() -> void:
	var btn := FireButton.new()
	btn.size = Vector2(200.0, 200.0)
	var taps := [0]
	var aims := []
	btn.tapped.connect(func() -> void: taps[0] += 1)
	btn.aimed.connect(func(a: float) -> void: aims.append(a))

	btn._gui_input(_touch(0, true))
	_check(btn.held and taps[0] == 0,
		"basılanda hələ atılmır — toxunuşdurmu, nişandırmı, bilinmir")
	# Başqa barmağın qalxması bu düyməyə aid deyil.
	btn._input(_touch(1, false))
	_check(btn.held, "yad barmaq düyməni buraxmır")
	# Baş barmaq toxunanda da bir neçə piksel titrəyir.
	btn._input(_drag(0, Vector2(108.0, 104.0)))
	_check(not btn.aiming, "ölü zonadakı titrəmə nişan sayılmır")
	btn._input(_touch(0, false))
	_check(not btn.held and taps[0] == 1 and aims.is_empty(),
		"qısa toxunuş avtomatik atəşdir (toxunuş=%d, nişan=%d)" % [taps[0], aims.size()])

	btn._gui_input(_touch(0, true))
	btn._input(_drag(0, Vector2(100.0, 160.0)))
	_check(btn.aiming and btn.aim_dir.is_equal_approx(Vector2.DOWN), "sürüşdürmə nişandır")
	btn._input(_drag(1, Vector2(300.0, 100.0)))
	_check(btn.aim_dir.is_equal_approx(Vector2.DOWN), "yad barmağın sürüşməsi nişanı dəyişmir")
	btn._input(_touch(0, false))
	_check(aims.size() == 1 and taps[0] == 1 and is_equal_approx(float(aims[0]), PI * 0.5),
		"buraxılanda nişanın bucağı ilə atılır (%s)" % [aims])

	# Fikrini dəyişən oyunçu barmağı mərkəzə qaytarır.
	btn._gui_input(_touch(0, true))
	btn._input(_drag(0, Vector2(160.0, 100.0)))
	btn._input(_drag(0, Vector2(102.0, 101.0)))
	_check(btn.is_cancelling() and not btn.aiming, "mərkəzə qayıdan nişan ləğv halındadır")
	btn._input(_touch(0, false))
	_check(aims.size() == 1 and taps[0] == 1, "ləğv olunan nişan heç nə atmır")

	btn._gui_input(_touch(0, true))
	btn._input(_drag(0, Vector2(160.0, 100.0)))
	btn.cancel()
	_check(not btn.held and not btn.aiming, "cancel() düyməni buraxır")
	btn._input(_touch(0, false))
	_check(aims.size() == 1 and taps[0] == 1, "cancel()-dən sonrakı qalxma atmır")

	btn.free()


## Avtomatik nişan hədəfi seçir: ən yaxın görünən rəqib; maneə arxasındakı
## ancaq başqası yoxdursa. Xəta atəş başına çəkilir və həddi aşmır.
static func _test_auto_aim() -> void:
	var s := Sim.new()
	s.obstacles.clear()
	s.broken = PackedByteArray()
	var near := {"key": 1, "pos": Vector2(200.0, 0.0)}
	var far := {"key": 2, "pos": Vector2(400.0, 0.0)}
	_check(int(AutoAim.pick(Vector2.ZERO, [far, near], 600.0, s).get("key", -1)) == 1,
		"ən yaxın rəqib seçilir")
	_check(AutoAim.pick(Vector2.ZERO, [{"key": 3, "pos": Vector2(900.0, 0.0)}], 600.0, s).is_empty(),
		"nişanın çatmadığı rəqib seçilmir — top getdiyin tərəfə gedir")

	s.obstacles.append(Vector4(100.0, 0.0, 40.0, DishMap.Kind.MUCUS))
	s.broken = PackedByteArray([0])
	var open := {"key": 4, "pos": Vector2(0.0, 350.0)}
	_check(int(AutoAim.pick(Vector2.ZERO, [near, open], 600.0, s).get("key", -1)) == 4,
		"görünən rəqib maneə arxasındakı yaxından üstündür")
	_check(int(AutoAim.pick(Vector2.ZERO, [near], 600.0, s).get("key", -1)) == 1,
		"başqa hədəf yoxdursa, maneə arxasındakına atılır")

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var worst := 0.0
	var mean := 0.0
	for i in 4000:
		var e := AutoAim.roll_error(rng)
		worst = maxf(worst, absf(e))
		mean += e / 4000.0
	_check(worst <= AutoAim.ERROR and worst > AutoAim.ERROR * 0.8 and absf(mean) < 0.01,
		"avtomatik nişan dəqiq deyil, amma həddi aşmır və bir tərəfə əyilmir (ən çox %.3f, orta %.4f)" \
			% [worst, mean])
	_check(AutoAim.reach(Const.START_CAPACITY + 20) > AutoAim.reach(Const.START_CAPACITY),
		"nişanın məsafəsi kamera ilə böyüyür")


## Nişan xətti topun ÖZ yolu olmalıdır: xətt bir yerdə, top başqa yerdə
## səkərsə, dəqiq nişan aldadır. Ona görə xətt əsl topla müqayisə olunur.
static func _test_aim_path() -> void:
	var s := Sim.new()
	s.obstacles.clear()
	s.broken = PackedByteArray()
	var p := s.aim_path(Vector2.ZERO, Vector2.RIGHT, 500.0, 1)
	_check(p.size() == 2 and p[1].is_equal_approx(Vector2(500.0, 0.0)), "boş yolda xətt düzdür")

	s.obstacles.append(Vector4(300.0, 40.0, 50.0, DishMap.Kind.MUCUS))
	s.broken = PackedByteArray([0])
	p = s.aim_path(Vector2.ZERO, Vector2.RIGHT, 500.0, 1)
	var walked := 0.0
	for i in p.size() - 1:
		walked += p[i].distance_to(p[i + 1])
	_check(p.size() == 3 and p[2].x < p[1].x and absf(walked - 500.0) < 1.0,
		"selikdən səkir və uzunluq saxlanılır (%d nöqtə, %.1f px)" % [p.size(), walked])

	# Əsl top eyni yerdə səkməli və eyni tərəfə getməlidir.
	var g := s.add_germ(A_ID, "A", 0)
	g.pos = Vector2.ZERO
	g.aim = 0.0
	s._fire(g)
	var shot: Sim.ShotState = s.shots[0]
	var hit := Vector2.INF
	for i in 30:
		s._step_shots(Const.TICK_DELTA)
		for e in s.events:
			if e.get("t") == "hit" and hit == Vector2.INF:
				hit = e["pos"]
	_check(hit.distance_to(p[1]) < 0.6, "top xəttin göstərdiyi yerdə səkir (%s ~ %s)" % [hit, p[1]])
	# Top da, xətt də səkmə nöqtəsindən 0.5 px aralanıb davam edir — bucaq
	# fərqi o qədərdir (~0.1°), görünməzdir.
	var turn := absf(shot.dir.angle_to(p[2] - p[1]))
	_check(turn < 0.01, "səkmədən sonra top xəttin tərəfinə gedir (fərq %.4f rad)" % turn)

	s.obstacles[0] = Vector4(300.0, 0.0, 50.0, DishMap.Kind.BRITTLE)
	p = s.aim_path(Vector2.ZERO, Vector2.RIGHT, 500.0, 1)
	_check(p.size() == 2 and absf(p[1].x - (250.0 - Const.SHOT_RADIUS)) < 0.5,
		"kövrək qabıqda xətt dayanır — top onu yarır, səkmir")
	s.broken[0] = DishMap.Wall.GONE
	p = s.aim_path(Vector2.ZERO, Vector2.RIGHT, 500.0, 1)
	_check(p.size() == 2 and is_equal_approx(p[1].x, 500.0), "dağılmış qabıqdan xətt keçir")
	s.obstacles[0] = Vector4(300.0, 0.0, 50.0, DishMap.Kind.BUSH)
	p = s.aim_path(Vector2.ZERO, Vector2.RIGHT, 500.0, 1)
	_check(p.size() == 2, "koldan xətt keçir — top da keçir")

	s.obstacles.clear()
	s.broken = PackedByteArray()
	var from := Vector2(Const.WORLD_RADIUS - 100.0, 0.0)
	p = s.aim_path(from, Vector2.RIGHT, 300.0, 1)
	_check(p.size() == 3 and p[2].x < p[1].x
		and absf(p[1].length() - (Const.WORLD_RADIUS - Const.SHOT_RADIUS)) < 0.5,
		"qabın şüşə kənarından səkir")


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


static func _drag(index: int, at: Vector2) -> InputEventScreenDrag:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = at
	return e


static func _touch(index: int, pressed: bool) -> InputEventScreenTouch:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.pressed = pressed
	e.position = Vector2(100.0, 100.0)
	return e


## ── Şəbəkə donması (bax README, «Donma və dəstə») ──────────────────────

## Botsuz dünya: yalnız oyunçunun öz hərəkəti yoxlanır (ayırma, tor qarışmasın).
## İkinci, girişsiz oyunçu uzaqda durur: tək mikroblu dünya "matç bitdi" sayılır.
##
## Generator TOXUMLANIR: `Sim` onu hər dəfə təsadüfi qurur, yəni doğuş yeri hər
## çalışmada başqa idi. Yol maneəyə və ya qabın kənarına düşəndə ölçülər dəyişirdi
## — "yenidən oynatmasız server təxmin yolunda qalır" 7 çalışmada 64–177 px verdi
## (hədd 100) və təsadüfən düşürdü. Toxumla iki dünya (yenidən oynatmalı və
## oynatmasız) üstəlik EYNİ yerdən başlayır — müqayisə ədalətli olur.
static func _lonely_world(seed_id: int) -> World:
	var world := World.new(seed_id, Const.Mode.ENDLESS)
	world.sim.rng.seed = seed_id
	world._seeded = true
	world._bot_timer = 1.0e9
	return world


static func _park_far(world: World, from: Vector2) -> void:
	var other := world.add_player(B_ID, "B")
	var away := Vector2(0.0, 700.0) if from.y < 0.0 else Vector2(0.0, -700.0)
	other.pos = from + away


## Yuxarı istiqamət donanda server sonuncu girişi TƏKRARLAYIR (təxmin), donma açılanda
## isə girişlər bir tick-də gəlir. Server onları təxmin tick-ləri üçün yenidən oynadır:
## mikrobun yeri oyunçunun ÖZ yolu ilə üst-üstə düşür, proqnoz geri dartılmır.
static func _test_late_inputs_replayed() -> void:
	var ends := {}
	for replay in [true, false]:
		var world := _lonely_world(91)
		world.replay_enabled = replay
		var g := world.add_player(A_ID, "A")
		_park_far(world, g.pos)
		var ref := Sim.new()
		var c := ref.add_germ(A_ID, "A", g.color, false, g.species)
		c.pos = g.pos
		c.vel = g.vel
		c.capacity = g.capacity
		var seq := 0
		var anchor_ok := false
		for t in 36:
			var move := Vector2.RIGHT if t < 10 else Vector2.UP
			ref.dish_radius = world.sim.dish_radius
			# 10..29: donma — client girişləri göndərir, server heç birini almır.
			if t < 10 or t >= 30:
				var upto := t + 1
				while seq < upto:
					seq += 1
					var m := Vector2.RIGHT if seq <= 10 else Vector2.UP
					world.accept_input(A_ID, Sim.PlayerInput.make(seq, m, m.angle(), false).to_array())
			world.tick(Const.TICK_DELTA)
			ref.step_movement({A_ID: Sim.PlayerInput.make(t + 1, move, move.angle(), false)},
				Const.TICK_DELTA, false)
			if t == 29 and replay:
				world._build_frame()
				var me_self: Array = world.snapshot_for(A_ID)[Const.Snap.SELF]
				anchor_ok = me_self.size() == 7 and int(me_self[2]) == 20 \
					and Vector2(float(me_self[3]), float(me_self[4])).distance_to(ends["anchor"]) < 0.01
			if t == 9:
				ends["anchor"] = g.pos
		ends[replay] = g.pos.distance_to(c.pos)
		if replay:
			world._build_frame()
			var after: Array = world.snapshot_for(A_ID)[Const.Snap.SELF]
			_check(anchor_ok and after.size() == 3 and int(after[2]) == 0,
				"donmada SELF təxmin sayı (20) və ankoru daşıyır, açılandan sonra sıfırdır")
	_check(float(ends[true]) < 1.0,
		"20 tick-lik donmadan sonra server oyunçunun ÖZ yolundadır (fərq %.1f px)" % float(ends[true]))
	_check(float(ends[false]) > 100.0,
		"yenidən oynatmasız server təxmin yolunda qalır (fərq %.0f px) — yoxlama mənalıdır"
			% float(ends[false]))


## Donma ərzində mikroba kənardan nə isə toxunubsa (burada trixosist itələməsi kimi
## sürət zərbəsi), təxmin yolu təmiz hərəkət deyil: yenidən oynatmaq o təsiri SİLƏRDİ.
## Belə pəncərə yenidən oynadılmır — server köhnə qayda ilə davranır.
static func _test_replay_keeps_pushes() -> void:
	var pos := {}
	var spawn := Vector2.INF
	for replay in [true, false]:
		var world := _lonely_world(93)
		world.replay_enabled = replay
		var g := world.add_player(A_ID, "A")
		# Doğuş yeri təsadüfidir — iki dünya eyni yerdən başlamalıdır.
		if spawn == Vector2.INF:
			spawn = g.pos
		g.pos = spawn
		g.vel = Vector2.ZERO
		_park_far(world, g.pos)
		var seq := 0
		for t in 36:
			if t < 10 or t >= 30:
				while seq < t + 1:
					seq += 1
					var m := Vector2.RIGHT if seq <= 10 else Vector2.UP
					world.accept_input(A_ID, Sim.PlayerInput.make(seq, m, m.angle(), false).to_array())
			if t == 15:
				g.vel += Vector2(0.0, 250.0)
			world.tick(Const.TICK_DELTA)
		pos[replay] = g.pos
	_check(Vector2(pos[true]).distance_to(pos[false]) < 0.01,
		"donmada itələnən mikrobun yolu yenidən oynadılmır (fərq %.2f px)"
			% Vector2(pos[true]).distance_to(pos[false]))


## Client tick-ləri ATANDA (uzun kadr) o slot-ların girişi heç vaxt gəlmir: təxmin sayğacı
## girişlər axanda ən çox iki [constant World.DEBT_WINDOW] pəncərəsində sıfırlanmalıdır.
static func _test_guess_counter_resets() -> void:
	var world := _lonely_world(92)
	_park_far(world, world.add_player(A_ID, "A").pos)
	var seq := 0
	var reps := []
	for t in 80:
		# 20..24 tick-lərində client heç nə göndərmir və seq-i də ARTIRMIR (tick-ləri atıb).
		if t < 20 or t >= 25:
			seq += 1
			world.accept_input(A_ID, Sim.PlayerInput.make(seq, Vector2.RIGHT, 0.0, false).to_array())
		world.tick(Const.TICK_DELTA)
		world._build_frame()
		reps.append(int((world.snapshot_for(A_ID)[Const.Snap.SELF] as Array)[2]))
	_check(int(reps[24]) == 5 and int(reps[30]) == 5 and int(reps[79]) == 0,
		"atılan tick-lərin təxmini sayılır (%d), girişlər axanda sıfırlanır (%d)"
			% [int(reps[24]), int(reps[79])])


## Borc JITTER-də də silinir (yoxlamada tapılıb). Client 15 tick-i həmişəlik atır (vərəq arxa
## planda), sonra girişlər adi jitter-lə gəlir: hər yeddinci bir tick gecikir, yəni bir tick
## boş, növbətidə iki giriş. Köhnə qayda (30 tick FASİLƏSİZ giriş) heç ödənmirdi: borc sessiya
## boyu 15 qalırdı, server hər tick 15 slot-u ən təzə girişlə yenidən hesablayırdı və oyunçu
## dönəndə mikrob bir tick-də 155 px sıçrayırdı.
static func _test_guess_debt_clears_under_jitter() -> void:
	var world := _lonely_world(94)
	var g := world.add_player(A_ID, "A")
	_park_far(world, g.pos)
	var seq := 0
	var held := []
	var last_rep := -1
	var max_step := 0.0
	var prev := g.pos
	for t in 200:
		if t < 20 or t >= 35:
			seq += 1
			var m := Vector2.RIGHT if t < 120 else Vector2.UP
			held.append(Sim.PlayerInput.make(seq, m, m.angle(), false).to_array())
		if t % 7 != 3:
			for a in held:
				world.accept_input(A_ID, a)
			held.clear()
		world.tick(Const.TICK_DELTA)
		world._build_frame()
		last_rep = int((world.snapshot_for(A_ID)[Const.Snap.SELF] as Array)[2])
		if t > 100:
			max_step = maxf(max_step, g.pos.distance_to(prev))
		prev = g.pos
	_check(last_rep <= 1 and max_step < 20.0,
		"atılan tick-lərin borcu jitter-də silinir (təxmin %d), dönəndə sıçrayış yoxdur (%.1f px/tick)"
			% [last_rep, max_step])


## ÜÇLÜK raundu vaxtla bitəndə mikroblar yeni doğuş yerinə köçür. Həmin tick-də növbədə gec
## gələn giriş olsa belə, yenidən oynatma mikrobu köhnə raundun yerinə QAYTARMAMALIDIR,
## geri sayım boyu da heç nə "təxmin" sayılmamalıdır (yoxlamada tapılıb: sayım 90 təxmin
## yığırdı, ankor client-i köhnə yerə çəkirdi). Saxlanan köhnə giriş də silinir — sayımda
## mikrobu yalnız su axını aparır, proqnozdakı kimi (köhnə raundun hərəkəti yox).
static func _test_round_reset_forgets_replay() -> void:
	var world := World.new(96, Const.Mode.TRIO)
	world.add_player(A_ID, "A")
	world.tick(Const.TICK_DELTA)
	var steps := int(Const.COUNTDOWN_TIME / Const.TICK_DELTA) + 2
	for i in steps:
		world.tick(Const.TICK_DELTA)
	var seq := 0
	for t in 20:
		seq += 1
		world.accept_input(A_ID, Sim.PlayerInput.make(seq, Vector2.RIGHT, 0.0, false).to_array())
		world.tick(Const.TICK_DELTA)
	# Bir tick giriş gəlmir (təxmin), sonra iki gec giriş növbədə — və raund elə o tick bitir.
	world.tick(Const.TICK_DELTA)
	for i in 2:
		seq += 1
		world.accept_input(A_ID, Sim.PlayerInput.make(seq, Vector2.DOWN, PI / 2.0, false).to_array())
	world.match_t = Const.TRIO_ROUND
	world.tick(Const.TICK_DELTA)
	var g: Sim.GermState = world.sim.germs[A_ID]
	var still := g.vel.length() < 0.01
	var stale := world._inputs.has(A_ID)
	var max_rep := 0
	for i in steps - 4:
		world.tick(Const.TICK_DELTA)
		world._build_frame()
		max_rep = maxi(max_rep, int((world.snapshot_for(A_ID)[Const.Snap.SELF] as Array)[2]))
	_check(world.phase == Const.Phase.COUNTDOWN and still,
		"raund sıfırlananda yenidən oynatma mikrobu köhnə yerə qaytarmır (sürət %s)" % str(g.vel))
	_check(max_rep == 0 and not stale,
		"geri sayımda təxmin sayılmır (%d), köhnə raundun girişi saxlanmır (%s)" % [max_rep, stale])


## Göstərilən an: geri getmir, ən təzə snapshot-dan EXTRAP_MAX-dan çox qabağa keçmir,
## 1.5 s donmadan sonra SIÇRAMADAN (ən çox CATCHUP_MAX× sürətlə) yetişir, 4 s-lik
## donmada bir dəfə sıçrayır və 2.5 s ərzində normal gecikməyə qayıdır.
static func _test_render_clock_stall() -> void:
	for stall in [1.5, 4.0]:
		var a := Arena.new()
		var dt := 1.0 / 60.0
		var k := 0
		var back := false
		var over := false
		var max_step := 0.0
		var jumps := 0
		var lag_after := INF
		var snap_at := func(tick: int) -> float:
			var at := tick * Const.TICK_DELTA + 0.05
			if at >= 5.0 and at < 5.0 + stall:
				at = 5.0 + stall
			return at
		var now := 0.0
		while now < 5.0 + stall + 2.5:
			var batch := []
			while snap_at.call(k + 1) <= now:
				k += 1
				batch.append(k)
			if not batch.is_empty():
				a._batch_stalled = a._tick_base_set and a._clock - float(batch[0]) * Const.TICK_DELTA \
					- a._floor > Arena.LATE_STALL
				for tick in batch:
					var snap := []
					snap.resize(Const.Snap.EVENTS + 1)
					snap[Const.Snap.TICK] = tick
					a._snaps.append({"t": a._tick_time_of(float(tick)), "d": snap})
				a._batch_stalled = false
				a._update_delay_target()
			var prev := a._rtick
			a._clock += dt
			now += dt
			a._advance_render(dt)
			if prev >= 0.0:
				var step := a._rtick - prev
				back = back or step < -0.0001
				if now > 5.0 + stall:
					max_step = maxf(max_step, step)
					if step > Arena.CATCHUP_MAX * dt / Const.TICK_DELTA + 0.01:
						jumps += 1
			over = over or a._rtick > float(k) + Arena.EXTRAP_MAX / Const.TICK_DELTA + 0.01
			lag_after = (a._clock - a._delay - a._floor) / Const.TICK_DELTA - a._rtick
		_check(not back and not over, "%.1f s donma: göstərilən tick geri getmir, %.1f s-dən çox irəli çəkilmir"
			% [stall, Arena.EXTRAP_MAX])
		_check((jumps == 0) if stall < 2.0 else (jumps == 1),
			"%.1f s donmadan sonra %s (kadrda ən böyük addım %.1f tick, sıçrayış %d)"
				% [stall, "sıçrayış yoxdur" if stall < 2.0 else "bir sıçrayış", max_step, jumps])
		_check(lag_after * Const.TICK_DELTA < 0.05,
			"%.1f s donmadan 2.5 s sonra göstərilən an normaldır (geriləmə %.0f ms)"
				% [stall, lag_after * Const.TICK_DELTA * 1000.0])
		a.free()


## DAVAMLI sürüşmə (yol uzanıb, server tick atıb): 5-ci saniyədən hər snapshot 0.3 / 0.5 s gec
## gəlir, üstəlik adi jitter. Baza yavaş qalxanda rəqiblər 30–65 s ekstrapolyasiya olunurdu
## (yoxlamada ölçülüb). İndi baza ~1.5 s-də yenidən qurulur: sürüşmədən 3 s sonra göstərilən
## an artıq buferin içindədir, geriyə isə heç vaxt getmir.
static func _test_render_clock_shift() -> void:
	var base_frames := -1
	for shift in [0.0, 0.3, 0.5]:
		var a := Arena.new()
		var dt := 1.0 / 60.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		var k := 0
		var next_at := Const.TICK_DELTA
		var back := false
		var extra_late := 0
		var now := 0.0
		while now < 12.0:
			var batch := []
			while next_at <= now:
				k += 1
				batch.append(k)
				next_at = k * Const.TICK_DELTA + 0.05 + rng.randf() * 0.03 \
					+ (shift if k * Const.TICK_DELTA >= 5.0 else 0.0)
				next_at = maxf(next_at, now)
			for tick in batch:
				var snap := []
				snap.resize(Const.Snap.EVENTS + 1)
				snap[Const.Snap.TICK] = tick
				a._snaps.append({"t": a._tick_time_of(float(tick)), "d": snap})
			if not batch.is_empty():
				a._update_delay_target()
			var prev := a._rtick
			a._clock += dt
			now += dt
			a._advance_render(dt)
			back = back or (prev >= 0.0 and a._rtick < prev - 0.0001)
			if now > 5.0 + shift + 3.0 and a._extra > 0.0:
				extra_late += 1
		a.free()
		# Sürüşməsiz hal ölçü xəttidir: adi jitter də bəzən bir-iki kadr boşluq verir.
		if shift == 0.0:
			base_frames = extra_late
			continue
		_check(not back and extra_late <= base_frames + 12,
			"%.1f s davamlı sürüşmə: 3 s sonra ekstrapolyasiya sürüşməsizdəki qədərdir (%d / %d kadr), geri getmir"
				% [shift, extra_late, base_frames])


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


## Xəritə atlası (V1 "Damla") və onun teksturaları pozulmamalıdır:
##   1. hər hüceyrənin bölgəsi öz 512/256/128 blokunun içindədir — mip
##      səviyyələri qonşu hüceyrəni qarışdırmır, bilinear nümunə başqa şəklə daşmır;
##   2. pivot hüceyrənin mərkəzidir (ayaq izinin mərkəzi), ayaq izinin radiusu
##      sinfinə uyğundur (L 192, S 96 tekstel) — oyunda miqyas = R / radius;
##   3. bərk maneənin silueti TOQQUŞMA DAİRƏSİNİN ÖZÜDÜR (ART_BIBLE §4b): oyunçu
##      divarı şəkildən oxuyur. Şəkil dairədən böyük olsa keçə biləcəyi boşluğu
##      bağlı görər, kiçik olsa "boş" yerdə ilişər;
##   4. divar zolağı və döşəmə detalı tikişsiz təkrarlanır — tikiş qab boyunca
##      27 dəfə, döşəmədə hər 400 px-də görünərdi.
## Atlas `design/map_art/build_map.gd` ilə yenidən qurulanda bu test onu yoxlayır.
static func _test_map_atlas() -> void:
	var cells := MapKit.cells()
	var bad_block := []
	var bad_pivot := []
	var bad_radius := []
	for name: String in cells:
		var c: Dictionary = cells[name]
		var r: Array = c["rect"]
		var rect := Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3]))
		var n := int(c["cell"])
		var origin := rect.position - Vector2i(posmod(rect.position.x, n), posmod(rect.position.y, n))
		if not Rect2i(origin, Vector2i(n, n)).encloses(rect):
			bad_block.append(name)
		var off: Array = c["offset"]
		var pivot := Vector2(rect.position) + Vector2(rect.size) * 0.5 \
			- Vector2(float(off[0]), float(off[1]))
		if pivot.distance_to(Vector2(origin) + Vector2(n, n) * 0.5) > 0.6:
			bad_pivot.append(name)
		var want := 192.0 if name.ends_with("_L") else (96.0 if name.ends_with("_S") else -1.0)
		if want > 0.0 and absf(float(c["r"]) - want) > 0.01:
			bad_radius.append(name)
	_check(bad_block.is_empty(), "atlas: hər hüceyrə öz blokundadır %s" % [bad_block])
	_check(bad_pivot.is_empty(), "atlas: pivot hüceyrənin (ayaq izinin) mərkəzidir %s" % [bad_pivot])
	_check(bad_radius.is_empty(), "atlas: ayaq izi L-də 192, S-də 96 teksteldir %s" % [bad_radius])

	# PNG birbaşa oxunur: başsız testdə idxal olunmuş tekstura GPU-ya gedir və
	# pikselləri geri oxunmur.
	var page := Image.new()
	var loaded := page.load_png_from_buffer(FileAccess.get_file_as_bytes(MapKit.ATLAS_PATH)) == OK
	var inside := 1.0
	var outside := 0.0
	if loaded:
		for base in ["mucus_blob", "mucus_bloom", "brittle_s0", "brittle_s1", "brittle_s2"]:
			for cls in ["L", "S"]:
				var c: Dictionary = cells["%s_%s" % [base, cls]]
				var r: Array = c["rect"]
				var n := int(c["cell"])
				var origin := Vector2(int(r[0]) - posmod(int(r[0]), n), int(r[1]) - posmod(int(r[1]), n))
				var center := origin + Vector2(n, n) * 0.5
				var rad := float(c["r"])
				for k in 36:
					var dir := Vector2.from_angle(TAU * float(k) / 36.0)
					inside = minf(inside, page.get_pixelv(Vector2i(center + dir * (rad - 2.0))).a)
					outside = maxf(outside, page.get_pixelv(Vector2i(center + dir * (rad + 2.0))).a)
	_check(loaded and inside >= 0.9 and outside <= 0.1,
		"bərk maneənin silueti toqquşma dairəsidir (kənardan 2 tekstel içəridə alfa ≥ %.2f, bayırda ≤ %.2f)"
			% [inside, outside])

	for spec in [[MapKit.RIM_PATH, false], [MapKit.DETAIL_PATH, true]]:
		var img := Image.new()
		var ok := img.load_png_from_buffer(FileAccess.get_file_as_bytes(String(spec[0]))) == OK
		var w := img.get_width()
		var h := img.get_height()
		# Tikiş qonşu sütunlardan çox fərqlənməməlidir (orta fərqin iki misli).
		var seam := _map_seam(img, w - 1, 0, true)
		var typical := _map_seam(img, (w >> 1) - 1, w >> 1, true)
		var good := ok and seam <= typical * 2.0 + 0.01
		if bool(spec[1]):
			good = good and _map_seam(img, h - 1, 0, false) \
				<= _map_seam(img, (h >> 1) - 1, h >> 1, false) * 2.0 + 0.01
		_check(good, "%s tikişsiz təkrarlanır (tikiş %.3f, adi qonşu %.3f)"
			% [String(spec[0]).get_file(), seam, typical])


## İki sütunun (və ya sətrin) orta parlaqlıq fərqi.
static func _map_seam(img: Image, a: int, b: int, columns: bool) -> float:
	var n := img.get_height() if columns else img.get_width()
	var s := 0.0
	for i in n:
		var p := img.get_pixel(a, i) if columns else img.get_pixel(i, a)
		var q := img.get_pixel(b, i) if columns else img.get_pixel(i, b)
		s += absf(p.get_luminance() - q.get_luminance())
	return s / float(n)
