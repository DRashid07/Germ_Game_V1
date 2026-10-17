class_name MenuV2
extends Control
## Baş menyu — yatay.
##
## Şəbəkə axını buradan başlayır və qısadır — io tipli oyunda növbə yoxdur:
##   düymə → serverə qoşul → dünyaya gir → arena
##
## "MƏŞQ" düyməsi şəbəkəyə heç toxunmur: eyni [World] və [Sim] kodu yerli işə
## düşür, botlarla. Server yatmış olsa da oyun oynanır.
##
## ── Düzülüş niyə belədir ─────────────────────────────────────────────────
##
## Köhnə menyu ([MainMenu]) şaquli FORMA idi: loqo, iki mətn qutusu, düymələr
## sütunu. Forma məlumat toplayır, oyun menyusu isə OYUNU SATIR — ikisi ayrı
## işdir. Düzülüş Brawl Stars-ın BUGÜNKÜ (2026) ana ekranından götürülüb —
## araşdırma və zonaların cədvəli `design/ART_BIBLE.md` § 6b-dədir:
##
##   yuxarı-sol   profil (avatar + ad)          yuxarı-sağ   valyutalar + AYARLAR
##   sol lent     MAĞAZA, MİKROBLAR, MƏŞQ       mərkəz       qəhrəman podiumda, adı üstündə
##   aşağı-sol    [ MİKRO PASS ][ TAPŞIRIQLAR ] aşağı-sağ    [ rejim kartı ][ OYNA ]
##
## Dil də oradandır: qalın qara kontur, altda tünd "dodaq", konturlu ağ yazı
## (bax [ChunkyBox]). Qəhrəmana toxunmaq, çəkib dartmaq olur — Brawl Stars-ın
## 2026 lobbisindəki Loony kimi: heç bir iş görmür, ekranın canlı olduğunu
## barmaqla sübut edir.
##
## **1. Mikrob səhnənin ortasındadır — QƏHRƏMAN kimi.** Brawl Stars ana
## ekranda brawler-i oyundakı kiçik fiqur kimi yox, iri, işıqlı modeli ilə
## göstərir: fiqur ekranın sahibidir. Bizdə də ana ekranda hər növün öz
## illüstrasiyası var (bax `design/menu_art/`), podiumun üstündə durur və
## nəfəs alır. Əvvəl burada oyunun öz [GermVisual]-ı 4.2× böyüdülürdü —
## oyunla eyni idi, amma boş qara fonda kiçik bir ləkə kimi oxunurdu.
##
## Oyundakı görünüş itmir: növün səhifəsindəki «OYUNDA» pəncərəsi canlı
## [GermVisual]-dır, yəni oyunçu seçərkən nəyi oynayacağını dəqiq görür.
##
## **2. Növ seçimi KARTLARLA.** Köhnədə bir düymə növləri növbə ilə keçirdi:
## üç növü görmək üçün üç dəfə basmaq lazım idi. İndi üçü də yan-yanadır və
## hər kartda növün silueti var — seçim BİR toxunuşdur, fərq isə basmadan
## oxunur.
##
## **3. OYNA sağ aşağıdadır, SARIDIR və ekranın ən böyük obyektidir.** Yatay
## tutulan telefonda sağ baş barmaq məhz oraya çatır. Rejim kartı onun
## SOLUNDADIR — Brawl Stars-da olduğu kimi «nə oynayıram» və «başla» bir
## baxışda oxunur. Ekranda başqa sarı ləkə yoxdur.
##
## **4. Yuxarı zolaq yalnız OXUNUR.** Ad, valyutalar, ayarlar. Vacib heç
## bir toxunuş yuxarıda deyil, çünki yatayda barmaq ora çatmır. Server
## vəziyyəti ekranda YOXDUR — texniki daxili vəziyyətdir (bax [method _probe_server]).
##
## **5. AYARLAR yalnız buradadır.** Matçın içində dişli yoxdur (Brawl Stars
## kimi) — səs və qrafika döyüşdən ƏVVƏL qurulur. Server ünvanı da ayarların
## içindədir: oyunçunun 99%-i ona heç vaxt toxunmur.
##
## **6. Mağaza, valyuta, MİKRO PASS və tapşırıqlar GÖRÜNÜŞ ÜÇÜNDÜR.** Brawl
## Stars-da ekranın yarısı iqtisadiyyatdır və ana ekran onsuz yarımçıq
## görünür — düymələr Brawl Stars-dakı yerlərindədir. Arxalarında isə hələ
## sistem YOXDUR: valyutalar 0-dır, pass zolağı boşdur. Basılıb heç nə olmayan
## düymə etibarı aparır, ona görə hər biri "TEZLİKLƏ!" cavabı verir (bax
## [method _coming_soon]) — oyunçu aldadılmır. Sistemlər gələndə qəhrəman və
## OYNA yerini dəyişməyəcək.

## Arena səhnəsi — TİPSİZ yüklənir (`var arena = load(...)`).
##
## `var arena: Arena` yazılanda arena, [GermVisual], [Sim], [World] və qalan
## oyun kodu menyunun özü ilə birlikdə kompilyasiya olunurdu — oyunçu OYNA-ya
## basmamışdan, menyu açılarkən. Brauzerdə bu, açılış donmasının bir hissəsi idi.
const ARENA_SCENE := "res://scenes/game/arena.tscn"

## Kənar boşluq. Yatayda kənarlar barmağın altında qalır, ona görə heç bir
## düymə ekranın lap kənarına yapışmır.
const PAD := 30.0
## OYNA — sağ-aşağı küncdə, ekranın lövbəri (1280×720 bazasında ölçülüb).
const BTN_W := 290.0
const PLAY_H := 112.0
## Rejim kartı — OYNA-nın SOLUNDA, eyni hündürlükdə (Brawl Stars düzümü).
const MODE_W := 330.0
const MODE_GAP := 16.0
## Qəhrəmanın başının üstündəki ad lövhəsi.
const PLATE := Vector2(300.0, 64.0)
## Dəvət kartı açılanda/bağlananda ad lövhəsi bu qədər saniyədə sönür/görünür.
const PLATE_FADE := 0.15
## Sol lentin düyməsi (Brawl Stars-da Shop/Brawlers).
const RAIL := Vector2(112.0, 112.0)
const RAIL_GAP := 18.0
## Yuxarı zolağın hündürlüyü: profil, valyutalar, dişli.
const BAR_H := 64.0
## Valyuta zolağı (yuxarı-sağ) və aşağı-soldakı MİKRO PASS kartı.
const CURRENCY := Vector2(150.0, 44.0)
const PASS_W := 250.0
## MİKROBLAR kolleksiyasının portret kartı və rejim sətri.
const CARD_BIG := Vector2(280.0, 400.0)
## Kartın konturu və dodağı — portret bu qədər içəridən başlayır, yəni
## şəklin nisbəti də bundan çıxır (bax [constant CARD_ASPECT]).
const CARD_OUTLINE := 3.0
const CARD_LIP := 7.0
## Portretin eni : hündürlüyü = (280 − 6) : (400 − 6 − 7). Kart şəkilləri
## emalda MƏHZ bu nisbətə kəsilir (bax `design/menu_art/README.md`).
const CARD_ASPECT := 274.0 / 387.0
## Növ səhifəsindəki göstərici zolaqları.
const STAT_ROWS := 4
const STAT_BAR_W := 300.0
## Səhifədəki "OYUNDA" pəncərəsinin mikrobu — qəhrəman illüstrasiyaları ilə
## eyni rəng (laym), ona görə şəkil ilə oyun görünüşü yan-yana tutuşdurula bilir.
const MENU_GERM_COLOR := 0
const GRID_GAP := 30.0
const ROW_W := 700.0
const ROW_H := 104.0
const ROW_GAP := 14.0
## Rejimlərin rəngi — [constant Palette.GERM_COLORS] indeksləri. Rejim kartı
## bu rənglə dolur (Brawl Stars-da hər rejimin öz rəngi var: Gem Grab
## bənövşəyi, Showdown yaşıl) və ikonlar da məhz bu rənglərlə çəkilib.
const MODE_TINT := [1, 3, 7, 4]
const CARD := Vector2(176.0, 96.0)

## Vərəqdəki canlı mikrobların tutumu: içindəki topların sayı bundan asılıdır.
const GERM_CAPACITY := 14
const GERM_BALLS := 8

## Ana ekranın illüstrasiyaları. Codex ilə çəkilib; xam fayllar və promptlar
## `design/menu_art/`-dadır — növ əlavə olunanda eyni dildə yenisi çəkilir.
const BG_TEX := "res://assets/menu/menu_bg.jpg"
const PODIUM_TEX := "res://assets/menu/menu_podium.png"
const _HEROES := {
	Const.Species.CILIATE: "res://assets/menu/hero_ciliate.png",
	Const.Species.HELIOZOAN: "res://assets/menu/hero_heliozoan.png",
	Const.Species.AMOEBA: "res://assets/menu/hero_amoeba.png",
}
## Ana ekranın ikonları — Brawl Stars-ın qalın konturlu glif dili, Codex ilə.
const ICON_BRAWLERS := "res://assets/menu/icon_brawlers.png"
const ICON_PRACTICE := "res://assets/menu/icon_practice.png"
const ICON_SETTINGS := "res://assets/menu/icon_settings.png"
## Brawl Stars-ın iqtisadiyyat yuvaları — GÖRÜNÜŞ ÜÇÜN (bax [method _coming_soon]).
const ICON_SHOP := "res://assets/menu/icon_shop.png"
const ICON_PASS := "res://assets/menu/icon_pass.png"
const ICON_QUESTS := "res://assets/menu/icon_quests.png"
const ICON_FOOD := "res://assets/menu/currency_food.png"
const ICON_DNA := "res://assets/menu/currency_dna.png"
## MİKROBLAR kolleksiyası — portret kartlar, sinif və super ikonları (Codex).
const _CARD_ART := {
	Const.Species.CILIATE: "res://assets/menu/card_ciliate.png",
	Const.Species.HELIOZOAN: "res://assets/menu/card_heliozoan.png",
	Const.Species.AMOEBA: "res://assets/menu/card_amoeba.png",
}
const _SUPER_ICONS := {
	Const.Species.CILIATE: "res://assets/menu/super_trichocyst.png",
	Const.Species.HELIOZOAN: "res://assets/menu/super_net.png",
	Const.Species.AMOEBA: "res://assets/menu/super_cyst.png",
}
## DOSTLAR — Brawl Stars-ın sağ lentindəki "Friends" düyməsi və komanda dili.
const ICON_FRIENDS := "res://assets/menu/icon_friends.png"
const ICON_CROWN := "res://assets/menu/icon_crown.png"
const ICON_INVITE := "res://assets/menu/icon_invite.png"
## Yoldaşın qəhrəmanı — öz qəhrəmanının yarısı. Brawl Stars-da da yoldaşlar
## kiçik və bir az arxada durur: ekranın sahibi yenə SƏNİN fiqurundur.
## 0.62 sınandı: amöb (ən enli növ) yanındakı amöbə dəyirdi, sağdakı isə
## DOSTLAR düyməsinə çatırdı.
const MATE_SCALE := 0.50
## Yoldaşla qəhrəman arasındakı boşluq (piksel, 1280×720 bazasında).
const MATE_GAP := 14.0
## «+» yuvasının kvadratı.
const SLOT := 96.0

const _MODE_ICONS := {
	Const.Mode.ENDLESS: "res://assets/menu/mode_endless.png",
	Const.Mode.SOLO: "res://assets/menu/mode_solo.png",
	Const.Mode.DUO: "res://assets/menu/mode_duo.png",
	Const.Mode.TRIO: "res://assets/menu/mode_trio.png",
}

## Qəhrəmanın sığdığı qutu — ekran HÜNDÜRLÜYÜNƏ nisbətdə. Hündürlük, çünki
## yatayda en telefondan telefona dəyişir (16:9 → 20:9), düzümü isə yuxarı
## zolaqla OYNA arasındakı hündürlük müəyyən edir. En hündürlükdən çoxdur:
## kirpiklinin quyruğu və ayaqlının ayaqları yana açılır.
const HERO_BOX := Vector2(0.70, 0.45)
## Podiumun eni (hündürlüyə nisbətdə) və üst üzünün mərkəzi — şəklin içində,
## yuxarıdan 0..1. Qəhrəman məhz o nöqtədə dayanır; şəkil dəyişsə, bu rəqəm
## də yenidən ölçülməlidir.
const PODIUM_W := 0.80
const PODIUM_TOP := 0.39

## Boşda nəfəs: eni və hündürlüyü ƏKS fazada dəyişir — həcm saxlanılır,
## ona görə jele kimi oxunur, şişən şar kimi yox. 2.6 s dövr sakit insan
## nəfəsinə yaxındır; daha tez olanda mikrob "həyəcanlı" görünürdü.
const BREATH := 0.028
const BREATH_T := 2.6
## Suda asılı qalma: yüngül qalxıb-enmə. Kölgə də onunla kiçilir — yuxarı
## qalxdığı kölgədən oxunur, podium yerində qalır.
const HOVER := 0.011
const HOVER_T := 3.4
## Yellənmə (radian). ±2°-dən çoxu "başı gicəllənir" hissi verirdi.
const SWAY := 0.035

## Toxunanda jele titrəyişi — sönən yay. k=190, d=9: təxminən 2 Hz, iki-üç
## yellənmədə sönür. Brawl Stars-da da lobbidə fiqura toxunmaq onu oynadır:
## heç bir iş görmür, amma ekranın CANLI olduğunu barmaqla sübut edir.
const JELLY_K := 190.0
const JELLY_D := 9.0
const JELLY_KICK := 2.4
## Barmaqla dartma — Brawl Stars 2026 lobbisindəki Loony kimi qəhrəmanı
## çəkmək, sıxmaq olur. Yuxarı çəkəndə uzanır, aşağı basanda yastılaşır, yana
## çəkəndə əyilir; buraxanda yay onu titrədərək yerinə qaytarır.
##
## Hədlər: 0.30 dartılma və 0.35 rad (20°) əyilmə. Daha çoxunda şəklin
## kirpikləri və ayaqları rastr kimi "sınır" — illüstrasiya elastik deyil.
const PULL_MAX := 0.30
const LEAN_MAX := 0.35
## Barmaq bu qədərdən az gedibsə (piksel), bu dartma yox, TOXUNUŞDUR.
const TAP_SLOP := 10.0

## Giriş animasiyasının uzunluğu. 0.6 saniyə: görünəcək qədər uzun, gözləməyə
## məcbur etməyəcək qədər qısa. OYNA sonuncu düşür — göz ora yönəlsin deyə.
const INTRO_TIME := 0.6

## Serverin cavabını nə qədər gözləyirik (bax [method _probe_server] və
## [method _arm_join_timeout]).
const PROBE_TIMEOUT := 8.0
const JOIN_TIMEOUT := 12.0

