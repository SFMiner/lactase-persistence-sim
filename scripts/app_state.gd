class_name AppState
extends RefCounted
## Shared presentation state for every view: Explore/Explain, labels, speed, and the accessibility
## options. It holds no science: each view owns its own model, and the DNA & Lactase view passes
## its lactase amount to the digestion model through RegulationModel.build_digestion().

# === SIGNALS ===
## Emitted when any presentation setting changes; views redraw.
signal changed

# === CONSTANTS ===
const SPEEDS: Array[float] = [1.0, 2.0, 0.5]
const SPEED_NAMES: Array[String] = ["1x", "2x", "0.5x"]

# === PUBLIC VARIABLES ===
## False = Explore (names only, no causal conclusions); true = Explain (relationships labelled).
var explain: bool = false
var labels: bool = true
var speed_index: int = 0
var access: AccessibilityOptions = AccessibilityOptions.new()
var announcer: Announcer = null


# === PUBLIC METHODS ===
func speed() -> float:
	return SPEEDS[speed_index]


func speed_name() -> String:
	return SPEED_NAMES[speed_index]


func cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEEDS.size()
	changed.emit()


func set_explain(on: bool) -> void:
	explain = on
	changed.emit()


func set_labels(on: bool) -> void:
	labels = on
	changed.emit()


func reduced_motion() -> bool:
	return access.reduced_motion


func set_reduced_motion(on: bool) -> void:
	access.reduced_motion = on
	access.reduced_motion_chosen = true
	access.save()
	changed.emit()


func set_text_size(index: int) -> void:
	access.text_size = clampi(index, 0, AccessibilityOptions.TEXT_SCALES.size() - 1)
	access.save()
	changed.emit()


## Applies recognised address settings for this session (not saved).
func apply_query(query: Dictionary) -> void:
	if query.has("mode"):
		explain = str(query["mode"]) == "explain"
	if query.has("labels"):
		labels = str(query["labels"]) == "on"
	if query.has("motion"):
		access.reduced_motion = str(query["motion"]) == "reduced"
		access.reduced_motion_chosen = true


func say(text: String) -> void:
	if announcer != null:
		announcer.say(text)
