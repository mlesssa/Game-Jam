extends Node2D
# Screen manager: owns the current screen and the zoom transition between the comic page and a strip.

var screen: Node
var layer: CanvasLayer
var ov: DrawProxy
var ov_rect := Rect2()
var ov_col := Color.BLACK
var ov_alpha := 0.0
var ov_on := false
var busy := false

func _ready() -> void:
	Game.main = self
	layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	ov = DrawProxy.new()
	ov.cb = Callable(self, "_draw_ov")
	layer.add_child(ov)
	_set_screen(load("res://scripts/title.gd").new())

func _draw_ov(c: CanvasItem) -> void:
	if not ov_on:
		return
	c.draw_rect(ov_rect, Color(ov_col.r, ov_col.g, ov_col.b, ov_alpha))
	c.draw_rect(ov_rect, Art.INK, false, 5.0)

func _set_screen(s: Node) -> void:
	if screen:
		screen.queue_free()
	screen = s
	add_child(s)
	move_child(s, 0)

func to_title() -> void:
	_set_screen(load("res://scripts/title.gd").new())

func to_page(zoom_back := false, from_idx := -1) -> void:
	var p: Node = load("res://scripts/page.gd").new()
	_set_screen(p)
	if zoom_back and from_idx >= 0:
		p.pulse = from_idx + 1
		ov_on = true
		ov_col = _theme_col(from_idx)
		ov_alpha = 1.0
		busy = true
		var tw := create_tween()
		tw.tween_method(func(v: float): ov_rect = _lerp_rect(Game.strip_rect(from_idx), Rect2(0, 0, 640, 360), v), 1.0, 0.0, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tw.tween_callback(func():
			ov_on = false
			busy = false)

func _lerp_rect(a: Rect2, b: Rect2, v: float) -> Rect2:
	return Rect2(a.position.lerp(b.position, v), a.size.lerp(b.size, v))

func _theme_col(i: int) -> Color:
	return [Color("8fd3f0"), Color("3d2f5c"), Color("2c5a6a"), Color("6a2a4a"), Color("c9a98a")][i]

func start_level(i: int) -> void:
	if busy:
		return
	busy = true
	Game.current = i
	ov_on = true
	ov_col = _theme_col(i)
	ov_alpha = 1.0
	var tw := create_tween()
	tw.tween_method(func(v: float): ov_rect = _lerp_rect(Game.strip_rect(i), Rect2(0, 0, 640, 360), v), 0.0, 1.0, 0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		var lv: Node = load("res://scripts/level.gd").new()
		_set_screen(lv)
		lv.setup(i))
	tw.tween_property(self, "ov_alpha", 0.0, 0.4)
	tw.tween_callback(func():
		ov_on = false
		busy = false)

func finish_level(i: int) -> void:
	if busy:
		return
	Game.complete(i)
	if i + 1 >= Game.LEVEL_COUNT:
		_set_screen(load("res://scripts/ending.gd").new())
	else:
		to_page(true, i)
