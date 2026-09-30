class_name FriendsView
extends Control
## DOSTLAR ekranı — Brawl Stars-ın Friends pəncərəsinin qarşılığı.
##
##   sol     SƏNİN KODUN (kopyala / paylaş) · DOST ƏLAVƏ ET · KOMANDA
##   sağ     DOSTLAR · SORĞULAR · SON OYUNÇULAR — üç tab, bir siyahı
##   aşağı   ‹ GERİ (menyunun bütün vərəqləri kimi)
##
## Ekran heç nəyi özü saxlamır: hər şey [Friends]-dədir və o dəyişəndə
## ([signal Friends.changed]) siyahı yenidən qurulur. Siyahılar kiçikdir (ən
## çox 100 dost), ona görə hər dəfə sıfırdan qurmaq ucuzdur və "köhnə sətir
## qaldı" tipli səhvləri kökündən bağlayır.
##
## Ana ekrandakı «+» yuvası bu ekranı DƏVƏT rejimində açır ([member invite_mode]):
## siyahı eynidir, sadəcə başlıq "komandaya dəvət et" deyir — oyunçu niyə
## burada olduğunu bilsin.

signal closed()

const PAD := 34.0
const TITLE_H := 52.0
const FOOT_H := 52.0
const LEFT_W := 420.0
const ROW_H := 66.0

const ICON_ADD := "res://assets/menu/icon_add_friend.png"
const ICON_LINK := "res://assets/menu/icon_link.png"
const ICON_CROWN := "res://assets/menu/icon_crown.png"
const ICON_INVITE := "res://assets/menu/icon_invite.png"
const ICON_FRIENDS := "res://assets/menu/icon_friends.png"
const HEROES := {
	Const.Species.CILIATE: "res://assets/menu/hero_ciliate.png",
	Const.Species.HELIOZOAN: "res://assets/menu/hero_heliozoan.png",
	Const.Species.AMOEBA: "res://assets/menu/hero_amoeba.png",
}

enum Tab { FRIENDS, REQUESTS, RECENT }

var tab := Tab.FRIENDS
var invite_mode := false
## Linkdən gələn dost kodu — sahəyə yazılır, göndərmək oyunçunun öz qərarıdır.
var prefill := ""

## QA agenti və testlər üçün açıq saxlanılır.
var tag_edit: LineEdit
var code_edit: LineEdit
var back_btn: Button

var _left: VBoxContainer
var _list: VBoxContainer
var _tabs: Array[Button] = []
var _title: Label
## İkinci toxunuşla silmə — təsadüfi basış dostu itirməsin.
var _arm_remove := ""
## Sol sütunun son qurulduğu vəziyyət. Sütun YALNIZ komanda dəyişəndə
## yenidən qurulur: dostların vəziyyəti hər dəqiqə dəyişir və hər dəfə
## qursaydıq, oyunçu kodu yazarkən sahə silinib yenidən yaranardı — telefonda
## klaviatura yazının ortasında bağlanardı.
var _left_key := "-"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Palette.BG_OUTER
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_title = Hud._make_label(40, Palette.TEXT)
	ChunkyBox.stroke(_title, 8, true)
	_title.theme_type_variation = "Heading"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 22.0
	_title.offset_bottom = 22.0 + TITLE_H
	add_child(_title)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	cols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cols.offset_left = PAD
	cols.offset_right = -PAD
	cols.offset_top = 22.0 + TITLE_H + 10.0
	cols.offset_bottom = -(PAD + FOOT_H + 14.0)
	add_child(cols)

	_left = _panel(cols, LEFT_W, false)
	var right := _panel(cols, 0.0, true)

	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	right.add_child(tabs)
	for t in [Tab.FRIENDS, Tab.REQUESTS, Tab.RECENT]:
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 46)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 19)
		ChunkyBox.stroke(b, 5, true)
		b.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			tab = t
			_arm_remove = ""
			_rebuild())
		tabs.add_child(b)
		_tabs.append(b)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	_build_footer()
	# Cavab gözləyən sorğu varsa, ekran onunla açılır: oyunçu məhz ona görə
	# gəlib (qırmızı nişan onu bura gətirib).
	if not invite_mode and (not Friends.requests.is_empty() or not Friends.invites.is_empty()):
		tab = Tab.REQUESTS
	Friends.changed.connect(_rebuild)
	_rebuild()

	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.16)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		close()


