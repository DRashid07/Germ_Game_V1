class_name Palette
extends RefCounted
## Kod tərəfdən çəkilən elementlərin rəngləri.
##
## Dəyərlər `design/ART_BIBLE.md` sənədindən götürülüb. Mikrob bədəni,
## membran və nüvə tamamilə kodla çəkilir (ölçüsü tutumla dəyişir, ona görə
## sprite uyğun deyil) — rəng dəyişəndə həm bu fayl, həm ART_BIBLE yenilənməlidir.

# ---------- Petri qabı ----------
const BG_OUTER := Color("071012")      ## Qabın kənarındakı qaranlıq
const BG_VIGNETTE := Color("020708")   ## Bayırın uzaq hissəsi — gözü qaba çəkir
const DISH := Color("12262C")          ## Qabın döşəməsi — qaranlıq orta ton
const DISH_EDGE := Color("2B5963")     ## Qalxmış şüşə dodağın gövdəsi
const GRID := Color("1A3942")          ## Döşəmə şəbəkəsi və bevel işığı
const MUCUS := Color("16333B")         ## Maneə (selik) ləkəsi
const MUCUS_EDGE := Color("245562")
## Kolun gövdəsi — xəritənin V1 "Damla" dəsti bu rənglə çəkilib (sahib
## 2026-10-19-da təsdiqləyib). Əvvəlki parlaq `#4FCB72` laym (7CFF5B), nanə
## (4BFFA5) və yoldaş halqası (A6FF4D) ilə eyni yaşıl ailədə idi və HIGH-ın
## parlamasında saçırdı; bu ton nanənin TONUDUR (151° / 150°), amma xeyli tünd
## və solğundur (V 0.56) — döşəmənin ən parlaq yaşıl kütləsi qalır, saçmır.
## Kod tərəfdə yalnız xəritə stendi və minimap işlədir; oyunda kol atlasdandır.
const BUSH := Color("3E9068")
## Şüşə divarın işıq xətti — V1 divar zolağının üst xətti ilə eyni ton.
## Cənub dodağının kənarı və onun parıltıları bununla çəkilir.
const RIM_LINE := Color("8FD3D6")
const BRITTLE := Color("D09345")        ## Kövrək qabığın kəhrəba işarəsi
const VENT := Color("F0B94E")           ## Cərəyan deşiyinin isti xəbərdarlığı
const DRY_CRACK := Color("81785C")      ## Quru zonanın doymamış çatları
const STEAM := Color("B9D8D0")          ## Yüksək keyfiyyətdə quru sərhəd buxarı

## Bütün kodla çəkilən həcm üçün TƏK işıq istiqaməti. Ayrı istiqamətlər
## sınananda mikrobun sel-shading-i və maneələrin kölgəsi bir-birini təkzib
## edirdi; yuxarı-sol həm sprite işığına, həm də arena kamerasına uyğundur.
const LIGHT_DIR := Vector2(-0.45, -0.89)   ## normallaşdırılmış, yuxarı-sol

# ---------- Mikrob rəngləri ----------
## 10 nəfərlik dünyada hər mikroba bir rəng düşür. Rənglər həm tondan,
## həm parlaqlıqdan fərqlənir ki, rəng korluğunda da ayırd edilsin.
const GERM_COLORS: Array[Color] = [
	Color("7CFF5B"),   # 0 — laym
	Color("2FE8E0"),   # 1 — firuzəyi
	Color("FF5BC8"),   # 2 — magenta
	Color("FFB43D"),   # 3 — kəhrəba
	Color("A96BFF"),   # 4 — bənövşəyi
	Color("FF6B5B"),   # 5 — mərcan
	Color("4D9BFF"),   # 6 — göy
	Color("4BFFA5"),   # 7 — nanə
	Color("FF87A8"),   # 8 — çəhrayı
	Color("F2E14C"),   # 9 — qızılı
]

