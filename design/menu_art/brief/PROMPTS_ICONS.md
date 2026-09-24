# Germ Arena icon generation report

All final assets were generated with the built-in `image_gen` tool, resized to 1024x1024 with alpha-preserving System.Drawing resampling, then verified with PowerShell and System.Drawing. Each final loaded as `Format32bppArgb`; alpha at `(8,8)` and `(width-8,height-8)` was `0`.

## `out/icon_brawlers.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game lobby glyph icon
Primary request: Three playable microbes huddled together as an overlapping group: an oval ciliate with a short cilia fringe and one flagellum, a round heliozoan with a few bead-tipped spokes, and a blobby amoeba.
Input images: three reference images define the exact Germ Arena microbe jelly material and silhouettes.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: chunky premium mobile game UI glyph, polished soft 3D cel shading; bold simple silhouette; thick uniform #04090B outline about 4% of canvas width around every exterior shape.
Composition/framing: centered tight group, slight playful tilt, subjects fill about 80% of square canvas, readable at 64x64.
Lighting/mood: single top-left light, one crisp glossy top-left highlight, shaded lower-right edge.
Color palette: laym green #7CFF5B bodies, pale green #D9FFC0 glossy balls inside, #F6FFEE highlight core, #04090B outline.
Constraints: microbes are strictly FACELESS. No eyes, pupils, mouth, eyebrows, nose, or paired dots resembling eyes. Internal glossy balls must be visible but arranged irregularly and biologically, not like facial features. Transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard pattern, painted background, tile, badge, frame, circle behind glyph, shadow or glow outside outline, fine detail.
```

## `out/icon_practice.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game lobby glyph icon
Primary request: A chunky round bullseye target with broad alternating white and amber #FFB43D rings; one glossy pale-green #D9FFC0 ball is just striking the exact center, with one small simple impact splash behind the ball.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: same cohesive premium mobile game UI glyph style; soft 3D cel shading; thick uniform #04090B outline about 4% canvas width around every shape.
Composition/framing: centered, slight dynamic tilt, fills about 80% of square canvas, only a few large shapes, readable at 64x64.
Lighting/mood: top-left light, one crisp glossy highlight, darker side thickness lower-right.
Color palette: white #F6FFEE, amber #FFB43D, pale-green ball #D9FFC0, outline #04090B.
Constraints: clearly a target and ball impact, no characters or faces, real transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, extra circle behind the target, cast shadow, outer glow, fine details.
```

## `out/icon_settings.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game settings glyph icon
Primary request: One chunky cog wheel with exactly 8 large rounded teeth and a large circular hole in the middle; light grey-white front #E8F4F2 with darker grey side thickness.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: cohesive premium mobile game UI glyph; bold simple 3D cel-shaded form; thick uniform #04090B outline about 4% canvas width on outer contour and inner hole.
Composition/framing: centered, slight tilt, fills about 80% of square canvas, readable at 64x64.
Lighting/mood: top-left lighting, one crisp glossy highlight, dark grey thickness on lower-right.
Color palette: #E8F4F2, medium cool grey, #04090B.
Constraints: exactly eight rounded teeth, clean central hole showing transparency, real transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, circle behind glyph, shadow, glow, tiny mechanical detail.
```

## `out/mode_endless.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game mode glyph icon
Primary request: A single thick continuous infinity loop made of glossy cyan #2FE8E0 jelly, with three small pale #D9FFC0 glossy balls visibly travelling along the loop surface.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: chunky premium mobile game UI glyph; soft 3D cel shading; thick uniform #04090B outline about 4% canvas width around loop and balls.
Composition/framing: centered horizontal infinity symbol, slight tilt, fills about 80% canvas, few big shapes, readable at 64x64.
Lighting/mood: one top-left light and one crisp glossy highlight, lower-right shading.
Color palette: cyan #2FE8E0, pale green-white #D9FFC0, #04090B.
Constraints: infinity loop unmistakable, real transparent PNG alpha.
Avoid: faces, eyes, text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, extra circle behind glyph, cast shadow, outer glow, fine detail.
```

## `out/mode_solo.png`

Initial generation prompt:

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game mode glyph icon
Primary request: One round faceless laym-green microbe, victorious and alone, wearing a small chunky golden crown tilted slightly on top. The microbe contains a few irregularly arranged large glossy pale-green balls.
Input image: round heliozoan reference defines Germ Arena jelly material; simplify to a clean round microbe without spokes.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: chunky premium mobile game UI glyph; soft 3D cel shading; thick uniform #04090B outline about 4% canvas width around body, crown, and balls.
Composition/framing: centered single microbe and crown, fills about 80% square canvas, readable at 64x64.
Lighting/mood: top-left lighting, crisp glossy highlight, lower-right shadow.
Color palette: body #7CFF5B, balls #D9FFC0, crown #FFB43D and #FFD23F, outline #04090B.
Constraints: absolutely FACELESS—no eyes, pupils, mouth, eyebrows, nose, or paired dots resembling eyes. Internal balls arranged asymmetrically, not like a face. Crown is the only accessory. Real transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, circle behind glyph, cast shadow, glow.
```

