> Codex-in öz hesabatıdır (gpt-6-astra, reasoning effort `max`; dəyişdirilməyib). Brif: [BRIEF_AIM.md](BRIEF_AIM.md), xam fayllar: [../raw/hud/](../raw/hud/).

# Exact prompts used

Tool: built-in `image_gen.imagegen`.
Every call set `transparent_background: true`.
Generation calls omitted both image-reference parameters. Edit calls supplied the preceding PNG with `referenced_image_paths` and omitted `num_last_images_to_include`.
The attached approved icons were style references only.

## hud_fire.png

### 1. Generation

```text
Use case: stylized-concept.
Create one finished isolated raster HUD glyph for Germ Arena, a mobile game, on a 1024 x 1024 square canvas. This is one asset, never a sheet or interface screenshot.
Style references: the attached approved practice target, gear, cyan chain and spiked microbe are STYLE ONLY. Match their chunky Brawl Stars / Supercell mobile-game rendering: bold simple silhouette, thick clean near-black #04090B contour approximately 40 pixels wide, rounded bevels, soft 3D cel shading, one top-left light source and one crisp glossy white highlight. Do not copy any reference subject.
MONOCHROME TINTABLE ART: pure white #FFFFFF lit faces and highlight; light grey #D4DCDE midtone; deepest grey #9AA6A9 shading; near-black #04090B outline and dark details. Perceived neutral white/grey only, no visible hue, no green, cyan, blue, pink, amber or coloured glow. Keep every RGB channel difference below 24. Large white faces must remain opaque.
Background: genuine transparent alpha, not an opaque checkerboard. No painted checkerboard, tile, badge, backing shape, scene, ground, cast drop shadow or outside glow. All holes and gaps are transparent. Smooth anti-aliased silhouette without a pale halo.
No text, letters, numbers, logo, watermark, face, eyes, mouth, humans, hands or lab equipment. Few big shapes, instantly readable at 48 x 48. Keep the subject centered with safe transparent margins.

SUBJECT: one chunky glossy spherical projectile BALL flying diagonally toward the UPPER-RIGHT. Exactly THREE short thick rounded capsule speed streaks trail behind the ball toward the LOWER-LEFT, along the same lower-left to upper-right direction. The streaks become shorter and thinner farther from the ball. The ball and all three streaks are distinct shapes separated by obvious fully transparent gaps; no merged tail, no extra specks. The round ball occupies about 45% of the complete glyph width. The complete centered glyph fills about 80% of canvas width and height. Smooth neutral white ball with a light-grey lower-right cel-shadow and one crisp top-left white highlight, thick black contour. Each streak has matching thickness of contour and subtle grey bevel. The ball is a projectile, not a microbe or a character.
```

### 2. Transparency edit

```text
Use case: background-extraction.
Edit target: the supplied generated HUD glyph. This is a precision alpha cleanup, preserving its subject and rendering.
Output exactly 1024 x 1024 pixels as a transparent RGBA PNG. Preserve the icon silhouette, all parts, layout, chunky black outline, white/grey cel shading, bevel and glossy highlight. Do not redesign, recolour, add parts or add text.
Remove every background pixel completely, including any faint alpha haze, stray pixel specks, painted checkerboard, shadow, glow or matte fringe. All empty space outside AND INSIDE the subject must have alpha exactly 0. The subject's solid interior, white faces, grey shading and black outlines must have alpha exactly 255, not 253 or 254. Allow fractional alpha only on the narrow anti-aliased contour. Do not treat the white or grey subject as background.
Keep the palette neutral white and grey only, lit white #FFFFFF, light grey #D4DCDE, deepest body grey #9AA6A9, near-black contour/details #04090B, no visible hue and no RGB channel difference of 24 or more in any solid part. No coloured light. No background colour, no checkerboard pixels, no backing shape or circle, no scene, no drop shadow. Maintain the original top-left lighting and thick dark contour. Do not add any text, letters, numbers, faces or UI screenshots.

Preserve exactly one projectile ball flying upper-right and exactly three separate rounded streaks trailing lower-left. Clear all the spaces between the ball and streaks and between the three streaks to true alpha 0. Keep the complete subject centered at about 80% of the canvas.
```

