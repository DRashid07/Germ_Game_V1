> Codex-in öz hesabatıdır (gpt-6-astra, reasoning effort `max`; dəyişdirilməyib, yalnız fayl yolları nisbi edilib).

# Germ Arena social icons

Created with the built-in image_gen tool. Each icon received one generation pass and one background-extraction edit (two calls per icon). Final exports are in `out/` under the five requested filenames.

| File | Pixels | System.Drawing pixel format | Alpha at (8,8) | Alpha at (1016,1016) | Result |
|---|---|---|---|---|---|
| [icon_friends.png](../raw/icons/icon_friends.png) | 1024 x 1024 | Format32bppArgb | 0 | 0 | PASS |
| [icon_add_friend.png](../raw/icons/icon_add_friend.png) | 1024 x 1024 | Format32bppArgb | 0 | 0 | PASS |
| [icon_crown.png](../raw/icons/icon_crown.png) | 1024 x 1024 | Format32bppArgb | 0 | 0 | PASS |
| [icon_invite.png](../raw/icons/icon_invite.png) | 1024 x 1024 | Format32bppArgb | 0 | 0 | PASS |
| [icon_link.png](../raw/icons/icon_link.png) | 1024 x 1024 | Format32bppArgb | 0 | 0 | PASS |

Additional transparency checks:

- `icon_link.png`: ring-hole centers (651,374) and (377,666) both have alpha 0. Their enclosed fully transparent regions contain 14,474 and 14,358 pixels respectively.
- `icon_crown.png`: notch samples (323,447) and (698,447) both have alpha 0.

Every result was visually inspected. The final set was also reviewed at 128 and 40 pixels on dark blue and light backgrounds: faceless microbes, large readable glyphs, heavy dark outlines, and no text or background tiles. The preview's backgrounds and labels are inspection aids only and are absent from the final PNGs.

The tool returned 1254 x 1254 images despite the size prompt. PowerShell + System.Drawing performed only the final aspect-ratio-preserving export to a centered 1024 x 1024 transparent canvas, fitting the artwork bounds to approximately 80% of the canvas. All art generation and background removal used image_gen. No Python was used.

Verification data: [alpha-verification.json](work/alpha-verification.json). Inspection preview: [size-preview.png](work/size-preview.png). Exact machine-readable tool prompts and parameters: [prompts.json](prompts.json).

## Exact prompts used

The complete strings below are the prompts submitted to image_gen, without abbreviation. Every call used `transparent_background: true`. Generation calls omitted both image-reference parameters. Each edit used its corresponding `work/<name>-generated.png` as `referenced_image_paths`; `num_last_images_to_include` was omitted.

<details>
<summary>icon_friends.png: exact generation and edit prompts</summary>

Generation:

```text
Use case: stylized-concept.
Asset type: one standalone UI icon for Germ Arena, a premium mobile game; this is a production icon, not a UI screenshot.
Style references: the four approved images in the conversation (mode_duo, icon_quests, icon_settings, class_guard) are STYLE REFERENCES ONLY. Match their chunky Brawl Stars-style glyph rendering, rich saturated color, glossy rounded volume, and heavy near-black outlines; do not copy their subjects or compose a sheet.
Canvas: exactly 1024x1024 pixels. Center the complete subject, with its longest dimension about 820 pixels (80% of the canvas), comfortable transparent margin on every side. Few large shapes, clearly readable at 40x40 pixels.
Rendering: very thick continuous #04090B outer outline, about 40 pixels at 1024 resolution; bold clean inner separations. Soft 3D cel shading, one global light from TOP-LEFT, brighter top-left faces, deeper lower-right shading, subtle bright lower-right edge inside the silhouette. One crisp glossy highlight per main form. Smooth polished surfaces, no fine texture.
Background: genuinely transparent RGBA PNG with real alpha 0 in all empty pixels. No painted checkerboard, no solid or gradient background, no tile, no frame or backing plate, no backdrop circle, no cast shadow, no glow outside the outline.
Hard rules: absolutely no faces, eyes, pupils, mouths, eyebrows, noses, humans, hands, fingers, lab equipment, text, letters, numbers, logos, watermarks, signatures, or UI. Internal pale spheres are cellular contents, never eyes; never align two equal spheres or two small glossy dots as an eye pair.
Subject: FRIENDS. Exactly TWO faceless glossy jelly microbes side by side: lime green #7CFF5B on the left, cyan #2FE8E0 on the right and slightly behind. Distinct rounded cell bodies with a little transparent space between them above and below their contact. Each body extends ONE short, broad, rounded pseudopod toward the other. These two simple blob projections visibly TOUCH in the middle, conveying friendship like a handshake of blobs, without human anatomy. Do not simply overlap two round cells as in mode_duo. Place ONE small warm amber #FFB43D four-point sparkle exactly at the contact, with a thick dark outline, large enough to survive reduction.
Cell contents: each body contains exactly THREE pale glossy #D9FFC0 balls of clearly different sizes placed in a scattered, asymmetric, diagonally staggered arrangement throughout the body, similar in material to the approved mode_duo. The internal balls have pale #F6FFEE highlights, soft green shading, and bold dark borders. No tiny decorative dots or paired eye-like highlights. Preserve the two-cell silhouette and make the touching pseudopods conspicuous.
```

