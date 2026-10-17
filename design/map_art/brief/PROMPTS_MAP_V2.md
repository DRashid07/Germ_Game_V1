> Codex-in öz hesabatlarıdır (gpt-6-astra, reasoning effort `max`). Brif: [BRIEF_MAP_V2.md](BRIEF_MAP_V2.md), xam fayllar: [../raw/v2/](../raw/v2/).
>
> **1-ci iş** (2026-10-17 18:54): slot 1–5 hazırdır (lövbər baraban = try3, qurbağa kürüsü, diatom s0/s1/s2). 6-cı slotda (qırıntı) Codex limitə düşdü (bərpa 23:38). Qırıntının try1-i qəbul olunmadı: parlaq (p99 0.69, hədəf 0.47), parçaların hündürlüyü var və halqa kimi səpələnib (halqa cərəyan kimi oxunur). Kənarlaşmalar: hamısı ayaq izindən bir az böyükdür (bbox ~81..942 — pipeline dairəyə oturdur), diatom qabığı brifdən parlaqdır (p99_noamber 0.75–0.88). **Risk:** diatom s0-ın ortasındakı badam formalı hamar sahə və ətrafındakı şüalar göz kimi oxuna bilər — çatlar əlavə olunduqca zəifləyir.

## 1-ci iş — slot 1–5

# Pond Drop / Pillar — Version 2 prompt and verification log

Generated with the built-in `image_gen` tool. References are measurement/material/style guides as specified in each exact prompt. All coordinates refer to the final canvas. Untouched tool outputs and rejected candidates are retained in `out/rejected/`. Each accepted slot below records its calls, verification results and deviations.

The shared light and V2 projection sentences are reproduced in every obstacle prompt. Flat/passable slots use their explicitly requested geometry. Up to three attempts per slot; the best candidate is retained and any remaining deviations are reported.

## 01 — map_v2_mucus_blob.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `ref/mockup_crop_v2.png`.

```text
Use case: stylized-concept.
Asset: one isolated 1024x1024 mobile arena obstacle sprite, MUCUS A jelly drum, the master material anchor for a pond kit.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image 2: mockup_crop_v2, style reference only; do not copy the scene. Use only its chunky slate-blue jelly material language, with much dimmer highlights.

Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.

Geometry is critical: the circular base is centred at (512,512), radius 384. The lifted rounded cap fills a circle centred at (512,443), radius 353, top at y90, bottom at y796. The entire silhouette is the union of those circles: x128..896, y90..896. Outside the base circle, paint only the tiny allowed northern crescent inside the cap circle. No lateral bulges. A continuous dark front band fills ALL space between cap and base along the south, reaching the base at y896. Down x512, cap ends near y796 and front band extends solidly to y896, about 100 pixels thick. Absolutely no transparent gap, empty floor, detached base ring or floating lid.

Material: squat glossy, cool slate-blue translucent gel, rounded top edge, broad simple soft cel shading, top #4A6670, body #36505A, front band #22363E. A very subdued internal curved glow line immediately under the top rim, entirely inside the gel. A single irregular elongated upper-left specular smear #75909A, not a pale round spot. Continuous clean dark outline #081A20 approximately 13 pixels wide around the whole silhouette. No beads, no bubbles, no specks, no rings on the cap. Understated broad cloudy colour variations only, never detached round shapes. No smallest painted detail under 40px apart from the outline and internal rim line.
Brightness: all ordinary body and rim RGB channels at most 148/255; tiny specular at most 158/255, occupying less than 1% of the opaque silhouette. No white, cyan or saturated blue.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_blob_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.528 bbox=114,94,1139,1122 p99_max=0.780 spread=107 key_px=0 checker=0.000 p99_any=0.780 p99_noamber=0.780 amber=0.0000 amber_glow=0.0000 spread8=107
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_blob_try1.png -1 -1 -1`
```text
map_v2_mucus_blob_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.528 bbox=93,77,930,916 p99_max=0.776 spread=109 key_px=0 checker=0.000 p99_any=0.773 p99_noamber=0.776 amber=0.0000 amber_glow=0.0000 spread8=109
```

Rejected attempt 1: bbox 93,77,930,916 exceeds registration and p99_noamber 0.776 exceeds 0.62; alpha is valid.

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/rejected/map_v2_mucus_blob_try1.png`.

```text
Use case: precise-object-edit.
Create the corrected 1024x1024 MUCUS A jelly drum sprite.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image 2: previous drum, edit target. Preserve the gel material and solid front band, correct only registration and excessive brightness.

Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.

The previous drum is oversized. Reduce it to fit EXACTLY the template silhouette, leaving 128 pixels empty on the left and right of the base: base circle centre (512,512), radius384; lifted top circle centre (512,443), radius353. Top y90, bottom y896, left x128, right x896. Follow these positions in the output canvas, not the enlarged edit target. Lower cap boundary at x512 is y796; the solid dark front band reaches y896 continuously. Keep the outline entirely inside this union of circles.

Darken the whole gel substantially, especially the huge upper-left reflection and rim. Muted low-luminance slate palette: cap #4A6670, body #36505A, front band #22363E, specular #75909A. Absolutely no RGB channel above158 anywhere; 99% of the opaque pixels below148. Upper-left reflection should be a dim elongated smear, no white or pale shapes. The tiny internal rim line is muted slate, never cyan. Dark continuous outline #081A20 about13px. Keep all internal gel opaque enough that the centre alpha is255. No beads, bubbles, round dots or isolated spots. Broad softly shaded gel variations only.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_blob_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.508 bbox=124,99,1130,1114 p99_max=0.690 spread=81 key_px=0 checker=0.000 p99_any=0.690 p99_noamber=0.690 amber=0.0000 amber_glow=0.0000 spread8=85
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_blob_try2.png -1 -1 -1`
```text
map_v2_mucus_blob_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.508 bbox=102,81,922,910 p99_max=0.690 spread=83 key_px=0 checker=0.000 p99_any=0.690 p99_noamber=0.690 amber=0.0000 amber_glow=0.0000 spread8=85
```

Rejected attempt 2: bbox 102,81,922,910 remains oversized, p99_noamber 0.690 remains too bright, and corner_a=1 contains faint alpha residue.

### Attempt 3

References (ordered): `ref/template_v2.png`, `out/rejected/map_v2_mucus_blob_try2.png`.

```text
Use case: precise-object-edit.
One isolated square MUCUS A slate jelly drum asset on perfectly transparent background.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow. Preserve its framing exactly; no zoom.
Input image 2: previous drum, edit target for material only. Correct size, dark value range and background alpha.

Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.

LOCKED RELATIVE CANVAS REGISTRATION: full art width is exactly 75% of the full square canvas, not 82%. Empty transparent margin is 12.5% of total canvas width on EACH side. Full art begins at 8.8% canvas height and ends at87.5% canvas height. Upper cap is a circle diameter68.95% of canvas, centred horizontally at50%, vertically at43.26%. Round base diameter75%, centred at50%,50%. These proportional measurements scale to any output resolution. At1024, bounds x128..896, y90..896; at1254, bounds x157..1097, y110..1097. Do not fill or crop the canvas.
Top and front band form one completely solid continuous drum. Bottom-centre cap boundary at77.7% canvas height, base at87.5%, with a dark band about9.8% canvas height. No transparent separation.
Reduce brightness decisively: a very dark, muted slate top using #3C535C and #4A6670, dark body #36505A, front band #22363E, single dim upper-left long specular smear #6B818A. No light blue rim; internal rim #516C76. The BRIGHTEST channel anywhere must be no more than145 out of255, no white and no cyan. Soft broad gel cloudy shading without dot shapes. Opaque gel interior alpha255, despite the implied translucent material.
Continuous 13px dark outline #081A20, no detached spots. Background extraction requirement: erase ALL pixels outside the intended silhouette to alpha0, including tiny low-alpha corner residue. All four corner blocks perfectly alpha0.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_blob_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=119,99,1133,1119 p99_max=0.675 spread=64 key_px=0 checker=0.000 p99_any=0.675 p99_noamber=0.675 amber=0.0000 amber_glow=0.0000 spread8=69
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_blob_try3.png -1 -1 -1`
```text
map_v2_mucus_blob_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=97,81,925,913 p99_max=0.675 spread=65 key_px=0 checker=0.000 p99_any=0.675 p99_noamber=0.675 amber=0.0000 amber_glow=0.0000 spread8=65
```


Final: out/map_v2_mucus_blob.png (attempt 3). Retained best after three attempts under the quality-loop rule, not a full gate pass. Correct real alpha, outline type and continuous front band. Deviations: bbox 97,81,925,913 (too wide and low), p99_noamber 0.675 (limit 0.62); front band approximately 150px at centre. Attempts 1 and 2 were rejected for larger brightness/registration errors; attempt 2 also had corner alpha residue.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_mucus_blob.png -1 -1 -1`
```text
map_v2_mucus_blob.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=97,81,925,913 p99_max=0.675 spread=65 key_px=0 checker=0.000 p99_any=0.675 p99_noamber=0.675 amber=0.0000 amber_glow=0.0000 spread8=65
```

## 02 — map_v2_mucus_bloom.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`.

```text
Use case: stylized-concept.
Create one 1024x1024 isolated MUCUS B FROGSPAWN CUSHION obstacle sprite, a squat slate gel drum made from fused irregular lumpy gel beads.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image 2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting. Match its drum design but use the template for exact size and a darker bounded highlight range.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
The drum is the same continuous circular silhouette and filled south band as the anchor, not a separate pile of balls. Full 1024 canvas stays visible; empty margins128px left and right. Round base centre(512,512), radius384; lifted cap centre(512,443), radius353, uppermost y90. Continuous 100px front band at bottom centre from y796 to896, with no gap or floor visible. All art within x128..896,y90..896. Scale proportionally if rendering at a larger resolution.
Inside this silhouette, show 11 fused irregular lumpy gel lobes with strongly varied sizes and asymmetric placement, all at least60px across, soft wet lobes merged with no gaps. Use the SAME dark slate values as the anchor body; no pale beads. Each lobe has broad smooth shading with NO internal dots, cores, specks or spots. No similar lobe pair side by side. Continuous outer outline #081A20 about13px; much softer internal joins.
Cap #4A6670, body #36505A, front band #22363E. Tiny elongated upper-left specular smears muted #6B818A, total area under1%. All channels <=145/255 throughout; no pale or white highlights, no saturated cyan. Interior alpha255.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_bloom_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.546 bbox=101,82,1153,1132 p99_max=0.682 spread=60 key_px=0 checker=0.000 p99_any=0.682 p99_noamber=0.682 amber=0.0000 amber_glow=0.0000 spread8=60
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_bloom_try1.png -1 -1 -1`
```text
map_v2_mucus_bloom_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.546 bbox=82,67,941,924 p99_max=0.682 spread=62 key_px=0 checker=0.000 p99_any=0.682 p99_noamber=0.682 amber=0.0000 amber_glow=0.0000 spread8=62
```

Rejected attempt 1: too large (bbox82,67,941,924) and too bright (p99_noamber0.682).

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_mucus_bloom_try1_orig.png`.

```text
Use case: precise-object-edit.
Edit the third input only: a single FROGSPAWN CUSHION sprite, 1024x1024 transparent PNG.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image 2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image 3: current cushion, edit target. Keep its lumpy fused topology and continuous side band.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Make the entire cushion visibly SMALLER within the unchanged square canvas. Reduce current painted width by12% about canvas centre, keeping at least128px of empty space on each side, and move the shrunken sprite upward7px. All opaque art must be within x128..896,y90..896 in the final1024 canvas. Use the template silhouette and circular base, not the larger anchor bounds. Cap ends at y796 down the middle; the front band continues to y896.
Darken all lobe highlights and rim strokes by25%. The brightest mark should be muted #617984; no RGB channel above148. Top #4A6670, body #36505A, front #22363E. Interior alpha255. Eleven irregular fused gel lobes, unequal shapes and sizes at least60px; nothing drawn inside any lobe except broad smooth gradients. No dots, cores or paired repeated spots. Remove all pale small shine specks, use broad dim elongated shading instead. Keep dark #081A20 continuous outer outline about13px.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_bloom_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.318 bbox=226,247,1032,1050 p99_max=0.671 spread=57 key_px=0 checker=0.000 p99_any=0.671 p99_noamber=0.671 amber=0.0000 amber_glow=0.0000 spread8=57
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_bloom_try2.png -1 -1 -1`
```text
map_v2_mucus_bloom_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.318 bbox=184,201,842,857 p99_max=0.671 spread=58 key_px=0 checker=0.000 p99_any=0.671 p99_noamber=0.671 amber=0.0000 amber_glow=0.0000 spread8=58
```

Rejected attempt 2: over-shrunk and shifted down (bbox184,201,842,857), still too bright (0.671), corner_a1.

### Attempt 3

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_mucus_bloom_try2_orig.png`.