# ---------- Neytral ----------
const FOOD := Color("D9FFC0")          ## Yerdəki qida topu
const FOOD_CORE := Color("F6FFEE")
const OUTLINE := Color("04090B")
## Sel-shading-in açıq tonu üçün neytral ağ. Ağın kod daxilində ayrıca
## yazılması palitranın tək mənbə olmasını pozurdu.
const BODY_LIGHT := Color("FFFFFF")
## Zərbə örtüyü HDR həddini qəsdən keçir: glow onu bir anlıq işıq kimi tutur.
## Adi ağ sınandı, amma dolu mikrobda orqanellaları örtməyə gücü çatmadı.
const HIT_FLASH := Color(1.7, 1.7, 1.7, 1.0)

# ---------- UI ----------
const TEXT := Color("EAFBF6")
const TEXT_MUTED := Color("7FA0A0")
const PANEL := Color("0E1D22")
const PANEL_BORDER := Color("1F3D45")
const FOCUS := Color("FFD166")
## Yoldaşın adı və xəritə halqası — laym.
##
## Mikrob rənglərindən (bax [constant GERM_COLORS]) qəsdən KƏNARDADIR:
## yoldaş nişanı heç bir oyunçunun öz rəngi ilə qarışmamalıdır.
const ALLY := Color("A6FF4D")
## Ulti HAZIRDIR — düymədə və mikrobun aurasında EYNİ rəng.
##
## Mikrob rənglərindən kənardadır (qızılı 9 = F2E14C-dən daha isti və
## narıncıya yaxın): "super hazır" heç bir oyunçunun öz rəngi ilə qarışmamalıdır.
## Brawl Stars-da da ulti hər yerdə eyni sarı dildə deyilir — oyunçu onu bir
## dəfə öyrənir, sonra həm düymədə, həm rəqibin üstündə tanıyır.
const SUPER_READY := Color("FFC83D")
## Ana ekranın Brawl Stars dili (bax [ChunkyBox]).
##
## OYNA SARIDIR: Brawl Stars-da ekranın ən böyük obyekti — sarı düymə —
## oyunçunun gözünü öyrədib; bizim də ana ekranımız onun məntiqi ilə
## qurulub. [constant SUPER_READY]-dən qəsdən AYRIDIR (daha soyuq, limona
## yaxın): super düyməsi menyuda görünmür, amma iki rəng eyni olsaydı, "super
## hazırdır" dili oyunçunun gözündə adi düymə ilə qarışardı.
const MENU_PLAY := Color("FFD83B")
## Sol lentin və rejim kartının mavisi — Brawl Stars düymələrinin mavisi,
## bizim firuzəyi qaba doğru çəkilib ki, fon şəkli ilə mübahisə etməsin.
const MENU_BLUE := Color("1F95D6")
## Məlumat panelləri (profil, server nişanı, ad lövhəsi) — tünd göy-firuzəyi.
## Düymə deyil, ona görə doymuş deyil: göz basılası şeyləri ondan ayırır.
const MENU_PANEL := Color("0E3346")
const SAFE := Color("52E08A")
const DANGER := Color("FF4757")
const WARNING := Color("FFB020")


## Mikrobun əsas rəngi. İndeks dünyada boş qalan rəng yuvasından gəlir.
static func germ_color(color_index: int) -> Color:
	return GERM_COLORS[posmod(color_index, GERM_COLORS.size())]


## Membran işığı — əsas rəngin açıq variantı.
static func germ_light(color_index: int) -> Color:
	return germ_color(color_index).lerp(BODY_LIGHT, 0.45)


## Kölgə/kontur — əsas rəngin tünd variantı.
static func germ_shadow(color_index: int) -> Color:
	return germ_color(color_index).lerp(OUTLINE, 0.55)


## Doluluq göstəricisinin rəngi: boşalanda sarı, dolanda qırmızı.
## [param fill] 0..1 — mövcud top sayının tutuma nisbəti.
static func fill_color(fill: float) -> Color:
	if fill >= 0.85:
		return DANGER
	if fill <= 0.30:
		return WARNING
	return SAFE
