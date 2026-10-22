# utils_data.R
# Pure data-wrangling helpers with no Shiny reactivity dependency.
# These functions take data in and return data out; they can be unit-tested
# without a Shiny session.


# Canonical "master category" (type) display order -------------------------
#
# This fixes the order in which the different Dict$type groups appear
# wherever categories from multiple types are combined into a single grouped
# widget (e.g. the Feature Maps / Layer Information dropdowns). It mirrors
# the hardcoded section order already used in mod_2scenario_ui() /
# mod_3compare_ui(): Targets (Feature, then Bioregion) -> Cost -> Climate ->
# Constraints (LockIn, LockOut). EcosystemServices has its own tab and no
# sidebar widget, so it is placed last. "Justification" rows have no
# category-grouped widget at all and are intentionally excluded -- any such
# rows are appended after all known types by fbuild_category_levels() so
# they are never dropped.
#
# noRd because this is an internal implementation detail, not part of the
# public API. Changing the order here changes ordering everywhere at once.
.shinyplanr_type_order <- c(
  "Feature", "SilentFeature", "Bioregion", "Cost", "Climate", "LockIn", "LockOut", "EcosystemServices"
)


#' Order Dict rows and factor-order Dict$category for consistent display
#'
#' Establishes a single, explicit ordering for feature/cost/lock-in/etc.
#' categories that is then respected by every category-grouped UI element in
#' the app: the Scenario/Compare sidebar sliders and checkboxes (which rely
#' on row order via \code{unique()} / \code{dplyr::summarise(.by=)}), the
#' Cost/Climate/Layer-Information dropdowns and \code{spatialplanr}'s bar
#' charts (which rely on factor level order via \code{dplyr::arrange()} /
#' \code{dplyr::group_by()}).
#'
#' The ordering is computed as:
#' \enumerate{
#'   \item Master category (\code{type}) order, as fixed by
#'     \code{.shinyplanr_type_order} (Feature, Bioregion, Cost, Climate,
#'     LockIn, LockOut, EcosystemServices). Any \code{type} not in this list
#'     (e.g. \code{"Justification"}) is appended after all known types, in
#'     first-appearance order, so such rows are never dropped or coerced to
#'     \code{NA}.
#'   \item Within each \code{type}, by the optional numeric
#'     \code{categoryOrder} column if present; otherwise by \code{categoryID}
#'     (alphabetically) -- this preserves the pre-existing default behaviour
#'     for Dict_Feature.csv files that predate \code{categoryOrder}.
#'   \item Ties broken by original row order in \code{Dict} (a stable sort),
#'     which is what continues to control feature order \emph{within} a
#'     category.
#' }
#'
#' \code{Dict$category} is then converted to an \strong{ordered factor} with
#' levels in that exact sequence, and \code{Dict} itself is re-arranged to
#' match. Setting the factor levels (not just re-arranging rows) is what
#' propagates the ordering to \code{dplyr::arrange()} / \code{group_by()}
#' consumers downstream, which sort by factor level code rather than by
#' Dict's row order.
#'
#' @param Dict Data frame. The feature dictionary, filtered to
#'   \code{includeApp == TRUE} rows (must contain columns \code{type},
#'   \code{category}, \code{categoryID}, and optionally \code{categoryOrder}).
#'
#' @return \code{Dict}, re-arranged, with \code{category} converted to an
#'   ordered factor reflecting the same sequence.
#'
#' @noRd
#'
forder_dict_categories <- function(Dict) {
  has_category_order <- "categoryOrder" %in% names(Dict)

  # Build a one-row-per-category lookup carrying the sort keys, preserving
  # first-appearance order as the ultimate tiebreak (via row_number()).
  #
  # .cat_order_key is numeric (NA sorts last within its type, via the
  # explicit is.na() tiebreak below) so that e.g. categoryOrder values 2 and
  # 10 sort numerically (2 < 10), not as strings ("10" < "2").
  # .cat_id_key is the character categoryID, used as the fallback ordering
  # when categoryOrder is absent/NA -- this preserves the pre-existing
  # alphabetical-by-categoryID default behaviour.
  cat_lookup <- Dict %>%
    dplyr::mutate(.orig_row = dplyr::row_number()) %>%
    dplyr::group_by(.data$type, .data$category) %>%
    dplyr::summarise(
      .type_first_row = min(.data$.orig_row),
      .cat_order_key = if (has_category_order) {
        suppressWarnings(as.numeric(dplyr::first(.data$categoryOrder)))
      } else {
        NA_real_
      },
      .cat_id_key = as.character(dplyr::first(.data$categoryID)),
      .groups = "drop"
    )

  # Master type rank: known types get their position in .shinyplanr_type_order;
  # anything else (e.g. "Justification") is ranked after all known types, in
  # order of first appearance, so it is appended rather than dropped/NA'd.
  known_types_present <- intersect(.shinyplanr_type_order, unique(cat_lookup$type))
  other_types_present <- setdiff(unique(cat_lookup$type), .shinyplanr_type_order)
  # Order "other" types by their first appearance in Dict for determinism.
  other_types_present <- cat_lookup %>%
    dplyr::filter(.data$type %in% other_types_present) %>%
    dplyr::arrange(.data$.type_first_row) %>%
    dplyr::pull("type") %>%
    unique()

  type_rank <- stats::setNames(
    seq_along(c(known_types_present, other_types_present)),
    c(known_types_present, other_types_present)
  )

  cat_lookup <- cat_lookup %>%
    dplyr::mutate(.type_rank = type_rank[.data$type]) %>%
    # Categories with a categoryOrder value sort numerically first (ascending);
    # categories without one (is.na(.cat_order_key) == TRUE sorts after
    # FALSE) fall back to alphabetical categoryID, then original row order.
    dplyr::arrange(
      .data$.type_rank,
      is.na(.data$.cat_order_key),
      .data$.cat_order_key,
      .data$.cat_id_key,
      .data$.type_first_row
    )

  category_levels <- unique(cat_lookup$category)

  Dict %>%
    dplyr::mutate(
      category = factor(.data$category, levels = category_levels, ordered = TRUE)
    ) %>%
    dplyr::arrange(.data$category)
}


