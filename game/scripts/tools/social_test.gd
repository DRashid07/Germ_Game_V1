class_name SocialTest
extends RefCounted
## Dostluq və komanda sisteminin headless testləri — [SimTest]-in içindən işləyir.
##
## [SocialHub] şəbəkəyə toxunmur: mesajları [member SocialHub.send] ilə
## göndərir. Burada o, [Wire]-a bağlanır və hər mesaj yazılır — yəni bütün
## axın (sorğu → qəbul → vəziyyət → dəvət → hazır → oyun) serversiz yoxlanılır.

const PA := 11
const PB := 22
const PC := 33
const PD := 44
const PE := 55

static var SA := "a".repeat(32)
static var SB := "b".repeat(32)
static var SC := "c".repeat(32)
static var SD := "d".repeat(32)
static var SE := "e".repeat(32)


## Hub-ın "şəbəkəsi": göndərilən hər mesaj və oyuna salınan hər komanda.
class Wire:
	var log: Array = []
	var started: Array = []
	var playing := {}

	func send(peer: int, method: String, args: Array) -> void:
		log.append([peer, method, args])

	func start(peers: Array, mode: int) -> void:
		started.append([peers.duplicate(), mode])

	func in_game(peer: int) -> bool:
		return playing.has(peer)

	## [param peer]-ə gedən [param method] mesajlarının arqumentləri; oxunanlar silinir.
	func take(peer: int, method: String) -> Array:
		var out := []
		var keep := []
		for m in log:
			if int(m[0]) == peer and str(m[1]) == method:
				out.append(m[2])
			else:
				keep.append(m)
		log = keep
		return out

	func clear() -> void:
		log.clear()


static func _hub() -> Array:
	var hub := SocialHub.new()
	var w := Wire.new()
	hub.send = w.send
	hub.start = w.start
	hub.in_game = w.in_game
	return [hub, w]


static func T(secret: String) -> String:
	return Social.tag_of(secret)


static func _check(ok: bool, label: String) -> void:
	SimTest._check(ok, label)


static func run() -> void:
	print("\n----- Dostluq və komanda -----")
	_test_tags()
	_test_tag_catches_typos()
	_test_links()
	_test_request_flow()
	_test_presence_needs_mutual()
	_test_answer_needs_request()
	_test_crossed_requests()
	_test_offline_accept_mail()
	_test_remove_friend()
	_test_request_rate_limit()
	_test_same_tag_two_windows()
	_test_party_invite()
	_test_party_ready_start()
	_test_party_code_join()
	_test_party_leader_leaves()
	_test_party_grace()
	_test_party_mode_rules()
	_test_party_kick()
	_test_recent_players()
	_test_world_party_seating()
	_test_notice_texts()


# ---------------------------------------------------------------- kod

static func _test_tags() -> void:
	var t := T(SA)
	_check(t == T(SA), "oyunçu kodu açardan sabit çıxır (#%s)" % t)
	_check(t.length() == Social.TAG_LEN and Social.is_tag(t),
		"kod %d simvoldur və yoxlamadan keçir" % Social.TAG_LEN)
	var bad := 0
	var seen := {}
	for i in 300:
		var s := Social.new_secret()
		var tag := T(s)
		if not Social.is_tag(tag):
			bad += 1
		seen[tag] = true
	_check(bad == 0 and seen.size() == 300, "300 təsadüfi açarın hamısı düzgün və fərqli koddur")
	_check(Social.clean_tag(" #%s " % t.to_lower()) == t, "yazılan kod təmizlənir: #, boşluq, kiçik hərf")
	var with_o := t.replace("0", "O")
	_check(Social.clean_tag(with_o) == t, "O hərfi sıfıra çevrilir")
	_check(not Social.is_tag(t.substr(0, 8)) and not Social.is_tag(t + "0"), "uzunluğu səhv kod rədd edilir")
	_check(not Social.is_secret("xyz") and Social.is_secret(SA), "gizli açarın forması yoxlanılır")


