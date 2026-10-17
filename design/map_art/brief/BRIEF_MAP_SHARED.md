You are the VFX/texture artist for a mobile game. Read STYLE_MAP.md in this folder first and
follow its HARD RULES. Use your built-in image generation tool (image_gen).

These FIVE assets are shared by every map theme. Four are NEUTRAL WHITE/GREY: the game tints
them at runtime by multiplying with a colour (amber for the vent swirl, white/teal for
ripples, the theme's shell colour for debris), so they must contain NO hue at all: pure
greys, R = G = B (keep every |R-G|, |G-B|, |R-B| below 24 — verify.ps1 "spread").

Attached images:
- ref/template_swirl.png, ref/template_ring.png, ref/template_grid2x2.png — measurement
  guides; reproduce none of their lines, colours or crosses.
- ref/world_center.png — a real battle frame: STYLE REFERENCE ONLY for where these will be
  used (small, over a dark teal floor, next to glossy outlined microbes). Do not copy it.
- ref/mockup_v1.png — the approved concept frame of the new map: STYLE REFERENCE ONLY.

## 1. out/map_shared_floor_detail.png — micro-texture tile (opaque)
- 1024x1024, opaque, greyscale. It is overlaid on every theme's floor, one tile = 400 world
  units, repeated many times, so it must be SEAMLESS: the left edge continues into the right
  edge and the top into the bottom.
- Mean value exactly middle grey (#808080, mean 0.50 +/- 0.02), very low contrast
  (+/- 6% value). Content: fine wet agar grain, a few faint soft fibres, a few HOLLOW
  micro-bubble rings (at least 12 px, low contrast, odd count, irregular). Flat even light:
  no light direction, no vignette, no objects, nothing that repeats visibly in a 3x3 tiling.
- The game will offset the tile by half and repair the seams itself, so only flag in your
  report if you see an obvious seam.
- verify: p99_max and spread printed; spread must be < 24.

## 2. out/map_shared_vent_swirl.png — rotating current (transparent)
- 1024x1024, real transparency. Follow template_swirl: everything inside the circle radius
  269 around (512,512); nothing outside it.
- THREE thick tapering spiral arms turning the same way (counter-clockwise), at least 40 px
  thick at their roots, thinning to soft points; white cores, light-grey edges, a soft fade
  toward the centre (the centre may be empty or faintly grey).
- ROTATIONALLY NEUTRAL: it spins in the game, so NO light direction, no highlight on one
  side, no shadow side, no outline heavier than 6 px (a thin grey edge is fine).
- verify: corner_a 0, centre may be any, spread < 24, bbox inside 243..781.

## 3. out/map_shared_ripple.png — water ripple ring (transparent)
- 1024x1024, real transparency. Follow template_ring: one soft white ring of radius about
  420 px around (512,512), about 40 px wide, its OUTER edge slightly brighter and crisper,
  with a faint wake fading inward. The centre is fully transparent (alpha 0).
- No hard double lines, no droplets, no colour. verify: centre_a 0, corner_a 0, spread < 24.

## 4. out/map_shared_splash.png — shot-landing splash (transparent)
- 1024x1024, real transparency, within radius 420 of (512,512).
- A soft core RING (hollow, not a filled ball) with 9 droplet streaks radiating out at
  irregular angles and varied lengths, white cores fading to grey. Not a perfect star, no
  filled central ball (balls are the game's food and shots). verify: corner_a 0, spread < 24.

## 5. out/map_shared_debris.png — breakable-crust chunks, 2x2 sheet (transparent)
- 1024x1024, real transparency, four 512x512 cells per template_grid2x2. One chunk in each
  cell, each inside the circle radius 180 around its cell centre, empty gutters between
  cells.
- Four DIFFERENT chunky shell shards (a curved plate, a wedge, a small thick flake, a
  broken arc piece) seen from almost straight above with a slight 3/4 tilt: grey body
  (#9AA6A9 -> #D4DCDE, neutral), white lit upper-left sides, darker lower-right sides, a thick
  near-black #04090B outline (about 15 px). This outline is an exception: debris flies only
  for a moment.
- No amber (the game tints it), no needles, no glow. verify: corner_a 0, spread < 24 (the
  outline is black, still neutral).

## Quality loop and report
Up to 3 tries per asset; reject on any hue, text, filled balls, light direction on the swirl,
or failed verification. Write ./out/PROMPTS.md (exact prompts, -i images, verify lines,
rejections) and finish with a short report.
