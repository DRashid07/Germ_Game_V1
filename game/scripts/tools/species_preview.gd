class_name SpeciesPreview
extends Node2D
## Növlərin görüntüsünü redaktoru açmadan yoxlamaq üçün stend.
##
##   Godot_v4.7.2.exe --path game --resolution 720x1280 -- \
##       --preview --preview-species 2 --shot kadr.png --shot-delay 120
##
## Oyunun içində mikrob 30 piksel radiusundadır — telefonda kifayətdir, amma
## forma üzərində işləyəndə heç nə seçilmir. Burada eyni [GermVisual] böyüdülüb
## çəkilir və HƏQİQİ sürətlə hərəkət edir: sürünmə, addım və kirpik dövrü
## sürətdən çıxdığı üçün dayanan mikroba baxmaq mənasızdır.
##
## Hərəkət düz xətlədir və kamera onu izləyir — dairə üzrə getsə istiqamət
## fasiləsiz dönər və "ön uc" ilə "arxa uc" bir-birinə qarışardı.

## Neçə dəfə böyüdülür.
const ZOOM := 3.4
## Mikrobun tutumu — radius və sürünmə addımı bundan çıxır (`--preview-cap`).
var capacity := 16

var species := Const.Species.AMOEBA
var balls := 9
## 0 = dayanır, 1 = tam sürət. Sürünmə dövrü bundan asılıdır.
var speed_scale := 1.0

## Neçə saniyədən bir atəş açılır — topun membranı yarması görünsün deyə
## (`--preview-fire`). 0 = heç vaxt.
var fire_every := 0.0

var _germ: GermVisual
var _travelled := 0.0
var _cam: Camera2D
var _since_fire := 0.0


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Palette.DISH
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -100
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	_germ = GermVisual.new()
	_germ.setup(0, _title(), true, species)
	add_child(_germ)
	_germ.apply(Vector2.ZERO, 0.0, balls, capacity, false, true)

	_cam = Camera2D.new()
	# Ekranda hər tutum EYNİ ölçüdə görünür — yerişləri müqayisə etmək üçün.
	var k := ZOOM * Const.BASE_RADIUS / Const.germ_radius(capacity)
	_cam.zoom = Vector2(k, k)
	add_child(_cam)
	_cam.make_current()


func _process(delta: float) -> void:
	_travelled += Const.germ_speed(capacity) * speed_scale * delta
	var pos := Vector2(_travelled, 0.0)
	_germ.apply(pos, 0.0, balls, capacity, false, true)
	_cam.position = pos

	# Atəş burada oyun məntiqi olmadan, birbaşa görüntü üzərində sınanılır:
	# stendin məqsədi topun deyil, MEMBRANIN davranışını göstərməkdir.
	if fire_every > 0.0:
		_since_fire += delta
		if _since_fire >= fire_every:
			_since_fire = 0.0
			_germ.eject(0.0)


func _title() -> String:
	match species:
		Const.Species.HELIOZOAN:
			return "AYAQLI"
		Const.Species.AMOEBA:
			return "AMÖB"
		_:
			return "KİRPİKLİ"
