# Germ Arena — shared rules for MAP art (read this first, every run)

Game: "Germ Arena", a mobile LANDSCAPE online arena. Players are single-celled microbes
swimming in a giant water-filled PETRI DISH and shooting glossy balls at each other. The
camera looks down at the dish floor. We are giving the battle map a premium "2.5D" look in
the spirit of chunky top-down mobile arena games: obstacles show a lit top and a darker front
(south) band, soft light shadows, swaying cover, breakable crusts. The map is drawn as
separate sprites that the game places on circular collision footprints, so every obstacle
image must be REGISTERED to a template.

Units: every "px" in these briefs means pixels of the 1024x1024 canvas (or 1536x1024 for
strips and mockups), unless it says "world units".

## HARD RULES — an image that breaks one of these is rejected
1. NO FACES anywhere: no eyes, pupils, mouths, eyebrows. NO TWO SIMILAR SPOTS SIDE BY SIDE
   (two bubbles, two vesicles, two chips, two embers or two glowing dots next to each other
   read as eyes).
2. No text, letters, numbers, logos, symbols, watermarks or signatures.
3. No humans, hands, lab equipment, metal, chrome, machinery or hard geometric corners.
   Everything is soft, wet, gelatinous, organic. The only angular lines allowed are cracks
   in breakable crusts and ribs of diatom shells.
4. Never write a real game or company name inside an image prompt. Describe the look:
   "premium chunky mobile arena game art, soft 3D cel shading, thick clean outlines".
5. Never a FILLED pale (whitish or pale-green) or saturated ROUND dot or ball, at any size.
   Pale round balls are the game's FOOD (#D9FFC0) and the shots; the map must never imitate
   them. Bubbles and beads are drawn as HOLLOW rings or lumpy, non-round shapes.
6. Avoid these words in prompts for props: eye, iris, pupil, nucleus, face, cute, character,
   creature, egg, drain, lava. (Say "top", "cap" or "upper surface", never "top face".)

## Light — one sentence, the same in every call
"One key light from the upper-left (11 o'clock); highlight on the upper-left; shading darkens
toward the lower-right; optional hairline rim light on the lower-right edge."
Never rotate the light. Never paint a cast shadow on the ground: the game makes shadows.

## Projection — paste the version's sentence unchanged into every call of its kit
- V1 / V3 (Damla): "Seen from almost straight above. The round footprint stays a perfect
  circle. Height shows ONLY as a darker side band along the bottom (south) edge of the
  object, widest at the bottom centre, thinning to nothing at the left, right and top.
  Nothing rises above the footprint circle."
- V2 (Sütun): "Seen from almost straight above, like a low pillar: its top is lifted up the
  image by a small amount, so a darker front band shows below it along the bottom (south)
  edge. The round footprint stays a perfect circle; the top may rise above the footprint
  ONLY inside the thin yellow-hatched crescent of the template (at most 38 px, up to y 90)."
- V4 (Perspektiv): "Orthographic 3/4 view from about 55 degrees above, NO vanishing points.
  The footprint is an ELLIPSE (wider than tall, ratio 0.82); the object stands on it and
  shows its front (south) side band; its top rises up to y 191."

## Registration (templates) — geometry is given in PIXELS
Templates live in ref/ and are MEASUREMENT GUIDES ONLY. Reproduce none of their lines,
colours, hatching, crosses or the arrow. Colour key:
- RED circle/ellipse = the footprint = the collision circle. The object's outer silhouette
  sits exactly on it: centre (512,512), radius 384 (V4: ellipse centre (512,560), radii
  384 x 315). In template_vent the red circle runs under the amber dashes.
- BLUE = the edge of the top (cap). In template_vent: the floor of the hole.
- GREY hatching = the visible south side band. In template_vent: the pore's INNER WALL
  (widest at the top, narrow at the bottom).
- YELLOW hatching (V2 only) = the only place the cap may rise above the red circle: a
  crescent 38 px deep at the top (y 90..128), thinning to nothing at the sides.
- GREEN dashes (bush) = the bush base mat; WHITE disc = the bush's EMPTY centre; the pale
  zone north of the red circle = sparse frond tips only.
- AMBER dashes (vent) = the vent's broken lip.
- ORANGE arrow = where the light comes from (not drawn on neutral or unlit templates).
Images passed with -i, always name their role in the prompt in this order:
(1) template = "measurement guide; reproduce none of its lines, colours or arrow";
(2) kit anchor (the version's approved mucus_blob) = "match its material, outline weight
    and lighting";
(3) mockup crop or game frame = "style reference only; do not copy the scene".
image_gen accepts AT MOST 5 reference images per call — pick the ones the slot needs.

## Outline — one rule per kind (this is how players read the rules)
- MUCUS (blocks) and BRITTLE (blocks, breakable): continuous dark outline #081A20, about
  13 px wide.
- BUSH (passable, hides): NO outline at all; fuzzy frond edge.
- VENT (passable hole that pushes): NO dark outline; its lip is exactly 9 AMBER #F0B94E
  dashes with clear gaps.
- Rubble, clutter, floors: no outline. Shared debris chunks are the one exception (they
  fly only for a moment) and keep a thick near-black outline.

## Values (the floor is dark; microbes and food must pop)
- Obstacle bodies (MUCUS, BRITTLE shell, VENT walls): no pixel brighter than #949494 (max
  channel 0.58), except a specular highlight of at most 1% of the area, which may reach
  0.62, and the amber listed below.
