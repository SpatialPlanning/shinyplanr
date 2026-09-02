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
  "Feature", "Bioregion", "Cost", "Climate", "LockIn", "LockOut", "EcosystemServices"
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
    dplyr::filter(.data$type %in% c("Feature", "Bioregion")) %>%
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


#' Calculate targets including bioregions
#'
#' Consolidates the logic for getting both feature and bioregion targets.
#' This replaces ~30 lines of duplicated code in both Scenario and Compare modules.
#'
#' @param input Shiny input object
#' @param name_check Prefix for slider inputs (e.g., \code{"sli_"} for Scenario, \code{"sli1_"} / \code{"sli2_"} for Compare)
#' @param Dict The data dictionary
#'
#' @noRd
#'
fget_targets_with_bioregions <- function(input, name_check = "sli_", Dict) {
  # Get feature targets
  targets <- fget_targets(input, Dict = Dict, name_check = name_check, dataType = "Feature")

  # Get bioregion targets if they exist
  ft_bioregion <- Dict %>%
    dplyr::filter(.data$type %in% "Bioregion") %>%
    dplyr::select("feature" = "nameVariable", "categoryID")

  # If no bioregions, return just features
  if (nrow(ft_bioregion) == 0) {
    return(targets)
  }

  # Build bioregion name_check (e.g., "sli_" -> "master_sli_", "sli2_" -> "master_sli2_")
  bioregion_name_check <- paste0("master_", name_check)

  # Get unique categories
  cats <- ft_bioregion %>%
    dplyr::pull("categoryID") %>%
    unique()

  # Get bioregion targets from inputs.
  # purrr::map_dbl() with %||% 0 is type-safe: returns a numeric vector of the
  # same length as cats even when a master slider input is NULL (e.g. not yet
  # initialised). The previous enframe()+unnest() approach silently dropped
  # NULL rows, which could produce a shorter-than-expected targets data frame.
  targets_bioregion_raw <- tibble::tibble(
    categoryID = cats,
    target     = purrr::map_dbl(cats, \(x) input[[paste0(bioregion_name_check, x)]] %||% 0) / 100
  )

  targets_bioregion <- dplyr::left_join(ft_bioregion, targets_bioregion_raw, by = "categoryID") %>%
    dplyr::select(-"categoryID")

  # Combine feature and bioregion targets
  targets_combined <- dplyr::bind_rows(targets, targets_bioregion)

  return(targets_combined)
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
#' @param Dict Data dictionary (unused here; retained for API consistency)
#'
#' @return Data frame with feature representation
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
    targetPlotData <- spatialplanr::splnr_get_featureRep(
      soln = soln,
      pDat = problem_data,
      climsmart = FALSE
    )
  } else {
    targetPlotData <- spatialplanr::splnr_get_featureRep(
      soln = soln,
      pDat = problem_data,
      climsmart = TRUE,
      climsmartApproach = options$climate_change,
      targets = targets
    )
  }

  return(targetPlotData)
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
      dplyr::filter(.data$type %in% c("Feature", "Bioregion")) %>%
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
