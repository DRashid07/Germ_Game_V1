> Codex-in öz hesabatlarıdır (gpt-6-astra, reasoning effort `max`). Brif: [BRIEF_MAP_V1.md](BRIEF_MAP_V1.md), xam fayllar: [../raw/v1/](../raw/v1/).
>
> V1 iki işdə çəkilib. **1-ci iş** (20:10) lövbər damlanın 3 cəhdinin üçünü də rədd edib dayandı — qayda "mərkəz alfası 255" idi, gel 253 verir. Claude try2-ni lövbər kimi təsdiqlədi (cənub bandı ~120 px, hədəf 76 — qəbul). **2-ci iş** (20:23, davam brifi) slot 2-dən başladı və 7-ci slotdan sonra Codex limitinə düşdü (bərpa: 3 oktyabr 01:10). Kolun tacı (slot 8) Codex-in try1-idir: gözəl, amma ~1.2× böyük (bbox 56..978) — pipeline 0.83 kiçildəcək; Claude onu final kimi qəbul etdi. Qalan: vent_base, floor_macro, rim_north, clutter.
>
> Kənarlaşmalar: bloom bir az kiçik (r ~350, pipeline dairəyə oturdur) və parlaq (p99 0.68); brittle qabığı brifdən tünddür (kömür rəngi, "soyuyan lava daşı" kimi), s0 közü 1.4% (hədəf ≤ 1%), s1 kəhrəbası 6.3% (hədəf 7–10%), s2 közü 8.6% (hədəf 3–5%) — üç mərhələ uzaqdan aydın seçilir; bush_base p99 0.65.

## 1-ci iş — lövbər

# V1 Damla / Droplet — Aqar

Built-in `image_gen` production log. Rules: `../STYLE_MAP.md` and the supplied V1 brief. Reference guides are measurement-only; concept images are style-only. Acceptance is based on visual inspection and the supplied `verify.ps1`, including each slot's gate.

Outputs are generated one at a time in brief order. Untouched generated files and unsuccessful attempts are retained under `rejected/`. Pipeline operations follow the supplied rules: proportional resizing, stage-0 alpha replacement, and flat colour-key extraction when the transparency fallback is necessary.

## 1. map_v1_mucus_blob.png

### Call 1 — generation

References: `ref/template_v1.png`, `ref/mockup_crop_v1.png`. `transparent_background: true`.

```text
Use case: stylized-concept.
Asset type: one isolated production environment sprite, MUCUS variant A, kit anchor.
Input images, in order: (1) ref/template_v1.png = measurement guide; reproduce none of its lines, colours or arrow. (2) ref/mockup_crop_v1.png = style reference only; do not copy the scene.
Canvas: exactly 1024x1024 RGBA PNG with real transparency. No backdrop.
Primary request: a smooth glossy dark teal gel droplet dome. Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows
ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom
centre, thinning to nothing at the left, right and top. Nothing rises above the footprint
circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens
toward the lower-right; optional hairline rim light on the lower-right edge.
Registration is critical: the outer silhouette is the exact circle centred (512,512), radius 384, extent x=128..896 and y=128..896. The continuous dark #081A20 outline is about 13 px wide and stays on that circle. The cap is the circle centred (512,474), radius 346: its top meets the outer top at y=128; its bottom ends at y=820. The south band occupies the crescent between cap and footprint, 76 px at bottom centre and about 38 px at the widest side positions; it never becomes a protruding pedestal. No part of the object may go above y=128 or below y=896.
Material: smooth translucent-looking dense gel, but the sprite itself is fully opaque inside its silhouette. Top #37666F, body #26494F, south band #142C32 darkest lower-right. One broad soft elongated specular highlight on the upper-left of the cap, muted #5A8C93, restrained to at most 1% of object area. No additional gleam rings. No granules or spots. Large simple readable shapes for display at 64px.
Brightness: body channels never above 148/255; the single specular may reach at most 158/255. Remain refined, dark, low contrast.
No text, letters, numbers, logos, symbols, watermarks or signatures. No anatomy or anthropomorphic arrangement; no two similar spots side by side. No people, hands, lab equipment, metal, chrome, machinery or hard geometric corners. Organic soft forms. Never a filled pale or saturated round dot or ball. No background pattern or checkerboard. No cast shadow, ground, glow or haze outside the silhouette. Do not reproduce guide lines, guide colours, hatching, crosses or arrows.
One image only, no layouts or alternatives.
```

Call 1 rejected: p99_noamber 0.769 exceeds 0.62, centre alpha 253 fails full opacity, and the bottom band is visibly too deep. Untouched source and resized candidate preserved under `rejected/`.

Untouched verify: `size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.446 bbox=152,149,1101,1096 p99_max=0.773 spread=94 key_px=0 checker=0.000 p99_any=0.773 p99_noamber=0.773 amber=0.0000 amber_glow=0.0000 spread8=94`.

Candidate verify: `size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.446 bbox=124,122,899,895 p99_max=0.769 spread=96 key_px=0 checker=0.000 p99_any=0.769 p99_noamber=0.769 amber=0.0000 amber_glow=0.0000 spread8=96`.

### Call 2 — palette, geometry, opacity edit

References: `ref/template_v1.png`, `out/rejected/map_v1_mucus_blob_try1.png`. `transparent_background: true`.

```text
Use case: precise-object-edit.
Asset: one isolated dark-teal agar droplet sprite, 1024x1024 RGBA PNG.
Input images in order: (1) ref/template_v1.png = measurement guide; reproduce none of its lines, colours or arrow. (2) out/rejected/map_v1_mucus_blob_try1.png = edit target. Correct this target precisely as below; retain its smooth simple gel material and single upper-left elongated reflection.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows
ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom
centre, thinning to nothing at the left, right and top. Nothing rises above the footprint
circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens
toward the lower-right; optional hairline rim light on the lower-right edge.
Make three corrections:
1. Darken and desaturate all material to the exact restrained palette: most of the cap #37666F, shaded body #26494F, south band #142C32, continuous 13px outline #081A20. One subdued elongated upper-left reflection #5A8C93, at most 1% of painted area. Highest RGB channel anywhere in this non-emissive sprite is 147/255. No pale, white, silver, cyan or bright reflection. No bright rim. The cap should be about #37666F, not a luminous turquoise gradient.
2. Match the measurement guide exactly: the outer silhouette MUST be the perfect circle centred (512,512) radius 384; the cap MUST be the perfect circle centred (512,474) radius 346. Cap bottom at y820, outline bottom at y896: only 76px band depth at bottom centre. The previous band's depth was about 120px: reduce it. Do not create an oval. Nothing beyond the outer circle.
3. The painted object, including the entire cap and its exact centre (512,512), MUST have alpha 255. Use dense opaque gel, with all transparency strictly outside its silhouette; only the boundary has antialiasing. Preserve the empty transparent background.
No granules or spots. No extra rings or lines. Premium chunky mobile arena game art, soft 3D cel shading, thick clean outline.
No text, letters, numbers, logos, symbols, watermarks or signatures. No anatomy or anthropomorphic arrangement; no two similar spots side by side. No people, hands, lab equipment, metal, chrome, machinery or hard geometric corners. Organic soft forms. Never a filled pale or saturated round dot or ball. No background pattern or checkerboard. No cast shadow, ground, glow or haze outside the silhouette. Do not reproduce guide lines, guide colours, hatching, crosses or arrows.
Return just the corrected sprite.
```

Call 2 rejected: brightness reached the numerical gate, but centre alpha remains 253 and the cap remains vertically compressed with an over-deep band.

Untouched verify: `size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=149,147,1102,1096 p99_max=0.616 spread=72 key_px=0 checker=0.000 p99_any=0.616 p99_noamber=0.616 amber=0.0000 amber_glow=0.0000 spread8=72`.

Candidate verify: `size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=122,120,899,894 p99_max=0.620 spread=74 key_px=0 checker=0.000 p99_any=0.620 p99_noamber=0.620 amber=0.0000 amber_glow=0.0000 spread8=74`.

### Call 3 — last-resort flat-key generation

References: `ref/template_v1.png`, `out/rejected/map_v1_mucus_blob_try2.png`. `transparent_background: false`.

```text
Use case: stylized-concept.
Asset type: one isolated MUCUS droplet sprite, dark teal glossy agar, premium chunky mobile arena game art, soft 3D cel shading, thick clean outline.
Canvas exactly 1024x1024. LAST-RESORT COLOUR-KEY OUTPUT: the background is solid pure #FF00FF, perfectly uniform, with no gradient or pattern. This key colour must occur nowhere in the object. Paint the entire object fully opaque.
Input images in order: (1) ref/template_v1.png = measurement guide; reproduce none of its lines, colours or arrow. (2) out/rejected/map_v1_mucus_blob_try2.png = MATERIAL AND PALETTE reference only. Its cap was too oval and too far north; do NOT preserve its cap geometry.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows
ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom
centre, thinning to nothing at the left, right and top. Nothing rises above the footprint
circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens
toward the lower-right; optional hairline rim light on the lower-right edge.
Follow the measurement guide's TWO PERFECT CIRCLES exactly. Outer circle centre (512,512), radius 384, diameter 768, x128..896 y128..896. Inner cap centre (512,474), radius 346, diameter 692 IN BOTH DIRECTIONS, x166..858 y128..820. The inner cap is a CIRCLE, never an ellipse; almost the same height as width. The two circles touch at the top. The south band is the region between them and is only 76px deep at bottom centre, 38px at the extreme left/right. Its boundary at the middle column is y820. Reduce the band's bottom depth from the material reference substantially. Draw neither a raised sphere nor a pedestal.
Palette: cap #37666F; body #26494F; south band #142C32; a continuous 13px outer outline #081A20. Exact colours, muted and dark. Darkest lower-right.
One single broad but short muted elongated upper-left specular accent #5A8C93, painted area about 60x70px, under 1% of object area. Keep all other cap pixels at or below 125/255 on their brightest channel. No white or pale reflection. No shining lower rim.
Perfectly smooth gel, no granules or spots, no extra rings. Entire object is solid opaque including all inner pixels. The only background is the flat magenta key.
No text, letters, numbers, logos, symbols, watermark or signature. No anthropomorphic arrangement or paired spots. No filled pale or saturated round dots or balls. No people, equipment, metal or angular forms. No cast shadow, ground, exterior glow or haze. No template lines, guide colours, hatching, crosses or arrow. One image only.
```

Call 3 rejected: the last-resort key workflow fixes centre opacity, but the silhouette begins at y109 (must be at least y120), p99_noamber 0.639 exceeds 0.62, and the cap is still visibly vertically compressed with too much south band.

Untouched verify: `size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.988 spread=255 key_px=844691 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0000 amber_glow=0.0000 spread8=255`.

Pipeline: `powershell -ExecutionPolicy Bypass -File out/extract-key.ps1 out/rejected/map_v1_mucus_blob_key.png out/rejected/map_v1_mucus_blob_try3_extracted.png`, then `powershell -ExecutionPolicy Bypass -File resize.ps1 out/rejected/map_v1_mucus_blob_try3_extracted.png out/rejected/map_v1_mucus_blob_try3.png 1024 1024`.

Verification command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_mucus_blob_try3.png`.

Candidate verify: `size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=255 opaque=0.461 bbox=120,109,903,897 p99_max=0.639 spread=81 key_px=0 checker=0.000 p99_any=0.639 p99_noamber=0.639 amber=0.0000 amber_glow=0.0000 spread8=215`.

Status: three-attempt limit reached; no accepted anchor. User decision requested before further anchor calls. Later obstacle calls have not begun.

<!-- next-call -->

## 2-ci iş — slot 2–8

# Damla / Droplet V1 — resumed production log

Built-in image_gen used. STYLE_MAP.md read. Slot 1 is the user-approved prior-run try 2 and is not regenerated. All output paths are relative to this workspace. Generation originals and rejected candidates are kept in out/rejected/. Exact tool arguments are also saved under out/calls/.

## 1. map_v1_mucus_blob.png — APPROVED ANCHOR, unchanged

Source: `ref/map_v1_mucus_blob.png`, copied unchanged to `out/map_v1_mucus_blob.png`. No image generation call in this resumed run; the previous run's exact prompt was not supplied.

SHA256 (source and final): `A3A445E91217C930890F969D914DE35CB5E143E94071D4A53CEEE5206D6D1200`.

Verification command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_mucus_blob.png`

