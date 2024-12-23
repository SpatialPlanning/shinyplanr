#' 7credit UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS
mod_7credit_ui <- function(id) {
  ns <- NS(id)
  shiny::fluidPage(
    titlePanel("Development"),
    shiny::div(shiny::markdown(tx_7credit)),
    shiny::h2("Acknowledgements"),
    shiny::h6("This Shiny App was built in R Shiny and uses many R packages, and we would like to acknowledge the following contributions:"),
    shiny::fluidPage(
      tags$ul(
        shiny::HTML("<li>Sievert C, Cheng J (2022). <em>bslib: Custom 'Bootstrap' 'Sass' Themes for 'shiny' and 'rmarkdown'</em>. R package version 0.4.0, <a href = https://CRAN.R-project.org/package=bslib target = _blank> Website</a>."),
        shiny::HTML("<li>Allaire J (2020). <em>config: Manage Environment Specific Configuration Values</em>. R package version 0.3.1, <a href = https://CRAN.R-project.org/package=config target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H, Fran\u00E7ois R, Henry L, M\u00FCller K (2022). <em>dplyr: A Grammar of Data Manipulation</em>. R package version 1.0.9, <a href = https://CRAN.R-project.org/package=dplyr target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H (2021). <em>forcats: Tools for Working with Categorical Variables (Factors)</em>. R package version 0.5.1, <a href = https://CRAN.R-project.org/package=forcats target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H (2016). <em>ggplot2: Elegant Graphics for Data Analysis</em>. Springer-Verlag New York, <a href = https://ggplot2.tidyverse.org target = _blank> Website</a>."),
        shiny::HTML("<li>Wilke C (2021). <em>ggridges: Ridgeline Plots in 'ggplot2'</em>. R package version 0.5.3, <a href = https://CRAN.R-project.org/package=ggridges target = _blank> Website</a>."),
        shiny::HTML("<li>Fay C, Guyader V, Rochette S, Girard C (2022). <em>golem: A Framework for Robust Shiny Applications</em>. R package version 0.3.3, <a href = https://CRAN.R-project.org/package=golem target = _blank> Website</a>."),
        shiny::HTML("<li>Auguie B (2017). <em>gridExtra: Miscellaneous Functions for 'Grid' Graphics</em>. R package version 2.3, <a href = https://CRAN.R-project.org/package=gridExtra target = _blank> Website</a>."),
        shiny::HTML("<li>Bache S, Wickham H (2022). <em>magrittr: A Forward-Pipe Operator for R</em>. R package version 2.0.3, <a href = https://CRAN.R-project.org/package=magrittr target = _blank> Website</a>."),
        shiny::HTML("<li>Pedersen T (2020). <em>patchwork: The Composer of Plots</em>. R package version 1.1.1, <a href = https://CRAN.R-project.org/package=patchwork target = _blank> Website</a>."),
        shiny::HTML("<li>Hanson JO, Schuster R, Morrell N, Strimas-Mackey M, Edwards BPM, Watts ME, Arcese P, Bennett J, Possingham HP (2021). <em>prioritizr: Systematic Conservation Prioritization in R</em>. R package version 7.1.1, <a href = https://CRAN.R-project.org/package=prioritizr target = _blank> Website</a>."),
        shiny::HTML("<li>Henry L, Wickham H (2020). <em>purrr: Functional Programming Tools</em>. R package version 0.3.4, <a href = https://CRAN.R-project.org/package=purrr target = _blank> Website</a>."),
        shiny::HTML("<li>Schumacher D, Ooms J, Yapparov B, and Hanson JO (2022) rcbc: COIN CBC MILP Solver Bindings. R package version 0.1.0.9001. <a href = https://github.com/dirkschumacher/rcbc target = _blank> Website</a>."),
        shiny::HTML("<li>Forrest J and Lougee-Heimer R (2005) CBC User Guide. In Emerging theory, Methods, and Applications (pp. 257--277). INFORMS, Catonsville, MD."),
        shiny::HTML("<li>Neuwirth E (2022). <em>RColorBrewer: ColorBrewer Palettes</em>. R package version 1.1-3, <a href = https://CRAN.R-project.org/package=RColorBrewer target = _blank> Website</a>."),
        shiny::HTML("<li>Henry L, Wickham H (2022). <em>rlang: Functions for Base Types and Core R and 'Tidyverse' Features</em>. R package version 1.0.4, <a href = https://CRAN.R-project.org/package=rlang target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H, Seidel D (2022). <em>scales: Scale Functions for Visualization</em>. R package version 1.2.0, <a href = https://CRAN.R-project.org/package=scales target = _blank> Website</a>."),
        shiny::HTML("<li>Pebesma, E., 2018. Simple Features for R: Standardized Support for Spatial Vector Data. The R Journal 10 (1), 439-446, <a href = https://doi.org/10.32614/RJ-2018-009 target = _blank> Website</a>."),
        shiny::HTML("<li>Chang W, Cheng J, Allaire J, Sievert C, Schloerke B, Xie Y, Allen J, McPherson J, Dipert A, Borges B (2022). <em>shiny: Web Application Framework for R</em>. R package version 1.7.2, <a href = https://CRAN.R-project.org/package=shiny target = _blank> Website</a>."),
        shiny::HTML("<li>Attali, D, Edwards T (2021). <em>shinyalert: Easily Create Pretty Popup Messages (Modals) in 'Shiny'</em>. R package version 3.0.0, <a href = https://cran.r-project.org/web/packages/shinyalert/index.html target = _blank> Website</a>."),
        shiny::HTML("<li>Sali A, Attali D (2020). <em>shinycssloaders: Add Loading Animations to a 'shiny' Output While It's Recalculating</em>. R package version 1.0.0, <a href = https://CRAN.R-project.org/package=shinycssloaders target = _blank> Website</a>."),
        shiny::HTML("<li>Chang W, Borges Ribeiro B (2021). <em>shinydashboard: Create Dashboards with 'Shiny'</em>. R package version 0.7.2, <a href = https://CRAN.R-project.org/package=shinydashboard target = _blank> Website</a>."),
        shiny::HTML("<li>Attali, D (2020). <em>shinydisconnect: Show a Nice Message When a 'Shiny' App Disconnects or Errors</em>. R package version 0.1.0, <a href = https://cran.rstudio.com/web/packages/shinydisconnect/index.html target = _blank> Website</a>."),
        shiny::HTML("<li>Attali D (2021). <em>shinyjs: Easily Improve the User Experience of Your Shiny Apps in Seconds</em>. R package version 2.1.0, <a href = https://CRAN.R-project.org/package=shinyjs target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H (2019). <em>stringr: Simple, Consistent Wrappers for Common String Operations</em>. R package version 1.4.0, <a href = https://CRAN.R-project.org/package=stringr target = _blank> Website</a>."),
        shiny::HTML("<li>Hijmans, RJ (2022). <em>terra: Spatial Data Analysis</em>. R package version 1.6-17, <a href = https://cran.r-project.org/web/packages/terra/index.html target = _blank>Website</a>."),
        shiny::HTML("<li>M\u00FCller K, Wickham H (2022). <em>tibble: Simple Data Frames</em>. R package version 3.1.8, <a href = https://CRAN.R-project.org/package=tibble target = _blank> Website</a>."),
        shiny::HTML("<li>Wickham H, Girlich M (2022). <em>tidyr: Tidy Messy Data</em>. R package version 1.2.0, <a href = https://CRAN.R-project.org/package=tidyr target = _blank> Website</a>."),
        shiny::HTML("<li>Henry L, Wickham H (2022). <em>tidyselect: Select from a Set of Strings</em>. R package version 1.1.2, <a href = https://CRAN.R-project.org/package=tidyselect target = _blank> Website</a>."),
        shiny::HTML("<li>Garcia Molinos, J., Schoeman, D.S., Brown, C.J., & Burrows, M.T. (2019). <em>VoCC: An R package for calculating the velocity of climate change and related climate metrics</em>. Methods in Ecology and Evolution, 10(12), 2195-2202. <a href = 'https://doi.org/10.1111/2041-210X.13295' target= _blank>https://doi.org/10.1111/2041-210X.13295</a>"),
      )
    )
  )
}

#' 7credit Server Functions
#'
#' @noRd
mod_7credit_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

## To be copied in the UI
# mod_7credit_ui("7credit_1")

## To be copied in the server
# mod_7credit_server("7credit_1")
