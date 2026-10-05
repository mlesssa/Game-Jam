extends Node2D
# Title screen: pick two-player co-op or solo (swap notes).

var sel := 0
var t := 0.0
var items := ["TWO PLAYERS  (CO-OP)", "SOLO  (SWAP NOTES)"]
var tex_a: Texture2D
var tex_b: Texture2D

func _ready() -> void:
	tex_a = load("res://assets/chars/circle_grey.png")
	tex_b = load("res://assets/chars/circle_cyan.png")
	sel = 0 if Game.mode == "coop" else 1

func item_rect(i: int) -> Rect2:
	return Rect2(190, 214 + i * 42, 260, 34)

func _process(dt: float) -> void:
	t += dt
	queue_redraw()

func _unhandled_input(e: InputEvent) -> void:
	Sfx.start_music()
	if e.is_action_pressed("ui_up") or e.is_action_pressed("ui_down"):
		sel = 1 - sel
		Sfx.play("ui_move")
	elif e.is_action_pressed("accept"):
		_go()
	elif e is InputEventMouseMotion:
		for i in 2:
			if item_rect(i).has_point(e.position) and sel != i:
				sel = i
				Sfx.play("ui_move")
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in 2:
			if item_rect(i).has_point(e.position):
				sel = i
				_go()

func _go() -> void:
	Game.mode = "coop" if sel == 0 else "solo"
	Game.solo_active = 0
	Sfx.play("ui_select")
	Game.main.to_page()

func _draw() -> void:
	var bgt := Slots.tex("res://assets/title.png")
	if bgt:
		draw_texture_rect(bgt, Rect2(0, 0, 640, 360), false)
	else:
		draw_rect(Rect2(0, 0, 640, 360), Art.PAPER)
	# creeping ink on the left
	var pts := PackedVector2Array([Vector2(-10, -10)])
	var y := -10.0
	while y <= 370.0:
		pts.append(Vector2(34 + sin(t * 1.3 + y * 0.05) * 6.0 + maxf(0.0, sin(y * 0.03 + 1.0)) * 24.0, y))
		y += 10.0
	pts.append(Vector2(-10, 370))
	draw_colored_polygon(pts, Art.INK)
	# logo
	var f: Font = Game.font
	var lw: float = f.get_string_size("BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 72).x
	var lx := 320.0 - lw * 0.5
	for o in [Vector2(4, 4), Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_string(f, Vector2(lx, 120) + o, "BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Art.INK)
	draw_string(f, Vector2(lx, 120), "BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color("ff5a36"))
	for k in 5:
		var dx := lx + 14.0 + k * (lw / 5.0)
		var dl := 6.0 + floorf((sin(t * 2.0 + k * 1.7) + 1.0) * 4.0)
		draw_rect(Rect2(dx, 124, 4, dl), Art.INK)
	var sub := "Two notes of a lyre. One comic page. Keep the light alive."
	draw_string(Game.font_hand, Vector2(320 - Game.font_hand.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x * 0.5, 170), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Art.INK)
	# the two notes
	for k in 2:
		var tx := tex_a if k == 0 else tex_b
		var cx := 70.0 if k == 0 else 570.0
		var by := 200.0 + sin(t * 2.5 + k * 1.5) * 6.0
		if k == 1:
			for r in 3:
				draw_circle(Vector2(cx, by - 20), 52.0 - r * 14.0, Color(0.45, 0.95, 1, 0.12))
		draw_texture_rect(tx, Rect2(cx - 28, by - 56, 56, 56), false)
	# menu
	for i in 2:
		var r := item_rect(i)
		var on := sel == i
		draw_rect(Rect2(r.position + Vector2(4, 4), r.size), Color(0, 0, 0, 0.3))
		draw_rect(r, Art.INK)
		draw_rect(r.grow(-3), Art.YELLOW if on else Art.PAPER)
		var tw: float = Game.font.get_string_size(items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(Game.font, Vector2(r.position.x + (r.size.x - tw) * 0.5, r.position.y + 22), items[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Art.INK)
