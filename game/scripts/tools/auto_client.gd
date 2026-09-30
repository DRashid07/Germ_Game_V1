class_name AutoClient
extends Node
## Şəbəkə üçün inteqrasiya testi: menyusuz, insansız client.
##
##   Godot_v4.7.2.exe --headless --path game -- --autoclient --host ws://127.0.0.1:27015
##
## Serverə qoşulur, dünyaya girir, arenanı açır və avtomatik giriş göndərir.
## İki belə client + bir server = tam onlayn oyun yoxlaması.
## Oyunun özündə istifadə olunmur.

var host := "127.0.0.1"
var port := Const.DEFAULT_PORT
var label := "auto"
## 0-dan böyükdürsə, dünyaya girdikdən bu qədər saniyə sonra bağlantı qəsdən
## kəsilir — reconnect məntiqini sınamaq üçün.
var drop_after := 0.0
## 0-dan böyükdürsə, bu qədər saniyədən sonra proses özü çıxır (CI üçün).
var quit_after := 0.0
## Hansı rejimə girsin (bax [enum Const.Mode]).
var mode := int(Const.Mode.ENDLESS)
## Hansı növlə girsin (bax [enum Const.Species]).
var species := int(Const.Species.CILIATE)

var _joined := false
## Oyun ekranı — çıxışda vuruş statistikası buradan oxunur.
var _arena: Arena = null
## Vuruşu ekranda ölçən probe (bax [HitProbe]); boş deyilsə kadrlar buraya yazılır.
var probe_shots := ""
var _probe: HitProbe = null

## ── Dostluq və komanda testi (bax README, «Dostlar və komanda») ──
## Boş deyilsə, client bu gizli açarla tanınır (diskə yazılmır).
var secret := ""
## Bu açarın (vergüllə — açarların) sahibinə dostluq sorğusu göndərilir (kod açardan hesablanır —
## test skripti kodu əvvəlcədən bilməli olmasın).
var befriend_secret := ""
## > 0 olanda client TƏK girmir: bu qədər nəfərlik komanda yığılır, hamı
## HAZIR olur və server komandanı birlikdə oyuna salır.
var party := 0
var _asked := false
var _invited := {}
## HAZIR hansı komanda tərkibinə göndərilib — serverin cavabı gələnə qədər
## hər [signal Friends.changed]-də təkrar göndərilməsin.
var _ready_for := ""


func _ready() -> void:
	Net.nickname = label
	Net.mode = Const.mode_from(mode)
	Net.species = Const.species_from(species)
	if not secret.is_empty():
		Friends.use_secret(secret)
		_log("oyunçu kodu #%s" % Friends.my_tag)
	if party > 0:
		Friends.changed.connect(_social_step)
		Friends.invite_arrived.connect(func(tag: String) -> void:
			_log("dəvət gəldi: %s" % tag)
			Friends.answer_invite(tag, true))
		Friends.notice.connect(func(title: String, sub: String, _k: String) -> void:
			_log("bildiriş: %s — %s" % [title, sub]))
	Net.connected_to_server.connect(_on_connected)
	Net.connection_failed.connect(func(): _log("qoşulma alınmadı"))
	Net.world_joined.connect(_on_world_joined)
	Net.join_rejected.connect(func(reason): _log("qəbul edilmədi: %s" % reason))
	Net.you_burst.connect(_on_burst)

	var target := host if host.begins_with("ws") else "%s:%d" % [host, port]
	_log("qoşulur → %s" % target)
	if Net.join_server(host, port) != OK:
		_log("join_server xətası")

	if quit_after > 0.0:
		get_tree().create_timer(quit_after).timeout.connect(func():
			_log("vaxt bitdi, çıxılır")
			_log_hits()
			get_tree().quit(0))


func _on_connected() -> void:
	if _joined:
		# Artıq dünyadayıq — bu təkrar qoşulmadır. Yenidən girmək olmaz,
		# nişanla mikroba qayıtmağı [Arena] özü edir.
		_log("yenidən qoşuldu (id=%d), nişanla qayıdır" % Net.local_id)
		return
	if party > 0:
		_log("qoşuldu (id=%d), komanda yığılır" % Net.local_id)
		return
	_log("qoşuldu (id=%d), dünyaya girir" % Net.local_id)
	# Rejim də ötürülür — onsuz TƏK QALAN-ın ONLAYN yolu bu alətlə heç vaxt
	# sınana bilmirdi: server tərəf hazır idi, alət isə həmişə sonsuz arenaya
	# girirdi.
	Net.request_join.rpc_id(1, label, int(species), int(mode))


func _on_world_joined(info: Dictionary) -> void:
	if _joined:
		return
	_joined = true
	_log("DÜNYAYA GİRDİ — id=%d, rəng=%d, dünya #%d, rejim %s" % [
		info["you"], info["color"], info["world"], Const.mode_name(int(info["mode"]))])

	var arena: Arena = load("res://scenes/game/arena.tscn").instantiate()
	arena.configure_online(info)
	arena.auto_input = true
	_arena = arena
	_probe = HitProbe.new()
	_probe.label = label
	_probe.shots_dir = probe_shots
	add_child(_probe)
	var tree := get_tree()
	tree.root.add_child(arena)
	tree.current_scene = arena

	if drop_after > 0.0:
		tree.create_timer(drop_after).timeout.connect(_simulate_drop)


