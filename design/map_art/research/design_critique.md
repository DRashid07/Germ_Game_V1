# Strict review: Germ Arena 2.5D map design (before any Codex image is generated)

**Verdict:** The design is sound in structure: three themes, a technique ladder, mockups behind a review gate, and stages made as edits. It is **not ready to generate yet**. Fourteen defects must be fixed in the briefs and specs first. Five of them would ship wrong or misleading art, and one is a server change that nobody has flagged. Corrected asset lists and the prompt rules are at the end.

What I checked:
- I read the two research reports in full, plus ART_BIBLE §1/§4/§4b/§5, BRAWL_UPGRADE, STYLE.md, menu_art README, BRIEF_ENV, BRIEF_AIM, PROMPTS_AIM, `dish_map.gd`, `palette.gd`, the obstacle, canopy, wall and `_draw` code in `arena.gd`, `minimap.gd` and `design/map_art/template.gd`.
- I re-derived the obstacle counts and radii from `dish_map.gd`; the design's table is correct.
- I computed every contrast with a WCAG luminance script plus a deuteranopia/protanopia simulation (Viénot). The scripts are in the scratchpad: `review_c.js`, `review_c2.js`, `review_c3.js`.

---

## A. Blocking findings (fix before the first image)

| # | Severity | Finding | Evidence | Fix |
|---|---|---|---|---|
| B1 | **High, unflagged server change** | **Only layout 0 is ever played.** `DishMap.layout` is set only in `map_preview.gd`, `sim_test.gd` and `boot.gd --map-layout` (the stand). Nothing in server, net or arena code chooses a layout. "One theme per layout" therefore means players only ever see Aqar. The Sütun playtest "on Arxipelaq's 74 px gaps" is impossible in a real match. | grep of `scripts/` | Flag it as an owner decision: layout rotation needs a server choice, a handshake byte, bots and `--simtest`. Alternatives with no server change: (a) a **practice-only** client flag that sets `DishMap.layout` (offline sim) for the playtest; (b) bind the theme to a client setting instead of the layout. |
| B2 | High | **Shots and trails go under the canopy after the F1 fix.** `_trails` and `_shot_layer` are z 0 and are added before `_canopy`. With `_canopy.z_index = 3`, an enemy ball crossing a bush is hidden by fronds, so dodging gets worse. Food inside bushes is hidden too. | `arena.gd:597-623` | Shots and trails go **above** the canopy (z 3, added after `_canopy`), as in BS. Food stays under the canopy; the hollow centre keeps it partly visible. |
| B3 | High | **Your own microbe is faded twice inside a bush.** It is already at alpha 0.45 there (`_watch_bush`). Under a canopy at 0.55 it is nearly invisible to its owner. | `arena.gd:1941` | While inside, raise own alpha to about 0.70 **and** draw the x-ray outline (the V2 mitigation) on **every** version. That is the "see-through ring" that works without a shader. |
| B4 | High | **A lifted canopy lies about the hide zone.** It covers 0.15 R of floor *north* of the bush, where microbes are visible to everyone, and leaves the *south* 0.15 R of the bush uncovered, where microbes are hidden. | template_bush geometry | Canopy envelope = footprint disc ∪ lifted disc. North of the footprint, only sparse frond tips at alpha ≤ 0.6. The south edge must cover the footprint edge. |
| B5 | High | **The floor needs a node, and the drying zone goes with it.** The drying tint, cracks, pulse ring and steam are drawn in `Arena._draw`, which renders **before** children. If the floor becomes a child sprite or shader node, all of that disappears under it. A shader on the arena node itself would apply to every `_draw` primitive. | `arena.gd:3886-4057` | Order: annulus mesh, then floor node, then `_dry` node (moved out of `_draw`), then rim Line2D, then `_blobs`. |
| B6 | High | **The S1 detail tile darkens the floor by half.** At "mean 50 % grey, multiplied" the floor drops to half value. The two-sprite LOW fallback with BLEND_MUL would do exactly that. | §4 S1 | Author S1 at mean 0.5 for the shader (`macro * (1 + k·(d−0.5)·2)`). The pipeline derives `_mul`, remapped to 0.90–1.00, for the no-shader MUL sprite. |
| B7 | Medium | **Two elements speak the VENT language by accident:**<br>• the V2 ghost ring is drawn as **dashed** arcs, but broken outline means "passable vent";<br>• the BRITTLE rubble is a **loose ring** of shards with amber embers, which reads like a broken amber ring, i.e. a vent. | ART_BIBLE §4 "kəsik haşiyə = cərəyan" | Ghost ring is **solid**, thin and continuous. Rubble is an irregular heap weighted to the lower right, with no amber within 0.15 R of its edge. |
| B8 | Medium | **Amber cracks fit neither value band.** `#D09345` has max channel 0.82: above the non-emissive cap (0.58) and below the emissive floor (0.85). "15/35/60 % of the cap cracked" cannot be measured and contradicts "emissive ≤ 3 %". | C6 vs §5.6 | Make crack bodies a named exception band (0.58–0.85). Measure stages as **amber pixel share of the cap**: s0 4–6 %, s1 9–12 %, s2 18–25 %. Glowing cores (≥ 0.85): ≤ 1 %, ≤ 2 %, 4–6 %. s2 may exceed 3 % on purpose, because the bloom on HIGH reads as "about to break". |
| B9 | Medium | **BUSH colour contradicts an owner document.** BRAWL_UPGRADE §3.3 says the bush is *"parlaq doymuş yaşıl … kəskin ayrılır"* (bright saturated green, sharply separated from the floor). The design gives `#357A5C` at **2.81:1** against the floor; today's is 7.55:1. The design says C7 forces this, but it does not: `#4FCB72` is S 0.61 / V 0.80 and passes C7. Only the technique study's own glow-driven cap (V ≤ 0.62) does. Hue 154° is also mint's hue (150°), not "away from mint". | contrast script | Keep it as an owner decision, but use **body `#3E9068` (3.7:1 vs floor, 3.0:1 vs pool), tips `#4F9E7C` (V 0.62), shadow `#24543F`**. Bushes stay the brightest green mass without blooming. |
| B10 | Medium | **Blocking kinds are too weak against the floor and too similar to each other.**<br>• V1 MUCUS top `#2F5A63` vs floor: 1.90 (1.57 vs pool).<br>• V1 BRITTLE `#4C5A57` vs MUCUS: **1.05** (deut 1.05); only cracks separate them.<br>• V3 MUCUS: 1.53.<br>• V2 BRITTLE `#8A8670` (V 0.54) is the brightest mass on screen, beige next to amber cracks. | contrast script | Value ladder per theme (§E rule 9). Corrected anchors: V1 MUCUS `#37666F`, BRITTLE `#77766C`; V2 MUCUS `#4A6670`, diatom `#76786E`; V3 MUCUS `#52507A`, BRITTLE `#7A7080`. |
| B11 | Medium | **Face risk in the designs themselves:**<br>• V2 diatom with a **central rosette** reads as an iris or eye;<br>• V3 canopy "glowing **dots** at the tips" are paired round lights;<br>• "condensation beads" (V1 rim) and "clinging bubbles" (V2 rim) are filled pale balls. These also read as **food** (`#D9FFC0`) at the wall, where food spawns. | STYLE rule 1, ART_BIBLE §4 | Diatom: an off-centre smooth patch, no central dot. V3 tips: elongated streaks, length ≥ 3× width. Beads and bubbles: hollow rings only, never filled pale discs. |
| B12 | Medium | **Hero silhouettes as outside props look like enemies.** The camera sees about 300 px beyond the north rim, and blurred microbe shapes there read as players. | §3.5, §5.8 | Drop `hero_*` from the props. Use only blurred obstacle masters, which are not microbe-shaped. |
| B13 | Medium | **V4 gating contradicts itself.** §8 says "until then, only the mockup **and 3 probe cells**"; §11 says "probe only if the mockup and prototype pass". §12.1 says the lift is "0.10 R … (versions 2 and 4)", but V4's lift is 0.14 R. | §8, §11, §12 | Mockup, then owner approval, then the 3 probe cells (needed **inside** the prototype, otherwise squashed V1 art looks flat), then the prototype, then +3. §12.1 must name both values. |
| B14 | Low–Medium | **MINIMUM loses the grid.** "Macro only" on MINIMUM drops the range grid, which BS and §4b treat as a measuring aid. A 512² macro cannot hold 2 px lines at about 4.7 world px per texel. | §5.4 | MINIMUM keeps today's single `draw_multiline_colors` grid call. |

