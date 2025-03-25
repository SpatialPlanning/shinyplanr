# Some code to create a hex sticker for the spatialplanr package
#
# Last updated: Saturday 8th July 2023
#
# Jason D. Everett (UQ/CSIRO/UNSW)
#
# For installation instructions see here:
# https://github.com/GuangchuangYu/hexSticker

# devtools::install_github("GuangchuangYu/hexSticker")

library(spatialplanr)
library(tidyverse)
library(sf)

cCRS <- "EPSG:4326"


create_hexagon <- function(center_x, center_y, size, top_type) {
  if (top_type == "flat" || top_type == "flat_topped") {
    angles <- seq(0, 300, by = 60)
  } else if (top_type == "pointy" || top_type == "pointed" || top_type == "pointed_top") {
    angles <- seq(30, 360, by = 60)
  } else {
    stop("Invalid top_type. Must be 'flat' or 'pointy'.")
  }

  vertices <- matrix(0, nrow = length(angles), ncol = 2)

  for (i in 1:length(angles)) {
    angle <- angles[i]
    vertices[i, 1] <- center_x + size * cos(angle * pi / 180)
    vertices[i, 2] <- center_y + size * sin(angle * pi / 180)
  }

  # Close the polygon by duplicating the first vertex
  vertices <- rbind(vertices, vertices[1, ])

  out <- list()
  for (i in 1:length(angles)) {
    int <- sf::st_linestring(vertices[i:(i+1),]) %>%
      sf::st_segmentize(units::set_units(0.1, km)) %>%
      sf::st_coordinates()

    out[[i]] <- int[,1:2]

  }

  out2 <- list(do.call(rbind, out))

  # Create an sf polygon
  polygon <- sf::st_polygon(out2)

  return(polygon)
}

Bndry <- create_hexagon(-150, -5, 70*1.1547, "pointed") %>%
  sf::st_polygon() %>%
  sf::st_sfc(crs = "EPSG:4326") %>%
  sf::st_sf() %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude()

ggplot() + geom_sf(data = Bndry)



polygon <- sf::st_polygon(x = list(rbind(
  c(-0.0001, 90),
  c(0, 90),
  c(0, -90),
  c(-0.0001, -90),
  c(-0.0001, 90)))) %>%
  sf::st_sfc() %>%
  sf::st_set_crs(cCRS)

# Modify world dataset to remove overlapping portions with world's polygons
landmass <- rnaturalearth::ne_countries(scale = "medium", returnclass = "sf") %>%
  sf::st_transform(cCRS) %>% # The input needs to be unprojected.
  sf::st_make_valid() %>% # Just in case....
  sf::st_difference(polygon) %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude() %>%
  sf::st_intersection(Bndry) %>%
  sf::st_shift_longitude()

ggplot() +
  geom_sf(data = landmass)

# This block works
PUs <- sf::st_make_grid(Bndry,
                        square = FALSE,
                        cellsize = c(4, 4),
                        what = "polygons") %>%
  sf::st_sf() %>%
  sf::st_intersection(Bndry) %>%
  sf::st_shift_longitude()

ggplot() +
  geom_sf(data = PUs)


ggplot() +
  geom_sf(data = PUs) +
  geom_sf(data = Bndry, fill = NA) +
  geom_sf(data = landmass, fill = NA)


# PUs <- PUs %>%
#   dplyr::mutate(Prob = runif(dim(PUs)[1]))


# read the png file from device
img <- grid::rasterGrob(png::readPNG(file.path("data-raw", "shinyplanr", "shiny_black.png"), native = TRUE))



# Possible colours...
# https://www.pinterest.com.au/pin/sunset-color-scheme-image-search-results-in-2023--224194887692504381/



#
# (gg <- ggplot2::ggplot() +
#     ggplot2::geom_sf(data = PUs, colour = "#fdf7c2", linewidth = 0.05, show.legend = FALSE, ggplot2::aes(fill = Prob)) +
#     ggplot2::scale_fill_gradient(
#       low = "#9ac4e1", # "#84dfd3"
#       high = "#3b81bd"
#     ) +
#     ggplot2::geom_sf(data = landmass, colour = "grey40", fill = "grey20", alpha = 1, linewidth = 0.05, show.legend = FALSE) +
#     ggplot2::coord_sf(xlim = sf::st_bbox(PUs)$xlim, ylim = sf::st_bbox(PUs)$ylim) +
#     ggplot2::theme_void() +
#   ggplot2::annotation_custom(img, xmin = 150, xmax = 212, ymin = -35, ymax = 15)
# )
#
#
# hexSticker::sticker(gg,
#                     package = "planr",
#                     p_x = 1.38,
#                     p_y = 0.98,
#                     p_color = "black",
#                     p_family = "Aller_Rg",
#                     p_fontface = "bold",
#                     p_size = 80,
#                     s_x = 1,
#                     s_y = 1,
#                     s_width = 2.2,
#                     s_height = 2.2,
#                     # h_fill = "#9FE2BF",
#                     h_color = "grey90", # "grey40",
#                     dpi = 1000,
#                     asp = 1,
#                     filename = file.path("man", "figures", "logo.png")
# )



