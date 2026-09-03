class_name Arena
extends Node2D
## Oyun ekranı: girişi toplayır, proqnoz qurur, serverin sözünü qəbul edir və çəkir.
##
## Üç fərqli zaman xətti burada birləşir:
##   1. İndi         — öz mikrobun. Girişi dərhal tətbiq olunur (prediction).
##   2. 100 ms əvvəl — rəqiblər, toplar və qida. Snapshot-lar arasında interpolyasiya.
##   3. Serverin sözü — snapshot gələndə öz vəziyyətin düzəldilir (reconciliation).
##
## Rəqibləri qəsdən 100 ms geridə göstəririk: paket itsə belə interpolyasiya üçün
## əlimizdə həmişə iki snapshot olur, hərəkət titrəmir.
##
## Dünya ekrandan böyükdür, ona görə kamera mikrobu izləyir və tutum böyüdükcə
## uzaqlaşır — böyük mikrob daha geniş sahə görür.

const SNAP_BUFFER_MAX := 24
const FX_LIFETIME := 0.26

## Bağlantı kəsiləndə neçə dəfə və hansı aralıqla qayıtmağa çalışırıq.
## Serverin saxladığı müddətə (Lobby.REJOIN_GRACE = 20 s) sığmalıdır.
const REJOIN_ATTEMPTS := 5
const REJOIN_INTERVAL := 3.0

## Qida sprite-ının miqyası — 32 px-lik şəkil FOOD_RADIUS ilə uyğunlaşdırılır.
const FOOD_SCALE := 0.85

## Serverin artıq bildirmədiyi obyektin görüntüsü bu qədər saniyə saxlanılır.
##
## Rəqəm təsadüfi deyil: biz keçmişi göstəririk (INTERP_DELAY = 100 ms), ona görə
## obyekt son görüldüyü andan düz bir interpolyasiya gecikməsi sonra ekrandan
## çıxmalıdır — nə tez (udulan qida qığılcımdan əvvəl yox olar), nə gec
## (udulmuş qida ekranda qalar). Üstünə bir tick əlavə olunur ki, itən bir
## paket obyekti yanıb-söndürməsin.
const VIEW_GRACE := Const.INTERP_DELAY + Const.TICK_DELTA

## Yerli doğuş nöqtəsi bu qədər saniyə gözləyir (bax [method _remember_muzzle]).
##
## Atəş fasiləsindən (FIRE_COOLDOWN = 1 s) KİÇİK olmalıdır: belə olanda
## növbədə heç vaxt iki gözləyən atəş qalmır, yəni səhv uyğunlaşma mümkün
## deyil. Serverin qəbul etmədiyi atəş isə özü düşüb gedir.
const MUZZLE_GRACE := 0.6

## Server "super hələ işləyir" deyəndə proqnozun sayğacının uzadıldığı vaxt.
##
## Üç tick-dir: bir tick bayrağın öz gecikməsi, qalan ikisi itən paket üçün
## ehtiyat. Uzun olsaydı, super serverdə bitəndən sonra da ekranda qalardı
## (bax [method _reconcile]).
const SUPER_TAIL := Const.TICK_DELTA * 3.0

# ---------------------------------------------------------------- vəziyyət

var my_id := 0
var my_color := 0
var practice := false

var pred: Sim                       ## Yalnız lokal mikrobu saxlayan proqnoz
var me: Sim.GermState
var pending: Array[Sim.PlayerInput] = []
## Serverin son dediyi "super işləyir" biti — qalxma anını tutmaq üçün
## saxlanılır (bax [method _reconcile]).
var _super_on_srv := false

## Şəbəkə testi üçün: joystick əvəzinə avtomatik giriş üretilir.
var auto_input := false

var _seq := 0
var _tick_accum := 0.0

## Öz mikrobunun ÇƏKİLİŞ üçün interpolyasiya edilən vəziyyəti.
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Proqnoz server tick-i ilə addımlayır (saniyədə 30), ekran isə 60 kadr çəkir.
## Yəni öz mikrobunun mövqeyi hər İKİ kadrdan birində dəyişir. Ölçüldükdə:
## "60 kadr çəkildi, öz mövqeyim yalnız 30 dəfə dəyişdi".
##
## Kamera da həmin mövqeyə bağlıdır, ona görə nəticə yalnız mikrobun yox,
## BÜTÜN dünyanın 30 Hz-lə pilləli sürüşməsidir — ekranda bu, "ilişmək" kimi
## oxunur. Rəqiblər bu problemi yaşamır: onlar hər kadrda snapshot-lar arasında
## interpolyasiya olunur ([method _render_germs]), yəni 60 Hz-də hamardır.
## Oyunçunun "botlarda hər şey düzgündür, mənimki ilişir" müşahidəsinin
## səbəbi məhz bu fərq idi.
##
## Həll: tick-dən əvvəlki və sonrakı vəziyyət saxlanılır, çəkiliş isə aradakı
## nisbətə görə qarışdırılır. Bunun bir tick-ə qədər (33 ms) görüntü gecikməsi
## var; simulyasiya isə TOXUNULMAZ qalır — yalnız göstərilən nöqtə yumşalır.
var _pos_prev := Vector2.ZERO
var _pos_curr := Vector2.ZERO
var _aim_prev := 0.0
var _aim_curr := 0.0
var _clock := 0.0
var _snaps: Array[Dictionary] = []  ## {"t": lokal vaxt, "d": snapshot}
var _last_snap: Array = []
var _finished := false

## Mikroba qayıtmaq üçün sessiya nişanı — serverdən dünyaya girəndə gəlir.
var _token := ""
var _reconnecting := false
var _rejoin_left := 0

var _local_world: World = null      ## Yalnız məşq rejimində

# ---------------------------------------------------------------- vizual

var _cam: Camera2D
var _blobs: Node2D
var _food_layer: Node2D
var _shot_layer: Node2D
var _entities: Node2D
var _fx: Node2D
var _trails: ShotTrails
## Maneə sprite-ları — indeks [method DishMap.obstacles] ilə eynidir, ona görə
## dağılan divarı serverin göndərdiyi indekslə tapmaq olur.
var _blob_nodes: Array[Sprite2D] = []
## Kolun üst yarpaq qatı — mikrobların üstündə çəkilir (bax [method _build_world]).
var _canopy: Node2D
## Üst yarpaqların node-ları, indeks [method DishMap.obstacles] ilə eynidir.
var _canopy_nodes := {}
## Dağılmış maneələr (serverin sözü). Kölgə çəkilişi bunu oxuyur.
var _broken := PackedByteArray()
var _motes: WaterMotes
## Dərin su qatı — maneələrin üstündə, qidanın altında (bax [method _build_world]).
var _motes_deep: WaterMotes
var _hud: Hud

var _visuals := {}                  ## germ id -> {"node": GermVisual, "seen": float}

## Ad və rəng cədvəli — `{id: [ad, rəng]}` (bax [method Net.on_roster]).
##
## Snapshot-da daşınmır: sabit dəyərləri saniyədə 30 dəfə göndərmək paketi
## MTU-dan yuxarı qaldırırdı.
var _roster := {}
var _roster_rev := -1
var _food_views := {}               ## food id -> {"node": Sprite2D, "seen": float}

## Sprite HOVUZLARI — qida və toplar üçün.
##
## Partlayan mikrob BİR kadrda 24-ə qədər qida yaradır
## (bax [method Sim._burst]) və client həmin kadrda 24 dəfə `Sprite2D.new()`
## + `add_child` çağırırdı. Ölçülüb: 25 saniyəlik oyunda 2-3 kadr 60 FPS
## büdcəsini aşırdı, ən pisi 68 ms — masaüstündə görünmür (orta 1.9 ms),
## telefonda isə açıq "ilişmə"dir.
##
## Hovuz yaratmanı sıfıra endirir: node bir dəfə qurulur, sonra gizlədilib
## təkrar işlədilir. Qat başına ayrı hovuz var ki, valideyn dəyişməsin —
## `reparent` özü də ucuz deyil.
var _food_pool: Array[Sprite2D] = []
var _shot_pool: Array[Sprite2D] = []
var _shot_views := {}               ## shot id -> Dictionary
## Öz atəşlərinin doğuş nöqtələri — serverin topu təsdiqləməsini gözləyir
## (bax [method _remember_muzzle]).
var _muzzles: Array[Dictionary] = []
var _fx_queue: Array[Dictionary] = []
var _tex := {}
var _view_span := Const.VIEW_SPAN_BASE
var _shake := 0.0

## Serverdən gələn matç vəziyyəti (bax [enum Const.MF]).
##
## Qabın kənarı BURADAN gəlir, düsturla hesablanmır: faza keçidləri saatı
## sıfırlayır və client-in öz saatı serverdən bir neçə tick geri qala bilər.
## Bir float göndərmək həmin riski büsbütün silir.
var _mode := Const.Mode.ENDLESS
var _phase := Const.Phase.PLAYING
var _phase_t := 0.0
var _wet_radius := Const.WORLD_RADIUS
var _alive := 0
var _place := 0
## Baxanın komandası (-1 komandasız) — serverdən gəlir (bax [enum Const.MF]).
var _my_team := -1
var _score_us := 0
var _score_em := 0

## ── Zərbə hissi ──────────────────────────────────────────────────────────

## Donmuş kadr: öldürmə anında ekran bir anlıq DAYANIR.
##
## YALNIZ görüntü donur — kamera və mikrob animasiyaları. Simulyasiya,
## proqnoz və şəbəkə tam sürətlə işləməyə davam edir.
##
## `Engine.time_scale` ilə donduran variant QƏSDƏN seçilməyib: o, `_process`
## deltasını da kiçildir, yəni proqnoz tick-ləri yavaşıyır və serverə daha az
## giriş gedir. Server isə 30 Hz-lə işləməyə davam edir — nəticədə client geri
## qalır və donma bitəndə düzəliş mikrobu sıçradır. Yəni zərbə hissi üçün
## qoyulan effekt öz zərbəsini yeyərdi.
const FREEZE_TIME := 0.075
var _freeze := 0.0

## Kamera zərbəsi — partlayış anında görüntü bir anlıq YAXINLAŞIR.
##
## Silkələnmə (bax [member _shake]) hadisənin OLDUĞUNU deyir, zərbə isə
## onun BÖYÜKLÜYÜNÜ. İkisi birlikdə işləyir: silkələnmə mövqeyə, zərbə
## miqyasa toxunur, ona görə bir-birini pozmurlar.
var _punch := 0.0

## Öz tutumun — artımı tutmaq üçün saxlanılır (bax [method _watch_capacity]).
## Hadisə ilə gəlmir: tutum artımı snapshot-dakı sahədir, ayrıca hadisə deyil.
var _last_cap := 0

## Öz mikrobun kolun içindədirmi (bax [method _watch_bush]).
var _hidden := false
## "Gizləndin" yazısı artıq göstərilibmi.
var _bush_taught := false


# ================================================================ quraşdırma

## Serverdən "dünyaya girdin" mesajı gələndə çağırılır. add_child-dan ƏVVƏL.
func configure_online(info: Dictionary) -> void:
	practice = false
	my_id = int(info["you"])
	my_color = int(info.get("color", 0))
	Net.species = _species_from(info)
	_token = str(info.get("token", ""))


## Serverin təsdiqlədiyi növ.
##
## Menyudakı seçim TƏKLİFDİR, son söz serverindir: yenidən qoşulanda oyunçu
## köhnə mikrobuna qayıdır və onun növü artıq dünyada qeydə alınıb.
## Etibarsız dəyər gəlsə kirpikliyə düşür.
static func _species_from(info: Dictionary) -> Const.Species:
	return Const.species_from(int(info.get("species", 0)))


