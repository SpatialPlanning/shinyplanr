#' 5coverage UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_5coverage_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::h2("Upload Protected Area"),
      shiny::p("Upload a spatial file containing polygons to evaluate how well they conserve the features in the planning domain."),
      shiny::br(),

      shiny::fileInput(
        inputId = ns("uploadFile"),
        label = "Choose a spatial file",
        accept = c(".gpkg", ".gdb"),
        multiple = FALSE
      ),

      shiny::helpText("Accepted formats: GeoPackage (.gpkg), File Geodatabase (.gdb)"),

      shiny::br(),
      shiny::uiOutput(ns("uploadStatus")),

      width = 4
    ),

    shiny::mainPanel(
      shinydisconnect::disconnectMessage(
        text = "Your session timed out, reload the application.",
        refresh = "Reload now",
        background = "#f89f43",
        colour = "white",
        overlayColour = "grey",
        overlayOpacity = 0.3,
        refreshColour = "brown"
      ),

      shiny::h2("Coverage Analysis"),
      shiny::p("Upload a spatial file to visualise the protected area and evaluate feature coverage."),
      shiny::br(),

      # Leaflet map for uploaded polygons
      shiny::h3("Uploaded Polygons"),
      shinycssloaders::withSpinner(
        leaflet::leafletOutput(ns("leaflet_coverage"), height = "500px")
      ),

      shiny::br(),
      shiny::hr(),

      # Feature coverage plot
      shiny::h3("Feature Coverage"),
      shiny::p("This plot shows how well the uploaded polygons conserve each feature."),
      shiny::uiOutput(ns("coveragePlotContainer")),

      width = 8
    )
  )
}

#' 5coverage Server Functions
#'
#' @noRd
mod_5coverage_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Store uploaded spatial data
    uploaded_sf <- shiny::reactiveVal(NULL)

    # Store validation status
    upload_status <- shiny::reactiveVal(NULL)

    # Initialize the base leaflet map (runs once)
    output$leaflet_coverage <- leaflet::renderLeaflet({
      leaflet::leaflet() %>%
        leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron)
    })

    # Handle file upload
    shiny::observeEvent(input$uploadFile, {
      shiny::req(input$uploadFile)

      # Reset status
      upload_status(NULL)
      uploaded_sf(NULL)

      # Validate and read the file
      result <- fread_uploaded_spatial(input$uploadFile)

      if (result$success) {
        uploaded_sf(result$data)
        upload_status(list(
          type = "success",
          message = paste0("Successfully loaded ", nrow(result$data), " polygon(s).")
        ))
      } else {
        upload_status(list(
          type = "error",
          message = result$message
        ))
      }
    })

    # Render upload status message
    output$uploadStatus <- shiny::renderUI({
      status <- upload_status()

      if (is.null(status)) {
        return(NULL)
      }

      if (status$type == "success") {
        shiny::div(
          class = "alert alert-success",
          shiny::icon("check-circle"),
          shiny::span(status$message)
        )
      } else {
        shiny::div(
          class = "alert alert-danger",
          shiny::icon("exclamation-triangle"),
          shiny::span(status$message)
        )
      }
    })

    # Update leaflet map when spatial data is uploaded
    shiny::observeEvent(uploaded_sf(), {
      sf_data <- uploaded_sf()

      if (is.null(sf_data)) {
        # Clear the map if no data
        leaflet::leafletProxy("leaflet_coverage", session = session) %>%
          leaflet::clearShapes()
        return()
      }

      # Transform to WGS84 for Leaflet
      sf_wgs84 <- sf_data %>%
        sf::st_transform("EPSG:4326")

      # Get bounding box for map view
      bbox <- sf::st_bbox(sf_wgs84)

      # Update map with polygons using leafletProxy
      leaflet::leafletProxy("leaflet_coverage", session = session) %>%
        leaflet::clearShapes() %>%
        leaflet::clearControls() %>%
        leaflet::fitBounds(
          lng1 = as.numeric(bbox["xmin"]),
          lat1 = as.numeric(bbox["ymin"]),
          lng2 = as.numeric(bbox["xmax"]),
          lat2 = as.numeric(bbox["ymax"])
        ) %>%
        leaflet::addPolygons(
          data = sf_wgs84,
          fillColor = "lightgrey",
          fillOpacity = 0.7,
          color = "#000000",
          weight = 1,
          highlightOptions = leaflet::highlightOptions(
            weight = 2,
            color = "#666666",
            fillOpacity = 0.9,
            bringToFront = TRUE
          ),
          group = "uploaded_polygons"
        )
    })

    # Calculate coverage data when file is uploaded
    coverageData <- shiny::reactive({
      sf_data <- uploaded_sf()
      shiny::req(sf_data)

      fcalculate_coverage(
        uploaded_sf = sf_data,
        raw_sf = raw_sf,
        Dict = Dict
      )
    })

    # Create coverage plot
    gg_coverage <- shiny::reactive({
      coverage_data <- coverageData()
      shiny::req(coverage_data)

      spatialplanr::splnr_plot_featureRep(
        df = coverage_data,
        category = fget_category(Dict = Dict),
        renameFeatures = TRUE,
        namesToReplace = Dict,
        nr = 2,
        showTarget = FALSE
      ) +
        ggplot2::theme(
          plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
        )
    })

    # Render coverage plot output
    output$gg_coveragePlot <- shiny::renderPlot({
      gg_coverage()
    }, bg = "transparent")

    # Container that shows placeholder or plot
    output$coveragePlotContainer <- shiny::renderUI({
      sf_data <- uploaded_sf()

      if (is.null(sf_data)) {
        shiny::div(
          style = "padding: 40px; text-align: center; background-color: #f5f5f5; border: 1px dashed #ccc; border-radius: 5px;",
          shiny::icon("upload", style = "font-size: 48px; color: #999;"),
          shiny::br(),
          shiny::br(),
          shiny::p("Upload a spatial file to see the feature coverage analysis.",
                   style = "color: #666; font-style: italic;")
        )
      } else {
        shinycssloaders::withSpinner(
          shiny::plotOutput(ns("gg_coveragePlot"), height = "600px")
        )
      }
    })

  })
}

## To be copied in the UI
# mod_5coverage_ui("5coverage_1")

## To be copied in the server
# mod_5coverage_server("5coverage_1")
