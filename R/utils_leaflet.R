#' Prepare an sf object for Leaflet rendering, handling the antimeridian
#'
#' Transforms \code{x} to WGS84 (EPSG:4326) for use in a Leaflet map. When
#' \code{antimeridian = TRUE}, also applies \code{sf::st_shift_longitude()}
#' so that geometries crossing the +/-180 degree line (e.g. Pacific regions
#' such as Fiji or the WestPacific deployment) are shifted into the 0-360
#' degree longitude range instead of wrapping around the globe.
#'
#' Leaflet's tile renderer (and \code{leafgl}'s WebGL layer) both handle
#' longitudes outside the conventional -180..180 range correctly -- they are
#' simply treated as being further around the globe -- so shifting to 0-360
#' is sufficient to stop antimeridian-crossing polygons from being drawn as
#' enormous bands spanning the entire map.
#'
#' This helper is intended ONLY for data about to be drawn on a Leaflet map.
#' Do NOT use it when preparing data for \code{sf::st_write()} (e.g. GeoJSON
#' downloads) -- external GIS tools expect standard -180..180 coordinates,
#' and shifted output would be non-standard and hard to reopen.
#'
#' @param x An \code{sf} object in any CRS.
#' @param antimeridian Logical. If \code{TRUE}, shift longitudes to 0-360
#'   after transforming to WGS84. Defaults to \code{FALSE}. Typically sourced
#'   from \code{options$antimeridian} (see \code{setup/3_setup_app.R}).
#'
#' @return An \code{sf} object in EPSG:4326, with longitudes shifted to
#'   0-360 when \code{antimeridian = TRUE}.
#'
#' @examples
#' poly <- sf::st_sf(
#'   geometry = sf::st_sfc(
#'     sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
#'     crs = "EPSG:4326"
#'   )
#' )
#' fprep_wgs84(poly, antimeridian = FALSE)
#'
#' @importFrom sf st_transform st_shift_longitude
#'
#' @noRd
fprep_wgs84 <- function(x, antimeridian = FALSE) {
  out <- sf::st_transform(x, "EPSG:4326")
  if (isTRUE(antimeridian)) {
    out <- sf::st_shift_longitude(out)
  }
  out
}


#' Add a coastline overlay to a leafletProxy chain, if enabled
#'
#' Draws \code{coast_overlay_wgs84} as an SVG polygon layer on top of a
#' WebGL (\code{leafgl}) planning-unit layer. SVG polygons always render
#' above WebGL in Leaflet, so the coastline remains visible even where
#' planning units cover the same area.
#'
#' This is a no-op (returns \code{proxy} unchanged) when
#' \code{coast_overlay_wgs84} is \code{NULL} -- i.e. when
#' \code{options$show_coast_overlay} is \code{FALSE} or the overlay is empty.
#' Centralising this here avoids duplicating the same ~15-line block across
#' every module with an interactive leaflet map
#' (\code{mod_2scenario}, \code{mod_4afeatures}, \code{mod_3compare}).
#'
#' @param proxy A \code{leaflet::leafletProxy} (or a magrittr-piped chain
#'   ending in one), typically straight after \code{leafgl::addGlPolygons()}.
#' @param coast_overlay_wgs84 An \code{sf} object in WGS84 (already prepared
#'   via \code{fprep_wgs84()} and \code{sf::st_make_valid()}), or \code{NULL}.
#' @param options Named list of app options (from \code{load_config()}).
#'   Reads \code{coast_overlay_colour} and \code{coast_overlay_fill}
#'   (both optional, with \code{\%||\%} fallbacks).
#'
#' @return The \code{leafletProxy} chain, with the coastline layer appended
#'   when applicable.
#'
#' @noRd
fadd_coast_overlay <- function(proxy, coast_overlay_wgs84, options) {
  if (is.null(coast_overlay_wgs84)) {
    return(proxy)
  }
  leaflet::addPolygons(
    proxy,
    data = coast_overlay_wgs84,
    color = options$coast_overlay_colour %||% "black",
    fillColor = options$coast_overlay_fill %||% "grey50",
    fillOpacity = 0.6,
    weight = 1,
    group = "coast_overlay"
  )
}
