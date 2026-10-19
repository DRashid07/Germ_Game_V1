extends SceneTree
## V1 "Damla" xəritə dəsti → oyunun atlası, döşəməsi və şüşə divarı.
##
## İstifadə (boş project.godot olan qovluqda, template.gd kimi):
##   GODOT --headless --path build/map_tool -s <repo>/design/map_art/build_map.gd -- <repo>
##
## Giriş: `raw/v1/` (sahib 2026-10-19-da təsdiqləyib) və `raw/shared/`.
## Çıxış — `game/assets/map/`:
##   map_atlas.png + map_atlas.json  bütün maneələr (L və S sinfi), kölgə, burulğan,
##                                   dalğa, sıçrantı, qırıntı, döşəmə bəzəyi
##   map_floor.png                   qabın döşəməsi: disk, kənarı şəffaf, sediment
##                                   zolaqları bişmiş
##   map_floor_detail.png            400 dünya px-lik tikişsiz faktura, orta 0.5, boz
##   map_rim.png                     şimal şüşə divarının zolağı, üfüqi tikişsiz
## `build/map_review/atlas_on_floor.png` — atlas döşəmə rənginin üstündə, gözlə
## yoxlamaq üçün.
##
## Niyə Codex-in şəkli birbaşa oyuna girmir: image_gen dairəni hər dəfə bir az
## başqa ölçüdə və yerdə çəkir (V1-də radius 350..390, mərkəz 5 px-ə qədər
## sürüşüb), bloklayan maneənin silueti isə TOQQUŞMA DAİRƏSİNİN ÖZÜDÜR
## (ART_BIBLE §4b). Ona görə hər şəkil dairəsinə oturdulur, maskalanır və
## kontur dəqiq kənarda yenidən çəkilir. Kölgəni də Codex çəkmir: bütün
## bloklayan siluetlər EYNİ dairədir, bir kölgə hüceyrəsi hamısına yarayır və
## işıq istiqaməti burada, `Palette.LIGHT_DIR` ilə eyni qalır.
##
## Bütün rəqəmlər `research/godot_25d_technique.md` §9 və
## `research/design_critique.md` §B–§D-dəndir.

const MASTER := 1024
const HALF := 512.0
## Ayaq izinin (toqquşma dairəsinin) radiusu master-də — `template_v1`.
const FOOT := 384.0

## Ölçü sinifləri. L: R > 60, S: R ≤ 60. Hüceyrə / master = r / 384, yəni
## hüceyrə sadəcə kiçildilmiş master-dir. S-in konturu nisbətən QALINDIR:
## R 34-lük daşda 3.5% R cəmi 1.2 dünya px olardı və kontur itərdi.
const L := {"name": "L", "cell": 512, "r": 192.0, "outline": 0.035}
const S := {"name": "S", "cell": 256, "r": 96.0, "outline": 0.06}

## Maneə konturu — mikrobların #04090B-sindən QƏSDƏN zəif: maneə fon
## obyektidir, oyunçu ilə eyni çəkidə danışmamalıdır.
const OUTLINE := Color("081A20")
const SHADOW := Color("020708")
## Cərəyan burulğanının rəngi — `Palette.VENT`.
const VENT := Color("F0B94E")

## Kölgə (§9.2, V1): maskanın (1.05, 0.80) sıxılmış, (+0.11R, +0.22R)
## sürüşmüş nüsxəsi, nüvədə alfa 0.36, kənar σ 0.06R. Brawl Stars-da kölgə
## pikseli cəmi ×0.75 tündləşir — kölgə hündürlüyü deməlidir, ləkə olmamalıdır.
const SHADOW_CENTER := Vector2(0.11, 0.22)
const SHADOW_RADII := Vector2(1.05, 0.80)
const SHADOW_ALPHA := 0.36
const SHADOW_SIGMA := 0.06
## Təmas kölgəsi (AO): ayaq izinin dərhal xaricində 0.04R-lik nazik halqa.
const AO_WIDTH := 0.04
const AO_ALPHA := 0.28

## Kol tacı ~1.2× böyük çəkilib (MAP_25D §6) — bu əmsal onu ayaq izinə gətirir.
const CANOPY_SCALE := 0.83
## Tacın boş mərkəzi (template_bush: r 134 = 0.35 R) — mərkəzdəki mikrob görünür.
const HOLLOW_R := 134.0

## Atlas düzümü: 2048², 512-lik 16 blok. Hüceyrələr 512/256/128 şəbəkəsinə
## oturur — mip səviyyələrinin 2×2 qutu filtri bir blokun içində qalır və
## qonşu hüceyrəni qarışdırmır.
const PAGE := 2048
const SLOTS := {
	"mucus_blob_L": Vector2i(0, 0), "mucus_bloom_L": Vector2i(512, 0),
	"brittle_s0_L": Vector2i(1024, 0), "brittle_s1_L": Vector2i(1536, 0),
	"brittle_s2_L": Vector2i(0, 512), "brittle_rubble_L": Vector2i(512, 512),
	"bush_base_L": Vector2i(1024, 512), "bush_canopy_L": Vector2i(1536, 512),
	"vent_base_L": Vector2i(0, 1024), "vent_swirl_L": Vector2i(512, 1024),
	"shadow_L": Vector2i(1024, 1024),
	"mucus_blob_S": Vector2i(1536, 1024), "mucus_bloom_S": Vector2i(1792, 1024),
	"brittle_s0_S": Vector2i(1536, 1280), "brittle_s1_S": Vector2i(1792, 1280),
	"brittle_s2_S": Vector2i(0, 1536), "brittle_rubble_S": Vector2i(256, 1536),
	"bush_base_S": Vector2i(0, 1792), "bush_canopy_S": Vector2i(256, 1792),
	"vent_base_S": Vector2i(512, 1536), "vent_swirl_S": Vector2i(768, 1536),
	"shadow_S": Vector2i(512, 1792), "ripple": Vector2i(768, 1792),
	"splash": Vector2i(1024, 1536),
	"debris_0": Vector2i(1280, 1536), "debris_1": Vector2i(1408, 1536),
	"debris_2": Vector2i(1280, 1664), "debris_3": Vector2i(1408, 1664),
	"clutter_0": Vector2i(1536, 1536), "clutter_1": Vector2i(1792, 1536),
	"clutter_2": Vector2i(1536, 1792), "clutter_3": Vector2i(1792, 1792),
}

