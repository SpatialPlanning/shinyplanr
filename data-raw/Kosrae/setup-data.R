library(tidyverse)
library(spatialplanr)
library(oceandatr)
library(sf)
library(terra)

# TODO Add check that all names in Dict are unique. Or change target plotting to
# use variable name rather than the common name. It would be good to have the
# same Common name if needed.

data_path <- file.path("data-raw", "Kosrae", "KosraeData")

name <- "Kosrae"

#kosrae equal area projection from projection wizard, found using bbox of 12nm limits
kos_crs <- "+proj=cea +lon_0=163 +lat_ts=2.8 +datum=WGS84 +units=m +no_defs"

coast <-  sf::st_read(file.path(data_path, "kos_osm_shoreline.gpkg")) %>%
  sf::st_transform(crs = kos_crs)

bndry <- sf::st_read(file.path(data_path, "contour_500.gpkg")) %>%
  sf::st_transform(crs = kos_crs)

pgrid <- get_grid(boundary = bndry,
                  # resolution = 50,
                  resolution = 100,
                  crs = kos_crs,
                  touches = TRUE)


habitat_coral_seagrass <- read_sf(file.path(data_path, "benthic_geomorph_allen_intersect.gpkg")) %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   feature_names = "habitat",
                   antimeridian = FALSE,
                   cutoff = 0.1)

habitat_other_reef <- read_sf(file.path(data_path, "benthic_no_coral_seagrass.gpkg")) %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   feature_names = "Benthic_cover",
                   antimeridian = FALSE,
                   cutoff = 0.1)



depth_zones <- oceandatr::get_bathymetry(spatial_grid = pgrid,
                                         classify_bathymetry = TRUE,
                                         above_sea_level_isNA = FALSE,
                                         bathymetry_data_filepath = file.path(data_path, "gebco_2024_n6.0_s4.9_w162.0_e164.0.tif"))
# mask(sum(c(habitat_coral_seagrass, habitat_other_reef), na.rm = TRUE) %>% subst(1:10, NA))
names(depth_zones) <- c("Shelf", "Slope")

# Features: Tourism, Community and recreational use (you can use binary values)
# Cost: OUS fisheries data (you already have in the app), maybe also include bottom fishing and trolling (have values across most of the planning area)
# Locked-out: Construction and infrastructure (binary values)

ous <- terra::rast(c(
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "aquaculture.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "community_recreational_use.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "construction_and_infrastructure.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "cultural_use.tif"),
  # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "maritime_activity.tif"),
  # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "other.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "research.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "transportation.tif"),
  file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "tourism.tif"))) %>%
  get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)

ous[ous>=1] <- 1 # Cutoff of 1
ous[ous<1] <- 0 # Cutoff of 1

files <- list.files(file.path(data_path, "ocean-use-survey", "subsectors"), recursive = TRUE, pattern = ".tif$", full.names = TRUE)
ous_ss <- purrr::map(files, \(x) terra::rast(x) %>% get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)) %>%
  terra::rast()

ous_ss[ous_ss>=1] <- 1 # Cutoff of 1
ous_ss[ous_ss<1] <- 0 # Cutoff of 1

# Locked in areas ---------------------------------------------------------

# ous_lock <- c(terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "aquaculture.tif")) %>%
#                 get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
#               terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "construction_and_infrastructure.tif")) %>%
#                 get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE))
#
# ous[ous>=1] <- 1 # Cutoff of 1



dat_sf <- c(habitat_coral_seagrass, habitat_other_reef, depth_zones, ous, ous_ss) %>%
  terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, na.all = TRUE, round = FALSE) %>%
  sf::st_as_sf() %>%
  mutate(across(everything(), ~replace_na(.x, 0))) %>%
  janitor::clean_names() %>%
  sf::st_transform(kos_crs)

PUs <- dat_sf %>%
  dplyr::select(geometry)



# Geomorphology -----------------------------------------------------------

## TODO Seems to be an error in the data - Abyss is inside the shelf for Kosrae. Contact Blue Planet
# geo <- list.files(file.path(data_path, "geomorph"), pattern = ".shp$", full.names = TRUE) %>%
#   purrr::map(st_read) %>%
#   bind_rows() %>%
#   dplyr::select(-area_km2) %>%
#   sf::st_transform(kos_crs) %>%
#   sf::st_crop(PUs) %>%
#   dplyr::group_by(Geomorphic) %>%
#   st_intersection(PUs)
#
# geo_sf <- spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = geo, feature_names = )


