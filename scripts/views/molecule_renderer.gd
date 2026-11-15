class_name MoleculeRenderer
extends Control
## Draws one MoleculeModel: a schematic strip of small intestine with lactose in the lumen,
## lactase on the lining (drawn enlarged), and glucose and galactose crossing into the cells.
## It only reads the model. What it shows as "touching" is illustration; the model decides.

# === PUBLIC VARIABLES ===
var model: MoleculeModel = null
var app: AppState = null
## Text shown when lactase comes from the DNA & Lactase view (e.g. a muscle cell has no lining).
var empty_note: String = ""


# === PRIVATE VARIABLES ===
var _w: float = 0.0
var _h: float = 0.0
var _band: float = 0.0
var _border_y: float = 0.0
var _enzyme_w: float = 0.0
var _sugar_r: float = 0.0


# === LIFECYCLE METHODS ===
func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(160, 96)


func _draw() -> void:
	_w = size.x
	_h = size.y
	_band = clampf(_h * 0.16, 18.0, 44.0)
	_border_y = _h - _band
	_enzyme_w = clampf(minf(_w / 11.5, _border_y * 0.34), 22.0, 66.0)
	_sugar_r = _enzyme_w * 0.135
	_draw_background()
	if model == null:
		return
	var labels: bool = app != null and app.labels
	var explain: bool = app != null and app.explain
	var reduced: bool = app != null and app.reduced_motion()
	for e: MoleculeModel.Enzyme in model.enzymes:
		_draw_enzyme(e, labels)
	for p: MoleculeModel.Particle in model.particles:
		_draw_particle(p, reduced)
	_draw_time()
	if labels:
		_draw_labels(explain, reduced)
	_draw_status(explain)


# === PUBLIC METHODS ===
## Model coordinates (0..1) to pixels. y = 1 is the surface of the lining.
func to_px(p: Vector2) -> Vector2:
	return Vector2(p.x * _w, lerpf(6.0, _border_y, p.y))


func enzyme_px(e: MoleculeModel.Enzyme) -> Vector2:
	var p: Vector2 = to_px(e.pos)
	if not e.supplement:
		# Keep the lower row sitting on the lining whatever the stage height.
		var rest: float = _border_y - _enzyme_w * 0.31 * 0.75
		var lift: float = (0.92 - e.pos.y) / 0.14 * _enzyme_w * 0.75
		p.y = rest - lift
	return p


# === PRIVATE METHODS ===
func _draw_background() -> void:
	draw_rect(Rect2(0, 0, _w, _border_y), UiTheme.LUMEN)
	# The lining: a row of cells with a brush border (microvilli) on the lumen side.
	var cell_w: float = clampf(_band * 1.5, 30.0, 70.0)
	var count: int = int(ceil(_w / cell_w))
	for i: int in range(count):
		var x: float = float(i) * cell_w
		var rect: Rect2 = Rect2(x + 1.0, _border_y, cell_w - 2.0, _band + 8.0)
		Shapes.filled(self, Shapes.rounded_rect(rect, 5.0, 3), UiTheme.CELL, UiTheme.CELL_EDGE, 1.5)
		draw_circle(Vector2(x + cell_w / 2.0, _border_y + _band * 0.62), _band * 0.17, UiTheme.NUCLEUS)
	var x2: float = 2.0
	var comb: PackedVector2Array = PackedVector2Array()
	while x2 < _w:
		comb.append(Vector2(x2, _border_y))
		comb.append(Vector2(x2, _border_y - 5.0))
		x2 += 4.0
	if comb.size() >= 2:
		draw_multiline(comb, UiTheme.CELL_EDGE, 1.5)
	draw_rect(Rect2(0, 0, _w, _h), UiTheme.LINE, false, 1.0)


func _draw_enzyme(e: MoleculeModel.Enzyme, labels: bool) -> void:
	var c: Vector2 = enzyme_px(e)
	Shapes.lactase(self, c, _enzyme_w, e.supplement, e.state == MoleculeModel.EnzymeState.CLEAVING)
	if labels and _enzyme_w >= 34.0 and e.turnovers > 0:
		var at: Vector2 = c + Vector2(_enzyme_w * (0.22 if e.supplement else 0.0), _enzyme_w * 0.13)
		Shapes.text_centered(self, at, "x%d" % e.turnovers, int(clampf(_enzyme_w * 0.2, 9.0, 12.0)), UiTheme.INK)


func _pocket_px(enzyme_id: int) -> Vector2:
	if enzyme_id < 0 or enzyme_id >= model.enzymes.size():
		return Vector2.ZERO
	return enzyme_px(model.enzymes[enzyme_id]) + Shapes.pocket_offset(_enzyme_w)


func _particle_px(p: MoleculeModel.Particle, reduced: bool) -> Vector2:
	match p.state:
		MoleculeModel.ParticleState.FREE:
			return to_px(p.home if reduced else p.pos)
		MoleculeModel.ParticleState.CLAIMED:
			var pocket: Vector2 = _pocket_px(p.enzyme)
			if reduced:
				return pocket
			var t: float = clampf(float(p.timer) / float(MoleculeModel.BIND_TICKS), 0.0, 1.0)
			return to_px(p.from).lerp(pocket, smoothstep(0.0, 1.0, t))
		MoleculeModel.ParticleState.BOUND:
			return _pocket_px(p.enzyme)
		MoleculeModel.ParticleState.DRIFTING:
			return to_px(p.home if reduced else p.pos)
		_:
			if reduced:
				return to_px(Vector2(p.home.x, 1.0))
			return to_px(p.pos)


