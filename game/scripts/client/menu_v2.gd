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
## OYNA — aşağı-mərkəzdə, ekranın lövbəri.
const BTN_W := 340.0
const PLAY_H := 104.0
## Rejim kartı — OYNA-nın sağında, eyni hündürlükdə.
const MODE_W := 300.0
## Mikrobun altındakı ad lövhəsi.
const PLATE := Vector2(330.0, 76.0)
## Sol lentin düyməsi (Brawl Stars-da Brawlers/Shop/Social).
const RAIL := Vector2(126.0, 116.0)
## Vərəqdəki böyük növ kartı və rejim sətri.
const CARD_BIG := Vector2(300.0, 440.0)
const GRID_GAP := 30.0
const ROW_W := 700.0
const ROW_H := 104.0
const ROW_GAP := 14.0
## Rejimlərin rəng nişanları — [constant Palette.GERM_COLORS] indeksləri.
const MODE_TINT := [1, 3, 7, 4]
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
var _mode_card: Button
var _mode_name: Label
var _mode_note: Label
var _settings_panel: PanelContainer
var _quality_btn: Button
var _cards: Array[Button] = []
var _mode_rows: Array[Button] = []
## Mikrobun altındakı ad lövhəsi — kimlik obyektə bağlıdır, ayrı sütuna yox.
var _plate_name: Label
var _plate_super: Label
## Tam ekran vərəq: MİKROBLAR və REJİMLƏR eyni çərçivəni paylaşır.
var _sheet: Control
var _sheet_title: Label
var _sheet_species: Control
var _sheet_modes: Control

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
	_build_home()
	_build_sheet()
	_refresh_species()
	_refresh_mode()
	_refresh_quality()

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
	# Ad lövhəsi podiumun ALT kənarına oturur; podium ekran ölçüsündən
	# asılıdır, ona görə yeri hər kadr yenilənir.
	var plate := get_node_or_null("Plate") as Control
	if plate != null:
		plate.position = Vector2(_stage_centre().x - PLATE.x * 0.5,
			_stage_centre().y + _dish_radius() - 142.0)

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
## Podium MƏRKƏZDƏDİR.
##
## Brawl Stars-da fiqur ekranın ortasındadır və bütün idarələr onun
## ÇEVRƏSİNDƏ halqa qurur: yuxarı-sol kimlik, yuxarı-sağ sistem,
## aşağı-mərkəz PLAY, aşağı-sağ rejim, yan lentlər bölmələr.
##
## Əvvəl mikrob solda, mətn sütunu sağda idi — o düzüm fiquru səhnənin
## sahibi yox, sadəcə sol yarının bəzəyi edirdi.
func _stage_centre() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.44)


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
	#
	# Keyfiyyət ayarı da EYNİ olmalıdır və bu, sonradan düzəldilib: arena
	# `Net.quality`-ni oxuyurdu, menyu isə yox — nəticədə "QRAFİKA: AŞAĞI"
	# düyməsi elə öz ekranında heç nə dəyişmirdi. Oyunçu basır, ekran eyni
	# qalır, deməli düymə ölü sayılır. Üstəlik ən bahalı ekran (bloom-lu menyu)
	# zəif telefonda bahalı qalırdı.
	_apply_quality()
	if Net.quality == Const.Quality.LOW:
		return

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
	_sink_germ()
	_stage.add_child(_germ)
	_germ.apply(Vector2.ZERO, 0.0, GERM_BALLS, GERM_CAPACITY, false, true)


