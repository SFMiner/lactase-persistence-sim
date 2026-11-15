class_name RegulationModel
extends RefCounted
## Gene regulation across life stages (GDD section 5).
##
## The chain is: inherited regulatory DNA + life stage + cell type -> LCT expression -> amount of
## lactase -> the same digestion model used by the Molecules view (MoleculeModel).
## The coding sequence is the same for every scenario; only the regulatory DNA differs, and it
## is inherited: nothing in this model edits DNA during a lifetime.
## The expression values are illustrative teaching constants, not measured enzyme levels.

# === CONSTANTS ===
enum Stage { INFANT, CHILD, ADULT }
enum Variant { TYPICAL, PERSISTENT }
enum CellType { INTESTINE, MUSCLE }

## Relative LCT expression in a small-intestine cell, by regulatory DNA and life stage.
## Infant and adult values are the GDD's; the child values are an added in-between step.
const EXPRESSION_TYPICAL: Array[float] = [1.0, 0.5, 0.1]
const EXPRESSION_PERSISTENT: Array[float] = [1.0, 0.95, 0.9]
## Cells outside the small intestine do not make lactase in this model.
const EXPRESSION_MUSCLE: float = 0.0
## Lactose in the digestion preview for the Low / Medium / High challenge (model units).
const CHALLENGE_LACTOSE: Array[int] = [20, 50, 80]
## Extra enzyme a supplement adds to the gut contents (model units). It changes no DNA.
const SUPPLEMENT_ENZYMES: int = 10

const STAGE_NAMES: Array[String] = ["Infant", "Child", "Adult"]
const VARIANT_NAMES: Array[String] = ["Typical decline", "Persistence variant"]
const CELL_NAMES: Array[String] = ["Intestine cell", "Muscle cell"]
const CHALLENGE_NAMES: Array[String] = ["Low", "Medium", "High"]


# === INNER CLASSES ===
## One scenario: a person with inherited regulatory DNA, looked at in one cell at one life stage.
class Config:
	extends RefCounted
	var stage: int = Stage.INFANT
	var variant: int = Variant.TYPICAL
	var cell: int = CellType.INTESTINE
	var challenge: int = 1
	var supplement: bool = false

	func copy() -> Config:
		var c: Config = Config.new()
		c.stage = stage
		c.variant = variant
		c.cell = cell
		c.challenge = challenge
		c.supplement = supplement
		return c


# === PUBLIC METHODS ===
## Relative LCT expression, 0 to 1.
static func expression(variant: int, stage: int, cell: int) -> float:
	if cell == CellType.MUSCLE:
		return EXPRESSION_MUSCLE
	var s: int = clampi(stage, 0, 2)
	if variant == Variant.PERSISTENT:
		return EXPRESSION_PERSISTENT[s]
	return EXPRESSION_TYPICAL[s]


static func expression_of(cfg: Config) -> float:
	return expression(cfg.variant, cfg.stage, cfg.cell)


## Lactase on the lining, in the Molecules view's units (0 to MoleculeModel.MAX_ENZYMES).
static func enzyme_count(expr: float) -> int:
	return clampi(int(round(clampf(expr, 0.0, 1.0) * float(MoleculeModel.MAX_ENZYMES))), 0, MoleculeModel.MAX_ENZYMES)


static func supplement_count(cfg: Config) -> int:
	return SUPPLEMENT_ENZYMES if cfg.supplement else 0


## A word for the expression level, so the level is never shown by colour or bar length alone.
static func expression_word(expr: float) -> String:
	if expr <= 0.0:
		return "off"
	if expr < 0.3:
		return "low"
	if expr < 0.75:
		return "medium"
	return "high"


## The LCT coding excerpt. It takes no arguments on purpose: it is the same for everyone.
static func coding_sequence() -> String:
	return EvidenceData.CODING


## The upstream regulatory excerpt for a person who inherited this variant.
static func regulatory_sequence(variant: int) -> String:
	if variant == Variant.PERSISTENT:
		return EvidenceData.UPSTREAM_VARIANT
	return EvidenceData.UPSTREAM_TYPICAL


## Builds the digestion preview for a scenario, using the Molecules model itself.
static func build_digestion(cfg: Config, run_seed: int = 1) -> MoleculeModel:
	var m: MoleculeModel = MoleculeModel.new()
	m.setup(CHALLENGE_LACTOSE[clampi(cfg.challenge, 0, 2)], enzyme_count(expression_of(cfg)), run_seed,
		supplement_count(cfg))
	return m


static func describe(cfg: Config) -> String:
	return "%s, %s, %s" % [STAGE_NAMES[cfg.stage], VARIANT_NAMES[cfg.variant].to_lower(), CELL_NAMES[cfg.cell].to_lower()]
