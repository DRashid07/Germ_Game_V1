class_name ChunkyBox
extends StyleBox
## Brawl Stars-ın bugünkü düymə və panel dili: qalın qara kontur, altda
## rəngin tünd "dodağı", üz, üst yarıda parıltı.
##
## ── Niyə öz StyleBox-u ───────────────────────────────────────────────────
##
## [StyleBoxFlat]-ın BİR sərhəd rəngi var, bu dilin isə üç qatı var: kontur
## (qara), dodaq (tünd rəng), üz (rəng). Biri əskik olanda düymə ya yastı
## (dodaqsız), ya da "qara ayaqqabılı" (dodaq qara) görünürdü — hər ikisi
## sınandı. Button-un öz `_draw`-ı isə mətndən SONRA çağırılır, yəni orada
## çəkilən fon yazını örtərdi. StyleBox mətndən ƏVVƏL çəkilir, ona görə qatlar
## məhz burada yığılır.
##
## Basılanda dodaq nazikləşir və üz aşağı enir — düymə "içəri girir". Mətn də
## onunla enir (bax [member sink] və [method make]-dəki kənar boşluqları).

## Üzün rəngi. Dodaq və parıltı bundan çıxır — ayrıca rəng saxlanılmır ki,
## düymənin rəngi dəyişəndə biri köhnə qalmasın.
var fill := Color.WHITE
## Konturun rəngi. Seçilmiş kartda laym olur — seçim konturdan oxunur.
var outline := Palette.OUTLINE
var outline_w := 3.0
## Dodağın hündürlüyü (piksel).
var lip := 7.0
## Basılanda üzün nə qədər endiyi.
var sink := 0.0
var radius := 16.0
## Üst yarıdakı parıltının şəffaflığı. Brawl Stars-da hər düymənin üst
## yarısı açıqdır — işığın yuxarıdan gəldiyi elə oradan oxunur.
var gloss := 0.16

var _layer := StyleBoxFlat.new()


## Hazır stil. [param pressed] basılmış variantı qaytarır: dodaq 2 pikselə
## düşür, üz və mətn qalan qədər aşağı enir.
static func make(face: Color, pressed := false, rad := 16.0, lip_h := 7.0) -> ChunkyBox:
	var sb := ChunkyBox.new()
	sb.fill = face
	sb.radius = rad
	sb.lip = 2.0 if pressed else lip_h
	sb.sink = lip_h - 2.0 if pressed else 0.0
	sb.content_margin_left = sb.outline_w + 10.0
	sb.content_margin_right = sb.outline_w + 10.0
	sb.content_margin_top = sb.outline_w + 2.0 + sb.sink
	sb.content_margin_bottom = sb.outline_w + 2.0 + sb.lip
	return sb


## Düyməyə dörd vəziyyəti birdən qoyur.
##
## Üzərinə gəlmə (hover) üzü bir az açır — siçanla oynayanda düymənin "canlı"
## olduğu bilinsin; telefonda hover yoxdur, zərəri də yoxdur.
static func apply(b: Button, face: Color, rad := 16.0, lip_h := 7.0) -> void:
	b.add_theme_stylebox_override("normal", make(face, false, rad, lip_h))
	b.add_theme_stylebox_override("hover", make(face.lightened(0.07), false, rad, lip_h))
	b.add_theme_stylebox_override("pressed", make(face, true, rad, lip_h))
	b.add_theme_stylebox_override("disabled", make(face.darkened(0.35), false, rad, lip_h))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


## Brawl Stars yazısı: ağ mətn, qalın qara kontur, altda kölgə.
##
## Rəngli, işıqlı fonun üstündə — illüstrasiya, sarı düymə, mavi panel —
## konturu olmayan ağ yazı itir. Kontur isə istənilən fonda oxunur.
##
## [param heavy] başlıq şriftinin QALINLAŞDIRILMIŞ variantını qoyur (bax
## [method heavy_font]) — düymə adları, OYNA, qəhrəmanın adı üçün.
static func stroke(c: Control, size := 6, heavy := false) -> void:
	if heavy:
		c.add_theme_font_override("font", heavy_font())
	c.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	c.add_theme_constant_override("outline_size", size)
	if c is Label:
		c.add_theme_color_override("font_shadow_color", Color(Palette.OUTLINE, 0.75))
		c.add_theme_constant_override("shadow_offset_x", 0)
		c.add_theme_constant_override("shadow_offset_y", maxi(2, size / 2))


static var _heavy: FontVariation


## Başlıq şrifti (Baloo 2, 800), bir az qalınlaşdırılmış.
##
## Brawl Stars-ın yazısı (Lilita One) Baloo-dan xeyli qalındır və qalın
## konturla birlikdə "bloklu" oxunur; 800 çəkidə Baloo isə 9 piksellik
## konturun içində nazik qalırdı. Lilita-nın özü götürülə bilməz — onda Ə/ə
## yoxdur (bax `assets/ui/theme.tres`). Ona görə eyni şrift süni
## qalınlaşdırılır: bütün Azərbaycan hərfləri yerində qalır.
static func heavy_font() -> Font:
	if _heavy == null:
		_heavy = FontVariation.new()
		_heavy.base_font = ThemeDB.get_project_theme().get_font("font", "Heading")
		_heavy.variation_embolden = 0.55
	return _heavy


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	# 1. Kontur — dodaq da daxil, bütün forma bir qara lövhənin üstündədir.
	_rect(to_canvas_item, rect, outline, radius + outline_w)
	var inner := rect.grow(-outline_w)
	# 2. Dodaq — üzün rənginin tünd variantı; üzün altından görünən hissədir.
	_rect(to_canvas_item, inner, fill.darkened(0.38), radius)
	# 3. Üz.
	var face := Rect2(inner.position + Vector2(0.0, sink),
		inner.size - Vector2(0.0, lip + sink))
	_rect(to_canvas_item, face, fill, radius)
	# 4. Parıltı — üzün üst 45%-i, amma 24 pikseldən hündür deyil: hündür
	# kartda 45% ayrıca "başlıq zolağı" kimi oxunurdu, düymənin işığı kimi yox.
	if gloss > 0.0:
		var g := Rect2(face.position + Vector2(4.0, 3.0),
			Vector2(face.size.x - 8.0, minf(face.size.y * 0.45, 24.0)))
		_rect(to_canvas_item, g, Color(Palette.BODY_LIGHT, gloss), maxf(radius - 4.0, 2.0))


## Bir yumru düzbucaqlı. Hər qat üçün ayrıca StyleBoxFlat yaradılmır — bir
## köməkçi yenidən rənglənir və çəkilir.
func _rect(ci: RID, r: Rect2, c: Color, rad: float) -> void:
	_layer.bg_color = c
	_layer.set_corner_radius_all(int(rad))
	_layer.draw(ci, r)
