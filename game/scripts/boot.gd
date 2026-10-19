extends Node
## Giriş nöqtəsi. Eyni build həm oyun, həm server kimi işə düşür.
##
##   Oyun   : Godot_v4.7.2.exe --path game
##   Server : Godot_v4.7.2.exe --headless --path game -- --server --port 27015
##
## Bir build olması vacibdir: server və client EYNİ [Sim] kodunu icra edir,
## versiya fərqi olsa simulyasiyalar ayrılar.


func _ready() -> void:
	_keep_landscape()
	get_window().size_changed.connect(_keep_landscape)
	var args := OS.get_cmdline_user_args()
	if args.has("--simtest"):
		# Test skripti açılmasa (sintaksis xətası), `run()` çağırışı uğursuz olur və
		# `quit` heç vaxt gəlmir — başsız proses əbədi ilişib qalırdı.
		var tests := _tool("sim_test")
		if tests == null or not tests.can_instantiate():
			printerr("[simtest] sim_test.gd açılmadı — yuxarıdakı xətaya bax")
			get_tree().quit(2)
			return
		get_tree().quit(tests.run())
	elif args.has("--server"):
		_start_server(args)
	elif args.has("--practice"):
		_start_practice(args)
	elif args.has("--autoclient"):
		_start_auto_client(args)
	elif args.has("--preview"):
		_start_preview(args)
	elif args.has("--germ-bench"):
		_start_germ_bench(args)
	elif args.has("--menu1"):
		_start_old_menu(args)
	elif args.has("--map"):
		_start_map(args)
	elif args.has("--agent"):
		_start_agent(args)
	elif args.has("--social-demo"):
		# Dostlar/komanda ekranlarının stendi (bax `tools/social_demo.gd`).
		var demo = _tool("social_demo").new()
		demo.view = _arg_value(args, "--social-demo", "home")
		get_tree().root.add_child.call_deferred(demo)
		_setup_screenshot(args)
	else:
		# `_ready` icra olunarkən ağac hələ məşğuldur — səhnə dəyişimi
		# növbəti kadra təxirə salınmalıdır.
		get_tree().change_scene_to_file.call_deferred("res://scenes/ui/menu.tscn")
		_setup_screenshot(args)


## Menyunu keçib birbaşa botlarla dolu yerli dünyaya düşür.
## Həm cihazda sürətli sınaq, həm də bütün oyun axınının inteqrasiya testidir.
func _start_practice(args: PackedStringArray) -> void:
	# `--species <0|1|2>` — məşq rejimində mikrob növünü seçir.
	#
	# Menyu keçilib birbaşa dünyaya düşüldüyü üçün `settings.cfg` oxunmur,
	# yəni növü yalnız buradan vermək olar. Bu, hər növün görüntüsünü
	# redaktoru açmadan, təkrarlana bilən şəkildə yoxlamağa imkan verir
	# (`--shot` ilə birlikdə).
	var kind := _arg_value(args, "--species", "")
	if not kind.is_empty():
		Net.species = Const.species_from(int(kind))

	# `--mode <0|1>` — rejim (0 sonsuz arena, 1 TƏK QALAN).
	#
	# Menyu keçildiyi üçün seçim yalnız buradan verilə bilər. `--species` ilə
	# eyni səbəb: rejimi redaktoru açmadan, təkrarlana bilən şəkildə yoxlamaq.
	var mode := _arg_value(args, "--mode", "")
	if not mode.is_empty():
		Net.mode = Const.mode_from(int(mode))

	# `--quality <0|1|2>` — qrafika səviyyəsi (0 yüksək, 1 aşağı, 2 minimum).
	#
	# `--species` və `--mode` ilə eyni səbəb: məşq menyunu keçir, yəni
	# `settings.cfg` oxunmur. Onsuz aşağı keyfiyyətin görüntüsünü təkrarlana
	# bilən şəkildə yoxlamaq mümkün deyil.
	#
	# Səviyyə yalnız çəkilişi yox, kadr həddini və render ölçüsünü də dəyişir
	# (MİNİMUM: 30 kadr, 1280×720) — ona görə ayarlar yenidən tətbiq olunur.
	# Avtomatika da söndürülür: seçilmiş səviyyə ölçmə boyu sabit qalmalıdır.
	var q := _arg_value(args, "--quality", "")
	if not q.is_empty():
		Net.quality = Const.quality_from(int(q))
		Settings.quality_chosen = true
		Settings.apply()

	_spawn_practice(args)

	_setup_screenshot(args)
	_setup_perf(args)
	_setup_frame_probe(args)
	_setup_super_probe(args)


