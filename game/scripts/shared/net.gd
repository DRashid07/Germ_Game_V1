extends Node
## Şəbəkə təbəqəsi — client və server arasındakı bütün mesajlar buradan keçir.
##
## Bu autoload həm client-də, həm serverdə eyni node yolunda (`/root/Net`) yaşayır.
## Godot-un RPC sistemi məhz buna görə işləyir: hər iki tərəfdə eyni ünvan.
##
## Qayda: client YALNIZ input göndərir. Toqquşma, udma, partlama qərarlarını
## həmişə server verir — cheat qorunması buradan başlayır.
##
## Oyun io tiplidir: matçmeykinq növbəsi yoxdur. "Oyna" düyməsi birbaşa
## açıq dünyaya girir, mikrob partlayanda isə oyunçu dünyadan çıxarılır.

signal connected_to_server()
signal connection_failed()
signal server_disconnected()

signal world_joined(info: Dictionary)
signal join_rejected(reason: String)
signal snapshot_arrived(data: Array)
## Ad/rəng cədvəli gəldi (bax [method on_roster]).
signal roster_arrived(table: Dictionary)
signal you_burst(result: Dictionary)
signal rejoin_failed()
signal server_message(text: String)

var is_server := false
var local_id := 0
var nickname := "Mikrob"
## Oyunçunun seçdiyi mikrob növü (bax [enum Const.Species]). Menyuda seçilir,
## dünyaya girərkən bir dəfə serverə göndərilir və oradan hamıya yayılır.
var species := Const.Species.CILIATE

## Menyuda seçilmiş rejim — dünyaya girərkən bir dəfə serverə göndərilir.
var mode := Const.Mode.ENDLESS

var _peer: MultiplayerPeer = null
## Serverdə lobby-ni saxlayır; client-də həmişə null.
var lobby: Node = null

## İşlədilən nəqliyyat — diaqnostika və UI üçün.
var transport := "enet"

## Sonuncu qoşulma ünvanı — bağlantı kəsiləndə avtomatik təkrar cəhd üçün saxlanılır.
var last_address := ""
var last_port := Const.DEFAULT_PORT


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


# ---------------------------------------------------------------- qoşulma

## Serveri qaldırır (headless rejim üçün).
##
## İki nəqliyyat var:
##   • **ENet (UDP)** — ən aşağı gecikmə, oyun üçün ideal. Öz VPS-ində bunu işlət.
##   • **WebSocket (TCP)** — bir az yavaş, amma hər yerdən keçir. Railway və
##     bənzər PaaS platformaları ictimai UDP-yə icazə vermir, orada bu lazımdır.
func host_server(port: int = Const.DEFAULT_PORT, use_websocket := false) -> Error:
	var err := OK
	if use_websocket:
		var ws := WebSocketMultiplayerPeer.new()
		err = ws.create_server(port)
		_peer = ws
		transport = "websocket"
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_server(port, Const.MAX_CLIENTS)
		_peer = enet
		transport = "enet"

	if err != OK:
		push_error("Server %d portunda qalxa bilmədi: %s" % [port, error_string(err)])
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	is_server = true
	local_id = 1
	print("[server] %d portunda dinləyir (%s)" % [port, transport])
	return OK


## Serverə qoşulur.
##
## Ünvan `ws://` və ya `wss://` ilə başlayırsa WebSocket, əks halda ENet işlədilir —
## beləcə menyuda ayrıca seçim düyməsinə ehtiyac qalmır.
func join_server(address: String, port: int = Const.DEFAULT_PORT) -> Error:
	last_address = address
	last_port = port
	var err := OK
	if address.begins_with("ws://") or address.begins_with("wss://"):
		var ws := WebSocketMultiplayerPeer.new()
		err = ws.create_client(address)
		_peer = ws
		transport = "websocket"
	else:
		var enet := ENetMultiplayerPeer.new()
		err = enet.create_client(address, port)
		_peer = enet
		transport = "enet"

	if err != OK:
		push_error("Qoşulma alınmadı: %s" % error_string(err))
		_peer = null
		return err

	multiplayer.multiplayer_peer = _peer
	is_server = false
	return OK


## Növbədəki paketləri dərhal yola salır.
##
## Bağlantını bağlamazdan ƏVVƏL çağırılır: RPC növbədə qalıb peer bağlansa,
## ENet paketi kanalsız peer-ə göndərməyə çalışır və xəta yazır.
func flush() -> void:
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		(peer as ENetMultiplayerPeer).host.flush()


func disconnect_from_server() -> void:
	if _peer != null:
		_peer.close()
		_peer = null
	multiplayer.multiplayer_peer = null
	local_id = 0
	is_server = false


## Serverə qoşulmuşuq VƏ əl sıxışma bitib — yəni ona söz göndərmək olar.
##
## Yalnız nəqliyyat vəziyyətini soruşmaq AZDIR və bu, sükutla oyunu sındırır.
## Godot hər oyuna standart olaraq [OfflineMultiplayerPeer] qoyur: heç bir
## şəbəkə yoxdur, amma o, özünü "QOŞULU" elan edir və `get_unique_id()` 1
## qaytarır — yəni "mən serverəm". Nəticədə:
##
##   • menyu hələ heç yerə qoşulmadan özünü "onlayn" sayır,
##   • `Net.request_join.rpc_id(1, ...)` çağırışı ÖZÜMÜZƏ göndərilmiş sayılır
##     və "RPC on yourself is not allowed" xətası ilə itir,
##   • oyunçu OYNA basır, heç nə olmur.
##
## [member local_id] yalnız əl sıxışma bitəndə doldurulur
## ([method _on_connected]) və bağlantı qopanda sıfırlanır — serverə söz
## göndərməyin yeganə etibarlı şərti odur.
func is_connected_to_server() -> bool:
	return local_id != 0 \
		and multiplayer.multiplayer_peer != null \
		and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func _on_connected() -> void:
	local_id = multiplayer.get_unique_id()
	print("[client] qoşuldu, id=%d" % local_id)
	connected_to_server.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_server_disconnected() -> void:
	local_id = 0
	server_disconnected.emit()


