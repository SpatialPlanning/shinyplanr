# shinyplanr — Comprehensive Code Review

**Reviewed by:** Zoo (Architect mode)  
**Date:** 2026-06-15  
**Scope:** Full R package source — all modules, utilities, config system, template generator, and tests.

---

## Executive Summary

The app is well-structured as a golem package with a clean config-driven deployment model. The separation of concerns between the package (UI/server logic) and the deployment project (data, config, content) is sound. However, there are **several bugs that will cause runtime errors**, significant **code duplication** that creates maintenance risk, and a number of **architectural inconsistencies** that should be addressed before the tool is used widely with stakeholders.

Issues are grouped by severity: **Critical** (will break at runtime), **Major** (incorrect behaviour or serious maintenance risk), and **Minor** (style, robustness, or improvement opportunities).

---

## 1. Critical Bugs

### 1.1 `utils_controlslider.R` is a runnable Shiny app, not a utility file

**File:** [`R/utils_controlslider.R`](R/utils_controlslider.R:1)

This file contains a complete, standalone Shiny app (`library(shiny)`, `ui <- pageWithSidebar(...)`, `server <- function(...)`, `shinyApp(...)`). It is **not** a utility function — it appears to be a scratch/prototype file that was accidentally committed. Because it calls `library(shiny)` at the top level and defines `ui` and `server` as global objects, it will:

- Pollute the package namespace with `ui` and `server` objects.
- Trigger `R CMD CHECK` warnings/errors.
- Potentially conflict with the actual app's `ui`/`server` objects.

**Fix:** Delete this file entirely. If the slider-linking logic is needed, extract it as a documented internal function.

---

### 1.2 `fDownloadPlotServer()` never returns its value

**File:** [`R/utils_server.R`](R/utils_server.R:329)

```r
fDownloadPlotServer <- function(input, gg_id, gg_prefix, time_date, width = 19, height = 18) {
  ...
  dlPlot <- shiny::downloadHandler(...)
  # <-- no return(dlPlot) !
}
```

The function constructs a `downloadHandler` and assigns it to `dlPlot`, but **never returns it**. Every call site assigns the result to `output$dlPlotN`:

```r
output$dlPlot1 <- fDownloadPlotServer(input, gg_id = plot_data1(), ...)
```

Because the function returns `NULL` invisibly, **all download buttons are broken** — they are assigned `NULL` instead of a `downloadHandler`. This affects every download button in both `mod_2scenario` and `mod_3compare`.

**Fix:** Add `return(dlPlot)` at the end of both branches of the function.

---

### 1.3 `mod_3compare_server()` references undefined `switchMinSet`

**File:** [`R/mod_3compare.R`](R/mod_3compare.R:406)

```r
if (options$obj_func == "min_set") {
  shinyjs::show(id = "switchMinSet")   # <-- this div does not exist in the UI
} else {
  shinyjs::hide(id = "switchMinSet")
}
```

There is no `div(id = ns("switchMinSet"), ...)` in [`mod_3compare_ui()`](R/mod_3compare.R:10). The commented-out block in `mod_2scenario_ui` shows this was intentionally removed, but the server-side `show/hide` call was not cleaned up. This will produce a JavaScript error in the browser console every time the Compare module loads with `obj_func = "min_set"`.

**Fix:** Remove the `switchMinSet` show/hide block from `mod_3compare_server()`.

---

### 1.4 `mod_4features_server()` accesses `input$checkFeat` outside a reactive context

**File:** [`R/mod_4features.R`](R/mod_4features.R:152)

```r
if (input$checkFeat == "Cost_None") {   # <-- outside any reactive/observer
  pl_title <- " "
} else {
  pl_title <- Dict %>% ...
}
```

This `if` block runs at module initialisation time, **outside** any `reactive()`, `observe()`, or `observeEvent()`. Accessing `input$checkFeat` outside a reactive context will throw:

> `Error: Can't access reactive value 'checkFeat' outside of reactive consumer.`

The `pl_title` variable is then used inside `plotFeature <- shiny::reactive({...})` below, but by then it is a stale non-reactive value. The feature title will never update when the user changes the dropdown.

**Fix:** Move the `pl_title` computation inside the `plotFeature` reactive.

---

### 1.5 `fresetSlider()` references `Dict` from the global environment

**File:** [`R/utils_server.R`](R/utils_server.R:248)

