class_name Social
extends RefCounted
## Dostluq və komanda sisteminin QAYDALARI — client də, server də buradan oxuyur.
##
## ── Brawl Stars-dan nə götürülüb ────────────────────────────────────────
##
##   • Hər oyunçunun dəyişməz OYUNÇU KODU var (`#2PPLQ8GY` kimi). Dost məhz
##     onunla əlavə olunur: sorğu gedir, qarşı tərəf QƏBUL edir.
##   • Dost siyahısında hər dostun vəziyyəti görünür: menyuda, komandada,
##     oyunda, oflayn.
##   • Ana ekranda qəhrəmanın iki yanında «+» yuvası var — toxunanda dost
##     siyahısı açılır və dost KOMANDAYA dəvət olunur. Dəvət qəbul olunanda
##     yoldaş podiumda sənin yanında durur.
##   • Komandanın KODU var: kodu (və ya linki) alan hər kəs komandaya girir —
##     dost olmaq şərt deyil.
##   • Hamı HAZIR olanda komanda BİRLİKDƏ oyuna girir: CÜT və ÜÇLÜK-də eyni
##     komandada, SONSUZ ARENA-da eyni dünyada.
##
## ── Niyə dost siyahısı SERVERDƏ deyil ───────────────────────────────────
##
## Server Render-in pulsuz planındadır: 15 dəqiqə boş qalanda yatır, hər
## deploy-da yenidən qalxır və diski müvəqqətidir. Siyahı serverdə yaşasaydı,
## hər yuxudan sonra hamının dostları silinərdi. Ona görə siyahının SAHİBİ
## oyunçunun öz cihazıdır (`user://social.cfg`), server isə yalnız ÖTÜRÜCÜDÜR:
## kimin onlayn olduğunu bilir və sorğuları/dəvətləri çatdırır.
##
## Bunun təhlükəsizlik tərəfi də var: client siyahısını özü göndərir, yəni
## istədiyi kodu yaza bilər. Ona görə server vəziyyəti və dəvəti yalnız
## QARŞILIQLI dostluqda ötürür — iki tərəfin siyahısında da bir-biri olmalıdır.
## Yad biri sənin kodunu siyahısına yazmaqla sənin onlayn olduğunu görə bilməz.

## Brawl Stars-ın oyunçu kodlarının əlifbası — 14 simvol, bir-birinə
## bənzəyən cütlər yoxdur (O/0, I/1, B/8 kimi). Telefonda əllə yazılan kodda
## bu, səhvlərin yarısını aradan qaldırır.
const TAG_ALPHABET := "0289PYLQGRJCUV"
## Kodun "məzmun" hissəsi. 14^8 ≈ 1.5 milyard: 10 000 oyunçuda iki eyni kod
## düşmə ehtimalı ~3%-dir. 9 simvol daha az olardı, amma kod əllə yazılır və
## hər simvol yazma səhvi deməkdir.
const TAG_BODY := 8
## Sonuncu simvol YOXLAMA simvoludur (Luhn mod N, bax [method _check_char]).
## Server yatandan sonra "belə oyunçu yoxdur" deyə bilmir — oflayn oyunçunu
## tanımır. Yoxlama simvolu isə yazma səhvini CLIENT-DƏ tutur: bir simvolu
## səhv yazılmış hər kod rədd edilir və sorğu heç vaxt boşluğa getmir.
const TAG_LEN := TAG_BODY + 1

## Komanda kodu: 6 simvol, bir-birinə bənzəyənlər yoxdur. Kod komanda
## yaşadıqca yaşayır (dəqiqələr) — oyunçu kodu kimi uzun olmağa ehtiyac yoxdur.
const CODE_ALPHABET := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LEN := 6