## Şəbəkəsiz məşq. Eyni [World] və [Sim] kodu yerli işləyir — fərq yalnız
## snapshot-ların şəbəkədən yox, yaddaşdan gəlməsidir.
## Məşqdə mikrobun doğuş yeri. `Vector2.INF` = adi (təsadüfi) doğuş.
##
## YALNIZ yoxlama üçündür (`--at x,y`). Xəritənin bir hissəsini gözlə görmək
## üçün başqa yol yoxdur: doğuş təsadüfidir, kol və cərəyan deşiyi isə
## dünyanın müəyyən yerlərindədir, ona görə "kolun içi necə görünür"
## sualına ekran görüntüsü ilə cavab vermək təsadüfə qalırdı.
var start_at := Vector2.INF


func configure_practice() -> void:
	practice = true
	my_id = 1000
	_local_world = World.new(1, Net.mode)
	var g := _local_world.add_player(my_id, Net.nickname, Net.species)
	my_color = g.color
	if start_at.is_finite():
		g.pos = start_at
		g.vel = Vector2.ZERO


func _ready() -> void:
	_build_glow()
	_load_textures()
	_build_world()
	_build_hud()
	_init_prediction()

	Net.snapshot_arrived.connect(_on_snapshot)
	Net.roster_arrived.connect(_on_roster)
	Net.you_burst.connect(_on_you_burst)
	Net.server_disconnected.connect(_on_server_lost)
	Net.connected_to_server.connect(_on_reconnected)
	Net.world_joined.connect(_on_rejoin_accepted)
	Net.rejoin_failed.connect(_on_rejoin_rejected)

	_hud.show_message("DÜNYAYA GİRDİN", "Qida ye, rəqibi doldur, partlat")
	get_tree().create_timer(2.0).timeout.connect(_hud.hide_message)
	Sfx.play("spawn")


## Bioluminessensiya — parlaq piksellər ətrafa işıq saçır.
##
## `gl_compatibility` renderer-ində DƏ işləyir, amma iki şərtlə:
##   1. `rendering/viewport/hdr_2d` açıq olmalıdır (bax `project.godot`),
##      yoxsa rənglər 1.0-da kəsilir və hədd heç vaxt keçilmir;
##   2. hədd 1.0-dan AŞAĞI olmalıdır, çünki oyunun bütün rəngləri
##      `Palette`-də ≤ 1.0-dır — heç nə HDR diapazonuna çıxmır.
##
## Hədd 0.62 seçilib: mikrob rəngləri (ən parlaq komponenti 1.0) və qida
## saçır, qabın döşəməsi (0.05) və şəbəkə isə toxunulmaz qalır. Yəni fon
## bulanmır — yalnız CANLI olan şeylər işıq verir.
func _build_glow() -> void:
	# AŞAĞI keyfiyyətdə glow QURULMUR.
	#
	# Glow tam ekranı bir neçə dəfə bulandıran keçiddir və `hdr_2d` ilə birlikdə
	# kadr buferini RGBA16F-ə qaldırır — mobil GPU-da hər kadr iki dəfə çox
	# yaddaş zolağı. Söndürəndə HDR buferi də söndürülür, yoxsa bahalı format
	# heç nəyə xidmət etmədən qalır.
	if Net.quality == Const.Quality.LOW:
		get_viewport().use_hdr_2d = false
		return

	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.62
	env.glow_intensity = 1.15
	env.glow_strength = 1.20
	env.glow_bloom = 0.14
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _load_textures() -> void:
	_tex = {
		"food": load("res://assets/sprites/food_ball.svg"),
		"floor": load("res://assets/sprites/dish_floor.svg"),
		"blob": load("res://assets/sprites/mucus_blob.svg"),
		"crust": load("res://assets/sprites/mucus_crust.svg"),
		# Qabığın zədə mərhələləri — 1 və 2 zərbədən sonra (bax [method _apply_walls]).
		"crust2": load("res://assets/sprites/mucus_crust2.svg"),
		"crust3": load("res://assets/sprites/mucus_crust3.svg"),
		"bloom": load("res://assets/sprites/mucus_bloom.svg"),
		"bush": load("res://assets/sprites/mucus_bush.svg"),
		# Kolun ÜST yarpaqları — mikrobun üstündən keçir (bax [member _canopy]).
		"bush_top": load("res://assets/sprites/mucus_bush_top.svg"),
		"vent": load("res://assets/sprites/mucus_vent.svg"),
		"shot": load("res://assets/sprites/shot_ball.svg"),
		"spark": load("res://assets/sprites/spark.svg"),
		"burst": load("res://assets/sprites/burst.svg"),
		"stick_base": load("res://assets/ui/joystick_base.svg"),
		"stick_knob": load("res://assets/ui/joystick_knob.svg"),
	}


## Səhnə qatları QƏSDƏN növlərə ayrılıb: bütün qida sprite-ları bir qatda,
## bütün toplar başqasında, mikroblar üçüncüsündə.
##
## Səbəb çəkiliş çağırışıdır: Godot yalnız ARDICIL və eyni teksturalı
## elementləri bir çağırışa yığır. Hamısı bir node-un altında qarışıq
## dursaydı, hər qida topu ayrıca çağırış olardı.
func _build_world() -> void:
	# Qab və şəbəkə bu node-un öz `_draw`-ında çəkilir (bax [method _draw]):
	# statik məzmundur və uşaqların arxasında qalır.
	_blobs = Node2D.new()
	add_child(_blobs)
	_spawn_obstacles()

	# Suda asılı zərrəciklər — qabın döşəməsi ilə oyun obyektləri arasındakı
	# "su" qatı. Sırası MƏHZ buradadır: bu node-un öz `_draw`-ı (döşəmə) və
	# maneələr artıq çəkilib, qida ilə mikroblar isə sonra əlavə olunur.
	# İKİ dərinlik qatı — su bir qat deyil, SÜTUNDUR.
	#
	# Dərin qat maneələrin dərhal üstündədir və sönükdür; səth qatı isə
	# qidanın altında qalır, amma parlaqdır. Aralarındakı sürət fərqi
	# parallaks verir və dərinlik hissi elə buradan gəlir.
	#
	# Zərrəcik sayı ARTMIR (110 ikiyə bölünür), ona görə əlavə yük yalnız
	# ikinci  çağırışıdır.
	_motes_deep = WaterMotes.new()
	# Zərrəcik sıxlığı da keyfiyyətdən asılıdır: onlar oyuna təsir etmir,
	# yalnız suyun canlı görünməsi üçündür — ilk kəsiləcək şey budur.
	_motes_deep.count = 80 if Net.quality == Const.Quality.HIGH else 34
	_motes_deep.depth = 1.0
	add_child(_motes_deep)

	_motes = WaterMotes.new()
	_motes.count = 30 if Net.quality == Const.Quality.HIGH else 14
	add_child(_motes)

	_food_layer = Node2D.new()
	add_child(_food_layer)

	# İzlər toplardan ƏVVƏL əlavə olunur: arxada qalmalıdırlar.
	_trails = ShotTrails.new()
	add_child(_trails)

	_shot_layer = Node2D.new()
	add_child(_shot_layer)

	_entities = Node2D.new()
	add_child(_entities)

	# KOLUN ÜST YARPAQLARI — mikrobların ÜSTÜNDƏ.
	#
	# Dərinliyin ən güclü işarəsi rəng deyil, ÖRTÜLMƏDİR. Kolun içindəki mikrob
	# indiyə qədər kolun üstündə dayanırdı: gizlənmə qaydası yalnız serverdə
	# mövcud idi, ekranda isə heç nə onu demirdi. İndi frondlar mikrobun
	# üstündən keçir və "nəyinsə altındayam" izahsız oxunur.
	#
	# Effektlərdən ƏVVƏLdir: partlayış və qığılcım yarpaqların da üstündə
	# olmalıdır, yoxsa kolda baş verən ölüm yarımçıq görünür.
	_canopy = Node2D.new()
	add_child(_canopy)
	_spawn_canopy()

	_fx = Node2D.new()
	add_child(_fx)

	_cam = Camera2D.new()
	_cam.enabled = true
	add_child(_cam)


## Maneə növü → sprite.
##
## Toqquşma həndəsəsi bütün növlərdə EYNİDİR (dairə, radius `Vector4.z`) və
## beş sprite-ın da xarici dairəsi eynidir. Fərq YALNIZ forma dilindədir:
## oyunçu bir baxışda qaydanı oxumalıdır — keçə bilərəmmi, sındıra bilərəmmi.
##
## SELİK iki naxışa bölünür (mövqedən asılı olaraq `blob` və ya `bloom`):
## dünyada 22 maneə var və eyni qaydanın 12 eyni şəkli oriyentiri öldürürdü.
## Qalan növlərin hər birinin TƏK şəkli var — onlar qaydadır, bəzək deyil,
## və qaydanın iki görkəmi olmamalıdır.
const BLOB_TEXTURE := {
	DishMap.Kind.BUSH: "bush",
	DishMap.Kind.BRITTLE: "crust",
	DishMap.Kind.VENT: "vent",
}

## Çəkiliş sırası: hər tekstura ARDICIL getməlidir, yoxsa batch qırılır
## (bax [method _spawn_obstacles]).
const BLOB_ORDER := ["blob", "bloom", "crust", "bush", "vent"]

## Sprite-dakı ləkənin radiusu (bax `mucus_blob.svg`).
const BLOB_SPRITE_RADIUS := 120.0


func _spawn_obstacles() -> void:
	var list := DishMap.obstacles()
	_blob_nodes.resize(list.size())

	# Teksturaya görə qruplaşdırma. Godot yalnız ARDICIL və eyni teksturalı
	# elementləri bir çağırışa yığır — qarışıq düzülsəydi hər tekstura
	# dəyişimi yeni çağırış olardı (22 maneə üçün ~22 çağırış). Belə isə
	# cəmi BEŞ çağırışdır.
	var by_tex := {}
	for name in BLOB_ORDER:
		by_tex[name] = []
	for i in list.size():
		by_tex[_blob_texture(list[i])].append(i)

	for name in BLOB_ORDER:
		for i in by_tex[name]:
			var o: Vector4 = list[i]
			var spr := Sprite2D.new()
			spr.texture = _tex[name]
			spr.position = Vector2(o.x, o.y)
			spr.scale = Vector2.ONE * (o.z / BLOB_SPRITE_RADIUS)
			# Maneələr FIRLADILMIR — və bu, unudulma deyil.
			#
			# Əvvəl hər ləkə `(o.x + o.y) * 0.01` radian fırladılırdı ki, eyni
			# şəklin təkrarı bilinməsin. Ölçü isə yüzlərlədir: x=400, y=300 üçün
			# bu, 7 radian ≈ 401°, yəni bucaq FAKTİKİ TƏSADÜFİDİR. Sprite-ın
			# içindəki qradiyent yuxarı-soldan işıqlanıb, ona görə fırlanma
			# İŞIĞI da fırladırdı: 26 maneənin hər birində işıq başqa tərəfdən
			# gəlirdi və qradiyent həcm yox, rəng ləkəsi kimi oxunurdu.
			#
			# Naxış variasiyası lazımdırsa, EYNİ istiqamətdə işıqlandırılmış
			# ayrı sprite variantı seçilməlidir (bax [method _blob_texture]).
			#
			# Cərəyan deşiyi isə əksinə — qabın MƏRKƏZİNƏ döndərilir, çünki
			# qüvvə məhz oraya itələyir (bax [method Sim._vent_push]).
			if int(o.w) == DishMap.Kind.VENT:
				spr.rotation = (-Vector2(o.x, o.y)).angle()
			# QEYD: burada hər sprite-a ayrıca `modulate` verilirdi (±6%
			# parlaqlıq). ÇIXARILDI, ölçmə ilə: `gl_compatibility` batch-i eyni
			# `modulate` tələb edir, ona görə 22 fərqli rəng 22 AYRI çağırış
			# demək idi (131 → 242, ən pis kadr 11 ms → 70 ms).
			_blobs.add_child(spr)
			_blob_nodes[i] = spr


