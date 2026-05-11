# tests/testthat/test-mod_2scenario.R
#
# Meaningful tests for mod_2scenario_ui() and mod_2scenario_server().
# Uses the stub sysdata.rda (options, Dict, raw_sf, etc.) already in the namespace.

# ---------------------------------------------------------------------------
# UI structure tests
# ---------------------------------------------------------------------------

test_that("mod_2scenario_ui() returns a shiny tag (sidebarLayout)", {
  ui <- mod_2scenario_ui(id = "test")
  golem::expect_shinytag(ui)
})

test_that("mod_2scenario_ui() formals contain 'id'", {
  fmls <- formals(mod_2scenario_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_2scenario_ui() renders without error using stub namespace data", {
  expect_no_error(mod_2scenario_ui(id = "test"))
})

test_that("mod_2scenario_ui() contains the 'Run Analysis' button", {
  ui   <- mod_2scenario_ui(id = "test")
  html <- as.character(ui)
  expect_match(html, "Run Analysis", fixed = TRUE)
})

test_that("mod_2scenario_ui() contains the cost layer select input", {
  ui   <- mod_2scenario_ui(id = "test")
  html <- as.character(ui)
  expect_match(html, "costid", fixed = TRUE)
})

test_that("mod_2scenario_ui() has expected main-panel tabs", {
  ui   <- mod_2scenario_ui(id = "test")
  html <- as.character(ui)

  # Core tabs that should always be present
  expect_match(html, "Scenario", fixed = TRUE)
  expect_match(html, "Explore",  fixed = TRUE)
  expect_match(html, "Targets",  fixed = TRUE)
  expect_match(html, "Cost",     fixed = TRUE)
  expect_match(html, "Details",  fixed = TRUE)
  expect_match(html, "Log",      fixed = TRUE)
})

test_that("mod_2scenario_ui() has download buttons for Scenario and Targets tabs", {
  ui   <- mod_2scenario_ui(id = "test")
  html <- as.character(ui)
  expect_match(html, "dlPlot1", fixed = TRUE)
  expect_match(html, "dlPlot2", fixed = TRUE)
})

test_that("mod_2scenario_ui() shows master slider panel when targetsBy is 'master'", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(targetsBy = "master"))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- mod_2scenario_ui(id = "test_master")
  html <- as.character(ui)
  expect_match(html, "switchMasterTargets", fixed = TRUE)
})

test_that("mod_2scenario_ui() shows climate panel when include_climateChange is TRUE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(include_climateChange = TRUE))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- mod_2scenario_ui(id = "test_clim")
  html <- as.character(ui)
  expect_match(html, "switchClimSmart", fixed = TRUE)
  expect_match(html, "climateid",       fixed = TRUE)
})

# ---------------------------------------------------------------------------
# Server tests
# ---------------------------------------------------------------------------

test_that("mod_2scenario_server() has correct formals", {
  fmls <- formals(mod_2scenario_server)
  expect_true("id" %in% names(fmls))
})

testServer(mod_2scenario_server, args = list(), {
  ns <- session$ns
  expect_true(inherits(ns, "function"))
  expect_true(grepl(id, ns("")))
  expect_true(grepl("test", ns("test")))
})
