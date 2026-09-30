class_name ShotPrediction
extends RefCounted
## Öz topunun PROQNOZU — serveri gözləmədən uçur, sıçrayır və DƏYİR.
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Əvvəl öz topun yalnız serverin topunun surəti idi: düz xətlə uçurdu,
## dəyməni isə server deyirdi. Serverin HIT hadisəsi isə gec gəlir — şəbəkə
## gedişi-gəlişi (RTT), üstəlik növbədə 100 ms interpolyasiya gecikməsi. Ekranda
## top rəqibin içindən keçib o biri tərəfdən çıxırdı, parıltı isə ~250 ms sonra
## yanırdı. Oyunçu dəydiyini HİSS ETMİRDİ.
##
## Brawl Stars və bənzər oyunlar bunu belə həll edir: öz mərmin öz ekranında
## tam simulyasiya olunur və gördüyün rəqibə dəyən kimi zərbə ELƏ O KADRDA
## göstərilir. Server isə eyni anı öz tərəfində geri sararaq yoxlayır
## ([member Sim.lag_comp]) ki, gördüyün dəymə sayılsın. Nəticəni — top sayını,
## partlamanı — yenə yalnız server verir; proqnoz yalnız GÖRÜNTÜDÜR.
##
## ── Serverin addımı ilə ──────────────────────────────────────────────────
## Top serverdəki kimi TICK-lərlə uçur: [method _sim_tick] [method Sim._step_shots]-un
## bir top üçün surətidir — eyni ömür sayğacı, eyni maneə və sıçrayış, qabın
## kənarında eyni radial proyeksiya. Ekranda isə tick daxilində hamar çəkilir.
##
## Əvvəl top kadrla (60 Hz) addımlayırdı və iki şey fərqlənirdi. Qabın kənarında
## sıçrayış nöqtəsi addımın uzunluğundan asılıdır (server 14 px, kadr 7 px): 500
## px sonra top serverinkindən 18 px aralı uçurdu. Hədəfin vaxtı isə kadrın
## saatına bağlı idi: snapshot-lar jitter-lə gələndə ekrandakı rəqib tick-in
## yarısı qədər qabaqda və ya geridə olurdu. İndi `k`-cı tick-in parçası rəqibin
## MƏHZ serverin yoxladığı tick-dəki halına qarşı yoxlanılır: `görünən tick + k`
## (bax [member Sim.lag_comp] — server qurbanı `tick − rewind`-də yoxlayır).
##
## Node deyil, sadə sinifdir: çəkilişi [Arena] edir, bu sinif isə yalnız
## "harada, nəyə dəydi" sualına cavab verir — ona görə başsız testdən keçir.

enum Contact {
	HIT,     ## rəqibin içinə keçdi
	BOUNCE,  ## divardan, maneədən və ya amöbün qabığından sıçradı
	CRACK,   ## kövrək qabığa dəyib qaldı
	SPENT,   ## ömrü və ya sıçrama haqqı bitdi — serverdə qidaya çevrilir
}

## Server bu qədər saniyəyə topu təsdiqləməsə, atəş qəbul edilməyib sayılır.
##
## RTT + bir tick-dən xeyli böyük olmalıdır: mobil şəbəkədə gediş-gəliş 300 ms-ə
## çıxa bilir və o halda doğru top vaxtından əvvəl silinərdi.
const CLAIM_GRACE := 1.0

## Tick sərhədində üzən nöqtə xətası (tick ilə ölçülür).
const EPS := 0.000001

## Ömrünün son bu qədər saniyəsindəki dəymə "gec"dir — [Arena] onun zərbəsini
## serverin təsdiqinə saxlayır. Proqnozun atəş nöqtəsi serverinkindən xətt boyu
## bir tick-in yoluna qədər fərqlənə bilir, ömrün sonunda isə bu fərq topun
## hədəfə çatıb-çatmamasını həll edir. Ölçülüb: 64-cü tick-də "dəyən" proqnoz
## serverinkindən 9 px qabaqda idi — serverin topu qurbana 1.20 məsafədə öldü.
## Son iki parça (qalan ömür 1 və 2 tick; 2.5 — tam ədəddə üzən nöqtə sərhədi olmasın).
const LATE_LIFE := 2.5 * Const.TICK_DELTA


