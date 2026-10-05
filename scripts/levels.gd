class_name Levels
# Hand-built level data. Everything is placed in pixels along a ground line at y = 300.
# Jump reaches ~60 px up and ~85 px across; standing on the other note's head reaches ~130 px up.

const GY := 300.0

static func all() -> Array:
	return [_l1(), _l2(), _l3(), _l4(), _l5()]

static func _new(roman: String, title: String, theme: String, length: float, speed: float) -> Dictionary:
	return {"roman": roman, "title": title, "theme": theme, "length": length, "speed": speed,
		"pits": [], "plats": [], "blocks": [], "overs": [], "plates": [], "gates": [], "bridges": [],
		"cps": [], "drops": {}, "story": [], "scenery": [], "narr": [], "chat": [], "thumb": [], "ender": ""}

static func pit(L: Dictionary, x: float, w: float) -> void:
	L.pits.append([x, w])

static func plat(L: Dictionary, x: float, y: float, w: float) -> void:
	L.plats.append([x, y, w])

static func block(L: Dictionary, x: float, y: float, w: float, text: String) -> void:
	L.blocks.append([x, y, w, GY - y, text])

static func over(L: Dictionary, x: float, w: float) -> void:
	L.overs.append([x, w])

# Plate-and-gate pair: stand on one plate while your friend goes through, then swap places.
static func gate_pair(L: Dictionary, id: int, p1: float, gx: float, p2: float) -> void:
	L.plates.append([p1, GY, id])
	L.plates.append([p2, GY, id])
	L.gates.append([gx, id])

# Gate opened from a high ledge that only a bounce off the other note's head reaches.
static func ledge_gate(L: Dictionary, id: int, px: float, gx: float, p2: float) -> void:
	plat(L, px, 175.0, 90.0)
	L.plates.append([px + 45.0, 175.0, id])
	L.plates.append([p2, GY, id])
	L.gates.append([gx, id])

# Pit that is only bridged while a plate is held on either side.
static func bridge_pair(L: Dictionary, id: int, p1: float, x: float, w: float, p2: float) -> void:
	pit(L, x, w)
	L.bridges.append([x, w, id])
	L.plates.append([p1, GY, id])
	L.plates.append([p2, GY, id])

static func say(L: Dictionary, at: float, who: String, text: String, tw := "", flip := false) -> void:
	L.story.append({"at": at, "who": who, "text": text, "tw": tw, "flip": flip})

static func narr(L: Dictionary, at: float, text: String, solo := "") -> void:
	L.narr.append({"at": at, "text": text, "solo": solo})

static func chat(L: Dictionary, at: float, who: int, text: String) -> void:
	L.chat.append({"at": at, "who": who, "text": text})

# ---------------------------------------------------------------- Level 1
static func _l1() -> Dictionary:
	var L := _new("I", "A SONG IN THE MEADOW", "meadow", 4200.0, 22.0)
	L.thumb = ["orpheus", "eurydice"]
	block(L, 700, 262, 80, "MEANWHILE...")
	plat(L, 1000, 250, 90)
	pit(L, 1350, 50)
	plat(L, 1460, 250, 80)
	over(L, 1800, 70)
	over(L, 1950, 70)
	gate_pair(L, 0, 2300, 2450, 2600)
	block(L, 2900, 255, 70, "SUDDENLY!")
	pit(L, 3150, 55)
	ledge_gate(L, 1, 3470, 3700, 3820)
	L.cps = [1550.0, 2150.0, 3300.0]
	L.scenery = [["deer", 0.04, false], ["bird", 0.30, false], ["deer", 0.46, true], ["bird", 0.70, false]]
	say(L, 0.07, "orpheus", "My song makes the whole meadow dance.", "Your song kills everything it touches.")
	say(L, 0.12, "eurydice", "Play it again. I could listen forever.", "", true)
	say(L, 0.36, "orpheus", "Wait for me, Eurydice!", "You let go of her hand.")
	say(L, 0.41, "eurydice", "I'm right behind you.", "", true)
	say(L, 0.71, "orpheus", "Eurydice? Where are you?", "You were too slow. You always are.")
	say(L, 0.87, "orpheus", "I will bring her back. I will find a way.", "It is all your fault. Give up.")
	narr(L, 0.00, "Two little notes drift through a comic page. Player 1: A / D move, W jump. Player 2: arrow keys.",
		"Two little notes drift through a comic page. Move with A / D or the arrows, jump with W / Up / Space.")
	narr(L, 0.15, "Panels are platforms. Jump on top of the caption box!")
	narr(L, 0.29, "Pits swallow notes. Jump across! Hold jump for a higher hop.")
	narr(L, 0.40, "Low panels ahead. Hold S / Down to duck underneath.")
	narr(L, 0.49, "Something black is creeping across the page. Keep moving, and never get caught.")
	narr(L, 0.53, "Lanterns push the ink back. Touch one to save your place.")
	narr(L, 0.56, "A gate! One note stands on a plate to hold it open while the other passes. Then swap.",
		"A gate! Stand on the plate, press Q to swap notes, and send the other one through. Then swap back.")
	narr(L, 0.74, "Jump onto your friend's head to bounce high!", "Stand still, press Q, and jump on the frozen note's head to bounce high!")
	narr(L, 0.93, "Reach the light, both of you.")
	chat(L, 0.03, 0, "la la")
	chat(L, 0.03, 1, "hello!")
	chat(L, 0.22, 1, "whee!")
	chat(L, 0.50, 0, "uh oh")
	chat(L, 0.64, 1, "go go!")
	L.ender = "The meadow falls silent. Eurydice is gone."
	return L

