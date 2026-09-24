class_name Hud
extends CanvasLayer
## Oyun içi interfeys: doluluq göstəricisi, liderlər, xəritə, idarəetmə.
##
## Ekran koordinatlarında yaşayır (CanvasLayer), ona görə kamera yaxınlaşıb
## uzaqlaşsa da HUD həmişə eyni fiziki ölçüdə qalır — baş barmaq üçün bu vacibdir.
##
## Sol yarı hərəkət joystickinin zonasıdır — barmağı hara qoysan, idarə orada
## yaranır. Sağ aşağı küncdə top atma düyməsi dayanır.
##
## HUD-un ƏSAS işi bir rəqəmi göstərməkdir: neçə topun var və tutumun nə qədərdir.
## Oyunun bütün qərarları bu rəqəmdən asılıdır, ona görə o, ekranın ən görünən
## yerindədir və rəngi vəziyyəti özü izah edir.

const STICK_ZONE_TOP := 0.34     ## Hərəkət zonası ekranın bu hündürlüyündən aşağı başlayır

const FIRE_BOX := 200.0
const FIRE_MARGIN_RIGHT := 40.0
const FIRE_MARGIN_BOTTOM := 68.0

## Super düyməsinin qutusu və atəş düyməsindən nə qədər yuxarıda durduğu.
##
## Atəşdən KİÇİKDİR (108 : 200) və üstündədir — Brawl Stars-dakı yerləşmə.
## Səbəb sadədir: atəş saniyədə basılır, super 20-30 saniyədən bir. Böyük və
## əlaltı olan tez-tez basılan olmalıdır; superin isə səhvən basılmaması
## vacibdir, ona görə bir az uzaqdadır.
const SUPER_BOX := 108.0
const SUPER_GAP := 14.0

const GAUGE_W := 250.0
const BAR_H := 16.0
const MAP_SIZE := 132.0

## Liderlər cədvəlinin sətir sayı və bir sətrin hündürlüyü.
##
## Minimapın yeri buradan çıxır — iki ədəd ayrı-ayrı saxlansaydı, biri
## dəyişəndə o biri unudulardı və panellər yenidən üst-üstə düşərdi.
const BOARD_ROWS := 5
const BOARD_ROW_H := 33.0
const BOARD_BOTTOM := 74.0 + BOARD_ROWS * BOARD_ROW_H

## Matçın içində AYARLAR YOXDUR — Brawl Stars-da olduğu kimi.
##
## Əvvəl yuxarı-mərkəzdə dişli vardı və tam ekran ayarları açırdı. Brawl
## Stars döyüşdə heç bir sistem düyməsi göstərmir: ekranda yalnız döyüş var,
## ayarlar isə ana ekrandadır. Səs və qrafika matçdan əvvəl bir dəfə qurulur,
## döyüşün ortasında ona ehtiyac olmur — dişli isə hər matçda ekranın bir
## parçasını tuturdu.
##
## ÇIXIŞ isə qalır, çünki sonsuz arenada matç bitmir: dişlidən əvvəl
## oyunçunun yeganə yolu ölmək idi. Çıxış düymə deyil, sistem jestidir — ESC
## və ya Android-in GERİ jesti bu təsdiqi açır (bax [method Arena._notification]).
## Təsdiq ona görədir ki, GERİ jesti ekranın kənarından sürüşdürməklə edilir
## və döyüşdə barmaq ora təsadüfən gedir.
signal leave_confirmed()

var move_stick: TouchStick
var fire_button: FireButton
var super_button: SuperButton
var minimap: Minimap

var _root: Control
var _safe_root: Control
var _gauge_lbl: Label
var _level_lbl: Label
var _bar: ColorRect
var _bar_bg: ColorRect
var _warn_lbl: Label
var _drying := false
var _board_lbl: Label
var _pop_lbl: Label
## Sağ qalan mikrob sayı — yalnız matçlı rejimdə görünür.
var _alive_lbl: Label
var _score_lbl: Label
var _center_lbl: Label
var _sub_lbl: Label
var _result: Control
var _result_title: Label
var _result_body: Label
var _result_rule: ColorRect
## Çıxış təsdiqi (bax [method toggle_leave_prompt]).
var _leave: Control
var _fps_lbl: Label
## Kadr sayğacı saniyədə bir dəfə yenilənir — bax [method _process].
var _fps_t := 0.0

var _local_color := Palette.TEXT
var _warn_t := 0.0
var _bar_fill_target := 0.0
var _bar_fill_shown := 0.0
var _gauge_danger := false
var _gauge_t := 0.0
var _message_tween: Tween = null
## ÜÇLÜK-ün raund hesabı — nəticə ekranı da onu göstərməlidir, ona görə
## [method set_match]-dan saxlanılır.
var _trio := false
var _score_us := 0
var _score_them := 0


