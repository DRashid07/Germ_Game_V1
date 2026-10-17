# Germ Arena: Brawl Stars-style 2.5D map versions and their Codex asset lists

**Inputs used:**
- `design/map_art/research/brawl_stars_research.md` (BS research)
- `design/map_art/research/godot_25d_technique.md` (technique study). Its §9 is the contract the Codex art follows; this document changes it only where a version's technique needs something different.
- ART_BIBLE §1, §4 and §4b
- BRAWL_UPGRADE
- `menu_art/brief/STYLE.md`, `BRIEF_ENV.md` and `BRIEF_AIM.md`
- The current frames in `build/shots/` and the approved menu art

**Obstacle sizes per kind.** I measured these by re-running the DishMap re-implementation in the scratchpad. They decide which size classes each asset must survive.

| Layout | MUCUS | BUSH | BRITTLE | VENT |
|---|---|---|---|---|
| 0 Halqalar | 12 obstacles, R 58–96 (6 in the S class) | 9, R 78–132 | 2, R 96 | 3, R 58 (all S) |
| 1 Arxipelaq | 26, R 34–132 (**17 S**) | 9, R 43–150 (**8 S**) | – | – |
| 2 Spiral | 12, R 84–118 | 10, R 34–145 (**9 S**) | 9, R 50–73 (3 S) | – |

What follows from these numbers:
- Every kind except VENT is used in both size classes. The smallest bush is R 32–34.
- **One 1024² master per asset must still read at R = 34.** The main forms therefore follow the S-class detail rule: no feature smaller than 4% of the canvas, about 40 px.
- Every theme still fills all four slots, even where its showcase layout does not use one. This mirrors BS `location_themes`.

---

## 0. The versions at a glance

| # | Name (AZ / EN) | Technique | Theme | ART_BIBLE §4b | Showcase layout | Codex images |
|---|---|---|---|---|---|---|
| **1** | **Damla / Droplet** | V1: height baked inside the footprint, south face, lifted bush canopy, "Kasa" rim | T1 **Aqar**: refined teal (the current identity, finished) | **Kept strictly** | 0 Halqalar | 13 |
| **2** | **Sütun / Pillar** | V2: MUCUS and BRITTLE caps raised by L ≤ 0.10 R and ≤ 16 px; two layers; ghost ring; x-ray outline | T3 **Gölməçə / Pond Drop**: olive silt, jelly drums, diatoms, algae. The BS "Deep Sea" analogue | **Breaks it; needs the owner's approval** | 1 Arxipelaq | 13 |
| **3** | **Mağara / Cave** | V1 (same as version 1) | T2 **Biofilm**: dark violet biofilm cave whose floor glows back at the microbes | **Kept strictly** | 2 Spiral | 13 |
| **4** | **Perspektiv / Perspective** (gated) | V4: Camera2D squashed by c = 0.82, upright sprites on elliptical footprints, V2-style lift and mitigations | T1 **Aqar** (the same theme as 1, so only the camera differs) | Breaks it, and changes camera and input. **Needs the owner's approval plus a code prototype first** | any | 4 now (+3 if adopted) |
| – | Shared, theme-neutral | – | – | – | – | 7 |

**Why these combinations make the most informative choice:**
- **1 vs 3** use the same technique with different themes. They show how far a theme alone moves the look without touching a rule.
- **1 vs 4** use the same theme with a different camera. They isolate what the BS-style tilt adds.
- **2** is the complete "true Brawl Stars" package: raised walls, the Deep-Sea-like theme and the strongest juice. Its theme fits the islands layout.
- **The three themes map one-to-one onto the three layouts**, the way BS assigns a location theme to each map: Halqalar is the classic agar culture, Arxipelaq is islands in a pond, Spiral is biofilm arms. If the owner wants "all of them", nothing is wasted.

**Cost of swapping a theme between techniques.**
- Between Damla and Sütun only six cells depend on the technique: MUCUS ×2 and BRITTLE s0/s1/s2/rubble. Floor, rim, bush, vent and clutter are identical.
- So any theme can be re-cut in the other technique for **+6 images**.
- Perspektiv reuses everything that lies flat in world space (floor, bush base, rubble, vent, clutter) and needs new art only for upright things.

**Themes I did not choose, and why:**
- **T4 Cryo:** its frost blue and cyan sit on top of the microbe colours `4D9BFF` and `2FE8E0`. Keep it for a later seasonal theme.
- **T5 Thermal:** amber and orange are the warning channel (BRITTLE, VENT, drying zone, `WARNING`, and the microbe colours amber `FFB43D` and coral `FF6B5B`). A thermal world would erase that signal. Rejected.

**Naming note.** Version numbers follow the technique study where they match: 1 = Damla, 2 = Sütun, 4 = Perspektiv. The study's "V3 Kasa" is the bowl rim, and it is part of every version here. Version 3 in this document is the new Biofilm combination.

---

## 1. Global Codex contract (all versions)

These rules apply to every call unless a table row says otherwise. They extend technique study §9.1.

