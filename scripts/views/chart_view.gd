class_name ChartView
extends Control
## A line chart of a percentage (0 to 100) against generation. Each series has its own line style
## (solid or dashed), marker shape (circle or square) and a name in the legend, so two runs can be
## told apart without colour. Vertical ticks mark generations where the setting was changed.

# === PUBLIC VARIABLES ===
var chart_title: String = ""
var y_label: String = "%"
## Each series: {"name": String, "values": PackedFloat64Array (0..1), "color": Color,
## "dashed": bool, "square": bool, "marks": PackedInt32Array}
var series: Array[Dictionary] = []


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(180, 110)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.PANEL)
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.LINE, false, 1.0)
	var left: float = 40.0
	var top: float = 24.0
	var bottom: float = 34.0
	var plot: Rect2 = Rect2(left, top, size.x - left - 12.0, size.y - top - bottom)
	if plot.size.x < 40.0 or plot.size.y < 30.0:
		return
	Shapes.text(self, Vector2(6.0, 3.0), chart_title, 13)
	# Axes and grid.
	for i: int in range(5):
		var frac: float = float(i) / 4.0
		var y: float = plot.end.y - plot.size.y * frac
		draw_line(Vector2(plot.position.x, y), Vector2(plot.end.x, y), Color(UiTheme.LINE, 0.5), 1.0)
		Shapes.text_right(self, Vector2(plot.position.x - 4.0, y - 7.0), "%d%%" % int(frac * 100.0), 11, UiTheme.MUTED)
	draw_rect(plot, UiTheme.INK, false, 1.5)
	var last_gen: int = 10
	for s: Dictionary in series:
		var values: PackedFloat64Array = s["values"]
		last_gen = maxi(last_gen, values.size() - 1)
	# Round the axis up so it does not rescale on every step.
	var span: int = int(ceil(float(last_gen) / 10.0)) * 10
	var tick_every: int = maxi(1, span / 5)
	for g: int in range(0, span + 1, tick_every):
		var x: float = plot.position.x + plot.size.x * float(g) / float(span)
		draw_line(Vector2(x, plot.end.y), Vector2(x, plot.end.y + 4.0), UiTheme.INK, 1.0)
		Shapes.text_centered(self, Vector2(x, plot.end.y + 11.0), str(g), 11, UiTheme.MUTED)
	Shapes.text_centered(self, Vector2(plot.get_center().x, size.y - 9.0), "generation", 12, UiTheme.MUTED)
	var legend_x: float = plot.position.x + 6.0
	for s: Dictionary in series:
		_draw_series(s, plot, span)
		legend_x = _draw_legend(s, Vector2(legend_x, plot.position.y + 9.0))


# === PRIVATE METHODS ===
func _point(plot: Rect2, span: int, generation: int, value: float) -> Vector2:
	return Vector2(plot.position.x + plot.size.x * float(generation) / float(span),
		plot.end.y - plot.size.y * clampf(value, 0.0, 1.0))


func _draw_series(s: Dictionary, plot: Rect2, span: int) -> void:
	var values: PackedFloat64Array = s["values"]
	var col: Color = s["color"]
	var dashed: bool = bool(s.get("dashed", false))
	var n: int = values.size()
	if n == 0:
		return
	var marks: PackedInt32Array = s.get("marks", PackedInt32Array())
	for g: int in marks:
		var mx: float = _point(plot, span, g, 0.0).x
		Shapes.dashed_line(self, Vector2(mx, plot.position.y), Vector2(mx, plot.end.y), col, 1.0, 3.0, 3.0)
	for i: int in range(1, n):
		var a: Vector2 = _point(plot, span, i - 1, values[i - 1])
		var b: Vector2 = _point(plot, span, i, values[i])
		if dashed:
			Shapes.dashed_line(self, a, b, col, 2.5, 5.0, 4.0)
		else:
			draw_line(a, b, col, 2.5, true)
	# Markers: every point on a short run, thinned out on a long one.
	var every: int = maxi(1, int(ceil(float(n) / 24.0)))
	for i: int in range(0, n, every):
		_marker(_point(plot, span, i, values[i]), col, bool(s.get("square", false)))
	var last: Vector2 = _point(plot, span, n - 1, values[n - 1])
	_marker(last, col, bool(s.get("square", false)))
	var text: String = "%.1f%%" % (values[n - 1] * 100.0)
	var tx: float = clampf(last.x + 6.0, plot.position.x + 2.0, plot.end.x - Shapes.text_width(text, 12) - 2.0)
	var ty: float = clampf(last.y - 18.0, plot.position.y + 20.0, plot.end.y - 16.0)
	if bool(s.get("square", false)):
		ty = clampf(last.y + 5.0, plot.position.y + 20.0, plot.end.y - 16.0)
	Shapes.text(self, Vector2(tx, ty), text, 12, col)


func _marker(at: Vector2, col: Color, square: bool) -> void:
	if square:
		draw_rect(Rect2(at - Vector2(3.5, 3.5), Vector2(7, 7)), UiTheme.PANEL)
		draw_rect(Rect2(at - Vector2(3.5, 3.5), Vector2(7, 7)), col, false, 2.0)
	else:
		draw_circle(at, 3.5, col)


func _draw_legend(s: Dictionary, at: Vector2) -> float:
	var col: Color = s["color"]
	var a: Vector2 = at
	var b: Vector2 = at + Vector2(26.0, 0)
	if bool(s.get("dashed", false)):
		Shapes.dashed_line(self, a, b, col, 2.5, 5.0, 4.0)
	else:
		draw_line(a, b, col, 2.5, true)
	_marker((a + b) / 2.0, col, bool(s.get("square", false)))
	var legend_text: String = str(s.get("name", ""))
	var w: float = Shapes.text_width(legend_text, 12)
	draw_rect(Rect2(b.x + 3.0, at.y - 8.0, w + 4.0, 16.0), Color(1, 1, 1, 0.85))
	Shapes.text(self, Vector2(b.x + 5.0, at.y - 8.0), legend_text, 12)
	return b.x + w + 18.0