## Döşəmə: dünyanın radiusu (Const.WORLD_RADIUS) və sediment zolaqları — əvvəl
## `Arena._draw`-da üç `draw_arc` idi, indi teksturaya bişir (−3 çağırış).
const WORLD_R := 1200.0
const GRID := Color("1A3942")

## Döşəmə detalının bir kafeli neçə dünya px-dir (oyunda şeyder bunu işlədir).
const DETAIL_WORLD := 400.0

var _repo := ""
var _cells := {}        ## ad -> Image (hüceyrə ölçüsündə, düz alfa)
var _radius := {}       ## ad -> hüceyrədə nominal radius (tekstel)
var _fail := false


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		printerr("istifadə: -- <repo>")
		quit(2)
		return
	_repo = args[0].replace("\\", "/").trim_suffix("/")
	var t0 := Time.get_ticks_msec()
	var out := _repo + "/game/assets/map/"
	DirAccess.make_dir_recursive_absolute(out)
	DirAccess.make_dir_recursive_absolute(_repo + "/build/map_review")

	_blocking("mucus_blob")
	_blocking("mucus_bloom")
	var shell := _brittle()
	_bush()
	_vent()
	_shadow()
	_ripple_splash()
	_debris(shell)
	_clutter()
	_pack(out)
	_floor(out)
	_detail(out)
	_rim(out)
	_props(out)

	print("[map] hazırdır, %d ms%s" % [Time.get_ticks_msec() - t0,
		" — XƏTA VAR (yuxarıya bax)" if _fail else ""])
	quit(1 if _fail else 0)


# ---------------------------------------------------------------- maneələr

## SELİK: dairəyə oturt, maskala, konturu dəqiq kənarda çək.
func _blocking(name: String) -> void:
	var img := _load("raw/v1/map_v1_%s.png" % name)
	var fit := _disc(img)
	_report(name, fit)
	var m := _place(img, fit["c"], FOOT / float(fit["r"]))
	for cls in [L, S]:
		_put("%s_%s" % [name, cls["name"]], _finish_blocking(_shrink(m, cls), cls),
			cls["r"])


## KÖVRƏK: üç mərhələ + qalıcı qırıntı. Qaytarır: qabığın orta rəngi (qırıntı
## parçaları onunla boyanır).
##
## s1 və s2 s0-ın REDAKTƏSİDİR. image_gen redaktəsi bütün şəkli bir az dəyişir
## (rəng, işıq), ona görə yalnız DƏYİŞƏN yer s0-ın üstünə köçürülür
## ([method _delta]): mərhələ dəyişəndə qabığın toxunulmamış hissəsi yerindən
## oynamır. Hamısına s0-ın oturtması tətbiq olunur — siluet üçündə də eynidir.
func _brittle() -> Color:
	var s0 := _load("raw/v1/map_v1_brittle_s0.png")
	var fit := _disc(s0)
	_report("brittle_s0", fit)
	var stages: Array[Image] = [s0,
		_delta(s0, _load("raw/v1/map_v1_brittle_s1.png"), "brittle_s1"),
		_delta(s0, _load("raw/v1/map_v1_brittle_s2.png"), "brittle_s2")]
	for k in 3:
		var m := _place(stages[k], fit["c"], FOOT / float(fit["r"]))
		for cls in [L, S]:
			_put("brittle_s%d_%s" % [k, cls["name"]], _finish_blocking(_shrink(m, cls), cls),
				cls["r"])

	# Qırıntı yastı, konturu yoxdur və 0.9 R-in içindədir (brif). Alfa ≤ 0.8:
	# döşəmə onun arasından görünməlidir — dağılmış divar artıq keçid YERİDİR.
	var rub := _load("raw/v1/map_v1_brittle_rubble.png")
	var mr := _place(rub, Vector2(HALF, HALF), 1.0)
	for cls in [L, S]:
		var cell := _unpremul_image(_shrink(mr, cls))
		_scale_alpha(cell, 0.8)
		_put("brittle_rubble_" + cls["name"], cell, cls["r"])
	return _mean_color(_cells["brittle_s0_L"], 0.30)


## KOL: yastı baza (mikrobun altında) və boş mərkəzli tac (mikrobun üstündə).
func _bush() -> void:
	var base := _load("raw/v1/map_v1_bush_base.png")
	var fit := _disc(base)
	_report("bush_base", fit, false)
	# Baza 0.95 R-lik döşəkdir; kənarı yumşaq qalır, amma ayaq izindən çıxmır —
	# keçilən sahənin sərhədi gizlənmə sərhədidir.
	var m := _place(base, fit["c"], FOOT * 0.95 / float(fit["r"]))
	for cls in [L, S]:
		var cell := _unpremul_image(_shrink(m, cls))
		_fade_outside(cell, float(cls["r"]) * 0.96, float(cls["r"]))
		_put("bush_base_" + cls["name"], cell, cls["r"])

	# Tac. Ölçü alfa çərçivəsinin mərkəzinə görə kiçildilir (tac halqadır,
	# ağırlıq mərkəzi boş mərkəzə düşür, amma yarpaqlar asimmetrikdir).
	var top := _load("raw/v1/map_v1_bush_canopy.png")
	var box := _alpha_box(top, 128)
	var c := Vector2(box.position) + Vector2(box.size) * 0.5
	var mt := _place(top, c, CANOPY_SCALE)
	var mt_straight := _unpremul_image(mt)
	var hole := _hollow(mt_straight)
	print("[map] bush_canopy: çərçivə %s, kiçildildi %.2f, boş mərkəz (%.0f,%.0f) r %.0f → %.0f" % [
		box, CANOPY_SCALE, hole.x, hole.y, hole.z, maxf(hole.z, HOLLOW_R)])
	# Boş mərkəz ZƏMANƏTLİDİR (critique §B): r 134-dən kiçikdirsə, uclar kəsilir.
	_cut_hole(mt_straight, Vector2(hole.x, hole.y), maxf(hole.z, HOLLOW_R))
	var cover := _coverage(mt_straight, Vector2(hole.x, hole.y), HOLLOW_R)
	print("[map] bush_canopy: boş mərkəzin örtüyü %.1f%% (hədd ≤ 30%%)" % (cover * 100.0))
	if cover > 0.30:
		_error("bush_canopy: boş mərkəz örtülüb")
	mt_straight.premultiply_alpha()
	for cls in [L, S]:
		_put("bush_canopy_" + cls["name"], _unpremul_image(_shrink(mt_straight, cls)), cls["r"])


