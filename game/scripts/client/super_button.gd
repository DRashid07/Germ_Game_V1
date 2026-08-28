class_name SuperButton
extends Control
## Super düyməsi — atəş düyməsinin ÜSTÜNDƏ, eyni sağ baş barmaq üçün.
##
## Yeri Brawl Stars-dan götürülüb və orada həll olunmuş bir problemə cavabdır:
## yatay tutulan telefonda iki barmaq artıq doludur (sol joystick, sağ atəş).
## Üçüncü düymə ayrıca yerə qoyulsaydı, oyunçu ya hərəkətdən, ya atəşdən
## əl çəkməli olardı. Atəş düyməsinin bir az yuxarısında isə EYNİ barmaq
## ikisinə də çatır — hərəkət solda toxunulmaz qalır.
##
## Düymə ÜÇ vəziyyət göstərir və üçü də oyunçuya lazımdır:
##   • sönük halqa   — super hazır deyil
##   • dolan halqa   — nə qədər qalıb (dəymə, qida, partlatma doldurur)
##   • yanıb-sönən   — hazırdır, bas
##
## Toxunuşun BAŞLANĞICI [method _gui_input] ilə tutulur (yalnız düymənin
## üstündə), BURAXILMASI isə [method _input] ilə — barmaq düymədən kənara
## sürüşüb qalxsa belə. Eyni səbəb [FireButton]-dakı kimidir: itən buraxılma
## düyməni "basılı" ilişdirir.

signal used    ## Basılan an; super hazırdırsa oyun onu işə salır

@export var radius := 54.0

var _charge := 0.0            ## 0..1
var _ready_now := false
var _color := Palette.TEXT
var _touch_index := -1
var _pressed := false
var _t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	# Yanıb-sönmə YALNIZ hazır olanda hesablanır: sönük düymənin öz saatı
	# olmasının mənası yoxdur və hər kadr yenidən çəkiliş tələb edərdi.
	if _ready_now:
		_t += delta
		queue_redraw()


## Oyunçunun rəngi — hazır düymə məhz onunla yanır, ona görə ekranda
## "mənim superim" başqasının superindən dərhal ayrılır.
func set_local_color(c: Color) -> void:
	_color = c
	queue_redraw()


## [param charge] 0..1 · [param ready] super işlədilə bilərmi.
##
## İkisi ayrıca verilir, çünki eyni şey deyil: doluluq 1.0 ola bilər, amma
## super artıq işləyirsə (tor açıq, qabıq bağlı) yenidən basmaq olmaz.
func set_charge(charge: float, ready: bool) -> void:
	var c := clampf(charge, 0.0, 1.0)
	if is_equal_approx(c, _charge) and ready == _ready_now:
		return
	_charge = c
	_ready_now = ready
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		if _touch_index < 0:
			_touch_index = event.index
			_press()
		accept_event()
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_index < 0:
			_touch_index = -2      # siçan: ayrıca indeks
			_press()
		accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		if event.index == _touch_index:
			_release()
	elif event is InputEventMouseButton and not event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if _touch_index == -2:
			_release()


func _press() -> void:
	_pressed = true
	queue_redraw()
	# Hazır olmayan düymə səs də vermir, siqnal da: boş basılış "işlədi"
	# hissi verməməlidir.
	if _ready_now:
		used.emit()


func _release() -> void:
	_touch_index = -1
	_pressed = false
	queue_redraw()


## Barmaq düymədən kənarda qalxsa da vəziyyət sıfırlanmalıdır.
func release() -> void:
	_release()


func _draw() -> void:
	var c := size * 0.5
	var r := radius
	var scale := 0.93 if _pressed and _ready_now else 1.0
	r *= scale

	# Fon — atəş düyməsi ilə eyni material, bir az kiçik.
	draw_circle(c, r, Color(Palette.PANEL, 0.72))

	if _ready_now:
		# Hazır: dolu halqa + nəbz. Nəbz yalnız BURADA var, ona görə göz onu
		# ekranın qalan hərəkətindən ayırır.
		var pulse := 0.5 + 0.5 * sin(_t * 4.2)
		draw_arc(c, r + 5.0, 0.0, TAU, 40, Color(_color, 0.18 + 0.30 * pulse), 3.0, true)
		draw_arc(c, r, 0.0, TAU, 44, _color, 5.0, true)
		draw_circle(c, r * 0.42, Color(_color, 0.85 + 0.15 * pulse))
		draw_arc(c, r * 0.66, 0.0, TAU, 28, Color(Palette.TEXT, 0.45 + 0.25 * pulse), 2.0, true)
	else:
		# Dolur: boş halqa + dolan qövs. Qövs YUXARIDAN başlayır və saat
		# istiqamətində gedir — dolma istiqaməti gözə tanış olmalıdır.
		#
		# Boş halqa da oyunçunun ÖZ RƏNGİNDƏDİR, sadəcə sönük. Neytral boz
		# çəkiləndə düymə fona qarışırdı və ilk dəfə oynayan onun ümumiyyətlə
		# olduğunu görmürdü — boş düymə də "bura bir şey gələcək" deməlidir.
		draw_arc(c, r, 0.0, TAU, 40, Color(_color, 0.26), 4.0, true)
		if _charge > 0.001:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * _charge, 40,
				Color(_color, 0.85), 5.0, true)
		draw_circle(c, r * 0.34, Color(_color, 0.14 + 0.20 * _charge))
