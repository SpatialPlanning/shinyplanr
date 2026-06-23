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
  cost_col <- rep(10, n_total)

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
  result <- shinyplanr:::fSolnText(
    input = list(), sDat = NULL,
    cost_name = "Cost_Area"
  )

  expect_type(result, "list")
  expect_length(result, 2L)
  expect_match(result[[1]], "No solution")
  expect_null(result[[2]])
})

test_that("fSolnText() returns fallback message when soln is not an sf object", {
  result <- shinyplanr:::fSolnText(
    input = list(), sDat = data.frame(x = 1),
    cost_name = "Cost_Area"
  )

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

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = "Cost_Area",
    col_name = "solution_1"
  )

  expect_match(result[[1]], "No solution text available")
  expect_null(result[[2]])
})

# ---------------------------------------------------------------------------
# fSolnText() — happy path without cost
# ---------------------------------------------------------------------------

test_that("fSolnText() returns selection percentage text when no cost column", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = NULL
  )

  expect_type(result, "list")
  expect_length(result, 2L)
  # 2 of 5 = 40%
  expect_match(result[[1]], "40")
  expect_null(result[[2]])
})

test_that("fSolnText() computes correct selection percentage", {
  # 3 of 5 selected = 60%
  soln <- make_soln_sf(n_selected = 3L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = NULL
  )

  expect_match(result[[1]], "60")
})

# ---------------------------------------------------------------------------
# fSolnText() — happy path with cost
# ---------------------------------------------------------------------------

test_that("fSolnText() returns both solution and cost text when cost column present", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = TRUE)

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = "Cost_Area"
  )

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

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = "Cost_Area"
  )

  expect_match(result[[2]], "60")
})

test_that("fSolnText() returns NULL cost text when cost_name not in solution", {
  soln <- make_soln_sf(n_selected = 2L, n_total = 5L, include_cost = FALSE)

  result <- shinyplanr:::fSolnText(
    input = list(), sDat = soln,
    cost_name = "Cost_Area"
  ) # column absent

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

# ---------------------------------------------------------------------------
# fplot_climate_density() — climate call path
#
# These tests exercise the actual spatialplanr call path and therefore require
# ggridges. They are skipped when ggridges is absent (e.g. minimal CI images).
#
# Architecture note: fplot_climate_density() calls
# spatialplanr::splnr_plot_climKernelDensity() once per active scenario
# (not once for all scenarios combined). Each call receives a single sf object.
# Multiple plots are stacked with patchwork::wrap_plots(ncol = 1).
#
# Key regression guarded: previously solution_names was passed as
# c("solution_1", "solution_2"), but prioritizr always names its output column
# "solution_1" regardless of scenario. Passing "solution_2" caused
# splnr_plot_climKernelDensity_Fancy() to assert-fail with:
#   "'soln' is missing the solution column 'solution_2'."
# ---------------------------------------------------------------------------

make_clim_soln_sf <- function(n_total = 10L, clim_col = "clim_metric") {
  # Build a minimal sf with solution_1 (0/1) and a named climate column.
  # Both columns are required by splnr_plot_climKernelDensity_Fancy().
  set.seed(42L)
  solution_col <- c(rep(1L, n_total %/% 2L), rep(0L, n_total - n_total %/% 2L))
  clim_vals <- stats::runif(n_total, min = 0, max = 1)

  geoms <- sf::st_sfc(
    lapply(seq_len(n_total), function(i) {
      sf::st_polygon(list(cbind(
        c(i - 1, i, i, i - 1, i - 1),
        c(0, 0, 1, 1, 0)
      )))
    }),
    crs = "EPSG:4326"
  )

  df <- data.frame(solution_1 = solution_col)
  df[[clim_col]] <- clim_vals
  sf::st_sf(df, geometry = geoms)
}

test_that("fplot_climate_density() does not error when only scenario 2 has climate (regression for solution_2 bug)", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")
  soln2 <- make_clim_soln_sf(clim_col = "clim_metric")

  # Scenario 1: no climate ("NA"); Scenario 2: has climate.
  # fplot_climate_density() filters to active scenarios and calls
  # splnr_plot_climKernelDensity() once with soln2 only.
  expect_no_error(
    shinyplanr:::fplot_climate_density(
      soln_list      = list(soln1, soln2),
      climate_ids    = c("NA", "clim_metric"),
      solution_names = c("solution_1", "solution_1")
    )
  )
})

test_that("fplot_climate_density() does not error when both scenarios have climate", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")
  soln2 <- make_clim_soln_sf(clim_col = "clim_metric")

  # Both active: two separate splnr_plot_climKernelDensity() calls, stacked
  # with patchwork::wrap_plots(ncol = 1).
  expect_no_error(
    shinyplanr:::fplot_climate_density(
      soln_list      = list(soln1, soln2),
      climate_ids    = c("clim_metric", "clim_metric"),
      solution_names = c("solution_1", "solution_1")
    )
  )
})