var _hero: Sprite2D
var _bg: Texture2D
var _podium: Texture2D
var _motes: WaterMotes
## Qəhrəmanın boş animasiyasının saatı.
var _clock := 0.0
## Jele yayının yerdəyişməsi və sürəti (bax [constant JELLY_K]).
var _jelly := 0.0
var _jelly_v := 0.0
## Əyilmə yayı — dartmanın yana hissəsi (bax [constant LEAN_MAX]).
var _lean := 0.0
var _lean_v := 0.0
## Barmaq qəhrəmanı tutubmu, harada tutub.
var _grab := false
var _grab_from := Vector2.ZERO
## 0 → 1. Qəhrəman bununla "doğulur" — girişdə və növ dəyişəndə.
var _hero_in := 0.0
var _hero_tween: Tween
## 0 → 1. Podium bununla açılır (bax [method _draw]).
var _intro := 0.0

var _nick: LineEdit
## Profildəki avatar — seçilmiş növün qəhrəman şəkli.
var _avatar: TextureRect
## Serverlə bağlantının DAXİLİ vəziyyəti ("ONLAYN", "yoxlanılır" ...).
## Ekranda göstərilmir — yalnız QA agenti və diaqnostika oxuyur (bax
## [method _set_status]).
var _net_state := ""
## "TEZLİKLƏ" bildirişi — sistemsiz düymələrin cavabı (bax [method _coming_soon]).
var _toast: VBoxContainer
var _toast_tween: Tween
var _play: Button
var _mode_card: Button
var _mode_icon: TextureRect
var _mode_name: Label
var _mode_note: Label
## Açıq AYARLAR ekranı — bağlı olanda `null` (bax [method _open_settings]).
var _settings: SettingsView
var _cards: Array[Button] = []
## Kartın yenilənən hissələri: ad, super, "SEÇİLİB" etiketi, sinif.
var _card_parts: Array[Dictionary] = []
## Kolleksiya (kartlar) və növ səhifəsi — eyni vərəqdə, növbə ilə görünür.
var _species_grid: Control
var _detail: Control
var _detail_kind := Const.Species.CILIATE
var _detail_frame: Button
var _detail_art: TextureRect
var _detail_live: PanelContainer
var _detail_name: Label
var _detail_badge_slot: Control
var _detail_note: Label
var _stat_rows: Array[Dictionary] = []
var _detail_super_icon: TextureRect
var _detail_super_name: Label
var _detail_super_note: Label
## Səhifənin SEÇ düyməsi — QA agenti ([PlayAgent]) növü məhz bununla seçir.
var _select_btn: Button
var _mode_rows: Array[Button] = []
## Mikrobun altındakı ad lövhəsi — kimlik obyektə bağlıdır, ayrı sütuna yox.
var _plate_name: Label
var _plate_super: Label
## Tam ekran vərəq: MİKROBLAR və REJİMLƏR eyni çərçivəni paylaşır.
var _sheet: Control
## Vərəqin uşaq sırasındakı yeri — o, ilk açılışda qurulur (bax [method _ensure_sheet]),
## amma sonradan əlavə olunan bildiriş və ayarlar ekranının ALTINDA qalmalıdır.
var _sheet_slot := -1
var _sheet_title: Label
var _sheet_species: Control
var _sheet_modes: Control

## ── DOSTLAR və KOMANDA (bax [Friends], [FriendsView]) ──
var _friends_btn: Button
var _friends_badge: Label
var _friends_view: FriendsView
## Qəhrəmanın iki yanındakı «+» yuvaları — Brawl Stars-ın komanda yuvaları.
var _slots: Array[Button] = []
## Yuvada yoldaş varsa: onun qəhrəmanı, ad lövhəsi və lider tacı.
var _mates: Array[Sprite2D] = []
var _mate_plates: Array[PanelContainer] = []
var _mate_crowns: Array[TextureRect] = []
## Öz ad lövhəmin üstündəki tac — komandanın lideriyəmsə.
var _my_crown: TextureRect
## Gələn dəvətin kartı (ekranın yuxarısında) və onun kimdən olduğu.
var _invite_card: PanelContainer
var _invite_tag := ""
var _invite_bar: Panel
## Ad lövhəsinin görünməsi, 0 → 1 (bax [method _fade_plate]).
var _plate_shown := 1.0

## Qoşulma gedirmi. OYNA düyməsi bu vəziyyəti ÖZÜ göstərir — ayrıca status
## sətri və "LƏĞV ET" düyməsi yoxdur (köhnə menyuda hər ikisi vardı və menyunu
## bir düymə boyu uzadırdı).
var _joining := false
## Yoxlama növbəsinin nömrəsi — köhnə vaxt həddi yenisini pozmasın deyə
## (ünvan dəyişəndə yoxlama yenidən başlayır).
var _probe_token := 0

const _ICONS := {
	Const.Species.CILIATE: "res://assets/ui/species_ciliate.svg",
	Const.Species.HELIOZOAN: "res://assets/ui/species_heliozoan.svg",
	Const.Species.AMOEBA: "res://assets/ui/species_amoeba.svg",
}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_background()
	# Diskdəki ayarlar BU ANDA artıq oxunub: [Settings] autoload-dur və oyunun
	# ilk kadrında işə düşür. Yəni menyu qurulanda ad, növ, rejim və keyfiyyət
	# hazır dəyərlərdir — əvvəlki kimi "əvvəl sahəni qur, sonra faylı oxu"
	# ardıcıllığına ehtiyac yoxdur.
	_build_top_bar()
	_build_hero()
	_build_home()
	# Növ və rejim vərəqi burada QURULMUR — ilk açılışda qurulur
	# ([method _ensure_sheet]). Açılışda görünmür, qurulması isə menyunun ən
	# bahalı hissəsi idi: üç böyük kart şəkli və növ səhifəsi. Ölçülüb: brauzerdə,
	# 4× yavaş CPU-da menyunun açılışına ~350 ms əlavə edirdi.
	_sheet_slot = get_child_count()
	_refresh_species()
	_refresh_mode()
	_apply_quality()

	# Ayarlar ekranı keyfiyyəti dəyişə bilər — menyunun öz fonu da dərhal
	# cavab verməlidir, yoxsa oyunçu düyməni basır və ekranda heç nə olmur.
	Settings.changed.connect(_on_settings_changed)
	Net.connected_to_server.connect(_on_connected)
	Net.connection_failed.connect(_on_connect_failed)
	Net.server_disconnected.connect(_on_disconnected)
	Net.world_joined.connect(_on_world_joined)
	Net.join_rejected.connect(_on_join_rejected)

	_build_social()
	Friends.changed.connect(_refresh_party)
	Friends.notice.connect(_on_friends_notice)
	Friends.invite_arrived.connect(_show_invite)
	_refresh_party()

	_probe_server()
	_play_intro()

	# Matçdan qayıdanda cavabsız dəvət varsa, kart yenidən göstərilir.
	if not Friends.invites.is_empty():
		_show_invite(Friends.invites.keys()[-1])
	# Veb versiya dost linki ilə açılıb — DOSTLAR ekranı o kodla açılır.
	var link := Friends.take_friend_link()
	if not link.is_empty():
		_open_friends.call_deferred(false, link)


func _process(delta: float) -> void:
	_clock += delta
	# Jele yayları. Yarım-açıq Euler kifayətdir: sərtlik kiçikdir və kadr 60
	# Hz-də sabitdir; `delta` sıçrasa belə sürət əvvəl yenilənir, partlamır.
	#
	# Barmaq qəhrəmanı TUTANDA yay işləmir — forma barmağın ardınca gedir
	# (bax [method _gui_input]); buraxanda yay oradan davam edir və məhz o anda
	# titrəyiş yaranır.
	var dt := minf(delta, 0.05)
	if not _grab:
		_jelly_v += (-JELLY_K * _jelly - JELLY_D * _jelly_v) * dt
		_jelly += _jelly_v * dt
		_lean_v += (-JELLY_K * _lean - JELLY_D * _lean_v) * dt
		_lean += _lean_v * dt
	_pose_hero()

	# Ad lövhəsi qəhrəmanın BAŞININ ÜSTÜNDƏDİR — Brawl Stars-da brawler-in
	# adı və kuboku da fiqurun üstündə durur. Qəhrəmanın hündürlüyü növdən
	# asılıdır, ona görə yeri hər kadr yenilənir; yuxarı zolağa isə girmir.
	var plate := get_node_or_null("Plate") as Control
	if plate != null:
		var foot := _foot()
		# Lövhənin HƏQİQİ ölçüsü götürülür, PLATE yox: PanelContainer yazıya
		# sığmaq üçün minimumdan böyüyə bilir və mərkəz sürüşərdi.
		var top := foot.y - _hero_size().y * 0.97 - plate.size.y - 6.0
		plate.position = Vector2(foot.x - plate.size.x * 0.5, maxf(top, 22.0))

	_pose_mates()
	_tick_invite()
	_fade_plate(delta)

	if _motes != null:
		# Zərrəciklər podiumun ətrafında toplanır: fon şəklindəki su hərəkətsizdir,
		# onu canlı edən məhz bu cizgilərdir.
		_motes.focus = _foot()
		_motes.span = maxf(size.x, size.y) * 0.9
	queue_redraw()


## Qəhrəmanın AYAQ nöqtəsi — podiumun üst üzünün mərkəzi.
##
## Brawl Stars-da fiqur ekranın ortasındadır və bütün idarələr onun
## ÇEVRƏSİNDƏ halqa qurur: yuxarı-sol kimlik, yuxarı-sağ sistem,
## aşağı-mərkəz PLAY, aşağı-sağ rejim, yan lentlər bölmələr.
##
## 0.61: başın üstündəki ad lövhəsi yuxarı zolağa dəyməsin, podiumun ön üzü
## isə aşağı-sağdakı rejim kartına girməsin. Mərkəz nöqtəsi yox, AYAQ
## seçilib, çünki fiqur yerə basmalıdır — hündürlüyü növdən növə dəyişir,
## ayağı dəyişmir.
func _foot() -> Vector2:
	return Vector2(size.x * 0.5, size.y * 0.61)


func _podium_size() -> Vector2:
	if _podium == null:
		return Vector2.ZERO
	var w := size.y * PODIUM_W
	return Vector2(w, w * float(_podium.get_height()) / float(_podium.get_width()))


# ---------------------------------------------------------------- fon

func _build_background() -> void:
	# Fon və səhnə bu node-un ÖZ `_draw`-ında çəkilir, ayrıca `ColorRect` ilə
	# yox: `ColorRect` uşaqdır və uşaqlar valideynin çəkilişindən SONRA gəlir,
	# yəni zərrəcikləri örtürdü. Öz `_draw` isə hər şeydən əvvəldir.
	_motes = WaterMotes.new()
	add_child(_motes)

	# Bioluminessensiya — oyundakı ilə eyni ayar (bax [method Arena._build_glow]).
	# Menyu ilə oyun arasında görüntü kəsiyi olmamalıdır: eyni mikrob, eyni işıq.
	#
	# Keyfiyyət ayarı da EYNİ olmalıdır və bu, sonradan düzəldilib: arena
	# `Net.quality`-ni oxuyurdu, menyu isə yox — nəticədə "QRAFİKA: AŞAĞI"
	# düyməsi elə öz ekranında heç nə dəyişmirdi. Oyunçu basır, ekran eyni
	# qalır, deməli düymə ölü sayılır. Üstəlik ən bahalı ekran (bloom-lu menyu)
	# zəif telefonda bahalı qalırdı.
	_apply_quality()
	if Const.is_light(int(Net.quality)):
		return

	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_hdr_threshold = 0.62
	env.glow_intensity = 1.15
	env.glow_strength = 1.20
	env.glow_bloom = 0.14
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## Fon, podium və qəhrəmanın kölgəsi.
##
## Brawl Stars brawler-i podiumun üstündə göstərir: fiqurun yerə oturduğu hiss
## olmasa, o, boşluqda asılı qalır. Podium petri qabının şüşə halqasıdır —
## oyunun dünyası ilə eyni dil: döşəmədəki iki məsafə halqası onun da üstündədir.
func _draw() -> void:
	# Şəkil yüklənməsə menyu QARA qalmır, köhnə düz fona düşür.
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BG_OUTER)
	if _bg != null:
		draw_texture_rect(_bg, _bg_rect(), false)
	# Vərəq açıqdırsa podium çəkilmir: vərəqin tündləşdirməsi fonu göstərir,
	# amma boş podium kartların arxasında "kimsə getdi" kimi oxunurdu.
	# Vərəq tənbəl qurulur (bax [method _ensure_sheet]) — `null` "bağlıdır"
	# deməkdir. Əvvəl şərt `_sheet == null`-da da çıxırdı və podium ilə
	# qəhrəmanın kölgəsi menyunun ilk açılışında ümumiyyətlə çəkilmirdi.
	if _podium == null or (_sheet != null and _sheet.visible):
		return

	var foot := _foot()
	var ps := _podium_size() * lerpf(0.86, 1.0, _intro)
	var top := foot - Vector2(ps.x * 0.5, ps.y * PODIUM_TOP)
	draw_texture_rect(_podium, Rect2(top, ps), false, Color(1, 1, 1, _intro))

	# Kontakt kölgəsi — İKİ qat ellips (bax `design/BRAWL_UPGRADE.md` § 2.3):
	# geniş-sönük və dar-tünd birlikdə yumşaq kənar verir, şeyder istəmir.
	# Qəhrəman qalxanda kölgə kiçilir və solur — suda asılı qalma məhz
	# bundan oxunur, çünki fiqurun özünün qalxması cəmi bir neçə pikseldir.
	if _hero == null or _hero.texture == null:
		return
	# Yoldaşların kölgəsi — qəhrəmanınkı ilə eyni iki qat, kiçik.
	for i in _mates.size():
		if _mates[i].visible:
			var mr := _mate_size(i).x * 0.28
			draw_set_transform(_mate_foot(i) - Palette.LIGHT_DIR * mr * 0.12, 0.0, Vector2(1.0, 0.30))
			draw_circle(Vector2.ZERO, mr * 1.2, Color(Palette.OUTLINE, 0.18))
			draw_circle(Vector2.ZERO, mr * 0.8, Color(Palette.OUTLINE, 0.38))
			draw_set_transform(Vector2.ZERO)

	var lift := _lift() / maxf(HOVER, 0.001)
	var r := _hero_size().x * 0.30 * (1.0 - 0.16 * lift) * _hero_in
	var a := (1.0 - 0.35 * lift) * clampf(_hero_in, 0.0, 1.0)
	draw_set_transform(foot - Palette.LIGHT_DIR * r * 0.12, 0.0, Vector2(1.0, 0.30))
	draw_circle(Vector2.ZERO, r * 1.2, Color(Palette.OUTLINE, 0.20 * a))
	draw_circle(Vector2.ZERO, r * 0.8, Color(Palette.OUTLINE, 0.42 * a))
	draw_set_transform(Vector2.ZERO)


## Fon şəklinin ekrandakı yeri — "cover": ekranı TAM örtür, artığı kəsilir.
##
## Şəkil 16:9-dur, telefonlar isə 16:9-dan 20:9-a qədərdir, yəni geniş
## ekranda yuxarı və aşağıdan kəsilir. Codex-ə məhz ona görə "yuxarı və
## aşağı 12%-də vacib heç nə olmasın" deyilib.
##
## 4% artıq böyüdülür və çox yavaş sürüşür (40 s-lik dövr): podium yerində
## qalır, fon isə arxada hərəkət edir — bu, parallaksdır və gözə DƏRİNLİK
## kimi oxunur. Sürüşmə artıq payı keçmir, ona görə kənar heç vaxt açılmır.
func _bg_rect() -> Rect2:
	var ts := _bg.get_size()
	var s := ts * maxf(size.x / ts.x, size.y / ts.y) * 1.04
	var drift := Vector2(sin(_clock * TAU / 40.0), sin(_clock * TAU / 27.0) * 0.5)
	return Rect2((size - s) * 0.5 + drift * (s - size) * 0.5, s)