func close() -> void:
	closed.emit()
	queue_free()


# ================================================================ qurma

func _rebuild() -> void:
	if not is_inside_tree():
		return
	_title.text = "KOMANDAYA DƏVƏT ET" if invite_mode else "DOSTLAR"
	var key := Friends.my_tag + str(Friends.party)
	if key != _left_key:
		_left_key = key
		var keep_tag := tag_edit.text if tag_edit != null else prefill
		var keep_code := code_edit.text if code_edit != null else ""
		for c in _left.get_children():
			c.queue_free()
		_build_left(keep_tag, keep_code)
		prefill = ""

	var names := [
		"DOSTLAR %d/%d" % [Friends.online_count(), Friends.friends.size()],
		"SORĞULAR" + (" (%d)" % Friends.badge_count() if Friends.badge_count() > 0 else ""),
		"SON OYUNÇULAR",
	]
	for i in _tabs.size():
		_tabs[i].text = names[i]
		var on := i == int(tab)
		ChunkyBox.apply(_tabs[i], Palette.MENU_BLUE if on else Palette.MENU_PANEL.lightened(0.08), 12.0, 5.0)
		_tabs[i].add_theme_color_override("font_color", Palette.TEXT if on else Palette.TEXT_MUTED)

	for c in _list.get_children():
		c.queue_free()
	match tab:
		Tab.FRIENDS: _fill_friends()
		Tab.REQUESTS: _fill_requests()
		Tab.RECENT: _fill_recent()


## Sol sütun: kimlik, əlavə etmə, komanda.
func _build_left(keep_tag: String, keep_code: String) -> void:
	_head(_left, "SƏNİN KODUN")
	var my := Hud._make_label(30, Palette.GERM_COLORS[0])
	my.theme_type_variation = "Heading"
	my.text = "#" + Friends.my_tag
	ChunkyBox.stroke(my, 7, true)
	_left.add_child(my)
	var share_row := HBoxContainer.new()
	share_row.add_theme_constant_override("separation", 10)
	_left.add_child(share_row)
	share_row.add_child(_btn("KOPYALA", Palette.MENU_BLUE, 17, func() -> void:
		_copy("#" + Friends.my_tag, "Oyunçu kodun")))
	share_row.add_child(_btn("PAYLAŞ", Palette.GERM_COLORS[1].darkened(0.35), 17, func() -> void:
		_share("Germ Arena-da məni dost əlavə et!", Friends.share_link_friend()), ICON_LINK))

	_head(_left, "DOST ƏLAVƏ ET")
	var add_row := HBoxContainer.new()
	add_row.add_theme_constant_override("separation", 10)
	_left.add_child(add_row)
	tag_edit = _edit("#OYUNÇU KODU", Social.TAG_LEN + 1)
	tag_edit.text = keep_tag
	var send := func() -> void:
		if Friends.request(tag_edit.text):
			tag_edit.text = ""
	tag_edit.text_submitted.connect(func(_t: String) -> void: send.call())
	add_row.add_child(tag_edit)
	var send_btn := _btn("GÖNDƏR", Palette.SAFE.darkened(0.3), 17, send, ICON_ADD)
	send_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	add_row.add_child(send_btn)

	_head(_left, "KOMANDA")
	if Friends.in_party():
		_build_party_card()
	else:
		var note := Hud._make_label(14, Palette.TEXT_MUTED)
		note.text = "Komanda yarat və kodunu dostuna göndər — və ya onun kodunu yaz."
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_left.add_child(note)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_left.add_child(row)
		code_edit = _edit("KOMANDA KODU", Social.CODE_LEN + 2)
		code_edit.text = keep_code
		code_edit.text_submitted.connect(func(_t: String) -> void: Friends.join_code(code_edit.text))
		row.add_child(code_edit)
		row.add_child(_btn("QOŞUL", Palette.MENU_BLUE, 17, func() -> void:
			Friends.join_code(code_edit.text)))
		var make := _btn("KOMANDA YARAT", Palette.MENU_PLAY.darkened(0.2), 18, func() -> void:
			Friends.open_party())
		make.add_theme_color_override("font_color", Palette.TEXT)
		_left.add_child(make)


