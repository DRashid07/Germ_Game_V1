class_name Arena
extends Node2D
## Oyun ekranı: girişi toplayır, proqnoz qurur, serverin sözünü qəbul edir və çəkir.
##
## Üç fərqli zaman xətti burada birləşir:
##   1. İndi         — öz mikrobun. Girişi dərhal tətbiq olunur (prediction).
##   2. Keçmiş       — rəqiblər, toplar və qida, 100–200 ms geridə (şəbəkənin jitter-inə
##                     görə dəyişir, bax [method _update_delay_target]). Interpolyasiya.
##   3. Serverin sözü — snapshot gələndə öz vəziyyətin düzəldilir (reconciliation).
##
## Rəqibləri qəsdən geridə göstəririk: paket gecikəndə belə interpolyasiya üçün
## əlimizdə həmişə iki snapshot olur, hərəkət titrəmir.

## Kadrda yığılmış snapshot-lar emal olundu (bax [method _drain_inbox]) — test probe-u üçün:
## öz mikrobun proqnozunun cəmi düzəlişi (px), emalın vaxtı (ms), snapshot sayı.
signal drained(corr_px: float, ms: float, count: int)
##
## Dünya ekrandan böyükdür, ona görə kamera mikrobu izləyir və tutum böyüdükcə
## uzaqlaşır — böyük mikrob daha geniş sahə görür.

const FX_LIFETIME := 0.26
## Effekt sprite-ı neçə dəfə böyüyür və ömrünün NEÇƏNCİ hissəsində.
##
## Böyümə sönmədən qabaqda getməlidir — səbəb [method _spawn_fx]-dədir.
## Çağıranlar başlanğıc miqyası bu ədədə görə seçir ki, SONDA diametr həqiqi
## sahəyə bərabər olsun (bax [method _flush_fx]-in SUPER budağı).
const FX_GROW := 1.7
const FX_GROW_RATIO := 0.35

## Bağlantı kəsiləndə neçə dəfə və hansı aralıqla qayıtmağa çalışırıq.
## Serverin saxladığı müddətə (Lobby.REJOIN_GRACE = 20 s) sığmalıdır.
const REJOIN_ATTEMPTS := 5
const REJOIN_INTERVAL := 3.0

## Qida ilə uçan top EYNİ şey kimi görünürdü: ikisi də ~10 px-lik parlaq dairə
## idi, top sahibinin rəngində, qida solğun yaşıl (öz rəngin laym olanda lap
## eyni). Oyunun ən vacib sualı isə budur: "bu, təhlükədir, yoxsa yem?"
## İndi fərq ÜÇ kanaldadır: forma (top kometdir, qida dairə), ölçü (qida
## kiçikdir) və işıq (top parlayır, qida tutqundur).
##
## Qida sprite-ının miqyası: 32 px-lik şəklin görünən radiusu ~7.8 px — topun
## başından (9.6) kiçik. Udma radiusu ([constant Const.FOOD_RADIUS] = 10)
## dəyişmir: görüntü ondan bir az kiçikdir, yəni mikrob qidanı membranı ona
## toxunmamış udur — bu, toxunuşdan "səxavətli" hiss olunur, əksi yox.
const FOOD_SCALE := 0.68
## Spor (iri qida yığını) KİÇİLMİR və tutqunlaşmır: o, tutum verən mükafatdır
## və uzaqdan seçilməlidir. Miqyası köhnə qidanınkından çıxır (0.85 × 22/10).
const SPORE_SCALE := 0.85
## Qidanın tutqunluğu: ən açıq kanalı xətti fəzada glow həddindən (0.62, bax
## [method _build_glow]) aşağı salır — YÜKSƏK-də qida artıq işıq saçmır, top saçır.
const FOOD_DIM := Color(0.78, 0.78, 0.78)
## Komet sprite-ı ([code]shot_comet.svg[/code]) 2× sıxlıqda idxal olunur və yarım
## miqyasla çəkilir: fırlanan sprite 1×-də pilləli görünür, telefonun ekranında
## isə dünya ~1.9× böyüdülür. Başı teksturanın mərkəzindən sağdadır (46/64) —
## `offset` onu node-un nöqtəsinə, yəni topun həqiqi yerinə qoyur.
const SHOT_SCALE := 0.5
const SHOT_HEAD := Vector2(-28.0, 0.0)

## Serverin artıq bildirmədiyi obyektin görüntüsü bu qədər saniyə saxlanılır.
##
## Rəqəm təsadüfi deyil: biz keçmişi göstəririk (INTERP_DELAY = 100 ms), ona görə
## obyekt son görüldüyü andan düz bir interpolyasiya gecikməsi sonra ekrandan
## çıxmalıdır — nə tez (udulan qida qığılcımdan əvvəl yox olar), nə gec
## (udulmuş qida ekranda qalar). Üstünə bir tick əlavə olunur ki, itən bir
## paket obyekti yanıb-söndürməsin.
const VIEW_GRACE := Const.INTERP_DELAY + Const.TICK_DELTA

## Proqnozun atdığı top serverin FIRE hadisəsini bu qədər saniyə gözləyir
## (bax [method ShotPrediction.take_unseen_fire]).
##
## Atəş fasiləsindən (FIRE_COOLDOWN = 1 s) KİÇİK olmalıdır: belə olanda
## növbədə heç vaxt iki gözləyən atəş qalmır, yəni səhv uyğunlaşma mümkün
## deyil.
const MUZZLE_GRACE := 0.6

## Proqnozun oynatdığı öz superi serverin SUPER hadisəsini bu qədər saniyə
## gözləyir (bax [method _take_own_super]). Gediş-gəlişdən və adi donmadan
## xeyli uzundur; gəlməsə (server superi rədd edib), qeyd bu müddətdən sonra
## düşür. İki öz super arasında partlatma doluluğu dərhal doldursa da, hər
## basılış öz qeydini qoyur — sıra ilə götürülür, səhv uyğunlaşma olmur.
const OWN_SUPER_GRACE := 2.0

## Proqnozlaşdırılmış dəymənin vədi (top sayı, super doluluğu) bu qədər
## saniyə saxlanılır. Serverin sözü RTT + interpolyasiya (~250 ms) sonra
## ekrana çatır; server dəyməni qəbul etməsə, vəd bu müddətdən sonra sönür.
const PROMISE_HOLD := 0.6

## Proqnozun dəymə/sıçrayışı serverin hadisəsini bu qədər saniyə gözləyir.
## Uyğun gələn server hadisəsi İKİNCİ dəfə göstərilmir.
const CLAIM_KEEP := 1.2
## Proqnozdan əvvəl gələn öz dəyməsi bu qədər gözləyir (bax [method _take_early_hit]).
const EARLY_HIT_KEEP := 0.6
## Serverin dəymə nöqtəsi proqnozunkundan bu qədər aralı ola bilər (px).
## Geri sarma eyni anı yoxlayır, ona görə fərq adətən bir tick-in yoludur
## (14 px); ehtiyat pinq dəyişkənliyi üçündür.
const CLAIM_REACH_HIT := 110.0
## Öz topunun XƏTTİ qurbanın ellipsindən bundan dayaz keçirsə (0 = mərkəz,
## 1 = sərhəd), zərbə serverin təsdiqini gözləyir — top isə gövdənin kənarında
## dayanır. Ölçülüb (RTT 120/180 ms, 24 sessiya): təsdiqlənməyən öz dəymələrinin
## çoxu 0.99+ dərinlikdə idi — atəş nöqtəsinin bir neçə piksellik fərqi sərhəddə
## nəticəni dəyişir; sonra 0.88-lik biri də çıxdı (sürətli amöb, serverdə 1.02).
## Təsdiqlənən dəymələrin ~10%-i bundan dayazdır.
const OWN_SURE_DEPTH := 0.85
const CLAIM_REACH_WALL := 70.0

## Öz topunun dəydiyi qurbanın PARTLAMASI bu qədər saniyə ərzində gələrsə,
## interpolyasiyanı gözləmədən dərhal göstərilir (bax [method _queue_events]).
const KILL_LINK := 1.5

## Botun topu öz mikrobuna bu qədər yaxınlaşanda (gövdənin kənarından, px)
## tam OYUNÇUNUN zaman xəttinə keçir; keçid [constant SELF_BLEND] px boyu hamardır.
## Bax [method _remote_shot_pos].
const SELF_NEAR := 150.0
const SELF_BLEND := 300.0
## Top yalnız yolu gövdənin bu qədər yaxınından keçəndə "sənə uçur" sayılır
## (bax [method _aimed_at_me]).
const SELF_AIM_SLACK := 40.0
## Köçürmənin ən böyük sürəti (1/s): sən topun yoluna qəfil girəndə top
## irəli sıçramır, ~0.25 s-də hamar yetişir.
const SELF_CATCH_RATE := 4.0
## Sənə artıq təhlükə olmayan, qabağında başqa mikrob olan top keçmişə ən azı
## bu sürətlə qayıdır (px/s, topun öz sürətindən çıxılır: top geri getmir,
## yalnız yavaşıyır). Qabaqda mikrob [constant SELF_RELEASE_LOOK] px-ə qədər
## axtarılır. Bax [method _release_room], [method release_rate].
const SELF_RELEASE_SPEED := 0.6 * Const.SHOT_SPEED
const SELF_RELEASE_LOOK := 220.0
## Proqnoz yalnız topun XƏTTİ ellipsin bu qədər içindən keçəndə dərhal oynanır
## (0 = mərkəzdən, 1 = sərhədə toxunur). Sərhəddə proqnozun bir neçə piksellik
## xətası nəticəni dəyişir — ölçülüb: yalançı dəymələrin yarısı gövdədən 5–7 px
## kənardan keçən toplar idi. 0.8-də əmin proqnozların ~5%-i yenə yalançı çıxırdı:
## serverdə top gövdənin yanından keçirdi. Bax [method _remote_shot_pos].
const SELF_SURE_DEPTH := 0.65
## Sənin serverdəki yerinin proqnozdan nə qədər fərqlənə biləcəyi — topun yoluna
## DİK: sabit hissə (px) və yola dik sürətinin payı (s). Server girişləri öz tick-i
## ilə emal edir: jitter-də bir giriş iki dəfə, növbəti isə heç işlənmir və
## mövqe bir tick-in yolu qədər (~6 px) sürüşür — ölçülüb, girişlərin ~10%-i.
## RTT və snapshot saatının xətası da üstünə gəlir. Topun yoluna dik qaçan mikrob
## bu vaxtda yoldan çəkilə bilir (bax [method self_sure_depth]).
const SELF_POS_ERR := 2.0
const SELF_TIME_ERR := 0.12
## Yolda başqa mikrob bu qədər yaxındırsa (px), top ona dəyə bilər — proqnoz gözləyir.
const SELF_SURE_GAP := 24.0
## Serverin topu hədəfin əhatəsindən bu qədər (px) də uzaqlaşıbsa, dəymə olmayıb
## (bax [method shot_gone_past]).
const UNDO_MARGIN := 20.0

## Minixəritənin yenilənmə tezliyi (bax [method _update_minimap]).
const MINIMAP_HZ := 10.0

## Server "super hələ işləyir" deyəndə proqnozun sayğacının uzadıldığı vaxt.
##
## Üç tick-dir: bir tick bayrağın öz gecikməsi, qalan ikisi itən paket üçün
## ehtiyat. Uzun olsaydı, super serverdə bitəndən sonra da ekranda qalardı
## (bax [method _reconcile]).
const SUPER_TAIL := Const.TICK_DELTA * 3.0

# ---------------------------------------------------------------- vəziyyət

var my_id := 0
var my_color := 0
var practice := false

var pred: Sim                       ## Yalnız lokal mikrobu saxlayan proqnoz
var me: Sim.GermState
var pending: Array[Sim.PlayerInput] = []
## Serverin son dediyi "super işləyir" biti — qalxma anını tutmaq üçün
## saxlanılır (bax [method _reconcile]).
var _super_on_srv := false

## Şəbəkə testi üçün: joystick əvəzinə avtomatik giriş üretilir.
var auto_input := false
## Avtomatik giriş superi özü işlətsinmi. `false` — superi DÜYMƏ ilə basan
## sınaq üçündür (bax `tools/super_probe.gd`): yoxsa avtomatik oyunçu onu
## düymə yanan tick-də özü xərcləyirdi.
var auto_super := true

var _seq := 0
var _tick_accum := 0.0

## Öz mikrobunun ÇƏKİLİŞ üçün interpolyasiya edilən vəziyyəti.
##
## ── Niyə lazımdır ────────────────────────────────────────────────────────
## Proqnoz server tick-i ilə addımlayır (saniyədə 30), ekran isə 60 kadr çəkir.
## Yəni öz mikrobunun mövqeyi hər İKİ kadrdan birində dəyişir. Ölçüldükdə:
## "60 kadr çəkildi, öz mövqeyim yalnız 30 dəfə dəyişdi".
##
## Kamera da həmin mövqeyə bağlıdır, ona görə nəticə yalnız mikrobun yox,
## BÜTÜN dünyanın 30 Hz-lə pilləli sürüşməsidir — ekranda bu, "ilişmək" kimi
## oxunur. Rəqiblər bu problemi yaşamır: onlar hər kadrda snapshot-lar arasında
## interpolyasiya olunur ([method _render_germs]), yəni 60 Hz-də hamardır.
## Oyunçunun "botlarda hər şey düzgündür, mənimki ilişir" müşahidəsinin
## səbəbi məhz bu fərq idi.
##
## Həll: tick-dən əvvəlki və sonrakı vəziyyət saxlanılır, çəkiliş isə aradakı
## nisbətə görə qarışdırılır. Bunun bir tick-ə qədər (33 ms) görüntü gecikməsi
## var; simulyasiya isə TOXUNULMAZ qalır — yalnız göstərilən nöqtə yumşalır.
var _pos_prev := Vector2.ZERO
var _pos_curr := Vector2.ZERO
var _aim_prev := 0.0
var _aim_curr := 0.0
var _clock := 0.0
var _snaps: Array[Dictionary] = []  ## {"t": lokal vaxt, "d": snapshot}
var _last_snap: Array = []
## [member _last_snap]-ın gəldiyi an və onun topları sonuncu dəfə hansı
## snapshot-dan oxunub (bax [method _render_shots]).
var _last_snap_t := 0.0
var _shots_synced_t := -1.0

## ── Tick saatı və jitter buferi ─────────────────────────────────────────
##
## Snapshot-lar xam GƏLİŞ anı ilə yox, tick-dən çıxan an ilə çəkilir:
## `_floor + tick × TICK_DELTA` ([method _tt]). Əvvəl hər snapshot öz gəliş anı ilə
## interpolyasiya olunurdu və jitter-də rəqib tick-in yarısı qədər qabağa-geriyə
## sürüşürdü: proqnoz topu rəqibi serverin yoxladığı dəqiq tick-də görür
## ([method _ghost_targets]), ekranda isə rəqib başqa yerdə çəkilirdi.
##
## `_floor` gəlişlərin ORTASI yox, ƏN TEZİDİR (gəliş anı − tick vaxtı): gec gələn
## paket — jitter və ya donmadan sonrakı dəstə — onu TƏRPƏTMİR. Əvvəlki orta (0.7 s
## zaman sabiti, 0.25 s-dən böyük fərqdə dərhal köçmə) donmadan sonra gələn dəstədə
## hər ~8 snapshot-da bir köçürdü: anlar dişli mişar kimi düzülür, rəqiblər 15–21
## tick (0.5–0.7 s) GERİYƏ atılırdı (ölçülüb: 1.5 s donmada median 16.5 tick).
## Baza yalnız yavaş qalxır ([constant FLOOR_RISE]) — yol həmişəlik uzananda; enməsi
## isə dərhaldır (Godot uzun kadrda `delta`-nı ~133 ms-də kəsir, saat geri qalır).
##
## Göstərilən an [member _rtick] — rəqiblərin, topların, qidanın və effektlərin
## server tick-i (kəsrli). Serverə gedən görünən tick ([method _view_tick]) da odur:
##   • `_clock − _delay`-i izləyir. [member _delay] son [constant LATE_WINDOW] s-də
##     snapshot-ların bazadan gecikməsinin p95-i + bir tick + ehtiyatdır,
##     [constant Const.INTERP_DELAY]..[constant DELAY_MAX] arasında, yavaş dəyişir;
##   • HEÇ VAXT geri getmir;
##   • ən təzə snapshot-u [constant EXTRAP_MAX]-dan çox keçmir: bufer quruyanda
##     rəqiblər son sürətləri ilə bu qədər irəli çəkilir, sonra DAYANIR;
##   • geridə qalanda (donmadan sonra) SÜRƏTLƏNİB yetişir ([constant CATCHUP_GAIN],
##     ən çox [constant CATCHUP_MAX]×): rəqiblər sıçramır, qısa müddət tez hərəkət edir.
##     Çox geridədirsə ([constant CATCHUP_JUMP]) əvvəl [constant CATCHUP_LEFT] saniyəyə
##     qədər sıçrayır — 4 s-lik donmanı sürətlə oynatmaq 2 s çəkərdi.
const FLOOR_RISE := 0.005
## Bundan çox gecikən snapshot jitter deyil, donmadır: bufer ölçüsünə daxil olmur.
const LATE_STALL := 0.3
const LATE_WINDOW := 3.0
## Gecikmənin yuxarı həddi. Server topu ən çox [constant Const.REWIND_MAX] (0.4 s)
## geri sarır: `RTT/2 + gecikmə` ondan böyük olanda atıcının gördüyü yoxlanmır.
const DELAY_MAX := 0.2
const DELAY_MARGIN := 0.015
## Gecikmə saniyədə ən çox bu qədər dəyişir.
const DELAY_RATE := 0.1
const EXTRAP_MAX := 0.2
## Yetişmə: geriləmə (s) × bu = artıq sürət — 25 ms geridə 1.1×, 0.5 s geridə 3×.
## Qabaqda olanda ən çox 10% yavaşıyır. 1.5 s-lik donmadan sonra ~0.5 s sürətli hərəkət.
const CATCHUP_GAIN := 4.0
const CATCHUP_MAX := 3.0
const CATCHUP_JUMP := 1.5
const CATCHUP_LEFT := 0.75
## Bundan böyük fərq (yeni dünya, yenidən qoşulma) — göstərilən an dərhal köçür.
const RENDER_RESET := 5.0
## Snapshot-lar sayla yox, VAXTLA saxlanılır: göstərilən andan bu qədər əvvəlkilər
## atılır ([method _server_row] ən təzədən ən çox REWIND_MAX geri baxır).
const SNAP_KEEP := 0.6
const SNAP_HARD_MAX := 200
## Zəif bağlantı nişanı: bu qədər snapshot gəlmir və ya təsdiq donursa yanır,
## düzələndən sonra [constant WEAK_HOLD] saniyə qalır (bax [method _watch_net]).
const WEAK_AFTER := 0.4
const WEAK_HOLD := 1.0
## DAVAMLI sürüşmə: yol uzanıb və ya server tick atıb — bundan sonra HƏR snapshot gec gəlir.
## Baza saniyədə cəmi [constant FLOOR_RISE] qalxdığı üçün 0.3 s-lik sürüşmə 30 s, 0.5 s-lik
## 65 s ekstrapolyasiya və donma demək idi (yoxlamada ölçülüb). İndi son [constant REBASE_WINDOW]
## saniyənin ƏN AZ gecikməsi də [constant REBASE_MIN]-dən böyükdürsə, baza dərhal o qədər
## qalxır. Donma dəstəsi bunu işə salmır: dəstənin paketləri eyni anda gəlir (səpələnmə
## [constant REBASE_SPAN]-dan qısadır), ən təzələri isə gecikmir.
const REBASE_WINDOW := 1.5
const REBASE_SPAN := 1.2
const REBASE_MIN := 0.06
const REBASE_SAMPLES := 20

var _tick_base_set := false
## Son [constant REBASE_WINDOW] saniyədə HƏR snapshot-un gecikməsi (donma dəstəsi də daxil).
var _late_all: Array[Vector2] = []
var _floor := 0.0
var _floor_t := 0.0
## Son snapshot-ların bazadan gecikməsi: (gəliş anı, gecikmə).
var _late: Array[Vector2] = []
var _delay := Const.INTERP_DELAY
var _delay_target := Const.INTERP_DELAY
## Göstərilən server tick-i (kəsrli); mənfi — hələ yoxdur.
var _rtick := -1.0
## [member _rtick]-in yerli saatdakı anı (`_floor + _rtick × TICK_DELTA`).
var _rt := -INF
## Göstərilən an ən təzə snapshot-dan nə qədər qabaqdadır (ekstrapolyasiya, s).
var _extra := 0.0
## [member _last_snap]-ın tick saatındakı anı.
var _last_snap_tt := 0.0
var _last_tick_seen := -1
var _batch_stalled := false
## Zəif bağlantı nişanı yanırmı (bax [method _watch_net]).
var weak_net := false
var _weak_until := -INF
var _ack_moved_t := 0.0
var _me_in_snap := false
## Test ölçüləri (bax [method _probe_extra]).
var _pm := {"corr": 0.0, "drain_ms": 0.0, "drained": 0}


## Snapshot tick-inin yerli saatdakı anı; gəlişi bazaya və gecikmə statistikasına yazır.
func _tick_time_of(tick: float) -> float:
	var sample := _clock - tick * Const.TICK_DELTA
	if not _tick_base_set:
		_tick_base_set = true
		_floor = sample
		_floor_t = _clock
		_late.clear()
		_late_all.clear()
		_rtick = -1.0
	_floor = minf(_floor + FLOOR_RISE * maxf(_clock - _floor_t, 0.0), sample)
	_floor_t = _clock
	var late := sample - _floor
	late -= _rebase(late)
	# Donma dəstəsi jitter deyil: buferi böyütməməlidir (bax [method _drain_inbox]).
	if late < LATE_STALL and not _batch_stalled:
		_late.append(Vector2(_clock, late))
	return _floor + tick * Const.TICK_DELTA


## Davamlı sürüşmədə bazanı qaldırır (bax [constant REBASE_WINDOW]); qaldırılan miqdarı qaytarır.
##
## Göstərilən tick ([member _rtick]) dəyişmir — ekrandakı rəqiblər yerindən oynamır. Yalnız
## gecikmə hədəfi yaxınlaşır və göstərilən an ən çox 10% yavaşıyaraq yenidən buferə girir.
func _rebase(late: float) -> float:
	_late_all.append(Vector2(_clock, late))
	while not _late_all.is_empty() and _late_all[0].x < _clock - REBASE_WINDOW:
		_late_all.pop_front()
	if _late_all.size() < REBASE_SAMPLES or _clock - _late_all[0].x < REBASE_SPAN:
		return 0.0
	var m := INF
	for v in _late_all:
		m = minf(m, v.y)
	if m <= REBASE_MIN:
		return 0.0
	_floor += m
	for i in _late_all.size():
		_late_all[i].y -= m
	for i in _late.size():
		_late[i].y = maxf(0.0, _late[i].y - m)
	return m


## Buferdəki snapshot-un anı — HƏMİŞƏ indiki bazadan (tick-ə görə monoton).
func _tt(d: Array) -> float:
	return _floor + float(d[Const.Snap.TICK]) * Const.TICK_DELTA


func _render_time() -> float:
	return _rt


## Göstərilən tick ekstrapolyasiya ilə birlikdə (test probe-u üçün).
func _render_tick() -> float:
	return _rtick


## Gecikmə hədəfi: son [constant LATE_WINDOW] saniyənin p95-i (dəstədən sonra bir dəfə).
func _update_delay_target() -> void:
	while not _late.is_empty() and _late[0].x < _clock - LATE_WINDOW:
		_late.pop_front()
	var lates := PackedFloat32Array()
	for v in _late:
		lates.append(v.y)
	lates.sort()
	var p95 := lates[mini(lates.size() - 1, int(0.95 * lates.size()))] if lates.size() > 0 else 0.0
	_delay_target = clampf(p95 + DELAY_MARGIN + Const.TICK_DELTA, Const.INTERP_DELAY, DELAY_MAX)


## Hər kadr bir dəfə ([method _process]): gecikmə və göstərilən an.
func _advance_render(delta: float) -> void:
	if _snaps.is_empty():
		return
	_delay += clampf(_delay_target - _delay, -DELAY_RATE * delta, DELAY_RATE * delta)
	var want := (_clock - _delay - _floor) / Const.TICK_DELTA
	var newest := float((_snaps[-1]["d"] as Array)[Const.Snap.TICK])
	var cap := newest + EXTRAP_MAX / Const.TICK_DELTA
	var prev := _rtick
	if _rtick < 0.0 or absf(want - _rtick) * Const.TICK_DELTA > RENDER_RESET:
		_rtick = minf(want, cap)
		prev = _rtick
	else:
		var lag := (want - _rtick) * Const.TICK_DELTA
		if lag > CATCHUP_JUMP:
			_rtick = want - CATCHUP_LEFT / Const.TICK_DELTA
			lag = CATCHUP_LEFT
		var rate := 1.0 + clampf(lag * CATCHUP_GAIN, -0.1, CATCHUP_MAX - 1.0)
		_rtick += delta * rate / Const.TICK_DELTA
	_rtick = clampf(_rtick, prev, maxf(cap, prev))
	_rt = _floor + _rtick * Const.TICK_DELTA
	_extra = maxf(0.0, _rtick - newest) * Const.TICK_DELTA


## Bağlantı ilişib: snapshot [constant WEAK_AFTER] saniyədir gəlmir, və ya server
## girişləri o qədər vaxtdır təsdiqləmir (yuxarı istiqamət ilişib). Geri sayımda və
## mikrob dünyada olmayanda giriş onsuz da təsdiqlənmir — o hal sayılmır.
func _link_stalled() -> bool:
	if _local_world != null or _snaps.is_empty():
		return false
	if _clock - _last_snap_t > WEAK_AFTER:
		return true
	return _phase == Const.Phase.PLAYING and _me_in_snap and _clock - _ack_moved_t > WEAK_AFTER


## Zəif bağlantı nişanı ([method Hud.set_weak_net]). Oyun "dondu" görünməsin —
## oyunçu səbəbin şəbəkə olduğunu bilsin. Düzələndən sonra [constant WEAK_HOLD] qalır.
func _watch_net() -> void:
	var weak := false
	if not _finished and not _reconnecting:
		if _link_stalled():
			_weak_until = _clock + WEAK_HOLD
		weak = _clock < _weak_until
	if weak != weak_net:
		weak_net = weak
		_hud.set_weak_net(weak)


func _probe_extra() -> String:
	var s := "%.0f|%.0f|%.1f|%d|%.1f|%d|%.1f|%d" % [_extra * 1000.0, _delay * 1000.0, _pm["corr"],
		int(_pm["drained"]), float(_pm["drain_ms"]), 1 if weak_net else 0, _corr_off.length(), _srv_rep]
	_pm["corr"] = 0.0
	_pm["drained"] = 0
	_pm["drain_ms"] = 0.0
	return s


var _finished := false

## Mikroba qayıtmaq üçün sessiya nişanı — serverdən dünyaya girəndə gəlir.
var _token := ""
var _reconnecting := false
var _rejoin_left := 0

## Yalnız məşq rejimində — serverin [World]-u. Tipsizdir və `load` ilə yaradılır:
## tipli istinad `World`-u (və onunla [Bot]-u) onlayn oyunda da, klientin
## açılışında da kompilyasiya etdirərdi (bax [constant WORLD_SCRIPT]).
var _local_world = null
## Menyu onu fonda əvvəlcədən yükləyir ([method MenuV2._preload_arena]).
const WORLD_SCRIPT := "res://scripts/server/world.gd"

# ---------------------------------------------------------------- vizual

var _cam: Camera2D
var _blobs: Node2D
var _food_layer: Node2D
var _shot_layer: Node2D
## Nişan xətti və avtomatik nişanın kilidi (bax [AimGuide]).
var _aim_guide: AimGuide
var _entities: Node2D
var _fx: Node2D
## Qısa effektlərin hamısını üç batch çağırışında saxlayan ortaq qat.
## Hadisə başına node yaratmaq pik döyüşdə çağırış sayını hadisə ilə böyüdürdü.
var _juice: JuiceFx
var _trails: ShotTrails
## Maneə sprite-ları — indeks [method DishMap.obstacles] ilə eynidir, ona görə
## dağılan divarı serverin göndərdiyi indekslə tapmaq olur. Bərk növdə bu,
## qalxan gövdədir; kol və cərəyanda yastı bazadır.
var _blob_nodes: Array[Sprite2D] = []
## Bərk maneələrin kölgəsi və kövrəyin qalıcı qırıntısı (indeks -> Sprite2D).
## Ayrı sprite-dır: kölgə döşəmədə qalır, gövdə titrəyəndə o titrəmir; qırıntı
## isə yastı qatdadır — qalxan gövdələrin cənub üzünü örtməməlidir.
var _shadow_nodes := {}
var _rubble_nodes := {}
## Kolun üst yarpaq qatı — mikrobların üstündə çəkilir (bax [method _build_world]).
var _canopy: Node2D
## Üst yarpaqların node-ları, indeks [method DishMap.obstacles] ilə eynidir.
var _canopy_nodes := {}
## Cərəyan deşiyinin fırlanan İÇ qatı. Baza sabit qalır ki, mənfi hündürlüyün
## yuxarı-sol daxili kölgəsi qlobal işıqla ziddiyyətə düşməsin.
var _vent_swirl_nodes: Array[Sprite2D] = []
## Dağılmış maneələr (serverin sözü).
var _broken := PackedByteArray()

## Xəritənin qatları, altdan yuxarı (bax [method _build_world]): qabın bayırı
## bu node-un öz `_draw`-ındadır, sonra döşəmə, şəbəkə, quruyan zona, şimal
## şüşə divarı. Dalğalar maneələrlə qida arasında, cənub dodağı mikrobların
## və yarpaqların üstündə.
var _ground: Node2D
## Qabın bayırındakı bulanıq koloniyalar (bax [method _spawn_props]).
var _props: Node2D
var _prop_nodes: Array[Sprite2D] = []
var _grid: Node2D
var _dry: Node2D
var _rim: Node2D
var _ripples: Node2D
var _lip: Node2D
var _backdrop: ArrayMesh
var _rim_mesh: ArrayMesh
## Döşəmə və divar teksturalarını arena ÖZÜ tutur: çəkiliş əmri yalnız RID
## saxlayır, istinadı heç kim tutmasa tekstura azad olunur və GPU ağ
## standart teksturanı çəkir (bax [method MapKit.release]).
var _floor_tex: Texture2D
var _rim_tex: Texture2D
var _lip_mesh: ArrayMesh
## Kolların siyahısı (x, y, radius, indeks) — topun yarpaq üstünə çıxması və
## xışıltı üçün. Top onu birbaşa gəzmir, öz xanasındakı kolları oxuyur
## (bax [member _bush_grid]).
var _bush_list: Array[Vector4] = []
## Döşəmə bəzəyi: [{"node", "at", "r", "base", "pop"}] — top üstündən keçəndə
## sıçrayır. Hər kadr hər top üçün 46 parçanı gəzmək GDScript-də ölçülən iş idi
## (masaüstündə +0.1 ms proses, zəif telefonda ~10 dəfə çox), ona görə parçalar
## 128 px-lik şəbəkə xanalarına yığılıb: top yalnız öz xanasına baxır.
var _clutter: Array[Dictionary] = []
var _clutter_grid := {}             ## Vector2i xana -> Array[int] parça indeksləri
var _clutter_popping: Array[int] = []
## Kolların eyni xanalara yığılması: Vector2i xana -> Array[int] ([member _bush_list]
## indeksi). Topların çoxu heç bir kolun yanında deyil — xanası boşdur.
var _bush_grid := {}
## Dalğa və sıçrantı sprite-larının hovuzu (bax [method _ripple]).
var _ripple_pool: Array[Sprite2D] = []
var _ripple_live: Array[Dictionary] = []
## Şüşə dodaqda parıltılar: [{"angle", "t"}] (bax [method _glint]).
var _glints: Array[Dictionary] = []
## Kolun içindəki toplar: top açarı -> Vector2(kol indeksi, son görülmə anı).
var _shot_bushes := {}
var _shot_bushes_swept := 0.0
var _motes: WaterMotes
## Dərin su qatı — maneələrin üstündə, qidanın altında (bax [method _build_world]).
var _motes_deep: WaterMotes
var _hud: Hud
## Öz mikrobunun altındakı top zolağı (bax [AmmoBar]).
var _ammo: AmmoBar
## Bioluminessensiya mühiti — keyfiyyətdən asılı olaraq yandırılır/söndürülür
## (bax [method _apply_quality]).
var _glow: WorldEnvironment

var _visuals := {}                  ## germ id -> {"node": GermVisual, "seen": float}

## Ad və rəng cədvəli — `{id: [ad, rəng]}` (bax [method Net.on_roster]).
##
## Snapshot-da daşınmır: sabit dəyərləri saniyədə 30 dəfə göndərmək paketi
## MTU-dan yuxarı qaldırırdı.
var _roster := {}
var _roster_rev := -1
var _food_views := {}               ## food id -> {"node": Sprite2D, "seen": float}

## Sprite HOVUZLARI — qida və toplar üçün.
##
## Partlayan mikrob BİR kadrda 24-ə qədər qida yaradır
## (bax [method Sim._burst]) və client həmin kadrda 24 dəfə `Sprite2D.new()`
## + `add_child` çağırırdı. Ölçülüb: 25 saniyəlik oyunda 2-3 kadr 60 FPS
## büdcəsini aşırdı, ən pisi 68 ms — masaüstündə görünmür (orta 1.9 ms),
## telefonda isə açıq "ilişmə"dir.
##
## Hovuz yaratmanı sıfıra endirir: node bir dəfə qurulur, sonra gizlədilib
## təkrar işlədilir. Qat başına ayrı hovuz var ki, valideyn dəyişməsin —
## `reparent` özü də ucuz deyil.
var _food_pool: Array[Sprite2D] = []
var _shot_pool: Array[Sprite2D] = []
var _shot_views := {}               ## shot id -> Dictionary
## Öz toplarının proqnozu — serveri gözləmədən uçur və dəyir (bax [ShotPrediction]).
var _own_shots := ShotPrediction.new()
## Proqnoz topunun sprite-ı: ghost id -> Sprite2D (eyni [member _shot_pool]-dan).
var _ghost_nodes := {}
## Proqnozla birləşmiş server toplarının id-si -> birləşmə anı.
##
## Snapshot yalnız ən yaxın topları daşıyır və sıx döyüşdə öz topun bir-iki
## paketdən düşüb geri qayıda bilir. Görüntüsü o arada silinir; bu siyahı
## olmasa qayıdan top "yeni" sayılıb proqnozun yanında ikinci dəfə çəkilərdi.
var _own_sids := {}
## Proqnozun gördüyü, serverin hələ təsdiqləmədiyi təmaslar:
## `{"pos", "t", "hit": bool}` (bax [method _match_claim]).
var _claims: Array[Dictionary] = []
## Öz topunun son dəydiyi qurbanlar: rəng indeksi -> saat (bax [constant KILL_LINK]).
var _my_victims := {}
## Gediş-gəliş vaxtının hamar təxmini (s): girişin göndərilməsindən onu
## təsdiqləyən snapshot-un gəlişinə qədər. Server tick-ini gözləmə də daxildir.
var _rtt := 0.15
## Son saniyələrin ən aşağı gediş-gəlişi (bax [method _congested]).
var _rtt_floor := INF
var _rtt_floor_t := 0.0
## [member _rtt_floor] saniyədə bu qədər qalxır — uzun sürən yeni gecikmə yalnız
## yarım dəqiqədən sonra "adi" olur. Ölçülüb: 0.02 s/s-də 20 saniyəlik sıxılma
## (təsdiq 400–720 ms) bir neçə saniyəyə "adi" sayılırdı və dəymələr yenə əmin
## göstərilirdi.
const RTT_FLOOR_RISE := 0.005
## Gediş-gəliş ən aşağısından bu qədər (və ən azı yarısı qədər) uzundursa, şəbəkə sıxılıb.
const RTT_SPIKE := 0.08
## Botların rəngləri — reyestrdən (bax [method _on_roster]). Çəkiliş bundan asılı
## deyil (top öz geri sarmasını daşıyır); ölçmə alətləri insanın topunu ayırmaq
## üçün işlədir (bax [HitProbe]).
var _bot_colors := {}
## Öz mikrobuna proqnozlaşdırılmış dəymələr: `{"pos", "t", "color", "sid", "soft", "lead"}`,
## rəng ATANINDIR
## (bax [method _remote_shot_pos]).
var _self_claims: Array[Dictionary] = []
## Öz topunun proqnozdan əvvəl gələn server dəymələri: `{"pos", "t", "victim"}`.
var _early_hits: Array[Dictionary] = []
## Hər girişin göndərildiyi an: seq -> saat. Serverin FIRE hadisəsindən öyrənilən
## atəşin topu məhz bu andan uçmağa başlayır (bax [method _spawn_own_shot]).
var _input_time := {}
## Son snapshot-un təsdiqlədiyi giriş — həmin tick-də emal olunan giriş.
var _last_ack := 0
## Super halqasının vədi — dəymənin +3-ü serveri gözləmədən görünür.
var _charge_promise := -1
var _charge_base := 0
var _charge_until := 0.0

