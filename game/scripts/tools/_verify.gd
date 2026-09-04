extends Node
## MÜVƏQQƏTİ yoxlama zondu — düzəlişlərin görüntüsünü təkrarlana bilən şəkildə
## çəkmək üçün. Yoxlama bitəndən sonra SİLİNİR, buraxılışda qalmır.
##
## Bayraqlar:
##   --v-species 0|1|2      növ (0 kirpikli · 1 ayaqlı · 2 amöb)
##   --v-mode 0|1|2|3       rejim (0 sonsuz · 1 TƏK QALAN · 2 CÜT · 3 ÜÇLÜK)
##   --v-balls N            top sayını zorla təyin edir
##   --v-charge             super doluluğunu tam edir
##   --v-press              super düyməsinə İNSAN kimi basır (siçan hadisəsi)
##   --v-near               botları superin təsir sahəsinə yığır
##   --v-matcht SEC         matç saatını sabit saxlayır (quruma üçün: 60+)
##   --v-result             nəticə ekranını göstərir
##   --v-shot YOL           şəkil
##   --v-delay N            basılışdan/qurulmadan neçə kadr sonra çəkilsin

var arena: Arena
var _f := 0
var _stage := 0
var _after := 0
var _shot := ""
var _delay := 10
var _matcht := -1.0


func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	Net.species = Const.species_from(int(_arg(a, "--v-species", "0")))
	Net.mode = Const.mode_from(int(_arg(a, "--v-mode", "0")))
	_shot = _arg(a, "--v-shot", "")
	_delay = int(_arg(a, "--v-delay", "10"))
	_matcht = float(_arg(a, "--v-matcht", "-1"))
	arena = load("res://scenes/game/arena.tscn").instantiate()
	arena.configure_practice()
	var tree := get_tree()
	tree.root.add_child.call_deferred(arena)
	tree.set_deferred("current_scene", arena)


static func _arg(a: PackedStringArray, key: String, fb: String) -> String:
	var i := a.find(key)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else fb


func _process(_dt: float) -> void:
	if arena == null or not is_instance_valid(arena) or arena.me == null:
		return
	var args := OS.get_cmdline_user_args()
	# Matç saatı hər kadr sabitlənir — arena tick-i onu irəli aparır.
	if _matcht >= 0.0 and arena._local_world != null:
		arena._local_world.match_t = _matcht

	_f += 1
	if _f < 45:
		return
	var srv: Sim.GermState = arena._local_world.sim.germs.get(arena.my_id)
	if srv == null:
		return

	match _stage:
		0:
			if args.has("--v-charge"):
				srv.charge = Const.SUPER_MAX
			var b := _arg(args, "--v-balls", "")
			if not b.is_empty():
				srv.balls = int(b)
			if args.has("--v-near"):
				var i := 0
				for id in arena._local_world.sim.germs:
					if id == arena.my_id:
						continue
					var o: Sim.GermState = arena._local_world.sim.germs[id]
					o.pos = srv.pos + Vector2.from_angle(float(i) * 1.05) * (105.0 + float(i) * 28.0)
					i += 1
			_stage = 1
		1:
			# Snapshot-un çatmasını VƏ oyunun başlamasını gözləyirik.
			#
			# Geriyə sayımda basılış qəsdən atılır ([method Arena._sample_input]),
			# ona görə PLAYING-dən əvvəl basmaq heç nə sınamır.
			if _f > 60 and arena._phase == Const.Phase.PLAYING:
				print("[v] client: balls=%d charge=%d ready=%s | düymə: yanır=%s kilidli=%s"
					% [arena.me.balls, arena.me.charge, arena.me.super_ready(),
					   arena._hud.super_button._ready_now,
					   arena._hud.super_button._is_locked()])
				_stage = 2
		2:
			if args.has("--v-press"):
				var btn: SuperButton = arena._hud.super_button
				var c := btn.get_global_rect().get_center()
				for down in [true, false]:
					var ev := InputEventMouseButton.new()
					ev.button_index = MOUSE_BUTTON_LEFT
					ev.pressed = down
					ev.position = c
					ev.global_position = c
					Input.parse_input_event(ev)
			if args.has("--v-result"):
				arena._hud.show_result({
					"place": 3, "total": Const.mode_capacity(int(Net.mode)),
					"pops": 2, "cap": 20, "level": 3, "age": 96.0,
					"killer": "Sitoz", "won": false, "survived": false,
				})
			_stage = 3
		3:
			_after += 1
			if _after == _delay and not _shot.is_empty():
				_save()
			if _after > _delay + 6:
				print("[v] son: charge=%d super_t=%.2f balls=%d yaş_radius=%.0f"
					% [srv.charge, srv.super_t, srv.balls, arena._local_world.sim.dish_radius])
				_finish()


func _save() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img.save_png(_shot) == OK:
		print("[v] şəkil: %s" % _shot)
	else:
		printerr("[v] şəkil saxlanmadı: %s" % _shot)


func _finish() -> void:
	set_process(false)
	await get_tree().process_frame
	get_tree().quit()
