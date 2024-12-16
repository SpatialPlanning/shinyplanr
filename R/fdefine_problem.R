
#' Define conservation problem
#'
#' @noRd
#'

fdefine_problem <- function(targets, input, name_check = "sli_", clim_input = FALSE, compare_id = "") {

  #TODO need to get this to work for cost layers without Cost_ at the start

  #TODO Move function to a new file. re write and structure the file...

  browser()

  # TODO raw_sf, options  is not passed into the function

  out_sf <- raw_sf %>%
    dplyr::select(
      .data$geometry,
      tidyselect::all_of(targets$feature)
      # tidyselect::starts_with("Cost_")
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
