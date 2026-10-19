// Qabın DÖŞƏMƏSİ — makro ton × tikişsiz detal, BİR keçiddə (bax
// scripts/client/arena.gd `_floor`, design/MAP_25D.md §7, critique B6).
//
// Makro (1024², bütün qab) yumşaq zonaları, kənarın qaralmasını və sediment
// zolaqlarını daşıyır; bir teksteli 2.34 dünya px-dir, yəni yaxından bulanıqdır.
// Detal (400 dünya px-lik kafel) agar dənəsini, mikro baloncuq halqalarını və
// lifləri verir — kəskinlik ondan gəlir.
//
// Niyə şeyder, iki sprite yox: detal ORTA 0.5 boz kimi çəkilib. Adi MUL
// qarışdırma döşəməni yarıya qədər qaraldardı; MUL üçün ayrıca 0.90–1.00-ə
// sıxılmış nüsxə isə yalnız qaraldır, işıq dənəsi verə bilmir. Burada detal
// ±12% ətrafında həm açır, həm qaraldır, və bu, ikinci tam ekran keçidi
// olmadan, bir çəkiliş çağırışıdır.
shader_type canvas_item;

uniform sampler2D detail : filter_linear_mipmap, repeat_enable;
// Bir kafel neçə dünya px-dir (manifestin `detail_world`-ü).
uniform float detail_world = 400.0;
// Detalın gücü: 1.0 → makro × (1 ± 0.12).
uniform float strength = 1.0;

varying vec2 world_pos;

void vertex() {
	// Node qabın mərkəzindədir və fırlanmır — lokal koordinat dünya koordinatıdır.
	world_pos = VERTEX;
}

void fragment() {
	// COLOR burada artıq makro teksturanın rəngidir (× modulate).
	float d = texture(detail, world_pos / detail_world).r;
	COLOR.rgb *= 1.0 + strength * (d - 0.5) * 2.0;
}
