#' 2scenario UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom rlang .data
mod_2scenario_ui <- function(id) {
  ns <- shiny::NS(id)

  # Decide numbering for optional sections
  if (isTRUE(options$include_climateChange)){
    LI_num <- "4"
  } else {
    LI_num <- "3"
  }


  # TODO I want to use this in the server as well. Not sure how to pass between the two.
  slider_vars <- fcreate_vars(id = id,
                              Dict = Dict,
                              name_check = "sli_",
                              categoryOut = TRUE,
                              byCategory = FALSE)

  # Reformat varsIn for the category sliders
  slider_varsBioR <- fcreate_vars(id = id,
                                  Dict = Dict,
                                  name_check = "sli_",
                                  categoryOut = TRUE,
                                  byCategory = TRUE,
                                  dataType = "Bioregion")

  # Reformat varsIn for the category sliders
  slider_varsCat <- fcreate_vars(id = id,
                                 Dict = Dict,
                                 name_check = "sli_",
                                 categoryOut = TRUE,
                                 byCategory = TRUE)

  check_lockIn <- fcreate_check(id = id,
                                Dict = Dict,
                                idType = "LockIn",
                                name_check = "checkLI_",
                                categoryOut = TRUE)

  check_lockOut <- fcreate_check(id = id,
                                 Dict = Dict,
                                 idType = "LockOut",
                                 name_check = "checkLO_",
                                 categoryOut = TRUE)



  # shiny::tagList(
  # shiny::fluidPage(
  # actionLink("sidebar_button","",icon = icon("bars")
  shiny::sidebarLayout(
    shiny::sidebarPanel(

      # shiny::actionButton(ns("resetSlider"), "Reset All Sliders",
      #                     width = "100%", class = "btn btn-outline-primary",
      #                     style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
      # ),
      # shiny::hr(style = "border-top: 1px solid #000000;"),


      shinyjs::hidden(div(
        id = ns("switchMasterTargets"),
        shiny::h2("1. Select Master Target"),
        shiny::sliderInput(inputId = ns("masterSli"), label = NULL,
                           min = min(Dict$targetMin, na.rm = TRUE), max = max(Dict$targetMax, na.rm = TRUE),
                           step = 5,
                           value = round(mean(Dict$targetInitial, na.rm = TRUE))),
      )),

      shinyjs::hidden(div(
        id = ns("switchCategoryTargets"),
        shiny::h2("1. Select Category Targets"),
        fcustom_sliderCategory(slider_varsCat, labelNum = 1, byCategory = TRUE),
      )),

      shinyjs::hidden(div(
        id = ns("switchIndividualTargets"),
        shiny::h2("1. Select Targets"),
        fcustom_sliderCategory(slider_vars, labelNum = 1, byCategory = FALSE),
      )),

      shinyjs::hidden(div(
        id = ns("switchBioregions"),
        # TODO Add a conditional here to account for yes/no bioregions
        shiny::h3(paste0("1.", length(unique(slider_vars$category)) + 1, " Bioregions")),
        fcustom_sliderCategory(slider_varsBioR, labelNum = 1, byCategory = TRUE),
      )),

      shiny::hr(style = "border-top: 1px solid #000000;"),

      shiny::h2("2. Select Cost Layer"),
      create_fancy_dropdown(id, "costid", Dict %>%
                              dplyr::filter(.data$type == "Cost")),


      # Define Objective Function -----

      # shinyjs::hidden(div(
      #   id = ns("switchMinSet"),
      #   shiny::p("The objective function used here is ......."),
      #   shiny::h4("Minimum Set"),
      #   shiny::p("All targets will be met for the smallest possible cost.")
      # )),

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
          inputId = id,
          label = NULL,
          value = 100,
          min = 0,
          max = 1000,
        )
      )),



      shinyjs::hidden(div(
        id = ns("switchClimSmart"),
        shiny::h2("3. Climate-smart"),
        shiny::p("Should the spatial plan be made climate-smart?"),
        shiny::p("NOTE: This will slow down the analysis significantly. Be patient."),
        create_fancy_dropdown(id = id,
                              id_in = "climateid",
                              Dict = Dict %>%
                                dplyr::filter(.data$type == "Climate") %>%
                                dplyr::add_row(nameCommon = "Don't consider",
                                               category = "Climate", .before = 1)),
      )),

      shinyjs::hidden(div(
        id = ns("switchConstraints"),
        shiny::h2(paste0(LI_num,". Constraints")),
        shiny::p("You can also lock-in or lock-out some pre-defined areas to ensure they are either specifically included (lock-in) or excluded (lock-out) from the protected area. Planning Units outside these areas will be selected if needed to meet the targets."),
        shiny::h3(paste0(LI_num, ".1 Locked-In Areas")),
        fcustom_checkCategory(check_lockIn),
        shiny::h3(paste0(LI_num,".2 Locked-Out Areas")),
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
      ),
      width = 4),
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
        tabPanel("Scenario",
                 value = 1,
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
mod_2scenario_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    . <- NULL

    # Define all switches ----
    # I wonder if I can move these to a function as I can use the same
    # switches in mod3 as well.

    ## Define objective function ----
    if (options$obj_func == "min_shortfall") {
      shinyjs::show(id = "switchMinShortfall")
    } else {
      shinyjs::hide(id = "switchMinShortfall")
    }

    # I have turned this off. I don't think we want a description of the min_set
    # unless specifically asked for
    # if (options$obj_func == "min_set") {
    #   shinyjs::show(id = "switchMinSet")
    # } else {
    #   shinyjs::hide(id = "switchMinSet")
    # }


    ## Turn on Boundary Penalty -----
    if (isTRUE(options$switchBoundaryPenalty)) {
      shinyjs::show(id = "switchBoundaryPenalty")
    }

    ## Turn on Bioregions -----
    if (isTRUE(options$include_bioregion)) {
      shinyjs::show(id = "switchBioregions")
    }

    ## Turn on Climate Smart -----
    if (isTRUE(options$include_climateChange)) {
      shinyjs::show(id = "switchClimSmart")
    } else {
      shinyjs::hide(id = "switchClimSmart")

      # Hide the Climate tab if climate change is not enabled
      shiny::hideTab(inputId = "tabs", target = "6", session = session)
    }

    ## Turn off Report tab ----
    if (!isTRUE(options$include_report)) {
      shiny::hideTab(inputId = "tabs", target = "10", session = session)
    }

    ## Turn on Locked In/Out Constraints ----
    if (isTRUE(options$include_lockedArea)) {
      shinyjs::show(id = "switchConstraints")
    }

    observeEvent(input$disconnect, {
      session$close()
    })


    # TODO This is not working. Not sure why. Also not sure if we want that.
    # # Go back to the first tab when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shiny::updateTabsetPanel(session, "tabs", selected = 1)
    })

    # Go back to the top of the page when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shinyjs::runjs("window.scrollTo(0, 0)")
    })


    switch(options$targetsBy,
           "master" = shinyjs::show(id = "switchMasterTargets"), # Hide Individual targets,
           "category" = shinyjs::show(id = "switchCategoryTargets"), # Show Category targets
           "individual" = shinyjs::show(id = "switchIndividualTargets") # Hide Individual targets
    )




    slider_vars <- fcreate_vars(id = id,
                                Dict = Dict,
                                name_check = "sli_",
                                categoryOut = TRUE,
                                byCategory = FALSE)

    # Recreate lock-in/out objects for server logic
    check_lockIn <- fcreate_check(id = id,
                                  Dict = Dict,
                                  idType = "LockIn",
                                  name_check = "checkLI_",
                                  categoryOut = TRUE)

    check_lockOut <- fcreate_check(id = id,
                                   Dict = Dict,
                                   idType = "LockOut",
                                   name_check = "checkLO_",
                                   categoryOut = TRUE)

    # Reformat varsIn for the category sliders
    slider_varsBioR <- fcreate_vars(id = id,
                                    Dict = Dict,
                                    name_check = "sli_",
                                    categoryOut = TRUE,
                                    byCategory = TRUE,
                                    dataType = "Bioregion")

    # Reformat varsIn for the category sliders
    slider_varsCat <- fcreate_vars(id = id,
                                   Dict = Dict,
                                   name_check = "sli_",
                                   categoryOut = TRUE,
                                   byCategory = TRUE)



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


    # Reset Features
    shiny::observeEvent(input$resetSlider, {
      fresetSlider(session, input, output)
    }, ignoreInit = TRUE)

    # Generic lock-in/lock-out toggling for all features
    # Pair lock-in/lock-out toggling only for matching features
    lockIn_ids <- check_lockIn$id_in
    lockOut_ids <- check_lockOut$id_in

    # Extract feature names from input IDs (assumes format 'checkLI_feature')
    get_feature <- function(id, prefix) stringr::str_remove(id, prefix)
    lockIn_features <- purrr::map_chr(lockIn_ids, get_feature, prefix = "checkLI_")
    lockOut_features <- purrr::map_chr(lockOut_ids, get_feature, prefix = "checkLO_")

    # For each feature present in both lock-in and lock-out, set up paired observers
    # so they can't both be enabled at the same time
    shared_features <- intersect(lockIn_features, lockOut_features)
    purrr::walk(shared_features, function(feat) {
      lockInId <- paste0("checkLI_", feat)
      lockOutId <- paste0("checkLO_", feat)
      shiny::observeEvent(input[[lockInId]], {
        shinyjs::toggleState(lockOutId)
      }, ignoreInit = TRUE)
      shiny::observeEvent(input[[lockOutId]], {
        shinyjs::toggleState(lockInId)
      }, ignoreInit = TRUE)
    })



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



    p1Data <- shiny::reactive({
      p1 <- fdefine_problem(targetData(), raw_sf, options, input, clim_input = input$climateid)
      return(p1)
    })


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
    # Don't use bindEvent - let it update reactively whenever solveLog changes
    output$logText <- shiny::renderText({
      # Force solution() to run when on log tab by accessing it
      # This ensures the solve happens even when viewing the log tab
      solution()  # Trigger the solve

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


    analysisTime <- shiny::reactive({
      analysisTime <- format(Sys.time(), "%Y%m%d%H%M%S")
    }) %>% shiny::bindEvent(input$analyse)


    # Expose scoped reactives for report generation (filled inside respective observeEvent blocks)
    plot_data1 <- NULL
    gg_Target <- NULL
    costPlotData <- NULL
    ggr_clim <- NULL
    DataTabler <- NULL


    ############## All Plots #########################


    ## Binary Solution Plot ----------------------------------------------------

    observeEvent(
      {
        input$tabs == 1 | input$tabs == 10 | input$analyse > 0
      },
      {
        # Solution plotting reactive
        plot_data1 <<- shiny::reactive({

          # Guard: only attempt to plot if a solution exists
          if (!inherits(solution(), "sf")) {
            return(NULL)
          }

          print(dim(solution()))

          # Use consolidated helper function
          plot1 <- fplot_solution_with_constraints(
            soln = solution(),
            input = input,
            raw_sf = raw_sf,
            bndry = bndry,
            overlay = overlay,
            map_theme = map_theme,
            num = ""
          )

          return(plot1)
        })

        output$gg_soln <- shiny::renderPlot({
          req(inherits(solution(), "sf"))
          plot_data1()
        }, bg = "transparent")

        hdrr_soln <- shiny::reactive({
          txt_out <- "Your Scenario"
          return(txt_out)
        })


        output$hdr_soln <- shiny::renderText({
          hdrr_soln()
        }) %>%
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
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot1 <- fDownloadPlotServer(input, gg_id = plot_data1(), gg_prefix = "Solution", time_date = analysisTime()) # Download figure

        # Download spatial data (GeoJSON) containing only 'solution' attribute
        output$dlSpatial1 <- shiny::downloadHandler(
          filename = function() {
            paste0("Scenario_Spatial_", analysisTime(), ".geojson")
          },
          content = function(file) {
            sol <- solution()
            if (!inherits(sol, "sf")) {
              shiny::showNotification(
                "Please run an analysis before downloading the spatial file.",
                type = "error", duration = 5
              )
              stop("No solution available.")
            }

            # Ensure a 'solution' column exists; map from prioritizr's 'solution_1' if needed
            if (!("solution" %in% names(sol))) {
              if ("solution_1" %in% names(sol)) {
                names(sol)[names(sol) == "solution_1"] <- "solution"
              } else {
                # create a placeholder column if none exists
                sol <- dplyr::mutate(sol, solution = NA_integer_)
              }
            }

            sol_out <- sol %>%
              dplyr::select("solution") %>%
              sf::st_transform("EPSG:4326")

            # Write GeoJSON
            sf::st_write(sol_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
          }
        )

      }
    )



    ## Target Plot -------------------------------------------------------------

    observeEvent(
      {
        input$tabs == 2 | input$tabs == 10 | input$analyse > 0
      },
      {
        gg_Target <<- shiny::reactive({

          # Use consolidated helper function for feature representation
          targetPlotData <- fget_feature_representation(
            soln = solution(),
            problem_data = p1Data(),
            targets = targetData(),
            climate_id = input$climateid,
            options = options,
            Dict = Dict
          )

          # Return NULL if no data
          if (is.null(targetPlotData)) {
            return(NULL)
          }

          gg_Target <- spatialplanr::splnr_plot_featureRep(targetPlotData,
                                                           category = fget_category(Dict = Dict),
                                                           renameFeatures = TRUE,
                                                           namesToReplace = Dict,
                                                           nr = 2,
                                                           showTarget = TRUE,
                                                           sort_by = input$checkSort) +
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA)
            )

          return(gg_Target)
        }) %>%
          shiny::bindCache(input$analyse, input$checkSort)


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

        output$dlPlot2 <- fDownloadPlotServer(input, gg_id = gg_Target(), gg_prefix = "Target", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 2





    ## Cost Plot -------------------------------------------------------------

    observeEvent(
      {
        input$tabs == 3 | input$tabs == 10 | input$analyse > 0
      },
      {
        costPlotData <<- shiny::reactive({

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

        output$dlPlot3 <- fDownloadPlotServer(input, gg_id = costPlotData(), gg_prefix = "Cost", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 3

    ## Climate Tab -------------------------------------------------
    observeEvent(
      {
        input$tabs == 6 | input$tabs == 10 | input$analyse > 0
      },
      {
        ggr_clim <<- shiny::reactive({

          # Use consolidated helper function for climate plotting
          ggClimDens <- fplot_climate_density(
            soln_list = list(solution()),
            climate_ids = c(input$climateid),
            solution_names = c("solution_1")
          )

          return(ggClimDens)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$gg_clim <- shiny::renderPlot({
          if (input$climateid != "NA") {
            ggr_clim()
          }
        }, bg = "transparent")

        output$hdr_clim <- shiny::renderText({
          if (input$climateid != "NA") {
            paste("Climate Resilience")
          }
        }) %>%
          shiny::bindEvent(input$analyse)

        output$txt_clim <- shiny::renderText({
          if (input$climateid != "NA") {
            paste(tx_2climate)
          } else if (input$climateid == "NA") {
            paste("Climate-smart spatial planning option not selected.")
          }
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot6 <- fDownloadPlotServer(input, gg_id = ggr_clim(), gg_prefix = "Climate", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 6





    # Table of Targets --------------------------------------------------------

    observeEvent(
      {
        input$tabs == 7 | input$tabs == 10 | input$analyse > 0
      },
      {
        DataTabler <<- shiny::reactive({

          # Use consolidated helper function for feature representation
          targetPlotData <- fget_feature_representation(
            soln = solution(),
            problem_data = p1Data(),
            targets = targetData(),
            climate_id = input$climateid,
            options = options,
            Dict = Dict
          )

          # Return NULL if no data
          if (is.null(targetPlotData)) {
            return(NULL)
          }

          # Create named vector to do the replacement
          rpl <- Dict %>%
            dplyr::filter(.data$nameVariable %in% targetPlotData$feature) %>%
            dplyr::select("nameVariable", "nameCommon") %>%
            dplyr::mutate(nameVariable = stringr::str_c("^", .data$nameVariable, "$")) %>%
            tibble::deframe()

          # TODO Add category to spatialplanr::splnr_get_featureRep and remove from splnr_plot_featureRep
          FeaturestoSave <- targetPlotData %>%
            dplyr::left_join(Dict %>% dplyr::select("nameVariable", "category"), by = c("feature" = "nameVariable")) %>%
            dplyr::mutate(
              value = as.integer(round(.data$relative_held * 100)),
              target = as.integer(round(.data$target * 100))
            ) %>%
            dplyr::select("category", "feature", "target", "value", "incidental") %>%
            dplyr::rename(
              Feature = .data$feature,
              `Protection (%)` = .data$value,
              `Target (%)` = .data$target,
              Incidental = .data$incidental,
              Category = .data$category
            ) %>%
            dplyr::arrange(.data$Category, .data$Feature) %>%
            dplyr::mutate(Feature = stringr::str_replace_all(.data$Feature, rpl))

          return(FeaturestoSave)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$DataTable <- shiny::renderTable({
          DataTabler()
        }) %>%
          shiny::bindEvent(input$analyse)

        output$hdr_DetsData <- shiny::renderText(
          "Feature Summary"
        ) %>%
          shiny::bindEvent(input$analyse)

        # Create data tables for download
        ggr_DataPlot <- shiny::reactive({
          dat <- DataTabler() %>%
            dplyr::mutate(Class = as.factor(.data$Class)) %>%
            dplyr::group_by(.data$Class) %>%
            dplyr::group_split()

          design <- "AACC
           BBCC
           BBCC
           BBCC"

          ggr_DataPlot <- patchwork::wrap_plots(
            gridExtra::tableGrob(dat[[1]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 8)),
            gridExtra::tableGrob(dat[[2]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 8)),
            design = design
          ) &
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
            )

          return(ggr_DataPlot)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot7 <- fDownloadPlotServer(input, gg_id = DataTabler(), gg_prefix = "DataSummary", time_date = analysisTime(), width = 16, height = 10) # Download figure
      }
    ) # End observe event 7


    # Ecosystem Services Tab -------------------------------------------------
observeEvent(
      {
        input$tabs == 5 | input$tabs == 10 | input$analyse > 0
      },
      {


# Header and description text for ESS tab from markdown

output$txt_ess <- shiny::renderText(
      shiny::markdown(tx_2ess)
        ) %>%
          shiny::bindEvent(input$analyse)


        ess_para <<- shiny::reactive({

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

          # Calculate value in selected planning units (solution)
          ess_values <- sf::st_join(raw_sf %>% dplyr::select(dplyr::all_of(c(ess_layers, "geometry"))),
                             solution(),
             join = sf::st_equals) %>%
            dplyr::filter(.data$solution_1 == 1) %>%
            dplyr::select(dplyr::all_of(ess_layers)) %>%
            sf::st_drop_geometry() %>%
            tidyr::pivot_longer(cols = dplyr::everything(), names_to = "nameVariable", values_to = "Value") %>%
            dplyr::summarise(SelectedValue = sum(.data$Value, na.rm = TRUE), .by = "nameVariable") %>%
            dplyr::left_join(total_values, by = "nameVariable") %>%
            dplyr::left_join(Dict %>% dplyr::select(nameVariable, nameCommon, justification, units),
                             by = "nameVariable") %>%
            dplyr::mutate(
              Name = .data$nameCommon,
              Description = .data$justification,
              Value = paste0(round(.data$SelectedValue, 0), " ", .data$units),
              pct_selected = round((.data$SelectedValue / .data$TotalValue) * 100, 1),
              pct_unselected = 100 - .data$pct_selected
            ) %>%
            dplyr::select(Name, Description, Value, pct_selected, pct_unselected)

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

      }
      ) # End observe event 5






    ## Report Generation -------------------------------------------------------
    # Bind the report generation on analysis so it can access scoped reactives without visiting tabs
    observeEvent(input$analyse, {
      output$dlReport <- shiny::downloadHandler(
        filename = function() {
          paste0("Scenario_Report_", analysisTime(), ".html")
        },
        content = function(file) {
          # Show progress notification
          shiny::showNotification(
            "Generating report... This may take a moment. Do not click anything or navigate away from this page while you wait.",
            duration = NULL,
            closeButton = FALSE,
            id = "report_progress",
            type = "message"
          )

          # Update UI status while generating
          output$reportStatus <- shiny::renderUI({
            shiny::tagList(
              shiny::icon("spinner", class = "fa-spin"),
              shiny::span(" Generating report…")
            )
          })

          # Get the template path
          template_path <- system.file("app", "report_scenario.qmd", package = "shinyplanr")

          # If not found in installed package, try local inst/ directory
          if (template_path == "" || !file.exists(template_path)) {
            template_path <- "inst/app/report_scenario.qmd"
          }

          # Check if template exists
          if (!file.exists(template_path)) {
            shiny::removeNotification("report_progress")
            shiny::showNotification(
              "Report template not found. Please ensure report_scenario.qmd exists.",
              type = "error",
              duration = 10
            )
            return(NULL)
          }

          # Prepare assets (plots/tables) as files to avoid passing complex objects across sessions
          # Evaluate reactives to obtain objects
          sol_plot <- tryCatch({ if (is.function(plot_data1)) plot_data1() else NULL }, error = function(e) NULL)
          tgt_plot <- tryCatch({ if (is.function(gg_Target)) gg_Target() else NULL }, error = function(e) NULL)
          cst_plot <- tryCatch({ if (is.function(costPlotData)) costPlotData() else NULL }, error = function(e) NULL)
          clim_plot <- tryCatch({ if (input$climateid != "NA" && is.function(ggr_clim)) ggr_clim() else NULL }, error = function(e) NULL)
          det_table <- tryCatch({ if (is.function(DataTabler)) DataTabler() else NULL }, error = function(e) NULL)

          # Create file paths
          ts <- analysisTime()
          out_dir <- tempdir()
          sol_path  <- if (!is.null(sol_plot))  file.path(out_dir, paste0("solution_", ts, ".png"))  else NULL
          tgt_path  <- if (!is.null(tgt_plot))  file.path(out_dir, paste0("targets_", ts, ".png"))   else NULL
          cst_path  <- if (!is.null(cst_plot))  file.path(out_dir, paste0("cost_", ts, ".png"))      else NULL
          clim_path <- if (!is.null(clim_plot)) file.path(out_dir, paste0("climate_", ts, ".png"))   else NULL
          det_path  <- if (!is.null(det_table)) file.path(out_dir, paste0("details_", ts, ".csv"))   else NULL

          # Save plots if present
          try({ if (!is.null(sol_path))  ggplot2::ggsave(sol_path,  plot = sol_plot,  width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(tgt_path))  ggplot2::ggsave(tgt_path,  plot = tgt_plot,  width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(cst_path))  ggplot2::ggsave(cst_path,  plot = cst_plot,  width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)
          try({ if (!is.null(clim_path)) ggplot2::ggsave(clim_path, plot = clim_plot, width = 10, height = 8, dpi = 150, bg = "white") }, silent = TRUE)

          # Save details table if present
          try({ if (!is.null(det_path)) utils::write.csv(det_table, det_path, row.names = FALSE) }, silent = TRUE)

          # Consolidate solver log as a single string
          solver_log_txt <- tryCatch({ paste0(solveLog(), collapse = "\n") }, error = function(e) "")

          # Render the report by copying the QMD into a temp directory and rendering there
          tryCatch({
            tmp_dir <- file.path(tempdir(), paste0("qrender_", ts))
            if (!dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
            tmp_qmd <- file.path(tmp_dir, "report_scenario.qmd")
            file.copy(template_path, tmp_qmd, overwrite = TRUE)

            # Render in temp location; Quarto expects output_file to be a filename (no path)
            quarto::quarto_render(
              input = tmp_qmd,
              output_file = "report.html",
              execute_params = list(
                # Prefer file paths to avoid cross-session object passing
                solution_plot_path = sol_path,
                target_plot_path   = tgt_path,
                cost_plot_path     = cst_path,
                climate_plot_path  = clim_path,
                details_table_path = det_path,
                # Keep text/scalars as plain params
                solver_log = solver_log_txt,
                cost_id    = input$costid,
                climate_id = input$climateid,
                timestamp  = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
              )
            )

            # Copy the rendered HTML to the file path expected by Shiny
            out_html <- file.path(tmp_dir, "report.html")
            if (!file.exists(out_html)) stop("Rendered report not found at ", out_html)
            file.copy(out_html, file, overwrite = TRUE)

            shiny::removeNotification("report_progress")
            shiny::showNotification(
              "Report generated successfully!",
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
            shiny::removeNotification("report_progress")
            shiny::showNotification(
              paste("Error generating report:", e$message),
              type = "error",
              duration = 10
            )

            # Update UI with error
            output$reportStatus <- shiny::renderUI({
              shiny::tagList(
                shiny::icon("exclamation-triangle"),
                shiny::span(paste(" Error generating report:", e$message))
              )
            })
          })
        }
      )
    }, ignoreInit = TRUE)

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

  })
}

## To be copied in the UI
# mod_2scenario_ui("2scenario_1")

## To be copied in the server
# mod_2scenario_server("2scenario_1")