#' Format a feature representation data frame for display
#'
#' Takes the output of \code{spatialplanr::splnr_get_featureRep()} and returns
#' a tidy display table with human-readable column names, integer percentages,
#' and features sorted by category then name.  Zero-target features are marked
#' as incidental (consistent behaviour across both the scenario and comparison
#' modules).
#'
#' @param tpd Data frame. Output of \code{splnr_get_featureRep()}, or
#'   \code{NULL} (returns \code{NULL} immediately).
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{nameVariable}, \code{nameCommon}, \code{category}).
#' @param suffix Character. Appended to column headers to distinguish scenarios
#'   in the comparison module (e.g. \code{" 1"}, \code{" 2"}).  Default
#'   \code{""} (no suffix).
#'
#' @return A tibble with columns Category, Feature, Target (%), Selected (%),
#'   and Incidental (column names include the suffix when provided), with
#'   feature variable names replaced by their common names from Dict.
#'
#' @importFrom rlang :=
#' @noRd
#'
fformat_feature_table <- function(tpd, Dict, suffix = "") {
  if (is.null(tpd)) {
    return(NULL)
  }

  # Mark zero-target features as incidental (consistent across both modules)
  tpd <- tpd %>%
    dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))

  # Build replacement lookup: "^nameVariable$" -> nameCommon
  rpl <- Dict %>%
    dplyr::filter(.data$nameVariable %in% tpd$feature) %>%
    dplyr::select("nameVariable", "nameCommon") %>%
    dplyr::mutate(nameVariable = stringr::str_c("^", .data$nameVariable, "$")) %>%
    tibble::deframe()

  tpd %>%
    dplyr::left_join(
      Dict %>% dplyr::select("nameVariable", "category"),
      by = c("feature" = "nameVariable")
    ) %>%
    dplyr::mutate(
      value  = as.integer(round(.data$relative_held * 100)),
      target = as.integer(round(.data$target * 100))
    ) %>%
    dplyr::select("category", "feature", "target", "value", "incidental") %>%
    dplyr::rename(
      Category = "category",
      Feature = "feature",
      !!paste0("Target", suffix, " (%)") := "target",
      !!paste0("Selected", suffix, " (%)") := "value",
      !!paste0("Incidental", suffix) := "incidental"
    ) %>%
    dplyr::arrange(.data$Category, .data$Feature) %>%
    dplyr::mutate(Feature = stringr::str_replace_all(.data$Feature, rpl))
}


