> Codex-in öz jurnalıdır (gpt-6-astra, reasoning effort `max`). Brif: [BRIEF_MAP_SHARED.md](BRIEF_MAP_SHARED.md), xam fayllar: [../raw/shared/](../raw/shared/).
>
> İş Codex-in istifadə limitinə düşüb yarımçıq qaldı: finalları Codex seçə bilmədi. Codex namizədləri müxtəlif səbəblərlə rədd etmişdi (ölçü 1254², kənarda alfa tozu, qeydiyyat, faktura); yalnız floor_detail try3 SIRF ölçüyə görə rədd olunmuşdu. Finalları Claude seçib və `resize.ps1` ilə 1024²-yə gətirib (başqa heç bir dəyişiklik yoxdur — test bayt-bayt təsdiqlədi): floor_detail = try2, vent_swirl = try3, ripple = try3, splash = try2, debris = try1.
>
> **Məlum qüsurlar** (test 2026-10-02, pipeline avtomatik düzəldə bilər — `design/MAP_25D.md` §6/§7): vent_swirl öz fırlanma mərkəzi (527,558)-dədir, (512,512) deyil, və r 349-a çatır (brif r 269) → (-15,-46) sürüşdür, 0.82 kiçilt; splash r 504-ə çatır, halqası ~23 px aşağıdadır → (-5,-23), 0.82; debris parçaları hücrə mərkəzindən 199–238 px-ə çatır (brif 180) → hər hücrəni 0.76 kiçilt və mərkəzlə; hamısında alfa < 8 sıfırlanmalı və boz rəngə çevrilməlidir (yarımşəffaf kənarlarda spread 51–57). floor_detail tikişsiz DEYİL (kənar fərqi 6.3, qonşu sütunlar 3.6) və brifin ±6%-dən çıxır (1.7% piksel) → yarım sürüşmə + 64 px keçid, 113..143-ə sıxma. ripple brifə uyğundur.

# Shared map texture and VFX generation log

Tool: built-in `image_gen` (`image_gen__imagegen`). All finals are copied byte-for-byte from generated PNGs; no scripted image edits.

> Qeyd (Claude): bu cümlə Codex-in öz planıdır. Sonda finallar `resize.ps1` ilə 1254² → 1024² kiçildilib — başqa heç bir dəyişiklik yoxdur.

The explicit shared-asset brief takes precedence over the generic map value caps, directional lighting for the floor/VFX, debris outline rule, and minimum feature size for micro-texture. All five assets target achromatic RGB. No kit anchor was supplied. Templates are measurement guides only, and the game/concept frames are style references only.

`verify.ps1` is used unchanged. Its `checker` value is the fraction of opaque pixels brighter than 185 with nearly equal channels, not a spatial checkerboard detector; white artwork may trigger this heuristic. Any such result will be recorded with visual and alpha evidence rather than silently changed.

## map_shared_floor_detail.png

### Try 1 — generation

Input images (`-i` equivalent): none passed; attached game/concept frames consulted for context only.

`transparent_background: false`

Exact prompt:

```text
Use case: stylized-concept
Asset type: seamless opaque micro-texture tile for a premium chunky mobile arena game, runtime floor overlay.
Create one 1024x1024 PNG, entirely opaque, entirely achromatic grayscale with exactly R=G=B in every pixel. This is a flat texture map, seen directly overhead, with no objects and no surrounding scene.
The whole tile must read as almost uniform middle grey #808080: target mean 128/255 (0.502); every tonal variation must remain within values 113 through 143 (#717171 through #8F8F8F), only +/-6% absolute value. Very low contrast and understated at thumbnail size.
Material: finely stippled moist agar micrograin, subtle fine wet grain distributed evenly everywhere, three very faint soft irregular fibres, and exactly five widely separated HOLLOW micro-bubble rings, irregular in size and placement, about 18 to 32 pixels diameter. The rings are subdued thin incomplete organic loops with interiors the same grey as the nearby texture, never filled discs. No two similar marks side by side.
Seamless repeat: left edge continues exactly into the right edge and top edge into bottom edge, grain and features wrap naturally. No border, no tiling grid, no focal patch, no visible repeated motif when tiled 3x3. Flat even illumination across every part of the image: no light direction, no highlight patch, no shading gradient, no vignette, no shadow.
Style: restrained softly painted organic wet microscopic material texture, compatible with glossy mobile game sprites, but no glossy objects in this texture.
No hue whatsoever: no warm tint, no cool tint, no blue, teal, green or amber. No solid pale round dots, spheres, beads or filled bubbles. No paired spots. No symbols, text, letters, numbers, logos, watermark, signature, organisms, laboratory equipment, metal, machinery or sharp geometric shapes. Output only the single seamless grey tile.
```


