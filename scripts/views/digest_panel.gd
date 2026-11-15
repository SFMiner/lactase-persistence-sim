class_name DigestPanel
extends VBoxContainer
## One digestion picture with its counts: a caption, a MoleculeRenderer and a MoleculeReadout bound
## to the same MoleculeModel. Used by the Molecules view and, as the digestion preview, by the
## DNA & Lactase view, so both views show the same rules.

# === PUBLIC VARIABLES ===
var model: MoleculeModel = null
var renderer: MoleculeRenderer = null
var readout: MoleculeReadout = null
var caption_label: Label = null


# === PUBLIC METHODS ===
static func create(app: AppState) -> DigestPanel:
	var d: DigestPanel = DigestPanel.new()
	d.add_theme_constant_override("separation", 2)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.caption_label = UiKit.label("", UiTheme.SMALL_FONT, UiTheme.INK, false)
	d.caption_label.clip_text = true
	d.add_child(d.caption_label)
	d.renderer = MoleculeRenderer.new()
	d.renderer.app = app
	d.renderer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	d.add_child(d.renderer)
	d.readout = MoleculeReadout.new()
	d.add_child(d.readout)
	return d


func set_model(m: MoleculeModel) -> void:
	model = m
	renderer.model = m
	readout.model = m
	redraw()


func set_caption(text: String) -> void:
	caption_label.text = text
	caption_label.visible = text != ""


func redraw() -> void:
	renderer.queue_redraw()
	readout.queue_redraw()


## The numbers of this run in one sentence, for "What changed?" and for screen readers.
static func summary_text(m: MoleculeModel) -> String:
	if m == null:
		return ""
	return "Lactose: %d at start, %d left. Split: %d. Glucose made: %d. Galactose made: %d. Lactase: %d at start, %d now. Time: %.1f s." % [
		m.lactose_start, m.lactose_remaining, m.cleaved, m.glucose_formed, m.galactose_formed,
		m.enzyme_count + m.supplement_count, m.total_enzymes(), m.time_seconds()]
