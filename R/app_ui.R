#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_ui <- function(request) {
  cfg <- get_pkg_config()
  options <- cfg$options

  # Build the tab list programmatically so that disabled optional tabs produce
  # no NULL entries in navbarPage() (which Shiny silently drops but can cause
  # layout issues and confuses the `selected` logic).
  tabs <- list()

  if (isTRUE(options$mod_1welcome)) {
    tabs[["Welcome"]] <- shiny::tabPanel(
      "Welcome",
      shiny::fluidPage(
        value = "welcome", mod_1welcome_ui("1welcome_ui_1", cfg)
      )
    )
  }

  tabs[["Scenario"]] <- shiny::tabPanel(
    "Scenario",
    shiny::fluidPage(
      value = "soln", mod_2scenario_ui("2scenario_ui_1", cfg)
    )
  )

  if (isTRUE(options$mod_3compare)) {
    tabs[["Comparison"]] <- shiny::tabPanel(
      "Comparison",
      shiny::fluidPage(
        value = "compare", mod_3compare_ui("3compare_ui_1", cfg)
      )
    )
  }

  if (isTRUE(options$mod_4features) || isTRUE(options$mod_4features_interactive)) {
    tabs[["Layer Information"]] <- shiny::tabPanel(
      "Layer Information",
      shiny::fluidPage(
        value = "features",
        if (isTRUE(options$mod_4features_interactive)) {
          mod_4afeatures_ui("4afeatures_ui_1", cfg)
        } else {
          mod_4features_ui("4features_ui_1", cfg)
        }
      )
    )
  }

  if (isTRUE(options$mod_5coverage)) {
    tabs[["Check Coverage"]] <- shiny::tabPanel(
      "Check Coverage",
      shiny::fluidPage(
        value = "coverage", mod_5coverage_ui("5coverage_ui_1", cfg)
      )
    )
  }

  if (isTRUE(options$mod_6help)) {
    tabs[["Help"]] <- shiny::tabPanel(
      "Help",
      shiny::fluidPage(
        value = "help", mod_6help_ui("6help_ui_1", cfg)
      )
    )
  }

  # Select the first available tab by name
  selected_tab <- names(tabs)[[1]]

  do.call(
    shiny::navbarPage,
    c(
      list(
        id = "navbar",
        title = shiny::a(
          shiny::img(src = "www/logo_navbar.png", height = 40, class = "navbar-logo"),
          options$nav_title
        ),
        header = shiny::tagList(
          golem_add_external_resources(options),
          shinyjs::useShinyjs(),
          shinydisconnect::disconnectMessage(
            text           = "Your session timed out, reload the application.",
            refresh        = "Reload now",
            background     = "#f89f43",
            colour         = "white",
            overlayColour  = "grey",
            overlayOpacity = 0.3,
            refreshColour  = "brown"
          )
        ),
        theme = bslib::bs_theme(version = 5),
        selected = selected_tab
      ),
      unname(tabs)
    )
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
  # Register package's built-in www/ under two URL prefixes:
  #   "www"              — used by bundle_resources() and logo src= paths
  #   "shinyplanr-pkg"   — a stable prefix that is NEVER overridden, used to
  #                        load the package CSS after the deployment www/ override
  add_resource_path("www", app_sys("app/www"))
  add_resource_path("shinyplanr-pkg", app_sys("app/www"))

  # If running from a deployment project, register the deployment www/ at the
  # "www" prefix. This replaces the package registration at "www", so deployment
  # logos (logo_navbar.png, logo_welcome.png, etc.) override the package defaults.
  # The "shinyplanr-pkg" prefix is NOT overridden, so the package CSS is always
  # served from the package regardless of what the deployment www/ contains.
  # All required files are copied to the deployment www/ by setup/3_setup_app.R.
  if (dir.exists("www")) {
    shiny::addResourcePath("www", normalizePath("www", mustWork = FALSE))
  }

  tags$head(
    favicon(ext = "png"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = options$app_title
    ),
    # Load the package CSS via the stable "shinyplanr-pkg" prefix. This is
    # immune to the deployment www/ override above, so the full package
    # stylesheet (navbar colours, footer, fonts, component rules) is always
    # loaded from the installed package — not from the deployment www/.
    tags$link(
      rel  = "stylesheet",
      type = "text/css",
      href = "shinyplanr-pkg/custom.css"
    ),
    # Deployment CSS override: if the deployment project contains www/custom.css
    # (copied there by setup/3_setup_app.R), load it last. It contains only
    # :root variable overrides (colours, font) and wins by cascade position.
    if (file.exists("www/custom.css")) {
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    }
  )
}
