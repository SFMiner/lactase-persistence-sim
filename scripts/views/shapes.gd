class_name Shapes
extends RefCounted
## Every picture in the simulator is drawn here from simple shapes, so there are no image files to
## load and each drawing can later be swapped for final art in one place (see ASSET_REQUIREMENTS.md).
## The same molecule always has the same shape in every view:
##   glucose   = hexagon with a centre dot       galactose = pentagon with a centre bar
##   lactose   = one of each, joined by a bond   lactase   = large body with a pocket on top
## These are symbols, not real molecular structures.

# === CONSTANTS ===
const SKIN: Array[Color] = [
	Color(0.99, 0.87, 0.77, 1), Color(0.95, 0.78, 0.63, 1), Color(0.85, 0.65, 0.47, 1),
	Color(0.72, 0.52, 0.36, 1), Color(0.55, 0.38, 0.26, 1), Color(0.38, 0.26, 0.19, 1),
]
const HAIR: Array[Color] = [
	Color(0.12, 0.1, 0.1, 1), Color(0.3, 0.2, 0.12, 1), Color(0.55, 0.38, 0.2, 1),
	Color(0.75, 0.62, 0.35, 1), Color(0.45, 0.45, 0.48, 1),
]
const SHIRT: Array[Color] = [
	Color(0.75, 0.82, 0.9, 1), Color(0.85, 0.8, 0.9, 1), Color(0.8, 0.9, 0.82, 1),
	Color(0.93, 0.87, 0.75, 1), Color(0.88, 0.88, 0.88, 1),
]


# === TEXT ===
static func font() -> Font:
	return ThemeDB.fallback_font


## Draws text with its top-left corner at `pos`.
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int = 13, col: Color = UiTheme.INK) -> void:
	var f: Font = font()
	ci.draw_string(f, pos + Vector2(0, f.get_ascent(size)), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)


## Draws text centred on `center`.
static func text_centered(ci: CanvasItem, center: Vector2, s: String, size: int = 13, col: Color = UiTheme.INK) -> void:
	var f: Font = font()
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var y: float = center.y + (f.get_ascent(size) - f.get_descent(size)) / 2.0
	ci.draw_string(f, Vector2(center.x - w / 2.0, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)


## Draws text whose right edge is at `pos.x`.
static func text_right(ci: CanvasItem, pos: Vector2, s: String, size: int = 13, col: Color = UiTheme.INK) -> void:
	var f: Font = font()
	var w: float = f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	ci.draw_string(f, Vector2(pos.x - w, pos.y + f.get_ascent(size)), s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, col)


static func text_width(s: String, size: int = 13) -> float:
	return font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x


## Text on a small white plate, so a label stays readable over any drawing.
static func tag(ci: CanvasItem, center: Vector2, s: String, size: int = 12, col: Color = UiTheme.INK) -> void:
	var w: float = text_width(s, size) + 8.0
	var h: float = float(size) + 6.0
	var r: Rect2 = Rect2(center - Vector2(w, h) / 2.0, Vector2(w, h))
	ci.draw_rect(r, Color(1, 1, 1, 0.92), true)
	ci.draw_rect(r, UiTheme.LINE, false, 1.0)
	text_centered(ci, center, s, size, col)


## Like tag(), but with its left edge at `pos.x`.
static func tag_left(ci: CanvasItem, pos: Vector2, s: String, size: int = 12, col: Color = UiTheme.INK) -> void:
	tag(ci, pos + Vector2((text_width(s, size) + 8.0) / 2.0, 0.0), s, size, col)


# === BASIC SHAPES ===
static func ngon(center: Vector2, r: float, sides: int, rotation: float = 0.0) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(sides):
		pts.append(center + Vector2.from_angle(rotation + TAU * float(i) / float(sides)) * r)
	return pts


static func outline(ci: CanvasItem, pts: PackedVector2Array, col: Color, width: float = 1.5) -> void:
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	ci.draw_polyline(closed, col, width, true)


static func filled(ci: CanvasItem, pts: PackedVector2Array, fill: Color, edge: Color, width: float = 1.5) -> void:
	ci.draw_colored_polygon(pts, fill)
	outline(ci, pts, edge, width)


static func rounded_rect(rect: Rect2, radius: float, steps: int = 5) -> PackedVector2Array:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) / 2.0)
	var pts: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [
		rect.position + Vector2(rect.size.x - r, r), rect.position + Vector2(rect.size.x - r, rect.size.y - r),
		rect.position + Vector2(r, rect.size.y - r), rect.position + Vector2(r, r),
	]
	for c: int in range(4):
		var start: float = -PI / 2.0 + float(c) * PI / 2.0
		for i: int in range(steps + 1):
			pts.append(corners[c] + Vector2.from_angle(start + PI / 2.0 * float(i) / float(steps)) * r)
	return pts