---

## B. Answers to the review questions

### 1. Hard rules
- **No faces:** C1 is good. B11 lists the three places that break it. "Crumb, grain or silt clusters" in clutter need "odd count ≥ 5, irregular, no two equal neighbours".
- **No text or logos:** covered. Add: never name "Brawl Stars" or Supercell inside the **image prompt text**, because it pulls in brand marks and skulls. Naming them in the brief's context is fine.
- **Light from the top-left:** C2 is correct and consistent with `LIGHT_DIR`. Two places need care:
  - V2 god rays must also come from the upper left (they do).
  - The swirl is rotation-neutral (correct).
- **Outline rules:**
  - The prompt skeleton says "broken **dark** outline #081A20" for VENT. ART_BIBLE and the current SVG use **amber** dashes. Fix the VENT line.
  - The S6 debris outline `#04090B` conflicts with C9 ("rubble no outline"). That is acceptable because debris is transient. State it as an exception.
- **Palette discipline:**
  - Code-drawn per-theme colours exist only for Aqar (`AQAR_*`). V2 and V3 need `POND_*` and `BIOFILM_*` constants (outside pair, lip, dry tint and crack, glow pool, caustic tint, ghost/x-ray, debris tint).
  - `minimap.gd:134` hard-codes `3E8A6B` today, so the theme change should route it through `Palette` too.
  - `Palette.BUSH` is used in `map_preview.gd:217`; changing it changes the legend.
- **Collision unchanged:** yes in every version. The pipeline masks to the footprint, and V2/V4 only lift upward. **The dish centre stays free:** all three centres are BUSH, untouched. Extras (§9) are correctly flagged as sim changes.
- **Draw calls:** V1 about 10–13 environment calls; V2 +2–3; V3 +1 on HIGH. Peak stays far under 350.
- **Quality.LOW:** cheap in every version. Correction to the fill numbers: S7 caustics are **two** full-view sprites, so +2 screens of fill on HIGH, not +1.
- **Memory:** 2 GB phones auto-select MINIMUM (about 8 MiB set), which is fine. **Not covered: web download size.** Three themes × (2048² lossless page + half-resolution copy + floor + strip) add roughly 15–25 MB to the `.pck`. Ship lossless WebP and load only the active theme. Remember the README's web startup concern.
- **Silent sim or server changes:** B1 (layout rotation) is the only one. Everything else is client-only:
  - wall hit and break from the existing wall byte;
  - rustle only for sent microbes;
  - clutter deterministic per client;
  - glow pools only on received microbes.

  MUCUS bounce jiggle needs client-side bounce detection: predicted for your own shots, direction change between snapshots for remote ones. That is not trivial, but it is not a sim change.

