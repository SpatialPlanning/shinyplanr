library(tidyverse)
library(spatialplanr)
library(oceandatr)
library(sf)
library(terra)
library(tidyterra)

# TODO Add check that all names in Dict are unique. Or change target plotting to
# use variable name rather than the common name. It would be good to have the
# same Common name if needed.

data_path <- file.path("data-raw", "Kosrae", "KosraeData")

name <- "Kosrae"

# Set up geospatial data ------

#kosrae equal area projection from projection wizard, found using bbox of 12nm limits
kos_crs <- "+proj=cea +lon_0=163 +lat_ts=2.8 +datum=WGS84 +units=m +no_defs"


## Kosrae Coastline --------------------------------------------------------

coast <-  sf::st_read(file.path(data_path, "kos_shoreline_IslAt", "kos_shoreline.shp")) %>%
  sf::st_transform(crs = kos_crs)

## Outer boundary ----------------------------------------------------------

# contour_500 has inner and outer boundaries. Need to isolate the outer (larger) one.
bndry <- sf::st_read(file.path(data_path, "contour_500.gpkg")) %>%
  sf::st_transform(crs = kos_crs) %>%
  sf::st_cast("POLYGON")

rings <- st_geometry(bndry)[[1]]

# The first element is the exterior ring (index 1).
bndry <- rings[1] %>%
  st_polygon() %>%  # Reconstruct the polygon using only the exterior ring
  st_sfc() %>%
  sf::st_sf(crs = kos_crs)


## Planning Units ----------------------------------------------------------

# First get all the cells wtihin the bndry
pgrid <- get_grid(boundary = bndry,
                  resolution = 100, # 50
                  crs = kos_crs,
                  touches = TRUE)

# Second, remove the cells that intersect the coast (on-land) polygons by masking
# Set cells covered by coast polygons to NA to exclude them from the planning grid
# inverse=TRUE means: set NA where polygons exist (i.e., mask the intersection)
# touches=TRUE includes cells that touch the polygon boundary
pgrid <- terra::mask(pgrid, terra::vect(coast), inverse = TRUE, touches = FALSE)

# Check cells
ggplot() +
  tidyterra::geom_spatraster(data = pgrid) +
  tidyterra::geom_spatvector(data = terra::vect(coast), colour = "red")


# Do features -----


## Allen Coral Atlas -------------------------------------------------------

benthic_allen <- read_sf(file.path(data_path, "benthic.geojson")) %>%
  filter(class %in% c("Seagrass", "Coral/Algae")) %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   feature_names = "class",
                   antimeridian = FALSE,
                   cutoff = 0.1)



## Ocean Use Survey --------------------------------------------------------

# Features: Tourism, Community and recreational use (you can use binary values)
# Cost: OUS fisheries data (you already have in the app), maybe also include bottom fishing and trolling (have values across most of the planning area)
# Locked-out: Construction and infrastructure (binary values)
#
# ous <- terra::rast(c(
#   file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "aquaculture.tif")
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "community_recreational_use.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "construction_and_infrastructure.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "cultural_use.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "maritime_activity.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "other.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "research.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "transportation.tif"),
#   # file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "tourism.tif"),
# )) %>%
#   get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)

# ous[ous>=1] <- 1 # Cutoff of 1
# ous[ous<1] <- 0 # Cutoff of 1


ous <- read_sf(file.path(data_path, "aquaculture_ous_polygons.gpkg")) %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   name = "aquaculture",
                   antimeridian = FALSE,
                   cutoff = 0.1)



files <- list.files(file.path(data_path, "ocean-use-survey", "subsectors"), recursive = TRUE, pattern = ".tif$", full.names = TRUE)

x <- files[1]


terra::rast(x) %>% get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)

ous_ss <- purrr::map(files, \(x) terra::rast(x) %>% get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE)) %>%
  terra::rast()

ous_ss[ous_ss>=1] <- 1 # Cutoff of 1
ous_ss[ous_ss<1] <- 0 # Cutoff of 1



## Depth Zones from GEBCO Bathymetry -------
depth_zones <- sf::st_read(file.path(data_path, "depth_zones.geojson")) %>%
  sf::st_as_sf() %>%
  dplyr::mutate(zone = janitor::make_clean_names(zone, case = "snake")) %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   feature_names = "zone",
                   antimeridian = FALSE,
                   cutoff = 1e-10) %>%
  terra::app(fun=function(x) {
    if(all(is.na(x))) return(x)
    max_val <- max(x, na.rm=TRUE)
    if(max_val == 0) return(x * 0)  # All zeros case
    max_idx <- which.max(x)  # Returns index of first maximum
    result <- x * 0  # Set all to zero
    result[max_idx] <- x[max_idx]  # Keep only the first maximum
    return(result)
  })



