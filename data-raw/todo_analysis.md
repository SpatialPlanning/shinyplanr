# TODO Analysis — shinyplanr + spatialplanr

> Generated: 2026-06-17 | Last updated: 2026-06-17
> Scope: all `TODO`, `FIXME`, `HACK`, `XXX`, `BUG`, `REVIEW` comments found in
> `shinyplanr/R/`, `shinyplanr/inst/`, and `spatialplanr/R/` +
> `spatialplanr/data-raw/`.

---

## Summary table

| # | File | Location | Group | Status | Priority |
|---|------|----------|-------|--------|----------|
| 1 | `R/fdefine_problem.R:37` | `fdefine_problem()` | Climate API | Deferred (climate work paused) | Medium |
| 2 | `R/fdefine_problem.R:62` | `fdefine_problem()` | Climate API | Deferred (climate work paused) | High |
| 3 | `R/fdefine_problem.R:68` | `fdefine_problem()` | Climate API | Deferred (climate work paused) | High |
| 4 | `R/fdefine_problem.R:172` | `fdefine_problem()` | Performance | ✅ Done — replaced with explanatory comment | Low |
| 5 | `R/utils_data.R:216` | `fget_feature_representation()` | Feature filtering | Deferred (needs investigation) | Medium |
| 6 | `R/mod_2scenario.R:70` | `mod_2scenario_ui()` | UI / Bioregions | ✅ Done — replaced with explanatory comment | Medium |
| 7 | `R/mod_2scenario.R:360` | `mod_2scenario_server()` | Category filtering | Deferred | Low |
| 8 | `R/mod_2scenario.R:606` | `mod_2scenario_server()` | Plot scaling | Deferred (needs example) | Low |
| 9 | `R/mod_3compare.R:740` | `mod_3compare_server()` | Dictionary text | ✅ Done — TODO removed | Low |
| 10 | `R/mod_4features.R:161` | `mod_4features_server()` | Type lookup | ✅ Done — replaced with explanatory comment | Medium |
| 11 | `R/create_template.R:704` | `fwrite_setup_data_script()` | Template stubs | Already correct | None |
| 12 | `R/create_template.R:708` | `fwrite_setup_data_script()` | Template stubs | Already correct | None |
| 13 | `R/create_template.R:712` | `fwrite_setup_data_script()` | Template stubs | Already correct | None |
| 14 | `R/create_template.R:747` | `fwrite_setup_data_script()` | Template stubs | Already correct | None |
| 15 | `R/create_template.R:803` | `fwrite_setup_data_script()` | Template stubs | Already correct | None |
| 16 | `R/create_template.R:1283` | `fwrite_dict_csv()` | Template stubs | Already correct | None |
| 17 | `../spatialplanr/R/splnr_gg_add.R:183` | `splnr_gg_add()` | API cleanup | Needs investigation | Low |
| 18 | `../spatialplanr/R/splnr_plotting_climate.R:287` | `splnr_plot_climKernelDensity_Fancy()` | Assertions | Needs fix | Medium |
| 19 | `../spatialplanr/R/splnr_plotting_climate.R:309` | `splnr_plot_climKernelDensity_Fancy()` | Assertions | Needs fix | Medium |
| 20 | `../spatialplanr/R/splnr_plotting_climate.R:331` | `splnr_plot_climKernelDensity_Fancy()` | Package check | Needs fix | Low |
| 21 | `../spatialplanr/R/splnr_get_MPAs.R:115` | `splnr_get_MPAs()` | Package check | Needs fix | Low |
| 22 | `../spatialplanr/R/splnr_get_IUCNRedList.R:90` | `splnr_get_IUCNRedList()` | Package check | Needs fix | Low |
| 23 | `../spatialplanr/R/splnr_get_boundary.R:157` | `splnr_get_boundary()` | EEZ disabled | Already handled | None |
| 24 | `../spatialplanr/data-raw/splnr_convert_toPacific.R:29` | `splnr_convert_toPacific()` | Input validation | Needs fix | Low |
| 25 | `../spatialplanr/data-raw/splnr_convert_toPacific.R:47` | `splnr_convert_toPacific()` | Input validation | Needs fix | Low |
| 26 | `../spatialplanr/data-raw/DATASET.R:130` | dataset builder | Data provenance | Needs investigation | Low |

