# shinyplanr 0.1.9

## New features

* The Cost overlay plot (Scenario tab "Cost" sub-tab, and Compare tab "Cost"
  sub-tab) now supports configurable styling via five new optional
  `shinyplanr_options` keys: `cost_plot_alpha`, `cost_plot_low_colour`,
  `cost_plot_high_colour`, `cost_plot_lower_percentile` and
  `cost_plot_upper_percentile`. These are passed through to
  `spatialplanr::splnr_plot_costOverlay()` (requires spatialplanr >= 0.7.7).
  If omitted, they default to the previous appearance (`alpha = 0.1`,
  `"#fff5eb"` -> `"#d94801"`), except that the colour scale limits now
  default to the 5th-95th percentile of the cost distribution (previously a
  fixed 0-99th percentile range), giving better colour contrast out of the
  box. Existing `3_setup_app.R` scripts do not need to be updated -- add
  these keys only if you want to customise the cost plot's appearance.

# shinyplanr 0.1.8

## New features

* Category display order (sidebar sliders, checkbox groups, Cost/Climate
  dropdowns, and the Layer Information dropdowns) is now explicit and
  consistent across the whole app, driven by a new internal helper,
  `forder_dict_categories()`.

  - Categories are grouped by their "master category" (`Dict$type`), always
    shown in the fixed order: `Feature` -> `Bioregion` -> `Cost` ->
    `Climate` -> `LockIn` -> `LockOut` -> `EcosystemServices`. This mirrors
    the existing hardcoded sidebar section order in the Scenario tab.
  - Within a `type`, categories are ordered by a new **optional** numeric
    `categoryOrder` column in `Dict_Feature.csv`. If `categoryOrder` is
    absent, category order falls back to the pre-existing default
    (alphabetical by `categoryID`) -- fully backward compatible with
    dictionaries created before this release.
  - `Dict$category` is now an **ordered factor** (not a plain character
    column) once `3_setup_app.R` has run. This lets `dplyr::arrange()` /
    `dplyr::group_by()` consumers (dropdowns, `spatialplanr` bar charts)
    automatically follow the same order as the sidebar sliders, which rely
    on `Dict` row order.
  - See `vignette("ac-setting-up")`, section "Controlling category order",
    for how to set `categoryOrder`.

* `validate_dict()` gained two new checks:
  - `categoryID` must be identical across every row sharing the same
    (`type`, `category`) combination. Previously, an inconsistent or blank
    `categoryID` on some rows of a category was silently ignored (via
    `dplyr::first()`), producing confusing results that depended on row
    order rather than raising an error.
  - If present, `categoryOrder` must be numeric and identical across every
    row sharing the same (`type`, `category`) combination.

## Bug fixes

* Fixed a latent bug where `categoryID` inconsistency within a category
  (e.g. blank on some rows) was silently tolerated rather than causing
  master-category sliders / bioregion display columns to behave
  unpredictably. This is now caught by `validate_dict()` (see above).

## Internal changes

* `create_fancy_dropdown()` (`R/utils_ui.R`) and the interactive Layer
  Information dropdown builder (`R/mod_4afeatures.R`) now explicitly coerce
  the grouping category to `character` before passing it to
  `purrr::map_chr()`, since that function does not coerce factors and would
  error once `Dict$category` became an ordered factor.
* `inst/templates/setup/3_setup_app.R` now calls
  `shinyplanr:::forder_dict_categories()` instead of
  `dplyr::arrange(type, categoryID)` when building `Dict`.
* The generated `Dict_Feature.csv` templates (both the oceandatr-based and
  minimal manual templates) now include an example `categoryOrder` column.

No `config_list` keys were added, removed, or renamed, so the config schema
version (`get_schema_version()`) is unchanged at `2`.
