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
	## ANA HÜCEYRƏ — komandanın bazası (yalnız [constant Const.LAYOUT_MOTHER]).
	## Selik kimi bloklayır, amma RƏQİBİN topu sıçramır, Anaya +2 kimi girir
	## (bax [method Sim._step_shots]). Kimin Anası olduğu yerindən çıxır: qərbdəki
	## komanda 0-ındır.
	MOTHER = 4,
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
	return kind == Kind.MUCUS or kind == Kind.BRITTLE or kind == Kind.MOTHER


## Topu dayandırırmı? (MUCUS sıçradır, BRITTLE sınır, MOTHER udur və ya sıçradır —
## hamısı "dayandırır")
static func blocks_shot(kind: int) -> bool:
	return kind == Kind.MUCUS or kind == Kind.BRITTLE or kind == Kind.MOTHER


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


## Qabın MƏRKƏZİ bloklayan maneədən AZAD qalmalıdır — bu radiusda.
##
## Səbəb quruyan qabdır. TƏK QALAN və CÜT-də yaş radius matçın sonunda
## [constant Const.SOLO_MIN_RADIUS]-ə (90 px) düşür: həmin an oyun sahəsi
## qabın mərkəzindəki KİÇİK dairədir. Orada bərk maneə dursa, sağ qalanların
## hamısı eyni anda quru zonaya sıxılır və döyüşmədən, dolub partlayır —
## yəni rejimin bütün son mərhələsi işləmir. Ölçülüb: CÜT matçının 217-ci
## saniyəsində kəhrəba halqanın İÇİ tamamilə mavi şüşə idi.
##
## Üç düzümün üçündə də mərkəzdə iri ləkə var və o, lazımdır — dünyanın sabit
## oriyentiridir. Ona görə ləkə QALIR, sadəcə KOL olur: görünür, gizlədir,
## görüşü kəsir, amma bloklamır. Son döyüş kolun içində gedir.
##
## Qoruyucu: `SimTest._test_arena_core_is_free`.
const CORE_CLEAR := 100.0


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
		Kind.MOTHER:
			return "ANA"
		_:
			return "SELİK"


## Rejimin öz düzümünün siyahısı (bax [method Const.mode_layout]).
##
## Ümumi [method obstacles]-dən AYRI keşdədir: server eyni prosesdə bir neçə rejimin
## dünyasını aparır, statik [member layout] isə hamısı üçün bir dəyərdir — ona görə
## rejim düzümü qlobal dəyişənə toxunmur. -1 ümumi düzümü qaytarır.
static var _by_layout := {}


static func obstacles_for(which: int) -> Array[Vector4]:
	if which < 0:
		return obstacles()
	if _by_layout.has(which):
		return _by_layout[which]
	var out: Array[Vector4] = []
	match which:
		Const.LAYOUT_MOTHER:
			_build_mother(out)
		Const.LAYOUT_ISLAND:
			_build_island_mode(out)
		Const.LAYOUT_BALL:
			_build_ball(out)
		_:
			return obstacles()
	_by_layout[which] = out
	return out


## ANA HÜCEYRƏ — iki yuva və aralarında açıq meydan (design/MODES.md §16.2).
##
## Yuva Ananı üç tərəfdən örtür: önündə tıxac, yanlarında iki selik. Aralarındakı
## iki ağız 87 px-dir — hücum məhz oradan gəlir. Yan seliklə şüşə arasında 50 px qalır:
## ARXA QAPI, yalnız amöb (tutum ≤ 13) sığır. Ana ilə şüşə arasında da 50 px — Ananın
## arxası yuvanın içidir. Meydanda yalnız iki dirək (orta xətti kəsir), dörd kol
## (cinahda pusqu) və iki cərəyan deşiyi (doğulandan sonra meydana tez qayıtmaq üçün).
## Kövrək qabıq yoxdur: hər şey matçın ilk saniyəsindən oxunmalıdır.
static func _build_mother(out: Array[Vector4]) -> void:
	for side in [-1.0, 1.0]:
		var s: float = side
		out.append(Vector4(s * Const.MOTHER_X, 0.0, Const.MOTHER_RADIUS, float(Kind.MOTHER)))
		out.append(Vector4(s * 420.0, 0.0, 72.0, float(Kind.MUCUS)))
		out.append(Vector4(s * 480.0, -215.0, 64.0, float(Kind.MUCUS)))
		out.append(Vector4(s * 480.0, 215.0, 64.0, float(Kind.MUCUS)))
		out.append(Vector4(s * 590.0, -328.0, 75.0, float(Kind.MUCUS)))
		out.append(Vector4(s * 590.0, 328.0, 75.0, float(Kind.MUCUS)))
	out.append(Vector4(0.0, -190.0, 62.0, float(Kind.MUCUS)))
	out.append(Vector4(0.0, 190.0, 62.0, float(Kind.MUCUS)))
	for p in [Vector2(-230.0, -430.0), Vector2(230.0, -430.0),
			Vector2(-230.0, 430.0), Vector2(230.0, 430.0)]:
		out.append(Vector4(p.x, p.y, 85.0, float(Kind.BUSH)))
	out.append(Vector4(0.0, -640.0, 55.0, float(Kind.VENT)))
	out.append(Vector4(0.0, 640.0, 55.0, float(Kind.VENT)))


