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
