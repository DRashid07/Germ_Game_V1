class_name DishMap
extends RefCounted
## Petri qabının statik maneə düzümü.
##
## Maneə: `Vector4(x, y, radius, kind)`.
##
## ── Niyə Vector4, niyə Dictionary yox ────────────────────────────────────
## Bu siyahı SIX yoldadır: hər tick-də hər mikrob üçün tam gəzilir
## ([method Sim._confine]), hər top üçün bir daha. `Vector4` dəyər tipidir —
## nə ayırma var, nə dolayı müraciət, nə də zibil yığımı. Dictionary və ya
## obyekt siyahısı eyni işi 10 mikrob × 60 tick-də minlərlə əlavə müraciətlə
## edərdi.
##
## Dördüncü sahə (`w`) maneənin NÖVÜDÜR. Növ maneənin oyun qaydasını təyin
## edir, yalnız görünüşünü yox — ona görə burada, PAYLAŞILAN koddadır: client
## proqnozu ilə server eyni qaydanı icra etməlidir, əks halda mikrob client-də
## keçdiyi yerdən serverdə keçə bilməz və düzəliş onu geri sıçradar.
##
## Dairə seçilib, çünki mikrob dünyasında düz künc yoxdur və dairə-dairə
## toqquşması ən ucuz testdir.

## Maneə növləri.
##
## Hər növ ÜÇ suala fərqli cavab verir: mikrobu buraxırmı, topu buraxırmı,
## görünməyə təsir edirmi. Dördü də bir-birindən ən azı iki cavabla fərqlənir,
## yəni heç biri başqasının təkrarı deyil.
enum Kind {
	## Selik ləkəsi — mikrobu bloklayır, topu sıçradır. Köhnə (yeganə) davranış.
	MUCUS = 0,
	## Selik kolu — mikrob da, top da KEÇİR. İçindəki mikrob GİZLİDİR:
	## server onu başqalarına göndərmir (bax [method World.snapshot_for]).
	BUSH = 1,
	## Kövrək qabıq — bloklayır, amma topla SINIR. Sındırılan yol bərpa
	## olunmur: dünya oyun getdikcə AÇILIR.
	BRITTLE = 2,
	## Cərəyan deşiyi — hər şey keçir, içindən keçən mikrob MƏRKƏZƏ doğru
	## güclü itələnir (bax [method Sim._vent_push]).
	VENT = 3,
}

## Divar baytının bitləri.
##
## Bayt hər snapshot ilə tam gedir (maneə başına bir bayt) və əvvəl yalnız
## 0/1 daşıyırdı — yəni yeddi biti boş yatırdı. Qabığın neçə zərbə yediyi
## oraya girir və şəbəkəyə SIFIR bayt əlavə olunur. Eyni üsul növ və superin
## doluluğu üçün də işlədilib (bax [enum Const.GFlag]).
##
##   bit 0    → maneə dağılıb
##   bit 1-2  → neçə zərbə yeyib (0..3)
##
## Sayğac oyunçuya LAZIMDIR: qabıq üç zərbədən sonra dağılır, amma sprite
## heç vaxt dəyişmirdi — oyunçu neçə zərbə qaldığını bilmirdi və qabığı
## yarıda qoyub gedirdi.
enum Wall { GONE = 1, HITS_SHIFT = 1, HITS_MASK = 6 }


## Maneə dağılıbmı?
static func wall_gone(b: int) -> bool:
	return (b & Wall.GONE) != 0


## Maneə neçə zərbə yeyib (0..3)?
static func wall_hits(b: int) -> int:
	return (b & Wall.HITS_MASK) >> Wall.HITS_SHIFT

## Kövrək qabıq neçə zərbədən sonra dağılır.
##
## 3 seçilib: bir zərbə təsadüf olardı, beş isə çox uzundur — atəş dövrü
## saniyədə birdir, yəni beş zərbə beş saniyə deməkdir və oyunçu qabığı
## yarıda qoyub gedərdi.
const BRITTLE_HP := 3


## Mikrobu bloklayırmı?
static func blocks_germ(kind: int) -> bool:
	return kind == Kind.MUCUS or kind == Kind.BRITTLE


## Topu dayandırırmı? (MUCUS sıçradır, BRITTLE sınır — ikisi də "dayandırır")
static func blocks_shot(kind: int) -> bool:
	return kind == Kind.MUCUS or kind == Kind.BRITTLE


## Görüşü kəsirmi? Bot hədəf seçəndə istifadə olunur
## ([method Sim.has_line_of_sight]).
##
## Kol da kəsir, baxmayaraq ki top ondan KEÇİR: kolun içindəki mikrob
## görünmür, deməli bot onu hədəf seçə bilməməlidir. Görünmək və toqquşmaq
## iki AYRI sualdır — bu, məhz onların ayrıldığı yerdir.
static func blocks_sight(kind: int) -> bool:
	return kind != Kind.VENT


## Burada mikrob DOĞULA bilərmi?
##
## Kol istisnadır: kolun içində doğulmaq düzgündür, hətta xoşdur — yeni gələn
## gizli başlayır. Cərəyan deşiyi isə yox: doğulan kimi atılmaq pis təcrübədir.
static func blocks_spawn(kind: int) -> bool:
	return kind != Kind.BUSH


