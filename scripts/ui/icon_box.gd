class_name IconBox
extends Control
## A small picture for the Help steps: either a named UI icon or one of the molecule shapes.

# === PUBLIC VARIABLES ===
var icon_id: String = "":
	set(value):
		icon_id = value
		queue_redraw()
var box_size: float = 40.0


# === LIFECYCLE METHODS ===
func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	custom_minimum_size = Vector2(box_size, box_size)


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var r: float = box_size / 2.0
	match icon_id:
		"lactose":
			Shapes.lactose(self, c, r * 0.42)
		"glucose":
			Shapes.glucose(self, c, r * 0.6)
		"galactose":
			Shapes.galactose(self, c, r * 0.6)
		"lactase":
			Shapes.lactase(self, c + Vector2(0, r * 0.1), r * 1.7)
		"person":
			Shapes.avatar(self, c + Vector2(0, r * 0.9), r * 1.8, 3)
		"dna":
			var rect: Rect2 = Rect2(c + Vector2(-r * 0.9, -r * 0.3), Vector2(r * 1.8, r * 0.6))
			draw_rect(rect, UiTheme.REGULATORY)
			Shapes.hatch(self, rect, UiTheme.INK, 6.0, 1.0)
			draw_rect(rect, UiTheme.INK, false, 1.5)
		_:
			Shapes.icon(self, icon_id, Rect2(c - Vector2(r, r) * 0.6, Vector2(r, r) * 1.2), UiTheme.INK)
