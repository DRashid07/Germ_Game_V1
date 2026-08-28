class_name MenuV2
extends Control
## Baş menyu — yatay.
##
## Şəbəkə axını buradan başlayır və qısadır — io tipli oyunda növbə yoxdur:
##   düymə → serverə qoşul → dünyaya gir → arena
##
## "MƏŞQ" düyməsi şəbəkəyə heç toxunmur: eyni [World] və [Sim] kodu yerli işə
## düşür, botlarla. Server yatmış olsa da oyun oynanır.
##
## ── Düzülüş niyə belədir ─────────────────────────────────────────────────
##
## Köhnə menyu ([MainMenu]) şaquli FORMA idi: loqo, iki mətn qutusu, düymələr
## sütunu. Forma məlumat toplayır, oyun menyusu isə OYUNU SATIR — ikisi ayrı
## işdir. Düzülüş Brawl Stars ana ekranının məntiqindən götürülüb:
##
## **1. Mikrob səhnənin ortasındadır və CANLIDIR.** Oyunçu nə oynayacağını
## görür. [GermVisual] həqiqi sürətlə hərəkət etdirilir — kirpiklər döyünür,
## ayaqlar addımlayır, amöb sürünür. Oyunun içindəki eyni koddur, ona görə
## menyu HƏMİŞƏ oyunla eynidir və ayrıca "menyu şəkli" saxlanmır.
##
## **2. Növ seçimi KARTLARLA.** Köhnədə bir düymə növləri növbə ilə keçirdi:
## üç növü görmək üçün üç dəfə basmaq lazım idi. İndi üçü də yan-yanadır və
## hər kartda növün silueti var — seçim BİR toxunuşdur, fərq isə basmadan
## oxunur.
##
## **3. OYNA sağ aşağıdadır və ekranın ən böyük obyektidir.** Yatay tutulan
## telefonda sağ baş barmaq məhz oraya çatır. Ekranda ondan başqa DOLU laym
## ləkə yoxdur — bir toxunuşluq yol həmişə görünür.
##
## **4. Yuxarı zolaq yalnız OXUNUR.** Ad, server vəziyyəti, ayarlar. Vacib heç
## bir toxunuş yuxarıda deyil, çünki yatayda barmaq ora çatmır.
##
## **5. Server ünvanı görünmür.** Köhnə menyuda `wss://...` bütün eni tuturdu.
## Oyunçunun 99%-i ona heç vaxt toxunmur; texniki sahə əsas ekranda oyunun
## özündən çox yer tutmamalıdır. Ayarlar düyməsinin altındadır.
##
## **6. Mağaza, valyuta və naviqasiya lenti QƏSDƏN yoxdur.** Brawl Stars-da
## ekranın yarısı iqtisadiyyatdır; bizdə onun arxasında məhsul yoxdur. Boş
## düymə heç bir düymədən pisdir — basılır, heç nə olmur, etibar itir. Yerləri
## isə ayrılıb (bax `design/ART_BIBLE.md` § menyu), ona görə bölmələr gələndə
## mikrob, kartlar və OYNA yerini dəyişməyəcək.

const SETTINGS_PATH := "user://settings.cfg"
const ARENA_SCENE := "res://scenes/game/arena.tscn"

## Kənar boşluq. Yatayda kənarlar barmağın altında qalır, ona görə heç bir
## düymə ekranın lap kənarına yapışmır.
const PAD := 34.0
## Sağ sütunun eni və hündürlüyü (1280×720 bazasında ölçülüb).
const COL_W := 560.0
const COL_H := 486.0
const BTN_W := 380.0
const PLAY_H := 112.0
const CARD := Vector2(176.0, 96.0)

## Səhnədəki mikrobun neçə dəfə böyüdüldüyü. Oyunda radius 30 pikseldir —
## menyuda o, kartın yanında itərdi.
const GERM_ZOOM := 4.2
## Menyudakı mikrobun tutumu: içindəki topların sayı bundan asılıdır.
const GERM_CAPACITY := 14
const GERM_BALLS := 8
## Menyudakı mikrobun rəngi — oyunda rəngi server paylayır, menyuda sabitdir.
const MENU_COLOR := 0

## Giriş animasiyasının uzunluğu. 0.6 saniyə: görünəcək qədər uzun, gözləməyə
## məcbur etməyəcək qədər qısa. OYNA sonuncu düşür — göz ora yönəlsin deyə.
const INTRO_TIME := 0.6

## Serverin cavabını nə qədər gözləyirik (bax [method _probe_server]).
const PROBE_TIMEOUT := 8.0

var _germ: GermVisual
var _stage: Node2D
var _motes: WaterMotes
var _travelled := 0.0
## 0 → 1. Qabın halqaları bununla açılır (bax [method _draw]).
var _intro := 0.0

