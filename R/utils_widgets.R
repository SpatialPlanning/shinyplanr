# utils_widgets.R
# Shiny input/widget helpers: functions that interact with Shiny inputs or
# session objects but are not full module-lifecycle patterns.


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
