class_name Screenshot
extends Node
## Oyunu bir neçə kadr işlədib ekran görüntüsü saxlayır, sonra çıxır.
##
##   Godot_v4.7.2.exe --path game --resolution 1280x720 -- --practice --shot C:/.../kadr.png
##
## Redaktoru açmadan tərtibatın doğru oturduğunu yoxlamaq üçündür.
## Headless rejimdə işləmir — həqiqi render tələb olunur.

var path := "shot.png"
var delay_frames := 90

var _frames := 0


func _process(_delta: float) -> void:
	_frames += 1
	if _frames < delay_frames:
		return
	set_process(false)
	# Kadrın tam çəkilməsini gözləyirik, yoxsa boş şəkil alınır.
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	if err == OK:
		print("[shot] saxlanıldı: %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	else:
		printerr("[shot] saxlanmadı: %s" % error_string(err))

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