## Komanda kartı: kod, üzvlər (lider tacla), çıxmaq/çıxarmaq.
func _build_party_card() -> void:
	code_edit = null
	var code := str(Friends.party.get("code", ""))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_left.add_child(row)
	var lab := Hud._make_label(26, Palette.MENU_PLAY)
	lab.theme_type_variation = "Heading"
	lab.text = code
	lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ChunkyBox.stroke(lab, 6, true)
	row.add_child(lab)
	row.add_child(_btn("KOPYALA", Palette.MENU_BLUE, 15, func() -> void:
		_copy(code, "Komanda kodu")))
	row.add_child(_btn("LİNK", Palette.GERM_COLORS[1].darkened(0.35), 15, func() -> void:
		_share("Germ Arena-da komandama gəl!", Friends.share_link_party()), ICON_LINK))

	var leader := str(Friends.party.get("leader", ""))
	var mode := int(Friends.party.get("mode", 0))
	var info := Hud._make_label(14, Palette.TEXT_MUTED)
	info.text = "%s · %d/%d nəfər" % [Const.mode_name(mode), Friends.party_size(), Social.party_limit(mode)]
	_left.add_child(info)
	for m in Friends.party.get("members", []):
		var mrow := HBoxContainer.new()
		mrow.add_theme_constant_override("separation", 8)
		_left.add_child(mrow)
		var crown := TextureRect.new()
		crown.custom_minimum_size = Vector2(26, 26)
		crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crown.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		crown.texture = load(ICON_CROWN) if str(m[0]) == leader else null
		mrow.add_child(crown)
		var nm := Hud._make_label(18, Palette.TEXT if int(m[4]) != Social.Presence.OFFLINE else Palette.TEXT_MUTED)
		nm.text = str(m[1]) + ("  (sən)" if str(m[0]) == Friends.my_tag else "")
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.clip_text = true
		mrow.add_child(nm)
		var st := Hud._make_label(15, Palette.SAFE if bool(m[3]) else Palette.TEXT_MUTED)
		st.text = "HAZIR ✓" if bool(m[3]) else (
			"oyunda" if int(m[4]) == Social.Presence.GAME else (
			"qopdu…" if int(m[4]) == Social.Presence.OFFLINE else "gözləyir"))
		mrow.add_child(st)
		if Friends.is_leader() and str(m[0]) != Friends.my_tag:
			var tag := str(m[0])
			var kick := _btn("✕", Palette.DANGER.darkened(0.3), 13, func() -> void:
				Friends.kick(tag))
			kick.custom_minimum_size = Vector2(38, 34)
			mrow.add_child(kick)
	_left.add_child(_btn("KOMANDADAN ÇIX", Palette.DANGER.darkened(0.35), 17, func() -> void:
		Friends.leave_party()))


# ---------------------------------------------------------------- siyahılar

func _fill_friends() -> void:
	if Friends.friends.is_empty():
		_empty("Hələ dostun yoxdur.\nKodunu PAYLAŞ və ya dostunun kodunu yaz — o qəbul edəndə burada görünəcək.")
		return
	var in_mine := {}
	for m in Friends.party.get("members", []):
		in_mine[str(m[0])] = true
	var full := Friends.party_size() >= Social.PARTY_MAX
	for t in Friends.sorted_friends():
		var f: Dictionary = Friends.friends[t]
		var p := Friends.status_of(t)
		var row := _row(int(f["species"]), str(f["name"]), _status_line(t, p), _status_color(p))
		if in_mine.has(t):
			row.add_child(_tag_label("KOMANDADA", Palette.SAFE))
		elif p == Social.Presence.MENU or p == Social.Presence.PARTY:
			# Yaşıl, sarı yox: ekranın sarısı yalnız OYNA-nındır (bax [MenuV2]).
			var b := _btn("DƏVƏT ET", Palette.SAFE.darkened(0.25), 17, func() -> void:
				Friends.invite(t), ICON_INVITE)
			b.disabled = full
			row.add_child(b)
		# Silmə — iki toxunuşla. Birinci "SİL?" deyir, ikinci silir.
		var armed := _arm_remove == t
		var rm := _btn("SİL?" if armed else "✕", Palette.DANGER.darkened(0.2 if armed else 0.45), 15,
			func() -> void:
				if _arm_remove == t:
					_arm_remove = ""
					Friends.remove(t)
				else:
					_arm_remove = t
					_rebuild())
		row.add_child(rm)