Background-extraction edit:

```text
Use case: background-extraction.
The supplied image is the ONLY edit target. Perform a background-removal / transparency finishing pass, preserving the subject exactly: keep all silhouettes, colors, thick #04090B outlines, cellular balls, pose, proportions, overlaps, shading, and glossy highlights unchanged.
Remove any background and output a genuine RGBA PNG with actual alpha 0 everywhere outside the complete glyph, including every empty gap or hole. Do not paint a checkerboard, grey, black, white, or any other color into transparent areas. Keep the subject's colored interiors and near-black outlines opaque; preserve clean antialiased edges without a halo. Do not add a shadow, glow, tile, frame, text, face, eye, pupil, mouth, or new object.
Deliver exactly 1024x1024 pixels, not 1254x1254. Keep the complete artwork centered and uncropped, occupying about 80% of the canvas on its longest dimension. Preserve the artwork's aspect ratio.
For this two-microbe friends glyph, retain the two reaching pseudopods and the single amber contact sparkle. Empty space between the two bodies must also have alpha 0.
```

</details>

<details>
<summary>icon_add_friend.png: exact generation and edit prompts</summary>

Generation:

```text
Use case: stylized-concept.
Asset type: one standalone UI icon for Germ Arena, a premium mobile game; this is a production icon, not a UI screenshot.
Style references: the four approved images in the conversation (mode_duo, icon_quests, icon_settings, class_guard) are STYLE REFERENCES ONLY. Match their chunky Brawl Stars-style glyph rendering, rich saturated color, glossy rounded volume, and heavy near-black outlines; do not copy their subjects or compose a sheet.
Canvas: exactly 1024x1024 pixels. Center the complete subject, with its longest dimension about 820 pixels (80% of the canvas), comfortable transparent margin on every side. Few large shapes, clearly readable at 40x40 pixels.
Rendering: very thick continuous #04090B outer outline, about 40 pixels at 1024 resolution; bold clean inner separations. Soft 3D cel shading, one global light from TOP-LEFT, brighter top-left faces, deeper lower-right shading, subtle bright lower-right edge inside the silhouette. One crisp glossy highlight per main form. Smooth polished surfaces, no fine texture.
Background: genuinely transparent RGBA PNG with real alpha 0 in all empty pixels. No painted checkerboard, no solid or gradient background, no tile, no frame or backing plate, no backdrop circle, no cast shadow, no glow outside the outline.
Hard rules: absolutely no faces, eyes, pupils, mouths, eyebrows, noses, humans, hands, fingers, lab equipment, text, letters, numbers, logos, watermarks, signatures, or UI. Internal pale spheres are cellular contents, never eyes; never align two equal spheres or two small glossy dots as an eye pair.
Subject: ADD FRIEND. Exactly ONE faceless glossy lime-green #7CFF5B jelly microbe, a simple rounded organic cell with exactly THREE pale glossy #D9FFC0 balls of clearly different sizes inside, distributed asymmetrically at different heights, not paired like eyes. Balls have pale #F6FFEE highlights, soft green shading, and bold dark borders. No tiny decorative bubbles.
Overlapping the microbe's LOWER-RIGHT is ONE big, chunky round bright-green #39D353 disc carrying a thick white geometric PLUS SIGN. This requested plus disc is part of the foreground glyph, not a backdrop. The disc and the white plus BOTH have very thick #04090B outlines. The plus is a plain equal-arm geometric shape, not text. Make the disc roughly 40% of the whole glyph width, with a very broad, unmistakable plus that reads at 40x40. Keep the cell contents clearly visible above and to the left of the disc. Nothing behind the complete glyph.
```

