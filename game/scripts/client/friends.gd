extends Node
## Client tərəfdə dostluq və komanda (autoload `Friends`).
##
## Menyu ilə arena arasında səhnə dəyişir, dostlar və komanda isə dəyişmir —
## ona görə vəziyyət səhnədə yox, autoload-dadır. Dost siyahısının SAHİBİ bu
## cihazdır (`user://social.cfg`); niyə server deyil — bax [Social].
##
## Ekranlar ([MenuV2], [FriendsView]) yalnız oxuyur və buradakı əməlləri
## çağırır — şəbəkəyə birbaşa toxunmurlar.
##
## ── Niyə RPC-lər Net-də deyil, BURADADIR ────────────────────────────────
##
## Godot hər node-un RPC siyahısından checksum hesablayır və iki tərəfdə
## fərqli olanda həmin node-un BÜTÜN RPC-ləri işləmir. Dostluq RPC-ləri əvvəl
## [Net]-ə əlavə olunmuşdu: köhnə APK yeni serverə qoşulanda "rpc node
## checksum failed" alırdı və `request_join` də ölürdü — yəni yeniləməmiş
## oyunçu ümumiyyətlə oynaya bilmirdi. Ayrı node-da (`/root/Friends`, bu
## autoload serverdə də var) Net-in checksum-u dəyişmir: köhnə client yeni
## serverdə oynayır (sadəcə dostları yoxdur), yeni client köhnə serverdə də
## oynayır (dostluq mesajları cavabsız qalır).

signal changed()
## İnsana deyiləcək bir şey oldu: başlıq, izah və rəng növü ("ok" / "warn").
signal notice(title: String, sub: String, kind: String)
## Yeni komanda dəvəti gəldi (bax [member invites]).
signal invite_arrived(tag: String)

const PATH := "user://social.cfg"

## Bu cihazın gizli açarı və ondan çıxan oyunçu kodu (bax [method Social.tag_of]).
var secret := ""
var my_tag := ""
## kod -> {"name", "species", "seen"} — `seen` son dəfə onlayn görüldüyü unix vaxtı.
var friends := {}
## [[kod, ad, unix vaxtı], ...] — ən yenisi əvvəldə.
var recent: Array = []

## Bu sessiyada — diskə yazılmır.
var presence := {}          ## kod -> [enum Social.Presence]
var requests := {}          ## gələn sorğular: kod -> ad
var sent := {}              ## göndərdiyim sorğular: kod -> true (düymə "GÖNDƏRİLDİ" desin)
var invites := {}           ## gələn dəvətlər: kod -> {"name", "mode", "size", "until"}
## Qəbul etdiyim, amma server hələ təsdiqləmədiyi dostlar (bax [method answer]).
var _accepting := {}
## Komandanın serverdən gələn şəkli; boşdursa komandada deyilik
## (bax [method SocialHub.party_state]).
var party := {}
## Server bizi tanıdı (hello cavabı gəldi) — əməllər göndərilə bilər.
var online := false

## Veb linki ilə gələn niyyət: `?party=KOD` və ya `?friend=KOD`.
var _link_party := ""
var _link_friend := ""
## Test alətləri iki client-i bir kompüterdə işlədir — onlar diskə yazmamalıdır,
## yoxsa ikisi eyni açarı, yəni eyni kodu paylaşardı (bax [method use_secret]).
var persist := true
var _clock := 0.0


func _ready() -> void:
	# Serverdə bu node boşdur: onun dostları yoxdur, açar yaradıb diskə
	# yazmağın da mənası yoxdur (Render-in diski onsuz da müvəqqətidir).
	if OS.get_cmdline_user_args().has("--server"):
		persist = false
		set_process(false)
		return
	_load()
	_read_link()
	Net.connected_to_server.connect(hello)
	Net.server_disconnected.connect(_on_lost)
	Net.connection_failed.connect(_on_lost)


func _process(delta: float) -> void:
	_clock += delta
	# Bağlantını bəzən siqnalsız bağlayırlar (MƏŞQ-ə keçid, bax
	# [method MenuV2._practice]) — onda onlayn vəziyyətlər də köhnəlir.
	if online and not Net.is_connected_to_server():
		_on_lost()
	# Vaxtı keçmiş dəvətlər özü sönür — server də onları qəbul etməyəcək.
	if not invites.is_empty():
		var dead := []
		for t in invites:
			if float(invites[t]["until"]) <= _clock:
				dead.append(t)
		for t in dead:
			invites.erase(t)
		if not dead.is_empty():
			changed.emit()


