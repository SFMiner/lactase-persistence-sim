extends "res://tests/test_base.gd"
## Scene-level checks on the real Main scene, headless: no auto-play, the three modules and the
## Evidence view driven through their own controls, pause / reset / compare, settings that only
## change presentation, address settings, and layout at the documented frame sizes.
## Frames are stepped by calling a view's _process directly, so "60 seconds" is simulated frames.
## Run:  Godot --headless --path . --script tests/test_views.gd

const EXPECTED: int = 98
const FRAME: float = 1.0 / 60.0
const VIEWS: Array[String] = ["menu", "molecules", "regulation", "evidence", "population"]


func _init() -> void:
	test_name = "test_views"
	_run.call_deferred()


func frames(view: Control, n: int) -> void:
	for i: int in range(n):
		view._process(FRAME)


func _run() -> void:
	await boot_main()
	_query()
	_scaling()
	await _no_autoplay()
	await _molecules()
	await _regulation()
	await _evidence()
	await _population()
	await _presentation_settings()
	await _layouts()
	finish(EXPECTED)


func _query() -> void:
	var q: Dictionary = AccessibilityOptions.parse_query("?model=population&mode=explain&motion=reduced&labels=off")
	check(q == {"model": "population", "mode": "explain", "motion": "reduced", "labels": "off"}, "all four address settings are read")
	check(AccessibilityOptions.parse_query("?model=admin&mode=teacher&debug=1&labels=maybe").is_empty(), "unknown keys and values are ignored")
	check(AccessibilityOptions.parse_query("model=evidence") == {"model": "evidence"}, "works without the question mark")
	check(AccessibilityOptions.parse_query("?model=molecules&model=population") == {"model": "molecules"}, "a repeated key keeps the first value")
	check(AccessibilityOptions.parse_query("?" + "a".repeat(600)).is_empty(), "an over-long address is ignored")
	check(AccessibilityOptions.parse_query("?MODEL=population&model=Population&model=%70opulation").is_empty(), "values must match exactly; nothing is decoded or run")
	var state: AppState = AppState.new()
	state.access.persist = false
	state.apply_query(q)
	check(state.explain and not state.labels and state.reduced_motion(), "address settings set mode, labels and motion")
	var defaults: AppState = AppState.new()
	check(not defaults.explain and defaults.labels and not defaults.reduced_motion(), "defaults: Explore, labels on, normal motion")


func _scaling() -> void:
	check(near(ResponsiveLayout.css_scale(Vector2(1180, 500), 1.0, 1.0), 1.0), "1180 x 500 frame: 1 layout px = 1 CSS px")
	check(near(ResponsiveLayout.css_scale(Vector2(1770, 750), 1.5, 1.0), 1.0), "the same frame at device pixel ratio 1.5: still 1 CSS px")
	check(near(ResponsiveLayout.css_scale(Vector2(1180, 360), 1.0, 1.0), 0.85), "360 px tall: text is held at 0.85 CSS px, not shrunk to 0.72")
	check(near(ResponsiveLayout.css_scale(Vector2(1180, 250), 2.0, 1.0), 0.85), "200% zoom (590 x 250 CSS px at ratio 2): held at 0.85")
	check(near(ResponsiveLayout.css_scale(Vector2(1180, 500), 1.0, 1.5), 1.5), "Extra large text: 1.5 CSS px per layout px")
	check(ResponsiveLayout.css_scale(Vector2(3840, 2160), 1.0, 1.0) <= 2.5, "a very large window is capped")


func _no_autoplay() -> void:
	var moving: int = 0
	for id: String in VIEWS:
		var view: Control = await open_view(id)
		if "running" in view and view.running:
			moving += 1
	check(moving == 0, "no view starts running by itself")
	var mol: Control = await open_view("molecules")
	var before: String = mol.model_a.digest()
	frames(mol, 3600)
	check(mol.model_a.digest() == before and mol.model_a.tick_count == 0, "Molecules: 60 s without input changes nothing")
	var pop: Control = await open_view("population")
	frames(pop, 3600)
	check(pop.model_a.generation == 0, "Generations: 60 s without input makes no generation")
	var players: int = 0
	players = _count_audio(main)
	check(players == 0, "there is no audio player anywhere in the scene")


