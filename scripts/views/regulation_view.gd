extends ViewBase
## Module B, "DNA & Lactase": gene regulation across life stages (GDD section 5).
## Each column is one person: their inherited regulatory DNA (top), one of their cells and how
## much it uses LCT (middle), and what that lactase does to lactose (bottom). The bottom strip is
## the Molecules model itself, fed with the lactase amount from this model, so the two views can
## never disagree. Choosing a different regulatory DNA means looking at a different person; it is
## never an edit to a person's DNA.

# === CONSTANTS ===
const RUN_SEED: int = 7

# === PUBLIC VARIABLES ===
var configs: Array[RegulationModel.Config] = []
var models: Array[MoleculeModel] = []
var compare: bool = false
## Which person the controls are editing (0 = A, 1 = B).
var editing: int = 0
var dna_views: Array[DnaRenderer] = []
var cell_views: Array[CellRenderer] = []
var digest_panels: Array[DigestPanel] = []
var columns: Array[VBoxContainer] = []
var headers: Array[Label] = []
var editing_row: ChoiceRow = null
var stage_row: ChoiceRow = null
var variant_row: ChoiceRow = null
var cell_row: ChoiceRow = null
var challenge_row: ChoiceRow = null
var compare_button: SimButton = null
var supplement_button: SimButton = null
var supplement_note: Label = null
var explain_note: Label = null


# === PRIVATE VARIABLES ===
var _anim_time: float = 0.0
var _announced_finish: bool = false


# === LIFECYCLE METHODS ===
func _process(delta: float) -> void:
	if not running:
		return
	var step: float = delta * app.speed()
	_anim_time += step
	for i: int in range(_active_count()):
		models[i].advance(step)
	_redraw()
	if _all_finished():
		set_running(false)
		_redraw()


# === VIEW METHODS ===
func title() -> String:
	return "DNA & Lactase: gene regulation"


func help_steps() -> Array[Dictionary]:
	return [
		{"icon": "dna", "text": "Top: a person's DNA near the LCT gene. The striped part is regulatory DNA; the solid part is the LCT coding region."},
		{"icon": "person", "text": "Choose a life stage and which regulatory DNA the person inherited. Each choice of DNA is a different person."},
		{"icon": "lactase", "text": "Middle: how much the cell uses LCT, and how much lactase it makes."},
		{"icon": "play", "text": "Press Run to see what that lactase does to lactose. Compare puts two people side by side."},
	]


