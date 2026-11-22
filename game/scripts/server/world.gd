class_name World
extends RefCounted
## Bir petri qabı — sonsuz işləyən dünya.
##
## Serverdə yaşayır, öz [Sim] nüsxəsini 30 Hz ilə addımlayır və hər tick-də
## iştirakçılara snapshot göndərir. Matç yoxdur: oyunçular istənilən anda
## girir, mikrobları partlayanda çıxırlar.
##
## Bir server prosesi onlarla belə dünyanı paralel aparır — hər dünya
## tamamilə müstəqildir, node ağacına toxunmur.
##
## Bot idarəsi də buradadır: dünya heç vaxt boş qalmır, çatmayan yer
## [Bot] mikroblarla doldurulur.

## Bot id-ləri peer id-lərindən uzaqda saxlanılır ki, heç vaxt toqquşmasınlar.
const BOT_ID_BASE := 1_000_000
## Bot partlayandan sonra yerinə yenisi bu qədər saniyəyə gəlir.
const BOT_RESPAWN := 2.0
## Proqnozun açdığı atəş serverdə soyumanı ən çox bu qədər tick gözləyir (bax
## [method tick]). Girişlərin birləşməsi soyumanı bir tick sürüşdürür; iki tick
## ehtiyatdır.
const FIRE_WAIT := 2

var id: int
var sim: Sim
var peers: Array[int] = []      ## Bu dünyadakı insan oyunçular

## peer_id -> sessiya nişanı. Bağlantı kəsiləndə oyunçu bu nişanla geri qayıdır:
## yeni peer id alır, amma nişan onu köhnə mikrobu ilə birləşdirir.
var tokens := {}
## Bağlantısı kəsilmiş, amma mikrobu hələ dünyada qalan oyunçular. peer_id -> true
var suspended := {}

var _inputs := {}               ## germ_id -> Sim.PlayerInput (ən son gələn)

## ── Gec gələn girişlər ──────────────────────────────────────────────────
##
## Yeni giriş gəlməyən tick-də server oyunçunun SONUNCU girişini təkrarlayır — bu,
## TƏXMİNDİR. Wi-Fi donanda (TCP girişləri saxlayıb sonra bir anda gətirir) təxmin
## saniyələrlə davam edirdi, dəstə gələndə isə [method accept_input] yalnız ən sonuncunu
## saxlayırdı: oyunçunun donma ərzindəki hərəkəti itirdi və öz ekranında mikrob 100–400 px
## geri dartılırdı (ölçülüb). Jitter-də də (paketlər cüt-cüt gəlir) hər birləşmədə proqnoz
## bir tick titrəyirdi.
##
## İndi təxmin olunan tick-lər ("slot"-lar) gec gələn girişlər gələn kimi mikrobun ÖZ
## hərəkəti üçün yenidən hesablanır ([method _replay_late], client proqnozunun eyni kodu —
## [method Sim.step_movement]). Atəş və super yenə ən son girişə birləşir və indiki tick-də
## işləyir — keçmişə yazılmır.
##
## Hədlər:
##   • ən çox [constant REPLAY_MAX] tick (4 s) geri. Real Wi-Fi donmaları 3.8–4.2 s idi
##     (Render logu, 2026-10-03); 1.5 s-lik hədd 4 s-lik donmada mikrobu yenə 500 px geri
##     dartırdı (ölçülüb). "Lag switch" (yuxarı istiqaməti qəsdən saxlamaq) bununla
##     topdan YAYINMAĞA imkan vermir: donma boyu dəymələr serverin TƏXMİN etdiyi yerdə —
##     rəqiblərin gördüyü yerdə — sayılıb və geri alınmır; yalnız sonda sıçrayış görünür;
##   • təxmin yolu TƏMİZ hərəkət deyilsə (rəqiblə toqquşma, trixosist itələməsi, tor, atəşin
##     geri təpməsi) yenidən oynadılmır — bu təsirləri silmək olmaz; onda təxmin qalır və
##     client barışıqla (hamar) düzəlir;
##   • girişlər bağlı olanda (geri sayım, matçın sonu) nə təxmin sayılır, nə yenidən
##     oynadılır; ÜÇLÜK-də raund sıfırlananda hamısı unudulur — yoxsa yenidən oynatma
##     mikrobu yeni doğuş yerindən köhnə raundun yerinə qaytarırdı (yoxlamada tapılıb);
##   • kistdə heç nə dəyişmir.
const REPLAY_MAX := 120
## DAİMİ BORC. Client tick-ləri həmişəlik itirə bilər (vərəq arxa plana keçib, kadr 0.5 s-dən
## uzun çəkib, ENet-də paket itib): o slot-ların girişi heç vaxt gəlməyəcək, seq isə ardıcıl
## qalır. Silinməsə server hər tick o slot-ları "gec giriş" sayıb yenidən oynadır.
##
## Ödənməyən borc belə tapılır: [constant DEBT_WINDOW] tick-lik pəncərədə girişlər AXIRSA
## (ən çox [constant DEBT_SLACK] əskik), pəncərədəki ən kiçik təxmin sayı daimidir və silinir.
## Əvvəlki qayda — 30 tick FASİLƏSİZ giriş — adi jitter-də heç ödənmirdi: bir boş tick
## sayğacı sıfırlayırdı, borc sessiya boyu qalırdı və server hər tick k slot-u ən təzə
## girişlə yenidən hesablayırdı — yoldaşlar 155–1022 px sıçrayış görürdü, client isə
## 120-dən böyük borcda proqnozunu tamam itirirdi (yoxlamada ölçülüb).
const DEBT_WINDOW := 30
const DEBT_SLACK := 2
## `--no-replay` ilə server köhnə qaydaya qayıdır (yalnız təxmin sayı göndərilir).
var replay_enabled := true
var _late_q := {}               ## peer -> Array[Sim.PlayerInput] — son tick-dən bəri gələnlər
var _rep := {}                  ## peer -> təxmin olunan ardıcıl slot sayı (snapshot SELF[2])
var _win := {}                  ## peer -> [tick sayı, giriş sayı, ən kiçik təxmin] — borc pəncərəsi
var _seq_seen := {}             ## peer -> əvvəlki tick-in sonunda emal olunmuş seq
var _ring := {}                 ## peer -> Array[[pos, vel, aim]] — hər tick-dən SONRAKI hal
var _applied := {}              ## peer -> son tick-də işlənən giriş (hərəkət və nişan)
var _scratch: Sim = null
var _last_seq := {}             ## peer_id -> emal edilmiş son seq
var _bots := {}                 ## bot_id -> Bot
var _next_bot_id := BOT_ID_BASE
var _bot_timer := 0.0
var _seeded := false
var _bot_name_no := 0

## Bu tick üçün hazırlanmış sətirlər — hər peer üçün yenidən qurulmasın deyə
## bir dəfə yığılır, sonra görüş sahəsinə görə süzülür.
## Bu dünyanın rejimi. Dünya boyu dəyişmir — bir dünyada hamı eyni qaydada
## oynayır (bax `design/MODES.md`).
var mode := Const.Mode.ENDLESS
## Qaydalar profili ([enum Const.Profile]). Mutasiyalar yalnız SONSUZ ARENA-da və yalnız
## proses eksperimental profillə işə salınanda işləyir ([method default_rules]). Client
## profili join info-dan bilir — öz bayrağı ilə qaydanı dəyişmir.
var profile: int = Const.Profile.STANDARD
## Yeni dünyaların profili; -1 — hələ komanda sətrindən oxunmayıb. Testlər birbaşa yazır.
static var default_profile := -1


## Prosesin qaydalar profili ([enum Const.Profile] bitləri), komanda sətrindən bir dəfə oxunur
## ([method rules_from_args]).
static func default_rules() -> int:
	if default_profile < 0:
		default_profile = rules_from_args(OS.get_cmdline_user_args())
	return default_profile


## Komanda sətrindən profil. MEMBRAN 2026-10-28-dən SONSUZ ARENA-nın STANDART qaydasıdır (rəy
## mərhələsi, design/MODES.md §20) — söndürmək: `--no-membrane`. Mutasiyalar eksperimental
## qalır: `--mutations` və ya `--profile mutations` (vergüllə, `--profile mutations,membrane`).
static func rules_from_args(args: PackedStringArray) -> int:
	var i := args.find("--profile")
	var named := (args[i + 1] if i >= 0 and i + 1 < args.size() else "").split(",")
	var p: int = Const.Profile.MEMBRANE
	if args.has("--mutations") or named.has("mutations"):
		p |= Const.Profile.MUTATIONS
	if args.has("--no-membrane"):
		p &= ~Const.Profile.MEMBRANE
	return p
## Matçın fazası. SONSUZ ARENA həmişə PLAYING-dədir və oradan çıxmır.
var phase := Const.Phase.PLAYING
## Hazırkı fazanın öz saatı (saniyə). Faza dəyişəndə sıfırlanır.
var phase_t := 0.0
## Matçın başlanğıcından keçən vaxt — qabın qurumasını bu idarə edir.
var match_t := 0.0
## Partlayan oyunçuların yeri: peer -> yer (1 = qalib).
var places := {}

## Matç bitəndə sağ qalan İNSANLARIN nəticələri. [Lobby] bir dəfə boşaldır.
##
## Ölənlərin nəticəsi `tick`-in qaytardığı siyahı ilə gedir, sağ qalanlarınkı
## isə heç bir hadisəyə bağlı deyil — matçın bitməsi onların tərəfindən
## baxanda heç nə "baş vermir". Ona görə ayrıca növbə lazımdır.
var pending_results: Array = []

## Matç VAXT LİMİTİ ilə bitdi (yəni sonuncu mikrob qalmadı).
##
## Nəticə ekranı üçün lazımdır: vaxt limitində bir neçə mikrob sağ qalır, yəni
## qalibə "sonuncu mikrob sənsən" yazmaq YALAN olardı.
var timed_out := false

## Mikrobun komandası — mikrob ÖLƏNDƏN SONRA da qalır.
##
## Nəticə ekranı ölmüş oyunçuya da göndərilir və orada "hansı komanda idin"
## sualı hələ də mənalıdır. [member Sim.germs] isə ölənləri saxlamır.
var teams := {}

## ÜÇLÜK: hər komandanın udduğu raund sayı.
var round_wins := PackedInt32Array()
## ÜÇLÜK: neçənci raunddur (1-dən başlayır).
var round_no := 1

## CÜT: dirilməni gözləyən mikroblar — `id -> qalan saniyə`.
##
## Ölən mikrob dünyadan çıxır, amma yeri komandaya SAXLANILIR. Yoldaşı da
## ölsə, növbə təmizlənir və cüt matçdan çıxır.
var _revive := {}
## Dirilməsi LƏĞV olunan insanların ölüm qeydləri — [method tick] onları
## partlayanların siyahısına qatır ki, [Lobby] nəticəni göndərsin.
var _revive_lost: Array = []

## ÜÇLÜK: raundda ölən İNSANLAR — `id -> {team, name, color, species, eye}`.
##
## Əvvəl ölən oyunçu dərhal nəticə alıb menyuya qayıdırdı, komandası isə qalan iki
## raundu onsuz (yerinə gələn botla) oynayırdı: "üç raundun ikisi" formatı insan üçün
## faktiki bir raund idi. İndi ölüm yalnız RAUNDU bitirir: oyunçu dünyada qalır,
## yoldaşını izləyir (bax [method spectate_target]) və növbəti raundda hamı ilə birlikdə
## doğulur ([method _reset_round]). Nəticəni matçın sonunda komanda kimi alır.
var _round_wait := {}
## ÜÇLÜK: bitmiş raundların cəmi vaxtı — nəticədəki "Matç" müddəti üçün
## ([member match_t] hər raundda sıfırlanır).
var _rounds_t := 0.0

## OBYEKT rejimləri (design/MODES.md §16): ölən mikrob öz bazasında yenidən doğulur —
## `id -> {left, team, bot, name, color, species, charge, eye}`. Ölüm matçdan çıxarmır,
## ona görə nəticə ekranı da yalnız matçın sonunda gəlir.
var _respawn := {}
## Ölən canların partlatmaları — nəticədə matç boyu cəmi göstərilir.
var _obj_pops := {}
## YAŞ ADA-nın xalları və NÜVƏ TOPU-nun qolları (indeks = komanda).
var obj_score := PackedInt32Array([0, 0])
## Qalib komanda: -1 hələ yoxdur, -2 heç-heçə.
var obj_winner := -1
## ANA HÜCEYRƏ: əlavə vaxt gedir.
var mother_ot := false
var _ot_fill := 0.0
var _island_acc := 0.0