```r
fresetSlider <- function(session, input, output, id = 1) {
  ...
  sld <- fcreate_vars(id = id,
                      Dict = Dict,   # <-- bare `Dict`, not passed as argument
                      ...)
}
```

`Dict` is not a parameter of `fresetSlider()` and is not in scope when this function is called from a module server. It relies on `Dict` being available in the calling environment via lexical scoping, which is fragile and will fail if the function is ever called from a context where `Dict` is not in scope. The `resetSlider` button in `mod_3compare` calls this function, and it will fail if `Dict` is not found.

**Fix:** Add `Dict` as an explicit parameter to `fresetSlider()` and update all call sites.

---

### 1.6 `mod_2scenario_server()` — `observeEvent` on `input$analyse` re-registers `output$dlReport` on every click

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:1127)

```r
observeEvent(input$analyse, {
  output$dlReport <- shiny::downloadHandler(...)
}, ignoreInit = TRUE)
```

Re-assigning `output$dlReport` inside an `observeEvent` that fires on every analysis run is an anti-pattern. Shiny does not cleanly replace output handlers — this can lead to memory leaks and unpredictable behaviour on repeated runs. The same pattern exists in `mod_3compare_server()` for `output$downloadReportCompare`.

**Fix:** Register the `downloadHandler` once, outside the `observeEvent`. Use `shiny::req(input$analyse > 0)` inside the handler's `content` function to guard against premature downloads.

---

### 1.7 `switchBoundaryPenalty` div uses `id` instead of `ns("switchBoundaryPenalty")`

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:136)

```r
shinyjs::hidden(div(
  id = ns("switchBoundaryPenalty"),
  shiny::h4("Boundary Penalty"),
  shiny::numericInput(
    inputId = id,   # <-- should be ns("boundaryPenalty") or similar
    ...
  )
))
```

The `numericInput` inside the boundary penalty panel uses `inputId = id` (the raw module namespace string, e.g. `"2scenario_ui_1"`) instead of a namespaced input ID like `ns("boundaryPenalty")`. This means the input will not be accessible as `input$boundaryPenalty` in the server, and the input ID will collide with the module's own namespace ID.

**Fix:** Replace `inputId = id` with `inputId = ns("boundaryPenalty")` (or whatever the intended input name is).

---

## 2. Major Issues

### 2.1 Module server initialisation pattern is fragile and causes repeated re-initialisation

**File:** [`R/app_server.R`](R/app_server.R:28)

```r
shiny::observe({
  if (options$mod_1welcome == TRUE && shiny::req(input$navbar) == "Welcome") {
    mod_1welcome_server("1welcome_ui_1", cfg)
  }
  if (shiny::req(input$navbar) == "Scenario") {
    mod_2scenario_server("2scenario_ui_1", cfg)
  }
  ...
})
```

Calling `moduleServer()` inside an `observe()` that re-fires every time `input$navbar` changes means **the module server is re-initialised every time the user navigates to that tab**. This creates duplicate observers, duplicate reactive values, and memory leaks. The correct pattern is to call `moduleServer()` once unconditionally (or use `shiny::bindEvent()` with `once = TRUE`).

The intent (lazy initialisation) is good, but the implementation is wrong. The standard golem approach is to call all module servers unconditionally at startup.

**Fix:** Either call all module servers unconditionally in `app_server()`, or use `shiny::observeEvent(input$navbar == "Scenario", { mod_2scenario_server(...) }, once = TRUE)` to ensure each module is only initialised once.

---

### 2.2 Massive code duplication between `mod_2scenario` and `mod_3compare`

The Scenario and Compare modules share almost identical logic for:
- Defining the problem (`fdefine_problem`)
- Solving with log (`fsolve_with_log`)
- Plotting solutions, targets, costs, climate
- Downloading spatial files (the `dlSpatial` handlers are copy-pasted verbatim)
- Generating reports

The spatial download handler (renaming `solution_1` → `solution`, transforming to WGS84, writing GeoJSON) is duplicated **three times** across the two modules. The report generation block (~130 lines) is duplicated in full.

**Fix:** Extract the spatial download logic into a helper function (e.g., `fdownload_solution_geojson(sol, filename)`). Extract the report generation logic into a helper function. This is the single largest maintenance risk in the codebase.

---

### 2.3 `fget_feature_representation()` does not handle `NULL` climate_id safely

**File:** [`R/utils_server.R`](R/utils_server.R:126)

```r
fget_feature_representation <- function(soln, problem_data, targets, climate_id, options, Dict) {
  if (!inherits(soln, "sf")) return(NULL)
  
  if (climate_id == "NA") {   # <-- will error if climate_id is NULL
```