# ================================================================ fayl

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		secret = str(cfg.get_value("id", "secret", ""))
		var keys := cfg.get_section_keys("friends") if cfg.has_section("friends") else PackedStringArray()
		for t in keys:
			var row = cfg.get_value("friends", t, [])
			if Social.is_tag(str(t)) and row is Array and (row as Array).size() >= 3:
				friends[str(t)] = {"name": str(row[0]), "species": int(row[1]), "seen": float(row[2])}
		var rec = cfg.get_value("recent", "list", [])
		if rec is Array:
			for r in rec:
				if r is Array and (r as Array).size() >= 3 and Social.is_tag(str(r[0])):
					recent.append([str(r[0]), str(r[1]), float(r[2])])
	if not Social.is_secret(secret):
		secret = Social.new_secret()
		save()
	my_tag = Social.tag_of(secret)


func save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("id", "secret", secret)
	for t in friends:
		var f: Dictionary = friends[t]
		cfg.set_value("friends", t, [f["name"], f["species"], f["seen"]])
	cfg.set_value("recent", "list", recent)
	cfg.save(PATH)


## Test alətləri üçün: diskə toxunmadan başqa açarla işlə.
func use_secret(value: String) -> void:
	persist = false
	secret = value
	my_tag = Social.tag_of(secret)
	friends.clear()
	recent.clear()


# ================================================================ link

## Veb versiya linklə açılıbsa (`?party=KOD`, `?friend=KOD`), niyyət yadda
## saxlanılır və server bizi tanıyan kimi icra olunur (bax [method _on_hello]).
func _read_link() -> void:
	if not OS.has_feature("web"):
		return
	var q = JavaScriptBridge.eval("location.search")
	if not (q is String) or (q as String).is_empty():
		return
	for part in (q as String).trim_prefix("?").split("&"):
		var kv := part.split("=")
		if kv.size() != 2:
			continue
		if kv[0] == "party":
			_link_party = Social.clean_code(kv[1].uri_decode())
		elif kv[0] == "friend":
			_link_friend = Social.clean_tag(kv[1].uri_decode())
	# Ünvan sətri təmizlənir: səhifəni yeniləyən oyunçu komandaya ikinci dəfə girməsin.
	JavaScriptBridge.eval("history.replaceState(null, '', location.pathname)")


## Linkdən gələn dost kodu — menyu onu bir dəfə götürür və DOSTLAR ekranını
## bu kodla açır. Sorğu özü göndərilmir: Brawl Stars-da da dost linki
## oyunçunun profilini açır, "əlavə et"-i oyunçu özü basır.
func take_friend_link() -> String:
	var t := _link_friend
	_link_friend = ""
	return t if Social.is_tag(t) and t != my_tag else ""


func share_link_party() -> String:
	return Social.party_link(Settings.address, str(party.get("code", "")))


func share_link_friend() -> String:
	return Social.friend_link(Settings.address, my_tag)


# ================================================================ vəziyyət

func in_party() -> bool:
	return not party.is_empty()


## Komandada məndən başqa kimsə varmı — OYNA yalnız onda "hazır" düyməsinə çevrilir.
func party_size() -> int:
	return (party.get("members", []) as Array).size()


func is_leader() -> bool:
	return in_party() and str(party.get("leader", "")) == my_tag


## Mən HAZIR-amı (komandanın şəklindən).
func am_ready() -> bool:
	for m in party.get("members", []):
		if str(m[0]) == my_tag:
			return bool(m[3])
	return false


func ready_count() -> int:
	var n := 0
	for m in party.get("members", []):
		if bool(m[3]):
			n += 1
	return n


## Məndən başqa üzvlər, komandadakı sırası ilə: [[kod, ad, növ, hazır, vəziyyət], ...]
func mates() -> Array:
	var out := []
	for m in party.get("members", []):
		if str(m[0]) != my_tag:
			out.append(m)
	return out