### 3. Correction

```text
Use case: precise-object-edit.
Edit the supplied isolated projectile HUD icon. Correct the ball-to-tail proportion: the current ball is too large, about 60% of the complete glyph width. Reduce ONLY the ball diameter so the ball is about 45% of the final complete glyph width. Keep a perfectly ROUND projectile ball at the upper-right, with exactly THREE thick rounded separate speed streaks trailing lower-left. Keep those streaks distinct, with clear transparent gaps, and taper their length and thickness away from the ball. The complete glyph remains centered, about 80% of the canvas width. Do not turn it into an oval or merge the streaks. Maintain a thick near-black contour around every piece, about 4% of canvas width.
Preserve the existing chunky Brawl Stars glossy 3D cel rendering and top-left lighting, with one crisp white top-left highlight on the ball. Keep a broad white face and simple grey lower-right shading. Remove any remaining hue: use pure white #FFFFFF, neutral light grey #DADADA, neutral shadow grey #A3A3A3 and neutral near-black #080808 only, R = G = B. No green, blue or cyan.
1024 x 1024 transparent RGBA PNG. Real alpha 0 everywhere outside the four subject pieces and in every gap, alpha 255 inside solid surfaces. No checkerboard pixels, background, backing shape, glow or shadow. No text, letters, numbers, faces, microbe features or UI screenshot.
```

## hud_aim_knob.png

### 1. Generation

```text
Use case: stylized-concept.
Create one finished isolated raster HUD glyph for Germ Arena, a mobile game, on a 1024 x 1024 square canvas. This is one asset, never a sheet or interface screenshot.
Style references: the attached approved practice target, gear, cyan chain and spiked microbe are STYLE ONLY. Match their chunky Brawl Stars / Supercell mobile-game rendering: bold simple silhouette, thick clean near-black #04090B contour approximately 40 pixels wide, rounded bevels, soft 3D cel shading, one top-left light source and one crisp glossy white highlight. Do not copy any reference subject.
MONOCHROME TINTABLE ART: pure white #FFFFFF lit faces and highlight; light grey #D4DCDE midtone; deepest grey #9AA6A9 shading; near-black #04090B outline and dark details. Perceived neutral white/grey only, no visible hue, no green, cyan, blue, pink, amber or coloured glow. Keep every RGB channel difference below 24. Large white faces must remain opaque.
Background: genuine transparent alpha, not an opaque checkerboard. No painted checkerboard, tile, badge, backing shape, scene, ground, cast drop shadow or outside glow. All holes and gaps are transparent. Smooth anti-aliased silhouette without a pale halo.
No text, letters, numbers, logo, watermark, face, eyes, mouth, humans, hands or lab equipment. Few big shapes, instantly readable at 48 x 48. Keep the subject centered with safe transparent margins.

SUBJECT: a perfectly ROUND chunky glossy disc viewed straight from the front, centered exactly at (512,512), circular silhouette about 880 pixels in diameter (86% of canvas). Geometrically strictly symmetric; absolutely no perspective ellipse. The disc itself is the subject. Thick black outer contour; a THIN darker grey concentric inner ring just inside the contour makes it feel like a pressed button. Large clean opaque white/light-grey face.
Cut into the face is a bold near-black CROSSHAIR: one small solid round near-black centre dot exactly at canvas center, plus exactly FOUR identical short thick rounded ticks directed north, south, west and east, evenly spaced. All four ticks start near the dot with clear gaps from it and end well before the inner rim; no full lines across the disc. The center pixel must be fully opaque near-black #04090B. Strictly centered, identical tick length and thickness, no other symbols. Top-left glossy highlight on the disc, restrained lower-right grey bevel.
```

### 2. Transparency edit

