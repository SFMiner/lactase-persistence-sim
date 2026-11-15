extends "res://tests/test_base.gd"
## Keyboard operation and the host exit (hosting requirements section 3; acceptance test 10), on
## the real Main scene, headless. Key presses are pushed into the window as real input events.
## The browser checks in tests/web/ cover the exported build and the real postMessage.
## Run:  Godot --headless --path . --script tests/test_keyboard.gd

const EXPECTED: int = 54
const VIEWS: Array[String] = ["menu", "molecules", "regulation", "evidence", "population"]


func _init() -> void:
	test_name = "test_keyboard"
	_run.call_deferred()


func _run() -> void:
	await boot_main()
	var nav: KeyboardNavigation = main.nav
	check(main.current_id == "menu", "opens on Choose a Model")
	# Ends of the ring on the menu.
	var ring: Array[Control] = nav.current_ring()
	check(ring.size() == 8, "menu ring: Mode, Labels, Help, Settings and four tiles (%d)" % ring.size())
	root.gui_release_focus()
	key(KEY_TAB)
	check(focus_owner() == ring[0], "Tab with nothing focused goes to the first control")
	root.gui_release_focus()
	key(KEY_TAB, true)
	check(focus_owner() == ring[-1], "Shift+Tab with nothing focused goes to the last control")
	var leaves: int = nav.leave_count
	key(KEY_TAB)
	check(nav.leave_count == leaves + 1 and focus_owner() == null, "Tab past the last control leaves the game and releases focus")
	ring[0].grab_focus()
	leaves = nav.leave_count
	key(KEY_TAB, true)
	check(nav.leave_count == leaves + 1 and focus_owner() == null, "Shift+Tab before the first control leaves the game")
	leaves = nav.leave_count
	key(KEY_ESCAPE)
	check(nav.leave_count == leaves + 1, "Escape with nothing open leaves the game")
	# A held Tab (key repeat) stops at the end instead of leaving.
	ring[-1].grab_focus()
	leaves = nav.leave_count
	nav.move_focus(1, true)
	check(nav.leave_count == leaves and focus_owner() == ring[-1], "a held Tab key does not throw the player out")
	# Overlays: Tab stays inside, Escape closes the overlay first.
	main.help_button.grab_focus()
	key(KEY_ENTER)
	await process_frame
	check(main.overlay_open(), "Enter on Help opens the help box")
	var inside: Array[Control] = nav.current_ring()
	var all_inside: bool = not inside.is_empty()
	for c: Control in inside:
		if not main.overlays[-1].is_ancestor_of(c):
			all_inside = false
	check(all_inside, "while Help is open, Tab can only reach controls inside it")
	leaves = nav.leave_count
	key(KEY_ESCAPE)
	await process_frame
	check(not main.overlay_open() and nav.leave_count == leaves, "Escape closes Help and does not leave")
	check(focus_owner() == main.help_button, "focus returns to the Help button")
	key(KEY_ESCAPE)
	check(nav.leave_count == leaves + 1, "the next Escape leaves the game")
	main.open_settings()
	await process_frame
	leaves = nav.leave_count
	key(KEY_TAB)
	key(KEY_TAB)
	key(KEY_TAB)
	key(KEY_TAB)
	key(KEY_TAB)
	key(KEY_TAB)
	check(main.overlay_open() and nav.leave_count == leaves + 1, "Tab past the last control of Settings leaves; Settings stays open for the return")
	main.close_topmost()
	await process_frame

	# Every view: walk the whole ring with Tab, check sizes and the reserved corner.
	for id: String in VIEWS:
		var view: Control = await open_view(id)
		ring = nav.current_ring()
		root.gui_release_focus()
		var visited: int = 0
		var in_order: bool = true
		for i: int in range(ring.size()):
			key(KEY_TAB)
			if focus_owner() == ring[i]:
				visited += 1
			else:
				in_order = false
		check(in_order and visited == ring.size() and ring.size() >= 6, "%s: Tab visits all %d controls in order" % [id, ring.size()])
		leaves = nav.leave_count
		key(KEY_TAB)
		check(nav.leave_count == leaves + 1, "%s: one more Tab leaves the game" % id)
		var small: int = 0
		for c: Control in ring:
			if c.size.x < 43.9 or c.size.y < 43.9:
				small += 1
		check(small == 0, "%s: every control is at least 44 x 44 (%d too small)" % [id, small])
		var corner: Rect2 = Rect2(1180.0 - 200.0, 0.0, 200.0, 64.0)
		var in_corner: int = 0
		for c: Control in ring:
			if c.get_global_rect().intersects(corner):
				in_corner += 1
		check(in_corner == 0, "%s: no control in the top-right 200 x 64 corner" % id)
		check(_buttons_focusable(view), "%s: no button or slider has focus turned off" % id)

	# Operating the models from the keyboard.
	var mol: Control = await open_view("molecules")
	mol.play_button.grab_focus()
	key(KEY_ENTER)
	check(mol.running, "Molecules: Enter on Run starts the run")
	key(KEY_SPACE)
	check(not mol.running, "Molecules: Space on Pause pauses it")
	mol.lactase_stepper.slider.grab_focus()
	var before: int = mol.lactase_stepper.value
	key(KEY_RIGHT)
	check(mol.lactase_stepper.value == before + 1, "Molecules: Right arrow on the slider adds one lactase")
	key(KEY_LEFT)
	key(KEY_LEFT)
	check(mol.lactase_stepper.value == before - 1, "Molecules: Left arrow removes lactase")
	mol.lactose_stepper.plus.grab_focus()
	key(KEY_ENTER)
	check(mol.lactose_stepper.value == 55, "Molecules: the plus button adds 5 lactose")
	check(main.announcer.last_text() != "", "focus changes are announced for screen readers")
	var evi: Control = await open_view("evidence")
	evi.zoom_row.buttons[2].grab_focus()
	key(KEY_ENTER)
	evi.compare_button.grab_focus()
	key(KEY_ENTER)
	await process_frame
	check(evi.zoom == 2 and evi.compare, "Evidence: zoom and compare work from the keyboard")
	evi.grid.grab_focus()
	for i: int in range(7):
		key(KEY_DOWN)
	for i: int in range(3):
		key(KEY_RIGHT)
	check(evi.grid.cursor == Vector2i(3, 7), "Evidence: arrow keys move the table cursor")
	key(KEY_ENTER)
	check(evi.grid.highlights.has(EvidenceData.cell_key(EvidenceData.ALISSA, 1, 3)), "Evidence: Enter highlights the cell under the cursor")
	check(focus_owner() == evi.grid, "Evidence: arrow keys stay in the table (focus did not jump)")
	evi.check_button.grab_focus()
	key(KEY_ENTER)
	check(evi.result_label.text.begins_with("Matches the lesson data"), "Evidence: Check highlighting reports a match")
	var pop: Control = await open_view("population")
	pop.step_button.grab_focus()
	key(KEY_ENTER)
	check(pop.model_a.generation == 1, "Generations: Enter on Step makes one generation")
	pop.context_row.buttons[1].grab_focus()
	key(KEY_SPACE)
	check(pop.model_a.context == PopulationModel.Context.MILK_IMPORTANT, "Generations: Space chooses a setting")
	main.home_button.grab_focus()
	key(KEY_ENTER)
	await process_frame
	check(main.current_id == "menu", "Home returns to Choose a Model")
	main.current_view.tiles[2].grab_focus()
	key(KEY_ENTER)
	await process_frame
	check(main.current_id == "population", "Enter on a tile opens that model")
	finish(EXPECTED)


## True when every button and slider under `node` can take keyboard focus.
func _buttons_focusable(node: Node) -> bool:
	if node is BaseButton or node is Slider:
		if (node as Control).focus_mode != Control.FOCUS_ALL:
			return false
	for child: Node in node.get_children():
		if not _buttons_focusable(child):
			return false
	return true