### 2. Readability
- **Rule read by shape alone** (colour-blind safe) holds in every version: solid outline = blocks, no outline + fronds = hides, amber dashes + swirl = vent, cracks = breaks. B7 lists the two leaks.
- **Under deuteranopia:**
  - BUSH vs MUCUS is 1.45 (V1), 1.18 (V2) and 2.02 (V3). Value is weak in V1 and V2, so the no-outline/frond texture must carry it. That is another reason for the B9 bush value.
  - Amber becomes yellow (`#A8A840`) against grey shells, which stays distinct.
- **Competition with microbes and food:**
  - Floors are fine: V1 ≥ 4.2:1 (violet in the pool 3.5:1); V2 pool 3.3:1 (worst; keep it small); V3 ≥ 4.5:1.
  - Food risks: V2 warm lip `#E8EDC8` is a line (acceptable); the round pale items from B11 are not.
  - The V3 aqua specks sit at cyan's hue (172° vs 177°) but S 0.27. They are fine while they stay ≤ 8 world px and non-round.
- **BRITTLE stages from across the screen:** not readable as specified.
  - Chips ≤ 0.06 R are 3 px at R 50, and 15/35/60 % is unmeasurable.
  - Use the B8 metrics, and require main cracks **≥ 24 px wide at 1024** (≥ 3 world px at R 50) and secondary cracks ≥ 14 px. Hairlines are decoration only.
  - s1 must have one crack spanning the full cap; s2 needs three spanning cracks plus a glowing core, with the shell darkened around the cracks so luminance rises stage by stage.
  - Code adds the hit wobble.

### 3. Brawl Stars fidelity
| | South faces | Height read | Occlusion | Bush see-through | Sway / rustle | Debris / rubble | Border decor | Verdict |
|---|---|---|---|---|---|---|---|---|
| V1 | 0.20 R (12 px at R 58) | weak: shadows and the canopy carry it | canopy only | x-ray + alpha (B3) | ✓ / ✓ (+ add "shot through canopy" rustle) | ✓ | north wall + lip + blurred colonies | Honest but modest 2.5D. The mockup must not cheat. |
| V2 | 0.26 R + lift | good | caps + ghost ring + x-ray | ✓ | two-frequency | ✓ | algae wall, god rays | The real BS look. Owner decision on §4b. |
| V3 | as V1 | as V1 | as V1 | ✓ | ✓ + flash | ✓ | glowing colonies | Theme lift only. |
| V4 | 3/4 view | strongest | caps | ✓ | ✓ | reused | tall far wall | The real BS camera. Prototype first. |

Missing across all versions:
- a "shot passes through a bush canopy" rustle (BS `HasHitAnim` on bushes);
- shots drawn above bushes (B2);
- the aim-guide bounce ring and arrow above canopies in **V1 too**. The canopy is now z 3 over `_aim_guide`, so split the overlay in every version, not only V2.

### 4. Codex feasibility
- **Projection consistency:** templates plus the pipeline fit are good, but the south band thickness inside the silhouette cannot be checked from alpha. Add a luminance-profile check down column x = 512: the cap edge must sit at y 820 ± 15 (V1) or 796 ± 15 (V2).
- **Anchors:** one approved obstacle should anchor the rest of its kit. Every slot after `mucus_blob` gets that blob with `-i` as the material and projection anchor. Use a **512² crop** of the mockup, not the whole scene, so whole scenes do not get copied into sprites.
- **Transparency:**
  - For stage edits, **ignore Codex alpha entirely**: the pipeline applies s0's mask, which also guarantees IoU = 1.
  - For keyed images, despill the fringe and set `fix_alpha_border`.
  - Pass `transparent_background: true` (that is what PROMPTS_AIM used).
- **Stages as edits:** image_gen edits drift globally. A delta composite makes "every pixel away from the changes identical" true:
  1. Take `|sN − s0|` above a threshold.
  2. Dilate it by 8 px and feather it.
  3. Paste only that region onto s0.
  4. Reject if the mean colour of untouched cap pixels drifts by more than 2 %.

  Rubble is a different shape, so it is a **new image using s2 as material reference**, not a constrained edit.
- **Seamless tiles and strips:** make the fix deterministic:
  1. Wrap-offset by half; the outer edges are now original neighbours and already seamless.
  2. Repair the centre cross with a Codex edit.
  3. Composite **only a 160 px feathered cross band** back.

  Strip crop: detect the non-key rows automatically instead of assuming 320–704. The Line2D needs `texture_repeat = ENABLED`.
- **Hollow canopy:** the pipeline enforces it (alpha × smoothstep inside r 0.35 R) instead of hoping.
- **Shared neutral assets:** the pipeline converts them to greyscale (luminance) deterministically. PROMPTS_AIM shows image_gen leaves a cyan bias that took an extra edit pass to fix.
- **Missing templates:** `template_grid2x2` (clutter, debris), `template_ring` (ripple, splash, telegraph), `template_strip` (rim). `template.gd` today draws only the cap on a light-grey background (0.93), not the #808080 the design specifies; extend it and pick one background.
- **Things that must be code, not frames:** sway, rustle, wobble, swirl spin, ripple growth, bubbles, caustic scroll, glow pools, ghost ring, x-ray, lip, annulus, shadows/AO, drying zone, rim glint and clutter pop. The design already does this.
- **Redundant or missing assets:**
  - S4 telegraph has no consumer: defer it.
  - S7 is used only by V2: generate it with V2.
  - S3 needs a consumer: a pooled sprite layer in `page_env` (+1 call), **not** JuiceFx, which draws code lines.
  - One shadow/AO cell per size class replaces per-asset shadows: every blocking silhouette is the same circle (see §C).
- **Realistic counts:** each transparent slot costs 2–3 generations plus about 1–2 alpha edits; each stage about 2 edits. Expect **4–5× the shipped count** in calls, not 3×.

