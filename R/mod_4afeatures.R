#' 4afeatures UI Function — Interactive Layer Information
#'
#' @description A shiny Module providing an interactive leaflet map for
#'   exploring feature layers. The user selects a layer from a dropdown;
#'   the map updates with a WebGL choropleth and the sidebar shows Dict
#'   metadata for the selected layer.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#' @param cfg App configuration list from \code{load_config()}.
#'
#' @noRd
#'
#' @import shiny
#' @importFrom rlang .data
#' @importFrom grDevices col2rgb
mod_4afeatures_ui <- function(id, cfg) {
  Dict    <- cfg$Dict
  options <- cfg$options

  ns <- shiny::NS(id)

  # Build grouped dropdown choices from Dict, mirroring create_fancy_dropdown()
  # but prepending the special "Feature Density" sentinel at the top.
  # We include all layer types that have spatial data in raw_sf (Feature, Cost,
  # EcosystemServices, LockIn, LockOut, Climate, Bioregion).
  # Justification-only rows are excluded because they have no spatial column.
  displayable_types <- c("Feature", "Cost", "EcosystemServices", "LockIn", "LockOut", "Climate", "Bioregion")

  # For Bioregion rows: collapse to one entry per categoryID.
  # The value is the categoryID (= the combined display column built by
  # fbuild_bioregion_display()). The display label is the shared category string.
  bioregion_entries <- Dict %>%
    dplyr::filter(.data$type == "Bioregion") %>%
    dplyr::distinct(.data$category, .data$categoryID) %>%
    dplyr::rename(nameCommon = "category", nameVariable = "categoryID") %>%
    dplyr::mutate(category = .data$nameCommon)

  other_entries <- Dict %>%
    dplyr::filter(.data$type %in% displayable_types, .data$type != "Bioregion") %>%
    dplyr::select("nameCommon", "nameVariable", "category")

  combined_dict <- dplyr::bind_rows(other_entries, bioregion_entries)

  # Group order follows dplyr::group_by()'s handling of the grouping key:
  # when Dict$category is an ordered factor (see forder_dict_categories()),
  # groups are emitted in factor level order (the app's canonical category
  # order), not alphabetically.
  #
  # .x$category[1] returns a length-1 factor (not character) when category
  # is a factor; as.character() is required because purrr::map_chr() does
  # not coerce factors and would otherwise error.
  grouped_choices <- combined_dict %>%
    dplyr::group_by(.data$category) %>%
    dplyr::group_split() %>%
    purrr::set_names(purrr::map_chr(., ~ as.character(.x$category[1]))) %>%
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

      # Full-width leaflet map — height fills the viewport minus navbar (~56px),
      # fixed footer (~120px), and a small buffer (4px) for borders.
      # calc(100vh - Npx) is self-contained and does not require ancestor
      # elements to have explicit heights (unlike height: 100%).
      shinycssloaders::withSpinner(
        leaflet::leafletOutput(ns("leaflet_map"), height = "calc(100vh - 180px)")
      ),

      # Top-left absolutePanel: layer selector
      # left = "60px" clears the leaflet zoom control buttons.
      shiny::absolutePanel(
        id        = ns("selectorPanel"),
        fixed     = FALSE,
        draggable = TRUE,
        top       = "10px",
        left      = "60px",
        width     = "280px",
        style     = paste0(
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
        id        = ns("infoPanel"),
        fixed     = FALSE,
        draggable = TRUE,
        top       = "10px",
        right     = "10px",
        width     = "260px",
        style     = paste0(
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
#' @param tab_visible A reactive that returns \code{TRUE} when the Layer
#'   Information tab is the active top-level navbar tab, and \code{FALSE}
#'   otherwise.  Passed from \code{app_server.R} as
#'   \code{reactive(input$navbar == "Layer Information")}.  Used to re-add
#'   the WebGL layer whenever the user returns to this tab, because the
#'   WebGL canvas context is destroyed when the tab panel is hidden.
#'
#' @noRd
mod_4afeatures_server <- function(id, cfg, tab_visible) {
  Dict    <- cfg$Dict
  options <- cfg$options
  raw_sf  <- cfg$raw_sf

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Transform raw_sf to WGS84 once at module init.
    # raw_sf never changes during a session, so this is safe to do outside
    # any reactive context.
    raw_wgs84 <- raw_sf %>% sf::st_transform("EPSG:4326")

    # Pre-compute the bounding box for fitBounds — done once, not per-render.
    bbox <- sf::st_bbox(raw_wgs84)

    # Pre-compute density values (rowSums of all Feature + Bioregion columns).
    # See fcalculate_feature_density() in utils_data.R for full rationale on
    # why Bioregion columns are included alongside Feature columns (this
    # layer's purpose is to show "where do we have data", and a Bioregion
    # scheme's raw binary zone columns are a presence/absence signal exactly
    # like a Feature column).
    # Plain numeric vector — cheap to compute once and reuse.
    density_vals <- fcalculate_feature_density(raw_wgs84, Dict)

    # --- Helper: build WebGL fill colour matrix from a hex colour vector -----
    # leafgl 0.2.4 requires fillColor as a 3-column numeric matrix with values
    # in [0, 1] (r, g, b per row) for per-polygon colours.
    # This is the same pattern used in mod_2scenario.R (Explore tab).
    hex_to_rgb_matrix <- function(hex_vec) {
      t(col2rgb(hex_vec)) / 255
    }

    # Coordinate precision for WebGL polygon payloads.
    #
    # WHY THIS EXISTS: leafgl::addGlPolygons() has no incremental-update API —
    # every single call re-serialises the ENTIRE geometry to GeoJSON (via
    # yyjsonr) and pushes it fresh over the Shiny websocket, regardless of
    # whether only the fill colour changed. yyjsonr's default is full double
    # precision (opts_write_json(digits = -1), i.e. no rounding), so every
    # coordinate is written with ~15 significant digits even though 5 decimal
    # degrees (~1.1 m at the equator) is already far finer than a single
    # planning unit. For a 30k-planning-unit hex grid this roughly halves the
    # serialised payload size with zero visible effect on rendering, which
    # directly reduces both server-side serialisation time and (more
    # importantly on hosted infrastructure like Posit Connect Cloud)
    # websocket transfer time.
    #
    # `digits` is forwarded by leafgl to yyjsonr::opts_write_json() via its
    # `...` argument (confirmed by reading leafgl::addGlPolygons() source —
    # it matches names(...) against names(formals(yyjsonr::opts_write_json))).
    geojson_digits <- 5

    # --- Helper: build and render a layer via leafletProxy ------------------
    # Encapsulates the leafgl rendering + legend + sidebar update so the same
    # logic is not duplicated between the initial render observer and the
    # dropdown change observer.
    #
    # NOTE ON RENDERING STRATEGY: an earlier version of this function tried to
    # cache a static grey "base" WebGL layer across dropdown changes and only
    # rebuild a small "overlay" subset for binary (Feature/LockIn/LockOut)
    # layers, to avoid resending the full planning-unit grid on every click.
    # In practice this only paid off when the user picked binary layers
    # back-to-back; switching to ANY other layer type (Cost, EcosystemServices,
    # Climate, Bioregion, Density) called leafgl::clearGlLayers(), which wipes
    # every WebGL group including "base" — forcing a full resend on the very
    # next binary-layer click anyway. Since users browse freely across layer
    # categories rather than staying within one type, that split added two
    # WebGL groups, extra state (a mutable base_layer_added flag), and more
    # leafletProxy round trips for a cache that was invalidated on most real
    # click sequences — a net loss, and plausibly why performance got worse
    # after that change rather than better. We deliberately use ONE uniform
    # code path for all layer types instead: simpler, and the coordinate
    # precision reduction above addresses the actual payload-size bottleneck
    # regardless of caching strategy.
    render_layer <- function(sel) {
      if (is.null(sel) || sel == "") return()

      if (sel == "__density__") {
        # ----------------------------------------------------------------
        # Feature Density: rowSums of all Feature columns
        # ----------------------------------------------------------------
        pal <- leaflet::colorNumeric(
          palette  = "YlGnBu",
          domain   = density_vals,
          na.color = "#808080"
        )

        hex_colours <- pal(density_vals)
        fill_rgb    <- hex_to_rgb_matrix(hex_colours)

        leaflet::leafletProxy("leaflet_map", session = session) %>%
          leafgl::clearGlLayers() %>%
          leaflet::clearControls() %>%
          leafgl::addGlPolygons(
            data        = raw_wgs84,
            fillColor   = fill_rgb,
            fillOpacity = 0.7,
            stroke      = TRUE,
            group       = "layer",
            digits      = geojson_digits
          ) %>%
          leaflet::addLegend(
            position = "bottomleft",
            pal      = pal,
            values   = density_vals,
            title    = "Feature Density",
            opacity  = 0.7
          )

        output$infoPanelContent <- shiny::renderUI({
          shiny::tagList(
            shiny::h4("Feature Density", style = "margin-top: 0;"),
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
        # Single feature layer OR combined bioregion display column
        # ----------------------------------------------------------------

        # Check if the selected value is a combined bioregion display column
        # (a categoryID added by fbuild_bioregion_display(), not a Dict nameVariable).
        bioregion_cat_ids <- Dict %>%
          dplyr::filter(.data$type == "Bioregion") %>%
          dplyr::pull("categoryID") %>%
          unique()

        is_bioregion_display <- sel %in% bioregion_cat_ids && sel %in% names(raw_wgs84)

        if (is_bioregion_display) {
          # ----------------------------------------------------------------
          # Combined bioregion display: integer zone index 1..N
          # ----------------------------------------------------------------
          bioregion_meta <- Dict %>%
            dplyr::filter(.data$type == "Bioregion", .data$categoryID == sel) %>%
            dplyr::slice(1)

          col_data <- sf::st_drop_geometry(raw_wgs84)[[sel]]
          zone_levels <- sort(unique(col_data))
          n_zones <- length(zone_levels)

          # Use a qualitative HCL palette (base R, no extra dependency).
          # hcl.colors() with palette "Set2" gives perceptually distinct colours
          # for up to ~12 zones; beyond that colours will start to repeat visually
          # but the legend will still be correct.
          palette_cols <- grDevices::hcl.colors(n_zones, palette = "Set2")

          pal <- leaflet::colorFactor(
            palette  = palette_cols,
            domain   = zone_levels,
            na.color = "#808080"
          )

          hex_colours <- pal(col_data)
          fill_rgb    <- hex_to_rgb_matrix(hex_colours)

          leaflet::leafletProxy("leaflet_map", session = session) %>%
            leafgl::clearGlLayers() %>%
            leaflet::clearControls() %>%
            leafgl::addGlPolygons(
              data        = raw_wgs84,
              fillColor   = fill_rgb,
              fillOpacity = 0.7,
              stroke      = TRUE,
              group       = "layer",
              digits      = geojson_digits
            ) %>%
            leaflet::addLegend(
              position = "bottomleft",
              pal      = pal,
              values   = zone_levels,
              title    = bioregion_meta$category,
              labFormat = leaflet::labelFormat(prefix = "Zone "),
              opacity  = 0.7
            )

          output$infoPanelContent <- shiny::renderUI({
            just  <- bioregion_meta$justification
            # as.character() guards against bioregion_meta$category being a
            # length-1 factor (Dict$category is an ordered factor after
            # forder_dict_categories()) -- htmltools tags generally coerce
            # factors fine, but this keeps the value an explicit character
            # for clarity and to avoid any edge-case surprises in rendering.
            shiny::tagList(
              shiny::h4(as.character(bioregion_meta$category), style = "margin-top: 0;"),
              shiny::p(
                shiny::strong("Type: "), "Bioregion",
                style = "margin-bottom: 4px;"
              ),
              shiny::p(
                shiny::strong("Zones: "), n_zones,
                style = "margin-bottom: 4px;"
              ),
              if (!is.na(just) && nchar(trimws(just)) > 0) {
                shiny::tagList(
                  shiny::hr(style = "margin: 8px 0;"),
                  shiny::h5("Justification", style = "margin-bottom: 4px;"),
                  shiny::p(just, style = "color: #333; font-size: 0.9em;")
                )
              }
            )
          })

          return()
        }

        # ----------------------------------------------------------------
        # Standard single feature layer
        # ----------------------------------------------------------------

        # Look up Dict metadata for the selected layer.
        # A layer can appear in Dict with multiple types (e.g. MPAs as both
        # LockIn and LockOut). Take the first row — type[1] is sufficient
        # for palette selection because binary layers produce identical plots
        # regardless of which lock type they represent.
        layer_info <- Dict %>%
          dplyr::filter(.data$nameVariable == sel)

        if (nrow(layer_info) == 0) return()

        layer_type <- layer_info$type[1]

        # Extract the column values as a plain numeric vector.
        col_data <- sf::st_drop_geometry(raw_wgs84)[[sel]]

        # Palette selection:
        #   Continuous (YlGnBu): Cost, EcosystemServices, Climate
        #   Binary (grey/teal):  Feature, LockIn, LockOut — 0/1
        is_continuous <- layer_type %in% c("Cost", "EcosystemServices", "Climate")

        # Binary fill colours (grey = absent, teal = present), defined once so
        # the addGlPolygons fill and the addLegend swatches can never drift
        # out of sync with each other.
        binary_colours <- c("#d3d3d3", "#2a9d8f")

        if (is_continuous) {
          pal <- leaflet::colorNumeric(
            palette  = "YlGnBu",
            domain   = col_data,
            na.color = "#808080"
          )
        } else {
          pal <- leaflet::colorFactor(
            palette  = binary_colours,
            domain   = c(0, 1),
            na.color = "#808080"
          )
        }

        hex_colours <- pal(col_data)
        fill_rgb    <- hex_to_rgb_matrix(hex_colours)

        map_proxy <- leaflet::leafletProxy("leaflet_map", session = session) %>%
          leafgl::clearGlLayers() %>%
          leaflet::clearControls() %>%
          leafgl::addGlPolygons(
            data        = raw_wgs84,
            fillColor   = fill_rgb,
            fillOpacity = 0.7,
            stroke      = TRUE,
            group       = "layer",
            digits      = geojson_digits
          )

        if (is_continuous) {
          # Continuous quantities (Cost, EcosystemServices, Climate): a
          # colorNumeric legend showing the raw value range is correct here.
          map_proxy %>%
            leaflet::addLegend(
              position = "bottomleft",
              pal      = pal,
              values   = col_data,
              title    = layer_info$nameCommon[1],
              opacity  = 0.7
            )
        } else {
          # Binary presence/absence (Feature, LockIn, LockOut): pal/values
          # would ask leaflet to auto-label the legend from the 0/1 domain,
          # literally printing "0" and "1". Passing colors/labels directly
          # avoids relying on that undocumented behaviour and mirrors the
          # explicit colors=/labels= legend used in mod_2scenario.R's
          # Explore tab for the same kind of categorical legend.
          map_proxy %>%
            leaflet::addLegend(
              position = "bottomleft",
              colors   = binary_colours,
              labels   = c("Absent", "Present"),
              title    = layer_info$nameCommon[1],
              opacity  = 0.7
            )
        }

        # Sidebar: Dict metadata for the selected layer
        output$infoPanelContent <- shiny::renderUI({
          just  <- layer_info$justification[1]
          units <- if ("units" %in% names(layer_info)) layer_info$units[1] else NA_character_

          # Base: name + category + type
          content <- shiny::tagList(
            shiny::h4(layer_info$nameCommon[1], style = "margin-top: 0;"),
            shiny::p(
              shiny::strong("Category: "), as.character(layer_info$category[1]),
              style = "margin-bottom: 4px;"
            ),
            shiny::p(
              shiny::strong("Type: "), layer_type,
              style = "margin-bottom: 4px;"
            )
          )

          # Units (if present and non-NA)
          if (!is.na(units) && nchar(trimws(units)) > 0) {
            content <- shiny::tagList(
              content,
              shiny::p(
                shiny::strong("Units: "), units,
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
    } # end render_layer()


    # --- Base map (rendered once) -------------------------------------------
    # renderLeaflet runs once at module initialisation.  The WebGL layer is
    # added separately via leafletProxy so it can be restored on every tab
    # visit without re-creating the base map (which would wipe the GL layer).
    output$leaflet_map <- leaflet::renderLeaflet({
      leaflet::leaflet() %>%
        leaflet::addProviderTiles(options$leaflet_provider) %>%
        leaflet::fitBounds(
          lng1 = as.numeric(bbox["xmin"]),
          lat1 = as.numeric(bbox["ymin"]),
          lng2 = as.numeric(bbox["xmax"]),
          lat2 = as.numeric(bbox["ymax"])
        )
    })


    # --- Tab-visibility observer --------------------------------------------
    # tab_visible() is TRUE whenever the Layer Information navbar tab is active.
    # We observe it here (rather than relying on input$navbar, which is not
    # accessible inside moduleServer) to re-add the WebGL layer on every tab
    # visit.  The WebGL canvas context is destroyed when the tab panel is
    # hidden (display:none), so the layer must be restored each time the tab
    # becomes visible.
    #
    # shinyjs::delay(0) defers the leafletProxy commands to the next browser
    # event loop tick, giving the browser time to make the canvas visible and
    # assign it correct dimensions before the WebGL polygon commands arrive.
    #
    # ignoreInit = FALSE so the layer is added on the very first visit (when
    # tab_visible() transitions from FALSE to TRUE for the first time).
    shiny::observeEvent(
      tab_visible(),
      {
        if (!isTRUE(tab_visible())) return()
        shinyjs::delay(0, render_layer(shiny::isolate(input$selectedLayer)))
      },
      ignoreInit = FALSE,
      ignoreNULL = TRUE
    )


    # --- Dropdown change observer -------------------------------------------
    # Fires whenever the user changes the layer selection.
    # delay(0) ensures the browser has processed any pending DOM updates
    # before the WebGL layer is replaced.
    # ignoreInit = TRUE because the tab-visibility observer above handles the
    # initial render on first tab visit.
    shiny::observeEvent(
      input$selectedLayer,
      {
        shinyjs::delay(0, render_layer(input$selectedLayer))
      },
      ignoreInit = TRUE,
      ignoreNULL = TRUE
    )

  }) # end moduleServer
} # end mod_4afeatures_server


## To be copied in the UI
# mod_4afeatures_ui("4afeatures_ui_1", cfg)

## To be copied in the server
# mod_4afeatures_server("4afeatures_ui_1", cfg)
