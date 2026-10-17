You are the environment concept artist for a mobile game. Read STYLE_MAP.md in this folder
first and follow its HARD RULES. Use your built-in image generation tool (image_gen).

We are choosing between FOUR art directions for the battle map. For each direction paint ONE
concept "screenshot" of a battle — NOT a game asset, only for comparing the directions side
by side. They must look like real frames of THIS game, so the microbes, balls and food must
match the attached game frames exactly; only the map (floor, obstacles, glass wall) changes.

Attached images (all in ref/):
- ref/world_center.png, ref/world.png, ref/world_solo.png — real battle frames of the game as
  it is now (ignore the HUD: no HUD, no text in your images). Note the scale: microbe bodies
  about 60 px wide on a 1280x720 frame, food balls small and pale green, the dark teal floor.
- ref/species_0.png (ciliate: hairy rounded body with a tail), ref/species_1.png (heliozoan:
  round body with thin ray-legs ending in small balls), ref/species_2.png (amoeba: a rounded
  triangular blob) — the three microbe species. They have NO FACE. Thick near-black outline,
  glossy cel-shaded jelly, the player's colour.
- ref/map0.png, ref/map1.png, ref/map2.png — top views of the three obstacle layouts.
- ref/menu_bg.jpg — the approved lobby background: STYLE REFERENCE ONLY for rendering
  quality and mood (do not copy its scene).

## Shared rules for all four frames
- 1536x1024, opaque. No HUD, no joystick, no buttons, no names, no text of any kind.
- The frame shows a part of the dish about 930 x 620 world units, so the scale is about
  1.65 image px per world unit: microbe bodies about 90 px wide, food balls about 25 px, shot
  balls about 30 px with short trails in the shooter's colour, obstacles 190-480 px across.
- The glass wall of the dish arcs gently across the TOP 15-20% of the frame (we are near
  the north edge); above it is the dark outside.
