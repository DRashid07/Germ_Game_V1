class_name MutationAnatomy
extends Node2D
## Mutasiyanın mikrobun ANATOMİYASINDA görüntüsü (eksperimental profil, design/MODES.md §19).
##
##   • UZUN ÇIXINTI — nişan tərəfə uzanan iti çıxıntı (topun çıxdığı yer uzanıb);
##   • İMPULS QAMÇISI — arxada qalın, yellənən qamçı (geri təpmənin mənbəyi);
##   • YAPIŞQAN AYAQLAR — membranın altından çıxan altı yapışqan yastıq.
##
## Node [GermVisual]-in uşağıdır və onun ARXASINDA çəkilir (`show_behind_parent`, ilk uşaq):
## gövdə — GDScript yolunda da, GPU yolunda da ([GermGPU] gövdə qatı) — kökləri örtür, yəni
## iki yol eyni görüntünü verir. Halqa yoxdur, membran böyümür: toqquşma radiusu gizli
## dəyişmir. Keyfiyyətdən asılı deyil — AŞAĞI və MİNİMUM-da da eyni məlumat görünür.
##
## Yalnız mutasiya və ya ölçü dəyişəndə yenidən çəkilir; nişana dönmə və qamçının
## yellənməsi transformasiyadır, çəkiliş deyil.

var _muts := 0
var _radius := 0.0
var _body := Color.WHITE
var _light := Color.WHITE
var _shadow := Color.BLACK
var _tail: Node2D
var _t := 0.0


func _init() -> void:
	show_behind_parent = true
	BatchDraw.use_mipmaps(self)
	_tail = Node2D.new()
	_tail.show_behind_parent = true
	_tail.draw.connect(_draw_tail)
	add_child(_tail)


func setup(muts: int, radius: float, body: Color, light: Color, shadow: Color) -> void:
	if muts == _muts and is_equal_approx(radius, _radius) and body == _body:
		return
	_muts = muts
	_radius = radius
	_body = body
	_light = light
	_shadow = shadow
	_tail.visible = Const.has_mut(muts, Const.Mut.WHIP)
	_tail.position = Vector2(-0.78 * radius, 0.0)
	queue_redraw()
	_tail.queue_redraw()


## Nişan bucağı — çıxıntı oraya, qamçı əksinə baxır.
func set_aim(angle: float, delta: float) -> void:
	rotation = angle
	if _tail.visible:
		_t += delta
		_tail.rotation = PI + 0.22 * sin(_t * 7.0)


func _draw() -> void:
	var r := _radius
	if r <= 0.0:
		return
	if Const.has_mut(_muts, Const.Mut.STICKY):
		# Yastıqlar: əvvəl hamısının konturu, sonra dolğusu — bir çəkiliş çağırışına yığılır.
		for k in 6:
			var p := Vector2.from_angle(TAU * (float(k) + 0.5) / 6.0) * r * 0.98
			BatchDraw.disc(self, p, r * 0.17, Color(Palette.OUTLINE, 0.85))
		for k in 6:
			var p := Vector2.from_angle(TAU * (float(k) + 0.5) / 6.0) * r * 0.98
			BatchDraw.disc(self, p, r * 0.13, _light.lerp(Color(1.0, 0.92, 0.62), 0.45))
			BatchDraw.disc(self, p + Vector2(-0.3, -0.3) * r * 0.06, r * 0.05, Color(1, 1, 1, 0.8))
	if Const.has_mut(_muts, Const.Mut.LONG):
		var spike := PackedVector2Array([
			Vector2(0.62 * r, -0.17 * r), Vector2(1.40 * r, -0.04 * r), Vector2(1.50 * r, 0.0),
			Vector2(1.40 * r, 0.04 * r), Vector2(0.62 * r, 0.17 * r)])
		var edge := spike.duplicate()
		edge.append(spike[0])
		draw_colored_polygon(spike, _shadow.lerp(_body, 0.35))
		draw_polyline(edge, Palette.OUTLINE, maxf(2.0, r * 0.05), true)
		draw_line(Vector2(0.7 * r, -0.09 * r), Vector2(1.36 * r, -0.02 * r), Color(_light, 0.8),
			maxf(1.0, r * 0.03), true)


## Qamçı: [member _tail]-in öz koordinatında +x boyu dalğalı, nazilən xətt.
func _draw_tail() -> void:
	var r := _radius
	if r <= 0.0:
		return
	var pts := PackedVector2Array()
	for i in 13:
		var x := float(i) / 12.0
		pts.append(Vector2(x * 1.1 * r, sin(x * TAU * 0.9) * 0.12 * r * x))
	_tail.draw_polyline(pts, Palette.OUTLINE, maxf(4.0, r * 0.22), true)
	_tail.draw_polyline(pts, _body, maxf(2.5, r * 0.15), true)
	_tail.draw_polyline(pts.slice(0, 6), Color(_light, 0.7), maxf(1.0, r * 0.05), true)