func status_of(tag: String) -> int:
	return int(presence.get(tag, Social.Presence.OFFLINE))


## Dostlar — oyuna qoşula biləcəyin yuxarıda, sonra ada görə.
func sorted_friends() -> Array[String]:
	var out: Array[String] = []
	for t in friends:
		out.append(str(t))
	out.sort_custom(func(a: String, b: String) -> bool:
		var pa := _rank(status_of(a))
		var pb := _rank(status_of(b))
		if pa != pb:
			return pa > pb
		return str(friends[a]["name"]).naturalnocasecmp_to(str(friends[b]["name"])) < 0)
	return out


## Sıralama: menyuda tək (dəvət olunur) > komandada > oyunda > oflayn.
static func _rank(p: int) -> int:
	match p:
		Social.Presence.MENU: return 3
		Social.Presence.PARTY: return 2
		Social.Presence.GAME: return 1
		_: return 0


func online_count() -> int:
	var n := 0
	for t in friends:
		if status_of(t) != Social.Presence.OFFLINE:
			n += 1
	return n


## Ana ekrandakı DOSTLAR düyməsinin qırmızı nişanı: cavab gözləyən şeylər.
func badge_count() -> int:
	return requests.size() + invites.size()


# ================================================================ əməllər

## Serverə özümüzü tanıdırıq. Qoşulan kimi və profil dəyişəndə çağırılır.
func hello() -> void:
	if Net.is_server or not Net.is_connected_to_server():
		return
	social_hello.rpc_id(1, secret, Net.nickname, int(Net.species), int(Net.mode),
		PackedStringArray(friends.keys()))


## Menyuda ad, növ və ya rejim dəyişdi — komanda yoldaşları podiumda dərhal görsün.
func profile_changed() -> void:
	if _can_send(false):
		social_profile.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))


func request(raw_tag: String) -> bool:
	var t := Social.clean_tag(raw_tag)
	if not Social.is_tag(t):
		_say("bad_tag", raw_tag)
		return false
	if t == my_tag:
		_say("self", "")
		return false
	if friends.has(t) and status_of(t) != Social.Presence.OFFLINE:
		_say("already", t)
		return false
	if not _can_send():
		return false
	sent[t] = true
	friend_request.rpc_id(1, t)
	changed.emit()
	return true


func answer(tag: String, accept: bool) -> void:
	if not _can_send():
		return
	friend_answer.rpc_id(1, tag, accept)
	var name := str(requests.get(tag, ""))
	requests.erase(tag)
	if accept:
		# Siyahıya DƏRHAL düşür — serverin təsdiqi (on_friend_added) adı yeniləyir.
		# Təsdiq gəlməsə (sorğu serverdə artıq yoxdur), geri götürülür —
		# yoxsa birtərəfli, əbədi "oflayn" dost qalardı.
		_accepting[tag] = true
		_add_friend(tag, name)
	changed.emit()


func remove(tag: String) -> void:
	friends.erase(tag)
	presence.erase(tag)
	save()
	if _can_send(false):
		friend_remove.rpc_id(1, tag)
	changed.emit()


func open_party() -> void:
	if _can_send():
		party_open.rpc_id(1)


func invite(tag: String) -> void:
	if _can_send():
		party_invite.rpc_id(1, tag)


func answer_invite(tag: String, accept: bool) -> void:
	invites.erase(tag)
	changed.emit()
	if _can_send():
		party_answer.rpc_id(1, tag, accept)


func join_code(raw: String) -> bool:
	var code := Social.clean_code(raw)
	if not Social.is_code(code):
		_say("bad_code", raw)
		return false
	if not _can_send():
		return false
	party_code.rpc_id(1, code)
	return true


func leave_party() -> void:
	if _can_send(false):
		party_leave.rpc_id(1)
	party = {}
	changed.emit()


func kick(tag: String) -> void:
	if _can_send():
		party_kick.rpc_id(1, tag)


func set_mode(mode: int) -> void:
	if _can_send(false):
		party_mode.rpc_id(1, mode)


func set_ready(on: bool) -> void:
	if _can_send():
		party_ready.rpc_id(1, on)


func _can_send(loud := true) -> bool:
	if online and Net.is_connected_to_server():
		return true
	if loud:
		_say("offline", "")
	return false


