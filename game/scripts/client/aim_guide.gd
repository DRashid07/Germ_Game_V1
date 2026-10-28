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
## Əlavə yollar — ayaqlının ikinci iynəsi ([method show_paths]).
var _extra: Array[PackedVector2Array] = []
## Zolağın eni bu atəşdə — mərminin radiusundan ([constant BAND]).
var _band := BAND
## Amöbün damcısı: başlanğıc, düşmə nöqtəsi və düşmə yeri etibarlıdırmı.
var _lob := false
var _lob_from := Vector2.ZERO
var _lob_to := Vector2.ZERO
var _lob_ok := true
var _color := Color.WHITE
var _live := true
var _t := 0.0

var _lock_key := -1
var _lock_t := 0.0
var _lock_at := Vector2.ZERO
var _lock_r := 0.0
var _lock_color := Color.WHITE

## Nişanın ÜST hissəsi — səkmə halqaları, ox və kilid çərçivəsi. Kol yarpaqları
## mikrobların üstündədir (z 2); bu hissə onların da üstündə olmalıdır, yoxsa
## kola nişan alanda ox və kilid yarpaq altında itərdi (critique B2–B3). Zolaq
## və nöqtələr isə döşəmədə, mikrobların altında qalır — nişan alınan rəqibi
## örtməsin deyə.
var _over: Node2D


func _ready() -> void:
	# Ikonlar 256 px-dir, dünyada ~50 px: mipmap-sız kiçiltmə konturu dişləyir.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_over = Node2D.new()
	_over.z_index = 3
	add_child(_over)
	_over.draw.connect(_draw_over)


## Xətti göstərir. [param can_fire] — buraxsan top indi atılarmı.
func show_path(path: PackedVector2Array, color: Color, can_fire: bool) -> void:
	show_paths([path], color, can_fire)


## Bir neçə xətt — ayaqlının iki iynəsi yelpik kimi açılır, ikisi də göstərilir.
## [param shot_r] — mərminin radiusu: zolaq ondan bir az enlidir.
func show_paths(paths: Array, color: Color, can_fire: bool, shot_r := Const.SHOT_RADIUS) -> void:
	_lob = false
	_path = paths[0] if not paths.is_empty() else PackedVector2Array()
	_extra.clear()
	for i in range(1, paths.size()):
		_extra.append(paths[i])
	_band = shot_r * 2.0 + 8.0
	_color = color
	_live = can_fire
	_redraw()


## Amöbün damcısı: qövs və düşmə halqası. [param valid] false — düşmə yeri etibarsızdır
## (şüşədən kənar və ya bərk maneənin içi): halqa qırmızıdır, buraxsan atılmayacaq.
func show_lob(from: Vector2, to: Vector2, color: Color, can_fire: bool, valid: bool) -> void:
	_lob = true
	_lob_from = from
	_lob_to = to
	_lob_ok = valid
	_path = PackedVector2Array([from, to])
	_extra.clear()
	_color = color
	_live = can_fire and valid
	_redraw()


func hide_path() -> void:
	if _path.is_empty():
		return
	_path = PackedVector2Array()
	_extra.clear()
	_lob = false
	_redraw()


## Avtomatik nişanın hədəfi [param key] üçün kilidi açır.
func lock(key: int, at: Vector2, radius: float, color: Color) -> void:
	_lock_key = key
	_lock_t = LOCK_TIME
	_lock_at = at
	_lock_r = radius
	_lock_color = color
	_redraw()


## Kilidlənmiş rəqib — işarə onun ardınca gedir; yoxdursa -1.
func locked_key() -> int:
	return _lock_key if _lock_t > 0.0 else -1


func follow(at: Vector2, radius: float) -> void:
	_lock_at = at
	_lock_r = radius


func unlock() -> void:
	_lock_t = 0.0
	_lock_key = -1
	_redraw()


func _process(delta: float) -> void:
	_t += delta
	if _lock_t > 0.0:
		_lock_t = maxf(0.0, _lock_t - delta)
		if _lock_t <= 0.0:
			_lock_key = -1
		_redraw()
	elif not _path.is_empty():
		_redraw()


func _redraw() -> void:
	queue_redraw()
	if _over != null:
		_over.queue_redraw()


func _draw() -> void:
	if _lob:
		_draw_lob()
		return
	if _path.size() >= 2:
		_draw_path(_path)
	for p in _extra:
		if p.size() >= 2:
			_draw_path(p)


## Üst hissə — yarpaqların üstündə (bax [member _over]).
func _draw_over() -> void:
	if _path.size() >= 2 and not _lob:
		_draw_path_top(_path)
		for p in _extra:
			if p.size() >= 2:
				_draw_path_top(p)
	if _lock_t > 0.0:
		_draw_lock()


