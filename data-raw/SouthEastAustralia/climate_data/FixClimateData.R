
library(raster)
library(sf)
library(tidyverse)
library(terra)
library(sf)

files <- list.files(pattern = ".rds", full.names = TRUE)

convert_files <- function(f){
  
  readRDS(f) %>%
  terra::rast() %>% # Needed here because the files are old raster files at the moment
  terra::project("EPSG:4326") %>% # Change it back ESPG4326 (not Pacific centred)
  terra::as.polygons(trunc = FALSE, dissolve = FALSE, na.rm = TRUE, round = FALSE) %>%
  sf::st_as_sf() %>%
  saveRDS(file = f)
}

purrr::walk(files, convert_files)

