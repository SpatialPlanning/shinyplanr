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
  Vars <- fcreate_vars(id = id, Dict = Dict, name_check = "sli_", categoryOut = TRUE)
  Vars2 <- fcreate_vars(id = id, Dict = Dict, name_check = "sli2_", categoryOut = TRUE)

  check_lockIn <- fcreate_check(id = id,
                                Dict = Dict,
                                idType = "LockIn",
                                name_check = "checkLI_",
                                categoryOut = TRUE)

  check_lockIn2 <- fcreate_check(id = id,
                                 Dict = Dict,
                                 idType = "LockIn",
                                 name_check = "check2LI_",
                                 categoryOut = TRUE)

  shinyjs::useShinyjs()

  # tagList(
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      width = 4,
      shiny::p(shiny::HTML("<strong>To Run Comparison:</strong> Select the features you want to compare
                                                and click 'Run Analysis'. For a detailed display of the spatial plans,
                                                targets and costs of the two analyses, navigate through the additional tabs.")),
      shiny::hr(style = "border-top: 1px solid #000000;"),
      shiny::splitLayout(
        shiny::h2("Input 1", style = "width: 100%; text-align:center; display: block"),
        shiny::h2("Input 2", style = "width: 100%; text-align:center; display: block"),
      ),
      shiny::h2("1. Select Targets"),
      shiny::actionButton(ns("resetFeat"), "Reset All Features",
                          width = "100%", class = "btn btn-outline-primary",
                          style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
      ),
      shiny::splitLayout(
        fcustom_sliderCategory(Vars, labelNum = 1),
        fcustom_sliderCategory(Vars2, labelNum = 1)
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

      shinyjs::hidden(div(
        id = ns("switchConstraints"),
        shiny::h2("3. Constraints"),
        shiny::splitLayout(
          fcustom_checkCategory(check_lockIn, labelNum = 3),
          fcustom_checkCategory(check_lockIn2, labelNum = 3)
        ),

        # shiny::checkboxInput(ns("checkClimsmart"), "Make Climate-resilient", FALSE)
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
      shinyjs::useShinyjs(),
      tabsetPanel(
        id = ns("tabs"), # type = "pills",
        tabPanel("Comparison",
                 value = 1,
                 shiny::fixedPanel(
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot1"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
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
                   style = "z-index:100", # To force the button above all plots.=
                   shiny::downloadButton(ns("dlPlot2"), "Download Plot",
                                         style = "float: right; padding:4px; font-size:120%"
                   ),
                   right = "1%", bottom = "1%", left = "34%"
                 ),
                 shiny::fluidRow(
                   shiny::span(shiny::h2(shiny::textOutput(ns("hdr_soln")))),
                   shiny::span(shiny::p(shiny::textOutput(ns("txt_soln")))),
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
                 shinycssloaders::withSpinner(shiny::plotOutput(ns("gg_target"), height = "700px")),
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
      )
    )
  )
  # ) # tagList
}

#' 3compare Server Functions
#'
#' @noRd
mod_3compare_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    if (options$climate_change != 0) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchClimSmart")
    }

    if (options$lockedInArea != 0) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchConstraints")
    }

    observeEvent(input$disconnect, {
      session$close()
    })

    shiny::observeEvent(input$resetFeat,
                        {fResetFeat(session, input, output, id = 1)
                        },ignoreInit = TRUE
    )

    shiny::observeEvent(input$resetFeat,
                        {fResetFeat(session, input, output, id = 2)
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

    # Get Target Data
    targetData1 <- shiny::reactive({
      targets <- fget_targets(input)
      return(targets)
    })

    targetData2 <- shiny::reactive({
      targets <- fget_targets(input, name_check = "sli2_")
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

    # Solve the problem -------------------------------------------------------
    selectedData1 <- shiny::reactive({
      selectedData1 <- solve(p1Data(), run_checks = FALSE) %>%
        sf::st_as_sf()
      return(selectedData1)
    }) %>% shiny::bindEvent(input$analyse)

    selectedData2 <- shiny::reactive({
      selectedData2 <- solve(p2Data(), run_checks = FALSE) %>%
        sf::st_as_sf()
      return(selectedData2)
    }) %>% shiny::bindEvent(input$analyse)


    #### Comparison Plot ####
    observeEvent(
      {
        input$tabsComp == 1
      },
      {
        ggr_comp <- shiny::reactive({
          area1 <- selectedData1() %>%
            dplyr::filter(.data$solution_1 == 1) %>%
            nrow()
          area2 <- selectedData2() %>%
            dplyr::filter(.data$solution_1 == 1) %>%
            nrow()

          area_change1 <- round(((area2 - area1) / nrow(selectedData1())) * 100) # As
          area_change2 <- round(((area2 - area1) / area1) * 100)

          if (area_change1 > 0) {
            txt_comb <- paste0("Area 2 is ", area_change2, "% larger than Area 1\nand contains ", area_change1, "% more of the\nplanning region")
          } else if (area_change1 < 0) {
            txt_comb <- paste0("Area 2 is ", abs(area_change2), "% smaller than Area 1\nand contains ", abs(area_change1), "% less of the\nplanning region")
          } else if (area_change1 == 0) {
            txt_comb <- paste0("Area 1 and Area 2 are the same size.")
          }

          ggr_comp <- spatialplanr::splnr_plot_comparison(selectedData1(), selectedData2()) +
            ggplot2::annotate(
              geom = "label", label = txt_comb, x = Inf, y = Inf, fill = "NA",
              hjust = 1.0, vjust = 1,
              size = 6, label.size = 0,
              label.padding = ggplot2::unit(0.2, "lines")
            ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData1(),
              ggtheme = map_theme
            )

          return(ggr_comp)
        })

        output$gg_comp <- shiny::renderPlot({
          ggr_comp()
        })

        output$dlPlot1 <- fDownloadPlotServer(input, gg_id = ggr_comp(), gg_prefix = "Compare", time_date = analysisTime()) # Download figure

      }
    ) # end observeEvent 1

    #### Binary Solution Plot ####

    observeEvent(
      {
        input$tabs == 2
      },
      {
        # Solution plotting reactive
        ggr_soln <- shiny::reactive({

          ## PLOT 1

          soln_text1 <- fSolnText(input, selectedData1(), input$costid1)

          plot_soln1 <- spatialplanr::splnr_plot_solution(
            soln = selectedData1(),
            plotTitle = "Planning Units"
          ) +
            ggplot2::annotate(geom = "text", label = soln_text1[[1]], x = Inf, y = Inf, hjust = 1.05, vjust = 1.5) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData1(),
              ggtheme = map_theme
            )

          if (input$costid1 != "Cost_None") {
            plot_soln1 <- plot_soln1 +
              ggplot2::annotate(geom = "text", label = soln_text1[[2]], x = Inf, y = Inf, hjust = 1.03, vjust = 3.5)
          }

          ## PLOT 2

          soln_text2 <- fSolnText(input, selectedData2(), input$costid2)

          plot_soln2 <- spatialplanr::splnr_plot_solution(
            soln = selectedData2(),
            plotTitle = "Planning Units"
          ) +
            ggplot2::annotate(geom = "text", label = soln_text2[[1]], x = Inf, y = Inf, hjust = 1.05, vjust = 1.5) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData2(),
              ggtheme = map_theme
            )

          if (input$costid2 != "Cost_None") {
            plot_soln2 <- plot_soln2 +
              ggplot2::annotate(geom = "text", label = soln_text2[[2]], x = Inf, y = Inf, hjust = 1.03, vjust = 3.5)
          }


          ## COMBINE PLOTS

          ggr_soln <- patchwork::wrap_plots(plot_soln1 + ggplot2::ggtitle("Input 1"),
                                            plot_soln2 + ggplot2::ggtitle("Input 2"),
                                            nrow = 1, guides = "collect"
          ) &
            ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

          return(ggr_soln)

        })

        output$gg_soln <- shiny::renderPlot({
          ggr_soln()
        }) %>%
          shiny::bindEvent(input$analyse)

        hdrr_soln <- shiny::reactive({
          txt_out <- "Your Scenario"
          return(txt_out)
        })

        output$hdr_soln <- shiny::renderText({
          hdrr_soln()
        }) %>%
          shiny::bindEvent(input$analyse)

        output$txt_soln <- shiny::renderText({
          paste(
            "This plot shows the optimal planning scenario for the study area
              that meets the selected targets for the chosen features whilst
              minimising the cost. The categorical map displays, which of
              the planning units were selected as important for meeting
              the conservation targets (dark blue) and which were not selected (light blue)
              either due to not being in an area prioritized for the selected features or
              because they are within areas valuable and accessible for other uses."
          )
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot2 <- fDownloadPlotServer(input, gg_id = ggr_soln(), gg_prefix = "Solution", time_date = analysisTime()) # Download figure

      }
    ) # end observeEvent 2

    ## Target Plot -------------------------------------------------------------


    observeEvent(
      {
        input$tabs == 3
      },
      {
        ggr_target <- shiny::reactive({

          ## DATA FOR PLOT 1
          if (input$climateid1 != "NA") {

            targetPlotData1 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData1(),
              pDat = p1Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targetData1()
            )
          } else {
            targetPlotData1 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData1(),
              pDat = p1Data(),
              climsmart = FALSE
            )
          }

          ## DATA FOR PLOT 2

          if (input$climateid2 != "NA") {

            targetPlotData2 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData2(),
              pDat = p2Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targetData2()
            )
          } else {
            targetPlotData2 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData2(),
              pDat = p2Data(),
              climsmart = FALSE
            )
          }


          ggr_target <- patchwork::wrap_plots(

            spatialplanr::splnr_plot_featureRep(targetPlotData1,
                                                nr = 2,
                                                showTarget = TRUE,
                                                category = fget_category(Dict = Dict),
                                                renameFeatures = TRUE,
                                                namesToReplace = Dict) +
              ggplot2::ggtitle("Input 1"),

            spatialplanr::splnr_plot_featureRep(targetPlotData2,
                                                nr = 2,
                                                showTarget = TRUE,
                                                category = fget_category(Dict = Dict),
                                                renameFeatures = TRUE,
                                                namesToReplace = Dict) +
              ggplot2::ggtitle("Input 2"),
            nrow = 1, guides = "collect") &
            ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

          return(ggr_target)

        }) %>%
          shiny::bindEvent(input$analyse)


        output$gg_target <- shiny::renderPlot({
          ggr_target()
        }) %>%
          shiny::bindEvent(input$analyse)

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
        input$tabs == 4
      },
      {
        ggr_cost <- shiny::reactive({

          gg_cost1 <- spatialplanr::splnr_plot_costOverlay(selectedData1(),
                                                           Cost = NA,
                                                           Cost_name = input$costid1,
                                                           legendTitle = "Cost",
                                                           plotTitle = "Solution overlaid with cost"
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData1(),
              ggtheme = map_theme
            )


          gg_cost2 <- spatialplanr::splnr_plot_costOverlay(selectedData2(),
                                                           Cost = NA,
                                                           Cost_name = input$costid2,
                                                           legendTitle = "Cost",
                                                           plotTitle = "Solution overlaid with cost"
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData2(),
              ggtheme = map_theme
            )


          ggr_cost <- patchwork::wrap_plots(gg_cost1 + ggplot2::ggtitle("Input 1"),
                                            gg_cost2 + ggplot2::ggtitle("Input 2"),
                                            nrow = 1, guides = "collect"
          ) &
            ggplot2::theme(legend.position = "bottom", legend.direction = "horizontal")

          return(ggr_cost)
        })


        output$gg_cost <- shiny::renderPlot({
          ggr_cost()
        }) %>%
          shiny::bindEvent(input$analyse)

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
            stringr::str_remove(cost_txt1$justification, "This cost"), ". The cost on the right is ",
            cost_txt2$nameCommon, " and ", stringr::str_remove(cost_txt2$justification, "This cost"), "."
          )
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot4 <- fDownloadPlotServer(input, gg_id = ggr_cost(), gg_prefix = "Cost", time_date = analysisTime()) # Download figure
      }
    ) # end observeEvent 4

    ## Climate Resilience Plot -------------------------------------------------

    observeEvent(
      {
        input$tabs == 7
      },
      {
        ggr_clim <- shiny::reactive({
          if (!"metric" %in% colnames(selectedData1())) { # just if one of the inputs does not have climate smart selected
            selectedData1 <- selectedData1() %>%
              dplyr::mutate(metric = climate_sf$metric)
          } else {
            selectedData1 <- selectedData1()
          }

          if (!"metric" %in% colnames(selectedData2())) {
            selectedData2 <- selectedData2() %>%
              dplyr::mutate(metric = climate_sf$metric)
          } else {
            selectedData2 <- selectedData2()
          }

          ggClimDens <- spatialplanr::splnr_plot_climKernelDensity(
            soln = list(selectedData1, selectedData2),
            names = c("Input 1", "Input 2"), type = "Normal",
            legendTitle = "Climate resilience metric (add unit)",
            xAxisLab = "Climate resilience metric"
          )
          return(ggClimDens)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$gg_clim <- shiny::renderPlot({
          if (input$climateid1 != "NA" | input$climateid2 != "NA") { # could also only generate one plot when only one of them is climate smart. Or always generate these plots when climate smart option is wanted in general.
            ggr_clim()
          }
        }) %>%
          shiny::bindEvent(input$analyse)

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
        input$tabs == 8
      },
      {
        # for saving data/ data next to plot
        DataTabler <- shiny::reactive({
          if (input$climateid1 != "NA") {
            targets <- targetData1()

            targetPlotData1 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData1(),
              pDat = p1Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targets
            ) %>% # TODO Move this mutate to spatialplanr to account for zeros
              dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))
          } else {
            targetPlotData1 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData1(),
              pDat = p1Data(),
              climsmart = FALSE
            ) %>%
              dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))
          }

          if (input$climateid2 == TRUE) {
            targets <- targetData2()

            targetPlotData2 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData2(),
              pDat = p2Data(),
              climsmart = TRUE,
              climsmartApproach = options$climate_change,
              targets = targets
            ) %>%
              dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))
          } else {
            targetPlotData2 <- spatialplanr::splnr_get_featureRep(
              soln = selectedData2(),
              pDat = p2Data(),
              climsmart = FALSE
            ) %>%
              dplyr::mutate(incidental = dplyr::if_else(.data$target == 0, TRUE, .data$incidental))
          }

          # Create named vector to do the replacement
          rpl <- Dict %>%
            dplyr::filter(.data$nameVariable %in% unique(c(targetPlotData1$feature, targetPlotData2$feature))) %>%
            dplyr::select("nameVariable", "nameCommon") %>%
            dplyr::mutate(nameVariable = stringr::str_c("^", nameVariable, "$")) %>%
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
          )

          return(ggr_DataPlot)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$dlPlot8 <- fDownloadPlotServer(input, gg_id = DataTabler(), gg_prefix = "DataSummary", time_date = analysisTime(), width = 16, height = 10) # Download figure
      }
    ) # End observe event 8
  })
}

## To be copied in the UI
# mod_3compare_ui("3compare_ui_1")

## To be copied in the server
# mod_3compare_server("3compare_1")