# ================================================================ RPC
#
# Client → server. Serverdə [SocialHub]-a ötürülür; client-də çağırılmır.
# Hamısı ETİBARLI kanaldadır: itən sorğu və ya dəvət növbəti paketlə düzəlmir.

@rpc("any_peer", "call_remote", "reliable")
func social_hello(secret_key: String, player_name: String, species: int, mode: int,
		list: PackedStringArray) -> void:
	if _hub() != null:
		_hub().hello(_sender(), secret_key, player_name, species, mode, list)


@rpc("any_peer", "call_remote", "reliable")
func social_profile(player_name: String, species: int, mode: int) -> void:
	if _hub() != null:
		_hub().profile(_sender(), player_name, species, mode)


@rpc("any_peer", "call_remote", "reliable")
func friend_request(tag: String) -> void:
	if _hub() != null:
		_hub().friend_request(_sender(), tag)


@rpc("any_peer", "call_remote", "reliable")
func friend_answer(tag: String, accept: bool) -> void:
	if _hub() != null:
		_hub().friend_answer(_sender(), tag, accept)


@rpc("any_peer", "call_remote", "reliable")
func friend_remove(tag: String) -> void:
	if _hub() != null:
		_hub().friend_remove(_sender(), tag)


@rpc("any_peer", "call_remote", "reliable")
func party_open() -> void:
	if _hub() != null:
		_hub().party_open(_sender())


@rpc("any_peer", "call_remote", "reliable")
func party_invite(tag: String) -> void:
	if _hub() != null:
		_hub().party_invite(_sender(), tag)


@rpc("any_peer", "call_remote", "reliable")
func party_answer(tag: String, accept: bool) -> void:
	if _hub() != null:
		_hub().party_answer(_sender(), tag, accept)


@rpc("any_peer", "call_remote", "reliable")
func party_code(code: String) -> void:
	if _hub() != null:
		_hub().party_code(_sender(), code)


@rpc("any_peer", "call_remote", "reliable")
func party_leave() -> void:
	if _hub() != null:
		_hub().party_leave(_sender())


@rpc("any_peer", "call_remote", "reliable")
func party_kick(tag: String) -> void:
	if _hub() != null:
		_hub().party_kick(_sender(), tag)


@rpc("any_peer", "call_remote", "reliable")
func party_mode(mode: int) -> void:
	if _hub() != null:
		_hub().party_mode(_sender(), mode)


@rpc("any_peer", "call_remote", "reliable")
func party_ready(on: bool) -> void:
	if _hub() != null:
		_hub().party_ready(_sender(), on)


## Serverin [SocialHub]-u; client-də `null`. Qaytarılan tip qəsdən yazılmayıb:
## tipli istinad serverin sinfini hər telefonun açılışında kompilyasiya etdirirdi
## (Friends autoload-dur).
func _hub():
	if not Net.is_server or Net.lobby == null:
		return null
	return Net.lobby.social


func _sender() -> int:
	return multiplayer.get_remote_sender_id()


# Server → client. Hamısı eyni yerə düşür (bax [method _on_event]).

@rpc("authority", "call_remote", "reliable")
func on_social_hello(tag: String) -> void:
	_on_event("on_social_hello", [tag])


@rpc("authority", "call_remote", "reliable")
func on_presence(rows: Array) -> void:
	_on_event("on_presence", [rows])


@rpc("authority", "call_remote", "reliable")
func on_friend_request(tag: String, player_name: String) -> void:
	_on_event("on_friend_request", [tag, player_name])


@rpc("authority", "call_remote", "reliable")
func on_friend_request_gone(tag: String) -> void:
	_on_event("on_friend_request_gone", [tag])


@rpc("authority", "call_remote", "reliable")
func on_friend_added(tag: String, player_name: String) -> void:
	_on_event("on_friend_added", [tag, player_name])


@rpc("authority", "call_remote", "reliable")
func on_friend_removed(tag: String) -> void:
	_on_event("on_friend_removed", [tag])


@rpc("authority", "call_remote", "reliable")
func on_party(state: Dictionary) -> void:
	_on_event("on_party", [state])


