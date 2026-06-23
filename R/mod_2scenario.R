#' 2scenario UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom rlang .data
mod_2scenario_ui <- function(id, cfg) {
  # Extract config locals
  Dict      <- cfg$Dict
  options   <- cfg$options
  sidebar   <- cfg$sidebar$scenario

  ns <- shiny::NS(id)

  # Decide numbering for optional sections
  if (isTRUE(options$include_climateChange)){
    LI_num <- "4"
  } else {
    LI_num <- "3"
  }

  # Unpack all pre-computed sidebar vars from config into the local environment.
  # rlang::env_bind() splices the named list so each key becomes a local variable
  # (e.g. sidebar$slider_vars -> slider_vars, sidebar$check_lockIn -> check_lockIn, etc.).

  slider_vars <- slider_varsBioR <- slider_varsCat <- check_lockIn <- check_lockOut <- NULL

  rlang::env_bind(environment(), !!!sidebar)



  # shiny::tagList(
  # shiny::fluidPage(
  # actionLink("sidebar_button","",icon = icon("bars")
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      width = 4,
      shinyjs::hidden(div(
        id = ns("switchMasterTargets"),
        shiny::h2("1. Select Master Target"),
        shiny::actionButton(ns("resetSlider"), "Reset All Sliders",
                            width = "100%", class = "btn btn-outline-primary",
                            style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
        ),
        shiny::hr(style = "border-top: 1px solid #000000;"),
        shiny::sliderInput(inputId = ns("masterSli"), label = NULL,
                           min = min(Dict$targetMin, na.rm = TRUE), max = max(Dict$targetMax, na.rm = TRUE),
                           step = 5,
                           value = round(mean(Dict$targetInitial, na.rm = TRUE))),
      )),

      shinyjs::hidden(div(
        id = ns("switchCategoryTargets"),
        shiny::h2("1. Select Category Targets"),
        shiny::actionButton(ns("resetSlider"), "Reset All Sliders",
                            width = "100%", class = "btn btn-outline-primary",
                            style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
        ),
        shiny::hr(style = "border-top: 1px solid #000000;"),
        fcustom_sliderCategory(slider_varsCat, labelNum = 1, byCategory = TRUE),
      )),

      shinyjs::hidden(div(
        id = ns("switchIndividualTargets"),
        shiny::h2("1. Select Feature Targets"),
        shiny::actionButton(ns("resetSlider"), "Reset All Sliders",
                            width = "100%", class = "btn btn-outline-primary",
                            style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
        ),
        shiny::hr(style = "border-top: 1px solid #000000;"),
        fcustom_sliderCategory(slider_vars, labelNum = 1, byCategory = FALSE),
      )),

      shinyjs::hidden(div(
        id = ns("switchBioregions"),
        # Hidden by default; shown by the server only when options$include_bioregion
        # is TRUE (see utils_server.R fsetup_ui_switches()). No UI-level conditional
        # is needed because shinyjs::hidden() already prevents rendering until shown.
        shiny::h3(paste0("1.", length(unique(slider_vars$category)) + 1, " Bioregions")),
        fcustom_sliderCategory(slider_varsBioR, labelNum = 1, byCategory = TRUE),
      )),

      shiny::hr(style = "border-top: 1px solid #000000;"),

      shiny::h2("2. Select Cost Layer"),
      create_fancy_dropdown(id, "costid", Dict %>%
                              dplyr::filter(.data$type == "Cost")),


      # Define Objective Function -----

      shinyjs::hidden(div(
        id = ns("switchMinShortfall"),
        shiny::h3("Choose a Budget"),
        shiny::p("This analysis will use the minimum shortfall objective which aims to find the set of
                 planning units that minimize the overall shortfall for the targets for as many features
                 as possible while staying within a fixed budget."),
        shiny::br(),
        shiny::p("Choose the total budget (% of cost layer) for your analysis."),
        shiny::numericInput(
          inputId = ns("budget"),
          label = NULL,
          value = 30,
          min = 0,
          max = 100,
          width = "50%"
        )
      )),

      shinyjs::hidden(div(
        id = ns("switchBoundaryPenalty"),
        shiny::h4("Boundary Penalty"),
        shiny::p("The boundary penalty tries to......"),
        shiny::numericInput(
          inputId = ns("boundaryPenalty"),
          label = NULL,
          value = 100,
          min = 0,
          max = 1000,
        )
      )),



      if (isTRUE(options$include_climateChange)) {
        div(
          shiny::h2("3. Climate-smart"),
          shiny::p("Should the spatial plan be made climate-smart?"),
          shiny::p("NOTE: This will slow down the analysis significantly. Be patient."),
          create_fancy_dropdown(id = id,
                                id_in = "climateid",
                                Dict = Dict %>%
                                  dplyr::filter(.data$type == "Climate") %>%
                                  dplyr::add_row(nameCommon = "Don't consider",
                                                 nameVariable = "NA",
                                                 category = "Climate", .before = 1)),
        )
      },

      shinyjs::hidden(div(
        id = ns("switchConstraints"),
        shiny::h2(paste0(LI_num,". Constraints")),
        shiny::p("You can also lock-in or lock-out some pre-defined areas to ensure they are either specifically included (lock-in) or excluded (lock-out) from the protected area. Planning Units outside these areas will be selected if needed to meet the targets."),
        if (nrow(check_lockIn) > 0) shiny::h3(paste0(LI_num, ".1 Locked-In Areas")),
        fcustom_checkCategory(check_lockIn),
        if (nrow(check_lockOut) > 0) shiny::h3(paste0(LI_num, ".2 Locked-Out Areas")),
        fcustom_checkCategory(check_lockOut),
      )),

      shiny::br(), # Leave space for analysis button at bottom
      shiny::br(), # Leave space for analysis button at bottom
      shiny::fixedPanel(
        style = "z-index:100", # To force the button above all plots.
        shiny::actionButton(ns("analyse"), "Run Analysis", shiny::icon("paper-plane"),
                            width = "100%", class = "btn btn-primary",
                            style = "display: block; float: left; padding:4px; font-size:150%;"
        ),
        right = "71%", bottom = "1%", left = "5%"
      )
    ),
    shiny::mainPanel(
      tabsetPanel(
        id = ns("tabs"),
        type = "pills",
        tabPanel("Scenario",
                 value = "1",
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the buttons above all plots.
                   shiny::div(
                     style = "display:flex; gap:10px; justify-content:flex-end; align-items:center;",
                     shiny::downloadButton(ns("dlSpatial1"), "Download Spatial File",
                                           style = "padding:4px; font-size:120%"),
                     shiny::downloadButton(ns("dlPlot1"), "Download Plot",
                                           style = "padding:4px; font-size:120%")
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_soln")))),
                 shiny::textOutput(ns("txt_soln")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_soln"), height = "700px"))
        ),
        tabPanel("Explore",
                 value = 4,
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_map")))),
                 shiny::textOutput(ns("txt_map")),
                 shiny::br(),
                 shiny::div(
                   style = "position: relative;",
                   shinycssloaders::withSpinner(
                     leaflet::leafletOutput(ns("leaflet_map"), height = "650px")
                   ),
                   shiny::absolutePanel(
                     id = ns("featurePanel"),
                     class = "panel panel-default",
                     fixed = FALSE,
                     draggable = TRUE,
                     top = "5%",
                     right = "10px",
                     width = "250px",
                     style = "background-color: rgba(255, 255, 255, 0.9); padding: 10px; border-radius: 5px; max-height: 600px; overflow-y: auto; z-index: 1000;",
                     shiny::uiOutput(ns("featurePanelContent"))
                   )
                 )
        ),
        tabPanel("Targets",
                 value = 2,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.
                   shiny::downloadButton(ns("dlPlot2"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_target")))),
                 shiny::textOutput(ns("txt_target")),
                 shiny::br(),
                 shiny::selectInput(inputId = ns("checkSort"),
                                    label = "Sort plot by:",
                                    choices = c("Category" = "category",
                                                "Target" = "target",
                                                "Representation" = "representation",
                                                "Difference from Target" = "difference"),
                                    selected = "category",  multiple = FALSE),

                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_targetPlot"), height = "600px"))
        ),
        tabPanel("Cost",
                 value = 3,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.
                   shiny::downloadButton(ns("dlPlot3"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_cost")))),
                 shiny::textOutput(ns("txt_cost")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_cost"), height = "700px"))
        ),

        tabPanel("Climate",
                 value = 6,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.
                   shiny::downloadButton(ns("dlPlot6"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_clim")))),
                 shiny::textOutput(ns("txt_clim")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_clim"), height = "700px"))
        ),
        tabPanel("Ecosystem Services",
                 value = 5,
                 shiny::htmlOutput(ns("txt_ess")),
                 shinycssloaders::withSpinner(reactable::reactableOutput(ns("soln_ess")))
        ),


        tabPanel("Details",
                 value = 7,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot7"), "Download Table",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),

                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_DetsData")))),
                 shiny::tableOutput(ns("DataTable"))
        ),
        tabPanel("Report",
                 value = 10,
                 shiny::span(shiny::h2("Generate Analysis Report")),
                 shiny::p("Download a comprehensive HTML report containing all analysis results from this scenario."),
                 shiny::p("The report includes:"),
                 shiny::tags$ul(
                   shiny::tags$li("Solution map with constraints"),
                   shiny::tags$li("Target achievement chart"),
                   shiny::tags$li("Cost analysis visualization"),
                   shiny::tags$li("Climate resilience analysis (if enabled)"),
                   shiny::tags$li(shiny::tagList(shiny::em("prioritizr"), " log")),
                 ),
                 shiny::br(),
                 shiny::downloadButton(ns("dlReport"), "Download Report",
                                       style = "padding:4px; font-size:120%"),
                 shiny::uiOutput(ns("reportStatus")),
                 shiny::br(),
                 shiny::br(),
                 shiny::p(shiny::em("Note: Report generation may take a few moments. The file will download automatically when ready."),
                          style = "color: #666;")
        ),
        tabPanel("Log",
                 value = 8,
                 shiny::span(shiny::h2("Solver Log")),
                 shiny::textOutput(ns("txt_log_hint")),
                 shinycssloaders::withSpinner(
                   shiny::verbatimTextOutput(ns("logText"), placeholder = TRUE)
                 )
        )
      )
    )
  )
  # ) # taglist end
}

#' 2scenario Server Functions
#'
#' @noRd
mod_2scenario_server <- function(id, cfg) {
  # Extract config locals
  Dict         <- cfg$Dict
  options      <- cfg$options
  raw_sf       <- cfg$raw_sf
  bndry        <- cfg$bndry
  overlay      <- cfg$overlay
  map_theme    <- cfg$map_theme
  sidebar      <- cfg$sidebar$scenario
  tx_2solution <- cfg$tx_2solution
  tx_2targets  <- cfg$tx_2targets
  tx_2cost     <- cfg$tx_2cost
  tx_2climate  <- cfg$tx_2climate
  tx_2ess      <- cfg$tx_2ess

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    . <- NULL

    # Apply all UI show/hide switches driven by options ----
    fapply_ui_switches(options, session,
                       tab_climate = "6",
                       tab_explore = "4",
                       tab_ess     = "5",
                       tab_report  = "10",
                       tab_log     = "8")

    observeEvent(input$disconnect, {
      session$close()
    })

    # Go back to the first tab and top of page when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shiny::updateTabsetPanel(session, "tabs", selected = "1")
      shinyjs::runjs("window.scrollTo(0, 0)")
    })




    # Unpack all pre-computed sidebar vars from config into the local environment.
    # rlang::env_bind() splices the named list so each key becomes a local variable
    # (e.g. sidebar$slider_vars -> slider_vars, sidebar$check_lockIn -> check_lockIn, etc.).
    slider_vars <- slider_varsBioR <- slider_varsCat <- check_lockIn <- check_lockOut <- NULL


    rlang::env_bind(environment(), !!!sidebar)



    # Observe Event for categories - Updates individual sliders
    shiny::observeEvent({
      purrr::map(slider_varsCat$id_in, \(x) input[[x]]) # All category slider inputs
    }, {

      inps <- slider_vars %>%
        # dplyr::filter(category) %>% # TODO I can't filter by category yet. Need to identify changes by category
        dplyr::pull(.data$id_in)

      targ <- slider_varsCat %>%
        dplyr::select("category") %>%
        dplyr::mutate(targetCurrent = purrr::map_vec(slider_varsCat$id_in, \(x) input[[x]])) %>%
        dplyr::right_join(slider_vars, by = "category")

      purrr::map2(inps, targ$targetCurrent, \(x, y) shiny::updateSliderInput(session = session, inputId = x, value = y))

    })


    # Reset all slider groups so the full state is clean regardless of which
    # target mode (master / category / individual) is currently active.
    shiny::observeEvent(input$resetSlider, {
      fresetSlider(session, slider_vars)      # individual feature sliders
      fresetSlider(session, slider_varsCat)   # per-category master sliders
      shiny::updateSliderInput(               # single master slider
        session = session,
        inputId = "masterSli",
        value   = round(mean(Dict$targetInitial, na.rm = TRUE))
      )
    }, ignoreInit = TRUE)

    # Set up paired lock-in/lock-out mutual exclusion observers
    fsetup_lock_observers(input, check_lockIn, check_lockOut,
                          li_prefix = "checkLI_", lo_prefix = "checkLO_")



    # Observe Event for master slider. This updates the individual sliders.
    observeEvent(input$masterSli, {
      inps <- names(input) %>%
        stringr::str_subset("sli_")
      purrr::map(inps, \(x) shiny::updateSliderInput(session = session, inputId = x, value = input$masterSli))
    }, ignoreInit = TRUE)



    # Observe events from individual targets
    # Return targets and names for all features from sliders ---------------------------------------------------
    targetData <- shiny::reactive({
      targets <- fget_targets_with_bioregions(input, name_check = "sli_", Dict = Dict)
      return(targets)
    })



    # bindEvent(input$analyse) freezes p1Data to the inputs at click time,
    # matching solution() which is also bound to input$analyse.
    # Without this, a cost/climate change after clicking Analyse but before visiting
    # the Targets tab would cause targetPlotData to be computed with different inputs
    # than the solution was solved with.
    p1Data <- shiny::reactive({
      # Validate climate input - default to "NA" if NULL or empty
      clim_val <- input$climateid
      if (is.null(clim_val) || length(clim_val) == 0 || clim_val == "") {
        clim_val <- "NA"
      }
      p1 <- fdefine_problem(targetData(), raw_sf, options, input, clim_input = clim_val)
      return(p1)
    }) %>%
      shiny::bindEvent(input$analyse)


    # Solve the problem -------------------------------------------------------
    # Build custom log with problem summary and solve statistics
    solveLog <- shiny::reactiveVal(character(0))

    solution <- shiny::reactive({
      # Get the problem object
      prob <- p1Data()

      # Use consolidated helper that solves and builds a clean log
      res <- fsolve_with_log(prob, cost_id = input$costid)

      # Update log
      solveLog(res$log)

      # Return solution
      return(res$solution)
    }) %>% shiny::bindEvent(input$analyse)

    # Render the log tab contents
    output$logText <- shiny::renderText({
      log <- solveLog()
      if (is.null(log) || length(log) == 0 || nchar(log) == 0) {
        "No logs yet. Click 'Run Analysis' to generate output."
      } else {
        log
      }
    })

    output$txt_log_hint <- shiny::renderText({
      "This tab displays the problem setup and solve summary for the last analysis run."
    })

    # analysisTime is a reactiveVal so it can be read outside reactive contexts
    # (e.g. inside downloadHandler filename functions).
    analysisTime <- shiny::reactiveVal("")

    shiny::observeEvent(input$analyse, {
      analysisTime(format(Sys.time(), "%Y%m%d%H%M%S"))
    })


    ############## Plot reactives and caches ##################################
    #
    # Design: plots are computed lazily — only when the user visits the
    # relevant tab.  Each plot has:
    #   (a) a reactive() bound to input$analyse (invalidates on new analysis,
    #       but does NOT execute until called)
    #   (b) a reactiveVal(NULL) caching the last evaluated ggplot object
    #   (c) population strategy depends on the tab:
    #       - Tab 1 (Scenario): populated via observeEvent(solution()) because
    #         updateTabsetPanel() redirects to tab 1 *before* solution() has
    #         been evaluated, so an observeEvent(input$tabs == 1) fires too
    #         early and always sees a NULL solution.
    #       - All other tabs: populated via observeEvent(input$tabs) when the
    #         user navigates to that tab (lazy — only if visited).
    #
    # The report handler reads from the caches.  If a cache is NULL (tab never
    # visited), the report evaluates the reactive directly at download time.

    ## --- Solution plot (tab 1) -----------------------------------------------

    plot_data1 <- shiny::reactive({
      if (!inherits(solution(), "sf")) return(NULL)
      fplot_solution_with_constraints(
        soln = solution(), input = input, raw_sf = raw_sf,
        bndry = bndry, overlay = overlay, map_theme = map_theme, num = "",
        Dict = Dict
      )
    }) %>% shiny::bindEvent(input$analyse)

    plot_data1_cache <- shiny::reactiveVal(NULL)

    # Populate cache when solution() resolves, not on tab visit.
    # updateTabsetPanel() redirects to tab 1 before solution() is evaluated,
    # so observeEvent(input$tabs == 1) always fires too early and sees NULL.
    # solution() is bindEvent(input$analyse), so this fires exactly once per
    # analysis run, after the solve completes.
    shiny::observeEvent(solution(), {
      val <- tryCatch(plot_data1(), error = function(e) NULL)
      if (!is.null(val)) plot_data1_cache(val)
    }, ignoreNULL = TRUE)

    output$gg_soln <- shiny::renderPlot({
      req(inherits(solution(), "sf"))
      plot_data1()
    }, bg = "transparent")

    output$hdr_soln <- shiny::renderText({ "Your Scenario" }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_soln <- shiny::renderText({
      if (!inherits(solution(), "sf")) {
        return("No solution could be generated with the current settings. Try lowering targets or adjusting constraints.")
      }
      soln_text <- fSolnText(input, solution(), input$costid)
      if (input$costid != "Cost_None") {
        paste(tx_2solution, soln_text[[1]], soln_text[[2]])
      } else {
        paste(tx_2solution, soln_text[[1]])
      }
    }) %>% shiny::bindEvent(input$analyse)

    output$dlPlot1 <- fDownloadPlotServer(gg_reactive = plot_data1_cache,
                                          gg_prefix = "Solution",
                                          time_date_reactive = analysisTime)

    output$dlSpatial1 <- shiny::downloadHandler(
      filename = function() paste0("Scenario_Spatial_", analysisTime(), ".geojson"),
      content  = function(file) fdownload_solution_geojson(solution(), file)
    )



    ## Target Plot -------------------------------------------------------------

    # Shared feature-representation data — expensive computation, cached by analysis run.
    # Both gg_Target and DataTabler consume this reactive so fget_feature_representation
    # is called at most once per analysis, regardless of how many tabs the user visits.
    targetPlotData <- shiny::reactive({
      fget_feature_representation(
        soln = solution(),
        problem_data = p1Data(),
        targets = targetData(),
        climate_id = input$climateid %||% "NA",
        options = options,
        Dict = Dict
      )
    }) %>%
      shiny::bindCache(input$analyse)

    # Reactive for on-screen display — updates when analyse is clicked or sort changes.
    # Consumes targetPlotData() so the expensive data step is not repeated.
    gg_Target <- shiny::reactive({
      tpd <- targetPlotData()
      if (is.null(tpd)) return(NULL)

      spatialplanr::splnr_plot_featureRep(tpd,
                                          category = fget_category(Dict = Dict),
                                          renameFeatures = TRUE,
                                          namesToReplace = Dict,
                                          nr = 2,
                                          showTarget = TRUE,
                                          sort_by = input$checkSort) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
        )
    }) %>%
      shiny::bindCache(input$analyse, input$checkSort)

    # Cache for report — populated on tab visit using the already-memoised gg_Target().
    # The report uses whatever sort the user last selected (input$checkSort).
    # gg_Target() hits bindCache — no recomputation if the user has already
    # visited this tab with the current sort selection.
    gg_Target_cache <- fmake_tab_cache(gg_Target, tab_id = 2, input = input)

    output$gg_targetPlot <- shiny::renderPlot({
      gg_Target()
    }, bg = "transparent")

    output$hdr_target <- shiny::renderText({
      "Targets"
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_target <- shiny::renderText({
      tx_2targets
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot2 <- fDownloadPlotServer(gg_reactive = gg_Target,
                                          gg_prefix = "Target",
                                          time_date_reactive = analysisTime)





    ## Cost Plot -------------------------------------------------------------

    costPlotData <- shiny::reactive({

      #TODO Need to scale the cost data to look better on the plot.
      spatialplanr::splnr_plot_costOverlay(soln = solution(),
                                           cost = NA,
                                           costName = input$costid,
                                           legendTitle = "Cost",
                                           plotTitle = "Solution overlaid with cost"
      ) +
        spatialplanr::splnr_gg_add(
          Bndry = bndry,
          overlay = overlay,
          cropOverlay = solution(),
          ggtheme = map_theme
        ) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the legend background transparent
        )
    }) %>%
      shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    costPlotData_cache <- fmake_tab_cache(costPlotData, tab_id = 3, input = input)

    output$gg_cost <- shiny::renderPlot({
      costPlotData()
    }, bg = "transparent")

    output$hdr_cost <- shiny::renderText({
      "Cost Layer Overlaid with Selection"
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_cost <- shiny::renderText({
      # Extract cost info from Dictionary for justification
      cost_txt <- Dict %>%
        dplyr::filter(.data$nameVariable == input$costid) %>%
        dplyr::pull("justification")

      paste(tx_2cost, "\n", "\n", cost_txt)
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot3 <- fDownloadPlotServer(gg_reactive = costPlotData,
                                          gg_prefix = "Cost",
                                          time_date_reactive = analysisTime)

    ## Climate Tab -------------------------------------------------

    ggr_clim <- shiny::reactive({

      # Use consolidated helper function for climate plotting
      fplot_climate_density(
        soln_list      = list(solution()),
        climate_ids    = input$climateid,
        solution_names = "solution_1",
        Dict           = Dict
      )
    }) %>%
      shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    ggr_clim_cache <- fmake_tab_cache(ggr_clim, tab_id = 6, input = input)

    output$gg_clim <- shiny::renderPlot({
      clim <- input$climateid %||% "NA"
      if (clim != "NA") {
        ggr_clim()
      }
    }, bg = "transparent")

    output$hdr_clim <- shiny::renderText({
      clim <- input$climateid %||% "NA"
      if (clim != "NA") {
        paste("Climate Resilience")
      }
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_clim <- shiny::renderText({
      clim <- input$climateid %||% "NA"
      if (clim != "NA") {
        paste(tx_2climate)
      } else {
        paste("Climate-smart spatial planning option not selected.")
      }
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot6 <- fDownloadPlotServer(gg_reactive = ggr_clim,
                                          gg_prefix = "Climate",
                                          time_date_reactive = analysisTime)





    # Table of Targets --------------------------------------------------------

    DataTabler <- shiny::reactive({
      # Consume the shared targetPlotData reactive — fget_feature_representation
      # has already been called (and cached) by gg_Target; no duplicate work here.
      fformat_feature_table(targetPlotData(), Dict)
    }) %>%
      shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    DataTabler_cache <- fmake_tab_cache(DataTabler, tab_id = 7, input = input)

    output$DataTable <- shiny::renderTable({
      DataTabler()
    }) %>%
      shiny::bindEvent(input$analyse)

    output$hdr_DetsData <- shiny::renderText(
      "Feature Summary"
    ) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot7 <- fDownloadPlotServer(gg_reactive = DataTabler,
                                          gg_prefix = "DataSummary",
                                          time_date_reactive = analysisTime,
                                          type = "table")


    # Ecosystem Services Tab -------------------------------------------------

    # Header and description text for ESS tab from markdown
    output$txt_ess <- shiny::renderText(
      shiny::markdown(tx_2ess)
    ) %>%
      shiny::bindEvent(input$analyse)

    ess_para <- shiny::reactive({

      if (!inherits(solution(), "sf")) {
        return(NULL)
      }

      ess_layers <- Dict %>%
        dplyr::filter(.data$type == "EcosystemServices") %>%
        dplyr::pull("nameVariable")

      # Return NULL if no ESS layers
      if (length(ess_layers) == 0) {
        return(NULL)
      }

      # Calculate total value per ESS layer across all planning units
      total_values <- raw_sf %>%
        dplyr::select(dplyr::all_of(ess_layers)) %>%
        sf::st_drop_geometry() %>%
        tidyr::pivot_longer(cols = dplyr::everything(), names_to = "nameVariable", values_to = "Value") %>%
        dplyr::summarise(TotalValue = sum(.data$Value, na.rm = TRUE), .by = "nameVariable")

      # Calculate value in selected planning units (solution).
      ess_values <- raw_sf %>%
        dplyr::select(dplyr::all_of(ess_layers)) %>%
        dplyr::mutate(.row_id = dplyr::row_number()) %>%
        dplyr::left_join(
          solution() %>%
            sf::st_drop_geometry() %>%
            dplyr::select("solution_1") %>%
            dplyr::mutate(.row_id = dplyr::row_number()),
          by = ".row_id"
        ) %>%
        dplyr::select(-".row_id") %>%
        dplyr::filter(.data$solution_1 == 1) %>%
        dplyr::select(dplyr::all_of(ess_layers)) %>%
        sf::st_drop_geometry() %>%
        tidyr::pivot_longer(cols = dplyr::everything(), names_to = "nameVariable", values_to = "Value") %>%
        dplyr::summarise(SelectedValue = sum(.data$Value, na.rm = TRUE), .by = "nameVariable") %>%
        dplyr::left_join(total_values, by = "nameVariable") %>%
        dplyr::left_join(Dict %>% dplyr::select("nameVariable", "nameCommon", "justification", "units"),
                         by = "nameVariable") %>%
        dplyr::mutate(
          Name = .data$nameCommon,
          Description = .data$justification,
          Value = paste0(round(.data$SelectedValue, 0), " ", .data$units),
          pct_selected = round((.data$SelectedValue / .data$TotalValue) * 100, 1),
          pct_unselected = 100 - .data$pct_selected
        ) %>%
        dplyr::select("Name", "Description", "Value", "pct_selected", "pct_unselected")

      return(ess_values)

    }) %>%
      shiny::bindEvent(input$analyse)

    output$soln_ess <- reactable::renderReactable({
      ess_data <- ess_para()

      if (is.null(ess_data)) {
        return(NULL)
      }

      reactable::reactable(
        ess_data,
        columns = list(
          Name = reactable::colDef(name = "Name", align = "left", minWidth = 120),
          Description = reactable::colDef(name = "Description", align = "left", minWidth = 250),
          Value = reactable::colDef(name = "Value", align = "right", minWidth = 80),
          pct_selected = reactable::colDef(
            name = "% of Value in Solution",
            align = "center",
            minWidth = 200,
            cell = function(value, index) {
              pct_sel <- ess_data$pct_selected[index]
              pct_unsel <- ess_data$pct_unselected[index]

              # Create progress bar using CSS classes from custom.css
              # Pass --pct variable for consistent gradient scaling across rows
              htmltools::div(
                class = "ess-progress-container",
                htmltools::div(
                  class = "ess-progress-bar",
                  htmltools::div(
                    class = "ess-progress-selected",
                    style = sprintf("width: %.1f%%; --pct: %.1f;", pct_sel, pct_sel),
                    if (pct_sel >= 12) sprintf("%.1f%%", pct_sel) else ""
                  ),
                  htmltools::div(
                    class = "ess-progress-unselected",
                    style = sprintf("width: %.1f%%;", pct_unsel),
                    if (pct_unsel >= 12) sprintf("%.1f%%", pct_unsel) else ""
                  )
                ),
                htmltools::div(
                  class = "ess-progress-legend",
                  htmltools::span(class = "ess-legend-selected"),
                  "In Solution",
                  htmltools::span(class = "ess-legend-unselected"),
                  "Not Selected"
                )
              )
            },
            html = TRUE
          ),
          pct_unselected = reactable::colDef(show = FALSE)
        ),
        defaultColDef = reactable::colDef(
          headerStyle = list(background = "#f7f7f8", fontWeight = "600")
        ),
        bordered = TRUE,
        striped = TRUE,
        highlight = TRUE,
        compact = FALSE,
        fullWidth = TRUE
      )
    }) %>%
      shiny::bindEvent(input$analyse)




    ## Report Generation -------------------------------------------------------
    # Registered once at module init; content function is lazy (only called on download click).
    # Reads from per-tab caches populated when the user visits each tab.
    output$dlReport <- shiny::downloadHandler(
      filename = function() {
        paste0("Scenario_Report_", analysisTime(), ".html")
      },
      content = function(file) {
        ts <- analysisTime()

        # Use tab-visit caches where available; fall back to evaluating the reactive
        frender_report(
          file             = file,
          output           = output,
          template_name    = "report_scenario.qmd",
          notification_id  = "report_progress",
          notification_msg = "Generating report... This may take a moment. Do not click anything or navigate away from this page while you wait.",
          tmp_dir_prefix   = "qrender_",
          plots = list(
            solution = plot_data1_cache()   %||% tryCatch(plot_data1(),    error = function(e) NULL),
            target   = gg_Target_cache()    %||% tryCatch(gg_Target(),     error = function(e) NULL),
            cost     = costPlotData_cache() %||% tryCatch(costPlotData(),  error = function(e) NULL),
            climate  = ggr_clim_cache()     %||% tryCatch(
              if ((input$climateid %||% "NA") != "NA") ggr_clim() else NULL,
              error = function(e) NULL
            )
          ),
          tables = list(
            details = DataTabler_cache() %||% tryCatch(DataTabler(), error = function(e) NULL)
          ),
          params = list(
            solver_log = tryCatch(paste0(solveLog(), collapse = "\n"), error = function(e) ""),
            cost_id    = input$costid,
            climate_id = input$climateid,
            timestamp  = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
          ),
          ts = ts
        )
      }
    )

    ## Interactive Map Tab -----------------------------------------------------

    # Store the current solution sf transformed to WGS84 for Leaflet
    map_solution_sf <- shiny::reactiveVal(NULL)

    # Store the ID of the currently highlighted planning unit
    highlighted_pu <- shiny::reactiveVal(NULL)

    # Store panel content as a reactiveVal to avoid nested renderUI issues
    panel_content <- shiny::reactiveVal(NULL)

    # Flag to track if map has been initialized with solution
    map_initialized <- shiny::reactiveVal(FALSE)

    # Initialize the base leaflet map (runs once) - empty until solution is available
    output$leaflet_map <- leaflet::renderLeaflet({
      leaflet::leaflet() %>%
        leaflet::addProviderTiles(leaflet::providers$CartoDB.Positron)
    })

    # Render feature panel content from reactiveVal
    output$featurePanelContent <- shiny::renderUI({
      content <- panel_content()
      if (is.null(content)) {
        shiny::p("Click a planning unit on the map to see the features it contains.",
                 style = "color: #666; font-style: italic;")
      } else {
        content
      }
    })

    # Header and description text for Map tab
    output$hdr_map <- shiny::renderText({
      "Interactive Solution Map"
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_map <- shiny::renderText({
      "Click on a planning unit to see which features are driving its selection."
    }) %>%
      shiny::bindEvent(input$analyse)

    # Store the last analysis count to detect when new analysis is run
    last_analysis_count <- shiny::reactiveVal(0)

    # Update map when Map tab is selected OR when analysis is run while on Map tab
    # This pattern matches other tabs and ensures leafletProxy works (requires rendered output)
    shiny::observeEvent(
      {
        # Trigger when Map tab (value 4) is selected OR analysis is run
        input$tabs == 4 | input$analyse > 0
      },
      {
        # Only proceed if we have a valid solution
        shiny::req(inherits(solution(), "sf"))

        # Check if we're on the Map tab - proxy only works when output is rendered
        if (input$tabs != 4) {
          return()
        }

        # Transform solution to WGS84 for Leaflet
        soln_wgs84 <- solution() %>%
          dplyr::mutate(pu_id = dplyr::row_number()) %>%
          sf::st_transform("EPSG:4326")

        # Store for click handler
        map_solution_sf(soln_wgs84)

        # Get bounding box for map view
        bbox <- sf::st_bbox(soln_wgs84)

        # Create color palette for solution
        pal <- leaflet::colorFactor(
          palette = c("lightgrey", "#2ca02c"),
          domain = c(0, 1),
          na.color = "transparent"
        )

        # Update map with polygons using leafletProxy
        leaflet::leafletProxy("leaflet_map", session = session) %>%
          leaflet::clearShapes() %>%
          leaflet::clearControls() %>%
          leaflet::clearGroup("highlight") %>%
          leaflet::fitBounds(
            lng1 = as.numeric(bbox["xmin"]),
            lat1 = as.numeric(bbox["ymin"]),
            lng2 = as.numeric(bbox["xmax"]),
            lat2 = as.numeric(bbox["ymax"])
          ) %>%
          leaflet::addPolygons(
            data = soln_wgs84,
            layerId = ~pu_id,
            fillColor = ~pal(solution_1),
            fillOpacity = 0.7,
            color = "#444444",
            weight = 0.5,
            highlightOptions = leaflet::highlightOptions(
              weight = 3,
              color = "#666666",
              fillOpacity = 0.9,
              bringToFront = TRUE
            ),
            group = "solution_polygons"
          ) %>%
          leaflet::addLegend(
            position = "bottomleft",
            colors = c("#2ca02c", "lightgrey"),
            labels = c("Selected", "Not Selected"),
            title = "Solution",
            opacity = 0.7
          )

        # Reset highlighted PU and panel content when new solution is loaded
        highlighted_pu(NULL)
        panel_content(NULL)
        map_initialized(TRUE)
      }
    )

    # Handle polygon click events
    shiny::observeEvent(input$leaflet_map_shape_click, {
      tryCatch({
        click <- input$leaflet_map_shape_click

        # Guard against NULL clicks or clicks on highlight layer
        if (is.null(click) || is.null(click$id)) {
          return()
        }

        # Skip if clicking on highlight polygon (layerId starts with "highlight_")
        if (is.character(click$id) && grepl("^highlight_", click$id)) {
          return()
        }

        pu_id <- click$id

        # Use isolate to prevent reactive dependency on map_solution_sf
        soln_sf <- shiny::isolate(map_solution_sf())

        # Guard against missing solution data
        if (is.null(soln_sf)) {
          return()
        }

        # Get the clicked planning unit row using base R for better performance
        pu_idx <- which(soln_sf$pu_id == pu_id)
        if (length(pu_idx) == 0) {
          return()
        }

        pu_row <- sf::st_drop_geometry(soln_sf[pu_idx[1], , drop = FALSE])

        # Get feature names from targetData (only features with target > 0)
        # Use isolate to prevent reactive loop
        target_features <- shiny::isolate(targetData()$feature)

        # Find features present in this planning unit (value == 1)
        # Pre-filter to only columns that exist in pu_row for efficiency
        available_features <- intersect(target_features, names(pu_row))
        features_present <- available_features[
          vapply(available_features, function(feat) {
            val <- pu_row[[feat]]
            !is.na(val) && as.numeric(val) == 1
          }, logical(1))
        ]

        # Create lookup for common names and categories from Dict
        feature_info <- Dict[Dict$nameVariable %in% features_present,
                             c("nameVariable", "nameCommon", "category"),
                             drop = FALSE]

        # Update highlight using clearGroup for reliable removal
        # This clears ALL polygons in the "highlight" group, avoiding accumulation
        proxy <- leaflet::leafletProxy("leaflet_map", session = session) %>%
          leaflet::clearGroup("highlight")

        # Add new highlight polygon
        highlight_data <- soln_sf[pu_idx[1], , drop = FALSE]
        proxy %>%
          leaflet::addPolygons(
            data = highlight_data,
            layerId = paste0("highlight_", pu_id),
            fillColor = "yellow",
            fillOpacity = 0.5,
            color = "#FF6600",
            weight = 3,
            group = "highlight"
          )

        # Update tracked highlighted PU (use isolate to avoid triggering reactivity)
        shiny::isolate(highlighted_pu(pu_id))

        # Extract selection status and cost value
        is_selected <- if ("solution_1" %in% names(pu_row)) {
          as.logical(pu_row[["solution_1"]])
        } else {
          NA
        }

        # Get cost column name from input and extract value
        cost_col <- shiny::isolate(input$costid)
        cost_value <- if (!is.null(cost_col) && cost_col %in% names(pu_row)) {
          round(as.numeric(pu_row[[cost_col]]), 2)
        } else {
          NA
        }

        # Get cost display name from Dict
        cost_name <- if (!is.null(cost_col) && cost_col != "Cost_None") {
          cost_info <- Dict[Dict$nameVariable == cost_col, "nameCommon", drop = TRUE]
          if (length(cost_info) > 0) cost_info[1] else cost_col
        } else {
          "Cost"
        }

        # Generate panel content grouped by category
        new_content <- if (nrow(feature_info) == 0) {
          shiny::tagList(
            shiny::h4(shiny::strong(paste0("Planning Unit #", pu_id))),
            shiny::hr(style = "margin: 5px 0;"),
            shiny::p("No features with targets found in this planning unit.",
                     style = "color: #666; font-style: italic;")
          )
        } else {
          # Group features by category using base R for performance
          categories <- unique(feature_info$category)
          category_list <- lapply(categories, function(cat) {
            feats <- feature_info$nameCommon[feature_info$category == cat]
            shiny::tagList(
              shiny::p(shiny::strong(cat), style = "margin-bottom: 2px;"),
              shiny::p(paste(feats, collapse = ", "),
                       style = "margin-left: 10px; margin-top: 0; margin-bottom: 8px;")
            )
          })

          shiny::tagList(
            shiny::h4(paste0("Planning Unit")),
            shiny::p(shiny::strong(paste0("Number: ", pu_id))),
            shiny::p(
              shiny::strong("Selected: "),
              if (is.na(is_selected)) "N/A" else if (is_selected) "TRUE" else "FALSE",
              style = "margin-bottom: 2px;"
            ),
            shiny::hr(style = "margin: 5px 0;"),
            shiny::h5("Cost Value"),
            shiny::p(
              shiny::strong(paste0(cost_name, ": ")),
              if (is.na(cost_value)) "N/A" else format(cost_value, big.mark = ","),
              style = "margin-bottom: 2px;"
            ),
            shiny::hr(style = "margin: 5px 0;"),
            shiny::h5("Feature List"),
            category_list
          )
        }

        # Update panel content
        panel_content(new_content)

      }, error = function(e) {
        # Log error but don't crash the observer
        message("Map click handler error: ", e$message)
      })
    }, ignoreInit = TRUE, ignoreNULL = TRUE)

  }) # end moduleServer
} # end mod_2scenario_server

## To be copied in the UI
# mod_2scenario_ui("2scenario_1")

## To be copied in the server
# mod_2scenario_server("2scenario_1")