```text
Use case: background-extraction.
Edit target: the supplied generated HUD glyph. This is a precision alpha cleanup, preserving its subject and rendering.
Output exactly 1024 x 1024 pixels as a transparent RGBA PNG. Preserve the icon silhouette, all parts, layout, chunky black outline, white/grey cel shading, bevel and glossy highlight. Do not redesign, recolour, add parts or add text.
Remove every background pixel completely, including any faint alpha haze, stray pixel specks, painted checkerboard, shadow, glow or matte fringe. All empty space outside AND INSIDE the subject must have alpha exactly 0. The subject's solid interior, white faces, grey shading and black outlines must have alpha exactly 255, not 253 or 254. Allow fractional alpha only on the narrow anti-aliased contour. Do not treat the white or grey subject as background.
Keep the palette neutral white and grey only, lit white #FFFFFF, light grey #D4DCDE, deepest body grey #9AA6A9, near-black contour/details #04090B, no visible hue and no RGB channel difference of 24 or more in any solid part. No coloured light. No background colour, no checkerboard pixels, no backing shape or circle, no scene, no drop shadow. Maintain the original top-left lighting and thick dark contour. Do not add any text, letters, numbers, faces or UI screenshots.

The round disc is the actual subject and must remain filled and opaque. Preserve the perfectly round front-on disc, dark inner ring, small central black dot and exactly four matching short separated crosshair ticks. The pixel at exact canvas center (512,512) MUST be solid near-black with alpha 255. Outside the disc is alpha 0. Keep the round disc centered and about 86% of canvas diameter.
```

## hud_target.png

### 1. Generation

```text
Use case: stylized-concept.
Create one finished isolated raster HUD glyph for Germ Arena, a mobile game, on a 1024 x 1024 square canvas. This is one asset, never a sheet or interface screenshot.
Style references: the attached approved practice target, gear, cyan chain and spiked microbe are STYLE ONLY. Match their chunky Brawl Stars / Supercell mobile-game rendering: bold simple silhouette, thick clean near-black #04090B contour approximately 40 pixels wide, rounded bevels, soft 3D cel shading, one top-left light source and one crisp glossy white highlight. Do not copy any reference subject.
MONOCHROME TINTABLE ART: pure white #FFFFFF lit faces and highlight; light grey #D4DCDE midtone; deepest grey #9AA6A9 shading; near-black #04090B outline and dark details. Perceived neutral white/grey only, no visible hue, no green, cyan, blue, pink, amber or coloured glow. Keep every RGB channel difference below 24. Large white faces must remain opaque.
Background: genuine transparent alpha, not an opaque checkerboard. No painted checkerboard, tile, badge, backing shape, scene, ground, cast drop shadow or outside glow. All holes and gaps are transparent. Smooth anti-aliased silhouette without a pale halo.
No text, letters, numbers, logo, watermark, face, eyes, mouth, humans, hands or lab equipment. Few big shapes, instantly readable at 48 x 48. Keep the subject centered with safe transparent margins.

SUBJECT: target lock reticle formed of exactly FOUR disconnected, thick, rounded CORNER BRACKETS at upper-left, upper-right, lower-left and lower-right. Like the four corners of a square viewfinder, but each L-shaped corner is gently bowed to follow a circle. Brackets have two short connected legs and rounded elbows and endpoints. Fourfold rotationally symmetric geometry and equal sizes and spacing. Broad white faces, light-grey bevel/shading and thick near-black outlines, matching the reference icons.
The whole centered reticle spans about 920 pixels (90% of canvas). The entire central area, at least the central 60% of the canvas diameter, is EMPTY with alpha 0, including the exact center. Four substantial transparent gaps at north, south, east, west separate the brackets. No center dot, no crosshair, no microbe, no center disc, no connecting ring, no backing panel or extra shapes. Each bracket alone is a thick dimensional white/grey bar outlined in black. All empty space is real transparency, never grey fill or checkerboard.
```

### 2. Transparency edit

