# Plan: Comparison "Explore" tab follow-up fixes

> Follow-up to [`plans/comparison-explore-tab.md`](comparison-explore-tab.md),
> addressing five issues found after the initial implementation landed in
> [`mod_3compare.R`](../R/mod_3compare.R).
>
> **Status: IMPLEMENTED.** All steps below have been completed and verified
> (`devtools::document()`, `devtools::load_all()`, and the full
> `devtools::test()` suite all pass with 0 failures).

## Round 2 fixes (post-implementation bug reports)

After the above landed, four further issues were reported and fixed:

1. **Duplicate zoom controls** - `onRender()` added a second zoom control at
   bottom-left without suppressing the default top-left one. Fixed by
   constructing the base map with
   `leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = FALSE))`
   so only the bottom-left control (added via `onRender()`) exists.
2. **Legend position** - both `addLegend()` calls in
   `render_explore_layer()` used `position = "bottomright"`; changed to
   `"bottomleft"` so the legend sits next to the zoom control. A scoped CSS
   rule (`inst/app/www/shinyplanr.css`) arranges the
   `.leaflet-bottom.leaflet-left` container as a row instead of Leaflet's
   default column stacking, so the legend appears beside the zoom buttons
   rather than below them.
3. **Duplicate "Planning Unit" headings** - the `planningUnitPanel`
   `absolutePanel` had a static `h4("Planning Unit")` heading *outside* the
   `uiOutput(ns("exploreInfoPanelContent"))`, while the click handler's
   dynamic content also rendered its own `h4("Planning Unit #<id>")`
   *inside* the output - so after a click both were visible. Fixed by
   removing the static heading from the UI and instead rendering the
   default placeholder's heading inside `exploreInfoPanelContent` itself,
   so the dynamic (clicked) content fully replaces it rather than
   supplementing it.
4. **Display Mode panel position** - temporarily moved to top-right during
   this round, then corrected back to **top-left** per clarified
   requirements (left = "10px", no longer offset for a top-left zoom
   control since the zoom control now lives exclusively at bottom-left).
   The Planning Unit panel remains at top-right.

Tests updated in `tests/testthat/test-mod_3compare.R` to match: legend
position assertion changed to `bottomleft`, a new assertion for
`zoomControl = FALSE`, the static "Planning Unit" text assertion removed
from the UI-only test, and a new `testServer()`-based test confirming
`exploreInfoPanelContent` renders exactly one "Planning Unit" heading by
default.

## Issues addressed

1. The two greens used for "Selected" in Scenario mode (`#2ca02c` /
   `#1b7837`) are too similar to tell apart.
2. The "Display Mode" controls (radio buttons + scenario checkboxes) and the
   "Planning Unit" click-to-inspect info are crammed into one
   `absolutePanel`; they should be visually separate panels.
3. Toggling Display Mode / Show Scenario 1 / Show Scenario 2 resets the map
   zoom back to the full fitted bounds, because `render_explore_layer()`
   calls `leaflet::fitBounds()` on every invocation, including re-renders
   triggered by a toggle.
4. On first visit to the Explore tab, the map is zoomed to the whole world
   instead of the area of interest (AOI), because the base map
   (`output$leaflet_map_explore`, `renderLeaflet()`) has no bounds set; the
   AOI fit only happens later, asynchronously, once `comp_map_sf()` is
   populated via `leafletProxy`.
5. The click-to-inspect popup shows planning-unit ID, per-scenario selection
   status, and cost, but no information about which conservation features
   are present in that planning unit (unlike `mod_2scenario`'s Explore tab,
   which shows a feature list grouped by category).

## Decisions confirmed with user

- **Green colours**: Scenario 1 "Selected" -> `#7fc97f` (light green),
  Scenario 2 "Selected" -> `#00441b` (very dark green). Locked-in/out/grey
  colours for both scenarios are unchanged.
