library(tidyverse)
library(spatialplanr)
library(oceandatr)
library(spatialgridr)

country <- "Vanuatu"
proj <- "ESRI:54009"
res <- 10000 # 20 km x 20 km

# Get eez to create grid
eez <- spatialgridr::get_boundary(name = country) %>%
  sf::st_transform(crs = proj) %>%
  sf::st_geometry() %>%
  sf::st_sf()

# Separate Boundary and Coastline
bndry <- eez %>%
  sf::st_cast(to = "POLYGON") %>%
  dplyr::mutate(Area_km2 = sf::st_area(.) %>%
                  units::set_units("km2") %>%
                  units::drop_units())

coast <- rnaturalearth::ne_countries(country = country, scale = "medium", returnclass = "sf")

PUs <- spatialgridr::get_grid(boundary = eez,
                                    crs = proj,
                                    output = "sf_hex",
                                    resolution = res)


# Check data
ggplot() +
  geom_sf(data = PUs, fill = NA) +
  geom_sf(data = eez, fill = NA, colour = "red") +
  geom_sf(data = bndry, fill = NA, colour = "blue")


# Compile datasets -------------------------------------------------------------

dat_sf <- bind_cols(
  oceandatr::get_bathymetry(spatial_grid = PUs, keep = FALSE) %>% sf::st_drop_geometry(),
  oceandatr::get_geomorphology(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_knolls(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_seamounts(spatial_grid = PUs, buffer = 30000) %>% sf::st_drop_geometry(),
  oceandatr::get_coral_habitat(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_enviro_regions(spatial_grid = PUs, max_num_clusters = 5)
) %>%
  dplyr::mutate(across(everything(), ~replace_na(.x, 0)))



# Add cost data -----------------------------------------------------------


gfw_cost <- spatialplanr::splnr_get_gfw(region = country,
                                        start_date = "2014-01-01",
                                        end_date = "2023-12-31",
                                        temp_res = "YEARLY",
                                        spat_res = "LOW",
                                        compress = TRUE) %>%
  dplyr::select(-GFWregionID) %>%
  dplyr::mutate(ApparentFishingHrs = if_else(ApparentFishingHrs > 1000, NA, ApparentFishingHrs)) %>%
  sf::st_transform(sf::st_crs(PUs)) %>%
  sf::st_interpolate_aw(., PUs, extensive = TRUE, keep_NA = TRUE)


cost <- PUs %>%
  splnr_get_distCoast(custom_coast = coast) %>%  # Distance to nearest coast
  dplyr::rename(Cost_Distance = coastDistance_km) %>%
  dplyr::mutate(Cost_None = 0.1,
                Cost_Random = runif(dim(.)[1]),
                Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001)) %>%
  dplyr::relocate(geometry, .after = tidyselect::last_col())


# Locked in areas ---------------------------------------------------------

# TODO These are only point MPAs. Need some polygons to do this right.
#
# lock_in <- country %>%
#   lapply(wdpar::wdpa_fetch,
#          wait = TRUE,
#          download_dir = rappdirs::user_data_dir("wdpar")
#   ) %>%
#   dplyr::bind_rows() %>%
#   dplyr::filter(.data$MARINE > 0) %>%
#   sf::st_transform(crs = proj) %>%
#   dplyr::select(geometry) %>%
#   spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "MPAs")
#
# ggplot(lock_in, aes(fill = MPAs)) + geom_sf()


# Climate Data ------------------------------------------------------------

# Start with 1 climate layer called metric. Then come back and add other layers wth unique names
climate_sf <- bind_cols(
  read_rds(file.path("data-raw", "Vanuatu", "climate_data", "tos_Omon_trends_ssp245_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    sf::st_drop_geometry() %>% dplyr::select("slpTrends_245"="slpTrends"),
  read_rds(file.path("data-raw", "Vanuatu", "climate_data", "tos_Omon_trends_ssp370_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    sf::st_drop_geometry() %>% dplyr::select("slpTrends_370"="slpTrends"),
  read_rds(file.path("data-raw", "Vanuatu", "climate_data", "tos_Omon_trends_ssp585_r1i1p1f1_RegriddedAnnual_20150101-21001231.rds")) %>%
    dplyr::select("slpTrends_585"="slpTrends")) %>%
  sf::st_as_sf() %>%
  sf::st_transform(proj) %>%
  sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)


# Save raw data -----------------------------------------------------------

dat_sf <- bind_cols(dat_sf,
                    # lock_in %>% sf::st_drop_geometry(),
                    cost %>% sf::st_drop_geometry(),
                    climate_sf %>% sf::st_drop_geometry()) %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())

# rm(cost, lock_in, eez)



save(dat_sf, bndry, coast, file = file.path("data-raw", country, paste0(country,"_RawData.rda")))