## Kolların üst yarpaqlarını doğurur.
##
## Yalnız KOL üçün: bərk maneənin üstündən keçən yarpaq olmaz, cərəyan deşiyi
## isə döşəmədəki dəlikdir. Hamısı bir node-un altındadır və eyni teksturadır,
## yəni cəmi BİR əlavə çəkiliş çağırışıdır.
func _spawn_canopy() -> void:
	var list := DishMap.obstacles()
	for i in list.size():
		var o: Vector4 = list[i]
		if int(o.w) != DishMap.Kind.BUSH:
			continue
		var spr := Sprite2D.new()
		spr.texture = _tex["bush_top"]
		spr.position = Vector2(o.x, o.y)
		spr.scale = Vector2.ONE * (o.z / BLOB_SPRITE_RADIUS)
		_canopy.add_child(spr)
		_canopy_nodes[i] = spr


## Bu maneə hansı sprite ilə çəkilir?
##
## SELİK iki naxış arasında MÖVQEYƏ görə bölünür, təsadüfə görə yox: eyni
## maneə hər açılışda eyni görünməlidir, yoxsa xəritə yadda saxlanıla bilməz.
static func _blob_texture(o: Vector4) -> String:
	var kind := int(o.w)
	if BLOB_TEXTURE.has(kind):
		return BLOB_TEXTURE[kind]
	var pick := int(absf(o.x) * 0.37 + absf(o.y) * 0.61 + o.z * 1.7)
	return "bloom" if pick % 2 == 1 else "blob"


func _build_hud() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_hud.build(_tex["stick_base"], _tex["stick_knob"])
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.fire_button.fired.connect(_on_fire_pressed)
	_hud.super_button.used.connect(_on_super_pressed)


func _init_prediction() -> void:
	pred = Sim.new()
	# Növ MÜTLƏQ verilməlidir: passiv özəlliklər (sürətlənmə, sönmə, axına
	# tabelik, maneə radiusu) növdən çıxır və proqnoz onları serverlə eyni
	# hesablamalıdır. Növsüz yaradılsaydı, hər növ kirpikli kimi proqnozlaşdırılar
	# və mikrob hər snapshot-da geri sıçrayardı.
	me = pred.add_germ(my_id, Net.nickname, my_color, false, Net.species)
	# Proqnoz da eyni yerdən başlamalıdır, yoxsa ilk snapshot mikrobu
	# ekranın o biri başına sıçradır.
	if start_at.is_finite():
		me.pos = start_at
		me.vel = Vector2.ZERO
	_sync_shown()


## Çəkiliş nöqtəsi: iki proqnoz tick-i arasında hara düşdüyümüzə görə.
##
## [member _tick_accum] tick-dən sonra qalan vaxtdır, yəni nisbət elə odur.
func _shown_pos() -> Vector2:
	return _pos_prev.lerp(_pos_curr, clampf(_tick_accum / Const.TICK_DELTA, 0.0, 1.0))


func _shown_aim() -> float:
	return lerp_angle(_aim_prev, _aim_curr, clampf(_tick_accum / Const.TICK_DELTA, 0.0, 1.0))


## İnterpolyasiyanın hər iki ucunu indiki vəziyyətə bərabərləşdirir.
##
## Mövqe tick-dən KƏNARDA dəyişəndə (doğuş, serverin düzəlişi) çağırılmalıdır:
## əks halda çəkiliş köhnə nöqtədən yenisinə doğru sürünər və düzəliş
## oyunçuya "sürüşmə" kimi görünər.
func _sync_shown() -> void:
	_pos_prev = me.pos
	_pos_curr = me.pos
	_aim_prev = me.aim
	_aim_curr = me.aim


# ================================================================ dövr

func _process(delta: float) -> void:
	_clock += delta

	_tick_accum += delta
	var steps := 0
	while _tick_accum >= Const.TICK_DELTA and steps < 5:
		_tick_accum -= Const.TICK_DELTA
		steps += 1
		_do_tick()
	if steps == 5:
		_tick_accum = 0.0

	_render(delta)


func _do_tick() -> void:
	if _finished or _reconnecting:
		return

	var inp := _sample_input()

	if _local_world != null:
		_local_world.accept_input(my_id, inp.to_array())
		var bursts := _local_world.tick(Const.TICK_DELTA)
		# Məşq rejimində şəbəkə yoxdur, ona görə reyestri birbaşa götürürük.
		# Yalnız dəyişəndə: hər tick sözlük qurmaq boş yükdür.
		if _local_world.roster_rev != _roster_rev:
			_roster_rev = _local_world.roster_rev
			_on_roster(_local_world.roster())
		_on_snapshot(_local_world.snapshot_for(my_id))
		for entry in bursts:
			if int(entry["id"]) == my_id:
				_on_you_burst({
					"pops": entry["pops"], "cap": entry["cap"],
					"level": Const.level_of(int(entry["cap"])),
					"age": entry["age"], "killer": entry["killer_name"],
				})

		# Matçı sağ bitirmək — onlayn oyunda bunu [Lobby] göndərir, burada isə
		# Lobby yoxdur. Növbə boşaldılmasaydı, məşqdə qalib heç nə görməzdi və
		# rejimin ən vacib ekranı yalnız serverdə sınana bilərdi.
		for res in _local_world.pending_results:
			if int(res["id"]) == my_id:
				_on_you_burst({
					"pops": res["pops"], "cap": res["cap"],
					"level": Const.level_of(int(res["cap"])),
					"age": res["age"], "killer": "", "won": res["won"],
					"survived": true, "timed_out": res["timed_out"],
				})
		_local_world.pending_results.clear()
	else:
		Net.send_input.rpc_id(1, inp.to_array())

	pending.append(inp)
	while pending.size() > Const.INPUT_BUFFER_MAX:
		pending.pop_front()

	# Öz hərəkətini dərhal göstəririk — server cavabını gözləsək, idarə ağır hiss olunardı.
	# Tick-dən ƏVVƏLKİ vəziyyət saxlanılır: çəkiliş iki tick arasında
	# interpolyasiya olunur (bax [method _shown_state]).
	_pos_prev = me.pos
	_aim_prev = me.aim
	pred.step_movement({my_id: inp}, Const.TICK_DELTA, true)
	_pos_curr = me.pos
	_aim_curr = me.aim
	for e in pred.events:
		if e.get("t") == "fire":
			_spawn_fx("spark", e["pos"], 0.5, Palette.germ_color(my_color))
			Sfx.play("eject", 0.06)
			_eject_from(my_color, float(e["arg"]))
			_remember_muzzle(Vector2(e["pos"]), float(e["arg"]))

	_hud.set_fire_state(me.cooldown / Const.FIRE_COOLDOWN, me.balls >= Const.FIRE_MIN_BALLS)
	_hud.set_super(float(me.charge) / float(Const.SUPER_MAX), me.super_ready())
	if _mode != Const.Mode.ENDLESS:
		_hud.set_match(int(_mode), _phase, _phase_t, _alive,
			me.pos.length() > _wet_radius,
			_score_us, _score_em, _score_us + _score_em + 1)
	_hud.update_gauge(me.balls, me.capacity)


## Joystick-dən bir tick-lik giriş yığır.
func _sample_input() -> Sim.PlayerInput:
	_seq += 1
	if auto_input:
		return _auto_sample()

	var move := _hud.move_stick.value

	# Masaüstündə klaviatura joysticki əvəz edir. Bu, yalnız rahatlıq deyil:
	# siçan bir toxunuş kimi emulyasiya olunur, yəni eyni anda həm hərəkət,
	# həm atəş mümkün olmur — PC-də oyunu sınamağın yeganə düzgün yolu budur.
	if move == Vector2.ZERO:
		move = _keyboard_move()

	# Nişan almaq yoxdur — getdiyin tərəfə atırsan. Dayanmısansa, son baxdığın
	# tərəf qalır ki, yerində durub atmaq da mümkün olsun.
	var aim := me.aim
	if move.length() > 0.01:
		aim = move.angle()

	# Geriyə sayımda mikrob tərpənmir — server də girişi qəbul etmir
	# ([method World.accept_input]). İkisi eyni qaydanı tətbiq etməlidir,
	# yoxsa proqnoz serverdən qabağa düşür və sayım bitəndə mikrob geri sıçrayır.
	if _phase == Const.Phase.COUNTDOWN:
		return Sim.PlayerInput.make(_seq, Vector2.ZERO, me.aim, false, false)
	return Sim.PlayerInput.make(_seq, move, aim, _fire_requested(), _super_requested())


## WASD / ox düymələri. Diaqonal da normallaşdırılır ki, çəp getmək
## sürət qazandırmasın.
static func _keyboard_move() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	return v.limit_length(1.0)


var _fire_flag := false
var _super_flag := false
var _super_key_held := false


## Düymə basılı saxlanılanda atəş davam edir; bayraq isə bir kadrdan qısa
## toxunuşun itməməsi üçündür. İkisi də sürəti təyin etmir — onu serverdəki
## `FIRE_COOLDOWN` müəyyən edir, ona görə döyəcləmək heç nə qazandırmır.
## Boşluq düyməsi masaüstü üçündür (bax [method _keyboard_move]).
## Siçanın sol düyməsi QƏSDƏN buraya qoşulmayıb: o, ekran joystickini idarə edir,
## atəşə də bağlansaydı sürüşdürərək hərəkət edən oyunçu fasiləsiz atardı.
func _fire_requested() -> bool:
	var f := _fire_flag
	_fire_flag = false
	return f or _hud.fire_button.held \
		or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER)


func _on_fire_pressed() -> void:
	_fire_flag = true


## Super YALNIZ basılan kadrda göndərilir, atəş kimi basılı saxlanmır.
##
## Səbəb: super bir dəfəlik hadisədir və doluluq dolan kimi barmaq düymənin
## üstündə qalsa, oyunçu istəmədən dərhal işlədərdi. Klaviatura qarşılığı
## masaüstü sınağı üçündür (bax [method _keyboard_move]).
## Klaviatura KƏNARI əl ilə tutulur: Godot-da düymə üçün "just pressed"
## funksiyası yoxdur (o, yalnız təyin olunmuş `action`-lar üçündür), basılı
## saxlanan düymə isə superi dolan kimi işlədərdi.
func _super_requested() -> bool:
	var v := _super_flag
	_super_flag = false
	var key := Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_Q)
	var edge := key and not _super_key_held
	_super_key_held = key
	return v or edge


func _on_super_pressed() -> void:
	_super_flag = true


