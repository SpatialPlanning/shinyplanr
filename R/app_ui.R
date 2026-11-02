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
        value = "welcome",
        mod_1welcome_ui("1welcome_ui_1", cfg)
      )
    )
  }

  tabs[["Scenario"]] <- shiny::tabPanel(
    "Scenario",
    shiny::fluidPage(
      value = "soln",
      mod_2scenario_ui("2scenario_ui_1", cfg)
    )
  )

  if (isTRUE(options$mod_3compare)) {
    tabs[["Comparison"]] <- shiny::tabPanel(
      "Comparison",
      shiny::fluidPage(
        value = "compare",
        mod_3compare_ui("3compare_ui_1", cfg)
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
        value = "coverage",
        mod_5coverage_ui("5coverage_ui_1", cfg)
      )
    )
  }

  if (isTRUE(options$mod_6help)) {
    tabs[["Help"]] <- shiny::tabPanel(
      "Help",
      shiny::fluidPage(
        value = "help",
        mod_6help_ui("6help_ui_1", cfg)
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
          shiny::img(
            src = "www/logo_navbar.png",
            height = 40,
            class = "navbar-logo"
          ),
          options$nav_title
        ),
        header = shiny::tagList(
          golem_add_external_resources(options),
          shinyjs::useShinyjs(),
          shinydisconnect::disconnectMessage(
            text = "Your session timed out, reload the application.",
            refresh = "Reload now",
            background = "#f89f43",
            colour = "white",
            overlayColour = "grey",
            overlayOpacity = 0.3,
            refreshColour = "brown"
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
  # Register the package's built-in www/ under two URL prefixes:
  #   "www"            — used by bundle_resources() and logo src= paths
  #   "shinyplanr-pkg" — stable prefix never overridden by the deployment www/;
  #                      used to serve shinyplanr.css reliably from the package
  add_resource_path("www", app_sys("app/www"))
  add_resource_path("shinyplanr-pkg", app_sys("app/www"))

  # If running from a deployment project, override the "www" prefix with the
  # deployment www/ folder. This makes logo src= paths resolve to the
  # deployment's copies (logo_navbar.png, logo_welcome.png, etc.), which are
  # copied there by setup/3_setup_app.R.
  # The "shinyplanr-pkg" prefix is NOT overridden, so shinyplanr.css is always
  # served from the installed package regardless of what the deployment www/
  # contains.
  if (dir.exists("www")) {
    shiny::addResourcePath("www", normalizePath("www", mustWork = FALSE))
  }

  tags$head(
    favicon(ext = "png"),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = options$app_title
    ),
    # Load the package stylesheet (shinyplanr.css) via the stable
    # "shinyplanr-pkg" prefix. This file contains all layout, typography,
    # component rules, and default :root colour variables.
    #
    # The file is named shinyplanr.css (not custom.css) to avoid a naming
    # collision with the deployment override below. Previously, when the
    # package stylesheet was named custom.css, the golem html_dependency
    # (all_files=TRUE) caused Shiny to inject a <link> for the package
    # custom.css AFTER the deployment override, resetting the colours.
    # With the rename, bundle_resources() emits a <link href="www/shinyplanr.css">
    # which 404s harmlessly in deployment (deployment www/ has no shinyplanr.css),
    # and this explicit tag below loads the package CSS reliably.
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "shinyplanr-pkg/shinyplanr.css"
    ),
    # Deployment CSS override: if the deployment project contains www/custom.css
    # (copied there by setup/3_setup_app.R), load it AFTER the package
    # stylesheet. It contains only :root variable overrides (colours, font)
    # and wins by cascade position because it is the last stylesheet loaded.
    if (file.exists("www/custom.css")) {
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
    }
  )
}