## Bütün namizədlər (generation-log.json)

### map_shared_floor_detail — try 1

Rejected: wrong 1254x1254 dimensions, mean below 0.48, and excessive contrast; ring sizes were also too prominent.

```text
Use case: stylized-concept
Asset type: seamless opaque micro-texture tile for a premium chunky mobile arena game, runtime floor overlay.
Create one 1024x1024 PNG, entirely opaque, entirely achromatic grayscale with exactly R=G=B in every pixel. This is a flat texture map, seen directly overhead, with no objects and no surrounding scene.
The whole tile must read as almost uniform middle grey #808080: target mean 128/255 (0.502); every tonal variation must remain within values 113 through 143 (#717171 through #8F8F8F), only +/-6% absolute value. Very low contrast and understated at thumbnail size.
Material: finely stippled moist agar micrograin, subtle fine wet grain distributed evenly everywhere, three very faint soft irregular fibres, and exactly five widely separated HOLLOW micro-bubble rings, irregular in size and placement, about 18 to 32 pixels diameter. The rings are subdued thin incomplete organic loops with interiors the same grey as the nearby texture, never filled discs. No two similar marks side by side.
Seamless repeat: left edge continues exactly into the right edge and top edge into bottom edge, grain and features wrap naturally. No border, no tiling grid, no focal patch, no visible repeated motif when tiled 3x3. Flat even illumination across every part of the image: no light direction, no highlight patch, no shading gradient, no vignette, no shadow.
Style: restrained softly painted organic wet microscopic material texture, compatible with glossy mobile game sprites, but no glossy objects in this texture.
No hue whatsoever: no warm tint, no cool tint, no blue, teal, green or amber. No solid pale round dots, spheres, beads or filled bubbles. No paired spots. No symbols, text, letters, numbers, logos, watermark, signature, organisms, laboratory equipment, metal, machinery or sharp geometric shapes. Output only the single seamless grey tile.
```

`map_shared_floor_detail_try1.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.584 spread=5 key_px=0 checker=0.000`

### map_shared_floor_detail — try 2

Rejected as a final export: correct mean but wrong 1254x1254 dimensions and outliers exceeding +/-6% value. May serve as an export-normalization source if separately authorized.

```text
Use case: precise-object-edit
Input image 1: edit target, a rejected grey agar micro-texture tile. Preserve its basic micrograin material while correcting the texture below.
Deliver exactly one opaque 1024 by 1024 pixel PNG for a seamless runtime floor overlay.
Make it MUCH subtler and slightly lighter: overall mean MUST be middle grey #808080, value 128 out of 255. All pixels must be achromatic R=G=B. Compress every pixel into the narrow grey range 116 through 140; no dark pits and no bright speckles. The result should look almost like a flat middle grey swatch until viewed closely.
Keep fine wet agar grain at tiny amplitude, reduce the fibres to three barely visible soft wisps, and replace the large obvious rings with exactly five faint HOLLOW loops only 18 to 30 pixels across, scattered very irregularly and widely separated. Ring interiors must match their surroundings. No filled round dots or discs. No two similar marks side by side.
Uniform flat lighting, no upper-left illumination or any other directional lighting, no vignette, no height shading, no focal patch. No scene, props or organisms.
The tile must wrap left to right and top to bottom seamlessly with consistent grey and grain on all four edges and no boundary stripe.
No hue or tint, text, logos, symbols, watermark, border or grid. Keep the canvas filled and opaque. Final export MUST be 1024x1024 pixels, not 1254x1254.
```