var _frame_germs: Array = []    ## [Vector2 pos, Array row]
var _frame_shots: Array = []
## Qida sətir massivi yox, iki sıx massivdir — bax [method _build_frame].
var _frame_food_pos := PackedVector2Array()
var _frame_food_id := PackedInt64Array()
var _frame_events: Array = []
var _frame_board := PackedInt32Array()
## Koloniyaların vəziyyəti — tick-də bir dəfə, bütün baxanlar üçün eyni ([method Sim.colony_bytes]).
var _frame_colony := PackedByteArray()


func _init(p_id: int, p_mode := Const.Mode.ENDLESS) -> void:
	replay_enabled = not OS.get_cmdline_user_args().has("--no-replay")
	id = p_id
	mode = p_mode
	sim = Sim.new()
	# Atıcının gördüyü keçmişə qarşı yoxlama — həm onlayn serverdə, həm
	# məşqdə (orada da rəqiblər 100 ms geridə çəkilir, öz topun isə indidə).
	sim.lag_comp = true
	# Rejimin öz qabı, xəritəsi və obyekti — doğuşdan ƏVVƏL (bax [method Sim.set_mode]).
	sim.set_mode(int(mode))
	# SONSUZ ARENA-nın qida koloniyaları: yerləri düzümdən və dünyanın toxumundan çıxır
	# (bax [method DishMap.colony_spots]). Toxum hər dünyada başqadır — yerlər də.
	if mode == Const.Mode.ENDLESS:
		sim.setup_colonies(randi())
		profile = default_rules()
		sim.membrane_on = Const.rule_on(profile, Const.Profile.MEMBRANE)
	# Qabın kənarı elə İNDİ qurulur, ilk tick-i gözləmədən.
	#
	# Oyunçu [method add_player] ilə tick-dən ƏVVƏL doğulur və
	# [method Sim.find_spawn] məhz bu radiusdan istifadə edir. İlkin dəyər
	# `WORLD_RADIUS` (1200) idi, ÜÇLÜK-ün yaş radiusu isə 700 — yəni doğuş
	# dairəsinin üçdə ikisi QURU zonaya düşürdü. Oyunçu geriyə sayımda,
	# tərpənə bilmədən top yığmağa başlayırdı: doqquz çalışmanın altısı
	# birinci saniyədə "QURUYUR — mərkəzə get" xəbərdarlığı ilə açılırdı.
	_apply_wet()
	# Matçlı rejim oyunçu gözləyir; sonsuz arena isə həmişə açıqdır.
	phase = Const.Phase.PLAYING if mode == Const.Mode.ENDLESS else Const.Phase.WAITING


# ---------------------------------------------------------------- iştirakçılar

func human_count() -> int:
	return peers.size()


func has_room() -> bool:
	# Tutum REJİMDƏN çıxır: ÜÇLÜK altı mikrobludur, sabit 10 işlətsəydik
	# yeddinci oyunçu dolu dünyaya girməyə çalışardı.
	return peers.size() < Const.mode_capacity(int(mode))


## [param n] nəfərlik komanda bu dünyaya BİRLİKDƏ sığırmı.
##
## Komandalı rejimdə boş yuva azdır: yoldaşlar EYNİ komandada olmalıdır, yəni
## insanları ən azı n yeri boş olan bir komanda lazımdır. Botlar sayılmır —
## onlar insana yer verir (bax [method add_player]).
func has_room_for(n: int) -> bool:
	if peers.size() + n > Const.mode_capacity(int(mode)):
		return false
	return not Const.is_team_mode(int(mode)) or party_team(n) >= 0


## Komandanın oturacağı komanda: [param n] insan sığan və insanı ən az olan.
## Komandasız rejimdə və ya yer yoxdursa -1.
func party_team(n: int) -> int:
	if not Const.is_team_mode(int(mode)):
		return -1
	var size := Const.team_size(int(mode))
	var humans := PackedInt32Array()
	humans.resize(Const.mode_capacity(int(mode)) / size)
	for peer in peers:
		var t := int(teams.get(peer, -1))
		if t >= 0 and t < humans.size():
			humans[t] += 1
	var best := -1
	for i in humans.size():
		if humans[i] + n <= size and (best < 0 or humans[i] < humans[best]):
			best = i
	return best


## Dostlar komandası: hamısı EYNİ komandaya oturur (CÜT/ÜÇLÜK), sonsuz arenada
## isə sadəcə eyni dünyaya düşür. [param members] — `[[peer, ad, növ], ...]`.
## Çağıran əvvəlcə [method has_room_for] ilə yoxlamalıdır.
func add_party(members: Array) -> void:
	var team := party_team(members.size())
	for m in members:
		add_player(int(m[0]), str(m[1]), Const.species_from(int(m[2])), team)


## Oyunçunu dünyaya salır və mikrobunu doğurur.
##
## [param team] -2 = komandanı dünya özü seçir (tək oyunçu). Başqa dəyər
## komandanı MƏCBURİ edir — dostlar komandası üçündür (bax [method add_party]):
## o komandada bot varsa, yer məhz onun botundan açılır.
func add_player(peer: int, player_name: String,
		species := Const.Species.CILIATE, team := -2) -> Sim.GermState:
	if team >= 0:
		while _team_count(team) >= Const.team_size(int(mode)):
			if not _remove_one_bot(team):
				break
	# İnsan gələndə bot yerini ona verir — dünya heç vaxt hədddən çox olmur.
	if sim.germs.size() >= Const.mode_capacity(int(mode)):
		_remove_one_bot()
	peers.append(peer)
	_last_seq[peer] = 0
	tokens[peer] = _new_token()
	var g := sim.add_germ(peer, player_name, _free_color(), false, species)
	g.team = _free_team() if team == -2 else team
	teams[peer] = g.team
	_place_at_base(g)
	return g


## Dünyaya girəndə oyunçuya göndərilən məlumat.
func join_info_for(peer: int) -> Dictionary:
	var g: Sim.GermState = sim.germs.get(peer)
	# CÜT-də dirilməni gözləyən oyunçunun mikrobu yoxdur, amma qeydi var —
	# qopub qayıdanda rəngi, növü və adı oradan gəlir. Onsuz qayıdan oyunçu
	# HUD-da başqa rəngdə, super düyməsində başqa növlə görünərdi.
	var r: Dictionary = _revive.get(peer, {})
	return {
		"world": id,
		"you": peer,
		"color": g.color if g != null else int(r.get("color", 0)),
		# Növ serverdən geri qaytarılır: yenidən qoşulanda oyunçu köhnə mikrobuna
		# qayıdır və onun növü serverdəki qeyddir, menyudakı seçim deyil.
		"species": int(g.species) if g != null else int(r.get("species", Const.Species.CILIATE)),
		"name": g.name if g != null else str(r.get("name", "")),
		"mode": int(mode),
		"tick_rate": Const.TICK_RATE,
		"token": str(tokens.get(peer, "")),
		# Doğuş yeri: klientin proqnozu buradan başlayır (bax `Arena.configure_online`).
		# Dirilməni gözləyənin mikrobu yoxdur — onun klienti ilk snapshot-u gözləyir.
		"pos": g.pos if g != null else Vector2.INF,
		# Qaydaların versiyası — client uyğun gəlməsə açıq deyir (bax [constant Const.RULES]).
		"rules": Const.RULES,
		# Qida koloniyalarının yerləri `[x, y, növ, ...]` — dünya boyu dəyişmir; vəziyyəti
		# hər snapshot-dadır ([constant Const.Snap.COLONY]). Gec qoşulan da, qayıdan da
		# eyni yerləri alır.
		"colonies": sim.colony_flat(),
		# Qaydalar profili — mutasiyaların kartları və proqnozu yalnız bununla açılır.
		"profile": int(profile),
	}


## Oyunçunun mutasiya seçimi (design/MODES.md §19). Server yeganə hakimdir: profil və rejim,
## canlı mikrob, etibarlı və hələ seçilməmiş mutasiya, açılmış seçim (serverin saydığı həyat
## yaşı ilə), ən çox [constant Const.MUT_MAX]. Rədd səbəbi qaytarılır, "" — qəbul.
## Saxta, vaxtından əvvəl, təkrar və rejimə uyğun olmayan seçim heç nə dəyişmir.
func choose_mutation(peer: int, m: int) -> String:
	if not Const.rule_on(profile, Const.Profile.MUTATIONS) or mode != Const.Mode.ENDLESS:
		return "profile"
	var g: Sim.GermState = sim.germs.get(peer)
	if g == null or not g.alive:
		return "dead"
	if m < 0 or m >= Const.MUT_COUNT:
		return "unknown"
	if Const.has_mut(g.mutations, m):
		return "taken"
	var have := Const.mut_count(g.mutations)
	if have >= Const.MUT_MAX:
		return "full"
	if have >= Const.mut_earned(g.age):
		return "early"
	g.mutations |= 1 << m
	return ""


## Baxanın açılmış seçim sayı ([constant Const.Snap.EVO]); mutasiyasız profildə -1.
## Baxanın öz membranının soyuması ([constant Const.Snap.MEM]); membransız profildə -1.
func _mem_of(g: Sim.GermState) -> float:
	if not sim.membrane_on:
		return -1.0
	return snappedf(g.mem_cd, 0.01) if g != null else 0.0


func _evo_of(g: Sim.GermState) -> int:
	if not Const.rule_on(profile, Const.Profile.MUTATIONS):
		return -1
	return Const.mut_earned(g.age) if g != null else 0


static func _new_token() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## Ən kiçik boş rəng yuvası. 10 rəng var, dünyada da maksimum 10 mikrob —
## ona görə rəng həmişə tapılır və heç iki mikrob eyni rəngdə olmur.
func _free_color() -> int:
	var used := {}
	for gid in sim.germs:
		used[sim.germs[gid].color] = true
	for i in Palette.GERM_COLORS.size():
		if not used.has(i):
			return i
	return sim.germs.size() % Palette.GERM_COLORS.size()


# ---------------------------------------------------------------- matç

## Fazanı irəli aparır.
##
## SONSUZ ARENA bu funksiyadan DƏRHAL çıxır: onun fazası həmişə PLAYING-dir.
## Belə olanda köhnə rejim yeni sistemin altında toxunulmaz qalır — kod bir
## yoldan gedir, amma davranış iki cürdür.
func _step_phase(dt: float) -> void:
	if mode == Const.Mode.ENDLESS:
		return

	phase_t += dt
	match phase:
		Const.Phase.WAITING:
			# İnsan gələn kimi matç qurulur. NÖVBƏ YOXDUR: boş yerləri botlar
			# tutur, çünki oyunçu bazası kiçikdir və növbə "boş oyun" hissi verir.
			if human_count() > 0:
				_set_phase(Const.Phase.COUNTDOWN)
		Const.Phase.COUNTDOWN:
			if phase_t >= Const.COUNTDOWN_TIME:
				_set_phase(Const.Phase.PLAYING)
		Const.Phase.PLAYING:
			match_t += dt
			# ÜÇLÜK vaxt həddi matçın deyil, RAUNDUN həddidir.
			if mode == Const.Mode.TRIO and match_t >= Const.TRIO_ROUND:
				_end_round()
			# Bitmə şərti burada YOX, addımdan SONRA yoxlanılır: sonuncu mikrob
			# məhz `sim.step` içində partlayır və matç o anda bitməlidir,
			# növbəti tick-də yox. Bir tick gecikmə oyunçuya ölü dünyada bir
			# kadr göstərərdi.
		Const.Phase.OVER:
			pass    # Lobby bağlayır (bax [method Lobby._tick_worlds])


func _set_phase(next: Const.Phase) -> void:
	phase = next
	phase_t = 0.0
	if next == Const.Phase.OVER:
		_award_survivors()


## ÜÇLÜK: raundu bitirir və ya matçı yekunlaşdırır.
##
## Raund qalibi: sağ mikrobu çox olan komanda; bərabərdirsə TOP CƏMİ çox olan
## (bax design/MODES.md §6.4). Bərabərlik qaydası lazımdır, çünki 60 saniyə
## heç kimin ölmədiyi raund tamamilə mümkündür.
func _end_round() -> void:
	if round_wins.size() < 2:
		round_wins.resize(2)

	var alive := [_team_alive(0), _team_alive(1)]
	var balls := [0, 0]
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.team == 0 or g.team == 1:
			balls[g.team] += g.balls

	var winner := -1
	if alive[0] != alive[1]:
		winner = 0 if alive[0] > alive[1] else 1
	elif balls[0] != balls[1]:
		winner = 0 if balls[0] > balls[1] else 1
	if winner >= 0:
		round_wins[winner] += 1

	# Matç bitdimi?
	if winner >= 0 and round_wins[winner] >= Const.TRIO_ROUNDS_WIN:
		_set_phase(Const.Phase.OVER)
		return

	# Yeni raund: HAMI eyni şərtlərlə doğulur.
	#
	# Tutum raunddan raunda KEÇMİR — keçsəydi, birinci raundu udan komanda
	# ikincidə də üstün başlayardı və matç faktiki olaraq bir raundda həll
	# olunardı.
	round_no += 1
	_rounds_t += match_t
	_revive.clear()
	# `match_t` və qabın radiusu [method _reset_round]-un içində sıfırlanır —
	# doğuş yeri onlardan asılıdır, ona görə bir sahibi olmalıdır.
	_reset_round()
	_set_phase(Const.Phase.COUNTDOWN)


