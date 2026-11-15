class_name ViewBase
extends Control
## Shared frame for the four model views: a toolbar row (run controls), a stage (the picture) and
## a controls panel. In a narrow frame the stage and the controls become two tabs, so one panel is
## shown at a time and nothing has to shrink below a readable size. In a very short frame the
## whole view scrolls. Each view fills in build() and refresh().

# === CONSTANTS ===
const CONTROLS_WIDTH: float = 304.0
const MIN_BODY_HEIGHT: float = 250.0

# === PUBLIC VARIABLES ===
var app: AppState = null
var narrow: bool = false
var running: bool = false
var toolbar: HFlowContainer = null
var toolbar_reserve: Control = null
var stage_card: PanelContainer = null
var stage: VBoxContainer = null
var controls_card: PanelContainer = null
var controls: VBoxContainer = null
var play_button: SimButton = null
var step_button: SimButton = null
var reset_button: SimButton = null
var speed_button: SimButton = null
var tab_row: ChoiceRow = null


# === PRIVATE VARIABLES ===
var _column: VBoxContainer = null
var _tab: int = 0


# === LIFECYCLE METHODS ===
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if app == null:
		app = AppState.new()
		app.access.persist = false
	_build_frame()
	build()
	app.changed.connect(_on_app_changed)
	_on_app_changed()


# === VIRTUAL METHODS ===
## Fill the toolbar, stage and controls.
func build() -> void:
	pass


## Redraw after labels, mode, motion or speed changed.
func refresh() -> void:
	pass


func title() -> String:
	return ""


## Illustrated help: Array of {"icon": String, "text": String}.
func help_steps() -> Array[Dictionary]:
	return []


func on_play_pressed() -> void:
	pass


func on_step_pressed() -> void:
	pass


func on_reset_pressed() -> void:
	pass


# === PUBLIC METHODS ===
## Called by main.gd whenever the frame changes size.
func apply_layout(view_size: Vector2, is_narrow: bool, reserve: Vector2, bar_height: float) -> void:
	narrow = is_narrow
	# Keep the site's full-screen button corner clear if it reaches below the top bar.
	var overhang: bool = reserve.y > bar_height
	toolbar_reserve.custom_minimum_size = Vector2(reserve.x if overhang else 0.0, 0.0)
	toolbar_reserve.visible = overhang
	tab_row.visible = narrow
	controls_card.custom_minimum_size.x = 0.0 if narrow else CONTROLS_WIDTH
	controls_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	_apply_tab()
	layout_changed(view_size)


## Views override this to rearrange their stage for the new size.
func layout_changed(_view_size: Vector2) -> void:
	pass


## Adds Run/Pause, Step, Reset and Speed to the toolbar.
func add_run_controls(run_caption: String = "Run", step_caption: String = "Step") -> void:
	play_button = UiKit.button(run_caption, "play", on_play_pressed)
	play_button.min_width = 104.0
	play_button.set_meta("run_caption", run_caption)
	toolbar.add_child(play_button)
	step_button = UiKit.button(step_caption, "step", on_step_pressed)
	toolbar.add_child(step_button)
	reset_button = UiKit.button("Reset", "reset", on_reset_pressed)
	toolbar.add_child(reset_button)
	speed_button = UiKit.button("Speed 1x", "speed", app.cycle_speed)
	speed_button.min_width = 124.0
	toolbar.add_child(speed_button)


## Starts or stops the run and updates the Run/Pause button.
func set_running(on: bool) -> void:
	running = on
	if play_button != null:
		play_button.caption = "Pause" if on else str(play_button.get_meta("run_caption"))
		play_button.icon_id = "pause" if on else "play"


## Shows the stage (0) or the controls (1) when the frame is narrow.
func show_tab(index: int) -> void:
	_tab = clampi(index, 0, 1)
	tab_row.select(_tab, false)
	_apply_tab()


# === PRIVATE METHODS ===
func _build_frame() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side: String in ["margin_left", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 6)
	margin.add_theme_constant_override("margin_top", 4)
	scroll.add_child(margin)
	_column = UiKit.vbox(4)
	margin.add_child(_column)
	var top: HBoxContainer = UiKit.hbox(6)
	_column.add_child(top)
	toolbar = UiKit.flow(6)
	toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(toolbar)
	toolbar_reserve = UiKit.spacer(0.0)
	top.add_child(toolbar_reserve)
	var tab_names: Array[String] = ["Model", "Controls"]
	tab_row = ChoiceRow.create("", tab_names, 0, true)
	tab_row.title_label.visible = false
	tab_row.chosen.connect(show_tab)
	tab_row.visible = false
	toolbar.add_child(tab_row)
	var body: HBoxContainer = UiKit.hbox(6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size.y = MIN_BODY_HEIGHT
	_column.add_child(body)
	stage_card = UiKit.card()
	stage_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage_card)
	stage = UiKit.vbox(4)
	stage_card.add_child(stage)
	controls_card = UiKit.card()
	controls_card.custom_minimum_size.x = CONTROLS_WIDTH
	body.add_child(controls_card)
	var controls_scroll: ScrollContainer = ScrollContainer.new()
	controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls_scroll.follow_focus = true
	controls_card.add_child(controls_scroll)
	controls = UiKit.vbox(8)
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls_scroll.add_child(controls)


func _apply_tab() -> void:
	stage_card.visible = (not narrow) or _tab == 0
	controls_card.visible = (not narrow) or _tab == 1


func _on_app_changed() -> void:
	if speed_button != null:
		speed_button.caption = "Speed " + app.speed_name()
	refresh()