class Ghost:
	var id := 0
	## Ekranda çəkilən yer — cari tick parçasının içində.
	var pos := Vector2.ZERO
	## Hazırkı istiqamət (sonuncu simulyasiya olunmuş tick-in sonunda).
	var dir := Vector2.RIGHT
	## Atəş anındakı istiqamət — server topu gələndə uyğunlaşdırma bununla olur.
	var first_dir := Vector2.RIGHT
	## Serverdəki kimi saniyə ilə, hər tick bir [constant Const.TICK_DELTA] azalır.
	var life := Const.SHOT_LIFETIME
	var bounces := 0
	var born := 0.0
	## Atəş anında ekrandakı server tick-i ([member Sim.PlayerInput.view_tick]):
	## `k`-cı tick-in parçası rəqiblərin `view0 + k`-dakı halına qarşı yoxlanılır.
	## Mənfi = bilinmir (gec tapılan atəş) — onda ekrandakı yerlər götürülür.
	var view0 := -1.0
	## Serverin top id-si; -1 = hələ təsdiqlənməyib.
	var sid := -1
	## Serverin bu topa tətbiq etdiyi geri sarma (s) — təsdiq gələndə yazılır.
	## [constant Const.REWIND_MAX]-a dirənibsə, server hədəfləri proqnozdan daha
	## YENİ tick-də yoxlayır (bax [method Arena._on_own_contact]).
	var rewind := 0.0
	var alive := true
	## Dayandığı an (dəydi, sıçrama bitdi) — təmizlik üçün.
	var ended := -1.0
	## Serverin atəş hadisəsi bu topa aiddir və artıq emal olunub.
	var fire_seen := false
	## Serverin xəttinə qalan YAN düzəliş — hamar tətbiq olunur (bax [method claim]).
	var nudge := Vector2.ZERO
	## Neçə tick-in parçası simulyasiya olunub.
	var ticks := 0
	## Cari parça: başlanğıc, son, və parçanın içindəki təmas (sıçrayış, dəymə):
	## `seg_touch` parçanın hansı hissəsindədir (-1 = təmas yoxdur).
	var seg_from := Vector2.ZERO
	var seg_to := Vector2.ZERO
	var seg_touch := -1.0
	var seg_touch_at := Vector2.ZERO
	## Simulyasiya bitib (dəydi, ömrü və ya sıçrama haqqı bitdi); görüntü isə
	## təmasın anına qədər davam edir.
	var done := false
	## Vaxtı çatmamış təmaslar: `{"at": tick yaşı, "contact": Dictionary}`.
	var pending: Array[Dictionary] = []


var ghosts: Array[Ghost] = []
var _next_id := 1


## Yeni top — mikrobun MƏRKƏZİNDƏN, eynilə [method Sim._fire] kimi.
func spawn(center: Vector2, dir: Vector2, now: float, view0 := -1.0) -> Ghost:
	var g := Ghost.new()
	g.id = _next_id
	_next_id += 1
	g.pos = center
	g.seg_from = center
	g.seg_to = center
	g.dir = dir.normalized()
	g.first_dir = g.dir
	g.born = now
	g.view0 = view0
	ghosts.append(g)
	return g


## Gec tapılmış atəşin topunu İNDİYƏ çatdırır — [param seconds] qədər uçuş.
##
## Proqnoz atəşi bəzən yalnız serverin düzəlişindən sonra görür (bax
## [method Arena._reconcile]): top o vaxta artıq yoldadır. Uçuş maneə və
## divarlarla tick-tick aparılır ki, arada sıçrayış varsa top düzgün yerdə
## olsun. Rəqiblər YOXLANMIR: keçmişdə kimə dəydiyini proqnoz bilə bilməz —
## onu serverin hadisəsi deyəcək.
func catch_up(g: Ghost, seconds: float, now: float, obstacles: Array[Vector4],
		broken: PackedByteArray) -> void:
	var age := seconds / Const.TICK_DELTA
	while not g.done and g.ticks <= int(floor(age + EPS)):
		_sim_tick(g, obstacles, broken, [])
	g.pending.clear()
	_place(g, age)
	if g.done:
		_end(g, now)


## Hələ serverin atəş hadisəsini görməmiş TƏZƏ top varmı?
##
## Varsa, atəş proqnozda oynadılıb və serverin FIRE hadisəsi ikinci dəfə
## göstərilməməlidir. Top işarələnir ki, növbəti atəşin hadisəsi onu yenidən
## "tapmasın".
func take_unseen_fire(now: float, window: float) -> bool:
	for g in ghosts:
		if not g.fire_seen and now - g.born <= window:
			g.fire_seen = true
			return true
	return false