## Geomorphology -----------------------------------------------------------
geomorph <- sf::st_read(file.path(data_path, "reef_geomorph_complete.geojson")) %>%
  filter(class %in% c("Reef flat", "Forereef", "Diffuse fringing")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   meth = "average",
                   feature_names = "class",
                   antimeridian = FALSE,
                   cutoff = 0.1) %>%
  terra::app(fun=function(x) {
    if(all(is.na(x))) return(x)
    max_val <- max(x, na.rm=TRUE)
    if(max_val == 0) return(x * 0)  # All zeros case
    max_idx <- which.max(x)  # Returns index of first maximum
    result <- x * 0  # Set all to zero
    result[max_idx] <- x[max_idx]  # Keep only the first maximum
    return(result)
  })




## Mangroves ---------------------------------------------------------------

mangroves <- sf::st_read(file.path(data_path, "mangroves_usgs.geojson")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   name = "Mangroves",
                   # meth = "average",
                   # feature_names = "class",
                   antimeridian = FALSE,
                   cutoff = 0.1)



## Fisheries Attraction Device (FAD) ---------------------------------------
#
# fad <- sf::st_read(file.path(data_path, "fad_buffer.geojson")) %>%
#   sf::st_as_sf() %>%
#   sf::st_make_valid() %>%
#   get_data_in_grid(spatial_grid = pgrid,
#                    dat = .,
#                    # meth = "average",
#                    # feature_names = "class",
#                    antimeridian = FALSE,
#                    cutoff = 0.1)



## Reef monitoring data ----------------------------------------------------

reefscores <- c(terra::rast(file.path(data_path, "reefmonitoringJF", "fish_scores_interp_upper_quant.tif")) %>%
                  get_data_in_grid(spatial_grid = pgrid,
                                   dat = .,
                                   meth = "average",
                                   antimeridian = FALSE,
                                   cutoff = 0.1),
                terra::rast(file.path(data_path, "reefmonitoringJF", "benthic_scores_interp_upper_quant.tif")) %>%
                  get_data_in_grid(spatial_grid = pgrid,
                                   dat = .,
                                   meth = "average",
                                   antimeridian = FALSE,
                                   cutoff = 0.1))
names(reefscores) <- c("fish_scores", "benthic_scores")

reefscores <- (reefscores > 0) * 1


## Spawning aggregations ---------------------------------------------------

spawning <- sf::st_read(file.path(data_path, "spawning_aggs_by_species.gpkg")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   # meth = "average",
                   feature_names = "species_translated",
                   antimeridian = FALSE,
                   cutoff = 0.1)



## Locked in areas ---------------------------------------------------------

# ous_lock <- c(terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "aquaculture.tif")) %>%
#                 get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
#               terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "construction_and_infrastructure.tif")) %>%
#                 get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE))
#
# ous[ous>=1] <- 1 # Cutoff of 1


# Make test polygon file for category testing