`map_shared_floor_detail_try2.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.576 spread=6 key_px=0 checker=0.000`

### map_shared_vent_swirl — try 1

Rejected: oversized and overly textured with detached spray, inconsistent with the required clean registered swirl.

```text
Use case: sketch-to-render
Asset type: rotating water-current VFX sprite for runtime colour multiplication.
Input image 1: measurement guide; reproduce none of its lines, colours, cross or arrow. Replace all guide artwork with the new effect and make its background fully transparent. Preserve the guide's square 1024x1024 canvas and central registration.
Create exactly THREE thick tapering spiral ribbons all curling counter-clockwise around (512,512). Viewed from directly overhead. Each inner root is at least 40 pixels wide, broad luminous-white body, light neutral-grey softened edges, and a single graceful narrow soft outer point. The three arms are rotated copies spaced 120 degrees apart, sweeping counter-clockwise as they extend outward; no extra wisps or detached marks. Soft fade near the centre, leaving an empty or very faint centre. Readable thick water-current strokes, not hairline spirals.
Geometry: every nontransparent pixel MUST be inside radius 269 pixels about (512,512), the red measurement circle. Aim for outermost tips near radius 250, keeping a safety margin. Entire effect fits inside x=243..781 and y=243..781. Do not enlarge to fill the canvas: about half the total canvas width is artwork, surrounded by generous real transparency.
Lighting: rotationally neutral with perfectly equal intensity on all three arms; no external light source, no one-sided highlight or dark side, no bevel, no cast shadow, no 3D raised structure. Brightness follows each stroke's cross-section identically. No dark outline; any grey edge at most 4 pixels.
Palette: strictly achromatic white and light greys, R=G=B on every pixel, with no hue or tint. White cores gently translucent, soft light-grey edges fade into alpha. Real transparent RGBA PNG; all empty areas including the gaps between the arms must have alpha 0. Do not paint a background, checkerboard, black rectangle or grey rectangle.
Style: clean softly painted premium mobile arena water VFX, readable when small.
No filled round balls, beads or dots, no paired spots, text, letters, numbers, symbols, logos, watermark, signature, organisms, hardware, metal or machinery. Output only the single 1024x1024 transparent VFX sprite.
```

`map_shared_vent_swirl_try1.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=32 opaque=0.178 bbox=169,156,1056,1100 p99_max=1.000 spread=11 key_px=0 checker=0.879`

### map_shared_vent_swirl — try 2

Rejected as a final export: wrong dimensions, registration, corner_a=1 and stray alpha. Cleaner artwork but needs technical corrections.

```text
Use case: precise-object-edit
Image 1 is the 1024x1024 measurement guide; reproduce none of its lines, colours or cross. Image 2 is the rejected swirl to correct.
Output a square 1024x1024 real transparent PNG. The swirl must be SMALL and centred: centre (512,512), radius no more than 260 pixels. Keep the surrounding outer 25 percent of the canvas on every side completely transparent. Do not tightly crop the artwork.
Replace the textured foamy brushwork with exactly THREE SIMPLE SMOOTH THICK TAPERING CURVES. Three equal counter-clockwise spiral arms spaced 120 degrees apart, 45 to 60 pixels wide at their roots, thinning to soft points, with a gentle fade near the hollow centre.
Flat achromatic white cores and very light grey soft edges. R=G=B. Rotationally neutral, equal brightness in every direction, no lighting direction, no raised bevel, no shaded sides, no outlines. Clean restrained mobile-game VFX, soft translucency.
Remove all spray, speckles, ragged edges, grain, tiny strands and detached marks. Only the three clean curves. No filled balls or dots. No background rectangle, no checker pattern, no text, symbols or watermark.
```

`map_shared_vent_swirl_try2.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=145 opaque=0.088 bbox=325,319,921,963 p99_max=1.000 spread=9 key_px=0 checker=0.952`

### map_shared_ripple — try 1

Rejected: ring too thick with stray alpha and incorrect export dimensions.

