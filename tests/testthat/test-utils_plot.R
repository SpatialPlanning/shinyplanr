# tests/testthat/test-utils_plot.R
#
# Tests for utils_plot.R:
#   fSolnText()             — pure text computation, no Shiny/spatialplanr needed
#   fplot_climate_density() — guard clause (no climate data → NULL)
#
# Design rationale
# ----------------
# fSolnText() is a pure function: it takes an sf object and returns a list of
# character strings. All branches can be exercised with synthetic sf objects.
#
# fplot_climate_density() calls spatialplanr::splnr_plot_climKernelDensity()
# which requires real solution data. We only test the guard clause (all
# climate_ids == "NA" → returns NULL) which is pure logic.
#
# fplot_solution_with_constraints() and create_climDataPlot() both require
# spatialplanr and ggplot2 rendering; they are integration-level and are
# excluded from unit tests here.

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

make_soln_sf <- function(n_selected = 2L, n_total = 5L, include_cost = TRUE) {
  solution_col <- c(rep(1L, n_selected), rep(0L, n_total - n_selected))
  cost_col     <- rep(10, n_total)

  geoms <- sf::st_sfc(
    lapply(seq_len(n_total), function(i) {
      sf::st_polygon(list(cbind(
        c(i - 1, i, i, i - 1, i - 1),
        c(0, 0, 1, 1, 0)
      )))
    }),
    crs = "EPSG:4326"
  )

  if (include_cost) {
    sf::st_sf(solution_1 = solution_col, Cost_Area = cost_col, geometry = geoms)
  } else {
    sf::st_sf(solution_1 = solution_col, geometry = geoms)
  }
}

# ---------------------------------------------------------------------------
# fSolnText() — NULL / non-sf guard
# ---------------------------------------------------------------------------

test_that("fSolnText() returns fallback message when soln is NULL", {
  result <- shinyplanr:::fSolnText(input = list(), sDat = NULL,
                                    cost_name = "Cost_Area")

  expect_type(result, "list")
  expect_length(result, 2L)
  expect_match(result[[1]], "No solution")
  expect_null(result[[2]])
})

test_that("fSolnText() returns fallback message when soln is not an sf object", {
  result <- shinyplanr:::fSolnText(input = list(), sDat = data.frame(x = 1),
                                    cost_name = "Cost_Area")

  expect_type(result, "list")
  expect_match(result[[1]], "No solution")
})

# ---------------------------------------------------------------------------
# fSolnText() — missing solution column
# ---------------------------------------------------------------------------

test_that("fSolnText() returns 'No solution text available' when col_name absent", {
  soln <- make_soln_sf()
  # Rename solution_1 so the default col_name is missing
  names(soln)[names(soln) == "solution_1"] <- "solution_renamed"

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = "Cost_Area",
                                    col_name  = "solution_1")

  expect_match(result[[1]], "No solution text available")
  expect_null(result[[2]])
})

# ---------------------------------------------------------------------------
# fSolnText() — happy path without cost
# ---------------------------------------------------------------------------

test_that("fSolnText() returns selection percentage text when no cost column", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = NULL)

  expect_type(result, "list")
  expect_length(result, 2L)
  # 2 of 5 = 40%
  expect_match(result[[1]], "40")
  expect_null(result[[2]])
})

test_that("fSolnText() computes correct selection percentage", {
  # 3 of 5 selected = 60%
  soln <- make_soln_sf(n_selected = 3L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = NULL)

  expect_match(result[[1]], "60")
})

# ---------------------------------------------------------------------------
# fSolnText() — happy path with cost
# ---------------------------------------------------------------------------

test_that("fSolnText() returns both solution and cost text when cost column present", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = TRUE)

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = "Cost_Area")

  expect_type(result, "list")
  expect_length(result, 2L)
  expect_type(result[[1]], "character")
  expect_type(result[[2]], "character")
  # Cost text should mention percentage
  expect_match(result[[2]], "%")
})

test_that("fSolnText() cost text: outside cost percentage is correct", {
  # 2 selected (cost = 10 each), 3 not selected (cost = 10 each)
  # total cost = 50, outside cost = 30 → 60%
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = TRUE)

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = "Cost_Area")

  expect_match(result[[2]], "60")
})

test_that("fSolnText() returns NULL cost text when cost_name not in solution", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(input = list(), sDat = soln,
                                    cost_name = "Cost_Area")  # column absent

  expect_null(result[[2]])
})

# ---------------------------------------------------------------------------
# fplot_climate_density() — guard clause: no climate data → NULL
# ---------------------------------------------------------------------------

test_that("fplot_climate_density() returns NULL when all climate_ids are 'NA'", {
  # Minimal sf objects — content doesn't matter because we never reach the
  # spatialplanr call when all climate IDs are the sentinel "NA" string.
  dummy_soln <- make_soln_sf()

  result <- shinyplanr:::fplot_climate_density(
    soln_list    = list(dummy_soln),
    climate_ids  = "NA"
  )

  expect_null(result)
})

test_that("fplot_climate_density() returns NULL when all elements of climate_ids are 'NA'", {
  dummy_soln <- make_soln_sf()

  result <- shinyplanr:::fplot_climate_density(
    soln_list    = list(dummy_soln, dummy_soln),
    climate_ids  = c("NA", "NA")
  )

  expect_null(result)
})
