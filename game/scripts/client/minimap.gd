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


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_dots(dots: Array) -> void:
	_dots = dots
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 2.0
	var k := r / Const.WORLD_RADIUS

	draw_circle(c, r, Color(Palette.DISH, 0.85))
	draw_arc(c, r, 0.0, TAU, 48, Color(Palette.DISH_EDGE, 0.9), 2.0, true)

	# Maneələr — oriyentir üçün sönük ləkələr.
	for o in DishMap.obstacles():
		draw_circle(c + Vector2(o.x, o.y) * k, maxf(o.z * k, 1.5),
			Color(Palette.MUCUS, 0.9))

	for dot in _dots:
		var p: Vector2 = c + Vector2(dot[0]) * k
		var col: Color = dot[1]
		var mine: bool = dot[2]
		draw_circle(p, 4.5 if mine else 3.0, col)
		if mine:
			draw_arc(p, 7.0, 0.0, TAU, 16, Color(Palette.FOCUS, 0.9), 1.5, true)
