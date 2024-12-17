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
fget_targets <- function(input, name_check = "sli_") {

  ft <- Dict %>%
    dplyr::filter(.data$type != "Constraint", .data$type != "Cost", .data$type != "Climate") %>%
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
fResetFeat <- function(session, input, output, id = 1) {
  # Add 2 to check ID if using Input2 in the Compare module

  idx <- ifelse(id == 2, "2", "")

  sld <- fcreate_vars(id = id,
                      Dict = Dict %>%
                        dplyr::filter(.data$type == "Feature"),
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
      })
  }
}