## Mikrobu İNTERFEYSİN ALTINA salır.
##
## [method GermVisual.setup] özünə `z_index = 2` yazır ("öz mikrobun həmişə
## başqalarının üstündədir") — oyunda doğrudur, menyuda isə yox: buradakı
## panellər adi Control-lardır, yəni sıfırdadır. Nəticədə ayaqlının
## aksopodiyaları ad lövhəsindəki `SUPER · AKSOPODİYA TORU` yazısını, ayaqların
## uclarındakı toplar isə ayarlar panelinin içini örtürdü.
##
## Sıfırda sıra AĞACDAN çıxır: səhnə panellərdən əvvəl əlavə olunur, deməli
## onların altında qalır. Menyuda mikrob eksponatdır, idarə deyil.
##
## Ayrıca funksiyadır, çünki `setup` növ dəyişəndə TƏKRAR çağırılır
## ([method _swap_germ]) və hər dəfə z-i yenidən yazır.
func _sink_germ() -> void:
	_germ.z_index = 0


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

	# Alt yazı ("adı dəyişmək üçün toxun") SİLİNİB.
	#
	# Brawl Stars-ın yuxarı zolağında heç bir izahedici cümlə yoxdur. Ad
	# fokus alanda alt xətt çıxır (bax `_underline_style`) — yazıla biləcəyi
	# elə oradan bilinir, hər açılışda təkrar deməyə ehtiyac yoxdur.

	# ── server vəziyyəti ──
	# Menyu açılan kimi serverə qoşulma yoxlanılır (bax [method _probe_server]),
	# çünki Railway serveri yata bilir. Oyunçu OYNA basmazdan ƏVVƏL bilməlidir:
	# əks halda düyməni basır, gözləyir, xəta alır və oyunun sınıq olduğunu düşünür.
	_pill = Hud._make_label(16, Palette.TEXT_MUTED)
	_pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_pill.offset_top = 34.0
	_pill.offset_bottom = 78.0
	# Dişlinin solunda bitir — sabit ofsetlə qoyulsaydı, uzun mətn düymənin
	# altına girərdi.
	_pill.offset_right = -(PAD + 78.0)
	_pill.offset_left = -(PAD + 78.0 + 320.0)
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

	# QRAFİKA — telefonda ən böyük yük glow və HDR kadr buferidir, ona görə
	# seçim ayarların ƏN ÜSTÜNDƏDİR: kəsmə yaşayan oyunçu onu axtarmamalıdır.
	var gcap := Hud._make_label(18, Palette.TEXT_MUTED)
	gcap.text = "Qrafika"
	box.add_child(gcap)

	_quality_btn = Button.new()
	_quality_btn.custom_minimum_size = Vector2(420, 48)
	_quality_btn.add_theme_stylebox_override("normal", _ghost_style(Palette.PANEL_BORDER))
	_quality_btn.add_theme_stylebox_override("hover", _ghost_style(Palette.DISH_EDGE))
	_quality_btn.add_theme_stylebox_override("pressed", _ghost_style(Palette.PANEL_BORDER))
	_quality_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_quality_btn.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		Net.quality = Const.quality_from(1 - int(Net.quality))
		_save_settings()
		_refresh_quality())
	box.add_child(_quality_btn)

	var ghint := Hud._make_label(14, Palette.TEXT_MUTED)
	ghint.text = "Aşağı: işıq effektləri sönür. Oyuna təsiri yoxdur."
	box.add_child(ghint)

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
## ANA EKRAN — mikrobun ÇEVRƏSİNDƏKİ halqa.
##
## Zonalar Brawl Stars-ın menyusundan götürülüb, hər birinin işi saxlanılıb:
##   • mərkəz        — fiqur; adı və superi ONUN üstündəki lövhədə
##   • aşağı-mərkəz  — OYNA, ekranın lövbəri
##   • aşağı-sağ     — rejim; «nə oynayıram» və «başla» bir qərardır
##   • sol lent      — MİKROBLAR (Brawl Stars-da Brawlers/Shop/Social)
##   • aşağı-sol     — MƏŞQ; ən az prioritetli yuva
func _build_home() -> void:
	# ── AD LÖVHƏSİ ──
	#
	# Kimlik obyektə bağlıdır, ekranın başqa küncünə yox: Brawl Stars da rank
	# və gücü fiqurun üstündə saxlayır. Yeri hər kadr yenilənir, çünki podium
	# ekran ölçüsündən asılıdır (bax [method _process]).
	var plate := PanelContainer.new()
	plate.name = "Plate"
	plate.custom_minimum_size = Vector2(PLATE.x, PLATE.y)
	plate.size = PLATE
	plate.add_theme_stylebox_override("panel", _panel_style())
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 0)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(pv)

	_plate_name = Hud._make_label(30, Palette.TEXT)
	_plate_name.theme_type_variation = "Heading"
	_plate_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_plate_name)

	_plate_super = Hud._make_label(16, Palette.GERM_COLORS[1])
	_plate_super.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(_plate_super)

	# ── SOL LENT ──
	var rail := Button.new()
	rail.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	rail.offset_left = PAD
	rail.offset_right = PAD + RAIL.x
	rail.offset_top = -RAIL.y * 0.5
	rail.offset_bottom = RAIL.y * 0.5
	rail.add_theme_stylebox_override("normal", _panel_style())
	rail.add_theme_stylebox_override("hover", _panel_style(Palette.DISH_EDGE))
	rail.add_theme_stylebox_override("pressed", _panel_style())
	rail.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	rail.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_open_sheet("species"))
	add_child(rail)

	var ricon := TextureRect.new()
	ricon.texture = load(_ICONS[int(Const.Species.CILIATE)])
	ricon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ricon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ricon.modulate = Palette.GERM_COLORS[0]
	ricon.position = Vector2(0, 16)
	ricon.size = Vector2(RAIL.x, 52)
	ricon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.add_child(ricon)

	var rlab := Hud._make_label(14, Palette.TEXT_MUTED)
	rlab.text = "MİKROBLAR"
	rlab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rlab.position = Vector2(0, 76)
	rlab.size = Vector2(RAIL.x, 22)
	rail.add_child(rlab)

	# ── AŞAĞI-MƏRKƏZ: OYNA ──
	#
	# Ekranın yeganə DOLU laym ləkəsi və ən böyük obyekti.
	_play = Button.new()
	_play.text = "OYNA"
	_play.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_play.offset_left = -BTN_W * 0.5
	_play.offset_right = BTN_W * 0.5
	_play.offset_top = -(PAD + PLAY_H)
	_play.offset_bottom = -PAD
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
	add_child(_play)
	_squash(_play, Vector2(BTN_W, PLAY_H))

	# ── AŞAĞI-SAĞ: rejim ──
	_mode_card = Button.new()
	_mode_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mode_card.offset_right = -PAD
	_mode_card.offset_left = -(PAD + MODE_W)
	_mode_card.offset_top = -(PAD + PLAY_H)
	_mode_card.offset_bottom = -PAD
	_mode_card.add_theme_stylebox_override("normal", _panel_style())
	_mode_card.add_theme_stylebox_override("hover", _panel_style(Palette.DISH_EDGE))
	_mode_card.add_theme_stylebox_override("pressed", _panel_style())
	_mode_card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_mode_card.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_open_sheet("modes"))
	add_child(_mode_card)
	_squash(_mode_card, Vector2(MODE_W, PLAY_H))

	var mcap := Hud._make_label(13, Palette.TEXT_MUTED)
	mcap.text = "REJİM"
	mcap.position = Vector2(16, 10)
	mcap.size = Vector2(MODE_W - 110, 18)
	mcap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(mcap)

	var mch := Hud._make_label(15, Palette.TEXT_MUTED)
	mch.text = "DƏYİŞ ›"
	mch.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mch.position = Vector2(MODE_W - 106, 10)
	mch.size = Vector2(90, 20)
	mch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(mch)

	_mode_name = Hud._make_label(26, Palette.GERM_COLORS[1])
	_mode_name.theme_type_variation = "Heading"
	_mode_name.position = Vector2(16, 32)
	_mode_name.size = Vector2(MODE_W - 32, 34)
	_mode_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(_mode_name)

	_mode_note = Hud._make_label(15, Palette.TEXT_MUTED)
	_mode_note.position = Vector2(16, 68)
	_mode_note.size = Vector2(MODE_W - 32, 24)
	_mode_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(_mode_note)

	# ── AŞAĞI-SOL: MƏŞQ ──
	var practice := Button.new()
	practice.text = "MƏŞQ · offline"
	practice.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	practice.offset_left = PAD
	practice.offset_right = PAD + 216.0
	practice.offset_top = -(PAD + 56.0)
	practice.offset_bottom = -PAD
	practice.add_theme_font_size_override("font_size", 19)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		practice.add_theme_color_override(state, Palette.TEXT_MUTED)
	practice.add_theme_stylebox_override("normal", _ghost_style(Palette.PANEL_BORDER))
	practice.add_theme_stylebox_override("hover", _ghost_style(Palette.DISH_EDGE))
	practice.add_theme_stylebox_override("pressed", _ghost_style(Palette.PANEL_BORDER))
	practice.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	practice.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_practice())
	add_child(practice)
	_squash(practice, Vector2(216.0, 56.0))