func _build_hero() -> void:
	_bg = load(BG_TEX) as Texture2D
	_podium = load(PODIUM_TEX) as Texture2D

	# Sprite2D, TextureRect yox: fırlanma və əzilmə AYAQ nöqtəsindən olmalıdır
	# (bax `offset`), Control-un pivotu isə hər ölçü dəyişəndə yenidən
	# hesablanmalı olardı.
	#
	# Ağacda panellərdən ƏVVƏL əlavə olunur, yəni onların altında qalır:
	# menyuda qəhrəman eksponatdır, idarə deyil. Köhnə [GermVisual] özünə
	# `z_index = 2` yazırdı və ayaqları ad lövhəsinin yazısını örtürdü.
	_hero = Sprite2D.new()
	_hero.centered = false
	# Şəkil ekranda 2–3 dəfə kiçildilir; mipmap-sız kiçiltmə kirpiklərin və
	# ayaqların nazik xətlərini titrədir.
	_hero.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(_hero)
	_set_hero_texture()


## Seçilmiş növün şəklini qoyur və ayaq nöqtəsini ona görə yenidən hesablayır.
func _set_hero_texture() -> void:
	var tex := load(_HEROES.get(Net.species, _HEROES[Const.Species.CILIATE])) as Texture2D
	_hero.texture = tex
	if tex == null:
		return
	# Mənşə şəklin ALT-MƏRKƏZİDİR: nəfəs və jele əzilməsi yerdən yuxarı
	# gedir, fiqur podiumdan qopmur. 0.97 — emalda qalan 2%-lik şəffaf
	# haşiyə; onsuz fiqur podiumun üstündə bir az asılı qalırdı.
	_hero.offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() * 0.97)


## Qəhrəmanın miqyası: [constant HERO_BOX] qutusuna sığır, nisbəti saxlanılır.
func _hero_scale() -> float:
	if _hero == null or _hero.texture == null:
		return 1.0
	var ts := _hero.texture.get_size()
	return minf(size.y * HERO_BOX.x / ts.x, size.y * HERO_BOX.y / ts.y)


func _hero_size() -> Vector2:
	if _hero == null or _hero.texture == null:
		return Vector2.ZERO
	return _hero.texture.get_size() * _hero_scale()


## İndiki qalxma — ekran hündürlüyünə nisbətdə, 0..[constant HOVER].
func _lift() -> float:
	return (0.5 + 0.5 * sin(_clock * TAU / HOVER_T)) * HOVER


## Boş animasiya: nəfəs + qalxma + yellənmə + toxunuşun jele yayı.
##
## Hamısı bir node-un transformudur — çəkiliş çağırışı artmır, ona görə AŞAĞI
## keyfiyyətdə də söndürülmür.
func _pose_hero() -> void:
	if _hero == null or _hero.texture == null:
		return
	var squash := sin(_clock * TAU / BREATH_T) * BREATH + _jelly
	_hero.scale = Vector2(1.0 + squash, 1.0 - squash) * _hero_scale() * _hero_in
	_hero.position = _foot() - Vector2(0.0, _lift() * size.y)
	_hero.rotation = sin(_clock * TAU / (HOVER_T * 1.7)) * SWAY + _lean
	_hero.modulate.a = clampf(_hero_in * 1.6, 0.0, 1.0)


## Qəhrəmana toxunmaq onu titrədir, çəkmək isə dartır (bax [constant PULL_MAX]).
##
## Menyunun ÖZ girişidir, ayrıca düymə yox: düymə olsaydı, QA agentinin
## düzüm yoxlaması onu ad lövhəsi ilə "üst-üstə düşən idarə" sayardı, halbuki
## burada heç bir əməl yoxdur — yalnız cavab.
##
## Basılan Control barmaq buraxılana qədər hərəkət hadisələrini almağa davam
## edir, barmaq qəhrəmandan çıxsa da — ona görə dartma ekranın hər yerində
## izlənir.
func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			if _hero == null or not _hero.visible:
				return
			var hs := _hero_size()
			if not Rect2(_foot() - Vector2(hs.x * 0.5, hs.y), hs).has_point(mb.position):
				return
			_grab = true
			_grab_from = mb.position
			accept_event()
		elif _grab:
			_grab = false
			# Az gedibsə — toxunuş: yay təpikləyir. Çox gedibsə — dartma idi:
			# yay elə dartılmış vəziyyətdən buraxılır və özü titrəyir.
			if mb.position.distance_to(_grab_from) < TAP_SLOP:
				_jelly_v += JELLY_KICK
			Sfx.play("absorb", 0.12)
			accept_event()
		return

	var mm := event as InputEventMouseMotion
	if mm != null and _grab:
		var d := (mm.position - _grab_from) / maxf(size.y, 1.0)
		# Yuxarı çəkmək (d.y < 0) uzadır: squash mənfi olanda hündürlük artır.
		_jelly = clampf(d.y * 1.2, -PULL_MAX, PULL_MAX * 0.6)
		_lean = clampf(d.x * 1.6, -LEAN_MAX, LEAN_MAX)
		_jelly_v = 0.0
		_lean_v = 0.0
		accept_event()


## GERİ jesti (Android) və ESC: əvvəl açıq olanı bağlayır, ana ekranda isə
## oyundan çıxır — Android-in gözlənilən davranışı budur.
##
## `quit_on_go_back` söndürülüb (bax `project.godot`): açıq olsaydı, vərəq
## açıq ikən GERİ bütün tətbiqi bağlayardı.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	if _settings != null and is_instance_valid(_settings):
		_settings.close()
	elif _friends_view != null and is_instance_valid(_friends_view):
		_friends_view.close()
	elif _sheet != null and _sheet.visible:
		_sheet_back()
	else:
		get_tree().quit()


## ESC vərəqi bağlayır. Ayarlar ekranı ESC-ni ÖZÜ tutur (ağacda sonra gəlir,
## hadisəni birinci alır), ona görə burada yalnız vərəq qalır. Ana ekranda
## ESC heç nə etmir: masaüstündə təsadüfi basış oyunu bağlamamalıdır.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _sheet != null and _sheet.visible:
		get_viewport().set_input_as_handled()
		_sheet_back()


# ---------------------------------------------------------------- yuxarı zolaq

## Yuxarı zolaq: kim oynayır (sol) və server nə vəziyyətdədir (sağ).
func _build_top_bar() -> void:
	# ── oyunçu nişanı ──
	# Köhnə menyuda ad çılpaq mətn qutusu idi və ekranın ortasını tuturdu.
	# Burada o, kimliyə çevrilir: rəngli nişan + ad. Qutu görünmür, amma
	# toxunanda yazılır — ona görə "ayarlar" ekranı açmağa ehtiyac yoxdur.
	var chip := PanelContainer.new()
	chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	chip.offset_left = PAD
	chip.offset_top = 20.0
	chip.offset_right = PAD + 330.0
	chip.offset_bottom = 20.0 + BAR_H + 6.0
	chip.add_theme_stylebox_override("panel", _info_style())
	add_child(chip)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	chip.add_child(row)

	# Avatar — seçilmiş növün qəhrəmanı mavi kafeldə. Brawl Stars-da oyunçu
	# ikonu da profilin solunda, qalın konturlu kvadratdadır. Növ dəyişəndə
	# avatar da dəyişir (bax [method _refresh_species]) — kim olduğun bir
	# baxışda oxunur.
	var tile := PanelContainer.new()
	tile.custom_minimum_size = Vector2(56, 56)
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tile_sb := ChunkyBox.make(Palette.MENU_BLUE, false, 12.0, 4.0)
	tile_sb.set_content_margin_all(4.0)
	tile.add_theme_stylebox_override("panel", tile_sb)
	row.add_child(tile)

	_avatar = TextureRect.new()
	_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_avatar.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(_avatar)

	# Server vəziyyəti burada GÖSTƏRİLMİR (bax [member _net_state]). Əvvəl
	# adın altında "server yatıb" yazılırdı — bu, oyunçunun işi deyil, texniki
	# daxili vəziyyətdir və oyunu sınıq göstərir. Oyunçu yalnız özü OYNA basıb
	# qoşula bilməyəndə cavab alır, o da insan dilində (bax [method _online_failed]).
	_nick = LineEdit.new()
	_nick.text = Net.nickname
	_nick.max_length = 16
	_nick.custom_minimum_size = Vector2(220, 36)
	_nick.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nick.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_nick.add_theme_font_size_override("font_size", 25)
	_nick.add_theme_color_override("font_color", Palette.TEXT)
	ChunkyBox.stroke(_nick, 5, true)
	# Qutunun çərçivəsi silinir: ad METN kimi görünür, sahə kimi yox.
	# Fokus alanda alt xətt qalır — yazıla biləcəyi elə oradan bilinir.
	_nick.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_nick.add_theme_stylebox_override("focus", _underline_style())
	# Ad yazılıb bitəndə yadda saxlanılır — dostlar və komanda yoldaşları yeni
	# adı dərhal görsün (OYNA-nı gözləmədən).
	_nick.text_submitted.connect(func(_t: String) -> void:
		_nick.release_focus()
		# Telefon brauzerində sahə fokus almır (bax [WebText]) — fokus itmədiyi üçün
		# yadda saxlama elə buradan gedir. Ad dəyişməyibsə heç nə yazılmır.
		if _clean_nick() != Net.nickname:
			_save_settings())
	_nick.focus_exited.connect(func() -> void:
		if _clean_nick() != Net.nickname:
			_save_settings())
	WebText.attach(_nick, "nick", {"title": "ADIN", "ok": "OK"})
	row.add_child(_nick)

	# Alt yazı ("adı dəyişmək üçün toxun") yoxdur: Brawl Stars-ın yuxarı
	# zolağında heç bir izahedici cümlə yoxdur. Fokusda alt xətt çıxır (bax
	# `_underline_style`) — yazıla biləcəyi elə oradan bilinir.

	# ── dişli — AYARLARIN yeganə qapısı ──
	# Brawl Stars-da yuxarı-sağ küncdəki menyu düyməsidir. Bizdə arxasında bir
	# ekran var (ayarlar), ona görə siyahı açan "≡" yox, birbaşa dişlidir:
	# arada boş bir menyu pilləsi olmasın.
	var gear := Button.new()
	gear.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	gear.offset_top = 20.0
	gear.offset_bottom = 20.0 + BAR_H + 6.0
	gear.offset_right = -PAD
	gear.offset_left = -(PAD + BAR_H + 6.0)
	gear.icon = load(ICON_SETTINGS)
	gear.expand_icon = true
	gear.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ChunkyBox.apply(gear, Palette.MENU_BLUE, 14.0, 6.0)
	for state in ["normal", "hover", "pressed"]:
		var sb := gear.get_theme_stylebox(state) as ChunkyBox
		sb.content_margin_left = 8.0
		sb.content_margin_right = 8.0
	gear.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_open_settings())
	add_child(gear)
	_squash(gear, Vector2(BAR_H + 6.0, BAR_H + 6.0))

	# ── valyutalar — GÖRÜNÜŞ ÜÇÜN ──
	# Brawl Stars-ın yuxarı-sağındakı valyuta zolaqları: iri ikon zolağın sol
	# ucundan çıxır, sayı sağdadır, premium valyutada "+" var. Arxasında sistem
	# YOXDUR — sayı 0-dır və basanda "tezliklə" deyilir (bax [method _coming_soon]).
	var right := PAD + BAR_H + 6.0 + 14.0
	_currency_pill(ICON_DNA, "DNT", right, true)
	_currency_pill(ICON_FOOD, "QİDA", right + CURRENCY.x + 14.0, false)


## AYARLAR — tam ekran, bax [SettingsView].
##
## Əvvəl dişli kiçik bir paneli açıb-bağlayırdı. İndi açdığı şey ayrıca
## ekrandır: səs sürgüləri, kadr həddi, silkələnmə və idarə düzümü bir panelə
## sığmırdı.
##
## Dişli artıq AÇAN-BAĞLAYAN deyil, yalnız AÇANdır: ekran tam örtükdür və
## dişlinin üstünü tutur, yəni ikinci basılış onsuz da ora çatmazdı. Bağlamaq
## "‹ GERİ" düyməsində və ESC/sistem GERİ jestindədir.
func _open_settings() -> void:
	if _settings != null and is_instance_valid(_settings):
		return
	var view := SettingsView.new()
	add_child(view)
	_settings = view
	view.closed.connect(func() -> void:
		_settings = null
		# Ünvan ayarlarda dəyişmiş ola bilər — köhnə bağlantı artıq
		# etibarsızdır, ona görə yoxlama sıfırdan başlayır.
		if Net.parse_address(Settings.address)[0] != Net.last_address:
			Net.disconnect_from_server()
		_probe_server())


# ---------------------------------------------------------------- ana ekran