---

## Group A — Climate API: `metric` column naming (TODOs 1, 2, 3)

### Files
- [`R/fdefine_problem.R:37`](R/fdefine_problem.R:37)
- [`R/fdefine_problem.R:62`](R/fdefine_problem.R:62)
- [`R/fdefine_problem.R:68`](R/fdefine_problem.R:68)

### What the TODOs say

```r
# TODO Still need to check on how clim_input is being used here in this function.
# Many commands expect NA or T/F but it seems like we pass in the input$climateid

# TODO Rewrite the functions to allow other names of climate columns

# TODO Update these functions in spatialplanr to remove climate_sf and instead
# pass a column name.... We shouldn't need to name the column 'metric'
```

### Context

`fdefine_problem()` currently:

1. Reads `input$climateid` (a column name string, e.g. `"sst_trend"`) from the
   Shiny input.
2. Renames that column to `"metric"` in a new `climate_sf` object.
3. Passes `climate_sf` (with the hard-coded `"metric"` column) to
   `spatialplanr::splnr_climate_priorityAreaApproach()` /
   `splnr_climate_featureApproach()` / `splnr_climate_percentileApproach()`.

All three spatialplanr functions assert:

```r
assertthat::assert_that(
  "metric" %in% names(metric),
  msg = "'metric' sf object must contain a column named 'metric'."
)
```

So the rename is **required by the current spatialplanr API**. The TODO is
asking us to remove that requirement.

### Analysis

**TODO 1** (`clim_input` usage): The code is actually consistent — `clim_input`
is checked with `is.null(clim_input) || is.na(clim_input) || clim_input == "NA"`
at line 48, and `input$climateid` is read separately at line 56. The comment is
stale; the logic is correct. This TODO can be **removed**.

**TODOs 2 & 3** are the real issue. The `metric` column name is a hard-coded
contract between shinyplanr and spatialplanr. The fix requires changing the
spatialplanr API to accept a `metric_col` argument (a column name string) instead
of requiring a pre-renamed `climate_sf` object. This is a **breaking change** to
spatialplanr that needs careful coordination.

### Proposed fix

In `spatialplanr`, add a `metric_col = "metric"` argument to all three climate
approach functions (defaulting to `"metric"` for backwards compatibility), and
use `dplyr::rename()` internally. Then in `fdefine_problem()`, pass the raw
`raw_sf` with the original column name and the `metric_col` argument — removing
the need to create a separate `climate_sf` object.

**Critique of this approach:** The default `metric_col = "metric"` preserves
backwards compatibility for existing spatialplanr users. However, it adds
complexity to three functions simultaneously. An alternative is to keep the
current shinyplanr workaround (rename to `"metric"`) and simply remove the TODO
comments — the rename is a one-liner and the cost is negligible. The question is
whether the spatialplanr API should be cleaner for non-shinyplanr users who may
also have arbitrarily named climate columns.

**My recommendation:** Fix in spatialplanr (add `metric_col` argument). The
rename-to-`"metric"` workaround in shinyplanr is fragile if a user's data
already has a column called `"metric"` for a different purpose.

---

## Group B — Feature filtering in `splnr_get_featureRep` (TODO 5)

### File
- [`R/utils_data.R:216`](R/utils_data.R:216)

### What the TODO says

```r
# TODO: This filtering should eventually be moved into
# spatialplanr::splnr_get_featureRep
targetPlotData <- targetPlotData %>%
  dplyr::filter(.data$feature %in% (Dict %>%
    dplyr::filter(.data$type == "Feature") %>%
    dplyr::pull(.data$nameVariable)))
```

### Context

`splnr_get_featureRep()` returns representation data for **all** columns in the
problem data, including cost columns and the `"metric"` climate column. The
shinyplanr wrapper `fget_feature_representation()` must filter the result down
to only `type == "Feature"` rows using the `Dict`.

### Analysis

The filter is necessary because `splnr_get_featureRep()` has no concept of a
feature dictionary — it works purely from the `prioritizr` problem object, which
includes cost columns. Moving this filter into spatialplanr would require
spatialplanr to accept a `Dict` or a `feature_names` vector, which is a
shinyplanr-specific concept.