func _on_peer_connected(id: int) -> void:
	if is_server:
		print("[server] peer qoşuldu: %d" % id)


func _on_peer_disconnected(id: int) -> void:
	if is_server:
		print("[server] peer ayrıldı: %d" % id)
		if lobby != null:
			lobby.remove_peer(id)


# ================================================================
#  CLIENT  →  SERVER
# ================================================================

## Dünyaya girmək. Növbə yoxdur — yer varsa oyunçu dərhal doğulur.
@rpc("any_peer", "call_remote", "reliable")
func request_join(player_name: String, species: int, mode := 0) -> void:
	if not is_server or lobby == null:
		return
	lobby.join(multiplayer.get_remote_sender_id(), player_name, species, mode)


## Bağlantı kəsildikdən sonra öz mikrobuna qayıtmaq. Nişan dünyaya girəndə
## verilir və yeni peer id-ni köhnə mikrobla birləşdirir.
@rpc("any_peer", "call_remote", "reliable")
func request_rejoin(token: String) -> void:
	if not is_server or lobby == null:
		return
	lobby.rejoin(multiplayer.get_remote_sender_id(), token)


## Oyunçu könüllü çıxır (menyuya qayıdır).
@rpc("any_peer", "call_remote", "reliable")
func request_leave() -> void:
	if not is_server or lobby == null:
		return
	lobby.leave(multiplayer.get_remote_sender_id())


## Bir tick-lik giriş. Unreliable — köhnəlmiş inputu təkrar göndərməyin mənası
## yoxdur, növbəti paket onsuz da 33 ms sonra gəlir.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func send_input(packed: Array) -> void:
	if not is_server or lobby == null:
		return
	lobby.route_input(multiplayer.get_remote_sender_id(), packed)


# ================================================================
#  SERVER  →  CLIENT
# ================================================================

## Dünyaya girdin. `info` mikrobun id-sini, rəngini və sessiya nişanını daşıyır.
@rpc("authority", "call_remote", "reliable")
func on_world_join(info: Dictionary) -> void:
	world_joined.emit(info)


## Yer yoxdur və ya ad qəbul edilmədi.
@rpc("authority", "call_remote", "reliable")
func on_join_rejected(reason: String) -> void:
	join_rejected.emit(reason)


## 30 Hz state snapshot. Sıralı, amma etibarsız — itən paket növbəti ilə əvəzlənir.
## Hər oyunçuya YALNIZ öz görüş sahəsindəki obyektlər göndərilir.
@rpc("authority", "call_remote", "unreliable_ordered")
func on_snapshot(data: Array) -> void:
	snapshot_arrived.emit(data)


## Ad və rəng cədvəli: `{id: [ad, rəng]}`.
##
## ETİBARLI kanalla gedir və yalnız mikrobların dəsti dəyişəndə göndərilir.
## Snapshot-dan fərqli olaraq bu itə bilməz: itsəydi, adsız mikroblar ekranda
## qalardı və növbəti paket onu düzəltməzdi (cədvəl hər tick göndərilmir).
@rpc("authority", "call_remote", "reliable")
func on_roster(table: Dictionary) -> void:
	roster_arrived.emit(table)


## Mikrobun partladı — oyun bitdi, nəticə ekranı göstərilir.
@rpc("authority", "call_remote", "reliable")
func on_burst(result: Dictionary) -> void:
	you_burst.emit(result)


## Nişan artıq keçərli deyil — mikrob partlayıb və ya gözləmə vaxtı dolub.
@rpc("authority", "call_remote", "reliable")
func on_rejoin_failed() -> void:
	rejoin_failed.emit()


@rpc("authority", "call_remote", "reliable")
func on_server_message(text: String) -> void:
	server_message.emit(text)


## "host:port" formatını ayırır; port yazılmayıbsa standart port işlədilir.
## `ws://` və `wss://` ünvanları toxunulmadan ötürülür — porta orada URL özü qərar verir.
##
## Statikdir ki, testdən keçirilə bilsin: Railway ünvanı məhz buradan keçir və
## səhv ayrılsa oyun ümumiyyətlə qoşula bilmir.
##
## Menyuda YOX, burada yaşayır: ünvanı hər menyu variantı oxuyur, menyular isə
## dəyişir — köhnəsi silinəndə ayrışdırma onunla birlikdə getməməlidir.
static func parse_address(raw_text: String) -> Array:
	var raw := raw_text.strip_edges()
	if raw.begins_with("ws://") or raw.begins_with("wss://"):
		return [raw, 0]

	var port := Const.DEFAULT_PORT
	var host := raw
	var colon := raw.rfind(":")
	if colon > 0:
		host = raw.substr(0, colon)
		var tail := raw.substr(colon + 1)
		if tail.is_valid_int():
			port = int(tail)
	if host.is_empty():
		host = "127.0.0.1"
	return [host, port]
