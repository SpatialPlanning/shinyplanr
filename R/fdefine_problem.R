
#' Define conservation problem for shinyplanr
#'
#' @param targets
#' @param raw_sf
#' @param options
#' @param input
#' @param name_check
#' @param clim_input
#' @param compare_id
#'
#' @noRd
#'

fdefine_problem <- function(targets, raw_sf, options, input, name_check = "sli_",
                            clim_input, compare_id = "") {

  . <- NULL

  #TODO Still need to check on how clim_input is being used here in this function.
  # Many commands expect NA or T/F but it seems like we pass in the input$climateid

  # Create sf object with features/cost -------------------------------------
  out_sf <- raw_sf %>%
    dplyr::select(
      tidyselect::all_of(c(targets$feature,
                           rlang::eval_tidy(rlang::parse_expr(paste0("input$costid", compare_id))))))

  # Create options for climate-smart ----
  if (clim_input == "NA") { # Not Climate-smart
    p_dat <- out_sf # Create the problem data. Nothing more needed if not climate-smart

  } else { # Climate-smart

    # Add climate data and run climate approach --------------------------------------------------------

    # TODO Rewrite the functions to allow other names of climate columns
    # Rename column based on user selection
    if (rlang::eval_tidy(rlang::parse_expr(paste0("input$climateid", compare_id))) != "NA") {

      climate_sf <- raw_sf %>%
        dplyr::select("metric" = rlang::eval_tidy(rlang::parse_expr(paste0("input$climateid", compare_id))))
    }

    # TODO Update these functions in spatialplanr to remove climate_sf and instead pass a column name....
    # We shouldn't need to name the column 'metric'
    if (options$climate_change == 1) { # CPA approach

      CS_Approach <- spatialplanr::splnr_climate_priorityAreaApproach(
        features = out_sf %>%
          dplyr::select(-rlang::eval_tidy(rlang::parse_expr(paste0("input$costid", compare_id)))), # out_sf without cost
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction,
        refugiaTarget = options$refugiaTarget
      )
    } else if (options$climate_change == 2) { # feature approach

      CS_Approach <- spatialplanr::splnr_climate_featureApproach(
        features = out_sf %>%
          dplyr::select(-rlang::eval_tidy(rlang::parse_expr(paste0("input$costid", compare_id)))), # out_sf without cost
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction,
        refugiaTarget = options$refugiaTarget
      )
    } else if (options$climate_change == 3) { # percentile approach

      CS_Approach <- spatialplanr::splnr_climate_percentileApproach(
        features = out_sf %>%
          dplyr::select(-rlang::eval_tidy(rlang::parse_expr(paste0("input$costid", compare_id)))), # out_sf without cost
        metric = climate_sf,
        percentile = options$percentile,
        targets = targets,
        direction = options$direction
      )
    }

    # Get targets
    targets <- CS_Approach$Targets # New targets df with CS targets

    # Create p_dat and add cost column back in.
    p_dat <- CS_Approach$Features %>%
      sf::st_join(raw_sf %>%
                    dplyr::select(rlang::eval_tidy(rlang::parse_expr(paste0("input$costid", compare_id))),
                                  rlang::eval_tidy(rlang::parse_expr(paste0("input$climateid", compare_id)))),
                  join = sf::st_equals)
  } # End climate data analysis


  f_no <- fCheckFeatureNo(p_dat) # Check number of features


  ## Set up problem -------------------------------------------------

  if (f_no == 1) { # If geometry is the only column

    shinyalert::shinyalert("Error", "No features have been selected. You can't run a spatial prioritization without any features.",
                           type = "error",
                           callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
    )

    p_dat <- p_dat %>%
      dplyr::mutate(DummyVar = 1)

    p1 <- prioritizr::problem(p_dat, "DummyVar") %>%
      prioritizr::add_min_set_objective() %>%
      prioritizr::add_relative_targets(0) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_cbc_solver(verbose = TRUE)

  }

  ## Set Objective Functions -----------------------------------------------------

  if (options$obj_func == "min_set") {

    p1 <- prioritizr::problem(x = p_dat,
                              features = targets$feature,
                              cost_column = eval(parse(text = paste0("input$costid", compare_id)))) %>%
      prioritizr::add_min_set_objective() %>%
      prioritizr::add_relative_targets(targets$target) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_cbc_solver(verbose = TRUE)

  } else if (options$obj_func == "min_shortfall") {

    # Calculate total value of current cost layer
    # TODO make this a reactive and then this only needs to be done when cost layer changes
    total_cost <- p_dat %>%
      sf::st_drop_geometry() %>%
      dplyr::select(input$costid) %>%
      dplyr::pull() %>%
      sum()

    p1 <- prioritizr::problem(x = p_dat,
                              features = targets$feature,
                              cost_column = eval(parse(text = paste0("input$costid", compare_id)))) %>%
      prioritizr::add_min_shortfall_objective(budget = (input$budget/100) * total_cost) %>% # Create budget from total_cost and %
      prioritizr::add_relative_targets(targets$target) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_cbc_solver(verbose = TRUE)

  } # End objective function selection


  ## Do Locked In Regions ----------------------------------------------------

  LI <- get_lockIn(input, num = compare_id)

  if (length(LI) > 0) {
    for (idx in 1:length(LI)){
      p1 <- p1 %>%
        prioritizr::add_locked_in_constraints(as.logical(
          rlang::eval_tidy(rlang::parse_expr(paste0("raw_sf$",LI[idx])))
        ))
    } # End loop
  } # End Lock In



  ## Do Locked Out Regions ----------------------------------------------------

  LO <- get_lockOut(input, num = compare_id)

  if (length(LO) > 0) {
    for (idx in 1:length(LO)){
      p1 <- p1 %>%
        prioritizr::add_locked_out_constraints(as.logical(
          rlang::eval_tidy(rlang::parse_expr(paste0("raw_sf$",LO[idx])))
        ))
    } # End loop
  } # End Lock In


  rm(p_dat)

  return(p1)

}
