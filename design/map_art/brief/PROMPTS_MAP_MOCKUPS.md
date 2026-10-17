> Codex-in öz hesabatıdır (gpt-6-astra, reasoning effort `max`; dəyişdirilməyib). Brif: [BRIEF_MAP_MOCKUPS.md](BRIEF_MAP_MOCKUPS.md), xam fayllar: [../raw/mockups/](../raw/mockups/).

# Battle-map concept generation log

Built-in image_gen only. Opaque screenshot mockups. The user's mockup instructions supersede sprite-only alpha, registration-size, ground-shadow, and verify.ps1 requirements in STYLE_MAP.md. No verify.ps1 run was requested.

## map_v1_mockup.png — call 1

Status: tool rejected before generation because referenced_image_paths allows at most five paths. No image generated. This did not consume an image quality attempt.

-i references, in order:
- `ref/template_v1.png`
- `ref/world_center.png`
- `ref/world_solo.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`
- `ref/menu_bg.jpg`

transparent_background: false

Exact prompt:

```text
Use case: stylized-concept.
Deliverable: ONE opaque landscape battle screenshot concept, exactly 1536 x 1024 pixels. This is an environment art-direction comparison frame, not a sprite, poster, presentation, labeled diagram, or menu. Paint the live battle with no interface and no text whatsoever.

REFERENCE ROLES, in supplied order:
1. ref/template_v1.png is a measurement guide; reproduce none of its lines, colours or arrow. Use only its circular silhouette and the placement of the internal southern shaded band, scaled down to the obstacle sizes below.
2. ref/world_center.png and 3. ref/world_solo.png are game-frame style references only; do not copy the scene. Preserve their actual small gameplay microbe designs, food and projectile language. Remove all interface elements and lettering.
4. ref/species_0.png is the exact ciliate anatomy reference: flattened oval jelly body, a fringe of short fine cilia and one long thin flexible tail.
5. ref/species_1.png is the exact heliozoan anatomy reference: round jelly body with slender bent radial legs ending in tiny balls.
6. ref/species_2.png is the exact amoeba anatomy reference: asymmetrical flattened softly triangular bean/blob, double membrane and fine granular interior, no legs.
7. ref/menu_bg.jpg is STYLE REFERENCE ONLY for rendering quality and wet atmospheric mood; do not copy its scene, horizon, architecture or camera.

ART DIRECTION: finished dark-teal droplet arena, premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. Refined but still clearly a real playable frame of the supplied game. Preserve the simple bright cel-shaded gameplay sprites from the species references, with their dark near-black outlines and glossy colored jelly. The microbes are entirely faceless: no eyes, mouths or expressions. Internal inclusions form a varied irregular group, never a bilateral pair. All environmental forms also strictly non-anthropomorphic, without paired similar spots.

CAMERA AND SCALE:
Straight top-down, looking at about 930 x 620 world units at 1.65 pixels per world unit. No vanishing points. Microbe BODIES only about 90 pixels wide, food 25 pixels diameter, shots 30 pixels diameter. Obstacles roughly 190-480 pixels across; the microbes are small relative to them. Do not enlarge the microbes into mascots.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
Every blocking dome and crust is entirely contained in its circular base, including the northern cap. The silhouette is circular, not a raised mushroom or upright sphere. Height is solely an internal southern crescent.

COMPOSITION:
The far north glass wall arcs gently across the upper 15-20 percent. Its floor seam is about y=190 in the middle and y=215 at the edges; above it is the dark outside. This is a small portion of an enormous dish, never the whole circular dish. Leave generous connected dark open floor between obstacles for visible combat.
Use the following approximate positions on the 1536x1024 canvas for an easily comparable battle:
- Smooth blocking gel dome centered around (365,450), diameter 310.
- Granular blocking gel dome around (1040,835), diameter 270.
- Breakable crust around (1115,385), diameter 275, actively being struck on its lower-left edge.
- Passable bush around (510,790), diameter 300, with a genuinely hollow center.
- Passable vent around (1320,880), diameter 190.
Exactly six small microbes: lime ciliate player at (775,535); magenta heliozoan at (1310,640); blue amoeba at (215,815); amber ciliate at (1355,300); violet amoeba partly hidden at (510,790) under the bush fronds; coral amoeba on open floor immediately north of the smooth dome around (365,258). Their species, outline, highlights and membranes closely follow the supplied species images. Recolor the jelly only, do not redesign their anatomy. Both ciliates have thin hair and one long tail; only the heliozoan has ball-tipped ray legs. The violet body is visibly occluded by overlapping bush fronds.

FLOOR AND GLASS:
Smooth DARK teal agar #162D33 with a subtle slightly lighter pool #1E3B42 toward the bottom, a very faint widely spaced square grid, one broad soft sediment band and a few flat subdued agar flakes. Keep floor contrast extremely low, with no floor channel over #59. No busy surface texture. Clear teal glass seen from inside #2B5963 with a dark wet crease at the floor and a very thin bright cyan-white lip #8FD3D6. Sparse condensation marks on the glass are HOLLOW rings, transparent empty centers, irregular odd counts and spacing. Outside is near-black #071012 with huge distant blurred low-contrast colony blobs and fronds, no recognizable gameplay microbes.

OBSTACLE MATERIALS:
The two blocking blobs have a continuous dark #081A20 outline. Their glossy teal gel uses top #37666F, body #26494F, south band #142C32, one broad soft upper-left reflection #5A8C93. The granular dome contains seven low-contrast irregular vesicles, varied sizes and irregular distribution, no bright dots or round pale beads. The crust is matte chalky grey #77766C with a continuous dark outline, branching amber #D09345 cracks and restrained glowing #F0B94E cores. Three to five small angular chalk chips fly from the impact.
The bush is soft muted-green fronds #3E9068, tips #4F9E7C, loose radial growth around an open hollow center. It has NO OUTLINE and NO SHADOW. Never lime or mint. Several soft fronds overlap and partly conceal the violet microbe below them.
The vent is a flat round pore cut into the floor. NO dark outline and NO shadow. Exactly NINE separated AMBER #F0B94E curved dashes form its broken lip, with clear empty gaps. A small gently turning amber swirl is inside. It is integrated into the floor, never a button.

GAMEPLAY DETAILS:
Exactly nine pale-green food balls #D9FFC0, about 25 pixels each, on open floor: near (170,360), (690,300), (1450,505), (925,640), (750,875), (335,950), (120,630), (795,420), (970,240). Food is simple glossy round jelly, matching the actual frame.
Exactly three 30-pixel shot balls with short tapered trails in their shooters' colors: lime near (980,472) striking the crust; magenta near (565,735) flying visibly ABOVE the bush fronds, with the entire ball and its trail unoccluded; blue near (365,706). Trails are short, not laser beams. Two subtle soft white hollow ripple rings on the open floor near (850,735) and (685,945), where balls just landed. These are very faint impact ripples, not selection rings. Bright filled pale balls occur ONLY as the nine foods or the three projectiles, never as environmental decoration. Any environmental bubbles have hollow transparent centers.

LIGHT:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Because this is a complete screenshot concept, include extremely soft LIGHT ground shadows beneath blocking objects and microbes, offset lower-right and only 25-30 percent darker than the local floor. No black shadow pools. Bush and vent cast no shadow.

FINAL EXCLUSIONS:
No HUD, buttons, joysticks, minimap, selection circles, icons, names, text, letters, numbers, logos, signatures, watermarks, arrows or measurement guides. No humans, lab equipment, metal, machinery or hard geometric corners; only cracks may be angular. No paired eye-like spots. No filled decorative bubbles or pale beads. No neon or saturated floor. No raised caps extending north of the V1 circular footprints. Restrained environmental values, with brighter exceptions only for the explicitly requested lip, crack cores, gameplay sprites, foods and shots. Output a single finished 1536x1024 opaque image, no border.
```

## map_v1_mockup.png — call 2, image attempt 1

Status: rejected; saved as out/rejected/map_v1_mockup_try1.png (1536x1024, 24-bit RGB). Amoebas have cilia and large round interior inclusions; smooth dome contains vesicles; magenta shot misses the bush overlap.

