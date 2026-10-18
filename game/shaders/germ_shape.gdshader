// Mikrobun KONTURU — GPU-da, kadrda bir dəfə (bax scripts/client/germ_gpu.gd,
// design/PERF_PLAN.md F1-B).
//
// Kiçik RGBA8 render hədəfidir: hər sətir bir mikrob, hər texel bir nəticə:
//   0..43   son kontur (membran + atəş dartılması + hadisə + toqquşma ellipsi),
//   44..87  kölgənin konturu (hadisəsiz forma),
//   88      son konturun mərkəzi, 89 kölgə konturunun mərkəzi.
// Koordinat 16 bitlik sabit nöqtə ədədidir (±256 px, 1/128 px addım), iki bayta
// bölünür — RGBA8 hər GPU-da render hədəfi ola bilir, float isə yox (ANGLE-də
// "HDR" hədəf də 8 bitlik çıxır).
//
// Riyaziyyat GermVisual-ın GDScript yolunun bir-bir surətidir: _membrane,
// _crawl_body (+ _smooth_ring, sahənin qorunması, kökün sabitlənməsi), _fit_hit,
// _strain, _event_deform. Nöqtədən asılı OLMAYAN ədədləri CPU eyni funksiyalardan
// hesablayıb sətrə yazır (_membrane_args, _crawl_scalars, _event_params) — qayda
// bir yerdədir. Hər fragment konturun hamısını qurur, çünki mərhələlər arasında
// mərkəz və sahə lazımdır; kontur 24–44 nöqtədir, yəni bu ucuzdur.
shader_type canvas_item;
render_mode blend_disabled, unshaded;

uniform sampler2D data : filter_nearest, repeat_disable;
// Hədəfin ölçüsü: (sütun sayı, sətir sayı).
uniform vec2 grid;
uniform float hit_knee;
uniform float eject_half;
uniform float crawl_lobe;
uniform float uroid_bulge;
uniform float crawl_waves;
uniform float crawl_aim_bulge;
uniform float crawl_area;
uniform float crawl_anchor;
uniform int crawl_smooth;

const int MAXN = 44;
const int COL_SHADOW = 44;
const int COL_MID = 88;
const int COL_SMID = 89;
// Sabit nöqtə: (p + RANGE) · STEPS, 16 bit.
const float RANGE = 256.0;
const float STEPS = 128.0;

vec4 P(int rw, int k) {
	return texelFetch(data, ivec2(k, rw), 0);
}

vec4 encode(vec2 p) {
	vec2 q = clamp(floor((p + RANGE) * STEPS + 0.5), 0.0, 65535.0);
	vec2 hi = floor(q / 256.0);
	vec2 lo = q - hi * 256.0;
	return vec4(hi.x, lo.x, hi.y, lo.y) / 255.0;
}

float crs(vec2 a, vec2 b) {
	return a.x * b.y - a.y * b.x;
}

// GermVisual._reach — sıfırdan `dir` boyunca şüanın diskdən çıxma məsafəsi.
float reach(vec2 dir, vec2 centre, float radius) {
	float b = dot(dir, centre);
	float h = radius * radius - (dot(centre, centre) - b * b);
	return h > 0.0 ? b + sqrt(h) : 0.0;
}

// GDScript wrapf(x, -PI, PI).
float wrap_pi(float x) {
	return x - TAU * floor((x + PI) / TAU);
}