@rpc("authority", "call_remote", "reliable")
func on_party_invite(tag: String, player_name: String, mode: int, size: int, ttl: float) -> void:
	_on_event("on_party_invite", [tag, player_name, mode, size, ttl])


@rpc("authority", "call_remote", "reliable")
func on_recent(rows: Array) -> void:
	_on_event("on_recent", [rows])


@rpc("authority", "call_remote", "reliable")
func on_social_notice(what: String, arg: String) -> void:
	_on_event("on_social_notice", [what, arg])


# ================================================================ serverdən

func _on_event(method: String, args: Array) -> void:
	match method:
		"on_social_hello":
			_on_hello(str(args[0]))
		"on_presence":
			for row in args[0]:
				_on_presence_row(row)
			changed.emit()
		"on_friend_request":
			var t := str(args[0])
			requests[t] = str(args[1])
			_say("request_in", str(args[1]))
			changed.emit()
		"on_friend_request_gone":
			var t := str(args[0])
			requests.erase(t)
			if _accepting.has(t):
				_accepting.erase(t)
				friends.erase(t)
				save()
			changed.emit()
		"on_friend_added":
			var t := str(args[0])
			var fresh := not friends.has(t)
			_add_friend(t, str(args[1]))
			requests.erase(t)
			_accepting.erase(t)
			if fresh or sent.has(t):
				_say("friend_added", str(args[1]))
			sent.erase(t)
			changed.emit()
		"on_friend_removed":
			friends.erase(str(args[0]))
			presence.erase(str(args[0]))
			save()
			changed.emit()
		"on_party":
			_on_party(args[0])
		"on_party_invite":
			var t := str(args[0])
			invites[t] = {"name": str(args[1]), "mode": int(args[2]), "size": int(args[3]),
				"until": _clock + minf(float(args[4]), Social.INVITE_TTL)}
			invite_arrived.emit(t)
			changed.emit()
		"on_recent":
			for row in args[0]:
				add_recent(str(row[0]), str(row[1]))
			save()
			changed.emit()
		"on_social_notice":
			_say(str(args[0]), str(args[1]))


func _on_hello(tag: String) -> void:
	# Kod client-də də hesablanır; server başqa kod deyirsə, onunku keçərlidir
	# (eyni düstur, fərq ola bilməz — amma olarsa, server sözü son sözdür).
	my_tag = tag
	online = true
	if Social.is_code(_link_party):
		party_code.rpc_id(1, _link_party)
		_link_party = ""
	changed.emit()


func _on_presence_row(row: Array) -> void:
	var t := str(row[0])
	if not friends.has(t):
		return
	var p := int(row[1])
	var was := status_of(t)
	presence[t] = p
	var f: Dictionary = friends[t]
	if not str(row[2]).is_empty():
		f["name"] = str(row[2])
	f["species"] = int(row[3])
	if p == Social.Presence.OFFLINE and was != Social.Presence.OFFLINE:
		f["seen"] = Time.get_unix_time_from_system()
		save()
	elif p != Social.Presence.OFFLINE:
		f["seen"] = Time.get_unix_time_from_system()


func _on_party(state: Dictionary) -> void:
	var was_in := in_party()
	party = state
	if in_party():
		# Rejimi lider seçir — üzvün menyusu onu göstərir (bax [MenuV2._refresh_mode]).
		Net.mode = Const.mode_from(int(party.get("mode", 0)))
	elif was_in:
		_say("party_left", "")
	changed.emit()


## Bağlantı getdi: onlayn vəziyyətləri artıq doğru deyil.
func _on_lost() -> void:
	var now := Time.get_unix_time_from_system()
	for t in presence:
		if int(presence[t]) != Social.Presence.OFFLINE and friends.has(t):
			friends[t]["seen"] = now
	presence.clear()
	invites.clear()
	# Gələn sorğular serverin yaddaşındadır — qoşulanda yenidən gəlir. Burada
	# qalsaydı, server yenidən qalxandan sonra artıq olmayan sorğu qəbul edilərdi.
	requests.clear()
	_accepting.clear()
	party = {}
	online = false
	save()
	changed.emit()