var _nick: LineEdit
var _addr: LineEdit
var _pill: Label
var _play: Button
var _species_title: Label
var _species_note: Label
var _species_super: Label
var _mode_card: Button
var _mode_name: Label
var _mode_note: Label
var _settings_panel: PanelContainer
var _cards: Array[Button] = []

## Qoşulma gedirmi. OYNA düyməsi bu vəziyyəti ÖZÜ göstərir — ayrıca status
## sətri və "LƏĞV ET" düyməsi yoxdur (köhnə menyuda hər ikisi vardı və menyunu
## bir düymə boyu uzadırdı).
var _joining := false
## Yoxlama növbəsinin nömrəsi — köhnə vaxt həddi yenisini pozmasın deyə
## (ünvan dəyişəndə yoxlama yenidən başlayır).
var _probe_token := 0

const _ICONS := {
	Const.Species.CILIATE: "res://assets/ui/species_ciliate.svg",
	Const.Species.HELIOZOAN: "res://assets/ui/species_heliozoan.svg",
	Const.Species.AMOEBA: "res://assets/ui/species_amoeba.svg",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	# Yuxarı zolaq ƏVVƏL qurulur: ad və ünvan sahələri ayarları oxumaq üçün
	# lazımdır, mikrob isə diskdən gələn NÖVLƏ yaradılmalıdır — əks halda
	# menyu bir kadr köhnə növü göstərib sonra dəyişərdi.
	_build_top_bar()
	_load_settings()
	_build_stage()
	_build_right_column()
	_build_hint()
	_refresh_species()
	_refresh_mode()

	Net.connected_to_server.connect(_on_connected)
	Net.connection_failed.connect(_on_connect_failed)
	Net.server_disconnected.connect(_on_disconnected)
	Net.world_joined.connect(_on_world_joined)
	Net.join_rejected.connect(_on_join_rejected)

	_probe_server()
	_play_intro()


func _process(delta: float) -> void:
	# Mikrob YERİNDƏ görünür, amma dünyada HƏRƏKƏT EDİR.
	#
	# Bu şərtdir: kirpiklərin döyüntüsü, ayaqların addımı və amöbin sürünmə
	# dövrü mikrobun HƏQİQİ sürətindən çıxır (bax [GermVisual]). Dayanan
	# mikroba `apply` versək, menyuda donmuş bir ləkə görünərdi.
	#
	# Həll: mikrob uzaqlaşır, saxlayan node isə eyni qədər geri sürüşür.
	# Nəticə ekranda sabitdir, animasiya isə tam sürətlə işləyir.
	_travelled += Const.germ_speed(GERM_CAPACITY) * delta
	var at := Vector2(_travelled, 0.0)
	_germ.apply(at, 0.0, GERM_BALLS, GERM_CAPACITY, false, true)
	_stage.position = _stage_centre() - at * _stage.scale.x

	if _motes != null:
		# Zərrəciklər QABIN üstündə qalır, mikrobla getmir: mikrob ekranda
		# yerindədir, ona görə onunla sürüşən zərrəciklər bir küncə yığılırdı.
		_motes.focus = _stage_centre()
		_motes.span = minf(size.x, size.y) * 0.95
	queue_redraw()


## Mikrobun ekrandakı yeri: solda, mərkəzdən bir az aşağıda.
##
## Tam mərkəzdə DEYİL — sağ tərəf növ kartlarına və OYNA düyməsinə lazımdır,
## mikrob isə onların altında qalmamalıdır. Brawl Stars-da da brawler mərkəzdən
## sola sürüşüb: sağ yarı həmişə hərəkət sahəsidir.
func _stage_centre() -> Vector2:
	return Vector2(size.x * 0.30, size.y * 0.52)


func _dish_radius() -> float:
	return minf(size.x, size.y) * 0.40


# ---------------------------------------------------------------- fon

func _build_background() -> void:
	# Fon və səhnə bu node-un ÖZ `_draw`-ında çəkilir, ayrıca `ColorRect` ilə
	# yox: `ColorRect` uşaqdır və uşaqlar valideynin çəkilişindən SONRA gəlir,
	# yəni zərrəcikləri örtürdü. Öz `_draw` isə hər şeydən əvvəldir.
	_motes = WaterMotes.new()
	add_child(_motes)

	# Bioluminessensiya — oyundakı ilə eyni ayar (bax [method Arena._build_glow]).
	# Menyu ilə oyun arasında görüntü kəsiyi olmamalıdır: eyni mikrob, eyni işıq.
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.62
	env.glow_intensity = 1.15
	env.glow_strength = 1.20
	env.glow_bloom = 0.14
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## Fon və mikrobun altındakı qab.
##
## Brawl Stars brawler-i podiumun üstündə göstərir: fiqurun yerə oturduğu hiss
## olmasa, o, boşluqda asılı qalır. Burada podium petri qabının özüdür — həm
## oyunun dünyasıdır, həm boş fonu doldurur.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BG_OUTER)
	var c := _stage_centre()
	var r := _dish_radius()
	draw_circle(c, r, Color(Palette.DISH, _intro))
	draw_arc(c, r, 0.0, TAU, 96, Color(Palette.DISH_EDGE, _intro), 6.0, true)
	# Məsafə halqaları — oyunun döşəməsindəki ilə eyni dil. Girişdə mərkəzdən
	# açılırlar: qab "qurulur", sonra mikrob görünür.
	for i in 2:
		var k := 0.42 + 0.26 * float(i)
		draw_arc(c, r * k * _intro, 0.0, TAU, 64, Color(Palette.GRID, 0.55 * _intro), 2.0, true)


func _build_stage() -> void:
	_stage = Node2D.new()
	_stage.scale = Vector2(GERM_ZOOM, GERM_ZOOM) \
		* (Const.BASE_RADIUS / Const.germ_radius(GERM_CAPACITY))
	add_child(_stage)

	_germ = GermVisual.new()
	# Ad BOŞDUR: növün adı ayrıca, öz tipoqrafiyası ilə yazılır — mikrobun
	# başının üstündəki kiçik yazı menyuda oxunmur.
	_germ.setup(MENU_COLOR, "", true, Net.species)
	_stage.add_child(_germ)
	_germ.apply(Vector2.ZERO, 0.0, GERM_BALLS, GERM_CAPACITY, false, true)


# ---------------------------------------------------------------- yuxarı zolaq

## Yuxarı zolaq: kim oynayır (sol) və server nə vəziyyətdədir (sağ).
func _build_top_bar() -> void:
	# ── oyunçu nişanı ──
	# Köhnə menyuda ad çılpaq mətn qutusu idi və ekranın ortasını tuturdu.
	# Burada o, kimliyə çevrilir: rəngli nişan + ad. Qutu görünmür, amma
	# toxunanda yazılır — ona görə "ayarlar" ekranı açmağa ehtiyac yoxdur.
	var chip := PanelContainer.new()
	chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	chip.offset_left = PAD
	chip.offset_top = 24.0
	chip.offset_right = PAD + 316.0
	chip.offset_bottom = 88.0
	chip.add_theme_stylebox_override("panel", _panel_style())
	add_child(chip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	chip.add_child(row)

	var av := TextureRect.new()
	av.texture = load("res://assets/ui/app_icon.svg")
	av.custom_minimum_size = Vector2(40, 40)
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(av)

	var who := VBoxContainer.new()
	who.add_theme_constant_override("separation", 0)
	who.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(who)

	_nick = LineEdit.new()
	_nick.text = Net.nickname
	_nick.max_length = 16
	_nick.custom_minimum_size = Vector2(210, 30)
	_nick.add_theme_font_size_override("font_size", 23)
	_nick.add_theme_color_override("font_color", Palette.TEXT)
	# Qutunun çərçivəsi silinir: ad METN kimi görünür, sahə kimi yox.
	# Fokus alanda alt xətt qalır — yazıla biləcəyi elə oradan bilinir.
	_nick.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_nick.add_theme_stylebox_override("focus", _underline_style())
	who.add_child(_nick)

	var tip := Hud._make_label(13, Palette.TEXT_MUTED)
	tip.text = "adı dəyişmək üçün toxun"
	who.add_child(tip)

	# ── server vəziyyəti ──
	# Menyu açılan kimi serverə qoşulma yoxlanılır (bax [method _probe_server]),
	# çünki Railway serveri yata bilir. Oyunçu OYNA basmazdan ƏVVƏL bilməlidir:
	# əks halda düyməni basır, gözləyir, xəta alır və oyunun sınıq olduğunu düşünür.
	_pill = Hud._make_label(16, Palette.TEXT_MUTED)
	_pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_pill.offset_top = 34.0
	_pill.offset_bottom = 78.0
	_pill.offset_right = -(PAD + 80.0)
	_pill.offset_left = -(PAD + 80.0 + 320.0)
	_pill.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_pill)

	var gear := Button.new()
	gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_top = 24.0
	gear.offset_bottom = 88.0
	gear.offset_right = -PAD
	gear.offset_left = -(PAD + 64.0)
	gear.icon = load("res://assets/ui/gear.svg")
	gear.expand_icon = true
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color"]:
		gear.add_theme_color_override(state, Palette.TEXT_MUTED)
	gear.add_theme_stylebox_override("normal", _panel_style())
	gear.add_theme_stylebox_override("hover", _panel_style(Palette.PANEL_BORDER))
	gear.add_theme_stylebox_override("pressed", _panel_style())
	gear.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	gear.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_settings_panel.visible = not _settings_panel.visible)
	add_child(gear)
	_squash(gear, Vector2(64, 64))

	_build_settings_panel()