## Yoxlama simvolu: bir simvolu səhv yazılmış HƏR kod rədd edilməlidir.
## Server oflayn oyunçunu tanımır — yazma səhvini tutan yeganə yer budur.
static func _test_tag_catches_typos() -> void:
	var missed := 0
	var total := 0
	var swaps := 0
	var swaps_caught := 0
	for s in [SA, SB, SC, SD, SE]:
		var tag := T(s)
		for i in tag.length():
			for c in Social.TAG_ALPHABET:
				if c == tag[i]:
					continue
				total += 1
				var typo := tag.substr(0, i) + c + tag.substr(i + 1)
				if Social.is_tag(typo):
					missed += 1
		for i in tag.length() - 1:
			if tag[i] == tag[i + 1]:
				continue
			swaps += 1
			var sw := tag.substr(0, i) + tag[i + 1] + tag[i] + tag.substr(i + 2)
			if not Social.is_tag(sw):
				swaps_caught += 1
	_check(missed == 0, "bir simvolluq yazma səhvlərinin hamısı tutulur (%d/%d)" % [total - missed, total])
	_check(swaps_caught * 10 >= swaps * 9,
		"qonşu simvolların yerdəyişməsi ən azı 90%% tutulur (%d/%d)" % [swaps_caught, swaps])


static func _test_links() -> void:
	_check(Social.link_base("wss://germ-arena.onrender.com/ws") == "https://germ-arena.onrender.com/",
		"link server ünvanından çıxır (wss → https, /ws atılır)")
	_check(Social.link_base("ws://127.0.0.1:27015") == "http://127.0.0.1:27015/", "yerli server: ws → http")
	_check(Social.party_link("wss://x.com/ws", "ABC234") == "https://x.com/?party=ABC234", "komanda linki")
	_check(Social.fit_mode(Const.Mode.SOLO, 2) == Const.Mode.DUO
		and Social.fit_mode(Const.Mode.DUO, 3) == Const.Mode.TRIO
		and Social.fit_mode(Const.Mode.ENDLESS, 3) == Const.Mode.ENDLESS,
		"komanda böyüyəndə rejim uyğunlaşır: TƏK→CÜT, CÜT→ÜÇLÜK, SONSUZ qalır")


# ---------------------------------------------------------------- dostluq

static func _test_request_flow() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	_check(w.take(PA, "on_social_hello") == [[T(SA)]], "hello cavabı oyunçunun kodunu qaytarır")
	# B hələ oflayndır — sorğu gözləyir.
	hub.friend_request(PA, "#" + T(SB).to_lower())
	var sent := w.take(PA, "on_social_notice")
	_check(sent.size() == 1 and str(sent[0][0]) == "request_sent", "oflayn oyunçuya sorğu qəbul edilir")
	hub.hello(PB, SB, "Bob", 1, 0, PackedStringArray())
	var got := w.take(PB, "on_friend_request")
	_check(got.size() == 1 and str(got[0][0]) == T(SA) and str(got[0][1]) == "Ana",
		"B qoşulanda gözləyən sorğunu alır")
	hub.friend_answer(PB, T(SA), true)
	var to_a := w.take(PA, "on_friend_added")
	var to_b := w.take(PB, "on_friend_added")
	_check(to_a.size() == 1 and str(to_a[0][0]) == T(SB) and str(to_a[0][1]) == "Bob",
		"qəbuldan sonra A-ya 'Bob dostundur' gedir")
	_check(to_b.size() == 1 and str(to_b[0][0]) == T(SA), "B-yə də 'Ana dostundur' gedir")
	_check(hub.mutual(T(SA), T(SB)), "ikisi də bir-birinin siyahısındadır")
	var pres := w.take(PA, "on_presence")
	var seen_b := false
	for rows in pres:
		for r in rows[0]:
			if str(r[0]) == T(SB) and int(r[1]) == Social.Presence.MENU and int(r[3]) == 1:
				seen_b = true
	_check(seen_b, "A B-ni 'menyuda' görür (növü ilə)")
	w.clear()
	w.playing[PB] = true
	hub.set_in_game(PB, true)
	var p2 := w.take(PA, "on_presence")
	_check(p2.size() == 1 and int(p2[0][0][0][1]) == Social.Presence.GAME, "B oyuna girəndə A 'oyunda' görür")
	hub.drop(PB)
	var p3 := w.take(PA, "on_presence")
	_check(p3.size() == 1 and int(p3[0][0][0][1]) == Social.Presence.OFFLINE, "B çıxanda A 'oflayn' görür")