### 5. Implementability and conflicts with the technique study
- **arena.gd changes:**
  - atlas + `manifest.json` → `_spawn_obstacles` uses `region_rect`;
  - `_apply_walls` swaps the region and, on break, switches to the rubble region instead of `visible = false`, so `queue_redraw` is no longer needed;
  - canopy z, and shots above it (B2);
  - floor, annulus and `_dry` nodes (B5);
  - rim Line2D and lip;
  - V2 `_caps` node, label z, aim-overlay split.
- **Also update:** `map_preview.gd`, `sim_test._test_blob_textures` (assert both size classes for every kind), the minimap colours, ART_BIBLE §4/§4b (bush "flat, no shadow, saturated", canopy lift, the line-708 modulate claim) and BRAWL_UPGRADE §3.3.
- **Base layer order:** sort it once by footprint y. Spiral arms overlap by up to 40 px, and southern bodies must cover northern ones. The shadow cells form a separate first run in the same atlas, so this costs no extra call.
- **V2 cap cut:** cut along the cap circle + the outline width, with 2 px of feathered overlap, or wobble shows a seam.
- **Deviations from the technique study (all accepted):**
  - the S class reuses the L master in V2 (lift 0.10 R instead of 0.14 R; +2 masters if pebbles look flat);
  - the lip is code instead of `lip_strip`;
  - the swirl is shared instead of per theme;
  - animated outside props are replaced by static blurred props with code bob.
- **Conflict:** the technique study gives the bush "AO 0.20", but ART_BIBLE §4 says passables cast **no shadow**. Keep no AO on bush and vent.

---

## C. Templates (code, not Codex): corrected

All 1024², lines ≥ 4 px, background flat #808080 (fix `template.gd`), light arrow top-left except on neutral assets, no text.

| File | Contents |
|---|---|
| `template_v1` | Footprint circle (512,512) r 384; cap (512,474) r 346; hatched south band 76 px at S, about 38 px at E/W, 0 at N. |
| `template_v2` | Footprint as above; cap (512,443) r 353 (top y 90); lift zone y 90–128 shaded; south band 100 px. |
| `template_bush` | Base circle r 365. **Canopy envelope = footprint disc r 384 ∪ lifted disc (512,454) r 384**; "tips only" zone shaded north of y 128; hollow r 134 at (512,470). |
| `template_vent` | Lip r 384 drawn as 9 amber dashes; hole floor (512,539) r 342. |
| `template_ring` | Neutral, no arrow: circles r 420 and r 440, centre cross. |
| `template_swirl` | Neutral: circle r 269. |
| `template_grid2x2` | Four 512 cells, each with a circle r 200 (clutter) and r 180 (debris), 40 px gutters. |
| `template_strip` | 1536×1024: band y 320–704 outlined, everything else #FF00FF. |
| `template_v4` / `template_v4_bush` | As in the design (ellipse (512,560) rx 384 ry 315; cap (512,481) rx 353 ry 290); the bush envelope uses the same union rule. |

**Pipeline-made, no Codex call:**
- shadow + AO cell per class (L/S);
- V2 ghost-disc cell;
- annulus;
- lip gradient;
- glow pool;
- outside props (blurred `mucus_bloom`, `brittle_s0` and `bush_canopy` only);
- the `_mul` variant of S1;
- the caustic alpha conversion.

---

## D. Corrected final asset lists

Shared conventions:
- Masters are 1024 unless stated.
- Footprint centre (512,512), r 384.
- The pipeline cuts L cells (512, R_tex 192) and S cells (256, R_tex 96).
- `ref A` = the approved `mucus_blob` of that version (material and projection anchor).
- `ref M` = a 512² crop of the approved mockup.
- Outline = `#081A20`, about 13 px, re-stroked by the pipeline (S cells at 6 % R).
- "No CS" = no cast shadow, no glow outside the silhouette.

### D.0 Shared, theme-neutral (5 core + 2 conditional)

| # | File | Purpose | Canvas | Alpha | Projection | Placement | Made as edit of | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| S1 | `map_shared_floor_detail.png` | micro-texture over every macro floor (shader overlay; `_mul` variant for no-shader) | 1024² → 512² tile (= 400 world px) | opaque | plan, flat light | full tile; pipeline seam-fix + bakes 200 px grid and 400 px bevel | – | mean 0.50 ± 0.02 grey, ±6 % variation; wet grain, soft fibres, hollow micro-bubble rings ≥ 12 px | hue, light direction, vignette, filled dots, any feature repeating visibly in 3×3 |
| S2 | `map_shared_vent_swirl.png` | rotating current over VENT, tinted `VENT` | 1024² | transparent | plan, rotation-neutral | `template_swirl`, inside r 269 | – | 3 thick tapering arms (≥ 40 px at the root), white cores, light-grey edges, soft inner fade | light/shadow side, outline > 6 px, anything outside r 269 |
| S3 | `map_shared_ripple.png` | impact, dash, stop and absorb ripples (pooled sprites in `page_env`) | 1024² | transparent | plan | `template_ring`, r ≈ 420, width ≈ 40 | – | soft white ring, brighter outer edge, faint inward wake; centre alpha 0 | double hard lines, droplets, hue |
| S5 | `map_shared_splash.png` | shot-landing and bubble-burst splash | 1024² | transparent | plan | `template_ring`, inside r 420 | – | 8–10 radiating streaks of varied length from a soft core ring, white to grey | perfect star, filled central ball, hue |
| S6 | `map_shared_debris.png` | 4 BRITTLE chunks, tinted per theme | 1024² (2×2 → 256 of 128s) | transparent | plan, slight 3/4, lit top-left | `template_grid2x2`, each within r 180, 40 px gutters | – | 4 distinct chunky shards, grey with white top-left, `#04090B` outline about 3 % of a cell (transient exception to C9) | amber, needles, overlapping cells |
| (S4) | `map_shared_telegraph.png` | future dish events | 1024² | transparent | plan | `template_ring`, r ≈ 440, width 28 | – | solid ring, 8 inward wedge ticks, 12 % fill | symbols, hue. **Deferred: no consumer yet.** |
| (S7) | `map_shared_caustics.png` | V2 HIGH only; pipeline converts it to white + alpha = luminance | 1024² → 512² | opaque greyscale | plan | full tile, seam-fix | – | thin irregular bright cell network, lines 6–14 px, black base | blobs, hexagons, dense noise. **Only if V2 is approved.** |

