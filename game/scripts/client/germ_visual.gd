class_name GermVisual
extends Node2D
## Ekranda bir mikrob. İKİ NÖV var — hər ikisi eyni gövdəni bölüşür,
## fərq yalnız HƏRƏKƏT ORQANINDADIR.
##
## Burada heç bir oyun məntiqi yoxdur — yalnız verilən vəziyyəti çəkir.
## Bütün qərarlar serverdə, bütün proqnoz [Sim]-dədir. Növ oyuna TƏSİR ETMİR:
## iki mikrob eyni sürətlə gedir, eyni radiusa malikdir. Fərq yalnız gözdədir.
##
## ── Niyə sprite deyil ────────────────────────────────────────────────────
## Mikrobun ölçüsü TUTUMDAN, içindəki topların sayı isə MÖVCUD SAYDAN asılıdır.
## İkisi də oyun boyu dəyişir (tutum 10 → 60, top 0 → 60), ona görə hazır şəkil
## uyğun deyil. Növlər də hazır kadr ardıcıllığı ilə çəkilə bilməzdi: ayaqların
## addımı mikrobun HƏQİQİ sürətindən özü çıxır (bax [method _walk]).
##
## ── İki növ ──────────────────────────────────────────────────────────────
##
## **CILIATE — kirpikli** (paramesium modeli). Bədəni yumşaq kisədir, suda
## ÜZÜR: perimetr boyu kirpiklər metaxronal dalğa ilə döyünür, arxada qamçı
## qamçılanır, gövdə sürətə görə dartılır. İçindəki maye hərəkətdən GERİ
## QALIR — ətalət.
##
## **HELIOZOAN — ayaqlı** ("günəş heyvancığı"). Bədəni bərkdir, YERİYİR:
## gövdədən şüa kimi çıxan **aksopodiyalar** (mikroborucuq özəkli sərt
## ayaqlar) növbə ilə yığılıb-uzanır. Heliozoa məhz belə hərəkət edir —
## aksopodların uzunluğunun idarə olunan dəyişməsi ilə. İçindəki maye isə
## ÖNƏ AXIR (*fəvvarə axını*): sitoplazma öndəki ayağa tökülür və gövdəni
## dalınca çəkir.
##
## Daxili axının istiqaməti iki növdə QƏSDƏN əksdir: biri sürüklənir,
## digəri özünü çəkir. Ən incə, amma ən güclü fərqləndirici işarə budur.
##
## Növ RƏNGDƏN çıxarılır (bax [method species_of]) — snapshot-a bir bayt da
## əlavə olunmur.
##
## Oyunçu bir baxışda üç şeyi görməlidir:
##   1. Nə qədər doluyam        → membranın gərginliyi (öz dəqiq sayın HUD-dadır)
##   2. Rəqib partlamağa yaxındırmı → membranı bərk titrəyir və qırmızıya çalır
##   3. Kim mənəm               → kamera HƏMİŞƏ sənin mikrobunun üstündədir
##
## Mikrobun ətrafında HALQA YOXDUR — nə doluluq, nə fokus halqası. Hər ikisi
## vardı və hər ikisi çıxarıldı: mikrobu konsentrik halqaların içinə salırdılar
## və kirpiklər, ayaqlar, qamçı onlarla yarışırdı.
##
## Əvəzinə hər ikisinin işini onsuz da mövcud olan bir şey görür:
##   • doluluq → membranın öz gərginliyi (dəqiq rəqəm HUD-dadır);
##   • "bu, mənəm" → kamera. Öz mikrobun həmişə ekranın mərkəzindədir,
##     adı da parlaq yazılır (rəqiblərinki sönükdür).

## Membran çoxbucaqlısının nöqtə sayı. 24 kifayətdir: kiçik ekranda fərq
## görünmür, amma çəkiliş yükü iki dəfə azdır.
const MEMBRANE_POINTS := 24
const NAME_OFFSET := 22.0

## Halqaların membrandan uzaqlığı.
##
## Rəqəmlər kirpiklərin uzunluğundan (≈ r × 0.20, ən çoxu 10 px) BÖYÜK
## seçilib. Əks halda halqa kirpiklərin düz ortasından keçir və ikisi də
## oxunmaz olur — ilk versiyanın səhvi məhz bu idi.
##
## Yalnız BİR halqa qalıb və o da nadirdir: doğuş qalxanı yalnız ilk bir
## neçə saniyədə görünür. Ona görə mikrobun ətrafı təmizdir.
const SHIELD_GAP := 25.0            ## doğuş qalxanı

