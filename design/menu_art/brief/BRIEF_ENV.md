You are the environment artist for a mobile game lobby. Read STYLE.md in this folder
first and follow it exactly. Also look at ref/ingame_arena.png (what the game itself
looks like) and ref/menu_current.png (the current, too-plain lobby we are replacing).

Use your built-in image generation tool (image_gen). Create TWO images and save the
final files into ./out/ with exactly these names. Work only inside this folder.
Python is NOT installed on this machine; do not rely on it.

## 1. out/menu_bg.png — lobby background (opaque, landscape)
- Widest landscape size the tool supports (e.g. 1536x1024). It will be scaled to
  "cover" a 16:9 to 20:9 phone screen, so keep important content away from the top
  and bottom 12% of the image.
- Scene: the inside of a giant water-filled petri dish seen from a low 3/4 camera, as a
  stylized underwater arena world. A soft agar floor receding to a hazy horizon; the
  curved glass wall of the dish rising at the far left and far right with a bright
  cyan rim highlight; gentle god-rays falling from the top-left through the water;
  out-of-focus bokeh bubbles and a few blurred, faceless microbe silhouettes (round,
  ciliated, spiky) drifting far in the background; a few glowing plankton motes.
- Composition: the CENTRE of the image (where the hero stands, roughly x 35–65%,
  y 25–80%) must be calm, uncluttered and slightly brighter, like a spotlight pool on
  the floor — a character and a round stage will be composited there. All four
  corners must be dark and quiet (UI panels sit there). Strong but soft vignette.
- Mostly dark teal/cyan values; accents of laym green and a touch of warm amber for
  depth. Overall value range dark — light UI text (#EAFBF6) must stay readable on it.
- No characters in focus, no stage/podium (it is a separate image), no text.

## 2. out/menu_podium.png — the hero's stage (TRANSPARENT background)
- Transparent background with real alpha. Landscape canvas (e.g. 1536x1024).
- A round stage made from a thick glass petri-dish rim filled with a smooth agar-gel
  top, seen from about 25–30 degrees above, so it reads as a wide ellipse (width about
  3x height). It fills ~90% of the canvas width, centred.
- Thick bevelled glass rim with a cyan (#2FE8E0) bioluminescent glow on its edge and
  a bright specular streak on the top-left; the gel top is a dark teal (#12262C →
  #1A3942) with two faint concentric rings (same language as the in-game dish
  rings); the visible front side of the rim is darker (it has height).
- Soft outer glow allowed but must fade to fully transparent before the canvas edge.
- Nothing standing on it. No text.

## Quality loop
After each generation, look at the result yourself. Reject and regenerate (max 3 tries
per image) if: any text/letters appear, the podium background is not transparent, the
background centre is busy, or the corners are bright. If the tool saves images
somewhere else (e.g. ~/.codex/generated_images/...), copy the final chosen file into
./out/ under the exact name above.

Finish with a short report: each file, its pixel size, whether it has alpha, and the
exact prompt you used for it.