## CƏRƏYAN: mənfi hündürlüklü dəlik (baza) və onun üstündə fırlanan burulğan.
func _vent() -> void:
	var img := _load("raw/v1/map_v1_vent_base.png")
	var fit := _disc(img)
	_report("vent_base", fit)
	var m := _place(img, fit["c"], FOOT / float(fit["r"]))
	for cls in [L, S]:
		var cell := _unpremul_image(_shrink(m, cls))
		# Kontur yenidən çəkilmir: cərəyanın "konturu" 9 kəhrəba kəsikdir və
		# o, şəklin özündədir. Yalnız ayaq izindən çıxan toz kəsilir.
		_fade_outside(cell, float(cls["r"]) - 0.5, float(cls["r"]) + 0.5)
		_put("vent_base_" + cls["name"], cell, cls["r"])

	# Burulğan fırlanır, ona görə mərkəzi TAM fırlanma oxunda olmalıdır: Codex
	# onu (527,558)-də çəkib — oyunda ~10 ekran px yırğalanardı (MAP_25D §6).
	# Bu nöqtə üç qatlı simmetriya axtarışından gəlir (test 2026-10-02: üst-üstə
	# düşmə 0.910, (512,512)-də 0.418). Alfa ağırlıq mərkəzi (531,554) deyil —
	# qollar eyni çəkilməyib, ağırlıq ən qalın qola tərəf sürüşür.
	var sw := _load("raw/shared/map_shared_vent_swirl.png")
	var centroid := _alpha_centroid(sw, 8)
	print("[map] vent_swirl: oxu (527, 558), alfa mərkəzi (%.1f, %.1f)" % [centroid.x, centroid.y])
	var ms := _unpremul_image(_place(sw, Vector2(527, 558), 0.82))
	_neutral(ms, 8)
	# Rəng atlasa bişirilir (modulate yox): burulğan baza ilə EYNİ batch-də
	# qalsın deyə heç bir sprite-a ayrıca rəng verilmir. Alfa 0.85: köhnə
	# SVG-nin qolları 0.82 idi; 0.72 sınandı və tünd döşəmədə bej oxundu —
	# kəhrəba "cərəyan" dilidir, solğun olsa qayda itir.
	_tint(ms, VENT, 0.85)
	ms.premultiply_alpha()
	for cls in [L, S]:
		_put("vent_swirl_" + cls["name"], _unpremul_image(_shrink(ms, cls)), cls["r"])


## Kölgə + təmas kölgəsi hüceyrəsi (sinif başına bir). Bütün bloklayan siluetlər
## eyni dairədir, ona görə hər maneə bunu öz miqyasında çəkir.
func _shadow() -> void:
	for cls in [L, S]:
		var n: int = cls["cell"]
		var r: float = cls["r"]
		var img := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
		var c := float(n) * 0.5
		for y in n:
			for x in n:
				var p := Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c)
				var q := p / r
				var e := q - SHADOW_CENTER
				var en := (e / SHADOW_RADII).length()
				# İşarəli məsafə R vahidində: ellipsin bu istiqamətdəki radiusu ilə.
				var sd := (en - 1.0) * (e.length() / maxf(en, 0.0001))
				# Normal paylanmanın CDF-i (logistik yaxınlaşma) — bulanıq kənar.
				var sh := SHADOW_ALPHA / (1.0 + exp(1.702 * sd / SHADOW_SIGMA))
				var d := q.length()
				var ao := AO_ALPHA * (1.0 - smoothstep(1.0, 1.0 + AO_WIDTH, d))
				var a := 1.0 - (1.0 - sh) * (1.0 - ao)
				# Hüceyrənin kənar 12 teksteli şəffaf qalır (bilinear və mip üçün).
				var edge := maxf(absf(p.x), absf(p.y))
				a *= 1.0 - smoothstep(c - 20.0, c - 12.0, edge)
				if a > 0.002:
					img.set_pixel(x, y, Color(SHADOW.r, SHADOW.g, SHADOW.b, a))
		_put("shadow_" + cls["name"], img, r)


# ---------------------------------------------------------------- effektlər

## Dalğa halqası və sıçrantı — ağ-boz, oyunda `modulate` ilə boyanır.
func _ripple_splash() -> void:
	var rp := _load("raw/shared/map_shared_ripple.png")
	var crp := _alpha_centroid(rp, 8)
	var mrp := _unpremul_image(_place(rp, crp, 1.0))
	_neutral(mrp, 8)
	mrp.premultiply_alpha()
	_put("ripple", _unpremul_image(_shrink_to(mrp, 256)), _ring_radius(mrp) * 0.25)

	# Sıçrantının mərkəz halqası ~23 px aşağıdadır və r 504-ə çatır (brif 420).
	var sp := _load("raw/shared/map_shared_splash.png")
	var msp := _unpremul_image(_place(sp, Vector2(517, 535), 0.82))
	_neutral(msp, 8)
	msp.premultiply_alpha()
	_put("splash", _unpremul_image(_shrink_to(msp, 256)), 420.0 * 0.82 * 0.25)


## Qabığın qırıntısı — 2×2 vərəqdən dörd parça. Codex parçaları hücrənin
## mərkəzindən 199–238 px-ə qədər çəkib (brif 180): hər biri öz ağırlıq
## mərkəzinə gətirilir və 0.76 kiçildilir. Rəng qabığın öz orta rəngidir —
## sınan qabıq öz materialından qırıntı atmalıdır.
func _debris(shell: Color) -> void:
	var sheet := _load("raw/shared/map_shared_debris.png")
	for k in 4:
		var q := sheet.get_region(Rect2i((k % 2) * 512, (k >> 1) * 512, 512, 512))
		var c := _alpha_centroid(q, 8)
		var m := _unpremul_image(_place_in(q, c, 0.76, 512))
		_neutral(m, 8)
		_multiply(m, shell.lerp(Color.WHITE, 0.35))
		m.premultiply_alpha()
		_put("debris_%d" % k, _unpremul_image(_shrink_to(m, 128)), 180.0 * 0.76 * 0.25)


