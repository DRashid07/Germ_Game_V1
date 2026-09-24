class_name JuiceFx
extends Node2D
## Qısa döyüş effektlərinin BATCH qatı.
##
## Hər hadisəyə ayrıca Node2D vermək sınanmayıb: sıx atışmada node və çəkiliş
## çağırışı sayı hadisə sayı ilə birlikdə böyüyərdi. Burada bütün lülə alovları,
## sıçrantılar, udulmalar, zərbə halqaları, mükafat auraları və qabıq qırıntıları
## eyni node-da yaşayır; `_draw` onları yalnız üç qalınlıq qrupuna yığır.
## Beləliklə ekranda neçə hadisə olmasından asılı olmayaraq bu qat ən çox ÜÇ
## multiline çağırışı edir.

const MUZZLE_TIME := 0.08
const IMPACT_TIME := 0.22
const WAVE_TIME := 0.40
const ABSORB_TIME := 0.30
const REWARD_TIME := 0.62
const DEBRIS_TIME := 0.52

var _low := false
var _muzzles: Array[Dictionary] = []
var _impacts: Array[Dictionary] = []
var _waves: Array[Dictionary] = []
var _absorbs: Array[Dictionary] = []
var _rewards: Array[Dictionary] = []
var _debris: Array[Dictionary] = []


func setup(low_quality: bool) -> void:
	_low = low_quality
	z_index = 4


## Membranın yarıldığı nöqtədə nişan oxu boyunca 80 ms-lik ləçək.
func muzzle(at: Vector2, angle: float, color: Color) -> void:
	_muzzles.append({"age": 0.0, "at": at, "dir": Vector2.from_angle(angle),
		"color": color})
	queue_redraw()


## Qığılcımlar radial deyil: topun gəldiyi oxun ətrafında dar konusdur.
func impact(at: Vector2, incoming: Vector2, color: Color) -> void:
	var axis := incoming.normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT
	_impacts.append({"age": 0.0, "at": at, "dir": axis, "color": color})
	queue_redraw()


## Partlayışın ilk 0.4 saniyəsində açılan nazik, geniş zərbə halqası.
func shockwave(at: Vector2, radius: float, color: Color) -> void:
	_waves.append({"age": 0.0, "at": at, "radius": maxf(radius, 12.0),
		"color": color})
	queue_redraw()


## Qida əvvəl qısa qövslə membrana uçur, sonunda kiçik su dalğası qoyur.
func absorb(from: Vector2, to: Vector2, color: Color) -> void:
	var side := -1.0 if int(absf(from.x * 0.17 + from.y * 0.31)) % 2 == 0 else 1.0
	var d := to - from
	var control := (from + to) * 0.5
	if d.length_squared() > 1.0:
		control += d.normalized().orthogonal() * minf(34.0, d.length() * 0.28) * side
	_absorbs.append({"age": 0.0, "from": from, "to": to, "control": control,
		"color": color})
	queue_redraw()


## Tutum artımının qızılı aura və halqası. Uçan yazı ayrıca Arena qatındadır.
func reward(at: Vector2, radius: float) -> void:
	_rewards.append({"age": 0.0, "at": at, "radius": maxf(radius, 18.0)})
	queue_redraw()


## Qabığın adi zərbəsi bir tərəfə qırıntı atır; son zərbə bütün çevrəyə dağılır.
func crust(at: Vector2, outward: Vector2, radius: float, full_break: bool) -> void:
	var axis := outward.normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT
	_debris.append({"age": 0.0, "at": at, "dir": axis,
		"radius": maxf(radius, 18.0), "full": full_break})
	queue_redraw()


func _process(delta: float) -> void:
	_advance(_muzzles, delta, MUZZLE_TIME)
	_advance(_impacts, delta, IMPACT_TIME)
	_advance(_waves, delta, WAVE_TIME)
	_advance(_absorbs, delta, ABSORB_TIME)
	_advance(_rewards, delta, REWARD_TIME)
	_advance(_debris, delta, DEBRIS_TIME)
	if not _is_empty():
		queue_redraw()


func _advance(items: Array, delta: float, lifetime: float) -> void:
	for i in range(items.size() - 1, -1, -1):
		var e: Dictionary = items[i]
		e["age"] = float(e["age"]) + delta
		if float(e["age"]) >= lifetime:
			items.remove_at(i)