func _fill_requests() -> void:
	if Friends.requests.is_empty() and Friends.invites.is_empty():
		_empty("Cavab gözləyən sorğu yoxdur.")
		return
	for t in Friends.invites:
		var inv: Dictionary = Friends.invites[t]
		var row := _row(-1, str(inv["name"]),
			"səni komandasına çağırır · %s" % Const.mode_name(int(inv["mode"])), Palette.MENU_PLAY, ICON_INVITE)
		row.add_child(_btn("QƏBUL", Palette.SAFE.darkened(0.25), 17, func() -> void:
			Friends.answer_invite(t, true)))
		row.add_child(_btn("✕", Palette.DANGER.darkened(0.3), 15, func() -> void:
			Friends.answer_invite(t, false)))
	for t in Friends.requests:
		var row := _row(-1, str(Friends.requests[t]), "#%s · dost olmaq istəyir" % t, Palette.TEXT_MUTED)
		row.add_child(_btn("QƏBUL", Palette.SAFE.darkened(0.25), 17, func() -> void:
			Friends.answer(t, true)))
		row.add_child(_btn("✕", Palette.DANGER.darkened(0.3), 15, func() -> void:
			Friends.answer(t, false)))


## Birlikdə oynadığın insanlar — Brawl Stars-da döyüş jurnalından dost
## əlavə etmək kimi. Botlar buraya düşmür: onların kodu yoxdur.
func _fill_recent() -> void:
	if Friends.recent.is_empty():
		_empty("Onlayn matçda rastlaşdığın oyunçular burada görünəcək.")
		return
	var now := Time.get_unix_time_from_system()
	for r in Friends.recent:
		var t := str(r[0])
		var row := _row(-1, str(r[1]), "#%s · %s" % [t, Social.ago(now - float(r[2]))], Palette.TEXT_MUTED,
			ICON_FRIENDS)
		if Friends.friends.has(t):
			row.add_child(_tag_label("DOSTDUR", Palette.SAFE))
		elif Friends.sent.has(t):
			row.add_child(_tag_label("GÖNDƏRİLDİ", Palette.TEXT_MUTED))
		else:
			row.add_child(_btn("+ DOST", Palette.SAFE.darkened(0.3), 17, func() -> void:
				Friends.request(t), ICON_ADD))


func _status_line(tag: String, p: int) -> String:
	if p != Social.Presence.OFFLINE:
		return Social.presence_name(p)
	var seen := float(Friends.friends[tag].get("seen", 0.0))
	if seen <= 0.0:
		return "#%s · oflayn" % tag
	return "Oflayn · %s" % Social.ago(Time.get_unix_time_from_system() - seen)


static func _status_color(p: int) -> Color:
	match p:
		Social.Presence.MENU: return Palette.SAFE
		Social.Presence.PARTY: return Palette.GERM_COLORS[1]
		Social.Presence.GAME: return Palette.WARNING
		_: return Palette.TEXT_MUTED


# ---------------------------------------------------------------- paylaşma

## Mətni buferə yazır. Veb-də brauzer bunu yalnız toxunuşun ardınca icazə
## verir — düymə basılan kadrda çağırıldığı üçün icazə var.
func _copy(text: String, what: String) -> void:
	DisplayServer.clipboard_set(text)
	Friends.notice.emit("KOPYALANDI", "%s: %s" % [what, text], "ok")


## Telefonun brauzerində sistemin PAYLAŞ pəncərəsi (WhatsApp, Telegram…);
## olmayan yerdə link buferə yazılır.
func _share(text: String, url: String) -> void:
	if OS.has_feature("web"):
		var ok = JavaScriptBridge.eval(
			"(function(){ if (navigator.share) { navigator.share({title: 'Germ Arena', text: %s, url: %s}).catch(function(){}); return true; } return false; })()"
			% [JSON.stringify(text), JSON.stringify(url)])
		if ok == true:
			return
	_copy(url, "Link")


# ---------------------------------------------------------------- parçalar

