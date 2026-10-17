extends SceneTree
## Codex üçün ölçü vərəqləri (şablonlar) — xəritə assetləri üçün.
##
## İstifadə (boş project.godot olan qovluqda, menu_art/process.gd kimi):
##   GODOT --headless --path <boş_layihə> -s template.gd -- <çıxış_qovluğu>
## Bütün şablonları birdən yazır: template_v1, _v2, _bush, _vent, _ring, _swirl,
## _grid2x2, _strip, _strip_green, _v4, _v4_bush (.png).
##
## Niyə şəkil, söz yox: image_gen "dairə kətanın 75%-idir" cümləsini hər dəfə
## başqa ölçüdə çəkir, bir dəstin maneələri isə EYNİ ölçü sistemində olmalıdır —
## pipeline onları toqquşma dairəsinə oturdur və 2% R-dən çox sapma rədd olunur.
## Şablon yalnız istinaddır: xətlər çıxışda OLMAMALIDIR (brifdə deyilir).
##
## Rəng dili hər şablonda eynidir:
##   qırmızı      ayaq izi = toqquşma dairəsi (maneənin silueti MƏHZ budur)
##   göy          üst üz (cap)
##   ştrixli boz  cənub yan üzü (kameraya baxan tərəf)
##   sarı ştrix   V2-nin "qalxma zonası" — cap ayaq izindən yalnız burada çıxa bilər
##   yaşıl        kolun bazası; düz ağ disk — kolun BOŞ mərkəzi
##   ştrixli boz (vent) deşiyin DAXİLİ divarı — şimalda enli, cənubda dar
##   narıncı ox   işığın gəldiyi tərəf (yuxarı-sol, LIGHT_DIR)
## Ölçülər design/map_art/research/design_critique.md §C-dən götürülüb.

const BG := Color(0.502, 0.502, 0.502)          # #808080
const RED := Color(0.85, 0.10, 0.10)
const BLUE := Color(0.10, 0.35, 0.90)
const GREEN := Color(0.10, 0.70, 0.25)
const AMBER := Color(0.94, 0.73, 0.31)
const ORANGE := Color(1.0, 0.55, 0.0)
const HATCH := Color(0.33, 0.35, 0.36)
const LIFT := Color(0.95, 0.85, 0.20)
const MAGENTA := Color(1.0, 0.0, 1.0)

var _img: Image


func _init() -> void:
	var dir := OS.get_cmdline_user_args()[0]
	# Qovluq yoxdursa save_png səssizcə uğursuz olur və skript yenə 0 ilə çıxır.
	DirAccess.make_dir_recursive_absolute(dir)
	_v1(dir)
	_v2(dir)
	_bush(dir, false)
	_bush(dir, true)
	_vent(dir)
	_ring(dir)
	_swirl(dir)
	_grid(dir)
	_strip(dir, MAGENTA, "template_strip.png")
	# V3-ün zolağı bənövşəyidir, açar rəngi YAŞILDIR — şablon da onu göstərməlidir.
	_strip(dir, Color(0.0, 1.0, 0.0), "template_strip_green.png")
	_v4(dir)
	quit()


# ---------- şablonlar ----------

func _v1(dir: String) -> void:
	_new(1024, 1024)
	_obstacle(Vector2(512, 512), Vector2(384, 384), Vector2(512, 474), Vector2(346, 346))
	_arrow()
	_save(dir, "template_v1.png")


## V2: cap ayaq izindən ən çox 38 px YUXARI çıxır — sarı ay-para: zirvədə y 90..128,
## yanlara doğru incələrək y ≈ 310-da sıfıra enir.
func _v2(dir: String) -> void:
	_new(1024, 1024)
	_obstacle(Vector2(512, 512), Vector2(384, 384), Vector2(512, 443), Vector2(353, 353))
	_arrow()
	_save(dir, "template_v2.png")


## V4: döşəmə 0.82 sıxılıb — ayaq izi ellipsdir, cap 54 px qalxır.
func _v4(dir: String) -> void:
	_new(1024, 1024)
	_obstacle(Vector2(512, 560), Vector2(384, 315), Vector2(512, 481), Vector2(353, 290))
	_arrow()
	_save(dir, "template_v4.png")


