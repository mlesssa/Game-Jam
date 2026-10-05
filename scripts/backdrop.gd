class_name Backdrop
# Parallax scenery for each level theme. Everything is drawn in screen space from the camera position.

const HALO := 220.0
const TH := {
	"meadow": {"top": Color("8fd3f0"), "bot": Color("fff1c9"), "far": Color("9fc9a0"), "mid": Color("6eae67")},
	"cave": {"top": Color("1d1730"), "bot": Color("3d2f5c"), "far": Color("2c2342"), "mid": Color("3a2e57")},
	"river": {"top": Color("0f2a3a"), "bot": Color("2c5a6a"), "far": Color("1b3f4f"), "mid": Color("244d5f")},
	"hall": {"top": Color("2a0f24"), "bot": Color("6a2a4a"), "far": Color("3d1730"), "mid": Color("4c1f3c")},
	"climb": {"top": Color("2a2a4a"), "bot": Color("c9a98a"), "far": Color("4a4565"), "mid": Color("6a5a70")}}

static func tint(col: Color, wx: float, ink_x: float) -> Color:
	return Art.g(col, clampf(1.0 - (wx - ink_x) / HALO, 0.0, 1.0))

static func hash(i: float) -> float:
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)

static func hills(c: CanvasItem, left: float, ink_x: float, base: float, amp: float, freq: float, factor: float, col: Color) -> void:
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var sx := -16.0
	while sx <= 656.0:
		var u := sx + left * factor
		var y := base - amp * (sin(u * freq) + 0.5 * sin(u * freq * 2.3 + 1.7) + 0.6)
		pts.append(Vector2(sx, y))
		cols.append(tint(col, sx + left, ink_x))
		sx += 16.0
	pts.append(Vector2(656, 380))
	cols.append(cols[cols.size() - 1])
	pts.append(Vector2(-16, 380))
	cols.append(cols[0])
	c.draw_polygon(pts, cols)

static func draw(c: CanvasItem, theme: String, left: float, ink_x: float, t: float, prog: float) -> void:
	var th: Dictionary = TH[theme]
	var bot: Color = th.bot
	if theme == "climb":
		bot = bot.lerp(Color("fff3c0"), prog)
	for i in 10:
		var x0 := i * 64.0
		var ca: Color = tint(th.top, x0 + left, ink_x)
		var cb: Color = tint(bot, x0 + left, ink_x)
		var ca2: Color = tint(th.top, x0 + 64 + left, ink_x)
		var cb2: Color = tint(bot, x0 + 64 + left, ink_x)
		c.draw_polygon(PackedVector2Array([Vector2(x0, 0), Vector2(x0 + 65, 0), Vector2(x0 + 65, 360), Vector2(x0, 360)]), PackedColorArray([ca, ca2, cb2, cb]))
	match theme:
		"meadow":
			var sx := 500.0 - left * 0.03
			c.draw_circle(Vector2(sx, 70), 46, tint(Color(1, 0.95, 0.6, 0.25), sx + left, ink_x))
			c.draw_circle(Vector2(sx, 70), 28, tint(Color("ffd84a"), sx + left, ink_x))
		"cave", "hall":
			for i in 16:
				var wx := i * 83.0 + hash(i) * 40.0
				var sx2 := fposmod(wx - left * 0.3, 1330.0) - 60.0
				c.draw_circle(Vector2(sx2, 40 + hash(i + 5) * 200), 1.5 + hash(i + 9) * 1.5, tint(Color(1, 0.9, 0.6, 0.6), sx2 + left, ink_x))
		"river":
			var mx := 520.0 - left * 0.02
			c.draw_circle(Vector2(mx, 60), 22, tint(Color("e6f2ff"), mx + left, ink_x))
		"climb":
			var lx := 560.0
			var r := 30.0 + prog * 150.0
			for k in 4:
				c.draw_circle(Vector2(lx, 110), r + (3 - k) * 24.0, Color(1, 0.95, 0.7, 0.10))
			c.draw_circle(Vector2(lx, 110), r * 0.55, Color(1, 1, 0.9, 0.9))
	hills(c, left, ink_x, 215.0, 30.0, 0.006, 0.15, th.far)
	hills(c, left, ink_x, 262.0, 22.0, 0.011, 0.35, th.mid)
	# mid-ground decoration (parallax 0.5)
	var i0 := int(floorf(left * 0.5 / 130.0)) - 1
	for i in range(i0, i0 + 8):
		var wx2 := i * 130.0 + hash(float(i)) * 60.0
		var sx3 := wx2 - left * 0.5
		var h := hash(float(i) + 3.3)
		var tc := sx3 + left
		match theme:
			"meadow":
				c.draw_rect(Rect2(sx3 - 4, 250 - h * 20, 8, 50 + h * 20), tint(Color("6b4a2e"), tc, ink_x))
				c.draw_circle(Vector2(sx3, 244 - h * 26), 24 + h * 10, tint(Color("3f8f46"), tc, ink_x))
				c.draw_circle(Vector2(sx3 + 14, 254 - h * 20), 16, tint(Color("4aa052"), tc, ink_x))
			"cave":
				var len := 40.0 + h * 90.0
				c.draw_colored_polygon(PackedVector2Array([Vector2(sx3 - 16, 0), Vector2(sx3 + 16, 0), Vector2(sx3, len)]), tint(Color("2a2140"), tc, ink_x))
				c.draw_colored_polygon(PackedVector2Array([Vector2(sx3 - 14, 300), Vector2(sx3 + 14, 300), Vector2(sx3, 300 - 20 - h * 40)]), tint(Color("352a52"), tc, ink_x))
				if h > 0.6:
					c.draw_circle(Vector2(sx3 + 24, 292), 3.0 + sin(t * 3 + i) * 0.8, tint(Color("5fe0ff"), tc, ink_x))
			"river":
				var yy := 276.0 + sin(t * 1.5 + i) * 2.0
				c.draw_line(Vector2(sx3 - 20, yy), Vector2(sx3 + 20, yy), tint(Color("6fb4c9"), tc, ink_x), 2.0)
				if h > 0.5:
					var ly := 200.0 + sin(t + i * 2.0) * 6.0
					c.draw_circle(Vector2(sx3, ly), 9, tint(Color(1, 0.85, 0.4, 0.3), tc, ink_x))
					c.draw_circle(Vector2(sx3, ly), 3.5, tint(Color("ffd84a"), tc, ink_x))
			"hall":
				c.draw_rect(Rect2(sx3 - 14, 0, 28, 300), tint(Color("3a1630"), tc, ink_x))
				c.draw_rect(Rect2(sx3 - 20, 0, 40, 14), tint(Color("5a2646"), tc, ink_x))
				c.draw_rect(Rect2(sx3 - 20, 270, 40, 14), tint(Color("5a2646"), tc, ink_x))
				if h > 0.5:
					var fl := 6.0 + sin(t * 9 + i) * 2.0
					c.draw_colored_polygon(PackedVector2Array([Vector2(sx3 - 6, 200), Vector2(sx3 + 6, 200), Vector2(sx3, 200 - 14 - fl)]), tint(Color("ff8a36"), tc, ink_x))
			"climb":
				c.draw_colored_polygon(PackedVector2Array([Vector2(sx3 - 30, 300), Vector2(sx3 - 8, 300 - 40 - h * 60), Vector2(sx3 + 26, 300)]), tint(Color("55496a"), tc, ink_x))
