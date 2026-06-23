# utils_data.R
# Pure data-wrangling helpers with no Shiny reactivity dependency.
# These functions take data in and return data out; they can be unit-tested
# without a Shiny session.


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
#' @return A tibble with columns Category, Feature, Target (%), Protection (%),
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
      !!paste0("Protection", suffix, " (%)") := "value",
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

  targets <- ft %>%
    purrr::map(\(x) input[[paste0(name_check, x)]]) %>%
    tibble::enframe() %>%
    tidyr::unnest(cols = "value") %>%
    dplyr::rename(feature = "name", target = "value") %>%
    dplyr::mutate(feature = ft) %>%
    dplyr::mutate(target = .data$target / 100) # requires number between 0-1

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

  # Get bioregion targets from inputs
  targets_bioregion_raw <- cats %>%
    purrr::map(\(x) input[[paste0(bioregion_name_check, x)]]) %>%
    tibble::enframe() %>%
    tidyr::unnest(cols = "value") %>%
    dplyr::rename(categoryID = "name", target = "value") %>%
    dplyr::mutate(categoryID = cats) %>%
    dplyr::mutate(target = .data$target / 100) # requires number between 0-1

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
