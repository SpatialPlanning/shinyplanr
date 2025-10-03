library(tidyverse)
library(spatialplanr)
library(oceandatr)
library(sf)
library(terra)

# Monkey patch httr2 to disable SSL verification
original_req_perform <- httr2::req_perform
assignInNamespace("req_perform", function(req, ...) {
  req <- httr2::req_options(req, ssl_verifypeer = 0L, ssl_verifyhost = 0L)
  original_req_perform(req, ...)
}, ns = "httr2")

# Temporarily disable SSL verification - set multiple options to ensure it works
Sys.setenv(CURL_SSL_VERIFYPEER = "0")
Sys.setenv(CURL_SSL_VERIFYHOST = "0")
options(download.file.method = "curl", download.file.extra = "-k")


# The basics -------
data_path <- file.path("data-raw", "Fiji", "FijiData")
name <- "Fiji"
fiji_crs <- "EPSG:32760"


# Boundaries -----

Fiji_eez <- oceandatr::get_boundary(name = "Fiji", type = "eez") %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude() %>%
  sf::st_transform(fiji_crs)

# Fiji_12nmMR <- oceandatr::get_boundary(name = "Fiji", type = "12nm") %>%
#   sf::st_make_valid() %>%
#   sf::st_shift_longitude() %>%
#   sf::st_transform(fiji_crs)

Fiji_12nm <- sf::st_read(file.path(data_path, "Fiji_12nm", "Fiji_12nm.shp")) %>%
  sf::st_transform(fiji_crs) %>%
  sf::st_union() %>%
  sf::st_cast(to = "POLYGON")

# ggplot(data = Fiji_12nm) + geom_sf()


# Fiji_24nm <- oceandatr::get_boundary(name = "Fiji", type = "24nm") %>%
#   sf::st_make_valid() %>%
#   sf::st_shift_longitude() %>%
#   sf::st_transform(fiji_crs)

Fiji_cntry <- rnaturalearth::ne_countries(scale = 10, country = "Fiji") %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude() %>%
  sf::st_transform(fiji_crs) %>%
  sf::st_cast(to = "POLYGON")

# Fiji_arch <- oceandatr::get_boundary(name = "Fiji", type = "archipelagic") %>%
#   sf::st_make_valid() %>%
#   sf::st_shift_longitude() %>%
#   sf::st_transform(fiji_crs)


# The seasketch territorial waters layer is way different to the Marine Regions one.
# Fiji_terr <- sf::st_read(file.path(data_path, "TerritorialSeas_Fiji.fgb")) %>%
#   sf::st_as_sf() %>%
#   sf::st_transform(fiji_crs) %>%
#   sf::st_cast(to = "LINESTRING") %>%
#   sf::st_cast(to = "POLYGON")

# Fiji_terr2 <- sf::st_read(file.path(data_path, "FijiTerritorial_MR.json")) %>%
#   sf::st_as_sf() %>%
#   sf::st_transform(fiji_crs)
# ggplot(data = Fiji_terr2) + geom_sf()

ggplot() +
  geom_sf(data = Fiji_eez, colour = "red", linewidth = 0.1) +
  # geom_sf(data = Fiji_arch, fill = "orange", linewidth = 0.01) +
  geom_sf(data = Fiji_12nm, fill = "green", linewidth = 0.01) +
  # geom_sf(data = Fiji_12nmMR, fill = "yellow", linewidth = 0.01) +
  # geom_sf(data = Fiji_24nm, fill = "blue", linewidth = 0.01) +
  geom_sf(data = Fiji_cntry, fill = "black", linewidth = 0.01)
# geom_sf(data = Fiji_terr, fill = "purple", linewidth = 0.1)

# Planning Units ------

pgrid <- sf::st_make_grid(Fiji_eez, cellsize = 10000) %>% # cellsize in m
  sf::st_sf()

ggplot(data = pgrid) + geom_sf()

# First get all the PUs partially/wholly within the planning region
logi_Reg <- sf::st_centroid(pgrid) %>%
  sf::st_intersects(Fiji_eez) %>%
  lengths() > 0 # Get logical vector instead of sparse geometry binary

pgrid <- pgrid[logi_Reg, ] # Get TRUE

ggplot(data = pgrid) + geom_sf()

logi_Reg <- sf::st_centroid(pgrid) %>%
  sf::st_intersects(Fiji_12nm) %>%
  lengths() > 0 # Get logical vector instead of sparse geometry binary

pgrid <- pgrid[!logi_Reg, ]%>% # Get FALSE
  mutate(cellID = row_number())



ggplot(data = pgrid) + geom_sf()

ggplot() +
  geom_sf(data = Fiji_eez, colour = "red", linewidth = 0.1) +
  geom_sf(data = Fiji_12nm, fill = "green", linewidth = 0.01) +
  # geom_sf(data = Fiji_24nm, fill = "blue", linewidth = 0.01) +
  # geom_sf(data = Fiji_arch, fill = "orange", linewidth = 0.01) +
  geom_sf(data = Fiji_cntry, colour = "black", linewidth = 0.01) +
  # geom_sf(data = Fiji_terr, colour = "purple", linewidth = 0.2) +
  geom_sf(data = pgrid, colour = "black", fill = NA)


