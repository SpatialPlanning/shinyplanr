# tests/testthat/test-utils_coverage.R
#
# Tests for utils_coverage.R:
#   fread_uploaded_spatial()  — file validation logic (no real file I/O needed
#                               for the guard-clause branches)
#   fcalculate_coverage()     — pure spatial calculation, tested with synthetic
#                               sf objects
#
# Design rationale
# ----------------
# Both functions are pure (data in → data out) with no Shiny reactivity.
# fread_uploaded_spatial() has several guard clauses that can be exercised
# without touching the filesystem by passing NULL or a fake file_input list.
# The sf::st_read() branch is tested with a real temporary GeoPackage so that
# the happy-path and geometry-type checks are covered.
# fcalculate_coverage() is tested entirely with in-memory sf objects.

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

make_raw_sf <- function() {
  sf::st_sf(
    feature_A = c(1, 0, 1, 0, 1),
    feature_B = c(0, 1, 1, 0, 0),
    Cost_Area = c(1, 1, 1, 1, 1),
    geometry  = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(2, 3, 3, 2, 2), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(1, 1, 2, 2, 1)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(1, 1, 2, 2, 1)))),
      crs = "EPSG:4326"
    )
  )
}

make_dict <- function() {
  data.frame(
    nameCommon    = c("Feature A", "Feature B"),
    nameVariable  = c("feature_A", "feature_B"),
    category      = c("Habitat", "Habitat"),
    categoryID    = c("Hab", "Hab"),
    type          = c("Feature", "Feature"),
    targetInitial = c(30, 50),
    targetMin     = c(0, 0),
    targetMax     = c(85, 85),
    includeApp    = c(TRUE, TRUE),
    includeJust   = c(TRUE, TRUE),
    justification = c("A.", "B."),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# fread_uploaded_spatial() — guard clauses (no filesystem access)
# ---------------------------------------------------------------------------

test_that("fread_uploaded_spatial() returns failure when file_input is NULL", {
  result <- shinyplanr:::fread_uploaded_spatial(NULL)

  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$message, "No file provided")
})

test_that("fread_uploaded_spatial() returns failure when datapath is NULL", {
  result <- shinyplanr:::fread_uploaded_spatial(list(datapath = NULL, name = "test.gpkg"))

  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$message, "No file provided")
})

test_that("fread_uploaded_spatial() returns failure for unsupported file extension", {
  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = "/tmp/fake.shp", name = "fake.shp")
  )

  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$message, "Unsupported file format")
  expect_match(result$message, "\\.shp")
})

test_that("fread_uploaded_spatial() returns failure for .csv extension", {
  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = "/tmp/data.csv", name = "data.csv")
  )

  expect_false(result$success)
  expect_match(result$message, "Unsupported file format")
})

test_that("fread_uploaded_spatial() returns error message when file does not exist", {
  # .gpkg extension passes the format check but st_read() will fail
  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = "/nonexistent/path/file.gpkg", name = "file.gpkg")
  )

  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$message, "Error reading file")
})

test_that("fread_uploaded_spatial() accepts .geojson extension", {
  # Write a minimal GeoJSON to a temp file
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  poly <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
  sf::st_write(poly, tmp, driver = "GeoJSON", quiet = TRUE)

  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = tmp, name = "test.geojson")
  )

  expect_true(result$success)
  expect_s3_class(result$data, "sf")
  expect_null(result$message)
})

test_that("fread_uploaded_spatial() accepts .gpkg extension", {
  tmp <- tempfile(fileext = ".gpkg")
  on.exit(unlink(tmp))

  poly <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
  sf::st_write(poly, tmp, driver = "GPKG", quiet = TRUE)

  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = tmp, name = "test.gpkg")
  )

  expect_true(result$success)
  expect_s3_class(result$data, "sf")
})

test_that("fread_uploaded_spatial() rejects non-polygon geometry types", {
  tmp <- tempfile(fileext = ".geojson")
  on.exit(unlink(tmp))

  # Write a POINT geometry
  pts <- sf::st_sf(
    id = 1L,
    geometry = sf::st_sfc(sf::st_point(c(0, 0)), crs = "EPSG:4326")
  )
  sf::st_write(pts, tmp, driver = "GeoJSON", quiet = TRUE)

  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = tmp, name = "test.geojson")
  )

  expect_false(result$success)
  expect_null(result$data)
  expect_match(result$message, "POINT")
})