func _count_audio(node: Node) -> int:
	var n: int = 0
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D:
		n += 1
	for child: Node in node.get_children():
		n += _count_audio(child)
	return n


func _molecules() -> void:
	var v: Control = await open_view("molecules")
	check(v.lactose_stepper.value == 50 and v.lactase_stepper.value == 8, "defaults: 50 lactose, 8 lactase")
	check(v.model_a.lactose_start == 50 and v.model_a.enzyme_count == 8, "the model matches the controls")
	v.on_play_pressed()
	frames(v, 120)
	check(v.running and v.model_a.tick_count == 60, "Run: 2 s of frames is 60 model ticks at 1x")
	v.on_play_pressed()
	var paused_at: int = v.model_a.tick_count
	frames(v, 120)
	check(not v.running and v.model_a.tick_count == paused_at, "Pause stops the model")
	v.on_step_pressed()
	check(v.model_a.tick_count > paused_at and not v.running, "Step moves forward while paused")
	main.app.cycle_speed()
	v.on_play_pressed()
	var at: int = v.model_a.tick_count
	frames(v, 60)
	check(v.model_a.tick_count == at + 60, "Speed 2x: 1 s of frames is 60 ticks")
	main.app.cycle_speed()
	at = v.model_a.tick_count
	frames(v, 60)
	check(v.model_a.tick_count == at + 15, "Speed 0.5x: 1 s of frames is 15 ticks")
	main.app.cycle_speed()
	frames(v, 3000)
	check(v.model_a.finished and not v.running, "the run stops itself when it is finished")
	check(v.model_a.cleaved == 50 and v.model_a.check_invariants() == "", "the run through the view split all 50 lactose and the counts add up")
	check(v.step_button.disabled, "Step is unavailable once the run is over")
	var finished_digest: String = v.model_a.digest()
	v.on_reset_pressed()
	check(v.model_a.tick_count == 0 and v.model_a.lactose_remaining == 50, "Reset returns to the start")
	v.on_play_pressed()
	frames(v, 3000)
	check(v.model_a.digest() == finished_digest, "replay after Reset is the same run")
	# Compare: same lactose and seed, different lactase.
	v.compare_button.button_pressed = true
	await process_frame
	check(v.panel_b.visible and v.lactase_b_stepper.visible, "Compare shows strip B and its lactase control")
	check(v.model_b.lactose_start == v.model_a.lactose_start and v.model_b.rng_seed == v.model_a.rng_seed, "strip B has the same lactose and seed")
	v.on_play_pressed()
	frames(v, 3000)
	check(v.model_a.cleaved == 50 and v.model_b.cleaved == 19, "A (8 lactase) splits 50; B (2 lactase) splits 19 in the same time (%d, %d)" % [v.model_a.cleaved, v.model_b.cleaved])
	check(v.model_b.lactose_remaining == 31 and v.model_b.total_enzymes() == 2, "B: 31 lactose left, and still 2 lactase")
	v.changed_button.button_pressed = true
	check(v.changed_label.visible and v.changed_label.text.contains("Lactase: 2 at start, 2 now"), "What changed? gives the numbers, with lactase unchanged")
	# A setting change starts a fresh paused run.
	v.lactase_stepper.set_value(0)
	check(not v.running and v.model_a.tick_count == 0 and v.model_a.enzyme_count == 0, "changing a setting starts a fresh, paused run")
	v.on_play_pressed()
	frames(v, 3000)
	check(v.model_a.glucose_formed == 0 and v.model_a.lactose_remaining == 50, "through the view: zero lactase makes no products")


