extends Node2D
# One playable strip: a left-to-right sidescroller with two notes, panels, plates, ink and story layers.

const GY := 300.0
const HALO := 220.0
const HOLD := 0.45
const MAX_SPLIT := 560.0
const PLATE_COLS := [Color("ff5a36"), Color("2bb3c9"), Color("b36bd1"), Color("5fbf5a")]
const HEAD_Y := {"orpheus": 66, "eurydice": 68, "charon": 82, "persephone": 68, "hades": 98, "shade": 64}
const GROUND := {
	"meadow": [Color("5cae4c"), Color("6b4a2e")], "cave": [Color("6a5f8a"), Color("2b2338")],
	"river": [Color("8a6a40"), Color("2a2430")], "hall": [Color("8a3f58"), Color("2a1426")],
	"climb": [Color("c7b99a"), Color("5a4c44")]}
const ACCENT := {"meadow": Color("ffd84a"), "cave": Color("2bb3c9"), "river": Color("5fa8e0"), "hall": Color("ff5a36"), "climb": Color("ffe9a0")}

var idx := 0
var data: Dictionary
var length := 4000.0
var players: Array = []
var t := 0.0
var camx := 320.0
var ink_x := -260.0
var ink_on := false
var cp_i := -1
var cur_solids: Array = []
var static_solids: Array = []
var oneways: Array = []
var open_t := {}
var pressed := {}
var drops: Array = []
var drop_t := 4.0
var dead_t := 0.0
var locked := false
var finished := false
var fin_t := 0.0
var deaths := 0
var burst_t := 0.0
var burst_x := 0.0
var narr_i := 0
var queue: Array = []
var cur_text := ""
var cur_t := 0.0
var chat_i := 0
var chats: Array = []
var quipped := false
var world_top: DrawProxy
var hud: DrawProxy
var backdrop: DrawProxy

func cam_left() -> float:
	return camx - 320.0

func setup(i: int) -> void:
	idx = i
	data = Levels.all()[i]
	length = data.length
	for k in 4:
		open_t[k] = 0.0
	_build_static()
	var bl := CanvasLayer.new()
	bl.layer = -10
	add_child(bl)
	backdrop = DrawProxy.new()
	backdrop.cb = Callable(self, "_draw_backdrop")
	bl.add_child(backdrop)
	for k in 2:
		var p := Player.new()
		p.idx = k
		p.lv = self
		add_child(p)
		players.append(p)
	world_top = DrawProxy.new()
	world_top.cb = Callable(self, "_draw_top")
	add_child(world_top)
	var hl := CanvasLayer.new()
	hl.layer = 10
	add_child(hl)
	hud = DrawProxy.new()
	hud.cb = Callable(self, "_draw_hud")
	hl.add_child(hud)
	var cam := Camera2D.new()
	cam.position = Vector2(320, 180)
	add_child(cam)
	cam.make_current()
	_respawn()
	camx = 320.0
	_queue_narr_now()

func _build_static() -> void:
	static_solids.clear()
	oneways.clear()
	var edges: Array = [[0.0, length]]
	var pits: Array = data.pits.duplicate()
	pits.sort_custom(func(a, b): return a[0] < b[0])
	var x0 := -200.0
	for p in pits:
		static_solids.append(Rect2(x0, GY, p[0] - x0, 140))
		x0 = p[0] + p[1]
	static_solids.append(Rect2(x0, GY, length + 400.0 - x0, 140))
	for b in data.blocks:
		static_solids.append(Rect2(b[0], b[1], b[2], b[3]))
	for o in data.overs:
		static_solids.append(Rect2(o[0], -40, o[1], 322))
	for p in data.plats:
		oneways.append(Rect2(p[0], p[1], p[2], 12))
	chats = data.chat

func gate_open(id: int) -> bool:
	return open_t.get(id, 0.0) > 0.0

func blocked(r: Rect2) -> bool:
	for s in cur_solids:
		if r.intersects(s):
			return true
	return false

func gray(wx: float) -> float:
	return clampf(1.0 - (wx - ink_x) / HALO, 0.0, 1.0)

func lead_x() -> float:
	return maxf(players[0].position.x, players[1].position.x)

func rear_x() -> float:
	return minf(players[0].position.x, players[1].position.x)

