# Germ Arena — canlı oyun sınağı hesabatı (2026-11-22)

Versiya: `main` @ `49751d3` (Render-dəki ilə eyni), Godot 4.7.2, Windows masaüstü, 1280×720.
Sübut şəkilləri: [docs/qa_2026-11-22/](qa_2026-11-22/). İstifadə olunan alət: [tools/live_qa/](../tools/live_qa/README.md).

## 0. Düzəlişlər (eyni gün, sahibin seçdiyi bəndlər)

| Bənd | Nə dəyişdi | Necə yoxlandı |
|---|---|---|
| Xəta 1 — CÜT "kölgə" mikrob | Mikrob snapshot-dan düşəndə client gözləməyə keçir: idarə bağlı, öz mikrob görünmür, proqnoz yerində donur, mərkəzdə 15→1 sayğac və "Yoldaşın sağdır — səni diriltəcək"; server gözləyənin görüş sahəsini ölüm yerinə qurur | Canlı: gözləmədə atəş açılmır (top sayı 10-da qalır), sayğac 14→1, dirilmədə yazı itir, mikrob 6/10 ilə qayıdır; `_test_duo_revive_eye` |
| Xəta 2 — ÜÇLÜK menyuya atırdı | Ölən insan matçda qalır, yoldaşını izləyir ("İZLƏYİRSƏN · Vibrio · növbəti raundda qayıdırsan"), növbəti raundda öz komandasında doğulur; matçın sonunda komanda nəticəsi ("QALİB! · RAUND 2 — 0"). Qaydalar versiyası 5 → 6 | Canlı məşqdə və onlayn (yeni server): 1-ci raundda öldüm, komanda raundu mənsiz qazandı, 2-ci raundda qayıtdım, QALİB 2—0; izlənən yoldaş ölüncə kamera növbətisinə keçdi; `_test_trio_death_waits_round` (11 yoxlama) |
| Xəta 5 (yan təsir) | Ölüb gözləyəndə (CÜT, ÜÇLÜK və obyekt rejimləri) "DOLURSAN — TOP AT!" yazısı susur, SUPER hazır yanmır, atəş düyməsi sönük | Canlı şəkil |
| Özəllik 2 — server ünvanı | Ayarlarda gizlidir; versiya yazısına 5 dəfə toxunanda və ya saxlanan ünvan standart deyilsə görünür; QA agenti onu özü açır | Canlı: 4 toxunuşda gizli, 5-cidə açıldı; `_test_server_field_hidden` |
| Özəllik 3 — komanda rejimlərində cədvəl | CÜT, ÜÇLÜK, ANA, ADA, NÜVƏ TOPU-da gizlidir, minimap onun yerinə qalxır (251 → 82 px); SONSUZ və TƏK QALAN-da qalır | `_test_board_hidden_in_team_modes`, canlı şəkillər |
| Özəllik 7 — paketə test kodu | Play Store paketindən bütün `scripts/tools`, test APK və vebdən test dəstləri, agent, stendlər; hamısından köhnə menyu və 3D prototip çıxarıldı. Ölçmə probe-ları test APK-da və vebdə qalır (emulyator və brauzer ölçmələri onlara bağlıdır). Windows və Linux Server dəyişməyib | Hər profilin `--export-pack`-i: paketdə adlar yoxlandı, `--main-pack` ilə menyu və ÜÇLÜK məşqi xətasız; Release 14.92 → 14.36 MB |

İkinci dəstə (xəta 3–10):