## Kol: zərf = ayaq izi ∪ yuxarı qaldırılmış disk. Ayaq izinin şimalında yalnız
## seyrək uclar ola bilər (açıq zona), boş mərkəz düz ağ diskdir.
func _bush(dir: String, v4: bool) -> void:
	_new(1024, 1024)
	var fc := Vector2(512, 560) if v4 else Vector2(512, 512)
	var fr := Vector2(384, 315) if v4 else Vector2(384, 384)
	var lc := Vector2(512, 481) if v4 else Vector2(512, 454)
	var hc := Vector2(512, 480) if v4 else Vector2(512, 470)
	var hr := Vector2(134, 110) if v4 else Vector2(134, 134)
	var br := Vector2(365, 299) if v4 else Vector2(365, 365)
	for y in 1024:
		for x in 1024:
			var p := Vector2(x, y)
			var in_f := _ed(p, fc, fr) <= 1.0
			var in_l := _ed(p, lc, fr) <= 1.0
			if in_l and not in_f:
				_img.set_pixel(x, y, Color(0.72, 0.80, 0.72))   # yalnız seyrək uclar
			elif in_f:
				_img.set_pixel(x, y, Color(0.42, 0.50, 0.44))
			# Boş mərkəz DÜZ AĞDIR, şahmat yox: image_gen şahmatı "şəffaflıq"
			# kimi şəklin içinə köçürür (bax menu_art/README «Şəffaflıq tələsi»).
			if _ed(p, hc, hr) <= 1.0:
				_img.set_pixel(x, y, Color.WHITE)
	_ellipse_line(fc, fr, RED, 6.0)
	_ellipse_line(lc, fr, BLUE, 4.0)
	_dashed(fc, br, GREEN, 5.0, 24)
	_arrow()
	_save(dir, "template_v4_bush.png" if v4 else "template_bush.png")


## Cərəyan: dodaq 9 kəhrəba kəsik, deşiyin dibi (512,539) r 342 — daxili divar
## şimalda enli (69 px), cənubda dar (15 px).
func _vent(dir: String) -> void:
	_new(1024, 1024)
	var c := Vector2(512, 512)
	var hc := Vector2(512, 539)
	for y in 1024:
		for x in 1024:
			var p := Vector2(x, y)
			if p.distance_to(c) <= 384.0 and p.distance_to(hc) > 342.0:
				if (x + y) % 18 < 7:
					_img.set_pixel(x, y, HATCH)
			elif p.distance_to(hc) <= 342.0:
				_img.set_pixel(x, y, Color(0.20, 0.22, 0.23))
	_ellipse_line(hc, Vector2(342, 342), BLUE, 4.0)
	# Qırmızı ayaq izi kəsiklərin ALTINDA da çəkilir: brif dodağı "qırmızı dairənin
	# üstündə" deyir, rəng dili hər şablonda eyni olmalıdır.
	_ellipse_line(c, Vector2(384, 384), RED, 3.0)
	_dashed(c, Vector2(384, 384), AMBER, 10.0, 9)
	_cross(c, RED)
	_arrow()
	_save(dir, "template_vent.png")


## Neytral halqa (dalğa, sıçrantı, xəbərdarlıq): r 420 və r 440, işıq oxu YOX.
func _ring(dir: String) -> void:
	_new(1024, 1024)
	var c := Vector2(512, 512)
	_ellipse_line(c, Vector2(420, 420), RED, 4.0)
	_ellipse_line(c, Vector2(440, 440), BLUE, 4.0)
	_cross(c, RED)
	_save(dir, "template_ring.png")


## Burulğan: r 269, fırlanır — işıq oxu YOX.
func _swirl(dir: String) -> void:
	_new(1024, 1024)
	var c := Vector2(512, 512)
	_ellipse_line(c, Vector2(269, 269), RED, 5.0)
	_cross(c, RED)
	_save(dir, "template_swirl.png")


## 2×2 vərəq: dörd 512-lik hücrə, hər birində r 200 (qırıntı) və r 180 (qəlpə).
func _grid(dir: String) -> void:
	_new(1024, 1024)
	for i in 4:
		var c := Vector2(256 + 512 * (i % 2), 256 + 512 * (i / 2))
		_ellipse_line(c, Vector2(200, 200), RED, 4.0)
		_ellipse_line(c, Vector2(180, 180), BLUE, 3.0)
		_cross(c, RED)
	for t in range(-2, 3):
		for k in 1024:
			_img.set_pixel(512 + t, k, Color(0.15, 0.15, 0.15))
			_img.set_pixel(k, 512 + t, Color(0.15, 0.15, 0.15))
	# İşıq oxu YOXDUR: ox 0-cı hücrənin dairəsinə düşürdü, qırıntılar isə qəsdən
	# işıqsızdır (oyun onları fırladır). Qəlpələrin işığı brifdə sözlə deyilir.
	_save(dir, "template_grid2x2.png")


