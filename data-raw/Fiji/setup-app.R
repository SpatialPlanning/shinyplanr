## code to prepare the app goes here

library(tidyverse)
library(sf)
library(terra)

data_dir <- file.path("data-raw", "Fiji")

# TODO Write function to load default options
# Especially different colours for the plotting etc


# APP PARAMETERS --------------------------------------------------
options <- list(

  ## General Options
  app_title = "Fiji: shinyplanr",

  nav_title = "Fiji Spatial Planning", # Navbar title

  theme = "sandstone", # https://bootswatch.com/
  navbar = list(theme = "dark"), # light or dark or auto - determines colour of text

  ## File locations
  file_logo = file.path(data_dir, "logos", "WaittSquareLogo_invert.png"),
  file_logo2 = file.path(data_dir, "logos", "BP_Fiji_Logo.png"),
  file_logo3 = file.path(data_dir, "logos", "WaittSquareLogo.png"),

  file_data = file.path(data_dir, "Fiji_RawData.rda"),

  ## App Setup Options
  mod_1welcome = TRUE, #switch modules on/off
  mod_2scenario = TRUE, #switch modules on/off
  mod_3compare = TRUE, #switch modules on/off
  mod_4features = TRUE, #switch modules on/off
  mod_6help = TRUE, #switch modules on/off
  mod_7credit = FALSE, #switch modules on/off



  #TODO These options need to be updated. Probably into a list as we need specific
  # options (e.g. direction) for the number of layers we have in case they are different
  include_climateChange = TRUE,
  climate_change = 1, #switch climate change on/off; 0 = not clim-smart; 1 = CPA; 2 = Feature; 3 = Percentile
  percentile = 5,  # Warning: still requires some changes in the app: direction, percentile etc. should this be in here? those are input options to the functions
  direction = -1,
  refugiaTarget = 1,


  include_lockedArea = FALSE, # Includes locked in/out areas

  targetsBy = "individual", # How to group the targets. Options are c("individual", "category", "master")

  ## Which objective function module are we using
  obj_func = "min_set", # Minimum set objective
  # obj_func = min_shortfall # Minimum shortfall objective

  ## Geographic Options
  cCRS = "ESRI:54009"

  # Limits = c(xmin = 0, xmax = 30, ymin = -70.5, ymax = -60),
  # Shape = "Hexagon", # Shape of PUs
  # PU_size = 100 # km2
)


# Copy logo to required directory
file.copy(options$file_logo, file.path("inst", "app", "www", "logo.png"), overwrite = TRUE)

file.copy(options$file_logo2, file.path("inst", "app", "www", "logo2.png"), overwrite = TRUE)

file.copy(options$file_logo3, file.path("inst", "app", "www", "logo3.png"), overwrite = TRUE)

# DATASETS --------------------------------------------------------

# A dictionary of all data and feature-specific set up values
Dict <- readr::read_csv(file.path(data_dir, "Dict_Feature.csv")) %>%
  dplyr::filter(includeApp) %>% # Only those features to be included
  dplyr::arrange(.data$type, .data$category, .data$nameCommon)


vars <- Dict %>%
  dplyr::filter(!type %in% c("Justification")) %>%
  dplyr::pull(nameVariable)


# An sf object for all layers
load(options$file_data)

raw_sf <- dat_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::select(tidyselect::all_of(vars))

zero_cols <- colnames(raw_sf)[which(colSums(raw_sf, na.rm=TRUE) %in% 0)] # Remove all zero columns

raw_sf <- raw_sf %>%
  dplyr::select(-tidyselect::any_of(zero_cols)) %>%
  dplyr::bind_cols(dat_sf %>% dplyr::select(geometry)) %>%  # Add geometry back in
  sf::st_as_sf()

vars <- vars[! vars %in% zero_cols] # Remove zero's from vars

Dict <- Dict %>%
  dplyr::filter(!nameVariable %in% zero_cols)

