class_name LobMarks
extends Node2D
## Amöbün damcısının XƏBƏRDARLIĞI — düşmə işarəsi, uçuş qövsü və damcının özü.
##
## Damcı maneələrin üstündən keçir və düşdüyü yerdə tək rəqibə +2 verir (bax
## [method Sim._land_lob]). Ona görə təhlükə zərbədən ƏVVƏL oxunmalıdır:
##   • DÜŞMƏ HALQASI — düşmə sahəsinin ([constant Const.LOB_AREA]) sərhədi; içi
##     düşməyə qalan vaxtla dolur, son anda parlayır;
##   • QÖVS — atıcı görünürsə, başlanğıcdan düşmə nöqtəsinə nöqtəli yol;
##   • DAMCI — qövsün üstündə, yerdə kölgəsi ilə. Atıcı görünmürsə (kolda və ya
##     ekrandan kənarda) yol yoxdur: damcı son anda işarənin üstünə yuxarıdan düşür.
##
## Hamısı sadə çəkilişdir, shader yoxdur, ona görə bütün keyfiyyət səviyyələrində eyni
## oxunur. Node dünyanın mənşəyindədir.
##
## Çəkiliş ÜÇ keçiddir — dolu disklər, halqalar, sonra nöqtələr və damcılar — çünki
## ardıcıl gələn eyni növ çəkilişlər bir çağırışa yığılır ([BatchDraw]): damcı nə qədər
## olursa olsun, kadrda üç çağırış. Əvvəl hər damcının halqası iki `draw_arc` idi (hər
## biri yumşaq kənarı ilə üç poliqon) və növbə ilə disklərlə qarışırdı.

## Damcının qövsünün ən hündür nöqtəsi (px) — yalnız görüntü.
const ARC_HEIGHT := 90.0
## Atıcısı görünməyən damcı son bu qədər saniyədə yuxarıdan işarəyə düşür.
const DROP_TIME := 0.3
const DOT_GAP := 26.0

## Hər damcı: `{"origin", "target", "path": bool, "t0", "t1" (saat), "color": Color}`.
var _marks: Array[Dictionary] = []
var _now := 0.0


## Bu kadrın damcıları — [Arena] hər kadr yenidən verir.
func show_marks(marks: Array[Dictionary], now: float) -> void:
	_marks = marks
	_now = now
	queue_redraw()


func _ready() -> void:
	BatchDraw.use_mipmaps(self)


## Damcının uçuşunun payı 0..1 (x) və düşməyə qalan saniyə (y).
func _progress(m: Dictionary) -> Vector2:
	var t0 := float(m["t0"])
	var t1 := float(m["t1"])
	return Vector2(clampf((_now - t0) / maxf(t1 - t0, 0.001), 0.0, 1.0), t1 - _now)


func _draw() -> void:
	# 1. Düşmə sahəsinin içi — vaxtla dolur, son 0.25 s-də parlaqdır ("indi düşür").
	for m in _marks:
		var p := _progress(m)
		var col: Color = m["color"]
		BatchDraw.disc(self, m["target"], Const.LOB_AREA * p.x,
			Color(col, 0.16 if p.y >= 0.25 else 0.30))
	# 2. Sahənin sərhədi və qalan vaxtın qövsü (saat əqrəbi kimi, yuxarıdan).
	for m in _marks:
		var p := _progress(m)
		var col: Color = m["color"]
		var hot := p.y < 0.25
		BatchDraw.ring(self, m["target"], Const.LOB_AREA, 0.0, TAU, 40,
			Color(col, 0.85 if hot else 0.6), 3.0 if hot else 2.0)
		if p.x < 1.0:
			BatchDraw.ring(self, m["target"], Const.LOB_AREA + 6.0, -PI * 0.5,
				-PI * 0.5 + TAU * (1.0 - p.x), 32, Color(Color.WHITE, 0.55), 2.0)
	# 3. Qövsün nöqtələri, kölgə və damcının özü.
	for m in _marks:
		_draw_drop(m)


func _draw_drop(m: Dictionary) -> void:
	var target: Vector2 = m["target"]
	var origin: Vector2 = m["origin"]
	var col: Color = m["color"]
	var p := _progress(m)
	var k := p.x
	var drop: Vector2
	var height: float
	if bool(m["path"]):
		# Nöqtəli qövs — damcının qalan yolu.
		var steps := maxi(int(origin.distance_to(target) / DOT_GAP), 2)
		for i in range(steps + 1):
			var u := float(i) / float(steps)
			if u < k:
				continue
			var dot := origin.lerp(target, u) - Vector2(0.0, ARC_HEIGHT * ShotPrediction.lob_height(u))
			BatchDraw.disc(self, dot, 3.5, Color(col, 0.75))
		drop = origin.lerp(target, k)
		height = ARC_HEIGHT * ShotPrediction.lob_height(k)
	else:
		# Atıcı görünmür: damcı yalnız son anda, yuxarıdan düşür (yer və istiqamət açılmır).
		if p.y > DROP_TIME:
			return
		drop = target
		height = ARC_HEIGHT * clampf(p.y / DROP_TIME, 0.0, 1.0)
	# Yerdəki kölgə və havadakı damcı.
	BatchDraw.disc(self, drop, 7.0, Color(0.0, 0.0, 0.0, 0.25))
	var at := drop - Vector2(0.0, height)
	BatchDraw.disc(self, at, 10.0, Color(col, 0.95))
	BatchDraw.disc(self, at + Vector2(-3.0, -3.0), 3.5, Color(Color.WHITE, 0.7))
