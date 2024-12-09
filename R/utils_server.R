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


#' Define conservation problem
#'
#' @noRd
#'

fdefine_problem <- function(targets, input, name_check = "sli_", clim_input = FALSE, compare_id = "") {

  # TODO raw_sf, climate_sf, options  is not passed into the function

  out_sf <- raw_sf %>%
    dplyr::select(
      .data$geometry,
      tidyselect::all_of(targets$feature),
      tidyselect::starts_with("Cost_")
    ) %>%
    sf::st_as_sf()

  if (clim_input == "NA") {
    p_dat <- out_sf
  } else {
    features <- out_sf %>%
      dplyr::select(
        .data$geometry,
        tidyselect::all_of(targets$feature)
      )

    # TODO Rewrite this to allow other names of climate columns
    # Rename column based on user selection

    if (isTruthy(input$climateid)){
      climate_sf <- raw_sf %>%
        sf::st_as_sf() %>%
        dplyr::select("metric" = input$climateid)
    } else if (compare_id == "1" & input$climateid1 != "NA") {
      climate_sf <- raw_sf %>%
        sf::st_as_sf() %>%
        dplyr::select("metric" = input$climateid1)
    } else if (compare_id == "2" & input$climateid2 != "NA") {
      climate_sf <- raw_sf %>%
        sf::st_as_sf() %>%
        dplyr::select("metric" = input$climateid2)
    }


    if (options$climate_change == 1) { # CPA approach

      CS_Approach <- spatialplanr::splnr_climate_priorityAreaApproach(
        features = features,
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction,
        refugiaTarget = options$refugiaTarget
      )
    } else if (options$climate_change == 2) { # feature approach

      CS_Approach <- spatialplanr::splnr_climate_featureApproach(
        features = features,
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction,
        refugiaTarget = options$refugiaTarget
      )
    } else if (options$climate_change == 3) { # percentile approach

      CS_Approach <- spatialplanr::splnr_climate_percentileApproach(
        features = features,
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction
      )
    }

    targets <- CS_Approach$Targets

    # browser()

    p_dat <- CS_Approach$Features %>%
      sf::st_join(out_sf %>% dplyr::select(tidyselect::starts_with("Cost_")),
                  join = sf::st_equals) %>%
      sf::st_join(climate_sf, join = sf::st_equals)
    # } else {
    # print("Something odd is going on here. Check climate-smart tick box.")
  }

  f_no <- fCheckFeatureNo(p_dat) # Check number of features

  if (f_no == 1) {
    shinyalert::shinyalert("Error", "No features have been selected. You can't run a spatial prioritization without any features.",
                           type = "error",
                           callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
    )

    p_dat <- p_dat %>%
      dplyr::mutate(DummyVar = 1)

    p1 <- prioritizr::problem(p_dat, "DummyVar", ) %>%
      prioritizr::add_min_set_objective() %>%
      prioritizr::add_relative_targets(0) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_cbc_solver(verbose = TRUE)
  } else {
    ## Get names of the features
    if (clim_input == TRUE) {
      usedFeatures <- p_dat %>%
        sf::st_drop_geometry() %>%
        dplyr::select(-tidyselect::starts_with("Cost_"), -.data$metric) %>%
        names()
    } else {
      usedFeatures <- targets$feature
    }

    if (options$obj_func == "min_set") {
      p1 <- prioritizr::problem(p_dat, usedFeatures, eval(parse(text = paste0("input$costid", compare_id)))) %>%
        prioritizr::add_min_set_objective() %>%
        prioritizr::add_relative_targets(targets$target) %>%
        prioritizr::add_binary_decisions() %>%
        prioritizr::add_cbc_solver(verbose = TRUE)

      # Do Locked In Regions ----------------------------------------------------

      if (options$lockedInArea != 0) {
        LI <- Dict %>%
          dplyr::filter(.data$categoryID == "LockedInArea") %>%
          dplyr::pull("nameVariable")

        LI_check <- paste0("input$check", compare_id, "LI_", LI)
        LI_sf <- paste0("raw_sf$", LI)

        for (area in 1:length(LI)) { # TODO Why is area here? It is not used anywhere.... Is a placeholder needed?
          if (!rlang::is_null(rlang::eval_tidy(rlang::parse_expr(LI_check)))) {
            p1 <- p1 %>%
              prioritizr::add_locked_in_constraints(as.logical(rlang::eval_tidy(rlang::parse_expr(LI_sf))))
          }
        }
      }
    } else if (options$obj_func == "min_shortfall") {
      # Add new objective functions
    }
  }

  rm(p_dat)

  return(p1)
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
        readr::write_csv(x = gg_id, file = file)
      })
  }
}
