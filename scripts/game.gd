extends Node
# Global state: mode, progress, save file, input map and shared fonts.

const SAVE := "user://bleed.cfg"
const LEVEL_COUNT := 5

var mode := "coop"        # "coop" (two players) or "solo" (swap notes)
var unlocked := 1
var done := [false, false, false, false, false]
var current := 0
var total_deaths := 0
var solo_active := 0
var bot: Callable          # test hook: tools/bot.gd drives the notes through this
var main: Node
var font: Font
var font_hand: Font

func _ready() -> void:
	font = load("res://assets/fonts/Silkscreen-Bold.ttf")
	font_hand = load("res://assets/fonts/PixelifySans.ttf")
	for f in [font, font_hand]:
		f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		f.hinting = TextServer.HINTING_NONE
		f.generate_mipmaps = false
	_setup_input()
	_load()

func _key(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)

func _setup_input() -> void:
	_key("p1_left", [KEY_A]); _key("p1_right", [KEY_D])
	_key("p1_jump", [KEY_W, KEY_SPACE]); _key("p1_duck", [KEY_S])
	_key("p2_left", [KEY_LEFT]); _key("p2_right", [KEY_RIGHT])
	_key("p2_jump", [KEY_UP]); _key("p2_duck", [KEY_DOWN])
	_key("swap", [KEY_Q, KEY_TAB]); _key("pause", [KEY_ESCAPE])
	_key("retry", [KEY_R]); _key("accept", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE])
	_key("ui_up", [KEY_W, KEY_UP]); _key("ui_down", [KEY_S, KEY_DOWN])
	_key("skip", [KEY_F1])

# Input for one note. In solo mode only the active note listens, to both key sets.
func read(idx: int) -> Dictionary:
	if bot.is_valid():
		return bot.call(idx)
	var r := {"dx": 0.0, "jp": false, "jh": false, "duck": false}
	if mode == "solo":
		if idx != solo_active:
			return r
		r.dx = Input.get_axis("p1_left", "p1_right") + Input.get_axis("p2_left", "p2_right")
		r.dx = clampf(r.dx, -1.0, 1.0)
		r.jp = Input.is_action_just_pressed("p1_jump") or Input.is_action_just_pressed("p2_jump")
		r.jh = Input.is_action_pressed("p1_jump") or Input.is_action_pressed("p2_jump")
		r.duck = Input.is_action_pressed("p1_duck") or Input.is_action_pressed("p2_duck")
	else:
		var p := "p1_" if idx == 0 else "p2_"
		r.dx = Input.get_axis(p + "left", p + "right")
		r.jp = Input.is_action_just_pressed(p + "jump")
		r.jh = Input.is_action_pressed(p + "jump")
		r.duck = Input.is_action_pressed(p + "duck")
	return r

func strip_rect(i: int) -> Rect2:
	return Rect2(48, 44 + i * 58, 544, 50)

func complete(i: int) -> void:
	done[i] = true
	if i + 1 < LEVEL_COUNT:
		unlocked = maxi(unlocked, i + 2)
	_save()

func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "unlocked", unlocked)
	c.set_value("p", "done", done)
	c.save(SAVE)

func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE) == OK:
		unlocked = c.get_value("p", "unlocked", 1)
		var d = c.get_value("p", "done", done)
		if d is Array and d.size() == LEVEL_COUNT:
			done = d

func reset_progress() -> void:
	unlocked = 1
	done = [false, false, false, false, false]
	_save()