## Raund üçün dünyanı təzələyir: hamı diri, tam əhali, başlanğıc tutumu.
func _reset_round() -> void:
	# Qab ƏVVƏLCƏ genişlənir, sonra hamı doğulur.
	#
	# `_end_round` [method tick]-in İÇİNDƏ, `sim.dish_radius` yenilənməsindən
	# ƏVVƏL çağırılır, yəni bura gələndə radius hələ də bitən raundun SON
	# dəyəridir (ÜÇLÜK-də 220 px). Onsuz altı mikrob quruyub kiçilmiş qabın
	# mərkəzinə — üstəlik maneənin üstünə — yığılırdı.
	match_t = 0.0
	_apply_wet()
	# Raundda ölən insanlar QAYIDIR — öz komandalarına, adları və növləri ilə. Botlardan
	# ƏVVƏL: geri sayımda [method _keep_population] boş yerləri botlarla doldurur və
	# insanın yerini bot tutmamalıdır.
	for gid in _round_wait.keys():
		var r: Dictionary = _round_wait[gid]
		var back := sim.add_germ(gid, String(r["name"]), int(r["color"]), false,
			Const.species_from(int(r["species"])))
		back.team = int(r["team"])
	_round_wait.clear()
	for gid in sim.germs.keys():
		var g: Sim.GermState = sim.germs[gid]
		g.balls = Const.START_BALLS
		g.capacity = Const.START_CAPACITY
		g.charge = 0
		g.super_t = 0.0
		g.dry_t = 0.0
		g.safe_t = Const.SPAWN_SAFE_TIME
		# Yeninin qalxanı növbəti raundun ilk girişində yenidən qurulur ([method accept_input]).
		g.newbie = false
		g.vel = Vector2.ZERO
		g.pos = sim.find_spawn(g.radius())
	sim.clear_shots()
	# İnsanların köhnə raund girişi silinir: geri sayımda girişlər qəbul olunmur, server isə
	# saxlanan SONUNCU girişi təkrarlayırdı — mikrob doğulduğu yerdən sürüşürdü, proqnoz
	# (sayımda yerində durur) isə raund başlayanda geri dartılırdı. Gec giriş halı da
	# unudulur: yenidən oynatma mikrobu köhnə raundun yerinə qaytara bilərdi.
	for peer in peers:
		_inputs.erase(peer)
		_forget_replay(peer)


## CÜT: dirilmə növbəsini işlədir.
##
## Tutum və super doluluğu SIFIRDAN başlayır — dirilmə ikinci şansdır,
## cəzasız davam deyil. Əks halda dolu cüt qəsdən ölüb təzələnərdi.
func _step_revive(dt: float) -> void:
	if _revive.is_empty():
		return
	for gid in _revive.keys():
		var r: Dictionary = _revive[gid]
		# Yoldaşı da ölübsə dirilmə ləğv olunur — cüt matçdan çıxır.
		#
		# İnsan isə NƏTİCƏ almalıdır. Əvvəl ona yalnız yer yazılırdı: cüt
		# matçdan çıxmışdı, oyunçu isə matç bitənə qədər nəticəsiz izləyici
		# qalırdı. Ölüm qeydi onun öz partlamasındandır — partladan da, tutum da
		# o anın rəqəmləridir, ləğv anının yox.
		if _team_alive(int(r["team"])) <= 0:
			_revive.erase(gid)
			places[gid] = _teams_standing() + 1
			if not bool(r["bot"]):
				_revive_lost.append(r["entry"])
			continue
		r["left"] = float(r["left"]) - dt
		if float(r["left"]) > 0.0:
			continue
		_revive.erase(gid)
		var g := sim.add_germ(gid, String(r["name"]), int(r["color"]),
			bool(r["bot"]), Const.species_from(int(r["species"])))
		g.team = int(r["team"])
		if bool(r["bot"]):
			_bots[gid] = Bot.new(gid, sim.rng.randf_range(0.7, 1.3), sim.rng.randi())
		sim.events.append({
			"t": "super", "pos": g.pos, "arg": 0.0, "color": g.color})


## Sağ qalanlara yer verir və insanların nəticəsini hazırlayır.
##
## [member places] yalnız PARTLAYANLAR üçün doldurulur (bax [method tick]) —
## qalib isə tərifinə görə partlamır. Bu funksiya olmasaydı, matçı UDAN oyunçu
## nəticə ekranında yerini "0" görərdi: sıralamanın yeganə boşluğu budur.
##
## Vaxt həddi ilə bitən matçda bir neçə mikrob sağ qala bilər. Onlar liderlər
## cədvəli ilə EYNİ meyara görə sıralanır: partlatma sayı, bərabərlikdə tutum
## (bax [method Sim.leaderboard]).
##
## Əvvəl top sayına görə sıralanırdı və bu, ekranla ziddiyyət yaradırdı:
## oyunçu bütün matç boyu cədvəlin birincisi ola, sonda isə dördüncü çıxa
## bilərdi. Üstəlik çox top saxlamaq bacarıq deyil — partlamağa yaxın olmaqdır.
func _award_survivors() -> void:
	if Const.is_objective_mode(int(mode)):
		_award_teams()
		return
	if mode == Const.Mode.TRIO:
		_award_trio()
		return
	var ids := sim.germs.keys()
	ids.sort_custom(func(a, b) -> bool:
		var ga: Sim.GermState = sim.germs[a]
		var gb: Sim.GermState = sim.germs[b]
		if ga.pops != gb.pops:
			return ga.pops > gb.pops
		return ga.capacity > gb.capacity)

	var place := 1
	for gid in ids:
		places[gid] = place
		if not _bots.has(gid):
			var g: Sim.GermState = sim.germs[gid]
			# Ölüm nəticəsi ilə EYNİ formadır ki, client tək yolla işləsin —
			# fərq yalnız `won` bayrağındadır.
			pending_results.append({
				"id": gid,
				"killer_name": "",
				"pops": g.pops,
				"cap": g.capacity,
				"age": g.age,
				"won": place == 1,
				# `survived` OLMASAYDI, client sağ oyunçunu partlamış sayardı:
				# partladan adı boşdur, boş ad isə "acından partladın" deməkdir.
				"survived": true,
				"timed_out": timed_out,
			})
		place += 1


## Matç bitdimi?
##
## TƏK QALAN: bir mikrob qalanda. Vaxt həddi keçilsə də bitir — o vaxta qədər
## qab onsuz da tam qurumuş olur, yəni matç uzana bilməz.
func _match_over() -> bool:
	# Sıra VACİBDİR: hər iki şərt eyni tick-də ödənə bilər və o halda matç
	# "sonuncu qaldı" ilə bitməlidir, "vaxt bitdi" ilə yox — nəticə ekranındakı
	# cümlə bundan asılıdır.
	#
	# KOMANDALI rejimdə şərt "bir mikrob" yox, "bir KOMANDA" qalmasıdır:
	# CÜT-də sona iki mikrob qalır və matç onda bitir.
	if Const.is_team_mode(int(mode)):
		if _teams_standing() <= 1:
			return true
	elif sim.germs.size() <= 1:
		return true
	if match_t >= Const.MATCH_MAX:
		timed_out = true
		return true
	return false


## Giriş qəbul edilirmi? Geriyə sayımda mikroblar görünür, amma tərpənmir —
## oyunçu kimlə oynadığını görür və hamı eyni anda başlayır.
func inputs_open() -> bool:
	return phase == Const.Phase.PLAYING


## Snapshot-un matç sahəsi (bax [enum Const.MF]).
func _match_row(peer: int) -> Array:
	var team: int = int(teams.get(peer, -1))
	var us := 0
	var them := 0
	if mode == Const.Mode.TRIO and team >= 0 and round_wins.size() >= 2:
		us = round_wins[team]
		them = round_wins[1 - team]
	var objective := Const.is_objective_mode(int(mode))
	if objective:
		var score := team_scores()
		us = score[team] if team == 0 or team == 1 else score[0]
		them = score[1 - team] if team == 0 or team == 1 else score[1]
	var row := [
		int(mode),
		int(phase),
		phase_t,
		sim.dish_radius,
		_alive_count(),
		int(places.get(peer, 0)),
		team,
		us,
		them,
	]
	# Köhnə rejimlərin sətri dəyişmir — yeni sahələr yalnız obyekt rejimində gedir.
	if objective:
		row.append(_obj_row())
		var r: Dictionary = _respawn.get(peer, {})
		row.append(maxf(float(r.get("left", 0.0)), 0.0))
	return row


## Sağ sayılan mikroblar — CÜT-də dirilmə gözləyən də SAĞ sayılır.
##
## Yoxsa HUD-dakı "SAĞ: N" yoldaş öləndə düşür, 15 saniyə sonra qalxır və
## oyunçu kiminsə matçdan çıxdığını sanır.
func _alive_count() -> int:
	return sim.germs.size() + _revive.size() + _respawn.size()


## Komandada neçə mikrob sağdır (dirilmə gözləyənlər DAXİL DEYİL).
func _team_alive(team: int) -> int:
	if team < 0:
		return 0
	var n := 0
	for gid in sim.germs:
		if sim.germs[gid].team == team:
			n += 1
	return n


## Neçə komandanın sağ mikrobu var.
func _teams_standing() -> int:
	var seen := {}
	for gid in sim.germs:
		seen[sim.germs[gid].team] = true
	for gid in _revive:
		seen[int(_revive[gid]["team"])] = true
	return seen.size()


# ---------------------------------------------------------------- obyekt rejimləri

## Yaş sahəni dünyaya yazır. Radius və mərkəz YALNIZ rejimdən və matç saatından
## çıxır ([method Const.wet_circle]) — client-in proqnozu eyni dəyəri özü hesablayır.
func _apply_wet() -> void:
	var wet := Const.wet_circle(int(mode), match_t)
	sim.wet_center = Vector2(wet.x, wet.y)
	sim.dish_radius = wet.z


## Bazanın doğuş dairəsinin radiusu. ANA-da yuvanın içi dardır (Ana, tıxac, yan
## seliklər), ona görə axtarış geniş dairədə gedir və maneələr yeri özü süzür.
static func _base_spread(m: int) -> float:
	match m:
		Const.Mode.MOTHER: return 170.0
		Const.Mode.ISLAND: return 100.0
		_: return 110.0


## Mikrobu öz komandasının bazasına qoyur (yalnız obyekt rejimlərində).
func _place_at_base(g: Sim.GermState) -> void:
	if not Const.is_objective_mode(int(mode)) or g.team < 0:
		return
	g.pos = sim.find_spawn_near(Const.team_base(int(mode), g.team), _base_spread(int(mode)),
		g.radius())
	g.vel = Vector2.ZERO
	# Rəqibin tərəfinə baxır — doğulan kimi öz şüşəsinə atəş açmasın.
	g.aim = 0.0 if g.team == 0 else PI


## Ölən mikrobu bazada doğulma növbəsinə qoyur.
func _queue_respawn(gid: int, team: int, entry: Dictionary) -> void:
	_obj_pops[gid] = int(_obj_pops.get(gid, 0)) + int(entry.get("pops", 0))
	var bot := _bots.has(gid)
	_respawn[gid] = {
		"left": Const.respawn_time(int(mode)),
		"team": team,
		"bot": bot,
		"name": String(entry.get("name", "Mikrob")),
		"color": int(entry.get("color", 0)),
		"species": int(entry.get("species", 0)),
		# Superin doluluğu ölümdən keçir (design/MODES.md §16.1) — ölüm tutumu alır, səbri yox.
		"charge": int(entry.get("charge", 0)),
		"eye": entry.get("pos", Const.team_base(int(mode), team)),
	}
	if bot:
		_bots.erase(gid)


func _step_respawn(dt: float) -> void:
	if _respawn.is_empty():
		return
	for gid in _respawn.keys():
		var r: Dictionary = _respawn[gid]
		r["left"] = float(r["left"]) - dt
		if float(r["left"]) > 0.0:
			continue
		_respawn.erase(gid)
		_respawn_now(gid, r)


func _respawn_now(gid: int, r: Dictionary) -> void:
	var g := sim.add_germ(gid, String(r["name"]), int(r["color"]), bool(r["bot"]),
		Const.species_from(int(r["species"])))
	g.team = int(r["team"])
	g.charge = int(r["charge"])
	_place_at_base(g)
	if bool(r["bot"]):
		_bots[gid] = Bot.new(gid, sim.rng.randf_range(0.7, 1.3), sim.rng.randi())
	sim.events.append({"t": "super", "pos": g.pos, "arg": 0.0, "color": g.color})


