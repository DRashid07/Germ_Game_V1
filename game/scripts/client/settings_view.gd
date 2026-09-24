class_name SettingsView
extends Control
## AYARLAR ekranı — YALNIZ menyuda.
##
## ── Niyə tam ekran, niyə üç sütun ───────────────────────────────────────
##
## Əvvəl ayarlar dişlinin altından düşən kiçik panel idi və içində cəmi iki
## şey vardı: qrafika düyməsi və server ünvanı. Müasir mobil oyunda ayarlar
## AYRI EKRANDIR (Brawl Stars, Clash Royale, Standoff) — səbəb sadədir:
## açılan panel oyunun üstündə üzür, yəni böyüyə bilmir, sürüşdürülə bilmir
## və barmağın altında qalan hər piksel arxadakı düymələrlə mübahisə edir.
##
## Sütunlar YATAY ekranın nəticəsidir. 1280×720-də bir sütunluq siyahı
## ekranın üçdə birini tutub qalanını boş qoyardı və oyunçunu sürüşdürməyə
## məcbur edərdi. Üç sütun HAMISINI bir kadra yığır: səs · görüntü · idarə.
##
## ── Niyə matçın içində yoxdur ───────────────────────────────────────────
##
## Əvvəl eyni ekran matçda da açılırdı (dişli + "MATÇI TƏRK ET"). Brawl
## Stars-da döyüşdə heç bir sistem düyməsi yoxdur — ayarlar ana ekrandadır.
## Matçdan çıxış isə ayrı, kiçik bir təsdiqdir (bax [signal Hud.leave_confirmed]).

signal closed()

const PAD := 34.0
const TITLE_H := 52.0
const FOOT_H := 52.0
const COL_GAP := 22.0
## Sürüşən açarın qutusu — zolağın eni × hündürlüyü.
const SWITCH := Vector2(76.0, 40.0)

## Keyfiyyət zolağının düymələri və server sahəsi — QA agenti ([PlayAgent])
## ekranı insan kimi sürür və bunlara basmalıdır. Ad tapmaqla axtarsaydı,
## yazını dəyişən hər düzəliş testi səssizcə sındırardı.
var quality_seg: Array[Button] = []
var addr_edit: LineEdit
var back_btn: Button

var _cols: HBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Örtük arxadakı hər şeyi TUTUR: menyunun kartlarına təsadüfən basılmamalıdır.
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	# TAM örtür. 0.97 sınandı və az idi: OYNA düyməsinin doymuş rəngi,
	# qəhrəman və dişli 3 faizdən keçib ayarların arxasında oxunurdu — ekran
	# iki interfeysin üst-üstə düşməsi kimi görünürdü.
	dim.color = Palette.BG_OUTER
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	var title := Hud._make_label(40, Palette.TEXT)
	ChunkyBox.stroke(title, 8, true)
	title.theme_type_variation = "Heading"
	title.text = "AYARLAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 26.0
	title.offset_bottom = 26.0 + TITLE_H
	add_child(title)

	_cols = HBoxContainer.new()
	_cols.add_theme_constant_override("separation", int(COL_GAP))
	_cols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cols.offset_left = PAD
	_cols.offset_right = -PAD
	_cols.offset_top = 26.0 + TITLE_H + 12.0
	_cols.offset_bottom = -(PAD + FOOT_H + 14.0)
	add_child(_cols)

	_build_footer()
	_rebuild()

	# Giriş: örtük aşağıdan qalxır. Qısa (0.18 s) — ayarlar tez-tez açılır və
	# uzun animasiya ikinci dəfədən sonra əngələ çevrilir.
	modulate.a = 0.0
	var t := create_tween()
	t.parallel().tween_property(self, "modulate:a", 1.0, 0.16)
	_cols.position.y += 26.0
	t.parallel().tween_property(_cols, "position:y", _cols.position.y - 26.0, 0.22) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## Klaviaturada ESC, Android-də isə sistemin GERİ düyməsi.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close()


func close() -> void:
	closed.emit()
	queue_free()


# ---------------------------------------------------------------- sütunlar

func _rebuild() -> void:
	for child in _cols.get_children():
		child.queue_free()
	quality_seg.clear()
	addr_edit = null
	_build_audio_column()
	_build_video_column()
	_build_control_column()


