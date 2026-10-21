class_name AmmoBar
extends Node2D
## Öz mikrobunun ALTINDAKI top zolağı — Brawl Stars-ın sursat zolağı kimi.
##
## ── Niyə mikrobun altında ────────────────────────────────────────────────
## Oyunun bütün qərarları bir rəqəmdən asılıdır: neçə topun var və tutumun nə
## qədərdir. O rəqəm əvvəl yalnız sol-yuxarı küncdə idi (böyük "4 / 10" və
## zolaq). Döyüşdə isə göz mərkəzdədir — öz mikrobunda, nişan xəttində,
## yaxınlaşan topda. Küncə baxmaq üçün göz döyüşü buraxmalı idi. Brawl Stars
## sursatı ona görə oyunçunun düz altında göstərir.
##
## Künc rəqəmi qalır, amma kiçikdir ([method Hud._build_gauge]): dəqiq say
## lazım olanda oradadır, "doluyam / boşalıram" isə buradan oxunur.
##
## ── Niyə dünyada, HUD-da yox ─────────────────────────────────────────────
## Zolaq mikroba BAĞLIDIR: kamera zərbəsi, təpik və silkələnmə mikrobu ekranın
## mərkəzindən tərpədir, HUD isə yerində qalır — ekran koordinatında çəkilən
## zolaq zərbə anında mikrobdan qopardı. Dünyadadır, amma miqyası kameranın
## əksidir ([method Arena._update_ammo_bar]): ekranda ölçüsü həmişə eynidir,
## mikrob böyüyəndə və kamera uzaqlaşanda kiçilmir.
##
## Rəqəm yazılmır, yalnız zolaq: hər yazı iki çəkiliş çağırışıdır (kontur
## qlifləri ayrı teksturadadır) və mərkəzə yenidən yazı yığardı — öz adın elə
## buna görə yığışdırılıb ([member GermVisual.show_name]).

## Ölçülər EKRAN pikselidir. En mikrobun diametrindən bir az böyükdür
## (oyunda radius ~30 px): Brawl Stars-da da zolaq qəhrəmanın enindədir.
const WIDTH := 84.0
const HEIGHT := 11.0
const BORDER := 2.5
## Zolağın gövdədən aşağı aralığı (ekran px) — kirpiklərin ucundan bir az o yana.
const GAP := 14.0
## Bölmələr: kiçik tutumda hər top bir bölmədir (atəş −1, zərbə +2 — sayılır),
## böyük tutumda bölmələr bir-birinə yapışar, ona görə beşlikdir.
const TICK_EACH_MAX := 20
const TICK_GROUP := 5

var _balls := -1
var _capacity := -1
var _target := 0.0
var _shown := 0.0
var _t := 0.0
var _plate := StyleBoxFlat.new()
var _fill := StyleBoxFlat.new()


func _init() -> void:
	# Kol tacının (z 2) və onun üstündəki topların (z 3) da ÜSTÜNDƏDİR: kolda
	# gizlənəndə mikrob şəffaflaşır, amma öz sayını görmək lazımdır.
	z_index = 4
	_plate.bg_color = Color(Palette.OUTLINE, 0.92)
	_plate.set_corner_radius_all(int(ceil(HEIGHT * 0.5 + BORDER)))
	_plate.anti_aliasing = true
	_fill.set_corner_radius_all(int(ceil(HEIGHT * 0.5)))
	_fill.anti_aliasing = true


## [Arena] hər tick çağırır — HUD-un künc rəqəmi ilə eyni say ([method Hud.update_gauge]).
func set_value(balls: int, capacity: int) -> void:
	if balls == _balls and capacity == _capacity:
		return
	# İlk dəyər animasiyasız oturur — doğuşda zolaq sıfırdan "dolmasın".
	var first := _capacity < 0
	_balls = balls
	_capacity = capacity
	_target = clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	if first:
		_shown = _target
	queue_redraw()


func _process(delta: float) -> void:
	if not visible or _capacity < 0:
		return
	_t += delta
	var moving := not is_equal_approx(_shown, _target)
	if moving:
		# Eksponensial yaxınlaşma: zərbənin +2-si dərhal oxunur, sonu yumşaq oturur.
		_shown = lerpf(_shown, _target, 1.0 - exp(-delta * 14.0))
		if absf(_shown - _target) < 0.002:
			_shown = _target
	# Təhlükədə (dolu və ya ac) zolaq hər kadr yenidən çəkilir; sakit halda heç vaxt.
	if moving or _danger() or _starving():
		queue_redraw()


func _danger() -> bool:
	return _target >= 0.85


## Acından partlamağa bir metabolizm dövrü qalıb — HUD-un "ACSAN — QİDA YE!" anı.
func _starving() -> bool:
	return _balls <= Const.MIN_BALLS


func _draw() -> void:
	if _capacity < 0:
		return
	var at := Vector2(-WIDTH * 0.5, 0.0)
	# Dolu: zolaq titrəyir — köhnə künc zolağının eyni dili (iki qeyri-bərabər sinus).
	if _danger():
		at += Vector2(sin(_t * 35.0) * 1.6, sin(_t * 47.0) * 0.7)
	draw_style_box(_plate, Rect2(at - Vector2(BORDER, BORDER),
		Vector2(WIDTH, HEIGHT) + Vector2(BORDER, BORDER) * 2.0))
	draw_rect(Rect2(at, Vector2(WIDTH, HEIGHT)), Color(Palette.PANEL, 0.95))

	var w := WIDTH * _shown
	if w >= 1.0:
		# Rəng künc rəqəmi ilə eynidir: sarı az, yaşıl normal, qırmızı dolu.
		var col := Palette.fill_color(_target)
		# Ac: doluluq yanıb-sönür — boşalan zolaq tək rənglə "az" deyir, "təcili" demir.
		if _starving():
			col.a = 0.55 + 0.45 * (0.5 + 0.5 * sin(_t * 9.0))
		# StyleBoxFlat dairəvi ucu zolağın hündürlüyündən dar enində düzgün çəkmir.
		if w >= HEIGHT:
			if _fill.bg_color != col:
				_fill.bg_color = col
			draw_style_box(_fill, Rect2(at, Vector2(w, HEIGHT)))
		else:
			draw_rect(Rect2(at, Vector2(w, HEIGHT)), col)
		# Üst işıq zolağı — düymələrin "qalın, parlaq" dili ([ChunkyBox]).
		draw_rect(Rect2(at + Vector2(2.0, 1.5), Vector2(maxf(w - 4.0, 0.0), HEIGHT * 0.28)),
			Color(1.0, 1.0, 1.0, 0.28 * col.a))

	var step := 1 if _capacity <= TICK_EACH_MAX else TICK_GROUP
	var tick := Color(Palette.OUTLINE, 0.55)
	var n := step
	while n < _capacity:
		var x := at.x + WIDTH * float(n) / float(_capacity)
		draw_rect(Rect2(Vector2(x - 0.75, at.y), Vector2(1.5, HEIGHT)), tick)
		n += step
