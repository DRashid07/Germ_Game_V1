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


func set_dots(dots: Array) -> void:
	_dots = dots
	_dots_layer.queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var k := r / Const.WORLD_RADIUS

	draw_circle(c, r, Color(Palette.DISH, 0.85))
	draw_arc(c, r, 0.0, TAU, 48, Color(Palette.DISH_EDGE, 0.9), 2.0, true)

	# YAŞ ZONA — TƏK QALAN-da qab quruyub daralır.
	#
	# Onsuz minimap həmişə tam qabı göstərirdi və oyunçunun "hara qaçım"
	# sualına cavab verə bilmirdi: təhlükəsiz sahə 1200-dən 90 px-ə düşür,
	# xəritə isə dəyişmir. Xəritənin bütün mənası məhz o sualdır.
	if wet_radius < Const.WORLD_RADIUS - 1.0:
		var wr := wet_radius * k
		# QURU halqa tündləşdirilir, yaş sahə isə toxunulmaz qalır.
		#
		# Əvvəl əksinə idi — yaş dairənin üstünə `DISH@0.55` çəkilirdi, yəni
		# içi ilə çölü demək olar eyni rəngdə qalırdı və sərhəd yalnız 2 px-lik
		# xətt idi. Halbuki xəritənin bu hissəsi "hara qaçım" sualına cavab
		# verir: TƏHLÜKƏLİ sahə seçilməlidir, təhlükəsiz olan yox.
		draw_circle(c, r, Color(Palette.DANGER, 0.20))
		draw_circle(c, wr, Color(Palette.DISH, 0.95))
		draw_arc(c, wr, 0.0, TAU, 40, Color(Palette.WARNING, 0.95), 2.5, true)

	# Maneələr — oriyentir üçün sönük ləkələr.
	#
	# Kol və cərəyan deşiyi ÖZ rənglərində çəkilir: xəritənin əsas işi
	# "harada gizlənə bilərəm, hara qaçsam məni mərkəzə atar" suallarına
	# cavab verməkdir. Bərk maneələr isə sönük qalır — onlar sadəcə fondur.
	#
	# Dağılmış qabıqlar ÇƏKİLMİR: xəritə keçilməz yer göstərsə, oyunçu
	# açdığı yolu unudar və qaçış marşrutunu səhv seçər.
	var list := DishMap.obstacles()
	for i in list.size():
		if i < broken.size() and DishMap.wall_gone(broken[i]):
			continue
		var o := list[i]
		draw_circle(c + Vector2(o.x, o.y) * k, maxf(o.z * k, 1.5), _kind_color(int(o.w)))


## Mikroblar — qabın üstündəki ayrı qatda (bax [member _dots_layer]).
func _draw_dots() -> void:
	var c := size * 0.5
	var k := (minf(size.x, size.y) * 0.5 - 2.0) / Const.WORLD_RADIUS
	for dot in _dots:
		var p: Vector2 = c + Vector2(dot[0]) * k
		var col: Color = dot[1]
		var mine: bool = dot[2]
		var ally: bool = dot.size() > 3 and bool(dot[3])
		_dots_layer.draw_circle(p, 4.5 if mine else 3.0, col)
		if mine:
			# Halqa AĞDIR, kəhrəba deyil.
			#
			# Əvvəl `Palette.FOCUS` idi və yaş zonanın sərhədi `Palette.WARNING` —
			# ikisi də kəhrəba, yəni matçın sonunda öz nöqtən daralan sərhədə
			# qarışırdı. Xəritədə oyunçunun ƏN ÇOX axtardığı şey özüdür.
			_dots_layer.draw_arc(p, 7.0, 0.0, TAU, 16, Color(Palette.TEXT, 0.95), 1.8, true)
		elif ally:
			# YOLDAŞ halqası — komanda rejimlərinin ikinci tanıma kanalı
			# (birincisi ad rəngi, üçüncüsü membrandakı halqadır).
			# Onsuz xəritədə yoldaş rəqibdən heç cür seçilmirdi.
			_dots_layer.draw_arc(p, 6.0, 0.0, TAU, 16, Color(Palette.ALLY, 0.95), 1.8, true)


## Maneə növünün xəritə rəngi.
##
## Oyunun içində növ FORMA ilə oxunur (bax [const Arena.BLOB_TEXTURE]) —
## xəritədə isə maneə bir neçə pikseldir və forma seçilmir, ona görə burada
## rəng işlədilir. İki ayrı dil deyil: hər ikisi eyni suala cavab verir,
## sadəcə ölçü fərqlidir.
static func _kind_color(kind: int) -> Color:
	match kind:
		DishMap.Kind.BUSH:
			return Color("3E8A6B", 0.9)
		DishMap.Kind.VENT:
			return Color("E8A845", 0.9)
		_:
			return Color(Palette.MUCUS, 0.9)