## Sürətə görə dartılma həddi. 0.16 = ən sürətli halda 16% uzanır.
## Daha çox olsa mikrob damcıya dönür və toqquşma radiusu ilə uyğunsuzluq
## gözə çarpır — membran gerçək radiusdan uzaqda görünür.
const STRETCH_MAX := 0.16

# ---------------------------------------------------------------- CILIATE
## Kirpiklər. Say radiusdan asılıdır, amma hədlər var: azı oxunmaz,
## çoxu isə telefonda bir-birinə qarışıb tük yumağına dönür.
const CILIA_MIN := 18
const CILIA_MAX := 30
## Halqa boyunca neçə tam dalğa qaçır. 3 seçilib: 1 çox yavaş görünür,
## 5-də qonşu kirpiklər əks istiqamətə baxıb titrəyiş kimi oxunur.
const CILIA_WAVES := 3.0
const CILIA_BEAT := 7.0             ## döyüntü tezliyi (rad/saniyə)
## Qamçının nöqtə sayı və uzunluğu (radiusa nisbətdə).
const TAIL_POINTS := 9
const TAIL_LENGTH := 1.5

# ---------------------------------------------------------------- HELIOZOAN
## Ayaq sayı. Kirpikdən qat-qat azdır: ayaq AYRICA oxunmalıdır, kirpik isə
## kütlə kimi. 13-dən çoxunda gövdə ulduza dönür və addım seçilmir.
const LEGS_MIN := 7
const LEGS_MAX := 13
## Ayağın normal uzaqlığı (radiusa nisbətdə).
##
## Halqalardan (ən uzağı r + 25) KƏNARDA olmalıdır — ilk versiyada 1.55 idi
## və kiçik mikrobda pəncələr düz halqaların üstünə düşürdü, ayaq da,
## halqa da oxunmurdu. Real heliozoada aksopodlar bədən diametri boyda olur,
## yəni 2.15 həm düzgün, həm oxunaqlıdır.
const LEG_REACH := 2.15
## Pəncə "ev" nöqtəsindən bu qədər (radiusa nisbətdə) uzaqlaşanda yeni addım
## atılır. Kiçik olsa mikrob titrəyir, böyük olsa ayaqlar dartılıb qopmuş görünür.
const LEG_STRIDE := 0.85
## Havadakı ayağın sürəti (1/saniyə).
##
## [constant LEG_STRIDE] ilə BİRLİKDƏ tənzimlənməlidir — ikisi yerişin
## "yük dövrünü" (duty cycle) təyin edir: ayaq nə qədər müddət yerdə,
## nə qədər havada olur. Addım uzun və yellənmə sürətli olmalıdır ki, hər an
## ayaqların çoxu YERDƏ qalsın. Əks halda mikrob yerimir, sıçrayır —
## `_test_heliozoan_gait` məhz bunu qoruyur.
const LEG_SWING := 12.0
## Addımın ortasında ayaq bu nisbətdə YIĞILIR. Heliozoa məhz belə yeriyir:
## aksopod qısalır, yeni yerə uzanır. Yana əyilmə DEYİL, uzunluq dəyişməsi —
## üstdən baxışda "sürünmə" yox, "addım" oxunur.
const LEG_TUCK := 0.55

var color_index := 0
var germ_name := ""
var is_local := false
var species := Const.Species.CILIATE

var balls := Const.START_BALLS
var capacity := Const.START_CAPACITY
var aim := 0.0
var alive := true
var safe := false
## Partladı. [method apply] bundan sonra görüntünü geri qaytarmır — öz
## mikrobun hər kadr proqnozdan yenilənir, ona görə tək `visible = false`
## növbəti kadrda geri açılardı.
var burst := false

var _base := Color.WHITE
var _light := Color.WHITE
var _shadow := Color.BLACK
var _label: Label
var _t := 0.0
## Doluluq göstəricisi ani sıçramır — göz üçün yumşaq keçid.
var _shown_fill := 0.0

## Hərəkət yalnız MÖVQEDƏN çıxarılır — nə serverdən, nə proqnozdan sürət
## istənilmir. Səbəb: eyni node həm proqnozla (öz mikrobun), həm
## interpolyasiya ilə (rəqiblər) sürülür, mövqe fərqi isə hər ikisində
## eyni mənanı verir. Nəticədə görüntü qatı şəbəkə qatından tam ayrıdır.
var _last_pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _has_pos := false
## Daxili mayenin sürüşməsi. İstiqaməti NÖVDƏN asılıdır (bax [method _track_motion]).
var _core := Vector2.ZERO

