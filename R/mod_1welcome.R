

create_welcome_page <- function(x, ns){

  if (length(x) == 1) {
    shiny::div(shiny::markdown(x[[1]]$text))
  } else {

    shiny::tabsetPanel(
      id = ns("welcome_tabs"),
      type = "pills",

      !!!purrr::map2(x, seq_along(x), ~ shiny::tabPanel(.x$title,
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
#' @importFrom shiny NS tagList
mod_1welcome_ui <- function(id) {
  ns <- NS(id)
  shiny::fluidPage(

    create_welcome_page(tx$welcome, ns),


    # Footer section with logos and funding information
    div(
      class = "home-footer",
      shiny::fluidRow(
        shiny::column(
          width = 4,
          div(
            class = "contact-section",
            shiny::h4("For further information:", class = "funding-title"),
            shiny::p(
              "General Enquiries: ",
              a("Emily Stokes",
                href = "https://www.waittinstitute.org/team",
                target = "_blank",
                class = "contact-link"),
              shiny::br(),
              "About the app: ",
              a("Jason Everett",
                href = "https://jaseeverett.github.io",
                target = "_blank",
                class = "contact-link")
            )
          )
        ),

        shiny::column(
          width = 4,
          shiny::div(class = "contact-section",
                     shiny::p("This shiny application was developed by researchers at The University of Queensland."),
                     shiny::p("Powered by shinyplanr and spatialplanr."),
                     shiny::p("© 2025"),
          )
        ),

        shiny::column(
          width = 4,
          div(
            class = "funding-section",
            shiny::h4("Funded by:", class = "funding-title"),
            div(
              class = "funding-logos",
              a(img(src = "www/logo.png",
                    alt = "Waitt Institute Logo"),
                href = "https://waittinstitute.org",
                target = "_blank"),
              a(img(src = "www/uq-logo-white.png",
                    alt = "UQ Logo"),
                href = "https://www.uq.edu.au",
                target = "_blank")
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
mod_1welcome_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_1welcome_ui("1welcome_1")

## To be copied in the server
# mod_1welcome_server("1welcome_1")
