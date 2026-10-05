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
	c.draw_multiline_string(font, rect.position + Vector2(8, 2 + size) + off, text, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 16, size, -1, txt)
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
