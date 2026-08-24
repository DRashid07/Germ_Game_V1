class_name PerfProbe
extends Node
## Performans ölçmə aləti.
##
##   Godot_v4.7.2.exe --path game -- --practice --perf 20
##
## Kadr vaxtlarını toplayır və sonda orta, 1% ən pis və ən pis kadrı yazır.
##
## DİQQƏT: masaüstü nəticəsi telefon nəticəsi DEYİL. Bu ölçmə iki şeyi deyir:
##   1. Kadr sıçrayışı (spike) varmı — bu, hər cihazda problem yaradır
##   2. Çəkiliş çağırışlarının sayı — mobil GPU-da əsas məhdudiyyət budur
## Əsl FPS rəqəmi üçün orta səviyyəli cihazda ölçmək lazımdır.

## Ölçmədən əvvəl gözlənilən müddət — shader kompilyasiyası və ilk kadr
## sıçrayışları nəticəni korlamasın.
const WARMUP := 2.0

var duration := 20.0

var _frames: Array[float] = []
var _elapsed := 0.0
var _warmup_left := WARMUP
var _peak_draw := 0


func _process(delta: float) -> void:
	if _warmup_left > 0.0:
		_warmup_left -= delta
		return

	_elapsed += delta
	_frames.append(delta)
	_peak_draw = maxi(_peak_draw,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))

	if _elapsed >= duration:
		set_process(false)
		_report()
		get_tree().quit()


func _report() -> void:
	if _frames.is_empty():
		printerr("[perf] ölçmə alınmadı")
		return

	var sorted := _frames.duplicate()
	sorted.sort()

	var total := 0.0
	for f in _frames:
		total += f
	var avg := total / float(_frames.size())

	# 1% ən pis kadr: real "ilişmə" hissini bu göstərir, orta FPS yox.
	var p99: float = sorted[mini(int(float(sorted.size()) * 0.99), sorted.size() - 1)]
	var worst: float = sorted[-1]

	print("\n===== Performans (%d kadr, %.1f s) =====" % [_frames.size(), _elapsed])
	print("  Orta          : %6.2f FPS  (%.2f ms)" % [1.0 / avg, avg * 1000.0])
	print("  1%% ən pis     : %6.2f FPS  (%.2f ms)" % [1.0 / p99, p99 * 1000.0])
	print("  Ən pis kadr   : %6.2f FPS  (%.2f ms)" % [1.0 / worst, worst * 1000.0])
	print("  Çəkiliş çağ.  : %d (pik)" % _peak_draw)
	print("  Node sayı     : %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("  Statik yaddaş : %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

	# 60 FPS = 16.67 ms. Mobil üçün hədəf budur.
	var budget := 16.67
	print("  60 FPS büdcəsindən istifadə: %.0f%% (orta), %.0f%% (1%% ən pis)" % [
		avg * 1000.0 / budget * 100.0, p99 * 1000.0 / budget * 100.0])
	print("=====================================\n")
