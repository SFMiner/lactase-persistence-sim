class_name PopulationModel
extends RefCounted
## Population change across generations (GDD section 7.3).
##
## One locus, two alleles: P (persistence-associated regulatory variant) and n. P is dominant for
## adult persistence in this teaching model. Each generation: newborn genotype shares come from
## the allele frequency (Hardy-Weinberg, used only as the mating approximation), each genotype is
## weighted by its relative reproductive success in the chosen setting, and the allele frequency of
## the next generation is read from the weighted shares.
##
## Nothing here changes any individual's genotype, and there is no mutation: the only thing that
## moves the allele frequency is a new generation. The weights are illustrative, not historical.

# === CONSTANTS ===
enum Context { LITTLE_MILK, MILK_IMPORTANT }
enum Strength { NONE, MILD, STRONG }

const INITIAL_CHOICES: Array[float] = [0.01, 0.10, 0.30]
const INITIAL_NAMES: Array[String] = ["1%", "10%", "30%"]
const CONTEXT_NAMES: Array[String] = ["Little or no fresh milk used", "Fresh milk is an important food"]
const STRENGTH_NAMES: Array[String] = ["None", "Mild", "Strong"]
## Relative reproductive success of adults who digest lactose, when it is an advantage.
const ADVANTAGE: Array[float] = [1.0, 1.05, 1.20]


# === PUBLIC VARIABLES ===
var p_start: float = 0.10
## Frequency of allele P among the newborns of the current generation.
var p: float = 0.10
var generation: int = 0
var context: int = Context.LITTLE_MILK
var strength: int = Strength.MILD
## Allele frequency at each generation, starting with generation 0.
var history_p: PackedFloat64Array = PackedFloat64Array()
## Share of adults who keep making lactase (PP + Pn) at each generation.
var history_phenotype: PackedFloat64Array = PackedFloat64Array()
## Generations at which the setting was changed, for marks on the chart.
var change_marks: PackedInt32Array = PackedInt32Array()


# === PUBLIC METHODS ===
func _init() -> void:
	reset(p_start)


## Starts again from generation 0 with this allele frequency. The setting is kept.
func reset(start_frequency: float) -> void:
	p_start = clampf(start_frequency, 0.0, 1.0)
	p = p_start
	generation = 0
	history_p = PackedFloat64Array([p])
	history_phenotype = PackedFloat64Array([phenotype_share(p)])
	change_marks = PackedInt32Array()


## Changes the setting for the generations still to come. The current population is untouched.
func set_conditions(new_context: int, new_strength: int) -> void:
	var c: int = clampi(new_context, 0, 1)
	var s: int = clampi(new_strength, 0, 2)
	if c == context and s == strength:
		return
	context = c
	strength = s
	if generation > 0:
		change_marks.append(generation)


## True when digesting lactose as an adult raises reproductive success in the current setting.
func advantage_on() -> bool:
	return context == Context.MILK_IMPORTANT and strength != Strength.NONE


## Relative reproductive weights (w_PP, w_Pn, w_nn).
static func weights(for_context: int, for_strength: int) -> Vector3:
	if for_context != Context.MILK_IMPORTANT:
		return Vector3(1.0, 1.0, 1.0)
	var w: float = ADVANTAGE[clampi(for_strength, 0, 2)]
	return Vector3(w, w, 1.0)


## Newborn genotype shares (PP, Pn, nn) for an allele frequency.
static func genotype_shares(freq: float) -> Vector3:
	var q: float = 1.0 - freq
	return Vector3(freq * freq, 2.0 * freq * q, q * q)


## Share of adults who keep making lactase: PP + Pn. Not the same number as the allele frequency.
static func phenotype_share(freq: float) -> float:
	var g: Vector3 = genotype_shares(freq)
	return g.x + g.y


## Genotype shares among the parents of the next generation, after weighting.
static func selected_shares(freq: float, w: Vector3) -> Vector3:
	var g: Vector3 = genotype_shares(freq)
	var weighted: Vector3 = Vector3(g.x * w.x, g.y * w.y, g.z * w.z)
	var total: float = weighted.x + weighted.y + weighted.z
	if total <= 0.0:
		return g
	return weighted / total


## The allele frequency one generation later.
static func next_frequency(freq: float, w: Vector3) -> float:
	var s: Vector3 = selected_shares(freq, w)
	return clampf(s.x + 0.5 * s.y, 0.0, 1.0)


## Moves to the next generation. This is the only method that changes the allele frequency.
func step_generation() -> void:
	p = next_frequency(p, weights(context, strength))
	generation += 1
	history_p.append(p)
	history_phenotype.append(phenotype_share(p))


## Whole-number genotype counts [PP, Pn, nn] for `n` pictured newborns (largest remainders, so the
## counts always add up to n).
static func avatar_counts(freq: float, n: int) -> Array[int]:
	var g: Vector3 = genotype_shares(freq)
	var exact: Array[float] = [g.x * float(n), g.y * float(n), g.z * float(n)]
	var counts: Array[int] = [int(floor(exact[0])), int(floor(exact[1])), int(floor(exact[2]))]
	var left: int = n - counts[0] - counts[1] - counts[2]
	while left > 0:
		var best: int = 0
		var best_frac: float = -1.0
		for i: int in range(3):
			var frac: float = exact[i] - float(counts[i])
			if frac > best_frac:
				best_frac = frac
				best = i
		counts[best] += 1
		exact[best] = float(counts[best])
		left -= 1
	return counts