If `climate_id` is `NULL` (which can happen when `include_climateChange = FALSE` and the input has never been set), the comparison `climate_id == "NA"` will return `logical(0)` rather than `TRUE`, causing the wrong branch to execute. The calling code in `mod_2scenario_server` guards against this with a `clim_val` check, but `fget_feature_representation` itself is not safe.

**Fix:** Change the check to `is.null(climate_id) || climate_id == "NA"`.

---

### 2.4 `fcreate_vars()` uses `targetMax = min(...)` for category sliders — likely a typo

**File:** [`R/utils_ui.R`](R/utils_ui.R:59)

```r
vars <- vars %>%
  dplyr::summarise(
    ...
    targetMin = min(.data$targetMin, na.rm = TRUE),
    targetMax = min(.data$targetMax, na.rm = TRUE),   # <-- should be max()?
    ...
  )
```

When collapsing to category-level sliders (`byCategory = TRUE`), `targetMax` is computed as `min()` of all individual `targetMax` values. This means the category master slider's maximum will be the *lowest* maximum across all features in that category, which is almost certainly wrong. It should be `max(.data$targetMax, na.rm = TRUE)`.

**Fix:** Change `targetMax = min(...)` to `targetMax = max(...)`.

---

### 2.5 `mod_3compare` — `ggr_DataPlot` references `Class` column that doesn't exist

**File:** [`R/mod_3compare.R`](R/mod_3compare.R:1180)

```r
ggr_DataPlot <- shiny::reactive({
  dat <- DataTabler() %>%
    dplyr::mutate(Class = as.factor(.data$Class)) %>%   # <-- 'Class' doesn't exist
    dplyr::group_by(.data$Class) %>%
    dplyr::group_split()
```

The `DataTabler()` reactive in `mod_3compare` produces a data frame with columns `Category`, `Feature`, `Protection 1 (%)`, etc. There is no `Class` column. This reactive will error when called. (The equivalent in `mod_2scenario` correctly uses `Category`.)

**Fix:** Replace `.data$Class` with `.data$Category`.

---

### 2.6 `mod_4features_ui()` uses un-namespaced `tabsetPanel` ID

**File:** [`R/mod_4features.R`](R/mod_4features.R:28)

```r
tabsetPanel(
  id = "tabs4",   # <-- not namespaced with ns()
  ...
)
```

Similarly in `mod_6help_ui()`:

```r
tabsetPanel(
  id = "tabs5",   # <-- not namespaced
  ...
)
```

Using un-namespaced IDs inside a Shiny module means these IDs are global. If two instances of these modules were ever created (unlikely but possible), they would conflict. More importantly, any server-side `updateTabsetPanel()` call targeting these IDs would need to use the raw string rather than `ns("tabs4")`, which is inconsistent with the rest of the codebase.

**Fix:** Use `id = ns("tabs4")` and `id = ns("tabs5")`.

---

### 2.7 `app_server.R` — `input$sidebar_button` observer references a commented-out UI element

**File:** [`R/app_server.R`](R/app_server.R:12)

```r
observeEvent(input$sidebar_button, {
  shinyjs::toggle(...)
  shinyjs::runjs(...)
})
```

The `sidebar_button` action button is commented out in both `mod_2scenario_ui` and `app_ui`. This observer will never fire but adds dead code and confusion.

**Fix:** Remove this `observeEvent` block, or uncomment and implement the sidebar toggle feature properly.

---

### 2.8 `fdefine_problem()` — locked-in/out constraints use `rlang::eval_tidy(rlang::parse_expr(...))` unnecessarily

**File:** [`R/fdefine_problem.R`](R/fdefine_problem.R:227)

```r
for (idx in 1:length(LI)){
  p1 <- p1 %>%
    prioritizr::add_locked_in_constraints(as.logical(
      rlang::eval_tidy(rlang::parse_expr(paste0("raw_sf$", LI[idx])))
    ))
}
```

Using `rlang::parse_expr` + `eval_tidy` to access a column by name is unnecessary and fragile. The idiomatic R approach is simply `raw_sf[[LI[idx]]]`. The `parse_expr` approach is also a potential injection vector if `LI[idx]` ever contains unexpected characters.

**Fix:** Replace with `as.logical(raw_sf[[LI[idx]]])`.

---

### 2.9 `fget_targets()` uses `rlang::eval_tidy(rlang::parse_expr(...))` to read slider inputs

