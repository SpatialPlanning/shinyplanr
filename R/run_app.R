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
  ...
) {
  # Register a top-level onStop callback so that when the app is interrupted
  # (e.g. via Positron's Stop button or Ctrl+C), httpuv's libuv event loop is
  # explicitly closed. Without this, uv_run() can hold the R process open after
  # SIGINT because it is waiting for pending WebSocket writes to flush.
  # stopAllServers() is the documented way to force-close all httpuv sockets;
  # it is what shiny::stopApp() calls internally.
  shiny::onStop(httpuv::stopAllServers)

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
