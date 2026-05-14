# build_stub_sysdata.R
#
# Creates a minimal stub R/sysdata.rda so that the shinyplanr package can be
# installed and R CMD CHECK passes even without a real deployment config loaded.
#
# The stub contains a tiny 5-planning-unit hexagonal grid (covering a small
# synthetic ocean area) with two synthetic features. It is NOT used at runtime
# when load_config() is called — load_config() overwrites all namespace objects
# with the real deployment data.
#
# When to re-run this script:
#   - After adding a new required key to .shinyplanr_required_keys in config_schema.R
#   - If R CMD CHECK starts complaining about missing internal objects
#
# Run from the shinyplanr package root:
#   source("data-raw/build_stub_sysdata.R")

library(sf)
library(ggplot2)

# ---------------------------------------------------------------------------
# Tiny synthetic planning unit grid (5 hexagonal cells)
# ---------------------------------------------------------------------------
# Use a simple grid of 5 squares in ESRI:54009 (Mollweide), centred on the
# Pacific to represent a generic ocean region.

centres <- data.frame(
  x = c(0, 20000, 40000, 10000, 30000),
  y = c(0, 0,     0,     17320, 17320)
)

make_hex <- function(cx, cy, r = 10000) {
  angles <- seq(30, 330, by = 60) * pi / 180  # 6 vertices
  xs <- cx + r * cos(angles)
  ys <- cy + r * sin(angles)
  # Close the polygon by repeating the first coordinate
  xs <- c(xs, xs[1])
  ys <- c(ys, ys[1])
  st_polygon(list(cbind(xs, ys)))
}

geoms <- st_sfc(
  lapply(seq_len(nrow(centres)), function(i) make_hex(centres$x[i], centres$y[i])),
  crs = "ESRI:54009"
)

raw_sf <- st_sf(
  feature_A = c(0.8, 0.2, 0.5, 0.9, 0.1),
  feature_B = c(0.3, 0.7, 0.4, 0.1, 0.6),
  geometry  = geoms
)

# ---------------------------------------------------------------------------
# Boundary (convex hull of all PUs)
# ---------------------------------------------------------------------------
bndry <- st_convex_hull(st_union(geoms)) |>
  st_sf() |>
  st_set_crs("ESRI:54009")

# ---------------------------------------------------------------------------
# Overlay (empty coastline placeholder)
# ---------------------------------------------------------------------------
overlay <- st_sf(geometry = st_sfc(crs = "ESRI:54009"))

# ---------------------------------------------------------------------------
# Minimal Dict
# ---------------------------------------------------------------------------
Dict <- data.frame(
  nameCommon    = c("Feature A", "Feature B"),
  nameVariable  = c("feature_A", "feature_B"),
  category      = c("Habitat", "Habitat"),
  categoryID    = c("Hab", "Hab"),
  type          = c("Feature", "Feature"),
  targetInitial = c(30, 30),
  targetMin     = c(0, 0),
  targetMax     = c(85, 85),
  includeApp    = c(TRUE, TRUE),
  includeJust   = c(TRUE, TRUE),
  units         = c("", ""),
  justification = c("Stub feature A.", "Stub feature B."),
  stringsAsFactors = FALSE
)

vars <- c("feature_A", "feature_B")

# Schema version (must match .shinyplanr_schema_version in config_schema.R)
schema_version <- 1L

# ---------------------------------------------------------------------------
# Options (stub)
# ---------------------------------------------------------------------------
options <- list(
  app_title  = "shinyplanr (stub)",
  nav_title  = "Stub Region",
  funder_url = "https://spatialplanning.github.io",
  mod_1welcome = TRUE,
  mod_2scenario = TRUE,
  mod_3compare = TRUE,
  mod_4features = TRUE,
  mod_5coverage = TRUE,
  mod_6help = TRUE,
  mod_7credit = FALSE,
  include_report = FALSE,
  include_bioregion = FALSE,
  show_uq_logo = TRUE,
  include_climateChange = FALSE,
  climate_change = 0,
  include_lockedArea = FALSE,
  targetsBy = "individual",
  obj_func = "min_shortfall",
  cCRS = "ESRI:54009"
)

# ---------------------------------------------------------------------------
# Plotting themes (stub)
# ---------------------------------------------------------------------------
map_theme <- theme_bw(base_size = 14) +
  theme(
    legend.position = "right",
    legend.direction = "vertical",
    axis.title = element_blank()
  )

bar_theme <- theme_bw(base_size = 14) +
  theme(
    legend.position = "right",
    legend.direction = "vertical",
    axis.title = element_blank()
  )

# ---------------------------------------------------------------------------
# Text content (stub)
# ---------------------------------------------------------------------------
tx <- list(
  welcome = list(
    list(title = "Welcome", text = "# Stub region\n\nNo config loaded yet.")
  )
)

tx_1footer    <- "Stub footer — run `load_config()` to load real content."
tx_2solution  <- ""
tx_2targets   <- ""
tx_2cost      <- ""
tx_2climate   <- ""
tx_2ess       <- ""
tx_6faq       <- ""
tx_6technical <- ""
tx_6changelog <- ""

# ---------------------------------------------------------------------------
# Save to R/sysdata.rda
# ---------------------------------------------------------------------------
usethis::use_data(
  schema_version,
  options,
  map_theme,
  bar_theme,
  Dict,
  vars,
  raw_sf,
  bndry,
  overlay,
  tx,
  tx_1footer,
  tx_2solution,
  tx_2targets,
  tx_2cost,
  tx_2climate,
  tx_2ess,
  tx_6faq,
  tx_6technical,
  tx_6changelog,
  overwrite = TRUE,
  internal  = TRUE
)

message("\nStub R/sysdata.rda written successfully.")
message("These objects are placeholders only.")
message("At runtime, load_config() overwrites them with real deployment data.")
