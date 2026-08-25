class_name WaterMotes
extends Node2D
## Suda asılı qalmış zərrəciklər — qabın MAYE olduğunu göstərən qat.
##
## Oyunçu axını mikrobun sürüşməsindən hiss edir, amma GÖRMÜR: özü də,
## rəqib də hərəkət edir, ona görə sürüşməni idarəetmə xətası kimi oxumaq
## olar. Sərbəst zərrəciklər bu şübhəni aradan qaldırır — onların heç bir
## iradəsi yoxdur, yalnız su onları aparır.
##
## Zərrəciklər NÖQTƏ yox, CIZGI kimi çəkilir və cizgi məhz axının istiqaməti
## boyunca uzanır. Beləliklə qat eyni zamanda axın sahəsinin özünü çəkir:
## oyunçu burulğanı görür və ondan istifadə etməyi öyrənir.
##
## Bütün qat BİR [method CanvasItem.draw_multiline] çağırışıdır.

## Zərrəcik sayı. Kadr yükü deyil (bir çağırışdır), amma çoxu fonu
## "qar" kimi göstərir və mikrobların oxunmasına mane olur.
const COUNT := 110
## Zərrəciklər kameranın ətrafındakı bu kvadratda saxlanılır (yarı-en, ekran
## eninə nisbətdə). Kənara çıxan zərrəcik əks tərəfə keçir — dünyanın hər
## yerində eyni sıxlıq, sabit yaddaş.
const FIELD_FACTOR := 0.8
## Cizginin uzunluğu = axın sürəti × bu (saniyə). 0.85 seçilib: qısa cizgi
## nöqtəyə bənzəyir, uzunu isə yağış kimi görünür.
const STREAK := 0.85

## Kameranın mərkəzi və göstərdiyi dünya eni — [Arena] hər kadr yeniləyir.
var focus := Vector2.ZERO
var span := Const.VIEW_WIDTH_BASE

var _pos := PackedVector2Array()
var _seed := PackedFloat32Array()
var _ready_field := 0.0


func _ready() -> void:
	# `z_index` QƏSDƏN sıfır qalır. Mənfi qoysaq, zərrəciklər valideynin öz
	# `_draw`-ının — yəni qabın döşəməsinin — ALTINA düşər və tamamilə
	# görünməz olar (Godot-da uşağın z-i valideynin çəkilişinə nisbətdədir).
	# Sıfırda isə ağac sırası işləyir: döşəmə və maneələr altda, zərrəciklər
	# onların üstündə, qida və mikroblar isə sonrakı qatlarda.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in COUNT:
		_pos.push_back(Vector2.ZERO)
		# Hər zərrəciyin öz fazası — hamısı eyni ritmdə titrəməsin.
		_seed.push_back(rng.randf() * TAU)
	_scatter(rng)


## Zərrəcikləri görüş sahəsinə bərabər səpir.
func _scatter(rng: RandomNumberGenerator) -> void:
	var half := span * FIELD_FACTOR
	_ready_field = half
	for i in _pos.size():
		_pos[i] = focus + Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))


func _process(delta: float) -> void:
	var half := span * FIELD_FACTOR
	# Kamera uzaqlaşanda sahə genişlənir; birdən-birə deyil, tədricən —
	# əks halda böyüyən mikrobun ətrafında zərrəciklər peyda olardı.
	_ready_field = lerpf(_ready_field, half, clampf(delta * 1.5, 0.0, 1.0))
	half = _ready_field

	for i in _pos.size():
		var p: Vector2 = _pos[i]
		# Broun hərəkəti: su molekullarının təsadüfi zərbələri. Zəifdir, amma
		# olmasa zərrəciklər riyazi düzgünlükdə süzülür və süni görünür.
		var jitter := Vector2.from_angle(_seed[i] + float(Time.get_ticks_msec()) * 0.0004) * 6.0
		p += (Const.current_at(p) + jitter) * delta

		# Görüş kvadratından çıxan zərrəcik əks kənardan qayıdır.
		var d := p - focus
		if absf(d.x) > half:
			p.x -= signf(d.x) * half * 2.0
		if absf(d.y) > half:
			p.y -= signf(d.y) * half * 2.0
		_pos[i] = p

	queue_redraw()


func _draw() -> void:
	var pts := PackedVector2Array()
	for i in _pos.size():
		var p: Vector2 = _pos[i]
		var flow := Const.current_at(p)
		# Axının dayandığı yerdə (mərkəz, şüşənin dibi) cizgi nöqtəyə enir —
		# orada su sakitdir və bunu göstərmək lazımdır.
		var tail := flow * STREAK
		if tail.length_squared() < 0.25:
			tail = Vector2(0.9, 0.0)
		pts.push_back(p)
		pts.push_back(p - tail)

	# Şüşə kənarın rəngindən bir az açıq: fonun içində qalmalıdır, amma
	# görünməlidir. Sönük olsa qat boş yerə hesablanır, parlaq olsa
	# mikroblarla yarışır — ikisi arasında dar bir yol var.
	draw_multiline(pts, Color(Palette.DISH_EDGE.lerp(Palette.TEXT, 0.30), 0.55), 1.8)
