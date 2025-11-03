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

      # SHOULD THIS BE A PERCENTAGE OR A VALUE?

      shinyjs::hidden(div(
        id = ns("switchMinShortfall"),
        shiny::p("Total budget amount for scenario."),
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
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot1"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_soln")))),
                 shiny::textOutput(ns("txt_soln")),
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_soln"), height = "700px"))
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
                                                # "Feature" = "feature",
                                                "Target" = "target",
                                                "Representation" = "representation",
                                                "Difference from Target" = "difference"),
                                    selected = "category",  multiple = FALSE),

                 # shinyWidgets::prettyCheckboxGroup(inputId = ns("checkSort"),
                 #                                   label = "Sort plot by:",
                 #                                   choiceValues = c("category", "feature", "target",  "representation", "difference"),
                 #                                   choiceNames = c("Category", "Feature", "Target",  "Representation", "Difference from Target"),
                 #                                   selected = "category",
                 #                                   inline = TRUE,
                 #                                   thick = TRUE,
                 #                                   animation = "pulse",
                 #                                   status = "info"),
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
        # tabPanel("Selection Frequency", value = 5,
        #          shiny::fixedPanel(style="z-index:100", # To force the button above all plots.
        #                            shiny::downloadButton(ns("dlPlot5"), "Download Plot",
        #                                                  style = "float: right; padding:4px; font-size:120%"),
        #                            right = '1%', bottom = '1%', left = '34%'),
        #          shiny::br(),
        #          shiny::actionButton(ns("plotSelFreq"), "Show Selection Frequency", align = "center",
        #                              style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"),
        #          shiny::p("WARNING: This will take 1-5 minutes to run. Please don't press the button several times or navigate away from this page while the analysis is running.", align = "center"),
        #          shiny::span(shiny::h2(shiny::textOutput(ns("hdr_selFreq")))),
        #          shiny::textOutput(ns("txt_selFreq")),
        #          shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_selFreq"), height = "700px"))),
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
        tabPanel("Log",
                 value = 8,
                 shiny::span(shiny::h2("Solver Log")),
                 shiny::textOutput(ns("txt_log_hint")),
                 shinycssloaders::withSpinner(
                   shiny::verbatimTextOutput(ns("logText"), placeholder = TRUE)
                 )
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

    # dont make observeEvent because it's a global variable
    if (options$obj_func == "min_shortfall") {
      shinyjs::show(id = "switchMinShortfall")
    } else {
      shinyjs::hide(id = "switchMinShortfall")
    }


    if (isTRUE(options$include_bioregion)) {
      shinyjs::show(id = "switchBioregions")
    }


    # dont make observeEvent because it's a global variable
    if (isTRUE(options$include_climateChange)) {
      shinyjs::show(id = "switchClimSmart")
    } else {
      shinyjs::hide(id = "switchClimSmart")

       # Hide the Climate tab if climate change is not enabled
      shiny::hideTab(inputId = "tabs", target = "6", session = session)
    }

    # dont make observeEvent because it's a global variable
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

    # Track when analysis has been run
    analysisRun <- shiny::reactiveVal(FALSE)
    shiny::observeEvent(input$analyse, {
      analysisRun(TRUE)
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
      if (analysisRun()) {
        solution()  # Trigger the solve
      }

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


    ############## All Plots #########################


    ## Binary Solution Plot ----------------------------------------------------

    observeEvent(
      {
        input$tabs == 1
      },
      {
        # Solution plotting reactive
        plot_data1 <- shiny::reactive({

          # Guard: only attempt to plot if a solution exists
          if (!inherits(solution(), "sf")) {
            return(NULL)
          }

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
          if (analysisRun()) {
            req(inherits(solution(), "sf"))
            plot_data1()
          }
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

      }
    )



    ## Target Plot -------------------------------------------------------------

    observeEvent(
      {
        input$tabs == 2
      },
      {
        gg_Target <- shiny::reactive({

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
          if (analysisRun()) {
            gg_Target()
          }
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
        input$tabs == 3
      },
      {
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


        output$gg_cost <- shiny::renderPlot({
          if (analysisRun()) {
            costPlotData()
          }
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
        input$tabs == 6
      },
      {
        ggr_clim <- shiny::reactive({

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
          if (analysisRun() && input$climateid != "NA") {
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
        input$tabs == 7
      },
      {
        DataTabler <- shiny::reactive({

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
            # gridExtra::tableGrob(SummaryTabler(), rows = NULL, theme = gridExtra::ttheme_default(base_size = 12)),
            gridExtra::tableGrob(dat[[1]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 8)),
            gridExtra::tableGrob(dat[[2]], rows = NULL, theme = gridExtra::ttheme_default(base_size = 8)),
            design = design
          ) &
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           # panel.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the panel background (where the data is plotted) transparent
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                           # legend.box.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the background of the legend box transparent
            )

          return(ggr_DataPlot)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot7 <- fDownloadPlotServer(input, gg_id = DataTabler(), gg_prefix = "DataSummary", time_date = analysisTime(), width = 16, height = 10) # Download figure
      }
    ) # End observe event 7
  })
}

## To be copied in the UI
# mod_2scenario_ui("2scenario_1")

## To be copied in the server
# mod_2scenario_server("2scenario_1")
