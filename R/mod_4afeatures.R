#' 4afeatures UI Function — Interactive Layer Information
#'
#' @description A shiny Module providing an interactive leaflet map for
#'   exploring feature layers. The user selects a layer from a dropdown;
#'   the map updates with a choropleth and the sidebar shows Dict metadata
#'   for the selected layer.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#' @param cfg App configuration list from \code{load_config()}.
#'
#' @noRd
#'
#' @import shiny
#' @importFrom rlang .data
mod_4afeatures_ui <- function(id, cfg) {
  Dict    <- cfg$Dict
  options <- cfg$options

  ns <- shiny::NS(id)

  # Build grouped dropdown choices from Dict, mirroring create_fancy_dropdown()
  # but prepending the special "Feature Density" sentinel at the top.
  # We include all layer types that have spatial data in raw_sf (Feature, Cost,
  # EcosystemServices, LockIn, LockOut) so the user can explore any layer.
  # Justification-only rows are excluded because they have no spatial column.
  displayable_types <- c("Feature", "Cost", "EcosystemServices", "LockIn", "LockOut", "Climate", "Bioregion")

  grouped_choices <- Dict %>%
    dplyr::filter(.data$type %in% displayable_types) %>%
    dplyr::group_by(.data$category) %>%
    dplyr::group_split() %>%
    purrr::set_names(purrr::map_chr(., ~ .x$category[1])) %>%
    purrr::map(~ (.x %>%
      dplyr::select("nameCommon", "nameVariable") %>%
      tibble::deframe()
    ))

  # Prepend the density sentinel as a top-level (ungrouped) entry.
  # selectInput() accepts a mixed list where character scalars are ungrouped
  # and named lists are optgroups — this is the standard Shiny pattern.
  layer_choices <- c(
    list("Feature Density" = "__density__"),
    grouped_choices
  )

  shiny::tagList(
    shiny::div(
      style = "position: relative;",

      # Full-width leaflet map
      shinycssloaders::withSpinner(
        leaflet::leafletOutput(ns("leaflet_map"), height = "650px")
      ),

      # Top-left absolutePanel: layer selector
      # Positioned to avoid overlapping the leaflet zoom controls (top-left).
      # Using left = "60px" to clear the zoom buttons.
      shiny::absolutePanel(
        id       = ns("selectorPanel"),
        fixed    = FALSE,
        draggable = TRUE,
        top      = "10px",
        left     = "60px",
        width    = "280px",
        style    = paste0(
          "background-color: rgba(255, 255, 255, 0.92); ",
          "padding: 10px; border-radius: 5px; z-index: 1000; ",
          "box-shadow: 0 1px 5px rgba(0,0,0,0.4);"
        ),
        shiny::h4("Select Layer", style = "margin-top: 0; margin-bottom: 8px;"),
        shiny::selectInput(
          inputId  = ns("selectedLayer"),
          label    = NULL,
          choices  = layer_choices,
          selected = "__density__",
          multiple = FALSE,
          width    = "100%"
        )
      ),

      # Top-right absolutePanel: layer information sidebar
      # Mirrors the featurePanel style from mod_2scenario.R (Explore tab).
      shiny::absolutePanel(
        id       = ns("infoPanel"),
        fixed    = FALSE,
        draggable = TRUE,
        top      = "10px",
        right    = "10px",
        width    = "260px",
        style    = paste0(
          "background-color: rgba(255, 255, 255, 0.92); ",
          "padding: 10px; border-radius: 5px; ",
          "max-height: 600px; overflow-y: auto; z-index: 1000; ",
          "box-shadow: 0 1px 5px rgba(0,0,0,0.4);"
        ),
        shiny::uiOutput(ns("infoPanelContent"))
      )
    )
  )
}


