# Test report

**Build tested:** web export made 2026-11-15 from this project (`index.pck` SHA-256 begins
`18b7c20459752024`), in `..\exports\lactase-persistence\`.
**Machine:** one Windows 11 Pro desktop. **Engine:** Godot 4.7.2-stable, GL Compatibility.
**Browser:** Google Chrome 157.0.8103.39, driven by Playwright.

Every result below is from a run on that date against that build. Commands are in `README.md`.
Each claim is stated at the strength of its method; section 9 lists what was **not** tested.

## 1. Summary

| Suite | Method | Result |
|---|---|---|
| Import and parse scan (`--editor --quit-after`) | Godot, headless | no `SCRIPT ERROR`, `Parse Error` or `not found` |
| `tests/test_molecules.gd` | pure model, headless | 43 / 43 |
| `tests/test_regulation.gd` | pure model, headless | 26 / 26 |
| `tests/test_population.gd` | pure model, headless | 27 / 27 |
| `tests/test_evidence.gd` | data, headless | 22 / 22 |
| `tests/test_keyboard.gd` | real Main scene, key events pushed in, headless | 54 / 54 |
| `tests/test_views.gd` | real Main scene, frames stepped by hand, headless | 98 / 98 |
| `tests/contrast_check.py` | computed from the palette | 31 / 31 pairs |
| `check_web_template.py` | static scan | 0 3D, 0 stripped GUI, 0 deprecated; "2D template OK" |
| `tests/web/web_check.js`, headless Chrome (software GL), 60 s idle wait | exported build | 72 / 72 |
| `tests/web/web_check.js`, visible Chrome window (real GPU), 60 s idle wait | exported build | 72 / 72 |
| `tests/web/axe_check.js` | axe-core on the HTML shell | 0 violations, 14 rules passed, while loading and while running |
| Packed-file check | strings in `index.pck` | 43 paths, all project scripts and scenes; nothing extraneous |

Headless tests total 270 checks. Each script states the number of checks it expects and fails if
the count differs, so a test that stops early cannot pass.

## 2. Scientific behaviour

GDD acceptance tests 1 to 7. Tested on the model classes directly, and again through the views.

| # | GDD acceptance test | Where | Result |
|---|---|---|---|
| 1 | Zero lactase, any positive lactose: no glucose or galactose | `test_molecules` (1, 50 and 100 lactose); `test_views` through the Molecules view | pass |
| 2 | Each cleavage: 1 lactose lost, 1 glucose and 1 galactose gained; enzyme remains | `test_molecules`: checked on every one of the 450 ticks of a run, plus that no product appears on a tick with no cleavage, and that the enzyme count never changes | pass |
| 3 | Same time and lactose, more lactase never lowers conversion | `test_molecules`: every lactase level 0 to 20, for 20, 50 and 100 lactose, at the end and after 5 s | pass |
| 4 | Infant typical and infant persistent both high; adult typical reduced; adult persistent higher; coding drawing unchanged | `test_regulation`; `test_views` checks the DNA picture's coding text is the same after changing the variant | pass |
| 5 | Evidence: four people, identical LCT excerpt, exactly one one-copy ATT / ACT difference for Alissa | `test_evidence`: the expected strings are typed out again in the test | pass |
| 6 | `p = 0` and `p = 1` fixed; neutral leaves p unchanged; selection raises p; shares sum to 1 | `test_population`: 500 generations at the endpoints; 200 neutral generations with p exactly equal; p strictly rising for 300 generations from five starting values, mild and strong; shares summed at 101 frequencies | pass |
| 7 | No choice changes DNA or allele frequency without a new generation | `test_population` and `test_views`: changing the setting leaves p, the generation and the history as they were; the change acts only through the next generation | pass |

Further science checks that passed:

- **Lactase is reused:** after a full run every enzyme has more than one turnover, and enzyme
  turnovers add up to the number of cleavages.
- **Intact lactose is never absorbed:** the counter stays at 0 in every run, and the model has no
  code path that absorbs it.
- **Less lactase changes the amount, not the enzyme:** an enzyme's turnover count after 10 s is
  the same whether there are 2 or 6 enzymes.
- **Replay:** the same seed and settings give an identical state after 120 ticks and at the end;
  60 fps and 24 fps reach the same state; a different seed moves the picture but not the totals.
- **Substrate limit:** 5 lactose with 20 lactase gives exactly 5 cleavages.
- **Muscle cell:** expression 0 at every stage and variant; nothing is split.
- **Supplement:** adds 10 enzymes to the gut contents, marked as supplement; the cell's own
  lactase, the LCT expression and the inherited variant are unchanged.
- **One rule set:** the DNA & Lactase preview is a `MoleculeModel` and passes the same invariants.
- **Phenotype is not allele frequency:** p = 10% gives 19% of adults making lactase; 30% gives 51%.
- **One generation by hand:** p = 0.1 with weights 1.2, 1.2, 1.0 gives 0.115607, matching
  `(0.012 + 0.108) / 1.038`.
- **No forced endpoint:** from 1% with a mild advantage, p is still below 100% after 100 generations.

A defect found and fixed by these tests: the first population model used `Vector3`, which is
32-bit, and the allele frequency drifted under no selection. It now uses 64-bit floats, and returns
the frequency unchanged when all weights are equal.

**Limits of these tests.** They show the model obeys its own stated rules and the GDD's formulas.
They do not show that the illustrative numbers (enzyme timing, expression levels, advantage sizes)
match real physiology or history; the simulator labels them as model values.

## 3. Interaction

From `test_views.gd` (real Main scene, headless; frames advanced by calling `_process`).

| Check | Result |
|---|---|
| All four views open from the menu and directly; Home returns | pass |
| Molecules: Run, Pause, Step, Reset; Speed 1x / 2x / 0.5x give 30 / 60 / 15 ticks per second | pass |
| Molecules: run stops itself when finished; replay after Reset is identical | pass |
| Molecules: Compare shows strip B with the same lactose and seed; A (8 lactase) splits 50, B (2) splits 19 | pass |
| Molecules: "What changed?" gives the numbers, with lactase the same before and after | pass |
| Molecules: changing a setting starts a fresh paused run | pass |
| DNA & Lactase: stage, variant, cell and challenge controls change the model; no manual lactase control exists | pass |
| DNA & Lactase: Compare keeps each person's own DNA; both previews run to the end (19 and 80 of 80 split) | pass |
| DNA & Lactase: supplement hidden in Explore, shown in Explain, removed on leaving Explain | pass |
| Evidence: nothing highlighted automatically; highlights kept per excerpt; Clear works | pass |
| Evidence: an unfinished check does not say where the difference is; Explore gives no biological meaning | pass |
| Generations: Step, Run 10 (one generation per 0.6 s), Pause, Reset | pass |
| Generations: Compare starts B from the same population; after 20 generations A unchanged, B higher | pass |
| Generations: second chart shows adults who make lactase; two runs differ by dash and marker | pass |
| Controls stay usable when the frame changes size (section 5) | pass |

## 4. Keyboard and exit

From `test_keyboard.gd` (54 checks, key events pushed into the window) and the browser run.

| Check | Headless Godot | Chrome, exported build in an iframe |
|---|---|---|
| Tab with nothing focused goes to the first control; Shift+Tab to the last | pass | pass |
| Tab visits every control in order, in all five screens | pass (8, 17, 20, 13 and 20 controls in the opening state of the menu, Molecules, DNA & Lactase, Evidence and Generations) | menu: all 8 |
| Tab past the last control leaves and releases focus | pass | pass: exactly one `sims:leave-game`; focus lands on the host's Full screen button |
| Shift+Tab before the first control leaves | pass | pass |
| Escape with nothing open leaves | pass | pass, also while a run is playing |
| Escape with Help open closes Help and does not leave; next Escape leaves | pass | pass |
| While Help or Settings is open, Tab reaches only its controls | pass | not checked in the browser |
| A held Tab key stops at the end instead of leaving | pass | not checked in the browser |
| Focus returns to the button that opened an overlay | pass | not checked in the browser |
| No button or slider has focus turned off | pass | n/a |
| Run, Pause, sliders, plus / minus, options, tiles, Home from the keyboard | pass | Run, Pause, Step, options, tiles: pass |
| DNA table: arrows move the cursor without losing focus, Enter highlights, Check reports a match | pass | zoom and Compare from the keyboard: pass |
| Only `sims:leave-game` is ever posted to the host (no scores or results) | n/a | pass (4 messages in the run, all of that type) |

The iframe test page (`tests/web/harness.html`) is a stand-in with a copy of the play page's
listener. It is not the real site.

## 5. Frame sizes, text and motion

| Case | Headless Godot (`test_views`) | Chrome, exported build |
|---|---|---|
| 1180 x 500, pixel ratio 1 | layout 1180 x 500 at 1.00 CSS px; all views usable | pass |
| 1180 x 500, pixel ratio 1.5 | same layout, 1.00 CSS px | pass (`layout 1180x500 css=1.00 dpr=1.50`) |
| 1180 x 360 | layout 1388 x 423; text held at 0.85 CSS px, not 0.72 | pass |
| 590 x 250 at ratio 2 (stands in for 200% zoom) | layout 694 x 294 at 0.85; tabs | pass |
| 380 x 640 at ratio 2 (phone-like) | layout 447 x 752 at 0.85; tabs | pass |
| 1366 x 768 (Chromebook-sized tab) | all views usable | not run in the browser |
| Frame resized while open | n/a | layout follows, in all five cases |

"All views usable" means, for every screen and both tabs: at least five controls reachable; every
control at least 44 x 44 CSS px; no control under the reserved top-right 200 x 64 CSS px corner;
no control running off the side. It was checked by measuring control rectangles, not by eye.

Screenshots of each case were also looked at once by the build agent, in the browser at all five
sizes and from the desktop build. That is a visual spot check, not a test.

| Setting | Check | Result |
|---|---|---|
| Text size Large | 1.25 CSS px per layout px; layout 944 wide | pass |
| Text size Extra large | 1.5 CSS px; view switches to tabs; both tabs work | pass |
| Back to Normal | both panels side by side again | pass |
| Reduced motion, labels, Explain | model run identical to the normal run | pass |
| Reduced motion | free lactose drawn in a fixed place; Run 10 shows its result at once | pass |
| Browser set to reduce motion | simulator starts with reduced motion (Chrome, emulated preference) | pass |
| `motion=normal` in the address | overrides the browser preference | pass |

## 6. No auto-play, no outside requests

| Check | Method | Result |
|---|---|---|
| No view starts running by itself | `test_views`: every view opened, `running` false | pass |
| 60 s without input changes nothing | `test_views`: 3600 stepped frames, model state identical | pass |
| Opening screen does not move | Chrome: screenshots 60 s apart are pixel-identical (headless and visible window) | pass |
| Molecules does not move before Run | Chrome: screenshots 10 s apart are pixel-identical | pass |
| Pause freezes the picture | Chrome: screenshots 4 s apart are pixel-identical; it changes again after resuming | pass |
| No audio | `test_views`: no audio player node in the scene; no audio file in `index.pck` | pass |
| No outside requests | Chrome: 6 requests, all to the build's own origin (`index.html`, `.js`, `.wasm`, `.pck`, icon, one `blob:`) | pass |
| No console errors | Chrome: no `SCRIPT ERROR`, `Parse Error`, `USER ERROR`, `ERROR` or page error in the 13 page loads where the console was checked (14 loads in all) | pass |
| Boot line | Chrome: every load reached `lactase-sim: boot ok` or a line printed after it | pass |
| Class settings | Chrome and `test_views`: all four applied; unknown keys and values ignored; over-long and non-exact values ignored | pass |

## 7. What is in the export

Command (PowerShell 7, from the export folder):

```powershell
python -c "import re; b=open('index.pck','rb').read(); [print(n.decode()) for n in sorted(set(re.findall(rb'res://[\x20-\x7e]{1,200}?\.(?:gd|gdc|tscn|scn|md|txt|png|svg|import|cfg|html|js|py|json|ctex|remap|uid|tres|res)', b)))]"
```

Result: 43 paths: the six scenes, `icon.svg`, and the 34 scripts under `scripts/`. A search of the
`.pck` for `fable`, `Sims_Site`, `GDD`, `tests/`, `shot`, `web_check`, `harness`, `README`,
`CREDITS`, `TEST_REPORT`, `password`, `PIN`, `https://`, `Users` and the owner's user name found
**0** of each. `http://` appears once, as the XML namespace inside `icon.svg`; it is not a link and
is never requested. `index.html` contains no URL.

