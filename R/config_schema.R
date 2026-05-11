# Internal: shinyplanr config schema version
#
# This integer is compared against the schema_version field in a
# shinyplanr_config.rds file when load_config() is called.
#
# Rules for incrementing:
#   - INCREMENT when a key is ADDED, REMOVED, or RENAMED in the config list
#   - DO NOT increment for bug fixes, new features that don't change the
#     config structure, or package version bumps
#
# When you increment, also update data-raw/build_stub_sysdata.R to match
# the new structure, then re-run it to regenerate R/sysdata.rda.
#
# Current schema version history:
#   1 - Initial runtime-config deployment model

.shinyplanr_schema_version <- 1L


# Required keys that must be present in every config file.
# Update this vector whenever .shinyplanr_schema_version is incremented.
.shinyplanr_required_keys <- c(
  "schema_version",
  "options",
  "map_theme",
  "bar_theme",
  "Dict",
  "vars",
  "raw_sf",
  "bndry",
  "overlay",
  "tx",
  "tx_1footer",
  "tx_2solution",
  "tx_2targets",
  "tx_2cost",
  "tx_2climate",
  "tx_2ess",
  "tx_6faq",
  "tx_6technical",
  "tx_6changelog"
)


#' Validate a shinyplanr config list
#'
#' Checks that a config object loaded from an .rds file has the correct schema
#' version and all required keys. Stops with a clear, actionable error message
#' if validation fails.
#'
#' @param config A list loaded from a shinyplanr_config.rds file.
#' @param config_path Character. Path to the config file (used in error messages).
#'
#' @return Invisibly returns TRUE if validation passes.
#'
#' @noRd
.validate_config <- function(config, config_path) {

  if (!is.list(config)) {
    stop(
      "The config file does not contain a valid list: ",
      normalizePath(config_path, mustWork = FALSE), "\n",
      "The file may be corrupted. Re-run setup-app.R to regenerate it."
    )
  }

  # Check schema version
  config_schema <- config[["schema_version"]]
  if (is.null(config_schema)) config_schema <- 0L

  if (!identical(as.integer(config_schema), .shinyplanr_schema_version)) {
    stop(
      "Config schema version mismatch.\n",
      "  Config was generated with schema version: ", config_schema, "\n",
      "  Installed shinyplanr expects schema version: ", .shinyplanr_schema_version, "\n\n",
      "To fix:\n",
      "  1. Re-run your setup-app.R script to regenerate the config\n",
      "  2. Run renv::snapshot() to update the version lock\n",
      "  3. Redeploy with source('deploy.R')\n\n",
      "Config path: ", normalizePath(config_path, mustWork = FALSE)
    )
  }

  # Check required keys
  missing_keys <- setdiff(.shinyplanr_required_keys, names(config))
  if (length(missing_keys) > 0) {
    stop(
      "Config is missing required keys: ",
      paste(missing_keys, collapse = ", "), "\n\n",
      "To fix: re-run setup-app.R to regenerate the config file.\n",
      "Config path: ", normalizePath(config_path, mustWork = FALSE)
    )
  }

  invisible(TRUE)
}
