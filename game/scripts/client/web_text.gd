class_name WebText
extends Control
## Telefon brauzerində yazı sahəsi — HTML pəncərəsi ilə (bax `game/web/shell.html`, `germText`).
##
## ── Niyə ─────────────────────────────────────────────────────────────────
## Godot brauzerdə yazı sahəsi fokus alanda gizli bir HTML elementini 100 ms-dən bir
## `focus()` edir (mühərrikin `GodotIME`-si). Android Chrome toxunuşdan sonrakı bir
## neçə saniyə buna icazə verir və klaviaturanı açır. iOS isə (Safari də, iOS-dakı
## Chrome da WebKit-dir) klaviaturanı YALNIZ toxunuş hadisəsinin İÇİNDƏ fokuslanan
## sahə üçün açır, taymerdən gələn fokusa yox. Nəticə: iPhone-da dost kodu, ad,
## komanda kodu — heç nə yazıla bilmirdi.
##
## ── Necə ─────────────────────────────────────────────────────────────────
## Telefon brauzerində sahənin ÜSTÜNÜ bu şəffaf qat örtür və toxunuşu özü tutur:
## [LineEdit] toxunuşu heç görmür. Fokus olmasa da Godot 4.7-nin LineEdit-i basılanda
## "redaktə" halına keçib gizli elementi işə salırdı (brauzerdə yoxlanıb) — o isə fokusu
## 100 ms-dən bir özünə çəkib HTML pəncərəsinin klaviaturasını bağlayırdı. Toxunuş qata
## düşəndə [method _on_gui_input] JS-ə "bu sahə basıldı"
## deyir; barmaq qalxanda (`touchend` — iOS-un icazə verdiyi an) brauzer öz <input>-unu
## ekranın yuxarısında açır və klaviatura çıxır. Yazı bitəndə nəticə buraya qayıdır:
## mətn sahəyə yazılır, [signal LineEdit.text_changed] və GÖNDƏR/Enter-də
## [signal LineEdit.text_submitted] buraxılır — ekranların öz məntiqi dəyişmir.
##
## Android də eyni yoldan gedir: iki platformada eyni davranış, üstəlik böyük sahə və
## "Yapışdır". Masaüstü brauzerdə və native build-lərdə (APK, Windows) heç nə dəyişmir.

## Bundan köhnə nəticə atılır (məs. pəncərə açıq ikən ekran dəyişib, sahə yoxa çıxıb).
const RESULT_MAX_AGE_MS := 2000.0

## Hər açar üçün ekranda neçə canlı sahə var. Dostlar ekranı siyahı yenilənəndə sol
## sütunu YENİDƏN qurur — sahə silinib eyni açarla dərhal yenisi yaranır. Pəncərə o
## halda bağlanmamalıdır, yalnız açarın heç bir sahəsi qalmayanda.
static var _live := {}
## Telefon/planşet brauzeridirmi (bax [method enabled]): -1 — hələ soruşulmayıb.
static var _on := -1

var edit: LineEdit
var key := ""
var cfg := {}
var _js: JavaScriptObject = null


## Telefon/planşet brauzeridirmi — yalnız orada HTML pəncərəsi lazımdır.
##
## iPadOS Safari özünü "Macintosh" kimi təqdim edir və Godot onu `web_ios` saymır
## (`web_macos` sayır) — toxunuş nöqtələri olan "Mac" əslində iPad-dır.
static func enabled() -> bool:
	if _on < 0:
		var phone: bool = OS.has_feature("web_android") or OS.has_feature("web_ios") \
			or (OS.has_feature("web_macos")
				and JavaScriptBridge.eval("navigator.maxTouchPoints > 1", true) == true)
		# Köhnə shell (brauzer keşində qalıb) `germText` bilmir — onda Godot-un öz yolu qalır.
		_on = 1 if phone and JavaScriptBridge.get_interface("germText") != null else 0
	return _on == 1


## [param field] sahəsini HTML pəncərəsinə bağlayır. [param key] — sahənin MƏNASI
## ("nick", "friend_tag"…): eyni mənalı sahə yenidən qurulanda nəticə yenisinə gedir.
## [param options]: `title`, `placeholder`, `ok`, `hint`, `upper` (böyük hərflər),
## `enter` (klaviaturanın Enter düyməsi: done/send/go), `inputmode` (text/url).
static func attach(field: LineEdit, field_key: String, options := {}) -> void:
	if not enabled() or field == null:
		return
	var w := WebText.new()
	w.edit = field
	w.key = field_key
	w.cfg = options
	w.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	w.mouse_filter = Control.MOUSE_FILTER_STOP
	w.mouse_default_cursor_shape = Control.CURSOR_IBEAM
	w.focus_mode = Control.FOCUS_NONE
	field.add_child(w)