| Xəta | Nə dəyişdi | Necə yoxlandı |
|---|---|---|
| 3 — YAŞ ADA "100 xal" | Başlanğıc yazısının rəqəmləri sabitlərdən (`ISLAND_WIN`, `BALL_GOALS`) | Canlı: "Adada çox ol — 70 xal udur"; `_test_mode_goal_numbers` |
| 4 — ANA sayımda boşalır | Geri sayımda metabolizm, quru zonanın topu və Anadan əmmə donur (`Sim.economy_paused`) | Canlı: sayımın 1.0/2.0/2.9-cu saniyəsində iki Ana da 70; `_test_countdown_economy_frozen` |
| 5 — ölü ikən köhnə HUD | Xəbərdarlıq susur, SUPER hazır yanmır, atəş sönük; joystik və göstərici solğunlaşır (gizlənmir — barmağını saxlayan doğulan kimi yeriyir) | Canlı şəkil (ANA, "Bazanda yenidən doğulursan"); `_test_hud_wait_and_top` |
| 6 — yuxarıda üst-üstə | Obyekt lövhəsi görünəndə FPS və "ZƏİF BAĞLANTI" onun altına enir | Canlı: NÜVƏ TOPU-nda "240 FPS" "QOL 2:19"-un altında; test |
| 7 — yalançı "ZƏİF BAĞLANTI" | Səbəb: sayımda server girişi qəbul etmir, təsdiq (ACK) donur; oyun başlayanda və mikrob dünyaya qayıdanda təsdiq saatı sıfırlanır | Onlayn, lokal server: sayım → oyun keçidində fasiləsiz ölçmədə nişan bir dəfə də yanmadı (əvvəl BAŞLADI-da yanırdı) |
| 8 — məşqdə çıxış təsdiqi | MƏŞQ-də təsdiq açıq ikən dünya dayanır (onlayn dəyişməyib) | Canlı: 3 s ərzində tick 271 → 271, DAVAM ET-dən sonra işləyir |
| 9 — yeni oyunçu sayğacı | Yalnız onlayn, 20 s oynanan və ya ölüm/nəticə ilə bitən matç sayılır; məşq və dərhal çıxış sayılmır | Kod + mövcud sayğac testi |
| 10 — izahlar | Mərkəz mesajlarının taymeri yalnız ÖZ mesajını silir (əvvəl 2 s-lik köhnə taymer yeni mesajı da silirdi); "DÜNYAYA GİRDİN", "GİZLƏNDİN", məqsəd cümləsi 3 s; membran izahı sakit lövhədə, aşağı-ortada, girişdən sonra, 5 s, növbə ilə; telefonda "superin üstündəki düymə", masaüstündə "E və ya …" | Canlı (təmiz profil): giriş mesajı 3 s, sonra ayrıca membran lövhəsi; `_test_hud_wait_and_top` |

Testlər: `--simtest` 1032 → 1047 → **1056 keçdi, 0 uğursuz**; `--objtest` **119/0**.

Qeyd: düzəlişlərin canlı sınağında bir dəfə ÜÇLÜK məşqində ölümdən ~3 s sonra arena səbəbsiz menyuya qayıtdı (nəticə ekranı yox idi). Eyni ardıcıllıq sonra 4 dəfə (2 məşq, 1 tam matç, 1 onlayn) təkrarlanmadı, loqda xəta yoxdur, səbəbi tapılmayıb.

## 1. Necə yoxlandı

| Nə | Necə | Nəticə |
|---|---|---|
| Canlı oyun (özüm) | Oyuna əmrlə idarə olunan sürücü yazdım: toxunuş joystiki, atəş, nişanlı atəş, super, membran, ESC, menyu klikləri, mətn yazmaq — hamısı oyunçunun yolundan (`push_input`). Arena əmrlər arasında donur, hər addımdan sonra ekran şəklinə baxdım. Təmiz profil (yeni oyunçu kimi), sahibin `settings.cfg`-sinə toxunulmayıb. | 6 sessiya, ~1.5 saat oyun |
| Oynanan rejimlər | SONSUZ ARENA (Kirpikli, məşq + onlayn), ANA HÜCEYRƏ (Amöb, tam matç), YAŞ ADA (Ayaqlı, tam matç, 70—23 qələbə), NÜVƏ TOPU (Kirpikli, tam matç 0—1 + onlayn), CÜT (ölüm/dirilmə) | aşağıda |
| Avtomatik QA agenti (mövcud `PlayAgent`) | 6 qaçış × 2 raund: TƏK QALAN, CÜT, ÜÇLÜK, YAŞ ADA, NÜVƏ TOPU, SONSUZ (hər üç növ) | 0–1 problem hər qaçışda (aşağıda) |
| Avtomatik testlər | `--simtest` | **1032 keçdi, 0 uğursuz** |
| Şəbəkə | Lokal server + 3 avtomatik client: dostluq sorğusu → qəbul → komandaya dəvət → eyni CÜT dünyası; qopub nişanla qayıtma; matçın ortasında serveri öldürmək | hamısı işlədi |
| Menyu | MAĞAZA/DNT/PASS, MİKROBLAR + növ səhifəsi + SEÇ, rejim vərəqi, AYARLAR (keyfiyyət, kadr həddi, FPS, sol əl, ünvan, sıfırla), DOSTLAR (kod, KOPYALA, son oyunçular, komanda yarat/çıx), ad dəyişmə (16 simvol həddi işləyir), «+» yuvası | aşağıda |
| Veb (canlı sayt) | germ-arena.onrender.com açıldı, mühərrik yükləndi, canlı serverə qoşuldu | yüklənir; brauzer paneli gizli olduğu üçün orada oynanmadı |