# ------------------------------------------------------------ simulation
func _respawn() -> void:
	var x := 70.0 if cp_i < 0 else float(data.cps[cp_i])
	for k in 2:
		var p: Player = players[k]
		p.position = Vector2(x + (k * 2 - 1) * 14.0, GY)
		p.vel = Vector2.ZERO
		p.ducking = false
		p.on_floor = true
		p.prev_y = GY
	ink_x = -260.0 if cp_i < 0 else x - 380.0
	ink_on = cp_i >= 0
	drops.clear()
	drop_t = 3.0
	camx = clampf(x, 320.0, length - 320.0)
	for k in open_t.keys():
		open_t[k] = 0.0

func _physics_process(dt: float) -> void:
	t += dt
	if Input.is_action_just_pressed("pause"):
		Game.main.to_page(false)
		return
	if Input.is_action_just_pressed("skip") and OS.is_debug_build():
		_finish()
	if dead_t > 0.0:
		dead_t -= dt
		if dead_t <= 0.0:
			_respawn()
		_update_text(dt)
		return
	if Input.is_action_just_pressed("retry") and not finished:
		_respawn()
	if Game.mode == "solo" and Input.is_action_just_pressed("swap"):
		Game.solo_active = 1 - Game.solo_active
		Sfx.play("swap")
	_update_gates(dt)
	_rebuild_solids()
	var mid: float = (players[0].position.x + players[1].position.x) * 0.5
	for p in players:
		p.step(dt)
	for p in players:
		p.position.x = clampf(p.position.x, mid - MAX_SPLIT * 0.5, mid + MAX_SPLIT * 0.5)
	_stomp()
	_update_checkpoints()
	_update_ink(dt)
	_update_drops(dt)
	_update_camera(dt)
	_update_story(dt)
	_check_death()
	_check_goal(dt)
	burst_t = maxf(0.0, burst_t - dt)

func _rebuild_solids() -> void:
	cur_solids = static_solids.duplicate()
	for g in data.gates:
		if not gate_open(g[1]):
			cur_solids.append(Rect2(g[0], -40, 14, 340))
	for b in data.bridges:
		if gate_open(b[2]):
			cur_solids.append(Rect2(b[0] - 2, GY, b[1] + 4, 12))

func _update_gates(dt: float) -> void:
	pressed.clear()
	for pl in data.plates:
		for p in players:
			if p.on_floor and absf(p.position.x - pl[0]) < 17.0 and absf(p.position.y - pl[1]) < 3.0:
				pressed[pl[2]] = true
	for k in open_t.keys():
		var was: bool = open_t[k] > 0.0
		if pressed.has(k):
			if not was:
				Sfx.play("plate")
				Sfx.play("gate", -6.0)
			open_t[k] = HOLD
		else:
			open_t[k] = maxf(0.0, open_t[k] - dt)
			if was and open_t[k] <= 0.0:
				# do not shut a gate on a note standing in it
				for g in data.gates:
					if g[1] == k:
						for p in players:
							if p.rect().intersects(Rect2(g[0], -40, 14, 340)):
								open_t[k] = 0.15

func _unused() -> void:
	pass

func _stomp() -> void:
	for a in players:
		for b in players:
			if a == b or a.vel.y <= 0.0:
				continue
			if absf(a.position.x - b.position.x) < 15.0 and a.prev_y <= b.top() + 3.0 and a.position.y >= b.top() - 1.0 and a.position.y <= b.top() + 14.0:
				a.position.y = b.top()
				a.bounce(Player.BOUNCE + (30.0 if Input.is_action_pressed("p1_jump") or Input.is_action_pressed("p2_jump") else 0.0))

func _update_checkpoints() -> void:
	var nxt := cp_i + 1
	if nxt < data.cps.size() and rear_x() >= data.cps[nxt]:
		cp_i = nxt
		ink_x = minf(ink_x, data.cps[nxt] - 380.0)
		burst_t = 1.0
		burst_x = data.cps[nxt]
		Sfx.play("checkpoint")

func _update_ink(dt: float) -> void:
	if not ink_on and lead_x() > 140.0:
		ink_on = true
	if not ink_on:
		return
	var dist := rear_x() - ink_x
	var k := 1.0
	if dist > 480.0:
		k = 0.35
	elif dist > 280.0:
		k = lerpf(1.0, 0.35, (dist - 280.0) / 200.0)
	ink_x += float(data.speed) * k * dt