## Komandaların hesabı: ANA-da Anaların top sayı, ADA-da xal, TOP-da qol.
func team_scores() -> PackedInt32Array:
	if mode == Const.Mode.MOTHER:
		return sim.mother_balls.duplicate()
	return obj_score.duplicate()


## Adada neçə SAĞ mikrob var — komandaya görə.
func island_counts() -> PackedInt32Array:
	var n := PackedInt32Array([0, 0])
	var r2 := sim.dish_radius * sim.dish_radius
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		if g.alive and (g.team == 0 or g.team == 1) \
				and g.pos.distance_squared_to(sim.wet_center) <= r2:
			n[g.team] += 1
	return n


## Matçı obyekt qərar verir — tick-dən SONRA, çünki Ana və qol `sim.step`-in içində olur.
func _step_objective(dt: float) -> void:
	match int(mode):
		Const.Mode.MOTHER:
			_step_mother(dt)
		Const.Mode.ISLAND:
			_step_island(dt)
		Const.Mode.BALL:
			_step_ball_match()


## ANA HÜCEYRƏ: partlayan Ana matçı bitirir; 2:30-da daha boş Ana udur, yaxındırsa
## 30 s əlavə vaxt — əmmək dayanır, iki Ana da dolur (design/MODES.md §16.2).
func _step_mother(dt: float) -> void:
	if sim.mother_burst >= 0:
		_finish(1 - sim.mother_burst, false)
		return
	if mother_ot:
		_ot_fill += Const.MOTHER_OT_FILL * dt
		while _ot_fill >= 1.0:
			_ot_fill -= 1.0
			sim.mother_balls[0] += 1
			sim.mother_balls[1] += 1
		var over := [sim.mother_balls[0] > Const.MOTHER_CAP, sim.mother_balls[1] > Const.MOTHER_CAP]
		if over[0] or over[1]:
			for t in 2:
				if over[t] and sim.mother_index[t] >= 0:
					var o := sim.obstacles[sim.mother_index[t]]
					sim.events.append({"t": "break", "pos": Vector2(o.x, o.y), "arg": o.z, "color": 0})
			_finish(-2 if over[0] and over[1] else (1 if over[0] else 0), false)
			return
		if match_t >= Const.MOTHER_TIME + Const.MOTHER_OT:
			_finish(_emptier_mother(1), true)
		return
	if match_t < Const.MOTHER_TIME:
		return
	if _emptier_mother(Const.MOTHER_TIE) >= 0:
		_finish(_emptier_mother(Const.MOTHER_TIE), true)
	else:
		mother_ot = true
		sim.mother_ot = true


## Daha boş Ananın komandası — fərq [param gap]-dən azdırsa -2 (bərabər).
func _emptier_mother(gap: int) -> int:
	var d := sim.mother_balls[0] - sim.mother_balls[1]
	if absi(d) < gap:
		return -2
	return 0 if d < 0 else 1


## YAŞ ADA: hər saniyə adada SAĞ mikrobu çox olan komandaya +1 xal.
func _step_island(dt: float) -> void:
	if match_t >= Const.ISLAND_START + Const.ISLAND_SHRINK:
		_island_acc += dt
		while _island_acc >= 1.0:
			_island_acc -= 1.0
			_island_point()
	for t in 2:
		if obj_score[t] >= Const.ISLAND_WIN:
			_finish(t, false)
			return
	# 3:00-dan sonra bərabərlik "ilk fərq" ilə açılır; 4:00 son həddir.
	if match_t >= Const.ISLAND_TIME and obj_score[0] != obj_score[1]:
		_finish(0 if obj_score[0] > obj_score[1] else 1, true)
	elif match_t >= Const.MATCH_MAX:
		_finish(-2, true)


func _island_point() -> void:
	var n := island_counts()
	var t := -1
	if n[0] != n[1]:
		t = 0 if n[0] > n[1] else 1
	elif n[0] > 0:
		# Bərabərlik geridə qalanındır — yalnız fərq böyükdürsə (qaçan hesabı dondurmasın).
		var gap := obj_score[0] - obj_score[1]
		if gap <= -Const.ISLAND_CATCHUP:
			t = 0
		elif gap >= Const.ISLAND_CATCHUP:
			t = 1
	if t >= 0:
		obj_score[t] += 1


## NÜVƏ TOPU: qol hamını yerinə qaytarır; ilk 2 qol, 2:30-da çox qolu olan, bərabərdirsə
## ilk qol (ən çox [constant Const.BALL_OT] saniyə, sonra heç-heçə).
func _step_ball_match() -> void:
	var g := sim.ball_goal
	if g >= 0:
		obj_score[g] += 1
		if obj_score[g] >= Const.BALL_GOALS or match_t >= Const.BALL_TIME:
			_finish(g, match_t >= Const.BALL_TIME)
		else:
			_kickoff()
		return
	if match_t >= Const.BALL_TIME and obj_score[0] != obj_score[1]:
		_finish(0 if obj_score[0] > obj_score[1] else 1, true)
	elif match_t >= Const.BALL_TIME + Const.BALL_OT:
		_finish(-2, true)


## Qoldan sonra: ölənlər dərhal doğulur, hamı bazasına qayıdır, Nüvə mərkəzə, 3 s sayım.
## Matçın saatı dayanır (sayımda `match_t` artmır).
func _kickoff() -> void:
	for gid in _respawn.keys():
		var r: Dictionary = _respawn[gid]
		_respawn.erase(gid)
		_respawn_now(gid, r)
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		_place_at_base(g)
		g.safe_t = maxf(g.safe_t, Const.SPAWN_SAFE_TIME)
	sim.clear_shots()
	if sim.ball != null:
		sim.ball.reset()
	# Köhnə giriş təkrarlanmasın və gec giriş mikrobu köhnə yerinə qaytarmasın
	# (bax [method _reset_round] — eyni səbəb).
	for peer in peers:
		_inputs.erase(peer)
		_forget_replay(peer)
	_set_phase(Const.Phase.COUNTDOWN)


func _finish(winner: int, by_time: bool) -> void:
	obj_winner = winner
	timed_out = by_time
	_set_phase(Const.Phase.OVER)


## Obyekt rejiminin nəticəsi KOMANDANINDIR: hər insan — sağ da, doğulmağı gözləyən
## də — eyni anda nəticə alır. Yer: qalib komanda 1, uduzan 2, heç-heçədə hamı 1.
## ÜÇLÜK-ün nəticəsi KOMANDANINDIR: iki raund udan komanda qalibdir, raund hesabı
## göstərilir, fərdi "N-ci YER" yoxdur. Son raundda ölüb gözləyən insan da ([member
## _round_wait]) nəticəni məhz burada alır — öz komandasının nəticəsini.
##
## Forma obyekt rejimlərininki ilədir (`mode`, `score_us`, `score_them`): [Lobby] və
## məşq bu açarları olduğu kimi ötürür, client isə komanda ekranını göstərir.
func _award_trio() -> void:
	if round_wins.size() < 2:
		round_wins.resize(2)
	var winner := -1
	if round_wins[0] != round_wins[1]:
		winner = 0 if round_wins[0] > round_wins[1] else 1
	for gid in teams:
		places[gid] = 1 if winner < 0 or int(teams[gid]) == winner else 2
	for peer in peers:
		var t := int(teams.get(peer, -1))
		var g: Sim.GermState = sim.germs.get(peer)
		pending_results.append({
			"id": peer,
			"killer_name": "",
			"pops": int(_obj_pops.get(peer, 0)) + (g.pops if g != null else 0),
			"cap": g.capacity if g != null else Const.START_CAPACITY,
			"age": _rounds_t + match_t,
			"won": winner >= 0 and t == winner,
			"survived": true,
			"timed_out": timed_out,
			"draw": winner < 0,
			"mode": int(mode),
			"score_us": round_wins[t] if t == 0 or t == 1 else 0,
			"score_them": round_wins[1 - t] if t == 0 or t == 1 else 0,
		})
	_round_wait.clear()


func _award_teams() -> void:
	var score := team_scores()
	for gid in teams:
		var t := int(teams[gid])
		places[gid] = 1 if obj_winner == -2 or t == obj_winner else 2
	for peer in peers:
		var t := int(teams.get(peer, -1))
		var g: Sim.GermState = sim.germs.get(peer)
		var us := score[t] if t == 0 or t == 1 else 0
		var them := score[1 - t] if t == 0 or t == 1 else 0
		pending_results.append({
			"id": peer,
			"killer_name": "",
			"pops": int(_obj_pops.get(peer, 0)) + (g.pops if g != null else 0),
			"cap": g.capacity if g != null else Const.START_CAPACITY,
			"age": match_t,
			"won": obj_winner >= 0 and t == obj_winner,
			"survived": true,
			"timed_out": timed_out,
			"draw": obj_winner == -2,
			"mode": int(mode),
			"score_us": us,
			"score_them": them,
		})


## Snapshot-un OBJ sahəsi (bax [enum Const.MF]): birinci ədəd həmişə matçın saatıdır —
## NÜVƏ TOPU-nda qoldan sonrakı sayım fazanın saatını sıfırlayır, matçınkını yox.
func _obj_row() -> PackedFloat32Array:
	var o := PackedFloat32Array([match_t])
	match int(mode):
		Const.Mode.MOTHER:
			o.append(1.0 if mother_ot else 0.0)
		Const.Mode.ISLAND:
			o.append_array([sim.wet_center.x, sim.wet_center.y, sim.dish_radius])
		Const.Mode.BALL:
			var b := sim.ball
			o.append_array([b.pos.x, b.pos.y, b.vel.x, b.vel.y, b.weight, 1.0 if b.alive else 0.0])
	return o


# ---------------------------------------------------------------- botlar

## Ən boş komandanın nömrəsi (komandasız rejimdə -1).
##
## Ən azı olana verilir ki, komandalar bərabər dolsun. İnsanlar ayrı-ayrı
## vaxtlarda gəlir və botlar aradakı boşluqları tutur — sadə növbə ilə
## paylasaydıq, bir komanda iki insanla, digəri iki botla qalardı.
func _free_team() -> int:
	if not Const.is_team_mode(int(mode)):
		return -1
	var size := Const.team_size(int(mode))
	var teams := Const.mode_capacity(int(mode)) / size
	var count := PackedInt32Array()
	count.resize(teams)
	for gid in sim.germs:
		var t: int = sim.germs[gid].team
		if t >= 0 and t < teams:
			count[t] += 1

	var best := 0
	for i in teams:
		if count[i] < count[best]:
			best = i
	return best


func _add_bot() -> void:
	var bid := _next_bot_id
	_next_bot_id += 1
	_bot_name_no += 1
	# Çətinlik təsadüfidir: dünyada həm asan, həm təhlükəli mikroblar olsun.
	#
	# Təsadüf dünyanın ÖZ generatorundandır ([member Sim.rng]), qlobaldan yox:
	# onun bir toxumu bütün dünyanı — doğuşları, botların növünü və qərarlarını —
	# təkrarlana bilən edir. Oyunda o, onsuz da təsadüfi başlayır.
	var bot := Bot.new(bid, sim.rng.randf_range(0.7, 1.3), sim.rng.randi())
	_bots[bid] = bot
	# Botların növü təsadüfidir ki, dünyada hər üç növ görünsün.
	var species := Const.species_from(sim.rng.randi() % Const.SPECIES_COUNT)
	var g := sim.add_germ(bid, Bot.random_name(_bot_name_no), _free_color(), true, species)
	g.team = _free_team()
	teams[bid] = g.team
	_place_at_base(g)


## Bir botu çıxarır; [param team] verilibsə, yalnız o komandanın botunu.
func _remove_one_bot(team := -1) -> bool:
	for bid in _bots:
		if team >= 0 and (not sim.germs.has(bid) or sim.germs[bid].team != team):
			continue
		_bots.erase(bid)
		sim.remove_germ(bid)
		_inputs.erase(bid)
		return true
	return false


func _team_count(team: int) -> int:
	var n := 0
	for gid in sim.germs:
		if sim.germs[gid].team == team:
			n += 1
	return n