# ---------- ayaqların vəziyyəti (yalnız HELIOZOAN) ----------
## Pəncələr VALİDEYN fəzasında saxlanılır — [member Node2D.position] ilə eyni
## fəzada. Bu, təsadüfi deyil: yerə basılmış pəncə gövdə hərəkət edərkən
## OLDUĞU YERDƏ qalmalıdır. Bütün "yeriyir" hissi elə bundan ibarətdir —
## pəncə yerli koordinatda saxlansaydı gövdə ilə birlikdə sürüşərdi və
## nəticə yeriş yox, titrəyiş olardı.
var _foot := PackedVector2Array()
var _swing_from := PackedVector2Array()
var _swing_to := PackedVector2Array()
## 1.0 = yerə basılıb, 0..1 = havadadır.
var _step := PackedFloat32Array()
var _legs := LEGS_MIN
var _planted := false


## Eyni anda havada ola bilən ən çox ayaq — sayın yarısından BİR AZ AZ.
##
## Bu, bəzək deyil, yerişin TƏRİFİDİR: ayaqların çoxu hər an yerdə olmalıdır,
## əks halda hərəkət yeriş yox, sıçrayışdır. Budcə dolu olanda ayaq növbəsini
## gözləyir — bir az dartılır, sonra daha uzun addım atır.
##
## Yalnız faza yayımına güvənmək kifayət deyildi: mikrob yerindən tərpənəndə
## bütün ayaqlar hələ də eyni anda qalxa bilirdi. Budcə bu xassəni artıq
## TƏMİN EDİR, gözləmir. Qoruyucu: `SimTest._test_heliozoan_gait`.
static func lift_budget(legs: int) -> int:
	return maxi(1, (legs - 1) / 2)


## [param p_species] snapshot-dan gəlir ([constant Const.GFlag.HELIOZOAN]),
## öz mikrobun üçün isə menyudakı seçimdən. Rəngdən ÇIXARILMIR: növ artıq
## oyunçunun seçimidir, rənglə əlaqəsi yoxdur.
func setup(p_color: int, p_name: String, p_is_local: bool,
		p_species := Const.Species.CILIATE) -> void:
	color_index = p_color
	germ_name = p_name
	is_local = p_is_local
	species = p_species
	_base = Palette.germ_color(p_color)
	_light = Palette.germ_light(p_color)
	_shadow = Palette.germ_shadow(p_color)

	if species == Const.Species.HELIOZOAN:
		# Ən böyük ölçüyə görə bir dəfə ayrılır: mikrob böyüdükcə ayaq sayı
		# artır, massivi hər dəfə ölçüləndirmək isə lüzumsuz yaddaş hərəkətidir.
		_foot.resize(LEGS_MAX)
		_swing_from.resize(LEGS_MAX)
		_swing_to.resize(LEGS_MAX)
		_step.resize(LEGS_MAX)

	_label = Label.new()
	_label.text = p_name
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.size = Vector2(200, 24)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Palette.TEXT if p_is_local else Palette.TEXT_MUTED)
	_label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	_label.add_theme_constant_override("outline_size", 5)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)

	# Öz mikrobun həmişə başqalarının üstündə çəkilir — itirməmək üçün.
	z_index = 2 if is_local else 1
	# Hər mikrob öz fazasından başlayır ki, hamısı eyni ritmdə titrəməsin.
	_t = float(p_color) * 1.37


## Mikrob partladı: görüntü [BurstFx]-ə ötürülür və bu node susur.
func kill() -> void:
	burst = true
	alive = false
	visible = false


func apply(p_pos: Vector2, p_aim: float, p_balls: int, p_capacity: int,
		p_safe: bool, p_alive: bool) -> void:
	if burst:
		return
	position = p_pos
	aim = p_aim
	balls = p_balls
	capacity = p_capacity
	safe = p_safe
	if p_alive != alive:
		alive = p_alive
		visible = alive
	_place_label()


