class_name SocialHub
extends RefCounted
## Serverdə dostluq və komanda: kim onlayndır, sorğular, dəvətlər, komandalar.
##
## Qaydaların özü [Social]-dadır. Bu sinif onları İCRA edir və heç nəyi
## diskə yazmır — niyə belə olduğu [Social]-ın başındadır: dost siyahısının
## sahibi oyunçunun cihazıdır, server yalnız ötürücüdür.
##
## Şəbəkəyə birbaşa toxunmur. Mesajları [member send] ilə göndərir, komandanı
## oyuna [member start] ilə salır — [Lobby] onları Net RPC-yə və öz
## `join_party`-sinə bağlayır, testlər isə sadə yazıcıya ([SimTest]). Beləcə
## bütün məntiq şəbəkəsiz, headless yoxlanılır.

## `send.call(peer, "on_x", [arqumentlər])` — client-ə RPC.
var send: Callable
## `start.call(peers: Array[int], mode: int)` — hamı HAZIR-dır, komanda oyuna girir.
var start: Callable
## `in_game.call(peer) -> bool` — oyunçu hazırda dünyadadırmı ([Lobby]-dən).
var in_game: Callable

## Oyunçu sorğu/dəvət ilə spam edə bilməsin: saniyədə bir, ehtiyatla on.
const ACTION_BURST := 10.0
const ACTION_RATE := 1.0
## Oflayn oyunçuya gözləyən sorğu və bildirişlərin həddi — yaddaş sonsuz
## böyüməsin (server həftələrlə işləyə bilər, hər yad kod bir açar yaradır).
const MAIL_PER_TAG := 50
const MAIL_TAGS := 5000

var clock := 0.0

## kod -> {peer, name, species, mode, friends: {kod: true}}
var online := {}
var peer_tag := {}                 ## peer -> kod
## Hədəf -> {göndərən kod -> ad}. Hədəf oflayn olsa da saxlanılır və
## qoşulanda çatdırılır. Qəbul/rədd yalnız burada olan sorğuya keçərlidir —
## yoxsa hər kəs "qəbul etdim" deyib özünü başqasının siyahısına yazardı.
var requests := {}
## Oflayn oyunçunun poçtu: [["added"|"removed", kod, ad], ...]
var mail := {}
## Hədəf -> {dəvət edən kod -> {party, until}}
var invites := {}

var parties := {}                  ## id -> Party
var party_of := {}                 ## kod -> komanda id
var codes := {}                    ## komanda kodu -> id
## Bağlantısı kəsilmiş üzvlər: kod -> vaxt (bax [constant Social.PARTY_GRACE]).
var gone := {}
## Oyunda rastlaşdığı insanlar: kod -> {kod: ad} — "Son oyunçular" üçün.
var met := {}

var _next_party := 1
var _budget := {}                  ## peer -> qalan hərəkət


class Party:
	var id := 0
	var leader := ""
	var members: Array[String] = []
	var mode := 0
	var code := ""
	var ready := {}                ## kod -> true


func _init() -> void:
	send = func(_p: int, _m: String, _a: Array) -> void: pass
	start = func(_peers: Array, _mode: int) -> void: pass
	in_game = func(_p: int) -> bool: return false


# ================================================================ kimlik

