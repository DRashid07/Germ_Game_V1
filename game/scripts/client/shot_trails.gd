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

## shot id -> {"pts": PackedVector2Array, "color": Color, "over": bool}
var _tracks := {}

## Kol yarpaqlarının ÜSTÜNDƏ çəkilən izlər (bax [method set_over]). Ayrı uşaq
## node-dur, çünki bir node-un bütün çəkilişi eyni z-dədir. Kola girən top
## olmayanda yenidən çəkilmir — nə əlavə çağırış, nə əlavə dövr.
var _over: Node2D
## Hazırda yarpaq üstündə olan izlərin id-ləri və üst node son dəfə nəsə çəkibmi.
var _over_ids := {}
var _over_drawn := false


func _ready() -> void:
	_over = Node2D.new()
	# Yarpaqlar z 2-dədir; topun özü də kolun içində z 3-ə qalxır
	# (bax [method Arena._layer_shots]). İz topun arxasında qalmalıdır — ağacda
	# atəş qatından əvvəldir, z eynidir.
	_over.z_index = 3
	add_child(_over)
	_over.draw.connect(_draw_over)


## Top kolun içindədir (və heç bir mikrobun gövdəsində deyil) — onun izi də
## yarpaqların üstünə çıxır, yoxsa top görünər, izi isə yarpaq altında itərdi.
func set_over(id: int, over: bool) -> void:
	if not _tracks.has(id):
		return
	_tracks[id]["over"] = over
	if over:
		_over_ids[id] = true
	else:
		_over_ids.erase(id)


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
	_over_ids.erase(id)


func _draw() -> void:
	_draw_tracks(self, false)
	# Üst node yalnız yarpaq üstündə iz varsa (və ya son iz elə indi çıxıbsa —
	# köhnə xətt silinsin deyə) yenidən çəkilir.
	if _over != null and (not _over_ids.is_empty() or _over_drawn):
		_over.queue_redraw()


func _draw_over() -> void:
	_over_drawn = not _over_ids.is_empty()
	if _over_drawn:
		_draw_tracks(_over, true)


func _draw_tracks(ci: CanvasItem, over: bool) -> void:
	if _tracks.is_empty():
		return
	# Yarpaq üstündə iz yoxdursa (çox vaxt belədir) hər izin bayrağı oxunmur.
	var split := not _over_ids.is_empty()
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for id in _tracks:
		var track: Dictionary = _tracks[id]
		if split and bool(track.get("over", false)) != over:
			continue
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
	ci.draw_multiline_colors(pts, cols, WIDTH)
