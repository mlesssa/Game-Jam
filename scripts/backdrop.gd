class_name Backdrop
# Level background. Three image slots per level (start, middle, end of the strip) are tiled along the level.
# Missing images show a labelled placeholder. Drawn in screen space from the camera position.

const TILE := 640.0
const ZONES := ["start", "mid", "end"]
# placeholder colours only (and thumbnails); no art is drawn here
const TH := {
	"meadow": {"top": Color("5a7fa0"), "bot": Color("8aa07a")},
	"cave": {"top": Color("1d1730"), "bot": Color("3d2f5c")},
	"river": {"top": Color("0f2a3a"), "bot": Color("2c5a6a")},
	"hall": {"top": Color("2a0f24"), "bot": Color("6a2a4a")},
	"climb": {"top": Color("2a2a4a"), "bot": Color("8a7a70")}}

static func draw(c: CanvasItem, level_idx: int, theme: String, left: float, length: float) -> void:
	var th: Dictionary = TH[theme]
	var n0 := int(floorf(left / TILE))
	for n in range(n0, n0 + 3):
		var sx := roundf(n * TILE - left)
		var frac := clampf((n * TILE + TILE * 0.5) / length, 0.0, 0.999)
		var zone: String = ZONES[int(frac * 3.0)]
		var tx := Slots.tex("res://assets/bg/level%d_%s.png" % [level_idx + 1, zone])
		if tx:
			if n % 2 == 0:
				c.draw_texture_rect(tx, Rect2(sx, 0, TILE, 360), false)
			else:
				c.draw_texture_rect(tx, Rect2(sx + TILE, 0, -TILE, 360), false)
		else:
			var k := 0.0 if zone == "start" else (-0.12 if zone == "mid" else 0.12)
			var top: Color = (th.top as Color).lightened(maxf(k, 0.0)).darkened(maxf(-k, 0.0))
			var bot: Color = (th.bot as Color).lightened(maxf(k, 0.0)).darkened(maxf(-k, 0.0))
			c.draw_polygon(PackedVector2Array([Vector2(sx, 0), Vector2(sx + TILE, 0), Vector2(sx + TILE, 360), Vector2(sx, 360)]), PackedColorArray([top, top, bot, bot]))
			c.draw_rect(Rect2(sx, 0, 2, 360), Color(1, 1, 1, 0.15))
			var label := "level%d_%s.png" % [level_idx + 1, zone]
			var w: float = Game.font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			c.draw_string(Game.font, Vector2(sx + TILE * 0.5 - w * 0.5, 150), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.55))