-i references, in order:
- `ref/world_center.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`
- `ref/menu_bg.jpg`

transparent_background: false

Exact prompt:

```text
Use case: stylized-concept.
Deliverable: ONE opaque landscape battle screenshot concept, exactly 1536 x 1024 pixels. This is an environment art-direction comparison frame, not a sprite, poster, presentation, labeled diagram, or menu. Paint the live battle with no interface and no text whatsoever.

REFERENCE ROLES, in supplied order:
1. ref/world_center.png is a game-frame style reference only; do not copy the scene. Preserve its actual small gameplay microbe designs, food and projectile language. Remove all interface elements and lettering.
2. ref/species_0.png is the exact ciliate anatomy reference: flattened oval jelly body, a fringe of short fine cilia and one long thin flexible tail.
3. ref/species_1.png is the exact heliozoan anatomy reference: round jelly body with slender bent radial legs ending in tiny balls.
4. ref/species_2.png is the exact amoeba anatomy reference: asymmetrical flattened softly triangular bean/blob, double membrane and fine granular interior, no legs.
5. ref/menu_bg.jpg is STYLE REFERENCE ONLY for rendering quality and wet atmospheric mood; do not copy its scene, horizon, architecture or camera.

ART DIRECTION: finished dark-teal droplet arena, premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. Refined but still clearly a real playable frame of the supplied game. Preserve the simple bright cel-shaded gameplay sprites from the species references, with their dark near-black outlines and glossy colored jelly. The microbes are entirely faceless: no eyes, mouths or expressions. Internal inclusions form a varied irregular group, never a bilateral pair. All environmental forms also strictly non-anthropomorphic, without paired similar spots.

CAMERA AND SCALE:
Straight top-down, looking at about 930 x 620 world units at 1.65 pixels per world unit. No vanishing points. Microbe BODIES only about 90 pixels wide, food 25 pixels diameter, shots 30 pixels diameter. Obstacles roughly 190-480 pixels across; the microbes are small relative to them. Do not enlarge the microbes into mascots.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
Every blocking dome and crust is entirely contained in its circular base, including the northern cap. The silhouette is circular, not a raised mushroom or upright sphere. Height is solely an internal southern crescent.

COMPOSITION:
The far north glass wall arcs gently across the upper 15-20 percent. Its floor seam is about y=190 in the middle and y=215 at the edges; above it is the dark outside. This is a small portion of an enormous dish, never the whole circular dish. Leave generous connected dark open floor between obstacles for visible combat.
Use the following approximate positions on the 1536x1024 canvas for an easily comparable battle:
- Smooth blocking gel dome centered around (365,450), diameter 310.
- Granular blocking gel dome around (1040,835), diameter 270.
- Breakable crust around (1115,385), diameter 275, actively being struck on its lower-left edge.
- Passable bush around (510,790), diameter 300, with a genuinely hollow center.
- Passable vent around (1320,880), diameter 190.
Exactly six small microbes: lime ciliate player at (775,535); magenta heliozoan at (1310,640); blue amoeba at (215,815); amber ciliate at (1355,300); violet amoeba partly hidden at (510,790) under the bush fronds; coral amoeba on open floor immediately north of the smooth dome around (365,258). Their species, outline, highlights and membranes closely follow the supplied species images. Recolor the jelly only, do not redesign their anatomy. Both ciliates have thin hair and one long tail; only the heliozoan has ball-tipped ray legs. The violet body is visibly occluded by overlapping bush fronds.

FLOOR AND GLASS:
Smooth DARK teal agar #162D33 with a subtle slightly lighter pool #1E3B42 toward the bottom, a very faint widely spaced square grid, one broad soft sediment band and a few flat subdued agar flakes. Keep floor contrast extremely low, with no floor channel over #59. No busy surface texture. Clear teal glass seen from inside #2B5963 with a dark wet crease at the floor and a very thin bright cyan-white lip #8FD3D6. Sparse condensation marks on the glass are HOLLOW rings, transparent empty centers, irregular odd counts and spacing. Outside is near-black #071012 with huge distant blurred low-contrast colony blobs and fronds, no recognizable gameplay microbes.

OBSTACLE MATERIALS:
The two blocking blobs have a continuous dark #081A20 outline. Their glossy teal gel uses top #37666F, body #26494F, south band #142C32, one broad soft upper-left reflection #5A8C93. The granular dome contains seven low-contrast irregular vesicles, varied sizes and irregular distribution, no bright dots or round pale beads. The crust is matte chalky grey #77766C with a continuous dark outline, branching amber #D09345 cracks and restrained glowing #F0B94E cores. Three to five small angular chalk chips fly from the impact.
The bush is soft muted-green fronds #3E9068, tips #4F9E7C, loose radial growth around an open hollow center. It has NO OUTLINE and NO SHADOW. Never lime or mint. Several soft fronds overlap and partly conceal the violet microbe below them.
The vent is a flat round pore cut into the floor. NO dark outline and NO shadow. Exactly NINE separated AMBER #F0B94E curved dashes form its broken lip, with clear empty gaps. A small gently turning amber swirl is inside. It is integrated into the floor, never a button.

GAMEPLAY DETAILS:
Exactly nine pale-green food balls #D9FFC0, about 25 pixels each, on open floor: near (170,360), (690,300), (1450,505), (925,640), (750,875), (335,950), (120,630), (795,420), (970,240). Food is simple glossy round jelly, matching the actual frame.
Exactly three 30-pixel shot balls with short tapered trails in their shooters' colors: lime near (980,472) striking the crust; magenta near (565,735) flying visibly ABOVE the bush fronds, with the entire ball and its trail unoccluded; blue near (365,706). Trails are short, not laser beams. Two subtle soft white hollow ripple rings on the open floor near (850,735) and (685,945), where balls just landed. These are very faint impact ripples, not selection rings. Bright filled pale balls occur ONLY as the nine foods or the three projectiles, never as environmental decoration. Any environmental bubbles have hollow transparent centers.

LIGHT:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Because this is a complete screenshot concept, include extremely soft LIGHT ground shadows beneath blocking objects and microbes, offset lower-right and only 25-30 percent darker than the local floor. No black shadow pools. Bush and vent cast no shadow.

FINAL EXCLUSIONS:
No HUD, buttons, joysticks, minimap, selection circles, icons, names, text, letters, numbers, logos, signatures, watermarks, arrows or measurement guides. No humans, lab equipment, metal, machinery or hard geometric corners; only cracks may be angular. No bilaterally paired spots. No filled decorative bubbles or pale beads. No neon or saturated floor. No raised caps extending north of the V1 circular footprints. Restrained environmental values, with brighter exceptions only for the explicitly requested lip, crack cores, gameplay sprites, foods and shots. Output a single finished 1536x1024 opaque image, no border.
```

## map_v1_mockup.png — call 3, image attempt 2

Status: rejected; saved as out/rejected/map_v1_mockup_try2.png (1536x1024, 24-bit RGB). Vent lip has eight dashes; amoebas retain round interior beads.