## Server ünvanı burada yaşayır — əsas ekranda yox.
func _build_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_settings_panel.offset_top = 100.0
	_settings_panel.offset_right = -PAD
	_settings_panel.offset_left = -(PAD + 460.0)
	_settings_panel.add_theme_stylebox_override("panel", _panel_style())
	_settings_panel.visible = false
	add_child(_settings_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_settings_panel.add_child(box)

	var caption := Hud._make_label(18, Palette.TEXT_MUTED)
	caption.text = "Server ünvanı"
	box.add_child(caption)

	_addr = LineEdit.new()
	_addr.text = Const.DEFAULT_SERVER
	_addr.custom_minimum_size = Vector2(420, 48)
	_addr.add_theme_font_size_override("font_size", 18)
	_addr.add_theme_color_override("font_color", Palette.TEXT)
	# Ünvan dəyişəndə köhnə qoşulma artıq etibarsızdır — yenidən yoxlanılır.
	_addr.text_submitted.connect(func(_t: String) -> void:
		Net.disconnect_from_server()
		_probe_server())
	box.add_child(_addr)


# ---------------------------------------------------------------- sağ sütun

## Sağ sütun: növ seçimi, rejim lövhəsi, OYNA.
##
## Aşağıya bağlanıb, yuxarıya yox: OYNA baş barmağın çatdığı yerdə qalmalıdır,
## ekran nə qədər hündür olsa da.
func _build_right_column() -> void:
	var col := Control.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	col.offset_right = -PAD
	col.offset_left = -(PAD + COL_W)
	col.offset_bottom = -PAD
	col.offset_top = -(PAD + COL_H)
	add_child(col)

	_species_title = Hud._make_label(40, Palette.TEXT)
	_species_title.theme_type_variation = "Heading"
	_species_title.position = Vector2(0, 0)
	_species_title.size = Vector2(COL_W, 42)
	col.add_child(_species_title)

	## Növün NƏ ETDİYİ. Seçim oyuna təsir etmir (sürət, ölçü, ölüm qaydaları
	## eynidir), ona görə mətn üstünlük vəd etmir — yalnız hərəkəti təsvir edir.
	# Superin adı — növün adının altında, oyunçunun rəngində.
	#
	# Seçim artıq zövq məsələsi deyil: hər növün öz superi var və oyunçu nə
	# seçdiyini menyuda BİLMƏLİDİR. Kartın üstündə yer yoxdur, ona görə ad
	# seçilən növün başlığının altındadır.
	_species_super = Hud._make_label(17, Palette.GERM_COLORS[1])
	_species_super.position = Vector2(0, 42)
	_species_super.size = Vector2(COL_W, 24)
	col.add_child(_species_super)

	_species_note = Hud._make_label(18, Palette.TEXT_MUTED)
	_species_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_species_note.position = Vector2(0, 66)
	_species_note.size = Vector2(COL_W, 56)
	col.add_child(_species_note)

	# Kartlar KONTEYNERSİZ yerləşdirilir. Səbəb: seçilmiş kart 4 piksel
	# QALXIR (bax [method _refresh_species]), konteyner isə uşağın mövqeyini
	# hər layout-da geri qaytarardı — qalxma heç vaxt görünməzdi.
	const GAP := 14.0
	var row_w := CARD.x * float(Const.SPECIES_COUNT) + GAP * float(Const.SPECIES_COUNT - 1)
	for i in Const.SPECIES_COUNT:
		var kind := Const.species_from(i)
		var card := _make_card(kind)
		card.position = Vector2((COL_W - row_w) * 0.5 + float(i) * (CARD.x + GAP), 132.0)
		card.size = CARD
		card.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			Net.species = kind
			_save_settings()
			_swap_germ()
			_refresh_species())
		col.add_child(card)
		_cards.append(card)

	# Rejim lövhəsi — OYNA düyməsinin üstündə.
	#
	# Brawl Stars-da oyun rejimi düymənin üstündədir: oyunçu NƏYƏ girdiyini
	# basmadan əvvəl bilir. Burada rejim birdir, amma sual eynidir — dünyada
	# neçə nəfər var, nə qədər davam edir.
	# REJİM SEÇİCİSİ — OYNA düyməsinin üstündə.
	#
	# Brawl Stars-da hadisə kartı məhz oradadır: oyunçu NƏYƏ girdiyini basmadan
	# əvvəl bilir. Yeri əvvəldən bu iş üçün saxlanmışdı, indi doldurulur.
	#
	# Kart basılanda növbəti rejimə keçir. İki rejim var, ona görə növbə ilə
	# keçmək bəsdir — üçüncüsü gələndə sürüşən lentə çevriləcək.
	_mode_card = Button.new()
	_mode_card.position = Vector2(0, 246)
	_mode_card.size = Vector2(COL_W, 52)
	_mode_card.add_theme_stylebox_override("normal", _ghost_style(Palette.PANEL_BORDER))
	_mode_card.add_theme_stylebox_override("hover", _ghost_style(Palette.DISH_EDGE))
	_mode_card.add_theme_stylebox_override("pressed", _ghost_style(Palette.PANEL_BORDER))
	_mode_card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_mode_card.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		Net.mode = Const.Mode.ENDLESS if Net.mode == Const.Mode.SOLO else Const.Mode.SOLO
		_save_settings()
		_refresh_mode())
	col.add_child(_mode_card)
	_squash(_mode_card, Vector2(COL_W, 52))

	_mode_name = Hud._make_label(24, Palette.GERM_COLORS[1])
	_mode_name.theme_type_variation = "Heading"
	_mode_name.position = Vector2(14, 2)
	_mode_name.size = Vector2(COL_W - 28, 28)
	_mode_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(_mode_name)

	_mode_note = Hud._make_label(14, Palette.TEXT_MUTED)
	_mode_note.position = Vector2(14, 28)
	_mode_note.size = Vector2(COL_W - 96, 20)
	_mode_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(_mode_note)

	# "DƏYİŞ ›" — kartın BASILA BİLDİYİNİ bildirən yeganə əlamət.
	#
	# Onsuz kart sadəcə lövhə kimi oxunur: növ kartlarının seçilmiş halı var,
	# bunun isə yoxdur, ona görə oyunçu ikinci rejimin varlığını heç bilməz.
	# Brawl Stars-da hadisə kartının yanındakı ox eyni işi görür.
	var swap := Hud._make_label(14, Palette.TEXT_MUTED)
	swap.text = "DƏYİŞ ›"
	swap.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	swap.position = Vector2(COL_W - 96, 16)
	swap.size = Vector2(82, 20)
	swap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(swap)

	# OYNA — ekranın ən böyük obyekti və yeganə DOLU laym ləkəsi.
	_play = Button.new()
	_play.text = "OYNA"
	_play.position = Vector2(COL_W - BTN_W, 310)
	_play.size = Vector2(BTN_W, PLAY_H)
	_play.add_theme_font_size_override("font_size", 46)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_play.add_theme_color_override(state, Color("06140A"))
	_play.add_theme_stylebox_override("normal", _play_style(false))
	_play.add_theme_stylebox_override("hover", _play_style(false))
	_play.add_theme_stylebox_override("pressed", _play_style(true))
	_play.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_play.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_on_play())
	col.add_child(_play)
	_squash(_play, Vector2(BTN_W, PLAY_H))

	var practice := Button.new()
	practice.text = "MƏŞQ (offline)"
	practice.position = Vector2(COL_W - BTN_W, 434)
	practice.size = Vector2(BTN_W, 52)
	practice.add_theme_font_size_override("font_size", 21)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		practice.add_theme_color_override(state, Palette.TEXT_MUTED)
	practice.add_theme_stylebox_override("normal", _ghost_style(Palette.PANEL_BORDER))
	practice.add_theme_stylebox_override("hover", _ghost_style(Palette.DISH_EDGE))
	practice.add_theme_stylebox_override("pressed", _ghost_style(Palette.PANEL_BORDER))
	practice.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	practice.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_practice())
	col.add_child(practice)
	_squash(practice, Vector2(BTN_W, 52))