- BUSH may reach max channel 0.62 (never above: brighter greens bloom in the game's glow).
- Floors: no pixel brighter than #595959 (0.35), except glowing flecks a brief names.
- Exempt by design: rim lip lines (bright, thin), shared neutral VFX (white, tinted in the
  game), shared debris (grey/white, tinted in the game).
- Glow (bright emissive) allowed only where a brief names it, with its maximum share.
- Amber is allowed ONLY for BRITTLE cracks (bodies #D09345, glowing cores #F0B94E ->
  #FFD27A) and the VENT lip dashes. verify.ps1 measures it: `amber` = share of opaque pixels
  that are amber, `amber_glow` = the glowing part, `p99_noamber` = the value cap without
  the amber.
- No environment colour may be a saturated, bright version of a microbe colour (lime
  #7CFF5B, cyan #2FE8E0, magenta #FF5BC8, amber #FFB43D, violet #A96BFF, coral #FF6B5B,
  blue #4D9BFF, mint #4BFFA5, pink #FF87A8, gold #F2E14C).
- OBSTACLE SPRITES: smallest painted feature 40 px (sprites are shown as small as 64 px on
  screen). Main cracks at least 24 px wide, secondary cracks at least 14 px. Floors, rims and
  VFX follow the sizes their slot gives. Repeated features in ODD counts with IRREGULAR
  spacing.

## Transparency — where earlier attempts FAILED
image_gen sometimes answers "transparent background" by PAINTING A CHECKERBOARD (24-bit
RGB, no alpha). Unusable. The workflow that worked in this project:
1. generate with `transparent_background: true`;
2. run verify.ps1 on the UNTOUCHED image_gen file first: format must be Format32bppArgb and
   corner_a 0. If not, run an image_gen EDIT that removes the background and outputs real
   transparency, preserving the subject exactly (use case: background-extraction);
3. last resort: paint on a flat key colour — #FF00FF, or #00FF00 for violet/lilac subjects —
   and say that the key colour must not appear anywhere in the subject. Keep that file as
   `<name>_key.png`; the pipeline removes the key.
Watch the empty areas INSIDE shapes too (bush hollow, gaps between shards, ring centres).
Rim STRIPS are different: their flat key fill above and below the band is intentional, the
file keeps its normal name, and key_px is expected there.

## Exact size before verification
image_gen often returns a different pixel size than asked (e.g. 1254x1254 for a square). The
templates and every pixel number in the briefs are for 1024x1024 (or 1536x1024 for strips
and mockups). After the untouched-file check above, bring every final to the exact size
with the provided script (proportional only, keeps alpha; it prints the source format):
`powershell -ExecutionPolicy Bypass -File resize.ps1 out\rejected\<name>_orig.png out\<name>.png 1024 1024`
`powershell -ExecutionPolicy Bypass -File resize.ps1 out\rejected\<name>_orig.png out\<name>.png 1536 1024`
Skip resizing when the size is already exact. Keep the untouched original as
out\rejected\<name>_orig.png.

## Verification — run it on EVERY final before accepting it
`powershell -ExecutionPolicy Bypass -File verify.ps1 out\<file>.png [hx hy hr]`
It prints: format, corner_a, a8, aw8, centre_a, opaque, bbox, p99_max, spread, key_px,
checker, [hollow_a], p99_any, p99_noamber, amber, amber_glow, spread8.
Accept a transparent asset only if format=Format32bppArgb, corner_a=0, a8=0, aw8=0,
key_px=0, AND its slot's gate line holds. When a slot gives its own gate line, it REPLACES
the section's general gate line for that slot. "checker" is informational only (white and
grey art scores high by design); LOOK for a checkerboard painted inside holes instead.
Report the numbers for every file.

## Quality loop
Look at every result yourself. Up to 3 tries per slot. Reject and redo on: any text, any
face or eye-like pair, wrong alpha or checkerboard, art outside the allowed silhouette, the
wrong outline type, a value-cap breach, a missing hollow, a key colour inside the subject,
template lines copied into the art, a cast shadow or ground painted around a sprite. If the
only problem is the pixel size, resize — do not regenerate.
NEVER STOP THE KIT. After 3 tries for a slot, keep the BEST candidate as the final (save it
under the final name), list its deviations in PROMPTS.md, and continue with the next slot. Hard
rules (faces, text, wrong alpha, wrong outline type) still decide which candidate is best.
Geometry numbers in the briefs are targets with tolerance: a footprint/bbox within 8 px and a
side band within roughly half to double its stated thickness are acceptable.

## Output
- One image per image_gen call (no variation grids, except 2x2 sheets that follow
  template_grid2x2).
- Save finals into ./out/ with the EXACT file names from the brief. Keep rejected tries in
  ./out/rejected/ (name_try1.png ...). Work only inside this folder. Python is NOT installed.
- If the tool saves images somewhere else (e.g. ~/.codex/generated_images/...), copy the
  chosen file into ./out/.
- Write ./out/PROMPTS.md AS YOU GO (after each accepted slot), not only at the end — a run
  can be cut off by a usage limit. For every final: the exact prompts of every call
  (generation and edits), which -i images were used, the verify.ps1 line, and one sentence
  on what you rejected and why. Finish with a short report.