#' Return category df from Dict
#'
#' @noRd
#'
fget_category <- function(Dict) {
  category <- Dict %>%
    dplyr::filter(.data$type %in% c("Feature", "SilentFeature", "Bioregion")) %>%
    dplyr::select("nameVariable", "category") %>%
    dplyr::rename(feature = "nameVariable")

  return(category)
}


# Get Targets

#' Calculate targets based on slider inputs
#'
#' Reads slider input values for all features of a given \code{dataType} from
#' the feature dictionary and returns a data frame of feature name / target
#' pairs ready for use in \code{prioritizr::add_relative_targets()}.
#'
#' @param input Shiny input object.
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{type} and \code{nameVariable}).
#' @param name_check Character. Prefix used to build slider input IDs
#'   (e.g. \code{"sli_"} for the Scenario module, \code{"sli1_"} / \code{"sli2_"} for Compare).
#' @param dataType Character. The \code{type} value(s) in \code{Dict} to
#'   include (default \code{"Feature"}).
#'
#' @return A tibble with columns \code{feature} (character) and \code{target}
#'   (numeric, 0–1 scale).
#'
#' @noRd
#'
fget_targets <- function(input, Dict, name_check = "sli_", dataType = "Feature") {
  ft <- Dict %>%
    dplyr::filter(.data$type %in% dataType) %>%
    dplyr::pull("nameVariable")

  # purrr::map_dbl() with %||% 0 is type-safe: it returns a numeric vector of
  # the same length as ft even when a slider input is NULL (e.g. not yet
  # initialised). The previous enframe()+unnest() approach silently dropped
  # NULL rows, which could produce a shorter-than-expected targets data frame.
  targets <- tibble::tibble(
    feature = ft,
    target  = purrr::map_dbl(ft, \(x) input[[paste0(name_check, x)]] %||% 0) / 100
  )

  return(targets)
}


