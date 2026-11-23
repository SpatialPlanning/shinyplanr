# Plan: `visible_climateOptions` for Climate-Smart Planning

## Problem

Deployers currently set `climate_change`, `percentile`, `direction`, and
`refugiaTarget` in `inst/templates/setup/3_setup_app.R` at deploy time. The
person using the running app never sees or controls these — only the climate
**layer** dropdown (`climateid` / `climateid1` / `climateid2`) is exposed in
the UI today. We want an opt-in option, `visible_climateOptions`, that when
`TRUE` exposes `climate_change`, `percentile`, `direction`, and
`refugiaTarget` as sidebar controls in both the Scenario tab
(`mod_2scenario`) and the Comparison tab (`mod_3compare`).

## Current state (traced through the codebase)

- `climate_change`, `percentile`, `direction`, `refugiaTarget` are read
  directly from `options` in [`fdefine_problem()`](../R/fdefine_problem.R:85-119)
  (selects CPA / Feature / Percentile approach) and in
  [`fget_feature_representation()`](../R/utils_data.R:458) (feature-rep
  reporting).
- The climate **layer** dropdown is already user-facing in
  [`mod_2scenario_ui()`](../R/mod_2scenario.R:146-167) and
  [`mod_3compare_ui()`](../R/mod_3compare.R:229-271).
- `refugiaTarget` is silently ignored by the Percentile approach
  (`climate_change == 3`) — see `fdefine_problem.R` lines 109-120.
- The existing `%||%` fallback convention is used throughout the codebase for
  optional overridable options (e.g. `options$cost_plot_alpha %||% 0.1` in
  `mod_2scenario.R`).
- Precedent: the `cost_plot_*` options (NEWS 0.1.9) were added purely
  additively with `%||%` fallbacks and **no config schema version bump**.
  Existing deployments are unaffected until they opt in.

## Confirmed design decisions

1. New option `visible_climateOptions` (default `FALSE`) added next to the
   existing climate block in `3_setup_app.R`.
2. The Comparison tab gets **independent** per-scenario controls (Scenario 1
   / Scenario 2 side-by-side), consistent with how cost/budget/climateid are
   already duplicated there.
3. Widgets: `selectInput` for `climate_change` (approach) and `direction`;
   `sliderInput` for `percentile` and `refugiaTarget`.
4. `refugiaTarget` is hidden whenever the Percentile approach
   (`climate_change == 3`) is selected.
5. The whole approach-controls panel stays hidden until the user picks an
   actual climate layer (i.e. hidden while the climate dropdown is set to
   "Don't consider").
6. `fdefine_problem()` and `fget_feature_representation()` use the `%||%`
   fallback convention: `input[[paste0("climate_change", compare_id)]] %||%
   options$climate_change`. This works uniformly whether or not the UI is
   rendered — no branching on `visible_climateOptions` is needed in the
   business logic.

## Todo list

- [ ] Add `visible_climateOptions = FALSE` option (with explanatory comment)
      to the climate block in `inst/templates/setup/3_setup_app.R`.
- [ ] Add a reusable UI helper (e.g. `fclimate_options_ui()`) in
      `R/utils_ui.R` building the `climate_change` (selectInput),
      `percentile` (sliderInput), `direction` (selectInput), and
      `refugiaTarget` (sliderInput) widgets, parameterised by an id suffix
      (`""` / `"1"` / `"2"`).
- [ ] Update `mod_2scenario_ui()` to render the climate-options panel
      (wrapped in `shinyjs::hidden()`) directly below the existing
      `climateid` dropdown, gated on
      `options$include_climateChange && options$visible_climateOptions`.
- [ ] Update `mod_3compare_ui()` to render two independent climate-options
      panels (suffix `"1"` and `"2"`) below `climateid1`/`climateid2`, same
      gating.
- [ ] Add a reusable server-side observer helper (e.g.
      `fsetup_climate_option_observers()`) in `R/utils_server.R`: show/hide
      the climate-options panel when `climateid<suffix>` changes from/to
      `"NA"`, and show/hide `refugiaTarget` when `climate_change<suffix>`
      toggles to/from the Percentile approach (3).
- [ ] Wire the new observer helper into `mod_2scenario_server()` (suffix
      `""`) and `mod_3compare_server()` (suffix `"1"` and `"2"`), gated on
      `options$visible_climateOptions`.
- [ ] Update `R/fdefine_problem.R`: replace direct `options$climate_change` /
      `options$percentile` / `options$direction` / `options$refugiaTarget`
      reads with
      `input[[paste0(<name>, compare_id)]] %||% options$<name>` fallbacks in
      all three climate-approach branches.
- [ ] Update `R/utils_data.R` `fget_feature_representation()`: add an
      explicit `climate_change` parameter (default `options$climate_change`)
      replacing the internal `options$climate_change` read, and update its
      roxygen docs.
- [ ] Update call sites of `fget_feature_representation()` in
      `mod_2scenario.R` and `mod_3compare.R` to pass the resolved
      `climate_change` value (`input$climate_change %||%
      options$climate_change`, with `1`/`2` suffixes in compare).
- [ ] Update `data-raw/build_stub_sysdata.R` to include
      `visible_climateOptions = FALSE` for consistency, and re-run to
      regenerate `R/sysdata.rda`.
- [ ] Add/extend tests: `mod_2scenario` UI shows/hides climate-options
      controls based on `visible_climateOptions`; `mod_3compare` UI same for
      both scenarios; `fdefine_problem()` input-override tests;
      `fget_feature_representation()` explicit `climate_change` param tests.
- [ ] Update `vignettes/ac-setting-up.qmd` "Climate Options" section to
      document `visible_climateOptions`.
- [ ] Add a `NEWS.md` entry describing the new `visible_climateOptions`
      feature.
- [ ] Run `devtools::document()`, `devtools::load_all()`, and
      `devtools::test()` to verify the change; report results.

## Notes

- No config schema version bump is required — this follows the same
  additive, `%||%`-fallback precedent as the `cost_plot_*` options.
