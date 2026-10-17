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
## Hazır olma anının "pop"u — düymə bir anlıq böyüyüb yerinə qayıdır.
const POP_TIME := 0.32
## Növün ikonu — menyudakı kartlarla EYNİ şəkil (bax [MenuV2]). Oyunçu
## düyməni öz növünün superi kimi tanıyır, adsız halqa kimi yox.
const ICONS := {
	Const.Species.CILIATE: "res://assets/ui/species_ciliate.svg",
	Const.Species.HELIOZOAN: "res://assets/ui/species_heliozoan.svg",
	Const.Species.AMOEBA: "res://assets/ui/species_amoeba.svg",
}

@export var radius := 54.0

var _charge := 0.0            ## 0..1
var _ready_now := false
var _color := Palette.TEXT
var _touch_index := -1
var _pressed := false
var _t := 0.0
var _deny_t := 0.0
var _pop_t := 0.0
var _icon: Texture2D = null


func _ready() -> void:
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Disklər (bax [BatchDraw]) və ikon kiçildiləndə pilləsiz qalsın.
	BatchDraw.use_mipmaps(self)


func _process(delta: float) -> void:
	# Yanıb-sönmə YALNIZ hazır olanda hesablanır: sönük düymənin öz saatı
	# olmasının mənası yoxdur və hər kadr yenidən çəkiliş tələb edərdi.
	if _deny_t > 0.0:
		_deny_t = maxf(0.0, _deny_t - delta)
		queue_redraw()
	if _pop_t > 0.0:
		_pop_t = maxf(0.0, _pop_t - delta)
		queue_redraw()
	if _ready_now:
		_t += delta
		queue_redraw()


## Doluluq tamdır, amma super işləmir — kilidli haldır.
func _is_locked() -> bool:
	return _charge >= 0.999 and not _ready_now


## Oyunçunun rəngi — DOLAN düymə onunla çəkilir.
##
## Hazır düymə isə artıq oyunçunun rəngində DEYİL, [constant Palette.SUPER_READY]
## ilə yanır. Əvvəl hazır hal da öz rəngdə idi və oyunçunun rəngi yaşıl/nanə
## olanda dolan halqadan yalnız nəbzlə fərqlənirdi. İndi "hazır" hər yerdə
## eyni qızılı dildədir: düymədə, öz mikrobunun aurasında və RƏQİBİN
## üstündə (bax [member GermVisual.super_ready]).
func set_local_color(c: Color) -> void:
	_color = c
	queue_redraw()


## Düymənin ortasındakı ikon — oyunçunun növü.
func set_species(kind: Const.Species) -> void:
	_icon = load(ICONS.get(kind, ICONS[Const.Species.CILIATE]))
	queue_redraw()