```text
Use case: precise-object-edit and background-extraction.
Final correction of the MUCUS B fused gel cushion; one transparent square sprite.
Input image 1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image 2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image 3: cushion edit target. Its material and fused lobes must remain; its framing and brightness need correction.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Render at1024x1024. The current target is TOO SMALL and TOO LOW. Make it17% wider, move its centre upward36px, then match its top and bottom to the TEMPLATE: silhouette x128..896,y90..896, circular base(512,512)radius384, cap(512,443)radius353. The object must be centred exactly like image1. Dark front band about100px at bottom, continuous, no gap.
The highlights are still too pale. Remove all bright white-looking shine marks. Replace ALL specular streaks with dark muted #617780; brightest colour in the entire image #71868F, maximum143. Lower rim lines to#4A6670. Gel body #36505A to#4A6670, band#22363E. Eleven large fused irregular slate gel lobes; no internal dots or cores, no paired similar spots; continuous dark13px outline#081A20. No pale beads. Entire subject opaque alpha255.
Extract the background completely: every empty pixel, including all corners and padding, must be EXACTLY alpha0. There must be no low-opacity haze or scattered residual pixels. Preserve genuine alpha, no checkerboard.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_mucus_bloom_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=118,125,1136,1149 p99_max=0.690 spread=60 key_px=0 checker=0.000 p99_any=0.690 p99_noamber=0.690 amber=0.0000 amber_glow=0.0000 spread8=60
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_mucus_bloom_try3.png -1 -1 -1`
```text
map_v2_mucus_bloom_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=97,102,927,938 p99_max=0.690 spread=61 key_px=0 checker=0.000 p99_any=0.690 p99_noamber=0.690 amber=0.0000 amber_glow=0.0000 spread8=63
```


Final: out/map_v2_mucus_bloom.png (attempt 3). Retained best after three attempts. Valid real alpha and continuous outline/front band; irregular fused lobes without internal dots. Deviations: bbox97,102,927,938 is wider/lower than template and p99_noamber0.690 exceeds0.62; estimated centre band100px. Attempt1 was larger and attempt2 too small with corner alpha residue.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_mucus_bloom.png -1 -1 -1`
```text
map_v2_mucus_bloom.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.513 bbox=97,102,927,938 p99_max=0.690 spread=61 key_px=0 checker=0.000 p99_any=0.690 p99_noamber=0.690 amber=0.0000 amber_glow=0.0000 spread8=63
```

## 03 — map_v2_brittle_s0.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`.

```text
Use case: stylized-concept.
One isolated 1024x1024 BRITTLE stage0 obstacle: round silica DIATOM PILLBOX, a squat organic grey-green glass drum, barely cracked but still structurally undamaged.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting; translate the wet organic finish to grey-green silica. Template controls geometry.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Use the entire square canvas; never zoom or crop. Base circle centre(512,512), radius384; lifted cap centre(512,443), radius353, top y90, cap bottom y796. Outer bounds x128..896,y90..896. Outside the base, art allowed only inside the northern cap crescent. Bottom-centre dark front band fills y796..896 continuously, no floor or alpha gap. These are 1024 coordinates: scale proportionally at any other resolution. Empty side margins are12.5% each; total width75% of canvas.
The upper plate carries 23 gently irregular fine radial rib channels flowing outward from a broad OFF-CENTRE smooth asymmetrical patch near(390,360). Patch is not circular and contains no dot. Ribs are organic curved silica ridges, not a centred rosette, no hub, no spokes meeting at the centre, no gear teeth. Continuous softly rounded outer rim with a13px #081A20 outline.
Palette: matte wet pale grey-green silica #76786E, ribs #4E544C, south band #33372F. These are DARK muted midtones, never white, silver, chrome or shiny metal. Ordinary RGB maximum148, tiny upper-left specular maximum158 on under1% of body. No bright rim. Top centre alpha255, body opaque.
Amber cracks traverse the ribs: use one asymmetric branched angular fracture, main crack width24..30px and secondary width14px, combined crack bodies4..6% of the TOP area, equivalent3..5% of the whole opaque sprite. Crack bodies #D09345; restrained thin glowing core #F0B94E to#FFD27A on LESS THAN1% of the entire sprite. Concentrate fractures asymmetrically away from the centre. Solid continuous top, no holes, no detached chips. No amber in the side band or outside the silhouette. Keep the whole lower band unchanged and unbroken.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s0_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.590 bbox=83,65,1170,1160 p99_max=0.867 spread=186 key_px=0 checker=0.000 p99_any=0.867 p99_noamber=0.839 amber=0.0180 amber_glow=0.0031 spread8=186
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s0_try1.png -1 -1 -1`
```text
map_v2_brittle_s0_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.590 bbox=68,53,955,947 p99_max=0.855 spread=184 key_px=0 checker=0.000 p99_any=0.855 p99_noamber=0.827 amber=0.0184 amber_glow=0.0030 spread8=184
```

Rejected attempt 1: too large (bbox68,53,955,947), shell too bright(p99_noamber0.827), amber0.0184 below0.03.

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s0_try1_orig.png`.

```text
Use case: precise-object-edit.
One 1024x1024 transparent silica DIATOM PILLBOX, damage stage0.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: current diatom, EDIT TARGET. Keep the off-centre smooth patch, flowing ribs and full front band.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Three essential corrections:
1. Give the object generous empty margins: its circular base diameter is75% of canvas width, with12.5% blank left and12.5% blank right. Base centre(512,512), bottom896. Raised cap top90, bottom796. The existing object fills87% of canvas width: reduce width to75%, retaining the exact circular template geometry. No zoom or crop.
2. Make the silica DARK GREY-GREEN, with a low-key charcoal finish and no white reflections. Broad upper-left shading may reach only #76786E. Every non-amber pixel must have maximum channel less than150/255. Ribs#4E544C, side band#33372F; dark#081A20 outline13px. Remove the pale glare patch and pale rim completely, use muted mid-grey instead. This is a dark background obstacle, never a luminous prop.
3. Widen existing angular amber crack bodies to more than DOUBLE their present width so amber occupies4% of the complete opaque sprite,5% of the top. Main cracks at least24px, secondary14px. Crack body#D09345. Keep the sparse glowing cores essentially unchanged: total glow less than1%. Keep the top solid, no holes or chips, no amber on band.
Interior alpha255. Completely clean transparent padding alpha0.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s0_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.486 bbox=128,128,1125,1113 p99_max=0.863 spread=224 key_px=0 checker=0.000 p99_any=0.859 p99_noamber=0.675 amber=0.0500 amber_glow=0.0101 spread8=224
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s0_try2.png -1 -1 -1`
```text
map_v2_brittle_s0_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.486 bbox=104,104,919,909 p99_max=0.851 spread=224 key_px=0 checker=0.000 p99_any=0.851 p99_noamber=0.675 amber=0.0502 amber_glow=0.0095 spread8=224
```

Rejected attempt 2: shell p99_noamber0.675 exceeds0.62, bbox104,104,919,909, corner_a1, amber0.0502 marginally over0.05.

### Attempt 3

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s0_try2_orig.png`.

```text
Use case: precise-object-edit and background-extraction.
Final refinement of one stage0 silica diatom drum,1024x1024 transparent PNG.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: stage0 diatom edit target. Preserve rib layout and broad off-centre smooth patch.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Correct the object border to match the template exactly: base circle centre512,512 radius384, cap circle512,443 radius353. Full painted bounds128,90 to896,896; generous transparent margin. Dark front band solid to the base, bottom-centre thickness100px. Continuous13px outline#081A20. Never paint outside the guide silhouette.
Make all grey-green silica15% darker than input3. It should be a subdued charcoal-grey-green object. Its BRIGHTEST non-amber mark is muted #85877E, maximum135/255. Remove all pale rim accents. Silica base#76786E, ribs#4E544C, front#33372F, dark gradients below these values.
Reduce amber crack widths20% from input3: amber body total exactly4% of the whole opaque sprite. Main cracks still24px minimum. Body#D09345, glowing thin linear core#F0B94E on under0.8% of opaque area. Smooth angular crack interiors, no granular bright specks or round filled glow spots. All fractures contained inside top, no chips, no holes, no detached fragments.
The empty padding must be ABSOLUTELY transparent alpha0. Remove every faint low-alpha pixel from all corners and exterior. Interior alpha255, true transparent PNG.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s0_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=99,83,1154,1147 p99_max=0.890 spread=237 key_px=0 checker=0.000 p99_any=0.890 p99_noamber=0.753 amber=0.0385 amber_glow=0.0099 spread8=237
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s0_try3.png -1 -1 -1`
```text
map_v2_brittle_s0_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.882 spread=235 key_px=0 checker=0.000 p99_any=0.882 p99_noamber=0.745 amber=0.0386 amber_glow=0.0098 spread8=235
```


Final: out/map_v2_brittle_s0.png (attempt 3). Retained best after three attempts: correct real alpha, continuous outline, off-centre rib patch; amber0.0386 and amber_glow0.0098 pass. Deviations: oversized bbox81,68,942,936; p99_noamber0.745 exceeds0.62, upper-left glare too pale, fine rib/crack details below requested feature scale. Front band approximately140px. Attempts1 and2 had worse amber/alpha or brightness compliance.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s0.png -1 -1 -1`
```text
map_v2_brittle_s0.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.882 spread=235 key_px=0 checker=0.000 p99_any=0.882 p99_noamber=0.745 amber=0.0386 amber_glow=0.0098 spread8=235
```

## 04 — map_v2_brittle_s1.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/map_v2_brittle_s0.png`.

```text
Use case: precise-object-edit.
Create BRITTLE stage1 by editing ONLY THE TOP of the stage0 sprite in input3, preserving its exact canvas framing. Output1024x1024 with real transparency.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: map_v2_brittle_s0, EDIT TARGET and exact spatial master. Preserve its current size, position, outline, entire south front band and lighting identically. Do not redraw or rescale those parts.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
TOP ONLY damage changes: broaden and connect angular amber fractures until crack bodies cover9..12% of the top,7..10% of the whole opaque sprite. Target8.5% overall. One strong crack spans the entire top. Main fractures24px or wider, subordinate fractures14px or wider. Body#D09345, narrow core#F0B94E to#FFD27A, glowing cores LESS THAN2% of the whole sprite. No glowing round dots.
Add one large chip recessed into the top rim at upper-right, and one SMALL chip at lower-left, very far apart. They expose darker silica/amber inside the existing silhouette, not missing outer pixels. Do not detach pieces. No holes.
Preserve the off-centre smooth patch and original radial ribs, displaced only where fractures cross. Keep silica#76786E,ribs#4E544C,front#33372F,outline#081A20. Do not brighten the shell. The south band remains completely solid and identical to input3, extending to the round base with no floor gap.
The outside silhouette and its13px outline must be pixel-aligned to input3. Do not touch the outer edge: output alpha will be discarded and replaced by the stage0 mask. All changes confined within the top plate. No changes to background or lighting.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s1_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.515 bbox=118,97,1136,1128 p99_max=0.988 spread=250 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.957 amber=0.0700 amber_glow=0.0257 spread8=250
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s1_try1.png -1 -1 -1`
```text
map_v2_brittle_s1_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.514 bbox=97,79,928,921 p99_max=0.984 spread=251 key_px=0 checker=0.000 p99_any=0.984 p99_noamber=0.945 amber=0.0700 amber_glow=0.0255 spread8=251
```

