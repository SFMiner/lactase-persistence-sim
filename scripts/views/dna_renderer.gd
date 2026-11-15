class_name DnaRenderer
extends Control
## Draws chromosome 2 and a zoomed, unrolled stretch of its DNA with two marked parts:
##   regulatory DNA    = striped box (upstream, not protein-coding)
##   LCT coding region = solid box with an arrow tip (the instructions for the lactase protein)
## The two parts differ by pattern, shape and label, not only by colour. The coding box is drawn
## the same way for every person and every scenario: only the regulatory DNA can differ.
## Used by the DNA & Lactase view (with a variant and an expression level) and by the Evidence
## view (zoom steps, no variant marker, so nothing is given away).

# === PUBLIC VARIABLES ===
var app: AppState = null
## 0 = the two copies of chromosome 2; 1 or more = chromosome plus the zoomed DNA strip.
var zoom: int = 1
## -1 = show no variant; otherwise a RegulationModel.Variant.
var variant: int = -1
## -1 = show no expression arrow; otherwise 0..1 (drawn in Explain mode only).
var expression: float = -1.0
## -1 = neither part emphasised; otherwise an EvidenceData.Region.
var focus_region: int = -1


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(200, 84)


func _draw() -> void:
	var labels: bool = app == null or app.labels
	if zoom <= 0:
		_draw_pair(labels)
	else:
		_draw_strip(labels)


# === PUBLIC METHODS ===
## The first groups of the coding excerpt that fit in `width` pixels. Same text for everyone.
static func coding_text(width: float, font_size: int) -> String:
	var groups: PackedStringArray = EvidenceData.groups(RegulationModel.coding_sequence())
	var out: String = ""
	for i: int in range(groups.size()):
		var next: String = groups[i] if out == "" else out + "-" + groups[i]
		if Shapes.text_width(next + "...", font_size) > width:
			break
		out = next
	if out == "":
		return ""
	return out if out == RegulationModel.coding_sequence() else out + "..."


# === PRIVATE METHODS ===
func _chromosome(rect: Rect2, mark: bool) -> void:
	var split: float = rect.size.x * 0.38
	var short_arm: Rect2 = Rect2(rect.position, Vector2(split - 1.0, rect.size.y))
	var long_arm: Rect2 = Rect2(rect.position + Vector2(split + 1.0, 0), Vector2(rect.size.x - split - 1.0, rect.size.y))
	for arm: Rect2 in [short_arm, long_arm]:
		Shapes.filled(self, Shapes.rounded_rect(arm, rect.size.y / 2.0, 5), UiTheme.CHROMOSOME, UiTheme.INK, 1.5)
	var bands: Array[float] = [0.1, 0.2, 0.29, 0.5, 0.58, 0.74, 0.83, 0.91]
	for f: float in bands:
		draw_rect(Rect2(rect.position.x + rect.size.x * f, rect.position.y + 3.0, maxf(2.0, rect.size.x * 0.03), rect.size.y - 6.0), Color(UiTheme.MUTED, 0.75))
	if mark:
		var m: Rect2 = Rect2(rect.position.x + rect.size.x * 0.64, rect.position.y - 3.0, maxf(5.0, rect.size.x * 0.06), rect.size.y + 6.0)
		draw_rect(m, UiTheme.INK, false, 2.5)


func _draw_pair(labels: bool) -> void:
	var w: float = size.x
	var h: float = size.y
	var cw: float = minf(w * 0.8, 520.0)
	var ch: float = clampf(h * 0.16, 16.0, 30.0)
	var x: float = (w - cw) / 2.0
	var y1: float = h * 0.3 - ch / 2.0
	var y2: float = h * 0.62 - ch / 2.0
	_chromosome(Rect2(x, y1, cw, ch), true)
	_chromosome(Rect2(x, y2, cw, ch), true)
	if labels:
		Shapes.text(self, Vector2(x, y1 - 19.0), "chromosome 2, copy 1", 13)
		Shapes.text(self, Vector2(x, y2 - 19.0), "chromosome 2, copy 2", 13)
		var mark_x: float = x + cw * 0.67
		Shapes.text_centered(self, Vector2(clampf(mark_x, 110.0, w - 110.0), y2 + ch + 16.0), "boxed part: where the excerpts come from", 12, UiTheme.MUTED)
		Shapes.text_centered(self, Vector2(w / 2.0, h - 12.0), "Each person has two copies. Only short excerpts are shown.", 12, UiTheme.MUTED)


