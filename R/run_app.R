#' Run the Shiny Application
#'
#' @description
#' Launches the shinyplanr Shiny application. When running from a deployment
#' project (i.e. not from the package source), you must call
#' [load_config()] **before** calling `run_app()` so that all region-specific
#' data and settings are loaded into the package namespace. A typical
#' `app.R` entry point looks like:
#'
#' ```r
#' shinyplanr::load_config("config/shinyplanr_config.rds")
#' shinyplanr::run_app()
#' ```
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @seealso [load_config()] for loading region configuration prior to launch.
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(
    onStart = NULL,
    options = list(),
    enableBookmarking = NULL,
    uiPattern = "/",
    ...) {
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      uiPattern = uiPattern
    ),
    golem_opts = list(...)
  )
}