### D.1 Version 1: Damla · Aqar (13)

Palette anchors (corrected):
- floor: pool `#1E3B42`, mid `#162D33`, edge `#0D1C20`;
- MUCUS top `#37666F`, body `#26494F`, face `#142C32`, specular `#5A8C93`;
- BRITTLE shell `#77766C`, face `#3A3934`; cracks `#D09345` with cores `#F0B94E`→`#FFD27A`;
- BUSH body `#3E9068`, tips `#4F9E7C`, shadow `#24543F`;
- VENT lip `#F0B94E`, hole `#050C0E`, lit wall `#2A4A50`;
- rim `#2B5963` with line `#8FD3D6`.

| # | File | Purpose | Canvas | Alpha | Projection | Footprint / placement | Made as edit of | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v1_mockup.png` | style anchor and comparison | 1536×1024 | opaque | in-game ortho + south bands | §5.13 scene (with the B11 changes) | refs: `world.png`, `world_solo.png`, `map0.png`, `menu_bg.jpg` (not `hero_*`) | microbes as in the game frames; shots drawn above the bush; corrected palette | HUD, text, faces, raised caps, filled beads, perspective |
| 2 | `map_v1_floor_macro.png` | whole-dish tone | 1024² | opaque (pipeline masks outside r) | plan, flat | disc touches all edges | ref M | pool → mid → foot AO; 5–9 soft zones ≥ 10 % of the canvas; max ≤ 0.35 | rings, grid, objects, bright spots |
| 3 | `map_v1_rim_north.png` | north inner glass wall strip | 1536×1024 → 1024×256 | opaque band on `#FF00FF` | flat wall face | `template_strip`; foot = band bottom | – (pipeline seam-fix) | wet foot crease `#0B1A1E`, teal face, soft vertical streaks, **hollow** condensation rings, lip line ≤ 12 px | filled beads, curvature, high-frequency verticals, text |
| 4 | `map_v1_mucus_blob.png` | MUCUS A, and **kit anchor A** | 1024² | transparent | `template_v1` | footprint r 384; cap (512,474) r 346 | template, ref M | glossy teal gel dome, one broad specular upper-left, south band darkest lower-right, continuous outline, no CS | granules, paired spots, any art above y 128 |
| 5 | `map_v1_mucus_bloom.png` | MUCUS B | 1024² | transparent | same | same | ref A | same dome + 7 or 9 low-contrast vesicles ≥ 60 px, irregular spacing | two similar vesicles side by side, pale or bright vesicles |
| 6 | `map_v1_brittle_s0.png` | BRITTLE s0 | 1024² | transparent | same | same | ref A (lighting only) | matte chalky shell `#77766C`; amber 4–6 % of the cap; main cracks ≥ 24 px; cores ≤ 1 % | gel gloss, crystal spikes, hairline-only cracks |
| 7 | `map_v1_brittle_s1.png` | stage 1 | 1024² | ignored (s0 mask) | same | identical | **edit of 6** + delta composite | amber 9–12 %, one crack spanning the cap, 2 painted chips | silhouette, outline or lighting change |
| 8 | `map_v1_brittle_s2.png` | stage 2 | 1024² | ignored (s0 mask) | same | identical | **edit of 7** + delta composite | amber 18–25 %, three spanning cracks, glowing core 4–6 %, shell darkened around the cracks | holes, silhouette change |
| 9 | `map_v1_brittle_rubble.png` | permanent broken decal | 1024² | transparent | plan, flat | within r 346; alpha ≤ 0.8 | new image, ref 8 (material) | 8–12 flat dull shards in an irregular heap weighted lower-right; embers in 2 inner cracks only; max ≤ 0.45; no outline | ring arrangement, amber near the edge, height, side band |
| 10 | `map_v1_bush_base.png` | ground mat (under microbes) | 1024² | transparent | plan, flat | r 365 | ref A (palette context only) | dark green mat of frond roots, fuzzy edge, no AO or shadow | outline, height, bright tips |
| 11 | `map_v1_bush_canopy.png` | canopy (above microbes) | 1024² | transparent (pipeline enforces the hollow) | plan + lifted fronds | `template_bush` union envelope; hollow r 134 at (512,470) | ref 10 | 18–24 fronds ≥ 40 px at the root, rooted on a ring at about 0.6 R, curled tips `#4F9E7C`, only sparse tips north of y 128, full cover of the south edge | solid centre, outline, round dots, lime or mint saturation |
| 12 | `map_v1_vent_base.png` | VENT pit | 1024² | transparent | plan, negative height | `template_vent` | template | **9 amber dashes** on r 384, inner wall dark upper-left and lit lower-right, near-black centre | swirl, continuous or dark outline, glow outside the lip |
| 13 | `map_v1_clutter.png` | 4 pop-able clutter pieces | 1024² 2×2 | transparent | plan, flat, unlit | `template_grid2x2`, r ≤ 200 | ref M | agar flake, crumb cluster (odd, ≥ 5), fibre curl, salt grains; ±0.08 from the floor; max ≤ 0.45 | round balls, outlines, highlights, pairs |
| (14) | `map_v1_x_osmos.png` | optional showcase (sim change) | 1024² | transparent | plan pad | r 384 | `template_v1` footprint | pale-cyan halo pad, 3 soft rings | amber, swirl, dashes |

