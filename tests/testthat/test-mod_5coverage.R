# tests/testthat/test-mod_5coverage.R
#
# Tests for mod_5coverage_ui() and mod_5coverage_server().
# cfg is built from the stub sysdata.rda objects in the package namespace.

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

testServer(
  mod_5coverage_server,
  args = list(cfg = cfg),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl(id, ns("")))
    expect_true(grepl("test", ns("test")))
  }
)

test_that("mod_5coverage_ui() works", {
  ui <- mod_5coverage_ui(id = "test", cfg = cfg)
  # mod_5coverage_ui returns a sidebarLayout (shiny.tag), not a tagList
  expect_s3_class(ui, "shiny.tag")
  # Check that formals contain id and cfg
  fmls <- formals(mod_5coverage_ui)
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_5coverage_server() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_5coverage_server)
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})
