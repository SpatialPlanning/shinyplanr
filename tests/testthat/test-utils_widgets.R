# tests/testthat/test-utils_widgets.R
#
# Tests for utils_widgets.R:
#   get_lockIn()   — pure logic: filters input names and strips prefix
#   get_lockOut()  — pure logic: filters input names and strips prefix
#
# Design rationale
# ----------------
# get_lockIn() and get_lockOut() take a Shiny input list and a numeric suffix
# string. They are pure in the sense that they only read from the input list
# (no session, no observers, no side-effects). We can therefore test them by
# passing a plain named list that mimics a Shiny input object.
#
# fupdate_checkbox() and fresetSlider() require a live Shiny session object
# (shiny::updateCheckboxGroupInput / shiny::updateSliderInput). They are
# excluded from unit tests here.
#
# Coverage gap: the coverage report shows get_lockIn() and get_lockOut() at
# 0% because the existing tests only exercise fget_targets() and
# fget_targets_with_bioregions(). These tests close that gap.

# ---------------------------------------------------------------------------
# get_lockIn() — no locked-in inputs
# ---------------------------------------------------------------------------

test_that("get_lockIn() returns empty character vector when no checkLI_ inputs exist", {
  input <- list(sli_feature_A = 30, sli_feature_B = 50)

  result <- shinyplanr:::get_lockIn(input, num = "")

  expect_type(result, "character")
  expect_length(result, 0L)
})

# ---------------------------------------------------------------------------
# get_lockIn() — some inputs present but none selected (FALSE)
# ---------------------------------------------------------------------------

test_that("get_lockIn() returns empty vector when all checkLI_ inputs are FALSE", {
  input <- list(
    checkLI_mpas    = FALSE,
    checkLI_reserves = FALSE,
    sli_feature_A   = 30
  )

  result <- shinyplanr:::get_lockIn(input, num = "")

  expect_length(result, 0L)
})

# ---------------------------------------------------------------------------
# get_lockIn() — selected inputs
# ---------------------------------------------------------------------------

test_that("get_lockIn() returns nameVariable for selected checkLI_ inputs", {
  input <- list(
    checkLI_mpas     = TRUE,
    checkLI_reserves = FALSE,
    sli_feature_A    = 30
  )

  result <- shinyplanr:::get_lockIn(input, num = "")

  expect_equal(result, "mpas")
})

test_that("get_lockIn() returns multiple nameVariables when multiple inputs selected", {
  input <- list(
    checkLI_mpas     = TRUE,
    checkLI_reserves = TRUE,
    checkLI_other    = FALSE
  )

  result <- shinyplanr:::get_lockIn(input, num = "")

  expect_length(result, 2L)
  expect_setequal(result, c("mpas", "reserves"))
})

# ---------------------------------------------------------------------------
# get_lockIn() — num suffix for comparison module
# ---------------------------------------------------------------------------

test_that("get_lockIn() respects num suffix for comparison module (num = '1')", {
  input <- list(
    check1LI_mpas     = TRUE,
    check1LI_reserves = FALSE,
    checkLI_mpas      = TRUE   # scenario module input — should be ignored
  )

  result <- shinyplanr:::get_lockIn(input, num = "1")

  expect_equal(result, "mpas")
  expect_length(result, 1L)
})

test_that("get_lockIn() with num = '2' only matches check2LI_ prefix", {
  input <- list(
    check2LI_mpas = TRUE,
    check1LI_mpas = TRUE   # different suffix — should be ignored
  )

  result <- shinyplanr:::get_lockIn(input, num = "2")

  expect_equal(result, "mpas")
  expect_length(result, 1L)
})

# ---------------------------------------------------------------------------
# get_lockOut() — no locked-out inputs
# ---------------------------------------------------------------------------

test_that("get_lockOut() returns empty character vector when no checkLO_ inputs exist", {
  input <- list(sli_feature_A = 30)

  result <- shinyplanr:::get_lockOut(input, num = "")

  expect_type(result, "character")
  expect_length(result, 0L)
})

# ---------------------------------------------------------------------------
# get_lockOut() — some inputs present but none selected
# ---------------------------------------------------------------------------

test_that("get_lockOut() returns empty vector when all checkLO_ inputs are FALSE", {
  input <- list(
    checkLO_mpas     = FALSE,
    checkLO_reserves = FALSE
  )

  result <- shinyplanr:::get_lockOut(input, num = "")

  expect_length(result, 0L)
})

# ---------------------------------------------------------------------------
# get_lockOut() — selected inputs
# ---------------------------------------------------------------------------

test_that("get_lockOut() returns nameVariable for selected checkLO_ inputs", {
  input <- list(
    checkLO_mpas     = TRUE,
    checkLO_reserves = FALSE
  )

  result <- shinyplanr:::get_lockOut(input, num = "")

  expect_equal(result, "mpas")
})

test_that("get_lockOut() returns multiple nameVariables when multiple inputs selected", {
  input <- list(
    checkLO_mpas     = TRUE,
    checkLO_reserves = TRUE,
    checkLO_other    = FALSE
  )

  result <- shinyplanr:::get_lockOut(input, num = "")

  expect_length(result, 2L)
  expect_setequal(result, c("mpas", "reserves"))
})

# ---------------------------------------------------------------------------
# get_lockOut() — num suffix for comparison module
# ---------------------------------------------------------------------------

test_that("get_lockOut() respects num suffix for comparison module (num = '1')", {
  input <- list(
    check1LO_mpas = TRUE,
    checkLO_mpas  = TRUE   # scenario module input — should be ignored
  )

  result <- shinyplanr:::get_lockOut(input, num = "1")

  expect_equal(result, "mpas")
  expect_length(result, 1L)
})

# ---------------------------------------------------------------------------
# Symmetry: get_lockIn and get_lockOut are independent
# ---------------------------------------------------------------------------

test_that("get_lockIn() does not pick up checkLO_ inputs", {
  input <- list(
    checkLO_mpas = TRUE,
    checkLI_mpas = FALSE
  )

  result <- shinyplanr:::get_lockIn(input, num = "")

  expect_length(result, 0L)
})

test_that("get_lockOut() does not pick up checkLI_ inputs", {
  input <- list(
    checkLI_mpas = TRUE,
    checkLO_mpas = FALSE
  )

  result <- shinyplanr:::get_lockOut(input, num = "")

  expect_length(result, 0L)
})
