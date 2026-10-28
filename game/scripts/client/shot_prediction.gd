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
	ABSORB,  ## rəqibin Anası və ya Nüvə topu udub — top orada bitir (obyekt rejimləri)
	## Amöbün damcısı düşdü. Kimə dəydiyini proqnoz DEMİR: zərbə düşmə anındakı server
	## mövqelərinə qarşıdır, rəqiblər isə ekranda keçmişdə çəkilir — nəticə serverin
	## hadisəsi ilə gəlir. Proqnoz yalnız sıçrantını vaxtında göstərir.
	LAND,
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
	## Profil ([enum Const.Shot]) və ondan çıxanlar — serverin [Sim.ShotState]-i kimi.
	var profile := int(Const.Shot.MINIGUN)
	var speed := Const.SHOT_SPEED
	var radius := Const.SHOT_RADIUS
	var payload := Const.SHOT_PAYLOAD
	## Bir atəş hərəkətinin topları (iki iynə) eyni nömrəni bölüşür — client-in öz sayğacı.
	var volley := 0
	## DAMCI: başlanğıc, düşmə nöqtəsi və uçuş müddəti ([member Sim.ShotState.target]).
	var origin := Vector2.ZERO
	var target := Vector2.ZERO
	var flight := 0.0
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
	## Yalnız ölçüdə ([member trace_on]): tick sonlarının yolu, necə bitdiyi ([enum Contact];
	## -2 = server təsdiqləmədi) və gec tapılan atəşdə geri çatdırılan saniyələr.
	var trace := PackedVector2Array()
	## Hər tick üçün `(ən yaxın hədəfin açarı, gövdəsindən uzaqlıq, hədəf sayı)`.
	var trace_near := PackedVector3Array()
	var end_kind := -1
	var late := 0.0
	## Təsdiq anında: serverin atəş tick-i ilə proqnozun `view0`-ı fərqi (tick) və
	## eyni addım sayında serverin topu proqnozdan xətt boyu nə qədər QABAQDADIR (px).
	var srv_dv := NAN
	var srv_along := NAN


var ghosts: Array[Ghost] = []
var _next_id := 1
var _next_volley := 1
## Ölçü üçün ([Arena]-nın `hit_stats`-ı): topların yolu yazılır və ölən toplar [member recent]-də
## bir müddət qalır — proqnozun görmədiyi dəymənin səbəbi onlardan oxunur. Oyunda söndürülüdür.
var trace_on := false
var recent: Array[Ghost] = []

## Rejimin qabının şüşəsi ([method Const.wall_radius]) — [Arena] verir.
var wall := Const.WORLD_RADIUS
## Atıcının komandası: rəqibin Anası topu UDUR, öz Anası sıçradır (bax
## [method Sim._step_shots]).
var team := -1
## NÜVƏ TOPU: Nüvə `(x, y, radius)`; radius ≤ 0 — Nüvə yoxdur. Top ona dəyib dayanır.
var ball := Vector3(0.0, 0.0, -1.0)


## Yeni top — mikrobun MƏRKƏZİNDƏN, eynilə [method Sim._fire] kimi.
##
## [param profile] — atəşin profili ([enum Const.Shot]); susmaya görə miniqanın topu,
## yəni köhnə düz top.
## [param muts] — atıcının mutasiyaları: sürət və ömür serverlə EYNİ funksiyadan
## ([method Const.shot_speed], [method Const.shot_life]).
func spawn(center: Vector2, dir: Vector2, now: float, view0 := -1.0,
		profile := int(Const.Shot.MINIGUN), muts := 0) -> Ghost:
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
	var p := Const.profile_from(profile)
	g.profile = p
	g.speed = Const.shot_speed(p, muts)
	g.radius = Const.SHOT_PROFILE_RADIUS[p]
	g.payload = Const.SHOT_PROFILE_PAYLOAD[p]
	g.life = Const.shot_life(p, muts)
	g.volley = _next_volley
	_next_volley += 1
	if trace_on:
		g.trace.append(center)
	ghosts.append(g)
	return g


