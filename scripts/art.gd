class_name Art
# Shared procedural drawing: palette, plague tint, comic characters, speech bubbles.

const INK := Color(0.082, 0.067, 0.11)
const PAPER := Color(0.965, 0.933, 0.859)
const YELLOW := Color(1.0, 0.847, 0.29)
const SHADOW := Color(0.788, 0.725, 0.561)

# Drain colour toward grey. a = 0 untouched, a = 1 fully plagued.
static func g(c: Color, a: float) -> Color:
	if a <= 0.0:
		return c
	var l := c.get_luminance()
	return c.lerp(Color(l, l, l, c.a), a).darkened(0.22 * a)

static func ellipse(c: CanvasItem, p: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(p + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)

static func poly(c: CanvasItem, pts: Array, col: Color) -> void:
	var v := PackedVector2Array(pts)
	c.draw_colored_polygon(v, col)
	v.append(v[0])
	c.draw_polyline(v, INK, 1.5)

static func head(c: CanvasItem, p: Vector2, r: float, skin: Color, hair: Color) -> void:
	c.draw_circle(p, r + 1.2, INK)
	c.draw_circle(p, r, hair)
	c.draw_circle(p + Vector2(0, 1.6), r - 1.6, skin)
	c.draw_circle(p + Vector2(-2.6, 1.6), 0.9, INK)
	c.draw_circle(p + Vector2(2.6, 1.6), 0.9, INK)

static func robe(c: CanvasItem, x: float, y: float, w: float, h: float, col: Color) -> void:
	poly(c, [Vector2(x - w, y), Vector2(x + w, y), Vector2(x + w * 0.5, y - h), Vector2(x - w * 0.5, y - h)], col)

# Draws a story character standing at feet position (x, y). a = plague amount 0..1.
static func figure(c: CanvasItem, kind: String, x: float, y: float, t: float, a: float, flip := false) -> void:
	var f := -1.0 if flip else 1.0
	var bob := sin(t * 2.0 + x * 0.1) * 1.0
	y += 0.0
	match kind:
		"orpheus":
			robe(c, x, y, 15, 44, g(Color("c8553d"), a))
			head(c, Vector2(x, y - 53 + bob), 8, g(Color("e9b98f"), a), g(Color("5a3a22"), a))
			var lc := g(Color("f2c14e"), a)
			var lp := Vector2(x + f * 15, y - 26)
			c.draw_arc(lp, 8, 0, PI, 12, lc, 2.5)
			c.draw_line(lp + Vector2(-8, 0), lp + Vector2(8, 0), lc, 2.5)
			c.draw_line(lp + Vector2(0, 0), lp + Vector2(0, 7), lc, 1.0)
		"eurydice":
			robe(c, x, y, 14, 46, g(Color("f4f1e6"), a))
			c.draw_rect(Rect2(x - 9, y - 30, 18, 3), g(Color("2bb3c9"), a))
			head(c, Vector2(x, y - 55 + bob), 8, g(Color("e9b98f"), a), g(Color("2a1a14"), a))
			c.draw_circle(Vector2(x + f * 6, y - 62 + bob), 2.5, g(Color("ff5a36"), a))
		"charon":
			robe(c, x, y, 17, 62, g(Color("2b2540"), a))
			poly(c, [Vector2(x - 9, y - 58), Vector2(x, y - 76), Vector2(x + 9, y - 58)], g(Color("1a1626"), a))
			c.draw_circle(Vector2(x, y - 62), 4, g(Color("c9c3d6"), a))
			c.draw_line(Vector2(x + f * 20, y + 4), Vector2(x + f * 20, y - 84), INK, 2.5)
			c.draw_circle(Vector2(x + f * 20, y - 80), 4 + sin(t * 5) * 0.5, g(Color("ffd84a"), a))
		"persephone":
			robe(c, x, y, 14, 46, g(Color("4fa05a"), a))
			head(c, Vector2(x, y - 55 + bob), 8, g(Color("e9b98f"), a), g(Color("7a3b2a"), a))
			for i in 4:
				c.draw_circle(Vector2(x - 6 + i * 4, y - 63 + bob), 2.2, g(Color("ff7aa8"), a))
		"hades":
			robe(c, x, y, 18, 66, g(Color("4a2a6a"), a))
			head(c, Vector2(x, y - 76 + bob), 9, g(Color("c7b9d6"), a), g(Color("1a1626"), a))
			var cr := g(Color("ffd84a"), a)
			poly(c, [Vector2(x - 9, y - 86), Vector2(x - 6, y - 96), Vector2(x - 2, y - 88), Vector2(x + 2, y - 98),
				Vector2(x + 6, y - 88), Vector2(x + 9, y - 96), Vector2(x + 10, y - 86)], cr)
		"cerberus":
			ellipse(c, Vector2(x, y - 14), 22, 14, g(Color("3a2a2a"), a))
			for i in 3:
				var hp := Vector2(x - 17 + i * 17, y - 26 - (0 if i % 2 == 0 else 6) + sin(t * 1.5 + i) * 1.0)
				c.draw_circle(hp, 8, INK)
				c.draw_circle(hp, 6.6, g(Color("5a3a38"), a))
				c.draw_line(hp + Vector2(-3, -1), hp + Vector2(-1, -1), INK, 1.5)
				c.draw_line(hp + Vector2(1, -1), hp + Vector2(3, -1), INK, 1.5)
			c.draw_string(ThemeDB.fallback_font, Vector2(x + 18, y - 38 - fmod(t * 6.0, 6.0)), "z", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, g(Color.WHITE, a))
		"deer":
			ellipse(c, Vector2(x, y - 20), 16, 8, g(Color("b07a45"), a))
			for lx in [-10, -4, 6, 12]:
				c.draw_line(Vector2(x + lx, y - 14), Vector2(x + lx, y), g(Color("8a5a30"), a), 2.0)
			c.draw_line(Vector2(x + f * 12, y - 24), Vector2(x + f * 18, y - 36), g(Color("b07a45"), a), 4.0)
			c.draw_circle(Vector2(x + f * 19, y - 38), 4.5, g(Color("b07a45"), a))
			c.draw_line(Vector2(x + f * 19, y - 42), Vector2(x + f * 24, y - 52), INK, 1.5)
			c.draw_line(Vector2(x + f * 19, y - 42), Vector2(x + f * 14, y - 52), INK, 1.5)
		"bird":
			var fl := sin(t * 9.0 + x) * 4.0
			var bc := g(Color("2bb3c9"), a)
			c.draw_circle(Vector2(x, y - 60 + bob), 4, bc)
			c.draw_line(Vector2(x, y - 60 + bob), Vector2(x - 8, y - 64 + fl + bob), bc, 2.0)
			c.draw_line(Vector2(x, y - 60 + bob), Vector2(x + 8, y - 64 + fl + bob), bc, 2.0)
		"shade":
			var sc := Color(0.75, 0.85, 1.0, 0.55)
			sc = g(sc, a)
			ellipse(c, Vector2(x, y - 50 + bob), 9, 11, sc)
			poly(c, [Vector2(x - 9, y - 50), Vector2(x + 9, y - 50), Vector2(x + 11, y - 8 + sin(t * 3) * 3),
				Vector2(x + 4, y - 14), Vector2(x, y - 6), Vector2(x - 4, y - 14), Vector2(x - 11, y - 8 - sin(t * 3) * 3)], sc)
			c.draw_circle(Vector2(x - 3, y - 52 + bob), 1.5, INK)
			c.draw_circle(Vector2(x + 3, y - 52 + bob), 1.5, INK)

# Comic speech bubble. center_x is the bubble centre; bottom is its lower edge; tail_to is the speaker's head.
static func bubble(c: CanvasItem, text: String, rect: Rect2, tail_to: Vector2, twisted: bool, t: float, alpha := 1.0, size := 12, dots := false) -> void:
	var font: Font = Game.font_hand
	var fill := Color(1, 1, 1, alpha)
	var edge := INK
	var txt := INK
	var off := Vector2.ZERO
	if twisted:
		fill = Color(0.2, 0.18, 0.22, alpha)
		edge = Color(0.75, 0.1, 0.12, alpha)
		txt = Color(0.95, 0.9, 0.9, alpha)
		off = Vector2(sin(t * 47.0), cos(t * 53.0)) * 0.7
	var tx := clampf(tail_to.x, rect.position.x + 14, rect.end.x - 14)
	var tail := PackedVector2Array([Vector2(tx - 7, rect.end.y - 1), Vector2(tx + 7, rect.end.y - 1), tail_to])
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(2)
	sb.border_color = Color(edge.r, edge.g, edge.b, alpha)
	sb.set_corner_radius_all(12 if not twisted else 3)
	var ec := Color(edge.r, edge.g, edge.b, alpha)
	if dots:
		var st := Vector2(tx, rect.end.y + 3.0)
		for k in 5:
			var dp := st.lerp(tail_to, (k + 0.5) / 5.5)
			var dr := lerpf(4.0, 1.8, k / 4.0)
			c.draw_circle(dp, dr + 1.3, ec)
			c.draw_circle(dp, dr, fill)
	else:
		c.draw_colored_polygon(tail, fill)
		c.draw_polyline(PackedVector2Array([tail[0], tail[2], tail[1]]), ec, 2.0)
	c.draw_style_box(sb, rect)
	c.draw_multiline_string(font, rect.position + Vector2(8, 3 + size * 1.05) + off, text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, size, -1, txt)
	if twisted:
		for i in 6:
			var px := rect.position.x + 6 + i * (rect.size.x - 12) / 5.0
			c.draw_line(Vector2(px, rect.position.y - 2), Vector2(px + 3, rect.position.y - 6 - (i % 2) * 2), edge, 2.0)

static func text_size(text: String, w: float, size := 12) -> Vector2:
	return Game.font_hand.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, w, size)