func build(base_tex: Texture2D, knob_tex: Texture2D) -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# Kənara YAPIŞMAYAN qat — bax [method _apply_safe_area].
	_safe_root = Control.new()
	_safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_safe_root)

	_build_gauge()
	_build_board()
	_build_minimap()
	_build_center()
	_build_result()
	_build_system()
	_build_controls(base_tex, knob_tex)
	# SONUNCU: çıxış təsdiqi atəş və super düymələrinin ÜSTÜNDƏ olmalıdır —
	# ağacda sonra gələn həm üstdə çəkilir, həm toxunuşu birinci alır.
	_build_leave_prompt()

	apply_settings()
	# Ayarlar artıq yalnız menyudadır, amma siqnala qoşulmaq ucuzdur və HUD-u
	# gələcəkdə ayarı dəyişən hər yerə (məs. ilk açılış bələdçisi) hazır saxlayır.
	Settings.changed.connect(apply_settings)

	_apply_safe_area()
	get_viewport().size_changed.connect(_apply_safe_area)


## Çıxıntı (notch) və ev göstəricisi zolağı üçün kənar boşluq.
##
## Portretdə sistemin zolaqları HUD-un boş yerinə düşürdü. Yatayda isə vəziyyət
## başqadır: ev göstəricisi düz ATƏŞ DÜYMƏSİNİN altındadır, çıxıntı isə yan
## kənardadır — barmaq düyməyə basmaq əvəzinə sistemin jestini işə salır.
##
## Ölçü sabitə yazılmır, SİSTEMDƏN soruşulur: hər cihazda başqadır, masaüstündə
## və brauzerdə isə ümumiyyətlə yoxdur. Pəncərə ekrandan kiçik olanda fərq
## mənfi çıxır və sıfıra qısaldılır — yəni masaüstündə heç nə tərpənmir.
##
## Yalnız OXUNAN və BASILAN elementlər içəridədir; joystick zonası, mərkəzi
## mesajlar və nəticə lövhəsi tam ekranda qalır — onlar kənara toxunmalıdır.
func _apply_safe_area() -> void:
	var vp := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	if win.x <= 0 or win.y <= 0:
		return

	# Sistem ekran pikselləri ilə cavab verir, HUD isə viewport vahidləri ilə
	# yaşayır (`stretch/mode = canvas_items`) — ona görə nisbətə vurulur.
	var safe := DisplayServer.get_display_safe_area()
	var kx := vp.x / float(win.x)
	var ky := vp.y / float(win.y)

	_safe_root.offset_left = maxf(float(safe.position.x), 0.0) * kx
	_safe_root.offset_top = maxf(float(safe.position.y), 0.0) * ky
	_safe_root.offset_right = -maxf(float(win.x - safe.end.x), 0.0) * kx
	_safe_root.offset_bottom = -maxf(float(win.y - safe.end.y), 0.0) * ky


# ---------------------------------------------------------------- qurulma

## Sol yuxarı: "top / tutum" — oyunun bütün məntiqi bu rəqəmdədir.
func _build_gauge() -> void:
	_gauge_lbl = _make_label(46, Palette.TEXT)
	_gauge_lbl.theme_type_variation = "Heading"
	_gauge_lbl.position = Vector2(20, 12)
	_gauge_lbl.size = Vector2(GAUGE_W, 56)
	_safe_root.add_child(_gauge_lbl)

	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(Palette.PANEL, 0.9)
	_bar_bg.position = Vector2(22, 70)
	_bar_bg.size = Vector2(GAUGE_W, BAR_H)
	_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_root.add_child(_bar_bg)

	_bar = ColorRect.new()
	_bar.color = Palette.SAFE
	_bar.position = _bar_bg.position
	_bar.size = Vector2(0, BAR_H)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_safe_root.add_child(_bar)

	_level_lbl = _make_label(20, Palette.TEXT_MUTED)
	_level_lbl.position = Vector2(22, 92)
	_level_lbl.size = Vector2(GAUGE_W, 28)
	_safe_root.add_child(_level_lbl)

	# Xəbərdarlıq zolağı — yalnız təhlükə anında görünür.
	_warn_lbl = _make_label(24, Palette.DANGER)
	_warn_lbl.position = Vector2(22, 118)
	_warn_lbl.size = Vector2(420, 32)
	_warn_lbl.visible = false
	_safe_root.add_child(_warn_lbl)


