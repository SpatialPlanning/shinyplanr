# tests/testthat/test-load_config.R
#
# Tests for load_config() and .validate_config()
# Uses temporary RDS files — no real region data required.

# ---------------------------------------------------------------------------
# Helpers: build a minimal valid config matching schema v1
# ---------------------------------------------------------------------------

make_valid_config <- function() {
  Dict <- data.frame(
    nameCommon    = c("Feature A"),
    nameVariable  = c("feature_A"),
    category      = c("Habitat"),
    categoryID    = c("Hab"),
    type          = c("Feature"),
    targetInitial = c(30),
    targetMin     = c(0),
    targetMax     = c(85),
    includeApp    = c(TRUE),
    includeJust   = c(TRUE),
    units         = c(""),
    justification = c("A stub feature."),
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
      Vars1          = fcreate_vars("3compare_ui_1", Dict, "sli_",  categoryOut = TRUE),
      Vars2          = fcreate_vars("3compare_ui_1", Dict, "sli2_", categoryOut = TRUE),
      check_lockIn1  = fcreate_check("3compare_ui_1", Dict, "LockIn",  "check1LI_", categoryOut = TRUE),
      check_lockIn2  = fcreate_check("3compare_ui_1", Dict, "LockIn",  "check2LI_", categoryOut = TRUE),
      check_lockOut1 = fcreate_check("3compare_ui_1", Dict, "LockOut", "check1LO_", categoryOut = TRUE),
      check_lockOut2 = fcreate_check("3compare_ui_1", Dict, "LockOut", "check2LO_", categoryOut = TRUE)
    )
  )
  list(
    schema_version = 2L,
    options        = list(
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
    map_theme      = ggplot2::theme_bw(),
    bar_theme      = ggplot2::theme_bw(),
    Dict           = Dict,
    raw_sf         = sf::st_sf(
      feature_A = c(0.8, 0.2),
      geometry  = sf::st_sfc(
        sf::st_polygon(list(cbind(c(0,1,1,0,0), c(0,0,1,1,0)))),
        sf::st_polygon(list(cbind(c(1,2,2,1,1), c(0,0,1,1,0)))),
        crs = "ESRI:54009"
      )
    ),
    bndry          = sf::st_sf(
      geometry = sf::st_sfc(
        sf::st_polygon(list(cbind(c(0,2,2,0,0), c(0,0,1,1,0)))),
        crs = "ESRI:54009"
      )
    ),
    overlay        = sf::st_sf(geometry = sf::st_sfc(crs = "ESRI:54009")),
    sidebar        = sidebar,
    tx             = list(
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
# .validate_config() — internal, accessed via :::
# ---------------------------------------------------------------------------

test_that(".validate_config() passes for a valid config", {
  cfg <- make_valid_config()
  expect_true(shinyplanr:::.validate_config(cfg, "test_path.rds"))
})

test_that(".validate_config() stops when schema_version is wrong", {
  cfg <- make_valid_config()
  cfg$schema_version <- 999L
  expect_error(
    shinyplanr:::.validate_config(cfg, "test_path.rds"),
    regexp = "schema version"
  )
})

test_that(".validate_config() stops when schema_version is NULL", {
  cfg <- make_valid_config()
  cfg$schema_version <- NULL
  expect_error(
    shinyplanr:::.validate_config(cfg, "test_path.rds"),
    regexp = "schema version"
  )
})

test_that(".validate_config() stops when required keys are missing", {
  cfg <- make_valid_config()
  cfg$Dict <- NULL
  cfg$raw_sf <- NULL
  expect_error(
    shinyplanr:::.validate_config(cfg, "test_path.rds"),
    regexp = "missing required keys"
  )
})

test_that(".validate_config() stops when config is not a list", {
  expect_error(
    shinyplanr:::.validate_config("not_a_list", "test_path.rds"),
    regexp = "valid list"
  )
})

# ---------------------------------------------------------------------------
# load_config() — exported
# ---------------------------------------------------------------------------

test_that("load_config() stops with clear error when file does not exist", {
  expect_error(
    load_config("nonexistent/path/config.rds"),
    regexp = "Config file not found"
  )
})

test_that("load_config() reads a valid config and assigns objects to config env", {
  cfg <- make_valid_config()
  tmp <- tempfile(fileext = ".rds")
  saveRDS(cfg, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_message(
    load_config(tmp),
    regexp = "shinyplanr config loaded"
  )

  # Check that key objects were assigned into shinyplanr_config (not namespace)
  cfg_env <- shinyplanr:::shinyplanr_config
  expect_true(exists("options",  envir = cfg_env, inherits = FALSE))
  expect_true(exists("Dict",     envir = cfg_env, inherits = FALSE))
  expect_true(exists("raw_sf",   envir = cfg_env, inherits = FALSE))
  expect_true(exists("tx",       envir = cfg_env, inherits = FALSE))
})

test_that("load_config() invisibly returns the config list", {
  cfg <- make_valid_config()
  tmp <- tempfile(fileext = ".rds")
  saveRDS(cfg, tmp)
  on.exit(unlink(tmp), add = TRUE)

  result <- suppressMessages(load_config(tmp))
  expect_type(result, "list")
  expect_equal(result$schema_version, 2L)
  expect_equal(result$options$app_title, "Test App")
})

test_that("load_config() normalises stale agr so dplyr::select keeps geometry", {
  # Reproduce the stale-agr condition: build an sf via st_set_geometry() which
  # sets agr to all-NA, then corrupt the factor so it behaves as if loaded from
  # an RDS saved in a different R session.
  plain_df <- data.frame(feature_A = c(0.8, 0.2))
  geom <- sf::st_sfc(
    sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
    sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
    crs = "ESRI:54009"
  )
  # st_set_geometry produces agr = NA (all-NA factor) — the stale state
  stale_sf <- sf::st_set_geometry(plain_df, geom)

  cfg <- make_valid_config()
  cfg$raw_sf <- stale_sf

  tmp <- tempfile(fileext = ".rds")
  saveRDS(cfg, tmp)
  on.exit(unlink(tmp), add = TRUE)

  suppressMessages(load_config(tmp))

  # After load_config, raw_sf in the config env must have a clean agr so that
  # dplyr::select keeps geometry stickily (the bug that caused the crashes).
  loaded_sf <- shinyplanr:::shinyplanr_config$raw_sf
  selected  <- dplyr::select(loaded_sf, "feature_A")
  expect_true(
    inherits(selected, "sf"),
    label = "dplyr::select keeps geometry after load_config normalises agr"
  )
  expect_true(
    attr(loaded_sf, "sf_column") %in% names(selected),
    label = "geometry column present after select"
  )
})