## Əhalini [constant Const.MIN_POPULATION] səviyyəsində saxlayır.
##
## İlk doldurma DƏRHAL olur: oyunçu düyməni basandan sonra boş qaba düşməməlidir.
## Sonrakı itkilər isə gecikmə ilə əvəzlənir — mikroblar bir anda "peyda olmur".
func _keep_population(dt: float) -> void:
	# Matçlı rejimdə ölən ÖLÜR — əhali bərpa olunmur, yoxsa "sona qalan udur"
	# qaydası mənasız olur. Doldurma yalnız matç başlamazdan əvvəl işləyir.
	if mode != Const.Mode.ENDLESS:
		if phase != Const.Phase.WAITING and phase != Const.Phase.COUNTDOWN:
			return
		# Doğulmağı gözləyən də yer tutur — NÜVƏ TOPU-nda qoldan sonrakı sayımda
		# ölənlərin yerinə bot gəlməsin.
		while sim.germs.size() + _respawn.size() + _round_wait.size() 				< Const.mode_capacity(int(mode)):
			_add_bot()
		return

	var target: int = mini(Const.MIN_POPULATION, Const.WORLD_CAPACITY)
	if not _seeded:
		_seeded = true
		while sim.germs.size() < target:
			_add_bot()
		return
	if sim.germs.size() >= target:
		return
	_bot_timer -= dt
	if _bot_timer > 0.0:
		return
	_bot_timer = BOT_RESPAWN
	_add_bot()


# ---------------------------------------------------------------- axın

## Client-dən gələn giriş paketi.
func accept_input(peer: int, packed: Array) -> void:
	# Geriyə sayımda giriş qəbul edilmir: mikroblar görünür, amma tərpənmir.
	# Client də eyni qaydanı tətbiq edir, yoxsa proqnoz serverdən qabağa düşür
	# və sayım bitəndə mikrob geri sıçrayır.
	if not inputs_open():
		return
	if not sim.germs.has(peer):
		return
	if packed.size() < 5:
		return
	var inp := Sim.PlayerInput.from_array(packed)
	# Köhnəlmiş paketi atırıq — UDP-də sıra pozula bilər.
	if inp.seq <= int(_last_seq.get(peer, 0)):
		return
	# YENİ OYUNÇU: bit ilk dəfə görünəndə qalxan qurulur (bax [constant Const.NEWBIE_SAFE_TIME]).
	# Burada, sayımdan SONRA: girişlər yalnız oyun gedəndə qəbul olunur, yəni
	# qalxan oyunun ilk saniyəsindən sayılır. Yeni raund mikrobun bayrağını
	# sıfırlayır ([method _reset_round]) — qalxan hər raundda yenidən qurulur.
	if inp.newbie and peers.has(peer):
		var me: Sim.GermState = sim.germs[peer]
		if not me.newbie:
			me.newbie = true
			me.safe_t = maxf(me.safe_t, Const.NEWBIE_SAFE_TIME)
	# Mutasiya seçimi dərhal yoxlanılır və tətbiq olunur — növbəyə düşmür. Client onu təsdiq
	# gələnə qədər hər girişdə təkrarlayır; ikinci gəlişi "taken" deyə rədd olunur.
	if inp.evolve >= 0:
		choose_mutation(peer, inp.evolve)
	# BİR DƏFƏLİK bayraqlar köhnə paketdən yenisinə KEÇİR, onunla birlikdə
	# atılmır.
	#
	# Növbədə oyunçu başına yalnız SON giriş saxlanılır, iki paketin bir tick
	# aralığında gəlməsi isə adi haldır: client kadr sıçrayanda iki tick-i bir
	# kadrda göndərir ([method Arena._process] beş tick-ə qədər bərabərləşdirir),
	# WebSocket isə paketləri onsuz da yığır.
	#
	# Hərəkət üçün bunun əhəmiyyəti yoxdur — sonuncu mövqe onsuz da doğrudur.
	# Atəş də bilinmirdi, çünki düymə basılı saxlanılır və növbəti tick onu
	# təkrar göndərir. SUPER isə CƏMİ BİR tick göndərilir
	# ([method Arena._super_requested]), ona görə üstündən yazılan paket onu
	# tamamilə udurdu: oyunçu yanan düyməyə basırdı, proqnoz effekti bir kadr
	# göstərirdi, növbəti snapshot onu ləğv edirdi və doluluq yerində qalırdı.
	#
	# Ölçülüb: LOKAL WebSocket bağlantısında (itkisiz şəbəkə, sıfır gecikmə)
	# 50 saniyədə 1761 girişin 62-si belə atılırdı — 3.4%. Şəbəkə jitter-i ilə
	# rəqəm yalnız böyüyür, yəni onlayn oyunda superin "işləməməsi" məhz burada
	# doğulurdu.
	var queued: Sim.PlayerInput = _inputs.get(peer)
	if queued != null:
		# Atəş öz ANI ilə köçür: görünən tick və nişan atəşin paketindəndir. Tick
		# olmasa geri sarma itərdi; nişan olmasa top yeni paketin nişanı ilə,
		# proqnozunku isə köhnəsininki ilə uçardı (bax [member Sim.PlayerInput.fire_aim]).
		#
		# Hansı paket atəşin paketidir: proqnozun atəşi açdığı ([member
		# Sim.PlayerInput.shot]); o bilinmirsə (köhnə client) — düymənin İLK
		# basıldığı, çünki proqnoz atəşi soyuma bitən ilk paketdə açır.
		if queued.fire and (queued.shot or not inp.shot):
			inp.fire_aim = queued.aim if is_nan(queued.fire_aim) else queued.fire_aim
			inp.view_tick = queued.view_tick
			inp.fire_from = queued.fire_from
			inp.fire_range = queued.fire_range
			inp.shot = queued.shot
			inp.fire_wait = queued.fire_wait
		inp.fire = inp.fire or queued.fire
		inp.use_super = inp.use_super or queued.use_super
		# Membran da bir dəfəlikdir — üstündən yazılan paket onu udmasın.
		inp.membrane = inp.membrane or queued.membrane
	_inputs[peer] = inp
	# Gec gələn girişin hərəkəti saxlanılır — təxmin tick-ləri üçün (bax [method _replay_late]).
	if peers.has(peer):
		var q: Array = _late_q.get(peer, [])
		q.append(Sim.PlayerInput.make(inp.seq, inp.move, inp.aim, false))
		_late_q[peer] = q


## Bir tick. Partlayan oyunçuların siyahısını qaytarır — [Lobby] onlara
## nəticə göndərib dünyadan çıxarır.
func tick(dt: float) -> Array:
	_step_phase(dt)
	# Qabın kənarı YALNIZ rejimdən və matç saatından çıxır — prediction şərti
	# (bax [method Const.dish_radius]).
	_apply_wet()
	_keep_population(dt)
	# Spor TƏK QALAN və CÜT-dədir. ÜÇLÜK-də yoxdur: raund 60 saniyədir və
	# tutum artımı o qədər qısa oyunda balansı pozur (bax design/MODES.md §6.4).
	if phase == Const.Phase.PLAYING \
			and (mode == Const.Mode.SOLO or mode == Const.Mode.DUO):
		sim.keep_spores(dt)
	if phase == Const.Phase.PLAYING:
		_step_revive(dt)
		_step_respawn(dt)

	# Geri sayımda botlar da DAYANIR, insanlar kimi (insanın girişi bağlıdır — bax
	# [method accept_input]). Botun girişi o qapıdan keçmir və əvvəl botlar sayımda
	# tərpənirdi: TƏK QALAN/CÜT/ÜÇLÜK-də insandan 3 s qabaq yer seçirdilər (ölçülüb — matç
	# başına mikroblar cəmi 4.5–7.6 min px yer dəyişirdi), NÜVƏ TOPU-nda isə qoldan sonrakı
	# sayımda Nüvəni qapıya itələyirdilər, qol sayılmırdı və Nüvə yox olurdu.
	var frozen := phase == Const.Phase.COUNTDOWN
	for bid in _bots:
		var bot: Bot = _bots[bid]
		_inputs[bid] = Sim.PlayerInput.make(0, Vector2.ZERO, sim.germs[bid].aim, false) \
			if frozen and sim.germs.has(bid) else bot.think(sim, dt)
		# Botlar da eyni hədlərdə, eyni yoxlamadan keçən seçim edir — gizli üstünlük yoxdur.
		if Const.rule_on(profile, Const.Profile.MUTATIONS):
			var bg: Sim.GermState = sim.germs.get(bid)
			if bg != null and Const.mut_count(bg.mutations) < Const.mut_earned(bg.age):
				choose_mutation(bid, Bot.pick_mutation(bg))

	# Gec gələn girişlər təxmin olunan tick-lər üçün yenidən oynadılır (bax [constant REPLAY_MAX]).
	_replay_late()

	# Matç bitibsə dünya DONUR.
	#
	# Yoxsa nəticə ekranının arxasında botlar döyüşməyə, partlamağa və yer
	# dəyişməyə davam edir: oyunçu "bitmiş" matçın davam etdiyini görür və
	# server nəticə ekranı boyu boş yerə hesablayır.
	if phase != Const.Phase.OVER:
		sim.economy_paused = phase == Const.Phase.COUNTDOWN
		sim.step(_inputs, dt)
	else:
		# Hadisələri və partlama siyahısını yalnız `step` təmizləyir. Donmuş
		# dünyada təmizlənməsə, son tick-in partlayanları nəticə ekranı boyu HƏR
		# tick yenidən emal olunur: oyunçuya `on_burst` təkrar gedir (yeni matça
		# keçibsə, onu orada da "partladır") və effekt hər snapshot-da təkrarlanır.
		sim.events.clear()
		sim.burst_log.clear()

	# Atəş və super BİR DƏFƏLİK hadisələrdir. Paket itsə, saxlanan giriş təkrar
	# oxunar və oyunçu istəmədən yenidən atəş açar (super isə kirpiklidə üstəlik
	# iki top xərcləyər) — ona görə emaldan sonra ikisi də sıfırlanır.
	#
	# Bir istisna: proqnozun AÇDIĞI atəş ([member Sim.PlayerInput.shot]) serverdə
	# soyuma hələ bitməyibsə, [constant FIRE_WAIT] tick gözləyir. Soyumanı iki
	# tərəf eyni saxlayır, amma girişlər birləşəndə server onu bir tick gec
	# başlayır — o halda proqnoz atəşi açırdı, server isə "hələ tezdir" deyib
	# atırdı: ekranda uçan top serverdə heç olmurdu. Sürət dəyişmir — atəş yenə
	# yalnız soyuma bitəndə açılır.
	for gid in _inputs:
		var inp: Sim.PlayerInput = _inputs[gid]
		var g: Sim.GermState = sim.germs.get(gid)
		if g != null:
			_last_seq[gid] = inp.seq
		var waits := inp.fire and inp.shot and inp.fire_wait < FIRE_WAIT \
			and g != null and g.cooldown < Const.FIRE_COOLDOWN - 0.0001
		if waits:
			inp.fire_wait += 1
		else:
			inp.fire = false
			inp.shot = false
			inp.fire_wait = 0
		inp.use_super = false
		# Saxlanan giriş növbəti tick-də membranı yenidən istəməsin (bir basış — bir cəhd).
		inp.membrane = false

	# Hal və təxmin sayğacı (snapshot-un SELF sətri üçün, bax [method _self_row]).
	_record_replay_state()

	# YER — matçlı rejimdə partlayan mikrob o anda sağ qalanların sayı + 1
	# yerini alır. Yəni ilk ölən sonuncu, sona qalan birincidir.
	#
	# `sim.burst_log` `_reap`-dən SONRA oxunur, yəni `sim.germs.size()` artıq
	# ölənləri saymır — ona görə düstur sadədir.
	# Sayğac İRƏLİ gedir, geri yox.
	#
	# Geri getsəydi, eyni tick-də üç mikrob partlayanda onlar 6, 5, 4 yerlərini
	# alardı — halbuki 5 və 4 sonra SAĞ QALANLARA veriləcək və iki oyunçu eyni
	# "N-ci YER"-i görərdi. Quruma fazasında bir neçə mikrobun eyni anda dolub
	# partlaması adi haldır.
	var place := sim.germs.size() + 1

	var out := []
	for entry in sim.burst_log:
		var gid := int(entry["id"])
		_inputs.erase(gid)

		# CÜT — yoldaşı sağ ikən ölüm MÜVƏQQƏTİDİR.
		#
		# Yer verilmir, nəticə ekranı göndərilmir, mikrob dünyaya qayıdır
		# (bax [method _step_revive]). Yoldaşı da ölübsə, cüt matçdan çıxır və
		# adi ölüm yolu işləyir.
		var t: int = int(teams.get(gid, -1))
		# OBYEKT rejimi — ölüm həmişə MÜVƏQQƏTİDİR: mikrob bazasında yenidən doğulur.
		if Const.is_objective_mode(int(mode)):
			_queue_respawn(gid, t, entry)
			continue
		if mode == Const.Mode.DUO and phase == Const.Phase.PLAYING \
				and _team_alive(t) > 0:
			_revive[gid] = {
				"left": Const.REVIVE_TIME,
				"team": t,
				"bot": _bots.has(gid),
				"name": String(entry.get("name", "Mikrob")),
				"color": int(entry.get("color", 0)),
				"species": int(entry.get("species", 0)),
				"entry": entry,
				# Gözləyən öldüyü yeri görür — client-in kamerası da orada qalır
				# (bax [method snapshot_for]). Əvvəl görüş sahəsi qabın MƏRKƏZİ idi.
				"eye": entry.get("pos", Vector2.ZERO),
			}
			if _bots.has(gid):
				_bots.erase(gid)
			continue
		# ÜÇLÜK — ölən insan matçda qalır, növbəti raundu gözləyir (bax [member _round_wait]).
		if mode == Const.Mode.TRIO and phase == Const.Phase.PLAYING \
				and not _bots.has(gid) and peers.has(gid):
			_obj_pops[gid] = int(_obj_pops.get(gid, 0)) + int(entry.get("pops", 0))
			_round_wait[gid] = {
				"team": t,
				"name": String(entry.get("name", "Mikrob")),
				"color": int(entry.get("color", 0)),
				"species": int(entry.get("species", 0)),
				"eye": entry.get("pos", Vector2.ZERO),
			}
			continue

		if mode != Const.Mode.ENDLESS:
			places[gid] = place
			place += 1
		if _bots.has(gid):
			_bots.erase(gid)
			continue
		out.append(entry)

	out.append_array(_revive_lost)
	_revive_lost.clear()

	# Obyekt rejimini komandanın qırılması BİTİRMİR (hamı dirilir) — obyekt və vaxt bitirir.
	if phase == Const.Phase.PLAYING and Const.is_objective_mode(int(mode)):
		_step_objective(dt)
	elif phase == Const.Phase.PLAYING and _match_over():
		# ÜÇLÜK-də bir komandanın qırılması RAUNDU bitirir, matçı yox.
		if mode == Const.Mode.TRIO:
			_end_round()
		else:
			_set_phase(Const.Phase.OVER)

	_build_frame()
	return out