#' Calculate targets for all feature types, expanding category-level inputs
#'
#' Consolidates the logic for assembling per-feature targets from three sources:
#' \enumerate{
#'   \item Regular \code{Feature} rows — one slider per feature, read directly
#'     via \code{name_check} prefix.
#'   \item \code{SilentFeature} rows — one slider per \emph{category} (keyed by
#'     \code{categoryID} with prefix \code{"silent_<name_check>"}), expanded to
#'     one target row per individual feature in that category.  The individual
#'     layers are never shown in the UI; only the category slider is visible.
#'   \item \code{Bioregion} rows — one slider per \emph{categoryID} (keyed by
#'     \code{categoryID} with prefix \code{"master_<name_check>"}), expanded to
#'     one target row per zone column.
#' }
#'
#' This replaces the former \code{fget_targets_with_bioregions()} function and
#' extends it to handle \code{SilentFeature} rows.
#'
#' @param input Shiny input object.
#' @param name_check Character. Prefix for individual-feature slider input IDs
#'   (e.g. \code{"sli_"} for Scenario, \code{"sli1_"} / \code{"sli2_"} for
#'   Compare).  The SilentFeature prefix is derived as
#'   \code{paste0("silent_", name_check)} and the Bioregion prefix as
#'   \code{paste0("master_", name_check)}.
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{type}, \code{nameVariable}, and \code{categoryID}).
#'
#' @return A tibble with columns \code{feature} (character, matching column
#'   names in \code{raw_sf}) and \code{target} (numeric, 0–1 scale), with one
#'   row per prioritizr feature across all three source types.
#'
#' @noRd
#'
fget_targets_expanded <- function(input, name_check = "sli_", Dict) {
  # --- 1. Regular Feature targets (one slider per feature) -------------------
  targets <- fget_targets(input, Dict = Dict, name_check = name_check, dataType = "Feature")

  # --- 2. SilentFeature targets (one slider per category -> one row per feature) ---
  ft_silent <- Dict %>%
    dplyr::filter(.data$type == "SilentFeature") %>%
    dplyr::select("feature" = "nameVariable", "categoryID")

  if (nrow(ft_silent) > 0) {
    # Slider IDs use the "silent_<name_check><categoryID>" pattern, e.g.
    # "silent_sli_SeagrassMeadows" for name_check = "sli_".
    # fcreate_vars() is called with name_check = "silent_sli_" for SilentFeature
    # sliders, which (after removing the old "master_" prepend) produces
    # id_in = "silent_sli_<categoryID>" — matching this read pattern.
    silent_name_check <- paste0("silent_", name_check)

    cats_silent <- ft_silent %>%
      dplyr::pull("categoryID") %>%
      unique()

    targets_silent_raw <- tibble::tibble(
      categoryID = cats_silent,
      target     = purrr::map_dbl(cats_silent, \(x) input[[paste0(silent_name_check, x)]] %||% 0) / 100
    )

    targets_silent <- dplyr::left_join(ft_silent, targets_silent_raw, by = "categoryID") %>%
      dplyr::select(-"categoryID")

    targets <- dplyr::bind_rows(targets, targets_silent)
  }

  # --- 3. Bioregion targets (one slider per categoryID -> one row per zone) --
  ft_bioregion <- Dict %>%
    dplyr::filter(.data$type == "Bioregion") %>%
    dplyr::select("feature" = "nameVariable", "categoryID")

  if (nrow(ft_bioregion) > 0) {
    # Slider IDs use the "bioregion_<name_check><categoryID>" pattern, e.g.
    # "bioregion_sli_EnviroZone" when name_check = "sli_".
    # The caller passes the base prefix (e.g. "sli_"); we prepend "bioregion_"
    # here to match the explicit prefix passed to fcreate_vars() for Bioregion
    # sliders (e.g. "bioregion_sli_").
    bioregion_name_check <- paste0("bioregion_", name_check)

    cats <- ft_bioregion %>%
      dplyr::pull("categoryID") %>%
      unique()

    # purrr::map_dbl() with %||% 0 is type-safe: returns a numeric vector of the
    # same length as cats even when a bioregion slider input is NULL (e.g. not yet
    # initialised).
    targets_bioregion_raw <- tibble::tibble(
      categoryID = cats,
      target     = purrr::map_dbl(cats, \(x) input[[paste0(bioregion_name_check, x)]] %||% 0) / 100
    )

    targets_bioregion <- dplyr::left_join(ft_bioregion, targets_bioregion_raw, by = "categoryID") %>%
      dplyr::select(-"categoryID")

    targets <- dplyr::bind_rows(targets, targets_bioregion)
  }

  return(targets)
}


