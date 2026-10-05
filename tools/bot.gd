extends SceneTree
# Plays every level with two scripted notes to prove the levels are solvable.
# Usage: godot --headless --path . -s tools/bot.gd [-- level_index]   (droplets off; they are random)
const GY := 300.0
var lv
var inp := [{}, {}]
var hold := [0, 0]
var puzzles: Array = []
var bridge_pits: Array = []

func _initialize() -> void:
	await process_frame
	await process_frame
	var G = root.get_node("Game")
	G.bot = Callable(self, "get_inp")
	G.mode = "coop"
	var only := -1
	for a in OS.get_cmdline_user_args():
		only = int(a)
	for i in 5:
		if only >= 0 and i != only:
			continue
		run_level(i)
	quit()

func get_inp(idx: int) -> Dictionary:
	return inp[idx]

func build_puzzles(d: Dictionary) -> void:
	puzzles.clear()
	bridge_pits.clear()
	for b in d.bridges:
		bridge_pits.append(b[0])
		var ps := []
		for pl in d.plates:
			if pl[2] == b[2]:
				ps.append(pl[0])
		ps.sort()
		puzzles.append({"type": "bridge", "id": b[2], "p1": ps[0], "p2": ps[1], "x": b[0], "w": b[1], "start": ps[0] - 45.0, "end": b[0] + b[1] + 30.0, "stage": 0})
	for g in d.gates:
		var ps := []
		var high := -1.0
		for pl in d.plates:
			if pl[2] == g[1]:
				if pl[1] < GY:
					high = pl[0]
				else:
					ps.append(pl[0])
		ps.sort()
		if high >= 0.0:
			puzzles.append({"type": "ledge", "id": g[1], "cx": high, "sx": high - 20.0, "p2": ps[0], "gx": g[0], "start": high - 70.0, "end": g[0] + 40.0, "stage": 0})
		else:
			puzzles.append({"type": "gate", "id": g[1], "p1": ps[0], "p2": ps[1], "gx": g[0], "start": ps[0] - 45.0, "end": g[0] + 40.0, "stage": 0})
	puzzles.sort_custom(func(a, b): return a.start < b.start)

# walk toward tx, reacting to pits, blocks and low panels
func walk(i: int, tx: float, stop_near := 3.0) -> void:
	var p = lv.players[i]
	var d = lv.data
	var dx: float = tx - p.position.x
	var o := {"dx": 0.0, "jp": false, "jh": hold[i] > 0, "duck": false}
	if absf(dx) > stop_near:
		o.dx = signf(dx)
	if hold[i] > 0:
		hold[i] -= 1
	if o.dx > 0.0:
		for pit in d.pits:
			if not bridge_pits.has(pit[0]) and p.position.x < pit[0] and pit[0] - p.position.x < 26.0 and p.on_floor:
				o.jp = true
		for b in d.blocks:
			if p.position.x < b[0] and b[0] - p.position.x < 30.0 and p.on_floor and p.position.y > b[1] + 5.0:
				o.jp = true
	for ov in d.overs:
		if p.position.x > ov[0] - 34.0 and p.position.x < ov[0] + ov[1] + 14.0:
			o.duck = true
	if o.jp:
		hold[i] = 30
		o.jh = true
	inp[i] = o

func idle(i: int) -> void:
	inp[i] = {"dx": 0.0, "jp": false, "jh": false, "duck": false}

func run_puzzle(P: Dictionary) -> bool:
	var A = lv.players[0]
	var B = lv.players[1]
	var pressed: bool = lv.pressed.has(P.id)
	match P.type:
		"gate", "bridge":
			match P.stage:
				0:
					walk(0, P.p1)
					walk(1, P.p1 - 30.0)
					if pressed and A.on_floor:
						P.stage = 1
				1:
					idle(0)
					walk(1, P.p2)
					if absf(B.position.x - P.p2) < 6.0 and B.on_floor:
						P.stage = 2
				2:
					walk(0, P.end)
					idle(1)
					if A.position.x > P.end:
						return true
		"ledge":
			match P.stage:
				0:
					walk(0, P.sx)
					walk(1, P.sx - 40.0)
					if absf(A.position.x - P.sx) < 5.0 and absf(B.position.x - P.sx) < 45.0:
						P.stage = 1
				1:
					idle(0)
					walk(1, P.sx, 1.0)
					if absf(B.position.x - P.sx) < 4.0 and B.on_floor:
						P.stage = 2
				2:
					idle(0)
					inp[1] = {"dx": 0.0, "jp": B.on_floor, "jh": true, "duck": false}
					if not B.on_floor:
						P.stage = 3
				3:
					idle(0)
					inp[1] = {"dx": signf(P.cx - B.position.x) if B.position.y < 215.0 else 0.0, "jp": false, "jh": false, "duck": false}
					if B.on_floor and B.position.y < 200.0:
						P.stage = 4
				4:
					idle(0)
					walk(1, P.cx, 2.0)
					if pressed and B.on_floor and B.position.y < 200.0:
						P.stage = 5
				5:
					walk(0, P.p2)
					idle(1)
					if absf(A.position.x - P.p2) < 6.0 and A.on_floor:
						P.stage = 6
				6:
					idle(0)
					walk(1, P.end)
					if B.position.x > P.end and B.on_floor:
						return true
	return false

func run_level(i: int) -> void:
	lv = load("res://scripts/level.gd").new()
	root.add_child(lv)
	lv.setup(i)
	lv.data.drops = {}
	build_puzzles(lv.data)
	var frames := 0
	var active := 0
	var goal: float = lv.length - 40.0
	while not lv.finished and frames < 60 * 420:
		var cur = null
		if active < puzzles.size():
			cur = puzzles[active]
		if cur != null:
			var a = lv.players[0]
			var b = lv.players[1]
			var staged: bool = cur.stage > 0 or (a.position.x > cur.start - 60.0 and b.position.x > cur.start - 60.0)
			if cur.stage == 0 and not staged:
				walk(0, cur.start)
				walk(1, cur.start - 10.0)
			elif run_puzzle(cur):
				active += 1
		else:
			walk(0, goal)
			walk(1, goal)
		lv._physics_process(1.0 / 60.0)
		frames += 1
		if OS.get_environment("BOTDBG") != "" and active < puzzles.size() and puzzles[active].stage >= 2 and frames % 4 == 0 and frames < 60 * 400:
			print(frames, " st=", puzzles[active].stage, " B=", lv.players[1].position, " v=", lv.players[1].vel, " floor=", lv.players[1].on_floor)
	var st := "ok" if lv.finished else "STUCK"
	var info := ""
	if not lv.finished:
		info = " A=%s B=%s ink=%.0f puzzle=%s" % [lv.players[0].position, lv.players[1].position, lv.ink_x, str(puzzles[active]) if active < puzzles.size() else "none"]
	print("level %d %s time=%.0fs deaths=%d cp=%d%s" % [i + 1, st, frames / 60.0, lv.deaths, lv.cp_i, info])
	lv.queue_free()