Background-extraction edit:

```text
Use case: background-extraction.
The supplied image is the ONLY edit target. Perform a background-removal / transparency finishing pass, preserving the subject exactly: keep all silhouettes, colors, thick #04090B outlines, cellular balls, pose, proportions, overlaps, shading, and glossy highlights unchanged.
Remove any background and output a genuine RGBA PNG with actual alpha 0 everywhere outside the complete glyph, including every empty gap or hole. Do not paint a checkerboard, grey, black, white, or any other color into transparent areas. Keep the subject's colored interiors and near-black outlines opaque; preserve clean antialiased edges without a halo. Do not add a shadow, glow, tile, frame, text, face, eye, pupil, mouth, or new object.
Deliver exactly 1024x1024 pixels, not 1254x1254. Keep the complete artwork centered and uncropped, occupying about 80% of the canvas on its longest dimension. Preserve the artwork's aspect ratio.
For this add-friend glyph, keep the green plus disc and white outlined plus fully opaque, and retain exactly three pale internal balls.
```

</details>

<details>
<summary>icon_crown.png: exact generation and edit prompts</summary>

Generation:

```text
Use case: stylized-concept.
Asset type: one standalone UI icon for Germ Arena, a premium mobile game; this is a production icon, not a UI screenshot.
Style references: the four approved images in the conversation (mode_duo, icon_quests, icon_settings, class_guard) are STYLE REFERENCES ONLY. Match their chunky Brawl Stars-style glyph rendering, rich saturated color, glossy rounded volume, and heavy near-black outlines; do not copy their subjects or compose a sheet.
Canvas: exactly 1024x1024 pixels. Center the complete subject, with its longest dimension about 820 pixels (80% of the canvas), comfortable transparent margin on every side. Few large shapes, clearly readable at 40x40 pixels.
Rendering: very thick continuous #04090B outer outline, about 40 pixels at 1024 resolution; bold clean inner separations. Soft 3D cel shading, one global light from TOP-LEFT, brighter top-left faces, deeper lower-right shading, subtle bright lower-right edge inside the silhouette. One crisp glossy highlight per main form. Smooth polished surfaces, no fine texture.
Background: genuinely transparent RGBA PNG with real alpha 0 in all empty pixels. No painted checkerboard, no solid or gradient background, no tile, no frame or backing plate, no backdrop circle, no cast shadow, no glow outside the outline.
Hard rules: absolutely no faces, eyes, pupils, mouths, eyebrows, noses, humans, hands, fingers, lab equipment, text, letters, numbers, logos, watermarks, signatures, or UI. Internal pale spheres are cellular contents, never eyes; never align two equal spheres or two small glossy dots as an eye pair.
Subject: TEAM LEADER. One chunky rounded golden crown, simple and bold, WIDER THAN IT IS TALL. Rich #FFC83D gold body with deeper #E08A1E shading. Exactly THREE broad rounded points: a taller central point and two lower outward points. On TOP of each point sits ONE small pale glossy #D9FFC0 spherical ball with #F6FFEE highlight, instead of a jewel: exactly three balls total. Each sphere and the crown silhouette have thick #04090B outlines. Broad simple curved gold base band, no extra jewels, emblems, ornament, or tiny details. Slight three-quarter tilt is acceptable while preserving an instantly recognizable three-point crown. Empty notches BETWEEN the points must show genuinely transparent alpha 0 all the way down to the crown's contour.
```

