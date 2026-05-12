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
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_3compare_server() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_3compare_server)
  expect_true("id"  %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})
