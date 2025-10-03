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

  shinyjs::useShinyjs()

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

        # TODO Add a conditional here to account for yes/no bioregions
        shiny::h3(paste0("1.", length(unique(slider_vars$category)) + 1, " Bioregions")),
        fcustom_sliderCategory(slider_varsBioR, labelNum = 1, byCategory = TRUE),

      )),

      shiny::hr(style = "border-top: 1px solid #000000;"),

      shiny::h2("2. Select Cost Layer"),
      create_fancy_dropdown(id, "costid", Dict %>%
                              dplyr::filter(.data$type == "Cost")),

      shinyjs::hidden(div(
        id = ns("switchClimSmart"),
        shiny::h2("3. Climate-smart"),
        shiny::p("Should the spatial plan be made climate-smart?"),
        shiny::p("NOTE: This will slow down the analysis significantly. Be patient."),
        create_fancy_dropdown(id = id,  id_in = "climateid", Dict = Dict %>%
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
      shinyjs::useShinyjs(),
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

    if (isTRUE(options$include_climateChange)) { # dont make observeEvent because it's a global variable

      # browser()
      shinyjs::show(id = "switchClimSmart")
    } else {
      # browser()
      shinyjs::hide(id = "switchClimSmart")
      # Hide the Climate tab if climate change is not enabled
      shiny::hideTab(inputId = "tabs", target = 6, session = session)
    }

    if (isTRUE(options$include_lockedArea)) { # dont make observeEvent because it's a global variable
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
        dplyr::pull(id_in)

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


    # TODO This needs to be made generic.... somehow....
    observeEvent(input$checkLI_aquaculture, {
      shinyjs::toggleState("checkLO_aquaculture")
    }, ignoreInit = TRUE)


    observeEvent(input$checkLO_aquaculture, {
      shinyjs::toggleState("checkLI_aquaculture")
    }, ignoreInit = TRUE)


    # Observe Event for master slider. This updates the individual sliders.
    observeEvent(input$masterSli, {
      inps <- names(input) %>%
        stringr::str_subset("sli_")
      purrr::map(inps, \(x) shiny::updateSliderInput(session = session, inputId = x, value = input$masterSli))
    }, ignoreInit = TRUE)



    # Observe events from individual targets
    # Return targets and names for all features from sliders ---------------------------------------------------
    targetData <- shiny::reactive({
      targets <- fget_targets(input, dataType = "Feature")
      # targets <- fget_targets(input, dataType = c("Feature", "Bioregion"))

      # This is where I need to add something about bioregions
      # TODO This needs to be moved into a function and possible merged with fget_targets

      # Now find the Bioregions features
      name_check = "master_sli_"

      # Get the features
      ft <- Dict %>%
        dplyr::filter(.data$type %in% "Bioregion") %>%
        dplyr::select(feature = "nameVariable", "categoryID")

      cats <- ft %>%
        dplyr::pull("categoryID") %>%
        unique()

      targets2 <- cats %>%
        purrr::map(\(x) rlang::eval_tidy(rlang::parse_expr(paste0("input$", paste0(name_check, x))))) %>%
        tibble::enframe() %>%
        tidyr::unnest(cols = .data$value) %>%
        dplyr::rename(categoryID = "name", target = "value") %>%
        dplyr::mutate(categoryID = cats) %>%
        dplyr::mutate(target = .data$target / 100) %>% # requires number between 0-1
        dplyr::left_join(ft, ., by = "categoryID") %>%
        dplyr::select(-"categoryID")

      targets = dplyr::bind_rows(targets, targets2)



      return(targets)
    })



    p1Data <- shiny::reactive({
      p1 <- fdefine_problem(targetData(), raw_sf, options, input, clim_input = input$climateid)
      return(p1)
    })


    # Solve the problem -------------------------------------------------------
    selectedData <- shiny::reactive({

      result <- tryCatch({

        sD <- solve(p1Data(), run_checks = FALSE) %>%
          sf::st_as_sf()

      }, error = function(err) {

        shinyalert::shinyalert("Error", "Can't find a solution! This is because it is impossible to meet the currently selected targets, budgets, or constraints. Try decreasing the targets or removing locked-out areas.",
                               type = "error",
                               callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
        )

      })

    }) %>% shiny::bindEvent(input$analyse)


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

          # TODO Add better error tracking in here so I can change soln_text to provide a useful error when a solution can't be found.

          LI <- get_lockIn(input)
          LO <- get_lockOut(input)

          plot1 <- spatialplanr::splnr_plot_solution(
            soln = selectedData(),
            plotTitle = ""
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData(),
              ggtheme = map_theme
            )

          if (length(LI) > 0){
            plot1 <- plot1 +
              spatialplanr::splnr_gg_add(
                lockIn = raw_sf,
                nameLockIn = LI,
                legendLockIn = "Locked In Areas",
                ggtheme = FALSE
              )
          }

          if (length(LO) > 0) {
            plot1 <- plot1 +
              spatialplanr::splnr_gg_add(
                lockOut = raw_sf,
                nameLockOut = LO,
                legendLockOut = "Locked Out Areas",
                ggtheme = FALSE
              )
          }

          plot1 <- plot1 +
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                           legend.position = "bottom", legend.direction = "horizontal",
                           legend.box = "horizontal")
          # + ggplot2::guides(fill = ggplot2::guide_legend(nrow = 1, byrow = TRUE))

          plot1 <- plot1

          return(plot1)
        })

        output$gg_soln <- shiny::renderPlot({
          if (analysisRun()) {
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
          soln_text <- fSolnText(input, selectedData(), input$costid)
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

          if (input$climateid == "NA"){
            targetPlotData <- spatialplanr::splnr_get_featureRep(
              soln = selectedData(),
              pDat = p1Data(),
              climsmart = FALSE
            )

          } else {

            targets <- targetData()
            targetPlotData <- spatialplanr::splnr_get_featureRep(
              soln = selectedData(),
              pDat = p1Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targets
            )
          }

          # TODO splnr_get_featureRep needs a rewrite. Now that we don't always use
          # "Cost_" as a cost, we need to work out a better way (The Dict) to remove
          # columns that are not features. The code below is just a workaround.

          targetPlotData <- targetPlotData %>%
            dplyr::filter(feature %in% (Dict %>%
                                          dplyr::filter(type == "Feature") %>%
                                          dplyr::pull(nameVariable)))

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
          shiny::bindCache(input$analyse, input$checkSort) # TODO Check all caching and ensure I am caching correctly. E.g. the plot or the reactive or both?


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
          spatialplanr::splnr_plot_costOverlay(soln = selectedData(),
                                               cost = NA,
                                               costName = input$costid,
                                               legendTitle = "Cost",
                                               plotTitle = "Solution overlaid with cost"
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData(),
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

    ## Climate Resilience Plot -------------------------------------------------


    observeEvent(
      {
        input$tabs == 6
      },
      {
        ggr_clim <- shiny::reactive({

          ggClimDens <- spatialplanr::splnr_plot_climKernelDensity(
            soln = list(selectedData()),
            solution_names = "solution_1",
            climate_names = input$climateid,
            type = "Normal",
            legendTitle = "Climate resilience metric",
            xAxisLab = "Climate resilience metric"
          ) +
            ggplot2::theme(plot.background = ggplot2::element_rect(fill = "transparent", colour = NA),
                           # panel.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the panel background (where the data is plotted) transparent
                           legend.background = ggplot2::element_rect(fill = "transparent", colour = NA), # Makes the legend background transparent
                           # legend.box.background = ggplot2::element_rect(fill = "transparent", colour = NA) # Makes the background of the legend box transparent
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
          if (input$climateid != "NA") {
            targets <- targetData()

            targetPlotData <- spatialplanr::splnr_get_featureRep(
              soln = selectedData(),
              pDat = p1Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targets
            )
          } else {
            targetPlotData <- spatialplanr::splnr_get_featureRep(
              soln = selectedData(),
              pDat = p1Data(),
              climsmart = FALSE
            )
          }

          # TODO Remove this when we fix spatialplanr as above
          targetPlotData <- targetPlotData %>%
            dplyr::filter(feature %in% (Dict %>% dplyr::filter(type == "Feature") %>% dplyr::pull(nameVariable)))

          # TODO I think I can clean up this code and make it into a function
          # Create named vector to do the replacement
          rpl <- Dict %>%
            dplyr::filter(.data$nameVariable %in% targetPlotData$feature) %>%
            dplyr::select("nameVariable", "nameCommon") %>%
            dplyr::mutate(nameVariable = stringr::str_c("^", nameVariable, "$")) %>%
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