### D.2 Version 2: Sütun · Gölməçə (13; +S7; +2 S masters if needed after playtest)

Palette changes:
- MUCUS jelly `#4A6670` (top) with face `#22363E`;
- diatom `#76786E`, ribs `#4E544C`, face `#33372F`;
- BUSH body `#3F8A70`, tips `#519C82`;
- floor as designed, with the pool kept ≤ 15 % of the dish.

| # | File | Purpose | Canvas | Alpha | Projection | Footprint / placement | Made as edit of | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v2_mockup.png` | anchor and comparison | 1536×1024 | opaque | top-down floor, caps lifted 0.10 R | §6.11 + honest occlusion + solid ghost ring | refs as V1 + `map1.png` | a microbe behind a drum shown with the x-ray line; shots above the bush | towers, perspective, dashed rings, filled bubbles |
| 2 | `map_v2_floor_macro.png` | silt floor | 1024² | opaque | plan | disc to the edges | ref M | olive silt `#2B3023`, small pool `#3A3E2C`, ochre dust drifts; max ≤ 0.35 | caustics, rings, bright greens |
| 3 | `map_v2_rim_north.png` | algae-filmed glass | 1536×1024 → 1024×256 | band on `#FF00FF` | flat face | `template_strip` | seam-fix | algae fuzz at the foot (≤ ⅓ of the band), green-teal glass, warm lip line, **hollow** bubble rings | filled bubbles, curvature, text |
| 4 | `map_v2_mucus_blob.png` | jelly drum, **anchor A** | 1024² | transparent | `template_v2` | footprint r 384; cap (512,443) r 353; top ≥ y 90 | template, ref M | squat slate drum, rounded top edge, 100 px south band with an inner glow line, specular upper-left, outline | lift above y 90, side bulge, beads |
| 5 | `map_v2_mucus_bloom.png` | frogspawn cushion | 1024² | transparent | same | same | ref A | drum built of fused gel beads ≥ 60 px, same value as the drum | cores or dots in the beads, pale beads, pairs |
| 6 | `map_v2_brittle_s0.png` | diatom pillbox s0 | 1024² | transparent | same | same | template, ref A | grey-green silica drum; radial striae from an **off-centre** smooth patch; amber 4–6 %; cracks ≥ 24 px | central rosette or dot, chrome, gear teeth |
| 7 | `map_v2_brittle_s1.png` | s1 | 1024² | ignored | same | identical | **edit of 6**, cap region only | amber 9–12 %, 2 rim chips | south-band change |
| 8 | `map_v2_brittle_s2.png` | s2 | 1024² | ignored | same | identical | **edit of 7**, cap only | amber 18–25 %, glowing core, top plate splitting | silhouette change |
| 9 | `map_v2_brittle_rubble.png` | decal | 1024² | transparent | plan, flat | r ≤ 346, alpha ≤ 0.8 | new image, ref 8 | irregular heap of silica shards and rib fragments, lower-right weighted; max ≤ 0.45 | ring layout, outline, height |
| 10 | `map_v2_bush_base.png` | algae mat | 1024² | transparent | plan | r 365 | ref A (context) | dark olive-teal filament mat, fuzzy edge | outline, AO |
| 11 | `map_v2_bush_canopy.png` | pondweed canopy | 1024² | transparent (hollow enforced) | plan + lifted strands | union envelope | ref 10 | 16–22 twisted ribbons ≥ 40 px, tips `#519C82`, south edge covered | solid centre, flowers, dots |
| 12 | `map_v2_vent_base.png` | bubbler spring | 1024² | transparent | negative height | `template_vent` | template | 9 amber dashes, silt-rim lip shadow, dark throat lit lower-right | painted bubbles, dark outline |
| 13 | `map_v2_clutter.png` | 4 pieces | 1024² 2×2 | transparent | plan, unlit | grid2x2 | ref M | half diatom valve, algae scrap, detritus flake, silt grains (odd count) | balls, outlines, glow |
| (14) | `map_v2_x_geyser.png` | optional showcase (large sim change) | 1024² | transparent | plan pad | r 384 | `template_v1` footprint | silt ring, white bubble column, one chevron notch | amber, swirl, dashes |

### D.3 Version 3: Mağara · Biofilm (13)

Palette changes:
- MUCUS top `#52507A`, body `#3A3858`, face `#1E1C2E`, specular `#7A7299` (S ≤ 0.35);
- BRITTLE `#7A7080` with face `#45404C`;
- BUSH as designed.
- Key colour `#00FF00` for violet and lilac subjects, `#FF00FF` for the bush.

