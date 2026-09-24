extends SceneTree
## Usage: -- <mode> <in> <out> <max_side>
##   mode = trim : crop to alpha bbox (+pad), downscale so longest side <= max_side
##   mode = key  : remove flat #FF00FF background first, then trim
##   mode = info : print size, alpha at corners, used rect
##   mode = card : -- card <in> <out> <width> <aspect w/h> <corner radius px>
##                 crop an opaque portrait to the card aspect (keeps 35% of the cut
##                 above the subject), resize to <width>, round the corners in alpha

func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var mode := a[0]
	var img := Image.load_from_file(a[1])
	if img == null:
		printerr("cannot load ", a[1]); quit(1); return
	img.convert(Image.FORMAT_RGBA8)
	if mode == "card":
		_card(img, a[2], int(a[3]), float(a[4]), float(a[5]))
		quit(); return
	if mode == "info":
		var w := img.get_width(); var h := img.get_height()
		print("size %dx%d  corner alpha %.2f %.2f %.2f %.2f  used %s" % [w, h,
			img.get_pixel(4, 4).a, img.get_pixel(w - 5, 4).a,
			img.get_pixel(4, h - 5).a, img.get_pixel(w - 5, h - 5).a, img.get_used_rect()])
		quit(); return
	if mode == "key":
		_key(img)
	var r := img.get_used_rect()
	# Tiny alpha dust far from the subject would blow up the bbox — ignore alpha < 8/255.
	r = _solid_rect(img, 0.03)
	var pad := int(max(r.size.x, r.size.y) * 0.02)
	r = r.grow(pad).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var out := img.get_region(r)
	var max_side := int(a[3])
	var s := float(max_side) / float(max(out.get_width(), out.get_height()))
	if s < 1.0:
		out.resize(int(round(out.get_width() * s)), int(round(out.get_height() * s)), Image.INTERPOLATE_LANCZOS)
	out.save_png(a[2])
	print("%s -> %s  %dx%d (crop %s)" % [a[1].get_file(), a[2].get_file(), out.get_width(), out.get_height(), r])
	quit()


func _solid_rect(img: Image, thr: float) -> Rect2i:
	var w := img.get_width(); var h := img.get_height()
	var x0 := w; var y0 := h; var x1 := -1; var y1 := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > thr:
				x0 = mini(x0, x); y0 = mini(y0, y); x1 = maxi(x1, x); y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Flat magenta key. For a pixel P = a*C + (1-a)*K with K = (1,0,1), the
## "magenta-ness" min(r,b) - g equals 1-a exactly when C is the dark outline,
## which is what borders the whole silhouette. Colour is then un-mixed.
func _key(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			var m := minf(p.r, p.b) - p.g
			var al := clampf((1.0 - m - 0.06) / 0.88, 0.0, 1.0)
			if al <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := Color(
				clampf((p.r - (1.0 - al)) / al, 0.0, 1.0),
				clampf(p.g / al, 0.0, 1.0),
				clampf((p.b - (1.0 - al)) / al, 0.0, 1.0), al)
			img.set_pixel(x, y, c)


## Portrait card: the art must fill the card face exactly, and TextureRect cannot
## clip rounded corners — so the corners are cut into the alpha here.
func _card(img: Image, out_path: String, width: int, aspect: float, radius: float) -> void:
	var w := img.get_width(); var h := img.get_height()
	var cw := w; var ch := int(round(w / aspect))
	if ch > h:
		ch = h; cw = int(round(h * aspect))
	var x0 := (w - cw) / 2
	# Characters sit in the upper-middle and the name band is at the bottom:
	# take 35% of the excess from the top, 65% from the bottom.
	var y0 := int((h - ch) * 0.35)
	var out := img.get_region(Rect2i(x0, y0, cw, ch))
	var height := int(round(width / aspect))
	out.resize(width, height, Image.INTERPOLATE_LANCZOS)
	for y in height:
		for x in width:
			var dx := maxf(maxf(radius - x, x - (width - 1 - radius)), 0.0)
			var dy := maxf(maxf(radius - y, y - (height - 1 - radius)), 0.0)
			if dx <= 0.0 or dy <= 0.0:
				continue
			var d := sqrt(dx * dx + dy * dy) - radius
			var cov := clampf(0.5 - d, 0.0, 1.0)
			var p := out.get_pixel(x, y)
			p.a *= cov
			out.set_pixel(x, y, p)
	out.save_png(out_path)
	print("%s -> %s  %dx%d (crop %d,%d %dx%d)" % [img.get_width(), out_path.get_file(), width, height, x0, y0, cw, ch])