## Proqnozun YAN düzəlişinin sürəti (1/s): 12-də ~0.1 saniyəyə tamamlanır.
const NUDGE_RATE := 12.0


## Serverdə yeni öz topu göründü — onu ən köhnə təsdiqlənməmiş proqnozla birləşdirir.
##
## İstiqamət yoxlaması həm ilk, həm indiki istiqamətlə aparılır: yaxın divara
## atılan top serverin ilk snapshot-ına artıq sıçramış halda düşə bilər.
## Artıq DƏYMİŞ (ölü) proqnoz da tutulur — qısa məsafədə top server onu
## göndərməmişdən əvvəl hədəfə çatır və o halda serverin topu çəkilməməlidir.
##
## [param server_pos] verilibsə, proqnoz serverin XƏTTİNƏ yana doğru çəkilir:
## atəşin başlanğıcı proqnozun xətası qədər (bir neçə piksel) fərqlənə bilər.
## Xətt boyu vaxta toxunulmur — proqnoz qəsdən İNDİDƏDİR; yalnız xəttə dik
## fərq silinir.
func claim(sid: int, server_dir: Vector2, now: float,
		server_pos := Vector2.INF) -> Ghost:
	var d := server_dir.normalized()
	for g in ghosts:
		if g.sid >= 0 or now - g.born > CLAIM_GRACE:
			continue
		if g.first_dir.dot(d) > 0.99 or g.dir.dot(d) > 0.99:
			g.sid = sid
			if g.alive and server_pos.is_finite() and g.dir.dot(d) > 0.99:
				var side := d.orthogonal()
				g.nudge = -side * (g.pos - server_pos).dot(side)
			return g
	return null


## Hadisə nöqtəsinə ən yaxın UÇAN topu dayandırır.
##
## Serverin dəyməsini proqnoz görməyəndə (rəqib kolda idi, və ya geri sarma
## həddi aşılmışdı) top ekranda uçmağa davam edirdi — artıq olmayan top.
func stop_nearest(at: Vector2, reach: float, now: float) -> Ghost:
	var best: Ghost = null
	var best_d := reach * reach
	for g in ghosts:
		if not g.alive:
			continue
		var dd := g.pos.distance_squared_to(at)
		if dd <= best_d:
			best_d = dd
			best = g
	if best != null:
		_end(best, now)
	return best


## Rəqibin trixosisti partladı — radiusdakı UÇAN öz toplarını dayandırır.
##
## Çağıran bunu partlayışı EKRANDA göstərdiyi anda edir: rəqib keçmişdə, öz
## topun isə indidə çəkilir, yəni partlayış görünəndə top artıq `rewind` qədər
## irəlidədir. Server də məhz bu anı yoxlayır ([member Sim._blasts]) — ekranda
## partlayışdan SONRA rəqibə çatan top serverdə də dəymir, ƏVVƏL çatan isə dəyir.
func blast(at: Vector2, reach: float, now: float) -> Array[Ghost]:
	var out: Array[Ghost] = []
	for g in ghosts:
		if g.alive and g.pos.distance_squared_to(at) <= reach * reach:
			_end(g, now)
			out.append(g)
	return out


