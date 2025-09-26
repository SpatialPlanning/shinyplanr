

create_welcome_page <- function(x, ns){

  if (length(x) == 1) {
    shiny::div(shiny::markdown(x[[1]]$text))
  } else {

    shiny::tabsetPanel(
      id = ns("welcome_tabs"), # type = "pills",

      !!!purrr::map2(x, seq_along(x), ~ shiny::tabPanel(.x$title,
                                              value = .y,
                                              shiny::div(shiny::markdown(.x$text))))

    ) # end tabset panel
  } # end else
} # end function





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
  shiny::fluidPage(

    create_welcome_page(tx$welcome, ns)

  )
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
