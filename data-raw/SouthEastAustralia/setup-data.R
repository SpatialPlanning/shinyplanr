# Setup data for shinyplanr app
# Country/Region: SouthEastAustralia
# Generated: 2026-03-04

library(tidyverse)
library(spatialplanr)
library(sf)
library(terra)

library(oceandatr)

# =============================================================================
# BASIC PARAMETERS
# =============================================================================

country <- "Australia"
crs <- "EPSG:9473"
resolution <- 20000L  # Planning unit size in meters

data_dir <- file.path("data-raw", "SouthEastAustralia")
data_path <- file.path(data_dir, "data")  # Path to your raw data files

# =============================================================================
# BOUNDARIES (using oceandatr)
# =============================================================================


#' Remove Planning Units (PUs) that intersect with land
#'
#' This function filters a grid (sf object) to remove any cells that overlap
#' with a provided coastline or landmass polygon. It automatically ensures
#' the coastline matches the CRS of the grid.
#'
#' @param PUs An sf object representing the grid (planning units).
#' @param coast An sf object representing the coastline or landmass.
#'
#' @return An sf object containing only the grid cells that are entirely in the ocean.
#' @export
#'
#' @examples
#' \dontrun{
#' ocean_only <- splnr_remove_PUs(my_grid, my_coastline)
#' }
splnr_remove_PUs <- function(PUs, coast) {

  # 1. Input Validation using assertthat
  assertthat::assert_that(
    inherits(PUs, "sf"),
    msg = "PUs must be an sf object."
  )
  assertthat::assert_that(
    inherits(coast, "sf"),
    msg = "coast must be an sf object."
  )

  # 2. CRS Alignment
  if (sf::st_crs(PUs) != sf::st_crs(coast)) {
    message("Transforming coastline CRS to match grid...")
    coast <- sf::st_transform(coast, sf::st_crs(PUs))
  }

  # 3. Spatial Filtering
  # Find intersections (TRUE if grid cell touches land)
  intersects_mask <- sf::st_intersects(PUs, coast, sparse = FALSE)

  # Filter: Keep rows where NO intersections were found
  ocean_grid <- PUs[!apply(intersects_mask, 1, any), ]

  return(ocean_grid)
}


# Get EEZ boundary from Marine Regions database
# See: https://marineregions.org/gazetteer.php for valid names
# eez <- oceandatr::get_boundary(name = country, type = "eez") %>%
#   sf::st_transform(crs = crs) %>%
#   sf::st_geometry() %>%
#   sf::st_sf()

# Alternative: Load custom boundary
# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%
#   sf::st_transform(crs = crs)

# Separate boundary (for plotting)
# bndry <- eez %>%
#   sf::st_cast(to = "POLYGON") %>%
#   dplyr::mutate(Area_km2 = sf::st_area(.) %>%
#                   units::set_units("km2") %>%
#                   units::drop_units())
#

boundary <- spatialplanr::splnr_create_polygon(dplyr::tibble(
  x = c(142, 150, 150, 142, 142),
  y = c(-37.6, -37.6, -41.5, -41.5, -37.6)
), cCRS = crs)


# Get coastline for plotting overlays
coast <- rnaturalearth::ne_countries(country = country, scale = "medium", returnclass = "sf") %>%
  sf::st_transform(crs = crs) %>%
  sf::st_crop(boundary)

# Create planning unit grid
PUs <- spatialgridr::get_grid(boundary = boundary,
                              crs = crs,
                              output = "sf_hex",
                              resolution = resolution) %>%
  splnr_remove_PUs(coast)


# Check the grid
ggplot() +
  geom_sf(data = PUs, fill = NA, colour = "grey80") +
  geom_sf(data = boundary, fill = NA, colour = "blue") +
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

gfw_cost <- splnr_get_gfw(region = country, "2014-01-01", "2023-12-31", "YEARLY", spat_res = "LOW", compress = TRUE) %>%
  dplyr::mutate(ApparentFishingHrs = if_else(ApparentFishingHrs > 1000, NA, ApparentFishingHrs)) %>%
  dplyr::select(-GFWregionID) %>%
  sf::st_transform(sf::st_crs(PUs)) %>%
  sf::st_interpolate_aw(., PUs, extensive = TRUE, keep_NA = TRUE)