## ANA EKRAN — qəhrəmanın ÇEVRƏSİNDƏKİ halqa, Brawl Stars 2026 düzümü.
##
##   • mərkəz        — qəhrəman podiumda; adı və superi BAŞININ ÜSTÜNDƏ
##   • aşağı-sağ     — [ rejim kartı ][ OYNA ]: «nə oynayıram» və «başla» bir
##                     baxışdadır, sağ baş barmaq ikisinə də çatır
##   • sol lent      — MAĞAZA, MİKROBLAR, MƏŞQ (Brawl Stars-da Shop, Brawlers)
##   • aşağı-sol     — MİKRO PASS və TAPŞIRIQLAR (Brawl Pass və Quests)
##   • MAĞAZA, pass, tapşırıqlar və valyutalar GÖRÜNÜŞ ÜÇÜNDÜR — sinif şərhi, 6-cı bənd
func _build_home() -> void:
	# ── AD LÖVHƏSİ ──
	#
	# Kimlik obyektə bağlıdır, ekranın başqa küncünə yox: Brawl Stars da
	# brawler-in adını və kubokunu fiqurun üstündə saxlayır. Yeri hər kadr
	# yenilənir, çünki qəhrəmanın hündürlüyü növdən asılıdır (bax [method _process]).
	var plate := PanelContainer.new()
	plate.name = "Plate"
	plate.custom_minimum_size = Vector2(PLATE.x, PLATE.y)
	plate.size = PLATE
	plate.add_theme_stylebox_override("panel", _info_style())
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(plate)

	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", -4)
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(pv)

	_plate_name = Hud._make_label(30, Palette.TEXT)
	_plate_name.theme_type_variation = "Heading"
	_plate_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ChunkyBox.stroke(_plate_name, 7, true)
	pv.add_child(_plate_name)

	_plate_super = Hud._make_label(16, Palette.SUPER_READY)
	_plate_super.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ChunkyBox.stroke(_plate_super, 4)
	pv.add_child(_plate_super)

	# ── SOL LENT ──
	# Üç kvadrat düymə, ikonu üstdə, adı altda — Brawl Stars-ın sol lentinin
	# ölçüsü, dili və sırası: MAĞAZA ən üstdə. Lent ekranın ortasından YUXARI
	# sürüşüb: aşağı-sol küncdə MİKRO PASS və TAPŞIRIQLAR durur.
	var rail_top := -(RAIL.y * 1.5 + RAIL_GAP) - 46.0
	var shop := _rail_button("MAĞAZA", ICON_SHOP, rail_top, func() -> void:
		_coming_soon("MAĞAZA"))
	# Brawl Stars-da mağaza düyməsi həmişə "yeni təklif" nişanı ilə işarələnir;
	# bizdə təklif yoxdur, ona görə nişan yox, sadəcə rəng fərqi — basılası,
	# amma əsas yol deyil.
	ChunkyBox.apply(shop, Palette.GERM_COLORS[2].darkened(0.25), 16.0, 7.0)
	_rail_button("MİKROBLAR", ICON_BRAWLERS, rail_top + RAIL.y + RAIL_GAP, func() -> void:
		_open_sheet("species"))
	_rail_button("MƏŞQ", ICON_PRACTICE, rail_top + (RAIL.y + RAIL_GAP) * 2.0, _practice)

	# ── AŞAĞI-SOL: MİKRO PASS + TAPŞIRIQLAR — görünüş üçün ──
	_build_pass_card()
	var quests := _icon_button("TAPŞIRIQLAR", ICON_QUESTS, 13, func() -> void:
		_coming_soon("TAPŞIRIQLAR"))
	quests.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	quests.offset_left = PAD + PASS_W + MODE_GAP
	quests.offset_right = PAD + PASS_W + MODE_GAP + RAIL.x
	quests.offset_top = -(PAD + PLAY_H)
	quests.offset_bottom = -PAD

	# ── AŞAĞI-SAĞ: OYNA ──
	#
	# Ekranın yeganə SARI ləkəsi və ən böyük obyekti.
	_play = Button.new()
	_play.text = "OYNA"
	_play.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_play.offset_right = -PAD
	_play.offset_left = -(PAD + BTN_W)
	_play.offset_top = -(PAD + PLAY_H)
	_play.offset_bottom = -PAD
	_play.add_theme_font_size_override("font_size", 50)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_play.add_theme_color_override(state, Palette.TEXT)
	ChunkyBox.stroke(_play, 9, true)
	ChunkyBox.apply(_play, Palette.MENU_PLAY, 20.0, 10.0)
	_play.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_on_play())
	add_child(_play)
	_squash(_play, Vector2(BTN_W, PLAY_H))

	# ── OYNA-NIN SOLU: rejim ──
	#
	# Brawl Stars-ın hadisə yuvası: rejimin ikonu, adı və bir sətir qaydası,
	# kart isə rejimin öz rəngindədir (bax [method _refresh_mode]). "DƏYİŞ ›"
	# yazısı yoxdur — kartın özü düymədir və qalın konturu bunu deyir.
	_mode_card = Button.new()
	_mode_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_mode_card.offset_right = -(PAD + BTN_W + MODE_GAP)
	_mode_card.offset_left = -(PAD + BTN_W + MODE_GAP + MODE_W)
	_mode_card.offset_top = -(PAD + PLAY_H)
	_mode_card.offset_bottom = -PAD
	_mode_card.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		# Brawl Stars-da da komandada hadisəni yalnız lider dəyişir.
		if Friends.party_size() >= 2 and not Friends.is_leader():
			_notify("REJİMİ LİDER SEÇİR", "Komandanın lideri tacla işarələnib.", Palette.MENU_PLAY)
			return
		_open_sheet("modes"))
	add_child(_mode_card)
	_squash(_mode_card, Vector2(MODE_W, PLAY_H))

	_mode_icon = TextureRect.new()
	_mode_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_mode_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mode_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mode_icon.position = Vector2(10, 10)
	_mode_icon.size = Vector2(82, 82)
	_mode_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_card.add_child(_mode_icon)

	_mode_name = Hud._make_label(27, Palette.TEXT)
	_mode_name.theme_type_variation = "Heading"
	_mode_name.position = Vector2(100, 14)
	_mode_name.size = Vector2(MODE_W - 112, 38)
	_mode_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(_mode_name, 6, true)
	_mode_card.add_child(_mode_name)

	_mode_note = Hud._make_label(15, Palette.TEXT)
	_mode_note.position = Vector2(100, 56)
	_mode_note.size = Vector2(MODE_W - 112, 26)
	_mode_note.clip_text = true
	_mode_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(_mode_note, 4)
	_mode_card.add_child(_mode_note)


## Sol lentin bir düyməsi: ikon üstdə, konturlu ad altda.
##
## Düymənin ÖZ mətni və ikonu işlədilmir: Button ikisini yalnız yan-yana düzə
## bilir, Brawl Stars-da isə ikon üstdə, ad altdadır. Ad Label-dır — QA agenti
## ([PlayAgent]) düyməni məhz bu yazı ilə tapır.
func _rail_button(label: String, icon_path: String, top: float, action: Callable) -> Button:
	var b := _icon_button(label, icon_path, 16, action)
	b.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	b.offset_left = PAD
	b.offset_right = PAD + RAIL.x
	b.offset_top = top
	b.offset_bottom = top + RAIL.y
	return b


## Kvadrat ikon düyməsi (112×112): ikon üstdə, konturlu ad altda. Yerini
## çağıran qoyur — sol lent də, aşağı-soldakı TAPŞIRIQLAR da eyni düymədir.
func _icon_button(label: String, icon_path: String, font: int, action: Callable) -> Button:
	var b := Button.new()
	ChunkyBox.apply(b, Palette.MENU_BLUE, 16.0, 7.0)
	b.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		action.call())
	add_child(b)
	_squash(b, RAIL)

	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.position = Vector2(14, 6)
	icon.size = Vector2(RAIL.x - 28, 66)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var lab := Hud._make_label(font, Palette.TEXT)
	lab.theme_type_variation = "Heading"
	lab.text = label
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.position = Vector2(0, 70)
	lab.size = Vector2(RAIL.x, 26)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(lab, 5, true)
	b.add_child(lab)
	return b


## MİKRO PASS — Brawl Stars-ın Brawl Pass düyməsi: ikon, ad, səviyyə və
## irəliləyiş zolağı. GÖRÜNÜŞ ÜÇÜNDÜR: zolaq boşdur (0 XP) və basanda
## "tezliklə" deyilir — irəliləyiş sistemi gələnə qədər doldurulacaq rəqəm yoxdur.
func _build_pass_card() -> void:
	var b := Button.new()
	b.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	b.offset_left = PAD
	b.offset_right = PAD + PASS_W
	b.offset_top = -(PAD + PLAY_H)
	b.offset_bottom = -PAD
	ChunkyBox.apply(b, Palette.MENU_PANEL.lightened(0.06), 16.0, 7.0)
	b.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_coming_soon("MİKRO PASS"))
	add_child(b)
	_squash(b, Vector2(PASS_W, PLAY_H))

	var icon := TextureRect.new()
	icon.texture = load(ICON_PASS)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.position = Vector2(8, 10)
	icon.size = Vector2(80, 80)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var nm := Hud._make_label(22, Palette.MENU_PLAY)
	nm.theme_type_variation = "Heading"
	nm.text = "MİKRO PASS"
	nm.position = Vector2(94, 12)
	nm.size = Vector2(PASS_W - 104, 30)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(nm, 6, true)
	b.add_child(nm)

	var lvl := Hud._make_label(15, Palette.TEXT)
	lvl.text = "Səviyyə 1"
	lvl.position = Vector2(94, 42)
	lvl.size = Vector2(PASS_W - 104, 22)
	lvl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(lvl, 4)
	b.add_child(lvl)

	# Boş irəliləyiş zolağı — qalın konturlu, Brawl Stars-dakı kimi.
	var bar := Panel.new()
	bar.position = Vector2(94, 68)
	bar.size = Vector2(PASS_W - 110, 16)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bar_sb := ChunkyBox.make(Palette.BG_OUTER, false, 8.0, 0.0)
	bar_sb.outline_w = 2.0
	bar_sb.gloss = 0.0
	bar.add_theme_stylebox_override("panel", bar_sb)
	b.add_child(bar)


## Valyuta zolağı (yuxarı-sağ): tünd zolaq, sol ucundan çıxan iri ikon, sayı.
## [param right] — ekranın sağ kənarından zolağın sağ ucuna qədər məsafə.
func _currency_pill(icon_path: String, what: String, right: float, plus: bool) -> Button:
	var b := Button.new()
	b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	b.offset_right = -right
	b.offset_left = -(right + CURRENCY.x)
	b.offset_top = 20.0 + (BAR_H + 6.0 - CURRENCY.y) * 0.5
	b.offset_bottom = b.offset_top + CURRENCY.y
	ChunkyBox.apply(b, Palette.MENU_PANEL, 12.0, 3.0)
	b.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_coming_soon(what))
	add_child(b)
	_squash(b, CURRENCY)

	# İkon zolaqdan BÖYÜKDÜR və sol ucundan çıxır — Brawl Stars-ın imzası:
	# valyuta rəqəmdən əvvəl şəkildən tanınır.
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.position = Vector2(-16, -9)
	icon.size = Vector2(CURRENCY.y + 18.0, CURRENCY.y + 18.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(icon)

	var num := Hud._make_label(22, Palette.TEXT)
	num.theme_type_variation = "Heading"
	num.text = "0"
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.position = Vector2(40, 0)
	num.size = Vector2(CURRENCY.x - 52.0 - (30.0 if plus else 0.0), CURRENCY.y - 4.0)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(num, 5, true)
	b.add_child(num)

	if plus:
		# Premium valyutanın yaşıl "+" kvadratı — Brawl Stars-da qiymətli daşların
		# yanında durur və mağazaya aparır.
		var p := Label.new()
		p.text = "+"
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		p.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		p.position = Vector2(CURRENCY.x - 38.0, 6.0)
		p.size = Vector2(28, 28)
		p.add_theme_font_size_override("font_size", 22)
		p.add_theme_color_override("font_color", Palette.TEXT)
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := ChunkyBox.make(Palette.SAFE.darkened(0.1), false, 7.0, 3.0)
		psb.outline_w = 2.0
		psb.set_content_margin_all(0.0)
		p.add_theme_stylebox_override("normal", psb)
		ChunkyBox.stroke(p, 4, true)
		b.add_child(p)
	return b


## Sistemsiz düymənin cavabı: "MAĞAZA — TEZLİKLƏ!" bildirişi.
##
## Brawl Stars-ın düzümü üçün bu düymələr ekrandadır, arxalarında isə hələ
## sistem yoxdur. Basılıb heç nə olmayan düymə etibarı aparır — oyunçu oyunun
## sınıq olduğunu düşünür. Ona görə hər basış görünən və səsli CAVAB alır:
## nəyin gəlmədiyini açıq deyir, oyunçunu aldatmır.
func _coming_soon(what: String) -> void:
	_notify("%s — TEZLİKLƏ!" % what, "", Palette.MENU_PLAY)


## Ekranın yuxarısında qısa bildiriş: başlıq + (istəyə görə) bir sətir izah.
##
## Həm sistemsiz düymələrin "TEZLİKLƏ" cavabı, həm də onlayn oyuna girə
## bilməyəndə verilən cavab buradan keçir — oyunçuya danışan tək bir səs var.
func _notify(title: String, sub: String, color: Color) -> void:
	if _toast == null:
		_toast = VBoxContainer.new()
		_toast.add_theme_constant_override("separation", 0)
		_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_toast.offset_left = -400.0
		_toast.offset_right = 400.0
		_toast.offset_top = 146.0
		_toast.offset_bottom = 220.0
		_toast.pivot_offset = Vector2(400.0, 24.0)
		_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_toast)
		var head := Hud._make_label(30, Palette.MENU_PLAY)
		head.theme_type_variation = "Heading"
		head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ChunkyBox.stroke(head, 8, true)
		_toast.add_child(head)
		var line := Hud._make_label(19, Palette.TEXT)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ChunkyBox.stroke(line, 5)
		_toast.add_child(line)
	# Bildiriş HƏMİŞƏ ən üstdədir: DOSTLAR ekranı ondan sonra açıla bilər və
	# "SORĞU GÖNDƏRİLDİ" onun arxasında qalardı.
	move_child(_toast, -1)
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	var head_lbl := _toast.get_child(0) as Label
	var sub_lbl := _toast.get_child(1) as Label
	head_lbl.text = title
	head_lbl.add_theme_color_override("font_color", color)
	sub_lbl.text = sub
	sub_lbl.visible = not sub.is_empty()
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast.scale = Vector2(0.7, 0.7)
	var t := create_tween()
	_toast_tween = t
	t.tween_property(_toast, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# İzahlı bildiriş (səhv) daha uzun qalır — iki sətri oxumağa vaxt lazımdır.
	t.tween_interval(1.1 if sub.is_empty() else 2.6)
	t.tween_property(_toast, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: _toast.visible = false)


# ---------------------------------------------------------------- dostlar

## DOSTLAR düyməsi, «+» yuvaları, yoldaşlar və dəvət kartı.
##
## Brawl Stars-ın ana ekranında qəhrəmanın iki yanında iki «+» kvadratı
## durur: toxunanda dost siyahısı açılır, dəvət qəbul olunanda yuvada
## yoldaşın brawler-i peyda olur. Bizdə də eynidir — yuva yoldaşın NÖVÜNÜN
## qəhrəman şəkli ilə dolur, üstündə adı, hazırdırsa yaşıl işarə, liderdirsə tac.
##
## DOSTLAR düyməsi SAĞ lentdədir — Brawl Stars-da "Friends" və "Club"
## sağ sütundadır, sol lent isə mağaza və brawler-lərindir.
func _build_social() -> void:
	var rail_top := -(RAIL.y * 1.5 + RAIL_GAP) - 46.0
	_friends_btn = _icon_button("DOSTLAR", ICON_FRIENDS, 16, func() -> void:
		_open_friends(false))
	_friends_btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_friends_btn.offset_right = -PAD
	_friends_btn.offset_left = -(PAD + RAIL.x)
	_friends_btn.offset_top = rail_top
	_friends_btn.offset_bottom = rail_top + RAIL.y

	# Qırmızı nişan — cavab gözləyən sorğu və dəvətlərin sayı (Brawl Stars-ın
	# "1" nişanı kimi düymənin yuxarı-sağ küncündən çıxır).
	_friends_badge = Label.new()
	_friends_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_friends_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_friends_badge.position = Vector2(RAIL.x - 26.0, -12.0)
	_friends_badge.size = Vector2(36, 36)
	_friends_badge.add_theme_font_size_override("font_size", 19)
	_friends_badge.add_theme_color_override("font_color", Palette.TEXT)
	var bsb := ChunkyBox.make(Palette.DANGER, false, 18.0, 3.0)
	bsb.outline_w = 3.0
	bsb.set_content_margin_all(0.0)
	_friends_badge.add_theme_stylebox_override("normal", bsb)
	_friends_badge.add_theme_font_override("font", ChunkyBox.heavy_font())
	ChunkyBox.stroke(_friends_badge, 4, true)
	_friends_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_friends_btn.add_child(_friends_badge)

	for i in 2:
		# ── boş yuva: «+» ──
		var slot := Button.new()
		slot.text = "+"
		slot.size = Vector2(SLOT, SLOT)
		slot.add_theme_font_size_override("font_size", 64)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			slot.add_theme_color_override(state, Palette.TEXT)
		ChunkyBox.stroke(slot, 8, true)
		for state in ["normal", "hover", "pressed"]:
			var sb := StyleBoxFlat.new()
			# Yarı-şəffaf ağ kvadrat — Brawl Stars-ın komanda yuvasının dili:
			# "burada kimsə ola bilər", amma düymə kimi qışqırmır.
			sb.bg_color = Color(1, 1, 1, 0.26 if state == "hover" else 0.18)
			sb.border_color = Color(1, 1, 1, 0.55)
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(16)
			slot.add_theme_stylebox_override(state, sb)
		slot.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		slot.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			_open_friends(true))
		add_child(slot)
		_squash(slot, Vector2(SLOT, SLOT))
		_slots.append(slot)

		# ── dolu yuva: yoldaşın qəhrəmanı ──
		var mate := Sprite2D.new()
		mate.centered = false
		mate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mate.visible = false
		add_child(mate)
		# Qəhrəmandan ƏVVƏL çəkilir: yoldaş arxadadır.
		move_child(mate, _hero.get_index())
		_mates.append(mate)

		var plate := PanelContainer.new()
		plate.add_theme_stylebox_override("panel", _info_style(12.0))
		plate.mouse_filter = Control.MOUSE_FILTER_STOP
		plate.gui_input.connect(func(e: InputEvent) -> void:
			var mb := e as InputEventMouseButton
			if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				Sfx.play("ui_click")
				_open_friends(false))
		add_child(plate)
		var pv := VBoxContainer.new()
		pv.add_theme_constant_override("separation", -4)
		pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_child(pv)
		var nm := Hud._make_label(20, Palette.TEXT)
		nm.theme_type_variation = "Heading"
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ChunkyBox.stroke(nm, 5, true)
		pv.add_child(nm)
		var st := Hud._make_label(14, Palette.TEXT_MUTED)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pv.add_child(st)
		_mate_plates.append(plate)

		var crown := _crown_rect()
		add_child(crown)
		_mate_crowns.append(crown)

	_my_crown = _crown_rect()
	add_child(_my_crown)
	_build_invite_card()