**My recommendation:** This TODO is **aspirational but not appropriate for
spatialplanr**. The `Dict` is a shinyplanr concept. The correct fix is to ensure
the `prioritizr` problem is built with only feature columns (not cost columns) so
that `splnr_get_featureRep()` returns only features. Looking at `fdefine_problem()`,
the problem is built with `features = targets$feature` which already excludes
cost — so `splnr_get_featureRep()` should already return only features. The
filter in `fget_feature_representation()` may be defensive code against a
historical bug. **We should investigate whether the filter is still needed** by
checking what `splnr_get_featureRep()` actually returns when the problem is
correctly specified.

---

## Group C — Performance: reactive `total_cost` (TODO 4)

### File
- [`R/fdefine_problem.R:172`](R/fdefine_problem.R:172)

### What the TODO says

```r
# TODO make this a reactive and then this only needs to be done when cost
# layer changes
total_cost <- p_dat %>%
  sf::st_drop_geometry() %>%
  dplyr::select(input[[paste0("costid", compare_id)]]) %>%
  dplyr::pull() %>%
  sum()
```

### Analysis

`fdefine_problem()` is itself called inside a reactive (it is called from
`solution()` which is bound to `input$analyse`). The `total_cost` calculation
is therefore already only re-run when the user clicks "Analyse". The TODO
suggests caching it separately so it only re-runs when the cost layer changes
(not when other inputs like targets change). This is a valid optimisation but
**low priority** — the sum of a numeric vector is fast even for large datasets.
Making it a separate reactive would require restructuring `fdefine_problem()` to
accept `total_cost` as an argument, which adds complexity.

**My recommendation:** Leave as-is. Add a comment explaining why it is not a
separate reactive (it is already gated by `input$analyse`). Remove the TODO.

---

## Group D — UI: Bioregion section visibility (TODO 6)

### File
- [`R/mod_2scenario.R:70`](R/mod_2scenario.R:70)

### What the TODO says

```r
# TODO Add a conditional here to account for yes/no bioregions
shiny::h3(paste0("1.", length(unique(slider_vars$category)) + 1, " Bioregions")),
```

### Context

The bioregion section is wrapped in `shinyjs::hidden(div(id = ns("switchBioregions"), ...))`.
The section is shown/hidden by JavaScript based on whether bioregions exist in
the `Dict`. The TODO asks for a conditional to handle the case where there are
no bioregions.

### Analysis

Looking at the code, `slider_varsBioR` is derived from `Dict` filtered to
`type == "Bioregion"`. If there are no bioregions, `slider_varsBioR` will be
empty. The `shinyjs::hidden()` wrapper means the section is hidden by default.
The question is: **is the section ever shown when there are no bioregions?**

The show/hide logic needs to be checked in the server. If the server correctly
never calls `shinyjs::show("switchBioregions")` when `nrow(slider_varsBioR) == 0`,
then the UI TODO is already handled. If not, the fix is to add a conditional in
the UI: `if (nrow(slider_varsBioR) > 0) { ... }`.

**My recommendation:** Add a UI-level guard: wrap the entire
`shinyjs::hidden(div(id = ns("switchBioregions"), ...))` block in
`if (nrow(slider_varsBioR) > 0)`. This is defensive and makes the intent
explicit, regardless of server-side logic.

---

## Group E — Category slider filtering (TODO 7)

### File
- [`R/mod_2scenario.R:360`](R/mod_2scenario.R:360)

### What the TODO says

```r
inps <- slider_vars %>%
  # dplyr::filter(category) %>% # TODO I can't filter by category yet.
  # Need to identify changes by category
  dplyr::pull(.data$id_in)
```

### Context

This observer fires when **any** category slider changes, then updates **all**
individual feature sliders to match. The TODO notes that it cannot yet filter to
only update sliders in the changed category.

### Analysis

The observer uses `purrr::map(slider_varsCat$id_in, \(x) input[[x]])` as its
trigger — this fires when any category slider changes. To know **which** category
changed, we would need to compare old vs new values or use separate observers per
category.