## Bir atəş HƏRƏKƏTİ — [method Sim._fire] kimi: iynə profili iki top (±7°), qalanı bir.
## Hərəkətin topları bir qrupdadır ([member Ghost.volley]).
func spawn_volley(center: Vector2, dir: Vector2, now: float, view0 := -1.0,
		profile := int(Const.Shot.MINIGUN), muts := 0) -> Array[Ghost]:
	var out: Array[Ghost] = []
	var p := Const.profile_from(profile)
	if p != Const.Shot.NEEDLE:
		out.append(spawn(center, dir, now, view0, p, muts))
		return out
	for k in Const.NEEDLE_COUNT:
		var g := spawn(center, dir.rotated(Const.NEEDLE_SPREAD * (-1.0 if k == 0 else 1.0)),
			now, view0, p, muts)
		if not out.is_empty():
			g.volley = out[0].volley
		out.append(g)
	return out


## Amöbün DAMCISI — [param center]-dən [param target]-ə [constant Const.LOB_FLIGHT]-da.
## Uçuşda heç nəyə toxunmur ([method Sim._step_shots]), düşəndə [constant Contact.LAND].
func spawn_lob(center: Vector2, target: Vector2, now: float, muts := 0) -> Ghost:
	var g := spawn(center, (target - center).normalized(), now, -1.0, Const.Shot.LOB, muts)
	g.origin = center
	g.target = target
	g.flight = Const.lob_flight(muts)
	return g


## Damcının yerdən hündürlüyü 0..1 — uçuşun payı [param t]-də (parabola). Görüntü üçün.
static func lob_height(t: float) -> float:
	var k := clampf(t, 0.0, 1.0)
	return 4.0 * k * (1.0 - k)


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
	g.late = seconds
	while not g.done and g.ticks <= int(floor(age + EPS)):
		_sim_tick(g, obstacles, broken, [])
		if trace_on:
			g.trace.append(g.seg_to)
	g.pending.clear()
	_place(g, age)
	if g.done:
		_end(g, now)


## Hələ serverin atəş hadisəsini görməmiş TƏZƏ top varmı?
##
## Varsa, atəş proqnozda oynadılıb və serverin FIRE hadisəsi ikinci dəfə
## göstərilməməlidir. Top işarələnir ki, növbəti atəşin hadisəsi onu yenidən
## "tapmasın".
##
## Bir hərəkətin bütün topları (iki iynə) birlikdə işarələnir: server hərəkətə BİR
## atəş hadisəsi göndərir və ikinci iynə növbəti atəşin hadisəsini "udmamalıdır".
func take_unseen_fire(now: float, window: float) -> bool:
	for g in ghosts:
		if not g.fire_seen and now - g.born <= window:
			for other in ghosts:
				if other.volley == g.volley:
					other.fire_seen = true
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
		# Damcı istiqamətlə tanınmır — serverin damcı sətri başqa yolla gəlir ([method claim_lob]).
		if g.sid >= 0 or now - g.born > CLAIM_GRACE or g.profile == Const.Shot.LOB:
			continue
		if g.first_dir.dot(d) > 0.99 or g.dir.dot(d) > 0.99:
			g.sid = sid
			if g.alive and server_pos.is_finite() and g.dir.dot(d) > 0.99:
				var side := d.orthogonal()
				g.nudge = -side * (g.pos - server_pos).dot(side)
			return g
	return null


## Serverin öz damcısı göründü — düşmə nöqtəsi [param reach] px yaxın olan ən köhnə
## təsdiqlənməmiş proqnoz damcısı. Damcını proqnoz çəkir, serverinki gizli qalır.
func claim_lob(sid: int, target: Vector2, now: float, reach := 24.0) -> Ghost:
	for g in ghosts:
		if g.sid >= 0 or g.profile != Const.Shot.LOB or now - g.born > CLAIM_GRACE:
			continue
		if g.target.distance_to(target) <= reach:
			g.sid = sid
			return g
	return null