func _place_label() -> void:
	if _label == null:
		return
	var r := Const.germ_radius(capacity)
	_label.position = Vector2(-100.0, -r - NAME_OFFSET - 18.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_track_motion(delta)
	if species == Const.Species.HELIOZOAN:
		_walk(delta)

	var target := clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	_shown_fill = move_toward(_shown_fill, target, delta * 2.5)
	queue_redraw()


## Getdiyi istiqamət. Dayanmışsa nişan istiqaməti götürülür ki, yerində
## fırlanan mikrob da düzgün baxsın (və ayaqları ona görə yerini dəyişsin).
func _heading() -> float:
	return _vel.angle() if _vel.length_squared() > 25.0 else aim


## Mövqe fərqindən sürət çıxarır və daxili mayeni sürüşdürür.
##
## Sürət YUMŞALDILIR: rəqiblərin mövqeyi 100 ms-lik interpolyasiya ilə gəlir,
## ona görə xam fərq snapshot sərhədlərində sıçrayır. Yumşaltmadan
## dartılma effekti hər paketdə çırpınardı.
func _track_motion(delta: float) -> void:
	if delta <= 0.0:
		return
	if not _has_pos:
		_last_pos = position
		_has_pos = true
		return

	var raw := (position - _last_pos) / delta
	_last_pos = position
	# Doğuş və yenidən qoşulma mövqeyi bir kadrda dəyişir — o sıçrayış sürət
	# deyil, ona görə atılır. Ayaqlı mikrob üçün eyni siqnal pəncələri də
	# sıfırlayır: gövdə teleport olunanda ayaqlar köhnə yerdə qalmamalıdır.
	if raw.length() > Const.BASE_SPEED * 4.0:
		raw = Vector2.ZERO
		_planted = false
	_vel = _vel.lerp(raw, clampf(delta * 9.0, 0.0, 1.0))

	# Daxili mayenin sürüşməsi — İKİ NÖVDƏ ƏKS İSTİQAMƏTDƏ:
	#   • kirpikli (müsbət): geri qalır. Sürətlənəndə içindəki maye arxada
	#     qalır — üzən yumşaq kisənin ətaləti.
	#   • ayaqlı (mənfi): irəli axır. Sitoplazma öndəki aksopoda tökülür və
	#     gövdəni dalınca çəkir — heliozoa hərəkətinin *fəvvarə axını*.
	var r := Const.germ_radius(capacity)
	var pull := 0.16 if species == Const.Species.CILIATE else -0.20
	var lag := -_vel / Const.BASE_SPEED * (r * pull)
	_core = _core.lerp(lag.limit_length(r * 0.22), clampf(delta * 6.0, 0.0, 1.0))


# ================================================================ ayaqlar

## Aksopodiyaların addım dövrü.
##
## Model animasiyadan yox, HƏNDƏSƏDƏN gəlir: pəncənin dünya koordinatındakı
## yeri saxlanılır və gövdə ondan uzaqlaşana qədər pəncə TƏRPƏNMİR. Hədd
## keçiləndə ayaq yığılır, irəli atılır və yenidən basılır.
##
## Nəticə budur ki, addımın tezliyi HEÇ BİR YERDƏ yazılmayıb — o, mikrobun
## həqiqi sürətindən özü çıxır. Sabit sürətli animasiya olsaydı, yavaş gedən
## mikrobun ayaqları yerdə sürüşərdi (animasiyada "foot sliding" deyilən
## nasazlıq); burada isə dayanan mikrob sadəcə ayaqları üstündə DURUR, axının
## sürüklədiyi mikrob isə addımlamağa başlayır.
func _walk(delta: float) -> void:
	var r := Const.germ_radius(capacity)
	# Böyüyən mikrobda ayaq sayı artır. Say dəyişəndə "ev" nöqtələri sürüşür,
	# ayaqlar isə onsuz da uzaqlığa görə yenidən basılır — özü düzəlir.
	_legs = clampi(int(r * 0.14) + 4, LEGS_MIN, LEGS_MAX)

	var dir := Vector2.from_angle(_heading())
	var reach := r * LEG_REACH
	var stride := r * LEG_STRIDE

	if not _planted:
		_planted = true
		for i in LEGS_MAX:
			# Hər ayaq dövrün BAŞQA nöqtəsindən başlayır: pəncə geriyə doğru
			# müxtəlif qədər sürüşdürülür, ona görə birincidən sonuncuya qədər
			# addım növbəsi onsuz da yayılmış olur.
			#
			# Bu olmadan hamısı eyni məsafədən başlayır və mikrob yerindən
			# tərpənən kimi BÜTÜN ayaqlar bir anda qalxır — yeriş yox, sıçrayış.
			# Səhv gözlə görünmür (bir kadrlıq hadisədir), ona görə testlə tutulub.
			var phase := fposmod(float(i) * 0.381966, 1.0)
			var seat := Vector2.from_angle(TAU * float(i) / float(_legs)) * reach
			_foot[i] = position + seat - dir * (stride * phase)
			_step[i] = 1.0

	# ---- 1. Havadakı ayaqları irəli aparırıq ----
	var lifted := 0
	for i in _legs:
		if _step[i] >= 1.0:
			continue
		_step[i] = minf(1.0, _step[i] + delta * LEG_SWING)
		var k: float = _step[i]
		_foot[i] = _swing_from[i].lerp(_swing_to[i], k * k * (3.0 - 2.0 * k))
		if _step[i] < 1.0:
			lifted += 1

	# ---- 2. Budcə imkan verdikcə ƏN GECİKMİŞ ayağı qaldırırıq ----
	#
	# Növbə indeks sırası ilə verilsəydi, hər zaman birinci ayaq qabağa
	# keçərdi və sonuncu ayaq gözləyə-gözləyə həddindən artıq dartılardı
	# (sınaqda 102 px — həddən bir piksel çox). Ən gecikmişi seçmək həm
	# ədalətlidir, həm də dartılmanı özü məhdudlaşdırır.
	var budget := lift_budget(_legs)
	while lifted < budget:
		var worst := -1
		var worst_over := 0.0
		for i in _legs:
			if _step[i] < 1.0:
				continue
			var over := _foot[i].distance_to(_leg_home(i, r, dir)) - _leg_trip(i, stride)
			if over > worst_over:
				worst_over = over
				worst = i
		if worst < 0:
			break                       # gecikmiş ayaq yoxdur

		_step[worst] = 0.0
		_swing_from[worst] = _foot[worst]
		# Yeni yer evdən bir az İRƏLİDƏ seçilir: ayaq gövdəni qabaqlayır,
		# növbəti addıma qədər isə gövdə ona çatır.
		_swing_to[worst] = _leg_home(worst, r, dir) + dir * (stride * 0.5)
		lifted += 1


## Ayağın olmaq İSTƏDİYİ yer: gövdənin ətrafında, amma getdiyi tərəfə
## sürüşmüş, çünki mikrob ayağı irəliyə uzadır, geriyə yox.
func _leg_home(i: int, r: float, dir: Vector2) -> Vector2:
	return position \
		+ Vector2.from_angle(TAU * float(i) / float(_legs)) * (r * LEG_REACH) \
		+ dir * (r * 0.35)


## Ayağın "evindən" bu qədər uzaqlaşması yeni addım tələb edir.
##
## Hədd hər ayaq üçün FƏRQLİDİR — qızıl nisbətin kəsr hissəsi ardıcıllığı
## bərabər paylayır, ona görə ayaqların dövrü heç vaxt tam üst-üstə düşmür.
func _leg_trip(i: int, stride: float) -> float:
	return stride * (0.65 + 0.7 * fposmod(float(i) * 0.618034, 1.0))


## Pəncənin yerli koordinatı. Addımın ortasında ayaq yığılmış olur, ona görə
## uc nöqtəsi gövdəyə doğru dartılır — çəkiliş və pəncə eyni hesabı görməlidir.
func _leg_tip(i: int, r: float) -> Vector2:
	# Bu node fırlanmır və miqyaslanmır, ona görə valideyn fəzasından yerli
	# fəzaya keçid sadə çıxmadır.
	var tip: Vector2 = _foot[i] - position
	var d := tip.length()
	if d < 1.0:
		return Vector2.ZERO
	var k: float = _step[i]
	if k >= 1.0:
		return tip
	return tip.lerp(tip / d * (r * 1.02), sin(PI * k) * LEG_TUCK)


## Aksopodiyalar. Hər ayaq iki seqmentdir və hamısı BİR çəkiliş çağırışıdır:
## [method CanvasItem.draw_multiline_colors] hər seqmentə ayrıca rəng verə
## bilir, ona görə havadakı ayaq sönük çəkilsə də çağırış sayı artmır.
func _draw_legs(r: float) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var planted := Color(_light, 0.88)
	var lifted := Color(_light, 0.40)

	for i in _legs:
		var tip := _leg_tip(i, r)
		if tip == Vector2.ZERO:
			continue
		var root := tip.normalized() * (r * 0.94)
		var mid := root.lerp(tip, 0.5)
		var col: Color = planted if _step[i] >= 1.0 else lifted
		pts.push_back(root); pts.push_back(mid)
		cols.push_back(col)
		# Uca doğru sönür — aksopod nazilir.
		pts.push_back(mid); pts.push_back(tip)
		cols.push_back(Color(col, col.a * 0.7))

	if not pts.is_empty():
		draw_multiline_colors(pts, cols, 3.0)

	# Pəncələr — yapışma nöqtələri. Basılmış pəncə şüadan GÖZƏ ÇARPACAQ QƏDƏR
	# yoğundur (şüa 3 px, pəncə ən azı 4.2 px): fərq kiçik olsa ayaq sadəcə
	# uzun tikan kimi oxunur. Havadakı pəncə isə xırda və sönükdür —
	# oyunçu bir baxışda hansı ayağın YÜK DAŞIDIĞINI görür.
	for i in _legs:
		var tip := _leg_tip(i, r)
		if tip == Vector2.ZERO:
			continue
		if _step[i] >= 1.0:
			draw_circle(tip, maxf(r * 0.13, 4.2), Color(_light, 0.92))
		else:
			draw_circle(tip, maxf(r * 0.06, 2.0), Color(_light, 0.45))


# ================================================================ çəkiliş

## Çəkiliş sırası qəsdən "əvvəlcə bütün dolu formalar, sonra bütün xətlər"
## şəklindədir. Godot kanvası eyni növ ardıcıl əmrləri bir çəkiliş çağırışına
## yığır — sıra qarışsa, hər mikrob 15-20 ayrıca çağırış olur və mobil GPU-da
## əsas məhdudiyyət məhz çağırış sayıdır.
func _draw() -> void:
	if not alive:
		return

	var r := Const.germ_radius(capacity)
	var fill := _shown_fill
	# Dolduqca membran daha çox gərilir — partlamağa yaxın olduğu buradan görünür.
	var strain := clampf((fill - 0.6) / 0.4, 0.0, 1.0)
	# Sürət 0..1 — dartılma, kirpik döyüntüsü və quyruq bundan asılıdır.
	var rush := clampf(_vel.length() / Const.BASE_SPEED, 0.0, 1.0)
	var heading := _heading()
	var rigid := species == Const.Species.HELIOZOAN

	# Ayaqlı mikrobun gövdəsi BƏRKDİR (mineral skeleti var): daha az və daha
	# yavaş titrəyir, sürətdə demək olar dartılmır. Kirpiklininki isə yumşaq
	# kisədir. Forma dili eynidir, yalnız rəqəmlər fərqlənir — belə olanda iki
	# növ bir dünyanın canlısı kimi görünür, iki ayrı oyundan gəlmiş kimi yox.
	var ring := _membrane(r,
		(0.018 if rigid else 0.030) + (0.030 if rigid else 0.055) * strain,
		(1.6 if rigid else 2.2) + (2.4 if rigid else 3.4) * strain,
		heading, rush * (0.3 if rigid else 1.0))
	var skin := Color(_base.lerp(Palette.DANGER, strain * 0.45), 0.30)

	# ---- dolu formalar ----
	# Kölgə — mikrob döşəmədən qopuq görünsün.
	draw_circle(Vector2(0, 4), r * 1.02, Color(Palette.OUTLINE, 0.35))
	# Bioluminessensiya halosu: suyun içində işıq yayılır (bax ART_BIBLE §1).
	draw_circle(Vector2.ZERO, r + SHIELD_GAP + 6.0, Color(_base, 0.055 + 0.05 * strain))
	if not rigid:
		# Quyruq "əvvəlcə formalar, sonra xətlər" qaydasının YEGANƏ istisnasıdır:
		# xətdir, amma bədənin ARXASINDA olmalıdır ki, dibi membranın altında qalsın.
		# Bir çəkiliş çağırışına dəyər — quyruq olmadan mikrob üzmür, sürüşür.
		_draw_tail(r, heading, rush)
	# İrəli baxan çıxıntı (psevdopodiya) — hansı tərəfə atacağını göstərir.
	# HƏR İKİ növdə var: bu, bəzək deyil, atəş istiqamətinin göstəricisidir.
	draw_circle(Vector2.from_angle(aim) * (r + 5.0), maxf(r * 0.22, 5.0), Color(_light, 0.85))
	draw_colored_polygon(ring, skin)
	_draw_core(r, strain)
	_draw_inner_balls(r)

	# ---- xətlər ----
	if rigid:
		_draw_legs(r)
		# Mineral skelet — bərk gövdənin daxili konturu. Kirpiklidə yoxdur,
		# çünki onun gövdəsi yumşaqdır və belə bir sərhədi olmazdı.
		draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 28, Color(_light, 0.30), 1.6, true)
	else:
		_draw_cilia(r, rush, heading)

	var edge := PackedVector2Array(ring)
	edge.push_back(ring[0])
	draw_polyline(edge, Color(_light, 0.95), 3.0, true)
	# Yaş səth: sol-yuxarıdan gələn işıq parıltısı. Yalnız bir qövsdür,
	# amma "bu, mayedir" mesajını bütün halodan güclü verir.
	draw_arc(Vector2.ZERO, r * 0.80, PI * 1.05, PI * 1.55, 12, Color(Palette.TEXT, 0.35), 2.5, true)

	if safe:
		# Doğuş qalxanı — fırlanan kəsik halqa. Atəş açan kimi sönür.
		draw_arc(Vector2.ZERO, r + SHIELD_GAP, _t * 2.0, _t * 2.0 + PI * 1.4, 24,
			Color(Palette.TEXT, 0.55), 3.0, true)