**File:** [`R/utils_server.R`](R/utils_server.R:45)

```r
targets <- ft %>%
  purrr::map(\(x) rlang::eval_tidy(rlang::parse_expr(paste0("input$", paste0(name_check, x))))) %>%
```

Same pattern as above — using `parse_expr` to access `input$sli_featureName` is unnecessary. The idiomatic approach is `input[[paste0(name_check, x)]]`.

**Fix:** Replace with `purrr::map(\(x) input[[paste0(name_check, x)]])`.

---

### 2.10 `3_setup_app.R` template — `raw_sf` construction drops geometry then re-adds it unsafely

**File:** [`R/create_template.R`](R/create_template.R:922)

```r
raw_sf <- dat_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::select(tidyselect::all_of(vars))   # plain data frame, no geometry

...

raw_sf <- raw_sf %>%
  dplyr::bind_cols(dat_sf %>% dplyr::select(geometry)) %>%
  sf::st_as_sf()
```

This pattern assumes `dat_sf` and `raw_sf` have the same row order after the `select` and `filter` operations. If any rows were dropped (e.g., by the zero-column removal step), `bind_cols` will silently produce a misaligned sf object. The zero-column removal step modifies `raw_sf` but not `dat_sf`, so the geometry re-attachment could be misaligned.

**Fix:** Use `sf::st_geometry(raw_sf) <- sf::st_geometry(dat_sf)` (which requires same row count and is explicit), or restructure to keep geometry throughout.

---

## 3. Minor Issues / Improvements

### 3.1 Inconsistent use of `shiny::` namespace prefix

Some files use fully-qualified `shiny::observeEvent(...)` while others use bare `observeEvent(...)`. For example, [`mod_3compare.R`](R/mod_3compare.R:364) uses `moduleServer(id, ...)` without the `shiny::` prefix, while [`mod_2scenario.R`](R/mod_2scenario.R:362) uses `shiny::moduleServer(...)`. The `@import shiny` directive in `app_ui.R` and `app_server.R` makes bare calls work, but consistency is better practice.

---

### 3.2 `analysisTime` reactive is unnecessarily wrapped in a reactive

**Files:** [`R/mod_2scenario.R`](R/mod_2scenario.R:612), [`R/mod_3compare.R`](R/mod_3compare.R:531)

```r
analysisTime <- shiny::reactive({
  analysisTime <- format(Sys.time(), "%Y%m%d%H%M%S")
}) %>% shiny::bindEvent(input$analyse)
```

The variable name inside the reactive shadows the outer variable name, which is confusing. More importantly, `Sys.time()` is called at reactive evaluation time, not at button-click time, so the timestamp may drift slightly from the actual analysis time. A `reactiveVal` updated inside the `observeEvent(input$analyse, ...)` block would be cleaner.

---

### 3.3 `disconnectMessage` is placed in both `mod_2scenario` and `mod_3compare` main panels

**Files:** [`R/mod_2scenario.R`](R/mod_2scenario.R:188), [`R/mod_3compare.R`](R/mod_3compare.R:185)

`shinydisconnect::disconnectMessage()` should be placed once in the app-level UI (e.g., in `app_ui.R`'s `header` tagList), not duplicated in every module. Having it in multiple modules means it could render multiple times.

---

### 3.4 `mod_2scenario_server()` — `plot_data1`, `gg_Target`, etc. initialised as `NULL` then assigned with `<<-`

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:618)

```r
plot_data1 <- NULL
gg_Target <- NULL
...

observeEvent(..., {
  plot_data1 <<- shiny::reactive({ ... })
  ...
})
```

Using `<<-` to assign reactives from inside `observeEvent` blocks is an anti-pattern. It makes the reactive graph hard to reason about and can cause issues with Shiny's dependency tracking. The report generation code then checks `if (is.function(plot_data1))` to detect whether the reactive has been assigned, which is fragile.

**Fix:** Initialise these as `reactiveVal(NULL)` and update them properly, or restructure so the reactives are defined unconditionally and guarded with `shiny::req()`.

---

### 3.5 `mod_2scenario_server()` — duplicate `observeEvent(input$analyse, ...)` for tab reset and scroll

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:436)

```r
shiny::observeEvent(input$analyse, {
  shiny::updateTabsetPanel(session, "tabs", selected = 1)
})

shiny::observeEvent(input$analyse, {
  shinyjs::runjs("window.scrollTo(0, 0)")
})
```

