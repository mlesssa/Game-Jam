extends Node2D
# The comic page: five strips, one per level. Pick one to zoom in.

var sel := 0
var t := 0.0
var pulse := -1
var pulse_t := 0.0

func _ready() -> void:
	sel = clampi(Game.unlocked - 1, 0, Game.LEVEL_COUNT - 1)
	for i in Game.LEVEL_COUNT:
		if i < Game.unlocked and not Game.done[i]:
			sel = i
			break

func _process(dt: float) -> void:
	t += dt
	if pulse >= 0:
		pulse_t += dt
	queue_redraw()

func _unhandled_input(e: InputEvent) -> void:
	if Game.main.busy:
		return
	Sfx.start_music()
	if e.is_action_pressed("ui_up"):
		sel = maxi(0, sel - 1)
		Sfx.play("ui_move")
	elif e.is_action_pressed("ui_down"):
		sel = mini(Game.unlocked - 1, sel + 1)
		Sfx.play("ui_move")
	elif e.is_action_pressed("accept"):
		_enter()
	elif e.is_action_pressed("pause"):
		Game.main.to_title()
	elif e is InputEventMouseMotion:
		for i in Game.LEVEL_COUNT:
			if i < Game.unlocked and Game.strip_rect(i).has_point(e.position) and sel != i:
				sel = i
				Sfx.play("ui_move")
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in Game.LEVEL_COUNT:
			if i < Game.unlocked and Game.strip_rect(i).has_point(e.position):
				sel = i
				_enter()

func _enter() -> void:
	if sel < Game.unlocked:
		Sfx.play("ui_select")
		Game.main.start_level(sel)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(0.2, 0.17, 0.22))
	draw_rect(Rect2(14, 6, 612, 348), Art.SHADOW)
	draw_rect(Rect2(10, 2, 612, 348), Art.PAPER)
	var f: Font = Game.font
	draw_string(f, Vector2(50, 34), "BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ff5a36"))
	draw_string(f, Vector2(48, 32), "BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Art.INK)
	draw_string(f, Vector2(50, 32), "BLEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ff5a36"))
	var hint := "W / S choose     Enter play     Esc title"
	draw_string(Game.font_hand, Vector2(592 - Game.font_hand.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, 30), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Art.INK)
	for i in Game.LEVEL_COUNT:
		_strip(i)
	var done_n := 0
	for d in Game.done:
		if d:
			done_n += 1
	draw_string(Game.font_hand, Vector2(50, 344), "Panels saved: %d / %d     Splats: %d" % [done_n, Game.LEVEL_COUNT, Game.total_deaths], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Art.INK)

func _strip(i: int) -> void:
	var data: Dictionary = Levels.all()[i] if _cache.size() <= i else _cache[i]
	if _cache.size() <= i:
		_cache.append(data)
	var r := Game.strip_rect(i)
	var locked := i >= Game.unlocked
	var on := sel == i
	if i == pulse:
		var k := clampf(1.0 - pulse_t, 0.0, 1.0)
		r = r.grow(sin(pulse_t * 12.0) * 3.0 * k)
	if on:
		r = r.grow(3)
	var th: String = data.theme
	var tp: Dictionary = Backdrop.TH[th]
	draw_rect(Rect2(r.position + Vector2(3, 3), r.size), Color(0, 0, 0, 0.25))
	draw_rect(r, Art.INK)
	var inner := r.grow(-3)
	draw_polygon(PackedVector2Array([inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]),
		PackedColorArray([tp.top, tp.top, tp.bot, tp.bot]))
	# hills
	var hp := PackedVector2Array([Vector2(inner.position.x, inner.end.y)])
	var x := inner.position.x
	while x <= inner.end.x:
		hp.append(Vector2(x, inner.end.y - 12.0 - 8.0 * (sin(x * 0.03 + i) + 0.5 * sin(x * 0.07))))
		x += 8.0
	hp.append(Vector2(inner.end.x, inner.end.y))
	draw_colored_polygon(hp, tp.mid)
	draw_rect(Rect2(inner.position.x, inner.end.y - 5, inner.size.x, 5), Color(0.1, 0.08, 0.12, 0.5))
	# the story, in miniature
	var kinds: Array = data.thumb
	for k in kinds.size():
		var px := inner.position.x + inner.size.x * (0.3 + 0.17 * k) + (30.0 if kinds.size() == 2 else 0.0)
		draw_set_transform(Vector2(px, inner.end.y - 4), 0, Vector2(0.42, 0.42))
		Art.figure(self, kinds[k], 0.0, 0.0, t, 0.0, k % 2 == 1)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# the plague creeps in from the left, further each page
	var ink_w := 10.0 + i * 14.0
	if Game.done[i]:
		ink_w = 4.0
	var ip := PackedVector2Array([inner.position, inner.position + Vector2(ink_w, 0)])
	var yy := inner.position.y
	while yy <= inner.end.y:
		ip.append(Vector2(inner.position.x + ink_w + sin(t * 1.5 + yy * 0.3) * 3.0 + maxf(0.0, sin(yy * 0.4 + i)) * 6.0, yy))
		yy += 6.0
	ip.append(Vector2(inner.position.x, inner.end.y))
	draw_colored_polygon(ip, Art.INK)
	# title caption
	var txt := ("%s. %s" % [data.roman, data.title]) if not locked else "%s. ???" % data.roman
	var cw: float = Game.font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12.0
	draw_rect(Rect2(inner.position.x + 22, inner.position.y + 2, cw, 18), Art.YELLOW)
	draw_rect(Rect2(inner.position.x + 22, inner.position.y + 2, cw, 18), Art.INK, false, 2.0)
	draw_string(Game.font, Vector2(inner.position.x + 28, inner.position.y + 16), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Art.INK)
	if locked:
		draw_rect(inner, Color(0.08, 0.07, 0.1, 0.82))
		draw_string(Game.font, Vector2(inner.position.x + inner.size.x * 0.5 - 40, inner.position.y + 38), "NOT YET...", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.6, 0.6, 0.65))
		draw_rect(Rect2(inner.position.x + 22, inner.position.y + 2, cw, 18), Color(0.08, 0.07, 0.1, 0.82))
	elif Game.done[i]:
		var c := Vector2(inner.end.x - 20, inner.position.y + 18)
		draw_circle(c, 12, Color("5fbf5a"))
		draw_polyline(PackedVector2Array([c + Vector2(-5, 0), c + Vector2(-1, 4), c + Vector2(6, -5)]), Art.INK, 3.0)
	if on:
		draw_rect(r, Art.YELLOW, false, 3.0)

var _cache: Array = []