void fragment() {
	int col = int(floor(UV.x * grid.x));
	int R = int(floor(UV.y * grid.y));
	vec4 p0 = P(R, 0);
	float r = p0.x;
	vec4 p2 = P(R, 2);
	int n = clamp(int(p2.x + 0.5), 3, MAXN);
	bool shadow = (col >= COL_SHADOW && col < COL_MID) || col == COL_SMID;
	int k = shadow ? col - COL_SHADOW : col;
	// Boş sətir və ya istifadə olunmayan sütun.
	if (r <= 0.0 || (col < COL_MID && k >= n)) {
		COLOR = encode(vec2(0.0));
	} else {
		float heading = p0.w;
		vec4 p3 = P(R, 3);
		float aim = p3.z;
		bool amoeba = p3.w > 1.5;
		vec4 p15 = P(R, 15);
		float stretch = shadow ? p15.w : p15.z;
		vec2 axis = vec2(cos(heading), sin(heading));
		vec2 side = vec2(-axis.y, axis.x);
		vec2 pts[44];

		if (amoeba) {
			// ---- GermVisual._crawl_body ----
			vec4 a16 = P(R, 16);
			vec4 a17 = P(R, 17);
			vec4 a18 = P(R, 18);
			vec4 a19 = P(R, 19);
			float rays[44];
			for (int i = 0; i < n; i++) {
				float a = TAU * float(i) / float(n);
				vec2 d = vec2(cos(a), sin(a));
				rays[i] = max(reach(d, vec2(0.0), a17.y),
					max(reach(d, a16.xy, a17.x), reach(d, a16.zw, a17.z)));
			}
			// _smooth_ring(rays, CRAWL_SMOOTH): hər keçid [0.25 0.5 0.25].
			float tmp[44];
			for (int pass = 0; pass < crawl_smooth; pass++) {
				for (int i = 0; i < n; i++) {
					tmp[i] = rays[(i + n - 1) % n] * 0.25 + rays[i] * 0.5 + rays[(i + 1) % n] * 0.25;
				}
				for (int i = 0; i < n; i++) {
					rays[i] = tmp[i];
				}
			}
			float squash = 1.0 / stretch;
			for (int i = 0; i < n; i++) {
				float a = TAU * float(i) / float(n);
				float m = 1.0 + crawl_lobe * sin(a * 3.0 + a18.x)
					+ crawl_lobe * 0.20 * sin(a * 5.0 - a18.y);
				float cd = a - heading;
				m += a19.y * cos(cd) * sin(cd) * sin(cd);
				float rear = max(cos(a - heading - PI), 0.0);
				m += uroid_bulge * mix(0.50, 1.0, clamp(a17.w, 0.0, 1.0)) * pow(rear, 6.0);
				float u = abs(wrap_pi(a - heading));
				m += a18.w * (0.30 + 0.70 * sin(u)) * (sin(u * crawl_waves + a18.z) - a19.x);
				float tt = max(cos(a - aim), 0.0);
				m += crawl_aim_bulge * tt * tt * tt * tt;
				vec2 v = vec2(cos(a), sin(a)) * (rays[i] * m);
				pts[i] = axis * (dot(v, axis) * stretch) + side * (dot(v, side) * squash);
			}
			// Sahə dəqiq qorunur, sonra kök sabitlənir (mərkəz miqyasla dəyişmir).
			float a2 = 0.0;
			vec2 acc = vec2(0.0);
			for (int i = 0; i < n; i++) {
				vec2 a = pts[i];
				vec2 b = pts[(i + 1) % n];
				float c = a.x * b.y - b.x * a.y;
				a2 += c;
				acc += (a + b) * c;
			}
			vec2 mid = abs(a2) < 0.0001 ? vec2(0.0) : acc / (3.0 * a2);
			float have = abs(a2) * 0.5;
			if (have > 0.001) {
				float kk = sqrt(PI * r * r * crawl_area / have);
				for (int i = 0; i < n; i++) {
					pts[i] = mid + (pts[i] - mid) * kk;
				}
			}
			vec2 drift = mid * crawl_anchor;
			for (int i = 0; i < n; i++) {
				pts[i] -= drift;
			}
		} else {
			// ---- GermVisual._membrane ----
			vec4 m16 = P(R, 16);
			float squash = 1.0 / stretch;
			for (int i = 0; i < n; i++) {
				float a = TAU * float(i) / float(n);
				float m = 1.0 + m16.x * sin(m16.y + a * 3.0) + m16.x * 0.6 * sin(m16.z + a * 5.0);
				if (m16.w > 0.0) {
					float tt = max(cos(a - aim), 0.0);
					m += m16.w * tt * tt * tt * tt;
				}
				vec2 v = vec2(cos(a), sin(a)) * r * m;
				pts[i] = axis * (dot(v, axis) * stretch) + side * (dot(v, side) * squash);
			}
		}

		// ---- GermVisual._fit_hit (forma) ----
		vec4 p11 = P(R, 11);
		bool fit = p11.z > 0.5;
		vec4 p12 = P(R, 12);
		vec2 inv = vec2(1.0 / max(p12.x, 0.001), 1.0 / max(p12.y, 0.001));
		float fc = cos(-p12.z);
		float fs = sin(-p12.z);
		float soft = 1.0 - hit_knee;
		if (fit) {
			for (int i = 0; i < n; i++) {
				vec2 p = pts[i];
				float q = length(vec2(p.x * fc - p.y * fs, p.x * fs + p.y * fc) * inv);
				if (q > hit_knee) {
					pts[i] = p * ((hit_knee + soft * tanh((q - hit_knee) / soft)) / q);
				}
			}
		}

		if (!shadow) {
			// ---- GermVisual._strain — top membranı yarır ----
			float push = p12.w;
			if (push != 0.0) {
				float ej = P(R, 9).z;
				vec2 ax = vec2(cos(ej), sin(ej));
				float a2 = 0.0;
				vec2 acc = vec2(0.0);
				for (int i = 0; i < n; i++) {
					vec2 a = pts[i];
					vec2 b = pts[(i + 1) % n];
					float c = a.x * b.y - b.x * a.y;
					a2 += c;
					acc += (a + b) * c;
				}
				vec2 mid = abs(a2) < 0.0001 ? vec2(0.0) : acc / (3.0 * a2);
				for (int i = 0; i < n; i++) {
					vec2 v = pts[i] - mid;
					if (dot(v, ax) > 0.0) {
						float kk = clamp(1.0 - abs(crs(v, ax)) / eject_half, 0.0, 1.0);
						pts[i] += ax * (push * kk * kk * (3.0 - 2.0 * kk));
					}
				}
			}

			// ---- GermVisual._event_deform ----
			vec4 p13 = P(R, 13);
			vec4 p14 = P(R, 14);
			bool axis_on = p13.x != 0.0 || p13.y != 0.0;
			bool uniform_on = p14.z != 1.0 || p14.w != 0.0;
			if (axis_on || uniform_on) {
				float a2 = 0.0;
				vec2 acc = vec2(0.0);
				for (int i = 0; i < n; i++) {
					vec2 a = pts[i];
					vec2 b = pts[(i + 1) % n];
					float c = a.x * b.y - b.x * a.y;
					a2 += c;
					acc += (a + b) * c;
				}
				vec2 mid = abs(a2) < 0.0001 ? vec2(0.0) : acc / (3.0 * a2);
				if (axis_on) {
					vec2 f = normalize(p13.xy);
					vec2 s = vec2(-f.y, f.x);
					for (int i = 0; i < n; i++) {
						vec2 v = pts[i] - mid;
						pts[i] = mid + f * (dot(v, f) * p13.z) + s * (dot(v, s) * p13.w) + p14.xy;
					}
					// Affin çevirmə mərkəzi də özü ilə aparır.
					mid += p14.xy;
				}
				if (uniform_on) {
					float uc = cos(p14.w);
					float us = sin(p14.w);
					for (int i = 0; i < n; i++) {
						vec2 v = pts[i] - mid;
						pts[i] = mid + vec2(v.x * uc - v.y * us, v.x * us + v.y * uc) * p14.z;
					}
				}
			}
			vec2 jitter = p15.xy;
			for (int i = 0; i < n; i++) {
				pts[i] += jitter;
			}

			// ---- GermVisual._fit_hit (son kontur) ----
			if (fit) {
				for (int i = 0; i < n; i++) {
					vec2 p = pts[i];
					float q = length(vec2(p.x * fc - p.y * fs, p.x * fs + p.y * fc) * inv);
					if (q > hit_knee) {
						pts[i] = p * ((hit_knee + soft * tanh((q - hit_knee) / soft)) / q);
					}
				}
			}
		}

		if (col == COL_MID || col == COL_SMID) {
			// GermVisual._ring_centre.
			float a2 = 0.0;
			vec2 acc = vec2(0.0);
			for (int i = 0; i < n; i++) {
				vec2 a = pts[i];
				vec2 b = pts[(i + 1) % n];
				float c = a.x * b.y - b.x * a.y;
				a2 += c;
				acc += (a + b) * c;
			}
			COLOR = encode(abs(a2) < 0.0001 ? vec2(0.0) : acc / (3.0 * a2));
		} else {
			COLOR = encode(pts[k]);
		}
	}
}
