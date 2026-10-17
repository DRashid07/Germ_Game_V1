You are the environment artist for a mobile game. Read STYLE_MAP.md in this folder first and
follow its HARD RULES. Use your built-in image generation tool (image_gen).

VERSION 3 — "Mağara / Cave" (theme "Biofilm": a dark violet biofilm cave inside the petri dish
whose floor answers the microbes with sparse pale bioluminescence). Same strict technique as
version 1: every blocking obstacle stays EXACTLY inside its collision circle.

PROJECTION SENTENCE (paste unchanged into every obstacle call):
"Seen from almost straight above. The round footprint stays a perfect circle. Height shows
ONLY as a darker side band along the bottom (south) edge of the object, widest at the bottom
centre, thinning to nothing at the left, right and top. Nothing rises above the footprint
circle."

Attached images (all in ref/):
- ref/template_v1.png — guide for MUCUS and BRITTLE: red footprint circle centre (512,512)
  radius 384; blue cap centre (512,474) radius 346; grey hatching = the side band.
- ref/template_bush.png, ref/template_vent.png, ref/template_strip_green.png,
  ref/template_grid2x2.png — guides for the other slots.
- ref/mockup_v3.png and ref/mockup_crop_v3.png — the approved concept of this version:
  STYLE REFERENCE ONLY. Never copy its scene into a sprite.
- ref/world_center.png — the real game, for scale only.

Palette:
- floor: centre #2A2238, mid #201B2C, edge #120F1A, EPS strands #352C46; outside #0B0812
- MUCUS (EPS mound): top #52507A, body #3A3858, south band #1E1C2E, specular #7A7299 (lilac
  saturation stays low: S <= 0.35)
- BRITTLE (mineral crust): plates #7A7080, south band #45404C, crack/seam bodies #D09345,
  glowing cores #F0B94E -> #FFD27A
- BUSH (streamers): shadow #1E4A41, body #33796A, tips #4C9A88; glowing tip streaks #A6E4DC
- bioluminescent flecks #A6E4DC (sparse, streak-shaped, never round dots)
- VENT (biofilm pore): lip dashes #F0B94E, throat #06040A, lit inner wall #3E3558
- glass: #4A4466 body, lilac lip line #D9D2F0
- environment outline #081A20
KEY COLOUR if transparency fails: #00FF00 for violet/lilac subjects (mounds, crust, pore),
#FF00FF for the teal bush. The key colour must not appear in the subject.

Make them IN THIS ORDER; after map_v3_mucus_blob.png is accepted, attach it to every later
obstacle call as the KIT ANCHOR ("match its material, outline weight and lighting").

## Obstacles (1024x1024, real transparency, footprint centre (512,512) radius 384)
No cast shadow, no ground, no glow outside the silhouette.
GENERAL GATE (slots 1-5 and 9; slots 6-8 have their own): corner_a 0, a8 0, aw8 0,
centre_a >= 250, bbox x0 >= 120, x1 <= 904, y0 >= 120, y1 <= 904, p99_noamber <= 0.62. Also
look down the middle column: the south band at the bottom centre is about 76 px thick
(cap edge near y 820; 40-130 px is acceptable).