## Döşəmə bəzəyi — dörd yastı parça (lopa, qırıntı topası, lif, duz dənələri).
## Rəngi döşəmədən cəmi ±0.08 fərqlənir: maneə kimi oxunmamalıdır.
func _clutter() -> void:
	var sheet := _load("raw/v1/map_v1_clutter.png")
	for k in 4:
		var q := sheet.get_region(Rect2i((k % 2) * 512, (k >> 1) * 512, 512, 512))
		var c := _alpha_centroid(q, 8)
		var m := _place_in(q, c, 1.0, 512)
		_put("clutter_%d" % k, _unpremul_image(_shrink_to(m, 256)), 200.0 * 0.5)


# ---------------------------------------------------------------- atlas

func _pack(out: String) -> void:
	var page := Image.create_empty(PAGE, PAGE, false, Image.FORMAT_RGBA8)
	var cells := {}
	for name in SLOTS:
		if not _cells.has(name):
			_error("atlasda hüceyrə yoxdur: " + name)
			continue
		var img: Image = _cells[name]
		var at: Vector2i = SLOTS[name]
		var n := img.get_width()
		page.blit_rect(img, Rect2i(0, 0, n, n), at)
		# Kəsilmiş bölgə: şəffaf künclər rasterləşməsin (qapaq və tacda dolma
		# xərcinin 30–40%-i). Bilinear üçün 2 tekstel ehtiyat saxlanılır.
		var used := _alpha_box(img, 1)
		if used.size.x <= 0:
			_error("boş hüceyrə: " + name)
			continue
		used = used.grow(2).intersection(Rect2i(0, 0, n, n))
		var rect := Rect2i(at + used.position, used.size)
		# Sprite2D `centered` olanda bölgənin mərkəzini node-a qoyur; pivot isə
		# hüceyrənin mərkəzidir (ayaq izinin mərkəzi) — fərq `offset`-dir.
		var off := Vector2(used.position) + Vector2(used.size) * 0.5 - Vector2(n, n) * 0.5
		cells[name] = {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
			"offset": [snappedf(off.x, 0.5), snappedf(off.y, 0.5)],
			"r": snappedf(float(_radius[name]), 0.01), "cell": n}
	page.save_png(out + "map_atlas.png")
	var manifest := {
		"note": "build_map.gd yazır — əllə dəyişmə. rect: səhifədə kəsilmiş bölgə; offset: bölgənin mərkəzi ilə hüceyrənin (ayaq izinin) mərkəzi arasındakı fərq; r: hüceyrədə ayaq izinin (effektdə nominal) radiusu, tekstel.",
		"page": "res://assets/map/map_atlas.png",
		"size": [PAGE, PAGE],
		"detail_world": DETAIL_WORLD,
		"cells": cells,
	}
	var f := FileAccess.open(out + "map_atlas.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t", false) + "\n")
	f.close()

	# Gözlə yoxlamaq üçün: döşəmənin orta rəngi üstündə.
	var review := Image.create_empty(PAGE, PAGE, false, Image.FORMAT_RGBA8)
	review.fill(Color("162D33"))
	review.blend_rect(page, Rect2i(0, 0, PAGE, PAGE), Vector2i.ZERO)
	review.save_png(_repo + "/build/map_review/atlas_on_floor.png")
	print("[map] atlas: %d hüceyrə → %s" % [cells.size(), out + "map_atlas.png"])


# ---------------------------------------------------------------- döşəmə, divar

## Döşəmə: disk kətanın kənarına toxunur (radius 512 tekstel = 1200 dünya px).
## Künclər şəffaf olur — orada qabın bayırı (halqa mesh-i) görünür. Sediment
## zolaqları əvvəlki `Arena._draw` qövsləri ilə EYNİDİR (radius, bucaq, rəng).
func _floor(out: String) -> void:
	var img := _load("raw/v1/map_v1_floor_macro.png")
	var n := img.get_width()
	var k := float(n) * 0.5 / WORLD_R
	var c := float(n) * 0.5
	var bands: Array[Vector3] = []     # (radius, a0, a1) tekstel/radian
	for i in 3:
		var a0 := float(i) * 2.1
		bands.append(Vector3(WORLD_R * (0.35 + 0.22 * float(i)) * k, a0, a0 + PI * 0.85))
	var half_w := 26.0 * k * 0.5
	for y in n:
		for x in n:
			var p := Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c)
			var rho := p.length()
			var cov := clampf(c - rho + 0.5, 0.0, 1.0)
			if cov <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var col := img.get_pixel(x, y)
			var phi := fposmod(p.angle(), TAU)
			for b in bands:
				var along := _arc_inside(phi, b.y, b.z) * rho
				var band := clampf(half_w - absf(rho - b.x) + 0.5, 0.0, 1.0) \
					* clampf(along + 0.5, 0.0, 1.0)
				if band > 0.0:
					col = col.lerp(Color(GRID, 1.0), 0.30 * band)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, cov))
	img.save_png(out + "map_floor.png")
	print("[map] döşəmə: %dx%d, sediment zolaqları bişdi" % [n, n])


