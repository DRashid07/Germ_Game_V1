class_name Sim
extends RefCounted
## Oyunun bütün məntiqi — səhnə node-ları olmadan, saf məlumat üzərində.
##
## Bu sinif EYNİ ilə üç yerdə işləyir:
##   1. Serverdə — həqiqət mənbəyi (authoritative)
##   2. Client-də — öz mikrobun üçün prediction
##   3. Client-də — server düzəlişi gələndə reconciliation (geri sar, yenidən oynat)
##
## Məhz buna görə Godot fizikası istifadə olunmur: fizika mühərriki geri sarılıb
## yenidən oynadıla bilmir, bu isə prediction-u qeyri-mümkün edir.
##
## ── Oyunun qaydası bir cümlədə ───────────────────────────────────────────
## Mikrobun içindəki top sayı həm sursat, həm candır:
##   • Atəş = öz içindən bir top atmaq (səndə −1, dəydiyi rəqibdə +2: top bölünür)
##   • Rəqibin sayı TUTUMU aşsa → partlayır, partladan tutum +5 alır
##   • Öz sayın MIN_BALLS-dan aşağı düşsə → acından partlayırsan
##   • Metabolizm vaxt keçdikcə top yandırır → yemək məcburidir


class GermState:
	var id: int
	var name := "Mikrob"
	var color := 0
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var aim := 0.0
	var balls := Const.START_BALLS
	var capacity := Const.START_CAPACITY
	var cooldown := 0.0
	var safe_t := 0.0           ## Doğuş toxunulmazlığı
	var drain_t := 0.0          ## Növbəti topun yanmasına qalan vaxt
	var pops := 0               ## Neçə rəqib partladıb
	var age := 0.0              ## Neçə saniyədir yaşayır
	var is_bot := false
	var alive := true           ## false = bu tick partladı, indi silinəcək
	## Superin doluluğu 0..[constant Const.SUPER_MAX]. Snapshot-da bayrağın
	## boş bitlərində gedir (bax [enum Const.GFlag]) — ayrıca sahə deyil.
	var charge := 0
	## Super İNDİ nə qədər davam edir. Kirpiklinin superi anidir (0 qalır),
	## ayaqlının toru və amöbin qabığı isə vaxt tutur.
	var super_t := 0.0
	## Doluluğa doğru yeyilmiş qida sayğacı — hər [constant Const.SUPER_FOOD_PER]
	## qidadan bir doluluq artır. Vəziyyətdədir ki, reconciliation zamanı
	## itməsin.
	var food_acc := 0
	## Quru zonada növbəti topun yığılmasına qalan vaxt (bax [method Sim._step_germs]).
	var dry_t := 0.0
	## Görüntü növü — oyunçunun menyuda seçdiyi (bax [enum Const.Species]).
	## Simulyasiyaya TƏSİR EDİR: sürətlənmə, sönmə, axına tabelik və maneə
	## radiusu növdən çıxır ([constant Const.SPECIES_THRUST]), üstəlik hər növün
	## öz superi var ([method _use_super]). Döyüş riyaziyyatı — atəş dövrü,
	## topun qiyməti, tutum artımı — üç növdə də EYNİDİR və bu, testlə saxlanılır.
	var species := Const.Species.CILIATE
	## Komanda nömrəsi, -1 = komandasız (SONSUZ ARENA, TƏK QALAN).
	##
	## Simulyasiyaya təsir edir: yoldaşa top dəymir və tor yoldaşı yavaşlatmır.
	## İTƏLƏMƏ isə komandaya baxmır — üst-üstə düşən iki yoldaş ekranda
	## oxunmaz bir ləkəyə çevrilərdi.
	var team := -1

	func radius() -> float:
		return Const.germ_radius(capacity)

	func speed() -> float:
		return Const.germ_speed(capacity) * Const.SPECIES_SPEED[int(species)]

	## Doluluq 0..1 — HUD-dakı zolaq və membranın gərginliyi bundan gəlir.
	func fill() -> float:
		return clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)

	func clone() -> GermState:
		var c := GermState.new()
		c.id = id; c.name = name; c.color = color
		c.pos = pos; c.vel = vel; c.aim = aim
		c.balls = balls; c.capacity = capacity
		c.cooldown = cooldown; c.safe_t = safe_t; c.drain_t = drain_t
		c.pops = pops; c.age = age; c.is_bot = is_bot; c.alive = alive
		c.species = species
		c.team = team
		c.charge = charge; c.super_t = super_t; c.food_acc = food_acc
		c.dry_t = dry_t
		return c


	## Superi işlətməyə hazırdırmı — doluluq DA, qiyməti də.
	##
	## Trixosist top xərcləyir, ona görə burada da DÖŞƏMƏ var — eynilə atəşdəki
	## [constant Const.FIRE_MIN_BALLS] kimi və eyni səbəbdən: qanuni bir hərəkət
	## oyunçunu öldürməməlidir. Döşəmə olmasaydı, üç toplu oyunçu yanan düyməni
	## basıb dərhal acından partlayardı — düymə ona xilas vəd edib öldürərdi.
	##
	## Qalan iki superin top qiyməti yoxdur (onların qiyməti vaxt və riskdir),
	## ona görə şərt praktikada yalnız kirpikliyə aiddir.
	##
	## Döşəmənin ÖZÜ [method Const.super_min_balls]-dadır: HUD həmin rəqəmi
	## oyunçuya yazmalıdır ([method Const.super_block_reason]) və iki yerdə
	## saxlanılsaydı, biri dəyişəndə düymə yenidən səbəbsiz susardı.
	func super_ready() -> bool:
		if charge < Const.SUPER_MAX or super_t > 0.0:
			return false
		return balls >= Const.super_min_balls(int(species))

	## Amöb qabığın içindədir: top səkir, metabolizm dayanır, tərpənmir.
	func in_cyst() -> bool:
		return species == Const.Species.AMOEBA and super_t > 0.0

	## Ayaqlının toru açıqdır: qida axır, yaxındakı rəqib yavaşıyır.
	func in_net() -> bool:
		return species == Const.Species.HELIOZOAN and super_t > 0.0


## Uçan top — atılmış, hələ heç kimə dəyməmiş mikrob topu.
class ShotState:
	var id: int
	var owner_id: int
	var color := 0
	var pos := Vector2.ZERO
	var dir := Vector2.RIGHT
	var life := 0.0
	var bounces := 0
	## Atıcının ekranı serverdən neçə tick GERİDƏ idi (bax [method _rewound]).
	## 0 = geri sarma yoxdur: bot, proqnoz və köhnə client.
	var rewind := 0.0


## Yerdəki sərbəst top (qida). Atılıb boşa gedən toplar da buna çevrilir —
## dünyada maddə itmir, sadəcə sahib dəyişir.
class FoodState:
	## Müsbət — adi qida, MƏNFİ — spor.
	##
	## Bayraq id-nin İŞARƏSİNDƏ daşınır, ayrıca sahədə yox. Qida axını
	## snapshot-un ən ağır hissəsidir və [constant Const.FOOD_STRIDE] üç ədəddir;
	## dördüncü sahə axını 33% ağırlaşdırardı. İşarə isə pulsuzdur.
	var id: int
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var lock_id := 0            ## Bu mikrob onu hələ uda bilməz
	var lock_t := 0.0


## Bir tick üçün oyunçu girişi.
class PlayerInput:
	var seq := 0
	var move := Vector2.ZERO
	var aim := 0.0
	var fire := false
	var use_super := false
	## Atəş anında oyunçunun EKRANINDA olan server tick-i (kəsrli).
	##
	## Rəqiblər client-də interpolyasiya ilə keçmişdə çəkilir, öz topun isə
	## indidə uçur. Server bu ədədlə topu atıcının GÖRDÜYÜ rəqiblərə qarşı
	## yoxlayır (bax [method Sim._rewound]). Mənfi = bilinmir, geri sarma yoxdur.
	var view_tick := -1.0
	## Atəşin ÖZ nişanı — atəş basılan paket növbədə yenisinə birləşəndə (bax
	## [method World.accept_input]). NAN = atəş bu paketin öz [member aim]-i ilə açılır.
	##
	## Şəbəkədə getmir: server iki paketi bir tick arasında alanda köhnəsini
	## atır, atəşi isə yenisinə köçürür. Əvvəl atəş YENİ paketin nişanı ilə
	## açılırdı, proqnoz isə köhnəsininki ilə — ölçülüb, RTT 120–180 ms-də atəşlərin
	## 19%-i birləşirdi, onların üçdə birində bucaq 1°-dən çox fərqlənirdi (ən
	## çoxu 147°). Proqnoz top bir xətlə uçurdu, serverinki başqa xətlə.
	var fire_aim := NAN
	## Client-in proqnozu atəşi MƏHZ bu paketdə açıb.
	##
	## [member fire] düymənin basılı olduğunu deyir və basılı saxlanan düymədə hər
	## paketdə durur; proqnoz isə atəşi soyuma bitən İLK paketdə açır. Server
	## soyumanı bir tick fərqli sayanda (girişlər birləşəndə, gecikəndə) atəşi
	## başqa paketdə — başqa nişan və görünən tick ilə — açırdı. Bu bayraqla
	## server proqnozun atəşini tanıyır ([method World.accept_input]) və soyuma
	## bir-iki tick gecikəndə onu itirmir ([constant World.FIRE_WAIT]).
	##
	## Köhnə client bu biti göndərmir — server onda əvvəlki qayda ilə işləyir.
	var shot := false
	## Server tərəfi: proqnozun atəşi neçə tick soyumanı gözləyib.
	var fire_wait := 0

	static func make(p_seq: int, p_move: Vector2, p_aim: float, p_fire: bool,
			p_super := false, p_view := -1.0) -> PlayerInput:
		var i := PlayerInput.new()
		i.seq = p_seq
		i.move = p_move.limit_length(1.0)
		i.aim = p_aim
		i.fire = p_fire
		i.use_super = p_super
		i.view_tick = p_view
		return i

	## İki bayraq BİR ədəddə gedir, ayrı-ayrı sahələrdə yox.
	##
	## Giriş paketi saniyədə 30 dəfə göndərilir və Variant massivində hər ədəd
	## 9 bayt tutur. Atəş onsuz da 0/1 idi — super onun yanındakı bitə girir və
	## massivin uzunluğu DƏYİŞMİR.
	##
	## Görünən tick YALNIZ atəşli paketə yazılır: server onu yalnız topu
	## doğanda oxuyur, qalan 29 paketdə isə boş yerə 9 bayt olardı.
	func to_array() -> Array:
		var out := [seq, move.x, move.y, aim,
			(1 if fire else 0) | (2 if use_super else 0) | (4 if shot else 0)]
		if fire and view_tick >= 0.0:
			out.append(view_tick)
		return out

	static func from_array(a: Array) -> PlayerInput:
		var bits := int(a[4])
		var view := float(a[5]) if a.size() > 5 else -1.0
		var i := PlayerInput.make(int(a[0]), Vector2(a[1], a[2]), float(a[3]),
			(bits & 1) != 0, (bits & 2) != 0, view)
		i.shot = (bits & 4) != 0 and i.fire
		return i