Export folder: `index.html`, `index.js`, `index.wasm` (39.5 MB), `index.pck` (0.16 MB), three icon
images, and two audio worklet scripts that the engine always writes (unused: there is no audio).

## 8. Accessibility

| Item | Method | Result |
|---|---|---|
| Text contrast 4.5:1, outlines and focus 3:1 | computed for 31 colour pairs from `ui_theme.gd` | pass; lowest text pair 4.64:1 (unavailable button), lowest outline pair 3.06:1 (table cell edge) |
| Target size 44 x 44 CSS px | measured rectangles of every focusable control at six frame sizes | pass. DNA table cells inside the table are 44 tall but about 39 wide at phone width. |
| Visible focus | drawn outline on buttons, sliders, tiles and the table cursor; seen in browser screenshots | present; not measured |
| Colour not the only cue | by design: shape, pattern, letters, marks, dash style | reviewed in screenshots, not tested by a person with colour-vision deficiency |
| No flashing | nothing blinks; fastest change is a molecule moving | by inspection |
| HTML shell | axe-core, WCAG 2.0 / 2.1 / 2.2 A and AA rules | 0 violations. axe cannot see inside the canvas. |
| Live-region messages | `test_keyboard`: a message is recorded on focus change | the text is produced; **whether a screen reader reads it was not tested** |