func _update_drops(dt: float) -> void:
	for d in drops:
		if d.warn > 0.0:
			d.warn -= dt
			if d.warn <= 0.0:
				if d.kind == "right":
					d.pos = Vector2(cam_left() + 670.0, d.pos.y)
				Sfx.play("warn", -10.0)
		else:
			d.pos += d.vel * dt
	drops = drops.filter(func(d): return d.pos.y < 330.0 and d.pos.x > cam_left() - 40.0)
	if data.drops.is_empty() or not ink_on or lead_x() < 500.0 or lead_x() > length - 400.0:
		return
	drop_t -= dt
	if drop_t > 0.0:
		return
	drop_t = float(data.drops.interval) * randf_range(0.7, 1.3)
	var from: String = data.drops.from[randi() % data.drops.from.size()]
	var sp: float = data.drops.speed
	if from == "top":
		var tp: Player = players[randi() % 2]
		var x := clampf(tp.position.x + randf_range(-40.0, 110.0), cam_left() + 30.0, cam_left() + 610.0)
		drops.append({"kind": "top", "pos": Vector2(x, -12.0), "vel": Vector2(0, sp), "warn": 1.0})
	else:
		var y: float = [276.0, 293.0][randi() % 2]
		drops.append({"kind": "right", "pos": Vector2(0, y), "vel": Vector2(-sp * 0.8, 0), "warn": 1.0})
	Sfx.play("warn", -10.0)

func _update_camera(dt: float) -> void:
	var target := clampf((players[0].position.x + players[1].position.x) * 0.5, 320.0, length - 320.0)
	camx = lerpf(camx, target, 1.0 - exp(-8.0 * dt))
	for c in get_children():
		if c is Camera2D:
			c.position = Vector2(camx, 180)

func _check_death() -> void:
	var dead := false
	for p in players:
		if p.position.x - 8.0 < ink_x or p.position.y > 400.0:
			dead = true
		for d in drops:
			if d.warn <= 0.0:
				var r: Rect2 = p.rect()
				var cpnt := Vector2(clampf(d.pos.x, r.position.x, r.end.x), clampf(d.pos.y, r.position.y, r.end.y))
				if cpnt.distance_to(d.pos) < 5.0:
					dead = true
	if dead and not finished:
		deaths += 1
		Game.total_deaths += 1
		dead_t = 0.8
		Sfx.play("death")
		if not quipped:
			quipped = true
			queue.push_front("Ouch! Ink got you. Lanterns remember where you were.")
		return

func _check_goal(dt: float) -> void:
	if finished:
		fin_t += dt
		if fin_t > 3.2:
			Game.main.finish_level(idx)
		return
	if rear_x() > length - 110.0:
		_finish()

func _finish() -> void:
	if finished:
		return
	finished = true
	locked = true
	Sfx.play("goal")
	queue.clear()
	cur_text = String(data.ender)
	cur_t = 5.0

func _update_text(dt: float) -> void:
	cur_t = maxf(0.0, cur_t - dt)

func _queue_narr_now() -> void:
	narr_i = 0
	_update_story(0.0)

func _update_story(dt: float) -> void:
	var lead := lead_x() / length
	while narr_i < data.narr.size() and lead >= float(data.narr[narr_i].at):
		var n = data.narr[narr_i]
		var txt: String = n.text
		if Game.mode == "solo" and String(n.solo) != "":
			txt = n.solo
		queue.append(txt)
		narr_i += 1
	if queue.size() > 2:
		queue = queue.slice(queue.size() - 2)
	if not finished:
		cur_t = maxf(0.0, cur_t - dt)
		if cur_t <= 0.0 and not queue.is_empty():
			cur_text = queue.pop_front()
			cur_t = 3.5 + cur_text.length() * 0.055
	while chat_i < chats.size() and lead >= float(chats[chat_i].at):
		var c = chats[chat_i]
		_say[int(c.who)] = [c.text, 2.4]
		chat_i += 1
	for k in _say.keys():
		_say[k][1] -= dt
		if _say[k][1] <= 0.0:
			_say.erase(k)

var _say := {}

func _process(_dt: float) -> void:
	queue_redraw()

# ------------------------------------------------------------ drawing
func _col(c: Color, wx: float) -> Color:
	return Art.g(c, gray(wx))

func _draw_backdrop(c: CanvasItem) -> void:
	Backdrop.draw(c, data.theme, cam_left(), ink_x, t, lead_x() / length)

