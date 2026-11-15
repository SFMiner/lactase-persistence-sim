# Credits

## Third-party assets

**None.** The project contains no third-party art, sound, fonts, data files, add-ons or libraries.
Every picture (molecules, enzyme, intestine lining, chromosome, DNA, cell, people, icons, charts)
is drawn in code by `scripts/views/shapes.gd` and the renderers beside it. `icon.svg` was written
by hand for this project. There is no audio.

Add an entry here, with its licence, as soon as any third-party asset is added.

## Engine

| Item | Source | Licence |
|---|---|---|
| Godot Engine 4.7.2 | https://godotengine.org | MIT |
| Default font (Open Sans, built into the engine and used for all text) | part of the Godot Engine distribution | SIL Open Font License 1.1 |

The exported build contains the Godot engine. Godot's own third-party notices are in the engine's
`COPYRIGHT.txt`.

## Lesson content

The DNA excerpts and the four named people (Kanna, Kanna's mother, Kanna's baby brother, Alissa)
come from the student materials of *Lactase Persistence 5E*, New Visions for Public Schools,
Biology Unit 3, *Evolution of Sick Humans* (student materials p. 18), as quoted in the design
document. They are instructional excerpts, reproduced so the simulator matches the lesson. The
terms under which New Visions materials may be reused have **not** been checked for this project;
the owner should confirm them before publication.

## Code patterns reused from the owner's other projects

Not third-party; listed so the history is clear.

- `web/shell.html`, `scripts/ui/announcer.gd`, `scripts/ui/keyboard_navigation.gd`,
  `tests/web/harness.html`, `tests/web/axe_check.js` and the structure of `tests/web/web_check.js`
  follow the versions in the Cell Designer project, which in turn follow Data Detectives.
- Responsive scaling follows the approach in evolution-simulator's `ResponsiveLayout.gd`.

## Tools used for testing (not shipped)

Playwright and axe-core, from the site repository's `node_modules`; Google Chrome; Python 3.