func _crown_rect() -> TextureRect:
	var c := TextureRect.new()
	c.texture = load(ICON_CROWN)
	c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	c.size = Vector2(46, 38)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.visible = false
	return c


## Komanda dəyişdi (və ya menyu açıldı) — yuvalar, OYNA, rejim kartı, nişan.
func _refresh_party() -> void:
	if _friends_btn == null:
		return
	var n := Friends.badge_count()
	_friends_badge.text = str(n) if n < 10 else "9+"
	_friends_badge.visible = n > 0

	var mates := Friends.mates()
	var home := _sheet == null or not _sheet.visible
	var leader := str(Friends.party.get("leader", ""))
	for i in 2:
		var has := i < mates.size()
		_slots[i].visible = home and not has
		_mates[i].visible = home and has
		_mate_plates[i].visible = home and has
		_mate_crowns[i].visible = home and has and str(mates[i][0]) == leader
		if not has:
			continue
		var m: Array = mates[i]
		var tex := load(_HEROES.get(Const.species_from(int(m[2])), _HEROES[Const.Species.CILIATE])) as Texture2D
		if _mates[i].texture != tex:
			_mates[i].texture = tex
			_mates[i].offset = Vector2(-tex.get_width() * 0.5, -tex.get_height() * 0.97)
		var gone := int(m[4]) == Social.Presence.OFFLINE
		# Qopmuş yoldaş SOLUQ görünür: yeri 30 s saxlanılır (bax
		# [constant Social.PARTY_GRACE]), amma indi oynaya bilmir.
		_mates[i].modulate = Color(1, 1, 1, 0.45 if gone else 1.0)
		var pv := _mate_plates[i].get_child(0)
		(pv.get_child(0) as Label).text = str(m[1])
		var st := pv.get_child(1) as Label
		if bool(m[3]):
			st.text = "HAZIR ✓"
			st.add_theme_color_override("font_color", Palette.SAFE)
		else:
			st.text = "qopdu…" if gone else ("oyunda" if int(m[4]) == Social.Presence.GAME else "gözləyir")
			st.add_theme_color_override("font_color", Palette.TEXT_MUTED)
		_mate_plates[i].reset_size()
	_my_crown.visible = home and Friends.party_size() >= 2 and Friends.is_leader()
	_refresh_play()
	_refresh_mode()


## OYNA-nın yazısı. Komandada o, HAZIR düyməsidir və neçə nəfərin hazır
## olduğunu deyir — Brawl Stars-da da yoldaşı gözləyəndə düymə bunu göstərir.
func _refresh_play() -> void:
	if _joining or _play == null:
		return
	if Friends.party_size() < 2:
		_play.text = "OYNA"
		_play.add_theme_font_size_override("font_size", 50)
		ChunkyBox.apply(_play, Palette.MENU_PLAY, 20.0, 10.0)
		return
	var ready := Friends.am_ready()
	_play.text = ("HAZIR %d/%d  ✕" if ready else "OYNA  %d/%d") % [Friends.ready_count(), Friends.party_size()]
	_play.add_theme_font_size_override("font_size", 34 if ready else 42)
	# Hazır olanda düymə YAŞILA keçir — "gözləyirəm" vəziyyəti rəngdən oxunur,
	# sarı isə yenə "bas" deməkdir.
	ChunkyBox.apply(_play, Palette.SAFE.darkened(0.12) if ready else Palette.MENU_PLAY, 20.0, 10.0)


## Yoldaşın ayaq nöqtəsi.
##
## Məsafə QƏHRƏMANIN ENİNDƏN çıxır, sabit deyil: amöb kirpiklidən 1.6 dəfə
## enlidir və sabit məsafədə ona dəyirdi. Yan lentlərə isə girmir — dar
## (16:9) ekranda bir az qəhrəmanın arxasına keçir, çünki yoldaş ARXADADIR.
func _mate_foot(i: int) -> Vector2:
	var side := -1.0 if i == 0 else 1.0
	var mw := maxf(_mate_size(i).x, SLOT) * 0.5
	var d := _hero_size().x * 0.5 + mw + MATE_GAP
	var room := size.x * 0.5 - (PAD + RAIL.x + MATE_GAP) - mw
	# Bir az YUXARIDA (arxada) dururlar — ön planda sənin qəhrəmanındır.
	return _foot() + Vector2(side * minf(d, room), -size.y * 0.025)


func _mate_size(i: int) -> Vector2:
	var tex := _mates[i].texture
	if tex == null:
		return Vector2.ZERO
	return tex.get_size() * _mate_scale(tex)


func _mate_scale(tex: Texture2D) -> float:
	var ts := tex.get_size()
	return minf(size.y * HERO_BOX.x * MATE_SCALE / ts.x, size.y * HERO_BOX.y * MATE_SCALE / ts.y)


## Yoldaşlar da nəfəs alır (öz qəhrəmanınla FƏRQLİ fazada — yoxsa üçü
## əsgər kimi eyni anda şişərdi), yuvalar və lövhələr onların yerinə düzülür.
func _pose_mates() -> void:
	if _mates.is_empty():
		return
	for i in 2:
		var foot := _mate_foot(i)
		var slot := _slots[i]
		slot.position = foot - Vector2(SLOT * 0.5, size.y * HERO_BOX.y * MATE_SCALE * 0.72)
		var mate := _mates[i]
		if mate.texture == null:
			continue
		var k := _mate_scale(mate.texture)
		var squash := sin(_clock * TAU / BREATH_T + 1.7 + float(i) * 2.1) * BREATH
		mate.scale = Vector2(1.0 + squash, 1.0 - squash) * k * _hero_in
		mate.position = foot
		var ms := _mate_size(i)
		var plate := _mate_plates[i]
		plate.position = Vector2(foot.x - plate.size.x * 0.5, foot.y - ms.y * 0.97 - plate.size.y - 4.0)
		var crown := _mate_crowns[i]
		crown.position = plate.position + Vector2(plate.size.x * 0.5 - crown.size.x * 0.5, -crown.size.y + 8.0)
	var mine := get_node_or_null("Plate") as Control
	if mine != null:
		_my_crown.position = mine.position + Vector2(mine.size.x * 0.5 - _my_crown.size.x * 0.5, -_my_crown.size.y + 8.0)


## DOSTLAR ekranı. [param inviting] — «+» yuvasından açılıb (başlıq dəvət deyir);
## [param tag] — linkdən gələn dost kodu, sahəyə yazılır.
func _open_friends(inviting: bool, tag := "") -> void:
	if _friends_view != null and is_instance_valid(_friends_view):
		return
	var view := FriendsView.new()
	view.invite_mode = inviting
	view.prefill = tag
	add_child(view)
	_friends_view = view
	view.closed.connect(func() -> void: _friends_view = null)


func _on_friends_notice(title: String, sub: String, kind: String) -> void:
	_notify(title, sub, Palette.WARNING if kind == "warn" else Palette.MENU_PLAY)


## Dəvət kartı — ekranın yuxarısında, Brawl Stars-ın komanda dəvəti kimi:
## kim çağırır, hansı rejim, QƏBUL / ✕ və sönən vaxt zolağı.
func _build_invite_card() -> void:
	_invite_card = PanelContainer.new()
	_invite_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_invite_card.offset_left = -300.0
	_invite_card.offset_right = 300.0
	_invite_card.offset_top = 100.0
	_invite_card.offset_bottom = 196.0
	_invite_card.pivot_offset = Vector2(300.0, 0.0)
	var sb := ChunkyBox.make(Palette.MENU_PANEL.lightened(0.05), false, 16.0, 6.0)
	sb.set_content_margin_all(10.0)
	sb.content_margin_bottom = 14.0
	_invite_card.add_theme_stylebox_override("panel", sb)
	_invite_card.visible = false
	add_child(_invite_card)

	# Kart konteynerdir və uşaqlarını özü düzür — zolaq sətrin ALTINDA olsun
	# deyə ikisi bir şaquli qutudadır (birbaşa uşaq olsaydı, zolaq bütün kartı örtərdi).
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	_invite_card.add_child(stack)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	stack.add_child(row)
	var icon := TextureRect.new()
	icon.texture = load(ICON_INVITE)
	icon.custom_minimum_size = Vector2(70, 60)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	row.add_child(icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", -2)
	row.add_child(col)
	var who := Hud._make_label(24, Palette.MENU_PLAY)
	who.theme_type_variation = "Heading"
	who.clip_text = true
	ChunkyBox.stroke(who, 6, true)
	col.add_child(who)
	var what := Hud._make_label(15, Palette.TEXT)
	what.clip_text = true
	col.add_child(what)

	for spec in [["QƏBUL", Palette.SAFE.darkened(0.2), true], ["✕", Palette.DANGER.darkened(0.3), false]]:
		var b := Button.new()
		b.text = spec[0]
		b.custom_minimum_size = Vector2(118 if spec[2] else 60, 58)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.add_theme_font_size_override("font_size", 22)
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(state, Palette.TEXT)
		ChunkyBox.stroke(b, 6, true)
		ChunkyBox.apply(b, spec[1], 14.0, 6.0)
		var accept: bool = spec[2]
		b.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			Friends.answer_invite(_invite_tag, accept)
			_hide_invite())
		row.add_child(b)

	# Vaxt zolağı kartın alt kənarında — dəvətin nə qədər qaldığı.
	_invite_bar = Panel.new()
	var bar_sb := StyleBoxFlat.new()
	bar_sb.bg_color = Palette.MENU_PLAY
	bar_sb.set_corner_radius_all(3)
	_invite_bar.add_theme_stylebox_override("panel", bar_sb)
	_invite_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invite_bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_invite_bar.custom_minimum_size = Vector2(0, 5)
	stack.add_child(_invite_bar)


func _show_invite(tag: String) -> void:
	var inv: Dictionary = Friends.invites.get(tag, {})
	if inv.is_empty() or _invite_card == null:
		return
	_invite_tag = tag
	var col := _invite_card.get_child(0).get_child(0).get_child(1)
	(col.get_child(0) as Label).text = str(inv["name"]).to_upper()
	(col.get_child(1) as Label).text = "səni komandasına çağırır · %s · %d/%d" % [
		Const.mode_name(int(inv["mode"])), int(inv["size"]), Social.PARTY_MAX]
	_invite_card.visible = true
	move_child(_invite_card, -1)
	_invite_card.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(_invite_card, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("level_up", 0.1)
	Settings.vibrate(40)


func _hide_invite() -> void:
	_invite_tag = ""
	_invite_card.visible = false
	# Başqa cavabsız dəvət qalıbsa, növbəti o olur.
	if not Friends.invites.is_empty():
		_show_invite(Friends.invites.keys()[-1])


func _tick_invite() -> void:
	if _invite_card == null or not _invite_card.visible:
		return
	var inv: Dictionary = Friends.invites.get(_invite_tag, {})
	if inv.is_empty():
		_hide_invite()
		return
	var left := clampf((float(inv["until"]) - Friends._clock) / Social.INVITE_TTL, 0.0, 1.0)
	_invite_bar.custom_minimum_size.x = (_invite_card.size.x - 20.0) * left


## Dəvət kartı qəhrəmanın ad lövhəsinin YERİNDƏDİR: yuxarı zolaqla qəhrəman
## arasında 600 px-lik kart üçün başqa yer yoxdur — yuxarıda valyutalara,
## aşağıda yoldaşların lövhələrinə dəyir. Kart görünəndə lövhə və lider tacı
## sönür: əvvəl lövhənin alt sətri ("SUPER · …") kartın üst kənarından yarıya
## kəsilmiş görünürdü.
##
## `modulate` yox, `self_modulate` və lövhənin içi dəyişir: girişdə
## [method _play_intro] ana ekranın node-larının `modulate`-ini tween edir və
## dəvət elə menyu açılanda göstərilə bilər — ikisi bir-birini əzərdi.
func _fade_plate(delta: float) -> void:
	var plate := get_node_or_null("Plate") as PanelContainer
	if plate == null or _my_crown == null:
		return
	var want := 0.0 if _invite_card != null and _invite_card.visible else 1.0
	if _plate_shown == want:
		return
	_plate_shown = move_toward(_plate_shown, want, delta / PLATE_FADE)
	plate.self_modulate.a = _plate_shown
	(plate.get_child(0) as CanvasItem).modulate.a = _plate_shown
	_my_crown.self_modulate.a = _plate_shown


# ---------------------------------------------------------------- vərəq

## MİKROBLAR və REJİMLƏR — eyni çərçivəni paylaşan iki tam ekran vərəq.
##
## Brawl Stars-ın Brawlers və Events ekranlarının qarşılığı. Ana ekranda
## saxlanılsaydılar, oyunçu OYNA-ya çatana qədər on yeddi elementin arasından
## keçərdi; burada isə hər ekranın bir işi var.
func _build_sheet() -> void:
	_sheet = Control.new()
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.visible = false
	add_child(_sheet)

	# Tam tutqun deyil: fon şəkli vərəqin arxasında sönük görünür, yəni vərəq
	# ayrı ekran yox, eyni dünyanın üstündə açılan pərdə kimi oxunur.
	var dim := ColorRect.new()
	dim.color = Color(Palette.BG_OUTER, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet.add_child(dim)

	_sheet_title = Hud._make_label(42, Palette.TEXT)
	_sheet_title.theme_type_variation = "Heading"
	_sheet_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sheet_title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_sheet_title.offset_top = 40.0
	_sheet_title.offset_bottom = 100.0
	ChunkyBox.stroke(_sheet_title, 9, true)
	_sheet.add_child(_sheet_title)

	var back := Button.new()
	back.text = "‹ GERİ"
	back.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	back.offset_left = PAD
	back.offset_right = PAD + 180.0
	back.offset_top = -(PAD + 68.0)
	back.offset_bottom = -PAD
	back.add_theme_font_size_override("font_size", 24)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(state, Palette.TEXT)
	ChunkyBox.stroke(back, 6, true)
	ChunkyBox.apply(back, Palette.MENU_BLUE, 14.0, 6.0)
	back.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		_sheet_back())
	_sheet.add_child(back)

	_sheet_species = Control.new()
	_sheet_species.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_species.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_sheet_species)
	_build_species_grid()
	_build_species_detail()

	_sheet_modes = Control.new()
	_sheet_modes.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_modes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet.add_child(_sheet_modes)
	_build_mode_list()