## Məşq arenasını yaradıb səhnə edir. Ayrıca funksiyadır: kadr probu oyunçu
## öləndə menyu əvəzinə yeni arena açır (bax `tools/frame_probe.gd`).
func _spawn_practice(args: PackedStringArray) -> void:
	# `--at x,y` — mikrobu xəritənin müəyyən yerində doğurur (yalnız yoxlama).
	# `configure_practice`-dən ƏVVƏL oxunmalıdır: yerli dünya mikrobu məhz
	# orada yaradır. Sonra qoyulsaydı proqnoz yeni yerdə, server isə köhnə
	# yerdə olardı və ilk düzəliş mikrobu geri sıçradardı.
	var at := _arg_value(args, "--at", "")

	# Tipsizdir — tipli yazılsaydı arena (və onun bütün asılılıqları) HƏR
	# açılışda kompilyasiya olunardı, menyuya da (bax [method _tool]).
	var arena = load("res://scenes/game/arena.tscn").instantiate()
	if not at.is_empty():
		var parts := at.split(",")
		if parts.size() == 2:
			arena.start_at = Vector2(float(parts[0]), float(parts[1]))
	# `--charge` — super DOLU başlayır (yalnız yoxlama).
	#
	# Superin görüntüsünü kadrla yoxlamaq üçündür: adi oyunda doluluq 20–30
	# saniyə yığılır və avtomatik oyunçu onu nə vaxt dolduracağı təsadüfdür.
	# `--shot-count` ilə birlikdə hər növün superi ilk saniyədə, təkrarlana
	# bilən şəkildə çəkilir.
	arena.start_charged = args.has("--charge")
	arena.configure_practice()
	# Görüntü üçün mikrob hərəkətdə olsun. `--idle` bunu söndürür: avtomatik
	# oyunçu superi hazır olan kimi işlədir, yəni HAZIR vəziyyətin (düymə,
	# aura) şəklini başqa yolla çəkmək olmur.
	#
	# `--auto` — kadr çəkmədən də avtomatik oyunçu: performans ssenarisində
	# mikrob döyüşməlidir (qaçır, atəş açır, super işlədir), dayanmış oyunçunu
	# botlar tez yeyir və ölçmənin qalanı başqa səhnə olur (bax PERF_PLAN, A04s).
	arena.auto_input = (args.has("--shot") or args.has("--auto")) and not args.has("--idle")
	var tree := get_tree()
	tree.root.add_child.call_deferred(arena)
	tree.set_deferred("current_scene", arena)


## Pəncərə portret olanda kadrı YATAY saxlayır.
##
## Oyun yataydır və telefonda oriyentasiya kilidlidir, amma masaüstündə və
## brauzerdə pəncərə portret ola bilər. `expand` rejimi o halda görüş sahəsini
## ŞAQULİ genişləndirir: 720×1280 pəncərədə viewport 1280×2275 olur — HUD-un
## künclərə bağlı elementləri bir-birindən qopur, minimap sağ kənardan kəsilir,
## yazılar isə 56%-ə kiçilir.
##
## `keep` isə eyni 1280×720 kadrı bütöv saxlayıb yanlarına zolaq qoyur: yazı
## yenə kiçikdir (720 px enə 1280 px dizayn sığmır — bu fizikadır), amma düzüm
## pozulmur və heç nə kəsilmir.
##
## Yatay pəncərələrdə `expand` qalır: ultra-geniş ekranda ƏLAVƏ görüş sahəsi
## verir və 2400×1080-də düzgün işləyir.
func _keep_landscape() -> void:
	var w := get_window()
	var want := Window.CONTENT_SCALE_ASPECT_EXPAND
	if w.size.y > w.size.x:
		want = Window.CONTENT_SCALE_ASPECT_KEEP
	if w.content_scale_aspect != want:
		w.content_scale_aspect = want


## Test və yoxlama alətini YALNIZ həmin rejim seçiləndə yükləyir.
##
## Sinif adı ilə yazılanda (`SimTest.run()`, `PlayAgent.new()`) GDScript onları
## `boot.gd`-nin özü ilə birlikdə, yəni HƏR açılışda yükləyib kompilyasiya
## edirdi — oyunçunun heç vaxt işlətmədiyi ~6 000 sətir test kodu da daxil.
## Ölçülüb: brauzerdə, 4× yavaşladılmış CPU-da `boot.gd` 1.7 s yüklənirdi və
## həmin müddətdə ekran donmuş qalırdı (bax README, «Brauzerdə donma»).
static func _tool(file: String) -> Script:
	return load("res://scripts/tools/%s.gd" % file)


