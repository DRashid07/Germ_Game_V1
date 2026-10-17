# Germ Arena: technical feasibility of a Brawl Stars-style 2.5D interactive map

**Scope.** I read the code and docs the task listed. I checked the Godot facts against the 4.7.2 engine source and the official docs. Two things I measured: a captured game frame, and the obstacle gaps in all three layouts. I changed no project files. My only side effects are files in the session scratchpad.

---

## 0. Verdict

1. **Recommended base, "V1 Damla"** (approach A, pushed further). Four parts:
   - **Obstacles:** height stays baked inside the collision footprint. The visible side face moves to the **south** to suggest a camera tilt, and the light stays top-left. Today the face sits lower-right, driven by the light.
   - **Bushes:** canopies are lifted and drawn above the microbes. Bushes are passable, so lifting them costs no gap readability.
   - **Rim, "V3 Kasa":** the glass rim is drawn as a 2.5D bowl.
   - **Atlas and juice:** one texture atlas, plus the cheap interactive effects in §7.
   - **Cost:** no shaders required, environment draw calls drop from about 20 to about 10, and alpha-blended fill drops by 1–2 screens.
2. **Optional "V2 Sütun"** (approach B). MUCUS and BRITTLE tops are lifted above the footprint by **at most 0.10–0.14 R and at most 16 px**. It uses **two layers, without y-sort**, plus a footprint "ghost ring" and an x-ray outline of your own microbe. It breaks ART_BIBLE §4b, so it needs the user's decision.
3. **"V4 Perspektiv"** (approach C, squashing the world vertically) is **prototype only**. It needs a different art set, so it must be decided *before* Codex art is commissioned.
4. **Real 3D** (approach D) is **not viable here**. Codex produces images, not meshes. GermVisual (2,473 lines of procedural `_draw`) would have to be rewritten. It would also kill the planned 3D-less web template.

---

## 1. What the code does today: verified facts and findings

| # | Finding | Evidence |
|---|---|---|
| **F1 – bug** | **Bush canopies are drawn UNDER microbes, not over them.** `GermVisual` sets `z_index = 2 if is_local else 1`. The `_canopy` node and its sprites stay at z 0. Z-index sorts before tree order, so the "fronds pass over the microbe" intent in ART_BIBLE §4b never happens. `map_preview.gd` gives the top layer `z_index = 1`, which shows the intent. | `germ_visual.gd:730`, `arena.gd:621-623` and `728-742`. Confirmed in a captured frame (`--practice --at -95,640 --idle`): the fronds run *under* the microbe body. Files: `…\scratchpad\bush_check2.png`, `…\scratchpad\bush_zoom2.png` |
| **F2 – trap is stale** | README "Sprite-lara AYRI-AYRI modulate vermə" (line 1742) and the comment at `arena.gd:701` say per-sprite `modulate` breaks batching (131 → 242 calls). **Godot 4.7.2's GLES3 canvas renderer stores modulate per instance** (`instance_data_array[i].modulation = rect->modulate * base_color`). There is no batch-break condition on modulate. A new batch starts only on texture, material, blend mode, filter, repeat, clip owner or lighting state changes, and **on every polygon command** ("Polygon's can't be batched, so always create a new batch"). The 131 → 242 regression must have had another cause. Re-measure before relying on either claim. Until then, treat a modulate fade on 1–2 sprites as "≤ +2 calls in the worst case". | `drivers/gles3/rasterizer_canvas_gles3.cpp` @ `4.7.2-stable` |
| F3 | **Two invisible full-screen fills every frame.** `_draw` paints `draw_circle(r+600, BG_VIGNETTE)` and `draw_circle(r+260, BG_OUTER)`. Inside the dish both are covered by the floor, so they are two full-screen blended passes plus two calls. The clear colour is already `#071012` (= `BG_OUTER`). On MINIMUM, which README §5 shows is fill-bound, this is the cheapest win available. | `arena.gd:3894-3895`, `project.godot` |
| F4 | **Current art is low-density.** `dish_floor.svg` is 512² stretched over 2400 px, about 4.7 world px per texel. Obstacle SVGs are 320² with R_tex = 120, so an R = 150 obstacle has 0.8 texels per world px. That is about 2.4× magnification on a 1080p phone. All imports use `compress/mode=0` and `mipmaps=false`. | `.import` files |
| F5 | **Every `_draw` primitive is a separate draw call; sprites batch** (README 1721, confirmed in source). Environment calls today: `_draw` = 2 discs + floor + grid + 3 sediment arcs + 4 rim arcs = **11**, plus 3–4 in drying modes. Obstacles: up to 5 base textures, + 2 damaged crust, + 1 swirl, + 1 canopy = **≤ 9**. Motes: **2**. Total about **20–22**. | `arena.gd:3886-4057`, `655` |
| F6 | **Obstacle counts and sizes.** 26 / 35 / 31 obstacles (not 22–26), R from 34 to 150. 9 / 25 / 12 obstacles have R ≤ 60, so small obstacles are common. | `node …\scratchpad\gaps.js`, which reimplements `DishMap` |
| F7 | **Gap measurement** (blocking pairs and dish wall). See the table below. | same |
| F8 | **Screen input is already direction-only.** The joystick (`_hud.move_stick.value`), the aim drag (`fire_button.aim_dir`) and the keyboard give screen vectors. Nothing converts a screen point to a world point. Auto-aim, lock, claims and hit feedback all work in world space. `_view_rect` (`arena.gd:1742`) is the only screen-geometry dependency. | grep |

