class_name KeyboardNavigation
extends Node
## Focus boundary for the sims site (hosting requirements section 3; GDD 9.2).
## - Tab / Shift+Tab walk a ring of the live controls. The ring is rebuilt from the scene tree on
##   every key press, so it is always right after a layout change, a view change or a new overlay.
## - Tab past the last control, Shift+Tab before the first, and Escape with nothing open all leave
##   the game: focus is released and the host page gets a `sims:leave-game` message.
## - Escape with an overlay open closes only the innermost overlay.
## - With nothing focused (for example after a click on the canvas), Tab goes to the first control
##   and Shift+Tab to the last.
## Keys are caught in _input, not _unhandled_input, because the GUI consumes Tab first.

# === SIGNALS ===
signal left_game

# === PUBLIC VARIABLES ===
## Returns the Control whose subtree holds the reachable controls right now (the open overlay, or
## the whole screen). Supplied by main.gd.
var root_provider: Callable = Callable()
## Closes the innermost open overlay and returns true, or returns false if nothing is open.
var close_topmost: Callable = Callable()
## Called with the newly focused control, so it can be announced.
var on_focus: Callable = Callable()
## How many times the game has been left. Read by tests.
var leave_count: int = 0


# === LIFECYCLE METHODS ===
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	if event.is_action_pressed("ui_focus_next", true, true):
		move_focus(1, event.is_echo())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_focus_prev", true, true):
		move_focus(-1, event.is_echo())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		escape()
		get_viewport().set_input_as_handled()


# === PUBLIC METHODS ===
## The controls Tab can reach right now, in scene-tree order (which is reading order here).
func current_ring() -> Array[Control]:
	var ring: Array[Control] = []
	if not root_provider.is_valid():
		return ring
	var root: Variant = root_provider.call()
	if root is Control:
		_collect(root, ring)
	return ring


## Moves focus one step. With `stay_inside` (a held key) it stops at the ends instead of leaving,
## so a key held down cannot throw the player out of the game.
func move_focus(direction: int, stay_inside: bool = false) -> void:
	var ring: Array[Control] = current_ring()
	if ring.is_empty():
		if not stay_inside:
			leave_game()
		return
	var focused: Control = get_viewport().gui_get_focus_owner()
	var index: int = ring.find(focused)
	var target: int = 0
	if index < 0:
		target = 0 if direction > 0 else ring.size() - 1
	else:
		target = index + direction
	if target < 0 or target >= ring.size():
		if not stay_inside:
			leave_game()
		return
	ring[target].grab_focus()


## Escape: close the innermost overlay, or leave the game when none is open.
func escape() -> void:
	if close_topmost.is_valid() and bool(close_topmost.call()):
		return
	leave_game()


func leave_game() -> void:
	leave_count += 1
	ExitBridge.leave(get_viewport())
	left_game.emit()


# === PRIVATE METHODS ===
func _collect(node: Node, ring: Array[Control]) -> void:
	if node is Control:
		var c: Control = node
		if not c.visible:
			return
		var usable: bool = c.focus_mode == Control.FOCUS_ALL
		if c is BaseButton and (c as BaseButton).disabled:
			usable = false
		if usable and not c.is_queued_for_deletion():
			ring.append(c)
	for child: Node in node.get_children():
		_collect(child, ring)


func _on_focus_changed(control: Control) -> void:
	if on_focus.is_valid() and control != null:
		on_focus.call(control)