func _build_audio_column() -> void:
	var box := _column("SƏS")

	# Nümunə klip HƏMİN sürgünün şinindən seçilir (bax [method _slider_row]):
	# "İnterfeys" sürgüsü `SFX` şinindən səs çalsaydı, oyunçu çəkdiyi sürgünün
	# nəyə təsir etdiyini eşitməzdi.
	_slider_row(box, "Ümumi səs", Settings.master, "blunk", func(v: float) -> void:
		Settings.master = v
		# Sürüşdürərkən yalnız TƏTBİQ olunur, diskə yazılmır: barmaq bir dəfə
		# çəkiləndə onlarla kadr keçir və hər kadrda fayl yazmaq mənasızdır.
		Settings.apply())
	_slider_row(box, "Effektlər", Settings.sfx, "blunk", func(v: float) -> void:
		Settings.sfx = v
		Settings.apply())
	_slider_row(box, "İnterfeys", Settings.ui, "ui_click", func(v: float) -> void:
		Settings.ui = v
		Settings.apply())

	_gap(box, 6)
	_switch_row(box, "Səssiz rejim", Settings.muted, func(on: bool) -> void:
		Settings.muted = on
		Settings.commit())

	var note := Hud._make_label(13, Palette.TEXT_MUTED)
	note.text = "Kliplərin öz tarazlığı qorunur — sürgü hamısını bərabər çəkir."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)


func _build_video_column() -> void:
	var box := _column("QRAFİKA")

	quality_seg = _segment_row(box, "Keyfiyyət", ["YÜKSƏK", "AŞAĞI"], int(Net.quality),
		func(i: int) -> void:
			Net.quality = Const.quality_from(i)
			Settings.commit())

	_segment_row(box, "Kadr həddi", Settings.FPS_NAMES,
		maxi(Settings.FPS_CAPS.find(Settings.fps_cap), 0),
		func(i: int) -> void:
			Settings.fps_cap = Settings.FPS_CAPS[i]
			Settings.commit())

	_segment_row(box, "Ekran silkələnməsi", Settings.SHAKE_NAMES,
		_nearest_shake(Settings.shake),
		func(i: int) -> void:
			Settings.shake = Settings.SHAKE_LEVELS[i]
			Settings.commit())

	_gap(box, 4)
	_switch_row(box, "Kadr sayğacı (FPS)", Settings.show_fps, func(on: bool) -> void:
		Settings.show_fps = on
		Settings.commit())

	var note := Hud._make_label(13, Palette.TEXT_MUTED)
	note.text = "AŞAĞI: işıq effektləri sönür. Oyuna təsiri yoxdur."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(note)


func _build_control_column() -> void:
	var box := _column("İDARƏ")

	_switch_row(box, "Sol əl düzümü", Settings.left_handed, func(on: bool) -> void:
		Settings.left_handed = on
		Settings.commit())
	var lnote := Hud._make_label(13, Palette.TEXT_MUTED)
	lnote.text = "Joystick sağa, atəş və super sola keçir."
	lnote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(lnote)

	_gap(box, 6)
	_switch_row(box, "Titrəmə", Settings.haptics, func(on: bool) -> void:
		Settings.haptics = on
		Settings.commit()
		if on:
			# Yandırılan kimi bir dəfə titrəyir — ayarın işlədiyi elə buradan
			# bilinir, oyunun içində sınamağa ehtiyac qalmır.
			Settings.vibrate(40))
	var hnote := Hud._make_label(13, Palette.TEXT_MUTED)
	hnote.text = "Yalnız telefonda: zərbə, super və partlayış."
	hnote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(hnote)

	_gap(box, 10)

	var caption := Hud._make_label(17, Palette.TEXT_MUTED)
	caption.text = "Server ünvanı"
	box.add_child(caption)

	addr_edit = LineEdit.new()
	addr_edit.text = Settings.address
	addr_edit.custom_minimum_size.y = 44
	addr_edit.add_theme_font_size_override("font_size", 16)
	addr_edit.add_theme_color_override("font_color", Palette.TEXT)
	addr_edit.text_changed.connect(func(t: String) -> void:
		Settings.address = t
		Settings.save())
	box.add_child(addr_edit)

	_gap(box, 6)

	var reset := Button.new()
	reset.text = "AYARLARI SIFIRLA"
	reset.custom_minimum_size.y = 52
	reset.add_theme_font_size_override("font_size", 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		reset.add_theme_color_override(state, Palette.TEXT)
	# Narıncı — geri qaytarılmayan əməlin rəngi. Yazı ağdır və konturludur:
	# narıncı üstündə narıncı yazı oxunmurdu.
	ChunkyBox.stroke(reset, 5, true)
	ChunkyBox.apply(reset, Palette.WARNING.darkened(0.12), 12.0, 6.0)
	reset.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		Settings.reset()
		# Sıfırlama HƏR dəyəri dəyişir, ona görə ekran yenidən qurulur —
		# sürgüləri və açarları bir-bir yeniləmək eyni işin uzun yoludur.
		_rebuild())
	box.add_child(reset)

	var ver := Hud._make_label(13, Palette.TEXT_MUTED)
	var gv := Engine.get_version_info()
	ver.text = "Germ Arena %s · Godot %d.%d.%d" % [
		str(ProjectSettings.get_setting("application/config/version", "—")),
		gv.get("major", 0), gv.get("minor", 0), gv.get("patch", 0)]
	box.add_child(ver)