func _add_friend(tag: String, name: String) -> void:
	if not Social.is_tag(tag):
		return
	if friends.size() >= Social.FRIEND_MAX and not friends.has(tag):
		_say("list_full", "")
		return
	var f: Dictionary = friends.get(tag, {"name": name, "species": 0, "seen": 0.0})
	if not name.is_empty():
		f["name"] = name
	friends[tag] = f
	save()


func add_recent(tag: String, name: String) -> void:
	if not Social.is_tag(tag) or tag == my_tag:
		return
	for i in range(recent.size() - 1, -1, -1):
		if str(recent[i][0]) == tag:
			recent.remove_at(i)
	recent.push_front([tag, name, Time.get_unix_time_from_system()])
	while recent.size() > Social.RECENT_MAX:
		recent.pop_back()


func _say(what: String, arg: String) -> void:
	var t := notice_text(what, arg)
	if not t.is_empty():
		notice.emit(t[0], t[1], t[2])


## Serverin və client-in bildiriş kodları insan dilində.
static func notice_text(what: String, arg: String) -> Array:
	match what:
		"request_sent": return ["SORĞU GÖNDƏRİLDİ", "#%s qəbul edəndə dostların siyahısına düşəcək." % arg, "ok"]
		"request_in": return ["YENİ DOSTLUQ SORĞUSU", "%s səni dost əlavə etmək istəyir." % arg, "ok"]
		"friend_added": return ["YENİ DOST!", "%s artıq dostlarının siyahısındadır." % arg, "ok"]
		"invite_sent": return ["DƏVƏT GÖNDƏRİLDİ", "%s cavab verəndə podiumda yanında görünəcək." % arg, "ok"]
		"invite_declined": return ["DƏVƏT RƏDD EDİLDİ", "%s indi oynaya bilmir." % arg, "warn"]
		"invite_gone": return ["DƏVƏTİN VAXTI KEÇİB", "Komanda artıq dağılıb və ya oyundadır.", "warn"]
		"bad_tag": return ["BELƏ KOD YOXDUR", "Kod %d simvoldur, yalnız bunlardan: %s" % [Social.TAG_LEN, " ".join(Social.TAG_ALPHABET.split(""))], "warn"]
		"self": return ["BU SƏNİN ÖZ KODUNDUR", "Dostunun kodunu yaz.", "warn"]
		"already": return ["ARTIQ DOSTSUNUZ", "", "ok"]
		"busy": return ["SORĞU GÖNDƏRİLMƏDİ", "Bu oyunçunun çoxlu cavabsız sorğusu var.", "warn"]
		"not_friend": return ["YALNIZ DOSTLAR", "Dəvət üçün ikiniz də bir-birinizin siyahısında olmalısınız.", "warn"]
		"in_game": return ["OYUNDADIR", "%s matçı bitirəndə yenidən dəvət et." % arg if not arg.is_empty() else "Matç bitəndən sonra.", "warn"]
		"party_full": return ["KOMANDA DOLUDUR", "Komandada ən çox %d nəfər olur." % Social.PARTY_MAX, "warn"]
		"bad_code": return ["KOMANDA TAPILMADI", "Kodu yoxla — komanda dağılmış ola bilər.", "warn"]
		"kicked": return ["KOMANDADAN ÇIXARILDIN", "%s səni komandadan çıxardı." % arg, "warn"]
		"party_left": return ["KOMANDADAN ÇIXDIN", "", "ok"]
		"mode_small": return ["KOMANDA BU REJİM ÜÇÜN BÖYÜKDÜR", "%s — %s" % [Const.mode_name(int(arg)), _limit_text(int(arg))], "warn"]
		"elsewhere": return ["BAŞQA CİHAZDA AÇILDI", "Dostlar o cihazdadır — bu pəncərədə yalnız oyun işləyir.", "warn"]
		"offline": return ["SERVERƏ QOŞULMAYIB", "Dostlar və komanda yalnız onlayn işləyir.", "warn"]
		"list_full": return ["SİYAHI DOLUDUR", "Ən çox %d dost ola bilər." % Social.FRIEND_MAX, "warn"]
		"copied": return ["KOPYALANDI", arg, "ok"]
	return []


static func _limit_text(mode: int) -> String:
	var n := Social.party_limit(mode)
	return "tək oynanır" if n == 1 else "ən çox %d nəfər" % n