## Siyahı client-dən gəlir — yad biri kodunu yazmaqla vəziyyətini görə bilməz.
static func _test_presence_needs_mutual() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PB, SB, "Bob", 0, 0, PackedStringArray())
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray([T(SB)]))
	var leak := false
	for rows in w.take(PA, "on_presence"):
		for r in rows[0]:
			if str(r[0]) == T(SB):
				leak = true
	_check(not leak, "birtərəfli siyahı B-nin vəziyyətini göstərmir")
	w.playing[PB] = true
	hub.set_in_game(PB, true)
	_check(w.take(PA, "on_presence").is_empty(), "B-nin dəyişən vəziyyəti də A-ya getmir")
	hub.party_invite(PA, T(SB))
	_check(w.take(PB, "on_party_invite").is_empty(), "qarşılıqsız 'dosta' dəvət getmir")


static func _test_answer_needs_request() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	hub.hello(PC, SC, "Cem", 0, 0, PackedStringArray())
	hub.friend_answer(PC, T(SA), true)
	_check(w.take(PA, "on_friend_added").is_empty(), "sorğusuz 'qəbul' heç kimi dost etmir")
	_check(w.take(PC, "on_friend_request_gone").size() == 1, "client-ə sorğunun olmadığı deyilir")


static func _test_crossed_requests() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	hub.hello(PB, SB, "Bob", 0, 0, PackedStringArray())
	hub.friend_request(PA, T(SB))
	hub.friend_request(PB, T(SA))
	_check(w.take(PA, "on_friend_added").size() == 1 and w.take(PB, "on_friend_added").size() == 1,
		"qarşılıqlı sorğular avtomatik dostluqdur")
	_check(not (hub.requests.get(T(SA), {}) as Dictionary).has(T(SB))
		and not (hub.requests.get(T(SB), {}) as Dictionary).has(T(SA)), "gözləyən sorğu qalmır")


static func _test_offline_accept_mail() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	hub.friend_request(PA, T(SB))
	hub.drop(PA)
	hub.hello(PB, SB, "Bob", 0, 0, PackedStringArray())
	hub.friend_answer(PB, T(SA), true)
	_check(w.take(PB, "on_friend_added").size() == 1, "B qəbul edir, A oflayndır")
	hub.hello(PC, SA, "Ana", 0, 0, PackedStringArray())
	var got := w.take(PC, "on_friend_added")
	_check(got.size() == 1 and str(got[0][0]) == T(SB), "A qayıdanda poçtdan 'Bob dostundur' alır")
	_check(hub.mutual(T(SA), T(SB)), "poçtdan sonra dostluq qarşılıqlıdır")


