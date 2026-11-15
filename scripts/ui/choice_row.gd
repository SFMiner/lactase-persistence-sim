class_name ChoiceRow
extends VBoxContainer
## A titled set of options where exactly one is chosen. Each option is a button with a drawn
## radio mark, so the choice is shown by shape as well as colour and every option is a Tab stop.

# === SIGNALS ===
signal chosen(index: int)

# === PUBLIC VARIABLES ===
var selected: int = 0
var title_label: Label = null
var buttons: Array[SimButton] = []


# === PUBLIC METHODS ===
static func create(title: String, options: Array[String], start: int = 0, inline: bool = false) -> ChoiceRow:
	var row: ChoiceRow = ChoiceRow.new()
	row.add_theme_constant_override("separation", 3)
	row.title_label = UiKit.label(title, UiTheme.SMALL_FONT, UiTheme.MUTED)
	row.add_child(row.title_label)
	# `inline` keeps the options on one line (for use inside a flowing toolbar).
	var holder: Container = UiKit.hbox(4) if inline else UiKit.flow(4)
	row.add_child(holder)
	for i: int in range(options.size()):
		var b: SimButton = SimButton.new()
		b.caption = options[i]
		b.mark = SimButton.Mark.RADIO
		b.toggle_mode = true
		b.pressed.connect(row._on_pressed.bind(i))
		holder.add_child(b)
		row.buttons.append(b)
	row.select(start, false)
	return row


## Chooses an option. With `notify` it also emits `chosen`.
func select(index: int, notify: bool = true) -> void:
	selected = clampi(index, 0, buttons.size() - 1)
	for i: int in range(buttons.size()):
		buttons[i].set_pressed_no_signal(i == selected)
		buttons[i].queue_redraw()
	if notify:
		chosen.emit(selected)


func set_disabled(off: bool) -> void:
	for b: SimButton in buttons:
		b.disabled = off
		b.queue_redraw()


# === PRIVATE METHODS ===
func _on_pressed(index: int) -> void:
	select(index, true)