## Kopyala / paylaş düyməsi telefon brauzerində (bax `germText.armAction` shell.html-də).
##
## iOS panoya yazmağa və paylaşma pəncərəsinə də yalnız toxunuşun İÇİNDƏ icazə verir.
## Godot-un `clipboard_set`-i kadr dövründən gəlir — iPhone-da susaraq uğursuz olurdu, oyun
## isə "KOPYALANDI" yazırdı; `navigator.share` heç nə açmırdı. İndi düymə BASILANDA (barmaq
## hələ ekrandadır) tapşırıq silahlanır, barmaq qalxanda brauzer özü icra edir.
## [param make] — tapşırıq: `{"action": "copy"|"share", "text", "title", "url"}`.
## [param done] — `done(ok: bool, how: String)`, how: copied | shared | cancelled.
## Telefonda düymənin öz `pressed` əməli kopyalamamalıdır (bax [method enabled]).
static func attach_action(button: BaseButton, action_key: String, make: Callable,
		done: Callable) -> void:
	if not enabled() or button == null:
		return
	var hook := ActionHook.new()
	hook.button = button
	hook.key = action_key
	hook.make = make
	hook.done = done
	button.add_child(hook)


class ActionHook extends Node:
	var button: BaseButton
	var key := ""
	var make: Callable
	var done: Callable
	var _js: JavaScriptObject = null

	func _ready() -> void:
		_js = JavaScriptBridge.get_interface("germText")
		if _js == null:
			queue_free()
			return
		button.button_down.connect(_on_down)

	func _on_down() -> void:
		var c: Dictionary = make.call()
		c["key"] = key
		_js.armAction(JSON.stringify(c))

	func _process(_delta: float) -> void:
		if _js == null or String(_js.pending()) != key:
			return
		var r: Variant = JSON.parse_string(String(_js.take()))
		if not (r is Dictionary) or float(r.get("age", 0.0)) > RESULT_MAX_AGE_MS:
			return
		done.call(bool(r.get("submit", false)), String(r.get("value", "")))


func _enter_tree() -> void:
	_live[key] = int(_live.get(key, 0)) + 1


func _ready() -> void:
	_js = JavaScriptBridge.get_interface("germText")
	if _js == null:
		# Köhnə shell (germText yoxdur) — Godot-un öz yolu qalır.
		queue_free()
		return
	# Sahə fokus almır: klaviatura naviqasiyası ilə də ora düşüb gizli elementi işə salmasın.
	edit.focus_mode = Control.FOCUS_NONE
	edit.context_menu_enabled = false
	edit.virtual_keyboard_enabled = false
	gui_input.connect(_on_gui_input)


func _exit_tree() -> void:
	_live[key] = maxi(0, int(_live.get(key, 1)) - 1)
	if _js == null:
		return
	# Yeni sahə eyni kadrda yarana bilər (bax [member _live]) — yoxlama kadrın sonunda.
	var js := _js
	var k := key
	var tree := get_tree()
	if tree != null:
		tree.process_frame.connect(func() -> void:
			if int(_live.get(k, 0)) == 0:
				js.dismiss(k), CONNECT_ONE_SHOT)


func _on_gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed or not edit.editable or _js == null:
		return
	accept_event()
	var c := cfg.duplicate()
	c["key"] = key
	c["value"] = edit.text
	c["max"] = edit.max_length
	if not c.has("placeholder"):
		c["placeholder"] = edit.placeholder_text
	_js.arm(JSON.stringify(c))


func _process(_delta: float) -> void:
	if _js == null or String(_js.pending()) != key:
		return
	var raw := String(_js.take())
	var r: Variant = JSON.parse_string(raw)
	if not (r is Dictionary) or float(r.get("age", 0.0)) > RESULT_MAX_AGE_MS:
		return
	# Ləğv (✕, fona toxunmaq) nəticə göndərmir; köhnə shell göndərsə də, sahə toxunulmaz qalır.
	if not bool(r.get("submit", false)):
		return
	var text := String(r.get("value", ""))
	if edit.max_length > 0:
		text = text.substr(0, edit.max_length)
	if text != edit.text:
		edit.text = text
		edit.text_changed.emit(text)
	edit.text_submitted.emit(text)
