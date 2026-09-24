> Codex-in öz hesabatıdır (dəyişdirilməyib, yalnız fayl yolları nisbi edilib).

Created and QA-checked both assets using the built-in image generator.

- [menu_bg.png](../raw/menu_bg.png) — 1672×941, opaque RGB, no alpha.
- [menu_podium.png](../raw/menu_podium.png) — 1952×806, RGBA with genuine transparency; all corner alpha values are 0.

Both passed on the first generation attempt.

Exact background prompt:

```text
Use case: stylized-concept
Asset type: mobile game lobby background, opaque landscape environment art
Primary request: Create a polished premium mobile-game environment showing the inside of a giant water-filled petri dish as a stylized microscopic underwater arena world.
Scene/backdrop: A soft agar floor recedes toward a hazy underwater horizon. The curved glass wall of the enormous dish rises at the far left and far right, each edge caught by a bright cyan rim highlight. Gentle volumetric god-rays fall diagonally from the top-left through dark water. Only in the far background, include a few very soft, out-of-focus, completely faceless microbe silhouettes: one round, one ciliated, one spiky. Add sparse bokeh bubbles and a few tiny glowing plankton motes.
Style/medium: Stylized chunky soft-3D cartoon rendering, premium mobile game key art, clean graphic shapes, subtle cel-shading, readable and atmospheric rather than realistic. Match the visual language of a dark teal io arena with faint broad concentric dish rings. One global light from top-left.
Composition/framing: Widest landscape composition, designed to cover 16:9 through 20:9 phone screens. Keep all important environmental features away from the top and bottom 12 percent. The central region from approximately x 35–65 percent and y 25–80 percent must be calm, uncluttered, slightly brighter, and shaped like a soft spotlight pool on the agar floor, leaving clear room for a separately composited hero and round stage. No object may cross or clutter this central staging zone. All four corners must be dark, quiet, low-detail negative space for UI panels. Strong but soft vignette.
Lighting/mood: Bioluminescent, mysterious but readable; top-left god-rays, subtle floor bloom in the center, atmospheric depth.
Color palette: Mostly dark teal and cyan: deep background #071012, far vignette #020708, agar floor #12262C, glass #2B5963, faint rings #1A3942, cyan edge glow #2FE8E0. Very sparse lime green #7CFF5B and tiny warm amber #FFB43D accents only in distant motes for depth. Overall value range dark enough for #EAFBF6 UI text to remain readable.
Constraints: Opaque full-frame background. No foreground character. No in-focus creature. Microbes must be distant, blurred, silhouetted, and have absolutely no face, eyes, pupils, mouth, or eyebrows. No stage or podium. No humans, hands, or laboratory equipment. No interface elements.
Text: none.
Avoid: any text, letters, numbers, logos, watermarks, signatures, bright corners, busy center, sharp central objects, cute faces, foreground props, surface-above-water view.
```

Exact podium prompt:

```text
Use case: stylized-concept
Asset type: isolated transparent hero-stage asset for a mobile game lobby
Primary request: Create one empty round stage made from a thick glass petri-dish rim filled with a smooth agar-gel top, isolated on a genuinely transparent background with real alpha.
Scene/backdrop: No scene and no backdrop; every pixel outside the stage and its soft glow must be transparent.
Subject: A single empty circular petri-dish platform viewed from about 25–30 degrees above, so the circle reads as a very wide ellipse, approximately three times wider than its visible total height. The stage fills about 90 percent of the landscape canvas width and is centered. It has a substantial beveled glass rim with real thickness. The visible front side wall is darker and shaded, clearly giving the platform height. The smooth agar-gel top is inset inside the rim and contains exactly two faint concentric rings, echoing a microscopic arena floor.
Style/medium: Stylized chunky soft-3D cartoon rendering, polished premium mobile-game asset, clean graphic silhouette, subtle cel-shading, one global light from top-left, compatible with dark teal microscopic underwater game art.
Composition/framing: Landscape canvas. Center the stage horizontally and vertically, with generous fully transparent clearance on every side. Wide ellipse, width about 3x height. Nothing stands on the stage.
Lighting/mood: Bioluminescent cyan edge glow. Bright controlled specular streak along the top-left of the glass bevel. The front side is dark and weighty. A soft cyan outer glow is allowed but must smoothly fade to zero alpha well before every canvas edge.
Color palette: Glass edge #2FE8E0 cyan; gel top gradient from #12262C to #1A3942; faint arena rings #1A3942 with subtle cyan influence; deepest side shadows #04090B and #071012.
Materials/textures: Thick translucent glass, rounded beveled rim, smooth slightly glossy agar gel, crisp polished edge highlights.
Transparency requirement: Output must be RGBA PNG-like artwork with a truly transparent background, not white, black, gray, checkerboard, or a painted background. Preserve real alpha around the isolated stage and glow.
Constraints: Exactly one stage. Empty top. No character, creature, prop, pedestal base, legs, environment, ground plane, horizon, wall, or cast shadow on a backdrop.
Text: none.
Avoid: any text, letters, numbers, logos, watermark, signature, opaque background, checkerboard pattern, square crop, top-down circle, thin flat ring, busy gel texture, objects standing on it.
```