test_that("fplot_climate_density() returns a ggplot when a single scenario has climate", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")

  result <- shinyplanr:::fplot_climate_density(
    soln_list      = list(soln1),
    climate_ids    = "clim_metric",
    solution_names = "solution_1"
  )

  expect_true(inherits(result, "gg"))
})

test_that("fplot_climate_density() returns a patchwork when two scenarios have climate", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")
  soln2 <- make_clim_soln_sf(clim_col = "clim_metric")

  result <- shinyplanr:::fplot_climate_density(
    soln_list      = list(soln1, soln2),
    climate_ids    = c("clim_metric", "clim_metric"),
    solution_names = c("solution_1", "solution_1")
  )

  # patchwork objects inherit from "gg" and also from "patchwork"
  expect_true(inherits(result, "patchwork"))
})

test_that("fplot_climate_density() uses Dict nameCommon as axis label when Dict provided", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")

  # Minimal Dict with a Climate entry mapping clim_metric -> "SST Warming"
  test_dict <- data.frame(
    nameVariable = "clim_metric",
    nameCommon = "SST Warming",
    type = "Climate",
    stringsAsFactors = FALSE
  )

  result <- shinyplanr:::fplot_climate_density(
    soln_list      = list(soln1),
    climate_ids    = "clim_metric",
    solution_names = "solution_1",
    Dict           = test_dict
  )

  # The x-axis label should be the nameCommon, not the raw column name.
  # ggplot stores the x label in plot$labels$x.
  expect_equal(result$labels$x, "SST Warming")
})

test_that("fplot_climate_density() suppresses colour-bar title by default (legendTitle = NULL)", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")

  result <- shinyplanr:::fplot_climate_density(
    soln_list      = list(soln1),
    climate_ids    = "clim_metric",
    solution_names = "solution_1"
  )

  # ggplot2 stores scale names in the scales list.
  # scale_fill_viridis_c(name = NULL) leaves the name as NULL (no title).
  # We locate the fill scale and confirm its name is NULL.
  fill_scale <- Filter(
    function(s) inherits(s, "ScaleContinuous") && s$aesthetics[[1]] == "fill",
    result$scales$scales
  )
  expect_length(fill_scale, 1L)
  expect_null(fill_scale[[1]]$name)
})

test_that("fplot_climate_density() x-axis label falls back to raw climate_id when Dict is NULL", {
  skip_if_not_installed("ggridges")

  soln1 <- make_clim_soln_sf(clim_col = "clim_metric")

  result <- shinyplanr:::fplot_climate_density(
    soln_list      = list(soln1),
    climate_ids    = "clim_metric",
    solution_names = "solution_1"
    # Dict intentionally omitted
  )

  # Without a Dict the raw column name is used as the x-axis label.
  expect_equal(result$labels$x, "clim_metric")
})
