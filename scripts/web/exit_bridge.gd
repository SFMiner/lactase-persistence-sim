class_name ExitBridge
extends RefCounted
## The one message the simulator ever sends to its host page: "the player wants to leave".
## The sims site's play page listens for it and moves focus to its own Full screen button.
## Outside a web export, or when the game is not in a frame, nothing is sent.

# === CONSTANTS ===
const LEAVE_SCRIPT: String = "if (window.parent !== window) window.parent.postMessage({type: 'sims:leave-game'}, location.origin)"


# === PUBLIC METHODS ===
## Releases keyboard focus and tells a same-origin host page that the player is leaving.
static func leave(viewport: Viewport) -> void:
	viewport.gui_release_focus()
	if OS.has_feature("web"):
		JavaScriptBridge.eval(LEAVE_SCRIPT)
