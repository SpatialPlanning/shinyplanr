#' Build a variable metadata data frame for slider inputs
#'
#' Filters the feature dictionary to a given data type and returns a tibble
#' containing the information needed to build \code{sliderInput} widgets:
#' input IDs, display labels, target range values, and (optionally) category
#' groupings.
#'
#' @param id Character. Shiny module namespace ID used to prefix input IDs.
#' @param Dict Data frame. Feature dictionary (must contain columns
#'   \code{type}, \code{nameVariable}, \code{nameCommon}, \code{category},
#'   \code{categoryID}, \code{targetMin}, \code{targetMax},
#'   \code{targetInitial}, \code{justification}, \code{includeApp},
#'   \code{includeJust}).
#' @param name_check Character. Prefix for slider input IDs (e.g.
#'   \code{"sli_"}, \code{"sli2_"}).
#' @param categoryOut Logical. If \code{TRUE} (default \code{FALSE}), include
#'   \code{category} and \code{categoryID} columns in the output.
#' @param byCategory Logical. If \code{TRUE}, collapse to one row per category
#'   (for category-level master sliders). Requires \code{categoryOut = TRUE}.
#' @param dataType Character. The \code{type} value to filter \code{Dict} on
#'   (default \code{"Feature"}).
#'
#' @return A tibble with columns \code{id}, \code{id_in}, \code{nameCommon},
#'   \code{targetMin}, \code{targetMax}, \code{targetInitial}, and optionally
#'   \code{category} and \code{categoryID}.
#'
#' @noRd
#'
fcreate_vars <- function(id, Dict = Dict, name_check = "check",
                         categoryOut = FALSE, byCategory = FALSE,
                         dataType = "Feature") {

  vars <- Dict %>%
    dplyr::filter(.data$type == dataType) %>%
    dplyr::select(-c("justification", "includeApp", "includeJust", "type")) %>%
    dplyr::mutate(
      id = id,
      id_in = paste(name_check, .data$nameVariable, sep = "")
    )

  if (nrow(vars) > 0){ # If dataType doesn't exist, vars will be 0 here. Just return

    if (categoryOut == TRUE) {
      vars <- vars %>%
        dplyr::select("id", "id_in", "nameCommon", "category", "categoryID", "targetMin", "targetMax", "targetInitial")
    } else {
      vars <- vars %>%
        dplyr::select("id", "id_in", "nameCommon", "targetMin", "targetMax", "targetInitial")
    }


    if (isTRUE(byCategory) & isTRUE(categoryOut)){

      vars <- vars %>%
        dplyr::summarise(id = dplyr::first(.data$id),
                         id_in = paste0("master_sli_", dplyr::first(.data$categoryID)),
                         nameCommon = dplyr::first(.data$category),
                         targetMin = min(.data$targetMin, na.rm = TRUE),
                         targetMax = min(.data$targetMax, na.rm = TRUE),
                         targetInitial = round(mean(.data$targetInitial, na.rm = TRUE)),
                         .by = "category")
    }
  }

  return(vars)
}


#' Build a variable metadata data frame for checkbox inputs
#'
#' Filters the feature dictionary to a given lock-in or lock-out type and
#' returns a tibble containing the information needed to build
#' \code{prettyCheckbox} widgets.
#'
#' @param id Character. Shiny module namespace ID used to prefix input IDs.
#' @param Dict Data frame. Feature dictionary (must contain columns
#'   \code{type}, \code{nameVariable}, \code{nameCommon}, \code{category}).
#' @param idType Character. The \code{type} value to filter \code{Dict} on
#'   (e.g. \code{"LockIn"} or \code{"LockOut"}).
#' @param name_check Character. Prefix for checkbox input IDs (e.g.
#'   \code{"checkLI_"}, \code{"checkLO_"}).
#' @param categoryOut Logical. If \code{TRUE} (default \code{FALSE}), include
#'   the \code{category} column in the output.
#'
#' @return A tibble with columns \code{id}, \code{id_in}, \code{nameCommon},
#'   and optionally \code{category}.
#'
#' @noRd
#'
fcreate_check <- function(id, Dict = Dict, idType, name_check = "check", categoryOut = FALSE) {

  vars <- Dict %>%
    dplyr::filter(.data$type == idType) %>%
    dplyr::select(tidyselect::all_of(c("nameCommon", "nameVariable", "category"))) %>%
    dplyr::mutate(
      id = id,
      id_in = paste(name_check, .data$nameVariable, sep = "")
    )

  if (categoryOut == TRUE) {
    vars <- vars %>%
      dplyr::select("id", "id_in", "nameCommon", "category")
  } else {
    vars <- vars %>%
      dplyr::select("id", "id_in", "nameCommon")
  }

  return(vars)
}