## Proqnozun serverlə nə qədər üst-üstə düşdüyü — oyuna təsiri yoxdur, şəbəkə
## testi oxuyur ([AutoClient]). `predicted` — ekranda göstərilən öz dəymələrin,
## `confirmed` — serverin sonra təsdiqlədikləri, `server_only` — proqnozun
## görmədiyi, amma serverin saydığı dəymələr; `ghost` — ekranda göstərilib
## serverin heç vaxt saymadıqları; `confirm_s` — təsdiqin cəmi gecikməsi.
var hit_stats := {"predicted": 0, "confirmed": 0, "server_only": 0, "ghost": 0,
	"confirm_s": 0.0, "ghost_gone": 0, "lines": 0, "line_off_sum": 0.0, "line_off_max": 0.0, "miss": [],
	"self_pred": 0, "self_conf": 0, "self_false": 0,
	"self_soft": 0, "self_soft_conf": 0, "self_soft_miss": 0, "self_undo": 0,
	"own_soft": 0, "own_soft_conf": 0, "own_soft_miss": 0, "own_soft_undo": 0}
var _fx_queue: Array[Dictionary] = []
## Proqnozun oynatdığı öz superlərinin anları — serverin hadisəsini gözləyir
## (bax [method _take_own_super]).
var _own_supers: Array[float] = []
var _tex := {}
var _view_span := Const.VIEW_SPAN_BASE
## Kameranın gördüyü dünya düzbucaqlısı — ekrandan kənardakı mikrobu çəkməmək
## üçün (bax [member GermVisual.on_screen]). Kamera qurulana qədər bütün dünya.
var _view_rect := Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6)
## Minixəritənin növbəti yenilənməsinə qalan vaxt (bax [method _update_minimap]).
var _minimap_wait := 0.0
var _shake := 0.0
## Təsadüfi silkələnmədən ayrı istiqamətli kamera təpiyi.
## Ayrı saxlanır ki, zərbənin haradan gəldiyi random titrəyişdə itməsin.
var _kick := Vector2.ZERO

## Serverdən gələn matç vəziyyəti (bax [enum Const.MF]).
##
## Qabın kənarı BURADAN gəlir, düsturla hesablanmır: faza keçidləri saatı
## sıfırlayır və client-in öz saatı serverdən bir neçə tick geri qala bilər.
## Bir float göndərmək həmin riski büsbütün silir.
var _mode := Const.Mode.ENDLESS
var _phase := Const.Phase.PLAYING
var _phase_t := 0.0
var _wet_radius := Const.WORLD_RADIUS
var _alive := 0
var _place := 0
## Baxanın komandası (-1 komandasız) — serverdən gəlir (bax [enum Const.MF]).
var _my_team := -1
var _score_us := 0
var _score_em := 0

## ── Zərbə hissi ──────────────────────────────────────────────────────────

## Donmuş kadr: öldürmə anında ekran bir anlıq DAYANIR.
##
## YALNIZ görüntü donur — kamera və mikrob animasiyaları. Simulyasiya,
## proqnoz və şəbəkə tam sürətlə işləməyə davam edir.
##
## `Engine.time_scale` ilə donduran variant QƏSDƏN seçilməyib: o, `_process`
## deltasını da kiçildir, yəni proqnoz tick-ləri yavaşıyır və serverə daha az
## giriş gedir. Server isə 30 Hz-lə işləməyə davam edir — nəticədə client geri
## qalır və donma bitəndə düzəliş mikrobu sıçradır. Yəni zərbə hissi üçün
## qoyulan effekt öz zərbəsini yeyərdi.
const FREEZE_TIME := 0.075
var _freeze := 0.0

## Kamera zərbəsi — partlayış anında görüntü bir anlıq YAXINLAŞIR.
##
## Silkələnmə (bax [member _shake]) hadisənin OLDUĞUNU deyir, zərbə isə
## onun BÖYÜKLÜYÜNÜ. İkisi birlikdə işləyir: silkələnmə mövqeyə, zərbə
## miqyasa toxunur, ona görə bir-birini pozmurlar.
var _punch := 0.0

## Öz tutumun — artımı tutmaq üçün saxlanılır (bax [method _watch_capacity]).
## Hadisə ilə gəlmir: tutum artımı snapshot-dakı sahədir, ayrıca hadisə deyil.
var _last_cap := 0

## Öz mikrobun kolun içindədirmi (bax [method _watch_bush]).
var _hidden := false
## İçində olduğumuz kolun indeksi — giriş və çıxış dalğası həmin fronda gedir.
var _bush_index := -1
## Görünən rəqib id-si -> kol indeksi. Xışıltı yalnız öz mikrobuna bağlanmır.
var _germ_bushes := {}
## Kol indeksi -> xışıltının başlama vaxtı. Daimi Tween əvəzinə bir dövrdə hesablanır.
var _bush_rustles := {}
## "Gizləndin" yazısı artıq göstərilibmi.
var _bush_taught := false


# ================================================================ quraşdırma

## Serverdən "dünyaya girdin" mesajı gələndə çağırılır. add_child-dan ƏVVƏL.
func configure_online(info: Dictionary) -> void:
	practice = false
	my_id = int(info["you"])
	my_color = int(info.get("color", 0))
	Net.species = _species_from(info)
	_token = str(info.get("token", ""))


## Serverin təsdiqlədiyi növ.
##
## Menyudakı seçim TƏKLİFDİR, son söz serverindir: yenidən qoşulanda oyunçu
## köhnə mikrobuna qayıdır və onun növü artıq dünyada qeydə alınıb.
## Etibarsız dəyər gəlsə kirpikliyə düşür.
static func _species_from(info: Dictionary) -> Const.Species:
	return Const.species_from(int(info.get("species", 0)))


## Şəbəkəsiz məşq. Eyni [World] və [Sim] kodu yerli işləyir — fərq yalnız
## snapshot-ların şəbəkədən yox, yaddaşdan gəlməsidir.
## Məşqdə mikrobun doğuş yeri. `Vector2.INF` = adi (təsadüfi) doğuş.
##
## YALNIZ yoxlama üçündür (`--at x,y`). Xəritənin bir hissəsini gözlə görmək
## üçün başqa yol yoxdur: doğuş təsadüfidir, kol və cərəyan deşiyi isə
## dünyanın müəyyən yerlərindədir, ona görə "kolun içi necə görünür"
## sualına ekran görüntüsü ilə cavab vermək təsadüfə qalırdı.
var start_at := Vector2.INF

## Məşqdə super DOLU başlayır. YALNIZ yoxlama üçündür (`--charge`), bax
## `boot.gd` (`_start_practice`).
var start_charged := false


func configure_practice() -> void:
	practice = true
	my_id = 1000
	_local_world = load(WORLD_SCRIPT).new(1, Net.mode)
	var g: Sim.GermState = _local_world.add_player(my_id, Net.nickname, Net.species)
	my_color = g.color
	if start_at.is_finite():
		g.pos = start_at
		g.vel = Vector2.ZERO
	if start_charged:
		g.charge = Const.SUPER_MAX


## ── Uzun kadr ────────────────────────────────────────────────────────────
##
## Godot kadrın `delta`-nı `max_physics_steps_per_frame / physics_ticks_per_second`-də
## (8 / 60 = 133 ms) KƏSİR: 500 ms-lik kadrdan sonra `delta` 137 ms gəlir (ölçülüb), yəni
## telefonun hər ilişməsində client-in saatı geri qalırdı. Oyunçunun o tick-lərinin girişi
## heç göndərilmirdi — server həmin tick-ləri sonuncu girişlə TƏXMİN edirdi, proqnoz
## düzəlirdi, rəqiblərin zaman xətti də sıçrayırdı. Oyunda fizika qovşağı yoxdur, ona görə
## hədd [constant LONG_FRAME] saniyəyə qaldırılır və bir kadrda [constant TICKS_PER_FRAME]
## tick-ə qədər işlənir. Məşqdə tick bütün dünyanı hesablayır — orada köhnə hədd qalır.
const LONG_FRAME := 0.5
const TICKS_PER_FRAME := 15
const TICKS_PER_FRAME_PRACTICE := 5


func _ready() -> void:
	Engine.max_physics_steps_per_frame = maxi(Engine.max_physics_steps_per_frame,
		ceili(LONG_FRAME * Engine.physics_ticks_per_second))
	_build_glow()
	_load_textures()
	_build_world()
	_build_hud()
	_init_prediction()
	# Zərrəciklər və "şirə" effektləri [method _build_world]-də yaranır, ona
	# görə keyfiyyət ONDAN SONRA tətbiq olunur — mühit isə artıq hazırdır.
	_apply_quality()
	# Oyunçu matçın içində ayarları aça bilir; keyfiyyət dəyişsə, ekran elə
	# həmin kadrda cavab verməlidir.
	Settings.changed.connect(_apply_quality)

	Net.snapshot_arrived.connect(_on_snapshot)
	Net.roster_arrived.connect(_on_roster)
	Net.you_burst.connect(_on_you_burst)
	Net.server_disconnected.connect(_on_server_lost)
	Net.connected_to_server.connect(_on_reconnected)
	Net.world_joined.connect(_on_rejoin_accepted)
	Net.rejoin_failed.connect(_on_rejoin_rejected)

	# Öyrədici mesajdır — ilk bir neçə girişdə (bax [constant Settings.TIP_SHOWS]).
	if Settings.tip_due("enter"):
		Settings.tip_shown("enter")
		_hud.show_message("DÜNYAYA GİRDİN", "Qida ye, rəqibi doldur, partlat")
		get_tree().create_timer(2.0).timeout.connect(_hud.hide_message)
	Sfx.play("spawn")
	# Menyusuz açılışda (məşq, test client-i) brauzerin yükləmə örtüyü buradan götürülür.
	Settings.web_page_ready()
	# Menyudan gəlibsə — "Matç hazırlanır…" örtüyü (bax [method MenuV2._enter_arena]).
	Settings.web_hide_prep()
	# Menyudan gəlməyibsə, mikrobun shader-ləri hələ kompilyasiya olunmayıb (bax
	# [method GermGPU.warm_up]); menyudan gəlibsə bu çağırış heç nə etmir.
	GermGPU.warm_up(self)


## Bioluminessensiya — parlaq piksellər ətrafa işıq saçır.
##
## `gl_compatibility` renderer-ində DƏ işləyir, amma iki şərtlə:
##   1. `rendering/viewport/hdr_2d` açıq olmalıdır (bax `project.godot`),
##      yoxsa rənglər 1.0-da kəsilir və hədd heç vaxt keçilmir;
##   2. hədd 1.0-dan AŞAĞI olmalıdır, çünki oyunun bütün rəngləri
##      `Palette`-də ≤ 1.0-dır — heç nə HDR diapazonuna çıxmır.
##
## Hədd 0.62 seçilib: mikrob rəngləri (ən parlaq komponenti 1.0) və qida
## saçır, qabın döşəməsi (0.05) və şəbəkə isə toxunulmaz qalır. Yəni fon
## bulanmır — yalnız CANLI olan şeylər işıq verir.
func _build_glow() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_hdr_threshold = 0.62
	env.glow_intensity = 1.15
	env.glow_strength = 1.20
	env.glow_bloom = 0.14
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	_glow = WorldEnvironment.new()
	_glow.environment = env
	add_child(_glow)


## Keyfiyyət ayarını DƏRHAL tətbiq edir — matçın ortasında da.
##
## Əvvəl bu, yalnız qurulma vaxtı oxunurdu: `WorldEnvironment` AŞAĞI-da
## ümumiyyətlə yaradılmırdı, ona görə oyunçu ayarı matçda dəyişəndə ekranda
## heç nə olmurdu və növbəti matça qədər gözləmək lazım gəlirdi. Kəsmə yaşayan
## oyunçu isə düzəlişi ELƏ İNDİ istəyir.
##
## İndi mühit həmişə qurulur, glow isə yandırılıb-söndürülür. Sönülü glow
## praktiki olaraq pulsuzdur; onunla birlikdə HDR kadr buferi də söndürülür,
## yoxsa RGBA16F format heç nəyə xidmət etmədən hər kadr iki dəfə çox yaddaş
## zolağı yeyər — mobil GPU-da bu, ən böyük tək xərcdir.
func _apply_quality() -> void:
	var low := Const.is_light(int(Net.quality))
	var minimum := Net.quality == Const.Quality.MINIMUM
	# Mikrobların detal səviyyəsi dərhal dəyişir (bax [member GermVisual.lod]).
	for gid in _visuals:
		(_visuals[gid]["node"] as GermVisual).lod = 1 if minimum else 0
	get_viewport().use_hdr_2d = not low
	if _glow != null:
		_glow.environment.glow_enabled = not low
	if _juice != null:
		_juice.setup(low)

	# Zərrəcik sıxlığı da keyfiyyətdən asılıdır: onlar oyuna təsir etmir,
	# yalnız suyun canlı görünməsi üçündür — ilk kəsiləcək şey budur.
	if _motes_deep != null:
		_motes_deep.count = (12 if minimum else 34) if low else 80
		_motes_deep.rebuild()
	if _motes != null:
		_motes.count = (8 if minimum else 14) if low else 30
		# Cərəyan axını yalnız YÜKSƏK-dədir və ayrıca node deyil: deşiyə
		# sorulan cizgilər səth zərrəciklərinin mövcud multiline batch-inə
		# qoşulur.
		var sinks := PackedVector3Array()
		if not low:
			for o in DishMap.obstacles():
				if int(o.w) == DishMap.Kind.VENT:
					sinks.push_back(Vector3(o.x, o.y, o.z))
		_motes.sinks = sinks
		_motes.rebuild()


## Xəritənin özü (döşəmə, maneələr, divar) burada deyil — [MapKit]-in
## atlasındadır (bax [method _build_world]).
##
## `preload`: teksturalar skriptlə birlikdə yüklənir — menyu arenanı fonda
## yükləyəndə (bax `MenuV2._preload_arena`) onlar da hazırdır, keçid kadrında
## disk oxunmur.
func _load_textures() -> void:
	_tex = {
		"food": preload("res://assets/sprites/food_ball.svg"),
		"shot": preload("res://assets/sprites/shot_comet.svg"),
		"spark": preload("res://assets/sprites/spark.svg"),
		"burst": preload("res://assets/sprites/burst.svg"),
		"stick_base": preload("res://assets/ui/joystick_base.svg"),
		"stick_knob": preload("res://assets/ui/joystick_knob.svg"),
	}


## Səhnə qatları QƏSDƏN növlərə ayrılıb: bütün qida sprite-ları bir qatda,
## bütün toplar başqasında, mikroblar üçüncüsündə.
##
## Səbəb çəkiliş çağırışıdır: Godot yalnız ARDICIL və eyni teksturalı
## elementləri bir çağırışa yığır. Hamısı bir node-un altında qarışıq
## dursaydı, hər qida topu ayrıca çağırış olardı.
func _build_world() -> void:
	# QABIN BAYIRI bu node-un öz `_draw`-ındadır (bax [method _draw]) — uşaqlardan
	# əvvəl çəkilir, yəni hər şeyin altındadır. Bulanıq koloniyalar onun üstündə,
	# döşəmədən əvvəl: hamısı qabın xaricindədir, döşəmə ilə üst-üstə düşmür.
	_build_backdrop()
	_floor_tex = MapKit.floor_texture()
	_rim_tex = MapKit.rim_texture()
	_props = Node2D.new()
	_props.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_props)
	_spawn_props()

	# DÖŞƏMƏ ayrıca node-dur və şeyderlə çəkilir: makro ton × tikişsiz detal
	# (bax `shaders/map_floor.gdshader`). Arenanın öz `_draw`-ında qalsaydı,
	# şeyder arenanın bütün primitivlərinə tətbiq olunardı.
	_ground = Node2D.new()
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = preload("res://shaders/map_floor.gdshader")
	floor_mat.set_shader_parameter("detail", MapKit.detail_texture())
	floor_mat.set_shader_parameter("detail_world", MapKit.detail_world())
	_ground.material = floor_mat
	add_child(_ground)
	_ground.draw.connect(_draw_ground)

	# Şəbəkə statikdir və bir dəfə çəkilir; quruyan zona isə snapshot ritmində
	# nəbz vurur. Ayrı node-lardır: əvvəl hamısı bir `_draw`-da idi və matçlı
	# rejimdə hər snapshot-da döşəmə, şəbəkə və divar da yenidən qurulurdu.
	# Quruyan zona döşəmənin ÜSTÜNDƏ olmalıdır — arenanın `_draw`-ında qalsaydı
	# döşəmə node-u onu örtərdi (critique B5).
	_grid = Node2D.new()
	add_child(_grid)
	_grid.draw.connect(_draw_grid)
	_dry = Node2D.new()
	add_child(_dry)
	_dry.draw.connect(_draw_dry)

	# ŞİMAL ŞÜŞƏ DİVARI — qabın bayırına, yuxarı uzanır (bax [method _build_rim]).
	_rim = Node2D.new()
	_rim.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_rim.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_rim)
	_build_rim()
	_rim.draw.connect(_draw_rim)

	# Maneələr — kölgə, yastı baza, burulğan və qalxan gövdələr BİR atlasdan,
	# BİR çəkiliş çağırışında (bax [MapKit]). Atlas mipmap-lıdır: R 34-lük daş
	# 192 teksteli hüceyrədən 10 dəfəyə qədər kiçilir.
	_blobs = Node2D.new()
	_blobs.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_blobs)
	_spawn_obstacles()

	# Suda asılı zərrəciklər — qabın döşəməsi ilə oyun obyektləri arasındakı
	# "su" qatı. Sırası MƏHZ buradadır: bu node-un öz `_draw`-ı (döşəmə) və
	# maneələr artıq çəkilib, qida ilə mikroblar isə sonra əlavə olunur.
	# İKİ dərinlik qatı — su bir qat deyil, SÜTUNDUR.
	#
	# Dərin qat maneələrin dərhal üstündədir və sönükdür; səth qatı isə
	# qidanın altında qalır, amma parlaqdır. Aralarındakı sürət fərqi
	# parallaks verir və dərinlik hissi elə buradan gəlir.
	#
	# Zərrəcik sayı ARTMIR (110 ikiyə bölünür), ona görə əlavə yük yalnız
	# ikinci  çağırışıdır.
	# Sıxlıq və cərəyan cizgiləri [method _apply_quality]-də verilir: eyni
	# dəyərlər matçın ortasında ayar dəyişəndə də lazımdır, iki yerdə
	# saxlansaydı biri unudulardı.
	_motes_deep = WaterMotes.new()
	_motes_deep.depth = 1.0
	add_child(_motes_deep)

	_motes = WaterMotes.new()
	add_child(_motes)

	# Su dalğaları və sıçrantılar — suyun səthindədir: maneələrin və
	# zərrəciklərin üstündə, qida və mikrobların altında. Mikrobun üstünə
	# düşən halqa onu örtərdi (JuiceFx bütün mikrobların üstündədir, z 4).
	_ripples = Node2D.new()
	_ripples.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_ripples)

	_food_layer = Node2D.new()
	add_child(_food_layer)

	# İzlər toplardan ƏVVƏL əlavə olunur: arxada qalmalıdırlar.
	_trails = ShotTrails.new()
	add_child(_trails)

	_shot_layer = Node2D.new()
	add_child(_shot_layer)

	# Nişan xətti döşəmədə uzanır, mikrobların ALTINDA — Brawl Stars-dakı kimi.
	# Üstdə olsaydı, nişan alınan rəqibi örtərdi.
	_aim_guide = AimGuide.new()
	add_child(_aim_guide)

	_entities = Node2D.new()
	add_child(_entities)

	# KOLUN ÜST YARPAQLARI — mikrobların ÜSTÜNDƏ.
	#
	# Dərinliyin ən güclü işarəsi rəng deyil, ÖRTÜLMƏDİR. Kolun içindəki mikrob
	# indiyə qədər kolun üstündə dayanırdı: gizlənmə qaydası yalnız serverdə
	# mövcud idi, ekranda isə heç nə onu demirdi. İndi frondlar mikrobun
	# üstündən keçir və "nəyinsə altındayam" izahsız oxunur.
	#
	# Effektlərdən ƏVVƏLdir: partlayış və qığılcım yarpaqların da üstündə
	# olmalıdır, yoxsa kolda baş verən ölüm yarımçıq görünür.
	#
	# z 2 ŞƏRTDİR. Əvvəl qat z 0-da idi, [GermVisual] isə özünə 1 (rəqib) və 2
	# (öz mikrobun) yazır: z ağac sırasından ƏVVƏL gəlir, yəni yarpaqlar bu
	# yazıya baxmayaraq mikrobun ALTINDA çəkilirdi (MAP_25D F1). z 2 + ağacda
	# `_entities`-dən sonra = hər iki mikrobun üstündə, effektlərin (z 3–4) altında.
	# Kola girən topun yarpaq üstünə çıxması ayrıca yazılır (bax [method _layer_shots]).
	_canopy = Node2D.new()
	_canopy.z_index = 2
	_canopy.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_canopy)
	_spawn_canopy()

	# CƏNUB DODAĞI — qabın yaxın şüşə divarının üstü, mikrobların və yarpaqların
	# ÜSTÜNDƏ (bax [method _build_rim]). Cənub kənarına sıxılan mikrob "şüşənin
	# arxasında" görünür — Brawl Stars-ın kənar divarları kimi.
	_lip = Node2D.new()
	_lip.z_index = 2
	add_child(_lip)
	_lip.draw.connect(_draw_lip)

	_fx = Node2D.new()
	add_child(_fx)
	_juice = JuiceFx.new()
	_juice.setup(Const.is_light(int(Net.quality)))
	_fx.add_child(_juice)

	# Effektlərdən SONRA: eyni z-də (4) olsalar da partlayış qığılcımı öz sayını örtməsin.
	_ammo = AmmoBar.new()
	_ammo.visible = false
	add_child(_ammo)

	_cam = Camera2D.new()
	_cam.enabled = true
	add_child(_cam)


## Maneələri qurur — hamısı [MapKit] atlasından, BİR çəkiliş çağırışında.
##
## Sıra altdan yuxarı:
##   1. döşəmə bəzəyi (yastı, konturu yox — bax [method _spawn_clutter]);
##   2. bərk maneələrin kölgəsi — HAMISI əvvəl: heç bir kölgə qonşu maneənin
##      gövdəsinin üstünə düşmür;
##   3. yastı növlər: kol döşəyi, cərəyan dəliyi, kövrəyin (hələ gizli) qırıntısı;
##   4. cərəyanın fırlanan burulğanı;
##   5. qalxan gövdələr (selik, kövrək) ŞİMALDAN CƏNUBA: kamera cənubdan
##      baxır, cənubdakı gövdə şimaldakının üstündə olmalıdır (Spiral
##      düzümündə qonşular 40 px-ə qədər üst-üstə düşür).
## Hamısı eyni teksturadır, ona görə bu növbə batch-i bölmür.
##
## Maneələr FIRLADILMIR — və bu, unudulma deyil. Əvvəl hər ləkə `(x + y) * 0.01`
## radian fırladılırdı; ölçü yüzlərlədir, yəni bucaq faktiki təsadüfi idi və
## sprite-a bişmiş işıq da fırlanırdı: 26 maneənin hər birində işıq başqa
## tərəfdən gəlirdi. Naxış variasiyası EYNİ işıqlı ayrı hüceyrə ilə verilir
## (bax [method MapKit.base_name]).
##
## Hər sprite-a ayrıca `modulate` verilmir. README-nin köhnə ölçüsü (131 → 242
## çağırış) bunu batch-i qıran səbəb sayırdı; Godot 4.7-nin GLES3 mənbəyi isə
## modulate-i instansiya başına saxlayır (MAP_25D F2). Yenə də ehtiyac yoxdur:
## rəng fərqi atlasın öz hüceyrələrindədir.
func _spawn_obstacles() -> void:
	var list := DishMap.obstacles()
	_blob_nodes.resize(list.size())
	_spawn_clutter(list)

	for i in list.size():
		var o: Vector4 = list[i]
		if not MapKit.casts_shadow(int(o.w)):
			continue
		var shadow := MapKit.sprite(MapKit.cell_name("shadow", o.z), o.z)
		shadow.position = Vector2(o.x, o.y)
		_blobs.add_child(shadow)
		_shadow_nodes[i] = shadow

	for i in list.size():
		var o: Vector4 = list[i]
		match int(o.w):
			DishMap.Kind.BRITTLE:
				# Qırıntı əvvəlcədən qurulur və gizlənir: dağılanda yalnız
				# görünürlük dəyişir, yeni node yaranmır.
				var rubble := MapKit.sprite(MapKit.cell_name("brittle_rubble", o.z), o.z)
				rubble.position = Vector2(o.x, o.y)
				rubble.visible = false
				_blobs.add_child(rubble)
				_rubble_nodes[i] = rubble
			DishMap.Kind.BUSH:
				_blob_nodes[i] = _obstacle_sprite(o)
				_grid_add(_bush_grid, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS,
					_bush_list.size())
				_bush_list.append(Vector4(o.x, o.y, o.z, float(i)))
			DishMap.Kind.VENT:
				_blob_nodes[i] = _obstacle_sprite(o)

	# Cərəyanın mənfi hündürlüyü baza hüceyrəsindədir, hərəkəti isə AYRI iç
	# qatdadır: deşiyin yuxarı-sol daxili kölgəsi qlobal işıqla mismarlanır,
	# yalnız burulğan fırlanır.
	for i in list.size():
		var o: Vector4 = list[i]
		if int(o.w) != DishMap.Kind.VENT:
			continue
		var swirl := MapKit.sprite(MapKit.cell_name("vent_swirl", o.z), o.z)
		swirl.position = Vector2(o.x, o.y)
		# Eyni kadrda deşiklər üst-üstə düşən mexaniki nüsxə kimi görünməsin;
		# faza mövqedən deterministik çıxır, təsadüf xəritə yaddaşını pozmur.
		swirl.set_meta("phase", fposmod((o.x * 0.013 + o.y * 0.021), TAU))
		_blobs.add_child(swirl)
		_vent_swirl_nodes.append(swirl)

	var raised: Array[int] = []
	for i in list.size():
		if DishMap.blocks_germ(int(list[i].w)):
			raised.append(i)
	raised.sort_custom(func(a: int, b: int) -> bool: return list[a].y < list[b].y)
	for i in raised:
		_blob_nodes[i] = _obstacle_sprite(list[i])


func _obstacle_sprite(o: Vector4) -> Sprite2D:
	var cell := MapKit.cell_name(MapKit.base_name(o), o.z)
	var spr := MapKit.sprite(cell, o.z)
	spr.position = Vector2(o.x, o.y)
	spr.set_meta("cell", cell)
	# Titrəmə miqyası bu baza üzərinə gəlir (bax [method _wobble]).
	spr.set_meta("base_scale", spr.scale)
	_blobs.add_child(spr)
	return spr


## Döşəmə bəzəyi neçə ədəddir və toxumu. Brawl Stars-ın "D" qırıntısı kimi:
## oyuna təsir etmir, top üstündən keçəndə sıçrayır (bax [method _pop_clutter]).
const CLUTTER_COUNT := 46
const CLUTTER_SEED := 7715


## Döşəmə bəzəyini səpir. Yalnız client-dədir və DETERMİNİSTİKDİR (sabit toxum,
## düzümə görə): hər açılışda eyni yerdədir, xəritə yadda qalır. Maneələrdən,
## qabın kənarından və bir-birindən aralıdır; rəngi döşəmədən cəmi ±0.08
## fərqlənir — maneə, qida və ya top kimi oxunmamalıdır. Yastı və işıqsız
## çəkilib, ona görə fırlatmaq olar — eyni dörd parça təkrar kimi görünmür.
func _spawn_clutter(list: Array[Vector4]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = CLUTTER_SEED + DishMap.layout
	var tries := 0
	while _clutter.size() < CLUTTER_COUNT and tries < CLUTTER_COUNT * 40:
		tries += 1
		var at := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) \
			* (Const.WORLD_RADIUS - 90.0)
		var r := rng.randf_range(16.0, 30.0)
		var piece := rng.randi_range(0, 3)
		var spin := rng.randf() * TAU
		var free := true
		for o in list:
			if at.distance_to(Vector2(o.x, o.y)) < o.z + r + 18.0:
				free = false
				break
		for c in _clutter:
			if free and at.distance_to(c["at"]) < float(c["r"]) + r + 60.0:
				free = false
		if not free:
			continue
		var spr := MapKit.sprite("clutter_%d" % piece, r)
		spr.position = at
		spr.rotation = spin
		_blobs.add_child(spr)
		_grid_add(_clutter_grid, at, r + Const.SHOT_RADIUS, _clutter.size())
		_clutter.append({"node": spr, "at": at, "r": r, "base": spr.scale, "pop": -INF})


## Bayır dekoru: neçə koloniya və toxum.
const PROP_COUNT := 18
const PROP_SEED := 9137


## Qabın bayırına fokusdan kənar koloniyalar səpir — Brawl Stars-da arena
## dünyanın içində durur, bizim qab isə boş qaranlıqda asılı idi. Kənara sıxılan
## oyunçu ekranın yarısında boşluq görürdü; indi şüşənin o tayında dərinlik var.
## Hamısı DETERMİNİSTİKDİR (sabit toxum) və oyuna heç bir təsiri yoxdur.
func _spawn_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = PROP_SEED
	for k in PROP_COUNT:
		var a := TAU * (float(k) + rng.randf_range(-0.32, 0.32)) / float(PROP_COUNT)
		# Şimal divarı bayıra 70 px uzanır — koloniyalar ondan aralı başlayır.
		var d := Const.WORLD_RADIUS + rng.randf_range(210.0, 640.0)
		var spr := MapKit.prop_sprite(rng.randi_range(0, 3), rng.randf_range(70.0, 175.0))
		spr.position = Vector2.from_angle(a) * d
		spr.set_meta("home", spr.position)
		spr.set_meta("phase", rng.randf() * TAU)
		_props.add_child(spr)
		_prop_nodes.append(spr)


## Koloniyaların yavaş "üzməsi" — yalnız görünənlər tərpənir (çoxu ekrandan
## kənardadır, onlara heç nə yazılmır).
func _bob_props() -> void:
	var view := _view_rect.grow(220.0)
	# Kamera qabın içindədirsə və kənarı görmürsə, heç bir koloniya görünmür.
	var far := Vector2(maxf(absf(view.position.x), absf(view.end.x)),
		maxf(absf(view.position.y), absf(view.end.y)))
	if far.length() < Const.WORLD_RADIUS + 140.0:
		return
	for spr in _prop_nodes:
		var home: Vector2 = spr.get_meta("home")
		if not view.has_point(home):
			continue
		var ph := float(spr.get_meta("phase"))
		spr.position = home + Vector2(sin(_clock * 0.23 + ph), cos(_clock * 0.19 + ph * 1.3)) * 9.0


## Xəritə şəbəkəsinin xanası (128 px).
static func _map_cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / 128.0), floori(at.y / 128.0))


## Dairəni (topun çata biləcəyi radiusla) toxunduğu bütün xanalara yazır: onda
## top yalnız ÖZ xanasına baxır, qonşulara yox.
static func _grid_add(grid: Dictionary, at: Vector2, reach: float, index: int) -> void:
	var lo := _map_cell(at - Vector2(reach, reach))
	var hi := _map_cell(at + Vector2(reach, reach))
	for cx in range(lo.x, hi.x + 1):
		for cy in range(lo.y, hi.y + 1):
			var key := Vector2i(cx, cy)
			if not grid.has(key):
				grid[key] = [] as Array[int]
			(grid[key] as Array[int]).append(index)


## Kolların üst yarpaqları — hamısı bir qatda və bir atlas hüceyrəsindən, yəni
## BİR çəkiliş çağırışı.
##
## Yalnız KOL üçün: bərk maneənin üstündən keçən yarpaq olmaz, cərəyan deşiyi
## isə döşəmədəki dəlikdir. Tacın ortası BOŞDUR (atlas bunu zəmanətləyir) —
## kolun mərkəzindəki mikrob və qida görünür.
func _spawn_canopy() -> void:
	var list := DishMap.obstacles()
	for i in list.size():
		var o: Vector4 = list[i]
		if int(o.w) != DishMap.Kind.BUSH:
			continue
		var spr := MapKit.sprite(MapKit.cell_name("bush_canopy", o.z), o.z)
		spr.position = Vector2(o.x, o.y)
		# Xışıltı miqyası bu baza üzərinə gəlir; hər kadr əvvəlki miqyasın
		# üstünə vurulsaydı kol tədricən şişib kiçilərdi.
		spr.set_meta("base_scale", spr.scale)
		_canopy.add_child(spr)
		_canopy_nodes[i] = spr


func _build_hud() -> void:
	_hud = Hud.new()
	add_child(_hud)
	_hud.build(_tex["stick_base"], _tex["stick_knob"])
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.super_button.set_species(Net.species)
	_hud.fire_button.tapped.connect(_on_fire_tapped)
	_hud.fire_button.aimed.connect(_on_fire_aimed)
	_hud.super_button.used.connect(_on_super_pressed)
	_hud.super_button.blocked.connect(_on_super_blocked)
	_hud.leave_confirmed.connect(_leave_match)


## ESC və Android-in GERİ jesti — matçdan çıxış təsdiqi.
##
## Matçın içində ayarlar YOXDUR (bax [signal Hud.leave_confirmed]), ona görə
## çıxışın yeganə qapısı budur. İki yol birlikdə tutulur: ESC `ui_cancel`
## hərəkətidir, Android-in GERİ jesti isə bildirişdir — `quit_on_go_back`
## söndürülüb (bax `project.godot`), yoxsa jest təsdiq soruşmadan bütün
## tətbiqi bağlayırdı.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_ask_leave()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_ask_leave()


## Xəritənin teksturaları yalnız arena yaşadıqca saxlanılır (bax [method MapKit.release]).
func _exit_tree() -> void:
	MapKit.release()


func _ask_leave() -> void:
	# Nəticə ekranında və ya çıxış artıq gedərkən soruşmağa dəyməz: menyuya
	# onsuz da qayıdılır.
	if _finished or _hud == null:
		return
	_hud.toggle_leave_prompt()


## Matçdan öz istəyi ilə çıxış.
##
## Bu yol olmasaydı, sonsuz arenadan çıxmağın yeganə yolu ÖLMƏK idi (və ya
## proqramı bağlamaq). [member _finished] qoyulur ki, gedən kimi işə düşən
## nəticə ekranı, təkrar qoşulma cəhdi və sayğaclar susdurulsun.
func _leave_match() -> void:
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_return_to_menu()


