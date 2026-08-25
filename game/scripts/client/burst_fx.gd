class_name BurstFx
extends Node2D
## Mikrobun partlaması — ölümün görüntüsü.
##
## Demək olar tamamilə kodla çəkilir və səbəbi [GermVisual] ilə eynidir:
## partlayan mikrobun radiusu 28-dən 96 pikselə qədər dəyişir, içindəki top
## sayı isə səpilən damcıların sayını təyin edir. Hazır kadr ardıcıllığı
## bunların heç birini bilmir.
##
## Yeganə istisna duman bulududur: onun YUMŞAQ kənarı lazımdır, kodla
## çəkilən dairə isə kəskin kənar verir. Bulud üçün mövcud `burst.svg`
## radial qradiyenti işlədilir (bax [method _draw_mist]).
##
## ── Niyə beş qat var ──────────────────────────────────────────────────────
## Partlayış oyunun ƏN VACİB hadisəsidir (bax AUDIO_BIBLE §3) və ekranda
## eyni anda başqa 9 mikrob var. Bir ağ ləkə kifayət etmir; hadisə üç ayrı
## kanaldan oxunmalıdır: ANİ (parıltı), YAYILAN (dalğa və duman), QALAN
## (damcılar və membran parçaları). Damcılar həm də oyunçuya səpilən qidanın
## HARAYA getdiyini göstərir — partlayış eyni zamanda bir təklifdir.
##
## Bütün hərəkət MAYE modelindədir: heç nə düz xətlə uçmur, hər şey
## eksponensial sürtünmə ilə yavaşıyır — suyun içində partlayış belə görünür.

## Effektin ömrü. Səsdən (burst.wav = 0.70 s) uzundur ki, qulaq susandan
## sonra göz hələ də hadisənin qalıqlarını görsün.
const LIFETIME := 1.15
## Damcıların suda yavaşıma tempi (1/saniyə) — [constant Const.FLUID_DRAG]
## ilə eyni məntiq, amma daha kəskin: xırda damcı böyük cisimdən tez dayanır.
const DROP_DRAG := 3.4
## Membran parçalarının sayı — çox olsa böyük mikrobda kontur "dağılmış"
## yox, "cırılmış" görünür.
const SHREDS := 9

var _color := Color.WHITE
var _radius := 40.0
var _age := 0.0
## Yaş ləkənin teksturası (`burst.svg`). Yumşaq kənarlı radial qradiyentdir —
## kodla çəkilən dairə belə kənar verə bilmir, ona görə buludu məhz o çəkir.
var _splat: Texture2D = null
## Öz ölümün daha böyük çəkilir: kamera onun üstündədir və oyun bitir.
var _scale := 1.0

var _drop_pos := PackedVector2Array()
var _drop_vel := PackedVector2Array()
var _drop_size := PackedFloat32Array()

var _shred_at := PackedFloat32Array()   ## hər parçanın başlanğıc bucağı
var _shred_span := PackedFloat32Array() ## qövsün uzunluğu (radian)
var _shred_spin := PackedFloat32Array() ## öz oxu ətrafında fırlanma sürəti
var _shred_push := PackedFloat32Array() ## kənara atılma sürəti


## [param p_radius] partlayan mikrobun radiusu (server hadisədə göndərir).
## [param p_balls] içindəki top sayı — damcıların sayını təyin edir; bilinmirsə
## radiusdan təxmin olunur.
func setup(p_color: Color, p_radius: float, p_balls := -1, p_big := false,
		p_splat: Texture2D = null) -> void:
	_color = p_color
	_splat = p_splat
	_radius = maxf(p_radius, 12.0)
	_scale = 1.45 if p_big else 1.0
	z_index = 3                          # hər mikrobun üstündə

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	# Damcılar — səpilən sitoplazma. Say top sayına bağlıdır: dolu mikrob
	# partlayanda ekran daha çox dağılır, bu da qazancın ölçüsünü göstərir.
	var guess := int(_radius / 3.2)
	var n := clampi(p_balls if p_balls > 0 else guess, 10, 28)
	for i in n:
		# Bərabər paylanmış bucaq + kiçik təsadüf: tam simmetrik səpilmə
		# süni görünür, tam təsadüfi isə boşluqlar buraxır.
		var a := TAU * float(i) / float(n) + rng.randf_range(-0.35, 0.35)
		var speed := rng.randf_range(200.0, 480.0) * _scale
		_drop_pos.push_back(Vector2.from_angle(a) * (_radius * rng.randf_range(0.15, 0.5)))
		_drop_vel.push_back(Vector2.from_angle(a) * speed)
		_drop_size.push_back(rng.randf_range(0.055, 0.16) * _radius)

	# Membran parçaları — cırılan qabığın qövsləri.
	for i in SHREDS:
		_shred_at.push_back(TAU * float(i) / float(SHREDS) + rng.randf_range(-0.2, 0.2))
		_shred_span.push_back(rng.randf_range(0.30, 0.62))
		_shred_spin.push_back(rng.randf_range(-3.2, 3.2))
		_shred_push.push_back(rng.randf_range(90.0, 230.0) * _scale)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return

	# Damcılar suda yavaşıyır. Eksponensial sönmə — kadr sürətindən asılı deyil.
	var damp := exp(-DROP_DRAG * delta)
	for i in _drop_pos.size():
		_drop_pos[i] += _drop_vel[i] * delta
		_drop_vel[i] *= damp

	queue_redraw()


