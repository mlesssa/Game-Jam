extends Node2D
class_name Player
# One lyre note. Position is the feet. Collision is a custom AABB against the level's panels.

const W := 20.0
const RUN := 120.0
const GRAV := 900.0
const JUMP := 330.0
const BOUNCE := 490.0

var idx := 0
var lv
var vel := Vector2.ZERO
var on_floor := false
var ducking := false
var coyote := 0.0
var buf := 0.0
var facing := 1.0
var prev_y := 0.0
var tex: Texture2D
var t := 0.0
var squash := 0.0
var alive := true
var no_cut := false

func _ready() -> void:
	var path := "res://assets/chars/circle_grey.png" if idx == 0 else "res://assets/chars/circle_cyan.png"
	tex = load(path)

func height() -> float:
	return 14.0 if ducking else 22.0

func rect() -> Rect2:
	return Rect2(position.x - W * 0.5, position.y - height(), W, height())

func top() -> float:
	return position.y - height()

func step(dt: float) -> void:
	t += dt
	prev_y = position.y
	var inp: Dictionary = Game.read(idx)
	if lv.locked:
		inp = {"dx": 0.0, "jp": false, "jh": false, "duck": false}
	var target: float = inp.dx * (RUN * 0.5 if ducking else RUN)
	vel.x = move_toward(vel.x, target, (1500.0 if on_floor else 900.0) * dt)
	if inp.dx != 0.0:
		facing = signf(inp.dx)
	if on_floor and inp.duck:
		ducking = true
	elif ducking and not inp.duck and not lv.blocked(Rect2(position.x - W * 0.5, position.y - 22.0, W, 22.0)):
		ducking = false
	coyote = 0.1 if on_floor else maxf(0.0, coyote - dt)
	buf = 0.1 if inp.jp else maxf(0.0, buf - dt)
	if buf > 0.0 and coyote > 0.0 and not ducking:
		vel.y = -JUMP
		buf = 0.0
		coyote = 0.0
		on_floor = false
		squash = 0.25
		Sfx.play("jump", -6.0)
	vel.y = minf(vel.y + GRAV * dt, 620.0)
	if vel.y >= 0.0 or on_floor:
		no_cut = false
	if vel.y < 0.0 and not inp.jh and not no_cut:
		vel.y += 1500.0 * dt
	_move(dt)
	squash = move_toward(squash, 0.0, dt * 2.0)

func _move(dt: float) -> void:
	var solids: Array = lv.cur_solids
	position.x = clampf(position.x + vel.x * dt, 10.0, lv.length - 10.0)
	for s in solids:
		var r := rect()
		if r.intersects(s):
			if vel.x > 0.0 or (vel.x == 0.0 and position.x < s.get_center().x):
				position.x = s.position.x - W * 0.5
			else:
				position.x = s.end.x + W * 0.5
			vel.x = 0.0
	var was_floor := on_floor
	on_floor = false
	position.y += vel.y * dt
	for s in solids:
		var r := rect()
		if r.intersects(s):
			if vel.y >= 0.0 and prev_y <= s.position.y + 1.0:
				position.y = s.position.y
				vel.y = 0.0
				on_floor = true
			elif vel.y < 0.0:
				position.y = s.end.y + height()
				vel.y = 0.0
			else:
				# squeezed sideways into a wall edge; push up out of it
				position.y = s.position.y
				vel.y = 0.0
				on_floor = true
	for s in lv.oneways:
		var r := rect()
		if vel.y >= 0.0 and r.intersects(s) and prev_y <= s.position.y + 1.0:
			position.y = s.position.y
			vel.y = 0.0
			on_floor = true
	if on_floor and not was_floor:
		squash = -0.2

func bounce(power := BOUNCE) -> void:
	vel.y = -power
	no_cut = true
	on_floor = false
	squash = 0.3
	Sfx.play("bounce", -4.0)

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var active: bool = Game.mode == "coop" or Game.solo_active == idx
	var h := 24.0 * (0.58 if ducking else 1.0) * (1.0 + squash)
	var w := 24.0 * (1.15 if ducking else 1.0) * (1.0 - squash * 0.6)
	var centre := Vector2(0, -h * 0.5 + 2.0)
	var glow := Color(0.45, 0.95, 1.0) if idx == 1 else Color(1.0, 0.9, 0.7)
	var gs := 1.0 if active else 0.5
	for i in 3:
		draw_circle(centre, 46.0 - i * 13.0, Color(glow.r, glow.g, glow.b, 0.06 * gs))
	if tex:
		var tint := Color.WHITE if active else Color(0.75, 0.75, 0.8, 0.9)
		draw_texture_rect(tex, Rect2(-w * 0.5, -h + 2.0, w, h), false, tint)
	else:
		draw_circle(centre, 12, glow)
	if Game.mode == "solo" and active:
		var by := -h - 10.0 + sin(t * 6.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-5, by - 5), Vector2(5, by - 5), Vector2(0, by + 2)]), Art.YELLOW)