# Yellow narrator caption.
static func caption(c: CanvasItem, text: String, rect: Rect2, size := 12, alpha := 1.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(YELLOW.r, YELLOW.g, YELLOW.b, alpha)
	sb.set_border_width_all(3)
	sb.border_color = Color(INK.r, INK.g, INK.b, alpha)
	sb.shadow_color = Color(0, 0, 0, 0.35 * alpha)
	sb.shadow_offset = Vector2(3, 3)
	c.draw_style_box(sb, rect)
	c.draw_multiline_string(Game.font_hand, rect.position + Vector2(10, 17), text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 20, size, -1, Color(INK.r, INK.g, INK.b, alpha))

# Little comic panel used for platforms.
static func panel(c: CanvasItem, r: Rect2, fill: Color, accent: Color, a: float, seed_i := 0) -> void:
	c.draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.3))
	c.draw_rect(r, INK)
	var inner := r.grow(-3)
	c.draw_rect(inner, g(fill, a))
	var s := seed_i % 3
	if s == 0:
		c.draw_colored_polygon(PackedVector2Array([inner.position, inner.position + Vector2(inner.size.x * 0.5, 0), inner.position + Vector2(0, inner.size.y)]), g(accent, a))
	elif s == 1:
		c.draw_circle(inner.get_center(), minf(inner.size.x, inner.size.y) * 0.28, g(accent, a))
	else:
		for i in int(inner.size.x / 8):
			c.draw_line(Vector2(inner.position.x + 4 + i * 8, inner.end.y), Vector2(inner.position.x + 10 + i * 8, inner.position.y), g(accent, a), 2.0)
