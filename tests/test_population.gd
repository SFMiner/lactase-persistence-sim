extends "res://tests/test_base.gd"
## Module C mathematical invariants (GDD 7.3 and acceptance tests 6-7), on the pure model.
## Run:  Godot --headless --path . --script tests/test_population.gd

const EXPECTED: int = 27

const CTX := PopulationModel.Context
const STR := PopulationModel.Strength


func _init() -> void:
	test_name = "test_population"
	_run.call_deferred()


func model(start: float, context: int, strength: int) -> PopulationModel:
	var m: PopulationModel = PopulationModel.new()
	m.reset(start)
	m.set_conditions(context, strength)
	return m


func run(m: PopulationModel, generations: int) -> void:
	for i: int in range(generations):
		m.step_generation()


func _run() -> void:
	# Weights.
	check(PopulationModel.weights(CTX.MILK_IMPORTANT, STR.MILD) == [1.05, 1.05, 1.0], "mild advantage weights are 1.05, 1.05, 1.00")
	check(PopulationModel.weights(CTX.MILK_IMPORTANT, STR.STRONG) == [1.2, 1.2, 1.0], "strong advantage weights are 1.20, 1.20, 1.00")
	check(PopulationModel.weights(CTX.MILK_IMPORTANT, STR.NONE) == [1.0, 1.0, 1.0], "no advantage: all weights 1.00")
	check(PopulationModel.weights(CTX.LITTLE_MILK, STR.STRONG) == [1.0, 1.0, 1.0], "where fresh milk is not used, the variant gives no advantage")
	# Neutral: allele frequency is constant.
	var neutral_ok: bool = true
	for setting: Array in [[CTX.LITTLE_MILK, STR.NONE], [CTX.LITTLE_MILK, STR.STRONG], [CTX.MILK_IMPORTANT, STR.NONE]]:
		for start: float in [0.01, 0.1, 0.3, 0.77]:
			var m: PopulationModel = model(start, setting[0], setting[1])
			run(m, 200)
			if m.p != start:
				neutral_ok = false
	check(neutral_ok, "with no advantage the allele frequency stays the same for 200 generations")
	# Fixed endpoints: no mutation.
	var zero: PopulationModel = model(0.0, CTX.MILK_IMPORTANT, STR.STRONG)
	run(zero, 500)
	check(zero.p == 0.0, "p = 0 stays 0: allele P never appears from nothing")
	check(PopulationModel.phenotype_share(zero.p) == 0.0, "p = 0: no adults make lactase")
	var one: PopulationModel = model(1.0, CTX.MILK_IMPORTANT, STR.STRONG)
	run(one, 500)
	check(one.p == 1.0, "p = 1 stays 1")
	# Selection favouring P raises p at every interior frequency.
	var rises: bool = true
	var bounded: bool = true
	for strength: int in [STR.MILD, STR.STRONG]:
		for start: float in [0.01, 0.1, 0.3, 0.6, 0.95]:
			var m: PopulationModel = model(start, CTX.MILK_IMPORTANT, strength)
			var last: float = m.p
			for i: int in range(300):
				m.step_generation()
				if m.p <= last and last < 0.999999:
					rises = false
				if m.p < 0.0 or m.p > 1.0:
					bounded = false
				last = m.p
	check(rises, "with an advantage, p rises every generation from any interior start")
	check(bounded, "p always stays between 0 and 1")
	var mild: PopulationModel = model(0.1, CTX.MILK_IMPORTANT, STR.MILD)
	var strong: PopulationModel = model(0.1, CTX.MILK_IMPORTANT, STR.STRONG)
	run(mild, 20)
	run(strong, 20)
	check(strong.p > mild.p and mild.p > 0.1, "a strong advantage raises p faster than a mild one (%.3f > %.3f > 0.100)" % [strong.p, mild.p])
	# One generation by hand: p = 0.1, strong. PP .012, Pn .216, nn .81; W = 1.038.
	check(near(PopulationModel.next_frequency(0.1, [1.2, 1.2, 1.0]), (0.012 + 0.108) / 1.038, 0.0000001), "one generation matches the formula worked by hand")
	# Shares sum to 1.
	var sums_ok: bool = true
	var selected_ok: bool = true
	var avatars_ok: bool = true
	for i: int in range(0, 101):
		var f: float = float(i) / 100.0
		var g: Array[float] = PopulationModel.genotype_shares(f)
		if not near(g[0] + g[1] + g[2], 1.0, 0.000000001):
			sums_ok = false
		var s: Array[float] = PopulationModel.selected_shares(f, [1.2, 1.2, 1.0])
		if not near(s[0] + s[1] + s[2], 1.0, 0.000000001):
			selected_ok = false
		for n: int in [50, 100]:
			var c: Array[int] = PopulationModel.avatar_counts(f, n)
			if c[0] + c[1] + c[2] != n or c[0] < 0 or c[1] < 0 or c[2] < 0:
				avatars_ok = false
	check(sums_ok, "newborn genotype shares always sum to 1")
	check(selected_ok, "weighted genotype shares always sum to 1")
	check(avatars_ok, "pictured genotype counts always add up to the number of people pictured")
	# Phenotype is not the same number as allele frequency.
	check(near(PopulationModel.phenotype_share(0.1), 0.19), "p = 10%: 19% of adults make lactase (PP + Pn)")
	check(near(PopulationModel.phenotype_share(0.3), 0.51), "p = 30%: 51% of adults make lactase")
	check(PopulationModel.avatar_counts(0.1, 100) == [1, 18, 81], "p = 10%: 1 PP, 18 Pn, 81 nn per 100 newborns")
	# Acceptance 7: a choice changes nothing until a new generation is made.
	var m2: PopulationModel = model(0.1, CTX.LITTLE_MILK, STR.NONE)
	run(m2, 5)
	var p_before: float = m2.p
	var gen_before: int = m2.generation
	var history_before: int = m2.history_p.size()
	m2.set_conditions(CTX.MILK_IMPORTANT, STR.STRONG)
	check(m2.p == p_before and m2.generation == gen_before and m2.history_p.size() == history_before,
		"changing the setting does not change the allele frequency or the generation")
	check(m2.change_marks.size() == 1 and m2.change_marks[0] == 5, "the change of setting is marked at generation 5")
	m2.step_generation()
	check(m2.p > p_before and m2.generation == gen_before + 1, "the new setting acts only through the next generation")
	# History and reset.
	check(m2.history_p.size() == m2.generation + 1 and m2.history_phenotype.size() == m2.generation + 1, "one history point per generation")
	check(near(m2.history_p[0], 0.1), "history starts at the starting frequency")
	m2.reset(0.3)
	check(m2.generation == 0 and near(m2.p, 0.3) and m2.history_p.size() == 1 and m2.change_marks.size() == 0, "reset returns to generation 0")
	check(m2.context == CTX.MILK_IMPORTANT and m2.strength == STR.STRONG, "reset keeps the chosen setting")
	# No forced endpoint: with a mild advantage p is still below 1 after 100 generations.
	var slow: PopulationModel = model(0.01, CTX.MILK_IMPORTANT, STR.MILD)
	run(slow, 100)
	check(slow.p > 0.01 and slow.p < 1.0, "no forced endpoint: 1%% start, mild advantage, 100 generations gives %.1f%%" % (slow.p * 100.0))
	check(model(0.1, CTX.MILK_IMPORTANT, STR.MILD).advantage_on() and not model(0.1, CTX.LITTLE_MILK, STR.MILD).advantage_on(), "advantage is on only where fresh milk matters")
	finish(EXPECTED)
