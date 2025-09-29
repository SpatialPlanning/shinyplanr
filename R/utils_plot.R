
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

  sDat <- sDat %>%
    sf::st_drop_geometry() %>%
    dplyr::select(cost_name, col_name)

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

