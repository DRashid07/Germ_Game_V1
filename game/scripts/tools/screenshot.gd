class_name Screenshot
extends Node
## Oyunu bir neçə kadr işlədib ekran görüntüsü saxlayır, sonra çıxır.
##
##   Godot_v4.7.2.exe --path game --resolution 1280x720 -- --practice --shot C:/.../kadr.png
##
## Redaktoru açmadan tərtibatın doğru oturduğunu yoxlamaq üçündür.
## Headless rejimdə işləmir — həqiqi render tələb olunur.
##
## ── Kadr ardıcıllığı ─────────────────────────────────────────────────────
## `--shot-count N --shot-every K` verilərsə, ilk kadrdan sonra hər K kadrda
## bir daha çəkir və faylları `kadr_00.png`, `kadr_01.png` … adlandırır.
##
## Tək kadr ANİ hadisələri tuta bilmir: super 0.1–2.5 saniyə yaşayır,
## partlayış 0.4 saniyə, doğuş pop-u 0.35 saniyə. Təsadüfi gecikmə ilə çəkilən
## tək şəkildə effekt ya hələ başlamamışdı, ya artıq bitmişdi — və "görünmür"
## şikayətini nə təsdiq, nə də təkzib etmək olurdu.

var path := "shot.png"
var delay_frames := 90
## Neçə kadr çəkilir. 1 = köhnə davranış (fayl adı dəyişmir).
var count := 1
## Ardıcıllıqda iki kadr arasındakı kadr sayı.
var every := 6

var _frames := 0
var _taken := 0


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < delay_frames + _taken * every:
		return
	set_process(false)
	# Pəncərə bəzən MİNİMALLAŞDIRILMIŞ açılır (başqa pəncərə fokusdadırsa). Onda
	# Godot heç nə çəkmir və aşağıdakı `frame_post_draw` heç vaxt gəlmir.
	if get_window().mode == Window.MODE_MINIMIZED:
		print("[shot] pəncərə minimallaşdırılıb — bərpa edilir")
		get_window().mode = Window.MODE_WINDOWED
		get_window().move_to_foreground()
		await get_tree().create_timer(0.5).timeout
	# Kadrın tam çəkilməsini gözləyirik, yoxsa boş şəkil alınır.
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out := _path_for(_taken)
	var err := img.save_png(out)
	if err == OK:
		print("[shot] saxlanıldı: %s (%dx%d)" % [out, img.get_width(), img.get_height()])
	else:
		printerr("[shot] saxlanmadı: %s" % error_string(err))
	_taken += 1
	if _taken < count:
		set_process(true)
		return

	# Çıxış RENDER GERİ ÇAĞIRIŞININ İÇİNDƏN edilmir.
	#
	# Yuxarıdakı `await` bizi `frame_post_draw` siqnalının içinə salır, yəni
	# rendering server hələ kadrı bağlayır. Elə oradan `quit()` çağırmaq
	# bağlanma sırasını pozur və çıxışda "N resources still in use" /
	# "ObjectDB instances were leaked" xəbərdarlıqlarını verə bilir.
	#
	# QEYD: bu xəbərdarlıq təkrarlana bilmədi — 40-dan çox çalışmada səhnədən,
	# səs sürücüsündən, gözləyən taymerdən və çıxış yolundan asılı olmadığı
	# göstərildi. Yəni bu, sübut edilmiş düzəliş deyil, sadəcə düzgün sıra:
	# kadrdan çıxıb normal döngəyə qayıdırıq, sonra bağlayırıq.
	await get_tree().process_frame
	get_tree().quit()


func _path_for(i: int) -> String:
	if count <= 1:
		return path
	return "%s_%02d.%s" % [path.get_basename(), i, path.get_extension()]