## Sürüşdürmə dəyəri ilə ən yaxın pilləni tapır.
##
## Ayar faylı əl ilə redaktə oluna bilər (məsələn 0.7), seçim isə üç pillədir —
## yaxını seçilməsə heç bir düymə işıqlanmazdı və ekran sınıq görünərdi.
static func _nearest_shake(v: float) -> int:
	var best := 0
	for i in Settings.SHAKE_LEVELS.size():
		if absf(Settings.SHAKE_LEVELS[i] - v) < absf(Settings.SHAKE_LEVELS[best] - v):
			best = i
	return best


# ---------------------------------------------------------------- parçalar

## Bir sütun: panel + başlıq + sürüşdürülə bilən məzmun.
##
## Sürüşmə ehtiyat üçündür: 1280×720-də hər şey sığır, amma alçaq pəncərədə
## (və ya gələcəkdə bir sətir əlavə olunanda) sonuncu sətir kəsilməməlidir.
func _column(title: String) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _panel_style())
	_cols.add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	scroll.add_child(box)

	var head := Hud._make_label(24, Palette.GERM_COLORS[1])
	ChunkyBox.stroke(head, 5, true)
	head.theme_type_variation = "Heading"
	head.text = title
	box.add_child(head)

	return box


func _gap(box: VBoxContainer, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = h
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(s)


## Ad + faiz + sürgü. Faiz sağdadır, çünki göz onu sürgünün SONUNDA axtarır.
##
## [param preview] barmaq qalxanda çalınan klipdir və HƏMİN sürgünün şinindən
## olmalıdır — səviyyə rəqəmlə yox, QULAQLA seçilir.
func _slider_row(box: VBoxContainer, title: String, value: float,
		preview: String, on_change: Callable) -> void:
	var head := HBoxContainer.new()
	box.add_child(head)

	var name_lbl := Hud._make_label(17, Palette.TEXT)
	name_lbl.text = title
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(name_lbl)

	var pct := Hud._make_label(17, Palette.TEXT_MUTED)
	pct.text = "%d%%" % roundi(value * 100.0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(pct)

	var slider := TouchSlider.new()
	slider.set_value_silent(value)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % roundi(v * 100.0)
		on_change.call(v))
	slider.released.connect(func(_v: float) -> void:
		Settings.save()
		# Buraxılanda bir nümunə səs: oyunçu səviyyəni EŞİDİR, rəqəmə baxmır.
		# Sürüşdürərkən çalınsaydı, hər kadrda bir klip düşərdi.
		Sfx.play(preview))
	box.add_child(slider)


## Seçim zolağı — iki-dörd variant yan-yana.
##
## Növbə ilə keçən tək düymə DEYİL (əvvəlki QRAFİKA düyməsi belə idi): orada
## oyunçu qalan variantları görmür və neçə dəfə basmalı olduğunu bilmir.
func _segment_row(box: VBoxContainer, title: String, options: Array,
		current: int, on_pick: Callable) -> Array[Button]:
	var name_lbl := Hud._make_label(17, Palette.TEXT)
	name_lbl.text = title
	box.add_child(name_lbl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)

	var buttons: Array[Button] = []
	for i in options.size():
		var b := Button.new()
		b.text = str(options[i])
		b.custom_minimum_size.y = 42
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.add_child(b)
		buttons.append(b)

	_paint_segment(buttons, current)

	for i in buttons.size():
		var idx := i
		buttons[i].pressed.connect(func() -> void:
			Sfx.play("ui_click")
			_paint_segment(buttons, idx)
			on_pick.call(idx))

	return buttons


## Seçilmiş pillə parlaq mavidir, qalanları tünd — Brawl Stars ayarlarının
## düymə dili (bax [ChunkyBox]). Seçim həm rəngdən, həm də dodağın
## qalınlığından oxunur: seçilən "qalxıb", qalanları yastıdır.
static func _paint_segment(buttons: Array[Button], current: int) -> void:
	for i in buttons.size():
		var on := i == current
		var face := Palette.MENU_BLUE if on else Palette.MENU_PANEL.lightened(0.08)
		ChunkyBox.apply(buttons[i], face, 10.0, 6.0 if on else 3.0)
		ChunkyBox.stroke(buttons[i], 4 if on else 0)
		var col := Palette.TEXT if on else Palette.TEXT_MUTED
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			buttons[i].add_theme_color_override(state, col)


## Ad + sürüşən açar. AÇIQ/QAPALI yazısı yoxdur: açarın yeri və rəngi onsuz da
## vəziyyəti deyir, yazı isə iki dildə iki fərqli enə düşür və sütunu dartır.
func _switch_row(box: VBoxContainer, title: String, on: bool,
		on_toggle: Callable) -> void:
	var row := HBoxContainer.new()
	box.add_child(row)

	var name_lbl := Hud._make_label(17, Palette.TEXT)
	name_lbl.text = title
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name_lbl)

	var b := Button.new()
	b.custom_minimum_size = SWITCH
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var knob := Panel.new()
	knob.size = Vector2(SWITCH.y - 10.0, SWITCH.y - 10.0)
	knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(knob)

	b.set_meta("on", on)
	_paint_switch(b, on, false)
	b.pressed.connect(func() -> void:
		var v: bool = not bool(b.get_meta("on"))
		b.set_meta("on", v)
		_paint_switch(b, v, true)
		Sfx.play("ui_click")
		on_toggle.call(v))
	row.add_child(b)