## [param charge] 0..1 · [param ready] super işlədilə bilərmi.
##
## İkisi ayrıca verilir, çünki eyni şey deyil: doluluq 1.0 ola bilər, amma
## super artıq işləyirsə (tor açıq, qabıq bağlı) yenidən basmaq olmaz.
func set_charge(charge: float, ready: bool) -> void:
	var c := clampf(charge, 0.0, 1.0)
	if is_equal_approx(c, _charge) and ready == _ready_now:
		return
	if ready and not _ready_now:
		_pop_t = POP_TIME
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
	if _pop_t > 0.0:
		# Hazır olma anı: sürətli böyümə, yavaş qayıdış (sin yarım dalğası).
		scale *= 1.0 + 0.16 * sin(PI * (1.0 - _pop_t / POP_TIME))
	r *= scale

	# Fon — atəş düyməsi ilə eyni material, bir az kiçik.
	BatchDraw.disc(self, c, r, Color(Palette.PANEL, 0.72))

	# Rədd cavabı — kilidli düyməyə basanda qırmızı halqa sönür.
	# Basılışın CAVABSIZ qalmaması üçündür: səbəb yazısı HUD-da çıxır, amma
	# barmağın altındakı düymə də dərhal nəsə deməlidir.
	if _deny_t > 0.0:
		var k := _deny_t / DENY_TIME
		draw_arc(c, r + 6.0, 0.0, TAU, 40, Color(Palette.DANGER, 0.85 * k), 4.0, true)

	if _ready_now:
		# Hazır: qızılı dolu disk + nəbz + fırlanan işıq zolağı. Hərəkət yalnız
		# BURADA var, ona görə göz onu ekranın qalan hərəkətindən ayırır.
		var gold := Palette.SUPER_READY
		var pulse := 0.5 + 0.5 * sin(_t * 4.2)
		draw_arc(c, r + 9.0, 0.0, TAU, 44, Color(gold, 0.10 + 0.20 * pulse), 6.0, true)
		draw_arc(c, r + 4.0, 0.0, TAU, 44, Color(gold, 0.30 + 0.35 * pulse), 3.0, true)
		BatchDraw.disc(self, c, r - 3.0, Color(gold, 0.88 + 0.12 * pulse))
		draw_arc(c, r, 0.0, TAU, 44, gold.lerp(Color.WHITE, 0.25), 5.0, true)
		# İşıq zolağı halqa boyunca qaçır — "hazırdır" siqnalının ikinci kanalı.
		var sweep := _t * 3.2
		draw_arc(c, r, sweep, sweep + 0.7, 12, Color(Color.WHITE, 0.85), 5.0, true)
		_draw_face(c, r, Palette.OUTLINE, true)
	elif _is_locked():
		# KİLİDLİ: halqa doludur, amma oyunçunun RƏNGİNDƏ DEYİL.
		#
		# Rəng fərqi burada bəzək deyil, yeganə oxunan siqnaldır: forma
		# "hazır" ilə eynidir (tam halqa), ona görə fərqi rəng daşımalıdır.
		# Nəbz də yoxdur — hərəkət yalnız işlək düymədə olmalıdır.
		draw_arc(c, r, 0.0, TAU, 44, Color(Palette.TEXT_MUTED, 0.75), 5.0, true)
		# Üstündən kilid xətti — atəş düyməsindəki "sursat yoxdur" xətti ilə
		# eyni dildir, oyunçu onu artıq tanıyır (bax [method FireButton._draw]).
		BatchDraw.disc(self, c, r - 3.0, Color(Palette.TEXT_MUTED, 0.14))
		_draw_face(c, r, Color(Palette.TEXT_MUTED, 0.55), true)
		var d := Vector2(r * 0.42, r * 0.42)
		draw_line(c - d, c + d, Color(Palette.TEXT_MUTED, 0.85), 5.0, true)
	else:
		# Dolur: boş halqa + dolan qövs. Qövs YUXARIDAN başlayır və saat
		# istiqamətində gedir — dolma istiqaməti gözə tanış olmalıdır.
		#
		# Boş halqa da oyunçunun ÖZ RƏNGİNDƏDİR, sadəcə sönük. Neytral boz
		# çəkiləndə düymə fona qarışırdı və ilk dəfə oynayan onun ümumiyyətlə
		# olduğunu görmürdü — boş düymə də "bura bir şey gələcək" deməlidir.
		#
		# İçi aşağıdan YUXARI dolur — maye səviyyəsi kimi. Halqadakı qövs
		# dəqiq, amma nazikdir; dolan disk isə baş barmağın altından da
		# görünür (barmaq halqanın bir hissəsini həmişə örtür).
		_draw_level(c, r - 3.0, _charge, Color(_color, 0.30))
		draw_arc(c, r, 0.0, TAU, 40, Color(_color, 0.26), 4.0, true)
		if _charge > 0.001:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * _charge, 40,
				Color(_color, 0.85), 5.0, true)
		_draw_face(c, r, Color(Palette.TEXT, 0.35 + 0.35 * _charge), false)


## Ortadakı ikon və "SUPER" yazısı.
##
## Yazı yalnız HAZIR və KİLİDLİ halda çıxır: dolan düymədə ikon kifayətdir,
## yazı isə kiçik ekranda halqanın içini doldurub qövsü oxunmaz edirdi.
func _draw_face(c: Vector2, r: float, tint: Color, label: bool) -> void:
	var lift := r * 0.14 if label else 0.0
	if _icon != null:
		var s := r * (0.92 if label else 1.02)
		draw_texture_rect(_icon, Rect2(c - Vector2(s, s) * 0.5 - Vector2(0.0, lift),
			Vector2(s, s)), false, tint)
	if not label:
		return
	var font := get_theme_default_font()
	var fs := int(r * 0.30)
	draw_string(font, Vector2(c.x - r, c.y + r * 0.62), "SUPER",
		HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, fs, tint)


## Dairənin aşağıdan [param level] (0..1) hündürlüyə qədər dolu hissəsi.
func _draw_level(c: Vector2, r: float, level: float, col: Color) -> void:
	if level <= 0.001:
		return
	if level >= 0.999:
		BatchDraw.disc(self, c, r, col)
		return
	# Səviyyə xəttinin bucağı: y = r - 2r·level ⇒ sin(a) = 1 - 2·level.
	var a := asin(clampf(1.0 - 2.0 * level, -1.0, 1.0))
	var pts := PackedVector2Array()
	var steps := 24
	# Sağ kəsişmədən (a) saat istiqamətində aşağıdan keçib sol kəsişməyə (π - a).
	for i in steps + 1:
		var ang := lerpf(a, PI - a, float(i) / float(steps))
		pts.push_back(c + Vector2(cos(ang), sin(ang)) * r)
	draw_colored_polygon(pts, col)