func _panel(parent: Control, width: float, grow: bool) -> VBoxContainer:
	var panel := PanelContainer.new()
	if grow:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		panel.custom_minimum_size.x = width
	var sb := ChunkyBox.make(Palette.MENU_PANEL, false, 16.0, 0.0)
	sb.gloss = 0.0
	sb.set_content_margin_all(16.0)
	panel.add_theme_stylebox_override("panel", sb)
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	if grow:
		panel.add_child(box)
		return box
	# Sol sütun SÜRÜŞÜR: üç nəfərlik komanda kartı ilə birlikdə 720 px-ə
	# sığmırdı və panel GERİ düyməsinin üstünə daşırdı. Sürüşmə olmasa, sütunun
	# minimum hündürlüyü bütün sırani da aşağı itələyirdi.
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	return box


func _head(box: VBoxContainer, text: String) -> void:
	var head := Hud._make_label(21, Palette.GERM_COLORS[1])
	ChunkyBox.stroke(head, 5, true)
	head.theme_type_variation = "Heading"
	head.text = text
	box.add_child(head)


func _gap(box: VBoxContainer, h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size.y = h
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(s)


func _empty(text: String) -> void:
	var l := Hud._make_label(18, Palette.TEXT_MUTED)
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(300, 0)
	_list.add_child(l)


## Siyahı sətri: avatar, ad, vəziyyət; düymələri çağıran sona əlavə edir.
## [param species] -1 olanda avatar əvəzinə [param icon] çıxır (yad oyunçu —
## növü bilinmir).
func _row(species: int, title: String, sub: String, sub_color: Color, icon := ICON_ADD) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = ROW_H
	var sb := ChunkyBox.make(Palette.MENU_PANEL.lightened(0.07), false, 12.0, 0.0)
	sb.gloss = 0.0
	sb.outline_w = 2.0
	sb.set_content_margin_all(8.0)
	panel.add_theme_stylebox_override("panel", sb)
	_list.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(48, 48)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tsb := ChunkyBox.make(Palette.MENU_BLUE, false, 10.0, 0.0)
	tsb.gloss = 0.0
	tsb.outline_w = 2.0
	tsb.set_content_margin_all(3.0)
	tile.add_theme_stylebox_override("panel", tsb)
	row.add_child(tile)
	var av := TextureRect.new()
	av.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	av.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	av.texture = load(HEROES[Const.species_from(species)]) if species >= 0 else load(icon)
	tile.add_child(av)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	var nm := Hud._make_label(21, Palette.TEXT)
	nm.theme_type_variation = "Heading"
	nm.text = title
	nm.clip_text = true
	ChunkyBox.stroke(nm, 5, true)
	col.add_child(nm)
	var st := Hud._make_label(14, sub_color)
	st.text = sub
	st.clip_text = true
	col.add_child(st)
	return row


func _tag_label(text: String, color: Color) -> Label:
	var l := Hud._make_label(16, color)
	l.theme_type_variation = "Heading"
	l.text = text
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


func _edit(placeholder: String, max_len: int) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.max_length = max_len
	e.custom_minimum_size = Vector2(0, 46)
	e.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e.add_theme_font_size_override("font_size", 20)
	e.add_theme_color_override("font_color", Palette.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG_OUTER
	sb.border_color = Palette.OUTLINE
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	e.add_theme_stylebox_override("normal", sb)
	var focus := sb.duplicate() as StyleBoxFlat
	focus.border_color = Palette.GERM_COLORS[1]
	e.add_theme_stylebox_override("focus", focus)
	return e


func _btn(text: String, face: Color, font: int, action: Callable, icon := "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 46)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", font)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, Palette.TEXT)
	ChunkyBox.stroke(b, 5, true)
	ChunkyBox.apply(b, face, 12.0, 5.0)
	if not icon.is_empty():
		# `expand_icon` YOX: onda ikon mətndən qalan boşluğa sığdırılır və dar
		# düymədə sıfıra düşürdü — düymə ikonsuz görünürdü.
		b.icon = load(icon)
		b.add_theme_constant_override("icon_max_width", 28)
		b.add_theme_constant_override("h_separation", 6)
	b.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		action.call())
	SettingsView._squash(b, Vector2(120, 46))
	return b


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
	ChunkyBox.stroke(back_btn, 6, true)
	ChunkyBox.apply(back_btn, Palette.MENU_BLUE, 14.0, 6.0)
	back_btn.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		close())
	add_child(back_btn)
	SettingsView._squash(back_btn, Vector2(170.0, FOOT_H))
