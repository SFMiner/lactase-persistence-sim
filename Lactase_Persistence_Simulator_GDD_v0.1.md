# Lactase Persistence Simulator — Game Design Document v0.1

**Status:** Initial build specification | **Engine:** Godot 4.7.x, GDScript | **Platform:** HTML5/WebAssembly, desktop/browser-first | **Audience:** 8th-grade biology | **Role:** Supplemental learning aid, not a substitute for the 5E sequence

## 1. Executive summary

An interactive, visually legible model explores a central question: **Why can some people digest lactose in adulthood while others cannot?** The player moves across three scales: (A) molecules interacting inside the small intestine, (B) expression of the lactase gene in intestinal cells, and (C) inherited variation changing in a population over many generations. A fourth, compact **Evidence Viewer** links the models to the lesson's Kanna/Alissa case study.

**Design priorities, in order:** biological correctness; visible cause-and-effect; alignment to lesson timing and evidence; minimal reading load; keyboard/touch accessibility; reliable lightweight Godot web export. There are **no scores, win states, invented chemical outcomes, scripted student answers, or mandatory linear progression**.

**Core questions:**
1. How does the shape and action of lactase enable the breakdown of lactose into glucose and galactose?
2. Why can two people with the same lactase protein-coding sequence produce different amounts of lactase as adults?
3. How can an inherited regulatory variant become more frequent over many generations if environmental and cultural conditions make it advantageous?

**Non-goals:** replacing the real/simulated strip investigation, automatically completing the notebook/CER, predicting individual symptoms or health, realistically modeling human digestion or biochemical kinetics, reconstructing real-world allele distributions, teaching full transcription/translation or population genetics mathematics, and declaring lactose intolerance a disease or an inferior trait.

## 2. Curriculum integration and reveal discipline

The source lesson is New Visions for Public Schools, Biology Unit 3, *Evolution of Sick Humans*, *Lactase Persistence 5E*, SY 2026–27. The teacher sequence spans roughly **9–10 days**, and identifies HS-LS1-1 and HS-LS3-1. Adapted here for eighth grade; these remain the *source lesson's* standards, not a claim that the simulator itself covers all their requirements.

| 5E stage | Source lesson | Simulator's role | What remains outside simulator |
|---|---|---|---|
| Engage | Map of regional lactose intolerance, See–Think–Wonder | Optional **reference-only** map/image viewer after teacher presents source map; no map guessing game | Students notice, wonder, and discuss |
| Explore 1 | Four mock intestinal-fluid samples: Kanna, Kanna's infant brother, Kanna's mother, Alissa | Molecular viewport shows how enzyme amount changes lactose breakdown; optional controlled comparison of two adults | Hands-on sample analysis, data table, model construction |
| Explain 1 | Digesting Dairy text and structure/function explanation | Pause and step through enzyme–substrate interaction; reveal correct labels when teacher chooses | Text annotation, model revision and group explanation |
| Explore 2 | Chromosome 2, lactase-coding sequence and upstream DNA comparisons | **Evidence Viewer** reproduces source comparison with a zoom from chromosome to sequence; students can highlight similarities/differences | Recording evidence and generating initial explanation |
| Explain 2 | Non-coding DNA, model revision, CER and consensus | Gene-expression module links regulatory variant + life stage to enzyme quantity; compare outcomes at two scales | Text, CER writing, peer feedback and consensus discussion |
| Elaborate | Video *Got Lactase?*, historical dairy cultures, variation/selection | Population model changes frequency *only through generations*, with controllable relative advantage | Video, reading, discussion about culture and environment |
| Evaluate | School-health mismatch and driving question board | Optional revisit/reference; no added school-design minigame | Teacher-led design discussion and assessment |

**Pedagogical disclosure control:** Launch defaults to **Choose a Model** rather than a full explanatory tutorial. Each model supports **Explore** (minimal labels, no causal conclusion) and **Explain** (additional labeled structures and relationships). An optional `mode=explore|explain` classroom setting can preselect this; this is not security or a teacher lock. Navigating between modules is always possible. No software-generated CER answer is shown.

## 3. Student experience and UI

