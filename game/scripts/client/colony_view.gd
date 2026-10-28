class_name ColonyView
extends Node2D
## SONSUZ ARENA-nın qida koloniyaları — görüntü (bax design/MODES.md §18, [Sim.ColonyState]).
##
## Koloniya bəzəkdən seçilməlidir: qida rəngində şişkin hüceyrələrdən rozet, altında
## qidanın çıxdığı sahənin zəif halosu. Ehtiyat azaldıqca hüceyrələr bir-bir kiçilib sönür —
## mənbə uzaqdan "dolu / yarım / boş" oxunur. Tükənəndə quru boz nüvə qalır və onun
## ətrafında BƏRPA HALQASI dolur. Bol koloniya iri və doqquz hüceyrəlidir, zəif olan
## kiçik və altı hüceyrəli.
##
## Vəziyyət YALNIZ snapshot-dan gəlir ([method apply]): client ehtiyatı özü xərcləmir.
## Görünən doluluq hədəfə yumşaq yaxınlaşır, bərpa halqası isə snapshot-lar arasında yerli
## saatla irəliləyir və hər snapshot onu düzəldir — paket itsə də növbəti bərpa edir.
##
## Hər koloniya ayrıca uşaq node-dur və YALNIZ görüntüsü dəyişəndə yenidən çəkilir (dolu
## dayanan koloniya heç vaxt). "Nəfəs" transformasiya ilə verilir, yenidən çəkilişsiz.
## Hamısı sadə çəkilişdir, shader və glow-dan asılı deyil — bütün keyfiyyətlərdə eyni oxunur.

## Rozetdəki hüceyrə sayı, növə görə ([enum Const.ColonyKind]).
const CELLS := [9, 6]
## Görünən doluluq bu qədər dəyişəndə yenidən çəkilir.
const REDRAW_STEP := 1.0 / 24.0
## Doluluğun hədəfə yaxınlaşma sürəti (saniyədə tam diapazonun bu qədəri).
const FILL_SPEED := 2.5
## Hüceyrələrin rəngi — qidanınkı, amma glow həddindən aşağı: koloniya parlayan top deyil.
const CELL := Color(0.70, 0.86, 0.60)
const CELL_LIGHT := Color(0.93, 1.0, 0.88)
## Tükənmiş koloniyanın quru nüvəsi.
const DRY := Color(0.42, 0.40, 0.31)


class Spot:
	var node: Node2D
	var kind := 0
	var full := 1
	var stock := -1             ## snapshot-dan; -1 — hələ gəlməyib
	var shown := 1.0            ## görünən doluluq 0..1
	var drawn := -1.0
	var regen_end := 0.0        ## yerli saatla bərpanın sonu; 0 — işləyir
	var drawn_regen := -1.0
	var phase := 0.0


var _spots: Array[Spot] = []
var _now := 0.0


## Yerlər join info-dan: `[x, y, növ, ...]` ([method Sim.colony_flat]).
func setup(flat: PackedFloat32Array) -> void:
	var i := 0
	while i + 3 <= flat.size():
		var s := Spot.new()
		s.kind = clampi(int(flat[i + 2]), 0, CELLS.size() - 1)
		s.full = Const.COLONY_STOCK[s.kind]
		s.phase = float(_spots.size()) * 1.7
		var n := Node2D.new()
		n.position = Vector2(flat[i], flat[i + 1])
		BatchDraw.use_mipmaps(n)
		n.draw.connect(_draw_spot.bind(_spots.size()))
		add_child(n)
		s.node = n
		_spots.append(s)
		i += 3


func count() -> int:
	return _spots.size()


## Snapshot-un koloniya sətri ([method Sim.colony_bytes]): hər koloniyaya ehtiyat və
## bərpaya qalan vaxt ([constant Const.COLONY_REGEN_STEP] vahidində).
func apply(state: PackedByteArray) -> void:
	for i in mini(_spots.size(), state.size() / 2):
		var s := _spots[i]
		s.stock = int(state[i * 2])
		var q := int(state[i * 2 + 1])
		if s.stock <= 0 and q > 0:
			var end := _now + float(q) * Const.COLONY_REGEN_STEP
			# Yerli saat snapshot-lar arasında özü gedir; yalnız aşkar fərqi düzəlt —
			# hər snapshot-da yazılsaydı halqa addım-addım titrəyərdi.
			if s.regen_end <= 0.0 or absf(end - s.regen_end) > Const.COLONY_REGEN_STEP * 1.5:
				s.regen_end = end
		else:
			s.regen_end = 0.0