## Avtomatik giriş — şəbəkə testində insansız client üçün.
##
## Sadə olsa da acından ölməməlidir: topu azalanda qidaya gedir, çox olanda
## rəqibə. Əks halda test client-i bir neçə saniyəyə partlayır və şəbəkə
## axını heç sınaqdan keçmir.
func _auto_sample() -> Sim.PlayerInput:
	var move := Vector2(sin(_clock * 1.3), cos(_clock * 0.9))
	var aim := me.aim
	var hungry := me.balls <= Const.FIRE_MIN_BALLS + 2

	var meal := _nearest_food()
	var target := _nearest_enemy()

	if hungry and not meal.is_empty():
		var to_food: Vector2 = Vector2(meal["pos"]) - me.pos
		move = to_food.normalized()
		aim = to_food.angle()
	elif not target.is_empty():
		var to: Vector2 = Vector2(target["pos"]) - me.pos
		aim = to.angle()
		move = to.normalized() if to.length() > 320.0 else -to.normalized()

	# Super dolubsa, amma top ÇATMIRSA, atəş saxlanılır.
	#
	# Kirpiklinin trixosisti iki top xərcləyir və [method Sim.GermState.super_ready]
	# ən azı beş top tələb edir. Avtomatik oyunçu isə beşə çatan kimi atəş açırdı,
	# yəni mikrob daim 3-4 topda ilişirdi və super DÜYMƏSİ HEÇ VAXT YANMIRDI:
	# regresiya testində kirpiklinin superi 11 cəhdin heç birində ekrana
	# düşmədi, digər iki növünkü isə ilk cəhddə düşdü.
	var saving := me.charge >= Const.SUPER_MAX and not me.super_ready()
	var fire := not saving and me.balls > Const.FIRE_MIN_BALLS and _seq % 8 == 0

	# Super HAZIR olan kimi basılır.
	#
	# Əvvəl heç vaxt basılmırdı və nəticədə superlərin görüntüsü (trixosist,
	# tor, kist) avtomatik testlə HEÇ VAXT ekrana düşmürdü — onları yalnız
	# botlarda, təsadüfən tutmaq olurdu. İndi `--practice --shot` ilə hər növün
	# superi təkrarlana bilən şəkildə çəkilir.
	var use_super := me.super_ready()
	return Sim.PlayerInput.make(_seq, move, aim, fire, use_super)


func _nearest_food() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var best := {}
	var best_d := INF
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var p := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


func _nearest_enemy() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var best := {}
	var best_d := INF
	for e in _last_snap[Const.Snap.GERMS]:
		if int(e[Const.GF.ID]) == my_id:
			continue
		var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


# ================================================================ server sözü

func _on_snapshot(data: Array) -> void:
	if data.size() < 8:
		return
	# Mikroblar şəbəkədən SIX gəlir; burada bir dəfə sətirlərə açılır ki,
	# çəkiliş və proqnoz kodu format dəyişikliyindən xəbərsiz qalsın.
	data[Const.Snap.GERMS] = Const.unpack_germs(data[Const.Snap.GERMS])
	data[Const.Snap.SHOTS] = Const.unpack_shots(data[Const.Snap.SHOTS])
	data[Const.Snap.EVENTS] = Const.unpack_events(data[Const.Snap.EVENTS])
	_last_snap = data
	_snaps.append({"t": _clock, "d": data})
	while _snaps.size() > SNAP_BUFFER_MAX:
		_snaps.pop_front()

	for entry in data[Const.Snap.GERMS]:
		if int(entry[Const.GF.ID]) == my_id:
			_reconcile(entry, data[Const.Snap.SELF])
			break

	_apply_walls(data[Const.Snap.WALLS])
	_apply_match(data[Const.Snap.MATCH])
	_queue_events(data[Const.Snap.EVENTS], _clock)
	_hud.update_board(data[Const.Snap.BOARD], int(data[Const.Snap.POP]), _roster)
	# Minimap yaş radiusu da bilməlidir: TƏK QALAN-da təhlükəsiz zona 1200-dən
	# 90 px-ə düşür və oyunçunun "hara qaçım" sualına cavab verən yeganə yer
	# xəritədir. Onsuz minimap həmişə tam qabı göstərirdi.
	_hud.minimap.wet_radius = _wet_radius


## Ad və rəng cədvəli gəldi.
##
## Artıq çəkilmiş mikroblar da yenilənir: reyestr snapshot-dan SONRA gələ
## bilər və o halda mikrob bir neçə kadr adsız qalır. Yenilənmə olmasaydı,
## ad birdəfəlik boş qalardı — [method _ensure_germ] yalnız bir dəfə qurur.
func _on_roster(table: Dictionary) -> void:
	_roster = table
	for gid in table:
		var entry: Dictionary = _visuals.get(gid, {})
		if entry.is_empty():
			continue
		var info: Array = table[gid]
		entry["node"].set_identity(String(info[0]), int(info[1]))


## Serverin dediyi vəziyyəti qəbul edir, sonra hələ təsdiqlənməmiş
## girişləri yenidən oynadır — belə öz hərəkətin geri sıçramır.
## [param me_self] — [constant Const.Snap.SELF] sahəsi: təsdiqlənmiş giriş
## nömrəsi və atəş soyuması. Bunlar mikrob sətrindən çıxarılıb, çünki yalnız
## öz mikrobuna lazımdır və hər kadr hər rəqib üçün göndərilirdi.
func _reconcile(entry: Array, me_self: Array) -> void:
	me.pos = Vector2(float(entry[Const.GF.X]), float(entry[Const.GF.Y]))
	me.vel = Vector2(float(entry[Const.GF.VX]), float(entry[Const.GF.VY]))
	me.aim = float(entry[Const.GF.AIM])
	me.cooldown = float(me_self[Const.SelfF.CD])
	me.safe_t = 1.0 if int(entry[Const.GF.FLAGS]) & Const.GFlag.SAFE else 0.0

	# Doluluq və superin işlək olması serverin sözüdür.
	#
	# Superin QALAN VAXTI göndərilmir — yalnız "işləyir / işləmir" biti gedir.
	# Bir bitlə saniyədə 30 dəfə vaxt göndərməkdən qurtulmuş oluruq; sayğacı
	# proqnoz özü aparır (atəşin soyuması ilə eyni model).
	#
	# Amma sayğacı QURMAQ proqnoza tapşırıla bilməz. Səbəb məşq rejimindədir:
	# orada yerli dünya girişi [method _do_tick]-in İÇİNDƏ, proqnoz addımından
	# ƏVVƏL emal edir. Super işə düşür, doluluq serverdə sıfırlanır və elə həmin
	# kadrda bura gəlib proqnozun doluluğunu da sıfırlayır — nəticədə proqnoz
	# addımına çatanda [method Sim.GermState.super_ready] artıq "yox" deyir və
	# `super_t` HEÇ VAXT qalxmır. Ayaqlının toru və amöbin qabığı ÖZ mikrobunda
	# görünmürdü (botlarda görünürdü, çünki onlar snapshot bayrağından çəkilir).
	#
	# Ona görə bayrağın QALXMASI sayğacı özü qurur, düşməsi isə sıfırlayır.
	var flags := int(entry[Const.GF.FLAGS])
	me.charge = (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
	var super_on := (flags & Const.GFlag.SUPER) != 0
	if not super_on:
		me.super_t = 0.0
	elif not _super_on_srv:
		# Serverdə super İNDİ başladı. `maxf` onlayn oyun üçündür: orada proqnoz
		# superi özü işə salıb və onun sayğacı bayraqdan bir neçə tick QABAQDA
		# olur — geri çəkilməməlidir.
		me.super_t = maxf(me.super_t, Const.super_time(int(me.species)))
	else:
		# Server hələ "işləyir" deyir, proqnozun sayğacı isə bitib: quyruq
		# fərqidir. Bir neçə tick uzadılır ki, effekt bayraq sönənə qədər
		# davam etsin və itən paketdə yanıb-sönməsin.
		me.super_t = maxf(me.super_t, SUPER_TAIL)
	_super_on_srv = super_on

	var balls_before := me.balls
	var cap_before := me.capacity
	me.balls = int(entry[Const.GF.BALLS])
	me.capacity = int(entry[Const.GF.CAP])

	# Rəqib partladı → tutum artdı. Bu, oyunun yeganə mükafatıdır, eşidilməlidir.
	if me.capacity > cap_before:
		Sfx.play("level_up")
		_add_shake(6.0)

	# Kimsə sənə top vurdu: doluluq artdı, amma sən yemədin.
	if me.balls > balls_before + 1:
		_add_shake(4.0)

	if me.balls >= me.capacity - 1 or me.balls <= Const.MIN_BALLS:
		Sfx.play_danger()

	var acked := int(me_self[Const.SelfF.ACK])
	while not pending.is_empty() and pending[0].seq <= acked:
		pending.pop_front()

	# Hadisələr saxlanmır: eyni atəş səsi hər düzəlişdə təkrar çalınmamalıdır.
	for inp in pending:
		pred.step_movement({my_id: inp}, Const.TICK_DELTA, false)

	# Düzəliş tick-dən KƏNARDA da gələ bilər (onlayn rejimdə snapshot istənilən
	# anda düşür) və onda interpolyasiyanın ucları köhnə qalır.
	#
	# Amma hər düzəlişdə uçları bərabərləşdirmək OLMAZ: proqnoz düzgün işləyəndə
	# fərq bir neçə pikseldir, saniyədə 30 dəfə sıçrayış isə elə həmin titrəməni
	# geri gətirərdi. Ona görə yalnız proqnozun HƏQİQƏTƏN yanıldığı hal
	# sıçradılır — divara dəymək, geri təpmə, yenidən qoşulma. Kiçik fərq
	# növbəti tick-də onsuz da öz-özünə düzəlir.
	if me.pos.distance_to(_pos_curr) > Const.germ_radius(me.capacity):
		_sync_shown()


## Oyun sənin üçün bitdi — ya partladın, ya da matçı SAĞ bitirdin.
##
## Bir RPC-dir, çünki client üçün ikisi eyni şeydir: idarə dayanır, nəticə
## çıxır, menyuya qayıdılır. Fərqi serverin qoyduğu `won` bayrağı deyir.
func _on_you_burst(result: Dictionary) -> void:
	# Yer yalnız matçlı rejimdə var: sonsuz arenada sıralama anlayışı yoxdur.
	if _mode != Const.Mode.ENDLESS:
		result["place"] = _place
		result["total"] = Const.WORLD_CAPACITY
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_result(result)

	# SAĞ QALDIN — mikrobun partlamayıb.
	#
	# Şərt `won` DEYİL, `survived`-dır: vaxt limitində birinci olmayan oyunçu da
	# sağdır. Yalnız `won`-a baxanda ekranda "Vaxt bitdi — sağ qaldın" yazılır,
	# oyun isə eyni anda partlama effektini, ölüm səsini və silkələnməni
	# oynadırdı — mətn görüntünü təkzib edirdi.
	if bool(result.get("survived", false)):
		Sfx.play("level_up" if result.get("won", false) else "ui_click")
		_freeze = 0.0
		get_tree().create_timer(6.0).timeout.connect(_return_to_menu)
		return

	# Öz partlayışın daha böyük çəkilir — kamera onun üstündədir və oyun bitir.
	_explode(me.pos, Const.germ_radius(me.capacity), my_color, true)
	Sfx.play("you_burst")
	_add_shake(18.0)
	# Öz ölümün ən uzun donmanı alır: oyun bu anda BİTİR, oyunçu nə baş
	# verdiyini görməlidir.
	_freeze = FREEZE_TIME * 2.0
	_punch = 0.11
	get_tree().create_timer(4.0).timeout.connect(_return_to_menu)


## Bağlantı kəsildi. Nişanımız varsa oyunu tərk etmirik — server mikrobumuzu
## bir müddət saxlayır, biz isə arxa planda qayıtmağa çalışırıq.
func _on_server_lost() -> void:
	if _finished or _reconnecting or practice:
		return
	if _token.is_empty():
		_give_up("BAĞLANTI KƏSİLDİ")
		return
	_reconnecting = true
	_rejoin_left = REJOIN_ATTEMPTS
	_hud.release_sticks()
	_try_reconnect()


func _try_reconnect() -> void:
	if not _reconnecting:
		return                      # artıq qayıtmışıq
	if _rejoin_left <= 0:
		_reconnecting = false
		_give_up("BAĞLANTI BƏRPA OLUNMADI")
		return

	_rejoin_left -= 1
	_hud.show_message("BAĞLANTI BƏRPA OLUNUR",
		"Cəhd %d / %d" % [REJOIN_ATTEMPTS - _rejoin_left, REJOIN_ATTEMPTS])

	Net.disconnect_from_server()
	Net.join_server(Net.last_address, Net.last_port)

	# Növbəti cəhd nəticədən asılı olmayaraq planlaşdırılır. Uğur olsa
	# `_reconnecting` sönür və bu çağırış yuxarıdakı yoxlamada dayanır.
	# Bu, `connection_failed` siqnalını gözləməkdən daha etibarlıdır:
	# WebSocket-də uğursuz cəhd bəzən heç bir siqnal vermədən asılı qalır.
	get_tree().create_timer(REJOIN_INTERVAL).timeout.connect(_try_reconnect)


func _on_reconnected() -> void:
	if not _reconnecting:
		return
	Net.request_rejoin.rpc_id(1, _token)


## Server nişanı qəbul etdi — eyni mikrobla dünyaya qayıdırıq.
func _on_rejoin_accepted(info: Dictionary) -> void:
	if not _reconnecting:
		return
	_reconnecting = false

	my_id = int(info["you"])
	my_color = int(info.get("color", my_color))
	# Yenidən qoşulanda köhnə mikrobuna qayıdırsan — onun növü serverdəki
	# qeyddir, menyudakı seçim yox.
	Net.species = _species_from(info)
	_token = str(info.get("token", _token))

	# Proqnoz sıfırdan qurulur; ilk snapshot onu dərhal serverin sözünə çəkəcək.
	pending.clear()
	_snaps.clear()
	_init_prediction()
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.hide_message()


## Nişan artıq keçərli deyil: mikrob partlayıb və ya gözləmə vaxtı dolub.
func _on_rejoin_rejected() -> void:
	_reconnecting = false
	_give_up("MİKROBUNA QAYITMAQ MÜMKÜN OLMADI")


func _give_up(title: String) -> void:
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_message(title, "Menyuya qayıdılır...")
	get_tree().create_timer(2.5).timeout.connect(_return_to_menu)


func _return_to_menu() -> void:
	if not practice:
		# Serverə "çıxıram" deyirik: mikrob dərhal silinir, 20 saniyəlik
		# yenidən qoşulma möhləti boş yerə gözlənilmir.
		if Net.is_connected_to_server():
			Net.request_leave.rpc_id(1)
			# Paket bağlantı BAĞLANMAZDAN əvvəl yola salınır.
			#
			# `disconnect_from_server` dərhal çağırılsaydı, RPC hələ növbədə
			# olarkən peer bağlanardı və ENet "Unable to send packet on channel 0,
			# max channels: 0" yazardı — matçın sonunda bir neçə oyunçu eyni anda
			# çıxanda server logunda məhz bu görünürdü.
			Net.flush()
		Net.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


# ================================================================ render

func _render(delta: float) -> void:
	var render_time := _clock - Const.INTERP_DELAY
	_render_germs(render_time)
	_render_shots(render_time)
	_render_food(render_time)
	_flush_fx(render_time)
	_sweep_views()
	_update_camera(delta)
	_update_minimap()
	_apply_freeze()
	_watch_capacity()
	_watch_bush()


func _update_camera(delta: float) -> void:
	# Böyük mikrob daha geniş sahə görür: bu, həm ədalətlidir (böyük hədəfə
	# uzaqdan da dəyirlər), həm də böyüməni hiss etdirir.
	var want := Const.view_span(me.capacity)
	_view_span = lerpf(_view_span, want, clampf(delta * 2.0, 0.0, 1.0))

	var vp := get_viewport_rect().size
	# Miqyas SAHƏDƏN çıxarılır — nə endən, nə də qısa kənardan.
	#
	# Qısa kənardan çıxsaydı (əvvəl belə idi), geniş ekran daha çox dünya
	# görərdi: 21:9 telefon 16:9-dan 31%, 4:3-dən isə 75% çox sahə. Ekranın
	# forması oyun üstünlüyünə çevrilirdi.
	#
	# Sahə sabit olanda forma yalnız KADRIN FORMASINI dəyişir: geniş ekran
	# enli və alçaq görür, kvadrata yaxın ekran dar və hündür. Məlumatın
	# miqdarı hamıda eynidir (bax [constant Const.VIEW_ASPECT_REF]).
	var k := Const.camera_zoom_span(_view_span, vp)
	# Kamera zərbəsi. Sönmə SÜRƏTLİDİR: zərbə ani olmalıdır, uzansa
	# "nəfəs alan kamera" kimi oxunur və oyunçunu yorur.
	_punch = move_toward(_punch, 0.0, delta * 0.75)
	_cam.zoom = Vector2(k, k) * (1.0 + _punch)

	# ---- donmuş kadr ----
	# Kamera YERİNDƏ qalır — donmanın özü elə budur. Miqyas yuxarıda artıq
	# tətbiq olunub, yəni donma anında zərbə görünür; hərəkət isə dayanır.
	if _freeze > 0.0:
		_freeze = maxf(0.0, _freeze - delta)
		return

	var shake := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - 46.0 * delta)
		shake = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_cam.position = _shown_pos() + shake

	# Zərrəciklər kameranı izləyir: dünyanın hamısını doldurmaq əvəzinə
	# yalnız görünən sahədə saxlanılır (bax [WaterMotes]).
	#
	# Sahə UZUN kənarla ölçülür: zərrəcik sahəsi kvadratdır və ekranın geniş
	# tərəfini də örtməlidir — yoxsa yatayda sol və sağ kənarlar boş qalar.
	#
	# Görünən dünya ölçüsü birbaşa miqyasdan çıxır (`piksel / zoom`), çünki
	# artıq qısa kənar deyil, SAHƏ sabitdir.
	var mote_span := maxf(vp.x, vp.y) / maxf(k, 0.001)
	_motes.focus = _shown_pos()
	_motes.span = mote_span
	_motes_deep.focus = _shown_pos()
	_motes_deep.span = mote_span