# ---------------------------------------------------------------- Level 2
static func _l2() -> Dictionary:
	var L := _new("II", "THE WAY DOWN", "cave", 4600.0, 28.0)
	L.thumb = ["orpheus", "shade"]
	L.drops = {"from": ["top"], "interval": 5.0, "speed": 210.0}
	over(L, 700, 80)
	pit(L, 900, 55)
	block(L, 1100, 258, 70, "ECHO...")
	over(L, 1300, 70)
	over(L, 1400, 70)
	gate_pair(L, 0, 1750, 1900, 2050)
	pit(L, 2250, 55)
	pit(L, 2400, 55)
	bridge_pair(L, 1, 2640, 2700, 150, 2880)
	block(L, 3200, 250, 60, "DEEPER...")
	over(L, 3350, 70)
	ledge_gate(L, 2, 3700, 3900, 4020)
	L.cps = [1600.0, 3000.0, 3600.0]
	L.scenery = [["shade", 0.30, false], ["shade", 0.62, true]]
	say(L, 0.09, "orpheus", "She is somewhere below. I can feel it.", "She is gone because of you.")
	say(L, 0.33, "orpheus", "Even the stones weep. Let me pass.", "Nothing weeps for you.")
	say(L, 0.57, "orpheus", "Down, and down, and down.", "Turn around. You cannot fix this.")
	say(L, 0.78, "shade", "Turn back, living one...", "", true)
	say(L, 0.93, "orpheus", "I hear her. She is close.", "That is only the dark laughing at you.")
	narr(L, 0.00, "The way down is cold. Ink drips from the ceiling. Watch for the red ! warnings.")
	narr(L, 0.21, "Fast ink drops fall where the ! appears. Step out of the way.")
	narr(L, 0.37, "A bridge appears while someone stands on a plate. Keep holding it!",
		"Stand on a plate, press Q, and the other note can cross the bridge. Then swap back.")
	narr(L, 0.80, "High ledge, hidden plate. You know the trick by now.")
	chat(L, 0.10, 0, "brr")
	chat(L, 0.45, 1, "dark...")
	chat(L, 0.70, 0, "stay close")
	chat(L, 0.90, 1, "?!")
	L.ender = "Orpheus keeps walking. The ink keeps whispering."
	return L

# ---------------------------------------------------------------- Level 3
static func _l3() -> Dictionary:
	var L := _new("III", "THE RIVER", "river", 4800.0, 33.0)
	L.thumb = ["charon", "orpheus"]
	L.drops = {"from": ["top", "right"], "interval": 4.2, "speed": 220.0}
	pit(L, 800, 55)
	plat(L, 900, 250, 80)
	block(L, 1000, 252, 60, "SPLASH!")
	over(L, 1200, 70)
	pit(L, 1350, 55)
	over(L, 1500, 70)
	bridge_pair(L, 0, 1790, 1850, 170, 2050)
	gate_pair(L, 1, 2200, 2330, 2460)
	ledge_gate(L, 2, 2900, 3100, 3220)
	pit(L, 3400, 55)
	over(L, 3550, 70)
	block(L, 3700, 250, 70, "CREAK...")
	bridge_pair(L, 3, 3990, 4050, 170, 4250)
	L.cps = [1650.0, 2600.0, 3850.0]
	L.scenery = [["charon", 0.55, true], ["shade", 0.15, false], ["shade", 0.80, true]]
	say(L, 0.06, "orpheus", "The river of the dead. I must cross it.", "You will never cross. You are too weak.")
	say(L, 0.29, "charon", "No living soul crosses my river.", "", true)
	say(L, 0.40, "orpheus", "Then hear my song, ferryman.", "He will not listen to a failure.")
	say(L, 0.68, "charon", "...Enough. Sit. I will row.", "", true)
	say(L, 0.91, "orpheus", "Almost there.", "You are wasting her time.")
	narr(L, 0.00, "Dark water. Ink also flies in from the right now. A ! on the edge shows where.")
	narr(L, 0.11, "Low ink? Duck under it. High ink? Jump over it.")
	narr(L, 0.62, "Take your time with the plates. Lanterns will hold the ink back.")
	chat(L, 0.12, 1, "splash")
	chat(L, 0.35, 0, "brave!")
	chat(L, 0.60, 1, "hold on!")
	chat(L, 0.85, 0, "nearly")
	L.ender = "The ferryman nods. The far shore is close."
	return L

