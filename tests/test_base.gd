extends SceneTree
## Shared helpers for the headless tests. Each test script extends this, runs its checks, and
## must report the exact number of checks it expects, so an aborted test cannot pass quietly.
## Run:  Godot --headless --path . --script tests/<name>.gd

# === PUBLIC VARIABLES ===
var passed: int = 0
var failures: int = 0
var test_name: String = "test"
var main: Control = null


# === PUBLIC METHODS ===
func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failures += 1
		print("  FAIL: " + label)


func finish(expected_total: int) -> void:
	var total: int = passed + failures
	var ok: bool = failures == 0 and total == expected_total
	print("%s: %d/%d passed (expected %d checks) -> %s" % [test_name, passed, total, expected_total,
		"PASS" if ok else "FAIL"])
	quit(0 if ok else 1)


func near(a: float, b: float, tolerance: float = 0.000001) -> bool:
	return absf(a - b) <= tolerance


## Loads the real Main scene without touching saved settings, at a given window size.
## `dpr` stands in for the browser's device pixel ratio.
func boot_main(window: Vector2i = Vector2i(1180, 500), dpr: float = 1.0) -> void:
	main = (load("res://Main.tscn") as PackedScene).instantiate()
	main.set("persist_settings", false)
	root.add_child(main)
	await process_frame
	await resize(window, dpr)


func resize(window: Vector2i, dpr: float = 1.0) -> void:
	main.layout.dpr_override = dpr
	# The headless window does not start at the project's size; set it explicitly.
	root.size = window
	await process_frame
	main.layout.apply()
	await process_frame
	await process_frame


func open_view(id: String) -> Control:
	main.show_view(id)
	await process_frame
	await process_frame
	return main.current_view


func key(keycode: Key, shift: bool = false) -> void:
	for pressed: bool in [true, false]:
		var ev: InputEventKey = InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		ev.shift_pressed = shift
		ev.pressed = pressed
		root.push_input(ev)


func focus_owner() -> Control:
	return root.gui_get_focus_owner()