## Dost siyahısının həddi. Brawl Stars-da 200-dür; bizdə siyahı hər
## qoşulmada serverə gedir və 100 × 10 bayt paketi kiçik saxlayır.
const FRIEND_MAX := 100
## Komandada ən çox neçə nəfər: ÜÇLÜK-ün komandası.
const PARTY_MAX := 3
## Dəvət bu qədər saniyə keçərlidir. Brawl Stars-da da dəvət tez sönür:
## köhnə dəvət qəbul olunanda komanda artıq oyunda ola bilər.
const INVITE_TTL := 60.0
## Bağlantısı kəsilən üzv komandada bu qədər saniyə saxlanılır (bax
## [constant Lobby.REJOIN_GRACE] — eyni səbəb: mobil şəbəkədə qopma adi haldır).
const PARTY_GRACE := 30.0
## Son oyunçular siyahısının uzunluğu (bax [method Friends.add_recent]).
const RECENT_MAX := 20

## Dostun vəziyyəti. Sıra vacibdir: siyahı bu rəqəmə görə azalan sıralanır —
## oyuna qoşula biləcəyin dost yuxarıdadır.
enum Presence {
	OFFLINE = 0,
	MENU = 1,    ## Menyuda, tək — dəvət etmək olar
	PARTY = 2,   ## Menyuda, bir komandada
	GAME = 3,    ## Oyunda (matçda)
}


## Gizli açardan oyunçu kodu.
##
## Kod açardan HESABLANIR, serverdə saxlanılmır — ona görə server yuxudan
## oyananda da hər oyunçu öz koduna sahibdir. Açar cihazdan çıxmır (yalnız
## şifrəli `wss` ilə serverə gedir), kod isə hamıya açıqdır: başqasının kodunu
## bilmək onun adından danışmağa imkan vermir.
static func tag_of(secret: String) -> String:
	var hash := ("germ-arena-tag:" + secret).sha256_buffer()
	# İlk 7 bayt — 56 bit, int64-ə sığır. 14^8 ≈ 2^30.5, yəni bu bitlər
	# əlifbanın bütün kodlarını bərabər örtür.
	var v := 0
	for i in 7:
		v = (v << 8) | hash[i]
	var body := ""
	var n := TAG_ALPHABET.length()
	for i in TAG_BODY:
		body = TAG_ALPHABET[v % n] + body
		v /= n
	return body + _check_char(body)


## Luhn mod N yoxlama simvolu.
##
## Hər tək simvol səhvini və qonşu iki simvolun yerdəyişməsinin demək olar
## hamısını tutur — əllə yazılan kodun iki ən adi səhvi.
static func _check_char(body: String) -> String:
	var n := TAG_ALPHABET.length()
	var factor := 2
	var total := 0
	for i in range(body.length() - 1, -1, -1):
		var addend := factor * TAG_ALPHABET.find(body[i])
		factor = 1 if factor == 2 else 2
		total += addend / n + addend % n
	return TAG_ALPHABET[(n - total % n) % n]


## İstifadəçinin yazdığını kod formasına salır: `#`, boşluq və tire atılır,
## hərflər böyüdülür, `O` sıfıra çevrilir (əlifbada `O` yoxdur, amma oyunçu
## sıfırı tez-tez belə yazır). Nəticə yoxlanmır — bax [method is_tag].
static func clean_tag(raw: String) -> String:
	var s := raw.strip_edges().to_upper().replace("#", "").replace(" ", "").replace("-", "")
	return s.replace("O", "0")


## Kod düzgündürmü: uzunluq, əlifba və yoxlama simvolu.
static func is_tag(tag: String) -> bool:
	if tag.length() != TAG_LEN:
		return false
	for c in tag:
		if TAG_ALPHABET.find(c) < 0:
			return false
	return _check_char(tag.substr(0, TAG_BODY)) == tag[TAG_BODY]


static func clean_code(raw: String) -> String:
	return raw.strip_edges().to_upper().replace("#", "").replace(" ", "").replace("-", "")


static func is_code(code: String) -> bool:
	if code.length() != CODE_LEN:
		return false
	for c in code:
		if CODE_ALPHABET.find(c) < 0:
			return false
	return true