**Gaps between blocking obstacles (MUCUS/BRITTLE) and the dish wall.** "Amoeba-only" means passable only by the amoeba at the starting size: amoeba body 0.78 r = 43.7–56 px.

| Layout | Blocking / bush / vent | Closed for all (< 43.7 px) | Amoeba-only at base size | Size-dependent (56–171 px) | Blocking area | Bush area |
|---|---|---|---|---|---|---|
| 0 Halqalar | 14 / 9 / 3 | 0 | **0** | 8 (six 97 px wall gaps, 131, 145) | 5.9% | 6.6% |
| 1 Arxipelaq | 26 / 9 / 0 | 12 (core–pebble 40 px, 24 px) | **0** | 16 (57–155 px) | 8.5% | 2.6% |
| 2 Spiral | 21 / 10 / 0 | 3 + 3 overlaps | **0** | 9 (60 px wall, 88, 158) | 11.0% | 2.4% |

What this means:
- **No current gap is amoeba-only at the starting size.** But the dish is full of **size-dependent** gaps, because passability depends on both size and species.
  - Example: a 74 px gap (five of them in the Archipelago) admits a ciliate or heliozoan only up to **capacity 15**, and an amoeba up to **capacity 25**.
  - So "silhouette = collision footprint" matters for *every* species as they grow, not just the amoeba.
- **Brawl Stars comparison.** BS has blocking about 11% and bushes 13%, and its smallest gap is 2 tiles, about 140 px, which is about 2.5 brawler widths.
  - Our gaps of 22–158 px with no grid quantisation leave far less slack than BS has. That is the core argument for keeping V1 as the default.
  - Bush coverage (2.4–6.6%) is the lever if the user wants BS-like bush play.

---

## 2. Screen density, which drives the source resolution

Physical pixels per world pixel = camera zoom × stretch factor.
- Camera zoom `k` comes from `Const.camera_zoom_span`, which keeps the visible area constant: `k = sqrt(W_log·H_log / (span²·16/9))`.
- Logical size is 1280×720 at 16:9 and 1600×720 at 20:9. Span is 620 at the base size and 1080 at capacity 60 (r = 85.5).

| Device / tier | Stretch factor | k at base (16:9 / 20:9) | Phys px per world px at base | At max span |
|---|---|---|---|---|
| 1440p APK (HIGH/LOW) | 2.0 | 1.161 / 1.298 | **2.60** | 1.49 |
| 1080p APK (HIGH/LOW) | 1.5 | – / 1.298 | **1.95** | 1.12 |
| APK MINIMUM (VIEWPORT 1280×720) | 1.0 | 1.298 | 1.30 | 0.75 |
| Web LOW (DPR ≤ 2, 412 CSS px tall) | 1.14 | 1.298 | 1.48 | 0.85 |
| Web MINIMUM DPR 1.25 → auto floor 0.75 | 0.72 → 0.43 | 1.298 | 0.93 → 0.56 | 0.53 → **0.32** |
| Desktop 1280×720 | 1.0 | 1.161 | 1.16 | 0.67 |

**Resolution decision:**
- **L class** (R > 60): 512² cell with a footprint radius of 192 texels. At R = 150 that is 1.28 texels per world px (1.5× magnification on 1080p, 2.0× on 1440p); at R ≤ 96 it is at least 2.0, which is crisp. This is about 1.6× sharper than today's SVGs.
- **S class** (R ≤ 60): 256² cell with R_tex = 96. That gives 1.6–2.8 texels per world px.
- **Mipmaps are mandatory.** The worst-case minification is about 10× (an R = 34 obstacle from an L master on web MINIMUM at max span).
- **Texture size cap ≤ 2048** on any page. WebGL2 and GLES 3.0 only guarantee `MAX_TEXTURE_SIZE ≥ 2048`.

---

## 3. The four approaches

### A. Height baked inside the footprint (current approach, pushed further) → V1 "Damla"

**What changes visually**

| Element | Today | V1 |
|---|---|---|
| Top face (cap) position | shifted up-left (151,145 in 320 px canvas; light-driven) | shifted **straight up** by 0.10 R, radius 0.90 R |
| Visible side face | lower-right band, 22% R (light-driven) | **south** band, 0.20 R thick at south, 0.10 R at the sides, 0 at north |
| Light | top-left | unchanged: highlight and rim light from `LIGHT_DIR` |
| Shadow | baked in each SVG (offset about 0.30 R, alpha 0.44–0.48) | deterministic, made by the pipeline (§9), alpha ≤ 0.36 (BS uses ×0.75, i.e. 25% darker), plus a thin AO contact ring |

- This is exactly the BS split: light decides the *shadows*, the camera decides the *visible face*. It also agrees with the V3 rim, where the north inner wall shows, south of the same imaginary camera.
- MUCUS is a droplet or dome, and a low dome seen at about 20° tilt barely rises above its own footprint, so A is physically honest for this art style.

**Cost**
- 0 extra draw calls. With the atlas, all obstacle kinds drop from about 9 calls to 2 (§6).
- Fill is the same or lower than today (trimmed quads).
- CPU: 0.

