class_name Minimap
extends Control
## Petri qabının kiçik xəritəsi.
##
## Dünya ekrandan xeyli böyükdür (2400 px enində), ona görə oyunçu harada
## olduğunu bilməlidir — əks halda kənara sıxışdırıldığını gec anlayır.
##
## Xəritə YALNIZ görüş sahəsindəki mikrobları göstərir: server onsuz da
## uzaqdakıları göndərmir, beləcə xəritə "divar arxasını görmək" vasitəsinə
## çevrilmir.

var _dots: Array = []           ## [Vector2 dünya mövqeyi, Color, bool özün]

## Mikrob nöqtələrinin qatı — AYRI canvas item-dir.
##
## Nöqtələr saniyədə 5–10 dəfə dəyişir, qab və 26 maneə isə demək olar heç vaxt.
## Hamısı bir `_draw`-da olanda hər yeniləmədə maneələr də təzədən çəkilirdi —
## zəif telefonda (6.5× yavaş CPU) bir çəkiliş ~4 ms idi. İndi [method _draw]
## yalnız qab dəyişəndə işləyir, nöqtələr isə [method _draw_dots]-dadır.
var _dots_layer: Control

## Dağılmış maneələr — [Arena] hər yeniləmədə ötürür (bax [method Arena._update_minimap]).
## Eyni qiymət yenidən çəkiliş tələb etmir.
var broken := PackedByteArray():
	set(value):
		if value == broken:
			return
		broken = value
		queue_redraw()


