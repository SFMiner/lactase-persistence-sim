class_name SequenceGrid
extends Control
## The DNA comparison table: one row per person per chromosome copy, one cell per group of bases,
## with the letters lined up in columns. The student highlights cells; nothing is highlighted for
## them. One Tab stop: arrow keys move the cell cursor, Enter or Space highlights. Each cell is at
## least one touch target tall.
## A highlight is a thick frame plus a corner mark, and a check result is a tick or a cross,
## so neither depends on colour.

# === SIGNALS ===
signal highlights_changed
signal cursor_moved(text: String)

# === CONSTANTS ===
const HEADER_H: float = 20.0

# === PUBLIC VARIABLES ===
var region: int = EvidenceData.Region.CODING
## Rows shown, as [person, copy] pairs.
var rows: Array[Vector2i] = []
## Highlighted cell keys (EvidenceData.cell_key) for the current region. Owned by the view.
var highlights: Dictionary = {}
## Check results by cell key: true = matches the lesson data, false = does not.
var marks: Dictionary = {}
var cursor: Vector2i = Vector2i.ZERO


# === LIFECYCLE METHODS ===
func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	add_to_group("sim_target")
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _ready() -> void:
	refresh_min()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var cell: Vector2i = _cell_at(mb.position)
			if cell.x >= 0:
				cursor = cell
				toggle_at_cursor()
			accept_event()
		return
	if not (event is InputEventKey) or not event.is_pressed():
		return
	var move: Vector2i = Vector2i.ZERO
	if event.is_action("ui_left"):
		move = Vector2i(-1, 0)
	elif event.is_action("ui_right"):
		move = Vector2i(1, 0)
	elif event.is_action("ui_up"):
		move = Vector2i(0, -1)
	elif event.is_action("ui_down"):
		move = Vector2i(0, 1)
	elif event.is_action("ui_accept"):
		if not event.is_echo():
			toggle_at_cursor()
		accept_event()
		return
	if move != Vector2i.ZERO:
		move_cursor(move)
		accept_event()


func _draw() -> void:
	var cols: int = EvidenceData.group_count(region)
	var label_w: float = _label_width()
	var cell_w: float = (size.x - label_w) / float(maxi(cols, 1))
	var row_h: float = _row_height()
	for g: int in range(cols):
		Shapes.text_centered(self, Vector2(label_w + (float(g) + 0.5) * cell_w, HEADER_H / 2.0), "group %d" % (g + 1), 11, UiTheme.MUTED)
	var letter_size: int = int(clampf(cell_w * 0.26, 13.0, 19.0))
	for r: int in range(rows.size()):
		var person: int = rows[r].x
		var copy: int = rows[r].y
		var y: float = HEADER_H + float(r) * row_h
		if r > 0 and copy == 0:
			draw_line(Vector2(0, y), Vector2(size.x, y), UiTheme.LINE, 2.0)
		if copy == 0:
			Shapes.text(self, Vector2(2.0, y + 3.0), EvidenceData.SHORT_NAMES[person], 13)
		Shapes.text(self, Vector2(2.0, y + row_h - 18.0) if copy == 0 else Vector2(2.0, y + row_h / 2.0 - 8.0), "copy %d" % (copy + 1), 11, UiTheme.MUTED)
		var groups: PackedStringArray = EvidenceData.groups(EvidenceData.sequence(person, region, copy))
		for g: int in range(cols):
			var rect: Rect2 = Rect2(label_w + float(g) * cell_w + 2.0, y + 2.0, cell_w - 4.0, row_h - 4.0)
			var key: int = EvidenceData.cell_key(person, copy, g)
			var lit: bool = highlights.has(key)
			draw_rect(rect, Color(1.0, 0.93, 0.55, 1) if lit else UiTheme.PANEL)
			draw_rect(rect, UiTheme.INK if lit else UiTheme.LINE, false, 3.0 if lit else 1.0)
			if lit:
				draw_colored_polygon(PackedVector2Array([rect.position, rect.position + Vector2(12, 0), rect.position + Vector2(0, 12)]), UiTheme.INK)
			_draw_letters(groups[g], rect, letter_size)
			if marks.has(key):
				var ok: bool = bool(marks[key])
				var badge: Rect2 = Rect2(rect.end.x - 18.0, rect.position.y + 2.0, 15.0, 15.0)
				draw_rect(badge, UiTheme.PANEL)
				Shapes.icon(self, "check" if ok else "cross", badge, UiTheme.GOOD if ok else UiTheme.BAD)
	if has_focus() and not rows.is_empty():
		var c: Rect2 = Rect2(label_w + float(cursor.x) * cell_w, HEADER_H + float(cursor.y) * row_h, cell_w, row_h)
		draw_rect(c, UiTheme.FOCUS, false, 4.0)