**Oyunun öz loqlarında heç bir skript/mühərrik xətası yoxdur** (bütün sessiyalarda 0; s5-dəki 18 xəta mənim alətimin `eval` sınaqlarındandır).

Sınanmayanlar: APK / Android cihaz və emulyator, iOS, səs, təmiz performans ölçüsü (agentin kadr sıçrayışları PNG yazılışını da sayır), mutasiya profili, membranın real vaxtda topu qaytarması (yalnız unit testlərlə).

## 2. Xülasə

| Ciddilik | Say |
|---|---|
| Yüksək | 2 |
| Orta | 8 |
| Aşağı | 6 |
| Lazımsız / mənasız özəllik | 8 |

## 3. Xətalar və problemlər

### Yüksək

**1. CÜT: ölüb dirilməni gözləyən oyunçu ekranda sağ "kölgə" mikrobu idarə edir.**
- Addımlar: CÜT, MƏŞQ → yoldaş sağ ikən partla.
- Gözlənilən: partlama, "yoldaşın sağdır — 15 s sonra dirilirsən" sayğacı, idarə bağlı.
- Baş verən: serverdə mikrob yoxdur (`World._revive`-dədir, 15 s), ekranda isə mikrob sağdır, gəzir, **atəş açır** və HUD-da top sayı azalır (10 → 4) — bu toplar serverdə mövcud deyil. Heç bir yazı yoxdur. 15 s sonra mikrob xəbərdarlıqsız xəritənin o biri ucuna sıçrayır (943,−172 → −637,715), 5/10 ilə.
- Səbəb: `Arena._own_dead()` yalnız obyekt rejimlərində doğrudur ([arena.gd:1417](../game/scripts/client/arena.gd)); CÜT-ün dirilmə növbəsi ([world.gd:1209](../game/scripts/server/world.gd)) client-də nəzərə alınmır. Onlayn da eyni kod işləyir.
- Şəkillər: `01_cut_olu_ikən_kölgə_mikrob.png`, `02_cut_dirilmə_sıçrayış.png`.

**2. ÜÇLÜK: ölən oyunçu 1-ci raunddan sonra menyuya atılır — 3 raund formatı insan üçün işləmir.**
- Agentin hər iki ÜÇLÜK raundunda: ölüm → "4-cü YER · RAUND HESABI 0 — 0 · Menyuya qayıdılır…".
- Rejimin vədi "üç raundun ikisini udan qalib" və "raund arası hamı yenidən doğulur"dur, amma ölən oyunçu 2-ci və 3-cü raundu görmür, komandası onsuz (botlarla) davam edir. Komanda rejimində fərdi "N-ci YER" də mənasızdır.
- Bu, design/MODES.md-dəki qərardan gəlir ("Öləndən sonra izləmə? Yox — dərhal menyuya"), amma rejimin əsas ideyası ilə ziddiyyət təşkil edir.
- Şəkil: `03_üçlük_ölüm_menyuya_atır.png`.

### Orta