## 9. Not tested

Do not read any of these as passed.

- **Phone**, **tablet**, **Chromebook**: not tried on real devices. Sizes were emulated only.
- **Touch input**: not tested. Buttons use ordinary mouse-style input, which Godot also sends for
  touch; scrolling panels by touch was not tried.
- **Physical keyboard by a person**: not done. All key presses were synthetic.
- **Screen reader** (NVDA, ChromeVox, VoiceOver): not tested at all.
- **The real site**: not imported; not run on `/play/<slug>`; the real play page's listener and
  headers were not exercised.
- **Real full screen**: the expected two-press Escape in Chrome full screen was not tried, and the
  site's full-screen button was not seen over the game.
- **Real browser zoom at 200%**: emulated with a small frame at pixel ratio 2, not with Ctrl +.
- **Other browsers**: Firefox, Safari, Edge and Vivaldi were not tested.
- **Low-end hardware**: frame rate was not measured. The heaviest screen draws about 300 small
  shapes per frame.
- **Students and teachers**: no one has used it. Whether the pictures and wording are clear to
  eighth graders, and how long it takes, is unknown.
- **Lesson fidelity beyond the GDD**: the DNA excerpts were checked against the GDD's text, not
  against the original New Visions student materials, which were not available to the build.
- **Git remote**: commits are local; pushing to GitHub was blocked by the session's permission
  layer and has not happened.
