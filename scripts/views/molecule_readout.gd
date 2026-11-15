class_name MoleculeReadout
extends Control
## Counts for one MoleculeModel as three labelled bars: lactose left, glucose made, galactose made.
## Glucose and galactose are counted separately, one of each per lactose split, so nothing looks
## as if it doubled. Each bar has its molecule's shape, its name and its number.

# === PUBLIC VARIABLES ===
var model: MoleculeModel = null
## One line of counts instead of three bars (used where height is short).
var compact: bool = false:
	set(value):
		compact = value
		custom_minimum_size = Vector2(160, 24 if compact else 62)
		queue_redraw()


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(160, 62)


func _draw() -> void:
	if model == null:
		return
	if compact:
		_draw_compact()
		return
	var row_h: float = size.y / 3.0
	var scale_max: float = float(maxi(model.lactose_start, 1))
	_row(0, row_h, MoleculeModel.Kind.LACTOSE, "Lactose left", model.lactose_remaining, scale_max,
		"%d of %d" % [model.lactose_remaining, model.lactose_start])
	_row(1, row_h, MoleculeModel.Kind.GLUCOSE, "Glucose made", model.glucose_formed, scale_max, str(model.glucose_formed))
	_row(2, row_h, MoleculeModel.Kind.GALACTOSE, "Galactose made", model.galactose_formed, scale_max, str(model.galactose_formed))


# === PRIVATE METHODS ===
func _draw_compact() -> void:
	var mid: float = size.y / 2.0
	var x: float = 14.0
	var parts: Array = [
		[MoleculeModel.Kind.LACTOSE, "lactose left %d of %d" % [model.lactose_remaining, model.lactose_start]],
		[MoleculeModel.Kind.GLUCOSE, "glucose %d" % model.glucose_formed],
		[MoleculeModel.Kind.GALACTOSE, "galactose %d" % model.galactose_formed],
	]
	var font_size: int = 13 if size.x >= 360.0 else 11
	for part: Array in parts:
		var kind: int = part[0]
		var text: String = part[1]
		if kind == MoleculeModel.Kind.LACTOSE:
			Shapes.lactose(self, Vector2(x, mid), 4.5)
		else:
			Shapes.sugar(self, kind, Vector2(x, mid), 6.0)
		Shapes.text(self, Vector2(x + 13.0, mid - float(font_size) * 0.68), text, font_size)
		x += 13.0 + Shapes.text_width(text, font_size) + 22.0


func _row(index: int, row_h: float, kind: int, caption: String, value: int, scale_max: float, number: String) -> void:
	var y: float = float(index) * row_h
	var mid: float = y + row_h / 2.0
	var r: float = minf(6.5, row_h * 0.32)
	var icon_x: float = 16.0
	if kind == MoleculeModel.Kind.LACTOSE:
		Shapes.lactose(self, Vector2(icon_x, mid), r * 0.72)
	else:
		Shapes.sugar(self, kind, Vector2(icon_x, mid), r)
	var font_size: int = 13
	Shapes.text(self, Vector2(34.0, mid - 9.0), caption, font_size)
	var bar_x: float = 150.0
	var number_w: float = 64.0
	var bar_w: float = maxf(size.x - bar_x - number_w, 10.0)
	var rect: Rect2 = Rect2(bar_x, mid - 6.0, bar_w, 12.0)
	draw_rect(rect, Color(1, 1, 1, 1))
	var fill_w: float = bar_w * clampf(float(value) / scale_max, 0.0, 1.0)
	var fill: Rect2 = Rect2(rect.position, Vector2(fill_w, rect.size.y))
	if kind == MoleculeModel.Kind.LACTOSE:
		draw_rect(fill, UiTheme.MUTED)
	elif kind == MoleculeModel.Kind.GLUCOSE:
		draw_rect(fill, UiTheme.GLUCOSE)
	else:
		draw_rect(fill, UiTheme.GALACTOSE)
		if fill_w > 2.0:
			Shapes.hatch(self, fill, UiTheme.GALACTOSE_EDGE, 6.0, 1.0)
	draw_rect(rect, UiTheme.INK, false, 1.0)
	Shapes.text(self, Vector2(bar_x + bar_w + 6.0, mid - 9.0), number, font_size)