pgrid4326 <- pgrid %>%
  sf::st_transform("EPSG:4326")

# Benthic Richness -----

# Not sure we can use this. Its richness.
# benthic <- sf::st_read(file.path(data_path, "ECO_benthic_species_richness.geojson")) %>%
#   sf::st_as_sf() %>%
#   sf::st_transform(fiji_crs)
# ggplot() + geom_sf(data = benthic, aes(fill = DeepSpCoun))


# Special and Unique Marine Areas -----

SUMA <- sf::st_read(file.path(data_path, "ECO_suma.geojson")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  sf::st_transform(fiji_crs) %>%
  dplyr::select(geometry) %>%
  sf::st_union() %>% # Getting errors so need to unionise
  sf::st_as_sf() %>%
  spatialgridr::get_data_in_grid(spatial_grid = pgrid, dat = ., cutoff = 0.1, name = "SUMA")

ggplot() +
  geom_sf(data = SUMA, aes(fill = as.logical(SUMA))) +
  geom_sf(data = Fiji_cntry, fill = "black", colour = "black")


# ISRAs -----

ISRA <- sf::st_read(file.path(data_path, "isra_region10", "isra_region10.shp")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  sf::st_transform(fiji_crs) %>%
  sf::st_as_sf() %>%
  spatialgridr::get_data_in_grid(spatial_grid = pgrid, dat = ., cutoff = 0.1, name = "ISRA")

ggplot() + geom_sf(data = ISRA, aes(fill = ISRA), show.legend = FALSE)

# IBAs -------

IBA <- sf::st_read(file.path(data_path, "IBAs", "sites.shp")) %>%
  sf::st_as_sf() %>%
  sf::st_make_valid() %>%
  sf::st_transform(fiji_crs) %>%
  sf::st_as_sf() %>%
  sf::st_crop(Fiji_cntry) %>%
  filter(IbaStatus == "confirmed") %>%
  spatialgridr::get_data_in_grid(spatial_grid = pgrid, dat = ., cutoff = 0.1, name = "IBA")

ggplot() + geom_sf(data = IBA, aes(fill = IBA), show.legend = TRUE)


 # Geomorphology ------
# geomorph <- sf::st_read(file.path(data_path, "geomorphic-crop.fgb")) %>%
#   sf::st_as_sf() %>%
#   sf::st_transform(fiji_crs) %>%
#   spatialgridr::get_data_in_grid(spatial_grid = pgrid,
#                                  dat = .,
#                                  feature_names = "class")

# TOO BIG TO PLOT??
# ggplot() + geom_sf(data = geomorph, aes(fill = class), show.legend = FALSE)

# Seamounts -----

# NEEDS TO BE CHECKED BECAUSE I AM ONLY DOING A ROUGH INTERSECTS
seamounts_temp <- sf::st_read(file.path(data_path, "Seamounts", "Seamounts.shp")) %>%
  sf::st_sf() %>%
  sf::st_break_antimeridian() %>%
  sf::st_make_valid()

out <- sf::st_intersects(pgrid4326, seamounts_temp) %>%
  lengths() > 0 # Get logical vector instead of sparse geometry binary

seamounts <- pgrid4326 %>%
  mutate(seamounts = out) %>%
  sf::st_transform(fiji_crs) %>%
  sf::st_as_sf()

ggplot() + geom_sf(data = seamounts, aes(fill = seamounts), colour = NA, show.legend = TRUE)


# Deepwater Bioregions -----

# I need to write code for the app for bioregionalisation
bioregions <- sf::st_read(file.path(data_path, "Revised_Deepwater_Bioregions_Fj", "Revised_Deepwater_Bioregions_Fj.shp")) %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude() %>%
  sf::st_transform(fiji_crs) %>%
  spatialgridr::get_data_in_grid(spatial_grid = pgrid,
                                 dat = .,
                                 feature_names = "Draft_name")

ggplot() + geom_sf(data = bioregions %>%
                     pivot_longer(cols = !tidyselect::contains("geometry")) %>%
                     dplyr::filter(value == 1),
                   aes(fill = name), show.legend = FALSE)


# Depth zones ------
depth_zones <- oceandatr::get_bathymetry(spatial_grid = pgrid4326,
                                         classify_bathymetry = TRUE,
                                         above_sea_level_isNA = FALSE,
                                         keep = TRUE) %>%
  sf::st_transform(fiji_crs)



ggplot() + geom_sf(data = depth_zones %>%
                     pivot_longer(cols = !tidyselect::contains("geometry")) %>%
                     dplyr::filter(value > 0),
                   aes(fill = name))

# Marine Protected Areas -----

# No MPAs outside 12 NM in Fiji?
# MPAs <- spatialplanr::splnr_get_MPAs(pgrid4326, Countries = "Fiji") %>%
#   sf::st_transform(fiji_crs)
#
# ggplot(data = MPAs) + geom_sf()


# Locked in areas ---------------------------------------------------------
# None offshore at this stage


# Join all datasets

dat_sf <- seamounts %>% sf::st_drop_geometry() %>%
  left_join(SUMA %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(depth_zones %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(ISRA %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(IBA %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(bioregions %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(pgrid, by = "cellID") %>%
  mutate(across(everything(), ~replace_na(.x, 0))) %>%
  mutate(across(where(is.logical), as.numeric)) %>%
  janitor::clean_names() %>%
  dplyr::rename(cellID = cell_id) %>%
  sf::st_sf()

ggplot(data = dat_sf) +geom_sf(aes(fill = iba))


PUs <- dat_sf %>%
  dplyr::select(geometry)


gfw <- rast(list.files(file.path(data_path, "GFW"), full.names = TRUE)) %>%
  mean(na.rm = TRUE) %>%
  spatialgridr::get_data_in_grid(spatial_grid = pgrid4326, dat = .) %>% # Need an option to fill NAs
  sf::st_transform(fiji_crs, method = "bilinear")

gfw_min <- min(gfw$mean, na.rm = TRUE)/2

gfw <- gfw %>%
  dplyr::mutate(mean = dplyr::if_else(is.na(mean), gfw_min, mean)) %>%
  dplyr::rename(GlobalFishingWatch = mean)

ggplot(data = gfw) + geom_sf(aes(fill = log10(GlobalFishingWatch)))


# I need to modify Fiji_cntry as some land is outside the 12nm at the moment
# due to an error in the polygons. Add a check here to deal with it.

Fiji_cntry12 <- st_filter(
  x = Fiji_cntry,
  y = Fiji_12nm,
  .predicate = st_within
)

ggplot() +
  geom_sf(data = Fiji_eez, colour = "red", linewidth = 0.1) +
  geom_sf(data = Fiji_12nm, fill = "green", linewidth = 0.01) +
  geom_sf(data = Fiji_cntry, fill = "black", linewidth = 0.01) +
  geom_sf(data = Fiji_cntry12, fill = "purple", linewidth = 0.01)


cost <- gfw %>%
  splnr_get_distCoast(custom_coast = Fiji_cntry12) %>%  # Distance to nearest coast
  dplyr::mutate(coastDistance_km = if_else(coastDistance_km == 0, .Machine$double.eps, coastDistance_km),
                Cost_Distance = 1/coastDistance_km,
                Cost_None = 0.1,
                # Cost_FishingHrs = tidyr::replace_na(gfw_cost$ApparentFishingHrs, 0.00001),
                # Cost_FishingHrs = dplyr::if_else(Cost_FishingHrs == 0, 0.00001, Cost_FishingHrs),
  ) %>%
  dplyr::select(-coastDistance_km) %>%
  dplyr::relocate(geometry, .after = tidyselect::last_col())


ggplot(data = cost) + geom_sf(aes(fill = Cost_Distance))

# Climate Data ------------------------------------------------------------

# Start with 0.5 deg files

fil <- list.files(file.path(data_path, "Climate"), full.names = TRUE)

sr_unwrap <- function(x){
  out <- read_rds(x) %>%
    terra::unwrap() %>%
    terra::subset("slpTrends")
  names(out) <- sub("\\.RDS$", "", basename(x))

  return(out)

}

rclimate <- purrr::map(fil, sr_unwrap) %>%
  rast()

lat_min <- -30
lat_max <- 0
ext_east <- ext(170, 180, lat_min, lat_max)
ext_west <- ext(-180, -170, lat_min, lat_max)
r_east <- crop(rclimate, ext_east)
r_west <- crop(rclimate, ext_west)
r_cropped_merged <- merge(r_east, r_west)

climate_temp <- r_cropped_merged %>%
  terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, na.all = TRUE, round = FALSE) %>%
  sf::st_as_sf()

# Convert to the PUs
nearest_indices <- st_nearest_feature(pgrid4326, climate_temp)

climate_sf <- st_drop_geometry(climate_temp)[nearest_indices, ] %>%
  as_tibble() %>%
  bind_cols(pgrid4326, .) %>%
  sf::st_transform(fiji_crs, method = "bilinear")

ggplot(data = climate_sf) + geom_sf(aes(
  fill = tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_recent_term,
  colour = tos_slpTrend_ensemble_ssp585_r1i1p1f1_rg_recent_term)) +
  scale_fill_viridis_c(option = "magma") +
  scale_colour_viridis_c(option = "magma")



# Save raw data -----------------------------------------------------------

dat_sf <- dat_sf %>%
  left_join(cost %>% sf::st_drop_geometry(), by = "cellID") %>%
  left_join(climate_sf %>% sf::st_drop_geometry(), by = "cellID") %>%
                    # lock_in %>% sf::st_drop_geometry(),
  dplyr::relocate(geometry, .after = tidyselect::everything())


save(dat_sf, Fiji_eez, Fiji_cntry, climate_sf, file = file.path("data-raw", name, paste0(name,"_RawData.rda")))

cat("Finished processing data")
