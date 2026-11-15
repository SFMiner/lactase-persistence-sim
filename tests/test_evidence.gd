extends "res://tests/test_base.gd"
## Evidence Viewer data (GDD 6.2 and acceptance test 5): the lesson's exact sequences.
## The expected strings are typed out again here on purpose, so a slip in the data file fails.
## Run:  Godot --headless --path . --script tests/test_evidence.gd

const EXPECTED: int = 22

const R := EvidenceData.Region


func _init() -> void:
	test_name = "test_evidence"
	_run.call_deferred()


func _run() -> void:
	check(EvidenceData.NAMES == ["Kanna", "Kanna's mother", "Kanna's baby brother", "Alissa"], "the four people are Kanna, her mother, her baby brother and Alissa")
	check(EvidenceData.PERSON_COUNT == 4 and EvidenceData.COPY_COUNT == 2, "four people, two copies each")
	# LCT coding excerpt: identical in all eight copies.
	var coding_same: bool = true
	for person: int in range(4):
		for copy: int in range(2):
			if EvidenceData.sequence(person, R.CODING, copy) != "ATA-AAG-GAC-ACT-CTT-GAC-AA":
				coding_same = false
	check(coding_same, "all eight LCT coding copies read ATA-AAG-GAC-ACT-CTT-GAC-AA")
	check(EvidenceData.differences(R.CODING).is_empty(), "the coding excerpt has no differences")
	# Upstream excerpt.
	var typical: String = "TTA-CGG-TAA-ATT-AAT-GCC-AA"
	check(EvidenceData.sequence(EvidenceData.KANNA, R.UPSTREAM, 0) == typical and EvidenceData.sequence(EvidenceData.KANNA, R.UPSTREAM, 1) == typical, "Kanna: both upstream copies typical")
	check(EvidenceData.sequence(EvidenceData.MOTHER, R.UPSTREAM, 0) == typical and EvidenceData.sequence(EvidenceData.MOTHER, R.UPSTREAM, 1) == typical, "Kanna's mother: both upstream copies typical")
	check(EvidenceData.sequence(EvidenceData.BROTHER, R.UPSTREAM, 0) == typical and EvidenceData.sequence(EvidenceData.BROTHER, R.UPSTREAM, 1) == typical, "Kanna's baby brother: both upstream copies typical")
	check(EvidenceData.sequence(EvidenceData.ALISSA, R.UPSTREAM, 0) == typical, "Alissa copy 1: typical")
	check(EvidenceData.sequence(EvidenceData.ALISSA, R.UPSTREAM, 1) == "TTA-CGG-TAA-ACT-AAT-GCC-AA", "Alissa copy 2: TTA-CGG-TAA-ACT-AAT-GCC-AA")
	var diffs: Array[int] = EvidenceData.differences(R.UPSTREAM)
	var alissa_cell: int = EvidenceData.cell_key(EvidenceData.ALISSA, 1, 3)
	check(diffs.size() == 1 and diffs[0] == alissa_cell, "exactly one cell differs: Alissa, copy 2, group 4")
	check(EvidenceData.groups(EvidenceData.UPSTREAM_TYPICAL)[3] == "ATT" and EvidenceData.groups(EvidenceData.UPSTREAM_VARIANT)[3] == "ACT", "the change is ATT -> ACT")
	var letters: int = 0
	for i: int in range(typical.length()):
		if EvidenceData.UPSTREAM_TYPICAL[i] != EvidenceData.UPSTREAM_VARIANT[i]:
			letters += 1
	check(letters == 1, "one letter differs between the two upstream excerpts")
	check(EvidenceData.group_count(R.CODING) == 7 and EvidenceData.group_count(R.UPSTREAM) == 7, "seven groups in each excerpt")
	var keys: Dictionary = {}
	for person: int in range(4):
		for copy: int in range(2):
			for g: int in range(7):
				keys[EvidenceData.cell_key(person, copy, g)] = true
	check(keys.size() == 56, "every table cell has its own key")
	# Check highlighting: says only whether the highlights match.
	var exact: Dictionary = EvidenceData.check_highlights(R.UPSTREAM, [alissa_cell])
	check(bool(exact["exact"]) and exact["right"] == [alissa_cell] and int(exact["missed"]) == 0, "highlighting only Alissa's changed group matches")
	var none: Dictionary = EvidenceData.check_highlights(R.UPSTREAM, [])
	check(not bool(none["exact"]) and int(none["missed"]) == 1, "no highlight on the upstream excerpt: one difference missed")
	var wrong_cell: int = EvidenceData.cell_key(EvidenceData.KANNA, 0, 3)
	var wrong: Dictionary = EvidenceData.check_highlights(R.UPSTREAM, [wrong_cell])
	check(not bool(wrong["exact"]) and wrong["wrong"] == [wrong_cell] and int(wrong["missed"]) == 1, "highlighting Kanna's group is marked as not a difference")
	var both: Dictionary = EvidenceData.check_highlights(R.UPSTREAM, [alissa_cell, wrong_cell])
	check(not bool(both["exact"]) and both["right"] == [alissa_cell] and both["wrong"] == [wrong_cell], "a right and a wrong highlight are told apart")
	var coding_none: Dictionary = EvidenceData.check_highlights(R.CODING, [])
	check(bool(coding_none["exact"]), "no highlight on the coding excerpt matches (there is no difference)")
	var coding_any: Dictionary = EvidenceData.check_highlights(R.CODING, [alissa_cell])
	check(not bool(coding_any["exact"]) and coding_any["wrong"] == [alissa_cell], "any highlight on the coding excerpt is not a difference")
	# The viewer's data and the regulation model use the same excerpts.
	check(RegulationModel.coding_sequence() == EvidenceData.CODING, "DNA & Lactase uses the same coding excerpt")
	check(RegulationModel.regulatory_sequence(RegulationModel.Variant.PERSISTENT) == EvidenceData.UPSTREAM_VARIANT, "DNA & Lactase uses the same variant excerpt")
	finish(EXPECTED)