## Serverin dəyməsi proqnozdan TEZ gəldi — proqnoz onu artıq hesablayıb, ekrana isə
## top o nöqtəyə çatanda verəcəkdi ([member Ghost.pending]).
##
## Kiçik pinqdə (RTT bir tick-dən az) serverin xəbəri topun ekranda qalan yarım
## tick-lik yolundan tez çatır. Əvvəl belə dəymə "proqnozsuz" sayılırdı: top
## [method stop_nearest] ilə nöqtəyə ~7 px qalmış dayandırılırdı. Ölçülüb (lokal
## server): "yalnız server" dəymələrinin hamısı belə idi. İndi təmas elə indi
## verilir və top dəymə nöqtəsində bitir. Boş lüğət — belə təmas yoxdur.
func take_pending_hit(at: Vector2, reach: float, now: float, key := -1) -> Dictionary:
	for g in ghosts:
		if not g.alive:
			continue
		for i in g.pending.size():
			var c: Dictionary = g.pending[i]["contact"]
			if int(c["kind"]) != Contact.HIT or Vector2(c["pos"]).distance_to(at) > reach \
					or (key >= 0 and int(c["key"]) != key):
				continue
			g.pending.remove_at(i)
			g.pos = c["pos"]
			g.seg_from = g.pos
			g.seg_to = g.pos
			g.seg_touch = -1.0
			_end(g, now)
			return c
	return {}