## Koloniyanın görünən doluluğu (0..1) — test və HUD üçün.
func shown_fill(i: int) -> float:
	return _spots[i].shown if i < _spots.size() else 0.0


## Bərpa halqasının doluluğu (0..1); işləyən koloniyada 0.
func regen_progress(i: int) -> float:
	if i >= _spots.size():
		return 0.0
	var s := _spots[i]
	if s.regen_end <= 0.0:
		return 0.0
	var total: float = Const.COLONY_REGEN[s.kind]
	return clampf(1.0 - (s.regen_end - _now) / total, 0.0, 1.0)


func _process(delta: float) -> void:
	_now += delta
	for i in _spots.size():
		var s := _spots[i]
		var want := float(maxi(s.stock, 0)) / float(s.full) if s.stock >= 0 else 1.0
		s.shown = move_toward(s.shown, want, delta * FILL_SPEED)
		var regen := regen_progress(i)
		if absf(s.shown - s.drawn) >= REDRAW_STEP or (s.shown == want and s.drawn != want) \
				or absf(regen - s.drawn_regen) >= 0.01:
			s.drawn = s.shown
			s.drawn_regen = regen
			s.node.queue_redraw()
		# Nəfəs: dolu koloniya yavaş döyünür, boş olan donur.
		var k := 1.0 + 0.035 * s.shown * sin(_now * 2.2 + s.phase)
		s.node.scale = Vector2(k, k)


func _draw_spot(i: int) -> void:
	var s := _spots[i]
	var n := s.node
	var r: float = Const.COLONY_RADIUS[s.kind]
	var fill := clampf(s.drawn, 0.0, 1.0)
	# Əvvəl bütün disklər, sonra halqalar: eyni növ çəkilişlər bir çağırışa yığılır.
	# Sahənin halosu — qida buradan çıxır. Həmişə var: boş mənbə də yerini göstərir.
	BatchDraw.disc(n, Vector2.ZERO, Const.COLONY_SPREAD + 12.0, Color(CELL, 0.05 + 0.07 * fill))
	BatchDraw.disc(n, Vector2.ZERO, r * 0.95, Color(Palette.OUTLINE, 0.45))
	BatchDraw.disc(n, Vector2.ZERO, r * 0.62, DRY.lerp(CELL.darkened(0.3), fill))
	# Hüceyrələr: doluluq azaldıqca sonuncular əvvəl kiçilib yox olur.
	var cells: int = CELLS[s.kind]
	for k in cells:
		var share := clampf(fill * float(cells) - float(k), 0.0, 1.0)
		if share <= 0.0:
			continue
		var a := TAU * float(k) / float(cells) + 0.35 * float(k % 2)
		var at := Vector2.from_angle(a) * r * (0.62 + 0.10 * float(k % 2))
		var cr := r * (0.30 + 0.07 * float(k % 3)) * (0.45 + 0.55 * share)
		BatchDraw.disc(n, at, cr + 2.0, Color(Palette.OUTLINE, 0.6))
		BatchDraw.disc(n, at, cr, Color(CELL, 0.55 + 0.45 * share))
		BatchDraw.disc(n, at + Vector2(-0.3, -0.35) * cr, cr * 0.38, Color(CELL_LIGHT, 0.75 * share))
	if fill > 0.0:
		BatchDraw.disc(n, Vector2.ZERO, r * 0.30 * (0.5 + 0.5 * fill), Color(CELL_LIGHT, 0.85))
	# Bərpa: tükənmiş koloniyanın ətrafında boz halqa, üstündə dolan qövs (12-dən saat əqrəbi ilə).
	if s.stock == 0 or s.drawn_regen > 0.0:
		var rr := r + 12.0
		BatchDraw.ring(n, Vector2.ZERO, rr, 0.0, TAU, 40, Color(DRY, 0.7), 2.0)
		if s.drawn_regen > 0.0:
			BatchDraw.ring(n, Vector2.ZERO, rr, -PI * 0.5, -PI * 0.5 + TAU * s.drawn_regen,
				maxi(4, int(40.0 * s.drawn_regen)), Color(CELL_LIGHT, 0.95), 3.0)