func _is_empty() -> bool:
	return _muzzles.is_empty() and _impacts.is_empty() and _waves.is_empty() \
		and _absorbs.is_empty() and _rewards.is_empty() and _debris.is_empty()


func _draw() -> void:
	var thick_pts := PackedVector2Array()
	var thick_cols := PackedColorArray()
	var spark_pts := PackedVector2Array()
	var spark_cols := PackedColorArray()
	var ring_pts := PackedVector2Array()
	var ring_cols := PackedColorArray()

	_draw_muzzles(thick_pts, thick_cols)
	_draw_absorbs(thick_pts, thick_cols, ring_pts, ring_cols)
	_draw_impacts(spark_pts, spark_cols)
	_draw_debris(spark_pts, spark_cols, ring_pts, ring_cols)
	_draw_waves(ring_pts, ring_cols)
	_draw_rewards(ring_pts, ring_cols)

	# Qalınlıqların üç qrupa ayrılması formaları oxunaqlı saxlayır, amma hadisə
	# sayı çəkiliş çağırışını artırmır: 1 alov/udulma + 1 qığılcım + 1 halqa.
	if not thick_pts.is_empty():
		draw_multiline_colors(thick_pts, thick_cols, 6.0)
	if not spark_pts.is_empty():
		draw_multiline_colors(spark_pts, spark_cols, 3.5)
	if not ring_pts.is_empty():
		draw_multiline_colors(ring_pts, ring_cols, 3.0)


func _draw_muzzles(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	for raw in _muzzles:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / MUZZLE_TIME, 0.0, 1.0)
		var fade := (1.0 - u) * (1.0 - u)
		var at: Vector2 = e["at"]
		var axis: Vector2 = e["dir"]
		var color: Color = e["color"]
		var lobes := 1 if _low else 3
		for i in lobes:
			var side := float(i) - float(lobes - 1) * 0.5
			var d := axis.rotated(side * 0.34)
			var reach := (28.0 - absf(side) * 7.0) * (0.75 + 0.25 * fade)
			_put(pts, cols, at - axis * 2.0, at + d * reach,
				Color(color.lerp(Palette.BODY_LIGHT, 0.68), 0.95 * fade))


func _draw_impacts(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	for raw in _impacts:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / IMPACT_TIME, 0.0, 1.0)
		var fade := (1.0 - u) * (1.0 - u)
		var at: Vector2 = e["at"]
		var axis: Vector2 = e["dir"]
		var color: Color = e["color"]
		var count := 4 if _low else 8
		for i in count:
			var k := (float(i) / maxf(float(count - 1), 1.0)) * 2.0 - 1.0
			var d := axis.rotated(k * 0.58)
			var speed := 42.0 + 18.0 * sin(float(i) * 4.7 + at.x * 0.013)
			var p := at + d * speed * (0.18 + 0.82 * u)
			var tail := d * (9.0 + 9.0 * (1.0 - u))
			_put(pts, cols, p - tail, p,
				Color(color.lerp(Palette.BODY_LIGHT, 0.62), 0.92 * fade))


func _draw_waves(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	for raw in _waves:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / WAVE_TIME, 0.0, 1.0)
		var reach := 1.0 - pow(1.0 - u, 3.0)
		var color: Color = e["color"]
		_ring(pts, cols, e["at"], float(e["radius"]) * (0.82 + 2.25 * reach),
			20 if _low else 40,
			Color(color.lerp(Palette.BODY_LIGHT, 0.52), 0.82 * (1.0 - u) * (1.0 - u)))


func _draw_absorbs(thick_pts: PackedVector2Array, thick_cols: PackedColorArray,
		ring_pts: PackedVector2Array, ring_cols: PackedColorArray) -> void:
	for raw in _absorbs:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / ABSORB_TIME, 0.0, 1.0)
		var color: Color = e["color"]
		var fade := 1.0 - u
		var trail_count := 2 if _low else 4
		for i in trail_count:
			var u1 := clampf(u - float(i) * 0.055, 0.0, 1.0)
			var u0 := clampf(u1 - 0.045, 0.0, 1.0)
			_put(thick_pts, thick_cols, _bezier(e, u0), _bezier(e, u1),
				Color(Palette.FOOD.lerp(color, 0.32), fade * (0.92 - float(i) * 0.14)))
		if u > 0.68:
			var ripple := (u - 0.68) / 0.32
			_ring(ring_pts, ring_cols, e["to"], 7.0 + ripple * 18.0,
				10 if _low else 18, Color(color, (1.0 - ripple) * 0.62))