func _draw_path(path: PackedVector2Array) -> void:
	var col := _color if _live else Palette.TEXT_MUTED
	draw_polyline(path, Color(col, 0.20 if _live else 0.14), _band, true)
	# Mərkəz nöqtələri irəli axır — xəttin hansı tərəfə "getdiyi" hərəkətdən
	# oxunur. Faza yol boyu ölçülür, ona görə səkmədə də qırılmır.
	var dot := Color(col.lerp(Color.WHITE, 0.35), 0.75 if _live else 0.35)
	var phase := fmod(_t * DOT_SPEED, DOT_GAP)
	var walked := 0.0
	for i in path.size() - 1:
		var a := path[i]
		var b := path[i + 1]
		var seg := a.distance_to(b)
		if seg < 0.001:
			continue
		var s := fposmod(phase - walked, DOT_GAP)
		while s < seg:
			# Disk — nöqtələr bir çəkiliş çağırışına yığılır (bax [BatchDraw]).
			BatchDraw.disc(self, a.lerp(b, s / seg), 3.5, dot)
			s += DOT_GAP
		walked += seg


func _draw_path_top(path: PackedVector2Array) -> void:
	var col := _color if _live else Palette.TEXT_MUTED
	var total := 0.0
	for i in path.size() - 1:
		total += path[i].distance_to(path[i + 1])
		# Səkmə nöqtəsi — kiçik halqa: "top burada döndü".
		if i + 1 < path.size() - 1:
			_over.draw_arc(path[i + 1], _band * 0.5, 0.0, TAU, 20, Color(col, 0.55), 2.5, true)
	# Uc: Codex-in oxu son seqmentin istiqamətində.
	if total < ARROW_MIN:
		return
	var end := path[path.size() - 1]
	var prev := path[path.size() - 2]
	var ang := (end - prev).angle()
	# Ox hündürlüyü ARROW_SIZE-dir; ucu xəttin sonundan bir az qabağa çıxır.
	var ts := ARROW.get_size()
	var sz := ts * (ARROW_SIZE / ts.y)
	_over.draw_set_transform(end, ang, Vector2.ONE)
	_over.draw_texture_rect(ARROW, Rect2(Vector2(-sz.x * 0.7, -sz.y * 0.5), sz), false,
		Color(col, 0.9 if _live else 0.45))
	_over.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Damcının nişanı: döşəmədə nöqtəli qövs (hündürlük [constant LobMarks.ARC_HEIGHT]) və
## düşmə halqası. Etibarsız yerdə halqa qırmızı və üstündən xətt — atılmayacaq.
func _draw_lob() -> void:
	var col := _color if _live else Palette.TEXT_MUTED
	if not _lob_ok:
		col = Palette.DANGER
	var steps := maxi(int(_lob_from.distance_to(_lob_to) / DOT_GAP * 1.5), 4)
	var phase := fmod(_t * DOT_SPEED / DOT_GAP, 1.0) / float(steps)
	for i in steps:
		var u := float(i) / float(steps) + phase
		if u > 1.0:
			continue
		var p := _lob_from.lerp(_lob_to, u) \
			- Vector2(0.0, LobMarks.ARC_HEIGHT * ShotPrediction.lob_height(u))
		BatchDraw.disc(self, p, 3.5, Color(col.lerp(Color.WHITE, 0.35), 0.75 if _live else 0.4))
	BatchDraw.disc(self, _lob_to, Const.LOB_AREA, Color(col, 0.16 if _lob_ok else 0.22))
	BatchDraw.ring(self, _lob_to, Const.LOB_AREA, 0.0, TAU, 40, Color(col, 0.85), 3.0)
	if not _lob_ok:
		var d := Vector2(Const.LOB_AREA, Const.LOB_AREA) * 0.6
		draw_line(_lob_to - d, _lob_to + d, Color(col, 0.9), 5.0, true)


## Kilid: tez böyüyüb hədəfin üstünə "oturur", sonra söner. Yavaşca fırlanır —
## hərəkətsiz çərçivə rəqibin konturu ilə qarışırdı.
func _draw_lock() -> void:
	var k := 1.0 - _lock_t / LOCK_TIME           # 0 → 1
	var pop := 1.0 + 0.45 * pow(1.0 - minf(k / 0.25, 1.0), 2.0)
	var alpha := minf(1.0, _lock_t / (LOCK_TIME * 0.4))
	var ts := TARGET.get_size()
	var sz := ts * ((_lock_r * 2.0 + 30.0) * pop / maxf(ts.x, ts.y))
	_over.draw_set_transform(_lock_at, _t * 1.4, Vector2.ONE)
	_over.draw_texture_rect(TARGET, Rect2(-sz * 0.5, sz), false, Color(_lock_color, 0.95 * alpha))
	_over.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
