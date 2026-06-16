#' Return category df from Dict
#'
#' @noRd
#'
fget_category <- function(Dict) {
  category <- Dict %>%
    dplyr::filter(.data$type %in% c("Feature", "Bioregion")) %>%
    dplyr::select("nameVariable", "category") %>%
    dplyr::rename(feature = .data$nameVariable)

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
#'   (e.g. \code{"sli_"} for the Scenario module, \code{"sli2_"} for Compare).
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
#' @param name_check Prefix for slider inputs (e.g., "sli_", "sli2_")
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
#' handling both climate-smart and regular approaches, and filtering
#' to only Feature type (not Cost columns).
#'
#' @param soln Solution sf object
#' @param problem_data Problem object
#' @param targets Targets data frame
#' @param climate_id Climate input ID (or "NA" if not using climate)
#' @param options App options list
#' @param Dict Data dictionary
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

  # Get feature representation based on climate approach
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

  # Filter to only include actual features (not cost or other columns)
  # TODO: This filtering should eventually be moved into spatialplanr::splnr_get_featureRep
  targetPlotData <- targetPlotData %>%
    dplyr::filter(.data$feature %in% (Dict %>%
                                        dplyr::filter(.data$type == "Feature") %>%
                                        dplyr::pull(.data$nameVariable)))

  return(targetPlotData)
}



#' Update a checkbox group input from the feature dictionary
#'
#' Refreshes the choices in a checkbox group input using entries from the
#' feature dictionary filtered by category. The category is derived by
#' stripping the known prefix from \code{id_in} (e.g. \code{"check2"},
#' \code{"check"}).
#'
#' When \code{selected} is \code{NA} (default), all choices are selected
#' (reset behaviour). Pass an explicit character vector to select specific
#' values, or \code{character(0)} to deselect all.
#'
#' @param session Shiny session object.
#' @param id_in Character. The input ID of the checkbox group to update.
#' @param Dict Data frame. The feature dictionary (must contain columns
#'   \code{category}, \code{nameCommon}, \code{nameVariable}).
#' @param selected Character or NA. The selected value(s) after update.
#'   When \code{NA} (default) all choices are selected.
#'
#' @noRd
#'
fupdate_checkbox <- function(session, id_in, Dict, selected = NA) {

  # Derive category by stripping the longest matching prefix first so that
  # "check2" is tried before "check" (avoids partial-match ambiguity).
  if (stringr::str_starts(id_in, "check2")) {
    cat <- stringr::str_remove(id_in, "^check2")
  } else if (stringr::str_starts(id_in, "check")) {
    cat <- stringr::str_remove(id_in, "^check")
  } else {
    cat <- id_in
  }

  choice <- Dict %>%
    dplyr::filter(.data$category == cat) %>%
    dplyr::select("nameCommon", "nameVariable") %>%
    tibble::deframe()

  sel <- if (is.na(selected)) unlist(choice) else selected

  shiny::updateCheckboxGroupInput(
    session  = session,
    inputId  = id_in,
    choices  = choice,
    selected = sel
  )
}




