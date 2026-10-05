extends Node2D
class_name DrawProxy
# Tiny helper: a node whose _draw is handled by a callable, so one script can own several draw layers.
var cb: Callable

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	if cb.is_valid():
		cb.call(self)