func _init_prediction() -> void:
	pred = Sim.new()
	_proxy_inputs.clear()
	# Növ MÜTLƏQ verilməlidir: passiv özəlliklər (sürətlənmə, sönmə, axına
	# tabelik, maneə radiusu) növdən çıxır və proqnoz onları serverlə eyni
	# hesablamalıdır. Növsüz yaradılsaydı, hər növ kirpikli kimi proqnozlaşdırılar
	# və mikrob hər snapshot-da geri sıçrayardı.
	me = pred.add_germ(my_id, Net.nickname, my_color, false, Net.species)
	# Proqnoz da eyni yerdən başlamalıdır, yoxsa ilk snapshot mikrobu
	# ekranın o biri başına sıçradır.
	if start_at.is_finite():
		me.pos = start_at
		me.vel = Vector2.ZERO
	_sync_shown()
	# Proqnoz təsadüfi yerdən başlayır — ilk barışıq serverin doğuş yerinə SIÇRAMALIDIR.
	_snap_next = true


## Çəkiliş nöqtəsi: iki proqnoz tick-i arasında hara düşdüyümüzə görə.
##
## [member _tick_accum] tick-dən sonra qalan vaxtdır, yəni nisbət elə odur.
## Üstünə serverin düzəlişinin hələ sönməmiş hissəsi gəlir (bax [member _corr_off]).
func _shown_pos() -> Vector2:
	return _pred_pos() + _corr_off


## Proqnozun öz yeri — düzəlişin sönən hissəsi OLMADAN. Dəymə məntiqi bununla işləyir:
## server səni burada görür; çəkiliş sürüşməsi yalnız göz üçündür (bax [member _corr_off]).
func _pred_pos() -> Vector2:
	return _pos_prev.lerp(_pos_curr, clampf(_tick_accum / Const.TICK_DELTA, 0.0, 1.0))


## ── Düzəlişin hamarlanması ──────────────────────────────────────────────
##
## Server proqnozu düzəldəndə (barışıq) simulyasiya DƏRHAL serverin sözünə keçir,
## çəkiliş isə köhnə yerdən başlayıb ona eksponensial yaxınlaşır. Əvvəl düzəliş
## növbəti tick-də birdən görünürdü: şəbəkə donmasından sonra öz mikrobun
## 37–404 px sıçrayırdı (ölçülüb). Yalnız GÖRÜNTÜDÜR — toqquşma, atəş, proqnoz
## [member me]-nin həqiqi yeri ilə işləyir.
const CORR_TAU := 0.1
## Bundan böyük fərq doğuş, yenidən qoşulma və ya teleportdur — hamarlanmır.
const CORR_SNAP := 500.0
var _corr_off := Vector2.ZERO
## Növbəti barışıq hamarlanmır, mikrob dərhal yerinə qoyulur: doğuş, yenidən qoşulma, CÜT-də
## dirilmə, ÜÇLÜK-də yeni raund — bunlar teleportdur, düzəliş deyil. Əvvəl 500 px-dən qısa
## teleport da sürüşərək görünürdü (yoxlamada tapılıb).
var _snap_next := true


## Barışıq proqnozu [param shift] qədər sürüşdürdü: çəkiliş yerində qalır.
func _smooth_correction(shift: Vector2) -> void:
	if shift.length_squared() < 0.0001:
		return
	if (_corr_off - shift).length() > CORR_SNAP:
		_sync_shown()
		return
	_pos_prev += shift
	_pos_curr += shift
	_corr_off -= shift


func _shown_aim() -> float:
	return lerp_angle(_aim_prev, _aim_curr, clampf(_tick_accum / Const.TICK_DELTA, 0.0, 1.0))


## İnterpolyasiyanın hər iki ucunu indiki vəziyyətə bərabərləşdirir.
##
## Mövqe tick-dən KƏNARDA dəyişəndə (doğuş, serverin düzəlişi) çağırılmalıdır:
## əks halda çəkiliş köhnə nöqtədən yenisinə doğru sürünər və düzəliş
## oyunçuya "sürüşmə" kimi görünər.
func _sync_shown() -> void:
	_pos_prev = me.pos
	_pos_curr = me.pos
	_aim_prev = me.aim
	_aim_curr = me.aim
	_corr_off = Vector2.ZERO


# ================================================================ dövr

func _process(delta: float) -> void:
	# Bu kadra qədər gələn snapshot-lar BİRLİKDƏ emal olunur (bax [method _drain_inbox]).
	# Saat hələ artırılmayıb — əvvəlki kimi, siqnalın işlədiyi anın saatı.
	_drain_inbox()
	_clock += delta
	_advance_render(delta)
	_corr_off *= exp(-delta / CORR_TAU)
	if _corr_off.length_squared() < 0.01:
		_corr_off = Vector2.ZERO
	_animate_environment()
	# Oyun bitibsə basış yığılmamalıdır: yenidən qoşulanda mikrob öz-özünə
	# superi işlədərdi.
	if not _finished and not _reconnecting:
		_poll_super_key()

	_tick_accum += delta
	var steps := 0
	var cap := TICKS_PER_FRAME_PRACTICE if _local_world != null else TICKS_PER_FRAME
	while _tick_accum >= Const.TICK_DELTA and steps < cap:
		_tick_accum -= Const.TICK_DELTA
		steps += 1
		_do_tick()
	if steps == cap:
		_tick_accum = 0.0

	_render(delta)
	_watch_net()
	_watch_performance(delta)
	_watch_resolution(delta)


## Xəritənin fasiləsiz iki yumşaq hərəkəti bir yerdə saxlanılır.
##
## Kolun yalnız ÜST frondları yellənir: baza hərəkət etsəydi keçilən sahənin
## özü sürüşür kimi görünərdi. Cərəyanın isə yalnız İÇ burulğanı fırlanır;
## deşiyin daxili kölgəsi qlobal işıq istiqamətində mismarlanır. Ayrı Tween-lər
## sınanmayıb, çünki 20+ daimi tween scene ağacını boş yerə böyüdərdi.
func _animate_environment() -> void:
	for raw_i in _canopy_nodes:
		var i := int(raw_i)
		var spr: Sprite2D = _canopy_nodes[raw_i]
		var phase := float(i) * 1.73
		var rustle := 0.0
		if _bush_rustles.has(i):
			var age := _clock - float(_bush_rustles[i])
			if age <= 0.52:
				# Sürətli başlanğıc, eksponensial sakitləşmə: daimi yellənmədən
				# seçilir, amma yarpağı oyuncaq kimi uzun müddət silkələmir.
				rustle = sin(age * 31.0) * exp(-age * 5.8)
			else:
				_bush_rustles.erase(i)
		spr.rotation = sin(_clock * 1.15 + phase) * 0.030 + rustle * 0.105
		spr.skew = sin(_clock * 0.83 + phase * 0.7) * 0.018
		var base: Vector2 = spr.get_meta("base_scale", spr.scale)
		var swell := absf(rustle)
		spr.scale = base * Vector2(1.0 + swell * 0.055, 1.0 - swell * 0.035)
	for spr in _vent_swirl_nodes:
		var phase := float(spr.get_meta("phase", 0.0))
		spr.rotation = phase + _clock * 0.72
	_step_ripples()
	_step_clutter()
	_bob_props()
	if not _glints.is_empty():
		while not _glints.is_empty() and _clock - float(_glints[0]["t"]) > GLINT_TIME:
			_glints.pop_front()
		_lip.queue_redraw()


func _do_tick() -> void:
	if _finished or _reconnecting:
		return

	var inp := _sample_input()
	_input_time[inp.seq] = _clock

	if _local_world != null:
		_local_world.accept_input(my_id, inp.to_array())
		var bursts: Array = _local_world.tick(Const.TICK_DELTA)
		# Məşq rejimində şəbəkə yoxdur, ona görə reyestri birbaşa götürürük.
		# Yalnız dəyişəndə: hər tick sözlük qurmaq boş yükdür.
		if _local_world.roster_rev != _roster_rev:
			_roster_rev = _local_world.roster_rev
			_on_roster(_local_world.roster())
		_on_snapshot(_local_world.snapshot_for(my_id))
		for entry in bursts:
			if int(entry["id"]) == my_id:
				_on_you_burst({
					"pops": entry["pops"], "cap": entry["cap"],
					"level": Const.level_of(int(entry["cap"])),
					"age": entry["age"], "killer": entry["killer_name"],
				})

		# Matçı sağ bitirmək — onlayn oyunda bunu [Lobby] göndərir, burada isə
		# Lobby yoxdur. Növbə boşaldılmasaydı, məşqdə qalib heç nə görməzdi və
		# rejimin ən vacib ekranı yalnız serverdə sınana bilərdi.
		for res in _local_world.pending_results:
			if int(res["id"]) == my_id:
				_on_you_burst({
					"pops": res["pops"], "cap": res["cap"],
					"level": Const.level_of(int(res["cap"])),
					"age": res["age"], "killer": "", "won": res["won"],
					"survived": true, "timed_out": res["timed_out"],
				})
		_local_world.pending_results.clear()

	pending.append(inp)
	while pending.size() > Const.INPUT_BUFFER_MAX:
		pending.pop_front()

	# Öz hərəkətini dərhal göstəririk — server cavabını gözləsək, idarə ağır hiss olunardı.
	# Tick-dən ƏVVƏLKİ vəziyyət saxlanılır: çəkiliş iki tick arasında
	# interpolyasiya olunur (bax [method _shown_state]).
	_pos_prev = me.pos
	_aim_prev = me.aim
	pred.step_movement(_pred_inputs(inp), Const.TICK_DELTA, true)
	_pos_curr = me.pos
	_aim_curr = me.aim
	var tricho := 0.0
	for e in pred.events:
		if e.get("t") == "fire":
			_spawn_fx("spark", e["pos"], 0.5, Palette.germ_color(my_color))
			_juice.muzzle(e["pos"], float(e["arg"]), Palette.germ_color(my_color))
			Sfx.play("eject", 0.06)
			_eject_from(my_color, float(e["arg"]))
			_spawn_own_shot(Vector2(e["pos"]), float(e["arg"]), 0.0, inp.view_tick)
			# Məşqdə istəyi yerli dünyanın atəşi bitirir (bax [method _queue_events]):
			# proqnoz orada serverdən bir tick QABAQDADIR və burada bitsəydi,
			# yerli dünya atəşi heç almazdı.
			if _local_world == null:
				_on_own_fire(float(e["arg"]))
			inp.shot = true
		elif e.get("t") == "super":
			# Öz superin effekti DƏRHAL — serverin hadisəsi onu sonra yalnız
			# təsdiqləyir (bax [method _take_own_super]).
			_play_super(Vector2(e["pos"]), float(e["arg"]), my_color)
			_own_supers.append(_clock)
			# Öz trixosistin (arg = təsir radiusu, bax [method Sim._use_super]).
			if float(e["arg"]) > 0.0:
				tricho = float(e["arg"])
	if tricho > 0.0:
		_pop_remote_shots(tricho)
	# Giriş proqnozdan SONRA gedir: server atəşi proqnozun açdığı paketdə tanısın
	# (bax [member Sim.PlayerInput.shot]). Məşqdə yerli dünya onu yuxarıda alıb.
	if _local_world == null:
		Net.send_input.rpc_id(1, inp.to_array())

	# Miniqanda top pulsuzdur — sursat həddi düyməni söndürməməlidir.
	_hud.set_fire_state(me.cooldown / Const.FIRE_COOLDOWN,
		me.balls >= Const.FIRE_MIN_BALLS or me.in_cyst())
	_hud.set_super(float(_shown_charge()) / float(Const.SUPER_MAX), me.super_ready())
	if _mode != Const.Mode.ENDLESS:
		_hud.set_match(int(_mode), _phase, _phase_t, _alive,
			me.pos.length() > _wet_radius,
			_score_us, _score_em, _score_us + _score_em + 1)
	_hud.update_gauge(me.balls, me.capacity)
	_ammo.set_value(me.balls, me.capacity)


## Joystick-dən bir tick-lik giriş yığır.
func _sample_input() -> Sim.PlayerInput:
	_seq += 1
	if auto_input:
		return _auto_sample()

	var move := _hud.move_stick.value

	# Masaüstündə klaviatura joysticki əvəz edir. Bu, yalnız rahatlıq deyil:
	# siçan bir toxunuş kimi emulyasiya olunur, yəni eyni anda həm hərəkət,
	# həm atəş mümkün olmur — PC-də oyunu sınamağın yeganə düzgün yolu budur.
	if move == Vector2.ZERO:
		move = _keyboard_move()

	# Nişan: getdiyin tərəf; dayanmısansa son baxdığın tərəf. Atəş düyməsi
	# sürüşdürülürkən isə nişanın tərəfi — mikrobun "ayaqcığı" oraya dönür və
	# rəqib də hara atacağını görür (bax [member GermVisual.aim]). Atəşdən sonra
	# bir az ([constant AIM_HOLD]) atdığı tərəfə baxır: yoxsa ayaqcıq bir tick
	# hədəfə, növbəti tick hərəkətə sıçrayardı.
	var aim := me.aim
	if move.length() > 0.01:
		aim = move.angle()
	if _hud.fire_button.aiming:
		aim = _hud.fire_button.aim_dir.angle()
	elif _clock < _face_until:
		aim = _face_aim

	# Geriyə sayımda mikrob tərpənmir — server də girişi qəbul etmir
	# ([method World.accept_input]). İkisi eyni qaydanı tətbiq etməlidir,
	# yoxsa proqnoz serverdən qabağa düşür və sayım bitəndə mikrob geri sıçrayır.
	#
	# Çıxış təsdiqi açıq olanda da mikrob dayanır: toxunuş idarələrini örtük
	# onsuz da tutur, klaviatura isə birbaşa sorğulanır — WASD basılı qalsa,
	# oyunçu "çıxım, ya yox" düşünərkən mikrob divara üzərdi.
	if _phase == Const.Phase.COUNTDOWN or _hud.is_leave_prompt_open():
		# Sayım boyu yığılan basılışlar ATILIR, saxlanmır: yoxsa səbirsizlikdən
		# düyməyə toxunan oyunçu "BAŞLADI" yazısı ilə eyni kadrda superini
		# istəmədən xərcləyərdi.
		_super_flag = false
		_shot_t = -INF
		return Sim.PlayerInput.make(_seq, Vector2.ZERO, me.aim, false, false)
	if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER):
		_request_shot(NAN)
	# Amöbün miniqanı: düymə BASILI qaldıqca atəş fasiləsizdir. Adi atəş barmaq
	# qalxanda açılır (bax [FireButton]), burada isə barmağı qaldırmaq lazım deyil —
	# sürüşdürülürsə nişanın tərəfinə, yoxsa avtomatik nişanla.
	if me.in_cyst() and _hud.fire_button.held and not _hud.fire_button.is_cancelling():
		_request_shot(_hud.fire_button.aim_dir.angle() if _hud.fire_button.aiming else NAN)
	# Atəş istəyi gözləyirsə, bit soyuma bitənə qədər HƏR paketdə durur —
	# əvvəlki basılı düymə kimi; server atəşi proqnozun açdığı paketdə tanıyır
	# ([member Sim.PlayerInput.shot]).
	var fire := _shot_pending()
	if fire:
		aim = _shot_angle(aim)
	return Sim.PlayerInput.make(_seq, move, aim, fire, _super_requested(), _view_tick())


## Ekranda İNDİ görünən server tick-i — rəqiblərin interpolyasiya nöqtəsi.
##
## Server topu məhz bu anın rəqiblərinə qarşı yoxlayır ([member Sim.lag_comp]).
## Kəsrlidir: rəqib iki snapshot arasında çəkilir, 33 ms-lik pillə isə
## sürətli rəqibdə 6 px xəta deməkdir. Bilinmirsə -1 — server geri sarmır.
##
## Göstərilən an [member _rtick]-dir (bax [method _advance_render]). Bufer quruyub
## rəqiblər irəli çəkiləndə də ən təzə snapshot-un tick-i deyilir: ekstrapolyasiya
## TƏXMİNDİR və server onu yoxlaya bilməz — gələcək tick iddia olunmur.
func _view_tick() -> float:
	if _rtick < 0.0 or _snaps.is_empty():
		return -1.0
	return clampf(_rtick, float((_snaps[0]["d"] as Array)[Const.Snap.TICK]),
		float((_snaps[-1]["d"] as Array)[Const.Snap.TICK]))


## WASD / ox düymələri. Diaqonal da normallaşdırılır ki, çəp getmək
## sürət qazandırmasın.
static func _keyboard_move() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1.0
	return v.limit_length(1.0)


var _super_flag := false
var _super_key_held := false

## Atəş istəyi düymə buraxılandan (və ya BOŞLUQ basılı ikən) proqnoz topu
## açana qədər ən çoxu bu qədər yaşayır. Soyumanın son anlarında edilən
## toxunuş itmir, amma yarım saniyə əvvəlki toxunuş da birdən-birə atılmır.
const FIRE_BUFFER := 0.2
## Atəşdən sonra mikrob bu qədər atdığı tərəfə baxır (bax [method _sample_input]).
const AIM_HOLD := 0.3
## Nişan xəttinin göstərdiyi səkmə sayı. Bir səkmə "divardan vur" üçün
## kifayətdir; hamısı ([constant Const.SHOT_BOUNCES]) ekranı xətlə doldururdu.
const AIM_BOUNCES := 1

## Gözləyən atəş istəyinin vaxtı; -INF = istək yoxdur.
var _shot_t := -INF
## Əl ilə alınan nişan (radian); NAN = avtomatik nişan.
var _shot_aim := NAN
## Avtomatik nişanın bu atəşlik xətası (bax [method AutoAim.roll_error]).
var _shot_err := 0.0
## Avtomatik nişanın seçdiyi rəqib — kilid işarəsi üçün; -1 = yoxdur.
var _shot_key := -1
var _face_aim := 0.0
var _face_until := -INF
var _aim_rng := RandomNumberGenerator.new()


## Atəş düyməsinə QISA toxunuş — avtomatik nişan.
func _on_fire_tapped() -> void:
	_request_shot(NAN)


## Düymə sürüşdürülüb buraxıldı — top barmağın göstərdiyi xətlə gedir.
func _on_fire_aimed(angle: float) -> void:
	_request_shot(angle)


## Atəş istəyi. Atəşin özünü [constant Const.FIRE_COOLDOWN] və top sayı
## müəyyən edir (serverdə də, proqnozda da) — istək yalnız "at" deyir.
##
## BOŞLUQ basılı ikən istək HƏR tick təzələnir; gözləyən avtomatik istəyin
## xətası isə dəyişmir — atəş başına bir dəfə çəkilir.
## Siçanın sol düyməsi QƏSDƏN buraya qoşulmayıb: o, ekran joystickini idarə edir,
## atəşə də bağlansaydı sürüşdürərək hərəkət edən oyunçu fasiləsiz atardı.
func _request_shot(angle: float) -> void:
	if is_nan(angle) and _shot_pending() and is_nan(_shot_aim):
		_shot_t = _clock
		return
	_shot_t = _clock
	_shot_aim = angle
	_shot_err = AutoAim.roll_error(_aim_rng)


func _shot_pending() -> bool:
	return _clock - _shot_t <= FIRE_BUFFER


## Gözləyən atəşin bucağı. Avtomatik nişanda hədəf HƏR tick yenidən seçilir:
## soyumanı gözləyən istək rəqibin indiki yerinə atır, toxunuş anındakına yox.
## Hədəf yoxdursa — [param fallback], yəni getdiyin (baxdığın) tərəf.
func _shot_angle(fallback: float) -> float:
	if not is_nan(_shot_aim):
		return _shot_aim
	var t := AutoAim.pick(me.pos, _aim_targets(), AutoAim.reach(me.capacity), pred)
	if t.is_empty():
		_shot_key = -1
		return fallback
	_shot_key = int(t["key"])
	return (Vector2(t["pos"]) - me.pos).angle() + _shot_err


## Avtomatik nişanın namizədləri — ekranda GÖRÜNƏN rəqiblər, göründükləri
## yerdə. Server topu atıcının gördüyü ana qarşı yoxlayır ([member Sim.lag_comp]),
## yəni ekrandakı yer düzgün hədəfdir. Süzgəc [method _step_own_shots]-dakı
## kimidir: qalxanlı və yoldaş mikroba top onsuz da dəymir.
func _aim_targets() -> Array:
	var out := []
	for gid in _visuals:
		if gid == my_id:
			continue
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.safe or v.is_ally or v.color_index == my_color:
			continue
		# Yalnız EKRANDAKI rəqib: server görüş sahəsindən geniş göndərir
		# ([constant Const.AOI_FACTOR]) və QA ekranın 188 px altındakı rəqibə
		# atılan toxunuşu tutdu — oyunçu görmədiyi hədəfə atəşi səhv sayır.
		if not _view_rect.has_point(v.position):
			continue
		out.append({"key": gid, "pos": v.position})
	return out


## Proqnoz topu açdı — istək bitdi.
func _on_own_fire(angle: float) -> void:
	var auto := is_nan(_shot_aim)
	_shot_t = -INF
	_face_aim = angle
	_face_until = _clock + AIM_HOLD
	if auto and _visuals.has(_shot_key):
		var v: GermVisual = _visuals[_shot_key]["node"]
		_aim_guide.lock(_shot_key, v.position, Const.germ_radius(v.capacity),
			Palette.germ_color(my_color))


## Nişan xətti (düymə sürüşdürülərkən) və kilid işarəsinin yeri — hər kadr.
##
## Xətt ÇƏKİLƏN mövqedən başlayır, proqnozunkundan yox: mikrob iki tick arasında
## yumşaldılır və xətt ondan qopmamalıdır. Xətt "hazır" görünür, əgər buraxsan
## top [constant FIRE_BUFFER] içində atılacaqsa.
func _update_aim_guide() -> void:
	var fb := _hud.fire_button
	if fb.aiming and not _finished:
		var r := Const.germ_radius(me.capacity)
		var path := pred.aim_path(_shown_pos() + fb.aim_dir * r, fb.aim_dir,
			Const.SHOT_SPEED * Const.SHOT_LIFETIME - r, AIM_BOUNCES)
		var live := me.cooldown <= FIRE_BUFFER and (me.balls >= Const.FIRE_MIN_BALLS or me.in_cyst()) 			and _phase != Const.Phase.COUNTDOWN
		_aim_guide.show_path(path, Palette.germ_color(my_color), live)
	else:
		_aim_guide.hide_path()
	var key := _aim_guide.locked_key()
	if key < 0:
		return
	var entry: Dictionary = _visuals.get(key, {})
	if entry.is_empty() or not (entry["node"] as GermVisual).visible 			or (entry["node"] as GermVisual).burst:
		_aim_guide.unlock()
		return
	var v: GermVisual = entry["node"]
	_aim_guide.follow(v.position, Const.germ_radius(v.capacity))


## Super YALNIZ basılan kadrda göndərilir, atəş kimi basılı saxlanmır.
##
## Səbəb: super bir dəfəlik hadisədir və doluluq dolan kimi barmaq düymənin
## üstündə qalsa, oyunçu istəmədən dərhal işlədərdi. Klaviatura qarşılığı
## masaüstü sınağı üçündür (bax [method _keyboard_move]).
## Klaviatura KƏNARI əl ilə tutulur: Godot-da düymə üçün "just pressed"
## funksiyası yoxdur (o, yalnız təyin olunmuş `action`-lar üçündür), basılı
## saxlanan düymə isə superi dolan kimi işlədərdi.
func _super_requested() -> bool:
	var v := _super_flag
	_super_flag = false
	return v


## Klaviatura kənarı HƏR KADR yoxlanılır, hər tick yox.
##
## Tick saniyədə 30 dəfədir, kadr isə 60+ — yoxlama tick-in içində olanda
## 33 ms-dən qısa toxunuş iki kadrın arasına düşüb tamamilə itirdi. Ölçülüb:
## bir kadrlıq basış altı cəhdin dördündə işləmədi, səkkiz kadr saxlananda
## isə hər dəfə işlədi. Düymə siqnalı ilə eyni bayrağa yığılır ki, aşağıda
## bir yerdən oxunsun.
func _poll_super_key() -> void:
	var key := Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_Q)
	if key and not _super_key_held:
		_super_flag = true
	_super_key_held = key


func _on_super_pressed() -> void:
	_super_flag = true
	# Düymə `used` siqnalını YALNIZ super hazır olanda atır (hazır deyilsə
	# `blocked` gəlir), ona görə buradakı titrəmə həmişə baş verən bir işi
	# təsdiqləyir — 20–30 saniyədə bir yığılan gücün xərclənməsini.
	Settings.vibrate(45)


## Doluluq tamdır, amma super işləmir: oyunçuya SƏBƏBİ deyilir.
##
## Kirpiklidə bu, adi haldır — trixosist iki top xərcləyir, ona görə beşdən
## az topla işləmir ([method Const.super_min_balls]), atəş düyməsi isə dörd
## topda hələ işləkdir. Yəni oyunçu tamamilə normal vəziyyətdə yanan düyməyə
## basıb heç bir cavab almırdı.
func _on_super_blocked() -> void:
	_hud.flash_hint(Const.super_block_reason(int(me.species), me.balls))
	Sfx.play("blunk", 0.0, -4.0)


## Avtomatik giriş — şəbəkə testində insansız client üçün.
##
## Sadə olsa da acından ölməməlidir: topu azalanda qidaya gedir, çox olanda
## rəqibə. Əks halda test client-i bir neçə saniyəyə partlayır və şəbəkə
## axını heç sınaqdan keçmir.
func _auto_sample() -> Sim.PlayerInput:
	var move := Vector2(sin(_clock * 1.3), cos(_clock * 0.9))
	var aim := me.aim
	var hungry := me.balls <= Const.FIRE_MIN_BALLS + 2

	var meal := _nearest_food()
	var target := _nearest_enemy()

	if hungry and not meal.is_empty():
		var to_food: Vector2 = Vector2(meal["pos"]) - me.pos
		move = to_food.normalized()
		aim = to_food.angle()
	elif not target.is_empty():
		var to: Vector2 = Vector2(target["pos"]) - me.pos
		aim = to.angle()
		move = to.normalized() if to.length() > 320.0 else -to.normalized()

	# Super dolubsa, amma top ÇATMIRSA, atəş saxlanılır.
	#
	# Kirpiklinin trixosisti iki top xərcləyir və [method Sim.GermState.super_ready]
	# ən azı beş top tələb edir. Avtomatik oyunçu isə beşə çatan kimi atəş açırdı,
	# yəni mikrob daim 3-4 topda ilişirdi və super DÜYMƏSİ HEÇ VAXT YANMIRDI:
	# regresiya testində kirpiklinin superi 11 cəhdin heç birində ekrana
	# düşmədi, digər iki növünkü isə ilk cəhddə düşdü.
	var saving := me.charge >= Const.SUPER_MAX and not me.super_ready()
	var fire := not saving and me.balls > Const.FIRE_MIN_BALLS and _seq % 8 == 0
	# Amöbün miniqanı: düymə basılı saxlanan kimi — hər tick.
	if me.in_cyst():
		fire = true

	# Super HAZIR olan kimi basılır.
	#
	# Əvvəl heç vaxt basılmırdı və nəticədə superlərin görüntüsü (trixosist,
	# tor, kist) avtomatik testlə HEÇ VAXT ekrana düşmürdü — onları yalnız
	# botlarda, təsadüfən tutmaq olurdu. İndi `--practice --shot` ilə hər növün
	# superi təkrarlana bilən şəkildə çəkilir.
	var use_super := _super_requested() if not auto_super else me.super_ready()
	return Sim.PlayerInput.make(_seq, move, aim, fire, use_super, _view_tick())


func _nearest_food() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var best := {}
	var best_d := INF
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var p := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


func _nearest_enemy() -> Dictionary:
	if _last_snap.is_empty():
		return {}
	var best := {}
	var best_d := INF
	for e in _last_snap[Const.Snap.GERMS]:
		if int(e[Const.GF.ID]) == my_id:
			continue
		var p := Vector2(float(e[Const.GF.X]), float(e[Const.GF.Y]))
		var d := me.pos.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = {"pos": p}
	return best


# ================================================================ server sözü

## ── Snapshot növbəsi ────────────────────────────────────────────────────
##
## Snapshot-lar gələn kimi emal olunmur: növbəyə yığılır və kadrın əvvəlində
## ([method _process]) BİRLİKDƏ emal olunur.
##
## Şəbəkə donub açılanda (Wi-Fi, TCP təkrar göndərişi) 45–120 snapshot BİR kadrda
## gəlir. Əvvəl hər biri tam emal olunurdu: barışıq (64-ə qədər girişin təkrarı),
## kölgələr, liderlər cədvəli — masaüstündə 124–290 ms-lik kadr (telefonda bir neçə
## dəfə çox), yəni donmanın üstünə ikinci donma. İndi bahalı hissə yalnız ƏN TƏZƏ
## snapshot ilə bir dəfə işləyir; bufer, divarlar, matç və hadisələr isə hamısından,
## gəliş sırası ilə — vuruş təsdiqləri əvvəlki kimi qalır.
##
## Məşqdə (yerli dünya) snapshot tick-in içində dərhal emal olunur — əvvəlki kimi.
## Başqa server mesajından ([method _on_roster], [method _on_you_burst]) əvvəl də
## növbə boşaldılır: mesajların sırası dəyişməsin.
var _inbox: Array = []


func _on_snapshot(data: Array) -> void:
	if data.size() < 8:
		return
	_inbox.append(data)
	if _local_world != null:
		_drain_inbox()


func _drain_inbox() -> void:
	if _inbox.is_empty():
		return
	var t0 := Time.get_ticks_usec()
	var corr0 := float(_pm["corr"])
	var n := _inbox.size()
	var newest: Array = _inbox[n - 1]
	# Dəstənin ən köhnəsi donma qədər gecikibsə, bütün dəstə jitter statistikasından
	# çıxır: dəstənin sonu donmanın ortasında göndərilib və gecikməsi azdır, amma
	# o da jitter deyil (bax [method _update_delay_target]).
	_batch_stalled = _tick_base_set and _clock - float((_inbox[0] as Array)[Const.Snap.TICK]) \
		* Const.TICK_DELTA - _floor > LATE_STALL
	for i in n:
		_ingest(_inbox[i], i == n - 1)
	_inbox.clear()
	_batch_stalled = false
	_update_delay_target()
	var was_in := _me_in_snap
	_me_in_snap = false
	for entry in newest[Const.Snap.GERMS]:
		if int(entry[Const.GF.ID]) == my_id:
			_me_in_snap = true
			# Mikrob snapshot-a QAYITDI (CÜT-də dirildi) — yeni doğuş yeridir.
			if not was_in:
				_snap_next = true
			_reconcile(entry, newest[Const.Snap.SELF])
			break
	_hud.update_board(newest[Const.Snap.BOARD], int(newest[Const.Snap.POP]), _roster)
	# Minimap yaş radiusu da bilməlidir: TƏK QALAN-da təhlükəsiz zona 1200-dən
	# 90 px-ə düşür və oyunçunun "hara qaçım" sualına cavab verən yeganə yer
	# xəritədir. Onsuz minimap həmişə tam qabı göstərirdi.
	_hud.minimap.wet_radius = _wet_radius
	var ms := float(Time.get_ticks_usec() - t0) / 1000.0
	_pm["drained"] = int(_pm["drained"]) + n
	_pm["drain_ms"] = float(_pm["drain_ms"]) + ms
	drained.emit(float(_pm["corr"]) - corr0, ms, n)


## Bir snapshot-un ucuz hissəsi: bufer, təsdiq sayğacları, divarlar, matç, hadisələr.
func _ingest(data: Array, newest: bool) -> void:
	var tick := int(data[Const.Snap.TICK])
	# Yeni dünya: tick sayğacı geri gedir və ya çox irəli sıçrayır — baza yenidən qurulur.
	if _last_tick_seen >= 0 and (tick < _last_tick_seen or tick > _last_tick_seen + 900):
		_tick_base_set = false
		_snaps.clear()
		_ack_seen = -1
		_ack_tick = -1
	_last_tick_seen = tick
	# Mikroblar şəbəkədən SIX gəlir; burada bir dəfə sətirlərə açılır ki,
	# çəkiliş və proqnoz kodu format dəyişikliyindən xəbərsiz qalsın.
	data[Const.Snap.GERMS] = Const.unpack_germs(data[Const.Snap.GERMS])
	# Toplar yalnız ən təzə snapshot-dan oxunur ([method _render_shots]).
	if newest:
		data[Const.Snap.SHOTS] = Const.unpack_shots(data[Const.Snap.SHOTS])
	data[Const.Snap.EVENTS] = Const.unpack_events(data[Const.Snap.EVENTS])
	var at := _tick_time_of(float(tick))
	_snaps.append({"t": at, "d": data})
	# Vaxtla saxlanılır: göstərilən andan SNAP_KEEP əvvəlkilər lazım deyil. Donmadan
	# sonrakı dəstə isə BÜTÖV qalır — göstərilən an onun içindən keçib yetişir.
	var keep_from := minf(_rt, _tt(data)) - SNAP_KEEP
	while _snaps.size() > 2 and (_snaps.size() > SNAP_HARD_MAX or _tt(_snaps[1]["d"]) < keep_from):
		_snaps.pop_front()
	# Təsdiqin tick-i: eyni ACK neçə tick təkrarlanıb (köhnə server üçün, bax [method _reconcile]).
	var acked := int((data[Const.Snap.SELF] as Array)[Const.SelfF.ACK])
	if acked != _ack_seen:
		_ack_seen = acked
		_ack_tick = tick
		_ack_moved_t = _clock
	_last_ack = acked
	if newest:
		# Server təxmin sayını və ankoru özü göndərir (SELF[2..6], bax [method World._self_row]).
		var me_self: Array = data[Const.Snap.SELF]
		_srv_rep = int(me_self[2]) if me_self.size() > 2 else -1
		_anchor = Vector4(float(me_self[3]), float(me_self[4]), float(me_self[5]), float(me_self[6])) \
			if me_self.size() > 6 else Vector4.INF
		_last_snap = data
		_last_snap_t = _clock
		_last_snap_tt = at
		_snap_tick = tick
	_apply_walls(data[Const.Snap.WALLS])
	_apply_match(data[Const.Snap.MATCH])
	_queue_events(data[Const.Snap.EVENTS], at)


## Ad və rəng cədvəli gəldi.
##
## Artıq çəkilmiş mikroblar da yenilənir: reyestr snapshot-dan SONRA gələ
## bilər və o halda mikrob bir neçə kadr adsız qalır. Yenilənmə olmasaydı,
## ad birdəfəlik boş qalardı — [method _ensure_germ] yalnız bir dəfə qurur.
func _on_roster(table: Dictionary) -> void:
	_drain_inbox()
	_roster = table
	_bot_colors.clear()
	for gid in table:
		# Bot olduğunu reyestr DEYİR. Əvvəl id-dən çıxarılırdı (`>= BOT_ID_BASE`), amma
		# insanın peer nömrəsi də adətən böyükdür: o biri oyunçunun topu bot topu
		# sayılır, sənin zamanına köçürülür və "sənə dəydi" proqnozu alırdı — server
		# isə insanın topunu geri sarma ilə başqa yerdə yoxlayır. Ölçülüb: yalançı
		# proqnozların çoxu məhz insan toplarında idi.
		var info: Array = table[gid]
		if info.size() > 2 and bool(info[2]):
			_bot_colors[int(info[1])] = true
	for gid in table:
		var entry: Dictionary = _visuals.get(gid, {})
		if entry.is_empty():
			continue
		var info: Array = table[gid]
		entry["node"].set_identity(String(info[0]), int(info[1]))


