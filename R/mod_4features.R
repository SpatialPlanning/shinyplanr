#' 4features UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @import shiny

mod_4features_ui <- function(id, cfg) {
  # Extract config locals
  Dict <- cfg$Dict

  ns <- shiny::NS(id)


  check_ftd <- fcreate_check(
    id = id,
    Dict = Dict,
    idType = "Feature",
    name_check = "checkftd_",
    categoryOut = TRUE
  )

  # shiny::tagList(
  shiny::tabsetPanel(
    id = ns("tabs4"),
    type = "pills",
    shiny::tabPanel("Feature Density",
      value = 3,
      shiny::sidebarLayout(
        shiny::sidebarPanel(
          shiny::h2("Select features"),
          shiny::br(), # add gap
          fcustom_checkCategory(
            varsIn = check_ftd,
            value = TRUE,
            labelNum = NULL
          )
        ),

        # Show a plot of the generated distribution
        shiny::mainPanel(
          shiny::p(""), # Add space
          shiny::h2("Examine Feature Density"),
          shiny::p("This map shows the overall feature density for each planning unit within the domain.
                            Planning units with a higher density of features are more likely to be selected in a given scenario because
                            (although it will depend on other factors such as targets and the cost layer)."),
          shiny::p(""), # Add space
          shiny::plotOutput(ns("gg_dens"), height = "700px") %>%
            shinycssloaders::withSpinner(),
          shiny::uiOutput(ns("web_link"))
        )
      )
    ),
    shiny::tabPanel("Feature Maps",
      value = 1,
      shiny::sidebarLayout(
        shiny::sidebarPanel(
          shiny::p("Choose a feature'."),
          shiny::h2("1. Select Feature"),
          create_fancy_dropdown(id, "checkFeat", Dict)
        ),

        # Show a plot of the generated distribution
        shiny::mainPanel(
          shiny::p(""), # Add space
          shiny::htmlOutput(ns("txt_just")),
          shiny::p(""), # Add space
          shiny::plotOutput(ns("gg_feat"), height = "700px") %>%
            shinycssloaders::withSpinner(),
          shiny::uiOutput(ns("web_link"))
        )
      )
    ),
    shiny::tabPanel("Layer Information",
      value = 2,
      shiny::fluidPage(
        shiny::tableOutput(ns("LayerTable")),
      )
    ),
  )
  # ) # tagList
}

#' 4features Server Functions
#'
#' @noRd
mod_4features_server <- function(id, cfg) {
  # Extract config locals
  Dict <- cfg$Dict
  options <- cfg$options
  raw_sf <- cfg$raw_sf
  bndry <- cfg$bndry
  overlay <- cfg$overlay
  map_theme <- cfg$map_theme

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    #     observeEvent(
    #       {
    #         input$tabs4 == 3
    #       },
    #       {
    # Solution plotting reactive

    # Sorted vector of currently-checked feature IDs, used both to compute
    # the density plot and as the bindCache() key below (mirrors the
    # input$checkFeat pattern used for plotFeature()).
    # Rapid successive checkbox toggles are debounced (300ms) so that ticking
    # several boxes in quick succession only triggers a single recompute of
    # the (expensive) rowSums + ggplot render, rather than one per click.
    checked_ftd_raw <- shiny::reactive({
      ftd_all <- names(input) %>%
        stringr::str_subset("checkftd_")

      idx <- purrr::map_vec(ftd_all, \(x) input[[x]])

      ftd_all[idx] %>%
        stringr::str_remove_all("checkftd_") %>%
        sort()
    })

    checked_ftd <- checked_ftd_raw %>% shiny::debounce(300)

    plotDensity <- shiny::reactive({
      ftd <- checked_ftd()

      dens <- raw_sf %>%
        dplyr::mutate(DummyVar = 0) %>% # Create a dummy variable so it will still plot 0 when nothing selected
        dplyr::mutate(FeatureSum = rowSums(dplyr::across(tidyselect::all_of(c(ftd, "DummyVar"))), na.rm = TRUE)) %>%
        dplyr::select("FeatureSum")

      gg <- spatialplanr::splnr_plot(
        df = dens,
        colNames = "FeatureSum",
        paletteName = "YlGnBu",
        legendTitle = "Density of Features per Planning Unit",
        base_size = options$base_size
      ) +
        spatialplanr::splnr_gg_add(
          Bndry = bndry,
          overlay = overlay,
          cropOverlay = dens,
          ggtheme = map_theme
        ) +
        ggplot2::theme(
          plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          legend.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the legend background transparent
        )
      return(gg)
    }) %>% shiny::bindCache(checked_ftd())


    output$gg_dens <- shiny::renderPlot(
      {
        plotDensity()
      },
      bg = "transparent"
    ) %>% shiny::bindCache(checked_ftd())


    plotFeature <- shiny::reactive({
      sel <- input$checkFeat

      # Determine if the selected value is a combined bioregion display column
      # (i.e. a categoryID added by fbuild_bioregion_display(), not a Dict nameVariable).
      # These columns are present in raw_sf but have no Dict row of their own.
      is_bioregion_display <- sel %in% (
        Dict %>%
          dplyr::filter(.data$type == "Bioregion") %>%
          dplyr::pull("categoryID") %>%
          unique()
      ) && sel %in% names(raw_sf)

      if (is_bioregion_display) {
        # Combined bioregion column: integer zone index 1..N.
        # Convert to factor so ggplot2 treats it as discrete.
        # Use a qualitative HCL palette (base R, no extra dependency).
        pl_title <- Dict %>%
          dplyr::filter(.data$type == "Bioregion", .data$categoryID == sel) %>%
          dplyr::pull("category") %>%
          dplyr::first()

        zone_vals <- raw_sf %>%
          sf::st_drop_geometry() %>%
          dplyr::pull(dplyr::all_of(sel))
        zone_levels <- sort(unique(zone_vals))
        n_zones     <- length(zone_levels)
        palette_cols <- grDevices::hcl.colors(n_zones, palette = "Set2")

        plot_sf <- raw_sf %>%
          dplyr::mutate(dplyr::across(dplyr::all_of(sel), \(x) factor(x, levels = zone_levels)))

        gg <- spatialplanr::splnr_plot(
          df = plot_sf,
          colNames = sel,
          legendTitle = pl_title,
          base_size = options$base_size
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = raw_sf,
            ggtheme = map_theme
          ) +
          ggplot2::scale_fill_manual(
            values   = stats::setNames(palette_cols, as.character(zone_levels)),
            na.value = "grey80",
            name     = pl_title,
            labels   = function(x) paste0("Zone ", x)
          ) +
          ggplot2::theme(
            plot.background   = ggplot2::element_rect(fill = "transparent", colour = NA),
            legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
          )

        return(gg)
      }

      pl_title <- Dict %>%
        dplyr::filter(.data$nameVariable %in% sel) %>%
        dplyr::pull("nameCommon")

      type <- Dict %>%
        dplyr::filter(.data$nameVariable == sel) %>%
        dplyr::pull(type)

      # A feature can appear in Dict with multiple types (e.g. MPAs as both LockIn and LockOut).
      # Taking type[[1]] is safe here because LockIn and LockOut produce identical binary plots.
      type <- type[[1]]

      if (type == "Cost") {
        gg <- spatialplanr::splnr_plot(
          df = raw_sf,
          colNames = sel,
          paletteName = "YlGnBu",
          legendTitle = paste0("Cost Layer: ", pl_title),
          base_size = options$base_size
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = raw_sf,
            ggtheme = map_theme
          ) +
          ggplot2::theme(
            plot.background  = ggplot2::element_rect(fill = "transparent", colour = NA),
            legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
          )

        return(gg)
      } else {
        gg <- spatialplanr::splnr_plot(raw_sf,
          colNames = sel,
          legendTitle = pl_title,
          base_size = options$base_size
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = raw_sf,
            ggtheme = map_theme
          ) +
          ggplot2::theme(
            plot.background  = ggplot2::element_rect(fill = "transparent", colour = NA),
            legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
          )

        return(gg)
      }
    }) %>% shiny::bindCache(input$checkFeat)


    output$gg_feat <- shiny::renderPlot(
      {
        plotFeature()
      },
      bg = "transparent"
    ) %>% shiny::bindCache(input$checkFeat)


    # Feature justification table
    output$LayerTable <- shiny::renderTable({
      Dict %>%
        dplyr::filter(.data$includeJust == TRUE) %>%
        dplyr::select("category", "nameCommon", "justification") %>%
        dplyr::rename(
          Category      = "category",
          Name          = "nameCommon",
          Justification = "justification"
        ) %>%
        dplyr::arrange(.data$Category, .data$Name)
    })

    # Text justification for the spatial plot (shown above the feature map)
    output$txt_just <- shiny::renderUI({
      just <- Dict %>%
        dplyr::filter(.data$nameVariable == input$checkFeat) %>%
        dplyr::pull("justification")
      if (length(just) == 0 || is.na(just) || nchar(just) == 0) {
        return(NULL)
      }
      shiny::p(just)
    })
  })
}


## To be copied in the UI
# mod_4features_ui("4features_ui_1")

## To be copied in the server
# mod_4features_server("4features_ui_1")
