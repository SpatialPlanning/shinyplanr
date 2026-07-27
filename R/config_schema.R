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
# When you increment:
#   1. Bump .shinyplanr_schema_version below
#   2. Add an entry to .shinyplanr_schema_changelog describing what changed
#      in 3_setup_app.R so users know exactly what to add manually
#   3. Update .shinyplanr_required_keys if keys were added or removed
#   4. Update data-raw/build_stub_sysdata.R to match the new structure,
#      then re-run it to regenerate R/sysdata.rda

.shinyplanr_schema_version <- 2L


# Human-readable changelog for each schema version bump.
#
# Each entry is a character vector of bullet points describing what changed
# in 3_setup_app.R between the previous version and this one. These are
# printed by .validate_config() when a version mismatch is detected, so the
# user knows exactly what to add to their existing 3_setup_app.R without
# having to diff against the template.
#
# Format: list(version_number = c("bullet 1", "bullet 2", ...))
# Only include versions >= 2 (version 1 was the initial release).
.shinyplanr_schema_changelog <- list(
  `2` = c(
    "Removed the `vars` key from config_list (now derived from Dict$nameVariable at runtime).",
    "Added the `sidebar` key: pre-computed fcreate_vars() / fcreate_check() results.",
    "In 3_setup_app.R, add the `sidebar` block before `config_list <- list(...)` and",
    "  include `sidebar = sidebar` in config_list. See the current template for the",
    "  exact code: shinyplanr:::.write_setup_app"
  )
)

#' Return the current shinyplanr config schema version
#'
#' Returns the integer schema version that this installation of shinyplanr
#' expects. Use this in your `3_setup_app.R` script to stamp the config with
#' the correct version so that `load_config()` can detect mismatches.
#'
#' @return An integer scalar.
#' @export
#' @examples
#' shinyplanr::get_schema_version()
get_schema_version <- function() {
  .shinyplanr_schema_version
}


# Required keys that must be present in every config file.
# Update this vector whenever .shinyplanr_schema_version is incremented.
.shinyplanr_required_keys <- c(
  "schema_version",
  "options",
  "map_theme",
  "bar_theme",
  "Dict",
  "raw_sf",
  "bndry",
  "overlay",
  "sidebar",
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
      "The file may be corrupted. Re-run setup/3_setup_app.R to regenerate it."
    )
  }

  # Check schema version
  config_schema <- config[["schema_version"]]
  if (is.null(config_schema)) config_schema <- 0L

  if (!identical(as.integer(config_schema), .shinyplanr_schema_version)) {
    # Build a changelog summary covering all versions between the config's
    # version and the current version, so the user sees exactly what changed
    # in 3_setup_app.R and what they need to add manually.
    old_v <- as.integer(config_schema)
    new_v <- .shinyplanr_schema_version

    changelog_versions <- seq(
      from = max(old_v + 1L, 2L),
      to   = new_v
    )

    changelog_lines <- unlist(lapply(changelog_versions, function(v) {
      entry <- .shinyplanr_schema_changelog[[as.character(v)]]
      if (is.null(entry)) {
        return(paste0("  [v", v, "] (no changelog entry)"))
      }
      c(paste0("  [v", v, "]"), paste0("    \u2022 ", entry))
    }))

    stop(
      "Config schema version mismatch.\n",
      "  Config was generated with schema version: ", config_schema, "\n",
      "  Installed shinyplanr expects schema version: ", new_v, "\n\n",
      "What changed between your config and the current version:\n",
      paste(changelog_lines, collapse = "\n"), "\n\n",
      "To fix:\n",
      "  1. Update setup/3_setup_app.R manually (see changes above)\n",
      "     OR run shinyplanr::update_shinyplanr_template() to refresh\n",
      "     safe-to-overwrite files (1_setup_enviro.R, app.R, deploy.R)\n",
      "  2. Re-run setup/3_setup_app.R to regenerate the config\n",
      "  3. Run renv::snapshot() to update the version lock\n",
      "  4. Redeploy with source('deploy.R')\n\n",
      "Config path: ", normalizePath(config_path, mustWork = FALSE),
      call. = FALSE
    )
  }

  # Check required keys
  missing_keys <- setdiff(.shinyplanr_required_keys, names(config))
  if (length(missing_keys) > 0) {
    stop(
      "Config is missing required keys: ",
      paste(missing_keys, collapse = ", "), "\n\n",
      "To fix: re-run setup/3_setup_app.R to regenerate the config file.\n",
      "Config path: ", normalizePath(config_path, mustWork = FALSE),
      call. = FALSE
    )
  }

  invisible(TRUE)
}
