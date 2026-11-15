extends "res://tests/test_base.gd"
## Module A science rules (GDD 4.4 and acceptance tests 1-3), on the pure model with no scene.
## Run:  Godot --headless --path . --script tests/test_molecules.gd

const EXPECTED: int = 43


func _init() -> void:
	test_name = "test_molecules"
	_run.call_deferred()


func model(lactose: int, enzymes: int, run_seed: int = 7, supplement: int = 0) -> MoleculeModel:
	var m: MoleculeModel = MoleculeModel.new()
	m.setup(lactose, enzymes, run_seed, supplement)
	return m


func _run() -> void:
	_zero_lactase()
	_accounting()
	_monotonic()
	_replay()
	_limits()
	_enzyme_unchanged()
	_supplement()
	_stepping()
	finish(EXPECTED)


## Acceptance 1: no lactase, no products, whatever the lactose.
func _zero_lactase() -> void:
	for lactose: int in [1, 50, 100]:
		var m: MoleculeModel = model(lactose, 0)
		m.run_to_end()
		check(m.glucose_formed == 0 and m.galactose_formed == 0, "zero lactase, %d lactose: no glucose or galactose" % lactose)
		check(m.lactose_remaining == lactose and m.cleaved == 0, "zero lactase, %d lactose: all lactose still whole" % lactose)
	var none: MoleculeModel = model(50, 0)
	none.run_to_end()
	check(none.glucose_absorbed == 0 and none.galactose_absorbed == 0 and none.lactose_absorbed == 0, "zero lactase: nothing is absorbed")
	check(none.tick_count == MoleculeModel.PERIOD_TICKS, "zero lactase: the run lasts the whole period")


## Acceptance 2: each cleavage is exactly 1 lactose -> 1 glucose + 1 galactose; enzymes remain.
func _accounting() -> void:
	var m: MoleculeModel = model(50, 8)
	var broken: int = 0
	var bad_steps: int = 0
	var enzyme_changes: int = 0
	var products_without_cleavage: int = 0
	while not m.finished:
		var before_l: int = m.lactose_remaining
		var before_g: int = m.glucose_formed
		var before_ga: int = m.galactose_formed
		var before_c: int = m.cleaved
		m.tick()
		if m.check_invariants() != "":
			broken += 1
		var dc: int = m.cleaved - before_c
		if before_l - m.lactose_remaining != dc or m.glucose_formed - before_g != dc or m.galactose_formed - before_ga != dc:
			bad_steps += 1
		if dc == 0 and (m.glucose_formed != before_g or m.galactose_formed != before_ga):
			products_without_cleavage += 1
		if m.total_enzymes() != 8:
			enzyme_changes += 1
	check(broken == 0, "counts add up on every tick (%d broken)" % broken)
	check(bad_steps == 0, "every cleavage is -1 lactose, +1 glucose, +1 galactose (%d bad ticks)" % bad_steps)
	check(products_without_cleavage == 0, "no product appears without a cleavage")
	check(enzyme_changes == 0, "the number of lactase enzymes never changes during a run")
	check(m.cleaved == 50 and m.lactose_remaining == 0, "8 lactase split all 50 lactose in the period")
	check(m.glucose_formed == 50 and m.galactose_formed == 50, "50 cleavages gave 50 glucose and 50 galactose")
	check(m.glucose_absorbed == 50 and m.galactose_absorbed == 50, "all products were absorbed by the end")
	check(m.lactose_absorbed == 0, "intact lactose was never absorbed")
	var reuse: int = 0
	for e: MoleculeModel.Enzyme in m.enzymes:
		if e.turnovers > 1:
			reuse += 1
	check(reuse == 8, "every enzyme was reused (more than one lactose each)")


## Acceptance 3: more lactase never means less conversion, at the end and part-way.
func _monotonic() -> void:
	for lactose: int in [20, 50, 100]:
		var last_end: int = -1
		var last_mid: int = -1
		var ok_end: bool = true
		var ok_mid: bool = true
		for enzymes: int in range(0, MoleculeModel.MAX_ENZYMES + 1):
			var m: MoleculeModel = model(lactose, enzymes)
			for i: int in range(150):
				m.tick()
			if m.cleaved < last_mid:
				ok_mid = false
			last_mid = m.cleaved
			m.run_to_end()
			if m.cleaved < last_end:
				ok_end = false
			last_end = m.cleaved
		check(ok_end, "lactose %d: conversion at the end never falls as lactase rises" % lactose)
		check(ok_mid, "lactose %d: conversion after 5 s never falls as lactase rises" % lactose)
	var few: MoleculeModel = model(100, 2)
	var many: MoleculeModel = model(100, 8)
	few.run_to_end()
	many.run_to_end()
	check(few.cleaved < many.cleaved, "with plenty of lactose, 2 lactase split fewer than 8 (%d < %d)" % [few.cleaved, many.cleaved])
	check(few.lactose_remaining > 0, "2 lactase leave lactose undigested when time runs out")


