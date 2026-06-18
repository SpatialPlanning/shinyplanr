# tests/testthat/test-validate_config.R
#
# Tests for validate_shinyplanr_data() — exported public function.
# Uses a minimal valid config (schema v2, no `vars` key) and mutates it
# to trigger each of the 10 internal checks individually.

# ---------------------------------------------------------------------------
# Helper: build a minimal valid config matching schema v2
# ---------------------------------------------------------------------------

make_valid_config_v2 <- function() {
  Dict <- data.frame(
    nameCommon    = c("Feature A", "Feature B"),
    nameVariable  = c("feature_A", "feature_B"),
    category      = c("Habitat", "Habitat"),
    categoryID    = c("Hab", "Hab"),
    type          = c("Feature", "Feature"),
    targetInitial = c(30, 30),
    targetMin     = c(0, 0),
    targetMax     = c(85, 85),
    includeApp    = c(TRUE, TRUE),
    includeJust   = c(TRUE, TRUE),
    units         = c("", ""),
    justification = c("Stub A.", "Stub B."),
    stringsAsFactors = FALSE
  )
  sidebar <- list(
    scenario = list(
      slider_vars     = fcreate_vars("2scenario_ui_1", Dict, "sli_", categoryOut = TRUE, byCategory = FALSE),
      slider_varsBioR = fcreate_vars("2scenario_ui_1", Dict, "sli_", categoryOut = TRUE, byCategory = TRUE, dataType = "Bioregion"),
      slider_varsCat  = fcreate_vars("2scenario_ui_1", Dict, "sli_", categoryOut = TRUE, byCategory = TRUE),
      check_lockIn    = fcreate_check("2scenario_ui_1", Dict, "LockIn",  "checkLI_", categoryOut = TRUE),
      check_lockOut   = fcreate_check("2scenario_ui_1", Dict, "LockOut", "checkLO_", categoryOut = TRUE)
    ),
    compare = list(
      Vars           = fcreate_vars("3compare_ui_1", Dict, "sli_",  categoryOut = TRUE),
      Vars2          = fcreate_vars("3compare_ui_1", Dict, "sli2_", categoryOut = TRUE),
      check_lockIn   = fcreate_check("3compare_ui_1", Dict, "LockIn",  "check1LI_", categoryOut = TRUE),
      check_lockIn2  = fcreate_check("3compare_ui_1", Dict, "LockIn",  "check2LI_", categoryOut = TRUE),
      check_lockOut  = fcreate_check("3compare_ui_1", Dict, "LockOut", "check1LO_", categoryOut = TRUE),
      check_lockOut2 = fcreate_check("3compare_ui_1", Dict, "LockOut", "check2LO_", categoryOut = TRUE)
    )
  )
  list(
    schema_version = 2L,
    options = list(
      app_title             = "Test App",
      nav_title             = "Test Region",
      funder_url            = "https://example.com",
      mod_1welcome          = TRUE,
      mod_2scenario         = TRUE,
      mod_3compare          = FALSE,
      mod_4features         = FALSE,
      mod_5coverage         = FALSE,
      mod_6help             = TRUE,
      mod_7credit           = FALSE,
      include_report        = FALSE,
      include_ess           = FALSE,
      include_explore       = FALSE,
      include_log           = FALSE,
      include_bioregion     = FALSE,
      show_logo_funder2     = FALSE,
      funder2_url           = "https://spatialplanning.github.io",
      include_climateChange = FALSE,
      climate_change        = 0L,
      include_lockedArea    = FALSE,
      targetsBy             = "individual",
      obj_func              = "min_set",
      cCRS                  = "ESRI:54009"
    ),
    map_theme = ggplot2::theme_bw(),
    bar_theme = ggplot2::theme_bw(),
    Dict    = Dict,
    raw_sf  = sf::st_sf(
      feature_A = c(0.8, 0.2),
      feature_B = c(0.3, 0.7),
      geometry  = sf::st_sfc(
        sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
        sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
        crs = "ESRI:54009"
      )
    ),
    bndry   = sf::st_sf(
      geometry = sf::st_sfc(
        sf::st_polygon(list(cbind(c(0, 2, 2, 0, 0), c(0, 0, 1, 1, 0)))),
        crs = "ESRI:54009"
      )
    ),
    overlay = sf::st_sf(geometry = sf::st_sfc(crs = "ESRI:54009")),
    sidebar = sidebar,
    tx      = list(
      welcome = list(list(title = "Welcome", text = "# Hello"))
    ),
    tx_1footer    = "Footer text",
    tx_2solution  = "",
    tx_2targets   = "",
    tx_2cost      = "",
    tx_2climate   = "",
    tx_2ess       = "",
    tx_6faq       = "",
    tx_6technical = "",
    tx_6changelog = ""
  )
}