### 3.1 Main navigation
- Welcome / model selector: **Molecules**, **DNA & Lactase**, **Generations**, **Evidence**. Short objective per tile; a consistent Home, Help, Reset, Pause, and Labels switch.
- Same visuals/terms across views: **lactose** (paired sugars), **lactase** (shaped enzyme), **glucose** and **galactose** (distinct single sugars), **LCT coding region**, **regulatory DNA** (not a protein-coding gene).
- Every relevant control updates observable quantities and/or animations; no decorative inactive toggles. Help uses a few illustrated steps, not a modal wall of text.

### 3.2 Layout
At about **1180 × 500 CSS px** iframe size: left/center primary illustration, right/underlying compact control panel and outcome labels; keep the **top-right ~200 × 64 CSS px free** for the site's fullscreen control. The canvas responds down to ~360 CSS px height by shrinking/scrolling simulation area and stacking/collapsing controls rather than shrinking type below legibility. Full standalone tab layout also works. Use large buttons and short captions. At phone widths, one focused panel at a time, with a dedicated controls tab.

**Visual hierarchy:** Molecule shapes first, labels second, counts/graphs third. Color may reinforce identity but must never be the only distinction. A subtle intestine epithelium/background context may show where the enzyme acts; avoid implying free-floating lactase throughout all body tissues.

### 3.3 Shared interaction
- **Play/Pause**, **Step** (one event or short time increment), **Reset**, speed choice 0.5×/1×/2×, **Labels On/Off**, and optional **What changed?** numerical summary.
- Text: clear sans serif, scalable, strong contrast, no emoji glyph reliance.
- Simulation begins paused: no sound or decorative movement without interaction.
- All adjustable values have button/keyboard alternatives. Hover-only information is forbidden.
- Optional prediction cue is non-graded: “What do you think will happen if lactase decreases?” with **no required typed response**.

## 4. Module A — Lactose digestion: molecular sandbox

### 4.1 View and model
An enlarged, **schematic** cross-section of the small intestine shows the surface where lactase functions and the intestinal lumen where lactose is present. For clarity, enzyme icons may be shown enlarged and slightly displaced from the brush border; explanatory labels identify their real location. Lactose has two visibly joined subunits. Lactase is a distinct reusable enzyme with an active-site pocket. Successful interaction is a short **bind → cleavage → release** sequence producing one glucose and one galactose. Products can move toward an epithelial absorption boundary, while uncleaved lactose remains available to move onward.

**Science constraints:** Lactase catalyzes hydrolysis; water is a reactant, but water molecules need not be animated unless optional labels are enabled. Lactase is *not consumed*, does not become glucose, and is not an ingredient of lactose. The two products are never generated unless lactose was cleaved. Lactose cannot pass through the model's glucose/galactose uptake route while intact. Reduced lactase changes rate/amount digested in the available period, not the inherent structure or effectiveness of remaining enzyme.

### 4.2 Controls (primary)
| Control | Suggested options | Observed effect |
|---|---|---|
| Lactose present | Slider 0–100 arbitrary classroom units; default 50 | Number of joined lactose molecules; remaining and processed counters |
| Lactase available | Slider 0–20 visible enzymes; default 8 | Rate/extent of lactose cleavage |
| Run / Step / Pause / Reset | Buttons | Temporal progression and reproducible comparisons |
| Compare | Split-screen or quick A/B state snapshots | Same lactose input, different lactase levels |

Use **arbitrary classroom units** consistently, explicitly identified as model units rather than real physiological concentration. A dynamic bar displays **lactose remaining** and **glucose + galactose formed**. Because each cleavage yields one of each, show counts for each separately or a “pairs cleaved” counter, not a falsely doubling mass estimate. If products are abstracted into one uptake counter, label this simplification.

### 4.3 Mechanics
Use deterministic, discrete event/collision-appearance logic rather than physics-engine outcomes to ensure clear instruction. Each active lactase icon selects a nearby eligible substrate; if available, its bind animation begins, then one lactose is converted to one glucose + one galactose, and the lactase is released with a short reset interval. A molecule cannot bind two enzymes, split twice, or disappear without accounting. The rendered molecules may move gently with seeded random velocities, but **visual collision is illustrative**, not the simulation authority.

A simple bounded rate function is sufficient: `events_this_step = min(available_lactose, capacity_from_active_lactase_and_time)`, with fractional capacity accumulated between ticks. Rate increases with available functional lactase; substrate availability caps total conversion. Avoid claiming this is quantitatively predictive Michaelis–Menten kinetics. For fair comparisons, allow a fixed common time horizon and seeded replay.

