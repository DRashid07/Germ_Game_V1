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

var _joined := false


func _ready() -> void:
	Net.nickname = label
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
			get_tree().quit(0))


func _on_connected() -> void:
	if _joined:
		# Artıq dünyadayıq — bu təkrar qoşulmadır. Yenidən girmək olmaz,
		# nişanla mikroba qayıtmağı [Arena] özü edir.
		_log("yenidən qoşuldu (id=%d), nişanla qayıdır" % Net.local_id)
		return
	_log("qoşuldu (id=%d), dünyaya girir" % Net.local_id)
	Net.request_join.rpc_id(1, label, int(Const.Species.CILIATE))


func _on_world_joined(info: Dictionary) -> void:
	if _joined:
		return
	_joined = true
	_log("DÜNYAYA GİRDİ — id=%d, rəng=%d" % [info["you"], info["color"]])

	var arena: Arena = load("res://scenes/game/arena.tscn").instantiate()
	arena.configure_online(info)
	arena.auto_input = true
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
	_log("PARTLADI — %d partlatma, tutum %d, %.0f s yaşadı (partladan: %s)" % [
		result["pops"], result["cap"], result["age"],
		result["killer"] if not str(result["killer"]).is_empty() else "aclıq"])


func _log(msg: String) -> void:
	print("[%s] %s" % [label, msg])