```text
Use case: background-extraction.
Edit target: the supplied generated HUD glyph. This is a precision alpha cleanup, preserving its subject and rendering.
Output exactly 1024 x 1024 pixels as a transparent RGBA PNG. Preserve the icon silhouette, all parts, layout, chunky black outline, white/grey cel shading, bevel and glossy highlight. Do not redesign, recolour, add parts or add text.
Remove every background pixel completely, including any faint alpha haze, stray pixel specks, painted checkerboard, shadow, glow or matte fringe. All empty space outside AND INSIDE the subject must have alpha exactly 0. The subject's solid interior, white faces, grey shading and black outlines must have alpha exactly 255, not 253 or 254. Allow fractional alpha only on the narrow anti-aliased contour. Do not treat the white or grey subject as background.
Keep the palette neutral white and grey only, lit white #FFFFFF, light grey #D4DCDE, deepest body grey #9AA6A9, near-black contour/details #04090B, no visible hue and no RGB channel difference of 24 or more in any solid part. No coloured light. No background colour, no checkerboard pixels, no backing shape or circle, no scene, no drop shadow. Maintain the original top-left lighting and thick dark contour. Do not add any text, letters, numbers, faces or UI screenshots.

Preserve exactly four disconnected rounded corner brackets, symmetric around the empty center. The entire central circular region with diameter 60% of the canvas MUST be empty, alpha exactly 0 everywhere, with no stray translucent specks. The pixel at exact center (512,512) is alpha 0. All four gaps between brackets are alpha 0. There is absolutely no backing disc. Reticle centered at about 90% of canvas.
```

### 3. Correction

```text
Use case: precise-object-edit.
Edit the supplied single isolated mobile-game HUD glyph. Preserve its exact silhouette, layout, parts, empty areas, thick black outline and chunky glossy 3D cel rendering. Make just this colour correction: remove the remaining blue/cyan bias from ALL grey shading, bevels, outlines and edge pixels. Use achromatic grayscale with R = G = B throughout: pure white #FFFFFF faces and crisp glossy highlight, neutral light grey #DADADA, neutral shadow grey #A3A3A3, and neutral near-black #080808 outline and dark detail. No pixel on the subject may have a perceptible hue. One top-left light source, no coloured reflections.
Transparent background with true alpha 0 in all empty space; solid subject interiors alpha 255. Preserve all empty holes and gaps as alpha 0, never an opaque grey pattern or translucent haze. Nothing behind the subject. No text, faces, symbols added, backing shape, glow, cast shadow or UI screenshot. 1024 x 1024 square PNG with real alpha.
Retain the four separate gently curved rounded corner brackets, symmetrically arranged at the four corners of the reticle, spanning about 90% of the canvas. Preserve the entirely empty center: the entire central disk occupying 60% of canvas diameter must be alpha exactly 0, with no specks. Keep four transparent cardinal gaps. Do not add a dot, disc, connecting circle or any center detail.
```

## hud_aim_arrow.png

### 1. Generation

