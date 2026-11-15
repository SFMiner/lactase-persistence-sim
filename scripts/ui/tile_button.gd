class_name TileButton
extends Button
## A large menu tile: a small drawing, a title and one line about what the model is for.

# === PUBLIC VARIABLES ===
var tile_id: String = ""
var tile_title: String = ""
var objective: String = ""


# === LIFECYCLE METHODS ===
func _init() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(200, 150)
	clip_contents = true
	# The tile clips its drawing, which would also clip the theme's outside focus outline, so
	# the outline is drawn inside the tile instead (see _draw).
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func _draw() -> void:
	var art: Rect2 = Rect2(10.0, 8.0, size.x - 20.0, clampf(size.y * 0.42, 40.0, 120.0))
	draw_rect(art, UiTheme.LUMEN)
	draw_rect(art, UiTheme.LINE, false, 1.0)
	var c: Vector2 = art.get_center()
	# One drawing unit: every picture fits in a box about 3.6 units wide and 1 unit tall.
	var u: float = minf(art.size.y * 0.8, art.size.x / 3.8)
	match tile_id:
		"molecules":
			Shapes.lactase(self, c + Vector2(-u * 0.5, u * 0.12), u * 1.1)
			Shapes.lactose(self, c + Vector2(-u * 0.5, u * 0.12) + Shapes.pocket_offset(u * 1.1), u * 1.1 * 0.135)
			Shapes.arrow(self, c + Vector2(u * 0.2, 0), c + Vector2(u * 0.6, 0), UiTheme.INK, 2.0)
			Shapes.glucose(self, c + Vector2(u * 0.95, -u * 0.12), u * 0.17)
			Shapes.galactose(self, c + Vector2(u * 1.4, u * 0.12), u * 0.17)
		"regulation":
			var reg: Rect2 = Rect2(c.x - u * 1.5, c.y - u * 0.18, u * 1.0, u * 0.36)
			var cod: Rect2 = Rect2(c.x - u * 0.2, c.y - u * 0.18, u * 1.7, u * 0.36)
			draw_line(Vector2(art.position.x + 6.0, c.y), Vector2(art.end.x - 6.0, c.y), UiTheme.MUTED, 3.0)
			draw_rect(reg, UiTheme.REGULATORY)
			Shapes.hatch(self, reg, Color(UiTheme.INK, 0.55), 7.0, 1.2)
			draw_rect(reg, UiTheme.INK, false, 2.0)
			draw_rect(cod, UiTheme.CODING)
			draw_rect(cod, UiTheme.INK, false, 2.0)
		"population":
			for i: int in range(5):
				Shapes.avatar(self, Vector2(c.x - u * 1.3 + float(i) * u * 0.42, c.y + u * 0.38), u * 0.7, 3 + i * 53)
			var pts: PackedVector2Array = PackedVector2Array([
				c + Vector2(u * 0.75, u * 0.3), c + Vector2(u * 1.05, u * 0.2), c + Vector2(u * 1.35, -u * 0.05), c + Vector2(u * 1.65, -u * 0.32)])
			draw_polyline(pts, UiTheme.ACCENT, 3.0, true)
			for p: Vector2 in pts:
				draw_circle(p, 3.5, UiTheme.ACCENT)
		"evidence":
			var letters: Array[String] = ["A", "T", "T", "A", "C", "T"]
			for i: int in range(6):
				var row: int = i / 3
				var at: Vector2 = c + Vector2((float(i % 3) - 1.0) * u * 0.34 - u * 0.4, (float(row) - 0.5) * u * 0.42)
				Shapes.text_centered(self, at, letters[i], int(u * 0.3))
			Shapes.icon(self, "zoom", Rect2(c + Vector2(u * 0.5, -u * 0.3), Vector2(u * 0.6, u * 0.6)), UiTheme.INK)
	var font: Font = get_theme_font("font")
	var y: float = art.end.y + 6.0
	draw_string(font, Vector2(12.0, y + font.get_ascent(UiTheme.TITLE_FONT)), tile_title, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, UiTheme.TITLE_FONT, UiTheme.INK)
	y += font.get_height(UiTheme.TITLE_FONT) + 2.0
	draw_multiline_string(font, Vector2(12.0, y + font.get_ascent(UiTheme.SMALL_FONT)), objective, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24.0, UiTheme.SMALL_FONT, 3, UiTheme.MUTED)
	if has_focus():
		draw_rect(Rect2(Vector2(2.5, 2.5), size - Vector2(5, 5)), UiTheme.FOCUS, false, 5.0)


# === PUBLIC METHODS ===
func spoken() -> String:
	return tile_title + ". " + objective