-i references, in order:
- `out/rejected/map_v1_mockup_try1.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`
- `ref/world_center.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
Edit image 1 into ONE finished opaque 1536x1024 battle screenshot. Image 1 (out/rejected/map_v1_mockup_try1.png) is the edit target and material/composition anchor. Images 2, 3 and 4 (ref/species_0.png, ref/species_1.png, ref/species_2.png) are exact gameplay anatomy references, not scenes to copy. Image 5 (ref/world_center.png) is a game-frame style reference only; do not copy its scene or any interface.

Preserve the target's complete battle layout, camera, scale, six microbe positions, teal droplet theme, all obstacle positions, crack impact, glass wall, nine foods and two faint white impact ripples. Make these precise corrections:
1. Correct the THREE AMOEBAS, using image 4 faithfully. The blue lower-left amoeba, coral amoeba north of the large left dome, and partly concealed violet amoeba must have a smooth asymmetrical rounded triangular/bean silhouette with a thick near-black outline, a colored double membrane, a broad glossy cel-shaded top and only TINY fine interior granulation. Absolutely no cilia, tail, legs or large round internal inclusions on any amoeba. They must resemble recolored smaller copies of the reference amoeba. The blue body is 90 pixels across. Remove the cilia currently protruding from it. Keep the lime and amber ciliates faithful to image 2, with fine hair and one thin long tail, and the magenta heliozoan faithful to image 3, with thin bent ray legs and ball tips. No eyes, mouths or expressions on any microbe.
2. The large left blocking dome is SMOOTH gel: remove every internal round vesicle, spot and ring. Keep only its broad upper-left soft specular reflection, subtle translucent material, dark outline and darker internal southern band. The lower-right granular dome alone has seven subdued irregular vesicles of varying sizes and asymmetrical spacing. Its inclusions are not bright balls.
3. Move the magenta projectile to about (570,710) so its entire bright 30-pixel ball and short magenta trail are visibly layered ON TOP OF actual bush fronds. Paint the fronds first, projectile last. The violet amoeba stays visibly BELOW and partially concealed by the bush fronds. Keep exactly three projectiles total: that magenta ball, the blue ball in open air and the lime ball striking the cracked crust. Their colors match their shooters.
4. The bush edge must stay softly fronded and completely unoutlined. Remove any cast ground shadow beneath bush and vent. The bush has an open hollow center around its concealed violet microbe. Keep its fronds muted green #3E9068 with tips #4F9E7C.
5. The vent has exactly nine separated amber #F0B94E curved dashes around its lip and an amber swirl inside, with no dark outline or cast shadow.
6. Keep all NINE food balls 25 pixels wide and very pale pastel green #D9FFC0, distinctly paler than the lime player. Do not add any decorative filled pale balls.
7. Reduce floor texture, haze and reflection contrast. Floor is smooth dark teal #162D33 with a subtle #1E3B42 lower pool, one broad very soft sediment band, a barely visible square grid and only a few subdued flat flakes. Remove the prominent diagonal light shafts. The glass lip remains thin, not a bright stage horizon; glass arcs gently across the top 15-20 percent with a dark outside above it. Outside colonies are huge blurred blobs and fronds without recognizable microbe anatomy.

Projection, unchanged:
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
All dome silhouettes and the breakable crust stay within their round bases, including the northern cap. No raised northern silhouette, no upright spheres.

Lighting, unchanged:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Ground shadows under blocking objects and microbes only: extremely soft, offset lower-right, only 25-30 percent darker than local floor. No ground shadow under bush or vent. Continuous dark #081A20 outlines on blocking gel and chalky grey crust. Amber cracks #D09345 with #F0B94E cores and a few chalk chips. Preserve the teal gel palette: top #37666F, body #26494F, south band #142C32, broad upper-left specular #5A8C93.

Strictly no text, letters, numbers, HUD, icons, UI, buttons, selection rings, watermark, signature or guides. No anthropomorphism or bilateral pairs of similar spots anywhere. No extra decorative filled balls, no saturated or neon floor. Preserve the clean premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines, small gameplay-scale microbes. One opaque 1536x1024 image.
```

## map_v1_mockup.png — call 4, image attempt 3

Status: selected best after the allowed three image attempts; saved as out/map_v1_mockup.png. No HUD/text/anthropomorphism; silhouettes improved. Residual: visible vent lip still has eight rather than nine dashes; no further V1 generation was made.

-i references, in order:
- `out/rejected/map_v1_mockup_try2.png`
- `ref/species_2.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/template_v1.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
Make a minimal correction to image 1, the supplied teal battle screenshot (out/rejected/map_v1_mockup_try2.png). Preserve its full composition and all existing environmental materials, six microbes, nine foods, three projectiles, outlines, sizes, lighting and colors except for the explicitly identified corrections. Image 2 (ref/species_2.png) is the exact amoeba anatomy reference; use only its anatomy and no text. Image 3 (ref/species_0.png) is the ciliate reference, image 4 (ref/species_1.png) is the heliozoan reference. Image 5 (ref/template_v1.png) is a measurement guide; reproduce none of its lines, colours or arrow. Use only its circular silhouette and internal southern band.

Correct the lower-right vent lip. It currently has EIGHT amber strokes. Erase those strokes and paint EXACTLY NINE separate short amber #F0B94E curved dashes around the round pore centered approximately (1371,833), radius 83 pixels. Count nine discrete strokes, each separated by a very clear gap. Use one dash at the very top and four along each side, with a gap at the very bottom. The angular intervals are approximately forty degrees, slightly irregular. Keep the amber swirl inside unchanged. Do not add any dark outline or shadow to this floor pore.

Correct only the interiors of the blue lower-left amoeba, coral upper-left amoeba and the violet amoeba partially concealed by the bush: REMOVE ALL ROUND BUBBLE INCLUSIONS. Replace them with very fine stippled grain like the exact amoeba reference, within the existing broad glossy cel-shaded body and double membrane. Preserve their asymmetrical rounded triangular/bean silhouettes, scale, placement, colors and near-black outlines. These three amoebas have no cilia, no tail, no ray legs. Do not alter the correctly hairy lime and amber ciliates, or the magenta heliozoan's thin ball-tipped legs. All six microbes stay faceless, without eyes or mouths.

The nine food balls stay pale #D9FFC0, 25 pixels diameter. The three shots remain 30 pixels with short colored trails; the magenta shot MUST remain on top of the bush fronds, fully visible. The violet microbe remains under and partly occluded by fronds. Preserve the bush's open hollow center, soft muted-green edge, absence of outline, and absence of cast shadow. The smooth dome stays smooth. The granular dome stays subtly granular.

Keep the floor very dark #162D33, with only a faint #1E3B42 lower pool and a few subdued flakes. If visible, the faint square grid is truly orthogonal: all north-south lines are straight and vertical on screen and all east-west lines straight and horizontal. No convergence or perspective shrinking. Make the two existing floor impact rings softly white and faint, still hollow, with no icon-like brightness. Add three faint HOLLOW condensation rings of different sizes and irregular spacing in the glass wall; their centers are completely empty. No filled decorative balls.

Projection:
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
The continuous dark silhouettes of all blocking domes and the crust fit inside their round footprints. No lifted northern cap. This is a complete top-down battle frame near the far north glass edge.

Lighting:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Extremely soft shadows for blockers and microbes only, offset lower-right, only 25-30 percent darker than the floor. No shadow for bush or pore.

Output ONE opaque 1536x1024 PNG-like screenshot, no border. Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. Absolutely no text, letters, numbers, HUD, UI, buttons, names, icons, selection rings, symbols, watermark, signature or guide marks. No anthropomorphism, no paired similar spots, no environmental pale balls, no neon or saturated floor.
```

## map_v2_mockup.png — call 5, image attempt 1

Status: rejected; saved as out/rejected/map_v2_mockup_try1.png. Floor too bright/noisy, third satellite pebble missing, drum occlusion shown as filled ghost rather than thin contour.

-i references, in order:
- `ref/template_v2.png`
- `out/map_v1_mockup.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`

transparent_background: false

Exact prompt:

```text
Use case: style-transfer.
Create ONE opaque 1536x1024 battle screenshot by re-rendering the environment of image 2 as a sunlit pond-drop arena with short raised pillars. Keep its gameplay sprites and battle beat consistent for art-direction comparison. This is a playable battle frame, no interface or text.

REFERENCE ROLES, in supplied order:
1. ref/template_v2.png = measurement guide; reproduce none of its lines, colours or arrow. Its geometry applies proportionally to each blocker, not to the whole screenshot.
2. out/map_v1_mockup.png = finished battle composition and gameplay anchor; match its outline weight and lighting, keep its small microbes, food and shots. Replace its environment with the pond materials described below.
3. ref/species_0.png = exact ciliate anatomy reference.
4. ref/species_1.png = exact heliozoan anatomy reference.
5. ref/species_2.png = exact amoeba anatomy reference.
Never copy text or interface from any reference.

CAMERA AND PROJECTION:
Top-down floor, no vanishing points, about 930x620 world units in view at 1.65 pixels per unit. Keep microbe BODIES about 90 pixels across, food 25 pixels, shots 30 pixels, obstacle diameters 190-480 pixels.
Seen from almost straight above, like a low pillar: the top face is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top face may rise above the footprint ONLY inside the thin yellow-hatched lift zone of the template (up to y 90).
The template y coordinate is only a proportion guide. At this screenshot scale, each blocking cap is lifted north by about ONE TENTH OF ITS RADIUS, roughly 18 pixels for the large drum, never a tall tower. A darker short vertical front band sits under the lifted top. Footprint circles remain round on the floor.

POND ENVIRONMENT:
DARK low-contrast olive silt floor #2B3023. One SMALL softly sunlit pool #3A3E2C toward lower center, not a bright floor everywhere. A very faint pale caustic network lies flat on the floor. No bright saturated greens. Floor channel values stay under #59.
The glass wall arcs gently across the upper 15-20 percent, with dark outside above. It is thinly coated in subdued olive algae and has a thin warm lip highlight #E8EDC8, a dark wet floor seam, and sparse HOLLOW transparent-centered bubble rings. Beyond it is deep pond-green darkness with HUGE heavily blurred low-contrast diatom colonies far below. No recognizable gameplay microbes outside, no room or horizon scene.

BLOCKING ISLAND:
Change the large left smooth dome into one big slate-blue jelly DRUM, top #4A6670, dark front #22363E, continuous near-black #081A20 outline, broad upper-left soft reflection. Preserve its approximate center (390,420) and diameter about 350.
Ring it with exactly THREE smaller jelly pebbles about 190 pixels across, at approximately (155,465), (270,640), and (650,400). Keep the existing foods and shots clear of these pebbles. Two pebbles are simple smooth gel. The right pebble is a frogspawn cushion made of SEVEN fused lumpy gel beads, all the same muted slate-blue value, without internal dots or spots. These fused beads are irregular lobes, never pale spherical balls. Remove the old separate large granular dome from the lower-right and leave dark open floor there. There are four blocking gel forms total: one big drum and three satellites.
The coral amoeba just NORTH of the large drum is partly hidden BEHIND its lifted cap. Position its lower portion behind the cap: the top shows in the gap above the drum, the lower 15-20 pixels are occluded. A THIN faint coral glowing contour of the hidden portion shows THROUGH the translucent drum top. This is a deliberate occlusion demonstration. A thin SOLID continuous pale muted ring marks the drum's true circular base on the floor, not a dashed ring. It sits at the unlifted footprint, distinct from the raised cap. Only this drum gets a footprint ring.

BREAKABLE:
Replace the upper-right crust with a grey-green silica diatom pillbox #76786E, approximately 300 pixels diameter, with continuous dark outline and low-pillar construction. Soft radial ribs start from an OFF-CENTRE smooth patch located toward its upper-left quadrant. There is no dot at their origin and no central spot. Glowing AMBER seams #D09345 with #F0B94E cores split its ribbed plates. The same lime shot hits its lower-left side right now; a few chalky silica chips fly. No metal or machinery; this is organic silica.

PASSABLE COVER AND PORE:
Replace the lower-left bush with a pondweed bush of twisted muted-teal ribbons #3F8A70, roughly 300 pixels across, loosely spiraling around an open HOLLOW center. Soft frond edges, NO OUTLINE, NO ground shadow. The same violet amoeba is partly hidden UNDER overlapping ribbons. The magenta projectile and its complete short trail are visibly ABOVE the ribbons, never occluded.
The lower-right pore is a round bubbler hole integrated flat into the floor. NO dark outline and NO cast shadow. Its broken lip consists of EXACTLY NINE isolated AMBER #F0B94E curved dashes, clear gaps between all nine. Do not inherit the anchor's eight-dash approximation: explicitly draw nine short dashes. A small amber swirl moves inside. Above it rise three differently sized HOLLOW bubble rings with transparent empty centers; no filled bubbles or pearl decorations.

GAMEPLAY, KEEP FROM ANCHOR:
Six faceless microbes, with reference-faithful thick near-black outlines and glossy simple cel-shaded jelly: lime ciliate near center, magenta heliozoan on right, blue amoeba lower-left, amber ciliate upper-right, violet amoeba partially concealed by pondweed, coral amoeba north of the large drum with the specified pillar occlusion. No eyes, mouths or expressions. Ciliates are oval with fine cilia and one tail; heliozoan is round with thin bent ray legs and tiny ball tips. Amoebas have a smoothly rounded triangular/bean silhouette, double membrane and fine interior grain, WITHOUT cilia, tails, legs or large round internal beads. Preserve the distinctive silhouette and colors of each species; do not transform them into conventional monsters.
Exactly NINE small PALE food balls #D9FFC0 on open floor, at the anchor's positions, about 25 pixels each. Exactly three 30-pixel shot balls with short trails: lime at the impact, magenta in front of bush fronds, blue in open floor. Two faint soft WHITE HOLLOW circular impact ripples on open floor, as in the anchor. Filled pale balls are ONLY food and projectiles, never environmental decoration.

LIGHT AND VALUES:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Soft LIGHT ground shadows beneath blockers and microbes, lower-right offset, only 25-30 percent darker than local floor. Bush and vent have NO shadow. Non-emissive environmental colors remain subdued, no brighter than #949494 except the specifically named warm glass lip. Amber is reserved for breakable cracks and pore lip/swirl; the amber player retains its gameplay color.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. No text, letters, numbers, names, UI, HUD, buttons, joystick, minimap, symbols, watermark, signature, arrow, hatching or diagram guides. No anthropomorphism or bilateral paired spots. No humans, equipment, metal, machinery or hard corners, except organic crust cracks and diatom ribs. No filled decorative pale balls. Keep the floor dark and microbes small and crisp. Output one 1536x1024 opaque image.
```

## map_v2_mockup.png — call 6, image attempt 2

Status: selected; saved as out/map_v2_mockup.png. Dark floor restored, all three satellites present, coral occlusion contour and solid footprint ring visible; nine-dash vent preserved.