**3. YAŞ ADA: başlanğıcda "Adada çox ol — 100 xal udur" yazılır, qələbə həddi isə 70-dir.**
[constants.gd:1167](../game/scripts/shared/constants.gd) mətni vs `ISLAND_WIN := 70` (sətir 676). Nəticə ekranı düzgün "70 xala ilk çatan udur" yazır — oyunçu iki fərqli rəqəm görür.

**4. ANA HÜCEYRƏ: geri sayımda (oyun başlamamış) Ana boşalır.**
Sayım "3"-də öz Ana 69, "2"-də 67, rəqibinki 70; BAŞLADI anında ikisi də 66. Yoldaş botlar Anaya toxunaraq doğulur və sayım boyu top əmir, metabolizm də işləyir. Səbəb: sayımda `sim.step` tam işləyir, yalnız giriş sıfırlanır ([world.gd:1126–1143](../game/scripts/server/world.gd)); `_suck` toxunuşla işləyir ([sim.gd:863](../game/scripts/shared/sim.gd)). Başlanğıc qeyri-bərabərdir. Şəkil: `04_ana_geri_sayımda_boşalır.png`.

**5. Obyekt rejimlərində ölüb bazada doğulmanı gözləyəndə HUD köhnə vəziyyəti göstərir.**
"Bazanda yenidən doğulursan 3…" yazısı ilə eyni anda qırmızı "15/15 DOLURSAN — TOP AT!", hazır yanan SUPER düyməsi və joystik görünür. Ölü oyunçuya "top at" deyilir. Həm mənim oyunumda, həm agentin YAŞ ADA qaçışında. Şəkil: `05_ölü_ikən_hud_köhnə.png`.

**6. Yuxarı-mərkəzdə yazılar üst-üstə düşür (obyekt rejimləri).**
- Kadr sayğacı (FPS) açıq olanda o, "QOL/XAL/ANA + vaxt" yazısının üstünə düşür: ölçülmüş yerlər FPS (570,10 140×24), obyekt yazısı (576,8 128×57) — ekranda "2QOLPS" kimi oxunmaz qarışıq.
- "ZƏİF BAĞLANTI" yazısı (480,36 320×34) də eyni sahəni örtür.
- Şəkillər: `06_fps_qol_üst_üstə.png`, `07_zəif_bağlantı_lokal_server.png`.

**7. Onlayn matçın ilk anında yalançı "ZƏİF BAĞLANTI".**
Lokal serverdə (0 ms gecikmə) NÜVƏ TOPU-na girəndə BAŞLADI anında (matçın 0.9-cu saniyəsində) "ZƏİF BAĞLANTI" yanır, növbəti yoxlamada (bir neçə saniyə sonra) artıq yox idi. Səbəb ehtimalən arenanın yüklənməsi zamanı snapshot boşluğudur — matçın ilk saniyələrində bu yoxlama üçün güzəşt lazımdır.

**8. MƏŞQ-də "MATÇDAN ÇIXIRSAN?" açıq ikən dünya dayanmır.**
Təsdiq açıq ikən 3 saniyədə 2 zərbə aldım, joystik isə buraxılıb (mikrob tərpənmir). Onlayn bu qaçılmazdır, amma oflayn məşqdə dünyanı dondurmaq mümkündür — oyunçu "davam et"i düşünərkən ölür.

**9. Yeni oyunçu qoruması (ilk 10 matç) oflayn məşqdə xərclənir.**
`Settings.note_match()` hər arena açılışında çağırılır ([arena.gd:844](../game/scripts/client/arena.gd)) — menyudakı MƏŞQ də, girib dərhal çıxmaq da "matç" sayılır. Yeni oyunçu məşqdə bir neçə dəfə sınayandan sonra onlayn ilk matçlarında qoruma qalmır.