| # | Rule |
|---|---|
| C1 | **Hard rules from STYLE.md:** no faces (no eyes, pupils or mouths, and **no two spots side by side** anywhere, because bubbles and vesicles read as eyes); no text, numbers, logos or watermarks; no humans or hands; **no metal, lab gear or hard geometric corners**. The only angular lines allowed are BRITTLE cracks and diatom ribs. The material is soft, wet, gelatinous and bioluminescent. |
| C2 | **One light, from the upper-left** (`LIGHT_DIR = (-0.45,-0.89)`, 11 o'clock, elevation about 50°). The highlight sits on the upper-left of the top face; shading darkens toward the lower-right; an optional hairline rim light (≤ 2% R) runs along the lower-right edge. **The visible side band is on the SOUTH (bottom)**, set by the camera, while its darkest part is lower-right, set by the light. Never rotate the light, and never ask the game to rotate an obstacle. |
| C3 | **No cast shadows are painted.** The pipeline builds the shadow and AO ring from the mask (technique §9.2). Codex leaves the floor around the object empty. |
| C4 | **Real alpha.** Output must be `Format32bppArgb` with alpha 0 at every corner 64×64 block and at (8,8) and (w−8, h−8). If image_gen paints a checkerboard, run a second "background-extraction" edit pass. Fallback is a flat key: **`#FF00FF` for green, teal, olive and amber subjects; `#00FF00` for violet and lilac subjects (version 3)**, removed by `process.gd key`. |
| C5 | **Registration.** Footprint circle centred at (512, 512), **r = 384** (only version 4 uses an ellipse, see §8). The matching `ref/template_*.png` is passed with `-i`; it is a guide, and none of its lines, colours or arrows may appear in the output. The pipeline fits the result and rejects it if the residual is > 2% R. |
| C6 | **Value caps:** non-emissive max(R,G,B) ≤ 0.58 (99th percentile ≤ 0.60); floors ≤ 0.35; BUSH ≤ 0.62 (just under the HIGH glow threshold of 0.62). **Emissive** accents are ≥ 0.85 and ≤ 3% of the opaque area. Only these may glow: BRITTLE crack cores, the VENT lip, bioluminescent dots and the rim highlight line. |
| C7 | **Saturation:** no environment pixel with S ≥ 0.75 and V ≥ 0.85 within the hue of any of the 10 microbe colours or the ally colour `A6FF4D`. The one exception is BRITTLE and VENT amber (`#D09345`–`#FFD27A`). |
| C8 | **Detail:** main forms ≥ 4% of the canvas (≥ 40 px at 1024), because one master serves the L cell (512) and the S cell (256). Surface texture in the 2–4% range is allowed only at low contrast, since it may disappear at S. |
| C9 | **Outline (the rule language of ART_BIBLE §4):** MUCUS and BRITTLE get a continuous dark `#081A20` outline, about 13 px at 1024 (3.5% R; the pipeline re-strokes the S cell at 6% R). BUSH has **no** outline. VENT has a **broken** amber outline. Clutter and rubble have no outline. |
| C10 | **Damage stages are EDITS** of the previous stage (`-i` with the source image). Silhouette, outline, lighting and colours stay identical; the pipeline checks alpha-mask IoU ≥ 0.98 against the source and rejects anything lower. |
| C11 | **Style anchor.** Every kit call gets the version's *approved* mockup with `-i`, marked "style reference only, do not copy the scene". Mockups are generated first (§11). |
| C12 | **Tries:** up to 3 candidates per slot, 1 ships (2 for MUCUS, because blob and bloom are both kept). Model `gpt-6-astra`, `model_reasoning_effort=max`. |

### 1.1 Prompt skeletons
These use the format of `menu_art/brief/PROMPTS_*.md`.

```text
[OBSTACLE: new image]
Use case: game sprite, isolated, registered to a template
Asset type: {KIND} obstacle for a top-down mobile arena ({VERSION}); part of a matched set
Primary request: Paint ONE {SUBJECT}. It sits on the floor of a giant water-filled petri dish and is
  seen from almost straight above; its height shows ONLY as a darker side band along its bottom
  (south) edge.
Registration: ref/template_{T}.png is a guide, not content. Red circle = footprint (centre 512,512,
  radius 384): the object's outer silhouette lies exactly on it{V2: except the top face, which may
  rise up to 38 px above it inside the shaded lift zone}. Blue circle = top face. Hatched crescent =
  the visible side band (widest at the bottom centre, thinning to nothing at left, right and top).
  Reproduce none of the guide lines, colours or arrow.
Style/medium: chunky premium mobile-game art in the family of ref/mockup_{N}.png (style reference
  only, do not copy its scene); soft wet gelatinous organic forms; clean cel shading, soft gradients.
Lighting: one key light from the upper-left (11 o'clock); highlight upper-left of the top face;
  shading darkens toward lower-right; the side band is the darkest part, darkest at its lower-right;
  optional hairline rim light on the lower-right edge.
Palette: {HEX LIST}. Every non-glowing pixel at most 58% brightness. {GLOW RULE}
Outline: {continuous | none | broken} dark outline #081A20, about 13 px wide.
Constraints: 1024x1024, real transparent background (RGBA, alpha 0 outside the object), no cast
  shadow, no glow or haze outside the silhouette, nothing else on the canvas, smallest painted
  feature at least 40 px wide (the sprite is shown as small as 64 px).
Text: none.
Avoid: faces, eyes, two dots side by side, mouths, text, metal, lab equipment, hard geometric
  corners, vanishing-point perspective, cast shadows, checkerboard, painted background.

[STAGE: edit]
Edit the attached image ref/{SOURCE}.png. Keep the canvas, the outer silhouette, the outline, the
lighting, the colours and every pixel away from the changes IDENTICAL. Change only: {DELTA}.
Output 1024x1024 with real transparency.

[SEAMLESS TILE]
Use case: seamless texture tile. {CONTENT}. Flat even lighting (no light direction, no vignette,
no objects), low contrast. The left edge must continue seamlessly into the right edge and the top
into the bottom. 1024x1024, opaque. Text: none.

[RIM STRIP]
Use case: horizontally tiling texture strip. 1536x1024 canvas: the strip fills exactly the band
y = 320..704 (384 px tall) across the full width; everything above and below it is flat #FF00FF.
{CONTENT}. The left end must continue seamlessly into the right end. No curvature, no perspective.

[MOCKUP]: see each version's §x.13
```

---

## 2. Guide templates (drawn by code, not Codex)

Make these with `process.gd template`, or with PowerShell System.Drawing. Each is a 1024² image on flat grey `#808080`, with lines at least 4 px wide, an arrow in the top-left corner pointing from the light toward the lower-right, and **no text**.

| File | Contents (px on the 1024 canvas; R = 384) |
|---|---|
| `template_v1.png` (Damla MUCUS/BRITTLE) | Red footprint circle centred (512,512), r 384. Blue cap circle centred (512,474), r 346 (0.90 R, shifted up 0.10 R). Hatched south band: 76 px at the bottom (0.20 R), about 40 px at the sides (0.10 R), 0 at the top. |
| `template_v2.png` (Sütun) | Red footprint as above. Blue cap centred (512,443), r 353 (0.92 R, H = 0.18 R), so the cap top is at y 90. The **lift zone** (y 90–128 inside the cap) is shaded: L = 38 px = 0.10 R. South band 100 px (0.26 R). |
| `template_bush.png` | Green dashed base circle r 365 (0.95 R). Canopy envelope: centre (512,454), i.e. up 0.15 R; reaches x 128–896 (1.0 R) and up to y 70 (1.15 R above centre). **Hollow** circle r 134 (0.35 R) centred (512,454). |
| `template_vent.png` | Amber dashed lip circle r 384. Hole-floor circle centred (512,539), r 342. That gives an inner wall 69 px wide at the north (0.18 R) and 15 px at the south (0.04 R). |
| `template_swirl.png` | Circle r 269 (0.70 R) centred (512,512). No light arrow. |
| `template_v4.png` (Perspektiv) | Red footprint **ellipse** centred (512,560), rx 384, ry 315 (ratio 0.82). Blue cap ellipse centred (512,481), rx 353, ry 290, so the top is at y 191 and the lift is 54 px (0.14 R). South band 104 px. |
| `template_v4_bush.png` | Base ellipse centred (512,560), rx 365, ry 299. Canopy envelope with its top at y ≥ 100. Hollow ellipse rx 134, ry 110 at (512,480). |

Cells: **L** = 512² with footprint radius 192 texels; **S** = 256² with radius 96; outer padding 12 texels in L and 6 in S. All masters therefore keep a 24 px empty margin at 1024.

---

## 3. Pipeline additions on top of technique study §9.4

All of this runs in `process.gd` and PowerShell; there is no Python on this machine.

1. **Seam fix for tiles and strips:**
   - Wrap-offset the image by (w/2, h/2), or by w/2 only for strips, so the seams form a central cross.
   - Run a Codex edit: "repair the straight seams crossing the centre so the texture is continuous; do not change anything within 64 px of the outer edges; keep grain, scale and contrast."
   - Verify that the mean |column 0 − column w−1| is ≤ 1.5× the mean difference between adjacent columns (rows likewise for tiles), and that the image mean and standard deviation are unchanged within 3%.
   - Fallback: cross-fade a 48 px band with a mirrored copy.
2. **Strip crop:** cut rows 320–704 of the 1536×1024 canvas and resize to 1024×256. The 4 texels at the top edge get an alpha ramp into `BG_OUTER`.
3. **Floor macro:**
   - Re-mask the disc at r = 512 and fill the corners with the theme's outside colour.
   - **Bake the sediment bands at their exact world radii.** Codex cannot place them precisely, so it paints none; baking removes 3 draw calls.
4. **Detail tile:** **bake the 200 px grid and the 400 px bevel** into the shared tile at exact spacing (one tile = 400 world px).
5. **Ambient props outside the dish** come from existing masters:
   - Blur (σ about 24 px at 1024), pull value down to ≤ 0.15, alpha 0.35.
   - Sources: the version's `mucus_bloom`, `brittle_s0` and `bush_canopy` (shown as "distant colonies"), plus the approved `hero_*.png` silhouettes. The approved menu background already uses this blurred faceless-microbe look.
   - **No Codex call.**
6. **Stage registration:** alpha IoU ≥ 0.98 between s0, s1 and s2. For V2, only the **cap** cell is taken from s1 and s2; the base cell comes from s0.
7. **V2 split:** cap cell = inside the cap circle. Base cell = face band + shadow + AO + **ghost footprint disc** with a crisp 2–3 px rim exactly on the collision circle.
8. **Verification**, PowerShell System.Drawing, per class:

| Class | Checks |
|---|---|
| Obstacles | corners alpha 0, centre opaque |
| Canopy | mean alpha inside the hollow ≤ 0.30 |
| Ripple / telegraph / swirl | centre alpha 0 |
| Shared items | neutrality: max \|R−G\|, \|G−B\|, \|R−B\| < 24 |
| Floors | 99th percentile of max channel ≤ 0.35 |
| Clutter and rubble | max channel ≤ 0.45 |

---

## 4. Shared, theme-neutral assets (generated once for all versions)

All are white or grey, tinted at runtime by `modulate` on the **parent** node, so there is no batch split. Channel spread must stay < 24.

| # | File | Purpose | Canvas | Alpha | View | Placement | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|
| S1 | `map_shared_floor_detail.png` | Seamless micro-texture multiplied over every theme's macro floor | 1024² → 512² | opaque | plan, flat light | full tile | Mean exactly 50% grey, ±6% variation. Fine wet grain, a few micro-bubble rings (≥ 12 px), faint soft fibres. Edges match (pipeline seam fix). The pipeline bakes the grid | Directional light, vignette, any feature that repeats visibly over 3×3 tiles, hue |
| S2 | `map_shared_vent_swirl.png` | Rotating current over every VENT (tinted VENT amber) | 1024² | transparent | plan | `template_swirl`: three spiral arms inside r 269 | 3 thick tapering arms (≥ 40 px at their roots), white cores and light-grey edges, soft inner fade, **rotationally neutral** (no light direction, so it can spin) | Light or shadow side, outline heavier than 6 px, anything outside r 269 |
| S3 | `map_shared_ripple.png` | Impact, dash and absorb ripples (JuiceFx ring type) | 1024² | transparent | plan | ring r ≈ 420, width ≈ 40 | Soft white ring with a slightly brighter outer edge and a faint wake fading inward; centre alpha 0 | Hard double lines, droplets, colour |
| S4 | `map_shared_telegraph.png` | Floor warning ring for future dish events (tinted DANGER or WARNING) | 1024² | transparent | plan | ring r ≈ 440, width 28 | Solid ring + 8 short inward wedge ticks + a faint 12% fill disc | Text, symbols (skulls etc.), colour |
| S5 | `map_shared_splash.png` | Shot-landing and bubble-burst splash | 1024² | transparent | plan | burst within r 420 | 8–10 droplet streaks radiating from a soft core ring, varied lengths, white to grey | Asymmetric light, colour, a tight perfect star |
| S6 | `map_shared_debris.png` | 4 BRITTLE chunks (tinted with the theme's shell colour) | 1024² (2×2 cells of 512 → 256 cell of 128s) | transparent | plan, slight 3/4 | each chunk within r 180 of its cell centre, ≥ 40 px gaps between cells | 4 different chunky shell shards, grey with a white lit top-left, thick `#04090B` outline (~3% of a cell) | Amber (added by tint), sharp needles, overlapping cells |
| S7 | `map_shared_caustics.png` | Animated light caustics (version 2 on HIGH; optional elsewhere) | 1024² → 512² | opaque greyscale (luminance becomes alpha) | plan | full tile | Black base with a thin bright wavy network of irregular cells (lines 6–14 px); edges match | Bright blobs, dense noise, perfect hexagons |

Total: 7 images. Shadows, AO rings, the glow pool (version 3), the lip gradient and the outside annulus are all made **by code**, not Codex.

---

## 5. Version 1: **Damla / Droplet** (technique V1 × theme T1 Aqar)

### 5.1 Pitch
The current game, finished. Clean teal agar in a glass dish; every blocker is a glossy droplet that swells **inside its exact collision circle**. Height reads from a south face band, a light offset shadow and an AO ring. Bushes are the only thing that rises over the microbes. This is Brawl Stars readability (light top-left, south faces, light shadows, swaying cover, destruction) without breaking a single rule. Showcase layout: Halqalar.

BS mapping: walls → droplets; fragile/damageable → agar crust; bush → frond tuft; bouncer → MUCUS ricochet; damage states → BRITTLE s0–s2; "destroyed stays destroyed" → permanent rubble.

### 5.2 Palette

| Role | Hex | HSV / note |
|---|---|---|
| Outside / far vignette | `#071012` / `#020708` | unchanged `BG_OUTER` / `BG_VIGNETTE` |
| Floor: centre pool / mid / edge AO | `#1E3B42` / `#162D33` / `#0D1C20` | V 0.26 / 0.20 / 0.13, chroma ≤ 0.14. Contrast against the darkest microbe colours (blue, violet) is ≥ 4.3:1 on the mid floor and 3.5:1 in the centre pool |
| Sediment band light / dark (baked) | `#21424A` / `#10242A` | |
| MUCUS top / body / face / specular | `#2F5A63` / `#1F414A` / `#12292F` / `#5E9097` | specular ≤ 1% of area, V 0.59 |
| BRITTLE shell top / face | `#4C5A57` / `#28322F` | near-neutral grey-teal stone, S 0.16 |
| BRITTLE crack / glowing core | `#D09345` / `#F0B94E` → `#FFD27A` | the amber exception |
| BUSH shadow / body / tips | `#1E4A38` / `#357A5C` / `#4E9C7A` | hue 154°, S 0.50–0.59, V ≤ 0.61; away from lime, mint and ally |
| VENT lip / hole / lit inner wall | `#F0B94E` (broken) / `#050C0E` / `#2A4A50` | |
| Rim glass body / highlight line | `#2B5963` / `#8FD3D6` | highlight ≤ 3% |
| Bioluminescent motes | `#A8E6E2` | S 0.27, emissive |
| Environment outline | `#081A20` | |
| Drying: tint / cracks | `#3A3626` @ α 0.55 / `#81785C` (`DRY_CRACK`) | code |

Constants to add to `palette.gd` for the code-drawn parts:
- `AQAR_LIP` `#2B5963` @ 0.35 and `AQAR_LIP_HI` `#8FD3D6`
- `AQAR_DRY` `#3A3626`
- `AQAR_OUT` / `AQAR_OUT_FAR` (= the existing pair)
- `Palette.BUSH` → `#357A5C`. The minimap may keep a lighter `MINIMAP_BUSH`.

### 5.3 Technique and camera
- **Camera:** unchanged. Orthographic top-down floor; height projects straight up the screen at 0.35 (elevation about 70°).
- **MUCUS and BRITTLE:**
  - Cap centred (0, −0.10 R), radius 0.90 R.
  - South band 0.20 R at the bottom, 0.10 R at the sides, 0 at the top.
  - Lift is **0**: art never leaves the footprint upward.
- **Shadow (pipeline):** mask × (1.05, 0.80), offset (+0.11 R, +0.22 R), alpha 0.36 falling to 0, blur σ 0.06 R. AO band 0.04 R at alpha 0.28.
- **BUSH:**
  - The flat base is drawn under the microbes.
  - The canopy is lifted 0.15 R (allowed, because bushes are passable) and drawn **above** the microbes. This fixes bug F1: `_canopy.z_index = 3`, placed before `_fx`.
- **VENT:** negative height. The upper-left inner wall is in shadow and the lower-right is lit; the shared swirl turns on top.
- **Layers:**

| Layer | Contents | Draw calls |
|---|---|---|
| Base atlas | bases, vents, rubble, swirls | 1 |
| Canopy atlas | canopies | 1 |
| Environment total | | about 10 (today about 20) |

### 5.4 Floor
- **Macro (Codex, 1024² opaque):**
  - The dish disc touches all four canvas edges, so the pipeline can re-mask it.
  - A softly lighter centre pool, 5–9 large soft "agar zones" (each ≥ 10% of the canvas, ±0.03 value), and a gentle darkening over the outer 6% of the radius into the glass foot.
  - **No rings, no grid, no objects.**
- **Detail:** shared S1, multiplied over the macro. The grid and bevel are baked in.
- **HIGH/LOW:** a single `canvas_item` shader (macro × detail) if the shader policy allows it; otherwise two sprites.
- **MINIMUM:** macro only, at 512².

### 5.5 Rim and outside
- **North inner wall (`rim_north`, Codex):**
  - A clear teal glass wall seen from inside the dish.
  - Bottom edge: a dark wet foot crease (`#0B1A1E`) with a thin meniscus highlight.
  - Wall face: `#2B5963` → `#1E4650`, soft vertical refraction streaks, a few low-contrast condensation beads.
  - Top edge: a bright lip line `#8FD3D6`, ≤ 12 px.
  - Drawn outward from the foot line at width W(θ) = 8 + 62·max(0, −sin θ)^1.5, so 70 px at due north. One `Line2D` in TILE mode.
- **South lip:** code only. A `Line2D` with a `GradientTexture2D` (body alpha ≤ 0.35, top highlight ≤ 3 px), drawn inward and **above** the microbes, 28 px at due south. No Codex call.
- **Outside:**
  - One annulus mesh with vertex colours `BG_OUTER` → `BG_VIGNETTE`; it replaces the two full-screen discs (F3).
  - Plus the pipeline-made "distant colonies" (§3.5) and bubbles clinging to the outer glass (code circles in the JuiceFx multiline group).

### 5.6 Obstacles

| Kind | Design |
|---|---|
| **MUCUS blob** | A smooth, glossy teal gel dome. One broad specular at the upper-left of the cap. The south band is a deeper, denser gel tone. Continuous outline. |
| **MUCUS bloom** | The same dome with 6–10 embedded gel vesicles (each ≥ 6% of the canvas, low contrast, unevenly spaced so no two read as a pair of eyes). Granular surface. |
| **BRITTLE** | A dried agar crust dome: matte, faintly chalky grey-teal stone with **amber cracks** whose cores glow.<br>• **s0:** 15% of the cap cracked, hairline branches.<br>• **s1:** 35%, wider cracks, 2 shallow chips inside the silhouette (≤ 0.06 R).<br>• **s2:** 60%, the glowing amber interior shows through, 4 chips, flakes lifting.<br>• **Rubble:** 8–12 flat dull shards in a loose ring (≤ 0.9 R), no outline, faint embers in 2–3 cracks, max channel ≤ 0.45. |
| **BUSH** | **Base:** a dark green mat of frond roots with a soft fuzzy edge (r 0.95 R), no outline. **Canopy:** 18–24 thick, soft fronds radiating from a ring, curling at the tips, lit from the upper-left, with a **hollow centre** (≤ 30% coverage) so a hiding microbe shows through. |
| **VENT** | A round pore in the agar. A **broken** amber lip (8–10 dashes) exactly on the footprint. Inner wall `#0A171A` at the upper-left (shadow) and `#2A4A50` at the lower-right (lit), dropping into a near-black centre. The shared swirl turns above it. |

### 5.7 Interactive behaviours (client-only)

Signature: **"wet agar"**. Ripples spread over the agar, droplets jiggle and the glass glints.

| Behaviour | Trigger | Implementation | Frames needed? | HIGH / LOW / MIN |
|---|---|---|---|---|
| Canopy over microbes | always | z fix (F1) | no | all |
| Bush sway | always | rotation ±0.030 rad, skew ±0.018; phase seeded by position (`x*0.013 + y*0.021`) | no | full / full / ×0.5 |
| Bush rustle | a **visible** microbe enters, leaves or shoots inside | sway impulse + 1.04 scale pulse over 200 ms. Never for unsent microbes, so no information leaks | no | all |
| Own-microbe see-through | own microbe inside a bush | hole shader (if allowed), else canopy `modulate.a` 0.55 on that single sprite | no | shader / modulate / modulate |
| MUCUS jiggle | a shot bounces off | scale 1 → 1.04 → 0.98 → 1 over 160 ms + a ripple | no | all |
| BRITTLE hit | hits 1 and 2 | wobble + atlas region swap s0 → s1 → s2 + 3–4 shared debris chunks | **yes: s0, s1, s2 (Codex edits)** | chunks ×0.5 on LOW; JuiceFx only on MIN |
| BRITTLE break | hit 3 | base region → rubble (**permanent**) + dust ring | **yes: rubble (edit)** | all |
| Ripples | shot lands, bounces or expires; dash; stop; food absorbed | shared S3 ring inside JuiceFx | no | ≤ 12 / ≤ 6, impacts only / off |
| Vent current | always | S2 swirl at 0.72 rad/s, tint `VENT`; existing sink motes | no | all |
| Clutter pop | a shot crosses a clutter piece | scale 1 → 1.25 → 0 + spin + a tiny ripple; it regrows after 6 s (deterministic, client-only) | no | pop / static / hidden |
| Rim glint | own microbe touches the wall | lip `Line2D` brightens for 200 ms (one node) | no | HIGH / LOW |
| Ambient drift | always | outside props bob ±20 px over 8 s | no | animated / static / hidden |

### 5.8 Ambient props outside the dish
Pipeline-made "distant colonies" (blurred `mucus_bloom` and `bush_canopy`), two or three blurred approved hero silhouettes drifting far beyond the glass (V ≤ 0.15), and bubbles on the outer glass. Everything sits ≥ 150 px outside the rim so nothing reads as a live enemy. No Codex call.

### 5.9 Quality.LOW fallback
- No shaders: two floor sprites, or the macro alone on MINIMUM.
- Canopy fade by modulate.
- Clutter static on LOW, hidden on MINIMUM. Ambient props static on LOW, hidden on MINIMUM.
- Ripples ≤ 6 and impacts only.
- Half-resolution atlas (1024²) on MINIMUM.
- Total VRAM about 28 MiB on HIGH/LOW and about 8 MiB on MINIMUM (technique §6).

### 5.10 Drying zone (SOLO/DUO/TRIO)
- Outside the wet radius the agar dries to khaki: `AQAR_DRY` @ 0.55, plus the existing deterministic cracks in `DRY_CRACK` (18 on HIGH, 10 on LOW).
- The boundary ring stays **amber and pulsing**, as it does in every theme.
- Steam only on HIGH.
- Clutter and ripples are suppressed outside the wet radius ("dry, dead floor").

### 5.11 Optional extra (needs a sim change): **Osmos bulağı / Osmotic spring**
- A BS healing-pad analogue: a flat round seep that slowly moves fullness toward 50%, the healthy middle. This is the game's equivalent of healing.
- Look: a pale, mint-free soft-cyan halo pad with concentric gentle rings, no amber and no swirl (so it can never be mistaken for a VENT).
- Needs a new `Kind`, a sim rule and the network bits. **Optional showcase image only.**

### 5.12 Codex asset list: Version 1

| # | File | Purpose | Canvas | Alpha | View / projection | Footprint / placement | Stage / made from | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v1_mockup.png` | Style anchor; version comparison | 1536×1024 | opaque | in-game Damla camera | scene, §5.13 | refs: `world.png`, `world_solo.png`, `hero_*.png`, `menu_bg.jpg`, `map0.png` | see §5.13 | HUD, text, faces, vanishing points, raised caps |
| 2 | `map_v1_floor_macro.png` | Whole-dish floor tone | 1024² | opaque | plan, flat light | disc touches all four edges; corners `#071012` | ref 1 | centre `#1E3B42` → `#162D33` → foot AO `#0D1C20`; 5–9 soft agar zones ≥ 10% of the canvas; max channel ≤ 0.35 | rings, grid, objects, bright spots, hard edges |
| 3 | `map_v1_rim_north.png` | North inner glass wall strip | 1536×1024; band y 320–704 | opaque band on `#FF00FF` | wall face seen from inside, flat (no curvature) | foot line = bottom of the band; lip = top | seam fix (§3.1) | §5.5: foot crease, teal glass face, soft vertical streaks, condensation beads, lip line ≤ 12 px; seamless left to right | curvature, things behind the glass, high-frequency verticals (they strobe when tiled), text |
| 4 | `map_v1_mucus_blob.png` | MUCUS variant A | 1024² | transparent | plan + oblique height (`template_v1`) | footprint (512,512) r 384; cap (512,474) r 346 | `template_v1`, ref 1 | smooth glossy teal gel dome; specular upper-left; south band darkest lower-right; continuous outline | granules, paired spots, cast shadow, lift above the red circle |
| 5 | `map_v1_mucus_bloom.png` | MUCUS variant B | 1024² | transparent | same | same | ref 4 (lighting match) | same dome + 6–10 vesicles ≥ 6% of the canvas, low contrast, irregular spacing | eye-like pairs, bubbles breaking the silhouette |
| 6 | `map_v1_brittle_s0.png` | BRITTLE stage 0 | 1024² | transparent | same | same | `template_v1`, ref 1 | matte chalky grey-teal crust dome; 15% hairline **amber** cracks with glowing cores; angular crack language | smooth gel look, amber over > 3% of the area as glow |
| 7 | `map_v1_brittle_s1.png` | Stage 1 | 1024² | transparent | same | identical | **edit of 6** | cracks 35%, wider; 2 shallow chips inside the silhouette (≤ 0.06 R) | any change to silhouette or outline |
| 8 | `map_v1_brittle_s2.png` | Stage 2 | 1024² | transparent | same | identical | **edit of 7** | cracks 60%; glowing amber interior visible; 4 chips; lifted flakes | holes through the shell, silhouette change |
| 9 | `map_v1_brittle_rubble.png` | Permanent broken decal | 1024² | transparent | plan, **flat** | within r 346 (0.9 R) | **edit of 8** | 8–12 flat dull shards in a loose ring, no outline, embers in 2–3 cracks; max channel ≤ 0.45 | height, side band, outline, glow > 3% |
| 10 | `map_v1_bush_base.png` | BUSH ground mat (under microbes) | 1024² | transparent | plan, flat | r 365 (0.95 R) | `template_bush`, ref 1 | dark green `#1E4A38`–`#357A5C` mat of frond roots, soft fuzzy edge | outline, height, bright tips, flowers |
| 11 | `map_v1_bush_canopy.png` | BUSH canopy (above microbes) | 1024² | transparent | plan + lifted fronds | envelope per `template_bush`; hollow r 134 at (512,454) | ref 10 | 18–24 thick soft fronds (≥ 40 px at the root), curled tips, lit upper-left, `#4E9C7A` tips; hollow centre ≤ 30% coverage | solid centre, outline, lime/mint saturation, faces |
| 12 | `map_v1_vent_base.png` | VENT pit | 1024² | transparent | plan, negative height | lip on r 384; hole floor (512,539) r 342 | `template_vent` | broken amber lip (8–10 dashes); inner wall shadow upper-left, lit lower-right; near-black centre | swirl (that is S2), continuous outline, glow outside the lip |
| 13 | `map_v1_clutter.png` | 4 pop-able floor clutter pieces | 1024², 2×2 cells of 512 | transparent | plan, flat, **unlit** (the game may rotate and flip them) | each within r 200 of its cell centre | ref 1 | agar flake, crumb cluster, fibre curl, salt-grain cluster; ±0.08 value from the floor; max channel ≤ 0.45 | round balls (they read as food), outlines, highlights, glow |
| (14) | `map_v1_x_osmos.png` | *Optional showcase:* Osmotic spring | 1024² | transparent | plan, flat pad | r 384 | `template_v1` (footprint only) | soft pale-cyan halo pad, 3 concentric soft rings | amber, swirl, broken outline (VENT language) |

### 5.13 Mockup brief (`map_v1_mockup.png`)

```text
Use case: stylized concept frame for comparing art directions (not a game asset)
Primary request: A battle frame from the mobile game "Germ Arena", exactly as the phone would show it
  but with NO HUD and no text. Single-celled microbes fight inside a giant water-filled petri dish.
Camera: straight top-down; floor circles stay circles (no perspective, no vanishing points). Height
  shows only as darker side bands on the SOUTH (bottom) side of obstacles. Light from the upper-left;
  shadows are soft and light (only 25-30% darker), offset to the lower-right.
Framing: the frame shows about 1000 x 670 world units near the NORTH edge of the dish: the glass
  wall arcs gently across the top 15-20% of the frame; above it, the dark outside (#071012) with a
  few huge blurred, faceless colony silhouettes far away.
Floor: smooth dark-teal agar (#162D33, lighter #1E3B42 pool toward the frame's bottom), a faint
  square grid, one wide soft sediment band, a few flat agar flakes.
Glass wall: clear teal glass seen from inside, a dark wet crease where it meets the floor, a thin
  bright cyan-white lip line on top.
Microbes (game style: thick near-black outline, glossy cel-shaded jelly, NO FACE), body ~86 px:
  lime ciliate (player) near the centre; magenta heliozoan (round body, thin ray-legs ending in balls)
  right; blue amoeba (rounded-triangle blob) lower-left; amber ciliate upper-right; a violet one half
  hidden UNDER a bush, the fronds drawn over it. Three glossy shot balls (~28 px, shooter's colour,
  short trails), 8-10 pale food balls (#D9FFC0, ~30 px).
Obstacles (diameters 100-300 px): two smooth glossy teal gel domes and one granular dome, each fully
  inside its round base; one chalky crust dome with glowing AMBER cracks being hit (amber chips
  flying); one bush of soft muted-green fronds (#357A5C, no outline) with a hollow centre; one round
  pore with a dashed amber lip and a slowly turning amber swirl, close to the glass wall.
Juice: soft white ripple rings where balls hit the floor.
Avoid: any text or UI, faces/eyes on anything, lab equipment, metal, raised walls taller than their
  base, saturated lime or mint bushes, perspective.
```

---

## 6. Version 2: **Sütun / Pillar** (technique V2 × theme T3 Gölməçə / Pond Drop)

> **Needs the owner's approval.** It breaks ART_BIBLE §4b ("silhouette = collision footprint") for MUCUS and BRITTLE caps, lifted by ≤ 0.10 R and ≤ 16 px, with the mitigations below. Playtest it on Arxipelaq's 74 px core–pebble gaps (technique study F7).

### 6.1 Pitch
The full Brawl Stars package in a sunlit pond drop:
- Squat jelly drums and diatom pillboxes whose tops stand slightly above their bases, like BS walls.
- Algae tufts sway over hidden microbes like BS seaweed.
- Bubblers fizz in the vents.
- Caustic light crawls over olive silt.

This is the closest analogue to BS **Deep Sea**: its jellyfish walls become jelly drums, its bubbler clutter becomes bubbler vents, and the seaweed sway shader becomes the two-frequency algae sway. Showcase layout: Arxipelaq (islands in a pond).

### 6.2 Palette

| Role | Hex | Note |
|---|---|---|
| Outside / far | `#0A1310` / `#030706` | deep pond water |
| Floor: sunlit centre / mid / edge | `#3A3E2C` / `#2B3023` / `#181C14` | olive silt, hue 73–90°, chroma ≤ 0.07, V ≤ 0.24. **Lowest microbe contrast of the four versions (3.3:1 in the centre pool), so keep the pool small** |
| MUCUS (jelly drum) top / body / face / specular | `#4A6670` / `#36505A` / `#22363E` / `#75909A` | cool slate jelly, a deliberate opposite to the warm floor |
| BRITTLE (diatom) top / ribs / face | `#8A8670` / `#5D5A4A` / `#3F3D32` | pale silica glass, S ≤ 0.21 |
| BRITTLE crack / core | `#D09345` / `#F0B94E` → `#FFD27A` | |
| BUSH shadow / body / tips | `#1F4A3D` / `#387A64` / `#519C82` | hue 160°, S 0.48–0.58, V ≤ 0.61 |
| VENT lip / hole | `#F0B94E` (broken) / `#070B08` | |
| Rim glass body / lip highlight | `#3D5B52` / `#E8EDC8` | algae-film glass with a warm sunlit lip |
| Caustic tint | `#D8E6B0` @ α 0.06–0.10 | code |
| Ghost footprint rim / x-ray outline | `#E8EDC8` @ 0.35 / own microbe colour @ 0.55 | code |
| Drying: tint / cracks | `#4A3F2A` @ 0.5 / `#2A2418` | dried mud plates |

### 6.3 Technique and camera
- **Camera:** unchanged (orthographic floor, height straight up).
- **Geometry (template_v2):**
  - L class: H = 0.18 R, cap radius 0.92 R, **lift L = 0.10 R (≤ 16 px at R = 150)**, south band 0.26 R.
  - S class reuses the L master, so the lift there is 0.10 R (3–6 px on pebbles). If pebbles look flat in playtest, add S-specific masters at H = 0.22 R for +2 images.
  - Shadow offset (+0.14 R, +0.27 R).
- **Codex paints one complete obstacle;** the pipeline cuts it into a **cap cell** and a **base cell** (base = face + shadow + AO + ghost footprint disc).
- **Layers (two, no y-sort):**

| Layer | z | Contents | Draw calls |
|---|---|---|---|
| Base atlas | below microbes | bases, vents, rubble, swirls | 1 |
| Cap atlas | z 3, above microbes | MUCUS/BRITTLE caps + bush canopies, sorted **once** by footprint y | +1 |

- **Mitigations, required on all tiers:**
  - A footprint **ghost ring**: dashed arcs around blocking obstacles within R + r + 60 px of your microbe. One `draw_multiline`, +1 call.
  - An **x-ray outline** of your own microbe while it overlaps a cap (+1 call while active).
  - The **cap fade** to 0.55 on the 1–2 affected caps.
  - `aim_guide` is split: the line stays under the microbes; bounce rings, arrow and lock go above the caps.
  - The name `Label` uses `z_as_relative=false` at z 6.
- **Cost:** environment calls about 12–13; fill +0.3–0.5 screen over version 1; about +2 days of code.

### 6.4 Floor
- **Macro:** warm olive silt; a soft sunlit pool; 6–10 faint ochre "diatom-dust" drifts and a few darker organic smudges; foot AO.
- **Detail:** shared S1 (the silt grain reads fine under olive).
- **HIGH only:** S7 caustics as two overlapping sprites of the tile, scrolling slowly in opposite directions, additive, α 0.06–0.10. +1 call and about +1 screen of fill, so it is **off on LOW and MINIMUM**.

### 6.5 Rim and outside
- **`rim_north`:** glass coated with a thin olive-green algae film that is thickest at the foot (fuzzy filaments rising a little), a sun-warm lip line `#E8EDC8`, a few clinging bubbles.
- **South lip:** code, same as version 1, with pond colours.
- **Outside:** deep pond water annulus. Pipeline-blurred giant diatoms (from `brittle_s0`) and algae (from `bush_canopy`) drift far below. On HIGH only, 2–3 slow, very faint god-ray quads from the upper-left (code `GradientTexture2D`, additive).

### 6.6 Obstacles

| Kind | Design |
|---|---|
| **MUCUS blob** | A squat glossy **jelly drum**: a rounded cushion top, straight-ish sides in the south band, cool slate-blue translucent gel with a soft inner glow line under the top rim. |
| **MUCUS bloom** | A **frogspawn cushion**: the same drum built of clustered gel beads (≥ 6% of the canvas each). **No dots or cores inside the beads** (they would read as eyes). |
| **BRITTLE** | A **centric diatom pillbox**: a round silica drum whose top carries fine radial ribs (striae) and a central rosette, pale glass. **Amber cracks** cut across the ribs. Stages (s1 and s2 change **only the top face**; the band is kept, as the V2 split requires):<br>• **s0:** 15% cracked.<br>• **s1:** 35% + 2 chips in the top rim.<br>• **s2:** 60%, the glowing interior shows, the top plate starts to split.<br>• **Rubble:** flat glass shards and rib fragments. |
| **BUSH** | **Base:** dark olive-teal algae mat. **Canopy:** ribbon-like pondweed and spiral-filament tufts, 16–22 strands ≥ 40 px wide at the root, gently twisted, hollow centre. |
| **VENT** | A **bubbler spring**: a round hole in the silt with a broken amber lip, a silt-rim lip shadow and a dark throat. Rising bubbles are code (rings in the JuiceFx group). |

### 6.7 Interactive behaviours
Everything in the version 1 table, plus the following. Signature: **"living pond"**.

| Behaviour | Implementation | Frames? | HIGH / LOW / MIN |
|---|---|---|---|
| Two-frequency algae sway (BS `seaweed.vsh`: faster, amplitude ≈ 7.5% of height) | per-node rotation/skew, sum of two sines | no | full / full / ×0.5 |
| Cap wobble moves cap and base together | the same tween on both sprites | no | all |
| Cap fade over own microbe | `modulate.a` 0.55 on ≤ 2 caps, or the hole shader | no | all |
| Ghost footprint ring + x-ray | code (§6.3) | no | **all** |
| Bubbler bubbles | 3–5 rising, growing rings per vent, then a small S5 splash at the top | no | 5 / 3 / 0 |
| Caustics | S7, two scrolling layers | no | on / off / off |
| Diatom shatter | s0 → s1 → s2 region swap + S6 chunks tinted silica + rubble | **yes: s0–s2 + rubble (edits)** | as version 1 |

### 6.8 Ambient props, LOW and drying
- **Ambient props:** §6.5. Pipeline-made, no Codex call.
- **LOW:** as version 1, plus caustics and god rays off, and bubble count 3. Ghost ring and x-ray stay on every tier, because they are a readability fix, not juice.
- **Drying zone:** the pond evaporates. Mud tint `#4A3F2A` @ 0.5; cracks drawn as **polygonal mud plates** (the same multiline call with a different seed pattern); caustics clipped to the wet radius; amber boundary ring; on HIGH the existing steam becomes a "shimmer".

### 6.9 Optional extra (needs a sim change): **Fışqırıq / Geyser pad**
- The BS springboard analogue: a bubbling vent that throws a microbe about 600 px in a fixed direction after 1 s; 3 s cooldown.
- The sim needs a ballistic "airborne" state that ignores obstacles. This is a big change.
- Look: a ring of silt with a white bubble column and **one** chevron notch in its rim pointing the launch direction. No amber, no swirl.
- **Optional showcase image only.**

### 6.10 Codex asset list: Version 2

| # | File | Purpose | Canvas | Alpha | View / projection | Footprint / placement | Stage / made from | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v2_mockup.png` | Style anchor; comparison | 1536×1024 | opaque | in-game, raised caps | scene, §6.11 | refs as version 1 + `map1.png` | see §6.11 | HUD, text, faces, tall towers, vanishing points |
| 2 | `map_v2_floor_macro.png` | Pond silt floor | 1024² | opaque | plan | disc touches all edges; corners `#0A1310` | ref 1 | olive silt `#2B3023`, small sunlit pool `#3A3E2C`, ochre dust drifts, foot AO; max channel ≤ 0.35 | caustics (S7 does those), rings, grid, objects, bright greens |
| 3 | `map_v2_rim_north.png` | Algae-filmed glass wall | 1536×1024; band y 320–704 | opaque band on `#FF00FF` | flat wall face | foot = bottom of the band | seam fix | olive algae fuzz at the foot thinning upward, glassy green-teal face, warm lip line, clinging bubbles; seamless | curvature, plants taller than ~1/3 of the band, text |
| 4 | `map_v2_mucus_blob.png` | MUCUS A: jelly drum | 1024² | transparent | plan + oblique, **lifted cap** (`template_v2`) | footprint r 384; cap (512,443) r 353; top at y ≥ 90 | `template_v2`, ref 1 | squat slate-blue jelly drum, rounded top edge, 100 px south band with a subsurface glow line, specular upper-left; continuous outline | lift beyond y 90, sideways bulge beyond the red circle, beads, faces |
| 5 | `map_v2_mucus_bloom.png` | MUCUS B: frogspawn cushion | 1024² | transparent | same | same | ref 4 | the same drum built of clustered gel beads ≥ 60 px | dots or cores in beads, eye pairs, beads outside the silhouette |
| 6 | `map_v2_brittle_s0.png` | Diatom pillbox, stage 0 | 1024² | transparent | same | same | `template_v2`, ref 1 | pale silica drum, radial rib top, central rosette, 15% amber cracks | metallic or chrome look, perfect gear teeth, text-like marks |
| 7 | `map_v2_brittle_s1.png` | Stage 1 | 1024² | transparent | same | identical | **edit of 6, top face only** | 35% cracks, 2 rim chips | any change to the south band |
| 8 | `map_v2_brittle_s2.png` | Stage 2 | 1024² | transparent | same | identical | **edit of 7, top face only** | 60% cracks, glowing interior, top plate splitting | silhouette change |
| 9 | `map_v2_brittle_rubble.png` | Broken decal | 1024² | transparent | plan, flat | within r 346 | **edit of 8** | flat silica shards and rib fragments, no outline, max channel ≤ 0.45 | height, outline |
| 10 | `map_v2_bush_base.png` | Algae mat | 1024² | transparent | plan, flat | r 365 | `template_bush` | dark olive-teal filament mat, fuzzy edge | outline, height |
| 11 | `map_v2_bush_canopy.png` | Pondweed canopy | 1024² | transparent | plan + lifted strands | `template_bush` envelope, hollow r 134 | ref 10 | 16–22 twisted ribbon/filament strands ≥ 40 px, tips `#519C82`, hollow centre | solid centre, lime, flowers, outline |
| 12 | `map_v2_vent_base.png` | Bubbler spring | 1024² | transparent | plan, negative height | `template_vent` | `template_vent` | broken amber lip, silt-rim shadow, dark throat; inner wall lit lower-right | painted bubbles (code draws them), continuous outline |
| 13 | `map_v2_clutter.png` | 4 pop-able pieces | 1024², 2×2 | transparent | plan, flat, unlit | r ≤ 200 per cell | ref 1 | half diatom valve, algae scrap, detritus flake, silt grains | round balls, outlines, glow |
| (14) | `map_v2_x_geyser.png` | *Optional showcase:* Geyser pad | 1024² | transparent | plan, flat pad | r 384 | `template_v1` (footprint only) | silt ring, white bubble column core, one chevron notch in the rim | amber, swirl, broken outline |

### 6.11 Mockup brief (`map_v2_mockup.png`)
Same frame rules as §5.13, with these changes:

```text
Camera: top-down floor, but obstacles are short PILLARS seen from slightly south: each top face is
  lifted a little above its round base (by about one tenth of its radius), with a visible darker
  front band below it, like the low walls in Brawl Stars. Light upper-left; soft light shadows to
  the lower-right.
Theme: a sunlit pond drop inside the petri dish. Olive silt floor (#2B3023) with a faint pale
  caustic light network; glass wall at the top coated in a thin olive algae film with a warm lip
  highlight; deep pond-green darkness beyond, blurred giant diatoms far below.
Obstacles: an island of one big slate-blue jelly drum ringed by 3 small jelly pebbles (one beaded
  "frogspawn" cushion); a pale silica diatom pillbox with radial ribs and AMBER cracks being hit
  (glass chips flying); a pondweed bush of twisted muted-teal ribbons (#387A64) with a microbe
  hidden under it, ribbons drawn over the microbe; a round bubbler hole with a dashed amber lip and
  bubbles rising.
Show the occlusion honestly: one microbe just NORTH of a jelly drum is partly hidden behind the
  drum's top, and its outline shows through as a thin glowing line.
Microbes, balls, food, ripples: as version 1.
Avoid: as version 1, plus tall towers, cliffs, saturated green water.
```

---

## 7. Version 3: **Mağara / Cave** (technique V1 × theme T2 Biofilm)

### 7.1 Pitch
Version 1's strict droplet technique in a bold new world: a dark violet biofilm cave where the floor **answers the microbes with pale bioluminescence**. Glossy EPS mounds, chalky mineral crusts with amber seams, and glowing teal streamer bushes, which make the strongest bush-versus-floor contrast of any version. It shows how far a theme alone can push the look without touching a single rule. Showcase layout: Spiral (biofilm arms).

### 7.2 Palette

| Role | Hex | Note |
|---|---|---|
| Outside / far | `#0B0812` / `#040307` | |
| Floor: centre / mid / edge | `#2A2238` / `#201B2C` / `#120F1A` | hue 256–262°, chroma ≤ 0.09, V ≤ 0.22. **Best microbe contrast: ≥ 4.5:1 even for violet `A96BFF`** |
| EPS strands (in the floor) | `#352C46` | |
| MUCUS (EPS mound) top / body / face / specular | `#3F3858` / `#2C2742` / `#1A1628` / `#7A7299` | lilac specular kept at S ≤ 0.35 |
| BRITTLE (mineral crust) top / face | `#6B6274` / `#3E3746` | chalky mauve-grey |
| BRITTLE crack / core | `#D09345` / `#F0B94E` → `#FFD27A` | |
| BUSH shadow / body / tips | `#1E4A41` / `#33796A` / `#4C9A88` | hue 166°, S 0.51–0.59, V ≤ 0.60 |
| Bioluminescent accents | `#A6E4DC` | S 0.27, emissive ≤ 3% |
| VENT lip / hole | `#F0B94E` (broken) / `#06040A` | |
| Rim glass body / lip highlight | `#4A4466` / `#D9D2F0` | |
| Glow pool (code) | `#A6E4DC` @ α 0.10–0.18 | additive |
| Drying: tint / cracks | `#4A4652` @ 0.5 / `#847E90` | |

**Colour risk:** the violet `A96BFF`, magenta `FF5BC8` and pink `FF87A8` microbes sit on a violet floor. Hue contrast is lost, but the value gap (floor V ≤ 0.22 against microbes V ≥ 0.91) plus the thick outline carry them. Keep every environment lilac at S ≤ 0.35. **Key colour for violet subjects is `#00FF00`;** for the bush it is `#FF00FF`.

### 7.3 Technique and camera
Identical to version 1 (§5.3): lift 0, south band, pipeline shadows, lifted canopy above the microbes. One addition: the **glow pool**, a code-made `GradientTexture2D` radial sprite under each **received** microbe on HIGH. All pools share one texture and an additive material on the parent, so they cost +1 call.

### 7.4 Floor
- **Macro:** dark plum-indigo, with a fibrous EPS matrix of soft branching strands (≥ 12 px wide at 1024, low contrast) and sparse pale-aqua bioluminescent specks (≤ 2% of area). Gentle foot AO.
- **Detail:** shared S1.

### 7.5 Rim and outside
- **`rim_north`:** glass overgrown with violet biofilm sheets creeping up from the foot and thinning with height, a scatter of glowing pale-aqua dots, a cool lilac-white lip line.
- **Outside:** the dark violet void. Pipeline-blurred colonies (from `mucus_bloom`) tinted pale aqua at low alpha pulse slowly (code), like distant bioluminescent towns.

### 7.6 Obstacles

| Kind | Design |
|---|---|
| **MUCUS blob** | A glossy dark **EPS mound**: a smooth slime dome, deep indigo, with a lilac specular at the upper-left. |
| **MUCUS bloom** | A **microcolony cluster**: a dome of fused bumpy lobes like a slime cauliflower, each lobe ≥ 6% of the canvas. |
| **BRITTLE** | A **mineralised crust**: a chalky mauve-grey dome of calcite plates; the amber seams between the plates are the cracks. Stages:<br>• **s0:** 15%.<br>• **s1:** 35%, 2 plates chipped.<br>• **s2:** 60%, the amber core glows through the open seams.<br>• **Rubble:** flat chalk plates. |
| **BUSH** | **Base:** dark teal filament mat. **Canopy:** 18–24 flowing **streamer** fronds with pale-aqua glowing dots at their tips (emissive ≤ 3%), hollow centre. |
| **VENT** | A **biofilm pore**: a broken amber lip, a slick violet inner wall (lit lower-right) and a black throat. |

### 7.7 Interactive behaviours
Everything in the version 1 table, plus the following. Signature: **"the floor glows back"**.

| Behaviour | Implementation | Frames? | HIGH / LOW / MIN |
|---|---|---|---|
| Glow pool under each **received** microbe. Hidden enemies are never sent, so nothing leaks | one additive sprite per microbe, radius 2.2 r, alpha follows speed | no | on / off / off |
| Streamer flash when a visible microbe brushes through | canopy `modulate` +15% for 250 ms on 1 sprite (≤ +2 calls in the worst case, F2) | no | on / on / off |
| Popped clutter glows briefly | pop tween + pale-aqua tint | no | on / static / hidden |
| Bioluminescent specks | baked in the macro | no | all |
| Crust shatter | as version 1, with chunks tinted chalk | **yes: s0–s2 + rubble** | as version 1 |

### 7.8 Ambient props, LOW and drying
- **Ambient props:** §7.5. Pipeline-made, no Codex call.
- **LOW:** glow pools off (the baked specks stay), outside pulses static; otherwise as version 1.
- **Drying zone:** the biofilm desiccates into a chalky film (`#4A4652` @ 0.5, cracks `#847E90`); glow pools and streamer flashes are disabled outside the wet radius ("dead zone"); the boundary ring stays amber.

### 7.9 Optional extra (needs a sim change): **Məsamə cütü / Pore pair** (teleporter)
- The BS teleporter analogue: two linked pores (biofilm water channels). Entering one moves you to the other; 3 s activation and cooldown.
- **The pair is marked by a notch pattern (1, 2 or 3 notches), not by colour,** because colours belong to the microbes.
- Look: a pale-aqua glowing ring pad with notches in its rim. No amber, no swirl.
- **Optional showcase image only.**

### 7.10 Codex asset list: Version 3

| # | File | Purpose | Canvas | Alpha | View / projection | Footprint / placement | Stage / made from | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v3_mockup.png` | Style anchor; comparison | 1536×1024 | opaque | in-game Damla camera | scene, §7.11 | refs as version 1 + `map2.png` | see §7.11 | HUD, text, faces, bright violet floor |
| 2 | `map_v3_floor_macro.png` | Biofilm floor | 1024² | opaque | plan | disc touches all edges; corners `#0B0812` | ref 1 | plum-indigo `#201B2C`, EPS strand matrix ≥ 12 px, pale-aqua specks ≤ 2%; max channel ≤ 0.35 (specks excepted) | magenta/pink saturation, rings, grid, objects |
| 3 | `map_v3_rim_north.png` | Biofilm-overgrown glass | 1536×1024; band y 320–704 | opaque band on **`#00FF00`** | flat wall face | foot = bottom of the band | seam fix | violet slime sheets thinning upward, aqua glow dots, lilac lip line; seamless | dripping strands longer than 1/4 of the band, curvature, text |
| 4 | `map_v3_mucus_blob.png` | MUCUS A: EPS mound | 1024² | transparent (key `#00FF00`) | plan + oblique (`template_v1`) | footprint r 384; cap (512,474) r 346 | `template_v1`, ref 1 | smooth glossy indigo slime dome, lilac specular upper-left, darker south band; continuous outline | lift, lilac S > 0.35, faces |
| 5 | `map_v3_mucus_bloom.png` | MUCUS B: microcolony cluster | 1024² | transparent | same | same | ref 4 | fused bumpy lobes ≥ 60 px, cauliflower dome | eye pairs, lobes outside the silhouette |
| 6 | `map_v3_brittle_s0.png` | Mineral crust, stage 0 | 1024² | transparent | same | same | `template_v1`, ref 1 | chalky mauve-grey calcite plates, amber seams 15% | crystal spikes (corners), metal |
| 7 | `map_v3_brittle_s1.png` | Stage 1 | 1024² | transparent | same | identical | **edit of 6** | 35% seams, 2 chipped plates | silhouette change |
| 8 | `map_v3_brittle_s2.png` | Stage 2 | 1024² | transparent | same | identical | **edit of 7** | 60%, the amber core glows through | holes, silhouette change |
| 9 | `map_v3_brittle_rubble.png` | Broken decal | 1024² | transparent | plan, flat | r ≤ 346 | **edit of 8** | flat chalk plates, no outline, max channel ≤ 0.45 | height, outline |
| 10 | `map_v3_bush_base.png` | Filament mat | 1024² | transparent (key `#FF00FF`) | plan, flat | r 365 | `template_bush` | dark teal mat, fuzzy edge | outline, height |
| 11 | `map_v3_bush_canopy.png` | Glowing streamer canopy | 1024² | transparent | plan + lifted streamers | `template_bush`, hollow r 134 | ref 10 | 18–24 flowing streamers ≥ 40 px, pale-aqua tip dots ≤ 3%, hollow centre | solid centre, full-body glow, outline |
| 12 | `map_v3_vent_base.png` | Biofilm pore | 1024² | transparent | plan, negative height | `template_vent` | `template_vent` | broken amber lip, slick violet inner wall lit lower-right, black throat | swirl, continuous outline |
| 13 | `map_v3_clutter.png` | 4 pop-able pieces | 1024², 2×2 | transparent | plan, flat, unlit | r ≤ 200 per cell | ref 1 | EPS strand knot, mineral grain cluster, slime flake, branching filament | round balls, outlines, glow |
| (14) | `map_v3_x_pores.png` | *Optional showcase:* Pore pair (one pore; the game uses it twice) | 1024² | transparent | plan, flat pad | r 384 | `template_v1` (footprint only) | pale-aqua glowing ring pad with 2 rim notches | amber, swirl, colour coding |

### 7.11 Mockup brief (`map_v3_mockup.png`)
Same frame rules as §5.13, with these changes:

```text
Theme: a dark violet BIOFILM CAVE inside the petri dish. Floor of dark plum-indigo slime (#201B2C)
  laced with soft branching strands and sparse tiny pale-aqua glowing specks; a soft pale-aqua glow
  pool on the floor under each microbe. Glass wall at the top overgrown with violet biofilm and
  glowing dots, cool lilac lip line; violet darkness beyond with faint distant glowing colonies.
Obstacles (all fully inside their round bases, south side bands only): glossy indigo slime mounds,
  one bumpy microcolony cluster, a chalky mauve-grey crust of plates with glowing AMBER seams being
  hit (chalk chips flying), a bush of flowing muted-teal streamers (#33796A) with glowing aqua tips
  and a microbe hidden under them, one round pore with a dashed amber lip and a slowly turning swirl.
Keep the floor DARK so the microbes (including the violet and magenta ones) pop. Glow is sparse.
Avoid: as version 1, plus neon purple, bright magenta, glowing floor everywhere.
```

---

## 8. Version 4: **Perspektiv / Perspective** (technique V4 × theme T1 Aqar), gated

> **Needs the owner's approval** for three things: §4b is broken (lift ≤ 0.14 R), the round dish shows as an oval, and movement and aim feel anisotropic. **Build a code prototype first** (about 1 day): squash the camera only and show version 1's art in world space. Commission the remaining art only if the prototype feels right. Until then only the mockup and 3 probe cells are generated.

### 8.1 Pitch
Version 1's world seen through a tilted Brawl Stars-style camera. The dish becomes an oval, the far glass wall rises tall, the floor grid foreshortens, and the droplets stand in 3/4 view on elliptical bases. This is the closest 2D gets to BS's 3D camera at zero GPU cost.

### 8.2 Technique and camera (technique study §3C)
- **Camera:** `Camera2D.zoom = (k, k·0.82)`, an orthographic squash with no vanishing points.
- **Input:** `world = Vector2(s.x, s.y / c).normalized()`. Also fix `_view_rect` and `_test_aoi_covers_screen`.
- **Upright sprites** (obstacle art, canopies, the north wall, labels) are counter-scaled by (1, 1/c) at their foot.
- **Microbes are NOT counter-scaled.** They lie flat on the floor and squash with it, which keeps gap reading affine-exact.
- **Obstacle art:** elliptical footprint ratio 0.82 (`template_v4`); cap lift ≤ 0.14 R (54 px at 1024).
- **Version 2 mitigations apply:** ghost ring, x-ray, cap fade, aim overlay split, label z.

### 8.3 Reuse from version 1
Everything that is flat in world space is squashed correctly by the camera, so it is reused **unchanged**:

| Reused as is | Reused with a change |
|---|---|
| floor macro + S1 detail, `bush_base`, `brittle_rubble`, `vent_base` + S2 swirl, clutter, all shared juice | `rim_north`: drawn upright, with W(θ) raised to 70 / 0.82 at due north |

The palette, drying zone, LOW fallback and juice are those of version 1.

### 8.4 Codex asset list: Version 4 (probe)

| # | File | Purpose | Canvas | Alpha | View / projection | Footprint / placement | Stage / made from | Must have | Must avoid |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `map_v4_mockup.png` | Comparison with version 1 | 1536×1024 | opaque | 55° tilted orthographic camera | scene, §8.5 | refs as version 1 + `map_v1_mockup.png` (theme match) | see §8.5 | vanishing points, foreshortened microbes drawn upright, text |
| 2 | `map_v4_mucus_blob.png` | MUCUS A in 3/4 view | 1024² | transparent | 3/4 view, elevation 55° | **ellipse** centred (512,560), rx 384, ry 315; cap ellipse (512,481) rx 353 ry 290 | `template_v4`, ref `map_v1_mucus_blob.png` (material match) | the same teal gel as version 1, now a low dome on an elliptical base, front band 104 px | lift above y 191, side bulge beyond the ellipse |
| 3 | `map_v4_brittle_s0.png` | BRITTLE s0 in 3/4 view | 1024² | transparent | same | same | `template_v4`, ref `map_v1_brittle_s0.png` | the same crust and amber cracks in 3/4 | as above |
| 4 | `map_v4_bush_canopy.png` | Canopy in 3/4 view | 1024² | transparent | same | `template_v4_bush`; hollow ellipse rx 134 ry 110 at (512,480) | ref `map_v1_bush_canopy.png` | fronds rise and arch, hollow centre | outline, solid centre |
| later | `map_v4_mucus_bloom.png`, `map_v4_brittle_s1.png`, `map_v4_brittle_s2.png` | Only if adopted | 1024² | transparent | same | same | bloom: ref 2; s1 and s2: **edits of 3** | as version 1 | as version 1 |

### 8.5 Mockup brief (`map_v4_mockup.png`)
```text
Same theme, microbes, obstacles and juice as the Version 1 mockup (attached as reference), but the
CAMERA is tilted like Brawl Stars: an orthographic view from about 55 degrees above, with NO
vanishing points (parallel lines stay parallel). The floor is squashed vertically to about 82%:
round things lying on the floor (the dish edge, the bush base mats, the pore, the ripple rings, and
the flat microbes themselves) become slightly wide ellipses. Obstacles stand up in 3/4 view as low
glossy domes on elliptical bases, showing their front (south) side. The glass wall at the top of the
frame is the far wall, so it rises noticeably taller. Light from the upper-left; light shadows to the
lower-right. No HUD, no text, no faces.
```

---

## 9. Optional gameplay tiles (all need a sim change; not part of any core list)

Each would be a new `DishMap.Kind` drawn as a circle `Vector4(x, y, r, kind)`, so it fits the footprint system. Server, sim, bots and the `--simtest` suite all change. Each extra is **visually separated from VENT** (no amber, no swirl, no broken outline) and from food and microbes (no glossy balls, no microbe hues).

| Extra (AZ / EN) | BS analogue | Theme fit | Behaviour | Sim and network impact | Visual |
|---|---|---|---|---|---|
| **Osmos bulağı / Osmotic spring** | Healing pad / mushroom ring | 1 Aqar | moves fullness toward 50% at about 2/s while standing on it | new rule in `sim.gd`; 1 byte for the kind | showcase image in version 1 |
| **Fışqırıq / Geyser pad** | Springboard | 2 Gölməçə | launches 600 px in a fixed direction after 1 s; 3 s cooldown | new airborne state that ignores obstacles: **large** | showcase image in version 2 |
| **Məsamə cütü / Pore pair** | Teleporter | 3 Biofilm | links two pores; 3 s activation and cooldown | new pairing data + cooldown state | showcase image in version 3 |
| **Yapışqan ləkə / Sticky patch** | Slow tile | 1 or 3 | speed ×0.7 for microbes only; shots unaffected | a speed multiplier in movement | code decal (darker glossy floor patch) |
| **Axın zolağı / Current lane** | Fast tile | 2 or 3 | strong directional push along a lane; extends the existing current field | the current field gets a lane term | code (dense water motes along the lane) |

Bush coverage is the other BS lever (BS has 13% bush area; ours is 2.4–6.6%). It is a layout change in shared code, not an art task.

---

## 10. Comparison

Ratings are 1–5, where 5 is best (for "perf risk", 5 means the safest).

| | **1 Damla · Aqar** | **2 Sütun · Gölməçə** | **3 Mağara · Biofilm** | **4 Perspektiv · Aqar** |
|---|---|---|---|---|
| **Gap readability** (true footprint visible) | **5**: the art is exactly the footprint | 3.5: up to a 16 px north overlap; needs the ghost ring + x-ray | **5**: same as 1 | 3: oval dish, anisotropic movement, lift ≤ 0.14 R |
| **Microbe contrast on the floor** | 4: ≥ 4.3:1 on the mid floor | 3: 3.3:1 in the sunlit pool; warm floor near amber/gold microbes | **5**: ≥ 4.5:1 | 4: same as 1 |
| **Brawl Stars fidelity** | 3: south faces, light shadows, lifted swaying cover, destruction | **4**: plus raised walls and a Deep-Sea-like theme | 3: same technique as 1, richest theme | **5**: plus a tilted camera and a receding floor |
| **Perf risk** | **5**: environment calls about 20 → about 10; −1 to −2 screens of fill | 4: +2–3 calls, +0.3–0.5 screen; caustics on HIGH only (+1 screen) | 4.5: +1 call on HIGH (glow pools) | 4: 0 GPU, but code risk in input, camera and tests |
| **Implementation effort** | about 1 day of code + about 1–2 days of pipeline (shared by all versions) | 1 + about 2 days (cap split, ghost ring, x-ray, aim overlay, label z) | 1 + about 0.5 day | 1 + 2–4 days + its own art + test updates |
| **Rule changes** | none. Palette: new `BUSH`; shader policy optional | **ART_BIBLE §4b relaxed for caps** (owner) | none (new theme palette constants) | §4b + "the dish is round" identity + input mapping + `_test_aoi_covers_screen` |
| **Codex images** | 13 | 13 | 13 | 4 now (+3) |
| **Who it is for** | the safe ship | the owner who wants it to look like BS | a second environment at no rule cost | a "how far can 2D go" test |

---

## 11. Recommendation and run order

**Recommendation:**
1. **Ship version 1 (Damla · Aqar) as the base.** It needs no rule change, carries the lowest risk, fixes F1 (canopy under microbes) and halves environment draw calls. Every other version builds on its pipeline and juice.
2. **Use the themes like BS location themes, one per layout:** Halqalar = Aqar, Arxipelaq = Gölməçə, Spiral = Biofilm. One theme is loaded at a time (about 28 MiB on HIGH/LOW, about 8 MiB on MINIMUM). This answers "several versions" with variety players actually feel.
3. **Treat Sütun as a global A/B flag decided after a playtest on Arxipelaq.** That layout has the 57–155 px size-dependent gaps, the worst case for raised caps.
   - If approved: re-cut the Aqar and Biofilm MUCUS/BRITTLE cells in Sütun geometry, +6 images per theme.
   - If not: re-cut Gölməçə's six cells in Damla geometry, +6 images.
4. **Perspektiv:** show the mockup. Build the 1-day camera prototype with version 1's art only if the owner likes it. Otherwise drop it.
5. Independent of art and doable first (technique study §8): the F1 z-fix, the F3 annulus that replaces the two full-screen discs, and a re-measurement of the F2 modulate claim with `--perf`.

**Codex run order** (one version at a time, agents sequential; `codex exec --skip-git-repo-check -s workspace-write -m gpt-6-astra -c model_reasoning_effort=max -i ref/... < BRIEF`; raw output to `design/map_art/raw/vN/`, actual prompts to `brief/PROMPTS_MAP_VN.md`):

| Step | What | Images |
|---|---|---|
| 0 | Templates (§2) by code; refs: `world.png`, `world_solo.png`, `map0–2.png`, `hero_*.png`, `menu_bg.jpg` | 0 |
| 1 | Shared S1–S7 (not tied to any decision) | 7 |
| 2 | **Mockups 1–4, then the owner's review gate** | 4 |
| 3 | Version 1 kit (items 2–13), using the approved mockup as style anchor | 12 |
| 4 | Version 2 kit and/or version 3 kit, per the gate | 12 + 12 |
| 5 | Version 4 probe cells, only if its mockup and prototype pass | 3 |
| – | Optional showcase extras, one per version | ≤ 3 |
| **Total shipped** | | **≤ 53** (about 3× that in tries at worst) |

---

## 12. Decisions the owner must make
1. **§4b:** allow MUCUS and BRITTLE caps to rise up to 0.10 R / 16 px (versions 2 and 4)?
2. **Themes:** one theme per layout (recommended), or a single global theme?
3. **Shader policy:** allow two small `canvas_item` shaders on HIGH/LOW (floor macro × detail; canopy/cap hole)? Every version also works without them.
4. **Perspektiv:** prototype it, or drop it after seeing the mockup?
5. **`BUSH` colour:** move from `#4FCB72` to the per-theme muted greens above (hue 154–166°, V ≤ 0.62)? This is required by the technique study's saturation rule.
6. **Extras:** do any of the §9 tiles go on the gameplay roadmap? (Each is a sim change.)

**Files referenced:**
- `C:/Users/User/Desktop/Germ game V1/design/map_art/research/brawl_stars_research.md`
- `C:/Users/User/Desktop/Germ game V1/design/map_art/research/godot_25d_technique.md`
- `C:/Users/User/Desktop/Germ game V1/design/ART_BIBLE.md`
- `C:/Users/User/Desktop/Germ game V1/design/BRAWL_UPGRADE.md`
- `C:/Users/User/Desktop/Germ game V1/design/menu_art/brief/STYLE.md`
- `C:/Users/User/Desktop/Germ game V1/design/menu_art/brief/BRIEF_ENV.md`
- `C:/Users/User/Desktop/Germ game V1/design/menu_art/brief/BRIEF_AIM.md`
- `C:/Users/User/Desktop/Germ game V1/design/menu_art/README.md`
- `C:/Users/User/Desktop/Germ game V1/game/scripts/shared/palette.gd`
- `C:/Users/User/Desktop/Germ game V1/game/scripts/shared/dish_map.gd`
- `C:/Users/User/Desktop/Germ game V1/game/scripts/shared/constants.gd`
- `C:/Users/User/Desktop/Germ game V1/build/shots/world.png`, `world_solo.png`, `map0.png`, `map1.png`, `map2.png`
- `C:/Users/User/Desktop/Germ game V1/game/assets/menu/` (`menu_bg.jpg`, `menu_podium.png`, `hero_*.png`)

**Scratchpad files I created** (no project files were changed):
- `C:\Users\User\AppData\Local\Temp\claude\C--Users-User-Desktop-Germ-game-V1\5479a438-be68-4dd6-918e-3e73992da313\scratchpad\pal.js` (palette HSV and contrast check)
- `…\scratchpad\kinds.js` (radius ranges per obstacle kind)