# ---------------------------------------------------------------- Level 4
static func _l4() -> Dictionary:
	var L := _new("IV", "THE HALL OF THE KING", "hall", 5000.0, 38.0)
	L.thumb = ["hades", "persephone", "cerberus"]
	L.drops = {"from": ["top", "right"], "interval": 3.6, "speed": 230.0}
	block(L, 700, 250, 80, "ZZZ...")
	over(L, 900, 70)
	over(L, 1000, 70)
	pit(L, 1150, 55)
	block(L, 1250, 255, 60, "SHHH!")
	gate_pair(L, 0, 1600, 1730, 1860)
	pit(L, 2050, 55)
	over(L, 2200, 70)
	ledge_gate(L, 1, 2500, 2700, 2820)
	bridge_pair(L, 2, 3140, 3200, 170, 3400)
	over(L, 3600, 70)
	over(L, 3700, 70)
	pit(L, 3800, 55)
	gate_pair(L, 3, 4000, 4130, 4260)
	L.cps = [1450.0, 3000.0, 4400.0]
	L.scenery = [["cerberus", 0.10, false]]
	say(L, 0.14, "orpheus", "Shh. The three-headed dog is sleeping.", "One wrong step and you will lose her again.")
	say(L, 0.50, "orpheus", "Great king, I have come for my wife.", "You have no right to ask for anything.")
	say(L, 0.60, "persephone", "Let him sing for us, my love.", "", true)
	say(L, 0.69, "hades", "...Take her. But do not look back. Not once.", "", true)
	say(L, 0.90, "eurydice", "I am here. Walk on.", "", true)
	narr(L, 0.00, "The hall of the king. Everything here is large, quiet and asleep. Try not to wake it.")
	narr(L, 0.40, "Ink flies faster in here. Stay calm and keep your notes together.")
	narr(L, 0.86, "The way out is close. Do not stop now.")
	chat(L, 0.08, 1, "shh...")
	chat(L, 0.25, 0, "so big")
	chat(L, 0.55, 1, "listen")
	chat(L, 0.80, 0, "go go!")
	L.ender = "The king relents. There is only one rule."
	return L

# ---------------------------------------------------------------- Level 5
static func _l5() -> Dictionary:
	var L := _new("V", "DO NOT LOOK BACK", "climb", 5200.0, 42.0)
	L.thumb = ["orpheus", "eurydice"]
	L.drops = {"from": ["top", "right"], "interval": 3.2, "speed": 240.0}
	block(L, 600, 255, 70, "STEP")
	pit(L, 800, 55)
	over(L, 950, 70)
	over(L, 1050, 70)
	ledge_gate(L, 0, 1400, 1600, 1720)
	pit(L, 1900, 55)
	block(L, 2000, 250, 60, "STEP")
	pit(L, 2150, 55)
	bridge_pair(L, 1, 2490, 2550, 170, 2750)
	over(L, 2950, 70)
	over(L, 3050, 70)
	over(L, 3150, 70)
	gate_pair(L, 2, 3500, 3630, 3760)
	ledge_gate(L, 3, 4000, 4200, 4320)
	pit(L, 4500, 55)
	block(L, 4600, 250, 60, "STEP")
	pit(L, 4720, 55)
	L.cps = [1200.0, 2350.0, 3350.0, 4800.0]
	L.scenery = [["eurydice", 0.22, true], ["eurydice", 0.52, true], ["shade", 0.40, false]]
	say(L, 0.07, "orpheus", "Don't look back. Don't look back.", "Look back. She is not there. You lost her again.")
	say(L, 0.27, "eurydice", "Orpheus... I can't hear your song.", "", true)
	say(L, 0.46, "orpheus", "Is she still there? I can't hear her steps.", "Of course she is gone. Look and see.")
	say(L, 0.60, "eurydice", "I am right behind you.", "", true)
	say(L, 0.78, "orpheus", "The light! We are almost out!", "Turn around. Turn around. Turn around.")
	say(L, 0.92, "eurydice", "Do not turn, my love...", "", true)
	narr(L, 0.00, "The last climb. Every trick, one more time. The light is up ahead.")
	narr(L, 0.45, "The ink is loud now. Orpheus can hear it. Keep playing.")
	narr(L, 0.90, "Almost at the light. Play, little notes. Play!")
	chat(L, 0.10, 0, "up up")
	chat(L, 0.35, 1, "I hear it")
	chat(L, 0.60, 0, "keep going")
	chat(L, 0.88, 1, "light!")
	L.ender = "The light is right there."
	return L