#' Get feature representation data with climate handling
#'
#' Consolidates the logic for getting feature representation data,
#' handling both climate-smart and regular approaches.
#' All features in the problem (including those with target = 0) are returned;
#' zero-target features are flagged as incidental by
#' \code{spatialplanr::splnr_get_featureRep()}.
#'
#' @param soln Solution sf object
#' @param problem_data Problem object
#' @param targets Targets data frame
#' @param climate_id Climate input ID (or "NA" if not using climate)
#' @param options App options list
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{type} and \code{nameVariable}). Used to split the returned data
#'   into \code{$main} (non-SilentFeature rows, for the Targets plot) and
#'   \code{$silent} (SilentFeature rows only, for the Details tab silent
#'   section). Individual silent layers are never shown in the Targets plot.
#'
#' @return A named list with two elements:
#'   \describe{
#'     \item{\code{main}}{Data frame of feature representation with
#'       \code{SilentFeature} rows removed. Passed to
#'       \code{splnr_plot_featureRep()} and \code{fformat_feature_table()}.}
#'     \item{\code{silent}}{Data frame of \code{SilentFeature} rows only,
#'       or \code{NULL} if no \code{SilentFeature} rows exist in \code{Dict}.
#'       Passed to \code{fformat_feature_table()} for the Details tab silent
#'       section.}
#'   }
#'
#' @noRd
#'
fget_feature_representation <- function(soln, problem_data, targets, climate_id, options, Dict) {
  # Check if solution is valid
  if (!inherits(soln, "sf")) {
    return(NULL)
  }

  # Get feature representation based on climate approach.
  # splnr_get_featureRep() uses eval_feature_representation_summary() internally,
  # which only reads the solution column — it does not pick up cost, climate, or
  # other non-feature columns from soln. All features in the problem (including
  # those with target = 0) are returned and flagged correctly as incidental.
  if (climate_id == "NA") {
    all_rep <- spatialplanr::splnr_get_featureRep(
      soln = soln,
      pDat = problem_data,
      climsmart = FALSE
    )
  } else {
    all_rep <- spatialplanr::splnr_get_featureRep(
      soln = soln,
      pDat = problem_data,
      climsmart = TRUE,
      climsmartApproach = options$climate_change,
      targets = targets
    )
  }

  # Split into main (non-silent) and silent sections.
  # Individual SilentFeature layers are never shown in the Targets plot —
  # showing them individually would be confusing and causes duplicate-factor-
  # level errors in splnr_plot_featureRep() when multiple layers share the
  # same nameCommon. They are shown separately in the Details tab.
  silent_vars <- Dict %>%
    dplyr::filter(.data$type == "SilentFeature") %>%
    dplyr::pull("nameVariable")

  if (length(silent_vars) > 0) {
    main_rep   <- all_rep %>% dplyr::filter(!.data$feature %in% silent_vars)
    silent_rep <- all_rep %>% dplyr::filter(.data$feature %in% silent_vars)
  } else {
    main_rep   <- all_rep
    silent_rep <- NULL
  }

  return(list(main = main_rep, silent = silent_rep))
}


# Bioregion display column -----------------------------------------------

#' Build combined bioregion display columns from binary zone columns
#'
#' For each unique \code{categoryID} in the \code{Dict} with
#' \code{type == "Bioregion"}, derives a single integer column (zone index
#' 1..N) by taking \code{which.max()} across the corresponding binary columns.
#' The derived column is named after the \code{categoryID} (e.g.
#' \code{"EnviroZone"}) and is appended to \code{raw_sf}.
#'
#' These columns are \strong{display-only}: they are not added to \code{Dict}
#' and are never passed to \code{prioritizr}. They allow the Layer Information
#' tab to show a single categorical choropleth for each bioregionalisation
#' instead of N separate binary maps.
#'
#' The function is a no-op (returns \code{raw_sf} unchanged) when \code{Dict}
#' contains no \code{Bioregion} rows.
#'
#' @param raw_sf An \code{sf} object containing the binary bioregion columns.
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{type}, \code{nameVariable}, \code{categoryID}).
#'
#' @return \code{raw_sf} with one additional integer column per unique
#'   \code{categoryID} in the Bioregion rows of \code{Dict}.
#'
#' @noRd
#'
fbuild_bioregion_display <- function(raw_sf, Dict) {
  bioregion_rows <- Dict %>%
    dplyr::filter(.data$type == "Bioregion") %>%
    dplyr::select("nameVariable", "categoryID")

  if (nrow(bioregion_rows) == 0) {
    return(raw_sf)
  }

  cat_ids <- unique(bioregion_rows$categoryID)

  for (cat in cat_ids) {
    cols <- bioregion_rows %>%
      dplyr::filter(.data$categoryID == cat) %>%
      dplyr::pull("nameVariable")

    # which.max() returns the index of the first maximum — since each row has
    # exactly one 1 across the binary columns, this gives the zone number (1..N).
    raw_sf[[cat]] <- raw_sf %>%
      sf::st_drop_geometry() %>%
      dplyr::select(dplyr::all_of(cols)) %>%
      apply(1, which.max)
  }

  return(raw_sf)
}


# Feature density (Layer Information tab) ----------------------------------

