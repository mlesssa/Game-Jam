extends Node2D
# The last page: the light wins, and the two notes keep playing.

var t := 0.0
var tex_a: Texture2D
var tex_b: Texture2D
const LINES := [
	[0.5, "At the last step, the ink whispered. Orpheus turned."],
	[6.5, "And the page went quiet."],
	[12.5, "But two little notes kept playing."],
	[18.5, "A song cannot bring back what is gone. But it can carry it home."]]

func _ready() -> void:
	tex_a = load("res://assets/chars/circle_grey.png")
	tex_b = load("res://assets/chars/circle_cyan.png")

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _unhandled_input(e: InputEvent) -> void:
	if t > 4.0 and (e.is_action_pressed("accept") or e.is_action_pressed("pause")):
		Game.main.to_title()

func _draw() -> void:
	var k := clampf((t - 10.0) / 14.0, 0.0, 1.0)
	var top := Color(0.1, 0.1, 0.12).lerp(Color("8fd3f0"), k)
	var bot := Color(0.2, 0.2, 0.22).lerp(Color("fff1c9"), k)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(640, 0), Vector2(640, 360), Vector2(0, 360)]), PackedColorArray([top, top, bot, bot]))
	for r in 5:
		draw_circle(Vector2(320, 180), 20.0 + k * 230.0 - r * 30.0 * k, Color(1, 0.95, 0.7, 0.10))
	# the ink pulls back
	var ink_x := lerpf(380.0, -120.0, clampf((t - 11.0) / 6.0, 0.0, 1.0))
	var pts := PackedVector2Array([Vector2(-10, -10)])
	var y := -10.0
	while y <= 370.0:
		pts.append(Vector2(ink_x + sin(t * 1.6 + y * 0.07) * 8.0, y))
		y += 10.0
	pts.append(Vector2(-10, 370))
	draw_colored_polygon(pts, Art.INK)
	var by := 238.0
	for n in 2:
		var cx := 292.0 + n * 56.0
		var bob := sin(t * 2.0 + n * 1.4) * 4.0
		if n == 1:
			for r in 3:
				draw_circle(Vector2(cx, by - 26 + bob), 50.0 - r * 14.0, Color(0.45, 0.95, 1, 0.18))
		draw_texture_rect(tex_a if n == 0 else tex_b, Rect2(cx - 24, by - 48 + bob, 48, 48), false)
	draw_rect(Rect2(0, 296, 640, 64), Color("5cae4c").lerp(Color(0.25, 0.25, 0.25), 1.0 - k))
	draw_rect(Rect2(0, 296, 640, 3), Art.INK)
	var txt := ""
	for l in LINES:
		if t >= l[0]:
			txt = l[1]
	if txt != "":
		Art.caption(self, txt, Rect2(80, 24, 480, 52), 14)
	if t > 25.0:
		var a := clampf((t - 25.0) / 1.5, 0.0, 1.0)
		draw_string(Game.font, Vector2(206, 150), "THE END", HORIZONTAL_ALIGNMENT_LEFT, -1, 74, Color(Art.INK.r, Art.INK.g, Art.INK.b, a))
		draw_string(Game.font_hand, Vector2(214, 330), "Thanks for playing.  Press Enter for the title.", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, a))