## ── Serverin təxmini ───────────────────────────────────────────────────
##
## Yeni giriş gəlməyən tick-də server SONUNCUNU təkrar işlədir və mikrob irəli
## gedir, ACK isə yerində qalır. Barışıq ACK-dan sonrakı BÜTÜN girişləri yenidən
## oynadırdı, yəni təkrarlanan tick-lər İKİ dəfə sayılırdı: jitter-də hər
## birləşmədə ~6 px irəli-geri titrəmə, donmadan sonra isə əvvəl yüz pikseldən
## çox İRƏLİ, bir RTT sonra GERİ sıçrayış (ölçülüb).
##
## İndi serverin təxmin etdiyi tick sayı ("slot") qədər giriş atılır: həmin
## girişlərin vaxtını server artıq sonuncu girişlə doldurub. Sayı yeni server özü
## göndərir (SELF[2]); köhnə serverdə ACK-ın neçə tick dəyişmədiyindən çıxır.
##
## ANKOR (SELF[3..6]) — serverin təxminlərdən ƏVVƏLKİ halı (bax [method World._self_row]):
## gec gələn girişlər o tick-lər üçün yenidən oynadılacaq, ona görə proqnoz ankordan
## BÜTÜN gözləyən girişləri oynadır və serverin son yeri ilə üst-üstə düşür.
var _ack_seen := -1
var _ack_tick := -1
var _snap_tick := 0
var _srv_rep := -1
var _anchor := Vector4.INF
## Server bundan çox tick TƏXMİN edirsə (yuxarı istiqamət ilişib), onun yeri oyunçunun
## son girişinin uzantısıdır: proqnozun MÖVQEYİ sərbəst qalır, oyunçu idarəni itirmir.
## Təzə ACK gələndə barışıq qayıdır; fərq varsa [method _smooth_correction] onu yumşaldır.
const GUESS_TICKS := 6


## Serverin dediyi vəziyyəti qəbul edir, sonra hələ təsdiqlənməmiş
## girişləri yenidən oynadır — belə öz hərəkətin geri sıçramır.
## [param me_self] — [constant Const.Snap.SELF] sahəsi: təsdiqlənmiş giriş
## nömrəsi və atəş soyuması. Bunlar mikrob sətrindən çıxarılıb, çünki yalnız
## öz mikrobuna lazımdır və hər kadr hər rəqib üçün göndərilirdi.
func _reconcile(entry: Array, me_self: Array) -> void:
	var acked := int(me_self[Const.SelfF.ACK])
	var rep := _srv_rep if _srv_rep >= 0 else (_snap_tick - _ack_tick if _ack_tick >= 0 else 0)
	rep = clampi(rep, 0, Const.INPUT_BUFFER_MAX)
	# Ankordan oynatmaq üçün ilk təsdiqlənməmiş giriş buferdə olmalıdır.
	var anchored := _anchor != Vector4.INF \
		and (pending.is_empty() or pending[0].seq <= acked + 1)
	# Sərbəst proqnoz yalnız təsdiq HƏQİQƏTƏN donanda (snapshot-larda ACK dəyişmir): server
	# təxmin sayını desə də, ACK hər tick dəyişirsə barışıq dayanmamalıdır.
	var frozen := _snap_tick - _ack_tick if _ack_tick >= 0 else 0
	var keep := rep > GUESS_TICKS and frozen > GUESS_TICKS and not pending.is_empty()
	var before := me.pos
	var cd_before := me.cooldown
	var super_before := me.super_t
	if keep:
		pass
	elif anchored:
		me.pos = Vector2(_anchor.x, _anchor.y)
		me.vel = Vector2(_anchor.z, _anchor.w)
		me.aim = float(entry[Const.GF.AIM])
		# Soyuma ankorun tick-indən deyil, indidəndir: təxmin tick-lərində atəş olmur,
		# yəni ankorda o, `rep` tick çox idi (sıfırdırsa — bilinmir, sıfır qalır).
		var cd := float(me_self[Const.SelfF.CD])
		me.cooldown = minf(cd + rep * Const.TICK_DELTA, Const.FIRE_COOLDOWN) if cd > 0.0 else 0.0
	else:
		me.pos = Vector2(float(entry[Const.GF.X]), float(entry[Const.GF.Y]))
		me.vel = Vector2(float(entry[Const.GF.VX]), float(entry[Const.GF.VY]))
		me.aim = float(entry[Const.GF.AIM])
		me.cooldown = float(me_self[Const.SelfF.CD])
	me.safe_t = 1.0 if int(entry[Const.GF.FLAGS]) & Const.GFlag.SAFE else 0.0

	# Doluluq və superin işlək olması serverin sözüdür.
	#
	# Superin QALAN VAXTI göndərilmir — yalnız "işləyir / işləmir" biti gedir.
	# Bir bitlə saniyədə 30 dəfə vaxt göndərməkdən qurtulmuş oluruq; sayğacı
	# proqnoz özü aparır (atəşin soyuması ilə eyni model).
	#
	# Amma sayğacı QURMAQ proqnoza tapşırıla bilməz. Səbəb məşq rejimindədir:
	# orada yerli dünya girişi [method _do_tick]-in İÇİNDƏ, proqnoz addımından
	# ƏVVƏL emal edir. Super işə düşür, doluluq serverdə sıfırlanır və elə həmin
	# kadrda bura gəlib proqnozun doluluğunu da sıfırlayır — nəticədə proqnoz
	# addımına çatanda [method Sim.GermState.super_ready] artıq "yox" deyir və
	# `super_t` HEÇ VAXT qalxmır. Ayaqlının toru və amöbin qabığı ÖZ mikrobunda
	# görünmürdü (botlarda görünürdü, çünki onlar snapshot bayrağından çəkilir).
	#
	# Ona görə bayrağın QALXMASI sayğacı özü qurur, düşməsi isə sıfırlayır.
	var flags := int(entry[Const.GF.FLAGS])
	me.charge = (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
	var super_on := (flags & Const.GFlag.SUPER) != 0
	# Super əvvəlki snapshot-da da işləyirdi — sayğac aşağıda, yenidən oynatmadan
	# ƏVVƏL geri çəkilir (bax həmin yer).
	var super_cont := super_on and _super_on_srv
	if not super_on:
		me.super_t = 0.0
	elif not _super_on_srv:
		# Serverdə super İNDİ başladı. `maxf` onlayn oyun üçündür: orada proqnoz
		# superi özü işə salıb və onun sayğacı bayraqdan bir neçə tick QABAQDA
		# olur — geri çəkilməməlidir.
		me.super_t = maxf(me.super_t, Const.super_time(int(me.species)))
	else:
		# Server hələ "işləyir" deyir, proqnozun sayğacı isə bitib: quyruq
		# fərqidir. Bir neçə tick uzadılır ki, effekt bayraq sönənə qədər
		# davam etsin və itən paketdə yanıb-sönməsin.
		me.super_t = maxf(me.super_t, SUPER_TAIL)
	_super_on_srv = super_on

	var balls_before := me.balls
	var cap_before := me.capacity
	me.balls = int(entry[Const.GF.BALLS])
	me.capacity = int(entry[Const.GF.CAP])

	# Rəqib partladı → tutum artdı. Bu, oyunun yeganə mükafatıdır, eşidilməlidir.
	if me.capacity > cap_before:
		Sfx.play("level_up")
		_add_shake(6.0)

	# Kimsə sənə top vurdu: doluluq artdı, amma sən yemədin.
	if me.balls > balls_before + 1:
		_add_shake(4.0)

	if me.balls >= me.capacity - 1 or me.balls <= Const.MIN_BALLS:
		Sfx.play_danger()

	# Təxmin slot-larının girişləri atılır (ankorla və ya sərbəst proqnozda — yox).
	# Atılan, amma serverə hələ çatmayan girişin atəşi/superi proqnozda qalır: server
	# onu gələndə ən son girişə birləşdirib işlədəcək ([method World.accept_input]).
	var drop_to := acked if (anchored or keep) else acked + rep
	var keep_fire := false
	var keep_super := false
	while not pending.is_empty() and pending[0].seq <= drop_to:
		if pending[0].seq > acked:
			keep_fire = keep_fire or pending[0].shot
			keep_super = keep_super or pending[0].use_super
		pending.pop_front()
	_last_ack = acked
	if _input_time.has(acked):
		var sample := clampf(_clock - float(_input_time[acked]), 0.0, 1.0)
		_rtt = lerpf(_rtt, sample, 0.1)
		# Son saniyələrin ən aşağı gediş-gəlişi: dərhal enir, yavaş qalxır (bax [method _congested]).
		_rtt_floor = minf(_rtt_floor + RTT_FLOOR_RISE * maxf(_clock - _rtt_floor_t, 0.0), sample)
		_rtt_floor_t = _clock
	for seq in _input_time.keys():
		if int(seq) < acked:
			_input_time.erase(seq)
	if keep:
		me.super_t = maxf(me.super_t, super_before)
		# Kölgələr yenə təzə snapshot-dan qurulur: yoxsa donma boyu köhnə sürətlə irəli
		# gedən "xəyali" rəqiblər proqnozdakı mikrobu itələyirdi (ölçülüb: 737 px düzəliş).
		_sync_proxies()
		return

	# Yaxın rəqiblərin kölgəsi də eyni snapshot-dan qurulur və girişlərlə birlikdə
	# irəli aparılır (bax [method _sync_proxies]).
	_sync_proxies()
	# Davam edən superin sayğacı oynatmanın BAŞLANĞICINA qaytarılır.
	#
	# Gözləyən girişlərin hər biri canlı proqnozda bir dəfə addımlanıb və sayğacı
	# artıq azaldıb; aşağıdakı oynatma onu İKİNCİ dəfə azaldırdı. Gecikmə ilə
	# (~200 ms, 6 gözləyən giriş) hər snapshot 0.2 s yeyirdi: ayaqlının 4
	# saniyəlik toru və amöbün kisti öz ekranında ~0.7 s sonra sönürdü, server
	# isə superi tam müddət işlədirdi — oyunçu "ulti işləmir" görürdü. Kist üstəlik
	# proqnozda vaxtından əvvəl açılır, mikrob yeriyib geri dartılırdı. Məşqdə
	# gözləyən giriş olmadığı üçün görünmürdü. Kirpiklinin superi anidir.
	#
	# Bayrağın QALXDIĞI snapshot-da bu lazım deyil: orada sayğac serverin
	# başlanğıc anından qurulur və oynatma onu düz bugünə çatdırır.
	if super_cont:
		me.super_t += pending.size() * Const.TICK_DELTA
	# Hadisələr saxlanmır: eyni atəş səsi hər düzəlişdə təkrar çalınmamalıdır.
	for inp in pending:
		pred.step_movement(_pred_inputs(inp), Const.TICK_DELTA, false)
	if keep_fire:
		me.cooldown = maxf(me.cooldown, cd_before)
	if keep_super:
		me.super_t = maxf(me.super_t, super_before)

	# Düzəliş tick-dən KƏNARDA da gələ bilər (onlayn rejimdə snapshot istənilən
	# anda düşür). Əvvəl kiçik düzəliş növbəti tick-də birdən, böyüyü (gövdə
	# radiusundan çox) dərhal sıçrayışla görünürdü. İndi çəkiliş yerində qalır və
	# düzəliş [constant CORR_TAU] ilə sönür (bax [method _smooth_correction]).
	var shift := me.pos - before
	_pm["corr"] = float(_pm["corr"]) + shift.length()
	if _snap_next:
		_snap_next = false
		_sync_shown()
	else:
		_smooth_correction(shift)


## ── Proqnozda yaxın rəqiblər ─────────────────────────────────────────────
##
## Server mikrobları hər tick bir-birindən ayırır ([method Sim._separate_germs]).
## Proqnoz əvvəl yalnız öz mikrobunu bilirdi: rəqibə sıxılanda o, serverdə
## geri itələnirdi, proqnozda isə içindən keçirdi — hər snapshot mikrobu geri
## dartırdı, nöqtə-nöqtə döyüşdə atəşin başlanğıcı 12–24 px fərqlənirdi və
## ekranda dəyən top serverdə rəqibin kənarından keçirdi.
##
## İndi yaxın rəqiblər proqnozda KÖLGƏ kimi durur: son snapshot-dakı halları
## ilə qurulur, sonra sürətlərini saxlayaraq irəli gedir (ölü hesab) və server
## kimi itələnir. Onların öz qərarlarını bilmirik — yalnız RTT qədər irəli
## təxmin edirik; növbəti snapshot kölgəni yenidən həqiqətə bağlayır.
##
## Kölgə çəkilmir — rəqiblər əvvəlki kimi interpolyasiya ilə görünür. Tor da
## (ayaqlının superi) indi proqnozdadır: yaxın torun yavaşlatması serverlə eynidir.

## Kölgə olmaq üçün məsafə: iki gövdənin kənarları arasında bu qədər piksel.
## RTT boyu iki mikrob birlikdə ~120 px yaxınlaşa bilər; ehtiyatla 220.
const PROXY_REACH := 220.0
## Kölgənin superi snapshot-da "işləyir" deyirsə, proqnoz pəncərəsi boyu işləyir.
## Qalan vaxtı göndərilmir; bir saniyə RTT-dən xeyli uzundur.
const PROXY_SUPER := 1.0

## Kölgələrin təxmini girişi: germ id -> [Sim.PlayerInput].
var _proxy_inputs := {}


## Proqnozun bir tick-lik girişi: öz girişin və kölgələrinki.
func _pred_inputs(inp: Sim.PlayerInput) -> Dictionary:
	var out := _proxy_inputs.duplicate()
	out[my_id] = inp
	return out


## Kölgələri son snapshot-dan qurur (bax yuxarıdakı izah). [method _reconcile]
## öz mikrobunu serverin halına qaytarandan SONRA çağırır.
func _sync_proxies() -> void:
	var keep := {}
	if not _last_snap.is_empty():
		var my_r := Const.germ_radius(me.capacity)
		for row in _last_snap[Const.Snap.GERMS]:
			var gid := int(row[Const.GF.ID])
			if gid == my_id:
				continue
			var at := Vector2(float(row[Const.GF.X]), float(row[Const.GF.Y]))
			var cap := int(row[Const.GF.CAP])
			var flags := int(row[Const.GF.FLAGS])
			var kind := Const.species_from(
				(flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)
			var super_on := (flags & Const.GFlag.SUPER) != 0
			var r := Const.germ_radius(cap)
			var reach := my_r + r + PROXY_REACH
			if super_on and kind == Const.Species.HELIOZOAN:
				reach = maxf(reach, my_r + r * Const.NET_RADIUS + PROXY_REACH)
			if at.distance_squared_to(me.pos) > reach * reach:
				continue
			var g: Sim.GermState = pred.germs.get(gid)
			if g == null:
				g = Sim.GermState.new()
				g.id = gid
				pred.germs[gid] = g
			g.pos = at
			g.vel = Vector2(float(row[Const.GF.VX]), float(row[Const.GF.VY]))
			g.aim = float(row[Const.GF.AIM])
			g.balls = int(row[Const.GF.BALLS])
			g.capacity = cap
			g.species = kind
			g.team = ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) - 1
			g.super_t = PROXY_SUPER if super_on else 0.0
			g.safe_t = 0.0
			g.alive = true
			keep[gid] = true
			# Sürəti SAXLAYAN giriş: suya nisbi sürət hədəf sürətə bərabərdirsə,
			# [method Sim._step_germs] onu dəyişmir; axın isə öz-özünə əlavə olunur.
			_proxy_inputs[gid] = Sim.PlayerInput.make(0, g.vel / maxf(g.speed(), 1.0),
				g.aim, false)
	for gid in pred.germs.keys():
		if gid != my_id and not keep.has(gid):
			pred.germs.erase(gid)
			_proxy_inputs.erase(gid)


## Oyun sənin üçün bitdi — ya partladın, ya da matçı SAĞ bitirdin.
##
## Bir RPC-dir, çünki client üçün ikisi eyni şeydir: idarə dayanır, nəticə
## çıxır, menyuya qayıdılır. Fərqi serverin qoyduğu `won` bayrağı deyir.
func _on_you_burst(result: Dictionary) -> void:
	_drain_inbox()
	# Yer yalnız matçlı rejimdə var: sonsuz arenada sıralama anlayışı yoxdur.
	if _mode != Const.Mode.ENDLESS:
		result["place"] = _place
		# Tutum REJİMDƏN çıxır: ÜÇLÜK altı mikrobla oynanır və nəticə ekranı
		# "10 mikrobdan · 6-cı YER" yazırdı — üstəlik arxadakı HUD eyni anda
		# "Dünyada 6 mikrob" göstərirdi.
		result["total"] = Const.mode_capacity(int(_mode))
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_result(result)

	# SAĞ QALDIN — mikrobun partlamayıb.
	#
	# Şərt `won` DEYİL, `survived`-dır: vaxt limitində birinci olmayan oyunçu da
	# sağdır. Yalnız `won`-a baxanda ekranda "Vaxt bitdi — sağ qaldın" yazılır,
	# oyun isə eyni anda partlama effektini, ölüm səsini və silkələnməni
	# oynadırdı — mətn görüntünü təkzib edirdi.
	if bool(result.get("survived", false)):
		Sfx.play("level_up" if result.get("won", false) else "ui_click")
		_freeze = 0.0
		get_tree().create_timer(6.0).timeout.connect(_return_to_menu)
		return

	# Öz partlayışın daha böyük çəkilir — kamera onun üstündədir və oyun bitir.
	_explode(me.pos, Const.germ_radius(me.capacity), my_color, true)
	Sfx.play("you_burst")
	_add_shake(18.0)
	# Ən uzun titrəmə oyunun ən böyük hadisəsinə düşür — ölümə.
	Settings.vibrate(160)
	# Öz ölümün ən uzun donmanı alır: oyun bu anda BİTİR, oyunçu nə baş
	# verdiyini görməlidir.
	_freeze = FREEZE_TIME * 2.0
	_punch = 0.11
	get_tree().create_timer(4.0).timeout.connect(_return_to_menu)


## Bağlantı kəsildi. Nişanımız varsa oyunu tərk etmirik — server mikrobumuzu
## bir müddət saxlayır, biz isə arxa planda qayıtmağa çalışırıq.
func _on_server_lost() -> void:
	if _finished or _reconnecting or practice:
		return
	if _token.is_empty():
		_give_up("BAĞLANTI KƏSİLDİ")
		return
	_reconnecting = true
	_rejoin_left = REJOIN_ATTEMPTS
	_hud.release_sticks()
	_try_reconnect()


func _try_reconnect() -> void:
	if not _reconnecting:
		return                      # artıq qayıtmışıq
	if _rejoin_left <= 0:
		_reconnecting = false
		_give_up("BAĞLANTI BƏRPA OLUNMADI")
		return

	_rejoin_left -= 1
	_hud.show_message("BAĞLANTI BƏRPA OLUNUR",
		"Cəhd %d / %d" % [REJOIN_ATTEMPTS - _rejoin_left, REJOIN_ATTEMPTS])

	Net.disconnect_from_server()
	Net.join_server(Net.last_address, Net.last_port)

	# Növbəti cəhd nəticədən asılı olmayaraq planlaşdırılır. Uğur olsa
	# `_reconnecting` sönür və bu çağırış yuxarıdakı yoxlamada dayanır.
	# Bu, `connection_failed` siqnalını gözləməkdən daha etibarlıdır:
	# WebSocket-də uğursuz cəhd bəzən heç bir siqnal vermədən asılı qalır.
	get_tree().create_timer(REJOIN_INTERVAL).timeout.connect(_try_reconnect)


func _on_reconnected() -> void:
	if not _reconnecting:
		return
	Net.request_rejoin.rpc_id(1, _token)


## Server nişanı qəbul etdi — eyni mikrobla dünyaya qayıdırıq.
func _on_rejoin_accepted(info: Dictionary) -> void:
	if not _reconnecting:
		return
	_reconnecting = false

	my_id = int(info["you"])
	my_color = int(info.get("color", my_color))
	# Yenidən qoşulanda köhnə mikrobuna qayıdırsan — onun növü serverdəki
	# qeyddir, menyudakı seçim yox.
	Net.species = _species_from(info)
	_token = str(info.get("token", _token))

	# Proqnoz sıfırdan qurulur; ilk snapshot onu dərhal serverin sözünə çəkəcək.
	pending.clear()
	_snaps.clear()
	_tick_base_set = false
	_rtick = -1.0
	_rt = -INF
	_inbox.clear()
	_ack_seen = -1
	_ack_tick = -1
	_srv_rep = -1
	_anchor = Vector4.INF
	_last_tick_seen = -1
	# Köhnə sessiyanın topları yeni sessiyada təsdiqlənə bilməz: server id-ləri
	# başqadır. Sprite-ları [method _render_ghosts] növbəti kadrda hovuza qaytarır.
	_own_shots.clear()
	_own_supers.clear()
	_claims.clear()
	_own_sids.clear()
	_input_time.clear()
	_init_prediction()
	_hud.set_local_color(Palette.germ_color(my_color))
	_hud.super_button.set_species(Net.species)
	_hud.hide_message()


## Nişan artıq keçərli deyil: mikrob partlayıb və ya gözləmə vaxtı dolub.
func _on_rejoin_rejected() -> void:
	_reconnecting = false
	_give_up("MİKROBUNA QAYITMAQ MÜMKÜN OLMADI")


func _give_up(title: String) -> void:
	if _finished:
		return
	_finished = true
	_hud.release_sticks()
	_hud.show_message(title, "Menyuya qayıdılır...")
	get_tree().create_timer(2.5).timeout.connect(_return_to_menu)


func _return_to_menu() -> void:
	if not practice:
		# Serverə "çıxıram" deyirik: mikrob dərhal silinir, 20 saniyəlik
		# yenidən qoşulma möhləti boş yerə gözlənilmir.
		#
		# Bağlantı BAĞLANMIR — menyu onu olduğu kimi işlədir (bax
		# [method MenuV2._probe_server]), növbəti OYNA yenidən qoşulmur.
		# Dərhal bağlasaq, WebSocket-də bu RPC itirdi: bağlama çərçivəsi paketlə
		# bir poll-a düşür və server bağlanmış peer-in qalan paketlərini
		# oxumadan onu silir. Mikrob "bağlantını itirdi" sayılıb 20 s dünyada
		# qalırdı, dərhal OYNA basan oyunçu isə öz tərk etdiyi mikrobla eyni
		# dünyaya düşürdü. Brauzer və Render yalnız WebSocket işlədir.
		if Net.is_connected_to_server():
			Net.request_leave.rpc_id(1)
		else:
			Net.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")


# ================================================================ render

func _render(delta: float) -> void:
	# Göstərilən an ([method _advance_render]): rəqiblər, toplar, qida və effektlər eyni
	# zaman xəttindədir. Bufer quruyanda [constant EXTRAP_MAX]-dan sonra hamısı birlikdə
	# DAYANIR, donmadan sonra birlikdə yetişir.
	var render_time := _rt if _rt != -INF else _clock - _delay
	_render_germs(render_time)
	_update_aim_guide()
	# Öz topların rəqiblər YERLƏŞƏNDƏN sonra addımlanır: proqnoz məhz bu
	# kadrda ekranda görünən mövqelərə qarşı yoxlayır.
	_step_own_shots(delta)
	_render_shots(render_time)
	_render_food(render_time)
	_flush_fx(render_time)
	_sweep_views()
	_update_camera(delta)
	_update_ammo_bar()
	_update_minimap(delta)
	_apply_freeze()
	_watch_capacity()
	_watch_bush()


func _update_camera(delta: float) -> void:
	# Böyük mikrob daha geniş sahə görür: bu, həm ədalətlidir (böyük hədəfə
	# uzaqdan da dəyirlər), həm də böyüməni hiss etdirir.
	var want := Const.view_span(me.capacity)
	_view_span = lerpf(_view_span, want, clampf(delta * 2.0, 0.0, 1.0))

	var vp := get_viewport_rect().size
	# Miqyas SAHƏDƏN çıxarılır — nə endən, nə də qısa kənardan.
	#
	# Qısa kənardan çıxsaydı (əvvəl belə idi), geniş ekran daha çox dünya
	# görərdi: 21:9 telefon 16:9-dan 31%, 4:3-dən isə 75% çox sahə. Ekranın
	# forması oyun üstünlüyünə çevrilirdi.
	#
	# Sahə sabit olanda forma yalnız KADRIN FORMASINI dəyişir: geniş ekran
	# enli və alçaq görür, kvadrata yaxın ekran dar və hündür. Məlumatın
	# miqdarı hamıda eynidir (bax [constant Const.VIEW_ASPECT_REF]).
	var k := Const.camera_zoom_span(_view_span, vp)
	# Kamera zərbəsi. Sönmə SÜRƏTLİDİR: zərbə ani olmalıdır, uzansa
	# "nəfəs alan kamera" kimi oxunur və oyunçunu yorur.
	_punch = move_toward(_punch, 0.0, delta * 0.75)
	_cam.zoom = Vector2(k, k) * (1.0 + _punch)
	# Görünən sahə zərbəsiz miqyasdan hesablanır: zərbə kadrı KİÇİLDİR, yəni
	# bu düzbucaqlı həmişə ekranı tam örtür.
	var half := vp / (2.0 * maxf(k, 0.001))
	_view_rect = Rect2(_cam.position - half, half * 2.0)

	# ---- donmuş kadr ----
	# Kamera YERİNDƏ qalır — donmanın özü elə budur. Miqyas yuxarıda artıq
	# tətbiq olunub, yəni donma anında zərbə görünür; hərəkət isə dayanır.
	if _freeze > 0.0:
		_freeze = maxf(0.0, _freeze - delta)
		return

	var shake := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - 46.0 * delta)
		shake = Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	# İstiqamətli təpik random silkələnmədən tez sönür. Uzun quyruq kamera
	# sürüşməsi kimi oxunurdu; 70 px/san onu təxminən 0.15 saniyədə bitirir.
	_kick = _kick.move_toward(Vector2.ZERO, 70.0 * delta)
	_cam.position = _shown_pos() + shake + _kick

	# Zərrəciklər kameranı izləyir: dünyanın hamısını doldurmaq əvəzinə
	# yalnız görünən sahədə saxlanılır (bax [WaterMotes]).
	#
	# Sahə UZUN kənarla ölçülür: zərrəcik sahəsi kvadratdır və ekranın geniş
	# tərəfini də örtməlidir — yoxsa yatayda sol və sağ kənarlar boş qalar.
	#
	# Görünən dünya ölçüsü birbaşa miqyasdan çıxır (`piksel / zoom`), çünki
	# artıq qısa kənar deyil, SAHƏ sabitdir.
	var mote_span := maxf(vp.x, vp.y) / maxf(k, 0.001)
	_motes.focus = _shown_pos()
	_motes.span = mote_span
	_motes_deep.focus = _shown_pos()
	_motes_deep.span = mote_span


## Top zolağını öz mikrobunun altına qoyur (bax [AmmoBar]).
##
## Kameradan SONRA: miqyas bu kadrın zoom-unun əksidir, yəni zolaq ekranda həmişə
## eyni ölçüdədir, mövqe isə mikrobun özündən gəlir — zərbə və silkələnmədə onunla
## birlikdə tərpənir. Mikrob partlayanda və matç bitəndə zolaq susur.
func _update_ammo_bar() -> void:
	var entry: Dictionary = _visuals.get(my_id, {})
	var mine: GermVisual = entry.get("node")
	_ammo.visible = mine != null and mine.visible and not mine.burst and not _finished
	if not _ammo.visible:
		return
	var k := maxf(_cam.zoom.x, 0.001)
	_ammo.scale = Vector2.ONE / k
	_ammo.position = mine.position \
		+ Vector2(0.0, Const.germ_radius(mine.capacity) + AmmoBar.GAP / k)


## Kameranın zərbə cavabı. Gücü oyunçunun ayarındadır ([member Settings.shake]).
##
## Ayar YALNIZ kameraya toxunur: donmuş kadr, ağ parıltı və səs olduğu kimi
## qalır, yəni hadisənin baş verdiyi eyni qədər aydın deyilir (bax `README`
## § Zərbə hissi — dörd kanal). Silkələnmə bəzi oyunçularda ürəkbulanma
## yaradır və onu söndürmək məlumat itkisi olmamalıdır.
func _add_shake(amount: float, direction := Vector2.ZERO) -> void:
	var k := Settings.shake
	if k <= 0.001:
		return
	_shake = minf(_shake + amount * k, 20.0)
	if direction.length_squared() > 0.001:
		_kick = (_kick + direction.normalized() * amount * k).limit_length(16.0)


## Serverin dediyi divar vəziyyətini tətbiq edir.
##
## PROQNOZA da yazılır və bu, məcburidir: dağılmış qabıq client-in öz
## simulyasiyasında da yox olmalıdır, yoxsa proqnoz mikrobu artıq olmayan
## divarda saxlayar, server isə keçirər — hər tick-də düzəliş, yəni
## rezin kimi dartılma.
##
## Massiv hər snapshot ilə tam gəlir (maneə başına bir bayt), fərq kimi yox: fərq
## göndərilsəydi bir itən paket client-i əbədi səhv vəziyyətdə qoyardı.
## Matç vəziyyətini serverdən götürür.
##
## Qabın kənarı proqnoza da verilir: mikrobun quru zonaya girib-girmədiyini
## client özü hesablamır (top sayı serverin sözüdür), amma KƏNARI çəkmək və
## xəbərdarlıq göstərmək üçün radius lazımdır.
func _apply_match(row: Array) -> void:
	if row.size() < Const.MF.size():
		return
	_mode = Const.mode_from(int(row[Const.MF.MODE]))
	var was := _phase
	_phase = int(row[Const.MF.PHASE]) as Const.Phase
	_phase_t = float(row[Const.MF.CLOCK])
	_wet_radius = float(row[Const.MF.RADIUS])
	_alive = int(row[Const.MF.ALIVE])
	_place = int(row[Const.MF.PLACE])
	_my_team = int(row[Const.MF.TEAM])
	_score_us = int(row[Const.MF.SCORE_US])
	_score_em = int(row[Const.MF.SCORE_EM])
	pred.dish_radius = _wet_radius

	if was != _phase:
		_on_phase_changed()
	# Kənar hər kadr tərpənir, ona görə quruyan zona yenidən çəkilməlidir —
	# yalnız o: döşəmə, şəbəkə və divar statikdir və öz node-larındadır.
	if _mode != Const.Mode.ENDLESS:
		_dry.queue_redraw()


## Faza dəyişdi — mesaj və səs.
func _on_phase_changed() -> void:
	match _phase:
		Const.Phase.COUNTDOWN:
			# Mətn burada YAZILMIR — sayımın hər iki sətri [method Hud.set_match]
			# tərəfindən hər kadr yenilənir. Burada da yazsaq, iki sahib olar.
			# ÜÇLÜK-də yeni raund: hamı yeni doğuş yerindədir — öz mikrobun sürüşmədən köçür.
			_snap_next = true
		Const.Phase.PLAYING:
			# "BAŞLADI" siqnaldır — həmişə. Altındakı məqsəd cümləsi isə öyrədicidir:
			# hər rejimdə yalnız ilk bir neçə matçda (bax [constant Settings.TIP_SHOWS]).
			var goal_tip := "goal_%d" % int(_mode)
			var goal := ""
			if Settings.tip_due(goal_tip):
				Settings.tip_shown(goal_tip)
				goal = Const.mode_goal(int(_mode))
			_hud.show_message("BAŞLADI", goal)
			get_tree().create_timer(1.4).timeout.connect(_hud.hide_message)
			Sfx.play("level_up")
		_:
			pass


func _apply_walls(walls: PackedByteArray) -> void:
	if walls.size() != _blob_nodes.size():
		return
	var list := DishMap.obstacles()
	for i in walls.size():
		var spr := _blob_nodes[i]
		if spr == null:
			continue

		# Dağılan divar YOX OLMUR, sınıq qalır — Brawl Stars-dakı kimi: gövdə
		# və kölgə gizlənir, yastı qırıntı görünür. Keçid artıq açıqdır, amma
		# oyunçu hələ də "burada divar vardı" oxuyur. Hal hər iki istiqamətdə
		# baytdan qurulur: yenidən qoşulanda (və ya başqa dünyaya düşəndə)
		# bütöv divar da geri görünür.
		var gone := DishMap.wall_gone(walls[i])
		if spr.visible == gone:
			spr.visible = not gone
			if _shadow_nodes.has(i):
				(_shadow_nodes[i] as Sprite2D).visible = not gone
			if _rubble_nodes.has(i):
				(_rubble_nodes[i] as Sprite2D).visible = gone
		if gone:
			continue

		# Hələ durur, amma zədə almış ola bilər. Qabığın şəkli zərbə sayına
		# görə dəyişir: BRITTLE_HP üçdür, yəni oyunçu neçə zərbə qaldığını
		# görməlidir — əvvəl sprite heç vaxt dəyişmirdi və qabıq son zərbəyə
		# qədər toxunulmamış görünürdü.
		#
		# Mərhələ tekstura deyil, atlasın BÖLGƏSİDİR — batch bölünmür (köhnə
		# SVG-lərdə zədəli qabıq ən pis halda +2 çağırış idi).
		var o: Vector4 = list[i]
		var hits := DishMap.wall_hits(walls[i])
		if int(o.w) == DishMap.Kind.BRITTLE:
			var want := MapKit.cell_name("brittle_s%d" % mini(hits, 2), o.z)
			if String(spr.get_meta("cell", "")) != want:
				MapKit.apply(spr, want, o.z)
				spr.set_meta("cell", want)
				spr.set_meta("base_scale", spr.scale)
	_broken = walls
	pred.broken = walls


## Donmanı mikrob görüntülərinə ötürür.
##
## Hər kadr ŞƏRTSİZ yazılır. Yalnız donma başlayanda qoyulsaydı, donma
## anında ekranda olmayan (sonra peyda olan) mikrob donmuş doğulardı və
## bir daha oyanmazdı.
func _apply_freeze() -> void:
	var on := _freeze > 0.0
	for gid in _visuals:
		(_visuals[gid]["node"] as GermVisual).frozen = on


## Tutum artımını tutur — oyunun YEGANƏ mükafatı, görünməlidir.
##
## Hadisə ilə gələ bilmir: partlama hadisəsində PARTLAYAN yazılır, partladan
## yox (bax [method Sim._burst]). Ona görə artım öz mikrobunun sahəsindən
## oxunur — bu, həm onlayn, həm məşq rejimində işləyir.
func _watch_capacity() -> void:
	# İlk kadr: başlanğıc tutumu mükafat kimi göstərmək olmaz.
	if _last_cap == 0:
		_last_cap = me.capacity
		return
	if me.capacity > _last_cap:
		_pop_text(_shown_pos(), "+%d TUTUM" % (me.capacity - _last_cap),
			Palette.SAFE, 30)
		_juice.reward(_shown_pos(), Const.germ_radius(me.capacity))
		_punch = maxf(_punch, 0.05)
		# Oyunun yeganə mükafatı — titrəmə də onu qeyd edir.
		Settings.vibrate(60)
	_last_cap = me.capacity