#' Calculate per-planning-unit feature density
#'
#' Computes the "Feature Density" value shown in the Layer Information tab
#' (\code{mod_4afeatures}): the row-wise sum, across all planning units, of
#' every \strong{Feature} and \strong{Bioregion} column in \code{raw_sf}.
#'
#' \strong{Why Bioregion columns are included, not just Feature columns:}
#' each Bioregion \code{categoryID} (e.g. \code{"EnviroZone"}) is represented
#' in \code{Dict}/\code{raw_sf} as a set of mutually-exclusive binary zone
#' columns (see \code{fbuild_bioregion_display()}): a planning unit covered
#' by that bioregionalisation has exactly one zone column equal to 1, while a
#' planning unit with NO coverage at all (e.g. outside the classified/sampled
#' extent) has every zone column equal to 0. Summing these raw binary columns
#' alongside Feature columns therefore extends Feature Density into a general
#' "where do we have data" signal -- the stated purpose of this layer -- with
#' each independent bioregion scheme contributing at most +1 per planning
#' unit, exactly like a single Feature layer. A planning unit covered by
#' multiple independent bioregion schemes correctly accumulates +1 per
#' covered scheme (e.g. +2 if covered by both an environmental-zone and a
#' depth-zone bioregionalisation).
#'
#' This deliberately sums the RAW per-zone binary Dict columns, NOT the
#' derived combined display column added to \code{raw_sf} by
#' \code{fbuild_bioregion_display()} (e.g. an integer 1..N zone index used
#' only by the Layer Information choropleth dropdown). That combined column
#' is display-only and is never added to \code{Dict}, so pulling
#' \code{"nameVariable"} from \code{Dict} can never accidentally include it --
#' summing zone \emph{indices} would be numerically meaningless (zone 3 is
#' not "3x the density" of zone 1).
#'
#' @param raw_sf An \code{sf} object (or plain data frame) containing Feature
#'   and Bioregion columns as named in \code{Dict$nameVariable}.
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{type} and \code{nameVariable}).
#'
#' @return A numeric vector, one value per row of \code{raw_sf}, giving the
#'   summed Feature + Bioregion values for that planning unit. \code{NA}
#'   values in any contributing column are treated as 0 (\code{rowSums(...,
#'   na.rm = TRUE)}).
#'
#' @noRd
#'
fcalculate_feature_density <- function(raw_sf, Dict) {
  # Intersect with names(raw_sf) to guard against Dict entries that were
  # removed during zero-column filtering in 3_setup_app.R.
  # SilentFeature layers are included so that feature density reflects the
  # actual number of underlying layers (not just the number of visible sliders).
  density_vars <- Dict %>%
    dplyr::filter(.data$type %in% c("Feature", "SilentFeature", "Bioregion")) %>%
    dplyr::pull("nameVariable") %>%
    intersect(names(raw_sf))

  # unname() strips the row-name-derived names that rowSums() inherits from
  # its input data frame -- callers get a plain numeric vector, consistent
  # with other f*() helpers in this file (e.g. fCheckFeatureNo()).
  raw_sf %>%
    sf::st_drop_geometry() %>%
    dplyr::select(dplyr::all_of(density_vars)) %>%
    rowSums(na.rm = TRUE) %>%
    unname()
}


# Check the number of features --------------------------------------------

#' Check the number of features
#'
#' Counts the number of feature columns in \code{dat} by looking up which
#' column names appear in \code{Dict} as type \code{"Feature"} or
#' \code{"Bioregion"}. Falls back to the legacy prefix-exclusion approach
#' when \code{Dict} is not supplied (for backwards compatibility).
#'
#' @param dat An \code{sf} object or data frame containing the problem data.
#' @param Dict Optional data frame. The feature dictionary. When supplied,
#'   only columns whose \code{nameVariable} appears in \code{Dict} with
#'   \code{type \%in\% c("Feature", "Bioregion")} are counted.
#'
#' @noRd
#'
fCheckFeatureNo <- function(dat, Dict = NULL) {
  dat_plain <- sf::st_drop_geometry(dat)

  if (!is.null(Dict)) {
    feature_vars <- Dict %>%
      dplyr::filter(.data$type %in% c("Feature", "SilentFeature", "Bioregion")) %>%
      dplyr::pull("nameVariable")
    f_no <- sum(names(dat_plain) %in% feature_vars)
  } else {
    # Legacy fallback: exclude Cost_ prefix and "metric" column
    f_no <- dat_plain %>%
      dplyr::select(
        -tidyselect::starts_with("Cost_"),
        -tidyselect::any_of("metric")
      ) %>%
      ncol()
  }

  return(f_no)
}