## Titrəyən membran konturu.
##
## Üç təsir üst-üstə düşür:
##   • iki fərqli tezlikli sinus — mexaniki görünməsin, canlı orqanizm olsun;
##   • doluluq gərginliyi — dolduqca titrəmə güclənir və sürətlənir;
##   • sürətə görə dartılma — getdiyi ox boyunca uzanır, ona dik istiqamətdə
##     yastılaşır. Maye içində üzən cismin forması budur; həcm qorunur, ona
##     görə uzanma və yastılaşma eyni əmsalın tərs cütüdür.
func _membrane(r: float, wobble: float, speed: float, heading: float,
		rush: float) -> PackedVector2Array:
	var stretch := 1.0 + STRETCH_MAX * rush
	var squash := 1.0 / stretch
	var axis := Vector2.from_angle(heading)
	var side := Vector2(-axis.y, axis.x)

	var pts := PackedVector2Array()
	for i in MEMBRANE_POINTS:
		var a := TAU * float(i) / float(MEMBRANE_POINTS)
		var m := 1.0 \
			+ wobble * sin(_t * speed + a * 3.0) \
			+ wobble * 0.6 * sin(_t * speed * 0.7 + a * 5.0)
		var v := Vector2.from_angle(a) * r * m
		pts.push_back(axis * (v.dot(axis) * stretch) + side * (v.dot(side) * squash))
	return pts


