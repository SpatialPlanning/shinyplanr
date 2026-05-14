#' Validate a shinyplanr deployment configuration before saving
#'
#' Runs a comprehensive set of checks on a config list produced by
#' \code{setup-app.R} before it is saved to
#' \code{config/shinyplanr_config.rds}. This function is intended to be
#' called at the end of the deployer's \code{setup-app.R} script, immediately
#' before \code{saveRDS()}, to catch data problems early rather than at
#' runtime.
#'
#' @section Checks performed:
#' \itemize{
#'   \item \code{Dict} contains all required columns.
#'   \item All \code{Dict$nameVariable} values for Feature/Cost/LockIn/LockOut
#'     types are present as columns in \code{raw_sf}.
#'   \item \code{raw_sf} CRS matches \code{options$cCRS}.
#'   \item \code{bndry} and \code{overlay} are valid \code{sf} objects.
#'   \item \code{bndry} CRS matches \code{raw_sf} CRS.
#'   \item No Feature columns in \code{raw_sf} are entirely zero or entirely
#'     \code{NA} (would cause prioritizr to error or produce meaningless results).
#'   \item \code{tx} is a list with a \code{welcome} element, each entry of
#'     which contains \code{title} and \code{text} character fields.
#'   \item All \code{tx_*} text fields are non-\code{NULL} character strings.
#'   \item Feature-type Dict rows have \code{targetMin}, \code{targetMax},
#'     and \code{targetInitial} values within the 0-100 range.
#' }
#'
#' @param config_list A named list. The config object built in
#'   \code{setup-app.R}, containing at minimum the keys listed in
#'   \code{.shinyplanr_required_keys}.
#' @param strict Logical. If \code{TRUE} (default), the function stops
#'   immediately with a clear error message on the first failed check. If
#'   \code{FALSE}, all checks are run and a summary report is returned
#'   invisibly; warnings are issued for each failure.
#'
#' @return When \code{strict = FALSE}, invisibly returns a named list of
#'   logical values (\code{TRUE} = passed, \code{FALSE} = failed) for each
#'   check. When \code{strict = TRUE}, returns \code{invisible(TRUE)} if all
#'   checks pass.
#'
#' @examples
#' \dontrun{
#' # At the end of setup-app.R, before saveRDS():
#' validate_shinyplanr_data(config_list)           # strict -- stops on failure
#' validate_shinyplanr_data(config_list, strict = FALSE)  # report mode
#' }
#'
#' @export
validate_shinyplanr_data <- function(config_list, strict = TRUE) {

  stopifnot(is.list(config_list))

  results  <- list()
  messages <- character(0)

  # Helper: record a check result
  .check <- function(name, passed, msg = NULL) {
    results[[name]] <<- passed
    if (!passed) {
      full_msg <- if (is.null(msg)) name else paste0(name, ": ", msg)
      messages <<- c(messages, full_msg)
      if (isTRUE(strict)) {
        stop(
          "validate_shinyplanr_data() failed check '", name, "'.\n",
          full_msg, "\n\n",
          "Fix the issue in setup-app.R and re-run to regenerate the config.",
          call. = FALSE
        )
      }
    }
    invisible(passed)
  }

  Dict    <- config_list[["Dict"]]
  raw_sf  <- config_list[["raw_sf"]]
  bndry   <- config_list[["bndry"]]
  overlay <- config_list[["overlay"]]
  opts    <- config_list[["options"]]
  tx      <- config_list[["tx"]]

  # -------------------------------------------------------------------------
  # 1. Dict required columns
  # -------------------------------------------------------------------------
  required_dict_cols <- c(
    "nameCommon", "nameVariable", "category", "categoryID",
    "type", "targetInitial", "targetMin", "targetMax",
    "includeApp", "includeJust", "justification"
  )

  if (!is.data.frame(Dict)) {
    .check(
      "Dict_is_dataframe",
      FALSE,
      "config_list$Dict must be a data frame."
    )
  } else {
    missing_cols <- setdiff(required_dict_cols, names(Dict))
    .check(
      "Dict_required_columns",
      length(missing_cols) == 0,
      if (length(missing_cols) > 0)
        paste0("Dict is missing required columns: ",
               paste(missing_cols, collapse = ", "))
    )
  }

  # -------------------------------------------------------------------------
  # 2. raw_sf column coverage
  # -------------------------------------------------------------------------
  if (inherits(raw_sf, "sf") && is.data.frame(Dict)) {

    types_with_cols <- c("Feature", "Cost", "LockIn", "LockOut", "Bioregion",
                         "EcosystemServices")
    dict_vars <- Dict %>%
      dplyr::filter(.data$type %in% types_with_cols) %>%
      dplyr::pull("nameVariable")

    raw_cols <- setdiff(names(raw_sf), attr(raw_sf, "sf_column"))
    missing_vars <- setdiff(dict_vars, raw_cols)

    .check(
      "raw_sf_columns_match_Dict",
      length(missing_vars) == 0,
      if (length(missing_vars) > 0)
        paste0(
          length(missing_vars), " Dict variable(s) not found in raw_sf: ",
          paste(missing_vars, collapse = ", ")
        )
    )
  } else if (!inherits(raw_sf, "sf")) {
    .check("raw_sf_is_sf", FALSE, "config_list$raw_sf is not an sf object.")
  }

  # -------------------------------------------------------------------------
  # 3. CRS: raw_sf matches options$cCRS
  # -------------------------------------------------------------------------
  if (inherits(raw_sf, "sf") && !is.null(opts[["cCRS"]])) {
    raw_crs_wkt  <- sf::st_crs(raw_sf)
    target_crs   <- tryCatch(sf::st_crs(opts$cCRS), error = function(e) NA)

    crs_match <- !is.na(target_crs) && isTRUE(raw_crs_wkt == target_crs)
    .check(
      "raw_sf_CRS_matches_options_cCRS",
      crs_match,
      if (!crs_match)
        paste0(
          "raw_sf CRS does not match options$cCRS ('", opts$cCRS, "').\n",
          "  raw_sf CRS: ", sf::st_crs(raw_sf)$input
        )
    )
  }

  # -------------------------------------------------------------------------
  # 4. bndry is a valid sf object
  # -------------------------------------------------------------------------
  .check(
    "bndry_is_sf",
    inherits(bndry, "sf") && nrow(bndry) > 0,
    "config_list$bndry must be a non-empty sf object."
  )

  # -------------------------------------------------------------------------
  # 5. overlay is a valid sf object (can be empty)
  # -------------------------------------------------------------------------
  .check(
    "overlay_is_sf",
    inherits(overlay, "sf"),
    "config_list$overlay must be an sf object (can be empty)."
  )

  # -------------------------------------------------------------------------
  # 6. bndry CRS matches raw_sf CRS
  # -------------------------------------------------------------------------
  if (inherits(raw_sf, "sf") && inherits(bndry, "sf")) {
    crs_match_bndry <- isTRUE(sf::st_crs(raw_sf) == sf::st_crs(bndry))
    .check(
      "bndry_CRS_matches_raw_sf",
      crs_match_bndry,
      if (!crs_match_bndry)
        paste0(
          "bndry CRS does not match raw_sf CRS.\n",
          "  raw_sf: ", sf::st_crs(raw_sf)$input, "\n",
          "  bndry:  ", sf::st_crs(bndry)$input
        )
    )
  }

  # -------------------------------------------------------------------------
  # 7. No Feature columns in raw_sf are all-zero or all-NA
  # -------------------------------------------------------------------------
  if (inherits(raw_sf, "sf") && is.data.frame(Dict)) {
    feature_vars <- Dict %>%
      dplyr::filter(.data$type == "Feature") %>%
      dplyr::pull("nameVariable")

    raw_data <- sf::st_drop_geometry(raw_sf)
    present_feature_vars <- intersect(feature_vars, names(raw_data))

    if (length(present_feature_vars) > 0) {
      all_zero_or_na <- purrr::map_lgl(present_feature_vars, function(v) {
        col <- raw_data[[v]]
        all(is.na(col)) || (is.numeric(col) && sum(col, na.rm = TRUE) == 0)
      })

      zero_vars <- present_feature_vars[all_zero_or_na]
      .check(
        "no_feature_columns_all_zero_or_NA",
        length(zero_vars) == 0,
        if (length(zero_vars) > 0)
          paste0(
            length(zero_vars), " Feature column(s) are all-zero or all-NA in raw_sf: ",
            paste(zero_vars, collapse = ", "), "\n",
            "These features would cause prioritizr to error. ",
            "Remove them from Dict or check your data pipeline."
          )
      )
    }
  }

  # -------------------------------------------------------------------------
  # 8. tx structure
  # -------------------------------------------------------------------------
  tx_structure_ok <- (
    is.list(tx) &&
    !is.null(tx[["welcome"]]) &&
    is.list(tx[["welcome"]]) &&
    length(tx[["welcome"]]) >= 1 &&
    all(purrr::map_lgl(tx[["welcome"]], function(entry) {
      is.list(entry) &&
        !is.null(entry[["title"]]) && is.character(entry[["title"]]) &&
        !is.null(entry[["text"]])  && is.character(entry[["text"]])
    }))
  )

  .check(
    "tx_welcome_structure",
    tx_structure_ok,
    paste0(
      "config_list$tx must be a list with a 'welcome' element.\n",
      "  Each entry of tx$welcome must be a list with 'title' (character) ",
      "and 'text' (character) fields."
    )
  )

  # -------------------------------------------------------------------------
  # 9. All tx_* text fields are character strings
  # -------------------------------------------------------------------------
  tx_text_fields <- c(
    "tx_1footer", "tx_2solution", "tx_2targets", "tx_2cost",
    "tx_2climate", "tx_2ess", "tx_6faq", "tx_6technical", "tx_6changelog"
  )

  purrr::walk(tx_text_fields, function(field) {
    val <- config_list[[field]]
    .check(
      paste0(field, "_is_character"),
      !is.null(val) && is.character(val),
      paste0("config_list$", field, " must be a non-NULL character string.")
    )
  })

  # -------------------------------------------------------------------------
  # 10. Feature-type target values are in 0-100 range
  # -------------------------------------------------------------------------
  if (is.data.frame(Dict)) {
    feature_dict <- Dict %>%
      dplyr::filter(.data$type == "Feature") %>%
      dplyr::select("nameVariable", "targetMin", "targetMax", "targetInitial")

    if (nrow(feature_dict) > 0) {
      out_of_range <- feature_dict %>%
        dplyr::filter(
          (!is.na(.data$targetMin)     & (.data$targetMin < 0 | .data$targetMin > 100)) |
          (!is.na(.data$targetMax)     & (.data$targetMax < 0 | .data$targetMax > 100)) |
          (!is.na(.data$targetInitial) & (.data$targetInitial < 0 | .data$targetInitial > 100))
        ) %>%
        dplyr::pull("nameVariable")

      .check(
        "feature_targets_in_range_0_100",
        length(out_of_range) == 0,
        if (length(out_of_range) > 0)
          paste0(
            length(out_of_range), " Feature(s) have target values outside 0-100: ",
            paste(out_of_range, collapse = ", ")
          )
      )
    }
  }

  # -------------------------------------------------------------------------
  # Summary
  # -------------------------------------------------------------------------
  n_checks  <- length(results)
  n_passed  <- sum(unlist(results))
  n_failed  <- n_checks - n_passed

  if (n_failed == 0) {
    message(
      "validate_shinyplanr_data(): all ", n_checks, " checks passed. ",
      "Config is ready to save."
    )
  } else {
    # strict = FALSE path: issue warnings for all failures
    for (msg in messages) {
      warning(msg, call. = FALSE)
    }
    message(
      "validate_shinyplanr_data(): ", n_failed, " of ", n_checks,
      " check(s) failed (see warnings above)."
    )
  }

  invisible(if (strict) TRUE else as.list(results))
}