## MİKROBLAR — Brawl Stars-ın Brawlers kolleksiyası (bax `design/ART_BIBLE.md` § 6d).
##
## Brawl Stars-da hər brawler bir PORTRET kartıdır: personaj yaxından, kartın
## rəngli şüalı fonunda, adı altda. Karta toxunmaq onu SEÇMİR — brawler-in
## səhifəsini açır; seçim orada, sarı SEÇ düyməsi ilədir. Bizdə də belədir:
## əvvəl karta toxunan kimi növ dəyişir və vərəq bağlanırdı, yəni oyunçu
## növün NƏ ETDİYİNİ oxumadan seçirdi.
##
## Kartın rəngi SİNFİN rəngidir (bax [method _species_class]). Brawl Stars-da
## rəng nadirliyi deyir; bizdə nadirlik yoxdur, hər növ əvvəldən açıqdır — ona
## görə rəng növün oyun tərzini deyir.
func _build_species_grid() -> void:
	_species_grid = Control.new()
	_species_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_species_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_species.add_child(_species_grid)

	var total := CARD_BIG.x * 3.0 + GRID_GAP * 2.0
	for i in Const.SPECIES_COUNT:
		var kind := Const.species_from(i)
		var cls := _species_class(kind)
		var card := Button.new()
		card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		card.offset_left = -total * 0.5 + float(i) * (CARD_BIG.x + GRID_GAP)
		card.offset_right = card.offset_left + CARD_BIG.x
		card.offset_top = -CARD_BIG.y * 0.5 + 16.0
		card.offset_bottom = card.offset_top + CARD_BIG.y
		card.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			_open_detail(kind))
		_species_grid.add_child(card)
		_cards.append(card)
		_squash(card, CARD_BIG)

		# Portret kartın bütün üzünü tutur. Künclər ŞƏKLİN ÖZÜNDƏ yumrudur (bax
		# `design/menu_art/process.gd` — `card` rejimi): TextureRect künc kəsə
		# bilmir, `clip_children` isə mobil (Compatibility) renderdə etibarsızdır.
		var art := TextureRect.new()
		art.texture = load(_CARD_ART[kind])
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		art.position = Vector2(CARD_OUTLINE, CARD_OUTLINE)
		art.size = CARD_BIG - Vector2(CARD_OUTLINE * 2.0, CARD_OUTLINE * 2.0 + CARD_LIP)
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)

		var badge := _class_badge(cls, 15)
		badge.position = Vector2(12, 12)
		card.add_child(badge)

		var nm := Hud._make_label(32, Palette.TEXT)
		nm.theme_type_variation = "Heading"
		nm.text = _species_name(kind)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.position = Vector2(0, CARD_BIG.y - 104.0)
		nm.size = Vector2(CARD_BIG.x, 42)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ChunkyBox.stroke(nm, 8, true)
		card.add_child(nm)

		# Ağ, sarı yox: kəhrəba kartın fonunda sarı yazı itirdi. Superin sarısı
		# növün səhifəsindədir (bax [method _build_species_detail]).
		var sp := Hud._make_label(15, Palette.TEXT)
		sp.text = "SUPER · " + _species_super_name(kind)
		sp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sp.position = Vector2(0, CARD_BIG.y - 60.0)
		sp.size = Vector2(CARD_BIG.x, 22)
		sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ChunkyBox.stroke(sp, 5)
		card.add_child(sp)

		# "SEÇİLİB" etiketi — sarı, yuxarı-sağda. Seçilmiş kart həm sarı
		# konturla, həm də bu yazı ilə deyir: rəng tək başına kifayət etmir.
		var tag := Label.new()
		tag.text = "SEÇİLİB"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.position = Vector2(CARD_BIG.x - 112.0, 12.0)
		tag.size = Vector2(100, 30)
		tag.add_theme_font_size_override("font_size", 15)
		tag.add_theme_color_override("font_color", Palette.OUTLINE)
		var tag_sb := ChunkyBox.make(Palette.MENU_PLAY, false, 8.0, 3.0)
		tag_sb.outline_w = 2.0
		tag_sb.set_content_margin_all(0.0)
		tag.add_theme_stylebox_override("normal", tag_sb)
		tag.add_theme_font_override("font", ChunkyBox.heavy_font())
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tag)

		_card_parts.append({"name": nm, "super": sp, "tag": tag, "class": cls})


## Sinif nişanı: ikon + sinfin adı, tünd kapsulun içində.
func _class_badge(cls: Dictionary, font: int) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := ChunkyBox.make(Color(Palette.OUTLINE, 0.72), false, 14.0, 0.0)
	sb.gloss = 0.0
	sb.outline_w = 2.0
	sb.content_margin_left = 4.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 2.0
	sb.content_margin_bottom = 2.0
	box.add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	var icon := TextureRect.new()
	icon.texture = load(cls.icon)
	icon.custom_minimum_size = Vector2(font * 2.0, font * 2.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var lab := Hud._make_label(font, cls.color)
	lab.text = cls.name
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(lab, 4, true)
	row.add_child(lab)
	return box


## Növün SƏHİFƏSİ — Brawl Stars-ın brawler səhifəsi.
##
##   sol     böyük portret + "OYUNDA" pəncərəsi (canlı [GermVisual])
##   sağ     ad, sinif, təsvir, dörd göstərici, super
##   aşağı   ‹ GERİ (kolleksiyaya) · SEÇ (sarı, sağ-aşağı — OYNA-nın yeri)
##
## "OYUNDA" pəncərəsi ona görədir ki, illüstrasiya oyundakı görünüşü əvəz
## etməsin: oyunçu matçda NƏYİ idarə edəcəyini seçməmişdən əvvəl görür.
func _build_species_detail() -> void:
	_detail = Control.new()
	_detail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.visible = false
	_sheet_species.add_child(_detail)

	# ── sol: portret ──
	var art_w := 360.0
	var art := Button.new()
	art.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	art.offset_left = 90.0
	art.offset_right = 90.0 + art_w
	art.offset_top = -art_w / CARD_ASPECT * 0.5 - 30.0
	art.offset_bottom = art.offset_top + art_w / CARD_ASPECT + CARD_LIP
	# Düymə deyil, çərçivədir — amma ChunkyBox düymə dilindədir; basılmır.
	art.disabled = true
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(art)
	_detail_frame = art

	_detail_art = TextureRect.new()
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.stretch_mode = TextureRect.STRETCH_SCALE
	_detail_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_detail_art.position = Vector2(CARD_OUTLINE, CARD_OUTLINE)
	_detail_art.size = Vector2(art_w - CARD_OUTLINE * 2.0, art_w / CARD_ASPECT - CARD_OUTLINE * 2.0)
	_detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(_detail_art)

	# "OYUNDA" pəncərəsi portretin aşağı-sağ küncünə oturur.
	var live := PanelContainer.new()
	live.position = Vector2(art_w - 120.0, art_w / CARD_ASPECT - 110.0)
	live.custom_minimum_size = Vector2(150, 150)
	live.size = Vector2(150, 150)
	live.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var live_sb := ChunkyBox.make(Palette.BG_OUTER, false, 16.0, 0.0)
	live_sb.gloss = 0.0
	live.add_theme_stylebox_override("panel", live_sb)
	art.add_child(live)
	_detail_live = live

	var live_cap := Hud._make_label(13, Palette.TEXT_MUTED)
	live_cap.text = "OYUNDA"
	live_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	live_cap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	live_cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ChunkyBox.stroke(live_cap, 3, true)
	live.add_child(live_cap)

	# ── sağ: məlumat ──
	var left := 90.0 + art_w + 56.0
	_detail_name = Hud._make_label(54, Palette.TEXT)
	_detail_name.theme_type_variation = "Heading"
	_detail_name.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_detail_name.position = Vector2(left, 44)
	_detail_name.size = Vector2(620, 66)
	ChunkyBox.stroke(_detail_name, 10, true)
	_detail.add_child(_detail_name)

	_detail_badge_slot = Control.new()
	_detail_badge_slot.position = Vector2(left, 116)
	_detail_badge_slot.size = Vector2(300, 44)
	_detail_badge_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail.add_child(_detail_badge_slot)

	_detail_note = Hud._make_label(18, Palette.TEXT)
	_detail_note.position = Vector2(left, 168)
	_detail_note.size = Vector2(640, 56)
	_detail_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ChunkyBox.stroke(_detail_note, 4)
	_detail.add_child(_detail_note)

	# Dörd göstərici — HAMISI `Const`-dan gəlir (bax [method _species_stats]).
	for r in STAT_ROWS:
		var y := 236.0 + float(r) * 44.0
		var lab := Hud._make_label(17, Palette.TEXT)
		lab.position = Vector2(left, y)
		lab.size = Vector2(210, 30)
		lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ChunkyBox.stroke(lab, 4, true)
		_detail.add_child(lab)

		var track := Panel.new()
		track.position = Vector2(left + 214.0, y + 5.0)
		track.size = Vector2(STAT_BAR_W, 20)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tsb := ChunkyBox.make(Palette.BG_OUTER, false, 10.0, 0.0)
		tsb.gloss = 0.0
		tsb.outline_w = 2.0
		track.add_theme_stylebox_override("panel", tsb)
		_detail.add_child(track)

		var fill := Panel.new()
		fill.position = Vector2(2, 2)
		fill.size = Vector2(0, 16)
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)

		var val := Hud._make_label(17, Palette.TEXT)
		val.position = Vector2(left + 214.0 + STAT_BAR_W + 12.0, y)
		val.size = Vector2(80, 30)
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ChunkyBox.stroke(val, 4, true)
		_detail.add_child(val)
		_stat_rows.append({"label": lab, "fill": fill, "value": val})

	# ── super ──
	var sup := PanelContainer.new()
	sup.position = Vector2(left, 420)
	sup.size = Vector2(640, 118)
	sup.custom_minimum_size = Vector2(640, 118)
	sup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sup_sb := ChunkyBox.make(Palette.MENU_PANEL, false, 16.0, 0.0)
	sup_sb.gloss = 0.0
	sup_sb.set_content_margin_all(10.0)
	sup.add_theme_stylebox_override("panel", sup_sb)
	_detail.add_child(sup)

	var srow := HBoxContainer.new()
	srow.add_theme_constant_override("separation", 14)
	srow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sup.add_child(srow)

	_detail_super_icon = TextureRect.new()
	_detail_super_icon.custom_minimum_size = Vector2(92, 92)
	_detail_super_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_super_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_super_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_detail_super_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	srow.add_child(_detail_super_icon)

	var scol := VBoxContainer.new()
	scol.add_theme_constant_override("separation", 2)
	scol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scol.mouse_filter = Control.MOUSE_FILTER_IGNORE
	srow.add_child(scol)

	_detail_super_name = Hud._make_label(24, Palette.SUPER_READY)
	_detail_super_name.theme_type_variation = "Heading"
	ChunkyBox.stroke(_detail_super_name, 6, true)
	scol.add_child(_detail_super_name)

	_detail_super_note = Hud._make_label(16, Palette.TEXT)
	_detail_super_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_super_note.custom_minimum_size = Vector2(500, 0)
	ChunkyBox.stroke(_detail_super_note, 4)
	scol.add_child(_detail_super_note)

	# ── SEÇ ── OYNA-nın yerində və rəngində: "bu, əsas əməldir".
	_select_btn = Button.new()
	_select_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_select_btn.offset_right = -PAD
	_select_btn.offset_left = -(PAD + BTN_W)
	_select_btn.offset_top = -(PAD + PLAY_H)
	_select_btn.offset_bottom = -PAD
	_select_btn.add_theme_font_size_override("font_size", 44)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
			"font_disabled_color"]:
		_select_btn.add_theme_color_override(state, Palette.TEXT)
	ChunkyBox.stroke(_select_btn, 9, true)
	_select_btn.pressed.connect(func() -> void:
		Sfx.play("ui_click")
		Net.species = _detail_kind
		_save_settings()
		_swap_hero()
		_refresh_species()
		_close_sheet())
	_detail.add_child(_select_btn)
	_squash(_select_btn, Vector2(BTN_W, PLAY_H))


## Səhifəni [param kind] üçün doldurur və açır.
func _open_detail(kind: Const.Species) -> void:
	_detail_kind = kind
	var cls := _species_class(kind)
	_detail_art.texture = load(_CARD_ART[kind])
	ChunkyBox.apply(_detail_frame, cls.color.darkened(0.3), 16.0, CARD_LIP)
	_detail_frame.add_theme_stylebox_override("disabled", ChunkyBox.make(cls.color.darkened(0.3), false, 16.0, CARD_LIP))
	_detail_name.text = _species_name(kind)
	_detail_note.text = _species_note_for(kind).replace("\n", " ")

	for c in _detail_badge_slot.get_children():
		c.queue_free()
	_detail_badge_slot.add_child(_class_badge(cls, 20))

	var stats := _species_stats(kind)
	for r in _stat_rows.size():
		var row: Dictionary = _stat_rows[r]
		var st: Dictionary = stats[r]
		(row.label as Label).text = st.name
		(row.value as Label).text = "%d%%" % roundi(float(st.value) * 100.0)
		# 100% zolağın YARISIDIR: göstəricilər "orta mikroba" nisbətdədir, ona
		# görə yarıdan uzun zolaq "ondan yaxşı", qısa zolaq "ondan zəif" oxunur.
		var fill := row.fill as Panel
		fill.size.x = (STAT_BAR_W - 4.0) * clampf(float(st.value) / 2.0, 0.04, 1.0)
		var fsb := ChunkyBox.make(cls.color, false, 8.0, 0.0)
		fsb.outline_w = 0.0
		fsb.gloss = 0.22
		fill.add_theme_stylebox_override("panel", fsb)

	_detail_super_icon.texture = load(_SUPER_ICONS[kind])
	_detail_super_name.text = "SUPER · " + _species_super_name(kind)
	_detail_super_note.text = _species_super_note(kind)

	# Canlı mikrob HƏR açılışda yenidən qurulur: [GermVisual] növü qurulanda
	# oxuyur (bax [method _swap_hero]-in köhnə qeydi) — növ dəyişdirilə bilmir.
	for c in _detail_live.get_children():
		if c is Node2D:
			c.queue_free()
	var stage := Node2D.new()
	stage.position = Vector2(75, 82)
	stage.scale = Vector2(1.0, 1.0) * (Const.BASE_RADIUS / Const.germ_radius(GERM_CAPACITY))
	_detail_live.add_child(stage)
	# `load` ilə, sinif adı ilə yox: tipli istinad ~2 300 sətirlik görüntü kodunu
	# menyunun ÖZÜ ilə birlikdə, açılışda kompilyasiya etdirirdi (bax [constant ARENA_SCENE]).
	var g = load("res://scripts/client/germ_visual.gd").new()
	g.setup(MENU_GERM_COLOR, "", true, kind)
	stage.add_child(g)
	g.apply(Vector2.ZERO, 0.0, GERM_BALLS, GERM_CAPACITY, false, true)

	_refresh_select()
	_species_grid.visible = false
	_sheet_title.visible = false
	_detail.visible = true


