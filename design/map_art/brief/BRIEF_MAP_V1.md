You are the environment artist for a mobile game. Read STYLE_MAP.md in this folder first and
follow its HARD RULES. Use your built-in image generation tool (image_gen).

VERSION 1 — "Damla / Droplet" (theme "Aqar": refined dark-teal agar). This is the strict
version: every blocking obstacle is a glossy droplet dome that stays EXACTLY inside its
collision circle; height shows only as a darker side band on its south (bottom) side.

PROJECTION SENTENCE (paste unchanged into every obstacle call):
"Seen from almost straight above. The round footprint stays a perfect circle. Height shows
ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom
centre, thinning to nothing at the left, right and top. Nothing rises above the footprint
circle."

Attached images (all in ref/):
- ref/template_v1.png — measurement guide for MUCUS and BRITTLE: red footprint circle centre
  (512,512) radius 384 = the silhouette; blue top (cap) centre (512,474) radius 346; grey
  hatching = the side band (76 px at the bottom, about 38 px at left/right, 0 at the top).
- ref/template_bush.png, ref/template_vent.png, ref/template_strip.png,
  ref/template_grid2x2.png — guides for the other slots (see each slot).
- ref/mockup_v1.png and ref/mockup_crop_v1.png — the approved concept of this version:
  STYLE REFERENCE ONLY (material, palette, mood). Never copy its scene into a sprite.
- ref/world_center.png — the real game, for scale and context only.

Palette (stay on these):
- floor: pool #1E3B42, mid #162D33, edge #0D1C20; outside #071012
- MUCUS: top #37666F, body #26494F, south band #142C32, specular #5A8C93 (at most 1% of area)
- BRITTLE: shell #77766C, south band #3A3934, crack bodies #D09345, glowing cores #F0B94E ->
  #FFD27A
- BUSH: body #3E9068, tips #4F9E7C, shadow #24543F (muted green — never lime, never mint)
- VENT: lip dashes #F0B94E, hole #050C0E, lit inner wall #2A4A50, shadowed wall #0A171A
- glass: body #2B5963, lip line #8FD3D6, foot crease #0B1A1E
- environment outline #081A20

Make them IN THIS ORDER. After map_v1_mucus_blob.png is accepted, attach it (-i / referenced
image) to every later obstacle call as the KIT ANCHOR: "match its material, outline weight
and lighting".

## Obstacles (1024x1024, real transparency, footprint centre (512,512) radius 384)
Every obstacle: no cast shadow, no ground, no glow or haze outside the silhouette.
GENERAL GATE (slots 1-5 and 9; slots 6-8 have their own): corner_a 0, a8 0, aw8 0,
centre_a >= 250, bbox x0 >= 120, x1 <= 904, y0 >= 120, y1 <= 904 (the red circle is 128..896;
the anti-aliased outline may add a few px), p99_noamber <= 0.62. Also look down the middle
column: the south band at the bottom centre is about 76 px thick (cap edge near y 820;
40-130 px is acceptable).

1. out/map_v1_mucus_blob.png — MUCUS variant A, the KIT ANCHOR. A smooth glossy teal gel
   dome filling the red circle. One broad specular highlight on the upper-left of the top;
   the south band is a deeper, denser gel tone, darkest lower-right. Continuous outline
   #081A20 about 13 px on the red circle. No granules, no spots.
2. out/map_v1_mucus_bloom.png — MUCUS variant B. The same dome (same outline, same light,
   same silhouette) with 7 embedded low-contrast gel vesicles, each at least 60 px, unevenly
   spaced, NO two similar vesicles side by side, none pale or bright, none breaking the
   silhouette.
