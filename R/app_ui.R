#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  shiny::navbarPage(
    shinyjs::useShinyjs(),

    # Leave this function for adding external resources
    golem_add_external_resources(),

    title = shiny::a(shiny::img(src = "www/logo.png",
                                height = 40,
                                class = "navbar-logo"),
                     options$nav_title
    ),
    id = "navbar",

    # Theme completely handled by inst/app/www/custom.css
    theme = bslib::bs_theme(version = 5),
    selected = "Scenario",
    shiny::tabPanel(
      "Welcome",
      shiny::fluidPage(
        value = "welcome", mod_1welcome_ui("1welcome_ui_1")
      )
    ),
    shiny::tabPanel(
      "Scenario",
      shiny::fluidPage(
        # shiny::actionButton("sidebar_button","Settings",icon = icon("bars")),
        value = "soln", mod_2scenario_ui("2scenario_ui_1")
      )
    ),
    shiny::tabPanel(
      "Comparison", # maybe make this optional?
      shiny::fluidPage(
        value = "compare", mod_3compare_ui("3compare_ui_1")
      )
    ),
    shiny::tabPanel(
      "Layer Information",
      shiny::fluidPage(
        value = "features", mod_4features_ui("4features_ui_1")
      )
    ),
    shiny::tabPanel(
      "Help",
      shiny::fluidPage(
        value = "help", mod_6help_ui("6help_ui_1")
      )
    ),
    shiny::tabPanel(title = HTML("<li><a href='https://www.waittinstitute.org'target='_blank'>Waitt Institute")),
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
      app_title = "shinyplanr"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