# ---------------------------------------------------------------- vərəq

## MİKROBLAR və REJİMLƏR — eyni çərçivəni paylaşan iki tam ekran vərəq.
##
## Brawl Stars-ın Brawlers və Events ekranlarının qarşılığı. Ana ekranda
## saxlanılsaydılar, oyunçu OYNA-ya çatana qədər on yeddi elementin arasından
## keçərdi; burada isə hər ekranın bir işi var.
func _build_sheet() -> void:
	_sheet = Control.new()
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.visible = false
	add_child(_sheet)

	var dim := ColorRect.new()
	dim.color = Palette.BG_OUTER
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.add_child(dim)

	_sheet_title = Hud._make_label(36, Palette.TEXT)
	_sheet_title.theme_type_variation = "Heading"
	_sheet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheet_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_sheet_title.offset_top = 88.0
	_sheet_title.offset_bottom = 140.0
	_sheet.add_child(_sheet_title)

	var back := Button.new()
	back.text = "‹ GERİ"
	back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = PAD
	back.offset_right = PAD + 170.0
	back.offset_top = -(PAD + 52.0)
	back.offset_bottom = -PAD
	back.add_theme_font_size_override("font_size", 20)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(state, Palette.TEXT_MUTED)
	back.add_theme_stylebox_override("normal", _ghost_style(Palette.PANEL_BORDER))
	back.add_theme_stylebox_override("hover", _ghost_style(Palette.DISH_EDGE))
	back.add_theme_stylebox_override("pressed", _ghost_style(Palette.PANEL_BORDER))
	back.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	back.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_close_sheet())
	_sheet.add_child(back)

	_sheet_species = Control.new()
	_sheet_species.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_species.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_sheet_species)
	_build_species_grid()

	_sheet_modes = Control.new()
	_sheet_modes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_modes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_sheet_modes)
	_build_mode_list()


