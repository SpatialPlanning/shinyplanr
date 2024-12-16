#' 1welcome UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_1welcome_ui <- function(id) {
  ns <- NS(id)
  # tagList(
    shiny::div(shiny::markdown(tx_1welcome))
  # ) # tagList
}

#' 1welcome Server Functions
#'
#' @noRd
mod_1welcome_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_1welcome_ui("1welcome_1")

## To be copied in the server
# mod_1welcome_server("1welcome_1")
