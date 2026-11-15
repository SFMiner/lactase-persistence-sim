class_name SimButton
extends Button
## A button that draws its own icon, mark and caption, so icons need no image files and a chosen
## option is shown by a drawn mark as well as by colour. The built-in `text` stays empty; read
## `caption` instead. Every SimButton keeps a minimum size of one touch target (UiKit.target_px).

# === CONSTANTS ===
enum Mark { NONE, RADIO, CHECK }
const ICON_SIZE: float = 20.0
const GAP: float = 5.0
const PAD: float = 8.0

# === PUBLIC VARIABLES ===
var caption: String = "":
	set(value):
		caption = value
		refresh_min()
var icon_id: String = "":
	set(value):
		icon_id = value
		refresh_min()
## Icon only (the caption is still used for announcements).
var compact: bool = false:
	set(value):
		compact = value
		refresh_min()
var mark: int = Mark.NONE:
	set(value):
		mark = value
		refresh_min()
## Extra minimum width, for buttons whose caption changes (keeps the row from jumping).
var min_width: float = 0.0:
	set(value):
		min_width = value
		refresh_min()


# === LIFECYCLE METHODS ===
func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	add_to_group("sim_target")


func _ready() -> void:
	refresh_min()
	toggled.connect(func(_on: bool) -> void: queue_redraw())


func _notification(what: int) -> void:
	if what == NOTIFICATION_THEME_CHANGED:
		refresh_min()


func _draw() -> void:
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var col: Color = _ink()
	var show_text: bool = not (compact and icon_id != "")
	var content_w: float = _content_width(font, font_size, show_text)
	var x: float = (size.x - content_w) / 2.0
	var mid: float = size.y / 2.0
	if mark != Mark.NONE:
		_draw_mark(Vector2(x + ICON_SIZE / 2.0, mid), col)
		x += ICON_SIZE + GAP
	if icon_id != "":
		Shapes.icon(self, icon_id, Rect2(x, mid - ICON_SIZE / 2.0, ICON_SIZE, ICON_SIZE), col)
		x += ICON_SIZE + (GAP if show_text else 0.0)
	if show_text and caption != "":
		var ascent: float = font.get_ascent(font_size)
		var descent: float = font.get_descent(font_size)
		draw_string(font, Vector2(x, mid + (ascent - descent) / 2.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, col)


# === PUBLIC METHODS ===
## Recomputes the minimum size from the caption, icon and current touch-target size.
func refresh_min() -> void:
	var font: Font = get_theme_font("font")
	var font_size: int = get_theme_font_size("font_size")
	var show_text: bool = not (compact and icon_id != "")
	var w: float = _content_width(font, font_size, show_text) + PAD * 2.0
	custom_minimum_size = Vector2(maxf(maxf(w, min_width), UiKit.target_px), UiKit.target_px)
	queue_redraw()


## What a screen reader should hear for this button.
func spoken() -> String:
	var out: String = caption
	if mark == Mark.RADIO:
		out += ", selected" if button_pressed else ", not selected"
	elif mark == Mark.CHECK or toggle_mode:
		out += ", on" if button_pressed else ", off"
	if disabled:
		out += ", unavailable"
	return out


# === PRIVATE METHODS ===
func _content_width(font: Font, font_size: int, show_text: bool) -> float:
	var w: float = 0.0
	if mark != Mark.NONE:
		w += ICON_SIZE + GAP
	if icon_id != "":
		w += ICON_SIZE + (GAP if show_text else 0.0)
	if show_text and caption != "":
		w += font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
	return w


func _ink() -> Color:
	if disabled:
		return UiTheme.DISABLED_INK
	if button_pressed or (is_pressed() and not toggle_mode):
		return Color.WHITE
	return UiTheme.INK


func _draw_mark(center: Vector2, col: Color) -> void:
	if mark == Mark.RADIO:
		draw_arc(center, 8.0, 0.0, TAU, 28, col, 2.0, true)
		if button_pressed:
			draw_circle(center, 4.5, col)
	elif mark == Mark.CHECK:
		draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), col, false, 2.0)
		if button_pressed:
			draw_polyline(PackedVector2Array([center + Vector2(-5, 0), center + Vector2(-1.5, 4.5), center + Vector2(5.5, -5)]), col, 3.0, true)