# ---------------------------------------------------------------------------
# Happy path
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() passes for a fully valid config (strict)", {
  cfg <- make_valid_config_v2()
  expect_message(
    result <- validate_shinyplanr_data(cfg, strict = TRUE),
    regexp = "all.*checks passed"
  )
  expect_true(result)
})

test_that("validate_shinyplanr_data() returns named list of TRUEs in non-strict mode", {
  cfg <- make_valid_config_v2()
  result <- suppressMessages(validate_shinyplanr_data(cfg, strict = FALSE))
  expect_type(result, "list")
  expect_true(all(unlist(result)))
})

# ---------------------------------------------------------------------------
# Check 1a: Dict is not a data frame
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 1 when Dict is not a data frame", {
  cfg <- make_valid_config_v2()
  cfg$Dict <- "not_a_dataframe"
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "Dict_is_dataframe"
  )
})

# ---------------------------------------------------------------------------
# Check 1b: Dict missing required columns
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 1 when Dict is missing required columns", {
  cfg <- make_valid_config_v2()
  cfg$Dict <- cfg$Dict[, c("nameCommon", "nameVariable")]  # strip most columns
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "Dict_required_columns"
  )
})

# ---------------------------------------------------------------------------
# Check 2a: raw_sf is not an sf object
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 2 when raw_sf is not sf", {
  cfg <- make_valid_config_v2()
  cfg$raw_sf <- as.data.frame(sf::st_drop_geometry(cfg$raw_sf))
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "raw_sf_is_sf"
  )
})

# ---------------------------------------------------------------------------
# Check 2b: Dict variable missing from raw_sf columns
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 2 when Dict variable absent from raw_sf", {
  cfg <- make_valid_config_v2()
  # Add a Dict row whose nameVariable doesn't exist in raw_sf
  extra_row <- data.frame(
    nameCommon    = "Missing Feature",
    nameVariable  = "feature_missing",
    category      = "Habitat",
    categoryID    = "Hab",
    type          = "Feature",
    targetInitial = 30,
    targetMin     = 0,
    targetMax     = 85,
    includeApp    = TRUE,
    includeJust   = TRUE,
    units         = "",
    justification = "Not in raw_sf.",
    stringsAsFactors = FALSE
  )
  cfg$Dict <- rbind(cfg$Dict, extra_row)
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "raw_sf_columns_match_Dict"
  )
})

# ---------------------------------------------------------------------------
# Check 3: CRS mismatch between raw_sf and options$cCRS
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 3 when raw_sf CRS mismatches options$cCRS", {
  cfg <- make_valid_config_v2()
  # raw_sf is ESRI:54009 but options says EPSG:4326
  cfg$options$cCRS <- "EPSG:4326"
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "raw_sf_CRS_matches_options_cCRS"
  )
})

# ---------------------------------------------------------------------------
# Check 4: bndry is not a valid sf object
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 4 when bndry is not sf", {
  cfg <- make_valid_config_v2()
  cfg$bndry <- data.frame(x = 1)
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "bndry_is_sf"
  )
})

test_that("validate_shinyplanr_data() fails check 4 when bndry is empty sf", {
  cfg <- make_valid_config_v2()
  cfg$bndry <- sf::st_sf(geometry = sf::st_sfc(crs = "ESRI:54009"))  # 0 rows
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "bndry_is_sf"
  )
})

# ---------------------------------------------------------------------------
# Check 5: overlay is not an sf object
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 5 when overlay is not sf", {
  cfg <- make_valid_config_v2()
  cfg$overlay <- list()
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "overlay_is_sf"
  )
})

# ---------------------------------------------------------------------------
# Check 6: bndry CRS does not match raw_sf CRS
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 6 when bndry CRS mismatches raw_sf", {
  cfg <- make_valid_config_v2()
  # Re-project bndry to WGS84 while raw_sf stays in ESRI:54009
  cfg$bndry <- sf::st_transform(cfg$bndry, "EPSG:4326")
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "bndry_CRS_matches_raw_sf"
  )
})

