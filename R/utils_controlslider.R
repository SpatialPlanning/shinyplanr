library(shiny)

ui <- pageWithSidebar(
  headerPanel("Glass fullness"),
  sidebarPanel(
    sliderInput(inputId = "Full", label = "% water", min = 0, max = 1, value = 0.2),
    sliderInput(inputId = "Empty", label = "% air", min = 0, max = 1, value = 1 - 0.2),
    uiOutput("Empty")),
  mainPanel()
)

server <- function(input, output, session){

  # when water change, update air
  observeEvent(input$Full,  {
    updateSliderInput(session = session, inputId = "Empty", value = 1 - input$Full)
  })

  # when air change, update water
  observeEvent(input$Empty,  {
    updateSliderInput(session = session, inputId = "Full", value = 1 - input$Empty)
  })

}

shinyApp(ui = ui, server = server)
