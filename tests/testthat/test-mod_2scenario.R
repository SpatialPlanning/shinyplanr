# tests/testthat/test-mod_2scenario.R
#
# Meaningful tests for mod_2scenario_ui() and mod_2scenario_server().
# cfg is built from the stub sysdata.rda objects in the package namespace.

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

# ---------------------------------------------------------------------------
# UI structure tests
# ---------------------------------------------------------------------------

test_that("mod_2scenario_ui() returns a shiny tag (sidebarLayout)", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  golem::expect_shinytag(ui)
})

test_that("mod_2scenario_ui() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_2scenario_ui)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_2scenario_ui() renders without error using stub cfg", {
  expect_no_error(mod_2scenario_ui(id = "test", cfg = cfg))
})

test_that("mod_2scenario_ui() contains the 'Run Analysis' button", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "Run Analysis", fixed = TRUE)
})

test_that("mod_2scenario_ui() contains the cost layer select input", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "costid", fixed = TRUE)
})

test_that("mod_2scenario_ui() has expected main-panel tabs", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  html <- as.character(ui)

  # Core tabs that should always be present
  expect_match(html, "Scenario", fixed = TRUE)
  expect_match(html, "Explore", fixed = TRUE)
  expect_match(html, "Targets", fixed = TRUE)
  expect_match(html, "Cost", fixed = TRUE)
  expect_match(html, "Details", fixed = TRUE)
  expect_match(html, "Log", fixed = TRUE)
})

test_that("mod_2scenario_ui() has download buttons for Scenario and Targets tabs", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "dlPlot1", fixed = TRUE)
  expect_match(html, "dlPlot2", fixed = TRUE)
})

test_that("mod_2scenario_ui() contains the 'Download Report' button (dlReport)", {
  ui <- mod_2scenario_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "dlReport", fixed = TRUE)
  expect_match(html, "Download Report", fixed = TRUE)
})

test_that("mod_2scenario_ui() Report tab is always present in HTML regardless of include_report", {
  # The Report tab is always rendered in the HTML; server-side hideTab() controls
  # visibility at runtime based on options$include_report.
  cfg_no_report <- cfg
  cfg_no_report$options <- modifyList(cfg$options, list(include_report = FALSE))
  ui_no_report <- mod_2scenario_ui(id = "test_no_report", cfg = cfg_no_report)
  html_no_report <- as.character(ui_no_report)
  expect_match(html_no_report, "dlReport", fixed = TRUE)

  cfg_with_report <- cfg
  cfg_with_report$options <- modifyList(cfg$options, list(include_report = TRUE))
  ui_with_report <- mod_2scenario_ui(id = "test_with_report", cfg = cfg_with_report)
  html_with_report <- as.character(ui_with_report)
  expect_match(html_with_report, "dlReport", fixed = TRUE)
})

test_that("mod_2scenario_ui() shows master slider panel when targetsBy is 'master'", {
  cfg_master <- cfg
  cfg_master$options <- modifyList(cfg$options, list(targetsBy = "master"))

  ui <- mod_2scenario_ui(id = "test_master", cfg = cfg_master)
  html <- as.character(ui)
  expect_match(html, "switchMasterTargets", fixed = TRUE)
})

test_that("mod_2scenario_ui() shows climate panel when include_climateChange is TRUE", {
  cfg_clim <- cfg
  cfg_clim$options <- modifyList(cfg$options, list(include_climateChange = TRUE))

  ui <- mod_2scenario_ui(id = "test_clim", cfg = cfg_clim)
  html <- as.character(ui)
  expect_match(html, "Climate-smart", fixed = TRUE)
  expect_match(html, "climateid", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# Server tests
# ---------------------------------------------------------------------------

test_that("mod_2scenario_server() has correct formals including 'cfg'", {
  fmls <- formals(mod_2scenario_server)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

testServer(
  mod_2scenario_server,
  args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl(id, ns("")))
    expect_true(grepl("test", ns("test")))
  }
)

test_that("mod_2scenario_server() registers dlReport as a download handler", {
  testServer(
    mod_2scenario_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      # downloadHandler outputs are registered in the MockShinySession's private
      # $outs list (keyed as "proxy1-<name>"). We check this without triggering
      # a reactive flush (reading output$x directly flushes all pending observers,
      # which errors when inputs like slider_varsCat are NULL in the test context).
      mock_session <- .subset2(session$output, "impl")
      registered <- names(mock_session$.__enclos_env__$private$outs)
      expect_true(
        any(grepl("dlReport", registered)),
        info = paste("Registered outputs:", paste(registered, collapse = ", "))
      )
    }
  )
})