## Qaydanın iki sətri — sol aşağıda, mikrobun altında.
##
## Brawl Stars-da orada naviqasiya lenti durur (Mağaza, Brawler-lər, Xəbərlər).
## Bizdə o bölmələr yoxdur, ona görə yer oyunun QAYDASINA verilir: oyun tanış
## deyil və menyu onu bir dəfə izah etməlidir.
func _build_hint() -> void:
	var hint := Hud._make_label(19, Palette.TEXT_MUTED)
	hint.text = "Qida ye — böyü.  Rəqibə top at — onu doldur.\n" \
		+ "Tutumu aşan mikrob PARTLAYIR."
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hint.offset_left = PAD
	hint.offset_bottom = -PAD
	hint.offset_top = -(PAD + 72.0)
	hint.offset_right = PAD + 620.0
	add_child(hint)


## Giriş animasiyası.
##
## Ardıcıllıq təsadüfi deyil: əvvəl QAB qurulur, sonra MİKROB görünür, sonra
## SEÇİM, ən sonda OYNA sıçrayır. Göz sonuncu hərəkətə yönəlir, ona görə
## sonuncu hərəkət düz basılası düymədə olmalıdır.
func _play_intro() -> void:
	var groups: Array[Control] = []
	for child in get_children():
		if child is Control:
			groups.append(child as Control)
	for g in groups:
		g.modulate.a = 0.0

	# Qab öz `_draw`-ındadır, mikrob isə ayrıca node — ikisi ayrı sönür.
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _intro = v, 0.0, 1.0, INTRO_TIME * 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_stage.modulate.a = 0.0
	var germ_in := create_tween()
	germ_in.tween_interval(INTRO_TIME * 0.28)
	germ_in.tween_property(_stage, "modulate:a", 1.0, 0.3)

	var step := INTRO_TIME / maxf(float(groups.size()), 1.0)
	for i in groups.size():
		var g := groups[i]
		var fade := create_tween()
		fade.tween_interval(step * float(i) * 0.55)
		fade.tween_property(g, "modulate:a", 1.0, 0.22)

	# OYNA sonuncu və yeganə SIÇRAYAN elementdir.
	_play.scale = Vector2(0.86, 0.86)
	var pop := create_tween()
	pop.tween_interval(INTRO_TIME * 0.72)
	pop.tween_property(_play, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- növ

## Növ dəyişəndə mikrob YENİDƏN qurulur.
##
## [GermVisual] növü qurulanda oxuyur (ayaqların sayı, kirpiklərin düzümü və
## sürünmə vəziyyəti hamısı [method GermVisual.setup]-da hazırlanır), ona görə
## növü sonradan dəyişmək yarımçıq vəziyyət qoyardı: köhnə ayaqlar yeni gövdədə.
func _swap_germ() -> void:
	_stage.remove_child(_germ)
	_germ.queue_free()
	_germ = GermVisual.new()
	_germ.setup(MENU_COLOR, "", true, Net.species)
	_stage.add_child(_germ)
	_germ.apply(Vector2(_travelled, 0.0), 0.0, GERM_BALLS, GERM_CAPACITY, false, true)


## Seçilmiş rejimin adı və bir sətirlik qaydası.
##
## Bir sətir MƏCBURİDİR: oyunçu nəyə girdiyini basmadan əvvəl bilməlidir.
## Menyunun onsuz da yazılmış qaydasıdır (bax sinif şərhi, 3-cü bənd).
func _refresh_mode() -> void:
	if Net.mode == Const.Mode.SOLO:
		_mode_name.text = "TƏK QALAN"
		_mode_name.add_theme_color_override("font_color", Palette.WARNING)
		_mode_note.text = "10 mikrob · qab quruyur · sona qalan udur"
	else:
		_mode_name.text = "SONSUZ ARENA"
		_mode_name.add_theme_color_override("font_color", Palette.GERM_COLORS[1])
		_mode_note.text = "matç yoxdur · girdin, oynadın · gözləmə yoxdur"


func _refresh_species() -> void:
	_species_title.text = _species_name(Net.species)
	_species_super.text = "SUPER: " + _species_super_name(Net.species)
	_species_note.text = _species_note_for(Net.species)
	for i in _cards.size():
		var on := Const.species_from(i) == Net.species
		var card := _cards[i]
		for state in ["normal", "hover", "pressed"]:
			card.add_theme_stylebox_override(state, _card_style(on))
		var icon := card.get_child(0) as TextureRect
		icon.modulate = Palette.GERM_COLORS[0] if on else Color(0.45, 0.55, 0.55)
		var name_lbl := card.get_child(1) as Label
		name_lbl.add_theme_color_override("font_color",
			Palette.TEXT if on else Color(0.62, 0.72, 0.71))
		# Seçilmiş kart QALXIR. Yalnız rəng fərqi kifayət etmirdi: üç kart
		# yan-yana olanda göz hansının aktiv olduğunu formadan daha tez tutur.
		card.position.y = 128.0 if on else 132.0


static func _species_name(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "AYAQLI"
		Const.Species.AMOEBA:
			return "AMÖB"
		_:
			return "KİRPİKLİ"


## Növün superinin adı.
static func _species_super_name(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "AKSOPODİYA TORU"
		Const.Species.AMOEBA:
			return "SİSTLƏŞMƏ"
		_:
			return "TRİXOSİST"


## Növün NƏ ETDİYİ — bir üstünlük, bir qiymət.
##
## Hər sətirdə ikisi də var və bu, qəsdəndir: menyu "güclü olanı seç" yox,
## "necə oynamaq istəyirsən" sualını verməlidir. Növlərin DÖYÜŞ riyaziyyatı
## eynidir — atəş dövrü, topun qiyməti, tutum artımı (bax [constant
## Const.SPECIES_THRUST] və `sim_test`-dəki yoxlama). Fərq yalnız mühitlə
## münasibətdə və superdədir.
static func _species_note_for(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "Qidanı özünə çəkir, rəqibi yavaşladır.\nAxına dirənir, amma ən yavaş növdür."
		Const.Species.AMOEBA:
			return "Qabığa çevrilir: top səkir, aclıq dayanır.\nDar yerdən keçir, amma tərpənə bilmir."
		_:
			return "Gələn topları partladıb qaçır.\nƏn cəld, amma axın onu aparır."


# ---------------------------------------------------------------- şəbəkə

## Menyu açılan kimi serverin ayaqda olub-olmadığı yoxlanılır.
##
## Səbəb praktikdir: server Railway-də yaşayır və işsiz qalanda YATIR. Oyunçu
## OYNA basıb gözləmək əvəzinə vəziyyəti yuxarı sağda oxuyur. Qoşulma boşuna
## getmir — OYNA basılanda hazır bağlantı işlədilir və dünyaya giriş ani olur.
func _probe_server() -> void:
	if Net.is_connected_to_server():
		_set_pill("ONLAYN", Palette.SAFE)
		return
	_set_pill("server yoxlanılır…", Palette.TEXT_MUTED)
	var parts := Net.parse_address(_addr.text)
	if Net.join_server(parts[0], parts[1]) != OK:
		_set_pill("ünvan səhvdir", Palette.WARNING)
		return

	# Vaxt həddi. Qoşulma HƏMİŞƏ "alınmadı" ilə bitmir: server yatmış olsa,
	# ünvan səssiz düşsə və ya paketlər yolda itsə, `connection_failed`
	# ümumiyyətlə gəlmir və yazı əbədi "yoxlanılır…" qalır. Oyunçu isə
	# gözləməli olduğunu, yoxsa MƏŞQ oynamalı olduğunu bilmir.
	_probe_token += 1
	var token := _probe_token
	get_tree().create_timer(PROBE_TIMEOUT).timeout.connect(func() -> void:
		if token != _probe_token or _joining or Net.is_connected_to_server():
			return
		_set_pill("server cavab vermir — MƏŞQ oyna", Palette.WARNING))


func _on_play() -> void:
	# Basılan düymə qoşulmanı həm başladır, həm ləğv edir — vəziyyəti O
	# göstərdiyinə görə ləğv də ONUN üstündədir.
	if _joining:
		Net.disconnect_from_server()
		_set_joining(false)
		_set_pill("ləğv edildi", Palette.TEXT_MUTED)
		return

	Net.nickname = _clean_nick()
	_save_settings()
	_set_joining(true)

	if Net.is_connected_to_server():
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_set_pill("dünyaya girilir…", Palette.TEXT_MUTED)
		return

	_set_pill("serverə qoşulur…", Palette.TEXT_MUTED)
	var parts := Net.parse_address(_addr.text)
	if Net.join_server(parts[0], parts[1]) != OK:
		_set_joining(false)
		_set_pill("ünvan səhvdir", Palette.WARNING)


func _practice() -> void:
	Net.nickname = _clean_nick()
	_save_settings()
	# Yoxlama üçün açılmış bağlantı məşqdə lazım deyil — açıq qalsa server
	# oyunçunu onlayn sayardı.
	Net.disconnect_from_server()
	var arena: Arena = load(ARENA_SCENE).instantiate()
	arena.configure_practice()
	_swap_to(arena)


func _on_connected() -> void:
	if _joining:
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_set_pill("dünyaya girilir…", Palette.TEXT_MUTED)
	else:
		_set_pill("ONLAYN", Palette.SAFE)


func _on_connect_failed() -> void:
	_set_joining(false)
	_set_pill("server yatıb — MƏŞQ oyna", Palette.WARNING)


func _on_disconnected() -> void:
	if _joining:
		_set_joining(false)
		_set_pill("server bağlantısı kəsildi", Palette.WARNING)


func _on_join_rejected(reason: String) -> void:
	_set_joining(false)
	_set_pill(reason, Palette.WARNING)


func _on_world_joined(info: Dictionary) -> void:
	var arena: Arena = load(ARENA_SCENE).instantiate()
	arena.configure_online(info)
	_swap_to(arena)


func _swap_to(scene: Node) -> void:
	# configure_* mütləq ağaca əlavə etməzdən ƏVVƏL çağırılmalıdır:
	# arena `_ready`-də həmin məlumatla qurulur.
	var tree := get_tree()
	tree.root.add_child(scene)
	tree.current_scene = scene
	queue_free()


func _set_joining(busy: bool) -> void:
	_joining = busy
	_play.text = "QOŞULUR…  ✕" if busy else "OYNA"
	_play.add_theme_font_size_override("font_size", 30 if busy else 46)


func _set_pill(text: String, color: Color) -> void:
	_pill.text = text
	_pill.add_theme_color_override("font_color", color)


# ---------------------------------------------------------------- ayarlar

func _clean_nick() -> String:
	var s := _nick.text.strip_edges()
	return "Mikrob" if s.is_empty() else s.substr(0, 16)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	_nick.text = str(cfg.get_value("player", "nickname", _nick.text))
	# Ayar faylı əl ilə redaktə oluna bilər — dəyər çərçivəyə salınır.
	Net.species = Const.species_from(int(cfg.get_value("player", "species", 0)))
	Net.mode = Const.mode_from(int(cfg.get_value("player", "mode", 0)))
	_addr.text = str(cfg.get_value("net", "address", _addr.text))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "nickname", _clean_nick())
	cfg.set_value("player", "species", int(Net.species))
	cfg.set_value("player", "mode", int(Net.mode))
	cfg.set_value("net", "address", _addr.text.strip_edges())
	cfg.save(SETTINGS_PATH)


# ---------------------------------------------------------------- parçalar

## Növ kartı: siluet + ad.
##
## Siluet ona görədir ki, fərq BASMADAN oxunsun — köhnə menyuda növü görmək
## üçün düyməni basıb mikrobun dəyişməsinə baxmaq lazım idi.
func _make_card(kind: Const.Species) -> Button:
	# Düymənin ÖZ mətni işlədilmir: siluet yuxarıda, ad aşağıda olmalıdır,
	# Button isə ikisini yalnız yan-yana düzə bilir. Ona görə hər ikisi ayrıca
	# uşaqdır və əl ilə yerləşdirilir (bax [method _refresh_species] — rəngi
	# də oradan verilir).
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var icon := TextureRect.new()
	icon.texture = load(_ICONS[kind])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2((CARD.x - 36.0) * 0.5, 14.0)
	icon.size = Vector2(36, 36)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var name_lbl := Hud._make_label(19, Palette.TEXT)
	name_lbl.text = _species_name(kind)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.position = Vector2(0, 56)
	name_lbl.size = Vector2(CARD.x, 26)
	b.add_child(name_lbl)

	_squash(b, CARD)
	return b


## Basılanda əzilmə — Brawl Stars-ın imzası, bizdə də eynidir.
## Toxunuşun cavabsız qalmadığı məhz bundan bilinir.
static func _squash(b: Button, box: Vector2) -> void:
	b.pivot_offset = box * 0.5
	b.button_down.connect(func() -> void:
		var t := b.create_tween()
		t.tween_property(b, "scale", Vector2(0.955, 0.94), 0.06))
	b.button_up.connect(func() -> void:
		var t := b.create_tween()
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "scale", Vector2.ONE, 0.14))


static func _panel_style(border := Palette.PANEL_BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.PANEL, 0.8)
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(10)
	return sb


static func _underline_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Palette.GERM_COLORS[1]
	sb.border_width_bottom = 2
	return sb


## OYNA düyməsi. Konturlu SVG çərçivə DEYİL, dolu ləkədir: ekranda ondan başqa
## dolu laym sahə yoxdur, ona görə göz onu bir anda tapır.
##
## Aşağıdakı tünd kənar — "dodaq" — düymənin qalınlığını verir. Brawl Stars
## bunu qara konturla edir; bizim dil yumşaq və işıqlıdır, ona görə kontur
## əvəzinə əsas rəngin tünd variantı işlədilir.
static func _play_style(pressed: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.GERM_COLORS[0]
	sb.set_corner_radius_all(20)
	sb.border_color = Palette.GERM_COLORS[0].lerp(Palette.OUTLINE, 0.55)
	sb.border_width_bottom = 3 if pressed else 8
	# Basılanda düymə dodağın içinə oturur — məzmun aşağı sürüşür.
	sb.content_margin_top = 5.0 if pressed else 0.0
	return sb


static func _ghost_style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	return sb


static func _card_style(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.PANEL, 0.85)
	sb.border_color = Palette.GERM_COLORS[0] if selected else Palette.PANEL_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	if selected:
		sb.border_width_bottom = 6
		sb.shadow_color = Color(Palette.GERM_COLORS[0], 0.28)
		sb.shadow_size = 10
	return sb
