
#' Define conservation problem for shinyplanr
#'
#' Constructs a \code{prioritizr} problem object from user-selected targets,
#' spatial data, and options. Handles minimum-set and minimum-shortfall
#' objective functions, optional climate-smart approaches, and locked-in /
#' locked-out constraints.
#'
#' @param targets Data frame. Feature-target pairs with columns \code{feature}
#'   (character, matching column names in \code{raw_sf}) and \code{target}
#'   (numeric, 0–1 scale). Typically the output of
#'   \code{fget_targets_with_bioregions()}.
#' @param raw_sf An \code{sf} object containing all feature and cost columns
#'   as well as planning unit geometries.
#' @param options List. App-level options (from the deployment config), including
#'   \code{obj_func} (\code{"min_set"} or \code{"min_shortfall"}),
#'   \code{climate_change} (integer, 0–3), \code{percentile},
#'   \code{direction}, and \code{refugiaTarget}.
#' @param input Shiny input object. Used to read cost, climate, budget, and
#'   lock-in/lock-out input values.
#' @param name_check Character. Prefix for slider input IDs. Default
#'   \code{"sli_"}.
#' @param clim_input Character. Value of the climate dropdown input. Pass
#'   \code{"NA"} (as a string) when climate-smart planning is not selected.
#' @param compare_id Character. Suffix appended to input IDs when called from
#'   the Comparison module (e.g. \code{""} for Scenario, \code{"1"} or
#'   \code{"2"} for the two Compare panels). Default \code{""}.
#'
#' @return A \code{prioritizr} problem object ready for solving.
#'
#' @noRd
#'