Rejected attempt 1: p99_noamber0.945, amber_glow0.0255 exceeds0.02, outer chip cut into silhouette and framing drifted from stage0.

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s1_try1_orig.png`, `out/map_v2_brittle_s0.png`.

```text
Use case: precise-object-edit.
Correct ONLY the top damage on the stage0 diatom. Output1024x1024 transparent.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: stage1 EDIT TARGET, use its damage layout.
Input image4: stage0 LOCKED geometry, front band, outline and lighting reference.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Match input4's exact silhouette, framing, unbroken outline and south band. Repair the large missing outer piece at the upper-right: the chip is an inset TOP chip and must NOT alter the round outer contour. The smaller top chip remains far away at lower-left. Keep the stage0 outer band unchanged, solid to the bottom, with identical colours.
Stage1 damage only: one angular spanning fracture and its irregular branches. Amber bodies7..10% of opaque art, target8.5%, body#D09345. Reduce the bright core width by50% compared to input3. Total bright core coverage1..1.5%, never above2%. Core muted warm amber#F0B94E, not white-yellow. No bright round spots in cracks.
The TOP shell in input3 is far too bright. REMOVE pale glare and pale rib edges. Render shell as very subdued matte dark-grey-green with an absolute brightest shell colour#85877E. Main shell#76786E, ribs#4E544C. Blackish dark-green front#33372F, outline#081A20 about13px. No white marks, no shining pale upper-left spot. Keep the off-centre rib flow, no central dot, no central rosette.
Every RGB pixel outside damage must match stage0 as closely as possible. Do not rotate, zoom or move the image. Output alpha will be replaced with stage0 alpha, so all edits must remain inside the top plate. No empty holes.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s1_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.533 bbox=115,95,1136,1154 p99_max=0.949 spread=225 key_px=0 checker=0.000 p99_any=0.945 p99_noamber=0.765 amber=0.0475 amber_glow=0.0182 spread8=225
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s1_try2.png -1 -1 -1`
```text
map_v2_brittle_s1_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.533 bbox=94,77,928,942 p99_max=0.941 spread=223 key_px=0 checker=0.000 p99_any=0.941 p99_noamber=0.761 amber=0.0474 amber_glow=0.0180 spread8=223
```

Rejected attempt 2: amber0.0474 below0.07, p99_noamber0.761 exceeds0.62; glow0.0180 passes, but large top chip lost and source geometry drift remains.

### Attempt 3

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s1_try2_orig.png`, `out/rejected/map_v2_brittle_s0_orig.png`.

```text
Use case: precise-object-edit.
Final TOP-ONLY edit for BRITTLE stage1, a transparent1024x1024 sprite.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: stage1 edit target.
Input image4: original stage0, exact silhouette, front band and outline reference.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Keep the outside border, front band and position exactly as input4. Changes only on the top plate, no holes, unbroken silhouette. Do not reshape or scale the drum. Stage0 alpha will replace your alpha afterward.
Amber total is currently too low. Widen the BROWN-AMBER crack body regions by80%, without widening the glowing yellow cores. Target amber8.5% of total opaque sprite,10.5% of top. Fill expanded bodies with dim ochre#D09345, never dark black or grey. Keep glowing core total1.3%, never over2%. At least one crack spans the whole top; angular main cracks minimum24px.
Restore one large TOP-RIM chip inset at upper-right and one SMALL inset chip far away at lower-left. Both remain inside the original unbroken outer silhouette. No extra chips or fragments.
Reduce exposure of ONLY the grey-green top shell by0.7 stop. No white or pale specular marks. Upper-left rib highlight maximum#85877E; silica muted#76786E, rib shadows#4E544C. Preserve off-centre radial rib patch. Front band#33372F and outline#081A20 must stay identical to original stage0.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s1_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.557 bbox=102,83,1153,1157 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.890 amber=0.0852 amber_glow=0.0353 spread8=255
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s1_try3.png -1 -1 -1`
```text
map_v2_brittle_s1_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.556 bbox=83,67,941,945 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.871 amber=0.0847 amber_glow=0.0351 spread8=254
```


User-requested postprocessing: exact stage-0 alpha replacement (RGB untouched).
`powershell -ExecutionPolicy Bypass -File out/copy-stage0-alpha.ps1 out/map_v2_brittle_s1.png`
Stage-0 alpha copied exactly; changed_alpha_pixels=94091; RGB unchanged.

Final: out/map_v2_brittle_s1.png (attempt 3). Retained best after three attempts. Alpha replaced exactly with stage0 as requested; valid transparency and common silhouette. Correct separated top chips and spanning fracture. Deviations: inherited oversized stage0 mask; p99_noamber and amber_glow exceed limits; front-band RGB and rim lighting drifted despite top-only prompts. Attempt1 was brighter and attempt2 lacked sufficient amber and the large chip.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s1.png -1 -1 -1`
```text
map_v2_brittle_s1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.988 spread=255 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.875 amber=0.0853 amber_glow=0.0354 spread8=255
```

## 05 — map_v2_brittle_s2.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/map_v2_brittle_s1.png`, `out/map_v2_brittle_s0.png`.

```text
Use case: precise-object-edit.
Create BRITTLE stage2 by editing ONLY THE TOP of stage1. One1024x1024 sprite, true transparency.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: map_v2_brittle_s1, EDIT TARGET. Preserve its spatial registration.
Input image4: map_v2_brittle_s0, LOCKED mask, outline, front band and lighting reference.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
The plate is beginning to split, with exactly THREE main spanning angular fractures. Each travels across the whole top; irregular branches divide the ribbed plate into several large plates, no detached rubble, no holes. Preserve the off-centre rib origin and existing widely separated top chips. Main cracks24px minimum, secondary14px minimum.
Crack bodies#D09345 cover18..25% of the TOP, equivalent14..20% of the whole opaque sprite; aim17% overall. Glowing interior visible only within the widest cracks: thin continuous amber cores#F0B94E to#FFD27A on4..6% of TOP,3..5% overall, aim4% overall. Expanded crack bodies should be subdued ochre, NOT all bright yellow. No round filled glowing spots or bead-like granular light.
Silica#76786E, ribs#4E544C, front#33372F, outline#081A20 about13px. Dark muted shell; max non-amber channel148, at most158 on a specular area under1%. No white upper-left glare.
Keep the front band, outer silhouette, outline and lighting IDENTICAL to stage0. Do not touch the outer edge. Output alpha will be discarded and replaced by stage0 alpha. No shifting, no rotation, no changing scale. Solid band all the way to the base circle, no gap beneath the top.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s2_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.553 bbox=101,83,1153,1151 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.984 amber=0.1080 amber_glow=0.0412 spread8=255
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s2_try1.png -1 -1 -1`
```text
map_v2_brittle_s2_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.553 bbox=83,68,941,940 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.976 amber=0.1076 amber_glow=0.0406 spread8=254
```

Rejected attempt 1: amber0.1076 below0.14; p99_noamber0.976 too high (shell highlights and yellow cores outside amber hue definition). Glow0.0406 is within stage2 range. Source geometry slightly drifts.

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s2_try1_orig.png`, `out/map_v2_brittle_s0.png`.

```text
Use case: precise-object-edit.
Refine only the top of stage2. One1024x1024 transparent obstacle.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: current stage2 EDIT TARGET.
Input image4: stage0 locked outline, band and alpha reference.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Keep THREE spanning cracks and the splitting ribbed plate. Keep position, band and outer border unchanged and exactly aligned with stage0. Do not touch the outer edge; stage0 alpha will replace it.
Widen ONLY the dim amber body of the cracks by55%, growing into the shell. Aim17% of entire opaque sprite in amber crack bodies,22% of the top. Main fractures at least24px. Fill expanded fracture walls with solid warm ochre#D09345, not black. Preserve total glowing core coverage at4% overall (currently about4%). Cores must be WARM ORANGE-AMBER #F0B94E to#FFD27A; remove every lemon-yellow, white or green-yellow highlight. Continuous fine warm cores, no round spots.
Dim the grey-green silica shell strongly: no pale highlights anywhere. Flat muted upper plate #76786E, shaded ribs#4E544C. The absolute maximum grey-green channel is140. Keep chunky soft shading but no pale reflective glare, no pale edge lines. Dark band#33372F and dark outline#081A20 stay unchanged. Off-centre rib patch stays recognizable, no centred rosette.
No holes, no loose fragments, no floating pieces, no floor.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s2_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.588 bbox=86,69,1168,1171 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.804 amber=0.1441 amber_glow=0.0515 spread8=255
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s2_try2.png -1 -1 -1`
```text
map_v2_brittle_s2_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.587 bbox=70,56,953,956 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.796 amber=0.1439 amber_glow=0.0503 spread8=254
```

Rejected attempt 2: amber0.1439 passes but glow0.0503 marginally exceeds0.05, p99_noamber0.796 remains bright, source bbox70,56,953,956 enlarged.

### Attempt 3

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_s2_try2_orig.png`, `out/rejected/map_v2_brittle_s0_orig.png`.

```text
Use case: precise-object-edit.
Final stage2 correction: only top-plate colours and damage. Transparent1024x1024.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting.
Input image3: stage2 edit target.
Input image4: stage0 exact outer contour, band, registration and lighting reference.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Preserve the three spanning fracture paths and existing amber coverage from input3. Amber bodies should remain15..18% of total opaque art. Darken their non-core area to#D09345. Make glowing cores20% thinner, aiming4% of total art. Their brightest colour is warm#FFD27A, never pure yellow or white. No yellow haze or round glow spots.
Make the grey-green shell MUCH DARKER, with no light-coloured rim strokes or pale upper-left glare. Use a muted charcoal-grey-green palette: top#65695F to#76786E, rib recesses#4E544C. All non-amber channels below145. Preserve flowing ribs from the off-centre patch.
Restore image4's exact overall size and silhouette, do not enlarge the drum. Preserve its band and13px#081A20 outline. The front band, outer border and lighting outside the top must be identical to stage0. Stage0 alpha will replace output alpha. Continuous filled top and band, no holes or detached fragments.
Premium chunky mobile arena game art, soft 3D cel shading. Strictly inanimate organic material. No text, symbols, logos, labels, watermark, anatomy, animals, people, metal, chrome, machinery, ground, cast shadow, detached particles, or glow beyond the silhouette. No filled pale or saturated round dots or balls. Never two similar spots side by side. No copied template marks or reference scene. Isolated asset on true transparent alpha, with all empty areas alpha zero, no painted checkerboard.
```


Untouched output verification:
```text
map_v2_brittle_s2_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.583 bbox=90,70,1166,1168 p99_max=0.992 spread=255 key_px=0 checker=0.000 p99_any=0.992 p99_noamber=0.753 amber=0.1013 amber_glow=0.0380 spread8=255
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_s2_try3.png -1 -1 -1`
```text
map_v2_brittle_s2_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.583 bbox=74,57,952,953 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.745 amber=0.1011 amber_glow=0.0372 spread8=254
```


User-requested postprocessing: exact stage-0 alpha replacement (RGB untouched).
`powershell -ExecutionPolicy Bypass -File out/copy-stage0-alpha.ps1 out/map_v2_brittle_s2.png`
Stage-0 alpha copied exactly; changed_alpha_pixels=115831; RGB unchanged.

Final: out/map_v2_brittle_s2.png (attempt 2). Retained attempt2 after three tries for its three spanning fractures and amber progression. Exact stage0 alpha applied. Deviations: inherited oversized mask, non-amber highlights over0.62, glow near/slightly above0.05, band RGB and lighting not identical to stage0. Attempt1 had insufficient amber and attempt3 reduced amber again while losing a spanning branch.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s2.png -1 -1 -1`
```text
map_v2_brittle_s2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.804 amber=0.1531 amber_glow=0.0535 spread8=254
```

## 06 — map_v2_brittle_rubble.png

### Attempt 1

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/map_v2_brittle_s2.png`.

