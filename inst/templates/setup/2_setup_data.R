# setup/2_setup_data.R
# Step 2: Prepare spatial data for shinyplanr: {country}
# Generated: {date}
#
# Run this script once to prepare the raw spatial data.
# Output: setup/data/{country}_RawData.rda
#
# HOW TO RUN: Click 'Source' or run line-by-line.

library(tidyverse)
library(spatialplanr)
library(sf)
library(terra)
# [IF oceandatr]
library(oceandatr)
# [END oceandatr]

# =============================================================================
# BASIC PARAMETERS
# =============================================================================

country    <- "{country}"
crs        <- "{crs}"
resolution <- {resolution}L  # Planning unit size in meters

setup_dir <- "setup"                              # Location of this folder
data_path <- file.path(setup_dir, "data")         # Raw spatial data files

# =============================================================================
# [IF oceandatr]
# BOUNDARIES (using oceandatr)
# =============================================================================

# Get EEZ boundary from Marine Regions database
# See: https://marineregions.org/gazetteer.php for valid names
bndry <- oceandatr::get_boundary(name = country, type = "eez") %>%
  sf::st_transform(crs = crs) %>%
  sf::st_geometry() %>%
  sf::st_sf()

# Alternative: Load custom boundary
# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%
#   sf::st_transform(crs = crs)

# Separate boundary (for plotting)
bndry <- bndry %>%
  sf::st_cast(to = "POLYGON") %>%
  dplyr::mutate(Area_km2 = sf::st_area(.) %>%
                  units::set_units("km2") %>%
                  units::drop_units())

# Get coastline for plotting overlays
coast <- rnaturalearth::ne_countries(country = country, scale = "medium", returnclass = "sf") %>%
  sf::st_transform(crs = crs)

# If using a state rather than a coountry, you can try ne_states
# coast <- rnaturalearth::ne_states(country = country, returnclass = "sf") %>%
#   filter(name == state_name) %>%
#   sf::st_transform(crs = crs)


# Create planning unit grid
PUs <- spatialgridr::get_grid(boundary = bndry,
                              crs = crs,
                              output = "sf_hex",
                              resolution = resolution)

# Check the grid
ggplot() +
  geom_sf(data = PUs, fill = NA, colour = "grey80") +
  geom_sf(data = bndry, fill = NA, colour = "blue") +
  geom_sf(data = coast, fill = "darkgrey")

# [END oceandatr]
# [IF manual]
# BOUNDARIES (custom data)
# =============================================================================

# TODO: Load your boundary file
# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%
#   sf::st_transform(crs = crs)

# TODO: Load your coastline for plotting
# coast <- sf::st_read(file.path(data_path, "my_coastline.gpkg")) %>%
#   sf::st_transform(crs = crs)

# TODO: Create or load planning units
# PUs <- spatialgridr::get_grid(boundary = bndry,
#                               crs = crs,
#                               output = "sf_hex",
#                               resolution = resolution)

# [END manual]

# =============================================================================
# FEATURE DATA
# =============================================================================

# [IF oceandatr]
bathymetry    <- oceandatr::get_bathymetry(spatial_grid = PUs, classify_bathymetry = TRUE) # Keep geometry for bathymetry
geomorphology <- oceandatr::get_geomorphology(spatial_grid = PUs) %>% sf::st_drop_geometry()
knolls        <- oceandatr::get_knolls(spatial_grid = PUs) %>% sf::st_drop_geometry()
seamounts     <- oceandatr::get_seamounts(spatial_grid = PUs, buffer = 30000) %>% sf::st_drop_geometry()
enviro_zones  <- oceandatr::get_enviro_zones(spatial_grid = PUs, max_num_clusters = 5, show_plots = FALSE) %>% sf::st_drop_geometry()
corals        <- oceandatr::get_coral_habitat(spatial_grid = PUs) %>% sf::st_drop_geometry()

dat_sf <- dplyr::bind_cols(bathymetry, geomorphology, knolls, seamounts, enviro_zones, corals) %>%
  dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))

# Replace any spaces in column names with underscores
names(dat_sf) <- stringr::str_replace_all(names(dat_sf), ' ', '_')

# [END oceandatr]
# [IF manual]
# TODO: Load and process your feature data, then combine into dat_sf
# dat_sf <- dplyr::bind_cols(PUs, ...) %>%
#   dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))

# [END manual]

# =============================================================================
# [IF include_cost]
# COST DATA
# =============================================================================

PU_Area <- as.numeric(units::set_units(sf::st_area(PUs)[1], km^2)) %>% round(2)

cost <- dat_sf %>%
  dplyr::select(geometry) %>%
  spatialplanr::splnr_get_distCoast(custom_coast = coast) %>%
  dplyr::mutate(
    cost_area     = PU_Area,
    cost_distance = coastDistance_km
  ) %>%
  dplyr::select(-coastDistance_km) %>%
  sf::st_drop_geometry()

dat_sf <- dplyr::bind_cols(dat_sf, cost)

# [END include_cost]

# =============================================================================
# [IF include_mpas]
# LOCKED-IN AREAS (MPAs)
# =============================================================================

mpas <- spatialplanr::splnr_get_MPAs(PlanUnits = PUs, Countries = country, Raw = TRUE) %>%
  sf::st_transform(crs = crs) %>%
  dplyr::select(geometry) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "mpas", cutoff = 0.5) %>%
  sf::st_drop_geometry()

dat_sf <- dplyr::bind_cols(dat_sf, mpas)

# [END include_mpas]

# =============================================================================
# [IF include_climate]
# CLIMATE DATA (optional)
# =============================================================================

# TODO: Load climate data if available
# climate_sf <- readr::read_rds(file.path(data_path, 'sst_trends.rds')) %>%
#   sf::st_transform(crs) %>%
#   sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)
# dat_sf <- dplyr::bind_cols(dat_sf, climate_sf %>% sf::st_drop_geometry())

# [END include_climate]

# =============================================================================
# FINAL PROCESSING AND SAVE
# =============================================================================

dat_sf <- dat_sf %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())

if (any(is.na(sf::st_drop_geometry(dat_sf)))) {
  warning("NA values found in data - replacing with 0")
  dat_sf <- dat_sf %>%
    dplyr::mutate(across(where(is.numeric), ~replace_na(., 0)))
}

message("Data columns: ", paste(names(dat_sf), collapse = ", "))

save(dat_sf, bndry, coast,
     file = file.path(data_path, paste0(country, "_RawData.rda")))

message("Data saved to: ", file.path(data_path, paste0(country, "_RawData.rda")))
message("Next: open setup/3_setup_app.R and configure the app.")

# Open the next setup script -----------------------------------------------
if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
  rstudioapi::navigateToFile('setup/3_setup_app.R')
}