## Növün görüntü stendi — oyun məntiqi olmadan tək mikrob (bax [SpeciesPreview]).
func _start_preview(args: PackedStringArray) -> void:
	var stand = _tool("species_preview").new()
	stand.species = Const.species_from(int(_arg_value(args, "--preview-species", "2")))
	stand.balls = int(_arg_value(args, "--preview-balls", "9"))
	stand.capacity = int(_arg_value(args, "--preview-cap", "16"))
	stand.fire_every = float(_arg_value(args, "--preview-fire", "0"))
	stand.speed_scale = float(_arg_value(args, "--preview-speed", "1"))
	var tree := get_tree()
	tree.root.add_child.call_deferred(stand)
	tree.set_deferred("current_scene", stand)
	_setup_screenshot(args)


## Mikrob stendi — çəkilişin qiyməti və görüntü müqayisəsi (bax `tools/germ_bench.gd`).
func _start_germ_bench(args: PackedStringArray) -> void:
	var stand = _tool("germ_bench").new()
	stand.species_arg = _arg_value(args, "--bench-species", "mix")
	stand.count = maxi(1, int(_arg_value(args, "--bench-count", "10")))
	stand.lod = int(_arg_value(args, "--bench-lod", "0"))
	stand.secs = float(_arg_value(args, "--bench-secs", "8"))
	stand.render_mode = _arg_value(args, "--bench-render", "gpu")
	stand.verify = args.has("--bench-verify")
	stand.delay = float(_arg_value(args, "--bench-delay", "0"))
	stand.warm = args.has("--bench-warm")
	stand.motes = args.has("--bench-motes")
	stand.superfx = args.has("--bench-superfx")
	stand.superfx_light = args.has("--bench-light")
	var tree := get_tree()
	tree.root.add_child.call_deferred(stand)
	tree.set_deferred("current_scene", stand)
	_setup_screenshot(args)


## Köhnə şaquli menyu — ehtiyat (bax [MainMenu]).
##
## Oyunun girişi artıq [MenuV2]-dir. Köhnəsi bir buraxılış boyu saxlanılır:
## yeni menyu şəbəkə axınını tam üzərinə götürüb və cihazda sınanana qədər
## geri dönüş yolu açıq qalmalıdır.
func _start_old_menu(args: PackedStringArray) -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/main_menu.tscn")
	_setup_screenshot(args)

## Xəritə düzümünün stendi — bütün qab yuxarıdan (bax [MapPreview]).
func _start_map(args: PackedStringArray) -> void:
	var stand = _tool("map_preview").new()
	stand.layout = int(_arg_value(args, "--map-layout", "0"))
	var tree := get_tree()
	tree.root.add_child.call_deferred(stand)
	tree.set_deferred("current_scene", stand)
	_setup_screenshot(args)


## Oyunu menyudan başlayıb REAL girişlə oynayan QA agenti (bax [PlayAgent]).
##
## Menyu adi yolla açılır — agentin işi elə oradan başlamaqdır. Seçimlərin
## hamısı (növ, rejim, keyfiyyət, server) menyunun öz düymələri ilə edilir,
## burada birbaşa `Net`-ə yazılmır.
func _start_agent(args: PackedStringArray) -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/menu.tscn")
	var agent = _tool("play_agent").new()
	agent.out_dir = _arg_value(args, "--agent-out", "user://agent")
	agent.species = int(_arg_value(args, "--agent-species", "-1"))
	agent.mode = int(_arg_value(args, "--agent-mode", "-1"))
	agent.quality = int(_arg_value(args, "--agent-quality", "-1"))
	agent.match_time = float(_arg_value(args, "--agent-time", "60"))
	agent.rounds = maxi(1, int(_arg_value(args, "--agent-rounds", "1")))
	agent.server = _arg_value(args, "--agent-server", "")
	agent.try_dead_server = args.has("--agent-dead-server")
	agent.keyboard_test = not args.has("--agent-no-keys")
	agent.shots_enabled = not args.has("--agent-noshots")
	# Sərt hədd: xarici `timeout`-dan TEZ düşməlidir ki, agent hesabatını
	# yazsın və oyunçunun ayarlarını geri qaytarsın.
	agent.hard_limit = float(_arg_value(args, "--agent-limit",
		str(agent.match_time * agent.rounds + 90.0)))
	get_tree().root.add_child.call_deferred(agent)


## `--perf <saniyə>` verilibsə, kadr vaxtlarını ölçüb hesabat yazır.
func _setup_perf(args: PackedStringArray) -> void:
	var secs := _arg_value(args, "--perf", "")
	if secs.is_empty():
		return
	var probe = _tool("perf_probe").new()
	probe.duration = maxf(float(secs), 3.0)
	get_tree().root.add_child.call_deferred(probe)


