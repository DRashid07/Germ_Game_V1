// Su zərrəcikləri GPU-da (bax scripts/client/water_motes.gd).
//
// Hər zərrəcik GDScript yolundakı kimi hər kadr axın sahəsi ilə Eyler addımı atır
// (Const.current_at + Broun titrəməsi), kameranın kvadratından çıxanda əks kənara
// keçir. Vəziyyət (mövqe, toxum) CUSTOM-dadır; TRANSFORM isə çəkiliş üçündür:
// 1×1 tekstura zərrəcikdən cizginin quyruğuna qədər uzanan, `line_width` enli
// düzbucaqlıya çevrilir — draw_multiline-ın qalın xəttinin eyni dörd küncü.
shader_type particles;
render_mode disable_force, disable_velocity, keep_data;

// Const-dan (bax WaterMotes._sync_constants) — formul bir yerdədir.
uniform float world_radius;
uniform float current_edge;
uniform float current_scale;
uniform float current_strength;
uniform float current_swirl;

uniform vec2 focus;
uniform float half_size;
uniform float depth;
// fposmod(_flow_t * 0.4, TAU) — GDScript yolundakı titrəmənin fazası.
uniform float jitter_phase;
// Bu kadrın addımı — `_process(delta)`-in ÖZÜ. Hissəcik sisteminin öz DELTA-sı render
// tərəfində ayrıca hesablanır və dəyişkən kadrlarda (brauzer, telefon) bir-iki kadrlıq
// fərqlə gəlirdi: iki yol eyni qanunla, amma fərqli vaxtla gedirdi.
uniform float step_dt;
uniform float streak;
uniform float line_width;
uniform vec4 mote_color : source_color;
// Yenidən səpəndə (WaterMotes.rebuild) dəyişir — yeni təsadüfi düzüm.
uniform uint seed;

const float TAU_F = 6.28318530718;

// Const.current_at — sətir-sətir eynidir.
vec2 current_at(vec2 pos) {
	float d = length(pos);
	float q = d / world_radius;
	float u = clamp((1.0 - q) / (1.0 - current_edge), 0.0, 1.0);
	if (u <= 0.0) {
		return vec2(0.0);
	}
	float fade = u * u * (3.0 - 2.0 * u);
	float k = TAU_F / current_scale;
	float sx = sin(pos.x * k);
	float cx = cos(pos.x * k);
	float sy = sin(pos.y * k);
	float cy = cos(pos.y * k);
	vec2 flow = vec2(sx * cy, -cx * sy) * (current_strength * fade);
	if (d > 1.0) {
		vec2 n = pos / d;
		float d_fade = 6.0 * u * (1.0 - u) / ((current_edge - 1.0) * world_radius);
		flow += vec2(n.y, -n.x) * (d_fade * (current_strength / k) * sx * sy);
		flow += vec2(-n.y, n.x) * (current_swirl * sin(3.14159265359 * q) * fade);
	}
	return flow;
}

// 0..1 — PCG heşi (zərrəciyin indeksi + toxum).
float rand01(uint x) {
	uint s = x * 747796405u + 2891336453u;
	uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
	w = (w >> 22u) ^ w;
	return float(w) / 4294967295.0;
}

// Cizginin düzbucaqlısı: p-dən p − tail-ə qədər; en istiqaməti Godot-un qalın
// xəttindəki kimi (b − a)-nın perpendikulyarıdır.
mat4 place(vec2 p) {
	vec2 tail = current_at(p) * streak;
	if (dot(tail, tail) < 0.25) {
		tail = vec2(0.9, 0.0);
	}
	vec2 along = -tail;
	vec2 across = normalize(vec2(-along.y, along.x)) * line_width;
	return mat4(vec4(along, 0.0, 0.0), vec4(across, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0), vec4(p + along * 0.5, 0.0, 1.0));
}

void start() {
	uint base = INDEX * 3u + seed * 7919u;
	vec2 r = vec2(rand01(base), rand01(base + 1u)) * 2.0 - 1.0;
	vec2 p = focus + r * half_size;
	CUSTOM = vec4(rand01(base + 2u) * TAU_F, p, 0.0);
	TRANSFORM = place(p);
	COLOR = mote_color;
}

void process() {
	vec2 p = CUSTOM.yz;
	float a = CUSTOM.x + jitter_phase;
	vec2 jitter = vec2(cos(a), sin(a)) * 6.0;
	p += (current_at(p) * (1.0 - 0.42 * depth) + jitter) * step_dt;
	vec2 d = p - focus;
	if (abs(d.x) > half_size) {
		p.x -= sign(d.x) * half_size * 2.0;
	}
	if (abs(d.y) > half_size) {
		p.y -= sign(d.y) * half_size * 2.0;
	}
	CUSTOM.yz = p;
	TRANSFORM = place(p);
	COLOR = mote_color;
}
