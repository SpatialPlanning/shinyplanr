#' 7multiobj UI Function
#'
#' @description A shiny Module for multi-objective optimisation.
#'   This module is currently a placeholder and is disabled in the default
#'   app configuration.
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
      width = 3
    ),

    shiny::mainPanel(

    )
  )
}

#' 7multiobj Server Functions
#'
#' @noRd
mod_7multiobj_server <- function(id) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns


  })
}

## To be copied in the UI
# mod_7multiobj_ui("7multiobj_ui_1")

## To be copied in the server
# mod_7multiobj_server("7multiobj_ui_1")
