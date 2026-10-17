# Germ Arena

Onlayn **io tipli** mikrob arenası. Mobil (Android) üçün, **yatay** ekranda.
10 nəfərlik sonsuz petri qabı: girirsən, yeyirsən, böyüyürsən — partlayanda çıxırsan.

- **Format:** matç yoxdur, növbə yoxdur. Düyməni basan kimi dünyadasan.
- **Hərəkət:** telefonda sol barmaq üzən joystick, sağ aşağıda top atma düyməsi
- **Super:** hər növün öz gücü — atəş düyməsinin üstündəki halqa dolanda basılır
- **PC-də:** `WASD` / ox düymələri hərəkət, `BOŞLUQ` top atır (avtomatik nişanla)
- **Nişan:** Brawl Stars kimi — atəş düyməsinə **toxun**: top ən yaxın rəqibə
  gedir, amma dəqiq deyil. **Basılı saxla və sürüşdür**: nişan xətti çıxır,
  buraxanda top məhz o xətlə gedir (bax [«Nişan»](#nişan--toxun-və-ya-sürüşdür))
- **Ekran:** yatay, 1280×720 baza — telefon kilidlənir, brauzerdə portret
  pəncərədə "telefonu yan çevir" örtüyü çıxır
- **Motor:** Godot 4.7.2 · **Dil:** GDScript · **Şəbəkə:** server-authoritative

## Oyunun qaydası

Mikrobun içindəki top sayı həm **sursat**, həm **candır**:

```
        ┌──────────────────────────────────────────────┐
        │  SƏN 7/10        top at →○          RƏQİB 8/10│
        │  ↓ 6/10                             ↓ 10/10  │
        │                  top at →○                   │
        │  ↓ 5/10                             ↓ 💥 12/10│
        │                                              │
        │  Sənin tutumun:  10 → 15  (+5)               │
        └──────────────────────────────────────────────┘
```

| Hadisə | Nəticə |
|---|---|
| **Top atırsan** | səndə −1, dəydiyi rəqibdə **+2** (top içəridə bölünür) |
| **Top haradan çıxır** | mikrobun **öz içindən** — membranı yararaq |
| **Rəqibin sayı tutumu aşır** | rəqib **partlayır**, sən **+5 tutum** alırsan |
| **Sənin sayın 2-dən aşağı düşür** | **acından partlayırsan** — heç kim hesab almır |
| **Qida yeyirsən** | +1 (tutumun doludursa yemirsən) |
| **Metabolizm** | hər ~6 saniyəyə bir top yanır — yemək məcburidir |

Üç nəticə:

1. **Hücum risklidir** — hər atəş səni ölüm həddinə yaxınlaşdırır.
2. **Zəifi vurmaq mənasızdır** — verdiyin toplar onun sursatına çevrilir.
   Doğru hədəf **dolu** rəqibdir.
3. **Dolan oyunçu top ataraq boşala bilər** — saniyədə bir top. Sənin atdığın
   içəridə ikiyə bölündüyü üçün hücum edən saniyədə xalis +1 qazanır:
   partlatmaq mümkündür, amma vaxt və dəqiqlik istəyir.

Böyüməyin qiyməti var: tutum artdıqca mikrob **böyüyür** (iri hədəf),
**yavaşlayır** və **daha tez acır**. Lider sonsuz böyüyə bilmir.

### Qab su ilə doludur

Mikrob quru döşəmədə sürüşmür — **maye içində üzür**, və bu, görüntü deyil,
simulyasiyanın bir hissəsidir:

| | Nə edir |
|---|---|
| **İtələmə / müqavimət** | Barmağını qaldıranda mikrob dərhal dayanmır, ~1 saniyə sürüşür. Geri təpmə də ona görə əsl manevr vasitəsidir. |
| **Axın** | Qabda yavaş burulğanlar var. Hər şey — mikroblar da, yerdəki qida da — onlarla birlikdə sürüşür. |
| **Yapışma qatı** | Şüşəyə yaxın maye dayanır, ona görə axın heç nəyi divara sıxmır. |

Axın sahəsi YALNIZ mövqedən asılıdır (vaxtdan yox) və **divergensiyasızdır**:
bu iki xassə təsadüfi deyil — birincisi olmasa client-in proqnozu serverlə
uyuşmazdı, ikincisi olmasa qida burulğanların mərkəzinə yığılıb ilişərdi.
Kod: [`Const.current_at`](game/scripts/shared/constants.gd).

Üçüncü xassə isə tamamilə **qavrayışla** bağlıdır: burulğanın dalğa uzunluğu
(430 px) ekranın enindən (620 px) KİÇİK olmalıdır. Böyük olsa ekrandakı bütün
zərrəciklər eyni tərəfə baxır və oyunçu fırlanmanı görmür — riyaziyyat düzgün
işləsə də effekt yox olur. İlk versiyada məhz belə idi (760 px, orta sürət
BASE_SPEED-in 6.7%-i); indi orta sürət 11%-dir və testlə qorunur.

### Xəritə interaktivdir

Maneə `Vector4(x, y, radius, kind)`-dır. Toqquşma həndəsəsi hər növdə eynidir
— dairə — amma QAYDA fərqlidir:

| Növ | Mikrob | Top | Xüsusi |
|---|---|---|---|
| **SELİK** | bloklayır | sıçrayır | — |
| **KOL** | keçir | keçir | içindəki mikrob **GİZLİDİR** |
| **KÖVRƏK** | bloklayır | **sındırır** | 3 zərbədən sonra dağılır, yol açılır |
| **CƏRƏYAN** | keçir | keçir | **mərkəzə doğru itələyir** |

Növ [`DishMap`](game/scripts/shared/dish_map.gd)-dədir, yəni PAYLAŞILAN
koddadır: client proqnozu ilə server eyni qaydanı icra etməlidir, əks halda
mikrob client-də keçdiyi yerdən serverdə keçə bilməz və düzəliş onu geri
sıçradar.

**Gizlənmə YALNIZ serverdə mövcuddur.** Kolun içindəki mikrobun mövqeyi
rəqiblərə **göndərilmir** ([`World._near_germs`](game/scripts/server/world.gd)).
Client-də gizlətmək gizlənmə olmazdı: paket onsuz da şəbəkədə gedir və onu
oxuyan hər kəs mikrobu görər. Eyni kolun içindəki iki oyunçu isə bir-birini
görür — yoxsa kolda toqquşub bir-birini heç vaxt tapa bilməzdilər.

> **Böyük mikrob kiçik kolda gizlənə bilmir.** Bu, oyunun öz qaydasının
> davamıdır: böyümənin qiyməti var — iri hədəf, yavaş hərəkət, tez acma, və
> indi bir də gizlənə bilməmək. Lider kolda oturub oyunu dondura bilmir.

**Dağılan qabıq bərpa olunmur** — dünya oyun getdikcə AÇILIR. Vəziyyət hər
snapshot ilə tam gedir (maneə başına bir bayt, `Const.Snap.WALLS`), fərq kimi
yox: fərq göndərilsəydi bir itən paket client-i əbədi səhv vəziyyətdə qoyardı.

Düzümü yuxarıdan görmək üçün — stend maneələri OYUNDAKI sprite-larla çəkir,
yəni bir kadrda beş sprite-ın da həqiqi görkəmi yoxlanılır:
```bash
GODOT --path game --resolution 760x760 -- --map --map-layout 0 \
      --shot C:/yol/kadr.png --shot-delay 60
```

### Nişan — toxun və ya sürüşdür

Atəş düyməsi Brawl Stars-ın atəş joystickidir
([`FireButton`](game/scripts/client/fire_button.gd)):

| Hərəkət | Nə olur |
|---|---|
| **Qısa toxunuş** | **Avtomatik nişan** — top ən yaxın GÖRÜNƏN rəqibə gedir. Hədəfin üstündə bir anlıq kilid çərçivəsi çıxır |
| **Basılı saxla + sürüşdür** | Düymə joystickə çevrilir, dünyada **nişan xətti** çəkilir — səkmə ilə birlikdə. Barmağı qaldıranda top o xətlə gedir |
| **Sürüşdür, mərkəzə qaytar, burax** | **Ləğv** — heç nə atılmır (fikrini dəyişənin yolu) |
| `BOŞLUQ` / `ENTER` (PC) | Avtomatik nişanla atəş; basılı saxlananda saniyədə bir |

Avtomatik nişan **qəsdən dəqiq deyil** ([`AutoAim`](game/scripts/client/auto_aim.gd)):

- rəqibin **indiki** yerinə atır, getdiyi yeri qabaqlamır — hərəkət edən rəqib
  topdan çəkilib qaçır, yerində duranı isə vurur;
- hər atəşə **±10°**-yə qədər təsadüfi xəta düşür (üçbucaq paylanma, çox vaxt
  kiçik). Yerində duran rəqibə 300 px-də ~91%, 400 px-də ~78%, ekranın kənarında
  (600 px) ~58% dəyir; hərəkət edənə çox vaxt dəymir;
- hədəf **ekranda görünən** ən yaxın rəqibdir; maneə arxasındakı və kistdəki amöb
  (top ondan səkir) yalnız başqası yoxdursa seçilir. Ekranda heç kim yoxdursa,
  top getdiyin tərəfə gedir.

Dəqiq vurmaq istəyən nişan alır: xətt topun ÖZ yoludur — [`Sim.aim_path`](game/scripts/shared/sim.gd)
səkmə qaydalarını [`Sim._step_shots`]-dan götürür və test xətti əsl topla müqayisə
edir. Xətt soyuma və ya sursat çatmayanda bozdur: «buraxsan, atılmayacaq».

Atəş barmaq **qalxanda** açılır, basılanda yox — basılış anında toxunuşmu,
nişanmı, hələ bilinmir. Əvvəlki "basılı saxla, fasiləsiz at" qaydası ona görə
getdi (BOŞLUQ-da qalıb). Soyumanın son 0.2 s-ində edilən toxunuş itmir: istək
gözləyir ([`Arena.FIRE_BUFFER`](game/scripts/client/arena.gd)).

Hamısı client-dədir — nişan bucağı onsuz da girişdə gedirdi
([`Sim.PlayerInput.aim`]), server və proqnoz onu olduğu kimi götürür. Server
dəyişmədi: köhnə server yeni client-lə, yeni server köhnə client-lə işləyir.
Hədəf yalnız ekranda görünən rəqiblərdəndir — kolda gizlənəni server onsuz da
göndərmir, yəni avtomatik nişan heç kimi ifşa etmir.

Nişan alarkən mikrobun ayaqcığı ([`GermVisual.aim`]) nişanın tərəfinə dönür,
atəşdən sonra da 0.3 s atdığı tərəfə baxır — rəqib hara atacağını görür.
Düymənin ikonu, nişan başı, kilid çərçivəsi və xəttin oxu Codex ilə çəkilib, ağ-boz,
oyunçunun rəngi ilə boyanır (bax [design/menu_art/](design/menu_art/)).

### Zərbə hissi

Hadisə baş verəndə oyun bunu **dörd ayrı kanaldan** deyir. Səbəb odur ki,
ekranda 10 mikrob var və tək kanal (məsələn, yalnız səs) itir:

| Kanal | Nə vaxt | Kod |
|---|---|---|
| **Ağ parıltı** | top rəqibin içinə keçəndə | [`GermVisual.flash`](game/scripts/client/germ_visual.gd) |
| **Donmuş kadr** (75 ms) | yaxında biri partlayanda | [`Arena._apply_freeze`](game/scripts/client/arena.gd) |
| **Kamera zərbəsi** | partlama və tutum artımı | `Arena._punch` |
| **Uçan rəqəm** | `+2` zərbədə, `+5 TUTUM` mükafatda | [`Arena._pop_text`](game/scripts/client/arena.gd) |
| **Titrəmə** (telefonda) | zərbə 22 ms · super 45 · tutum 60 · ölüm 160 | [`Settings.vibrate`](game/scripts/shared/settings.gd) |

Uçan toplar da iz buraxır — [`ShotTrails`](game/scripts/client/shot_trails.gd).

Titrəmə BEŞİNCİ kanaldır və qalanlarını əvəz etmir: səs kəsilə bilər (səssiz
rejim, qulaqlıqsız oyun), parıltı isə barmağın altında qala bilər. Ayarlardan
söndürülür. Kamera silkələnməsi də ayardadır (QAPALI/AZ/NORMAL) — söndürüləndə
digər kanallar toxunulmaz qalır, yəni məlumat itmir.

Bu dörd kanal SAXLANILIR. Üçüncü vizual mərhələ onların üstünə istiqamət və
material qatını əlavə edir:

| Yeni qat | Hadisə | Oxunuş |
|---|---|---|
| Lülə alovu | atəş | membran yarığında `0.08 s`, nişan oxunda parlaq ləçək |
| İstiqamətli sıçrantı | top mikroba girir | gələn oxun ətrafında dar konus; radial deyil |
| Zərbə dalğası | mikrob partlayır | `0.40 s` genişlənən nazik halqa |
| Qida qövsü | qida udulur | qida membrana qövslə uçur, sonunda kiçik su halqası |
| Tutum aurası | `+5 TUTUM` | `0.62 s` qızılı aura + halqa |
| Kol xışıltısı | kola giriş/çıxış | yalnız toxunulan üst frond `0.52 s` dalğalanır |
| Qabıq qırıntısı | kövrək divara zərbə | adi zərbədə bir tərəfə, üçüncüdə bütün çevrəyə parça + toz |
| Cərəyan axını | fasiləsiz | HIGH-da hər deşiyə sorulan 7 cizgi; LOW-da sönür |
| Doğuş halqası | mikrob ilk görünür | `0 → 1.12 → 1.0`, `0.35 s`; [`GermVisual`](game/scripts/client/germ_visual.gd) |

İlk altı zərrəcikli döyüş effekti və qabıq qırıntıları ayrıca node açmır:
[`JuiceFx`](game/scripts/client/juice_fx.gd) hamısını bir node-da üç qalınlıq
batch-inə yığır. Eyni anda neçə hadisə olmasından asılı olmayaraq qat ən çox
**3** `draw_multiline_colors` çağırışı edir. Zərbə öz mikrobuna dəyəndə kamera
gələn ox boyunca ən çox 16 px təpik alır; yaxın rəqibin ölümü mövcud
`_punch` mexanizmi ilə qısa zoom verir.

> **Donma `Engine.time_scale` ilə edilmir və bu, məcburidir.** `time_scale`
> `_process` deltasını da kiçildir, yəni proqnoz tick-ləri yavaşıyır və serverə
> daha az giriş gedir. Server isə 30 Hz-lə işləməyə davam edir: client geri
> qalır, donma bitəndə düzəliş mikrobu sıçradır. Zərbə hissi üçün qoyulan
> effekt öz zərbəsini yeyərdi. Ona görə donma YALNIZ görüntüdədir — kamera və
> mikrob animasiyaları dayanır, simulyasiya isə tam sürətlə davam edir.

### Onlayn vuruş — gecikməsiz zərbə

**Problem:** onlayn oyunda rəqibi vuranda zərbə hiss olunmurdu. Top ekranda
rəqibin içindən keçib o biri tərəfdən çıxırdı, parıltı isə ~250 ms sonra
yanırdı. Səbəb iki zaman xətti idi: öz topun proqnozla İNDİ uçur, rəqib isə
interpolyasiyaya görə `100 ms + RTT` KEÇMİŞDƏ çəkilir. Zərbəni isə yalnız
server deyirdi, onun HIT hadisəsi də növbədə daha 100 ms gözləyirdi.

**Həll Brawl Stars və Overwatch-dakı kimi iki qatdır:**

| Qat | Nə edir | Kod |
|---|---|---|
| **Öz topunun proqnozu** | Topun ekranda tam simulyasiya olunur: divardan özü sıçrayır və gördüyün rəqibə dəyən kimi zərbə **elə o kadrda** göstərilir. Serverin eyni hadisəsi sonra gələndə tanınır və ikinci dəfə oynanmır. | [`ShotPrediction`](game/scripts/client/shot_prediction.gd), `Arena._step_own_shots` |
| **Serverdə geri sarma** (lag compensation) | Atəş paketi oyunçunun ekranda gördüyü tick-i daşıyır. Server son 16 tick-in mövqelərini saxlayır və topu rəqibin **atıcının gördüyü** yerinə qarşı yoxlayır. Ən çox 400 ms geri sarır ([`Const.REWIND_MAX`](game/scripts/shared/constants.gd)) — ölçülüb: RTT 180 ms-də lazım olan geri sarma 300–367 ms-dir, köhnə 300 ms həddi atəşlərin 84%-ni kəsirdi. Yalnız mövqe yox, qurbanın **halı** da geri sarılır: doğuş qalxanı və kist ([`Sim._rewound_bits`](game/scripts/shared/sim.gd)). | [`Sim._rewound`](game/scripts/shared/sim.gd) |

Proqnoz yalnız **görüntüdür**: top sayını, partlamanı və superin açılmasını yenə
yalnız server verir. Proqnozun vəd etdikləri (`+2` qurbanda, `+3` super
halqasında) serverin rəqəmi çatana qədər, ən çox 0.6 s göstərilir. Server
dəyməni saymasa, vəd özü sönür.

Atıcıya aid əlavə siqnallar (hamısı proqnozlaşdırılmış dəymədə, gecikməsiz):

| Siqnal | Nə deyir |
|---|---|
| `hit_confirm.wav` | Yalnız atana çalınan "sənin topun dəydi" səsi. Tonu qurbanın doluluğu ilə 1.0-dan 1.3-ə qalxır |
| Zərbə donması (50 ms) | Yalnız qurbanın animasiyası dayanır və parıltı tam ağ qalır. Ekran donmur, çünki o, öldürməyə saxlanılıb |
| Qırmızı `+2` | Növbəti top rəqibi partladacaq |
| Titrəmə 15 ms | Qurbanın titrəməsindən (22 ms) yüngül |
| Dərhal partlama | Sənin topunla dolan rəqibin partlaması interpolyasiyanı gözləmir |

Snapshot hadisə büdcəsində **baxanın öz hadisələri öndədir**
([`World._near_flat`](game/scripts/server/world.gd)). Əvvəl hadisələr yalnız
məsafəyə görə seçilirdi və 400–500 px uzaqda dəyən öz topunun HIT hadisəsi
yaxındakı qida udmalarının arxasında paketdən düşürdü: server dəyməni sayırdı,
client isə eşitmirdi.

Proqnozun topu serverinki ilə iki yerdə tutuşdurulur:

- **Gec tapılan atəş.** Server atəşi bəzən proqnozdan bir tick TEZ açır: server
  tick-ləri girişlərdən asılı olmayaraq 30 Hz-lə gedir və jitter-də bir girişi
  iki tick işlədə bilir. O halda atəşi yalnız serverin FIRE hadisəsi deyir.
  Əvvəl top həmin hadisə GƏLƏNDƏ doğulurdu, serverinkindən ~RTT geridə. Server
  dəyməni əvvəl sayırdı, gec top isə sonra ikinci, boş zərbə göstərirdi. İndi
  top atəşi açan girişin GÖNDƏRİLDİYİ andan uçur ([`Arena._spawn_own_shot`](game/scripts/client/arena.gd),
  [`ShotPrediction.catch_up`](game/scripts/client/shot_prediction.gd)).
- **Xəttə çəkmə.** Proqnoz yalnız öz mikrobunu simulyasiya edir. Serverdə isə
  mikroblar bir-birini itələyir, ona görə yaxın döyüşdə atəş nöqtəsi 50–80 px
  fərqlənə bilir. Server topu gələndə proqnoz onun xəttinə yana doğru ~0.1 s-də
  hamar çəkilir; xətt boyu vaxta toxunulmur ([`ShotPrediction.claim`](game/scripts/client/shot_prediction.gd)).

**Ekranda ölçülüb — köhnə və yeni kod yan-yana.** [`HitProbe`](game/scripts/tools/hit_probe.gd)
oyunun daxili vəziyyətinə yox, EKRANA baxır: öz topunu sprite rəngindən, rəqibi
[`GermVisual`](game/scripts/client/germ_visual.gd)-dan, zərbəni parıltının
yanmasından tanıyır. Ona görə eyni probe köhnə kodda (ayrıca git worktree) və
yenisində eyni şeyi ölçür. [`AutoClient`](game/scripts/tools/auto_client.gd)
onu hər dəfə qoşur və çıxışda `PROBE:`, `VURUŞ:` və `XƏTT:` sətirləri yazır.
Gecikdirici TCP proksi (hər istiqamətdə RTT/2, 15–20 ms jitter), 2 client × 90 s,
60 FPS:

| | Köhnə kod | Yeni kod |
|---|---|---|
| Top ekranda rəqibə çatır → parıltı, RTT 120 ms | median 184–281 ms, ən pisi 528 ms | **0 ms** |
| Eyni, RTT 180 ms | median 200–361 ms, ən pisi 516 ms | **0 ms** |
| Top rəqibin içindən keçib o biri tərəfdən çıxır | 45 / 51 toxunuş | **0 / 67** |
| Top rəqibə girir, zərbə ümumiyyətlə görünmür | 18 / 51 | **0 / 67** |
| Ekranda göstərilən öz dəymələrindən serverin saydığı, RTT 120 ms | — | **46 / 48 (96%)** |
| Eyni, RTT 180 ms | — | **17 / 19 (89%)** |

Geri sarmanın özünün payı: RTT 120 ms-də geri sarmasız server ekranda görünən
dəymələrin yalnız 10 / 21-ni (48%) sayırdı. Təsdiq ekrana RTT + ~40 ms sonra
çatır (RTT 120-də ~160 ms), amma bu artıq zərbənin gecikməsi deyil, yalnız top
sayının serverdən gəlmə vaxtıdır. Qalan fərq serverin bildiyi, client-in isə
bilə bilmədiyi hallardır: kolda gizlənən mikrob topu tutur, doğuş qalxanı
serverdə bir an əvvəl bitir. Geri sarma serverin tick qiymətini dəyişmir
(ölçülüb: 1.66 → 1.54 ms, səpələnmə daxilində).

Qaydaya görə dəyməyən hədəfləri probe ayrıca sayır (`+N qayda`): doğuş qalxanlı
mikrobdan top keçir, amöbün qabığından sıçrayır.

#### Top gövdənin içindən keçib dəymirdi

İkinci şikayət: onlayn oyunda top bəzən rəqibin içindən keçir, ona dəymir.
Bunu ölçmək üçün probe-a **siluet yoxlaması** əlavə olundu: topun yolu mikrobun
ÇƏKİLƏN gövdəsinə (toqquşma dairəsinə yox) girib parıltı yanmırsa, bu "keçid"dir.
Çıxışda `KEÇİD:`, `KEÇİD-DETAL:`, `GÖVDƏ:` və `SƏNƏ:` sətirləri yazılır. Hər
keçid üçün topun dəymə ellipsinə nə qədər dərin girdiyi (`d`) və gövdədən sonra
ekranda nə qədər uçduğu (`sonra`) da yazılır: uçmağa davam edibsə, server
dəyməni saymayıb.

Səbəbləri tapmaq üçün server də ölçüldü (yalnız test nüsxəsində): hər topun
necə bitdiyi (kimə dəydi, ömrü bitdi, sıçradı) yazıldı. Client-in hər
təsdiqlənməyən proqnozu topun id-si ilə həmin qeydə tutuşduruldu. Tapılan
səbəblər:

**Server**

| Səbəb | Düzəliş | Kod |
|---|---|---|
| Dəymə forması dairə idi, gövdə isə hərəkətdə uzanır: amöb oxu boyu radiusun 1.58 mislinə çatır, yanlardan 0.6-ya qədər sıxılır | Hərəkət istiqamətində uzanan **ellips**: kirpikli +20% / −14%, ayaqlı +4% / −5%, amöb +24% / −28%. Topun "payı" elə seçilir ki, ellipsin ORTA eni dairəninki qalsın — vurulma ehtimalı dəyişmir (bax aşağıda, «Balans»). Çəkilən gövdə bu ellipsdən bayıra çıxmır ([`GermVisual._fit_hit`](game/scripts/client/germ_visual.gd)): mərkəzi gövdədən keçən top həmişə dəyir. Server də, proqnoz da eyni funksiyanı işlədir | [`Sim.hit_shape`](game/scripts/shared/sim.gd) |
| Tick-də mikroblar toplardan ƏVVƏL yeriyir. Topa doğru gedən mikrob onun üstünə çıxanda topun 14 px-lik parçası bütünlüklə gövdənin içində qalırdı, sərhəd yoxlaması isə yalnız GİRİŞİ tapır. Serverin öz snapshot-unda top gövdənin 8–29 px içindən keçib uçmağa davam edirdi | İçində başlayan parça da dəymədir (kistdən isə top əvvəlki kimi səkir) | [`Sim.seg_ellipse_hit_t`](game/scripts/shared/sim.gd) |
| HIT hadisəsi qurbanı demirdi — client zərbəni ən yaxın mikroba TƏXMİN edirdi | `arg` qurbanın rəngini daşıyır (`1 + rəng`), köhnə `arg > 0.5` yoxlaması dəyişmir | [`Const.hit_arg`](game/scripts/shared/constants.gd), `Const.hit_victim` |
| Paketin hadisə büdcəsində (10 mikrobla tick-də ~7) sənə dəyən top sənin qida udmaların ilə eyni pillədə idi və düşə bilirdi — diaqnostikada tutuldu | Pillələr: sənə dəyən top → öz atəşin və zərbən → öz udman → başqalarının hadisələri (məsafəyə görə) → başqalarının udması | [`World._near_flat`](game/scripts/server/world.gd) |
| Client topun ömrünü bilmirdi və onu serverin sildiyi yerdən o yana çəkirdi | Qalan ömür istiqamətin uzunluğundadır (`dir × (1 + ömür)`) — əlavə bayt yoxdur | [`World._build_frame`](game/scripts/server/world.gd), `Const.unpack_shots` |
| İnsanın topu geri sarma ilə yoxlanılır — qurbanın ~0.27 s ƏVVƏLKİ yerinə qarşı. Client bunu bilmirdi | Hər top geri sarma miqdarını daşıyır ([`Const.SF`](game/scripts/shared/constants.gd) `REWIND`, 4 bayt; ən pis paket 1316 / 1392 bayt) | `World._build_frame` |
| Reyestr botu demirdi, client onu id-dən (`>= BOT_ID_BASE`) çıxarırdı. İnsanın peer nömrəsi təsadüfi 32 bitlik ədəddir və adətən daha böyükdür — o biri oyunçu BOT sayılırdı | Reyestr üçüncü sahədə "bot" bayrağını göndərir | [`World.roster`](game/scripts/server/world.gd) |

**Balans: ellips dəymə ehtimalını dəyişmir.** Əvvəl burada "amöb az vurulur,
superi yarıya endi" yazılmışdı — o, hər tərəfdə 5 çalışmalıq ölçü idi və
səs-küy imiş. Bot dünyası 300 dəfə × 60 s təkrarlananda şəkil tərsinə çıxdı:
köhnə ellipsdə amöb ÇOX vurulurdu. Səbəb həndəsədir: top hər tərəfdən gəlir,
dəymə ehtimalı formanın ORTA enindən (perimetr / π) asılıdır, ellipsə sadəcə
topun radiusu əlavə olunanda isə orta en böyüyürdü (amöbdə +8%, kirpiklidə +3%).
İndi topun payı elə seçilir ki, orta en dəqiq dairəninki olsun
([`Sim._even_margin`](game/scripts/shared/sim.gd), xətası 0.003%); amöbün forması da
çəkilən gövdəyə yenidən uyğunlaşdırıldı (+24% / −28%). Yoxlama — eyni kod, eyni
toxumlar, yalnız dəymə forması fərqli, hər dünya 300 × 60 s:

| Bot dünyası | Dəymə / 60 s: dairə → **indi** | Super / 60 s: dairə → **indi** | Supersiz çalışma |
|---|---:|---:|---:|
| Qarışıq (3 növ) | 75.6 → **77.1** | 11.53 → **11.68** | 0 → 0 |
| Yalnız kirpikli | 68.9 → **68.7** | 14.84 → **14.61** | 0 → 0 |
| Yalnız ayaqlı | 82.7 → **83.6** | 13.45 → **13.41** | 0 → 0 |
| Yalnız amöb | 78.2 → **79.7** | 4.26 → **4.21** | 7 → 4 (300-dən) |

Bütün fərqlər səpələnmə daxilindədir (ən böyüyü 1.3σ). Dəymələrdə 1–2%-lik artım
"tick-i gövdənin içində başlayan top da dəyir" düzəlişidir — o, ekranda
gövdədən keçən topun dəyməsidir, balans yox. Köhnə ellips isə amöb dünyasında
dəymələri 75.4 → 79.6, ölümü +21% artırmışdı. Amöbün superi təbiətən seyrəkdir
(dəqiqədə ~0.7), ona görə supersiz çalışmalar dairədə də var — bunu yoxlayan
test iki sabit toxumlu dünya ilə aparılır ki, təsadüfdən asılı olmasın.

**Client** ([`Arena`](game/scripts/client/arena.gd), [`ShotPrediction`](game/scripts/client/shot_prediction.gd))

| Səbəb | Düzəliş | Kod |
|---|---|---|
| Rəqibin topu hər kadr son snapshot-dan `t = _clock` ilə qurulurdu: iki snapshot arasında yerində durur, 30 Hz-lə pillə-pillə gedir və mikroblardan 0–33 ms GERİDƏ çəkilirdi. Rəqib artıq parlayırdı, top ona 15–30 ms sonra çatırdı | Top snapshot-un gəldiyi ana bağlanır — mikroblarla eyni zaman xətti, hamar hərəkət | `_render_shots` |
| Rəqibin topu keçmişdə çəkilir, sənin mikrobun isə indi | Sənə tərəf uçan top (yolu gövdənin yaxınından keçir, arada başqa mikrob yoxdur) yaxınlaşdıqca sənin zaman xəttinə keçir; yoluna qəfil girəndə top sıçramır, ~0.25 s-də yetişir | `_remote_shot_pos`, `_aimed_at_me` |
| İnsanın topu hədəflərinə qarşı `rewind` qədər gec yoxlanılır | Hər top öz hədəflərindən `rewind` qədər QABAQDA çəkilir — keçmişdəki mikrobların yanında da, sənin yanında da. Botda 0-dır | `_remote_shot_pos` |
| "Sənə dəydi" proqnozunun bir neçə piksellik mövqe xətası sərhəddə nəticəni dəyişirdi | Yalnız ƏMİN dəymə (topun xətti ellipsin 65%-dən dərinindən keçir, yolda başqa mikrob yoxdur) dərhal göstərilir. Sərhəddəki dəymədə top gizlənir, zərbə serverin təsdiqi GƏLƏNDƏ oynanır. Server topu göndərməyə davam edirsə, top GERİ qaytarılır | `SELF_SURE_DEPTH`, `_undo_self_claims` |
| Təsdiq hədd daxilindəki İLK proqnoza yazılırdı: eyni rəqibə ardıcıl iki top atılanda server ikincinin dəyməsini deyirdi, təsdiq birinciyə düşürdü | Ən YAXIN proqnoz, qurban bilinirsə yalnız onunku | `_match_claim`, `_match_self_claim` |
| Öz topunun proqnozu serverinkindən bir tick (14 px) çox uçurdu: server topu ömrünün son tick-ində hərəkətsiz silir | Proqnoz serverin addımı ilə, TICK-lərlə uçur (bax aşağıda) — düz 65 tick, kadr tezliyindən asılı olmayaraq | [`ShotPrediction._sim_tick`](game/scripts/client/shot_prediction.gd) |
| Serverin HIT-i bəzən proqnozun toxunuşundan ƏVVƏL gəlir (gec tapılan atəş) — zərbə iki dəfə göstərilir, proqnoz "boş" sayılırdı | Tez gələn dəymə 0.6 s yadda saxlanır və gecikən toxunuşu təsdiqləyir | `_take_early_hit` |

Probe-un özü də dəqiqləşdirildi: parıltı topun çəkilən gövdəyə toxunmasından
50 ms-ə qədər ƏVVƏL yanıbsa, bu da cavab sayılır (1–3 kadr fərqi göz ayırmır).
Belə hallar ayrıca göstərilir (`erkən parıltı`).

**Nəticə** — eyni probe, gecikdirici proksi (RTT 120 və 180 ms, 15–20 ms jitter),
8 çalışma × 2 client × 90 s. "Köhnə kod" bu işdən əvvəlki vəziyyətdir (RTT 120 ms,
2 çalışma):

| | Köhnə kod | **Yekun** |
|---|---:|---:|
| Öz topun rəqibə toxunur → parıltı | median 184–281 ms, ən pisi 528 ms | **97 / 101 toxunuşda 0–18 ms** |
| Öz topun rəqibin içindən keçib o biri tərəfdən çıxır | 45 / 51 | **2 / 101** |
| Öz topun rəqibə girir, zərbə heç görünmür | 18 / 51 | **4 / 101** |
| Rəqibin topu → sən, gövdəyə girib zərbəsiz | 3 / 10 | **0 / 3** |
| Rəqibin topu → başqası, gövdəyə girib zərbəsiz | 2 / 7 | **2 / 66** (ikisi də ekrandan kənarda) |
| Botun sənə dəyməsi: ƏMİN proqnoz, server təsdiqlədi | — | **111 / 127**, yalançı **2 (1.6%)**, qalanı sessiyanın sonunda cavabsız |
| Botun sənə dəyməsi: SƏRHƏDDƏ, server təsdiqini gözlədi | — | 24 / 30 təsdiq, 5-i dəymədi — top geri qaytarıldı |

"Sənə dəydi" proqnozunun yalançı hissəsi bu işin əvvəlində 22 / 221 (10%) idi.

Emulyatordakı Android Chrome-dan da (bax [Brauzerdə donma, 6-cı bənd](#brauzerdə-android-donma-və-kəsilmə))
onlayn oynanıb: RTT 120 ms-də zərbə dərhal göstərilir, keçid yoxdur.

#### Öz topunun təsdiqlənməyən dəymələri — əsl səbəblər

Yuxarıdakı işdən sonra öz topunun proqnozlaşdırılmış dəymələrinin hələ
14 / 138-i (10%) serverdə təsdiqlənmirdi. Fərziyyə itələmə idi: server üst-üstə
minən mikrobları ayırır, proqnoz isə yalnız öz mikrobunu hərəkət etdirirdi.
**Ölçü fərziyyəni təkzib etdi:** serverdə hər atəşin anında mikrobun son 8
tick-dəki itələnməsi yazıldı — təsdiqlənməyən dəymələrin HEÇ BİRİNDƏ itələmə
yox idi (`sep = 0`). Proqnoz yenə də yaxındakı mikrobları nəzərə alır
(aşağıda), amma səbəblər başqa imiş. Hər təsdiqlənməyən dəymə serverdəki topun
taleyi ilə (kimə dəydi, harada öldü, qurbana nə qədər yaxınlaşdı) tutuşduruldu:

| Səbəb (ölçüdə tapılıb) | Düzəliş | Kod |
|---|---|---|
| Rəqibin **trixosisti** topu dağıdır. Proqnoz bunu bilmirdi, top ekranda rəqibə çatıb "dəyirdi". Server isə partlayışı İNDİKİ zamanda yoxlayırdı, geri sarılan top isə keçmişdədir | Geri sarılan topun dağılması da `rewind` qədər gecikdirilir ([`Sim._blasts`](game/scripts/shared/sim.gd)): ekranda partlayışdan SONRA rəqibə çatan top serverdə də dəymir, ƏVVƏL çatan dəyir. Client partlayışı görən an radiusdakı öz toplarını dayandırır ([`ShotPrediction.blast`](game/scripts/client/shot_prediction.gd)); bot geri sarılan topu qabaqda görür | `Sim._super_trichocyst`, `_apply_blasts`, `Bot._wants_super` |
| Serverdə iki giriş bir tick-ə düşəndə (jitter) SONUNCU qalırdı — atəş bitinin istiqaməti və görünən tick-i isə ƏVVƏLKİ girişdə idi. Top başqa bucaqla uçurdu | Birləşmədə atəş girişinin öz nişanı (`fire_aim`) və `view_tick`-i saxlanılır; proqnozun atəş açdığı giriş "shot" biti ilə işarələnir və server soyuma bitənə qədər onu 2 tick gözləyir (`FIRE_WAIT`) | [`World.accept_input`](game/scripts/server/world.gd), `Sim.PlayerInput` |
| Qurbanın qalxanı və kisti İNDİKİ haldan oxunurdu, mövqeyi isə geri sarılmışdan | Hal da geri sarılır: tarixçədə hər tick-in bitləri saxlanılır | `Sim._rewound_bits`, `HIST_SAFE`, `HIST_CYST` |
| Geri sarma həddi (300 ms) RTT 180-də atəşlərin çoxunu kəsirdi | 400 ms | `Const.REWIND_MAX` |
| Qabın kənarında sıçrayış nöqtəsi addımın uzunluğundan asılıdır: proqnoz 60 Hz-lə (7 px), server 30 Hz-lə (14 px) addımlayırdı — 500 px sonra top 18 px aralı uçurdu | Proqnoz topu serverin addımı ilə, TICK-lərlə simulyasiya edir; ekranda tick içində hamar çəkilir | [`ShotPrediction._sim_tick`](game/scripts/client/shot_prediction.gd) |
| Hədəflər ekranda gəliş VAXTINA görə interpolyasiya olunur; snapshot jitter-lə gələndə rəqib tick-in yarısı qədər qabaqda və ya geridə olur. Server isə qurbanı dəqiq `tick − rewind`-də yoxlayır | Topun `k`-cı tick-i rəqiblərin `görünən tick + k`-dakı halına qarşı yoxlanılır — snapshot buferindən, TICK-ə görə. Mikrobların çəkilişi də gəliş anına yox, hamarlanmış tick saatına bağlandı | `Arena._ghost_targets`, `_tick_time_of` |
| Qalan yalançıların çoxu qurbanın kənarına **sürtünmə** idi: xətt ellipsin 0.88–0.99+ dərinliyindən keçirdi, serverdə isə 1.02–1.05 məsafədən (atəş nöqtəsi bir tick fərqli — 6–10 px) | Xətt ellipsin 0.85-dən dayaz hissəsindən keçirsə, top gövdənin kənarında dayanır, zərbə isə serverin təsdiqi GƏLƏNDƏ oynanır. Server dəymənin tick-indən sonra da topu göndərirsə, top geri qaytarılır | `OWN_SURE_DEPTH`, `_undo_own_soft` |
| Server atəşi HƏLƏ təsdiqləməmiş (yaxın məsafə, top rəqibə RTT-dən tez çatır) dəymələrin 23-dən 3-ü yalançı idi: jitter-də soyuma server ilə proqnoz arasında bir neçə tick sürüşür və server o atəşi heç açmırdı. Sonrakı 310 dəymədən 3-ü | Atəşi hələ təsdiqlənməmiş topun dəyməsi də təsdiqi gözləyir | `_on_own_contact` |
| Şəbəkə sıxılanda (RTT 180 → 443 ms) girişlər serverə dəstə ilə çatır və birləşir — proqnozun iki atəşini server açmadı | Sıxılmada heç bir dəymə əmin sayılmır. "Adi" gecikmə son saniyələrin ən aşağı RTT-sidir və yavaş qalxır (0.005 s/s) — 20 saniyəlik sıxılma da "adi" sayılmır | [`_congested`](game/scripts/client/arena.gd) |
| Çox sıx şəbəkədə (təsdiq 400–720 ms) geri sarma 400 ms həddinə dirənir və server hədəfi atıcının gördüyü tick-dən daha YENİ tick-də yoxlayır — bir seriyanın 6 yalançısından 2-si belə idi | Server geri sarmanı həddə kəsibsə (topun təsdiqində gəlir), onun dəymələri təsdiqi gözləyir | [`ShotPrediction.Ghost.rewind`](game/scripts/client/shot_prediction.gd) |
| Qurban ekranda sağdır, amma başqasının topundan artıq partlayıb (hadisə gəlib, interpolyasiyanı gözləyir) | Belə dəymə də təsdiqi gözləyir | `_burst_pending` |
| Top qurbana ömrünün SON tick-ində çatırdı: proqnozun atəş nöqtəsi xətt boyu 9 px qabaqda idi, proqnoz 0.7 tick uzağa uçub "dəydi", serverin topu isə qurbana 1.20 məsafədə öldü | Ömrün son iki tick-indəki dəymə də təsdiqi gözləyir | [`ShotPrediction.LATE_LIFE`](game/scripts/client/shot_prediction.gd) |
| Qurban superi dolu kirpikli idi: bot trixosisti topu görən an açır, atıcı isə onu `rewind` qədər gec görür — mərkəzdən keçən (0.02) dəymə belə itdi | Yanında superi dolu kirpikli olan dəymə təsdiqi gözləyir | `_rival_tricho_near` |

Proqnoz indi yaxındakı mikrobları da (220 px) öz dünyasına qoyur — son
snapshot-dan irəli çəkilmiş surətlər kimi — və server kimi ayırır
([`Arena._sync_proxies`](game/scripts/client/arena.gd)). Yan-yana dayanıb itələnən
mikrobun proqnoz mövqeyi serverinkindən əvvəl 74.8 px aralı düşürdü, indi 0-dır
(test).

**Botun sənə dəyməsi** ("sənə dəydi" proqnozu) üçün də iki səbəb tapıldı: aradakı
mikrob topu səndən əvvəl tuta bilər (o, keçmişdə çəkilir), və superi dolu
kirpikli rəqib topu görən an trixosistlə dağıdır — sən isə onun superini gec
görürsən. İndi yolda mikrob varsa ([`_proxy_blocks`](game/scripts/client/arena.gd))
və ya yaxında superi dolmaq üzrə olan kirpikli varsa (`_rival_tricho_near`),
dəymə ƏMİN sayılmır və serveri gözləyir. Öz trixosistin hazırdırsa da belədir:
superin girişi serverə hansı tick-də çatırsa, top o tick-də dağılır (əvvəl dəymə
yalnız bir tick gözləyirdi — super iki tick sonra açılanda zərbə göstərilir,
serverdə isə top dağılırdı). Şəbəkə sıxılanda ([`_congested`](game/scripts/client/arena.gd):
gediş-gəliş son saniyələrin ən aşağısından xeyli uzundur) heç bir dəymə əmin
sayılmır — o anda girişlər serverə dəstə ilə çatır və birləşir: ölçülüb, RTT 180
→ 443 ms-də proqnozun açdığı iki atəşi server heç açmadı, ekranda isə toplar
rəqibə "dəydi". Sonrakı seriyalarda daha üç səbəb tapıldı:

| Səbəb | Düzəliş |
|---|---|
| Sən qayanın arxasındasan: irəli çəkilən top qayanın səthində dayanır və gövdənə məhz o nöqtədə toxunur. Serverdə eyni `t`-də qaya qalib gəlir, top səkir — xətti gövdənin düz mərkəzindən keçən (0.01) dəymə belə yalançı çıxdı | Gövdəyə yalnız qayanın səthində toxunan top dəymə sayılmır |
| Server sıçrayışı deyəndə top köhnə yoldan yenisinə KÖÇÜR; köçmə xətti gövdəni kəsirdi, halbuki top serverdə sənə heç yaxınlaşmamışdı | İstiqamət dəyişən kadrda yol yenidən başlayır |
| Topun yoluna DİK qaçanda (140 px/s) yerinin xətası sürətlə böyüyür: server girişləri öz tick-i ilə emal edir, jitter-də bir giriş iki dəfə, növbəti heç işlənmir (girişlərin ~10%-i, bir tick-in yolu ≈ 6 px) — üstəlik RTT xətası. 0.59 dərinlikli "əmin" dəymə belə yalançı çıxdı | Əmin hədd yola dik sürətlə dərinləşir: xəta = 2 px + dik sürət × 0.12 s, ellipsin yola dik yarım-eninə bölünür ([`Arena.self_sure_depth`](game/scripts/client/arena.gd)) |
| Serverin topu vurduğu, amma client-in onu "vurmadı" sayıb geri qaytardığı hallar: geri qaytarma vaxtla (RTT + ehtiyat) ölçülürdü, şəbəkə sıxılanda isə xəbər RTT-nin hamar təxminindən gec gəlir — bir seriyada 3 əmin və 7 sərhəd dəyməsi belə qaytarıldı. Serverin təsdiqlədiyi girişə bağlamaq da kömək etmədi (daha sıx seriyada 21 hal): sıxılmada proqnozun zaman xətti serverdən bir neçə tick qabağa düşür və top serverdə sənə hələ ÇATMAMIŞ olur | Geri qaytarma snapshot-dakı YERLƏRƏ baxır: serverin topu sənin (serverin onu yoxladığı — insanın topunda `rewind` qədər əvvəlki) yerinin yanından keçib uzaqlaşıbsa, dəymə olmayıb; çatmayıbsa, gözlənilir ([`Arena.shot_gone_past`](game/scripts/client/arena.gd)). Öz topunun sərhəd dəyməsi də eyni qayda ilə |

**Başqasına gedən top.** Sənə tərəf uçub yayınan top sənin zaman xəttində qalırdı
və qabaqdakı mikrobun (keçmişdə çəkilir) gövdəsindən keçirdi. İndi qabaqda mikrob
varsa, top yavaşıyıb onun zaman xəttinə qayıdır — geri getmir, mikrob yola qəfil
girəndə isə elə sürətlə ki, ona çatmamış qayıtsın ([`Arena.release_rate`](game/scripts/client/arena.gd)).
Ömrü bitən top da ölü yerində donub qalmır — serverdə o, həmin tick qidaya çevrilir.

**Yekun ölçü** — eyni probe və diaqnostika, RTT 120 və 180 ms (15–20 ms jitter),
hər seriya 6 sessiya × 2 client × 90 s. Serverin gerçək cavab vaxtı seriyadan
seriyaya dəyişdi (bir maşında 9 Godot prosesi və proksi): "adi" seriyada təsdiq
140–240 ms, "sıx" seriyalarda 150–350 ms (ayrı-ayrı sessiyalarda 720 ms-ə qədər).
"Sənə dəydi" serverin topun taleyinə görə yoxlanır — client təsdiqi tutmayıbsa,
amma server səni vurubsa, bu yalançı sayılmır:

| | Bu işin əvvəli | **İndi, adi şəbəkə** (1 seriya) | **İndi, sıx şəbəkə** (2 seriya) |
|---|---:|---:|---:|
| Öz topunun dərhal göstərilən dəyməsi, server saymadı | 14 / 138 (10%) | **1 / 80** (1.3%) | 4 / 97 (4.1%) |
| Öz topunun dəyməsi serverin təsdiqini gözlədi | — | 27 / 107 (25%) | 83 / 180 (46%) |
| Botun sənə ƏMİN dəyməsi, server saymadı | 22 / 221 (10%) | **0 / 122** | **0 / 134** |
| Server topu vurdu, client isə "dəymədi" sayıb qaytardı | — (ara seriyada 21) | **0** | **0** |
| Rəqibin topu → başqası, gövdədən zərbəsiz keçir | 14 / 47 | 2 / 44 (ekranda 0) | 3 / 80 (ekranda 2) |
| Rəqibin topu → sən, gövdədən zərbəsiz keçir | — | **0** | **0** |

Şəbəkə sıxılanda client özü daha çox gözləyir (25% → 46%): o anda proqnozun
xətası böyüyür və "gözləmə" yalançı zərbədən yaxşıdır — gözləyən dəymə yenə
göstərilir, sadəcə serverin cavabı ilə (~RTT sonra). Qalan yalançı öz dəymələri
yarış hallarıdır: qurban serverdə başqasının topundan partlayıb və ya öz trixosistini
açıb, xəbəri isə client-ə hələ çatmayıb — client bunu əvvəlcədən bilə bilməz.
Serverdə bir dəfə insan qurbanın heç yoxlanmaması da görüldü (top onun 31 px
yaxınından keçdi, "yaxınlıq" siyahısı boş idi). Serverə hər insan↔insan keçidini
səbəbləri ilə yazan diaqnostika qoyuldu: sonrakı 8 seriyada 30 px-dən yaxın 24
keçidin hamısı dəydi — hal təkrarlanmadı.

### Bioluminessensiya (glow)

Parlaq piksellər ətrafa işıq saçır — [`Arena._build_glow`](game/scripts/client/arena.gd).
`gl_compatibility` renderer-ində DƏ işləyir, amma **iki şərtlə**:

1. `rendering/viewport/hdr_2d` açıq olmalıdır (`project.godot`), yoxsa rənglər
   1.0-da kəsilir və hədd heç vaxt keçilmir;
2. `glow_hdr_threshold` 1.0-dan **aşağı** olmalıdır (indi `0.62`), çünki
   `Palette`-dəki bütün rənglər ≤ 1.0-dır — heç nə öz-özünə HDR diapazonuna
   çıxmır.

Hədd fonu (`0.05`) toxunulmaz saxlayır: yalnız **canlı** olan şeylər işıq verir.

## Rejimlər

Dörd rejim var və oyunçu menyuda OYNA düyməsinin üstündəki kartdan seçir.
Qaydalar (top, partlama, növ gücləri) hər ikisində EYNİDİR — fərq yalnız
matçın olub-olmamasındadır.

| | **SONSUZ ARENA** | **TƏK QALAN** | **CÜT** | **ÜÇLÜK** |
|---|---|---|---|---|
| Mikrob | ən azı 6 | 10 | 10 (5×2) | 6 (3v3) |
| Giriş | dərhal | 3 s sayım | 3 s sayım | 3 s sayım |
| Ölüm | menyu, yenidən gir | matç bitir | **yoldaşın diriltir** | raund bitir |
| Qab | sabit 1200 | 1200 → 90 | 1200 → 90 | 700 → 220 |
| Spor | yox | 3 | 3 | yox |
| Bitiş | yoxdur | sonuncu mikrob | sonuncu cüt | 3 raundun 2-si |

**Quru zona top ARTIRIR, azaltmır.** Bu, rejimin əsas qərarıdır: oyunun imza
ölümü partlamaqdır, aclıqla sönmək deyil. Ona görə kənar həm təhlükə, həm də
yemdir — dolu oyunçunu öldürür, ac oyunçunu isə xilas edə bilər. Oyunçu hər
dəfə real seçim edir: "kənara girib doldurummu, yoxsa mərkəzdə qalım?"

Qabın radiusu YALNIZ matç saatından asılıdır (`Const.dish_radius`) — client
eyni düsturu işlədir, ona görə daralma proqnozla ziddiyyət yaratmır.

**Spor** — matçda doğulan iri qida yığını. Yeyənə **tutum** verir, yəni
partlatmaqla eyni mükafata ikinci yol açır: döyüşməyən oyunçu da irəliləyir.

**Quru zonada qida yoxdur.** Qab daralanda kənarda qalan qida quruyur və
doğuş hədəfi də qabın ölçüsü ilə kiçilir. Bu, qaydanı bir cümləyə yığır:
*quru zonada TOP var, QİDA yoxdur.* Onsuz matçın sonu ilişirdi — aşağıya bax.

**Matç bitəndə qab dayanmır.** Əsas quruma 250 px-də bitir, sonra matçın
sonuna qədər 90 px-ə qədər yavaş sıxılma davam edir. Dayansaydı, son dəqiqədə
heç nə dəyişməzdi.

**Komanda ayrı KANALLA göstərilir, rənglə yox.** On mikrob rəngi qalır, çünki
rəng "kim" sualına cavab verir, komanda isə "dost ya düşmən" sualına — ikisi
ayrı sualdır. Yoldaşın adı **laym**, düşməninki sönük ağdır.

CÜT-də yoldaşın sağ ikən ölüm müvəqqətidir: 15 saniyə sonra qayıdırsan, amma
**tutum sıfırlanır** — dirilmə ikinci şansdır, cəzasız davam deyil. İkiniz də
ölsəniz cüt matçdan çıxır.

ÜÇLÜK-də tutum raunddan raunda **keçmir**: keçsəydi, birinci raundu udan
komanda ikincidə də üstün başlayardı və matç faktiki olaraq bir raundda
həll olunardı.

Tam quruluş: [design/MODES.md](design/MODES.md).

## Ekranlar

[Baş menyu](docs/screenshot_menu.png) · [Oyun ekranı](docs/screenshot_world.png)

### Menyunun quruluşu

Zonalar Brawl Stars-ın **bugünkü (2026)** ana ekranından götürülüb — hər
birinin bir işi var (araşdırma: [ART_BIBLE § 6b](design/ART_BIBLE.md)):

| Zona | Nə var | Niyə |
|---|---|---|
| Mərkəz | podiumda növün qəhrəmanı, adı başının üstündə | Kimlik OBYEKTƏ bağlıdır; toxunmaq titrədir, çəkmək dartır |
| Aşağı-sağ | [rejim kartı][sarı **OYNA**] | «Nə oynayıram» və «başla» bir qərardır — yan-yana |
| Sol lent | MAĞAZA\*, MİKROBLAR, MƏŞQ | Brawl Stars-da Shop, Brawlers |
| Sağ lent | **DOSTLAR** (qırmızı nişan = cavab gözləyən sorğu/dəvət) | Brawl Stars-da Friends — bax [Dostlar və komanda](#dostlar-və-komanda) |
| Qəhrəmanın iki yanı | iki **«+»** yuvası → komanda yoldaşları | Brawl Stars-ın komanda yuvaları |
| Yuxarı-sol | profil: növün avatarı + ad | Sabit konvensiya |
| Yuxarı-sağ | QİDA\*, DNT\* valyutaları + dişli (AYARLAR) | Ayarların YEGANƏ qapısı |
| Aşağı-sol | MİKRO PASS\*, TAPŞIRIQLAR\* | Brawl Pass və Quests |

\* **Görünüş üçündür** — arxalarında hələ sistem yoxdur: valyutalar `0`-dır,
basanda «… — TEZLİKLƏ!» bildirişi çıxır. Cavabsız düymə etibarı aparır, ona
görə hər biri nə gəlmədiyini açıq deyir.

Düymələrin dili də Brawl Stars-dandır: qalın qara kontur, altda tünd dodaq,
konturlu ağ yazı ([`ChunkyBox`](game/scripts/client/chunky_box.gd)). İkonlar
və illüstrasiyalar Codex ilə çəkilib ([design/menu_art/](design/menu_art/)).

**MİKROBLAR** — Brawl Stars-ın Brawlers kolleksiyası: hər növ sinfinin rəngində
portret kartdır (KİRPİKLİ — CƏLD, AYAQLI — NƏZARƏTÇİ, AMÖB — MÜDAFİƏÇİ). Karta
toxunmaq növün **səhifəsini** açır: böyük portret, «OYUNDA» pəncərəsində canlı
oyun mikrobu, `Const`-dan gələn dörd göstərici, super və sarı **SEÇ** düyməsi.
Ətraflı: [ART_BIBLE § 6d](design/ART_BIBLE.md).

Növ və rejim seçimi ANA EKRANDA deyil, ayrı vərəqlərdədir
([design/menu/](design/menu/)). Səbəb sayğacdır: əvvəl ana ekranda on yeddi
zona və altı cümlə vardı, oyunçu OYNA-ya çatana qədər hamısının arasından
keçirdi. İndi səkkiz zona və bir sətir qeyd var.

> Sağ lentdə hələ yalnız DOSTLAR var. Brawl Stars-da orada xəbərlər və klub
> da var; bizdə yoxdur və boş düymə qoymaqdansa yeri saxlamaq daha düzgündür.

### Ayarlar

Menyudakı dişli → tam ekran **AYARLAR**. **Matçın içində ayarlar yoxdur** —
Brawl Stars-da olduğu kimi, döyüş ekranında sistem düyməsi yoxdur. Matçdan
çıxmaq üçün Android-in **GERİ** jesti və ya **ESC**: kiçik təsdiq açılır
(DAVAM ET / ÇIX). Sonsuz arenada matç bitmədiyi üçün bu çıxış qalmalıdır.

Üç sütun, çünki ekran yatay 1280×720-dir: bir sütunluq siyahı eni boş qoyub
oyunçunu sürüşdürməyə məcbur edərdi.

| Sütun | Ayar | Nə edir |
|---|---|---|
| **SƏS** | Ümumi · Effektlər · İnterfeys | Üç şin: `Master`, `SFX`, `UI` |
| | Səssiz rejim | `Master` sıfırda — səviyyələr yadda qalır |
| **QRAFİKA** | Keyfiyyət YÜKSƏK/AŞAĞI/MİNİMUM | Glow, HDR buferi, zərrəcik sıxlığı; MİNİMUM-da sadə mikrob və az piksel — brauzerdə kətan DPR 1.25, tətbiqdə 1280×720 (bax [Zəif telefonlar](#brauzerdə-android-donma-və-kəsilmə)) |
| | Kadr həddi 30/60/120/SƏRBƏST | `Engine.max_fps` — telefonda batareya ayarıdır. Seçilməyibsə MİNİMUM-da 30 |
| | Ekran silkələnməsi QAPALI/AZ/NORMAL | Yalnız kamera; səs, parıltı və donmuş kadr qalır |
| | Kadr sayğacı | HUD-un yuxarı-mərkəzində FPS |
| **İDARƏ** | Sol əl düzümü | Joystick sağ yarıya, atəş və super sol aşağıya |
| | Titrəmə | Zərbə, super, tutum artımı, ölüm (yalnız telefonda) |
| | Server ünvanı · Sıfırla · versiya | |

Hamısı [`Settings`](game/scripts/shared/settings.gd) autoload-undadır və
`user://settings.cfg`-yə yazılır. Autoload olması praktik nəticə verir: menyunu
KEÇƏN yollar da (`--practice`, `--agent`, `--map`) oyunçunun səsi və kadr həddi
ilə başlayır — əvvəl ayarları yalnız menyu oxuyurdu.

**Musiqi sürgüsü QƏSDƏN yoxdur** — oyunda musiqi treki yoxdur (bax
[AUDIO_BIBLE](design/AUDIO_BIBLE.md): cəmi 10 qısa effekt). Heç nəyi idarə
etməyən sürgü bütün ekrana olan etibarı aparır; şin isə hazırdır, trek gələndə
bir sətir əlavə olunacaq.

> **Kadr həddi əmr sətrini POZMUR.** `--max-fps` və ya `--fixed-fps` verilibsə
> ayar `Engine.max_fps`-ə toxunmur — yoxsa oyunçunun 30-luq seçimi `--perf` və
> `--shot` ölçmələrini səssizcə dəyişərdi.

### Dostlar və komanda

Brawl Stars-ın dostluq və komanda dəvəti axını, eyni ardıcıllıqla:

| Brawl Stars | Bizdə | Harada |
|---|---|---|
| Oyunçu kodu `#2PPLQ8GY` | Hər cihazın dəyişməz kodu, məs. `#JL9J9GYPY` | DOSTLAR → SƏNİN KODUN (KOPYALA / PAYLAŞ) |
| Kodla dost əlavə etmək → sorğu → QƏBUL / RƏDD | Eyni; qarşılıqlı sorğu avtomatik dostluqdur | DOSTLAR → DOST ƏLAVƏ ET, SORĞULAR |
| Dost linki | `https://…/?friend=KOD` — veb oyun kodu hazır yazılmış DOSTLAR ekranı ilə açılır | PAYLAŞ |
| Döyüş jurnalından əlavə | Onlayn matçda rastlaşdığın insanlar (botlar yox) | SON OYUNÇULAR → + DOST |
| Dostun vəziyyəti | Menyuda · Komandada · Oyunda · Oflayn («5 saat əvvəl») | DOSTLAR siyahısı |
| Qəhrəmanın yanında «+» → dost siyahısı → DƏVƏT ET | Eyni; dəvət 60 s yaşayır, ekranın yuxarısında kart + sönən zolaq | Ana ekran |
| Qəbul olunan yoldaş podiumda | Yoldaşın NÖVÜNÜN qəhrəmanı, adı, HAZIR ✓, liderdə tac | Ana ekran |
| Komanda kodu / linki | 6 simvollu kod və `?party=KOD` linki — dost olmaq şərt deyil | DOSTLAR → KOMANDA |
| Rejimi lider seçir | Eyni; üzv rejim kartına basanda «REJİMİ LİDER SEÇİR» | Rejim kartı |
| Hamı hazır → birlikdə matç | OYNA komandada HAZIR düyməsidir: `OYNA 1/3` → yaşıl `HAZIR 2/3 ✕` | OYNA |
| Solo Showdown-a komanda ilə girmək olmur | TƏK QALAN tək oynanır; ikinci üzv gələndə rejim özü CÜT-ə, üçüncüdə ÜÇLÜK-ə keçir | — |

Komanda **CÜT və ÜÇLÜK-də EYNİ KOMANDAYA** oturur (o komandadakı botlar yer
verir — [`World.add_party`](game/scripts/server/world.gd)), **SONSUZ ARENA-da**
isə eyni dünyaya düşür (orada komanda yoxdur). Komandada ən çox 3 nəfər olur.

**Dost siyahısı serverdə YOX, cihazdadır** (`user://social.cfg`). Server Render-in
pulsuz planındadır: 15 dəqiqə boş qalanda yatır və diski müvəqqətidir — siyahı
orada olsaydı, hər yuxudan sonra hamının dostları silinərdi. Server yalnız
ötürücüdür ([`SocialHub`](game/scripts/server/social_hub.gd)): kim onlayndır,
sorğuları və dəvətləri çatdırır, oflayn oyunçunun "qəbul etdi / sildi"
bildirişini poçtda saxlayır.

Buna görə üç qoruyucu var:

- **Kod gizli açardan hesablanır.** Cihaz bir dəfə 16 baytlıq açar yaradır;
  kod ondan çıxır ([`Social.tag_of`](game/scripts/shared/social.gd)), server
  heç nə yadda saxlamır. Başqasının kodunu bilmək onun adından danışmağa imkan vermir.
- **Vəziyyət və dəvət yalnız QARŞILIQLI dostluqda gedir.** Siyahını client
  göndərir, yəni istədiyi kodu yaza bilər; amma iki tərəfin siyahısında da
  bir-biri olmayanda server heç nə ötürmür. Qəbul da yalnız həqiqətən göndərilmiş
  sorğuya keçərlidir.
- **Kodun sonuncu simvolu yoxlama simvoludur** (Luhn mod 14). Yuxudan oyanan
  server oflayn oyunçunu tanımır və "belə oyunçu yoxdur" deyə bilmir — yazma
  səhvini client özü tutur. Test: bir simvolluq 585 səhvin 585-i tutulur.

Bağlantısı qopan üzv komandada **30 s** qalır (soluq görünür, «qopdu…») —
yenidən qoşulan eyni kodla yerinə oturur. Sorğu və dəvət spamı saniyədə birə
məhduddur. Açar cihazdan köçmür: oyunu silən və ya başqa brauzerdə açan oyunçu
yeni kod alır (Brawl Stars-da bunu Supercell ID həll edir — bizdə hələ yoxdur).

> **RPC-lər `Net`-də deyil, `/root/Friends`-dədir** — bu məcburidir. Godot
> hər node-un RPC siyahısından checksum hesablayır və fərqli olanda o node-un
> BÜTÜN RPC-ləri ölür. İlk variantda dostluq RPC-ləri `Net`-ə əlavə olunmuşdu və
> QA agenti canlı (köhnə) serverə qoşulanda «rpc node checksum failed» aldı —
> yeniləməmiş APK yeni serverdə `request_join` də edə bilməzdi. Ayrı node-da
> `Net` dəyişmir: köhnə client yeni serverdə oynayır (sadəcə dostları yoxdur),
> yeni client köhnə serverdə də oynayır.

#### Telefon brauzerində yazı — iPhone-da kod yazılmırdı

Şikayət (2026-10-03): iPhone-da dost kodu yazıla bilmirdi. Səbəb mühərrikdədir.
Godot brauzerdə yazı sahəsi fokus alanda gizli bir HTML elementini 100 ms-dən
bir `focus()` edir (`GodotIME`). Android Chrome toxunuşdan sonrakı bir neçə
saniyə buna icazə verir və klaviaturanı açır — Android-də ad yazılırdı. iOS isə
(Safari də, iOS-dakı Chrome da WebKit-dir) klaviaturanı YALNIZ toxunuş
hadisəsinin İÇİNDƏ fokuslanan sahə üçün açır. Taymerdən gələn fokus heç vaxt
klaviatura açmır. Export-dakı `experimental_virtual_keyboard` də kömək etmir:
onun `focus()`-u da mühərrikin kadr dövründən gəlir.

Həll — telefon brauzerində sahə HTML pəncərəsində yazılır
([`WebText`](game/scripts/client/web_text.gd), `germText` [`web/shell.html`](game/web/shell.html)-də):

1. Sahənin Godot fokusu söndürülür — gizli element işə düşmür və pəncərənin fokusunu oğurlamır.
2. Toxunuş sahəyə düşəndə Godot JS-ə "bu sahə basıldı" deyir (`germText.arm`).
3. Barmaq qalxanda (`touchend` — iOS-un icazə verdiyi an) brauzer öz `<input>`-unu
   açır və ELƏ HƏMİN hadisədə fokuslayır: klaviatura çıxır.
4. GÖNDƏR / Enter — mətn sahəyə yazılır və `text_submitted` buraxılır, yəni dost
   sorğusu birbaşa klaviaturadan gedir. ✕ və ya fona toxunmaq ləğv edir.

Pəncərə ekranın YUXARISINDADIR və `visualViewport`-u izləyir: yatay telefonda
klaviatura ekranın yarıdan çoxunu örtür, sahənin öz yeri onun altında qalardı.
Kod sahələrində hərflər özü böyüyür, avtoduzəliş sönülüdür, "Yapışdır" işləyir.
Dost kodu sahəsinə `#`, boşluq və tire üçün yer qalıb — mesajdan "#JL9 J9G YPY"
kimi yapışdırılan kod kəsilmir. Eyni yol adda, komanda kodunda və server ünvanında
işləyir. Masaüstü brauzerdə və APK-da heç nə dəyişməyib.

> Kadr çox yavaşdırsa və Godot toxunuşu barmaq qalxandan SONRA emal edirsə,
> pəncərə dərhal açılır, amma iOS onda klaviaturanı açmır — oyunçu sahəyə bir
> dəfə də toxunur. iPad-da siçan/trackpad ilə (toxunuş yoxdur) pəncərə elə
> basılan kimi açılır. iPadOS Safari özünü "Macintosh" kimi təqdim edir — toxunuş
> nöqtəsi olan "Mac" iPad sayılır.

Yatay telefonda klaviatura açılanda görünən hissə cəmi 60–130 CSS px qalır
(emulyatorda ölçülüb: 71 px). Ona görə telefonda pəncərə YIĞCAMDIR: sahə + GÖNDƏR + ✕
bir sətirdə, ən yuxarıda. ✕, fona toxunmaq və Esc LƏĞVDİR — yazılan mətn sahəyə
keçmir. Böyük hərf yalnız göstərilir (CSS) və göndəriləndə tətbiq olunur: dəyəri yazı
zamanı dəyişmək Android klaviaturalarının söz yığımını pozur.

> Godot 4.7-nin `LineEdit`-i fokus ala bilməsə də, basılanda gizli IME elementini
> işə salır və o, fokusu 100 ms-dən bir özünə çəkir (brauzerdə yoxlanıb) — HTML
> sahəsinin klaviaturası dərhal bağlanırdı. Ona görə [`WebText`](game/scripts/client/web_text.gd)
> sahənin ÜSTÜNÜ örtən şəffaf `Control`-dur: toxunuşu o tutur, `LineEdit` heç görmür.

**KOPYALA və LİNK də iPhone-da işləmirdi** — eyni səbəbdən. Godot-un `clipboard_set`-i
kadr dövründən çağırılır; iOS panoya yalnız toxunuşun içində yazmağa icazə verir və
mühərrik özü konsola "only possible from an input callback" yazırdı, oyun isə
"KOPYALANDI" göstərirdi. `navigator.share` isə heç nə açmırdı. İndi düymə BASILANDA
tapşırıq silahlanır (`germText.armAction`), barmaq qalxanda brauzer kopyalayır və ya
PAYLAŞ pəncərəsini açır (yoxdursa linki kopyalayır). Bildiriş nəticəyə görədir:
"KOPYALANDI" və ya "KOPYALANMADI — əllə yaz: #KOD".

Yoxlama (iPhone bu maşında yoxdur — iOS-un davranışı sənədlərdən və mühərrikin öz
kodundan çıxarılıb, real cihazda sınanmayıb):

| Harada | Nə yoxlanıb |
|---|---|
| Android emulyatoru (Chrome 113, DevTools ilə etibarlı toxunuş) | DOSTLAR → kod sahəsi: pəncərə açılır, real klaviatura çıxır, sətir klaviaturanın üstündə görünür, yazı → GÖNDƏR → sorğu gedir, sahə təmizlənir |
| Başsız Chrome, telefon emulyasiyası (CDP, toxunuş) | ad: toxunuş açır, ✕ dəyişmir, OK dəyişir · KOPYALA toxunuşun içində `#KOD` kopyalayır, bir bildiriş · LİNK `?friend=KOD` ilə paylaşır, artıq kopyalamır · `ScrollContainer` içindəki kod sahəsi açılır · sahədən başlayan sürüşdürmə sonrakı toxunuşu silahlamır |

> Masaüstü tətbiqin brauzer paneli GİZLİ olanda `requestAnimationFrame` dayanır —
> Godot toxunuşu emal etmir və sınaq təsadüfi uğursuz olur. JS-lə yaradılan sintetik
> `TouchEvent`-lər də etibarlı deyil. Etibarlı yol: CDP-nin `Input.dispatchTouchEvent`-i.

İkonlar (DOSTLAR, dost əlavə et, lider tacı, dəvət məktubu, link) Codex ilə
çəkilib — bax [design/menu_art/](design/menu_art/). Şəbəkəsiz stend (uydurma
komanda ilə):

```bash
GODOT --path game --resolution 1280x720 -- --social-demo home --shot C:/yol/kadr.png --shot-delay 200
# home | solo | invite | friends | requests | recent
```

---

## Windows-da sınamaq — ən sürətli yol

```
build/GermArena.exe
```

Tək fayldır (PCK içindədir), quraşdırma tələb etmir. Açıb **MƏŞQ (offline)**
düyməsini bas — botlarla dolu dünya dərhal açılır, serverə ehtiyac yoxdur.

| | |
|---|---|
| `WASD` və ya ox düymələri | hərəkət |
| `BOŞLUQ` (və ya `ENTER`) | top atmaq — avtomatik nişanla |
| `SHIFT` (və ya `Q`) | **super** — dolubsa |
| `ESC` | matçdan çıxış təsdiqi · menyuda açıq vərəqi bağlayır |
| Siçan | ekran joysticki və düymələr; atəş düyməsini sürüşdürmək — nişan |

> **Niyə klaviatura?** Oyun toxunuş üçün qurulub, siçan isə Godot-da BİR toxunuş
> kimi emulyasiya olunur — yəni siçanla eyni anda həm hərəkət etmək, həm atmaq
> mümkün deyil. PC-də əsl oyun hissi yalnız klaviatura ilə alınır.
> Əsl sınaq yenə telefondadır (`build/GermArena.apk`).

`build/GermArena.console.exe` eyni oyundur, amma terminal pəncərəsi ilə açılır —
xəta və server loglarını görmək üçün.

Yenidən qurmaq:
```bash
GODOT --headless --path game --export-release "Windows" build/GermArena.exe
```

---

## Canlı server — Render

```
https://germ-arena.onrender.com       brauzer versiyası — linki açıb oyna
wss://germ-arena.onrender.com/ws      oyun serveri (telefon və masaüstü build-ləri)
```

Sayt və oyun serveri **bir** Render servisidir: nginx `/` ünvanında brauzer
build-ini verir, `/ws`-i isə eyni konteynerdəki Godot serverinə ötürür (bax
["Render-də saxlamaq"](#render-də-saxlamaq)). Brauzer versiyası server ünvanını
səhifənin ÖZ ünvanından götürür ([`Const.default_server`](game/scripts/shared/constants.gd)),
telefon və masaüstü build-ləri isə `DEFAULT_SERVER`-i işlədir.

> ⏳ **Pulsuz plan 15 dəqiqə boş qalanda yatır.** Yatmış servisin ilk açılışı
> ~1 dəqiqə çəkir — Render konteyneri oyadır. Brauzerdə bu, sadəcə uzun
> yüklənmədir: səhifə açılanda server artıq oyaqdır. Telefonda isə OYNA-nın
> 12 saniyəlik həddi oyanmadan qısadır — "cavab yoxdur" görünsə, bir dəqiqə
> sonra yenidən bas.

Serverə oynamadan baxmaq:
```bash
bash tools/check_server.sh                            # Render
bash tools/check_server.sh ws://127.0.0.1:27015       # lokal server
```

Şəbəkəsiz oynamaq həmişə mümkündür: **MƏŞQ (offline)** — eyni dünya kodu
botlarla yerli işləyir.

Texniki qərarlar və yol xəritəsi: [PLAN.md](PLAN.md) ·
Vizual üslub: [design/ART_BIBLE.md](design/ART_BIBLE.md) ·
Səs üslubu: [design/AUDIO_BIBLE.md](design/AUDIO_BIBLE.md) ·
Dizayner brifi: [design/BRIEF.md](design/BRIEF.md)

---

## Qovluq strukturu

```
game/                    Godot layihəsi
  scripts/
    shared/              Client VƏ server tərəfindən paylaşılan kod
      sim.gd             ★ Oyunun bütün məntiqi (hərəkət, top, udma, partlama)
      constants.gd       Sabitlər və snapshot sahə indeksləri (autoload: Const)
      net.gd             Bütün RPC-lər, ENet/WebSocket seçimi (autoload: Net)
      dish_map.gd        Petri qabındakı maneələrin düzümü
      bot.gd             Bot mikrob — serverdə işləyir, dünyanı canlı saxlayır
      palette.gd         Kod tərəfdən çəkilən rənglər
      settings.gd        Oyunçunun bütün ayarları, `settings.cfg` (autoload: Settings)
      social.gd          Dostluq qaydaları: oyunçu kodu, yoxlama simvolu, limitlər, linklər
    server/
      lobby.gd           Dünyalar, giriş/çıxış, yenidən qoşulma
      world.gd           Bir petri qabı: Sim + oyunçular + botlar + snapshot
      social_hub.gd      Dostluq sorğuları, vəziyyət, komandalar, dəvətlər (diskə yazmır)
    client/
      arena.gd           ★ Oyun ekranı: prediction, interpolyasiya, kamera, reconnect
      menu_v2.gd         ★ Baş menyu: fon + podiumda qəhrəman, növ kartları, qoşulma
      main_menu.gd       KÖHNƏ şaquli menyu — ehtiyat (`--menu1`), sonra silinir
      hud.gd             Doluluq göstəricisi, liderlər, xəbərdarlıqlar, nəticə
      germ_visual.gd     Bir mikrobun görüntüsü — ÜÇ NÖV (üzür, yeriyir, sürünür)
      burst_fx.gd        Partlayaraq ölmə effekti (dalğa, damcı, membran parçaları)
      juice_fx.gd        Qısa VFX-lər — bütün hadisələr bir node-da, ən çox 3 batch
      shot_trails.gd     Uçan topların izi — hamısı BİR çəkiliş çağırışında
      shot_prediction.gd Öz topunun proqnozu — serveri gözləmədən uçur və dəyir
      water_motes.gd     Suda asılı zərrəciklər — axını gözlə görünən edir
      minimap.gd         Petri qabının kiçik xəritəsi
      batch_draw.gd      Dairə və nazik halqa — bir çəkiliş çağırışına yığılan variant
      touch_stick.gd     Üzən virtual joystick (hərəkət)
      fire_button.gd     Top atma düyməsi (basılı saxlananda davamlı atəş)
      super_button.gd    Super düyməsi — maye dolumu, hazır nəbzi və işıq zolağı
      sfx.gd             Səs effektləri (autoload: Sfx)
      settings_view.gd   AYARLAR ekranı — yalnız menyuda (matçda ayar yoxdur)
      friends.gd         Dostlar və komanda: cihazdakı siyahı + RPC-lər (autoload: Friends)
      friends_view.gd    DOSTLAR ekranı: kodun, dost əlavə et, komanda, sorğular, son oyunçular
      chunky_box.gd      Brawl Stars düymə dili: kontur + dodaq + parıltı, konturlu yazı
      touch_slider.gd    Səs sürgüsü — barmaq üçün (Godot-un HSlider-i çox kiçikdir)
      web_text.gd        Telefon brauzerində yazı sahəsi — HTML pəncərəsi (iOS klaviaturası üçün)
    tools/
      sim_test.gd        604 headless test (`--simtest`)
      auto_client.gd     Şəbəkə testi üçün insansız client (`--party` ilə komanda testi)
      social_test.gd     Dostluq və komanda testləri (`--simtest`-in içindən)
      social_demo.gd     Dostlar/komanda ekranlarının şəbəkəsiz stendi (`--social-demo`)
      hit_probe.gd       Vuruşu EKRANDA ölçür: toxunuş → parıltı, topun rəqibdən keçməsi
      net_probe.gd       Şəbəkəni ölçür: snapshot boşluğu, gecikmə, ACK donması (`--net-probe`)
      stall_probe.gd     Donmanı kadr-kadr ölçür: bufer boşluğu, geri sıçrayış (`--stall-probe`)
      super_probe.gd     Superi həqiqi düymə ilə basır: server, proqnoz, görüntü (`--super-probe`)
      screenshot.gd      Redaktorsuz ekran görüntüsü
      species_preview.gd Növün görüntü stendi — tək mikrob, böyüdülmüş
      map_preview.gd     Xəritə düzümünün stendi — bütün qab yuxarıdan
      perf_probe.gd      Kadr vaxtı və çəkiliş çağırışı ölçmə
  assets/                SVG sprite-lar, UI, şriftlər, WAV səslər
    fonts/               Baloo 2 (başlıq) + Nunito (mətn) — bax «Şriftlər»
    ui/theme.tres        Şrift rolları; bütün Control-lar bunu oxuyur
    sprites/             maneə sprite-ları: blob, bloom (SELİK) · crust ×3 (KÖVRƏK,
                         zədə mərhələləri) · bush + bush_top (KOL) · vent (CƏRƏYAN)
                         · dish_floor (qabın döşəməsi)
    menu/                ana ekranın illüstrasiyaları (Codex): fon, podium, üç
                         növün qəhrəmanı — mənbə və promptlar design/menu_art/-da
  web/shell.html         Brauzer versiyasının HTML qabığı
design/                  Dizayn mənbəyi (art/audio bible, brif, sprite, səs generatoru)
tools/                   Build və deploy skriptləri
build/                   Hazır APK və Linux server binarı
deploy/render/           Render: sayt + oyun serveri bir konteynerdə (mənbədən build)
render.yaml              Render servisinin tərifi
web/                     Railway: brauzer versiyasının hostinqi (nginx konteyneri)
Dockerfile               Railway: hədəf serverin konteyner tərifi
railway.json             Railway deploy konfiqurasiyası
```

★ ilə işarələnən iki fayl layihənin özəyidir.

---

## Necə işə salmaq

Godot bu maşında quraşdırılıb:
`C:\Users\User\Godot\Godot_v4.7.2-stable_win64.exe` (aşağıda `GODOT`).

```bash
GODOT --path game --editor        # redaktorda aç
GODOT --path game                 # oyunu işə sal (menyudan)
```

### Məşq rejimi — şəbəkəsiz, botlarla
```bash
GODOT --path game -- --practice

# Mikrob növünü seçərək (0 kirpikli · 1 ayaqlı · 2 amöb):
GODOT --path game -- --practice --species 2

# Rejimi seçərək (0 sonsuz · 1 TƏK QALAN · 2 CÜT · 3 ÜÇLÜK):
GODOT --path game -- --practice --mode 3

# Qrafika səviyyəsi (0 yüksək · 1 aşağı · 2 minimum) — sabit qalır, avtomatika işləmir:
GODOT --path game -- --practice --quality 1
```
Eyni `World` və `Sim` kodu yerli işləyir; fərq yalnız snapshot-ların şəbəkədən
yox, yaddaşdan gəlməsidir. Server yatmış olsa da oyun oynanır.

`--species` və `--mode` menyunu keçdiyimiz üçün lazımdır: birbaşa dünyaya
düşəndə `settings.cfg` oxunmur. `--shot` ilə birlikdə hər növün və hər
rejimin görüntüsünü redaktoru açmadan, təkrarlana bilən şəkildə yoxlamağa
imkan verir.

> Quruma `--mode 1`-də 45 saniyə sonra başlayır — ekran görüntüsü üçün çox
> gözlətmə. Yoxlayarkən `Const.DRY_DELAY`-i müvəqqəti azalt, çək, sonra geri
> qaytar. Bayraq ƏLAVƏ ETMƏ: sınaq üçün qoyulan bayraq buraxılışda qalır.

### Serveri lokal qaldırmaq
```bash
GODOT --headless --path game -- --server --port 27015            # ENet (UDP)
GODOT --headless --path game -- --server --ws --verbose          # WebSocket + diaqnostika
```
Sonra menyuda server sahəsinə `ws://127.0.0.1:27015` yaz.
Server və oyun EYNİ build-dir — simulyasiya kodu ikisində eynidir.

### Testlər
```bash
# Simulyasiya + World + dostluq/komanda testləri (604 test)
GODOT --headless --path game -- --simtest

# Şəbəkə inteqrasiya testi: 1 server + 2 insansız client
#   --mode <0|1> və --species <0|1|2> ilə rejim/növ seçilir; onsuz
#   TƏK QALAN-ın onlayn yolu heç vaxt sınanmır.
GODOT --headless --path game -- --server --ws --verbose &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label A --quit-after 30 &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --quit-after 30 &

# Yenidən qoşulma testi: B 10 saniyə sonra qəsdən düşür və nişanla qayıdır
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label B --drop-after 10 --quit-after 30 &

# Dostlar və komanda: Ana Bob-a sorğu göndərir, Bob qəbul edir, Ana onu komandaya
# dəvət edir, ikisi HAZIR olur və server onları EYNİ CÜT komandasına salır.
# --secret kimlikdir (diskə yazılmır), oyunçu kodu ondan hesablanır.
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label Ana \
      --secret aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa --befriend-secret bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb \
      --party 2 --mode 2 --quit-after 20 &
GODOT --headless --path game -- --autoclient --host ws://127.0.0.1:27015 --label Bob \
      --secret bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb --party 2 --quit-after 20 &
```

Şəbəkə donmasını ölçmək (bax [«Donma və dəstə»](#donma-və-dəstə--server-yoxsa-wi-fi)):

```bash
# Snapshot boşluqları, gecikmə, giriş→təsdiq vaxtı, ACK donması (hər 10 s bir sətir)
GODOT --headless --max-fps 60 --path game -- --autoclient --host wss://germ-arena.onrender.com/ws \
      --label A --quit-after 240 --net-probe --net-probe-csv C:/yol/A.csv
# Üstəlik hər kadr: bufer boşdurmu, rəqiblər geri sıçrayırmı, öz mikrobun nə qədər sıçradı
#   --stall-probe --stall-probe-csv C:/yol/A_kadr.csv [--stall-move flip:0.6] [--stall-hitch 8:400]
```

`--max-fps` vacibdir: onsuz headless client həddsiz fırlanır. CSV yolu MÜTLƏQ
olmalıdır. Hər iki probe ([`net_probe.gd`](game/scripts/tools/net_probe.gd),
[`stall_probe.gd`](game/scripts/tools/stall_probe.gd)) yalnız bu bayraqlarla
yüklənir, oyunun özündə yoxdur.

Testlər oyunun HƏR İKİ ölüm qaydasını ayrıca yoxlayır: tutumu aşıb partlamaq
və acından partlamaq. Bunlar oyunun bütün balansının dayandığı iki qaydadır.

Ayaqlı mikrobun **yerişi** də buradadır — ekran görüntüsü ilə yoxlana bilməyən
üç xassə: dayanan mikrob ayaqlarını tərpətməməli, ayaqlar sonsuz dartılmamalı,
və hər an ayaqların çoxu yerdə qalmalıdır. Sonuncu məhz bu testlə tapıldı:
mikrob yerindən tərpənəndə bütün ayaqlar bir anda qalxırdı, yəni yerimirdi,
sıçrayırdı — bir kadrlıq hadisə olduğuna görə gözlə görünmürdü.

Maye modeli də buradadır: mikrobun buraxandan sonra sürüşdüyü, axının hər
nöqtədə eyni qaldığı, şüşənin dibində dayandığı və **divergensiyasız** olduğu
ayrıca yoxlanılır. Sonuncu ədədi testdir (mərkəzi fərqlə `∂vx/∂x + ∂vy/∂y`) —
pozulsa qida burulğanlarda ilişər və dünyanın bir hissəsi acından qırılar.

### Performans ölçmək
```bash
GODOT --path game --resolution 1280x720 --disable-vsync -- --practice --mode 0 --perf 12
```

> ⚠️ **`--disable-vsync` MƏCBURİDİR.** Alət divar saatının kadr aralığını ölçür;
> vsync açıq olanda o aralıq oyunun yükündən yox, EKRANIN tezliyindən çıxır.
> 240 Hz monitorda nəticə həmişə 4.17 ms olur — yük nə olursa olsun. Bir dəfə
> bu rəqəmə inanılıb buraya "büdcənin 25%-i" yazılmışdı; həqiqi yük 10–12%
> imiş. Alət indi vsync açıq olanda xəbərdarlıq edir, amma bayrağı vermək
> yenə sənin işindir.

Orta, **1% ən pis** kadr, çəkiliş çağırışı və yaddaş yazılır.
Masaüstü nəticəsi (RTX 5050), `--disable-vsync` ilə. “Əvvəl” bu sənəddəki ilkin
ölçüdür; “M2” xəritə redizaynından sonrakı ağacdır; “M3” animasiya/VFX/UI
qatının 2026-09-17 yekun ölçüsüdür:

| Rejim | Əvvəl orta | M2 orta | **M3 orta** | **M3 1% ən pis** | M3 büdcə | Çəkiliş çağ. pik (əvvəl → M2 → M3) |
|---|---:|---:|---:|---:|---:|---:|
| SONSUZ ARENA (6 mikrob) | 1.85 ms | 2.15 ms | **2.48 ms** | **3.70 ms** | **15% / 22%** | ~230 → 188 → **196** |
| TƏK QALAN (10 mikrob) | 2.82 ms | 2.93 ms | **2.35 ms** | **4.03 ms** | **14% / 24%** | ~212 → 249 → **202** |

Hər iki rejimdə 16.7 ms-i aşan kadr **0**-dır. Pik çağırışlar 350 həddindən
müvafiq 154 və 148 aşağıdır. Eyni M3 reviziyasının daha sıx TƏK QALAN
çalışmasında **263** pik də müşahidə olunub; konservativ ehtiyat yenə 87-dir.
Səhnə təsadüfi olduğuna görə çağırış sayı görünən mikrob/top/qida ilə dəyişir.
Hadisə sayı artmasına baxmayaraq limitin qorunmasının səbəbi yeni VFX-in hadisə
başına node yox, ortaq batch olmasıdır. TƏK QALAN-da dörd əlavə mikrob və quruma
materialı ən bahalı kombinasiyadır, ona görə mikrob sayını artıran hər rejim bu
cədvəldə ayrıca ölçülməlidir.

> Çəkiliş çağırışının 280-dən ~170-ə düşməsi bir dəyişiklikdən gəlir: səhnə
> qatları növlərə bölündü (bütün qida bir qatda, bütün toplar başqasında) və
> maneələr sprite-a keçirildi. Godot yalnız ARDICIL və eyni teksturalı elementləri
> bir çağırışa yığır — qarışıq düzülsə, hər qida topu ayrıca çağırış olur.

### Brauzerdə (Android) donma və kəsilmə

Şikayət: Android-də brauzerdə açanda oyun donur, oynananda kəsilir. Telefon
qoşulu olmadığı üçün Chrome-da Android emulyasiya olunub (puppeteer-core:
915×412 ekran, DPR 2.625, toxunuş, Android user-agent, **CPU 4× yavaş** — orta
səviyyəli telefon). Ölçmə üçün layihənin surəti instrumentasiya olunub; əsas
koda ölçmə kodu girməyib.

**1. Telefon brauzeri masaüstü sayılırdı.** Veb build-də `OS.has_feature("mobile")`
telefonda da YALANDIR — Godot telefonun brauzerini `web_android` / `web_ios` kimi
tanıyır (emulyasiyada yoxlanıb: `web_android=true mobile=false`). Nəticədə
telefonda oyun **YÜKSƏK** keyfiyyətlə (glow + RGBA16F HDR buferi, ~1830×824
kadrda) və **kadr həddi olmadan** açılırdı: 90/120 Hz ekranda saniyədə 90–120
kadr. İndi [`Const.is_handheld`](game/scripts/shared/constants.gd) üçünü də
yoxlayır: telefon brauzeri AŞAĞI + 60 FPS ilə, zəif telefon isə MİNİMUM + 30
FPS ilə açılır (bax 4-cü bənd).

Menyu OYNA basılanda bütün ayarları yazır, yəni əvvəl oynamış hər kəsdə YÜKSƏK
diskdə qalmışdı. Ona görə keyfiyyət və kadr həddi yalnız oyunçu onları
AYARLAR-da **özü seçibsə** fayldan oxunur (`quality_chosen`, `fps_chosen` —
[`Settings`](game/scripts/shared/settings.gd)).

**2. Açılışda donma.** Yükləmə zolağı bitəndən sonra ekran saniyələrlə donurdu.
Addım-addım ölçülüb (CPU 4×, eyni sessiyada əvvəl/sonra):

| Addım | Əvvəl | Sonra | Nə dəyişdi |
|---|---:|---:|---|
| Mühərrikin açılışı (wasm, shader-lər, şriftlər) | ~5.0 s | ~5.0 s | mühərrikin işidir, GDScript-dən dəyişmir |
| `boot.gd` yüklənməsi | 2.73–2.84 s | 0.91 s | test alətləri (`SimTest`, `PlayAgent` …, ~6 000 sətir) artıq yalnız lazım olanda yüklənir |
| Menyunun qurulması | 1.47–1.49 s | 0.91–0.94 s | növ/rejim vərəqi ilk açılışda qurulur; arena və `GermVisual` menyu ilə birlikdə kompilyasiya olunmur |
| İlk kadrın render-i | 232–249 ms | 131–138 ms | AŞAĞI keyfiyyət (glow yoxdur) |
| **Menyunun ilk kadrı** | **10.4–10.6 s** | **8.2–8.35 s** | |

**3. Oyunda kəsilmə.** Kadrın ən böyük payı mikrobların hər kadr GDScript-də
yenidən çəkilməsi idi. Server ekrandan ~3 dəfə böyük sahəni göndərir və
görünən mikrobların çoxu kadrdan kənarda qalır, amma hamısı çəkilirdi.
Minixəritə də saniyədə 60 dəfə 26 maneəni təzədən çəkirdi. Düzəlişlər:

- ekrandan kənardakı mikrob yenidən çəkilmir ([`GermVisual.on_screen`](game/scripts/client/germ_visual.gd));
- AŞAĞI keyfiyyətdə rəqibin FORMASI saniyədə 30 dəfə yenilənir. Hərəkət yenə
  60 kadrla gedir, çünki mövqe çəkilişdən ayrıdır. Öz mikrobun və zərbə
  anları hər kadr çəkilir ([`GermVisual.redraw_step`](game/scripts/client/germ_visual.gd));
- gövdənin forması kadrda bir dəfə qurulur (əvvəl kölgə üçün ikinci dəfə);
- minixəritə saniyədə 10 dəfə yenilənir, maneələri isə ayrı qatdadır və yalnız
  divar dağılanda çəkilir.

Sabit toxumlu benchmark (görüş dairəsində 10 mikrob — TƏK QALAN-ın sonu kimi
sıx döyüş), CPU 4×, 3 çalışma:

| | Əvvəl (telefonda YÜKSƏK) | Sonra (telefonda AŞAĞI) |
|---|---:|---:|
| Kadrda çəkilən mikrob | 10.1 | 4.0 |
| Mikrobların çəkilişi | ~46 ms | ~17 ms |
| Kadr | 70.5–72.6 ms (~14 FPS) | **35.3–35.6 ms (~28 FPS)** |
| 50 ms-dən uzun kadr | 100% | 1–5% |

Qalan xərc: bir mikrobun çəkilişi hələ də bahalıdır (içindəki toplar, kirpiklər,
işıqlandırma poliqonu). Növbəti addımlar ölçüyə görə budur: içindəki topları
teksturaya bişirmək və 3D-siz xüsusi veb şablonu (mühərrikin açılışındakı 3D
shader kompilyasiyası CPU 4×-də ~1.9 s çəkir).

**4. Zəif telefonlar — MİNİMUM səviyyə.** Ucuz Android telefonların çoxu
hələ də Helio G85 / Unisoc T606 / Snapdragon 680 sinfindədir: iki böyük A75
nüvəsi + altı kiçik A55 (Snapdragon 680-də dörd A73 + dörd A53), qrafika Mali-G52 MC2, Mali-G57 MP1 və ya
Adreno 610, yaddaş 2–4 GB. Bu çiplərin CPU-su orta telefondan (yuxarıdakı 4×
emulyasiya) təxminən 1.6 dəfə zəifdir, ona görə ölçü **6.5× yavaş CPU** ilə
təkrarlandı. AŞAĞI səviyyədə kadrın işi 37 ms idi, yəni 60-lıq hədd heç vaxt
tutulmurdu, kadrlar 25–60 ms arasında atlanırdı.

Buna görə üçüncü səviyyə əlavə olundu — **MİNİMUM**:

| | AŞAĞI | MİNİMUM |
|---|---|---|
| Kadr həddi | 60 | **30**, oyunçu hədd seçməyibsə. Sabit 30 kadr, 30 ilə 60 arasında atlanmaqdan hamar görünür |
| Render ölçüsü | brauzerdə kətan DPR ≤ 2 (`web/shell.html`): 915×412 CSS → 1830×824 | brauzerdə **kətan DPR 1.25**: 1143×515, ekrana böyütməni brauzer edir. Telefon tətbiqində (APK) 1280×720, sonra böyüdülür (`VIEWPORT`) |
| Mikrob ([`GermVisual.lod`](game/scripts/client/germ_visual.gd)) | tam | kirpiklərin yarısı bir çağırışda çəkilir, kölgə tək qatdır, parıltı və kənar işığı yoxdur, içindəki toplar sadədir |
| Su zərrəcikləri | 34+14 | 12+8 |
| Minixəritə | 10 Hz | 5 Hz |

**Avtomatik seçim iki qatdır.**
- **Birinci qat — cihazın özü** ([`Const.default_quality`](game/scripts/shared/constants.gd)).
  Yaddaş ≤ 3 GB-dırsa və ya qrafikanın adı zəiflər siyahısındadırsa, telefon
  MİNİMUM ilə açılır. Yaddaş `navigator.deviceMemory`-dən oxunur; brauzer onu
  2/4/8-ə yuvarlaqlaşdırır. Ad `WEBGL_debug_renderer_info`-dan gəlir; siyahıda
  Mali-G31/G51/G52, Mali-T, PowerVR, Adreno 3xx/4xx/50x/51x/60x/610 var.
  Qalan telefonlar AŞAĞI ilə açılır.
- **İkinci qat — oyunun içində kadr vaxtı** ([`Arena._watch_performance`](game/scripts/client/arena.gd)).
  Siyahı yanıla bilər: brauzer adı gizlədə bilər, siyahıda olmayan zəif çip də
  var. Arena açılandan 4 s sonra hər 5 s-də kadrlar yoxlanır. Median kadr
  büdcədən 35% uzundursa və ya hər onuncu kadr iki qat uzundursa, səviyyə bir
  pillə enir: YÜKSƏK → AŞAĞI → MİNİMUM. Ekranda "QRAFİKA AVTOMATİK" yazılır və
  seçim yadda qalır (`auto_quality`).

Oyunçu keyfiyyəti AYARLAR-da özü seçibsə, heç nə avtomatik dəyişmir.

Sabit toxumlu benchmark (görüş dairəsində 10 mikrob), CPU 6.5×, 2 çalışma:

| | Əvvəlki kod, YÜKSƏK | AŞAĞI | **MİNİMUM** |
|---|---:|---:|---:|
| Kadrın işi | 76.7–77.4 ms | 36.7–37.4 ms | **29.7–29.8 ms** |
| Kadr | 82.6–83.1 ms (~12 FPS) | 42.3–43.0 ms | **36.0–36.1 ms** (30-luq hədd) |
| Bir mikrobun bir çəkilişi | 5.5 ms | 5.3–5.4 ms | **2.6 ms** |
| 50 ms-dən uzun kadr | 100% | 19–23% | **0.5–2.3%** |

Avtomatika emulyasiyada da yoxlanıb. Onlayn oyun AŞAĞI ilə açıldı, ilk
yoxlamada yavaşlığı tapıb MİNİMUM-a keçdi və kadr 37–43 ms-ə düşdü (iş 27–32 ms).

Sonra onlayn oyunun özü profil edildi (MİNİMUM, 6.5×). HUD hər tick
lazımsız iş görürdü:

| | Əvvəl | Sonra | Nə dəyişdi |
|---|---:|---:|---|
| Doluluq göstəricisi | 0.86–2.33 ms | 0.22–0.42 ms | Say dəyişməyibsə yazıya və rəngə toxunulmur. `add_theme_color_override` eyni rəngdə də yazını yenidən düzürdü |
| Atəş düyməsi | 0.76–1.55 ms | 0.45–0.70 ms | Atəşdən sonrakı 1 s-də yalnız halqa təzədən çəkilir; o, ayrı qatdadır |
| Minixəritə | 0.47–0.90 ms | 0.13–0.26 ms | 26 maneə ayrı qatdadır və yalnız divar dağılanda çəkilir |
| **HUD-un cəmi** | **2.5–4.8 ms** | **0.9–1.3 ms** | kadr başına ~70% az |

Rəqəmlər kadr başınadır: təzə serverdə köhnə və yeni build növbə ilə, iki
sessiyada ölçülüb. Kadrın ümumi işi hər sessiyada ekrandakı döyüşdən asılı
olaraq 25–38 ms arasında dəyişir. Ona görə HUD-un qənaəti ayrıca, hissə-hissə
verilib. Eyni səhnəyə yaxın bir cütdə kadrın işi 29.2 ms-dən 25.7 ms-ə endi,
50 ms-dən uzun kadr isə 58 / 654-dən 25 / 708-ə düşdü.

**5. GPU yükü — piksel sayı.** Chrome-un CPU yavaşlatması yalnız səhifənin
JS/wasm işini yavaşladır, GPU işinə toxunmur. Ona görə GPU tərəfi ayrıca
ölçüldü: **SwiftShader** (Chrome-un proqram GPU-su, `--use-angle=swiftshader`)
hər pikseli CPU-da rəngləyir, yəni zəif mobil GPU kimi piksel doldurmaya
həssasdır. Məşq oyunu, MİNİMUM detalı, iki çalışma:

| Render | Piksel | FPS | Kadrın işi |
|---|---:|---:|---:|
| Kətan DPR 2 (AŞAĞI) | 1.51 M | 32–36 | 27–30 ms |
| `VIEWPORT` 1280×720 (MİNİMUM-un əvvəlki halı) | 0.92 M + böyütmə | 33–40 | 24–29 ms |
| Kətan DPR 1.5 | 0.85 M | 42–44 | 22 ms |
| **Kətan DPR 1.25** | **0.59 M** | **57–59** | **8–13 ms** |
| Kətan DPR 1.0 | 0.38 M | 60 (hədd) | 5–6 ms |

`VIEWPORT` rejimi brauzerdə az qazanc verir: kətan onsuz da DPR 2 ilə
məhduddur, səhnə 1280×720-də çəkilsə də üstəlik ayrıca böyütmə keçidi gedir.
Kətanı kiçiltmək isə birbaşa işləyir — ekrana böyütməni brauzerin kompozitoru
onsuz da edir. Ona görə brauzerdə MİNİMUM indi kətanın sıxlığını endirir
([`Settings._apply_render_scale`](game/scripts/shared/settings.gd) →
`window.germSetMaxDpr` [`web/shell.html`](game/web/shell.html)-də). Yekun
build-də (SwiftShader) AŞAĞI 1830×824-də ~30 FPS-də qalır, kadrın işi 32–33 ms-dir;
MİNİMUM 1143×515-də 30-luq həddi tutur, kadrın işi **6.3–6.6 ms**-dir.

Real telefonların GPU-su da yoxlandı — shader-lər **sığırmı**. Godot-un hər
shader proqramının adi uniform-ları sayıldı (WebGL2, masaüstü Chrome): ən çoxu
**36 vektor**dur, qalanı UBO-dadır (ən böyüyü 4 KB). WebGL2-nin minimumu 224
vektor və 16 KB-dır, Adreno adətən 256 verir — yəni ehtiyat böyükdür.

**6. Real Android brauzeri — emulyatorda.** Telefon qoşulu olmadığı üçün
Android SDK-ya emulyator quruldu: Android 14, Chrome 113, **2 GB yaddaş**,
4 nüvə, ekran 1080×2400 (DPR 2.625), yatay. Oyun `localhost` üzərindən
(`adb reverse`) açıldı — `navigator.deviceMemory` yalnız təhlükəsiz kontekstdə
işləyir. Chrome DevTools protokolu ilə idarə olundu.

| | Nəticə |
|---|---|
| Avtomatik seçim | `deviceMemory = 2` → **MİNİMUM**, kadr həddi 30 — heç bir bayraq verilmədən |
| Kətan | CSS 866×308 (Chrome-un paneli çıxılır) → **1082×385** (DPR 1.25) |
| MİNİMUM | sabit **30 FPS**, kadrın işi 11.7–13.1 ms |
| AŞAĞI (müqayisə) | kətan 1732×616, **49 FPS** — 60-lıq hədd tutulmur |
| Onlayn (RTT 120 ms proksi ilə) | zərbə dərhal göstərilir, keçid yoxdur, 29.9 FPS |
| Açılış | 3–6 s |

Emulyatorun **proqram GPU-su** ilə (`-gpu swiftshader_indirect`) oyun heç
çəkilmədi: `Fragment shader active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`.
Səbəb emulyatorun GLES tərcüməçisidir — o, UBO-ları adi uniform-lara çevirir
(256 + 36 > 261). Real telefon sürücüsü UBO-nu özü saxlayır (yuxarıdakı yoxlama),
ona görə ölçmə host GPU ilə (`-gpu host`) aparıldı.

Emulyatorda bir problem də tapıldı: brauzerin dili başqa olanda Chrome aşağıda
**"tərcümə et" paneli** açırdı və o, joystik ilə atəş düyməsinin üstünə düşürdü.
`web/shell.html`-ə `translate="no"` və `<meta name="google" content="notranslate">`
əlavə olundu — panel artıq çıxmır.

**7. Zəif GPU — dinamik kətan sıxlığı.** Yuxarıdakı ölçülər emulyasiyadır:
SwiftShader piksel doldurmaya həssas modeldir, amma real Mali/Adreno-nun
millisaniyəsi başqa olacaq, və o telefon əlimizdə yoxdur. Ona görə oyun artıq
GPU-nun mütləq sürətinə bel bağlamır — kadr vaxtını **həmin telefonun özündə**
ölçüb kətanın piksel sıxlığını tənzimləyir ([`Arena._watch_resolution`](game/scripts/client/arena.gd)):

- Keyfiyyət səviyyəsi birinci addımdır (4-cü bənd). MİNİMUM-da (və ya oyunçu
  səviyyəni özü seçibsə) hər 3 s-lik pəncərədə kadrlar yoxlanır. Kadrın medianı
  30 kadrın büdcəsini 10% aşırsa, və ya kadrların onda biri 35% uzundursa,
  kətanın sıxlığı 15% kiçilir, 0.75-ə qədər.
- **Yük GPU-dadır, yoxsa CPU-da — brauzerdə soruşulmur.** İlk variant bunu kadrın
  CPU işindən ayırırdı. Real Chrome-da yoxlananda (aşağıda) GPU prosesi 100% dolu
  ikən oyunun "CPU işi" də kadrın özünə bərabər çıxdı — 80 ms: WebGL əmrləri GPU
  prosesinə növbə ilə gedir, GPU geri qalanda növbə dolur və kadrın İSTƏNİLƏN GL
  çağırışı, `_process`-dəki də, gözləyir. Tənzimləyici yükü CPU-da sanıb heç nə
  etmirdi. İndi sual təcrübə ilə həll olunur: kiçiltmə iki addımda (piksel ~48%
  az) orta kadrı qısaltmayıbsa, yük pikseldə deyil — sıxlıq geri qaytarılır və bu
  sessiyada daha kiçilmir.
- 4 pəncərə ardıcıl rahatdırsa, sıxlıq 12% böyüyür. Böyümə kadrı yavaşladırsa,
  əvvəlki sıxlığa qayıdır və o, sessiyanın tavanı olur — titrəmir.
- Büdcə kadr həddindən asılı olmayaraq 30 kadrdır: məqsəd zəif GPU-da oyunu
  OYNANAN saxlamaqdır, 60 kadr xatirinə şəkli bulandırmaq yox. Enerjiyə qənaət
  rejimində brauzer kadrı özü 30-a kəsir — büdcə 60 olsaydı, sıxlıq boş yerə
  dibə enərdi.
- Öyrənilən sıxlıq yadda qalır (`video/auto_dpr`); keyfiyyəti dəyişəndə sıfırlanır.

Tənzimləyici GPU-nun geniş aralığında modeldə yoxlanıb (`_test_resolution_converges`):
GPU işi piksel sayı ilə artır, kadr 60 Hz ekranın vsync-inə yuvarlanır, ±8% səs-küy:

| 1.25 sıxlıqda kadrın GPU işi | Tənzimləyici gəlir | Ən böyük uyğun sıxlıq | Kadr |
|---:|---:|---:|---:|
| 12 ms, 30 ms | 1.25 (dəyişmir) | 1.25 | 30 FPS |
| 45 ms | 1.01 | 1.04 | 30 FPS |
| 60 ms | 0.86 | 0.90 | 30 FPS |
| 80 ms | 0.77 | 0.78 | 30 FPS |
| 110 ms, 150 ms | 0.75 (aşağı hədd) | — | 20, 15 FPS |
| GPU 80 ms + CPU 30 ms | 0.77 | | 30 FPS |
| CPU yüklü (45 ms), GPU yüngül | iki dəfə kiçilir, kömək etmədiyini görüb 1.25-ə qayıdır | | |
| Enerjiyə qənaət (brauzer 30 kadr verir) | 1.25 (dəyişmir) | | |

Yəni SwiftShader-in 6.5 ms-lik MİNİMUM kadrından **12 dəfə** zəif GPU-da da oyun
30 kadrı tutur. Ondan da zəifində sıxlıq aşağı həddə enir və oyun o GPU-nun
verə bildiyi ən yaxşı kadrla gedir.

**Real Chrome-da yoxlama.** Eyni veb build (MİNİMUM, telefon emulyasiyası 915×412,
DPR 2.625), SwiftShader ilə. "GPU"-nun gücü GPU prosesinə verilən nüvə sayı ilə
dəyişdirildi, CPU-yüklü telefon isə Chrome-un CPU yavaşlatması ilə:

| Model | 1.25-də | Tənzimləyici | Sonra |
|---|---:|---|---:|
| GPU sərbəst | 30 FPS | dəyişmir | 30 FPS |
| GPU 2 nüvə | 15 FPS | 1.25 → 1.06 → 0.90 → **0.77**; 12 s rahat gedəndən sonra 0.86-ya qalxır və orada qalır | **30** → 28–29 FPS |
| GPU 1 nüvə | 13 FPS | 1.25 → … → 0.75 (aşağı hədd) | 15–17 FPS |
| GPU 1 nüvə, ekran DPR 1.25 | 10 FPS | 1.25 → … → 0.75 | 19 FPS |
| CPU 12× yavaş, GPU sərbəst | 7 FPS | 1.25 → 1.06 → 0.90, kadr dəyişmir → **1.25-ə qayıdır** | 7 FPS, şəkil bulanıqlaşmır |

Bir nüvəli GPU-da qazanc azdır, çünki SwiftShader brauzerin kompozitorunu da
proqramla çəkir: hər kadr bütün ekranı (2.6 milyon piksel), kətanın ölçüsündən
asılı olmayaraq. Ekranın DPR-i 1.25 olanda eyni GPU-da qazanc iki qatdır (10 → 19
FPS). Real telefonda bu kompozisiya GPU-nun aparatındadır. Bu yoxlama həm də
yuxarıdakı "CPU işi" səhvini tapdı: ilk variant 1 nüvəli GPU-da 13 FPS-də heç nə
etmirdi.

**Real telefonda ölçü necə oxunur.** Telefon qoşulan kimi heç nə qurmadan:
AYARLAR → «Kadr sayğacı» açılır — brauzerdə yanında kətanın sıxlığı da yazılır
(`30 FPS · 1.25x`). Uzaqdan sazlamada (`chrome://inspect`) konsola hər 30 s-dən
bir və sıxlıq dəyişəndə bir sətir düşür:

```
[perf] MİNİMUM · kətan 1.25 · kadr p50 33.3 / p90 33.4 ms (orta 30 FPS) · CPU 9.8 ms · hədd 30 FPS · GPU Mali-G52
[perf] kətan sıxlığı 1.25 → 1.06 ([perf] MİNİMUM · kətan 1.25 · kadr p50 50.0 / p90 50.1 ms ...)
```

Ölçü serverə göndərilmir: yeni RPC köhnə APK-ların RPC nömrələrini sürüşdürərdi
(Godot onları metod adına görə sıralayır).

**8. Galaxy A04s sinfi — brauzer, yoxsa APK?** (2026-10-17)

Şikayət: A04s kimi telefonlarda brauzerdə oyun donur. Sual: səbəb brauzerdirmi,
yoxsa APK da bu telefonlarda donacaq?

Cihaz: Exynos 850 — **səkkiz kiçik Cortex-A55** nüvə (2.0 GHz, böyük nüvə yoxdur),
Mali-G52 MP1, 3/4 GB, 720×1600 90 Hz ekran. Geekbench 6 tək nüvə **216** — bu
kompüterdən (Ryzen AI 7 350) ~13 dəfə, MİNİMUM-un hesablandığı Helio G85-dən
(~420, 4-cü bənd) iki dəfə zəif. Oyun onu düzgün tanıyır: `deviceMemory` 2 və ya 4,
GPU adı Mali-G52 → MİNİMUM, 30 kadr, kətan 1.25.

Masaüstü Chrome, telefon emulyasiyası, MİNİMUM, onlayn oyun, **13× yavaş CPU**
(A04s-in modeli), 45 s:

| | Əvvəl | İndi |
|---|---:|---:|
| FPS | 5.7 | **7.0** |
| Kadrın işi, orta / p90 | 149 / 233 ms | **118 / 177 ms** |
| Kadrda WebGL əmri | 5 874 | **3 929** |
| Kadrda çəkiliş çağırışı | 145 | **97** |

Üstəlik açılış: fayllar 2 s-də gəlir, menyu isə **24–28 s**-də çıxır (mühərrik,
shader-lər, menyunun qurulması); matça girişdə ekran **~3.2 s** donur (arena
skriptləri yüklənir).

Eyni **Android** cihazında (emulyator: Android 14, Chrome 113, `-gpu host`) eyni
onlayn ssenari, MİNİMUM, 30 kadr — APK ilə brauzer yan-yana:

| | APK | Brauzer, əvvəl | Brauzer, indi |
|---|---:|---:|---:|
| Əsas axının kadr işi | 8–12 ms | 23–27 ms | **16 ms** |
| Bütün CPU kadr başına | 10–14 ms | 42–43 ms | **34 ms** |
| Bunun GPU prosesi (Chrome) | — | 22–24 ms | 18 ms |
| 30 kadr tutulurmu | bəli | yox (28.8–29.3) | bəli |

**Nəticə: donmanın əsas səbəbi brauzerdir.** Eyni oyun brauzerdə təxminən **üç dəfə
çox CPU** yeyir: WebGL hər GL əmrini yoxlayıb ayrıca GPU prosesinə ötürür (Chrome-un
GPU prosesi tək başına APK-nın bütün işindən çoxdur), oyunun özü isə tək axında
WebAssembly-dir. A04s-də bu, ~7–13 FPS deməkdir — donma hissi. Masaüstündə native
build kadrı 3.2 ms işləyir; ×13 ilə APK A04s-də təxminən **20–25 FPS** verir: donmur,
amma sıx döyüşdə 30-u tam tutmur. Bu sinif telefon üçün tövsiyə APK-dır. Rəqəmlər
emulyasiyadır — A04s əlimizdə yoxdur; real telefonda 7-ci bənddəki `[perf]` sətri ilə
yoxlanmalıdır.

Brauzerdə düzəldilənlər:

- **Kadr həddi boş dövrsüz.** Godot 4.7-nin thread-siz veb build-ində `Engine.max_fps`
  kadrlar arasını `usleep` ilə doldurur, emscripten-də isə əsas axında `usleep` BOŞ
  DÖVRDÜR. Ölçülüb: kadrın işi 4.4 ms, requestAnimationFrame çağırışı isə 32.8 ms —
  bir nüvə oyun boyu 100% fırlanırdı (istilik, batareya, brauzerin GPU prosesinə
  qalmayan vaxt). İndi brauzerdə `Engine.max_fps = 0`, hədd isə `web/shell.html`-də
  kadr buraxmaqla tətbiq olunur ([`Settings._apply_frame_cap`](game/scripts/shared/settings.gd),
  `germSetFrameCap`). Kadr çağırışı 32.8 → **4.0 ms**, renderer prosesinin CPU-su kadr
  başına 33.8 → **7.5 ms**. Kadr büdcəsini hesablayan kod indi `Settings.frame_cap()`-i oxuyur.
- **Dairələr bir çağırışda** ([`BatchDraw`](game/scripts/client/batch_draw.gd)).
  `draw_circle` və `draw_arc` hər biri ayrıca poliqondur — öz GPU buferi, öz çəkiliş
  çağırışı; yenidən çəkiləndə bufer silinib təzədən yaradılır (antialias-lı qövs üç
  poliqondur). Bir sessiyada qatları növbə ilə gizlədib ölçüləndə kadrın ~150
  çağırışından ~61-i HUD idi, onun da çoxu minimap: 26 maneənin hər biri ayrı
  `draw_circle`. İndi dairə mipmap-lı ağ disk teksturasıdır, nazik halqa isə xətt
  seqmentləri — ikisi də ardıcıl gələndə bir çağırışa yığılır. HUD 61 → ~10 çağırış,
  kadr 146 → 87, kadrda yaradılan poliqon 41 → 17. Mikrobun topları, nüvəsi, ayaq
  ucları, partlayış damcıları və nişan nöqtələri də belədir. Görüntü eynidir, kiçik
  nöqtələrin kənarı hətta hamarlaşıb (əvvəl 3 piksellik dairə kvadrat çıxırdı).
- **"Oyun hazırlanır…"** Yükləmə bitəndən menyunun ilk kadrına qədər (A04s-də 20+ s)
  ekranda dolu tərəqqi zolağı donub qalırdı. İndi yazı və üç nöqtə görünür; nöqtələr
  yalnız `transform`/`opacity` ilə oynayır, yəni əsas axın məşğul olanda da hərəkət
  edir (13× yavaş CPU-da pəncərə şəkilləri ilə yoxlanıb). Örtük oyunun ilk ekranı
  çəkiləndə götürülür ([`Settings.web_page_ready`](game/scripts/shared/settings.gd)),
  oyun xəbər verməsə 60 s sonra özü.

APK-da çəkiliş dəyişikliyinin təsiri kiçikdir (masaüstü native: kadr 3.24 → 3.21 ms) —
orada GL çağırışı onsuz da ucuzdur. Növbəti addımlar ölçüyə görə: açılışın böyük
hissəsi mühərrikin özüdür (wasm, 3D shader-lər) — 3D-siz xüsusi veb şablonu onu
qısaldardı (Emscripten ilə build tələb edir); A04s-də brauzerin kadrını isə əsasən
Godot-un kanvas render-i (hər batch ~25 WebGL əmri) və GDScript məntiqi təyin edir.

### Telefon uyğunluğu — ölçülmüş vəziyyət

| Yoxlanan | Nəticə |
|---|---|
| Nisbətlər 16:9 … 21:9 və 4:3 | HUD bütöv, kəsilmə yoxdur |
| Görüş sahəsi ekranın küncünə çatır | bəli, ehtiyat **18%** (ən dar hal 21:9) |
| Ekran forması üstünlük verirmi | **yox** — görünən sahə hər ekranda eynidir |
| Qrafika səviyyəsi | YÜKSƏK / AŞAĞI / MİNİMUM. Telefonda ilkin dəyər AŞAĞI, zəif telefonda MİNİMUM, telefonun brauzerində də (`web_android`, `web_ios`). Kadrlar yavaşdırsa səviyyə oyunun içində özü enir, brauzerdə MİNİMUM-da isə kətanın sıxlığı da (1.25 → 0.75, bax 7-ci bənd) |
| Çox toxunuş (hərəkət + atəş + super) | hər idarə öz `_touch_index`-ini izləyir |
| Safe area (çıxıntı/notch) | `DisplayServer.get_display_safe_area()` tətbiq olunur |
| Portret pəncərə | yatay kadra letterbox olunur (bax [boot.gd](game/scripts/boot.gd)) |
| Renderer | `gl_compatibility`, arm64 + x86_64, ETC2/ASTC |
| Yaddaş | 42–54 MB |
| Çəkiliş çağırışı | yekun çalışmada 196 / 202; müşahidə edilən pik 263; sərt hədd 350 |

### Ekran forması üstünlük VERMİR

Kameranın miqyası qısa kənardan yox, **SAHƏDƏN** çıxır: oyunçunun gördüyü
dünya sahəsi bütün ekranlarda eynidir (`620 × 620 × 16/9`). Geniş ekran daha
enli, amma daha alçaq görür.

Əvvəl miqyas qısa kənardan çıxırdı və ekranın forması oyun üstünlüyü verirdi:

| Nisbət | Əvvəl | İndi |
|---|---|---|
| 4:3 | 513k sahə (−25%) | 683k |
| 16:9 | 683k (etalon) | 683k |
| 20:9 | 854k (+25%) | 683k |
| 21:9 | 897k (**+31%**) | 683k |

Yəni ən yaxşı və ən pis telefon arasında **56 faiz** fərq vardı. Mobil rəqabət
oyunları (Brawl Stars və bənzərləri) məhz bunu bağlayır. Bonus olaraq görüş
sahəsinin ehtiyatı da 6%-dən **18%**-ə qalxdı: sahə sabit olanda kadrın küncü
sonsuz uzaqlaşmır. `_test_aoi_covers_screen` altı real telefon nisbətini yoxlayır.

### Qrafika səviyyəsi

Dişli → AYARLAR → QRAFİKA → **Keyfiyyət: YÜKSƏK / AŞAĞI / MİNİMUM**. Telefonda
ilkin dəyər AŞAĞI-dır, zəif telefonda MİNİMUM (bax [Brauzerdə donma, 4-cü bənd](#brauzerdə-android-donma-və-kəsilmə)).
Brauzerdə MİNİMUM-un altında daha bir pillə var — kətanın sıxlığı kadr vaxtına
görə özü enib-qalxır (bax [Brauzerdə donma, 7-ci bənd](#brauzerdə-android-donma-və-kəsilmə)).
Seçim MATÇIN ORTASINDA da işləyir (bax [`Arena._apply_quality`](game/scripts/client/arena.gd)):
mühit həmişə qurulur, glow isə yandırılıb-söndürülür — əvvəl `WorldEnvironment`
AŞAĞI-da ümumiyyətlə yaradılmırdı və oyunçu ayarı dəyişəndə növbəti matça qədər
heç nə dəyişmirdi.

AŞAĞI-da glow və `hdr_2d` sönür; əsas su zərrəcikləri `80+30`-dan `34+14`-ə
enir; cərəyan axını və quru sərhəd buxarı tam sönür. Yeni döyüş zərrəcikləri
yarıya enir (lülə ləçəyi `3→1`, sıçrantı `8→4`, udulma izi `4→2`, qabıq
qırıntısı `6/12→3/6`, aura şüası `12→6`), halqa seqmentləri də `40→20` olur.
Glow tam ekranı bir neçə dəfə bulandıran keçiddir və HDR ilə birlikdə kadr
buferini RGBA16F-ə qaldırır — mobil GPU-da hər kadr iki dəfə çox yaddaş zolağı.

> Bu fərq masaüstündə **ölçülə bilmir**: eyni konfiqurasiyanın iki çalışması
> arasındakı səpələnmə (2.0 ms və 3.3 ms) konfiqurasiyalar arasındakı fərqdən
> böyükdür. Ona görə seçim oyunçuya verilib — telefonda ölçmək lazımdır.

MİNİMUM AŞAĞI-nın üstünə mikrobun özünü sadələşdirir və daha az pikseldə
çəkir: brauzerdə kətanın sıxlığı DPR 2-dən 1.25-ə enir, telefon tətbiqində
səhnə 1280×720-də çəkilib böyüdülür. Bu fərq ölçülüb: 6.5× yavaş CPU-da kadrın
işi 37 ms-dən 30 ms-ə, piksel doldurmaya həssas GPU-da (SwiftShader) isə
32–33 ms-dən 6.3–6.6 ms-ə düşür (bax [Brauzerdə donma, 4–6-cı bəndlər](#brauzerdə-android-donma-və-kəsilmə)).

Səviyyə YALNIZ görüntüyə təsir edir: qaydalar, görüş sahəsi və şəbəkə eynidir,
yəni aşağı keyfiyyət nə üstünlük verir, nə də məhrum edir.

### Ekran görüntüsü almaq
```bash
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --shot C:/yol/kadr.png --shot-delay 500
```

Ani hadisələr (super, partlayış, doğuş) tək kadra düşmür — ardıcıllıq çək.
`--charge` superi dolu başladır, `--idle` avtomatik oyunçunu söndürür (HAZIR
vəziyyətin şəkli üçün):
```bash
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --species 0 --charge --shot C:/yol/s.png \
         --shot-delay 4 --shot-count 12 --shot-every 4      # s_00.png … s_11.png
```

### Oyunu agentlə oynamaq (vizual QA)

[`PlayAgent`](game/scripts/tools/play_agent.gd) oyunu menyudan başlayıb **real
girişlə** oynayır: düymələrə basır, ünvan sahəsinə yazır, joysticki barmaqla
sürüşdürür, atəş və super düymələrinə toxunur. `--practice --shot`-dakı
avtomatik oyunçu isə girişi tamamilə keçir — joystik, düymələr, menyu və
ölümdən sonra menyuya qayıdış onunla heç vaxt sınanmır.

```bash
GODOT --path game --resolution 1280x720 --max-fps 60 -- --agent \
      --agent-out C:/yol/qovluq --agent-species 1 --agent-mode 2 --agent-time 90
```

| Bayraq | Mənası |
|---|---|
| `--agent-species`, `--agent-mode`, `--agent-quality` | menyunun öz düymələri ilə seçilir |
| `--agent-server ws://127.0.0.1:27015` | ünvan AYARLAR ekranına yazılır, OYNA ilə onlayn |
| `--agent-dead-server` | OYNA-nı yatmış serverlə sına: düymə ilişməməli, səbəb yazılmalıdır |
| `--agent-rounds N` | ölüm → nəticə → menyu → yenidən oyun dövrü; ölməsə **MATÇI TƏRK ET** ilə çıxır |
| `--agent-noshots` | kadr çəkmə — yalnız ölçü (PNG yazmaq 50–150 ms sıçrayış verir) |
| `--agent-no-keys`, `--agent-limit S` | klaviatura sınağını keç; sərt vaxt həddi |

Qovluğa `NNN_ad.png` (dövri və hadisə anında), `log.jsonl`, `issues.txt` və
`summary.json` yazılır; çıxış kodu 3 = problem tapılıb. Avtomatik yoxlamalar:
joystik/atəş/super cavabı, kamera, kadr sıçrayışı, node sızması, ekrandan
çıxan və üst-üstə düşən düymələr, menyu axını, AYARLAR ekranı (menyuda və
matçın içində — açılır, bağlananda matç davam edir), mühərrik xətaları.

> Oyunçunun `settings.cfg`-si agentin menyu seçimləri ilə dəyişir — agent onu
> başlanğıcda saxlayıb sonda geri yazır. Xarici `timeout` agenti öldürsə, bu
> addım icra olunmur, ona görə `--agent-limit` həmişə `timeout`-dan qısa olmalıdır.
> Pəncərəni kiçiltmə: Godot kiçildilmiş pəncərəni çəkmir və kadr çəkilmir.

### Superi düymə ilə yoxlamaq

[`super_probe.gd`](game/scripts/tools/super_probe.gd) super düyməsinə həqiqi
toxunuşla basır və zəncirin hər halqasını ayrıca yazır: düymə yandımı, server
superi işə saldımı, "super işləyir" biti, proqnozun sayğacı və mikrobun öz
görüntüsü nə qədər qaldı, görüntü yanıb-söndümü, açılış effekti çıxdımı.
Çıxış kodu 3 = ən azı bir cəhd alınmadı.

```bash
# Məşq: doluluğu yerli dünyada özü doldurur, hər növü təkrarlana bilən şəkildə sınayır
GODOT --path game --resolution 1280x720 --max-fps 60 \
      -- --practice --species 1 --super-probe 5 [--super-probe-shots C:/yol/qovluq]

# Onlayn: avtomatik oyunçu oynayır, superi isə YALNIZ probe düymə ilə basır
GODOT --headless --max-fps 60 --path game -- --autoclient \
      --host ws://127.0.0.1:27015 --species 1 --super-probe 6 --quit-after 170
```

Onlayn rejimdə cavab serverin snapshot-undan ölçülür, proqnozdan yox — proqnoz
superi həmişə "işlədir". Lokal server gecikməsizdir və bəzi xətaları göstərmir:
telefon bağlantısını yoxlamaq üçün client-i gecikmə əlavə edən TCP proksidən
keçir (hər istiqamətdə 70±30 ms bəs edir; proksi baytların SIRASINI
saxlamalıdır, yoxsa WebSocket axını pozulur).

Probe məhz belə bir xəta tapdı — aşağıdakı tələyə bax ([«Yenidən oynatma
sayğacı ikinci dəfə azaldır»](#tələlər--səssiz-uğursuzluqlar)). 70±30 ms
gecikmə ilə, öz ekranında:

| Növ | Server | Əvvəl | İndi |
|---|---|---|---|
| Kirpikli (ani) | işləyir | işləyir | işləyir |
| Ayaqlı — tor | 4.0 s | 0.95 s | 4.2 s |
| Amöb — kist | 2.5 s | 0.65–1.13 s, yanıb-sönür | 2.65 s |

Məşqdə hər şey düzgün görünürdü: orada gözləyən giriş yoxdur.

Probe ikinci xətanı da tapdı: öz superinin açılış effekti (`fx_t`) serverin
hadisəsini interpolyasiya anında gözləyirdi. Kirpiklinin superinin yeganə
görüntüsü trixosist partlayışıdır — o, məşqdə 130 ms, onlayn bir gediş-gəliş
üstəgəl bufer qədər gec çıxırdı, mikrob isə proqnozda dərhal geri sıçrayırdı və
partlayış onun arxasında, köhnə yerdə yanırdı. İndi öz superin effekti atəş
kimi proqnozdan, basılan tick-də oynanır ([`Arena._play_super`](game/scripts/client/arena.gd));
serverin hadisəsi onu yalnız təsdiqləyir və ikinci dəfə oynatmır
([`Arena._take_own_super`](game/scripts/client/arena.gd)), proqnoz görməyəndə
isə gecikmədən oynadır. Probe effektin sayını da yoxlayır (`fx_n` = 1):
70±30 ms gecikmə ilə üç növdə `fx_t` 33 ms-dir — bir tick.

Amöbün superində probe atəş düyməsinə də basır və topları iki yerdə sayır:
ekranda uçan (proqnoz) və serverin həqiqətən atdığı. Köhnə kodda super
toxunulmaz qabıq (kist) idi və atəş qadağan idi, amma kist öz ekranında ~0.7
s-də "bitirdi" və proqnoz atəşə icazə verirdi — bir superdə 6–7 top ekranda
uçurdu, serverdə isə SIFIR idi (oyunçu "vuruşlar rəqibə dəymir" görürdü).
Oyunçu məhz bu hissi superin özü kimi istədi: indi amöbün superi MİNİQANDIR —
qalxan yoxdur, amöb yerində donur, düymə basılı qaldıqca 0.25 s-də bir PULSUZ
top atır (bax [`Sim._step_germs`](game/scripts/shared/sim.gd)). Probe superdə
topların atıldığını və ekrandakı hər topun serverdə də olduğunu yoxlayır.

### Xəritənin bir yerini gözlə yoxlamaq

Doğuş yeri təsadüfidir, kol və cərəyan deşiyi isə dünyanın müəyyən
yerlərindədir — ona görə "kolun içi necə görünür" sualına ekran görüntüsü ilə
cavab vermək təsadüfə qalırdı. `--at` mikrobu istənilən nöqtədə doğurur:

```bash
GODOT --path game --resolution 1280x720 --fixed-fps 60 \
      -- --practice --at "-190,610" --shot C:/yol/kadr.png --shot-delay 26
```

Düzümdəki koordinatlar [`DishMap`](game/scripts/shared/dish_map.gd)-dədir.
Kadr nömrəsi vacibdir: `--shot` mikrobu hərəkətə salır, ona görə uzun
gecikmədə o, artıq yoxlamaq istədiyin yerdən çıxmış olur.

### Növün görüntüsü üzərində işləmək
```bash
GODOT --path game --resolution 900x900 --fixed-fps 60 \
      -- --preview --preview-species 2 --preview-balls 6 \
         --shot C:/yol/kadr.png --shot-delay 100
```
Oyunun içində mikrob 30 piksel radiusundadır — telefonda kifayətdir, forma
üzərində işləyəndə isə heç nə seçilmir. Stend eyni [`GermVisual`]-i böyüdüb
çəkir və mikrobu **həqiqi sürətlə** hərəkət etdirir: sürünmə, addım və kirpik
dövrü sürətdən çıxdığı üçün dayanan mikroba baxmaq mənasızdır.

`--fixed-fps` kadrı deterministik edir, yəni eyni `--shot-delay` həmişə eyni
kadrı verir — dəyişikliyi əvvəl/sonra müqayisə etmək mümkün olur.

---

## Android

### Test APK (debug imza, arm64 + x86_64)
```bash
GODOT --headless --path game --export-debug "Android" build/GermArena.apk
adb install -r build/GermArena.apk
```

### Release APK (Play Store, arm64)
```bash
bash tools/build_release_apk.sh
```

**Release imzası.** İmza açarı qəsdən repodan kənardadır. Skript onu
`C:\Users\User\.keystores\germ_arena_release.env` faylından oxuyur:

```bash
# germ_arena_release.env
GERM_ARENA_KEYSTORE=C:/Users/User/.keystores/germ_arena_release.keystore
GERM_ARENA_KEYSTORE_USER=germarena
GERM_ARENA_KEYSTORE_PASSWORD=...
```

Açar yaratmaq:
```bash
keytool -genkeypair -v -keystore germ_arena_release.keystore -alias germarena \
        -keyalg RSA -keysize 2048 -validity 10000
```

> ⚠️ **Keystore faylını və parolu mütləq ehtiyat nüsxələyin.** Play Store-a
> yüklənən tətbiq həmişə eyni açarla imzalanmalıdır. Açar itsə, tətbiqi bir daha
> yeniləmək mümkün olmur — yalnız yeni paket adı ilə sıfırdan yayımlamaq qalır.
>
> **iOS:** Windows-da mümkün deyil, Mac tələb olunur.

---

## Şəbəkə modeli

```
Client (60 FPS)                          Server (30 Hz, headless)
  giriş oxu ──────────────────────────>   giriş buferi
  öz hərəkətini dərhal oynat (predict)     Sim.step() — yeganə həqiqət
  snapshot gələndə düzəlt (reconcile) <──  30 Hz snapshot yayımı
  rəqibləri 100 ms geridə göstər
```

Üç prinsip:

1. **Client heç nə qərar vermir.** Yalnız giriş göndərir; dəymə, udma, partlama serverdədir.
2. **Simulyasiya bir dəfə yazılıb.** `sim.gd` həm serverdə, həm client proqnozunda işləyir.
3. **Godot fizikası istifadə olunmur.** Prediction üçün simulyasiyanı geri sarıb yenidən
   oynatmaq lazımdır; fizika mühərriki bunu deterministik etmir.

> **Öz topun gecikməli xəttdə çəkilmir.** Rəqiblər 100 ms geridə göstərilir, öz
> mikrobun isə proqnozdan — yəni indi. Top da gecikməli xəttə salınsaydı (və
> salınırdı), öz atdığın top mikrobunun 100 ms əvvəlki yerində doğulardı: top
> 420 px/s getdiyinə görə bu, 42 piksel, mikrobun radiusundan (28 px) çox.
> Ekranda görünən budur ki, top mikrobun **arxasında** peyda olur, gövdənin
> içindən keçir və qabaqdan çıxır — sanki kənardan atılıb. Ona görə öz topun
> serverin topu ilə yox, öz proqnozu ilə çəkilir ([`ShotPrediction`](game/scripts/client/shot_prediction.gd)):
> atəş anında mərkəzdən çıxır, divardan özü sıçrayır və rəqibə dəyməni də özü
> göstərir. Server isə eyni dəyməni geri sararaq yoxlayır — bax
> [«Onlayn vuruş»](#onlayn-vuruş--gecikməsiz-zərbə).

### Görüş sahəsi (area of interest)

Dünya ekrandan ~4 dəfə böyükdür (2400 px enində), ona görə hər oyunçuya **yalnız
öz ətrafı** göndərilir. Bu iki problemi birdən həll edir:

- **Trafik** — io oyunlarının ən böyük problemi. 110 qida topunun hamısını
  saniyədə 30 dəfə göndərmək mobil şəbəkəni doldurar.
- **Cheat** — uzaqdakı rəqiblərin yeri client-ə ümumiyyətlə çatmır, ona görə
  "divar arxasını görmək" mümkün deyil. Mini xəritə də yalnız gördüklərini göstərir.

Sahənin radiusu tutumla böyüyür: böyük mikrob kamerada daha geniş görür, ona görə
daha çox məlumat alır. İki rəqəm eyni funksiyadan gəlir
([`Const.view_width` / `Const.aoi_radius`](game/scripts/shared/constants.gd)) —
əks halda ekranın kənarında obyektlər kəsilərdi.

Qida snapshot-un ən ağır hissəsidir, ona görə massiv-içində-massiv yox,
düz `PackedFloat32Array` göndərilir: ədəd başına 9 bayt əvəzinə 4.

### İki nəqliyyat

| Nəqliyyat | Nə vaxt | Qeyd |
|---|---|---|
| **ENet (UDP)** | Öz VPS-ində | Ən aşağı gecikmə — oyun üçün ideal |
| **WebSocket (TCP)** | Railway və bənzər PaaS | Bir az yavaş, amma hər yerdən keçir |

Seçim avtomatikdir: **ünvan `wss://` və ya `ws://` ilə başlayırsa WebSocket**, əks halda ENet.
Serverdə `PORT` mühit dəyişəni varsa (Railway onu verir) WebSocket-ə keçilir.

### Bağlantı kəsiləndə

Mobil şəbəkədə düşmək adi haldır, ona görə mikrob dərhal itmir:

1. Server mikrobu **20 saniyə** dünyada saxlayır. Mikrob hərəkət etmir, amma
   **vurula bilir** və metabolizmi işləyir (bağlantını kəsmək qorunma üsulu olmamalıdır).
2. Client 3 saniyə aralıqla 5 dəfə qayıtmağa çalışır.
3. Qayıdanda dünyaya girəndə verilmiş **sessiya nişanı** ilə tanınır — yeni peer id
   alır, amma köhnə mikrobuna (mövqe, toplar, tutum, hesab) qayıdır.
4. 20 saniyə keçsə və ya mikrob bu müddətdə partlasa, nişan etibarsız olur.

**CÜT-də dirilməni gözləyən oyunçu da qayıda bilir.** Onun mikrobu ölüdür
(`sim.germs`-də yoxdur), amma matçda yeri var — [`World.holds`](game/scripts/server/world.gd)
məhz bunu soruşur. Əvvəl üç yer yalnız `sim.germs`-ə baxırdı və üçü də səhv
edirdi: qopan belə oyunçu "dayandırılmış" sayılmırdı (server 20 s boyu ona
30 Hz-lə snapshot göndərməyə çalışırdı — "unknown peer ID" xətası), qayıdanda
"gözləmədə partladı" deyilirdi, matçı tərk edəndə isə dirilmə növbəsi qalırdı
və 15 s sonra dünyada sahibsiz mikrob dirilirdi. İndi növbə yeni peer id-yə
köçür, qayıdana öz rəngi/növü/adı gedir, tərk edənin növbəsi silinir.
Yoldaşı da ölüb dirilməsi ləğv olunan oyunçu isə nəticə ekranını alır — əvvəl
matç bitənə qədər nəticəsiz izləyici qalırdı.

### Donma və dəstə — server, yoxsa Wi-Fi?

Şikayət (2026-10-03): üç nəfər qoşulanda oyun tez-tez donurdu və kəsilirdi.

**Diaqnoz — server deyil, ortaq Wi-Fi.** Render logu (11:19–11:29 UTC):

| Nə görüldü | Nə deyir |
|---|---|
| Üç cihaz (1 iPhone, 2 Android) və bu kompüter EYNİ ictimai IP-dən — bir Wi-Fi | ortaq yol |
| Status sətri hər 5.03 s, tick orta 1.4–1.75 ms (büdcə 33 ms), **atılan tick 0** | server prosesi heç vaxt ilişməyib |
| 11:25:17–22-də cəmi **74** giriş (normal ~300), növbəti 5 s-də **715** (gözlənilən 453) | girişlər itməyib — ~4 s **gecikib** və bir anda gəlib (TCP Wi-Fi kəsilməsindən sonra belə edir) |
| 74 bir sağlam oyunçunun girişindən (151) də azdır | iki cihaz (iPhone və Android) EYNİ ANDA ilişib — fərqli əməliyyat sistemləri, ortaq şəbəkə |

Canlı yoxlama: bu kompüterdən (eyni IP, 2.4 GHz Wi-Fi, kanal 11) canlı serverə
3 test client-i + neytral ünvanlar (1.1.1.1, 8.8.8.8, Render `/healthz`) eyni
anda ölçüldü. Yeganə uzun dayanma (~0.6 s) **hamısında birdən** göründü — oyunda
da, Cloudflare/Google-a gedən yolda da. Render-in 0.1 CPU-su yalnız kiçik ilişmə
verir: tick bəzən 13–39 ms-ə uzanır, saniyələrlə yox. Qrup oyunu üçün bir
routerdə 5 GHz və ya mobil internet daha yaxşıdır.

**Amma oyun hər dayanmanı böyüdürdü** (lokal ölçü, şəbəkə simulyatoru ilə
1.5 s və 4 s dayanma — real hadisə kimi: TCP baytları saxlayır, sonra bir anda buraxır):

| Problem | Ölçü (köhnə kod) | Düzəliş | Kod |
|---|---|---|---|
| Dayanmadan sonra 45–120 snapshot BİR kadrda tam emal olunurdu (barışıq, kölgələr, liderlər cədvəli hər biri üçün) | masaüstündə 124–290 ms-lik kadr — donmanın üstünə ikinci donma | Snapshot-lar növbəyə yığılır, kadrın əvvəlində birlikdə emal olunur; bahalı hissə yalnız ən təzəsi ilə bir dəfə | `Arena._drain_inbox`, `_ingest` |
| Tick saatının ortası (0.7 s, 0.25 s-də köçmə) dəstədə dişli mişar kimi köçürdü | rəqiblər 16–22 tick (0.5–0.7 s) **geriyə** atılırdı | Baza gəlişlərin ORTASI yox, ƏN TEZİDİR — gec paket onu tərpətmir | `Arena._tick_time_of`, `_tt` |
| Bufer quruyanda rəqiblər, toplar, qida birdən DONURDU, sonra sıçrayırdı | 1.5 s-də ön sıçrayış 45 tick bir kadrda | Göstərilən an (`Arena._rtick`) geri getmir; bufer quruyanda 200 ms son sürətlə irəli, sonra dayanır; sonra 3×-ə qədər sürətlənib yetişir (sıçramır) | `_advance_render`, `EXTRAP_MAX`, `CATCHUP_*` |
| Jitter-ə görə bufer sabit 100 ms idi | Wi-Fi sıçrayışlarında boş bufer | Gecikmə son 3 s-in p95-i + tick + ehtiyat, 100–200 ms, yavaş dəyişir; serverə gedən görünən tick də elə odur | `_update_delay_target` |
| Server dəstədə yalnız SON girişi saxlayırdı, donma boyu isə sonuncunu təkrarlayırdı | öz mikrobun 140–510 px **geri** dartılırdı | Server təxmin etdiyi tick-ləri gec gələn girişlərlə yenidən hesablayır (ən çox 4 s; mikroba kənardan bir şey toxunubsa — yox); client ankordan oynadır. Girişlər bağlı olanda (geri sayım, matçın sonu) heç nə təxmin sayılmır; ÜÇLÜK-də raund sıfırlananda hamısı unudulur | `World._replay_late`, `_self_row`, `Arena._reconcile` |
| Client tick-ləri həmişəlik itirəndə (vərəq arxa planda, 0.5 s-dən uzun kadr) o slot-ların girişi heç gəlmir | ilk variantda bu "borc" adi jitter-də heç silinmirdi — yoldaşlar 155–1022 px sıçrayış görürdü (müstəqil yoxlamada tapılıb) | Borc girişlərin SAYI ilə yox, `seq` irəliləyişi ilə sayılır; girişlər 30 tick axırsa, pəncərənin ən kiçik qalığı daimidir və silinir | `World._settle_debt` |
| Davamlı sürüşmə (yol uzanıb, server tick atıb): baza saniyədə 5 ms qalxırdı | 0.3–0.5 s-lik sürüşmədən sonra rəqiblər 30–65 s ekstrapolyasiya olunurdu | Son 1.5 s-in ən az gecikməsi də 60 ms-dən böyükdürsə, baza dərhal qalxır (donma dəstəsi bunu işə salmır) | `Arena._rebase` |
| Barışıq düzəlişi birdən görünürdü | normal oyunda da 6–26 px titrəmə | Düzəliş 0.1 s-də sönən görüntü sürüşməsidir; simulyasiya dərhal serverin sözünə keçir. Doğuş, yenidən qoşulma, CÜT-də dirilmə və yeni raund TELEPORTDUR — onlar sürüşmür, dərhal yerinə qoyulur; "sənə dəydi" proqnozu da sürüşmənin yox, proqnozun yerinə baxır | `_smooth_correction`, `CORR_TAU`, `_snap_next`, `_pred_pos` |
| Brauzerdə WebSocket giriş buferi 64 KiB idi | dəstə onu doldururdu, mühərrik mesajları ATIRDI — etibarlı RPC-lər də | 512 KiB (~20 s axın) | `Net.INBOUND_BUFFER` |
| Godot uzun kadrda `delta`-nı 133 ms-də kəsir, client 5 tick-dən çoxunu atırdı | telefonun hər ilişməsində saat geri qalırdı | Hədd 0.5 s, kadrda 15 tick-ə qədər | `LONG_FRAME`, `TICKS_PER_FRAME` |
| Donma "oyun ilişdi" kimi görünürdü | — | **ZƏİF BAĞLANTI** nişanı: 0.4 s snapshot gəlmirsə və ya giriş təsdiqlənmirsə | `Arena._watch_net`, `Hud.set_weak_net` |
| Gözləyən dəymələr donma boyu "köhnəlirdi" | təsdiq gələndə ikinci, ayrı zərbə | Donma boyu gözləmə saatı dayanır | `_hold_claims` |

`INPUT_BUFFER_MAX` 64-dən (2.1 s) 160-a (5.3 s) qalxdı — 4 s-lik donmada da
barışıq tam olur. Köhnə client yeni serverdə işləyir (SELF sətrinin yalnız ilk iki
sahəsini oxuyur), RPC-lər dəyişməyib.

**Nəticə** — eyni şəbəkə simulyatoru, 2–3 client × 120 s hər ssenaridə, "köhnə" bu
işdən əvvəlki koddur. Rəqəmlər dayanma pəncərələrinin medianıdır (mötərizədə ən pisi):

| Ssenari (şəbəkə simulyatoru) | Göstərici | Köhnə kod | **İndi** |
|---|---|---:|---:|
| 0.4 s dayanma, hər iki istiqamət | öz mikrobunun sıçrayışı | 51 px (ən pisi 84) | **0** (0) |
| | rəqiblərin bir kadrda irəli sıçrayışı | 9 tick | **0.8 tick** |
| 1.5 s dayanma | öz mikrobunun sıçrayışı | 218 px (329) | **0** (0) |
| | rəqiblərin GERİYƏ atılması | 16.5 tick | **0** |
| | rəqiblərin bir kadrda irəli sıçrayışı | 45 tick | **1.5 tick** (sürətlənib yetişir) |
| 1.5 s dayanma, oyunçu bu arada istiqaməti dəyişir | öz mikrobunun sıçrayışı | 201 px (328) | **0** (0) |
| 1.5 s, yalnız yuxarı istiqamət (girişlər ilişir) | öz mikrobunun sıçrayışı | 139 px (218) | **0** (60; bir ölçüdə 939*) |
| 4 s dayanma (real hadisə kimi) | öz mikrobunun sıçrayışı | 331 px (514) | **0** (52) |
| | rəqiblərin GERİYƏ atılması | 22 tick | **0** |
| | dəstənin emalı bir kadrda | 122 ms | **3 ms** |
| Wi-Fi jitter-i (5–25 ms + 60–250 ms sıçrayışlar), dayanmasız | öz mikrobunun titrəməsi (>5 px) | 3–7 dəfə/dəq, ən çox 20–30 px | **0** |

\* Server yenidən oynatmanı yalnız TƏMİZ yolda edir. Donma boyu mikroba kənardan nə isə
toxunubsa (rəqiblə toqquşma, trixosist, tor, zərbənin təpməsi), o təsiri silmək olmaz —
yoxsa bağlantını qəsdən ilişdirib zərbədən qaçmaq olardı. O halda köhnə qayda qalır və
mikrob serverin təxmininə dartılır; sıx döyüşdə 3 client + botla bir ölçüdə bu, 939 px oldu.

Dayanmanın ÖZÜ yox olmur — 4 s şəbəkə gəlmirsə, rəqiblər 4 s yenilənmir (indi
200 ms irəli gedib dayanır və **ZƏİF BAĞLANTI** yazılır). Yox olan budur ki,
donmadan sonra öz mikrobun geri dartılmır, rəqiblər geriyə atılmır, ekran ikinci
dəfə ilişmir.

Topların keçidi də ölçüldü (HitProbe, eyni ssenarilər). Öz topunun rəqibdən
zərbəsiz keçməsi dayanmalarda belə 0–1-dir. Rəqibin topu ilə üçüncü mikrob
arasındakı qalıq keçid isə dəyişməyib — Wi-Fi ssenarisində köhnə kodda 14 / 262
(5.3%), indi 12 / 265 (4.5%). Bu, əvvəldən qalan səviyyədir (bax «Öz topunun
təsdiqlənməyən dəymələri»). Topların və effektlərin vaxtı da artıq tick-ə
bağlanıb, mütləq ana yox: baza erkən paketdə enəndə mikroblar dərhal sürüşür,
toplar və zərbə parıltısı isə əvvəl növbəti snapshot-a qədər köhnə bazada qalırdı
(8–25 px aralı).

**Server diaqnostikası.** `--verbose` serverdə iki sətir əlavə olundu:

```
[lobby] 1 dünya · ... · atılan tick 0 · CPU 61 ms/s · kvotada saxlanma 3/50 dövr, 12 ms
[net] Ana: girişlər 3810 ms gəlmədi, sonra 114-ü bir kadrda
```

Birincisi Render konteynerinin cgroup kvotasıdır (`/sys/fs/cgroup/cpu.stat`):
"saxlanma" artırsa, server CPU-ya dirənir. İkincisi kimin, nə vaxt, nə qədər
ilişdiyini deyir — bir neçə oyunçuda eyni anda görünürsə, səbəb onların ortaq şəbəkəsidir.

### Botlar

io oyununun ölüm səbəbi boş dünyadır: ilk oyunçu qoşulanda ortada tək qalsa,
dərhal çıxır. Ona görə **serverdə** bot mikroblar işləyir və əhalini 6-da saxlayır.

Bot heç bir imtiyaza malik deyil — insan oyunçu ilə eyni `Sim.PlayerInput`
strukturunu doldurur və eyni məhdudiyyətlərə tabedir. Davranışı doluluqdan asılıdır:
acdırsa qida axtarır, doludursa rəqibdən qaçır (bir dəymə onu partlada bilər),
ortadadırsa hücuma keçir.

İnsan oyunçu gələndə bot yerini ona verir — dünyada heç vaxt 10-dan çox mikrob olmur.

---

## Render-də saxlamaq

Hər şey TƏK servisdir (`germ-arena`, pulsuz plan, Frankfurt):

| Yol | Nə verir |
|---|---|
| `/` | Brauzer build-i — nginx, `.wasm`/`.pck`/`.js` əvvəlcədən gzip-lənib |
| `/ws` | Oyun serveri — nginx → `127.0.0.1:27015` (Godot headless, WebSocket) |
| `/healthz` | Render-in sağlamlıq yoxlaması (oyun serveri adi HTTP-yə cavab vermir) |

**Niyə bir servis:** pulsuz planda hər servis ayrıca yatır. İki servis olsaydı,
oyunçu əvvəl saytın, sonra serverin oyanmasını gözləyərdi. Domen eyni olduğuna
görə brauzer build-inə ünvan yazmaq da lazım deyil.

| Fayl | Nədir |
|---|---|
| [`render.yaml`](render.yaml) | Servisin tərifi (Blueprint) |
| [`deploy/render/Dockerfile`](deploy/render/Dockerfile) | Oyunu MƏNBƏDƏN qurur: Godot 4.7.2-ni yükləyir, Web və Linux Server presetlərini ixrac edir |
| [`deploy/render/fetch_templates.py`](deploy/render/fetch_templates.py) | 1.28 GB-lıq şablon arxivindən HTTP Range ilə yalnız 2 faylı (~84 MB) çəkir |
| [`deploy/render/start.sh`](deploy/render/start.sh) | Serveri və nginx-i qaldırır; biri düşsə konteyner də düşür və Render onu yenidən başladır |
| [`deploy/render/nginx.conf.template`](deploy/render/nginx.conf.template) | Statik fayllar, `/ws` proksisi, wasm MIME tipi |

Repoda hazır binar saxlanmır — build hər dəfə mənbədən gedir (~2 dəqiqə).

### Yenidən deploy

`main`-ə push kifayətdir: Render avtomatik build edir. Yalnız `game/`,
`deploy/render/` və `.dockerignore` dəyişəndə — README-yə görə build getmir.

```bash
render login                                        # brauzerdə təsdiq
render services                                     # servis id-si (srv-...)
render logs --resources <srv-id> --tail             # server hər 5 s status yazır
render deploys create <srv-id> --wait               # əl ilə yenidən deploy
```

### Lokal sınaq — Render şərtləri ilə
```bash
docker build -f deploy/render/Dockerfile -t germ-arena .
docker run --rm --cpus=0.1 --memory=512m -p 10000:10000 germ-arena
# brauzer: http://127.0.0.1:10000 · server: ws://127.0.0.1:10000/ws
```
`--cpus=0.1 --memory=512m` pulsuz planın limitləridir.

### Pulsuz planın CPU-su (0.1)

Server 30 Hz-də işləyir, yəni 0.1 CPU ilə bir tick-ə ~3.3 ms CPU düşür.
Status sətri bunu birbaşa göstərir:

```
[lobby] 1 dünya · son 5 s-də 302 giriş paketi · tick orta 0.83 ms, maks 1.50 ms · atılan tick 0
```

**`atılan tick` sıfırdan böyükdürsə**, server real vaxtdan geri qalır və oyun
yavaşıyır — o zaman Starter plan (0.5 CPU) lazımdır.

Ölçü (2026-09-25, konteyner `--cpus=0.1 --memory=512m`, 2 oyunçu + botlar):

| | Tick orta / maks | Atılan tick | CPU | RAM |
|---|---:|---:|---:|---:|
| Optimallaşdırmadan əvvəl | — | ölçülüb: oyun 18–24 Hz-ə düşürdü | — | — |
| 1 dünya (SONSUZ ARENA) | 0.8–1.0 / 1.9 ms | 0 | ~5% | 79 MB |
| 2 dünya (+ TƏK QALAN) | 1.5 / 2.8 ms | 0 | ~5.6% | 79 MB |
| **Render, canlı:** 1 dünya | 1.15–1.34 / 3.3 ms | 0 | — | — |
| **Render, canlı:** 2 dünya | 1.8–2.4 / 6.8 ms | 0 | — | — |

Render-in vCPU-su lokal konteynerdən ~1.5x yavaşdır. İki dünya 3.3 ms-lik
büdcənin ~70%-ini tutur, yəni pulsuz plan təxminən **iki eyni vaxtda açıq
dünyaya** çatır. Üçüncüsü açılanda `atılan tick` artmağa başlayacaq.

Tick-in ən bahalı yeri qida döngüsü idi (qida × mikrob, tick-in ~45%-i).
Mikrob siyahısı döngüdən əvvəl bir dəfə yığılır, ucuz məsafə yoxlaması
statik çağırışlardan əvvəl gedir; nəticə **bit-bit eynidir** (8 ssenarinin
hər tick-dəki SHA-256 izi əvvəl/sonra üst-üstə düşür). Tick ~2.3x ucuzlaşıb.

---

## Serveri Railway-də saxlamaq (alternativ, qurulmayıb)

> Əsas host Render-dir (yuxarıya bax). Bu bölmə iki servisli köhnə sxemi
> alternativ kimi saxlayır — kök `Dockerfile` və `web/` ona aiddir.

Railway **ictimai UDP-ni dəstəkləmir**, ona görə orada WebSocket işlədilir.
Portu Railway `PORT` dəyişəni ilə verir, server onu özü tutur.

### İlk qurulum
```bash
railway login
railway init                      # yeni layihə: germ-arena
railway service create germ-arena
bash tools/deploy_server.sh
railway domain                    # ünvanı götür və constants.gd-də yenilə
```

### Yenidən deploy
```bash
bash tools/deploy_server.sh       # binarı ixrac edir + Railway-ə göndərir
```

Layihədə İKİ servis nəzərdə tutulub və hər biri müstəqil deploy olunur:

| Servis | Nədir |
|---|---|
| `germ-arena` | Oyun serveri (Godot headless, WebSocket) |
| `germ-arena-web` | Brauzer build-ini verən nginx |

### Brauzer versiyası
```bash
RAILWAY_PROJECT_ID=<id> bash tools/deploy_web.sh
```

Skript `Web` presetini `web/public/` qovluğuna ixrac edir, sonra `web/` qovluğunu
`germ-arena-web` servisinə göndərir.

Üç detal brauzerdə vacibdir və `web/default.conf.template` faylında həll olunub:

1. **wasm MIME tipi.** `application/wasm` verilməsə brauzer streaming kompilyasiyadan imtina edir.
2. **gzip.** Sıxılmamış wasm 38 MB-dır; Dockerfile build zamanı `.gz` hazırlayır,
   nginx `gzip_static` ilə onu verir — şəbəkədən ~10 MB keçir.
3. **`Cache-Control: no-cache`.** Fayl adları dəyişmir (`index.wasm`), ona görə keş
   köhnə build-i ilişdirə bilər. `no-cache` = hər dəfə ETag ilə yoxla (dəyişməyibsə 304).

### Diaqnostika
```bash
railway logs --service germ-arena     # server hər 5 saniyədə dünyaların vəziyyətini yazır
bash tools/check_server.sh            # WebSocket əl sıxması ilə sağlamlıq yoxlaması
```

Server `--verbose` ilə işləyir: neçə dünya var, 5 saniyədə neçə giriş paketi gəlib,
hər dünyada kimin harada olduğu, top sayı və tutumu loglarda görünür.

### Öz VPS-ində (ENet, daha aşağı gecikmə)
```bash
./germ_arena_server.x86_64 --headless -- --server --port 27015
```
UDP 27015 portu açıq olmalıdır.

---

## Tələlər — səssiz uğursuzluqlar

> ⚠️ **`multiplayer.multiplayer_peer` heç vaxt `null` olmur — Godot ora
> `OfflineMultiplayerPeer` qoyur.**
>
> O peer heç bir şəbəkəyə toxunmur, amma özünü **QOŞULU** elan edir
> (`get_connection_status() == CONNECTION_CONNECTED`) və `get_unique_id()`
> kimi **1**, yəni "mən serverəm", qaytarır. Yalnız statusa baxan yoxlama
> buna görə oyun açılan kimi "onlayn" deyir:
>
> ```gdscript
> # SƏHV — qoşulmadan da true qaytarır
> return multiplayer.multiplayer_peer != null \
>     and multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED
> ```
>
> Nəticə tam səssizdir: menyu "artıq qoşuluyuq" deyib `request_join.rpc_id(1, …)`
> göndərir, Godot isə bunu ÖZÜMÜZƏ göndərilmiş sayır və
> `RPC 'request_join' on yourself is not allowed` yazıb çağırışı atır. Serverə
> heç nə getmir, heç bir siqnal gəlmir — **OYNA düyməsi sadəcə işləmir.**
>
> Etibarlı şərt əl sıxışmanın bitməsidir: [`Net.local_id`](game/scripts/shared/net.gd)
> yalnız `connected_to_server` gələndə doldurulur. `sim_test`-də bunun üçün
> ayrıca yoxlama var — qoşulmamış client özünü onlayn saymamalıdır.

> ⚠️ **"Dəyişibmi?" sualına SAYLA cavab vermək olmaz — kimlik dəyişir, say qalır.**
>
> Ad və rəng snapshot-dan çıxarılıb ayrıca reyestrə köçürüləndə köhnəlmə
> yoxlaması belə yazılmışdı:
>
> ```gdscript
> if sim.germs.size() != _roster_n:   # SƏHV
> ```
>
> Amma `Sim.rekey_germ` mikrobu silib yenidən əlavə edir — **id dəyişir, say
> dəyişmir**. Yenidən qoşulma məhz bunu edir. Nəticədə qayıdan oyunçunun
> mikrobu bütün DİGƏR ekranlarda adsız və 0 rəngli qalırdı. Eyni tələ: bir
> tick-də bot doğulub biri partlasa da say dəyişmir.
>
> Səhv oyunçunun ÖZÜNDƏN gizlidir — o, öz ekranında hər şeyi düzgün görür.
> Yalnız başqasının ekranında bilinir, yəni tək client ilə test edəndə heç vaxt
> tapılmır.
>
> Düzgün yol id-lərin ÖZÜNDƏN imza yığmaqdır (`key = key * 31 + gid`).
> `_test_roster_tracks_ids` bunu qoruyur.

> ⚠️ **Variant massivində hər ədəd ~9 bayt tutur — snapshot səssizcə MTU-nu aşırdı.**
>
> Godot bunu yalnız bir sətirlə deyir və o da server logunda itir:
>
> ```
> WARNING: Sending 1448 bytes unreliably which is above the MTU (1392)
> ```
>
> Aşan paket PARÇALANIR, snapshot isə `unreliable_ordered` gedir — yəni bir
> parçanın itməsi **bütün snapshot-u** itirir. Oyunçu üçün bu, təsadüfi
> "ilişmə" kimi görünür və səbəbi heç vaxt aydın olmur.
>
> Ölçüldükdə ən pis hal **2224 bayt** idi. Üç səbəb vardı və üçü də
> "məntiqli görünən" koddan gəlirdi:
>
> | Səbəb | Ölçü |
> |---|---|
> | Ad və rəng hər tick göndərilirdi — halbuki heç vaxt dəyişmir | reyestrə köçdü |
> | Rəqiblərin `ack` və `cooldown`-u da gedirdi — client onları oxumur | [enum SelfF]-ə köçdü |
> | Mikroblar Variant massivi idi (~9 bayt/ədəd) | `PackedFloat32Array` (4 bayt) |
>
> Nəticə: **2224 → 1116 bayt**. Şəbəkəyə sıx gedir, client-də isə
> [`Const.unpack_germs`](game/scripts/shared/constants.gd) köhnə sətir formasına
> açır — belə çəkiliş kodu formatdan xəbərsiz qalır.
>
> `sim_test`-dəki `_test_snapshot_fits_mtu` indi bunu qoruyur və uğursuzluqda
> hansı sahənin şişdiyini bayt-bayt çap edir. Snapshot-a yeni sahə əlavə
> edəndə **əvvəlcə o testi çalışdır**.

> ⚠️ **Bot maneəni ATƏŞ üçün görürdü, HƏRƏKƏT üçün yox — xəritə daralanda donurdu.**
>
> [`Bot.think`](game/scripts/shared/bot.gd) hədəf seçəndə
> `Sim.has_line_of_sight` çağırırdı, amma getdiyi istiqaməti heç yoxlamırdı.
> Açıq qabda bu bilinmirdi: yer çox idi, bot maneəyə sürtünüb yan keçirdi.
>
> TƏK QALAN qabı daraldanda isə hamı mərkəzə sıxıldı və botlar maneəyə
> dirənib **tamamilə donub qaldı**. Diaqnostika birbaşa göstərdi — matçın son
> 60 saniyəsində üç botun mərkəzdən uzaqlığı `177, 177, 154` dəyərlərində
> dəyişmirdi:
>
> ```
> t=176 r= 204 uzaq=181, 183, 184
> t=208 r= 147 uzaq=177, 177, 154   ← donub
> t=240 r=  90 uzaq=177, 177, 154   ← hələ də
> ```
>
> Səssiz uğursuzluq idi: heç bir xəta yox, bütün testlər keçir, sadəcə matç
> **beş dəfədən beşində** döyüşlə yox, 240 saniyəlik vaxt limiti ilə bitirdi.
> Bir neçə saat balans "düzəlişi" (qida sıxlığı, quruma sürəti, botun
> aqressivliyi) heç nəyi dəyişmədi, çünki səbəb balansda deyildi.
>
> Düzəlişdən sonra: **altı matçdan altısı** 2:34–3:34 arasında, tək qalibi ilə.
> Dərs: rejim balansını ölçməzdən əvvəl agentlərin ümumiyyətlə TƏRPƏNDİYİNİ
> yoxla. `sim_test`-dəki `_test_full_solo_match` indi məhz bunu qoruyur.

> ⚠️ **Bir HUD elementinin BİR sahibi olmalıdır — yoxsa sonuncu yazan udur.**
>
> `Hud`-un xəbərdarlıq sətri, mərkəzdəki iri yazı və alt sətri kadr ərzində
> bir neçə yerdən yazılır. Sıra `Arena._apply_local`-dadır və orada
> `set_match` `update_gauge`-dən ƏVVƏL çağırılır:
>
> ```gdscript
> # SƏHV — set_match mətni yazır, update_gauge dərhal üstündən silir
> func set_match(...) -> void:
>     if drying:
>         _warn_lbl.text = "QURUYUR — mərkəzə get"
>         _warn_lbl.visible = true      # növbəti sətirdə itir
> ```
>
> `update_gauge` sonra gəlib `_set_warning("")` çağırır və sətri gizlədir.
> Nəticə səssizdir: kod işləyir, test yoxdur, sadəcə TƏK QALAN rejiminin ən
> ölümcül xəbərdarlığı **heç vaxt ekrana çıxmır**. Eyni səbəbdən sayımın alt
> sətrində doğuş anındakı "GİZLƏNDİN" yazısı donub qalırdı.
>
> Qayda: mətni yazan **bir** funksiya olsun, qalanları yalnız bayraq qoysun
> (`_drying`), yazan funksiya isə prioriteti özü həll etsin. Sayım gedərkən
> mərkəzdəki hər iki sətrin sahibi [`Hud.set_match`](game/scripts/client/hud.gd)-dir.

> ⚠️ **Şrift seçəndə Azərbaycan hərflərini YOXLA — xüsusən `Ə` və `ə`.**
>
> Oyun şrifti kimi ilk ağla gələnlərin çoxunda şva **yoxdur**: Fredoka, Titan
> One, Lilita One, Archivo Black, Rubik, Sora, Gabarito, Russo One — hamısında
> `Ə`/`ə` çatışmır (bəzilərində `Ğ ğ İ Ş ş` də). Şrift qalan hər şeyi düzgün
> göstərir, ona görə səhv gec görünür: menyuda "MƏŞQ" **"M□ŞQ"**, HUD-da
> "SƏVİYYƏ" **"S□VİYY□"** çıxır.
>
> Layihədə işlənən **Baloo 2** (başlıq) və **Nunito** (mətn) 14 hərfin
> hamısını daşıyır: `Ç ç Ə ə Ğ ğ İ ı Ö ö Ş ş Ü ü`. Yenisini əlavə etməzdən
> əvvəl həmin sətri fontda çap etdirib gözlə yoxla.

> ⚠️ **`_draw` içindəki hər primitiv AYRICA çəkiliş çağırışıdır.**
>
> Sprite-lar batch olunur, `draw_circle`/`draw_arc` isə yox. Xəritəyə dərinlik
> verəndə əvvəlcə hər şey `_draw`-a yazılmışdı — döşəmə 14 konsentrik disk,
> hər bərk maneəyə iki kölgə dairəsi, şüşə kənara dörd qövs. Ölçmə:
>
> | | Çəkiliş çağ. | Orta kadr | 1% ən pis |
> |---|---|---|---|
> | Əvvəl | 237 | 4.17 ms | 4.26 ms |
> | Hamısı `_draw`-da | **293** | 4.18 ms | 4.55 ms |
> | Döşəmə teksturaya, kölgə sprite-a | **207** | 4.17 ms | 4.17 ms |
>
> Yəni 14 disk = 14 çağırış, 15 maneənin kölgəsi = 30 çağırış. Teksturaya
> köçürüləndə isə **pulsuzdur**: sprite onsuz da çəkilir, kölgə onun bir
> hissəsidir. Nəticədə xəritə ƏVVƏLKİNDƏN də ucuz oldu — köhnə kod da
> kölgələri hər kadr `_draw`-da çəkirdi.
>
> Qayda: `_draw` yalnız **azsaylı və qat boyu ortaq** şeylər üçündür (şəbəkə
> bir `draw_multiline`, şüşə kənar bir neçə qövs). Obyekt başına təkrarlanan
> hər şey teksturaya bişirilməlidir.

> ⚠️ **Sprite-lara AYRI-AYRI `modulate` vermə.**
> 
> `gl_compatibility` batch-i yalnız ardıcıl, eyni teksturalı VƏ **eyni
> `modulate`-lı** elementləri bir çağırışa yığır. Hər maneəyə ±6% parlaqlıq
> fərqi verilmişdi — nəticə ölçüldü:
> 
> | | Çəkiliş çağ. | Ən pis kadr | 1% ən pis |
> |---|---|---|---|
> | Hər sprite-a ayrı `modulate` | 242 | **70.7 ms** (14 FPS) | 50% büdcə |
> | `modulate` çıxarılıb | **131** | 11.3 ms | 25% büdcə |
> 
> Xəta yoxdur, xəbərdarlıq yoxdur — sadəcə oyun telefonda ilişir. Rəng
> fərqi lazımdırsa **teksturaya bişir**, kodda modulate ilə vermə.

> ⚠️ **Yeni `class_name` skript yaradandan sonra MÜTLƏQ `--import` işlət.**
> 
> ```bash
> GODOT --headless --path game --import
> ```
> 
> Godot qlobal sinif adlarını `.godot/global_script_class_cache.cfg`-də saxlayır
> və onu YALNIZ redaktor (və ya `--import`) yeniləyir. Fayl diskdə olsa da,
> keşdə olmasa `class_name` tapılmır:
> 
> ```
> Parse Error: Could not find type "ShotTrails" in the current scope.
> Compile Error: Failed to compile depended scripts. (boot.gd)
> ```
> 
> Nəticə isə xətaya BƏNZƏMİR: `boot.gd` kompilyasiya olunmur, əsas səhnə heç
> vaxt yüklənmir, pəncərə açıq qalır və oyun sadəcə **donur**. Skript düzgün
> yazılıb, sınaqlar keçir, amma oyun işləmir — sanki dəyişiklik "alınmayıb".
> 
> `.uid` faylı da elə `--import` zamanı yaranır; onsuz commit etsən başqa
> maşında eyni hal təkrarlanır.

> ⚠️ **iOS klaviaturanı YALNIZ toxunuşun içində fokuslanan HTML sahəsi üçün açır.**
>
> Godot-un brauzerdəki yazı sahəsi gizli elementi taymerlə fokuslayır. Android
> Chrome buna icazə verir, iOS isə yox — və heç bir xəta yoxdur: sahə fokuslanır,
> kursor yanır, sadəcə klaviatura çıxmır. Ona görə Android-də sınanan dost
> ekranı "işləyirdi", iPhone-da isə kod ümumiyyətlə yazıla bilmirdi.
>
> Telefon brauzerində yeni `LineEdit` əlavə edəndə onu [`WebText.attach`](game/scripts/client/web_text.gd)
> ilə bağla (bax «Telefon brauzerində yazı»). Yoxlamaq üçün emulyator kifayət
> deyil: masaüstü Chrome-un telefon rejimi fokusu həmişə qəbul edir.

> ⚠️ **Brauzerdə `Engine.max_fps` qoyma — o, BOŞ DÖVRDÜR.**
>
> Godot 4.7-nin thread-siz veb build-ində kadr həddi kadrlar arasını `usleep` ilə
> doldurur, emscripten-də isə əsas axında `usleep` fırlanmadır: 30 kadrlıq hədd ilə
> bir nüvə oyun boyu 100% yüklü qalırdı və bu, heç bir ölçüdə "yavaşlıq" kimi
> görünmürdü — kadr vaxtı düz 33.3 ms çıxırdı. Hədd brauzerdə səhifədədir
> (`germSetFrameCap`, bax [`Settings._apply_frame_cap`](game/scripts/shared/settings.gd)),
> kadr büdcəsini hesablayan kod isə `Settings.frame_cap()`-i oxuyur — `Engine.max_fps`
> orada 0-dır. `sim_test` arena kodunda `Engine.max_fps` yazılmasına icazə vermir.

> ⚠️ **`JavaScriptBridge.eval` JS-in `true`-sunu bool yox, int 1 qaytarır.**
>
> `JavaScriptBridge.eval("... === 'function'") == true` müqayisəsi int ilə bool
> olduğu üçün xəta verir və funksiya səssizcə dayanır — release build-də heç nə
> yazılmır. Kadr həddi elə buna görə ilk sınaqda köhnə yola düşmüşdü. JS-dən ədəd
> qaytar (`? 1 : 0`) və `float(...)` ilə müqayisə et.

> ⚠️ **İsti çəkilişdə `draw_circle` / `draw_arc` işlətmə — hər biri ayrıca poliqondur.**
>
> Godot 4.7-nin GLES3 render-ində (brauzerdə WebGL2) hər dairə öz GPU buferi və öz
> çəkiliş çağırışıdır, yenidən çəkiləndə bufer silinib təzədən yaradılır;
> antialias-lı qövs üç poliqondur. Kadrda çəkilən yerlərdə [`BatchDraw`](game/scripts/client/batch_draw.gd)
> işlət: disk və nazik halqa ardıcıl gələndə bir çağırışdır. Disk və xətti NÖVBƏLƏŞDİRMƏ
> — hər keçid yeni çağırışdır: əvvəl bütün disklər, sonra bütün xətlər. `sim_test`
> mikrob, minimap, partlayış və nişan xəttində `draw_circle` qalmadığını yoxlayır.

## Assetlər — bir vacib məhdudiyyət

> ⚠️ **Yenidən oynatma sayğacı İKİNCİ dəfə azaldır — onlayn ulti "işləmirdi".**
>
> [`Arena._reconcile`](game/scripts/client/arena.gd) hər snapshot-da mikrobu
> serverin halına qaytarır və təsdiqlənməmiş girişləri yenidən oynadır. Atəşin
> soyuması bunu düzgün keçirdi, çünki server onu göndərir və oynatma serverin
> dəyərindən başlayır. Superin qalan vaxtı isə GÖNDƏRİLMİR (yalnız "işləyir"
> biti) — oynatma CANLI sayğacdan başlayırdı, canlı proqnoz isə həmin tick-ləri
> artıq saymışdı. ~200 ms gediş-gəlişdə hər snapshot sayğacdan 0.2 s yeyirdi:
> ayaqlının 4 saniyəlik toru və amöbün kisti öz ekranında ~0.7 s sonra sönürdü,
> kist üstəlik proqnozda tez açılır, mikrob yeriyib geri dartılırdı. Server
> superi tam müddət işlədirdi və rəqiblər onu düzgün görürdü — səhv yalnız
> oyunçunun ÖZ ekranında idi. Kirpiklinin superi anidir, ona toxunmurdu; məşqdə
> gözləyən giriş olmadığı üçün görünmürdü.
>
> Qayda: canlı proqnozun saydığı hər sayğac oynatmadan ƏVVƏL oynatmanın
> başlanğıcına qaytarılmalıdır — ya serverin dəyəri ilə, ya da gözləyən
> girişlərin sayı qədər geri çəkilərək. `_test_super_timer_survives_reconcile`
> bunu 200 və 530 ms gecikmə ilə qoruyur.

> ⚠️ **SVG-də `<text>` elementi işlətmə.** Godot SVG-ni ThorVG ilə rasterləşdirir,
> ThorVG isə mətn elementlərini **sükutla atır** — heç bir xəta vermir, sadəcə
> yazı görünmür.
>
> Loqodakı "GERM ARENA" yazısı məhz buna görə SVG-də yox, Godot `Label`-ı ilə
> çəkilirdi (`main_menu.gd → _make_logo`). Yatay menyuda söz nişanı yoxdur —
> yuxarı sol küncdə oyunçunun öz nişanı dayanır, Brawl Stars ana ekranında
> olduğu kimi.

### Şriftlər

İki rol var və hər ikisi [`assets/ui/theme.tres`](game/assets/ui/theme.tres)-dən
gəlir — kodda hər `Label` üçün ayrıca şrift təyin edilmir:

| Rol | Şrift | Harada |
|---|---|---|
| Başlıq | **Baloo 2** (dəyişkən, 800) | Düymələr, növün adı, doluluq rəqəmi, mərkəzi mesajlar |
| Mətn | **Nunito** (dəyişkən, 600) | Liderlər, izahlar, ad qutusu, ipucları |

Başlıq rolu `Label`-a `theme_type_variation = "Heading"` ilə verilir (ayrıca
tip yoxdur — başlıq da `Label`-dir). Şrift dəyişdirməzdən əvvəl yuxarıdakı
Azərbaycan hərfləri tələsini oxu.

Dünyada **üç mikrob növü** var və hamısı tamamilə kodla çəkilir:

- **Kirpikli** — paramesium modeli. Kirpikləri metaxronal dalğa ilə döyünür,
  arxasında qamçı var, suda **üzür**.
- **Ayaqlı** — "günəş heyvancığı". Şüa kimi çıxan aksopodiyaları növbə ilə
  yığılıb-uzanır, dibdə **yeriyir**; sitoplazması öndəki ayağa axır.
- **Amöb** — hərəkət orqanı yoxdur, kənarın ÖZÜ hərəkət edir. İki qatlı gövdə
  (jel qabıq + axıcı iç) önə uzanıb arxadan yığılır və sahəsini saxlayaraq
  irəli axır — **sürünür**.

Növü **menyudan sən seçirsən** (üç kart). Seçim oyunun gedişinə **təsir edir**
(aşağıdakı bölmə) və buna baxmayaraq şəbəkəyə **bir bayt da** əlavə etmir:
növ də, superin doluluğu da toxunulmazlıq bayrağının boş bitlərində daşınır.

### Növün özəlliyi və superi

Hər növün **mühitlə münasibəti** başqadır — bu, üç orqanizmin əsl
ekologiyasıdır: planktonik üzgüçü, bentik yeriyən, substrat sürünəni.

| | Passiv | Super | Superin qiyməti |
|---|---|---|---|
| **Kirpikli** | ən cəld: tez qopur, uzun sürüşür · axın onu daha çox aparır | **TRİXOSİST** — yaxındakı rəqib topları dağılıb qidaya çevrilir, mikroblar itələnir, özü geri sıçrayır | −2 top; dağılan toplar yerə düşür və rəqib onları geri yeyə bilər |
| **Ayaqlı** | axına dirənir (pəncələr yapışır) · ən yavaş növ | **AKSOPODİYA TORU** — 4 saniyə: qida ona axır, tora düşən rəqib 40% yavaşlayır | tutumu aşarsa **öz superi onu partladır** — dolu ikən açmaq olmaz |
| **Amöb** | maneə radiusu kiçikdir: başqasının sığmadığı aralıqdan keçir | **MİNİQAN** — 2.5 saniyə yerində donub **fasiləsiz** atəş: 0.25 s-də bir top, toplar **öz sayından getmir**, metabolizm dayanır | qalxan yoxdur — sənə top adi kimi dəyir, qaça da bilmirsən |

Super **döyüşərək** dolur (Brawl Stars məntiqi): dəymə +3, qida +1/3 top,
sənə dəyəndə +1, partlatma isə tam doldurur. Hədd **15**-dir və bu rəqəm
təsadüfi deyil — dörd bitə tam sığır.

> **Superin özü rəqibin top sayına toxunmur.** Zərər verən super
> `SHOT_PAYLOAD` riyaziyyatını yan yoldan pozardı, ona görə trixosist və tor
> **mövqe və qida** üzərində işləyir. Amöbün miniqanı isə adi topla vurur — top
> rəqibə yenə `SHOT_PAYLOAD` qədər verir, sadəcə super boyu atəş tez və PULSUZDUR
> (oyunçunun istəyi). Bu, qəsdən istisnadır: miniqanın topları dünyaya maddə
> əlavə edir. Supersiz atəş dövrü, topun qiyməti və tutum artımı üç növdə də
> eynidir — bunu sənəd yox, `sim_test` saxlayır.

Botlar da superini işlədir və bu, məcburidir: dünyanın əhalisinin çoxu botdur,
super yalnız onlar da işlədəndə oyunun bir hissəsinə çevrilir.

Mikrobun ətrafında **halqa yoxdur**. Əvvəl iki halqa vardı (doluluq və fokus);
ikisi də çıxarıldı, çünki mikrobu konsentrik dairələrin içinə salırdı. Doluluq
indi membranın öz gərginliyindən oxunur, "bu, mənəm" sualına isə kamera cavab
verir — öz mikrobun həmişə ekranın mərkəzindədir.

Mikrob sprite DEYİL: ölçüsü tutumdan, içindəki topların sayı isə mövcud
saydan asılıdır, ikisi də oyun boyu dəyişir. Tam kodla çəkilir —
[`germ_visual.gd`](game/scripts/client/germ_visual.gd). Eyni səbəbdən partlayış
([`burst_fx.gd`](game/scripts/client/burst_fx.gd)) da kodla çəkilir: dalğaların
ölçüsü partlayan mikrobun radiusundan, damcıların sayı isə içindəki top
sayından asılıdır.

Təfərrüat: [`design/ART_BIBLE.md`](design/ART_BIBLE.md).

## Səslər

9 səs effekti [`design/tools/gen_audio.js`](design/tools/gen_audio.js) skripti ilə
**sintez olunur** — hazır sample yoxdur:

```bash
node design/tools/gen_audio.js   # design/audio/ qovluğuna yazır
cp design/audio/*.wav game/assets/sfx/
```

Skript yazdığı faylı geri oxuyub yoxlayır (format, müddət həddi, pik səviyyə,
kənar fade-lər) — pozuq klip layihəyə düşə bilmir.

`eject` və `hit` qəsdən fərqli tezlik sahələrindədir: oyunçu ekrana baxmadan
atışının canlı hədəfə dəydiyini eşitməlidir. Təfərrüat:
[design/AUDIO_BIBLE.md](design/AUDIO_BIBLE.md)

### Şinlər

Üç şin var: `Master` → `SFX` və `UI`. Sürgülər yalnız şini çəkir, klipin öz
səviyyəsini yox — `AUDIO_BIBLE`-ın üçpilləli tarazlığı (səviyyə 3 səsləri
−6 dB ilə çalınır) olduğu kimi qalır.

`UI` ayrıdır, çünki menyu toxunuşu ilə oyunun səsi bir-birinin işi deyil:
oyunçu arenada effektləri qısıb düymə cavabını saxlaya bilər, ya da əksinə.
Şinlər `default_bus_layout.tres` faylı ilə yox, kodda qurulur —
[`Settings._ensure_buses`](game/scripts/shared/settings.gd).
