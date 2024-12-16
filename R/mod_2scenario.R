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

  # TODO I want to use this in the server as well. Not sure how to pass between the two.
  slider_vars <- fcreate_vars(id = id,
                              Dict = Dict %>%
                                dplyr::filter(.data$type == "Feature"),
                              name_check = "sli_",
                              categoryOut = TRUE)

  check_constraints <- fcreate_check(id = id,
                                     Dict = Dict %>%
                                       dplyr::filter(.data$type == "Constraint"),
                                     name_check = "checkLI_",
                                     categoryOut = TRUE)

  shinyjs::useShinyjs()

  # shiny::tagList(
  # shiny::fluidPage(
  # actionLink("sidebar_button","",icon = icon("bars")
  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::h2("1. Select Targets"),
      shiny::actionButton(ns("resetFeat"), "Reset All Features",
                          width = "100%", class = "btn btn-outline-primary",
                          style = "display: block; margin-left: auto; margin-right: auto; padding:4px; font-size:120%"
      ),
      fcustom_sliderCategory(slider_vars, labelNum = 1),
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
        shiny::h2("3. Constraints"),
        shiny::p("You can also lock-in some pre-defined areas to ensure they are protected. Planning Units outside these areas will also be selected if needed to meet the targets."),
        fcustom_checkCategory(check_constraints, labelNum = 3),
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
        id = ns("tabs"), # type = "pills",
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
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_DetsSummary")))),
                 shiny::br(),
                 shiny::tableOutput(ns("SummaryTable")),
                 shiny::span(shiny::h2(shiny::textOutput(ns("hdr_DetsData")))),
                 shiny::tableOutput(ns("DataTable"))
        ),
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

    if (options$climate_change != 0) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchClimSmart")
    }

    if (options$lockedInArea != 0) { # dont make observeEvent because it's a global variable
      shinyjs::show(id = "switchConstraints")
    }

    observeEvent(input$disconnect, {
      session$close()
    })

    # # Go back to the first tab when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shiny::updateTabsetPanel(session, "tabs", selected = 1)
    })

    # Go back to the top of the page when analyse is clicked.
    shiny::observeEvent(input$analyse, {
      shinyjs::runjs("window.scrollTo(0, 0)")
    })

    # Reset values
    # shiny::observeEvent(input$reset,
    #                     {fResetInputs(session, input, output)},
    #                     ignoreInit = TRUE
    # )

    # Reset Features
    shiny::observeEvent(input$resetFeat,
                        {fResetFeat(session, input, output)
                        },ignoreInit = TRUE
    )


    # Return targets and names for all features from sliders ---------------------------------------------------
    targetData <- shiny::reactive({
      targets <- fget_targets(input)
      return(targets)
    })



    p1Data <- shiny::reactive({
      p1 <- fdefine_problem(targetData(), input, clim_input = input$climateid)
      return(p1)
    })


    # Solve the problem -------------------------------------------------------
    selectedData <- shiny::reactive({
      selectedData <- solve(p1Data(), run_checks = FALSE) %>%
        sf::st_as_sf()
      return(selectedData)
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
          soln_text <- fSolnText(input, selectedData(), input$costid)

          plot1 <- spatialplanr::splnr_plot_solution(
            soln = selectedData(),
            plotTitle = "Planning Units"
          ) +
            ggplot2::annotate(
              geom = "text",
              label = soln_text[[1]], x = Inf, y = Inf,
              hjust = 1.05, vjust = 1.5) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData(),
              ggtheme = map_theme
            )

          if (input$costid != "Cost_None") {
            plot1 <- plot1 +
              ggplot2::annotate(
                geom = "text",
                label = soln_text[[2]], x = Inf, y = Inf,
                hjust = 1.03, vjust = 3.5)
          } else {
            plot1 <- plot1
          }
          return(plot1)
        })

        output$gg_soln <- shiny::renderPlot({
          plot_data1()
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
            tx_2solution,
            " For the chosen inputs ",
            round(sum(selectedData()$solution_1) / nrow(selectedData()) * 100),
            "% of the planning region was selected."
          )
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

          gg_Target <- spatialplanr::splnr_plot_featureRep(targetPlotData,
                                                           category = fget_category(Dict = Dict),
                                                           renameFeatures = TRUE,
                                                           namesToReplace = Dict,
                                                           nr = 2,
                                                           showTarget = TRUE,
          )

          return(gg_Target)
        }) %>%
          shiny::bindEvent(input$analyse)


        output$gg_targetPlot <- shiny::renderPlot({
          gg_Target()
        }) %>%
          shiny::bindEvent(input$analyse)

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
          spatialplanr::splnr_plot_costOverlay(selectedData(),
                                               Cost = NA,
                                               Cost_name = input$costid,
                                               legendTitle = "Cost",
                                               plotTitle = "Solution overlaid with cost"
          ) +
            spatialplanr::splnr_gg_add(
              Bndry = bndry,
              overlay = overlay,
              cropOverlay = selectedData(),
              ggtheme = map_theme
            )
        }) %>%
          shiny::bindEvent(input$analyse)


        output$gg_cost <- shiny::renderPlot({
          costPlotData()
        }) %>%
          shiny::bindEvent(input$analyse)

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
            names = c("Input 1"), type = "Normal",
            legendTitle = "Climate resilience metric",
            xAxisLab = "Climate resilience metric"
          )

          return(ggClimDens)
        }) %>%
          shiny::bindEvent(input$analyse)

        output$gg_clim <- shiny::renderPlot({
          if (input$climateid != "NA") {
            ggr_clim()
          }
        }) %>%
          shiny::bindEvent(input$analyse)

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

            browser()

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