**Advanced drawer (optional, not required for v0.1 acceptance):** temperature, pH, and a line graph. If included, these must alter enzyme activity using explicitly **illustrative, normalized response curves** and a visible “conceptual model” disclaimer. Extreme pH/temperature can reduce activity; do not imply the actual gut naturally spans these adjustable values. Never make temperature or pH the lesson's causal explanation for persistence.

### 4.4 Success checks
With identical starting lactose and time, more active lactase produces at least as much hydrolysis (subject to substrate exhaustion). Zero lactase generates zero products. Every cleavage subtracts exactly one substrate and adds exactly one of each product. Replay after Reset with same seed and settings is equivalent.

## 5. Module B — Gene regulation across life stages

### 5.1 Core display
Top: schematic **chromosome 2 → DNA → LCT protein-coding region and nearby regulatory DNA**. Middle: intestinal-cell illustration with a state indicator for LCT expression, and animated production of lactase. Bottom/side: an adult/infant small-intestine digestion preview reusing Module A's quantitative model, not an independently contradictory rule system.

**Critical biological distinction:** Lactase persistence is associated with inherited **noncoding regulatory variants** that sustain LCT expression beyond childhood, not a required change in the lactase protein's coding sequence. “Regulatory DNA” is preferable to “regulatory gene.” LCT normally declines after weaning for most humans; this is a reduction, not necessarily an absolute on/off switch. Persistence can arise from different regulatory variants in different populations, even though the lesson uses one simplified example.

### 5.2 Student controls
| Control | Values | Effect |
|---|---|---|
| Life stage | Infant / Child (optional) / Adult | Nonpersistent expression reduces with age |
| Regulatory DNA | Typical decline / Persistence-associated variant | Adult LCT expression stays higher with persistence variant |
| Cell type | Small-intestine epithelial cell / muscle cell (optional) | Restrict the model's high lactase expression to appropriate intestinal cells |
| Lactose challenge | Low / Medium / High or linked slider | Applies corresponding amount in digestive preview |
| **Compare** | Two parallel configurations | Makes cause/effect visible without erasing either state |

Presets: Infant + typical regulation (high), Adult + typical regulation (low), Adult + persistent regulation (higher). Do not depict every baby as absolutely identical; general tendency is sufficient. **Do not let users interpret the regulatory switch as changing their DNA within their lifetime**: switches compare different inherited DNA scenarios, not mutation by clicking.

The default coupling is: regulatory state + age → **lactase abundance** → Module A's hydrolysis capacity. A visible lock or note says “Lactase quantity is determined by this model.” Manual enzyme sliders are only enabled in the independent Molecular Sandbox; this avoids conflicting controls.

**Simplified model mapping (illustrative, not empirical enzyme concentration):** infant typical = 1.0, adult typical = 0.1, infant persistence variant = 1.0, adult persistence variant = 0.9, muscle cell = 0.0. Values are tunable constants, explicitly not prevalence or measured physiological rates. A crossfade between states is **presentation** rather than a claim of abrupt biological change.

## 6. Evidence Viewer — Kanna/Alissa DNA investigation

This is a targeted bridge to Explore 2, not another elaborate game system.

### 6.1 Four people
Show **Kanna**, **Kanna's mother**, **Kanna's baby brother**, and **Alissa**. The lesson's evidence treats Kanna and mother as nonpersistent, Kanna's baby brother as an infant who digests lactose, and Alissa as an individual who persists in producing lactase. The student table shows their **LCT coding sequences identical**, with a difference in **one copy of Alissa's upstream noncoding sequence**. The visualization must follow these supplied classroom data, not invent a family pedigree, birthplace, ethnicity, or diagnostic genotype.

### 6.2 Exact source sequences from student materials, p. 18
**Lactase coding excerpt, both copies, all four individuals:** `ATA-AAG-GAC-ACT-CTT-GAC-AA`.

**Upstream regulatory-region excerpt:**
- Kanna: both copies `TTA-CGG-TAA-ATT-AAT-GCC-AA`.
- Kanna's mother: both copies same as Kanna.
- Kanna's baby brother: both copies same as Kanna.
- Alissa: copy 1 `TTA-CGG-TAA-ATT-AAT-GCC-AA`; copy 2 `TTA-CGG-TAA-ACT-AAT-GCC-AA`.

