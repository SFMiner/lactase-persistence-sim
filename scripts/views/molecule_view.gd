extends ViewBase
## Module A, "Molecules": the lactose digestion sandbox (GDD section 4).
## The student sets how much lactose and how much lactase there is, then runs, steps or resets.
## Compare shows a second strip with the same lactose, the same seed and a different amount of
## lactase, so the only thing that differs between the two is the enzyme.

# === CONSTANTS ===
## Fixed seed: Reset replays the same starting picture, so comparisons are fair.
const RUN_SEED: int = 7

# === PUBLIC VARIABLES ===
var model_a: MoleculeModel = MoleculeModel.new()
var model_b: MoleculeModel = MoleculeModel.new()
var panel_a: DigestPanel = null
var panel_b: DigestPanel = null
var lactose_stepper: Stepper = null
var lactase_stepper: Stepper = null
var lactase_b_stepper: Stepper = null
var compare_button: SimButton = null
var changed_button: SimButton = null
var changed_label: Label = null
var compare: bool = false


# === PRIVATE VARIABLES ===
var _announced_finish: bool = false


# === LIFECYCLE METHODS ===
func _process(delta: float) -> void:
	if not running:
		return
	var step: float = delta * app.speed()
	model_a.advance(step)
	if compare:
		model_b.advance(step)
	_after_change()
	if _all_finished():
		set_running(false)


# === VIEW METHODS ===
func title() -> String:
	return "Molecules: lactose and lactase"


func help_steps() -> Array[Dictionary]:
	return [
		{"icon": "lactose", "text": "Set how much lactose is present and how much lactase is available."},
		{"icon": "play", "text": "Press Run to watch, or Step to move one event at a time. Pause whenever you like."},
		{"icon": "compare", "text": "Compare shows two strips with the same lactose and different lactase."},
		{"icon": "reset", "text": "Reset replays the same start, so you can test a prediction."},
	]


func build() -> void:
	add_run_controls("Run", "Step")
	var row: HBoxContainer = UiKit.hbox(6)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(row)
	panel_a = DigestPanel.create(app)
	row.add_child(panel_a)
	panel_b = DigestPanel.create(app)
	panel_b.visible = false
	row.add_child(panel_b)
	lactose_stepper = Stepper.create("Lactose present", "units", 0, MoleculeModel.MAX_LACTOSE, 50, 5)
	lactose_stepper.value_changed.connect(_on_setting_changed)
	controls.add_child(lactose_stepper)
	lactase_stepper = Stepper.create("Lactase available", "enzymes", 0, MoleculeModel.MAX_ENZYMES, 8, 1)
	lactase_stepper.value_changed.connect(_on_setting_changed)
	controls.add_child(lactase_stepper)
	controls.add_child(UiKit.label("Before you run: what do you think will happen if there is less lactase?", UiTheme.SMALL_FONT, UiTheme.MUTED))
	compare_button = UiKit.toggle("Compare two amounts", false, _on_compare_toggled)
	controls.add_child(compare_button)
	lactase_b_stepper = Stepper.create("Lactase in strip B", "enzymes", 0, MoleculeModel.MAX_ENZYMES, 2, 1)
	lactase_b_stepper.value_changed.connect(_on_setting_changed)
	lactase_b_stepper.visible = false
	controls.add_child(lactase_b_stepper)
	changed_button = UiKit.toggle("What changed?", false, _on_changed_toggled)
	controls.add_child(changed_button)
	changed_label = UiKit.label("", UiTheme.SMALL_FONT)
	changed_label.visible = false
	controls.add_child(changed_label)
	controls.add_child(UiKit.label("Units are model units for this lesson, not real amounts in a body.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	_rebuild_models()


func refresh() -> void:
	if panel_a == null:
		return
	_after_change()


func on_play_pressed() -> void:
	if running:
		set_running(false)
		return
	if _all_finished():
		_rebuild_models()
	set_running(true)
	print("lactase-sim: molecules run")


func on_step_pressed() -> void:
	set_running(false)
	if _all_finished():
		return
	model_a.step_event()
	if compare:
		# Keep strip B at the same model time as strip A.
		while model_b.tick_count < model_a.tick_count and not model_b.finished:
			model_b.tick()
	_after_change()


func on_reset_pressed() -> void:
	set_running(false)
	_rebuild_models()
	app.say("Reset. " + DigestPanel.summary_text(model_a))


# === PRIVATE METHODS ===
func _all_finished() -> bool:
	return model_a.finished and (not compare or model_b.finished)


func _rebuild_models() -> void:
	model_a = MoleculeModel.new()
	model_a.setup(lactose_stepper.value, lactase_stepper.value, RUN_SEED)
	panel_a.set_model(model_a)
	model_b = MoleculeModel.new()
	model_b.setup(lactose_stepper.value, lactase_b_stepper.value, RUN_SEED)
	panel_b.set_model(model_b)
	_announced_finish = false
	_after_change()


func _on_setting_changed(_value: int) -> void:
	# A changed setting starts a fresh, paused run: nothing is altered half-way through.
	set_running(false)
	_rebuild_models()


func _on_compare_toggled(on: bool) -> void:
	compare = on
	panel_b.visible = on
	lactase_b_stepper.visible = on
	set_running(false)
	_rebuild_models()


func _on_changed_toggled(on: bool) -> void:
	changed_label.visible = on
	_after_change()
	if on:
		app.say(changed_label.text)


func _after_change() -> void:
	panel_a.set_caption("Strip A: %d lactase" % model_a.enzyme_count if compare else "")
	panel_b.set_caption("Strip B: %d lactase" % model_b.enzyme_count)
	panel_a.redraw()
	panel_b.redraw()
	var text: String = DigestPanel.summary_text(model_a)
	if compare:
		text = "A. " + text + "\nB. " + DigestPanel.summary_text(model_b)
	changed_label.text = text
	step_button.disabled = _all_finished()
	if _all_finished() and not _announced_finish and model_a.tick_count > 0:
		_announced_finish = true
		app.say("Run finished. " + text)
		print("lactase-sim: molecules finished split=%d left=%d lactase=%d" % [model_a.cleaved, model_a.lactose_remaining, model_a.total_enzymes()])