func _close_detail() -> void:
	_detail.visible = false
	_species_grid.visible = true
	_sheet_title.visible = true


## SEÇ düyməsi: bu növ artıq seçilibsə — "SEÇİLİB", sönük və basılmır.
func _refresh_select() -> void:
	var on := _detail_kind == Net.species
	_select_btn.text = "SEÇİLİB" if on else "SEÇ"
	_select_btn.disabled = on
	ChunkyBox.apply(_select_btn, Palette.MENU_PLAY, 20.0, 10.0)
	_select_btn.add_theme_stylebox_override("disabled",
		ChunkyBox.make(Palette.SAFE.darkened(0.25), false, 20.0, 4.0))


## Rejimlər ŞAQULİ siyahıdır, şəbəkə deyil.
##
## Brawl Stars-ın Events ekranı da belədir: rejimlər bərabər deyil, sıralıdır —
## sonsuz arena giriş, ÜÇLÜK isə ən dar oyundur. Göz yuxarıdan aşağı bir dəfə keçir.
func _build_mode_list() -> void:
	var n := Const.Mode.size()
	var h := ROW_H * float(n) + ROW_GAP * float(n - 1)
	for i in n:
		var mode := Const.mode_from(i)
		var row := Button.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		row.offset_left = -ROW_W * 0.5
		row.offset_right = ROW_W * 0.5
		row.offset_top = -h * 0.5 + 30.0 + float(i) * (ROW_H + ROW_GAP)
		row.offset_bottom = row.offset_top + ROW_H
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.pressed.connect(func() -> void:
			Sfx.play("ui_click")
			# Komandada rejimi lider seçir və rejim komandaya SIĞMALIDIR. Tək
			# üzvlü komanda da (kod yaradılıb, hələ kimsə gəlməyib) serverə
			# deyilir — yoxsa kodla gələn yoldaş köhnə rejimə düşərdi.
			if Friends.in_party():
				if Friends.party_size() > Social.party_limit(int(mode)):
					var t := Friends.notice_text("mode_small", str(int(mode)))
					_notify(t[0], t[1], Palette.WARNING)
					return
				Friends.set_mode(int(mode))
			Net.mode = mode
			_save_settings()
			_refresh_mode()
			_close_sheet())
		_sheet_modes.add_child(row)
		_mode_rows.append(row)

		# Rəng kvadratı əvəzinə rejimin ikonu — ana ekrandakı kartla EYNİ şəkil,
		# yəni oyunçu seçdiyini ana ekranda dərhal tanıyır.
		var icon := TextureRect.new()
		icon.texture = load(_MODE_ICONS[mode])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon.position = Vector2(16, (ROW_H - 80.0) * 0.5 - 2.0)
		icon.size = Vector2(80, 80)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)

		var nm := Hud._make_label(28, Palette.TEXT)
		nm.theme_type_variation = "Heading"
		nm.text = Const.mode_name(int(mode))
		nm.position = Vector2(110, 14)
		nm.size = Vector2(ROW_W - 130, 38)
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ChunkyBox.stroke(nm, 6, true)
		row.add_child(nm)

		var note := Hud._make_label(16, Palette.TEXT)
		note.text = Const.mode_note(int(mode))
		note.position = Vector2(110, 54)
		note.size = Vector2(ROW_W - 130, 26)
		note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ChunkyBox.stroke(note, 4)
		row.add_child(note)


## Vərəq açılanda qəhrəman və podium GİZLƏNİR.
##
## Vərəq yarı-şəffafdır (fon görünsün deyə), yəni onların altında sönük
## qalardı — kartlardakı canlı mikrobların arxasında ikinci, böyük bir mikrob.
##
## Ana ekranın PANELLƏRİ və düymələri də gizlənir. Brawl Stars-da Brawlers
## ekranı ayrı ekrandır; burada isə 14%-lik şəffaflıqdan arxadakı ad lövhəsi
## vərəqin başlığının altına, OYNA isə GERİ-nin yanına düşürdü — iki
## interfeys üst-üstə oxunurdu.
func _open_sheet(which: String) -> void:
	_ensure_sheet()
	_hero.visible = false
	for m in _mates:
		m.visible = false
	for c in _home_ui():
		c.visible = false
	_sheet_title.text = "MİKROBLAR" if which == "species" else "REJİMLƏR"
	_sheet_species.visible = which == "species"
	_sheet_modes.visible = which != "species"
	# Vərəq HƏMİŞƏ kolleksiyadan açılır, son baxılan növün səhifəsindən yox.
	_close_detail()
	_sheet.visible = true
	_refresh_species()
	_refresh_mode()


## GERİ (düymə, ESC, Android jesti): növ səhifəsindən kolleksiyaya, oradan
## ana ekrana — Brawl Stars-da da geri bir pillə-bir pillə gedir.
func _sheet_back() -> void:
	if _detail != null and _detail.visible:
		_close_detail()
	else:
		_close_sheet()


## Vərəqi ilk dəfə lazım olanda qurur və əvvəlki yerinə qoyur.
func _ensure_sheet() -> void:
	if _sheet != null:
		return
	_build_sheet()
	if _sheet_slot >= 0:
		move_child(_sheet, mini(_sheet_slot, get_child_count() - 1))
	_refresh_species()
	_refresh_mode()


func _close_sheet() -> void:
	_sheet.visible = false
	_hero.visible = true
	for c in _home_ui():
		c.visible = true
	# Yuvaların görünməsi komandadan asılıdır — hamısını açmaq boş yuvanın
	# yerində gizli yoldaşın lövhəsini də göstərərdi.
	_refresh_party()


## Ana ekranın öz Control-ları — vərəq, ayarlar ekranı və bildiriş xaric.
## Bildiriş öz görünməsini özü idarə edir; burada olsaydı, vərəq bağlananda
## sönmüş "TEZLİKLƏ" yazısı yenidən görünən sayılardı.
func _home_ui() -> Array[Control]:
	var out: Array[Control] = []
	for child in get_children():
		var c := child as Control
		if c != null and c != _sheet and c != _settings and c != _toast \
				and c != _invite_card and c != _friends_view:
			out.append(c)
	return out


## Giriş animasiyası.
##
## Ardıcıllıq təsadüfi deyil: əvvəl PODİUM qurulur, sonra QƏHRƏMAN doğulur,
## sonra SEÇİM, ən sonda OYNA sıçrayır. Göz sonuncu hərəkətə yönəlir, ona görə
## sonuncu hərəkət düz basılası düymədə olmalıdır.
func _play_intro() -> void:
	var groups: Array[Control] = []
	for child in get_children():
		if child is Control:
			groups.append(child as Control)
	for g in groups:
		g.modulate.a = 0.0

	# Podium öz `_draw`-ındadır, qəhrəman isə ayrıca node — ikisi ayrı gəlir.
	# Fon isə HEÇ sönmür: qara kadrdan açılan menyu "yüklənir" kimi oxunur.
	var t := create_tween()
	t.tween_method(func(v: float) -> void: _intro = v, 0.0, 1.0, INTRO_TIME * 0.55) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	_pop_hero(INTRO_TIME * 0.28)

	var step := INTRO_TIME / maxf(float(groups.size()), 1.0)
	for i in groups.size():
		var g := groups[i]
		var fade := create_tween()
		fade.tween_interval(step * float(i) * 0.55)
		fade.tween_property(g, "modulate:a", 1.0, 0.22)

	# OYNA sonuncu və yeganə SIÇRAYAN elementdir.
	_play.scale = Vector2(0.86, 0.86)
	var pop := create_tween()
	pop.tween_interval(INTRO_TIME * 0.72)
	pop.tween_property(_play, "scale", Vector2.ONE, 0.3) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- növ

## Növ dəyişəndə qəhrəman podiumda YENİDƏN doğulur.
##
## Şəkil sadəcə dəyişdirilsəydi, seçim "səssiz" keçərdi — oyunçu vərəqi
## bağlayır və fərqi axtarmalı olur. Doğuş sıçrayışı və səsi seçimi təsdiq edir.
func _swap_hero() -> void:
	_set_hero_texture()
	_pop_hero(0.0)
	Sfx.play("spawn")