**10. Giriş izahları çox qısadır və bir-birinin üstünə düşür.**
- İkinci girişdə "GİZLƏNDİN / Kolun içində rəqiblər səni görmür" (mərkəz) və membran izahı eyni anda çıxdı, ikisi də 1.9 s-də itdi (`HINT_TIME := 2.0`). Uzun cümləni 2 saniyədə oxumaq olmur.
- Membran izahı **qırmızı xəbərdarlıq rəngində**, kiçik şriftlə, göstəricinin altında çıxır — təhlükə kimi görünür.
- Mətn "MEMBRAN **(E)**: …" — telefonda (əsas hədəf APK) E düyməsi yoxdur ([arena.gd:1407](../game/scripts/client/arena.gd)); ekrandakı hansı düymə olduğunu da göstərmir (ikonu mücərrəd qövsdür).
- Şəkil: `08_giriş_izahları_üst_üstə.png`.

### Aşağı

**11. KOPYALA bildirişi fonsuzdur və SON OYUNÇULAR siyahısının ilk sətrinin üstünə düşür** — "KOPYALANDI / Oyunçu kodun: #…" ilə "B · #…" bir-birinə qarışır. Şəkil: `09_kopyalandı_siyahı_üstündə.png`.

**12. "AYARLARI SIFIRLA" təsdiq soruşmur** — səs, keyfiyyət, kadr həddi, sol əl düzümü və server ünvanı bir toxunuşla sıfırlanır.

**13. CÜT nəticə ekranı uyğunsuzdur.** "4-cü YER · 10 mikrobdan": yoldaşın ölümü ilə dirilmə ləğv olunanda yer **cütlərlə** sayılır ([world.gd:514](../game/scripts/server/world.gd) `_teams_standing() + 1`), mətn isə "10 mikrobdan" deyir. "Yaşadın: 0:03" — dirilmədən sonrakı vaxtdır, bütün matç yox.

**14. Amöb ANA rejimində rəqib Anasının üstünə nişan alanda atəş səssizcə açılmır.** Damcı bərk maneənin (Ananın) içinə düşürsə atəş qadağandır (`Sim.lob_valid`) — bu qaydadır, nişan xətti qırmızı olur, amma buraxanda heç bir bildiriş və səs yoxdur. Rejimin hədəfi Ana olduğu üçün yeni oyunçu "atəş işləmir" düşünür; yalnız Ananın kənarına atanda işləyir (yoxlandı: 57 → 58).

**15. Android-in GERİ jesti ana ekranda təsdiqsiz oyundan çıxır** ([menu_v2.gd:840](../game/scripts/client/menu_v2.gd)). Kod oxunub, cihazda sınanmayıb.

**16. Agentin 3 qaçışında bir dəfə: atəş düyməsi basıldı, top xərcləndi, soyuma başladı, amma agent 0.8 s-də çıxış effektini görmədi.** Hər dəfə Kirpikli/Amöb, 1/22–1/59 atəş. Ehtimalən agentin aşkarlama boşluğudur (top atılıb) — təsdiqlənməyib.

### İşləyənlər (problem tapılmayanlar)
Yemək/tutum/aclıq, "DOLURSAN — TOP AT!" və "ACSAN — QİDA YE!" xəbərdarlıqları, nişanlı və avtomatik atəş, üç növün superi (trixosist, tor, miniqan — miniqanda toplar pulsuzdur), membranın qiyməti və soyuması, kol, partlama → nəticə → menyu, ESC → DAVAM ET / ÇIX, obyekt rejimlərində bazada doğulma və nəticə ekranları, sol əl düzümü, MİNİMUM keyfiyyət (30 FPS), dostluq/komanda axını, yenidən qoşulma (5 cəhd → "BAĞLANTI BƏRPA OLUNMADI" → menyu), qopan client-in nişanla qayıtması.

## 4. Lazımsız və ya mənasız özəlliklər