Transparency repair edit prompt:

```text
Use case: background-extraction
Asset type: mobile game glyph PNG transparency repair
Primary request: Remove the entire painted grey checkerboard background and output genuine transparent pixels with a real alpha channel.
Input image: the provided crowned green microbe is the edit target.
Constraints: Preserve the crowned green microbe subject exactly—same silhouette, crown, colors, internal glossy balls, thick black outline, highlights, proportions, placement, and scale. Change only the background. Keep every subject pixel and edge clean. Output a transparent PNG.
Avoid: any checkerboard pixels, grey background, new background, halo, drop shadow, glow, text, face, added or removed subject details.
```

## `out/mode_duo.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game mode glyph icon
Primary request: Two faceless round microbes side by side, touching and leaning together as a team; left microbe mint #4BFFA5 and right microbe cyan #2FE8E0; each body contains a few irregularly arranged glossy pale-green balls.
Input image: round heliozoan reference defines Germ Arena jelly material; simplify both to clean round microbes without spokes.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: chunky premium mobile game UI glyph; soft 3D cel shading; thick uniform #04090B outline about 4% canvas width around every body and ball.
Composition/framing: centered compact pair, slight tilt, overlapping/touching, fills about 80% square canvas, readable at 64x64.
Lighting/mood: one top-left light, crisp glossy highlight, lower-right shading.
Color palette: mint #4BFFA5, cyan #2FE8E0, balls #D9FFC0, outline #04090B.
Constraints: absolutely FACELESS—no eyes, pupils, mouth, eyebrows, nose, or paired dots resembling eyes. Internal balls asymmetrical and clearly intracellular. Real transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, circle behind glyph, cast shadow, glow.
```

## `out/mode_trio.png`

```text
Use case: stylized-concept
Asset type: 1024x1024 mobile game mode glyph icon
Primary request: Three faceless round microbes in a tight triangular team formation, one centered slightly above and two below, overlapping; all purple #A96BFF; each contains a few irregularly arranged glossy pale balls.
Input image: round heliozoan reference defines Germ Arena jelly material; simplify to clean round microbes without spokes.
Scene/backdrop: none; genuine transparent background with real alpha.
Style/medium: chunky premium mobile game UI glyph; soft 3D cel shading; thick uniform #04090B outline about 4% canvas width around every body and ball.
Composition/framing: centered compact triangle, slight energetic tilts, fills about 80% square canvas, few big shapes, readable at 64x64.
Lighting/mood: one top-left light, crisp glossy highlights, lower-right shading.
Color palette: purple #A96BFF, pale glossy balls #D9FFC0 with #F6FFEE highlight, outline #04090B.
Constraints: absolutely FACELESS—no eyes, pupils, mouth, eyebrows, nose, or paired dots resembling eyes. Internal balls asymmetrical and clearly intracellular. Real transparent PNG alpha.
Avoid: text, letters, numbers, logo, watermark, checkerboard, painted background, tile, badge, frame, circle behind glyph, cast shadow, glow.
```