## Doğuş: miqyas 0 → ~1.1 → 1 (back-out, 0.35 s) — oyundakı doğuşla eyni
## dil (bax `design/BRAWL_UPGRADE.md` § 2.4).
func _pop_hero(delay: float) -> void:
	# Köhnə doğuş öldürülür: girişin ilk 0.6 saniyəsində növ seçilsə, iki
	# tween eyni dəyişənə yazar və qəhrəman titrəyərdi.
	if _hero_tween != null and _hero_tween.is_valid():
		_hero_tween.kill()
	_hero_in = 0.0
	_jelly = 0.0
	_jelly_v = 0.0
	var t := create_tween()
	_hero_tween = t
	t.tween_interval(delay)
	t.tween_method(func(v: float) -> void: _hero_in = v, 0.0, 1.0, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Seçilmiş rejimin adı və bir sətirlik qaydası.
##
## Bir sətir MƏCBURİDİR: oyunçu nəyə girdiyini basmadan əvvəl bilməlidir.
## Menyunun onsuz da yazılmış qaydasıdır (bax sinif şərhi, 3-cü bənd).
## Ayarlar ekranında nəyisə dəyişdilər — menyu özünü yeniləyir.
##
## Yalnız keyfiyyət menyunun GÖRÜNTÜSÜNƏ təsir edir, qalan ayarlar (səs, kadr
## həddi, idarə) motorda və ya oyunun içindədir. Ona görə burada bir çağırış var.
func _on_settings_changed() -> void:
	_apply_quality()


## HDR kadr buferi və zərrəcik sıxlığı — DƏRHAL, düymə basılan kadrda.
##
## Glow-un özü `WorldEnvironment`-dədir və o, [method _build_background]-da bir
## dəfə qurulur; menyu yenidən qurulmadığı üçün seçim növbəti açılışdan tam
## işləyir. Bufer və zərrəciklər isə elə indi dəyişir, yəni düymə basılan kimi
## ekranda gözlə görünən fərq olur — oyunçu ayarın işlədiyini bilir.
func _apply_quality() -> void:
	var low := Const.is_light(int(Net.quality))
	get_viewport().use_hdr_2d = not low
	if _motes != null:
		_motes.count = 26 if low else 54
		_motes.rebuild()


func _refresh_mode() -> void:
	# Ad və qayda [Const]-dan gəlir: rejim əlavə edəndə menyu özü yenilənir.
	_mode_name.text = Const.mode_name(int(Net.mode))
	_mode_note.text = Const.mode_brief(int(Net.mode))
	_mode_icon.texture = load(_MODE_ICONS.get(Net.mode, _MODE_ICONS[Const.Mode.ENDLESS]))
	# Kart rejimin ÖZ rəngindədir — Brawl Stars-da hər rejimin rəngi var və
	# oyunçu onu adından əvvəl tanıyır. Rəng tündləşdirilir ki, üstündəki ağ
	# yazı və ikon oxunsun: doymuş firuzəyi üstündə ağ mətn itirdi.
	var tint: Color = Palette.GERM_COLORS[MODE_TINT[int(Net.mode)]]
	ChunkyBox.apply(_mode_card, tint.darkened(0.45), 16.0, 8.0)

	for i in _mode_rows.size():
		var on := Const.mode_from(i) == Net.mode
		var row := _mode_rows[i]
		for state in ["normal", "hover", "pressed"]:
			row.add_theme_stylebox_override(state, _card_style(on, state == "pressed"))
		var nm := row.get_child(1) as Label
		nm.add_theme_color_override("font_color",
			Palette.TEXT if on else Color(0.62, 0.72, 0.71))


func _refresh_species() -> void:
	_plate_name.text = _species_name(Net.species)
	_plate_super.text = "SUPER · " + _species_super_name(Net.species)
	_avatar.texture = load(_HEROES.get(Net.species, _HEROES[Const.Species.CILIATE]))
	for i in _cards.size():
		var on := Const.species_from(i) == Net.species
		var card := _cards[i]
		# Seçilən kart yerində donmur: mərkəzindən 3.5% qalxır, qalanları
		# ölçüsünə qayıdır. Yerdəyişmə yox, miqyas seçilib ki, üç kartın
		# aralarındakı toxunma sahələri bir-birinə sürüşməsin.
		_animate_card_rest(card, Vector2.ONE * (1.035 if on else 1.0))
		# Kartın rəngi sinfindir; seçilmiş kartın konturu SARI və qalındır.
		# Basılanda üz ENMİR (dodaq eyni qalır): portret düymənin üzündə
		# çəkilmir, ayrıca uşaqdır — üz ensəydi, şəkil yerində qalıb dodağı örtərdi.
		var parts: Dictionary = _card_parts[i]
		var face: Color = (parts.class as Dictionary).color
		for state in ["normal", "hover", "pressed"]:
			var sb := ChunkyBox.make(face.darkened(0.3), false, 16.0, CARD_LIP)
			if on:
				sb.outline = Palette.MENU_PLAY
				sb.outline_w = 5.0
			card.add_theme_stylebox_override(state, sb)
		card.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		(parts.tag as Label).visible = on


static func _species_name(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "AYAQLI"
		Const.Species.AMOEBA:
			return "AMÖB"
		_:
			return "KİRPİKLİ"


## Növün superinin adı.
static func _species_super_name(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "AKSOPODİYA TORU"
		Const.Species.AMOEBA:
			# Əvvəl "SİSTLƏŞMƏ" idi — toxunulmaz qabıq. İndi qalxan yoxdur, yerində
			# fasiləsiz atəşdir (bax [method Sim._step_germs]).
			return "MİNİQAN"
		_:
			return "TRİXOSİST"


## Növün NƏ ETDİYİ — bir üstünlük, bir qiymət.
##
## Hər sətirdə ikisi də var və bu, qəsdəndir: menyu "güclü olanı seç" yox,
## "necə oynamaq istəyirsən" sualını verməlidir. Növlərin DÖYÜŞ riyaziyyatı
## eynidir — atəş dövrü, topun qiyməti, tutum artımı (bax [constant
## Const.SPECIES_THRUST] və `sim_test`-dəki yoxlama). Fərq yalnız mühitlə
## münasibətdə və superdədir.
static func _species_note_for(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "Qidanı özünə çəkir, rəqibi yavaşladır.\nAxına dirənir, amma ən yavaş növdür."
		Const.Species.AMOEBA:
			return "Qabığa çevrilir: top səkir, aclıq dayanır.\nDar yerdən keçir, amma tərpənə bilmir."
		_:
			return "Gələn topları partladıb qaçır.\nƏn cəld, amma axın onu aparır."


## Növün SİNFİ — Brawl Stars-ın sinifləri (Assassin, Controller, Tank) kimi.
##
## Sinif növün oyun tərzini bir sözlə deyir: kolleksiyada kartları rəngindən
## tanımaq olur, səhifədə isə adın altında yazılır. Rənglər [constant
## Palette.GERM_COLORS]-dandır və kart portretlərinin fonu da məhz bu
## rənglərlə çəkilib (bax `design/menu_art/brief/BRIEF_CARDS.md`).
static func _species_class(kind: Const.Species) -> Dictionary:
	match kind:
		Const.Species.HELIOZOAN:
			return {"name": "NƏZARƏTÇİ", "color": Palette.GERM_COLORS[4],
				"icon": "res://assets/menu/class_control.png"}
		Const.Species.AMOEBA:
			return {"name": "MÜDAFİƏÇİ", "color": Palette.GERM_COLORS[6],
				"icon": "res://assets/menu/class_guard.png"}
		_:
			return {"name": "CƏLD", "color": Palette.GERM_COLORS[3],
				"icon": "res://assets/menu/class_swift.png"}


## Səhifədəki dörd göstərici — HAMISI [Const]-un növ əmsallarından.
##
## Brawl Stars-ın səhifəsində can, zərər və super rəqəmləri var. Bizdə DÖYÜŞ
## riyaziyyatı hər növdə eynidir (bax [constant Const.SPECIES_THRUST]-un
## qaydası), fərq yalnız mühitlədir — ona görə göstəricilər də mühit
## göstəriciləridir. Rəqəm uydurulmur: əmsal dəyişəndə səhifə özü dəyişir.
## Axın və maneə əmsalları TƏRS göstərilir, çünki kiçik əmsal üstünlükdür.
static func _species_stats(kind: Const.Species) -> Array[Dictionary]:
	var i := int(kind)
	return [
		{"name": "SÜRƏTLƏNMƏ", "value": Const.SPECIES_THRUST[i]},
		{"name": "ÜST SÜRƏT", "value": Const.SPECIES_SPEED[i]},
		{"name": "AXINA DÖZÜM", "value": 1.0 / Const.SPECIES_FLOW[i]},
		{"name": "DAR YERDƏN KEÇİD", "value": 1.0 / Const.SPECIES_BODY[i]},
	]


## Superin nə etdiyi — rəqəmlər [Const]-dan, yəni balans dəyişəndə mətn yalan
## danışmır.
static func _species_super_note(kind: Const.Species) -> String:
	match kind:
		Const.Species.HELIOZOAN:
			return "%d saniyəlik tor: ətrafdakı qida sənə axır, tora düşən rəqib %d%% yavaşlayır." % [
				int(Const.NET_TIME), roundi((1.0 - Const.NET_SLOW) * 100.0)]
		Const.Species.AMOEBA:
			# Onluq kəsr VERGÜLLƏ yazılır ("2,5") — Azərbaycan dilinin qaydası.
			return "%s saniyə yerində donub fasiləsiz atəş açırsan: toplar öz sayından getmir, aclıq dayanır. Qalxan yoxdur — sənə də dəyir." % \
				("%.1f" % Const.CYST_TIME).replace(".", ",")
		_:
			return "Yaxındakı rəqib topları qidaya çevrilir, mikroblar itələnir, sən geri sıçrayırsan. Qiyməti: %d top." % Const.TRICHO_COST


# ---------------------------------------------------------------- şəbəkə

## Menyu açılan kimi serverə SƏSSİZ qoşulma yoxlanılır.
##
## Səbəb praktikdir: server Railway-də yaşayır və işsiz qalanda YATIR, oyanması
## isə bir neçə saniyə çəkir. Menyu açılan kimi qoşulmağa başlamaq o saniyələri
## oyunçunun gözləməsindən çıxarır: OYNA basılanda bağlantı çox vaxt artıq
## hazırdır və dünyaya giriş ani olur.
##
## Nəticə EKRANDA GÖSTƏRİLMİR. Əvvəl profilin altında "server yatıb" yazılırdı:
## oyunçu heç nə etməmiş oyun ona "sınığam" deyirdi, üstəlik texniki dildə.
## İndi vəziyyət yalnız [member _net_state]-dədir; oyunçu cavabı ancaq özü
## OYNA basıb qoşula bilməyəndə alır (bax [method _online_failed]).
func _probe_server() -> void:
	if Net.is_connected_to_server():
		_set_status("ONLAYN")
		return
	_set_status("yoxlanılır")
	var parts := Net.parse_address(Settings.address)
	if Net.join_server(parts[0], parts[1]) != OK:
		_set_status("ünvan səhvdir")
		return

	# Vaxt həddi. Qoşulma HƏMİŞƏ "alınmadı" ilə bitmir: server yatmış olsa,
	# ünvan səssiz düşsə və ya paketlər yolda itsə, `connection_failed`
	# ümumiyyətlə gəlmir və vəziyyət əbədi "yoxlanılır" qalardı.
	_probe_token += 1
	var token := _probe_token
	get_tree().create_timer(PROBE_TIMEOUT).timeout.connect(func() -> void:
		if token != _probe_token or _joining or Net.is_connected_to_server():
			return
		_set_status("cavab yoxdur"))


func _on_play() -> void:
	# Komandada OYNA "HAZIRAM" deməkdir: hamı hazır olanda server komandanı
	# BİRLİKDƏ oyuna salır (bax [method SocialHub._try_start]). İkinci basış
	# hazırlığı geri alır — Brawl Stars-da da belədir.
	if Friends.party_size() >= 2:
		Net.nickname = _clean_nick()
		_save_settings()
		Friends.set_ready(not Friends.am_ready())
		return
	# Basılan düymə qoşulmanı həm başladır, həm ləğv edir — vəziyyəti O
	# göstərdiyinə görə ləğv də ONUN üstündədir.
	if _joining:
		Net.disconnect_from_server()
		_set_joining(false)
		_set_status("ləğv edildi")
		return

	Net.nickname = _clean_nick()
	_save_settings()
	_set_joining(true)
	_arm_join_timeout()

	if Net.is_connected_to_server():
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_set_status("dünyaya girilir")
		return

	_set_status("qoşulur")
	var parts := Net.parse_address(Settings.address)
	if Net.join_server(parts[0], parts[1]) != OK:
		_set_status("ünvan səhvdir")
		_online_failed("Ayarlarda server ünvanını yoxla.")


## OYNA-nın vaxt həddi. Səssiz yoxlamanın həddi qoşulma gedərkən işləmir (orada
## `_joining` yoxlanılır), yəni server heç cavab verməsə düymə əbədi "QOŞULUR…"
## qalardı — oyunçu isə gözləmək, yoxsa MƏŞQ oynamaq lazım olduğunu bilməzdi.
## 12 s: yatmış Railway serverinin oyanmasına kifayət edir, səbri isə tükətmir.
func _arm_join_timeout() -> void:
	_probe_token += 1
	var token := _probe_token
	get_tree().create_timer(JOIN_TIMEOUT).timeout.connect(func() -> void:
		if token != _probe_token or not _joining or not is_instance_valid(self):
			return
		Net.disconnect_from_server()
		_set_status("cavab yoxdur")
		_online_failed())


## Oyunçunun ÖZ cəhdi alınmadı — bunu bilməlidir, amma insan dilində.
##
## "server yatıb", "bağlantı kəsildi" kimi sözlər oyunçuya heç nə demir və
## oyunu sınıq göstərir. Onun bilməli olduğu iki şeydir: onlayn oyun indi
## alınmır və NƏ edə bilər — MƏŞQ həmişə işləyir.
func _online_failed(hint := "Botlarla MƏŞQ oynaya bilərsən.") -> void:
	_set_joining(false)
	_notify("ONLAYN OYUN HAZIRDA ƏLÇATMAZDIR", hint, Palette.WARNING)


func _practice() -> void:
	# MƏŞQ oflayndır — bağlantı bağlanır və üzv 30 s sonra komandadan düşərdi.
	# Brawl Stars-da da komandada məşq meydançasına girmək olmur.
	if Friends.party_size() >= 2:
		_notify("MƏŞQ TƏK OYNANIR", "Əvvəl komandadan çıx — DOSTLAR ekranında.", Palette.WARNING)
		return
	Net.nickname = _clean_nick()
	_save_settings()
	# Yoxlama üçün açılmış bağlantı məşqdə lazım deyil — açıq qalsa server
	# oyunçunu onlayn sayardı.
	Net.disconnect_from_server()
	var arena = load(ARENA_SCENE).instantiate()
	arena.configure_practice()
	_swap_to(arena)


func _on_connected() -> void:
	if _joining:
		Net.request_join.rpc_id(1, Net.nickname, int(Net.species), int(Net.mode))
		_set_status("dünyaya girilir")
	else:
		_set_status("ONLAYN")


## Səssiz yoxlama alınmadısa — SƏSSİZ qalır. Oyunçu OYNA basıbsa — cavab alır.
func _on_connect_failed() -> void:
	_set_status("qoşulmadı")
	if _joining:
		_online_failed()


func _on_disconnected() -> void:
	_set_status("kəsildi")
	if _joining:
		_online_failed()


## Serverin rədd cavabı insan dilində yazılır — onu olduğu kimi göstərmək olar.
func _on_join_rejected(reason: String) -> void:
	_set_status("rədd: " + reason)
	_set_joining(false)
	_notify("OYUNA GİRMƏK ALINMADI", reason, Palette.WARNING)


func _on_world_joined(info: Dictionary) -> void:
	var arena = load(ARENA_SCENE).instantiate()
	arena.configure_online(info)
	_swap_to(arena)


func _swap_to(scene: Node) -> void:
	# configure_* mütləq ağaca əlavə etməzdən ƏVVƏL çağırılmalıdır:
	# arena `_ready`-də həmin məlumatla qurulur.
	var tree := get_tree()
	tree.root.add_child(scene)
	tree.current_scene = scene
	queue_free()


func _set_joining(busy: bool) -> void:
	_joining = busy
	_play.text = "QOŞULUR…  ✕" if busy else "OYNA"
	_play.add_theme_font_size_override("font_size", 30 if busy else 50)
	if not busy:
		_refresh_play()


## Bağlantının daxili vəziyyəti — ekrana çıxmır (bax [method _probe_server]).
func _set_status(text: String) -> void:
	_net_state = text


# ---------------------------------------------------------------- ayarlar

func _clean_nick() -> String:
	var s := _nick.text.strip_edges()
	return "Mikrob" if s.is_empty() else s.substr(0, 16)


## Menyunun öz seçimləri (ad, növ, rejim) — qalanını ayarlar ekranı yazır.
##
## Əvvəl `ConfigFile` elə burada açılırdı. İndi ayar faylının bir sahibi var
## ([Settings]) və bunun praktik nəticəsi var: menyunu KEÇƏN yollar
## (`--practice`, `--agent`, `--map`) da artıq oyunçunun səsi, kadr həddi və
## keyfiyyəti ilə başlayır — əvvəl onlarda ayarlar ümumiyyətlə oxunmurdu.
func _save_settings() -> void:
	Net.nickname = _clean_nick()
	Settings.save()
	# Ad, növ və rejim komanda yoldaşlarının podiumunda da görünür.
	Friends.profile_changed()


# ---------------------------------------------------------------- parçalar

## Basılanda əzilmə — Brawl Stars-ın imzası, bizdə də eynidir.
## Toxunuşun cavabsız qalmadığı məhz bundan bilinir.
static func _squash(b: Button, box: Vector2) -> void:
	b.pivot_offset = box * 0.5
	if not b.has_meta("rest_scale"):
		b.set_meta("rest_scale", Vector2.ONE)
	b.button_down.connect(func() -> void:
		var old: Tween = b.get_meta("motion_tween") if b.has_meta("motion_tween") else null
		if old != null and old.is_valid():
			old.kill()
		var rest: Vector2 = b.get_meta("rest_scale", Vector2.ONE)
		var t := b.create_tween()
		b.set_meta("motion_tween", t)
		t.tween_property(b, "scale", rest * 0.94, 0.06))
	b.button_up.connect(func() -> void:
		var old: Tween = b.get_meta("motion_tween") if b.has_meta("motion_tween") else null
		if old != null and old.is_valid():
			old.kill()
		var rest: Vector2 = b.get_meta("rest_scale", Vector2.ONE)
		var t := b.create_tween()
		b.set_meta("motion_tween", t)
		t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "scale", rest, 0.16))


## Seçim dəyişəndə kartın istirahət miqyasını hərəkətlə yeniləyir.
## `_squash` eyni meta-nı oxuyur, yəni seçilmiş kart buraxılanda 1.0-a yox,
## öz qaldırılmış vəziyyətinə qayıdır.
static func _animate_card_rest(b: Button, target: Vector2) -> void:
	b.set_meta("rest_scale", target)
	var old: Tween = b.get_meta("motion_tween") if b.has_meta("motion_tween") else null
	if old != null and old.is_valid():
		old.kill()
	var t := b.create_tween()
	b.set_meta("motion_tween", t)
	t.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(b, "scale", target, 0.20)


## Məlumat paneli (profil, ad lövhəsi): düymə kimi qalın
## konturlu, amma DODAQSIZ və tünd — basılmır, ona görə "basılası" kimi
## görünməməlidir. Brawl Stars-da da oxunan zolaqlar yastıdır.
static func _info_style(rad := 16.0) -> ChunkyBox:
	var sb := ChunkyBox.make(Palette.MENU_PANEL, false, rad, 0.0)
	# Parıltı YOXDUR: dodaqsız paneldə onun alt kənarı yazının ortasından
	# keçən sərt xətt kimi oxunurdu. Parıltı basılası şeylərin işarəsidir.
	sb.gloss = 0.0
	sb.content_margin_left = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	return sb


static func _underline_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = Palette.GERM_COLORS[1]
	sb.border_width_bottom = 2
	return sb


## Vərəqdəki kart: tünd panel, qalın kontur. Seçilmiş kartın konturu SARI
## və qalındır — Brawl Stars-da seçilmiş brawler kartı da sarı çərçivəlidir,
## həm də ana ekrandakı sarı OYNA ilə eyni dildə "bu seçilib, başla" deyir.
static func _card_style(selected: bool, pressed := false) -> ChunkyBox:
	var face := Palette.MENU_PANEL.lightened(0.10) if selected else Palette.MENU_PANEL
	var sb := ChunkyBox.make(face, pressed, 16.0, 7.0)
	if selected:
		sb.outline = Palette.MENU_PLAY
		sb.outline_w = 5.0
	return sb