## Üç növ yan-yana — Brawl Stars-ın Brawlers şəbəkəsi.
##
## Kartda CANLI mikrob var, ikona yox: növ seçimi görünüşə görə edilir və
## kirpiklinin dalğası ilə amöbin sürünməsi arasındakı fərq yalnız hərəkətdə
## görünür.
func _build_species_grid() -> void:
	var total := CARD_BIG.x * 3.0 + GRID_GAP * 2.0
	for i in Const.SPECIES_COUNT:
		var kind := Const.species_from(i)
		var card := Button.new()
		card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		card.offset_left = -total * 0.5 + float(i) * (CARD_BIG.x + GRID_GAP)
		card.offset_right = card.offset_left + CARD_BIG.x
		card.offset_top = -CARD_BIG.y * 0.5 + 22.0
		card.offset_bottom = card.offset_top + CARD_BIG.y
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		card.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			Net.species = kind
			_save_settings()
			_swap_germ()
			_refresh_species()
			_close_sheet())
		_sheet_species.add_child(card)
		_cards.append(card)

		var stage := Node2D.new()
		stage.position = Vector2(CARD_BIG.x * 0.5, 130.0)
		stage.scale = Vector2(1.45, 1.45) \
			* (Const.BASE_RADIUS / Const.germ_radius(GERM_CAPACITY))
		card.add_child(stage)
		var g := GermVisual.new()
		g.setup(i, "", true, kind)
		stage.add_child(g)
		g.apply(Vector2.ZERO, 0.0, GERM_BALLS, GERM_CAPACITY, false, true)

		var nm := Hud._make_label(28, Palette.TEXT)
		nm.theme_type_variation = "Heading"
		nm.text = _species_name(kind)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = Vector2(0, 252)
		nm.size = Vector2(CARD_BIG.x, 36)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		var sp := Hud._make_label(15, Palette.GERM_COLORS[1])
		sp.text = "SUPER · " + _species_super_name(kind)
		sp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sp.position = Vector2(0, 292)
		sp.size = Vector2(CARD_BIG.x, 22)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sp)

		var note := Hud._make_label(15, Palette.TEXT_MUTED)
		note.text = _species_note_for(kind)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.position = Vector2(16, 328)
		note.size = Vector2(CARD_BIG.x - 32, 64)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(note)