## Gizli açar: 16 təsadüfi bayt, hex. Cihaz onu bir dəfə yaradır və saxlayır.
static func new_secret() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## Açarın forması — server client-in göndərdiyinə İNANMIR.
static func is_secret(secret: String) -> bool:
	return secret.length() >= 16 and secret.length() <= 64 and secret.is_valid_hex_number()


## Rejimə neçə nəfərlik komanda ilə girmək olar.
##
## TƏK QALAN təkdir — Brawl Stars-da da Solo Showdown-a komanda ilə girmək
## olmur (orada birləşmək qadağandır). CÜT və ÜÇLÜK öz komanda ölçüsündədir.
## SONSUZ ARENA-da komanda yoxdur, amma dostlar EYNİ DÜNYAYA düşür — io
## oyunlarının "birlikdə oyna" rejimi budur.
static func party_limit(mode: int) -> int:
	match mode:
		Const.Mode.SOLO: return 1
		Const.Mode.DUO, Const.Mode.BALL: return 2
		Const.Mode.TRIO, Const.Mode.MOTHER, Const.Mode.ISLAND: return 3
		_: return PARTY_MAX


## Komanda böyüyəndə seçilmiş rejim ona SIĞMIRSA, sığan ən yaxın rejim.
##
## Brawl Stars bu halda sadəcə "komanda bu rejim üçün böyükdür" deyib OYNA-nı
## bağlayır və lider rejimi özü dəyişməlidir. Bizdə dəvəti qəbul etmək özü
## niyyətdir: tək oynayan dostunu çağırıbsa, birlikdə oynamaq istəyir. Ona görə
## rejim avtomatik uyğunlaşır — TƏK QALAN → CÜT → ÜÇLÜK. Lider onu yenə dəyişə bilər.
static func fit_mode(mode: int, size: int) -> int:
	if size <= party_limit(mode):
		return mode
	for m in [Const.Mode.DUO, Const.Mode.TRIO, Const.Mode.ENDLESS]:
		if size <= party_limit(m):
			return m
	return Const.Mode.ENDLESS


## Paylaşma linkinin kökü — oyunun veb versiyası.
##
## Server ünvanı `wss://host/ws`-dir və Render-də veb oyun EYNİ hostdadır
## (bax `deploy/render/`). Link telefonda brauzerdə açılır və oyun elə oradan
## komandaya girir; tətbiqdə isə kod əllə yazılır.
static func link_base(address: String) -> String:
	var a := address.strip_edges()
	if a.begins_with("wss://"):
		a = "https://" + a.substr(6)
	elif a.begins_with("ws://"):
		a = "http://" + a.substr(5)
	else:
		a = Const.DEFAULT_SERVER.replace("wss://", "https://")
	var slash := a.find("/", a.find("//") + 2)
	if slash > 0:
		a = a.substr(0, slash)
	return a + "/"


static func party_link(address: String, code: String) -> String:
	return "%s?party=%s" % [link_base(address), code]


static func friend_link(address: String, tag: String) -> String:
	return "%s?friend=%s" % [link_base(address), tag]


## Vəziyyətin oxunan adı.
static func presence_name(p: int) -> String:
	match p:
		Presence.MENU: return "Menyuda"
		Presence.PARTY: return "Komandada"
		Presence.GAME: return "Oyunda"
		_: return "Oflayn"


## "Son görülmə" — saniyədən insan dilinə: "5 dəq", "3 saat", "2 gün".
static func ago(seconds: float) -> String:
	var s := maxf(seconds, 0.0)
	if s < 90.0:
		return "indicə"
	if s < 3600.0:
		return "%d dəq əvvəl" % int(s / 60.0)
	if s < 86400.0:
		return "%d saat əvvəl" % int(s / 3600.0)
	return "%d gün əvvəl" % int(s / 86400.0)
