class_name UiTheme
extends RefCounted
## Colours and the code-built theme. Light background with dark ink text (well above 4.5:1),
## buttons with a dark border, and a thick focus outline on every focusable control.
## Every drawn shape also has a dark outline, so nothing depends on fill colour alone.

# === CONSTANTS ===
const BG: Color = Color(0.953, 0.937, 0.902, 1)
const PANEL: Color = Color(1, 1, 1, 1)
const INK: Color = Color(0.094, 0.129, 0.184, 1)
const MUTED: Color = Color(0.29, 0.333, 0.408, 1)
const LINE: Color = Color(0.55, 0.58, 0.63, 1)
const ACCENT: Color = Color(0.043, 0.365, 0.388, 1)
const ACCENT_SOFT: Color = Color(0.86, 0.94, 0.93, 1)
const FOCUS: Color = Color(0.76, 0.094, 0.357, 1)
const DISABLED_BG: Color = Color(0.914, 0.902, 0.875, 1)
const DISABLED_INK: Color = Color(0.373, 0.4, 0.447, 1)
const GOOD: Color = Color(0.06, 0.42, 0.2, 1)
const BAD: Color = Color(0.66, 0.11, 0.11, 1)

# Molecules and body.
const GLUCOSE: Color = Color(0.95, 0.663, 0.231, 1)
const GLUCOSE_EDGE: Color = Color(0.42, 0.24, 0.0, 1)
const GALACTOSE: Color = Color(0.56, 0.5, 0.92, 1)
const GALACTOSE_EDGE: Color = Color(0.16, 0.12, 0.47, 1)
const LACTASE: Color = Color(0.3, 0.72, 0.6, 1)
const LACTASE_EDGE: Color = Color(0.04, 0.27, 0.22, 1)
const SUPPLEMENT: Color = Color(0.68, 0.85, 0.97, 1)
const SUPPLEMENT_EDGE: Color = Color(0.09, 0.28, 0.46, 1)
const WATER: Color = Color(0.25, 0.55, 0.9, 1)
const LUMEN: Color = Color(1.0, 0.973, 0.906, 1)
const CELL: Color = Color(0.97, 0.80, 0.77, 1)
const CELL_EDGE: Color = Color(0.55, 0.25, 0.23, 1)
const NUCLEUS: Color = Color(0.76, 0.5, 0.58, 1)
const MUSCLE: Color = Color(0.9, 0.6, 0.55, 1)

# DNA.
const CODING: Color = Color(0.36, 0.62, 0.86, 1)
const REGULATORY: Color = Color(0.97, 0.85, 0.4, 1)
const CHROMOSOME: Color = Color(0.8, 0.82, 0.88, 1)

# Chart series.
const SERIES_A: Color = Color(0.043, 0.365, 0.388, 1)
const SERIES_B: Color = Color(0.62, 0.2, 0.05, 1)

const FONT_SIZE: int = 16
const SMALL_FONT: int = 13
const TITLE_FONT: int = 20


# === PUBLIC METHODS ===
static func build() -> Theme:
	var t: Theme = Theme.new()
	t.default_font_size = FONT_SIZE
	t.set_stylebox("normal", "Button", _box(PANEL, INK, 2))
	t.set_stylebox("hover", "Button", _box(ACCENT_SOFT, INK, 2))
	t.set_stylebox("pressed", "Button", _box(ACCENT, INK, 2))
	t.set_stylebox("hover_pressed", "Button", _box(ACCENT, INK, 2))
	t.set_stylebox("disabled", "Button", _box(DISABLED_BG, LINE, 2))
	var focus: StyleBoxFlat = _box(Color(0, 0, 0, 0), FOCUS, 4)
	focus.draw_center = false
	focus.set_expand_margin_all(3.0)
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_hover_pressed_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", INK)
	t.set_color("font_disabled_color", "Button", DISABLED_INK)
	t.set_color("font_color", "Label", INK)
	var panel: StyleBoxFlat = _box(PANEL, LINE, 1)
	panel.set_content_margin_all(8.0)
	t.set_stylebox("panel", "PanelContainer", panel)
	# Sliders: a visible track, a filled part, and a dark round grabber.
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color(0.82, 0.84, 0.87, 1)
	track.border_color = INK
	track.set_border_width_all(1)
	track.set_corner_radius_all(5)
	track.content_margin_top = 5.0
	track.content_margin_bottom = 5.0
	t.set_stylebox("slider", "HSlider", track)
	var filled: StyleBoxFlat = StyleBoxFlat.new()
	filled.bg_color = ACCENT
	filled.set_corner_radius_all(5)
	t.set_stylebox("grabber_area", "HSlider", filled)
	t.set_stylebox("grabber_area_highlight", "HSlider", filled)
	var knob: ImageTexture = _disc(26, INK, Color.WHITE)
	t.set_icon("grabber", "HSlider", knob)
	t.set_icon("grabber_highlight", "HSlider", knob)
	t.set_icon("grabber_disabled", "HSlider", _disc(26, LINE, DISABLED_BG))
	return t


## A panel style for the stage areas (white card with a thin edge).
static func card(bg: Color = PANEL) -> StyleBoxFlat:
	var sb: StyleBoxFlat = _box(bg, LINE, 1)
	sb.set_content_margin_all(6.0)
	return sb


# === PRIVATE METHODS ===
static func _box(bg: Color, edge: Color, border: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0
	return sb


## A filled circle with a ring, drawn pixel by pixel (no deprecated Image calls).
static func _disc(size: int, fill: Color, ring: Color) -> ImageTexture:
	var img: Image = Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var c: float = float(size - 1) / 2.0
	var r: float = float(size) / 2.0 - 1.0
	for y: int in range(size):
		for x: int in range(size):
			var d: float = Vector2(float(x) - c, float(y) - c).length()
			var col: Color = Color(0, 0, 0, 0)
			if d <= r - 3.0:
				col = fill
			elif d <= r:
				col = ring
				col.a = clampf(r - d + 0.5, 0.0, 1.0) if d > r - 1.0 else 1.0
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