func _draw_rewards(pts: PackedVector2Array, cols: PackedColorArray) -> void:
	for raw in _rewards:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / REWARD_TIME, 0.0, 1.0)
		var fade := (1.0 - u) * (1.0 - u)
		var at: Vector2 = e["at"]
		var r := float(e["radius"]) * (1.02 + 0.72 * (1.0 - pow(1.0 - u, 3.0)))
		_ring(pts, cols, at, r, 20 if _low else 36,
			Color(Palette.SUPER_READY, 0.88 * fade))
		var rays := 6 if _low else 12
		for i in rays:
			var a := TAU * float(i) / float(rays) + u * 0.28
			var d := Vector2.from_angle(a)
			_put(pts, cols, at + d * (r + 5.0), at + d * (r + 15.0 + 8.0 * u),
				Color(Palette.SUPER_READY, 0.62 * fade))


func _draw_debris(spark_pts: PackedVector2Array, spark_cols: PackedColorArray,
		ring_pts: PackedVector2Array, ring_cols: PackedColorArray) -> void:
	for raw in _debris:
		var e: Dictionary = raw
		var u := clampf(float(e["age"]) / DEBRIS_TIME, 0.0, 1.0)
		var fade := (1.0 - u) * (1.0 - u)
		var at: Vector2 = e["at"]
		var axis: Vector2 = e["dir"]
		var full := bool(e["full"])
		var count := (6 if _low else 12) if full else (3 if _low else 6)
		for i in count:
			var spread := TAU if full else 1.35
			var k := float(i) / maxf(float(count), 1.0)
			var a := axis.angle() + (k - 0.5) * spread
			if full:
				a = TAU * k + sin(float(i) * 7.1 + at.y * 0.017) * 0.16
			var d := Vector2.from_angle(a)
			var travel := float(e["radius"]) * (0.18 + 1.05 * u) \
				* (0.72 + 0.28 * sin(float(i) * 3.9 + 1.4))
			var p := at + d * travel + Vector2.DOWN * 12.0 * u * u
			var tangent := d.orthogonal() * (3.0 + float(i % 3))
			_put(spark_pts, spark_cols, p - tangent, p + tangent,
				Color(Palette.BRITTLE.lerp(Palette.BODY_LIGHT, 0.20), 0.92 * fade))
		# Toz ayrıca disk deyil: qırıq halqa seqmentləri eyni batch-də yumşaq
		# bulud konturu yaradır; dolu dairə qabığın üstünü bağlayırdı.
		var dust_steps := 6 if _low else 12
		var dust_r := float(e["radius"]) * (0.12 + 0.72 * u)
		for i in dust_steps:
			if i % 3 == 2:
				continue
			var a0 := TAU * float(i) / float(dust_steps)
			var a1 := a0 + TAU / float(dust_steps) * 0.66
			_put(ring_pts, ring_cols, at + Vector2.from_angle(a0) * dust_r,
				at + Vector2.from_angle(a1) * dust_r,
				Color(Palette.MUCUS_EDGE, 0.38 * fade))


func _bezier(e: Dictionary, u: float) -> Vector2:
	var a: Vector2 = e["from"]
	var b: Vector2 = e["control"]
	var c: Vector2 = e["to"]
	var v := 1.0 - u
	return a * v * v + b * 2.0 * v * u + c * u * u


func _ring(pts: PackedVector2Array, cols: PackedColorArray, at: Vector2,
		radius: float, steps: int, color: Color) -> void:
	for i in steps:
		var a0 := TAU * float(i) / float(steps)
		var a1 := TAU * float(i + 1) / float(steps)
		_put(pts, cols, at + Vector2.from_angle(a0) * radius,
			at + Vector2.from_angle(a1) * radius, color)


func _put(pts: PackedVector2Array, cols: PackedColorArray,
		a: Vector2, b: Vector2, color: Color) -> void:
	pts.push_back(a)
	pts.push_back(b)
	cols.push_back(color)
