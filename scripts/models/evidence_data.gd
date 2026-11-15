class_name EvidenceData
extends RefCounted
## The DNA comparison from the lesson's student materials (p. 18), exactly as supplied (GDD 6.2).
## These are instructional excerpts, not full genomic coordinates or a clinical genotype.
## Read-only: nothing in the simulator changes this data.

# === CONSTANTS ===
enum Region { CODING, UPSTREAM }

## Lactase (LCT) coding excerpt: both copies, all four people.
const CODING: String = "ATA-AAG-GAC-ACT-CTT-GAC-AA"
## Upstream regulatory-region excerpt.
const UPSTREAM_TYPICAL: String = "TTA-CGG-TAA-ATT-AAT-GCC-AA"
## Alissa's second copy: ATT -> ACT in the fourth group.
const UPSTREAM_VARIANT: String = "TTA-CGG-TAA-ACT-AAT-GCC-AA"

const KANNA: int = 0
const MOTHER: int = 1
const BROTHER: int = 2
const ALISSA: int = 3
const PERSON_COUNT: int = 4
const COPY_COUNT: int = 2

const NAMES: Array[String] = ["Kanna", "Kanna's mother", "Kanna's baby brother", "Alissa"]
const SHORT_NAMES: Array[String] = ["Kanna", "Mother", "Baby brother", "Alissa"]
## What the lesson's sample test found for each person (shown in Explain mode only).
const LESSON_NOTES: Array[String] = [
	"Lesson sample: little lactase",
	"Lesson sample: little lactase",
	"Lesson sample: lactase present (infant)",
	"Lesson sample: lactase present (adult)",
]
const REGION_NAMES: Array[String] = ["LCT coding excerpt", "Upstream (regulatory) excerpt"]


# === PUBLIC METHODS ===
## The excerpt for one person, one region, one of their two chromosome copies (0 or 1).
static func sequence(person: int, region: int, copy: int) -> String:
	if region == Region.CODING:
		return CODING
	if person == ALISSA and copy == 1:
		return UPSTREAM_VARIANT
	return UPSTREAM_TYPICAL


## The excerpt split into its hyphen-separated groups of bases.
static func groups(seq: String) -> PackedStringArray:
	return seq.split("-")


static func group_count(region: int) -> int:
	return groups(sequence(KANNA, region, 0)).size()


## A key for one cell of the comparison table.
static func cell_key(person: int, copy: int, group: int) -> int:
	return person * 100 + copy * 50 + group


## Every cell that differs from Kanna's first copy (the reference row), as cell keys.
static func differences(region: int) -> Array[int]:
	var out: Array[int] = []
	var reference: PackedStringArray = groups(sequence(KANNA, region, 0))
	for person: int in range(PERSON_COUNT):
		for copy: int in range(COPY_COUNT):
			var row: PackedStringArray = groups(sequence(person, region, copy))
			for g: int in range(row.size()):
				if row[g] != reference[g]:
					out.append(cell_key(person, copy, g))
	return out


## Compares a student's highlighted cells (cell keys) with the lesson data.
## Returns {"right": Array[int], "wrong": Array[int], "missed": int, "exact": bool}.
## It reports only whether the highlighting matches; it does not say what the difference means.
static func check_highlights(region: int, highlighted: Array[int]) -> Dictionary:
	var real: Array[int] = differences(region)
	var right: Array[int] = []
	var wrong: Array[int] = []
	for key: int in highlighted:
		if real.has(key):
			right.append(key)
		else:
			wrong.append(key)
	var missed: int = real.size() - right.size()
	return {"right": right, "wrong": wrong, "missed": missed, "exact": wrong.is_empty() and missed == 0}