## Tunelə girmiş telefonu təqlid edir: peer bağlanır və oyun bunu
## adi bağlantı kəsilməsi kimi görür. Sonrasını [Arena] öz üzərinə götürür.
func _simulate_drop() -> void:
	_log("=== şəbəkə kəsilməsi simulyasiya olunur ===")
	Net.disconnect_from_server()
	Net.server_disconnected.emit()


func _on_burst(result: Dictionary) -> void:
	if bool(result.get("survived", false)):
		_log("matçı SAĞ bitirdi — %s" % ("QALİB" if result.get("won", false) else "sağ qaldı"))
	else:
		_log("PARTLADI — %d partlatma, tutum %d, %.0f s yaşadı (partladan: %s)" % [
			result["pops"], result["cap"], result["age"],
			result["killer"] if not str(result["killer"]).is_empty() else "aclıq"])

	# Oyun bitdi — DƏRHAL çıxırıq.
	#
	# [Arena] normalda menyuya qayıdır, menyu isə serveri yoxlamaq üçün şəbəkəyə
	# çıxır. Headless test client-ində bunun mənası yoxdur və CI logunu
	# "server yatıb" xətaları ilə doldururdu.
	_log_hits()
	get_tree().quit(0)


## Öz dəymələrin proqnozu serverlə nə qədər üst-üstə düşdü (bax [member Arena.hit_stats]).
##
## Şəbəkə gecikməsi ilə sınaq üçündür: proqnozun göstərdiyi hər dəymənin
## server tərəfindən təsdiqlənməsi və təsdiqin nə qədər gec gəldiyi buradan oxunur.
func _log_hits() -> void:
	if _arena == null or not is_instance_valid(_arena):
		return
	if _probe != null:
		_log(_probe.report())
	var st := _arena.hit_stats
	var ok := int(st["confirmed"])
	_log("VURUŞ: proqnoz %d · təsdiq %d · boş %d · yalnız server %d · orta təsdiq %.0f ms" % [
		int(st["predicted"]), ok, int(st["ghost"]), int(st["server_only"]),
		1000.0 * float(st["confirm_s"]) / float(maxi(ok, 1))])
	_log("XƏTT: proqnoz↔server yan fərqi orta %.1f px, maks %.1f px (%d top) · boşların %d-nin qurbanı artıq yox idi" % [
		float(st["line_off_sum"]) / float(maxi(int(st["lines"]), 1)), float(st["line_off_max"]),
		int(st["lines"]), int(st["ghost_gone"])])
	_log("SƏNƏ: botun topu proqnozla dəydi %d · server təsdiqlədi %d · təsdiqsiz %d · sərhəddə gözlədi %d (təsdiq %d, dəymədi %d) · geri qaytarılan top %d" % [
		int(st["self_pred"]), int(st["self_conf"]), int(st["self_false"]),
		int(st["self_soft"]), int(st["self_soft_conf"]), int(st["self_soft_miss"]),
		int(st["self_undo"])])
	_log("SƏRHƏD: öz topun qurbanın kənarına toxundu %d · server təsdiqlədi %d · dəymədi %d (geri qaytarılan top %d)" % [
		int(st["own_soft"]), int(st["own_soft_conf"]), int(st["own_soft_miss"]), int(st["own_soft_undo"])])
	if not (st["miss"] as Array).is_empty():
		_log("XƏTT: yalnız serverin saydığı dəymələrə ən yaxın proqnoz: %s" % ", ".join(st["miss"]))


## Komanda testinin addımı — hər [signal Friends.changed]-də çağırılır.
##
## Sorğunu yalnız bir tərəf göndərir, o biri avtomatik qəbul edir. Dost
## olandan sonra sorğu göndərən LİDERDİR: menyuda olan dostları dəvət edir.
## Komanda tam yığılanda hamı HAZIR basır.
func _social_step() -> void:
	if not Friends.online or _joined:
		return
	if not befriend_secret.is_empty() and not _asked:
		_asked = true
		# Vergüllə bir neçə açar — ÜÇLÜK testi üçün iki dost lazımdır.
		for one in befriend_secret.split(","):
			var tag := Social.tag_of(one)
			_log("dostluq sorğusu → #%s" % tag)
			Friends.request(tag)
	for t in Friends.requests.keys():
		_log("sorğu gəldi: %s — qəbul" % t)
		Friends.answer(t, true)
	if not befriend_secret.is_empty() and Friends.party_size() < party:
		for t in Friends.friends:
			if Friends.status_of(t) == Social.Presence.MENU and not _invited.has(t):
				_invited[t] = true
				_log("komandaya dəvət → %s" % Friends.friends[t]["name"])
				Friends.invite(t)
	var roster := str(Friends.party.get("members", []).map(func(m): return m[0]))
	if Friends.party_size() >= party and not Friends.am_ready() and _ready_for != roster:
		_ready_for = roster
		_log("komanda tamdır (%d nəfər, %s) — HAZIR" % [
			Friends.party_size(), Const.mode_name(int(Friends.party.get("mode", 0)))])
		Friends.set_ready(true)


func _log(msg: String) -> void:
	print("[%s] %s" % [label, msg])
