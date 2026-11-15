class_name Stepper
extends VBoxContainer
## A number control with three ways to change it: a slider (drag, or arrow keys when focused) and
## minus / plus buttons. The value and its unit are always written out above the slider.

# === SIGNALS ===
signal value_changed(value: int)

# === PUBLIC VARIABLES ===
var title: String = ""
var unit: String = ""
var value: int = 0
var min_value: int = 0
var max_value: int = 100
var big_step: int = 1
var slider: FocusSlider = null
var minus: SimButton = null
var plus: SimButton = null
var title_label: Label = null


# === INNER CLASSES ===
## An HSlider that draws a focus outline (the built-in slider shows none).
class FocusSlider:
	extends HSlider

	func _init() -> void:
		focus_mode = Control.FOCUS_ALL
		add_to_group("sim_target")
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)

	func _ready() -> void:
		refresh_min()

	func refresh_min() -> void:
		custom_minimum_size = Vector2(90.0, UiKit.target_px)

	func _draw() -> void:
		if has_focus():
			draw_rect(Rect2(Vector2(-3, 2), size + Vector2(6, -4)), UiTheme.FOCUS, false, 4.0)


# === PUBLIC METHODS ===
static func create(caption: String, unit_name: String, lo: int, hi: int, start: int, button_step: int = 1) -> Stepper:
	var s: Stepper = Stepper.new()
	s.title = caption
	s.unit = unit_name
	s.min_value = lo
	s.max_value = hi
	s.big_step = button_step
	s.add_theme_constant_override("separation", 2)
	s.title_label = UiKit.label("", UiTheme.FONT_SIZE)
	s.add_child(s.title_label)
	var row: HBoxContainer = UiKit.hbox(6)
	s.add_child(row)
	s.minus = UiKit.button("", "minus", s._nudge.bind(-1))
	s.minus.caption = "Less " + caption.to_lower()
	s.minus.compact = true
	row.add_child(s.minus)
	s.slider = FocusSlider.new()
	s.slider.min_value = float(lo)
	s.slider.max_value = float(hi)
	s.slider.step = 1.0
	s.slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.slider.value_changed.connect(s._on_slider)
	row.add_child(s.slider)
	s.plus = UiKit.button("", "plus", s._nudge.bind(1))
	s.plus.caption = "More " + caption.to_lower()
	s.plus.compact = true
	row.add_child(s.plus)
	s.set_value(start, false)
	return s


func set_value(v: int, notify: bool = true) -> void:
	var clamped: int = clampi(v, min_value, max_value)
	var changed: bool = clamped != value
	value = clamped
	slider.set_value_no_signal(float(value))
	title_label.text = "%s: %d %s" % [title, value, unit]
	minus.disabled = value <= min_value
	plus.disabled = value >= max_value
	minus.queue_redraw()
	plus.queue_redraw()
	if notify and changed:
		value_changed.emit(value)


func spoken() -> String:
	return "%s, %d %s, slider" % [title, value, unit]


# === PRIVATE METHODS ===
func _nudge(direction: int) -> void:
	set_value(value + direction * big_step)


func _on_slider(v: float) -> void:
	set_value(int(round(v)))