```text
Use case: stylized-concept.
Create one finished isolated raster HUD glyph for Germ Arena, a mobile game, on a 1024 x 1024 square canvas. This is one asset, never a sheet or interface screenshot.
Style references: the attached approved practice target, gear, cyan chain and spiked microbe are STYLE ONLY. Match their chunky Brawl Stars / Supercell mobile-game rendering: bold simple silhouette, thick clean near-black #04090B contour approximately 40 pixels wide, rounded bevels, soft 3D cel shading, one top-left light source and one crisp glossy white highlight. Do not copy any reference subject.
MONOCHROME TINTABLE ART: pure white #FFFFFF lit faces and highlight; light grey #D4DCDE midtone; deepest grey #9AA6A9 shading; near-black #04090B outline and dark details. Perceived neutral white/grey only, no visible hue, no green, cyan, blue, pink, amber or coloured glow. Keep every RGB channel difference below 24. Large white faces must remain opaque.
Background: genuine transparent alpha, not an opaque checkerboard. No painted checkerboard, tile, badge, backing shape, scene, ground, cast drop shadow or outside glow. All holes and gaps are transparent. Smooth anti-aliased silhouette without a pale halo.
No text, letters, numbers, logo, watermark, face, eyes, mouth, humans, hands or lab equipment. Few big shapes, instantly readable at 48 x 48. Keep the subject centered with safe transparent margins.

SUBJECT: a single bold rounded CHEVRON pointing RIGHT, east toward positive X. Exactly two thick bars joined at a rounded rightmost tip, forming the visual silhouette of a greater-than chevron; it is a directional shape, not typography. No shaft, no tail, no complete arrow, no extra object. Geometry perfectly symmetric about the horizontal center line at y=512. Two free rounded bar ends at the upper-left and lower-left, broad transparent V-shaped notch between them opening to the left. The notch remains fully transparent.
The centered chevron spans approximately 70% of canvas (about 717 pixels in height and comparable visual extent in width), with generous transparent margins. A chunky white-to-grey body with a slight bevel, thick clean near-black outline and one crisp top-left glossy highlight; no thin lines or tiny detail. No circular backing or button behind it.
```

### 2. Transparency edit

```text
Use case: background-extraction.
Edit target: the supplied generated HUD glyph. This is a precision alpha cleanup, preserving its subject and rendering.
Output exactly 1024 x 1024 pixels as a transparent RGBA PNG. Preserve the icon silhouette, all parts, layout, chunky black outline, white/grey cel shading, bevel and glossy highlight. Do not redesign, recolour, add parts or add text.
Remove every background pixel completely, including any faint alpha haze, stray pixel specks, painted checkerboard, shadow, glow or matte fringe. All empty space outside AND INSIDE the subject must have alpha exactly 0. The subject's solid interior, white faces, grey shading and black outlines must have alpha exactly 255, not 253 or 254. Allow fractional alpha only on the narrow anti-aliased contour. Do not treat the white or grey subject as background.
Keep the palette neutral white and grey only, lit white #FFFFFF, light grey #D4DCDE, deepest body grey #9AA6A9, near-black contour/details #04090B, no visible hue and no RGB channel difference of 24 or more in any solid part. No coloured light. No background colour, no checkerboard pixels, no backing shape or circle, no scene, no drop shadow. Maintain the original top-left lighting and thick dark contour. Do not add any text, letters, numbers, faces or UI screenshots.

Preserve the single chunky rounded two-bar chevron pointing RIGHT, symmetric in silhouette about the horizontal centerline. Clear its entire V-shaped notch and all surrounding empty area to alpha 0. No shaft. Keep the chevron centered and about 70% of the canvas in height.
```

### 3. Correction

```text
Use case: precise-object-edit.
Edit the supplied single isolated mobile-game HUD glyph. Preserve its exact silhouette, layout, parts, empty areas, thick black outline and chunky glossy 3D cel rendering. Make just this colour correction: remove the remaining blue/cyan bias from ALL grey shading, bevels, outlines and edge pixels. Use achromatic grayscale with R = G = B throughout: pure white #FFFFFF faces and crisp glossy highlight, neutral light grey #DADADA, neutral shadow grey #A3A3A3, and neutral near-black #080808 outline and dark detail. No pixel on the subject may have a perceptible hue. One top-left light source, no coloured reflections.
Transparent background with true alpha 0 in all empty space; solid subject interiors alpha 255. Preserve all empty holes and gaps as alpha 0, never an opaque grey pattern or translucent haze. Nothing behind the subject. No text, faces, symbols added, backing shape, glow, cast shadow or UI screenshot. 1024 x 1024 square PNG with real alpha.
Retain the single chunky rounded two-bar right-pointing chevron, with its deep empty left-opening notch, horizontal symmetry, no shaft and no backing. Keep the bevel slight and the thick dark outline clean. Center the chevron and size it to about 70% of canvas height. The entire notch must be genuine transparent alpha 0.
```