func build() -> void:
	add_run_controls("Run", "Step")
	var a: RegulationModel.Config = RegulationModel.Config.new()
	var b: RegulationModel.Config = RegulationModel.Config.new()
	a.stage = RegulationModel.Stage.ADULT
	b.stage = RegulationModel.Stage.ADULT
	b.variant = RegulationModel.Variant.PERSISTENT
	configs = [a, b]
	var row: HBoxContainer = UiKit.hbox(8)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(row)
	for i: int in range(2):
		var column: VBoxContainer = UiKit.vbox(2)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		columns.append(column)
		var header: Label = UiKit.label("", UiTheme.SMALL_FONT, UiTheme.INK, false)
		header.clip_text = true
		column.add_child(header)
		headers.append(header)
		var dna: DnaRenderer = DnaRenderer.new()
		dna.app = app
		column.add_child(dna)
		dna_views.append(dna)
		var cell: CellRenderer = CellRenderer.new()
		cell.app = app
		column.add_child(cell)
		cell_views.append(cell)
		var digest: DigestPanel = DigestPanel.create(app)
		digest.set_caption("")
		digest.readout.compact = true
		column.add_child(digest)
		digest_panels.append(digest)
	columns[1].visible = false
	var who: Array[String] = ["Person A", "Person B"]
	editing_row = ChoiceRow.create("These controls change", who, 0)
	editing_row.chosen.connect(_on_editing_chosen)
	editing_row.visible = false
	controls.add_child(editing_row)
	var stage_names: Array[String] = []
	stage_names.assign(RegulationModel.STAGE_NAMES)
	stage_row = ChoiceRow.create("Life stage", stage_names, a.stage)
	stage_row.chosen.connect(_on_stage_chosen)
	controls.add_child(stage_row)
	var variant_names: Array[String] = []
	variant_names.assign(RegulationModel.VARIANT_NAMES)
	variant_row = ChoiceRow.create("Regulatory DNA this person inherited", variant_names, a.variant)
	variant_row.chosen.connect(_on_variant_chosen)
	controls.add_child(variant_row)
	controls.add_child(UiKit.label("A person keeps the DNA they inherited. It does not change with age or with what they eat or drink.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	var cell_names: Array[String] = []
	cell_names.assign(RegulationModel.CELL_NAMES)
	cell_row = ChoiceRow.create("Cell to look at", cell_names, a.cell)
	cell_row.chosen.connect(_on_cell_chosen)
	controls.add_child(cell_row)
	var challenge_names: Array[String] = []
	challenge_names.assign(RegulationModel.CHALLENGE_NAMES)
	challenge_row = ChoiceRow.create("Lactose in the meal", challenge_names, a.challenge)
	challenge_row.chosen.connect(_on_challenge_chosen)
	controls.add_child(challenge_row)
	compare_button = UiKit.toggle("Compare two people", false, _on_compare_toggled)
	controls.add_child(compare_button)
	supplement_button = UiKit.toggle("Lactase supplement", false, _on_supplement_toggled)
	controls.add_child(supplement_button)
	supplement_note = UiKit.label("A supplement adds lactase to the food in the gut. It does not change DNA or LCT use, and it is not inherited.", UiTheme.SMALL_FONT, UiTheme.MUTED)
	controls.add_child(supplement_note)
	var lock: HBoxContainer = UiKit.hbox(6)
	var lock_icon: IconBox = IconBox.new()
	lock_icon.icon_id = "lock"
	lock_icon.box_size = 26.0
	lock.add_child(lock_icon)
	lock.add_child(UiKit.label("Lactase amount is set by this model. To set it by hand, use the Molecules view.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	controls.add_child(lock)
	explain_note = UiKit.label("Both people have the same LCT coding region, so they make the same lactase protein. The regulatory DNA changes how much is made, and when.", UiTheme.SMALL_FONT)
	controls.add_child(explain_note)
	controls.add_child(UiKit.label("Levels are model values for this lesson, not measurements.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	_rebuild_models()


func refresh() -> void:
	if supplement_button == null:
		return
	# The supplement and the summary sentence belong to Explain mode.
	supplement_button.visible = app.explain
	supplement_note.visible = app.explain
	explain_note.visible = app.explain
	if not app.explain and (configs[0].supplement or configs[1].supplement):
		configs[0].supplement = false
		configs[1].supplement = false
		supplement_button.set_pressed_no_signal(false)
		set_running(false)
		_rebuild_models()
	_redraw()


func on_play_pressed() -> void:
	if running:
		set_running(false)
		_redraw()
		return
	if _all_finished():
		_rebuild_models()
	set_running(true)
	print("lactase-sim: regulation run")


func on_step_pressed() -> void:
	set_running(false)
	if _all_finished():
		return
	models[0].step_event()
	if compare:
		while models[1].tick_count < models[0].tick_count and not models[1].finished:
			models[1].tick()
		if models[0].finished and not models[1].finished:
			models[1].step_event()
	_redraw()


func on_reset_pressed() -> void:
	set_running(false)
	_rebuild_models()


## Sets one person's scenario and rebuilds. Used by the controls and by tests.
func set_config(index: int, cfg: RegulationModel.Config) -> void:
	configs[index] = cfg
	set_running(false)
	_sync_controls()
	_rebuild_models()


# === PRIVATE METHODS ===
func _active_count() -> int:
	return 2 if compare else 1


func _all_finished() -> bool:
	for i: int in range(_active_count()):
		if not models[i].finished:
			return false
	return true


func _rebuild_models() -> void:
	models.clear()
	for i: int in range(2):
		var m: MoleculeModel = RegulationModel.build_digestion(configs[i], RUN_SEED)
		models.append(m)
		digest_panels[i].set_model(m)
	_announced_finish = false
	_redraw()
	var cfg: RegulationModel.Config = configs[editing]
	var expr: float = RegulationModel.expression_of(cfg)
	print("lactase-sim: regulation %s expression=%.2f lactase=%d" % [RegulationModel.describe(cfg), expr, RegulationModel.enzyme_count(expr)])


func _redraw() -> void:
	for i: int in range(2):
		var cfg: RegulationModel.Config = configs[i]
		var expr: float = RegulationModel.expression_of(cfg)
		var person: String = ("Person A" if i == 0 else "Person B") if compare else "This person"
		headers[i].text = "%s: %s" % [person, RegulationModel.describe(cfg)]
		dna_views[i].variant = cfg.variant
		dna_views[i].expression = expr
		dna_views[i].queue_redraw()
		cell_views[i].cell_type = cfg.cell
		cell_views[i].expression = expr
		cell_views[i].enzyme_count = RegulationModel.enzyme_count(expr)
		cell_views[i].stage_name = RegulationModel.STAGE_NAMES[cfg.stage]
		cell_views[i].anim_time = _anim_time
		cell_views[i].animating = running
		cell_views[i].queue_redraw()
		digest_panels[i].renderer.empty_note = "No lactase from this cell." if models[i].enzyme_count == 0 else ""
		digest_panels[i].redraw()
	if step_button != null:
		step_button.disabled = _all_finished()
	if _all_finished() and not _announced_finish and models[0].tick_count > 0:
		_announced_finish = true
		var text: String = "Run finished. " + headers[0].text + ". " + DigestPanel.summary_text(models[0])
		if compare:
			text += " " + headers[1].text + ". " + DigestPanel.summary_text(models[1])
		app.say(text)
		print("lactase-sim: regulation finished split=%d left=%d" % [models[0].cleaved, models[0].lactose_remaining])


func _sync_controls() -> void:
	var cfg: RegulationModel.Config = configs[editing]
	stage_row.select(cfg.stage, false)
	variant_row.select(cfg.variant, false)
	cell_row.select(cfg.cell, false)
	challenge_row.select(cfg.challenge, false)
	supplement_button.set_pressed_no_signal(cfg.supplement)
	supplement_button.queue_redraw()


func _changed() -> void:
	set_running(false)
	_rebuild_models()
	var cfg: RegulationModel.Config = configs[editing]
	var expr: float = RegulationModel.expression_of(cfg)
	app.say("%s. LCT use %s. Lactase made: %d." % [RegulationModel.describe(cfg), RegulationModel.expression_word(expr), RegulationModel.enzyme_count(expr)])


func _on_editing_chosen(index: int) -> void:
	editing = index
	_sync_controls()


func _on_stage_chosen(index: int) -> void:
	configs[editing].stage = index
	_changed()


func _on_variant_chosen(index: int) -> void:
	configs[editing].variant = index
	_changed()


func _on_cell_chosen(index: int) -> void:
	configs[editing].cell = index
	_changed()


func _on_challenge_chosen(index: int) -> void:
	# The same meal for both people, so the comparison stays fair.
	configs[0].challenge = index
	configs[1].challenge = index
	_changed()


func _on_compare_toggled(on: bool) -> void:
	compare = on
	columns[1].visible = on
	editing_row.visible = on
	if not on:
		editing = 0
		editing_row.select(0, false)
	_sync_controls()
	set_running(false)
	_rebuild_models()


func _on_supplement_toggled(on: bool) -> void:
	configs[editing].supplement = on
	_changed()