```text
size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=122,120,899,894 p99_max=0.620 spread=74 key_px=0 checker=0.000 p99_any=0.620 p99_noamber=0.620 amber=0.0000 amber_glow=0.0000 spread8=74
```

Review: Numeric gate passes; south band approximately 120 px is explicitly accepted by the user and sets kit depth. No rejection or regeneration in this run.


## 2. map_v1_mucus_bloom.png — BEST OF THREE, deviations

Selected try 3: keeps the entire sprite inside the collision circle and has genuine alpha and exactly 7 distinct vesicles. It is undersized (bbox163,158,860,862 versus target128..896), and p99_noamber0.678 exceeds0.62. South band is approximately110px. Try1 rejected for excessive size and brightness; try2 is darker but still exceeds the collision footprint. Per the three-try rule the kit continues with try3 retained, not marked gate-passing.

### Call 1

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/mockup_crop_v1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. Asset: map_v1_mucus_bloom.png, one isolated mobile map obstacle, 1024x1024 RGBA PNG.
Input 1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input 2 map_v1_mucus_blob.png: approved KIT ANCHOR and edit target; match its material, outline weight and lighting. Input 3 mockup_crop_v1.png: style reference only; do not copy the scene.
Edit the approved teal dome by embedding EXACTLY 7 low-contrast gel vesicles inside its cap. Keep the anchor's canvas, round silhouette, continuous #081A20 outline about 13 px, broad upper-left specular, and deeper south band unchanged. Anchor south band is deliberately about 120 px deep at bottom centre; cap meets band near y770, bottom near y895. This accepted anchor depth overrides the thinner cap in the measurement guide.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Vesicles: 7 large submerged lumpy organic forms, each 60–120 px across, clearly unequal sizes, shapes and depths, unevenly scattered, never in a line or a symmetric arrangement; no similar pair beside one another. Their contrast is very low, entirely teal within the gel, no pale or bright rings or beads. Keep every vesicle well inside the cap. Top #37666F, body #26494F, south band #142C32; specular #5A8C93, no channel above 158/255; no more than 1% bright specular area. Match the subdued existing sheen of the anchor.
Outer footprint centre (512,512), radius384, desired bounds128..896, tolerance120..904. Fully opaque centre; only edge antialiasing translucent. Empty transparent margin all around.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_mucus_bloom_try1_orig.png`, followed by proportional resize with resize.ps1 and verification of try1.png.

```text
Untouched: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.510 bbox=120,107,1131,1123 p99_max=0.718 spread=84 key_px=0 checker=0.000 p99_any=0.718 p99_noamber=0.718 amber=0.0000 amber_glow=0.0000 spread8=84
Resized: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.510 bbox=98,87,924,917 p99_max=0.718 spread=85 key_px=0 checker=0.000 p99_any=0.718 p99_noamber=0.718 amber=0.0000 amber_glow=0.0000 spread8=85
```

### Call 2

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_mucus_bloom_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. Output one 1024x1024 RGBA sprite.
Input 1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow.
Input 2 map_v1_mucus_blob.png: approved KIT ANCHOR; match its material, outline weight and lighting.
Input 3 map_v1_mucus_bloom_try1.png: EDIT TARGET. Keep its exactly seven unevenly scattered, differently shaped embedded vesicles and its deep south band. Correct ONLY registration and brightness.
CRITICAL REGISTRATION: the entire circular silhouette must be exactly 75% of the canvas width AND height, centred at 50%,50%, leaving 12.5% TRANSPARENT padding at all four cardinal directions. Never zoom to fill the frame. On a 1024 canvas outer bounds are128..896; on ANY other output size the bounds must be12.5%..87.5%. Match the scale and placement of Input2. Circular outline #081A20 about1.3% of canvas width, continuous. South band about120px on1024, matching anchor.
CRITICAL COLOUR: darken the entire cap and every inclusion to match Input2. Top #37666F, body #26494F, band #142C32. The SINGLE broad upper-left sheen must be very subdued, max #5A8C93. No channel anywhere may exceed158/255; most cap channels below120/255. Avoid additive brightening of overlapping vesicles and sheen. The vesicles are faint internal low-contrast teal volumes, never bright blobs, every one at least60px on1024.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Keep seven inclusions, no extra detail. Opaque centre alpha255, genuine transparent surrounding canvas, no painted backdrop. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_mucus_bloom_try2_orig.png`, followed by proportional resize with resize.ps1 and verification of try2.png.

```text
map_v1_mucus_bloom_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.508 bbox=123,107,1130,1121 p99_max=0.580 spread=73 key_px=0 checker=0.000 p99_any=0.580 p99_noamber=0.580 amber=0.0000 amber_glow=0.0000 spread8=73
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_mucus_bloom_try2.png (1024x1024)
map_v1_mucus_bloom_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.508 bbox=100,87,923,915 p99_max=0.580 spread=74 key_px=0 checker=0.000 p99_any=0.576 p99_noamber=0.580 amber=0.0000 amber_glow=0.0000 spread8=74

```

### Call 3

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_mucus_bloom_try2.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One isolated PNG sprite with real transparency.
Input1 template_v1.png is a measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png is the KIT ANCHOR: match its material, outline weight and lighting. Input3 map_v1_mucus_bloom_try2.png is the edit target.
Make ONE correction: ZOOM OUT from input3, reducing the circular object to 92% of its current diameter while leaving the square canvas the same size. Centre it exactly at the canvas centre. Increase the empty margin at the top and sides. Do not enlarge the object to fit. The final object's diameter must be exactly THREE QUARTERS of the canvas, with ONE EIGHTH of the canvas completely empty at top, bottom, left and right. If the output canvas is1254x1254, the silhouette MUST run x157..1097 and y157..1097, centred627,627, radius470. If1024x1024, x128..896 y128..896. Everything beyond that circle must have alpha0. The approved anchor in Input2 demonstrates the correct size.
Preserve the seven large faint differently-shaped teal gel vesicles, the single subdued upper-left sheen, deep120px-equivalent south band, outline, and existing dark colours of input3 exactly; do not brighten anything. No channel above158/255, body #37666F and #26494F, south band #142C32, outline #081A20.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_mucus_bloom_try3_orig.png`, followed by proportional resize with resize.ps1 and verification of try3.png.

```text
map_v1_mucus_bloom_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.364 bbox=199,194,1053,1056 p99_max=0.678 spread=79 key_px=0 checker=0.000 p99_any=0.678 p99_noamber=0.678 amber=0.0000 amber_glow=0.0000 spread8=79
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_mucus_bloom_try3.png (1024x1024)
map_v1_mucus_bloom_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.364 bbox=163,158,860,862 p99_max=0.678 spread=81 key_px=0 checker=0.000 p99_any=0.678 p99_noamber=0.678 amber=0.0000 amber_glow=0.0000 spread8=81

```

Final verification command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_mucus_bloom.png`; same metrics as resized try3 above.


## 3. map_v1_brittle_s0.png — BEST OF THREE, deviations

Selected try3. Matte crust, continuous outline, deep south band approximately100px, amber3.27% and non-amber p99=0.529. Remaining deviations: glow1.40% exceeds1.00%; north bbox118 is2px beyond gate120, within STYLE_MAP's8px geometry tolerance. Fine texture and some secondary cracks are smaller than requested. Try1 rejected for shell brightness0.824 and glow1.14%; try2 for shell brightness0.678. No fourth call, per three-try rule.

### Call 1

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`.

transparent_background: true

Exact prompt:
```text
Use case: style-transfer. Create one matte dried-agar crust dome sprite, 1024x1024 RGBA, isolated on true transparency.
Input1 template_v1.png = measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png = approved KIT ANCHOR; match its material, outline weight and lighting, translating the gel into matte grey dried agar.
Keep exactly the anchor's circular footprint, canvas placement, continuous13px dark #081A20 outline, and its accepted deep south band about120px at bottom centre. The object occupies75% of canvas width and height, centred50%,50%; transparent12.5% margins on all sides. Outer circle(512,512) radius384 on1024. Never enlarge to fill the canvas. Cap bottom near y770, silhouette bottom y896.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Stage0 undamaged brittle crust: shell #77766C, matte faintly chalky, softly rounded, NO gel gloss or shine. South band #3A3934, darkest lower-right. Main angular branching cracks are24px wide, secondary14px wide on1024. Sparse but readable amber crack bodies #D09345 must occupy4–6% of the top (3–5% of total opaque sprite). Target total amber share4%. A few restrained thin core sections #F0B94E to #FFD27A, LESS than1% of total opaque area. Crack distribution irregular, no symmetric spokes, not a cobweb. No chips at this stage. No spikes or rocky protrusions.
All NON-AMBER pixels max channel148/255, with almost all shell pixels below130/255; do not overexpose. Opaque alpha255 throughout interior.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Untouched and resized checks, using `powershell -ExecutionPolicy Bypass -File out/tools/Import-Candidate.ps1 -Source <generated image path> -Name map_v1_brittle_s0 -Try 1` (calls verify.ps1 before and after resize.ps1):
```text
map_v1_brittle_s0_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.444 bbox=152,148,1100,1093 p99_max=0.910 spread=210 key_px=0 checker=0.000 p99_any=0.910 p99_noamber=0.827 amber=0.0338 amber_glow=0.0116 spread8=210
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s0_try1.png (1024x1024)
map_v1_brittle_s0_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.444 bbox=124,121,898,892 p99_max=0.910 spread=211 key_px=0 checker=0.000 p99_any=0.910 p99_noamber=0.824 amber=0.0338 amber_glow=0.0114 spread8=211

```

### Call 2

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s0_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One1024x1024 RGBA image.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR, match its material, outline weight and lighting. Input3 map_v1_brittle_s0_try1.png: EDIT TARGET.
Change ONLY the brightness and colour of Input3. Keep the same canvas, EXACT same silhouette and13px dark continuous outline, position and scale, south band and every crack shape. This is a DARK game map prop.
Repaint the grey shell dark muted warm grey #77766C, with its very brightest upper-left patch only #89877C (RGB137,135,124). The whole top has restrained low-contrast matte chalk shading; absolutely no pale beige or near-white highlight. Most shell pixels should have max channel105–125/255. The very brightest shell pixel MUST remain below145/255. South band dark #3A3934. Remove the excessively bright beige area at upper-left while retaining faint chalk texture.
Preserve current amber area3.4% of total opaque pixels but turn almost all of it into subdued ochre #D09345. Glowing cores #F0B94E only in a few short thin sections, total0.5% of opaque pixels, half as much as now. Nothing glows beyond cracks.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Footprint circle centre512,512 radius384, occupying75% ofcanvas; do not zoom or change framing. Deep south band near120px matches anchor. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Untouched and resized checks, using `powershell -ExecutionPolicy Bypass -File out/tools/Import-Candidate.ps1 -Source <generated image path> -Name map_v1_brittle_s0 -Try 2` (calls verify.ps1 before and after resize.ps1):
```text
map_v1_brittle_s0_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=149,145,1102,1094 p99_max=0.851 spread=220 key_px=0 checker=0.000 p99_any=0.851 p99_noamber=0.682 amber=0.0325 amber_glow=0.0098 spread8=220
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s0_try2.png (1024x1024)
map_v1_brittle_s0_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=122,119,900,894 p99_max=0.847 spread=217 key_px=0 checker=0.000 p99_any=0.847 p99_noamber=0.678 amber=0.0325 amber_glow=0.0096 spread8=217