## Rejimlər ŞAQULİ siyahıdır, şəbəkə deyil.
##
## Brawl Stars-ın Events ekranı da belədir: rejimlər bərabər deyil, sıralıdır —
## sonsuz arena giriş, ÜÇLÜK isə ən dar oyundur. Göz yuxarıdan aşağı bir dəfə keçir.
func _build_mode_list() -> void:
	var n := Const.Mode.size()
	var h := ROW_H * float(n) + ROW_GAP * float(n - 1)
	for i in n:
		var mode := Const.mode_from(i)
		var row := Button.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		row.offset_left = -ROW_W * 0.5
		row.offset_right = ROW_W * 0.5
		row.offset_top = -h * 0.5 + 30.0 + float(i) * (ROW_H + ROW_GAP)
		row.offset_bottom = row.offset_top + ROW_H
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			Net.mode = mode
			_save_settings()
			_refresh_mode()
			_close_sheet())
		_sheet_modes.add_child(row)
		_mode_rows.append(row)

		var sw := ColorRect.new()
		sw.color = Palette.GERM_COLORS[MODE_TINT[i]]
		sw.position = Vector2(20, (ROW_H - 60.0) * 0.5)
		sw.size = Vector2(60, 60)
		sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(sw)

		var nm := Hud._make_label(26, Palette.TEXT)
		nm.theme_type_variation = "Heading"
		nm.text = Const.mode_name(int(mode))
		nm.position = Vector2(100, 18)
		nm.size = Vector2(ROW_W - 120, 34)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(nm)

		var note := Hud._make_label(15, Palette.TEXT_MUTED)
		note.text = Const.mode_note(int(mode))
		note.position = Vector2(100, 54)
		note.size = Vector2(ROW_W - 120, 24)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(note)


## Vərəq açılanda podium GİZLƏNİR.
##
## [GermVisual] öz `z_index`-ini 2 qoyur (oyunda öz mikrobun rəqiblərin
## üstündə çəkilməlidir), ona görə vərəq onu ADİ ağac sırası ilə örtə bilmir —
## mikrob kartların üstündə qalırdı.
func _open_sheet(which: String) -> void:
	_stage.visible = false
	_sheet_title.text = "MİKROBLAR" if which == "species" else "REJİMLƏR"
	_sheet_species.visible = which == "species"
	_sheet_modes.visible = which != "species"
	_sheet.visible = true
	_refresh_species()
	_refresh_mode()


func _close_sheet() -> void:
	_sheet.visible = false
	_stage.visible = true


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
	_sink_germ()
	_stage.add_child(_germ)
	_germ.apply(Vector2(_travelled, 0.0), 0.0, GERM_BALLS, GERM_CAPACITY, false, true)


