extends Control
## "Choose a Model": the opening screen. Four tiles, no tutorial and no fixed order; every model
## can be opened at any time and Home always comes back here.

# === SIGNALS ===
signal model_chosen(id: String)

# === CONSTANTS ===
const TILES: Array[Dictionary] = [
	{"id": "molecules", "title": "Molecules", "objective": "Watch lactose meet lactase. What changes when there is more or less lactase?"},
	{"id": "regulation", "title": "DNA & Lactase", "objective": "Compare people who inherited different regulatory DNA, at different ages."},
	{"id": "population", "title": "Generations", "objective": "Follow one inherited DNA variant in a population over many generations."},
	{"id": "evidence", "title": "Evidence", "objective": "Compare DNA excerpts from Kanna, her family and Alissa."},
]

# === PUBLIC VARIABLES ===
var app: AppState = null
var tiles: Array[TileButton] = []


# === PRIVATE VARIABLES ===
var _grid: GridContainer = null
var _question: Label = null


# === LIFECYCLE METHODS ===
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 10)
	scroll.add_child(margin)
	var column: VBoxContainer = UiKit.vbox(8)
	margin.add_child(column)
	_question = UiKit.label("Why can some people digest lactose as adults, while others cannot? Choose a model to explore.", UiTheme.TITLE_FONT)
	column.add_child(_question)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_grid)
	for info: Dictionary in TILES:
		var tile: TileButton = TileButton.new()
		tile.tile_id = str(info["id"])
		tile.tile_title = str(info["title"])
		tile.objective = str(info["objective"])
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tile.pressed.connect(_choose.bind(tile.tile_id))
		_grid.add_child(tile)
		tiles.append(tile)
	column.add_child(UiKit.label("This is a model for exploring ideas. It does not predict anyone's health or symptoms.", UiTheme.SMALL_FONT, UiTheme.MUTED))


# === PUBLIC METHODS ===
func title() -> String:
	return "Lactase Persistence Simulator"


func help_steps() -> Array[Dictionary]:
	return [
		{"icon": "lactase", "text": "Molecules: what lactase does to lactose in the small intestine."},
		{"icon": "dna", "text": "DNA & Lactase: how inherited regulatory DNA and age change how much lactase a cell makes."},
		{"icon": "person", "text": "Generations: how an inherited variant can become more common in a population."},
		{"icon": "zoom", "text": "Evidence: the DNA excerpts from the lesson. Open the models in any order; Home comes back here."},
	]


func apply_layout(view_size: Vector2, _narrow: bool, _reserve: Vector2, _bar_height: float) -> void:
	if _grid == null:
		return
	var columns: int = 4
	if view_size.x < 560.0:
		columns = 1
	elif view_size.x < 1060.0:
		columns = 2
	_grid.columns = columns
	_question.add_theme_font_size_override("font_size", UiTheme.TITLE_FONT if view_size.x >= 700.0 else UiTheme.FONT_SIZE)


# === PRIVATE METHODS ===
func _choose(id: String) -> void:
	model_chosen.emit(id)
