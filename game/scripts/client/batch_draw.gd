class_name BatchDraw
## Dairə və nazik halqa — ardıcıl gələndə BİR çəkiliş çağırışına yığılan variant.
##
## Godot 4.7-nin GLES3 render-ində (brauzerdə WebGL2) `draw_circle`, `draw_arc`
## və `draw_colored_polygon` hər biri ayrıca POLİQONDUR: çəkiləndə ona öz GPU
## buferi yaradılır, hər kadr ayrıca çəkiliş çağırışı gedir, canvas item yenidən
## çəkiləndə isə bufer silinib təzədən yaradılır. Antialias-lı qövs ÜÇ poliqondur
## (xətt + iki yumşaq kənar). Teksturalı düzbucaqlı və xətt seqmenti isə
## ardıcıl gələndə, eyni teksturadadırsa, hamısı bir çağırışa yığılır.
##
## Ölçülüb (brauzer, MİNİMUM, bir sessiyada qatları növbə ilə gizlədərək): kadrın
## ~150 çağırışından ~61-i HUD idi, onun da çoxu minimap — 26 maneənin hər biri
## ayrı `draw_circle`. Brauzerdə bir çağırış ~35 WebGL əmridir və hər əmr GPU
## prosesinə ötürülür; 8 kiçik A55 nüvəli telefonda (Galaxy A04s sinfi) kadrın
## ən böyük hissəsi elə budur (bax README, «Zəif telefonda donma»).
##
## Disk teksturası mipmap-lıdır, ona görə onu çəkən canvas item-də
## `texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` olmalıdır (bax
## [method use_mipmaps]) — yoxsa 3 piksellik nöqtə pilləli çıxır.

## 256 piksellik ağ dairə, radiusu 127 — kənar yumşaltma kətanın içində qalır.
## Şəffaf piksellərin rəngi də AĞDIR: SVG-dən idxalda orada qara qalırdı və
## mipmap ortalaması kiçik nöqtələrin kənarını boz haşiyə ilə tündləşdirirdi.
const DISC := preload("res://assets/sprites/disc.png")
## Düzbucaqlı bu qədər böyük götürülür ki, görünən dairə tam [param radius] olsun.
const _EDGE := 128.0 / 127.0


## Dolu dairə — `draw_circle`-ın yerinə. Kənarı yumşaqdır (poliqonunku pilləli idi).
static func disc(ci: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	if radius <= 0.0:
		return
	var h := radius * _EDGE
	ci.draw_texture_rect(DISC, Rect2(center.x - h, center.y - h, h * 2.0, h * 2.0), false, color)


## Nazik halqa və ya qövs — `draw_arc(..., true)`-nun yerinə.
##
## Seqmentlər `draw_multiline` ilə çəkilir: hər biri ayrıca düzbucaqlıdır və
## hamısı bir çağırışa yığılır. Birləşmə yerlərində seqmentlər bir-birinin üstünə
## çox az düşür, ona görə yalnız NAZİK (≤ 3 px) və demək olar tutqun xətlər üçündür —
## qalın şəffaf halqada üst-üstə düşən künclər nöqtə-nöqtə parlaq görünərdi.
static func ring(ci: CanvasItem, center: Vector2, radius: float, from: float, to: float,
		points: int, color: Color, width: float) -> void:
	ci.draw_multiline(ring_points(center, radius, from, to, points), color, width, true)


## Qövsün seqmentləri `draw_multiline` üçün cüt-cüt: [a0, a1, a1, a2, ...].
## [param points] `draw_arc`-dakı kimidir — seqment sayı ondan bir azdır.
static func ring_points(center: Vector2, radius: float, from: float, to: float,
		points: int) -> PackedVector2Array:
	var n := maxi(points - 1, 1)
	var pts := PackedVector2Array()
	pts.resize(n * 2)
	var prev := center + Vector2(cos(from), sin(from)) * radius
	for i in n:
		var a := lerpf(from, to, float(i + 1) / float(n))
		var p := center + Vector2(cos(a), sin(a)) * radius
		pts[i * 2] = prev
		pts[i * 2 + 1] = p
		prev = p
	return pts


## Disk teksturasını kiçik ölçüdə də hamar çəkmək üçün canvas item-in süzgəci.
## Mipmap-sız teksturalara təsir etmir — onlar adi xətti süzgəclə qalır.
static func use_mipmaps(ci: CanvasItem) -> void:
	ci.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
