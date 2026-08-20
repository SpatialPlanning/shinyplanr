#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  cfg <- get_pkg_config()
  options <- cfg$options


  # Initialise each module server exactly once, the first time its tab is visited.
  # The event expression is the specific tab condition — observeEvent fires only when
  # that expression becomes TRUE. once = TRUE ensures moduleServer() is never called
  # more than once per module, preventing duplicate observers and memory leaks.

  if (isTRUE(options$mod_1welcome)) {
    shiny::observeEvent(
      input$navbar == "Welcome",
      mod_1welcome_server("1welcome_ui_1", cfg),
      once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
    )
  }

  shiny::observeEvent(
    input$navbar == "Scenario",
    {
      # tab_visible is a reactive that is TRUE whenever the Scenario navbar tab
      # is active.  Passed into the module so it can re-add the WebGL layer on
      # the Explore sub-tab whenever the user returns to the Scenario tab after
      # visiting another top-level tab (input$navbar is not accessible inside
      # moduleServer — it belongs to the parent session).
      tab_visible_2 <- shiny::reactive(input$navbar == "Scenario")
      mod_2scenario_server("2scenario_ui_1", cfg, tab_visible = tab_visible_2)
    },
    once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
  )

  if (isTRUE(options$mod_3compare)) {
    shiny::observeEvent(
      input$navbar == "Comparison",
      mod_3compare_server("3compare_ui_1", cfg),
      once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
    )
  }

  if (isTRUE(options$mod_4features) || isTRUE(options$mod_4features_interactive)) {
    shiny::observeEvent(
      input$navbar == "Layer Information",
      if (isTRUE(options$mod_4features_interactive)) {
        # tab_visible is a reactive that is TRUE whenever the Layer Information
        # tab is the active navbar tab.  It is passed into the module so the
        # module can re-add the WebGL layer on every tab visit without needing
        # access to input$navbar (which belongs to the parent session and is
        # not accessible inside moduleServer).
        tab_visible_4a <- shiny::reactive(input$navbar == "Layer Information")
        mod_4afeatures_server("4afeatures_ui_1", cfg, tab_visible = tab_visible_4a)
      } else {
        mod_4features_server("4features_ui_1", cfg)
      },
      once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
    )
  }

  if (isTRUE(options$mod_5coverage)) {
    shiny::observeEvent(
      input$navbar == "Check Coverage",
      mod_5coverage_server("5coverage_ui_1", cfg),
      once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
    )
  }

  if (isTRUE(options$mod_6help)) {
    shiny::observeEvent(
      input$navbar == "Help",
      mod_6help_server("6help_ui_1", cfg),
      once = TRUE, ignoreInit = FALSE, ignoreNULL = TRUE
    )
  }
}