The depicted change is **ATT → ACT** in the supplied excerpt. Treat these excerpts as **instructional sequences from the lesson**, not as validated full genomic coordinates or a definitive modern clinical genotyping test. Make explicit that a single person's two copies are displayed, and that the rest of the DNA is not shown.

### 6.3 Navigation and prompt style
Zoom: chromosome bands → same LCT coding excerpt → upstream excerpt. Click **Compare** to align sequences character-by-character. Initially, nothing is highlighted automatically. Students can highlight differences and select **Check highlighting**, which marks whether the selected location matches the lesson data; do not immediately explain what it means biologically. Optional prompt: “What stayed the same? What changed?” With Explain mode, label that the difference is **outside** the LCT protein-coding region and affects regulation in the lesson's model.

Do not label the difference “gene broken,” “lactase mutation,” or “Alissa has the lactase gene and Kanna doesn't.”

## 7. Module C — Population change across generations

### 7.1 Purpose
Allow students to contrast **inheritance, variation, differential reproductive success, and environmental context**. An allele that affects lactase persistence may already exist at low frequency; dairy-related cultural practices can change its selective advantage. Repeated generations, not an individual's diet or decision, alter allele frequency. The game must make clear that **culture does not direct DNA mutations** and milk consumption does not automatically change anyone's inherited variant.

### 7.2 Interface
A simple population of stylized humans, with counts for genotypes/phenotypes, and a big line chart: **Persistence-associated allele frequency (%) vs. generation**. Add a separate optional chart for **adult lactase-persistence phenotype (%)**. Use accessible pattern/labels, not color alone. At most 100–200 visible avatars; underlying population can be statistical.

Controls:
- Initial allele frequency (1%, 10%, 30% presets; default 10%).
- Environment/cultural context: **little or no use of fresh milk**, **fresh milk is an important resource**; option **advantage off/on**. These are classroom scenarios, not assertions that all historical dairying was identical.
- Selection strength: **None / Mild / Strong** (illustrative relative reproductive advantage; not measured historical coefficients).
- Generations: Step one generation, Run 10, Reset, and optionally a seeded repeat.
- Optional **Compare Runs**: two scenarios with the **same initial population** and different relative advantage.

### 7.3 Population mechanics
Model a single diploid autosomal locus with two alleles: `P` = persistence-associated regulatory variant, `n` = nonpersistent. For this simplified teaching model, **P is dominant for adult persistence** (PP and Pn persistent; nn typically nonpersistent). This convention describes the model's single chosen variant and does not assert that all real genetic mechanisms and clinical tolerances reduce to one locus.

Use Hardy–Weinberg frequencies to obtain zygote genotype shares **only as the reproduction/mating approximation**: `PP=p²`, `Pn=2p(1−p)`, `nn=(1−p)²`. Give genotype relative survival/reproductive weights `w_PP, w_Pn, w_nn` determined by the chosen environment. After selection:

`PP' = p²*w_PP / W`, `Pn' = 2*p*(1-p)*w_Pn / W`, `nn' = (1-p)²*w_nn / W`, where `W` is their weighted sum. Then `p_next = PP' + 0.5*Pn'`. This advances a generation; it does **not** transform an individual genotype. Keep p in [0,1]. For deterministic class visualization, default to these expected proportions; optional stochastic drift can be postponed to v0.2. Sample teaching fitness weights when advantage is on: `w_PP=1.05, w_Pn=1.05, w_nn=1.00` (mild), or `1.20, 1.20, 1.00` (strong); with no advantage, all 1.00. Clearly mark weights and effect sizes **illustrative**. No claim that persistence always increases survival or that intolerance is an overall disadvantage.

**Verification:** With no selection, allele frequency is constant. With `p>0` and selection favoring P, expected p rises over generations. With `p=0`, no P appears in the no-mutation model. With `p=1`, P stays fixed. Dominant phenotype frequency is `p²+2p(1−p)`, distinct from allele frequency. No automatic forced endpoint. No mapping of simulation outputs to real ethnic groups or particular geographic areas.

### 7.4 Historical-science cautions
The teacher lesson connects lactase persistence to milk use thousands of years ago and changing culture/environment. This model can illustrate a **possible mechanism of gene–culture coevolution**, not establish a single universal historical cause. Actual regional differences involve multiple variants, ancestry, migration, demography, cultural food processing, ecological factors, and differing historical selection pressures. Lactase nonpersistence is widespread and normal; lactose intolerance symptoms are variable. The reference map is schematic and does not label individual students or groups by presumed genotype.