-i references, in order:
- `ref/template_v2.png`
- `out/rejected/map_v2_mockup_try1.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
Edit the pond battle screenshot in image 2. Output one opaque 1536x1024 frame. Preserve all six exact small microbes, nine food balls, three shots, the impact, all existing object positions and the pond palette. No interface or text.

References in order:
1. ref/template_v2.png: measurement guide; reproduce none of its lines, colours or arrow.
2. out/rejected/map_v2_mockup_try1.png: edit target and material/composition anchor; match its material, outline weight and lighting.
3. ref/species_0.png, 4. ref/species_1.png, 5. ref/species_2.png: exact ciliate, heliozoan and amoeba anatomy references only. Never reproduce their labels.

CORRECT THE FLOOR:
The current floor is much too bright, busy and yellow. Repaint it as very DARK smooth olive silt, base #2B3023, with one SMALL low-contrast sunlit pool #3A3E2C centered around (850,750), diameter about 250 pixels. Outside that small pool, the floor must remain uniformly quiet and dark. Every floor color channel stays at or below #59, including caustics. The caustic network is faint, narrow and sparse, only slightly lighter than the floor, never a glowing carpet. Remove most gravel texture, mottling and yellow light shafts. The bright microbes and pale food must pop strongly against the quiet floor. Keep the glass lip warm #E8EDC8 and thin, with subdued olive algae as a THIN wet film rather than thick vegetation. Preserve distant heavily blurred diatom colonies beyond the curved far glass wall in the upper 15-20 percent. Hollow glass bubbles have transparent centers.

COMPLETE THE BLOCKING ISLAND:
Keep the big slate-blue jelly drum and the two existing satellites (left smooth pebble and right fused-bead cushion). ADD the missing THIRD satellite: one smooth low slate-blue jelly pebble about 190 pixels diameter, centered around (255,625), to the lower-left of the big drum. It may slightly overlap its neighboring blocker as an island. Do not overlap the blue projectile, the blue amoeba, or the bush. The final island has ONE BIG DRUM plus exactly THREE small satellites. The fused cushion remains unevenly lumpy, all lobes similarly dark slate-blue, no internal bright dots. All blockers have continuous dark #081A20 outlines.

CORRECT THE DRUM OCCLUSION:
The coral amoeba north of the large drum stays partly hidden behind the raised cap. Remove its filled ghost/reflection inside the drum. Replace that with only a THIN faint glowing coral outline of its hidden bottom portion showing through the gel, a subtle contour and no colored interior fill. Keep the thin SOLID pale muted ring marking the true circular ground footprint. No dashed base ring. Keep cap lift small, about 18 pixels for this drum.

PRESERVE THESE SUCCESSFUL DETAILS:
The grey-green #76786E silica pillbox has radial ribs starting from its off-center smooth upper-left patch, without a center dot, and amber cracking at the lime projectile impact. A few chalk chips fly.
The muted-teal pondweed ribbons #3F8A70 have soft edges, NO outline and NO cast shadow, an open hollow center, and the violet amoeba stays partially under them. The magenta shot and its entire short trail stay ABOVE the ribbon fronds.
The round lower-right bubbler pore remains flush with the floor, without a dark outline or shadow. Preserve its EXACT NINE separated amber lip dashes and small amber inner swirl. Add one more small HOLLOW bubble ring above it so three transparent-centered rings of irregular sizes rise from it. No filled bubbles.
Keep nine PALE #D9FFC0 food balls at their current positions, 25 pixels across. Keep three shot balls, 30 pixels across, with short trails matching lime, magenta and blue shooters. Keep the two floor impact rings, softly WHITE, very faint and hollow, rather than bright golden loops.
Keep all microbial anatomy reference-faithful. Ciliates have fine hairs and one tail. Heliozoan has thin bent radial legs with tiny ball tips. Amoebas have smooth rounded triangular/bean silhouettes, double membranes, no hair, no tail, no legs and only fine internal granulation, not round beads. No eyes or mouths on the microbes.

Projection:
Seen from almost straight above, like a low pillar: the top face is lifted up the image by a small amount, so a darker front band shows below it along the bottom (south) edge. The round footprint stays a perfect circle; the top face may rise above the footprint ONLY inside the thin yellow-hatched lift zone of the template (up to y 90).
The template coordinate is proportional; do not draw guide lines. Floor is strictly top-down, no vanishing points.

Light:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Shadows under blockers and microbes are very soft and LIGHT, only 25-30 percent darker than the surrounding floor, offset lower-right. No cast shadow under bush or pore.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. No text, letters, numbers, names, logos, HUD, UI, symbols, selection rings, buttons, watermark, guides or signatures. No anthropomorphism or bilateral spot pairs. No pale filled environmental decorations. One opaque 1536x1024 image.
```

## map_v3_mockup.png — call 7, image attempt 1

Status: rejected; saved as out/rejected/map_v3_mockup_try1.png. High-contrast purple floor web/pits and bead-like glowing bush tips; too much glow away from microbes.

-i references, in order:
- `out/map_v1_mockup.png`
- `out/map_v2_mockup.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`

transparent_background: false

Exact prompt:

```text
Use case: style-transfer.
Repaint the ENVIRONMENT of image 1 as a dark violet biofilm cave inside a petri dish. Output ONE opaque 1536x1024 battle concept screenshot. Keep the same six small gameplay microbes, nine food balls, three shots and general battle layout for direct comparison with image 1. No interface or text.

REFERENCE ROLES:
1. out/map_v1_mockup.png is the composition, gameplay and projection anchor. Match its outline weight and lighting; preserve its six microbe positions, sizes, species and colors, its food and projectile positions, its circle-contained domes and battle impact. Change the environment palette and materials to the cave brief below.
2. out/map_v2_mockup.png is a DETAIL REFERENCE ONLY for the correct NINE isolated amber vent-lip dashes. Borrow only that nine-dash lip, not its pillar geometry, floor, arrangement or sunlit lighting.
3. ref/species_0.png is the exact ciliate anatomy reference: glossy flattened oval, fine short cilia, one flexible tail.
4. ref/species_1.png is the exact heliozoan reference: round jelly body, thin bent radial legs ending in tiny balls.
5. ref/species_2.png is the exact amoeba reference: smooth flattened asymmetric rounded triangle/bean, double membrane, fine granular interior, no hairs, tails or legs.
No text or labels from references may appear.

CAMERA, SCALE AND PROJECTION:
Strict top-down floor, no vanishing points. The frame covers about 930x620 world units, 1.65 pixels per unit. Microbe bodies about 90 pixels wide; food balls 25 pixels; projectiles 30 pixels; obstacles 190-480 pixels. Microbes are small gameplay sprites, not large mascots.
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.
Each mound, including bumpy lobes, remains entirely WITHIN its circular footprint; northern silhouette never protrudes. No pillar lift, mushroom cap or upright rounded sphere. Height is only a darker internal south crescent. Preserve the anchor's obstacle sizes and positions.

DARK BIOFILM FLOOR:
Base #201B2C, dark desaturated plum-indigo slime. Soft branching strands are only a little lighter than the base, subtle and widely spaced, not a bright web. Sparse tiny pale-aqua glowing flecks are short narrow STREAKS, never round dots. Keep nearly all of the floor dark and quiet; no saturated purple, no bright magenta, no neon carpet. A SMALL soft pale-aqua light pool lies directly under EACH of the six microbes, including the concealed violet one, to separate their silhouettes from the dark floor. These are faint diffuse pools, not hard rings or selection indicators; together cover less than five percent of the frame. The remainder of the floor stays dark, floor colors no brighter than #595959 apart from the explicitly sparse emissive streaks.

FAR GLASS WALL:
The dish's far north wall gently arcs across the upper 15-20 percent, dark outside above it. It is translucent glass overgrown with thin flowing violet biofilm sheets, scattered short glowing aqua flecks and a narrow cool-lilac lip #D9D2F0. Clear dark wet crease where it meets the floor. A few HOLLOW condensation rings have transparent centers and irregular sizes/spacing. Beyond is very dark violet with faint distant blurred glowing colony masses. No stone cave architecture, stalactites, room horizon or whole dish view. This is still the same microscopic floor and glass boundary.

BLOCKING MOUNDS:
The large left smooth blocker is glossy indigo slime, top #52507A and one broad soft upper-left specular #7A7299, a darker muted southern band, continuous dark #081A20 outline. No decorative spots in the smooth one.
The lower-right blocker is a bumpy microcolony mound with seven low fused lobes of varied size, same muted indigo value. Lobes are squat and subtly embossed WITHIN ONE ROUND base, not a tall cluster of stacked spheres. Continuous dark external outline. No bright internal dots or pale round beads.

BREAKABLE CRUST:
At upper-right, replace the grey crust with a matte chalky MAUVE-GREY plate crust #7A7080. Continuous dark outline, overlapping broad chalk plates all within a circular base. Glowing AMBER seams have #D09345 crack bodies and #F0B94E cores. The existing lime shot hits the lower-left edge right now, with a few angular chalk chips flying. Amber stays reserved for the breakable cracks and vent, except the amber gameplay microbe.

PASSABLE BUSH:
The lower-left bush is flowing muted-teal streamers #33796A, softly tapering edges, completely WITHOUT an outline or cast shadow. Its center is HOLLOW and partly occupied by the violet amoeba. Overlapping streamers visibly hide part of the violet body. Some tips have short faint aqua glowing STREAKS, never round dot tips. Sparse glow only, no neon frond halo. The magenta projectile and its short magenta trail sit clearly ABOVE actual streamers, fully visible in front of them. Preserve the shot-over-cover versus microbe-under-cover layering.

PASSABLE PORE:
The lower-right pore lies flat in the floor, round, without a dark outline or cast shadow. Its lip has EXACTLY NINE separate AMBER #F0B94E curved dashes with clear gaps, using the successful nine-dash ring from image 2. A small slowly turning amber swirl lies inside, simple organic movement rather than a symbol. No filled bubbles or beads.

PRESERVE THE GAMEPLAY:
Exactly six faceless glossy cel-shaded microbes with thick near-black outlines: lime ciliate near center, magenta heliozoan right, blue amoeba lower-left, amber ciliate upper-right, violet amoeba partly UNDER the bush, coral amoeba north of the left dome. In this top-down direction the coral microbe is fully visible, not behind a raised cap. Their anatomy must match the species images, never conventional monsters. No eyes or mouths. Only the ciliate and heliozoan have the reference-style internal inclusion group, irregularly arranged; amoebas have only fine grain, not round beads.
Exactly nine PALE #D9FFC0 food balls about 25 pixels wide on open floor. Exactly three 30-pixel colored shot balls with short trails: lime at crust impact, magenta above bush fronds, blue over open floor. Preserve positions from image 1. Two very faint soft WHITE HOLLOW ripple rings lie on open floor where balls just landed. Pale filled balls belong ONLY to food and shots; all environmental bubbles are hollow rings. Glow flecks are short STREAKS only.

LIGHT:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Ground shadows beneath blockers and microbes are very soft and LIGHT, lower-right offset, only 25-30 percent darker than the local floor. No cast shadow beneath bush or pore. Sparse small named emissive accents only. Keep violet and magenta microbes bright and readable against the dark desaturated setting.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. No text, letters, numbers, names, logos, watermarks, HUD, UI, controls, buttons, symbols, selection circles, arrows, signatures or diagram marks. No anthropomorphism or bilateral paired similar spots. No humans, equipment, metal or machinery. No hard geometric corners except crust cracks. No filled decorative pale balls. No raised northern caps, no vanishing points, no outlined bush, no hidden shots. One opaque 1536x1024 finished image.
```

