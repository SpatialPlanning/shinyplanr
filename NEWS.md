# shinyplanr 0.1.9

## New features

* New "Explore" tab in the Comparison module (`mod_3compare`), matching the
  interactive Leaflet map already available in the Scenario module's Explore
  tab. A radio button lets the user switch between two display modes:
  - **Compare**: shows which planning units were added (blue), removed
    (red), or selected in both scenarios (grey). Unselected-in-both cells
    are not drawn, consistent with every other plot in the app.
  - **Scenario**: shows Scenario 1 and/or Scenario 2's selected areas (each
    independently toggleable via checkboxes) using a light green
    (`#7fc97f`, Scenario 1) and a dark green (`#00441b`, Scenario 2) chosen
    to be clearly distinguishable, at 50% opacity so overlapping areas
    remain visible. Locked-in/locked-out constraints are also shown per
    scenario using lighter blue/red shades for Scenario 2 to keep the two
    scenarios visually distinguishable.
  Clicking a planning unit shows its selection status in each scenario,
  cost values, and a feature list grouped by category (mirroring the
  Scenario module's Explore tab popup). The Display Mode controls and the
  Planning Unit info are shown in two separate, independently draggable
  panels (top-left and top-right respectively), and the map's zoom/pan is
  preserved when toggling Display Mode or the scenario checkboxes — it only
  re-fits to the solution's extent once per "Run Analysis" click, and is
  correctly framed to the area of interest (rather than the whole world) on
  first visiting the tab. The existing `include_explore` option now
  controls both the Scenario and Comparison modules' Explore tabs.

* New optional `shinyplanr_options` key `antimeridian` (default `FALSE`).
  Set `TRUE` for deployments whose planning region crosses the +/-180
  degree line (e.g. Fiji, Tonga, or a multi-country West Pacific
  deployment). ggplot2 maps are unaffected, since they are drawn directly
  in the working CRS set by `cCRS`. Interactive leaflet maps
  (`mod_2scenario` Explore tab, `mod_4afeatures` interactive Layer
  Information, `mod_5coverage` Check Coverage), however, always reproject
  to WGS84 (lon/lat) before rendering, which previously caused
  antimeridian-crossing polygons to be drawn as giant bands spanning the
  entire map. When `antimeridian = TRUE`, all data shown on these leaflet
  maps is additionally shifted to 0-360 degree longitude (via
  `sf::st_shift_longitude()`) immediately before rendering, keeping the
  region compact on screen. GeoJSON downloads are never shifted and
  remain standard -180..180 files. Existing `3_setup_app.R` scripts do not
  need to be updated -- add `antimeridian = TRUE` only if your region
  crosses the dateline.

* New optional `shinyplanr_options` key `visible_climateOptions` (default
  `FALSE`). When set `TRUE`, the climate-smart approach parameters
  (`climate_change`, `percentile`, `direction`, `refugiaTarget`) -- previously
  fixed at deploy time -- are exposed as live sidebar controls in both the
  Scenario and Comparison tabs, letting app users choose their own
  climate-smart approach instead of only picking the climate layer. In the
  Comparison tab, each scenario panel gets independent controls. The
  controls appear only once a climate layer is selected, and `refugiaTarget`
  is hidden automatically when the Percentile approach is chosen (it has no
  effect on that approach). Existing `3_setup_app.R` scripts do not need to
  be updated -- add `visible_climateOptions = TRUE` only if you want to
  enable this behaviour. The live `refugiaTarget` slider is shown as a 0-100
  percentage (consistent with the `percentile` control), even though
  `shinyplanr_options$refugiaTarget` itself remains on a 0-1 scale.

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
