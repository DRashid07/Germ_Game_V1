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

## 60 FPS büdcəsi (saniyə).
const BUDGET := 1.0 / 60.0

var duration := 20.0

var _frames: Array[float] = []
## Kadrın ÖZ hesablama vaxtı (skriptlər + çəkilişin hazırlanması) — ekranın
## tezliyindən asılı deyil. Brauzerdə kadr aralığı həmişə requestAnimationFrame-ə
## bağlıdır; yükü aralıqdan yox, bundan oxumaq lazımdır.
var _cpu: Array[float] = []
var _elapsed := 0.0
var _warmup_left := WARMUP
var _peak_draw := 0
var _over := 0        ## 16.7 ms-i aşan kadr sayı
var _over2 := 0       ## 33.3 ms-i aşan kadr sayı
var _worst := 0.0
var _worst_at := 0.0


func _process(delta: float) -> void:
	if _warmup_left > 0.0:
		_warmup_left -= delta
		return

	_elapsed += delta
	_frames.append(delta)
	_cpu.append(Performance.get_monitor(Performance.TIME_PROCESS))
	# Sıçrayışın NƏ VAXT olduğu ölçüsü qədər vacibdir: başlanğıcda bir dəfə
	# olan sıçrayış shader kompilyasiyasıdır, oyun ortasında təkrarlanan isə
	# əsl problemdir. Orta rəqəm ikisini də gizlədir.
	if delta > BUDGET:
		_over += 1
		if delta > _worst:
			_worst = delta
			_worst_at = _elapsed
	if delta > BUDGET * 2.0:
		_over2 += 1
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
	# Büdcəni aşan kadrlar — telefonda "sürüşmə" kimi görünən şey budur.
	print("  Büdcəni aşan  : %d kadr > 16.7 ms, %d kadr > 33 ms (%d kadrdan)" % [
		_over, _over2, _frames.size()])
	if _worst > 0.0:
		print("  Ən pis sıçrayış: %.1f ms, ölçmənin %.1f-ci saniyəsində" % [
			_worst * 1000.0, _worst_at])
	var cpu := _cpu.duplicate()
	cpu.sort()
	var cpu_total := 0.0
	for c in _cpu:
		cpu_total += c
	print("  Kadrın işi    : %.2f ms orta, %.2f ms 1%% ən pis (TIME_PROCESS)" % [
		cpu_total / float(_cpu.size()) * 1000.0,
		float(cpu[mini(int(float(cpu.size()) * 0.99), cpu.size() - 1)]) * 1000.0])
	print("  Çəkiliş çağ.  : %d (pik)" % _peak_draw)
	print("  Node sayı     : %d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("  Statik yaddaş : %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))

	# 60 FPS = 16.67 ms. Mobil üçün hədəf budur.
	var budget := BUDGET * 1000.0
	print("  60 FPS büdcəsindən istifadə: %.0f%% (orta), %.0f%% (1%% ən pis)" % [
		avg * 1000.0 / budget * 100.0, p99 * 1000.0 / budget * 100.0])

	# VSYNC XƏBƏRDARLIĞI — bu olmasa alət səssizcə YALAN danışır.
	#
	# Ölçülən şey divar saatının kadr aralığıdır. Vsync açıq olanda o aralıq
	# oyunun yükündən yox, EKRANIN tezliyindən çıxır: yük nə qədər az olsa da,
	# nəticə həmişə 16.7 / 8.3 / 4.2 ms görünür. Sınanıb — `--max-fps 30` ilə
	# alət "büdcənin 200%-i" yazır, halbuki oyun daha yüngül işləyir.
	#
	# Bir dəfə bu rəqəmə inanılıb sənədə "büdcənin 25%-i" yazılmışdı; əslində
	# 240 Hz monitorun kadr aralığı idi, həqiqi yük isə 10–12% çıxdı.
	if DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED:
		print("")
		print("  ⚠ VSYNC AÇIQDIR — yuxarıdakı FPS və büdcə rəqəmləri OYUNUN")
		print("    yükünü yox, ekranın tezliyini göstərir. Yalnız çəkiliş")
		print("    çağırışı etibarlıdır. Düzgün ölçmək üçün: --disable-vsync")
	print("=====================================\n")