static func dashed_line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float = 2.0, dash: float = 7.0, gap: float = 5.0) -> void:
	var total: float = a.distance_to(b)
	if total <= 0.0:
		return
	var dir: Vector2 = (b - a) / total
	var at: float = 0.0
	while at < total:
		ci.draw_line(a + dir * at, a + dir * minf(at + dash, total), col, width, true)
		at += dash + gap


## Diagonal stripes inside a rectangle: a pattern that tells two regions apart without colour.
static func hatch(ci: CanvasItem, rect: Rect2, col: Color, spacing: float = 7.0, width: float = 1.5) -> void:
	var h: float = rect.size.y
	var x: float = -h
	while x < rect.size.x:
		var x0: float = maxf(x, 0.0)
		var x1: float = minf(x + h, rect.size.x)
		if x1 > x0:
			var a: Vector2 = rect.position + Vector2(x0, h - (x0 - x))
			var b: Vector2 = rect.position + Vector2(x1, h - (x1 - x))
			ci.draw_line(a, b, col, width, true)
		x += spacing


static func arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, width: float = 2.0, head: float = 7.0) -> void:
	ci.draw_line(a, b, col, width, true)
	var dir: Vector2 = (b - a).normalized()
	var side: Vector2 = dir.orthogonal()
	ci.draw_colored_polygon(PackedVector2Array([b, b - dir * head + side * head * 0.6, b - dir * head - side * head * 0.6]), col)


# === MOLECULES ===
static func glucose(ci: CanvasItem, center: Vector2, r: float, alpha: float = 1.0) -> void:
	filled(ci, ngon(center, r, 6, PI / 6.0), _a(UiTheme.GLUCOSE, alpha), _a(UiTheme.GLUCOSE_EDGE, alpha), maxf(1.5, r * 0.16))
	ci.draw_circle(center, maxf(1.5, r * 0.22), _a(UiTheme.GLUCOSE_EDGE, alpha))


static func galactose(ci: CanvasItem, center: Vector2, r: float, alpha: float = 1.0) -> void:
	filled(ci, ngon(center, r, 5, -PI / 2.0), _a(UiTheme.GALACTOSE, alpha), _a(UiTheme.GALACTOSE_EDGE, alpha), maxf(1.5, r * 0.16))
	ci.draw_line(center + Vector2(-r * 0.38, 0), center + Vector2(r * 0.38, 0), _a(UiTheme.GALACTOSE_EDGE, alpha), maxf(1.5, r * 0.2))


static func sugar(ci: CanvasItem, kind: int, center: Vector2, r: float, alpha: float = 1.0) -> void:
	if kind == MoleculeModel.Kind.GLUCOSE:
		glucose(ci, center, r, alpha)
	elif kind == MoleculeModel.Kind.GALACTOSE:
		galactose(ci, center, r, alpha)
	else:
		lactose(ci, center, r, 0.0, 0.0, alpha)


## Lactose: a glucose and a galactose joined by a bond. `split` (0 to 1) pulls the halves apart
## and removes the bond, for the moment of cleavage.
static func lactose(ci: CanvasItem, center: Vector2, r: float, angle: float = 0.0, split: float = 0.0, alpha: float = 1.0) -> void:
	var axis: Vector2 = Vector2.from_angle(angle)
	var offset: float = r * (1.02 + split * 0.7)
	var left: Vector2 = center - axis * offset
	var right: Vector2 = center + axis * offset
	if split < 0.35:
		ci.draw_line(left, right, _a(UiTheme.INK, alpha), maxf(2.5, r * 0.4), true)
	glucose(ci, left, r, alpha)
	galactose(ci, right, r, alpha)


