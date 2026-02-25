library(tidyverse)
library(spatialplanr)
library(oceandatr)
library(rnaturalearth)
library(sf)
library(terra)
library(gfwr)

# TODO Add check that all names in Dict are unique. Or change target plotting to
# use variable name rather than the common name. It would be good to have the
# same Common name if needed.

data_path <- file.path("data-raw", "SouthEastAustralia", "SEAustraliaData")

name <- "South East Australia"
country = "Australia"

# Set up geospatial data ------

#kosrae equal area projection from projection wizard, found using bbox of 12nm limits
aus_crs <- "+proj=aea +lon_0=146.4038086 +lat_1=-40.8934514 +lat_2=-37.9069435 +lat_0=-39.4001975 +datum=WGS84 +units=m +no_defs"

## Boundary ----------------------------------------------------------

bndry <- spatialplanr::splnr_create_polygon(dplyr::tibble(
  x = c(142, 150, 150, 142, 142),
  y = c(-37.6, -37.6, -41.5, -41.5, -37.6)
), cCRS = aus_crs)


## Coastline --------------------------------------------------------

coast <- rnaturalearth::ne_countries(scale = 10, country = country) %>%
  sf::st_transform(crs = aus_crs) %>%
  sf::st_crop(bndry)

ggplot() + geom_sf(data = coast) + geom_sf(data = bndry, colour = "red", fill = NA)

## Planning Units ----------------------------------------------------------


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


# First get all the cells within the bndry
PUs <- get_grid(boundary = bndry,
                  resolution = 5000,
                  crs = aus_crs,
                  touches = TRUE,
                  output = "sf_hex")


PUs <- splnr_remove_PUs(PUs, coast)


ggplot() +
  geom_sf(data = PUs, colour = "black") +
  geom_sf(data = coast, colour = "red")


# Do features -----


dat_sf <- bind_cols(
  oceandatr::get_bathymetry(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_geomorphology(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_knolls(spatial_grid = PUs) %>% sf::st_drop_geometry(),
  oceandatr::get_seamounts(spatial_grid = PUs, buffer = 30000) %>% sf::st_drop_geometry(),
  oceandatr::get_enviro_zones(spatial_grid = PUs, max_num_clusters = 5, show_plots = FALSE) %>% sf::st_drop_geometry(),
  oceandatr::get_coral_habitat(spatial_grid = PUs)
) %>%
  dplyr::mutate(across(everything(), ~replace_na(.x, 0))) # Replace NA/NaN with 0


# Add cost data -----------------------------------------------------------

gfw_cost <- splnr_get_gfw(region = country, "2014-01-01", "2023-12-31", "YEARLY", spat_res = "LOW", compress = TRUE) %>%
  dplyr::mutate(ApparentFishingHrs = if_else(ApparentFishingHrs > 1000, NA, ApparentFishingHrs)) %>%
  dplyr::select(-GFWregionID) %>%
  sf::st_transform(sf::st_crs(PUs)) %>%
  sf::st_interpolate_aw(., PUs, extensive = TRUE, keep_NA = TRUE)


cost <- PUs %>%
  splnr_get_distCoast(custom_coast = coast) %>%  # Distance to nearest coast
  dplyr::rename(Cost_Distance = coastDistance_km) %>%
  dplyr::mutate(Cost_None = 0.1,
                Cost_Random = runif(dim(.)[1]),
                Cost_Distance = 1/Cost_Distance,
                Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001)) %>%
  dplyr::relocate(geometry, .after = tidyselect::last_col())


# Locked in areas ---------------------------------------------------------

# TODO These are only point MPAs. Need some polygons to do this right.

lock_in <- country %>%
  lapply(wdpar::wdpa_fetch,
         wait = TRUE,
         # force = TRUE,
         download_dir = rappdirs::user_data_dir("wdpar")
  ) %>%
  dplyr::bind_rows() %>%
  dplyr::filter(.data$MARINE > 0) %>%
  sf::st_transform(crs = aus_crs) %>%
  dplyr::select(geometry) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "MPAs", cutoff = 0.5)




# Multiple Use

MultiUse <- st_read(file.path(data_path, "OffshoreRenewable_Energy_Infrastructure_Regions_987513835804844725.gpkg")) %>%
  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "REI", cutoff = 0.5)


ggplot() + geom_sf(data = MultiUse, aes(fill = REI))


# Ecosystem Services


ES <- sf::st_read("/Users/jason/Nextcloud/MME1DATA-Q1215/WAITT_ES/Menendez_2020_CoastalProtection/3_CoastalStudyUnit Aggregations/UCSC_CWON_studyunits.gpkg") %>%
  filter(ISO3 == "AUS") %>%
  sf::st_transform(aus_crs) %>%
  sf::st_crop(bndry) %>%
  dplyr::select(all_of(c("Risk_Pop_2020", "Risk_Stock_2020"))) %>%
  sf::st_interpolate_aw(., PUs, extensive = FALSE, keep_NA = FALSE) #, "Ben_Stock_2020")) # Benefits to population, Benefits to Property

EcoServ <- sf::st_join(PUs, ES, join = st_equals)




# Summarise
dat_sf <- bind_cols(dat_sf,
                    lock_in %>% sf::st_drop_geometry(),
                    cost %>% sf::st_drop_geometry(),
                    EcoServ %>% sf::st_drop_geometry(),
                    MultiUse %>% sf::st_drop_geometry()) %>%
  dplyr::relocate(geometry, .after = tidyselect::everything())

rm(cost, lock_in, eez)


save(dat_sf, bndry, coast, file = file.path("data-raw", "SouthEastAustralia", "SouthEastAustralia_RawData.rda"))

cat("Finished processing data")
