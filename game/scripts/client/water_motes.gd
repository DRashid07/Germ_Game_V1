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
##
## İki qat arasında bölünür (bax [member depth]): 80 dərin, 30 səthə yaxın.
const COUNT := 110

## Zərrəciklər kameranın ətrafındakı bu kvadratda saxlanılır (yarı-en, ekran
## eninə nisbətdə). Kənara çıxan zərrəcik əks tərəfə keçir — dünyanın hər
## yerində eyni sıxlıq, sabit yaddaş.
const FIELD_FACTOR := 0.8
## Cizginin uzunluğu = axın sürəti × bu (saniyə). 0.85 seçilib: qısa cizgi
## nöqtəyə bənzəyir, uzunu isə yağış kimi görünür.
const STREAK := 0.85

## Kameranın mərkəzi və görünən sahənin UZUN kənarı — [Arena] hər kadr
## yeniləyir. Uzun kənar, çünki sahə kvadratdır: qısa kənarla ölçülsəydi,
## yatayda ekranın sol və sağ hissəsi zərrəciksiz qalardı.
var focus := Vector2.ZERO
var span := Const.VIEW_SPAN_BASE

## Bu qat nə qədər DƏRİNDƏDİR: 0 = səth, 1 = dib.
##
## Su bir qat deyil, SÜTUNDUR. Bütün zərrəciklər eyni parlaqlıqda və eyni
## sürətlə süzüləndə qat yastı bir "qar" kimi oxunur. İki dərinlik isə
## parallaks verir: dərindəkilər sönük, nazik və yavaş, səthdəkilər parlaq
## və sürətlidir. Göz fərqi ölçmür — DƏRİNLİK kimi oxuyur.
##
## Fərq qəsdən kiçikdir: yuxarıdan baxışda böyük parallaks "kamera səhv
## işləyir" hissi verir.
var depth := 0.0

## Neçə zərrəcik. İki qat arasında bölünür (bax [method Arena._build_world]).
var count := COUNT

## Cərəyan deşikləri `(x, y, radius)` — yalnız HIGH keyfiyyətdə Arena doldurur.
##
## Ayrı zərrəcik node-u qurulmur: sorulan cizgilər aşağıdakı mövcud su batch-inə
## əlavə olunur. LOW-da massiv boş qalır və həm hesab, həm görüntü tam sönür.
var sinks := PackedVector3Array()

var _pos := PackedVector2Array()
var _seed := PackedFloat32Array()
var _ready_field := 0.0
var _flow_t := 0.0


func _ready() -> void:
	# `z_index` QƏSDƏN sıfır qalır. Mənfi qoysaq, zərrəciklər valideynin öz
	# `_draw`-ının — yəni qabın döşəməsinin — ALTINA düşər və tamamilə
	# görünməz olar (Godot-da uşağın z-i valideynin çəkilişinə nisbətdədir).
	# Sıfırda isə ağac sırası işləyir: döşəmə və maneələr altda, zərrəciklər
	# onların üstündə, qida və mikroblar isə sonrakı qatlarda.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in count:
		_pos.push_back(Vector2.ZERO)
		# Hər zərrəciyin öz fazası — hamısı eyni ritmdə titrəməsin.
		_seed.push_back(rng.randf() * TAU)
	_scatter(rng)


## Sayı dəyişdikdən SONRA sahəni yenidən qurur.
##
## [member count] yalnız [method _ready]-də oxunur, ona görə ağaca girmiş
## node-da onu dəyişmək tək başına heç nə etmir. Keyfiyyət ayarı isə düymə ilə
## işlək vaxtı dəyişir (bax [method MenuV2._apply_quality]) və oyunçu fərqi
## elə həmin kadrda görməlidir — yoxsa düymə ölü sayılır.
func rebuild() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_pos.resize(count)
	_seed.resize(count)
	for i in count:
		_seed[i] = rng.randf() * TAU
	_scatter(rng)
	queue_redraw()


## Zərrəcikləri görüş sahəsinə bərabər səpir.
func _scatter(rng: RandomNumberGenerator) -> void:
	var half := span * FIELD_FACTOR
	_ready_field = half
	for i in _pos.size():
		_pos[i] = focus + Vector2(rng.randf_range(-half, half), rng.randf_range(-half, half))


func _process(delta: float) -> void:
	_flow_t += delta
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
		# Dərin qat daha yavaş sürüşür — parallaks buradan gəlir.
		p += (Const.current_at(p) * (1.0 - 0.42 * depth) + jitter) * delta

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
	var cols := PackedColorArray()
	# Şüşə kənarının rəngindən bir az açıq: fonun içində qalmalıdır, amma
	# görünməlidir. Dərin qat sönük və nazikdir.
	var col := Palette.DISH_EDGE.lerp(Palette.TEXT, 0.30 - 0.12 * depth)
	var mote_col := Color(col, 0.40 - 0.16 * depth)
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
		cols.push_back(mote_col)

	# Deşiyə sorulma spiral + radial hərəkətdir. Nöqtə deyil, qısa iz çəkilir
	# ki, axının istiqaməti tək kadrda da oxunsun. Hər ventdə yeddi cizgi
	# kifayətdir; daha çoxu burulğan sprite-ını örtüb deşiyi qapadırdı.
	for vi in sinks.size():
		var sink: Vector3 = sinks[vi]
		var centre := Vector2(sink.x, sink.y)
		for j in 7:
			var phase := fposmod(_flow_t * 0.46 + float(j) / 7.0 + float(vi) * 0.13, 1.0)
			var dist := sink.z * lerpf(0.22, 1.08, 1.0 - phase)
			var angle := _flow_t * 0.92 + float(j) * 2.39996 + phase * 2.8
			var radial := Vector2.from_angle(angle)
			var tangent := radial.orthogonal()
			var p := centre + radial * dist
			# Quyruq hərəkətin əksinə — çölə və bir az saat istiqamətinin əksinə.
			var tail := radial * (5.0 + 7.0 * phase) - tangent * 5.0
			pts.push_back(p)
			pts.push_back(p + tail)
			cols.push_back(Color(Palette.VENT.lerp(Palette.TEXT, 0.28),
				0.16 + 0.30 * (1.0 - phase)))

	# Rəng massivinə keçmək əlavə çağırış yaratmır: adi su cizgiləri ilə isti
	# vent axını eyni multiline batch-də qalır.
	draw_multiline_colors(pts, cols, 1.8 - 0.5 * depth)