static func _test_remove_friend() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray([T(SB)]))
	hub.hello(PB, SB, "Bob", 0, 0, PackedStringArray([T(SA)]))
	_check(hub.mutual(T(SA), T(SB)), "hər iki siyahıda olan kodlar dostdur")
	hub.friend_remove(PA, T(SB))
	_check(w.take(PB, "on_friend_removed").size() == 1 and not hub.mutual(T(SA), T(SB)),
		"silinəndə qarşı tərəfə xəbər gedir")
	# Oflayn silinmə — poçtla.
	hub.hello(PC, SC, "Cem", 0, 0, PackedStringArray([T(SA)]))
	hub.drop(PC)
	hub.friend_remove(PA, T(SC))
	hub.hello(PD, SC, "Cem", 0, 0, PackedStringArray([T(SA)]))
	_check(w.take(PD, "on_friend_removed").size() == 1, "oflayn olan silinməni qoşulanda öyrənir")


static func _test_request_rate_limit() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	for i in 30:
		hub.friend_request(PA, T(Social.new_secret()))
	var n := w.take(PA, "on_social_notice").size()
	_check(n <= int(SocialHub.ACTION_BURST), "sorğu spamı kəsilir (%d/30 keçdi)" % n)
	hub.tick(3.0)
	hub.friend_request(PA, T(Social.new_secret()))
	_check(w.take(PA, "on_social_notice").size() == 1, "gözləyəndən sonra yenə göndərmək olur")


static func _test_same_tag_two_windows() -> void:
	var h = _hub()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.hello(PA, SA, "Ana", 0, 0, PackedStringArray())
	hub.hello(PB, SA, "Ana", 0, 0, PackedStringArray())
	var n := w.take(PA, "on_social_notice")
	_check(n.size() == 1 and str(n[0][0]) == "elsewhere", "eyni kod ikinci pəncərədə açılanda birinciyə deyilir")
	_check(hub.tag_of_peer(PB) == T(SA) and hub.tag_of_peer(PA).is_empty(), "kod sonuncu pəncərədə qalır")
	# Köhnə pəncərənin qopması yenisini silməməlidir.
	hub.drop(PA)
	_check(hub.online.has(T(SA)), "köhnə pəncərənin qopması yeni sessiyanı pozmur")


# ---------------------------------------------------------------- komanda

## Üç qarşılıqlı dost (A, B, C) və bir yad (D).
static func _friends3() -> Array:
	var h = _hub()
	var hub: SocialHub = h[0]
	hub.hello(PA, SA, "Ana", 0, int(Const.Mode.SOLO), PackedStringArray([T(SB), T(SC)]))
	hub.hello(PB, SB, "Bob", 1, 0, PackedStringArray([T(SA), T(SC)]))
	hub.hello(PC, SC, "Cem", 2, 0, PackedStringArray([T(SA), T(SB)]))
	hub.hello(PD, SD, "Dan", 0, 0, PackedStringArray())
	(h[1] as Wire).clear()
	return h


static func _last_party(w: Wire, peer: int) -> Dictionary:
	var all := w.take(peer, "on_party")
	return all[-1][0] if not all.is_empty() else {}


static func _test_party_invite() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	var inv := w.take(PB, "on_party_invite")
	_check(inv.size() == 1 and str(inv[0][0]) == T(SA) and str(inv[0][1]) == "Ana",
		"dəvət dosta çatır (kimdən, adı)")
	_check(float(inv[0][4]) > 50.0, "dəvətin ömrü göndərilir (%.0f s)" % float(inv[0][4]))
	hub.party_answer(PB, T(SA), true)
	var st := _last_party(w, PA)
	_check((st.get("members", []) as Array).size() == 2 and str(st["leader"]) == T(SA),
		"qəbuldan sonra komanda iki nəfərdir, lider dəvət edəndir")
	_check(int(st.get("mode", -1)) == Const.Mode.DUO, "TƏK QALAN-da olan liderin komandası CÜT-ə keçir")
	_check(not _last_party(w, PB).is_empty(), "yeni üzv də komandanın şəklini alır")
	_check(hub.presence_of(T(SA)) == Social.Presence.PARTY, "üzvlər dostlarına 'komandada' görünür")
	hub.party_invite(PA, T(SD))
	var n := w.take(PA, "on_social_notice")
	_check(w.take(PD, "on_party_invite").is_empty() and str(n[-1][0]) == "not_friend",
		"yada dəvət getmir")
	w.playing[PC] = true
	hub.set_in_game(PC, true)
	hub.party_invite(PA, T(SC))
	_check(w.take(PC, "on_party_invite").is_empty(), "oyunda olan dosta dəvət getmir")
	# Rədd — dəvət edənə deyilir.
	w.playing.erase(PC)
	hub.set_in_game(PC, false)
	hub.party_invite(PA, T(SC))
	hub.party_answer(PC, T(SA), false)
	var d := w.take(PA, "on_social_notice")
	_check(str(d[-1][0]) == "invite_declined" and str(d[-1][1]) == "Cem", "rədd dəvət edənə çatır")
	# Vaxtı keçmiş dəvət qəbul olunmur.
	hub.party_invite(PA, T(SC))
	hub.tick(Social.INVITE_TTL + 1.0)
	hub.party_answer(PC, T(SA), true)
	_check((hub.parties[hub.party_of[T(SA)]] as SocialHub.Party).members.size() == 2,
		"vaxtı keçmiş dəvət komandaya salmır")