func _draw() -> void:
	var th: String = data.theme
	var left := cam_left()
	var gc: Array = GROUND[th]
	var acc: Color = ACCENT[th]
	# story characters stand behind everything
	for s in data.scenery:
		var x: float = s[1] * length
		if x > left - 60 and x < left + 700:
			Art.figure(self, s[0], x, GY, t, gray(x), s[2])
	for s in data.story:
		var x: float = s.at * length
		if x > left - 60 and x < left + 700:
			Art.figure(self, s.who, x, GY, t, gray(x), s.flip)
	# ground
	var x0 := floorf(left / 16.0) * 16.0
	for r in static_solids:
		if r.position.y != GY:
			continue
		var a := maxf(r.position.x, x0)
		var b := minf(r.end.x, left + 656.0)
		var sx := floorf(a / 16.0) * 16.0
		while sx < b:
			var xa := maxf(sx, a)
			var xb := minf(sx + 16.0, b)
			if xb > xa:
				var m := (xa + xb) * 0.5
				draw_rect(Rect2(xa, GY, xb - xa + 0.5, 70), _col(gc[1], m))
				draw_rect(Rect2(xa, GY, xb - xa + 0.5, 8), _col(gc[0], m))
				draw_rect(Rect2(xa, GY, xb - xa + 0.5, 2.5), Art.INK)
			sx += 16.0
		var m2 := fmod(a, 24.0)
		for dx in range(int(a - m2), int(b), 24):
			draw_circle(Vector2(dx + 10, GY + 22 + (dx / 24 % 3) * 14), 2.0, _col(gc[0].darkened(0.3), dx))
		if r.position.x > left - 400 and r.position.x < left + 700 and r.position.x > 0:
			draw_rect(Rect2(r.position.x - 3, GY, 3, 70), Art.INK)
		if r.end.x > left - 400 and r.end.x < left + 700 and r.end.x < length + 100:
			draw_rect(Rect2(r.end.x, GY, 3, 70), Art.INK)
	# plates
	for pl in data.plates:
		if pl[0] < left - 40 or pl[0] > left + 680:
			continue
		var pc: Color = PLATE_COLS[pl[2]]
		var down: bool = pressed.has(pl[2])
		var yy: float = pl[1] - (2.0 if down else 5.0)
		draw_rect(Rect2(pl[0] - 17, pl[1] - 2, 34, 2), Art.INK)
		draw_rect(Rect2(pl[0] - 15, yy, 30, pl[1] - yy), _col(pc, pl[0]))
		draw_rect(Rect2(pl[0] - 15, yy, 30, pl[1] - yy), Art.INK, false, 1.5)
	# bridges (ghost when closed)
	for b in data.bridges:
		if b[0] > left + 700 or b[0] + b[1] < left - 40:
			continue
		var bc: Color = PLATE_COLS[b[2]]
		var op := gate_open(b[2])
		if op:
			draw_rect(Rect2(b[0], GY, b[1], 12), _col(bc, b[0]))
			draw_rect(Rect2(b[0], GY, b[1], 12), Art.INK, false, 2.0)
		else:
			for k in range(0, int(b[1]), 14):
				draw_rect(Rect2(b[0] + k + 2, GY + 2, 8, 6), Color(bc.r, bc.g, bc.b, 0.25))
	# gates
	for g in data.gates:
		if g[0] < left - 40 or g[0] > left + 680:
			continue
		var gc2: Color = PLATE_COLS[g[1]]
		if gate_open(g[1]):
			for k in range(0, 300, 20):
				draw_rect(Rect2(g[0] + 5, k, 4, 10), Color(gc2.r, gc2.g, gc2.b, 0.35))
		else:
			draw_rect(Rect2(g[0] - 2, -10, 18, 310), Art.INK)
			draw_rect(Rect2(g[0], -10, 14, 310), _col(gc2.darkened(0.15), g[0]))
			for k in range(0, 310, 22):
				draw_rect(Rect2(g[0], k, 14, 8), _col(gc2.lightened(0.25), g[0]))
	# panels
	for o in data.overs:
		if o[0] > left + 700 or o[0] + o[1] < left - 40:
			continue
		var r := Rect2(o[0], -20, o[1], 302)
		Art.panel(self, r, Art.PAPER, acc, gray(o[0]), int(o[0]))
		draw_rect(Rect2(o[0], 274, o[1], 8), Art.INK)
	for b in data.blocks:
		if b[0] > left + 700 or b[0] + b[2] < left - 40:
			continue
		var r2 := Rect2(b[0], b[1], b[2], b[3])
		draw_rect(Rect2(r2.position + Vector2(3, 3), r2.size), Color(0, 0, 0, 0.3))
		draw_rect(r2, Art.INK)
		draw_rect(r2.grow(-3), _col(Art.YELLOW, b[0]))
		draw_string(Game.font, Vector2(b[0] + 6, b[1] + 17), b[4], HORIZONTAL_ALIGNMENT_LEFT, b[2] - 8, 14, _col(Art.INK, b[0]))
	for i in oneways.size():
		var r3: Rect2 = oneways[i]
		if r3.position.x > left + 700 or r3.end.x < left - 40:
			continue
		Art.panel(self, Rect2(r3.position, Vector2(r3.size.x, 14)), Art.PAPER, acc, gray(r3.position.x), i)
	# checkpoint lanterns
	for i in data.cps.size():
		var x: float = data.cps[i]
		if x < left - 40 or x > left + 680:
			continue
		var on: bool = cp_i >= i
		draw_line(Vector2(x, GY), Vector2(x, GY - 38), Art.INK, 3.0)
		var lc := Art.YELLOW if on else Color(0.45, 0.42, 0.4)
		if on:
			for k in 3:
				draw_circle(Vector2(x, GY - 42), 30 - k * 9, Color(1, 0.9, 0.5, 0.10))
		draw_rect(Rect2(x - 6, GY - 54, 12, 14), Art.INK)
		draw_rect(Rect2(x - 4, GY - 52, 8, 10), lc)
	# exit light
	var ex := length - 60.0
	if ex < left + 700:
		for k in 6:
			var w := 140.0 - k * 22.0
			draw_rect(Rect2(ex - w * 0.5, 0, w, GY), Color(1, 0.97, 0.8, 0.12 + k * 0.05))
		draw_rect(Rect2(ex - 12, 40, 24, GY - 40), Color(1, 1, 0.92, 0.9))
		draw_rect(Rect2(ex - 12, 40, 24, GY - 40), Art.INK, false, 2.0)
	if burst_t > 0.0:
		for k in 3:
			draw_circle(Vector2(burst_x, GY - 42), (1.0 - burst_t) * 160.0 + k * 20.0, Color(1, 0.9, 0.5, 0.12 * burst_t))

