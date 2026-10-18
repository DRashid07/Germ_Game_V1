// Mikrobun bütün görüntüsü — GPU-da (bax scripts/client/germ_gpu.gd, design/PERF_PLAN.md F1).
//
// Mesh SABİTDİR: təpələrdə mövqe yox, KOD var — VERTEX.x qat, VERTEX.y element
// indeksi, UV.x təpənin rolu. Hər kadr dəyişən hər şey (radius, vaxt, sürət,
// rənglər, ayaqların ucları) `data` teksturasındakı mikrobun SƏTRİNDƏN oxunur
// (sətrin nömrəsi `row`-dur); membranın konturu və mərkəzi isə bu kadr kontur
// keçidinin qurduğu `ring_tex`-dən (shaders/germ_shape.gdshader).
//
// Formullar [GermVisual]-dakı GDScript çəkilişinin bir-bir köçürülməsidir,
// antialias-lı xətlər isə Godot-un öz `canvas_item_add_polyline`-ının
// (servers/rendering/renderer_canvas_cull.cpp, 4.7.2) həndəsəsidir: eyni en
// kompensasiyası, eyni miter, eyni yumşaq kənar, eyni uc qapaqları və eyni
// çəkiliş sırası (özək → sol kənar → sağ kənar). Rəqəm dəyişəndə HƏR İKİ yer
// dəyişməlidir — GDScript yolu ehtiyat və müqayisə üçün qalır
// (`--germ-bench --bench-render pair`).
shader_type canvas_item;

uniform sampler2D data : filter_nearest, repeat_disable;
// Konturlar — GPU-da kadrda bir dəfə qurulur (shaders/germ_shape.gdshader).
uniform sampler2D ring_tex : filter_nearest, repeat_disable;
instance uniform float row = 0.0;

// Palitra və sabitlər — GermGPU onları Palette/Const/GermVisual-dan BİR dəfə yazır.
uniform vec3 c_outline;
uniform vec3 c_body_light;
uniform vec3 c_danger;
uniform vec3 c_warning;
uniform vec3 c_text;
uniform vec3 c_hit_flash;
uniform vec3 c_ally;
uniform vec3 c_super_ready;
uniform vec2 light_dir;
uniform float shot_radius;
uniform float shot_speed;
uniform float net_radius;
uniform float shield_gap;
uniform float halo_gap_scale;
uniform float lit_inset;
uniform float lit_shift;
uniform vec2 specular_size;
uniform float specular_offset;
uniform float specular_alpha;
uniform float rim_normal_cutoff;
uniform float crawl_band;
uniform float crawl_band_min;
uniform float crawl_core;
uniform float leg_sway;
uniform float cilia_beat;
uniform float cilia_waves;
uniform float stretch_max;
uniform float tail_length;
uniform int tail_points;
uniform int cilia_min;
uniform int cilia_max;

// `ring_tex`-in sütunları (son kontur, kölgənin konturu, iki mərkəz) və `data`
// sətrində ayaqların yeri — GermGPU-dakı adları ilə EYNİ.
const int RING0 = 0;
const int SRING0 = 44;
const int COL_MID = 88;
const int COL_SMID = 89;
const int LEGS0 = 20;
// Kontur nöqtəsinin sabit nöqtə kodu (germ_shape.gdshader-dəki ilə EYNİ).
const float RANGE = 256.0;
const float STEPS = 128.0;

// Qatlar — GermGPU-dakı L_* ilə EYNİ.
const int L_SHADOW_OUT = 1;
const int L_SHADOW_IN = 2;
const int L_BIRTH = 3;
const int L_HALO = 4;
const int L_AURA = 5;
const int L_SKIN = 6;
const int L_LIT = 7;
const int L_SKIN2 = 8;
const int L_LIT2 = 9;
const int L_SPEC = 10;
const int L_CORE = 11;
const int L_BALL = 12;
const int L_EMERGE = 13;
const int L_OUTLINE = 14;
const int L_OUTLINE2 = 15;
const int L_LEG_DARK = 16;
const int L_LEG_COL = 17;
const int L_LEG_TIP = 18;
const int L_SKELETON = 19;
const int L_CILIA = 20;
const int L_TAIL_OUT = 21;
const int L_TAIL_IN = 22;
const int L_RIM = 23;
const int L_CRACK = 24;
// Super — CPU sırasında olduğu kimi çatlardan sonra, yoldaş halqasından əvvəl.
const int L_CYST_DISC = 30;
const int L_CYST_SHELL = 31;
const int L_CYST_INNER = 32;
const int L_CYST_GLINT = 33;
const int L_CYST_SEAM = 34;
const int L_NET_FILL = 35;
const int L_NET_EDGE_DARK = 36;
const int L_NET_EDGE = 37;
const int L_NET_INNER = 38;
const int L_NET_RAY = 39;
const int L_NET_TIP = 40;
const int L_ALLY = 41;
const int L_SAFE = 42;
const int L_SPARK = 43;
const int L_FLASH = 44;

// Fragmentin növü.
const int K_FLAT = 0;
const int K_DISC = 1;
const int K_STAR = 2;
const int K_ELLIPSE = 3;
const int K_HALO = 4;
const int K_AURA = 5;

// Godot-un FEATHER_SIZE-ı.
const float FEATHER = 1.25;

const vec2 CORNER[4] = vec2[](vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0), vec2(-1.0, 1.0));

varying vec2 v_local;
varying vec4 v_shape;
varying flat int v_kind;

vec4 P(int rw, int k) {
	return texelFetch(data, ivec2(k, rw), 0);
}

// İki baytlıq sabit nöqtə koordinatı (bax germ_shape.gdshader, `encode`).
vec2 decode(vec4 c) {
	vec4 b = floor(c * 255.0 + 0.5);
	return vec2(b.x * 256.0 + b.y, b.z * 256.0 + b.w) / STEPS - RANGE;
}

vec2 RT(int rw, int col) {
	return decode(texelFetch(ring_tex, ivec2(col, rw), 0));
}

// Konturun i-ci nöqtəsi (`base` = RING0 və ya SRING0). GLSL-də mənfi ədədin `%`-i
// təyin olunmayıb, ona görə əvvəl n əlavə olunur (i >= -n).
vec2 RP(int rw, int base, int n, int i) {
	return RT(rw, base + (i + n) % n);
}

