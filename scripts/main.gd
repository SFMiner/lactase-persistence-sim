extends Control
## Lactase Persistence Simulator: the screen that holds everything else.
## It builds the top bar (Home, Explore/Explain, Labels, Help, Settings), swaps the model views,
## owns the Help and Settings overlays, and wires keyboard navigation, the responsive layout and
## the screen-reader announcer. It contains no science; each view owns its own model.

# === CONSTANTS ===
const VIEW_SCENES: Dictionary = {
	"menu": "res://scenes/ModelSelect.tscn",
	"molecules": "res://scenes/MoleculeView.tscn",
	"regulation": "res://scenes/RegulationView.tscn",
	"evidence": "res://scenes/EvidenceView.tscn",
	"population": "res://scenes/PopulationView.tscn",
}
const GAME_TITLE: String = "Lactase Persistence Simulator"

# === PUBLIC VARIABLES ===
## Tests set this to false before adding the scene, so no saved settings are read or written.
var persist_settings: bool = true
var app: AppState = null
var layout: ResponsiveLayout = null
var nav: KeyboardNavigation = null
var announcer: Announcer = null
var current_view: Control = null
var current_id: String = ""
var overlays: Array[OverlayPanel] = []
var top_bar: PanelContainer = null
var home_button: SimButton = null
var mode_button: SimButton = null
var labels_button: SimButton = null
var help_button: SimButton = null
var settings_button: SimButton = null
var title_label: Label = null


# === PRIVATE VARIABLES ===
var _content: Control = null
var _overlay_layer: Control = null
var _corner: Control = null


# === LIFECYCLE METHODS ===
func _ready() -> void:
	theme = UiTheme.build()
	app = AppState.new()
	app.access.persist = persist_settings
	if persist_settings:
		app.access.load_saved()
	var query: Dictionary = app.access.read_browser()
	app.apply_query(query)
	announcer = Announcer.new()
	add_child(announcer)
	app.announcer = announcer
	_build()
	nav = KeyboardNavigation.new()
	nav.root_provider = _focus_root
	nav.close_topmost = close_topmost
	nav.on_focus = _announce_focus
	add_child(nav)
	app.changed.connect(_on_app_changed)
	layout = ResponsiveLayout.new()
	layout.text_scale = app.access.text_scale()
	layout.layout_changed.connect(_on_layout)
	add_child(layout)
	show_view(str(query.get("model", "menu")))
	_on_app_changed()
	# The browser smoke test waits for this line: a grey canvas with no errors must not pass.
	print("lactase-sim: boot ok")


# === PUBLIC METHODS ===
## Opens one of the views: "menu", "molecules", "regulation", "evidence" or "population".
func show_view(id: String) -> void:
	var target: String = id if VIEW_SCENES.has(id) else "menu"
	if current_view != null:
		_content.remove_child(current_view)
		current_view.queue_free()
		current_view = null
	var scene: PackedScene = load(str(VIEW_SCENES[target]))
	var view: Control = scene.instantiate()
	if "app" in view:
		view.set("app", app)
	current_view = view
	current_id = target
	_content.add_child(view)
	if view.has_signal("model_chosen"):
		view.connect("model_chosen", show_view)
	home_button.visible = target != "menu"
	title_label.text = _view_title()
	_on_layout(layout.view_size)
	announcer.say(_view_title())
	print("lactase-sim: view " + target)


func open_help() -> void:
	var o: OverlayPanel = _open_overlay("Help: " + _view_title())
	var steps: Array[Dictionary] = []
	if current_view.has_method("help_steps"):
		steps = current_view.call("help_steps")
	for step: Dictionary in steps:
		_help_row(o, str(step.get("icon", "")), str(step.get("text", "")))
	_help_row(o, "next", "Keyboard: Tab and Shift+Tab move between controls. Enter or Space presses a button. Arrow keys move a slider.")
	_help_row(o, "close", "Escape closes this box. With nothing open, Escape (or Tab past the last control) leaves the simulator.")
	_help_row(o, "labels", "Shapes are symbols, and all numbers are model units made for this lesson. They are not real measurements.")
	o.close_button.grab_focus()
	print("lactase-sim: help open")


