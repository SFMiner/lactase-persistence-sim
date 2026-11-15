class_name OverlayPanel
extends Control
## A modal card (Help, Settings) over a dimmed screen. While it is open, Tab stays inside it and
## Escape closes it; main.gd asks for both through KeyboardNavigation.

# === SIGNALS ===
signal closed

# === PUBLIC VARIABLES ===
var panel: PanelContainer = null
var content: VBoxContainer = null
var close_button: SimButton = null
var title_label: Label = null


# === PUBLIC METHODS ===
static func create(title: String) -> OverlayPanel:
	var o: OverlayPanel = OverlayPanel.new()
	o.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	o.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.05, 0.08, 0.12, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	o.add_child(dim)
	o.panel = PanelContainer.new()
	var sb: StyleBoxFlat = UiTheme.card()
	sb.border_color = UiTheme.INK
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12.0)
	o.panel.add_theme_stylebox_override("panel", sb)
	o.add_child(o.panel)
	var column: VBoxContainer = UiKit.vbox(8)
	o.panel.add_child(column)
	var head: HBoxContainer = UiKit.hbox(8)
	column.add_child(head)
	o.title_label = UiKit.label(title, UiTheme.TITLE_FONT)
	head.add_child(o.title_label)
	o.close_button = UiKit.button("Close", "close", o.close)
	head.add_child(o.close_button)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	o.content = UiKit.vbox(8)
	o.content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(o.content)
	return o


## Sizes the card for the current layout size and centres it.
func fit(view_size: Vector2) -> void:
	var w: float = minf(620.0, view_size.x - 16.0)
	var h: float = minf(440.0, view_size.y - 16.0)
	panel.position = ((view_size - Vector2(w, h)) / 2.0).floor()
	panel.size = Vector2(w, h)


func close() -> void:
	closed.emit()
	queue_free()
