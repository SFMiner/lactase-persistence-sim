extends ViewBase
## "Evidence": the Kanna / Alissa DNA comparison from the lesson (GDD section 6).
## Zoom from the two copies of chromosome 2 to the LCT coding excerpt and the upstream excerpt,
## then compare people. The student does the highlighting; "Check highlighting" only says whether
## it matches the lesson data. Nothing here changes any other model.

# === CONSTANTS ===
const ZOOM_NAMES: Array[String] = ["Chromosome 2", "LCT coding excerpt", "Upstream excerpt"]

# === PUBLIC VARIABLES ===
var person: int = EvidenceData.KANNA
## 0 = chromosome, 1 = coding excerpt, 2 = upstream excerpt.
var zoom: int = 0
var compare: bool = false
var dna: DnaRenderer = null
var grid: SequenceGrid = null
var result_label: Label = null
var person_label: Label = null
var person_row: ChoiceRow = null
var zoom_row: ChoiceRow = null
var compare_button: SimButton = null
var check_button: SimButton = null
var clear_button: SimButton = null
var explain_note: Label = null
## Highlights per region: region -> Dictionary of cell keys.
var highlights: Dictionary = {EvidenceData.Region.CODING: {}, EvidenceData.Region.UPSTREAM: {}}
## The last check result per region ("" before any check).
var last_result: Dictionary = {EvidenceData.Region.CODING: "", EvidenceData.Region.UPSTREAM: ""}


# === VIEW METHODS ===
func title() -> String:
	return "Evidence: comparing DNA"


func help_steps() -> Array[Dictionary]:
	return [
		{"icon": "person", "text": "Pick a person. Each person has two copies of chromosome 2."},
		{"icon": "zoom", "text": "Zoom from the chromosome to the LCT coding excerpt, then to the upstream excerpt."},
		{"icon": "compare", "text": "Compare lines up all four people. Click a group of letters (or use arrow keys and Enter) to highlight it."},
		{"icon": "check", "text": "Check highlighting tells you whether your highlights match the lesson data."},
	]