The current behaviour (update all individual sliders when any category slider
changes) is functionally correct but slightly inefficient — it updates sliders
that didn't need updating. For typical use cases (< 20 categories), this is
negligible.

**My recommendation:** The simplest fix is to create one observer per category
using `purrr::walk()` over `slider_varsCat`. Each observer would only update the
individual sliders for its own category. This is clean, idiomatic Shiny, and
removes the need for the TODO. However, this is a refactor that needs testing.
**Defer until there is a performance complaint.**

---

## Group F — Cost plot scaling (TODO 8)

### File
- [`R/mod_2scenario.R:606`](R/mod_2scenario.R:606)

### What the TODO says

```r
#TODO Need to scale the cost data to look better on the plot.
spatialplanr::splnr_plot_costOverlay(soln = solution(), ...)
```

### Analysis

This is a visual quality issue. The cost overlay plot may look poor when cost
values span many orders of magnitude (e.g., distance-to-coast in km vs. equal
area cost). The fix would be to normalise or log-transform the cost column before
plotting, or to add a `scale` argument to `splnr_plot_costOverlay()`.

**My recommendation:** This needs a concrete example of what "looks bad" before
implementing a fix. Log-transforming cost is a common approach but changes the
visual interpretation. **Raise as a separate issue with a screenshot.**

---

## Group G — Cost text in Dictionary (TODO 9)

### File
- [`R/mod_3compare.R:740`](R/mod_3compare.R:740)

### What the TODO says

```r
# TODO Move this text to the Dictionary and implement call to display here as usual
output$txt_cost <- shiny::renderText({
  cost_txt1 <- Dict %>% dplyr::filter(.data$nameVariable == input$costid1)
  ...
  paste0("To illustrate how the chosen cost influences the spatial plan, ...")
})
```

### Context

The cost description text in the Compare module is partially hard-coded (the
preamble sentence) and partially pulled from `Dict$justification`. The TODO asks
to move the preamble into the Dictionary too.

### Analysis

The `Dict` already has a `justification` column. The hard-coded preamble
("To illustrate how the chosen cost influences the spatial plan...") is generic
and applies to all cost layers. Moving it to the Dictionary would mean duplicating
it for every cost row, which is worse. A better approach is to store the preamble
in the app's markdown files (e.g., `shinyplanr_2cost.md`) and render it
separately from the dynamic cost-specific text.

**My recommendation:** Keep the preamble hard-coded (or move to a markdown
template), and keep the cost-specific text from `Dict$justification`. The TODO
as written would make the Dictionary harder to maintain. Remove the TODO and add
a comment explaining the design decision.

---

## Group H — Feature type lookup (TODO 10)

### File
- [`R/mod_4features.R:161`](R/mod_4features.R:161)

### What the TODO says

```r
# TODO I have fudged this it only returns a single type (e.g. when a feature
# is both lock in and lock out). Are there situations where this will be a problem?
type <- type[[1]]
```

### Context

A feature can appear multiple times in `Dict` with different `type` values (e.g.,
`"LockIn"` and `"LockOut"` for MPAs). The code takes only the first type, which
determines how the feature is plotted.

### Analysis

In the Features tab, the user selects a feature from a dropdown. If that feature
has multiple types (e.g., MPAs appear as both `LockIn` and `LockOut`), the plot
type is determined by `type[[1]]`. The plot types are: `"Cost"` (continuous
colour scale), `"Feature"` / `"Bioregion"` (binary), `"LockIn"` / `"LockOut"`
(binary). For MPAs, both `LockIn` and `LockOut` would produce the same binary
plot, so taking `type[[1]]` is harmless in practice.

However, the `Dict` design of having the same `nameVariable` appear twice (once
as `LockIn`, once as `LockOut`) is the root cause. A cleaner design would be a
single row with `type = "LockIn,LockOut"` or a separate `role` column.

**My recommendation:** For now, the `type[[1]]` fudge is acceptable because the
plot output is identical for `LockIn` and `LockOut`. Add a comment explaining
this. The deeper fix (Dict schema change) should be tracked as a separate issue.

---

## Group I — Template stubs in `create_template.R` (TODOs 11–16)