```text
Use case: sketch-to-render
Asset type: one water ripple ring VFX sprite.
Input image 1: measurement guide; reproduce none of its lines, colours or cross. Replace the guide completely with the effect while preserving its 1024x1024 canvas registration.
On a real transparent background, paint ONE soft white circular ripple around (512,512). Centreline radius about 420 pixels, stroke width about 40 pixels, outermost edge near radius 440. The outer edge is slightly brighter and crisper; the single band fades gently inward into a faint wake. A softly brushed 2D water VFX ring, no raised solid rim and no bevel.
One continuous circular band only, not two hard concentric outlines. Hollow interior: everything within radius 370 is completely transparent, alpha 0. Outside radius 450 also completely transparent. At least 62 pixels of empty margin around the ring.
Pure achromatic white and light grey only, R=G=B, no colour or tint. Uniform brightness around the circumference, without directional illumination. Moderately translucent white band fading to transparent, no dark outline, no black shadow, no glowing fog cloud.
No droplets, balls, dots, paired spots, extra rings, symbols, text, watermark or scene. Remove all original guide markings and the grey backdrop. Output exactly one 1024x1024 RGBA PNG with real alpha transparency, never a painted checkerboard.
```

`map_shared_ripple_try1.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.011 bbox=84,91,1170,1161 p99_max=1.000 spread=4 key_px=0 checker=1.000 hollow_a=0.024`

### map_shared_splash — try 1

Rejected: shading resembles metallic material; too textured. Nine streaks and open ring retained for the next edit.

```text
Use case: sketch-to-render
Asset type: soft water-impact splash VFX sprite for a mobile arena game.
Input image 1: measurement guide only; reproduce none of its lines, colours or cross. Replace it with the requested effect on a real transparent 1024x1024 canvas.
One small hollow core RING at the canvas centre (512,512), with exactly NINE separate elongated droplet STREAKS radiating outward at irregular angles and varied lengths. The core ring is about 125 pixels in radius, softly irregular and hollow, with a fully transparent opening at least 160 pixels across. No central solid mass.
Nine droplets should read as stretched curved water slivers with tapering points, not round balls: different lengths about 70 to 170 pixels, different widths about 20 to 45 pixels, irregular spacing. Use approximate angles 8, 44, 91, 127, 172, 212, 254, 297, 334 degrees. Keep all streaks separate from the core ring, no additional spray specks. Do not create a symmetric starburst.
Everything fits within radius 410 pixels about (512,512), with 102 pixels or more of completely transparent margin around the square. Centre opening, gaps and background all have actual alpha 0.
Palette: purely achromatic neutral white and greys, exact R=G=B. Soft white cores fading through grey and transparency, no hue or colour, no black outline, no glow cloud, no cast shadows. Clean painterly mobile-game water VFX, clear rounded organic strokes, uniform non-directional brightness.
No filled balls, dots, beads, disc at the centre, paired spots, hard angular shapes, text, symbols, logo or watermark. No guide artwork and no painted checkerboard. Output a single real transparent 1024x1024 RGBA PNG.
```

`map_shared_splash_try1.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.097 bbox=69,42,1185,1199 p99_max=1.000 spread=19 key_px=0 checker=0.199 hollow_a=0.381`

### map_shared_debris — try 1

Four distinct shapes and upper-left lighting achieved; export verification pending review.

