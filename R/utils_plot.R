
# Climate Feature Plot ----------------------------------------------------
#' Climate Feature Plot
#'
#' @noRd
#'
create_climDataPlot <- function(df) {
  gg_clim <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = df %>% sf::st_as_sf(), ggplot2::aes(fill = .data$metric), colour = NA) +
    ggplot2::scale_fill_viridis_c(
      name = "Climate resilience metric\n(climate exposure and velocity)",
      option = "C",
      guide = ggplot2::guide_colourbar(
        title.position = "bottom",
        title.hjust = 0.5,
        order = 1,
        barheight = grid::unit(0.03, "npc"),
        barwidth = grid::unit(0.25, "npc")
      )
    )

  return(gg_clim)
}



#' Get solution text for plot
#'
#' @noRd
fSolnText <- function(input, sDat, cost_name, col_name = "solution_1") {

  # Guard: must be an sf/data-frame with required columns
  if (is.null(sDat) || !inherits(sDat, "sf")) {
    return(list("No solution could be generated for the current settings.", NULL))
  }

  s_no_geom <- sDat %>% sf::st_drop_geometry()

  if (!all(c(cost_name, col_name) %in% names(s_no_geom))) {
    return(list("No solution text available.", NULL))
  }

  sDat <- s_no_geom %>%
    dplyr::select(dplyr::all_of(c(cost_name, col_name)))

  totalCost <- sDat %>%
    dplyr::pull(cost_name) %>%
    sum()

  outsideCost <- sDat %>%
    dplyr::filter(.data[[col_name]] == 0) %>%
    dplyr::pull(cost_name) %>%
    sum()

  PU_count <- sDat %>%
    dplyr::filter(.data[[col_name]] == 1) %>%
    nrow()

  txt_soln <- paste0("In this scenario ", round(PU_count / nrow(sDat) * 100), "% of the planning region was selected.")
  txt_cost <- paste0(round((outsideCost / totalCost) * 100), "% of the total cost is outside the selected area.")

  out <- list(txt_soln, txt_cost)
  return(out)
}


#' Plot solution with lock-in/lock-out constraints
#'
#' Consolidates the logic for creating solution plots with constraint overlays.
#' Handles lock-in and lock-out areas dynamically based on inputs.
#'
#' @param soln Solution sf object
#' @param input Shiny input object
#' @param raw_sf Raw spatial data with constraint columns
#' @param bndry Boundary sf object
#' @param overlay Overlay sf object
#' @param map_theme ggplot2 theme for map
#' @param num Scenario number ("", "1", or "2" for compare module)
#'
#' @return ggplot2 object
#'
#' @noRd
#'
fplot_solution_with_constraints <- function(soln, input, raw_sf, bndry, overlay, map_theme, num = "") {

  # Base solution plot
  plot_out <- spatialplanr::splnr_plot_solution(
    soln = soln,
    plotTitle = ""
  ) +
    spatialplanr::splnr_gg_add(
      Bndry = bndry,
      overlay = overlay,
      cropOverlay = soln,
      ggtheme = map_theme
    )

  # Add lock-in areas if selected
  LI <- get_lockIn(input, num = num)
  if (length(LI) > 0) {
    plot_out <- plot_out +
      spatialplanr::splnr_gg_add(
        lockIn = raw_sf,
        nameLockIn = LI,
        legendLockIn = "Locked In Areas",
        ggtheme = FALSE
      )
  }

  # Add lock-out areas if selected
  LO <- get_lockOut(input, num = num)
  if (length(LO) > 0) {
    plot_out <- plot_out +
      spatialplanr::splnr_gg_add(
        lockOut = raw_sf,
        nameLockOut = LO,
        legendLockOut = "Locked Out Areas",
        ggtheme = FALSE
      )
  }

  # Apply consistent theme
  plot_out <- plot_out +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      legend.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      legend.position = "bottom",
      legend.direction = "horizontal",
      legend.box = "horizontal"
    )

  return(plot_out)
}


#' Plot climate kernel density for one or two scenarios
#'
#' Creates climate resilience density plots, handling single or dual scenario comparisons.
#'
#' @param soln_list List of solution sf objects (1 or 2)
#' @param climate_ids Character vector of climate input IDs
#' @param solution_names Character vector of solution column names
#'
#' @return ggplot2 object or NULL if no climate data
#'
#' @noRd
#'
fplot_climate_density <- function(soln_list, climate_ids, solution_names = NULL) {

  # Filter out scenarios without climate data
  has_climate <- climate_ids != "NA"

  if (!any(has_climate)) {
    return(NULL)
  }

  # Filter to only scenarios with climate
  soln_filtered <- soln_list[has_climate]
  climate_filtered <- climate_ids[has_climate]

  # Default solution names if not provided
  if (is.null(solution_names)) {
    solution_names <- rep("solution_1", length(soln_filtered))
  } else {
    solution_names <- solution_names[has_climate]
  }

  # Create density plot
  ggClimDens <- spatialplanr::splnr_plot_climKernelDensity(
    soln = soln_filtered,
    solution_names = solution_names,
    climate_names = climate_filtered,
    type = "Normal",
    legendTitle = "Climate resilience metric",
    xAxisLab = "Climate resilience metric"
  ) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
      legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
    )

  return(ggClimDens)
}


