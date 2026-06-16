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


  check_ftd <- fcreate_check(id = id,
                             Dict = Dict,
                             idType = "Feature",
                             name_check = "checkftd_",
                             categoryOut = TRUE)




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
                 fcustom_checkCategory(varsIn = check_ftd,
                                       value = TRUE,
                                       labelNum = NULL)

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
  Dict      <- cfg$Dict
  raw_sf    <- cfg$raw_sf
  bndry     <- cfg$bndry
  overlay   <- cfg$overlay
  map_theme <- cfg$map_theme

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    #     observeEvent(
    #       {
    #         input$tabs4 == 3
    #       },
    #       {
    # Solution plotting reactive

    plotDensity <- shiny::reactive({

      # Derive checked feature IDs inside the reactive so it re-evaluates
      # whenever any checkbox changes (fixes A3: ftd was computed outside reactive).
      ftd_all <- names(input) %>%
        stringr::str_subset("checkftd_")

      idx <- purrr::map_vec(ftd_all, \(x) input[[x]])

      ftd <- ftd_all[idx] %>% stringr::str_remove_all("checkftd_")

      dens <- raw_sf %>%
        dplyr::mutate(DummyVar = 0) %>% # Create a dummy variable so it will still plot 0 when nothing selected
        dplyr::mutate(FeatureSum = rowSums(dplyr::across(tidyselect::all_of(c(ftd, "DummyVar"))), na.rm = TRUE)) %>%
        dplyr::select("FeatureSum")

      gg <- spatialplanr::splnr_plot(df = dens,
                                     colNames = "FeatureSum",
                                     paletteName = "YlGnBu",
                                     legendTitle = "Density of Features per Planning Unit"
      ) +
        spatialplanr::splnr_gg_add(
          Bndry = bndry,
          overlay = overlay,
          cropOverlay = dens,
          ggtheme = map_theme
        ) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       # panel.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the panel background (where the data is plotted) transparent
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                       # legend.box.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the background of the legend box transparent
        )
      return(gg)
    })


    output$gg_dens <- shiny::renderPlot({
      plotDensity()
    }, bg = "transparent")



    plotFeature <- shiny::reactive({

      pl_title <- Dict %>%
        dplyr::filter(.data$nameVariable %in% input$checkFeat) %>%
        dplyr::pull("nameCommon")

      type <- Dict %>%
        dplyr::filter(.data$nameVariable == input$checkFeat) %>%
        dplyr::pull(type)

      # TODO I have fudged this it only returns a single type (e.g. when a feature is both lock in and lock out). Are there situations where this will be a problem?
      # Ideally we would used the same function regardless of the type so this becomes irrelevent.

      type <- type[[1]]

      if (type == "Cost") {
        gg <- spatialplanr::splnr_plot(df = raw_sf,
                                       colNames = input$checkFeat,
                                       paletteName = "YlGnBu",
                                       legendTitle = paste0("Cost Layer: ", pl_title)
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = raw_sf,
            ggtheme = map_theme
          ) +
          ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                         # panel.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the panel background (where the data is plotted) transparent
                         legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                         # legend.box.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the background of the legend box transparent
          )

        return(gg)
      } else {

        gg <- spatialplanr::splnr_plot(raw_sf,
                                       colNames = input$checkFeat,
                                       legendTitle = pl_title
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = raw_sf,
            ggtheme = map_theme
          ) +
          ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                         # panel.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the panel background (where the data is plotted) transparent
                         legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                         # legend.box.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the background of the legend box transparent
          )

        return(gg)
      }
    }) %>% shiny::bindCache(input$checkFeat)


    output$gg_feat <- shiny::renderPlot({
      plotFeature()
    }, bg = "transparent") %>% shiny::bindCache(input$checkFeat)


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
