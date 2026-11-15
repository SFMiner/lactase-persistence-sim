extends "res://tests/test_base.gd"
## Module B science rules (GDD 5 and acceptance test 4), on the pure model with no scene.
## Run:  Godot --headless --path . --script tests/test_regulation.gd

const EXPECTED: int = 26

const S := RegulationModel.Stage
const V := RegulationModel.Variant
const C := RegulationModel.CellType


func _init() -> void:
	test_name = "test_regulation"
	_run.call_deferred()


func cfg(stage: int, variant: int, cell: int = C.INTESTINE, challenge: int = 1, supplement: bool = false) -> RegulationModel.Config:
	var c: RegulationModel.Config = RegulationModel.Config.new()
	c.stage = stage
	c.variant = variant
	c.cell = cell
	c.challenge = challenge
	c.supplement = supplement
	return c


func digest(c: RegulationModel.Config) -> MoleculeModel:
	var m: MoleculeModel = RegulationModel.build_digestion(c, 7)
	m.run_to_end()
	return m


func _run() -> void:
	# The GDD's illustrative mapping.
	check(near(RegulationModel.expression(V.TYPICAL, S.INFANT, C.INTESTINE), 1.0), "infant, typical: 1.0")
	check(near(RegulationModel.expression(V.TYPICAL, S.ADULT, C.INTESTINE), 0.1), "adult, typical: 0.1")
	check(near(RegulationModel.expression(V.PERSISTENT, S.INFANT, C.INTESTINE), 1.0), "infant, persistence variant: 1.0")
	check(near(RegulationModel.expression(V.PERSISTENT, S.ADULT, C.INTESTINE), 0.9), "adult, persistence variant: 0.9")
	var muscle_all_zero: bool = true
	for variant: int in [V.TYPICAL, V.PERSISTENT]:
		for stage: int in [S.INFANT, S.CHILD, S.ADULT]:
			if RegulationModel.expression(variant, stage, C.MUSCLE) != 0.0:
				muscle_all_zero = false
	check(muscle_all_zero, "muscle cell: 0.0 for every stage and variant")
	# Acceptance 4: age-dependent expression.
	check(RegulationModel.expression(V.TYPICAL, S.INFANT, C.INTESTINE) == RegulationModel.expression(V.PERSISTENT, S.INFANT, C.INTESTINE),
		"infants make the same lactase whichever regulatory DNA they inherited")
	check(RegulationModel.expression(V.TYPICAL, S.ADULT, C.INTESTINE) < RegulationModel.expression(V.TYPICAL, S.INFANT, C.INTESTINE),
		"typical regulation: adult expression is lower than infant expression")
	check(RegulationModel.expression(V.TYPICAL, S.ADULT, C.INTESTINE) > 0.0, "typical adult expression is reduced, not switched fully off")
	check(RegulationModel.expression(V.PERSISTENT, S.ADULT, C.INTESTINE) > RegulationModel.expression(V.TYPICAL, S.ADULT, C.INTESTINE),
		"adult with the persistence variant makes more lactase than a typical adult")
	var child: float = RegulationModel.expression(V.TYPICAL, S.CHILD, C.INTESTINE)
	check(child < 1.0 and child > 0.1, "typical child is between infant and adult")
	# Expression -> lactase amount, in the Molecules view's units.
	check(RegulationModel.enzyme_count(1.0) == 20 and RegulationModel.enzyme_count(0.9) == 18, "high expression maps to 20 and 18 lactase")
	check(RegulationModel.enzyme_count(0.1) == 2 and RegulationModel.enzyme_count(0.0) == 0, "low expression maps to 2 lactase, none to 0")
	check(RegulationModel.expression_word(1.0) == "high" and RegulationModel.expression_word(0.1) == "low" and RegulationModel.expression_word(0.0) == "off",
		"expression has a word as well as a bar")
	# Coding versus regulatory DNA.
	check(RegulationModel.coding_sequence() == "ATA-AAG-GAC-ACT-CTT-GAC-AA", "the coding excerpt is the lesson's, and takes no variant")
	var typical: String = RegulationModel.regulatory_sequence(V.TYPICAL)
	var persistent: String = RegulationModel.regulatory_sequence(V.PERSISTENT)
	var diffs: int = 0
	for i: int in range(typical.length()):
		if typical[i] != persistent[i]:
			diffs += 1
	check(typical.length() == persistent.length() and diffs == 1, "the two regulatory excerpts differ by exactly one letter")
	check(DnaRenderer.coding_text(1000.0, 11) == RegulationModel.coding_sequence(), "the DNA picture writes the same coding text for every scenario")
	# The digestion preview is the Molecules model, fed by this model.
	var adult_typical: MoleculeModel = digest(cfg(S.ADULT, V.TYPICAL))
	var adult_persistent: MoleculeModel = digest(cfg(S.ADULT, V.PERSISTENT))
	var infant_typical: MoleculeModel = digest(cfg(S.INFANT, V.TYPICAL))
	var infant_persistent: MoleculeModel = digest(cfg(S.INFANT, V.PERSISTENT))
	check(adult_typical.enzyme_count == 2 and adult_persistent.enzyme_count == 18, "preview lactase comes from the regulation model (2 and 18)")
	check(adult_typical.cleaved < adult_persistent.cleaved, "typical adult splits less lactose than a persistent adult (%d < %d)" % [adult_typical.cleaved, adult_persistent.cleaved])
	check(adult_typical.cleaved > 0, "a typical adult still splits some lactose")
	check(infant_typical.digest() == infant_persistent.digest(), "the two infants digest identically")
	var muscle: MoleculeModel = digest(cfg(S.INFANT, V.PERSISTENT, C.MUSCLE))
	check(muscle.cleaved == 0 and muscle.glucose_formed == 0, "a muscle cell makes no lactase, so nothing is split")
	check(adult_typical.check_invariants() == "" and adult_persistent.check_invariants() == "", "preview counts add up")
	# The supplement adds enzyme to the gut; it changes neither DNA nor expression.
	var plain: RegulationModel.Config = cfg(S.ADULT, V.TYPICAL)
	var helped: RegulationModel.Config = cfg(S.ADULT, V.TYPICAL, C.INTESTINE, 1, true)
	check(RegulationModel.expression_of(helped) == RegulationModel.expression_of(plain) and helped.variant == plain.variant,
		"a supplement leaves LCT expression and the inherited variant unchanged")
	var helped_run: MoleculeModel = digest(helped)
	check(helped_run.enzyme_count == 2 and helped_run.supplement_count == 10, "supplement enzyme is separate from the cell's own lactase")
	check(helped_run.cleaved > adult_typical.cleaved, "with a supplement more lactose is split")
	# Growing older does not edit DNA: the variant is untouched by a change of stage.
	var person: RegulationModel.Config = cfg(S.INFANT, V.TYPICAL)
	var before: String = RegulationModel.regulatory_sequence(person.variant)
	person.stage = S.ADULT
	check(RegulationModel.regulatory_sequence(person.variant) == before, "changing life stage leaves the regulatory DNA as it was")
	finish(EXPECTED)