## Kirpiklər — perimetr boyu döyünən tüklər (paramesium modeli).
##
## Hər kirpik iki parçadan ibarətdir: dibi membrana dik çıxır, ucu isə
## dalğaya görə yana əyilir. Faza bucaqla birlikdə sürüşür (metaxronal dalğa),
## ona görə halqa boyunca dalğa qaçır — bütün tüklər eyni anda döysəydi
## nəticə titrəyiş kimi görünərdi, üzmə kimi yox.
##
## Hamısı BİR [method CanvasItem.draw_multiline] çağırışıdır: 30 kirpik
## ayrıca xətt olsaydı, tək mikrob 30 çəkiliş çağırışı yeyərdi.
func _draw_cilia(r: float, rush: float, heading: float) -> void:
	var n := clampi(int(r * 0.42), CILIA_MIN, CILIA_MAX)
	var length := clampf(r * 0.20, 5.5, 10.0)
	# Hərəkətdə həm daha sürətli, həm daha geniş döyünür.
	var beat := CILIA_BEAT * (0.55 + 0.9 * rush)
	var sweep := 0.35 + 0.55 * rush
	# Dalğa getdiyi istiqamətin əksinə qaçır — mikrob suyu geri itələyir.
	var flow := heading + PI

	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var phase := _t * beat - a * CILIA_WAVES
		var out := Vector2.from_angle(a)
		var tangent := Vector2(-out.y, out.x)

		var root := out * (r * 0.97)
		var bend := sin(phase) * sweep
		# Ön tərəfdəki kirpiklər arxadakılardan daha az açılır: axın oradan gəlir.
		var lean := 0.45 + 0.55 * (0.5 - 0.5 * cos(a - flow))
		var mid := root + (out * 0.75 + tangent * bend).normalized() * (length * 0.55)
		var tip := mid + (out * 0.35 + tangent * (bend * 1.6)).normalized() * (length * 0.65 * lean)

		pts.push_back(root)
		pts.push_back(mid)
		pts.push_back(mid)
		pts.push_back(tip)

	draw_multiline(pts, Color(_light, 0.50 + 0.28 * rush), 1.8)