| # | File | Purpose | Canvas | Alpha | Projection | Footprint / placement | Made as edit of | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v3_mockup.png` | anchor and comparison | 1536×1024 | opaque | in-game ortho | §7.11 | refs as V1 + `map2.png` | dark floor, sparse glow, violet and magenta microbes still pop | neon purple, glowing floor everywhere, round glow dots |
| 2 | `map_v3_floor_macro.png` | biofilm floor | 1024² | opaque | plan | disc to the edges | ref M | plum-indigo `#201B2C`, EPS strands ≥ 12 px, aqua specks ≤ 2 % and ≤ 8 px, non-round | magenta, rings, grid |
| 3 | `map_v3_rim_north.png` | overgrown glass | 1536×1024 → 1024×256 | band on `#00FF00` | flat face | `template_strip` | seam-fix | violet sheets thinning upward, aqua glow flecks, lilac lip line | drips longer than ¼ of the band, round dot pairs |
| 4 | `map_v3_mucus_blob.png` | EPS mound, **anchor A** | 1024² | transparent | `template_v1` | V1 geometry | template, ref M | glossy indigo dome, lilac specular upper-left, outline | lift, lilac S > 0.35 |
| 5 | `map_v3_mucus_bloom.png` | microcolony cluster | 1024² | transparent | same | same | ref A | fused lobes ≥ 60 px | pairs, lobes outside the silhouette |
| 6 | `map_v3_brittle_s0.png` | mineral crust s0 | 1024² | transparent | same | same | template, ref A | chalky mauve calcite plates `#7A7080`, amber seams 4–6 %, ≥ 24 px | spikes, metal |
| 7 | `map_v3_brittle_s1.png` | s1 | 1024² | ignored | same | identical | **edit of 6** | amber 9–12 %, 2 chipped plates | silhouette change |
| 8 | `map_v3_brittle_s2.png` | s2 | 1024² | ignored | same | identical | **edit of 7** | amber 18–25 %, amber core glowing through the seams | holes |
| 9 | `map_v3_brittle_rubble.png` | decal | 1024² | transparent | flat | r ≤ 346, alpha ≤ 0.8 | new image, ref 8 | irregular heap of chalk plates, max ≤ 0.45 | ring layout, outline |
| 10 | `map_v3_bush_base.png` | filament mat | 1024² | transparent | flat | r 365 | ref A (context) | dark teal mat, fuzzy edge | outline |
| 11 | `map_v3_bush_canopy.png` | streamer canopy | 1024² | transparent (hollow enforced) | lifted streamers | union envelope | ref 10 | 18–24 streamers ≥ 40 px; **glowing streak tips (length ≥ 3× width)**, emissive ≤ 3 % | round tip dots, full-body glow |
| 12 | `map_v3_vent_base.png` | biofilm pore | 1024² | transparent | negative height | `template_vent` | template | 9 amber dashes, slick violet wall lit lower-right, black throat | swirl, dark outline |
| 13 | `map_v3_clutter.png` | 4 pieces | 1024² 2×2 | transparent | flat, unlit | grid2x2 | ref M | EPS knot, mineral grains (odd), slime flake, branching filament | balls, glow |
| (14) | `map_v3_x_pores.png` | optional showcase (sim change) | 1024² | transparent | flat pad | r 384 | `template_v1` footprint | pale-aqua ring pad with 2 rim notches | amber, swirl, colour coding |

### D.4 Version 4: Perspektiv · Aqar (1 at the gate, then 3, then 3)

| # | File | Purpose | Canvas | Alpha | Projection | Footprint / placement | Made as edit of | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v4_mockup.png` | **gate** | 1536×1024 | opaque | 55° orthographic tilt, floor squashed 0.82 | §8.5 | ref `map_v1_mockup.png` (approved) | elliptical footprints, taller far wall, flat squashed microbes, shots above the bush | vanishing points, upright microbes, text |
| 2 | `map_v4_mucus_blob.png` | probe; used in the prototype | 1024² | transparent | 3/4 at 55° | `template_v4` (ellipse (512,560) rx 384 ry 315; cap top ≥ y 191) | ref `map_v1_mucus_blob` | same gel, 104 px front band | lift above y 191, side bulge |
| 3 | `map_v4_brittle_s0.png` | probe | 1024² | transparent | same | same | ref `map_v1_brittle_s0` | same crust; B8 amber metrics | as above |
| 4 | `map_v4_bush_canopy.png` | probe | 1024² | transparent | same | `template_v4_bush` union envelope; hollow ellipse rx 134 ry 110 | ref `map_v1_bush_canopy` | arching fronds, hollow, south edge covered | solid centre |
| 5–7 | `map_v4_mucus_bloom.png`, `map_v4_brittle_s1.png`, `map_v4_brittle_s2.png` | only if adopted | 1024² | transparent / ignored | same | same | bloom: ref 2; s1 and s2: **edits of 3** with delta composite | as V1 | as V1 |

Reused unchanged from V1: floor macro and S1, bush base, rubble, vent base and swirl, clutter, shared juice. The rim strip is drawn upright with W = 70/0.82 at due north.

---

## E. Prompt-writing rules the Codex briefs must include

1. Open every brief with "Read STYLE.md and follow its HARD RULES". Repeat inline: no face (no eyes, pupils, mouth), **no two similar spots side by side**, no text, logos or numbers, no humans or hands, no metal, lab gear or hard corners.
2. Do not write "Brawl Stars", "Supercell" or any brand inside the image prompt. Describe the look: "premium chunky mobile arena game art".
3. Use one **fixed projection sentence per version**, pasted identically into every call of that kit. Use one fixed light sentence: "one key light from the upper-left (11 o'clock); highlight upper-left; shading darkens toward lower-right".
4. Give geometry in **pixels**, never percentages: "footprint circle centre (512,512) radius 384; nothing above y 128 (V1) / y 90 (V2)".
5. Name every `-i` image by its role, in this order: (1) template = "measurement guide, reproduce none of its lines, colours or arrow"; (2) kit anchor A = "match material, outline weight and lighting"; (3) mockup crop = "style reference only, do not copy the scene".
6. Set `transparent_background: true`. Then do a separate alpha-cleanup edit if needed (the PROMPTS_AIM wording). If both fail, use a flat key: `#FF00FF`, or `#00FF00` for violet and lilac subjects. State that **no key colour may appear in the subject**.
7. "No cast shadow, no ground, no glow or haze outside the silhouette": the pipeline makes shadows.
8. Give a value ceiling as a hex: "no non-glowing pixel brighter than `#949494`". Name the only glowing parts allowed and their maximum share.
9. **Value ladder per theme (pipeline-checked on the mean cap colour):**
   - MUCUS top ≥ 2.2:1 against the mid floor;
   - BRITTLE shell ≥ 1.35:1 lighter than the MUCUS top;
   - BUSH body ≥ 3:1 against the mid floor;
   - BUSH max V ≤ 0.62;
   - floor max ≤ 0.35.