func _build_board() -> void:
	_pop_lbl = _make_label(20, Palette.TEXT_MUTED)
	_pop_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pop_lbl.anchor_left = 1.0
	_pop_lbl.anchor_right = 1.0
	_pop_lbl.offset_left = -260
	_pop_lbl.offset_right = -20
	_pop_lbl.offset_top = 14
	_pop_lbl.offset_bottom = 40
	_safe_root.add_child(_pop_lbl)

	# Sağ qalan sayı liderlər cədvəlinin ÜSTÜNDƏDİR: matçda ən vacib rəqəm
	# odur — kim liderdir yox, neçə nəfər qalıb.
	_alive_lbl = _make_label(24, Palette.WARNING)
	_alive_lbl.theme_type_variation = "Heading"
	_alive_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_alive_lbl.anchor_left = 1.0
	_alive_lbl.anchor_right = 1.0
	_alive_lbl.offset_left = -260
	_alive_lbl.offset_right = -20
	_alive_lbl.offset_top = 40
	_alive_lbl.offset_bottom = 70
	_alive_lbl.visible = false
	_safe_root.add_child(_alive_lbl)

	# RAUND HESABI — yalnız ÜÇLÜK-də.
	#
	# "SAĞ: N" sayğacının yerində durur, çünki ikisi eyni sualın iki rejimdəki
	# cavabıdır: "matç harda dayanıb". ÜÇLÜK-də sağ sayı az məna daşıyır —
	# raund onsuz da 60 saniyəyə bitir, matçı isə hesab həll edir.
	_score_lbl = _make_label(24, Palette.ALLY)
	_score_lbl.theme_type_variation = "Heading"
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_lbl.anchor_left = 1.0
	_score_lbl.anchor_right = 1.0
	_score_lbl.offset_left = -260
	_score_lbl.offset_right = -20
	_score_lbl.offset_top = 40
	_score_lbl.offset_bottom = 70
	_score_lbl.visible = false
	_safe_root.add_child(_score_lbl)

	_board_lbl = _make_label(21, Palette.TEXT)
	_board_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_board_lbl.anchor_left = 1.0
	_board_lbl.anchor_right = 1.0
	_board_lbl.offset_left = -260
	_board_lbl.offset_right = -20
	_board_lbl.offset_top = 74
	# Alt hədd BEŞ sətri tam tutmalıdır: 21 px şrift ≈ 33 px sətir, 5 × 33 = 165,
	# yəni 74 + 165 = 239. Əvvəl 200 idi və minimap da elə 200-dən başlayırdı —
	# nəticədə 5-ci sətrin ADI minimapın altında qalır, yalnız sağdakı rəqəm
	# görünürdü və sətir qırılmış kimi oxunurdu.
	_board_lbl.offset_bottom = 74 + BOARD_ROWS * BOARD_ROW_H
	_safe_root.add_child(_board_lbl)


func _build_minimap() -> void:
	minimap = Minimap.new()
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.offset_left = -(MAP_SIZE + 18.0)
	minimap.offset_right = -18.0
	# Cədvəlin ALTINDAN başlayır (bax [method _build_board]) — sabit 200 deyil.
	# Sabit olsaydı, cədvəl bir sətir uzananda yenidən örtülərdi.
	# Cədvəlin ALTINDAN başlayır (bax [method _build_board]) — sabit ədəd deyil.
	minimap.offset_top = BOARD_BOTTOM + 12.0
	minimap.offset_bottom = BOARD_BOTTOM + 12.0 + MAP_SIZE
	_safe_root.add_child(minimap)


func _build_center() -> void:
	_center_lbl = _make_label(54, Palette.TEXT)
	_center_lbl.theme_type_variation = "Heading"
	_center_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_lbl.anchor_left = 0.0
	_center_lbl.anchor_right = 1.0
	# 0.30 DEYİL, 0.20.
	#
	# Oyunçunun mikrobu ekranın tam mərkəzindədir və adı ondan ~65 px yuxarıda
	# çəkilir. 0.30-da alt sətir məhz o adın üstünə düşürdü: sayımda
	# "TƏK QALAN · 10 mikrob" ilə "Mikrob" bir-birinə qarışırdı.
	_center_lbl.anchor_top = 0.20
	_center_lbl.anchor_bottom = 0.20
	_center_lbl.offset_bottom = 72
	_root.add_child(_center_lbl)

	_sub_lbl = _make_label(26, Palette.TEXT_MUTED)
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.anchor_left = 0.0
	_sub_lbl.anchor_right = 1.0
	_sub_lbl.anchor_top = 0.20
	_sub_lbl.anchor_bottom = 0.20
	_sub_lbl.offset_top = 70
	_sub_lbl.offset_bottom = 112
	_root.add_child(_sub_lbl)

	hide_message()