## Qamçı — arxada qamçılanan quyruq. Uzunluğu boyunca sinus dalğası qaçır,
## amplitudası uca doğru artır: real qamçının hərəkəti belədir və gözə
## "bu, öz-özünə üzür" mesajını verir.
##
## Dayanan mikrobda da yavaş yellənir — ölü görünməsin.
func _draw_tail(r: float, heading: float, rush: float) -> void:
	var back := Vector2.from_angle(heading + PI)
	var side := Vector2(-back.y, back.x)
	var span := r * TAIL_LENGTH
	var wave := 2.6 + 5.4 * rush
	var amp := r * (0.13 + 0.16 * rush)

	var pts := PackedVector2Array()
	for i in TAIL_POINTS:
		var u := float(i) / float(TAIL_POINTS - 1)
		# Uca doğru həm nazikləşir, həm daha çox yellənir.
		var swing := sin(_t * wave - u * 5.0) * amp * u
		pts.push_back(back * (r * 0.75 + span * u) + side * swing)

	# Sürət artdıqca bir az sönür: sürətli mikrobda diqqət bədənə və
	# kirpiklərə düşməlidir, quyruq isə hərəkət cizgisinə qarışır.
	var col := Color(_base, 0.60 - 0.20 * rush * rush)
	var wide := maxf(r * 0.10, 2.2)
	# İki hissəyə bölünür ki, dibdən uca doğru NAZİLSİN. Godot-un
	# `draw_polyline`-ı dəyişkən qalınlıq bilmir; iki çağırış isə tək
	# çağırışla çəkilmiş "kabel"dən qat-qat canlı görünür.
	var half := (TAIL_POINTS + 1) / 2
	draw_polyline(pts.slice(0, half + 1), col, wide, true)
	draw_polyline(pts.slice(half), Color(col, col.a * 0.75), wide * 0.5, true)


