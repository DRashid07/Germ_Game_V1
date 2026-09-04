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

## Dağılmış maneələr — [Arena] hər kadr ötürür (bax [method Arena._update_minimap]).
var broken := PackedByteArray()


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
	queue_redraw()


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

	for dot in _dots:
		var p: Vector2 = c + Vector2(dot[0]) * k
		var col: Color = dot[1]
		var mine: bool = dot[2]
		var ally: bool = dot.size() > 3 and bool(dot[3])
		draw_circle(p, 4.5 if mine else 3.0, col)
		if mine:
			# Halqa AĞDIR, kəhrəba deyil.
			#
			# Əvvəl `Palette.FOCUS` idi və yaş zonanın sərhədi `Palette.WARNING` —
			# ikisi də kəhrəba, yəni matçın sonunda öz nöqtən daralan sərhədə
			# qarışırdı. Xəritədə oyunçunun ƏN ÇOX axtardığı şey özüdür.
			draw_arc(p, 7.0, 0.0, TAU, 16, Color(Palette.TEXT, 0.95), 1.8, true)
		elif ally:
			# YOLDAŞ halqası — komanda rejimlərinin ikinci tanıma kanalı
			# (birincisi ad rəngi, üçüncüsü membrandakı halqadır).
			# Onsuz xəritədə yoldaş rəqibdən heç cür seçilmirdi.
			draw_arc(p, 6.0, 0.0, TAU, 16, Color(Palette.ALLY, 0.95), 1.8, true)


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