## Öz mikrobun kolun içindədirmi — və oyunçu bunu BİLİRMİ?
##
## Gizlənmə GÖRÜNMƏYƏN qaydadır: server sadəcə rəqiblərə paket göndərmir
## (bax [method World._near_germs]), oyunçunun ekranında isə heç nə dəyişmir.
## Geribildirim olmasa xüsusiyyət PRAKTİKİ OLARAQ YOXDUR — oyunçu ondan
## istifadə etməyi ağlına gətirmir.
##
## Sönükləşmə seçilib, ikona yox: mikrobun ÖZÜ dəyişir, yəni mesaj hara
## baxırsansa oradadır. HUD-dakı ikonu döyüş vaxtı heç kim görmür.
##
## Yazı yalnız BİR dəfə çıxır. Hər kola girəndə təkrarlansaydı, kolların
## arasından keçən oyunçu fasiləsiz mesaj yağışı altında qalardı.
##
## Yarpaqlar indi mikrobun ÜSTÜNDƏDİR, ona görə iki şey birlikdə dəyişir: öz
## mikrobun 0.70-ə sönür (əvvəl 0.45 idi — yarpaq altında demək olar itərdi,
## critique B3) və içində olduğun kolun tacı yarımşəffaf olur — Brawl Stars-da
## kol öz oyunçusunun ətrafında şəffaflaşır. Yalnız SƏNİN kolun: başqa kolların
## tacı tutqun qalır, gizli rəqib orada gizli qalır.
func _watch_bush() -> void:
	var now := pred.bush_of(me)
	var inside := now >= 0
	# Bir koldan o birinə düz keçəndə gizlilik dəyişmir, amma hər iki frond
	# toxunuşa cavab verməlidir. Ona görə indeks boolean-dan ayrıca izlənir.
	if now == _bush_index and inside == _hidden:
		return
	if _bush_index >= 0:
		_bush_rustles[_bush_index] = _clock
	if now >= 0:
		_bush_rustles[now] = _clock
	if now != _bush_index:
		_fade_canopy(_bush_index, 1.0)
		_fade_canopy(now, CANOPY_SEE_THROUGH)
	_bush_index = now
	if inside == _hidden:
		return
	_hidden = inside
	var v := _germ_by_color(my_color)
	if v != null:
		var tw := create_tween()
		tw.tween_property(v, "modulate:a", OWN_HIDDEN_ALPHA if inside else 1.0, 0.22)
	# Matçda bir dəfə, ümumilikdə ilk bir neçə matçda (bax [constant Settings.TIP_SHOWS]).
	# Sonra qaydanı yalnız görüntü deyir: mikrobun şəffaflaşır, tac aralanır.
	if inside and not _bush_taught and Settings.tip_due("bush"):
		_bush_taught = true
		Settings.tip_shown("bush")
		_hud.show_message("GİZLƏNDİN", "Kolun içində rəqiblər səni görmür")
		get_tree().create_timer(2.2).timeout.connect(_hud.hide_message)


## Kolda öz mikrobunun şəffaflığı və içində olduğun kolun tacının şəffaflığı.
const OWN_HIDDEN_ALPHA := 0.70
const CANOPY_SEE_THROUGH := 0.45


## Kolun tacını [param alpha]-ya yumşaq keçirir ([param i] < 0 — heç nə).
func _fade_canopy(i: int, alpha: float) -> void:
	if not _canopy_nodes.has(i):
		return
	var spr: Sprite2D = _canopy_nodes[i]
	if spr.has_meta("fade"):
		var old: Tween = spr.get_meta("fade")
		if old != null and old.is_valid():
			old.kill()
	var tw := create_tween()
	tw.tween_property(spr, "modulate:a", alpha, 0.22)
	spr.set_meta("fade", tw)


## Görünən rəqibin kol sərhədini keçməsini yalnız görüntü üçün tutur.
## Serverin gizlənmə qaydası dəyişmir; eyni radius yoxlaması burada frondun
## hansı anda xışıldayacağını seçir. Rəqib kola girib paketdən itəndə son görünən
## sərhəd və VIEW_GRACE çıxışı birlikdə dalğanı yenə bir dəfə oynadır.
func _watch_visible_bush(gid: int, at: Vector2, radius: float) -> void:
	var now := -1
	var list := DishMap.obstacles()
	for i in list.size():
		var o: Vector4 = list[i]
		if int(o.w) != DishMap.Kind.BUSH or o.z < radius:
			continue
		if at.distance_squared_to(Vector2(o.x, o.y)) <= o.z * o.z:
			now = i
			break
	var before := int(_germ_bushes.get(gid, -1))
	if now == before:
		return
	if before >= 0:
		_bush_rustles[before] = _clock
	if now >= 0:
		_bush_rustles[now] = _clock
	_germ_bushes[gid] = now


## Top rəqibin içinə keçdi — serverin HIT hadisəsindən.
##
## Hadisədə atanın rəngi [code]color[/code]-dadır, qurbanınkı isə `arg`-dadır
## (bax [method Const.hit_victim]) — ayrıca bayt getmir. Qurban bilinməsə
## (köhnə server), dəymə nöqtəsinə ƏN YAXIN mikrob götürülür: nöqtə onun öz
## səthidir. Amma sıx döyüşdə mikroblar üst-üstə minir və "ən yaxın" başqası
## ola bilirdi — parıltı yanlış mikrobda yanırdı.
func _on_impact(at: Vector2, shooter_color: int, victim_color := -1) -> void:
	if victim_color >= 0:
		var exact := _germ_by_color(victim_color)
		if exact != null and exact.visible and not exact.burst:
			_impact_on(exact, at, shooter_color, (exact.position - at).normalized())
			return
	var victim: GermVisual = null
	var best := INF
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.color_index == shooter_color:
			continue
		var d := v.position.distance_to(at)
		if d < best:
			best = d
			victim = v
	# Ən böyük mikrobun radiusu ~96 pikseldir. Bundan uzaqdakı "ən yaxın"
	# mikrob qurban deyil: hadisə görüş sahəsindən kənarda baş verib və
	# vurulan hələ bizə göndərilmir.
	if victim == null or best > 220.0:
		return
	_impact_on(victim, at, shooter_color, (victim.position - at).normalized())


## Zərbənin görüntüsü — həm proqnozdan ([method _on_own_contact]), həm serverdən.
##
## [param incoming] topun gəliş oxudur. Serverin hadisəsində istiqamət yoxdur
## və dəymə nöqtəsindən mərkəzə götürülür; proqnoz isə topun ƏSL uçuş oxunu
## bilir — maili dəymədə fərq açıq görünür.
##
## Öz topunun zərbəsi [method _own_hit_feel] ilə gücləndirilir: atıcının
## eşitdiyi təsdiq səsi, barmağa titrəmə, super halqasının dolması. Başqasının
## atdığı top buna layiq deyil — ekranda 10 mikrob atəş açır.
func _impact_on(victim: GermVisual, at: Vector2, shooter_color: int,
		incoming: Vector2, predicted := false) -> void:
	# Membran zərbə oxuna DİK genişlənir. Hadisədə ayrıca istiqamət baytı
	# yoxdur və lazım da deyil: dəymə nöqtəsi artıq qurbanın səthindədir.
	victim.flash((at - victim.position).angle())
	# Topun gəliş oxu. Sıçrantı və kamera eyni oxu paylaşır; radial effekt
	# zərbənin hansı tərəfdən gəldiyini silirdi.
	_juice.impact(at, incoming, Palette.germ_color(shooter_color))
	if victim.color_index == my_color:
		_add_shake(4.5, incoming)
		# Zərbə ƏN vacib xəbərdir: səs qarışıqlıqda itə bilər, parıltı isə
		# barmağın altında qala bilər. Titrəmə hər ikisindən keçir.
		Settings.vibrate(22)
	var gained := victim.balls + Const.SHOT_PAYLOAD
	var mine := shooter_color == my_color
	if mine:
		_own_hit_feel(victim, gained, predicted)
	# Rəqəm dəymə nöqtəsində yox, QURBANIN ADINDAN yuxarıda doğulur.
	#
	# Dəymə nöqtəsi mikrobun üst kənarına düşəndə rəqəm tam adın sətrinə otururdu
	# və "Mik+2ob" kimi oxunurdu. Ad mikrobun mərkəzindən sabit məsafədədir,
	# ona görə etibarlı yer odur — dəymə isə gövdənin istənilən yerində olur.
	var above := victim.position - Vector2(0.0, Const.germ_radius(victim.capacity) + 74.0)
	# Öz zərbəndə rəqəm partlamaya nə qədər qaldığını da deyir: bir zərbəlik
	# yer qalıbsa QIRMIZI və iri — "növbəti top onu partladır".
	var color := Palette.germ_color(victim.color_index)
	var size := 26
	if mine and gained + Const.SHOT_PAYLOAD > victim.capacity:
		color = Palette.DANGER
		size = 32
	_pop_text(Vector2(at.x, minf(at.y, above.y)), "+%d" % Const.SHOT_PAYLOAD, color, size)


## Atıcının öz zərbəsini hiss etməsi — Brawl Stars-ın "vurdum" təsdiqi.
##
## Parıltı və sıçrantı hamı üçündür; bunlar isə YALNIZ atana:
##   • `hit_confirm` — `hit`-dən ayrı, yüksək zolaqda qısa "pop". Tonu qurbanın
##     doluluğu ilə QALXIR: qulaq rəqibin partlamağa yaxınlaşdığını eşidir.
##   • qısa titrəmə (15 ms) — qurbanın titrəməsindən (22 ms) yüngül;
##   • +2 top qurbanda, +3 super halqasında DƏRHAL — serveri gözləmədən.
##
## Super vədi YALNIZ proqnozdadır: serverin hadisəsi ilə gələn dəymədə doluluq
## eyni snapshot-la artıq gəlib ([method _reconcile]) və vəd onu ikiqat sayardı.
func _own_hit_feel(victim: GermVisual, gained: int, predicted: bool) -> void:
	var fill := float(gained) / float(maxi(victim.capacity, 1))
	Sfx.play_pitched("hit_confirm", 1.0 + 0.30 * clampf((fill - 0.3) / 0.7, 0.0, 1.0))
	Settings.vibrate(15)
	victim.promise_balls(gained, PROMISE_HOLD)
	if predicted:
		_promise_charge(Const.SUPER_ON_HIT)
	_my_victims[victim.color_index] = _clock


## Uçan rəqəm — hadisənin ÖZ YERİNDƏ yazılır.
##
## HUD-a qoyula bilməzdi: HUD ekranın kənarındadır, hadisə isə ortada baş
## verir və oyunçunun gözü orada olur. Rəqəmin bütün dəyəri elə yerində
## görünməsindədir.
##
## Etiket `_fx` qatındadır, yəni DÜNYA koordinatlarındadır və kamera ilə
## birlikdə sürüşür. Mərkəzləmə sabit enlə edilir: `Label`-ın öz ölçüsü
## yalnız növbəti kadrda bilinir, mərkəz isə İNDİ lazımdır.
func _pop_text(at: Vector2, text: String, color: Color, size: int) -> void:
	const BOX := 260.0
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(BOX, float(size) + 8.0)
	# Yuxarı sürüşmə: rəqəm dəymə nöqtəsində doğulsa mikrobun ADI ilə üst-üstə
	# düşür (ad mikrobun başının üstündədir) və ikisi də oxunmaz olur.
	label.position = at - Vector2(BOX * 0.5, float(size) + 20.0)
	label.z_index = 50
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	# Kontur şərtdir: rəqəm öz rəngindədir və eyni rəngli mikrobun üstünə
	# düşəndə onsuz oxunmur.
	label.add_theme_color_override("font_outline_color", Palette.OUTLINE)
	label.add_theme_constant_override("outline_size", 7)
	label.pivot_offset = label.size * 0.5
	label.scale = Vector2(0.52, 0.52)
	_fx.add_child(label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y - 52.0, 0.85) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2.ONE, 0.26) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Sönmə GECİKİR: rəqəm əvvəlcə tam oxunmalı, sonra getməlidir.
	tw.tween_property(label, "modulate:a", 0.0, 0.50).set_delay(0.35)
	tw.chain().tween_callback(label.queue_free)


## Rəqibin forması neçə kadrdan bir çəkilir — hədəf saniyədə ~30 forma.
##
## YÜKSƏK-də hər kadr. Yüngül səviyyələrdə 60 kadrda iki kadrdan bir;
## MİNİMUM-un 30 kadr həddində isə hər kadr (yenə saniyədə 30).
func _remote_redraw_step() -> int:
	if not Const.is_light(int(Net.quality)):
		return 1
	# Godot-un öz həddi yox: brauzerdə hədd səhifədədir və mühərrikdə 0 durur
	# (bax [method Settings._apply_frame_cap]).
	var cap := Settings.frame_cap()
	var fps := cap if cap > 0 else 60
	return maxi(1, int(round(float(fps) / 30.0)))


## ── Avtomatik keyfiyyət ──────────────────────────────────────────────────
##
## Telefonun gücünü əvvəlcədən bilmək olmur: brauzer GPU-nun adını həmişə
## vermir, eyni çip isə qızanda iki dəfə yavaşlayır. Ona görə kadr vaxtı
## OYUNUN İÇİNDƏ ölçülür: arena açılandan [constant PERF_WARMUP] saniyə sonra
## (yükləmə sıçrayışları sayılmır) hər [constant PERF_WINDOW] saniyədə median
## və 90-cı faiz yoxlanır. Kadrlar büdcəni ardıcıl aşırsa, keyfiyyət bir pillə
## endirilir (YÜKSƏK → AŞAĞI → MİNİMUM) və cihaz üçün yadda saxlanılır
## ([member Settings.auto_quality]) — növbəti açılış elə oradan başlayır.
##
## Oyunçu keyfiyyəti AYARLAR-da özü seçibsə, tənzimləyici toxunmur.
const PERF_WARMUP := 4.0
const PERF_WINDOW := 5.0
## Kadr həddi dəyişəndən sonra ölçülməyən müddət — ritm yeni həddə keçənə qədər.
const PERF_SETTLE := 2.0
var _perf_wait := PERF_WARMUP
var _perf_frames := PackedFloat32Array()
var _perf_time := 0.0
var _perf_cap := -1


func _watch_performance(delta: float) -> void:
	if Settings.quality_chosen or Net.quality == Const.Quality.MINIMUM or _finished:
		return
	# Hədd matçın ortasında dəyişə bilir (telefon qızdı, batareya qənaəti, 90 Hz
	# ekranda 60 → 45; bax [FramePacer]). Yığılan kadrlar köhnə büdcəyə aiddir:
	# 30-dan 60-a qayıdanda 33 ms-lik kadrlar "yavaş" sayılıb keyfiyyəti — yəni
	# qrafikanı — boş yerə endirərdi.
	var cap := Settings.frame_cap()
	if cap != _perf_cap:
		_perf_cap = cap
		_perf_frames.clear()
		_perf_time = 0.0
		_perf_wait = maxf(_perf_wait, PERF_SETTLE)
	if _perf_wait > 0.0:
		_perf_wait -= delta
		return
	_perf_frames.append(delta)
	_perf_time += delta
	if _perf_time < PERF_WINDOW:
		return
	var slow := too_slow(_perf_frames, Settings.frame_cap())
	_perf_frames.clear()
	_perf_time = 0.0
	if not slow:
		return
	var next := Const.Quality.MINIMUM if Net.quality == Const.Quality.LOW else Const.Quality.LOW
	Net.quality = next
	Settings.auto_quality = int(next)
	# Yeni səviyyə öz kətan həddindən başlayır (bax [method _watch_resolution]).
	Settings.auto_dpr = 0.0
	Settings.commit()
	_hud.flash_hint("QRAFİKA AVTOMATİK: %s" % Const.quality_name(int(next)))
	print("[perf] kadrlar büdcəni aşır — keyfiyyət avtomatik: %s" % Const.quality_name(int(next)))
	_perf_wait = PERF_WARMUP
	_res_wait = RES_WARMUP


## Kadrlar büdcəni ARDICIL aşırmı: median büdcədən 35% uzun və ya hər onuncu
## kadr iki qat uzun. Tək-tük sıçrayış (şəbəkə, zibil yığımı) sayılmır.
## Büdcə kadr həddindən çıxır; hədd yoxdursa 60 kadr götürülür.
static func too_slow(frames: PackedFloat32Array, fps_cap: int) -> bool:
	if frames.size() < 20:
		return false
	var budget := _frame_budget(fps_cap)
	var sorted := frames.duplicate()
	sorted.sort()
	var median := sorted[sorted.size() / 2]
	var p90 := sorted[mini(int(float(sorted.size()) * 0.9), sorted.size() - 1)]
	return median > budget * 1.35 or p90 > budget * 2.0


static func _frame_budget(fps_cap: int) -> float:
	return maxf(1.0 / float(fps_cap if fps_cap > 0 else 60), 1.0 / 60.0)


## ── Dinamik kətan sıxlığı (brauzer) ─────────────────────────────────────
##
## Keyfiyyət səviyyəsi birinci addımdır ([method _watch_performance]); bu isə
## onun altında işləyən ikincidir. MİNİMUM-da (və ya oyunçu səviyyəni özü
## seçibsə) kadr [constant RES_FPS] kadrın büdcəsini aşırsa, kətanın sıxlığı
## [constant RES_DOWN] qədər kiçilir, [constant Settings.WEB_FLOOR_DPR]-a qədər.
## Kiçiltmə kadrı qısaltmırsa (yük pikseldə deyil), sıxlıq geri qaytarılır.
## Kadrlar bir müddət rahat gedirsə, geri böyüyür (bax [method resolution_step]).
## Öyrənilən sıxlıq yadda qalır ([member Settings.auto_dpr]).
##
## Büdcə kadr həddindən asılı olmayaraq 30 kadrdır: tənzimləyicinin işi zəif
## GPU-da oyunu OYNANAN saxlamaqdır, 60 kadr xatirinə şəkli bulandırmaq yox.
## Enerjiyə qənaət rejimində brauzer kadrı özü 30-a kəsir — büdcə 60 olsaydı,
## sıxlıq boş yerə dibə enərdi.
##
## Niyə lazımdır: zəif GPU-nun yükü SwiftShader modelində ölçülüb, real
## Mali/Adreno-nun millisaniyəsi isə başqa olacaq. Sabit sıxlıq bir telefonda
## hələ yavaş, başqasında lazımsız bulanıq qalardı. Burada sıxlıq HƏMİN
## telefonun öz kadrlarından öyrənilir — GPU nə qədər zəif olsa da, kadr
## büdcəsi tutulur (bax README, «Zəif GPU — dinamik sıxlıq»).
const RES_FPS := 30
const RES_WARMUP := 4.0
const RES_WINDOW := 3.0
const RES_DOWN := 0.85
const RES_UP := 1.12
## Sıxlıq geri böyüməzdən əvvəl ardıcıl neçə rahat pəncərə.
const RES_CALM := 4
## Ölçülən kadr statistikası konsola bu qədər saniyədən bir yazılır — real
## telefonda (uzaqdan sazlama ilə) elə bundan oxunur.
const RES_REPORT := 30.0
var _res_wait := RES_WARMUP
var _res_frames := PackedFloat32Array()
var _res_cpu := PackedFloat32Array()
var _res_time := 0.0
## Tənzimləyicinin yaddaşı (bax [method resolution_step]); səviyyə dəyişəndə sıfırlanır.
var _res_state := {}
var _res_tier := -1
var _res_cap := -1
var _res_report := RES_REPORT
## Son pəncərənin ölçüsü: `[kadr p50, kadr p90, CPU işi p50, orta kadr]` (ms) — konsol sətri.
var res_stats := Vector4.ZERO


func _watch_resolution(delta: float) -> void:
	if not OS.has_feature("web") or _finished:
		return
	if int(Net.quality) != _res_tier:
		_res_tier = int(Net.quality)
		_res_state = {}
	# Kadr həddi dəyişibsə (bax [method _watch_performance]) pəncərə yenidən başlayır.
	var cap := Settings.frame_cap()
	if cap != _res_cap:
		_res_cap = cap
		_res_frames.clear()
		_res_cpu.clear()
		_res_time = 0.0
		_res_wait = maxf(_res_wait, PERF_SETTLE)
	if _res_wait > 0.0:
		_res_wait -= delta
		return
	_res_frames.append(delta)
	_res_cpu.append(_frame_cpu())
	_res_time += delta
	_res_report -= delta
	if _res_time < RES_WINDOW:
		return
	var budget := maxf(_frame_budget(Settings.frame_cap()), 1.0 / float(RES_FPS))
	var verdict := resolution_verdict(_res_frames, _res_cpu, budget)
	res_stats = frame_stats(_res_frames, _res_cpu)
	_res_frames.clear()
	_res_cpu.clear()
	_res_time = 0.0
	# Kətan ekranın öz sıxlığından sıx olmur — tənzimləyici HƏQİQİ sıxlıqla işləyir.
	var device := Settings.device_dpr()
	var dpr := minf(Settings.web_dpr(), device)
	# Səviyyəni endirmək hələ mümkündürsə, birinci o işləyir.
	var may_shrink := Settings.quality_chosen or Net.quality == Const.Quality.MINIMUM
	var next := resolution_step(dpr, verdict, res_stats.w, may_shrink,
		minf(Settings.tier_dpr(int(Net.quality)), device), _res_state)
	if _res_report <= 0.0:
		_res_report = RES_REPORT
		print(perf_line(dpr))
	if absf(next - dpr) < 0.001:
		return
	Settings.auto_dpr = next
	Settings.commit()
	print("[perf] kətan sıxlığı %.2f → %.2f (%s)" % [dpr, next, perf_line(dpr)])
	_res_wait = RES_WINDOW


## Kadrın oyun işi (saniyə): `_process` və fizika — yalnız konsol sətri üçün.
## GPU geri qalanda bura onu gözləmə də düşür (bax [method resolution_verdict]).
func _frame_cpu() -> float:
	return Performance.get_monitor(Performance.TIME_PROCESS) \
		+ Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)


## Bir pəncərədən sonra yeni kətan sıxlığı. [param mean] — pəncərənin orta
## kadrı, [param state] — tənzimləyicinin sessiya yaddaşı.
##
## Yavaşdırsa [constant RES_DOWN] qədər kiçilir və həmin sıxlıq bu sessiyanın
## TAVANI olur. [constant RES_CALM] pəncərə ardıcıl rahatdırsa [constant RES_UP]
## qədər böyüyür — tavandan və səviyyənin öz həddindən ([param cap]) yuxarı yox.
## Böyümə kadrı yavaşladırsa, əvvəlki (rahat) sıxlığa qayıdır və o, tavan olur:
## sıxlıq bir dəfə sınayır, sonra yerində qalır, titrəmir.
##
## Kiçiltmə İKİ addımda (piksel ~48% az) orta kadrı qısaltmayıbsa, yük pikseldə
## deyil (CPU-nun ölçülməyən işi, brauzerin kadr kəsməsi): sıxlıq başlanğıca
## qaytarılır və bu sessiyada daha kiçilmir — oyun boş yerə bulanıq qalmasın.
static func resolution_step(dpr: float, verdict: int, mean: float, may_shrink: bool,
		cap: float, state: Dictionary) -> float:
	var grew_from := float(state.get("grew_from", 0.0))
	state.erase("grew_from")
	if verdict < 0 and may_shrink and not bool(state.get("futile", false)):
		state["calm"] = 0
		if grew_from > 0.0:
			state["ceiling"] = grew_from
			return grew_from
		var steps := int(state.get("steps", 0))
		if steps == 0:
			state["from"] = dpr
			state["from_mean"] = mean
		elif steps >= 2 and mean >= float(state["from_mean"]) * 0.97:
			state["futile"] = true
			state["ceiling"] = float(state["from"])
			return float(state["from"])
		state["steps"] = steps + 1
		state["ceiling"] = minf(float(state.get("ceiling", INF)), dpr * 0.999)
		return maxf(minf(Settings.WEB_FLOOR_DPR, dpr), dpr * RES_DOWN)
	if verdict > 0:
		state["steps"] = 0
		state["calm"] = int(state.get("calm", 0)) + 1
		var top := minf(cap, float(state.get("ceiling", INF)))
		if int(state["calm"]) >= RES_CALM and dpr < top - 0.001:
			state["calm"] = 0
			state["grew_from"] = dpr
			return minf(top, dpr * RES_UP)
		return dpr
	state["calm"] = 0
	return dpr


## Pəncərənin hökmü: -1 = yavaşdır, piksel azaldılmalıdır; +1 = rahatdır,
## piksel artırıla bilər; 0 = sərhəddədir.
##
## Kadr həddi olanda rahat oyun da büdcə qədər kadr göstərir, ona görə "rahat"
## kadrın büdcədən çox uzun olmamasıdır. Kadrların onda biri büdcəni 35% aşırsa
## da yavaşdır (60 Hz ekranda 30 kadr ya 33, ya 50 ms çəkir — hər onuncu 50 ms
## titrəmə deməkdir); tək-tük sıçrayış (şəbəkə, şeyder yüklənməsi) sayılmır.
##
## Yükün GPU-da, yoxsa CPU-da olduğu burada SORUŞULMUR — brauzerdə bunu ölçmək
## olmur. WebGL əmrləri GPU prosesinə növbə ilə gedir; GPU geri qalanda növbə
## dolur və kadrın İSTƏNİLƏN yerindəki GL çağırışı gözləyir — `_process` də daxil.
## Ölçülüb (SwiftShader, GPU prosesi bir nüvədə, 100% dolu): kadr 80 ms, oyunun
## "CPU işi" də 80 ms idi. Ona görə sual təcrübə ilə həll olunur: kiçiltmə kadrı
## qısaltmırsa, sıxlıq geri qaytarılır (bax [method resolution_step]).
static func resolution_verdict(frames: PackedFloat32Array, cpu: PackedFloat32Array,
		budget: float) -> int:
	if frames.size() < 20:
		return 0
	var st := frame_stats(frames, cpu)
	var p50 := st.x / 1000.0
	var p90 := st.y / 1000.0
	if p50 > budget * 1.1 or p90 > budget * 1.35:
		return -1
	if p50 <= budget * 1.04 and p90 <= budget * 1.2:
		return 1
	return 0


## `[kadr p50, kadr p90, CPU işi p50, orta kadr]`, millisaniyə ilə.
static func frame_stats(frames: PackedFloat32Array, cpu: PackedFloat32Array) -> Vector4:
	if frames.is_empty():
		return Vector4.ZERO
	var f := frames.duplicate()
	f.sort()
	var c := cpu.duplicate()
	c.sort()
	var n := f.size()
	var total := 0.0
	for x in f:
		total += x
	return Vector4(f[n / 2], f[mini(int(float(n) * 0.9), n - 1)],
		c[c.size() / 2] if not c.is_empty() else 0.0, total / float(n)) * 1000.0


## Real cihazın ölçüsü bir sətirdə — konsola yazılır (uzaqdan sazlama ilə oxunur).
func perf_line(dpr: float) -> String:
	return "[perf] %s · kətan %.2f · kadr p50 %.1f / p90 %.1f ms (orta %.0f FPS) · CPU %.1f ms · hədd %d FPS · GPU %s" % [
		Const.quality_name(int(Net.quality)), dpr, res_stats.x, res_stats.y,
		1000.0 / maxf(res_stats.w, 0.001), res_stats.z, Settings.frame_cap(), Const.gpu_label()]


## Minixəritə saniyədə [constant MINIMAP_HZ] dəfə yenilənir, hər kadr yox.
##
## Əvvəl hər kadr çağırılırdı və hər dəfə 26 maneəni də təzədən çəkirdi:
## brauzerdə (4× yavaş CPU) kadr başına ~2.8 ms — oyunun ən böyük xərclərindən
## biri, halbuki xəritədə nöqtə kadrda bir pikseldən az yerini dəyişir. İndi
## maneələr ayrı qatdadır (bax [member Minimap._dots_layer]) və burada yalnız
## nöqtələr yenilənir.
func _update_minimap(delta: float) -> void:
	_minimap_wait -= delta
	if _minimap_wait > 0.0:
		return
	_minimap_wait = 1.0 / (MINIMAP_HZ * (0.5 if Net.quality == Const.Quality.MINIMUM else 1.0))
	var dots := []
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible:
			continue
		# Dördüncü sahə YOLDAŞDIR: xəritədə hamı eyni dolu nöqtə idi, yəni
		# komanda rejimlərində yoldaş rəqibdən seçilmirdi
		# (bax [method Minimap._draw]).
		dots.append([v.position, Palette.germ_color(v.color_index),
			gid == my_id, v.is_ally])
	_hud.minimap.broken = _broken
	_hud.minimap.set_dots(dots)


# ---------------------------------------------------------------- mikroblar

