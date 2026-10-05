# Image slots

Drop PNG files at these paths. Anything missing shows a labelled placeholder, so the game always runs. Re-open the project in Godot after adding files so it imports them.

Pixel look: draw or export the art as pixel art (the game renders at 640x360 with nearest-neighbour filtering). Images are scaled by the game, so any size works, but keep the aspect ratios below.

## Level backgrounds (3 per level)

`assets/bg/levelN_start.png`, `levelN_mid.png`, `levelN_end.png` for N = 1 to 5 (15 files).

- Aspect 16:9. Recommended 640x360 (or 1280x720 and downscale to pixel art yourself).
- No characters in them. Keep the bottom sixth (about 60 px of 360) plain: the game draws its own ground there at y = 300.
- The strip scrolls left to right: `start` covers the first third of the level, `mid` the middle third, `end` the last third. Each is tiled and mirrored along its third, so make the left and right edges blend.
- The ink turns these grey automatically as it approaches.

## Story characters

`assets/chars/NAME.png`, transparent background, facing right (the game flips them when needed). Scaled to the height shown; width follows the image.

| File | Drawn height |
| ---- | ------------ |
| orpheus.png | 64 px |
| eurydice.png | 66 px |
| charon.png | 86 px |
| persephone.png | 66 px |
| hades.png | 96 px |
| cerberus.png | 44 px |
| shade.png | 64 px |
| deer.png | 48 px |
| bird.png | 24 px |

Characters stand with their feet at the bottom edge of the image, so crop tightly.

## Page thumbnails (one per strip on the comic page)

`assets/thumbs/level1.png` to `level5.png`. Ultra wide, roughly 12:1. Recommended 538x44 px (shown at that size).

## Title image (optional)

`assets/title.png`, 640x360. Replaces the plain cream title background; the BLEED logo and menu draw on top.

## Player sprites (already in)

`assets/chars/circle_grey.png` (player 1) and `circle_cyan.png` (player 2).
