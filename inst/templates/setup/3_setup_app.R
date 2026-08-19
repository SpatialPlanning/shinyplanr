# setup/3_setup_app.R
# Step 3: Configure shinyplanr app for: {country}
# Generated: {date}
#
# Run this script after 2_setup_data.R.
# Output: config/shinyplanr_config.rds  (in the project root)
#
# HOW TO RUN: Click 'Source' or run line-by-line.

library(tidyverse)
library(sf)

country   <- "{country}"
setup_dir <- "setup"                              # Location of the setup folder
data_path <- file.path(setup_dir, "data")         # Raw spatial data files

# =============================================================================
# APP OPTIONS
# =============================================================================
#
# NOTE: This variable is named 'shinyplanr_options' (not 'options') to avoid
# shadowing base::options(), which is a function. If 'options' were used here
# and you ran the app in the same R session without restarting, any code that
# calls options() internally (e.g. withr, purrr) would find the list instead
# of the function and crash R immediately.

shinyplanr_options <- list(

  ## General
  app_title  = "{country}: shinyplanr",
  nav_title  = "{country} Spatial Planning",
  navbar = list(theme = "dark"),  # "light" or "dark"

  ## Funder link
  funder_url = "https://spatialplanning.github.io",

  ## Logo file locations (relative to setup/logos/)
  #
  # Replace the placeholder images in setup/logos/ with your own files,
  # then re-run this script to copy them to www/.
  #
  #   logo_navbar.png  -- top-left of the navbar on every page
  #   logo_welcome.png -- inline image in the welcome page (shinyplanr_1welcome1.md)
  #   logo_funder.png  -- 'Funded by' section in the welcome page footer
  #   favicon.png      -- browser tab icon (16x16 or 32x32 px PNG recommended)
  #
  # The option values are the SOURCE paths (in setup/logos/).
  # This script copies them to www/ with the same filenames.
  file_logo_navbar  = file.path(setup_dir, "logos", "logo_navbar.png"),
  file_logo_welcome = file.path(setup_dir, "logos", "logo_welcome.png"),
  file_logo_funder  = file.path(setup_dir, "logos", "logo_funder.png"),
  file_favicon      = file.path(setup_dir, "logos", "favicon.png"),
  file_data        = file.path(data_path, paste0(country, "_RawData.rda")),

  ## Module switches (TRUE = enabled, FALSE = disabled)
  mod_1welcome = TRUE,
  mod_2scenario = TRUE,
  mod_3compare = TRUE,
  mod_4features = TRUE,
  mod_4features_interactive = FALSE,  # Set TRUE to use the interactive leaflet version instead of the static ggplot version
  mod_5coverage = TRUE,
  mod_6help = TRUE,
  mod_7credit = FALSE,

  ## Report generation
  include_report = TRUE,

  ## Optional tabs
  include_ess     = FALSE,  # Ecosystem Services tab - set TRUE if Dict contains EcosystemServices rows
  include_explore = TRUE,  # Explore tab
  include_log     = TRUE,  # Log tab

  ## Bioregion stratification
  include_bioregion = FALSE,

  ## Second funder logo in welcome footer (optional)
  # The default is the UQ logo (shinyplanr was developed at UQ).
  # Replace setup/logos/uq-logo-white.png with your own image and update
  # the path below, or comment out file_logo_funder2 to show only one
  # funder logo.
  file_logo_funder2 = file.path(setup_dir, "logos", "uq-logo-white.png"),
  funder2_url       = "https://spatialplanning.github.io",

  ## Institution text in welcome footer
  # institution_text = "This application was developed by researchers at My Institution."
  # Leave commented out to use the default UQ text.
# [IF include_climate]

  ## Climate-smart planning
  include_climateChange = FALSE,  # Set TRUE when climate data is available
  climate_change = 1,  # 0 = off; 1 = CPA; 2 = Feature; 3 = Percentile
  percentile     = 5,
  direction      = -1,  # 1 = high values are refugia; -1 = low values
  refugiaTarget  = 1,
# [END include_climate]

  ## Locked areas
  include_lockedArea = TRUE,

  ## Target grouping
  targetsBy = "individual",  # "individual", "category", or "master"

  ## Objective function
  #
  # 'min_set'       (default) -- finds the smallest-cost set of planning units
  #                  that meets ALL targets. Use this for most analyses.
  #
  # 'min_shortfall' -- finds the set of planning units that minimises the
  #                  overall shortfall across features while staying within a
  #                  fixed budget (set as a % of the total cost layer).
  #                  Only use this when you have a hard budget constraint.
  obj_func = "min_set",  # "min_set" or "min_shortfall"

  ## CRS
  cCRS = "{crs}",

  ## Plotting defaults
  base_size = 18
)

