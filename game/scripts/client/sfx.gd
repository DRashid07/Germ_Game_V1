extends Node
## Səs effektləri. Autoload — hər yerdən `Sfx.play("eject")` kimi çağırılır.
##
## Səslər `design/AUDIO_BIBLE.md`-də təsvir olunan iyerarxiyaya görə qurulub:
## fayllar özləri artıq düzgün səs gücündədir, ona görə burada əlavə
## tarazlama edilmir — yalnız kiçik ton dəyişimi var ki, fasiləsiz atəş
## mexaniki səslənməsin.
##
## Serverdə (headless) heç nə yüklənmir: hədəf serverin səsə ehtiyacı yoxdur.

## Eyni anda səslənə bilən maksimum səs sayı.
## Ekranda 10 mikrob ola bilər, hamısı eyni anda atəş açsa belə 14 kanal bəsdir.
const POOL_SIZE := 14

const CLIPS := [
	"eject", "blunk", "absorb", "hit", "burst", "spawn",
	"danger", "level_up", "you_burst", "ui_click",
]

var enabled := true

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _silent := false
## Xəbərdarlıq siqnalı çox tez-tez təkrarlanmasın deyə.
var _last_danger := -10.0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		_silent = true
		return

	for clip in CLIPS:
		var stream := load("res://assets/sfx/%s.wav" % clip)
		if stream != null:
			_streams[clip] = stream

	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


## [param pitch_spread] tonu təsadüfi olaraq ±bu qədər dəyişir (0.03 = ±3%).
func play(clip: String, pitch_spread := 0.0, volume_db := 0.0) -> void:
	if _silent or not enabled:
		return
	var stream: AudioStream = _streams.get(clip)
	if stream == null:
		return

	# Dairəvi hovuz: ən köhnə kanal təkrar işlədilir. Bir səs kəsilsə də
	# qulağa çatmır, çünki kliplərin hamısı çox qısadır.
	var p := _players[_next]
	_next = (_next + 1) % POOL_SIZE
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 if is_zero_approx(pitch_spread) \
		else randf_range(1.0 - pitch_spread, 1.0 + pitch_spread)
	p.play()


## Təhlükə siqnalı — saniyədə bir dəfədən çox çalınmır.
## HUD hər kadr "təhlükədəyəm" deyir, amma qulaq bunu bir dəfə eşitməlidir.
func play_danger() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_danger < 1.1:
		return
	_last_danger = now
	play("danger")


## Bütün səsləri dərhal susdurur (oyun bitəndə).
func stop_all() -> void:
	for p in _players:
		p.stop()