1. out/map_v3_mucus_blob.png — MUCUS A, the KIT ANCHOR: a smooth glossy dark indigo EPS
   slime mound filling the red circle, a lilac specular on the upper-left of the top, a
   darker south band (#1E1C2E) darkest lower-right. Continuous outline #081A20 about 13 px.
2. out/map_v3_mucus_bloom.png — MUCUS B: a MICROCOLONY CLUSTER — the same mound (same
   silhouette, outline, light) made of fused bumpy lobes like a slime cauliflower, each lobe
   at least 60 px, irregular, no pairs, no lobes outside the silhouette.
3. out/map_v3_brittle_s0.png — BRITTLE undamaged: a MINERALISED CRUST dome of chalky
   mauve-grey calcite plates (#7A7080); the seams between plates are the amber cracks: crack
   bodies 4-6% of the top, main seams at least 24 px wide, glowing cores at most 1%.
   Continuous outline. No crystal spikes, no metal. Gate extra: amber 0.03-0.05,
   amber_glow <= 0.01.
4. out/map_v3_brittle_s1.png — EDIT of s0: amber 9-12% of the top, one seam spanning the
   whole top, one large and one small chipped plate far apart from each other, cores at
   most 2%. Silhouette, outline, lighting, colours identical; do not touch the outer edge
   (its alpha will be discarded and replaced by the stage-0 mask). Gate extra: amber
   0.07-0.10, amber_glow <= 0.02.
5. out/map_v3_brittle_s2.png — EDIT of s1: amber 18-25% of the top, three spanning seams,
   the amber core glowing through the open seams (cores 4-6%), plates darkened around the
   seams. Same silhouette, no holes; do not touch the outer edge. Gate extra: amber
   0.14-0.20, amber_glow 0.03-0.05.
6. out/map_v3_brittle_rubble.png — NEW image, s2 attached as material reference only. FLAT:
   an irregular heap of 9 chalk plates of different sizes, weighted to the lower-right,
   inside radius 346 of (512,512); no outline, no height; faint embers in 1 or 3 inner seams
   of clearly different length (never 2). Paint the plates fully OPAQUE (the game draws the
   decal at 80% opacity). NOT a ring. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, bbox
   inside 160..864 on both axes, p99_noamber <= 0.47, amber <= 0.02.
7. out/map_v3_bush_base.png — a flat dark teal filament mat (#1E4A41 -> #33796A) in the green
   dashed circle radius 365 of template_bush, fuzzy edge, no outline, no height, no shadow.
   OWN GATE: corner_a 0, a8 0, aw8 0, centre_a >= 250, bbox inside 140..884, p99_max <= 0.62.
8. out/map_v3_bush_canopy.png — STREAMER canopy drawn ABOVE the microbes: 19 flowing
   streamer fronds, each at least 40 px wide at the root, rooted on a ring about 230 px from
   (512,470), body #33796A, lit upper-left. Each tip ends in a short glowing pale-aqua
   STREAK (#A6E4DC, length at least 3x its width — never a round dot); all glow together at
   most 3% of the area. Attach map_v3_bush_base.png as the palette reference. The white disc
   of template_bush (radius 134 around (512,470)) stays MOSTLY EMPTY; streamers cover the
   bottom edge of the red circle; only sparse tips north of it. NO outline, no full-body
   glow. OWN GATE (run verify with `512 470 134`): corner_a 0, a8 0, aw8 0, centre_a any (it
   is in the hollow), hollow_a <= 0.30, bbox x0 >= 120, x1 <= 904, y0 >= 62, y1 >= 880;
   p99_max may exceed 0.62 only because of the tip streaks.
9. out/map_v3_vent_base.png — BIOFILM PORE: lip = exactly 9 AMBER dashes on the red circle
   radius 384, no dark outline; a slick violet inner wall (the grey hatching of
   template_vent), in shadow on the upper-left, lit (#3E3558) on the lower-right; a black
   throat #06040A around (512,539). No swirl. Gate extra: amber 0.02-0.10 (the dashes).

## Environment
10. out/map_v3_floor_macro.png — opaque 1024x1024, plan view, flat light. Dish disc touching
    all four edges, corners flat #0B0812. Dark plum-indigo #201B2C with a slightly lighter
    centre #2A2238, a fibrous matrix of soft branching EPS strands (#352C46, at least 12 px
    wide, low contrast) and SPARSE tiny pale-aqua glowing flecks (#A6E4DC): short streaks at
    most 6 px long and 2 px wide (one canvas px is about 2.3 world units, so a fleck stays far
    smaller than a food ball), at most 1% of the area, never round dots, never pairs. Gentle
    darkening into the glass foot over the outer 30 px. No magenta, no rings, no grid, no
    objects. OWN GATE: p99_max <= 0.35 (the flecks are under 1%, so p99 still holds).
11. out/map_v3_rim_north.png — horizontally tiling strip, canvas 1536x1024, the strip ONLY in
    the band y 320..704. Use ref/template_strip_green.png: above and below flat **#00FF00**
    (not magenta: this subject is violet). Bottom to top: violet biofilm sheets creeping up
    from a dark foot and thinning with height (drips at most a quarter of the band), the
    glass #4A4466 with a few glowing aqua FLECKS (streaks, not dots, none side by side), a
    cool lilac lip line #D9D2F0 at most 12 px at the top. Nothing behind the glass (no
    shapes, no microbes, no spiky silhouettes). Seamless left-right, no curvature, no text.
    OWN GATE: exactly 1536x1024; rows y < 320 and y > 704 are flat #00FF00 (key_px is
    expected here); no key colour inside the band.
12. out/map_v3_clutter.png — 2x2 sheet (template_grid2x2), real transparency, unlit, no
    outline, +/- 8% value from the floor, max channel <= 0.45: (a) a knot of EPS strands,
    (b) 7 irregular mineral grains, (c) a slime flake, (d) a branching filament. No balls,
    no glow, no pairs. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, p99_any <= 0.47,
    each piece inside the circle radius 200 of its cell.

Write ./out/PROMPTS.md as you go and finish with a short report (see STYLE_MAP.md "Output").