# === PUBLIC METHODS ===
func refresh_min() -> void:
	custom_minimum_size = Vector2(_label_width() + 7.0 * 46.0, HEADER_H + float(maxi(rows.size(), 1)) * UiKit.target_px)
	queue_redraw()


func set_rows(new_rows: Array[Vector2i]) -> void:
	rows = new_rows
	cursor.y = clampi(cursor.y, 0, maxi(rows.size() - 1, 0))
	refresh_min()


func move_cursor(by: Vector2i) -> void:
	if rows.is_empty():
		return
	cursor.x = clampi(cursor.x + by.x, 0, EvidenceData.group_count(region) - 1)
	cursor.y = clampi(cursor.y + by.y, 0, rows.size() - 1)
	queue_redraw()
	cursor_moved.emit(spoken())


func toggle_at_cursor() -> void:
	if rows.is_empty():
		return
	var key: int = cursor_key()
	if highlights.has(key):
		highlights.erase(key)
	else:
		highlights[key] = true
	# An old check result no longer describes the new highlighting.
	marks.clear()
	queue_redraw()
	highlights_changed.emit()
	cursor_moved.emit(spoken())


func cursor_key() -> int:
	return EvidenceData.cell_key(rows[cursor.y].x, rows[cursor.y].y, cursor.x)


func highlighted_keys() -> Array[int]:
	var out: Array[int] = []
	for key: Variant in highlights.keys():
		out.append(int(key))
	return out


## What a screen reader hears for the cell under the cursor.
func spoken() -> String:
	if rows.is_empty():
		return "DNA table"
	var person: int = rows[cursor.y].x
	var copy: int = rows[cursor.y].y
	var letters: String = EvidenceData.groups(EvidenceData.sequence(person, region, copy))[cursor.x]
	var state: String = "highlighted" if highlights.has(cursor_key()) else "not highlighted"
	return "DNA table. %s, copy %d, group %d: %s, %s. Arrow keys move, Enter highlights." % [
		EvidenceData.NAMES[person], copy + 1, cursor.x + 1, " ".join(letters.split("")), state]


# === PRIVATE METHODS ===
func _label_width() -> float:
	return 88.0


func _row_height() -> float:
	return (size.y - HEADER_H) / float(maxi(rows.size(), 1))


func _cell_at(pos: Vector2) -> Vector2i:
	var cols: int = EvidenceData.group_count(region)
	var label_w: float = _label_width()
	if pos.x < label_w or pos.y < HEADER_H or rows.is_empty():
		return Vector2i(-1, -1)
	var cell_w: float = (size.x - label_w) / float(cols)
	var col: int = int((pos.x - label_w) / cell_w)
	var row: int = int((pos.y - HEADER_H) / _row_height())
	if col >= cols or row >= rows.size():
		return Vector2i(-1, -1)
	return Vector2i(col, row)


## Letters are drawn one per fixed slot, so the same position lines up in every row.
func _draw_letters(group: String, rect: Rect2, letter_size: int) -> void:
	var slot: float = minf(rect.size.x / 3.6, float(letter_size) * 1.1)
	var start: float = rect.get_center().x - slot
	for i: int in range(group.length()):
		Shapes.text_centered(self, Vector2(start + float(i) * slot, rect.get_center().y), group[i], letter_size)
