#' 3compare UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @import shiny
mod_3compare_ui <- function(id, cfg) {
  # Extract config locals
  Dict    <- cfg$Dict
  options <- cfg$options
  sidebar <- cfg$sidebar$compare

  ns <- NS(id)

  # Decide numbering for optional sections
  if (isTRUE(options$include_climateChange)){
    LI_num <- "4"
  } else {
    LI_num <- "3"
  }

  # Unpack all pre-computed sidebar vars from config into the local environment.
  # rlang::env_bind() splices the named list so each key becomes a local variable
  # (e.g. sidebar$Vars1 -> Vars1).
  Vars1 <- Vars2 <- slider_varsBioR1 <- slider_varsBioR2 <- check_lockIn1 <- check_lockIn2 <- check_lockOut1 <- check_lockOut2 <- NULL

  rlang::env_bind(environment(), !!!sidebar)



  # tagList(
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      width = 4,
      shiny::p(shiny::HTML("<strong>To Run Comparison:</strong> Select the features you want to compare
                                                and click 'Run Analysis'. For a detailed display of the spatial plans,
                                                targets and costs of the two analyses, navigate through the additional tabs.")),
      shiny::hr(style = "border-top: 1px solid #000000;"),
      shiny::splitLayout(
        shiny::h2("Scenario 1", style = "width: 100%; text-align:center; display: block"),
        shiny::h2("Scenario 2", style = "width: 100%; text-align:center; display: block"),
      ),
      shiny::h2("1. Select Feature Targets"),
      shiny::actionButton(ns("resetSlider"), "Reset All Features",
                          width = "100%", class = "btn btn-outline-primary",
                          style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
      ),
      shiny::splitLayout(
        fcustom_sliderCategory(Vars1, labelNum = 1),
        fcustom_sliderCategory(Vars2, labelNum = 1, labelCategory = FALSE)
      ),

      shinyjs::hidden(div(
        id = ns("switchBioregions"),
        # Hidden by default; shown by the server only when options$include_bioregion
        # is TRUE (see utils_server.R fapply_ui_switches()). No UI-level conditional
        # is needed because shinyjs::hidden() already prevents rendering until shown.
        shiny::h3(paste0("1.", length(unique(Vars1$category)) + 1, " Bioregions")),
        shiny::splitLayout(
          fcustom_sliderCategory(slider_varsBioR1, labelNum = 1, byCategory = TRUE),
          fcustom_sliderCategory(slider_varsBioR2, labelNum = 1, byCategory = TRUE,
                                 labelCategory = FALSE)
        ),
      )),

      shiny::h2("2. Select Cost Layer"),
      shiny::splitLayout(
        # This was needed to account for cost not expanding inside splitlayout
        # Thanks to https://stackoverflow.com/questions/40077388/shiny-splitlayout-and-selectinput-issue
        tags$head(tags$style(HTML(".shiny-split-layout > div {overflow: visible;}"))),
        cellWidths = c("0%", "50%", "50%"), # note the 0% here at position zero...
        create_fancy_dropdown(id, "costid1", Dict %>%
                                dplyr::filter(.data$type == "Cost")),
        create_fancy_dropdown(id, "costid2", Dict %>%
                                dplyr::filter(.data$type == "Cost")),
      ),

      shinyjs::hidden(div(
        id = ns("switchMinSet"),
        shiny::h3("Minimum Set"),
        shiny::p("This analysis will use the minimum set objective which aims to find the set of
                 planning units that meets all targets for the smallest possible cost.")
      )),

      shinyjs::hidden(div(
        id = ns("switchMinShortfall"),
        shiny::h3("Choose a Budget"),
        shiny::p("This analysis will use the minimum shortfall objective which aims to find the set of
                 planning units that minimize the overall shortfall for the targets for as many features
                 as possible while staying within a fixed budget."),
        shiny::br(),
        shiny::p("Choose the total budget (% of cost layer) for your analysis."),
        shiny::splitLayout(
          shiny::numericInput(
            inputId = ns("budget1"),
            label = "Budget 1 (%)",
            value = 30,
            min = 0,
            max = 100
          ),
          shiny::numericInput(
            inputId = ns("budget2"),
            label = "Budget 2 (%)",
            value = 30,
            min = 0,
            max = 100
          ),
        ),
      )),



      if (isTRUE(options$include_climateChange)) {
        div(
          shiny::h2("3. Climate-smart"),
          shiny::p("Should the spatial plan be made climate-resilient?"),
          shiny::p("NOTE: This will slow down the analysis significantly. Be patient."),
          shiny::fluidRow(
            shiny::column(6,
              create_fancy_dropdown(id = id,  id_in = "climateid1", Dict = Dict %>%
                                      dplyr::filter(.data$type == "Climate") %>%
                                      dplyr::add_row(nameCommon = "Don't consider",
                                                     nameVariable = "NA",
                                                     category = "Climate", .before = 1))
            ),
            shiny::column(6,
              create_fancy_dropdown(id = id,  id_in = "climateid2", Dict = Dict %>%
                                      dplyr::filter(.data$type == "Climate") %>%
                                      dplyr::add_row(nameCommon = "Don't consider",
                                                     nameVariable = "NA",
                                                     category = "Climate", .before = 1))
            )
          )
        )
      },

      shinyjs::hidden(div(
        id = ns("switchConstraints"),
        shiny::h2(paste0(LI_num,". Constraints")),
        shiny::p("You can also lock-in or lock-out some pre-defined areas to ensure they are either specifically included (lock-in) or excluded (lock-out) from the protected area. Planning Units outside these areas will be selected if needed to meet the targets."),
        if (nrow(check_lockIn1) > 0 || nrow(check_lockIn2) > 0) shiny::h3(paste0(LI_num, ".1 Locked-In Areas")),
        if (nrow(check_lockIn1) > 0 || nrow(check_lockIn2) > 0) shiny::splitLayout(
          fcustom_checkCategory(check_lockIn1),
          fcustom_checkCategory(check_lockIn2)
        ),
        if (nrow(check_lockOut1) > 0 || nrow(check_lockOut2) > 0) shiny::h3(paste0(LI_num, ".2 Locked-Out Areas")),
        if (nrow(check_lockOut1) > 0 || nrow(check_lockOut2) > 0) shiny::splitLayout(
          fcustom_checkCategory(check_lockOut1),
          fcustom_checkCategory(check_lockOut2)
        )
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
      ),
    ),

    shiny::mainPanel(

      tabsetPanel(
        id = ns("tabs"),
        type = "pills",
        tabPanel("Comparison",
                 value = 1,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the buttons above all plots.
                   shiny::div(
                     style = "display:flex; gap:10px; justify-content:flex-end; align-items:center;",
                     shiny::downloadButton(ns("dlSpatialComp"), "Download Spatial File",
                                           style = "padding:4px; font-size:120%"),
                     shiny::downloadButton(ns("dlPlot1"), "Download Plot",
                                           style = "padding:4px; font-size:120%")
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_comp")))),
                 shiny::textOutput(ns("txt_comp")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_comp"), height = "600px"))
        ),
        tabPanel("Scenario",
                 value = 2,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the buttons above all plots.
                   shiny::div(
                     style = "display:flex; gap:10px; justify-content:flex-end; align-items:center;",
                     shiny::downloadButton(ns("dlSpatial1"), "Download Scenario 1 Spatial",
                                           style = "padding:4px; font-size:110%"),
                     shiny::downloadButton(ns("dlSpatial2"), "Download Scenario 2 Spatial",
                                           style = "padding:4px; font-size:110%"),
                     shiny::downloadButton(ns("dlPlot2"), "Download Plot",
                                           style = "padding:4px; font-size:120%")
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::fluidRow(
                   shiny::span(shiny::p(shiny::textOutput(ns("txt_soln")))),
                   shiny::column(width = 1),
                   shiny::column(width = 4,
                                 shiny::h2(shiny::textOutput(ns("hdr_soln1"))),
                                 shiny::p(shiny::textOutput(ns("txt_soln1")))),
                   shiny::column(width = 2),
                   shiny::column(width = 4,
                                 shiny::h2(shiny::textOutput(ns("hdr_soln2"))),
                                 shiny::p(shiny::textOutput(ns("txt_soln2")))),
                   shiny::column(width = 1),
                   shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_soln"), height = "700px"))
                 ),
        ),
        tabPanel("Targets",
                 value = 3,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot3"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_target")))),
                 shiny::br(),
                 shiny::selectInput(inputId = ns("checkSort"),
                                    label = "Sort plot by:",
                                    choices = c("Category" = "category",
                                                # "Feature" = "feature",
                                                "Target" = "target",
                                                "Representation" = "representation",
                                                "Difference from Target" = "difference"),
                                    selected = "category",  multiple = FALSE),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_target"), height = "700px"))
        ),
        tabPanel("Cost",
                 value = 4,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot4"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_cost")))),
                 shiny::span(shiny::p(shiny::textOutput(ns("txt_cost")))),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_cost"), height = "700px")),
        ),
        tabPanel("Climate",
                 value = 7,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot7"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_clim")))),
                 shiny::textOutput(ns("txt_clim")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_clim"), height = "600px"))
        ),
        tabPanel("Details",
                 value = 8,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot8"), "Download Table",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_DetsSummary")))),
                 shiny::br(),
                 shiny::tableOutput(ns("SummaryTable")),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_DetsData")))),
                 shiny::tableOutput(ns("DataTable")),
        ),
        tabPanel("Report",
                 value = 10,
                 shiny::span(shiny::h2("Generate Analysis Report")),
                 shiny::p("Download a comprehensive HTML report containing all analysis results from this scenario."),
                 shiny::p("The report includes:"),
                 shiny::tags$ul(
                   shiny::tags$li("Comparison map"),
                   shiny::tags$li("Solution map with constraints"),
                   shiny::tags$li("Target achievement chart"),
                   shiny::tags$li("Cost analysis visualization"),
                   shiny::tags$li("Climate resilience analysis (if enabled)"),
                   shiny::tags$li(shiny::tagList(shiny::em("prioritizr"), " log")),
                 ),
                 shiny::br(),
                 shiny::downloadButton(ns("downloadReportCompare"), "Download Report",
                                       style = "padding:10px 20px; font-size:120%"),
                 shiny::uiOutput(ns("reportStatus")),
                 shiny::br(),
                 shiny::br(),
                 shiny::p(shiny::em("Note: Report generation may take a few moments. The file will download automatically when ready."),
                          style = "color: #666;")
        ),
        tabPanel("Log",
                 value = 9,
                 shiny::span(shiny::h2("Solver Logs")),
                 shiny::textOutput(ns("txt_log_hint")),
                 shiny::tabsetPanel(
                   id = ns("logTabs"),
                   type = "tabs",
                   shiny::tabPanel("Scenario 1",
                                   shinycssloaders::withSpinner(
                                     shiny::verbatimTextOutput(ns("logText1"), placeholder = TRUE)
                                   )
                   ),
                   shiny::tabPanel("Scenario 2",
                                   shinycssloaders::withSpinner(
                                     shiny::verbatimTextOutput(ns("logText2"), placeholder = TRUE)
                                   )
                   )
                 )
        ),
      )
    )
  )}