func open_settings() -> void:
	var o: OverlayPanel = _open_overlay("Settings")
	var sizes: Array[String] = []
	sizes.assign(AccessibilityOptions.TEXT_NAMES)
	var text_row: ChoiceRow = ChoiceRow.create("Text size", sizes, app.access.text_size)
	text_row.chosen.connect(app.set_text_size)
	o.content.add_child(text_row)
	var motion: SimButton = UiKit.toggle("Reduce motion", app.reduced_motion(), app.set_reduced_motion)
	o.content.add_child(motion)
	o.content.add_child(UiKit.label("Reduce motion: molecules and people stop drifting. Results appear in steps and every count stays the same.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	o.content.add_child(UiKit.label("These two settings are saved on this device only.", UiTheme.SMALL_FONT, UiTheme.MUTED))
	o.close_button.grab_focus()
	print("lactase-sim: settings open")


## Closes the innermost overlay. Returns false when none is open.
func close_topmost() -> bool:
	if overlays.is_empty():
		return false
	overlays[-1].close()
	return true


func overlay_open() -> bool:
	return not overlays.is_empty()


# === PRIVATE METHODS ===
func _build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = UiTheme.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var column: VBoxContainer = UiKit.vbox(0)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(column)
	top_bar = PanelContainer.new()
	var bar_style: StyleBoxFlat = StyleBoxFlat.new()
	bar_style.bg_color = UiTheme.PANEL
	bar_style.border_color = UiTheme.LINE
	bar_style.border_width_bottom = 1
	bar_style.content_margin_left = 6.0
	bar_style.content_margin_right = 0.0
	bar_style.content_margin_top = 4.0
	bar_style.content_margin_bottom = 4.0
	top_bar.add_theme_stylebox_override("panel", bar_style)
	column.add_child(top_bar)
	var row: HBoxContainer = UiKit.hbox(6)
	top_bar.add_child(row)
	home_button = UiKit.button("Home", "home", show_view.bind("menu"))
	row.add_child(home_button)
	title_label = UiKit.label(GAME_TITLE, UiTheme.TITLE_FONT, UiTheme.INK, false)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	mode_button = UiKit.button("Mode: Explore", "view", _toggle_mode)
	row.add_child(mode_button)
	labels_button = UiKit.button("Labels: On", "labels", _toggle_labels)
	row.add_child(labels_button)
	help_button = UiKit.button("Help", "help", open_help)
	row.add_child(help_button)
	settings_button = UiKit.button("Settings", "settings", open_settings)
	row.add_child(settings_button)
	# Empty space under the site's full-screen button.
	_corner = UiKit.spacer(ResponsiveLayout.RESERVED_CSS.x)
	row.add_child(_corner)
	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.clip_contents = true
	column.add_child(_content)
	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay_layer)


func _view_title() -> String:
	if current_view != null and current_view.has_method("title"):
		var t: String = str(current_view.call("title"))
		if t != "":
			return t
	return GAME_TITLE


func _toggle_mode() -> void:
	app.set_explain(not app.explain)
	announcer.say("Explain mode: more labels" if app.explain else "Explore mode: fewer labels")


func _toggle_labels() -> void:
	app.set_labels(not app.labels)


func _on_app_changed() -> void:
	mode_button.caption = "Mode: Explain" if app.explain else "Mode: Explore"
	labels_button.caption = "Labels: On" if app.labels else "Labels: Off"
	if layout != null and not is_equal_approx(layout.text_scale, app.access.text_scale()):
		layout.set_text_scale(app.access.text_scale())


func _on_layout(view_size: Vector2) -> void:
	var narrow: bool = layout.is_narrow()
	var reserve: Vector2 = layout.reserved_corner()
	_corner.custom_minimum_size = Vector2(reserve.x, 0.0)
	home_button.compact = narrow
	help_button.compact = narrow
	settings_button.compact = narrow
	mode_button.compact = view_size.x < 620.0
	labels_button.compact = view_size.x < 620.0
	title_label.visible = not narrow
	# Without the title the spacer has to push the buttons left of the reserved corner.
	_corner.size_flags_horizontal = Control.SIZE_EXPAND_FILL if narrow else Control.SIZE_FILL
	var bar_height: float = UiKit.target_px + 9.0
	if current_view != null and current_view.has_method("apply_layout"):
		current_view.call("apply_layout", view_size - Vector2(0.0, bar_height), narrow, reserve, bar_height)
	for o: OverlayPanel in overlays:
		o.fit(view_size)


func _open_overlay(title: String) -> OverlayPanel:
	var o: OverlayPanel = OverlayPanel.create(title)
	_overlay_layer.add_child(o)
	overlays.append(o)
	o.fit(layout.view_size)
	var opener: Control = get_viewport().gui_get_focus_owner()
	o.closed.connect(_on_overlay_closed.bind(o, opener))
	announcer.say(title + " opened")
	return o


func _on_overlay_closed(o: OverlayPanel, opener: Control) -> void:
	overlays.erase(o)
	# Put focus back where it was, so a keyboard user is not dropped at the start of the page.
	if opener != null and is_instance_valid(opener) and opener.is_visible_in_tree():
		opener.grab_focus()
	print("lactase-sim: overlay closed")


func _help_row(o: OverlayPanel, icon_id: String, text: String) -> void:
	var row: HBoxContainer = UiKit.hbox(10)
	var box: IconBox = IconBox.new()
	box.icon_id = icon_id
	row.add_child(box)
	row.add_child(UiKit.label(text))
	o.content.add_child(row)


## Tab stays inside the innermost overlay while one is open.
func _focus_root() -> Control:
	if not overlays.is_empty():
		return overlays[-1]
	return self


func _announce_focus(control: Control) -> void:
	var text: String = ""
	if control.has_method("spoken"):
		text = str(control.call("spoken"))
	elif control.get_parent() != null and control.get_parent().get_parent() != null and control.get_parent().get_parent().has_method("spoken"):
		text = str(control.get_parent().get_parent().call("spoken"))
	if text != "":
		announcer.say(text)