fdefine_problem <- function(targets, raw_sf, options, input, name_check = "sli_",
                            clim_input, compare_id = "") {

  #TODO Still need to check on how clim_input is being used here in this function.
  # Many commands expect NA or T/F but it seems like we pass in the input$climateid

  # Create sf object with features/cost -------------------------------------
  out_sf <- raw_sf %>%
    dplyr::select(
      tidyselect::all_of(c(targets$feature,
                           input[[paste0("costid", compare_id)]],
                           "geometry")))

  # Create options for climate-smart ----
  if (is.null(clim_input) || is.na(clim_input) || clim_input == "NA") { # Not Climate-smart
    p_dat <- out_sf # Create the problem data. Nothing more needed if not climate-smart

  } else { # Climate-smart

    # Add climate data and run climate approach --------------------------------------------------------

    # Validate that climate column exists in raw_sf
    clim_col <- input[[paste0("climateid", compare_id)]]

    if (!clim_col %in% names(raw_sf)) {
      warning(paste0("Climate column '", clim_col, "' not found in spatial data. Proceeding without climate-smart planning."))
      p_dat <- out_sf
    } else {
      # TODO Rewrite the functions to allow other names of climate columns
      # Rename column based on user selection
      # Note: Must keep geometry column for sf operations
      climate_sf <- raw_sf %>%
        dplyr::select("metric" = clim_col, "geometry")

      # TODO Update these functions in spatialplanr to remove climate_sf and instead pass a column name....
      # We shouldn't need to name the column 'metric'
      if (options$climate_change == 1) { # CPA approach
        CS_Approach <- spatialplanr::splnr_climate_priorityAreaApproach(
          features = out_sf %>%
            dplyr::select(-input[[paste0("costid", compare_id)]]), # out_sf without cost
          metric = climate_sf,
          percentile = options$percentile,
          targets = targets,
          direction = options$direction,
          refugiaTarget = options$refugiaTarget
        )
      } else if (options$climate_change == 2) { # feature approach
        CS_Approach <- spatialplanr::splnr_climate_featureApproach(
          features = out_sf %>%
            dplyr::select(-input[[paste0("costid", compare_id)]]), # out_sf without cost
          metric = climate_sf,
          percentile = options$percentile,
          targets = targets,
          direction = options$direction,
          refugiaTarget = options$refugiaTarget
        )
      } else if (options$climate_change == 3) { # percentile approach
        CS_Approach <- spatialplanr::splnr_climate_percentileApproach(
          features = out_sf %>%
            dplyr::select(-input[[paste0("costid", compare_id)]]), # out_sf without cost
          metric = climate_sf,
          percentile = options$percentile,
          targets = targets,
          direction = options$direction
        )
      }

      # Get targets
      targets <- CS_Approach$Targets # New targets df with CS targets

      # Create p_dat and add cost column back in.
      # Use a row-ID left_join instead of sf::st_join(join = sf::st_equals) to avoid
      # duplicate rows caused by floating-point geometry mismatches (same fix as spatialplanr).
      cost_col   <- input[[paste0("costid",    compare_id)]]
      clim_col_j <- input[[paste0("climateid", compare_id)]]

      # Build a plain data frame of the columns to attach, keyed by row position
      join_cols <- raw_sf %>%
        sf::st_drop_geometry() %>%
        dplyr::select(dplyr::all_of(c(cost_col, clim_col_j))) %>%
        dplyr::mutate(.row_id = dplyr::row_number())

      p_dat <- CS_Approach$Features %>%
        dplyr::mutate(.row_id = dplyr::row_number()) %>%
        dplyr::left_join(join_cols, by = ".row_id") %>%
        dplyr::select(-".row_id")

      # Sanity check: row count must not have changed
      n_features <- nrow(CS_Approach$Features)
      if (nrow(p_dat) != n_features) {
        stop(paste0(
          "Row-count mismatch after joining cost/climate columns. ",
          "CS_Approach$Features has ", n_features, " rows but p_dat has ", nrow(p_dat), " rows. ",
          "This indicates a bug in the join logic."
        ))
      }
    } # End else block for valid climate column
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

    p1 <- prioritizr::problem(p_dat, "DummyVar", cost_column = "DummyVar") %>%
      prioritizr::add_min_set_objective() %>%
      prioritizr::add_relative_targets(0) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_default_solver(verbose = TRUE)

  }

  ## Set Objective Functions -----------------------------------------------------

  if (options$obj_func == "min_set") {


    p1 <- prioritizr::problem(x = p_dat,
                              features = targets$feature, # targets ensures the features are in the correct order
                              cost_column = input[[paste0("costid", compare_id)]]) %>%
      prioritizr::add_min_set_objective() %>%
      prioritizr::add_relative_targets(targets$target) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_default_solver(verbose = TRUE)

  } else if (options$obj_func == "min_shortfall") {

    # Calculate total value of current cost layer.
    # Note: fdefine_problem() is called inside solution(), which is bound to
    # input$analyse. total_cost is therefore already only recalculated when the
    # user clicks Analyse. A separate reactive would require passing total_cost
    # as an argument here, adding complexity for negligible performance gain.
    total_cost <- p_dat %>%
      sf::st_drop_geometry() %>%
      dplyr::select(input[[paste0("costid", compare_id)]]) %>%
      dplyr::pull() %>%
      sum()

    # Get budget value - use budget1/budget2 for comparison module, budget for scenario module
    budget_id <- if (compare_id == "") "budget" else paste0("budget", compare_id)
    budget_value <- input[[budget_id]]

    p1 <- prioritizr::problem(x = p_dat,
                              features = targets$feature, # targets ensures the features are in the correct order
                              cost_column = input[[paste0("costid", compare_id)]]) %>%
      prioritizr::add_min_shortfall_objective(budget = (budget_value/100) * total_cost) %>% # Create budget from total_cost and %
      prioritizr::add_relative_targets(targets$target) %>%
      prioritizr::add_binary_decisions() %>%
      prioritizr::add_default_solver(verbose = TRUE)

  } # End objective function selection


  ## Do Locked In Regions ----------------------------------------------------

  LI <- get_lockIn(input, num = compare_id)

  if (length(LI) > 0) {
    p1 <- purrr::reduce(
      LI,
      \(prob, li) prob %>% prioritizr::add_locked_in_constraints(as.logical(raw_sf[[li]])),
      .init = p1
    )
  }

  ## Do Locked Out Regions ----------------------------------------------------

  LO <- get_lockOut(input, num = compare_id)

  if (length(LO) > 0) {
    p1 <- purrr::reduce(
      LO,
      \(prob, lo) prob %>% prioritizr::add_locked_out_constraints(as.logical(raw_sf[[lo]])),
      .init = p1
    )
  }


  rm(p_dat)

  return(p1)

}
