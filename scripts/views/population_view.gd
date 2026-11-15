extends ViewBase
## Module C, "Generations": one inherited variant in a population over many generations (GDD 7).
## The student chooses the starting allele frequency and the setting (how fresh milk is used and
## how much of an advantage digesting it gives), then steps one generation or runs ten.
## Changing a control never changes the people already pictured or the allele frequency: only a
## new generation does. Compare runs two settings from the same starting population.

# === CONSTANTS ===
## Seconds between generations while running at 1x.
const GENERATION_SECONDS: float = 0.6
const RUN_LENGTH: int = 10

# === PUBLIC VARIABLES ===
var model_a: PopulationModel = PopulationModel.new()
var model_b: PopulationModel = PopulationModel.new()
var compare: bool = false
## Which setting the controls are editing (0 = A, 1 = B).
var editing: int = 0
## 0 = allele frequency chart, 1 = adult phenotype chart.
var chart_metric: int = 0
var pop_a: PopulationRenderer = null
var pop_b: PopulationRenderer = null
var chart: ChartView = null
var counts_label: Label = null
var start_row: ChoiceRow = null
var editing_row: ChoiceRow = null
var context_row: ChoiceRow = null
var strength_row: ChoiceRow = null
var metric_row: ChoiceRow = null
var compare_button: SimButton = null
var advantage_label: Label = null
var explain_note: Label = null


# === PRIVATE VARIABLES ===
var _timer: float = 0.0
var _left_in_run: int = 0
var _pops: BoxContainer = null
var _split: BoxContainer = null


# === LIFECYCLE METHODS ===
func _process(delta: float) -> void:
	if not running:
		return
	_timer += delta * app.speed()
	while _timer >= GENERATION_SECONDS and _left_in_run > 0:
		_timer -= GENERATION_SECONDS
		_advance_one()
		_left_in_run -= 1
	if _left_in_run <= 0:
		set_running(false)
		app.say(_counts_text(model_a))
		print("lactase-sim: population run done gen=%d p=%.4f" % [model_a.generation, model_a.p])


# === VIEW METHODS ===
func title() -> String:
	return "Generations: a population over time"


func help_steps() -> Array[Dictionary]:
	return [
		{"icon": "person", "text": "Each person is a newborn of one generation. The badge shows the two alleles they inherited: P or n."},
		{"icon": "settings", "text": "Choose the starting share of P and the setting the population lives in."},
		{"icon": "step", "text": "Step makes the next generation. Run makes ten. The people already pictured never change."},
		{"icon": "chart", "text": "The chart shows the share of allele P over the generations. Compare runs two settings from the same start."},
	]


