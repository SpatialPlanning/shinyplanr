#' Return category df from Dict
#'
#' @noRd
#'
fget_category <- function(Dict) {
  category <- Dict %>%
    dplyr::filter(!.data$type %in% c("Cost", "Justification", "Climate")) %>%
    dplyr::select("nameVariable", "category") %>%
    dplyr::rename(feature = .data$nameVariable)
  # TODO I want to remove this last command and have the app deal with `nanmeVariable`

  return(category)
}



# Get Targets

#' Calculate targets based on inputs
#'
#' @noRd
#'
fget_targets <- function(input, name_check = "sli_", dataType = "Feature") {

  ft <- Dict %>%
    dplyr::filter(.data$type %in% dataType) %>%
    dplyr::pull("nameVariable")

  targets <- ft %>%
    purrr::map(\(x) rlang::eval_tidy(rlang::parse_expr(paste0("input$", paste0(name_check, x))))) %>%
    tibble::enframe() %>%
    tidyr::unnest(cols = .data$value) %>%
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
  targets <- fget_targets(input, name_check = name_check, dataType = "Feature")

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
  targets_bioregion <- cats %>%
    purrr::map(\(x) rlang::eval_tidy(rlang::parse_expr(paste0("input$", paste0(bioregion_name_check, x))))) %>%
    tibble::enframe() %>%
    tidyr::unnest(cols = .data$value) %>%
    dplyr::rename(categoryID = "name", target = "value") %>%
    dplyr::mutate(categoryID = cats) %>%
    dplyr::mutate(target = .data$target / 100) %>% # requires number between 0-1
    dplyr::left_join(ft_bioregion, ., by = "categoryID") %>%
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



#' Title
#'
#' @noRd
#'
fupdate_checkbox <- function(session, id_in, Dict, selected = NA) { # works unless everything is not selected

  if (stringr::str_detect(id_in, "check2") == TRUE) {
    choice <- Dict %>%
      dplyr::filter(.data$Category == stringr::str_remove(id_in, "check2")) # %>%
  } else if (stringr::str_detect(id_in, "check") == TRUE) {
    choice <- Dict %>%
      dplyr::filter(.data$Category == stringr::str_remove(id_in, "check")) # %>%
  }
  choice <- choice %>%
    dplyr::select("NameCommon", "NameVariable") %>%
    tibble::deframe()

  shiny::updateCheckboxGroupInput(
    session = session,
    inputId = id_in,
    choices = choice,
    selected = selected
  )
}



#' Title
#'
#' @noRd
#'
fupdate_checkboxReset <- function(session, id_in, Dict, selected = NA) { # works unless everything is not selected

  if (stringr::str_detect(id_in, "check2") == TRUE) {
    choice <- Dict %>%
      dplyr::filter(.data$Category == stringr::str_remove(id_in, "check2")) # %>%
  } else if (stringr::str_detect(id_in, "check") == TRUE) {
    choice <- Dict %>%
      dplyr::filter(.data$Category == stringr::str_remove(id_in, "check")) # %>%
  }
  choice <- choice %>%
    dplyr::select("NameCommon", "NameVariable") %>%
    tibble::deframe()

  # selected <- ifelse(selected == NA, unlist(choice), selected)
  if (is.na(selected)) {
    shiny::updateCheckboxGroupInput(
      session = session, inputId = id_in,
      choices = choice,
      selected = unlist(choice)
    )
  }
}




#' Reset all inputs to default
#'
#' @noRd
#'
fresetSlider <- function(session, input, output, id = 1) {
  # Add 2 to check ID if using Input2 in the Compare module

  idx <- ifelse(id == 2, "2", "")

  sld <- fcreate_vars(id = id,
                      Dict = Dict,
                      name_check = paste0("sli", idx, "_"),
                      categoryOut = TRUE)

  purrr::walk2(.x = sld$id_in, .y = sld$targetInitial,
               .f = \(x, y) shiny::updateSliderInput(session = session, inputId = x, value = y))
}





# Check the number of features --------------------------------------------

#' Check the number of features
#'
#' @noRd
#'
fCheckFeatureNo <- function(dat) {
  f_no <- dat %>%
    dplyr::select(-tidyselect::starts_with("Cost_"), -tidyselect::any_of("metric")) %>%
    ncol()

  return(f_no)
}


#' Get the names of the locked In variables
#'
#' @noRd
#'
get_lockIn <- function(input, num = "") {

  . <- NULL

  # Are there locked in areas in the app
  inps <- names(input) %>%
    stringr::str_subset(paste0("check",num,"LI_")) %>%
    stringr::str_c("input$", .)

  # Which ones (if any) are selected?
  n_inps <- purrr::map_vec(inps, \(x) rlang::eval_tidy(rlang::parse_expr(x)))

  # Get the selected names
  LI <- inps[n_inps] %>%
    stringr::str_remove_all("input\\$check\\d*LI_")

}


#' Get the names of the locked Out variables
#'
#' @noRd
#'
get_lockOut <- function(input, num = "") {

  . <- NULL

  # Are there locked in areas in the app
  inps <- names(input) %>%
    stringr::str_subset(paste0("check",num,"LO_")) %>%
    stringr::str_c("input$", .)

  # Which ones (if any) are selected?
  n_inps <- purrr::map_vec(inps, \(x) rlang::eval_tidy(rlang::parse_expr(x)))

  # Get the selected names
  LO <- inps[n_inps] %>%
    stringr::str_remove_all("input\\$check\\d*LO_")

}





#' Download Plot - Server Side
#'
#' @noRd
#'
fDownloadPlotServer <- function(input, gg_id, gg_prefix, time_date, width = 19, height = 18) {

  # TODO For some reason, this code is run 5 times (once for each button/tab preseumably)
  # every time the tab is changed. It should only load when the tab is active? Or load all at
  # the start and then not update?


  if (gg_prefix != "DataSummary"){

    # TODO what does this rv do? Stop downloading when nothing run?
    # Create reactiveValues object
    # and set flag to 0 to prevent errors with adding NULL
    rv <- reactiveValues(download_flag = 0)

    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste(gg_prefix, "_", time_date, ".png", sep = "")
      },
      content = function(file) {
        # Guard: ensure a plot exists (analysis has been run and plot created)
        if (is.null(gg_id)) {
          shiny::showNotification(
            "Please run an analysis and generate the plot before downloading.",
            type = "error", duration = 5
          )
          stop("No plot available to download.")
        }
        ggplot2::ggsave(file,
                        plot = gg_id,
                        device = "png", width = width, height = height, units = "in", dpi = 400
        )
        # When the downloadHandler function runs, increment rv$download_flag
        rv$download_flag <- rv$download_flag + 1

        # if (rv$download_flag > 0 & gg_prefix == "Solution") { # trigger event whenever the value of rv$download_flag changes
        #   # shinyjs::alert("File downloaded!")
        #   shinyalert::shinyalert("<h3><strong>Further Information!</strong></h3>", "<h4>Don't forget to also download the data table (Details Tab) to store information about the inputs you provided to this analysis.</h4>",
        #                          type = "info",
        #                          closeOnEsc = TRUE,
        #                          closeOnClickOutside = TRUE,
        #                          html = TRUE,
        #                          callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
        #   )
        #   shinyjs::runjs("window.scrollTo(0, 0)")
        # }
      }
    )
  } else {
    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste(gg_prefix,"_", format(Sys.time(), "%Y%m%d%H%M%S"), ".csv", sep="")
      },
      content = function(file){
        # If you later pass a data frame here, add similar guards and write.csv
        shiny::showNotification(
          "No data available to download yet. Please run an analysis first.",
          type = "error", duration = 5
        )
        stop("No data available to download.")
      })
  }
}
