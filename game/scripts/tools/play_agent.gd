class_name PlayAgent
extends Node
## Oyunu REAL GİRİŞLƏ oynayan QA agenti.
##
##   Godot_v4.7.2.exe --path game --resolution 1280x720 -- --agent \
##       --agent-out C:/yol/qovluq --agent-species 1 --agent-mode 2 --agent-time 90
##
## ── Niyə ayrıca agent ────────────────────────────────────────────────────
## `--practice --shot`-dakı avtomatik oyunçu ([method Arena._auto_sample])
## girişi TAMAMİLƏ keçir: `PlayerInput`-u birbaşa qurur. Ona görə joystik,
## atəş və super düymələri, menyu, ayarlar paneli və ölümdən sonra menyuya
## qayıdış avtomatik sınaqda heç vaxt işləmirdi.
##
## Bu agent oyunçunun etdiyini edir: menyuda düymələrə basır, ünvan sahəsinə
## yazır, ekran joystickini barmaqla sürüşdürür, atəş və super düymələrinə
## toxunur. Hadisələr [method Viewport.push_input] ilə göndərilir, yəni HUD-un
## öz `_gui_input`-una HƏQİQİ toxunuş kimi çatır — yer yoxlaması da daxil.
## Joystik, atəş və super AYRI barmaq indeksləridir (0, 1, 2): telefondakı
## çoxbarmaqlı oyun eynilə təkrarlanır.
##
## Oynadıqca iki şey yığır:
##   • kadrlar — dövri və HADİSƏ anında (zərbə, super, ölüm, kol, …);
##   • problemlər — avtomatik yoxlamalar: joystik/atəş/super cavabı, kamera,
##     kadr sıçrayışı, node sızması, ekrandan çıxan və üst-üstə düşən HUD,
##     menyu axını, mühərrik xətaları ([Logger] ilə tutulur).
##
## Nəticə `--agent-out` qovluğuna yazılır: `NNN_ad.png`, `log.jsonl`,
## `issues.txt`, `summary.json`. Çıxış kodu: 0 = problem yoxdur, 3 = var.
##
## Oyunçunun öz `settings.cfg` faylı agentin menyu seçimləri ilə dəyişir —
## ona görə başlanğıcda saxlanılır və sonda geri yazılır.

const SETTINGS := "user://settings.cfg"
## Bir qaçışda ən çox bu qədər kadr (məcburi kadrlar sayılmır).
const MAX_FRAMES := 56
const PERIODIC_SHOT := 8.0
## Toxunuşdan sonra oyunun cavab verməli olduğu vaxt.
##
## Atəşdə topun membranı yarması mikrobun ölçüsündən asılıdır (≈70–200 ms),
## üstünə bir tick (33 ms) və interpolasiya gecikməsi gəlir — 0.8 saniyə bol
## ehtiyatdır, amma "heç cavab vermədi"ni "gec cavab verdi"dən ayırır.
const RESPONSE_TIME := 0.8
const SPIKE_MS := 50.0
## Menyudakı yoxlama bağlantısı standart ünvana gedir və o server hələ
## yaradılmayıb (README). Bu xətalar gözləniləndir — ayrıca sayılır.
const KNOWN_ERRORS := ["Invalid status code", "Invalid response headers"]

var out_dir := "user://agent"
var species := -1
var mode := -1
var quality := -1
var match_time := 60.0
var rounds := 1
## Boş deyilsə, ayarlar panelinə yazılır və OYNA ilə ONLAYN oynanır.
var server := ""
## OYNA-nı standart (yatmış) serverlə sına: düymə ilişməməli, səbəb yazılmalıdır.
var try_dead_server := false
## Klaviatura yolunu da sına (WASD + boşluq + Q).
var keyboard_test := true
var hard_limit := 900.0

var _t := 0.0
var _done := false
var _frames := 0
var _shot_at := {}
var _issues := {}                 ## mətn -> {"cat", "count", "t", "shot"}
var _issue_order: Array[String] = []
var _known := {}
var _log: FileAccess
var _settings_backup := PackedByteArray()
var _had_settings := false
var _catcher: ErrorCatcher
var _counts := {
	"rounds": 0, "fires": 0, "fire_taps": 0, "super_taps": 0, "supers": 0,
	"hits_taken": 0, "deaths": 0, "level_ups": 0, "bursts_seen": 0,
	"bush": 0, "vent": 0, "brittle": 0, "stuck": 0,
}

# ---- arena ----
var _arena: Arena = null
var _in_arena := false
var _play_t := 0.0
var _stick_down := false
var _stick_origin := Vector2.ZERO
var _stick_dir := Vector2.ZERO
var _fire_cool := 0.0
var _win_t := 0.0
var _cmd_win := 0.0
var _pos_win := Vector2.ZERO
var _stuck_run := 0
var _unstick_t := 0.0
var _unstick_dir := Vector2.ZERO
var _poi := Vector2.INF
var _poi_kind := -1
var _poi_t := 0.0
var _poi_hold := 0.0
var _seen_kinds := {}
var _prev := {}
var _nodes: Array[int] = []
var _fx_max := 0
var _spikes := 0
var _worst_ms := 0.0
var _draw_max := 0
var _sample_t := 0.0
var _shot_t := 0.0
var _cam_t := 0.0
var _super_tap_t := -1.0
var _charge_before := 0
var _fire_tap_t := -1.0
var _eject_before := 0
var _ejects := 0
var _hooked: GermVisual = null
var _override_t := 0.0
var _override_dir := Vector2.ZERO
var _override_fire := false
## Beyin dayandırılıb — əl ilə sınaq gedir (klaviatura). Əks halda agentin
## joysticki klaviaturanı üstələyirdi ([method Arena._sample_input]-da joystik
## birinci oxunur) və sınaq yalançı "D işləmir" verirdi.
var _manual := false
## Kadr çəkilmir — yalnız ölçü. PNG saxlamaq əsas axını 50–150 ms bloklayır
## və kadr sıçrayışı ölçüsünü agentin ÖZÜ korlayırdı.
var shots_enabled := true
## Super hazırdır, düymə hələ yanmayıb — nə qədərdir.
var _ready_lag := 0.0
var _fire_diag := ""


## Mühərrik xətalarını tutur. Xəta başqa axından gələ bilər, ona görə
## siyahı kilidlə qorunur və əsas axında boşaldılır.
class ErrorCatcher extends Logger:
	var _lines := PackedStringArray()
	var _mutex := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String,
			rationale: String, _editor_notify: bool, error_type: int,
			_script_backtraces: Array[ScriptBacktrace]) -> void:
		var msg := rationale if not rationale.is_empty() else code
		var kind := "XƏBƏRDARLIQ" if error_type == Logger.ERROR_TYPE_WARNING else "XƏTA"
		_mutex.lock()
		_lines.append("%s: %s (%s:%d)" % [kind, msg, file.get_file(), line])
		_mutex.unlock()

	func drain() -> PackedStringArray:
		_mutex.lock()
		var out := _lines
		_lines = PackedStringArray()
		_mutex.unlock()
		return out


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(out_dir)
	_log = FileAccess.open(out_dir.path_join("log.jsonl"), FileAccess.WRITE)
	_backup_settings()
	_catcher = ErrorCatcher.new()
	OS.add_logger(_catcher)
	_event("start", {"species": species, "mode": mode, "quality": quality,
		"server": server, "viewport": _vp_size()})
	_run()