```text
Use case: stylized-concept.
Create a NEW image, one flat rubble decal on true transparency,1024x1024.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow. Only use its centre to measure a smaller radius346 region; do NOT make a circular drum.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting as the kit reference, with the explicit flat-decal override below: NO outline or height for rubble.
Input image3: map_v2_brittle_s2, MATERIAL REFERENCE ONLY. Use broken grey-green silica and rib fragments; do not copy the intact drum or its composition.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For THIS rubble slot, override raised-obstacle geometry: all fragments lie perfectly FLAT, seen directly overhead, no thickness, no side bands, no cast shadow, NO outline. An irregular low heap of EXACTLY9 clearly countable silica shards and curved rib fragments, all different sizes and orientations. Largest fragments sit lower-right of centre, sparse upper-left. No circular arrangement, no ring, no intact plate. Organic worn fragments with angular fracture boundaries and faint flowing diatom rib traces.
Keep every fragment inside radius346 around(512,512), safely within x160..864,y160..864. Leave large true-transparent gaps between shards. Fill shard interiors alpha255, fully OPAQUE; do not bake80% game opacity.
Low dark values: muted grey-green silica#555A50, ribs#3D443B, brightest mark#6D7468, no RGB channel above120 except a single faint ember. No pale highlights, no glossy glare. Exactly ONE faint thin INNER crack on one large central shard glows subdued amber#A07138; it stops well before that shard's edge. Total amber below1%, never over2%; no amber near any perimeter. No other embers or glowing fragments.
Premium chunky mobile arena game art, restrained soft shading. No text, symbols, logos, anatomy, people, animals, metal, chrome, machinery, balls, dots, paired similar spots, ground, floor wash, shadow, glow outside shards, painted checkerboard or template marks. Real transparent alpha outside all shards and in every gap. No outline.

```


User-requested postprocessing: exact stage-0 alpha replacement (RGB untouched).
`powershell -ExecutionPolicy Bypass -File out/copy-stage0-alpha.ps1 out/map_v2_brittle_s2.png`
Stage-0 alpha copied exactly; changed_alpha_pixels=92377; RGB unchanged.

Final: out/map_v2_brittle_s2.png (attempt 1). FINAL SELECTION SUPERSEDES preceding attempt2 selection: visual inspection after mask replacement showed attempt2 lost portions of its dark outline because its source was larger. Attempt1 better preserves the required continuous outline and three spanning cracks. Exact stage0 alpha applied. Deviations: amber below0.14, p99_noamber over0.62, inherited oversized mask, small band/RGB lighting drift. Hard outline rule takes priority; attempt3 also reduced amber and lost a spanning branch.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s2.png -1 -1 -1`
```text
map_v2_brittle_s2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.988 spread=255 key_px=2 checker=0.000 p99_any=0.988 p99_noamber=0.976 amber=0.1076 amber_glow=0.0406 spread8=255
```


User-requested postprocessing: exact stage-0 alpha replacement; newly exposed unpainted edge RGB restored from stage0 to avoid hidden matte colours. Generated painted RGB is retained.
`powershell -ExecutionPolicy Bypass -File out/copy-stage0-alpha.ps1 out/map_v2_brittle_s1.png`
Stage-0 alpha copied exactly; changed_alpha_pixels=94091; only newly exposed unpainted edge RGB restored from stage0.

Final: out/map_v2_brittle_s1.png (attempt 3). Final stage1: best of three, stage0 alpha exact, newly exposed edge colours from stage0. Amber coverage passes. Deviations: oversized inherited mask; shell brightness and glow exceed caps; side-band RGB and rim light drift from stage0. Alternatives were brighter or missing the large chip and enough amber.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s1.png -1 -1 -1`
```text
map_v2_brittle_s1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.875 amber=0.0853 amber_glow=0.0354 spread8=254
```


User-requested postprocessing: exact stage-0 alpha replacement; newly exposed unpainted edge RGB restored from stage0 to avoid hidden matte colours. Generated painted RGB is retained.
`powershell -ExecutionPolicy Bypass -File out/copy-stage0-alpha.ps1 out/map_v2_brittle_s2.png`
Stage-0 alpha copied exactly; changed_alpha_pixels=92377; only newly exposed unpainted edge RGB restored from stage0.

Final: out/map_v2_brittle_s2.png (attempt 1). Final stage2: attempt1 retained for continuous outline and three spanning cracks; stage0 alpha exact, newly exposed edge colours from stage0. Glow coverage passes. Deviations: inherited oversized mask, amber coverage below0.14, shell/core hues cause high p99_noamber, slight band RGB and lighting drift. Attempt2 lost outline when masked; attempt3 lacked a spanning branch.

`powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_s2.png -1 -1 -1`
```text
map_v2_brittle_s2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.552 bbox=81,68,942,936 p99_max=0.988 spread=254 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.976 amber=0.1076 amber_glow=0.0406 spread8=254
```


Untouched output verification:
```text
map_v2_brittle_rubble_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.255 bbox=146,163,1138,1108 p99_max=0.702 spread=198 key_px=0 checker=0.000 p99_any=0.698 p99_noamber=0.690 amber=0.0037 amber_glow=0.0005 spread8=198
```

Candidate verification:
`powershell -ExecutionPolicy Bypass -File verify.ps1 out/rejected/map_v2_brittle_rubble_try1.png -1 -1 -1`
```text
map_v2_brittle_rubble_try1.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.255 bbox=119,133,929,905 p99_max=0.698 spread=201 key_px=0 checker=0.000 p99_any=0.698 p99_noamber=0.686 amber=0.0037 amber_glow=0.0005 spread8=201
```

Rejected attempt 1: corner_a1, oversized bbox119,133,929,905, p99_noamber0.686 exceeds0.47, visible bevel thickness. Count9 and amber0.0037 were appropriate.

### Attempt 2

References (ordered): `ref/template_v2.png`, `out/map_v2_mucus_blob.png`, `out/rejected/map_v2_brittle_rubble_try1_orig.png`, `out/map_v2_brittle_s2.png`.

```text
Use case: precise-object-edit and background-extraction.
Correct one FLAT silica rubble decal,1024x1024 transparent.
Input image1: template_v2, measurement guide; reproduce none of its lines, colours or arrow. Use only centre512,512 and an inner radius346 boundary.
Input image2: map_v2_mucus_blob, KIT ANCHOR: match its material, outline weight and lighting for the kit; this decal explicitly has NO outline and NO height.
Input image3: rubble EDIT TARGET. Keep EXACTLY9 fragments and their asymmetrical arrangement.
Input image4: map_v2_brittle_s2, material reference only; do not copy drum geometry.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Flat decal override: overhead orthographic flakes lying flat, no raised bevels, no thickness, no side band, no dark outlines, no cast shadow.
Shrink the whole9-piece arrangement about its centre by18%, leaving broad clear margins; every visible fragment stays inside circle centre512,512 radius346 and bbox160..864 in both axes. The large fragments remain weighted lower-right. True transparent gaps; do not create a ring.
The shards are FAR TOO BRIGHT. Make all silica RGB approximately55% as bright as input3, a dark charcoal grey-green. Body#41483E, faint rib marks#555C50, brightest non-amber channel100. No light-coloured bevel rims or speculars. Single faint inner amber crack only, below1% coverage, no amber near any shard perimeter.
Shard interiors fully opaque alpha255, not translucent. Remove all background residue to exactly alpha0, including all four corners. Empty spaces between shards remain exactly alpha0.
No text, symbols, anatomy, people, animals, metal, chrome, balls, dots, paired similar shapes, painted checkerboard, ground or template marks. No outline.

```


## 2-ci iş (2026-10-17 23:42 – 10-18 00:13) — slot 6–12

> Codex 12-ci slotda limitə düşdü (bərpa 10-18 04:42). Finallar Codex-indir, clutter-dən başqa: clutter = try1, Claude qəbul etdi — dörd parça düzgündür, hərəsi öz hücrəsindədir, dəyər 0.38, amma r 200-dən böyükdür (pipeline hücrəni kiçildir). Kənarlaşma: rim_north-un sol/sağ kənarı uyğun gəlmir (orta fərq ~25/255) — pipeline-ın tikiş düzəlişi lazımdır. Qalan: slot 13 (kaustika).

# Pond Drop V2 — resumed run, slots 6–13

Slots 1–5 were previously approved and are not regenerated or modified. The supplied kit anchor is `ref/map_v2_mucus_blob.png`; the supplied stage-2 material reference is `ref/map_v2_brittle_s2.png`.

Method: built-in `image_gen`, one asset per call, sequential slot order. All generation prompts, reference images, untouched checks, exact-size final checks, and deviations are recorded below as work proceeds. Only the supplied proportional `resize.ps1` is used for size normalization.

The pillar projection sentence is retained verbatim in every obstacle call. Slot-specific requirements take precedence: rubble and bush base are flat, the canopy has a hollow, and the vent is recessed.


## Slot 6 — rubble

### Try 1 — generation

References: `ref/template_v2.png`, `ref/map_v2_mucus_blob.png`, `ref/map_v2_brittle_s2.png`.

```text
Use case: stylized-concept.
Asset: slot 6, map_v2_brittle_rubble.png, ONE 1024x1024 transparent game decal.
Input images in order: (1) ref/template_v2.png = measurement guide; reproduce none of its lines, colours or arrow. This slot uses only its centre coordinate, NOT its raised geometry. (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting for the kit; the specific rubble rule overrides outline and gloss: NO outline, matte and flat. (3) ref/map_v2_brittle_s2.png = silica material and broken rib reference ONLY, never copy its disc, volume, orange network or arrangement.
Kit projection sentence, supplied verbatim for consistency; this FLAT DECAL is explicitly the zero-height exception:
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
RUBBLE OVERRIDE: perfectly overhead plan view of completely FLAT, wafer-thin silica shards lying flush on an invisible floor. Show their upper surfaces ONLY. Zero visible thickness, zero side bands, zero bevels, zero extruded edges, zero drop shadows, zero relief. Fine curved diatom rib marks are painted tonal marks, not raised ridges.
Composition: exactly NINE distinct shards and rib fragments of clearly different sizes in one irregular close heap, weighted lower-right of (512,512). Have shards through the central region and the largest pieces at lower-right. Unequal narrow transparent gaps separate the nine pieces. No circular arrangement, no wreath, no radial symmetry, no perimeter ring. Every painted pixel stays within radius 346 of (512,512); bounding box within x160..864 and y160..864, aim x210..815,y225..825. Smallest shard at least 40 px. Large broad broken plates mixed with slender curved rib fragments.
Color: very dull dark grey-green silica, main #55594F, rib marks #454B42, brightest material #707466. ABSOLUTE MAXIMUM of every RGB channel is 119/255 (0.467), including all edges and accents. No bright highlights. Exactly ONE faint short inner crack ember colored muted ochre #77562E, entirely deep inside a central shard, occupying under 1% of painted area; no amber along any shard edge, no bright core, no light emission.
All shard interiors are fully opaque alpha 255. Only antialiased boundaries may soften. The game applies opacity later. The rest, including every inter-shard gap, is true alpha zero, not a dark background or a checkerboard.
Style: premium chunky mobile arena game art, soft simplified painted material, readable at 64 px. No outlines of any color.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this flat decal keep that light extremely subtle and diffuse; it must never create side planes or thickness.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 untouched check: `size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.366 bbox=216,167,1176,1142 p99_max=0.518 spread=58 key_px=0 checker=0.000 p99_any=0.518 p99_noamber=0.518 amber=0.0002 amber_glow=0 spread8=58`.

Try 1 after proportional resize: `size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.365 bbox=177,136,960,933 p99_max=0.514 spread=60 key_px=0 checker=0.000 p99_any=0.514 p99_noamber=0.514 amber=0.0002 amber_glow=0 spread8=60`.

Rejected try 1: its heap exceeded the bounds and its p99 material value exceeded 0.47.

### Try 2 — size and value edit

References: the same three references, then `out/rejected/map_v2_brittle_rubble_try1.png` as edit target.

```text
Use case: precise-object-edit. Output ONE 1024x1024 transparent game decal.
Inputs in order: image 1 ref/template_v2.png = measurement guide; reproduce none of its lines, colours or arrow; image 2 ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, with this slot's mandatory no-outline exception; image 3 ref/map_v2_brittle_s2.png = silica material reference only; image 4 out/rejected/map_v2_brittle_rubble_try1.png = EDIT TARGET.
Keep the target's exactly nine flat shards, irregular heap, unequal sizes, painted curved rib marks and single dull interior amber crack. Correct only overall placement/size and material values.
Reduce the entire heap to 70% of its current width and height, place the heap's centre at (540,535) of the 1024x1024 canvas. Leave wide TRANSPARENT margins. Keep every painted pixel inside radius 320 from (512,512), bbox inside x190..834,y190..834. The heap remains fuller lower-right, with shards filling the centre, never a ring.
Darken every material color by 25%, so normal silica lies around #45483F and its brightest marks around #606357; ABSOLUTE MAXIMUM RGB channel 115/255 including highlights and the single faint ember. Do not normalize brightness or auto-brighten. All shard interiors must have alpha 255, not semitransparency; gaps and background alpha 0.
Mandatory common kit projection sentence follows; this rubble remains the zero-height FLAT exception:
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
Perfect straight-down flat decal; only upper surfaces are visible, no thickness, no bevels, no side planes, no extrusion, no raised ridges, no dark edge strokes. No outline at all. No shadow or ground.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Only subtle diffuse color variation for this flat matte material; do not imply height.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 2 checks:

