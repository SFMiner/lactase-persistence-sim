class_name ResponsiveLayout
extends Node
## Keeps text readable in any frame. The project stretches with aspect `expand`; this node sets
## the stretch base size on every resize so that one layout pixel is never smaller than about
## 0.85 CSS pixels, then tells the screen how much room it has. Small frames get less play area,
## not smaller text. The Text size setting multiplies the same scale, so "Large" behaves like a
## browser zoom that the canvas would otherwise ignore.

# === SIGNALS ===
## Emitted after every change with the new layout size (in layout pixels).
signal layout_changed(view_size: Vector2)

# === CONSTANTS ===
const BASE: Vector2 = Vector2(1180.0, 500.0)
## Smallest allowed size of a layout pixel, in CSS pixels.
const MIN_CSS_SCALE: float = 0.85
const MAX_CSS_SCALE: float = 2.5
## Below this layout width the views show one panel at a time (Model / Controls tabs).
const NARROW_WIDTH: float = 820.0
## The site's full-screen button covers this much of the top-right corner (CSS pixels).
const RESERVED_CSS: Vector2 = Vector2(200.0, 64.0)
const TARGET_CSS: float = 44.0

# === PUBLIC VARIABLES ===
var text_scale: float = 1.0
## Device pixel ratio override for tests (0 = ask the display server).
var dpr_override: float = 0.0
## CSS pixels per layout pixel after the last apply().
var css_per_px: float = 1.0
var view_size: Vector2 = BASE


# === LIFECYCLE METHODS ===
func _ready() -> void:
	get_tree().root.size_changed.connect(apply)
	apply()


# === PUBLIC METHODS ===
## CSS pixels per layout pixel for a window of this size (in device pixels).
static func css_scale(window_px: Vector2, dpr: float, text_mult: float) -> float:
	var css: Vector2 = window_px / maxf(dpr, 0.1)
	var fit: float = minf(css.x / BASE.x, css.y / BASE.y)
	return clampf(fit, MIN_CSS_SCALE, MAX_CSS_SCALE) * text_mult


func device_pixel_ratio() -> float:
	if dpr_override > 0.0:
		return dpr_override
	return maxf(DisplayServer.screen_get_scale(), 0.1)


func set_text_scale(mult: float) -> void:
	text_scale = mult
	apply()


func is_narrow() -> bool:
	return view_size.x < NARROW_WIDTH


## Size of the corner to keep clear, in layout pixels.
func reserved_corner() -> Vector2:
	return RESERVED_CSS / css_per_px


func apply() -> void:
	var win: Window = get_tree().root
	var window_px: Vector2 = Vector2(win.size)
	if window_px.x < 1.0 or window_px.y < 1.0:
		return
	var dpr: float = device_pixel_ratio()
	css_per_px = css_scale(window_px, dpr, text_scale)
	var device_per_px: float = css_per_px * dpr
	var base: Vector2i = Vector2i((window_px / device_per_px).floor())
	base.x = maxi(base.x, 200)
	base.y = maxi(base.y, 120)
	if win.content_scale_size != base:
		win.content_scale_size = base
	view_size = Vector2(base)
	# A touch target stays at least 44 CSS pixels even when a layout pixel is smaller than one.
	var target: float = ceilf(TARGET_CSS / minf(css_per_px, 1.0))
	if not is_equal_approx(target, UiKit.target_px):
		UiKit.target_px = target
		get_tree().call_group("sim_target", "refresh_min")
	layout_changed.emit(view_size)