# Cost layers
cost <- dat_sf %>%
  dplyr::select(geometry) %>%
  spatialplanr::splnr_get_distCoast(custom_coast = coast) %>%
  dplyr::mutate(
    Cost_Area = PU_Area,  # Equal area cost
    Cost_Distance = 1/coastDistance_km,  # Distance to coast
    Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001)
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

# climate_files <- c(
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_recent_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_intermediate_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_long_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_mid_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_near_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_recent_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_intermediate_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_long_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_mid_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_near_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_recent_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_intermediate_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_long_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_mid_term.RDS",
#   "data-raw/SouthEastAustralia/data/Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_near_term.RDS"
# )


# fix_climate <- function(file){
#
#   dat <- read_rds(file) %>%
#     terra::rast() %>%
#     subset("slpTrends")
#
#   names(dat) <- tools::file_path_sans_ext(basename(file) %>%
#                                             str_remove("ensemble_") %>%
#                                             str_remove("r1i1p1f1_rg_") %>%
#                                             str_remove("_term"))
#
#   terra::writeRaster(dat, stringr::str_replace_all(file, ".RDS", ".tif"))
#
# }

# purrr::walk(climate_files, fix_climate)


climate_files <- c(
  file.path(data_path, "Climate/tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_intermediate_term.tif"),
  file.path(data_path, "Climate/tos_slpTrend_ensemble_ssp370_r1i1p1f1_rg_intermediate_term.tif"),
  file.path(data_path, "Climate/tos_slpTrend_ensemble_ssp245_r1i1p1f1_rg_intermediate_term.tif")
)

climate_sf <- rast(climate_files) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = .,)

# If you have climate data, bind it:
dat_sf <- dplyr::bind_cols(dat_sf, climate_sf %>% sf::st_drop_geometry())

# ========
# Add Multiple Use
# ========

MultiUse <- st_read(file.path(data_path, "OffshoreRenewable_Energy_Infrastructure_Regions_987513835804844725.gpkg")) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "REI", cutoff = 0.5)



# ========
# Ecosystem Services
# ========


# Mangroves
# ES <- terra::mosaic(
#   terra::rast("~/Nextcloud/MME1DATA-Q1215/WAITT_ES/Maxwell_2020_SOC_mangroves_2020/163E_05N/sol_soc.tha_mangroves.typology_m_30m_s0..100cm_2020_global_v1.1.tif"),
#   terra::rast("~/Nextcloud/MME1DATA-Q1215/WAITT_ES/Maxwell_2020_SOC_mangroves_2020/162E_05N/sol_soc.tha_mangroves.typology_m_30m_s0..100cm_2020_global_v1.1.tif")) %>%
#   get_data_in_grid(spatial_grid = PUs, dat = ., meth = "mean", antimeridian = FALSE, name = "soilOrganicCarbon_tPU") %>%
#   dplyr::mutate(across(everything(), ~replace_na(., 0)),
#                 soilOrganicCarbon_tPU = soilOrganicCarbon_tPU * 1.00635) # Convert to total carbon per PU CellARea = 1.00635 ha



ES <- sf::st_read("/Users/jason/Nextcloud/MME1DATA-Q1215/WAITT_ES/Menendez_2020_CoastalProtection/3_CoastalStudyUnit Aggregations/UCSC_CWON_studyunits.gpkg") %>%
  filter(ISO3 == "AUS") %>%
  sf::st_transform(crs) %>%
  sf::st_crop(boundary) %>%
  dplyr::select(all_of(c("Risk_Pop_2020", "Risk_Stock_2020"))) %>%
  sf::st_interpolate_aw(., PUs, extensive = FALSE, keep_NA = FALSE) #, "Ben_Stock_2020")) # Benefits to population, Benefits to Property

EcoServ <- sf::st_join(PUs, ES, join = st_equals)




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
save(dat_sf, boundary, coast,
     file = file.path(data_dir, paste0(country, "_RawData.rda")))

message("Data saved to: ", file.path(data_dir, paste0(country, "_RawData.rda")))
message("Finished processing data for ", country)