## Mikrob partlayanda açılan nəticə lövhəsi.
func _build_result() -> void:
	_result = Control.new()
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result.visible = false
	_root.add_child(_result)

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_OUTER, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result.add_child(dim)

	_result_title = _make_label(64, Palette.DANGER)
	_result_title.theme_type_variation = "Heading"
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.anchor_left = 0.0
	_result_title.anchor_right = 1.0
	_result_title.anchor_top = 0.32
	_result_title.anchor_bottom = 0.32
	_result_title.offset_bottom = 84
	_result.add_child(_result_title)

	# QIZIL XƏTT — yalnız qələbədə görünür.
	#
	# Təkcə rəng dəyişsəydi, qalib və uduzan ekranı eyni quruluşda qalardı və
	# fərq bir baxışda oxunmazdı. Xətt + böyümə + fərqli mətn birlikdə "bu
	# başqa nəticədir" deyir — Brawl Stars da qələbəni quruluşla ayırır.
	_result_rule = ColorRect.new()
	_result_rule.color = Palette.FOCUS
	_result_rule.anchor_left = 0.5
	_result_rule.anchor_right = 0.5
	_result_rule.anchor_top = 0.32
	_result_rule.anchor_bottom = 0.32
	_result_rule.offset_left = -120
	_result_rule.offset_right = 120
	_result_rule.offset_top = 84
	_result_rule.offset_bottom = 88
	_result_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result_rule.visible = false
	_result.add_child(_result_rule)

	_result_body = _make_label(28, Palette.TEXT)
	_result_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_body.anchor_left = 0.0
	_result_body.anchor_right = 1.0
	_result_body.anchor_top = 0.32
	_result_body.anchor_bottom = 0.32
	_result_body.offset_top = 96
	_result_body.offset_bottom = 320
	_result.add_child(_result_body)


## Yuxarı-mərkəz: kadr sayğacı (ayarlarda açılır).
func _build_system() -> void:
	_fps_lbl = _make_label(15, Palette.TEXT_MUTED)
	_fps_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fps_lbl.anchor_left = 0.5
	_fps_lbl.anchor_right = 0.5
	_fps_lbl.offset_left = -70.0
	_fps_lbl.offset_right = 70.0
	_fps_lbl.offset_top = 10.0
	_fps_lbl.offset_bottom = 34.0
	_fps_lbl.visible = false
	_safe_root.add_child(_fps_lbl)


## "MATÇDAN ÇIXIRSAN?" — GERİ jestinin təsdiqi (bax [signal leave_confirmed]).
##
## Oyun DAYANMIR: dünya serverdədir və bu pəncərə ora heç nə demir. Ona görə
## örtük yarımşəffafdır və DAVAM ET böyük, sol tərəfdədir — oyunçunun ilk
## refleksi geri qayıtmaqdır, çıxmaq yox.
func _build_leave_prompt() -> void:
	_leave = Control.new()
	_leave.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_leave.visible = false
	# Arxadakı atəş və super düymələrinə basılmasın.
	_leave.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_leave)

	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_OUTER, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_leave.add_child(dim)

	var title := _make_label(40, Palette.TEXT)
	title.theme_type_variation = "Heading"
	title.text = "MATÇDAN ÇIXIRSAN?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.offset_left = -400.0
	title.offset_right = 400.0
	title.offset_top = -120.0
	title.offset_bottom = -64.0
	ChunkyBox.stroke(title, 8, true)
	_leave.add_child(title)

	var note := _make_label(19, Palette.TEXT_MUTED)
	note.text = "Mikrobun dünyadan silinir, qazandığın tutum itir."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	note.offset_left = -400.0
	note.offset_right = 400.0
	note.offset_top = -58.0
	note.offset_bottom = -28.0
	_leave.add_child(note)

	var stay := _prompt_button("DAVAM ET", Palette.MENU_BLUE, -250.0)
	stay.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		close_leave_prompt())
	var go := _prompt_button("ÇIX", Palette.DANGER, 20.0)
	go.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		close_leave_prompt()
		leave_confirmed.emit())


func _prompt_button(label: String, face: Color, left: float) -> Button:
	var b := Button.new()
	b.text = label
	b.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	b.offset_left = left
	b.offset_right = left + 230.0
	b.offset_top = 10.0
	b.offset_bottom = 94.0
	b.add_theme_font_size_override("font_size", 30)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Palette.TEXT)
	ChunkyBox.stroke(b, 6, true)
	ChunkyBox.apply(b, face)
	_leave.add_child(b)
	return b


## Təsdiqi açır və ya (açıqdırsa) bağlayır — GERİ jesti ikinci dəfə edilsə,
## oyunçu fikrindən daşınıb deməkdir.
func toggle_leave_prompt() -> void:
	if _leave.visible:
		close_leave_prompt()
		return
	# Barmaq joystickdə idisə, örtük onun "buraxıldı" hadisəsini udur və mikrob
	# son istiqamətdə üzməyə davam edərdi.
	release_sticks()
	_leave.visible = true


func close_leave_prompt() -> void:
	_leave.visible = false


func is_leave_prompt_open() -> bool:
	return _leave.visible


