# Brawl Stars maps: research report for a 2.5D petri-dish arena in Germ Arena

## 0. Method and how much to trust each claim

Brawl Stars from here on is "BS". Every claim carries one of these tags:

- **[official]**: Supercell blog, release notes, or a Supercell article.
- **[datamine]**: game files from client v69.230, taken from the community repo `tailsjs/brawl-stars-assets` (commit cc307ff). I read these CSV and shader files:
  - `csv_logic/tiles.csv`, `location_themes.csv`, `maps.csv`, `globals.csv`, `characters.csv`
  - `csv_client/location_features.csv`
  - `shader/plants.vsh`, `seaweed.vsh`, `uber.fsh`, `ghost.fsh`, `impostor_outline.fsh`
  - The data is real. **What a column means is my reading** where marked [interp].
  - Base URL: https://github.com/tailsjs/brawl-stars-assets/tree/master/69.230
- **[wiki]**: community wikis or guides. The BS Fandom wiki returned HTTP 402 to every fetch, including through mirrors. Fandom facts therefore come from search-result excerpts of brawlstars.fandom.com.
- **[observed / unverified]**: my own knowledge of how the game looks, with no primary source found.

Two blocked or suspicious sources:
- The Medium articles (the Zooba bush-rendering article and a BS UX analysis) were blocked.
- https://tcrf.net/Squad_Busters returned text addressed to AI tools instead of real content. I ignored it and used nothing from it.

**Scale for translating to Germ Arena** [datamine]: in BS, 1 tile = 300 units and a standard brawler's collision radius is 120 units, so a brawler is 0.8 tile wide. Our `BASE_RADIUS` is 28 px, which gives **1 BS tile ≈ 70 px**. All "≈ px" numbers below use this.

---

## 1. Camera and projection

- **True 3D.** BS runs on Supercell's own Titan engine and loads 3D models, animation and effects as assets [official, https://supercell.com/en/news/titan-game-engine/]. The game moved "from 2D to 3D" during soft launch [https://en.wikipedia.org/wiki/Brawl_Stars].
  - In the datamine, every tile, wall, bush and background is a `.glb` mesh (`sc3d/mine_wall1_geo.glb`, `bgr_mine_ground_geo.glb`, ...).
  - The shaders use projection and view matrices and support real-time shadow maps.
