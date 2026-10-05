# Bleed

A one-page comic you play. Two little circles, the notes of Orpheus' lyre, walk through five comic strips to help him bring Eurydice home, while black ink bleeds across the page behind them, drains the colour and twists Orpheus' words into something cruel.

Made for the TGC Game Jam. Themes: **Comic, Twist, Light**.

- **itch.io page:** _link added at submission_
- **Engine:** Godot 4.7.2, GDScript, Compatibility renderer, HTML5 web export
- **Play time:** about 10 to 15 minutes

## How to play

Pick **Two players** (co-op on one keyboard) or **Solo** (you control one note and swap to the other). On the comic page, choose a strip and zoom into it. Each strip is a left to right sidescroller. Reach the light at the end with **both** notes. Finish a strip and the next one unlocks.

- Panels are platforms. Hop on caption boxes, duck under low panels, jump pits.
- Ink creeps in from the left. Touching it, or a flying drop of it, sends you back to the last lantern.
- Lanterns save your place and push the ink back.
- Plates open gates and make bridges, but only while a note stands on them. One note holds, the other goes through, then you swap.
- Landing on the other note's head bounces you much higher. Some plates are on ledges that need it.
- When the ink covers Orpheus' speech bubble, his words turn on him.

## Controls

| Action | Player 1 | Player 2 | Solo |
| ------ | -------- | -------- | ---- |
| Move | A / D | Left / Right | A D or arrows |
| Jump | W or Space | Up | W, Up or Space |
| Duck | S | Down | S or Down |
| Swap note | | | Q or Tab |
| Retry from lantern | R | | |
| Back to the page | Esc | | |

## Setup / run

1. Install [Godot 4.7.2](https://godotengine.org/download) (standard build, not .NET).
2. Open `project.godot` in Godot and press **F5**.
3. Web build: Project > Export > Web (single-threaded, thread support off), then zip the export folder for itch.io.

Tests (optional): `godot --headless -s tools/bot.gd` plays all five levels with a scripted pair of notes to prove they are solvable. `tools/gen_audio.py` regenerates all sounds and the music loop.

## How it is made

Everything is drawn in code (backdrops, characters, panels, ink) except the two player sprites and the fonts. Levels are plain data in `scripts/levels.gd`. See [CREDITS.md](CREDITS.md) for fonts and the full AI disclosure.

## Team

Team details are in `proposal.pdf`. Licensed under the [MIT License](LICENSE).