## YAŞ ADA — adanın yolu boş qalır (design/MODES.md §16.3).
##
## Ada orta xətt boyunca şimal–cənub yırğalanır ([method Const.island_center]) və onun
## zolağında (|x| ≤ 220) heç nə yoxdur. Dörd dirək zolağın yanlarında: adaya gedən yolda
## sığınacaq verir, amma adanın içinə düşmür. Dörd kol bazaların yanında, quruda —
## dolarkən gizlənmək üçün. Cərəyan deşikləri bazaların önündədir: doğulan mikrobu
## mərkəzə, adanın yoluna atır (katapult).
static func _build_island_mode(out: Array[Vector4]) -> void:
	for p in [Vector2(-320.0, -240.0), Vector2(320.0, -240.0),
			Vector2(-320.0, 240.0), Vector2(320.0, 240.0)]:
		out.append(Vector4(p.x, p.y, 62.0, float(Kind.MUCUS)))
	for p in [Vector2(-520.0, -330.0), Vector2(520.0, -330.0),
			Vector2(-520.0, 330.0), Vector2(520.0, 330.0)]:
		out.append(Vector4(p.x, p.y, 75.0, float(Kind.BUSH)))
	out.append(Vector4(-470.0, 0.0, 55.0, float(Kind.VENT)))
	out.append(Vector4(470.0, 0.0, 55.0, float(Kind.VENT)))


## NÜVƏ TOPU — iki qapı, dörd dirək və dörd bamper (design/MODES.md §16.4).
##
## Dirəklər qapının iki yanında şüşəyə toxunur: Nüvə dirəkdən səkib qapıya girə bilər.
## Bamperlər meydanın ortasındadır — top və Nüvə üçün sıçrayış bucağı. İki kol
## cinahdadır. Deşik və kövrək yoxdur: Nüvənin yolu oyunçunun əlində olmalıdır.
static func _build_ball(out: Array[Vector4]) -> void:
	for side in [-1.0, 1.0]:
		var s: float = side
		out.append(Vector4(s * 585.0, -150.0, 30.0, float(Kind.MUCUS)))
		out.append(Vector4(s * 585.0, 150.0, 30.0, float(Kind.MUCUS)))
	for p in [Vector2(-250.0, -235.0), Vector2(250.0, -235.0),
			Vector2(-250.0, 235.0), Vector2(250.0, 235.0)]:
		out.append(Vector4(p.x, p.y, 52.0, float(Kind.MUCUS)))
	out.append(Vector4(0.0, -410.0, 88.0, float(Kind.BUSH)))
	out.append(Vector4(0.0, 410.0, 88.0, float(Kind.BUSH)))


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
	# Mərkəz KOLDUR, bərk ləkə deyil — bax [constant CORE_CLEAR].
	out.append(Vector4(0.0, 0.0, 120.0, float(Kind.BUSH)))
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
	# Gövdəsi KOLDUR — bax [constant CORE_CLEAR].
	_island(out, Vector2(0.0, 0.0), 150.0, 4, Kind.BUSH)
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
		pebbles: int, core := Kind.MUCUS) -> void:
	out.append(Vector4(at.x, at.y, big, float(core)))
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
	# Qolların çıxdığı mərkəz KOLDUR — bax [constant CORE_CLEAR].
	out.append(Vector4(0.0, 0.0, 145.0, float(Kind.BUSH)))
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
	return is_free_in(obstacles(), Const.WORLD_RADIUS, pos, radius)


## [method is_free] verilmiş düzüm və şüşə üçün — hər dünya öz xəritəsini yoxlayır.
static func is_free_in(list: Array[Vector4], wall: float, pos: Vector2, radius: float) -> bool:
	if pos.length() > wall - radius:
		return false
	for o in list:
		if not blocks_spawn(int(o.w)):
			continue
		if pos.distance_squared_to(Vector2(o.x, o.y)) < pow(o.z + radius, 2.0):
			return false
	return true


## Koloniya üçün toxumdan götürülən təsadüfi namizədlərin sayı; sonra şəbəkə gəzilir.
const COLONY_TRIES := 24