static func _test_party_ready_start() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	hub.party_answer(PB, T(SA), true)
	hub.party_ready(PA, true)
	_check(w.started.is_empty(), "bir nəfər hazırdır — oyun başlamır")
	var st := _last_party(w, PB)
	var a_ready := false
	for m in st.get("members", []):
		if str(m[0]) == T(SA):
			a_ready = bool(m[3])
	_check(a_ready, "yoldaş liderin HAZIR olduğunu görür")
	hub.party_ready(PB, true)
	_check(w.started.size() == 1, "hamı hazırdır — komanda oyuna girir")
	if w.started.size() == 1:
		var peers: Array = w.started[0][0]
		_check(peers.has(PA) and peers.has(PB) and peers.size() == 2
			and int(w.started[0][1]) == Const.Mode.DUO, "iki üzv CÜT rejimində birlikdə başlayır")
	var p: SocialHub.Party = hub.parties[hub.party_of[T(SA)]]
	_check(p.ready.is_empty(), "başlayandan sonra hazırlar sıfırlanır")
	w.playing[PA] = true
	w.playing[PB] = true
	hub.party_ready(PA, true)
	_check(p.ready.is_empty(), "oyunda olan HAZIR ola bilməz")
	# Biri menyuya qayıdıb hazır olsa da, o biri hələ oyundadır — başlamır.
	w.playing.erase(PA)
	hub.set_in_game(PA, false)
	hub.party_ready(PA, true)
	_check(w.started.size() == 1, "yoldaş matçdadırsa komanda gözləyir")


static func _test_party_code_join() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_open(PA)
	var code := str(_last_party(w, PA).get("code", ""))
	_check(Social.is_code(code), "komanda açılır və kodu var (%s)" % code)
	hub.party_code(PD, code.to_lower())
	_check((_last_party(w, PD).get("members", []) as Array).size() == 2, "kodu bilən yad da girir")
	hub.party_code(PB, code)
	var st := _last_party(w, PA)
	_check((st.get("members", []) as Array).size() == 3 and int(st["mode"]) == Const.Mode.TRIO,
		"üçüncü üzv — komanda ÜÇLÜK-ə keçir")
	hub.hello(PE, SE, "Eda", 0, 0, PackedStringArray())
	w.clear()
	hub.party_code(PE, code)
	var n := w.take(PE, "on_social_notice")
	_check(n.size() == 1 and str(n[0][0]) == "party_full", "dolu komandaya girmək olmur")
	hub.party_code(PE, "ZZZZZZ")
	n = w.take(PE, "on_social_notice")
	_check(n.size() == 1 and str(n[0][0]) == "bad_code", "səhv kod rədd edilir")