```text
map_v2_brittle_rubble_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.195 bbox=313,284,1008,1034 p99_max=0.565 spread=86 key_px=0 checker=0.000 p99_any=0.565 p99_noamber=0.565 amber=0.0010 amber_glow=0.0000 spread8=86
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_brittle_rubble_try2.png (1024x1024)
map_v2_brittle_rubble_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.194 bbox=256,232,823,844 p99_max=0.561 spread=79 key_px=0 checker=0.000 p99_any=0.561 p99_noamber=0.561 amber=0.0009 amber_glow=0.0000 spread8=79

```


Rejected try 2: value rose to 0.561 and one corner pixel had alpha 1, despite corrected bounds.

### Try 3 — dark palette and alpha cleanup

References: `ref/map_v2_mucus_blob.png`, `ref/map_v2_brittle_s2.png`, then `out/rejected/map_v2_brittle_rubble_try2.png` as edit target.

```text
Use case: background-extraction and precise-object-edit.
Output ONE transparent 1024x1024 PNG decal.
Inputs: (1) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, except this flat rubble has no outline and no shine; (2) ref/map_v2_brittle_s2.png = diatom rib material reference ONLY; (3) out/rejected/map_v2_brittle_rubble_try2.png = EDIT TARGET.
Preserve the target's nine shard silhouettes, exact smaller scale and positions, irregular heap with a full centre and lower-right weight. Change only their painted colors and clean the transparent background.
Repaint the silica as VERY DARK matte charcoal olive-grey. Use ONLY these three silica shades: #30352E, #3A4036, #484E42. These are display RGB colors, not colors to brighten under illumination. Broad flat color shapes with subdued curved rib marks; remove every pale highlight. No pixel of silica may exceed RGB 85,85,85, even at edges. Keep the one interior ember crack but darken it to #70502C. No other amber. The output must look dark and subdued against a medium grey viewer. No brightness normalization.
Remove ALL background and all faint alpha haze. Every background pixel, including corners, margins and gaps, must be exact alpha 0. Every shard interior must be exact alpha 255. Do not paint a black background. Preserve real transparency.
No raised material: these are flush flat broken sheets with only upper surfaces visible. Rib marks are flat strokes with no bevel or shadow. No outlines, side bands, thickness, side planes, extrusion, shadows, ground or external glow. Keep all artwork inside x250..830,y225..850 and radius346 from (512,512). Do not enlarge.
Verbatim common kit projection sentence, NOT applied to this zero-height rubble exception:
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For the flat matte decal, apply the light ONLY as a very slight shift among the three dark shades above.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 3 checks:

```text
map_v2_brittle_rubble_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.294 bbox=233,201,1094,1118 p99_max=0.380 spread=71 key_px=0 checker=0.000 p99_any=0.376 p99_noamber=0.380 amber=0.0000 amber_glow=0.0000 spread8=77
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_brittle_rubble_try3.png (1024x1024)
map_v2_brittle_rubble_try3.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.294 bbox=190,164,893,913 p99_max=0.376 spread=73 key_px=0 checker=0.000 p99_any=0.376 p99_noamber=0.376 amber=0.0000 amber_glow=0.0000 spread8=73

```


**Selected after three tries: try 3, best candidate with deviations, not a full gate pass.** It preserves nine flat upper-only shards, irregular central heap and subdued values. Remaining deviations: bbox right 893/bottom 913 exceed 864, faint corner alpha 1/255, and shard interiors are near-opaque (centre alpha 253) rather than all 255. Amber is so dull it falls below the verifier's amber threshold. Try 1 has clean zero corners but is much larger and over the value cap; try 2 is too bright. No more rubble calls, per the three-try limit.

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_brittle_rubble.png`

```text
map_v2_brittle_rubble.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.294 bbox=190,164,893,913 p99_max=0.376 spread=73 key_px=0 checker=0.000 p99_any=0.376 p99_noamber=0.376 amber=0.0000 amber_glow=0.0000 spread8=73

```


## Slot 7 — bush base