## Lactase: a body with one pocket (the active site) on top. `w` is the full width.
static func lactase(ci: CanvasItem, center: Vector2, w: float, supplement: bool = false, busy: bool = false) -> void:
	var hw: float = w / 2.0
	var hh: float = w * 0.31
	var raw: Array[Vector2] = [
		Vector2(-1.0, -0.55), Vector2(-0.64, -0.8), Vector2(-0.58, -0.15), Vector2(0.58, -0.15),
		Vector2(0.64, -0.8), Vector2(1.0, -0.55), Vector2(1.05, 0.2), Vector2(0.8, 0.75),
		Vector2(0.3, 0.95), Vector2(-0.3, 0.95), Vector2(-0.8, 0.75), Vector2(-1.05, 0.2),
	]
	var pts: PackedVector2Array = PackedVector2Array()
	for v: Vector2 in raw:
		pts.append(center + Vector2(v.x * hw, v.y * hh))
	var fill: Color = UiTheme.SUPPLEMENT if supplement else UiTheme.LACTASE
	var edge: Color = UiTheme.SUPPLEMENT_EDGE if supplement else UiTheme.LACTASE_EDGE
	if busy:
		fill = fill.darkened(0.12)
	filled(ci, pts, fill, edge, maxf(1.5, w * 0.04))
	if supplement:
		# A plus sign marks enzyme that was added, as well as its different colour.
		var c: Vector2 = center + Vector2(0, hh * 0.4)
		var arm: float = w * 0.09
		ci.draw_line(c - Vector2(arm, 0), c + Vector2(arm, 0), edge, maxf(1.5, w * 0.045))
		ci.draw_line(c - Vector2(0, arm), c + Vector2(0, arm), edge, maxf(1.5, w * 0.045))


## Where a held lactose sits, relative to the lactase centre, for a lactase of width `w`.
static func pocket_offset(w: float) -> Vector2:
	return Vector2(0.0, -w * 0.31 * 0.15 - w * 0.115)


static func droplet(ci: CanvasItem, center: Vector2, r: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array([center + Vector2(0, -r * 1.5)])
	for i: int in range(9):
		pts.append(center + Vector2.from_angle(-PI * 0.15 + PI * 1.3 * float(i) / 8.0) * r)
	filled(ci, pts, UiTheme.WATER, UiTheme.INK, 1.0)


# === PEOPLE ===
## A simple person. `look` picks skin, hair and shirt; it never depends on genotype.
static func avatar(ci: CanvasItem, foot: Vector2, h: float, look: int) -> void:
	var skin: Color = SKIN[posmod(look, SKIN.size())]
	var hair: Color = HAIR[posmod(look / 7, HAIR.size())]
	var shirt: Color = SHIRT[posmod(look / 37, SHIRT.size())]
	var style: int = posmod(look / 191, 4)
	var head_r: float = h * 0.2
	var head: Vector2 = foot + Vector2(0, -h + head_r)
	var body_top: float = foot.y - h + head_r * 2.0 + h * 0.03
	var half: float = h * 0.3
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(foot.x - half, foot.y), Vector2(foot.x - half, body_top + h * 0.14),
		Vector2(foot.x - half * 0.55, body_top), Vector2(foot.x + half * 0.55, body_top),
		Vector2(foot.x + half, body_top + h * 0.14), Vector2(foot.x + half, foot.y),
	])
	filled(ci, body, shirt, UiTheme.INK, 1.0)
	if style == 2:
		ci.draw_circle(head + Vector2(0, head_r * 0.25), head_r * 1.18, hair)
	ci.draw_circle(head, head_r, skin)
	if style != 3:
		var cap: PackedVector2Array = PackedVector2Array()
		for i: int in range(9):
			cap.append(head + Vector2.from_angle(PI + PI * float(i) / 8.0) * head_r * 1.04)
		cap.append(head + Vector2(head_r * 0.6, -head_r * 0.25))
		cap.append(head + Vector2(-head_r * 0.7, -head_r * 0.15))
		ci.draw_colored_polygon(cap, hair)
	if style == 1:
		ci.draw_circle(head + Vector2(0, -head_r * 1.15), head_r * 0.42, hair)
	ci.draw_arc(head, head_r, 0.0, TAU, 20, UiTheme.INK, 1.0, true)