# ---------------------------------------------------------------- snapshot

## Şəbəkəyə gedən kompakt state. Dictionary yox, Array — 30 Hz-də hər bayt sayılır.
##
## Sətirlər bir dəfə qurulur, sonra hər oyunçu üçün YALNIZ görüş sahəsindəkilər
## süzülür. Dünya ekrandan böyükdür: hər kəsə hər şeyi göndərmək həm trafik
## israfıdır, həm də "divar arxasını görmək" kimi bir üstünlük verərdi.
## Ad və rəng cədvəli: `{id: [ad, rəng]}`.
##
## Bunlar mikrobun ömrü boyu DƏYİŞMİR, ona görə snapshot-da yeri yoxdur —
## ora yalnız hər kadr dəyişən şeylər gedir (bax [enum Const.GF]). Cədvəl
## etibarlı kanalla, yalnız mikrobların dəsti dəyişəndə göndərilir.
func roster() -> Dictionary:
	var out := {}
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		# Üçüncü sahə: bot, yoxsa insan. Client bunu id-dən çıxara bilməz — insanın
		# peer nömrəsi təsadüfi 32 bitlik ədəddir və adətən [constant BOT_ID_BASE]-dən
		# böyükdür (bax [member Arena._bot_colors]). Topun özü isə nə qədər geri
		# sarıldığını snapshot-da daşıyır ([enum Const.SF] `REWIND`).
		out[gid] = [g.name, g.color, _bots.has(gid)]
	return out


## Mikrobların dəsti dəyişdikcə artır — [Lobby] bununla nə vaxt göndərəcəyini bilir.
var roster_rev := 0
var _roster_key := 0


func _build_frame() -> void:
	# Dəst dəyişibsə reyestr köhnəlib.
	#
	# SAYI müqayisə etmək BƏS ETMİR: [method Sim.rekey_germ] mikrobu silib
	# yenidən əlavə edir, yəni id DƏYİŞİR, say isə qalır. Yenidən qoşulma məhz
	# bunu edir — say yoxlaması ilə qayıdan oyunçu bütün digər ekranlarda
	# adsız və 0 rəngli qalırdı. Eyni tələ: bir tick-də bot doğulub biri
	# partlasa da say dəyişmir.
	#
	# Ona görə id-lərin ÖZÜNDƏN sadə imza yığılır. On mikrob üçün pulsuzdur.
	var key := sim.germs.size()
	for gid in sim.germs:
		key = key * 31 + gid
	if key != _roster_key:
		_roster_key = key
		roster_rev += 1

	_frame_germs.clear()
	for gid in sim.germs:
		var g: Sim.GermState = sim.germs[gid]
		# Üçüncü sahə: hansı kolun içindədir (bax [method _near_germs]).
		_frame_germs.append([g.pos, sim.bush_of(g), g.id,
			g.pos.x, g.pos.y,
			g.vel.x, g.vel.y,
			g.aim, g.balls, g.capacity,
			_flags_of(g)])

	_frame_shots.clear()
	for s in sim.shots:
		var meta := Const.shot_meta(s.profile, s.payload, s.volley, s.long)
		if s.is_lob():
			# Damcının sətri baxana görə qurulur (bax [method _lob_row]): burada xam
			# məlumat — düşmə nöqtəsi, başlanğıc, qalan vaxt, sahib, atıcının kolu, indiki yer.
			_frame_shots.append([s.target, s.id, s.color, s.target.x, s.target.y,
				s.origin.x, s.origin.y, maxf(s.life, 0.0), meta, s.owner_id, s.bush, s.pos])
			continue
		# Qalan ömür istiqamətin UZUNLUĞUNDADIR: `dir × (1 + ömür)` — ayrıca sahə
		# paketi böyüdərdi (bax [method Const.unpack_shots]).
		var packed := s.dir * (1.0 + maxf(s.life, 0.0))
		# Geri sarma SANİYƏ ilə gedir: client insanın topunu məhz bu qədər irəli
		# çəkir ki, ekrandakı toxunuş serverin qərarı ilə üst-üstə düşsün
		# (bax [method Arena._remote_shot_pos]).
		_frame_shots.append([s.pos, s.id, s.color, s.pos.x, s.pos.y, packed.x, packed.y,
			s.rewind * Const.TICK_DELTA, meta])

	# Qida düz ədəd axını kimi paketlənir (bax [constant Const.FOOD_STRIDE]).
	#
	# Hər qida üçün kiçik `[pos, id]` massivi YARADILMIR: qida ən çox olan
	# obyektdir və tick-də yüzdən çox ayırma ölçülən xərc idi.
	var n_food := sim.food.size()
	_frame_food_pos.resize(n_food)
	_frame_food_id.resize(n_food)
	for i in n_food:
		var f := sim.food[i]
		_frame_food_pos[i] = f.pos
		_frame_food_id[i] = f.id

	# Hadisələr (top atma, udma, partlama) yalnız bu tick üçün gedir.
	# Sıra [enum Const.EF] ilə eynidir: KIND, X, Y, ARG, COLOR.
	_frame_events.clear()
	for e in sim.events:
		var kind := Const.EvKind.FIRE
		match e.get("t"):
			"fire": kind = Const.EvKind.FIRE
			"absorb": kind = Const.EvKind.ABSORB
			"super": kind = Const.EvKind.SUPER
			"spore": kind = Const.EvKind.SPORE
			"parry": kind = Const.EvKind.PARRY
			"hit": kind = Const.EvKind.HIT
			"burst": kind = Const.EvKind.BURST
			"break": kind = Const.EvKind.BREAK
		var pos: Vector2 = e["pos"]
		_frame_events.append([pos, kind, pos.x, pos.y, float(e["arg"]), int(e["color"])])

	# Cədvəldə AD yox, ID gedir: adlar onsuz da reyestrdədir (bax [method roster]).
	# Adları hər tick təkrar göndərmək cəmi beş sətir üçün ~200 bayt yeyirdi.
	_frame_board = PackedInt32Array()
	for row in sim.leaderboard(5):
		_frame_board.push_back(int(row[Const.LF.ID]))
		_frame_board.push_back(int(row[Const.LF.POPS]))

	# Koloniyalar azdır və yerində durur — AOI-siz, hamısı gedir: minimap onları göstərir,
	# qərar ("hansı mənbəyə gedim") ekrandan kənardakı mənbəni də bilməyi tələb edir.
	# Mikrob haqqında heç nə daşımır, gizlənəni açmır.
	_frame_colony = sim.colony_bytes()


## Mikrobun bayraqları bir ədəddə (bax [enum Const.GFlag]).
static func _flags_of(g: Sim.GermState) -> int:
	var f := (int(g.species) << Const.GFlag.SPECIES_SHIFT) & Const.GFlag.SPECIES_MASK
	if g.safe_t > 0.0:
		f |= Const.GFlag.SAFE
	# Superin doluluğu və işlək olması — ikisi də bayrağın boş bitlərində.
	# Rəqibin superinin hazır olduğu görünür: gərginlik oradan gəlir.
	f |= (g.charge << Const.GFlag.CHARGE_SHIFT) & Const.GFlag.CHARGE_MASK
	if g.super_t > 0.0:
		f |= Const.GFlag.SUPER
	# Komanda `team + 1` kimi yazılır ki, SIFIR "komandasız" qalsın
	# (bax [enum Const.GFlag]).
	if g.team >= 0:
		f |= ((g.team + 1) << Const.GFlag.TEAM_SHIFT) & Const.GFlag.TEAM_MASK
	# Aktiv mutasiyalar — anatomiya hamıya görünür, proqnoz öz mikrobununkunu buradan alır.
	f |= (g.mutations << Const.GFlag.MUT_SHIFT) & Const.GFlag.MUT_MASK
	# Membran: faza və kilidli istiqamət — rəqib aktiv və bərpa hissəsini görür, vaxtını seçir.
	var ph := Const.membrane_phase(g.mem_left)
	if ph != Const.MemPhase.NONE:
		f |= (ph << Const.GFlag.MEM_SHIFT) & Const.GFlag.MEM_MASK
		f |= (Const.dir_quant(g.mem_dir) << Const.GFlag.MEMDIR_SHIFT) & Const.GFlag.MEMDIR_MASK
	return f


func snapshot_for(peer: int) -> Array:
	var g: Sim.GermState = sim.germs.get(peer)
	var eye: Vector2 = g.pos if g != null else Vector2.ZERO
	# Doğulmağı gözləyən öldüyü yeri görür — client-in kamerası da orada qalır.
	if g == null and _respawn.has(peer):
		eye = _respawn[peer]["eye"]
	elif g == null and _revive.has(peer):
		eye = _revive[peer]["eye"]
	# ÜÇLÜK-də raundu gözləyən YOLDAŞININ gözü ilə görür (bax [method spectate_target]):
	# görüş sahəsi də, kol qaydası da onunkudur — yoxsa kolda gizlənən yoldaş izləyicinin
	# snapshot-undan düşərdi və kamera başqasına sıçrayardı.
	var watch: Sim.GermState = null
	if g == null and _round_wait.has(peer):
		var target := spectate_target(peer)
		watch = sim.germs.get(target) if target >= 0 else null
		eye = watch.pos if watch != null else _round_wait[peer]["eye"]
	# Böyük mikrob daha geniş görür, ona görə sahə tutumla birlikdə böyüyür —
	# əks halda ekranın kənarında obyektlər kəsilərdi.
	var cap: int = g.capacity if g != null else Const.START_CAPACITY
	var r2 := pow(Const.aoi_radius(cap), 2.0)
	# Baxan özü hansı koldadır — gizlənənləri yalnız o görür.
	var eye_bush := sim.bush_of(g) if g != null else (sim.bush_of(watch) if watch != null else -1)

	# BÜDCƏ — paket MTU-ya sığmalıdır və sabit hədlər bunu təmin etmir.
	#
	# Hər hədd ayrılıqda məqbul görünür, birlikdə isə aşır: ölçülüb, 10 mikrob
	# + 16 top + 12 hadisə + 32 qida birlikdə 1604 bayt verirdi (hədd 1392).
	# Ona görə qalan sahələr MİKROBLARDAN SONRA qalan yeri bölüşür.
	#
	# Prioritet sırası oyundan çıxır: mikrob (kimə qarşı oynayıram) → top
	# (nədən qaçıram) → hadisə (nə baş verdi) → qida (sonra yeyərəm).
	var germs := _near_germs(_frame_germs, eye, r2, eye_bush, peer)
	# Baxanın gördüyü mikroblar — damcının atıcısı onların arasında deyilsə, xəbərdarlıq
	# onun yerini və rəngini AÇMIR (bax [method _lob_row]).
	var seen: PackedInt32Array = germs[0]
	var n_germs: int = (germs[0] as PackedInt32Array).size()
	var fixed := Const.SNAP_FIXED + (Const.SNAP_OBJ if Const.is_objective_mode(int(mode)) else 0)
	var left: int = maxi(Const.MTU_SAFE - fixed - n_germs * Const.GERM_BYTES, 120)

	var shot_n: int = clampi(left * 40 / 100 / Const.SHOT_BYTES, 4, Const.SHOT_SEND_MAX)
	left -= shot_n * Const.SHOT_BYTES
	var event_n: int = clampi(left * 35 / 100 / Const.EVENT_BYTES, 3, Const.EVENT_SEND_MAX)
	left -= event_n * Const.EVENT_BYTES
	var food_n: int = clampi(left / Const.FOOD_BYTES, 6, Const.FOOD_SEND_MAX)

	return [
		sim.tick,
		germs,
		_near_shots(_frame_shots, eye, r2, shot_n, seen, eye_bush, peer,
			g.radius() if g != null else Const.BASE_RADIUS),
		_near_food(_frame_food_pos, _frame_food_id, eye, r2, food_n),
		_near_flat(_frame_events, eye, r2, event_n, g.color if g != null else -1),
		_frame_board,
		# ƏHALİ və SAĞ SAY eyni tərifdən çıxır ([method _alive_count]).
		#
		# Əvvəl bura `sim.germs.size()` gedirdi, matç sətrinə isə dirilmə
		# gözləyənlər DAXİL olan say — nəticədə HUD-un iki qonşu sətri
		# ziddiyyət yazırdı: "Dünyada 8 mikrob" və altında "SAĞ: 10".
		# CÜT-də yoldaş öləndən dirilənə qədər 15 saniyə belə görünürdü.
		_alive_count(),
		sim.broken,
		_match_row(peer),
		_self_row(peer, g),
		_frame_colony,
		_evo_of(g),
		_mem_of(g),
	]