## Zolaq: 1536×1024, zolaq yalnız y 320..704-də; qalan hər yer açar rəngidir
## (#FF00FF; bənövşəyi V3 üçün #00FF00 — template_strip_green).
## Aşağı kənar = şüşənin döşəməyə dəydiyi xətt (qalın tünd), yuxarı = dodaq (açıq).
func _strip(dir: String, key: Color, name: String) -> void:
	_new(1536, 1024)
	_img.fill(key)
	for y in range(320, 705):
		for x in 1536:
			_img.set_pixel(x, y, BG)
	for t in 8:
		for x in 1536:
			_img.set_pixel(x, 704 - t, Color(0.12, 0.12, 0.12))
			_img.set_pixel(x, 320 + t, Color(0.92, 0.92, 0.92))
	_save(dir, name)


# ---------- köməkçilər ----------

func _new(w: int, h: int) -> void:
	_img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	_img.fill(BG)


func _save(dir: String, name: String) -> void:
	var path := dir.path_join(name)
	_img.save_png(path)
	print("template -> ", path)


## Ellips məsafəsi: 1.0 = kontur üstündə.
func _ed(p: Vector2, c: Vector2, r: Vector2) -> float:
	var d := (p - c) / r
	return d.length()


## Maneə vərəqi: üst üz göy, ayaq izinin içində cap-dan kənar hissə ştrixli
## (cənub yan üzü), cap-ın ayaq izindən ÇIXAN hissəsi sarı (qalxma zonası).
func _obstacle(fc: Vector2, fr: Vector2, cc: Vector2, cr: Vector2) -> void:
	for y in 1024:
		for x in 1024:
			var p := Vector2(x, y)
			var in_f := _ed(p, fc, fr) <= 1.0
			var in_c := _ed(p, cc, cr) <= 1.0
			if in_c and not in_f:
				if (x - y + 4096) % 14 < 7:
					_img.set_pixel(x, y, LIFT)
			elif in_f and not in_c:
				_img.set_pixel(x, y, Color(0.42, 0.44, 0.45))
				if (x + y) % 18 < 6:
					_img.set_pixel(x, y, HATCH)
			elif in_c:
				_img.set_pixel(x, y, Color(0.62, 0.64, 0.65))
	_ellipse_line(cc, cr, BLUE, 4.0)
	_ellipse_line(fc, fr, RED, 6.0)
	_cross(fc, RED)


func _ellipse_line(c: Vector2, r: Vector2, col: Color, w: float) -> void:
	if w <= 0.0:
		return
	var steps := int(TAU * maxf(r.x, r.y) * 1.5)
	for i in steps:
		var a := TAU * float(i) / float(steps)
		_dot(c + Vector2(cos(a) * r.x, sin(a) * r.y), col, w)


func _dashed(c: Vector2, r: Vector2, col: Color, w: float, dashes: int) -> void:
	var steps := int(TAU * maxf(r.x, r.y) * 1.5)
	for i in steps:
		var a := TAU * float(i) / float(steps)
		# Kəsik : boşluq = 3 : 2 — boşluqlar aydın görünsün.
		if fposmod(a / TAU * float(dashes), 1.0) < 0.6:
			_dot(c + Vector2(cos(a) * r.x, sin(a) * r.y), col, w)


func _dot(p: Vector2, col: Color, w: float) -> void:
	var h := int(ceil(w * 0.5))
	for dy in range(-h, h + 1):
		for dx in range(-h, h + 1):
			if dx * dx + dy * dy > h * h:
				continue
			var x := int(p.x) + dx
			var y := int(p.y) + dy
			if x >= 0 and y >= 0 and x < _img.get_width() and y < _img.get_height():
				_img.set_pixel(x, y, col)


func _cross(c: Vector2, col: Color) -> void:
	for i in range(-24, 25):
		_dot(c + Vector2(i, 0), col, 3.0)
		_dot(c + Vector2(0, i), col, 3.0)


## İşıq oxu: yuxarı-sol küncdən içəri, LIGHT_DIR = (-0.45, -0.89) tərəfdən.
func _arrow() -> void:
	var ldir := Vector2(-0.45, -0.89).normalized()
	var head := Vector2(150, 110)
	var tail := head + ldir * 90.0
	var steps := 90
	for i in steps + 1:
		_dot(tail.lerp(head, float(i) / float(steps)), ORANGE, 6.0)
	var back := -ldir
	var side := Vector2(-back.y, back.x)
	for i in 29:
		var t := float(i) / 28.0
		_dot(head.lerp(head - back * 28.0 + side * 18.0, t), ORANGE, 6.0)
		_dot(head.lerp(head - back * 28.0 - side * 18.0, t), ORANGE, 6.0)
