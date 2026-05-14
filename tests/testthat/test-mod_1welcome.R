# tests/testthat/test-mod_1welcome.R
#
# Meaningful tests for mod_1welcome_ui() and mod_1welcome_server().
# cfg is built from the stub sysdata.rda objects (populated by load_config()
# in tests/testthat/setup.R or the namespace stubs).

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

# ---------------------------------------------------------------------------
# UI structure tests
# ---------------------------------------------------------------------------

test_that("mod_1welcome_ui() returns a shiny tag list", {
  ui <- mod_1welcome_ui(id = "test", cfg = cfg)
  golem::expect_shinytaglist(ui)
})

test_that("mod_1welcome_ui() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_1welcome_ui)
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_1welcome_ui() renders without error using stub cfg", {
  expect_no_error(mod_1welcome_ui(id = "test", cfg = cfg))
})

test_that("mod_1welcome_ui() produces HTML containing a footer div", {
  ui   <- mod_1welcome_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "home-footer", fixed = TRUE)
})

test_that("mod_1welcome_ui() includes a funder logo image tag", {
  ui   <- mod_1welcome_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "logo_funder\\.png", perl = TRUE)
})

test_that("mod_1welcome_ui() shows UQ logo when options$show_uq_logo is TRUE", {
  cfg_uq <- cfg
  cfg_uq$options <- modifyList(cfg$options, list(show_uq_logo = TRUE))

  ui   <- mod_1welcome_ui(id = "test_uq", cfg = cfg_uq)
  html <- as.character(ui)
  expect_match(html, "uq-logo-white\\.png", perl = TRUE)
})

test_that("mod_1welcome_ui() hides UQ logo when options$show_uq_logo is FALSE", {
  cfg_nouq <- cfg
  cfg_nouq$options <- modifyList(cfg$options, list(show_uq_logo = FALSE))

  ui   <- mod_1welcome_ui(id = "test_nouq", cfg = cfg_nouq)
  html <- as.character(ui)
  expect_false(grepl("uq-logo-white\\.png", html))
})

test_that("mod_1welcome_ui() renders a tabsetPanel when tx$welcome has multiple entries", {
  cfg_multi <- cfg
  cfg_multi$tx <- list(
    welcome = list(
      list(title = "Tab 1", text = "# First tab"),
      list(title = "Tab 2", text = "# Second tab")
    )
  )

  ui   <- mod_1welcome_ui(id = "test_multi", cfg = cfg_multi)
  html <- as.character(ui)
  expect_match(html, "nav nav-pills", fixed = TRUE)
})

test_that("mod_1welcome_ui() renders plain div when tx$welcome has a single entry", {
  cfg_single <- cfg
  cfg_single$tx <- list(
    welcome = list(
      list(title = "Welcome", text = "# Hello")
    )
  )

  ui   <- mod_1welcome_ui(id = "test_single", cfg = cfg_single)
  html <- as.character(ui)
  # A single entry is rendered without a tabsetPanel
  expect_false(grepl("nav nav-pills", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Server tests
# ---------------------------------------------------------------------------

test_that("mod_1welcome_server() has correct formals including 'cfg'", {
  fmls <- formals(mod_1welcome_server)
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

testServer(mod_1welcome_server, args = list(cfg = cfg), {
  ns <- session$ns
  expect_true(inherits(ns, "function"))
  expect_true(grepl(id, ns("")))
  expect_true(grepl("test", ns("test")))
})
