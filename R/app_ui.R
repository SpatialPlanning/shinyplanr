#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  shiny::navbarPage(
    id = "navbar",
    title = shiny::a(shiny::img(src = "www/logo.png",
                                height = 40,
                                class = "navbar-logo"),
                     options$nav_title
    ),
    header = shiny::tagList(
      golem_add_external_resources(), # fn() for adding external resources
      shinyjs::useShinyjs()
    ),
    theme = bslib::bs_theme(version = 5), # Theme handled by custom.css
    selected = "Welcome",
    if (options$mod_1welcome == TRUE) {
      shiny::tabPanel(
        "Welcome",
        shiny::fluidPage(
          value = "welcome", mod_1welcome_ui("1welcome_ui_1")
        )
      )
    },
    shiny::tabPanel(
      "Scenario",
      shiny::fluidPage(
        # shiny::actionButton("sidebar_button","Settings",icon = icon("bars")),
        value = "soln", mod_2scenario_ui("2scenario_ui_1")
      )
    ),
    if (options$mod_3compare == TRUE) {
      shiny::tabPanel(
        "Comparison",
        shiny::fluidPage(
          value = "compare", mod_3compare_ui("3compare_ui_1")
        )
      )
    },
    if (options$mod_4features == TRUE) {
      shiny::tabPanel(
        "Layer Information",
        shiny::fluidPage(
          value = "features", mod_4features_ui("4features_ui_1")
        )
      )
    },
    if (options$mod_5coverage == TRUE) {
      shiny::tabPanel(
        "Check Coverage",
        shiny::fluidPage(
          value = "coverage", mod_5coverage_ui("5coverage_1")
        )
      )
    },
    if (options$mod_6help == TRUE) {
      shiny::tabPanel(
        "Help",
        shiny::fluidPage(
          value = "help", mod_6help_ui("6help_ui_1")
        )
      )
    },
  )

}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(ext = "png"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = options$app_title
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
