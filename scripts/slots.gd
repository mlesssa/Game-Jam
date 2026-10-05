class_name Slots
# Image slots for the comic art. The art is supplied as image files; when a file is missing a labelled
# placeholder is drawn instead, so the game always runs. Filenames and sizes are listed in assets/SLOTS.md.

# height in px the figure is scaled to, and how far it floats above the ground
const FIG := {"orpheus": [64.0, 0.0], "eurydice": [66.0, 0.0], "charon": [86.0, 0.0], "persephone": [66.0, 0.0],
	"hades": [96.0, 0.0], "cerberus": [44.0, 0.0], "shade": [64.0, 0.0], "deer": [48.0, 0.0], "bird": [24.0, 52.0]}

static var _cache := {}

static func tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_cache[path] = t
	return t

# Draws a story character standing with feet at (x, y). Images face right; flip turns them to face left.
static func figure(c: CanvasItem, kind: String, x: float, y: float, t: float, flip := false) -> void:
	var spec: Array = FIG.get(kind, [64.0, 0.0])
	var h: float = spec[0]
	var lift: float = spec[1] + (sin(t * 3.0 + x) * 3.0 if lift_bob(kind) else 0.0)
	var tx := tex("res://assets/chars/%s.png" % kind)
	if tx:
		var w := h * tx.get_width() / tx.get_height()
		if flip:
			c.draw_texture_rect(tx, Rect2(x + w * 0.5, y - h - lift, -w, h), false)
		else:
			c.draw_texture_rect(tx, Rect2(x - w * 0.5, y - h - lift, w, h), false)
	else:
		var r := Rect2(x - h * 0.25, y - h - lift, h * 0.5, h)
		c.draw_rect(r, Color(1, 1, 1, 0.18))
		c.draw_rect(r, Color(1, 1, 1, 0.7), false, 1.0)
		c.draw_string(Game.font, Vector2(x - h * 0.25 + 2, y - h * 0.5 - lift), kind.substr(0, 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.9))

static func lift_bob(kind: String) -> bool:
	return kind == "bird"
