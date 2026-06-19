# tests/testthat/test-utils_server_extra.R
#
# Tests for utils_server.R functions not covered in test-utils_server.R:
#   fdownload_solution_geojson() — sf I/O, no Shiny session needed
#
# Design rationale
# ----------------
# fdownload_solution_geojson() is a pure I/O function: it takes an sf object
# and a file path, transforms to WGS84, renames the solution column, and
# writes GeoJSON. All branches can be exercised without a Shiny session by
# passing a temp file path directly.
#
# frender_report(), fmake_tab_cache(), fsetup_lock_observers(), and
# fapply_ui_switches() all require a live Shiny session (shinyjs, shiny
# observers, session object). They are excluded from unit tests here — their
# logic is exercised indirectly through the module integration tests.
#
# fDownloadPlotServer() wraps shiny::downloadHandler() and also requires a
# session; excluded for the same reason.

# ---------------------------------------------------------------------------
# fdownload_solution_geojson() — guard: not an sf object
# ---------------------------------------------------------------------------

test_that("fdownload_solution_geojson() stops when sol is not an sf object", {
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  # The function calls shiny::showNotification() then stop(). Outside a Shiny
  # session, showNotification() itself errors before stop() is reached, but the
  # function still throws — we just check that it errors at all.
  expect_error(
    shinyplanr:::fdownload_solution_geojson(sol = list(), file = tmp)
  )
})

test_that("fdownload_solution_geojson() stops when sol is NULL", {
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  expect_error(
    shinyplanr:::fdownload_solution_geojson(sol = NULL, file = tmp)
  )
})

# ---------------------------------------------------------------------------
# fdownload_solution_geojson() — column normalisation
# ---------------------------------------------------------------------------

make_soln_sf <- function(col_name = "solution_1", crs = "ESRI:54009") {
  # Use setNames() to avoid requiring rlang's := operator outside dplyr context
  geom <- sf::st_sfc(
    sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
    sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
    sf::st_polygon(list(cbind(c(2, 3, 3, 2, 2), c(0, 0, 1, 1, 0)))),
    crs = crs
  )
  df <- setNames(data.frame(c(1L, 0L, 1L)), col_name)
  sf::st_sf(df, geometry = geom)
}

test_that("fdownload_solution_geojson() writes a valid GeoJSON file", {
  sol <- make_soln_sf("solution_1")
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  expect_true(file.exists(tmp))
  written <- sf::st_read(tmp, quiet = TRUE)
  expect_s3_class(written, "sf")
})

test_that("fdownload_solution_geojson() renames solution_1 to solution", {
  sol <- make_soln_sf("solution_1")
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  written <- sf::st_read(tmp, quiet = TRUE)
  expect_true("solution" %in% names(written))
  expect_false("solution_1" %in% names(written))
})

test_that("fdownload_solution_geojson() keeps existing 'solution' column unchanged", {
  sol <- make_soln_sf("solution")  # already named 'solution'
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  written <- sf::st_read(tmp, quiet = TRUE)
  expect_true("solution" %in% names(written))
})

test_that("fdownload_solution_geojson() adds NA solution column when neither column exists", {
  # sf with no solution or solution_1 column
  sol <- sf::st_sf(
    other_col = c(1L, 0L),
    geometry  = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  written <- sf::st_read(tmp, quiet = TRUE)
  expect_true("solution" %in% names(written))
  expect_true(all(is.na(written$solution)))
})

# ---------------------------------------------------------------------------
# fdownload_solution_geojson() — CRS transformation
# ---------------------------------------------------------------------------

test_that("fdownload_solution_geojson() transforms output to EPSG:4326", {
  # Input in Mollweide (ESRI:54009)
  sol <- make_soln_sf("solution_1", crs = "ESRI:54009")
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  written <- sf::st_read(tmp, quiet = TRUE)
  # GeoJSON round-trips embed WKT, so the CRS input string differs from
  # "EPSG:4326" even though the authority code is the same. Compare via
  # sf::st_crs()$epsg which is robust to WKT representation differences.
  expect_equal(sf::st_crs(written)$epsg, 4326L)
})

test_that("fdownload_solution_geojson() output contains only the solution column", {
  # Input has multiple columns; output should only have 'solution' + geometry
  sol <- make_soln_sf("solution_1")
  sol$extra_col <- c(1, 2, 3)
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  shinyplanr:::fdownload_solution_geojson(sol = sol, file = tmp)

  written    <- sf::st_read(tmp, quiet = TRUE)
  data_cols  <- setdiff(names(written), attr(written, "sf_column"))
  expect_equal(data_cols, "solution")
})