var tick := 0

## Qabın hazırkı işlək radiusu — YAŞ RADİUS.
##
## [World] hər tick-dən əvvəl [method Const.dish_radius] ilə doldurur.
## [Sim] onu özü hesablamır: rejim və matç saatı dünyanın işidir, simulyasiya
## isə yalnız "kənar buradadır" bilməlidir. Client-in proqnozu eyni dəyəri
## snapshot-dan alır (bax [enum Const.MF]).
##
## Bu radius DİVAR DEYİL — [method _confine] yenə [constant Const.WORLD_RADIUS]
## işlədir. Quru zona keçilə biləndir və oyunçu ora ÖZ SEÇİMİ ilə girir.
var dish_radius := Const.WORLD_RADIUS

var germs := {}                         ## id -> GermState
var shots: Array[ShotState] = []
var food: Array[FoodState] = []
var obstacles: Array[Vector4] = []

## Dağılmış maneələr — 1 = artıq yoxdur. İndeks [member obstacles] ilə eynidir.
##
## `PackedByteArray` seçilib, Dictionary yox: bu massiv hər tick-də hər mikrob
## və hər top üçün oxunur. Paketlənmiş massivdə yoxlama sadə indeksləmədir,
## Dictionary-də isə hash hesablanması — sıx yolda fərq ölçüləndir.
##
## Şəbəkəyə MƏHZ bu massiv gedir (bax [constant Const.Snap.WALLS]): mövqe və
## radius onsuz da hər iki tərəfdə var ([DishMap] paylaşılan koddadır), ona
## görə 22 baytla bütün dağıntı vəziyyəti köçürülür.
var broken := PackedByteArray()

## Kövrək qabıqların qalan canı. İndeks [member obstacles] ilə eynidir.
## Yalnız [constant DishMap.Kind.BRITTLE] üçün mənalıdır.
var brittle_hp := PackedByteArray()

## Yalnız təqdimat üçün (səs, partikullar). Simulyasiyaya təsir etmir,
## ona görə reconciliation zamanı təhlükəsiz şəkildə atılır.
var events: Array[Dictionary] = []

## Bu tick-də partlayan mikroblar: {"id", "killer", "pops", "cap", "age"}.
## Server bunu oxuyub oyunçuya nəticə ekranını göndərir və onu dünyadan çıxarır.
var burst_log: Array[Dictionary] = []

var rng := RandomNumberGenerator.new()

## Geri sarma (lag compensation) — YALNIZ [World] yandırır.
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Atıcının ekranında iki ayrı zaman var: öz topu İNDİ uçur (proqnoz), rəqib
## isə interpolyasiyaya görə keçmişdədir — `INTERP_DELAY + RTT` qədər. Server
## isə topu rəqibin İNDİKİ yerinə qarşı yoxlayırdı. Nəticə: ekranda top
## rəqibin düz ortasına girir, serverdə isə rəqib artıq 40-60 px aralıdadır
## və top ya boşa gedir, ya da dəymə bir anlıq gecikmə ilə başqa yerdə olur.
##
## Həll atıcının tərəfini tutur (favor the shooter): top rəqiblərin atıcının
## GÖRDÜYÜ mövqeyinə və halına (qalxan, kist) qarşı yoxlanılır. Geri sarma
## [constant Const.REWIND_MAX] ilə hədlənir — Overwatch və Battlefield 4-də
## 250 ms-dir; bizdə 30 Hz interpolyasiyası (100 ms) tək başına onun yarısıdır.
##
## Client-in proqnozu bunu yandırmır: orada rəqib yoxdur.
var lag_comp := false

## Son [constant HISTORY] tick-in mikrob mövqeləri: slot = tick % HISTORY.
## Hər slot `{id: Vector2}` — mikrob o tick-də yox idisə açar da yoxdur,
## yəni yeni doğulan mikrob keçmişdə "olduğu" yerdə vurula bilmir.
const HISTORY := 16
var _hist: Array[Dictionary] = []
## Eyni slotların hal bitləri: `{id: int}` (bax [method germ_bits]).
var _hist_bits: Array[Dictionary] = []
var _hist_tick := PackedInt64Array()

var _next_shot_id := 1
var _next_food_id := 1
var _food_budget := 0.0
var _spore_timer := 0.0
## Prediction rejimi: metabolizm və acından partlama işlədilmir
## (bax [method step_movement]).
var _no_metabolism := false


func _init() -> void:
	obstacles = DishMap.obstacles()
	_reset_walls()
	rng.randomize()


## Divar vəziyyətini başlanğıc halına qaytarır — bütün qabıqlar bütövdür.
func _reset_walls() -> void:
	broken.resize(obstacles.size())
	brittle_hp.resize(obstacles.size())
	for i in obstacles.size():
		broken[i] = 0
		brittle_hp[i] = DishMap.BRITTLE_HP if int(obstacles[i].w) == DishMap.Kind.BRITTLE else 0


# ---------------------------------------------------------------- mikroblar

func add_germ(id: int, germ_name: String, color: int, bot := false,
		species := Const.Species.CILIATE) -> GermState:
	var g := GermState.new()
	g.id = id
	g.name = germ_name
	g.color = color
	g.is_bot = bot
	g.species = species
	g.balls = Const.START_BALLS
	g.capacity = Const.START_CAPACITY
	g.safe_t = Const.SPAWN_SAFE_TIME
	g.drain_t = Const.drain_period(g.capacity)
	g.pos = find_spawn(g.radius())
	# Neytral halda mərkəzə baxır — doğulan kimi divara atəş açmasın.
	g.aim = (-g.pos).angle() if g.pos.length() > 1.0 else 0.0
	germs[id] = g
	return g


## Mikrobu dünyadan çıxarır. Onun UÇAN topları isə uçmağa davam edir — sahibsiz.
##
## Əvvəl toplar da silinirdi: bot partlayanda onun hələ uçan topu serverdə
## yox olurdu, client isə onu snapshot-dan düşənə qədər (RTT + interpolyasiya)
## uçurdurdu və top ekranda sənə DƏYİRDİ — ölçülüb, yalançı "sənə dəydi"-lərin
## bir hissəsi belə idi. Atılmış top sahibindən asılı olmamalıdır: dəyəndə
## sahibə super yükü və partlatma xalı sadəcə verilmir (sahib yoxdur).
func remove_germ(id: int) -> void:
	germs.erase(id)


## Mikrobun açarını dəyişir.
##
## Yenidən qoşulanda peer id dəyişir, amma mikrobun özü — mövqeyi, topları,
## hesabı — eyni qalmalıdır. Ona görə silib yenidən yaratmaq olmaz.
func rekey_germ(old_id: int, new_id: int) -> void:
	if old_id == new_id or not germs.has(old_id):
		return
	var g: GermState = germs[old_id]
	germs.erase(old_id)
	g.id = new_id
	germs[new_id] = g
	for s in shots:
		if s.owner_id == old_id:
			s.owner_id = new_id
	for f in food:
		if f.lock_id == old_id:
			f.lock_id = new_id


## Maneədən və başqa mikroblardan uzaq boş yer tapır.
## Tapılmasa (dünya çox sıxdırsa) ən son namizədi qaytarır — oyun dayanmamalıdır.
## Boş yer YAŞ radiusun içində axtarılır — quru zonada doğulan qida və mikrob
## oyunçunu ora çəkərdi, halbuki ora təhlükə sahəsidir.
func find_spawn(radius: float) -> Vector2:
	var pad := radius + 40.0
	var pos := Vector2.ZERO
	for _attempt in 40:
		var a := rng.randf() * TAU
		# sqrt — dairə üzrə BƏRABƏR paylanma (əks halda hamı mərkəzdə doğulur)
		var d := sqrt(rng.randf()) * maxf(dish_radius - pad, 40.0)
		pos = Vector2.from_angle(a) * d
		if not DishMap.is_free(pos, pad):
			continue
		var clear := true
		for gid in germs:
			var other: GermState = germs[gid]
			# Doğuş yeri rəqiblərdən UZAQ olmalıdır — 320 px atəş məsafəsinin üçdə biridir,
			# yəni yeni oyunçu heç olmasa yerini seçməyə vaxt tapır.
			if pos.distance_to(other.pos) < other.radius() + pad + 320.0:
				clear = false
				break
		if clear:
			return pos
	return pos


