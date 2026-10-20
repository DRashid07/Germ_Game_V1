extends SceneTree
## Usage: -- <mode> <in> <out> <max_side>
##   mode = trim : crop to alpha bbox (+pad), downscale so longest side <= max_side
##   mode = key  : remove flat #FF00FF background first, then trim
##   mode = keyc : remove a flat background of any colour (sampled from the corners), then trim
##   mode = info : print size, alpha at corners, used rect
##   mode = card : -- card <in> <out> <width> <aspect w/h> <corner radius px>
##                 crop an opaque portrait to the card aspect (keeps 35% of the cut
##                 above the subject), resize to <width>, round the corners in alpha
##   mode = splash : -- splash <in> <out> <canvas w> <canvas h> <logo height fraction>
##                 trim a transparent logo and centre it on a transparent canvas
##                 (the boot splash: Godot fits the whole canvas to the screen)
##   mode = png  : -- png <in> <out>  save any loadable image (SVG at its own size) as PNG

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
	if mode == "splash":
		_splash(img, a[2], int(a[3]), int(a[4]), float(a[5]))
		quit(); return
	if mode == "png":
		img.save_png(a[2])
		print("%s -> %s  %dx%d" % [a[1].get_file(), a[2].get_file(), img.get_width(), img.get_height()])
		quit(); return
	if mode == "info":
		var w := img.get_width(); var h := img.get_height()
		print("size %dx%d  corner alpha %.2f %.2f %.2f %.2f  used %s" % [w, h,
			img.get_pixel(4, 4).a, img.get_pixel(w - 5, 4).a,
			img.get_pixel(4, h - 5).a, img.get_pixel(w - 5, h - 5).a, img.get_used_rect()])
		quit(); return
	if mode == "key":
		_key(img)
	if mode == "keyc":
		_key_sampled(img)
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


## Key of any flat background colour K, sampled from the four corners. image_gen's
## "magenta" is really ~#FC40C1, and the #FF00FF formula above misreads it. With the
## dark outline (C = 0) on the border, P = (1-a)K, so t = min(r/K.r, b/K.b) is 1-a;
## the green EXCESS over K.g*t is what tells the logo's own colours (lime, ivory,
## white — all high in green) apart from the key.
func _key_sampled(img: Image) -> void:
	var w := img.get_width(); var h := img.get_height()
	var k := Color(0, 0, 0, 0)
	for p in [Vector2i(8, 8), Vector2i(w - 9, 8), Vector2i(8, h - 9), Vector2i(w - 9, h - 9)]:
		k += img.get_pixelv(p) * 0.25
	print("key colour %s" % k.to_html(false))
	for y in h:
		for x in w:
			var p := img.get_pixel(x, y)
			var t := minf(p.r / k.r, p.b / k.b)
			var m := t - 2.5 * maxf(p.g - k.g * t, 0.0)
			var al := clampf((1.0 - m - 0.06) / 0.88, 0.0, 1.0)
			if al <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := Color(
				clampf((p.r - (1.0 - al) * k.r) / al, 0.0, 1.0),
				clampf((p.g - (1.0 - al) * k.g) / al, 0.0, 1.0),
				clampf((p.b - (1.0 - al) * k.b) / al, 0.0, 1.0), al)
			img.set_pixel(x, y, c)
	# Noise in the painted key leaves a few faint pixels far from the art; they would
	# stretch the trim box to the whole canvas. Clear everything outside the box of
	# the solid art (grown by 1% for the antialiased rim).
	var solid := _solid_rect(img, 0.5)
	var keep := solid.grow(int(max(solid.size.x, solid.size.y) * 0.01))
	for y in h:
		for x in w:
			if not keep.has_point(Vector2i(x, y)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))


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


## Boot splash: Godot scales the WHOLE image to the screen (`Keep`) and draws it on
## `boot_splash/bg_color`, so the canvas sets the logo's size on screen.
func _splash(img: Image, out_path: String, cw: int, ch: int, frac: float) -> void:
	var r := _solid_rect(img, 0.03)
	var logo := img.get_region(r)
	var th := int(round(ch * frac))
	var tw := int(round(logo.get_width() * float(th) / logo.get_height()))
	logo.resize(tw, th, Image.INTERPOLATE_LANCZOS)
	var out := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	out.blit_rect(logo, Rect2i(Vector2i.ZERO, logo.get_size()), Vector2i((cw - tw) / 2, (ch - th) / 2))
	# Fully transparent pixels carry no colour: a premultiplied blend would add it.
	for y in ch:
		for x in cw:
			if out.get_pixel(x, y).a <= 0.0:
				out.set_pixel(x, y, Color(0, 0, 0, 0))
	out.save_png(out_path)
	print("%s -> %s  logo %dx%d on %dx%d (crop %s)" % [img.get_width(), out_path.get_file(), tw, th, cw, ch, r])
