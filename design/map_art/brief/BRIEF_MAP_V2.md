You are the environment artist for a mobile game. Read STYLE_MAP.md in this folder first and
follow its HARD RULES. Use your built-in image generation tool (image_gen).

VERSION 2 — "Sütun / Pillar" (theme "Gölməçə / Pond Drop": a sunlit pond drop inside the
petri dish — olive silt, slate jelly drums, silica diatoms, pondweed). This is the most
"raised" version: blocking obstacles are squat PILLARS whose top is lifted slightly above the
round base, like the low walls of top-down arena games.

PROJECTION SENTENCE (paste unchanged into every obstacle call):
"Seen from almost straight above, like a low pillar: its top is lifted up the image by a
small amount, so a darker front band shows below it along the bottom (south) edge. The round
footprint stays a perfect circle; the top may rise above the footprint ONLY inside the thin
yellow-hatched crescent of the template (at most 38 px, up to y 90)."

Attached images (all in ref/):
- ref/template_v2.png — guide for MUCUS and BRITTLE: red footprint circle centre (512,512)
  radius 384; blue cap circle centre (512,443) radius 353 (its top edge at y 90); the yellow
  hatched crescent (38 px deep at the top, y 90..128, thinning to nothing at the sides near
  y 310) is the ONLY place art may leave the red circle; the grey hatched crescent is the
  front band (100 px at the bottom).
- ref/template_bush.png, ref/template_vent.png, ref/template_strip.png,
  ref/template_grid2x2.png — guides for the other slots.
- ref/mockup_v2.png and ref/mockup_crop_v2.png — the approved concept of this version:
  STYLE REFERENCE ONLY. Never copy its scene into a sprite. Note: in that concept the big
  drum's front band does not reach its base ring — in the sprites the front band must reach
  all the way down to the red circle (no floor visible between them).
- ref/world_center.png — the real game, for scale only.

Palette:
- floor: silt mid #2B3023, sunlit pool #3A3E2C (small), edge #181C14; outside #0A1310
- MUCUS (jelly drum): top #4A6670, body #36505A, front band #22363E, specular #75909A
- BRITTLE (diatom pillbox): silica #76786E, ribs #4E544C, front band #33372F, crack bodies
  #D09345, glowing cores #F0B94E -> #FFD27A
- BUSH (pondweed): body #3F8A70, tips #519C82, shadow #1F4A3D (never lime, never mint)
- VENT (bubbler): lip dashes #F0B94E, throat #070B08, lit inner wall #3A4434
- glass: algae-filmed #3D5B52, warm lip line #E8EDC8
- environment outline #081A20

Make them IN THIS ORDER; after map_v2_mucus_blob.png is accepted, attach it to every later
obstacle call as the KIT ANCHOR ("match its material, outline weight and lighting").

## Obstacles (1024x1024, real transparency)
No cast shadow, no ground, no glow outside the silhouette.
GENERAL GATE (slots 1-5 and 9; slots 6-8 have their own): corner_a 0, a8 0, aw8 0,
centre_a >= 250, bbox x0 >= 120, x1 <= 904, y0 >= 82, y1 <= 904, p99_noamber <= 0.62. Also
look down the middle column: the front band at the bottom centre is about 100 px thick
(cap edge near y 796;
60-150 px is acceptable).

1. out/map_v2_mucus_blob.png — MUCUS A, the KIT ANCHOR: a squat glossy JELLY DRUM. Rounded
   top edge, the top filling the blue circle (lifted, up to y 90), a 100 px front band below
   it at the bottom that reaches down to the red circle, with a soft inner glow line just
   under the top rim; cool slate-blue translucent gel, specular upper-left. Continuous
   outline #081A20 about 13 px around the whole silhouette. No beads, no sideways bulge
   beyond the red circle.
2. out/map_v2_mucus_bloom.png — MUCUS B: a FROGSPAWN CUSHION — the same drum (same
   silhouette, outline and light) built of fused lumpy gel beads, each at least 60 px, the
   SAME value as the drum, NO dots or cores inside the beads, no pale beads, no pairs.
3. out/map_v2_brittle_s0.png — BRITTLE undamaged: a round silica DIATOM PILLBOX drum in the
   same geometry. Its top carries fine radial ribs that start from an OFF-CENTRE smooth patch
   (NO central dot, no radial rosette); pale grey-green glass, not chrome, no gear teeth.
   Amber cracks across the ribs: crack bodies 4-6% of the top, main cracks at least 24 px,
   glowing cores at most 1%. Continuous outline. Gate extra: amber 0.03-0.05,
   amber_glow <= 0.01.
4. out/map_v2_brittle_s1.png — EDIT of s0, THE TOP ONLY: amber 9-12% of the top, one crack
   spanning the whole top, one large and one small chip in the top rim far apart from each
   other, cores at most 2%. The front band, silhouette, outline and lighting stay identical;
   do not touch the outer edge (its alpha will be discarded and replaced by the stage-0
   mask). Gate extra: amber 0.07-0.10, amber_glow <= 0.02.