sf::st_read(file.path(data_path, "kos_protected_areas.geojson")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  sf::st_write(file.path(data_path,"KosraeMPA.gpkg"))




## Marine Protected Areas --------------------------------------------------

mpas <- sf::st_read(file.path(data_path, "kos_protected_areas.geojson")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  get_data_in_grid(spatial_grid = pgrid,
                   dat = .,
                   name = "mpas",
                   # meth = "average",
                   # feature_names = "class",
                   antimeridian = FALSE,
                   cutoff = 0.1)

# Create feature dataframe ------------------------------------------------

dat_sf <- c(benthic_allen, depth_zones, geomorph, mangroves, mpas, ous, ous_ss, reefscores, spawning) %>%
  terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, na.all = TRUE, round = FALSE) %>%
  sf::st_as_sf() %>%
  mutate(across(everything(), ~replace_na(.x, 0))) %>%
  janitor::clean_names() %>%
  sf::st_transform(kos_crs)


PUs <- dat_sf %>%
  dplyr::select(geometry)


## Remove cost layers from dat_sf
dat_sf <- dat_sf %>%
  dplyr::select(-c("bottom_fishing", "trolling"))

# Add cost data -----------------------------------------------------------
ous_cost <- c(
  # terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "fisheries.tif")) %>%
  #               get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
  # terra::rast(file.path(data_path, "ocean-use-survey", "kosrae_ous_heatmaps", "maritime_activity.tif")) %>%
  #   get_data_in_grid(spatial_grid = pgrid, dat = ., meth = "average", antimeridian = FALSE),
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


ous_cost <- ous_cost %>%
  mutate(cellID = row_number())

# Function to impute missing values for a column in an sf object
impute_nearest <- function(df, value_col, id_col = "cellID") {
  has_value <- df %>% dplyr::filter(!is.na(.data[[value_col]]))
  needs_imputation <- df %>% dplyr::filter(is.na(.data[[value_col]]))
  if (nrow(needs_imputation) == 0) return(df)
  nearest_index <- sf::st_nearest_feature(needs_imputation, has_value)
  imputed_values <- has_value[[value_col]][nearest_index]
  needs_imputation[[value_col]] <- imputed_values
  dplyr::bind_rows(has_value, needs_imputation) %>% dplyr::arrange(.data[[id_col]])
}

# Add cellID and impute missing values for both columns
ous_cost <- impute_nearest(ous_cost, "bottom_fishing")
ous_cost <- impute_nearest(ous_cost, "trolling")


# Replace zeroes in bottom_fishing and trolling with small value to avoid zero cost
# The small number should be half the minimum non-zero value in each column
ous_cost <- ous_cost %>%
  mutate(
    bottom_fishing = if_else(bottom_fishing == 0, min(bottom_fishing[bottom_fishing > 0]) / 2, bottom_fishing),
    trolling = if_else(trolling == 0, min(trolling[trolling > 0]) / 2, trolling)
  )


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


PU_Area <- as.numeric(units::set_units(st_area(PUs)[1], km^2)) %>%
  round(2)

cost <- ous_cost %>%
  splnr_get_distCoast(custom_coast = coast) %>%   # Distance to nearest coast
  dplyr::mutate(
    # coastDistance_km = if_else(coastDistance_km < 0.1, 0.1, coastDistance_km),
    # Cost_Distance = 1/coastDistance_km,
    Cost_Area = PU_Area,
    # Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001),
    # Cost_FishingHrs = dplyr::if_else(Cost_FishingHrs == 0, 0.00001, Cost_FishingHrs),
  ) %>%
  # dplyr::select(-coastDistance_km) %>%
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
#
# # Start with 0.5 deg files
# climate_sf <- bind_cols(
#   read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp245_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
#     sf::st_drop_geometry() %>%
#     dplyr::select("slpTrends_245"="slpTrends"),
#   read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp370_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
#     sf::st_drop_geometry() %>%
#     dplyr::select("slpTrends_370"="slpTrends"),
#   read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_trends_ssp585_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
#     dplyr::select("slpTrends_585"="slpTrends")) %>%
#   sf::st_as_sf() %>%
#   sf::st_transform(kos_crs) %>%
#   sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)
#
#
#
# # Now add High Res
# climate_sf <-
#   bind_cols(climate_sf,
#             read_rds(file.path("data-raw", "Kosrae", "climate_data", "tos_Omon_ensemble_highres-future_r1i1p1f1_RegriddedAnnual_20150101-205003311.rds")) %>%
#               sf::st_transform(kos_crs) %>%
#               dplyr::select("slpTrends_HR" = "slpTrends") %>%
#               sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE) %>%
#               sf::st_drop_geometry())





# Ecosystem Services ----

ES <- terra::mosaic(
  terra::rast("~/Nextcloud/MME1DATA-Q1215/WAITT_ES/Maxwell_2020_SOC_mangroves_2020/163E_05N/sol_soc.tha_mangroves.typology_m_30m_s0..100cm_2020_global_v1.1.tif"),
  terra::rast("~/Nextcloud/MME1DATA-Q1215/WAITT_ES/Maxwell_2020_SOC_mangroves_2020/162E_05N/sol_soc.tha_mangroves.typology_m_30m_s0..100cm_2020_global_v1.1.tif")) %>%
  get_data_in_grid(spatial_grid = PUs, dat = ., meth = "mean", antimeridian = FALSE, name = "soilOrganicCarbon_tPU") %>%
  dplyr::mutate(across(everything(), ~replace_na(., 0)),
                soilOrganicCarbon_tPU = soilOrganicCarbon_tPU * 1.00635) # Convert to total carbon per PU CellARea = 1.00635 ha


ES2 <- sf::st_read("~/Nextcloud/MME1DATA-Q1215/WAITT_ES/Beck_2018_CoralReef_CoastalProtection/AEB_Coral.gdb") %>%
  get_data_in_grid(spatial_grid = PUs, dat = .)





# This is just seagrass extent. Not sure there is any point using this at the moment.
# gmw <- terra::rast("/Users/jason/Nextcloud/MME1DATA-Q1215/WAITT_ES/gmw_mng_2020_v4019_gtiff/GMW_N06E163_v4019_mng.tif")
# ggplot() + geom_spatraster(data = gmw)

# Nothing for Kosrae
# tourism <- sf::st_read("/Users/jason/Nextcloud/MME1DATA-Q1215/WAITT_ES/Spalding_2017_CoralReef_TourismValue_OnReef/Coral_Reef_Tourism_Global_On_Reef_Tourism.shp") %>%
#   sf::st_transform(crs = st_crs(bndry)) %>%
#   sf::st_crop(bndry)


# Check for NAs
if (any(is.na(dat_sf))){
  dat_sf <- dat_sf %>%
    mutate(across(everything(), ~replace_na(., 0)))
}

# Save raw data -----------------------------------------------------------

dat_sf <- bind_cols(dat_sf,
                    # lock_in %>% sf::st_drop_geometry(),
                    cost %>% sf::st_drop_geometry(),
                    # climate_sf %>% sf::st_drop_geometry(),
                    ES %>% sf::st_drop_geometry(),
) %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())




save(dat_sf, bndry, coast, file = file.path("data-raw", name, paste0(name,"_RawData.rda")))

cat("Finished processing data")