#' 3compare Server Functions
#'
#' @noRd
mod_3compare_server <- function(id, cfg) {
  # Extract config locals
  Dict      <- cfg$Dict
  options   <- cfg$options
  raw_sf    <- cfg$raw_sf
  bndry     <- cfg$bndry
  overlay   <- cfg$overlay
  map_theme <- cfg$map_theme
  sidebar   <- cfg$sidebar$compare

  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
    . <- NULL

    # Unpack all pre-computed sidebar vars from config into the local environment.
    # rlang::env_bind() splices the named list so each key becomes a local variable
    # (e.g. sidebar$Vars1 -> Vars1, sidebar$check_lockIn1 -> check_lockIn1, etc.).
    Vars1 <- Vars2 <- slider_varsBioR1 <- slider_varsBioR2 <- check_lockIn1 <- check_lockIn2 <- check_lockOut1 <- check_lockOut2 <- NULL

    rlang::env_bind(environment(), !!!sidebar)

    # Declare all reactiveVals at the top so they are available to all observers
    # and handlers below, regardless of evaluation order.
    analysisTime <- shiny::reactiveVal("")
    solveLog1    <- shiny::reactiveVal(character(0))
    solveLog2    <- shiny::reactiveVal(character(0))

    # Apply all UI show/hide switches driven by options ----
    # Note: switches for elements not yet in the compare UI (switchBoundaryPenalty,
    # switchMasterTargets, etc.) are silently ignored by shinyjs
    # until those features are added to this module.
    fapply_ui_switches(options, session,
                       tab_climate = "7",
                       tab_report  = "10",
                       tab_log     = "9")

    shiny::observeEvent(input$disconnect, {
      session$close()
    })

    shiny::observeEvent(input$resetSlider, {
      fresetSlider(session, Vars1)
      fresetSlider(session, Vars2)
    }, ignoreInit = TRUE)

    # On analyse: capture timestamp, reset to first tab, scroll to top.
    shiny::observeEvent(input$analyse, {
      analysisTime(format(Sys.time(), "%Y%m%d%H%M%S"))
      shiny::updateTabsetPanel(session, "tabs", selected = 1)
      shinyjs::runjs("window.scrollTo(0, 0)")
    })


    # Set up paired lock-in/lock-out mutual exclusion observers for each scenario
    fsetup_lock_observers(input, check_lockIn1, check_lockOut1,
                          li_prefix = "check1LI_", lo_prefix = "check1LO_")
    fsetup_lock_observers(input, check_lockIn2, check_lockOut2,
                          li_prefix = "check2LI_", lo_prefix = "check2LO_")





    # Get Target Data
    targetData1 <- shiny::reactive({

      targets <- fget_targets_with_bioregions(input, name_check = "sli1_", Dict = Dict)
      return(targets)
    })

    targetData2 <- shiny::reactive({
      targets <- fget_targets_with_bioregions(input, name_check = "sli2_", Dict = Dict)
      return(targets)
    })

    # Normalise climate inputs: NULL (when dropdown not rendered) or "" -> "NA"
    climVal1 <- shiny::reactive({
      clim <- input$climateid1 %||% "NA"
      if (clim == "") "NA" else clim
    })

    climVal2 <- shiny::reactive({
      clim <- input$climateid2 %||% "NA"
      if (clim == "") "NA" else clim
    })

    # Define Problems
    # bindEvent(input$analyse) freezes p1Data/p2Data to the inputs at click time,
    # matching solution1()/solution2() which are also bound to input$analyse.
    # Without this, a cost/climate change after clicking Analyse but before visiting
    # the Targets tab would cause targetPlotData to be computed with different inputs
    # than the solution was solved with.
    p1Data <- shiny::reactive({
      p1 <- fdefine_problem(targetData1(), raw_sf, options, input, clim_input = climVal1(), compare_id = "1")
      return(p1)
    }) %>%
      shiny::bindEvent(input$analyse)

    p2Data <- shiny::reactive({
      p2 <- fdefine_problem(targetData2(), raw_sf, options, input, clim_input = climVal2(), compare_id = "2")
      return(p2)
    }) %>%
      shiny::bindEvent(input$analyse)


    # Solve the problems and capture logs -------------------------------------------------------

    solution1 <- shiny::reactive({
      res <- fsolve_with_log(p1Data(), cost_id = input$costid1)
      solveLog1(res$log)
      return(res$solution)
    }) %>% shiny::bindEvent(input$analyse)

    solution2 <- shiny::reactive({
      res <- fsolve_with_log(p2Data(), cost_id = input$costid2)
      solveLog2(res$log)
      return(res$solution)
    }) %>% shiny::bindEvent(input$analyse)


    #### Comparison Plot ####

    ggr_comp <- shiny::reactive({

      area1 <- solution1() %>%
        dplyr::filter(.data$solution_1 == 1) %>%
        nrow()
      area2 <- solution2() %>%
        dplyr::filter(.data$solution_1 == 1) %>%
        nrow()

      area_change1 <- round(((area2 - area1) / nrow(solution1())) * 100)
      area_change2 <- round(((area2 - area1) / area1) * 100)

      if (area_change1 > 0) {
        txt_comb <- paste0("Area 2 is ", area_change2, "% larger than Area 1\nand contains ", area_change1, "% more of the\nplanning region")
      } else if (area_change1 < 0) {
        txt_comb <- paste0("Area 2 is ", abs(area_change2), "% smaller than Area 1\nand contains ", abs(area_change1), "% less of the\nplanning region")
      } else if (area_change1 == 0) {
        txt_comb <- paste0("Area 1 and Area 2 are the same size.")
      }

      spatialplanr::splnr_plot_comparison(solution1(), solution2()) +
        ggplot2::annotate(
          geom = "label", label = txt_comb, x = Inf, y = Inf, fill = "NA",
          hjust = 1.0, vjust = 1,
          size = 6, linewidth = 0,
          label.padding = ggplot2::unit(0.2, "lines")
        ) +
        spatialplanr::splnr_gg_add(
          Bndry = bndry,
          overlay = overlay,
          cropOverlay = solution1(),
          ggtheme = map_theme
        ) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
        )
    }) %>% shiny::bindEvent(input$analyse)

    # Cache populated when both solutions resolve, not on tab visit.
    # updateTabsetPanel() redirects to tab 1 before solution1()/solution2()
    # are evaluated, so observeEvent(input$tabs == 1) always fires too early.
    # Both solutions are bindEvent(input$analyse), so observing solution2()
    # (evaluated after solution1()) fires exactly once per analysis run.
    ggr_comp_cache <- shiny::reactiveVal(NULL)

    shiny::observeEvent(solution2(), {
      val <- tryCatch(ggr_comp(), error = function(e) NULL)
      if (!is.null(val)) ggr_comp_cache(val)
    }, ignoreNULL = TRUE)

    output$gg_comp <- shiny::renderPlot({
      ggr_comp()
    }, bg = "transparent")

    output$dlPlot1 <- fDownloadPlotServer(gg_reactive = ggr_comp, gg_prefix = "Compare", time_date_reactive = analysisTime)

    # Download comparison spatial data (GeoJSON) showing which areas are in which scenario
    output$dlSpatialComp <- shiny::downloadHandler(
      filename = function() {
        paste0("Comparison_Spatial_", analysisTime(), ".geojson")
      },
      content = function(file) {
        sol1 <- solution1()
        sol2 <- solution2()
        if (!inherits(sol1, "sf") || !inherits(sol2, "sf")) {
          shiny::showNotification(
            "Please run an analysis before downloading the spatial file.",
            type = "error", duration = 5
          )
          stop("No solutions available.")
        }

        sol1_selected <- sol1$solution_1 == 1
        sol2_selected <- sol2$solution_1 == 1

        comp_sf <- sol1
        comp_sf$comparison <- dplyr::case_when(
          sol1_selected & sol2_selected ~ "Both scenarios",
          sol1_selected & !sol2_selected ~ "Scenario 1 only",
          !sol1_selected & sol2_selected ~ "Scenario 2 only",
          TRUE ~ "Neither scenario"
        )

        comp_out <- comp_sf %>%
          dplyr::filter(.data$comparison != "Neither scenario") %>%
          dplyr::select("comparison") %>%
          sf::st_transform("EPSG:4326")

        sf::st_write(comp_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
      }
    )

    #### Binary Solution Plot ####

    ggr_soln <- shiny::reactive({

      plot_soln1 <- fplot_solution_with_constraints(
        soln = solution1(), input = input, raw_sf = raw_sf,
        bndry = bndry, overlay = overlay, map_theme = map_theme, num = "1",
        Dict = Dict
      )

      plot_soln2 <- fplot_solution_with_constraints(
        soln = solution2(), input = input, raw_sf = raw_sf,
        bndry = bndry, overlay = overlay, map_theme = map_theme, num = "2",
        Dict = Dict
      )

      patchwork::wrap_plots(plot_soln1, plot_soln2, nrow = 1, guides = "collect") &
        ggplot2::theme(
          legend.position = "bottom",
          legend.direction = "horizontal",
          plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          legend.background = ggplot2::element_rect(fill = "transparent", colour = NA),
          legend.box = "horizontal"
        ) &
        ggplot2::guides(
          fill = ggplot2::guide_legend(nrow = 2, byrow = TRUE, title.position = "top", title.hjust = 0.5),
          colour = ggplot2::guide_legend(nrow = 2, byrow = TRUE, title.position = "top", title.hjust = 0.5),
          linetype = ggplot2::guide_legend(nrow = 2, byrow = TRUE, title.position = "top", title.hjust = 0.5)
        )
    }) %>% shiny::bindEvent(input$analyse)

    # Cache populated when both solutions resolve (same rationale as ggr_comp_cache).
    # Tab 2 is always shown after analysis, so the tab observer fires too early.
    ggr_soln_cache <- shiny::reactiveVal(NULL)

    shiny::observeEvent(solution2(), {
      val <- tryCatch(ggr_soln(), error = function(e) NULL)
      if (!is.null(val)) ggr_soln_cache(val)
    }, ignoreNULL = TRUE)

    output$gg_soln <- shiny::renderPlot({
      ggr_soln()
    }, bg = "transparent")

    output$hdr_soln1 <- shiny::renderText("Scenario 1") %>%
      shiny::bindEvent(input$analyse)

    output$hdr_soln2 <- shiny::renderText("Scenario 2") %>%
      shiny::bindEvent(input$analyse)

    output$txt_soln <- shiny::renderText({
      paste(
        "These plots shows the optimal planning scenario for the study area
          that meet the selected targets for the chosen features whilst
          minimising the cost. The categorical map displays, which of
          the planning units were selected as important for meeting
          the conservation targets (dark blue) and which were not selected (light blue)
          either due to not being in an area prioritized for the selected features or
          because they are within areas valuable and accessible for other uses."
      )
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_soln1 <- shiny::renderText({
      soln_text1 <- fSolnText(input, solution1(), input$costid1)
      paste(c(soln_text1[[1]], soln_text1[[2]]), collapse = " ")
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_soln2 <- shiny::renderText({
      soln_text2 <- fSolnText(input, solution2(), input$costid2)
      paste(c(soln_text2[[1]], soln_text2[[2]]), collapse = " ")
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot2 <- fDownloadPlotServer(gg_reactive = ggr_soln, gg_prefix = "Solution", time_date_reactive = analysisTime)

    # Download spatial data for Scenario 1
    output$dlSpatial1 <- shiny::downloadHandler(
      filename = function() paste0("Scenario1_Spatial_", analysisTime(), ".geojson"),
      content = function(file) fdownload_solution_geojson(solution1(), file)
    )

    # Download spatial data for Scenario 2
    output$dlSpatial2 <- shiny::downloadHandler(
      filename = function() paste0("Scenario2_Spatial_", analysisTime(), ".geojson"),
      content = function(file) fdownload_solution_geojson(solution2(), file)
    )

    ## Target Plot -------------------------------------------------------------

    # Shared feature-representation data — expensive computation, cached by analysis run.
    # Both ggr_target and DataTabler consume these reactives so fget_feature_representation
    # is called at most once per scenario per analysis, regardless of tabs visited.
    targetPlotData1 <- shiny::reactive({
      fget_feature_representation(
        soln = solution1(), problem_data = p1Data(), targets = targetData1(),
        climate_id = climVal1(), options = options, Dict = Dict
      )
    }) %>%
      shiny::bindCache(input$analyse)

    targetPlotData2 <- shiny::reactive({
      fget_feature_representation(
        soln = solution2(), problem_data = p2Data(), targets = targetData2(),
        climate_id = climVal2(), options = options, Dict = Dict
      )
    }) %>%
      shiny::bindCache(input$analyse)

    # On-screen reactive — updates when analyse is clicked or sort changes.
    # Consumes targetPlotData1/2() so the expensive data step is not repeated.
    ggr_target <- shiny::reactive({
      tpd1 <- targetPlotData1()
      tpd2 <- targetPlotData2()

      if (is.null(tpd1) || is.null(tpd2)) return(NULL)

      patchwork::wrap_plots(
        spatialplanr::splnr_plot_featureRep(tpd1,
                                            nr = 2, showTarget = TRUE,
                                            category = fget_category(Dict = Dict),
                                            renameFeatures = TRUE, namesToReplace = Dict,
                                            sort_by = input$checkSort) +
          ggplot2::ggtitle("Scenario 1") +
          ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                         legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)),
        spatialplanr::splnr_plot_featureRep(tpd2,
                                            nr = 2, showTarget = TRUE,
                                            category = fget_category(Dict = Dict),
                                            renameFeatures = TRUE, namesToReplace = Dict,
                                            sort_by = input$checkSort) +
          ggplot2::ggtitle("Scenario 2") +
          ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                         legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)),
        nrow = 1, guides = "collect"
      ) &
        ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal",
                       plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA))
    }) %>%
      shiny::bindCache(input$analyse, input$checkSort)

    # Cache for report — populated on tab visit using the already-memoised ggr_target().
    # The report uses whatever sort the user last selected (input$checkSort).
    # ggr_target() hits bindCache — no recomputation if already visited with
    # the current sort selection.
    ggr_target_cache <- fmake_tab_cache(ggr_target, tab_id = 3, input = input)

    output$gg_target <- shiny::renderPlot({
      ggr_target()
    }, bg = "transparent")

    output$hdr_target <- shiny::renderText("Targets") %>%
      shiny::bindEvent(input$analyse)

    output$txt_target <- shiny::renderText({
      "Given the scenario for the spatial planning problem formulated with
      the chosen inputs, these plots show the proportion of
      suitable habitat/area of each of the important and representative
      conservation features that are included. The dashed line represents
      the set target for the features. Hollow bars with a black border indicate incidental
      protection of features which were not chosen in this analysis but have areal overlap with selected planning units."
    })

    output$dlPlot3 <- fDownloadPlotServer(gg_reactive = ggr_target, gg_prefix = "Target", time_date_reactive = analysisTime)
    ## Cost Plot -------------------------------------------------------------

    ggr_cost <- shiny::reactive({

      gg_cost1 <- spatialplanr::splnr_plot_costOverlay(soln = solution1(),
                                                       cost = NA, costName = input$costid1,
                                                       legendTitle = "Cost",
                                                       plotTitle = "Solution overlaid with cost"
      ) +
        spatialplanr::splnr_gg_add(Bndry = bndry, overlay = overlay,
                                   cropOverlay = solution1(), ggtheme = map_theme) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA))

      gg_cost2 <- spatialplanr::splnr_plot_costOverlay(soln = solution2(),
                                                       cost = NA, costName = input$costid2,
                                                       legendTitle = "Cost",
                                                       plotTitle = "Solution overlaid with cost"
      ) +
        spatialplanr::splnr_gg_add(Bndry = bndry, overlay = overlay,
                                   cropOverlay = solution2(), ggtheme = map_theme) +
        ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA))

      patchwork::wrap_plots(gg_cost1 + ggplot2::ggtitle("Scenario 1"),
                            gg_cost2 + ggplot2::ggtitle("Scenario 2"),
                            nrow = 1, guides = "collect") &
        ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal",
                       plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                       legend.background = ggplot2::element_rect(fill = "transparent", colour = NA))
    }) %>% shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    ggr_cost_cache <- fmake_tab_cache(ggr_cost, tab_id = 4, input = input)

    output$gg_cost <- shiny::renderPlot({
      ggr_cost()
    }, bg = "transparent")

    output$hdr_cost <- shiny::renderText("The Cost Layer Overlaid with Selection") %>%
      shiny::bindEvent(input$analyse)

    output$txt_cost <- shiny::renderText({
      cost_txt1 <- Dict %>% dplyr::filter(.data$nameVariable == input$costid1)
      cost_txt2 <- Dict %>% dplyr::filter(.data$nameVariable == input$costid2)
      # Strip a leading "This cost" sentence if present, otherwise use justification as-is
      strip_cost_prefix <- function(just) {
        stripped <- stringr::str_remove(just, "^This cost[^.]*\\.\\s*")
        if (nchar(stripped) == 0) just else stripped
      }
      paste0(
        "To illustrate how the chosen cost influences the spatial plan, this plot shows the",
        " spatial plan (= scenario) overlaid with the cost of including a planning unit in a",
        " reserve. The cost used on the left is ", cost_txt1$nameCommon, " and ",
        strip_cost_prefix(cost_txt1$justification),
        " The cost on the right is ",
        cost_txt2$nameCommon, " and ", strip_cost_prefix(cost_txt2$justification)
      )
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot4 <- fDownloadPlotServer(gg_reactive = ggr_cost, gg_prefix = "Cost", time_date_reactive = analysisTime)

    ## Climate Resilience Plot -------------------------------------------------

    ggr_clim <- shiny::reactive({
      fplot_climate_density(
        soln_list = list(solution1(), solution2()),
        climate_ids = c(input$climateid1, input$climateid2),
        solution_names = c("solution_1", "solution_2")
      )
    }) %>%
      shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    ggr_clim_cache <- fmake_tab_cache(ggr_clim, tab_id = 7, input = input)

    output$gg_clim <- shiny::renderPlot({
      clim1 <- input$climateid1 %||% "NA"
      clim2 <- input$climateid2 %||% "NA"
      if (clim1 != "NA" || clim2 != "NA") ggr_clim()
    }, bg = "transparent")

    output$hdr_clim <- shiny::renderText({
      clim1 <- input$climateid1 %||% "NA"
      clim2 <- input$climateid2 %||% "NA"
      if (clim1 != "NA" || clim2 != "NA") paste("Climate Resilience")
    }) %>%
      shiny::bindEvent(input$analyse)

    output$txt_clim <- shiny::renderText({
      clim1 <- input$climateid1 %||% "NA"
      clim2 <- input$climateid2 %||% "NA"
      if (clim1 != "NA" || clim2 != "NA") {
        paste("Kernel density estimates for the climate-resilience metric. The metric comprises two components,
          both based on projected temperature in 2100 from a suite of Earth System Models under a high emission scenario:
          1. Exposure to climate change (amount of warming); 2. Climate velocity (the pace of isotherm movement).
          These two components are combined into a single climate-resilience metric so that higher values represent areas
          likely to warm less and where biodiversity is more likely to be retained. The prioritization preferentially places protected areas
          where there are higher values of the climate-resilience metric, whilst still meeting the biodiversity targets and
          minimising overlap with costly areas. The dark blue polygon represents the climate-resilience metric in planning units
          selected for protection. The light blue polygon represents the climate-resilience metric in areas not selected for protection. The median values of the climate-resilience metric for the two groups are represented by the vertical lines.")
      } else {
        paste("Climate-smart spatial planning option not selected.")
      }
    }) %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot7 <- fDownloadPlotServer(gg_reactive = ggr_clim, gg_prefix = "Climate", time_date_reactive = analysisTime)

    ## Details / Feature Summary Table -----------------------------------------

    DataTabler <- shiny::reactive({
      # Consume the shared targetPlotData reactives — fget_feature_representation
      # has already been called (and cached) by ggr_target; no duplicate work here.
      tbl1 <- fformat_feature_table(targetPlotData1(), Dict, suffix = " 1")
      tbl2 <- fformat_feature_table(targetPlotData2(), Dict, suffix = " 2")

      if (is.null(tbl1) || is.null(tbl2)) return(NULL)

      dplyr::full_join(tbl1, tbl2, by = c("Category", "Feature"))
    }) %>%
      shiny::bindEvent(input$analyse)

    # Cache populated on tab visit
    DataTabler_cache <- fmake_tab_cache(DataTabler, tab_id = 8, input = input)

    output$DataTable <- shiny::renderTable({
      DataTabler()
    }) %>%
      shiny::bindEvent(input$analyse)

    output$hdr_DetsData <- shiny::renderText("Feature Summary") %>%
      shiny::bindEvent(input$analyse)

    output$dlPlot8 <- fDownloadPlotServer(gg_reactive = DataTabler, gg_prefix = "DataSummary",
                                          time_date_reactive = analysisTime, type = "table")

    ## Log Tab -----------------------------------------------------------------
    # Render log text for Scenario 1
    output$logText1 <- shiny::renderText({
      solution1()  # Trigger the solve

      log <- solveLog1()
      if (is.null(log) || length(log) == 0 || nchar(log) == 0) {
        "No logs yet. Click 'Run Analysis' to generate output."
      } else {
        log
      }
    })

    # Render log text for Scenario 2
    output$logText2 <- shiny::renderText({
      solution2()  # Trigger the solve

      log <- solveLog2()
      if (is.null(log) || length(log) == 0 || nchar(log) == 0) {
        "No logs yet. Click 'Run Analysis' to generate output."
      } else {
        log
      }
    })

    output$txt_log_hint <- shiny::renderText({
      "This tab displays the problem setup and solve summary for each scenario. Switch between tabs to view logs for Scenario 1 and Scenario 2."
    })

    ## Report Generation -------------------------------------------------------
    # Registered once at module init; content function is lazy (only called on download click).
    # Reads from per-tab caches populated when the user visits each tab.
    output$downloadReportCompare <- shiny::downloadHandler(
      filename = function() {
        paste0("Comparison_Report_", analysisTime(), ".html")
      },
      content = function(file) {
        ts <- analysisTime()

        # Use tab-visit caches where available; fall back to evaluating the reactive
        frender_report(
          file             = file,
          output           = output,
          template_name    = "report_compare.qmd",
          notification_id  = "report_progress_compare",
          notification_msg = "Generating comparison report... This may take a moment. Do not click anything or navigate away from this page while you wait.",
          tmp_dir_prefix   = "qrender_compare_",
          plots = list(
            comp    = ggr_comp_cache()   %||% tryCatch(ggr_comp(),   error = function(e) NULL),
            soln    = ggr_soln_cache()   %||% tryCatch(ggr_soln(),   error = function(e) NULL),
            target  = ggr_target_cache() %||% tryCatch(ggr_target(), error = function(e) NULL),
            cost    = ggr_cost_cache()   %||% tryCatch(ggr_cost(),   error = function(e) NULL),
            climate = ggr_clim_cache()   %||% tryCatch(ggr_clim(),   error = function(e) NULL)
          ),
          tables = list(
            details = DataTabler_cache() %||% tryCatch(DataTabler(), error = function(e) NULL)
          ),
          params = list(
            solver_log1 = tryCatch(paste0(solveLog1(), collapse = "\n"), error = function(e) ""),
            solver_log2 = tryCatch(paste0(solveLog2(), collapse = "\n"), error = function(e) ""),
            cost_id1    = input$costid1,
            cost_id2    = input$costid2,
            climate_id1 = input$climateid1,
            climate_id2 = input$climateid2,
            timestamp   = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
          ),
          ts = ts
        )
      }
    )

  }) # end moduleServer
} # end mod_3compare_server

## To be copied in the UI
# mod_3compare_ui("3compare_ui_1")

## To be copied in the server
# mod_3compare_server("3compare_1")
