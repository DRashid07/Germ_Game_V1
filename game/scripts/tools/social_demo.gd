extends Node
## Dostlar və komanda ekranlarının stendi — şəbəkəsiz, hazır vəziyyətlə.
##
##   GODOT --path game --resolution 1280x720 -- --social-demo home \
##         --shot C:/yol/kadr.png --shot-delay 90
##
## [Friends]-ə uydurma vəziyyət yazır (iki yoldaşlı komanda, dostlar, sorğu,
## dəvət, son oyunçular) və menyunu açır. Görünüş belə yoxlanılır: server,
## ikinci oyunçu və dəvət gözləmək lazım deyil. `view`:
##   home      ana ekran — yuvalarda iki yoldaş, lider tacı, HAZIR sayğacı
##   invite    ana ekran + gələn dəvət kartı
##   solo      ana ekran, komandasız — iki boş «+» yuvası
##   friends / requests / recent   DOSTLAR ekranının tabları

var view := "home"


func _ready() -> void:
	# Menyu açılan kimi serverə qoşulur və onun cavabı uydurma vəziyyəti
	# silərdi. Ünvan yalnız yaddaşda dəyişir — stend ayar faylına yazmır.
	Settings.address = "ws://127.0.0.1:9"
	Friends.use_secret("d".repeat(32))
	var now := Time.get_unix_time_from_system()
	var people := [
		["Aysel", 1, Social.Presence.PARTY],
		["Tural", 2, Social.Presence.PARTY],
		["Nigar", 0, Social.Presence.MENU],
		["Kamran", 1, Social.Presence.GAME],
		["Leyla", 2, Social.Presence.OFFLINE],
	]
	var tags: Array[String] = []
	for i in people.size():
		var tag := Social.tag_of("%032x" % (i + 1))
		tags.append(tag)
		Friends.friends[tag] = {"name": people[i][0], "species": people[i][1],
			"seen": now - 3600.0 * 5.0}
		Friends.presence[tag] = people[i][2]
	if view != "solo":
		Friends.party = {
			"code": "KX7M2Q", "leader": Friends.my_tag, "mode": int(Const.Mode.TRIO),
			"members": [
				[Friends.my_tag, Net.nickname, int(Net.species), false, Social.Presence.PARTY],
				[tags[0], "Aysel", 1, true, Social.Presence.PARTY],
				[tags[1], "Tural", 2, false, Social.Presence.PARTY],
			],
		}
		Net.mode = Const.Mode.TRIO
	Friends.requests[Social.tag_of("%032x" % 77)] = "Orxan"
	Friends.recent = [
		[Social.tag_of("%032x" % 81), "Samir", now - 120.0],
		[Social.tag_of("%032x" % 82), "Günay", now - 900.0],
		[tags[2], "Nigar", now - 4000.0],
	]
	if view == "invite" or view == "requests":
		Friends.invites[tags[2]] = {"name": "Nigar", "mode": int(Const.Mode.DUO), "size": 1,
			"until": 45.0}
	get_tree().change_scene_to_file.call_deferred("res://scenes/ui/menu.tscn")
	_after_menu.call_deferred()


func _after_menu() -> void:
	# Menyu növbəti kadrda qurulur — bir neçə kadr gözlənilir.
	for i in 4:
		await get_tree().process_frame
	var menu := get_tree().current_scene as MenuV2
	if menu == null:
		return
	match view:
		"friends", "requests", "recent":
			menu._open_friends(false)
			var fv := menu._friends_view
			fv.tab = {"friends": FriendsView.Tab.FRIENDS, "requests": FriendsView.Tab.REQUESTS,
				"recent": FriendsView.Tab.RECENT}[view]
			fv._rebuild()
		"invite":
			menu._show_invite(Friends.invites.keys()[0])