func _regulation() -> void:
	var v: Control = await open_view("regulation")
	check(v.models[0].enzyme_count == 2, "default person: adult, typical decline, 2 lactase")
	check(not _has_enabled_stepper(v), "no manual lactase control here: the amount comes from the model")
	v.stage_row.buttons[0].pressed.emit()
	check(v.configs[0].stage == RegulationModel.Stage.INFANT and v.models[0].enzyme_count == 20, "Infant: 20 lactase")
	var coding_before: String = DnaRenderer.coding_text(1000.0, 11)
	v.variant_row.buttons[1].pressed.emit()
	check(v.models[0].enzyme_count == 20, "infant with the persistence variant: still 20 lactase")
	v.stage_row.buttons[2].pressed.emit()
	check(v.models[0].enzyme_count == 18 and v.cell_views[0].enzyme_count == 18, "adult with the persistence variant: 18 lactase, shown in the cell")
	check(v.dna_views[0].variant == RegulationModel.Variant.PERSISTENT and DnaRenderer.coding_text(1000.0, 11) == coding_before, "the DNA picture marks the regulatory variant; the coding text is unchanged")
	v.cell_row.buttons[1].pressed.emit()
	check(v.models[0].enzyme_count == 0, "muscle cell: no lactase")
	v.cell_row.buttons[0].pressed.emit()
	v.compare_button.button_pressed = true
	await process_frame
	check(v.columns[1].visible and v.editing_row.visible, "Compare shows a second person")
	v.editing_row.buttons[0].pressed.emit()
	v.variant_row.buttons[0].pressed.emit()
	check(v.configs[0].variant == RegulationModel.Variant.TYPICAL and v.configs[1].variant == RegulationModel.Variant.PERSISTENT, "the two people keep their own regulatory DNA")
	v.challenge_row.buttons[2].pressed.emit()
	check(v.models[0].lactose_start == 80 and v.models[1].lactose_start == 80, "both people get the same lactose challenge")
	v.on_play_pressed()
	frames(v, 3000)
	check(v.models[0].finished and v.models[1].finished and not v.running, "both previews run to the end")
	check(v.models[0].cleaved == 19 and v.models[1].cleaved == 80, "typical adult splits 19 of 80; persistent adult splits all 80 (%d, %d)" % [v.models[0].cleaved, v.models[1].cleaved])
	check(v.models[0].check_invariants() == "" and v.models[1].check_invariants() == "", "preview counts add up")
	# Supplement: Explain mode only, and it does not touch DNA or expression.
	check(not v.supplement_button.visible, "the supplement is hidden in Explore mode")
	main.app.set_explain(true)
	check(v.supplement_button.visible, "the supplement appears in Explain mode")
	v.supplement_button.button_pressed = true
	check(v.models[0].supplement_count == 10 and v.models[0].enzyme_count == 2, "supplement adds 10 enzymes to the gut; the cell still makes 2")
	check(v.configs[0].variant == RegulationModel.Variant.TYPICAL and near(v.cell_views[0].expression, 0.1), "supplement: same DNA, same LCT use")
	main.app.set_explain(false)
	check(v.models[0].supplement_count == 0, "leaving Explain mode removes the supplement")


func _has_enabled_stepper(node: Node) -> bool:
	if node is Stepper:
		return true
	for child: Node in node.get_children():
		if _has_enabled_stepper(child):
			return true
	return false


func _evidence() -> void:
	var v: Control = await open_view("evidence")
	check(v.zoom == 0 and not v.grid.visible and v.check_button.disabled, "opens on the chromosome; no sequences yet")
	v.zoom_row.buttons[1].pressed.emit()
	check(v.grid.visible and v.grid.rows.size() == 2 and v.grid.region == EvidenceData.Region.CODING, "coding excerpt: one person, two copies")
	check(v.grid.highlights.is_empty() and v.grid.marks.is_empty(), "nothing is highlighted automatically")
	v.compare_button.button_pressed = true
	await process_frame
	check(v.grid.rows.size() == 8, "Compare lines up four people, two copies each")
	v.check_highlighting()
	check(v.result_label.text.contains("no difference"), "coding excerpt with no highlights: matches, no difference")
	v.zoom_row.buttons[2].pressed.emit()
	check(v.grid.region == EvidenceData.Region.UPSTREAM and v.grid.highlights.is_empty(), "upstream excerpt: still nothing highlighted")
	v.check_highlighting()
	check(v.result_label.text.begins_with("Not a match yet") and not v.result_label.text.contains("Alissa"), "an unfinished check does not say where the difference is")
	v.grid.cursor = Vector2i(3, 7)
	v.grid.toggle_at_cursor()
	check(v.result_label.text == "", "changing the highlighting clears the old result")
	v.check_highlighting()
	check(v.result_label.text.begins_with("Matches the lesson data") and v.grid.marks.size() == 1, "highlighting Alissa copy 2, group 4 matches")
	check(not v.result_label.text.contains("regulat") and not v.explain_note.visible, "Explore mode: the check does not explain what the difference means")
	main.app.set_explain(true)
	check(v.explain_note.visible, "Explain mode adds the note that the difference is outside the coding region")
	main.app.set_explain(false)
	v.clear_highlights()
	check(v.grid.highlights.is_empty(), "Clear highlights removes them")
	v.zoom_row.buttons[1].pressed.emit()
	v.grid.cursor = Vector2i(0, 0)
	v.grid.toggle_at_cursor()
	v.zoom_row.buttons[2].pressed.emit()
	check(v.grid.highlights.is_empty(), "highlights are kept separately for each excerpt")