## Oyunçu qoşuldu (və ya profilini yenilədi). Eyni peer-dən təkrar gələ bilər:
## ad, növ və siyahı dəyişəndə client hello-nu yenidən göndərir.
func hello(peer: int, secret: String, player_name: String, species: int,
		mode: int, friends: PackedStringArray) -> void:
	if not Social.is_secret(secret):
		return
	var tag := Social.tag_of(secret)

	# Bu peer başqa kodla danışırdısa (cihazda hesab dəyişib) — köhnəsi çıxır.
	var old_tag: String = peer_tag.get(peer, "")
	if not old_tag.is_empty() and old_tag != tag:
		drop(peer)
	# Eyni kod başqa peer-dən açıqdır (iki pəncərə, iki cihaz) — sonuncu qalır.
	# Köhnə peer oyunu oynamağa davam edir, sadəcə dostluq kanalı onda deyil.
	var rec: Dictionary = online.get(tag, {})
	if not rec.is_empty() and int(rec["peer"]) != peer:
		var prev := int(rec["peer"])
		peer_tag.erase(prev)
		send.call(prev, "on_social_notice", ["elsewhere", ""])

	var list := {}
	for raw in friends:
		var t := Social.clean_tag(str(raw))
		if Social.is_tag(t) and t != tag:
			list[t] = true
		if list.size() >= Social.FRIEND_MAX:
			break

	var first := rec.is_empty() or int(rec["peer"]) != peer
	online[tag] = {
		"peer": peer,
		"name": _clean_name(player_name),
		"species": int(Const.species_from(species)),
		"mode": int(Const.mode_from(mode)),
		# Qaydaların versiyası — komanda oyuna girəndə yoxlanılır ([method Lobby.join_party]).
		"rules": Const.wire_rules(mode),
		"friends": list,
	}
	peer_tag[peer] = tag
	gone.erase(tag)

	if first:
		send.call(peer, "on_social_hello", [tag])
		_deliver_mail(tag)
		for from in requests.get(tag, {}):
			send.call(peer, "on_friend_request", [from, str(requests[tag][from])])
		for from in invites.get(tag, {}):
			_send_invite(tag, from)

	_send_presence_to(tag)
	_announce(tag)
	if party_of.has(tag):
		_broadcast(parties[party_of[tag]])


## Menyuda ad, növ və ya rejim dəyişdi — hello-dan yüngül: siyahı dəyişmir.
func profile(peer: int, player_name: String, species: int, mode: int) -> void:
	var tag := tag_of_peer(peer)
	if tag.is_empty():
		return
	var rec: Dictionary = online[tag]
	rec["name"] = _clean_name(player_name)
	rec["species"] = int(Const.species_from(species))
	rec["mode"] = int(Const.mode_from(mode))
	rec["rules"] = Const.wire_rules(mode)
	_announce(tag)
	if party_of.has(tag):
		_broadcast(parties[party_of[tag]])


## Bağlantı kəsildi. Komandadakı yeri [constant Social.PARTY_GRACE] saniyə
## saxlanılır: qayıdan oyunçu (yeni peer, eyni kod) yerinə oturur.
func drop(peer: int) -> void:
	var tag: String = peer_tag.get(peer, "")
	peer_tag.erase(peer)
	_budget.erase(peer)
	if tag.is_empty() or int(online.get(tag, {}).get("peer", -1)) != peer:
		return
	_announce(tag, true)
	online.erase(tag)
	met.erase(tag)
	if party_of.has(tag):
		gone[tag] = clock
		var p: Party = parties[party_of[tag]]
		p.ready.erase(tag)
		_broadcast(p)


func tag_of_peer(peer: int) -> String:
	return str(peer_tag.get(peer, ""))


# ================================================================ vəziyyət

## Oyunçu dünyaya girdi və ya oradan çıxdı ([Lobby] çağırır).
func set_in_game(peer: int, playing: bool) -> void:
	var tag := tag_of_peer(peer)
	if tag.is_empty():
		return
	if playing:
		# Matçda olan HAZIR sayılmır: qayıdanda yenidən basmalıdır, yoxsa
		# menyuya çıxan kimi komanda onu gözləmədən növbəti oyuna salardı.
		if party_of.has(tag):
			(parties[party_of[tag]] as Party).ready.erase(tag)
	else:
		_send_recent(tag)
	_announce(tag)
	if party_of.has(tag):
		_broadcast(parties[party_of[tag]])


func presence_of(tag: String) -> int:
	var rec: Dictionary = online.get(tag, {})
	if rec.is_empty():
		return Social.Presence.OFFLINE
	if in_game.call(int(rec["peer"])):
		return Social.Presence.GAME
	if party_of.has(tag) and (parties[party_of[tag]] as Party).members.size() > 1:
		return Social.Presence.PARTY
	return Social.Presence.MENU