func build() -> void:
	add_run_controls("Run 10 generations", "Step 1 generation")
	_split = BoxContainer.new()
	_split.add_theme_constant_override("separation", 6)
	_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_child(_split)
	_pops = BoxContainer.new()
	_pops.vertical = true
	_pops.add_theme_constant_override("separation", 4)
	_pops.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pops.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pops.size_flags_stretch_ratio = 0.85
	_split.add_child(_pops)
	pop_a = PopulationRenderer.new()
	pop_a.app = app
	pop_a.model = model_a
	pop_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pop_a.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pops.add_child(pop_a)
	pop_b = PopulationRenderer.new()
	pop_b.app = app
	pop_b.model = model_b
	pop_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pop_b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pop_b.visible = false
	_pops.add_child(pop_b)
	chart = ChartView.new()
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_child(chart)
	counts_label = UiKit.label("", UiTheme.SMALL_FONT)
	stage.add_child(counts_label)
	var starts: Array[String] = []
	starts.assign(PopulationModel.INITIAL_NAMES)
	start_row = ChoiceRow.create("Share of allele P at the start (resets the run)", starts, 1)
	start_row.chosen.connect(_on_start_chosen)
	controls.add_child(start_row)
	compare_button = UiKit.toggle("Compare two settings", false, _on_compare_toggled)
	compare_button.icon_id = "compare"
	controls.add_child(compare_button)
	var which: Array[String] = ["Setting A", "Setting B"]
	editing_row = ChoiceRow.create("These controls change", which, 0)
	editing_row.chosen.connect(_on_editing_chosen)
	editing_row.visible = false
	controls.add_child(editing_row)
	var contexts: Array[String] = []
	contexts.assign(PopulationModel.CONTEXT_NAMES)
	context_row = ChoiceRow.create("How the population uses milk", contexts, model_a.context)
	context_row.chosen.connect(_on_context_chosen)
	controls.add_child(context_row)
	var strengths: Array[String] = []
	strengths.assign(PopulationModel.STRENGTH_NAMES)
	strength_row = ChoiceRow.create("Advantage where fresh milk matters", strengths, model_a.strength)
	strength_row.chosen.connect(_on_strength_chosen)
	controls.add_child(strength_row)
	advantage_label = UiKit.label("", UiTheme.SMALL_FONT)
	controls.add_child(advantage_label)
	var metrics: Array[String] = ["Allele P", "Adults who make lactase"]
	metric_row = ChoiceRow.create("Chart shows the share of", metrics, 0)
	metric_row.chosen.connect(_on_metric_chosen)
	controls.add_child(metric_row)
	explain_note = UiKit.label("Milk use does not cause the P variant or change anyone's DNA. P was already there, inherited. Where digesting fresh milk helps people raise more children, people with P leave more descendants, so P becomes more common over generations.", UiTheme.SMALL_FONT)
	controls.add_child(explain_note)
	controls.add_child(UiKit.label("The advantage sizes are made up for this model. They are not measurements from history, and the model does not stand for any real group or place.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	model_b.set_conditions(PopulationModel.Context.MILK_IMPORTANT, PopulationModel.Strength.MILD)
	_update()


func refresh() -> void:
	if chart == null:
		return
	_update()


func layout_changed(view_size: Vector2) -> void:
	# Side by side when wide; stacked when the frame is narrow.
	_split.vertical = view_size.x < 700.0
	_pops.vertical = not _split.vertical


func on_play_pressed() -> void:
	if running:
		set_running(false)
		return
	_left_in_run = RUN_LENGTH
	_timer = 0.0
	if app.reduced_motion():
		# No animation: show the ten generations at once.
		for i: int in range(RUN_LENGTH):
			_advance_one()
		_left_in_run = 0
		app.say(_counts_text(model_a))
		print("lactase-sim: population run done gen=%d p=%.4f" % [model_a.generation, model_a.p])
		return
	set_running(true)
	print("lactase-sim: population run")


func on_step_pressed() -> void:
	set_running(false)
	_advance_one()
	app.say(_counts_text(model_a))
	print("lactase-sim: population step gen=%d p=%.4f" % [model_a.generation, model_a.p])


func on_reset_pressed() -> void:
	set_running(false)
	model_a.reset(model_a.p_start)
	model_b.reset(model_a.p_start)
	_update()
	app.say("Reset to generation 0. " + _counts_text(model_a))


# === PRIVATE METHODS ===
func _advance_one() -> void:
	model_a.step_generation()
	# Setting B always advances too, so both runs share the same generation number.
	model_b.step_generation()
	_update()


func _edited() -> PopulationModel:
	return model_b if editing == 1 else model_a


func _counts_text(m: PopulationModel) -> String:
	var c: Array[int] = PopulationModel.avatar_counts(m.p, 100)
	return "Generation %d. Allele P: %.1f%%. Per 100 newborns: PP %d, Pn %d, nn %d. Adults who make lactase: %.1f%%." % [
		m.generation, m.p * 100.0, c[0], c[1], c[2], PopulationModel.phenotype_share(m.p) * 100.0]


func _setting_text(m: PopulationModel) -> String:
	var text: String = PopulationModel.CONTEXT_NAMES[m.context].to_lower()
	if m.advantage_on():
		text += ", %s advantage" % PopulationModel.STRENGTH_NAMES[m.strength].to_lower()
	else:
		text += ", no advantage"
	return text


func _update() -> void:
	pop_a.caption = "A. " if compare else ""
	pop_b.caption = "B. "
	pop_a.queue_redraw()
	pop_b.queue_redraw()
	var text: String = _counts_text(model_a)
	if compare:
		text = "A (%s). %s\nB (%s). %s" % [_setting_text(model_a), text, _setting_text(model_b), _counts_text(model_b)]
	counts_label.text = text
	var m: PopulationModel = _edited()
	var w: Array[float] = PopulationModel.weights(m.context, m.strength)
	if m.advantage_on():
		advantage_label.text = "Advantage now: ON. In this model, adults who make lactase leave %.2f times as many children." % w[0]
	elif m.context == PopulationModel.Context.LITTLE_MILK:
		advantage_label.text = "Advantage now: OFF. Fresh milk is not used here, so making lactase as an adult changes nothing."
	else:
		advantage_label.text = "Advantage now: OFF (set to None)."
	explain_note.visible = app.explain
	chart.chart_title = "Allele P in the population (%)" if chart_metric == 0 else "Adults who keep making lactase (%)"
	var list: Array[Dictionary] = []
	list.append({
		"name": "A: " + _setting_text(model_a) if compare else _setting_text(model_a),
		"values": model_a.history_p if chart_metric == 0 else model_a.history_phenotype,
		"color": UiTheme.SERIES_A, "dashed": false, "square": false, "marks": model_a.change_marks,
	})
	if compare:
		list.append({
			"name": "B: " + _setting_text(model_b),
			"values": model_b.history_p if chart_metric == 0 else model_b.history_phenotype,
			"color": UiTheme.SERIES_B, "dashed": true, "square": true, "marks": model_b.change_marks,
		})
	chart.series = list
	chart.queue_redraw()


func _sync_controls() -> void:
	var m: PopulationModel = _edited()
	context_row.select(m.context, false)
	strength_row.select(m.strength, false)


func _on_start_chosen(index: int) -> void:
	set_running(false)
	var start: float = PopulationModel.INITIAL_CHOICES[index]
	model_a.reset(start)
	model_b.reset(start)
	_update()
	app.say("Start: allele P at %s. Generation 0." % PopulationModel.INITIAL_NAMES[index])
	print("lactase-sim: population start p=%.2f" % start)


func _on_compare_toggled(on: bool) -> void:
	compare = on
	pop_b.visible = on
	editing_row.visible = on
	if not on:
		editing = 0
		editing_row.select(0, false)
	# B restarts from A's starting population, so the two runs are a fair comparison.
	set_running(false)
	model_a.reset(model_a.p_start)
	model_b.reset(model_a.p_start)
	_sync_controls()
	_update()


func _on_editing_chosen(index: int) -> void:
	editing = index
	_sync_controls()
	_update()


func _on_context_chosen(index: int) -> void:
	var m: PopulationModel = _edited()
	m.set_conditions(index, m.strength)
	_update()
	app.say(advantage_label.text)


func _on_strength_chosen(index: int) -> void:
	var m: PopulationModel = _edited()
	m.set_conditions(m.context, index)
	_update()
	app.say(advantage_label.text)


func _on_metric_chosen(index: int) -> void:
	chart_metric = index
	_update()
