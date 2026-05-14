#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  cfg     <- get_pkg_config()
  options <- cfg$options

  shiny::navbarPage(
    id = "navbar",
    title = shiny::a(shiny::img(src = "www/logo.png",
                                height = 40,
                                class = "navbar-logo"),
                     options$nav_title
    ),
    header = shiny::tagList(
      golem_add_external_resources(options), # fn() for adding external resources
      shinyjs::useShinyjs()
    ),
    theme = bslib::bs_theme(version = 5), # Theme handled by custom.css
    selected = "Welcome",
    if (options$mod_1welcome == TRUE) {
      shiny::tabPanel(
        "Welcome",
        shiny::fluidPage(
          value = "welcome", mod_1welcome_ui("1welcome_ui_1", cfg)
        )
      )
    },
    shiny::tabPanel(
      "Scenario",
      shiny::fluidPage(
        # shiny::actionButton("sidebar_button","Settings",icon = icon("bars")),
        value = "soln", mod_2scenario_ui("2scenario_ui_1", cfg)
      )
    ),
    # shiny::tabPanel(
    #   "Multi-Objective Optimisation",
    #   shiny::fluidPage(
    #     value = "moo", mod_7multiobj_ui("7multiobj_ui_1", cfg)
    #   )
    # ),
    if (options$mod_3compare == TRUE) {
      shiny::tabPanel(
        "Comparison",
        shiny::fluidPage(
          value = "compare", mod_3compare_ui("3compare_ui_1", cfg)
        )
      )
    },
    if (options$mod_4features == TRUE) {
      shiny::tabPanel(
        "Layer Information",
        shiny::fluidPage(
          value = "features", mod_4features_ui("4features_ui_1", cfg)
        )
      )
    },
    if (options$mod_5coverage == TRUE) {
      shiny::tabPanel(
        "Check Coverage",
        shiny::fluidPage(
          value = "coverage", mod_5coverage_ui("5coverage_ui_1", cfg)
        )
      )
    },
    if (options$mod_6help == TRUE) {
      shiny::tabPanel(
        "Help",
        shiny::fluidPage(
          value = "help", mod_6help_ui("6help_ui_1", cfg)
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
golem_add_external_resources <- function(options) {
  # Register package's built-in www/ (CSS, JS, default logos, favicon)
  add_resource_path("www", app_sys("app/www"))

  # If running from a deployment project, register the deployment www/ at the
  # SAME prefix. Shiny's addResourcePath() replaces the previous registration,
  # so deployment logos (logo.png, logo2.png, etc.) will override the package
  # defaults. All required files (uq-logo-white.png, etc.) are copied to the
  # deployment www/ by setup-app.R.
  if (dir.exists("www")) {
    shiny::addResourcePath("www", normalizePath("www", mustWork = FALSE))
  }

  tags$head(
    favicon(ext = "png"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = options$app_title
    ),
    # Deployer CSS override: if the deployment project contains www/custom.css,
    # it is loaded AFTER the package CSS so that :root variable overrides win.
    # Create setup/content/custom.css and re-run setup-app.R to use this.
    if (file.exists("www/custom.css")) {
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    }
  )
}