## Hadisə nöqtəsinə ən yaxın UÇAN topu dayandırır.
##
## Serverin dəyməsini proqnoz görməyəndə (rəqib kolda idi, və ya geri sarma
## həddi aşılmışdı) top ekranda uçmağa davam edirdi — artıq olmayan top.
func stop_nearest(at: Vector2, reach: float, now: float) -> Ghost:
	var best: Ghost = null
	var best_d := reach * reach
	for g in ghosts:
		# Damcı öz anında düşür — başqa topun hadisəsi onu havada dayandırmır.
		if not g.alive or g.profile == Const.Shot.LOB:
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
		# Havadakı damcıya trixosist çatmır ([method Sim._super_trichocyst]).
		if g.alive and g.profile != Const.Shot.LOB \
				and g.pos.distance_squared_to(at) <= reach * reach:
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
## [param targets] — rəqiblər: `{"pos", "radius", "key", "shape"}`
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
			g.end_kind = -2
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
			if trace_on:
				g.trace.append(g.seg_to)
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
	# DAMCI: düz xətlə düşmə nöqtəsinə, heç nəyə toxunmadan (serverdəki kimi).
	if g.profile == Const.Shot.LOB:
		if g.life <= 0.0:
			_finish(g, Contact.LAND, g.target, float(k + 1), -1)
			return
		g.seg_to = g.origin.lerp(g.target, clampf(1.0 - g.life / maxf(g.flight, 0.001), 0.0, 1.0))
		return
	if g.life <= 0.0:
		_finish(g, Contact.SPENT, from, float(k + 1), -1)
		return

	var to := from + g.dir * g.speed * Const.TICK_DELTA
	var best := 2.0
	var hit_index := -1
	var hit_obstacle := Vector4.ZERO
	var victim: Dictionary = {}
	for i in obstacles.size():
		var o := obstacles[i]
		var t := Sim._seg_circle_t(from, to, Vector2(o.x, o.y), o.z + g.radius)
		if not (t >= 0.0 and t < best):
			continue
		if i < broken.size() and DishMap.wall_gone(broken[i]):
			continue
		if not DishMap.blocks_shot(int(o.w)):
			continue
		best = t
		hit_index = i
		hit_obstacle = o
	# Nüvə: top ona dəyib dayanır (serverdə onu itələyir və ağırlaşdırır).
	var hit_ball := false
	if ball.z > 0.0:
		var tb := Sim._seg_circle_t(from, to, Vector2(ball.x, ball.y), ball.z + g.radius)
		if tb >= 0.0 and tb < best:
			best = tb
			hit_ball = true
	var list: Array = targets.call(g.view0 + float(k) if g.view0 >= 0.0 else -1.0) \
		if targets is Callable else targets
	# Ölçü: bu tick-in parçasına ən yaxın hədəf və onun gövdəsindən uzaqlıq (bax [member trace_on]).
	if trace_on:
		var near := Vector3(-1.0, INF, float(list.size()))
		for target in list:
			var tp: Vector2 = target["pos"]
			var ab := to - from
			var tt := clampf((tp - from).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var gap := tp.distance_to(from + ab * tt) - float(target.get("radius", 0.0))
			if gap < near.y:
				near = Vector3(float(target["key"]), gap, float(list.size()))
		g.trace_near.append(near)
	for target in list:
		# Server kimi: mikroba içində başlayan parça da dəyir (bax
		# [method Sim.seg_ellipse_hit_t]).
		var t := Sim.seg_ellipse_hit_t(from, to, target["pos"], _shape_of(target, g.radius)) \
			if target.has("shape") else Sim._seg_circle_t(from, to, target["pos"],
				float(target["radius"]) + g.radius)
		if t >= 0.0 and t < best:
			best = t
			victim = target
			hit_index = -1
			hit_ball = false

	if best <= 1.0:
		var at := from.lerp(to, best)
		var when := float(k) + best
		if hit_ball:
			_finish(g, Contact.ABSORB, at, when, -1, best)
			return
		if not victim.is_empty():
			var key := int(victim["key"])
			_finish(g, Contact.HIT, at, when, key, best)
			# Xəttin qurbandan nə qədər dərin keçdiyi — sərhəddəki dəymənin zərbəsini
			# [Arena] serverin təsdiqinə saxlayır (bax [constant Arena.OWN_SURE_DEPTH]).
			var reach := float(victim.get("radius", 0.0)) + g.radius
			var contact: Dictionary = g.pending[-1]["contact"]
			contact["depth"] = Sim.line_depth(at, g.dir, victim["pos"],
				_shape_of(victim, g.radius) if victim.has("shape") else Vector3(reach, reach, 0.0))
			contact["late"] = g.life < LATE_LIFE
			return
		if hit_index >= 0:
			if int(hit_obstacle.w) == DishMap.Kind.BRITTLE:
				_finish(g, Contact.CRACK, at, when, hit_index, best)
				return
			# Rəqibin Anası topu udur — top orada bitir.
			if int(hit_obstacle.w) == DishMap.Kind.MOTHER and team >= 0 \
					and team != (0 if hit_obstacle.x < 0.0 else 1):
				_finish(g, Contact.ABSORB, at, when, -1, best)
				return
			_bounce(g, at, (at - Vector2(hit_obstacle.x, hit_obstacle.y)).normalized(),
				best, when, -1)
			return

	g.seg_to = to
	# Qabın şüşə kənarı — serverdəki kimi addımın sonundan radial proyeksiya.
	var limit := wall - g.radius
	if to.length() > limit:
		var n := -to.normalized()
		var at := -n * limit
		g.seg_to = at
		_bounce(g, at, n, 1.0, float(k + 1), -1)


## Hədəfin toqquşma ellipsi bu topun radiusu ilə ([method Sim.hit_shape]). Hədəf
## `species/cap/vel` daşıyırsa ellips topun öz radiusu ilə qurulur; yalnız hazır
## `shape` varsa (köhnə çağıran, testlər) o götürülür.
static func _shape_of(target: Dictionary, shot_r: float) -> Vector3:
	if target.has("cap"):
		return Sim.hit_shape(int(target.get("species", 0)), int(target["cap"]),
			Vector2(target.get("vel", Vector2.ZERO)), shot_r)
	return target["shape"]


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
	g.end_kind = int(kind)
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
		if trace_on:
			recent.append(g)
			if recent.size() > 48:
				recent.pop_front()
		ghosts.remove_at(i)


func clear() -> void:
	ghosts.clear()
