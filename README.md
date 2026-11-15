# Lactase Persistence Simulator

A Godot 4.7 teaching aid for eighth-grade biology. It explores one question at three scales:
**why can some people digest lactose as adults while others cannot?**

Built from `Lactase_Persistence_Simulator_GDD_v0.1.md` (in this folder) for hosting on
`sims.mr-miner.com`. It supplements the *Lactase Persistence 5E* lesson; it does not replace it.
There are no scores, no win states and no fixed order.

- **Status:** first complete build, 2026-11-15. All four views work; the web export is built and
  tested in Chrome on a Windows desktop. Not yet tried on a phone, a Chromebook or with a screen
  reader (see [Accessibility notes](#accessibility-notes-for-the-registry)).
- **Web export:** `..\exports\lactase-persistence\` (`index.html` at its top).
- **Not published.** The game-sim-server session imports it; publication is the owner's decision.

## Features

- [x] **Choose a Model** opening screen: four tiles, any order, Home always returns
- [x] **Molecules** (Module A): lactose digestion sandbox
	- [x] Lactose 0-100 and lactase 0-20, each with a slider and minus / plus buttons
	- [x] Bind, cleave, release: one lactose becomes one glucose and one galactose; lactase is reused
	- [x] Products cross the lining; whole lactose never does
	- [x] Run / Pause, Step (one enzyme event), Reset (same seed, same replay), Speed 0.5x / 1x / 2x
	- [x] Compare: two strips, same lactose and seed, different lactase
	- [x] Counts as labelled bars, and a "What changed?" summary in numbers
- [x] **DNA & Lactase** (Module B): gene regulation across life stages
	- [x] Chromosome 2, regulatory DNA (striped) and LCT coding region (solid), drawn the same coding region for everyone
	- [x] Life stage (infant / child / adult), inherited regulatory DNA, cell type, lactose challenge
	- [x] LCT-use gauge with a word and ten boxes; lactase count; production shown while running
	- [x] Digestion preview that is the Molecules model itself (no second rule set)
	- [x] Compare two people side by side
	- [x] Lactase supplement (Explain mode only): adds enzyme to the gut, changes no DNA
- [x] **Generations** (Module C): population change
	- [x] One locus, alleles P and n, P dominant for adult persistence; expected proportions (no drift)
	- [x] Start at 1%, 10% or 30%; two settings for milk use; advantage None / Mild / Strong
	- [x] Step one generation, Run ten, Reset; 100 pictured newborns with genotype badges
	- [x] Chart of allele P (%) by generation, and a second chart of adults who make lactase (%)
	- [x] Compare two settings from the same starting population
- [x] **Evidence**: the Kanna / Alissa DNA comparison, with the lesson's exact excerpts
	- [x] Zoom: chromosome 2 (two copies), LCT coding excerpt, upstream excerpt
	- [x] Compare all four people; student highlights; Check highlighting (match / no match only)
- [x] **Explore / Explain** modes and **Labels on / off**, on every view
- [x] Help (illustrated steps for the open view) and Settings (text size, reduce motion)
- [x] Keyboard: every control reachable; Tab / Shift+Tab / Escape leave the game (`sims:leave-game`)
- [x] Responsive layout: 1180 x 500 frame, 360 px tall, phone width, device pixel ratio 1.5 and 2
- [x] Class settings in the address (`model`, `mode`, `motion`, `labels`)
- [x] Screen-reader live regions (written, not yet tested with a screen reader)
- [x] Web export, headless tests, browser tests, contrast check
- [ ] Advanced drawer: temperature and pH (optional in the GDD; not built)
- [ ] Reference map of regional lactose intolerance (optional; needs the lesson's licensed image)
- [ ] Final artwork (everything is drawn in code; see `ASSET_REQUIREMENTS.md`)
- [ ] Checks on a phone, a Chromebook, a physical keyboard by hand, and with a screen reader

## Setup

Requires **Godot 4.7.x** (built and tested with 4.7.2-stable). No add-ons, no plugins, no
third-party assets.

Open the project folder in the Godot editor, or run it from PowerShell 7:

```powershell
$godot = "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.7.2-stable_win64_console.exe"
& $godot --path .
```

The main scene is `Main.tscn` (capital M). Scenes are thin: each is one node with a script, and the
script builds its interface in code, so the layout can respond to the frame size.

### Project layout

```
Main.tscn                     the screen that holds everything
scenes/                       ModelSelect, MoleculeView, RegulationView, EvidenceView, PopulationView
scripts/main.gd               top bar, view switching, Help and Settings
scripts/app_state.gd          shared presentation state (mode, labels, speed)
scripts/models/               the science, as plain RefCounted classes with no drawing
	molecule_model.gd         digestion: discrete events on a fixed tick
	regulation_model.gd       regulatory DNA + life stage + cell -> lactase amount
	population_model.gd       allele frequency across generations
	evidence_data.gd          the lesson's DNA excerpts (read-only)
scripts/views/                view controllers and code-drawn pictures (shapes.gd holds every shape)
scripts/ui/                   theme, buttons, steppers, keyboard navigation, responsive layout, announcer
scripts/web/exit_bridge.gd    the one message sent to the host page
web/shell.html                HTML page around the canvas (loading text, live regions)
tests/                        headless tests, screenshot tool, contrast check
tests/web/                    Playwright checks of the real export
```

## Controls

| Action | Mouse / touch | Keyboard |
|---|---|---|
| Move between controls | click or tap | Tab, Shift+Tab |
| Press a button, choose an option | click or tap | Enter or Space |
| Change a slider | drag, or the minus / plus buttons | Left / Right arrows on the slider |
| Highlight a DNA group (Evidence) | click or tap the cell | arrow keys move the cursor, Enter or Space highlights |
| Close Help or Settings | Close button | Escape |
| Leave the simulator | click outside the frame | Escape with nothing open, Tab past the last control, or Shift+Tab before the first |

Every view has Home, Mode (Explore / Explain), Labels, Help and Settings in the top bar. Views that
run have Run / Pause, Step, Reset and Speed. Nothing moves until Run or Step is pressed.

**Explore** shows names only. **Explain** adds the relationships: that lactase is reused, that
water splits the bond, that regulatory DNA sets how much LCT is used, that the DNA difference is
outside the coding region, and that milk use does not cause the variant. The teacher chooses when
to switch; it is not a lock.

## Tests

Run from the project folder in PowerShell 7. Each headless script prints one PASS / FAIL line and
exits non-zero on failure. Results from the last run are in `TEST_REPORT.md`.

```powershell
$godot = "C:\Users\seanm\Nextcloud2\Gamedev\Godot_v4.7.2-stable_win64_console.exe"

# Import and parse check (expect no SCRIPT ERROR / Parse Error)
& $godot --headless --path . --editor --quit-after 250

# Headless tests (270 checks in all)
foreach ($t in "molecules", "regulation", "population", "evidence", "keyboard", "views") {
	& $godot --headless --path . --script "tests/test_$t.gd"
}

# Colour contrast of the palette
python tests/contrast_check.py

# Screenshot of a view (needs a window, so no --headless)
& $godot --path . --resolution 1180x500 --script tests/shot.gd -- "$env:TEMP\molecules.png" molecules 4 explain
```

### Browser tests (the real export)

These need Node with Playwright; the site repo's copy is reused, and Playwright drives the
installed Google Chrome (no browser download).

```powershell
# 1. Stage the export next to the iframe harness, outside the project folder
$root = "$env:TEMP\lactase-webroot"
New-Item -ItemType Directory -Force "$root\game" | Out-Null
Copy-Item ..\exports\lactase-persistence\* "$root\game\"
Copy-Item tests\web\harness.html "$root\"

# 2. Serve it (check the port is free first: Get-NetTCPConnection -LocalPort 8793)
python -m http.server 8793 --bind 127.0.0.1 --directory $root

# 3. In a second terminal
$env:NODE_PATH = "C:\Users\seanm\Nextcloud2\Website\game-sim-server\node_modules"
$env:PORT = "8793"
node tests/web/web_check.js "$env:TEMP\lactase-shots"          # headless Chrome
node tests/web/web_check.js "$env:TEMP\lactase-shots" headed   # a real Chrome window
node tests/web/axe_check.js                                    # axe-core on the HTML shell
```

Set `$env:QUICK = "1"` to shorten the 60-second no-input wait to 6 seconds.

## Export

1. In the editor: **Project > Export > Web**, with **Export With Debug unticked**. Or from
   PowerShell 7:

	```powershell
	& $godot --headless --path . --export-release "Web"
	```

2. The preset writes to `..\exports\lactase-persistence\index.html`.
3. Settings that matter, all in `export_presets.cfg` and `project.godot`:
	- `variant/thread_support=false` (the site sends no cross-origin isolation headers)
	- renderer GL Compatibility
	- stretch mode `canvas_items`, aspect `expand`; `display/window/dpi/allow_hidpi=true`
	- custom HTML shell `res://web/shell.html`
	- `exclude_filter="tests/*, web/*, *.md, *.txt"` (tests and documents are not packed)
4. After exporting, run the browser tests above, then check what was packed:
   `TEST_REPORT.md` section 7 has the command and the last result.

**Export template.** The standard Godot 4.7.2 `web_nothreads_release` template is used. The lean
2D templates in `Gamedev\godot-2d-web-template\` are built from 4.5 source, and a template must match
the engine exactly, so they cannot be used with 4.7. `check_web_template.py` was run anyway and
reports "2D template OK", with no stripped GUI classes and no deprecated calls, so the project
should fit a lean 4.7 template if one is built later. The cost today is size: `index.wasm` is
about 39.5 MB before the site's gzip.

## Hosting-registry information

For the game-sim-server session that writes the registry record.

| Field | Value |
|---|---|
| Title | Lactase Persistence Simulator |
| Suggested folder | `lactase-persistence` (served at `/g/lactase-persistence/`) |
| Description | Explore why some people can digest lactose as adults, at the scale of molecules, of genes and of a population over generations. |
| Godot version | 4.7.2-stable |
| Export template | standard `web_nothreads_release` (4.7.2), release build, no threads |
| Estimated minutes | about 10 to 20 for all four views. This is an estimate; it has not been timed with students. |
| Credits | no third-party assets; see `CREDITS.md` |
| `level` (grade) | **owner to confirm** (the GDD says eighth-grade biology) |
| `author` | **owner to fill in** |
| `license` | **owner to fill in** |

Project name (`application/config/name`) is "Lactase Persistence Simulator", so its saved settings
cannot collide with another game on the same origin. Only two things are saved, on the device:
text size and reduced motion.

### Class settings

Read from the page address in a web export only. Unknown keys, and values not in the list, are
ignored and the default is used. Values are only compared with fixed strings; nothing from the
address is run, shown or used as a path. They are a convenience, not a lock: students can still
change everything.

| Key | Type | Values | Default |
|---|---|---|---|
| `model` | choice | `menu`, `molecules`, `regulation`, `evidence`, `population` | `menu` |
| `mode` | choice | `explore`, `explain` | `explore` |
| `motion` | choice | `normal`, `reduced` | `normal` (or the browser's reduced-motion preference, if set) |
| `labels` | choice | `on`, `off` | `on` |

Example: `index.html?model=population&mode=explain`

### Accessibility notes for the registry

Stated at the strength of what was checked. Details and counts are in `TEST_REPORT.md`.

- **Keyboard.** Every button, option, slider and the DNA table can be used from the keyboard.
  Tab past the last control, Shift+Tab before the first, and Escape with nothing open all release
  focus and post `sims:leave-game` to a same-origin parent; Escape closes Help or Settings first.
  *How tested:* a headless Godot test pushing real key events into the Main scene (54 checks), and
  Playwright pressing keys in the exported build in Google Chrome 157 on Windows, inside a
  same-origin iframe with a copy of the play page's listener, in both a headless and a visible
  window. **Not yet checked** by a person with a physical keyboard, and **not yet checked** on the
  real site's play page.
- **Full screen.** In real Chrome full screen the browser takes the first Escape, so leaving takes
  two presses. That is expected behaviour and was **not tested**.
- **Screen reader.** Not tested. The canvas has a label, and the simulator writes the focused
  control's name and state, and results such as "Run finished ...", to hidden live regions
  (`web/shell.html`, `scripts/ui/announcer.gd`). Whether a screen reader reads these usefully is
  unknown. The pictures themselves are not described beyond those messages.
- **Devices.** Phone: **not yet checked**. Chromebook: **not yet checked**. Physical keyboard:
  **not yet checked** by hand (synthetic key events only). Tested on one Windows 11 desktop in
  Google Chrome, plus emulated frame sizes: 1180 x 500, 1180 x 360, 380 x 640, and device pixel
  ratios 1.5 and 2.
- **No auto-play.** Confirmed in the exported build: the opening screen was pixel-identical after
  60 seconds without input, and the Molecules view did not change until Run was pressed (Chrome,
  headless and visible window). There is no audio in the project at all: no audio files are packed
  and no audio player node exists.
- **Text size and zoom.** Browser zoom does not enlarge canvas text, so Settings has Normal / Large
  / Extra large (1x, 1.25x, 1.5x). The layout keeps one layout pixel at 0.85 CSS pixels or more in
  every frame size tested. 200% zoom was **emulated** with a 590 x 250 frame at pixel ratio 2; it
  was not tested with real browser zoom on the site page.
- **Reduced motion.** A setting, a class setting, and the browser's preference as the default.
  Molecules stop drifting and "Run 10 generations" shows its result at once; counts are identical.
- **Contrast and targets.** 31 colour pairs pass WCAG AA (text 4.5:1, outlines and focus rings
  3:1), computed from the palette, not measured from pixels. Buttons and sliders are at least
  44 x 44 CSS pixels in every frame size tested. DNA table cells are 44 CSS pixels tall but can be
  about 39 wide in a phone-width frame.
- **Colour is never the only cue.** Molecules differ by shape, DNA regions by pattern and shape,
  genotypes by letters and badge style, chart lines by dash and marker, chosen options by a mark.
- **Privacy.** No text entry, accounts, network requests, analytics, external URLs or fonts. The
  only message to the host page is `sims:leave-game`; no scores or results are sent.
- **Hidden tab.** A web game stops while its tab is hidden or its window is fully covered or
  minimised (Chrome stops sending frames). This is not a bug: keep the tab visible during a run.

## Implementation notes

- **One rule set for digestion.** `RegulationModel.build_digestion()` creates a `MoleculeModel`, so
  the DNA & Lactase preview and the Molecules view cannot disagree.
- **Fixed tick.** `MoleculeModel` advances in 1/30 s ticks, so a run is identical at any frame rate
  and Reset replays it exactly. Positions are illustration; an enzyme's timing never depends on
  distance. One enzyme cycle is 46 ticks; the "available period" is 15 model seconds.
- **Expected proportions.** `PopulationModel` is deterministic (no drift). It uses 64-bit floats,
  not `Vector3`: a `Vector3` is 32-bit and made the allele frequency creep under no selection.
- **Text scale = layout scale.** `ResponsiveLayout` sets the stretch base size on every resize.
  Small frames get less picture, not smaller text; below 820 layout pixels wide a view shows its
  picture and its controls as two tabs; a very short frame scrolls.
- **Keyboard ring.** `KeyboardNavigation` rebuilds the Tab order from the scene tree on every key
  press, so it is always right after a layout change, a view change or an overlay.
- **Console lines.** The build prints short `lactase-sim: ...` lines (boot, view opened, run
  finished). The browser tests wait for them. They contain no personal data.

### Decisions and deviations from the GDD

1. **`model` default.** GDD 9.4 gives `model` a default of `molecules`, but GDD 2 says launch
   defaults to Choose a Model. These conflict. Resolved by adding a fifth value, `menu`, as the
   default; `model=molecules` still opens Molecules directly.
2. **Export template.** Standard 4.7.2 template, not a lean one (see Export).
3. **Evidence highlighting works on groups of three letters**, not single letters, so each cell can
   be a full-size touch target. The lesson's difference (ATT to ACT) is one group.
4. **Changing lactose or lactase restarts a paused run** in Molecules, so a run is never altered
   half-way and comparisons stay fair.
5. **Child life stage** is included (GDD: optional) with added in-between values: 0.5 for typical
   regulation and 0.95 for the persistence variant. Like the GDD's own values these are illustrative.
6. **Lactose challenge is shared** by both people in a DNA & Lactase comparison (same meal).
7. **Turning Compare on or off in Generations restarts both runs** from the starting population.
8. **Settings changed mid-run in Generations take effect from the next generation** and are marked
   on the chart. Choosing a different starting share resets the run.
9. **Explain-only items:** the supplement, the water note, the lesson's sample results for the four
   people, and the sentence that the DNA difference is outside the coding region.
10. **Not built** (all optional or deferred in the GDD): temperature / pH drawer, reference map,
    stochastic drift, real HTML controls outside the canvas.
11. **File layout** follows GDD 9.1 with extra view and UI scripts; `Main.tscn` is at the project
    root as the GDD shows. The hosting document was written for Cell Designer and lives one folder
    up (`GodotGames\Sims_Site_Hosting_Requirements.md`); its rules were applied with this
    project's names.

### Known limitations

- In a phone-width portrait frame the top bar wraps onto three lines, because the top-right
  200 x 64 CSS-pixel corner is kept clear for the site's full-screen button at every size.
- At 360 px tall and smaller, views scroll vertically rather than fitting on one screen.
- In the Evidence comparison, if the table is taller than the frame the cell cursor can move out of
  sight; the page scrolls to the table, not to the cursor.
- 100 lactose is crowded on screen; the counts stay exact.
- The pictures are placeholders drawn in code. They are consistent and labelled, not final art.
