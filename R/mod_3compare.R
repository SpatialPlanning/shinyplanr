#' 3compare UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_3compare_ui <- function(id) {

  ns <- NS(id)

  # Decide numbering for optional sections
  if (isTRUE(options$include_climateChange)){
    LI_num <- "4"
  } else {
    LI_num <- "3"
  }

  # TODO I need to look at the slider_ variables at the top of mod2 and work our
  #  how to implement that here. Then I need to implement the bioregions stuff

  Vars <- fcreate_vars(id = id, Dict = Dict, name_check = "sli_", categoryOut = TRUE)
  Vars2 <- fcreate_vars(id = id, Dict = Dict, name_check = "sli2_", categoryOut = TRUE)

  check_lockIn <- fcreate_check(id = id,
                                Dict = Dict,
                                idType = "LockIn",
                                name_check = "check1LI_",
                                categoryOut = TRUE)

  check_lockIn2 <- fcreate_check(id = id,
                                 Dict = Dict,
                                 idType = "LockIn",
                                 name_check = "check2LI_",
                                 categoryOut = TRUE)

  check_lockOut <- fcreate_check(id = id,
                                 Dict = Dict,
                                 idType = "LockOut",
                                 name_check = "check1LO_",
                                 categoryOut = TRUE)

  check_lockOut2 <- fcreate_check(id = id,
                                  Dict = Dict,
                                  idType = "LockOut",
                                  name_check = "check2LO_",
                                  categoryOut = TRUE)





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
      shiny::h2("1. Select Targets"),
      shiny::actionButton(ns("resetSlider"), "Reset All Features",
                          width = "100%", class = "btn btn-outline-primary",
                          style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
      ),
      shiny::splitLayout(
        fcustom_sliderCategory(Vars, labelNum = 1),
        fcustom_sliderCategory(Vars2, labelNum = 1, labelCategory = FALSE)
      ),
      #   purrr::pmap(Vars, fcustom_slider),
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
        id = ns("switchClimSmart"),
        shiny::h2("3. Climate-smart"),
        shiny::p("Should the spatial plan be made climate-resilient?"),
        shiny::p("NOTE: This will slow down the analysis significantly. Be patient."),
        shiny::splitLayout(
          create_fancy_dropdown(id = id,  id_in = "climateid1", Dict = Dict %>%
                                  dplyr::filter(.data$type == "Climate") %>%
                                  dplyr::add_row(nameCommon = "Don't consider",
                                                 category = "Climate", .before = 1)),
          create_fancy_dropdown(id = id,  id_in = "climateid2", Dict = Dict %>%
                                  dplyr::filter(.data$type == "Climate") %>%
                                  dplyr::add_row(nameCommon = "Don't consider",
                                                 category = "Climate", .before = 1)),
        )
      )),
      #
      #       shinyjs::hidden(div(
      #         id = ns("switchConstraints"),
      #         shiny::h2("3. Constraints"),
      #         shiny::splitLayout(
      #           fcustom_checkCategory(check_lockIn, labelNum = 3),
      #           fcustom_checkCategory(check_lockIn2, labelNum = 3)
      #         ),
      # )),


      shinyjs::hidden(div(
        id = ns("switchConstraints"),
        shiny::h2(paste0(LI_num,". Constraints")),
        shiny::p("You can also lock-in or lock-out some pre-defined areas to ensure they are either specifically included (lock-in) or excluded (lock-out) from the protected area. Planning Units outside these areas will be selected if needed to meet the targets."),
        shiny::h3(paste0(LI_num, ".1 Locked-In Areas")),
        shiny::splitLayout(
          fcustom_checkCategory(check_lockIn),
          fcustom_checkCategory(check_lockIn2)
        ),
        shiny::h3(paste0(LI_num,".2 Locked-Out Areas")),
        shiny::splitLayout(
          fcustom_checkCategory(check_lockOut),
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
      shinydisconnect::disconnectMessage(
        text = "Your session timed out, reload the application.",
        refresh = "Reload now",
        background = "#f89f43",
        colour = "white",
        overlayColour = "grey",
        overlayOpacity = 0.3,
        refreshColour = "brown"
      ),

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
mod_3compare_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    . <- NULL

    # Recreate lock-in/out objects for server logic
    check_lockIn <- fcreate_check(id = id,
                                  Dict = Dict,
                                  idType = "LockIn",
                                  name_check = "check1LI_",
                                  categoryOut = TRUE)

    check_lockIn2 <- fcreate_check(id = id,
                                   Dict = Dict,
                                   idType = "LockIn",
                                   name_check = "check2LI_",
                                   categoryOut = TRUE)

    check_lockOut <- fcreate_check(id = id,
                                   Dict = Dict,
                                   idType = "LockOut",
                                   name_check = "check1LO_",
                                   categoryOut = TRUE)

    check_lockOut2 <- fcreate_check(id = id,
                                    Dict = Dict,
                                    idType = "LockOut",
                                    name_check = "check2LO_",
                                    categoryOut = TRUE)

    if (isTRUE(options$include_climateChange)) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchClimSmart")
    } else {
      shinyjs::hide(id = "switchClimSmart")

      # Hide the Climate tab if climate change is not enabled
      shiny::hideTab(inputId = "tabs", target = "7", session = session)
    }

      # Hide the Report tab if include_report is FALSE
      if (!isTRUE(options$include_report)) {
        shiny::hideTab(inputId = "tabs", target = "10", session = session)
      }

    if (isTRUE(options$include_lockedArea)) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchConstraints")
    }

    observeEvent(input$disconnect, {
      session$close()
    })

    shiny::observeEvent(input$resetSlider,
                        {fresetSlider(session, input, output, id = 1)
                        },ignoreInit = TRUE
    )

    shiny::observeEvent(input$resetSlider,
                        {fresetSlider(session, input, output, id = 2)
                        },ignoreInit = TRUE
    )

    # # Go back to the first tab when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shiny::updateTabsetPanel(session, "tabs", selected = 1)
    })

    # Go back to the top of the page when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shinyjs::runjs("window.scrollTo(0, 0)")
    })


    # TODO This needs to be made generic.... somehow....

    # Generic lock-in/lock-out toggling for all features (Scenario 1)
    # Pair lock-in/lock-out toggling only for matching features (Scenario 1)
    lockIn_ids1 <- check_lockIn$id_in
    lockOut_ids1 <- check_lockOut$id_in
    get_feature <- function(id, prefix) stringr::str_remove(id, prefix)
    lockIn_features1 <- purrr::map_chr(lockIn_ids1, get_feature, prefix = "check1LI_")
    lockOut_features1 <- purrr::map_chr(lockOut_ids1, get_feature, prefix = "check1LO_")
    shared_features1 <- intersect(lockIn_features1, lockOut_features1)
    purrr::walk(shared_features1, function(feat) {
      lockInId <- paste0("check1LI_", feat)
      lockOutId <- paste0("check1LO_", feat)
      shiny::observeEvent(input[[lockInId]], {
        shinyjs::toggleState(lockOutId)
      }, ignoreInit = TRUE)
      shiny::observeEvent(input[[lockOutId]], {
        shinyjs::toggleState(lockInId)
      }, ignoreInit = TRUE)
    })

    # Generic lock-in/lock-out toggling for all features (Scenario 2)
    # Pair lock-in/lock-out toggling only for matching features (Scenario 2)
    lockIn_ids2 <- check_lockIn2$id_in
    lockOut_ids2 <- check_lockOut2$id_in
    lockIn_features2 <- purrr::map_chr(lockIn_ids2, get_feature, prefix = "check2LI_")
    lockOut_features2 <- purrr::map_chr(lockOut_ids2, get_feature, prefix = "check2LO_")
    shared_features2 <- intersect(lockIn_features2, lockOut_features2)
    purrr::walk(shared_features2, function(feat) {
      lockInId <- paste0("check2LI_", feat)
      lockOutId <- paste0("check2LO_", feat)
      shiny::observeEvent(input[[lockInId]], {
        shinyjs::toggleState(lockOutId)
      }, ignoreInit = TRUE)
      shiny::observeEvent(input[[lockOutId]], {
        shinyjs::toggleState(lockInId)
      }, ignoreInit = TRUE)
    })





    # Get Target Data
    targetData1 <- shiny::reactive({
      targets <- fget_targets_with_bioregions(input, name_check = "sli_", Dict = Dict)
      return(targets)
    })

    targetData2 <- shiny::reactive({
      targets <- fget_targets_with_bioregions(input, name_check = "sli2_", Dict = Dict)
      return(targets)
    })

    # Define Problems
    p1Data <- shiny::reactive({
      p1 <- fdefine_problem(targetData1(), raw_sf, options, input, clim_input = input$climateid1, compare_id = "1")
      return(p1)
    })

    p2Data <- shiny::reactive({
      p2 <- fdefine_problem(targetData2(), raw_sf, options, input, clim_input = input$climateid2, compare_id = "2")
      return(p2)
    })


    analysisTime <- shiny::reactive({
      analysisTime <- format(Sys.time(), "%Y%m%d%H%M%S")
    }) %>% shiny::bindEvent(input$analyse)

    # Expose scoped reactives for report generation (populated inside observeEvent blocks)
    ggr_comp <- NULL
    ggr_soln <- NULL
    ggr_target <- NULL
    ggr_cost <- NULL
    ggr_clim <- NULL
    DataTabler <- NULL

    # Solve the problems and capture logs -------------------------------------------------------
    solveLog1 <- shiny::reactiveVal(character(0))
    solveLog2 <- shiny::reactiveVal(character(0))

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
    observeEvent(
      {
        input$tabs == 1 | input$tabs == 10 | input$analyse > 0
      },
      {
        ggr_comp <<- shiny::reactive({

          area1 <- solution1() %>%
            dplyr::filter(.data$solution_1 == 1) %>%
            nrow()
          area2 <- solution2() %>%
            dplyr::filter(.data$solution_1 == 1) %>%
            nrow()

          area_change1 <- round(((area2 - area1) / nrow(solution1())) * 100) # As
          area_change2 <- round(((area2 - area1) / area1) * 100)

          if (area_change1 > 0) {
            txt_comb <- paste0("Area 2 is ", area_change2, "% larger than Area 1\nand contains ", area_change1, "% more of the\nplanning region")
          } else if (area_change1 < 0) {
            txt_comb <- paste0("Area 2 is ", abs(area_change2), "% smaller than Area 1\nand contains ", abs(area_change1), "% less of the\nplanning region")
          } else if (area_change1 == 0) {
            txt_comb <- paste0("Area 1 and Area 2 are the same size.")
          }

          ggr_comp <- spatialplanr::splnr_plot_comparison(solution1(), solution2()) +
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

          return(ggr_comp)
        })

        output$gg_comp <- shiny::renderPlot({
          ggr_comp()
        }, bg = "transparent")

        output$dlPlot1 <- fDownloadPlotServer(input, gg_id = ggr_comp(), gg_prefix = "Compare", time_date = analysisTime()) # Download figure

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

            # Create comparison layer showing: only in scenario 1, only in scenario 2, in both
            sol1_selected <- sol1$solution_1 == 1
            sol2_selected <- sol2$solution_1 == 1

            comp_sf <- sol1
            comp_sf$comparison <- dplyr::case_when(
              sol1_selected & sol2_selected ~ "Both scenarios",
              sol1_selected & !sol2_selected ~ "Scenario 1 only",
              !sol1_selected & sol2_selected ~ "Scenario 2 only",
              TRUE ~ "Neither scenario"
            )

            # Only keep planning units that are in at least one scenario
            comp_out <- comp_sf %>%
              dplyr::filter(.data$comparison != "Neither scenario") %>%
              dplyr::select("comparison") %>%
              sf::st_transform("EPSG:4326")

            # Write GeoJSON
            sf::st_write(comp_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
          }
        )

      }
    ) # end observeEvent 1

    #### Binary Solution Plot ####

    observeEvent(
      {
        input$tabs == 2 | input$tabs == 10 | input$analyse > 0
      },
      {
        # Solution plotting reactive
        ggr_soln <<- shiny::reactive({

          ## PLOT 1 - Use consolidated helper function
          plot_soln1 <- fplot_solution_with_constraints(
            soln = solution1(),
            input = input,
            raw_sf = raw_sf,
            bndry = bndry,
            overlay = overlay,
            map_theme = map_theme,
            num = "1"
          )

          ## PLOT 2 - Use consolidated helper function
          plot_soln2 <- fplot_solution_with_constraints(
            soln = solution2(),
            input = input,
            raw_sf = raw_sf,
            bndry = bndry,
            overlay = overlay,
            map_theme = map_theme,
            num = "2"
          )

          ## COMBINE PLOTS
          ggr_soln <- patchwork::wrap_plots(
            plot_soln1,
            plot_soln2,
            nrow = 1,
            guides = "collect"
          ) &
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

          return(ggr_soln)

        })

        output$gg_soln <- shiny::renderPlot({
          ggr_soln()
        }, bg = "transparent")

        hdrr_soln1 <- shiny::reactive({
          txt_out <- "Scenario 1"
          return(txt_out)
        })

        hdrr_soln2 <- shiny::reactive({
          txt_out <- "Scenario 2"
          return(txt_out)
        })

        output$hdr_soln1 <- shiny::renderText({
          hdrr_soln1()
        }) %>%
          shiny::bindEvent(input$analyse)

        output$hdr_soln2 <- shiny::renderText({
          hdrr_soln2()
        }) %>%
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
          if (input$costid1 != "Cost_None") {
            paste(soln_text1[[1]], soln_text1[[2]])
          } else {
            paste(soln_text1[[1]])
          }
        }) %>%
          shiny::bindEvent(input$analyse)


        output$txt_soln2 <- shiny::renderText({
          soln_text2 <- fSolnText(input, solution2(), input$costid2)
          if (input$costid2 != "Cost_None") {
            paste(soln_text2[[1]], soln_text2[[2]])
          } else {
            paste(soln_text2[[1]])
          }
        }) %>%
          shiny::bindEvent(input$analyse)


        output$dlPlot2 <- fDownloadPlotServer(input, gg_id = ggr_soln(), gg_prefix = "Solution", time_date = analysisTime()) # Download figure

        # Download spatial data for Scenario 1
        output$dlSpatial1 <- shiny::downloadHandler(
          filename = function() {
            paste0("Scenario1_Spatial_", analysisTime(), ".geojson")
          },
          content = function(file) {
            sol <- solution1()
            if (!inherits(sol, "sf")) {
              shiny::showNotification(
                "Please run an analysis before downloading the spatial file.",
                type = "error", duration = 5
              )
              stop("No solution available.")
            }

            # Ensure a 'solution' column exists
            if (!("solution" %in% names(sol))) {
              if ("solution_1" %in% names(sol)) {
                names(sol)[names(sol) == "solution_1"] <- "solution"
              } else {
                sol <- dplyr::mutate(sol, solution = NA_integer_)
              }
            }

            sol_out <- sol %>%
              dplyr::select("solution") %>%
              sf::st_transform("EPSG:4326")

            sf::st_write(sol_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
          }
        )

        # Download spatial data for Scenario 2
        output$dlSpatial2 <- shiny::downloadHandler(
          filename = function() {
            paste0("Scenario2_Spatial_", analysisTime(), ".geojson")
          },
          content = function(file) {
            sol <- solution2()
            if (!inherits(sol, "sf")) {
              shiny::showNotification(
                "Please run an analysis before downloading the spatial file.",
                type = "error", duration = 5
              )
              stop("No solution available.")
            }

            # Ensure a 'solution' column exists
            if (!("solution" %in% names(sol))) {
              if ("solution_1" %in% names(sol)) {
                names(sol)[names(sol) == "solution_1"] <- "solution"
              } else {
                sol <- dplyr::mutate(sol, solution = NA_integer_)
              }
            }

            sol_out <- sol %>%
              dplyr::select("solution") %>%
              sf::st_transform("EPSG:4326")

            sf::st_write(sol_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
          }
        )

      }
    ) # end observeEvent 2

    ## Target Plot -------------------------------------------------------------


    observeEvent(
      {
        input$tabs == 3 | input$tabs == 10 | input$analyse > 0
      },
      {
        ggr_target <<- shiny::reactive({

          ## DATA FOR PLOT 1 - Use consolidated helper function
          targetPlotData1 <- fget_feature_representation(
            soln = solution1(),
            problem_data = p1Data(),
            targets = targetData1(),
            climate_id = input$climateid1,
            options = options,
            Dict = Dict
          )

          ## DATA FOR PLOT 2 - Use consolidated helper function
          targetPlotData2 <- fget_feature_representation(
            soln = solution2(),
            problem_data = p2Data(),
            targets = targetData2(),
            climate_id = input$climateid2,
            options = options,
            Dict = Dict
          )

          # Return NULL if either plot has no data
          if (is.null(targetPlotData1) || is.null(targetPlotData2)) {
            return(NULL)
          }

          ggr_target <- patchwork::wrap_plots(

            spatialplanr::splnr_plot_featureRep(targetPlotData1,
                                                nr = 2,
                                                showTarget = TRUE,
                                                category = fget_category(Dict = Dict),
                                                renameFeatures = TRUE,
                                                namesToReplace = Dict,
                                                sort_by = input$checkSort) +
              ggplot2::ggtitle("Scenario 1") +
              ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                             legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
              ),

            spatialplanr::splnr_plot_featureRep(targetPlotData2,
                                                nr = 2,
                                                showTarget = TRUE,
                                                category = fget_category(Dict = Dict),
                                                renameFeatures = TRUE,
                                                namesToReplace = Dict,
                                                sort_by = input$checkSort) +
              ggplot2::ggtitle("Scenario 2") +
              ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                             legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
              ),
            nrow = 1, guides = "collect") &
            ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal",
                           plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
            )

          return(ggr_target)

        }) %>%
          shiny::bindCache(input$analyse, input$checkSort)


        output$gg_target <- shiny::renderPlot({
          ggr_target()
        }, bg = "transparent")

        output$hdr_target <- shiny::renderText({
          "Targets"
        }) %>%
          shiny::bindEvent(input$analyse)

        output$txt_target <- shiny::renderText({
          "Given the scenario for the spatial planning problem formulated with
      the chosen inputs, these plots show the proportion of
      suitable habitat/area of each of the important and representative
      conservation features that are included. The dashed line represents
      the set target for the features. Hollow bars with a black border indicate incidental
        protection of features which were not chosen in this analysis but have areal overlap with selected planning units."
        })

        output$dlPlot3 <- fDownloadPlotServer(input, gg_id = ggr_target(), gg_prefix = "Target", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 3
    ## Cost Plot -------------------------------------------------------------

    observeEvent(
      {
        input$tabs == 4 | input$tabs == 10 | input$analyse > 0
      },
      {
        ggr_cost <<- shiny::reactive({

          gg_cost1 <- spatialplanr::splnr_plot_costOverlay(soln = solution1(),
                                                           cost = NA,
                                                           costName = input$costid1,
                                                           legendTitle = "Cost",
                                                           plotTitle = "Solution overlaid with cost"
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


          gg_cost2 <- spatialplanr::splnr_plot_costOverlay(soln = solution2(),
                                                           cost = NA,
                                                           costName = input$costid2,
                                                           legendTitle = "Cost",
                                                           plotTitle = "Solution overlaid with cost"
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = solution2(),
              ggtheme = map_theme
            ) +
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
            )


          ggr_cost <- patchwork::wrap_plots(gg_cost1 + ggplot2::ggtitle("Scenario 1"),
                                            gg_cost2 + ggplot2::ggtitle("Scenario 2"),
                                            nrow = 1, guides = "collect"
          ) &
            ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal",
                           plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
            )

          return(ggr_cost)
        })


        output$gg_cost <- shiny::renderPlot({
          ggr_cost()
        }, bg = "transparent")

        output$hdr_cost <- shiny::renderText({
          "The Cost Layer Overlaid with Selection"
        }) %>%
          shiny::bindEvent(input$analyse)



        # TODO Move this text to the Dictionary and implement call to display here as usual
        output$txt_cost <- shiny::renderText({
          # Extract cost info from Dictionary for justification
          cost_txt1 <- Dict %>%
            dplyr::filter(.data$nameVariable == input$costid1)

          cost_txt2 <- Dict %>%
            dplyr::filter(.data$nameVariable == input$costid2)

          paste0(
            "To illustrate how the chosen cost influences the spatial plan, this plot shows the
             spatial plan (= scenario) overlaid with the cost of including a planning unit in a
             reserve. The cost used on the left is ", cost_txt1$nameCommon, " and ",
            stringr::str_remove(cost_txt1$justification, "This cost"), "The cost on the right is ",
            cost_txt2$nameCommon, " and ", stringr::str_remove(cost_txt2$justification, "This cost")
          )
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot4 <- fDownloadPlotServer(input, gg_id = ggr_cost(), gg_prefix = "Cost", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 4

    ## Climate Resilience Plot -------------------------------------------------

    observeEvent(
      {
        input$tabs == 7 | input$tabs == 10 | input$analyse > 0
      },
      {
        ggr_clim <<- shiny::reactive({

          # Use consolidated helper function for climate plotting
          ggClimDens <- fplot_climate_density(
            soln_list = list(solution1(), solution2()),
            climate_ids = c(input$climateid1, input$climateid2),
            solution_names = c("solution_1", "solution_1")
          )

          return(ggClimDens)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$gg_clim <- shiny::renderPlot({
          if (input$climateid1 != "NA" | input$climateid2 != "NA") {
            ggr_clim()
          }
        }, bg = "transparent")

        output$hdr_clim <- shiny::renderText({
          if (input$climateid1 != "NA" | input$climateid2 != "NA") {
            paste("Climate Resilience")
          }
        }) %>%
          shiny::bindEvent(input$analyse)

        output$txt_clim <- shiny::renderText({
          if (input$climateid1 != "NA" | input$climateid2 != "NA") {
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

        output$dlPlot7 <- fDownloadPlotServer(input, gg_id = ggr_clim(), gg_prefix = "Climate", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 5



    observeEvent(
      {
        input$tabs == 8 | input$tabs == 10 | input$analyse > 0
      },
      {
        # for saving data/ data next to plot
        DataTabler <<- shiny::reactive({

          # Use consolidated helper function for feature representation - Scenario 1
          targetPlotData1 <- fget_feature_representation(
            soln = solution1(),
            problem_data = p1Data(),
            targets = targetData1(),
            climate_id = input$climateid1,
            options = options,
            Dict = Dict
          ) %>%
            # TODO Move this mutate to spatialplanr to account for zeros
            dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))

          # Use consolidated helper function for feature representation - Scenario 2
          targetPlotData2 <- fget_feature_representation(
            soln = solution2(),
            problem_data = p2Data(),
            targets = targetData2(),
            climate_id = input$climateid2,
            options = options,
            Dict = Dict
          ) %>%
            # TODO Move this mutate to spatialplanr to account for zeros
            dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))

          # Return NULL if either has no data
          if (is.null(targetPlotData1) || is.null(targetPlotData2)) {
            return(NULL)
          }

          # Create named vector to do the replacement
          rpl <- Dict %>%
            dplyr::filter(.data$nameVariable %in% unique(c(targetPlotData1$feature, targetPlotData2$feature))) %>%
            dplyr::select("nameVariable", "nameCommon") %>%
            dplyr::mutate(nameVariable = stringr::str_c("^", .data$nameVariable, "$")) %>%
            tibble::deframe()

          # TODO Add category to spatialplanr::splnr_get_featureRep and remove from splnr_plot_featureRep
          FeaturestoSave1 <- targetPlotData1 %>%
            dplyr::left_join(Dict %>% dplyr::select("nameVariable", "category"), by = c("feature" = "nameVariable")) %>%
            dplyr::mutate(
              value = as.integer(round(.data$relative_held * 100)),
              target = as.integer(round(.data$target * 100))
            ) %>%
            dplyr::select("category", "feature", "target", "value", "incidental") %>%
            dplyr::rename(
              Feature = .data$feature,
              `Protection 1 (%)` = .data$value,
              `Target 1 (%)` = .data$target,
              `Incidental 1` = .data$incidental,
              Category = .data$category
            ) %>%
            dplyr::arrange(.data$Category, .data$Feature) %>%
            dplyr::mutate(Feature = stringr::str_replace_all(.data$Feature, rpl))

          FeaturestoSave2 <- targetPlotData2 %>%
            dplyr::left_join(Dict %>% dplyr::select("nameVariable", "category"), by = c("feature" = "nameVariable")) %>%
            dplyr::mutate(
              value = as.integer(round(.data$relative_held * 100)),
              target = as.integer(round(.data$target * 100))
            ) %>%
            dplyr::select("category", "feature", "target", "value", "incidental") %>%
            dplyr::rename(
              Feature = .data$feature,
              `Protection 2 (%)` = .data$value,
              `Target 2 (%)` = .data$target,
              `Incidental 2` = .data$incidental,
              Category = .data$category
            ) %>%
            dplyr::arrange(.data$Category, .data$Feature) %>%
            dplyr::mutate(Feature = stringr::str_replace_all(.data$Feature, rpl))

          # TODO - Change to full join for compare
          FeaturestoSave <- dplyr::full_join(FeaturestoSave1, FeaturestoSave2, by = c("Category", "Feature"))

          return(FeaturestoSave)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$DataTable <- shiny::renderTable({
          DataTabler()
        }) %>%
          shiny::bindEvent(input$analyse)

        output$hdr_DetsData <- shiny::renderText("Feature Summary") %>%
          shiny::bindEvent(input$analyse)

        # Create data tables for download
        ggr_DataPlot <- shiny::reactive({
          dat <- DataTabler() %>%
            dplyr::mutate(Class = as.factor(.data$Class)) %>%
            dplyr::group_by(.data$Class) %>%
            dplyr::group_split()

          design <- "BBAA
           BBCC
           BBCC
           BBCC"

          ggr_DataPlot <- patchwork::wrap_plots(
            # gridExtra::tableGrob(SummaryTabler(), rows = NULL, theme = gridExtra::ttheme_default(base_size = 9)),
            gridExtra::tableGrob(dat[[1]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 7)),
            gridExtra::tableGrob(dat[[2]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 7)),
            design = design
          ) &
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
            )

          return(ggr_DataPlot)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot8 <- fDownloadPlotServer(input, gg_id = DataTabler(), gg_prefix = "DataSummary", time_date = analysisTime(), width = 16, height = 10) # Download figure
      }
    ) # End observe event 8

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
    # Bind the report generation on analysis so it can access scoped reactives without visiting tabs
    observeEvent(input$analyse, {
      output$downloadReportCompare <- shiny::downloadHandler(
        filename = function() {
          paste0("Comparison_Report_", analysisTime(), ".html")
        },
        content = function(file) {
          # Show progress notification
          shiny::showNotification(
            "Generating comparison report... This may take a moment. Do not click anything or navigate away from this page while you wait.",
            duration = NULL,
            closeButton = FALSE,
            id = "report_progress_compare",
            type = "message"
          )

          # Update UI status while generating
          output$reportStatus <- shiny::renderUI({
            shiny::tagList(
              shiny::icon("spinner", class = "fa-spin"),
              shiny::span(" Generating comparison report…")
            )
          })

          # Resolve template path

          # Resolve template path
          template_path <- system.file("app", "report_compare.qmd", package = "shinyplanr")
          if (template_path == "" || !file.exists(template_path)) {
            template_path <- "inst/app/report_compare.qmd"
          }
          if (!file.exists(template_path)) {
            shiny::removeNotification("report_progress_compare")
            shiny::showNotification(
              "Comparison report template not found (report_compare.qmd).",
              type = "error",
              duration = 10
            )
            return(NULL)
          }

          # Evaluate existing reactives and save to files
          ts <- analysisTime()
          out_dir <- tempdir()
          comp_plot <- tryCatch({ if (is.function(ggr_comp)) ggr_comp() else NULL }, error = function(e) NULL)
          soln_plot <- tryCatch({ if (is.function(ggr_soln)) ggr_soln() else NULL }, error = function(e) NULL)
          target_plot <- tryCatch({ if (is.function(ggr_target)) ggr_target() else NULL }, error = function(e) NULL)
          cost_plot <- tryCatch({ if (is.function(ggr_cost)) ggr_cost() else NULL }, error = function(e) NULL)
          climate_plot <- tryCatch({ if (is.function(ggr_clim)) ggr_clim() else NULL }, error = function(e) NULL)
          details_tbl <- tryCatch({ if (is.function(DataTabler)) DataTabler() else NULL }, error = function(e) NULL)

          comp_path <- if (!is.null(comp_plot)) file.path(out_dir, paste0("compare_", ts, ".png")) else NULL
          soln_path <- if (!is.null(soln_plot)) file.path(out_dir, paste0("solutions_", ts, ".png")) else NULL
          target_path <- if (!is.null(target_plot)) file.path(out_dir, paste0("targets_", ts, ".png")) else NULL
          cost_path <- if (!is.null(cost_plot)) file.path(out_dir, paste0("cost_", ts, ".png")) else NULL
          climate_path <- if (!is.null(climate_plot)) file.path(out_dir, paste0("climate_", ts, ".png")) else NULL
          details_path <- if (!is.null(details_tbl)) file.path(out_dir, paste0("details_", ts, ".csv")) else NULL

          # Save plots/tables
          try({ if (!is.null(comp_path)) ggplot2::ggsave(comp_path, plot = comp_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(soln_path)) ggplot2::ggsave(soln_path, plot = soln_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(target_path)) ggplot2::ggsave(target_path, plot = target_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(cost_path)) ggplot2::ggsave(cost_path, plot = cost_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(climate_path)) ggplot2::ggsave(climate_path, plot = climate_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(details_path)) utils::write.csv(details_tbl, details_path, row.names = FALSE) }, silent = TRUE)

          # Solver logs
          solver_log1_txt <- tryCatch({ paste0(solveLog1(), collapse = "\n") }, error = function(e) "")
          solver_log2_txt <- tryCatch({ paste0(solveLog2(), collapse = "\n") }, error = function(e) "")

          # Render in temp dir
          tryCatch({
            tmp_dir <- file.path(tempdir(), paste0("qrender_compare_", ts))
            if (!dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
            tmp_qmd <- file.path(tmp_dir, "report_compare.qmd")
            file.copy(template_path, tmp_qmd, overwrite = TRUE)

            quarto::quarto_render(
              input = tmp_qmd,
              output_file = "report.html",
              execute_params = list(
                comp_plot_path   = comp_path,
                soln_plot_path   = soln_path,
                target_plot_path = target_path,
                cost_plot_path   = cost_path,
                climate_plot_path = climate_path,
                details_table_path = details_path,
                solver_log1 = solver_log1_txt,
                solver_log2 = solver_log2_txt,
                cost_id1 = input$costid1,
                cost_id2 = input$costid2,
                climate_id1 = input$climateid1,
                climate_id2 = input$climateid2,
                timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
              )
            )

            out_html <- file.path(tmp_dir, "report.html")
            if (!file.exists(out_html)) stop("Rendered comparison report not found at ", out_html)
            file.copy(out_html, file, overwrite = TRUE)

            shiny::removeNotification("report_progress_compare")
            shiny::showNotification(
              "Comparison report generated successfully!",
              type = "message",
              duration = 3
            )

            # Update UI with success message
            output$reportStatus <- shiny::renderUI({
              shiny::tagList(
                shiny::icon("check-circle"),
                shiny::span(paste(" Report generated at", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
              )
            })
          }, error = function(e) {
            shiny::removeNotification("report_progress_compare")
            shiny::showNotification(
              paste("Error generating comparison report:", e$message),
              type = "error",
              duration = 10
            )

            # Update UI with error
            output$reportStatus <- shiny::renderUI({
              shiny::tagList(
                shiny::icon("exclamation-triangle"),
                shiny::span(paste(" Error generating comparison report:", e$message))
              )
            })
          })
        }
      )
    }, ignoreInit = TRUE)

  })
}

## To be copied in the UI
# mod_3compare_ui("3compare_ui_1")

## To be copied in the server
# mod_3compare_server("3compare_1")
