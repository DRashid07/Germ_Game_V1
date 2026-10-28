class_name MutationCards
extends Control
## Mutasiya seçiminin kartları (eksperimental profil, design/MODES.md §19).
##
## Oyun dayanmır: kartlar sol yuxarıda, top sayının altında yığcam sütundur — sol altdakı
## hərəkət çubuğu, sağ altdakı atəş/super düymələri, sağ yuxarıdakı cədvəl və xəritə, ortadakı
## oyun mesajları ("GİZLƏNDİN" və s.) açıq qalır. Əvvəl yuxarı ortada sıra idi və mərkəzi
## mesajın üstünə düşürdü (ekran görüntüsündə görüldü). Hər kart üstünlüyü və qiyməti BİR
## yerdə yazır. Seçim məcburi deyil, avtomatik də edilmir: kartları bağlamaq olar və
## göstəricidən ("MUTASİYA · 1") yenidən açılır. Klaviaturada 1/2/3.
##
## Seçim edilən kart serverin təsdiqini gözləyir ("SERVER GÖZLƏNİLİR…"); təsdiq mikrobun
## bayrağında gəlir ([Arena] [method set_state]-i çağırır). Rədd olunsa kartlar yenə açılır.

signal chosen(m: int)

const LEFT := 16.0
const CARD_W := 250.0
const CARD_H := 80.0
const GAP := 8.0
## Göstəricinin yuxarısı — top sayı və səviyyə yazısının altı.
const TOP := 86.0
const IND_H := 38.0

## Mutasiyanın adı, üstünlüyü və qiyməti ([enum Const.Mut] sırası ilə). İşarə ("+", "−")
## kartın özündədir, mətndə yox.
const TEXT := [
	["UZUN ÇIXINTI", "atəş məsafəsi 20%", "top sürəti 15%"],
	["İMPULS QAMÇISI", "atəşin təpməsi 30%", "sürüşür: əyləc 20%"],
	["YAPIŞQAN AYAQLAR", "axın 25% az aparır", "öz sürəti 5%"],
]

var _indicator: Button
var _row: Control
var _cards: Array[Button] = []
## Kartda göstərilən mutasiyalar (sıra kartların sırasıdır).
var _offers: Array[int] = []
var _pending := 0
var _mine := 0
var _waiting := -1
var _open := false
var _note: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_indicator = Button.new()
	_indicator.position = Vector2(LEFT, TOP)
	_indicator.size = Vector2(CARD_W, IND_H)
	_indicator.add_theme_font_size_override("font_size", 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_indicator.add_theme_color_override(state, Palette.TEXT)
	_indicator.focus_mode = Control.FOCUS_NONE
	ChunkyBox.stroke(_indicator, 4, true)
	ChunkyBox.apply(_indicator, Palette.MENU_PANEL)
	_indicator.pressed.connect(toggle)
	_indicator.visible = false
	add_child(_indicator)

	_row = Control.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.visible = false
	add_child(_row)
	for i in Const.MUT_COUNT:
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.clip_text = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 16)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
				"font_disabled_color"]:
			b.add_theme_color_override(state, Palette.TEXT)
		ChunkyBox.stroke(b, 4, true)
		ChunkyBox.apply(b, Palette.MENU_PANEL)
		b.pressed.connect(_press.bind(i))
		_row.add_child(b)
		_cards.append(b)

	_note = Hud._make_label(16, Palette.TEXT_MUTED)
	_note.position = Vector2(LEFT, TOP + IND_H + 4.0)
	_note.size = Vector2(CARD_W + 120.0, 24.0)
	_note.visible = false
	add_child(_note)


## Vəziyyət [Arena]-dan: [param pending] — açılıb seçilməmiş seçim sayı, [param mine] —
## aktiv mutasiyalar, [param waiting] — təsdiq gözləyən seçim (-1 yoxdur).
## Yeni seçim açılanda kartlar özü açılır (oyunçunu məcbur etmir — bağlamaq olar).
func set_state(pending: int, mine: int, waiting: int) -> void:
	if pending == _pending and mine == _mine and waiting == _waiting:
		return
	var grew := pending > _pending
	var was := _waiting
	var confirmed := was >= 0 and waiting < 0 and Const.has_mut(mine, was)
	_pending = pending
	_mine = mine
	_waiting = waiting
	_offers.clear()
	for m in Const.MUT_COUNT:
		if not Const.has_mut(mine, m):
			_offers.append(m)
	if pending <= 0:
		_open = false
	elif grew:
		_open = true
	if confirmed:
		_flash("%s aktivdir" % TEXT[was][0])
	_refresh()


## Server seçimi rədd etdi (və ya cavab gəlmədi) — kartlar yenidən seçilə bilir.
func reject() -> void:
	_waiting = -1
	_flash("Seçim qəbul olunmadı — yenidən seç")
	_refresh()


func is_open() -> bool:
	return _open and _pending > 0


func toggle() -> void:
	if _pending <= 0:
		return
	_open = not _open
	_refresh()


## Klaviatura: 1/2/3 açıq kartlardan birini seçir.
func key(n: int) -> void:
	if is_open() and n >= 0 and n < _offers.size():
		_press(n)


func _press(i: int) -> void:
	if _waiting >= 0 or i >= _offers.size() or _pending <= 0:
		return
	Sfx.play("ui_click")
	_waiting = _offers[i]
	_refresh()
	chosen.emit(_offers[i])


func _refresh() -> void:
	_indicator.visible = _pending > 0
	_indicator.text = ("MUTASİYA · %d" % _pending) + (" — GİZLƏT" if _open else " — AÇ")
	_row.visible = is_open()
	var n := _offers.size()
	# Açıq kartlar göstəricinin altındadır; qeyd ("... aktivdir") kartlar bağlıdırsa göstəricinin,
	# açıqdırsa kartların altına düşür.
	_note.position.y = TOP + IND_H + 4.0 + (float(n) * (CARD_H + GAP) if is_open() else 0.0)
	for i in _cards.size():
		var b := _cards[i]
		b.visible = i < n
		if i >= n:
			continue
		var m := _offers[i]
		b.position = Vector2(LEFT, TOP + IND_H + GAP + float(i) * (CARD_H + GAP))
		b.size = Vector2(CARD_W, CARD_H)
		var t: Array = TEXT[m]
		if _waiting == m:
			b.text = "%d  %s\nSERVER GÖZLƏNİLİR…" % [i + 1, t[0]]
		else:
			b.text = "%d  %s\n+ %s\n− %s" % [i + 1, t[0], t[1], t[2]]
		b.disabled = _waiting >= 0 and _waiting != m
		ChunkyBox.apply(b, Palette.MENU_BLUE if _waiting == m else Palette.MENU_PANEL)


func _flash(text: String) -> void:
	_note.text = text
	_note.visible = true
	_note.modulate.a = 1.0
	var tw := create_tween() if is_inside_tree() else null
	if tw != null:
		tw.tween_interval(1.6)
		tw.tween_property(_note, "modulate:a", 0.0, 0.5)