func _add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, 20.0)


## Serverin dediyi divar vəziyyətini tətbiq edir.
##
## PROQNOZA da yazılır və bu, məcburidir: dağılmış qabıq client-in öz
## simulyasiyasında da yox olmalıdır, yoxsa proqnoz mikrobu artıq olmayan
## divarda saxlayar, server isə keçirər — hər tick-də düzəliş, yəni
## rezin kimi dartılma.
##
## Massiv hər snapshot ilə tam gəlir (maneə başına bir bayt), fərq kimi yox: fərq
## göndərilsəydi bir itən paket client-i əbədi səhv vəziyyətdə qoyardı.
## Matç vəziyyətini serverdən götürür.
##
## Qabın kənarı proqnoza da verilir: mikrobun quru zonaya girib-girmədiyini
## client özü hesablamır (top sayı serverin sözüdür), amma KƏNARI çəkmək və
## xəbərdarlıq göstərmək üçün radius lazımdır.
func _apply_match(row: Array) -> void:
	if row.size() < Const.MF.size():
		return
	_mode = Const.mode_from(int(row[Const.MF.MODE]))
	var was := _phase
	_phase = int(row[Const.MF.PHASE]) as Const.Phase
	_phase_t = float(row[Const.MF.CLOCK])
	_wet_radius = float(row[Const.MF.RADIUS])
	_alive = int(row[Const.MF.ALIVE])
	_place = int(row[Const.MF.PLACE])
	_my_team = int(row[Const.MF.TEAM])
	_score_us = int(row[Const.MF.SCORE_US])
	_score_em = int(row[Const.MF.SCORE_EM])
	pred.dish_radius = _wet_radius

	if was != _phase:
		_on_phase_changed()
	# Kənar hər kadr tərpənir, ona görə fon yenidən çəkilməlidir.
	if _mode != Const.Mode.ENDLESS:
		queue_redraw()


## Faza dəyişdi — mesaj və səs.
func _on_phase_changed() -> void:
	match _phase:
		Const.Phase.COUNTDOWN:
			# Mətn burada YAZILMIR — sayımın hər iki sətri [method Hud.set_match]
			# tərəfindən hər kadr yenilənir. Burada da yazsaq, iki sahib olar.
			pass
		Const.Phase.PLAYING:
			_hud.show_message("BAŞLADI", "Sona qalan udur")
			get_tree().create_timer(1.4).timeout.connect(_hud.hide_message)
			Sfx.play("level_up")
		_:
			pass


func _apply_walls(walls: PackedByteArray) -> void:
	if walls.size() != _blob_nodes.size():
		return
	var changed := false
	for i in walls.size():
		var spr := _blob_nodes[i]
		if spr == null:
			continue

		if DishMap.wall_gone(walls[i]):
			# YENİ dağılan divar — effekt yalnız BİR dəfə oynadılır.
			if i < _broken.size() and DishMap.wall_gone(_broken[i]):
				continue
			changed = true
			spr.visible = false
			continue

		# Hələ durur, amma zədə almış ola bilər. Qabığın şəkli zərbə sayına
		# görə dəyişir: BRITTLE_HP üçdür, yəni oyunçu neçə zərbə qaldığını
		# görməlidir — əvvəl sprite heç vaxt dəyişmirdi və qabıq son zərbəyə
		# qədər toxunulmamış görünürdü.
		#
		# Zədəli qabıq öz teksturasına keçdiyinə görə maneə batch-i qısa müddətə
		# bölünə bilər (düzümdə cəmi iki qabıq var, yəni ən pis halda +2
		# çağırış) — qabıq dağılan kimi geri qapanır.
		var hits := DishMap.wall_hits(walls[i])
		if hits > 0 and _blob_texture(DishMap.obstacles()[i]) == "crust":
			var want: Texture2D = _tex["crust3"] if hits >= 2 else _tex["crust2"]
			if spr.texture != want:
				spr.texture = want
	_broken = walls
	pred.broken = walls
	if changed:
		# Kölgələr statik `_draw`-dadır: dağılan divarın kölgəsi öz-özünə
		# getmir, çəkiliş yenidən istənilməlidir.
		queue_redraw()


## Donmanı mikrob görüntülərinə ötürür.
##
## Hər kadr ŞƏRTSİZ yazılır. Yalnız donma başlayanda qoyulsaydı, donma
## anında ekranda olmayan (sonra peyda olan) mikrob donmuş doğulardı və
## bir daha oyanmazdı.
func _apply_freeze() -> void:
	var on := _freeze > 0.0
	for gid in _visuals:
		(_visuals[gid]["node"] as GermVisual).frozen = on


## Tutum artımını tutur — oyunun YEGANƏ mükafatı, görünməlidir.
##
## Hadisə ilə gələ bilmir: partlama hadisəsində PARTLAYAN yazılır, partladan
## yox (bax [method Sim._burst]). Ona görə artım öz mikrobunun sahəsindən
## oxunur — bu, həm onlayn, həm məşq rejimində işləyir.
func _watch_capacity() -> void:
	# İlk kadr: başlanğıc tutumu mükafat kimi göstərmək olmaz.
	if _last_cap == 0:
		_last_cap = me.capacity
		return
	if me.capacity > _last_cap:
		_pop_text(_shown_pos(), "+%d TUTUM" % (me.capacity - _last_cap),
			Palette.SAFE, 30)
		_punch = maxf(_punch, 0.05)
	_last_cap = me.capacity