## ÜÇLÜK-də ölüb raundu gözləyən oyunçu kimi izləyir: komandasının ən kiçik id-li SAĞ
## mikrobunu. Client eyni qaydanı öz snapshot-undan çıxarır ([method Arena._spectate_id]):
## izlənən yoldaş görüş sahəsinin mərkəzi olduğu üçün snapshot-da həmişə var, ondan kiçik
## id-li sağ yoldaş isə ola bilməz — iki tərəf eyni mikrobu seçir, şəbəkəyə sahə lazım deyil.
## Sağ yoldaş yoxdursa (raund elə bu tick bitir) öldüyü yer.
func spectate_target(peer: int) -> int:
	var team := int(teams.get(peer, -1))
	var best := -1
	for gid in sim.germs:
		if gid != peer and sim.germs[gid].team == team and team >= 0 \
				and (best < 0 or gid < best):
			best = gid
	return best



## Mikroblar üçün ayrıca süzgəc: məsafədən ƏLAVƏ gizlənmə qaydası var.
##
## Kolun içindəki mikrob yalnız EYNİ kolun içindəkinə görünür. Qayda
## serverdədir və başqa yerdə ola da bilməzdi: client-də olsaydı, gizlənən
## oyunçunun mövqeyi onsuz da şəbəkə ilə gedərdi və paketə baxan hər kəs onu
## görərdi. Gizlənmə YALNIZ göndərilməyəndə həqiqidir.
##
## Öz mikrobun həmişə göndərilir: sən özünü kolda da görməlisən.
## Nəticə İKİ sıx massivdir: id-lər və qalan ədədlər
## (bax [method Const.unpack_germs]).
static func _near_germs(rows: Array, eye: Vector2, r2: float,
		eye_bush: int, peer: int) -> Array:
	var ids := PackedInt32Array()
	var data := PackedFloat32Array()
	for row in rows:
		if eye.distance_squared_to(row[0]) > r2:
			continue
		var bush: int = row[1]
		var gid: int = row[2]
		if bush >= 0 and bush != eye_bush and gid != peer:
			continue
		ids.push_back(gid)
		for i in range(3, row.size()):
			data.push_back(float(row[i]))
	return [ids, data]


## Toplar üçün süzgəc — qida ilə eyni səbəbdən sıx ədəd axınıdır.
##
## Variant massivində hər ədəd ~9 bayt tutur, `PackedFloat32Array`-də isə 4.
## Döyüş qızışanda ekranda 15-ə qədər top olur; köhnə format o anda tək
## başına ~690 bayt yeyirdi və snapshot MTU-nu aşırdı.
##
## Hədd aşılanda ən yaxınlar qalır, amma TƏHLÜKƏLİ olan önə keçir: baxanın düşmə
## sahəsinə yaxın damcı hər topdan əvvəl gedir — oyunçu ona düşən xəbərdarlığı
## paket sıxlığına görə itirməməlidir. Atılanların sayı [member shots_cut]-a yazılır.
##
## Damcı görüş sahəsinə həm düşmə nöqtəsi, həm də havadakı yeri ilə düşə bilər.
func _near_shots(rows: Array, eye: Vector2, r2: float, limit: int,
		seen: PackedInt32Array, eye_bush: int, peer: int, eye_r: float) -> PackedFloat32Array:
	var near: Array = []
	var danger := pow(eye_r + Const.LOB_AREA + LOB_WARN_PAD, 2.0)
	for row in rows:
		var d := eye.distance_squared_to(row[0])
		var lob: bool = row.size() > 9
		if lob:
			if d <= danger:
				d = -1.0
			else:
				d = minf(d, eye.distance_squared_to(row[11]))
		if d > r2:
			continue
		near.append([d, row])

	if near.size() > limit:
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		shots_cut += near.size() - limit
		near.resize(limit)

	var out := PackedFloat32Array()
	for e in near:
		var row: Array = e[1]
		if row.size() > 9:
			out.append_array(_lob_row(row, seen, eye_bush, peer))
			continue
		for i in range(1, row.size()):
			out.push_back(float(row[i]))
	return out


## Damcının sətri baxana görə ([enum Const.SF], DAMCI).
##
## Xəbərdarlıq hamıya gedir — düşmə nöqtəsi və qalan vaxt. Başlanğıc nöqtəsi və
## atıcının rəngi isə yalnız atıcını GÖRƏNƏ gedir: atıcı baxanın mikrob siyahısındadır
## və atəş anında başqa kolda deyildi. Yoxsa başlanğıc əvəzinə düşmə nöqtəsi, rəng
## yerinə -1 gedir: kolda gizlənən və ya ekrandan kənardakı atıcının nə yeri, nə
## kimliyi paketdən oxunur (qəbul edənə lazım olmayan nöqtə ümumiyyətlə göndərilmir).
static func _lob_row(row: Array, seen: PackedInt32Array, eye_bush: int, peer: int) -> PackedFloat32Array:
	var owner: int = row[9]
	var bush: int = row[10]
	var open := owner == peer or (seen.has(owner) and (bush < 0 or bush == eye_bush))
	var tx: float = row[3]
	var ty: float = row[4]
	return PackedFloat32Array([row[1], row[2] if open else -1.0, tx, ty,
		row[5] if open else tx, row[6] if open else ty, row[7], row[8]])


## Baxanın gövdəsindən bu qədər piksel uzaqlığa qədər düşən damcı "təhlükəli" sayılır.
const LOB_WARN_PAD := 120.0
## Paket büdcəsinə görə göndərilməyən topların sayı (ölçü üçün, bax [method _near_shots]).
var shots_cut := 0


## Görüş sahəsindəki sətirləri süzür.
## Sıx ədəd axını kimi süzür — sətrin BİRİNCİ elementi mövqe, qalanı ədədlərdir.
##
## Hədd aşılanda ƏN YAXINLAR seçilir, ilk gələnlər yox — top və qida ilə eyni
## qayda ([method _near_shots], [method _near_food]).
##
## Əvvəl sadəcə `break` idi və sıra `sim.events`-in doğulma sırası idi: bir
## tick-də neçə hadisə varsa, ilk üçü keçirdi. Büdcə sıxılanda `event_n`
## cəmi 3 ola bilir (bax [method snapshot_for]), yəni uzaqda partlayan üç
## mikrob OYUNÇUNUN ÖZ SUPERİNİ paketdən çıxarırdı — basırdın, doluluq
## sıfırlanırdı, amma ekranda heç nə olmurdu.
##
## BAXANIN ÖZ hadisələri ([param own_color]) məsafədən asılı olmayaraq
## öndədir. Öz topun 400-500 px uzaqda dəyir, baxanın yanında isə hər tick
## onlarla qida udulur: yalnız məsafəyə görə seçəndə dəymə hadisəsi paketdən
## düşürdü. Server dəyməni sayırdı, client isə heç vaxt eşitmirdi — proqnozun
## göstərdiyi zərbə "təsdiqsiz" qalırdı və proqnozsuz zərbə ümumiyyətlə
## görünmürdü. Öz hadisələri azdır (atəş, dəymə, udma), büdcəni yemir.
static func _near_flat(rows: Array, eye: Vector2, r2: float, limit: int,
		own_color := -1) -> PackedFloat32Array:
	var near: Array = []
	for row in rows:
		var d := eye.distance_squared_to(row[0])
		if d > r2:
			continue
		var kind := int(row[1])
		var own := own_color >= 0 and int(row[row.size() - 1]) == own_color
		if own_color >= 0 and kind == Const.EvKind.HIT \
				and Const.hit_victim(float(row[4])) == own_color:
			# Baxana DƏYƏN top hamıdan öndədir — atan başqası olsa belə.
			#
			# Əvvəl o, baxanın öz qida udmaları ilə eyni pillədə idi. Bir tick-də
			# üç qida yeyəndə (büdcənin alt həddi 3-dür) zərbə paketdən düşürdü:
			# server dəyməni sayırdı, client-in "sənə dəydi" proqnozu isə
			# təsdiqsiz qalırdı. Diaqnostikada məhz belə bir hal tutuldu.
			d = -3.0
		elif own and kind != Const.EvKind.ABSORB:
			d = -2.0
		elif own:
			d = -1.0
		elif kind == Const.EvKind.ABSORB:
			# Başqasının qida udması yalnız bəzəkdir: qidanın özü onsuz da siyahıdan
			# çıxır. Büdcə sıxılanda ilk o düşür, zərbə və partlama yox.
			d += r2
		near.append([d, row])

	if limit > 0 and near.size() > limit:
		near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
		near.resize(limit)

	var out := PackedFloat32Array()
	for e in near:
		var row: Array = e[1]
		for i in range(1, row.size()):
			out.push_back(float(row[i]))
	return out


## [param limit] 0-dan böyükdürsə, ən çox o qədər sətir qaytarılır.
static func _near(rows: Array, eye: Vector2, r2: float, limit := 0) -> Array:
	var out := []
	for row in rows:
		if eye.distance_squared_to(row[0]) <= r2:
			out.append(row[1])
			if limit > 0 and out.size() >= limit:
				break
	return out


## Qida üçün ayrıca süzgəc: nəticə sıx ədəd axınıdır (id, x, y, id, x, y ...).
##
## Say [constant Const.FOOD_SEND_MAX] ilə məhdudlaşır və ƏN YAXINLAR seçilir.
##
## Hədd olmasaydı, iri mikrobun görüş sahəsi (tutumla böyüyür) bütün qabı
## örtərdi və snapshot-a 110-dan çox qida düşərdi — ölçülüb, tək bu sahə
## 1292 bayt tuturdu, ENet-in MTU-su isə 1392-dir. Uzaqdakı qida onsuz da
## ekrandan kənardadır, yəni itən heç nə yoxdur.
static func _near_food(pos: PackedVector2Array, ids: PackedInt64Array, eye: Vector2,
		r2: float, limit: int) -> PackedFloat32Array:
	var cand := PackedInt32Array()
	var dist := PackedFloat64Array()
	for i in pos.size():
		var d := eye.distance_squared_to(pos[i])
		if d > r2:
			continue
		cand.append(i)
		dist.append(d)

	var pick := cand
	if cand.size() > limit:
		pick = _closest(cand, dist, limit)

	var out := PackedFloat32Array()
	for i in pick:
		var p := pos[i]
		out.push_back(float(ids[i]))
		out.push_back(p.x)
		out.push_back(p.y)
	return out


## Ən yaxın [param limit] namizəd — yaxından uzağa, [param cand]-dakı indekslər.
##
## Əvvəl `sort_custom` ilə sıralanırdı və snapshot-un ən ağır yeri o idi: hər
## müqayisə bir lambda çağırışıdır, oyunçu başına tick-də yüzlərlə. İndi
## məsafələr yerli `sort()` ilə sıralanır və cavab oradan oxunur.
##
## Nəticə köhnə yolla EYNİDİR. Məsafələr fərqlidirsə, sıra tək mənalıdır —
## hansı alqoritmlə sıralansa da. Bərabər məsafə isə sıranı alqoritmdən asılı
## edir (`sort_custom` sabit deyil), ona görə o halda köhnə sıralama eyni
## ardıcıllıqla, eyni müqayisə ilə işlədilir.
static func _closest(cand: PackedInt32Array, dist: PackedFloat64Array, limit: int) -> PackedInt32Array:
	var sorted := dist.duplicate()
	sorted.sort()
	var pick := PackedInt32Array()
	for k in range(1, limit + 1):
		if sorted[k] == sorted[k - 1]:
			var near: Array = []
			for j in cand.size():
				near.append([dist[j], cand[j]])
			near.sort_custom(func(x, y) -> bool: return x[0] < y[0])
			for j in limit:
				pick.append(near[j][1])
			return pick

	var at := {}
	var edge := sorted[limit - 1]
	for j in cand.size():
		if dist[j] <= edge:
			at[dist[j]] = cand[j]
	for j in limit:
		pick.append(at[sorted[j]])
	return pick