```text
Use case: sketch-to-render
Asset type: four breakable organic crust chunks, one transparent 2x2 sprite sheet for a premium chunky mobile arena game.
Input image 1: measurement guide; reproduce none of its lines, colours, crosses, grid or arrow. Image 2: real game frame, style reference only; do not copy the scene. Image 3: approved concept, style reference only; do not copy the scene. Use the concept's chunky outlined organic shell treatment without its colours or crack glow.
Square 1024x1024 RGBA canvas split into four INVISIBLE 512x512 cells. Exactly one isolated chunky shell shard in each cell: upper-left a curved plate; upper-right a thick wedge; lower-left a small thick irregular flake; lower-right a broken curved arc piece with an open notch. All four silhouettes different. Each piece comfortably inside radius 170 around its cell centre, leaving safety space to radius 180. Cell centres (256,256), (768,256), (256,768), (768,768). Empty wide transparent gutters between every piece.
Seen from almost straight above with a slight 3/4 tilt. Rounded organic broken edges, chunky thickness readable as a darker lower-right side, no needle tips, no straight-cut geometric polygons. Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. These are wet organic crust fragments, not stones or manufactured parts.
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
STRICTLY ACHROMATIC: RGB channels equal everywhere. Body tones medium-grey #A3A3A3 through light-grey #D8D8D8, a small white upper-left lit area, dark grey lower-right thickness. Continuous bold near-black #080808 outlines about 15 pixels thick at 1024. No colour tint anywhere, no amber, blue, brown or teal. No glowing cracks and no glow.
Real transparent background alpha 0, including open notch and all spaces between pieces. No cast shadows or ground patches. No text, symbols, watermark, labels, grid, template marks, paired spots, round balls, beads, organisms, hardware, chrome or machinery. Exactly one chunk per quadrant, four total, no loose chips or extra objects. Export one 1024x1024 PNG.
```

`map_shared_debris_try1.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.311 bbox=58,78,1195,1173 p99_max=0.992 spread=9 key_px=0 checker=0.208`

### map_shared_ripple — try 2

Rejected: wrong output dimensions and band still broader than 40 px; background contains faint stray alpha.

```text
Use case: precise-object-edit
Input image 1 is the measurement guide; reproduce none of its lines, colours or cross. Input image 2 is the rejected ripple to correct.
Preserve one circular ring, but make its band much thinner and softer, and eliminate the thick solid tube appearance.
Exactly 1024x1024 transparent PNG. Centre (512,512). The SINGLE ring's outer edge is at radius 438 and inner fade ends at radius 398, so total band thickness is only 40 pixels. The brightest area is a very thin soft white crest near the OUTER edge, fading progressively toward the inside, with no inner bright line and no dark rim. Nothing is painted inside radius 390 or outside radius 442.
Thin ghostly water-wave VFX: ONE delicate circular white stroke with an inward blur, not a solid donut, not a raised rim. Equal lightness all around. Pure neutral greyscale, R=G=B.
Clean smooth circumference, no scallops, foam, spray, speckles or texture. Centre and background completely alpha 0, no colour backdrop or checkerboard.
No beads, balls, text, symbols, watermark, outline, ground shadow or scene. Export precisely 1024 by 1024 pixels.
```

`map_shared_ripple_try2.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.018 bbox=81,83,1172,1165 p99_max=1.000 spread=4 key_px=0 checker=1.000 hollow_a=0.002`

### map_shared_splash — try 2

Rejected: cleaner simple strokes but too much stray alpha/foam between the streaks and wrong export dimensions.

```text
Use case: precise-object-edit
Image 1: measurement guide; reproduce none of its lines, colours or cross. Image 2: splash edit target.
Keep the NINE separate radial streaks, irregular lengths and angles, and the hollow central ring from image 2. Change only the rendering and fit into the guide.
Redraw these silhouettes as SIMPLE SOFT 2D WHITE VFX STROKES. Smooth white cores with neutral light-grey soft edges fading to transparent. Remove ALL internal texture, shiny reflections, speckles, surface wrinkles, dark outlines, bevels and 3D volume. Each streak is one clean softly tapered elongated brush stroke, no rounded beads at its ends. The central ring is one soft hollow white loop, no solid centre.
Pure grayscale R=G=B. No directional light or shading. No metallic appearance, no glow cloud, no added spray, no extra marks. Exactly nine streaks and one hollow ring only.
Real transparent 1024x1024 PNG. Centre (512,512), entire splash inside radius 410. Transparent margin at least 102 pixels on every side. Core ring radius about 125, inner opening transparent alpha 0. Blank background and gaps have alpha 0. No text, logo, watermark, checkerboard or guide marks.
```

`map_shared_splash_try2.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.089 bbox=72,66,1186,1214 p99_max=1.000 spread=4 key_px=0 checker=1.000 hollow_a=0.468`

### map_shared_floor_detail — try 3

Rejected as a final export: still 1254x1254 despite three explicit 1024x1024 requests. Tonal contrast greatly improved.