#' Reset all slider inputs to their initial values
#'
#' @param session Shiny session object.
#' @param slider_vars Data frame. Pre-computed slider metadata from
#'   \code{cfg$sidebar$scenario$slider_vars} or
#'   \code{cfg$sidebar$compare$Vars} / \code{Vars2}. Must contain columns
#'   \code{id_in} and \code{targetInitial}.
#'
#' @noRd
#'
fresetSlider <- function(session, slider_vars) {
  purrr::walk2(
    .x = slider_vars$id_in,
    .y = slider_vars$targetInitial,
    .f = \(x, y) shiny::updateSliderInput(session = session, inputId = x, value = y)
  )
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


#' Get the names of the locked In variables
#'
#' @noRd
#'
get_lockIn <- function(input, num = "") {

  # Are there locked in areas in the app
  inps <- names(input) %>%
    stringr::str_subset(paste0("check", num, "LI_"))

  # Which ones (if any) are selected?
  n_inps <- purrr::map_vec(inps, \(x) input[[x]])

  # Get the selected names
  LI <- inps[n_inps] %>%
    stringr::str_remove_all(paste0("check", num, "LI_"))

  return(LI)
}


#' Get the names of the locked Out variables
#'
#' @noRd
#'
get_lockOut <- function(input, num = "") {

  # Are there locked out areas in the app
  inps <- names(input) %>%
    stringr::str_subset(paste0("check", num, "LO_"))

  # Which ones (if any) are selected?
  n_inps <- purrr::map_vec(inps, \(x) input[[x]])

  # Get the selected names
  LO <- inps[n_inps] %>%
    stringr::str_remove_all(paste0("check", num, "LO_"))

  return(LO)
}





#' Download Plot - Server Side
#'
#' Creates a \code{downloadHandler} for a ggplot or data frame output.
#'
#' @param gg_reactive A \strong{reactive} (callable, no parentheses) that
#'   returns the current ggplot object or data frame. Evaluated lazily inside
#'   the \code{content} function so it always reflects the latest analysis.
#' @param gg_prefix Character. Filename prefix (e.g. \code{"Solution"}).
#'   Use \code{"DataSummary"} to trigger CSV download instead of PNG.
#' @param time_date_reactive A \strong{reactive} or \strong{reactiveVal}
#'   (callable, no parentheses) that returns a timestamp string used in the
#'   filename. Evaluated lazily inside \code{filename}.
#' @param width,height Numeric. PNG dimensions in inches. Default 19 × 18.
#'
#' @noRd
#'
fDownloadPlotServer <- function(gg_reactive, gg_prefix, time_date_reactive,
                                width = 19, height = 18) {

  if (gg_prefix != "DataSummary") {

    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste0(gg_prefix, "_", time_date_reactive(), ".png")
      },
      content = function(file) {
        gg <- gg_reactive()
        if (is.null(gg)) {
          shiny::showNotification(
            "Please run an analysis and generate the plot before downloading.",
            type = "error", duration = 5
          )
          stop("No plot available to download.")
        }
        ggplot2::ggsave(file,
                        plot = gg,
                        device = "png", width = width, height = height,
                        units = "in", dpi = 400)
      }
    )

  } else {

    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste0(gg_prefix, "_", time_date_reactive(), ".csv")
      },
      content = function(file) {
        dat <- gg_reactive()
        if (is.null(dat) || !is.data.frame(dat)) {
          shiny::showNotification(
            "No data available to download yet. Please run an analysis first.",
            type = "error", duration = 5
          )
          stop("No data available to download.")
        }
        readr::write_csv(dat, file)
      }
    )

  }

  return(dlPlot)
}


#' Download a solution sf object as a GeoJSON file
#'
#' Shared helper used by \code{mod_2scenario_server} and \code{mod_3compare_server}
#' for the individual-scenario spatial download buttons. Transforms the solution
#' to WGS84 (EPSG:4326), renames \code{solution_1} to \code{solution} if needed,
#' and writes a GeoJSON file.
#'
#' @param sol An \code{sf} object returned by the solver (must contain a
#'   \code{solution_1} or \code{solution} column).
#' @param file Character. Output file path supplied by Shiny's
#'   \code{downloadHandler} content function.
#'
#' @return Invisibly \code{NULL}; called for its side-effect of writing \code{file}.
#'
#' @noRd
#'
fdownload_solution_geojson <- function(sol, file) {
  if (!inherits(sol, "sf")) {
    shiny::showNotification(
      "Please run an analysis before downloading the spatial file.",
      type = "error", duration = 5
    )
    stop("No solution available.")
  }

  # Normalise column name: solution_1 -> solution
  if (!("solution" %in% names(sol))) {
    if ("solution_1" %in% names(sol)) {
      names(sol)[names(sol) == "solution_1"] <- "solution"
    } else {
      sol <- dplyr::mutate(sol, solution = NA_integer_)
    }
  }

  sol_out <- sol %>%
    dplyr::select("solution") %>%
    sf::st_transform("EPSG:4326")

  sf::st_write(sol_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
  invisible(NULL)
}