## map_v3_mockup.png — call 8, image attempt 2

Status: selected; saved as out/map_v3_mockup.png. Floor darkened/desaturated, sparse linear glow flecks and tapered streamer tips, round contained domes and nine-dash vent retained.

-i references, in order:
- `ref/template_v1.png`
- `out/rejected/map_v3_mockup_try1.png`
- `out/map_v1_mockup.png`
- `ref/species_2.png`
- `ref/world_center.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
Correct the environmental restraint of image 2, the dark biofilm battle frame. Output one opaque 1536x1024 image. Keep its six microbes, nine food balls, three shots, obstacle positions and silhouettes, successful nine-dash amber pore, and crack impact unchanged.

INPUT ROLES:
1. ref/template_v1.png = measurement guide; reproduce none of its lines, colours or arrow.
2. out/rejected/map_v3_mockup_try1.png = edit target and material/composition anchor.
3. out/map_v1_mockup.png = reference for the restrained floor contrast and simple screenshot readability only; do not borrow teal colors.
4. ref/species_2.png = exact amoeba anatomy reference, no text.
5. ref/world_center.png = style reference only; do not copy the scene or interface.

FOCUSED CORRECTIONS:
The floor needs to be substantially DARKER, smoother and less saturated. Repaint the entire open floor in deep desaturated plum-indigo #201B2C, with only faint soft branching strands around #2A2536. Remove the raised purple honeycomb webs, pits, holes, coarse mottling, bright purple strands and high-contrast vein network. The strands should feel embedded, broad and soft, mostly fading into the floor. Keep less than ten tiny pale-aqua glowing SHORT STREAKS scattered widely across the floor, each visibly linear, not circular. No luminous purple anywhere in the floor. Do not lighten or saturate the base. Floor channels stay below #59 apart from those few emissive streaks.
Keep only SIX small very faint soft pale-aqua light pools, directly under the six microbes. The pool beneath the hidden violet microbe is mostly hidden by the bush. Remove aqua glows from food balls, empty floor, obstacle bases and other places. No hard aura outlines or glowing rings. The magenta and violet microbes must remain clearly readable.

Replace the bush's round-tipped glowing stalks with FLOWING SOFT MUTED-TEAL STREAMERS #33796A. Streamers have slim flattened ribbons and tapering ends that bend and flow. They grow around a clearly HOLLOW center. NO outline and NO cast shadow. Only SEVEN scattered streamer tips have a short faint aqua LINE STREAK along the last small section of the ribbon. No luminous round caps, no glowing balls, no broad cyan edge glow, no glow on every frond. The bush must be muted, softer and darker than the lime player.
The violet amoeba remains under overlapping streamers, partially hidden. The magenta shot and its entire short trail remain crisply visible ABOVE actual streamers, painted last. No frond may overlap the projectile.

Reduce the brightness and saturation of the distant violet colonies beyond the far glass lip, leaving them heavily blurred and faint. The wall itself has subtle translucent biofilm sheets and sparse short aqua streaks. Preserve its thin cool lilac #D9D2F0 lip and existing hollow condensation rings. No filled environmental spheres.

Preserve the big smooth indigo mound and the seven-lobed low microcolony mound, each entirely within its round base. Top #52507A, broad specular #7A7299, continuous dark #081A20 outlines. Their north silhouette stays circular with NO raised cap. Preserve the matte chalky mauve-grey #7A7080 crust with AMBER #D09345 cracks, #F0B94E cores and chips flying from the lime impact. Preserve the flat amber pore's EXACT NINE separated lip dashes, clear gaps, and internal swirl. No dark outline or shadow on the pore.

Keep the gameplay sprites faithful to the original game. Blue, violet and coral amoebas have smooth asymmetric rounded triangular/bean bodies with thick dark outlines, double membranes and only fine interior grain; no hair, tail, legs or large round internal inclusions. Ciliates retain their fine cilia and one thin tail; the magenta heliozoan retains its thin ball-tipped ray legs. No eyes or mouths on any microbe. Bodies about 90 pixels, nine food balls #D9FFC0 about 25 pixels, three colored shot balls about 30 pixels. Preserve the two very faint soft white hollow ripple rings on open floor.

Projection:
Seen from almost straight above. The round footprint stays a perfect circle. Height shows ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom centre, thinning to nothing at the left, right and top. Nothing rises above the footprint circle.

Light:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Very soft LIGHT shadows under blockers and microbes only, offset lower-right and just 25-30 percent darker than local floor. Bush and pore have NO cast shadow.

No text, lettering, numbers, symbols, names, HUD, controls, UI, buttons, selection circles, signatures, watermarks, arrows or guides. No anthropomorphism or paired similar spots. No bright magenta or neon purple environment, no glowing floor carpet, no filled pale decorative balls. Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. One opaque 1536x1024 battle frame.
```

## map_v4_mockup.png — call 9, image attempt 1

Status: rejected; saved as out/rejected/map_v4_mockup_try1.png. Floor grid converges, far wall is diagonally skewed, impact ellipses too flat.

-i references, in order:
- `ref/template_v4.png`
- `out/map_v1_mockup.png`
- `ref/species_0.png`
- `ref/species_1.png`
- `ref/species_2.png`

transparent_background: false

Exact prompt:

```text
Use case: style-transfer.
Re-render the finished dark-teal battle screenshot in image 2 through a TILTED ORTHOGRAPHIC CAMERA, about 55 degrees above the floor. This is the FOURTH and LAST art direction: the SAME teal agar theme, same microbes, same obstacles, same battle action and effects as the finished anchor, but viewed obliquely. Output ONE opaque 1536x1024 screenshot with no interface or text.

REFERENCE ROLES, in order:
1. ref/template_v4.png = measurement guide; reproduce none of its lines, colours or arrow. Use only its elliptical footprint, cap rise and visible southern band proportions, scaled to each obstacle.
2. out/map_v1_mockup.png = the FINISHED THEME AND SCENE REFERENCE. Match its teal gel and agar palette, outline weight, upper-left lighting, six gameplay microbes, nine pale foods, three shots, cracked crust impact, bush-over-microbe and shot-over-bush layering. This is the actual image to reproject. Do not borrow materials or pillars from other directions.
3. ref/species_0.png = exact ciliate anatomy.
4. ref/species_1.png = exact heliozoan anatomy.
5. ref/species_2.png = exact amoeba anatomy.
Species images are anatomy references only; never reproduce their labels or backgrounds.

CAMERA IS THE MAIN CHANGE:
Orthographic 3/4 view from about 55 degrees above, NO vanishing points. The footprint is an ELLIPSE (wider than tall, ratio 0.82); the object stands on it and shows its front (south) side band; the top face rises up to y 191.
The template's y coordinate is a proportional measurement within the guide, not a coordinate on the full screenshot.
This is an ORTHOGRAPHIC projection: all parallel world lines remain parallel and objects do NOT become smaller in the distance. East-west grid lines stay parallel and horizontal. North-south grid lines stay parallel and vertical on screen. Grid cells are equal-sized rectangles throughout the image, squashed in height to 82% of their width, with no convergence, no trapezoidal floor and no vanishing point.
Project the floor and all FLAT things with vertical foreshortening of 0.82. The floor footprint of a 300-pixel-wide circle must be a 300x246-pixel ellipse, not a circle. Bush base, pore opening, ground ripple rings and the FLAT microbe bodies all share this consistent slight flattening. Keep microbial bodies about 90 pixels wide, but their vertical dimension becomes about 82% of the top-down version. Microbes remain flat glossy cel-shaded gameplay sprites, not upright three-dimensional mascots. Food and airborne shots stay spherical, respectively about 25 and 30 pixels wide.
Blocking obstacles STAND ABOVE their elliptical footprints as low glossy domes in 3/4 view, with clear front/south bands. The cap can project slightly above the far edge of its elliptical base, following the guide, but the domes remain low, not tall columns. Keep all blockers 190-480 pixels across.
The glass wall at the top is the FAR wall. It rises noticeably TALLER than the top-down anchor: show about 130-170 pixels of translucent vertical glass between a thin raised upper lip and its dark floor seam. It gently arcs within the top 15-20 percent of the image, with dark outside above it. Do not put a near wall at the bottom.

SAME TEAL ENVIRONMENT:
The floor is smooth dark teal agar #162D33, slightly lighter lower pool #1E3B42, a barely visible equal-spaced rectangular grid, one broad soft sediment band and a few flat subdued agar flakes. Low contrast, floor channels under #59. The clear teal glass is #2B5963 with a dark wet crease at its foot, a very thin bright cyan-white lip #8FD3D6, and a few HOLLOW condensation rings with empty transparent centers. Outside is very dark #071012 with huge heavily blurred low-contrast colony blobs and fronds, not recognizable microbes, no bright light shafts or lobby scene.

SAME OBSTACLES, NOW ON ELLIPSES:
A large smooth glossy teal gel dome on the left, with continuous dark #081A20 outline, top #37666F, body #26494F, southern band #142C32, broad upper-left specular #5A8C93. No spots in the smooth dome. A second granular gel dome lower-right with seven subdued irregular vesicles of varied size, same muted teal values, no bright pale beads.
The upper-right breakable crust remains matte chalky grey #77766C with amber #D09345 cracks and #F0B94E cores, dark continuous outline, and a few chips flying from the lime impact. Its round footprint is now a wide ellipse and its low chalky front side is visible.
The lower-left bush stays muted green #3E9068, tips #4F9E7C, soft fronds and NO OUTLINE. Its base is a wide ellipse, with a hollow center. The violet amoeba is partly hidden UNDER several fronds. Bush casts NO shadow.
The lower-right vent becomes a visibly wide elliptical pore, about 0.82 as high as wide, integrated into the floor with NO outline and NO shadow. Around its elliptical lip put EXACTLY NINE separated AMBER #F0B94E short dashes, clear gaps. Correct the anchor's eight-dash approximation by using nine; no numerals or labels. Its amber swirl is also foreshortened into the same plane. Do not render it as a round button.

SAME BATTLE:
Exactly six faceless microbes, in the anchor's same relative positions after projection: lime ciliate near center, magenta heliozoan on right, blue amoeba lower-left, amber ciliate upper-right, violet amoeba partly under bush, coral amoeba north of the big left dome. They exactly match the supplied species with near-black outlines, broad glossy cel shading, player-colored jelly and flattened proportions. No eyes or mouths. Both ciliates have fine cilia and one thin tail; only the heliozoan has bent ball-tipped radial legs. Amoebas have smooth rounded triangular/bean silhouettes, double membranes and fine grain, no cilia, tails, ray legs or large round inclusions.
Keep exactly nine pale #D9FFC0 food balls scattered on open floor, corresponding to the anchor's positions after projection.
Keep exactly three airborne 30-pixel shot balls with short trails in their shooters' colors: lime at the crust impact, blue over open floor, magenta over the bush. The magenta shot and entire trail are drawn ABOVE the fronds, completely unoccluded.
The two faint soft WHITE hollow floor ripple rings are visibly wide ELLIPSES, height 82% of width, not circles and not UI. Environmental bubbles are hollow rings, never filled pale balls.

LIGHT:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Blocking domes, crust and microbes have very soft LIGHT lower-right shadows, only 25-30 percent darker than the local floor. Bush and pore have NO cast shadow. Keep the same restrained material values and small bright gameplay elements as the anchor.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. Absolutely no HUD, UI, controls, buttons, names, text, letters, numbers, symbols, logos, watermarks, signatures, arrows or guide markings. No anthropomorphism, bilateral paired spots, filled pale decorative bubbles, people, equipment, metal or machinery. No neon floor. No vanishing points or distance scaling. Make the orthographic tilt unmistakable through elliptical ground shapes, flat foreshortened microbes, standing low domes and the taller FAR glass wall. One opaque 1536x1024 image.
```

## map_v4_mockup.png — call 10, image attempt 2

Status: rejected; saved as out/rejected/map_v4_mockup_try2.png. Wall leveled, but several floor grid lines still visibly converge; ripples remain too flat.

-i references, in order:
- `ref/template_v4.png`
- `out/rejected/map_v4_mockup_try1.png`
- `out/map_v1_mockup.png`
- `ref/species_2.png`
- `ref/species_0.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
Fix ONLY the camera cues and subtle floor rendering in image 2, the tilted teal battle screenshot. Keep its existing six microbes, nine food balls, three shots, domes, crust impact, bush layering, successful nine-dash elliptical pore, color palette and overall battle positions. Output ONE opaque 1536x1024 image.

REFERENCE ROLES:
1. ref/template_v4.png is a measurement guide; reproduce none of its lines, colours or arrow. Use only the footprint ratio and low dome profile.
2. out/rejected/map_v4_mockup_try1.png is the edit target.
3. out/map_v1_mockup.png is the REQUIRED finished Droplet theme reference. Match its material, outline weight, upper-left lighting, quiet dark agar and same gameplay species. Do not revert to top-down circular floor shapes.
4. ref/species_2.png is the exact amoeba anatomy reference.
5. ref/species_0.png is the exact ciliate anatomy reference.
Never reproduce reference labels.

ESSENTIAL CORRECTION: ORTHOGRAPHIC, NOT CONVERGING.
Erase the current converging floor grid completely. Repaint a VERY FAINT true rectangular grid over the dark floor. Every vertical grid line is exactly VERTICAL on the screen: constant x from top to bottom, no sloping. Every horizontal grid line is exactly HORIZONTAL: constant y from left to right. All cells have identical size throughout. There are no diagonals, no converging lines, no smaller cells toward the north, no perspective depth scaling.
For practical geometry, vertical grid lines can be at x=220, 520, 820, 1120 and 1420; horizontal grid lines at y=360, 606 and 852. These are only layout measurements, never visible numbers, labels or guide marks. That is 300-pixel width and 246-pixel height per cell, the required 82 percent floor compression. Lines have extremely low contrast against smooth #162D33 agar and must not compete with gameplay.

LEVEL THE FAR GLASS WALL:
The camera has zero roll and faces due north. The far wall must not slope diagonally up to the right or disappear off the upper-right corner. Its left and right ends are at the SAME height. Paint a gently curving symmetric far wall across the TOP 15-20 percent, with the lip approximately y=40 at both edges and y=80 at center, and the floor crease approximately y=180 at both edges and y=220 at center. This gives about 140 pixels of visible tall teal glass all the way across. Both curves follow the same gentle arc; they do not converge. Dark outside lies ABOVE this far wall. No near wall at the bottom.
Glass #2B5963, dark wet floor crease, THIN cyan-white lip #8FD3D6, a few HOLLOW condensation rings with clear centers and irregular sizes. Lower the glass brightness to match the quiet teal anchor. Outside is dark #071012 with huge heavily blurred low-contrast colony blobs/fronds, no recognizable gameplay microbes.

FIX THE RIPPLE RATIO:
The two soft white hollow impact ripple rings on the floor are currently too flat. Make EACH ring a wide ellipse with height exactly 82 percent of its width: for example 100 pixels wide by 82 pixels tall. Keep them very faint and soft, with no button-like outlines. Preserve their locations. The bush base and pore also follow the same 0.82 elliptical floor projection. The nine-dash pore is already close: preserve its nine distinct amber dashes and small amber swirl, with NO dark outline or cast shadow.
Keep all microbes FLAT to the floor, with their vertical dimensions compressed to 82 percent relative to the top-down species shapes. They remain small, about 90 pixels across, with the same silhouettes and colors; no tall standing bodies. Food and shots are spherical, 25 and 30 pixels across.

Preserve the low standing teal domes with visible dark southern bands and elliptical footprints, as in the target. The upper-right chalky grey crust keeps glowing AMBER cracks and chips flying from the lime shot. The smooth left dome stays spot-free; the lower-right granular dome has only seven subdued irregular vesicles. All blockers have a continuous near-black outline. The bush stays muted green with soft unoutlined fronds and a hollow center. Violet microbe remains partly UNDER its fronds. The magenta shot and complete short trail remain ABOVE the fronds, fully visible. Bush and pore have NO shadow. No extra food, shots or decorative filled balls.

Reduce floor clutter: fewer flat agar flakes, one broad soft sediment band, a slight #1E3B42 lower pool, otherwise smooth dark #162D33. No bright diagonal light shafts. All floor channels stay below #59.

Projection:
Orthographic 3/4 view from about 55 degrees above, NO vanishing points. The footprint is an ELLIPSE (wider than tall, ratio 0.82); the object stands on it and shows its front (south) side band; the top face rises up to y 191.
The y coordinate belongs to the proportional template, not the full frame. All parallel world lines stay parallel. No vanishing points anywhere.

Light:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Only very soft LIGHT shadows to lower-right, 25-30 percent darker than local floor, beneath blockers and microbes only. Preserve existing upper-left highlights.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. Microbes are faceless: no eyes or mouths. No text, numbers, letters, names, symbols, UI, HUD, buttons, minimap, joystick, selection rings, signatures, watermark or drawn measurement guides. No anthropomorphism or paired similar spots. One opaque 1536x1024 screenshot.
```