## Döşəmə detalı: boz, orta 0.5, ±6%-ə sıxılmış, tikişsiz kafel.
##
## Codex-in kafeli tikişsiz DEYİL (kənar sütunlar təsadüfi sütunlar qədər
## fərqlidir). Yarım sürüşmə kənarları daxili qonşulara çevirir; mərkəzdə
## yaranan xaç tikişi orijinalın öz (tikişsiz) mərkəzi ilə örtülür. Keçid
## zolağında iki faktura HİSTOQRAMI QORUYARAQ qarışdırılır (Heitz–Neyret):
## adi orta götürmə küyün kontrastını √2 dəfə azaldardı və xaç solğun zolaq
## kimi görünərdi.
func _detail(out: String) -> void:
	var img := _load("raw/shared/map_shared_floor_detail.png")
	var n := img.get_width()
	var lum := PackedFloat32Array()
	lum.resize(n * n)
	var mean := 0.0
	for y in n:
		for x in n:
			var p := img.get_pixel(x, y)
			var v := p.r * 0.299 + p.g * 0.587 + p.b * 0.114
			lum[y * n + x] = v
			mean += v
	mean /= float(n * n)
	var h := n >> 1
	var res := Image.create_empty(n, n, false, Image.FORMAT_RGB8)
	var lo := 113.0 / 255.0 - 0.5
	var hi := 143.0 / 255.0 - 0.5
	var clipped := 0
	for y in n:
		for x in n:
			var a := lum[y * n + x] - mean
			var b := lum[((y + h) % n) * n + ((x + h) % n)] - mean
			var dx := absf(float(x) + 0.5 - float(h))
			var dy := absf(float(y) + 0.5 - float(h))
			var wa := maxf(1.0 - smoothstep(16.0, 64.0, dx), 1.0 - smoothstep(16.0, 64.0, dy))
			var wb := 1.0 - wa
			var v := (wa * a + wb * b) / sqrt(wa * wa + wb * wb)
			if v < lo or v > hi:
				clipped += 1
			v = 0.5 + clampf(v, lo, hi)
			res.set_pixel(x, y, Color(v, v, v))
	res.save_png(out + "map_floor_detail.png")
	print("[map] detal: orta %.3f → 0.500, %.2f%% piksel ±6%%-ə sıxıldı" % [
		mean, 100.0 * float(clipped) / float(n * n)])


## Şimal şüşə divarı: maqenta açarın arasından zolağı kəsir, 1024×256-ya
## gətirir və üfüqi tikişsiz edir (qab boyunca ~27 dəfə təkrarlanır).
##
## Tikiş ÜST-ÜSTƏ DÜŞMƏ ilə düzəlir, yarım sürüşmə ilə yox: zolaq 1152 enində
## kiçildilir və son 128 sütun ilk 128-in üstünə yumşaq keçir. Divardakı
## kondensasiya halqaları zolağın ortasındadır — keçid zolağına düşmür və yarı
## silinmiş "xəyal" halqası görünmür (yarım sürüşmədə orta halqa keçidə düşürdü).
## Üfüqi 12.5% dartılma gözə görünmür.
func _rim(out: String) -> void:
	var img := _load("raw/v1/map_v1_rim_north.png")
	var w := img.get_width()
	var h := img.get_height()
	var y0 := -1
	var y1 := -1
	for y in h:
		var keyed := 0
		for x in range(0, w, 8):
			if _is_key(img.get_pixel(x, y)):
				keyed += 1
		if keyed * 8 < (w >> 1):
			if y0 < 0:
				y0 = y
			y1 = y
	if y0 < 0:
		_error("rim: zolaq tapılmadı")
		return
	# Kənardakı 3 sətir açarla qarışıb (maqenta haşiyə) — kəsilir.
	var band := img.get_region(Rect2i(0, y0 + 3, w, y1 - y0 - 5))
	print("[map] rim: zolaq y %d..%d (%d sətir)" % [y0, y1, y1 - y0 + 1])
	band.convert(Image.FORMAT_RGB8)
	var tile := 1024
	var lap := 128
	band.resize(tile + lap, 256, Image.INTERPOLATE_LANCZOS)
	var bh := band.get_height()
	var res := Image.create_empty(tile, bh, false, Image.FORMAT_RGB8)
	for y in bh:
		for x in tile:
			var a := band.get_pixel(x, y)
			if x < lap:
				# x = 0-da sütun 1024-ün (kafelin sağ kənarının davamı) özüdür.
				var t := smoothstep(0.0, float(lap), float(x) + 0.5)
				a = band.get_pixel(x + tile, y).lerp(a, t)
			res.set_pixel(x, y, a)
	res.save_png(out + "map_rim.png")
	print("[map] rim: %dx%d, üfüqi tikişsiz" % [tile, bh])


## Qabın BAYIRINDAKI dekor — fokusdan kənar "başqa koloniyalar" (critique §B:
## "outside props = blurred obstacle masters"). Yalnız maneə şəkillərindən: mikrob
## formalı heç nə yox, çünki bayırdakı mikrob silueti rəqib kimi oxunur (B12).
## Bulanıqlıq kiçilt-böyüt ilə alınır; tündləşmə və alfa şəkilə bişirilir —
## oyunda heç bir sprite-a ayrıca rəng verilmir. 512² səhifə, dörd 256² hüceyrə;
## hüceyrədə diskin radiusu `PROP_R` teksteldir.
const PROP_R := 77.0


func _props(out: String) -> void:
	var page := Image.create_empty(512, 512, false, Image.FORMAT_RGBA8)
	var sources := ["mucus_bloom", "brittle_s0", "bush_canopy", "mucus_blob"]
	for k in sources.size():
		var img := _load("raw/v1/map_v1_%s.png" % sources[k])
		var m: Image
		# Disk hüceyrənin 0.6-sı qədərdir (77 / 128): bulanıqlığa yer qalır, kənar kəsilmir.
		var shrink := PROP_R * 4.0 / FOOT
		if sources[k] == "bush_canopy":
			var box := _alpha_box(img, 128)
			m = _place(img, Vector2(box.position) + Vector2(box.size) * 0.5, CANOPY_SCALE * shrink)
		else:
			var fit := _disc(img)
			m = _place(img, fit["c"], FOOT / float(fit["r"]) * shrink)
		# 1024 → 40 → 256: hər nümunə ~6 tekstellik ləkədir — fokusdan kənar görünüş.
		m.resize(40, 40, Image.INTERPOLATE_LANCZOS)
		m.resize(256, 256, Image.INTERPOLATE_CUBIC)
		var cell := _unpremul_image(m)
		for y in 256:
			for x in 256:
				var p := cell.get_pixel(x, y)
				if p.a <= 0.0:
					continue
				# Qaranlıqda, şüşənin o tayında: rəng yarıya qədər tünd, alfa 0.34.
				cell.set_pixel(x, y, Color(p.r * 0.5, p.g * 0.55, p.b * 0.58, p.a * 0.34))
		cell.fix_alpha_edges()
		page.blit_rect(cell, Rect2i(0, 0, 256, 256), Vector2i((k % 2) * 256, (k >> 1) * 256))
	page.save_png(out + "map_props.png")
	print("[map] bayır dekoru: %d bulanıq koloniya → map_props.png" % sources.size())