## 8. Optional concept extension — oral lactase supplement

In Explain mode only, a **Lactase supplement** toggle can add functional enzyme to a low-lactase adult's **digestive contents** and re-run the same lactose amount. It does **not edit DNA, activate LCT, or cause inherited persistence**. This connects to the lesson's medication discussion without becoming a medical advice feature. Represent supplement activity abstractly; no dosing instructions or claims that every product works identically.

This extension is lower priority than the three core modules and Evidence Viewer.

## 9. Godot 4.7 technical architecture

### 9.1 Project organization
```
LactasePersistence/
  project.godot
  Main.tscn
  scenes/
    ModelSelect.tscn
    MoleculeView.tscn
    RegulationView.tscn
    EvidenceView.tscn
    PopulationView.tscn
  scripts/
    main.gd
    models/molecule_model.gd
    models/regulation_model.gd
    models/population_model.gd
    models/evidence_data.gd
    views/molecule_renderer.gd
    views/dna_renderer.gd
    ui/responsive_layout.gd
    ui/keyboard_navigation.gd
    ui/accessibility_options.gd
    web/exit_bridge.gd
  assets/   # locally bundled vectors, textures, icon assets; no external fonts
  tests/
    test_molecules.gd
    test_regulation.gd
    test_population.gd
    test_evidence.gd
    test_keyboard.gd
  CREDITS.md
  README.md
```

Use Godot **Control** containers for buttons/panels, **Node2D** or `_draw()` for molecular and DNA visualizations, and pure **RefCounted** model classes for scientific state so tests do not depend on rendered frame timing. Keep randomness seeded and isolated from the underlying science rules. Godot `RigidBody2D` is **not** required and should not determine whether chemistry occurs; avoid excessive physics bodies. Prefer object pooling/batched drawing for 100+ animated lactose/product sprites. Render only as many visible objects as are informative, while maintaining exact model counters.

A single shared **simulation-state coordinator** can transfer enzyme abundance from regulation to the molecular viewport. The Evidence Viewer is read-only data plus student-selected highlights; it must not modify the genotype model. Population stepping is a separate algorithm and cannot affect present individual cases.

### 9.2 Web hosting specification — binding
The simulator is intended for **sims.mr-miner.com**, served at a site-managed `/g/lactase-persistence/` directory. It must run both in a **same-origin iframe** on `/play/<slug>` and directly in a new tab. These requirements are adapted from `Sims_Site_Hosting_Requirements.md` (originally written for Cell Designer); game-specific names/paths here replace the old project names.

- Godot **4.7.x**, **GDScript**, HTML5 export with `thread_support=false`. Use **GL Compatibility** renderer.
- Use stretch aspect **`expand`**, responsive `size_changed` handling, and leave high-DPI enabled. Test device-pixel ratio **1.5** and a **1180 × 500 CSS px** iframe; also ~360 px-tall constrained frame.
- Leave **top-right 200 × 64 CSS px** clear for site fullscreen overlay.
- Export must contain root `index.html`. Folder name uses only letters/numbers/hyphens/underscores.
- No external libraries, network calls, analytics, accounts, student names, freeform text entry, remote fonts, or embedded external URLs. All data/assets bundled. Browser-local settings permissible, with distinctive `application/config/name = "Lactase Persistence Simulator"`; persistent progress not required.
- No scoring or postMessage of results to host. The **only required host event** is iframe exit.
- No hidden cheats/admin mode or password/PIN.
- Main scene **`Main.tscn`** (exact case).
- If using lean web templates, validate exact Godot 4.7 support before choosing template. 2D-only lean template lacks `OptionButton`, `MenuButton`, `RichTextLabel`, dialogs, and some other APIs; use supported `Button` cycles and simple labels or select a 2D+GUI template. Avoid unsupported emoji, deprecated `Color8` and `Image.create`, `RegEx` in lean build. Export **without debug** and inspect actual Chrome console.
- Keep private notes/screenshots outside project directory. Include necessary `.json`/`.csv` using export include filter.