# ---------------------------------------------------------------- bağlantı

func token_of(peer: int) -> String:
	return str(tokens.get(peer, ""))


## Bağlantı kəsildi, amma mikrob dünyada qalır.
##
## Mikrob hərəkət etmir və atəş açmır, amma vurula bilir və metabolizmi
## işləyir. Bu qəsdəndir: bağlantını kəsmək qorunma üsuluna çevrilməməlidir.
##
## Şərt MİKROB yox, OYUNÇUDUR: CÜT-də dirilməni gözləyənin mikrobu
## `sim.germs`-də yoxdur. Əvvəl belə oyunçu "dayandırılmış" sayılmırdı və
## [Lobby] 20 saniyə boyu qopmuş peer-ə 30 Hz-lə snapshot göndərməyə
## çalışırdı — hər dəfə "unknown peer ID" xətası ilə.
func suspend_peer(peer: int) -> void:
	if not peers.has(peer):
		return
	suspended[peer] = true
	# Saxlanan giriş silinir, yoxsa mikrob son əmrlə hərəkət etməyə davam edərdi.
	_inputs.erase(peer)
	_forget_replay(peer)


## Oyunçu yeni peer id ilə geri qayıtdı — bütün açarları köçürürük.
func resume_peer(old_peer: int, new_peer: int) -> void:
	if old_peer == new_peer:
		suspended.erase(old_peer)
		return

	sim.rekey_germ(old_peer, new_peer)

	var idx := peers.find(old_peer)
	if idx >= 0:
		peers[idx] = new_peer

	# `teams` və `places` da peer-ə bağlıdır: köçürülməsəydi, qayıdan oyunçunun
	# snapshot-unda komandası -1 olardı və HUD yoldaşını düşmən kimi göstərərdi.
	# `_revive` də: dirilməni gözləyərkən qayıdan oyunçu YENİ id ilə dirilməlidir,
	# köhnə id ilə dirilən mikrob heç kimin olmazdı.
	for src in [tokens, _last_seq, teams, places, _revive, _respawn, _obj_pops, _round_wait]:
		if src.has(old_peer):
			src[new_peer] = src[old_peer]
			src.erase(old_peer)

	_inputs.erase(old_peer)
	suspended.erase(old_peer)
	_forget_replay(old_peer)
	# Nişan dəyişmir: eyni oyunçu, eyni sessiya.


func is_suspended(peer: int) -> bool:
	return suspended.has(peer)


## Oyunçunun matçda hələ YERİ varmı: mikrobu sağdır, və ya CÜT-də dirilməni
## gözləyir. İkinci hal üçün `sim.germs.has` KİFAYƏT DEYİL — ölü mikrob oradan
## çıxır, oyunçu isə matçdadır və yoldaşı onu diriltməlidir.
func holds(peer: int) -> bool:
	return sim.germs.has(peer) or _revive.has(peer) or _respawn.has(peer) 		or _round_wait.has(peer)


## Oyunçu dünyanı tərk edir (partladı, çıxdı və ya qayıtmadı).
func drop_peer(peer: int) -> void:
	peers.erase(peer)
	_inputs.erase(peer)
	_forget_replay(peer)
	_last_seq.erase(peer)
	tokens.erase(peer)
	suspended.erase(peer)
	sim.remove_germ(peer)
	# Dirilmə növbəsi də: yoxsa matçı tərk edən (və ya qayıtmayan) oyunçunun
	# mikrobu 15 s sonra dirilir və sahibsiz dünyada qalırdı.
	_revive.erase(peer)
	_respawn.erase(peer)
	_round_wait.erase(peer)


func is_empty() -> bool:
	return peers.is_empty()


# ---------------------------------------------------------------- gec gələn girişlər

func _forget_replay(peer: int) -> void:
	_late_q.erase(peer)
	_rep.erase(peer)
	_win.erase(peer)
	_seq_seen.erase(peer)
	_ring.erase(peer)
	_applied.erase(peer)


## Təxmin olunan slot-ları gec gələn girişlərlə yenidən hesablayır (bax [constant REPLAY_MAX]).
## [method tick]-də addımdan ƏVVƏL çağırılır: indiki tick artıq düzəldilmiş yerdən başlayır.
## Faza bu tick-in əvvəlində dəyişibsə (ÜÇLÜK raundu bitib, mikroblar yeni doğuş yerindədir),
## girişlər artıq bağlıdır və heç nə yenidən oynadılmır.
func _replay_late() -> void:
	if not replay_enabled or not inputs_open():
		return
	for peer in peers:
		var q: Array = _late_q.get(peer, [])
		var r := int(_rep.get(peer, 0))
		if q.is_empty() or r <= 0:
			continue
		var g: Sim.GermState = sim.germs.get(peer)
		var ring: Array = _ring.get(peer, [])
		var guess: Sim.PlayerInput = _applied.get(peer)
		var w := mini(r, REPLAY_MAX)
		if g == null or not g.alive or g.in_cyst() or guess == null or ring.size() < w + 1:
			continue
		var start: Array = ring[ring.size() - 1 - w]
		var c := _scratch_germ(peer, g, start)
		# Əvvəl təxmin yolu özü yoxlanılır: halqadakı hal təmiz hərəkətlə (sonuncu girişin
		# təkrarı) alınmırsa, mikroba başqa nə isə toxunub — yenidən oynatmaq onu silərdi.
		var clean := true
		for j in range(r - w + 1, r + 1):
			_scratch.step_movement({peer: guess}, Const.TICK_DELTA, false)
			var was: Vector2 = (ring[ring.size() - 1 - (r - j)] as Array)[0]
			if c.pos.distance_squared_to(was) > 0.25:
				clean = false
				break
		if not clean:
			continue
		c = _scratch_germ(peer, g, start)
		# Slot `j` client-in `a + j` girişidir (a — təkrarlanan girişin seq-i); hələ
		# gəlməyibsə ən yaxın əvvəlki (yəni yenə təxmin).
		var a := int(_last_seq.get(peer, 0))
		var qi := 0
		var use := guess
		for j in range(r - w + 1, r + 1):
			while qi < q.size() and int((q[qi] as Sim.PlayerInput).seq) <= a + j:
				use = q[qi]
				qi += 1
			_scratch.step_movement({peer: use}, Const.TICK_DELTA, false)
			# Halqa da düzəlir: növbəti yenidən oynatma buradan başlamalıdır.
			ring[ring.size() - 1 - (r - j)] = [c.pos, c.vel, c.aim]
		g.pos = c.pos
		g.vel = c.vel


## Yenidən hesablama üçün tək mikroblu boş dünya — [param start] halından.
##
## Mikrob `Sim.add_germ` ilə YOX, birbaşa qurulur: o, hər çağırışda `find_spawn` ilə
## doğuş yeri axtarır (maneələr arasında təsadüfi sınaqlar) — yenidən oynatmada iki dəfə,
## hər tick. Yer onsuz da [param start]-dan gəlir.
func _scratch_germ(peer: int, g: Sim.GermState, start: Array) -> Sim.GermState:
	if _scratch == null:
		_scratch = Sim.new()
		# Şüşə və maneələr rejimindir — yenidən oynatma eyni həndəsədə getməlidir.
		_scratch.set_mode(int(mode))
	_scratch.germs.clear()
	_scratch.broken = sim.broken
	_scratch.dish_radius = sim.dish_radius
	_scratch.wet_center = sim.wet_center
	var c := Sim.GermState.new()
	c.id = peer
	c.species = g.species
	c.capacity = g.capacity
	c.balls = g.balls
	c.team = g.team
	_scratch.germs[peer] = c
	# Atəş yenidən hesablanmır: o, indiki tick-dədir.
	c.cooldown = 1.0e9
	c.pos = start[0]
	c.vel = start[1]
	c.aim = start[2]
	return c


## Tick-dən SONRA: halı halqaya yazır və təxmin sayğacını yeniləyir.
func _record_replay_state() -> void:
	var open := inputs_open()
	for peer in peers:
		var g: Sim.GermState = sim.germs.get(peer)
		if g == null or suspended.has(peer):
			_forget_replay(peer)
			continue
		var q: Array = _late_q.get(peer, [])
		var r := int(_rep.get(peer, 0))
		var seq := int(_last_seq.get(peer, 0))
		var rep := 0
		if not open:
			# Geri sayım, matçın sonu: girişlər qəbul olunmur, deməli təxmin də yoxdur.
			# Əvvəl ÜÇLÜK-ün 3 s-lik sayımı 90 "təxmin" kimi yığılırdı və ankor client-i
			# köhnə raundun yerinə çəkirdi (yoxlamada tapılıb).
			rep = 0
		elif q.is_empty():
			# Yeni giriş yox — server sonuncunu təkrarladı (və ya heç giriş yoxdur).
			rep = r + 1 if _inputs.has(peer) else 0
		else:
			# Yeni girişlər r + 1 slot-un neçəsini doldurdu — SEQ irəliləyişi ilə: itən
			# (və ya köhnə sayılıb atılan) paket də öz slot-unu tutur.
			var seen := int(_seq_seen.get(peer, seq - q.size()))
			rep = r + 1 - clampi(seq - seen, 0, r + 1)
		_rep[peer] = _settle_debt(peer, rep, q.size(), open)
		_seq_seen[peer] = seq
		q.clear()
		var cur: Sim.PlayerInput = _inputs.get(peer)
		if cur != null:
			_applied[peer] = Sim.PlayerInput.make(cur.seq, cur.move, cur.aim, false)
		var ring: Array = _ring.get(peer, [])
		ring.append([g.pos, g.vel, g.aim])
		while ring.size() > REPLAY_MAX + 1:
			ring.pop_front()
		_ring[peer] = ring


## Daimi borcu silir (bax [constant DEBT_WINDOW]): girişlər pəncərə boyu axıbsa və təxmin
## sayı heç sıfıra enməyibsə, o ən kiçik qalıq heç vaxt gəlməyəcək slot-lardır.
##
## Donmada girişlər GƏLMİR — pəncərə "axın" sayılmır və borc toxunulmaz qalır. Donma
## açılanda dəstə borcu özü ödəyir və pəncərənin minimumu 0 olur.
func _settle_debt(peer: int, rep: int, inputs: int, open: bool) -> int:
	if not open:
		_win.erase(peer)
		return rep
	var w: Array = _win.get(peer, [0, 0, rep])
	w[0] = int(w[0]) + 1
	w[1] = int(w[1]) + inputs
	w[2] = mini(int(w[2]), rep)
	if int(w[0]) >= DEBT_WINDOW:
		if int(w[1]) >= DEBT_WINDOW - DEBT_SLACK and int(w[2]) > 0:
			rep -= int(w[2])
		w = [0, 0, rep]
	_win[peer] = w
	return rep


## Snapshot-un SELF sətri: `[ack, soyuma, təxmin sayı]`, təxmin varsa + `[ankor x, y, vx, vy]`.
##
## TƏXMİN SAYI — server sonuncu girişi neçə tick təkrarlayıb (client o qədər girişi
## yenidən oynatmır — bax [method Arena._reconcile]). ANKOR — mikrobun təsdiqlənən girişin
## öz slot-undan sonrakı halı, təxminlərdən ƏVVƏL: server təxmin etdiyi tick-ləri gec gələn
## girişlərlə yenidən hesablayacaq ([method _replay_late]), ona görə client ankordan BÜTÜN
## gözləyən girişləri oynadır və serverin son yeri ilə üst-üstə düşür. Köhnə client yalnız
## ilk iki sahəni oxuyur.
func _self_row(peer: int, g: Sim.GermState) -> Array:
	var r := int(_rep.get(peer, 0))
	var row := [int(_last_seq.get(peer, 0)), g.cooldown if g != null else 0.0, r]
	if g == null or not replay_enabled:
		return row
	var ring: Array = _ring.get(peer, [])
	if r > 0 and ring.size() > r:
		var st: Array = ring[ring.size() - 1 - r]
		var at: Vector2 = st[0]
		var v: Vector2 = st[1]
		row.append_array([at.x, at.y, v.x, v.y])
	return row
