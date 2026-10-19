// Superin açılış effekti GPU-da (bax scripts/client/super_fx.gd).
//
// GDScript yolu hər kadr disk, iynələr, iki antialias-lı halqa, lövhələr və
// parıltı çəkirdi; burada mesh sabitdir (təpələrdə kod: VERTEX = qat, indeks,
// UV.x = rol) və hər şey vaxtdan (`age`) hesablanır. Həndəsə Godot-un öz
// həndəsəsidir: draw_circle — 64 seqmentli yelpik, draw_multiline — seqment
// başına canvas_item_add_line dördbucaqlısı, draw_arc — antialias-lı polyline
// (mikrob shader-indəki kimi qapalı halqa, açıq polyline-ın tikişi olmadan).
shader_type canvas_item;

const int L_DISC = 1;
const int L_NEEDLE = 2;
const int L_RING_DARK = 3;
const int L_RING = 4;
const int L_PLATE = 5;
const int L_FLASH = 6;

const int CILIATE = 0;
const int HELIOZOAN = 1;
const int AMOEBA = 2;

// draw_circle və draw_arc-ın nöqtə sayları — super_fx.gd ilə eyni.
const int CIRCLE_SEGMENTS = 64;
const int RING_POINTS = 64;

// Godot-un FEATHER_SIZE-ı.
const float FEATHER = 1.25;

// Effektin özü — hər nüsxənin öz materialı var (SuperFx.setup).
uniform float age;
uniform int species;
uniform vec3 fx_color;
uniform float body;
uniform float reach;
uniform int needles;
uniform float turn;

// SuperFx və Palette sabitləri — bir yerdən gəlir (SuperFx._template).
uniform float lifetime;
uniform float wave_time;
uniform float needle_time;
uniform float snap_time;
uniform int plates;
uniform vec3 c_outline;
uniform vec3 c_text;

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

vec2 safe_norm(vec2 v) {
	float l = length(v);
	return l > 1e-12 ? v / l : vec2(0.0);
}

// SuperFx._ease_out.
float ease_out(float p) {
	float q = 1.0 - clamp(p, 0.0, 1.0);
	return 1.0 - q * q * q;
}

// draw_arc-ın i-ci nöqtəsi (CanvasItem::draw_arc ilə eyni ifadə).
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

// Qapalı antialias-lı polyline-ın bir təpəsi (germ.gdshader-dəki aa_vertex-in
// qapaqsız hissəsi). Rollar: 0 = cur + e, 1 = cur − e (özək), 2 = cur + e + B,
// 3 = cur − e − B (yumşaq kənarlar, şəffaf).
vec2 aa_loop_vertex(vec2 prev, vec2 cur, vec2 next, int role, float width, out float alpha) {
	float w2 = aa_width(width);
	float border = FEATHER * (w2 < 1.0 ? w2 : 1.0);
	vec2 base = miter(safe_norm(next - cur), safe_norm(cur - prev));
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
	return cur - e - b;
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

// canvas_item_add_ellipse-in i-ci nöqtəsi (yelpik: rol 0 mərkəz, rol 1 kənar).
vec2 circle_pt(float radius, int role, int i) {
	if (role == 0) {
		return vec2(0.0);
	}
	float angle = float(i) * (TAU / float(CIRCLE_SEGMENTS));
	return vec2(cos(angle), sin(angle)) * radius;
}

void vertex() {
	int layer = int(VERTEX.x + 0.5);
	int idx = int(VERTEX.y + 0.5);
	int role = int(UV.x + 0.5);

	float u = clamp(age / lifetime, 0.0, 1.0);
	// SuperFx._fade.
	float a = 1.0 - smoothstep(0.38, 1.0, u);

	// Halqa: kirpiklidə dalğa, ayaqlıda torun açılışı, amöbdə içəri çırpılan qabıq.
	float p;
	float ring;
	float w;
	float lighten;
	float dark_a;
	if (species == HELIOZOAN) {
		p = ease_out(age / (wave_time * 1.2));
		ring = mix(body, reach, p);
		w = mix(9.0, 3.0, p);
		lighten = 0.55;
		dark_a = 0.40;
	} else if (species == AMOEBA) {
		p = ease_out(age / snap_time);
		ring = mix(body * 2.3, reach, p);
		w = mix(3.0, 9.0, p);
		lighten = 0.45;
		dark_a = 0.45;
	} else {
		p = ease_out(age / wave_time);
		ring = mix(body, reach, p);
		w = mix(10.0, 3.5, p);
		lighten = 0.55;
		dark_a = 0.45;
	}

	vec2 pos = vec2(0.0);
	vec4 col = vec4(0.0);
	if (layer == L_DISC) {
		pos = circle_pt(ring, role, idx);
		col = vec4(fx_color, (species == CILIATE ? 0.20 : 0.12) * a);
	} else if (layer == L_NEEDLE) {
		// İki seqment iynə başına: rəngli gövdə və ağ uc.
		int i = idx / 2;
		if (i < needles) {
			float tip_r = mix(body, reach * 0.94, ease_out(age / needle_time));
			float length_n = mix(body * 0.55, body * 0.30, u);
			vec2 dir = dirv(turn + TAU * float(i) / float(needles));
			float k = i % 2 == 0 ? 1.0 : 0.78;
			vec2 tip = dir * (tip_r * k);
			vec2 mid = tip - dir * (length_n * 0.35);
			vec2 tail = tip - dir * length_n;
			float width = max(2.5, body * 0.09);
			if (idx % 2 == 0) {
				pos = line_vertex(tail, mid, width, role);
				col = vec4(mix(fx_color, vec3(1.0), 0.35), 0.95 * a);
			} else {
				pos = line_vertex(mid, tip, width, role);
				col = vec4(c_text, a);
			}
		}
	} else if (layer == L_RING_DARK || layer == L_RING) {
		bool dark = layer == L_RING_DARK;
		float a_line = 1.0;
		pos = aa_loop_vertex(arc_pt(ring, 0.0, TAU, RING_POINTS, idx - 1),
			arc_pt(ring, 0.0, TAU, RING_POINTS, idx), arc_pt(ring, 0.0, TAU, RING_POINTS, idx + 1),
			role, dark ? w + 5.0 : w, a_line);
		col = dark ? vec4(c_outline, dark_a * a * a_line)
			: vec4(mix(fx_color, vec3(1.0), lighten), a * a_line);
	} else if (layer == L_PLATE) {
		// Lövhə qırıntıları qabığa doğru çəkilir və onunla birləşir.
		float half_span = TAU / float(plates) * 0.28;
		float from = ring + mix(body * 0.9, 0.0, p);
		float ang = turn + TAU * float(idx) / float(plates);
		pos = line_vertex(dirv(ang - half_span) * from, dirv(ang + half_span) * from,
			max(3.0, body * 0.10), role);
		col = vec4(c_text, 0.85 * a);
	} else if (layer == L_FLASH) {
		// Gövdənin üstündə ani ağ parıltı — ilk 0.2 saniyə.
		float k = 1.0 - clamp(age / 0.2, 0.0, 1.0);
		if (k > 0.0) {
			pos = circle_pt(body * (1.0 + 0.35 * (1.0 - k)), role, idx);
			col = vec4(c_text, 0.65 * k * k);
		}
	}
	VERTEX = pos;
	COLOR = col * COLOR;
}
