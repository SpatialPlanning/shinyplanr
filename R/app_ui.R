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

    # Your application UI logic

    title = shiny::a(shiny::img(src = "www/logo.png",
                                height = 40,
                                style = "padding-right:10px; margin-top:-10px; margin-bottom:-10px"),
                     options$nav_title
    ),
    id = "navbar",

    # TODO Can I move this into a css?
    theme = bslib::bs_theme(
      version = 5,
      bootswatch = "sandstone", #"zephyr", #"flatly", # https://bootswatch.com/flatly/
      primary = options$nav_primary,
      #  # "border-width" = "5px",
      #  # "border-color" = "red",
      "h1-font-size" = "2rem", # Twice the base size
      "h2-font-size" = "1.8rem",
      "h3-font-size" = "1.6rem", # 1.6 times base size
      "h4-font-size" = "1.4rem",
      "h5-font-size" = "1.2rem",
      "h6-font-size" = "1rem",
      # "border-width" = "0px",
      "navbar-padding-bottom" = "100px",
      "enable-rounded" = TRUE,
      # inverse = TRUE
    ) %>% # https://rstudio.github.io/bslib/articles/bslib.html#custom
      bslib::bs_add_rules(
        # https://stackoverflow.com/questions/77230269/bslib-theme-not-coloring-page-navbar-as-expected
        rules = "
                  .navbar.navbar-default {
                        background-color: $primary !important;
                    }
                    "
      ),
    selected = "Welcome",
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
    shiny::tabPanel(
      "Credit",
      shiny::fluidPage(
        value = "credit", mod_7credit_ui("7credit_1")
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