# =============================================================================
# COPY LOGOS TO www/
# =============================================================================

if (!dir.exists("www")) dir.create("www", recursive = TRUE)

# Maps each option key to its fixed destination filename in www/.
# The filenames in www/ are what the running app loads - do not change them.
logo_map <- list(
  file_logo_navbar  = "logo_navbar.png",
  file_logo_welcome = "logo_welcome.png",
  file_logo_funder  = "logo_funder.png",
  file_logo_funder2 = "logo_funder2.png",
  file_favicon      = "favicon.png"
)

for (opt_name in names(logo_map)) {
  src <- shinyplanr_options[[opt_name]]
  dst <- file.path("www", logo_map[[opt_name]])
  if (!is.null(src) && file.exists(src)) {
    file.copy(src, dst, overwrite = TRUE)
    message("Copied logo: ", basename(src), " -> ", dst)
  } else if (!is.null(src)) {
    message("Logo not found (skipping): ", src)
  }
}

# Derive show_logo_funder2: TRUE only if the file was successfully copied.
# This is set automatically - do not set it manually in shinyplanr_options.
shinyplanr_options$show_logo_funder2 <- file.exists(file.path("www", "logo_funder2.png"))

# Copy custom CSS override if present (overrides package default styling)
# Edit setup/content/custom.css to change colours, fonts, etc.
custom_css_src <- file.path(setup_dir, "content", "custom.css")
if (!file.exists(custom_css_src)) custom_css_src <- file.path(setup_dir, "custom.css")
if (file.exists(custom_css_src)) {
  file.copy(custom_css_src, file.path("www", "custom.css"), overwrite = TRUE)
  message("Copied: www/custom.css")
}

# =============================================================================
# FEATURE DICTIONARY
# =============================================================================
#
# Step 1: Read the full (unfiltered) CSV and validate its structure.
# validate_dict() checks that:
#   - All required columns are present
#   - includeApp and includeJust are logical (TRUE/FALSE), not 1/0 or text
#   - All type values are from the known set (Feature, Cost, LockIn, etc.)
#   - nameVariable is unique within each type
#   - At least one Feature row has includeApp == TRUE
#   - Active Feature rows have target values in the 0-100 range
#
# Fix any errors reported here before proceeding.

Dict_raw <- readr::read_csv(file.path(setup_dir, "Dict_Feature.csv"))
shinyplanr::validate_dict(Dict_raw)

# Step 2: Filter to active rows and sort for consistent UI ordering.
Dict <- Dict_raw %>%
  dplyr::filter(includeApp) %>%
  dplyr::arrange(.data$type, .data$categoryID)

vars <- Dict %>%
  dplyr::filter(!type %in% c("Justification")) %>%
  dplyr::pull(nameVariable)

# =============================================================================
# LOAD AND PROCESS SPATIAL DATA
# =============================================================================

load(shinyplanr_options$file_data)

raw_sf <- dat_sf %>%
  sf::st_drop_geometry() %>%
  dplyr::select(tidyselect::all_of(vars))

zero_cols <- colnames(raw_sf)[which(colSums(raw_sf, na.rm = TRUE) == 0)]
if (length(zero_cols) > 0) {
  message("Removing all-zero columns: ", paste(zero_cols, collapse = ", "))
  raw_sf <- raw_sf %>% dplyr::select(-tidyselect::any_of(zero_cols))
  vars   <- vars[!vars %in% zero_cols]
  Dict   <- Dict %>% dplyr::filter(!nameVariable %in% zero_cols)
}