## Dünyanın liderləri — ən çox partlatmaya görə. Bərabərlikdə tutum həll edir.
func leaderboard(limit := 5) -> Array:
	var rows := []
	for id in germs:
		var g: GermState = germs[id]
		rows.append([g.id, g.name, g.pops, g.capacity])
	rows.sort_custom(func(a, b):
		if int(a[Const.LF.POPS]) != int(b[Const.LF.POPS]):
			return int(a[Const.LF.POPS]) > int(b[Const.LF.POPS])
		return int(a[Const.LF.CAP]) > int(b[Const.LF.CAP]))
	return rows.slice(0, limit)


# ---------------------------------------------------------------- addım

## Simulyasiyanı bir tick irəli aparır.
## [param inputs]: {germ_id: PlayerInput}
func step(inputs: Dictionary, dt: float) -> void:
	events.clear()
	burst_log.clear()
	tick += 1

	_step_germs(inputs, dt)
	_separate_germs()
	# Tarixçə TOPLARDAN ƏVVƏL yazılır: bu tick-in slotu snapshot-a gedən
	# mövqedir (mikroblar tick-in qalanında tərpənmir), client də onu görür.
	if lag_comp:
		_record_history()
	_step_shots(dt)
	_step_food(dt)
	_dry_food()
	_spawn_food(dt)
	_reap()


## Yalnız öz mikrobunun hərəkətini addımlayır — client-də prediction və
## reconciliation üçün.
##
## Toplar, qida və ölüm serverin sözüdür, ona görə burada emal olunmur.
## Ancaq atəşin özü işlənir: client belə öz cooldown-unu düzgün bilir və
## atəş effektini dərhal oynada bilir. Reconciliation zamanı
## ([param keep_events] = false) hadisələr atılır — əks halda həmin
## atəş səsi hər düzəlişdə təkrar çalınardı.
func step_movement(inputs: Dictionary, dt: float, keep_events := true) -> void:
	events.clear()
	tick += 1
	# Metabolizm və acından partlama serverin sözüdür. Client-də təkrar
	# hesablansaydı, proqnozdakı top sayı hər snapshot arasında yanıb-sönərdi.
	_no_metabolism = true
	_step_germs(inputs, dt)
	_no_metabolism = false
	# Proqnozda yaxın rəqiblərin kölgəsi də var (bax [method Arena._sync_proxies]):
	# server mikrobları hər tick bir-birindən AYIRIR, və proqnoz bunu bilməyəndə
	# sıxılan mikrob bir yerdə, serverdə başqa yerdə olurdu. Ölçülüb — nöqtə-nöqtə
	# döyüşdə atəşin başlanğıcı 12–24 px fərqlənirdi və top rəqibin kənarından
	# serverdə keçib gedirdi. Ayırma serverdəki funksiyanın ÖZÜDÜR.
	if germs.size() > 1:
		_separate_germs()
	shots.clear()
	if not keep_events:
		events.clear()


func _step_germs(inputs: Dictionary, dt: float) -> void:
	var starved: Array[GermState] = []

	# Tor yalnız AYAQLIDA olur, növ isə tick boyu dəyişmir. [method _net_slow]
	# hər mikrob üçün bütün dünyanı gəzməsin deyə ayaqlılar əvvəlcədən
	# seçilir (sıra `germs`-in sırasıdır). Tor açılıb-bağlanması tick-in
	# İÇİNDƏ baş verir, ona görə `in_net()` yenə canlı yoxlanılır.
	var helios: Array[GermState] = []
	for id in germs:
		var h: GermState = germs[id]
		if h.species == Const.Species.HELIOZOAN:
			helios.append(h)

	for id in germs:
		var g: GermState = germs[id]
		if not g.alive:
			continue

		var inp: PlayerInput = inputs.get(id)
		var wish := Vector2.ZERO
		if inp != null:
			wish = inp.move
			g.aim = inp.aim

		# ── Maye hərəkəti ────────────────────────────────────────────────
		# Mikrob suyu itələyərək gedir, ona görə sürət birbaşa təyin olunmur:
		# itələmə var → hədəf sürətə yaxınlaşır, itələmə yox → müqavimət söndürür.
		# Sönmə eksponensialdır, yəni addım ölçüsündən asılı deyil — 30 Hz server
		# ilə dəyişkən kadrlı client eyni nəticəni alır (prediction üçün şərtdir).
		#
		# Sürət SUYA NİSBƏTƏN saxlanılır: axın ayrıca əlavə olunur. Belə olanda
		# axına qarşı üzmək onu tam ləğv etmir — mikrob yenə də sürüklənir,
		# maye hissi məhz buradan gəlir.
		#
		# Əmsallar NÖVDƏN gəlir (bax [constant Const.SPECIES_THRUST]): kirpikli
		# tez qopub uzun sürüşür, amöb ağır qopur, ayaqlı isə suya az tabedir.
		var sp := int(g.species)
		g.super_t = maxf(0.0, g.super_t - dt)

		if g.in_cyst():
			# Qabıq bağlıdır: nə hərəkət, nə axın, nə metabolizm, nə atəş.
			# Sist YATMIŞ haldır — canlı öz həyatını müvəqqəti dayandırır.
			g.vel = Vector2.ZERO
			g.age += dt
			g.cooldown = maxf(0.0, g.cooldown - dt)
			g.safe_t = maxf(0.0, g.safe_t - dt)
			continue

		if wish.length_squared() > 0.0001:
			# Tora düşən rəqib yavaşıyır — şüalara yapışır.
			var target := wish * g.speed() * _net_slow(g, helios)
			g.vel = g.vel.lerp(target,
				1.0 - exp(-Const.FLUID_THRUST * Const.SPECIES_THRUST[sp] * dt))
		else:
			g.vel *= exp(-Const.FLUID_DRAG * Const.SPECIES_DRAG[sp] * dt)

		var flow := (Const.current_at(g.pos) + _vent_push(g.pos)) * Const.SPECIES_FLOW[sp]
		g.pos += (g.vel + flow) * dt
		_confine(g)

		g.age += dt
		g.cooldown = maxf(0.0, g.cooldown - dt)
		g.safe_t = maxf(0.0, g.safe_t - dt)

		# Metabolizm: vaxt keçdikcə bir top yanır.
		if not _no_metabolism:
			g.drain_t -= dt
			if g.drain_t <= 0.0:
				g.drain_t += Const.drain_period(g.capacity)
				g.balls -= 1

			# QURU ZONA — qab quruyub, mühit qatılaşıb: mikrob top QAZANIR.
			#
			# Top itirmir, çünki aclıqdan ölmək sönükdür və kənarı sadəcə "pis"
			# edir. Qazanmaq isə dilemma yaradır: kənar həm təhlükə, həm YEMDİR —
			# boşalmış oyunçu qəsdən ora çıxıb doldura bilər. Üstəlik dolu
			# oyunçunu mərkəzə sıxır, ac oyunçu isə orada nəfəs alır.
			#
			# Metabolizmlə EYNİ şərtin altındadır və bu, məcburidir: client
			# top sayını proqnozlaşdırmır, yoxsa HUD-dakı rəqəm hər snapshot
			# arasında yanıb-sönərdi.
			var depth := g.pos.length() - dish_radius
			if depth > 0.0:
				g.dry_t -= dt
				if g.dry_t <= 0.0:
					g.dry_t += Const.dry_period(depth)
					g.balls += 1
					if g.balls > g.capacity:
						_burst(g, 0)
						continue
			else:
				g.dry_t = 0.0

		# Super atəşdən ƏVVƏL yoxlanılır: eyni kadrda ikisi də basılsa,
		# oyunçunun niyyəti böyük olandır.
		if inp != null and inp.use_super and g.super_ready():
			_use_super(g)

		if inp != null and inp.fire and g.cooldown <= 0.0 and g.balls >= Const.FIRE_MIN_BALLS:
			_fire(g, inp.view_tick, inp.fire_aim)

		if g.balls < Const.MIN_BALLS and not _no_metabolism:
			starved.append(g)

	# Partlama dictionary-ni dəyişdiyi üçün gəzinti bitəndən sonra icra olunur.
	for g in starved:
		_burst(g, 0)


# ---------------------------------------------------------------- super

## Tora düşən mikrobun sürət əmsalı.
##
## Yalnız BAŞQASININ toru yavaşladır — öz torun səni saxlamır. Client-in
## proqnoz simulyasiyasında yalnız öz mikrobun var, ona görə rəqibin toru
## proqnozda görünmür və düzəlişlə gəlir. Bu, dəymə ilə eyni davranışdır:
## rəqibin sənə etdiyi hər şey serverin sözüdür.
##
## [param helios] — dünyadakı ayaqlılar, `germs` sırası ilə (bax
## [method _step_germs]). Başqa növün toru olmur, yəni nəticə eynidir.
func _net_slow(g: GermState, helios: Array[GermState]) -> float:
	for o in helios:
		if o.id == g.id or not o.alive or not o.in_net():
			continue
		# Tor YOLDAŞI yavaşlatmır — yoxsa ayaqlı öz komandasını tələyə salır və
		# super komanda rejimində cəzaya çevrilir.
		if o.team >= 0 and o.team == g.team:
			continue
		var reach := o.radius() * Const.NET_RADIUS
		if g.pos.distance_squared_to(o.pos) <= reach * reach:
			return Const.NET_SLOW
	return 1.0


