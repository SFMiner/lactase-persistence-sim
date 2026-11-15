# Asset requirements

Everything on screen is currently drawn in code. Nothing is blocked on art: the simulator is
complete with these placeholders. This file lists what final artwork could replace, where the
placeholder lives, and what a replacement must keep true.

## How placeholders are organised

- **One file draws every shape:** `scripts/views/shapes.gd`. Each asset below names the function
  to replace. The renderers call these functions and never draw a molecule themselves.
- **To swap in a texture:** load it once (for example in a small `Art` class), and in the
  function draw it with `ci.draw_texture_rect(texture, Rect2(center - size / 2, size), false)`
  instead of the polygons. Keep the function's arguments, so no caller changes.
- **Colours** are constants in `scripts/ui/ui_theme.gd`. `tests/contrast_check.py` reads them;
  run it again after changing any.

## Format and naming

- **Source:** SVG, one file per asset, artboard cropped to the shape with no padding.
- **In the project:** `assets/<group>/<name>.svg`. Godot imports SVG to a texture at import time;
  set the import scale to 2 so the art stays sharp at device pixel ratio 2. If an SVG uses
  features Godot's importer does not support (filters, text, masks), export a PNG at 2x instead:
  `assets/<group>/<name>@2x.png`.
- **Names:** lowercase, words joined by `_`, state as a suffix: `lactase_free.svg`,
  `lactase_bound.svg`.
- **No text inside art.** Labels are drawn by the simulator so they follow the Labels switch and
  the text size setting.
- **No emoji, no external fonts, no embedded links.**
- Add each file's source and licence to `CREDITS.md` when it is added.

## Rules every replacement must keep

1. **Shape tells the molecules apart, not colour.** Glucose and galactose must have clearly
   different outlines, and lactose must visibly be one of each, joined.
2. **Lactase has exactly one pocket**, and lactose must fit it at the drawn sizes.
3. **The LCT coding region looks the same for every person.** Only regulatory DNA may differ.
4. **Regulatory DNA and the coding region differ by pattern or shape**, as well as colour.
5. **Outlines keep 3:1 contrast** against the cream lumen (`#FFF8E7`) and white panels; text
   keeps 4.5:1.
6. **People's looks never depend on genotype.** Skin, hair and clothing are assigned at random.
7. **Nothing animates by itself.** Art is static; the simulator moves it only while running.

## Required assets (GDD section 10)

Sizes are the largest the asset is drawn at, in layout pixels at 1x. Supply SVG, or PNG at twice
this size.