test_that("fread_uploaded_spatial() filters mixed geometry to polygons only", {
  # sf::st_write does not support mixed geometry collections in GeoJSON easily,
  # so we test the filtering logic by checking that a pure polygon file succeeds
  # and returns only polygon geometries.
  tmp <- tempfile(fileext = ".gpkg")
  on.exit(unlink(tmp))

  polys <- sf::st_sf(
    id = 1:2,
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
  sf::st_write(polys, tmp, driver = "GPKG", quiet = TRUE)

  result <- shinyplanr:::fread_uploaded_spatial(
    list(datapath = tmp, name = "test.gpkg")
  )

  expect_true(result$success)
  geom_types <- unique(sf::st_geometry_type(result$data))
  expect_true(all(geom_types %in% c("POLYGON", "MULTIPOLYGON")))
})

# ---------------------------------------------------------------------------
# fcalculate_coverage() — pure spatial calculation
# ---------------------------------------------------------------------------

test_that("fcalculate_coverage() returns a tibble with expected columns", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  # Upload polygon covering the first two planning units
  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 2, 2, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "total_amount", "absolute_held",
                          "relative_held", "target", "incidental"))
})

test_that("fcalculate_coverage() returns one row per active Feature in Dict", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)

  expect_equal(nrow(result), 2L)
  expect_setequal(result$feature, c("feature_A", "feature_B"))
})

test_that("fcalculate_coverage() computes correct relative_held", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  # Upload polygon covering planning units 1, 2, 3 (x = 0-3, y = 0-1)
  # feature_A values: 1, 0, 1, 0, 1 → total = 3
  # PUs 1-3 (x=0-3, y=0-1): feature_A = 1, 0, 1 → absolute_held = 2
  # relative_held = 2/3
  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 3, 3, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)
  row_A  <- result[result$feature == "feature_A", ]

  expect_equal(row_A$total_amount, 3)
  expect_equal(row_A$relative_held, row_A$absolute_held / row_A$total_amount)
  expect_true(row_A$relative_held >= 0 & row_A$relative_held <= 1)
})

test_that("fcalculate_coverage() sets relative_held to 0 when total_amount is 0", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  # Set feature_A to all zeros
  raw_sf$feature_A <- 0

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)
  row_A  <- result[result$feature == "feature_A", ]

  expect_equal(row_A$relative_held, 0)
})

test_that("fcalculate_coverage() uses targetInitial / 100 as target", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()  # targetInitial = c(30, 50)

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)

  expect_equal(result$target[result$feature == "feature_A"], 0.30)
  expect_equal(result$target[result$feature == "feature_B"], 0.50)
})

test_that("fcalculate_coverage() falls back to 0.3 target when targetInitial is NA", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()
  Dict$targetInitial[Dict$nameVariable == "feature_A"] <- NA_real_

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)

  expect_equal(result$target[result$feature == "feature_A"], 0.3)
})

test_that("fcalculate_coverage() warns for non-binary feature values", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()
  raw_sf$feature_A <- c(0.5, 0.3, 0.8, 0.1, 0.9)  # continuous, not binary

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  expect_warning(
    shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict),
    regexp = "non-binary"
  )
})

test_that("fcalculate_coverage() sets incidental to FALSE for all rows", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  uploaded_sf <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  result <- shinyplanr:::fcalculate_coverage(uploaded_sf, raw_sf, Dict)

  expect_true(all(result$incidental == FALSE))
})

test_that("fcalculate_coverage() transforms uploaded_sf CRS to match raw_sf", {
  raw_sf <- make_raw_sf()  # EPSG:4326
  Dict   <- make_dict()

  # Create uploaded polygon in a different CRS (EPSG:3857 Web Mercator)
  # Approximate equivalent of (0,0)-(1,1) in EPSG:4326
  uploaded_sf_4326 <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
  uploaded_sf_3857 <- sf::st_transform(uploaded_sf_4326, "EPSG:3857")

  # Should not error — CRS transformation is handled internally
  expect_no_error(
    shinyplanr:::fcalculate_coverage(uploaded_sf_3857, raw_sf, Dict)
  )
})