## Remove cost layers from dat_sf
dat_sf <- dat_sf %>%
  dplyr::select(-c("bottom_fishing", "trolling"))

# Add cost data -----------------------------------------------------------
ous_cost <- c(terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "fisheries.tif")) %>%
                get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
              terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "maritime_activity.tif")) %>%
                get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
              terra::rast(file.path(data_path, "ocean-use-survey", "subsectors", "fishing", "bottom_fishing.tif")) %>%
                get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
              terra::rast(file.path(data_path, "ocean-use-survey", "subsectors", "fishing", "trolling.tif")) %>%
                get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)) %>%
  terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, na.all = TRUE, round = FALSE) %>%
  sf::st_as_sf() %>%
  mutate(across(everything(), ~replace_na(.x, 0))) %>%
  mutate(across(tidyselect::where(is.numeric), \(x) if_else(x > quantile(x, 0.99), quantile(x, 0.99), x))) %>%
  janitor::clean_names() %>%
  sf::st_transform(kos_crs) %>%
  sf::st_interpolate_aw(ous_lock, to = PUs, extensive = TRUE, keep_NA = TRUE)



# There is a lot of missing data in the region

# gfw_cost <- spatialplanr::splnr_get_gfw("Micronesia",
#                                         start_date = "2013-01-01",
#                                         end_date = "2023-12-31",
#                                         temp_res = "YEARLY",
#                                         spat_res = "HIGH",
#                                         compress = TRUE) %>%
#   dplyr::select(-GFWregionID) %>%
#   dplyr::mutate(ApparentFishingHrs = if_else(ApparentFishingHrs > 1000, NA, ApparentFishingHrs)) %>%
#   sf::st_transform(sf::st_crs(PUs)) %>%
#   sf::st_interpolate_aw(., to = PUs, extensive = FALSE, na.rm = TRUE)


cost <- ous_cost %>%
  splnr_get_distCoast(custom_coast = coast) %>%  # Distance to nearest coast
  dplyr::rename(Cost_Distance = 1/coastDistance_km) %>%
  dplyr::mutate(Cost_None = 0.1,
                # Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001),
                # Cost_FishingHrs = dplyr::if_else(Cost_FishingHrs == 0, 0.00001, Cost_FishingHrs),
  ) %>%
  dplyr::relocate(geometry, .after = tidyselect::last_col())



#
#
#
# mutate(across(!tidyselect::matches("geometry"), ~ifelse(is.nan(.), NA, .))) %>%
#   sf::st_transform(sf::st_crs(PUs))
#
#
# x <- sf::st_interpolate_aw(ous_lock, to = PUs, extensive = TRUE, keep_NA = TRUE)
#

# convert_rast <- function(files, PUs){
#   rast(files) %>%
#     get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE) %>%
#     terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, na.all = TRUE, round = FALSE) %>%
#     sf::st_as_sf() %>%
#     sf::st_transform(sf::st_crs(PUs)) %>%
#     sf::st_interpolate_aw(to = PUs, extensive = FALSE, na.rm = TRUE) #%>%
# sf::st_drop_geometry()
# }



# Climate Data ------------------------------------------------------------

# Start with 0.5 deg files
climate_sf <- bind_cols(
  read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp245_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    sf::st_drop_geometry() %>%
    dplyr::select("slpTrends_245"="slpTrends"),
  read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp370_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    sf::st_drop_geometry() %>%
    dplyr::select("slpTrends_370"="slpTrends"),
  read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp585_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    dplyr::select("slpTrends_585"="slpTrends")) %>%
  sf::st_drop_geometry() %>%
  sf::st_as_sf() %>%
  sf::st_transform(kos_crs) %>%
  sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)

# Now add High Res
climate_sf <-
  bind_cols(climate_sf,
            read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_ensemble_highres-future_r1i1p1f1_RegriddedAnnual_20150101-205003311.rds")) %>%
              sf::st_transform(kos_crs) %>%
              dplyr::select("slpTrends_HR" = "slpTrends") %>%
              sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE) %>%
              sf::st_drop_geometry())

# Save raw data -----------------------------------------------------------

dat_sf <- bind_cols(dat_sf,
                    # lock_in %>% sf::st_drop_geometry(),
                    cost %>% sf::st_drop_geometry(),
                    climate_sf %>% sf::st_drop_geometry()) %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())


save(dat_sf, bndry, coast, climate_sf, file = file.path("data-raw", name, paste0(name,"_RawData.rda")))
