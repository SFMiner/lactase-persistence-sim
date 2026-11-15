class_name Announcer
extends Node
## Mirrors what happens in the simulator to the hidden live regions in web/shell.html, so a screen
## reader has something to read: the focused control, and results such as "run finished".
## Same shell contract as cell-designer and data-detectives (renamed hook). Outside a web export it
## only records what would have been said. Not yet tested with a real screen reader.

# === CONSTANTS ===
const HISTORY_SIZE: int = 40

# === PUBLIC VARIABLES ===
## The last messages sent, newest last. Read by tests.
var history: Array[String] = []


# === PUBLIC METHODS ===
## Polite announcement (waits for the screen reader to finish).
func say(text: String) -> void:
	_send(text, false)


## Urgent announcement (interrupts).
func alert(text: String) -> void:
	_send(text, true)


func last_text() -> String:
	return "" if history.is_empty() else history[-1]


# === PRIVATE METHODS ===
func _send(text: String, assertive: bool) -> void:
	var clean: String = text.strip_edges()
	if clean.is_empty():
		return
	history.append(clean)
	while history.size() > HISTORY_SIZE:
		history.pop_front()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("if (window.lpAnnounce) window.lpAnnounce(%s, %s)" % [JSON.stringify(clean),
			"true" if assertive else "false"])