## Super işə düşdü. Doluluq sıfırlanır və növün öz effekti başlayır.
##
## Üç super da rəqibin TOP SAYINA toxunmur: biri mövqe, biri qida, biri vaxt
## üzərində işləyir. Zərər verən super [constant Const.SHOT_PAYLOAD]
## riyaziyyatını yan yoldan pozardı (bax həmin sabitin izahı).
func _use_super(g: GermState) -> void:
	g.charge = 0
	# Hadisənin arg sahəsi trixosistin TƏSİR RADİUSUNU daşıyır (qalan iki
	# superdə sıfır). Səbəb: partlayışın görüntüsü həqiqi sahə ilə eyni
	# böyüklükdə olmalıdır — oyunçu radiusu yalnız effektdən öyrənir.
	#
	# Tor və qabıq isə DAVAM EDƏN vəziyyətdir və onları [GermVisual] özü
	# çəkir, ona görə hadisəyə yalnız səs və qığılcım qalır.
	var reach := 0.0
	if g.species == Const.Species.CILIATE:
		reach = g.radius() * Const.TRICHO_RADIUS
	events.append({
		"t": "super",
		"pos": g.pos,
		"arg": reach,
		"color": g.color,
	})
	# Davametmə [method Const.super_time]-dan gəlir: client eyni cədvəldən
	# oxuyur (bax [method Arena._reconcile]), yəni müddət BİR yerdə yazılır.
	match g.species:
		Const.Species.CILIATE:
			_super_trichocyst(g)
		_:
			g.super_t = Const.super_time(int(g.species))


## KİRPİKLİ — trixosist partlayışı.
##
## Paramesium yırtıcı toxunanda dərisindəki trixosistləri partladır və eyni
## anda kirpiklərini tərsinə döyüb geri üzür. Ölçülüb: bu qabiliyyəti olmayan
## mutantlar 9–45 dəfə tez yeyilir.
##
## Oyunda: yaxındakı RƏQİB topları dağılır — amma yox olmur, qida kimi yerə
## tökülür. Dünyada maddə itmir ([method _burst] da eyni qanunla işləyir), ona
## görə səni vuran öz topunu geri yeyə bilər. Qaçmaq pulsuz deyil.
func _super_trichocyst(g: GermState) -> void:
	var reach := g.radius() * Const.TRICHO_RADIUS
	var reach2 := reach * reach

	var survivors: Array[ShotState] = []
	for shot in shots:
		if shot.owner_id == g.id:
			survivors.append(shot)
			continue
		# İnsanın topu atıcının ekranında `rewind` qədər QABAQDADIR: atıcı bu
		# partlayışı o qədər GEC görür, qurban isə topu elə o qədər qabaqda görür
		# (bax [method Arena._remote_shot_pos]). Yoxlama həmin ana saxlanılır —
		# o zaman iki ekran da eyni şeyi deyir (bax [method _apply_blasts]).
		if shot.rewind > 0.0:
			_blasts.append([float(tick) + shot.rewind, shot.id, g.pos, reach2])
			survivors.append(shot)
			continue
		if shot.pos.distance_squared_to(g.pos) <= reach2:
			# Sahib SIFIR verilir: dağılan top artıq heç kimin deyil, hamı
			# eyni anda yeyə bilər.
			_drop_food(shot.pos, shot.dir * 60.0, 0)
			continue
		survivors.append(shot)
	shots = survivors

	# Yaxındakı mikroblar itələnir — mərkəzdə güclü, kənarda sıfır.
	for id in germs:
		var o: GermState = germs[id]
		if o.id == g.id or not o.alive or o.in_cyst():
			continue
		var delta := o.pos - g.pos
		var d := delta.length()
		if d > reach or d < 0.001:
			continue
		o.vel += (delta / d) * Const.TRICHO_PUSH * (1.0 - d / reach)

	# Kirpiklərin tərsinə döyüntüsü — özü geri sıçrayır.
	g.vel -= Vector2.from_angle(g.aim) * Const.TRICHO_DASH
	# Trixosist maddədir. Bu oyunda maddə = top = həm sursat, həm can.
	g.balls -= Const.TRICHO_COST


## Superin doluluğunu artırır. Həddi keçmir — dörd bitə sığmalıdır.
func _charge(g: GermState, amount: int) -> void:
	if g == null or not g.alive:
		return
	g.charge = clampi(g.charge + amount, 0, Const.SUPER_MAX)


## Mikrobu qabın içində və maneələrdən kənarda saxlayır.
func _confine(g: GermState) -> void:
	var r := g.radius()
	# Maneə üçün radius NÖVƏ görə kiçilir: amöbin sabit forması yoxdur, ona
	# görə başqasının sığmadığı aralıqdan sızır (bax [constant
	# Const.SPECIES_BODY]). Qabın şüşə kənarı isə hamı üçün eynidir — dünyanın
	# sərhədi forma məsələsi deyil.
	var rb := r * Const.SPECIES_BODY[int(g.species)]
	# Yalnız BLOKLAYAN və hələ DAĞILMAMIŞ maneələr saxlayır. Kol və cərəyan
	# deşiyi mikrobu buraxır (bax [method DishMap.blocks_germ]).
	#
	# Məsafə İLK yoxlanılır: mikrob adətən heç bir maneəyə toxunmur və iki
	# statik çağırış yalnız toxunan maneəyə qalır. Şərtlər yan təsirsizdir.
	for i in obstacles.size():
		var o := obstacles[i]
		var c := Vector2(o.x, o.y)
		var min_d := o.z + rb
		var delta := g.pos - c
		var d := delta.length()
		if not (d < min_d):
			continue
		if DishMap.wall_gone(broken[i]) or not DishMap.blocks_germ(int(o.w)):
			continue
		var n := (delta / d) if d > 0.001 else Vector2.RIGHT
		g.pos = c + n * min_d
		# Maneəyə dik gələn sürət söndürülür, yan sürət qalır — mikrob sürüşür.
		g.vel -= n * minf(g.vel.dot(n), 0.0)


	var limit := Const.WORLD_RADIUS - r
	if g.pos.length() > limit:
		var n := g.pos.normalized()
		g.pos = n * limit
		g.vel -= n * maxf(g.vel.dot(n), 0.0)