# ---------------------------------------------------------------------------
# Check 7: Feature column is all-zero
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 7 when a Feature column is all-zero", {
  cfg <- make_valid_config_v2()
  cfg$raw_sf$feature_A <- 0  # all zeros
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "no_feature_columns_all_zero_or_NA"
  )
})

test_that("validate_shinyplanr_data() fails check 7 when a Feature column is all-NA", {
  cfg <- make_valid_config_v2()
  cfg$raw_sf$feature_B <- NA_real_
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "no_feature_columns_all_zero_or_NA"
  )
})

# ---------------------------------------------------------------------------
# Check 8: tx structure invalid
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 8 when tx$welcome is missing", {
  cfg <- make_valid_config_v2()
  cfg$tx <- list()  # no 'welcome' element
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "tx_welcome_structure"
  )
})

test_that("validate_shinyplanr_data() fails check 8 when tx$welcome entry lacks 'title'", {
  cfg <- make_valid_config_v2()
  cfg$tx$welcome <- list(list(text = "# Hello"))  # missing 'title'
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "tx_welcome_structure"
  )
})

# ---------------------------------------------------------------------------
# Check 9: tx_* text fields
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 9 when tx_2solution is NULL", {
  cfg <- make_valid_config_v2()
  cfg$tx_2solution <- NULL
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "tx_2solution_is_character"
  )
})

test_that("validate_shinyplanr_data() fails check 9 when tx_1footer is numeric", {
  cfg <- make_valid_config_v2()
  cfg$tx_1footer <- 42L
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "tx_1footer_is_character"
  )
})

# ---------------------------------------------------------------------------
# Check 10: Feature target values out of 0-100 range
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() fails check 10 when targetMin is negative", {
  cfg <- make_valid_config_v2()
  cfg$Dict$targetMin[1] <- -5
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "feature_targets_in_range_0_100"
  )
})

test_that("validate_shinyplanr_data() fails check 10 when targetMax exceeds 100", {
  cfg <- make_valid_config_v2()
  cfg$Dict$targetMax[2] <- 110
  expect_error(
    suppressMessages(validate_shinyplanr_data(cfg, strict = TRUE)),
    regexp = "feature_targets_in_range_0_100"
  )
})

# ---------------------------------------------------------------------------
# strict = FALSE: collects all failures, returns named list, warns not errors
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() with strict=FALSE returns list and warns on failure", {
  cfg <- make_valid_config_v2()
  cfg$Dict <- "not_a_dataframe"
  expect_warning(
    result <- suppressMessages(validate_shinyplanr_data(cfg, strict = FALSE)),
    regexp = "Dict_is_dataframe"
  )
  expect_type(result, "list")
  expect_false(isTRUE(result[["Dict_is_dataframe"]]))
})

test_that("validate_shinyplanr_data() with strict=FALSE continues past first failure", {
  cfg <- make_valid_config_v2()
  cfg$Dict$targetMax[1] <- 110   # check 10 failure
  cfg$bndry <- data.frame(x = 1) # check 4 failure
  # Should not stop — both failures should appear in result
  result <- suppressWarnings(suppressMessages(
    validate_shinyplanr_data(cfg, strict = FALSE)
  ))
  expect_false(isTRUE(result[["bndry_is_sf"]]))
  expect_false(isTRUE(result[["feature_targets_in_range_0_100"]]))
})

# ---------------------------------------------------------------------------
# config_list not a list — stopifnot fires before any check
# ---------------------------------------------------------------------------

test_that("validate_shinyplanr_data() stops immediately when config_list is not a list", {
  expect_error(
    validate_shinyplanr_data("not_a_list"),
    regexp = "is.list"
  )
})


# ===========================================================================
# validate_dict() tests
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: build a minimal valid full (unfiltered) Dict
# ---------------------------------------------------------------------------

