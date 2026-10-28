class_name MembraneButton
extends Control
## Membran müdafiəsinin düyməsi (eksperimental profil, design/MODES.md §20). Klaviaturada E.
##
## Super düyməsinin ÜSTÜNDƏdir — atəş və superi örtmür, minimap və hərəkət zonasından
## uzaqdır ([method Hud.apply_settings]). Dörd vəziyyət oxunur:
##   • HAZIR — ön qövs parlaq, halqa tam;
##   • AKTİV — qövs ağ-mavi, qalın (indi qaytarır);
##   • BƏRPA — qövs narıncı və nazik: atəş və super bloklu, müdafiə YOXDUR;
##   • SOYUMA — qövs boz, halqa saat əqrəbi ilə dolur.
## Mümkün olmayan basışda [signal blocked] gəlir və HUD səbəbi yazır.

signal used
signal blocked

const ARC_READY := Color(0.62, 0.92, 0.95)
const ARC_ACTIVE := Color(0.92, 0.98, 1.0)

@export var radius := 42.0

var _phase := Const.MemPhase.NONE
var _cd := 0.0          ## soyumanın qalan payı 0..1
var _ready_now := false
var _touch_index := -1


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	BatchDraw.use_mipmaps(self)


## [param phase] — [enum Const.MemPhase], [param cd] — soyumanın qalan payı (0 hazırdır),
## [param ready] — indi basılsa işə düşərmi.
func set_state(phase: int, cd: float, ready: bool) -> void:
	var c := snappedf(clampf(cd, 0.0, 1.0), 0.02)
	if phase == _phase and is_equal_approx(c, _cd) and ready == _ready_now:
		return
	_phase = phase
	_cd = c
	_ready_now = ready
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var press: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not press:
		return
	accept_event()
	if _ready_now:
		used.emit()
	else:
		blocked.emit()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	BatchDraw.disc(self, c, r, Color(Palette.PANEL, 0.82))
	BatchDraw.ring(self, c, r - 2.0, 0.0, TAU, 40, Color(Palette.PANEL_BORDER, 0.95), 2.0)
	if _cd > 0.0:
		# Soyuma: halqa 12-dən saat əqrəbi ilə dolur — dolanda hazırdır.
		BatchDraw.ring(self, c, r - 2.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - _cd), 32,
			Color(ARC_READY, 0.75), 3.0)
	elif _ready_now:
		BatchDraw.ring(self, c, r - 2.0, 0.0, TAU, 40, Color(ARC_READY, 0.9), 3.0)
	# İkon: ön membranın 120°-lik qövsü (yuxarıya baxır) və arxasında mikrobun gövdəsi.
	var col := Color(Palette.TEXT_MUTED, 0.7)
	var width := 4.0
	match _phase:
		Const.MemPhase.ACTIVE:
			col = ARC_ACTIVE
			width = 7.0
		Const.MemPhase.RECOVER:
			col = Palette.WARNING
			width = 3.0
		_:
			if _ready_now:
				col = ARC_READY
				width = 5.0
	BatchDraw.disc(self, c + Vector2(0.0, r * 0.18), r * 0.34, Color(col, 0.25))
	var pts := BatchDraw.ring_points(c + Vector2(0.0, r * 0.18), r * 0.58,
		-PI * 0.5 - Const.MEMBRANE_HALF, -PI * 0.5 + Const.MEMBRANE_HALF, 14)
	draw_multiline(pts, col, width, true)
