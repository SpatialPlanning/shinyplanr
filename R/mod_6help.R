#' 6help UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'

mod_6help_ui <- function(id) {
  ns <- shiny::NS(id)
  # shiny::tagList(
    tabsetPanel(
      id = "tabs5", # type = "pills",
      tabPanel("Frequently Asked Questions",
        value = 1,
        shiny::fluidPage(
          shiny::markdown(tx_6faq)
        )
      ),
      tabPanel("Technical Information",
        value = 2,
        shiny::fluidPage(
          shiny::markdown(tx_6technical)
        )
      ),
      tabPanel("References",
        value = 4,
        shiny::fluidPage(
          shiny::markdown(tx_6references)
        )
      ),
      # tabPanel("Changelog",
      #   value = 5,
      #   shiny::fluidPage(
      #     shiny::h1("Application Changelog"),
      #     shiny::div(shiny::markdown(tx_6changelog)),
      #   ),
      # )
    )
  # ) # tagList
}

#' 6help Server Functions
#'
#' @noRd
mod_6help_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_6help_ui("6help_ui_1")

## To be copied in the server
# mod_6help_server("6help_ui_1")