### Files
- [`R/create_template.R:704`](R/create_template.R:704) — boundary stub
- [`R/create_template.R:708`](R/create_template.R:708) — coastline stub
- [`R/create_template.R:712`](R/create_template.R:712) — planning units stub
- [`R/create_template.R:747`](R/create_template.R:747) — feature data stub
- [`R/create_template.R:803`](R/create_template.R:803) — climate data stub
- [`R/create_template.R:1283`](R/create_template.R:1283) — Dict CSV stub

### Analysis

These TODOs are **written into the generated setup scripts** (i.e., they are
string literals that become comments in `2_setup_data.R` and `Dict_Feature.csv`).
They are **intentional user-facing instructions**, not developer TODOs. They are
only generated when the user selects `oceandatr = FALSE` (custom data path),
which is the correct behaviour — the user must supply their own data.

**Status: Already correct. No action needed.** These should not be confused with
developer TODOs. Consider renaming them to `# USER ACTION REQUIRED:` in the
generated scripts to make the distinction clearer.

---

## Group J — `splnr_gg_add()` argument cleanup (TODO 17)

### File
- [`../spatialplanr/R/splnr_gg_add.R:183`](../spatialplanr/R/splnr_gg_add.R:183)

### What the TODO says

```r
# TODO Remove all uneeded arguments, especially the lockIn
```

### Context

`splnr_gg_add()` has `lockIn` and `lockOut` arguments with many sub-parameters
(`typeLockIn`, `nameLockIn`, `alphaLockIn`, `colorLockIn`, `legendLockIn`,
`labelLockIn`, and equivalents for `lockOut`). These are validated with
`assertthat` but the function signature is very wide.

### Analysis

Removing arguments is a **breaking change** to the spatialplanr API. Before
removing anything, we need to check whether shinyplanr or any other downstream
code uses these arguments. A search shows shinyplanr does **not** pass `lockIn`
to `splnr_gg_add()` — it uses `prioritizr`'s locked constraints instead.

**My recommendation:** Deprecate (not remove) the `lockIn`/`lockOut` arguments
using `lifecycle::deprecate_warn()`. This gives downstream users time to migrate.
Removal can happen in a future major version. **Low priority.**

---

## Group K — Climate plot assertions (TODOs 18, 19, 20)

### File
- [`../spatialplanr/R/splnr_plotting_climate.R:287`](../spatialplanr/R/splnr_plotting_climate.R:287)
- [`../spatialplanr/R/splnr_plotting_climate.R:309`](../spatialplanr/R/splnr_plotting_climate.R:309)
- [`../spatialplanr/R/splnr_plotting_climate.R:331`](../spatialplanr/R/splnr_plotting_climate.R:331)

### What the TODOs say

```r
#TODO ADD assert for new _names variables
# assertthat::assert_that(is.character(names), ...)

#TODO Re enable for new _names variable
# Check that each solution in the list has 'metric' and 'solution_1' columns

#TODO Write check for ggridges
```

### Context

`splnr_plot_climKernelDensity_Fancy()` was refactored to accept
`solution_names` and `climate_names` vectors (replacing the old hard-coded
`"metric"` column name). The assertions for these new parameters were commented
out during the refactor and not yet re-enabled.

### Analysis

These are **incomplete refactors** — the assertions were disabled to make the
refactor work but were never re-enabled with the new parameter names. This leaves
the function without input validation for its most important parameters.

**My recommendation:** Re-enable and update the assertions for `solution_names`
and `climate_names`. The `ggridges` check should use
`requireNamespace("ggridges", quietly = TRUE)` with a helpful error message.
These are **medium priority** — missing assertions don't break functionality but
make debugging harder.

---

## Group L — Package availability checks (TODOs 21, 22)

### Files
- [`../spatialplanr/R/splnr_get_MPAs.R:115`](../spatialplanr/R/splnr_get_MPAs.R:115)
- [`../spatialplanr/R/splnr_get_IUCNRedList.R:90`](../spatialplanr/R/splnr_get_IUCNRedList.R:90)

### What the TODOs say

```r
# TODO Add a check for wdpar package
# TODO add check for rredlist package
```

### Analysis