**Code changes**
- `_spawn_obstacles`: `region_rect` (or `AtlasTexture`) instead of five textures; scale = `R / R_tex_cell`.
- `_apply_walls`: damage stages swap the region (no batch split, unlike today's +2).
- `_test_blob_textures` (`sim_test.gd:164`) must follow the new manifest.
- `map_preview.gd` uses the same choice function.

**Impact on other systems**
- No change to `germ_visual`, minimap, `aim_guide`, auto-aim or hit feedback.

**Effort and risk**
- About 1 day of code plus the art pipeline. Risk is low.

### B. Raised 2.5D props (top lifted above the footprint) → V2 "Sütun"

**What exactly breaks in "silhouette = collision footprint"**

Model each obstacle as an extruded cylinder:
- Footprint (collision) circle at (0,0) with radius R.
- Top circle at (0,−H) with radius R_cap.
- Lift above the north footprint edge: L = H + R_cap − R.
- Visible south face band = R − R_cap + H.

1. **North-side gaps shrink visually by L.** For two obstacles stacked north–south (the pair axis is mostly vertical in several measured gaps), the lower obstacle's cap hides its own north footprint edge. The visible gap is g − L.
   - Example: L = 12 px turns a 74 px gap into 62 px on screen. A 74 px gap is open to a capacity-15 ciliate, but 62 px looks closed to it.
2. **North-side contact is occluded.** A microbe touching an obstacle from the north has its lower L + 0.22 r hidden.
   - The amoeba is already drawn at its full r while its collision radius is 0.78 r, so it visually overlaps obstacles by 0.22 r even today.
   - For the largest obstacle (L = 15) and r = 28, that is 21 px of a 56 px body (37%).
3. **Bounces off the north side happen under the cap.** The aim line's bounce ring, the lock reticle and impact points at the footprint can sit underneath the lifted art.

**How Brawl Stars avoids the confusion.** The footprint is a whole tile, so collision is the *base*. All gaps are whole tiles, at least 2 tiles (≈ 140 px ≈ 2.5 brawler widths). Walls are low, so the head shows. Brawler collision (0.8 tile) is smaller than the visual. Players never judge pixel-exact gaps. **We have none of that slack** (F7), so B needs mitigations.

**The cheap design: two layers, no y-sort.**
- **Base layer** (current `_blobs`, below microbes): shadow + AO ring + side face, plus a dark "ghost footprint" disc with a crisp 2–3 px rim *exactly* on the collision circle. The rim becomes visible when the cap fades.
- **Cap layer** (z 3, above microbes at z 1/2, below FX at z 3 and juice at z 4 by tree order): top faces, plus bush canopies (this also fixes F1).
- Why it works without sorting:
  - A microbe north of an obstacle overlaps only its cap → drawn behind ✓.
  - A microbe south of it overlaps only the face band → drawn in front ✓, because the cap bottom (R_cap − H) is above the touching microbe's top.
  - **Exception:** an amoeba squeezing from the south when 0.22 r > R − R_cap + H − R… (simplified: r > 0.91 R for the L geometry, e.g. a big amoeba against a pebble). The wrong-order overlap is ≤ 6–7 px.
  - Overlapping obstacles (spiral arms overlap by up to 40 px): sort the cap layer **once, statically, by footprint y**. Obstacles never move.
- **Cost:** the cap layer is **+1 draw call** for all caps and canopies, because they share the atlas page. Fill adds about 0.3–0.5 screens if the cap regions are trimmed.

**Alternative: y-sort** (`y_sort_enabled` on one node holding the caps and all GermVisuals).
- Correct in every case, but:
  - Z-index beats y-sort, so the "own microbe z=2" rule must go. Keep it with a parent-offset trick: sort node at y + ε, visual child at −ε.
  - Each microbe interleaved between caps splits the cap batch: **up to +N visible microbes calls** (≈ +5–11 in a 10-microbe fight).
- Use it only if the two-layer artefact is noticed in play.

**Occlusion handling options in gl_compatibility**

| Option | How | Draw calls | GPU / CPU | Verdict |
|---|---|---|---|---|
| **X-ray outline of own microbe** (no shader) | Child Node2D of the local GermVisual, `z_as_relative=false`, z 5, `draw_polyline(ring, color@0.55, 2px)`, only while the microbe overlaps a cap (≤ 38 circle tests per frame) | +1 while active | trivial | **Recommended baseline** |
| **Footprint ghost ring** (no shader) | One `draw_multiline` of dashed footprint arcs for blocking obstacles within R + r + 60 px of your own microbe, alpha 0.35 | +1 while near | trivial | **Recommended** for V2 (the gap-reading fix) |
| Fade the one cap | `modulate.a` → 0.55 on 1–2 sprites (tween) | 0 per 4.7.2 source; ≤ +2 if F2 proves otherwise | trivial | OK |
| **Cap/canopy "hole" shader** (Zooba-style) | One ShaderMaterial on the cap layer. Varying `world = (MODEL_MATRIX*vec4(VERTEX,0,1)).xy`. `uniform vec3 hole` = own microbe x, y, r. `alpha *= mix(0.35, 1.0, smoothstep(1.0*r, 1.7*r, distance(world, hole.xy)))` | 0 (same material, still 1 batch) | about 6 ALU per cap fragment; needs a shader warm-up draw during countdown (WebGL compile hitch) | **Best look.** Optional, because BRAWL_UPGRADE §6 says "no shaders". User decision |
| CanvasGroup, BackBufferCopy, `hint_screen_texture` | Render children or the screen into the back buffer, then composite | +1–2 plus a render-target pass | A screen copy is about 1.15 M px read+write per use on Mali-G52 | **No.** Pays a screen copy for something the options above do for free. README already notes `clip_children` is unreliable on Compatibility |
| LightOccluder2D / 2D lights | Light occlusion, not sprite occlusion | per light | wrong tool | **No** |

**Required code changes for B**
- `arena.gd`: split obstacles into base and cap sprites; add a `_caps` node at z 3 before `_fx`; move the canopy there; wobble both sprites on hit.
- `germ_visual.gd`: name `Label` → `z_as_relative=false`, z ≈ 6, or caps hide the names of microbes standing behind obstacles. Add the x-ray child.
- `aim_guide.gd`: split the line (stays under microbes, as BS intends) from the overlay with bounce rings, the arrow and the lock reticle (z 3, after caps).
- **Untouched:** minimap, auto-aim (`_aim_targets` uses positions), `_clip_to_walls` and claims (collision circles), the server and sim.
- Impact FX at z 3 is drawn over caps, which is fine. Optionally nudge north-side impact FX upward by up to L.

**Mitigation limits**
- L ≤ 0.10 R (L class) or 0.14 R (S class), and ≤ 16 world px.
- Ghost ring and x-ray in all tiers. The hole shader is optional.
- Never lift the lateral (east/west) silhouette: caps shift only on −Y.

**Effort and risk**
- About 2 days of code on top of V1, plus cap art. Medium readability risk; must be playtested on a size-dependent gap (e.g. Archipelago 74 px).

### C. Pseudo-perspective (squash the world vertically) → V4 "Perspektiv"

**Mechanics**
- Free on the GPU: `Camera2D.zoom = Vector2(k, k·c)` with c = cos(tilt) ≈ 0.80–0.85. The dish becomes an ellipse.

**Changes needed**
1. Input:
   - Joystick, aim drag and keyboard need `world = Vector2(s.x, s.y / c).normalized()`.
   - This keeps the on-screen direction; screen speed becomes anisotropic (vertical 420 → about 344 px/s).
2. Camera: `_view_rect` must use `vp / (2·Vector2(k, k·c))`; motes span too.
3. Upright items must be counter-scaled by (1, 1/c) at their foot:
   - name labels and pop text (z 50 labels);
   - all obstacle art, which must be painted with **elliptical footprints of ratio c**, i.e. a *different asset set*.
4. Microbes must **not** be counter-scaled. They are flat cells; keeping them on the ground plane preserves gap reading, because the transform is affine.
5. The equal-area rule. Two options:
   - Keep k: you see 1/c ≈ +22% more world vertically. AOI still covers it: 21:9 half-diagonal 712 px vs AOI 837 px, margin 15%.
   - Use k/√c to keep the area: view width shrinks about 9%.
   - Either way `_test_aoi_covers_screen` must change.
6. **Unaffected:** the minimap stays top-down; aim-guide and drying-zone rings become ellipses automatically.

**Cost:** 0 draw calls and 0 GPU, about 2–4 days of code.

**Risk:** high on feel. Aiming and dodging feel changes, the round dish looks oval, the specular and cel shading of microbes get squashed, and the world-to-screen error surface widens.

**Worth it?** Not for the first art pass. Its main win (a receding floor) is about 70% achieved by V3's rim plus south-facing faces at zero risk. Run it as a branch prototype only. If adopted, commission the art in C geometry from the start.

### D. Real 3D (Node3D world, tilted Camera3D) → reference only

**What it would take**
- Floor and obstacles as MultiMeshInstance3D: 1 call per kind, matcap/unshaded shading (as BS does), blob-decal shadows on MINIMUM.
- Microbes kept as 2D: draw all of them into one shared atlas SubViewport (reusing GermVisual), shown as billboards. That is +1 render-target pass per frame, about 1 M px.
- Screen-to-ground mapping via `Camera3D.project_ray_*`; all FX, labels and markers reprojected.
- A 3D content pipeline (Blender). **Codex image_gen cannot make meshes.**

**Problems**
- Web startup already pays about 1.9 s of 3D shader compilation at 4× CPU slowdown (README). D makes the planned 3D-less web template impossible.
- Effort 3–6 weeks; very high risk on Mali-G52 and WebGL. **Rejected.**

### Summary matrix

| | Draw calls (environment) | Fill | VRAM | CPU | Effort | Risk | Breaks §4b? | Codex-compatible |
|---|---|---|---|---|---|---|---|---|
| A / V1 | about 20 → about 10 | −1 to −2 screens | +10–28 MiB (see §6) | 0 | low | low | no | yes |
| B / V2 (two-layer) | V1 + 1 (+1–2 overlays) | +0.3–0.5 screen over V1 | + caps (+5 MiB) | trivial | +2 days | medium | **yes** | yes |
| B with y-sort | V1 + up to N microbes | same | same | trivial sort | +3 days | medium | yes | yes |
| C | V1 + 0 | same | separate art set | trivial | +2–4 days | high | n/a | yes (new set) |
| D | MultiMesh plus RT | +1 RT pass | meshes | high | weeks | very high | n/a | **no** |

---

## 4. Drawing the dish rim in 2.5D ("V3 Kasa")

The camera is imagined south of the scene, looking north and down at about 70°. That matches V1's south-facing obstacle faces.

1. **Back wall (north inner glass face)**
   - Drawn **outward** from the foot line at r = 1200, over the dark outside, so it costs nothing in gameplay space.
   - Width W(θ) = 8 + 62·max(0, −sin θ)^1.5 px: 70 px at due north, 8 px at east and west.
   - One `Line2D`, closed, about 128 points, `width_curve`, `texture_mode = TILE`, using the tileable `rim_strip` texture. Alternatively a precomputed ArrayMesh in a MeshInstance2D. **1 call**, static.
   - In the base layer: above the floor, below microbes.
2. **Front lip (south)**
   - Drawn **inward** from r over the south half only: 6 + 22·max(0, sin θ)^1.5 px, so 28 px at due south.
   - Translucent glass: body alpha ≤ 0.35, bright edge highlight ≤ 3 px.
   - In the cap layer (above microbes). A microbe against the south wall reads "behind glass", like BS edge walls.
   - **1 call**.
3. **The rest**
   - These two replace the 4 rim `draw_arc` calls (net −2) and also carry the exact boundary line.
   - The drying-zone ring is unchanged; the glass does not move.
   - Outer vignette: replace the two full-screen discs (F3) with one **annulus mesh** from r to r + 600, using vertex colours `BG_OUTER → BG_VIGNETTE`. Fill happens only outside the dish. **1 call, −2 screens of fill.**

---

## 5. Floor: tileable or one big texture?

A single 2400 px texture at 1 texel per world px would be 2400² RGBA8 = **22 MiB**. That is too much. Use two layers instead:

- **Macro layer:** 1024² (2.34 world px per texel), opaque, no mipmaps (always magnified, ≥ 1.27 physical px per texel).
  - Contains the radial tone, painted agar zones, the outer fringe in `BG_OUTER`, and **the baked sediment bands** (−3 arc calls).
- **Detail layer:** a 512² seamless tile representing 400 world px (1.28 texels per px), with mipmaps and `texture_repeat = ENABLED`.
  - Contains agar grain, micro-bubbles, and optionally the faint 200 px grid with the 400 px bevel. Baking the grid saves the multiline call.
  - The rim fade can be painted into the macro layer.
- **How to draw them:**
  - **(a) Two sprites:** no shader, +1 full-screen blended pass.
  - **(b) One `canvas_item` shader** (`macro * mix(1, detail(world_uv), k)`): 1 pass, 1 call. This is the recommended path for HIGH/LOW.
  - **MINIMUM:** macro only (512²).

---

## 6. Atlas, batching, VRAM and import settings

**Batching rules** (4.7.2 source): one draw call per consecutive run with the same texture, material, filter, repeat, blend, clip and lighting. Polygons and meshes are always their own call. Therefore:
- **One atlas page holds every obstacle kind.** Base layer (bases + vent swirls + rubble decals) = 1 call. Cap layer (caps + canopies) = 1 call.
- Use `Sprite2D` with `region_rect`, or `AtlasTexture`; both resolve to the page's texture RID.
- Set `texture_filter = LINEAR_WITH_MIPMAPS` on the **parent** nodes so filters never differ inside a run.
- Use **trimmed regions**: the pipeline stores each cell's tight alpha bounding box plus a pivot `offset`. Quads rasterise transparent pixels too, so trimming saves 30–40% fill on caps.
- Cells are aligned to the 512 / 256 grid, so box-filter mips never mix neighbours. Keep the outer 12 texels (L) or 6 texels (S) at alpha 0 for bilinear sampling at lower mips.

**Indicative layout and VRAM** (RGBA8 lossless, mipmaps ×4/3). Only one theme is loaded at a time.

| Texture | Contents | HIGH / LOW | MINIMUM (half-resolution copy) |
|---|---|---|---|
| `page_obstacles` 2048² | L: MUCUS blob/bloom (base + cap), BRITTLE base + 3 caps (stages) + rubble, BUSH base + canopy, VENT base + swirl; S quadrant: the same in 256 cells | 21.3 MiB (V1-only: 2048×1536 = 16 MiB) | 1024²: 5.3 MiB |
| `page_env` 1024² | clutter ×4, props 2 × 3 frames, debris chunks ×4, ripple, telegraph, splash | 5.3 | 512²: 1.3 |
| `floor_macro` 1024² | §5 | 4.0 (no mips) | 512²: 1.0 |
| `floor_detail` 512² tile | §5 | 1.3 | 256² or off: 0.3 |
| `rim_strip` 1024×256 + `lip_strip` 1024×128 | §4 | 2.0 | 0.5 |
| **Total** | | **≈ 34 MiB** (V1-only ≈ 28) | **≈ 8.4 MiB** |

- **Context.** The game uses 42–54 MB total today. Phones with ≤ 3 GB RAM already auto-select MINIMUM (README "Brauzerdə donma" §4), so the 2 GB tier only ever loads the about 8 MiB set. Pick the set at match start; a quality change mid-match takes effect next match.
- **Import settings**
  - Atlas pages: `compress/mode=0` (Lossless), `mipmaps/generate=true`, `process/fix_alpha_border=true` (Codex PNGs often have black RGB under alpha 0).
  - Floor macro: no mipmaps.
- **Web compression**
  - VRAM Compressed means S3TC on desktop and ETC2 on mobile (BPTC/ASTC "high quality" is not available on Compatibility). It would cut the obstacle page to 5.3 MiB.
  - Downsides: the docs advise against it for 2D, there is a banding risk on dark teal gradients, and web exports must enable both "For Desktop" and "For Mobile" (a bigger pck).
  - Recommendation: test ETC2 on the obstacle page only, as an A/B, after the lossless version ships.
- **Free win, independent of 2.5D:** today's SVGs can be re-imported at `svg/scale=2.0` (640², about 1.6 MiB each) for 2× sharpness at no art cost.

---

## 7. Interactive juice, cheapest first

| # | Effect | Implementation | Calls | HIGH | LOW | MINIMUM |
|---|---|---|---|---|---|---|
| 1 | **Canopy above microbes** (fixes F1) | `_canopy.z_index = 3`, placed before `_fx` | 0 | ✓ | ✓ | ✓ |
| 2 | Bush sway + rustle | Existing per-node rotation and skew. Phase is seeded by index; better seeded by position (`x*0.013 + y*0.021`, as the vents do) | 0 | ✓ | ✓ | ✓ (sway amplitude ×0.5) |
| 3 | Lifted canopy (0.15–0.20 R) | art (§9) | 0 | ✓ | ✓ | ✓ |
| 4 | See-through ring in bush or cap | Hole shader (§3B), or `modulate.a` 0.55 on the one canopy | 0 | shader | shader or modulate | modulate |
| 5 | Fronds part around your microbe | Same shader: radial UV push `uv += normalize(w-hole)*amp*falloff`; needs ≥ 4% cell padding | 0 | ✓ | – | – |
| 6 | Hit wobble (MUCUS bounce, BRITTLE hit) | Tween scale 1 → 1.04 → 0.98 → 1 over 160 ms on the base (and cap) sprites. Bounce point taken from predicted or remote shot direction changes near an obstacle | 0 | ✓ | ✓ | ✓ |
| 7 | BRITTLE stages 0/1/2 → break | Region swap (0 batch splits); on break, base region → `rubble` decal, cap hidden. Debris: existing JuiceFx debris (6/12 → 3/6) + 4 chunk sprites from `page_env` | 0 (+1 while chunks fly) | ✓ | chunks ×0.5 | JuiceFx only |
| 8 | Ripples (shot lands, bounces or expires; microbe dash or stop; food absorbed) | Add a ring type to **JuiceFx** (its existing ≤ 3 multiline groups) | 0 | ≤ 12 live | ≤ 6, impacts only | off |
| 9 | Vent swirl | Existing; move into the atlas so it merges with the base batch | −1 | ✓ | ✓ | ✓ |
| 10 | Ambient animated props (outside the dish only) | 2–3 atlas frames, region swap every 180–350 ms on one timer (BS `AnimateSwitchBetween`) | +1 (`page_env`) | ✓ | static | hidden |
| 11 | Ground telegraph rings (future dish events) | JuiceFx ring or a `page_env` sprite | 0–1 | ✓ | ✓ | ✓ |
| 12 | Cosmetic floor clutter that pops when a shot crosses it (BS `D`) | Client-only, deterministic from the layout seed; flat, no outline, max channel ≤ 0.45 so it never reads as an obstacle | +1 | ✓ | static | hidden |
| 13 | Rustle only for visible microbes | Already correct (`_watch_visible_bush` runs only on sent microbes, so no information leak) | – | – | – | – |
| 14 | Perspective lean of canopies (tops slide outward from the screen centre by ≤ 0.08 R) | Per-frame position on ≤ 10 visible canopies; never on blocking caps | 0 | ✓ | – | – |

All CPU additions are loops over ≤ 38 obstacles or ≤ 10 canopies, well under 0.1 ms. Any shader needs a warm-up draw during the countdown, because the README notes shader-load spikes on the web.

---

## 8. Recommendation and the "several versions"

**Technique versions**

| Version | Contents | Status |
|---|---|---|
| **V1 Damla** | A + lifted bush canopy + V3 rim + atlas + §7 items 1–3, 6–9 | **Build first.** Zero shaders; environment calls about 20 → about 10; −1 to −2 screens of fill |
| **V2 Sütun** | V1 + MUCUS/BRITTLE caps lifted L ≤ 0.10–0.14 R (≤ 16 px), two layers, ghost ring, x-ray, overlay split in `aim_guide` | Ask the user (breaks §4b). Ship behind a flag and playtest on the 74 px Archipelago gaps |
| V3 Kasa | the rim (§4) | Part of V1 and V2 |
| V4 Perspektiv | C | Branch prototype only; separate art |
| V5 3D | D | Rejected |

**Theme versions** (orthogonal to technique, BS-style reskins of identical footprints):
- T1 Agar Lab (current teal) and one contrast theme first, then T2–T5.
- T3 Pond Drop is the closest to BS "Deep Sea", which used jellyfish walls, bubbler clutter and a seaweed sway shader.
- Each theme is one `page_obstacles` + one `page_env` + floor + rim set built from the template below.

**Recommended order**
1. F1 z-fix and F3 vignette annulus. Minutes, measurable.
2. Re-measure the F2 modulate claim with `--perf`.
3. Pipeline (`process.gd` modes `obstacle` and `atlas`).
4. T1-V1 art → atlas code → rim → floor.
5. Juice.
6. V2 caps as an A/B.

After each step run the perf command and `--simtest` from BRAWL_UPGRADE §5 (the peak must stay ≤ 350 draw calls), and update `_test_blob_textures` to assert that every kind has a cell in both size classes.

---

## 9. Asset technical spec template (Codex must follow it)

### 9.1 Global constants, the same for every asset

| Parameter | Value |
|---|---|
| **Projection** | Top-down plan view with oblique height. The floor plane is drawn as an exact top view: circles stay circles, no foreshortening, no vanishing points (orthographic). Height projects **straight up the screen (−Y)** at 0.35 px per px of height (camera tilt about 20°, elevation about 70°). Side faces are visible **only on the south half**. *(V4 Perspektiv would instead use elevation 55° with footprint ellipses of ratio 0.82; not part of this template.)* |
| **Light** | One key light from the upper-left, toward `LIGHT_DIR = (−0.45, −0.89)`, which is 27° left of straight up ("11 o'clock"), elevation about 50°. Specular highlight centred at `LIGHT_DIR · 0.45 R` from the cap centre. Shading darkens toward lower-right. Optional thin rim light, ≤ 2% R, on the lower-right edge. |
| **Shadows** | **Not painted by Codex.** Generated by the pipeline from the silhouette mask (§9.4). Codex leaves the floor around the object empty and transparent. |
| **Generation canvas** | 1024×1024 RGBA, real alpha (`Format32bppArgb`, corner alpha 0, no painted checkerboard). Fallback: flat `#FF00FF` background with no magenta in the subject; `process.gd key` removes it. |
| **Registration** | Footprint (collision) circle centred at (512, 512), **radius 384 px** (0.375 of the canvas). A guide image `ref/template_<version>_<class>.png` (footprint, cap circle, face band, light arrow) is given with `-i`; the guides must not appear in the output. The pipeline fits and masks (§9.4). Reject if the fit residual is > 2% R. |
| **Delivered cell** | L class (R > 60): **512²**, footprint radius 192 texels. S class (R ≤ 60): **256²**, footprint radius 96. Pivot = cell centre = footprint centre. Every layer of one obstacle (base, cap, stages) uses the identical cell geometry and pivot. In game: `scale = R / R_tex`. |
| **Padding** | Outer 12 texels (L) or 6 texels (S) at alpha 0. Art may leave the footprint circle only upward (lift, §9.2) and, for the pipeline shadow, toward lower-right. |
| **Outline** | Dark `#081A20` (or `#04090B` at 80%), deliberately weaker than the microbes' `#04090B`. Outer silhouette stroke **3.5% R** (L) or **6% R** (S), re-stroked by the pipeline on the exact mask. Inner form lines (cap edge to face) are Codex's own, about 60% of that width. Passable kinds have **no outer outline** (rule language from ART_BIBLE §4: solid = continuous outline, bush = none, vent = broken). |
| **Value and glow** | Non-emissive pixels: max(R,G,B) ≤ **0.58**. HIGH glow has a threshold of 0.62, and only living things may bloom. Emissive accents (BRITTLE crack cores, VENT lip and swirl, bioluminescent dots) ≥ 0.85, covering ≤ 3% of the opaque area. |
| **Saturation** | No environment pixel near a microbe colour at full saturation (S ≥ 0.75 with V ≥ 0.85 in the hues of the 10 `GERM_COLORS` or `ALLY #A6FF4D`). The only exception is VENT/BRITTLE amber (`#D09345`–`#F0B94E`). **BUSH hue 140–165°, S 0.40–0.60, V ≤ 0.62**: today's `#4FCB72` sits too close to lime `7CFF5B`, mint `4BFFA5` and the ally lime. |
| **Detail scale** | No feature smaller than 2% of the canvas (L) or 4% (S), so it survives downsampling and mipmapping. |
| **Material** | Soft, wet, gelatinous, bioluminescent petri world. No hard corners, metal, lab equipment, text or faces. |

### 9.2 Per-kind geometry (units of R = footprint radius)

**V1 "Damla"** (lift = 0)

| Kind | Cap (top face) | South face band | Lift above footprint | Outline | Shadow (pipeline) | Layers and cells |
|---|---|---|---|---|---|---|
| MUCUS | circle centre (0, −0.10R), radius 0.90R, lit | 0.20R at south, 0.10R at the sides, 0 at north; darker, darkest lower-right | 0 | yes | mask × (1.05, 0.80), offset (+0.11R, +0.22R), core alpha 0.36 → 0, blur σ 0.06R; AO band 0.04R outside the footprint at alpha 0.28 | 1 cell per variant: **blob** (smooth) and **bloom** (granular) × L and S |
| BRITTLE | same as MUCUS, with an amber-cracked shell | same | 0 | yes | same | stages 0 / 1 / 2 hits with crack coverage 15% / 35% / 60% of the cap. Stage 2 chips are ≤ 0.06R deep and *inside* the silhouette (collision unchanged). Plus **rubble** decal: flat, no outline, radius ≤ 0.9R, max channel ≤ 0.45, alpha ≤ 0.8. L and S |
| BUSH | **base:** flat soft mat, radius 0.95R. **canopy:** frond mass centred (0, −0.15R), fronds to 1.0R sideways, top to −1.15R; **hollow centre** (radius 0.35R, ≤ 30% coverage) | none | canopy 0.15R (passable, allowed) | **no** | none; AO only, alpha 0.20 | base + canopy, L and S |
| VENT | negative height: lip exactly on the footprint. Inner wall band 0.18R at north tapering to 0.04R at south. Upper-left inner wall in shadow, lower-right lit (ART_BIBLE §4b) | – | 0 | broken outline | none | **base**, plus **swirl**: rotationally neutral (no directional light; it rotates), radius 0.70R, amber arms ≥ 0.85, alpha ≤ 0.7. S (L optional) |

**V2 "Sütun"** (MUCUS and BRITTLE only; BUSH and VENT as in V1)

| | L class | S class |
|---|---|---|
| Cap centre (0, −H) | H = 0.18R | H = 0.22R |
| Cap radius | 0.92R | 0.92R |
| **Lift L = H + R_cap − R** | **0.10R** (≤ 16 px at R = 150) | **0.14R** |
| South face band | 0.26R | 0.30R |
| Shadow offset | (+0.14R, +0.27R) | same |
| Split | Codex paints one complete obstacle. The pipeline cuts the **cap cell** (inside the cap circle) and the **base cell** (face + shadow + AO + **ghost footprint disc** with a crisp 2–3 px rim exactly on the collision circle, revealed when the cap fades) | same |

### 9.3 Stages, frames, variants, file names

- **Damage stages:** one row per obstacle, left to right `s0, s1, s2, rubble`, same pivot. In V2 only the cap changes per stage; the base is shared.
- **Animated props:** 3 frames left to right, same pivot, looped or ping-pong at 180–350 ms. Placed outside the dish rim only.
- **Debris:** 4 chunks in one 256 cell (2 × 2 of 128), each centred, with no baked shadow.
- **Shipped variants:** MUCUS 2 (blob, bloom); BRITTLE 1 design × 3 stages + rubble; BUSH 1 (base + canopy); VENT 1 (base + swirl). Each in L and S.
  - ART_BIBLE §4: only MUCUS gets variants; the others are rules, not decoration.
  - **Codex makes 3 candidates per slot; 1 ships (2 for MUCUS).**
- **Environment per theme:**
  - `floor_macro` 1024² (opaque, dish disc + `BG_OUTER` fringe, sediment bands baked, mid-to-low value, max channel ≤ 0.35);
  - `floor_detail` 512² seamless (= 400 world px, low contrast ±6% value);
  - `rim_strip` 1024×256 seamless horizontally (north inner glass wall, foot line at the bottom edge);
  - `lip_strip` 1024×128 seamless (south translucent lip, highlight on the top edge);
  - `page_env` items: ripple ring, telegraph ring and splash in **white or neutral grey** (tinted by `modulate`, max |R−G|, |G−B|, |R−B| < 24), clutter ×4, props 2 × 3.
- **Naming:** `<theme>_<kind>_<variant>_<layer>_<class>.png`, e.g. `t1_mucus_bloom_cap_L.png`, `t1_brittle_s2_cap_S.png`, `t1_bush_canopy_L.png`.

### 9.4 Pipeline (GDScript `process.gd`; no Python)

1. **Verify (PowerShell, System.Drawing):** `Format32bppArgb`; alpha 0 at (8,8), (w−8, h−8) and every corner 64×64 block; 99th percentile of max(R,G,B) over non-emissive opaque pixels ≤ 0.60; no checkerboard pattern.
2. **Fit:** measure the painted base silhouette (centroid and radius of the lower-half alpha edge), affine-fit it to the footprint circle, reject if the residual is > 2% R.
3. **Mask** to the allowed silhouette: footprint plus the per-version upward lift region.
4. **Outline:** re-stroke the outer edge at the exact width.
5. **Shadow:** generate it from the mask with the §9.2 numbers and composite it under the art in the base cell.
6. **Split** cap and base (V2).
7. **Downsample** 1024 → 512 (L) or 256 (S) with a box or Lanczos filter.
8. **Pack** the atlas page and write a `manifest.json` (cell rect, tight bbox, pivot offset, R_tex, kind, stage, class) that the game reads.

---

## 10. Open decisions for the user

1. **V2 lift:** allow MUCUS/BRITTLE tops above the footprint (L ≤ 0.10–0.14 R, ≤ 16 px)? Today's ART_BIBLE §4b forbids it. Bush lift is safe either way.
2. **Shader policy:** BRAWL_UPGRADE §6 says "no shaders". Allow two small `canvas_item` shaders (floor macro × detail; cap/canopy hole) on HIGH/LOW? V1 and V2 also work without them.
3. **Bush coverage and colour:** raise bush area toward BS levels (13% vs our 2.4–6.6%)? This is a layout change in shared code, so the server changes too. Move `BUSH` away from microbe lime/mint?
4. **Perspective prototype (C):** run it before art is commissioned, or drop it?

---

**Files I created** (scratchpad only, no project edits):
- `C:\Users\User\AppData\Local\Temp\claude\C--Users-User-Desktop-Germ-game-V1\5479a438-be68-4dd6-918e-3e73992da313\scratchpad\gaps.js` (gap and coverage analysis)
- `…\scratchpad\bush_check.png`, `…\scratchpad\bush_check2.png`, `…\scratchpad\bush_zoom2.png` (F1 evidence)

**Project files referenced:**
- `C:\Users\User\Desktop\Germ game V1\game\scripts\client\arena.gd` (lines 566-755, 878-899, 1719-1774, 1842-1877, 3886-4057)
- `C:\Users\User\Desktop\Germ game V1\game\scripts\client\germ_visual.gd` (730, 1405-1413)
- `C:\Users\User\Desktop\Germ game V1\game\scripts\client\aim_guide.gd`
- `C:\Users\User\Desktop\Germ game V1\game\scripts\client\minimap.gd`
- `C:\Users\User\Desktop\Germ game V1\game\scripts\shared\dish_map.gd`
- `C:\Users\User\Desktop\Germ game V1\game\scripts\shared\constants.gd` (8-48, 912-935)
- `C:\Users\User\Desktop\Germ game V1\game\scripts\tools\sim_test.gd` (164)
- `C:\Users\User\Desktop\Germ game V1\README.md` (1721, 1742)
- `C:\Users\User\Desktop\Germ game V1\design\ART_BIBLE.md` (§4b, §8)
- `C:\Users\User\Desktop\Germ game V1\design\BRAWL_UPGRADE.md` (§1, §6)

**Sources:**
- [Godot GLES3 canvas renderer @4.7.2-stable](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp)
- [CanvasItem docs (y_sort, z_index)](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html)
- [CanvasGroup docs](https://docs.godotengine.org/en/stable/classes/class_canvasgroup.html)
- [canvas_item shader reference](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html)
- [Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Renderers overview](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- [Godot 4.4 release (batching in all renderers)](https://godotengine.org/releases/4.4/)