10. One outline sentence per kind:
    - MUCUS and BRITTLE: continuous `#081A20`, about 13 px;
    - BUSH: none;
    - VENT: **9 amber `#F0B94E` dashes**, no dark outline;
    - rubble and clutter: none.
11. Minimum feature 40 px. Main cracks ≥ 24 px, secondary ≥ 14 px. Repeated features in **odd counts with irregular spacing**.
12. **Food and shot protection:** no filled pale round shapes anywhere (bubbles and beads are hollow rings); nothing round between 20 and 40 world px in `#D9FFC0`, white or any microbe hue.
13. **Stage edits:** "edit the attached stage; change ONLY: {delta with amber-share target}; keep canvas, silhouette, outline, lighting and colours". Tell Codex its alpha will be discarded and the s0 mask applied, so it should not touch the edge. The pipeline delta-composites the result.
14. **Damage targets as numbers:** amber share of the cap 4–6 / 9–12 / 18–25 %; glowing core ≤ 1 / ≤ 2 / 4–6 %; one spanning crack at s1, three at s2.
15. **Canopy:** "hollow centre radius 134 px around (512,470) mostly empty; fronds rooted on a ring; only sparse tips above y 128; fronds cover the bottom edge of the red circle".
16. **Tiles:** flat even light, no vignette, low contrast, "left continues into right, top into bottom". The brief says the pipeline will offset and repair, so Codex only flags visible seams.
17. **Strips:** "1536×1024; the strip fills only the band y 320–704 across the full width; above and below flat `#FF00FF`; no curvature".
18. **Neutral shared assets:** "pure greys, R = G = B". The pipeline greyscales them anyway.
19. **Mockups:** "not a game asset; no HUD or text; microbes exactly as in `world.png`"; obstacles obey the version's geometry. No cheating: no V1 cap above its base.
20. **Quality loop:** up to 3 tries per slot. Reject on any of: text, face or pair, wrong alpha, art above the lift line, wrong outline type, a value-cap breach, a missing hollow, checkerboard, or a key colour inside the subject.
21. **Self-verification in PowerShell + System.Drawing** (no Python):
    - `Format32bppArgb`;
    - corners and (8,8) / (w−8, h−8) alpha 0;
    - centre opaque (obstacles) or alpha 0 (ring, swirl, canopy hollow ≤ 0.30 mean);
    - 99th percentile of the max channel;
    - channel spread < 24 (shared items).

    Report the numbers.
22. Save raw output to `design/map_art/raw/vN/<exact name>.png`, never overwriting an approved file. Log the exact prompts to `brief/PROMPTS_MAP_VN.md`.
23. **One image per call:** no variation grids, except the 2×2 sheets, which must follow `template_grid2x2`.
24. **Avoid trigger words:** "eye", "iris", "pupil", "nucleus", "face", "cute", "character", "creature" for props. For VENT say "pore/hole", never "drain". For BRITTLE say "crust/shell", never "egg" or "rock with lava".

---

## F. Corrected run order and counts

| Step | What | Shipped images |
|---|---|---|
| 0 | Fix B1–B14 in the design; extend `template.gd` (10 templates); write the pipeline checks; produce a review sheet (each cell rendered at R 34/58/96/150 on its floor, at 1.0 and 0.56 phys px, plus a deuteranopia copy) | 0 |
| 1 | Shared S1, S2, S3, S5, S6 | 5 |
| 2 | Mockups V1, V2, V3, V4, then **owner gate** (§G) | 4 |
| 3 | V1 kit (anchor A first, then the rest) | 12 |
| 4 | V2 kit (+ S7) and/or V3 kit, per the gate | 12 (+1) + 12 |
| 5 | V4 probe cells, then the 1-day prototype, then +3 if adopted | 3 (+3) |
| – | Optional: S4, 3 showcases, 2 V2 S-class masters | ≤ 6 |
| **Total** | **48 core** (+1 S7, +3 V4, +6 optional = ≤ 58) | about **4–5×** that in calls |

## G. Owner decisions (updated)
1. §4b: may MUCUS and BRITTLE caps rise above the footprint? **V2 0.10 R / ≤ 16 px; V4 0.14 R.**
2. **Layout rotation in live play** (B1: server, net and simtest change), or a practice-only playtest flag, or themes as a client setting.
3. BUSH colour: today's bright `#4FCB72` (BRAWL_UPGRADE §3.3), or `#3E9068` at V ≤ 0.62 (no bloom).
4. Shader policy: BRAWL_UPGRADE §6 says no shaders. Everything works without them.
5. Shots and trails above bush canopies (recommended), plus the aim overlay above canopies in every version.
6. Perspektiv: prototype it after the mockup, or drop it.
7. §9 gameplay tiles: each one is a sim change.

**Files read:** the design inputs listed in the task, plus `game/scripts/client/minimap.gd`, `game/scripts/boot.gd`, `game/scripts/shared/palette.gd`, `design/map_art/template.gd` and `design/menu_art/brief/PROMPTS_AIM.md`.

I changed no project files. My only output is the scratchpad scripts `review_c.js`, `review_c2.js` and `review_c3.js` in `C:\Users\User\AppData\Local\Temp\claude\C--Users-User-Desktop-Germ-game-V1\5479a438-be68-4dd6-918e-3e73992da313\scratchpad\`.