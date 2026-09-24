You are the UI icon artist for a mobile game lobby. Read STYLE.md in this folder first
and follow its HARD RULES (especially: microbes have NO FACE — no eyes, no mouth).

Context: the lobby of "Germ Arena" is being rebuilt to match today's Brawl Stars home
screen: chunky buttons with thick black outlines, bold saturated colours, big readable
glyph icons. ref/menu_current.png is the current lobby; ref/hero_*.png are the three
playable microbes (use them for the microbe look: laym-green glossy jelly, thick dark
outline, glossy pale-green balls inside).

Use your built-in image generation tool (image_gen). Create SEVEN icons. Save the final
files into ./out/ with exactly these names. Work only inside this folder. Python is NOT
installed on this machine; do not rely on it.

## Common style (all seven must look like one set)
- Brawl Stars-style UI glyph icon: chunky, bold silhouette, THICK black outline
  (#04090B, about 4% of the canvas width) around every shape, bright saturated colours,
  soft 3D cel shading lit from the TOP-LEFT, one crisp glossy highlight, slight tilt
  allowed. Readable when shrunk to 64x64 pixels — so few, big shapes and no fine detail.
- Square canvas (1024x1024), subject centred, filling about 80% of the canvas.
- TRANSPARENT background with real alpha. No tile, no badge, no frame, no circle behind
  the glyph, no drop shadow onto a background, no glow outside the outline.
- No text, letters or numbers.

## The icons
1. out/icon_brawlers.png — "MİKROBLAR" (the character collection button). The three
   playable microbes huddled together as a group, overlapping: the oval ciliate with its
   cilia fringe, the round heliozoan with bead-tipped spokes, the blobby amoeba. All
   laym green #7CFF5B, faceless, glossy balls visible inside.
2. out/icon_practice.png — "MƏŞQ" (offline practice vs bots). A round bullseye target
   (white and amber #FFB43D rings) with one glossy pale-green ball (#D9FFC0) just
   hitting its centre, a small impact splash.
3. out/icon_settings.png — settings. A chunky cog wheel, light grey-white (#E8F4F2)
   with a darker grey side for thickness, 8 rounded teeth, a round hole in the middle.
4. out/mode_endless.png — "SONSUZ ARENA" (endless arena). An infinity loop made of
   glossy cyan (#2FE8E0) jelly with a few pale glossy balls travelling along it.
5. out/mode_solo.png — "TƏK QALAN" (last one standing). One round faceless laym-green
   microbe wearing a small golden crown (#FFB43D / #FFD23F), victorious and alone.
6. out/mode_duo.png — "CÜT" (teams of two). Two faceless round microbes side by side,
   touching, one mint (#4BFFA5) and one cyan (#2FE8E0), each with glossy balls inside.
7. out/mode_trio.png — "ÜÇLÜK" (3 vs 3). Three faceless round microbes in a tight
   triangle formation, all purple (#A96BFF), glossy balls inside.

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
face-like feature on a microbe (two dots that read as eyes count), any text, missing
thick black outline, a tile/badge/frame behind the glyph, the alpha check fails, or it
does not match the set's style.

Finish with a short report: each file, pixel size, alpha verification result, and the
exact prompt used.