### Try 1 — generation

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`.

```text
Use case: stylized-concept.
Asset: ONE 1024x1024 true transparent sprite, map_v2_bush_base.png.
Inputs: (1) ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow. Use ONLY the green dashed circle radius365 centred at (512,512) for this base. The white hollow belongs to the later canopy; this base has a fully filled centre. (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting for overall kit cohesion, with the mandatory bush exception: NO outline, NO glossy rim, NO height.
Paint a perfectly flat dark olive-teal algae filament mat seen straight overhead. A soft roughly circular carpet of loosely interwoven algae, saturated only moderately, fuzzy organic edge. Entire mat diameter about 720px = 70% of canvas width, centred exactly on the canvas, generous empty margins about150px on ALL four sides. All painted wisps inside the circle radius365 from (512,512), with absolute bbox within x140..884,y140..884. Do not expand to fill the canvas.
Palette: shadow #1F4A3D, body #2C6652, sparse lighter filament areas #3F8A70; brightest channel at most 150/255. Dark olive-teal throughout, never lime or mint. Subtle broad matte filament texture, no dots, flowers, beads or separate round elements. The centre is solid opaque alpha255, not a ring or hollow. Alpha0 outside the mat, all four corners and margins exactly alpha0 with no haze. Soft antialiasing is confined to its fuzzy edge.
The base is flush to the invisible floor: no side band, thickness, mound, cylindrical volume, rim, outline, cast shadow or surrounding ground. Simplified premium chunky mobile arena game art, broad readable texture.
Common kit projection sentence supplied unchanged, but this flat base is expressly a zero-height exception:
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this base keep lighting diffuse and very restrained, without embossed strands or specular marks.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 checks:

```text
map_v2_bush_base_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.417 bbox=141,145,1114,1108 p99_max=0.529 spread=72 key_px=0 checker=0.000 p99_any=0.525 p99_noamber=0.529 amber=0.0000 amber_glow=0.0000 spread8=113
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_base_try1.png (1024x1024)
map_v2_bush_base_try1.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.417 bbox=116,118,909,904 p99_max=0.529 spread=72 key_px=0 checker=0.000 p99_any=0.525 p99_noamber=0.529 amber=0.0000 amber_glow=0.0000 spread8=85

```


Rejected try 1: oversized bbox and faint corner alpha after resize.

### Try 2 — shrink and clean margins

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`, `out/rejected/map_v2_bush_base_try1.png` (edit target).

```text
Use case: precise-object-edit and background-extraction.
Output ONE 1024x1024 true transparent PNG, flat algae mat.
Inputs in order: image1 ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow. Image2 ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting with the required bush NO-outline exception. Image3 out/rejected/map_v2_bush_base_try1.png = EDIT TARGET.
Keep exactly the target's dark olive-teal palette, matte flat filament carpet, filled opaque centre, soft irregular circular edge. Correct ONLY its size and background cleanup: make the mat 80% of its current diameter, centred at exactly (512,512). Every painted filament and fuzz pixel must be confined inside radius345, and x167..857,y167..857. Preserve ample entirely empty transparent margins. Do not enlarge it or add new wisps outside.
Clean-cut transparent PNG: every pixel outside that radius must have alpha EXACTLY ZERO, not 1, no fine haze, no almost-transparent noise; all four corners and margins are empty. Inside the continuous mat, including (512,512), alpha255. Only mat edge antialiasing may soften.
Body #1F4A3D to #3F8A70, max channel below158/255; keep existing colors and subdued contrast. Do not brighten. No outline or border, no glossy rim, no thickness, no height, no cylindrical shape, no hole, no round dots, no beads, no flowers.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
The preceding shared kit projection sentence is preserved verbatim; this FLAT base is expressly the zero-height exception and has no band.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Soft diffuse light only, no embossed texture, no ground or cast shadow.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 2 checks:

```text
map_v2_bush_base_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.325 bbox=197,221,1051,1067 p99_max=0.604 spread=74 key_px=0 checker=0.000 p99_any=0.600 p99_noamber=0.604 amber=0.0000 amber_glow=0.0000 spread8=85
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_base_try2.png (1024x1024)
map_v2_bush_base_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.325 bbox=161,181,858,871 p99_max=0.604 spread=75 key_px=0 checker=0.000 p99_any=0.600 p99_noamber=0.604 amber=0.0000 amber_glow=0.0000 spread8=85

```


Try 2 meets bounds and p99 gate but corner alpha is 1; requesting the prescribed background-extraction edit.

### Try 3 — background extraction

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`, `out/rejected/map_v2_bush_base_try2.png` (edit target).

```text
Use case: background-extraction.
Edit target: image 3 out/rejected/map_v2_bush_base_try2.png. Supporting inputs: image1 ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow; image2 ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, except this bush base must remain unoutlined.
Preserve the target's exact flat algae mat, size, placement, colour values and texture. DO NOT regenerate or restyle the mat. Correct only the alpha channel: remove every trace of background haze, ensure every background pixel, especially the four 64x64 corner blocks, has exactly alpha0. Make the mat interior opaque alpha255. Keep the clean fuzzy boundary. True transparent PNG, not a checkerboard, not a black background. Output 1024x1024. Mat bbox remains x161..858,y181..871, no expansion. Colour maximum stays at or below158/255, no brightening.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
This flat base is the zero-height exception: no band, outline, side plane, height, cast shadow or ground.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Preserve the target's existing subdued lighting unchanged.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 3 checks:

```text
map_v2_bush_base_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.360 bbox=178,202,1070,1085 p99_max=0.706 spread=87 key_px=0 checker=0.000 p99_any=0.706 p99_noamber=0.706 amber=0.0000 amber_glow=0.0000 spread8=102
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_base_try3.png (1024x1024)
map_v2_bush_base_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=253 opaque=0.359 bbox=146,165,874,885 p99_max=0.706 spread=88 key_px=0 checker=0.000 p99_any=0.706 p99_noamber=0.706 amber=0.0000 amber_glow=0.0000 spread8=102

```


**Selected after three tries: try 2, best candidate with a tiny alpha deviation.** Bbox and p99 pass; centre alpha253 passes. Remaining deviation: corner_a=1 instead of0 (near-transparent residual). Try3 fixed that but raised p99 to0.706, so the darker, correctly bounded try2 was retained. No further calls per the quality-loop limit.

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_bush_base.png`

```text
map_v2_bush_base.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=253 opaque=0.325 bbox=161,181,858,871 p99_max=0.604 spread=75 key_px=0 checker=0.000 p99_any=0.600 p99_noamber=0.604 amber=0.0000 amber_glow=0.0000 spread8=85

```


## Slot 8 — bush canopy

### Try 1 — generation

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`, `ref/mockup_crop_v2.png`, `out/map_v2_bush_base.png` (palette only).

```text
Use case: stylized-concept. Output ONE 1024x1024 true transparent game sprite: map_v2_bush_canopy.png.
Input roles in order: (1) ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow. (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting; bush exception NO outlines. (3) ref/mockup_crop_v2.png = style reference only; do not copy the scene. (4) out/map_v2_bush_base.png = palette reference only, do not copy its solid mat.
Draw exactly SEVENTEEN broad twisting ribbon-like pondweed strands, some with spiral curls, forming a loose asymmetric canopy around an EMPTY transparent central hollow. Roots at least40px wide, rooted on an invisible ring radius230 around(512,470). No drawn root ring. Match the plant style in the crop with fewer broader readable strands.
White guide disc radius134 around(512,470) stays at least90% transparent, including its centre. NO mat beneath, no opaque interior disc. The canopy's central hollow and all spaces between ribbons reveal transparency.
Main strands spread sideways and downward, reaching the south footprint edge around y890..898. Keep at least one broad bottom strand there. Only THREE sparse thin-tipped fronds rise above y128 into the northern pale guide zone; northmost tip near y90. Width stays x140..884, with untouched transparent side margins. Do not exceed x120..904. The 17 strands have irregular lengths, twists, bends and spacing; avoid uniform radial symmetry.
Dark pondweed palette: body #3F8A70, tips #519C82, shadow #1F4A3D. No channel may exceed158/255, no bright white specular, lime, mint or yellow-green. Soft 3D cel shading, premium chunky mobile arena game art. No outline at all; soft frond silhouettes without dark edge strokes. No dots, flowers, round beads, paired marks or extra small strands.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
That common kit sentence establishes the kit camera; this canopy has no solid cap or cylinder, only the ribbons and a transparent hollow.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Real RGBA transparency: background, corner blocks, margins and hollow alpha EXACTLY0; opaque fronds. No almost-transparent haze.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 checks (hollow measured only after normalization):

```text
map_v2_bush_canopy_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.384 bbox=104,50,1158,1214 p99_max=0.780 spread=97 key_px=0 checker=0.000 p99_any=0.780 p99_noamber=0.780 amber=0.0000 amber_glow=0.0000 spread8=128
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_canopy_try1.png (1024x1024)
map_v2_bush_canopy_try1.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=0 opaque=0.384 bbox=85,41,945,991 p99_max=0.780 spread=98 key_px=0 checker=0.000 p99_any=0.776 p99_noamber=0.780 amber=0.0000 amber_glow=0.0000 spread8=114 hollow_a=0.364

```


Rejected try1: oversized, too bright (0.780), hollow coverage0.364 exceeds0.30, and faint corner alpha1.

### Try 2 — bounds, hollow, and value correction

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`, `out/map_v2_bush_base.png`, `out/rejected/map_v2_bush_canopy_try1.png` (edit target).

```text
Use case: precise-object-edit.
ONE 1024x1024 true transparent game sprite. Input roles: (1) ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow; (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, with bush NO-outline exception; (3) out/map_v2_bush_base.png = dark palette reference; (4) out/rejected/map_v2_bush_canopy_try1.png = EDIT TARGET.
Keep the flowing twisted pondweed style and asymmetric lower-heavy composition, but correct three measured defects:
1. SHRINK the canopy to85% of its present width and height about the canvas centre. Final extent should be x145..880,y110..920, with a bottom ribbon reaching y890..920. All four corners alpha0. Keep broad40px+ roots. Seventeen distinct major ribbon strands total, varied curls, no extra tiny tendrils.
2. Move/expand the transparent opening so a full circle radius150 centred at(512,470) is CLEAR ALPHA0. A few tips may enter its outermost10px but at least90% of the circle stays empty. Remove the upper-inner cross-ribbon that covers the guide hollow. Hollow is not painted black. No mat beneath.
3. Repaint all ribbons substantially DARKER and less glossy: shadow #173D30, body #285E4B, illuminated tips #3E7C63. Brightest channel must remain below135/255. No pale, light mint, yellowish or white highlights anywhere. Do not brighten the reference colors under the lighting.
No border stroke or dark outline. No flowers, round dots, beads, ground, cast shadow or glow. Preserve true transparency, all background and inter-strand spaces exactly alpha0 without haze.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
This canopy is an open arrangement of ribbons with no solid drum.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Restrained light, only subtle dark-green shade shifts, no specular shine.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 2 checks:

```text
map_v2_bush_canopy_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.333 bbox=120,99,1144,1163 p99_max=0.651 spread=75 key_px=0 checker=0.000 p99_any=0.651 p99_noamber=0.651 amber=0.0000 amber_glow=0.0000 spread8=107
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_canopy_try2.png (1024x1024)
map_v2_bush_canopy_try2.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.333 bbox=98,81,934,949 p99_max=0.651 spread=75 key_px=0 checker=0.000 p99_any=0.651 p99_noamber=0.651 amber=0.0000 amber_glow=0.0000 spread8=85 hollow_a=0.166

```


Try2 passes alpha and hollow but width is too large and p99=0.651 exceeds0.62.

### Try 3 — final scale and darkness correction

References: `ref/template_bush.png`, `ref/map_v2_mucus_blob.png`, `out/map_v2_bush_base.png`, `out/rejected/map_v2_bush_canopy_try2.png` (edit target).

```text
Use case: precise-object-edit. ONE true transparent 1024x1024 PNG.
Inputs: image1 ref/template_bush.png = measurement guide; reproduce none of its lines, colours or arrow. Image2 ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, but bush has NO outline. Image3 out/map_v2_bush_base.png = palette reference. Image4 out/rejected/map_v2_bush_canopy_try2.png = EDIT TARGET.
Make exactly TWO changes to the target:
- Scale the entire existing canopy down to90% of its current width and height, about(512,512), without cropping. Final bbox about x140..892,y124..906. Keep the lowest strand reaching y890 or lower. Do not change the hole or add fronds.
- Darken the RGB values of every painted strand by20%. This must be an actual visibly darker result: brightest highlights at most #42785E (max120/255), deep olive-teal shadows #17392D. No bright mint strokes.
Preserve the target's clean alpha0 corners, clear central hollow around(512,470), twisting broad17 major ribbons, irregular composition and exact absence of outlines. The whole radius134 hollow stays at least75% transparent. No opaque mat. True alpha0 in all background and gaps, no haze. Opaque fronds.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
This is the open plant canopy exception with no solid cap or side band.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Preserve subdued existing lighting while darkening it.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 3 checks:

```text
map_v2_bush_canopy_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.298 bbox=156,138,1115,1132 p99_max=0.608 spread=54 key_px=0 checker=0.000 p99_any=0.608 p99_noamber=0.608 amber=0.0000 amber_glow=0.0000 spread8=85
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_bush_canopy_try3.png (1024x1024)
map_v2_bush_canopy_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.297 bbox=127,112,910,924 p99_max=0.608 spread=56 key_px=0 checker=0.000 p99_any=0.604 p99_noamber=0.608 amber=0.0000 amber_glow=0.0000 spread8=85 hollow_a=0.246

```


**Selected try3: passes with allowed geometry tolerance.** Alpha and hollow0.246 pass; p99=0.608 passes. Right edge910 is6px beyond904, within STYLE_MAP's8px tolerance. Bottom reaches924 (gate requires at least880). Seventeen major strand forms were requested; overlapping curls make their exact visual count less certain than the alpha metrics. No further edits.

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_bush_canopy.png 512 470 134`

```text
map_v2_bush_canopy.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.297 bbox=127,112,910,924 p99_max=0.608 spread=56 key_px=0 checker=0.000 p99_any=0.604 p99_noamber=0.608 amber=0.0000 amber_glow=0.0000 spread8=85 hollow_a=0.246

```


## Slot 9 — vent base

### Try 1 — generation

References: `ref/template_vent.png`, `ref/map_v2_mucus_blob.png`.

```text
Use case: stylized-concept. ONE 1024x1024 true transparent game sprite, map_v2_vent_base.png.
Inputs in order: (1) ref/template_vent.png = measurement guide; reproduce none of its lines, colours or arrow. Its red circle centre(512,512),radius384 marks the OUTER lip; blue circle marks the dark bottom of the depression, grey hatched region its inner wall. (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting for the kit; vent exception: NO dark outline and the volume is recessed.
Subject: a round BUBBLER SPRING hole recessed into olive pond silt, viewed almost directly overhead. Perfect circular outer silhouette centred(512,512), diameter768px, exactly three-quarters of canvas width. Leave128px completely transparent margins on all four sides. No painted silt or shadow outside the circular lip.
Lip: thin organic olive-silt edge #2B3023, bearing exactly NINE warm AMBER curved dashes #F0B94E sitting on the radius384 circumference. Each dash is24-28px thick and varies in arc length, about90-155px long, with clearly visible unequal gaps. These are curved strokes, not dots or balls. Count nine only; no extra gold speckles, no dark outline. Amber total target5% of opaque sprite. No glow outside silhouette.
Inner wall slopes inward, widest at the north edge as the template shows: UPPER-LEFT INNER WALL deeply SHADOWED #182218; LOWER-RIGHT INNER WALL softly LIT #3A4434. The upper rim itself receives light upper-left. The dark opaque throat #070B08 is centred around(512,539), slightly south of the footprint centre. Clear concavity: this is a hole, not a mound or bowl standing above the ground. No painted bubbles, rings, dots, stones, plants or objects inside.
General kit projection sentence, verbatim:
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
VENT OVERRIDE: apply the same near-overhead camera to a RECESSED hole; the visible band is its INSIDE wall, never an outer raised drum band.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Except amber, keep all body colors below148/255, soft simplified cel shading, premium chunky mobile arena game art. The entire interior including the central throat is opaque alpha255. Outside the circle is true alpha0, clean empty corner blocks and margins, no haze, no checkerboard.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 checks:

```text
map_v2_vent_base_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=252 opaque=0.505 bbox=118,102,1135,1111 p99_max=0.969 spread=222 key_px=0 checker=0.000 p99_any=0.969 p99_noamber=0.580 amber=0.0543 amber_glow=0.0509 spread8=222
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_vent_base_try1.png (1024x1024)
map_v2_vent_base_try1.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=252 opaque=0.505 bbox=97,83,926,907 p99_max=0.965 spread=214 key_px=0 checker=0.000 p99_any=0.965 p99_noamber=0.580 amber=0.0545 amber_glow=0.0502 spread8=214

```


Try1 has exactly nine dashes, correct amber share and acceptable non-amber values, but is oversized and has corner alpha1.

### Try 2 — registration and alpha correction

References: `ref/template_vent.png`, `ref/map_v2_mucus_blob.png`, `out/rejected/map_v2_vent_base_try1.png` (edit target).

```text
Use case: precise-object-edit and background-extraction.
Output ONE true transparent 1024x1024 PNG.
Inputs: (1) ref/template_vent.png = measurement guide; reproduce none of its lines, colours or arrow; (2) ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting with the vent exception of NO dark outline; (3) out/rejected/map_v2_vent_base_try1.png = EDIT TARGET.
Preserve the target's EXACTLY NINE separated amber lip dashes, their shapes and colors, its dark concave throat and its inner-wall shading. Change ONLY registration and transparency:
Scale the circular sprite to92% of its current diameter, keeping it a perfect circle, then centre its outer circle exactly at(512,512). Its final outer radius384 means bbox x128..896,y128..896. Leave equal transparent margins128px on all sides. Do not add a raised outer band or an outline. No art beyond that circumference.
Remove all near-transparent background haze. All background, margins and corner blocks alpha EXACTLY0. Interior opaque alpha255. Preserve all existing RGB colors, especially the subtle olive rim, without brightening or sharpening. Non-amber p99 must remain below0.62; keep amber share about5%.
The dark opaque throat stays slightly south of centre near(512,539), inner wall shadowed upper-left, softly lit lower-right. No painted bubbles or new details.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
Vent exception: it is a depression, so the wall is INSIDE the hole, never an outward cylinder.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Keep the target's existing light unchanged.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 2 checks:

```text
map_v2_vent_base_try2_orig.png: size=1254x1254 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=252 opaque=0.461 bbox=146,132,1107,1102 p99_max=0.988 spread=238 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.663 amber=0.0566 amber_glow=0.0536 spread8=238
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_vent_base_try2.png (1024x1024)
map_v2_vent_base_try2.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=252 opaque=0.461 bbox=119,108,904,900 p99_max=0.984 spread=230 key_px=0 checker=0.000 p99_any=0.984 p99_noamber=0.663 amber=0.0568 amber_glow=0.0528 spread8=230

```


Try2 fixes registration within tolerance but non-amber p99 rose to0.663; corner alpha1 remains.

### Try 3 — darken silt and extract background

References: `ref/template_vent.png`, `ref/map_v2_mucus_blob.png`, `out/rejected/map_v2_vent_base_try2.png` (edit target).

```text
Use case: precise-object-edit and background-extraction. Output ONE1024x1024 transparent PNG.
Inputs: image1 ref/template_vent.png = measurement guide; reproduce none of its lines, colours or arrow. Image2 ref/map_v2_mucus_blob.png = KIT ANCHOR, match its material, outline weight and lighting, with vent NO-dark-outline exception. Image3 out/rejected/map_v2_vent_base_try2.png = EDIT TARGET.
PRESERVE target scale, position, circular outer silhouette, concave dark throat, and EXACTLY NINE separate amber dashes. No enlargement or new details.
Only correct the too-bright olive material and background alpha:
Repaint the olive lip and interior wall DARKER by30%. Lip #263021, dark wall #151E15, lit inner wall lower-right #3A4434. Absolutely no pale cream or white material highlights. Except the nine amber dashes, every RGB channel must stay below125/255. Keep the amber dashes at #F0B94E, unchanged shapes, no additional amber. Keep shadowed upper-left inside wall and softly lit lower-right inside wall.
Clean all empty background pixels to alpha EXACTLY0, including four corner blocks, margins and every pixel beyond the circular silhouette. Interior fully opaque alpha255 including dark throat #070B08. No haze or invisible speckles.
Seen from almost straight above, like a low pillar: its top is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90).
This recessed vent is the hole exception: its band is an inner wall, not a raised exterior band.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Subtle restrained lighting only; no specular strokes on the silt.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 3 checks:

```text
map_v2_vent_base_try3_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=252 opaque=0.509 bbox=125,96,1127,1133 p99_max=0.988 spread=247 key_px=0 checker=0.000 p99_any=0.988 p99_noamber=0.525 amber=0.0539 amber_glow=0.0512 spread8=247
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_vent_base_try3.png (1024x1024)
map_v2_vent_base_try3.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=252 opaque=0.508 bbox=102,79,920,925 p99_max=0.984 spread=236 key_px=0 checker=0.000 p99_any=0.984 p99_noamber=0.522 amber=0.0540 amber_glow=0.0506 spread8=236

```


**Selected after three tries: try2, best candidate with deviations.** It preserves the unoutlined recessed lip and exactly nine dashes; bbox is within1px tolerance of the general gate. Deviations: corner alpha1, p99_noamber0.663 above0.62. Try1 was oversized. Try3 meets values and alpha but adds a dark exterior bottom band and expands the bounds, so it was rejected on outline/projection priority. The general front-band check is interpreted as the vent's inner wall, per its specific brief.

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_vent_base.png`

```text
map_v2_vent_base.png: size=1024x1024 format=Format32bppArgb corner_a=1 a8=0 aw8=0 centre_a=252 opaque=0.461 bbox=119,108,904,900 p99_max=0.984 spread=230 key_px=0 checker=0.000 p99_any=0.984 p99_noamber=0.663 amber=0.0568 amber_glow=0.0528 spread8=230

```


## Slot 10 — floor macro

### Try 1 — generation

References: none; new opaque floor texture. Slot-specific plan view and flat illumination apply.

```text
Use case: stylized-concept.
Asset: ONE opaque1024x1024 floor texture, map_v2_floor_macro.png, completely overhead PLAN VIEW with flat diffuse illumination.
A perfectly circular pond-silt dish floor centred(512,512), radius512, touches the middle of all FOUR canvas edges. The corners outside the disc are uniform flat RGB(10,19,16), hex#0A1310. No visible raised rim, no border line, no outline.
Inside the disc: dark warm OLIVE silt, dominant exact palette #2B3023. Very restrained broad organic mottling. One SMALL softly blended sunlit pool #3A3E2C covering at most10% of the disc. Exactly SEVEN faint ochre diatom-dust drifts with irregular lengths, orientations and spacing, just barely different from the silt, no identifiable shells or particles. A few broad darker organic smudges. Over the outer30px only, gently darken to#181C14 toward the glass foot; blend into the disc with no concentric ring.
This is a quiet, DARK gameplay background. Every pixel of the floor must have max RGB channel at most82/255 (0.322), including dust and sunlit area; do not auto-brighten. Dust is muted dark ochre around#454631, not glowing amber. The small light pool is a low-contrast pigment variation, not a spotlight, and no cast shadows.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this flat floor exception the light is fully diffuse and even; no directional 3D relief, specular reflections or painted shading on objects.
Premium chunky mobile arena environment art, soft painted low-contrast organic material. NO caustics, water ripple networks, rings, grid, objects, rocks, microbes, plants, raised details, bright greens, dots, balls, or outlines. Full canvas alpha255.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 checks:

```text
map_v2_floor_macro_try1_orig.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.286 spread=45 key_px=0 checker=0.000 p99_any=0.286 p99_noamber=0.286 amber=0.0000 amber_glow=0.0000 spread8=45
resized 1254x1254 Format24bppRgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_floor_macro_try1.png (1024x1024)
map_v2_floor_macro_try1.png: size=1024x1024 format=Format32bppArgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1023,1023 p99_max=0.286 spread=45 key_px=0 checker=0.000 p99_any=0.286 p99_noamber=0.286 amber=0.0000 amber_glow=0.0000 spread8=45

```


Try1 passes numeric value gate but sampled outside corners varied #0A130F..#0B1612 instead of flat#0A1310.

### Try 2 — uniform outside fill

Reference/edit target: `out/rejected/map_v2_floor_macro_try1.png`.

```text
Use case: precise-object-edit.
Edit ONLY the four areas OUTSIDE the circular disc in the supplied floor texture. Replace those corner areas with perfectly uniform solid digital RGB(10,19,16), hex#0A1310, no texture, no noise, no gradient, no lighting variations. Every outside-disc pixel must be the same exact color. The disc is centred(512,512),radius512 on a1024x1024canvas, touching each edge midpoint.
Keep the entire floor INSIDE that circle unchanged: dark olive silt, small sunlit pool, seven faint ochre dust drifts, darker smudges, soft outer30px falloff. Preserve current maximum values; p99 must remain below0.35. No brightening, no new marks, no objects, no caustics, no ring or outline.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Preserve the existing flat diffuse floor appearance. The outside corners are an unlit solid fill.
ONE opaque1024x1024PNG, alpha255 everywhere.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 2 checks:

```text
map_v2_floor_macro_try2_orig.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.404 spread=89 key_px=0 checker=0.000 p99_any=0.404 p99_noamber=0.392 amber=0.0030 amber_glow=0.0000 spread8=89
resized 1254x1254 Format24bppRgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_floor_macro_try2.png (1024x1024)
map_v2_floor_macro_try2.png: size=1024x1024 format=Format32bppArgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1023,1023 p99_max=0.404 spread=88 key_px=0 checker=0.000 p99_any=0.404 p99_noamber=0.392 amber=0.0031 amber_glow=0.0000 spread8=88

```


Rejected try2: p99 rose to0.404 and outside fill still varies slightly (#0A130F..#0A1612).

### Try 3 — darken and flatten outside fill

Reference/edit target: `out/rejected/map_v2_floor_macro_try2.png`.

```text
Use case: precise-object-edit. Single opaque1024x1024PNG.
Supplied image is the edit target. Preserve its circular olive-silt floor touching all four edge midpoints, seven faint dusty drifts and small soft light pool.
Reduce the entire INSIDE-disc RGB brightness by35%. This is a DARK gameplay texture: dominant#2B3023, small light pool#3A3E2C, dim dust#3C3D2A. Maximum RGB channel89, p99 at most0.35. No shiny or golden flecks.
All four OUTSIDE-disc corner regions must be one flat solid color#0A1310 (RGB10,19,16), identical everywhere, no texture or gradient. This is a digital flat-color mask outside the circle. Circle centre512,512 radius512. No visible rim, outline or ring. Keep all pixels opaque.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Floor exception: diffuse even unlit material; preserve subtle mottling without dimensional shadows.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 3 checks:

```text
map_v2_floor_macro_try3_orig.png: size=1254x1254 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1253,1253 p99_max=0.318 spread=60 key_px=0 checker=0.000 p99_any=0.318 p99_noamber=0.318 amber=0.0000 amber_glow=0.0000 spread8=60
resized 1254x1254 Format24bppRgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_floor_macro_try3.png (1024x1024)
map_v2_floor_macro_try3.png: size=1024x1024 format=Format32bppArgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1023,1023 p99_max=0.318 spread=60 key_px=0 checker=0.000 p99_any=0.318 p99_noamber=0.318 amber=0.0000 amber_glow=0.0000 spread8=60

```


**Selected try1 after three tries: numeric gate pass, minor outside-fill deviation.** Its quieter texture and p99=0.286 fit the brief best. Try2 is too bright; try3 passes p99 but makes drifts coarser and stronger. Outside corners in try1 vary by a few RGB levels rather than being exactly flat#0A1310 (sampled #0A130F to#0B1612). The disc reaches all four edges, has no ring or caustics, and the light pool remains small.

Final command: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_floor_macro.png`

```text
map_v2_floor_macro.png: size=1024x1024 format=Format32bppArgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1023,1023 p99_max=0.286 spread=45 key_px=0 checker=0.000 p99_any=0.286 p99_noamber=0.286 amber=0.0000 amber_glow=0.0000 spread8=45

```


## Slot 11 — rim north

### Try 1 — generation

Reference: `ref/template_strip.png` (measurement guide). Opaque output with intentional magenta key outside the band.

```text
Use case: stylized-concept.
Asset: map_v2_rim_north.png. ONE OPAQUE PNG exactly1536px WIDE by1024px HIGH, aspect3:2.
Input ref/template_strip.png = measurement guide; reproduce none of its guide lines, grey fill, or marks. Preserve its full canvas and horizontal band concept, but use the EXACT rows below.
All rows y0..319 and y705..1023 must be perfectly uniform solid key MAGENTA#FF00FF (RGB255,0,255), identical everywhere, no texture, no gradients, no alpha. This deliberate key fill stays in the final file. No magenta anywhere INSIDE the band y320..704.
Render ONLY a straight horizontal segment of algae-filmed pond-dish glass in y320..704, stretching from x0 through x1535, flush with both edges. Flat rectangular strip, no curvature, perspective or rounded ends. SEAMLESS LEFT-RIGHT: at x0 and x1535 the lip height, material colors and texture continue exactly.
From BOTTOM to TOP within this band:
- y580..704: dark foot with soft olive algae fuzz, #181C14 to#2B3023. Fuzz thins upwards and NEVER occupies more than one-third of the band height. No long fronds or spikes.
- y328..579: clear-looking glossy green-teal glass, algae-filmed #3D5B52 with restrained broad shading. The glass has NO shapes, microbes, plants or scenery behind it.
- y320..327: one thin continuous warm sunlit lip line#E8EDC8,8px thick and never more than12px. Straight and parallel to canvas edges.
Exactly THREE small HOLLOW bubble rings embedded in the glass, all different diameters and at staggered vertical levels with unequal horizontal gaps. Example centres near(180,450),(790,515),(1300,395), diameters34,60,42px. Thin subtle rings, transparent-looking centres that show the same glass material, never filled circles. No pairs beside one another. No other circular marks.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Only restrained glass highlights inside the band; no light spill into the magenta.
Premium chunky mobile arena environment art, soft painted glass material, quiet muted colors. No outlines, text, symbols, equipment, metal, geometric ornament, behind-glass shapes or cast shadows. Full canvas opaque. Do not draw any border around the image. Respect EXACT y320 andy704 cutoff rows.
```


Try 1 checks (extra checks are read-only; no pixel edits):

```text
map_v2_rim_north_try1_orig.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=253 key_px=980186 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0002 amber_glow=0.0001 spread8=253
map_v2_rim_north_try1.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=253 key_px=980186 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0002 amber_glow=0.0001 spread8=253
mode=rim max_any=1.000 alpha_range=255..255 alpha255_px=1572864 opaque_px=1572864 visible_px=1572864 nonkey_outside_band=981504 key_inside_band=0 nonkey_y=319..705 seam_lr_mean=37.678 seam_lr_max=151 seam_tb_mean=3.885 seam_tb_max=19 max_radius=0.00 outside_radius_px=0 cell_radii=0.00,0.00,0.00,0.00 cell_components=0,0,0,0 floor_outside_off=0/0 floor_outside_max_delta=0

```


Rejected try1 for exact key-fill mismatch and obvious tiling seam (LR mean37.678/max151). Art extends one row beyond each band boundary.

### Try 2 — exact key and tiling correction

References: `ref/template_strip.png`, `out/rejected/map_v2_rim_north_try1.png` (edit target).

```text
Use case: precise-object-edit. ONE opaque PNG, EXACTLY1536x1024.
Image1 ref/template_strip.png = measurement guide; reproduce none of its lines or grey fill. Image2 out/rejected/map_v2_rim_north_try1.png = EDIT TARGET.
Preserve the straight glass strip, three staggered hollow rings, muted teal glass, thin warm lip and low algae foot. Correct ONLY these production details:
- All rows0..319 and705..1023 must be uniform PURE DIGITAL MAGENTA RGB255,0,255 (#FF00FF), no grain, no compression-like variation, no gradients. NOT #FC00FC or any nearby shade. Every such pixel exactly#FF00FF. Keep all magenta completely outside band320..704. Cut the strip at exactly y320 andy704.
- Make the band SEAMLESS LEFT-RIGHT. Remove the strong localized highlight at the far left. At every y in320..704, leftmost and rightmost pixels have matching RGB. Shade the glass consistently across its full width: even muted green-teal #3D5B52, no bright left end, no dark right end, no endcaps. Continue the algae foot texture smoothly over the wrap. Bubble rings remain away from both edges.
- Keep warm top lip#E8EDC8 strictly8px thick, y320..327, uniform alongx. Keep algae foot in bottom third y580..704.
Nothing behind the glass. No new rings, objects, silhouettes, dots, outlines or text.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this tiling strip, lighting is translationally uniform alongx; highlights may vary withy only. No isolated light hotspot.
No curvature. Full canvas opaque, straight rectangular band flush to both side edges.
```


Try 2 checks:

```text
map_v2_rim_north_try2_orig.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=251 key_px=979811 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0001 amber_glow=0.0001 spread8=251
map_v2_rim_north_try2.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=251 key_px=979811 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0001 amber_glow=0.0001 spread8=251
mode=rim max_any=1.000 alpha_range=255..255 alpha255_px=1572864 opaque_px=1572864 visible_px=1572864 nonkey_outside_band=981504 key_inside_band=0 nonkey_y=318..705 seam_lr_mean=32.259 seam_lr_max=115 seam_tb_mean=3.779 seam_tb_max=22 max_radius=0.00 outside_radius_px=0 cell_radii=0.00,0.00,0.00,0.00 cell_components=0,0,0,0 floor_outside_off=0/0 floor_outside_max_delta=0

```


Try2 improves the seam slightly but key is still non-exact and edge mismatch remains (LR mean32.259/max115).

### Try 3 — simplified edge shading and key fill

References: `ref/template_strip.png`, `out/rejected/map_v2_rim_north_try2.png` (edit target).

```text
Use case: precise-object-edit. Output ONE opaque1536x1024PNG.
Image1 ref/template_strip.png is the measurement guide; reproduce none of its guide marks. Image2 out/rejected/map_v2_rim_north_try2.png is the edit target.
Keep the target's band y320..704 and its EXACTLY THREE staggered hollow bubble rings, but SIMPLIFY the glass shading for seamless tiling.
Glass middle y328..579: muted #3D5B52, smooth low-contrast painted glass. At each y, use the SAME tone at x0 andx1535 and across the outermost128px on BOTH ends. Remove the left-right lighting gradient, scratch highlights, bright flecks and end seams. Glass remains green-teal without anything behind it.
Bottom y580..704: dark #181C14 olive algae foot, soft fine fuzz only within this bottom third. Match both ends exactly; no long grass, spikes or lime-green details.
Top y320..327: perfectly straight uniform8px warm lip#E8EDC8, identical at both ends.
Rows y0..319 and705..1023: REPLACE with a completely flat DIGITAL FILL of EXACT#FF00FF, RGB255,0,255, zero noise or shading. Preserve pure magenta with no color adjustment. No magenta inside320..704. Art may not bleed into row319 or705.
All pixels opaque. No border, curvature, extra circles, round filled dots, objects, text or symbols.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
For this horizontally tiling asset the illumination is constant alongx, varying only vertically within the glass band.
```


Try 3 checks:

```text
map_v2_rim_north_try3_orig.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=252 key_px=979142 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0000 amber_glow=0.0000 spread8=252
map_v2_rim_north_try3.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=252 key_px=979142 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0000 amber_glow=0.0000 spread8=252
mode=rim max_any=1.000 alpha_range=255..255 alpha255_px=1572864 opaque_px=1572864 visible_px=1572864 nonkey_outside_band=981504 key_inside_band=0 nonkey_y=318..705 seam_lr_mean=24.996 seam_lr_max=75 seam_tb_mean=3.709 seam_tb_max=17 max_radius=0.00 outside_radius_px=0 cell_radii=0.00,0.00,0.00,0.00 cell_components=0,0,0,0 floor_outside_off=0/0 floor_outside_max_delta=0

```


**Selected after three tries: try3, best candidate with significant technical deviations.** Correct1536x1024, three hollow rings, straight band and no key inside the band. The key fill remains near-magenta rather than exact#FF00FF (all981504 outside pixels differ), art reaches y318..705 instead of320..704, and left/right edges are not seamless (mean24.996, max75 RGB levels). Try3 has the smallest seam difference and least distracting glass texture. No pixel correction was applied; only image_gen edits were used.

Final commands: `powershell -ExecutionPolicy Bypass -File verify.ps1 out/map_v2_rim_north.png` and `powershell -ExecutionPolicy Bypass -File out/verify-extra.ps1 out/map_v2_rim_north.png rim`.

```text
map_v2_rim_north.png: size=1536x1024 format=Format24bppRgb corner_a=255 a8=255 aw8=255 centre_a=255 opaque=1.000 bbox=0,0,1535,1023 p99_max=0.988 spread=252 key_px=979142 checker=0.000 p99_any=0.988 p99_noamber=0.988 amber=0.0000 amber_glow=0.0000 spread8=252
mode=rim max_any=1.000 alpha_range=255..255 alpha255_px=1572864 opaque_px=1572864 visible_px=1572864 nonkey_outside_band=981504 key_inside_band=0 nonkey_y=318..705 seam_lr_mean=24.996 seam_lr_max=75 seam_tb_mean=3.709 seam_tb_max=17 max_radius=0.00 outside_radius_px=0 cell_radii=0.00,0.00,0.00,0.00 cell_components=0,0,0,0 floor_outside_off=0/0 floor_outside_max_delta=0

```


## Slot 12 — clutter

### Try 1 — generation

References: `ref/template_grid2x2.png` (measurement), `out/map_v2_floor_macro.png` (palette/value).

```text
Use case: stylized-concept.
ONE1024x1024 true transparent2x2 game decal sheet, map_v2_clutter.png.
Input1 ref/template_grid2x2.png = measurement guide; reproduce none of its lines, colours or crosses. Input2 out/map_v2_floor_macro.png = color/value reference ONLY, do not copy the floor disc or background.
Four isolated FLAT unlit pieces, each fully contained inside radius170 (absolute maximum200) around its cell centre. Cell centres: top-left(256,256), top-right(768,256), bottom-left(256,768), bottom-right(768,768). No artwork along the invisible cell dividers.
A, top-left: one broken HALF DIATOM VALVE, thin flat curved shell fragment with subtle painted fine ribs following its curve, missing the other half. No central dot, no rosette. No thickness or bright rim.
B, top-right: one limp flat ALGAE SCRAP, irregular folded torn silhouette with soft organic edges, no long fronds or blossoms.
C, bottom-left: one irregular flattened DETRITUS FLAKE, asymmetric soft torn edges, broad simple silhouette, subtle mottling.
D, bottom-right: a compact uneven SCATTER OF EXACTLY NINE distinct silt grains. Each is lumpy elongated or irregular, never circular or spherical; nine different sizes and shapes, unequal gaps, no paired similar grains. All nine contained within radius150 around(768,768). No dust beyond these nine grains.
Every piece is extremely DARK muted olive, closely matching the reference floor#2B3023. Keep max channel for normal material44..52 (within about8% of the floor value48), subtle shade range #252A20 to#2D3426. No bright highlight. ABSOLUTE max channel110/255; no amber, bright green, pale, mint or colored specks. Flat unlit painted decals, no 3D side planes, raised ribs, bevels, glossy strokes, outlines, dark contour strokes, shadows or ground.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
This UNLIT clutter exception suppresses all directional highlights and shadows; uniformly muted pigment.
All pieces opaque inside, true alpha0 background, all corner blocks and gaps exactly alpha0. No checkerboard, grid, borders, labels or key-colored pixels.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```


Try 1 checks:

```text
map_v2_clutter_try1_orig.png: size=1254x1254 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.311 bbox=55,57,1210,1200 p99_max=0.388 spread=69 key_px=0 checker=0.000 p99_any=0.384 p99_noamber=0.388 amber=0.0001 amber_glow=0.0000 spread8=85
resized 1254x1254 Format32bppArgb -> C:\Users\User\Desktop\Germ game V1\build\codex\v2\out\rejected\map_v2_clutter_try1.png (1024x1024)
map_v2_clutter_try1.png: size=1024x1024 format=Format32bppArgb corner_a=0 a8=0 aw8=0 centre_a=0 opaque=0.311 bbox=45,47,988,980 p99_max=0.380 spread=69 key_px=0 checker=0.000 p99_any=0.380 p99_noamber=0.380 amber=0.0002 amber_glow=0.0000 spread8=77
mode=clutter max_any=0.631 alpha_range=0..255 alpha255_px=3740 opaque_px=325615 visible_px=336996 nonkey_outside_band=0 key_inside_band=0 nonkey_y=1024..-1 seam_lr_mean=0.000 seam_lr_max=0 seam_tb_mean=0.000 seam_tb_max=0 max_radius=317.32 outside_radius_px=41132 cell_radii=296.65,281.64,317.32,279.71 cell_components=1,1,1,9 floor_outside_off=0/0 floor_outside_max_delta=0

```


Try1 passes basic alpha and p99 but exceeds per-cell radius200 (max317.32), has isolated bright pixels (max_any0.631), and small paired punctures in the algae scrap. Nine grains confirmed by connected components.

### Try 2 — cell scale, value and puncture correction

References: `ref/template_grid2x2.png`, `out/map_v2_floor_macro.png`, `out/rejected/map_v2_clutter_try1.png` (edit target).

```text
Use case: precise-object-edit.
ONE1024x1024 true transparent2x2 decal sheet.
Inputs: image1 ref/template_grid2x2.png = measurement guide; reproduce none of its lines, colours or crosses. Image2 out/map_v2_floor_macro.png = floor value reference. Image3 out/rejected/map_v2_clutter_try1.png = EDIT TARGET.
Keep the same FOUR groups and all nine silt grains, with these mandatory corrections:
1. Scale EACH of the four groups separately to55% of its current width/height, and recenter within its own cell: (256,256),(768,256),(256,768),(768,768). Do NOT scale the sheet or move the cell centres. Every piece including all grains fits fully within radius170 of its own centre, absolute max200. Leave very generous transparent margins around EACH item. Preserve nine clearly separated irregular grains in bottom-right.
2. Darken every painted RGB color by40%. Material should lie near the floor#2B3023, with main max channels44..52. NO pixel, including soft edges, may exceed105/255. Remove all pale flecks and bright yellowish rib marks. Half-shell ribs remain very subtle.
3. Remove the small paired round punctures in the upper-right algae scrap. It may have one irregular torn opening only. No paired similar marks. Keep all four pieces flat, unlit and without outlines, drop shadows, bevels or visible thickness.
Keep transparency clean: every corner, cell gap and background pixel alpha0, painted interiors opaque. No checkerboard or grid.
One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
UNLIT clutter exception: no highlights or shading from this light, only dark pigment texture.
No text, letters, numbers, logos, symbols, signatures or watermarks. No anthropomorphic details, paired similar spots, pale or saturated round filled dots, balls, lab equipment, metal, chrome, machinery or hard geometric corners except broken shell cracks and ribs. Repeated features use odd counts and irregular spacing. No cast shadow, ground patch, external glow, guide lines, crosses, arrows, hatching or painted checkerboard.
```

