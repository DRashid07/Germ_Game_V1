You are the UI icon artist for a mobile game lobby. Read STYLE.md in this folder first
and follow its HARD RULES (especially: microbes have NO FACE — no eyes, no mouth).

Context: "Germ Arena" has a Brawl Stars-style lobby (ref/menu_current.png). Seven icons
were already made and APPROVED — ref/approved_icon_set.png (on a blue test background).
Make FIVE MORE icons that belong to exactly the same set: same thick black outline,
same chunky soft-3D cel shading lit from the top-left, same saturation, same glossy
highlights. Put them next to the approved set in your head — they must not stand out.

Use your built-in image generation tool (image_gen). Save the final files into ./out/
with exactly these names. Work only inside this folder. Python is NOT installed.

## Common style
- Brawl Stars-style UI glyph icon: chunky, bold silhouette, THICK black outline
  (#04090B, about 4% of the canvas width) around every shape, bright saturated
  colours, soft 3D cel shading lit from the TOP-LEFT, one crisp glossy highlight.
  Readable when shrunk to 48x48 pixels — few, big shapes, no fine detail.
- Square canvas (1024x1024), subject centred, filling about 80% of the canvas.
- TRANSPARENT background with real alpha. No tile, badge, frame or circle behind the
  glyph, no drop shadow onto a background, no glow outside the outline.
- No text, letters or numbers anywhere.

## The icons
1. out/icon_shop.png — "MAĞAZA" (shop). A chunky shopping bag, bright magenta-pink
   (#FF5BC8) with a darker side, two rounded handles, and a small laym-green (#7CFF5B)
   faceless microbe blob peeking out of the top of the bag.
2. out/icon_pass.png — "MİKRO PASS" (season pass). A tilted golden ticket/pass card
   (#FFD23F with amber #FFB43D edges and notched ticket corners) with a round laym-green
   microbe emblem stamped in its centre (emblem = simple glossy blob with 3 pale balls
   inside, faceless). No text on the ticket.
3. out/icon_quests.png — "TAPŞIRIQLAR" (quests). A chunky parchment scroll, partly
   unrolled, cream-white (#F4EBD0) with a big bold green (#52E08A) check mark on it.
   No writing lines that look like text.
4. out/currency_food.png — soft currency. One big glossy "food ball" coin: a pale
   green sphere (#D9FFC0 with a #F6FFEE core and a white highlight), slightly
   translucent jelly, with a thick black outline — like the in-game food ball but
   chunky and rich enough to read as a coin.
5. out/currency_dna.png — premium currency (the "gems"). A faceted crystal gem shaped
   like a short twisted DNA double helix, glowing purple (#A96BFF) to cyan (#2FE8E0),
   sharp facets with bright highlights, thick black outline.

## Transparency — this is where earlier attempts FAILED
image_gen sometimes answers "transparent background" by PAINTING A GREY CHECKERBOARD
into the pixels (24-bit RGB, no alpha). That is unusable. The workflow that worked in
this project before: generate the icon, then run a second image_gen EDIT on it that
removes the background and outputs real transparency, preserving the subject exactly.

VERIFY every file with PowerShell + System.Drawing before accepting it: it must load as
Format32bppArgb AND the pixels at (8,8) and (width-8,height-8) must have alpha 0. Never
deliver a checkerboard.

## Quality loop
Look at every result yourself. Reject and redo (max 3 tries per icon) if: any
face-like feature on a microbe, any text or letters (including on the ticket or scroll),
missing thick black outline, a tile/badge/frame behind the glyph, the alpha check
fails, or it does not match the approved set's style.

Finish with a short report: each file, pixel size, alpha verification result, and the
exact prompt used.