static func _test_party_leader_leaves() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	hub.party_answer(PB, T(SA), true)
	var code: String = (hub.parties[hub.party_of[T(SA)]] as SocialHub.Party).code
	hub.party_leave(PA)
	_check(_last_party(w, PA).is_empty(), "çıxana boş komanda göndərilir")
	var st := _last_party(w, PB)
	_check(str(st.get("leader", "")) == T(SB), "lider çıxanda liderlik qalana keçir")
	hub.party_leave(PB)
	_check(hub.parties.is_empty() and not hub.codes.has(code), "sonuncu çıxanda komanda və kodu silinir")


static func _test_party_grace() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	hub.party_answer(PB, T(SA), true)
	hub.party_ready(PB, true)
	hub.drop(PB)
	var st := _last_party(w, PA)
	var b_row: Array = []
	for m in st.get("members", []):
		if str(m[0]) == T(SB):
			b_row = m
	_check(not b_row.is_empty() and int(b_row[4]) == Social.Presence.OFFLINE and not bool(b_row[3]),
		"qopan üzv komandada qalır, 'oflayn' və hazır deyil")
	hub.tick(Social.PARTY_GRACE * 0.5)
	hub.hello(PE, SB, "Bob", 1, 0, PackedStringArray([T(SA), T(SC)]))
	var back := _last_party(w, PE)
	_check((back.get("members", []) as Array).size() == 2, "möhlət içində qayıdan (yeni peer) yerinə oturur")
	hub.drop(PE)
	hub.tick(Social.PARTY_GRACE + 0.5)
	_check((hub.parties[hub.party_of[T(SA)]] as SocialHub.Party).members.size() == 1,
		"möhlət bitəndə qayıtmayan komandadan çıxır")


static func _test_party_mode_rules() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	hub.party_answer(PB, T(SA), true)
	hub.party_mode(PA, Const.Mode.SOLO)
	var p: SocialHub.Party = hub.parties[hub.party_of[T(SA)]]
	_check(p.mode == Const.Mode.DUO, "iki nəfərlik komanda TƏK QALAN-a keçə bilmir")
	hub.party_mode(PB, Const.Mode.ENDLESS)
	_check(p.mode == Const.Mode.DUO, "rejimi yalnız lider dəyişir")
	hub.party_ready(PB, true)
	hub.party_mode(PA, Const.Mode.ENDLESS)
	_check(p.mode == Const.Mode.ENDLESS and p.ready.is_empty(),
		"lider rejimi dəyişir, hazırlar sıfırlanır")
	w.clear()


static func _test_party_kick() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.party_invite(PA, T(SB))
	hub.party_answer(PB, T(SA), true)
	hub.party_kick(PB, T(SA))
	_check(hub.party_of.has(T(SA)) and hub.party_of.has(T(SB)), "üzv lideri çıxara bilmir")
	hub.party_kick(PA, T(SB))
	_check(not hub.party_of.has(T(SB)) and _last_party(w, PB).is_empty(), "lider üzvü çıxarır")
	var n := w.take(PB, "on_social_notice")
	_check(not n.is_empty() and str(n[-1][0]) == "kicked", "çıxarılana deyilir")


static func _test_recent_players() -> void:
	var h = _friends3()
	var hub: SocialHub = h[0]
	var w: Wire = h[1]
	hub.note_met([PA, PD, 1_000_001])
	hub.set_in_game(PA, false)
	var rec := w.take(PA, "on_recent")
	_check(rec.size() == 1 and str(rec[0][0][0][0]) == T(SD) and str(rec[0][0][0][1]) == "Dan",
		"matçdan sonra birlikdə oynadığın insanlar 'son oyunçular'a düşür (bot yox)")
	_check(w.take(PA, "on_recent").is_empty() and not hub.met.has(T(SA)), "siyahı bir dəfə göndərilir")


# ---------------------------------------------------------------- dünya