# read the png file from device
img <- grid::rasterGrob(png::readPNG(file.path("data-raw", "shinyplanr", "shiny_white.png"), native = TRUE))


MPA <- rbind(PUs[262,] %>% sf::st_buffer(dist = 1200000),
             PUs[375,] %>% sf::st_buffer(dist = 1100000),
             PUs[590,] %>% sf::st_buffer(dist = 1400000)
             ) %>%
  sf::st_shift_longitude() %>%
  sf::st_make_valid() %>%
  sf::st_shift_longitude() %>%
  st_filter(PUs %>% sf::st_make_valid() %>%
              sf::st_shift_longitude(),
            .,
            .predicate = st_within)


ggplot2::ggplot() +
  ggplot2::geom_sf(data = PUs, linewidth = 0.05, show.legend = TRUE, aes(fill = row_number(PUs))) +
  ggplot2::geom_sf(data = MPA, colour = "red", fill = "red", linewidth = 0.05, show.legend = FALSE)



MPA2 <- MPA %>%
  sf::st_union() %>%
  sf::st_shift_longitude()




ggplot2::ggplot() +
  ggplot2::geom_sf(data = PUs, linewidth = 0.05, show.legend = TRUE, aes(fill = row_number(PUs))) +
  ggplot2::geom_sf(data = MPA, colour = "red", fill = "red", alpha = 0.5, linewidth = 0.05, show.legend = FALSE) +
  ggplot2::geom_sf(data = MPA2, colour = "green", fill = NA, alpha = 0.5, linewidth = 0.5, show.legend = FALSE)



img <- grid::rasterGrob(png::readPNG(file.path("data-raw", "shinyplanr", "shiny_white.png"), native = TRUE))
pntr <- grid::rasterGrob(png::readPNG(file.path("data-raw", "shinyplanr", "AdobeStock_338133466_crop_rotate.png"), native = TRUE))



(gg <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = PUs, colour = "#4F4F51", fill = "#84A9BF", linewidth = 0.1, show.legend = FALSE) +
    ggplot2::geom_sf(data = landmass, colour = "grey70", fill = "#4F4F51", alpha = 1, linewidth = 0.05, show.legend = FALSE) +
    ggplot2::geom_sf(data = MPA, colour = "white", fill = "#46718C", alpha = 0.8, linewidth = 0.1, show.legend = FALSE) +
    ggplot2::geom_sf(data = MPA2, colour = "black", fill = NA, linewidth = 0.5, show.legend = FALSE) +
    ggplot2::coord_sf(xlim = sf::st_bbox(PUs)$xlim, ylim = sf::st_bbox(PUs)$ylim) +
    ggplot2::theme_void() +
    ggplot2::annotation_custom(img, xmin = 150, xmax = 212, ymin = -35, ymax = 15) +
    ggplot2::annotation_custom(pntr, xmin = 205, xmax = 230, ymin = 13, ymax = 38)
)


hexSticker::sticker(gg,
                    package = "planr",
                    p_x = 1.38,
                    p_y = 0.98,
                    p_color = "white",
                    p_family = "Aller_Rg",
                    p_fontface = "bold",
                    p_size = 80,
                    s_x = 1,
                    s_y = 1,
                    s_width = 2.2,
                    s_height = 2.2,
                    # h_fill = "#9FE2BF",
                    h_color = "black", # "grey40",
                    dpi = 1000,
                    asp = 1,
                    filename = file.path("man", "figures", "logo.png")
)





(gg <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = PUs, colour = "#4F4F51", fill = "#84A9BF", linewidth = 0.1, show.legend = FALSE) +
    ggplot2::geom_sf(data = landmass, colour = "grey70", fill = "#4F4F51", alpha = 1, linewidth = 0.05, show.legend = FALSE) +
    ggplot2::geom_sf(data = MPA, colour = "white", fill = "#46718C", alpha = 0.8, linewidth = 0.1, show.legend = FALSE) +
    ggplot2::geom_sf(data = MPA2, colour = "black", fill = NA, linewidth = 0.5, show.legend = FALSE) +
    ggplot2::coord_sf(xlim = sf::st_bbox(PUs)$xlim, ylim = sf::st_bbox(PUs)$ylim) +
    ggplot2::theme_void()
    # ggplot2::annotation_custom(img, xmin = 150, xmax = 212, ymin = -35, ymax = 15) +
    # ggplot2::annotation_custom(pntr, xmin = 205, xmax = 230, ymin = 13, ymax = 38)
)