raw_sf <- raw_sf %>%
  sf::st_set_geometry(sf::st_geometry(dat_sf))

# Normalise the agr (attribute-geometry-relationship) attribute so that
# dplyr::select() keeps geometry stickily when the config is loaded.
# sf::st_set_geometry() sets agr to all-NA; saving that to RDS and loading
# it in a new session can produce a stale factor that causes geometry to be
# silently dropped during select(). Setting agr to 'constant' here ensures
# the saved config is clean from the start.
raw_sf <- sf::st_set_agr(raw_sf, "constant")

if (length(unique(vars)) != ncol(raw_sf) - 1) {
  stop("Mismatch between Dict variables and data columns. Check Dict_Feature.csv")
}

# =============================================================================
# PLOTTING OVERLAYS
# =============================================================================

bndry   <- sf::st_set_agr(bndry, "constant")
overlay <- sf::st_set_agr(coast, "constant")

# =============================================================================
# TEXT CONTENT
# =============================================================================

content_dir <- file.path(setup_dir, "content")

tx <- list(
  welcome = list(
    list(title = "Welcome",      text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome1.md"))),
    list(title = "Terminology",  text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome2.md"))),
    list(title = "Instructions", text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome3.md"))),
    list(title = "CARE",         text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome4.md"))),
    list(title = "References",   text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome5.md")))
  )
)

tx_1footer_path <- file.path(content_dir, "shinyplanr_1footer.md")
tx_1footer <- if (file.exists(tx_1footer_path)) readr::read_file(tx_1footer_path) else ""
tx_2solution  <- readr::read_file(file.path(content_dir, "shinyplanr_2solution.md"))
tx_2targets   <- readr::read_file(file.path(content_dir, "shinyplanr_2targets.md"))
tx_2cost      <- readr::read_file(file.path(content_dir, "shinyplanr_2cost.md"))
tx_2climate   <- readr::read_file(file.path(content_dir, "shinyplanr_2climate.md"))
tx_2ess       <- readr::read_file(file.path(content_dir, "shinyplanr_2ecosystemServices.md"))
tx_6faq       <- readr::read_file(file.path(content_dir, "shinyplanr_6faq.md"))
tx_6technical <- readr::read_file(file.path(content_dir, "shinyplanr_6technical.md"))
tx_6changelog <- readr::read_file(file.path(content_dir, "shinyplanr_6changelog.md"))

# =============================================================================
# PLOTTING THEMES
# =============================================================================

map_theme <- 
  ggplot2::theme(
    legend.position = "right",
    legend.direction = "vertical",
    axis.title = ggplot2::element_blank()
  )

bar_theme <- 
  ggplot2::theme(
    plot.background = ggplot2::element_rect(fill = "transparent", colour = NA)
  )

# =============================================================================
# SIDEBAR (pre-computed slider/checkbox metadata)
# =============================================================================
#
# These are computed once here so that mod_2scenario and mod_3compare do not
# need to recompute them on every UI render and every server init.
# The module IDs must match those used in app_ui.R / app_server.R.

sidebar <- list(
  scenario = list(
    slider_vars     = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",
                                                categoryOut = TRUE, byCategory = FALSE),
    slider_varsBioR = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",
                                                categoryOut = TRUE, byCategory = TRUE,
                                                dataType = "Bioregion"),
    slider_varsCat  = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",
                                                categoryOut = TRUE, byCategory = TRUE),
    check_lockIn    = shinyplanr:::fcreate_check("2scenario_ui_1", Dict, "LockIn",
                                                 "checkLI_", categoryOut = TRUE),
    check_lockOut   = shinyplanr:::fcreate_check("2scenario_ui_1", Dict, "LockOut",
                                                 "checkLO_", categoryOut = TRUE)
  ),
  compare = list(
    Vars1             = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli1_",
                                                 categoryOut = TRUE),
    Vars2             = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli2_",
                                                 categoryOut = TRUE),
    slider_varsBioR1  = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli1_",
                                                 categoryOut = TRUE, byCategory = TRUE,
                                                 dataType = "Bioregion"),
    slider_varsBioR2  = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli2_",
                                                 categoryOut = TRUE, byCategory = TRUE,
                                                 dataType = "Bioregion"),
    check_lockIn1     = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockIn",
                                                   "check1LI_", categoryOut = TRUE),
    check_lockIn2     = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockIn",
                                                   "check2LI_", categoryOut = TRUE),
    check_lockOut1    = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockOut",
                                                   "check1LO_", categoryOut = TRUE),
    check_lockOut2    = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockOut",
                                                   "check2LO_", categoryOut = TRUE)
  )
)