# ---------------------------------------------------------------- köməkçilər

func _load(rel: String) -> Image:
	var path := _repo + "/design/map_art/" + rel
	var img := Image.load_from_file(path)
	if img == null or img.is_empty():
		_error("açılmadı: " + path)
		img = Image.create_empty(MASTER, MASTER, false, Image.FORMAT_RGBA8)
	img.convert(Image.FORMAT_RGBA8)
	return img


func _put(name: String, img: Image, radius: float) -> void:
	# Alfa 0-ın altındakı qara RGB bilinear nümunədə kənara tünd haşiyə
	# qatırdı — qonşu rəng ora yayılır (idxalın fix_alpha_border-i ilə eyni iş).
	img.fix_alpha_edges()
	_cells[name] = img
	_radius[name] = radius


func _error(msg: String) -> void:
	printerr("[map] XƏTA: " + msg)
	_fail = true


## [param strict] yalnız bloklayan növlər üçündür: onların silueti toqquşma
## dairəsidir. Kolun bazasının kənarı qəsdən tüklüdür, sapma orada məlumatdır.
func _report(name: String, fit: Dictionary, strict := true) -> void:
	var c: Vector2 = fit["c"]
	print("[map] %s: mərkəz (%.1f, %.1f), r %.1f → 384 (×%.3f), kənarın sapması %.1f%%" % [
		name, c.x, c.y, float(fit["r"]), FOOT / float(fit["r"]), float(fit["resid"]) * 100.0])
	# §9.1: oturtmanın qalığı 2% R-dən çoxdursa şəkil dairə deyil.
	if strict and float(fit["resid"]) > 0.02:
		_error("%s: siluet dairədən %.1f%% sapır (hədd 2%%)" % [name, float(fit["resid"]) * 100.0])


## Alfanın diskini tapır: alfa ≥ 0.5 olan piksellərin ağırlıq mərkəzi, sahədən
## radius və 72 şüa boyunca kənarın bu dairədən ən böyük nisbi sapması.
func _disc(img: Image) -> Dictionary:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var n := 0
	var sx := 0.0
	var sy := 0.0
	var i := 3
	for y in h:
		for x in w:
			if data[i] >= 128:
				n += 1
				sx += float(x)
				sy += float(y)
			i += 4
	if n == 0:
		return {"c": Vector2(w, h) * 0.5, "r": 1.0, "resid": 1.0}
	var c := Vector2(sx / float(n) + 0.5, sy / float(n) + 0.5)
	var r := sqrt(float(n) / PI)
	var worst := 0.0
	for k in 72:
		var dir := Vector2.from_angle(TAU * float(k) / 72.0)
		var s := r * 0.7
		var edge := r * 1.3
		while s < r * 1.3:
			var p := c + dir * s
			var px := int(p.x)
			var py := int(p.y)
			if px < 0 or py < 0 or px >= w or py >= h or data[(py * w + px) * 4 + 3] < 128:
				edge = s
				break
			s += 0.5
		worst = maxf(worst, absf(edge - r) / r)
	return {"c": c, "r": r, "resid": worst}


## Şəkli elə köçürür ki, [param c] nöqtəsi master-in mərkəzinə düşsün və miqyas
## [param s] olsun. Nəticə PREMULTIPLIED alfadadır: Codex PNG-lərində alfa 0-ın
## altında çox vaxt qara RGB durur və düz alfa ilə kiçiltmə onu kənara yayıb
## tünd haşiyə verərdi.
func _place(src: Image, c: Vector2, s: float) -> Image:
	return _place_in(src, c, s, MASTER)


func _place_in(src: Image, c: Vector2, s: float, size: int) -> Image:
	var img := src.duplicate() as Image
	img.premultiply_alpha()
	var nw := maxi(1, int(round(float(img.get_width()) * s)))
	var nh := maxi(1, int(round(float(img.get_height()) * s)))
	if nw != img.get_width() or nh != img.get_height():
		img.resize(nw, nh, Image.INTERPOLATE_LANCZOS)
	var sx := float(nw) / float(src.get_width())
	var sy := float(nh) / float(src.get_height())
	var out := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var off := Vector2(size, size) * 0.5 - Vector2(c.x * sx, c.y * sy)
	var dst := Vector2i(int(round(off.x)), int(round(off.y)))
	var rect := Rect2i(0, 0, nw, nh)
	if dst.x < 0:
		rect.position.x -= dst.x
		rect.size.x += dst.x
		dst.x = 0
	if dst.y < 0:
		rect.position.y -= dst.y
		rect.size.y += dst.y
		dst.y = 0
	rect.size.x = mini(rect.size.x, size - dst.x)
	rect.size.y = mini(rect.size.y, size - dst.y)
	if rect.size.x > 0 and rect.size.y > 0:
		out.blit_rect(img, rect, dst)
	return out


## Master (1024, ayaq izi r 384 mərkəzdə) → hüceyrə. Hüceyrə / master = r / 384,
## yəni bu sadəcə kiçiltmədir (L 0.5, S 0.25). Nəticə hələ premultiplied-dir.
func _shrink(master_pm: Image, cls: Dictionary) -> Image:
	return _shrink_to(master_pm, int(cls["cell"]))


func _shrink_to(img_pm: Image, n: int) -> Image:
	var img := img_pm.duplicate() as Image
	if img.get_width() != n or img.get_height() != n:
		img.resize(n, n, Image.INTERPOLATE_LANCZOS)
	return img