## İkisi də onlayndır VƏ ikisinin də siyahısında bir-biri var.
func mutual(a: String, b: String) -> bool:
	var ra: Dictionary = online.get(a, {})
	var rb: Dictionary = online.get(b, {})
	if ra.is_empty() or rb.is_empty():
		return false
	return (ra["friends"] as Dictionary).has(b) and (rb["friends"] as Dictionary).has(a)


func _row(tag: String, p: int) -> Array:
	var rec: Dictionary = online.get(tag, {})
	return [tag, p, str(rec.get("name", "")), int(rec.get("species", 0))]


## Oyunçunun QARŞILIQLI dostlarının vəziyyəti — qoşulanda bir paketlə.
func _send_presence_to(tag: String) -> void:
	var rows := []
	for f in (online[tag]["friends"] as Dictionary):
		if mutual(tag, f):
			rows.append(_row(f, presence_of(f)))
	send.call(int(online[tag]["peer"]), "on_presence", [rows])


## Oyunçunun vəziyyəti dəyişdi — onlayn qarşılıqlı dostlarına xəbər.
func _announce(tag: String, leaving := false) -> void:
	var rec: Dictionary = online.get(tag, {})
	if rec.is_empty():
		return
	var p := Social.Presence.OFFLINE if leaving else presence_of(tag)
	var row := _row(tag, p)
	for f in (rec["friends"] as Dictionary):
		if mutual(tag, f):
			send.call(int(online[f]["peer"]), "on_presence", [[row]])


# ================================================================ dostluq

func friend_request(peer: int, raw_tag: String) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not _spend(peer):
		return
	var t := Social.clean_tag(raw_tag)
	if not Social.is_tag(t):
		_notice(me, "bad_tag", raw_tag.substr(0, 16))
		return
	if t == me:
		_notice(me, "self", "")
		return
	if mutual(me, t):
		_notice(me, "already", t)
		return
	# Qarşı tərəf onsuz da mənə sorğu göndəribsə — bu, qəbuldur.
	if (requests.get(me, {}) as Dictionary).has(t):
		var their_name := str(requests[me][t])
		requests[me].erase(t)
		_befriend(me, t, their_name)
		return
	if not requests.has(t):
		if requests.size() >= MAIL_TAGS:
			return
		requests[t] = {}
	var box: Dictionary = requests[t]
	if box.size() >= MAIL_PER_TAG and not box.has(me):
		_notice(me, "busy", t)
		return
	var my_name := str(online[me]["name"])
	box[me] = my_name
	if online.has(t):
		send.call(int(online[t]["peer"]), "on_friend_request", [me, my_name])
	_notice(me, "request_sent", t)


func friend_answer(peer: int, raw_tag: String, accept: bool) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty():
		return
	var t := Social.clean_tag(raw_tag)
	var box: Dictionary = requests.get(me, {})
	if not box.has(t):
		# Sorğu artıq yoxdur (server yenidən qalxıb, və ya qarşı tərəf özü
		# qəbul edib). Client onu siyahıdan silsin.
		send.call(peer, "on_friend_request_gone", [t])
		return
	var their_name := str(box[t])
	box.erase(t)
	if box.is_empty():
		requests.erase(me)
	if accept:
		_befriend(me, t, their_name)
	# Rədd SƏSSİZDİR — Brawl Stars-da da göndərən bunu bilmir.


## İki tərəfi dost edir. [param a] həmişə onlayndır (qəbul edən).
func _befriend(a: String, b: String, b_name: String) -> void:
	var a_name := str(online[a]["name"])
	(online[a]["friends"] as Dictionary)[b] = true
	send.call(int(online[a]["peer"]), "on_friend_added", [b, b_name])
	if online.has(b):
		(online[b]["friends"] as Dictionary)[a] = true
		send.call(int(online[b]["peer"]), "on_friend_added", [a, a_name])
		# Qarşı tərəfin də mənə gözləyən sorğusu varsa, artıq lazım deyil.
		if requests.has(b):
			(requests[b] as Dictionary).erase(a)
	else:
		_post(b, ["added", a, a_name])
	_send_presence_to(a)
	_announce(a)
	if online.has(b):
		_send_presence_to(b)
		_announce(b)