func _population() -> void:
	var v: Control = await open_view("population")
	check(near(v.model_a.p, 0.1) and v.model_a.generation == 0, "starts at generation 0 with allele P at 10%")
	check(not v.model_a.advantage_on(), "default setting: no advantage")
	v.on_step_pressed()
	check(v.model_a.generation == 1 and near(v.model_a.p, 0.1), "no advantage: a generation passes and P stays at 10%")
	var p_before: float = v.model_a.p
	v.context_row.buttons[1].pressed.emit()
	check(v.model_a.p == p_before and v.model_a.generation == 1, "choosing 'fresh milk is important' changes no one: P and the generation are unchanged")
	check(v.model_a.advantage_on() and v.advantage_label.text.contains("ON"), "the advantage is now on, and the panel says so")
	v.on_play_pressed()
	frames(v, 36)
	check(v.running and v.model_a.generation == 2, "Run: one generation every 0.6 s")
	v.on_play_pressed()
	frames(v, 600)
	check(not v.running and v.model_a.generation == 2, "Pause stops the generations")
	v.on_play_pressed()
	frames(v, 600)
	check(not v.running and v.model_a.generation == 12, "Run makes ten generations and stops")
	check(v.model_a.p > p_before, "with the advantage on, P rose (%.3f > %.3f)" % [v.model_a.p, p_before])
	check(v.chart.series.size() == 1 and (v.chart.series[0]["values"] as PackedFloat64Array).size() == 13, "the chart has one point per generation")
	v.metric_row.buttons[1].pressed.emit()
	var shown: PackedFloat64Array = v.chart.series[0]["values"]
	check(near(shown[0], 0.19), "the second chart shows adults who make lactase (19% at the start)")
	v.metric_row.buttons[0].pressed.emit()
	v.on_reset_pressed()
	check(v.model_a.generation == 0 and near(v.model_a.p, 0.1), "Reset returns to generation 0")
	v.compare_button.button_pressed = true
	await process_frame
	check(v.pop_b.visible and near(v.model_b.p, v.model_a.p) and v.model_b.generation == 0, "Compare: setting B starts from the same population")
	v.editing_row.buttons[0].pressed.emit()
	v.context_row.buttons[0].pressed.emit()
	for i: int in range(20):
		v.on_step_pressed()
	check(near(v.model_a.p, 0.1) and v.model_b.p > 0.1, "after 20 generations: A (no milk use) unchanged, B (milk important) higher")
	check(v.chart.series.size() == 2 and bool(v.chart.series[1]["dashed"]) and bool(v.chart.series[1]["square"]), "the chart tells the two runs apart by line style and marker, not only colour")
	v.start_row.buttons[2].pressed.emit()
	check(near(v.model_a.p, 0.3) and near(v.model_b.p, 0.3) and v.model_a.generation == 0, "a new starting share resets both runs")
	main.app.set_reduced_motion(true)
	v.on_play_pressed()
	check(not v.running and v.model_a.generation == 10, "reduced motion: Run shows ten generations at once, with no animation")
	main.app.set_reduced_motion(false)