## GDD 4.4: replay after Reset with the same seed and settings is the same run.
func _replay() -> void:
	var a: MoleculeModel = model(50, 8, 7)
	var b: MoleculeModel = model(50, 8, 7)
	for i: int in range(120):
		a.tick()
		b.tick()
	check(a.digest() == b.digest(), "same seed and settings: identical state after 120 ticks")
	a.run_to_end()
	b.run_to_end()
	check(a.digest() == b.digest(), "same seed and settings: identical state at the end")
	# Frame timing must not matter: 60 fps and 24 fps reach the same state at the same tick.
	var fast: MoleculeModel = model(50, 8, 7)
	var slow: MoleculeModel = model(50, 8, 7)
	while fast.tick_count < 200:
		fast.advance(1.0 / 60.0)
	while slow.tick_count < 200:
		slow.advance(1.0 / 24.0)
	while fast.tick_count < slow.tick_count:
		fast.tick()
	check(fast.digest() == slow.digest(), "frame rate does not change the run")
	var other: MoleculeModel = model(50, 8, 8)
	other.run_to_end()
	check(other.cleaved == a.cleaved, "a different seed changes positions, not how much is split")
	var start_a: MoleculeModel = model(50, 2, 7)
	var start_b: MoleculeModel = model(50, 14, 7)
	var same_start: bool = true
	for i: int in range(50):
		if start_a.particles[i].pos != start_b.particles[i].pos:
			same_start = false
	check(same_start, "the same seed gives the same starting lactose whatever the lactase")


func _limits() -> void:
	var m: MoleculeModel = model(5, 20)
	m.run_to_end()
	check(m.cleaved == 5 and m.glucose_formed == 5, "5 lactose with 20 lactase: exactly 5 cleavages (substrate is the limit)")
	check(m.tick_count < MoleculeModel.PERIOD_TICKS, "the run ends early once everything is split and absorbed")
	var big: MoleculeModel = model(500, 99)
	check(big.lactose_start == MoleculeModel.MAX_LACTOSE and big.enzyme_count == MoleculeModel.MAX_ENZYMES, "settings are clamped to the model's limits")
	var empty: MoleculeModel = model(0, 8)
	check(empty.finished and empty.glucose_formed == 0, "no lactose: nothing to do, no products")


## Less lactase changes the amount digested, not how each remaining enzyme works.
func _enzyme_unchanged() -> void:
	var few: MoleculeModel = model(100, 2)
	var many: MoleculeModel = model(100, 6)
	for i: int in range(300):
		few.tick()
		many.tick()
	check(few.enzymes[0].turnovers == many.enzymes[0].turnovers and few.enzymes[1].turnovers == many.enzymes[1].turnovers,
		"an enzyme works at the same rate whether there are 2 or 6 of them")
	check(many.cleaved > 2 * few.cleaved, "three times the enzyme splits more lactose in the same time")


func _supplement() -> void:
	var plain: MoleculeModel = model(50, 2)
	var helped: MoleculeModel = model(50, 2, 7, 10)
	check(helped.total_enzymes() == 12 and helped.enzyme_count == 2, "a supplement adds enzyme to the gut contents, not to the lining")
	var flagged: int = 0
	for e: MoleculeModel.Enzyme in helped.enzymes:
		if e.supplement:
			flagged += 1
	check(flagged == 10, "supplement enzymes are marked as supplement")
	plain.run_to_end()
	helped.run_to_end()
	check(helped.cleaved > plain.cleaved, "supplement lactase splits more lactose (%d > %d)" % [helped.cleaved, plain.cleaved])
	check(helped.check_invariants() == "", "counts still add up with a supplement")


func _stepping() -> void:
	var m: MoleculeModel = model(50, 8)
	var before: int = m.event_serial
	m.step_event()
	check(m.event_serial == before + 1 or m.tick_count == 30, "Step stops at the next enzyme event")
	var none: MoleculeModel = model(50, 0)
	none.step_event()
	check(none.tick_count == 30, "Step with no events moves one second")
	check(m.summary()["enzymes_start"] == m.summary()["enzymes_now"], "the summary reports the same lactase before and after")