```

### Call 3

References (in order): `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s0_try2.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One isolated RGBA sprite.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR, match its material, outline weight and lighting. Input3 map_v1_brittle_s0_try2.png: EDIT TARGET.
Only darken the GREY SHELL of input3 substantially: multiply shell brightness by0.70. Its current upper-left area is still too light. Make the brightest part of the entire shell a subdued #77766C grey, and the rest darker. No shiny highlights, no pale patches, no beige. The upper-left diffuse light must be subtle. Dark grey matte chalk crust. Keep amber cracks and tiny glowing cores exactly unchanged, same pattern and area3.25%, glowing0.96%. Keep black outline, deep south band #3A3934, same shape, exact position and framing. Every non-amber pixel stays below max channel148/255; target highest shell grey119/255.
Canvas square1024x1024, unchanged registration: circle centred512,512 radius384,75% of canvas, transparent margins12.5%. Do not resize the subject relative to canvas.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Untouched and resized checks, using `powershell -ExecutionPolicy Bypass -File out/tools/Import-Candidate.ps1 -Source <generated image path> -Name map_v1_brittle_s0 -Try 3` (calls verify.ps1 before and after resize.ps1):
```text
map_v1_brittle_s0_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=149,145,1104,1097 p99_max=0.953 spread=246 key_px=0 checker=0.000 p99_any=0.953 p99_noamber=0.529 amber=0.0329 amber_glow=0.0142 spread8=246
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s0_try3.png (1024x1024)
map_v1_brittle_s0_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.949 spread=249 key_px=0 checker=0.000 p99_any=0.949 p99_noamber=0.529 amber=0.0327 amber_glow=0.0140 spread8=249

```

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_brittle_s0.png`

```text
map_v1_brittle_s0.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.949 spread=249 key_px=0 checker=0.000 p99_any=0.949 p99_noamber=0.529 amber=0.0327 amber_glow=0.0140 spread8=249

```


## 4. map_v1_brittle_s1.png — BEST OF THREE, deviations

Selected try3 with stage0 alpha copied pixel-for-pixel using out/tools/Copy-StageMask.ps1 (RGB unchanged). One spanning fissure and two widely separated unequal inset chips. Non-amber p99=0.612 passes. Remaining deviations: amber6.30% below7–10%; glow2.12% above2%; bbox north118 inherits the2px stage0 tolerance deviation. Shell colour/texture changed slightly during image edits despite preservation prompts. Try1 rejected for brightness, insufficient amber, excessive glow, and one key-colour edge pixel after masking; try2 for brightness and excessive glow. Deep band retained.

### Call 1

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s0.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. Output one1024x1024 RGBA damage-stage sprite.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting. Input3 map_v1_brittle_s0.png: EDIT TARGET, all exterior pixels and all grey shell colours locked.
Edit the attached crust. Change ONLY the cracks: amber now covers9–12% of the top, ONE crack now spans the whole top from edge to edge, one large and one small chip painted INSIDE the silhouette, far apart from each other; glowing cores at most2%. Keep the canvas, the outer silhouette, the outline, the lighting and all colours identical; do not touch the outer edge (its alpha will be discarded and replaced by the stage-0 mask).
Widen the muted #D09345 crack BODIES until total amber occupies8% of the entire opaque sprite. Preserve the original narrow glowing cores at their existing width and brightness so glowing area stays about1.4% of opaque sprite, never2% or more. The additional amber width is ochre without bright emission. One main edge-to-edge fissure, irregular angular branches. The two inset chips are clearly different sizes and far apart: one large near the upper-right, one small near lower-left, fully inside cap. No detached chips.
Preserve the subdued dark grey #77766C matte shell (maximum grey channel145/255), band #3A3934, and continuous dark #081A20 outline. Match stage0 scale exactly, centred circle occupying75% of the canvas with12.5% transparent margins; deepest south band about120px-equivalent.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 calls verify.ps1 on the untouched original and resized1024 candidate; Copy-StageMask.ps1 then copies stage0 alpha and verify.ps1 runs on the masked candidate.

```text
map_v1_brittle_s1_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=149,147,1103,1097 p99_max=0.988 spread=253 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.702 amber=0.0626 amber_glow=0.0316 spread8=253
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s1_try1.png (1024x1024)
map_v1_brittle_s1_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.447 bbox=122,120,901,896 p99_max=0.984 spread=254 key_px=0 checker=0.000 p99_any=0.984 p99_noamber=0.698 amber=0.0629 amber_glow=0.0309 spread8=254
Copied stage-0 alpha to out/rejected/map_v1_brittle_s1_try1_masked.png; RGB unmodified.
map_v1_brittle_s1_try1_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.984 spread=255 key_px=1 checker=0.000 p99_any=0.984 p99_noamber=0.698 amber=0.0626 amber_glow=0.0308 spread8=255

```

### Call 2

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s1_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One transparent square game sprite.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting. Input3 map_v1_brittle_s1_try1.png: EDIT TARGET.
Keep the same outline, circular framing, deep south band, crack layout, one continuous edge-to-edge crack and the one large upper-right inset chip and one small lower-left inset chip. Make these colour corrections:
1. Darken ALL grey shell pixels by25%, preserving matte texture. BRIGHTEST grey on entire shell #77766C. South band #3A3934. No pale upper-left patch.
2. Widen the muted ochre crack bodies slightly, from6.3% to8% of total opaque area. Use flat, smooth, non-emissive #D09345 ochre as85% of the amber. ONLY15% of amber may be glowing #F0B94E, meaning1.2% of entire opaque area. Eliminate the many bright granular bead-like patches inside the cracks: amber should be smooth narrow veins, no rounded bright speckles. The amber must look like dull ochre fissures with a very few thin lit sections, not glowing liquid.
Preserve all registration. Circle centred512,512 radius384 on1024,75% of canvas diameter with12.5% transparent margins. Keep every outer-edge pixel dark #081A20 and preserve the original stage0 border; its alpha will be replaced with the original mask.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 calls verify.ps1 on the untouched original and resized1024 candidate; Copy-StageMask.ps1 then copies stage0 alpha and verify.ps1 runs on the masked candidate.

```text
map_v1_brittle_s1_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.475 bbox=134,129,1113,1114 p99_max=0.910 spread=226 key_px=0 checker=0.000 p99_any=0.910 p99_noamber=0.647 amber=0.0658 amber_glow=0.0280 spread8=226
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s1_try2.png (1024x1024)
map_v1_brittle_s1_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.475 bbox=109,106,909,910 p99_max=0.906 spread=229 key_px=0 checker=0.000 p99_any=0.906 p99_noamber=0.647 amber=0.0658 amber_glow=0.0270 spread8=229
Copied stage-0 alpha to out/rejected/map_v1_brittle_s1_try2_masked.png; RGB unmodified.
map_v1_brittle_s1_try2_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.906 spread=229 key_px=0 checker=0.000 p99_any=0.906 p99_noamber=0.651 amber=0.0697 amber_glow=0.0286 spread8=229

```

### Call 3

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s0.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s1_try2_masked.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One1024x1024 PNG with real transparency.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting. Input3 map_v1_brittle_s0.png is the locked outer geometry and locked grey-shell colour reference. Input4 map_v1_brittle_s1_try2_masked.png is the edit target and stage1 crack layout.
Repair input4 as follows: restore the exact continuous dark #081A20 outline13px wide and grey-shell lighting of input3; preserve input3's scale, alpha silhouette, and deep south band. Inside that locked border use input4's crack pattern with one edge-to-edge fissure and two far-apart inset chips, one large upper-right and one small lower-left.
The amber cracks must become noticeably DULLER: darken all existing amber by20%. The crack bodies are ochre #D09345 with MAXIMUM channel209/255, no bright gold mass. Only a few tiny narrow core streaks may exceed217/255, under1% of opaque pixels. Increase muted crack-body width by15%, aiming for amber8% of whole opaque area. No granular bright dots, smooth continuous angular veins.
Grey shell is subdued #77766C, brightest grey at most145/255. Keep every exterior pixel dark and transparent outside; alpha will be replaced by stage0. Circle centred512,512 radius384, diameter75% ofcanvas, no framing changes.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 calls verify.ps1 on the untouched original and resized1024 candidate; Copy-StageMask.ps1 then copies stage0 alpha and verify.ps1 runs on the masked candidate.

```text
map_v1_brittle_s1_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.468 bbox=137,130,1113,1106 p99_max=0.902 spread=234 key_px=0 checker=0.000 p99_any=0.902 p99_noamber=0.612 amber=0.0606 amber_glow=0.0209 spread8=234
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s1_try3.png (1024x1024)
map_v1_brittle_s1_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.468 bbox=112,106,909,903 p99_max=0.898 spread=232 key_px=0 checker=0.000 p99_any=0.898 p99_noamber=0.608 amber=0.0604 amber_glow=0.0203 spread8=232
Copied stage-0 alpha to out/rejected/map_v1_brittle_s1_try3_masked.png; RGB unmodified.
map_v1_brittle_s1_try3_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.902 spread=232 key_px=0 checker=0.000 p99_any=0.902 p99_noamber=0.612 amber=0.0630 amber_glow=0.0212 spread8=232

```

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_brittle_s1.png`
```text
map_v1_brittle_s1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.902 spread=232 key_px=0 checker=0.000 p99_any=0.902 p99_noamber=0.612 amber=0.0630 amber_glow=0.0212 spread8=232

```


Stage1 mask hygiene note: zero-alpha RGB is now cleared to black by Copy-StageMask.ps1; visible RGB and all verification numbers are unchanged. The stage1 outline remains continuous but thinner than13px around parts of the north edge after mask replacement; this is an additional recorded deviation.

## 5. map_v1_brittle_s2.png — BEST OF THREE, deviations