- **Perspective, not orthographic.**
  - Players notice that block sides show near the left and right screen edges [https://forum.godotengine.org/t/how-to-get-camera-perspective-view-like-brawl-stars/23689].
  - A community recreation uses a narrow FOV of about 15° and a pitch of about 60° down, with the camera placed far away, so vertical edges stay almost parallel [same thread; **unverified approximation**, no datamined camera value found].
  - Geometry at a 55–60° pitch: a cube's front face shows at about 0.5–0.57 of its height, and the floor is squashed vertically to about 0.82–0.87 [my derivation].
- **Orientation history.**
  - Soft launch was portrait. The game moved to landscape and joystick controls in late 2017 / early 2018.
  - Deconstructor of Fun quotes the team: "Our decision was not portrait to landscape. Our decision was landscape or kill." [https://www.deconstructoroffun.com/blog/2018/5/11/bs].
  - In the March 2018 balance update the camera moved further out and all characters got bigger to compensate [https://toucharcade.com/2018/03/21/brawl-stars-landscape-balance-update-attempts-to-improve-long-range-brawlers/].
- **How much of a map you see.**
  - In landscape, the whole width of a 3v3 map is on screen, and the community complained it was too zoomed out [https://toucharcade.com/2018/03/13/brawl-stars-landscape-update-angers-community/]. The camera therefore mainly scrolls along the long axis.
  - In Showdown (60×60) it follows the player on both axes [observed].
  - Each team sees the map flipped so its own side is at the bottom [wiki excerpt, Fandom forum "End screen scoreboard" thread].
- **Asymmetric view box** [datamine `globals.csv`]: `VISIBILITY_X 43`, `VISIBILITY_UP 33`, `VISIBILITY_DOWN 28`, plus margins of 6/18/26.
  - The view reaches further ahead (up) than behind.
  - Units are not confirmed. If they are range units (3 per tile), the box is about 28.7 tiles wide, 11 tiles ahead and 9.3 behind. That fits "the whole 21-tile width plus margins" [interp].
- **Germ Arena comparison:**
  - BS shows at least 21 tiles of width, ≈ 1470 px in our units.
  - Our base view is about 620 px tall × about 1100 px wide, so we are about 25–35% tighter than BS.

## 2. Grid and dimensions

All of this is [datamine] from `location_themes.csv` (MapWidth/MapHeight) and a parse of all 1048 layouts in `maps.csv`:

| Mode | Tiles | ≈ px at 70 px/tile | Count in maps.csv |
|---|---|---|---|
| Gem Grab, Brawl Ball, Heist, Bounty, Hot Zone, Knockout, Payload, etc. | **21 × 33** | 1470 × 2310 | 710 maps |
| Showdown (solo/duo/trio), big 5v5 "island" maps | **60 × 60** | 4200 × 4200 | 311 |
| Siege (and one CTF map) | **27 × 39** | 1890 × 2730 | 20 |
| Tutorial, training, co-op, 2 old Gem Grab maps | 17 × 33 | — | 6 |

- **Germ Arena comparison:** our dish is 2400 px across. That is about 34 tiles, roughly the length of a 3v3 map.
  - By area, the dish is about 1.3× a 3v3 map and about ¼ of a Showdown map.
- **Map strings** use one character per tile [datamine `tiles.csv`]: `.` open, `M`/`X` wall 1/2, `Y` crate, `C` barrel, `F` bush, `W` water, `N` fence, `a` rope fence, `B` fragile, `T` themed, `I` indestructible, `J` invisible indestructible, `E` indestructible fence, `D` destructible deco, `x` damage, `z` slow, `w` fast, `S` snow, `q` ice, `o` bouncer, `=` empty.
- **What the maps are made of**, as average share of tiles [datamine, my count]:

| Tile class | 3v3 (710 maps) | Showdown (311 maps) |
|---|---|---|
| Open floor | 66.9% | 49.7% |
| Bush | 13.0% | 10.3% |
| Blocking (walls, crates, barrels, fences, fragile, themed, indestructible) | ≈ 11.3% | ≈ 12.4% |
| Invisible border (`J`) | 4.4% | — |
| Water | 2.5% | **23%** |

  In Showdown, water is mostly the island border.
- **Map Maker rules** [https://en.androidayuda.com/games/Tutorials/brawl-stars-map-creator/]:
  - No 1-tile-wide paths. Two tiles is the minimum spacing, about 140 px for us.
  - No diagonal-only gaps between walls, no fully enclosed areas, and gem spawners and goals may not be blocked.
  - Unlocks at 1000 trophies; up to 5 saved maps.
  - Maps can be published and go through Draft → Submitted → Greenlit → Published, with >50% approval needed from 10 votes [official, https://supercell.com/en/games/brawlstars/blog/release-notes/snowtel-update-patch-notes-1/].
  - A mirror tool encourages symmetric 3v3 maps.
- **Map Maker tile catalogue** [datamine, tiles with `MapEditorVisible=true`]:
  - Terrain: open, wall 1, wall 2, crate, barrel, destructible deco, bush, water, themed, fragile, fence, rope fence.
  - Spawns: spawn points 1/2, respawn points 1/2, power-cube crate, base.
  - Devices: springboard (jump pad), teleporters 1–4, siege bolt.
  - Floor effects: damage, healing, slow, fast, interval damage.
  - Not in the editor (official maps or modifiers only): indestructible, respawning bush, bouncer, snow, ice, indestructible fence, Damageable 1–4, gravity pull/push.

## 3. How the 2.5D look is built

- **Walls and props** are low 3D meshes standing on a one-tile footprint, roughly cube- or rock-shaped. The camera tilt shows a **lit top face and a darker front (south) face** [observed].
  - Side faces appear only toward the screen edges, because of perspective [Godot thread above].
  - I found no evidence of ink outlines on walls. Edges come from the value step between the top and front faces [observed / unverified].
  - Walls are low enough that a brawler's head usually stays visible behind one tile of wall [observed / unverified].
- **Lighting is a matcap ("lit sphere"), not a scene light** [datamine shaders].
  - The main shader (`uber`, its general-purpose shader) builds a texture coordinate from the view-space normal and reads a "lightmap" texture with it. The textures are named `cartoon_diffuse_lightmap.png`, `cartoon_specular_lightmap.png`, `virus`, `tentacles_goo`, `pink_liquid`, and so on.
  - The light is therefore fixed relative to the camera, so every object, at any rotation, is lit from the same screen direction [interp].
  - **This is why BS can rotate wall models at random:** `Wall1AngleStep` is 90° for 87 themes, 180° for 11 and 0° for 16. Rotation adds variety without moving the light.
  - We bake light into sprites, so we cannot do this. ART_BIBLE §4b already learned this the hard way; bake light-consistent variants instead.
- **Shadows are light.**
  - With shadow maps on, a shadowed pixel is multiplied by **0.75**, which is only 25% darker [datamine `uber.fsh`].
  - Every tile also carries planar "fake shadow" parameters [datamine `tiles.csv`]: `ShadowScaleX 100`, `ShadowScaleY 60`, `ShadowX -10`, `ShadowY 60`, `ShadowSkew 25`. Fences use `ShadowY 30`. Characters use 80/80 with skew 35.
  - [interp] The shadow is the object's own silhouette, squashed to 60% height, sheared and pushed down. Fences cast a shadow about half as long, so they are about half wall height.
  - This ports directly to 2D sprites.
- **Floor.** Each environment has one ground mesh (`bgr_<theme>_ground_geo.glb`) plus one surrounding "environment" mesh for the set dressing [datamine].
  - Most floors show a faint 1-tile pattern, and players count tiles to judge range [observed; a "tile measurements" wiki says ranges are counted in whole, half and third tiles: https://brawl-stars-accurate-tile-measurements.fandom.com/wiki/Brawl_Stars_Accurate_Tile_Measurements_Wiki].
- **Bushes:**
  - Each tuft is a mesh that sways in the vertex shader [datamine `plants.vsh`]. The sway grows with the vertex's height above the ground, and its phase comes from world position, so neighbouring tufts never move together.
  - An underwater variant (`seaweed.vsh`) sways faster on two frequencies, with amplitude about 7.5% of height.
  - Bush tiles have `HasWindAnim` and `HasHitAnim` set [datamine]; the hit animation's exact trigger is unverified.
  - When you hide in a bush, your own brawler turns translucent [guide excerpt].
  - Enemies hidden in bushes become visible within about **2 tiles** (≈ 140 px for us), and attacking reveals the attacker [wiki excerpt, pro-brawl-stars-tipsntricks.fandom.com/wiki/Bushes].
  - Bushes are drawn with a sort offset of -1 [datamine], so they render under nearby objects.
- **Team colours** [wiki excerpt, https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/BrawlStars]:
  - Your own brawler and health bar are green, allies and their attacks blue, enemies and their attacks red.
  - Characters have a ground "floor indicator" (`FloorIndicatorScale` column [datamine]), and health bars have separate player, team and enemy badges [datamine `health_bars.csv`].
- **Unexplained "ghost" shader** [datamine `ghost.fsh`]: a cyan-white rim (fresnel) shader. Its use (invisibility, x-ray, props) is **unverified**.
  - I found no proof that BS outlines brawlers through walls. The likely reason is that its walls are simply low.
- **Map edge and outside decor:**
  - On 3v3 maps, invisible indestructible tiles (`J`, 4.4% of tiles) cut the playable shape. A themed environment mesh fills the outside: Mine has mine carts and track lights (`bgr_mine_cart_*`, `bgr_mine_tracks_1_lights_geo.glb`) [datamine].
  - Showdown maps are islands framed by water plus indestructible fences.
  - Some themes show a resident brawler NPC in the scenery that is **hidden if that brawler is in the match** (`HideIfCharacter`, 39 entries, e.g. Tara and Sandy at the Bazaar) [datamine `location_features.csv`].
- **Spawns and mode objects:**
  - Spawn and respawn points are plain tiles.
  - Per-theme overrides exist for the Gem Grab gem-mine model, the spawn hole, the Brawl Ball goals, the Heist safe and the Showdown power-cube box [datamine `location_themes.csv`].

## 4. Tile types and rules

All [datamine `tiles.csv`] unless marked otherwise:

| Tile | Blocks move | Blocks shots | How it breaks | Notes |
|---|---|---|---|---|
| Wall1/Wall2, Crate, Barrel, Themed | yes | yes | by supers or Overtime | `HasHitAnim` (reacts when shot); per-theme break effect (`wall1_explo` …) |
| Fragile (`B`) | yes | yes | **by normal attacks** | per theme: bone pile, vase, candles, traffic cone, snow lantern, cannonballs, beehive |
| DecoDestructible / clutter (`D`) | no | no | normal attacks | walk-through floor decor that pops when shot (pothole, bone, seaweed, bubbler) |
| Indestructible (`I`), IndestructibleFence (`E`) | yes | yes | never | one shared indestructible model across most themes |
| Bush (`F`), RespawningForest (`R`) | no | no | supers | hides brawlers; `R` regrows |
| Water (`W`) | **yes** | **no** | never | auto-connected edges (`MapEditorConnected`) |
| Fence (`N`) | yes | yes | supers | connected |
| Rope fence (`a`) | **yes** | **no** | supers | posts plus rope, connected |
| Damageable 1–4 | yes | yes | 6000 HP | **4 visible damage states**, like our BRITTLE |
| Bouncer (`o`) | yes | yes | supers | `IsBouncer` [interp: shots ricochet, like our MUCUS] |
| Slow `z` / Fast `w` / Snow `S` / Ice `q` | no | no | — | speed -300 / +300 / -150 / slippery |
| Damage `x` (100), IntervalDamage `v`, Healing | no | no | — | floor effect pads |
| Springboard | — | — | — | launch pad: 12 tiles, 1 s delay, 3 s cooldown, aim rotates in 45° steps [wiki excerpt] |
| Teleport 1–4 | — | — | — | colour pairs blue/green/red/yellow; 3 s activation and cooldown [wiki excerpt] |
| GravityPull / GravityPush | yes | yes | — | newer pull/push tiles |

Other notes on tiles:
- Walls destroyed by supers **stay destroyed**; regrowing walls were removed [wiki excerpt, pro-brawl-stars-tipsntricks.fandom.com/wiki/Walls].
- Showdown poison gas starts after 20 s and advances 1 tile every 5 s [wiki excerpt].
- One theme has dedicated poison-fog and skull effects (`FogVFXExportName`, `SkullsVFXExportName`) [datamine].
- Colour coding at a glance [observed]:
  - Bushes are the only tall, soft, saturated green mass.
  - Water is the only animated, glossy, flat surface.
  - Rope fences look obviously "see-through": posts plus rope.
  - Fragile props are small and clearly breakable-looking.
  - Pads are flat and circular with an emissive glow.

## 5. Environment themes: one footprint, many skins

**How the system works** [datamine]:
- A map layout (`maps.csv`) is separate from its theme (`location_themes.csv`, 122 theme rows, **45 enabled** in v69.230). Each theme fills the same slots:
  - ground, environment, wall1, wall2, crate, barrel, themed, grass, clutter, fragile, water, fence, rope fence, indestructible, damageable 1–4, deco 1–4
  - mode overrides
  - the map-preview background colour
- Maps get re-themed over time. For example, Belle's Rock moved to Deep Sea in June 2024 and to Castle Courtyard in August 2024 [wiki excerpt].
- **Environments rotate monthly** [official]:
  - April 2026 removed Bizarre Circus, Ice Island, Retropolis, Rumble Jungle, Stunt Show and Tara's Bazaar, and added adidas Arena, Biodome, Gift Shop, Oddities Shop, Poco's Bandstand, Starr Toons, Tropical Island and new Showdown variants [https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-april-2026/].
  - June 2026 removed Biodome, Gift Shop and Starr Toons, and added Katana Kingdom, Hub (Showdown) and Windstock [https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-june-2026/].
  - August 2026 removed adidas Arena, Katana Kingdom, MadEvil Manor and Pyramid Quest, and added Brawlywood, Duolingo, Ghost Metro, Giftshop and Swamp of Love [https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-august-2026/].
- Maps currently in use, grouped by environment, are listed at https://api.brawlapi.com/v1/maps (Brawlify):
  - Most active right now: Love Swamp, Ghost Metro, Brawlywood, Hub, Windstock, Brawl Ball arena, Mortuary Showdown, Tropical Island.

**Theme names in the datamine** (internal names): Mine, Default (desert), Old Town, Grassfield, Oasis, Mortuary, Retropolis, Darryl's Ship, Arcade, BB Arena, Bazaar, Minicity (Super City), Gift Shop, Bandstand, Snowtel, Scrapyard, Starr Force, Action Show, Water Park, Castle Courtyard, Brawlywood, Fighting Game, Biodome, Stunt Show, **Deep Sea**, Robot Factory, Ghost Metro, Candy Stand, Hub, Rooftop, Rumble Jungle, Enchanted Forest, Ranger Ranch, Bizarre Circus, Coin Factory, Ice Island, Starr Toons, Love Swamp, MadEvil Manor, Godzilla, SpongeBob, Oddities Shop, Katana Kingdom, Air Hockey, Skatepark, Pyramid Quest, Tropical Island, Subway Surfers, Stranger Things, Sea Monsters, Windstock, Duolingo.

**How the slots are reskinned** [datamine]:

| Theme | Wall | Themed blocker | Fragile | Clutter |
|---|---|---|---|---|
| Mine | `Rock_1` | mushroom | bone pile | — |
| Default | `Rock_2` | ball cactus | — | bone |
| Mortuary | `rock_mortuary` | tree stump | candles | bone |
| Retropolis | — | potted plant | traffic cone | — |
| Snowtel | — | fir tree | snow lantern | — |
| Ghost Metro | — | ticket machine | — | — |
| Hub | — | trash bin | — | — |
| Ranger Ranch | hay bales | target | lantern | horseshoe |
| Deep Sea | **jellyfish** | — | — | **bubbler** |

Deep Sea also uses the seaweed sway shader. It ran from June 2022 to June 2023 and returned in June 2024 [wiki excerpt]. **It is the closest precedent to our underwater look.**

The map-preview background colours (`MapPreviewBGColor`) range from muted purples (Mortuary 74,52,82; Mine 96,68,84) to warm sand (Default 249,166,117) [datamine].

## 6. Interactivity and juice on the map

- **Hit reactions:** walls, crates, barrels and fragile props have a hit animation; water and fences don't [datamine `HasHitAnim`]. Every destructible has its own break effect.
- **Permanent destruction:**
  - Supers and Overtime carve the map for the rest of the match.
  - "Loaded Walls" (Aug 2026) makes broken walls drop random items: bombs, bowling balls, shuriken, bumper cars [official, Aug 2026].
  - April 2026 rebuilt ball physics because of the environment changing during a match [official, Apr 2026].
- **Ambient animation is cheap:**
  - Flags, torches and cheering robots are 2–3 mesh frames swapped every **180–350 ms** (`AnimateSwitchBetween`, 30 entries) [datamine `location_features.csv`]. It is stop-motion, not skeletal animation.
  - Bushes and seaweed sway in the vertex shader (§3).
- **Events and modifiers, always telegraphed on the floor** [https://mobilematters.gg/guides/brawl-stars/brawl-stars-event-modifiers-explained; wiki excerpts]:
  - Meteor Shower: a red circle appears, the hit lands 3 s later.
  - Energy Drink: a small marker before it spawns.
  - Healing Mushrooms: a green ring that heals 1000 HP/s.
  - Also: Angry Robo / Robo Boss, Devastation Cloud (poison clouds that also destroy obstacles), Super Bushy (bushes spread 1 tile every 3–5 s), Ice Age (floor turns to snow, water to ice), Instant Overtime (all obstacles removed), Toxic Arena, Top Dog, Graveyard Shift, Hyper Drop.
  - Added in 2026: Prop Hunt (stand still and you turn into nearby decor) and Friendly Fire [official, Aug 2026].
- **Readable chaos:** effects belong to teams (blue for allies, red for enemies), danger zones are flat circles on the floor, and the environment itself stays muted [observed / wiki].

## 7. Readability principles

The first six are evident in the game data; the last two are from community sources:

1. **Light, soft shadows**: 25% darkening (×0.75). Shadows give contact and depth but never black holes [datamine].
2. **One light direction** for everything, enforced by matcap shading rather than per-scene lights [datamine].
3. **Low walls**: the footprint is the gameplay; height is a cue that should not hide brawlers [observed].
4. **A strict grid**: every gap is a whole number of tiles, and the Map Maker bans 1-tile and diagonal gaps. Players never judge pixel-exact gaps [wiki/guide].
5. **The same footprint in every theme**: the rule a tile carries never changes; only its skin does. Each tile type keeps its own silhouette and material class (solid rock, soft bush, glossy water, see-through rope) [datamine].
6. **Mid-value, low-detail floor** with a faint grid for measuring range. Brawlers and effects carry the saturation [observed].
7. **Reserved team colours**: green for you, blue for allies, red for enemies [wiki].
8. **Iconic simplicity**: one key element per design, not hundreds of props (Supercell art director Fernanda Oliveira at GDC 2025) [https://www.pocketgamer.biz/5-creative-pillars-for-designing-brawlers-in-supercells-brawl-stars/].

## 8. Other top-down mobile arena games

| Game | Technique | What to borrow |
|---|---|---|
| **Clash Royale** (Supercell) | 2D game: pre-rendered 3D sprites on a painted arena; height is baked in [https://retrostylegames.com/portfolio/spell-arena-3d-characters-clash-royale/] | The same family as our Codex raster pipeline: baked light, painted floor, decor outside the play area |
| **Squad Busters** (Supercell, 2024; shutdown announced Oct 2025, servers off mid/late 2026 [https://en.wikipedia.org/wiki/Squad_Busters]) | True 3D with a tilted camera [unverified]. Credits list a dedicated "environment 3D and vertex paint" artist [ArtStation credits via search] | Gradient-coloured surfaces with very little texture: in 2D, flat shapes with soft gradients like our SVGs |
| **Zooba** (Wildlife) | 3D. When you enter a bush, a circular hole is cut into it around you, with the bush's inside wall visible. Built with depth and stencil buffers in a way suited to mobile GPUs [https://www.jendrikillner.com/post/graphics-programming-weekly-issue-140/, https://discussions.unity.com/t/help-needed-building-this-zooba-shader/1596279] | A soft circular hole in our bush canopy around your own microbe |
| **Pokémon Unite** | 3D tilted camera. Tall grass hides you from enemies; allies still see you; enemies in the same patch see each other [https://game8.co/games/Pokemon-UNITE/archives/337827] | A same-bush mutual-reveal rule and a matching visual |
| **Bullet Echo** (ZeptoLab) | 2D top-down; a flashlight cone sets vision [https://www.pocketgamer.com/bullet-echo/bullet-echo-hints-and-tips-to-help-you-illuminate-in-this-night-shooter/] | Light as gameplay: a bioluminescent glow radius |
| **Sprite stacking** (technique) | 2D slices stacked with small offsets to fake volume [https://jamespoole.itch.io/wee-boats/devlog/685630/using-sprite-stacking-for-pseudo-3d-in-wee-boats] | Blobs as 3–4 slices from one texture, so they still batch |

Godot helpers for a 2D 2.5D look:
- Y-sort.
- An occlusion-outline clone of the sprite: https://godotshaders.com/shader/occlusion-outline-for-godot-4/ and https://www.gdquest.com/tutorial/godot/shaders/silhouette-2d/.
- Use these only for your own microbe: each adds about 1 draw call.

## 9. What this means for a circular, organic petri-dish map

**Main takeaway:** BS gets its 2.5D read from four things:
1. A lit top face plus a darker south face.
2. Light, squashed, offset shadows.
3. Swaying vegetation.
4. Destruction that changes the map.

All four can be faked in 2D within our draw-call budget. The real decision is ART_BIBLE §4b's rule "silhouette = collision footprint". BS breaks it: the top cap rises above the footprint, and players read the base. So I propose versions on both sides of that rule.

### Structural versions (the user's "several versions")

- **V1 "Damla" (droplet, keeps §4b)**
  - The art stays inside the collision circle: a domed top cap shifted up and left inside the circle, and a south front crescent about 22% of r (as now).
  - Add a thin dark contact ring exactly on the collision circle.
  - Add a BS-style shadow: the silhouette at 60% height, sheared about 0.25, offset down-right by about 0.2 r, darkening only 25–30%.
  - Add a hit wobble on MUCUS: 3–5% scale pulse for about 120 ms, matching BS `HasHitAnim`.
  - Zero risk to logic.
- **V2 "Sütun" (pillar, most like BS; breaks §4b, so the user must decide)**
  - The base circle is the collision, drawn as an ambient-occlusion ring plus a wall band. The cap is lifted up the screen by h = 0.15–0.2 r, capped at about 16 px. That is less than the amoeba's radius (28 × 0.78 ≈ 22 px), so a microbe never fully disappears.
  - Needs Y-sorting of microbes against obstacles.
  - Needs an x-ray outline for your own microbe (one extra draw).
  - Optionally fade a cap when a microbe is under it. Do this only on the 1–3 affected sprites; modulating all of them is what took draw calls from 131 to 242.
- **V3 "Kasa" (bowl, 2.5D at the world level, cheap)**
  - Draw the dish as a tilted glass bowl: the inner glass wall shows on the **north** arc, fading to nothing at east and west; the **south** arc shows only the top lip and the outer face.
  - Microbes and balls get a small offset shadow on the agar, which says "swimming above the floor".
  - Optional sunken vents and raised agar terraces as decals only.
  - Pairs with V1.
- **V4 "3D render" (reference only)**
  - A Godot 3D render layer over the same simulation: Camera3D at about 55°, FOV about 25°, obstacles as one MultiMesh, matcap shading like BS.
  - Highest fidelity, but a large rewrite, and the WebGL and low-quality settings carry risk.

### Theme versions (BS-style reskins of the same four kinds)

Each theme reskins MUCUS, BUSH, BRITTLE and VENT, plus the floor, rim and outside decor:

| Theme | Look |
|---|---|
| T1 Agar Lab | current teal |
| T2 Biofilm Cave | deep violet, bioluminescent |
| T3 Pond Drop | olive and diatom green, algae filaments; closest to BS Deep Sea |
| T4 Cryo Culture | frost blue, ice-crystal brittle |
| T5 Thermal Vent | basalt and amber, thermophiles |

Floors stay mid-to-low value and desaturated. None of the 10 microbe colours may appear at full saturation in the environment.

**Flag:** BUSH `#4FCB72` is close to the microbe colours `7CFF5B` and `4BFFA5`. BS keeps environment greens away from team colours.

**Asset slots per theme for Codex**, mirroring BS `location_themes` (Codex should make 2–3 variants of each):
- floor
- rim north (inner wall)
- rim south (lip)
- outside decor ring
- MUCUS ×2
- BUSH base and canopy (with sway parts)
- BRITTLE ×3 damage stages, plus a debris burst and a non-blocking rubble decal
- VENT base and swirl
- walk-through clutter ×3–4 that pops when shot (like BS `D`)
- ambient props ×2, each 2–3 frames (BS swaps at 180–350 ms)
- one shadow blob
- a telegraph ring (BS-style event marker)

### Interactivity, cheapest first

1. Bush sway, scaled by height, phase seeded by position.
2. A soft hole in the canopy around your own microbe (Zooba), on top of the existing alpha 0.45.
3. Rustle only for microbes you can already see. A rustle from a hidden enemy would leak information the server deliberately withholds.
4. Hit wobble on mucus and brittle.
5. A permanent rubble decal where brittle breaks (BS "destroyed stays destroyed").
6. Wakes and splashes in the water.
7. Ground telegraph rings for any future dish events.

### Calibration numbers

| BS value | ≈ Germ Arena |
|---|---|
| 1 tile | 70 px |
| Bush reveal distance (about 2 tiles) | 140 px |
| Map Maker minimum gap (2 tiles) | 140 px; our amoeba-only gaps are a deliberate exception and need the V1/V2 contact ring to read |
| Bush share of tiles | 13% |
| Blocking share of tiles | 11% |

My rough estimate of the dish, not measured in game: about 7–8% blocking and about 3% bush. If we want BS-like bush play, bush coverage is the lever.

---

**Primary sources:**
- https://supercell.com/en/news/titan-game-engine/
- https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-april-2026/
- https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-june-2026/
- https://supercell.com/en/games/brawlstars/blog/release-notes/release-notes-august-2026/
- https://supercell.com/en/games/brawlstars/blog/release-notes/snowtel-update-patch-notes-1/
- https://github.com/tailsjs/brawl-stars-assets (v69.230)
- https://api.brawlapi.com/v1/maps
- https://forum.godotengine.org/t/how-to-get-camera-perspective-view-like-brawl-stars/23689
- https://toucharcade.com/2018/03/13/brawl-stars-landscape-update-angers-community/
- https://toucharcade.com/2018/03/21/brawl-stars-landscape-balance-update-attempts-to-improve-long-range-brawlers/
- https://www.deconstructoroffun.com/blog/2018/5/11/bs
- https://en.wikipedia.org/wiki/Brawl_Stars
- https://mobilematters.gg/guides/brawl-stars/brawl-stars-event-modifiers-explained
- https://en.androidayuda.com/games/Tutorials/brawl-stars-map-creator/
- https://www.pocketgamer.biz/5-creative-pillars-for-designing-brawlers-in-supercells-brawl-stars/

Raw datamine files I downloaded (in my session scratchpad): C:\Users\User\AppData\Local\Temp\claude\C--Users-User-Desktop-Germ-game-V1\5479a438-be68-4dd6-918e-3e73992da313\scratchpad\ — `tiles.csv`, `location_themes.csv`, `maps.csv`, `globals.csv`, `characters.csv`, `location_features.csv`, `maps.json`, and the shader files.