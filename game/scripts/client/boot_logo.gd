class_name BootLogo
extends CanvasLayer
## Açılış loqosunun (boot splash) oyunun içindəki davamı.
##
## Mühərrik `application/boot_splash/image`-i yalnız oyunun ilk kadrı çəkilənə
## qədər göstərir. Ondan sonra ekran bir kadr boş qalır, menyu isə birdən
## çıxır — loqo "kəsilir". Bu örtük HƏMİN şəkli həmin fonda və həmin yerdə
## saxlayır (`Keep` rejimi kimi: ekrana sığır, mərkəzdədir), menyu çəkiləndən
## sonra isə iki addımda çəkilir: əvvəl loqo tünd fonda sönür, sonra fon əriyib
## menyunu açır. Birlikdə sönəndə yarımşəffaf yazı qəhrəmanın üstündə "kölgə"
## kimi qalırdı. Menyunun giriş animasiyası fon əriyərkən başlayır (bax
## [method hold_time]).
##
## Şəkil `load` ilə yox, xam PNG kimi oxunur: o, idxal olunmur (`.import` →
## `skip`), ixracda isə mühərrik açılış şəklini onsuz da xam saxlayır — APK-da
## eyni şəklin iki nüsxəsi olmur.

## Loqonun sönməsi, saniyə.
const LOGO_FADE := 0.25
## Tünd fonun əriməsi, saniyə.
const BG_FADE := 0.3

static var _live: BootLogo

var _box := Control.new()
var _logo: TextureRect
var _boot_id := 0
var _frames := 0


func _ready() -> void:
	layer = 128
	_live = self
	var boot := get_tree().current_scene
	if boot != null:
		_boot_id = boot.get_instance_id()

	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_box)

	var bg := ColorRect.new()
	bg.color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.add_child(bg)

	# Baytlar ilə: `Image.load_from_file("res://…")` redaktordan işə salınanda
	# "ixracda işləməyəcək" xəbərdarlığı yazır — açılış şəkli üçün bu doğru deyil.
	var bytes := FileAccess.get_file_as_bytes(ProjectSettings.get_setting("application/boot_splash/image"))
	var img := Image.new()
	if bytes.is_empty() or img.load_png_from_buffer(bytes) != OK:
		return
	_logo = TextureRect.new()
	_logo.texture = ImageTexture.create_from_image(img)
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box.add_child(_logo)


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.get_instance_id() == _boot_id:
		return
	# Menyunun ilk kadrı onun qurulduğu kadrdır və zəif telefonda uzun çəkir.
	# Çəkilmə o kadrın delta-sı ilə başlasaydı, bir anda bitərdi — ona görə iki
	# kadr gözlənilir və addım 1/30 saniyə ilə məhdudlaşdırılır.
	_frames += 1
	if _frames < 3:
		return
	var step := minf(delta, 1.0 / 30.0)
	if _logo != null and _logo.modulate.a > 0.0:
		_logo.modulate.a -= step / LOGO_FADE
		return
	_box.modulate.a -= step / BG_FADE
	if _box.modulate.a <= 0.0:
		queue_free()


func _exit_tree() -> void:
	if _live == self:
		_live = null


## Menyunun giriş animasiyası nə qədər gözləməlidir: loqo sönənə qədər. Ondan
## əvvəl başlasaydı, düymələr tünd örtüyün altında görünməz yerdə "açılıb
## qurtarardı". Matçdan qayıdanda örtük yoxdur və gözləmə də yoxdur.
static func hold_time() -> float:
	return LOGO_FADE if _live != null else 0.0