## Öz mikrobun kolun içindədirmi — və oyunçu bunu BİLİRMİ?
##
## Gizlənmə GÖRÜNMƏYƏN qaydadır: server sadəcə rəqiblərə paket göndərmir
## (bax [method World._near_germs]), oyunçunun ekranında isə heç nə dəyişmir.
## Geribildirim olmasa xüsusiyyət PRAKTİKİ OLARAQ YOXDUR — oyunçu ondan
## istifadə etməyi ağlına gətirmir.
##
## Sönükləşmə seçilib, ikona yox: mikrobun ÖZÜ dəyişir, yəni mesaj hara
## baxırsansa oradadır. HUD-dakı ikonu döyüş vaxtı heç kim görmür.
##
## Yazı yalnız BİR dəfə çıxır. Hər kola girəndə təkrarlansaydı, kolların
## arasından keçən oyunçu fasiləsiz mesaj yağışı altında qalardı.
func _watch_bush() -> void:
	var inside := pred.bush_of(me) >= 0
	if inside == _hidden:
		return
	_hidden = inside
	var v := _germ_by_color(my_color)
	if v != null:
		var tw := create_tween()
		tw.tween_property(v, "modulate:a", 0.45 if inside else 1.0, 0.22)
	if inside and not _bush_taught:
		_bush_taught = true
		_hud.show_message("GİZLƏNDİN", "Kolun içində rəqiblər səni görmür")
		get_tree().create_timer(2.2).timeout.connect(_hud.hide_message)


## Top rəqibin içinə keçdi — zərbənin görüntüsü.
##
## Hadisədə ATANIN rəngi yazılır (bax [method Sim._inject]), vuruLANın rəngi
## isə yazılmır — snapshot-da hər bayt sayılır. Ona görə qurban dəymə
## nöqtəsinə ƏN YAXIN mikrobdur: nöqtə onun öz səthidir, başqa mikrob isə
## o qədər yaxın dura bilmir (mikroblar bir-birindən radiusları qədər
## aralanır).
func _on_impact(at: Vector2, shooter_color: int) -> void:
	var victim: GermVisual = null
	var best := INF
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.color_index == shooter_color:
			continue
		var d := v.position.distance_to(at)
		if d < best:
			best = d
			victim = v
	# Ən böyük mikrobun radiusu ~96 pikseldir. Bundan uzaqdakı "ən yaxın"
	# mikrob qurban deyil: hadisə görüş sahəsindən kənarda baş verib və
	# vurulan hələ bizə göndərilmir.
	if victim == null or best > 220.0:
		return
	victim.flash()
	# Rəqəm dəymə nöqtəsində yox, QURBANIN ADINDAN yuxarıda doğulur.
	#
	# Dəymə nöqtəsi mikrobun üst kənarına düşəndə rəqəm tam adın sətrinə otururdu
	# və "Mik+2ob" kimi oxunurdu. Ad mikrobun mərkəzindən sabit məsafədədir,
	# ona görə etibarlı yer odur — dəymə isə gövdənin istənilən yerində olur.
	var above := victim.position - Vector2(0.0, Const.germ_radius(victim.capacity) + 74.0)
	_pop_text(Vector2(at.x, minf(at.y, above.y)), "+%d" % Const.SHOT_PAYLOAD,
		Palette.germ_color(victim.color_index), 26)


## Uçan rəqəm — hadisənin ÖZ YERİNDƏ yazılır.
##
## HUD-a qoyula bilməzdi: HUD ekranın kənarındadır, hadisə isə ortada baş
## verir və oyunçunun gözü orada olur. Rəqəmin bütün dəyəri elə yerində
## görünməsindədir.
##
## Etiket `_fx` qatındadır, yəni DÜNYA koordinatlarındadır və kamera ilə
## birlikdə sürüşür. Mərkəzləmə sabit enlə edilir: `Label`-ın öz ölçüsü
## yalnız növbəti kadrda bilinir, mərkəz isə İNDİ lazımdır.
func _pop_text(at: Vector2, text: String, color: Color, size: int) -> void:
	const BOX := 260.0
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(BOX, float(size) + 8.0)
	# Yuxarı sürüşmə: rəqəm dəymə nöqtəsində doğulsa mikrobun ADI ilə üst-üstə
	# düşür (ad mikrobun başının üstündədir) və ikisi də oxunmaz olur.
	label.position = at - Vector2(BOX * 0.5, float(size) + 20.0)
	label.z_index = 50
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	# Kontur şərtdir: rəqəm öz rəngindədir və eyni rəngli mikrobun üstünə
	# düşəndə onsuz oxunmur.
	label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	label.add_theme_constant_override("outline_size", 7)
	_fx.add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 52.0, 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Sönmə GECİKİR: rəqəm əvvəlcə tam oxunmalı, sonra getməlidir.
	tw.tween_property(label, "modulate:a", 0.0, 0.50).set_delay(0.35)
	tw.chain().tween_callback(label.queue_free)


func _update_minimap() -> void:
	var dots := []
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible:
			continue
		dots.append([v.position, Palette.germ_color(v.color_index), gid == my_id])
	_hud.minimap.broken = _broken
	_hud.minimap.set_dots(dots)


# ---------------------------------------------------------------- mikroblar

func _render_germs(render_time: float) -> void:
	# Öz mikrobun proqnozdan gəlir — şəbəkə gecikməsi olmadan, amma iki tick
	# arasında yumşaldılmış (bax [member _pos_prev]).
	var mine := _ensure_germ(my_id, Net.nickname, my_color, Net.species)
	mine.apply(_shown_pos(), _shown_aim(), me.balls, me.capacity, me.safe_t > 0.0, true,
		me.super_t > 0.0)
	_visuals[my_id]["seen"] = _clock

	var pair := _bracket(render_time)
	if pair.is_empty():
		return
	var older := _index_germs(pair["a"])
	var newer := _index_germs(pair["b"])
	var alpha: float = pair["alpha"]

	for gid in newer:
		if gid == my_id:
			continue
		var n: Array = newer[gid]
		var o: Array = older.get(gid, n)
		# Növ bayraq bitlərindən gəlir — ayrıca sahə göndərilmir (bax [enum Const.GFlag]).
		var kind := Const.species_from(
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)
			# Ad və rəng snapshot-da GƏLMİR — reyestrdən oxunur (bax [method Net.on_roster]).
		# Reyestr hələ çatmayıbsa, mikrob adsız və neytral rənglə çəkilir; növbəti
		# etibarlı paket onu düzəldir. Boş ad qısa müddət qalır, çünki reyestr
		# mikrob yaranan kimi göndərilir.
		var info: Array = _roster.get(gid, ["", 0])
		var v := _ensure_germ(gid, String(info[0]), int(info[1]), kind)
		# Komanda bayraqda `team + 1` kimi gəlir; 0 komandasız deməkdir.
		var tm := ((int(n[Const.GF.FLAGS]) & Const.GFlag.TEAM_MASK)
			>> Const.GFlag.TEAM_SHIFT) - 1
		v.is_ally = _my_team >= 0 and tm == _my_team and gid != my_id

		var pos := Vector2(float(o[Const.GF.X]), float(o[Const.GF.Y])).lerp(
			Vector2(float(n[Const.GF.X]), float(n[Const.GF.Y])), alpha)
		var aim := lerp_angle(float(o[Const.GF.AIM]), float(n[Const.GF.AIM]), alpha)
		v.apply(pos, aim, int(n[Const.GF.BALLS]), int(n[Const.GF.CAP]),
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SAFE) != 0, true,
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SUPER) != 0)
		_visuals[gid]["seen"] = _clock


func _ensure_germ(gid: int, germ_name: String, color: int,
		species: Const.Species) -> GermVisual:
	var entry: Dictionary = _visuals.get(gid, {})
	if not entry.is_empty():
		return entry["node"]
	var v := GermVisual.new()
	v.setup(color, germ_name, gid == my_id, species)
	# "Blunk" atəş anında yox, topun membranı YARDIĞI anda çalınır. Gecikmə
	# mikrobun ölçüsündən asılıdır, ona görə vaxtı görüntü node-u özü bilir.
	v.broke_through.connect(_on_broke_through)
	_entities.add_child(v)
	_visuals[gid] = {"node": v, "seen": _clock}
	return v


## Top gövdəni tərk etdi. Öz mikrobun tam səslə, başqaları sönük eşidilir —
## eyni qayda [method _flush_fx]-dəki `eject` üçün də keçərlidir.
func _on_broke_through(local: bool) -> void:
	Sfx.play("blunk", 0.05, 0.0 if local else -6.0)


## Rənginə görə mikrobun görüntüsünü tapır. Bir dünyada iki eyni rəngli mikrob
## olmur ([method World._free_color]), ona görə rəng kimlikdir — hadisələrdə
## ayrıca id sahəsi göndərilmir.
## Mikrobun gövdəsini atəş istiqamətində dartır — top içəridən zorlayaraq
## çıxır (bax [method GermVisual.eject]). "Blunk" səsi buradan YOX, gövdə
## pərdəni yaranda siqnalla gəlir.
func _eject_from(color_index: int, angle: float) -> void:
	var v := _germ_by_color(color_index)
	if v != null:
		v.eject(angle)


func _germ_by_color(color_index: int) -> GermVisual:
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.burst and v.color_index == color_index:
			return v
	return null


## Render vaxtını əhatə edən iki snapshot-u tapır.
func _bracket(render_time: float) -> Dictionary:
	if _snaps.is_empty():
		return {}
	for i in range(_snaps.size() - 1):
		var t0: float = _snaps[i]["t"]
		var t1: float = _snaps[i + 1]["t"]
		if t0 <= render_time and render_time <= t1:
			var span := maxf(t1 - t0, 0.0001)
			return {"a": _snaps[i]["d"], "b": _snaps[i + 1]["d"],
				"alpha": clampf((render_time - t0) / span, 0.0, 1.0)}
	# Buferdən kənardayıq (yenicə başladıq və ya paket axını kəsildi) —
	# ən təzə məlum vəziyyəti göstəririk.
	var last: Array = _snaps[-1]["d"]
	return {"a": last, "b": last, "alpha": 1.0}


static func _index_germs(snap: Array) -> Dictionary:
	var out := {}
	for e in snap[Const.Snap.GERMS]:
		out[int(e[Const.GF.ID])] = e
	return out


# ---------------------------------------------------------------- toplar