- Five or six microbes: a lime ciliate (the player) near the centre; a magenta heliozoan on
  the right; a blue amoeba lower-left; an amber ciliate upper-right; one violet microbe
  partly hidden UNDER a bush (the bush's fronds are drawn over it). All FACELESS, exactly in
  the game's style. 8-10 pale food balls (#D9FFC0) scattered on open floor. Three shot balls
  in flight; the shots fly ABOVE the bush fronds (never hidden by them).
- Obstacles (all four kinds must appear, so the frames are comparable):
  (a) two or three BLOCKING blobs (continuous dark outline) — one smooth, one granular;
  (b) one BREAKABLE crust with glowing AMBER cracks, being hit right now (a few chips
  flying);
  (c) one BUSH: soft fronds, NO outline, a hollow centre, the hidden violet microbe under it;
  (d) one VENT: a round pore in the floor with a lip of 9 AMBER dashes and a slowly turning
  amber swirl inside.
- Soft white ripple rings on the floor where two balls just landed.
- Light from the upper-left; shadows soft and LIGHT (only 25-30% darker), offset to the
  lower-right. Bush and vent have NO shadow (they are passable).
- Keep the floor DARK and low in contrast so microbes and food pop.

## 1. out/map_v1_mockup.png — "Damla / Droplet" (strict, the current identity finished)
- Projection: straight top-down; every obstacle is a glossy droplet dome that stays EXACTLY
  inside its round base — height shows only as a darker side band along its bottom (south)
  edge. Nothing rises above its base.
- Floor: smooth dark teal agar #162D33 with a slightly lighter pool #1E3B42 toward the
  bottom of the frame, a faint square grid, one wide soft sediment band, a few flat agar
  flakes. Glass wall: clear teal glass seen from inside (#2B5963), a dark wet crease where
  it meets the floor, a thin bright cyan-white lip line (#8FD3D6) on top, a few HOLLOW
  condensation rings. Outside: very dark #071012 with huge blurred colony shapes far away
  (blurred blobs and fronds, NOT microbe shapes).
- Blobs: teal gel domes (top #37666F, body #26494F, south band #142C32, broad specular
  #5A8C93 upper-left). Granular one: the same dome with 7 low-contrast vesicles. Crust: matte
  chalky grey #77766C with amber #D09345 cracks and glowing #F0B94E cores. Bush: muted green
  fronds (#3E9068, tips #4F9E7C), not lime, not mint.

## 2. out/map_v2_mockup.png — "Sütun / Pillar" (pond drop, raised pillars)
- Projection: top-down floor, but the BLOCKING obstacles are short PILLARS: each top face is
  lifted a little above its round base (about one tenth of its radius) with a visible darker
  front band below it, like low walls in top-down arena games. Show the occlusion honestly:
  one microbe just NORTH of a jelly drum is partly hidden behind the drum's top, and its
  outline shows through the drum as a thin glowing line; a thin SOLID (not dashed) pale ring
  marks that drum's true round base.
- Theme: a sunlit pond drop inside the petri dish. Olive silt floor #2B3023 with a SMALL
  sunlit pool #3A3E2C and a faint pale caustic light network; glass wall coated in a thin
  olive algae film with a warm lip highlight #E8EDC8 and HOLLOW bubble rings; deep
  pond-green darkness beyond with blurred giant diatoms far below.
- Obstacles: an island of one big slate-blue jelly drum (top #4A6670, front #22363E) ringed
  by 3 small jelly pebbles, one of them a "frogspawn" cushion of fused gel beads (beads are
  lumpy, same value, NO dots inside); a grey-green silica diatom pillbox (#76786E) with
  radial ribs that start from an OFF-CENTRE smooth patch (no central dot) and AMBER cracks,
  being hit; a pondweed bush of twisted muted-teal ribbons (#3F8A70) over a hidden microbe;
  a round bubbler hole with an amber dashed lip and hollow bubble rings rising.

## 3. out/map_v3_mockup.png — "Mağara / Cave" (biofilm, strict technique)
- Projection: identical to version 1 (domes stay inside their bases, south side bands only).
- Theme: a dark violet BIOFILM CAVE inside the petri dish. Floor of dark plum-indigo slime
  #201B2C laced with soft branching strands and sparse tiny pale-aqua glowing flecks (short
  streaks, never round dots); a soft pale-aqua glow pool on the floor under each microbe.
  Glass wall overgrown with violet biofilm sheets, glowing aqua flecks, a cool lilac lip
  line #D9D2F0; violet darkness beyond with faint distant glowing colonies.
- Obstacles: glossy indigo slime mounds (top #52507A, specular #7A7299), one bumpy
  microcolony cluster of fused lobes, a chalky mauve-grey crust of plates (#7A7080) with
  glowing AMBER seams being hit (chalk chips flying), a bush of flowing muted-teal streamers
  (#33796A) with short glowing aqua STREAK tips over a hidden microbe, one pore with an amber
  dashed lip and a slowly turning amber swirl.
- Keep the floor DARK so the microbes — including the violet and magenta ones — pop. Glow is
  sparse. No neon purple, no bright magenta, no glowing floor everywhere.

## 4. out/map_v4_mockup.png — "Perspektiv / Perspective" (version 1 seen through a tilted camera)
Make this one LAST and attach your finished out/map_v1_mockup.png as the theme reference:
same theme, palette, microbes, obstacles and juice as version 1.
- CAMERA: tilted, an orthographic view from about 55 degrees above with NO vanishing points
  (parallel lines stay parallel). The floor is squashed vertically to about 82%: round things
  lying on the floor (the dish edge, the bush base, the pore, the ripple rings, the flat
  microbes themselves) become slightly wide ellipses. Obstacles stand up in 3/4 view as low
  glossy domes on elliptical bases, showing their front (south) side. The glass wall at the
  top is the FAR wall, so it rises noticeably taller. Light upper-left, light shadows to the
  lower-right.

## Quality loop
Look at every result yourself. Reject and regenerate (max 3 tries per frame) if: any text,
letters, HUD or UI; any face or eyes on a microbe or object; microbes that do not look like
the attached species; filled pale balls used as decoration (bubbles must be hollow rings);
a version 1 or 3 dome rising above its base; neon or saturated floors; perspective with
vanishing points; a bush drawn with an outline; shots hidden under bush fronds.
No alpha is needed (opaque frames). verify.ps1 is not needed for mockups.

Finish by writing ./out/PROMPTS.md (exact prompt per call, -i images used, rejections) and a
short report: each file, its pixel size, and one sentence on how it differs from the others.
