## CORRECTION — read this before anything else (it overrides the brief below)

A previous attempt was rejected: ref/rejected_hero_ciliate_checkerboard.png has a grey
CHECKERBOARD PATTERN PAINTED INTO THE PIXELS (24-bit RGB, no alpha). A painted
checkerboard is not transparency and is unusable in the game.

### How to deliver the background — in this order
A. Real alpha. Use image_gen's actual transparent-background option (not the words
   "transparent background" in the prompt text). Then VERIFY with PowerShell +
   System.Drawing: the file must load as Format32bppArgb AND the pixel at (8,8) and at
   (width-8, height-8) must have alpha 0. If both checks pass, save as
   out/hero_<name>.png.
B. If the tool cannot give real alpha (checks fail twice), generate instead on a
   perfectly FLAT, solid, pure magenta background #FF00FF — no checkerboard, no
   gradient, no vignette, no floor, no shadow, no glow spilling onto the background,
   and no magenta/pink anywhere on the creature. Save as out/hero_<name>_key.png.
   (The key colour will be removed later outside this session.)
Never deliver an image that contains a checkerboard.

### What to keep from the rejected ciliate
Its DESIGN was approved: the egg-shaped body, the eight glossy spheres, the darker inner
lobe, the tapered cilia fringe and the S-curved whip tail. Keep all of that.

### What to change on all three
- Add the thick dark outline (#04090B, clearly visible, roughly 1.5–2% of the image
  width) around the whole outer silhouette of the body — the in-game germs have it
  (see ref/ingame_species_*.png) and without it the art reads as generic clip-art.
  Cilia, tail, spokes and beads get a thinner version of the same dark outline.
- A bit more volume: 3/4 view from slightly above, so the body reads as a squishy 3D
  jelly with a visible underside shadow band, not a flat top-down disc.

---

You are the character artist for a mobile game lobby. Read STYLE.md in this folder
first and follow it exactly — especially HARD RULE 1: the microbes have NO FACE.

The attached images (also in ref/) show the three playable species exactly as the game
draws them from above during play:
- ref/ingame_species_0.png — KİRPİKLİ (ciliate)
- ref/ingame_species_1.png — AYAQLI (heliozoan)
- ref/ingame_species_2.png — AMÖB (amoeba)
The lobby needs a big, polished HERO version of each one — the same creature, same
laym-green colour and the same identifying features, but rendered as a chunky 3D-ish
character in a 3/4 view from slightly above, as if standing on a stage facing the
viewer. Think "Brawl Stars brawler in the lobby", but a faceless microbe.

Use your built-in image generation tool (image_gen). Create THREE images and save the
final files into ./out/ with exactly these names. Work only inside this folder.
Python is NOT installed on this machine; do not rely on it.

Common to all three:
- 1024x1024, TRANSPARENT background with real alpha. No ground, no shadow, no stage.
- Full body visible, centred, filling about 75–80% of the canvas, nothing cropped.
- Body: glossy, slightly translucent jelly membrane in laym green #7CFF5B, lighter
  tint on the top-left, deeper green shading bottom-right, thick dark #04090B outline,
  thin bright rim light on the bottom-right edge, a crisp specular highlight top-left.
- Inside the body, visible through the membrane: a darker inner cytoplasm lobe and
  about 7–9 glossy pale-green spheres (#D9FFC0 with a white highlight) — these are the
  game's ammo balls and must be clearly visible.
- NO eyes, NO mouth, NO face of any kind. No text.
- All three must look like one family: same rendering style, same outline weight,
  same green, same light direction. Make the first one, then use it as the style
  reference when generating the other two.

## 1. out/hero_ciliate.png — KİRPİKLİ
Slipper/egg-shaped oval body (paramecium), tilted slightly forward as if darting
ahead. A dense fringe of short, tapered cilia all around the outline (thick at the
root, fine at the tip, light green). One long whip-like tail trailing from the back,
thick at the root and thin at the end, in a gentle S-curve. Energetic, fastest species.

## 2. out/hero_heliozoan.png — AYAQLI
A round, spherical body. 8–10 long, thin, straight radiating spokes (axopodia), each
with a small glossy bead at its tip; the lower spokes are planted downward like legs
so the creature stands on them like a spider/walker, the upper ones fan out like a
sun-burst. Each spoke has a dark outline and a bright thin core. Sturdy, slowest species.

## 3. out/hero_amoeba.png — AMÖB
A soft bean/blob body with 2–3 bulging pseudopod lobes reaching forward and a small
bumpy tail bulge at the back. TWO clear layers: a lighter, more translucent outer gel
rim (ectoplasm) and a more saturated inner body (endoplasm). Inside, small pale
star-shaped crystal particles plus the glossy spheres. Squishy, sneaky species.

## Quality loop
After each generation, look at the result yourself. Reject and regenerate (max 3 tries
per image) if: there is ANY face-like feature (two dots that read as eyes count!), any
text, the background is not transparent, the body is cropped, or it stops matching the
in-game reference. If the tool saves images somewhere else (e.g.
~/.codex/generated_images/...), copy the chosen file into ./out/ under the exact name.

Finish with a short report: each file, its pixel size, whether it has alpha, and the
exact prompt you used for it.
