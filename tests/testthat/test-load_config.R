# tests/testthat/test-load_config.R
#
# Tests for load_config() and .validate_config()
# Uses temporary RDS files — no real region data required.

# ---------------------------------------------------------------------------
# Helpers: build a minimal valid config matching schema v1
# ---------------------------------------------------------------------------

make_valid_config <- function() {
  list(
    schema_version = 1L,
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
      include_bioregion     = FALSE,
      show_uq_logo          = FALSE,
      include_climateChange = FALSE,
      climate_change        = 0L,
      include_lockedArea    = FALSE,
      targetsBy             = "individual",
      obj_func              = "min_set",
      cCRS                  = "ESRI:54009"
    ),
    map_theme      = ggplot2::theme_bw(),
    bar_theme      = ggplot2::theme_bw(),
    Dict           = data.frame(
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
    ),
    vars           = "feature_A",
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

test_that("load_config() reads a valid config and assigns objects to namespace", {
  cfg <- make_valid_config()
  tmp <- tempfile(fileext = ".rds")
  saveRDS(cfg, tmp)
  on.exit(unlink(tmp), add = TRUE)

  expect_message(
    load_config(tmp),
    regexp = "shinyplanr config loaded"
  )

  # Check that key objects were assigned into the namespace
  pkg_env <- asNamespace("shinyplanr")
  expect_true(exists("options",  envir = pkg_env, inherits = FALSE))
  expect_true(exists("Dict",     envir = pkg_env, inherits = FALSE))
  expect_true(exists("raw_sf",   envir = pkg_env, inherits = FALSE))
  expect_true(exists("tx",       envir = pkg_env, inherits = FALSE))
})

test_that("load_config() invisibly returns the config list", {
  cfg <- make_valid_config()
  tmp <- tempfile(fileext = ".rds")
  saveRDS(cfg, tmp)
  on.exit(unlink(tmp), add = TRUE)

  result <- suppressMessages(load_config(tmp))
  expect_type(result, "list")
  expect_equal(result$schema_version, 1L)
  expect_equal(result$options$app_title, "Test App")
})