func friend_remove(peer: int, raw_tag: String) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty():
		return
	var t := Social.clean_tag(raw_tag)
	if not Social.is_tag(t):
		return
	(online[me]["friends"] as Dictionary).erase(t)
	if online.has(t):
		(online[t]["friends"] as Dictionary).erase(me)
		send.call(int(online[t]["peer"]), "on_friend_removed", [me])
	else:
		_post(t, ["removed", me, ""])


func _post(tag: String, item: Array) -> void:
	if not mail.has(tag):
		if mail.size() >= MAIL_TAGS:
			return
		mail[tag] = []
	var box: Array = mail[tag]
	# Eyni kodla köhnə bildiriş varsa, yenisi onu əvəz edir: "əlavə etdi,
	# sonra sildi" ardıcıllığında yalnız sonuncu həqiqətdir.
	for i in range(box.size() - 1, -1, -1):
		if str(box[i][1]) == str(item[1]):
			box.remove_at(i)
	if box.size() < MAIL_PER_TAG:
		box.append(item)


func _deliver_mail(tag: String) -> void:
	var box: Array = mail.get(tag, [])
	mail.erase(tag)
	var peer := int(online[tag]["peer"])
	var list: Dictionary = online[tag]["friends"]
	for item in box:
		var other := str(item[1])
		if str(item[0]) == "added":
			list[other] = true
			send.call(peer, "on_friend_added", [other, str(item[2])])
		else:
			list.erase(other)
			send.call(peer, "on_friend_removed", [other])


func _notice(tag: String, what: String, arg: String) -> void:
	if online.has(tag):
		send.call(int(online[tag]["peer"]), "on_social_notice", [what, arg])


# ================================================================ komanda

## Komanda açır (kod üçün). Artıq komandadadırsa — mövcud komandanın vəziyyəti.
func party_open(peer: int) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty():
		return
	if not party_of.has(me):
		_new_party(me)
	_broadcast(parties[party_of[me]])


func party_invite(peer: int, raw_tag: String) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not _spend(peer):
		return
	var t := Social.clean_tag(raw_tag)
	# Dəvət yalnız QARŞILIQLI dosta — bax sinfin şərhi.
	if not mutual(me, t):
		_notice(me, "not_friend", t)
		return
	if presence_of(t) == Social.Presence.GAME or presence_of(me) == Social.Presence.GAME:
		_notice(me, "in_game", str(online[t]["name"]))
		return
	var p: Party = parties[party_of[me]] if party_of.has(me) else _new_party(me)
	if p.members.has(t):
		return
	if p.members.size() >= Social.PARTY_MAX:
		_notice(me, "party_full", "")
		return
	if not invites.has(t):
		invites[t] = {}
	invites[t][me] = {"party": p.id, "until": clock + Social.INVITE_TTL}
	_send_invite(t, me)
	_notice(me, "invite_sent", str(online[t]["name"]))
	_broadcast(p)


func _send_invite(to: String, from: String) -> void:
	var inv: Dictionary = invites[to][from]
	var p: Party = parties.get(int(inv["party"]))
	if p == null or not online.has(to):
		return
	var from_name := str(online[from]["name"]) if online.has(from) else ""
	send.call(int(online[to]["peer"]), "on_party_invite",
		[from, from_name, p.mode, p.members.size(), float(inv["until"]) - clock])


