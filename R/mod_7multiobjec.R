#' 7multiobj UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_7multiobj_ui <- function(id) {

  ns <- shiny::NS(id)

  shiny::sidebarLayout(
    shiny::sidebarPanel(
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      shiny::br(),
      width = 3
    ),

    shiny::mainPanel(

    )
  )
}

#' 5coverage Server Functions
#'
#' @noRd
mod_7multiobj_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns


  })
}

## To be copied in the UI
# mod_5coverage_ui("5coverage_1")

## To be copied in the server
# mod_5coverage_server("5coverage_1")
