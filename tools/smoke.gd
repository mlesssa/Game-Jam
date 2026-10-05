extends SceneTree
# Headless smoke test: opens each screen and runs a level for a few seconds. Usage: godot --headless -s tools/smoke.gd
func _initialize() -> void:
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	for i in 5:
		main.start_level(i)
		for k in 120:
			await physics_frame
		var lv = main.screen
		if lv.has_method("setup"):
			print("level ", i, " ok x=", lv.players[0].position, " ink=", lv.ink_x)
	main.to_page()
	for k in 10:
		await process_frame
	main._set_screen(load("res://scripts/ending.gd").new())
	for k in 10:
		await process_frame
	print("SMOKE DONE")
	quit()