## Hansı düzüm işlədilir. 0 = indiki (halqalar).
##
## Dəyişmək HƏM client-i, HƏM serveri eyni anda dəyişməlidir — düzüm toqquşma
## həndəsəsidir, yalnız bəzək deyil. Ona görə burada, paylaşılan kodda durur.
static var layout := 0

static var _cache: Array[Vector4] = []
static var _cached_layout := -1


static func layout_name(which: int) -> String:
	match which:
		1:
			return "ARXİPELAQ"
		2:
			return "SPİRAL QOLLAR"
		_:
			return "HALQALAR (indiki)"


static func kind_name(kind: int) -> String:
	match kind:
		Kind.BUSH:
			return "KOL"
		Kind.BRITTLE:
			return "KÖVRƏK"
		Kind.VENT:
			return "CƏRƏYAN"
		_:
			return "SELİK"


static func obstacles() -> Array[Vector4]:
	if not _cache.is_empty() and _cached_layout == layout:
		return _cache
	var out: Array[Vector4] = []
	match layout:
		1:
			_build_islands(out)
		2:
			_build_arms(out)
		_:
			_build_rings(out)
	_cache = out
	_cached_layout = layout
	return _cache


## 0 — HALQALAR: üç konsentrik halqa, hər halqanın öz XARAKTERİ var.
##
## Halqaların özü simmetrikdir, amma növlər halqa boyunca NÖVBƏLƏŞİR, ona görə
## iki qonşu sektor eyni görünmür: birində gizlənirsən, o birində divar
## sındırırsan. Oriyentir problemi belə həll olunur — düzüm yox, MƏZMUN
## fərqləndirir.
##
## Xarici halqada cərəyan deşikləri var: kənara sıxışdırılan oyunçuya mərkəzə
## qayıtmaq üçün bir yol qalır.
static func _build_rings(out: Array[Vector4]) -> void:
	out.append(Vector4(0.0, 0.0, 120.0, float(Kind.MUCUS)))
	_ring(out, 5, 400.0, 78.0, 0.0, [Kind.MUCUS, Kind.BUSH])
	_ring(out, 7, 760.0, 96.0, PI / 7.0, [Kind.MUCUS, Kind.BRITTLE, Kind.BUSH])
	_ring(out, 9, 1045.0, 58.0, PI / 9.0, [Kind.MUCUS, Kind.MUCUS, Kind.VENT])

	# İri kollar halqadan KƏNARDA durur. Halqaya salınsalar simmetrik
	# düzülərdilər və "gizlənəcək yer" oriyentir olmaqdan çıxardı: hər
	# istiqamətdə eyni məsafədə eyni kol.
	_add_bush(out, Vector2(-190.0, 610.0), 132.0)
	_add_bush(out, Vector2(575.0, -330.0), 118.0)
	_add_bush(out, Vector2(-620.0, -215.0), 104.0)
	_add_bush(out, Vector2(240.0, 300.0), 92.0)


## Kol əlavə edir və ÜST-ÜSTƏ DÜŞMƏMƏSİNİ təmin edir.
##
## Örtüşən iki kol oyunun izah edilə bilməyən halını yaradır: örtüşən sahədə
## duran iki oyunçu FƏRQLİ kol indeksinə düşüb bir-birini görməz — yan-yana
## durub bir-birindən gizli ([method Sim.bush_of] tapdığı İLK kolu qaytarır,
## [method World._near_germs] isə indeksləri müqayisə edir).
##
## Qayda MƏNBƏDƏ saxlanılır, sənəddə yox: kol əl ilə qoyulan koordinatdadır
## və koordinat sonradan dəyişəndə qeyd oxunmur, kod isə işləyir. Kol
## örtüşmə istiqamətində sıxışdırılır — nəticə deterministikdir, yəni
## client və server eyni xəritəni qurur.
##
## Qoruyucu: `SimTest._test_map_layouts`.
static func _add_bush(out: Array[Vector4], at: Vector2, radius: float) -> void:
	var p := at
	for _step in 24:
		var worst := 0.0
		var away := Vector2.RIGHT
		for o in out:
			if int(o.w) != Kind.BUSH:
				continue
			var c := Vector2(o.x, o.y)
			var d := p.distance_to(c)
			var gap := d - o.z - radius
			if gap < worst:
				worst = gap
				away = (p - c) / d if d > 0.001 else Vector2.RIGHT
		if worst >= 0.0:
			break
		p += away * (-worst + 6.0)
	out.append(Vector4(p.x, p.y, radius, float(Kind.BUSH)))


