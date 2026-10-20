You are the logo designer for a mobile game. Read STYLE.md in this folder first: its
palette, light direction and "microbes have NO FACE" rule apply. Its rule "no text, no
logos" does NOT apply to this job — this job IS the logo, so the game's name is required.

## The job
"Germ Arena" is a landscape online io-style arena game for phones: faceless glossy jelly
microbes swim in a giant water-filled petri dish and shoot glossy balls at each other.
Right now the game opens with the Godot engine logo. We need the GAME'S OWN LOGO for the
opening (boot splash, shown centred on the plain dark background #070F12 while the game
loads), later also usable in the menu and store art.

The owner's words: the logo must fit the game's current design, but be SIMPLE — not
flashy like a typical AI-generated logo — and it must feel like a PREMIUM game.

Attached images (all are REFERENCES, do not copy them literally):
- menu_screenshot.png — the current home screen. The logo must clearly belong to this
  world: chunky Brawl Stars/Supercell-style UI, thick near-black outlines, lime hero,
  dark teal water, cyan accents.
- lettering_baloo2.png — "GERM ARENA" set in the game's own heading font (Baloo 2
  ExtraBold, used for OYNA, AMÖB, SONSUZ ARENA on the buttons). The logo lettering must
  be in this family's spirit: heavy, rounded, friendly, very legible. You may custom-tune
  it like a real logo (heavier, tighter spacing, optical kerning, a slightly taller
  "GERM"), but it must not drift into a different typeface style (no blackletter, no
  sci-fi, no handwriting, no wobbly cartoon bubbles).
- hero_amoeba.png, icon_friends.png, mode_duo.png, icon_practice.png — approved game art:
  the material and rendering of a faceless lime microbe (glossy jelly, pale balls inside,
  thick dark outline, light from the TOP-LEFT).

## What "simple, premium, not AI-looking" means here — HARD requirements
Do:
- Clean, flat-vector-like shapes with crisp edges and ONE consistent thick near-black
  outline (#04090B) around the whole lockup.
- At most two or three flat tones per surface (cel shading): base colour, one
  lighter top-left face, one darker lower-right. One small crisp highlight per letter is
  allowed, nothing more.
- A short solid extrusion / depth under the letters in deep teal (#0E3A40 to #12262C) is
  welcome — that is the Supercell "premium" cue — but keep it short and solid, no
  perspective tricks.
- A restrained palette: lime #7CFF5B (with light #C9FFB8 and shadow #3D8A2C), ivory
  #EAFBF6 / pale #D9FFC0, deep teal, outline #04090B. Cyan #2FE8E0 only as a tiny accent
  if at all. No more than these.
- Perfect spelling, exactly: G E R M  A R E N A (two words, nine letters). Nothing else:
  no tagline, no "TM", no extra letters, no numbers, no punctuation.
- Confident, balanced, centred composition that reads instantly at 300 px wide.
Do NOT (an image with any of these is rejected):
- glow, bloom, outer glow, neon, lens flare, light rays, sparkles, stars, twinkles,
  particles, floating bubbles, splashes, drips, smoke;
- chrome, metal, gold bevels, gemstones, glass/glassmorphism, rainbow or many-stop
  gradients, noise/grain textures, photoreal 3D render, depth of field;
- shields, banners, ribbons, wings, crowns, swooshes, frames, badges or plates behind the
  text; drop shadows onto a background;
- any face on a microbe: no eyes, pupils, mouth, eyebrows. Pale balls inside a microbe
  are cell contents; never place two equal balls side by side (they read as eyes).

## Directions — make THREE different concepts, each simple
1. out/logo_a.png — STACKED WORDMARK. "GERM" big on the first line, "ARENA" on the
   second line, a bit smaller and wider-spaced, both lines the same width. GERM in lime,
   ARENA in ivory, shared deep-teal extrusion. No emblem, or at most the counter of one
   letter turned into a tiny pale cell ball.
2. out/logo_b.png — ONE-LINE WORDMARK + SMALL GERM. "GERM ARENA" on one line, lime with a
   deep-teal extrusion; one small faceless lime germ blob (2–3 pale balls inside,
   different sizes) tucked onto the lettering in one place only, e.g. resting on top of
   the "G" or replacing the dot-space between the words. The germ must stay small.
3. out/logo_c.png — EMBLEM + WORDMARK. A compact round mark on the left — a faceless lime
   germ inside a thin petri-dish ring — and the two-line wordmark (GERM / ARENA) to its
   right. The mark must also work alone later as an app-icon symbol.

Keep all three on the same rendering and palette, so the only difference is layout.

## Technical
- Use your built-in image generation tool (image_gen). Work only inside this folder.
  Python is NOT installed; use PowerShell + System.Drawing for checks and previews.
- Landscape canvas (e.g. 1536x1024), lockup centred, about 80% of the canvas width,
  comfortable margin on every side; nothing cropped.
- TRANSPARENT background with real alpha. image_gen sometimes answers "transparent" by
  PAINTING a grey checkerboard into the pixels (24-bit RGB, no alpha) — unusable. The
  workflow that worked in this project: generate the logo, then run a second image_gen
  EDIT on it that removes the background and outputs real transparency while preserving
  the artwork exactly. The holes inside letters (the counters of A, R and the gap between
  the words) must be genuinely transparent too.
- VERIFY every final file with PowerShell + System.Drawing: it must load as
  Format32bppArgb, the pixels at (8,8) and (width-8,height-8) must have alpha 0, and a
  pixel in the middle of the counter of the first "A" must have alpha 0.
- For each concept also write work/preview_<a|b|c>.png: 1600x720, filled with #070F12,
  the logo centred at 45% of the width, plus the same logo at 300 px wide in the
  lower-left corner (legibility check). These previews are for review only.

## Quality loop
Look at every result yourself, closely, at full size and small. Reject and redo (max 3
tries per concept) if: any letter is misspelled, doubled, missing or malformed; any
banned effect from the list above appears; any microbe has something that reads as a
face; the outline is not continuous; it looks busy; the alpha checks fail.

Finish with a short report (in English): each file, pixel size, alpha verification
result, which concept you think is strongest and why, and the exact prompts used. Also
save the report as REPORT.md.