make_valid_dict <- function() {
  data.frame(
    nameCommon    = c("Feature A", "Feature B (off)", "Equal Area Cost", "MPAs"),
    nameVariable  = c("feature_A", "feature_B", "cost_area", "mpas"),
    category      = c("Habitat", "Habitat", "Cost", "Protected Areas"),
    categoryID    = c("Hab", "Hab", "Cost", "MPAs"),
    type          = c("Feature", "Feature", "Cost", "LockIn"),
    targetInitial = c(30, 30, NA, NA),
    targetMin     = c(0,  0,  NA, NA),
    targetMax     = c(85, 85, NA, NA),
    includeApp    = c(TRUE, FALSE, TRUE, TRUE),
    includeJust   = c(TRUE, TRUE,  TRUE, TRUE),
    units         = c("", "", "", ""),
    justification = c("Stub A.", "Stub B.", "Equal area.", "Existing MPAs."),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# Happy path
# ---------------------------------------------------------------------------

test_that("validate_dict() passes for a fully valid Dict (strict)", {
  d <- make_valid_dict()
  expect_message(
    result <- validate_dict(d, strict = TRUE),
    regexp = "all.*checks passed"
  )
  expect_true(result)
})

test_that("validate_dict() returns named list of TRUEs in non-strict mode", {
  d <- make_valid_dict()
  result <- suppressMessages(validate_dict(d, strict = FALSE))
  expect_type(result, "list")
  expect_true(all(unlist(result)))
})

# ---------------------------------------------------------------------------
# stopifnot: Dict is not a data frame
# ---------------------------------------------------------------------------

test_that("validate_dict() stops immediately when Dict is not a data frame", {
  expect_error(
    validate_dict("not_a_dataframe"),
    regexp = "is.data.frame"
  )
})

# ---------------------------------------------------------------------------
# Check 1: Required columns missing
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 1 when a required column is missing", {
  d <- make_valid_dict()
  d$justification <- NULL  # remove a required column
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "Dict_required_columns"
  )
})

test_that("validate_dict() skips remaining checks after missing-column failure (non-strict)", {
  d <- make_valid_dict()
  d$includeApp <- NULL
  result <- suppressWarnings(suppressMessages(validate_dict(d, strict = FALSE)))
  # Only the required-columns check should be recorded; others are skipped
  expect_false(isTRUE(result[["Dict_required_columns"]]))
  expect_null(result[["includeApp_is_logical"]])
})

# ---------------------------------------------------------------------------
# Check 2: includeApp / includeJust are logical
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 2 when includeApp is integer (Excel 1/0)", {
  d <- make_valid_dict()
  d$includeApp <- as.integer(d$includeApp)  # 1L / 0L, as Excel would produce
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "includeApp_is_logical"
  )
})

test_that("validate_dict() fails check 2 when includeApp is character", {
  d <- make_valid_dict()
  d$includeApp <- as.character(d$includeApp)  # "TRUE" / "FALSE"
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "includeApp_is_logical"
  )
})

test_that("validate_dict() fails check 2 when includeJust is integer", {
  d <- make_valid_dict()
  d$includeJust <- as.integer(d$includeJust)
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "includeJust_is_logical"
  )
})

# ---------------------------------------------------------------------------
# Check 3: type values from known set
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 3 when type contains a lowercase typo", {
  d <- make_valid_dict()
  d$type[1] <- "feature"  # lowercase — common typo
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "Dict_type_values_known"
  )
})

test_that("validate_dict() fails check 3 when type contains a completely unknown value", {
  d <- make_valid_dict()
  d$type[2] <- "Habitat"  # not a valid type
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "Dict_type_values_known"
  )
})

test_that("validate_dict() passes check 3 for all known type values", {
  d <- make_valid_dict()
  # Add rows for every known type to confirm none are rejected
  extra <- data.frame(
    nameCommon    = c("LO", "Bio", "ESS", "Just"),
    nameVariable  = c("lock_out_var", "bio_var", "ess_var", "just_var"),
    category      = c("C", "C", "C", "C"),
    categoryID    = c("C", "C", "C", "C"),
    type          = c("LockOut", "Bioregion", "EcosystemServices", "Justification"),
    targetInitial = c(NA, NA, NA, NA),
    targetMin     = c(NA, NA, NA, NA),
    targetMax     = c(NA, NA, NA, NA),
    includeApp    = c(TRUE, TRUE, TRUE, FALSE),
    includeJust   = c(TRUE, TRUE, TRUE, FALSE),
    units         = c("", "", "", ""),
    justification = c(".", ".", ".", "."),
    stringsAsFactors = FALSE
  )
  d2 <- rbind(d, extra)
  expect_message(
    validate_dict(d2, strict = TRUE),
    regexp = "all.*checks passed"
  )
})

