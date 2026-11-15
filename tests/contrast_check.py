#!/usr/bin/env python3
"""WCAG contrast check of the colour pairs the simulator actually uses.

Usage: python tests/contrast_check.py        (run from the project folder; stdlib only)

Reads the colour constants from scripts/ui/ui_theme.gd, so it checks the real palette, and
computes the WCAG 2.x contrast ratio for each pair listed below: 4.5:1 for text, 3:1 for
outlines, icons and focus rings. It checks colour pairs, not rendered pixels: thin strokes are
anti-aliased on screen and can measure lower. Exit code 0 only if every pair passes.
"""

import re
import sys

THEME = "scripts/ui/ui_theme.gd"


def load_colors(path):
	colors = {"WHITE": (1.0, 1.0, 1.0)}
	pattern = re.compile(r"const (\w+): Color = Color\(([\d.]+), ([\d.]+), ([\d.]+), [\d.]+\)")
	with open(path, encoding="utf-8") as handle:
		for line in handle:
			match = pattern.search(line)
			if match:
				colors[match.group(1)] = tuple(float(match.group(i)) for i in (2, 3, 4))
	return colors


def luminance(rgb):
	def channel(c):
		return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
	r, g, b = (channel(c) for c in rgb)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b


def ratio(a, b):
	la, lb = luminance(a), luminance(b)
	hi, lo = max(la, lb), min(la, lb)
	return (hi + 0.05) / (lo + 0.05)


# (foreground, background, minimum, where it is used)
TEXT = 4.5
SHAPE = 3.0
PAIRS = [
	("INK", "BG", TEXT, "body text on the page background"),
	("INK", "PANEL", TEXT, "text on cards and buttons"),
	("INK", "ACCENT_SOFT", TEXT, "button text while hovered"),
	("WHITE", "ACCENT", TEXT, "text on a chosen (pressed) button and on PP / Pn badges"),
	("MUTED", "PANEL", TEXT, "small notes and titles on cards"),
	("MUTED", "BG", TEXT, "small notes on the page background"),
	("MUTED", "LUMEN", TEXT, "caption inside the intestine picture"),
	("INK", "LUMEN", TEXT, "text drawn over the intestine picture"),
	("INK", "CODING", TEXT, "sequence letters on the LCT coding box"),
	("INK", "LACTASE", TEXT, "reuse count written on a lactase"),
	("INK", "SUPPLEMENT", TEXT, "reuse count written on a supplement lactase"),
	("DISABLED_INK", "DISABLED_BG", TEXT, "text on an unavailable button (not required, checked anyway)"),
	("SERIES_A", "PANEL", TEXT, "chart value label, run A"),
	("SERIES_B", "PANEL", TEXT, "chart value label, run B"),
	("FOCUS", "BG", SHAPE, "focus outline on the page background"),
	("FOCUS", "PANEL", SHAPE, "focus outline on a card"),
	("FOCUS", "LUMEN", SHAPE, "focus outline inside a tile picture"),
	("INK", "CHROMOSOME", SHAPE, "chromosome outline"),
	("GLUCOSE_EDGE", "LUMEN", SHAPE, "glucose outline"),
	("GLUCOSE_EDGE", "GLUCOSE", SHAPE, "glucose centre dot on its fill"),
	("GALACTOSE_EDGE", "LUMEN", SHAPE, "galactose outline"),
	("GALACTOSE_EDGE", "GALACTOSE", SHAPE, "galactose centre bar on its fill"),
	("LACTASE_EDGE", "LUMEN", SHAPE, "lactase outline"),
	("SUPPLEMENT_EDGE", "LUMEN", SHAPE, "supplement lactase outline"),
	("CELL_EDGE", "LUMEN", SHAPE, "cell outline and brush border"),
	("INK", "REGULATORY", SHAPE, "outline and stripes of the regulatory DNA box"),
	("GOOD", "PANEL", SHAPE, "tick on a checked cell"),
	("BAD", "PANEL", SHAPE, "cross on a checked cell"),
	("ACCENT", "PANEL", SHAPE, "filled gauge boxes, slider fill, chart line A"),
	("SERIES_B", "PANEL", SHAPE, "chart line B"),
	("LINE", "PANEL", SHAPE, "edge of an unhighlighted table cell"),
]


def main():
	colors = load_colors(THEME)
	failed = 0
	for fg, bg, minimum, where in PAIRS:
		if fg not in colors or bg not in colors:
			print("  FAIL  %s on %s: colour not found in %s" % (fg, bg, THEME))
			failed += 1
			continue
		value = ratio(colors[fg], colors[bg])
		ok = value >= minimum
		failed += 0 if ok else 1
		print("  %s  %5.2f:1 (needs %.1f)  %s on %s: %s" % ("ok  " if ok else "FAIL", value, minimum, fg, bg, where))
	print("CONTRAST: %d/%d pairs pass -> %s" % (len(PAIRS) - failed, len(PAIRS), "PASS" if failed == 0 else "FAIL"))
	return 0 if failed == 0 else 1


if __name__ == "__main__":
	sys.exit(main())