func _process(delta: float) -> void:
	_t += delta
	for line in _catcher.drain():
		if _is_known(line):
			_known[line] = int(_known.get(line, 0)) + 1
		else:
			_issue("mühərrik", line)

	var ms := delta * 1000.0
	if _in_arena and is_instance_valid(_arena):
		# Səhnə dəyişəndən sonra ilk iki saniyə yükləmədir — sayılmır.
		if _play_t > 2.0:
			if ms > SPIKE_MS:
				_spikes += 1
			_worst_ms = maxf(_worst_ms, ms)
			_draw_max = maxi(_draw_max, int(Performance.get_monitor(
				Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		_drive(delta)

	_sample_t += delta
	if _sample_t >= 1.0:
		_sample_t = 0.0
		_sample(ms)

	if _t > hard_limit and not _done:
		_issue("axın", "Sərt vaxt həddi (%d s) aşıldı — axın harasa ilişdi" % int(hard_limit))
		_finish()


# ================================================================ ssenari

func _run() -> void:
	await _wait(0.5)
	for r in rounds:
		if not await _menu_flow(r == 0):
			break
		var died := await _play_round(r == 0)
		if not died and r < rounds - 1:
			# Ölməyən oyunçu artıq matçı ÖZÜ tərk edə bilir (ayarlar →
			# MATÇI TƏRK ET). Əvvəl belə deyildi və agent burada dayanırdı:
			# SONSUZ rejimdə çoxraundlu qaçış ümumiyyətlə mümkün olmurdu.
			if not await _leave_match():
				break
	_finish()


func _menu_flow(first: bool) -> bool:
	var menu := await _await_scene("menu", 12.0) as MenuV2
	if menu == null:
		_issue("axın", "Menyu 12 saniyədə açılmadı (raund %d)" % (int(_counts.rounds) + 1))
		await _snap("menyu_yoxdur", true)
		return false
	await _wait(MenuV2.INTRO_TIME + 0.9)
	if not is_instance_valid(menu):
		return false
	_check_layout(menu, "menyu")
	if first:
		await _snap("menyu")
		_check_no_server_words(menu, "menyu")
		await _coming_soon_test(menu)
		if species >= 0:
			await _pick_species(menu)
		if mode >= 0:
			await _pick_mode(menu)
		if quality >= 0 or not server.is_empty():
			await _settings(menu)
		if try_dead_server and server.is_empty():
			await _try_dead_server(menu)
	else:
		await _snap("menyuya_qayıdış", true)

	if not server.is_empty():
		await _click(menu._play, "OYNA")
		if await _await_scene("arena", 15.0) == null:
			var state := menu._net_state if is_instance_valid(menu) else "?"
			_issue("axın", "OYNA basıldı, 15 s-də dünyaya girilmədi (vəziyyət: '%s')" % state)
			await _snap("girilmədi", true)
			return false
	else:
		var practice := _find_button(menu, "MƏŞQ")
		if practice == null:
			_issue("menyu", "MƏŞQ düyməsi tapılmadı")
			return false
		await _click(practice, "MƏŞQ")
		if await _await_scene("arena", 8.0) == null:
			_issue("axın", "MƏŞQ basıldı, 8 s-də arena açılmadı")
			await _snap("arena_yoxdur", true)
			return false
	return true


## Sistemsiz düymə (MAĞAZA) CAVABSIZ qalmamalıdır, amma heç nə də açmamalıdır.
##
## Menyuda mağaza, valyuta, pass və tapşırıqlar görünüş üçündür (bax
## [method MenuV2._coming_soon]). Sınanan iki şeydir: basılış "TEZLİKLƏ"
## bildirişi verir, və bu düymə səhvən vərəq, ayarlar və ya qoşulma işə salmır.
func _coming_soon_test(menu: MenuV2) -> void:
	var shop := _find_button(menu, "MAĞAZA")
	if shop == null:
		_issue("menyu", "MAĞAZA düyməsi tapılmadı")
		return
	await _click(shop, "MAĞAZA")
	await _wait(0.3)
	if not is_instance_valid(menu):
		return
	if menu._toast == null or not menu._toast.visible:
		_issue("menyu", "MAĞAZA basıldı, 'TEZLİKLƏ' bildirişi çıxmadı — düymə cavabsız qaldı")
	if (menu._sheet != null and menu._sheet.visible) or menu._settings != null or menu._joining:
		_issue("menyu", "MAĞAZA basıldı və başqa bir ekran/qoşulma işə düşdü")
	await _snap("menyu_tezliklə")
	await _wait(1.8)


func _pick_species(menu: MenuV2) -> void:
	var rail := _find_button(menu, "MİKROBLAR")
	if rail == null:
		_issue("menyu", "MİKROBLAR düyməsi tapılmadı")
		return
	await _click(rail, "MİKROBLAR")
	await _wait(0.5)
	if menu._sheet == null or not menu._sheet.visible:
		_issue("menyu", "MİKROBLAR basıldı, növ vərəqi açılmadı")
		return
	_check_layout(menu, "növ vərəqi")
	await _click_through_test(menu, "Növ vərəqi")
	await _snap("menyu_növlər")

	# Brawl Stars kimi: kart SEÇMİR, növün səhifəsini açır; seçim SEÇ ilədir.
	var before := int(Net.species)
	await _click(menu._cards[species], "növ kartı %d" % species)
	await _wait(0.4)
	if not menu._detail.visible:
		_issue("menyu", "Növ kartı %d basıldı, növün səhifəsi açılmadı" % species)
		return
	if int(Net.species) != before:
		_issue("menyu", "Növ kartı basılan kimi növ dəyişdi — seçim yalnız SEÇ ilə olmalıdır")
	_check_layout(menu, "növ səhifəsi")
	await _snap("menyu_növ_səhifəsi")

	if species == before:
		# Artıq seçilmiş növ: SEÇ sönükdür ("SEÇİLİB"). Oyunçu kimi GERİ ilə iki
		# pillə çıxılır: səhifə → kolleksiya → ana ekran.
		if not menu._select_btn.disabled:
			_issue("menyu", "Seçilmiş növün səhifəsində SEÇ düyməsi aktiv qalıb")
		var back := _find_button(menu._sheet, "GERİ")
		await _click(back, "GERİ (səhifə)")
		await _wait(0.3)
		if menu._detail.visible or not menu._sheet.visible:
			_issue("menyu", "Səhifədə GERİ kolleksiyaya qaytarmadı")
		await _click(back, "GERİ (kolleksiya)")
		await _wait(0.4)
	else:
		await _click(menu._select_btn, "SEÇ")
		await _wait(0.6)
	if int(Net.species) != species:
		_issue("menyu", "Növ %d seçildi, seçilən növ %d oldu" % [species, int(Net.species)])
	if menu._sheet != null and menu._sheet.visible:
		_issue("menyu", "Növ seçildi, vərəq bağlanmadı")
	await _snap("menyu_növ_seçildi")


func _pick_mode(menu: MenuV2) -> void:
	await _click(menu._mode_card, "REJİM kartı")
	await _wait(0.5)
	if menu._sheet == null or not menu._sheet.visible:
		_issue("menyu", "REJİM kartı basıldı, rejim vərəqi açılmadı")
		return
	_check_layout(menu, "rejim vərəqi")
	await _snap("menyu_rejimlər")
	await _click(menu._mode_rows[mode], "rejim sətri %d" % mode)
	await _wait(0.6)
	if int(Net.mode) != mode:
		_issue("menyu", "Rejim sətri %d basıldı, seçilən rejim %d oldu" % [mode, int(Net.mode)])
	if menu._sheet != null and menu._sheet.visible:
		_issue("menyu", "Rejim seçildi, vərəq bağlanmadı")


func _settings(menu: MenuV2) -> void:
	var gear := _find_icon_button(menu)
	if gear == null:
		_issue("menyu", "Ayarlar (dişli) düyməsi tapılmadı")
		return
	await _click(gear, "dişli")
	await _wait(0.4)
	var view := menu._settings
	if view == null or not is_instance_valid(view):
		_issue("menyu", "Dişli basıldı, ayarlar ekranı açılmadı")
		return
	_check_layout(view, "ayarlar")
	await _snap("menyu_ayarlar")

	# Keyfiyyət artıq seçim ZOLAĞIDIR: istənilən dəyər BİR toxunuşdadır,
	# köhnə növbə ilə keçən düymədəki kimi "neçə dəfə basmalıyam" sualı yoxdur.
	if quality >= 0 and int(Net.quality) != quality:
		if quality < view.quality_seg.size():
			await _click(view.quality_seg[quality], "QRAFİKA")
			await _wait(0.3)
			if int(Net.quality) != quality:
				_issue("menyu", "QRAFİKA zolağı keyfiyyəti %d etmədi (indi %d)" % [
					quality, int(Net.quality)])
		else:
			_issue("menyu", "QRAFİKA zolağında %d nömrəli seçim yoxdur" % quality)

	var typed := not server.is_empty()
	if typed:
		await _type_into(view.addr_edit, server)

	# Bağlamaq "‹ GERİ"-dədir, dişlidə yox: ayarlar tam örtükdür və dişlinin
	# üstünü tutur, yəni ikinci basılış ora heç vaxt çatmazdı. Agent oyunçunun
	# gördüyü yolu getməlidir.
	await _click(view.back_btn, "GERİ (ayarlar)")
	await _wait(0.3)
	if menu._settings != null and is_instance_valid(menu._settings):
		_issue("menyu", "GERİ basıldı, ayarlar bağlanmadı")

	if typed:
		# Ünvan ekran BAĞLANANDA yoxlanılır (bax [method MenuV2._open_settings]).
		var ok := await _wait_until(func() -> bool:
			return is_instance_valid(menu) and menu._net_state == "ONLAYN", 10.0)
		if not ok:
			_issue("şəbəkə", "Ünvan yazıldı, 10 s-də ONLAYN olmadı (vəziyyət: '%s')" % menu._net_state)
		await _snap("menyu_onlayn")


## OYNA — standart (yaradılmamış) serverlə. Oyunçu düymənin ilişmədiyini
## və SƏBƏBİ görməlidir — texniki sözlə yox, bildirişlə (bax
## [method MenuV2._online_failed]); sonra məşqə keçə bilməlidir.
func _try_dead_server(menu: MenuV2) -> void:
	await _click(menu._play, "OYNA (yatmış server)")
	await _wait(0.3)
	await _snap("oyna_yatmış_server")
	var settled := await _wait_until(func() -> bool:
		return is_instance_valid(menu) and not menu._joining, 14.0)
	await _snap("oyna_nəticə")
	if not settled:
		_issue("şəbəkə", "Yatmış serverdə OYNA 14 s sonra da 'QOŞULUR' qalır (vəziyyət: '%s')" % menu._net_state)
		await _click(menu._play, "OYNA (ləğv)")
		await _wait(0.4)
		return
	_event("dead_server", {"state": menu._net_state})
	if menu._toast == null or not menu._toast.visible:
		_issue("şəbəkə", "Yatmış serverdə OYNA alınmadı, amma oyunçu heç bir cavab görmədi")
	_check_no_server_words(menu, "yatmış serverdən sonra")


## Ana ekranda "server" sözü GÖRÜNMƏMƏLİDİR — oyunçu texniki vəziyyəti
## oxumamalıdır ("server yatıb" əvvəl profilin altında yazılırdı). Ayarlar
## ekranı istisnadır: orada server ünvanı sahəsi qəsdən var.
func _check_no_server_words(menu: MenuV2, where: String) -> void:
	if not is_instance_valid(menu):
		return
	for n in _descendants(menu):
		var l := n as Label
		if l == null or not l.is_visible_in_tree():
			continue
		if menu._settings != null and is_instance_valid(menu._settings) \
				and menu._settings.is_ancestor_of(l):
			continue
		if l.text.to_lower().contains("server"):
			_issue("menyu", "%s: ana ekranda texniki yazı görünür: '%s'" % [where, l.text])


func _play_round(first: bool) -> bool:
	_arena = get_tree().current_scene as Arena
	_counts.rounds = int(_counts.rounds) + 1
	_in_arena = true
	_play_t = 0.0
	_prev = {}
	_nodes.clear()
	_hooked = null
	_stick_down = false
	_poi = Vector2.INF
	await _wait(1.3)
	if not is_instance_valid(_arena):
		return false
	await _snap("arena_başlanğıc")
	_check_layout(_arena._hud, "HUD")
	if first:
		await _match_settings()
	if first and keyboard_test:
		await _keyboard_test()

	var end := _t + match_time
	while _t < end:
		if not is_instance_valid(_arena) or get_tree().current_scene != _arena:
			_issue("axın", "Arena gözlənilmədən bağlandı (%.0f s)" % _play_t)
			break
		if _arena._finished:
			break
		await get_tree().process_frame

	_release_all()
	var died := is_instance_valid(_arena) and _arena._finished
	if died:
		_counts.deaths = int(_counts.deaths) + 1
		await _wait(0.35)
		await _snap("nəticə_1", true)
		await _wait(1.5)
		if is_instance_valid(_arena):
			_check_layout(_arena._hud, "nəticə ekranı")
		await _snap("nəticə_2", true)
	_in_arena = false
	_leak_report()
	if died:
		var back := await _await_scene("menu", 10.0)
		if back == null:
			_issue("axın", "Nəticədən sonra 10 s-də menyuya qayıdılmadı")
		else:
			await _wait(0.2)
			var left := _count_arenas()
			if left > 0:
				_issue("sızma", "Menyuya qayıdandan sonra ağacda %d Arena qalıb" % left)
	return died


## Matçın İÇİNDƏ ayarlar YOXDUR, çıxış isə GERİ/ESC təsdiqindədir.
##
## Üç şey sınanır: HUD-da dişli qalmayıb (Brawl Stars kimi — ayarlar yalnız
## menyudadır), ESC təsdiqi açır, DAVAM ET isə onu bağlayır və matçı
## ÖLDÜRMÜR. Təsdiq idarələri buraxdığı üçün (bax [method Hud.toggle_leave_prompt])
## mikrobun ilişib qalmadığı da yoxlanılır.
func _match_settings() -> void:
	if not is_instance_valid(_arena):
		return
	if _find_icon_button(_arena._hud) != null:
		_issue("HUD", "Matçda ayarlar (dişli) düyməsi qalıb — ayarlar yalnız menyuda olmalıdır")
	if not await _open_leave_prompt("çıxış"):
		return
	await _click(_find_button(_arena._hud, "DAVAM ET"), "DAVAM ET")
	await _wait(0.3)
	if not is_instance_valid(_arena):
		_issue("çıxış", "DAVAM ET basıldı, arena bağlandı")
		return
	if _arena._hud.is_leave_prompt_open():
		_issue("çıxış", "DAVAM ET basıldı, təsdiq bağlanmadı")
	if _arena._finished:
		_issue("çıxış", "Təsdiq açılıb-bağlandı, matç bitdi")


## ESC göndərir və çıxış təsdiqinin açıldığını yoxlayır.
##
## Toxunuşla yox, KLAVİATURA ilə: təsdiqin yeganə qapısı sistem jestidir
## (Android-də GERİ, masaüstündə ESC) — ekranda ona aparan düymə yoxdur.
func _open_leave_prompt(tag: String) -> bool:
	if not is_instance_valid(_arena):
		return false
	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.physical_keycode = KEY_ESCAPE
	esc.pressed = true
	_push(esc)
	await get_tree().process_frame
	var up := esc.duplicate() as InputEventKey
	up.pressed = false
	_push(up)
	await _wait(0.3)
	if not is_instance_valid(_arena):
		return false
	if not _arena._hud.is_leave_prompt_open():
		_issue("çıxış", "Matçda ESC basıldı, çıxış təsdiqi açılmadı")
		return false
	_check_layout(_arena._hud, "çıxış təsdiqi")
	await _snap("oyun_" + tag)
	return true


## Matçı ESC → ÇIX ilə tərk edir və menyuya qayıdışı yoxlayır.
##
## Bu yol olmasaydı, ölməyən oyunçu sonsuz arenadan çıxa bilməzdi, agent də
## ölümsüz bitən raunddan sonra dayanardı.
func _leave_match() -> bool:
	if not await _open_leave_prompt("tərk"):
		return false
	var leave := _find_button(_arena._hud, "ÇIX")
	if leave == null:
		_issue("çıxış", "Çıxış təsdiqində 'ÇIX' düyməsi yoxdur")
		return false
	await _click(leave, "ÇIX")
	if await _await_scene("menu", 10.0) == null:
		_issue("axın", "ÇIX basıldı, 10 s-də menyuya qayıdılmadı")
		await _snap("tərk_edilmədi", true)
		return false
	await _wait(0.25)
	var left := _count_arenas()
	if left > 0:
		_issue("sızma", "Matç tərk ediləndən sonra ağacda %d Arena qalıb" % left)
	return true


## WASD / boşluq / Q — masaüstü yolu. Bir dəfə, qısa.
func _keyboard_test() -> void:
	var a := _arena
	await _wait_until(func() -> bool:
		return not is_instance_valid(a) or a._phase == Const.Phase.PLAYING, 12.0)
	if not is_instance_valid(a) or a._finished:
		return
	_manual = true
	_release_all()
	# Ətalət sönsün: mikrob suda sürüşür, yoxsa əvvəlki istiqamət ölçüyə qarışır.
	await _wait(1.2)
	var from := a.me.pos
	_key_state(KEY_D, true)
	await _wait(1.0)
	_key_state(KEY_D, false)
	_manual = false
	if not is_instance_valid(a):
		return
	var moved := a.me.pos.x - from.x
	_event("keyboard", {"dx": moved})
	if moved < 40.0 and not _touching_wall(from):
		_issue("giriş", "D düyməsi 1 s basıldı, mikrob sağa cəmi %.0f px getdi" % moved)
		await _snap("klaviatura_cavabsız", true)


# ================================================================ beyin

func _drive(delta: float) -> void:
	var a := _arena
	_play_t += delta
	if a._finished or a.me == null or _manual:
		return
	var me := a.me
	var hud := a._hud
	var playing := a._phase == Const.Phase.PLAYING
	var pos := me.pos
	var fill := float(me.balls) / float(maxi(me.capacity, 1))
	_hook_visual(a)

	if not pos.is_finite():
		_issue("sim", "Mikrobun mövqeyi sonsuz/NaN oldu")
		return

	# ---- qərar ----
	var dir := Vector2.ZERO
	var want_fire := false
	var enemy := _enemy(a)
	var food: Dictionary = a._nearest_food()
	var hungry := me.balls <= Const.FIRE_MIN_BALLS + 1
	if _override_t > 0.0:
		_override_t -= delta
		dir = _override_dir
		want_fire = _override_fire
	elif _unstick_t > 0.0:
		_unstick_t -= delta
		dir = _unstick_dir
	elif hungry and not food.is_empty():
		dir = (Vector2(food["pos"]) - pos).normalized()
	elif not enemy.is_empty() and pos.distance_to(enemy["pos"]) < 700.0:
		var to: Vector2 = Vector2(enemy["pos"]) - pos
		var d := to.length()
		if fill >= 0.8:
			dir = -to.normalized()
		else:
			# Nişan hərəkət istiqamətidir — atmaq üçün hədəfə tərəf getmək lazımdır.
			dir = to.normalized()
			want_fire = d < 560.0
			if d < 170.0:
				dir = to.normalized().rotated(PI * 0.5)
	else:
		dir = _explore(a, pos, delta)

	if a._mode != Const.Mode.ENDLESS and pos.length() > a._wet_radius * 0.82:
		dir = (-pos).normalized()
	if pos.length() > Const.WORLD_RADIUS * 0.93:
		dir = (-pos).normalized()

	_steer(dir)
	if _stick_down and dir.length() > 0.05 and not hud.move_stick.active:
		# Oyun barmağı buraxıb (məs. nəticə və ya yenidən qoşulma) — yenidən bas.
		_stick_down = false

	# ---- atəş ----
	_fire_cool -= delta
	if want_fire and playing and _fire_cool <= 0.0 and me.balls > Const.FIRE_MIN_BALLS:
		_fire_cool = 0.5
		_counts.fire_taps = int(_counts.fire_taps) + 1
		var probe := _fire_tap_t < 0.0 and hud.fire_button._cooldown_ratio <= 0.01 \
				and hud.fire_button._has_ammo
		if probe and me.in_cyst():
			# Kistada simulyasiya girişi ümumiyyətlə emal etmir ([method Sim._step_germs]),
			# yəni atəş QAYDA ilə bağlıdır. Problem düymədədir: o, hazır görünür.
			_issue("HUD", "Amöb kistadadır (atəş mümkün deyil), amma atəş düyməsi HAZIR görünür — basış səssizcə itir")
			probe = false
		if probe:
			_fire_tap_t = _t
			_eject_before = _ejects
		_tap(1, hud.fire_button)
		if probe:
			# Toxunuş düyməyə ÇATDIMI, arena onu GÖTÜRDÜMÜ — cavab olmasa səbəbi
			# bunlardan ayırır: yer yoxlaması, bayraq, yoxsa simulyasiya.
			_fire_diag = "held=%s flag=%s cd=%.3f balls=%d touch=%d" % [
				hud.fire_button.held, a._fire_flag, me.cooldown, me.balls,
				hud.fire_button._touch_index]

	# ---- super ----
	# İnsan düyməyə YANANDAN sonra basır. Onlayn rejimdə snapshot tick-dən kənarda
	# gəlir və düymə bir tick (≤33 ms) gec yanır — agent əvvəl elə həmin kadrda
	# basırdı və "super işləmədi" yalançı problemi çıxırdı.
	if playing and me.super_ready() and not hud.super_button._ready_now:
		_ready_lag += delta
		if _ready_lag > 0.3:
			_issue("HUD", "Super hazırdır, amma düymə 0.3 s-dən çox HAZIR göstərmir")
	else:
		_ready_lag = 0.0
	if playing and me.super_ready() and hud.super_button._ready_now and _super_tap_t < 0.0 \
			and (not enemy.is_empty() or _play_t > 12.0):
		_charge_before = me.charge
		_super_tap_t = _t
		_counts.super_taps = int(_counts.super_taps) + 1
		_tap(2, hud.super_button)
		_snap_later("super_açılış", 0.12, 6.0)
		_snap_later("super_davam", 0.45, 6.0)

	_check_responses(a, delta, dir, playing)
	_triggers(a, fill, playing)


func _explore(a: Arena, pos: Vector2, delta: float) -> Vector2:
	_poi_t -= delta
	var reach := 50.0
	if _poi_kind == DishMap.Kind.BRITTLE:
		reach = 170.0
	if _poi == Vector2.INF or _poi_t <= 0.0 or pos.distance_to(_poi) < reach:
		if _poi != Vector2.INF and pos.distance_to(_poi) < reach:
			_arrive(a, pos)
		_pick_poi(a, pos)
	return (_poi - pos).normalized()


## Maraq nöqtəsinə çatdıq. Kövrək qabığa bir neçə dəfə atılır ki, çat
## mərhələləri kadra düşsün.
func _arrive(_a: Arena, pos: Vector2) -> void:
	_seen_kinds[_poi_kind] = true
	match _poi_kind:
		DishMap.Kind.BRITTLE:
			_counts.brittle = int(_counts.brittle) + 1
			_override_dir = (_poi - pos).normalized()
			_override_fire = true
			_override_t = 2.6
			_snap_later("kövrək_atəş", 1.4, 30.0)
		DishMap.Kind.BUSH:
			_override_dir = Vector2.ZERO
			_override_fire = false
			_override_t = 1.5


func _pick_poi(a: Arena, pos: Vector2) -> void:
	var limit := Const.WORLD_RADIUS * 0.85
	if a._mode != Const.Mode.ENDLESS:
		limit = minf(limit, a._wet_radius * 0.75)
	var best := Vector2.INF
	var best_d := INF
	var kind := -1
	var list := DishMap.obstacles()
	for i in list.size():
		var o: Vector4 = list[i]
		var k := int(o.w)
		if k == DishMap.Kind.MUCUS or _seen_kinds.has(k):
			continue
		if k == DishMap.Kind.BRITTLE and DishMap.wall_gone(_wall_byte(a, i)):
			continue
		var p := Vector2(o.x, o.y)
		if p.length() > limit:
			continue
		var d := pos.distance_to(p)
		if d < best_d:
			best_d = d
			best = p
			kind = k
	if best == Vector2.INF:
		best = Vector2.from_angle(randf() * TAU) * randf_range(0.1, 0.7) * limit
	_poi = best
	_poi_kind = kind
	_poi_t = 14.0


func _wall_byte(a: Arena, i: int) -> int:
	if a._last_snap.is_empty():
		return 0
	var walls: PackedByteArray = a._last_snap[Const.Snap.WALLS]
	return walls[i] if i < walls.size() else 0


func _enemy(a: Arena) -> Dictionary:
	if a._last_snap.is_empty():
		return {}
	var best := {}
	var best_d := INF
	for e in a._last_snap[Const.Snap.GERMS]:
		if int(e[Const.GF.ID]) == a.my_id:
			continue
		var flags := int(e[Const.GF.FLAGS])
		var team := ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) - 1
		if a._my_team >= 0 and team == a._my_team:
			continue
		var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
		var d := a.me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


# ================================================================ yoxlamalar

func _check_responses(a: Arena, delta: float, dir: Vector2, playing: bool) -> void:
	var me := a.me
	# ---- joystik ----
	if _stick_down and dir.length() > 0.05 and a._hud.move_stick.value.length() < 0.3:
		_issue("giriş", "Joystik sürüşdürüldü, amma dəyəri %.2f qaldı" % a._hud.move_stick.value.length())

	_win_t += delta
	if dir.length() > 0.05 and playing and not me.in_cyst():
		_cmd_win += delta
	if _win_t >= 2.0:
		var moved := me.pos.distance_to(_pos_win)
		if _cmd_win >= 1.6 and moved < 25.0:
			_stuck_run += 1
			_counts.stuck = int(_counts.stuck) + 1
			_unstick_t = 1.0
			_unstick_dir = Vector2.from_angle(randf() * TAU)
			_poi = Vector2.INF
			if _stuck_run == 3:
				var why := "divara söykənib" if _touching_wall(me.pos) else "açıq yerdə"
				_issue("giriş", "Joystik 6 s basılıdır, mikrob yerindən tərpənmir (%s)" % why)
				_snap_later("ilişmə", 0.0, 60.0)
		else:
			_stuck_run = 0
		_win_t = 0.0
		_cmd_win = 0.0
		_pos_win = me.pos

	# ---- atəş ----
	if _fire_tap_t >= 0.0 and _t - _fire_tap_t > RESPONSE_TIME:
		if _ejects <= _eject_before and is_instance_valid(a) and not a._finished \
				and a._phase == Const.Phase.PLAYING:
			_issue("giriş", "Atəş düyməsi (sursat var, soyuma bitib) basıldı — top çıxmadı")
			_event("fire_diag", {"at_tap": _fire_diag,
				"now": "cd=%.3f balls=%d ejects=%d freeze=%.3f" % [
					a.me.cooldown, a.me.balls, _ejects, a._freeze]})
			_snap_later("atəş_cavabsız", 0.0, 60.0)
		_fire_tap_t = -1.0

	# ---- super ----
	if _super_tap_t >= 0.0 and _t - _super_tap_t > RESPONSE_TIME:
		if me.charge >= _charge_before and me.super_t <= 0.0:
			_issue("giriş", "SUPER düyməsi (hazır) basıldı — super işə düşmədi")
			_snap_later("super_cavabsız", 0.0, 60.0)
		else:
			_counts.supers = int(_counts.supers) + 1
		_super_tap_t = -1.0

	# ---- kamera ----
	_cam_t += delta
	if _cam_t >= 1.0:
		_cam_t = 0.0
		if a._freeze <= 0.0 and a._shake < 1.0:
			var off := a._cam.global_position.distance_to(a._shown_pos())
			if off > 40.0:
				_issue("kamera", "Kamera öz mikrobdan %.0f px aralıdır" % off)
		var v: GermVisual = a._visuals.get(a.my_id, {}).get("node")
		if v == null or not v.visible:
			_issue("görüntü", "Öz mikrobun görüntüsü yoxdur və ya gizlidir")


func _triggers(a: Arena, fill: float, playing: bool) -> void:
	var me := a.me
	var v: GermVisual = a._visuals.get(a.my_id, {}).get("node")
	var flash := v != null and v._flash > 0.05
	if flash and not _prev.get("flash", false):
		_counts.hits_taken = int(_counts.hits_taken) + 1
		_snap_later("zərbə_yedim", 0.02, 14.0)
	_prev["flash"] = flash

	if me.capacity > int(_prev.get("cap", me.capacity)):
		_counts.level_ups = int(_counts.level_ups) + 1
		_snap_later("tutum_artdı", 0.1, 12.0)
	_prev["cap"] = me.capacity

	var danger := fill >= 0.85
	if danger and not _prev.get("danger", false):
		_snap_later("təhlükə", 0.05, 20.0)
	_prev["danger"] = danger

	var ready := me.super_ready()
	if ready and not _prev.get("ready", false):
		_snap_later("super_hazır", 0.3, 40.0)
	_prev["ready"] = ready

	if a._hidden and not _prev.get("hidden", false):
		_counts.bush = int(_counts.bush) + 1
		_snap_later("kolda", 0.5, 25.0)
	_prev["hidden"] = a._hidden

	var in_vent := _in_kind(me.pos, DishMap.Kind.VENT)
	if in_vent and not _prev.get("vent", false):
		_counts.vent = int(_counts.vent) + 1
		_snap_later("cərəyan", 0.1, 30.0)
	_prev["vent"] = in_vent

	var bursts := 0
	for c in a._fx.get_children():
		if c is BurstFx:
			bursts += 1
	if bursts > int(_prev.get("bursts", 0)):
		_counts.bursts_seen = int(_counts.bursts_seen) + 1
		_snap_later("partlayış", 0.12, 12.0)
	_prev["bursts"] = bursts
	_fx_max = maxi(_fx_max, a._fx.get_child_count())

	if a._phase != int(_prev.get("phase", -1)):
		_snap_later("faza_%d" % a._phase, 0.3, 5.0)
	_prev["phase"] = a._phase

	if a._mode != Const.Mode.ENDLESS and a._wet_radius < Const.WORLD_RADIUS * 0.75 \
			and not _prev.get("dry", false):
		_prev["dry"] = true
		_snap_later("quruyan_qab", 0.0, 999.0)

	_shot_t += get_process_delta_time()
	if _shot_t >= PERIODIC_SHOT and playing:
		_shot_t = 0.0
		_snap_later("oyun", 0.0, 0.0)


## HUD və menyu düzümü: ekrandan çıxan, üst-üstə düşən, qutusundan daşan.
func _check_layout(root: Node, where: String) -> void:
	if root == null or not is_instance_valid(root):
		return
	var vr := get_viewport().get_visible_rect().grow(1.0)
	var buttons: Array[Control] = []
	for n in _descendants(root):
		var c := n as Control
		if c == null or not c.is_visible_in_tree() or c.size.x < 2.0 or c.size.y < 2.0:
			continue
		if c is TouchStick:
			continue
		var r := c.get_global_rect()
		var clipped := false
		var p := c.get_parent()
		while p != null:
			if p is Control and (p as Control).clip_contents:
				clipped = true
				break
			p = p.get_parent()
		if not clipped and not vr.encloses(r) and _label_text(c) != "":
			_issue("düzüm", "%s: '%s' ekrandan çıxır (%s)" % [where, _label_text(c), _rect_s(r)])
		# Yalnız HƏQİQƏTƏN üstdə olan düymə sayılır. Menyunun vərəqi arxadakı
		# OYNA-nı örtür, amma OYNA ağacda "görünən" qalır — ilk qaçışda bu,
		# yalançı "üst-üstə düşür" verdi. Mərkəzə siçan hərəkəti göndərilir və
		# hover-i kim tutursa, üstdəki odur.
		if (c is BaseButton or c is FireButton or c is SuperButton or c is Minimap) \
				and _is_topmost(c):
			buttons.append(c)
	for i in buttons.size():
		for j in range(i + 1, buttons.size()):
			var a := buttons[i]
			var b := buttons[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var ov := a.get_global_rect().intersection(b.get_global_rect())
			if ov.get_area() > 36.0:
				_issue("düzüm", "%s: '%s' ilə '%s' üst-üstə düşür (%.0f px²)" % [
					where, _name_of(a), _name_of(b), ov.get_area()])


func _is_topmost(c: Control) -> bool:
	if c.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		return true
	var move := InputEventMouseMotion.new()
	move.position = _centre(c)
	move.global_position = move.position
	_push(move)
	var hit := get_viewport().gui_get_hovered_control()
	return hit != null and (hit == c or c.is_ancestor_of(hit))


## Vərəq açıqdır: arxadakı OYNA-nın yerinə basmaq heç nə etməməlidir.
func _click_through_test(menu: MenuV2, where: String) -> void:
	var p := _centre(menu._play)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	_push(down)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	_push(up)
	await _wait(0.2)
	if menu._joining:
		_issue("menyu", "%s açıq ikən boş yerə basmaq arxadakı OYNA-nı işə saldı" % where)
		await _click(menu._play, "OYNA (ləğv)")
	if menu._sheet == null or not menu._sheet.visible:
		_issue("menyu", "%s açıq ikən boş yerə basmaq vərəqi bağladı" % where)


func _leak_report() -> void:
	if _nodes.size() < 20:
		return
	var head := 0.0
	var tail := 0.0
	for i in 5:
		head += _nodes[i + 3]
		tail += _nodes[_nodes.size() - 1 - i]
	head /= 5.0
	tail /= 5.0
	_event("nodes", {"head": head, "tail": tail, "fx_max": _fx_max})
	if tail > head * 1.5 and tail - head > 60.0:
		_issue("sızma", "Node sayı raund boyu %.0f → %.0f artdı" % [head, tail])
	if _fx_max > 160:
		_issue("sızma", "Effekt qatında eyni anda %d node olub" % _fx_max)


# ================================================================ giriş

func _push(ev: InputEvent) -> void:
	get_viewport().push_input(ev, true)


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	_push(ev)


func _drag(index: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	ev.relative = rel
	_push(ev)


func _tap(index: int, ctrl: Control) -> void:
	var p := _centre(ctrl)
	_touch(index, p, true)
	get_tree().create_timer(0.07).timeout.connect(_touch.bind(index, p, false))


func _steer(dir: Vector2) -> void:
	var stick := _arena._hud.move_stick
	if dir.length() < 0.05:
		if _stick_down:
			_touch(0, _stick_origin + _stick_dir * stick.max_radius * 0.85, false)
			_stick_down = false
		return
	var n := dir.normalized()
	if not _stick_down:
		var r := stick.get_global_rect()
		_stick_origin = r.position + r.size * Vector2(0.32, 0.62)
		_touch(0, _stick_origin, true)
		_stick_down = true
		_stick_dir = Vector2.ZERO
	if n.distance_to(_stick_dir) > 0.04:
		var from := _stick_origin + _stick_dir * stick.max_radius * 0.85
		var to := _stick_origin + n * stick.max_radius * 0.85
		_drag(0, to, to - from)
		_stick_dir = n


func _release_all() -> void:
	if _stick_down and is_instance_valid(_arena):
		_touch(0, _stick_origin, false)
	_stick_down = false
	_override_t = 0.0


func _click(ctrl: Control, what: String) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		_issue("menyu", "'%s' düyməsi mövcud deyil" % what)
		return
	if not ctrl.is_visible_in_tree():
		_issue("menyu", "'%s' görünmür, amma basılmalıdır" % what)
	var p := _centre(ctrl)
	if not get_viewport().get_visible_rect().has_point(p):
		_issue("düzüm", "'%s' düyməsinin mərkəzi ekrandan kənardadır" % what)
	var move := InputEventMouseMotion.new()
	move.position = p
	move.global_position = p
	_push(move)
	await get_tree().process_frame
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = p
	down.global_position = p
	_push(down)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	_push(up)
	_event("click", {"what": what, "at": [p.x, p.y]})
	await get_tree().process_frame


func _type_into(field: LineEdit, text: String) -> void:
	await _click(field, "ünvan sahəsi")
	await _wait(0.1)
	if not field.has_focus():
		_issue("menyu", "Ünvan sahəsinə basıldı, fokus almadı")
		field.grab_focus()
	field.select_all()
	_key(KEY_BACKSPACE)
	for ch in text:
		_key(KEY_NONE, ch)
	await _wait(0.05)
	if field.text != text:
		_issue("menyu", "Ünvan sahəsinə '%s' yazıldı, sahədə '%s' var" % [text, field.text])
	_key(KEY_ENTER)
	await _wait(0.05)


func _key(code: Key, ch := "") -> void:
	var ev := InputEventKey.new()
	ev.pressed = true
	ev.keycode = code
	if not ch.is_empty():
		ev.unicode = ch.unicode_at(0)
	_push(ev)
	var up := ev.duplicate() as InputEventKey
	up.pressed = false
	_push(up)


## Klaviatura Input VƏZİYYƏTİNİ dəyişir — `Input.is_key_pressed` onu oxuyur,
## ona görə burada `push_input` yox, `parse_input_event` lazımdır.
func _key_state(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


# ================================================================ kadr və jurnal

func _snap_later(tag: String, delay: float, cool: float) -> void:
	var last: float = _shot_at.get(tag, -INF)
	if _t - last < cool or _frames >= MAX_FRAMES:
		return
	_shot_at[tag] = _t
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(_snap.bind(tag))
	else:
		_snap(tag)


func _snap(tag: String, force := false) -> void:
	if _done or not shots_enabled or (_frames >= MAX_FRAMES and not force):
		return
	_frames += 1
	var path := out_dir.path_join("%03d_%s.png" % [_frames, tag])
	# Kadr gözlənilir, amma VAXT HƏDDİ ilə. Pəncərə kiçildiləndə Godot çəkmir
	# və `frame_post_draw` ümumiyyətlə gəlmir — `_process` isə işləməyə davam
	# edir. İlk qaçışlardan biri məhz belə ilişdi: arena 20 saniyədən çox
	# oynandı, agent isə ilk kadrı gözləyərək raundu heç bitirmədi.
	if not await _drawn_within(1.5):
		_frames -= 1
		_event("note", {"text": "kadr çəkilmədi — pəncərə çəkilmir (kiçildilib?)", "tag": tag})
		return
	if _done:
		return
	var img := get_viewport().get_texture().get_image()
	if img == null:
		return
	img.save_png(path)
	var info := {"file": path.get_file(), "tag": tag}
	if _in_arena and is_instance_valid(_arena) and _arena.me != null:
		info["balls"] = _arena.me.balls
		info["cap"] = _arena.me.capacity
		info["charge"] = _arena.me.charge
		info["phase"] = _arena._phase
	_event("shot", info)


func _drawn_within(limit: float) -> bool:
	var box := {"drawn": false}
	var mark := func() -> void: box["drawn"] = true
	RenderingServer.frame_post_draw.connect(mark, CONNECT_ONE_SHOT)
	var until := _t + limit
	while not box["drawn"] and _t < until:
		await get_tree().process_frame
	if not box["drawn"] and RenderingServer.frame_post_draw.is_connected(mark):
		RenderingServer.frame_post_draw.disconnect(mark)
	return box["drawn"]


func _sample(ms: float) -> void:
	var s := {
		"scene": _scene_name(),
		"fps": Engine.get_frames_per_second(),
		"ms": snappedf(ms, 0.01),
		"nodes": get_tree().get_node_count(),
		"draw": int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
	}
	if _in_arena and is_instance_valid(_arena) and _arena.me != null:
		var me := _arena.me
		s["pos"] = [snappedf(me.pos.x, 0.1), snappedf(me.pos.y, 0.1)]
		s["balls"] = me.balls
		s["cap"] = me.capacity
		s["charge"] = me.charge
		s["phase"] = _arena._phase
		s["fx"] = _arena._fx.get_child_count()
		_nodes.append(get_tree().get_node_count())
	_event("sample", s)


func _event(kind: String, data: Dictionary) -> void:
	if _log == null:
		return
	data["t"] = snappedf(_t, 0.01)
	data["ev"] = kind
	_log.store_line(JSON.stringify(data))
	# Hər sətir dərhal diskə: agent ilişəndə xarici `timeout` prosesi öldürür
	# və buferdə qalan sətirlər — məhz ilişmənin səbəbi — itirdi.
	_log.flush()


func _issue(cat: String, text: String) -> void:
	var key := "[%s] %s" % [cat, text]
	if _issues.has(key):
		_issues[key]["count"] += 1
		return
	_issues[key] = {"cat": cat, "count": 1, "t": snappedf(_t, 0.1),
		"frame": _frames}
	_issue_order.append(key)
	_event("issue", {"cat": cat, "text": text})
	printerr("[agent] PROBLEM ", key)


func _finish() -> void:
	if _done:
		return
	_done = true
	_release_all()
	_restore_settings()
	OS.remove_logger(_catcher)

	var lines := PackedStringArray()
	for key in _issue_order:
		var i: Dictionary = _issues[key]
		lines.append("%s   ×%d   (t=%.1f s, kadr ≈%03d)" % [key, i.count, i.t, i.frame])
	var known := PackedStringArray()
	for line in _known:
		known.append("%s   ×%d" % [line, _known[line]])
	var f := FileAccess.open(out_dir.path_join("issues.txt"), FileAccess.WRITE)
	f.store_string("\n".join(lines) if not lines.is_empty() else "(problem tapılmadı)")
	f.store_string("\n\n# Gözlənilən (server yaradılmayıb):\n" + "\n".join(known) + "\n")

	var summary := {
		"species": species, "mode": mode, "quality": quality, "server": server,
		"viewport": _vp_size(), "time": snappedf(_t, 0.1),
		"counts": _counts, "issues": _issue_order.size(),
		"frames": _frames, "spikes_over_50ms": _spikes,
		"worst_frame_ms": snappedf(_worst_ms, 0.01), "draw_calls_peak": _draw_max,
		"fx_peak": _fx_max,
	}
	var s := FileAccess.open(out_dir.path_join("summary.json"), FileAccess.WRITE)
	s.store_string(JSON.stringify(summary, "  "))
	_log.close()

	print("[agent] BİTDİ: %d problem, %d kadr, %s" % [_issue_order.size(), _frames,
		JSON.stringify(_counts)])
	if Net.is_connected_to_server():
		Net.disconnect_from_server()
	await get_tree().process_frame
	get_tree().quit(0 if _issue_order.is_empty() else 3)


# ================================================================ köməkçilər

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true).timeout


func _wait_until(cond: Callable, timeout: float) -> bool:
	var until := _t + timeout
	while _t < until:
		if cond.call():
			return true
		await get_tree().process_frame
	return bool(cond.call())


func _await_scene(want: String, timeout: float) -> Node:
	var until := _t + timeout
	while _t < until:
		var s := get_tree().current_scene
		if s != null and is_instance_valid(s) and s.is_inside_tree() \
				and not s.is_queued_for_deletion():
			if want == "menu" and s is MenuV2:
				return s
			if want == "arena" and s is Arena:
				return s
		await get_tree().process_frame
	return null


func _count_arenas() -> int:
	var n := 0
	for c in get_tree().root.get_children():
		if c is Arena:
			n += 1
	return n


func _hook_visual(a: Arena) -> void:
	var v: GermVisual = a._visuals.get(a.my_id, {}).get("node")
	if v == null or v == _hooked:
		return
	_hooked = v
	v.broke_through.connect(func(local: bool) -> void:
		if local:
			_ejects += 1
			_counts.fires = int(_counts.fires) + 1)


func _in_kind(pos: Vector2, kind: int) -> bool:
	for o in DishMap.obstacles():
		if int(o.w) == kind and pos.distance_to(Vector2(o.x, o.y)) < o.z:
			return true
	return false


func _touching_wall(pos: Vector2) -> bool:
	for o in DishMap.obstacles():
		if DishMap.blocks_germ(int(o.w)) \
				and pos.distance_to(Vector2(o.x, o.y)) < o.z + Const.germ_radius(Const.MAX_CAPACITY):
			return true
	return pos.length() > Const.WORLD_RADIUS * 0.9


func _is_known(line: String) -> bool:
	for k in KNOWN_ERRORS:
		if line.contains(k):
			return true
	return false


func _descendants(root: Node) -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		stack.append_array(n.get_children())
	return out


func _find_button(root: Node, text: String) -> Button:
	for n in _descendants(root):
		var b := n as Button
		if b == null:
			continue
		if b.text.contains(text):
			return b
		for c in b.get_children():
			if c is Label and (c as Label).text.contains(text):
				return b
	return null


## Mətnsiz, ikonlu düymə — dişli.
func _find_icon_button(root: Node) -> Button:
	for n in _descendants(root):
		var b := n as Button
		if b != null and b.icon != null and b.text.is_empty():
			return b
	return null


func _label_text(c: Control) -> String:
	if c is Label:
		return (c as Label).text
	if c is Button:
		return (c as Button).text
	return ""


func _name_of(c: Control) -> String:
	var t := _label_text(c)
	return t if not t.is_empty() else c.get_class()


func _centre(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _rect_s(r: Rect2) -> String:
	return "%d,%d %dx%d" % [int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)]


func _vp_size() -> Array:
	var s := get_viewport().get_visible_rect().size
	return [int(s.x), int(s.y)]


func _scene_name() -> String:
	var s := get_tree().current_scene
	if s == null:
		return ""
	if s is MenuV2:
		return "menu"
	if s is Arena:
		return "arena"
	return s.name


func _backup_settings() -> void:
	_had_settings = FileAccess.file_exists(SETTINGS)
	if _had_settings:
		_settings_backup = FileAccess.get_file_as_bytes(SETTINGS)


func _restore_settings() -> void:
	if _had_settings:
		var f := FileAccess.open(SETTINGS, FileAccess.WRITE)
		if f != null:
			f.store_buffer(_settings_backup)
	elif FileAccess.file_exists(SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS))
