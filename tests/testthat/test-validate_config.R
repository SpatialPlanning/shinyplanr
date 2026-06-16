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
      show_uq_logo          = FALSE,
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
