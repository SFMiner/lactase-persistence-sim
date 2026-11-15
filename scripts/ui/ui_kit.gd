class_name UiKit
extends RefCounted
## Small factory helpers shared by every view, plus the current touch-target size.

# === PUBLIC VARIABLES ===
## Minimum button size in layout pixels, set by ResponsiveLayout so a target is never smaller
## than 44 CSS pixels after scaling.
static var target_px: float = 44.0


# === PUBLIC METHODS ===
static func button(caption: String, icon_id: String = "", on_press: Callable = Callable()) -> SimButton:
	var b: SimButton = SimButton.new()
	b.caption = caption
	b.icon_id = icon_id
	if on_press.is_valid():
		b.pressed.connect(on_press)
	return b


## A button that stays down while on, with a drawn check box.
static func toggle(caption: String, on: bool, on_toggle: Callable = Callable()) -> SimButton:
	var b: SimButton = SimButton.new()
	b.caption = caption
	b.toggle_mode = true
	b.mark = SimButton.Mark.CHECK
	b.button_pressed = on
	if on_toggle.is_valid():
		b.toggled.connect(on_toggle)
	return b


static func label(text: String, font_size: int = UiTheme.FONT_SIZE, color: Color = UiTheme.INK, wrap: bool = true) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func vbox(separation: int = 6) -> VBoxContainer:
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 6) -> HBoxContainer:
	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func flow(separation: int = 6) -> HFlowContainer:
	var f: HFlowContainer = HFlowContainer.new()
	f.add_theme_constant_override("h_separation", separation)
	f.add_theme_constant_override("v_separation", separation)
	return f


static func spacer(width: float = 0.0, expand: bool = false) -> Control:
	var c: Control = Control.new()
	c.custom_minimum_size = Vector2(width, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func card(bg: Color = UiTheme.PANEL) -> PanelContainer:
	var p: PanelContainer = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.card(bg))
	return p


static func fill(c: Control, h_ratio: float = 1.0, v_ratio: float = 1.0) -> Control:
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_stretch_ratio = h_ratio if h_ratio != 1.0 else v_ratio
	return c