float crs(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

// Godot-un Vector2.orthogonal() — (y, -x).
vec2 orth(vec2 v) {
	return vec2(v.y, -v.x);
}

vec2 dirv(float a) {
	return vec2(cos(a), sin(a));
}

// Vector2.normalized() kimi: sıfır vektor sıfır qalır.
vec2 safe_norm(vec2 v) {
	float l = length(v);
	return l > 1e-12 ? v / l : vec2(0.0);
}

// GermVisual._inset — konturun mərkəzinə doğru bərabər enli çəkmə.
vec2 inset_pt(vec2 q, vec2 cen, float width) {
	vec2 v = q - cen;
	float d = length(v);
	if (d < 0.001) {
		return q;
	}
	return cen + v / d * max(d - width, d * 0.18);
}

// Amöbün iç qatının i-ci nöqtəsi (GermVisual._draw-dakı inner_ring).
vec2 inner_pt(int rw, int n, int i, vec2 mid, float r) {
	return inset_pt(RP(rw, RING0, n, i), mid, max(r * crawl_band, crawl_band_min));
}

vec2 ring_pt(int rw, int n, bool inner, vec2 mid, float r, int i) {
	return inner ? inner_pt(rw, n, i, mid, r) : RP(rw, RING0, n, i);
}

// GermVisual._ring_centre — iç qatın kütlə mərkəzi.
vec2 inner_centre(int rw, int n, vec2 mid, float r) {
	float a2 = 0.0;
	vec2 acc = vec2(0.0);
	vec2 a = inner_pt(rw, n, 0, mid, r);
	for (int j = 0; j < n; j++) {
		vec2 b = inner_pt(rw, n, j + 1, mid, r);
		float c = a.x * b.y - b.x * a.y;
		a2 += c;
		acc += (a + b) * c;
		a = b;
	}
	return abs(a2) < 0.0001 ? vec2(0.0) : acc / (3.0 * a2);
}

// draw_arc-ın i-ci nöqtəsi (CanvasItem::draw_ellipse_arc ilə eyni ifadə).
vec2 arc_pt(float radius, float start, float delta, int count, int i) {
	float th = (float(i) / (float(count) - 1.0)) * delta + start;
	return vec2(radius * cos(th), radius * sin(th));
}

// canvas_item_get_compensated_antialiasing_width.
float aa_width(float w) {
	if (w <= FEATHER * 2.0 + 0.00001) {
		return w * 0.5;
	}
	if (w <= FEATHER * 4.0 + 0.00001) {
		return mix(w * 0.5, w - FEATHER * 0.5, (w - FEATHER * 2.0) / (FEATHER * 2.0));
	}
	return w - FEATHER * 0.5;
}

// compute_polyline_edge_offset_clamped — birləşmədə miter.
vec2 miter(vec2 seg, vec2 prev) {
	vec2 d = prev - seg;
	float dl = length(d);
	if (dl < 1e-6 || length(prev) < 1e-6) {
		return orth(seg);
	}
	vec2 bis = d / dl;
	vec2 sc = vec2(dot(bis, prev), crs(bis, prev));
	float sa = sc.y / max(length(sc), 1e-12);
	if (abs(sa) < 0.00001) {
		return orth(seg);
	}
	return bis * clamp(1.0 / sa, -3.0, 3.0);
}

// Antialias-lı polyline-ın bir təpəsi. Rollar (Godot-un üç zolağındakı yerləri):
//   0 = cur + e, 1 = cur − e            — özək, tam rəng;
//   2 = cur + e + B, 3 = cur − e − B    — sol/sağ yumşaq kənar, şəffaf;
//   4 = cur + e + c, 5 = cur − e + c    — açıq xəttin ucundakı özək qapağı;
//   6 = 4 + B, 7 = 5 − B                — ucun künc kvadratları.
// first/last — açıq xəttin ucları (qapalı halqada ikisi də false); qapaq
// yalnız `cap_on` olanda çıxır, yoxsa 4..7 təpələri 0..3-ün üstünə düşür.
vec2 aa_vertex(vec2 prev, vec2 cur, vec2 next, bool first, bool last, bool cap_on,
		int role, float width, out float alpha) {
	float w2 = aa_width(width);
	float border = FEATHER * (w2 < 1.0 ? w2 : 1.0);
	vec2 seg = safe_norm(next - cur);
	vec2 pre = safe_norm(cur - prev);
	vec2 base;
	vec2 cap = vec2(0.0);
	if (first) {
		base = orth(seg);
		cap = -seg * border;
	} else if (last) {
		base = orth(pre);
		cap = pre * border;
	} else {
		base = miter(seg, pre);
	}
	if (!cap_on) {
		cap = vec2(0.0);
	}
	vec2 e = base * (w2 * 0.5);
	vec2 b = base * border;
	alpha = role <= 1 ? 1.0 : 0.0;
	if (role == 0) {
		return cur + e;
	}
	if (role == 1) {
		return cur - e;
	}
	if (role == 2) {
		return cur + e + b;
	}
	if (role == 3) {
		return cur - e - b;
	}
	if (role == 4) {
		return cur + e + cap;
	}
	if (role == 5) {
		return cur - e + cap;
	}
	if (role == 6) {
		return cur + e + cap + b;
	}
	return cur - e + cap - b;
}

// canvas_item_add_line (antialiassız qalın xətt): 0 = a+t, 1 = a−t, 2 = b−t, 3 = b+t.
vec2 line_vertex(vec2 a, vec2 b, float width, int corner) {
	vec2 t = safe_norm(orth(a - b)) * (width * 0.5);
	if (corner == 0) {
		return a + t;
	}
	if (corner == 1) {
		return a - t;
	}
	if (corner == 2) {
		return b - t;
	}
	return b + t;
}

// O nöqtəsindən d istiqamətində şüanın konturdan ilk çıxışı (kəsmirsə böyük ədəd).
float ray_hit(int rw, int n, bool inner, vec2 mid, float r, vec2 o, vec2 d) {
	float best = 1e9;
	vec2 a = ring_pt(rw, n, inner, mid, r, 0);
	for (int j = 0; j < n; j++) {
		vec2 b = ring_pt(rw, n, inner, mid, r, j + 1);
		vec2 e = b - a;
		float den = crs(d, e);
		if (abs(den) > 1e-6) {
			vec2 w = a - o;
			float tt = crs(w, e) / den;
			float u = crs(w, d) / den;
			if (tt > 0.0 && u >= 0.0 && u <= 1.0) {
				best = min(best, tt);
			}
		}
		a = b;
	}
	return best;
}

// İşıq qatının i-ci nöqtəsi — içəri çəkilmiş və işığa sürüşdürülmüş kontur.
vec2 lit_src(int rw, int n, bool inner, vec2 mid, vec2 cen, float r, int i) {
	vec2 q = ring_pt(rw, n, inner, mid, r, i);
	return inset_pt(q, cen, r * lit_inset) + light_dir * (r * lit_shift);
}

// Kontur (`lit` = sürüşdürülmüş kontur) `o` nöqtəsindən necə görünür:
// 0 = nöqtə xaricdədir (üfüqi şüanın kəsişmə cütlüyü, PNPOLY), 1 = içindədir,
// amma kontur ona görə ulduzvari deyil, 2 = BÜTÖV görünür (bütün (o, a, b)
// üçbucaqları eyni istiqamətdə fırlanır).
int seen_from(int rw, int n, bool inner, bool lit, vec2 mid, vec2 cen, float r, vec2 o) {
	bool in_poly = false;
	bool pos = false;
	bool neg = false;
	vec2 a = lit ? lit_src(rw, n, inner, mid, cen, r, n - 1) : ring_pt(rw, n, inner, mid, r, n - 1);
	for (int j = 0; j < n; j++) {
		vec2 b = lit ? lit_src(rw, n, inner, mid, cen, r, j) : ring_pt(rw, n, inner, mid, r, j);
		if ((a.y > o.y) != (b.y > o.y) && o.x < a.x + (o.y - a.y) * (b.x - a.x) / (b.y - a.y)) {
			in_poly = !in_poly;
		}
		float c = crs(a - o, b - o);
		pos = pos || c > 0.0001;
		neg = neg || c < -0.0001;
		a = b;
	}
	return !in_poly ? 0 : (pos && neg ? 1 : 2);
}

// Yelpiyin mərkəzi üçün namizədlər — işıqlı linzanın ortasından sürüşmə (işıq
// oxu boyunca, ona dik), r vahidində. Birincisi linzanın özüdür; qalanları gövdə
// çökəkləşəndə lazım olur (tam sürətdə atəş anında amöbün iç qatı).
const vec2 LIT_CANDIDATES[11] = vec2[](
	vec2(0.0, 0.0), vec2(-0.06, 0.0), vec2(0.06, 0.0), vec2(0.0, 0.08), vec2(0.0, -0.08),
	vec2(-0.12, 0.0), vec2(0.12, 0.0), vec2(-0.06, 0.08), vec2(-0.06, -0.08),
	vec2(0.06, 0.08), vec2(0.06, -0.08));

// İşıq qatının yelpik mərkəzi: HƏR İKİ konturun (gövdə və sürüşdürülmüş kontur)
// bütöv göründüyü ilk namizəd — onda kəsişmə də ona görə ulduzvaridir və yelpik
// onu dəqiq örtür (z = 1). Belə nöqtə yoxdursa, iki konturun içində olan ilk
// namizəd götürülür (z = 0.5): şüa gövdədən ilk çıxışda kəsildiyi üçün qat
// çökəkliyin arxasını bir az az örtür, amma heç vaxt bayıra daşmır. Heç biri
// içində deyilsə, linza boşdur (CPU-da da kəsişmə yoxdur) — qat çəkilmir (z = 0).
//
// Linzanın ortası: dairəvi gövdədə (radius R) linza işıq oxu boyunca
// [r·(shift+inset) − R, R] aralığını tutur, ortası R-dən asılı olmayaraq
// r·(shift+inset)/2-dədir — doğuş pop-unda gövdə beşdə birinə kiçiləndə də.
vec3 lit_centre(int rw, int n, bool inner, vec2 mid, vec2 cen, float r) {
	vec2 side = vec2(-light_dir.y, light_dir.x);
	vec2 lens = cen + light_dir * (r * (lit_shift + lit_inset) * 0.5);
	vec3 fallback = vec3(lens, 0.0);
	for (int k = 0; k < 11; k++) {
		vec2 c = lens + (light_dir * LIT_CANDIDATES[k].x + side * LIT_CANDIDATES[k].y) * r;
		int body = seen_from(rw, n, inner, false, mid, cen, r, c);
		if (body == 0) {
			continue;
		}
		int lit = seen_from(rw, n, inner, true, mid, cen, r, c);
		if (lit == 0) {
			continue;
		}
		if (body == 2 && lit == 2) {
			return vec3(c, 1.0);
		}
		if (fallback.z == 0.0) {
			fallback = vec3(c, 0.5);
		}
	}
	return fallback;
}

// GermVisual._lit_polygon — işıqlı sel qatı: içəri çəkilmiş, işığa sürüşdürülmüş
// kontur, HƏQİQİ gövdə ilə kəsişdirilmiş. CPU bunu Clipper ilə edir; burada hər
// nöqtə yelpiyin mərkəzindən çıxan öz şüası boyunca gövdənin sərhədinə sıxılır.
// İki çoxbucaqlı bu mərkəzə görə ulduzvaridir, ona görə kəsişmə də elə budur —
// fərq yalnız sərhəddəki vətərlərdədir (piksel altı, konturun altında qalır).
vec2 lit_pt(int rw, int n, bool inner, vec2 mid, vec2 cen, float r, vec2 c0, int i) {
	vec2 s = lit_src(rw, n, inner, mid, cen, r, i);
	vec2 d = s - c0;
	float ds = length(d);
	if (ds < 1e-4) {
		return s;
	}
	d /= ds;
	return c0 + d * min(ds, ray_hit(rw, n, inner, mid, r, c0, d));
}

bool bit_at(uint lo, uint hi, int j) {
	return j < 32 ? ((lo >> uint(j)) & 1u) != 0u : ((hi >> uint(j - 32)) & 1u) != 0u;
}

// GermVisual._rim_segment: işığın əksinə baxan təpələrin ƏN UZUN ardıcıl qövsü —
// (başlanğıc, say). Uyğun qövs bir neçə dənə ola bilər (amöbün dalğalı kənarı),
// CPU onların yalnız ən uzununu çəkir.
ivec2 rim_run(int rw, int n) {
	uint plo = 0u;
	uint phi = 0u;
	uint nlo = 0u;
	uint nhi = 0u;
	float area2 = 0.0;
	vec2 pa = RP(rw, RING0, n, n - 1);
	vec2 pb = RP(rw, RING0, n, 0);
	vec2 inc = safe_norm(pb - pa);
	for (int j = 0; j < n; j++) {
		vec2 pc = RP(rw, RING0, n, j + 1);
		vec2 outg = safe_norm(pc - pb);
		area2 += crs(pb, pc);
		vec2 s = vec2(inc.y, -inc.x) + vec2(outg.y, -outg.x);
		float sl = length(s);
		float d = sl > 1e-12 ? dot(s, -light_dir) / sl : 0.0;
		uint bit = 1u << uint(j % 32);
		if (d > rim_normal_cutoff) {
			if (j < 32) {
				plo |= bit;
			} else {
				phi |= bit;
			}
		}
		if (-d > rim_normal_cutoff) {
			if (j < 32) {
				nlo |= bit;
			} else {
				nhi |= bit;
			}
		}
		inc = outg;
		pb = pc;
	}
	uint lo = area2 >= 0.0 ? plo : nlo;
	uint hi = area2 >= 0.0 ? phi : nhi;
	int best_start = -1;
	int best_count = 0;
	for (int i = 0; i < n; i++) {
		if (!bit_at(lo, hi, i) || bit_at(lo, hi, (i + n - 1) % n)) {
			continue;
		}
		int count = 0;
		while (count < n && bit_at(lo, hi, (i + count) % n)) {
			count++;
		}
		if (count > best_count) {
			best_start = i;
			best_count = count;
		}
	}
	return ivec2(best_start, best_count);
}

void vertex() {
	int R = int(row + 0.5);
	int layer = int(VERTEX.x + 0.5);
	int idx = int(VERTEX.y + 0.5);
	int role = int(UV.x + 0.5);

	vec4 p0 = P(R, 0);
	float r = p0.x;
	float t = p0.y;
	float rush = p0.z;
	float heading = p0.w;
	vec4 p1 = P(R, 1);
	float strain = p1.x;
	bool danger_on = p1.y > 0.5;
	float pulse = p1.z;
	bool born = p1.w > 0.5;
	vec4 p2 = P(R, 2);
	int n = max(int(p2.x + 0.5), 3);
	vec2 mid = RT(R, COL_MID);
	float outline_w = p2.w;
	float species = P(R, 3).w;
	bool amoeba = species > 1.5;

	vec2 pos = vec2(0.0);
	vec4 col = vec4(0.0);
	int kind = K_FLAT;
	vec4 shape = vec4(0.0);
	vec2 local = vec2(0.0);
	float a_line = 1.0;

	// ---- dolu formalar — mərkəzdən yelpik (gövdə öz mərkəzinə görə ulduzvaridir) ----
	if (layer == L_SHADOW_OUT || layer == L_SHADOW_IN) {
		// GermVisual._draw_contact_shadow: hadisəsiz formanın iki ellipsi.
		vec2 smid = RT(R, COL_SMID);
		vec2 sc = layer == L_SHADOW_OUT ? vec2(1.15, 1.15 * 0.62) : vec2(1.0, 0.62);
		vec2 q = role == 0 ? smid : RP(R, SRING0, n, idx);
		pos = smid + (q - smid) * sc - light_dir * (r * 0.22);
		col = vec4(c_outline, layer == L_SHADOW_OUT ? 0.18 : 0.45);
	} else if (layer == L_SKIN || layer == L_FLASH) {
		pos = role == 0 ? mid : RP(R, RING0, n, idx);
		if (layer == L_FLASH) {
			// Zərbə parıltısı — siluetin üstündə ağ örtük, kvadrat sönmə.
			float f = P(R, 10).x;
			col = vec4(c_hit_flash, 0.92 * f * f);
			if (f <= 0.0) {
				pos = vec2(0.0);
			}
		} else {
			// Tünd dəri; amöbdə bu, açıq jel zolağıdır (gel_dark).
			vec3 tone = amoeba ? P(R, 5).rgb : P(R, 4).rgb;
			col = vec4(mix(mix(tone, c_outline, 0.30), c_danger, strain * (amoeba ? 0.26 : 0.30)), 1.0);
		}
	} else if (layer == L_SKIN2) {
		// Amöbün iç maye qatı (sol_dark).
		pos = role == 0 ? mid : inner_pt(R, n, idx, mid, r);
		col = vec4(mix(mix(P(R, 4).rgb, c_outline, 0.30), c_danger, strain * 0.30), 1.0);
	} else if (layer == L_LIT || layer == L_LIT2) {
		bool inner = layer == L_LIT2;
		vec2 cen = inner ? inner_centre(R, n, mid, r) : mid;
		vec3 c0 = lit_centre(R, n, inner, mid, cen, r);
		if (c0.z > 0.0) {
			pos = role == 0 ? c0.xy : lit_pt(R, n, inner, mid, cen, r, c0.xy, idx);
			bool gel = amoeba && !inner;
			vec3 tone = gel ? P(R, 5).rgb : P(R, 4).rgb;
			col = vec4(mix(mix(tone, c_body_light, 0.28), c_danger, strain * (gel ? 0.18 : 0.20)), 1.0);
		}

	// ---- yumşaq dairələr, ulduzlar, ellips, halo ----
	} else if (layer == L_HALO || layer == L_AURA) {
		float halo_r = r + shield_gap * halo_gap_scale;
		float h = halo_r;
		if (layer == L_HALO) {
			col = vec4(P(R, 4).rgb, 0.75 + 0.25 * strain);
			kind = K_HALO;
		} else {
			float fade = P(R, 8).w;
			h = fade > 0.004 ? halo_r * 1.25 : 0.0;
			col = vec4(c_super_ready, (0.70 + 0.30 * sin(t * 5.0)) * fade);
			kind = K_AURA;
		}
		local = CORNER[role] * h;
		pos = local;
		shape.x = h;
	} else if (layer == L_SPEC) {
		// GermVisual._specular_polygon — işıq tərəfində yaş parıltı.
		vec2 centre = light_dir * (r * specular_offset);
		vec2 tangent = vec2(-light_dir.y, light_dir.x);
		vec2 hs = specular_size * (r * 0.5);
		local = CORNER[role] * (hs + vec2(1.5));
		pos = centre + tangent * local.x + light_dir * local.y;
		shape.xy = hs;
		kind = K_ELLIPSE;
		col = vec4(c_body_light, specular_alpha);
	} else if (layer == L_CORE) {
		// GermVisual._draw_core — daxili kölgə (amöbün mesh-ində yoxdur).
		float rad = born ? r * 0.62 : 0.0;
		local = CORNER[role] * (rad > 0.0 ? rad + 1.5 : 0.0);
		pos = P(R, 8).xy + local;
		shape.x = rad;
		kind = K_DISC;
		col = vec4(mix(P(R, 6).rgb, c_danger, strain * 0.35), 0.45);
	} else if (layer == L_BALL) {
		// GermVisual._draw_inner_balls — "günəbaxan" düzümü. Topun üç kvadratı var
		// (role / 4): ulduzda kontur, ulduz və işıq nöqtəsi; dairədə top və işıq nöqtəsi.
		int sub = role / 4;
		vec4 p8 = P(R, 8);
		int nb = clamp(int(p8.z + 0.5), 0, 40);
		float rad = 0.0;
		vec2 at = vec2(0.0);
		float a = 0.0;
		if (idx < nb && born) {
			bool starry = amoeba && nb <= 14;
			float inner_r = amoeba ? r * crawl_core : r * 0.66;
			float dotr = clamp(inner_r / sqrt(float(nb)) * (starry ? 0.50 : 0.72), 2.0, 7.0);
			bool lit = dotr >= 4.0;
			float fi = float(idx);
			a = fi * 2.39996 + t * 0.35;
			float d = inner_r * sqrt((fi + 0.5) / float(nb));
			vec2 jitter = dirv(t * 1.8 + fi) * (dotr * 0.18);
			vec2 p = dirv(a) * d + jitter + p8.xy * (amoeba ? 1.0 : 0.6);
			at = p;
			if (starry) {
				if (sub == 0) {
					rad = dotr * 1.42;
					col = vec4(c_outline, 1.0);
					kind = K_STAR;
				} else if (sub == 1) {
					rad = dotr * 1.30;
					col = vec4(idx % 2 == 0 ? mix(P(R, 4).rgb, c_text, 0.25) : P(R, 5).rgb, 1.0);
					kind = K_STAR;
				} else if (lit) {
					rad = dotr * 0.30;
					at = p - vec2(dotr * 0.26);
					col = vec4(c_text, 0.75);
					kind = K_DISC;
				}
			} else if (sub == 0) {
				rad = dotr;
				col = vec4(P(R, 5).rgb, 0.95);
				kind = K_DISC;
			} else if (sub == 1 && lit) {
				rad = dotr * 0.35;
				at = p - vec2(dotr * 0.3);
				col = vec4(c_text, 0.8);
				kind = K_DISC;
			}
		}
		local = CORNER[role % 4] * (rad > 0.0 ? rad * 1.06 + 1.5 : 0.0);
		pos = at + local;
		shape = vec4(rad, a, 0.0, 0.0);
	} else if (layer == L_EMERGE) {
		// GermVisual._draw_emerging_ball — membranı yaran top.
		int sub = role / 4;
		vec4 p9 = P(R, 9);
		float rad = 0.0;
		vec2 at = vec2(0.0);
		if (born && p9.x >= 0.0 && p9.x <= p9.y + p9.w) {
			float travelled = shot_speed * p9.x;
			at = dirv(p9.z) * travelled;
			float lit = clamp(travelled / max(r, 1.0), 0.0, 1.0);
			if (sub == 0) {
				rad = shot_radius * 1.35;
				col = vec4(c_outline, 0.30 + 0.45 * lit);
			} else if (sub == 1) {
				rad = shot_radius;
				col = vec4(P(R, 5).rgb, 0.45 + 0.5 * lit);
			} else if (lit > 0.45) {
				rad = shot_radius * 0.55;
				col = vec4(c_text, 0.75 * (lit - 0.45) / 0.55);
			}
		}
		local = CORNER[role % 4] * (rad > 0.0 ? rad + 1.5 : 0.0);
		pos = at + local;
		shape.x = rad;
		kind = K_DISC;

	// ---- antialias-lı xətlər (Godot-un polyline həndəsəsi) ----
	} else if (layer == L_OUTLINE || layer == L_OUTLINE2) {
		// Qapalı kontur: n+1 stansiya, sonuncusu birincinin üstündədir.
		bool inner = layer == L_OUTLINE2;
		vec2 pv = ring_pt(R, n, inner, mid, r, idx - 1);
		vec2 cu = ring_pt(R, n, inner, mid, r, idx);
		vec2 nx = ring_pt(R, n, inner, mid, r, idx + 1);
		pos = aa_vertex(pv, cu, nx, false, false, false, role,
			inner ? outline_w * 0.58 : outline_w, a_line);
		col = vec4(P(R, 7).rgb, 0.95 * a_line);
	} else if (layer == L_RIM) {
		// Açıq xətt, uzunluğu dəyişir: stansiya s qövsün s-ci nöqtəsidir. Qövsdən
		// artıq stansiyalar sonuncunun üstünə yığılır — aradakı üçbucaqlar sıfır
		// sahəli olur. Son qapaq ayrıca stansiyadır (indeks n − 1, bax
		// GermGPU.Builder.aa_open_tail) və həmişə qövsün həqiqi sonuncusundadır.
		ivec2 run = rim_run(R, n);
		if (run.y >= 2) {
			float rim_w = max(1.4, r * 0.06);
			float inset_w = outline_w * 0.5 + rim_w * 0.5;
			bool tail = idx >= n - 1;
			int s = (tail || idx >= run.y) ? run.y - 1 : idx;
			int j = (run.x + s) % n;
			bool first = s == 0;
			bool last = s == run.y - 1;
			vec2 cu = inset_pt(RP(R, RING0, n, j), mid, inset_w);
			vec2 pv = first ? cu : inset_pt(RP(R, RING0, n, j - 1), mid, inset_w);
			vec2 nx = last ? cu : inset_pt(RP(R, RING0, n, j + 1), mid, inset_w);
			pos = aa_vertex(pv, cu, nx, first, last, first || tail, role, rim_w, a_line);
			col = vec4(P(R, 5).rgb, 0.55 * a_line);
		}
	} else if (layer == L_CRACK) {
		// GermVisual._draw_danger_cracks — membrandan içəri qırıq xətlər (3 nöqtə).
		int color_index = int(P(R, 11).y + 0.5);
		int count = 3 + color_index % 3;
		int c = idx / 3;
		int k = idx % 3;
		if (danger_on && c < count) {
			int ri = int(floor(float(c) * float(n) / float(count) + 0.5)) + 2;
			vec2 q = RP(R, RING0, n, ri % n);
			vec2 outer = mix(q, mid, 0.18);
			vec2 inn = mix(q, mid, 0.55);
			vec2 nrm = safe_norm(q - mid);
			vec2 side = vec2(-nrm.y, nrm.x);
			vec2 kink = mix(outer, inn, 0.48) + side * (r * (c % 2 == 0 ? 0.045 : -0.045));
			vec2 pts[3] = vec2[](outer, kink, inn);
			pos = aa_vertex(pts[max(k - 1, 0)], pts[k], pts[min(k + 1, 2)], k == 0, k == 2, true,
				role, max(1.2, r * 0.035), a_line);
			col = vec4(mix(c_danger, c_warning, 0.38), (0.42 + 0.48 * pulse) * a_line);
		}
	} else if (layer == L_BIRTH) {
		// GermVisual._draw_birth_ring — yerdə genişlənən halqa, draw_set_transform ilə
		// 0.62 ellipsə sıxılır (yumşaq kənar da daxil olmaqla).
		float bp = P(R, 10).y;
		if (bp < 1.0) {
			float radius = r * mix(0.45, 1.55, 1.0 - (1.0 - bp) * (1.0 - bp));
			vec2 lp = aa_vertex(arc_pt(radius, 0.0, TAU, 36, idx - 1), arc_pt(radius, 0.0, TAU, 36, idx),
				arc_pt(radius, 0.0, TAU, 36, idx + 1), false, false, false, role,
				max(1.4, r * 0.045), a_line);
			pos = -light_dir * (r * 0.22) + lp * vec2(1.0, 0.62);
			col = vec4(P(R, 5).rgb, 0.62 * (1.0 - bp) * a_line);
		}
	} else if (layer == L_SKELETON || layer == L_ALLY) {
		// Ayaqlının mineral skeleti (28 nöqtə) və yoldaş halqası (40 nöqtə) — qapalı qövslər.
		bool sk = layer == L_SKELETON;
		if (sk ? born : P(R, 10).w > 0.5) {
			float radius = sk ? r * 0.72 : r + shield_gap * 0.55;
			int count = sk ? 28 : 40;
			pos = aa_vertex(arc_pt(radius, 0.0, TAU, count, idx - 1), arc_pt(radius, 0.0, TAU, count, idx),
				arc_pt(radius, 0.0, TAU, count, idx + 1), false, false, false, role,
				sk ? 1.6 : 2.6, a_line);
			col = sk ? vec4(P(R, 5).rgb, 0.30 * a_line) : vec4(c_ally, 0.72 * a_line);
		}
	} else if (layer == L_SAFE) {
		// Doğuş qalxanı — fırlanan kəsik halqa (açıq qövs, 24 nöqtə).
		if (P(R, 10).z > 0.5) {
			float radius = r + shield_gap;
			float start = t * 2.0;
			float delta = PI * 1.4;
			pos = aa_vertex(arc_pt(radius, start, delta, 24, idx - 1), arc_pt(radius, start, delta, 24, idx),
				arc_pt(radius, start, delta, 24, idx + 1), idx == 0, idx == 23, true, role, 3.0, a_line);
			col = vec4(c_text, 0.55 * a_line);
		}

	// ---- hərəkət orqanları ----
	} else if (layer == L_CILIA) {
		// GermVisual._draw_cilia — perimetr boyu döyünən lentlər (6 nöqtəli çoxbucaqlı).
		int nc = clamp(int(r * 0.42), cilia_min, cilia_max);
		if (born && idx < nc) {
			float length_c = clamp(r * 0.26, 7.15, 13.0);
			float beat = cilia_beat * (0.55 + 0.9 * rush);
			float sweep = 0.35 + 0.55 * rush;
			float flow = heading + PI;
			float stretch = 1.0 + stretch_max * rush;
			float squash = 1.0 / stretch;
			vec2 axis = dirv(heading);
			vec2 side = vec2(-axis.y, axis.x);
			float root_half = max(r * 0.026, 0.85);
			float mid_half = root_half * 0.72;
			float tip_half = max(root_half * 0.28, 0.24);
			float a = TAU * float(idx) / float(nc);
			float phase = t * beat - a * cilia_waves;
			vec2 circle = dirv(a);
			vec2 outv = safe_norm(axis * (dot(circle, axis) / stretch) + side * (dot(circle, side) / squash));
			vec2 tangent = vec2(-outv.y, outv.x);
			vec2 b = circle * (r * 0.97);
			vec2 root = axis * (dot(b, axis) * stretch) + side * (dot(b, side) * squash);
			float bend = sin(phase) * sweep;
			float lean = 0.45 + 0.55 * (0.5 - 0.5 * cos(a - flow));
			vec2 midp = root + safe_norm(outv * 0.75 + tangent * bend) * (length_c * 0.55);
			vec2 tip = midp + safe_norm(outv * 0.35 + tangent * (bend * 1.6)) * (length_c * 0.65 * lean);
			vec2 first = midp - root;
			vec2 last = tip - midp;
			vec2 root_edge = safe_norm(vec2(-first.y, first.x));
			vec2 mid_axis = safe_norm(tip - root);
			vec2 mid_edge = vec2(-mid_axis.y, mid_axis.x);
			vec2 tip_edge = safe_norm(vec2(-last.y, last.x));
			if (role == 0) {
				pos = root - root_edge * root_half;
			} else if (role == 1) {
				pos = root + root_edge * root_half;
			} else if (role == 2) {
				pos = midp + mid_edge * mid_half;
			} else if (role == 3) {
				pos = tip + tip_edge * tip_half;
			} else if (role == 4) {
				pos = tip - tip_edge * tip_half;
			} else {
				pos = midp - mid_edge * mid_half;
			}
			col = vec4(mix(P(R, 5).rgb, c_body_light, 0.18), 0.85);
		}
	} else if (layer == L_TAIL_OUT || layer == L_TAIL_IN) {
		// GermVisual._draw_tail + _tapered_ribbon — qamçı (role 0 sol, 1 sağ kənar).
		if (born) {
			vec2 back = dirv(heading + PI);
			vec2 sidev = vec2(-back.y, back.x);
			float span = r * tail_length;
			float wave = 2.6 + 5.4 * rush;
			float amp = r * (0.13 + 0.16 * rush);
			int last_i = tail_points - 1;
			vec2 tp[3];
			for (int k = 0; k < 3; k++) {
				int j = clamp(idx - 1 + k, 0, last_i);
				float u = float(j) / float(last_i);
				float swing = sin(t * wave - u * 5.0) * amp * u;
				tp[k] = back * (r * 0.92 + span * u) + sidev * swing;
			}
			vec2 tangent = safe_norm(tp[2] - tp[0]);
			vec2 nrm = vec2(-tangent.y, tangent.x);
			float u = float(idx) / float(last_i);
			float wide = max(r * 0.10, 2.2);
			float half_w = layer == L_TAIL_OUT
				? mix(wide * 0.72, max(0.36, wide * 0.14), u)
				: mix(wide * 0.48, max(0.18, wide * 0.055), u);
			pos = tp[1] + nrm * (role == 0 ? half_w : -half_w);
			col = layer == L_TAIL_OUT
				? vec4(c_outline, 0.82)
				: vec4(P(R, 4).rgb, 0.60 - 0.20 * rush * rush);
		}
	} else if (layer == L_LEG_DARK || layer == L_LEG_COL || layer == L_LEG_TIP) {
		// GermVisual._draw_legs — ucların yeri CPU-nun addım vəziyyətindən gəlir
		// (sətirdə: uc.x, uc.y, basılıb, var). idx = ayaq × 2 + hissə.
		int leg = idx / 2;
		int part = idx % 2;
		vec4 lg = P(R, LEGS0 + leg);
		if (born && leg < int(P(R, 11).x + 0.5) && lg.w > 0.5) {
			vec2 tip = lg.xy;
			bool planted = lg.z > 0.5;
			vec3 light = P(R, 5).rgb;
			if (layer == L_LEG_TIP) {
				float rad = 0.0;
				if (planted) {
					rad = part == 0 ? max(r * 0.14, 4.6) : max(r * 0.065, 2.0);
					col = part == 0 ? vec4(c_outline, 0.78) : vec4(light, 0.82);
				} else if (part == 0) {
					rad = max(r * 0.06, 2.0);
					col = vec4(light, 0.45);
				}
				local = CORNER[role] * (rad > 0.0 ? rad + 1.5 : 0.0);
				pos = tip + local;
				shape.x = rad;
				kind = K_DISC;
			} else {
				vec2 root = safe_norm(tip) * (r * 0.94);
				vec2 side = safe_norm(vec2(-tip.y, tip.x));
				vec2 midp = mix(root, tip, 0.5) + side * (sin(t * 2.4 + float(leg) * 1.7) * r * leg_sway);
				vec2 a = part == 0 ? root : midp;
				vec2 b = part == 0 ? midp : tip;
				if (layer == L_LEG_DARK) {
					pos = line_vertex(a, b, max(r * 0.14, 5.4), role);
					col = vec4(c_outline, 0.90);
				} else {
					pos = line_vertex(a, b, max(r * 0.065, 2.4), role);
					float la = planted ? 0.88 : 0.40;
					col = vec4(light, part == 0 ? la : la * 0.7);
				}
			}
		}
	} else if (layer >= L_CYST_DISC && layer <= L_CYST_SEAM) {
		// GermVisual._draw_cyst — amöbün superi: bağlı qabıq. Həm solur, həm qapanır.
		float fade = P(R, 11).w;
		if (fade > 0.004) {
			float shell = r + shield_gap * 0.5 * fade;
			if (layer == L_CYST_DISC) {
				float rad = shell + 3.0;
				local = CORNER[role] * (rad + 1.5);
				pos = local;
				shape.x = rad;
				kind = K_DISC;
				col = vec4(c_outline, 0.55 * fade);
			} else if (layer == L_CYST_SHELL) {
				pos = aa_vertex(arc_pt(shell, 0.0, TAU, 40, idx - 1), arc_pt(shell, 0.0, TAU, 40, idx),
					arc_pt(shell, 0.0, TAU, 40, idx + 1), false, false, false, role, 10.0, a_line);
				col = vec4(mix(P(R, 6).rgb, c_text, 0.30), fade * a_line);
			} else if (layer == L_CYST_INNER) {
				float rad = shell - 6.0;
				pos = aa_vertex(arc_pt(rad, 0.0, TAU, 36, idx - 1), arc_pt(rad, 0.0, TAU, 36, idx),
					arc_pt(rad, 0.0, TAU, 36, idx + 1), false, false, false, role, 2.4, a_line);
				col = vec4(P(R, 5).rgb, 0.40 * fade * a_line);
			} else if (layer == L_CYST_GLINT) {
				// İşıq tərəfində açıq qövs (20 nöqtə).
				float rad = shell + 1.0;
				float start = atan(light_dir.y, light_dir.x) - 0.9;
				pos = aa_vertex(arc_pt(rad, start, 1.8, 20, idx - 1), arc_pt(rad, start, 1.8, 20, idx),
					arc_pt(rad, start, 1.8, 20, idx + 1), idx == 0, idx == 19, true, role, 3.0, a_line);
				col = vec4(c_text, 0.70 * fade * a_line);
			} else {
				// Qabığın səkkiz tikişi — antialiassız xətt.
				vec2 d = dirv(TAU * float(idx) / 8.0);
				pos = line_vertex(d * (shell - 6.0), d * (shell + 2.0), 3.0, role);
				col = vec4(c_outline, 0.7 * fade);
			}
		}
	} else if (layer >= L_NET_FILL && layer <= L_NET_TIP) {
		// GermVisual._draw_net — ayaqlının superi: aksopodiya toru. Şüalar yığılanda
		// geri çəkilir, sərhəd nəbz vurur.
		float fade = P(R, 11).w;
		if (fade > 0.004) {
			float reach = r * net_radius;
			float pulse = 0.5 + 0.5 * sin(t * 3.4);
			vec3 light = P(R, 5).rgb;
			if (layer == L_NET_FILL) {
				local = CORNER[role] * (reach + 1.5);
				pos = local;
				shape.x = reach;
				kind = K_DISC;
				col = vec4(light, 0.07 * fade);
			} else if (layer == L_NET_EDGE_DARK || layer == L_NET_EDGE) {
				bool dark = layer == L_NET_EDGE_DARK;
				pos = aa_vertex(arc_pt(reach, 0.0, TAU, 72, idx - 1), arc_pt(reach, 0.0, TAU, 72, idx),
					arc_pt(reach, 0.0, TAU, 72, idx + 1), false, false, false, role,
					dark ? 8.0 : 4.5, a_line);
				col = dark ? vec4(c_outline, 0.35 * fade * a_line)
					: vec4(light, (0.55 + 0.25 * pulse) * fade * a_line);
			} else if (layer == L_NET_INNER) {
				float rad = reach * 0.66;
				pos = aa_vertex(arc_pt(rad, 0.0, TAU, 56, idx - 1), arc_pt(rad, 0.0, TAU, 56, idx),
					arc_pt(rad, 0.0, TAU, 56, idx + 1), false, false, false, role, 2.2, a_line);
				col = vec4(light, (0.18 + 0.10 * pulse) * fade * a_line);
			} else {
				vec2 d = dirv(TAU * float(idx) / 16.0 + t * 0.20);
				float len = mix(r * 0.98, reach * (0.72 + 0.28 * sin(t * 2.2 + float(idx) * 1.3)), fade);
				if (layer == L_NET_RAY) {
					pos = line_vertex(d * (r * 0.98), d * len, 2.6, role);
					col = vec4(light, 0.62 * fade);
				} else {
					local = CORNER[role] * (3.8 + 1.5);
					pos = d * len + local;
					shape.x = 3.8;
					kind = K_DISC;
					col = vec4(c_text, 0.75 * fade);
				}
			}
		}
	} else if (layer == L_SPARK) {
		// GermVisual._draw_ready_sparks — hazır ultinin üç qığılcımı (hərəsi iki xətt).
		float fade = P(R, 8).w;
		if (fade > 0.004) {
			int s = idx / 2;
			float orbit = r + shield_gap * 0.55;
			vec2 at = dirv(t * 1.6 + TAU * float(s) / 3.0) * orbit;
			float sz = max(7.0, r * 0.30) * (0.65 + 0.35 * sin(t * 6.0 + float(s) * 2.1));
			vec2 dv = idx % 2 == 0 ? vec2(sz, 0.0) : vec2(0.0, sz);
			pos = line_vertex(at - dv, at + dv, max(3.0, r * 0.09), role);
			col = vec4(mix(c_super_ready, vec3(1.0), 0.3), fade);
		}
	}

	VERTEX = pos;
	COLOR = col * COLOR;
	v_local = local;
	v_shape = shape;
	v_kind = kind;
}

// Yumşaq kənar: bir ekran pikseli enində, ölçüdən asılı deyil (disk teksturası da
// mipmap ilə təxminən belə yumşalır).
float edge_alpha(float dist) {
	float w = max(fwidth(dist), 1e-4);
	return clamp(0.5 - dist / w, 0.0, 1.0);
}

void fragment() {
	vec4 c = COLOR;
	if (v_kind == K_DISC) {
		c.a *= edge_alpha(length(v_local) - v_shape.x);
	} else if (v_kind == K_STAR) {
		// GermVisual._star — 7 uclu ulduz (14 təpə, iç radius 0.5). Ulduz mərkəzə
		// görə ulduzvaridir: pikselin bucağı hansı iki təpə arasındadırsa, sərhəd
		// elə o kənardır.
		float size = v_shape.x;
		float turn = v_shape.y;
		float step_a = PI / 7.0;
		float k = floor((atan(v_local.y, v_local.x) - turn) / step_a);
		bool outer = mod(k, 2.0) < 0.5;
		vec2 q0 = dirv(k * step_a + turn) * (outer ? size : size * 0.5);
		vec2 q1 = dirv((k + 1.0) * step_a + turn) * (outer ? size * 0.5 : size);
		vec2 e = q1 - q0;
		// Müsbət = içəri (təpələr bucaq artdıqca düzülür).
		float inside = crs(e, v_local - q0) / max(length(e), 1e-4);
		c.a *= edge_alpha(-inside);
	} else if (v_kind == K_ELLIPSE) {
		vec2 q = v_local / max(v_shape.xy, vec2(1e-4));
		c.a *= edge_alpha((length(q) - 1.0) * min(v_shape.x, v_shape.y));
	} else if (v_kind == K_HALO) {
		// GermVisual._shared_halo_texture: 0 → 0.22, 0.52 → 0.08, 1 → 0.
		float d = length(v_local) / max(v_shape.x, 1e-4);
		c.a *= d < 0.52 ? mix(0.22, 0.08, d / 0.52) : mix(0.08, 0.0, clamp((d - 0.52) / 0.48, 0.0, 1.0));
	} else if (v_kind == K_AURA) {
		// GermVisual._shared_aura_texture: 0 → 0.70, 0.40 → 0.55, 0.62 → 0.20, 1 → 0.
		float d = length(v_local) / max(v_shape.x, 1e-4);
		float g;
		if (d < 0.40) {
			g = mix(0.70, 0.55, d / 0.40);
		} else if (d < 0.62) {
			g = mix(0.55, 0.20, (d - 0.40) / 0.22);
		} else {
			g = mix(0.20, 0.0, clamp((d - 0.62) / 0.38, 0.0, 1.0));
		}
		c.a *= g;
	}
	COLOR = c;
}