func _init() -> void:
	_dots_layer = Control.new()
	_dots_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dots_layer.draw.connect(_draw_dots)
	add_child(_dots_layer)
	# Dairələr disk teksturası ilə çəkilir (bax [BatchDraw]); nöqtələr qatı süzgəci
	# valideyndən götürür.
	BatchDraw.use_mipmaps(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Qabın hazırkı YAŞ radiusu — bundan kənarda mikrob dolub partlayır.
## [Arena] hər snapshot-da yeniləyir (bax [method Arena._on_snapshot]).
var wet_radius := Const.WORLD_RADIUS:
	set(value):
		if is_equal_approx(wet_radius, value):
			return
		wet_radius = value
		queue_redraw()

## Yaş sahənin mərkəzi — YAŞ ADA-da gəzən ada, qalan rejimlərdə qabın mərkəzi.
var wet_center := Vector2.ZERO:
	set(value):
		if wet_center.is_equal_approx(value):
			return
		wet_center = value
		queue_redraw()

## Rejimin qabı və xəritəsi (obyekt rejimlərinin qabı kiçikdir və öz düzümü var).
## [Arena] bir dəfə, rejimi biləndə verir.
var wall := Const.WORLD_RADIUS:
	set(value):
		wall = value
		queue_redraw()
var obstacles: Array[Vector4] = DishMap.obstacles():
	set(value):
		obstacles = value
		queue_redraw()
## Baxanın komandası — Ana və qapı onun gözü ilə rənglənir (bizimki laym, onlarınkı narıncı).
var team := -1:
	set(value):
		if team == value:
			return
		team = value
		queue_redraw()
## NÜVƏ TOPU: qapılar çəkilsin.
var goals := false:
	set(value):
		goals = value
		queue_redraw()
## NÜVƏ TOPU: Nüvənin yeri (`Vector2.INF` — yoxdur). Nöqtələr qatında çəkilir.
var ball := Vector2.INF


func set_dots(dots: Array) -> void:
	_dots = dots
	_dots_layer.queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var k := r / wall

	# Dairələr [BatchDraw] ilə çəkilir. Əvvəl hər `draw_circle` ayrıca poliqon və
	# ayrıca çəkiliş çağırışı idi: 26 maneə ilə minimap kadrda ~45 çağırış edirdi —
	# brauzerdə HUD-un ən bahalı hissəsi (bax README, «Zəif telefonda donma»).
	BatchDraw.disc(self, c, r, Color(Palette.DISH, 0.85))
	BatchDraw.ring(self, c, r, 0.0, TAU, 48, Color(Palette.DISH_EDGE, 0.9), 2.0)

	# YAŞ ZONA — TƏK QALAN-da qab quruyub daralır.
	#
	# Onsuz minimap həmişə tam qabı göstərirdi və oyunçunun "hara qaçım"
	# sualına cavab verə bilmirdi: təhlükəsiz sahə 1200-dən 90 px-ə düşür,
	# xəritə isə dəyişmir. Xəritənin bütün mənası məhz o sualdır.
	if wet_radius < wall - 1.0:
		var wr := wet_radius * k
		var wc := c + wet_center * k
		# QURU halqa tündləşdirilir, yaş sahə isə toxunulmaz qalır.
		#
		# Əvvəl əksinə idi — yaş dairənin üstünə `DISH@0.55` çəkilirdi, yəni
		# içi ilə çölü demək olar eyni rəngdə qalırdı və sərhəd yalnız 2 px-lik
		# xətt idi. Halbuki xəritənin bu hissəsi "hara qaçım" sualına cavab
		# verir: TƏHLÜKƏLİ sahə seçilməlidir, təhlükəsiz olan yox.
		BatchDraw.disc(self, c, r, Color(Palette.DANGER, 0.20))
		BatchDraw.disc(self, wc, wr, Color(Palette.DISH, 0.95))
		BatchDraw.ring(self, wc, wr, 0.0, TAU, 40, Color(Palette.WARNING, 0.95), 2.5)

	# NÜVƏ TOPU-nun qapıları — şüşənin üstündə qövs: öz qapın laym, rəqibinki narıncı.
	if goals:
		var half := asin(clampf(Const.BALL_GOAL_HALF / wall, 0.0, 1.0))
		for t in 2:
			var mid := PI if t == 0 else 0.0
			var col := Palette.ALLY if t == team else Palette.FOE
			BatchDraw.ring(self, c, r, mid - half, mid + half, 8, col, 4.0)

	# Maneələr — oriyentir üçün sönük ləkələr.
	#
	# Kol və cərəyan deşiyi ÖZ rənglərində çəkilir: xəritənin əsas işi
	# "harada gizlənə bilərəm, hara qaçsam məni mərkəzə atar" suallarına
	# cavab verməkdir. Bərk maneələr isə sönük qalır — onlar sadəcə fondur.
	#
	# Dağılmış qabıqlar ÇƏKİLMİR: xəritə keçilməz yer göstərsə, oyunçu
	# açdığı yolu unudar və qaçış marşrutunu səhv seçər.
	var list := obstacles
	for i in list.size():
		if i < broken.size() and DishMap.wall_gone(broken[i]):
			continue
		var o := list[i]
		var col := _kind_color(int(o.w))
		# ANA komandanın rəngindədir — xəritənin bu rejimdəki əsas sualı "hansı bizimkidir".
		if int(o.w) == DishMap.Kind.MOTHER:
			col = Palette.ALLY if (0 if o.x < 0.0 else 1) == team else Palette.FOE
		BatchDraw.disc(self, c + Vector2(o.x, o.y) * k, maxf(o.z * k, 1.5), col)


## Mikroblar — qabın üstündəki ayrı qatda (bax [member _dots_layer]).
func _draw_dots() -> void:
	var c := size * 0.5
	var k := (minf(size.x, size.y) * 0.5 - 2.0) / wall
	# Nüvə mikroblardan ƏVVƏL: onun üstündəki mikrob görünməlidir.
	if ball.is_finite():
		BatchDraw.disc(_dots_layer, c + ball * k, 5.0, Color("F4F1E6"))
	# Əvvəl BÜTÜN nöqtələr, sonra halqalar: disk və xətt fərqli çəkiliş növüdür,
	# növbələşsəydilər hər nöqtə ayrıca çağırış olardı (bax [BatchDraw]).
	for dot in _dots:
		BatchDraw.disc(_dots_layer, c + Vector2(dot[0]) * k, 4.5 if bool(dot[2]) else 3.0, dot[1])
	for dot in _dots:
		var p: Vector2 = c + Vector2(dot[0]) * k
		var mine: bool = dot[2]
		var ally: bool = dot.size() > 3 and bool(dot[3])
		if mine:
			# Halqa AĞDIR, kəhrəba deyil.
			#
			# Əvvəl `Palette.FOCUS` idi və yaş zonanın sərhədi `Palette.WARNING` —
			# ikisi də kəhrəba, yəni matçın sonunda öz nöqtən daralan sərhədə
			# qarışırdı. Xəritədə oyunçunun ƏN ÇOX axtardığı şey özüdür.
			BatchDraw.ring(_dots_layer, p, 7.0, 0.0, TAU, 16, Color(Palette.TEXT, 0.95), 1.8)
		elif ally:
			# YOLDAŞ halqası — komanda rejimlərinin ikinci tanıma kanalı
			# (birincisi ad rəngi, üçüncüsü membrandakı halqadır).
			# Onsuz xəritədə yoldaş rəqibdən heç cür seçilmirdi.
			BatchDraw.ring(_dots_layer, p, 6.0, 0.0, TAU, 16, Color(Palette.ALLY, 0.95), 1.8)


## Maneə növünün xəritə rəngi.
##
## Oyunun içində növ FORMA ilə oxunur (bax [method MapKit.base_name]) —
## xəritədə isə maneə bir neçə pikseldir və forma seçilmir, ona görə burada
## rəng işlədilir. İki ayrı dil deyil: hər ikisi eyni suala cavab verir,
## sadəcə ölçü fərqlidir. Kolun rəngi [Palette]-dəndir — əvvəl burada əl ilə
## yazılmış ayrı yaşıl idi və xəritə dəsti dəyişəndə köhnə qalırdı.
static func _kind_color(kind: int) -> Color:
	match kind:
		DishMap.Kind.BUSH:
			return Color(Palette.BUSH, 0.9)
		DishMap.Kind.VENT:
			return Color("E8A845", 0.9)
		_:
			return Color(Palette.MUCUS, 0.9)