```text
Use case: precise-object-edit
Input image 1: grey agar texture edit target.
Make the image nearly a flat #808080 swatch: reduce the texture contrast by 75 percent again, with a uniform middle-grey average of RGB 128,128,128. All texture should be barely visible on close inspection. Use neutral grey only with equal RGB channels.
Preserve the fine moist agar grain, three faint soft fibres and five widely separated hollow micro-rings, but subdue every mark, including all bright flecks and dark pits. No pixel brighter than RGB 140,140,140 or darker than 116,116,116. No new marks, no filled dots, no highlight patches.
Keep the tile seamless in both axes with flat, even, directionless light. Entirely opaque.
Crucially deliver a 1024 by 1024 pixel PNG, exactly the requested export dimensions. No frame, text or watermark.
```

`map_shared_floor_detail_try3.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.514 spread=4 key_px=0 checker=0.000`

### map_shared_vent_swirl — try 3 (FİNAL)

Codex limitə düşdüyü üçün statusu yazılmayıb; Codex-in öz qeydi (sessiya faylından): "Rejected as a final export: dimensions and registration still incorrect after cleanup edit; residual stray alpha remains." Claude yenə də bunu seçdi — üç qolu ən təmizi budur, qeydiyyatı pipeline düzəldir.

```text
Use case: background-extraction
Image 1: the 1024x1024 measurement guide; reproduce none of its lines, colours or cross. Image 2: existing three-arm white swirl to clean up.
Preserve the three counter-clockwise tapering spiral arms from image 2, but remove every detached speck and all background haze. Keep ONLY those three smooth soft strokes. Their cores are neutral white, edges light grey and translucent. R=G=B throughout. No texture, outlines, bevels, directional highlights or shadow side. Three equal arms and equal intensity around the rotation. Roots at least 40 pixels thick, tips narrow and soft, centre faded rather than a bright solid ball.
Place the COMPLETE swirl centred exactly at (512,512) on a 1024x1024 canvas, uniformly reduce it until all marks fit inside radius 260. Keep the entire outer 243-pixel border fully transparent.
Actual alpha transparency: alpha 0 outside the three strokes and between them, no low-opacity noise elsewhere. Preserve smooth soft antialiasing immediately on the stroke edges only. White cores have a gently translucent opacity of about 75 percent (alpha about 190), softer edges lower.
No new design elements, text, symbols, watermark or checkerboard. Export exactly 1024x1024 RGBA, not a larger image.
```

`map_shared_vent_swirl_try3.png: size=1254x1254 format=Format32bppArgb corner_a=1 bbox=290,304,950,994` (sonradan ölçülüb)

### map_shared_ripple — try 3 (FİNAL)

Prompt Codex-in sessiya faylından bərpa olunub (rollout-2026-10-02T16-17-01-01a0fc8b…jsonl, ordinal 222). İstinad: `ref/template_ring.png`, `transparent_background: true`.

```text
Use case: sketch-to-render
Image 1 is a measurement guide only; reproduce none of its lines, colours or cross.
Create a new VERY THIN water ripple VFX ring on a real transparent 1024x1024 canvas. The band should be only about four percent of the canvas width, with a very large empty centre.
Exact radial construction around centre (512,512): a single white crest at radius 438, only 3 pixels crisp; its soft white-to-light-grey wake fades inward until completely transparent at radius 398. Total crest-plus-wake width 40 pixels. Outside radius 441 and inside radius 390 absolutely no paint and alpha 0. ONE continuous thin circular band. There must not be a second inner line.
The brightest and crispest area is only along the outermost edge. Gently translucent white, a smooth fade inward, no texture, no raised volume, no solid tube, no dark rim, no shadow, no foam or dots. Even brightness around the full circle. Strictly R=G=B neutral white and grey.
Delete the guide background, coloured circles and cross. No symbols, writing, watermark or checkerboard. Export one 1024x1024 RGBA PNG with a completely transparent centre and transparent outside.
```

`map_shared_ripple_try3.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.010 bbox=90,92,1162,1154 p99_max=1.000 spread=3 key_px=0 hollow_a=0.004`