#
# #' Title
# #'
# #' @noRd
# #'
# fcustom_checkboxGroup <- function(id, id_in, Dict, titl) {
#   Dict <- Dict %>%
#     dplyr::select("nameCommon", "nameVariable") %>%
#     tibble::deframe()
#
#   shiny::checkboxGroupInput(shiny::NS(namespace = id, id = id_in),
#                             shiny::h5(titl),
#                             choices = Dict,
#                             selected = unlist(Dict)
#   )
# }



#' Create a single \code{sliderInput} for a conservation feature
#'
#' Wraps \code{shiny::sliderInput()} with consistent label styling and step
#' size. Used internally by \code{fcustom_sliderCategory()}.
#'
#' @param id Character. Shiny module namespace ID.
#' @param id_in Character. The input ID (within the namespace) for this slider.
#' @param nameCommon Character. Display label shown above the slider.
#' @param targetMin Numeric. Minimum slider value (percentage, 0–100).
#' @param targetMax Numeric. Maximum slider value (percentage, 0–100).
#' @param targetInitial Numeric. Initial slider value (percentage, 0–100).
#'
#' @return A \code{sliderInput} tag.
#'
#' @noRd
#'
fcustom_slider <- function(id, id_in, nameCommon, targetMin, targetMax, targetInitial) {

  shiny::sliderInput(
    inputId = shiny::NS(namespace = id, id = id_in),
    label = shiny::div(
      shiny::h5(nameCommon),
      style = "word-wrap: break-word; overflow-wrap: break-word; white-space: normal; width: 100%;"
    ),
    min = targetMin,
    max = targetMax,
    step = 5,
    value = targetInitial
  )
}



#' Build a list of sliders grouped by category
#'
#' Takes the output of \code{fcreate_vars()} and returns a list of Shiny tags
#' comprising category headers (h3) and individual \code{sliderInput} widgets,
#' ready to be passed into a \code{sidebarPanel}.
#'
#' @param varsIn Data frame. Output of \code{fcreate_vars()} containing
#'   columns \code{id}, \code{id_in}, \code{nameCommon}, \code{category},
#'   \code{categoryID}, \code{targetMin}, \code{targetMax},
#'   \code{targetInitial}.
#' @param labelNum Character or numeric. Section number prepended to category
#'   headings (e.g. \code{1} produces headings "1.1 Habitat", "1.2 Coral").
#' @param byCategory Logical. If \code{TRUE}, one slider per category is
#'   rendered (category-level master sliders). Default \code{FALSE}.
#' @param labelCategory Logical. If \code{FALSE}, category headings are
#'   replaced with an invisible spacer (used in the two-column Compare layout).
#'   Default \code{TRUE}.
#'
#' @return A list of Shiny tags.
#'
#' @noRd
#'
fcustom_sliderCategory <- function(varsIn, labelNum, byCategory = FALSE, labelCategory = TRUE) {

  ctgs <- unique(varsIn$category)

  if (isFALSE(byCategory)){

    shinyList <- vector("list", length = length(ctgs) * 2)

    for (ctg in 1:length(ctgs)) {
      feats <- varsIn %>%
        dplyr::filter(.data$category == ctgs[ctg]) %>%
        dplyr::select(-c("category", "categoryID"))

      shinyList[ctg * 2] <- # times as many entries as you want to have for one category per list: here: title and sliders (=2); for example with gap between = 3
        list(purrr::pmap(feats, fcustom_slider))

      if (isTRUE(labelCategory)){ # Show category label
        shinyList[ctg * 2 - 1] <- list(shiny::h3(paste0(labelNum, ".", ctg, " ", ctgs[ctg])))
      } else { # Don't show category label (ie for 2 column of comparison)
        shinyList[ctg * 2 - 1] <- list(shiny::HTML("<h3>&nbsp;</h3>"))
      }
    }

  } else {

    shinyList <- vector("list", length = length(ctgs))

    for (ctg in 1:length(ctgs)) {
      feats <- varsIn %>%
        dplyr::filter(.data$category == ctgs[ctg]) %>%
        dplyr::select(-"category")

      shinyList[ctg] <- list(purrr::pmap(feats, fcustom_slider))
    }
  }

  return(shinyList)
}








