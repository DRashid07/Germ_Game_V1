class_name MembraneArc
extends Node2D
## Membran müdafiəsinin görüntüsü — YALNIZ ön membranda, kilidli istiqamətin ±60°-si (design/
## MODES.md §20). Tam dairəvi qalxan deyil və faktiki bucaqdan geniş çəkilmir.
##
##   • AKTİV — membran qalın, ağ-mavi "sərtləşir" (qaytarır);
##   • BƏRPA — nazik, narıncı, qırıq qövs: müdafiə YOXDUR, atəş də bloklu — rəqib vaxtını
##     buradan seçir.
##
## [GermVisual]-in uşağıdır və gövdənin ÖNÜNDƏ çəkilir — GDScript və GPU yolunda eyni. Faza
## və istiqamət serverin bayrağından gəlir (öz mikrobunda proqnozdan). Keyfiyyətdən asılı deyil.

const ACTIVE := Color(0.92, 0.98, 1.0)

var _phase := Const.MemPhase.NONE
var _dir := 0.0
var _radius := 0.0


func set_state(phase: int, dir: float, radius: float) -> void:
	visible = phase != Const.MemPhase.NONE
	if phase == _phase and is_equal_approx(dir, _dir) and is_equal_approx(radius, _radius):
		return
	_phase = phase
	_dir = dir
	_radius = radius
	queue_redraw()


func _draw() -> void:
	if _phase == Const.MemPhase.NONE or _radius <= 0.0:
		return
	var r := _radius * 1.04
	var from := _dir - Const.MEMBRANE_HALF
	var to := _dir + Const.MEMBRANE_HALF
	if _phase == Const.MemPhase.ACTIVE:
		var pts := _arc(r, from, to, 20)
		draw_polyline(pts, Color(Palette.OUTLINE, 0.8), maxf(6.0, _radius * 0.20), true)
		draw_polyline(pts, ACTIVE, maxf(4.0, _radius * 0.13), true)
		return
	# Bərpa: qırıq qövs — beş seqment.
	for k in 5:
		var a0 := lerpf(from, to, float(k) / 5.0 + 0.03)
		var a1 := lerpf(from, to, float(k + 1) / 5.0 - 0.03)
		draw_polyline(_arc(r, a0, a1, 4), Color(Palette.WARNING, 0.85), maxf(2.0, _radius * 0.06), true)


static func _arc(r: float, from: float, to: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		out.append(Vector2.from_angle(lerpf(from, to, float(i) / float(n))) * r)
	return out