## Cərəyan deşiklərinin itələməsi. Verilmiş nöqtədə əlavə sürət qaytarır.
##
## İstiqamət MƏRKƏZƏ doğrudur və mövqedən çıxarılır — snapshot-a bir bayt da
## əlavə olunmur, `Vector4`-ün dördü də doludur. Bu, həm də oyun qaydasıdır:
## deşiklər xarici halqadadır ([method DishMap._build_rings]), yəni kənara
## sıxışdırılan oyunçuya mərkəzə qayıtmaq üçün bir yol verirlər.
##
## Güc kənara doğru SÖNÜR (kvadratik): deşiyin sərhədində sıfırdır. Kəskin
## keçid olsaydı, sərhəddə dayanan mikrob kadr-kadr içəri-bayıra atılıb
## titrəyərdi — proqnozla server arasında ən pis fərq növü budur.
##
## Axın kimi davranır, təkan kimi yox: [member GermState.vel]-ə toxunmur,
## yalnız mövqeyə əlavə olunur. Səbəb determinizmdir — sürətə yazsaydıq,
## client-in düzəlişi (bax [method Arena._reconcile]) itələməni İKİ dəfə
## saymış olardı.
func _vent_push(at: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for i in obstacles.size():
		# Növ əvvəl yoxlanılır: deşik azdır, statik çağırış yalnız onlara gedir.
		var o := obstacles[i]
		if int(o.w) != DishMap.Kind.VENT or DishMap.wall_gone(broken[i]):
			continue
		var c := Vector2(o.x, o.y)
		var d := at.distance_to(c)
		if d >= o.z:
			continue
		var u := 1.0 - d / o.z
		# Mərkəzə doğru. Deşiyin özü mərkəzdədirsə istiqamət yoxdur — belə
		# hal düzümdə olmamalıdır, amma sıfıra bölmə qadağandır.
		var dir := (-c).normalized() if c.length() > 0.001 else Vector2.ZERO
		push += dir * (Const.VENT_SPEED * u * u)
	return push


## Mikroblar bir-birinin içinə girmir — üst-üstə yığılma oyunu oxunmaz edir.
## İki tərəf bərabər itələnir, ona görə heç kim divara sıxışdırıla bilmir.
func _separate_germs() -> void:
	# Cüt döngüsüdür, ona görə radius hər mikrob üçün BİR dəfə hesablanır —
	# itələmə yalnız mövqeni dəyişir, tutumu yox.
	var list := germs.values()
	var radii := PackedFloat64Array()
	for g: GermState in list:
		radii.append(g.radius())
	for i in range(list.size()):
		var a: GermState = list[i]
		if not a.alive:
			continue
		for j in range(i + 1, list.size()):
			var b: GermState = list[j]
			if not b.alive:
				continue
			var delta := b.pos - a.pos
			var min_d := radii[i] + radii[j]
			var d := delta.length()
			if d >= min_d:
				continue
			var n := (delta / d) if d > 0.001 else Vector2.from_angle(float(a.id) * 0.37)
			var push := (min_d - d) * 0.5
			a.pos -= n * push
			b.pos += n * push


## [param view_tick] — atıcının ekranındakı tick ([member PlayerInput.view_tick]).
## [param aim] — atəşin öz nişanı ([member PlayerInput.fire_aim]); NAN = mikrobun nişanı.
func _fire(g: GermState, view_tick := -1.0, aim := NAN) -> void:
	var dir := Vector2.from_angle(g.aim if is_nan(aim) else aim)
	var s := ShotState.new()
	s.id = _next_shot_id
	_next_shot_id += 1
	s.owner_id = g.id
	s.color = g.color
	# Geri sarma atəş anında BİR dəfə ölçülür və uçuş boyu sabit qalır: top
	# client-də də o andan sabit sürətlə uçur, rəqiblər isə eyni gecikmə ilə
	# görünməyə davam edir. Client uydurma keçmiş göndərə bilər, ona görə
	# hədd var — ondan uzağa sarmaq olmur.
	if lag_comp and view_tick >= 0.0:
		s.rewind = clampf(float(tick) - view_tick, 0.0,
			Const.REWIND_MAX * float(Const.TICK_RATE))
	# Top mikrobun İÇİNDƏN doğulur və membranı yararaq çıxır.
	#
	# Əvvəl membranın kənarında, bir neçə piksel ARALIDA
	# doğulurdu — top mikrobun yanında birdən peyda olurdu, sanki kənardan
	# atılmışdı. Halbuki oyunun qaydası budur ki, mikrob öz içindəki topu atır
	# (bax README, "Oyunun qaydası"), ona görə top orada da başlamalıdır.
	#
	# Görüntü qatı bunu pulsuz düzgün çəkir: toplar mikroblardan ƏVVƏLKİ
	# qatdadır ([method Arena._build_world]), yəni gövdənin içindəki top
	# görünmür və membrandan keçəndə üzə çıxır.
	#
	# Toqquşmaya təsiri yoxdur: [method _step_shots] atıcının özünü onsuz da
	# keçir, başqa mikroblar isə bir-birinin içinə girə bilmir ([method _separate_germs]).
	s.pos = g.pos
	s.dir = dir
	s.life = Const.SHOT_LIFETIME
	shots.append(s)

	g.balls -= 1
	g.cooldown = Const.FIRE_COOLDOWN
	# Geri təpmə: atəş həm də manevr vasitəsidir.
	g.vel -= dir * Const.SHOT_RECOIL
	# Atəş açan toxunulmazlığını itirir — doğuş qorunması hücum qalxanı deyil.
	g.safe_t = 0.0

	# Qığılcım topun doğulduğu yerdə YOX, membranı yardığı yerdə çıxır —
	# mərkəzdə çəkilsə gövdənin altında qalıb heç görünməzdi.
	events.append({
		"t": "fire",
		"pos": g.pos + dir * g.radius(),
		"arg": dir.angle(),
		"color": g.color,
	})


func _step_shots(dt: float) -> void:
	if not _blasts.is_empty():
		_apply_blasts(dt)
	var survivors: Array[ShotState] = []

	for s in shots:
		s.life -= dt
		if s.life <= 0.0:
			_drop_food(s.pos, Vector2.ZERO, s.owner_id)
			continue

		var from := s.pos
		var to := s.pos + s.dir * Const.SHOT_SPEED * dt

		# Ən yaxın toqquşmanı tapırıq: maneə mikrobdan öndədirsə, top ona dəyir.
		var best := 2.0
		var victim: Sim.GermState = null
		## Qurbanın dəyilən andakı mövqeyi — geri sarılıbsa keçmişdəki.
		var victim_at := Vector2.ZERO
		var victim_shape := Vector3.ZERO
		var victim_cyst := false
		var hit_obstacle := Vector4.ZERO
		var hit_index := -1

		# Kol və cərəyan deşiyi topu BURAXIR (bax [method DishMap.blocks_shot]).
		# Kolun içindən atəş açmaq mümkündür — gizlənən oyunçunun yeganə
		# üstünlüyü elə budur.
		#
		# Kəsişmə İLK hesablanır: top adətən heç bir maneəyə dəymir və iki
		# statik çağırış yalnız dəyən maneəyə qalır. Şərtlər yan təsirsizdir.
		for i in obstacles.size():
			var o := obstacles[i]
			var t := _seg_circle_t(from, to, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS)
			if not (t >= 0.0 and t < best):
				continue
			if DishMap.wall_gone(broken[i]) or not DishMap.blocks_shot(int(o.w)):
				continue
			best = t
			victim = null
			hit_obstacle = o
			hit_index = i

		var owner: GermState = germs.get(s.owner_id)
		for id in germs:
			var g: GermState = germs[id]
			if not g.alive or g.id == s.owner_id:
				continue
			# DOST ATƏŞİ YOXDUR — top yoldaşın içindən keçir.
			#
			# Top rəqibə +2 verir, yəni yoldaşa dəyməsi ona KÖMƏK deyil, zərərdir:
			# onu partlama həddinə yaxınlaşdırır. Komandalı rejimdə bu, oyunçunu
			# yoldaşından qaçmağa məcbur edərdi.
			if owner != null and owner.team >= 0 and g.team == owner.team:
				continue
			# Doğuş qalxanı və kist də atıcının GÖRDÜYÜ andan oxunur, mövqe kimi.
			# İndikindən oxunanda top ekranda hələ qabıqsız amöbə girirdi, serverdə
			# isə yeni bağlanmış qabıqdan səkirdi — ölçülüb, boş dəymələrin bir
			# qismi belə idi.
			var bits := germ_bits(g) if s.rewind <= 0.0 else _rewound_bits(g, s.rewind)
			if bits & HIST_SAFE:
				continue
			var cyst := (bits & HIST_CYST) != 0
			var state := Vector4(g.pos.x, g.pos.y, g.vel.x, g.vel.y) if s.rewind <= 0.0 \
				else _rewound_state(g, s.rewind)
			var at := Vector2(state.x, state.y)
			# Ucuz ilk süzgəc: top-mikrob cütlərinin çoxu uzaqdadır, ellipsin
			# qurulması və kəsişməsi isə yalnız yaxındakına lazımdır.
			var near := hit_reach(g.capacity) + Const.SHOT_SPEED * dt
			if at.distance_squared_to(from) > near * near:
				continue
			var shape := hit_shape(int(g.species), g.capacity, Vector2(state.z, state.w))
			# Kistdən top SƏKİR, ona görə orada yalnız kənardan giriş sayılır.
			var t := seg_ellipse_t(from, to, at, shape) if cyst \
				else seg_ellipse_hit_t(from, to, at, shape)
			if t >= 0.0 and t < best:
				best = t
				victim = g
				victim_at = at
				victim_shape = shape
				victim_cyst = cyst
				hit_index = -1

		if best <= 1.0:
			var hit_pos := from.lerp(to, best)
			if victim != null:
				# Sistləşmiş amöb müvəqqəti QABIQDIR: top içəri girmir, səkir.
				# Səkən top başqasına dəyə bilər — səni vuran öz topunu geri
				# ala bilər.
				if victim_cyst:
					var cn := ellipse_normal(hit_pos, victim_at, victim_shape)
					if _bounce(s, hit_pos, cn):
						survivors.append(s)
					continue
				_inject(victim, hit_pos, s)
				continue
			if hit_index >= 0:
				# Kövrək qabıq topu UDUR, sıçratmır (bax [method _crack]).
				if int(hit_obstacle.w) == DishMap.Kind.BRITTLE:
					_crack(hit_index, hit_pos, s)
					continue
				var n := (hit_pos - Vector2(hit_obstacle.x, hit_obstacle.y)).normalized()
				if _bounce(s, hit_pos, n):
					survivors.append(s)
				continue

		s.pos = to

		# Qabın şüşə kənarı.
		var limit := Const.WORLD_RADIUS - Const.SHOT_RADIUS
		if s.pos.length() > limit:
			var n := -s.pos.normalized()
			s.pos = -n * limit
			if not _bounce(s, s.pos, n):
				continue

		survivors.append(s)

	shots = survivors


## Bu tick-in mikrob mövqelərini tarixçəyə yazır (bax [member lag_comp]).
##
## Hər tick bir kiçik lüğət: on mikrob üçün on açar. Slot dairəvi təkrar
## işlədilir, köhnə tick özü düşür.
func _record_history() -> void:
	if _hist.size() != HISTORY:
		_hist.resize(HISTORY)
		_hist_bits.resize(HISTORY)
		_hist_tick.resize(HISTORY)
		_hist_tick.fill(-1)
	var frame := {}
	var bits := {}
	for id in germs:
		var hg := germs[id] as GermState
		# Sürət də yazılır: toqquşma forması ondan asılıdır (bax [method hit_shape]).
		frame[id] = Vector4(hg.pos.x, hg.pos.y, hg.vel.x, hg.vel.y)
		# Qalxan və kist də — onlar da dəyməni həll edir (bax [method _step_shots]).
		# Çoxunda ikisi də yoxdur, ona görə yalnız olanlar yazılır.
		var b := germ_bits(hg)
		if b != 0:
			bits[id] = b
	var slot := tick % HISTORY
	_hist[slot] = frame
	_hist_bits[slot] = bits
	_hist_tick[slot] = tick


## Tarixçədə mikrobun dəyməni dəyişən halları (bax [method germ_bits]).
const HIST_SAFE := 1
const HIST_CYST := 2


## Mikrobun İNDİKİ halı: doğuş qalxanı və kist.
static func germ_bits(g: GermState) -> int:
	return (HIST_SAFE if g.safe_t > 0.0 else 0) | (HIST_CYST if g.in_cyst() else 0)


## Mikrobun [param back] tick əvvəlki halı — atıcının ekranındakı kimi.
##
## Client rəqibi iki snapshot arasında çəkir, bayraqları isə YENİ snapshot-dan
## götürür ([method Arena._render_germs]) — ona görə burada da yuxarı yuvarlanır.
## Keçmiş bilinmirsə indiki hal qaytarılır, mövqedəki kimi.
func _rewound_bits(g: GermState, back: float) -> int:
	var t := ceili(float(tick) - back)
	if t >= tick or t < 0 or _hist.size() != HISTORY:
		return germ_bits(g)
	var slot := t % HISTORY
	if _hist_tick[slot] != t or not _hist[slot].has(g.id):
		return germ_bits(g)
	return int(_hist_bits[slot].get(g.id, 0))


## Trixosistin geri sarılan toplara gecikən təsiri: `[an, top id, mərkəz, radius²]`.
##
## Kirpikli superini [code]tick[/code] anında açır, insanın topunu isə atıcı
## `rewind` qədər QABAQDA görür (bax [member ShotState.rewind]). Atıcının
## ekranında partlayış `rewind` gec görünür və o anda topu olduğu yerdə tutur;
## qurbanın ekranında isə top elə o qədər qabaqda çəkilir. İki ekranın ortaq
## anı budur — `tick + rewind`. Əvvəl top dərhal dağıdılırdı: atıcının ekranında
## top hələ uçub rəqibə DƏYİRDİ (zərbə, səs, +2), serverdə isə yox idi —
## ölçülüb, öz topunun təsdiqlənməyən dəymələrinin yarısından çoxu belə idi.
var _blasts: Array = []


## Vaxtı çatan trixosist partlayışlarını tətbiq edir (bax [member _blasts]).
##
## Tick-in əvvəlində top əvvəlki tick-in sonundadır; partlayışın anı onunla
## bu an arasındadır, ona görə top o qədər geri çəkilib yoxlanılır.
func _apply_blasts(dt: float) -> void:
	var now := float(tick)
	var keep := []
	for b in _blasts:
		if float(b[0]) > now:
			keep.append(b)
			continue
		for i in shots.size():
			var s := shots[i]
			if s.id != int(b[1]):
				continue
			var at := s.pos - s.dir * (Const.SHOT_SPEED * dt * (now - float(b[0])))
			if at.distance_squared_to(b[2]) <= float(b[3]):
				_drop_food(at, s.dir * 60.0, 0)
				shots.remove_at(i)
			break
	_blasts = keep


## Mikrobun [param back] tick əvvəlki mövqeyi — kəsrli, iki slot arasında xətti.
##
## Keçmiş bilinmirsə (mikrob yenicə doğulub, tarixçə hələ dolmayıb) İNDİKİ
## mövqe qaytarılır: geri sarma həmişə "ən pis halda köhnə qayda"ya enir.
## Mikrob o aralıqda [constant REWIND_JUMP]-dan çox yer dəyişibsə də indiki
## götürülür — bu sürüşmə deyil, teleportdur (raund başlanğıcı, dirilmə).
func _rewound(g: GermState, back: float) -> Vector2:
	var st := _rewound_state(g, back)
	return Vector2(st.x, st.y)


## Geri sarılmış mövqe VƏ sürət: `Vector4(x, y, vx, vy)`.
func _rewound_state(g: GermState, back: float) -> Vector4:
	var now := Vector4(g.pos.x, g.pos.y, g.vel.x, g.vel.y)
	var t := float(tick) - back
	var t0 := floori(t)
	var p0: Variant = _hist_at(t0, g.id)
	var p1: Variant = _hist_at(t0 + 1, g.id)
	if p0 == null or p1 == null:
		return now
	var st := (p0 as Vector4).lerp(p1 as Vector4, t - float(t0))
	if Vector2(st.x, st.y).distance_squared_to(g.pos) > REWIND_JUMP * REWIND_JUMP:
		return now
	return st


## Geri sarılmış mövqe indikindən bundan uzaqdırsa, keçmiş etibarsız sayılır.
##
## Ən sürətli qanuni yerdəyişmə cərəyan deşiyi ilə trixosist təkanıdır
## (~520 px/s); 300 ms-də bu, ~160 px edir. İki qatı ehtiyatla 320.
const REWIND_JUMP := 320.0


func _hist_at(t: int, id: int) -> Variant:
	if t < 0 or _hist.size() != HISTORY:
		return null
	var slot := t % HISTORY
	if _hist_tick[slot] != t:
		return null
	return _hist[slot].get(id)


## Topu səthdən sıçradır. Sıçrama haqqı bitibsə topu qidaya çevirir və
## [code]false[/code] qaytarır — çağıran onu siyahıdan çıxarmalıdır.
func _bounce(s: ShotState, at: Vector2, normal: Vector2) -> bool:
	s.bounces += 1
	if s.bounces > Const.SHOT_BOUNCES:
		_drop_food(at, Vector2.ZERO, s.owner_id)
		return false
	s.pos = at + normal * 0.5
	s.dir = s.dir.bounce(normal).normalized()
	events.append({"t": "hit", "pos": at, "arg": 0.0, "color": s.color})
	return true


## Kövrək qabığa zərbə. Canı bitəndə qabıq DAĞILIR və yol açılır.
##
## Top SIÇRAMIR — qabığı yarır və içində qalıb qidaya çevrilir. Sıçrasaydı,
## divar sındırmaq üçün atılan top geri qayıdıb atanın özünü vurardı: qapı
## açmaq özünə zərbə olmazdı. Qida isə maddənin itmədiyini saxlayır — oyunun
## bütün qalan hissəsində olduğu kimi.
##
## Dağılan qabıq BƏRPA OLUNMUR: dünya oyun getdikcə açılır və bu, qəsdəndir.
## Bərpa olunsaydı, sındırmağa sərf olunan üç top boşa gedərdi.
func _crack(i: int, at: Vector2, s: ShotState) -> void:
	# Qığılcım adi sıçrayış kimi yazılır (`arg` = 0): client burada mikrob
	# axtarmamalıdır, çünki vurulan mikrob yoxdur (bax [method Arena._on_impact]).
	events.append({"t": "hit", "pos": at, "arg": 0.0, "color": s.color})
	if brittle_hp[i] > 0:
		brittle_hp[i] -= 1
	# Zədə sayı BAYTA yazılır ki, client onu görsün və qabığın şəklini
	# dəyişsin (bax [enum DishMap.Wall]). Ayrıca sahə göndərilmir.
	var hits := DishMap.BRITTLE_HP - brittle_hp[i]
	broken[i] = (hits << DishMap.Wall.HITS_SHIFT) & DishMap.Wall.HITS_MASK
	if brittle_hp[i] == 0:
		broken[i] |= DishMap.Wall.GONE
		var o := obstacles[i]
		events.append({"t": "break", "pos": Vector2(o.x, o.y),
			"arg": o.z, "color": s.color})
	_drop_food(at, Vector2.ZERO, s.owner_id)


## Top rəqibin içinə keçdi və bölündü. Tutumu aşdısa rəqib partlayır —
## oyunun əsas qaydası. Niyə bir yox, [constant Const.SHOT_PAYLOAD] top:
## atəş dövrü ilə boşalma sürəti eyni olduğuna görə hücumun xalis üstünlüyü
## olmalıdır, əks halda dolu rəqib sadəcə atəş açaraq sonsuza qədər sağ qalır.
func _inject(victim: GermState, at: Vector2, s: ShotState) -> void:
	victim.balls += Const.SHOT_PAYLOAD
	# `arg` qurbanı da daşıyır (bax [method Const.hit_victim]): client zərbəni
	# ən yaxın mikroba TƏXMİN etmir, "sənə dəydi" proqnozu isə dəqiq təsdiqlənir.
	events.append({"t": "hit", "pos": at, "arg": Const.hit_arg(victim.color), "color": s.color})
	# Super hücum edəni mükafatlandırır — Brawl Stars-dakı məntiq. Dəyən
	# tərəf də bir az alır: üç superdən ikisi qaçış vasitəsidir və məhz
	# sıxılan oyunçuya lazım olur.
	_charge(germs.get(s.owner_id), Const.SUPER_ON_HIT)
	_charge(victim, Const.SUPER_ON_TAKEN)
	if victim.balls > victim.capacity:
		_burst(victim, s.owner_id)


## Mikrob partladı. İçindəki toplar qida kimi ətrafa səpilir —
## dünyada maddə itmir, partlatmanın mükafatı elə həmin topların özüdür.
func _burst(g: GermState, killer_id: int) -> void:
	if not g.alive:
		return
	g.alive = false
	events.append({"t": "burst", "pos": g.pos, "arg": g.radius(), "color": g.color})

	var scatter := clampi(g.balls, 3, 24)
	for i in scatter:
		var a := TAU * float(i) / float(scatter) + rng.randf() * 0.6
		var dir := Vector2.from_angle(a)
		_drop_food(g.pos + dir * (g.radius() * 0.4), dir * rng.randf_range(90.0, 240.0), 0)

	var killer: GermState = germs.get(killer_id)
	if killer != null and killer.id != g.id and killer.alive:
		killer.pops += 1
		killer.capacity = mini(killer.capacity + Const.CAPACITY_STEP, Const.MAX_CAPACITY)
		# Partlatma onsuz da +5 tutum verir; superin də açılması həmin anı
		# oyunun ən böyük anına çevirir.
		killer.charge = Const.SUPER_MAX

	# Ad, rəng, növ və komanda da yazılır: CÜT-də ölüm müvəqqətidir və mikrob
	# eyni kimliklə qayıdır (bax [method World._step_revive]). Bunlar yalnız
	# serverdə qalır — şəbəkəyə getmir.
	burst_log.append({
		"id": g.id,
		"killer": killer_id,
		"killer_name": killer.name if killer != null else "",
		"pops": g.pops,
		"cap": g.capacity,
		"age": g.age,
		"name": g.name,
		"color": g.color,
		"species": int(g.species),
		"team": g.team,
	})


func _reap() -> void:
	for entry in burst_log:
		remove_germ(int(entry["id"]))


# ---------------------------------------------------------------- qida

func _drop_food(at: Vector2, vel: Vector2, lock_id: int) -> void:
	var f := FoodState.new()
	f.id = _next_food_id
	_next_food_id += 1
	f.pos = at
	f.vel = vel
	f.lock_id = lock_id
	f.lock_t = Const.FOOD_ARM_TIME if lock_id != 0 else 0.0
	food.append(f)


func _step_food(dt: float) -> void:
	var damp := 1.0 / (1.0 + Const.FOOD_FRICTION * dt)
	var survivors: Array[FoodState] = []

	# Mikrobların siyahısı qida döngüsündən ƏVVƏL bir dəfə yığılır.
	#
	# Bu döngü tick-in ən ağır yeridir (qida × mikrob): hər cüt üçün Dictionary
	# axtarışı, `in_net()`, `radius()` və `pow` çağırılırdı. Mövqe, `alive` və
	# `in_net()` bu funksiyanın içində DƏYİŞMİR. Dəyişən iki şeydir — top sayı
	# (canlı oxunur) və spordan sonra tutum, yəni radius (həmin mikrobun həddi
	# yenidən hesablanır). Sıra `germs`-in sırasıdır, yəni nəticə eynidir.
	var nets: Array[GermState] = []
	var eaters: Array[GermState] = []
	var eat_pos := PackedVector2Array()
	var reach_food := PackedFloat64Array()
	var reach_spore := PackedFloat64Array()
	for id in germs:
		var g: GermState = germs[id]
		if not g.alive:
			continue
		if g.in_net():
			nets.append(g)
		eaters.append(g)
		eat_pos.append(g.pos)
		reach_food.append(pow(g.radius() + Const.FOOD_RADIUS, 2.0))
		reach_spore.append(pow(g.radius() + Const.SPORE_RADIUS, 2.0))
	var n_eaters := eaters.size()
	var limit := Const.WORLD_RADIUS - Const.FOOD_RADIUS

	for f in food:
		# Qidanın çoxu kilidsiz və SAKİTDİR (öz sürəti yoxdur) — onlar üçün boş
		# iş görülmür: sıfır kilid `maxf`-dən yenə sıfır çıxırdı, sıfır sürət də
		# dəyişmirdi.
		if f.lock_t > 0.0:
			f.lock_t = maxf(0.0, f.lock_t - dt)

		# Sürət və mövqe bir dəfə oxunur, sonda yazılır — əməliyyatlar və
		# onların sırası eynidir, sadəcə sahəyə hər dəfə müraciət olunmur.
		var v := f.vel
		var at := f.pos

		# Sərbəst top suda asılıdır: öz sürəti sönür, amma su onu heç vaxt
		# buraxmır — sakit qida da axınla birlikdə sürüşür. Ekranda 50-dən çox
		# qida topu var və hamısının eyni burulğanda süzülməsi "bu, mayedir"
		# mesajını hər şeydən yaxşı verir.
		if v != Vector2.ZERO:
			if v.length_squared() > 1.0:
				v *= damp
			else:
				v = Vector2.ZERO

		var flow := Const.current_at(at)
		if v != Vector2.ZERO or flow != Vector2.ZERO:
			at += (v + flow) * dt
			if at.length() > limit:
				var n := at.normalized()
				at = n * limit
				v = v.bounce(-n) * 0.5
		f.vel = v

		# Aksopodiya toru: açıq torun zolağındakı qida ona doğru axır.
		#
		# Kinetosistlər — şüaların üzərindəki qranullar — yem toxunan kimi
		# partlayıb onu şüaya yapışdırır. Heliozoa məhz belə yeyir: qovmadan,
		# gözləyərək.
		for h in nets:
			var pull_r := h.radius() * Const.NET_RADIUS
			var to_h := h.pos - at
			var pd := to_h.length()
			if pd > pull_r or pd < 0.001:
				continue
			at += (to_h / pd) * Const.NET_PULL * dt
			break
		f.pos = at

		var eaten := false
		var spore := f.id < 0
		for i in n_eaters:
			# Spor iri olduğuna görə udma məsafəsi də böyükdür — gözlə görünən
			# ölçü ilə oyun qaydası uyğun olmalıdır.
			#
			# Məsafə İLK yoxlanılır: qidanın çoxu hər mikrobdan uzaqdadır, qalan
			# şərtlər isə yan təsirsizdir — sıraları nəticəni dəyişmir.
			if at.distance_squared_to(eat_pos[i]) > (reach_spore[i] if spore else reach_food[i]):
				continue
			var g := eaters[i]
			if g.balls >= g.capacity:
				continue
			if f.lock_id == g.id and f.lock_t > 0.0:
				continue
			g.balls += 1
			if spore:
				# SPOR — tutum artır. Partlatma ilə EYNİ mükafat, başqa yolla.
				g.capacity = mini(g.capacity + Const.SPORE_CAPACITY, Const.MAX_CAPACITY)
				# Radius tutumdan gəlir — bu mikrobun udma həddi də yenilənir.
				reach_food[i] = pow(g.radius() + Const.FOOD_RADIUS, 2.0)
				reach_spore[i] = pow(g.radius() + Const.SPORE_RADIUS, 2.0)
				events.append({"t": "spore", "pos": f.pos, "arg": 0.0, "color": g.color})
			# Dinc oyunçu da super doldurur, sadəcə yavaş — kimsə tapmadan da
			# irəliləyiş var.
			g.food_acc += 1
			if g.food_acc >= Const.SUPER_FOOD_PER:
				g.food_acc = 0
				_charge(g, 1)
			events.append({"t": "absorb", "pos": f.pos, "arg": 0.0, "color": g.color})
			eaten = true
			break

		if not eaten:
			survivors.append(f)

	food = survivors


## Spor — iri qida yığını, yeyənə TUTUM verir.
##
## Brawl Stars-ın güc kubunun qarşılığı. Bizdə artan şey tutumdur — onsuz da
## partlatmanın mükafatı odur, yəni iki yol bir mükafata aparır və oyunçu
## döyüşməyi seçə də bilər, yığmağı da.
##
## Yaş radiusun İÇİNDƏ, mərkəzdən aralı doğulur: quru zonada doğulan spor
## oyunçunu ölümə çəkərdi, mərkəzdəki isə heç bir seçim tələb etməzdi.
func _drop_spore() -> void:
	var a := rng.randf() * TAU
	var d := dish_radius * rng.randf_range(0.40, 0.85)
	var f := FoodState.new()
	f.id = -_next_food_id
	_next_food_id += 1
	f.pos = Vector2.from_angle(a) * d
	food.append(f)


## Sporların sayını saxlayır (yalnız [constant Const.Mode.SOLO]-da işlədilir).
func keep_spores(dt: float) -> void:
	var have := 0
	for f in food:
		if f.id < 0:
			have += 1
	if have >= Const.SPORE_COUNT:
		_spore_timer = Const.SPORE_RESPAWN
		return
	_spore_timer -= dt
	if _spore_timer > 0.0:
		return
	_spore_timer = Const.SPORE_RESPAWN
	_drop_spore()


## Quru zonada qalan qida QURUYUR.
##
## Qab daralanda qida onunla daralmır: doğuş hədəfi sabitdir, üstəlik hər
## partlayan mikrob öz toplarını qida kimi yerə tökür. Ölçülüb — matçın
## sonunda 90 px-lik qabda 293 qida yığılmışdı (hədəf 110-dur). Nəticədə son
## iki mikrob heç vaxt acmırdı, heç vaxt hücum etmirdi və matç BEŞ dəfədən
## BEŞİNDƏ döyüşlə yox, vaxt limiti ilə bitirdi.
##
## Quru zonanın mənası da elə budur: orada TOP var, QİDA yoxdur.
func _dry_food() -> void:
	if dish_radius >= Const.WORLD_RADIUS:
		return
	# Sondan gedirik ki, silmək qalan indeksləri sürüşdürməsin.
	var i := food.size() - 1
	while i >= 0:
		if food[i].pos.length() > dish_radius:
			food.remove_at(i)
		i -= 1


## Hədəf qida sayı — qabın ölçüsünə görə.
##
## Sabit say olsaydı, qab daralanda sıxlıq partlayardı. Sahə ilə (r²) deyil,
## RADİUSLA (r) miqyaslanır: sahə ilə olsa, 250 px-lik qabda cəmi 5 qida
## qalardı və matçın sonu döyüş yox, aclıq yarışına çevrilərdi.
func _food_target() -> int:
	var k := dish_radius / Const.WORLD_RADIUS
	return maxi(int(round(float(Const.FOOD_TARGET) * k)), Const.FOOD_MIN)


func _spawn_food(dt: float) -> void:
	var target := _food_target()
	if food.size() >= target:
		_food_budget = 0.0
		return
	_food_budget += Const.FOOD_SPAWN_RATE * dt
	while _food_budget >= 1.0 and food.size() < target:
		_food_budget -= 1.0
		_drop_food(find_spawn(Const.FOOD_RADIUS), Vector2.ZERO, 0)


# ---------------------------------------------------------------- həndəsə

## İki nöqtə arasında maneəsiz atəş xətti varmı?
## Bot hədəf seçərkən istifadə olunur.
##
## Kəsişmə növdən və dağılmadan ƏVVƏL yoxlanılır — xətt adətən maneələrin
## çoxuna toxunmur. Hər üç şərt yan təsirsizdir, cavab eynidir.
func has_line_of_sight(a: Vector2, b: Vector2) -> bool:
	for i in obstacles.size():
		var o := obstacles[i]
		if not (_seg_circle_t(a, b, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS) >= 0.0):
			continue
		if DishMap.wall_gone(broken[i]) or not DishMap.blocks_sight(int(o.w)):
			continue
		return false
	return true


## Mikrob hansı kolun içindədir? Kolun indeksi, yoxdursa -1.
##
## ── Gizlənmə qaydası ────────────────────────────────────────────────────
## Kolun içindəki mikrobu YALNIZ eyni kolun içindəki görür. "Yaxınlıq"
## ölçüsü işlədilmir: sərhəddə duran iki oyunçu üçün nəticə kadr-kadr
## dəyişər və mikrob yanıb-sönərdi. Kol indeksi isə kəskin cavabdır.
##
## Mərkəz əsas götürülür, örtüşmə yox — oyunçu "içindəyəmmi" sualına baxıb
## cavab verə bilməlidir, örtüşmə isə gözlə ölçülmür.
##
## BÖYÜK mikrob kiçik kola sığmır (`o.z < g.radius()`). Bu, oyunun öz
## qaydasının davamıdır: böyümənin qiyməti var — iri hədəf, yavaş hərəkət,
## tez acma, və indi bir də GİZLƏNƏ BİLMƏMƏK. Lider kolda oturub oyunu
## dondura bilməz.
func bush_of(g: GermState) -> int:
	# Hər tick hər mikrob üçün çağırılır (bax [method World._build_frame]).
	# Növ İLK yoxlanılır — maneələrin çoxu kol deyil və statik çağırışa
	# ehtiyac qalmır. Şərtlər yan təsirsizdir, tapılan ilk kol eynidir.
	var r := g.radius()
	for i in obstacles.size():
		var o := obstacles[i]
		if int(o.w) != DishMap.Kind.BUSH or o.z < r:
			continue
		if DishMap.wall_gone(broken[i]):
			continue
		if g.pos.distance_squared_to(Vector2(o.x, o.y)) <= o.z * o.z:
			return i
	return -1


## ── Toqquşma forması ───────────────────────────────────────────────────
##
## Mikrob hərəkətdə DAİRƏ deyil: gövdə sürət oxu boyu uzanır, yanlardan daralır
## (amöb tam sürətdə orta hesabla 1.25 r önə, 1.40 r arxaya uzanır, yanları
## 0.75 r-ə enir). Toqquşma dairə qalanda top ekranda amöbün burnundan KEÇİRDİ,
## yandan isə gövdəyə çatmamış "havada" dəyirdi.
##
## Forma ellipsdir: gövdənin yarım-oxları sürət boyu `r·(1 + k₁·s)`, yana
## `r·(1 − k₂·s)`, burada `s` sürətin tavan sürətə nisbətidir. Əmsallar görünən
## gövdəyə uyğunlaşdırılıb ([GermVisual] siluetinin kadrları, s = 0…1, tutum
## 10…60). Görünən gövdə bu ellipsdən BAYIRA ÇIXMIR — [method GermVisual._fit_hit]
## onu içəridə saxlayır, yəni mərkəzi gövdədən keçən top həmişə dəyir.
##
## ── Balans: orta en dairəninkidir ───────────────────────────────────────
## Topun dəymə ehtimalı formanın topun yoluna DİK enindən asılıdır, top isə hər
## tərəfdən gəlir — ölçü ORTA endir: qabarıq fiqurun perimetri / π. Dayanan
## mikrobda (dairə) o, `2·(r + SHOT_RADIUS)`-dir. Ellipsə sadəcə topun radiusu
## əlavə olunanda orta en böyüyürdü (amöbdə +8%, kirpiklidə +3%) və hərəkətdəki
## mikrob asan vurulurdu. Ölçülüb — 300 bot dünyası × 60 s: bütün-amöb dünyasında
## dəymələr 75.4 → 79.6, ölüm +21%, super 4.37 → 3.98 (dairə → köhnə ellips).
##
## İndi topun "payı" ([method _even_margin]) elə seçilir ki, orta en dəqiq
## dairəninki olsun: forma dəyişir, dəymə ehtimalı dəyişmir. Növlər arasında da
## fərq yoxdur — [constant Const.SPECIES_BODY] kimi qaydadır: hədəf kimi hamı
## eyni ölçüdədir.
##
## Server də, client-in proqnozu da EYNİ düsturu işlədir; sürət snapshot-da gəlir.
const HIT_STRETCH: Array[float] = [0.20, 0.04, 0.24]
const HIT_SQUEEZE: Array[float] = [0.14, 0.05, 0.28]


## Toqquşma ellipsi: `Vector3(sürət boyu yarım-ox, yana yarım-ox, bucaq)`.
## Topun payı İKİ oxa da əlavə olunub.
static func hit_shape(species: int, capacity: int, vel: Vector2) -> Vector3:
	var r := Const.germ_radius(capacity)
	var sp := clampi(species, 0, HIT_STRETCH.size() - 1)
	var s := clampf(vel.length() / maxf(Const.germ_speed(capacity), 1.0), 0.0, 1.0)
	var angle := vel.angle() if vel.length_squared() > 1.0 else 0.0
	var a := r * (1.0 + HIT_STRETCH[sp] * s)
	var b := r * (1.0 - HIT_SQUEEZE[sp] * s)
	var m := _even_margin(a, b, r + Const.SHOT_RADIUS)
	return Vector3(a + m, b + m, angle)


## Toqquşma ellipsinin mərkəzdən ən uzaq nöqtəsi heç vaxt bundan uzaqda deyil —
## ucuz ilk süzgəc üçün (bax [method _step_shots]). `SimTest` hər növ, tutum və
## sürətdə yoxlayır.
static func hit_reach(capacity: int) -> float:
	return Const.germ_radius(capacity) * 1.3 + Const.SHOT_RADIUS + 2.0


## Ellipsin perimetri (Ramanujan) — bu ölçülərdə xətası 0.01%-dən azdır.
static func ellipse_perimeter(a: float, b: float) -> float:
	return PI * (3.0 * (a + b) - sqrt((3.0 * a + b) * (a + 3.0 * b)))


## Hər iki yarım-oxa əlavə olunan pay: `(a + m, b + m)` ellipsinin perimetri
## radiusu [param circle] olan dairəninkinə bərabərdir. Dairədə `m` topun
## radiusudur; uzanan gövdədə bir az kiçik, daralanda bir az böyük.
##
## Perimetr `m`-ə görə demək olar xəttidir (təpəsində `2π`), ona görə bir
## düzəliş addımı bəs edir: qalan xəta 0.001%-dən azdır.
static func _even_margin(a: float, b: float, circle: float) -> float:
	var m := circle - ellipse_perimeter(a, b) / TAU
	return m + circle - ellipse_perimeter(a + m, b + m) / TAU


## [param dir] istiqamətli, [param at]-dan keçən düz xəttin ellipsdən nə qədər
## DƏRİN keçdiyi: 0 = mərkəzdən, 1 = sərhədə toxunur, > 1 = kənardan.
##
## Proqnozun bir neçə piksellik xətası sərhəddə nəticəni dəyişir, dərində yox —
## client dəymənin nə qədər "əmin" olduğunu bununla ölçür.
static func line_depth(at: Vector2, dir: Vector2, center: Vector2, shape: Vector3) -> float:
	var k := Vector2(1.0 / shape.x, 1.0 / shape.y)
	var a := (at - dir * 4000.0 - center).rotated(-shape.z) * k
	var b := (at + dir * 4000.0 - center).rotated(-shape.z) * k
	return Geometry2D.get_closest_point_to_segment(Vector2.ZERO, a, b).length()


## Parça-ellips kəsişməsi — ellips vahid dairəyə çevrilir, kəsişmə anı
## xətti çevirmədə dəyişmir. [0,1] və ya -1 ([method _seg_circle_t] kimi).
static func seg_ellipse_t(a: Vector2, b: Vector2, center: Vector2, shape: Vector3) -> float:
	var la := (a - center).rotated(-shape.z)
	var lb := (b - center).rotated(-shape.z)
	return _seg_circle_t(Vector2(la.x / shape.x, la.y / shape.y),
		Vector2(lb.x / shape.x, lb.y / shape.y), Vector2.ZERO, 1.0)


## Top mikroba DƏYİRMİ: sərhəddən girir və ya tick-i elə onun İÇİNDƏ başlayır.
##
## [method seg_ellipse_t] yalnız sərhədin kəsildiyi anı tapır — parça bütünlüklə
## ellipsin içindədirsə "yox" deyir. Tick-də mikroblar toplardan ƏVVƏL yeriyir
## (bax [method step]): topa doğru gedən mikrob onun üstünə çıxırdı, topun 14 px-lik
## parçası gövdənin içində qalırdı və dəymə sayılmırdı. Növbəti tick-də dönən
## mikrobun ellipsi də dönür, top artıq çöldə olur — çıxışda da tutulmurdu.
## Ölçülüb: botun sənə "dəydi" proqnozlarının yalançı çıxanlarının çoxu budur —
## serverin öz snapshot-unda top gövdənin 8–29 px içindən keçib uçmağa davam edirdi.
static func seg_ellipse_hit_t(a: Vector2, b: Vector2, center: Vector2, shape: Vector3) -> float:
	var la := (a - center).rotated(-shape.z)
	if (la.x * la.x) / (shape.x * shape.x) + (la.y * la.y) / (shape.y * shape.y) <= 1.0:
		return 0.0
	return seg_ellipse_t(a, b, center, shape)


## Ellipsin [param at] nöqtəsindəki xarici normalı — qabıqdan sıçrayış üçün.
static func ellipse_normal(at: Vector2, center: Vector2, shape: Vector3) -> Vector2:
	var l := (at - center).rotated(-shape.z)
	var n := Vector2(l.x / (shape.x * shape.x), l.y / (shape.y * shape.y))
	if n.length_squared() < 0.000001:
		return (at - center).normalized()
	return n.normalized().rotated(shape.z)


## Parça-dairə kəsişməsi. Kəsişmə anını [0,1] qaytarır, yoxdursa -1.
static func _seg_circle_t(a: Vector2, b: Vector2, c: Vector2, radius: float) -> float:
	var d := b - a
	var f := a - c
	var aa := d.dot(d)
	if aa < 0.000001:
		return 0.0 if f.length_squared() <= radius * radius else -1.0
	var bb := 2.0 * f.dot(d)
	var cc := f.dot(f) - radius * radius
	var disc := bb * bb - 4.0 * aa * cc
	if disc < 0.0:
		return -1.0
	disc = sqrt(disc)
	var t1 := (-bb - disc) / (2.0 * aa)
	if t1 >= 0.0 and t1 <= 1.0:
		return t1
	var t2 := (-bb + disc) / (2.0 * aa)
	if t2 >= 0.0 and t2 <= 1.0:
		return t2
	return -1.0
