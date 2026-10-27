// YAŞ ADA-nın quru qabı (bax scripts/client/arena.gd `_build_island`).
//
// Qabın üstünə çatlamış palçıq çəkilir, adanın dairəsi isə kəsilib boş qalır — orada
// adi yaş döşəmə görünür. Ada hər kadr yerini dəyişir (matçın saatından), ona görə
// kəsik şeyderdədir: palçıq ayrıca halqa mesh-i olsaydı, hər kadr yenidən qurulardı.
// Palçıq kafeli tikişsizdir və dünya koordinatı ilə təkrarlanır — ada sürüşəndə
// palçıq yerində qalır, yalnız kəsik hərəkət edir.
shader_type canvas_item;

uniform sampler2D mud : source_color, filter_linear_mipmap, repeat_enable;
// Bir kafel neçə dünya px-dir.
uniform float tile = 420.0;
uniform vec2 center = vec2(0.0);
uniform float radius = 720.0;
uniform float wall = 720.0;
// 0 — qab yaşdır, 1 — tam quruyub (0:20–0:25 arasında artır).
uniform float amount = 0.0;

varying vec2 world_pos;

void vertex() {
	// Node qabın mərkəzindədir və fırlanmır — lokal koordinat dünya koordinatıdır.
	world_pos = VERTEX;
}

void fragment() {
	float d = distance(world_pos, center);
	float dry = smoothstep(radius - 4.0, radius + 26.0, d) * amount;
	// Şüşədən kənarda heç nə çəkilmir — qabın bayırı öz fonundadır.
	float glass = 1.0 - smoothstep(wall - 3.0, wall, length(world_pos));
	vec3 m = texture(mud, world_pos / tile).rgb;
	// Adanın kənarında palçıq hələ nəmdir — bir az tünd zolaq suyun çəkildiyini deyir.
	float damp = 1.0 - 0.28 * (1.0 - smoothstep(radius, radius + 90.0, d));
	COLOR = vec4(m * damp, dry * glass);
}