# ---------------------------------------------------------------------------
# Check 4: nameVariable unique within type
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 4 when nameVariable is duplicated within a type", {
  d <- make_valid_dict()
  # Add a second Feature row with the same nameVariable as the first
  dup_row <- d[1, ]
  d2 <- rbind(d, dup_row)
  expect_error(
    suppressMessages(validate_dict(d2, strict = TRUE)),
    regexp = "nameVariable_unique_within_type"
  )
})

test_that("validate_dict() passes check 4 when same nameVariable appears in LockIn AND LockOut", {
  d <- make_valid_dict()
  # MPAs legitimately appear as both LockIn and LockOut
  lockout_row <- data.frame(
    nameCommon    = "MPAs",
    nameVariable  = "mpas",  # same nameVariable as the LockIn row
    category      = "Protected Areas",
    categoryID    = "MPAs",
    type          = "LockOut",  # different type — should NOT trigger duplicate check
    targetInitial = NA_real_,
    targetMin     = NA_real_,
    targetMax     = NA_real_,
    includeApp    = TRUE,
    includeJust   = TRUE,
    units         = "",
    justification = "Existing MPAs.",
    stringsAsFactors = FALSE
  )
  d2 <- rbind(d, lockout_row)
  expect_message(
    validate_dict(d2, strict = TRUE),
    regexp = "all.*checks passed"
  )
})

# ---------------------------------------------------------------------------
# Check 5: At least one active Feature row
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 5 when no Feature rows have includeApp == TRUE", {
  d <- make_valid_dict()
  d$includeApp[d$type == "Feature"] <- FALSE  # disable all features
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "at_least_one_active_feature"
  )
})

# ---------------------------------------------------------------------------
# Check 6: Active Feature target values in 0-100 range
# ---------------------------------------------------------------------------

test_that("validate_dict() fails check 6 when an active Feature has targetMin < 0", {
  d <- make_valid_dict()
  d$targetMin[d$type == "Feature" & d$includeApp][1] <- -5
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "active_feature_targets_in_range"
  )
})

test_that("validate_dict() fails check 6 when an active Feature has targetMax > 100", {
  d <- make_valid_dict()
  d$targetMax[d$type == "Feature" & d$includeApp][1] <- 110
  expect_error(
    suppressMessages(validate_dict(d, strict = TRUE)),
    regexp = "active_feature_targets_in_range"
  )
})

test_that("validate_dict() passes check 6 when an inactive Feature has out-of-range targets", {
  # includeApp == FALSE rows are not checked for target range — they are not
  # used in the app and the deployer may have left them with placeholder values.
  d <- make_valid_dict()
  d$targetMax[d$type == "Feature" & !d$includeApp][1] <- 999
  expect_message(
    validate_dict(d, strict = TRUE),
    regexp = "all.*checks passed"
  )
})

# ---------------------------------------------------------------------------
# strict = FALSE: collects all failures, returns named list, warns not errors
# ---------------------------------------------------------------------------

test_that("validate_dict() with strict=FALSE returns list and warns on failure", {
  d <- make_valid_dict()
  # Add a second active Feature so that corrupting type[1] does not also
  # trigger the at_least_one_active_feature check (which would produce a
  # second, unexpected warning and cause the test to fail).
  extra_feature <- data.frame(
    nameCommon = "Feature C", nameVariable = "feature_C",
    category = "Habitat", categoryID = "Hab", type = "Feature",
    targetInitial = 30, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE,
    units = "", justification = "Stub C.",
    stringsAsFactors = FALSE
  )
  d <- rbind(d, extra_feature)
  d$type[1] <- "feature"  # unknown type — feature_C keeps Check 5 passing
  expect_warning(
    result <- suppressMessages(validate_dict(d, strict = FALSE)),
    regexp = "Dict_type_values_known"
  )
  expect_type(result, "list")
  expect_false(isTRUE(result[["Dict_type_values_known"]]))
})

test_that("validate_dict() with strict=FALSE continues past first failure", {
  d <- make_valid_dict()
  d$type[1]        <- "feature"  # check 3 failure
  d$includeApp     <- as.integer(d$includeApp)  # check 2 failure
  result <- suppressWarnings(suppressMessages(validate_dict(d, strict = FALSE)))
  expect_false(isTRUE(result[["includeApp_is_logical"]]))
  expect_false(isTRUE(result[["Dict_type_values_known"]]))
})
