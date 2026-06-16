#' 6help UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @import shiny
mod_6help_ui <- function(id, cfg) {
  # Extract config locals
  tx_6faq       <- cfg$tx_6faq
  tx_6technical <- cfg$tx_6technical

  ns <- shiny::NS(id)
  # shiny::tagList(
    shiny::tabsetPanel(
      id = ns("tabs5"),
      type = "pills",
      shiny::tabPanel("Frequently Asked Questions",
        value = 1,
        shiny::fluidPage(
          shiny::markdown(tx_6faq)
        )
      ),
      shiny::tabPanel("Technical Information",
        value = 2,
        shiny::fluidPage(
          shiny::markdown(tx_6technical)
        )
      ),
    )
  # ) # tagList
}

#' 6help Server Functions
#'
#' @noRd
mod_6help_server <- function(id, cfg) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_6help_ui("6help_ui_1")

## To be copied in the server
# mod_6help_server("6help_ui_1")
