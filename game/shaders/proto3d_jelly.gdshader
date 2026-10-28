// Kirpiklinin 3D prototipinin jel materialı (GL Compatibility-də işləyir).
// Yarışəffaf laym gövdə: kənarı (fresnel) parlaq, işıq yuxarı-soldan (DirectionalLight3D),
// içindəki nüvə və toplar görünür. Vəziyyət uniform-larla: dolu (tension) membranı dartır və
// kənarı parladır, aşağı ehtiyat (low) rəngi solğunlaşdırır, partlama həddi (danger) narıncı
// nəbz verir, zərbə (flash) bir anlıq ağ parıltıdır. Bax game/scripts/tools/germ3d.gd.
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert_wrap, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.70, 1.0, 0.42, 1.0);
uniform float alpha = 0.72;
uniform float tension = 0.0;
uniform float low = 0.0;
uniform float danger = 0.0;
uniform float flash = 0.0;

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	vec3 col = base_color.rgb * mix(1.0, 0.62, low);
	col = mix(col, vec3(1.0, 0.52, 0.30), danger * 0.55);
	ALBEDO = col;
	EMISSION = col * 0.62 + vec3(0.85, 1.0, 0.8) * fres * (0.30 + 0.55 * tension) + vec3(flash);
	ROUGHNESS = mix(0.38, 0.16, tension);
	SPECULAR = 0.55;
	ALPHA = clamp(mix(alpha, 0.96, fres) + flash * 0.3, 0.0, 1.0);
}