func _draw_strip(labels: bool) -> void:
	var w: float = size.x
	var h: float = size.y
	var mid: float = h * 0.46
	var cw: float = clampf(w * 0.14, 46.0, 110.0)
	var crect: Rect2 = Rect2(6.0, mid - 9.0, cw, 18.0)
	_chromosome(crect, true)
	if labels:
		Shapes.text(self, Vector2(6.0, mid + 14.0), "chromosome 2", 11, UiTheme.MUTED)
	var x0: float = crect.end.x + 26.0
	var x1: float = w - 6.0
	var length: float = x1 - x0
	if length < 60.0:
		return
	var box_h: float = clampf(h * 0.3, 22.0, 30.0)
	# Zoom lines from the boxed part of the chromosome to the strip.
	var mark_x: float = crect.position.x + cw * 0.67
	Shapes.dashed_line(self, Vector2(mark_x, mid - 12.0), Vector2(x0, mid - box_h / 2.0), UiTheme.MUTED, 1.0, 4.0, 3.0)
	Shapes.dashed_line(self, Vector2(mark_x, mid + 12.0), Vector2(x0, mid + box_h / 2.0), UiTheme.MUTED, 1.0, 4.0, 3.0)
	# The unrolled double strand: two rails with rungs.
	var rails: PackedVector2Array = PackedVector2Array([Vector2(x0, mid - 5.0), Vector2(x1, mid - 5.0), Vector2(x0, mid + 5.0), Vector2(x1, mid + 5.0)])
	var rx: float = x0 + 4.0
	while rx < x1:
		rails.append(Vector2(rx, mid - 5.0))
		rails.append(Vector2(rx, mid + 5.0))
		rx += 7.0
	draw_multiline(rails, UiTheme.MUTED, 1.5)
	var reg: Rect2 = Rect2(x0 + length * 0.05, mid - box_h / 2.0, length * 0.3, box_h)
	var cod: Rect2 = Rect2(x0 + length * 0.5, mid - box_h / 2.0, length * 0.47, box_h)
	# A break mark: the two parts are not next to each other on the real chromosome.
	var bx: float = x0 + length * 0.425
	draw_rect(Rect2(bx - 6.0, mid - 9.0, 12.0, 18.0), UiTheme.PANEL)
	draw_line(Vector2(bx - 5.0, mid + 8.0), Vector2(bx - 1.0, mid - 8.0), UiTheme.INK, 1.5, true)
	draw_line(Vector2(bx + 1.0, mid + 8.0), Vector2(bx + 5.0, mid - 8.0), UiTheme.INK, 1.5, true)
	var reg_dim: float = 0.4 if focus_region == EvidenceData.Region.CODING else 1.0
	var cod_dim: float = 0.4 if focus_region == EvidenceData.Region.UPSTREAM else 1.0
	# Regulatory DNA: striped.
	draw_rect(reg, Color(UiTheme.REGULATORY, reg_dim))
	Shapes.hatch(self, reg, Color(UiTheme.INK, 0.55 * reg_dim), 7.0, 1.2)
	draw_rect(reg, Color(UiTheme.INK, reg_dim), false, 4.0 if focus_region == EvidenceData.Region.UPSTREAM else 2.0)
	# LCT coding region: solid, with an arrow tip showing the reading direction.
	var tip: float = minf(12.0, cod.size.x * 0.2)
	var cod_pts: PackedVector2Array = PackedVector2Array([
		cod.position, Vector2(cod.end.x - tip, cod.position.y), Vector2(cod.end.x, mid),
		Vector2(cod.end.x - tip, cod.end.y), Vector2(cod.position.x, cod.end.y),
	])
	Shapes.filled(self, cod_pts, Color(UiTheme.CODING, cod_dim), Color(UiTheme.INK, cod_dim), 4.0 if focus_region == EvidenceData.Region.CODING else 2.0)
	if variant == RegulationModel.Variant.PERSISTENT:
		# The inherited difference: a diamond on the regulatory DNA (a shape, not just a colour).
		var d: Vector2 = Vector2(reg.position.x + reg.size.x * 0.5, reg.position.y - 7.0)
		Shapes.filled(self, PackedVector2Array([d + Vector2(0, -6), d + Vector2(6, 0), d + Vector2(0, 6), d + Vector2(-6, 0)]), UiTheme.PANEL, UiTheme.INK, 2.0)
	if labels:
		var fs: int = 11
		Shapes.text_centered(self, Vector2(reg.get_center().x, reg.end.y + 9.0), "regulatory DNA", fs)
		Shapes.text_centered(self, Vector2(cod.get_center().x, cod.end.y + 9.0), "LCT coding region", fs)
		var coding: String = coding_text(cod.size.x - tip - 8.0, fs)
		if coding != "":
			Shapes.text_centered(self, Vector2(cod.position.x + (cod.size.x - tip) / 2.0, mid), coding, fs)
		if variant >= 0:
			var group: String = EvidenceData.groups(RegulationModel.regulatory_sequence(variant))[3]
			Shapes.tag(self, reg.get_center(), "..." + group + "...", fs)
	var explain: bool = app != null and app.explain
	if explain and expression >= 0.0:
		_draw_control_arrow(reg, cod, labels)


func _draw_control_arrow(reg: Rect2, cod: Rect2, labels: bool) -> void:
	var a: Vector2 = Vector2(reg.end.x - 6.0, reg.position.y - 2.0)
	var b: Vector2 = Vector2(cod.position.x + 10.0, cod.position.y - 2.0)
	var top: float = maxf(reg.position.y - 16.0, 9.0)
	var pts: PackedVector2Array = PackedVector2Array([a, Vector2(a.x + 8.0, top), Vector2(b.x - 8.0, top)])
	var width: float = 1.5 + 4.0 * clampf(expression, 0.0, 1.0)
	var word: String = RegulationModel.expression_word(expression)
	if expression <= 0.0:
		Shapes.dashed_line(self, a, Vector2(a.x + 8.0, top), UiTheme.INK, 1.5, 4.0, 3.0)
		Shapes.dashed_line(self, Vector2(a.x + 8.0, top), Vector2(b.x - 8.0, top), UiTheme.INK, 1.5, 4.0, 3.0)
	else:
		draw_polyline(pts, UiTheme.INK, width, true)
	Shapes.arrow(self, Vector2(b.x - 8.0, top), b, UiTheme.INK, maxf(width, 1.5), 8.0)
	if labels:
		var note: String = "sets how much the cell uses LCT: " + word
		var cx: float = clampf((a.x + b.x) / 2.0, Shapes.text_width(note, 11) / 2.0 + 4.0, size.x - Shapes.text_width(note, 11) / 2.0 - 4.0)
		Shapes.tag(self, Vector2(cx, top - 1.0), note, 11)