Selected try3 with stage0 alpha copied exactly; hidden RGB cleared only where alpha=0. Three spanning crack paths and three fully inset flakes, amber18.19% passes. Remaining deviations: glow8.60% exceeds3–5%; p99_noamber0.984 exceeds0.62 (some very bright yellow cores fall outside the verifier's amber hue interval); outline is too thin or missing along portions of north edge because generated geometry drifted before mask replacement. Shell texture/colour also drifts from stage0. North bbox118 inherits the2px tolerance deviation. Try1 rejected for excessive glow and larger geometry drift; try2 has acceptable4.61% glow but insufficient8.34% amber, p99_noamber0.690, and loss of outline. Try3 retains more dark border and stronger damage progression. No fourth attempt per STYLE_MAP.

### Call 1

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One1024x1024 transparent damage-stage sprite.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR, match its material, outline weight and lighting. Input3 map_v1_brittle_s1.png is the EDIT TARGET.
Stage2, about to break: edit ONLY the cracks and immediate shell around them. Widen fissures substantially to about2.7 TIMES the current amber area. Amber covers18–25% of the TOP, equal to16–18% of all opaque pixels. THREE distinct branching angular cracks now span the whole cap from edge to edge in irregular different directions. Main openings roughly50–65px wide, secondary24–35px on1024. The glowing amber interior is visible through the widest sections: muted #D09345 bodies are75% of amber, smooth narrow #F0B94E to #FFD27A glowing cores are25% of amber, targeting4% of entire opaque area. This stage SHOULD glow, but no external halo.
Darken the grey shell locally around the cracks. Keep shell's brightest grey <=145/255, matte grey #77766C, south band #3A3934; no pale patches. Three small irregular flakes slightly lifting in three widely separated places, all projected completely INSIDE the cap. No transparent holes through shell, no detached debris beyond silhouette, no circular bright speckles.
Keep the canvas, outer silhouette, continuous13px #081A20 outline, lighting and unchanged shell areas identical. Do not touch outer edge; its alpha will be replaced by stage0 mask. Deep south band about120px as anchor. Footprint circle occupies75% of canvas, centre512,512 radius384; maintain exact framing.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 invokes verify.ps1 on untouched and proportionally resized candidates; Copy-StageMask.ps1 replaces alpha from stage0; verify.ps1 checks the masked candidate.
```text
map_v1_brittle_s2_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.575 bbox=83,76,1165,1151 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.988 amber=0.1373 amber_glow=0.0825 spread8=255
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s2_try1.png (1024x1024)
map_v1_brittle_s2_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.574 bbox=68,62,951,940 p99_max=0.992 spread=254 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.984 amber=0.1373 amber_glow=0.0814 spread8=254
Copied stage-0 alpha to out/rejected/map_v1_brittle_s2_try1_masked.png; RGB unmodified.
map_v1_brittle_s2_try1_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.992 spread=254 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.984 amber=0.1662 amber_glow=0.0985 spread8=254

```

### Call 2

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s0.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s2_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. Output one1024x1024 RGBA PNG.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting. Input3 map_v1_brittle_s1.png: EDIT TARGET, stage1 to become stage2. Input4 map_v1_brittle_s0.png: exact outline, scale and dark shell reference. Input5 map_v1_brittle_s2_try1.png: reference ONLY for three fracture paths and three inset flakes, NOT for brightness or scale.
Keep input4's full outer silhouette and13px continuous #081A20 border EXACTLY: circle75% of canvas diameter centred50%,50%, transparent margin12.5% on all sides. Never expand the crust to fill the image. On1024: footprint128..896. On1254: footprint157..1097. Keep the same deep south band about120px-equivalent. The outline must be visible and uninterrupted everywhere, even where cracks approach it.
Change stage1 to stage2 using three spanning cracks like input5, but correctly registered on the SMALLER cap of input4. Amber total16–18% of opaque sprite; ochre #D09345 bodies cover13%, narrow gold-orange #F0B94E cores cover4%. No cream, white, lemon-yellow or hot-white cores: the brightest allowed gold is #FFD27A, use primarily #F0B94E. Reduce the glowing area to HALF of input5. This is a dim interior with thin lit cores, not broad bright channels. Smooth cracks without round bright granules.
Shell must be dark matte #77766C; brightest non-amber pixel <=145/255, no pale upper-left patch. Darken shell around cracks; preserve other shell shading of input4. Three small flakes wholly inside silhouette at different places. No transparent holes.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 invokes verify.ps1 on untouched and proportionally resized candidates; Copy-StageMask.ps1 replaces alpha from stage0; verify.ps1 checks the masked candidate.
```text
map_v1_brittle_s2_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.504 bbox=121,110,1130,1122 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.702 amber=0.0747 amber_glow=0.0417 spread8=255
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s2_try2.png (1024x1024)
map_v1_brittle_s2_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.504 bbox=99,90,923,916 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.702 amber=0.0745 amber_glow=0.0412 spread8=254
Copied stage-0 alpha to out/rejected/map_v1_brittle_s2_try2_masked.png; visible RGB unmodified, zero-alpha RGB cleared.
map_v1_brittle_s2_try2_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.690 amber=0.0834 amber_glow=0.0461 spread8=254

```

### Call 3

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_v1.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_s2_try2_masked.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One transparent1024x1024 game sprite.
Input1 template_v1.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting. Input3 map_v1_brittle_s2_try2_masked.png: EDIT TARGET.
Three final corrections to input3, preserving its existing silhouette and canvas:
A. Paint a solid continuous dark #081A20 border16px wide INSIDE the entire existing circular edge, all the way around, including across every crack ending. The border must be plainly visible everywhere and must never expand the current silhouette. Do not zoom, do not reframe. Circle diameter75% ofcanvas and centred50%,50%, empty12.5% margin all around.
B. Double the width of the DULL OCHRE #D09345 bodies around the existing bright crack cores. Current amber covers8.3%; bring it to16% of total opaque area. Keep the current bright cores exactly their existing width, so they stay4.5% of opaque area. Only add dull ochre beside cores, never widen the bright portions. Smooth muted amber bodies with thin orange-gold cores, no pale or white colour.
C. Darken all grey shell and all three inset flakes by30%. Target subdued dark grey #77766C, very brightest shell pixel130/255 maximum. Preserve three flakes, three spanning crack paths and deep dark south band.
Same opaque interior and real transparent exterior; stage0 alpha will replace generated alpha.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: Import-Candidate.ps1 invokes verify.ps1 on untouched and proportionally resized candidates; Copy-StageMask.ps1 replaces alpha from stage0; verify.ps1 checks the masked candidate.
```text
map_v1_brittle_s2_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.482 bbox=136,121,1111,1114 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.988 amber=0.1700 amber_glow=0.0820 spread8=255
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_s2_try3.png (1024x1024)
map_v1_brittle_s2_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.481 bbox=111,99,907,909 p99_max=0.992 spread=254 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.980 amber=0.1706 amber_glow=0.0805 spread8=254
Copied stage-0 alpha to out/rejected/map_v1_brittle_s2_try3_masked.png; visible RGB unmodified, zero-alpha RGB cleared.
map_v1_brittle_s2_try3_masked.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.992 spread=254 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.984 amber=0.1819 amber_glow=0.0860 spread8=254

```

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_brittle_s2.png`
```text
map_v1_brittle_s2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=121,118,901,895 p99_max=0.992 spread=254 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.984 amber=0.1819 amber_glow=0.0860 spread8=254

```


## 6. map_v1_brittle_rubble.png — ACCEPTED, try2

Nine distinct flat irregular flakes, central heap weighted lower-right, one interior ember, no ring or dark contour outline. Transparent gaps and opaque painted interiors; bbox and radius346 containment pass. p99_noamber0.431, amber0.59%. No amber near the heap exterior. Try1 rejected for raised thick edges, oversized bbox and excessive brightness. Try2 has restrained dark edge shading but no dome side band.

### Call 1

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s2.png`.

transparent_background: true

Exact prompt:
```text
Use case: stylized-concept. NEW artwork, one flat rubble decal,1024x1024 RGBA.
Input1 map_v1_mucus_blob.png: KIT ANCHOR, match its material, outline weight and lighting for kit consistency, with this slot's mandatory exception of NO outline and NO height. Input2 map_v1_brittle_s2.png: MATERIAL reference ONLY for dried-agar crust, never copy its dome shape, cracks layout, illumination intensity or silhouette.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
This slot is completely FLAT, zero height, no side band, no outline, no cast shadow. Draw9 flat dull crust shards of visibly different sizes in one irregular compact HEAP, weighted lower-right. Several touching or overlapping flat shapes around centre and lower-right, sparse upper-left. Absolutely not a ring, not a radial arrangement, no central opening. All9 pieces clearly separable and unequal, without additional crumbs.
Keep entire heap within a circle of radius346px about512,512, and its painted bbox safely within170..854 on both axes of1024. Overall heap spans about65% ofcanvas, with broad transparent margins. Fully OPAQUE pieces alpha255, real transparent gaps and surroundings.
Dull dark grey crust: darkest #3A3934, main #575850, very brightest #706F66. No non-amber channel above119/255, target p99<=0.44. All flat, soft chalk shading without lit bevels. ONE faint short muted-ochre ember in an inner crack, irregular length about100px, width10–14px, at least60px away from every outer heap edge. Amber less than1% of total opaque pixels, no bright glow or pale cores.
Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: untouched original and resized candidate via Import-Candidate.ps1 (verify.ps1 before and after resize.ps1).
```text
map_v1_brittle_rubble_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.290 bbox=156,228,1108,1038 p99_max=0.620 spread=232 key_px=0 checker=0.000 p99_any=0.620 p99_noamber=0.608 amber=0.0032 amber_glow=0.0005 spread8=232
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_rubble_try1.png (1024x1024)
map_v1_brittle_rubble_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.289 bbox=127,186,905,848 p99_max=0.616 spread=229 key_px=0 checker=0.000 p99_any=0.620 p99_noamber=0.604 amber=0.0032 amber_glow=0.0004 spread8=229

```

### Call 2

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_brittle_s2.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_brittle_rubble_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One square RGBA decal.
Input1 map_v1_mucus_blob.png: KIT ANCHOR, match its material, outline weight and lighting except this flat decal has NO outline. Input2 map_v1_brittle_s2.png: MATERIAL reference only, no copied height or brightness. Input3 map_v1_brittle_rubble_try1.png: EDIT TARGET.
Keep the9 different-sized shards and single faint inner ember. Three corrections:
Flatten every shard completely into a thin irregular dried-agar flake, lying exactly flat. REMOVE every dark extruded side, bevel and raised edge. No visible thickness at all, no shadows, no dark outline. Very flat diffuse charcoal-grey texture, like pieces of a dried film seen exactly vertically.
Darken ALL grey crust by35%. Brightest patch only #66655D, most patches #4B4C45, darks #3A3934. Maximum non-amber channel115/255, p99 below0.45. No pale edges or lit bevels. The single muted inner ember remains faint and at least60px from the heap perimeter.
Shrink the complete heap to85% of its current width and height, around canvas centre, preserving the lower-right weight and irregular touching central pieces. Leave more empty space. Target bounding box within180..844 on1024 canvas, with all9 flakes inside radius330 of512,512. No ring arrangement.
Shared kit projection sentence, with this FLAT slot at zero height:
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
This rubble has zero height, zero side band. Paint every flake fully opaque alpha255, including centres, and all gaps and margin genuinely transparent. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification: untouched original and resized candidate via Import-Candidate.ps1 (verify.ps1 before and after resize.ps1).
```text
map_v1_brittle_rubble_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.168 bbox=271,300,999,962 p99_max=0.447 spread=221 key_px=0 checker=0.000 p99_any=0.447 p99_noamber=0.435 amber=0.0060 amber_glow=0.0015 spread8=221
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_brittle_rubble_try2.png (1024x1024)
map_v1_brittle_rubble_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.167 bbox=221,245,815,785 p99_max=0.447 spread=222 key_px=0 checker=0.000 p99_any=0.443 p99_noamber=0.431 amber=0.0059 amber_glow=0.0015 spread8=222
visible_alpha8=181316 outside_required_circle_alpha8=0 visible_max_channel=0.996

```

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_brittle_rubble.png`; additional circle check: `powershell -ExecutionPolicy Bypass -File out/tools/Audit-Special.ps1 rubble out/map_v1_brittle_rubble.png`.
```text
map_v1_brittle_rubble.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.167 bbox=221,245,815,785 p99_max=0.447 spread=222 key_px=0 checker=0.000 p99_any=0.443 p99_noamber=0.431 amber=0.0059 amber_glow=0.0015 spread8=222
visible_alpha8=181316 outside_required_circle_alpha8=0 visible_max_channel=0.996

```


## 7. map_v1_bush_base.png — BEST OF THREE, deviations

Selected try2 for in-bounds geometry, fully opaque centre, genuine transparency and no outline. Remaining deviation: p99_max0.651 exceeds0.62. Mat diameter about700px is slightly smaller than target730px. Try1 rejected for oversized bbox; try3 darkens successfully but re-enlarges the mat beyond all allowed bounds. No further call per three-try rule.

### Call 1

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_bush.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`.

transparent_background: true

Exact prompt:
```text
Use case: stylized-concept. One flat bush ground-mat sprite,1024x1024 RGBA.
Input1 template_bush.png: measurement guide; reproduce none of its lines, colours or arrow. Use ONLY its GREEN DASHED circle radius365 centred512,512 for this ground mat. Ignore the white central disc: the BASE must be solid and filled at centre. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting for kit consistency, with this slot's specific exception of NO outline and NO dome, fully flat.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Draw a completely flat dense dark-green mat of soft frond roots and fallen fronds, intended UNDER microbes. Centre fully opaque, no hollow. Gently irregular fuzzy edge following radius365; all painted pixels kept within x147..877 y147..877 with7px antialias allowance. Mat diameter71% of the square canvas, centred50%,50%, broad transparent margin14.5% all sides.
Palette ONLY muted forest green #24543F to #3E9068. Mostly #24543F and dull #326D50. NO bright tips. Maximum any channel144/255, no highlight brighter than body green. Flat diffuse shading, large simple fallen-frond forms40–70px wide, interwoven irregularly, low contrast, soft/fuzzy organic edges, no fine wiry detail. No height, no band, no cast shadow, no outline, no bright flecks.
True transparent PNG outside mat, alpha255 throughout the middle. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification (untouched then resized with provided scripts):
```text
map_v1_bush_base_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.500 bbox=107,129,1145,1131 p99_max=0.510 spread=68 key_px=0 checker=0.000 p99_any=0.510 p99_noamber=0.510 amber=0.0000 amber_glow=0.0000 spread8=85
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_bush_base_try1.png (1024x1024)
map_v1_bush_base_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.500 bbox=87,105,935,923 p99_max=0.510 spread=69 key_px=0 checker=0.000 p99_any=0.510 p99_noamber=0.510 amber=0.0000 amber_glow=0.0000 spread8=92

```

### Call 2

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_bush.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_bush_base_try1.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One RGBA ground-mat sprite.
Input1 template_bush.png: measurement guide; reproduce none of its lines, colours or arrow. Its green dashed circle is this mat's required outer extent. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting, except this ground mat remains flat and has NO outline. Input3 map_v1_bush_base_try1.png: EDIT TARGET.
Change ONLY registration: zoom out gently, reducing the mat about12% in diameter, keeping the same square canvas and centring it precisely. The finished fuzzy green mat should occupy71% of canvas diameter, with14.5% fully transparent margin on EVERY side. Fit the full mat inside the green dashed guide circle, radius365 on1024, without painting guide marks. Bbox must stay within140..884 on1024. On1254 use margin180px on each side. Do not crop the mat.
Keep the same dark muted forest-green colour, flat fallen-frond arrangement, fuzzy edge, all centre pixels opaque, same gentle upper-left light, and same brightness: p99 about0.51, never above0.62. No lightened tips, no hollow, no outlines or height.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
This base remains completely flat with no south band. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification (untouched then resized with provided scripts):
```text
map_v1_bush_base_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.353 bbox=198,197,1055,1057 p99_max=0.651 spread=79 key_px=0 checker=0.000 p99_any=0.651 p99_noamber=0.651 amber=0.0000 amber_glow=0.0000 spread8=102
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_bush_base_try2.png (1024x1024)
map_v1_bush_base_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.353 bbox=162,161,861,863 p99_max=0.651 spread=80 key_px=0 checker=0.000 p99_any=0.651 p99_noamber=0.651 amber=0.0000 amber_glow=0.0000 spread8=91

```

### Call 3

References: `C:/Users/User/Desktop/Germ game V1/build/codex/v1/ref/template_bush.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/map_v1_mucus_blob.png`, `C:/Users/User/Desktop/Germ game V1/build/codex/v1/out/rejected/map_v1_bush_base_try2.png`.

transparent_background: true

Exact prompt:
```text
Use case: precise-object-edit. One square transparent PNG.
Input1 template_bush.png: measurement guide; reproduce none of its lines, colours or arrow. Input2 map_v1_mucus_blob.png: KIT ANCHOR; match its material, outline weight and lighting except no outline for foliage. Input3 map_v1_bush_base_try2.png: EDIT TARGET.
ONLY DARKEN THE GREEN MAT by25%. Preserve the exact current canvas, shape, placement, scale, frond arrangement, fuzzy edge and full opaque centre. Current upper-left fronds are too bright. All colours must lie between dark #24543F and muted #3E9068; brightest green channel MUST NOT exceed144/255. No mint, lime, pale green, glints or bright tips. The brightest patches should be dull #367C59. The whole mat is a subdued ground decal, low contrast, flat diffuse paint, no shine.
Keep current roughly70% canvas diameter and transparent margins. No hollow, no outline, no height, no side band or shadow.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
The light is extremely subdued diffuse light on this completely FLAT mat. Premium chunky mobile arena game art, soft 3D cel shading. No text, letters, numbers, logos, symbols, anatomy, anthropomorphism, equipment, metal or hard geometric corners. No two similar spots side by side. Never filled pale or saturated round dots or balls; embedded inclusions must be muted, lumpy and non-round. No cast shadow, no ground, no exterior haze or glow. No guide marks. Real PNG transparency outside the subject and in gaps; never a painted checkerboard.
```

Verification (untouched then resized with provided scripts):
```text
map_v1_bush_base_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.524 bbox=106,133,1153,1176 p99_max=0.541 spread=69 key_px=0 checker=0.000 p99_any=0.541 p99_noamber=0.541 amber=0.0000 amber_glow=0.0000 spread8=92
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v1\out\rejected\map_v1_bush_base_try3.png (1024x1024)
map_v1_bush_base_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.523 bbox=87,109,941,960 p99_max=0.541 spread=71 key_px=0 checker=0.000 p99_any=0.541 p99_noamber=0.541 amber=0.0000 amber_glow=0.0000 spread8=84

```

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_bush_base.png`
```text
map_v1_bush_base.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.353 bbox=162,161,861,863 p99_max=0.651 spread=80 key_px=0 checker=0.000 p99_any=0.651 p99_noamber=0.651 amber=0.0000 amber_glow=0.0000 spread8=91

```


## 3-cü iş (2026-10-17) — slot 9–10

> Codex 10-cu slotdan sonra limitə düşdü (bərpa 18:34). vent_base = Codex-in öz seçimi (try1). floor_macro = try2 — Codex onu yoxlamağa çatmadı; Claude seçdi: try1-də "buludlar" ±3%-dən güclü idi, try2 daha sakitdir. Künclər düz `#071012` deyil — pipeline diski onsuz da yenidən maskalayır.

# V1 Droplet — resumed run, part 3

Scope: only slots 9–12. Slots 1–8 were already approved and are not regenerated or modified. Approved kit anchor: `ref/map_v1_mucus_blob.png`.

Tool: built-in `image_gen` (`image_gen__imagegen`). Read `STYLE_MAP.md` first. Originals and rejected attempts are retained under `out/rejected/`. Only the supplied proportional resize script may be used to adjust final dimensions; artwork changes use image_gen.

## Slot 9 — map_v1_vent_base.png

### Call 1 — generation with geometry and material references

- `transparent_background: true`
- `referenced_image_paths`: `ref/template_vent.png`, `ref/map_v1_mucus_blob.png` (absolute workspace paths passed).

Exact prompt:

```text
Use case: stylized-concept.
Asset type: one production mobile-game environment sprite, V1 Droplet refined dark-teal agar, VENT pore, square 1024x1024 RGBA with real transparency.

Input images, in order:
1. ref/template_vent.png is the measurement guide; reproduce none of its lines, colours or arrow. Use only its circle geometry, displaced inner circle and nine broken lip positions.
2. ref/map_v1_mucus_blob.png is the approved KIT ANCHOR: match its material, outline weight and lighting. The vent-specific exception is NO dark outline and negative height. Do not reproduce the solid dome.

Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this recessed pore, apply that same light to a CONCAVE inner wall: shadow on the upper-left inner wall, light on the lower-right inner wall. No raised exterior band.

Primary request: a single round recessed pore cut into wet agar, no surrounding floor. Its perfectly circular outer footprint is centred at (512,512), radius 384. Fill the interior completely opaque; outside is alpha zero. The lip is exactly NINE separate warm amber #F0B94E curved dashes, each about 14 px thick, sitting directly on the footprint circle, with nine clear dark gaps between them. Nine softly rounded arc segments, irregularly spaced and subtly unequal lengths, approximately following the guide. Amber covers 2-10% of the opaque sprite. No other border: no continuous dark outline, no second ring. Stay inside x=120..904 and y=120..904 including antialiasing.

The visible inner wall occupies the annular region from the footprint to a hole floor centred at (512,539), radius 342. Thus wall thickness is about 69 px at the top, 42 px at the sides and 15 px at bottom centre. The inner wall slopes downward and reads as a hole rather than a dome: upper-left wall #0A171A in shadow, lower-right wall muted #2A4A50 lit. Large near-black opaque centre #050C0E, softly joined to the wall, no decorations. Smooth wet agar material with broad soft 3D cel shading, quiet refined palette and clean readable silhouette. Non-amber channels stay below 148/255, never above 158/255.

No swirl, no radial spokes, no strainer, no metal, no machinery, no ground, no cast shadow, no external glow or haze. No pale filled round dots or balls, no paired similar spots, no anatomy, no symbols, no lettering, no labels or watermark. Do not reproduce guide hatching, crosses, red or blue lines, orange arrow, grey backdrop, or a checkerboard. Output exactly one isolated pore sprite with actual transparent pixels outside it.
```

Untouched original: `out/rejected/map_v1_vent_base_try1_orig.png`.

```text
map_v1_vent_base_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.449 bbox=148,139,1106,1093 p99_max=0.988 spread=215 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.612 amber=0.0527 amber_glow=0.0477 spread8=215
map_v1_vent_base_try1.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.448 bbox=121,114,903,892 p99_max=0.988 spread=216 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.612 amber=0.0524 amber_glow=0.0474 spread8=216
```

Rejected call 1: the normalized sprite sits too high (y0=114), has a faint nonzero corner pixel after resizing, and has an incorrect bright upper-left inner wall.

### Call 2 — registration and recessed-wall correction

- `transparent_background: true`
- `referenced_image_paths`: `ref/template_vent.png`, `ref/map_v1_mucus_blob.png`, `out/rejected/map_v1_vent_base_try1.png` (absolute workspace paths passed).

Exact prompt:

```text
Use case: precise-object-edit.
Asset type: one 1024x1024 RGBA recessed agar VENT sprite.
Input images, in order:
1. ref/template_vent.png: measurement guide; reproduce none of its lines, colours or arrow. Its outer circle is exactly centred (512,512), radius 384; its hole floor is centred (512,539), radius 342.
2. ref/map_v1_mucus_blob.png: approved KIT ANCHOR, match its material, outline weight and lighting. Vent-specific exception: no dark outline.
3. out/rejected/map_v1_vent_base_try1.png: edit target. Preserve the clean nine-dash pore idea and dark teal palette, but correct its registration and wall treatment as specified below.

Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
The VENT has negative height: light from upper-left illuminates the opposite LOWER-RIGHT INTERIOR wall. Remove the pale upper-left interior highlight entirely. The upper-left inner wall must be dark #0A171A. The lower-right inner wall is the single lit part, muted #2A4A50, never pale cyan.

Required corrections:
- Exact outer footprint at (512,512), radius 384; top=128, bottom=896, left=128, right=896. All edge antialiasing must stay within x120..904 and y120..904. Empty exterior is exactly alpha 0, including faint fringe pixels. No rectangular matte, no halo, no cast shadow.
- Inner hole floor centred (512,539), radius 342: top=197, bottom=881, left=170, right=854. Wall is WIDEST at the TOP (69 px), only 15 px wide at bottom centre. Do not make a thick bottom rim. Paint the central floor opaque near-black #050C0E and make its colour almost uniform. No giant inner shadow disc, no mottled spiral, no swirl.
- Exactly nine clearly separated amber #F0B94E curved dashes on the outer circle. Keep the nine positions, clear irregular gaps, and softly rounded ends. Each dash about 14 px thick; dashes mostly flat warm amber, no white glints or yellow haze. They cover about 4% of the opaque area.
- No continuous dark outline. No second bright ring or pale cyan line. Smooth wet muted agar, broad quiet soft 3D cel shading.
- Keep ALL visible non-amber colours at or below 148/255 maximum channel; lit wall targets #2A4A50. No pale filled round dots, no balls, no paired spots, no anatomy, no text, no symbols, no guide marks.
Output a single perfectly registered circular recessed pore, fully opaque inside its footprint and truly transparent everywhere outside, on exactly 1024x1024.
```

```text
map_v1_vent_base_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.454 bbox=149,130,1104,1092 p99_max=0.980 spread=204 key_px=0 checker=0.000 p99_any=0.980 p99_noamber=0.580 amber=0.0557 amber_glow=0.0489 spread8=204
map_v1_vent_base_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.454 bbox=122,107,901,892 p99_max=0.976 spread=204 key_px=0 checker=0.000 p99_any=0.976 p99_noamber=0.580 amber=0.0555 amber_glow=0.0488 spread8=204
```

Rejected call 2: top registration worsened (y0=107), corner alpha remains 1, and the upper-left wall is still brighter than specified; the non-amber value cap improved.

### Call 3 — transparent-background cleanup and registration

- `transparent_background: true`
- `referenced_image_paths`: `ref/template_vent.png`, `ref/map_v1_mucus_blob.png`, `out/rejected/map_v1_vent_base_try2.png` (absolute workspace paths passed).

Exact prompt:

```text
Use case: background-extraction.
Deliver one 1024x1024 RGBA game sprite. Inputs:
1. ref/template_vent.png = measurement guide; reproduce none of its lines, colours or arrow.
2. ref/map_v1_mucus_blob.png = KIT ANCHOR: match its material, outline weight and lighting. This pore has no dark outline.
3. out/rejected/map_v1_vent_base_try2.png = edit target, a dark-teal recessed pore with nine amber lip arcs.

Clean and register the target. REMOVE EVERY BACKGROUND PIXEL, including almost-invisible stray pixels and yellow/red fringes. Outside the circular lip the alpha channel must be exactly ZERO. There must be 128 pixels of clear padding on all four sides of the 1024-square canvas. Centre the circle precisely at (512,512) with radius384, the same circle as image1. Do not crop the padding, zoom in, or move the subject upward. The circle must touch x128,x896,y128,y896. Fully opaque centre. A maximum 7px of antialiasing/lip thickness may extend beyond this circle, no further.

Preserve exactly NINE separate softly rounded #F0B94E amber arc dashes with clear gaps. Preserve the smooth teal wet agar material, near-black #050C0E centre, and clean concave pore structure. No dark outline. The interior wall is dark #0A171A at upper-left and softly lit #2A4A50 at lower-right; remove the bright upper-left streak. The inner hole floor is centred (512,539), radius342, reaching y881: a broad wall at the top, only a narrow inner wall at bottom. No pale rim, no raised rim, no new details, no outside shadow or haze.

Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
This recessed pore uses negative height; that light reaches the opposite lower-right INSIDE wall. Non-amber RGB channels <=148. No symbols, writing, anatomy, paired spots, filled round balls, swirl or checkerboard. Produce clean actual transparency and a single exactly centred circular sprite.
```

```text
map_v1_vent_base_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=252 opaque=0.443 bbox=154,147,1099,1097 p99_max=0.992 spread=232 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.655 amber=0.0607 amber_glow=0.0566 spread8=234
map_v1_vent_base_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=252 opaque=0.442 bbox=126,120,897,895 p99_max=0.988 spread=233 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.655 amber=0.0607 amber_glow=0.0561 spread8=233
```

Final selection after the required maximum of three tries: **call 3, kept with deviations; not a full gate pass**. This candidate has clean measured corner alpha and the best registration, so it is preferred over the first two under the hard-rule priority. Visual deviations: only eight amber dashes rather than nine, an unwanted bright upper-left wall, and an overly broad bottom inner wall (visually about 72 px rather than 15 px). `p99_noamber=0.655` exceeds 0.62. No text, anatomy, checkerboard, or continuous dark outline. All three originals and normalized candidates retained.

Verification command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_vent_base.png`

```text
map_v1_vent_base.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=252 opaque=0.442 bbox=126,120,897,895 p99_max=0.988 spread=233 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.655 amber=0.0607 amber_glow=0.0561 spread8=233
```

## Slot 10 — map_v1_floor_macro.png

### Call 1 — generation

- `transparent_background: false`
- No image inputs; palette and geometry specified directly. Flat-even-light requirement takes priority over obstacle shading.

Exact prompt:

```text
Use case: stylized-concept.
Asset type: whole-dish macro floor tone for a premium mobile arena game, exactly 1024x1024, fully OPAQUE RGB. This is a quiet flat floor texture, viewed straight down, not an object or a raised dome.

Composition and exact palette: a circular agar floor disc with centre (512,512), radius512, touching the midpoint of ALL FOUR canvas edges. The four corner regions outside the circle are perfectly flat solid #071012, with no texture or variation. Inside the disc, a softly lighter central pool #1E3B42 eases smoothly into muted dark teal #162D33. Across the interior embed exactly SEVEN very large extremely soft irregular agar zones, each at least100px across, unevenly spaced, with value variation only plus/minus3%. Their boundaries dissolve completely into the floor. Over just the outer30px of the disc, gently darken to #0D1C20 at the glass foot. No visible outlines or concentric ring bands.

Lighting: flat even diffuse illumination with no directional highlight or shadow.
Kit lighting reference sentence: One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For THIS flat floor slot, use the explicit flat-even-light exception: no gloss, no directional shine, no rim highlight, no height band.

The image should be very dark, calm, refined, low contrast, and nearly featureless at game scale. Smooth broad colour transitions; no pixel channel brighter than89/255 (#595959), with normal floor colours much darker, maximum around66/255.
No rings, no grid, no objects, no litter, no bright spots, no bubbles, no filled dots or balls, no paired marks, no cracks, no hard edges, no swirling pattern, no gloss, no cast shadows, no transparent pixels, no lettering, no symbols or watermark. One complete opaque floor-tone image only.
```

```text
map_v1_floor_macro_try1_orig.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.298 spread=52 key_px=0 checker=0.000 p99_any=0.298 p99_noamber=0.298 amber=0.0000 amber_glow=0.0000 spread8=52
map_v1_floor_macro_try1.png: size=1024x1024 format=Format32bppArgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1023,1023 p99_max=0.298 spread=52 key_px=0 checker=0.000 p99_any=0.298 p99_noamber=0.298 amber=0.0000 amber_glow=0.0000 spread8=52
```

Rejected call 1 despite passing the floor value gate: exterior varies rather than being flat #071012; centre sample #1C444F is too blue/light and small cloudy texture is too prominent. Diagnostic: maximum channel81/255; 216252 outside-circle pixels differ from the exact key palette, 3030 differ by more than2 channel levels.

### Call 2 — palette and flatness correction

- `transparent_background: false`
- `referenced_image_paths`: `out/rejected/map_v1_floor_macro_try1.png` (absolute workspace path passed).

Exact prompt:

```text
Use case: precise-object-edit.
Edit the attached floor-tone image into a strict palette-correct production texture. Output exactly1024x1024, fully opaque. Preserve the disc layout: centre(512,512), radius512, touching the four canvas edges. Preserve its smooth flat plan view. Change ONLY colour uniformity and the subtle macro texture.

Outside the circle, every pixel must be the same exact solid dark colour #071012 (RGB7,16,18). Absolutely NO noise, grain, mottling or variation in the four corners. A flat colour field. Inside, set the centre pool to #1E3B42 (RGB30,59,66). Ease smoothly to #162D33 (RGB22,45,51), then through only the outer30px toward #0D1C20 (RGB13,28,32). The previous centre is too blue and too light; remove the cyan cast. Use the exact given neutral dark-teal palette.

Inside there are exactly seven huge irregular zones, each100-250px across, so faint that each changes the local value by only plus/minus3%, smoothly blurred until almost invisible. Remove the many small cloudy marks. No fine noise or grain, no separate round patches, no mottled spots. Preserve the calm, nearly uniform agar appearance.
Keep the entire image below89/255 per RGB channel; centre maximum should be about66/255. No opacity changes, no gloss, no ring outlines, no grid, no objects, no bright spots or balls, no symbols or text.

One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
That is the kit light reference only; this flat floor has the explicit exception of flat even diffuse illumination, no directional shading, no highlight, no height or rim band.
```

## 4-cü iş (2026-10-17 18:38) — slot 11–12

> rim_north = try3 (Codex-in "üçdən ən yaxşısı" seçimi; tikiş fərqi orta 2/255; açar rəng dəqiq #FF00FF deyil, yaxındır — pipeline yaxın-maqentanı da çıxarır). clutter = try3, bütün yoxlamalardan keçdi.

# Version 1 — resume run, part 4

Scope: only slots 11 and 12. Slots 1–10 are already approved and were not regenerated or modified. Read STYLE_MAP.md before generation. Built-in image_gen used. All edits, originals, verification logs and final assets for this run stay in this workspace.

The slot-specific straight strip and flat unlit litter instructions override circular obstacle projection for these environment assets. The clutter's explicit UNLIT requirement also overrides the kit's directional lighting sentence.

## Slot 11 — map_v1_rim_north.png

### Call 1 — initial strip generation

Tool: image_gen; transparent_background=false.

References, in order: ref/template_strip.png (measurement guide), ref/map_v1_mucus_blob.png (kit anchor), ref/mockup_crop_v1.png (style only).

Exact prompt:

```text
Use case: stylized-concept.
Asset type: one production game environment sprite, map_v1_rim_north.png.
Edit the measurement template into a straight, horizontally seamless glass wall strip viewed from inside a dark-teal agar dish. Produce ONE image, 1536x1024 pixels.

Reference inputs in order:
1. ref/template_strip.png = measurement guide; reproduce none of its lines, colours or arrow. Replace its central placeholder band with the glass artwork. The magenta outside the band is the intentional exception and MUST remain exactly #FF00FF.
2. ref/map_v1_mucus_blob.png = KIT ANCHOR: match its material, outline weight and lighting. Use its refined dark teal, wet material finish and restrained shading. This wall is not a circular obstacle and must not copy its round shape or thick perimeter.
3. ref/mockup_crop_v1.png = style reference only; do not copy the scene.

Exact registration, highest priority: output canvas 1536 wide by 1024 high. The only artwork occupies x=0..1535 and y=320..704 inclusive, a perfectly straight rectangular band across the ENTIRE width. All pixels in rows 0..319 and 705..1023 are fully opaque pure RGB(255,0,255), hex #FF00FF, with no variation, texture, gradients or antialiasing leaking into these rows. No key magenta anywhere INSIDE the band.

Inside the band, bottom to top: at y=680..704 a dark wet foot crease #0B1A1E, with one delicate thin meniscus highlight immediately above it; above that, clear teal glass wall shading between #2B5963 and #1E4650 with only broad, very soft vertical refraction streaks; at the very top y=320..327 a straight continuous thin bright lip line #8FD3D6, never thicker than 12 pixels. Keep the body subdued and clean. Exactly THREE sparse HOLLOW irregular condensation rings of clearly different size and proportion, unevenly spaced across the middle of the wall and at different heights; their centres show unchanged glass, no filled beads. Do not arrange similar marks side by side.

Horizontal tiling: the left edge must continue seamlessly into the right edge, with matching colour and texture at every corresponding row. Keep the 80-pixel strips at the far left and far right visually identical, quietly uniform, and free of rings; broad refractive variations blend gently into these edge strips. No lateral overall lighting gradient. The lip and foot crease run perfectly straight and horizontal at fixed y coordinates, all the way to both edges.

Style: premium chunky mobile arena game environment art, polished soft 3D cel shading, smooth organic wet glass, restrained low-frequency detail. One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge. Apply the light locally to the glass details while preserving the identical tiling edges.
This environment-strip geometry overrides obstacle projection: absolutely no curvature, no round footprint, no perspective, no vanishing point, no floor plane extending outside the band.
Nothing behind the glass: no objects, silhouettes, microbes, spikes, scenery, equipment, metal or chrome. No high-frequency vertical stripes. No filled pale or saturated round dots or balls. No paired similar marks, no anatomy or anthropomorphic motifs. No cast shadow, no glow or haze beyond the band. No text, letters, numbers, logos, symbols, watermarks or signatures. No template guides or borders. Keep intentional magenta padding opaque.
```

Call 1 original: `out/rejected/map_v1_rim_north_try1_orig.png` (untouched, exact 1536x1024; no resize).

Untouched verification command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_rim_north_try1_orig.png`

```text
size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=252 key_px=975304 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0000 amber_glow=0.0000 spread8=252
exact_size=true outside_bad_rgb=981504 outside_bad_alpha=0 band_exact_key=0 band_near_key=0 nonkey_rows=0..1023 seam_mean_channel_delta=9.588 seam_max_channel_delta=84 seam_nonidentical_channels=1109/1155
```

Rejected call 1: near-magenta exterior is not exact #FF00FF, the ends differ, and four tiny satellite marks accompany the three main rings.

### Call 2 — correct padding, seam and satellite marks

Tool: image_gen; transparent_background=false.

References, in order: ref/template_strip.png, ref/map_v1_mucus_blob.png, ref/mockup_crop_v1.png, out/rejected/map_v1_rim_north_try1_orig.png (edit target).

Exact prompt:

```text
Use case: precise-object-edit.
Make one corrected production sprite, 1536x1024 PNG, by editing reference 4. Preserve its dark-teal wet glass style, straight wall, three main hollow condensation rings and restrained refraction. Change ONLY the registration, padding, seam consistency, and stray small marks described below.

Reference inputs in order:
1. ref/template_strip.png = measurement guide; reproduce none of its lines, colours or arrow. The intentionally flat magenta exterior is the one exception.
2. ref/map_v1_mucus_blob.png = KIT ANCHOR: match its material, outline weight and lighting, without copying the circular obstacle.
3. ref/mockup_crop_v1.png = style reference only; do not copy the scene.
4. out/rejected/map_v1_rim_north_try1_orig.png = EDIT TARGET.

CRITICAL CORRECTIONS:
The entire artwork must fit exactly into x=0..1535, y=320..704 inclusive.
Every pixel at y=0..319 and y=705..1023 must be exactly RGB(255,0,255), #FF00FF, fully opaque. This is a digital colour-key mask, absolutely uniform, without any shading, colour grading, noise, or compression variation. Use pure fully saturated magenta, not the near-magenta purple of the target. Do not antialias the band's horizontal edges into the key area. Nothing painted outside the band. No magenta at all inside the band.
Put the perfectly straight thin top lip at y=320..327 in #8FD3D6, maximum thickness 12 pixels. The bottom wet crease #0B1A1E ends exactly on row 704. A single very thin meniscus highlight sits just above the crease.
Make the far LEFT and far RIGHT strips of glass identical in every row: the same lip height, same crease height, same teal colour #2B5963 to #1E4650, same shading. Eliminate the lateral colour difference and the broad dark patch at the right end. The edges must tile horizontally with no visible seam. Keep the ends quietly uniform, with all refraction concentrated softly away from the edges. No left-to-right global brightness gradient.
Keep ONLY the three large, middle and small main HOLLOW condensation rings at their existing irregular locations. Remove ALL four tiny satellite beads or marks. Ring centres must remain unfilled and show the same glass as around them. Soften the brightest accents on the rings to muted #5A8C93; only the top lip uses bright #8FD3D6. Keep the wall glass body around #2B5963 and #1E4650, darker than the first result.

Style: premium chunky mobile arena game environment art, smooth wet organic materials, clean soft 3D cel shading. One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge. Apply this locally to the rings, while keeping both tiling edges identical.
This is a straight rectangular environment strip: no circular silhouette, curvature, perspective or vanishing point. No objects, scenery, silhouettes or microbes behind the glass. No high-frequency vertical stripes. No filled pale or saturated round dots or balls, no paired similar marks, no anatomy or anthropomorphic motifs. No cast shadow, glow or haze outside the band. No text, letters, numbers, logos, symbols, watermarks or signatures. Do not draw template guides. Output a single finished image with opaque magenta padding, not a preview or presentation.
```

Call 2 original: `out/rejected/map_v1_rim_north_try2_orig.png` (untouched, exact 1536x1024; no resize).

Verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_rim_north_try2_orig.png`

```text
size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.984 spread=250 key_px=974165 checker=0.000 p99_any=0.984 p99_noamber=0.984 amber=0.0000 amber_glow=0.0000 spread8=250
exact_size=true outside_bad_rgb=981504 outside_bad_alpha=0 band_exact_key=0 band_near_key=0 nonkey_rows=0..1023 seam_mean_channel_delta=7.152 seam_max_channel_delta=72 seam_nonidentical_channels=1101/1155
```

Rejected call 2 as fully compliant: extra satellite marks are removed, but the near-magenta padding is still not exact and the tile ends still differ.

### Call 3 — clean template-based texture

Tool: image_gen; transparent_background=false.

References, in order: ref/template_strip.png, ref/map_v1_mucus_blob.png, ref/mockup_crop_v1.png. The prior attempts are not inputs to this call.

Exact prompt:

```text
Use case: precise-object-edit.
Edit reference 1 into ONE production texture: a horizontally seamless glass wall strip, 1536x1024 PNG.

Inputs, in order:
1. ref/template_strip.png = measurement guide; reproduce none of its lines, colours or arrow. Its existing flat #FF00FF outside the band is the intentional exception: preserve this pure digital key colour exactly.
2. ref/map_v1_mucus_blob.png = KIT ANCHOR: match its material, outline weight and lighting. Use only its refined subdued wet teal finish, not its circular silhouette.
3. ref/mockup_crop_v1.png = style reference only; do not copy the scene.

The final image has just THREE perfectly straight horizontal regions:
Rows 0..319: exactly solid opaque RGB(255,0,255), #FF00FF.
Rows 320..704: the full-width glass wall art.
Rows 705..1023: exactly solid opaque RGB(255,0,255), #FF00FF.
These are pixel-exact boundaries. No noise, vignette, illumination, colour grading, gradients, blur, dithering or texture in either magenta region. No artwork or antialiasing above row 320 or below row 704. No magenta inside the wall band.

Within the middle region, from bottom to top: a 24-pixel dark wet foot crease #0B1A1E, a thin subdued meniscus line, an uncluttered wall of clear dark teal glass #2B5963 easing vertically to #1E4650, then an 8-pixel straight bright top lip #8FD3D6 at y=320..327. Apart from this thin lip the wall is dark, muted and low contrast. Only a few extremely broad soft vertical refraction streaks; no busy grain or narrow stripes. Exactly THREE small HOLLOW condensation rings, all clearly different in size and proportion and irregularly spaced at different heights. One elongated lumpy loop, one smaller narrow loop, one tiny irregular loop. Their interiors are completely unfilled, the unchanged glass shows through. Ring accents stay muted #5A8C93. No additional beads, droplets or satellite marks.

CRITICAL SEAMLESS TILE: the first 128 columns and last 128 columns are identical flat horizontal bands with only the same vertical colour variation. For every y, the colour at x=0 and x=1535 must be identical. The lip and crease height and brightness are identical at both ends. All rings and subtle refractions sit away from these uniform end zones and fade gently before them. No horizontal lighting gradient, no darker right end.

Premium mobile game art, soft 3D cel shading, smooth clean wet organic glass. One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge. Apply this only locally to the three rings. Keep identical tile ends and absolutely flat key-colour padding.
This environment texture is completely straight: no curvature, perspective, round footprint, circular obstacle or scene. Nothing behind the glass. No scenery, equipment, metal, microbes, spiky silhouettes or objects. No filled round dots or balls. No two similar spots side by side, no anatomy or anthropomorphic motifs. No cast shadow, no glow or haze beyond the strip. No text, letters, numbers, logos, symbols, watermark, signatures or measurement lines.
```

Call 3 original: `out/rejected/map_v1_rim_north_try3_orig.png`; also kept as `out/rejected/map_v1_rim_north_orig.png`. Exact 1536x1024, so no resizing was performed. Untouched file checked with verify.ps1 before selection.

### Slot 11 selected final — best effort after three attempts

Selected call 3 and copied it unchanged to `out/map_v1_rim_north.png`. It has the cleanest three distinct hollow rings and the closest tile ends (mean channel difference 2.059/255 versus 7.152 and 9.588 on the previous attempts). It is **not a full gate pass**.

Final verification commands:

```powershell
powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_rim_north.png
powershell -ExecutionPolicy Bypass -File out/verify_part4.ps1 out/map_v1_rim_north.png rim
```

```text
map_v1_rim_north.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.992 spread=253 key_px=976894 checker=0.000 p99_any=0.992 p99_noamber=0.992 amber=0.0000 amber_glow=0.0000 spread8=253
exact_size=true outside_bad_rgb=981504 outside_bad_alpha=0 band_exact_key=0 band_near_key=1534 nonkey_rows=0..1023 seam_mean_channel_delta=2.059 seam_max_channel_delta=19 seam_nonidentical_channels=1006/1155
```

Remaining deviations: the padding is near-magenta with subtle variation rather than exact flat #FF00FF (all 981,504 outside-band pixels differ from that exact RGB); 1,534 near-key pixels fall inside the nominal band at its boundary; the tile ends are visually close but not pixel-identical (max channel jump 19/255); lip and band registration are a few pixels off the prescribed rows. No keying, repainting, seam blending or other image postprocessing was performed. The image is intentionally opaque, so 24-bit RGB and alpha=255 are appropriate for this strip; p99 includes the intended magenta padding and is not a wall brightness gate.

Rejection summary: attempts 1 and 2 had larger seam differences and still failed exact padding; attempt 1 also had four unwanted satellite marks. Call 3 is retained under STYLE_MAP.md's three-attempt fallback, with the deviations above disclosed.

## Slot 12 — map_v1_clutter.png

### Call 1 — flat clutter generation

Tool: image_gen; transparent_background=true.

References, in order: ref/template_grid2x2.png (measurement guide), ref/map_v1_mucus_blob.png (kit anchor, with unlit/no-outline slot exceptions), ref/mockup_crop_v1.png (floor colour context only).

Exact prompt:

```text
Use case: stylized-concept.
Asset type: one production sprite sheet of four tiny pieces of floor litter for a dark-teal agar arena.
Create ONE 1024x1024 PNG with genuine RGBA transparency, a 2x2 sheet following reference 1. The four separate pieces are seen straight overhead, completely FLAT and UNLIT. This is a rotation-safe albedo decal sheet, not shaded 3D props.

Reference inputs in order:
1. ref/template_grid2x2.png = measurement guide; reproduce none of its lines, colours or arrow. Its grid and circles are invisible layout guides only.
2. ref/map_v1_mucus_blob.png = KIT ANCHOR: match its material, outline weight and lighting for kit consistency, with mandatory slot exceptions: this flat litter has NO outline and is UNLIT. Only the refined organic material quality and subdued teal palette carry over; do not copy the dome, gloss, highlight or side band.
3. ref/mockup_crop_v1.png = style reference only; do not copy the scene. Use the deep teal floor as the colour context.

Exact layout: four 512x512 cells, centres at (256,256), (768,256), (256,768), (768,768). Every visible part of each piece MUST stay inside radius 200 pixels of its own cell centre, preferably radius 170 for comfortable transparent margin. All corners, gutters, spaces between pieces, internal gaps and the rest of the canvas are truly transparent, alpha=0. Paint the litter itself opaque with clean antialiased cutout edges. No background colour, checkerboard, floor, ground plane or shadow.

Top left cell (a): ONE single thin flat agar flake with a softly torn, lumpy organic contour, uneven lobes and no hard geometric corners.
Top right cell (b): ONE loose cluster of exactly SEVEN separate irregular crumbs. Every crumb is non-round, different in size and proportion, with uneven gaps and no repeated adjacent sizes. Leave clear transparent gaps so seven individual crumbs can be counted.
Bottom left cell (c): ONE thin flattened curled fibre, an asymmetric open curl with a long tapering tail; continuous and non-round, with a transparent open interior. No duplicate fibre.
Bottom right cell (d): ONE scatter of exactly NINE separate salt grains. Render these as tiny dull, soft irregular slivers and lumpy elongated grains of varied size and angle, not spherical beads or regular crystals. Keep all nine separated by clear transparent gaps, irregular spacing, no pairs and no extra dust.

PALETTE AND UNLIT RENDERING ARE CRITICAL:
Floor reference is pool #1E3B42 and mid #162D33. Litter differs by only +/-8% in value from the nearby floor. Use very dark subdued teal colours around #1D3940, #1F3D44 and #1B363D; stay between maximum RGB channel 61 and 71 for the painted material. Hard ceiling for ANY painted pixel is max RGB channel 0.45 (114/255), but the intended material is much darker, around 0.25. No pale, white, mint, lime or saturated grains.
Absolutely NO directional illumination, highlights, specular, glossy edges, dark outline, bevel, raised volume, south side band, ambient occlusion, cast shadow or drop shadow. Nearly uniform flat local colour with at most extremely faint non-directional organic texture. Do not shade one side differently from the other; these sprites will rotate in the game.

Premium clean mobile arena environment art, soft organic shapes, restrained detail readable when tiny. No filled round dots or balls. No two similar spots side by side. No anatomy or anthropomorphic motifs. No humans, equipment, metal, chrome, hard geometric corners, flowers or objects beyond these four specified litter pieces. No text, letters, numbers, labels, logos, symbols, watermark, signatures, divider lines or template circles. Output only the four dark flat sprites on real transparency.
```

Call 1 untouched original: `out/rejected/map_v1_clutter_try1_orig.png`.

Untouched verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_clutter_try1_orig.png`

```text
size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.128 bbox=126,150,1118,1110 p99_max=0.341 spread=51 key_px=0 checker=0.000 p99_any=0.341 p99_noamber=0.341 amber=0.0000 amber_glow=0.0000 spread8=85
```

Resized proportionally with the provided script: `powershell -ExecutionPolicy Bypass -File resize.ps1 out/rejected/map_v1_clutter_try1_orig.png out/rejected/map_v1_clutter_try1.png 1024 1024`.

Resized-candidate verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_clutter_try1.png`

```text
size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.127 bbox=103,122,913,906 p99_max=0.341 spread=51 key_px=0 checker=0.000 p99_any=0.341 p99_noamber=0.341 amber=0.0000 amber_glow=0.0000 spread8=84
exact_size=true outside_cell_radius_a8=2280 outside_cell_radius_a128=2007 max_channel_a8=102/255 (0.400) pixels_over_0.45=0 max_cell_radii=217.44,216.70,270.62,179.66 components_a128_ge4px=1,7,1,8 component_areas=[55477];[1587,3088,3302,4497,5149,5794,11979];[28121];[1562,1676,1723,1735,2038,2424,2697,2867]
```

Rejected call 1: only eight salt grains, oversize geometry in three cells, one round crumb, and a brighter patch on the broad curled fibre; real alpha and brightness ceiling passed.

### Call 2 — correct count, registration, flat colour

Tool: image_gen; transparent_background=true.

References, in order: ref/template_grid2x2.png, ref/map_v1_mucus_blob.png, out/rejected/map_v1_clutter_try1.png (edit target; inspected before editing).

Exact prompt:

```text
Use case: precise-object-edit.
Edit reference 3 into a corrected 1024x1024 RGBA sprite sheet, keeping the four types of dark flat litter. ONE image only, genuine transparency. Correct the size, positions, count and palette. Do not preserve the oversized silhouettes.

Reference inputs in order:
1. ref/template_grid2x2.png = measurement guide; reproduce none of its lines, colours or arrow. The four cell centres are (256,256), (768,256), (256,768), (768,768).
2. ref/map_v1_mucus_blob.png = kit anchor, muted dark-teal material context only. This litter is explicitly UNLIT and has NO outline, so do not copy gloss, shading, perimeter or round volume.
3. out/rejected/map_v1_clutter_try1.png = EDIT TARGET.

Make the litter visibly SMALLER and centred in each cell, with generous empty transparent space. All visible pixels must lie inside radius 170 of their own cell centre, never beyond radius 200. Do not expand the pieces to fill their cells or their guide circles.

TOP LEFT: one soft irregular flat agar flake centred at (256,256), about 205 pixels wide by 165 high, all inside x=145..367 and y=167..345. Preserve a softly torn organic contour. Completely flat colour, no edge treatment.

TOP RIGHT: exactly SEVEN separate non-round irregular crumbs, all separated with transparent gaps. Suggested centres (733,157), (828,198), (677,242), (765,251), (852,290), (724,335), (806,363). Vary their lengths between 24 and 58 pixels and vary their orientation; make every one lumpy and elongated, at least 1.5 times longer than wide. Remove the round disc-like crumb from the target and replace it with an irregular sliver. No paired similar shapes.

BOTTOM LEFT: one thin, flat curled fibre, asymmetric open curl and tapering tail, confined to x=148..364 and y=660..876. Narrow strand width only 12..24 pixels. Keep the curl interior transparent. Remove the target's broad ribbon bulge, bright patch and shadow-like shading. Uniform dark teal, no cylindrical volume or directional lighting.

BOTTOM RIGHT: exactly NINE separate dull irregular salt grains, not the eight in the target. Suggested centres (738,664), (843,702), (681,724), (784,735), (861,790), (719,801), (789,844), (686,858), (842,873). Different lengths respectively about 16,25,32,20,35,18,28,22,38 pixels, irregular widths and varied angles. Each a tiny soft elongated sliver with uneven organic edges, not a filled round dot, sphere or regular crystal. No extra dust; leave clear transparent gaps between all nine grains.

PALETTE: darken all litter to near the floor #1E3B42, within only +/-8% in value. Use nearly uniform #1D3940 and #1F3D44, with faint non-directional texture only. No visible pixel above RGB max channel 71/255; the hard ceiling is 114/255. No pale, white, mint, lime or saturated material.

UNLIT FLAT ALBEDO: no highlights, shading, gloss, bevel, outline, rim, side band, raised volume, ambient occlusion, drop shadow or cast shadow. Do not put any brighter patch on the upper-left of anything. The sheet must be safe to rotate in-game.
All litter interiors opaque, all background and gaps alpha=0; clean antialiased edges without halo. No painted checkerboard or background floor.
Premium clean mobile game environment art, soft organic forms. No filled round balls or dots, no two similar spots side by side, no anatomy or anthropomorphic motifs. No humans, metal, chrome, equipment or hard geometric corners. No text, letters, numbers, labels, logos, symbols, watermarks, signatures, grids or guide circles.
```

Call 2 untouched original: `out/rejected/map_v1_clutter_try2_orig.png`.

Untouched verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_clutter_try2_orig.png`

```text
size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.084 bbox=164,183,1120,1112 p99_max=0.302 spread=43 key_px=0 checker=0.000 p99_any=0.302 p99_noamber=0.302 amber=0.0000 amber_glow=0.0000 spread8=85
```

Resized proportionally: `powershell -ExecutionPolicy Bypass -File resize.ps1 out/rejected/map_v1_clutter_try2_orig.png out/rejected/map_v1_clutter_try2.png 1024 1024`.

Resized-candidate verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_clutter_try2.png`

```text
size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.084 bbox=134,150,914,908 p99_max=0.298 spread=44 key_px=0 checker=0.000 p99_any=0.298 p99_noamber=0.298 amber=0.0000 amber_glow=0.0000 spread8=84
exact_size=true outside_cell_radius_a8=106 outside_cell_radius_a128=55 max_channel_a8=95/255 (0.373) pixels_over_0.45=0 max_cell_radii=201.76,195.36,219.59,188.22 components_a128_ge4px=1,7,1,9 component_areas=[39220];[2053,2384,2401,2637,2984,3357,4422];[17531];[739,1248,1292,1322,1525,1567,1702,1771,1950]
```

Rejected call 2 as fully compliant: count, alpha and brightness ceiling pass, but the fibre still extends about 20 px beyond its cell radius, and the material is brighter than the requested +/-8% floor-value target.

### Call 3 — reduce scale and flatten colour

Tool: image_gen; transparent_background=true.

References, in order: ref/template_grid2x2.png, ref/map_v1_mucus_blob.png, out/rejected/map_v1_clutter_try2.png (edit target; inspected before editing).

Exact prompt:

```text
Use case: precise-object-edit.
Make ONE corrected 1024x1024 RGBA sprite sheet from reference 3. Keep genuine alpha transparency and the existing four-cell layout. Change ONLY scale and flat colour.

References in order:
1. ref/template_grid2x2.png = measurement guide; reproduce none of its lines, colours or arrow.
2. ref/map_v1_mucus_blob.png = kit anchor for subdued teal material context only; the litter stays UNLIT and has NO outline, no directional lighting and no gloss.
3. out/rejected/map_v1_clutter_try2.png = EDIT TARGET.

SCALE CORRECTION: in EACH 512x512 cell, scale the existing artwork down to 70 percent of its current size around that cell's exact centre. Keep canvas and cell centres fixed: (256,256), (768,256), (256,768), (768,768). All artwork must now fit comfortably inside radius 160 of its cell centre, leaving broad empty alpha margins. In particular shorten the curled fibre's long rightward tail by this scale reduction, so the tail cannot approach the cell edge. Do not re-enlarge the art to fill the available space. Preserve every separate shape and its relative position within its cell.

COUNT AND SHAPE INVARIANTS: exactly one irregular flat agar flake at top left; exactly SEVEN separate irregular non-round crumbs at top right; exactly one continuous open curled fibre at bottom left; exactly NINE separate irregular elongated salt grains at bottom right. Keep the existing non-round silhouettes, irregular spacing and distinct sizes. Do not add, merge, split or remove anything. Keep clear transparent gaps between all crumbs and all grains.

FLAT COLOUR CORRECTION: recolour the painted interiors to a uniform very dark muted teal #1D3940, RGB(29,57,64). Only extremely faint non-directional value variation between #1C373E and #1E3B42 is allowed. No brighter pixels or highlights. This is deliberately dim floor litter, only about +/-8% different in value from floor #1E3B42. Absolutely no channel above 71/255. Reduce the mottled texture contrast of the target. No gradients conveying a light direction, no rim, outline, gloss, bevel, shadows, side band or volume. The fibre is flat, not a lit tube or shaded ribbon.

Keep all litter interiors opaque and all background, corners, gutters, holes and gaps fully transparent with alpha=0. Preserve clean antialiased edges without bright fringes. No floor, backing, checkerboard or cast shadow.
Soft organic mobile game environment art. No filled round balls or dots, no paired similar spots, no anatomy or anthropomorphic motifs, no equipment, metal or geometric hard corners. No text, letters, numbers, symbols, labels, logos, watermarks, signatures, grid lines or guide circles.
```

Call 3 untouched original: `out/rejected/map_v1_clutter_try3_orig.png`; also saved as `out/rejected/map_v1_clutter_orig.png`.

Untouched verification: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v1_clutter_try3_orig.png`

```text
size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.063 bbox=180,219,1084,1083 p99_max=0.231 spread=33 key_px=0 checker=0.000 p99_any=0.231 p99_noamber=0.231 amber=0.0000 amber_glow=0.0000 spread8=69
```

Proportional size correction: `powershell -ExecutionPolicy Bypass -File resize.ps1 out/rejected/map_v1_clutter_try3_orig.png out/rejected/map_v1_clutter_try3.png 1024 1024`. Copied that resized result unchanged to `out/map_v1_clutter.png`. No other image postprocessing.

### Slot 12 selected final — stated own gate passes

Selected call 3. Visually inspected the generated result and resized final: flat dark teal, no painted background, no ground shadow, no perimeter outlines, irregular non-round litter, an open fibre curl, seven crumbs and nine separate grains.

Final verification commands:

```powershell
powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v1_clutter.png
powershell -ExecutionPolicy Bypass -File out/verify_part4.ps1 out/map_v1_clutter.png clutter
```

```text
map_v1_clutter.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.063 bbox=147,179,885,884 p99_max=0.231 spread=33 key_px=0 checker=0.000 p99_any=0.231 p99_noamber=0.231 amber=0.0000 amber_glow=0.0000 spread8=76
exact_size=true outside_cell_radius_a8=0 outside_cell_radius_a128=0 max_channel_a8=84/255 (0.329) pixels_over_0.45=0 max_cell_radii=173.82,172.70,161.91,159.86 components_a128_ge4px=1,7,1,9 component_areas=[28456];[1585,1732,1795,1914,2094,2222,3041];[13333];[688,1088,1140,1241,1272,1350,1552,1584,1641]
```

Rejection summary: call 1 had only eight grains and oversized forms; call 2 corrected the counts but retained an overlong fibre tail and brighter material. Call 3 passes all stated numeric own-gate checks, the hard max-channel ceiling, and the shape counts.

## Part 4 report

- Generated only slots 11 and 12, in that order, with the built-in image_gen tool: three calls per slot, six total. Slots 1–10 and all reference files were untouched.
- `out/map_v1_rim_north.png`: 1536x1024 opaque strip, best candidate after three attempts; **requires exact key/boundary and seamless-edge correction before strict acceptance**. Full deviations and numbers are above.
- `out/map_v1_clutter.png`: 1024x1024 real-alpha sheet; own gate passes, p99_any=0.231, maximum visible channel=0.329, no out-of-circle pixels, counts 1/7/1/9.
- Original and rejected candidates are retained in `out/rejected/`. Final verifier output is also saved in `out/*_verify.txt` and `out/*_extra.txt`; `out/verify_part4.ps1` performs read-only slot-specific measurements.
- Short standalone report: `out/REPORT.md`.