func _presentation_settings() -> void:
	var v: Control = await open_view("molecules")
	# Reduced motion and labels change the picture only: the model run is identical.
	v.on_play_pressed()
	frames(v, 200)
	var normal: String = v.model_a.digest()
	v.on_reset_pressed()
	main.app.set_reduced_motion(true)
	main.app.set_labels(false)
	main.app.set_explain(true)
	v.on_play_pressed()
	frames(v, 200)
	check(v.model_a.digest() == normal, "reduced motion, labels and mode do not change the model")
	var r: MoleculeRenderer = v.panel_a.renderer
	var free: MoleculeModel.Particle = null
	for p: MoleculeModel.Particle in v.model_a.particles:
		if p.kind == MoleculeModel.Kind.LACTOSE and p.state == MoleculeModel.ParticleState.FREE:
			free = p
			break
	var at: Vector2 = r._particle_px(free, true)
	frames(v, 30)
	check(free.state != MoleculeModel.ParticleState.FREE or r._particle_px(free, true) == at, "reduced motion: free lactose is drawn in a fixed place")
	main.app.set_reduced_motion(false)
	main.app.set_labels(true)
	main.app.set_explain(false)
	v.on_reset_pressed()
	# Text size.
	main.app.set_text_size(1)
	await process_frame
	check(near(main.layout.css_per_px, 1.25) and near(main.layout.view_size.x, 944.0), "Large text: 1.25 CSS px per layout px, layout width 944")
	main.app.set_text_size(2)
	await process_frame
	await process_frame
	check(near(main.layout.css_per_px, 1.5) and main.layout.is_narrow(), "Extra large text: 1.5 CSS px, and the view switches to tabs")
	check(v.tab_row.visible and v.stage_card.visible and not v.controls_card.visible, "tabs: Model shown, Controls hidden")
	v.show_tab(1)
	check(v.controls_card.visible and not v.stage_card.visible, "the Controls tab shows the controls instead")
	main.app.set_text_size(0)
	await process_frame
	await process_frame
	check(not main.layout.is_narrow() and v.stage_card.visible and v.controls_card.visible, "back to Normal: both panels side by side")


func _layouts() -> void:
	# [name, window (device px), device pixel ratio]
	var cases: Array = [
		["iframe 1180x500", Vector2i(1180, 500), 1.0],
		["iframe 1180x500 at ratio 1.5", Vector2i(1770, 750), 1.5],
		["iframe 1180x360", Vector2i(1180, 360), 1.0],
		["200% zoom 590x250 at ratio 2", Vector2i(1180, 500), 2.0],
		["phone 380x640 at ratio 2", Vector2i(760, 1280), 2.0],
		["Chromebook tab 1366x768", Vector2i(1366, 768), 1.0],
	]
	for case: Array in cases:
		var label: String = case[0]
		var dpr: float = case[2]
		await resize(case[1], dpr)
		var problems: PackedStringArray = PackedStringArray()
		if main.layout.css_per_px < 0.8499:
			problems.append("text below 0.85 CSS px")
		for id: String in VIEWS:
			var view: Control = await open_view(id)
			for tab: int in range(2):
				if view.has_method("show_tab"):
					view.show_tab(tab)
					await process_frame
					await process_frame
				var ring: Array[Control] = main.nav.current_ring()
				if ring.size() < 5:
					problems.append("%s: only %d controls reachable" % [id, ring.size()])
				var corner: Rect2 = Rect2(main.layout.view_size.x - main.layout.reserved_corner().x, 0.0, main.layout.reserved_corner().x, main.layout.reserved_corner().y)
				for c: Control in ring:
					var css: Vector2 = c.size * main.layout.css_per_px
					if css.x < 43.5 or css.y < 43.5:
						problems.append("%s: a control is %.0f x %.0f CSS px" % [id, css.x, css.y])
					var rect: Rect2 = c.get_global_rect()
					if rect.intersects(corner):
						problems.append("%s: a control is under the full-screen button" % id)
					if rect.position.x < -0.5 or rect.end.x > main.layout.view_size.x + 0.5:
						problems.append("%s: a control runs off the side (%.0f to %.0f of %.0f)" % [id, rect.position.x, rect.end.x, main.layout.view_size.x])
				if not main.layout.is_narrow() or not view.has_method("show_tab"):
					break
		check(problems.is_empty(), "%s: all views usable (%s)" % [label, "; ".join(problems.slice(0, 14))])
	await resize(Vector2i(1180, 500), 1.0)
