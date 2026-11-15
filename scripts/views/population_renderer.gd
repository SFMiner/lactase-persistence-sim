class_name PopulationRenderer
extends Control
## Draws the newborns of one generation as simple people, each with a genotype badge:
##   PP or Pn = filled badge (keeps making lactase as an adult)
##   nn       = outlined badge (makes little lactase as an adult)
## The badge shows letters and fill style, so it does not depend on colour. A person's looks are
## picked at random and never depend on genotype. Each generation is a new set of people: nobody
## changes genotype, the picture is simply redrawn for the next generation.

# === PUBLIC VARIABLES ===
var app: AppState = null
var model: PopulationModel = null
var caption: String = ""


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	custom_minimum_size = Vector2(150, 90)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.PANEL)
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.LINE, false, 1.0)
	if model == null:
		return
	var labels: bool = app == null or app.labels
	var head: float = 18.0
	var foot: float = 16.0 if labels else 0.0
	var area: Rect2 = Rect2(3.0, head, size.x - 6.0, size.y - head - foot - 2.0)
	var shown: int = shown_count(area.size)
	var counts: Array[int] = PopulationModel.avatar_counts(model.p, shown)
	Shapes.text(self, Vector2(4.0, 2.0), "%sGeneration %d: %d newborns pictured" % [caption, model.generation, shown], 12)
	var cols: int = _columns(area.size, shown)
	var rows_n: int = int(ceil(float(shown) / float(cols)))
	var cw: float = area.size.x / float(cols)
	var ch: float = area.size.y / float(rows_n)
	var badge_h: float = clampf(ch * 0.3, 9.0, 14.0) if labels else 0.0
	var avatar_h: float = minf(ch - badge_h - 2.0, cw * 1.25)
	var order: Array[int] = _genotype_order(counts, shown)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5000 + model.generation * 977
	for i: int in range(shown):
		var cx: float = area.position.x + (float(i % cols) + 0.5) * cw
		var top: float = area.position.y + float(i / cols) * ch
		var look: int = rng.randi_range(0, 100000)
		if avatar_h >= 8.0:
			Shapes.avatar(self, Vector2(cx, top + avatar_h), avatar_h, look)
		if labels:
			_badge(Vector2(cx, top + avatar_h + badge_h / 2.0 + 1.0), minf(cw - 2.0, 26.0), badge_h, order[i])
	if labels:
		var legend: String = "filled badge PP, Pn: makes lactase as an adult    outlined badge nn: makes little"
		if Shapes.text_width(legend, 11) > size.x - 8.0:
			legend = "filled PP, Pn: lactase as adult   outlined nn: little"
		Shapes.text(self, Vector2(4.0, size.y - 15.0), legend, 11, UiTheme.MUTED)


# === PUBLIC METHODS ===
## How many people to picture: 100 when there is room, 50 in a small frame.
static func shown_count(area: Vector2) -> int:
	return 100 if area.x * area.y >= 100.0 * 14.0 * 26.0 else 50


# === PRIVATE METHODS ===
func _columns(area: Vector2, n: int) -> int:
	var best: int = n
	var best_score: float = INF
	for cols: int in [10, 20, 25, 50]:
		if cols > n:
			continue
		var rows_n: int = int(ceil(float(n) / float(cols)))
		var cw: float = area.x / float(cols)
		var ch: float = area.y / float(rows_n)
		var score: float = absf(ch / cw - 1.9)
		if score < best_score:
			best_score = score
			best = cols
	return best


## Genotype of each pictured person (0 = PP, 1 = Pn, 2 = nn), mixed with a seeded shuffle.
func _genotype_order(counts: Array[int], n: int) -> Array[int]:
	var order: Array[int] = []
	for g: int in range(3):
		for k: int in range(counts[g]):
			order.append(g)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 91 + model.generation * 131
	for i: int in range(n - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	return order


func _badge(center: Vector2, w: float, h: float, genotype: int) -> void:
	var names: Array[String] = ["PP", "Pn", "nn"]
	var rect: Rect2 = Rect2(center - Vector2(w, h) / 2.0, Vector2(w, h))
	var font_size: int = int(clampf(h - 1.0, 8.0, 12.0))
	if genotype == 2:
		draw_rect(rect, UiTheme.PANEL)
		draw_rect(rect, UiTheme.INK, false, 1.0)
		if w >= 14.0:
			Shapes.text_centered(self, center, names[genotype], font_size, UiTheme.INK)
	else:
		draw_rect(rect, UiTheme.ACCENT)
		if w >= 14.0:
			Shapes.text_centered(self, center, names[genotype], font_size, Color.WHITE)