Background-extraction edit:

```text
Use case: background-extraction.
The supplied image is the ONLY edit target. Perform a background-removal / transparency finishing pass, preserving the subject exactly: keep all silhouettes, colors, thick #04090B outlines, cellular balls, pose, proportions, overlaps, shading, and glossy highlights unchanged.
Remove any background and output a genuine RGBA PNG with actual alpha 0 everywhere outside the complete glyph, including every empty gap or hole. Do not paint a checkerboard, grey, black, white, or any other color into transparent areas. Keep the subject's colored interiors and near-black outlines opaque; preserve clean antialiased edges without a halo. Do not add a shadow, glow, tile, frame, text, face, eye, pupil, mouth, or new object.
Deliver exactly 1024x1024 pixels, not 1254x1254. Keep the complete artwork centered and uncropped, occupying about 80% of the canvas on its longest dimension. Preserve the artwork's aspect ratio.
For this three-point crown, the two deep open notches between the three points must also be alpha 0. Retain exactly three pale spheres and preserve the gold base and dark outlines.
```

</details>

<details>
<summary>icon_invite.png: exact generation and edit prompts</summary>

Generation:

```text
Use case: stylized-concept.
Asset type: one standalone UI icon for Germ Arena, a premium mobile game; this is a production icon, not a UI screenshot.
Style references: the four approved images in the conversation (mode_duo, icon_quests, icon_settings, class_guard) are STYLE REFERENCES ONLY. Match their chunky Brawl Stars-style glyph rendering, rich saturated color, glossy rounded volume, and heavy near-black outlines; do not copy their subjects or compose a sheet.
Canvas: exactly 1024x1024 pixels. Center the complete subject, with its longest dimension about 820 pixels (80% of the canvas), comfortable transparent margin on every side. Few large shapes, clearly readable at 40x40 pixels.
Rendering: very thick continuous #04090B outer outline, about 40 pixels at 1024 resolution; bold clean inner separations. Soft 3D cel shading, one global light from TOP-LEFT, brighter top-left faces, deeper lower-right shading, subtle bright lower-right edge inside the silhouette. One crisp glossy highlight per main form. Smooth polished surfaces, no fine texture.
Background: genuinely transparent RGBA PNG with real alpha 0 in all empty pixels. No painted checkerboard, no solid or gradient background, no tile, no frame or backing plate, no backdrop circle, no cast shadow, no glow outside the outline.
Hard rules: absolutely no faces, eyes, pupils, mouths, eyebrows, noses, humans, hands, fingers, lab equipment, text, letters, numbers, logos, watermarks, signatures, or UI. Internal pale spheres are cellular contents, never eyes; never align two equal spheres or two small glossy dots as an eye pair.
Subject: TEAM INVITE. One chunky cream/ivory envelope, #FFF1D6 with warm #E9C48F shading, flap CLOSED. A slight energetic tilt like the approved quest-scroll illustration, but the subject is clearly an envelope. Bold simple triangular flap folds converge in the middle. Seal it in the middle with ONE round lime-green #7CFF5B glossy seal shaped like a small faceless microbe blob, subtly organic in outline. The seal contains exactly ONE pale glossy #D9FFC0 ball placed slightly off center. The seal and its one ball have bold #04090B outlines. No other internal dots, no face-like marks, no paired shine dots. Keep the envelope's thick silhouette, broad warm cel shading, and one crisp top-left glossy highlight. No stamp, writing, lettering, hearts, arrows, or added symbols.
```

Background-extraction edit:

```text
Use case: background-extraction.
The supplied image is the ONLY edit target. Perform a background-removal / transparency finishing pass, preserving the subject exactly: keep all silhouettes, colors, thick #04090B outlines, cellular balls, pose, proportions, overlaps, shading, and glossy highlights unchanged.
Remove any background and output a genuine RGBA PNG with actual alpha 0 everywhere outside the complete glyph, including every empty gap or hole. Do not paint a checkerboard, grey, black, white, or any other color into transparent areas. Keep the subject's colored interiors and near-black outlines opaque; preserve clean antialiased edges without a halo. Do not add a shadow, glow, tile, frame, text, face, eye, pupil, mouth, or new object.
Deliver exactly 1024x1024 pixels, not 1254x1254. Keep the complete artwork centered and uncropped, occupying about 80% of the canvas on its longest dimension. Preserve the artwork's aspect ratio.
For this envelope glyph, preserve the closed flap, cream material, lime-green microbe seal, and its exactly one pale ball. All cream envelope faces and black flap seams are subject pixels and must remain opaque.
```