# === ICONS ===
## Draws a named icon inside `rect` in one colour.
static func icon(ci: CanvasItem, id: String, rect: Rect2, col: Color) -> void:
	var c: Vector2 = rect.get_center()
	var s: float = minf(rect.size.x, rect.size.y)
	var u: float = s / 20.0
	match id:
		"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -8) * u, c + Vector2(8, 0) * u, c + Vector2(-6, 8) * u]), col)
		"pause":
			ci.draw_rect(Rect2(c + Vector2(-7, -8) * u, Vector2(5, 16) * u), col)
			ci.draw_rect(Rect2(c + Vector2(2, -8) * u, Vector2(5, 16) * u), col)
		"step":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-8, -8) * u, c + Vector2(3, 0) * u, c + Vector2(-8, 8) * u]), col)
			ci.draw_rect(Rect2(c + Vector2(4, -8) * u, Vector2(4, 16) * u), col)
		"reset":
			ci.draw_arc(c, 7.0 * u, -PI * 0.1, PI * 1.5, 24, col, 2.5 * u, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-1, -11) * u, c + Vector2(6, -6.5) * u, c + Vector2(-1, -2.5) * u]), col)
		"home":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -9) * u, c + Vector2(10, 0) * u, c + Vector2(-10, 0) * u]), col)
			ci.draw_rect(Rect2(c + Vector2(-6.5, 0) * u, Vector2(13, 9) * u), col)
		"compare":
			ci.draw_rect(Rect2(c + Vector2(-9, -7) * u, Vector2(8, 14) * u), col, false, 2.0 * u)
			ci.draw_rect(Rect2(c + Vector2(1, -7) * u, Vector2(8, 14) * u), col, false, 2.0 * u)
		"help":
			ci.draw_arc(c, 8.5 * u, 0.0, TAU, 28, col, 2.0 * u, true)
			text_centered(ci, c, "?", int(14.0 * u), col)
		"labels":
			var tag_pts: PackedVector2Array = PackedVector2Array([c + Vector2(-9, -6) * u, c + Vector2(3, -6) * u, c + Vector2(9, 0) * u, c + Vector2(3, 6) * u, c + Vector2(-9, 6) * u])
			outline(ci, tag_pts, col, 2.0 * u)
			ci.draw_circle(c + Vector2(3, 0) * u, 1.6 * u, col)
		"settings":
			ci.draw_arc(c, 5.0 * u, 0.0, TAU, 24, col, 3.0 * u, true)
			for i: int in range(8):
				var d: Vector2 = Vector2.from_angle(TAU * float(i) / 8.0)
				ci.draw_line(c + d * 6.5 * u, c + d * 9.5 * u, col, 3.0 * u)
		"minus":
			ci.draw_rect(Rect2(c + Vector2(-8, -1.5) * u, Vector2(16, 3) * u), col)
		"plus":
			ci.draw_rect(Rect2(c + Vector2(-8, -1.5) * u, Vector2(16, 3) * u), col)
			ci.draw_rect(Rect2(c + Vector2(-1.5, -8) * u, Vector2(3, 16) * u), col)
		"zoom":
			ci.draw_arc(c + Vector2(-2, -2) * u, 6.0 * u, 0.0, TAU, 24, col, 2.0 * u, true)
			ci.draw_line(c + Vector2(2.5, 2.5) * u, c + Vector2(9, 9) * u, col, 3.0 * u, true)
		"close":
			ci.draw_line(c + Vector2(-7, -7) * u, c + Vector2(7, 7) * u, col, 3.0 * u, true)
			ci.draw_line(c + Vector2(-7, 7) * u, c + Vector2(7, -7) * u, col, 3.0 * u, true)
		"speed":
			for k: int in range(2):
				var o: Vector2 = Vector2(-7.0 + 8.0 * float(k), 0) * u
				ci.draw_polyline(PackedVector2Array([c + o + Vector2(-2, -7) * u, c + o + Vector2(5, 0) * u, c + o + Vector2(-2, 7) * u]), col, 2.5 * u, true)
		"check":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-8, 0) * u, c + Vector2(-2, 6) * u, c + Vector2(8, -7) * u]), col, 3.0 * u, true)
		"cross":
			ci.draw_line(c + Vector2(-6, -6) * u, c + Vector2(6, 6) * u, col, 3.0 * u, true)
			ci.draw_line(c + Vector2(-6, 6) * u, c + Vector2(6, -6) * u, col, 3.0 * u, true)
		"lock":
			ci.draw_rect(Rect2(c + Vector2(-7, -1) * u, Vector2(14, 10) * u), col)
			ci.draw_arc(c + Vector2(0, -1) * u, 5.0 * u, PI, TAU, 16, col, 2.5 * u, true)
		"chart":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-9, -9) * u, c + Vector2(-9, 9) * u, c + Vector2(9, 9) * u]), col, 2.0 * u)
			ci.draw_polyline(PackedVector2Array([c + Vector2(-6, 5) * u, c + Vector2(-1, 1) * u, c + Vector2(3, 3) * u, c + Vector2(8, -6) * u]), col, 2.5 * u, true)
		"next":
			ci.draw_polyline(PackedVector2Array([c + Vector2(-4, -8) * u, c + Vector2(5, 0) * u, c + Vector2(-4, 8) * u]), col, 3.0 * u, true)
		"view":
			ci.draw_arc(c, 8.0 * u, 0.0, TAU, 24, col, 2.0 * u, true)
			ci.draw_circle(c, 3.0 * u, col)
		_:
			ci.draw_arc(c, 7.0 * u, 0.0, TAU, 20, col, 2.0 * u, true)


# === PRIVATE METHODS ===
static func _a(col: Color, alpha: float) -> Color:
	return Color(col.r, col.g, col.b, col.a * alpha)