func _draw() -> void:
	var u := clampf(_age / LIFETIME, 0.0, 1.0)
	var r := _radius * _scale

	_draw_mist(u, r)
	_draw_waves(u, r)
	_draw_flash(r)
	_draw_drops(u)
	_draw_shreds(u, r)


## Yayılan duman — dağılmış sitoplazma buludu. Ən yavaş sönən qatdır,
## ona görə partlayışın yeri səs bitəndən sonra da bilinir.
##
## Teksturasız variant sınandı və atıldı: `draw_circle` KƏSKİN kənar verir,
## nəticə partlayış buludu yox, rəngli disk kimi oxunurdu. Radial qradiyenti
## olan hazır ləkə (`burst.svg`) isə bir çəkiliş çağırışında düzgün nəticə verir.
func _draw_mist(u: float, r: float) -> void:
	if _splat == null:
		return
	# Bulud mikrobun ÖZ ölçüsündən başlayır və açılır. Əvvəlki variant birbaşa
	# 1.6 r-dən başlayırdı: partlayış "böyüyən bulud" yox, "peyda olan ləkə"
	# kimi oxunurdu — genişlənmə hiss olunmurdu.
	var grow := r * (0.95 + 2.55 * sqrt(u))
	var alpha := 0.70 * (1.0 - u) * (1.0 - u)
	draw_texture_rect(_splat, Rect2(-Vector2(grow, grow), Vector2(grow, grow) * 2.0),
		false, Color(_color, alpha))


## Zərbə dalğaları — üç halqa, bir-birindən gecikmə ilə.
##
## Radius `1 - exp(-t)` qanunu ilə artır: əvvəl sürətlə, sonra yavaşıyaraq.
## Sabit sürətlə genişlənən halqa "partlayış" yox, "animasiya" kimi oxunur;
## suyun içindəki dalğa isə məhz belə söndürülür.
func _draw_waves(u: float, r: float) -> void:
	for i in 3:
		var t := _age - float(i) * 0.075
		if t <= 0.0:
			continue
		var reach := 1.0 - exp(-t * 6.0)
		var life := clampf(t / (LIFETIME * 0.6), 0.0, 1.0)
		if life >= 1.0:
			continue
		# Genişləndikcə həm sönür, həm nazilir — suda dalğa belə yox olur.
		var alpha := (1.0 - life) * (1.0 - life) * (0.85 - 0.22 * float(i))
		var width := (5.0 - float(i)) * (1.0 - 0.6 * reach)
		draw_arc(Vector2.ZERO, r * (1.0 + 1.9 * reach), 0.0, TAU, 48,
			Color(_color.lerp(Palette.TEXT, 0.35), alpha), maxf(width, 1.2), true)


## Ani parıltı — membranın qopduğu an. Çox qısadır (75 ms), amma
## partlayışa "zərbə" hissi verən yeganə qatdır.
func _draw_flash(r: float) -> void:
	if _age > 0.075:
		return
	var k := 1.0 - _age / 0.075
	draw_circle(Vector2.ZERO, r * (0.40 + 0.55 * (1.0 - k)), Color(Palette.TEXT, k))


## Səpilən damcılar. Hər biri arxasında qısa iz buraxır — sürətli damcının
## izi uzun, dayanmışın isə yoxdur, ona görə hərəkət tək kadrda da oxunur.
func _draw_drops(u: float) -> void:
	var fade := 1.0 - u * u
	for i in _drop_pos.size():
		var p := _drop_pos[i]
		var size := _drop_size[i] * (1.0 - 0.55 * u)
		if size < 0.6:
			continue
		draw_circle(p, size, Color(_color.lerp(Palette.TEXT, 0.45), 0.95 * fade))
		var trail := _drop_vel[i] * 0.03
		if trail.length_squared() > 4.0:
			draw_line(p, p - trail, Color(_color, 0.45 * fade), size * 0.7)


## Membran parçaları — qopan qabığın qövsləri. Kənara uçur, öz oxu ətrafında
## fırlanır və nazilir. Hamısı BİR çəkiliş çağırışıdır.
func _draw_shreds(u: float, r: float) -> void:
	var fade := (1.0 - u) * (1.0 - u)
	if fade <= 0.01:
		return

	var pts := PackedVector2Array()
	for i in _shred_at.size():
		var a: float = _shred_at[i]
		# Uçuş məsafəsi damcılarla eyni qanunla söndürülür — hər şey eyni mayededir.
		var flown: float = _shred_push[i] * (1.0 - exp(-DROP_DRAG * _age)) / DROP_DRAG
		var centre := Vector2.from_angle(a) * (r * 0.92 + flown)
		var turn: float = a + _shred_spin[i] * _age
		var span: float = _shred_span[i]

		# Qövs üç seqmentlə çəkilir: iki azdır (düz xətt görünür), dörd artıqdır.
		var prev := Vector2.ZERO
		for j in 4:
			var k := float(j) / 3.0 - 0.5
			var p := centre + Vector2.from_angle(turn + k * span) * (r * 0.34)
			if j > 0:
				pts.push_back(prev)
				pts.push_back(p)
			prev = p

	draw_multiline(pts, Color(_color.lerp(Palette.TEXT, 0.55), 0.95 * fade), 3.5)
