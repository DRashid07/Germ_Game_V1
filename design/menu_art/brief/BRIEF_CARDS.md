You are the key-art artist for a mobile game. Read STYLE.md in this folder first and
follow its HARD RULES — above all: the microbes have NO FACE (no eyes, no pupils, no
mouth, no eyebrows, no pair of dots that could read as eyes).

## What we are making
"Germ Arena" rebuilds its character-collection screen in the style of Brawl Stars'
Brawlers screen (ref/current_collection.png is the current, too-plain version).
In Brawl Stars every brawler card is a PORTRAIT: the character, big and close, in a
dynamic hero pose, over a bold radial background in the card's colour, with light
rays behind it. We need THREE such card portraits — one per playable microbe.

The characters are ALREADY DESIGNED and approved — ref/hero_ciliate.png,
ref/hero_heliozoan.png, ref/hero_amoeba.png. Keep each one's exact design (shape,
laym-green #7CFF5B jelly body, thick dark #04090B outline, glossy pale-green balls
inside, species features). Do not redesign them. Use each hero image as the identity
reference for its card (image edit / reference, not a new character).

Use your built-in image generation tool (image_gen). Work only inside this folder.
Save final files into ./out/ with exactly these names. Python is NOT installed.

## Common to all three cards
- PORTRAIT canvas, 1024x1536, OPAQUE (full background, no transparency needed).
- Composition like a Brawl Stars brawler card: the microbe fills about 75% of the card
  width, positioned in the UPPER-MIDDLE (its centre at about 42% from the top), seen
  close and slightly from below/front so it feels heroic, tilted a little for energy.
  Its whole body stays inside the frame, only thin cilia/spoke tips may touch edges.
- Background: a bold radial burst in the card colour — bright glow behind the
  microbe, fading to a deep, darker shade of the same colour at the edges; soft
  sun-ray streaks radiating from behind the character; a few floating bubbles and
  tiny glossy food balls for depth (blurred). Stylized, clean, NOT photographic.
- The BOTTOM 25% of the card must be calm and darker (a solid-ish deep shade of the
  card colour) — the game will print the name there. Nothing important below 75% height.
- Same rendering on all three: chunky soft-3D cel shading, light from the TOP-LEFT,
  crisp specular highlight, thin bright rim light bottom-right, thick dark outline.
- No text, letters, numbers, logos, frames, borders or UI of any kind.

## The cards
1. out/card_ciliate.png — KİRPİKLİ, class "SWIFT". Card colour: warm AMBER/ORANGE
   (#FFB43D glow → #8A4A08 edges). Pose: darting diagonally up-right, whip tail
   trailing in a dynamic S-curve behind it, a few speed streaks in the background
   rays. Energetic, fastest species.
2. out/card_heliozoan.png — AYAQLI, class "CONTROLLER". Card colour: PURPLE/VIOLET
   (#A96BFF glow → #3A1670 edges). Pose: standing firm, spokes spread wide like a sun,
   a faint glowing web of thin lines between the spoke tips (its "net" ability),
   a couple of food balls being pulled toward it. Calm, in control.
3. out/card_amoeba.png — AMÖB, class "GUARDIAN". Card colour: BLUE (#4D9BFF glow →
   #102E66 edges). Pose: bulging forward with its pseudopod lobes, a faint translucent
   protective shell/cyst outline glowing around it (its "cyst" ability). Sturdy, sneaky.

## Quality loop
Look at every result yourself. Reject and redo (max 3 tries per card) if: any
face-like feature, any text or frame, the microbe's design drifted away from its
reference hero image, the body is cropped, the bottom 25% is busy, or the three cards
do not look like one matching set. Verify each file is 1024x1536 (or the closest
portrait size the tool gives) with PowerShell + System.Drawing.

Finish with a short report: each file, its pixel size, and the exact prompt used.