1. **Ana ekranda 6 boş element**: MAĞAZA, MİKRO PASS ("Səviyyə 1" + boş zolaq), TAPŞIRIQLAR, QİDA (0), DNT (0) və yanındakı "+". Hamısı yalnız "… — TEZLİKLƏ!" deyir və ana ekranın böyük hissəsini tutur. Sistem gələnə qədər gizlətmək daha düzgündür. Şəkil: `10_menyu_boş_düymələr.png`.
2. **"Server ünvanı" sahəsi oyunçu ayarlarındadır** — bu test alətidir; oyunçu onu təsadüfən pozub oynaya bilmir. Yanında texniki mətnlər də var ("Kliplərin öz tarazlığı qorunur — sürgü hamısını bərabər çəkir", "Godot 4.7.2"). Şəkil: `11_ayarlar_server_ünvanı.png`.
3. **Komanda/obyekt rejimlərində fərdi "partlatma" cədvəli** (ANA, ADA, NÜVƏ TOPU, CÜT, ÜÇLÜK): nəticəni hesab həll edir, cədvəl isə sağ yuxarını tutur və minimapla birlikdə meydanı örtür (NÜVƏ TOPU-da Nüvə və döyüş məhz o küncdə idi). Şəkil: `12_nüvə_topu_cədvəl_minimap.png`.
4. **7 rejim kiçik oyunçu bazası üçün çoxdur.** Pulsuz server ~2 dünyanı rahat saxlayır, boş yerləri botlar tutur; TƏK QALAN / CÜT / ÜÇLÜK bir-birinə çox bənzəyir, ÜÇLÜK isə (xəta 2) insan üçün faktiki bir raunddur. 3–4 rejimə endirmək oyunçuları bir yerə yığar.
5. **Membran müdafiəsi (SONSUZ ARENA)**: əlavə düymə və izah, 0.18 s pəncərə. Oynadığım müddətdə bir dəfə də faydası olmadı; izahı oxumağa vaxt yoxdur (xəta 10). "Rəy mərhələsi"dir — saxlamazdan əvvəl istifadə sayını ölçmək lazımdır.
6. **"Səviyyə N" yazısı** göstəricinin (10/15/20…) altında tutumu təkrarlayır, ayrıca məna daşımır.
7. **Buraxılış paketinə test və prototip kodu düşür**: bütün ixrac profillərində `export_filter="all_resources"`, yalnız `build/*` çıxarılır. APK və vebə köhnə menyu (`main_menu.tscn`, `--menu1`), 3D prototip (`assets/proto3d`, `germ3d_stand.gd`), `sim_test.gd` (6783 sətir), `play_agent`, bütün probe-lar daxildir.
8. **Eksperimental mutasiyalar**: standartda söndürülüb, amma kodu və kart UI-ı hər buildədir, `build/`-də ayrıca `.bat` var — ya oyuna daxil edilməli, ya da ayrılmalıdır.

## 5. Tövsiyə olunan ardıcıllıq

1. CÜT kölgə mikrobu: dirilmə gözləməsini obyekt rejimlərindəki kimi `_own_dead()`-ə daxil et, idarəni bağla, sayğac göstər (xəta 1).
2. ÜÇLÜK: ölən oyunçunu növbəti raunda qədər saxla (sadə izləmə: kamera yoldaşda) və ya rejimi tək raunda endir (xəta 2).
3. "100 xal" → `Const.ISLAND_WIN` (xəta 3).
4. Sayımda Ananı əmmək və metabolizmi dondur (xəta 4).
5. HUD: ölü ikən göstərici/xəbərdarlıq/super gizlənsin; FPS və "ZƏİF BAĞLANTI" obyekt yazısından ayrılsın; matç başında bağlantı yoxlamasına güzəşt (xəta 5–7).
6. Məşqdə çıxış təsdiqi dünyanı dondursun; yeni oyunçu sayğacı yalnız onlayn matçları saysın (xəta 8–9).
7. İzahlar: 4–5 s, növbə ilə, neytral rəngdə, telefonda "E" yox, düyməni göstərən ox (xəta 10).
8. Boş menyu elementlərini və server ünvanını gizlət, ixrac filtrinə `scripts/tools/*`, `assets/proto3d/*`, köhnə menyunu əlavə et (bölmə 4).

Əlavə təklif: nəticə ekranından sonra oyun 4–7 s gözləyib avtomatik menyuya qayıdır; "YENİDƏN OYNA" düyməsi io oyununda yenidən girişi 3 toxunuşdan 1-ə endirər.