| Asset | Placeholder (in `shapes.gd` unless noted) | Suggested file | Drawn size (1x) | Notes |
|---|---|---|---|---|
| Glucose | `glucose()`: orange hexagon, centre dot | `assets/molecules/glucose.svg` | 24 x 24 (as small as 9 x 9) | Must match one half of lactose. Must read at 9 px. |
| Galactose | `galactose()`: violet pentagon, centre bar | `assets/molecules/galactose.svg` | 24 x 24 (as small as 9 x 9) | Must match the other half of lactose. |
| Lactose | `lactose()`: glucose + galactose with a bond | `assets/molecules/lactose.svg` | 48 x 24 | Drawn rotated. The cleavage animation pulls the two halves apart, so either supply the halves separately (preferred: reuse the two files above plus `bond.svg`) or supply `lactose_split.svg`. |
| Lactase, free | `lactase()`: green body with a top pocket | `assets/molecules/lactase_free.svg` | 66 x 41 (as small as 15 x 9) | Pocket centred on top, about 58% of the width. |
| Lactase, bound / cleaving | `lactase(busy = true)`: same shape, darker | `assets/molecules/lactase_bound.svg` | 66 x 41 | Optional: a pocket that closes slightly. Must stay the same outline size. |
| Lactase, supplement | `lactase(supplement = true)`: pale blue with a plus sign | `assets/molecules/lactase_supplement.svg` | 66 x 41 | Must differ from cell-made lactase by a mark or shape, not only colour. Optional in the GDD. |
| Water drop | `droplet()` | `assets/molecules/water.svg` | 10 x 14 | Explain mode only. |
| Intestine lining (brush border) | `MoleculeRenderer._draw_background()` in `molecule_renderer.gd` | `assets/body/lining_cell.svg` (one tileable cell) and `assets/body/lumen.svg` (optional background) | cell 66 x 52, tiled across up to 880 | Cells tile horizontally; microvilli on the top edge. Stage width varies from 160 to 880, so it must tile, not stretch. |
| Chromosome 2 | `DnaRenderer._chromosome()` in `dna_renderer.gd` | `assets/dna/chromosome_2.svg` | 520 x 30 (large view), 110 x 18 (small) | Simple banding, centromere, horizontal. A boxed marker is drawn on top at 64-70% of the length. Not a photo. |
| DNA strand (unrolled) | rails and rungs in `DnaRenderer._draw_strip()` | `assets/dna/strand_tile.svg` | tile 14 x 10 | Tiles horizontally under the two boxes. |
| Regulatory DNA box | striped rectangle in `_draw_strip()` | `assets/dna/regulatory_region.svg` | 260 x 30 | Needs a 9-slice or stretchable middle; a pattern, not a flat colour. |
| LCT coding region | solid box with an arrow tip in `_draw_strip()` | `assets/dna/coding_region.svg` | 400 x 30 | Arrow tip shows reading direction. Identical in every scenario. |
| Variant marker | diamond in `_draw_strip()` | `assets/dna/variant_marker.svg` | 12 x 12 | Sits above the regulatory box for the persistence variant. |
| Intestine cell | `CellRenderer._draw_intestine()` in `cell_renderer.gd` | `assets/body/intestine_cell.svg` | 170 x 80 | Brush border on top, nucleus low in the cell. Lactase icons are drawn moving inside it. |
| Muscle cell | `CellRenderer._draw_muscle()` | `assets/body/muscle_cell.svg` | 170 x 50 | Optional in the GDD (cell-type control). |
| Population avatars | `avatar()`: head, hair, shoulders | `assets/people/person_01.svg` to `person_12.svg` | 26 x 36 (as small as 10 x 14) | A set of about 12 varied people. Neutral expressions, no clothing or features that suggest a place or group. A genotype badge is drawn under each by the simulator. |
| UI icons | `icon()`: play, pause, step, reset, home, compare, help, labels, settings, zoom, minus, plus, close, speed, check, cross, lock, chart, next, view | `assets/icons/<name>.svg` | 20 x 20 | Single colour, drawn in the button's text colour (dark, or white on a chosen button), so supply as one-colour shapes that can be tinted. |
| Menu tile pictures | `TileButton._draw()` in `scripts/ui/tile_button.gd` | `assets/tiles/molecules.svg`, `regulation.svg`, `population.svg`, `evidence.svg` | 250 x 100 | One per model. Currently composed from the shapes above. |
| App icon | `icon.svg` (hand-written) | `icon.svg` | 128 x 128 | Also used for the browser tab icon by the export. |

## Optional assets

| Asset | Status | Suggested file | Notes |
|---|---|---|---|
| Regional map (Engage stage) | **Not built.** | `assets/reference/lactose_map.png`, about 900 x 420 | The GDD asks for the lesson's own licensed or teacher-provided map, shown for reference only, with no invented statistics. It needs the image and written permission to include it. A viewer for it would be a small addition. |
| Lactase supplement illustration | Built as a marked enzyme (see above) | `assets/molecules/supplement_tablet.svg`, 40 x 24 | Optional picture of a tablet next to the toggle. Must not suggest a dose or a brand. |

## Not needed

- **Audio.** There is none, and the hosting rules mean any future sound must start off.
- **Fonts.** The engine's built-in font is used; external fonts are not allowed on the site.