**Keyboard exit behavior (required by site):** Every interaction keyboard accessible. Trap-free focus ring in sensible visual order. On Escape, first close innermost open overlay/help; otherwise leave game. On Tab beyond final focusable control or Shift+Tab before first, leave. In `_input`, detect focus traversal with exact-match modifier handling (`event.is_action_pressed("ui_focus_next", false, true)`), then release GUI focus and, on web when embedded, call:

```gdscript
get_viewport().gui_release_focus()
if OS.has_feature("web"):
    JavaScriptBridge.eval("if (window.parent !== window) window.parent.postMessage({type: 'sims:leave-game'}, location.origin)")
```

When focus is absent after clicking canvas, Tab moves to first focusable control and Shift+Tab to last. All buttons/sliders show strong visible focus. Do not use `FOCUS_NONE` for focusable controls. In Chrome fullscreen, the browser may consume first Escape; document the expected two-press behavior. Final focus order must be rebuilt after responsive reparenting/layout changes.

### 9.3 Accessibility
Aim for **WCAG 2.2 AA as far as Godot canvas supports**: text contrast ≥4.5:1, focus/icon contrast ≥3:1, targets ≥44×44 CSS px, icon + text/shape and not color alone, large-text option, reduced-motion toggle, never flashing. A running model has Pause; no compulsory timers. At first load nothing moves or sounds until user action. Browser canvas screen-reader limitations must be **honestly documented**; do not claim accessibility without testing. Optional hidden live-region announcer can use a previously proven hosting-site approach if supported, but not required for MVP.

### 9.4 Teacher presets
Allow these validated URL query parameters (optional classroom settings) via `JavaScriptBridge` and `window.location.search` **only** on web. Ignore unknown/out-of-range values; no arbitrary code or string inclusion. README records all supported defaults:
- `model=molecules|regulation|evidence|population` (choice; default `molecules`)
- `mode=explore|explain` (choice; default `explore`)
- `motion=normal|reduced` (choice; default derived from preference when supported, otherwise `normal`)
- `labels=on|off` (choice; default `on`)

Teacher presets are convenience settings, **not authentication**; students may navigate normally.

## 10. Visual asset list

| Asset | Design notes | Priority |
|---|---|---|
| Lactose molecule | Two distinguishable linked sugar shapes; visible bond | Required |
| Glucose | Single distinctive shape, matching one half of lactose | Required |
| Galactose | Different single shape, matching other half | Required |
| Lactase enzyme | One identifiable pocket and bind/release states; not consumed | Required |
| Small intestine / brush-border schematic | Clear location of intestinal enzyme action/absorption | Required |
| Chromosome 2 | Simple banding, zoom target, not a full photorealistic karyotype | Required |
| DNA double helix, unrolled strand | Zoom from chromosome to sequence and regulatory segment | Required |
| Coding vs regulatory region | Strong shape/pattern and labels, not color alone | Required |
| Cell / production indicator | Small intestine cell and lactase quantity icon | Required |
| Population avatars | Diverse silhouettes/skin tones; no phenotype inferred from appearance | Required |
| UI icons | Play, pause, step, home, reset, compare, help, zoom, labels, settings | Required |
| Regional map | Prefer lesson's licensed/teacher-provided reference; no synthetic regional statistics | Optional |
| Lactase supplement illustration | Add enzyme without editing DNA | Optional |

**Implementation:** Provide vector shapes as SVG references if convenient, but rasterize/pre-render to browser-compatible Godot assets where needed; also allow procedural drawing for simple sugars and DNA. Include source licenses and attribution in `CREDITS.md`. No requirement to create elaborate character art.

## 11. Acceptance tests and definition of done

**Scientific tests**
1. Zero lactase, any positive lactose: no generated glucose or galactose.
2. Each modeled cleavage: 1 lactose lost, 1 glucose gained, 1 galactose gained; enzyme remains.
3. Holding time and lactose constant, increasing lactase never decreases conversion in deterministic model.
4. Infant typical and infant persistent states both have substantial lactase activity; adult typical has reduced activity; adult persistent higher; coding-region drawing unchanged.
5. Evidence Viewer displays correct four people, **identical LCT excerpt**, and exactly the assigned one-copy ATT/ACT difference for Alissa.
6. Population `p=0` and `p=1` are fixed endpoints without mutation; neutral selection does not alter p; positive selection increases p for internal frequencies; frequencies sum to 1 to numerical tolerance.
7. No choice by any individual immediately changes inherited DNA or the population gene frequency without generational reproduction.