static func _paint_switch(b: Button, on: bool, animate: bool) -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(Palette.GERM_COLORS[0], 0.18) if on else Color(Palette.PANEL, 0.9)
	track.border_color = Palette.GERM_COLORS[0] if on else Palette.PANEL_BORDER
	track.set_border_width_all(2)
	track.set_corner_radius_all(int(SWITCH.y * 0.5))
	for state in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(state, track)

	var knob := b.get_child(0) as Panel
	var ks := StyleBoxFlat.new()
	ks.bg_color = Palette.GERM_COLORS[0] if on else Palette.TEXT_MUTED
	ks.set_corner_radius_all(int((SWITCH.y - 10.0) * 0.5))
	knob.add_theme_stylebox_override("panel", ks)

	var rest := Vector2(5.0, 5.0)
	var to := Vector2(SWITCH.x - SWITCH.y + 5.0, 5.0) if on else rest
	if animate:
		var t := knob.create_tween()
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(knob, "position", to, 0.16)
	else:
		knob.position = to


# ---------------------------------------------------------------- alt zolaq

func _build_footer() -> void:
	back_btn = Button.new()
	back_btn.text = "‹ GERİ"
	back_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back_btn.offset_left = PAD
	back_btn.offset_right = PAD + 170.0
	back_btn.offset_top = -(PAD + FOOT_H)
	back_btn.offset_bottom = -PAD
	back_btn.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back_btn.add_theme_color_override(state, Palette.TEXT)
	# Menyunun vərəqlərindəki GERİ ilə EYNİ düymə — ayarlar menyunun bir
	# hissəsidir, ayrı proqram kimi görünməməlidir.
	ChunkyBox.stroke(back_btn, 6, true)
	ChunkyBox.apply(back_btn, Palette.MENU_BLUE, 14.0, 6.0)
	back_btn.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		close())
	add_child(back_btn)
	_squash(back_btn, Vector2(170.0, FOOT_H))


## Basılanda əzilmə — menyudakı ilə eyni jest.
##
## [method MenuV2._squash] çağırılmır, baxmayaraq ki, kod eynidir: menyu bu
## ekranı yaradır; bu ekran da menyunu göstərsəydi, iki sinif bir-birini
## çağırardı və Godot dövrəvi asılılığı həll edə bilmir.
static func _squash(b: Button, box: Vector2) -> void:
	b.pivot_offset = box * 0.5
	b.button_down.connect(func() -> void:
		b.create_tween().tween_property(b, "scale", Vector2.ONE * 0.94, 0.06))
	b.button_up.connect(func() -> void:
		var t := b.create_tween()
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "scale", Vector2.ONE, 0.16))


## Sütun paneli — menyunun məlumat panelləri ilə eyni: qalın kontur, dodaqsız,
## parıltısız (bax [method MenuV2._info_style]).
static func _panel_style() -> ChunkyBox:
	var sb := ChunkyBox.make(Palette.MENU_PANEL, false, 16.0, 0.0)
	sb.gloss = 0.0
	sb.set_content_margin_all(4.0)
	return sb