#' Build a list of checkboxes grouped by category
#'
#' Takes the output of \code{fcreate_check()} and returns a list of Shiny
#' tags comprising category sub-headings (h5) and individual
#' \code{prettyCheckbox} widgets (from \code{shinyWidgets}), ready to be
#' passed into a \code{sidebarPanel}.
#'
#' @param varsIn Data frame. Output of \code{fcreate_check()} containing
#'   columns \code{id}, \code{id_in}, \code{nameCommon}, \code{category}.
#' @param value Logical. Default checked state for all checkboxes.
#'   Default \code{FALSE}.
#' @param labelNum Character or numeric or \code{NULL}. If provided, prepended
#'   to category headings (e.g. \code{"3"} produces "3.1 MPAs"). Default
#'   \code{NULL} (no number prefix).
#'
#' @return A list of Shiny tags.
#'
#' @noRd
#'
fcustom_checkCategory <- function(varsIn, value = FALSE, labelNum = NULL) {

  fcustom_checkbox <- function(id, id_in, nameCommon, value = FALSE) {
    shinyWidgets::prettyCheckbox(
      inputId = shiny::NS(namespace = id, id = id_in),
      label = nameCommon,
      value = value,
      thick = TRUE,
      animation = "pulse",
      status = "info"
    )
  }

  ctgs <- unique(varsIn$category)

  shinyList <- vector("list", length = length(ctgs) * 2)

  for (ctg in 1:length(ctgs)) {
    feats <- varsIn %>%
      dplyr::filter(.data$category == ctgs[ctg]) %>%
      dplyr::select(-"category")

    shinyList[ctg * 2] <- # times as many entries as you want to have for one category per list: here: title and sliders (=2); for example with gap between =3
      list(purrr::pmap(feats, fcustom_checkbox, value))

    if (is.null(labelNum)){
      shinyList[ctg * 2 - 1] <- list(shiny::h5(
        ctgs[ctg]))
    } else {
      shinyList[ctg * 2 - 1] <- list(shiny::h5(
        paste0(labelNum, ".", ctg, " ", ctgs[ctg])))
    }
  }

  return(shinyList)
}

#' Custom Drop Down for Cost
#'
#' @noRd
#'
fcustom_cost <- function(id, id_in, Dict) {
  choice <- Dict %>%
    dplyr::filter(.data$type == "Cost") %>%
    dplyr::select("nameCommon", "nameVariable") %>%
    tibble::deframe()

  shiny::selectInput(shiny::NS(namespace = id, id = id_in),
                     label = NULL, #shiny::h3(" "),
                     choices = choice,
                     multiple = FALSE
  )
}

#
#
# #' Custom Drop Down for Climate
# #'
# #' @noRd
# #'
# fcustom_climate <- function(id, id_in, Dict) {
#   choice <- Dict %>%
#     dplyr::filter(.data$type == "Climate") %>%
#     dplyr::select("nameCommon", "nameVariable") %>%
#     dplyr::add_row(nameCommon = "Don't consider", .before = 1) %>%
#     tibble::deframe()
#
#   shiny::selectInput(shiny::NS(namespace = id, id = id_in),
#                      label = NULL, #shiny::h3(" "),
#                      choices = choice,
#                      multiple = FALSE
#   )
# }



#' Fancy dropdown menu with categories
#'
#' @noRd
#'
create_fancy_dropdown <- function(id, id_in, Dict) {
  . <- NULL

  featureList <- Dict %>%
    dplyr::group_by(.data$category) %>%
    dplyr::select("nameCommon", "nameVariable", "category") %>%
    dplyr::group_split() %>%
    purrr::set_names(purrr::map_chr(., ~ .x$category[1])) %>%
    purrr::map(~ (.x %>% dplyr::select("nameCommon", "nameVariable"))) %>%
    purrr::map(tibble::deframe)

  shiny::selectInput(inputId = shiny::NS(namespace = id, id = id_in),
                     label = NULL,
                     choices = featureList,
                     multiple = FALSE
  )
}