Two separate `observeEvent` blocks for the same trigger. These should be combined into one.

---

### 3.6 `fCheckFeatureNo()` does not account for geometry column

**File:** [`R/utils_server.R`](R/utils_server.R:267)

```r
fCheckFeatureNo <- function(dat) {
  f_no <- dat %>%
    dplyr::select(-tidyselect::starts_with("Cost_"), -tidyselect::any_of("metric")) %>%
    ncol()
  return(f_no)
}
```

This counts all columns except those starting with `Cost_` and `metric`. It does not exclude the geometry column. For an `sf` object, `ncol()` includes the geometry column (named `geometry` by default), so `f_no` will always be at least 1 even when there are no features. The check `if (f_no == 1)` in `fdefine_problem` is therefore checking "only geometry column remains", which is correct by accident but fragile — if the geometry column is named differently, this breaks.

**Fix:** Use `ncol(sf::st_drop_geometry(dat))` or explicitly exclude the geometry column.

---

### 3.7 `validate_shinyplanr_data()` — check 2 uses `attr(raw_sf, "sf_column")` which may return `NULL`

**File:** [`R/validate_config.R`](R/validate_config.R:117)

```r
raw_cols <- setdiff(names(raw_sf), attr(raw_sf, "sf_column"))
```

`attr(raw_sf, "sf_column")` returns the name of the active geometry column (e.g., `"geometry"`). However, the standard way to get this is `attr(raw_sf, "sf_column")` which is correct for `sf` objects. But if `raw_sf` is not a proper `sf` object (e.g., a plain data frame that passed the `inherits(raw_sf, "sf")` check somehow), this could return `NULL`, and `setdiff(names(raw_sf), NULL)` would return all column names including geometry. The safer approach is `names(sf::st_drop_geometry(raw_sf))`.

---

### 3.8 `mod_5coverage` — `fcalculate_coverage()` assumes binary (0/1) feature values

**File:** [`R/utils_coverage.R`](R/utils_coverage.R:130)

```r
total_amount <- sum(feat_values == 1, na.rm = TRUE)
absolute_held <- sum(feat_values[is_covered] == 1, na.rm = TRUE)
```

This assumes all feature columns contain binary 0/1 values. If any feature column contains continuous values (e.g., proportional habitat suitability), the coverage calculation will be incorrect. The `validate_shinyplanr_data()` function does not enforce binary features. This should either be documented as a constraint or the calculation should use `sum(feat_values, na.rm = TRUE)` for continuous features.

---

### 3.9 `mod_2scenario` — `fSolnText()` called with `input$costid` which may be `"Cost_None"`

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:678)

```r
soln_text <- fSolnText(input, solution(), input$costid)
if (input$costid != "Cost_None") {
  paste(tx_2solution, soln_text[[1]], soln_text[[2]])
} else {
  paste(tx_2solution, soln_text[[1]])
}
```

`fSolnText()` is called with `cost_name = input$costid` even when `costid == "Cost_None"`. Inside `fSolnText()`, the check `if (!all(c(cost_name, col_name) %in% names(s_no_geom)))` will catch this and return early, but the function still computes `totalCost` and `outsideCost` using `"Cost_None"` as a column name before the guard. The guard is on line 39 but `totalCost` is computed on line 46 — the guard is in the right place, but the logic flow is confusing.

---

### 3.10 `create_shinyplanr_template()` — `3_setup_app.R` template accesses internal `:::`

**File:** [`R/create_template.R`](R/create_template.R:999)

```r
"  schema_version = shinyplanr:::.shinyplanr_schema_version,"
```

The generated `3_setup_app.R` script uses `:::` to access an internal constant. While this works, it is fragile — if the internal name changes, the generated script silently breaks. A better approach is to export a public function like `shinyplanr::schema_version()` or document that users should use the integer directly.

---

### 3.11 `mod_2scenario` — `observeEvent` trigger expressions use `|` instead of `||`

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:632)

```r
observeEvent(
  {
    input$tabs == 1 | input$tabs == 10 | input$analyse > 0
  },
  { ... }
)
```

Using `|` (vectorised OR) instead of `||` (short-circuit OR) inside an `observeEvent` trigger is technically fine for scalar values, but `||` is the conventional and safer choice for logical conditions. More importantly, this pattern means the plot observer fires whenever **any** of these conditions changes — including when `input$tabs` changes to a different tab. This causes unnecessary re-computation.

---