hexSticker::sticker(gg,
                    package = "",
                    p_x = 1.38,
                    p_y = 0.98,
                    p_color = "white",
                    p_family = "Aller_Rg",
                    p_fontface = "bold",
                    p_size = 80,
                    s_x = 1,
                    s_y = 1,
                    s_width = 2.2,
                    s_height = 2.2,
                    # h_fill = "#9FE2BF",
                    h_color = "black", # "grey40",
                    dpi = 1000,
                    asp = 1,
                    filename = file.path("shinyplanr_Daniel.png")
)




(gg <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = PUs, colour = "#4F4F51", fill = "#84A9BF", linewidth = 0.1, show.legend = FALSE) +
    # ggplot2::geom_sf(data = landmass, colour = "grey70", fill = "#4F4F51", alpha = 1, linewidth = 0.05, show.legend = FALSE) +
    # ggplot2::geom_sf(data = MPA, colour = "white", fill = "#46718C", alpha = 0.8, linewidth = 0.1, show.legend = FALSE) +
    # ggplot2::geom_sf(data = MPA2, colour = "black", fill = NA, linewidth = 0.5, show.legend = FALSE) +
    ggplot2::coord_sf(xlim = sf::st_bbox(PUs)$xlim, ylim = sf::st_bbox(PUs)$ylim) +
    ggplot2::theme_void()
  # ggplot2::annotation_custom(img, xmin = 150, xmax = 212, ymin = -35, ymax = 15) +
  # ggplot2::annotation_custom(pntr, xmin = 205, xmax = 230, ymin = 13, ymax = 38)
)


hexSticker::sticker(gg,
                    package = "",
                    p_x = 1.38,
                    p_y = 0.98,
                    p_color = "white",
                    p_family = "Aller_Rg",
                    p_fontface = "bold",
                    p_size = 80,
                    s_x = 1,
                    s_y = 1,
                    s_width = 2.2,
                    s_height = 2.2,
                    # h_fill = "#9FE2BF",
                    h_color = "black", # "grey40",
                    dpi = 1000,
                    asp = 1,
                    filename = file.path("shinyplanr_Daniel2.png")
)


# This block works
PUs <- sf::st_make_grid(Bndry,
                        square = FALSE,
                        cellsize = c(2, 2),
                        what = "polygons") %>%
  sf::st_sf() %>%
  sf::st_intersection(Bndry) %>%
  sf::st_shift_longitude()



(gg <- ggplot2::ggplot() +
    ggplot2::geom_sf(data = PUs, colour = "#4F4F51", fill = "#84A9BF", linewidth = 0.1, show.legend = FALSE) +
    # ggplot2::geom_sf(data = landmass, colour = "grey70", fill = "#4F4F51", alpha = 1, linewidth = 0.05, show.legend = FALSE) +
    # ggplot2::geom_sf(data = MPA, colour = "white", fill = "#46718C", alpha = 0.8, linewidth = 0.1, show.legend = FALSE) +
    # ggplot2::geom_sf(data = MPA2, colour = "black", fill = NA, linewidth = 0.5, show.legend = FALSE) +
    ggplot2::coord_sf(xlim = sf::st_bbox(PUs)$xlim, ylim = sf::st_bbox(PUs)$ylim) +
    ggplot2::theme_void()
  # ggplot2::annotation_custom(img, xmin = 150, xmax = 212, ymin = -35, ymax = 15) +
  # ggplot2::annotation_custom(pntr, xmin = 205, xmax = 230, ymin = 13, ymax = 38)
)


hexSticker::sticker(gg,
                    package = "",
                    p_x = 1.38,
                    p_y = 0.98,
                    p_color = "white",
                    p_family = "Aller_Rg",
                    p_fontface = "bold",
                    p_size = 80,
                    s_x = 1,
                    s_y = 1,
                    s_width = 2.2,
                    s_height = 2.2,
                    # h_fill = "#9FE2BF",
                    h_color = "black", # "grey40",
                    dpi = 1000,
                    asp = 1,
                    filename = file.path("shinyplanr_Daniel3.png")
)