func _render_germs(render_time: float) -> void:
	# Öz mikrobun proqnozdan gəlir — şəbəkə gecikməsi olmadan, amma iki tick
	# arasında yumşaldılmış (bax [member _pos_prev]).
	var mine := _ensure_germ(my_id, Net.nickname, my_color, Net.species)
	mine.apply(_shown_pos(), _shown_aim(), me.balls, me.capacity, me.safe_t > 0.0, true,
		me.super_t > 0.0)
	# Öz toqquşma ellipsin proqnozun sürətindən qurulur — rəqibin topu sənə
	# məhz bu ellipslə "dəyir" (bax [method _remote_shot_pos]), gövdə də onun içində qalır.
	mine.net_vel = me.vel
	# Aura yalnız HƏQİQƏTƏN işlədilə bilən superdə yanır: doluluq tamdır, amma
	# top çatmırsa (kirpikli), düymə kimi aura da susur.
	mine.super_ready = me.super_ready()
	_visuals[my_id]["seen"] = _clock

	var pair := _bracket(render_time)
	if pair.is_empty():
		return
	var older := _index_germs(pair["a"])
	var newer := _index_germs(pair["b"])
	var alpha: float = pair["alpha"]
	var extra := float(pair.get("extra", 0.0))

	for gid in newer:
		if gid == my_id:
			continue
		var n: Array = newer[gid]
		var o: Array = older.get(gid, n)
		# Növ bayraq bitlərindən gəlir — ayrıca sahə göndərilmir (bax [enum Const.GFlag]).
		var kind := Const.species_from(
			(int(n[Const.GF.FLAGS]) & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)
			# Ad və rəng snapshot-da GƏLMİR — reyestrdən oxunur (bax [method Net.on_roster]).
		# Reyestr hələ çatmayıbsa, mikrob adsız və neytral rənglə çəkilir; növbəti
		# etibarlı paket onu düzəldir. Boş ad qısa müddət qalır, çünki reyestr
		# mikrob yaranan kimi göndərilir.
		var info: Array = _roster.get(gid, ["", 0])
		var v := _ensure_germ(gid, String(info[0]), int(info[1]), kind)
		# Komanda bayraqda `team + 1` kimi gəlir; 0 komandasız deməkdir.
		var tm := ((int(n[Const.GF.FLAGS]) & Const.GFlag.TEAM_MASK)
			>> Const.GFlag.TEAM_SHIFT) - 1
		v.is_ally = _my_team >= 0 and tm == _my_team and gid != my_id

		var pos := Vector2(float(o[Const.GF.X]), float(o[Const.GF.Y])).lerp(
			Vector2(float(n[Const.GF.X]), float(n[Const.GF.Y])), alpha)
		var aim := lerp_angle(float(o[Const.GF.AIM]), float(n[Const.GF.AIM]), alpha)
		v.net_vel = Vector2(float(o[Const.GF.VX]), float(o[Const.GF.VY])).lerp(
			Vector2(float(n[Const.GF.VX]), float(n[Const.GF.VY])), alpha)
		if extra > 0.0:
			# Bufer qurudu: son sürətlə qısa müddət irəli (bax [constant EXTRAP_MAX]).
			pos = _clip_to_walls(pos, pos + v.net_vel * extra)
		var flags := int(n[Const.GF.FLAGS])
		v.apply(pos, aim, int(n[Const.GF.BALLS]), int(n[Const.GF.CAP]),
			(flags & Const.GFlag.SAFE) != 0, true,
			(flags & Const.GFlag.SUPER) != 0)
		# Kənar ehtiyatı gövdədən çıxan hər şeyi örtür: ayaqlar (1.75 r) və hazır
		# ultinin aurası (1.25 × halo). Ən geniş şey — ayaqlının toru (4 r) — yalnız
		# super açıq olanda var və ehtiyat yalnız onda böyüyür: həmişə 4 r götürəndə
		# ekrandan kənardakı mikrobların çoxu "görünən" sayılırdı. Kamera
		# düzbucaqlısı əvvəlki kadrdandır, onun bir kadrlıq sürüşməsi də içindədir.
		var r := Const.germ_radius(int(n[Const.GF.CAP]))
		var reach := r * (Const.NET_RADIUS + 0.5) if (flags & Const.GFlag.SUPER) != 0 \
			and kind == Const.Species.HELIOZOAN else r * 2.2
		v.on_screen = _view_rect.grow(reach + 40.0).has_point(pos)
		# AŞAĞI keyfiyyətdə rəqibin FORMASI saniyədə 30 dəfə yenilənir (bax
		# [member GermVisual.redraw_step]); öz mikrobun həmişə hər kadr.
		v.redraw_step = _remote_redraw_step()
		_watch_visible_bush(gid, pos, Const.germ_radius(int(n[Const.GF.CAP])))
		# RƏQİBİN ultisi hazırdırmı? Doluluq bayraqda onsuz da gəlirdi
		# ([enum Const.GFlag]), amma indiyə qədər heç yerdə göstərilmirdi.
		# Qayda [method Sim.GermState.super_ready] ilə eynidir.
		var charge := (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
		v.super_ready = charge >= Const.SUPER_MAX \
			and (flags & Const.GFlag.SUPER) == 0 \
			and int(n[Const.GF.BALLS]) >= Const.super_min_balls(int(kind))
		_visuals[gid]["seen"] = _clock


func _ensure_germ(gid: int, germ_name: String, color: int,
		species: Const.Species) -> GermVisual:
	var entry: Dictionary = _visuals.get(gid, {})
	if not entry.is_empty():
		return entry["node"]
	var v := GermVisual.new()
	# Öz adın yazılmır — sən həmişə mərkəzdəsən (bax [member GermVisual.show_name]).
	v.show_name = gid != my_id
	v.setup(color, germ_name, gid == my_id, species)
	v.lod = 1 if Net.quality == Const.Quality.MINIMUM else 0
	# Gövdə toqquşma ellipsindən bayıra çıxmasın: mərkəzi gövdədən keçən top
	# həmişə dəyməlidir (bax [method GermVisual._fit_hit]).
	v.hit_fit = true
	# "Blunk" atəş anında yox, topun membranı YARDIĞI anda çalınır. Gecikmə
	# mikrobun ölçüsündən asılıdır, ona görə vaxtı görüntü node-u özü bilir.
	v.broke_through.connect(_on_broke_through)
	_entities.add_child(v)
	_visuals[gid] = {"node": v, "seen": _clock}
	return v


## Top gövdəni tərk etdi. Öz mikrobun tam səslə, başqaları sönük eşidilir —
## eyni qayda [method _flush_fx]-dəki `eject` üçün də keçərlidir.
func _on_broke_through(local: bool) -> void:
	Sfx.play("blunk", 0.05, 0.0 if local else -6.0)


## Rənginə görə mikrobun görüntüsünü tapır. Bir dünyada iki eyni rəngli mikrob
## olmur ([method World._free_color]), ona görə rəng kimlikdir — hadisələrdə
## ayrıca id sahəsi göndərilmir.
## Mikrobun gövdəsini atəş istiqamətində dartır — top içəridən zorlayaraq
## çıxır (bax [method GermVisual.eject]). "Blunk" səsi buradan YOX, gövdə
## pərdəni yaranda siqnalla gəlir.
func _eject_from(color_index: int, angle: float) -> void:
	var v := _germ_by_color(color_index)
	if v != null:
		v.eject(angle)


func _germ_by_color(color_index: int) -> GermVisual:
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.burst and v.color_index == color_index:
			return v
	return null


## Render vaxtını əhatə edən iki snapshot-u tapır.
func _bracket(render_time: float) -> Dictionary:
	if _snaps.is_empty():
		return {}
	# Anlar tick-dən və İNDİKİ bazadan hesablanır ([method _tt]) — həmişə monotondur.
	# Sondan axtarılır: göstərilən an adətən ən təzə snapshot-ların yanındadır.
	var newest_t := _tt(_snaps[-1]["d"])
	if render_time >= newest_t:
		# Bufer qurudu — ən təzə vəziyyət + sürətlə ən çox [constant EXTRAP_MAX] irəli.
		var last: Array = _snaps[-1]["d"]
		return {"a": last, "b": last, "alpha": 1.0,
			"extra": minf(render_time - newest_t, EXTRAP_MAX)}
	for i in range(_snaps.size() - 2, -1, -1):
		var t0 := _tt(_snaps[i]["d"])
		if t0 <= render_time:
			var t1 := _tt(_snaps[i + 1]["d"])
			var span := maxf(t1 - t0, 0.0001)
			return {"a": _snaps[i]["d"], "b": _snaps[i + 1]["d"],
				"alpha": clampf((render_time - t0) / span, 0.0, 1.0)}
	# Render saatı buferin ƏVVƏLİNDƏDİR (yenicə başladıq) — ən köhnəsi göstərilir.
	var first: Array = _snaps[0]["d"]
	return {"a": first, "b": first, "alpha": 1.0}


static func _index_germs(snap: Array) -> Dictionary:
	var out := {}
	for e in snap[Const.Snap.GERMS]:
		out[int(e[Const.GF.ID])] = e
	return out


# ---------------------------------------------------------------- toplar

## Atılan toplar düz xətlə sabit sürətlə gedir, ona görə interpolyasiya
## əvəzinə sonuncu məlum nöqtədən hesablanır — nəticə tamamilə hamardır.
## Sıçrayanda server yeni istiqamət göndərir və hesablama sıfırlanır.
##
## ── Öz topun BAŞQA zaman xəttindədir ─────────────────────────────────────
## Bu faylın başındakı üç zaman xətti burada toqquşur. Rəqiblər 100 ms geridə
## çəkilir, ÖZ mikrobun isə proqnozdan — yəni İNDİ. Top da rəqiblərlə eyni
## gecikməyə salınsaydı (və salınırdı), öz atdığın top mikrobunun 100 ms
## əvvəlki yerində doğulardı: sürəti 420 px/s olduğuna görə bu, 42 piksel,
## yəni mikrobun radiusundan (28 px) BÖYÜK bir məsafədir.
##
## Ona görə öz topunu serverin topu ÇƏKMİR — onu [ShotPrediction] çəkir:
## atəş anında mikrobun mərkəzindən çıxır, divardan özü sıçrayır və ekranda
## gördüyün rəqibə dəyən kimi zərbə elə o kadrda göstərilir (bax
## [method _step_own_shots]). Serverin öz topu gələndə proqnozla birləşir və
## gizli qalır; yalnız proqnozun heç tanımadığı top (bir-birinə uyğun gəlməyən
## atəş) köhnə yolla çəkilir.
##
## Qalan hər şey (rəqib topları, qida) gecikməli xəttdə qalır — onların
## sahibi də oradadır.
##
## Sahib RƏNGDƏN tanınır: bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color]), ona görə snapshot-a sahib sahəsi əlavə
## etməyə ehtiyac yoxdur — eyni üsul [method _explode]-da da işlənir.
## ── Zaman xətti ─────────────────────────────────────────────────────────
## Topun mövqeyi snapshot-un GƏLDİYİ ana bağlanır, mikroblar kimi
## ([method _bracket]). Əvvəl `t` hər kadr `_clock` yazılırdı: top iki snapshot
## arasında yerində durur, 30 Hz-lə pillə-pillə gedirdi və mikrobdan 0–33 ms
## (jitter-lə daha çox) GERİDƏ çəkilirdi. Ölçülüb — rəqib artıq parlayırdı,
## top isə ona hələ 15–30 ms sonra çatırdı: gözə "içindən keçdi" görünürdü.
func _render_shots(render_time: float) -> void:
	if not _last_snap.is_empty() and _last_snap_t > _shots_synced_t:
		_shots_synced_t = _last_snap_t
		for e in _last_snap[Const.Snap.SHOTS]:
			var sid := int(e[Const.SF.ID])
			var color := int(e[Const.SF.COLOR])
			var dir := Vector2(float(e[Const.SF.DX]), float(e[Const.SF.DY]))
			var view: Dictionary = _shot_views.get(sid, {})
			if view.is_empty():
				var ghost: ShotPrediction.Ghost = null
				if color == my_color and not _own_sids.has(sid):
					ghost = _own_shots.claim(sid, dir, _clock,
						Vector2(float(e[Const.SF.X]), float(e[Const.SF.Y])))
					if ghost != null:
						_own_sids[sid] = _clock
						ghost.rewind = float(e[Const.SF.REWIND])
						# Proqnozun xətti serverinkindən nə qədər YANA sürüşüb (test ölçüsü).
						if ghost.first_dir.dot(dir) > 0.99:
							var srv := Vector2(float(e[Const.SF.X]), float(e[Const.SF.Y]))
							var off := absf((ghost.pos - srv).cross(dir.normalized()))
							hit_stats["lines"] += 1
							hit_stats["line_off_sum"] += off
							hit_stats["line_off_max"] = maxf(float(hit_stats["line_off_max"]), off)
				if ghost != null or _own_sids.has(sid):
					# Görüntünü proqnoz daşıyır. Sprite-sız görüntü yenə saxlanılır:
					# yoxsa növbəti snapshot eyni topu yenidən "yeni" sayıb çəkərdi.
					view = {"node": null, "ghost": ghost}
				else:
					var spr := _take(_shot_pool, _shot_layer)
					_dress_shot(spr, color)
					view = {"node": spr, "mine": color == my_color, "color": color}
				_shot_views[sid] = view
			view["seen"] = _clock
			view["base"] = Vector2(float(e[Const.SF.X]), float(e[Const.SF.Y]))
			view["dir"] = dir
			# Mikroblarla eyni tick saatı (bax [method _tt]). Tick saxlanılır, an hər kadr
			# İNDİKİ bazadan hesablanır (aşağıda): baza erkən paketdə enəndə mikroblar
			# dərhal sürüşür, top isə növbəti snapshot-a qədər köhnə bazada qalıb onlardan
			# 20–60 ms (8–25 px) aralı çəkilirdi.
			view["tick"] = _snap_tick
			# Server topu `life`-ın sıfıra çatdığı tick-də HƏRƏKƏTSİZ silir: qalan uçuş
			# `life − 1 tick`-dir (bax [method ShotPrediction._sim_tick]).
			view["life"] = maxf(float(e[Const.SF.LIFE]) - Const.TICK_DELTA, 0.0)
			view["rewind"] = float(e[Const.SF.REWIND])

	for sid in _shot_views:
		var view: Dictionary = _shot_views[sid]
		var spr: Sprite2D = view["node"]
		if spr == null:
			continue
		if view.has("tick"):
			view["t"] = _floor + float(view["tick"]) * Const.TICK_DELTA
			view["dies"] = float(view["t"]) + float(view["life"])
		if bool(view.get("absorbed", false)):
			continue
		# Komet uçduğu tərəfə baxır — sıçrayışdan sonra serverin yeni istiqaməti ilə.
		spr.rotation = Vector2(view["dir"]).angle()
		if not view.get("mine", false):
			spr.position = _remote_shot_pos(sid, view, spr, render_time)
			continue
		var at: float = _clock if view.get("mine", false) else render_time
		spr.position = Vector2(view["base"]) \
			+ Vector2(view["dir"]) * Const.SHOT_SPEED * (at - float(view["t"]))

	# İzlər mövqelər oturandan SONRA yığılır. İki ayrı yol var — öz topun
	# proqnozdan, rəqibinki gecikməli xəttdən — və hər ikisi eyni izə düşür.
	for tid in _shot_views:
		var node: Sprite2D = _shot_views[tid]["node"]
		if node != null and not bool(_shot_views[tid].get("absorbed", false)):
			_trails.push(tid, node.position, node.modulate)
	_render_ghosts()
	# Mövqelər oturub — indi hansı topun kol yarpağının üstündə olduğu seçilir.
	_layer_shots()
	_trails.queue_redraw()


## Yad topun ekrandakı yeri — sənə yaxınlaşdıqca SƏNİN zaman xəttinə keçir.
##
## ── Niyə ─────────────────────────────────────────────────────────────────
## Rəqibin topu interpolyasiya ilə keçmişdə (100 ms + RTT) çəkilir, öz mikrobun
## isə proqnozla İNDİ. Top ekranda sənə çatanda server səni artıq başqa yerdə
## görür: ölçülüb — rəqib toplarının ~18%-i gövdənin içindən zərbəsiz keçirdi.
##
## Botun topu düz xətlə sabit sürətlə uçur, yəni onu İNDİYƏ çəkmək dəqiqdir:
## serverdə top `t` anında haradadırsa, sənin mikrobun həmin `t`-də ekrandakı
## yerindədir (girişin serverə RTT/2 sonra çatır). Uzaqda top keçmişdə qalır —
## atanın yanından çıxmalıdır; sənə [constant SELF_NEAR] px qalanda tam indidədir.
## Keçid bir istiqamətlidir: qaçanda top geri sürüşmür.
##
## Yalnız SƏNƏ tərəf uçan top köçürülür ([method _aimed_at_me]). Yanından
## keçən top başqasına gedir və o başqası keçmişdə çəkilir: köçürülsəydi,
## hədəfindən irəli qaçıb onun içindən keçərdi. Ölçülüb — köçürülən toplar
## üçüncü mikrobların içindən zərbəsiz keçirdi.
##
## Sənə dəyəndə top DAYANIR və zərbə dərhal göstərilir. Server eyni anı yoxlayır
## — botun geri sarması yoxdur ([member Sim.lag_comp] yalnız insana aiddir).
## İnsanın topu keçmişdə qalır: server onu atıcının gördüyü keçmişə qarşı
## yoxlayır və burada proqnoz yanılardı.
##
## ── İnsanın topu ────────────────────────────────────────────────────────
## Server insanın topunu qurbanın `rewind` saniyə ƏVVƏLKİ yerinə qarşı yoxlayır
## (atanın gördüyü an — bax [member Sim.lag_comp]). Ona görə top hər yerdə
## hədəflərindən `rewind` qədər QABAQDA çəkilir: keçmişdə çəkilən mikrobların
## yanında da, sənin indiki mikrobunun yanında da. Onda ekrandakı toxunuş
## serverin qərarı ilə eyni anda olur. Əvvəl insanın topu bot kimi sayılırdı
## (id-dən), sonra isə keçmişdə qalırdı — hər iki halda səndən zərbəsiz keçirdi.
## Botun topunda `rewind` 0-dır.
func _remote_shot_pos(sid: int, view: Dictionary, spr: Sprite2D, render_time: float) -> Vector2:
	var base: Vector2 = view["base"]
	var dir: Vector2 = view["dir"]
	var t := float(view["t"])
	var lead := float(view.get("rewind", 0.0))
	var ahead := minf(render_time + lead, float(view.get("dies", INF))) - t
	var past := base + dir * Const.SHOT_SPEED * ahead
	# Son snapshot-dan İRƏLİ çəkilən top divardan keçməməlidir; geridəki yolu isə
	# top özü keçib gəlib, yoxlamağa ehtiyac yoxdur (26 maneə, hər kadr, hər top).
	if ahead > 0.0:
		past = _clip_to_walls(base, past)
	# Top server ömrü bitəndə silinir. İndiyə çəkilən top ondan o yana getməməlidir:
	# ölçülüb — bir neçə yalançı "sənə dəydi" topun ömrünün son anına düşürdü.
	var dies := float(view.get("dies", INF))
	if render_time + lead >= dies:
		# Keçmişdə də ömrü bitib: serverdə top həmin tick-də qidaya çevrilir, qida
		# da snapshot ilə elə o yerdə görünür. Top ölü yerində donub qalmamalıdır —
		# qalanda yanından keçən mikrob onun "içindən keçirdi" (probe belə tutub).
		spr.visible = false
		return past
	# "İndi" də göstərilən anla bağlıdır: bufer quruyub rəqib dünyası dayananda sənin
	# zaman xəttindəki top da dayanır, yetişəndə birlikdə yetişir. Normalda bu, `_clock`-dur.
	var now_line := minf(_clock, render_time + _delay)
	var present := base + dir * Const.SHOT_SPEED * (minf(now_line + _rtt + lead, dies) - t)
	# Öz trixosistin topu məhz bu yerdə yoxlayır (bax [method _pop_remote_shots]).
	var present_prev: Vector2 = view.get("present", present)
	view["present"] = present
	# Proqnozun yeri, çəkilən yer yox: donmadan sonrakı 100–400 px-lik düzəliş sönərkən
	# "sənə dəydi" proqnozu serverin səni görmədiyi yerdə verilərdi.
	var me_at := _pred_pos()
	var near := Const.germ_radius(me.capacity) + SELF_NEAR
	var col := int(view.get("color", -1))
	var drawn: Vector2 = view.get("shown", past)
	var k := 0.0
	# Top sənin zaman xəttinə İSTƏNİLƏN xəttdə sənə tərəf gedəndə keçir: indiki
	# yeri sənə yaxınlaşanda (sənə dəyəcək), və ya ekrandakı surəti hələ sənə
	# çatmayanda. İkincisi nöqtə-nöqtə atəşdir: sən topla eyni tərəfə gedirsən,
	# sənin xəttində top artıq yanından keçib (serverdə dəymir), keçmişdə çəkilən
	# surəti isə hələ arxandadır — orada qalsa gövdəndən keçib gedərdi. Ölçülüb:
	# yalnız indiki yerə baxanda belə top ekranda səndən keçirdi.
	#
	# Aradakı mikrob topu SƏNDƏN əvvəl tuta bilər — o keçmişdə çəkilir və
	# irəli çəkilən top onun içindən keçərdi.
	if (_aimed_at_me(present, dir, me_at) or _aimed_at_me(drawn, dir, me_at)) \
			and not _shot_blocked_before(present, me_at, col) \
			and not _shot_blocked_before(drawn, me_at, col):
		k = 1.0 - smoothstep(near, near + SELF_BLEND,
			minf(present.distance_to(me_at), drawn.distance_to(me_at)))
	# İlk kadrda top elə doğulduğu yerdə görünür; sonra yalnız hamar irəliləyir.
	if view.has("k"):
		var was := float(view["k"])
		var dt := clampf(_clock - float(view["k_at"]), 0.0, 0.1)
		var room := _release_room(drawn, dir, col) if k < was else -1.0
		if room >= 0.0:
			# Səndən yayınan top qabaqdakı mikrobun zaman xəttinə qayıdır (bax [method _release_room]).
			k = maxf(k, was - dt * release_rate(was, past.distance_to(present), room))
		else:
			k = maxf(was, minf(k, was + dt * SELF_CATCH_RATE))
	# İrəli çəkilən hissə divardan keçməməlidir: sıçrayışı server hələ deməyib.
	var aim := past.lerp(present, k)
	var pos := _clip_to_walls(past, aim)
	var clipped := pos.distance_squared_to(aim) > 0.01
	var prev: Vector2 = view.get("shown", pos)
	# Server sıçrayışı deyəndə top köhnə yoldan yenisinə KÖÇÜR — bu sıçrayış topun
	# uçduğu yol deyil. Ölçülüb: köçmə xətti gövdəni kəsdi və serverdə sənə heç
	# yaxınlaşmayan top "əmin dəydi" sayıldı. Belə kadrda parça yenidən başlayır.
	var jumped := Vector2(view.get("shown_dir", dir)).dot(dir) < 0.999
	if jumped:
		prev = pos
	view["shown_dir"] = dir
	# Keçid yarımçıq ikən top gövdənə çatır (sən onun yoluna gec girdin): keçmişdə
	# çəkilən top səndən keçərdi, halbuki sənin xəttində — serverin sənə qarşı
	# yoxladığı xəttdə — o başqa yerdədir. Top elə indi sənin xəttinə köçür, və
	# dəyib-dəymədiyi O XƏTTİN öz yolu ilə yoxlanılır, köçmə sıçrayışı ilə yox.
	if k < 0.99 and not view.has("no_claim") and not _finished \
			and Sim.seg_ellipse_hit_t(prev, pos, me_at,
				Sim.hit_shape(int(me.species), me.capacity, me.vel)) >= 0.0:
		k = 1.0
		pos = _clip_to_walls(past, present)
		clipped = pos.distance_squared_to(present) > 0.01
		prev = pos if jumped else present_prev
		# İz köçmə sıçrayışını çəkməsin — yenidən başlayır.
		_trails.drop(sid)
	view["k"] = k
	view["k_at"] = _clock
	view["shown"] = pos
	if now_line + _rtt + lead >= dies and k > 0.5:
		# Sənin zaman xəttində top artıq YOXDUR — ömrü bitib.
		spr.visible = false
		return pos
	if k < 0.99 or _finished or me.safe_t > 0.0 or view.has("no_claim"):
		return pos
	var shape := Sim.hit_shape(int(me.species), me.capacity, me.vel)
	var hit_t := Sim.seg_ellipse_hit_t(prev, pos, me_at, shape)
	if hit_t < 0.0:
		return pos
	var at := prev.lerp(pos, hit_t)
	# Top maneəyə çatıb və gövdənə yalnız MANEƏNİN SƏTHİNDƏ toxunur (sən maneənin
	# arxasındasan). Serverdə eyni `t`-də maneə qalib gəlir və top səkir — ölçülüb:
	# xətti gövdənin düz mərkəzindən keçən (0.01) "əmin" dəymə belə yalançı çıxdı.
	if clipped and at.distance_squared_to(pos) < 1.0:
		return pos
	# Yolda başqa mikrob varsa proqnoz edilmir: serverdə top ona dəyə bilər,
	# ekranda isə o mikrob keçmişdə çəkildiyi üçün top yanından keçir. Belə
	# "sənə dəydi" yalan olardı — qərar serverindir.
	#
	# İki hal var. ƏMİN dəymədə (xətt gövdənin dərinliyindən keçir, yolda başqa
	# mikrob yoxdur) zərbə elə bu kadrda göstərilir. SƏRHƏDDƏKİ dəymədə top yenə
	# gizlənir — içindən keçməsin — amma zərbə serverin sözünü gözləyir
	# ([method _queue_events]). Server dəyməni saymasa və topu göndərməyə davam
	# etsə, top geri qaytarılır ([method _undo_self_claims]).
	#
	# Yaxında superi hazır kirpikli varsa top ona çatmadan dağıla bilər — bot
	# bunu elə topu görən an edir, sən isə onun superini keçmişdə, gec görürsən.
	#
	# Öz trixosistin hazırdırsa da nəticə serverindir: superin girişi serverə hansı
	# tick-də çatırsa, top o tick-də dağılır. Əvvəl dəymə bir tick gözləyirdi — super
	# iki tick sonra açılanda (və ya şəbəkə yavaşlayanda) zərbə göstərilir, serverdə
	# isə top trixosistdən dağılırdı (ölçülüb, 0.15 dərinlikli "əmin" dəymə).
	var own_tricho := me.species == Const.Species.CILIATE and me.super_ready()
	var sure := _line_depth(at, dir, me_at, shape) <= self_sure_depth(me.vel, dir, shape) \
		and not _shot_blocked_before(past, at, col, SELF_SURE_GAP) \
		and not _proxy_blocks(at - dir * PROXY_LOOKBACK, at, col) \
		and not _rival_tricho_near(at, col) and not _congested() and not own_tricho
	view["absorbed"] = true
	spr.visible = false
	_trails.drop(sid)
	var claim := {"pos": at, "t": _clock, "color": col, "sid": sid, "soft": not sure,
		"dir": dir, "lead": lead}
	_self_claims.append(claim)
	if not sure:
		hit_stats["self_soft"] += 1
		return at
	hit_stats["self_pred"] += 1
	_self_hit_feel(at, col, dir)
	return at


## Sənin zaman xəttinə keçmiş top artıq sənə təhlükə deyil (yanından ötüb və
## ya sən çəkilmisən), qabağında isə başqa mikrob var. O mikrob KEÇMİŞDƏ
## çəkilir: top indidə qalsa, onun gövdəsindən keçərdi, halbuki serverdə top
## ora çatanda mikrob artıq başqa yerdədir. Ölçülüb (RTT 120, 90 s): 46
## toxunuşdan biri belə idi, ekranın ortasında — top səndən yayınıb qonşunun
## içindən keçdi, serverdə isə ömrü bitənə qədər heç kimə dəymədi.
##
## Belə top keçmişə qayıdır: yavaşıyır, geri getmir, və o mikrobla EYNİ zaman
## xəttinə düşür — dəyirsə zərbə vaxtında görünür, dəymirsə yanından keçir.
## Qabaqda mikrob yoxdursa, top indidə qalır: boş yerə yavaşımır.
##
## Qaytarır: qabaqdakı ilk mikroba qədər məsafə (px), yoxdursa -1.
func _release_room(drawn: Vector2, dir: Vector2, shooter_color: int) -> float:
	var best := -1.0
	for gid in _visuals:
		if gid == my_id:
			continue
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.safe or v.color_index == shooter_color:
			continue
		var shape := Sim.hit_shape(int(v.species), v.capacity, v.net_vel) \
			+ Vector3(SELF_SURE_GAP, SELF_SURE_GAP, 0.0)
		var t := Sim.seg_ellipse_hit_t(drawn, drawn + dir * SELF_RELEASE_LOOK, v.position, shape)
		if t >= 0.0 and (best < 0.0 or t * SELF_RELEASE_LOOK < best):
			best = t * SELF_RELEASE_LOOK
	return best


## Keçmişə qayıdışın sürəti (1/s): [param k] — topun indiki payı, [param gap] —
## iki zaman xətti arasındakı məsafə, [param room] — qabaqdakı mikroba qədər yol.
##
## Adi halda top [constant SELF_RELEASE_SPEED] qədər yavaşıyır. Mikrob yola
## qəfil girəndə bu çatmır — ölçülüb: bot topla sənin aranıza 27 px qalmış girdi,
## top 0.82 payla onun gövdəsindən keçdi. Onda sürət elə seçilir ki, pay mikroba
## çatmamış sıfıra ensin: `k·v / (room + k·gap)`. Top geri getmir — ən pis halda
## qısa an dayanıb keçmişin ona çatmasını gözləyir.
static func release_rate(k: float, gap: float, room: float) -> float:
	var g := maxf(gap, 1.0)
	var need := k * Const.SHOT_SPEED / (maxf(room, 0.0) + k * g)
	return minf(maxf(SELF_RELEASE_SPEED / g, need), 0.95 * Const.SHOT_SPEED / g)


## Kontakt nöqtəsinin yaxınlığında superi HAZIR kirpikli (atan yox) varmı.
##
## Bot trixosisti yaxınındakı topu görən an açır və top dağılır. Sən isə onun
## superini keçmişdə — RTT + interpolyasiya qədər gec — görürsən, topu isə öz
## zaman xəttində, yəni botun qərarından QABAQ. Belə dəymə əmin sayılmır.
## Ehtiyat məsafəsi botun o müddətdə gedə biləcəyi yoldur.
##
## Doluluq da ehtiyatla götürülür: snapshot yarım RTT köhnədir, bir dəymə isə
## doluluğa [constant Const.SUPER_ON_HIT] əlavə edir — o qədər əskik olan super
## artıq dolmuş ola bilər. Yer də ən təzə snapshot-dandır, ekrandakı keçmişdən yox.
func _rival_tricho_near(at: Vector2, shooter_color: int) -> bool:
	if _last_snap.is_empty():
		return false
	for row in _last_snap[Const.Snap.GERMS]:
		var gid := int(row[Const.GF.ID])
		if gid == my_id:
			continue
		var flags := int(row[Const.GF.FLAGS])
		var kind := (flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT
		if kind != int(Const.Species.CILIATE) or (flags & Const.GFlag.SUPER) != 0:
			continue
		var charge := (flags & Const.GFlag.CHARGE_MASK) >> Const.GFlag.CHARGE_SHIFT
		if charge < Const.SUPER_MAX - Const.SUPER_ON_HIT \
				or int(row[Const.GF.BALLS]) < Const.super_min_balls(kind):
			continue
		if int((_roster.get(gid, ["", -1]) as Array)[1]) == shooter_color:
			continue
		var reach := Const.germ_radius(int(row[Const.GF.CAP])) * Const.TRICHO_RADIUS + TRICHO_SLACK
		if Vector2(float(row[Const.GF.X]), float(row[Const.GF.Y])).distance_squared_to(at) \
				<= reach * reach:
			return true
	return false


## Kirpiklinin RTT + interpolyasiya müddətində gedə biləcəyi yol (px).
const TRICHO_SLACK := 60.0

## "Sənə dəydi"dən əvvəlki bu qədər yol (px) yaxın rəqiblərin KÖLGƏSİNƏ qarşı
## yoxlanılır (bax [method _proxy_blocks]) — təxminən iki tick-in yolu.
const PROXY_LOOKBACK := 30.0


## Topun sənə çatmazdan əvvəlki yolunda yaxın rəqibin KÖLGƏSİ varmı.
##
## Yanındakı rəqib ekranda keçmişdə çəkilir — sıxlaşmış döyüşdə 30–40 px geridə.
## Serverdə isə o, indiki yerindədir və top sənə çatmazdan ƏVVƏL ona dəyə bilər.
## Kölgə ([method _sync_proxies]) onun indiki yerinin təxminidir; top onun
## ellipsinə girirsə "sənə dəydi" əmin sayılmır və serveri gözləyir.
func _proxy_blocks(from: Vector2, to: Vector2, shooter_color: int) -> bool:
	for gid in pred.germs:
		if gid == my_id:
			continue
		if int((_roster.get(gid, ["", -1]) as Array)[1]) == shooter_color:
			continue
		var g: Sim.GermState = pred.germs[gid]
		var shape := Sim.hit_shape(int(g.species), g.capacity, g.vel) \
			+ Vector3(SELF_SURE_GAP, SELF_SURE_GAP, 0.0)
		if Sim.seg_ellipse_hit_t(from, to, g.pos, shape) >= 0.0:
			return true
	return false


## Öz trixosistin açıldı (proqnozda) — radiusdakı yad topları ekranda da dağıdır.
##
## Server eyni tick-də botların topunu dərhal, insanınkını isə `rewind` sonra
## dağıdır ([member Sim._blasts]) — sənin ekranında insanın topu elə o qədər
## qabaqda çəkilir, yəni hər iki halda top İNDİ olduğu yerdə yoxlanılır.
func _pop_remote_shots(reach: float) -> void:
	for sid in _shot_views:
		var view: Dictionary = _shot_views[sid]
		var spr: Sprite2D = view["node"]
		if spr == null or bool(view.get("absorbed", false)) or bool(view.get("mine", false)):
			continue
		var at: Vector2 = view.get("present", view.get("shown", spr.position))
		if at.distance_to(me.pos) > reach:
			continue
		view["absorbed"] = true
		view["no_claim"] = true
		spr.visible = false
		_trails.drop(sid)
		_spawn_fx("spark", spr.position, 0.4, Palette.germ_color(int(view.get("color", 0))))


## Botun topu sənə dəydi — qığılcım, səs, gövdənin zərbəsi.
func _self_hit_feel(at: Vector2, shooter_color: int, dir: Vector2) -> void:
	_spawn_fx("spark", at, 0.55, Palette.germ_color(shooter_color))
	Sfx.play("hit", 0.05)
	var mine_v := _germ_by_color(my_color)
	if mine_v != null:
		_impact_on(mine_v, at, shooter_color, dir)


## "Sənə dəydi"-nin ƏMİN sayıldığı dərinlik həddi (bax [constant SELF_SURE_DEPTH]).
##
## Sabit hədd dayanan və topa tərəf gedən mikrob üçündür. Topun yoluna DİK qaçanda
## isə yerinin xətası sürətlə böyüyür: [constant SELF_TIME_ERR] qədər zaman fərqində
## mikrob yolun yanına çəkilir. Ölçülüb: 140 px/s ilə dik qaçan mikrobda 0.59
## dərinlikli "əmin" dəymə serverdə yanından keçdi — sənin yerin 8 px, topun vaxtı
## isə ~2 tick fərqli idi. Xəta ellipsin topun yoluna DİK yarım-eninə bölünür.
static func self_sure_depth(vel: Vector2, dir: Vector2, shape: Vector3) -> float:
	var err := SELF_POS_ERR + absf(vel.cross(dir)) * SELF_TIME_ERR
	var n := dir.orthogonal().rotated(-shape.z)
	var half := sqrt(shape.x * shape.x * n.x * n.x + shape.y * shape.y * n.y * n.y)
	return minf(SELF_SURE_DEPTH, 1.0 - err / maxf(half, 1.0))


## Topun XƏTTİ ellipsin mərkəzindən nə qədər uzaqdan keçir: 0 = düz mərkəzdən,
## 1 = sərhədə toxunur (bax [constant SELF_SURE_DEPTH], [method Sim.line_depth]).
static func _line_depth(at: Vector2, dir: Vector2, center: Vector2, shape: Vector3) -> float:
	return Sim.line_depth(at, dir, center, shape)


## Top sənə tərəf uçurmu: sən onun qarşısındasan və xətti gövdənin
## [constant SELF_AIM_SLACK] px yaxınından keçir. Gövdə ən uzun oxu ilə
## götürülür — amöb hərəkətdə 1.4 dəfə uzanır (bax [method Sim.hit_shape]).
func _aimed_at_me(at: Vector2, dir: Vector2, me_at: Vector2) -> bool:
	var rel := me_at - at
	var reach := Const.germ_radius(me.capacity) * 1.4 + Const.SHOT_RADIUS + SELF_AIM_SLACK
	return rel.dot(dir) > -reach and absf(rel.cross(dir)) <= reach


## Topun [param from] → [param to] yolunda (atandan və özündən başqa) mikrob varmı.
## [param pad] mikrobların ellipsini böyüdür — "az qala dəyəcək" halı da sayılsın.
func _shot_blocked_before(from: Vector2, to: Vector2, shooter_color: int, pad := 0.0) -> bool:
	for gid in _visuals:
		if gid == my_id:
			continue
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.safe or v.color_index == shooter_color:
			continue
		var shape := Sim.hit_shape(int(v.species), v.capacity, v.net_vel) + Vector3(pad, pad, 0.0)
		if Sim.seg_ellipse_hit_t(from, to, v.position, shape) >= 0.0:
			return true
	return false


## Parçanın ilk bərk maneəyə və ya qabın kənarına qədər olan hissəsi.
func _clip_to_walls(from: Vector2, to: Vector2) -> Vector2:
	var best := 1.0
	var list := pred.obstacles
	for i in list.size():
		var o := list[i]
		var t := Sim._seg_circle_t(from, to, Vector2(o.x, o.y), o.z + Const.SHOT_RADIUS)
		if t < 0.0 or t >= best:
			continue
		if i < _broken.size() and DishMap.wall_gone(_broken[i]):
			continue
		if not DishMap.blocks_shot(int(o.w)):
			continue
		best = t
	var at := from.lerp(to, best)
	var limit := Const.WORLD_RADIUS - Const.SHOT_RADIUS
	if at.length() > limit:
		at = at.normalized() * limit
	return at


## Proqnozun toplarını çəkir və ölənlərin sprite-ını hovuza qaytarır.
##
## İzin açarı MƏNFİDİR: serverin top id-ləri müsbətdir və [ShotTrails] onları
## bir lüğətdə saxlayır — eyni ədəd iki topu bir izə birləşdirərdi.
func _render_ghosts() -> void:
	var live := {}
	var color := Palette.germ_color(my_color)
	for g in _own_shots.ghosts:
		if not g.alive:
			continue
		live[g.id] = true
		var spr: Sprite2D = _ghost_nodes.get(g.id)
		if spr == null:
			spr = _take(_shot_pool, _shot_layer)
			_dress_shot(spr, my_color)
			_ghost_nodes[g.id] = spr
		spr.modulate = color
		spr.position = g.pos
		spr.rotation = g.dir.angle()
		_trails.push(-g.id, g.pos, color)
	for gid in _ghost_nodes.keys():
		if live.has(gid):
			continue
		_give(_shot_pool, _ghost_nodes[gid])
		_ghost_nodes.erase(gid)
		_trails.drop(-int(gid))


## Öz atəşin: proqnoz topu mikrobun MƏRKƏZİNDƏN doğulur.
##
## [param membrane] atəş hadisəsindəki nöqtədir: membranın deşildiyi yer,
## yəni mərkəzdən düz bir radius aralıda. [method Sim._fire] həm onu, həm
## topun özünü eyni `g.pos`-dan qurur, ona görə mərkəzi geri hesablamaq olur.
##
## [param age] — atəş nə qədər ƏVVƏL olub. Proqnozun özü atanda sıfırdır; atəşi
## yalnız serverin FIRE hadisəsindən öyrənəndə isə top artıq yoldadır və
## indiyə çatdırılır (bax [method _queue_events]).
##
## [param view] — atəşin görünən tick-i ([member Sim.PlayerInput.view_tick]):
## proqnoz topu rəqibləri serverin yoxladığı tick-də görür (bax [ShotPrediction]).
func _spawn_own_shot(membrane: Vector2, aim: float, age := 0.0, view := -1.0) -> void:
	var dir := Vector2.from_angle(aim)
	var g := _own_shots.spawn(membrane - dir * Const.germ_radius(me.capacity), dir,
		_clock - age, view)
	if age > 0.0:
		_own_shots.catch_up(g, age, _clock, pred.obstacles, _broken)


## Öz toplarını bir kadr irəli aparır və təmaslarını dərhal göstərir.
##
## Top serverin tick addımı ilə uçur və hər tick-in parçası rəqiblərin MƏHZ
## serverin yoxladığı tick-dəki halına qarşı yoxlanılır ([method _ghost_targets],
## [member Sim.lag_comp]) — ona görə burada gördüyün dəymə orada da sayılır.
##
## Qaydalar [method Sim._step_shots]-dakı kimidir: doğuş qalxanlı və yoldaş
## mikrob keçilir, amöbün qabığı topu sıçradır.
func _step_own_shots(delta: float) -> void:
	_hold_claims(delta)
	_prune_claims()
	# Top ömründən uzun yaşayan id artıq heç bir snapshot-a düşə bilməz.
	for sid in _own_sids.keys():
		if _clock - float(_own_sids[sid]) > Const.SHOT_LIFETIME + 1.0:
			_own_sids.erase(sid)
	if _own_shots.ghosts.is_empty():
		return
	_screen_targets.clear()
	_tick_targets.clear()
	for gid in _visuals:
		if gid == my_id:
			continue
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst or v.safe or v.is_ally or v.color_index == my_color:
			continue
		_screen_targets.append({
			"pos": v.position,
			"radius": Const.germ_radius(v.capacity),
			# Serverlə EYNİ toqquşma ellipsi (bax [method Sim.hit_shape]).
			"shape": Sim.hit_shape(int(v.species), v.capacity, v.net_vel),
			"key": gid,
		})
	for c in _own_shots.step(delta, _clock, pred.obstacles, _broken, _ghost_targets):
		_on_own_contact(c)


## Bu kadrın ekrandakı hədəfləri və tick-lərə görə hədəflər (kadr boyu keş).
var _screen_targets := []
var _tick_targets := {}


## Proqnoz topunun hədəfləri server tick-i [param t]-də (kəsrli).
##
## Rəqiblər snapshot buferindən, TICK-ə görə interpolyasiya olunur — gəliş
## vaxtına görə yox. Ekrandakı rəqib gəliş vaxtı ilə çəkilir və snapshot-lar
## jitter-lə gələndə tick-in yarısı qədər qabaqda və ya geridə olur; server isə
## qurbanı dəqiq `tick − rewind`-də yoxlayır. Bayraqlar (qalxan, kist, komanda)
## YENİ snapshot-dandır — ekranda da belədir, serverin tarixçəsi də onu belə
## oxuyur ([method Sim._rewound_bits]).
##
## Tick bilinmirsə (mənfi) və ya bufer boşdursa — ekrandakı yerlər.
##
## Tick ən təzə snapshot-dan SONRADIRSA da ekrandakı yerlər götürülür. Bu, yalnız bufer
## quruyanda olur (şəbəkə donub): rəqiblər ekranda son sürətləri ilə irəli çəkilir, sonra
## dayanır ([constant EXTRAP_MAX]). Əvvəl top ən təzə snapshot-dakı yerlərə qarşı yoxlanırdı,
## ekranda isə rəqib başqa yerdə idi — top onun gövdəsindən zərbəsiz keçirdi (ölçülüb).
func _ghost_targets(t: float) -> Array:
	if t < 0.0 or _snaps.size() < 2 \
			or t > float((_snaps[-1]["d"] as Array)[Const.Snap.TICK]) + 0.001:
		return _screen_targets
	var key := snappedf(t, 0.001)
	if _tick_targets.has(key):
		return _tick_targets[key]
	var a: Array = _snaps[0]["d"]
	var b: Array = a
	for i in range(_snaps.size() - 1, -1, -1):
		var d: Array = _snaps[i]["d"]
		if float(d[Const.Snap.TICK]) <= t:
			a = d
			b = _snaps[i + 1]["d"] if i + 1 < _snaps.size() else d
			break
	var ta := float(a[Const.Snap.TICK])
	var tb := float(b[Const.Snap.TICK])
	var alpha := clampf((t - ta) / (tb - ta), 0.0, 1.0) if tb > ta else 1.0
	var older := _index_germs(a)
	var out := []
	for n in b[Const.Snap.GERMS]:
		var gid := int(n[Const.GF.ID])
		if gid == my_id:
			continue
		var flags := int(n[Const.GF.FLAGS])
		if flags & Const.GFlag.SAFE:
			continue
		var team := ((flags & Const.GFlag.TEAM_MASK) >> Const.GFlag.TEAM_SHIFT) - 1
		if _my_team >= 0 and team == _my_team:
			continue
		var o: Array = older.get(gid, n)
		var kind := Const.species_from(
			(flags & Const.GFlag.SPECIES_MASK) >> Const.GFlag.SPECIES_SHIFT)
		var cap := int(n[Const.GF.CAP])
		var vel := Vector2(float(o[Const.GF.VX]), float(o[Const.GF.VY])).lerp(
			Vector2(float(n[Const.GF.VX]), float(n[Const.GF.VY])), alpha)
		out.append({
			"pos": Vector2(float(o[Const.GF.X]), float(o[Const.GF.Y])).lerp(
				Vector2(float(n[Const.GF.X]), float(n[Const.GF.Y])), alpha),
			"radius": Const.germ_radius(cap),
			"shape": Sim.hit_shape(int(kind), cap, vel),
			"key": gid,
		})
	_tick_targets[key] = out
	return out


## Proqnoz topu bir şeyə toxundu — görüntü serveri GÖZLƏMƏDƏN oynanır.
##
## Hər təmas [member _claims]-ə yazılır: serverin eyni hadisəsi sonra gələndə
## tanınır və ikinci dəfə göstərilmir (bax [method _queue_events]).
func _on_own_contact(c: Dictionary) -> void:
	var at: Vector2 = c["pos"]
	var col := Palette.germ_color(my_color)
	match int(c["kind"]):
		ShotPrediction.Contact.HIT:
			var entry: Dictionary = _visuals.get(int(c["key"]), {})
			if entry.is_empty():
				return
			var victim: GermVisual = entry["node"]
			if _take_early_hit(at, victim.color_index):
				# Server bu dəyməni artıq deyib və zərbə göstərilib — ikinci dəfə yox.
				hit_stats["predicted"] += 1
				hit_stats["confirmed"] += 1
				return
			var claim := {"pos": at, "t": _clock, "hit": true, "victim": int(c["key"]),
				"vcol": victim.color_index, "dir": c["dir"], "ghost": c["ghost"]}
			var shooter: ShotPrediction.Ghost = c["ghost"]
			_claims.append(claim)
			if float(c.get("depth", 0.0)) > OWN_SURE_DEPTH or bool(c.get("late", false)) \
					or _burst_pending(victim.color_index) or _rival_tricho_near(at, my_color) \
					or _congested() or (shooter != null and shooter.sid < 0) \
					or (shooter != null and shooter.rewind >= Const.REWIND_MAX - 0.5 * Const.TICK_DELTA):
				# Nəticəsi proqnozun xətasından asılı olan dəymə — qurbanın kənarına,
				# topun ömrünün sonunda ([constant ShotPrediction.LATE_LIFE]), artıq
				# partlamış qurbana, yanında superi dolu kirpikli olanda (bot trixosisti
				# topu görən an açır, sən isə onu `rewind` qədər gec görürsən — ölçülüb,
				# mərkəzdən keçən 0.02 dərinlikli dəymə belə itdi), və ya şəbəkə
				# sıxılanda ([method _congested]), və ya server atəşi HƏLƏ təsdiqləməyibsə:
				# yaxın məsafədə top rəqibə RTT-dən tez çatır, soyuma isə jitter-də server
				# ilə proqnoz arasında bir neçə tick sürüşə bilir — ölçülüb, atəşin
				# təsdiqindən əvvəlki 23 dəymədən 3-ünün topu serverdə heç atılmamışdı
				# (sonrakı 310-dan 3-ü yalançı idi), və ya server geri sarmanı həddə
				# ([constant Const.REWIND_MAX]) kəsibsə: o zaman hədəfləri atıcının
				# gördüyü tick-dən daha YENİ tick-də yoxlayır. Top gövdədə dayanır, zərbə
				# serverin sözünü gözləyir (bax [method _match_claim], [method _undo_own_soft]).
				claim["soft"] = true
				hit_stats["own_soft"] += 1
				return
			_own_hit_flash(victim, at, Vector2(c["dir"]))
			hit_stats["predicted"] += 1
		ShotPrediction.Contact.BOUNCE, ShotPrediction.Contact.CRACK:
			_spawn_fx("spark", at, 0.55, col)
			Sfx.play("hit", 0.05)
			if int(c["kind"]) == ShotPrediction.Contact.CRACK:
				var o: Vector4 = DishMap.obstacles()[int(c["key"])]
				_juice.crust(at, (at - Vector2(o.x, o.y)).normalized(), o.z * 0.46, false)
			_map_hit(at)
			_claims.append({"pos": at, "t": _clock, "hit": false})
		_:
			# Ömrü bitdi: serverdə qidaya çevrilir və snapshot ilə görünəcək.
			# Top suya "enir" — kiçik sıçrantı və dalğa.
			_ripple(at, 22.0, Color(col, 0.40), "splash", SPLASH_TIME)
			_ripple(at, 30.0, Color(Palette.TEXT, 0.26))


## Şəbəkə sıxılıbmı: gediş-gəliş son saniyələrin ən aşağısından xeyli uzundur.
##
## Sıxılmada girişlər serverə DƏSTƏ ilə çatır, server isə hər tick yalnız
## sonuncunu işlədir: aradakılar birləşir, onların vaxtı sıxılır. Ölçülüb (RTT
## 180 → 443 ms, 14 giriş bir tick-də): proqnozun əvvəlkindən 31 tick sonra
## açdığı atəşi server 20 tick sonra gördü, soyuma hələ bitməmişdi və atəş heç
## açılmadı — ekranda isə top uçub rəqibə "dəydi". Sənin serverdəki yerin də belə
## anda proqnozdan fərqlənir. Sıxılma bitənə qədər proqnozun dəymələri əmin
## sayılmır — serverin sözünü gözləyir.
func _congested() -> bool:
	return _rtt_floor < INF and _rtt > _rtt_floor + maxf(RTT_SPIKE, _rtt_floor * 0.5)


## Qurbanın partlaması artıq gəlib, amma hələ göstərilməyib (interpolyasiyanı gözləyir).
##
## Onu başqasının topu doldurub: serverdə öz topun ora çatanda qurban artıq
## yoxdur və dəymə sayılmır — ekranda isə hələ sağdır. Ölçülüb (RTT 120 ms):
## təsdiqlənməyən öz dəymələrinin sonuncusu belə idi — topun qurbanı 0.56
## dərinliklə vurdu, qurban 100 ms sonra başqa botun topundan partladı. Belə
## dəymə də serverin sözünü gözləyir.
func _burst_pending(color: int) -> bool:
	for e in _fx_queue:
		if int(e["kind"]) == Const.EvKind.BURST and int(e["ci"]) == color:
			return true
	return false


## Öz topunun rəqibə dəyməsi: qığılcım, səs və qurbanın zərbəsi.
##
## Öz zərbənin qığılcımı başqalarınkından iridir (0.55): gözün izlədiyi yer
## məhz budur.
func _own_hit_flash(victim: GermVisual, at: Vector2, dir: Vector2) -> void:
	_spawn_fx("spark", at, 0.7, Palette.germ_color(my_color))
	Sfx.play("hit", 0.05)
	_impact_on(victim, at, my_color, dir, true)


## Proqnozun təmasını serverin hadisəsi ilə uyğunlaşdırır.
##
## Uyğun gəlirsə hadisə ARTIQ göstərilib və təsdiq sayılır — qeyd silinir ki,
## növbəti topun hadisəsi onu yenidən "tapmasın". Növ də uyğun gəlməlidir:
## divar sıçrayışı rəqibə dəyməni təsdiqləyə bilməz.
##
## Hədd daxilindəki İLK proqnoz yox, ƏN YAXINI götürülür, qurban bilinirsə
## (bax [method Const.hit_victim]) yalnız onunku. Eyni rəqibə yarım saniyə
## arayla iki top atılanda server ikincinin dəyməsini deyirdi, təsdiq isə 40–70 px
## aralıdakı BİRİNCİYƏ yazılırdı — ölçülüb.
func _match_claim(at: Vector2, hit: bool, victim_color := -1) -> bool:
	var reach := CLAIM_REACH_HIT if hit else CLAIM_REACH_WALL
	var best := -1
	var best_d := INF
	for i in _claims.size():
		var c := _claims[i]
		if bool(c["hit"]) != hit:
			continue
		if victim_color >= 0 and int(c.get("vcol", victim_color)) != victim_color:
			continue
		var d := Vector2(c["pos"]).distance_to(at)
		if d <= reach and d < best_d:
			best = i
			best_d = d
	if best < 0:
		return false
	var found := _claims[best]
	_claims.remove_at(best)
	if hit and bool(found.get("soft", false)):
		# Sərhəddəki dəymə — zərbə təsdiq GƏLƏN an, topun dayandığı yerdə oynanır.
		hit_stats["own_soft_conf"] += 1
		var entry: Dictionary = _visuals.get(int(found.get("victim", -1)), {})
		if not entry.is_empty():
			_own_hit_flash(entry["node"], Vector2(found["pos"]), Vector2(found.get("dir", Vector2.RIGHT)))
		return true
	if hit:
		hit_stats["confirmed"] += 1
		hit_stats["confirm_s"] += _clock - float(found["t"])
	return true


## Botun sənə proqnozlaşdırılmış dəyməsini serverin hadisəsi ilə tutuşdurur.
##
## HIT hadisəsi qurbanı demir, yalnız ATANIN rəngini. Əvvəl yalnız məsafə
## yoxlanırdı: yanındakı mikroba 110 px daxilində dəyən BAŞQA topun zərbəsi
## "sənin təsdiqin" sayılırdı və ekranda göstərilmirdi.
##
## Sərhəddəki proqnozun zərbəsi burada, təsdiq GƏLƏN an oynanır: top onsuz da
## gövdənin qarşısında gizlənib, interpolyasiyanı gözləmək zərbəni yalnız
## gecikdirərdi.
func _match_self_claim(at: Vector2, shooter: int) -> bool:
	# Ən yaxın proqnoz — eyni bot bir-birinin ardınca atanda ilki yox (bax [method _match_claim]).
	var best := -1
	var best_d := INF
	for i in _self_claims.size():
		var c := _self_claims[i]
		var d := Vector2(c["pos"]).distance_to(at)
		if int(c["color"]) == shooter and d <= CLAIM_REACH_HIT and d < best_d:
			best = i
			best_d = d
	if best < 0:
		return false
	var found := _self_claims[best]
	_self_claims.remove_at(best)
	if bool(found.get("soft", false)):
		hit_stats["self_soft_conf"] += 1
		_self_hit_feel(at, shooter, Vector2(found.get("dir", Vector2.RIGHT)))
	else:
		hit_stats["self_conf"] += 1
	return true


## Server təsdiqləmədi, top isə hələ uçur — gizlədilmiş top GERİ qaytarılır.
##
## Serverin son snapshot-unda top sənin yerinin (insanın topunda `rewind` qədər
## əvvəlki yerinin — server onu məhz ona qarşı yoxlayır) yanından keçib uzaqlaşırsa,
## dəymə olmayıb. Top bir də sənə "dəyə" bilməz (`no_claim`): serverin öz qərarı
## artıq bəllidir.
##
## Əvvəl bu, vaxtla (RTT + ehtiyat), sonra serverin təsdiqlədiyi girişlə ölçülürdü.
## İkisi də şəbəkə sıxılanda yanılır: proqnozun zaman xətti serverdən bir neçə
## tick qabağa düşür və top serverdə hələ sənə ÇATMAMIŞ olur — ölçülüb, bir
## seriyada server 21 topu vurmuşdu, client isə onları "dəymədi" sayıb qaytarmışdı.
## Snapshot-dakı yerlərə baxan qayda gecikmədən asılı deyil.
func _undo_self_claims() -> void:
	var i := 0
	while i < _self_claims.size():
		var c := _self_claims[i]
		var view: Dictionary = _shot_views.get(int(c.get("sid", -1)), {})
		var row := _server_row(my_id, float(c.get("lead", 0.0))) if not view.is_empty() else []
		if not row.is_empty() and float(view.get("seen", 0.0)) >= _last_snap_t \
				and shot_gone_past(view["base"], view["dir"],
					Vector2(float(row[Const.GF.X]), float(row[Const.GF.Y])),
					Const.germ_radius(int(row[Const.GF.CAP]))):
			view["absorbed"] = false
			view["no_claim"] = true
			var spr: Sprite2D = view["node"]
			if spr != null:
				spr.visible = true
			hit_stats["self_undo"] += 1
			hit_stats["self_soft_miss" if bool(c.get("soft", false)) else "self_false"] += 1
			_self_claims.remove_at(i)
			continue
		i += 1


## Serverin topu hədəfin yanından keçib UZAQLAŞIR: hədəfdən topa vektor onun
## uçuş istiqamətindədir və top gövdənin əhatəsindən [constant UNDO_MARGIN] qədər
## çıxıb. Hədəfə hələ çatmayan top gözlənilir — nə qədər gecikirsə-gecikisin.
static func shot_gone_past(ball: Vector2, dir: Vector2, target: Vector2, radius: float) -> bool:
	var rel := ball - target
	return rel.dot(dir) > 0.0 \
		and rel.length() > radius * 1.4 + Const.SHOT_RADIUS + UNDO_MARGIN


## Mikrobun serverdəki sətri son snapshot-dan [param back] saniyə əvvəl — buferdəki
## ən yaxın tick-dən. Server insanın topunu hədəfin məhz o qədər əvvəlki yerinə
## qarşı yoxlayır. Tapılmasa boş massiv.
func _server_row(gid: int, back: float) -> Array:
	if _snaps.is_empty():
		return []
	var want := float((_snaps[-1]["d"] as Array)[Const.Snap.TICK]) - back / Const.TICK_DELTA
	var best: Array = []
	var best_d := INF
	for s in _snaps:
		var d: Array = s["d"]
		var gap := absf(float(d[Const.Snap.TICK]) - want)
		if gap < best_d:
			best_d = gap
			best = d
	for row in best[Const.Snap.GERMS]:
		if int(row[Const.GF.ID]) == gid:
			return row
	return []


## Öz topunun proqnozdan ƏVVƏL gələn server dəymələri (bax [method _queue_events]).
func _take_early_hit(at: Vector2, victim_color: int) -> bool:
	for i in _early_hits.size():
		var h := _early_hits[i]
		if (int(h["victim"]) < 0 or int(h["victim"]) == victim_color) \
				and Vector2(h["pos"]).distance_to(at) <= CLAIM_REACH_HIT:
			_early_hits.remove_at(i)
			return true
	return false


## Sərhəddəki öz dəyməsini server saymadı, topu isə hələ göndərir — top GERİ
## qaytarılır və serverin yeri ilə uçmağa davam edir.
##
## Serverin topu qurbanın (serverin onu yoxladığı, `rewind` qədər əvvəlki) yerinin
## yanından keçib uzaqlaşırsa, dəymə olmayıb (bax [method shot_gone_past]; eyni
## qayda botun sənə dəyməsində — [method _undo_self_claims]).
func _undo_own_soft() -> void:
	var i := 0
	while i < _claims.size():
		var c := _claims[i]
		var g: ShotPrediction.Ghost = c.get("ghost")
		var view: Dictionary = _shot_views.get(g.sid, {}) \
			if bool(c.get("soft", false)) and g != null and g.sid >= 0 else {}
		if view.is_empty() or float(view.get("seen", 0.0)) < _last_snap_t:
			i += 1
			continue
		var row := _server_row(int(c.get("victim", -1)), float(view.get("rewind", 0.0)))
		if row.is_empty() or not shot_gone_past(view["base"], view["dir"],
				Vector2(float(row[Const.GF.X]), float(row[Const.GF.Y])),
				Const.germ_radius(int(row[Const.GF.CAP]))):
			i += 1
			continue
		if view["node"] == null:
			var spr := _take(_shot_pool, _shot_layer)
			_dress_shot(spr, my_color)
			view["node"] = spr
			view["mine"] = true
			view["color"] = my_color
		hit_stats["own_soft_miss"] += 1
		hit_stats["own_soft_undo"] += 1
		_claims.remove_at(i)


## Bağlantı ilişəndə ([method _link_stalled]) proqnozlar QOCALMIR.
##
## Təsdiq — serverin HIT hadisəsi — donmadan sonrakı dəstədədir. Əvvəl 1.2 s-dən uzun
## donmada proqnoz dəymələri vaxtı keçib "boş" sayılırdı, dəstədəki təsdiq isə ikinci,
## ayrı zərbə kimi göstərilirdi. İndi gözləmə saatı donma boyu dayanır.
func _hold_claims(delta: float) -> void:
	if not _link_stalled():
		return
	for list in [_claims, _self_claims, _early_hits]:
		for c in list:
			c["t"] = float(c["t"]) + delta


func _prune_claims() -> void:
	while not _early_hits.is_empty() and _clock - float(_early_hits[0]["t"]) > EARLY_HIT_KEEP:
		_early_hits.pop_front()
	_undo_self_claims()
	while not _self_claims.is_empty() and _clock - float(_self_claims[0]["t"]) > CLAIM_KEEP:
		# Server topu da artıq göndərmir (başqasına dəyib, vaxtı bitib) — geri
		# qaytarılacaq bir şey yoxdur.
		hit_stats["self_soft_miss" if bool(_self_claims[0].get("soft", false)) else "self_false"] += 1
		_self_claims.pop_front()
	_undo_own_soft()
	while not _claims.is_empty() and _clock - float(_claims[0]["t"]) > CLAIM_KEEP:
		if bool(_claims[0].get("soft", false)):
			# Sərhəddəki dəymə: zərbə göstərilməyib, server də saymadı.
			hit_stats["own_soft_miss"] += 1
		# Ekranda göstərilən, serverin isə heç vaxt saymadığı dəymə.
		elif bool(_claims[0]["hit"]):
			hit_stats["ghost"] += 1
			# Qurban artıq yoxdursa, onu başqası partladıb və ya görüşdən çıxıb.
			var entry: Dictionary = _visuals.get(int(_claims[0].get("victim", -1)), {})
			if entry.is_empty() or (entry["node"] as GermVisual).burst:
				hit_stats["ghost_gone"] += 1
		_claims.pop_front()


## Super halqasının vədi: öz zərbənin +3-ü dərhal görünür.
##
## Vəd serverin rəqəmi ona çatanda, super işlədilib doluluq SIFIRLANANDA (baza
## düşür) və ya [constant PROMISE_HOLD] bitəndə sönür. "Hazır" bayrağı isə vəddən
## ASILI DEYİL — düymə yalnız serverin doluluğu tam olanda işləyir.
func _promise_charge(amount: int) -> void:
	var from := _shown_charge()
	_charge_base = me.charge
	_charge_promise = mini(from + amount, Const.SUPER_MAX)
	_charge_until = _clock + PROMISE_HOLD


func _shown_charge() -> int:
	if _charge_promise < 0:
		return me.charge
	if me.charge >= _charge_promise or me.charge < _charge_base or _clock > _charge_until:
		_charge_promise = -1
		return me.charge
	return _charge_promise


# ---------------------------------------------------------------- qida

## Qida demək olar hərəkətsizdir (yalnız partlayışdan səpiləndə sürüşür),
## ona görə interpolyasiya lazım deyil — mövqe yumşaq şəkildə çəkilir.
func _render_food(_render_time: float) -> void:
	if _last_snap.is_empty():
		return
	var flat: PackedFloat32Array = _last_snap[Const.Snap.FOOD]
	var i := 0
	while i + Const.FOOD_STRIDE <= flat.size():
		var fid := int(flat[i + Const.FF.ID])
		var target := Vector2(flat[i + Const.FF.X], flat[i + Const.FF.Y])
		i += Const.FOOD_STRIDE

		var view: Dictionary = _food_views.get(fid, {})
		if view.is_empty():
			var spr := _take(_food_pool, _food_layer)
			spr.texture = _tex["food"]
			# Sprite-ın parlaq haşiyəsi var, ona görə görünən top gerçək
			# radiusdan bir az böyükdür — toqquşma ilə uyğunlaşdırılır.
			#
			# MƏNFİ id = SPOR (bax [Sim.FoodState]): iri yığın, tutum verir.
			# Bayraq id-nin işarəsindədir, ona görə axına bir ədəd də əlavə
			# olunmur.
			var k := FOOD_SCALE
			if fid < 0:
				k = SPORE_SCALE * Const.SPORE_RADIUS / Const.FOOD_RADIUS
			else:
				spr.modulate = FOOD_DIM
			spr.scale = Vector2(k, k)
			spr.position = target
			view = {"node": spr}
			_food_views[fid] = view
		var node: Sprite2D = view["node"]
		node.position = node.position.lerp(target, 0.4)
		view["seen"] = _clock


# ---------------------------------------------------------------- təmizlik

## Hovuzdan sprite götürür; hovuz boşdursa yenisini qurur.
func _take(pool: Array[Sprite2D], layer: Node) -> Sprite2D:
	if pool.is_empty():
		var fresh := Sprite2D.new()
		layer.add_child(fresh)
		return fresh
	var spr: Sprite2D = pool.pop_back()
	spr.visible = true
	spr.modulate = Color.WHITE
	spr.rotation = 0.0
	spr.scale = Vector2.ONE
	return spr


## Uçan topun görünüşü: komet, sahibinin rəngində (bax [constant SHOT_HEAD]).
## Fırlanma hər kadr mövqe ilə birlikdə yazılır — istiqamət sıçrayışda dəyişir.
func _dress_shot(spr: Sprite2D, color: int) -> void:
	spr.texture = _tex["shot"]
	spr.modulate = Palette.germ_color(color)
	spr.scale = Vector2(SHOT_SCALE, SHOT_SCALE)
	spr.offset = SHOT_HEAD


## Sprite-ı hovuza qaytarır — ağacda qalır, sadəcə gizlənir.
##
## Görünməyən node çəkilmir, yəni çəkiliş çağırışına düşmür; ağacdan
## çıxarıb geri qoymaq isə hovuzun qazancını yeyərdi.
func _give(pool: Array[Sprite2D], spr: Sprite2D) -> void:
	if spr == null or not is_instance_valid(spr):
		return
	spr.visible = false
	pool.append(spr)


## Görüş sahəsindən çıxan obyektlərin görüntüsü silinir.
## Kiçik möhlət verilir, çünki render 100 ms geridədir.
func _sweep_views() -> void:
	# Möhlət göstərilən anın gecikməsi qədərdir (bax [constant VIEW_GRACE]) — gecikmə indi dəyişkəndir.
	var grace := _delay + Const.TICK_DELTA
	var cutoff := _clock - grace
	# Top görüntüsü yalnız TƏZƏ snapshot-da olmayanda silinir. Donmada snapshot gəlmir:
	# əvvəl bütün rəqib topları 133 ms sonra yox olurdu, indi rəqiblərlə birlikdə dayanır.
	var shot_cutoff := minf(_clock, _last_snap_t + Const.TICK_DELTA) - grace
	for dict in [_visuals, _food_views, _shot_views]:
		var dead := []
		var cut := shot_cutoff if is_same(dict, _shot_views) else cutoff
		for key in dict:
			if float(dict[key].get("seen", 0.0)) < cut:
				dead.append(key)
		for key in dead:
			var node: Node = dict[key]["node"]
			# Qida və toplar HOVUZA qayıdır, silinmir. Mikrobun görüntüsü isə
			# mürəkkəbdir (ad etiketi, növ, animasiya vəziyyəti) — onu təkrar
			# işlətmək qurmaqdan ucuz deyil, ona görə o silinir.
			if is_same(dict, _food_views):
				_give(_food_pool, node as Sprite2D)
			elif is_same(dict, _shot_views):
				_give(_shot_pool, node as Sprite2D)
			else:
				if _germ_bushes.has(key):
					var old_bush := int(_germ_bushes[key])
					if old_bush >= 0:
						_bush_rustles[old_bush] = _clock
					_germ_bushes.erase(key)
				node.queue_free()
			dict.erase(key)
		# Ölən topun izi də getməlidir: yoxsa `_tracks` böyüyür və izin
		# qalığı ekranda donmuş qalır. `is_same` şərtdir — id-lər yalnız
		# ÖZ lüğəti daxilində unikaldır, mikrobun id-si topunku ilə üst-üstə
		# düşə bilər və onda canlı iz silinərdi.
		if is_same(dict, _shot_views):
			for key in dead:
				_trails.drop(key)


# ---------------------------------------------------------------- effektlər

func _queue_events(list: Array, at: float) -> void:
	for e in list:
		var kind := int(e[Const.EF.KIND])
		# Öz hadisələrimi artıq oynatmışam, ikinci dəfə göstərmirəm:
		#   • ATƏŞ    — proqnozda, gecikmə olmadan (bax [method _do_tick]);
		#   • PARTLAMA — serverin "sən partladın" mesajında (bax [method _on_you_burst]).
		# Partlama filtri xüsusilə vacibdir: keçsəydi, öz ölümün İKİ dəfə
		# çəkilər (biri böyük, biri normal ölçüdə) və `you_burst` ilə `burst`
		# səsləri üst-üstə düşərdi.
		if int(e[Const.EF.COLOR]) == my_color \
				and (kind == Const.EvKind.FIRE or kind == Const.EvKind.BURST):
			# Atəşi proqnoz HƏMİŞƏ oynatmır. Məşq rejimində yerli dünyanın
			# tick-i proqnozdan ƏVVƏL işləyir və soyuma sayğacını düzəldir,
			# ona görə proqnoz öz atəşini heç görmür — qığılcım da, səs də,
			# topun doğuş nöqtəsi də itir.
			#
			# Təsdiq gözləyən proqnoz topu elə bu sualın cavabıdır: varsa,
			# atəş proqnozda oynadılıb; yoxdursa, yalnız server bilir və top
			# da, effekt də burada doğulmalıdır.
			if kind != Const.EvKind.FIRE:
				continue
			var seen := _own_shots.take_unseen_fire(_clock, MUZZLE_GRACE)
			if not seen:
				var at_pos := Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y]))
				# Top indi DOĞULMUR — atəşi açan giriş göndəriləndə doğulub. Server onu
				# həmin tick-də təsdiqlədi ([member _last_ack]); proqnozun zaman xətti də
				# elə budur. Gəliş anında doğulsaydı, top serverinkindən ~RTT geri
				# qalardı: server dəyməni ƏVVƏL sayardı, gec top isə sonra ikinci, boş
				# zərbə göstərərdi. Ölçülüb — bu, təsdiqlənməyən dəymələrin əsas səbəbi idi.
				var age := clampf(_clock - float(_input_time.get(_last_ack, _clock)), 0.0, 0.5)
				_spawn_own_shot(at_pos, float(e[Const.EF.ARG]), age)
				_own_shots.take_unseen_fire(_clock, MUZZLE_GRACE)
				_spawn_fx("spark", at_pos, 0.5, Palette.germ_color(my_color))
				_juice.muzzle(at_pos, float(e[Const.EF.ARG]), Palette.germ_color(my_color))
				Sfx.play("eject", 0.06)
				_eject_from(my_color, float(e[Const.EF.ARG]))
			# Atəş istəyi SERVERİN atəşi ilə bitir, onlayn oyunda isə proqnozunku
			# ilə ([method _do_tick]) — burada yalnız proqnozun görmədiyi atəş.
			#
			# Məşqdə yerli dünya proqnozdan ƏVVƏL işləyir, ona görə proqnoz öz
			# atəşini ya heç görmür, ya da soyuma gözlənəndə bir tick ERKƏN görür
			# (barışıqdan sonra bir tick də özü addımlayır). Erkən atəşdə istək
			# proqnozda bitirdisə, yerli dünya atəş bitini heç almırdı: ekranda top
			# uçurdu, serverdə isə yox idi (QA: soyumanın son 0.2 s-indəki
			# toxunuşların hamısı). İndi istək yerli dünya atana qədər yaşayır və
			# proqnozun erkən topu burada onun təsdiqi kimi götürülür.
			if not seen or _local_world != null:
				_on_own_fire(float(e[Const.EF.ARG]))
			continue
		var pos := Vector2(float(e[Const.EF.X]), float(e[Const.EF.Y]))
		var when := at
		if int(e[Const.EF.COLOR]) == my_color:
			# Məşqdə yerli dünya superi proqnozdan ƏVVƏL emal edir və proqnoz onu
			# görmür (bax [method _reconcile]) — trixosistin dağıtdığı toplar burada
			# ekrandan da götürülür. Onlayn oyunda bunu proqnoz elə o tick edir.
			if kind == Const.EvKind.SUPER and float(e[Const.EF.ARG]) > 0.0 \
					and _local_world != null:
				_pop_remote_shots(float(e[Const.EF.ARG]))
			# Öz superin: proqnoz onu artıq oynadıbsa atılır, oynatmayıbsa
			# interpolyasiyanı gözləmir — öz mikrobun indidə çəkilir.
			if kind == Const.EvKind.SUPER:
				if _take_own_super():
					continue
				when = -INF
			# ÖZ topunun təması proqnozda artıq göstərilib — ikinci dəfə yox.
			if kind == Const.EvKind.HIT and _match_claim(pos, float(e[Const.EF.ARG]) > 0.5,
					Const.hit_victim(float(e[Const.EF.ARG]))):
				continue
			# Proqnozun GÖRMƏDİYİ təmas (rəqib kolda idi, geri sarma həddi
			# aşılmışdı). Öz topun indidə uçur və bu nöqtəni artıq keçib —
			# interpolyasiyanı gözləmək zərbəni yalnız daha da gecikdirərdi.
			if kind == Const.EvKind.HIT or kind == Const.EvKind.BREAK:
				when = -INF
			# Rəqibə dəyən top serverdə bitib, ekranda isə hələ uçur — dayandırılır.
			# Top bu nöqtəni RTT + interpolyasiya qədər qabaqlayıb (~100 px);
			# növbəti öz topun isə ən azı bir saniyəlik yol, 420 px aralıdadır.
			# Divar sıçrayışında (arg 0) top yaşayır, ona görə toxunulmur.
			if kind == Const.EvKind.HIT and float(e[Const.EF.ARG]) > 0.5:
				_own_shots.stop_nearest(pos, 220.0, _clock)
				hit_stats["server_only"] += 1
				# Proqnoz topu bu dəyməyə hələ ÇATMAYA bilər (gec tapılan atəş, eyni
				# paketdə gələn atəş və dəymə). Çatanda bu qeyd onu təsdiqləyir —
				# yoxsa zərbə iki dəfə göstərilir, proqnoz isə "boş" sayılırdı.
				_early_hits.append({"pos": pos, "t": _clock,
					"victim": Const.hit_victim(float(e[Const.EF.ARG]))})
				# Test ölçüsü: ən yaxın proqnoz nə qədər uzaqda və nə qədər köhnə idi.
				var near := [INF, -1.0]
				for c in _claims:
					if bool(c["hit"]) and Vector2(c["pos"]).distance_to(pos) < float(near[0]):
						near = [Vector2(c["pos"]).distance_to(pos), _clock - float(c["t"])]
				if (hit_stats["miss"] as Array).size() < 20:
					(hit_stats["miss"] as Array).append("%.0fpx/%.0fms"
						% [float(near[0]), float(near[1]) * 1000.0])
		elif kind == Const.EvKind.HIT and Const.hit_victim(float(e[Const.EF.ARG])) == my_color \
				and _match_self_claim(pos, int(e[Const.EF.COLOR])):
			# Proqnoz bu dəyməni artıq ya göstərib, ya da [method _match_self_claim]
			# sərhəddəki proqnozun zərbəsini elə indi oynadıb.
			continue
		elif kind == Const.EvKind.BURST \
				and _clock - float(_my_victims.get(int(e[Const.EF.COLOR]), -INF)) <= KILL_LINK:
			# Sənin topunla dolan rəqib partladı — öldürmə anı gecikməməlidir.
			#
			# Zərbəni proqnoz dərhal göstərib, "+5 TUTUM" da snapshot gələn kimi
			# çıxır ([method _watch_capacity]); partlayış isə növbədə 100 ms
			# interpolyasiya gözləyirdi və mükafat öldürmədən ƏVVƏL görünürdü.
			when = -INF
		_fx_queue.append({
			# Bazaya NİSBƏTƏN saxlanılır (tick × TICK_DELTA): baza erkən paketdə dərhal
			# enir və mikroblar onunla birlikdə sürüşür ([method _tt]) — mütləq an
			# saxlansaydı, zərbə toxunuşdan o qədər əvvəl və ya sonra yanardı.
			"at": when - _floor,
			"kind": kind,
			"pos": pos,
			"arg": float(e[Const.EF.ARG]),
			# Xam indeks də saxlanılır: partlayışda mikrobun görüntüsünü
			# tapmaq üçün lazımdır (bax [method _explode]).
			"ci": int(e[Const.EF.COLOR]),
			"color": Palette.germ_color(int(e[Const.EF.COLOR])),
		})