config_list <- list(
  schema_version = shinyplanr::get_schema_version(),
  options        = shinyplanr_options,
  map_theme      = map_theme,
  bar_theme      = bar_theme,
  Dict           = Dict,
  raw_sf         = raw_sf,
  bndry          = bndry,
  overlay        = overlay,
  sidebar        = sidebar,
  tx             = tx,
  tx_1footer     = tx_1footer,
  tx_2solution   = tx_2solution,
  tx_2targets    = tx_2targets,
  tx_2cost       = tx_2cost,
  tx_2climate    = tx_2climate,
  tx_2ess        = tx_2ess,
  tx_6faq        = tx_6faq,
  tx_6technical  = tx_6technical,
  tx_6changelog  = tx_6changelog
)

# =============================================================================
# VALIDATE CONFIGURATION
# =============================================================================
#
# Runs checks on the config before saving:
#   - All Dict variables are present in raw_sf
#   - CRS is consistent across raw_sf, bndry, and options$cCRS
#   - No feature columns are all-zero or all-NA
#   - Text content fields are character strings
#   - Target values are in the 0-100 range
#
# strict = TRUE (default) stops with a clear error if any check fails.
# Use strict = FALSE to get a report without stopping.
shinyplanr::validate_shinyplanr_data(config_list)

# =============================================================================
# SAVE CONFIGURATION
# =============================================================================

if (!dir.exists("config")) dir.create("config", recursive = TRUE)
saveRDS(config_list, file.path("config", "shinyplanr_config.rds"))

message("\nConfig saved: config/shinyplanr_config.rds")
message("Run shiny::runApp() to test, or source('deploy.R') to deploy.")

# =============================================================================
# CLEAN UP
# =============================================================================
#
# The setup scripts leave large objects (dat_sf, raw_sf, shinyplanr_options,
# etc.) in the global environment. Running the app in the same R session
# without clearing these can cause hard-to-diagnose crashes because some
# names shadow base R functions (e.g. a variable named 'options' would shadow
# base::options()). Remove the known objects, then restart R before running
# the app.

rm(list = intersect(
  ls(),
  c('shinyplanr_options', 'config_list', 'dat_sf', 'raw_sf', 'bndry',
    'coast', 'overlay', 'Dict', 'Dict_raw', 'vars', 'sidebar', 'tx', 'map_theme',
    'bar_theme', 'tx_1footer', 'tx_2solution', 'tx_2targets', 'tx_2cost',
    'tx_2climate', 'tx_2ess', 'tx_6faq', 'tx_6technical', 'tx_6changelog',
    'zero_cols', 'logo_map', 'opt_name', 'src', 'dst', 'custom_css_src',
    'content_dir', 'tx_1footer_path', 'country', 'setup_dir', 'data_path')
))
message('\nSetup objects removed from global environment.')
message('IMPORTANT: Please restart R before running the app.')
message('  Session > Restart R  (or Ctrl/Cmd+Shift+F10 in RStudio)')
message('Then open app.R and run shiny::runApp() to test the app.')

# Open app.R so it is ready to run after the user restarts R.
if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
  rstudioapi::navigateToFile('app.R')
}