func party_answer(peer: int, raw_tag: String, accept: bool) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty():
		return
	var from := Social.clean_tag(raw_tag)
	var inv: Dictionary = (invites.get(me, {}) as Dictionary).get(from, {})
	if not invites.get(me, {}).is_empty():
		(invites[me] as Dictionary).erase(from)
		if (invites[me] as Dictionary).is_empty():
			invites.erase(me)
	if inv.is_empty() or float(inv["until"]) < clock:
		_notice(me, "invite_gone", "")
		return
	var p: Party = parties.get(int(inv["party"]))
	if p == null:
		_notice(me, "invite_gone", "")
		return
	if not accept:
		_notice(from, "invite_declined", str(online[me]["name"]))
		return
	_join(me, p)


func party_code(peer: int, raw_code: String) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not _spend(peer):
		return
	var code := Social.clean_code(raw_code)
	var p: Party = parties.get(int(codes.get(code, 0)))
	if p == null:
		_notice(me, "bad_code", code)
		return
	_join(me, p)


func _join(me: String, p: Party) -> void:
	if p.members.has(me):
		_broadcast(p)
		return
	if presence_of(me) == Social.Presence.GAME:
		_notice(me, "in_game", "")
		return
	if p.members.size() >= Social.PARTY_MAX:
		_notice(me, "party_full", "")
		return
	if party_of.has(me):
		_leave(me)
	p.members.append(me)
	party_of[me] = p.id
	p.mode = Social.fit_mode(p.mode, p.members.size())
	# Yeni üzv gəldi — hamı yenidən təsdiq etməlidir (Brawl Stars kimi):
	# hazır düyməsini BAŞQA tərkibə basmışdılar.
	p.ready.clear()
	_broadcast(p)
	for m in p.members:
		_announce(m)


func party_leave(peer: int) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not party_of.has(me):
		return
	_leave(me)
	send.call(peer, "on_party", [{}])
	_announce(me)


func party_kick(peer: int, raw_tag: String) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not party_of.has(me):
		return
	var p: Party = parties[party_of[me]]
	var t := Social.clean_tag(raw_tag)
	if p.leader != me or t == me or not p.members.has(t):
		return
	_leave(t)
	if online.has(t):
		send.call(int(online[t]["peer"]), "on_party", [{}])
		_notice(t, "kicked", str(online[me]["name"]))
		_announce(t)


func party_mode(peer: int, mode: int) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not party_of.has(me):
		return
	var p: Party = parties[party_of[me]]
	if p.leader != me:
		return
	var m := int(Const.mode_from(mode))
	if p.members.size() > Social.party_limit(m):
		_notice(me, "mode_small", str(m))
		_broadcast(p)
		return
	if m != p.mode:
		p.mode = m
		# Rejim dəyişdi — hazırlar sıfırlanır: "hazıram" başqa rejimə deyilmişdi.
		p.ready.clear()
	_broadcast(p)


func party_ready(peer: int, on: bool) -> void:
	var me := tag_of_peer(peer)
	if me.is_empty() or not party_of.has(me):
		return
	if presence_of(me) == Social.Presence.GAME:
		return
	var p: Party = parties[party_of[me]]
	if on:
		p.ready[me] = true
	else:
		p.ready.erase(me)
	if not _try_start(p):
		_broadcast(p)


## Hamı hazır, hamı onlayn və menyudadır — komanda BİRLİKDƏ oyuna girir.
func _try_start(p: Party) -> bool:
	if p.members.size() > Social.party_limit(p.mode):
		return false
	var peers: Array[int] = []
	for m in p.members:
		if not p.ready.has(m) or gone.has(m) or not online.has(m):
			return false
		var peer := int(online[m]["peer"])
		if in_game.call(peer):
			return false
		peers.append(peer)
	p.ready.clear()
	start.call(peers, p.mode)
	return true


func _new_party(leader: String) -> Party:
	var p := Party.new()
	p.id = _next_party
	_next_party += 1
	p.leader = leader
	p.members.append(leader)
	p.mode = int(online[leader]["mode"]) if online.has(leader) else 0
	p.code = _new_code()
	parties[p.id] = p
	codes[p.code] = p.id
	party_of[leader] = p.id
	return p


