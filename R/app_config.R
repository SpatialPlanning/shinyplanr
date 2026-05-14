#' Access files in the current app
#'
#' NOTE: If you manually change your package name in the DESCRIPTION,
#' don't forget to change it here too, and in the config file.
#' For a safer name change mechanism, use the `golem::set_golem_name()` function.
#'
#' @param ... character vectors, specifying subdirectory and file(s)
#' within your package. The default, none, returns the root of the app.
#'
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "shinyplanr")
}


#' Retrieve the full shinyplanr config from the package config environment
#'
#' Called once at the top of `app_ui()` and `app_server()` to get the config
#' list that was populated by `load_config()`. All module UI and server
#' functions receive this list as their `cfg` argument and extract only the
#' objects they need as locals at the top of the function.
#'
#' The local-extraction pattern:
#' ```r
#' mod_2scenario_ui <- function(id, cfg) {
#'   Dict    <- cfg$Dict
#'   options <- cfg$options
#'   raw_sf  <- cfg$raw_sf
#'   # ... rest of function body unchanged
#' }
#' ```
#'
#' @return A named list containing all config keys (Dict, raw_sf, options,
#'   bndry, overlay, map_theme, tx, tx_1footer, tx_2solution, tx_2targets,
#'   tx_2cost, tx_2climate, tx_2ess, tx_6faq, tx_6technical, tx_6changelog,
#'   schema_version, etc.) as populated by `load_config()`.
#'
#' @seealso [load_config()] which must be called before `run_app()` to
#'   populate the config environment that this function reads from.
#'
#' @noRd
get_pkg_config <- function() {
  required <- .shinyplanr_required_keys
  mget(required, envir = shinyplanr_config, inherits = FALSE)
}


#' Read App Config
#'
#' @param value Value to retrieve from the config file.
#' @param config GOLEM_CONFIG_ACTIVE value. If unset, R_CONFIG_ACTIVE.
#' If unset, "default".
#' @param use_parent Logical, scan the parent directory for config file.
#' @param file Location of the config file
#'
#' @noRd
get_golem_config <- function(
    value,
    config = Sys.getenv(
      "GOLEM_CONFIG_ACTIVE",
      Sys.getenv(
        "R_CONFIG_ACTIVE",
        "default"
      )
    ),
    use_parent = TRUE,
    # Modify this if your config file is somewhere else
    file = app_sys("golem-config.yml")) {
  config::get(
    value = value,
    config = config,
    file = file,
    use_parent = use_parent
  )
}
