

create_welcome_page <- function(x, ns){

  if (length(x) == 1) {
    shiny::div(shiny::markdown(x[[1]]$text))
  } else {

    shiny::tabsetPanel(
      id = ns("welcome_tabs"),
      type = "pills",

      !!!purrr::map2(x,
                     seq_along(x),
                     ~ shiny::tabPanel(.x$title,
                                       value = .y,
                                       shiny::div(shiny::br(),
                                                  shiny::markdown(.x$text))))

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
#' @import shiny
mod_1welcome_ui <- function(id, cfg) {
  # Extract config locals
  tx         <- cfg$tx
  tx_1footer <- cfg$tx_1footer
  options    <- cfg$options

  # Institution text: use options$institution_text if set, otherwise fall back
  # to the legacy hard-coded UQ string so existing deployments are unaffected.
  institution_text <- options$institution_text %||%
    "This application was developed by researchers at The University of Queensland."

  ns <- shiny::NS(id)
  shiny::fluidPage(

    create_welcome_page(tx$welcome, ns),


    # Footer section with logos and funding information
    shiny::div(
      class = "home-footer",
      shiny::fluidRow(
        shiny::column(
          width = 4,
          shiny::div(
            class = "contact-section",
            shiny::markdown(tx_1footer)
          )
        ),
        shiny::column(
          width = 4,
          shiny::div(class = "contact-section",
                     shiny::p(institution_text),
                     shiny::p(paste0("\u00A9 ", format(Sys.Date(), "%Y"))),
          )
        ),
        shiny::column(
          width = 4,
          shiny::div(
            class = "funding-section",
            shiny::h5("Funded by:", class = "funding-title"),
            shiny::div(
              class = "funding-logos",
              a(img(src = "www/logo_funder.png",
                    alt = "Funder Logo"),
                href = options$funder_url,
                target = "_blank"),
              if (isTRUE(options$show_uq_logo)) {
                a(img(src = "www/uq-logo-white.png",
                      alt = "UQ Logo"),
                  href = "https://spatialplanning.github.io",
                  target = "_blank")
              }
            )
          )
        )
      )
    )
  )
}

#' 1welcome Server Functions
#'
#' @noRd
mod_1welcome_server <- function(id, cfg) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_1welcome_ui("1welcome_1")

## To be copied in the server
# mod_1welcome_server("1welcome_1")