## Göstərilən an sıçrayanda (uzun donmadan sonra) bu qədər köhnə SAF görüntü
## effektləri — atəş qığılcımı, qida udma, divar sıçrayışı — oynadılmır: onlarla səs
## bir kadrda çalınardı. Zərbə, partlama, super və divarın dağılması həmişə oynanır.
const FX_STALE := 0.5


func _flush_fx(render_time: float) -> void:
	var i := 0
	while i < _fx_queue.size():
		var e: Dictionary = _fx_queue[i]
		var at := float(e["at"]) + _floor
		if at > render_time:
			i += 1
			continue
		var fx_kind := int(e["kind"])
		if at < render_time - FX_STALE and (fx_kind == Const.EvKind.FIRE \
				or fx_kind == Const.EvKind.ABSORB \
				or (fx_kind == Const.EvKind.HIT and float(e["arg"]) <= 0.5)):
			_fx_queue.remove_at(i)
			continue
		var pos: Vector2 = e["pos"]
		var col: Color = e["color"]
		match int(e["kind"]):
			Const.EvKind.FIRE:
				_spawn_fx("spark", pos, 0.4, col)
				_juice.muzzle(pos, float(e["arg"]), col)
				Sfx.play("eject", 0.06, -6.0)
				_eject_from(int(e["ci"]), float(e["arg"]))
			Const.EvKind.SUPER:
				_play_super(pos, float(e["arg"]), int(e["ci"]))
			Const.EvKind.SPORE:
				# Tutum artımı — partlatma ilə eyni mükafat, ona görə eyni səs.
				_spawn_fx("spark", pos, 0.9, Palette.FOCUS)
				if int(e["ci"]) == my_color:
					Sfx.play("level_up")
					_add_shake(4.0)
			Const.EvKind.ABSORB:
				_spawn_fx("spark", pos, 0.28, Palette.FOOD)
				var eater := _germ_by_color(int(e["ci"]))
				var target := eater.position if eater != null else pos
				_juice.absorb(pos, target, col)
				# Yalnız ÖZ udmağın eşidilir: 10 mikrobun hamısının səsi
				# eşidilsəydi, arxa fon fasiləsiz xışıltı olardı.
				if col == Palette.germ_color(my_color):
					Sfx.play("absorb", 0.08)
			Const.EvKind.HIT:
				_spawn_fx("spark", pos, 0.55, col)
				Sfx.play("hit", 0.05)
				# `arg` iki HIT növünü ayırır (bax [method Sim._bounce] və
				# [method Sim._inject]): 0 = divardan sıçradı, 1 = rəqibin
				# içinə keçdi. Zərbə yalnız ikincisidir — sıçrayışda
				# parıldayacaq mikrob yoxdur.
				if float(e["arg"]) > 0.5:
					_on_impact(pos, int(e["ci"]), Const.hit_victim(float(e["arg"])))
				else:
					# Qabıq zərbəsi adi divar sıçrayışından mövqeyə görə ayrılır;
					# şəbəkə hadisəsinə yeni sahə əlavə etmək yalnız görüntü üçün olmazdı.
					var brittle := _brittle_at(pos, false)
					if brittle >= 0:
						var o: Vector4 = DishMap.obstacles()[brittle]
						_juice.crust(pos, (pos - Vector2(o.x, o.y)).normalized(),
							o.z * 0.46, false)
					_map_hit(pos)
			Const.EvKind.BREAK:
				# Divar dağıldı. Partlayış effekti TƏKRAR işlədilir: hadisə
				# eyni cinsdəndir (bir şey dağılıb ətrafa səpilir) və oyunçu
				# onu artıq tanıyır. Rəng maneənin öz rəngidir, mikrobunku yox.
				var fx := BurstFx.new()
				fx.position = pos
				fx.setup(Palette.MUCUS_EDGE, maxf(float(e["arg"]), 20.0), 6,
					false, _tex["burst"])
				_fx.add_child(fx)
				_juice.crust(pos, Vector2.RIGHT, maxf(float(e["arg"]), 20.0), true)
				_break_chunks(_brittle_at(pos, true))
				Sfx.play("burst", 0.05, -4.0)
				if pos.distance_to(me.pos) < 600.0:
					_add_shake(7.0)
			Const.EvKind.BURST:
				_explode(pos, maxf(float(e["arg"]), 12.0), int(e["ci"]), false)
				Sfx.play("burst", 0.05)
				if pos.distance_to(me.pos) < 500.0:
					_add_shake(10.0)
					# Öldürmə yaxında baş verdi — ekran bir anlıq DONUR.
					# Uzaqdakı partlama üçün donma qoyulmur: oyunçunun heç bir
					# əlaqəsi olmayan hadisə onun idarəsini kəsməməlidir.
					_freeze = FREEZE_TIME
					_punch = maxf(_punch, 0.07)
		_fx_queue.remove_at(i)


