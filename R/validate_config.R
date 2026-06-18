#' Validate a shinyplanr feature dictionary (Dict_Feature.csv)
#'
#' Runs structural checks on the raw (unfiltered) feature dictionary read from
#' \code{Dict_Feature.csv} in \code{setup/3_setup_app.R}, \strong{before} the
#' \code{includeApp} filter is applied.  Call this immediately after
#' \code{readr::read_csv()} and before \code{dplyr::filter(includeApp)}.
#'
#' Catching problems here -- before the data is loaded -- gives the deployer
#' the clearest possible error messages, because the issue is in the CSV they
#' just edited rather than buried inside a spatial data pipeline.
#'
#' @section Checks performed:
#' \itemize{
#'   \item All required columns are present in \code{Dict}.
#'   \item \code{includeApp} and \code{includeJust} columns are logical
#'     (\code{TRUE}/\code{FALSE}), not character or integer.  A common mistake
#'     is editing the CSV in Excel, which can convert \code{TRUE} to \code{1}
#'     or \code{"TRUE"} (character), causing \code{dplyr::filter(includeApp)}
#'     to silently drop all rows.
#'   \item All values in the \code{type} column are from the known set
#'     (\code{"Feature"}, \code{"Cost"}, \code{"LockIn"}, \code{"LockOut"},
#'     \code{"Bioregion"}, \code{"EcosystemServices"}, \code{"Justification"}).
#'     A typo like \code{"feature"} (lowercase) silently excludes a row from
#'     all app processing.
#'   \item \code{nameVariable} is unique within each \code{type}.  Duplicates
#'     cause silent bugs in \code{prioritizr} (duplicate feature columns) and
#'     duplicate slider input IDs in the Shiny UI.  Note: the same
#'     \code{nameVariable} may legitimately appear in both \code{"LockIn"} and
#'     \code{"LockOut"} rows (e.g. MPAs) -- uniqueness is only enforced within
#'     each type.
#'   \item At least one row has \code{includeApp == TRUE} and
#'     \code{type == "Feature"}.  An app with no active features cannot run a
#'     prioritisation.
#'   \item All rows with \code{includeApp == TRUE} and
#'     \code{type == "Feature"} have \code{targetMin}, \code{targetMax}, and
#'     \code{targetInitial} values in the 0--100 range.  Out-of-range values
#'     cause \code{prioritizr} to error at solve time.
#' }
#'
#' @param Dict A data frame.  The raw (unfiltered) feature dictionary, typically
#'   the direct output of
#'   \code{readr::read_csv(file.path(setup_dir, "Dict_Feature.csv"))}.
#' @param strict Logical.  If \code{TRUE} (default), stops immediately with a
#'   clear, actionable error message on the first failed check.  If
#'   \code{FALSE}, all checks are run and a summary report is returned
#'   invisibly; \code{warning()} is called for each failure.
#'
#' @return When \code{strict = FALSE}, invisibly returns a named list of
#'   logical values (\code{TRUE} = passed, \code{FALSE} = failed) for each
#'   check.  When \code{strict = TRUE}, returns \code{invisible(TRUE)} if all
#'   checks pass.
#'
#' @examples
#' \dontrun{
#' # In setup/3_setup_app.R, immediately after reading the CSV:
#' Dict_raw <- readr::read_csv(file.path(setup_dir, "Dict_Feature.csv"))
#' shinyplanr::validate_dict(Dict_raw)
#'
#' Dict <- Dict_raw |>
#'   dplyr::filter(includeApp) |>
#'   dplyr::arrange(type, categoryID, nameCommon)
#' }
#'
#' @export
validate_dict <- function(Dict, strict = TRUE) {

  stopifnot(is.data.frame(Dict))

  results  <- list()
  messages <- character(0)

  # Helper: record a check result (mirrors the pattern in validate_shinyplanr_data)
  .check <- function(name, passed, msg = NULL) {
    results[[name]] <<- passed
    if (!passed) {
      full_msg <- if (is.null(msg)) name else paste0("[Dict check '", name, "'] ", msg)
      messages <<- c(messages, full_msg)
      if (isTRUE(strict)) {
        stop(
          "validate_dict() failed check '", name, "'.\n\n",
          full_msg, "\n\n",
          "Fix Dict_Feature.csv and re-run setup/3_setup_app.R.",
          call. = FALSE
        )
      }
    }
    invisible(passed)
  }

  # Known valid type values -- update this vector if new types are added to the app.
  # "Climate" rows hold metric columns (e.g. SST trend) used to populate the
  # climate-smart dropdown in mod_2scenario and mod_3compare. They are not
  # features and have no targets, but their nameVariable must exist in raw_sf.
  .known_types <- c(
    "Feature", "Cost", "LockIn", "LockOut",
    "Bioregion", "EcosystemServices", "Justification", "Climate"
  )

  # ---------------------------------------------------------------------------
  # Check 1: Required columns are present
  # ---------------------------------------------------------------------------
  required_cols <- c(
    "nameCommon", "nameVariable", "category", "categoryID",
    "type", "targetInitial", "targetMin", "targetMax",
    "includeApp", "includeJust", "justification"
  )

  missing_cols <- setdiff(required_cols, names(Dict))
  .check(
    "Dict_required_columns",
    length(missing_cols) == 0,
    if (length(missing_cols) > 0)
      paste0(
        "Dict_Feature.csv is missing required column(s): ",
        paste(missing_cols, collapse = ", "), ".\n",
        "  Expected columns: ", paste(required_cols, collapse = ", "), ".\n",
        "  Check that the CSV has not been accidentally edited to remove a ",
        "column header."
      )
  )

  # Guard: remaining checks require the required columns to be present.
  # In strict mode we have already stopped above; in non-strict mode we skip
  # the remaining checks because they would produce misleading errors.
  if (!isTRUE(results[["Dict_required_columns"]])) {
    message(
      "validate_dict(): skipping remaining checks because required columns ",
      "are missing."
    )
    return(invisible(as.list(results)))
  }

  # ---------------------------------------------------------------------------
  # Check 2: includeApp and includeJust are logical
  # ---------------------------------------------------------------------------
  include_app_ok  <- is.logical(Dict$includeApp)
  include_just_ok <- is.logical(Dict$includeJust)

  .check(
    "includeApp_is_logical",
    include_app_ok,
    paste0(
      "The 'includeApp' column in Dict_Feature.csv must contain TRUE or FALSE ",
      "(logical), but found class: ", class(Dict$includeApp)[1], ".\n",
      "  This commonly happens when the CSV is opened and saved in Excel, ",
      "which converts TRUE/FALSE to 1/0 or the text \"TRUE\"/\"FALSE\".\n",
      "  Fix: open Dict_Feature.csv in a plain text editor and ensure the ",
      "column contains only TRUE or FALSE (no quotes, no 1/0)."
    )
  )

  .check(
    "includeJust_is_logical",
    include_just_ok,
    paste0(
      "The 'includeJust' column in Dict_Feature.csv must contain TRUE or FALSE ",
      "(logical), but found class: ", class(Dict$includeJust)[1], ".\n",
      "  Fix: open Dict_Feature.csv in a plain text editor and ensure the ",
      "column contains only TRUE or FALSE (no quotes, no 1/0)."
    )
  )

  # ---------------------------------------------------------------------------
  # Check 3: All type values are from the known set
  # ---------------------------------------------------------------------------
  unknown_types <- setdiff(unique(Dict$type), .known_types)
  .check(
    "Dict_type_values_known",
    length(unknown_types) == 0,
    if (length(unknown_types) > 0)
      paste0(
        "Dict_Feature.csv contains unknown value(s) in the 'type' column: ",
        paste(paste0('"', unknown_types, '"'), collapse = ", "), ".\n",
        "  Valid types are: ",
        paste(paste0('"', .known_types, '"'), collapse = ", "), ".\n",
        "  A typo (e.g. \"feature\" instead of \"Feature\") will silently ",
        "exclude that row from all app processing, including sliders, targets, ",
        "and constraints.\n",
        "  Affected nameVariable(s): ",
        paste(Dict$nameVariable[!Dict$type %in% .known_types], collapse = ", ")
      )
  )

  # ---------------------------------------------------------------------------
  # Check 4: nameVariable is unique within each type
  # ---------------------------------------------------------------------------
  dup_check <- Dict |>
    dplyr::group_by(.data$type, .data$nameVariable) |>
    dplyr::summarise(n = dplyr::n(), .groups = "drop") |>
    dplyr::filter(.data$n > 1)

  .check(
    "nameVariable_unique_within_type",
    nrow(dup_check) == 0,
    if (nrow(dup_check) > 0)
      paste0(
        nrow(dup_check), " nameVariable value(s) appear more than once within ",
        "the same type in Dict_Feature.csv:\n",
        paste(
          sprintf(
            "  type='%s', nameVariable='%s' (%d times)",
            dup_check$type, dup_check$nameVariable, dup_check$n
          ),
          collapse = "\n"
        ), "\n",
        "  Duplicate nameVariable values within a type cause duplicate slider ",
        "input IDs in the Shiny UI and silent errors in prioritizr.\n",
        "  Note: the same nameVariable CAN appear in both 'LockIn' and ",
        "'LockOut' rows (e.g. MPAs) -- duplicates are only checked within ",
        "each type."
      )
  )

  # ---------------------------------------------------------------------------
  # Check 5: At least one active Feature row exists
  # ---------------------------------------------------------------------------
  # Only meaningful when includeApp is logical; skip if Check 2 failed.
  if (isTRUE(results[["includeApp_is_logical"]])) {
    n_active_features <- sum(Dict$includeApp & Dict$type == "Feature", na.rm = TRUE)
    .check(
      "at_least_one_active_feature",
      n_active_features >= 1,
      paste0(
        "Dict_Feature.csv has no rows with type == \"Feature\" AND ",
        "includeApp == TRUE.\n",
        "  The app cannot run a prioritisation without at least one active ",
        "feature.\n",
        "  Fix: set includeApp = TRUE for at least one Feature row in ",
        "Dict_Feature.csv."
      )
    )
  }

  # ---------------------------------------------------------------------------
  # Check 6: Active Feature rows have target values in 0-100 range
  # ---------------------------------------------------------------------------
  # Only meaningful when includeApp is logical; skip if Check 2 failed.
  if (isTRUE(results[["includeApp_is_logical"]])) {
    active_features <- Dict |>
      dplyr::filter(.data$includeApp, .data$type == "Feature") |>
      dplyr::select("nameVariable", "targetMin", "targetMax", "targetInitial")

    if (nrow(active_features) > 0) {
      out_of_range <- active_features |>
        dplyr::filter(
          (!is.na(.data$targetMin)     & (.data$targetMin     < 0 | .data$targetMin     > 100)) |
          (!is.na(.data$targetMax)     & (.data$targetMax     < 0 | .data$targetMax     > 100)) |
          (!is.na(.data$targetInitial) & (.data$targetInitial < 0 | .data$targetInitial > 100))
        ) |>
        dplyr::pull("nameVariable")

      .check(
        "active_feature_targets_in_range",
        length(out_of_range) == 0,
        if (length(out_of_range) > 0)
          paste0(
            length(out_of_range), " active Feature row(s) in Dict_Feature.csv ",
            "have target values outside the 0-100 range:\n",
            "  ", paste(out_of_range, collapse = ", "), "\n",
            "  targetMin, targetMax, and targetInitial must all be between 0 ",
            "and 100 (inclusive).\n",
            "  These values are used as percentage targets in the ",
            "prioritisation slider UI."
          )
      )
    }
  }

  # ---------------------------------------------------------------------------
  # Summary
  # ---------------------------------------------------------------------------
  n_checks <- length(results)
  n_passed <- sum(unlist(results))
  n_failed <- n_checks - n_passed

  if (n_failed == 0) {
    message(
      "validate_dict(): all ", n_checks, " checks passed. ",
      "Dict_Feature.csv is valid."
    )
  } else {
    for (msg in messages) {
      warning(msg, call. = FALSE)
    }
    message(
      "validate_dict(): ", n_failed, " of ", n_checks,
      " check(s) failed (see warnings above)."
    )
  }

  invisible(if (strict) TRUE else as.list(results))
}


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

    # "Climate" columns are selected at runtime by fdefine_problem() when the
    # user picks a climate metric, so they must be present in raw_sf.
    types_with_cols <- c("Feature", "Cost", "LockIn", "LockOut", "Bioregion",
                         "EcosystemServices", "Climate")
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
  # 6b. overlay CRS matches raw_sf CRS (when overlay is non-empty)
  # -------------------------------------------------------------------------
  if (inherits(raw_sf, "sf") && inherits(overlay, "sf") && nrow(overlay) > 0) {
    crs_match_overlay <- isTRUE(sf::st_crs(raw_sf) == sf::st_crs(overlay))
    .check(
      "overlay_CRS_matches_raw_sf",
      crs_match_overlay,
      if (!crs_match_overlay)
        paste0(
          "overlay CRS does not match raw_sf CRS.\n",
          "  raw_sf:  ", sf::st_crs(raw_sf)$input, "\n",
          "  overlay: ", sf::st_crs(overlay)$input
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
  # 8b. sidebar structure
  # -------------------------------------------------------------------------
  sidebar <- config_list[["sidebar"]]
  sidebar_ok <- (
    is.list(sidebar) &&
    is.list(sidebar[["scenario"]]) &&
    is.list(sidebar[["compare"]]) &&
    is.data.frame(sidebar[["scenario"]][["slider_vars"]]) &&
    is.data.frame(sidebar[["compare"]][["Vars1"]]) &&
    is.data.frame(sidebar[["compare"]][["Vars2"]])
  )
  .check(
    "sidebar_structure",
    sidebar_ok,
    paste0(
      "config_list$sidebar must be a list with 'scenario' and 'compare' sub-lists.\n",
      "  Each must contain pre-computed slider/checkbox data frames.\n",
      "  Re-run setup-app.R to regenerate the config."
    )
  )

  # -------------------------------------------------------------------------
  # 8c. Dict has at least one Bioregion row (only when include_bioregion is TRUE)
  # -------------------------------------------------------------------------
  if (isTRUE(opts[["include_bioregion"]]) && is.data.frame(Dict)) {
    n_bioregion_rows <- sum(Dict$type == "Bioregion", na.rm = TRUE)
    .check(
      "Dict_has_bioregion_rows",
      n_bioregion_rows >= 1,
      paste0(
        "options$include_bioregion is TRUE but Dict contains no rows with ",
        "type == \"Bioregion\".\n",
        "  Add at least one Bioregion row to Dict_Feature.csv and re-run ",
        "setup-app.R."
      )
    )
  }

  # -------------------------------------------------------------------------
  # 8d. sidebar bioregion structure (only when include_bioregion is TRUE)
  # -------------------------------------------------------------------------
  if (isTRUE(opts[["include_bioregion"]]) && isTRUE(sidebar_ok)) {
    bioregion_sidebar_ok <- (
      is.data.frame(sidebar[["scenario"]][["slider_varsBioR"]]) &&
      is.data.frame(sidebar[["compare"]][["slider_varsBioR1"]]) &&
      is.data.frame(sidebar[["compare"]][["slider_varsBioR2"]])
    )
    .check(
      "sidebar_bioregion_structure",
      bioregion_sidebar_ok,
      paste0(
        "options$include_bioregion is TRUE but sidebar is missing bioregion ",
        "slider data frames.\n",
        "  Expected: sidebar$scenario$slider_varsBioR, ",
        "sidebar$compare$slider_varsBioR1, sidebar$compare$slider_varsBioR2.\n",
        "  Re-run setup-app.R to regenerate the config."
      )
    )
  }


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