func _build_controls(base_tex: Texture2D, knob_tex: Texture2D) -> void:
	move_stick = TouchStick.new()
	move_stick.base_texture = base_tex
	move_stick.knob_texture = knob_tex
	move_stick.anchor_top = STICK_ZONE_TOP
	move_stick.anchor_bottom = 1.0
	_root.add_child(move_stick)

	fire_button = FireButton.new()
	fire_button.anchor_top = 1.0
	fire_button.anchor_bottom = 1.0
	fire_button.offset_top = -(FIRE_BOX + FIRE_MARGIN_BOTTOM)
	fire_button.offset_bottom = -FIRE_MARGIN_BOTTOM
	_safe_root.add_child(fire_button)

	# Super — atəşin YANINDA, bir az yuxarı sürüşmüş: baş barmaq qövs cızaraq
	# hərəkət edir, düz yuxarı yox.
	super_button = SuperButton.new()
	super_button.radius = SUPER_BOX * 0.5
	super_button.anchor_top = 1.0
	super_button.anchor_bottom = 1.0
	var sy := FIRE_MARGIN_BOTTOM + (FIRE_BOX - SUPER_BOX) * 0.5
	super_button.offset_top = -(SUPER_BOX + sy)
	super_button.offset_bottom = -sy
	_safe_root.add_child(super_button)

	# Üfüqi yer [method apply_settings]-dədir: sol əl rejimi hamısını güzgüləyir.


## Ayarları HUD-a tətbiq edir — qurulanda və hər dəyişiklikdə.
##
## Sol əl düzümü ekranın İKİ yarısını da dəyişir, tək düyməni yox: joystick
## boş qalan yarıya keçməlidir, yoxsa hərəkət və atəş eyni baş barmağa düşər
## və oyun oynanmaz olar.
func apply_settings() -> void:
	_fps_lbl.visible = Settings.show_fps

	var lefty := Settings.left_handed

	# ── hərəkət joysticki: boş qalan yarı ──
	move_stick.anchor_left = 0.5 if lefty else 0.0
	move_stick.anchor_right = 1.0 if lefty else 0.5

	# ── atəş düyməsi ──
	_pin_horizontal(fire_button, lefty, FIRE_MARGIN_RIGHT, FIRE_BOX)

	# ── super: atəşin YAN tərəfində, mərkəzə doğru ──
	#
	# Üstündə DEYİL: orada 108 piksel yuxarı uzanıb minimapın alt-sol üçdə
	# birini örtürdü (104×53 kəsişmə, bütün 16:9 yatay pəncərələrdə).
	# Yan tərəf həm də daha doğrudur — baş barmaq atəşdən superə üfüqi keçir.
	# Güzgüləndikdə də mərkəzə doğru qalır, yəni joystickin zonasına girmir.
	_pin_horizontal(super_button, lefty,
		FIRE_MARGIN_RIGHT + FIRE_BOX + SUPER_GAP, SUPER_BOX)


## Bir idarəni ekranın sağ (adi) və ya sol (sol əl) kənarına bağlayır.
##
## [param margin] kənardan məsafə, [param box] elementin eni. Anchor-lar da
## dəyişir, təkcə ofsetlər yox: 0 və 1 anchor-ları eyni ofsetlə ekranın
## əks tərəflərini verir.
static func _pin_horizontal(node: Control, lefty: bool, margin: float, box: float) -> void:
	node.anchor_left = 0.0 if lefty else 1.0
	node.anchor_right = 0.0 if lefty else 1.0
	node.offset_left = margin if lefty else -(box + margin)
	node.offset_right = (margin + box) if lefty else -margin


