class_name DishMap
extends RefCounted
## Petri qabının statik maneə düzümü — "selik ləkələri".
##
## Client bunları çəkmək, server toqquşma üçün oxuyur — tək mənbə.
## Maneə dairəvidir: `Vector3(x, y, radius)`. Dairə seçilib, çünki mikrob
## dünyasında düz künc yoxdur və dairə-dairə toqquşması ən ucuz testdir.
##
## Düzüm qəsdən üç halqadan ibarətdir: mərkəzdə böyük ləkə (oriyentir),
## ortada gizlənmə üçün ləkələr, kənarda isə qovmaq/tələyə salmaq üçün kiçiklər.

static var _cache: Array[Vector3] = []


static func obstacles() -> Array[Vector3]:
	if not _cache.is_empty():
		return _cache
	var out: Array[Vector3] = []

	# Mərkəzi ləkə — dünyanın oriyentiri.
	out.append(Vector3(0.0, 0.0, 120.0))

	_ring(out, 5, 400.0, 78.0, 0.0)
	_ring(out, 7, 760.0, 96.0, PI / 7.0)
	_ring(out, 9, 1045.0, 58.0, PI / 9.0)

	_cache = out
	return _cache


static func _ring(out: Array[Vector3], count: int, dist: float, radius: float, phase: float) -> void:
	for i in count:
		var a := TAU * float(i) / float(count) + phase
		out.append(Vector3(cos(a) * dist, sin(a) * dist, radius))


## Verilmiş nöqtədə bu radiusda mikrob dayana bilərmi?
## Doğuş yeri seçəndə istifadə olunur — heç kim maneənin içində doğulmamalıdır.
static func is_free(pos: Vector2, radius: float) -> bool:
	if pos.length() > Const.WORLD_RADIUS - radius:
		return false
	for o in obstacles():
		if pos.distance_squared_to(Vector2(o.x, o.y)) < pow(o.z + radius, 2.0):
			return false
	return true