### 3.12 `mod_3compare` — `fplot_climate_density()` passes `solution_names = c("solution_1", "solution_1")`

**File:** [`R/mod_3compare.R`](R/mod_3compare.R:1035)

```r
ggClimDens <- fplot_climate_density(
  soln_list = list(solution1(), solution2()),
  climate_ids = c(input$climateid1, input$climateid2),
  solution_names = c("solution_1", "solution_1")   # both named the same
)
```

Both solutions are passed with the same `solution_names` value `"solution_1"`. If `splnr_plot_climKernelDensity` uses these names as legend labels, the two scenarios will be indistinguishable in the plot. They should be `c("Scenario 1", "Scenario 2")` or similar.

---

### 3.13 `DESCRIPTION` — `renv` listed as an `Imports` dependency

**File:** [`DESCRIPTION`](DESCRIPTION:55)

```
renv,
```

`renv` is a project-management tool, not a package that should be imported by a Shiny app package. It is used in the generated deployment project, not in the package itself. Listing it in `Imports` means it will be installed as a dependency of `shinyplanr`, which is unnecessary and potentially confusing.

**Fix:** Remove `renv` from `Imports`. It is already handled in the generated `1_setup_enviro.R`.

---

### 3.14 `mod_2scenario` — `solution()` is called inside `output$logText` render, causing double-solve

**File:** [`R/mod_2scenario.R`](R/mod_2scenario.R:594)

```r
output$logText <- shiny::renderText({
  solution()  # Trigger the solve
  log <- solveLog()
  ...
})
```

The comment says "Force solution() to run when on log tab". But `solution()` is already bound to `input$analyse` via `bindEvent`. Calling `solution()` inside `renderText` creates an additional reactive dependency, meaning the log text will re-render whenever `solution()` invalidates. This is redundant and could cause the solver to run twice in some edge cases.

---

## 4. Testing Gaps

### 4.1 Test for `mod_2scenario` checks for `"switchClimSmart"` which doesn't exist

**File:** [`tests/testthat/test-mod_2scenario.R`](tests/testthat/test-mod_2scenario.R:75)

```r
expect_match(html, "switchClimSmart", fixed = TRUE)
```

The actual div ID in `mod_2scenario_ui` is not `"switchClimSmart"` — the climate section is rendered conditionally with `if (isTRUE(options$include_climateChange)) { div(...) }` and has no explicit `id`. This test will always fail.

---

### 4.2 No tests for `fdefine_problem()`, `fsolve_with_log()`, or `fsolve_problem()`

The core prioritisation logic has no unit tests. These are the most critical functions in the app and should have tests covering:
- Correct problem construction for `min_set` and `min_shortfall`
- Climate-smart path
- Lock-in/lock-out constraints
- Error handling when no features are selected

---

### 4.3 No tests for `validate_shinyplanr_data()`

The validation function has no tests despite being a public exported function with complex logic.

---

### 4.4 No tests for `create_shinyplanr_template()`

The template generator has no tests. At minimum, it should be tested that it creates the expected directory structure and files.

---

### 4.5 `helper-config.R` silently skips missing keys

**File:** [`tests/testthat/helper-config.R`](tests/testthat/helper-config.R:13)

```r
if (exists(nm, envir = pkg_env, inherits = FALSE)) {
  cfg_env[[nm]] <- get(nm, envir = pkg_env, inherits = FALSE)
}
```

If a required key is missing from `sysdata.rda`, it is silently skipped. Tests that depend on that key will then fail with cryptic errors rather than a clear "missing config key" message.

---

## 5. Architecture / Design Observations

### 5.1 The `bar_theme` config key is stored but never used

**File:** [`R/config_schema.R`](R/config_schema.R:27)

`bar_theme` is listed as a required key in `.shinyplanr_required_keys` and is built in `3_setup_app.R`, but no module ever extracts or uses `cfg$bar_theme`. It is dead configuration.

---

### 5.2 `vars` config key is stored but its purpose is unclear

`vars` is a required config key (a character vector of column names from `Dict`). It is stored in the config but modules use `Dict` directly to derive column names. The `vars` key appears to be a redundant pre-computed subset of `Dict$nameVariable`.

---

### 5.3 The `mod_7multiobj` module is a complete placeholder

**File:** [`R/mod_7multiobj.R`](R/mod_7multiobj.R:1)

The multi-objective optimisation module is entirely empty (no UI content, no server logic). It is referenced in `app_server.R` (line 38-40) but the corresponding tab is commented out in