# Check if variables were removed from the data due to zero columns
if (length(unique(vars)) != dim(raw_sf)[2]-1){

  stop("raw_sf and the Dictionary have different numbers of variables. If columns
       were removed due to being all zero above, please remove corresponding
       variable from Dict")}


# Plotting Overlays -------------------------------------------------------

bndry <- Fiji_eez
overlay <- Fiji_cntry

# TODO Work out how to add options here without having to define all.
# Change to a list called plot_options()? that is passed to the function.


# MODULE 1 - WELCOME ------------------------------------------------------

tx <- list(
  welcome = list(
    list(
      title = "Welcome",
      text = readr::read_file(file.path(data_dir, "shinyplanr_1welcome1.md"))
    ),
    list(
      title = "Terminology",
      text = readr::read_file(file.path(data_dir, "shinyplanr_1welcome2.md"))
    ),
    list(
      title = "Instructions",
      text = readr::read_file(file.path(data_dir, "shinyplanr_1welcome3.md"))
    ),
    list(
      title = "C.A.R.E.",
      text = readr::read_file(file.path(data_dir, "shinyplanr_1welcome4.md"))
    ),
    list(
      title = "Credit",
      text = readr::read_file(file.path(data_dir, "shinyplanr_1welcome5.md"))
    )
  )
)

# return_list <- read_textboxes(FILENAME)


#TODO Add all these to the tx list above.
# MODULE 2 - SCENARIO ------------------------------------------------------
tx_2solution <- readr::read_file(file.path(data_dir, "shinyplanr_2solution.md"))
tx_2targets <- readr::read_file(file.path(data_dir, "shinyplanr_2targets.md"))
tx_2cost <- readr::read_file(file.path(data_dir, "shinyplanr_2cost.md"))
tx_2climate <- readr::read_file(file.path(data_dir, "shinyplanr_2climate.md"))

# MODULE 3 - COMPARISON ------------------------------------------------------



# MODULE 6 - HELP ------------------------------------------------------
tx_6faq <- readr::read_file(file.path(data_dir, "shinyplanr_6faq.md"))
tx_6changelog <- readr::read_file(file.path(data_dir, "shinyplanr_6changelog.md"))
tx_6technical <- readr::read_file(file.path(data_dir, "shinyplanr_6technical.md"))


# MODULE 7 - CREDIT ------------------------------------------------------
# tx_7credit <- readr::read_file(file.path(data_dir, "shinyplanr_7credit.md"))



# HEX STICKER -------------------------------------------------------------
# Create app-specific Hex sticker if wanted. Otherwise the generic shinyplanr one will be used
# hexSticker::sticker(options$file_logo,
#                     package="",
#                     s_x=1,
#                     s_y=1,
#                     s_width=.8,
#                     h_fill = "#0033a0",
#                     h_color = "grey40",
#                     # url = "",
#                     # u_color = "white",
#                     dpi=600,
#                     filename=file.path("inst", "app", "www", "Hex.png"))
#

golem::use_favicon(options$file_logo, pkg = golem::get_golem_wd(), method = "curl")


# PLOTTING THEME -----------------------------------------------------------
map_theme <- ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "right",
    legend.direction = "vertical",
    # text = ggplot2::element_text(size = 6, colour = "black"),
    # axis.text = ggplot2::element_text(size = 9, colour = "black"),
    # plot.title = ggplot2::element_text(size = 12),
    # legend.title = ggplot2::element_text(size = 9),
    # legend.text = ggplot2::element_text(size = 9),
    axis.title = ggplot2::element_blank()
  )

bar_theme <- ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "right",
    legend.direction = "vertical",
    # text = ggplot2::element_text(size = 6, colour = "black"),
    # axis.text = ggplot2::element_text(size = 6, colour = "black"),
    # plot.title = ggplot2::element_text(size = 12),
    # legend.title = ggplot2::element_text(size = 9),
    # legend.text = ggplot2::element_text(size = 9),
    axis.title = ggplot2::element_blank()
  )

file.copy(file.path("data-raw", "Fiji", "FijiData", "custom.css"),
          file.path("inst", "app", "www", "custom.css"),
          overwrite = TRUE)

usethis::use_data(options,
                  map_theme,
                  bar_theme,
                  Dict,
                  vars,
                  raw_sf,
                  bndry,
                  overlay,
                  tx,
                  tx_2solution,
                  tx_2targets,
                  tx_2cost,
                  tx_2climate,
                  tx_6faq,
                  tx_6technical,
                  tx_6changelog,
                  overwrite = TRUE,
                  internal = TRUE)

