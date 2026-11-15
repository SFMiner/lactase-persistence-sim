class_name CellRenderer
extends Control
## Draws one cell with an "LCT use" gauge and the lactase it makes.
## The gauge has ten boxes plus a word (off / low / medium / high), so the level never depends on
## colour. While a run is playing (and motion is not reduced) small lactase shapes move from the
## nucleus to the brush border: that movement stands for "the cell is making lactase", and its
## amount follows the gauge. It is a picture of production, not a model of transcription.

# === PUBLIC VARIABLES ===
var app: AppState = null
var cell_type: int = RegulationModel.CellType.INTESTINE
var expression: float = 1.0
var enzyme_count: int = 20
var stage_name: String = "Infant"
## Seconds of animation time; the view advances it only while running.
var anim_time: float = 0.0
var animating: bool = false


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(200, 92)


func _draw() -> void:
	var labels: bool = app == null or app.labels
	var h: float = size.y
	var cell_w: float = clampf(size.x * 0.3, 90.0, 170.0)
	var cell: Rect2 = Rect2(8.0, 12.0, cell_w, h - 30.0)
	if cell_type == RegulationModel.CellType.MUSCLE:
		_draw_muscle(cell)
	else:
		_draw_intestine(cell)
	if labels:
		var names: Array[String] = ["small-intestine cell", "muscle cell"]
		Shapes.text(self, Vector2(8.0, h - 16.0), "%s (%s)" % [names[cell_type], stage_name.to_lower()], 11, UiTheme.MUTED)
	_draw_gauge(Vector2(cell.end.x + 14.0, 6.0), size.x - cell.end.x - 20.0, labels)


# === PRIVATE METHODS ===
func _draw_intestine(cell: Rect2) -> void:
	Shapes.filled(self, Shapes.rounded_rect(cell, 8.0, 4), UiTheme.CELL, UiTheme.CELL_EDGE, 2.0)
	# Brush border on the top edge (the side that faces the inside of the intestine).
	var comb: PackedVector2Array = PackedVector2Array()
	var x: float = cell.position.x + 6.0
	while x < cell.end.x - 5.0:
		comb.append(Vector2(x, cell.position.y))
		comb.append(Vector2(x, cell.position.y - 6.0))
		x += 4.0
	draw_multiline(comb, UiTheme.CELL_EDGE, 1.5)
	var nucleus: Vector2 = Vector2(cell.position.x + cell.size.x * 0.5, cell.position.y + cell.size.y * 0.66)
	var nr: float = minf(cell.size.y * 0.24, 16.0)
	draw_circle(nucleus, nr, UiTheme.NUCLEUS)
	draw_arc(nucleus, nr, 0.0, TAU, 24, UiTheme.CELL_EDGE, 1.5, true)
	draw_polyline(PackedVector2Array([nucleus + Vector2(-nr * 0.55, 0), nucleus + Vector2(-nr * 0.2, -nr * 0.35), nucleus + Vector2(nr * 0.15, nr * 0.3), nucleus + Vector2(nr * 0.55, -nr * 0.1)]), UiTheme.INK, 1.5, true)
	var reduced: bool = app != null and app.reduced_motion()
	if animating and not reduced and expression > 0.0:
		# More expression = more lactase on its way to the brush border.
		var movers: int = int(ceil(expression * 4.0))
		for k: int in range(movers):
			var t: float = fposmod(anim_time * 0.45 + float(k) / float(movers), 1.0)
			var from: Vector2 = nucleus + Vector2((float(k) - float(movers - 1) / 2.0) * 12.0, -nr)
			var to: Vector2 = Vector2(from.x, cell.position.y + 9.0)
			Shapes.lactase(self, from.lerp(to, t), 15.0)


func _draw_muscle(cell: Rect2) -> void:
	var c: Vector2 = cell.get_center()
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(24):
		var a: float = TAU * float(i) / 24.0
		pts.append(c + Vector2(cos(a) * cell.size.x * 0.5, sin(a) * cell.size.y * 0.3))
	Shapes.filled(self, pts, UiTheme.MUSCLE, UiTheme.CELL_EDGE, 2.0)
	for i: int in range(5):
		var x: float = c.x + (float(i) - 2.0) * cell.size.x * 0.13
		var half: float = cell.size.y * 0.3 * sqrt(maxf(0.0, 1.0 - pow((x - c.x) / (cell.size.x * 0.5), 2.0))) - 3.0
		draw_line(Vector2(x, c.y - half), Vector2(x, c.y + half), UiTheme.CELL_EDGE, 1.5)
	draw_circle(c + Vector2(cell.size.x * 0.2, 0), 5.0, UiTheme.NUCLEUS)


func _draw_gauge(at: Vector2, width: float, labels: bool) -> void:
	if width < 80.0:
		return
	var word: String = RegulationModel.expression_word(expression)
	Shapes.text(self, at, "LCT use in this cell: " + word, 13)
	var boxes: int = 10
	var filled_boxes: int = int(round(clampf(expression, 0.0, 1.0) * float(boxes)))
	var bw: float = minf(18.0, (width - 4.0) / float(boxes) - 3.0)
	var y: float = at.y + 20.0
	for i: int in range(boxes):
		var r: Rect2 = Rect2(at.x + float(i) * (bw + 3.0), y, bw, 12.0)
		if i < filled_boxes:
			draw_rect(r, UiTheme.ACCENT)
		draw_rect(r, UiTheme.INK, false, 1.5)
	var row_y: float = y + 20.0
	if labels:
		Shapes.text(self, Vector2(at.x, row_y), "Lactase made: %d" % enzyme_count, 12)
		row_y += 17.0
	var icon_w: float = clampf((width - 4.0) / 10.0 - 2.0, 10.0, 20.0)
	var room: float = size.y - row_y
	var rows: int = 2 if enzyme_count > 10 else 1
	if room < float(rows) * icon_w * 0.7:
		return
	for i: int in range(enzyme_count):
		var col: int = i % 10
		var row: int = i / 10
		Shapes.lactase(self, Vector2(at.x + icon_w / 2.0 + float(col) * (icon_w + 2.0), row_y + icon_w * 0.35 + float(row) * (icon_w * 0.72)), icon_w)
