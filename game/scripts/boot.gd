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
		get_tree().quit(SimTest.run())
	elif args.has("--server"):
		_start_server(args)
	elif args.has("--practice"):
		_start_practice(args)
	elif args.has("--autoclient"):
		_start_auto_client(args)
	elif args.has("--preview"):
		_start_preview(args)
	elif args.has("--menu1"):
		_start_old_menu(args)
	elif args.has("--map"):
		_start_map(args)
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

	# `--quality <0|1>` — qrafika səviyyəsi (0 yüksək, 1 aşağı).
	#
	# `--species` və `--mode` ilə eyni səbəb: məşq menyunu keçir, yəni
	# `settings.cfg` oxunmur. Onsuz aşağı keyfiyyətin görüntüsünü təkrarlana
	# bilən şəkildə yoxlamaq mümkün deyil.
	var q := _arg_value(args, "--quality", "")
	if not q.is_empty():
		Net.quality = Const.quality_from(int(q))

	# `--at x,y` — mikrobu xəritənin müəyyən yerində doğurur (yalnız yoxlama).
	# `configure_practice`-dən ƏVVƏL oxunmalıdır: yerli dünya mikrobu məhz
	# orada yaradır. Sonra qoyulsaydı proqnoz yeni yerdə, server isə köhnə
	# yerdə olardı və ilk düzəliş mikrobu geri sıçradardı.
	var at := _arg_value(args, "--at", "")

	var arena: Arena = load("res://scenes/game/arena.tscn").instantiate()
	if not at.is_empty():
		var parts := at.split(",")
		if parts.size() == 2:
			arena.start_at = Vector2(float(parts[0]), float(parts[1]))
	arena.configure_practice()
	arena.auto_input = args.has("--shot")   # görüntü üçün mikrob hərəkətdə olsun
	var tree := get_tree()
	tree.root.add_child.call_deferred(arena)
	tree.set_deferred("current_scene", arena)

	_setup_screenshot(args)
	_setup_perf(args)


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


## Növün görüntü stendi — oyun məntiqi olmadan tək mikrob (bax [SpeciesPreview]).
func _start_preview(args: PackedStringArray) -> void:
	var stand := SpeciesPreview.new()
	stand.species = Const.species_from(int(_arg_value(args, "--preview-species", "2")))
	stand.balls = int(_arg_value(args, "--preview-balls", "9"))
	stand.capacity = int(_arg_value(args, "--preview-cap", "16"))
	stand.fire_every = float(_arg_value(args, "--preview-fire", "0"))
	stand.speed_scale = float(_arg_value(args, "--preview-speed", "1"))
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
	var stand := MapPreview.new()
	stand.layout = int(_arg_value(args, "--map-layout", "0"))
	var tree := get_tree()
	tree.root.add_child.call_deferred(stand)
	tree.set_deferred("current_scene", stand)
	_setup_screenshot(args)


## `--perf <saniyə>` verilibsə, kadr vaxtlarını ölçüb hesabat yazır.
func _setup_perf(args: PackedStringArray) -> void:
	var secs := _arg_value(args, "--perf", "")
	if secs.is_empty():
		return
	var probe := PerfProbe.new()
	probe.duration = maxf(float(secs), 3.0)
	get_tree().root.add_child.call_deferred(probe)


## `--shot <yol>` verilibsə, bir neçə kadr sonra görüntü çəkib çıxır.
## Səhnə dəyişimindən sağ çıxsın deyə node kökə əlavə olunur.
func _setup_screenshot(args: PackedStringArray) -> void:
	var shot := _arg_value(args, "--shot", "")
	if shot.is_empty():
		return
	var cam := Screenshot.new()
	cam.path = shot
	cam.delay_frames = int(_arg_value(args, "--shot-delay", "90"))
	get_tree().root.add_child.call_deferred(cam)


## Şəbəkə inteqrasiya testi üçün insansız client.
func _start_auto_client(args: PackedStringArray) -> void:
	var client := AutoClient.new()
	client.name = "AutoClient"
	client.host = _arg_value(args, "--host", "127.0.0.1")
	client.port = int(_arg_value(args, "--port", str(Const.DEFAULT_PORT)))
	client.label = _arg_value(args, "--label", "auto")
	client.drop_after = float(_arg_value(args, "--drop-after", "0"))
	client.quit_after = float(_arg_value(args, "--quit-after", "0"))
	client.mode = int(_arg_value(args, "--mode", "0"))
	client.species = int(_arg_value(args, "--species", "0"))
	get_tree().root.add_child.call_deferred(client)

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
