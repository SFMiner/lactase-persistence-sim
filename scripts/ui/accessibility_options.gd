class_name AccessibilityOptions
extends RefCounted
## Text size and reduced motion, saved in the browser (Godot user://), plus the whitelisted class
## settings a teacher can put in the page address (GDD 9.4). These settings only change how things
## are shown and which view opens first; none of them touch the science rules.

# === CONSTANTS ===
const SAVE_PATH: String = "user://settings.cfg"
const TEXT_SCALES: Array[float] = [1.0, 1.25, 1.5]
const TEXT_NAMES: Array[String] = ["Normal", "Large", "Extra large"]
## Values each address setting accepts. Anything else is ignored.
const QUERY_CHOICES: Dictionary = {
	"model": ["menu", "molecules", "regulation", "evidence", "population"],
	"mode": ["explore", "explain"],
	"motion": ["normal", "reduced"],
	"labels": ["on", "off"],
}

# === PUBLIC VARIABLES ===
## Index into TEXT_SCALES.
var text_size: int = 0
var reduced_motion: bool = false
## True once the player, a saved file or the address has chosen reduced motion, so the browser's
## own preference no longer decides.
var reduced_motion_chosen: bool = false
## Tests turn this off so they never write to a player's saved settings.
var persist: bool = true


# === PUBLIC METHODS ===
func load_saved() -> void:
	var cf: ConfigFile = ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	text_size = clampi(int(cf.get_value("view", "text_size", 0)), 0, TEXT_SCALES.size() - 1)
	if cf.has_section_key("view", "reduced_motion"):
		reduced_motion = bool(cf.get_value("view", "reduced_motion", false))
		reduced_motion_chosen = true


func save() -> void:
	if not persist:
		return
	var cf: ConfigFile = ConfigFile.new()
	cf.set_value("view", "text_size", text_size)
	if reduced_motion_chosen:
		cf.set_value("view", "reduced_motion", reduced_motion)
	cf.save(SAVE_PATH)


func text_scale() -> float:
	return TEXT_SCALES[text_size]


## Parses a page query string ("?model=population&mode=explain") into the settings it recognises.
## Unknown keys and values outside the lists are dropped. The text is only ever compared with
## fixed strings; it is never run, shown, or used as a path.
static func parse_query(search: String) -> Dictionary:
	var out: Dictionary = {}
	var text: String = search.strip_edges()
	if text.begins_with("?"):
		text = text.substr(1)
	if text.length() > 512:
		return out
	for pair: String in text.split("&", false):
		var parts: PackedStringArray = pair.split("=", true, 1)
		if parts.size() != 2:
			continue
		var key: String = parts[0]
		if not QUERY_CHOICES.has(key) or out.has(key):
			continue
		var allowed: Array = QUERY_CHOICES[key]
		for option: Variant in allowed:
			if parts[1] == str(option):
				out[key] = str(option)
				break
	return out


## Reads the page address and the browser's reduced-motion preference. Web builds only; returns
## the recognised address settings (empty elsewhere).
func read_browser() -> Dictionary:
	if not OS.has_feature("web"):
		return {}
	var query: Dictionary = {}
	var search: Variant = JavaScriptBridge.eval("window.location.search", true)
	if search is String:
		query = parse_query(search)
	if not reduced_motion_chosen:
		var prefers: Variant = JavaScriptBridge.eval(
			"(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches) ? 1 : 0", true)
		if prefers is float or prefers is int:
			reduced_motion = int(prefers) == 1
	return query