## Bloklayan maneənin son addımı: alfa = ayaq izinin örtüyü (siluet dairənin
## ÖZÜDÜR, Codex-in kənarı deyil), kənar zolağı konturla yenidən çəkilir.
func _finish_blocking(pm: Image, cls: Dictionary) -> Image:
	var n: int = cls["cell"]
	var r: float = cls["r"]
	var band := r * float(cls["outline"])
	var c := float(n) * 0.5
	var out := Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var d := Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
			var cov := clampf(r - d + 0.5, 0.0, 1.0)
			if cov <= 0.0:
				continue
			var col := _unpremul(pm.get_pixel(x, y), OUTLINE)
			var t := clampf(d - (r - band) + 0.5, 0.0, 1.0)
			col = col.lerp(OUTLINE, t)
			out.set_pixel(x, y, Color(col.r, col.g, col.b, cov))
	return out


func _unpremul(p: Color, fallback: Color) -> Color:
	if p.a <= 0.004:
		return fallback
	return Color(minf(p.r / p.a, 1.0), minf(p.g / p.a, 1.0), minf(p.b / p.a, 1.0), 1.0)


## Premultiplied şəkli düz alfaya qaytarır. Alfa 0 olan piksellərin RGB-si
## qonşudan doldurulur (`fix_alpha_edges`) — mip səviyyələrində tünd haşiyə olmasın.
func _unpremul_image(pm: Image) -> Image:
	var img := pm.duplicate() as Image
	var n := img.get_width()
	var m := img.get_height()
	for y in m:
		for x in n:
			var p := img.get_pixel(x, y)
			if p.a <= 0.004:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var c := _unpremul(p, Color.BLACK)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, p.a))
	img.fix_alpha_edges()
	return img


## Mərkəzdən [param r0]..[param r1] tekstel arasında alfanı yumşaq sıfıra endirir.
func _fade_outside(img: Image, r0: float, r1: float) -> void:
	var n := img.get_width()
	var c := float(n) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
			if d <= r0:
				continue
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			p.a *= 1.0 - smoothstep(r0, r1, d)
			img.set_pixel(x, y, p)