5. out/map_v2_brittle_s2.png — EDIT of s1, THE TOP ONLY: amber 18-25% of the top, three
   spanning cracks, glowing interior through the widest cracks (cores 4-6%), the top plate
   starting to split. Same silhouette, no holes; do not touch the outer edge (its alpha will
   be discarded). Gate extra: amber 0.14-0.20, amber_glow 0.03-0.05.
6. out/map_v2_brittle_rubble.png — NEW image, s2 attached as material reference only. FLAT
   on the floor: an irregular heap of 9 silica shards and rib fragments of different sizes,
   weighted to the lower-right, inside radius 346 of (512,512); no outline, no height; faint
   embers in 1 or 3 inner cracks of clearly different length (never 2), no amber near the
   edge. Paint the shards fully OPAQUE (the game draws the decal at 80% opacity). NOT a
   ring. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, bbox inside 160..864 on both
   axes, p99_noamber <= 0.47, amber <= 0.02.
7. out/map_v2_bush_base.png — a flat dark olive-teal algae filament mat (#1F4A3D ->
   #3F8A70) in the green dashed circle radius 365 of template_bush, fuzzy edge, no outline,
   no height, no shadow. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a >= 250, bbox inside
   140..884, p99_max <= 0.62.
8. out/map_v2_bush_canopy.png — POND WEED canopy drawn ABOVE the microbes: 17 twisted
   ribbon-like pondweed strands and spiral filaments, each at least 40 px wide at the root,
   rooted on a ring about 230 px from (512,470), tips #519C82, lit upper-left. Attach
   map_v2_bush_base.png as the palette reference. The white disc of template_bush (radius
   134 around (512,470)) stays MOSTLY EMPTY; the strands cover the bottom edge of the red
   circle; only sparse tips in the pale zone north of it. NO outline, no flowers, no dots.
   OWN GATE (run verify with `512 470 134`): corner_a 0, a8 0, aw8 0, centre_a any (it is in
   the hollow), hollow_a <= 0.30, bbox x0 >= 120, x1 <= 904, y0 >= 62, y1 >= 880,
   p99_max <= 0.62.
9. out/map_v2_vent_base.png — BUBBLER SPRING: a round hole in the silt. Lip = exactly 9
   AMBER dashes on the red circle radius 384, no dark outline; a silt-rim lip; the inner
   wall (the grey hatching of template_vent) in shadow on the upper-left, lit (#3A4434) on
   the lower-right, dark throat #070B08 around (512,539). NO painted bubbles (the game draws
   them). Gate extra: amber 0.02-0.10 (the dashes).

## Environment
10. out/map_v2_floor_macro.png — opaque 1024x1024, plan view, flat light. Dish disc
    touching all four edges, corners flat #0A1310. Warm olive silt #2B3023, a SMALL sunlit
    pool #3A3E2C (at most 15% of the disc), 7 faint ochre diatom-dust drifts and a few darker
    organic smudges, gentle darkening into the glass foot over the outer 30 px. No caustics
    (separate asset), no rings, no grid, no objects, no bright greens. OWN GATE:
    p99_max <= 0.35.
11. out/map_v2_rim_north.png — horizontally tiling strip, canvas 1536x1024, the strip ONLY in
    the band y 320..704 (template_strip), flat #FF00FF above and below. Bottom to top: a
    dark foot with olive algae fuzz (at most one third of the band height) thinning upward,
    glassy green-teal glass (#3D5B52), a few HOLLOW bubble rings (odd count, irregular, none
    side by side), a warm sunlit lip line #E8EDC8 at most 12 px at the top. Nothing behind
    the glass (no shapes, no microbes, no spiky silhouettes). Seamless left-right, no
    curvature, no text. OWN GATE: exactly 1536x1024; rows y < 320 and y > 704 are flat
    #FF00FF (key_px is expected here); no key colour inside the band.
12. out/map_v2_clutter.png — 2x2 sheet (template_grid2x2), real transparency, unlit, no
    outline, +/- 8% value from the floor, max channel <= 0.45: (a) half of a diatom valve,
    (b) an algae scrap, (c) a detritus flake, (d) a scatter of 9 silt grains. No balls, no
    pairs. OWN GATE: corner_a 0, a8 0, aw8 0, centre_a any, p99_any <= 0.47, each piece
    inside the circle radius 200 of its cell.
13. out/map_shared_caustics.png — pond light caustics tile (used only in this version, on
    HIGH quality): opaque GREYSCALE 1024x1024, black base with a thin bright wavy network of
    irregular cells (lines 6-14 px, soft), seamless (left into right, top into bottom), no
    blobs, no perfect hexagons, no dense noise. OWN GATE: spread < 24.

Write ./out/PROMPTS.md as you go and finish with a short report (see STYLE_MAP.md "Output").
