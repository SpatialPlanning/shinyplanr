# Setup data for shinyplanr app
# Country/Region: Tonga
# Generated: 2026-03-03

library(tidyverse)
library(spatialplanr)
library(sf)
library(terra)

library(oceandatr)

# =============================================================================
# BASIC PARAMETERS
# =============================================================================

country <- "Tonga"
crs <- "EPSG:32702"
resolution <- 20000L  # Planning unit size in meters

data_dir <- file.path("data-raw", country)
data_path <- file.path(data_dir, "data")  # Path to your raw data files

# =============================================================================
# BOUNDARIES (using oceandatr)
# =============================================================================

# Get EEZ boundary from Marine Regions database
# See: https://marineregions.org/gazetteer.php for valid names
eez <- oceandatr::get_boundary(name = country, type = "eez") %>%
  sf::st_transform(crs = crs) %>%
  sf::st_geometry() %>%
  sf::st_sf()

# Alternative: Load custom boundary
# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%
#   sf::st_transform(crs = crs)

# Separate boundary (for plotting)
bndry <- eez %>%
  sf::st_cast(to = "POLYGON") %>%
  dplyr::mutate(Area_km2 = sf::st_area(.) %>%
                  units::set_units("km2") %>%
                  units::drop_units())

# Get coastline for plotting overlays
coast <- rnaturalearth::ne_countries(country = country, scale = "medium", returnclass = "sf") %>%
  sf::st_transform(crs = crs)

# Create planning unit grid
PUs <- spatialgridr::get_grid(boundary = eez,
                              crs = crs,
                              output = "sf_hex",
                              resolution = resolution)

# Check the grid
ggplot() +
  geom_sf(data = PUs, fill = NA, colour = "grey80") +
  geom_sf(data = bndry, fill = NA, colour = "blue") +
  geom_sf(data = coast, fill = "darkgrey")

# =============================================================================
# FEATURE DATA
# =============================================================================

# Download and process oceandatr layers
# These will be automatically added to the planning units
# Variable names are set to match Dict_Feature.csv

# Bathymetry / Depth zones
bathymetry <- oceandatr::get_bathymetry(spatial_grid = PUs,
                                         classify_bathymetry = TRUE) %>%
  sf::st_drop_geometry()

# Geomorphology (seafloor features)
geomorphology <- oceandatr::get_geomorphology(spatial_grid = PUs) %>%
  sf::st_drop_geometry()

# Knolls (underwater hills)
knolls <- oceandatr::get_knolls(spatial_grid = PUs) %>%
  sf::st_drop_geometry()

# Seamounts (with 30km buffer)
seamounts <- oceandatr::get_seamounts(spatial_grid = PUs,
                                       buffer = 30000) %>%
  sf::st_drop_geometry()

# Environmental zones (data-driven bioregions)
enviro_zones <- oceandatr::get_enviro_zones(spatial_grid = PUs,
                                             max_num_clusters = 5,
                                             show_plots = FALSE) %>%
  sf::st_drop_geometry()

# Deep-water coral habitat
corals <- oceandatr::get_coral_habitat(spatial_grid = PUs) %>%
  sf::st_drop_geometry()

# Combine all oceandatr features
dat_sf <- dplyr::bind_cols(
  PUs,
  bathymetry,
  geomorphology,
  knolls,
  seamounts,
  enviro_zones,
  corals
) %>%
  dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))

# =============================================================================
# COST DATA
# =============================================================================

# Calculate planning unit area (for equal-area cost)
PU_Area <- as.numeric(units::set_units(sf::st_area(PUs)[1], km^2)) %>%
  round(2)

# Cost layers
cost <- dat_sf %>%
  dplyr::select(geometry) %>%
  spatialplanr::splnr_get_distCoast(custom_coast = coast) %>%
  dplyr::mutate(
    Cost_Area = PU_Area,  # Equal area cost
    Cost_Distance = coastDistance_km  # Distance to coast
  ) %>%
  dplyr::select(-coastDistance_km) %>%
  sf::st_drop_geometry()

# Add cost to main data
dat_sf <- dplyr::bind_cols(dat_sf, cost)

# TODO: Add custom cost layers (e.g., fishing effort, opportunity cost)
# fishing_cost <- ... %>% sf::st_drop_geometry()
# dat_sf <- dplyr::bind_cols(dat_sf, fishing_cost)

# =============================================================================
# LOCKED-IN AREAS (MPAs)
# =============================================================================

# Fetch marine protected areas from WDPA
# Note: First run may download data (~2GB)
mpas <- spatialplanr::splnr_get_MPAs(PlanUnits = PUs, Countries = country) %>%
  sf::st_transform(crs = crs) %>%
  dplyr::select(geometry) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "mpas", cutoff = 0.5) %>%
  sf::st_drop_geometry()

# Add MPAs to main data
dat_sf <- dplyr::bind_cols(dat_sf, mpas)

# TODO: Add custom locked-in/out areas
# locked_out <- sf::st_read(file.path(data_path, "no_take_zones.gpkg")) %>%
#   spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "locked_out")

# =============================================================================
# CLIMATE DATA (optional)
# =============================================================================

# TODO: Load climate data if available
# Climate data should be a metric where higher/lower values indicate
# climate refugia (depending on direction setting in setup-app.R)

# Example: SST trend data
# climate_sf <- readr::read_rds(file.path(data_path, "sst_trends.rds")) %>%
#   sf::st_transform(crs) %>%
#   sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)

# If you have climate data, bind it:
# dat_sf <- dplyr::bind_cols(dat_sf, climate_sf %>% sf::st_drop_geometry())

# =============================================================================
# FINAL PROCESSING AND SAVE
# =============================================================================

# Ensure geometry is last column
dat_sf <- dat_sf %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())

# Check for any remaining NAs and replace with 0
if (any(is.na(sf::st_drop_geometry(dat_sf)))) {
  warning("NA values found in data - replacing with 0")
  dat_sf <- dat_sf %>%
    dplyr::mutate(across(where(is.numeric), ~replace_na(., 0)))
}

# Check column names match Dict_Feature.csv
message("Data columns: ", paste(names(dat_sf), collapse = ", "))

# Save the processed data
save(dat_sf, bndry, coast,
     file = file.path(data_dir, paste0(country, "_RawData.rda")))

message("Data saved to: ", file.path(data_dir, paste0(country, "_RawData.rda")))
message("Finished processing data for ", country)

