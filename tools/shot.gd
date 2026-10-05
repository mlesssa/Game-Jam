extends SceneTree
# Takes screenshots for visual checks. Run under xvfb: xvfb-run -a godot --path . -s tools/shot.gd
func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/shots/%s.png" % name)

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("/tmp/shots")
	var main = load("res://main.tscn").instantiate()
	root.add_child(main)
	for k in 5:
		await process_frame
	await snap("title")
	var G = root.get_node("Game")
	G.unlocked = 5
	G.done = [true, true, false, false, false]
	main.to_page()
	for k in 5:
		await process_frame
	await snap("page")
	for i in 5:
		main.start_level(i)
		for k in 90:
			await process_frame
		var lv = main.screen
		for xf in [0.0, 0.3, 0.7]:
			var x: float = max(70.0, lv.length * xf)
			if xf > 0.0:
				lv.ink_on = true
				lv.cp_i = -1
				lv.ink_x = x - 150.0
				lv.players[0].position = Vector2(x - 14, 300)
				lv.players[1].position = Vector2(x + 14, 300)
				lv.camx = clampf(x, 320.0, lv.length - 320.0)
			for k in 20:
				await process_frame
			await snap("l%d_%d" % [i + 1, int(xf * 10)])
	main.start_level(0)
	for k in 90:
		await process_frame
	var l0 = main.screen
	l0.ink_on = true
	l0.camx = 420.0
	l0.players[0].position = Vector2(470, 300)
	l0.players[1].position = Vector2(500, 300)
	l0.ink_x = 330.0
	l0.drops.append({"kind": "top", "pos": Vector2(520, -12), "vel": Vector2(0, 200), "warn": 5.0})
	l0.drops.append({"kind": "right", "pos": Vector2(0, 276), "vel": Vector2(-200, 0), "warn": 5.0})
	for k in 15:
		await process_frame
	await snap("l1_twist")
	main._set_screen(load("res://scripts/ending.gd").new())
	for k in 400:
		await process_frame
	await snap("ending")
	quit()