## Atılan toplar düz xətlə sabit sürətlə gedir, ona görə interpolyasiya
## əvəzinə sonuncu məlum nöqtədən hesablanır — nəticə tamamilə hamardır.
## Sıçrayanda server yeni istiqamət göndərir və hesablama sıfırlanır.
##
## ── Öz topun BAŞQA zaman xəttindədir ─────────────────────────────────────
## Bu faylın başındakı üç zaman xətti burada toqquşur. Rəqiblər 100 ms geridə
## çəkilir, ÖZ mikrobun isə proqnozdan — yəni İNDİ. Top da rəqiblərlə eyni
## gecikməyə salınsaydı (və salınırdı), öz atdığın top mikrobunun 100 ms
## əvvəlki yerində doğulardı: sürəti 420 px/s olduğuna görə bu, 42 piksel,
## yəni mikrobun radiusundan (28 px) BÖYÜK bir məsafədir. Şəbəkə gecikməsi
## də üstünə gəlir.
##
## Nəticə gözlə belə görünürdü: top mikrobun ARXASINDA peyda olur, gövdənin
## içindən keçir və qabaqdan çıxır — sanki kənardan atılıb. Halbuki oyunun
## qaydası budur ki, mikrob ÖZ İÇİNDƏKİ topu atır (bax README, "Oyunun
## qaydası"), və [method Sim._fire] onu düz mərkəzdə doğurur.
##
## Ona görə öz topun serverin sözünü GÖZLƏMİR: atəş açılan andakı doğuş
## nöqtəsindən uçur (bax [method _remember_muzzle]) — pinq nə olursa olsun
## mərkəzdən başlayır və membranı yararaq çıxır. Sıçrayan kimi serverin
## xəttinə qaytarılır: sıçrayışı proqnoz bilmir, onu yalnız server deyir.
##
## Qalan hər şey (rəqib topları, qida) gecikməli xəttdə qalır — onların
## sahibi də oradadır.
##
## Sahib RƏNGDƏN tanınır: bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color]), ona görə snapshot-a sahib sahəsi əlavə
## etməyə ehtiyac yoxdur — eyni üsul [method _explode]-da da işlənir.
func _render_shots(render_time: float) -> void:
	if _last_snap.is_empty():
		return
	for e in _last_snap[Const.Snap.SHOTS]:
		var sid := int(e[Const.SF.ID])
		var view: Dictionary = _shot_views.get(sid, {})
		if view.is_empty():
			var spr := _take(_shot_pool, _shot_layer)
			spr.texture = _tex["shot"]
			spr.modulate = Palette.germ_color(int(e[Const.SF.COLOR]))
			var mine := int(e[Const.SF.COLOR]) == my_color
			view = {"node": spr, "mine": mine}
			if mine:
				var muzzle := _claim_muzzle(
					Vector2(float(e[Const.SF.DX]), float(e[Const.SF.DY])))
				if not muzzle.is_empty():
					view["muzzle"] = muzzle
			_shot_views[sid] = view
		view["base"] = Vector2(float(e[Const.SF.X]), float(e[Const.SF.Y]))
		view["dir"] = Vector2(float(e[Const.SF.DX]), float(e[Const.SF.DY]))
		view["t"] = _clock
		view["seen"] = _clock

	for sid in _shot_views:
		var view: Dictionary = _shot_views[sid]
		var spr: Sprite2D = view["node"]
		var dir: Vector2 = view["dir"]

		var muzzle: Dictionary = view.get("muzzle", {})
		if not muzzle.is_empty():
			if Vector2(muzzle["dir"]).dot(dir) > 0.995:
				spr.position = Vector2(muzzle["pos"]) \
					+ dir * Const.SHOT_SPEED * (_clock - float(muzzle["t"]))
				continue
			# İstiqamət dəyişdi — top divardan sıçradı. Proqnozun sözü bitdi.
			view.erase("muzzle")

		var at: float = _clock if view.get("mine", false) else render_time
		spr.position = Vector2(view["base"]) + dir * Const.SHOT_SPEED * (at - float(view["t"]))

	# İzlər mövqelər oturandan SONRA yığılır. Yuxarıdakı dövrədə iki ayrı yol
	# var — öz topun proqnozdan, rəqibinki gecikməli xəttdən — və hər ikisi
	# eyni izə düşməlidir.
	for tid in _shot_views:
		var node: Sprite2D = _shot_views[tid]["node"]
		_trails.push(tid, node.position, node.modulate)
	_trails.queue_redraw()


## Öz atəşinin doğuş nöqtəsini yadda saxlayır — top serverdən gələnə qədər.
##
## [param membrane] atəş hadisəsindəki nöqtədir: membranın deşildiyi yer,
## yəni mərkəzdən düz bir radius aralıda. [method Sim._fire] həm onu, həm
## topun özünü eyni `g.pos`-dan qurur, ona görə mərkəzi geri hesablamaq olur.
func _remember_muzzle(membrane: Vector2, aim: float) -> void:
	_prune_muzzles()
	var dir := Vector2.from_angle(aim)
	_muzzles.append({
		"pos": membrane - dir * Const.germ_radius(me.capacity),
		"dir": dir,
		"t": _clock,
	})


## Serverin təsdiqləmədiyi köhnə doğuş nöqtələrini atır.
func _prune_muzzles() -> void:
	while not _muzzles.is_empty() and _clock - float(_muzzles[0]["t"]) > MUZZLE_GRACE:
		_muzzles.pop_front()


## Yeni gələn öz topunu gözləyən doğuş nöqtəsi ilə uyğunlaşdırır.
##
## Atəşlər növbə ilə açıldığına görə sıra kifayətdir; istiqamət isə yoxlama
## rolunu oynayır. Server atəşi qəbul etməyibsə (məsələn, düzəlişdən sonra
## soyuma fərqi) nöqtə [constant MUZZLE_GRACE] sonra özü düşür — belə olanda
## bir buraxılmış atəş bütün ardıcıllığı sürüşdürmür.
func _claim_muzzle(dir: Vector2) -> Dictionary:
	while not _muzzles.is_empty():
		var m: Dictionary = _muzzles.pop_front()
		if _clock - float(m["t"]) > MUZZLE_GRACE:
			continue
		if Vector2(m["dir"]).dot(dir) > 0.995:
			return m
	return {}


# ---------------------------------------------------------------- qida

## Qida demək olar hərəkətsizdir (yalnız partlayışdan səpiləndə sürüşür),
## ona görə interpolyasiya lazım deyil — mövqe yumşaq şəkildə çəkilir.
func _render_food(_render_time: float) -> void:
	if _last_snap.is_empty():
		return
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var fid := int(flat[i + Const.FF.ID])
		var target := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE

		var view: Dictionary = _food_views.get(fid, {})
		if view.is_empty():
			var spr := _take(_food_pool, _food_layer)
			spr.texture = _tex["food"]
			# Sprite-ın parlaq haşiyəsi var, ona görə görünən top gerçək
			# radiusdan bir az böyükdür — toqquşma ilə uyğunlaşdırılır.
			#
			# MƏNFİ id = SPOR (bax [Sim.FoodState]): iri yığın, tutum verir.
			# Bayraq id-nin işarəsindədir, ona görə axına bir ədəd də əlavə
			# olunmur.
			var k := FOOD_SCALE
			if fid < 0:
				k *= Const.SPORE_RADIUS / Const.FOOD_RADIUS
			spr.scale = Vector2(k, k)
			spr.position = target
			view = {"node": spr}
			_food_views[fid] = view
		var node: Sprite2D = view["node"]
		node.position = node.position.lerp(target, 0.4)
		view["seen"] = _clock


# ---------------------------------------------------------------- təmizlik

## Hovuzdan sprite götürür; hovuz boşdursa yenisini qurur.
func _take(pool: Array[Sprite2D], layer: Node) -> Sprite2D:
	if pool.is_empty():
		var fresh := Sprite2D.new()
		layer.add_child(fresh)
		return fresh
	var spr: Sprite2D = pool.pop_back()
	spr.visible = true
	spr.modulate = Color.WHITE
	spr.rotation = 0.0
	spr.scale = Vector2.ONE
	return spr


## Sprite-ı hovuza qaytarır — ağacda qalır, sadəcə gizlənir.
##
## Görünməyən node çəkilmir, yəni çəkiliş çağırışına düşmür; ağacdan
## çıxarıb geri qoymaq isə hovuzun qazancını yeyərdi.
func _give(pool: Array[Sprite2D], spr: Sprite2D) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	spr.visible = false
	pool.append(spr)


## Görüş sahəsindən çıxan obyektlərin görüntüsü silinir.
## Kiçik möhlət verilir, çünki render 100 ms geridədir.
func _sweep_views() -> void:
	var cutoff := _clock - VIEW_GRACE
	for dict in [_visuals, _food_views, _shot_views]:
		var dead := []
		for key in dict:
			if float(dict[key].get("seen", 0.0)) < cutoff:
				dead.append(key)
		for key in dead:
			var node: Node = dict[key]["node"]
			# Qida və toplar HOVUZA qayıdır, silinmir. Mikrobun görüntüsü isə
			# mürəkkəbdir (ad etiketi, növ, animasiya vəziyyəti) — onu təkrar
			# işlətmək qurmaqdan ucuz deyil, ona görə o silinir.
			if is_same(dict, _food_views):
				_give(_food_pool, node as Sprite2D)
			elif is_same(dict, _shot_views):
				_give(_shot_pool, node as Sprite2D)
			else:
				node.queue_free()
			dict.erase(key)
		# Ölən topun izi də getməlidir: yoxsa `_tracks` böyüyür və izin
		# qalığı ekranda donmuş qalır. `is_same` şərtdir — id-lər yalnız
		# ÖZ lüğəti daxilində unikaldır, mikrobun id-si topunku ilə üst-üstə
		# düşə bilər və onda canlı iz silinərdi.
		if is_same(dict, _shot_views):
			for key in dead:
				_trails.drop(key)


# ---------------------------------------------------------------- effektlər

func _queue_events(list: Array, at: float) -> void:
	for e in list:
		var kind := int(e[Const.EF.KIND])
		# Öz hadisələrimi artıq oynatmışam, ikinci dəfə göstərmirəm:
		#   • ATƏŞ    — proqnozda, gecikmə olmadan (bax [method _do_tick]);
		#   • PARTLAMA — serverin "sən partladın" mesajında (bax [method _on_you_burst]).
		# Partlama filtri xüsusilə vacibdir: keçsəydi, öz ölümün İKİ dəfə
		# çəkilər (biri böyük, biri normal ölçüdə) və `you_burst` ilə `burst`
		# səsləri üst-üstə düşərdi.
		if int(e[Const.EF.COLOR]) == my_color \
				and (kind == Const.EvKind.FIRE or kind == Const.EvKind.BURST):
			# Atəşi proqnoz HƏMİŞƏ oynatmır. Məşq rejimində yerli dünyanın
			# tick-i proqnozdan ƏVVƏL işləyir və soyuma sayğacını düzəldir,
			# ona görə proqnoz öz atəşini heç görmür — qığılcım da, səs də,
			# topun doğuş nöqtəsi də itir.
			#
			# Gözləyən doğuş nöqtəsi elə bu sualın cavabıdır: varsa, atəş
			# proqnozda oynadılıb; yoxdursa, yalnız server bilir və burada
			# oynadılmalıdır.
			_prune_muzzles()
			if kind == Const.EvKind.FIRE and _muzzles.is_empty():
				var at_pos := Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y]))
				_remember_muzzle(at_pos, float(e[Const.EF.ARG]))
				_spawn_fx("spark", at_pos, 0.5, Palette.germ_color(my_color))
				Sfx.play("eject", 0.06)
				_eject_from(my_color, float(e[Const.EF.ARG]))
			continue
		_fx_queue.append({
			"at": at,
			"kind": kind,
			"pos": Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y])),
			"arg": float(e[Const.EF.ARG]),
			# Xam indeks də saxlanılır: partlayışda mikrobun görüntüsünü
			# tapmaq üçün lazımdır (bax [method _explode]).
			"ci": int(e[Const.EF.COLOR]),
			"color": Palette.germ_color(int(e[Const.EF.COLOR])),
		})


