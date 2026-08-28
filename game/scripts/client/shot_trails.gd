class_name ShotTrails
extends Node2D
## Uçan topların arxasındakı iz — HAMISI BİR çəkiliş çağırışında.
##
## ── Niyə ayrıca node, niyə `Line2D` yox ──────────────────────────────────
## Hər topa öz [Line2D]-ni versəydik, ekrandakı hər top BİR əlavə çağırış
## olardı. Oyunun bütün büdcəsi ~142 çağırışdır (bax README, "Performans
## ölçmək"), yəni izlər təkbaşına onun onda birini yeyərdi — özü də oyunun
## ən sıx anında, yəni atışma zamanı.
##
## [method CanvasItem.draw_multiline_colors] isə bütün seqmentləri TƏK
## çağırışa yığır və hər seqmentə ayrı rəng verə bilir. İzin uca doğru
## sönməsi məhz buradan gəlir — əlavə heç nə lazım deyil.
##
## Eyni üsul [method GermVisual._draw_cilia]-da da işlənir: 30 kirpik, bir
## çağırış.

## İz neçə keçmiş mövqedən qurulur.
##
## 8 seçilib: 60 FPS-də bu, 133 millisaniyə, yəni topun getdiyi ~56 piksel
## ([constant Const.SHOT_SPEED] = 420 px/s). Daha uzunu suda kometa quyruğu
## kimi oxunur və topun HARADA olduğu itir — iz topu göstərməlidir, ondan
## diqqəti çəkməməlidir.
const SPAN := 8

## İzin ən qalın yeri. Topun öz diametrindən (2 × 10 px) nazikdir: iz topun
## arxasınca sürünməli, onu udmamalıdır.
const WIDTH := 5.0

## Ən yaxın seqmentin şəffaflığı. Uca doğru sıfıra enir.
const ALPHA := 0.55

## shot id -> {"pts": PackedVector2Array, "color": Color}
var _tracks := {}


## Topun bu kadrdakı yerini izə əlavə edir. Hər kadr, hər canlı top üçün
## [Arena] çağırır.
func push(id: int, at: Vector2, color: Color) -> void:
	var track: Dictionary = _tracks.get(id, {})
	if track.is_empty():
		track = {"pts": PackedVector2Array(), "color": color}
		_tracks[id] = track
	var pts: PackedVector2Array = track["pts"]
	# Eyni yerdə duran top iz yaratmır: sıçrayışdan sonrakı kadrda mövqe
	# dəyişmir və sıfır uzunluqlu seqment `draw_multiline`-da nöqtə kimi
	# görünüb izin ucunda ləkə qoyurdu.
	if not pts.is_empty() and pts[pts.size() - 1].distance_squared_to(at) < 1.0:
		return
	pts.push_back(at)
	while pts.size() > SPAN:
		pts.remove_at(0)
	track["pts"] = pts


## Top öldü (dəydi, sıçrama haqqını bitirdi və ya görüş sahəsindən çıxdı).
func drop(id: int) -> void:
	_tracks.erase(id)


func _draw() -> void:
	if _tracks.is_empty():
		return
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for id in _tracks:
		var track: Dictionary = _tracks[id]
		var path: PackedVector2Array = track["pts"]
		if path.size() < 2:
			continue
		var col: Color = track["color"]
		var last := path.size() - 1
		for i in last:
			pts.push_back(path[i])
			pts.push_back(path[i + 1])
			# Sönmə KVADRATİKDİR: xətti sönmə izin ucunu kəsilmiş kimi
			# göstərir, çünki göz zəif fərqi sonda ayırd etmir.
			var u := float(i + 1) / float(last)
			cols.push_back(Color(col, ALPHA * u * u))
	if pts.is_empty():
		return
	draw_multiline_colors(pts, cols, WIDTH)
