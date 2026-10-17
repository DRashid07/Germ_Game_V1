You are the environment artist for a mobile game. Read STYLE_MAP.md in this folder first and
follow its HARD RULES. Use your built-in image generation tool (image_gen).

VERSION 4 — "Perspektiv / Perspective" (PROBE). Version 1's dark-teal agar world seen through
a tilted camera: the floor is squashed vertically to 82%, and obstacles stand up in 3/4 view
on ELLIPTICAL bases. We need only THREE probe sprites now, to test the camera in the game;
they must be the SAME objects as version 1's approved sprites (attached), just seen from the
tilted camera.

PROJECTION SENTENCE (paste unchanged into every call):
"Orthographic 3/4 view from about 55 degrees above, NO vanishing points. The footprint is an
ELLIPSE (wider than tall, ratio 0.82); the object stands on it and shows its front (south)
side band; its top rises up to y 191."

Attached images (all in ref/):
- ref/template_v4.png — guide for MUCUS and BRITTLE: red footprint ELLIPSE centre (512,560),
  radii 384 x 315 = the silhouette's base; blue cap ellipse centre (512,481), radii 353 x 290
  (its top at y 191); the yellow hatched crescent is the only place art may rise above the
  red ellipse; grey hatching = the front band (about 104 px at the bottom).
- ref/template_v4_bush.png — guide for the canopy: base ellipse; the canopy envelope is the
  red ellipse plus the blue lifted ellipse; WHITE ellipse (radii 134 x 110 around (512,480))
  = the EMPTY centre.
- ref/map_v1_mucus_blob.png, ref/map_v1_brittle_s0.png, ref/map_v1_bush_canopy.png — the
  approved version 1 sprites: MATCH their material, colours, outline and lighting exactly;
  only the viewpoint changes.
- ref/mockup_v4.png — the approved concept of this version: STYLE REFERENCE ONLY. Note: its
  ripple rings are squashed more than 0.82 — follow the templates, not the concept.

All three: 1024x1024, real transparency, no cast shadow, no ground, light from the upper-left,
palette exactly as the matching version 1 sprite.
GENERAL GATE (slots 1-2): corner_a 0, a8 0, aw8 0, centre_a >= 250, bbox x0 >= 120, x1 <= 904,
y0 >= 183, y1 <= 883, p99_noamber <= 0.62.

1. out/map_v4_mucus_blob.png — the version 1 smooth teal gel dome, now a low glossy dome
   standing on the red ellipse, its front (south) band about 104 px, the top filling the blue
   ellipse. Continuous outline #081A20 about 13 px. No sideways bulge beyond the ellipse,
   nothing above y 191.
2. out/map_v4_brittle_s0.png — the version 1 chalky crust dome with its amber cracks (crack
   bodies 4-6% of the top, main cracks at least 24 px, glowing cores at most 1%), in the
   same 3/4 geometry. Continuous outline. Gate extra: amber 0.03-0.05, amber_glow <= 0.01.
3. out/map_v4_bush_canopy.png — the version 1 frond canopy seen at 55 degrees: the fronds
   rise and arch, rooted on an elliptical ring, NO outline; the white ellipse stays MOSTLY
   EMPTY; fronds cover the bottom edge of the red ellipse; only sparse tips above it.
   OWN GATE (run verify with `512 480 110`): corner_a 0, a8 0, aw8 0, centre_a any,
   hollow_a <= 0.30, bbox x0 >= 120, x1 <= 904, y0 >= 158, y1 >= 860, p99_max <= 0.62.

Write ./out/PROMPTS.md as you go and finish with a short report (see STYLE_MAP.md "Output").