Both `wdpar` and `rredlist` are optional/suggested packages (not in `Imports`).
Without a check, calling these functions when the package is not installed
produces an unhelpful `could not find function` error.

The standard pattern in R packages is:

```r
if (!requireNamespace("wdpar", quietly = TRUE)) {
  stop("Package 'wdpar' is required. Install with: install.packages('wdpar')",
       call. = FALSE)
}
```

**My recommendation:** Add these checks immediately before the first use of each
package. This is a **quick, high-value fix** — it dramatically improves the user
experience when a package is missing.

---

## Group M — Input validation in `splnr_convert_toPacific()` (TODOs 24, 25)

### File
- [`../spatialplanr/data-raw/splnr_convert_toPacific.R:29`](../spatialplanr/data-raw/splnr_convert_toPacific.R:29)
- [`../spatialplanr/data-raw/splnr_convert_toPacific.R:47`](../spatialplanr/data-raw/splnr_convert_toPacific.R:47)

### What the TODOs say

```r
# TODO add a warning if df doesn't cross the pacific dateline
# TODO add a warning if the input df is not unprojected
```

### Analysis

These are in `data-raw/` — a **data preparation script**, not a package function.
`data-raw/` scripts are not shipped with the package and are not user-facing.
However, if `splnr_convert_toPacific()` is also defined as a package function
(it may be — the `data-raw/` version may be a copy), the warnings would be
valuable there.

**My recommendation:** Check whether `splnr_convert_toPacific()` exists as a
package function in `spatialplanr/R/`. If so, add the warnings there. If it only
exists in `data-raw/`, these TODOs are low priority.

---

## Group N — Dataset provenance (TODO 26)

### File
- [`../spatialplanr/data-raw/DATASET.R:130`](../spatialplanr/data-raw/DATASET.R:130)

### What the TODO says

```r
#TODO Need to sort out the datasets that are not created here
load("data/spDataFiltered.rda")
load("data/MPAsCoralSea.rda")
load("data/CoralSeaVelocity.rda")
```

### Analysis

Three datasets (`spDataFiltered`, `MPAsCoralSea`, `CoralSeaVelocity`) are loaded
from pre-existing `.rda` files rather than being created reproducibly in
`DATASET.R`. This breaks the reproducibility of the data build. These datasets
likely require external data sources (e.g., GBIF downloads, WDPA) that cannot
be automated easily.

**My recommendation:** Document the provenance of each dataset in a comment
above the `load()` call. If the source data can be downloaded programmatically,
add the download code (even if commented out). This is a **data management
issue** that should be tracked separately.

---

## Recommended action order

### Immediate (fix now, low risk)
1. **TODO 1** — Remove stale `clim_input` comment in `fdefine_problem.R`
2. **TODOs 21, 22** — Add `requireNamespace()` checks in `splnr_get_MPAs.R` and `splnr_get_IUCNRedList.R`
3. **TODOs 18, 19, 20** — Re-enable assertions in `splnr_plot_climKernelDensity_Fancy()`
4. **TODO 4** — Remove the reactive TODO, add explanatory comment
5. **TODO 9** — Remove the Dictionary TODO, add design-decision comment

### Short-term (requires design discussion)
6. **TODOs 2, 3** — Climate API: add `metric_col` argument to spatialplanr climate functions
7. **TODO 5** — Investigate whether the feature filter in `fget_feature_representation()` is still needed
8. **TODO 6** — Add UI-level guard for bioregion section
9. **TODO 10** — Add comment explaining the `type[[1]]` fudge; track Dict schema as separate issue

### Deferred (needs more information or is low priority)
10. **TODO 7** — Per-category observers (refactor, needs testing)
11. **TODO 8** — Cost plot scaling (needs concrete example)
12. **TODO 17** — Deprecate `lockIn`/`lockOut` in `splnr_gg_add()`
13. **TODOs 24, 25** — Warnings in `splnr_convert_toPacific()`
14. **TODO 26** — Dataset provenance in `DATASET.R`

### No action needed
15. **TODOs 11–16** — Template stubs in `create_template.R` (intentional user instructions)
16. **TODO 23** — EEZ disabled in `splnr_get_boundary()` (already handled with comment)