func _flush_fx(render_time: float) -> void:
	var i := 0
	while i < _fx_queue.size():
		var e: Dictionary = _fx_queue[i]
		if float(e["at"]) > render_time:
			i += 1
			continue
		var pos: Vector2 = e["pos"]
		var col: Color = e["color"]
		match int(e["kind"]):
			Const.EvKind.FIRE:
				_spawn_fx("spark", pos, 0.4, col)
				Sfx.play("eject", 0.06, -6.0)
				_eject_from(int(e["ci"]), float(e["arg"]))
			Const.EvKind.SUPER:
				# Səs üçün ayrıca fayl yoxdur, ona görə mövcud səslər rolu ilə
				# seçilir: trixosist PARTLAYIŞDIR, tor və qabıq isə AÇILIŞDIR.
				#
				# arg sıfırdan böyükdürsə, bu, trixosistdir və rəqəm onun təsir
				# RADİUSUDUR (bax [method Sim._use_super]).
				var reach := float(e["arg"])
				if reach > 0.0:
					# Bulud partlayışın HƏQİQİ sahəsi qədər açılır: sprite 256 px
					# enindədir və tween onu 1.7 dəfə böyüdür, ona görə başlanğıc
					# miqyas elə seçilir ki, SONDA diametr sahəyə bərabər olsun.
					# Effekt sahədən böyük olsaydı, oyunçu radiusu həmişə səhv
					# öyrənərdi — ilk variantda məhz belə idi (ekranın yarısı).
					_spawn_fx("burst", pos, reach * 2.0 / 256.0 / 1.7, col)
					_spawn_fx("spark", pos, 0.7, Palette.TEXT)
					Sfx.play("burst", 0.0, -6.0)
				else:
					_spawn_fx("spark", pos, 0.9, col)
					Sfx.play("level_up", 0.0, -5.0)
				if int(e["ci"]) == my_color:
					_add_shake(4.0)
			Const.EvKind.SPORE:
				# Tutum artımı — partlatma ilə eyni mükafat, ona görə eyni səs.
				_spawn_fx("spark", pos, 0.9, Palette.FOCUS)
				if int(e["ci"]) == my_color:
					Sfx.play("level_up")
					_add_shake(4.0)
			Const.EvKind.ABSORB:
				_spawn_fx("spark", pos, 0.28, Palette.FOOD)
				# Yalnız ÖZ udmağın eşidilir: 10 mikrobun hamısının səsi
				# eşidilsəydi, arxa fon fasiləsiz xışıltı olardı.
				if col == Palette.germ_color(my_color):
					Sfx.play("absorb", 0.08)
			Const.EvKind.HIT:
				_spawn_fx("spark", pos, 0.55, col)
				Sfx.play("hit", 0.05)
				# `arg` iki HIT növünü ayırır (bax [method Sim._bounce] və
				# [method Sim._inject]): 0 = divardan sıçradı, 1 = rəqibin
				# içinə keçdi. Zərbə yalnız ikincisidir — sıçrayışda
				# parıldayacaq mikrob yoxdur.
				if float(e["arg"]) > 0.5:
					_on_impact(pos, int(e["ci"]))
			Const.EvKind.BREAK:
				# Divar dağıldı. Partlayış effekti TƏKRAR işlədilir: hadisə
				# eyni cinsdəndir (bir şey dağılıb ətrafa səpilir) və oyunçu
				# onu artıq tanıyır. Rəng maneənin öz rəngidir, mikrobunku yox.
				var fx := BurstFx.new()
				fx.position = pos
				fx.setup(Palette.MUCUS_EDGE, maxf(float(e["arg"]), 20.0), 6,
					false, _tex["burst"])
				_fx.add_child(fx)
				Sfx.play("burst", 0.05, -4.0)
				if pos.distance_to(me.pos) < 600.0:
					_add_shake(7.0)
			Const.EvKind.BURST:
				_explode(pos, maxf(float(e["arg"]), 12.0), int(e["ci"]), false)
				Sfx.play("burst", 0.05)
				if pos.distance_to(me.pos) < 500.0:
					_add_shake(10.0)
					# Öldürmə yaxında baş verdi — ekran bir anlıq DONUR.
					# Uzaqdakı partlama üçün donma qoyulmur: oyunçunun heç bir
					# əlaqəsi olmayan hadisə onun idarəsini kəsməməlidir.
					_freeze = FREEZE_TIME
					_punch = maxf(_punch, 0.07)
		_fx_queue.remove_at(i)


## Partlayan mikrobun görüntüsünü partlayışla ƏVƏZ edir.
##
## Mikrobun özünü DƏRHAL susdurmaq şərtdir: server onu artıq göndərmir, amma
## görüntüsü [constant VIEW_GRACE] müddətincə saxlanılır (bax [method _sweep_views]) —
## susdurmasaq partlayışın ortasında sağ-salamat mikrob dayanardı.
##
## Mikrob RƏNGƏ görə tapılır. Bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color] bunu təmin edir), ona görə rəng mikrobun
## kimliyidir və partlama hadisəsinə ayrıca id sahəsi əlavə etmək lazım deyil —
## snapshot-da hər bayt sayılır.
func _explode(pos: Vector2, radius: float, color_index: int, mine: bool) -> void:
	var balls := -1
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if v.burst or v.color_index != color_index:
			continue
		# Son bilinən top sayı səpilən damcıların sayını təyin edir: dolu
		# mikrob partlayanda ekran daha çox dağılır.
		balls = v.balls
		v.kill()
		break

	var fx := BurstFx.new()
	fx.position = pos
	fx.setup(Palette.germ_color(color_index), radius, balls, mine, _tex["burst"])
	_fx.add_child(fx)


func _spawn_fx(kind: String, pos: Vector2, scale: float, color: Color) -> void:
	var spr := Sprite2D.new()
	spr.texture = _tex[kind]
	spr.position = pos
	spr.scale = Vector2(scale, scale)
	spr.modulate = color
	_fx.add_child(spr)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "modulate:a", 0.0, FX_LIFETIME)
	tw.tween_property(spr, "scale", Vector2(scale * 1.7, scale * 1.7), FX_LIFETIME)
	tw.chain().tween_callback(spr.queue_free)


# ---------------------------------------------------------------- fon

## Petri qabı və maneələr. Statikdir — bir dəfə çəkilir və heç vaxt yenilənmir.
func _draw() -> void:
	var r := Const.WORLD_RADIUS

	# Qabın kənarından bayır — oyunçu sərhədi aydın görməlidir.
	draw_circle(Vector2.ZERO, r + 600.0, Palette.BG_OUTER)

	# DÖŞƏMƏ — düz rəng deyil, ÇÖKƏN səth.
	#
	# Qab əyri şüşədir: mərkəz bir az açıq, kənar isə qaranlığa doğru düşür.
	# Düz rənglə çəkiləndə qab disk kimi oxunurdu — dərinliyin ilk işarəsi elə
	# səthin özündə olmalıdır, üstündəki obyektlərdə yox.
	#
	# TEKSTURA ilə, konsentrik disklərlə YOX. Əvvəlcə 14  yazmışdım
	# və ölçmə göstərdi ki, hər biri ayrıca çəkiliş çağırışıdır: təkcə döşəmə
	# 14 çağırış yeyirdi. Qradiyent teksturada isə bir çağırışdır.
	draw_texture_rect(_tex["floor"], Rect2(-r, -r, r * 2.0, r * 2.0), false)

	# ŞƏBƏKƏ — məsafə hissi verir, amma kənara doğru SÖNÜR.
	#
	# Bərabər parlaq şəbəkə koordinat kağızı kimi oxunur və səthi yastılaşdırır.
	# Kənara doğru sönəndə isə əksinə: səth əyilmiş görünür.
	#
	# `draw_multiline_colors` hər seqmentə ayrıca rəng verir və yenə TƏK
	# çağırışdır (eyni üsul mikrobun ayaqlarında işlənir).
	var step := 200.0
	var lines := PackedVector2Array()
	var cols := PackedColorArray()
	var n := int(r / step)
	for i in range(-n, n + 1):
		var x := float(i) * step
		var h := sqrt(maxf(r * r - x * x, 0.0))
		var fade := 1.0 - pow(absf(x) / r, 1.6)
		var gc := Color(Palette.GRID, 0.50 * fade)
		lines.push_back(Vector2(x, -h)); lines.push_back(Vector2(x, h))
		cols.push_back(gc)
		lines.push_back(Vector2(-h, x)); lines.push_back(Vector2(h, x))
		cols.push_back(gc)
	draw_multiline_colors(lines, cols, 2.0)

	# Maneələrin kölgəsi burada ÇƏKİLMİR — sprite-a bişirilib.
	#
	# Əvvəl hər bərk maneə üçün iki  vardı. Ölçmə göstərdi ki,
	#  içindəki hər primitiv ayrıca çəkiliş çağırışıdır: 15 maneə × 2
	# = 30 çağırış, yalnız kölgə üçün. Teksturaya bişəndə pulsuzdur, üstəlik
	# kölgə radiusla birlikdə özü miqyaslanır və fırlanma dayandırıldığı üçün
	# istiqaməti də sabit qalır (bax [method _spawn_obstacles]).

	# SEDİMENT ZOLAQLARI — mərkəzdən nə qədər uzaqdasan.
	#
	# Əvvəl nazik tam halqa idi və döşəmənin ÜSTÜNƏ çəkilmiş UI elementi kimi
	# oxunurdu. İndi enli, çox sönük və yalnız çevrənin bir hissəsində görünən
	# zolaqdır: oriyentir qalır, "xəritə üzərində cizgi" hissi gedir.
	#
	# Qırıq olması həm də təbiidir — çöküntü halqa boyunca bərabər yığılmır.
	for i in 3:
		var rr := r * (0.35 + 0.22 * float(i))
		var a0 := float(i) * 2.1
		draw_arc(Vector2.ZERO, rr, a0, a0 + PI * 0.85, 48,
			Color(Palette.GRID, 0.30), 26.0, true)

	# Şüşə kənar. Maneələr burada YOX, sprite kimi çəkilir —
	# bax [method _spawn_obstacles].
	# QURUMA KƏNARI — yalnız matçlı rejimdə və yalnız qab daralanda.
	#
	# Quru zona DİVAR DEYİL: mikrob ora keçir, sadəcə orada dolur və partlayır
	# (bax [method Sim._step_germs]). Ona görə kənar bərk xətt kimi yox, NƏBZ
	# VURAN halqa kimi çəkilir — "təhlükə", "maneə" yox.
	#
	# Quru döşəmə də ayrıca çəkilmir: qabın öz teksturasının üstünə kəhrəba
	# örtük qoyulur, yəni əlavə tekstura yoxdur.
	if _mode != Const.Mode.ENDLESS and _wet_radius < r - 1.0:
		var dry := Color(Palette.WARNING, 0.055)
		draw_arc(Vector2.ZERO, (_wet_radius + r) * 0.5, 0.0, TAU, 96, dry,
			r - _wet_radius, true)
		var pulse := 0.5 + 0.5 * sin(_clock * 2.2)
		draw_arc(Vector2.ZERO, _wet_radius, 0.0, TAU, 96,
			Color(Palette.WARNING, 0.30 + 0.22 * pulse), 8.0, true)

	# ŞÜŞƏ DİVAR — dörd hissə, çünki tək xətt "xəritə sərhədi" kimi oxunurdu.
	#
	# Qab QAB kimi görünmək üçün üç şey deməlidir: maye şüşəyə dırmaşır
	# (menisk), materialın qalınlığı var, və işıq ona bir tərəfdən düşür.
	# Sonuncusu ən vacibdir: simmetrik halqa həmişə yastı qalır.
	draw_arc(Vector2.ZERO, r - 16.0, 0.0, TAU, 96, Color(Palette.DISH_EDGE, 0.22), 30.0, true)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, Palette.DISH_EDGE, 11.0, true)
	draw_arc(Vector2.ZERO, r - 5.0, PI * 0.95, PI * 1.75, 40, Color(Palette.TEXT, 0.16), 3.0, true)
	draw_arc(Vector2.ZERO, r + 4.0, PI * 1.95, PI * 2.75, 40, Color(Palette.OUTLINE, 0.45), 6.0, true)