func build() -> void:
	person_label = UiKit.label("", UiTheme.FONT_SIZE, UiTheme.INK, false)
	person_label.clip_text = true
	stage.add_child(person_label)
	dna = DnaRenderer.new()
	dna.app = app
	dna.zoom = 0
	dna.custom_minimum_size = Vector2(200, 96)
	dna.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(dna)
	grid = SequenceGrid.new()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.highlights_changed.connect(_on_highlights_changed)
	grid.cursor_moved.connect(app.say)
	stage.add_child(grid)
	result_label = UiKit.label("", UiTheme.FONT_SIZE)
	stage.add_child(result_label)
	var names: Array[String] = []
	names.assign(EvidenceData.SHORT_NAMES)
	person_row = ChoiceRow.create("Person", names, person)
	person_row.chosen.connect(_on_person_chosen)
	controls.add_child(person_row)
	var zooms: Array[String] = []
	zooms.assign(ZOOM_NAMES)
	zoom_row = ChoiceRow.create("Zoom", zooms, zoom)
	zoom_row.chosen.connect(_on_zoom_chosen)
	controls.add_child(zoom_row)
	compare_button = UiKit.toggle("Compare all four people", false, _on_compare_toggled)
	compare_button.icon_id = "compare"
	controls.add_child(compare_button)
	controls.add_child(UiKit.label("What stayed the same? What changed?", UiTheme.FONT_SIZE))
	check_button = UiKit.button("Check highlighting", "check", check_highlighting)
	controls.add_child(check_button)
	clear_button = UiKit.button("Clear highlights", "close", clear_highlights)
	controls.add_child(clear_button)
	explain_note = UiKit.label("The one difference is outside the LCT protein-coding region. In the lesson's model, this upstream DNA affects regulation: how much lactase is made, not what the lactase protein is.", UiTheme.SMALL_FONT)
	controls.add_child(explain_note)
	controls.add_child(UiKit.label("These are short teaching excerpts from the lesson, not full DNA sequences or a medical test. The rest of the DNA is not shown.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	_update()


func refresh() -> void:
	if grid == null:
		return
	_update()


## Compares the student's highlights with the lesson data and reports only whether they match.
func check_highlighting() -> void:
	if zoom == 0:
		return
	var region: int = _region()
	var result: Dictionary = EvidenceData.check_highlights(region, grid.highlighted_keys())
	grid.marks.clear()
	for key: int in result["right"]:
		grid.marks[key] = true
	for key: int in result["wrong"]:
		grid.marks[key] = false
	var text: String = ""
	var right: Array = result["right"]
	var wrong: Array = result["wrong"]
	var missed: int = int(result["missed"])
	if bool(result["exact"]):
		if right.is_empty():
			text = "Matches the lesson data: there is no difference in this excerpt."
		else:
			text = "Matches the lesson data: you highlighted every difference and nothing else."
	else:
		var parts: PackedStringArray = PackedStringArray()
		if not wrong.is_empty():
			parts.append("%d highlighted group(s) are the same as the other rows" % wrong.size())
		if missed > 0:
			parts.append("%d difference(s) are not highlighted yet" % missed)
		text = "Not a match yet: " + "; ".join(parts) + "."
	last_result[region] = text
	result_label.text = text
	grid.queue_redraw()
	app.say(text)
	print("lactase-sim: evidence check exact=%s" % str(bool(result["exact"])))


func clear_highlights() -> void:
	if zoom == 0:
		return
	var region: int = _region()
	var store: Dictionary = highlights[region]
	store.clear()
	grid.marks.clear()
	last_result[region] = ""
	_update()
	app.say("Highlights cleared")


# === PRIVATE METHODS ===
func _region() -> int:
	return EvidenceData.Region.CODING if zoom == 1 else EvidenceData.Region.UPSTREAM


func _update() -> void:
	var show_grid: bool = zoom > 0
	var who: String = "All four people" if (compare and show_grid) else EvidenceData.NAMES[person]
	var line: String = who + ": " + ZOOM_NAMES[zoom].to_lower()
	if app.explain and not (compare and show_grid):
		line += "   (" + EvidenceData.LESSON_NOTES[person] + ")"
	person_label.text = line
	dna.zoom = zoom
	dna.focus_region = -1 if zoom == 0 else _region()
	# In the comparison the table needs the room, so the zoom picture steps aside.
	dna.visible = not (compare and show_grid)
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL if compare else Control.SIZE_FILL
	dna.queue_redraw()
	grid.visible = show_grid
	if show_grid:
		var region: int = _region()
		if grid.region != region:
			grid.marks.clear()
		grid.region = region
		grid.highlights = highlights[region]
		var rows: Array[Vector2i] = []
		if compare:
			for p: int in range(EvidenceData.PERSON_COUNT):
				for c: int in range(EvidenceData.COPY_COUNT):
					rows.append(Vector2i(p, c))
		else:
			for c: int in range(EvidenceData.COPY_COUNT):
				rows.append(Vector2i(person, c))
		grid.set_rows(rows)
		result_label.text = str(last_result[region])
	else:
		result_label.text = ""
	result_label.visible = show_grid
	check_button.disabled = not show_grid
	clear_button.disabled = not show_grid
	check_button.queue_redraw()
	clear_button.queue_redraw()
	person_row.set_disabled(compare and show_grid)
	explain_note.visible = app.explain and zoom == 2
	print("lactase-sim: evidence person=%d zoom=%d compare=%s" % [person, zoom, str(compare)])


func _on_person_chosen(index: int) -> void:
	person = index
	grid.marks.clear()
	_update()


func _on_zoom_chosen(index: int) -> void:
	zoom = index
	_update()
	app.say(person_label.text)


func _on_compare_toggled(on: bool) -> void:
	compare = on
	grid.marks.clear()
	if on and zoom == 0:
		zoom = 1
		zoom_row.select(1, false)
	_update()


func _on_highlights_changed() -> void:
	last_result[_region()] = ""
	result_label.text = ""
