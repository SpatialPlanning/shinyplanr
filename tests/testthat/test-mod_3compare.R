# tests/testthat/test-mod_3compare.R
#
# Tests for mod_3compare_ui() and mod_3compare_server().
# cfg is built from the stub sysdata.rda objects in the package namespace.

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

testServer(
  mod_3compare_server,
  args = list(cfg = cfg),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl(id, ns("")))
    expect_true(grepl("test", ns("test")))
  }
)

test_that("mod_3compare_ui() works", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  golem::expect_shinytag(ui)
  # Check that formals contain id and cfg
  fmls <- formals(mod_3compare_ui)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_3compare_server() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_3compare_server)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

# ---------------------------------------------------------------------------
# Copy-targets buttons
# ---------------------------------------------------------------------------

test_that("mod_3compare_ui() contains copyFromScen1 and copyFromScen2 buttons", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_true(grepl("copyFromScen1", html))
  expect_true(grepl("copyFromScen2", html))
})

test_that("mod_3compare_ui() copy buttons have expected labels", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_true(grepl("Match Scenario 1", html))
  expect_true(grepl("Match Scenario 2", html))
})

test_that("mod_3compare_server() copyFromScen1 button input exists in server", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg),
    {
      # Verify the server can receive the copyFromScen1 input without error
      expect_no_error(session$setInputs(copyFromScen1 = 1L))
    }
  )
})

test_that("mod_3compare_server() copyFromScen2 button input exists in server", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg),
    {
      # Verify the server can receive the copyFromScen2 input without error
      expect_no_error(session$setInputs(copyFromScen2 = 1L))
    }
  )
})

# ---------------------------------------------------------------------------
# Climate-smart approach controls (visible_climateOptions)
# ---------------------------------------------------------------------------

test_that("mod_3compare_ui() does not render climate-options controls when visible_climateOptions is FALSE", {
  cfg_clim <- cfg
  cfg_clim$options <- modifyList(
    cfg$options,
    list(include_climateChange = TRUE, visible_climateOptions = FALSE)
  )

  ui <- mod_3compare_ui(id = "test_clim_hidden", cfg = cfg_clim)
  html <- as.character(ui)
  expect_false(grepl("climate_change1", html, fixed = TRUE))
  expect_false(grepl("climate_change2", html, fixed = TRUE))
  expect_false(grepl("refugiaTarget1", html, fixed = TRUE))
  expect_false(grepl("refugiaTarget2", html, fixed = TRUE))
})

test_that("mod_3compare_ui() renders independent climate-options controls for both scenarios when visible_climateOptions is TRUE", {
  cfg_clim <- cfg
  cfg_clim$options <- modifyList(
    cfg$options,
    list(include_climateChange = TRUE, visible_climateOptions = TRUE)
  )

  ui <- mod_3compare_ui(id = "test_clim_visible", cfg = cfg_clim)
  html <- as.character(ui)
  expect_match(html, "climate_change1", fixed = TRUE)
  expect_match(html, "climate_change2", fixed = TRUE)
  expect_match(html, "percentile1", fixed = TRUE)
  expect_match(html, "percentile2", fixed = TRUE)
  expect_match(html, "direction1", fixed = TRUE)
  expect_match(html, "direction2", fixed = TRUE)
  expect_match(html, "refugiaTarget1", fixed = TRUE)
  expect_match(html, "refugiaTarget2", fixed = TRUE)
})