## Bir kadr irəli.
##
## Serverin topu snapshot-dan itəndə proqnoz DAYANDIRILMIR: snapshot yalnız
## ən yaxın [constant Const.SHOT_SEND_MAX] topu daşıyır və sıx döyüşdə öz
## topun bir-iki paketdən düşə bilir. Proqnozu yalnız öz qaydası (dəymə,
## sıçrama haqqı, ömür) və serverin dəymə hadisəsi ([method stop_nearest]) bitirir.
##
## [param targets] — rəqiblər: `{"pos", "radius", "key", "cyst", "shape"}`
## massivi (hər tick üçün eyni), və ya server tick-i alıb həmin tick-in
## massivini qaytaran [Callable] (bax [method Arena._ghost_targets]).
##
## Top YAŞA görə irəli gedir, çağırışların sayına görə yox: `now − born`.
##
## Qaytarır: `{"kind": Contact, "pos", "dir" (gəliş oxu), "key", "ghost"}`;
## HIT-də həm də `"depth"` — xəttin qurbandan keçdiyi dərinlik ([method Sim.line_depth]).
func step(dt: float, now: float, obstacles: Array[Vector4],
		broken: PackedByteArray, targets: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in ghosts:
		if not g.alive:
			continue
		if now - g.born > CLAIM_GRACE and g.sid == -1:
			# Server bu atəşi heç vaxt təsdiqləmədi — soyuma fərqi və ya itən
			# giriş. Top səssizcə gedir: olmayan topa dəymə göstərilməməlidir.
			_end(g, now)
			continue
		if g.nudge != Vector2.ZERO:
			var k := minf(1.0, dt * NUDGE_RATE)
			var shift := g.nudge * k
			g.nudge -= shift
			if g.nudge.length_squared() < 0.01:
				shift += g.nudge
				g.nudge = Vector2.ZERO
			g.seg_from += shift
			g.seg_to += shift
			g.seg_touch_at += shift
		var age := (now - g.born) / Const.TICK_DELTA
		while not g.done and g.ticks <= int(floor(age + EPS)):
			_sim_tick(g, obstacles, broken, targets)
		_place(g, age)
		while not g.pending.is_empty() and float(g.pending[0]["at"]) <= age + EPS:
			out.append(g.pending.pop_front()["contact"])
		if g.done and g.pending.is_empty():
			_end(g, now)
	_prune(now)
	return out


## Ekrandakı yer: cari tick-in parçası boyunca, parçanın içində təmas varsa
## ona qədər, sonra təmas nöqtəsində.
static func _place(g: Ghost, age: float) -> void:
	var f := clampf(age - float(g.ticks - 1), 0.0, 1.0)
	if g.seg_touch < 0.0:
		g.pos = g.seg_from.lerp(g.seg_to, f)
	elif f < g.seg_touch:
		g.pos = g.seg_from.lerp(g.seg_touch_at, f / maxf(g.seg_touch, EPS))
	else:
		g.pos = g.seg_to


## Topun BİR server tick-i — [method Sim._step_shots]-un bir top üçün surəti.
##
## Parça `k = ticks` nömrəlidir və serverin `atəş tick-i + k` tick-idir.
## Təmaslar vaxtı ilə yığılır (`k + t`), ekrana isə yaş ora çatanda verilir.
func _sim_tick(g: Ghost, obstacles: Array[Vector4], broken: PackedByteArray,
		targets: Variant) -> void:
	var k := g.ticks
	g.ticks += 1
	var from := g.seg_to
	g.seg_from = from
	g.seg_to = from
	g.seg_touch = -1.0
	# Server topun ömrünü əvvəl azaldır, bitibsə onu HƏRƏKƏTSİZ silir: top 2.2 s
	# yox, 65 tick uçur. Görüntü son nöqtədə bu tick-in sonuna qədər qalır —
	# serverin sonuncu snapshot-u da topu məhz orada göstərir.
	g.life -= Const.TICK_DELTA
	if g.life <= 0.0:
		_finish(g, Contact.SPENT, from, float(k + 1), -1)
		return

	var to := from + g.dir * Const.SHOT_SPEED * Const.TICK_DELTA
	var best := 2.0
	var hit_index := -1
	var hit_obstacle := Vector4.ZERO
	var victim: Dictionary = {}
	for i in obstacles.size():
		var o := obstacles[i]
		var t := Sim._seg_circle_t(from, to, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS)
		if not (t >= 0.0 and t < best):
			continue
		if i < broken.size() and DishMap.wall_gone(broken[i]):
			continue
		if not DishMap.blocks_shot(int(o.w)):
			continue
		best = t
		hit_index = i
		hit_obstacle = o
	var list: Array = targets.call(g.view0 + float(k) if g.view0 >= 0.0 else -1.0) \
		if targets is Callable else targets
	for target in list:
		# Server kimi: kistdən yalnız kənardan giriş səkir, qalan mikroba içində
		# başlayan parça da dəyir (bax [method Sim.seg_ellipse_hit_t]).
		var t := (Sim.seg_ellipse_t(from, to, target["pos"], target["shape"])
			if bool(target.get("cyst", false))
			else Sim.seg_ellipse_hit_t(from, to, target["pos"], target["shape"])) \
			if target.has("shape") else Sim._seg_circle_t(from, to, target["pos"],
				float(target["radius"]) + Const.SHOT_RADIUS)
		if t >= 0.0 and t < best:
			best = t
			victim = target
			hit_index = -1

	if best <= 1.0:
		var at := from.lerp(to, best)
		var when := float(k) + best
		if not victim.is_empty():
			var key := int(victim["key"])
			if bool(victim.get("cyst", false)):
				var normal := Sim.ellipse_normal(at, victim["pos"], victim["shape"]) \
					if victim.has("shape") else (at - Vector2(victim["pos"])).normalized()
				_bounce(g, at, normal, best, when, key)
				return
			_finish(g, Contact.HIT, at, when, key, best)
			# Xəttin qurbandan nə qədər dərin keçdiyi — sərhəddəki dəymənin zərbəsini
			# [Arena] serverin təsdiqinə saxlayır (bax [constant Arena.OWN_SURE_DEPTH]).
			var reach := float(victim.get("radius", 0.0)) + Const.SHOT_RADIUS
			var contact: Dictionary = g.pending[-1]["contact"]
			contact["depth"] = Sim.line_depth(at, g.dir, victim["pos"],
				victim.get("shape", Vector3(reach, reach, 0.0)))
			contact["late"] = g.life < LATE_LIFE
			return
		if hit_index >= 0:
			if int(hit_obstacle.w) == DishMap.Kind.BRITTLE:
				_finish(g, Contact.CRACK, at, when, hit_index, best)
				return
			_bounce(g, at, (at - Vector2(hit_obstacle.x, hit_obstacle.y)).normalized(),
				best, when, -1)
			return

	g.seg_to = to
	# Qabın şüşə kənarı — serverdəki kimi addımın sonundan radial proyeksiya.
	var limit := Const.WORLD_RADIUS - Const.SHOT_RADIUS
	if to.length() > limit:
		var n := -to.normalized()
		var at := -n * limit
		g.seg_to = at
		_bounce(g, at, n, 1.0, float(k + 1), -1)


## [method Sim._bounce] ilə eyni: haqq bitibsə top dayanır. [param frac] —
## təmasın parçanın hansı hissəsində olduğu, [param when] — onun yaşı.
func _bounce(g: Ghost, at: Vector2, normal: Vector2, frac: float, when: float,
		key: int) -> void:
	g.bounces += 1
	if g.bounces > Const.SHOT_BOUNCES:
		_finish(g, Contact.SPENT, at, when, key, frac)
		return
	var incoming := g.dir
	g.dir = g.dir.bounce(normal).normalized()
	g.seg_touch = frac
	g.seg_touch_at = at
	g.seg_to = at + normal * 0.5
	var c := _contact(Contact.BOUNCE, g, at, key)
	c["dir"] = incoming
	g.pending.append({"at": when, "contact": c})


## Simulyasiya burada bitir; görüntü təmasın anına qədər gedir.
func _finish(g: Ghost, kind: Contact, at: Vector2, when: float, key: int,
		frac := -1.0) -> void:
	g.done = true
	if frac >= 0.0:
		g.seg_touch = frac
		g.seg_touch_at = at
	g.seg_to = at
	g.pending.append({"at": when, "contact": _contact(kind, g, at, key)})


func _contact(kind: Contact, g: Ghost, at: Vector2, key: int) -> Dictionary:
	return {"kind": kind, "pos": at, "dir": g.dir, "key": key, "ghost": g}


func _end(g: Ghost, now: float) -> void:
	g.alive = false
	g.ended = now


## Ölü və artıq heç bir server topunun axtarmayacağı proqnozları atır.
##
## Təsdiqlənməmiş ölü top SAXLANILIR: server onu hələ göndərə bilər və o
## vaxt serverin topu proqnozla birləşməlidir, yoxsa artıq dəymiş top ekranda
## ikinci dəfə peyda olar. Təsdiqlənmiş ölü topu isə [Arena]-nın görüntüsü
## özü saxlayır, siyahıda qalmasına ehtiyac yoxdur.
func _prune(now: float) -> void:
	for i in range(ghosts.size() - 1, -1, -1):
		var g := ghosts[i]
		if g.alive:
			continue
		if g.sid == -1 and now - g.born <= CLAIM_GRACE:
			continue
		ghosts.remove_at(i)


func clear() -> void:
	ghosts.clear()
