class_name AutoAim
extends RefCounted
## Avtomatik nişan — atəş düyməsinə QISA toxunuş (Brawl Stars kimi).
##
## Toxunuş topu ən yaxın görünən rəqibə yönəldir, amma QƏSDƏN dəqiq deyil:
##   • rəqibin İNDİKİ yerinə atır, getdiyi yeri qabaqlamır — hərəkət edən
##     rəqib çəkilib qaçır, yerində duranı isə vurur;
##   • hər atəşə kiçik təsadüfi xəta düşür ([constant ERROR]), uzaqda bu,
##     qaçırmaq deməkdir.
## Dəqiq atəş üçün oyunçu düyməni basılı saxlayıb sürüşdürür (bax [FireButton]):
## onda top barmağın göstərdiyi xətlə gedir və bu xətt ekranda çəkilir.
##
## Hamısı client-dədir: nişan bucağı onsuz da girişdə gedir
## ([member Sim.PlayerInput.aim]), server və proqnoz onu olduğu kimi götürür.
## Ona görə server dəyişmir və köhnə server yeni client-lə işləyir.
##
## Hədəf yalnız ekranda GÖRÜNƏN rəqiblərdən seçilir ([method Arena._aim_targets]):
## kolda gizlənəni server onsuz da göndərmir ([method World._near_germs]), yəni
## nişan heç kimi ifşa etmir; ekrandan kənardakına da atmır.

## Xətanın həddi, radian (≈ 10°). Paylanma üçbucaqdır (iki `randf`-in cəmi):
## çox vaxt hədəfə yaxın, nadir hallarda kənarda.
##
## Yerində duran başlanğıc rəqibə (radius 28, top 9) dəymə payı, hesabla:
## 300 px — ~91%, 400 px — ~78%, 600 px (ekranın kənarı) — ~58%. Hərəkət
## edəni isə qabaqlamadığı üçün çox vaxt qaçırır. Əvvəl 6° idi və QA 600 px-də
## 79% ölçdü — yəni avtomatik nişan dəqiq nişandan az fərqlənirdi.
const ERROR := 0.175
## Görünməyən (maneə arxasındakı) rəqibin cəriməsi — məsafənin
## [method reach] payı kimi. Rədd edilmirlər: başqa hədəf yoxdursa, oyunçu
## ekranda gördüyü rəqibə atdığını gözləyir.
const BLOCKED_PENALTY := 1.0


## Nişanın çatdığı məsafə — kamera ilə böyüyür (bax [method Const.view_span]).
## Bu, ekranın təxminən hündürlüyüdür: ondan uzaqdakı rəqibə top 1.5 s-dən
## çox uçur və avtomatik atəş onsuz da boşa gedərdi. Ekran şərti ayrıcadır
## ([method Arena._aim_targets]) — bu yalnız künclərdəki uzaq rəqibi kəsir.
static func reach(capacity: int) -> float:
	return Const.view_span(capacity)


## Ən yaxşı hədəf: [param targets] `{"key", "pos"}` sözlükləridir.
## Boşdursa və ya heç kim çatmırsa — boş sözlük (top getdiyin tərəfə gedir).
##
## [param sight] maneələri bilən simulyasiyadır (client-in proqnozu); `null`
## olanda görünmə yoxlanılmır.
static func pick(from: Vector2, targets: Array, max_reach: float, sight: Sim) -> Dictionary:
	var best := {}
	var best_score := INF
	for t in targets:
		var p: Vector2 = t["pos"]
		var d := from.distance_to(p)
		if d > max_reach:
			continue
		var score := d
		if sight != null and not sight.has_line_of_sight(from, p):
			score += max_reach * BLOCKED_PENALTY
		if score < best_score:
			best_score = score
			best = t
	return best


## Bir atəşlik xəta. Atəş başına BİR dəfə çəkilir, tick başına yox: BOŞLUQ
## basılı ikən istək bir neçə tick gözləyir və xəta orada titrəməməlidir.
static func roll_error(rng: RandomNumberGenerator) -> float:
	return (rng.randf() + rng.randf() - 1.0) * ERROR