## 1 — ARXİPELAQ: qeyri-simmetrik adalar, hər biri ətrafında xırda daşlarla.
##
## Hər ada AYRICA yerdir: ölçüsü və ətrafındakı daşların sayı fərqlidir, ona
## görə oyunçu "böyük adanın yanındayam" deyə bilir. Aralarda geniş dəhlizlər
## qalır — qovhaqov üçün.
static func _build_islands(out: Array[Vector4]) -> void:
	# Mərkəz ən böyükdür: dünyanın sabit oriyentiri olaraq qalır.
	_island(out, Vector2(0.0, 0.0), 150.0, 4)
	_island(out, Vector2(-520.0, -190.0), 118.0, 3)
	_island(out, Vector2(430.0, -560.0), 96.0, 2)
	_island(out, Vector2(690.0, 300.0), 132.0, 4)
	_island(out, Vector2(-250.0, 620.0), 104.0, 3)
	_island(out, Vector2(-830.0, 400.0), 88.0, 2)
	_island(out, Vector2(180.0, 880.0), 92.0, 3)
	_island(out, Vector2(-880.0, -520.0), 110.0, 3)
	_island(out, Vector2(870.0, -640.0), 84.0, 2)
	# QEYD: əvvəl (950, 620) idi və ada qabın kənarından 12 px ÇIXIRDI
	# (1134 + 78 > 1200). `SimTest._test_map_layouts` tapdı.
	_island(out, Vector2(905.0, 590.0), 78.0, 2)


## Bir ada: mərkəzi ləkə və ətrafına səpilmiş xırda daşlar.
## Bucaqlar qızıl nisbətlə paylanır — heç bir cüt üst-üstə düşmür.
##
## Daşların arasında bir KOL olur: adanın ətrafı təkcə maneə deyil, həm də
## gizlənəcək yerdir, yəni adaya yaxınlaşmaq risklidir.
static func _island(out: Array[Vector4], at: Vector2, big: float,
		pebbles: int) -> void:
	out.append(Vector4(at.x, at.y, big, float(Kind.MUCUS)))
	for i in pebbles:
		var a := TAU * fposmod(float(i) * 0.618034 + at.x * 0.0013, 1.0)
		var d := big + 74.0 + float(i % 3) * 26.0
		var p := at + Vector2.from_angle(a) * d
		if p.length() > Const.WORLD_RADIUS - 90.0:
			continue
		var kind := Kind.BUSH if i == 1 else Kind.MUCUS
		out.append(Vector4(p.x, p.y, 34.0 + float(i % 3) * 9.0, float(kind)))


## 2 — SPİRAL QOLLAR: üç qol mərkəzdən kənara burulur.
##
## Qollar əyri dəhlizlər yaradır: oyunçu qolu izləyərək mərkəzə və ya kənara
## çıxa bilir, yəni xəritə özü istiqamət verir. Qabdakı burulğan axını ilə də
## eyni dildə danışır (bax [method Const.current_at]).
##
## Qolun ucundakı ləkələr KÖVRƏKDİR: qolu sındırıb kəsmə yol açmaq olur, yəni
## düzüm oyun getdikcə dəyişir.
static func _build_arms(out: Array[Vector4]) -> void:
	out.append(Vector4(0.0, 0.0, 145.0, float(Kind.MUCUS)))
	for arm in 3:
		var phase := TAU * float(arm) / 3.0
		for i in 7:
			var t := float(i) / 6.0
			var a := phase + t * 2.3
			var d := 260.0 + t * 830.0
			var p := Vector2.from_angle(a) * d
			# Qolun ucu nazilir: içəridə iri sığınacaq, kənarda xırda daşlar.
			# Uc hissə kövrəkdir — qolu kəsmək məhz oradan mümkündür.
			var kind := Kind.BRITTLE if t > 0.6 else Kind.MUCUS
			out.append(Vector4(p.x, p.y, 118.0 - t * 68.0, float(kind)))
			# Hər ikinci ləkənin yanına bir yoldaş — qol düz sıra görünməsin,
			# ətrafında gizlənmək olsun. Bunlar KOLDUR: qolun kənarı boyunca
			# pusqu zolağı yaranır.
			if i % 2 == 1:
				var side := p + Vector2.from_angle(a + PI * 0.5) * (150.0 - t * 40.0)
				if side.length() < Const.WORLD_RADIUS - 80.0:
					out.append(Vector4(side.x, side.y, 44.0 - t * 12.0,
						float(Kind.BUSH)))


## Bir halqa. Növlər halqa boyunca NÖVBƏLƏŞİR — bax [method _build_rings].
static func _ring(out: Array[Vector4], count: int, dist: float, radius: float,
		phase: float, kinds: Array) -> void:
	for i in count:
		var a := TAU * float(i) / float(count) + phase
		out.append(Vector4(cos(a) * dist, sin(a) * dist, radius,
			float(kinds[i % kinds.size()])))


## Verilmiş nöqtədə bu radiusda mikrob dayana bilərmi?
## Doğuş yeri seçəndə istifadə olunur — heç kim maneənin içində doğulmamalıdır.
static func is_free(pos: Vector2, radius: float) -> bool:
	if pos.length() > Const.WORLD_RADIUS - radius:
		return false
	for o in obstacles():
		if not blocks_spawn(int(o.w)):
			continue
		if pos.distance_squared_to(Vector2(o.x, o.y)) < pow(o.z + radius, 2.0):
			return false
	return true