static func _make_label(font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	# Kontur ŞRİFTƏ NİSBƏTDƏDİR, sabit 6 px deyil.
	#
	# Sabit qalanda kiçik yazılar boğulurdu: 18 px-lik "Səviyyə 1" portret
	# pəncərədə (miqyas 56%) tünd ləkəyə çevrilirdi, 64 px-lik nəticə başlığında
	# isə eyni 6 px nazik qalırdı. Kontur oxunaqlılıq üçündür — hərfin özündən
	# qalın olmamalıdır.
	l.add_theme_constant_override("outline_size",
		clampi(roundi(float(font_size) * 0.22), 3, 12))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# ---------------------------------------------------------------- yeniləmə

func set_local_color(c: Color) -> void:
	_local_color = c
	fire_button.set_germ_color(c)
	super_button.set_local_color(c)


## Qısa müddətli izah — daimi xəbərdarlıqları MÜVƏQQƏTİ olaraq üstələyir.
##
## Oyunçunun BASDIĞI düymənin cavabı üçündür ("super üçün 5 top lazımdır").
## Daimi xəbərdarlıqlar ([method update_gauge]) vəziyyəti təsvir edir və hər
## kadr yenidən yazılır; bu isə HADİSƏYƏ cavabdır və özündən sonra keçib
## getməlidir, yoxsa oyunçu təhlükə yazısını itirər.
const HINT_TIME := 2.0

var _hint := ""
var _hint_t := 0.0


## [param text] boşdursa heç nə etmir — səbəbsiz yanıb-sönmə olmasın.
func flash_hint(text: String) -> void:
	if text.is_empty():
		return
	_hint = text
	_hint_t = HINT_TIME
	_set_warning(text)


func _process(delta: float) -> void:
	# Kadr sayğacı SANİYƏDƏ BİR yenilənir.
	#
	# Hər kadr yazılsaydı rəqəm oxunmaz sürətlə titrəyərdi və sayğacın özü
	# ölçdüyü şeyə (kadr vaxtına) yük olardı — mətn yenidən düzülür.
	if _fps_lbl.visible:
		_fps_t += delta
		if _fps_t >= 1.0:
			_fps_t = 0.0
			_fps_lbl.text = "%d FPS" % Engine.get_frames_per_second()

	# Snapshot 30 Hz, ekran isə 60+ Hz-dir. Zolaq hədəfə eksponensial yaxınlaşır
	# ki, doluluq pillə-pillə sıçramasın; sabit sürət böyük artımda gecikirdi.
	_bar_fill_shown = lerpf(_bar_fill_shown, _bar_fill_target,
		1.0 - exp(-delta * 10.0))
	_bar.size.x = GAUGE_W * _bar_fill_shown
	_gauge_t += delta
	if _gauge_danger:
		# 2 piksel ekranı oxunmaz etmir, amma DANGER rəngini hərəkətlə də deyir.
		_bar.position = _bar_bg.position + Vector2(
			sin(_gauge_t * 35.0) * 1.9, sin(_gauge_t * 47.0) * 0.8)
	else:
		_bar.position = _bar_bg.position

	if _hint_t > 0.0:
		_hint_t = maxf(0.0, _hint_t - delta)

	# Xəbərdarlıq yazısı yanıb-sönür: hərəkət diqqəti mətndən tez çəkir.
	if _warn_lbl.visible:
		_warn_t += delta
		# Alt hədd 0.64-dür, 0.10 yox.
		#
		# Əvvəl `0.55 + 0.45 * sin` idi, yəni alfa 0.10-a qədər düşürdü və yazı
		# saniyədə ~1.4 dəfə praktiki olaraq GÖRÜNMÜR olurdu. Yanıb-sönmə diqqət
		# çəkmək üçündür; oxunmaz olmaq üçün deyil. Xüsusən "QURUYUR — mərkəzə
		# get" rejimin ən ölümcül xəbərdarlığıdır.
		_warn_lbl.modulate.a = 0.82 + 0.18 * sin(_warn_t * 7.5)


## Əsas göstərici: neçə top / tutum.
func update_gauge(balls: int, capacity: int) -> void:
	_gauge_lbl.text = "%d / %d" % [balls, capacity]
	var fill := clampf(float(balls) / float(maxi(capacity, 1)), 0.0, 1.0)
	var col := Palette.fill_color(fill)
	_gauge_lbl.add_theme_color_override("font_color", col)
	_bar.color = col
	_bar_fill_target = fill
	_gauge_danger = fill >= 0.85
	_level_lbl.text = "Səviyyə %d" % Const.level_of(capacity)

	# Üç təhlükə var və üçü də ölümcüldür: dolub partlamaq, acından partlamaq,
	# quru zonada qalmaq.
	#
	# Quruma ƏN TƏCİLİSİDİR: qalan ikisi oyunçunun öz sürətindən asılıdır və
	# dayanmaqla saxlanır, quruma isə saatdan asılıdır — yerində durmaq onu
	# yalnız pisləşdirir.
	# Oyun bitibsə xəbərdarlıq susur: nəticə lövhəsinin altından yanıb-sönən
	# "DOLURSAN — TOP AT!" görünürdü, halbuki artıq atmağa mikrob yoxdur.
	if _result.visible:
		_warn_lbl.visible = false
	elif _hint_t > 0.0:
		# Basılmış düymənin cavabı təhlükə yazısını qısa müddət üstələyir:
		# oyunçu məhz indi soruşub, cavab da indi gəlməlidir.
		_set_warning(_hint)
	elif _drying:
		_set_warning("QURUYUR — mərkəzə get")
	elif balls >= capacity - 1:
		_set_warning("DOLURSAN — TOP AT!")
	elif balls <= Const.MIN_BALLS:
		_set_warning("ACSAN — QİDA YE!")
	else:
		_set_warning("")


func _set_warning(text: String) -> void:
	if text.is_empty():
		_warn_lbl.visible = false
		return
	if _warn_lbl.text != text:
		_warn_lbl.text = text
		_warn_t = 0.0
	_warn_lbl.visible = true


## Liderlər cədvəli.
##
## [param rows] sıx ədəd cütlüyüdür: `id, partlatma, id, partlatma, ...`.
## Ad şəbəkədən GƏLMİR — [param names] reyestrindən tapılır, çünki adlar
## sabitdir və onları saniyədə 30 dəfə göndərmək snapshot-u MTU-dan yuxarı
## qaldırırdı (bax [method Net.on_roster]).
func update_board(rows: PackedInt32Array, population: int, names: Dictionary) -> void:
	_pop_lbl.text = "Dünyada %d mikrob" % population
	var lines := PackedStringArray()
	var n := rows.size() / 2
	for i in n:
		var gid := rows[i * 2]
		var info: Array = names.get(gid, ["", 0])
		lines.append("%d. %s  %d" % [i + 1, String(info[0]), rows[i * 2 + 1]])
	_board_lbl.text = "\n".join(lines)


func set_fire_state(ratio: float, has_ammo: bool) -> void:
	fire_button.set_state(ratio, has_ammo)


func show_message(text: String, sub := "") -> void:
	_center_lbl.text = text
	_center_lbl.visible = true
	_sub_lbl.text = sub
	_sub_lbl.visible = not sub.is_empty()
	# Bildiriş sadəcə peyda olmur: 0.72-dən back-out ilə aşıraraq gəlir.
	# Uzun fade sınananda döyüş mesajı oxunana qədər hadisə artıq bitirdi.
	if _message_tween != null and _message_tween.is_valid():
		_message_tween.kill()
	_center_lbl.pivot_offset = _center_lbl.size * 0.5
	_center_lbl.scale = Vector2(0.72, 0.72)
	_message_tween = create_tween()
	_message_tween.tween_property(_center_lbl, "scale", Vector2.ONE, 0.24) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_message() -> void:
	_center_lbl.visible = false
	_sub_lbl.visible = false
	_center_lbl.scale = Vector2.ONE


## Oyun bitdi — həm partlayanın, həm də qalibin ekranı.
##
## İki nəticə bir funksiyadadır, çünki gövdə (partlatma, tutum, yaşama
## müddəti) eynidir — fərq başlıqda və ilk sətirdədir. Ayrı funksiya olsaydı,
## gövdə iki yerdə saxlanmalı olardı və biri gec-tez geri qalardı.
func show_result(result: Dictionary) -> void:
	hide_message()
	_warn_lbl.visible = false
	# Oyun ekranı SÖNÜR — nəticə tək qalır.
	#
	# Örtük 0.82 alfalıdır, yəni altındakı hər şey oxunaqlı qalırdı: göstərici,
	# liderlər cədvəli, minimap, atəş və super düymələri nəticə mətni ilə
	# yarışırdı. Halbuki bu ekranda oyunçunun edə biləcəyi heç nə yoxdur.
	_safe_root.visible = false
	move_stick.visible = false
	var killer := str(result.get("killer", ""))
	var age := int(float(result.get("age", 0.0)))
	var won := bool(result.get("won", false))
	# Oyunçu SAĞDIRSA, partlama cümlələrinin heç biri ona aid deyil.
	#
	# Bu bayraq olmadan sağ qalan oyunçu "Acından partladın" oxuyurdu: partladan
	# adı boş idi, boş ad isə aclıq demək idi. Ekranda yalan yazılırdı.
	var survived := bool(result.get("survived", false))
	# Matç vaxt limiti ilə bitibsə, BİR NEÇƏ mikrob sağ qalır.
	var timed_out := bool(result.get("timed_out", false))
	# Matçlı rejimdə başlıq YERDİR — oyunçunun ilk soruşduğu odur.
	var place := int(result.get("place", 0))

	var lead := ("Səni partladan: " + killer) if not killer.is_empty() else "Acından partladın"
	if won:
		_result_title.text = "QALİB!"
		_result_title.add_theme_color_override("font_color", Palette.FOCUS)
		# Qələbə İKİ cürdür və onları qarışdırmaq yalan yazır: vaxt limitində
		# başqaları da sağdır, yəni "sonuncu mikrob sənsən" doğru deyil.
		lead = "Vaxt bitdi — ən çox topla sən qaldın" if timed_out else "Sonuncu mikrob sənsən"
	elif survived:
		# Sağ qaldı, amma birinci deyil — bu YALNIZ vaxt limitində mümkündür.
		_result_title.text = "%s YER" % Const.ordinal(place)
		_result_title.add_theme_color_override("font_color",
			Palette.FOCUS if place <= 3 else Palette.TEXT)
		lead = "Vaxt bitdi — sağ qaldın"
	elif place > 0:
		_result_title.text = "%s YER" % Const.ordinal(place)
		_result_title.add_theme_color_override("font_color",
			Palette.FOCUS if place <= 3 else Palette.DANGER)
	else:
		_result_title.text = "PARTLADIN"
		_result_title.add_theme_color_override("font_color", Palette.DANGER)

	# Neçə mikrobdan neçənci — yer tək başına mənasızdır.
	#
	# Budaqlardan SONRA gəlir: hər budaq `lead`-i yenidən yazır, ona görə əvvəl
	# qoyulsaydı, prefiks yalnız partlayan oyunçuda qalardı.
	# `total` serverdən gəlirdi, amma bura qədər heç vaxt oxunmurdu
	# (bax design/MODES.md §6.2).
	# Prefiks YALNIZ yer bildirən hallarda. Qalibdə "10 mikrobdan · Sonuncu
	# mikrob sənsən" yamaq kimi səslənir — orada say onsuz da mənasızdır.
	var total := int(result.get("total", 0))
	if total > 0 and not won:
		lead = "%d mikrobdan · %s" % [total, lead]

	_result_rule.visible = won
	if won:
		# Başlıq böyüyərək gəlir: qələbə AN olmalıdır, sadəcə yazı yox.
		_result_title.pivot_offset = _result_title.get_rect().size * 0.5
		_result_title.scale = Vector2(0.55, 0.55)
		var step := create_tween().tween_property(_result_title, "scale", Vector2.ONE, 0.5)
		step.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_result_title.scale = Vector2.ONE
	# ÜÇLÜK-də matçı YER yox, RAUND HESABI həll edir — nəticə də onu deməlidir.
	#
	# Hesab yalnız oyun ekranının sağ küncündə vardı və nəticə açılanda o künc
	# də sönür, yəni matçın əsas rəqəmi heç yerdə qalmırdı (design/MODES.md §11
	# onu başlıqda tələb edir).
	if _trio:
		lead = "RAUND HESABI  %d — %d\n%s" % [_score_us, _score_them, lead]

	_result_body.text = "%s\n\nPartlatdığın mikrob: %d\nÇatdığın tutum: %d (səviyyə %d)\nYaşadın: %d:%02d\n\nMenyuya qayıdılır..." % [
		lead,
		int(result.get("pops", 0)),
		int(result.get("cap", Const.START_CAPACITY)),
		int(result.get("level", 1)),
		age / 60, age % 60,
	]
	_result.visible = true


## Matçın göstəriciləri — yalnız matçlı rejimdə çağırılır.
##
## Üç şey deyir: neçəyə başlayır, neçə nəfər qalıb, quru zonadasanmı.
## Üçü də oyunçunun növbəti hərəkətini dəyişir, ona görə üçü də ekrandadır.
## [param us] və [param them] yalnız ÜÇLÜK-də mənalıdır: udulan raund sayı.
func set_match(mode: int, phase: int, phase_t: float, alive: int, drying: bool,
		us := 0, them := 0, round_no := 1) -> void:
	# Nəticə lövhəsi açıqdırsa mərkəzdəki yazı SUSUR.
	#
	# Yoxsa ÜÇLÜK-də növbəti raundun geriyə sayımı nəticə mətninin arxasından
	# görünür və iki mesaj eyni yeri paylaşır.
	if _result.visible:
		hide_message()
	elif phase == Const.Phase.COUNTDOWN:
		# Sayım gedərkən mərkəzdəki HƏR İKİ sətir bu funksiyanındır.
		#
		# Yalnız rəqəmi yazıb alt sətri başqasına buraxsaq, orada əvvəlki
		# mesajın alt yazısı qalır — məsələn doğularkən kola düşən mikroba
		# çıxan "Kolun içində rəqiblər səni görmür" sayımın altında donub
		# qalırdı. Oyunçu isə orada rejimin adını gözləyir.
		var left := int(ceilf(Const.COUNTDOWN_TIME - phase_t))
		_center_lbl.text = str(maxi(left, 1))
		_center_lbl.visible = true
		_sub_lbl.text = "%s · %d mikrob" % [Const.mode_name(mode), alive]
		_sub_lbl.visible = true

	var trio := mode == Const.Mode.TRIO
	_trio = trio
	_score_us = us
	_score_them = them
	_alive_lbl.text = "SAĞ: %d" % alive
	_alive_lbl.visible = phase == Const.Phase.PLAYING and not trio
	# Ayırıcı BOŞLUQ deyil, "·"-dır.
	#
	# `"RAUND %d   %d — %d"` üç boşluqla yazılırdı və bu şriftdə boşluq ~3 px
	# çıxır: ekranda "RAUND1 0 — 0" oxunurdu, yəni raund nömrəsi hesaba
	# yapışırdı. Görünən ayırıcı bunu şriftdən asılı olmaqdan çıxarır.
	_score_lbl.text = "RAUND %d  ·  %d — %d" % [round_no, us, them]
	_score_lbl.visible = trio and phase != Const.Phase.WAITING

	# DÜNYA ƏHALİSİ matçlı rejimdə yazılmır — orada mənalı olan SAĞ SAYIDIR.
	#
	# İkisi yan-yana duranda ekran özü ilə ziddiyyətə düşürdü ("Dünyada 8
	# mikrob" / "SAĞ: 10" — CÜT-də dirilmə gözləyən fərqi), TƏK QALAN-da isə
	# sadəcə eyni rəqəmi iki dəfə yazırdı.
	_pop_lbl.visible = false

	# Quruma xəbərdarlığı burada YAZILMIR — yalnız bayraq qoyulur.
	#
	# [method update_gauge] bu çağırışdan SONRA gəlir və öz xəbərdarlığını
	# yazır. Mətni burada yazsaydıq, o, üstündən silərdi və quruma —
	# rejimin ən ölümcül təhlükəsi — heç vaxt görünməzdi.
	_drying = drying


## Superin göstəricisi. [param charge] 0..1, [param ready] basıla bilərmi.
func set_super(charge: float, ready: bool) -> void:
	super_button.set_charge(charge, ready)


func release_sticks() -> void:
	move_stick.cancel()
	fire_button.cancel()
	super_button.release()
