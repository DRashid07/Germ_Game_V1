class_name SuperButton
extends Control
## Super düyməsi — atəş düyməsinin YANINDA (solunda), eyni sağ baş barmaq üçün.
##
## Yeri Brawl Stars-dan götürülüb və orada həll olunmuş bir problemə cavabdır:
## yatay tutulan telefonda iki barmaq artıq doludur (sol joystick, sağ atəş).
## Üçüncü düymə ayrıca yerə qoyulsaydı, oyunçu ya hərəkətdən, ya atəşdən
## əl çəkməli olardı. Atəşin bir az yanında isə EYNİ barmaq ikisinə də çatır —
## hərəkət solda toxunulmaz qalır. (Dəqiq yer və niyə YUXARI yox, YAN olduğu:
## [method Hud._build_controls].)
##
## Düymə DÖRD vəziyyət göstərir və dördü də oyunçuya lazımdır:
##   • sönük halqa   — super hazır deyil
##   • dolan halqa   — nə qədər qalıb (dəymə, qida, partlatma doldurur)
##   • KİLİDLİ halqa — doluluq tamdır, amma qiyməti ödəyə bilmirsən
##   • yanıb-sönən   — hazırdır, bas
##
## KİLİDLİ hal ayrıca çəkilir və bu, sonradan əlavə olunub: əvvəl dolu-amma-
## hazır-olmayan düymə də oyunçunun öz rəngi ilə TAM halqa çəkirdi, yəni
## "hazır"dan yalnız zəif nəbzlə fərqlənirdi. Kirpikli 4 topda məhz belə
## qalırdı — halqa dolu, basırsan, heç nə olmur, səbəb də yoxdur
## (bax [method Const.super_block_reason]).
##
## Toxunuşun BAŞLANĞICI [method _gui_input] ilə tutulur (yalnız düymənin
## üstündə), BURAXILMASI isə [method _input] ilə — barmaq düymədən kənara
## sürüşüb qalxsa belə. Eyni səbəb [FireButton]-dakı kimidir: itən buraxılma
## düyməni "basılı" ilişdirir.

signal used       ## Basıldı və super hazırdır — oyun onu işə salır
## Basıldı, doluluq TAMDIR, amma super işlədilə bilmir. HUD səbəbi yazır.
##
## Ayrıca siqnaldır, çünki bu, boş basılış DEYİL: oyunçu yanan düymə görüb
## basıb və cavab almalıdır. Sönük düymə isə heç nə göndərmir — orada
## gözlənti də yoxdur.
signal blocked

## Rədd cavabının nə qədər göründüyü.
const DENY_TIME := 0.45

@export var radius := 54.0

var _charge := 0.0            ## 0..1
var _ready_now := false
var _color := Palette.TEXT
var _touch_index := -1
var _pressed := false
var _t := 0.0
var _deny_t := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	# Yanıb-sönmə YALNIZ hazır olanda hesablanır: sönük düymənin öz saatı
	# olmasının mənası yoxdur və hər kadr yenidən çəkiliş tələb edərdi.
	if _deny_t > 0.0:
		_deny_t = maxf(0.0, _deny_t - delta)
		queue_redraw()
	if _ready_now:
		_t += delta
		queue_redraw()


## Doluluq tamdır, amma super işləmir — kilidli haldır.
func _is_locked() -> bool:
	return _charge >= 0.999 and not _ready_now


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
	if _ready_now:
		used.emit()
	elif _is_locked():
		# Doluluq tamdır, amma qiyməti ödənmir: oyunçuya SƏBƏB borcludur.
		# Sönük (hələ dolmamış) düymə isə susur — orada gözlənti yoxdur.
		_deny_t = DENY_TIME
		blocked.emit()


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
	var scale := 0.93 if _pressed and (_ready_now or _is_locked()) else 1.0
	r *= scale

	# Fon — atəş düyməsi ilə eyni material, bir az kiçik.
	draw_circle(c, r, Color(Palette.PANEL, 0.72))

	# Rədd cavabı — kilidli düyməyə basanda qırmızı halqa sönür.
	# Basılışın CAVABSIZ qalmaması üçündür: səbəb yazısı HUD-da çıxır, amma
	# barmağın altındakı düymə də dərhal nəsə deməlidir.
	if _deny_t > 0.0:
		var k := _deny_t / DENY_TIME
		draw_arc(c, r + 6.0, 0.0, TAU, 40, Color(Palette.DANGER, 0.85 * k), 4.0, true)

	if _ready_now:
		# Hazır: dolu halqa + nəbz. Nəbz yalnız BURADA var, ona görə göz onu
		# ekranın qalan hərəkətindən ayırır.
		var pulse := 0.5 + 0.5 * sin(_t * 4.2)
		draw_arc(c, r + 5.0, 0.0, TAU, 40, Color(_color, 0.18 + 0.30 * pulse), 3.0, true)
		draw_arc(c, r, 0.0, TAU, 44, _color, 5.0, true)
		draw_circle(c, r * 0.42, Color(_color, 0.85 + 0.15 * pulse))
		draw_arc(c, r * 0.66, 0.0, TAU, 28, Color(Palette.TEXT, 0.45 + 0.25 * pulse), 2.0, true)
	elif _is_locked():
		# KİLİDLİ: halqa doludur, amma oyunçunun RƏNGİNDƏ DEYİL.
		#
		# Rəng fərqi burada bəzək deyil, yeganə oxunan siqnaldır: forma
		# "hazır" ilə eynidir (tam halqa), ona görə fərqi rəng daşımalıdır.
		# Nəbz də yoxdur — hərəkət yalnız işlək düymədə olmalıdır.
		draw_arc(c, r, 0.0, TAU, 44, Color(Palette.TEXT_MUTED, 0.75), 5.0, true)
		# Üstündən kilid xətti — atəş düyməsindəki "sursat yoxdur" xətti ilə
		# eyni dildir, oyunçu onu artıq tanıyır (bax [method FireButton._draw]).
		var d := Vector2(r * 0.42, r * 0.42)
		draw_line(c - d, c + d, Color(Palette.TEXT_MUTED, 0.85), 5.0, true)
		draw_circle(c, r * 0.30, Color(Palette.TEXT_MUTED, 0.20))
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
