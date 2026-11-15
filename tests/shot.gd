extends SceneTree
## Developer tool, not a test: opens a view, optionally runs it, and saves a screenshot.
## Needs a real renderer, so run it windowed (no --headless):
##   Godot --path . --resolution 1180x500 --script tests/shot.gd -- <out.png> <view> [seconds] [extras]
## view: menu | molecules | regulation | evidence | population
## extras (any, joined by commas): explain, nolabels, reduced, large, xlarge, compare, help,
##   settings, focus, controls, upstream, coding, check, milk, dpr15
## It lives in tests/, which is left out of the web export.


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "shot.png"
	var view_id: String = args[1] if args.size() > 1 else "menu"
	var seconds: float = float(args[2]) if args.size() > 2 else 0.0
	var extras: PackedStringArray = (args[3] if args.size() > 3 else "").split(",", false)
	var main: Control = (load("res://Main.tscn") as PackedScene).instantiate()
	main.set("persist_settings", false)
	root.add_child(main)
	await process_frame
	await process_frame
	if extras.has("dpr15"):
		main.layout.dpr_override = 1.5
		main.layout.apply()
	if extras.has("explain"):
		main.app.set_explain(true)
	if extras.has("nolabels"):
		main.app.set_labels(false)
	if extras.has("reduced"):
		main.app.set_reduced_motion(true)
	if extras.has("large"):
		main.app.set_text_size(1)
	if extras.has("xlarge"):
		main.app.set_text_size(2)
	main.show_view(view_id)
	await process_frame
	await process_frame
	var view: Control = main.current_view
	if extras.has("compare") and "compare_button" in view:
		view.compare_button.button_pressed = true
	if view_id == "evidence":
		if extras.has("coding"):
			view.zoom_row.select(1)
		if extras.has("upstream"):
			view.zoom_row.select(2)
		if extras.has("check"):
			view.grid.cursor = Vector2i(3, view.grid.rows.size() - 1)
			view.grid.toggle_at_cursor()
			view.grid.cursor = Vector2i(1, 0)
			view.grid.toggle_at_cursor()
			view.check_highlighting()
	if view_id == "population" and extras.has("milk"):
		view.context_row.select(1)
	if view_id == "regulation" and extras.has("supplement"):
		view.supplement_button.button_pressed = true
	await process_frame
	if seconds > 0.0 and view.has_method("on_play_pressed"):
		view.on_play_pressed()
		var t: float = 0.0
		while t < seconds:
			await process_frame
			t += 1.0 / 60.0
		if not extras.has("keeprunning") and view.running:
			view.on_play_pressed()
	if extras.has("controls") and view.has_method("show_tab"):
		view.show_tab(1)
	if extras.has("help"):
		main.open_help()
	if extras.has("settings"):
		main.open_settings()
	if extras.has("focus"):
		for i: int in range(3):
			main.nav.move_focus(1)
	for i: int in range(6):
		await process_frame
	var img: Image = root.get_texture().get_image()
	img.save_png(out)
	print("saved %s (%dx%d), layout %s, css/px %.2f" % [out, img.get_width(), img.get_height(), str(main.layout.view_size), main.layout.css_per_px])
	quit(0)
