#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  cfg     <- get_pkg_config()
  options <- cfg$options

  observeEvent(input$sidebar_button,{
    shinyjs::toggle(selector = ".tab-pane.active div:has(> [role='complementary'])")

    js_maintab <- paste0('$(".tab-pane.active div[role=',"'main'",']")')

    shinyjs::runjs(paste0('
          width_percent = parseFloat(',js_maintab,'.css("width")) / parseFloat(',js_maintab,'.parent().css("width"));
          if (width_percent == 1){
            ',js_maintab,'.css("width","");
          } else {
            ',js_maintab,'.css("width","100%");
          }
          '))
  })


  shiny::observe({
    # Only initialize server modules for enabled tabs when they are accessed
    if (options$mod_1welcome == TRUE && shiny::req(input$navbar) == "Welcome") {
      mod_1welcome_server("1welcome_ui_1", cfg)
    }

    if (shiny::req(input$navbar) == "Scenario") {
      mod_2scenario_server("2scenario_ui_1", cfg)
    }

    if (shiny::req(input$navbar) == "Multi-Objective Optimisation") {
      mod_7multiobj_server("7multiobj_ui_1", cfg)
    }

    if (options$mod_3compare == TRUE && shiny::req(input$navbar) == "Comparison") {
      mod_3compare_server("3compare_ui_1", cfg)
    }

    if (options$mod_4features == TRUE && shiny::req(input$navbar) == "Layer Information") {
      mod_4features_server("4features_ui_1", cfg)
    }

    if (options$mod_5coverage == TRUE && shiny::req(input$navbar) == "Check Coverage") {
      mod_5coverage_server("5coverage_ui_1", cfg)
    }

    if (options$mod_6help == TRUE && shiny::req(input$navbar) == "Help") {
      mod_6help_server("6help_ui_1", cfg)
    }

  })
}