static func _team_of(world: World, peer: int) -> int:
	return world.sim.germs[peer].team


static func _test_world_party_seating() -> void:
	# CÜT: əvvəl tək oyunçu gəlir, dünya botlarla dolur, sonra iki nəfərlik komanda.
	var world := World.new(71, Const.Mode.DUO)
	world.add_player(PE, "Eda")
	world.tick(Const.TICK_DELTA)
	_check(world.has_room_for(2), "botla dolu CÜT dünyasında komanda üçün yer var")
	world.add_party([[PA, "Ana", 0], [PB, "Bob", 1]])
	_check(_team_of(world, PA) == _team_of(world, PB), "komanda üzvləri EYNİ komandadadır")
	_check(_team_of(world, PA) != _team_of(world, PE), "yad oyunçu onların komandasında deyil")
	_check(world.sim.germs.size() == Const.WORLD_CAPACITY, "dünya dolu qalır (botlar yer verdi)")
	var count := {}
	for gid in world.sim.germs:
		var t: int = world.sim.germs[gid].team
		count[t] = int(count.get(t, 0)) + 1
	var over := false
	for t in count:
		if int(count[t]) != 2:
			over = true
	_check(not over and count.size() == 5, "hər komanda yenə düz 2 mikrobdur")

	# ÜÇLÜK: üç nəfər bir komandada; ikinci üçlük o biri komandaya.
	var trio := World.new(72, Const.Mode.TRIO)
	trio.add_party([[PA, "Ana", 0], [PB, "Bob", 1], [PC, "Cem", 2]])
	trio.tick(Const.TICK_DELTA)
	_check(_team_of(trio, PA) == _team_of(trio, PB) and _team_of(trio, PB) == _team_of(trio, PC),
		"ÜÇLÜK: üç dost bir komandadadır")
	_check(trio.has_room_for(3) and not trio.has_room_for(4), "ÜÇLÜK-də ikinci üçlüyə yer var, dördlüyə yox")
	trio.add_party([[PD, "Dan", 0], [PE, "Eda", 0], [66, "Fər", 0]])
	_check(_team_of(trio, PD) != _team_of(trio, PA) and _team_of(trio, PD) == _team_of(trio, 66),
		"ikinci üçlük o biri komandadadır")
	_check(not trio.has_room_for(1), "dolu ÜÇLÜK-də yer qalmır")

	# Komandada bir insan artıq varsa, iki nəfərlik komanda ora sığmır.
	var duo := World.new(73, Const.Mode.DUO)
	for i in 4:
		duo.add_party([[100 + i * 2, "x", 0], [101 + i * 2, "y", 0]])
	duo.add_player(200, "tək")
	_check(not duo.has_room_for(2) and duo.has_room_for(1),
		"doqquz insanlı CÜT-də cütə yer yoxdur, təkə var")

	# SONSUZ ARENA: komanda yoxdur, sadəcə eyni dünya.
	var endless := World.new(74, Const.Mode.ENDLESS)
	endless.add_party([[PA, "Ana", 0], [PB, "Bob", 1], [PC, "Cem", 2]])
	_check(endless.human_count() == 3 and _team_of(endless, PA) == -1, "SONSUZ ARENA-da dostlar eyni dünyadadır, komandasız")


static func _test_notice_texts() -> void:
	var missing := []
	for code in ["request_sent", "request_in", "friend_added", "invite_sent", "invite_declined",
			"invite_gone", "bad_tag", "self", "already", "busy", "not_friend", "in_game",
			"party_full", "bad_code", "kicked", "party_left", "mode_small", "elsewhere", "offline",
			"list_full", "copied"]:
		var t: Array = load("res://scripts/client/friends.gd").notice_text(code, "1")
		if t.size() != 3 or str(t[0]).is_empty():
			missing.append(code)
	_check(missing.is_empty(), "serverin hər bildiriş kodunun insan dilində mətni var %s" % str(missing))