## `--frame-probe <saniyə> [--probe-phases]` — kadrın işini hissələrə bölür, fazalarda
## qatları növbə ilə gizlədib payını ölçür (bax `tools/frame_probe.gd`).
func _setup_frame_probe(args: PackedStringArray) -> void:
	var secs := _arg_value(args, "--frame-probe", "")
	if secs.is_empty():
		return
	var probe = _tool("frame_probe").new()
	probe.duration = maxf(float(secs), 5.0)
	probe.phases = args.has("--probe-phases")
	probe.respawn = _spawn_practice.bind(args)
	get_tree().root.add_child.call_deferred(probe)


## `--super-probe N` — superi həqiqi düymə ilə N dəfə basıb yoxlayır (bax `tools/super_probe.gd`).
func _setup_super_probe(args: PackedStringArray) -> void:
	var n := _arg_value(args, "--super-probe", "")
	if n.is_empty():
		return
	var probe = _tool("super_probe").new()
	probe.trials = maxi(1, int(n))
	probe.shots_dir = _arg_value(args, "--super-probe-shots", "")
	get_tree().root.add_child.call_deferred(probe)


## `--shot <yol>` verilibsə, bir neçə kadr sonra görüntü çəkib çıxır.
## Səhnə dəyişimindən sağ çıxsın deyə node kökə əlavə olunur.
func _setup_screenshot(args: PackedStringArray) -> void:
	var shot := _arg_value(args, "--shot", "")
	if shot.is_empty():
		return
	var cam = _tool("screenshot").new()
	cam.path = shot
	cam.delay_frames = int(_arg_value(args, "--shot-delay", "90"))
	cam.count = maxi(1, int(_arg_value(args, "--shot-count", "1")))
	cam.every = maxi(1, int(_arg_value(args, "--shot-every", "6")))
	get_tree().root.add_child.call_deferred(cam)


## Şəbəkə inteqrasiya testi üçün insansız client.
func _start_auto_client(args: PackedStringArray) -> void:
	var client = _tool("auto_client").new()
	client.name = "AutoClient"
	client.host = _arg_value(args, "--host", "127.0.0.1")
	client.port = int(_arg_value(args, "--port", str(Const.DEFAULT_PORT)))
	client.label = _arg_value(args, "--label", "auto")
	client.drop_after = float(_arg_value(args, "--drop-after", "0"))
	client.quit_after = float(_arg_value(args, "--quit-after", "0"))
	client.mode = int(_arg_value(args, "--mode", "0"))
	client.species = int(_arg_value(args, "--species", "0"))
	# Vuruş probe-unun kadrları (bax [HitProbe]) — yalnız pəncərəli client-də.
	client.probe_shots = _arg_value(args, "--probe-shots", "")
	# Dostlar və komanda: `--secret` kimlik, `--befriend-secret` kimə sorğu,
	# `--party N` neçə nəfərlik komanda ilə girmək (bax [AutoClient]).
	client.secret = _arg_value(args, "--secret", "")
	client.befriend_secret = _arg_value(args, "--befriend-secret", "")
	client.party = int(_arg_value(args, "--party", "0"))
	# `--net-probe [--net-probe-csv <fayl>]` — şəbəkə ölçüsü (bax `tools/net_probe.gd`).
	client.net_probe = args.has("--net-probe")
	client.net_probe_csv = _arg_value(args, "--net-probe-csv", "")
	get_tree().root.add_child.call_deferred(client)
	_setup_super_probe(args)

	# `--shot` burada da işləməlidir: onsuz ONLAYN oyunun görüntüsünü çəkmək
	# mümkün deyildi və adların, rənglərin, geri sıçramanın şəbəkə üzərindən
	# vizual yoxlanışı yalnız loglara qalırdı.
	_setup_screenshot(args)


static func _arg_value(args: PackedStringArray, key: String, fallback: String) -> String:
	var i := args.find(key)
	if i >= 0 and i + 1 < args.size():
		return args[i + 1]
	return fallback


func _start_server(args: PackedStringArray) -> void:
	# Railway və bənzər platformalar portu `PORT` mühit dəyişəni ilə verir və
	# ictimai UDP-yə icazə vermir — orada avtomatik WebSocket-ə keçirik.
	var env_port := OS.get_environment("PORT")
	var on_paas := not env_port.is_empty()

	var port := Const.DEFAULT_PORT
	if on_paas and env_port.is_valid_int():
		port = int(env_port)
	else:
		var i := args.find("--port")
		if i >= 0 and i + 1 < args.size():
			port = int(args[i + 1])

	var use_ws := on_paas or args.has("--ws")

	if Net.host_server(port, use_ws) != OK:
		push_error("Server qalxa bilmədi, çıxılır.")
		get_tree().quit(1)
		return

	var lobby := Lobby.new()
	lobby.name = "Lobby"
	lobby.verbose = args.has("--verbose")
	get_tree().root.add_child.call_deferred(lobby)
	print("[boot] server rejimi aktivdir")