## SONSUZ ARENA-nın qida koloniyalarının yerləri: `Vector3(x, y, növ)`, sıra
## [constant Const.COLONY_KINDS]-dakı kimidir (bax design/MODES.md §18).
##
## DETERMİNİSTİKDİR: eyni düzüm və eyni toxum eyni yerləri verir. Toxumu server dünya
## yaranarkən seçir; client yerləri join info-da alır və heç vaxt özü axtarmır.
##
## Bol cüt qabın iki qarşı tərəfindədir, zəif cüt onlara dikdir — mənbələr dörd tərəfə
## paylanır. Hər koloniya əvvəl [constant COLONY_TRIES] təsadüfi namizəddə, sonra
## bucaq × məsafə şəbəkəsində yoxlanılır ([method colony_ok]). Heç biri uyğun gəlməsə
## koloniya QOYULMUR (maneənin içinə səssizcə düşmür) və xəbərdarlıq yazılır.
static func colony_spots(list: Array[Vector4], wall: float, seed: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var base := rng.randf() * TAU
	for i in Const.COLONY_KINDS.size():
		var kind: int = Const.COLONY_KINDS[i]
		var span: Vector2 = Const.COLONY_DIST[kind]
		var want := base + (PI if i % 2 == 1 else 0.0) \
			+ (PI * 0.5 if kind == Const.ColonyKind.POOR else 0.0)
		var spot := Vector2.INF
		for _t in COLONY_TRIES:
			var p := Vector2.from_angle(want + rng.randf_range(-0.7, 0.7)) * rng.randf_range(span.x, span.y)
			if colony_ok(list, wall, p, out):
				spot = p
				break
		if not spot.is_finite():
			spot = _colony_scan(list, wall, want, span, out)
		if spot.is_finite():
			out.append(Vector3(spot.x, spot.y, float(kind)))
		else:
			push_warning("[colony] %d-ci koloniyaya uyğun yer tapılmadı — qoyulmur" % i)
	return out


## Toxumdan namizəd tapılmayanda: [param want] bucağından başlayıb hər iki tərəfə
## növbə ilə 5°-lik addımla, hər bucaqda beş məsafə. Deterministikdir.
static func _colony_scan(list: Array[Vector4], wall: float, want: float, span: Vector2,
		placed: PackedVector3Array) -> Vector2:
	for k in 72:
		var a := want + float((k + 1) / 2) * deg_to_rad(5.0) * (1.0 if k % 2 == 0 else -1.0)
		for j in 5:
			var p := Vector2.from_angle(a) * lerpf(span.x, span.y, float(j) / 4.0)
			if colony_ok(list, wall, p, placed):
				return p
	return Vector2.INF


## Koloniya bu nöqtədə dura bilərmi?
##
## Sahəsi ([constant Const.COLONY_CLEAR]) şüşənin içində və HƏR maneədən — kol və cərəyan
## deşiyi də daxil — aralıdır: qida maneənin içində çıxmır, kolun içindəki mənbə isə
## yeyəni gizlədərdi. Başqa koloniyalardan [constant Const.COLONY_GAP] aralıdır. Ən azı iki
## tərəfdən (aralarında 90°-dən çox) mikrob yaxınlaşa bilir.
static func colony_ok(list: Array[Vector4], wall: float, p: Vector2,
		placed: PackedVector3Array) -> bool:
	if p.length() > wall - Const.COLONY_CLEAR:
		return false
	for o in list:
		if p.distance_to(Vector2(o.x, o.y)) < o.z + Const.COLONY_CLEAR:
			return false
	for c in placed:
		if p.distance_to(Vector2(c.x, c.y)) < Const.COLONY_GAP:
			return false
	return colony_sides(list, wall, p) >= 2


## Koloniyaya neçə ayrı tərəfdən yaxınlaşmaq olar: səkkiz istiqamətdə sahənin kənarından
## bir mikrob (radius 30) boyu kənarda yer boşdurmu. Tərəflər yalnız aralarında 90°-dən
## çox olanda ayrı sayılır — yan-yana iki boş istiqamət "bir tərəfdir".
static func colony_sides(list: Array[Vector4], wall: float, p: Vector2) -> int:
	var free := PackedInt32Array()
	for k in 8:
		var probe := p + Vector2.from_angle(TAU * float(k) / 8.0) * (Const.COLONY_CLEAR + 30.0)
		if probe.length() > wall - 30.0:
			continue
		var open := true
		for o in list:
			if blocks_germ(int(o.w)) and probe.distance_to(Vector2(o.x, o.y)) < o.z + 30.0:
				open = false
				break
		if open:
			free.append(k)
	# Bir-birindən ən az iki addım (90°) aralı istiqamətlərin ən böyük dəsti — sadə hərisliklə.
	var sides := 0
	var last := -10
	var first := -1
	for k in free:
		if k - last >= 2 and not (first >= 0 and first + 8 - k < 2):
			sides += 1
			last = k
			if first < 0:
				first = k
	return sides