func _draw_top(c: CanvasItem) -> void:
	var left := cam_left()
	# ink wall
	if ink_x > left - 800.0:
		var pts := PackedVector2Array()
		var x0 := ink_x - 900.0
		pts.append(Vector2(x0, -20))
		var y := -20.0
		while y <= 380.0:
			var w := sin(t * 1.6 + y * 0.07) * 7.0 + sin(t * 2.7 + y * 0.19) * 4.0
			var drip := maxf(0.0, sin(y * 0.045 + 1.3)) * 14.0
			pts.append(Vector2(ink_x + w + drip, y))
			y += 10.0
		pts.append(Vector2(x0, 380))
		c.draw_colored_polygon(pts, Art.INK)
		var hp := PackedVector2Array([Vector2(ink_x + 6, -20), Vector2(ink_x + 130, -20), Vector2(ink_x + 130, 380), Vector2(ink_x + 6, 380)])
		c.draw_polygon(hp, PackedColorArray([Color(0, 0, 0, 0.5), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0, 0, 0, 0.5)]))
		for k in 7:
			var by := 30.0 + k * 48.0 + sin(t + k) * 6.0
			c.draw_circle(Vector2(ink_x + 14 + sin(t * 1.3 + k * 2) * 5.0, by), 6.0, Art.INK)
	# droplets + warnings
	for d in drops:
		if d.warn > 0.0:
			var flash := 0.5 + 0.5 * sin(t * 18.0)
			var wc := Color(1, 0.23, 0.19, 0.5 + 0.5 * flash)
			var wp: Vector2 = Vector2(d.pos.x, 16.0) if d.kind == "top" else Vector2(left + 618.0, d.pos.y)
			c.draw_colored_polygon(PackedVector2Array([wp + Vector2(-9, -9), wp + Vector2(9, -9), wp + Vector2(0, 11)]) if d.kind == "top" else PackedVector2Array([wp + Vector2(10, -9), wp + Vector2(10, 9), wp + Vector2(-10, 0)]), wc)
			c.draw_string(Game.font, wp + Vector2(-3, 6) if d.kind == "top" else wp + Vector2(1, 5), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Art.INK)
		else:
			var tail: Vector2 = -d.vel.normalized() * 14.0
			c.draw_colored_polygon(PackedVector2Array([d.pos + Vector2(-5, 0) if d.kind == "top" else d.pos + Vector2(0, -5), d.pos + Vector2(5, 0) if d.kind == "top" else d.pos + Vector2(0, 5), d.pos + tail]), Art.INK)
			c.draw_circle(d.pos, 6.0, Art.INK)
			c.draw_circle(d.pos + Vector2(-2, -2), 1.6, Color(1, 1, 1, 0.6))
	# story speech bubbles
	for s in data.story:
		var x: float = s.at * length
		var reveal := clampf((left + 600.0 - x) / 90.0, 0.0, 1.0)
		if reveal <= 0.0 or x < left - 120.0 or x > left + 760.0:
			continue
		var tw: bool = s.who == "orpheus" and s.tw != "" and ink_x > x - 50.0
		var txt: String = s.tw if tw else s.text
		var sz := Art.text_size(txt, 150.0)
		var w := minf(sz.x + 16.0, 166.0)
		var h := sz.y + 12.0
		var bx := clampf(x - w * 0.5, left + 8.0, left + 632.0 - w)
		var rise := (1.0 - reveal) * 14.0
		var hy: float = HEAD_Y.get(s.who, 62)
		Art.bubble(c, txt, Rect2(bx, 60.0 + rise, w, h), Vector2(x, GY - hy - 4.0), tw, t, reveal, 12, true)
	# note chatter
	for k in _say.keys():
		var p: Player = players[k]
		var txt2: String = _say[k][0]
		var w2 := Game.font_hand.get_string_size(txt2, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 22.0
		var sh := -w2 * 0.5 - 6.0 if k == 0 else w2 * 0.5 + 6.0
		var rc := Rect2(p.position.x + sh - w2 * 0.5, p.position.y - 62.0, w2, 20.0)
		Art.bubble(c, txt2, rc, Vector2(p.position.x, p.position.y - 36.0), false, t, 1.0, 11)

func _draw_hud(c: CanvasItem) -> void:
	# comic panel frame
	c.draw_rect(Rect2(0, 0, 640, 360), Art.INK, false, 8.0)
	# narrator
	if cur_t > 0.0 and cur_text != "":
		var sz := Art.text_size(cur_text, 400.0, 13)
		var rc := Rect2(100, 12, 440, sz.y + 14)
		Art.caption(c, cur_text, rc, 13, clampf(cur_t * 2.0, 0.0, 1.0))
	# footer
	var fs := Game.font
	var title := "%s. %s" % [data.roman, data.title]
	var tw := fs.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 16.0
	c.draw_rect(Rect2(10, 332, tw, 20), Art.YELLOW)
	c.draw_rect(Rect2(10, 332, tw, 20), Art.INK, false, 2.0)
	c.draw_string(fs, Vector2(18, 348), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Art.INK)
	var hint := "Q swap   R retry   Esc page" if Game.mode == "solo" else "R retry   Esc page"
	c.draw_string(Game.font_hand, Vector2(630 - Game.font_hand.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, 348), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.8))
	# progress dots
	var prog := clampf(lead_x() / length, 0.0, 1.0)
	c.draw_rect(Rect2(220, 340, 200, 6), Color(0, 0, 0, 0.45))
	c.draw_rect(Rect2(220, 340, 200 * prog, 6), Art.YELLOW)
	if dead_t > 0.0:
		var a := clampf(dead_t * 2.0, 0.0, 1.0)
		c.draw_rect(Rect2(0, 0, 640, 360), Color(0.08, 0.07, 0.1, 0.55 * a))
		c.draw_string(Game.font, Vector2(235, 190), "SPLAT!", HORIZONTAL_ALIGNMENT_LEFT, -1, 54, Color(1, 0.35, 0.3, a))
	if finished:
		var f := clampf(fin_t * 1.5, 0.0, 1.0)
		c.draw_string(Game.font, Vector2(150, 150), "PANEL COMPLETE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(1, 0.97, 0.7, f))