#' 4afeatures Server Functions — Interactive Layer Information
#'
#' @noRd
mod_4afeatures_server <- function(id, cfg) {
  Dict    <- cfg$Dict
  options <- cfg$options
  raw_sf  <- cfg$raw_sf

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Transform raw_sf to WGS84 once at module init.
    # raw_sf never changes during a session, so this is safe to do outside
    # any reactive context. Storing as a plain variable (not reactiveVal) avoids
    # unnecessary reactive invalidation on every dropdown change.
    raw_wgs84 <- raw_sf %>% sf::st_transform("EPSG:4326")

    # Pre-compute the bounding box for fitBounds — done once, not per-render.
    bbox <- sf::st_bbox(raw_wgs84)

    # Identify Feature-type columns for the density calculation.
    # Intersect with names(raw_wgs84) to guard against Dict entries that were
    # removed during zero-column filtering in 3_setup_app.R.
    feature_vars <- Dict %>%
      dplyr::filter(.data$type == "Feature") %>%
      dplyr::pull("nameVariable") %>%
      intersect(names(raw_wgs84))

    # Pre-compute density values (rowSums of all Feature columns).
    # This is a plain numeric vector — cheap to compute once and reuse.
    density_vals <- raw_wgs84 %>%
      sf::st_drop_geometry() %>%
      dplyr::select(dplyr::all_of(feature_vars)) %>%
      rowSums(na.rm = TRUE)


    # --- Base map -----------------------------------------------------------
    # Rendered once when the module server initialises (the tab is already
    # visible at this point because app_server.R uses once = TRUE on tab visit).
    # No inner-tab gating needed — unlike the Explore tab in mod_2scenario.R,
    # this module has no inner tabsetPanel, so the map container is always
    # visible when this server runs.
    output$leaflet_map <- leaflet::renderLeaflet({
      leaflet::leaflet() %>%
        leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron) %>%
        leaflet::fitBounds(
          lng1 = as.numeric(bbox["xmin"]),
          lat1 = as.numeric(bbox["ymin"]),
          lng2 = as.numeric(bbox["xmax"]),
          lat2 = as.numeric(bbox["ymax"])
        )
    })


    # --- Layer update observer ----------------------------------------------
    # Fires whenever the user changes the dropdown selection.
    # ignoreInit = FALSE ensures the first layer renders immediately on tab open
    # without requiring a manual selection change.
    #
    # shinyjs::delay(0) defers the leafletProxy commands to the next browser
    # event loop tick, guaranteeing the base map from renderLeaflet has been
    # initialised in the browser before proxy commands arrive.  This is the
    # same pattern used in mod_2scenario.R (Explore tab) to avoid the
    # zero-canvas race condition.
    shiny::observeEvent(
      input$selectedLayer,
      {
        sel <- input$selectedLayer

        if (is.null(sel) || sel == "") {
          return()
        }

        shinyjs::delay(0, {

          if (sel == "__density__") {
            # ----------------------------------------------------------------
            # Feature Density: rowSums of all Feature columns
            # ----------------------------------------------------------------
            pal <- leaflet::colorNumeric(
              palette  = "YlGnBu",
              domain   = density_vals,
              na.color = "#808080"
            )

            leaflet::leafletProxy("leaflet_map", session = session) %>%
              leaflet::clearShapes() %>%
              leaflet::clearControls() %>%
              leaflet::addPolygons(
                data        = raw_wgs84,
                fillColor   = pal(density_vals),
                fillOpacity = 0.7,
                color       = "#444444",
                weight      = 0.5,
                group       = "layer"
              ) %>%
              leaflet::addLegend(
                position = "bottomleft",
                pal      = pal,
                values   = density_vals,
                title    = "Feature Density",
                opacity  = 0.7
              )

            # Sidebar: density description
            output$infoPanelContent <- shiny::renderUI({
              shiny::tagList(
                shiny::h4("Feature Density",
                  style = "margin-top: 0;"
                ),
                shiny::hr(style = "margin: 5px 0;"),
                shiny::p(
                  "The number of features present in each planning unit.",
                  style = "margin-bottom: 8px;"
                ),
                shiny::p(
                  "Planning units with a higher density of features are more likely to be selected in a scenario (though this also depends on targets and the cost layer).",
                  style = "color: #555; font-size: 0.9em;"
                )
              )
            })

          } else {
            # ----------------------------------------------------------------
            # Single feature layer
            # ----------------------------------------------------------------

            # Look up Dict metadata for the selected layer.
            # A layer can appear in Dict with multiple types (e.g. MPAs as both
            # LockIn and LockOut). Take the first row — type[1] is sufficient
            # for palette selection because binary layers produce identical plots
            # regardless of which lock type they represent.
            layer_info <- Dict %>%
              dplyr::filter(.data$nameVariable == sel)

            if (nrow(layer_info) == 0) {
              return()
            }

            layer_type <- layer_info$type[1]

            # Extract the column values as a plain numeric vector.
            # Using st_drop_geometry() + [[]] avoids formula-based column
            # lookup in addPolygons, which can be fragile with special characters
            # in column names.
            col_data <- sf::st_drop_geometry(raw_wgs84)[[sel]]

            # Palette selection:
            #   Continuous (YlGnBu): Cost, EcosystemServices — numeric values
            #   Binary (grey/teal):  Feature, LockIn, LockOut, Bioregion — 0/1
            #   Climate layers are typically continuous (velocity, SST change)
            is_continuous <- layer_type %in% c("Cost", "EcosystemServices", "Climate")

            if (is_continuous) {
              pal <- leaflet::colorNumeric(
                palette  = "YlGnBu",
                domain   = col_data,
                na.color = "#808080"
              )
            } else {
              # Binary presence/absence: grey = absent, teal = present
              pal <- leaflet::colorFactor(
                palette = c("#d3d3d3", "#2a9d8f"),
                domain  = c(0, 1),
                na.color = "#808080"
              )
            }

            leaflet::leafletProxy("leaflet_map", session = session) %>%
              leaflet::clearShapes() %>%
              leaflet::clearControls() %>%
              leaflet::addPolygons(
                data        = raw_wgs84,
                fillColor   = pal(col_data),
                fillOpacity = 0.7,
                color       = "#444444",
                weight      = 0.5,
                group       = "layer"
              ) %>%
              leaflet::addLegend(
                position = "bottomleft",
                pal      = pal,
                values   = col_data,
                title    = layer_info$nameCommon[1],
                opacity  = 0.7
              )

            # Sidebar: Dict metadata for the selected layer
            output$infoPanelContent <- shiny::renderUI({
              just  <- layer_info$justification[1]
              units <- if ("units" %in% names(layer_info)) layer_info$units[1] else NA_character_

              # Base: name + category
              content <- shiny::tagList(
                shiny::h4(layer_info$nameCommon[1],
                  style = "margin-top: 0;"
                ),
                shiny::p(
                  shiny::strong("Category: "),
                  layer_info$category[1],
                  style = "margin-bottom: 4px;"
                ),
                shiny::p(
                  shiny::strong("Type: "),
                  layer_type,
                  style = "margin-bottom: 4px;"
                )
              )

              # Units (if present and non-NA)
              if (!is.na(units) && nchar(trimws(units)) > 0) {
                content <- shiny::tagList(
                  content,
                  shiny::p(
                    shiny::strong("Units: "),
                    units,
                    style = "margin-bottom: 4px;"
                  )
                )
              }

              # Justification (if present and non-empty)
              if (!is.na(just) && nchar(trimws(just)) > 0) {
                content <- shiny::tagList(
                  content,
                  shiny::hr(style = "margin: 8px 0;"),
                  shiny::h5("Justification", style = "margin-bottom: 4px;"),
                  shiny::p(just, style = "color: #333; font-size: 0.9em;")
                )
              }

              # Target range — only for Feature and Bioregion types
              if (layer_type %in% c("Feature", "Bioregion")) {
                t_min  <- layer_info$targetMin[1]
                t_max  <- layer_info$targetMax[1]
                t_init <- layer_info$targetInitial[1]

                if (!is.na(t_min) && !is.na(t_max) && !is.na(t_init)) {
                  content <- shiny::tagList(
                    content,
                    shiny::hr(style = "margin: 8px 0;"),
                    shiny::h5("Target", style = "margin-bottom: 4px;"),
                    shiny::p(
                      shiny::strong("Range: "),
                      paste0(t_min, "\u2013", t_max, "%"),
                      style = "margin-bottom: 2px;"
                    ),
                    shiny::p(
                      shiny::strong("Default: "),
                      paste0(t_init, "%"),
                      style = "margin-bottom: 2px;"
                    )
                  )
                }
              }

              content
            }) # end renderUI
          } # end else (single layer)

        }) # end shinyjs::delay(0)
      },
      ignoreNULL = TRUE,
      ignoreInit = FALSE
    ) # end observeEvent

  }) # end moduleServer
} # end mod_4afeatures_server


## To be copied in the UI
# mod_4afeatures_ui("4afeatures_ui_1", cfg)

## To be copied in the server
# mod_4afeatures_server("4afeatures_ui_1", cfg)