## Partlayan mikrobun görüntüsünü partlayışla ƏVƏZ edir.
##
## Mikrobun özünü DƏRHAL susdurmaq şərtdir: server onu artıq göndərmir, amma
## görüntüsü [constant VIEW_GRACE] müddətincə saxlanılır (bax [method _sweep_views]) —
## susdurmasaq partlayışın ortasında sağ-salamat mikrob dayanardı.
##
## Mikrob RƏNGƏ görə tapılır. Bir dünyada iki eyni rəngli mikrob olmur
## ([method World._free_color] bunu təmin edir), ona görə rəng mikrobun
## kimliyidir və partlama hadisəsinə ayrıca id sahəsi əlavə etmək lazım deyil —
## snapshot-da hər bayt sayılır.
func _explode(pos: Vector2, radius: float, color_index: int, mine: bool) -> void:
	var balls := -1
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if v.burst or v.color_index != color_index:
			continue
		# Son bilinən top sayı səpilən damcıların sayını təyin edir: dolu
		# mikrob partlayanda ekran daha çox dağılır.
		balls = v.balls
		v.kill()
		break

	var fx := BurstFx.new()
	fx.position = pos
	fx.setup(Palette.germ_color(color_index), radius, balls, mine, _tex["burst"])
	_fx.add_child(fx)
	_juice.shockwave(pos, radius * (1.45 if mine else 1.0),
		Palette.germ_color(color_index))


## Zərbə nöqtəsinin dayanan kövrək qabığa aid olub-olmadığını tapır.
##
## Üçüncü zərbədə `_apply_walls` qabığı hadisədən əvvəl artıq gizlədir; həmin
## halda kiçik qırıntı buraxılmır, çünki BREAK budağı tam dağılmanı çəkir.
func _brittle_at(at: Vector2, include_gone: bool) -> int:
	var list := DishMap.obstacles()
	var best := -1
	var best_d := INF
	for i in list.size():
		var o: Vector4 = list[i]
		if int(o.w) != DishMap.Kind.BRITTLE:
			continue
		if not include_gone and i < _broken.size() and DishMap.wall_gone(_broken[i]):
			continue
		var d := at.distance_to(Vector2(o.x, o.y))
		if d <= o.z + Const.SHOT_RADIUS + 12.0 and d < best_d:
			best_d = d
			best = i
	return best


## Effektlərin z-i — HƏR mikrobun üstündə.
##
## [GermVisual] özünə `1` (rəqib) və ya `2` (öz mikrobun) yazır, `_fx` qatı isə
## sıfırda idi: nəticədə qığılcım, atəş effekti və TRİXOSİST BULUDU məhz onların
## altında qalırdı — yəni superin təsir etdiyi mikroblar onun görüntüsünü
## örtürdü. [BurstFx] bunu əvvəldən düz edirdi (`z_index = 3`), `_spawn_fx`-də
## isə unudulmuşdu.
const FX_Z := 3


## Superin açılış anı — qığılcım, səs və [SuperFx].
##
## İki yerdən çağırılır: başqasının superi serverin hadisəsindən, interpolyasiya
## anında ([method _flush_fx]); ÖZ superin isə proqnozdan, basılan tick-də
## ([method _do_tick]) — atəş kimi. Əvvəl öz superin də serverin hadisəsini
## gözləyirdi: kirpiklinin trixosisti (onun superinin YEGANƏ görüntüsü) məşqdə
## 130 ms, onlayn bir gediş-gəliş üstəgəl bufer qədər gec çıxırdı, mikrob isə
## proqnozda dərhal geri sıçrayırdı — partlayış onun ARXASINDA, köhnə yerdə yanırdı.
##
## Səs üçün ayrıca fayl yoxdur, ona görə mövcud səslər rolu ilə seçilir:
## trixosist PARTLAYIŞDIR, tor və qabıq isə AÇILIŞDIR.
##
## [param reach] sıfırdan böyükdürsə, bu, trixosistdir və rəqəm onun təsir
## RADİUSUDUR (bax [method Sim._use_super]).
func _play_super(pos: Vector2, reach: float, ci: int) -> void:
	var col := Palette.germ_color(ci)
	# Açılış anı ayrıca effektdir (bax [SuperFx]). Əvvəl kirpiklidə
	# `burst.svg` buludu idi: 0.26 saniyə yaşayır, ilk kadrdan sönürdü
	# və kadr ardıcıllığında praktiki olaraq görünmürdü.
	#
	# Növ hadisədə GƏLMİR: trixosist öz radiusunu göndərir (arg > 0),
	# qalan ikisi isə mikrobun görüntüsündən tapılır.
	var who := _germ_by_color(ci)
	var kind := Const.Species.CILIATE
	var body := Const.BASE_RADIUS
	# Rəqibin trixosisti öz uçan toplarını elə İNDİ dağıdır — partlayış
	# ekranda görünən anda. Server də bu anı yoxlayır (bax [member Sim._blasts]):
	# partlayışdan əvvəl rəqibə çatan top dəyir, sonra çatan dağılır.
	if reach > 0.0 and ci != my_color:
		for gh in _own_shots.blast(pos, reach, _clock):
			_spawn_fx("spark", gh.pos, 0.45, Palette.germ_color(my_color))
	if who != null:
		body = Const.germ_radius(who.capacity)
		if reach <= 0.0:
			kind = who.species
	if reach <= 0.0:
		# Torun sərhədi [method GermVisual._draw_net] ilə eyni düsturdur;
		# kist isə gövdənin öz qabığıdır.
		if kind == Const.Species.HELIOZOAN:
			reach = body * Const.NET_RADIUS
		else:
			reach = body + GermVisual.SHIELD_GAP * 0.5
	var sfx := SuperFx.new()
	sfx.position = pos
	sfx.setup(kind, col, body, reach, Const.is_light(int(Net.quality)))
	if kind != Const.Species.CILIATE and who != null:
		sfx.follow(who)
	_fx.add_child(sfx)
	if kind == Const.Species.CILIATE:
		_spawn_fx("spark", pos, 0.9, Palette.TEXT)
		Sfx.play("burst", 0.0, -4.0)
	else:
		_spawn_fx("spark", pos, 0.9, col)
		Sfx.play("level_up", 0.0, -4.0)
	if ci == my_color:
		# Öz ultin partlatma ilə eyni sinifdə hadisədir. Yazı yalnız
		# SƏNİN superində çıxır: 10 mikrobun hamısınınkı yazılsaydı
		# ekran dolardı.
		_add_shake(6.0)
		_punch = maxf(_punch, 0.05)
		_pop_text(pos, "SUPER!", Palette.SUPER_READY, 34)


## Proqnozun oynatdığı öz superi serverin SUPER hadisəsini götürür — ikinci
## dəfə oynanmasın (atəşdəki [method ShotPrediction.take_unseen_fire] kimi).
## Proqnoz görməyibsə (məşqdə yerli dünya superi ondan ƏVVƏL emal edir, bax
## [method _reconcile]) `false` qaytarır və effekti serverin hadisəsi oynadır.
func _take_own_super() -> bool:
	while not _own_supers.is_empty() and _clock - _own_supers[0] > OWN_SUPER_GRACE:
		_own_supers.pop_front()
	if _own_supers.is_empty():
		return false
	_own_supers.pop_front()
	return true


func _spawn_fx(kind: String, pos: Vector2, scale: float, color: Color) -> void:
	var spr := Sprite2D.new()
	spr.texture = _tex[kind]
	spr.position = pos
	spr.scale = Vector2(scale, scale)
	spr.modulate = color
	spr.z_index = FX_Z
	_fx.add_child(spr)

	# Böyümə SÖNMƏDƏN TEZ bitir.
	#
	# İkisi eyni müddətdə olanda effekt tam ölçüsünə məhz görünməz olduğu an
	# çatırdı: trixosistin buludu ekranda ən böyüyü ~1/1.7 = 58% olurdu və
	# oyunçu superin təsir radiusunu HƏMİŞƏ yarı boyda öyrənirdi. Halbuki
	# [method Sim._use_super] radiusu qəsdən hadisə ilə göndərir ki, görüntü
	# həqiqi sahə ilə eyni olsun — ölçü oradan öyrənilir.
	var grow := FX_LIFETIME * FX_GROW_RATIO
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(spr, "modulate:a", 0.0, FX_LIFETIME)
	tw.tween_property(spr, "scale", Vector2(scale * FX_GROW, scale * FX_GROW), grow) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(spr.queue_free)


# ---------------------------------------------------------------- xəritənin canlılığı

## Xəritə toxunuşa CAVAB VERİR — Brawl Stars-da divar vurulanda titrəyir, kol
## top keçəndə xışıldayır, sınan divar sınıq qalır. Hamısı kodladır, kadr
## animasiyası yoxdur: atlasın sprite-ları miqyas və görünürlüklə oynanır, şüşə
## parıltısı dodaq node-unun öz multiline çağırışındadır.
##
## Heç biri keyfiyyət səviyyəsindən asılı deyil — hamısı ucuzdur (≤ 46 bəzək,
## ≤ 9 kol, bir neçə dalğa), və qrafika heç bir cihazda sadələşmir.

## Şüşə dodağın parıltısının ömrü.
const GLINT_TIME := 0.45
## Maneənin titrəməsi: 1 → 1.045 → 0.975 → 1. Qısa və kiçik — divar "canlıdır",
## amma toqquşma dairəsi tərpənmir (yalnız şəkil, sərhəd yox).
const WOBBLE_TIME := 0.17
const WOBBLE_UP := 0.045
const WOBBLE_DOWN := 0.025
## Su dalğası və sıçrantının ömrü.
const RIPPLE_TIME := 0.55
const SPLASH_TIME := 0.34
## Bəzəyin sıçrayışının ömrü.
const CLUTTER_POP := 0.32
## Yarpaq üstündəki topun z-i: yarpaqlardan (z 2) yuxarı. [constant FX_Z] ilə
## eynidir — ağacda `_shot_layer` `_fx`-dən əvvəldir, qığılcımlar yenə üstdədir.
const SHOT_OVER_Z := 3
## Dağılan kövrəyin atlas qırıntıları.
const CHUNK_TIME := 0.62


## Top dəyən yerdə hansı bərk maneə var? Sıçrayış nöqtəsi maneənin SƏTHİNDƏDİR,
## ona görə mərkəzə yox, çevrəyə olan məsafə yoxlanılır.
func _obstacle_at(at: Vector2) -> int:
	var list := DishMap.obstacles()
	var best := -1
	var best_d := INF
	for i in list.size():
		var o: Vector4 = list[i]
		if not DishMap.blocks_shot(int(o.w)):
			continue
		if i < _broken.size() and DishMap.wall_gone(_broken[i]):
			continue
		var d := absf(at.distance_to(Vector2(o.x, o.y)) - o.z)
		if d <= Const.SHOT_RADIUS + 12.0 and d < best_d:
			best_d = d
			best = i
	return best


## Topun maneəyə və ya şüşəyə dəyməsinin xəritə cavabı: maneə titrəyir, şüşə
## parıldayır, suda kiçik dalğa qalır. Proqnozun təması da, serverin HIT
## hadisəsi də buraya gəlir — öz topunun hadisəsini iddia sistemi süzür
## ([method _match_claim]), ona görə heç nə iki dəfə oynanmır.
func _map_hit(at: Vector2) -> void:
	var i := _obstacle_at(at)
	if i >= 0:
		_wobble(i)
	elif at.length() > Const.WORLD_RADIUS - Const.SHOT_RADIUS - 6.0:
		_glint(at.angle())
	_ripple(at, 24.0, Color(Palette.TEXT, 0.34))


## Maneənin gövdəsi qısa titrəyir. Kölgə döşəmədədir — titrəmir.
func _wobble(i: int) -> void:
	if i < 0 or i >= _blob_nodes.size():
		return
	var spr := _blob_nodes[i]
	if spr == null or not spr.visible:
		return
	if spr.has_meta("wobble"):
		var old: Tween = spr.get_meta("wobble")
		if old != null and old.is_valid():
			old.kill()
	var tw := create_tween()
	tw.tween_method(func(u: float) -> void:
		var base: Vector2 = spr.get_meta("base_scale", spr.scale)
		# Sönən sinus: əvvəl şişir, sonra bir az yığılır, sonra yerinə qayıdır.
		var k := sin(u * TAU) * (WOBBLE_UP if u < 0.5 else WOBBLE_DOWN) * (1.0 - u * 0.35)
		spr.scale = base * (1.0 + k), 0.0, 1.0, WOBBLE_TIME)
	tw.tween_callback(func() -> void: spr.scale = spr.get_meta("base_scale", spr.scale))
	spr.set_meta("wobble", tw)


## Şüşə dodağında [param angle] bucağında parıltı.
func _glint(angle: float) -> void:
	_glints.append({"angle": angle, "t": _clock})
	_lip.queue_redraw()


## Suyun səthində genişlənən halqa (atlasın `ripple` hüceyrəsi) — sprite
## hovuzdan gəlir, hamısı eyni teksturadır, yəni dalğa nə qədər olsa da bir
## çəkiliş çağırışıdır. [param reach] — halqanın son radiusu.
func _ripple(at: Vector2, reach: float, color: Color, cell := "ripple",
		life := RIPPLE_TIME) -> void:
	if not _in_view(at, reach):
		return
	var spr: Sprite2D
	if _ripple_pool.is_empty():
		spr = MapKit.sprite(cell, reach)
		_ripples.add_child(spr)
	else:
		spr = _ripple_pool.pop_back()
		spr.visible = true
		MapKit.apply(spr, cell, reach)
	spr.position = at
	spr.modulate = color
	spr.rotation = fposmod(at.x * 0.37 + at.y * 0.61, TAU)
	_ripple_live.append({"node": spr, "t": _clock, "life": life,
		"scale": spr.scale, "alpha": color.a})


## Dalğaların və sıçrantıların ömrü — böyüyür, sönür, hovuza qayıdır.
func _step_ripples() -> void:
	for k in range(_ripple_live.size() - 1, -1, -1):
		var e: Dictionary = _ripple_live[k]
		var spr: Sprite2D = e["node"]
		var u := (_clock - float(e["t"])) / float(e["life"])
		if u >= 1.0:
			spr.visible = false
			_ripple_pool.append(spr)
			_ripple_live.remove_at(k)
			continue
		var grow := 1.0 - pow(1.0 - u, 3.0)
		spr.scale = Vector2(e["scale"]) * (0.35 + 0.65 * grow)
		spr.modulate.a = float(e["alpha"]) * (1.0 - u) * (1.0 - u)


## Bu nöqtə kameranın görüş sahəsindədirmi (bir az ehtiyatla)?
func _in_view(at: Vector2, margin: float) -> bool:
	return _view_rect.grow(margin + 60.0).has_point(at)


## Kövrək dağıldı: atlasın dörd qırıntı parçası mərkəzdən səpilir, fırlanır və
## söner (JuiceFx-in xətt qırıntılarına əlavə — onlar toz, bunlar qabığın öz
## materialıdır). Üstəlik böyük dalğa və sıçrantı.
func _break_chunks(i: int) -> void:
	if i < 0 or i >= DishMap.obstacles().size():
		return
	var o: Vector4 = DishMap.obstacles()[i]
	var at := Vector2(o.x, o.y)
	_ripple(at, o.z * 1.5, Color(Palette.TEXT, 0.40))
	_ripple(at, o.z * 1.05, Color(Palette.TEXT, 0.55), "splash", SPLASH_TIME)
	if not _in_view(at, o.z * 2.0):
		return
	for k in 7:
		var spr := MapKit.sprite("debris_%d" % (k % 4), o.z * (0.13 + 0.05 * float(k % 3)))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		spr.position = at
		spr.z_index = FX_Z
		_fx.add_child(spr)
		var dir := Vector2.from_angle(TAU * float(k) / 7.0 + sin(float(k) * 7.1 + o.x) * 0.3)
		var dist := o.z * (0.75 + 0.45 * fposmod(float(k) * 0.618 + o.y * 0.01, 1.0))
		var spin := (1.0 if k % 2 == 0 else -1.0) * (2.0 + float(k % 3))
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(spr, "position", at + dir * dist, CHUNK_TIME) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tw.tween_property(spr, "rotation", spin, CHUNK_TIME)
		tw.tween_property(spr, "modulate:a", 0.0, CHUNK_TIME * 0.45).set_delay(CHUNK_TIME * 0.55)
		tw.chain().tween_callback(spr.queue_free)


## Top üstündən keçən döşəmə bəzəyi sıçrayır və kiçik dalğa qoyur. Yalnız topun
## öz xanasındakı parçalar yoxlanılır (bax [member _clutter_grid]).
func _pop_clutter(at: Vector2, cell_key: Vector2i) -> void:
	if not _clutter_grid.has(cell_key):
		return
	for k in _clutter_grid[cell_key]:
		var c: Dictionary = _clutter[k]
		if _clock - float(c["pop"]) < CLUTTER_POP * 2.0:
			continue
		var p: Vector2 = c["at"]
		var reach := float(c["r"]) + Const.SHOT_RADIUS
		if p.distance_squared_to(at) > reach * reach:
			continue
		c["pop"] = _clock
		_clutter_popping.append(k)
		_ripple(p, float(c["r"]) * 1.6, Color(Palette.TEXT, 0.22))


## Bəzəyin sıçrayışı: kiçik "hop" — böyüyür, sonra yerinə qayıdır. Yalnız
## sıçrayan parçalar gəzilir.
func _step_clutter() -> void:
	for n in range(_clutter_popping.size() - 1, -1, -1):
		var c: Dictionary = _clutter[_clutter_popping[n]]
		var spr: Sprite2D = c["node"]
		var u := (_clock - float(c["pop"])) / CLUTTER_POP
		if u >= 1.0:
			spr.scale = c["base"]
			_clutter_popping.remove_at(n)
			continue
		var hop := sin(u * PI) * (1.0 - u * 0.4)
		spr.scale = Vector2(c["base"]) * (1.0 + 0.32 * hop)


## Topları yarpaq qatına görə yerləşdirir və koldan keçən topa xışıltı verir.
##
## Top adətən mikrobların ALTINDADIR (ART_BIBLE §3c): mikrobun içindən doğulur
## və membrandan keçəndə üzə çıxır, rəqibə dəyəndə onun içinə girir. Yarpaqlar
## isə mikrobların ÜSTÜNDƏDİR. Kola girən top yarpaq altında itərdi — qaçmaq
## mümkün olmazdı (critique B2; Brawl Stars-da top kolların üstündədir). Ona
## görə top yalnız KOLUN İÇİNDƏ və heç bir mikrobun gövdəsində olmayanda
## yarpaqların üstünə çıxır: kolun xaricində heç nə dəyişmir, gövdədən çıxış
## və gövdəyə giriş isə yenə membranın altında görünür.
func _layer_shots() -> void:
	for sid in _shot_views:
		var view: Dictionary = _shot_views[sid]
		var spr: Sprite2D = view["node"]
		if spr == null or not spr.visible or bool(view.get("absorbed", false)):
			continue
		_layer_shot(sid, spr)
	for gid in _ghost_nodes:
		_layer_shot(-int(gid), _ghost_nodes[gid])
	# Kolun içində ölən topun qeydi saniyədə bir dəfə silinir: hər kadr "görülən
	# toplar" lüğəti qurmaq əlavə iş idi, qeyd isə yalnız kolun İÇİNDƏKİ toplar
	# üçün var, yəni azdır.
	if _clock - _shot_bushes_swept > 1.0:
		_shot_bushes_swept = _clock
		for key in _shot_bushes.keys():
			if _clock - float((_shot_bushes[key] as Vector2).y) > 0.5:
				_shot_bushes.erase(key)


func _layer_shot(key: int, spr: Sprite2D) -> void:
	var at := spr.position
	var cell := _map_cell(at)
	_pop_clutter(at, cell)
	var bush := -1
	if _bush_grid.has(cell):
		for n in _bush_grid[cell]:
			var b := _bush_list[n]
			var dx := at.x - b.x
			var dy := at.y - b.y
			var rr := b.z + Const.SHOT_RADIUS
			if dx * dx + dy * dy <= rr * rr:
				bush = int(b.w)
				break
	var before := int((_shot_bushes.get(key, Vector2(-1.0, 0.0)) as Vector2).x)
	if bush != before:
		# Koldan keçən top yarpağı silkələyir — həm girəndə, həm çıxanda.
		# Yalnız GÖRÜNƏN top: server gizli mikrobun topunu da göndərir, amma
		# topun özü onsuz da görünür, yəni xışıltı heç nəyi ifşa etmir.
		if bush >= 0:
			_bush_rustles[bush] = _clock
		elif before >= 0:
			_bush_rustles[before] = _clock
	if bush >= 0:
		_shot_bushes[key] = Vector2(float(bush), _clock)
	elif before >= 0:
		_shot_bushes.erase(key)
	var over := bush >= 0 and not _inside_germ(at)
	var z := SHOT_OVER_Z if over else 0
	if spr.z_index != z:
		spr.z_index = z
	# Heç vaxt kola girməyən top (əksəriyyət) iz lüğətinə toxunmur.
	if bush >= 0 or before >= 0:
		_trails.set_over(key, over)


## Nöqtə hər hansı görünən mikrobun gövdəsinin içindədirmi (top radiusu ilə)?
func _inside_germ(at: Vector2) -> bool:
	for gid in _visuals:
		var v: GermVisual = _visuals[gid]["node"]
		if not v.visible or v.burst:
			continue
		var r := Const.germ_radius(v.capacity) + Const.SHOT_RADIUS
		if v.position.distance_squared_to(at) <= r * r:
			return true
	return false


# ---------------------------------------------------------------- fon

## Qabın BAYIRI — halqa mesh-i (bax [method _build_backdrop]).
##
## Əvvəl burada iki tam ekran disk çəkilirdi və qabın içində ikisini də döşəmə
## örtürdü: hər kadr iki görünməz ekran doldurması (MAP_25D F3). Halqa yalnız
## qabın xaricini doldurur. Döşəmə, şəbəkə, quruyan zona və şüşə divar öz
## node-larındadır (bax [method _build_world]).
func _draw() -> void:
	if _backdrop != null:
		draw_mesh(_backdrop, null)


## Qabın bayırının halqası (bax [method MapKit.backdrop_mesh]).
func _build_backdrop() -> void:
	_backdrop = MapKit.backdrop_mesh()


## DÖŞƏMƏ — makro tekstura, şeyder detalı üstünə vurur (bax `map_floor.gdshader`).
##
## Qab əyri şüşədir: mərkəz bir az açıq, kənar qaranlığa düşür, zonalar və
## sediment zolaqları teksturaya bişib. Əvvəl 14 `draw_circle` idi (14 çağırış),
## sonra bir SVG, indi bir şeyderli düzbucaqlıdır. Diskin künclərindəki şəffaf
## sahədən qabın bayırı görünür.
func _draw_ground() -> void:
	var r := Const.WORLD_RADIUS
	_ground.draw_texture_rect(_floor_tex, Rect2(-r, -r, r * 2.0, r * 2.0), false)


## ŞƏBƏKƏ — məsafə hissi verir, amma kənara doğru SÖNÜR.
##
## Bərabər parlaq şəbəkə koordinat kağızı kimi oxunur və səthi yastılaşdırır.
## Kənara doğru sönəndə isə əksinə: səth əyilmiş görünür.
##
## `draw_multiline_colors` hər seqmentə ayrıca rəng verir və yenə TƏK
## çağırışdır (eyni üsul mikrobun ayaqlarında işlənir). Statikdir — node bir
## dəfə çəkilir.
func _draw_grid() -> void:
	var r := Const.WORLD_RADIUS
	var step := 200.0
	var lines := PackedVector2Array()
	var cols := PackedColorArray()
	var n := int(r / step)
	for i in range(-n, n + 1):
		var x := float(i) * step
		var h := sqrt(maxf(r * r - x * x, 0.0))
		var fade := 1.0 - pow(absf(x) / r, 1.6)
		var gc := Color(Palette.GRID, 0.38 * fade)
		lines.push_back(Vector2(x, -h)); lines.push_back(Vector2(x, h))
		cols.push_back(gc)
		lines.push_back(Vector2(-h, x)); lines.push_back(Vector2(h, x))
		cols.push_back(gc)
		# Hər 400 px-də xəttin yuxarı-solunda işıq, aşağı-sağında kölgə var.
		# Cüt xətt ayrıca `draw_*` deyil, eyni massivə əlavə olunur — kafel bevel-i
		# görünür, çağırış sayı isə yenə BİRDİR. Hər 200 px-də bevel sınansaydı
		# döşəmə tor kimi xırdalanardı, ona görə yalnız cüt indekslər vurğulanır.
		if i % 2 == 0:
			var hi := Color(Palette.DISH_EDGE, 0.20 * fade)
			var lo := Color(Palette.OUTLINE, 0.24 * fade)
			lines.push_back(Vector2(x - 2.5, -h)); lines.push_back(Vector2(x - 2.5, h))
			cols.push_back(hi)
			lines.push_back(Vector2(x + 2.5, -h)); lines.push_back(Vector2(x + 2.5, h))
			cols.push_back(lo)
			lines.push_back(Vector2(-h, x - 2.5)); lines.push_back(Vector2(h, x - 2.5))
			cols.push_back(hi)
			lines.push_back(Vector2(-h, x + 2.5)); lines.push_back(Vector2(h, x + 2.5))
			cols.push_back(lo)
	_grid.draw_multiline_colors(lines, cols, 2.0)


## QURUMA KƏNARI — yalnız matçlı rejimdə və yalnız qab daralanda.
##
## Quru zona DİVAR DEYİL: mikrob ora keçir, sadəcə orada dolur və partlayır
## (bax [method Sim._step_germs]). Ona görə kənar bərk xətt kimi yox, NƏBZ
## VURAN halqa kimi çəkilir — "təhlükə", "maneə" yox.
##
## Quru döşəmə ayrıca tekstura deyil: qabın üstünə kəhrəba örtük və bütün
## çatlar TƏK `draw_multiline_colors` çağırışı ilə düşür. Çatların nöqtələri
## indeksdən hesablanır, ona görə nəbz yenidən çəkiləndə naxış qaynamır.
##
## Ayrı node-dadır və snapshot ritmində yalnız O yenidən çəkilir (bax
## [method _apply_match]); əvvəl bütün fon — şəbəkə və divar da — yenilənirdi.
func _draw_dry() -> void:
	var r := Const.WORLD_RADIUS
	if _mode == Const.Mode.ENDLESS or _wet_radius >= r - 1.0:
		return
	var dry := Color(Palette.WARNING, 0.055)
	_dry.draw_arc(Vector2.ZERO, (_wet_radius + r) * 0.5, 0.0, TAU, 96, dry,
		r - _wet_radius, true)

	var crack_lines := PackedVector2Array()
	var crack_cols := PackedColorArray()
	var dry_span := r - _wet_radius
	var crack_count := 18 if Net.quality == Const.Quality.HIGH else 10
	for i in crack_count:
		var seed := float(i)
		var a := fposmod(seed * 2.39996 + sin(seed * 4.17) * 0.18, TAU)
		var radial := Vector2.from_angle(a)
		var tangent := radial.orthogonal()
		var inner_r := _wet_radius + dry_span * (0.12 + fposmod(seed * 0.37, 0.20))
		var outer_r := minf(r - 12.0, inner_r + dry_span * (0.30 + fposmod(seed * 0.19, 0.32)))
		var p0 := radial * inner_r
		var p1 := radial * lerpf(inner_r, outer_r, 0.48) \
			+ tangent * sin(seed * 8.3) * minf(22.0, dry_span * 0.10)
		var p2 := radial * outer_r \
			- tangent * cos(seed * 5.1) * minf(16.0, dry_span * 0.08)
		crack_lines.append_array(PackedVector2Array([p0, p1, p1, p2]))
		var cc := Color(Palette.DRY_CRACK, 0.25 + 0.12 * fposmod(seed * 0.43, 1.0))
		crack_cols.append_array(PackedColorArray([cc, cc]))
		# Hər üçüncü əsas çata qısa yan budaq verilir; eyni çağırışda qalır.
		if i % 3 == 0:
			var branch := p1 + (tangent + radial * 0.35).normalized() \
				* minf(34.0, dry_span * 0.16)
			crack_lines.append_array(PackedVector2Array([p1, branch]))
			crack_cols.append(Color(Palette.DRY_CRACK, 0.22))
	if not crack_lines.is_empty():
		_dry.draw_multiline_colors(crack_lines, crack_cols, 3.0)

	# Yaş sahə daraldıqca döyüşün təciliyi artır: 2.2-dən 7.0 rad/san-a.
	# Sabit 2.2 sınanmışdı və son 90 px-lik dairədə də başlanğıc qədər sakit
	# görünürdü; sürət radiusdan çıxanda qayda ilə görüntü eyni anda sıxılır.
	var danger := clampf(1.0 - _wet_radius / r, 0.0, 1.0)
	var pulse_speed := 2.2 + danger * 4.8
	var pulse := 0.5 + 0.5 * sin(_clock * pulse_speed)
	_dry.draw_arc(Vector2.ZERO, _wet_radius, 0.0, TAU, 96,
		Color(Palette.WARNING, 0.34 + 0.28 * pulse), 10.0, true)

	# Buxar yalnız YÜKSƏK keyfiyyətdədir. Səkkiz kəkil ayrıca primitiv deyil:
	# bütün qısa seqmentlər bir multiline çağırışında yığılır. LOW-da bu
	# massiv heç qurulmur, çünki buxar qayda yox, material işarəsidir.
	if Net.quality == Const.Quality.HIGH:
		var steam_lines := PackedVector2Array()
		var steam_cols := PackedColorArray()
		for i in 8:
			var drift := _clock * 0.16 + float(i) * TAU / 8.0
			var radial := Vector2.from_angle(drift)
			var tangent := radial.orthogonal()
			var lift := 18.0 + 9.0 * sin(_clock * 0.9 + float(i) * 1.7)
			var p0 := radial * (_wet_radius + 8.0)
			var p1 := p0 + radial * lift * 0.38 + tangent * 7.0
			var p2 := p0 + radial * lift * 0.72 - tangent * 6.0
			var p3 := p0 + radial * lift + tangent * 3.0
			steam_lines.append_array(PackedVector2Array([p0, p1, p1, p2, p2, p3]))
			steam_cols.append_array(PackedColorArray([
				Color(Palette.STEAM, 0.22), Color(Palette.STEAM, 0.15),
				Color(Palette.STEAM, 0.06)]))
		_dry.draw_multiline_colors(steam_lines, steam_cols, 4.0)


## ŞÜŞƏ DİVAR — iki hissə (godot_25d_technique §4, Brawl Stars-ın kənar divarı):
##
##   ŞİMAL DİVARI — şüşənin daxili üzü, dodaqdan BAYIRA uzanır. Kamera
##   cənubdadır və uzaq divarın içini görür: eni şimalda 70 px, yanlarda 8 px
##   (divar yandan görünür, bax [method MapKit.wall_width]). Tekstura divarın
##   zolağıdır (`map_rim.png`): ayağı dodaqda, kondensasiya halqalı üzü və
##   işıqlı üst xətti bayırda. Oyun sahəsindən bir piksel də yemir.
##   CƏNUB DODAĞI — yaxın divarın üstü, İÇƏRİYƏ 6..28 px: yarımşəffaf şüşə və
##   nazik işıq xətti. Mikrobların ÜSTÜNDƏ çəkilir (bax [member _lip]).
##
## İkisi də statik mesh-dir, hər biri bir çəkiliş çağırışı (bax
## [method MapKit.rim_mesh], [method MapKit.lip_mesh]). Əvvəlki dörd `draw_arc`
## (hər biri ayrıca poliqon) bunlarla əvəz olunub.
func _build_rim() -> void:
	_rim_mesh = MapKit.rim_mesh()
	_lip_mesh = MapKit.lip_mesh()


func _draw_rim() -> void:
	if _rim_mesh != null:
		_rim.draw_mesh(_rim_mesh, _rim_tex)


## Dodaq və onun parıltıları. Parıltı top şüşədən sıçrayanda yanır (bax
## [method _glint]): dodaq da maneələr kimi toxunuşa cavab verir.
func _draw_lip() -> void:
	if _lip_mesh != null:
		_lip.draw_mesh(_lip_mesh, null)
	if _glints.is_empty():
		return
	var r := Const.WORLD_RADIUS - 2.0
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	# HDR-dir (bax [constant Palette.HIT_FLASH]): YÜKSƏK-in parlaması onu bir anlıq
	# işıq kimi tutur. Adi açıq rəng 3 px-lik xətdə demək olar görünmürdü.
	var hot := Palette.RIM_LINE.lerp(Palette.BODY_LIGHT, 0.6) * 1.6
	for g in _glints:
		var u := clampf((_clock - float(g["t"])) / GLINT_TIME, 0.0, 1.0)
		var fade := (1.0 - u) * (1.0 - u)
		var a := float(g["angle"])
		# İşıq dodaq boyunca iki tərəfə yayılır və sönür.
		var span := 0.06 + 0.12 * (1.0 - pow(1.0 - u, 2.0))
		var seg := 14
		for k in seg:
			var a0 := a - span + 2.0 * span * float(k) / float(seg)
			var a1 := a0 + 2.0 * span / float(seg)
			var w := 1.0 - absf((float(k) + 0.5) / float(seg) * 2.0 - 1.0)
			pts.push_back(Vector2.from_angle(a0) * r)
			pts.push_back(Vector2.from_angle(a1) * r)
			cols.push_back(Color(hot.r, hot.g, hot.b, fade * minf(w * 1.6, 1.0)))
	_lip.draw_multiline_colors(pts, cols, 4.0)
