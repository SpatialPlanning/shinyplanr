#' Title
#'
#' @noRd
#'
fcreate_vars <- function(id, Dict = Dict, name_check = "check", categoryOut = FALSE) {
  vars <- Dict %>%
    dplyr::filter(.data$type == "Feature") %>%
    dplyr::select(-c("justification", "wsClass", "includeApp", "includeJust", "type")) %>%
    dplyr::mutate(
      id = id,
      id_in = paste(name_check, .data$nameVariable, sep = "")
    )

  if (categoryOut == TRUE) {
    vars <- vars %>%
      dplyr::select("id", "id_in", "nameCommon", "category", "targetMin", "targetMax", "targetInitial")
  } else {
    vars <- vars %>%
      dplyr::select("id", "id_in", "nameCommon", "targetMin", "targetMax", "targetInitial")
  }

  return(vars)
}


#' Title
#'
#' @noRd
#'
fcreate_check <- function(id, Dict = Dict, idType = "Constraint", name_check = "check", categoryOut = FALSE) {

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


#' Title
#'
#' @noRd
#'
fcustom_checkboxGroup <- function(id, id_in, Dict, titl) {
  Dict <- Dict %>%
    dplyr::select("nameCommon", "nameVariable") %>%
    tibble::deframe()

  shiny::checkboxGroupInput(shiny::NS(namespace = id, id = id_in),
    shiny::h5(titl),
    choices = Dict,
    selected = unlist(Dict)
  )
}

#' Title
#'
#' @noRd
#'
fcustom_checkbox <- function(id, id_in, nameCommon) {
  shiny::checkboxInput(shiny::NS(namespace = id, id = id_in),
    label = nameCommon,
    FALSE
  )
}

#' Title
#'
#' @noRd
#'
fcustom_slider <- function(id, id_in, nameCommon, targetMin, targetMax, targetInitial) {
  shiny::sliderInput(
    inputId = shiny::NS(namespace = id, id = id_in),
    label = nameCommon,
    min = targetMin,
    max = targetMax,
    step = 10,
    value = targetInitial
  )
}

#' Title
#'
#' @noRd
#'
fcustom_sliderCategory <- function(varsIn, labelNum) {
  ctgs <- unique(varsIn$category)

  shinyList <- vector("list", length = length(ctgs) * 2)

  for (ctg in 1:length(ctgs)) {
    feats <- varsIn %>%
      dplyr::filter(.data$category == ctgs[ctg]) %>%
      dplyr::select(-"category")

    shinyList[ctg * 2] <- # times as many entries as you want to have for one category per list: here: title and sliders (=2); for example with gap between =3
      list(purrr::pmap(feats, fcustom_slider))
    shinyList[ctg * 2 - 1] <-
      list(shiny::h3(paste0(labelNum, ".", ctg, " ", ctgs[ctg])))
  }

  return(shinyList)
}

#' Title
#'
#' @noRd
#'
fcustom_checkCategory <- function(varsIn, labelNum) {

  # browser()

  ctgs <- unique(varsIn$category)

  shinyList <- vector("list", length = length(ctgs) * 2)

  for (ctg in 1:length(ctgs)) {
    feats <- varsIn %>%
      dplyr::filter(.data$category == ctgs[ctg]) %>%
      dplyr::select(-"category")

    shinyList[ctg * 2] <- # times as many entries as you want to have for one category per list: here: title and sliders (=2); for example with gap between =3
      list(purrr::pmap(feats, fcustom_checkbox))
    shinyList[ctg * 2 - 1] <-
      list(shiny::h3(paste0(labelNum, ".", ctg, " ", ctgs[ctg])))
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

#'
#'
#' #' Custom Drop Down for Climate
#' #'
#' #' @noRd
#' #'
#' fcustom_climate <- function(id, id_in, Dict) {
#'   choice <- Dict %>%
#'     dplyr::filter(.data$type == "Climate") %>%
#'     dplyr::select("nameCommon", "nameVariable") %>%
#'     dplyr::add_row(nameCommon = "Don't consider", .before = 1) %>%
#'     tibble::deframe()
#'
#'   shiny::selectInput(shiny::NS(namespace = id, id = id_in),
#'                      label = NULL, #shiny::h3(" "),
#'                      choices = choice,
#'                      multiple = FALSE
#'   )
#' }



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
    label = NULL, #shiny::h4(" "),
    choices = featureList,
    multiple = FALSE
  )
}