**Interface and web tests**
8. Load a production HTML export in real Chrome; console has **no SCRIPT ERROR** and a startup log (e.g., `lactase-sim: boot ok`). Do not count a blank grey canvas as success.
9. Verify both standalone tab and same-origin iframe; 1180×500 and 360px-tall cases; DPR 1.5; controls visible/no overlap with top-right overlay.
10. Full keyboard-only operation; all buttons/controls reachable; Tab/Shift+Tab leaves at endpoints, Escape closes overlay and then leaves; no keyboard trap; visible focus.
11. Initial load produces no sound and no decorative motion. Running animations Pause; reduced motion works; text-size setting remains usable.
12. No outbound requests or personal data collection; no score/result messages; `.pck` checked for confidential or extraneous source filenames.
13. README records Godot version, export template, precise tested devices (phone, Chromebook, physical keyboard) or **not yet checked**, keyboard/screen-reader observations, no-autoplay test, and supported URL presets. Credit asset sources. Owner-only registry fields **grade**, **author**, **license** remain for owner confirmation.

## 12. Build order and scope management

**Milestone 1 — Web skeleton:** Godot 4.7 project, main selector, responsive controls, keyboard/exit bridge, actual browser export test. **Do this first**, so web incompatibilities cannot invalidate a finished scientific model.

**Milestone 2 — Molecular model:** pure model with tests, visual scene, hydrolysis animation, counters, two-level comparison, pause/step/reset.

**Milestone 3 — Regulation model:** life-stage and inherited-variant states coupled to the same molecular engine, with clear coding-versus-regulatory distinction.

**Milestone 4 — Evidence viewer:** exact lesson sequences, zoom/pair comparisons, discovery-friendly highlights.

**Milestone 5 — Generations:** deterministic model, controls, graph, compare conditions, tested mathematical invariants.

**Milestone 6 — Polish and verification:** labels/explain mode, accessible layouts, keyboard exit, production export, README and test record.

**Defer to v0.2:** real biochemical kinetics, full pH/temperature modeling, multiple historically specific persistence variants, stochastic drift and migration, custom allele editing, detailed geographic maps, full RNA/protein synthesis animation, disease modeling, multi-user features, scores, learning analytics, school redesign activity.

## 13. Agent handoff instruction

Build this as a **self-contained teaching aid** in Godot 4.7.x, targeting production browser export on `sims.mr-miner.com`. Prioritize the *scientific invariants*, the *uploaded lesson's exact evidence data*, the *pedagogical reveal discipline*, and the *binding hosting/accessibility rules*. Use simple attractive procedural graphics where final vectors are not available. Do not silently add features or claims outside this GDD. Test scientific models independently and test **in a real browser**, not just the editor. If a hosting requirement conflicts with a UI choice, obey the hosting specification and document the change. Hand over Godot source, working release export, tested README, and CREDITS. Do not publish or import to the site; the separate site-management process handles that, initially hidden until owner approves release.

## 14. Source and interpretation notes

**Direct curriculum grounding:** Teacher Materials *Lactase Persistence 5E*, especially overview/5E stages, Explore 1 sample setup and target results, Explore 2 comparison expectations, Explain 2, Elaborate and Evaluate; Student Materials p. 2–3 (map), pp. 5–10 (lab/model), pp. 13–14 (digestive enzyme), pp. 15–21 (DNA comparison), pp. 24–25 (regulatory explanation). The digital molecule, regulation, population, control and test designs are **proposed additions**, not parts already provided by the curriculum.

**Hosting grounding:** `Sims_Site_Hosting_Requirements.md`, dated 2026-11-14, originally targeting Cell Designer; constraints have been retained and project-specific names translated here. That document distinguishes site-binding [SPEC] requirements from strong [advice] recommendations. This GDD treats the former as mandatory and incorporates the latter as default implementation guidance.

**Accuracy clarifications added by this GDD:** distinguish genetic regulatory *DNA* from a regulatory protein-coding *gene*; distinguish lactase nonpersistence from variability in symptomatic lactose intolerance; do not treat all human populations as sharing one exact persistence variant; avoid treating gene frequencies or genotype effects as fully understood from a simple classroom graph; supplement enzyme in gut is not gene therapy.