## Seçilmiş rejimin adı və bir sətirlik qaydası.
##
## Bir sətir MƏCBURİDİR: oyunçu nəyə girdiyini basmadan əvvəl bilməlidir.
## Menyunun onsuz da yazılmış qaydasıdır (bax sinif şərhi, 3-cü bənd).
## Keyfiyyət düyməsinin yazısı və rəngi.
func _refresh_quality() -> void:
	_apply_quality()
	if _quality_btn == null:
		return
	_quality_btn.text = "QRAFİKA: %s" % Const.quality_name(int(Net.quality))
	_quality_btn.add_theme_color_override("font_color",
		Palette.TEXT if Net.quality == Const.Quality.HIGH else Palette.WARNING)


## HDR kadr buferi və zərrəcik sıxlığı — DƏRHAL, düymə basılan kadrda.
##
## Glow-un özü `WorldEnvironment`-dədir və o, [method _build_background]-da bir
## dəfə qurulur; menyu yenidən qurulmadığı üçün seçim növbəti açılışdan tam
## işləyir. Bufer və zərrəciklər isə elə indi dəyişir, yəni düymə basılan kimi
## ekranda gözlə görünən fərq olur — oyunçu ayarın işlədiyini bilir.
func _apply_quality() -> void:
	var low := Net.quality == Const.Quality.LOW
	get_viewport().use_hdr_2d = not low
	if _motes != null:
		_motes.count = 26 if low else 54
		_motes.rebuild()


func _refresh_mode() -> void:
	# Ad və qayda [Const]-dan gəlir: rejim əlavə edəndə menyu özü yenilənir.
	_mode_name.text = Const.mode_name(int(Net.mode))
	_mode_note.text = Const.mode_brief(int(Net.mode))
	# Sonsuz arena sakit mavidir, matçlı rejimlər isə xəbərdaredici narıncı:
	# matç girdiyin kimi bitmir, oyunçu bunu basmadan əvvəl bilməlidir.
	var col := Palette.GERM_COLORS[1] if Net.mode == Const.Mode.ENDLESS else Palette.WARNING
	_mode_name.add_theme_color_override("font_color", col)

	for i in _mode_rows.size():
		var on := Const.mode_from(i) == Net.mode
		var row := _mode_rows[i]
		for state in ["normal", "hover", "pressed"]:
			row.add_theme_stylebox_override(state, _card_style(on))
		var nm := row.get_child(1) as Label
		nm.add_theme_color_override("font_color",
			Palette.TEXT if on else Color(0.62, 0.72, 0.71))


func _refresh_species() -> void:
	_plate_name.text = _species_name(Net.species)
	_plate_super.text = "SUPER · " + _species_super_name(Net.species)
	for i in _cards.size():
		var on := Const.species_from(i) == Net.species
		var card := _cards[i]
		for state in ["normal", "hover", "pressed"]:
			card.add_theme_stylebox_override(state, _card_style(on))
		# Ad və super seçiləndə işıqlanır — kart sırasında hansının aktiv
		# olduğu yalnız çərçivədən yox, mətnin özündən də oxunmalıdır.
		var nm := card.get_child(1) as Label
		nm.add_theme_color_override("font_color",
			Palette.TEXT if on else Color(0.62, 0.72, 0.71))
		var sp := card.get_child(2) as Label
		sp.add_theme_color_override("font_color",
			Palette.GERM_COLORS[1] if on else Color(0.42, 0.52, 0.52))


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
		_set_pill("server cavab vermir", Palette.WARNING))


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
	_set_pill("server yatıb", Palette.WARNING)


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
	# İlkin dəyər CİHAZDAN çıxır (telefonda aşağı), sonra oyunçunun seçimi.
	Net.quality = Const.quality_from(int(cfg.get_value(
		"video", "quality", int(Const.default_quality()))))
	_addr.text = str(cfg.get_value("net", "address", _addr.text))


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "nickname", _clean_nick())
	cfg.set_value("player", "species", int(Net.species))
	cfg.set_value("player", "mode", int(Net.mode))
	cfg.set_value("video", "quality", int(Net.quality))
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
