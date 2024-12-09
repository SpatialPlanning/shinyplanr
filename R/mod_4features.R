#' 4features UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList

mod_4features_ui <- function(id) {
  ns <- shiny::NS(id)
  # shiny::tagList(
    tabsetPanel(
      id = "tabs4", # type = "pills",
      tabPanel("Layer Maps",
        value = 1,
        shiny::sidebarLayout(
          shiny::sidebarPanel(
            shiny::p("Choose a feature'."),
            shiny::h2("1. Select Layer"),
            create_fancy_dropdown(id, Dict, "checkFeat")
          ),

          # Show a plot of the generated distribution
          shiny::mainPanel(
            shiny::p(""), # Add space
            shiny::htmlOutput(ns("txt_just")),
            shiny::p(""), # Add space
            shiny::plotOutput(ns("gg_feat"), height = "700px") %>%
              shinycssloaders::withSpinner(), # %>%
            shiny::uiOutput(ns("web_link"))
          )
        )
      ),
      tabPanel("Layer Justification",
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
mod_4features_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

  # TODO Extract the chosen name from the Dict file and get the category. Otherwise
  # there will be a problem if, for example, cost doesn't start with Cost_ etc


    if (input$checkFeat == "Cost_None") { # to avoid No Cost Cost
      pl_title <- " "
    } else {
      pl_title <- Dict %>%
        dplyr::filter(.data$nameVariable %in% input$checkFeat) %>%
        dplyr::pull("nameCommon")
    }

    plotFeature <- shiny::reactive({

      if (input$checkFeat == "climdat") {
        gg <- create_climDataPlot(climate_sf) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = df,
            ggtheme = map_theme
          )

        return(gg)

      } else if (startsWith(input$checkFeat, "Cost_")) {
        df <- raw_sf %>%
          sf::st_as_sf() %>%
          dplyr::select(
            "geometry",
            input$checkFeat
          )

        gg <- spatialplanr::splnr_plot(
          df = df, col_names = input$checkFeat,
          paletteName = "YlGnBu",
          legend_title = paste0("Cost Layer: ", pl_title)
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = df,
            ggtheme = map_theme
          )

        return(gg)
      } else {

        gg <- spatialplanr::splnr_plot(raw_sf %>% sf::st_as_sf(),
          col_names = input$checkFeat,
          legend_title = pl_title
        ) +
          spatialplanr::splnr_gg_add(
            Bndry = bndry,
            overlay = overlay,
            cropOverlay = df,
            ggtheme = map_theme
          )

        return(gg)
      }
    }) %>% shiny::bindCache(input$checkFeat)


    output$gg_feat <- shiny::renderPlot({
      plotFeature()
    }) %>% shiny::bindCache(input$checkFeat)


    # Feature justification table
    output$LayerTable <- shiny::renderTable({

      Dict %>%
        dplyr::filter(.data$includeJust == TRUE) %>%
        dplyr::select("category", "nameCommon", "justification") %>%
        dplyr::rename(Category = "category", Name = "nameCommon", Justification = "justification") %>%
        dplyr::arrange(.data$Category, .data$Name)
    })

    # Text justification for the spatial plot
    output$txt_just <- shiny::renderText(
      Dict %>%
        dplyr::filter(.data$nameVariable == input$checkFeat) %>%
        dplyr::pull(.data$justification)
    )
  })
}



## To be copied in the UI
# mod_4features_ui("4features_ui_1")

## To be copied in the server
# mod_4features_server("4features_ui_1")