func _draw_particle(p: MoleculeModel.Particle, reduced: bool) -> void:
	var at: Vector2 = _particle_px(p, reduced)
	if p.kind == MoleculeModel.Kind.LACTOSE:
		var split: float = 0.0
		var angle: float = p.angle
		if p.state == MoleculeModel.ParticleState.BOUND:
			angle = 0.0
			split = clampf((float(p.timer) / float(MoleculeModel.CLEAVE_TICKS) - 0.55) / 0.45, 0.0, 1.0)
		elif p.state == MoleculeModel.ParticleState.CLAIMED and reduced:
			angle = 0.0
		Shapes.lactose(self, at, _sugar_r, angle, split * 0.5)
		return
	var alpha: float = 1.0
	if p.state == MoleculeModel.ParticleState.ABSORBING:
		alpha = 1.0 - 0.65 * clampf(float(p.timer) / float(MoleculeModel.PRODUCT_ABSORB_TICKS), 0.0, 1.0)
	Shapes.sugar(self, p.kind, at, _sugar_r, alpha)


func _draw_time() -> void:
	var total: float = model.period_seconds()
	var now: float = model.time_seconds()
	var bar_w: float = clampf(_w * 0.22, 60.0, 150.0)
	var rect: Rect2 = Rect2(_w - bar_w - 6.0, 5.0, bar_w, 8.0)
	draw_rect(rect, Color(1, 1, 1, 0.9))
	draw_rect(Rect2(rect.position, Vector2(bar_w * clampf(now / total, 0.0, 1.0), rect.size.y)), UiTheme.MUTED)
	draw_rect(rect, UiTheme.INK, false, 1.0)
	Shapes.text_right(self, Vector2(_w - 6.0, 15.0), "time %.1f of %.0f s" % [now, total], 11, UiTheme.INK)


func _draw_labels(explain: bool, reduced: bool) -> void:
	var size_px: int = 12 if _w >= 300.0 else 10
	Shapes.text(self, Vector2(5, 3), "inside the small intestine", size_px, UiTheme.MUTED)
	if _band >= 22.0:
		Shapes.tag(self, Vector2(minf(_w * 0.5, _w - 80.0), _h - _band * 0.42), "cells of the intestine lining", size_px)
	var first_lining: MoleculeModel.Enzyme = null
	var first_supplement: MoleculeModel.Enzyme = null
	for e: MoleculeModel.Enzyme in model.enzymes:
		if e.supplement and first_supplement == null:
			first_supplement = e
		elif not e.supplement and first_lining == null:
			first_lining = e
	if first_lining != null:
		Shapes.tag(self, enzyme_px(first_lining) + Vector2(maxf(0.0, 26.0 - enzyme_px(first_lining).x), -_enzyme_w * 0.55), "lactase", size_px)
	if first_supplement != null:
		Shapes.tag(self, enzyme_px(first_supplement) + Vector2(34.0, -_enzyme_w * 0.5), "supplement lactase", size_px)
	var seen: Dictionary = {}
	for p: MoleculeModel.Particle in model.particles:
		if seen.has(p.kind):
			continue
		if p.kind == MoleculeModel.Kind.LACTOSE and p.state != MoleculeModel.ParticleState.FREE:
			continue
		if p.kind != MoleculeModel.Kind.LACTOSE and p.state != MoleculeModel.ParticleState.DRIFTING:
			continue
		seen[p.kind] = true
		var names: Array[String] = ["lactose", "glucose", "galactose"]
		var at: Vector2 = _particle_px(p, reduced) + Vector2(0, -_sugar_r - 11.0)
		at.x = clampf(at.x, 32.0, _w - 36.0)
		at.y = maxf(at.y, 28.0)
		Shapes.tag(self, at, names[p.kind], size_px)
	if explain:
		for e: MoleculeModel.Enzyme in model.enzymes:
			if e.state == MoleculeModel.EnzymeState.CLEAVING:
				var c: Vector2 = enzyme_px(e) + Vector2(0, -_enzyme_w * 0.62)
				Shapes.droplet(self, c + Vector2(-34, 2), 4.0)
				c.x = clampf(c.x, 70.0, _w - 60.0)
				Shapes.tag(self, c + Vector2(18, 0), "water splits the bond", size_px)
				break


func _draw_status(explain: bool) -> void:
	var lines: Array[String] = []
	if model.total_enzymes() == 0 and empty_note != "":
		lines.append(empty_note)
	if model.finished and model.lactose_start > 0:
		if model.lactose_remaining > 0:
			lines.append("Time is up: %d lactose still whole." % model.lactose_remaining)
			if explain:
				lines.append("Whole lactose is not absorbed here. It moves on.")
		else:
			lines.append("All the lactose was split.")
	if explain and model.cleaved > 0 and not model.finished:
		lines.append("Lactase is not used up: each one is reused.")
	var y: float = _border_y * 0.42 - float(lines.size()) * 10.0
	for line: String in lines:
		Shapes.tag(self, Vector2(_w / 2.0, y), line, 13 if _w >= 300.0 else 11)
		y += 22.0