## Daxili kölgə — sitoplazmanın dərin qatı. Toplar bunun ÜSTÜNDƏ oturur,
## ona görə mikrob yastı disk yox, həcmli kisə kimi oxunur.
##
## Parlaq nüvəcik QƏSDƏN yoxdur: mərkəzdə ikinci bir işıqlı nöqtə topla
## qarışardı, top sayı isə oyunun əsas göstəricisidir — onu heç nə təqlid
## etməməlidir. İlk versiyada nüvəcik vardı və məhz belə oxunurdu.
##
## Kölgənin sürüşməsi daxili axını göstərir (bax [method _track_motion]):
## kirpiklidə geri qalır, ayaqlıda öndəki ayağa doğru axır.
func _draw_core(r: float, strain: float) -> void:
	draw_circle(_core, r * 0.62, Color(_shadow.lerp(Palette.DANGER, strain * 0.35), 0.45))


## Orqanellalar — mikrobun içindəki toplar. Oyunun ƏSAS oxunma vasitəsi:
## say həm sursat, həm candır.
##
## Nöqtələr "günəbaxan" (phyllotaxis) düzümü ilə paylanır: qızıl bucaq
## dairəni bərabər doldurur, ona görə say dəyişəndə düzüm sıçramır,
## sadəcə bir top əlavə olunur.
func _draw_inner_balls(r: float) -> void:
	var n := clampi(balls, 0, 40)
	if n <= 0:
		return
	var inner := r * 0.66
	var dot := clampf(inner / sqrt(float(n)) * 0.72, 2.2, 7.0)

	# İşıq nöqtəsi yalnız top kifayət qədər böyükdürsə çəkilir: kiçik topda
	# onsuz da görünmür, çəkiliş çağırışını isə iki dəfə artırır.
	var lit := dot >= 4.0
	for i in n:
		var a := float(i) * 2.39996 + _t * 0.35
		var d := inner * sqrt((float(i) + 0.5) / float(n))
		var jitter := Vector2.from_angle(_t * 1.8 + float(i)) * (dot * 0.18)
		# Toplar da daxili kölgə ilə birlikdə sürüşür — bütün daxili maye
		# bir yerdə axır.
		var p := Vector2.from_angle(a) * d + jitter + _core * 0.6
		draw_circle(p, dot, Color(_light, 0.95))
		if lit:
			draw_circle(p - Vector2(dot * 0.3, dot * 0.3), dot * 0.35, Color(Palette.TEXT, 0.8))


