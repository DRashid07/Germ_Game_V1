class_name AimGuide
extends Node2D
## Dünyada çəkilən iki nişan işarəsi:
##   • NİŞAN XƏTTİ — atəş düyməsi sürüşdürülərkən topun gedəcəyi yol, səkmələri
##     ilə birlikdə ([method Sim.aim_path]). Brawl Stars-dakı kimi döşəmədə,
##     mikrobların ALTINDA uzanan şəffaf zolaqdır; ucunda Codex-in oxu var.
##   • HƏDƏF İŞARƏSİ — avtomatik nişan atəş açanda seçdiyi rəqibin üstündə bir
##     anlıq "kilid" çərçivəsi: oyunçu topun KİMƏ getdiyini görür.
##
## Hər ikisi oyunçunun rəngindədir. Atəş hazır deyilsə (dövr və ya top
## çatmır) xətt sönük bozdur — buraxsan atılmayacaq.
##
## Node dünyanın mənşəyindədir və hər şeyi dünya koordinatında çəkir.

const ARROW := preload("res://assets/ui/hud_aim_arrow.png")
const TARGET := preload("res://assets/ui/hud_target.png")
## Kilid işarəsinin ömrü.
const LOCK_TIME := 0.5
## Zolağın eni — topun diametrindən bir az enli: kənarları topun keçdiyi
## sərhəddir, mərkəzdəki nöqtələr isə onun mərkəzinin yolu.
const BAND := Const.SHOT_RADIUS * 2.0 + 8.0
const DOT_GAP := 34.0
const DOT_SPEED := 90.0
const ARROW_SIZE := 44.0
## Bundan qısa xəttin oxu yoxdur: yaxındakı kövrək qabığa nişan alanda 49 px-lik
## xəttin oxu öz adının üstünə düşürdü, istiqaməti isə xəttin özü onsuz da deyir.
const ARROW_MIN := 90.0

var _path := PackedVector2Array()
var _color := Color.WHITE
var _live := true
var _t := 0.0

var _lock_key := -1
var _lock_t := 0.0
var _lock_at := Vector2.ZERO
var _lock_r := 0.0
var _lock_color := Color.WHITE


func _ready() -> void:
	# Ikonlar 256 px-dir, dünyada ~50 px: mipmap-sız kiçiltmə konturu dişləyir.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Xətti göstərir. [param can_fire] — buraxsan top indi atılarmı.
func show_path(path: PackedVector2Array, color: Color, can_fire: bool) -> void:
	_path = path
	_color = color
	_live = can_fire
	queue_redraw()


func hide_path() -> void:
	if _path.is_empty():
		return
	_path = PackedVector2Array()
	queue_redraw()


## Avtomatik nişanın hədəfi [param key] üçün kilidi açır.
func lock(key: int, at: Vector2, radius: float, color: Color) -> void:
	_lock_key = key
	_lock_t = LOCK_TIME
	_lock_at = at
	_lock_r = radius
	_lock_color = color
	queue_redraw()


## Kilidlənmiş rəqib — işarə onun ardınca gedir; yoxdursa -1.
func locked_key() -> int:
	return _lock_key if _lock_t > 0.0 else -1


func follow(at: Vector2, radius: float) -> void:
	_lock_at = at
	_lock_r = radius


func unlock() -> void:
	_lock_t = 0.0
	_lock_key = -1
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _lock_t > 0.0:
		_lock_t = maxf(0.0, _lock_t - delta)
		if _lock_t <= 0.0:
			_lock_key = -1
		queue_redraw()
	elif not _path.is_empty():
		queue_redraw()


func _draw() -> void:
	if _path.size() >= 2:
		_draw_path()
	if _lock_t > 0.0:
		_draw_lock()


func _draw_path() -> void:
	var col := _color if _live else Palette.TEXT_MUTED
	draw_polyline(_path, Color(col, 0.20 if _live else 0.14), BAND, true)
	# Mərkəz nöqtələri irəli axır — xəttin hansı tərəfə "getdiyi" hərəkətdən
	# oxunur. Faza yol boyu ölçülür, ona görə səkmədə də qırılmır.
	var dot := Color(col.lerp(Color.WHITE, 0.35), 0.75 if _live else 0.35)
	var phase := fmod(_t * DOT_SPEED, DOT_GAP)
	var walked := 0.0
	var total := 0.0
	for i in _path.size() - 1:
		total += _path[i].distance_to(_path[i + 1])
	for i in _path.size() - 1:
		var a := _path[i]
		var b := _path[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var s := fposmod(phase - walked, DOT_GAP)
		while s < seg:
			# Disk — nöqtələr bir çəkiliş çağırışına yığılır (bax [BatchDraw]).
			BatchDraw.disc(self, a.lerp(b, s / seg), 3.5, dot)
			s += DOT_GAP
		walked += seg
		# Səkmə nöqtəsi — kiçik halqa: "top burada döndü".
		if i + 1 < _path.size() - 1:
			draw_arc(b, BAND * 0.5, 0.0, TAU, 20, Color(col, 0.55), 2.5, true)
	# Uc: Codex-in oxu son seqmentin istiqamətində.
	if total < ARROW_MIN:
		return
	var end := _path[_path.size() - 1]
	var prev := _path[_path.size() - 2]
	var ang := (end - prev).angle()
	# Ox hündürlüyü ARROW_SIZE-dir; ucu xəttin sonundan bir az qabağa çıxır.
	var ts := ARROW.get_size()
	var sz := ts * (ARROW_SIZE / ts.y)
	draw_set_transform(end, ang, Vector2.ONE)
	draw_texture_rect(ARROW, Rect2(Vector2(-sz.x * 0.7, -sz.y * 0.5), sz), false,
		Color(col, 0.9 if _live else 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Kilid: tez böyüyüb hədəfin üstünə "oturur", sonra söner. Yavaşca fırlanır —
## hərəkətsiz çərçivə rəqibin konturu ilə qarışırdı.
func _draw_lock() -> void:
	var k := 1.0 - _lock_t / LOCK_TIME           # 0 → 1
	var pop := 1.0 + 0.45 * pow(1.0 - minf(k / 0.25, 1.0), 2.0)
	var alpha := minf(1.0, _lock_t / (LOCK_TIME * 0.4))
	var ts := TARGET.get_size()
	var sz := ts * ((_lock_r * 2.0 + 30.0) * pop / maxf(ts.x, ts.y))
	draw_set_transform(_lock_at, _t * 1.4, Vector2.ONE)
	draw_texture_rect(TARGET, Rect2(-sz * 0.5, sz), false, Color(_lock_color, 0.95 * alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