</details>

<details>
<summary>icon_link.png: exact generation and edit prompts</summary>

Generation:

```text
Use case: stylized-concept.
Asset type: one standalone UI icon for Germ Arena, a premium mobile game; this is a production icon, not a UI screenshot.
Style references: the four approved images in the conversation (mode_duo, icon_quests, icon_settings, class_guard) are STYLE REFERENCES ONLY. Match their chunky Brawl Stars-style glyph rendering, rich saturated color, glossy rounded volume, and heavy near-black outlines; do not copy their subjects or compose a sheet.
Canvas: exactly 1024x1024 pixels. Center the complete subject, with its longest dimension about 820 pixels (80% of the canvas), comfortable transparent margin on every side. Few large shapes, clearly readable at 40x40 pixels.
Rendering: very thick continuous #04090B outer outline, about 40 pixels at 1024 resolution; bold clean inner separations. Soft 3D cel shading, one global light from TOP-LEFT, brighter top-left faces, deeper lower-right shading, subtle bright lower-right edge inside the silhouette. One crisp glossy highlight per main form. Smooth polished surfaces, no fine texture.
Background: genuinely transparent RGBA PNG with real alpha 0 in all empty pixels. No painted checkerboard, no solid or gradient background, no tile, no frame or backing plate, no backdrop circle, no cast shadow, no glow outside the outline.
Hard rules: absolutely no faces, eyes, pupils, mouths, eyebrows, noses, humans, hands, fingers, lab equipment, text, letters, numbers, logos, watermarks, signatures, or UI. Internal pale spheres are cellular contents, never eyes; never align two equal spheres or two small glossy dots as an eye pair.
Subject: SHARE TEAM LINK. Exactly TWO thick interlocking CHAIN LINKS, each a pill-shaped ring, arranged end-to-end along a 45-degree diagonal running from bottom-left to top-right. Clear rounded elongated ring geometry, clearly woven together at the center with believable over-under overlap. Each ring must retain a LARGE OPEN HOLE, clearly visible and genuinely transparent. Cyan #2FE8E0 with a lighter top-left face and deeper teal #138C8A lower-right shading. Heavy continuous #04090B outlines on outer silhouettes AND inner hole boundaries. Substantial rounded ring thickness, broad smooth 3D cel-shaded faces, one crisp glossy highlight per link. No extra links, small dots, sparkles, or other symbols. Both ring holes must be empty alpha 0, never filled with teal, grey, white, black, or a painted checkerboard.
```

Background-extraction edit:

```text
Use case: background-extraction.
The supplied image is the ONLY edit target. Perform a background-removal / transparency finishing pass, preserving the subject exactly: keep all silhouettes, colors, thick #04090B outlines, cellular balls, pose, proportions, overlaps, shading, and glossy highlights unchanged.
Remove any background and output a genuine RGBA PNG with actual alpha 0 everywhere outside the complete glyph, including every empty gap or hole. Do not paint a checkerboard, grey, black, white, or any other color into transparent areas. Keep the subject's colored interiors and near-black outlines opaque; preserve clean antialiased edges without a halo. Do not add a shadow, glow, tile, frame, text, face, eye, pupil, mouth, or new object.
Deliver exactly 1024x1024 pixels, not 1254x1254. Keep the complete artwork centered and uncropped, occupying about 80% of the canvas on its longest dimension. Preserve the artwork's aspect ratio.
For this chain glyph, BOTH open ring holes must also be genuinely transparent alpha 0. Remove all backdrop pixels inside each ring as carefully as the outside background. Preserve both rings' inner black outlines and the correct over-under interlocking geometry.
```

</details>

