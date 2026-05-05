# Setup app configuration for shinyplanr
# Country/Region: Tonga
# Generated: 2026-03-03

library(tidyverse)
library(sf)

country <- "Tonga"
data_dir <- file.path("data-raw", country)

# =============================================================================
# APP PARAMETERS
# =============================================================================

options <- list(

  ## General Options
  app_title = "Tonga: shinyplanr",
  nav_title = "Tonga Spatial Planning",  # Navbar title
  navbar = list(theme = "dark"),  # "light" or "dark" - determines text colour

  ## Funder/credit link
  funder_url = "https://spatialplanning.github.io",  # URL for funder logo link

  ## File locations
  file_logo = file.path(data_dir, "logos", "logo.png"),       # Main logo
  file_logo2 = file.path(data_dir, "logos", "logo2.png"),     # Secondary logo
  file_logo3 = file.path(data_dir, "logos", "logo3.png"),     # Third logo
  file_logo_funder = file.path(data_dir, "logos", "logo_funder.png"),  # Funder logo
  file_data = file.path(data_dir, paste0(country, "_RawData.rda")),

  ## Module switches (TRUE = enabled, FALSE = disabled)
  mod_1welcome = TRUE,    # Welcome/introduction module
  mod_2scenario = TRUE,   # Scenario building module
  mod_3compare = TRUE,    # Compare solutions module
  mod_4features = TRUE,   # Feature exploration module
  mod_5coverage = TRUE,   # Coverage analysis module
  mod_6help = TRUE,       # Help/FAQ module
  mod_7credit = FALSE,    # Credits module

  ## Report generation
  include_report = TRUE,

  ## Bioregion stratification
  include_bioregion = FALSE,

  ## Climate-smart planning options
  include_climateChange = FALSE,  # Set TRUE when climate data is available
  climate_change = 1,  # 0 = off; 1 = CPA; 2 = Feature; 3 = Percentile
  percentile = 5,      # Percentile for climate refugia
  direction = -1,      # 1 = high values are refugia; -1 = low values are refugia
  refugiaTarget = 1,   # Target for climate refugia

  ## Locked areas
  include_lockedArea = TRUE,  # Include locked-in/out constraints

  ## Target grouping
  targetsBy = "individual",  # Options: "individual", "category", "master"

  ## Objective function
  obj_func = "min_shortfall",  # Options: "min_set", "min_shortfall"

  ## Geographic options
  cCRS = "EPSG:32702"
)

# =============================================================================
# COPY LOGOS
# =============================================================================

# Copy logos to app directory (create placeholder if missing)
if (file.exists(options$file_logo)) {
  file.copy(options$file_logo, file.path("inst", "app", "www", "logo.png"), overwrite = TRUE)
} else {
  message("Logo file not found: ", options$file_logo)
}

if (file.exists(options$file_logo2)) {
  file.copy(options$file_logo2, file.path("inst", "app", "www", "logo2.png"), overwrite = TRUE)
}

if (file.exists(options$file_logo3)) {
  file.copy(options$file_logo3, file.path("inst", "app", "www", "logo3.png"), overwrite = TRUE)
}

if (file.exists(options$file_logo_funder)) {
  file.copy(options$file_logo_funder, file.path("inst", "app", "www", "logo_funder.png"), overwrite = TRUE)
}

# Set favicon
if (file.exists(options$file_logo)) {
  golem::use_favicon(options$file_logo, pkg = golem::get_golem_wd(), method = "curl")
}

# =============================================================================
# LOAD DATA DICTIONARY
# =============================================================================

# Dictionary defines all layers and their properties
Dict <- readr::read_csv(file.path(data_dir, "Dict_Feature.csv")) %>%
  dplyr::filter(includeApp) %>%
  dplyr::arrange(.data$type, .data$categoryID, .data$nameCommon)

# Get variable names for features (not justification text)
vars <- Dict %>%
  dplyr::filter(!type %in% c("Justification")) %>%
  dplyr::pull(nameVariable)

# =============================================================================
# LOAD AND PROCESS SPATIAL DATA
# =============================================================================

load(options$file_data)

# Select only variables in the dictionary
raw_sf <- dat_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::select(tidyselect::all_of(vars))

# Remove columns that are all zeros
zero_cols <- colnames(raw_sf)[which(colSums(raw_sf, na.rm = TRUE) == 0)]

if (length(zero_cols) > 0) {
  message("Removing zero columns: ", paste(zero_cols, collapse = ", "))
  raw_sf <- raw_sf %>%
    dplyr::select(-tidyselect::any_of(zero_cols))
  vars <- vars[!vars %in% zero_cols]
  Dict <- Dict %>%
    dplyr::filter(!nameVariable %in% zero_cols)
}

# Add geometry back
raw_sf <- raw_sf %>%
  dplyr::bind_cols(dat_sf %>% dplyr::select(geometry)) %>%
  sf::st_as_sf()

# Validate
if (length(unique(vars)) != ncol(raw_sf) - 1) {
  stop("Mismatch between Dict variables and data columns. Check Dict_Feature.csv")
}

# =============================================================================
# PLOTTING OVERLAYS
# =============================================================================

# These are used for map overlays
bndry <- bndry   # From loaded data
overlay <- coast  # Coastline for overlay

# =============================================================================
# TEXT CONTENT - WELCOME MODULE
# =============================================================================

tx <- list(
  welcome = list(
    list(
      title = "Welcome",
      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome1.md"))
    ),
    list(
      title = "Terminology",
      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome2.md"))
    ),
    list(
      title = "Instructions",
      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome3.md"))
    ),
    list(
      title = "CARE",
      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome4.md"))
    ),
    list(
      title = "References",
      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome5.md"))
    )
  )
)

# =============================================================================
# TEXT CONTENT - SCENARIO MODULE
# =============================================================================

tx_2solution <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2solution.md"))
tx_2targets <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2targets.md"))
tx_2cost <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2cost.md"))
tx_2climate <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2climate.md"))
tx_2ess <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2ecosystemServices.md"))

# =============================================================================
# TEXT CONTENT - HELP MODULE
# =============================================================================

tx_1footer <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1footer.md"))

tx_6faq <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6faq.md"))
tx_6technical <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6technical.md"))
tx_6changelog <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6changelog.md"))

# =============================================================================
# PLOTTING THEMES
# =============================================================================

map_theme <- ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "right",
    legend.direction = "vertical",
    axis.title = ggplot2::element_blank()
  )

bar_theme <- ggplot2::theme_bw(base_size = 14) +
  ggplot2::theme(
    legend.position = "right",
    legend.direction = "vertical",
    axis.title = ggplot2::element_blank()
  )

# =============================================================================
# OPTIONAL: CUSTOM CSS
# =============================================================================

# Uncomment to use custom CSS
# file.copy(file.path(data_dir, "custom.css"),
#           file.path("inst", "app", "www", "custom.css"),
#           overwrite = TRUE)

# =============================================================================
# SAVE INTERNAL DATA
# =============================================================================

usethis::use_data(
  options,
  map_theme,
  bar_theme,
  Dict,
  vars,
  raw_sf,
  bndry,
  overlay,
  tx,
  tx_1footer,
  tx_2solution,
  tx_2targets,
  tx_2cost,
  tx_2climate,
  tx_2ess,
  tx_6faq,
  tx_6technical,
  tx_6changelog,
  overwrite = TRUE,
  internal = TRUE
)

message("App configuration complete for ", country)