func _new_code() -> String:
	var rng := Crypto.new()
	while true:
		var bytes := rng.generate_random_bytes(Social.CODE_LEN)
		var code := ""
		for b in bytes:
			code += Social.CODE_ALPHABET[b % Social.CODE_ALPHABET.length()]
		if not codes.has(code):
			return code
	return ""


func _leave(tag: String) -> void:
	var p: Party = parties.get(int(party_of.get(tag, 0)))
	party_of.erase(tag)
	gone.erase(tag)
	if p == null:
		return
	p.members.erase(tag)
	p.ready.erase(tag)
	if p.members.is_empty():
		parties.erase(p.id)
		codes.erase(p.code)
		# Bu komandaya gedən dəvətlər də ölür.
		for to in invites.keys():
			for from in (invites[to] as Dictionary).keys():
				if int(invites[to][from]["party"]) == p.id:
					(invites[to] as Dictionary).erase(from)
		return
	if p.leader == tag:
		# Liderlik ən köhnə üzvə keçir — Brawl Stars-da da belədir.
		p.leader = p.members[0]
	_broadcast(p)
	for m in p.members:
		_announce(m)


## Komandanın hazırkı şəkli — hər üzvə ayrıca, onun gözü ilə deyil, eyni.
func party_state(p: Party) -> Dictionary:
	var rows := []
	for m in p.members:
		var rec: Dictionary = online.get(m, {})
		var st := Social.Presence.OFFLINE if gone.has(m) or rec.is_empty() else presence_of(m)
		rows.append([m, str(rec.get("name", "")), int(rec.get("species", 0)),
			p.ready.has(m), st])
	return {"code": p.code, "leader": p.leader, "mode": p.mode, "members": rows}


func _broadcast(p: Party) -> void:
	var state := party_state(p)
	for m in p.members:
		if online.has(m) and not gone.has(m):
			send.call(int(online[m]["peer"]), "on_party", [state])


# ================================================================ son oyunçular

## Dünyada birlikdə olan insanlar bir-birinin "son oyunçular" siyahısına düşür.
## [Lobby] bunu dünyanın tərkibi dəyişəndə çağırır.
func note_met(peers: Array) -> void:
	var tags: Array[String] = []
	for peer in peers:
		var t := tag_of_peer(int(peer))
		if not t.is_empty():
			tags.append(t)
	if tags.size() < 2:
		return
	for a in tags:
		if not met.has(a):
			met[a] = {}
		var box: Dictionary = met[a]
		for b in tags:
			if b != a and box.size() < Social.RECENT_MAX:
				box[b] = str(online[b]["name"])


func _send_recent(tag: String) -> void:
	var box: Dictionary = met.get(tag, {})
	met.erase(tag)
	if box.is_empty() or not online.has(tag):
		return
	var rows := []
	for t in box:
		rows.append([t, str(box[t])])
	send.call(int(online[tag]["peer"]), "on_recent", [rows])


# ================================================================ saat

func tick(dt: float) -> void:
	clock += dt
	# Qayıtmayan üzvlər komandadan çıxır.
	for tag in gone.keys():
		if clock - float(gone[tag]) >= Social.PARTY_GRACE:
			_leave(tag)
	# Vaxtı keçmiş dəvətlər — client onları özü söndürür, burada yaddaş təmizlənir.
	for to in invites.keys():
		var box: Dictionary = invites[to]
		for from in box.keys():
			if float(box[from]["until"]) < clock:
				box.erase(from)
		if box.is_empty():
			invites.erase(to)
	for peer in _budget.keys():
		_budget[peer] = minf(ACTION_BURST, float(_budget[peer]) + dt * ACTION_RATE)


func _spend(peer: int) -> bool:
	var left := float(_budget.get(peer, ACTION_BURST))
	if left < 1.0:
		return false
	_budget[peer] = left - 1.0
	return true


static func _clean_name(raw: String) -> String:
	var s := raw.strip_edges()
	return "Mikrob" if s.is_empty() else s.substr(0, 16)