func _scale_alpha(img: Image, k: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a > 0.0:
				p.a *= k
				img.set_pixel(x, y, p)


## Boz (R = G = B = parlaqlıq) və alfa < [param min_a]/255 → 0. Ortaq assetlərdə
## image_gen yarımşəffaf kənarlarda rəng izi qoyub (spread8 51–57) və hər yerə
## alfa 1–7 tozu səpib — oyunda boyananda ikisi də görünərdi.
func _neutral(img: Image, min_a: int) -> void:
	var lim := float(min_a) / 255.0
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a < lim:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var v := p.r * 0.299 + p.g * 0.587 + p.b * 0.114
			img.set_pixel(x, y, Color(v, v, v, p.a))


## Boz şəkli rənglə boyayır: parlaqlıq rəngin dəyərinə vurulur, alfa × [param k].
func _tint(img: Image, col: Color, k: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			# Ağ nüvə rəngin bir az açıq tonuna çıxır, boz kənar rəngin özüdür,
			# tünd boz isə tündləşir — qolun həcmi qalır, rəng doymuş qalır.
			var v := p.r
			var c := col.lerp(Color.WHITE, clampf((v - 0.85) * 1.5, 0.0, 0.2)) \
				* clampf(0.55 + v * 0.5, 0.0, 1.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, p.a * k))


func _multiply(img: Image, col: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			img.set_pixel(x, y, Color(p.r * col.r, p.g * col.g, p.b * col.b, p.a))


## Alfa ≥ [param thr]/255 olan piksellərin çərçivəsi.
func _alpha_box(img: Image, thr: int) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	var i := 3
	for y in h:
		for x in w:
			if data[i] >= thr:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
				y0 = mini(y0, y)
				y1 = maxi(y1, y)
			i += 4
	if x1 < 0:
		return Rect2i()
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)


## Alfa ilə çəkilmiş ağırlıq mərkəzi (alfa < [param thr]/255 toz sayılmır).
func _alpha_centroid(img: Image, thr: int) -> Vector2:
	var w := img.get_width()
	var h := img.get_height()
	var data := img.get_data()
	var sw := 0.0
	var sx := 0.0
	var sy := 0.0
	var i := 3
	for y in h:
		for x in w:
			var a := data[i]
			if a >= thr:
				sw += float(a)
				sx += float(a) * (float(x) + 0.5)
				sy += float(a) * (float(y) + 0.5)
			i += 4
	if sw <= 0.0:
		return Vector2(w, h) * 0.5
	return Vector2(sx / sw, sy / sw)


## Halqanın radiusu: alfa ≥ 0.5 olan piksellərin mərkəzdən orta məsafəsi.
func _ring_radius(img: Image) -> float:
	var n := img.get_width()
	var c := float(n) * 0.5
	var s := 0.0
	var k := 0
	for y in range(0, n, 2):
		for x in range(0, n, 2):
			if img.get_pixel(x, y).a >= 0.5:
				s += Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length()
				k += 1
	return s / float(maxi(k, 1))


## Tacın boş mərkəzi: alfa < 0.5 olan sahənin içinə çəkilə bilən ən böyük
## dairə (256²-də iki keçidli chamfer məsafə çevirməsi). Qaytarır (x, y, r) master-də.
func _hollow(img: Image) -> Vector3:
	var n := 256
	var k := float(img.get_width()) / float(n)
	var small := img.duplicate() as Image
	small.resize(n, n, Image.INTERPOLATE_BILINEAR)
	var big := 1.0e6
	var dist := PackedFloat32Array()
	dist.resize(n * n)
	for y in n:
		for x in n:
			dist[y * n + x] = 0.0 if small.get_pixel(x, y).a >= 0.5 else big
	var d1 := 1.0
	var d2 := 1.4142
	for y in n:
		for x in n:
			var i := y * n + x
			var v := dist[i]
			if v == 0.0:
				continue
			if x > 0: v = minf(v, dist[i - 1] + d1)
			if y > 0:
				v = minf(v, dist[i - n] + d1)
				if x > 0: v = minf(v, dist[i - n - 1] + d2)
				if x < n - 1: v = minf(v, dist[i - n + 1] + d2)
			dist[i] = v
	for y in range(n - 1, -1, -1):
		for x in range(n - 1, -1, -1):
			var i := y * n + x
			var v := dist[i]
			if v == 0.0:
				continue
			if x < n - 1: v = minf(v, dist[i + 1] + d1)
			if y < n - 1:
				v = minf(v, dist[i + n] + d1)
				if x < n - 1: v = minf(v, dist[i + n + 1] + d2)
				if x > 0: v = minf(v, dist[i + n - 1] + d2)
			dist[i] = v
	# Yalnız mərkəzə yaxın axtarılır — tacın bayırı da "boşdur".
	var best := Vector3(HALF, HALF, 0.0)
	var cs := float(n) * 0.5
	for y in n:
		for x in n:
			if Vector2(float(x) + 0.5 - cs, float(y) + 0.5 - cs).length() > 90.0 / k:
				continue
			var v := dist[y * n + x]
			if v < big and v > best.z:
				best = Vector3((float(x) + 0.5) * k, (float(y) + 0.5) * k, v)
	best.z *= k
	return best


## Boş mərkəzi zəmanətləyir: [param r]-in içində alfa yumşaq sıfıra enir.
func _cut_hole(img: Image, at: Vector2, r: float) -> void:
	var n := img.get_width()
	for y in n:
		for x in n:
			var d := Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(at)
			if d >= r + 12.0:
				continue
			var p := img.get_pixel(x, y)
			if p.a <= 0.0:
				continue
			p.a *= smoothstep(r - 12.0, r + 12.0, d)
			img.set_pixel(x, y, p)


## Dairənin içində orta alfa (0..1).
func _coverage(img: Image, at: Vector2, r: float) -> float:
	var s := 0.0
	var k := 0
	var n := img.get_width()
	for y in n:
		for x in n:
			if Vector2(float(x) + 0.5, float(y) + 0.5).distance_to(at) <= r:
				s += img.get_pixel(x, y).a
				k += 1
	return s / float(maxi(k, 1))


## Mərhələ redaktəsinin DƏYİŞƏN yerini s0-ın üstünə köçürür (critique §B.4).
##   1. |sN − s0|-ın hər kanalda ən böyüyü 24/255-dən çox olan piksellər;
##   2. 8×8 bloklara yığılır, bir blok genişləndirilir;
##   3. bilinear böyüdülür — ~8 px yumşaq keçid;
##   4. yalnız bu bölgə köçürülür, alfa s0-ındır.
## Toxunulmamış sahədə orta rəng sürüşməsi 2%-dən çoxdursa xəbərdarlıq.
func _delta(base: Image, edit: Image, label: String) -> Image:
	var w := base.get_width()
	var h := base.get_height()
	if edit.get_width() != w or edit.get_height() != h:
		_error("%s: ölçü s0 ilə eyni deyil" % label)
		return base
	var bd := base.get_data()
	var ed := edit.get_data()
	var bw := w >> 3
	var bh := h >> 3
	var flag := PackedByteArray()
	flag.resize(bw * bh)
	var i := 0
	for y in h:
		for x in w:
			if bd[i + 3] >= 128:
				var dmax := maxi(absi(bd[i] - ed[i]), maxi(absi(bd[i + 1] - ed[i + 1]),
					absi(bd[i + 2] - ed[i + 2])))
				if dmax > 24:
					flag[(y >> 3) * bw + (x >> 3)] = 1
			i += 4
	var mask := Image.create_empty(bw, bh, false, Image.FORMAT_L8)
	var touched := 0
	for by in bh:
		for bx in bw:
			var on := false
			for oy in range(-1, 2):
				for ox in range(-1, 2):
					var xx := bx + ox
					var yy := by + oy
					if xx >= 0 and yy >= 0 and xx < bw and yy < bh and flag[yy * bw + xx] == 1:
						on = true
			if on:
				mask.set_pixel(bx, by, Color(1, 1, 1))
				touched += 1
	mask.resize(w, h, Image.INTERPOLATE_BILINEAR)
	var out := base.duplicate() as Image
	var drift := 0.0
	var drift_n := 0
	for y in h:
		for x in w:
			var b := base.get_pixel(x, y)
			if b.a <= 0.0:
				continue
			var m := mask.get_pixel(x, y).r
			var e := edit.get_pixel(x, y)
			if m <= 0.001:
				if b.a >= 0.5:
					drift += (absf(b.r - e.r) + absf(b.g - e.g) + absf(b.b - e.b)) / 3.0
					drift_n += 1
				continue
			var c := Color(b.r, b.g, b.b).lerp(Color(e.r, e.g, e.b), m)
			out.set_pixel(x, y, Color(c.r, c.g, c.b, b.a))
	var mean_drift := drift / float(maxi(drift_n, 1))
	print("[map] %s: dəyişən yer %.1f%% (8×8 bloklar), toxunulmamış sahədə orta sürüşmə %.2f%%" % [
		label, 100.0 * float(touched) / float(bw * bh), mean_drift * 100.0])
	if mean_drift > 0.02:
		print("[map] %s: XƏBƏRDARLIQ — redaktə şəkli 2%%-dən çox sürüşdürüb, kompozit onu gizlədir" % label)
	return out


## Qapağın orta rəngi (alfa = 1 olan, mərkəzdən [param inner] R-ə qədər pikselər).
func _mean_color(img: Image, inner: float) -> Color:
	var n := img.get_width()
	var c := float(n) * 0.5
	var r := float(L["r"]) * inner
	var s := Color(0, 0, 0)
	var k := 0
	for y in n:
		for x in n:
			if Vector2(float(x) + 0.5 - c, float(y) + 0.5 - c).length() > r:
				continue
			var p := img.get_pixel(x, y)
			s.r += p.r
			s.g += p.g
			s.b += p.b
			k += 1
	return Color(s.r / k, s.g / k, s.b / k)


## Açar rəngi (#FF00FF): yaxın maqenta.
func _is_key(p: Color) -> bool:
	return p.r > 0.75 and p.b > 0.75 and p.g < 0.35


## Bucaq [param phi] [a0, a1] qövsünün içindədirsə qövs boyu kənara qədər
## məsafə (radian), xaricindədirsə mənfi.
func _arc_inside(phi: float, a0: float, a1: float) -> float:
	var span := a1 - a0
	var rel := fposmod(phi - a0, TAU)
	if rel <= span:
		return minf(rel, span - rel)
	return -minf(rel - span, TAU - rel)
