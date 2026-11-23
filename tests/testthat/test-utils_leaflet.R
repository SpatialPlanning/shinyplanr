# tests/testthat/test-utils_leaflet.R
#
# Tests for fprep_wgs84() — prepares sf objects for Leaflet rendering,
# optionally shifting longitudes to 0-360 for antimeridian-crossing regions.

test_that("fprep_wgs84() transforms to EPSG:4326", {
  poly <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "ESRI:54009"
    )
  )

  out <- shinyplanr:::fprep_wgs84(poly, antimeridian = FALSE)

  expect_s3_class(out, "sf")
  expect_true(sf::st_crs(out) == sf::st_crs("EPSG:4326"))
})

test_that("fprep_wgs84() leaves longitudes untouched when antimeridian = FALSE", {
  poly <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(
        c(170, 175, 175, 170, 170),
        c(-10, -10, -5, -5, -10)
      ))),
      crs = "EPSG:4326"
    )
  )

  out <- shinyplanr:::fprep_wgs84(poly, antimeridian = FALSE)
  bbox <- sf::st_bbox(out)

  expect_equal(unname(bbox["xmin"]), 170)
  expect_equal(unname(bbox["xmax"]), 175)
})

test_that("fprep_wgs84() shifts a dateline-crossing polygon to 0-360 when antimeridian = TRUE", {
  # A polygon crossing the antimeridian (e.g. 179 to 181 equivalent -- here
  # built directly in EPSG:4326 as -179 to 179, which spans the full width
  # when drawn naively).
  poly <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(
        c(179, -179, -179, 179, 179),
        c(-5, -5, 5, 5, -5)
      ))),
      crs = "EPSG:4326"
    )
  )

  out <- shinyplanr:::fprep_wgs84(poly, antimeridian = TRUE)
  bbox <- sf::st_bbox(out)

  # After shifting to 0-360, the polygon should be a compact sliver near
  # the dateline (longitude 179) rather than spanning nearly the full globe.
  expect_true(unname(bbox["xmin"]) >= 0)
  expect_true(unname(bbox["xmax"]) <= 360)
  expect_lt(unname(bbox["xmax"]) - unname(bbox["xmin"]), 10)
})

test_that("fprep_wgs84() defaults antimeridian to FALSE when not supplied", {
  poly <- sf::st_sf(
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )

  out <- shinyplanr:::fprep_wgs84(poly)
  bbox <- sf::st_bbox(out)

  expect_equal(unname(bbox["xmin"]), 0)
  expect_equal(unname(bbox["xmax"]), 1)
})