- **Feature info in popup**: a single grouped-by-category list of feature
  names present in the clicked planning unit (same style as
  [`mod_2scenario.R`'s click handler](../R/mod_2scenario.R:1670-1681)),
  shown once (features are scenario-independent — only selection/targets
  differ between scenarios, not which features physically occur in a PU).
- **Panel layout** (new, replaces the single `explorePanel`):
  - **Display Mode panel**: moves to **top-left** of the map (`left = "60px"`
    to clear the zoom control, mirroring `mod_4afeatures`'s
    `selectorPanel`). Contains the `exploreMode` radio buttons and the
    `exploreScenarioToggles` checkboxes.
  - **Zoom control**: moved to **bottom-left** (`leaflet::leafletOptions(zoomControl = FALSE)` 
    at map creation + `leaflet::addControl()`/htmlwidgets JS, or simpler:
    use `leaflet::leaflet(options = leaflet::leafletOptions(zoomControl = FALSE))` 
    then re-add via `htmlwidgets::onRender()` JS snippet
    `L.control.zoom({position: 'bottomleft'}).addTo(this)` — avoids needing a
    new package dependency), so it no longer collides with the top-left
    Display Mode panel.
  - **Legend**: nudged right slightly (`leaflet::addLegend(position =
    "bottomleft")` currently sits at the very bottom-left; since zoom moves
    there too, change legend position to a small explicit offset — simplest
    robust option is to keep `position = "bottomleft"` for the legend but
    rely on Leaflet's automatic stacking of bottomleft controls, OR move the
    legend to `"bottomright"` instead, which cleanly avoids any overlap
    with the relocated zoom control without needing custom CSS. **Chosen
    approach: legend -> `position = "bottomright"`.**
  - **Planning Unit info panel**: stays at **top-right** (where the old
    combined panel was), now containing only the click-to-inspect content
    (`exploreInfoPanelContent`).

## Implementation steps

### 1. Colour fix (Scenario mode "Selected")
- [ ] In [`render_explore_layer()`](../R/mod_3compare.R:1847), change
      `colour_selected` for Scenario 1 from `"#2ca02c"` to `"#7fc97f"` and
      for Scenario 2 from `"#1b7837"` to `"#00441b"` (both the
      `add_scenario_layer()` calls and the corresponding
      `legend_colours`/`legend_labels` entries around
      [`mod_3compare.R:2003-2036`](../R/mod_3compare.R:2003-2036)).
- [ ] Update the colour table in
      [`plans/comparison-explore-tab.md`](comparison-explore-tab.md) (the
      "Final confirmed decisions" section, item 3) to reflect the new
      colours, so the design doc and code stay in sync.

### 2. Split "Display Mode" and "Planning Unit" panels
- [ ] In [`mod_3compare_ui()`](../R/mod_3compare.R:10), replace the single
      `explorePanel` `absolutePanel` (lines ~369-402) with two separate
      `absolutePanel`s:
      - `displayModePanel` — `top = "10px"`, `left = "60px"`, `width =
        "260px"` (mirrors `mod_4afeatures`'s `selectorPanel` positioning).
        Contains the `h4("Display Mode")` heading, the `exploreMode`
        `radioButtons()`, and the `shinyjs::hidden(div(id =
        "exploreScenarioToggles", ...))` checkboxes.
      - `planningUnitPanel` — `top = "10px"`, `right = "10px"`, `width =
        "260px"`. Contains a `h4("Planning Unit")` heading and
        `uiOutput(ns("exploreInfoPanelContent"))` only.
      - Both panels keep `draggable = TRUE` and the existing
        semi-transparent white background styling.
- [ ] No server-side changes needed beyond what's already there — the
      `exploreMode`/`showScen1`/`showScen2` input IDs and the
      `exploreInfoPanelContent` output ID are unchanged, only their UI
      container locations move.

### 3. Fix zoom reset on Display Mode / checkbox toggle
- [ ] In [`render_explore_layer()`](../R/mod_3compare.R:1847), remove the
      `leaflet::fitBounds(...)` call from the shared `base_proxy` chain
      (currently lines ~1862-1867) — this chain is rebuilt and re-run every
      time the mode or either checkbox changes, which is what causes the
      zoom reset.
- [ ] Bounds-fitting becomes the sole responsibility of a **new,
      separate observer** that fits bounds only when `comp_map_sf()`
      changes (i.e. once per analysis run) — see step 4, which folds this
      into the first-load fix.

### 4. Fix world-zoom on first Explore tab visit
- [ ] Compute the AOI bounding box once from `raw_sf` at module init
      (mirroring [`mod_4afeatures.R:197-198`](../R/mod_4afeatures.R:197-198)):
      ```r
      aoi_bbox <- sf::st_bbox(fprep_wgs84(raw_sf, options$antimeridian))
      ```
      placed near the existing `coast_overlay_wgs84` setup block (around
      [`mod_3compare.R:1717-1725`](../R/mod_3compare.R:1717-1725)).
- [ ] Apply this bbox directly inside `output$leaflet_map_explore`'s
      `renderLeaflet()` ([`mod_3compare.R:1827-1832`](../R/mod_3compare.R:1827-1832))
      via `leaflet::fitBounds(lng1=, lat1=, lng2=, lat2=)`, exactly like
      `mod_4afeatures` does at map-creation time — so the map is correctly
      framed on the very first paint, independent of solve/analysis timing.
- [ ] CONFIRMED: add a bounds re-fit that fires once per new analysis run,
      keyed on `comp_map_sf()` changing — e.g.
      `observeEvent(comp_map_sf(), { leafletProxy(...) %>% fitBounds(...) })`,
      populated via the existing `observeEvent(solution2(), ...)` pattern.
      This re-fits the zoom to the new solution's bounds every time "Run
      Analysis" is clicked (even if the user is already on the Explore tab
      with a custom zoom/pan), while Display Mode / scenario-checkbox
      toggles never trigger a re-fit (see step 3).

### 5. Add feature information to the click-to-inspect popup
- [ ] In the `observeEvent(input$leaflet_map_explore_glify_click, ...)`
      handler ([`mod_3compare.R:2092`](../R/mod_3compare.R:2092)), after
      looking up `pu_row`, replicate the feature-lookup logic from
      `mod_2scenario.R`'s click handler
      ([`mod_2scenario.R:1482-1505`](../R/mod_2scenario.R:1482-1505)):
      - Use the union of `targetData1()$feature` and `targetData2()$feature`
        (both scenarios' target feature lists) isolated via `shiny::isolate()`,
        since feature presence in a PU is scenario-independent but the two
        scenarios may have selected different feature subsets to target.
      - Filter to columns present in `pu_row` with value `== 1`.
      - Look up `nameCommon`/`category` from `Dict`.
      - Group by category into the same `shiny::tagList()` pattern as
        `mod_2scenario.R:1670-1681`.
- [ ] Append this as a new "Feature List" section to `new_content` (after
      the existing Cost section, mirroring the section order in
      `mod_2scenario`'s popup: Selected status -> Constraints -> Cost ->
      Feature List). Show "No features with targets found in this planning
      unit." when empty, same as `mod_2scenario`.
- [ ] Update [`plans/comparison-explore-tab.md`](comparison-explore-tab.md)'s
      "Final confirmed decisions" item 1 (click-to-inspect popup) to note
      that a feature list was added in this follow-up.

### 6. UI tidy-up for panel/control relocation
- [ ] CONFIRMED approach: in `output$leaflet_map_explore`'s
      `renderLeaflet()`, append the project's established
      `htmlwidgets::onRender()` snippet to relocate the zoom control to
      bottom-left:
      ```r
      htmlwidgets::onRender(
        "function(el, x) {
          L.control.zoom({ position: 'bottomleft' }).addTo(this);
        }"
      )
      ```
      Leaflet adds a second zoom control here rather than moving the
      default one; if a duplicate top-left control is visible after this
      change, also set `leaflet::leafletOptions(zoomControl = FALSE)` when
      constructing the base `leaflet::leaflet()` call to suppress the
      default control first.
- [ ] Change `leaflet::addLegend(position = "bottomleft", ...)` to
      `position = "bottomright"` in both the Compare-mode and Scenario-mode
      branches of `render_explore_layer()`.

### 7. Tests
- [ ] Update `tests/testthat/test-mod_3compare.R`:
      - UI test: assert both `displayModePanel`/`planningUnitPanel` ids (or
        equivalent) exist instead of the single `explorePanel`.
      - Colour assertions (if any existing test checks hex values) updated
        to the new greens.
      - Click-handler test: assert the feature list section appears in
        `exploreInfoPanelContent` output for a mocked `glify_click` input
        with known feature columns.
- [ ] Add/extend a test confirming `renderLeaflet()`'s initial map includes
      a `fitBounds` call with the AOI bbox (or equivalent assertion against
      the htmlwidget's `x$setView`/`x$fitBounds` call list via
      `leaflet::leaflet() %>% ...` inspection, matching how
      `test-mod_4afeatures.R` verifies this if such a test already exists —
      check first).
- [ ] Add a short `NEWS.md` entry summarising the five fixes.

## Implementation order

1. Colour fix (step 1) — trivial, no dependencies.
2. Feature-info popup addition (step 5) — independent of UI layout changes.
3. UI panel split (step 2) + zoom control/legend relocation (step 6) —
   done together since they affect the same UI block.
4. Zoom-reset fix (step 3) + first-visit AOI fit (step 4) — done together
   since step 4's new observer subsumes step 3's bounds-fitting concern.
5. Tests + NEWS.md entry (step 7).