3. out/map_v1_brittle_s0.png — BRITTLE, undamaged. A matte, faintly chalky grey dried-agar
   crust dome (#77766C) in the same geometry, continuous outline. Amber cracks: crack bodies
   #D09345 covering 4-6% of the top, main cracks at least 24 px wide, secondary at least
   14 px, angular branching; glowing cores (#F0B94E -> #FFD27A) at most 1% of the area. No
   gel gloss, no crystal spikes. Gate extra: amber 0.03-0.05, amber_glow <= 0.01.
4. out/map_v1_brittle_s1.png — stage 1, an EDIT of map_v1_brittle_s0.png: "Edit the
   attached crust. Change ONLY the cracks: amber now covers 9-12% of the top, ONE crack now
   spans the whole top from edge to edge, one large and one small chip painted INSIDE the
   silhouette, far apart from each other; glowing cores at most 2%. Keep the canvas, the
   outer silhouette, the outline, the lighting and all colours identical; do not touch the
   outer edge (its alpha will be discarded and replaced by the stage-0 mask)."
   Gate extra: amber 0.07-0.10, amber_glow <= 0.02.
5. out/map_v1_brittle_s2.png — stage 2, an EDIT of map_v1_brittle_s1.png: amber 18-25% of
   the top, THREE cracks spanning the top, the glowing amber interior visible through the
   widest cracks (glowing cores 4-6% — this stage is SUPPOSED to glow: "about to break"),
   the shell darkened around the cracks, 3 small flakes lifting at different places. Same
   silhouette and outline, no holes through the shell; do not touch the outer edge (its
   alpha will be discarded and replaced by the stage-0 mask).
   Gate extra: amber 0.14-0.20, amber_glow 0.03-0.05.
6. out/map_v1_brittle_rubble.png — the permanent remains after it breaks. A NEW image
   (attach map_v1_brittle_s2.png only as a MATERIAL reference). Completely FLAT on the floor
   (no height, no side band, no outline): 9 flat dull crust shards of different sizes in an
   irregular HEAP weighted toward the lower-right, inside a radius of 346 px around
   (512,512); faint embers in 1 or 3 inner cracks of clearly different length (never 2,
   never mirrored), no amber within 60 px of the heap's outer edge. Paint the shards fully OPAQUE
   (the game draws the decal at 80% opacity). NOT a ring of shards (a ring reads as a vent).
   OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, bbox inside 160..864 on both axes,
   p99_noamber <= 0.47, amber <= 0.02.
7. out/map_v1_bush_base.png — the bush's ground mat, drawn UNDER the microbes. Flat, a dark
   green mat of frond roots and fallen fronds (#24543F -> #3E9068) filling the green dashed
   circle radius 365 of template_bush, soft fuzzy edge, NO outline, no height, no shadow, no
   bright tips. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a >= 250, bbox inside 140..884,
   p99_max <= 0.62.
8. out/map_v1_bush_canopy.png — the bush canopy, drawn ABOVE the microbes (a microbe hiding
   in the bush is seen through its hollow centre). Follow template_bush: 19 thick soft
   fronds (at least 40 px wide at the root) rooted on a ring at about 230 px from (512,470),
   arching outward and curling at the tips; lit from the upper-left; body #3E9068, tips
   #4F9E7C. Attach map_v1_bush_base.png as the palette reference. The WHITE disc of the
   template (radius 134 around (512,470)) must stay MOSTLY EMPTY: fully transparent or only a
   few thin frond tips crossing it. The fronds must cover the bottom edge of the red circle;
   north of the red circle (the pale zone) only a few sparse frond tips. NO outline, no round
   dots, no flowers.
   OWN GATE (run verify with `512 470 134`): corner_a 0, a8 0, aw8 0, centre_a any (it is in
   the hollow), hollow_a <= 0.30, bbox x0 >= 120, x1 <= 904, y0 >= 62, y1 >= 880,
   p99_max <= 0.62.
9. out/map_v1_vent_base.png — VENT: a round pore in the agar floor (negative height). Lip:
   exactly 9 AMBER #F0B94E dashes with clear gaps lying on the red footprint circle radius
   384 — no dark outline. Inside, the pore's inner wall (the grey hatching of template_vent)
   drops toward a hole floor centred (512,539) radius 342: inner wall in SHADOW (#0A171A) on
   the upper-left, LIT (#2A4A50) on the lower-right, a near-black centre #050C0E. No swirl
   (the game adds it), no glow outside the lip. Gate extra: amber 0.02-0.10 (the dashes).

## Environment
10. out/map_v1_floor_macro.png — the whole-dish floor tone, opaque, 1024x1024, plan view,
    flat even light. The dish disc touches all four canvas edges (circle radius 512 centred
    (512,512)); the four corners outside it are flat #071012. Inside: a softly lighter
    centre pool #1E3B42 easing to #162D33, with 7 large soft "agar zones" (each at least 100
    px, value change only +/- 3%), and a gentle darkening over the outer 30 px into the glass
    foot (#0D1C20). NO rings, NO grid, NO objects, NO bright spots, no hard edges.
    verify: p99_max <= 0.35.
11. out/map_v1_rim_north.png — the dish's glass wall seen from inside, a HORIZONTALLY
    TILING strip. Canvas 1536x1024: the strip fills ONLY the band y 320..704 across the full
    width (template_strip); everything above and below is flat #FF00FF. Inside the band,
    bottom to top: a dark wet crease where the glass meets the floor (#0B1A1E) with a thin
    meniscus highlight; the clear teal glass wall (#2B5963 -> #1E4650) with soft vertical
    refraction streaks and a few HOLLOW condensation rings (odd count, irregular); a bright
    lip line #8FD3D6 at most 12 px at the very top of the band. No curvature, no perspective,
    nothing behind the glass (no shapes, no microbes, no spiky silhouettes), no
    high-frequency vertical stripes. The left end must continue
    seamlessly into the right end. OWN GATE: exactly 1536x1024; rows y < 320 and y > 704 are
    flat #FF00FF (key_px is expected here); no key colour inside the band.
12. out/map_v1_clutter.png — four tiny pieces of floor litter that pop when a shot crosses
    them, a 2x2 sheet (template_grid2x2), real transparency, each piece inside radius 200 of
    its cell centre, NO outline, UNLIT (flat, no highlight: the game rotates them), only
    +/- 8% value from the floor, max channel <= 0.45: (a) a flat agar flake, (b) a crumb
    cluster of 7 irregular crumbs, (c) a curled fibre, (d) a scatter of 9 salt grains. No
    round balls, no pairs. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, p99_any <= 0.47,
    each piece inside the circle radius 200 of its cell.

Write ./out/PROMPTS.md as you go and finish with a short report (see STYLE_MAP.md "Output").