## map_v4_mockup.png — call 11, image attempt 3

Status: selected best after three attempts; saved as out/map_v4_mockup.png. Floor grid is now parallel and far wall level/tall; low domes and pore have wide bases. Residual: ripple ellipses still look flatter than the requested 0.82 ratio.

-i references, in order:
- `ref/template_v4.png`
- `out/rejected/map_v4_mockup_try2.png`
- `out/map_v1_mockup.png`
- `ref/species_2.png`
- `ref/species_0.png`

transparent_background: false

Exact prompt:

```text
Use case: precise-object-edit.
FINAL CAMERA CORRECTION. Make a very localized edit to image 2. Deliver one opaque 1536x1024 image.

Inputs:
1. ref/template_v4.png: measurement guide; reproduce none of its lines, colours or arrow.
2. out/rejected/map_v4_mockup_try2.png: edit target.
3. out/map_v1_mockup.png: finished teal theme reference; match its material, outline weight and lighting.
4. ref/species_2.png and 5. ref/species_0.png: exact amoeba and ciliate anatomy references only, never their labels.

ERASE AND REPAINT THE FLOOR GRID.
The current floor contains slanted lines that converge toward the top. This is a camera error. Erase EVERY existing grid line on the floor, including the slanted lines at the left, right and center. Restore the underlying smooth dark #162D33 agar first.

The floor is a FLAT TWO-DIMENSIONAL TILE PLANE. It is NOT a three-dimensional perspective-rendered plane. Its grid is drawn directly onto the flat image: perfectly vertical and perfectly horizontal, like graph paper, but extremely faint. Domes are separately rendered 2.5D objects on this flat plane.
Draw only these three faint straight VERTICAL lines: x=256, x=768, x=1280. Each line remains at that exact x coordinate at every y, from the far-wall floor seam all the way to the bottom border. All three lines are parallel to the image's LEFT and RIGHT edges. They must have ZERO left/right drift.
Draw only these two faint straight HORIZONTAL lines: y=420 and y=840. They remain at those y coordinates from left to right. Both are parallel to the image's TOP and BOTTOM edges.
Grid cells are 512 pixels wide by 420 pixels tall, approximately 82 percent height. This is an orthographic flat map. NO SLANTED GRID LINES, NO DIAGONAL FLOOR LINES, NO CONVERGENCE. No alternate lines and no extra smaller cells.
The grid color is only #193137 over the #162D33 floor, almost invisible. No bright graphic overlay, no numbers, labels or measurement marks. Soft sediment and a few flat agar flakes remain.

Do not move or redesign any gameplay object. Keep the six small microbes, nine pale food balls, three colored shots, their trails and highlights, the lime shot impact and chips, two teal gel domes, chalky grey cracked crust, muted green hollow bush, nine-dash amber elliptical pore, and the already-level tall FAR glass wall EXACTLY as in image 2. The visible cover layering stays: violet microbe UNDER the bush; magenta shot and its trail ABOVE the fronds. No shadow or outline under bush or pore. The finished teal anchor must still be unmistakable.

The ONLY other correction is the two hollow white ripple rings: make each one 100 pixels wide by 82 pixels high, very faint, at the same centers as before. Do not draw them flatter than this. They lie flat on the same plane as the elliptical pore and bush base.

Projection:
Orthographic 3/4 view from about 55 degrees above, NO vanishing points. The footprint is an ELLIPSE (wider than tall, ratio 0.82); the object stands on it and shows its front (south) side band; the top face rises up to y 191.
The coordinate is from the proportional object guide. Blocking domes stay low, standing over elliptical footprints with a visible south side. Microbes stay flat, slightly foreshortened. Food and shots remain spherical.

Light:
One key light from the upper-left (11 o'clock); highlight on the upper-left of the top face; shading darkens toward the lower-right; optional hairline rim light on the lower-right edge.
Retain soft light lower-right shadows for blockers and microbes only, 25-30 percent darker than local floor.

Premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines. No text, letters, numbers, names, HUD, UI, symbols, buttons, logos, watermark, signature or measurement guides. No eyes or mouths on microbes, no paired similar spots, no filled pale environmental balls. No new elements. One opaque 1536x1024 battle screenshot.
```

## Final inspection and files

All generated results were visually inspected before selection. The four selected files are opaque 1536x1024 PNGs (Format24bppRgb). No alpha was requested. verify.ps1 was NOT run: the user explicitly waived it for mockups. Dimensions and RGB format were read with System.Drawing; no post-generation painting, compositing, resizing, or other pixel editing was applied.

| File | Size | Attempts | Direction |
| --- | --- | --- | --- |
| map_v1_mockup.png | 1536x1024 | 3 | Teal agar and circular droplet domes with internal south bands. |
| map_v2_mockup.png | 1536x1024 | 2 | Olive pond, raised jelly drums, occlusion contour and ribbed silica crust. |
| map_v3_mockup.png | 1536x1024 | 2 | Dark plum biofilm, indigo mounds and sparse aqua streaks. |
| map_v4_mockup.png | 1536x1024 | 3 | Droplet theme through a tilted orthographic camera with a taller far wall. |

The extra initial tool request failed before any image was generated because it supplied more than five references. It is included above for a complete exact-call record and is not counted as an image attempt.

Selected-frame limitations: V1 still has eight visible vent-lip dashes instead of nine after its three-attempt limit. V4's visible floor grid is now parallel, but the ripple ellipses remain more compressed than the specified 0.82 height/width ratio. Anatomy detail, palette matching and dimensional ratios are visual concept approximations rather than pixel-exact sprite composites or measured game geometry. These limitations are retained openly rather than claiming a strict complete pass.

All six rejected image files are retained under out/rejected/ (two V1, one V2, one V3, and two V4). No more than three generated images were made for any frame. V4 and its corrections were generated last, with the finished out/map_v1_mockup.png attached on every call.
