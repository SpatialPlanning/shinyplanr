# Plan: "Explore" tab for the Comparison module (`mod_3compare`)

> **Status: design finalised.** All open questions have been resolved with
> the user (see "Final confirmed decisions" section). Ready for
> implementation.

## Goal

Add an interactive Leaflet "Explore" tab to the Comparison module
([`mod_3compare_ui()`](../R/mod_3compare.R:10) /
[`mod_3compare_server()`](../R/mod_3compare.R:561)), modelled on the existing
Explore tab in the Scenario module
([`mod_2scenario_ui()`](../R/mod_2scenario.R:236-259) /
[`mod_2scenario_server()`](../R/mod_2scenario.R:1214-1457)), but supporting two
distinct visualisation modes selected by the user:

1. **Compare** — shows the spatial difference between Scenario 1 and
   Scenario 2 (added / removed / unchanged-selected), mirroring
   [`splnr_plot_comparison()`](../../spatialplanr/R/splnr_plotting.R:833) but
   as an interactive WebGL layer.
2. **Scenario** — shows Scenario 1 and/or Scenario 2's selected planning
   units (plus their lock-in/lock-out constraints) as independently
   toggleable semi-transparent overlays, so the user can see where they
   overlap.

`include_explore` in `shinyplanr_options` will control **both** modules'
Explore tabs (currently it only controls `mod_2scenario`'s).

## Final confirmed decisions (resolved with user)

1. **Click-to-inspect popup**: **INCLUDED** in v1. On click, show a
   lightweight panel with: planning unit ID, selection status in Scenario 1,
   selection status in Scenario 2, and cost value(s).
   > **Updated** (see
   > [`plans/comparison-explore-tab-followups.md`](comparison-explore-tab-followups.md)):
   > a feature list grouped by category (mirroring `mod_2scenario`'s popup)
   > was added in a follow-up change, shown once per planning unit since
   > feature presence is scenario-independent.
2. **Constraints (lock-in/lock-out) overlay**:
   - **Compare mode**: omitted entirely (blue/red already mean added/removed
     here). Constraints remain inspectable via the Details tab tables.
   - **Scenario mode**: **included**, matching `mod_2scenario`'s Explore tab
     behaviour, for BOTH scenarios simultaneously (see colour scheme below).
3. **Scenario-mode colour/opacity scheme** — both scenarios always render
   their full 4-colour scheme (selected / not-selected / locked-in /
   locked-out) at reduced opacity so overlaps remain visually distinguishable;
   if the user can't tell two overlapping colours apart they can toggle a
   scenario's checkbox off:

   | Category      | Scenario 1 colour | Scenario 2 colour | Fill opacity |
   |---------------|--------------------|--------------------|--------------|
   | Selected      | `#7fc97f` (light green) | `#00441b` (dark green) | 0.5 |
   | Locked-in     | `#1f77b4` (blue)   | `#6baed6` (light blue) | 0.5 |
   | Locked-out    | `#d62728` (red)    | `#fb6a4a` (light red/orange) | 0.5 |
   | Not selected  | `#a8a8a8` (grey)   | `#a8a8a8` (grey)   | **0.15** (very transparent) |

   > **Updated** (see
   > [`plans/comparison-explore-tab-followups.md`](comparison-explore-tab-followups.md)):
   > the original Selected colours (`#2ca02c` / `#1b7837`) were too similar
   > to distinguish and were replaced with the light/dark green pair above.

   Priority order within each scenario layer (same as `mod_2scenario`):
   locked-out > locked-in > selected > not-selected.
4. **Coast overlay**: carry over `show_coast_overlay` handling identically to
   `mod_2scenario` (drawn as SVG on top of the WebGL layer), via the new
   shared helper (see decision 6).
5. **Re-add-layer-on-tab-visit pattern**: like `mod_2scenario`, the WebGL
   canvas is destroyed when its tab panel is hidden. The Comparison module's
   `moduleServer` is currently initialised via
   `observeEvent(input$navbar == "Comparison", ..., once = TRUE)` in
   [`app_server.R:43-51`](../R/app_server.R:43-51) **without** a `tab_visible`
   reactive being passed in (unlike `mod_2scenario`/`mod_4afeatures`). This
   will be added.
6. **Shared coast-overlay helper**: extract the duplicated "add coast overlay
   to a leafletProxy chain" logic (currently inline in `mod_2scenario.R` and
   a locally-scoped function in `mod_4afeatures.R`) into one shared
   `fadd_coast_overlay()` helper in `R/utils_leaflet.R`, used by all three
   modules (`mod_2scenario`, `mod_4afeatures`, new `mod_3compare` code). This
   refactor is done **as part of this change**.
7. **Tab `value`**: use a new non-colliding value `"11"` for the Explore tab.
   Existing Comparison tab values (1, 2, 3, 4, 7, 8, 9, 10) are left
   untouched — no renumbering.
8. **Performance**: both Compare and Scenario modes only need to be
   (re-)rendered once both `solution1()` and `solution2()` resolve. Follows
   the same `observeEvent(solution2(), ...)` cache-population pattern already
   used for `ggr_comp_cache` (see
   [`mod_3compare.R:1000-1009`](../R/mod_3compare.R:1000-1009)) to prepare the
   WGS84 map data once per analysis run rather than on every tab visit.

## Implementation steps

### 1. Config / options wiring
- [ ] In [`mod_3compare_server()`](../R/mod_3compare.R:592), add
      `tab_explore = "11"` to the existing `fapply_ui_switches()` call, so
      `include_explore = FALSE` hides the new tab exactly like it does in
      `mod_2scenario`.
- [ ] No new config schema version bump needed — `include_explore` already
      exists; just a new consumer of the same flag. Update the comment at
      [`inst/templates/setup/3_setup_app.R:74`](../inst/templates/setup/3_setup_app.R:74)
      to say "Explore tab (Scenario and Comparison modules)".
- [ ] Add a one-line mention in `NEWS.md` describing the new tab.

### 2. `app_server.R` plumbing for `tab_visible`
- [ ] Mirror the `mod_2scenario` pattern: build
      `tab_visible_3 <- shiny::reactive(input$navbar == "Comparison")` and
      pass it into `mod_3compare_server("3compare_ui_1", cfg, tab_visible =
      tab_visible_3)`.
- [ ] Update `mod_3compare_server()`'s signature to accept `tab_visible` and
      use it in the WebGL re-add observer (see step 5).

### 3. Insert "Explore" tab with a new non-colliding value
Current Comparison tab values: Comparison=1, Scenario=2, Targets=3, Cost=4,
Climate=7, Details=8, Report=10, Log=9. Per confirmed decision #7, the new
Explore tab uses `value = "11"` — no renumbering of existing tabs.
- [ ] Insert new `tabPanel("Explore", value = "11", ...)` as the 2nd tabPanel
      in `mod_3compare_ui()`'s `tabsetPanel`, directly after the "Comparison"
      tabPanel (value = 1) and before "Scenario" (value = 2).
- [ ] Use `tab_explore = "11"` in the `fapply_ui_switches()` call from step 1.

### 4. UI additions ([`mod_3compare_ui()`](../R/mod_3compare.R:10))
New `tabPanel("Explore", value = "11", ...)` containing:
```r
shiny::span(shiny::h2("Explore Map")),
shiny::p("Compare the two scenarios spatially, or inspect each scenario's selected areas and constraints."),
shiny::br(),
shiny::div(
  style = "position: relative;",
  shinycssloaders::withSpinner(
    leaflet::leafletOutput(ns("leaflet_map_explore"), height = "650px")
  ),
  shiny::absolutePanel(
    id = ns("explorePanel"),
    class = "panel panel-default",
    fixed = FALSE,
    draggable = TRUE,
    top = "5%",
    right = "10px",
    width = "260px",
    style = "background-color: rgba(255, 255, 255, 0.9); padding: 10px; border-radius: 5px; max-height: 600px; overflow-y: auto; z-index: 1000;",
    shiny::radioButtons(
      inputId = ns("exploreMode"),
      label = "Display Mode",
      choices = c("Compare" = "compare", "Scenario" = "scenario"),
      selected = "compare"
    ),
    shinyjs::hidden(
      shiny::div(
        id = ns("exploreScenarioToggles"),
        shiny::checkboxInput(ns("showScen1"), "Show Scenario 1", value = TRUE),
        shiny::checkboxInput(ns("showScen2"), "Show Scenario 2", value = TRUE)
      )
    ),
    shiny::hr(),
    shiny::uiOutput(ns("exploreInfoPanelContent"))
  )
)
```
- [ ] Add a `shiny::observeEvent(input$exploreMode, ...)` (server-side) to
      `shinyjs::show/hide("exploreScenarioToggles")` based on mode.
- [ ] `exploreInfoPanelContent` defaults to a placeholder hint ("Click a
      planning unit on the map to see its status in each scenario.") and is
      replaced with the click-to-inspect popup content (step 5) once the user
      clicks.

### 5. Server additions ([`mod_3compare_server()`](../R/mod_3compare.R:561))
Mirror the `mod_2scenario` Explore tab pattern closely:

- [ ] **`comp_map_sf` reactiveVal**: populated by an
      `observeEvent(solution2(), ...)` (fires once both solutions resolve,
      same timing fix already used for `ggr_comp_cache`/`ggr_soln_cache`).
      Builds a single WGS84 sf object with:
      - `pu_id`, `solution_1` (Scenario 1), `solution_2` (Scenario 2 — copied
        in via direct vector assignment like `splnr_plot_comparison()` does),
        using `fprep_wgs84(options$antimeridian)`.
      - Per-scenario lock-in/lock-out flags, analogous to
        `is_locked_in`/`is_locked_out` in
        [`mod_2scenario.R:1287-1323`](../R/mod_2scenario.R:1287-1323),
        computed independently for Scenario 1
        (`get_lockIn(input, num = "1")` / `get_lockOut(input, num = "1")`)
        and Scenario 2 (`num = "2"`) against `raw_sf`, stored as columns
        `is_locked_in1`, `is_locked_out1`, `is_locked_in2`, `is_locked_out2`.
- [ ] **`output$leaflet_map_explore`** — `leaflet::renderLeaflet()` base map,
      created once (same empty-tiles-only pattern as
      [`mod_2scenario.R:1265-1270`](../R/mod_2scenario.R:1265-1270)).
- [ ] **`render_explore_layer()`** helper function (closure over session /
      `comp_map_sf`), parameterised by `mode`, `show_scen1`, `show_scen2`:

  **`mode == "compare"`:**
  - Compute `pu_colour` via `dplyr::case_when()`:
    - `solution_1 == 1 & solution_2 == 1 ~ "#4d4d4d"` (dark grey — both
      selected; darkened from the original `#808080` so it reads clearly
      distinct from the new light "not selected" grey below)
    - `solution_1 == 0 & solution_2 == 1 ~ "#1f77b4"` (blue — added)
    - `solution_1 == 1 & solution_2 == 0 ~ "#d62728"` (red — removed)
    - else `"#a8a8a8"` (light grey — neither selected; same hex as
      `mod_2scenario`'s "Not Selected" colour at
      [`mod_2scenario.R:1381`](../R/mod_2scenario.R:1381), so the two Explore
      sub-tabs are visually consistent)
  - Unlike earlier drafts of this plan, "neither selected" rows are **not**
    filtered out — they're rendered like `mod_2scenario` does, but at a much
    lower opacity so they read as a faint backdrop rather than competing
    with the Compare colours. Split the `leafgl::addGlPolygons()` call in
    two, sharing one `group=` (same split technique used for Scenario mode
    below):
    - Call A: rows where `pu_colour != "#a8a8a8"` (both / added / removed),
      `fillOpacity = 0.5`.
    - Call B: rows where `pu_colour == "#a8a8a8"` (neither selected),
      `fillOpacity = 0.15` — matching the Scenario-mode "Not Selected"
      opacity exactly.
  - Legend: `colors = c("#4d4d4d","#1f77b4","#d62728","#a8a8a8")`,
    `labels = c("Selected in Both", "Added (Scenario 2 only)", "Removed (Scenario 1 only)", "Not Selected")`,
    only including blue/red entries if any such cells exist (mirroring the
    locked-in/out conditional legend logic in
    [`mod_2scenario.R:1385-1396`](../R/mod_2scenario.R:1385-1396)); dark-grey
    and light-grey entries always shown if any matching cells exist. (Note:
    this differs from Scenario mode, which deliberately omits its "Not
    Selected" entry from the legend — Compare mode includes it since it's
    one of only four possible categories here, versus one of several in
    Scenario mode.)
  - No lock-in/lock-out colouring in this mode (confirmed decision #2).

  **`mode == "scenario"`:**
  - Build up to two scenario groups (`"scen1_polygons"` /
    `"scen2_polygons"`), only added when its `show_scenX` checkbox is TRUE.
  - Each scenario layer uses the full 4-colour `dplyr::case_when()` scheme
    from confirmed decision #3, with priority
    locked-out > locked-in > selected > not-selected:
    - Scenario 1: selected `#2ca02c`, locked-in `#1f77b4`, locked-out
      `#d62728`, not-selected `#a8a8a8`.
    - Scenario 2: selected `#1b7837`, locked-in `#6baed6`, locked-out
      `#fb6a4a`, not-selected `#a8a8a8`.
  - `fillOpacity` is **not uniform**: 0.5 for selected / locked-in /
    locked-out rows, but **0.15** for not-selected rows. Since
    `leafgl::addGlPolygons()` takes a single `fillOpacity=` value per call
    (not per-row), split each scenario's layer into two `addGlPolygons()`
    calls sharing the same `group=`:
    - Call A: rows where category != "not-selected", `fillOpacity = 0.5`.
    - Call B: rows where category == "not-selected", `fillOpacity = 0.15`.
    This keeps `leafgl::clearGlLayers()` able to cleanly remove both calls
    for a scenario via its shared `group=`.
  - `leafgl::clearGlLayers()` first to reset state before re-adding the
    selected combination of up to 4 `addGlPolygons()` calls (2 scenarios x
    2 opacity-groups each).
  - Legend entries conditionally include "Scenario 1 Selected / Locked In /
    Locked Out" and "Scenario 2 Selected / Locked In / Locked Out" rows
    matching whichever scenario(s) are currently shown and whichever
    categories actually occur in the data (mirroring the conditional
    legend-building pattern in
    [`mod_2scenario.R:1385-1396`](../R/mod_2scenario.R:1385-1396)). Grey "not
    selected" entries are omitted from the legend for both scenarios to
    avoid clutter (the grey fill itself IS still drawn at low opacity for
    visual context, just not listed in the legend).

  Both branches: use the new shared `fadd_coast_overlay()` helper (step 6)
  instead of an inline block.

- [ ] **Observer**: `observeEvent(list(input$tabs, tab_visible(), input$exploreMode, input$showScen1, input$showScen2), ...)`
      — fires `render_explore_layer()` (via `shinyjs::delay(0, ...)`) whenever
      the Explore tab (`input$tabs == "11"`) is active AND `tab_visible()` is
      TRUE AND `comp_map_sf()` is non-NULL. Mirrors
      [`mod_2scenario.R:1352-1457`](../R/mod_2scenario.R:1352-1457) but adds
      the mode/checkbox reactives to the trigger list.
- [ ] **Mode-switch show/hide observer**: toggles the
      `exploreScenarioToggles` div visibility via `shinyjs::show()`/`hide()`.
- [ ] **Click-to-inspect popup** (confirmed decision #1): click handler for
      `input$leaflet_map_explore_glify_click`, mirroring
      [`mod_2scenario.R:1463-1737`](../R/mod_2scenario.R:1463-1737) but
      simplified:
      - Look up the clicked `pu_id` in `comp_map_sf()`.
      - Build a lightweight panel showing: Planning Unit ID; "Selected in
        Scenario 1: Yes/No"; "Selected in Scenario 2: Yes/No"; cost value for
        Scenario 1's selected cost layer (`input$costid1`) and Scenario 2's
        (`input$costid2`), using the same cost-name lookup logic as
        [`mod_2scenario.R:1546-1566`](../R/mod_2scenario.R:1546-1566).
      - Does NOT show the full feature list (already in the Details tab) —
        keeps the popup short and dual-scenario-friendly.
      - Reuses the same `clearGroup("highlight")` +
        `addPolygons(... group = "highlight")` highlight pattern as
        `mod_2scenario`.
      - Renders into `output$exploreInfoPanelContent` (the `uiOutput()` in
        the `explorePanel`, below the mode/checkbox controls and a
        `shiny::hr()` separator).

### 6. Shared helper extraction (confirmed — part of this change)
- [ ] Extract the repeated "add coast overlay to a leafletProxy chain"
      pattern (currently duplicated inline in `mod_2scenario.R` and as a named
      function `add_coast_overlay()` in `mod_4afeatures.R`) into a single
      `fadd_coast_overlay(proxy, coast_overlay_wgs84, options)` helper in
      `R/utils_leaflet.R`.
- [ ] Update `mod_2scenario.R` to call the shared helper instead of its inline
      block (around
      [`mod_2scenario.R:1439-1455`](../R/mod_2scenario.R:1439-1455)).
- [ ] Update `mod_4afeatures.R` to call the shared helper instead of its local
      `add_coast_overlay()` closure (around
      [`mod_4afeatures.R:190-205`](../R/mod_4afeatures.R:190-205)).
- [ ] Use the shared helper in the new Comparison Explore code (both Compare
      and Scenario modes).
- [ ] Add/extend a test in `tests/testthat/test-utils_leaflet.R` for the new
      helper.

### 7. Documentation & tests
- [ ] Update `inst/templates/setup/3_setup_app.R` comment for
      `include_explore` (step 1).
- [ ] Add `tests/testthat/test-mod_3compare.R` cases:
  - UI contains "Explore" tab, radio button, and checkbox inputs.
  - `include_explore = FALSE` hides tab `"11"` (reuse the pattern from
    `test-mod_2scenario.R` if an equivalent hide-tab test exists there).
  - Mode-switch show/hide observer doesn't error via `testServer()`.
  - Click handler doesn't error with a mocked `glify_click` input.
- [ ] Add a short `NEWS.md` entry describing the new Explore tab in
      Comparison and that `include_explore` now toggles both modules.
- [ ] Update any vignette screenshots/text referencing the Comparison tabs
      if relevant (check `vignettes/images/ComparisonOverlay.png` /
      `vignettes/images/ComparisonScenario.png` — these filenames suggest
      this feature may already be partially documented/anticipated; worth
      checking `vignettes/ab-using-shinyplanr.qmd` for existing text to
      update).

## Implementation order

1. Shared `fadd_coast_overlay()` helper + refactor existing callers (step 6).
2. `app_server.R` `tab_visible` plumbing (step 2).
3. UI tab insertion + radio/checkbox controls (steps 3-4).
4. Server: `comp_map_sf` reactive + `render_explore_layer()` for both modes,
   including the lock-in/out colouring for Scenario mode and the
   click-to-inspect popup (step 5).
5. `fapply_ui_switches()` wiring + option comment updates (step 1).
6. Tests + NEWS.md entry (step 7).
