class_name Palette
extends RefCounted
## Kod tərəfdən çəkilən elementlərin rəngləri.
##
## Dəyərlər `design/ART_BIBLE.md` sənədindən götürülüb. Mikrob bədəni,
## membran və nüvə tamamilə kodla çəkilir (ölçüsü tutumla dəyişir, ona görə
## sprite uyğun deyil) — rəng dəyişəndə həm bu fayl, həm ART_BIBLE yenilənməlidir.

# ---------- Petri qabı ----------
const BG_OUTER := Color("071012")      ## Qabın kənarındakı qaranlıq
const DISH := Color("0C1A1E")          ## Qabın döşəməsi
const DISH_EDGE := Color("1E4650")     ## Şüşə kənar
const GRID := Color("122A31")          ## Döşəmə şəbəkəsi
const MUCUS := Color("16333B")         ## Maneə (selik) ləkəsi
const MUCUS_EDGE := Color("245562")

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
const SAFE := Color("52E08A")
const DANGER := Color("FF4757")
const WARNING := Color("FFB020")


## Mikrobun əsas rəngi. İndeks dünyada boş qalan rəng yuvasından gəlir.
static func germ_color(color_index: int) -> Color:
	return GERM_COLORS[posmod(color_index, GERM_COLORS.size())]


## Membran işığı — əsas rəngin açıq variantı.
static func germ_light(color_index: int) -> Color:
	return germ_color(color_index).lerp(Color.WHITE, 0.45)


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
