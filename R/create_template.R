#' Create a new shinyplanr app template
#'
#' Creates a folder structure with template files for deploying a new shinyplanr
#' app for a specific country/region. The function generates setup-data.R,
#' setup-app.R, Dict_Feature.csv, and markdown help files.
#'
#' @param country Character. Name of the country/region (e.g., "Fiji", "Kosrae").
#'   Used for folder naming and default titles.
#' @param crs Character. Coordinate reference system for the analysis.
#'   Default is "ESRI:54009" (Mollweide equal-area projection).
#'   Use https://projectionwizard.org to find an appropriate local CRS.
#' @param oceandatr Logical. If TRUE (default), the setup-data.R template will
#'   include code to automatically download data from oceandatr (bathymetry,
#'   geomorphology, seamounts, knolls, coral habitat, environmental regions).
#'   If FALSE, creates a minimal template for manual data entry.
#' @param resolution Numeric. Planning unit resolution in meters. Default is 20000
#'   (20 km x 20 km). Smaller values create more planning units.
#' @param include_climate Logical. If TRUE (default), includes climate-smart
#'   planning options in setup-app.R and placeholder climate data loading.
#' @param include_cost Logical. If TRUE (default), includes cost layer setup
#'   (distance to coast, equal area).
#' @param include_mpas Logical. If TRUE (default), includes code to fetch
#'   marine protected areas from WDPA as locked-in constraints.
#' @param output_dir Character. Path where the template folder will be created.
#'
#' @return Invisibly returns the path to the created folder.
#'
#' @examples
#' \dontrun{
#' # Create a template for Tonga with oceandatr data

#' create_shinyplanr_template(
#'   country = "Tonga",
#'   crs = "EPSG:32702",
#'   oceandatr = TRUE
#' )
#'
#' # Create a minimal template for custom data
#' create_shinyplanr_template(
#'   country = "MyRegion",
#'   crs = "+proj=cea +lon_0=150 +lat_ts=-10",
#'   oceandatr = FALSE
#' )
#' }
#'
#' @export
create_shinyplanr_template <- function(
    country,
    crs = "ESRI:54009",
    oceandatr = TRUE,
    resolution = 20000,
    include_climate = TRUE,
    include_cost = TRUE,
    include_mpas = TRUE,
    output_dir = file.path("data-raw", country)
) {


  # Validate inputs

if (missing(country) || !is.character(country) || nchar(country) == 0) {
    stop("'country' must be a non-empty character string.")
  }

  if (!is.character(crs) || nchar(crs) == 0) {
    stop("'crs' must be a non-empty character string.")
  }

  if (!is.logical(oceandatr)) {
    stop("'oceandatr' must be TRUE or FALSE.")
  }

  # Create directory structure
  dirs_to_create <- c(
    output_dir,
    file.path(output_dir, "data"),
    file.path(output_dir, "logos"),
    file.path(output_dir, "markdown")
  )

  for (dir_path in dirs_to_create) {
    if (!dir.exists(dir_path)) {
      dir.create(dir_path, recursive = TRUE)
      message("Created directory: ", dir_path)
    }
  }

  # Copy default logo to logos directory
  default_logo <- system.file("man", "figures", "logo.png", package = "shinyplanr")
  if (default_logo == "") {
    # Fallback for development: look relative to package root
    default_logo <- file.path("man", "figures", "logo.png")
  }

  if (file.exists(default_logo)) {
    logos_dir <- file.path(output_dir, "logos")
    file.copy(default_logo, file.path(logos_dir, "logo.png"), overwrite = FALSE)
    file.copy(default_logo, file.path(logos_dir, "logo2.png"), overwrite = FALSE)
    file.copy(default_logo, file.path(logos_dir, "logo3.png"), overwrite = FALSE)
    message("Copied default logo to: ", logos_dir)
  }

  # Copy default funder logo
  funder_logo <- system.file("app", "www", "FunderLogo.png", package = "shinyplanr")
  if (funder_logo == "") {
    # Fallback for development
    funder_logo <- file.path("inst", "app", "www", "FunderLogo.png")
  }

  if (file.exists(funder_logo)) {
    logos_dir <- file.path(output_dir, "logos")
    file.copy(funder_logo, file.path(logos_dir, "logo_funder.png"), overwrite = FALSE)
    message("Copied UQ funder logo to: ", logos_dir)
  }

  # Generate files
  .write_setup_data(output_dir, country, crs, oceandatr, resolution,
                    include_climate, include_cost, include_mpas)
  .write_setup_app(output_dir, country, crs, include_climate)
  .write_dict_feature(output_dir, oceandatr, include_cost, include_mpas)
  .write_markdown_templates(output_dir, country)

  message("\n========================================")
  message("Template created successfully at: ", output_dir)
  message("========================================")

  message("\nNext steps:")
  message("1. Replace default logos in: ", file.path(output_dir, "logos"))
  message("2. Add any custom data to: ", file.path(output_dir, "data"))
  message("3. Edit Dict_Feature.csv to match your data layers")
  message("4. Run setup-data.R to generate the .rda file")
  message("5. Run setup-app.R to configure and build the app")
  message("6. Edit the markdown files to customize help text")

  invisible(output_dir)
}


# Internal function to write setup-data.R
.write_setup_data <- function(output_dir, country, crs, oceandatr, resolution,
                              include_climate, include_cost, include_mpas) {

  # Header
  content <- c(
    "# Setup data for shinyplanr app",
    paste0("# Country/Region: ", country),
    paste0("# Generated: ", Sys.Date()),
    "",
    "library(tidyverse)",
    "library(spatialplanr)",
    "library(sf)",
    "library(terra)",
    ""
  )

  if (oceandatr) {
    content <- c(content, "library(oceandatr)", "")
  }

  # Basic parameters
  content <- c(content,
    "# =============================================================================",
    "# BASIC PARAMETERS",
    "# =============================================================================",
    "",
    paste0('country <- "', country, '"'),
    paste0('crs <- "', crs, '"'),
    paste0("resolution <- ", resolution, "L  # Planning unit size in meters"),
    "",
    'data_dir <- file.path("data-raw", country)',
    'data_path <- file.path(data_dir, "data")  # Path to your raw data files',
    ""
  )

  # Boundary and grid setup
  if (oceandatr) {
    content <- c(content,
      "# =============================================================================",
      "# BOUNDARIES (using oceandatr)",
      "# =============================================================================",
      "",
      "# Get EEZ boundary from Marine Regions database",
      "# See: https://marineregions.org/gazetteer.php for valid names",
      'eez <- oceandatr::get_boundary(name = country, type = "eez") %>%',
      "  sf::st_transform(crs = crs) %>%",
      "  sf::st_geometry() %>%",
      "  sf::st_sf()",
      "",
      "# Alternative: Load custom boundary",
      "# bndry <- sf::st_read(file.path(data_path, \"my_boundary.gpkg\")) %>%",
      "#   sf::st_transform(crs = crs)",
      "",
      "# Separate boundary (for plotting)",
      "bndry <- eez %>%",
      '  sf::st_cast(to = "POLYGON") %>%',
      "  dplyr::mutate(Area_km2 = sf::st_area(.) %>%",
      '                  units::set_units("km2") %>%',
      "                  units::drop_units())",
      "",
      "# Get coastline for plotting overlays",
      'coast <- rnaturalearth::ne_countries(country = country, scale = "medium", returnclass = "sf") %>%',
      "  sf::st_transform(crs = crs)",
      "",
      "# Create planning unit grid",
      "PUs <- spatialgridr::get_grid(boundary = eez,",
      "                              crs = crs,",
      '                              output = "sf_hex",',
      "                              resolution = resolution)",
      "",
      "# Check the grid",
      "ggplot() +",
      "  geom_sf(data = PUs, fill = NA, colour = \"grey80\") +",
      "  geom_sf(data = bndry, fill = NA, colour = \"blue\") +",
      "  geom_sf(data = coast, fill = \"darkgrey\")",
      ""
    )
  } else {
    content <- c(content,
      "# =============================================================================",
      "# BOUNDARIES (custom data)",
      "# =============================================================================",
      "",
      "# TODO: Load your boundary file",
      "# bndry <- sf::st_read(file.path(data_path, \"my_boundary.gpkg\")) %>%",
      "#   sf::st_transform(crs = crs)",
      "",
      "# TODO: Load your coastline for plotting",
      "# coast <- sf::st_read(file.path(data_path, \"my_coastline.gpkg\")) %>%",
      "#   sf::st_transform(crs = crs)",
      "",
      "# TODO: Create or load planning units",
      "# Option 1: Create grid from boundary",
      "# PUs <- spatialgridr::get_grid(boundary = bndry,",
      "#                               crs = crs,",
      '#                               output = "sf_hex",',
      "#                               resolution = resolution)",
      "",
      "# Option 2: Load pre-made planning units",
      "# PUs <- sf::st_read(file.path(data_path, \"planning_units.gpkg\")) %>%",
      "#   sf::st_transform(crs = crs)",
      "",
      "# Check the grid",
      "# ggplot() +",
      "#   geom_sf(data = PUs, fill = NA) +",
      "#   geom_sf(data = bndry, fill = NA, colour = \"blue\")",
      ""
    )
  }

  # Feature data
  content <- c(content,
    "# =============================================================================",
    "# FEATURE DATA",
    "# =============================================================================",
    ""
  )

  if (oceandatr) {
    content <- c(content,
      "# Download and process oceandatr layers",
      "# These will be automatically added to the planning units",
      "# Variable names are set to match Dict_Feature.csv",
      "",
      "# Bathymetry / Depth zones",
      "bathymetry <- oceandatr::get_bathymetry(spatial_grid = PUs,",
      "                                         classify_bathymetry = TRUE) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Geomorphology (seafloor features)",
      "geomorphology <- oceandatr::get_geomorphology(spatial_grid = PUs) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Knolls (underwater hills)",
      "knolls <- oceandatr::get_knolls(spatial_grid = PUs) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Seamounts (with 30km buffer)",
      "seamounts <- oceandatr::get_seamounts(spatial_grid = PUs,",
      "                                       buffer = 30000) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Environmental zones (data-driven bioregions)",
      "enviro_zones <- oceandatr::get_enviro_zones(spatial_grid = PUs,",
      "                                             max_num_clusters = 5,",
      "                                             show_plots = FALSE) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Deep-water coral habitat",
      "corals <- oceandatr::get_coral_habitat(spatial_grid = PUs) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Combine all oceandatr features",
      "dat_sf <- dplyr::bind_cols(",
      "  PUs,",
      "  bathymetry,",
      "  geomorphology,",
      "  knolls,",
      "  seamounts,",
      "  enviro_zones,",
      "  corals",
      ") %>%",
      "  dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))",
      ""
    )
  } else {
    content <- c(content,
      "# TODO: Load and process your feature data",
      "# Each feature should be added to the planning units grid",
      "",
      "# Example: Load habitat data from shapefile",
      "# habitat <- sf::st_read(file.path(data_path, \"habitat.gpkg\")) %>%",
      "#   spatialgridr::get_data_in_grid(spatial_grid = PUs,",
      "#                                   dat = .,",
      '#                                   feature_names = "habitat_type",',
      "#                                   meth = \"average\",",
      "#                                   cutoff = 0.1)",
      "",
      "# Example: Load raster data",
      "# depth <- terra::rast(file.path(data_path, \"depth.tif\")) %>%",
      "#   spatialgridr::get_data_in_grid(spatial_grid = PUs,",
      "#                                   dat = .,",
      "#                                   meth = \"average\")",
      "",
      "# TODO: Combine all features into a single sf object",
      "# dat_sf <- dplyr::bind_cols(",
      "#   PUs,",
      "#   habitat %>% sf::st_drop_geometry(),",
      "#   depth %>% sf::st_drop_geometry()",
      "# ) %>%",
      "#   dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))",
      ""
    )
  }

  # Cost data
  if (include_cost) {
    content <- c(content,
      "# =============================================================================",
      "# COST DATA",
      "# =============================================================================",
      "",
      "# Calculate planning unit area (for equal-area cost)",
      "PU_Area <- as.numeric(units::set_units(sf::st_area(PUs)[1], km^2)) %>%",
      "  round(2)",
      "",
      "# Cost layers",
      "cost <- dat_sf %>%",
      "  dplyr::select(geometry) %>%",
      "  spatialplanr::splnr_get_distCoast(custom_coast = coast) %>%",
      "  dplyr::mutate(",
      "    Cost_Area = PU_Area,  # Equal area cost",
      "    Cost_Distance = coastDistance_km  # Distance to coast",
      "  ) %>%",
      "  dplyr::select(-coastDistance_km) %>%",
      "  sf::st_drop_geometry()",
      "",
      "# Add cost to main data",
      "dat_sf <- dplyr::bind_cols(dat_sf, cost)",
      "",
      "# TODO: Add custom cost layers (e.g., fishing effort, opportunity cost)",
      "# fishing_cost <- ... %>% sf::st_drop_geometry()",
      "# dat_sf <- dplyr::bind_cols(dat_sf, fishing_cost)",
      ""
    )
  }

  # MPA / Locked areas
  if (include_mpas) {
    content <- c(content,
      "# =============================================================================",
      "# LOCKED-IN AREAS (MPAs)",
      "# =============================================================================",
      "",
      "# Fetch marine protected areas from WDPA",
      "# Note: First run may download data (~2GB)",
      "mpas <- spatialplanr::splnr_get_MPAs(PlanUnits = PUs, Countries = country) %>%",
      "  sf::st_transform(crs = crs) %>%",
      "  dplyr::select(geometry) %>%",
      '  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "mpas", cutoff = 0.5) %>%',
      "  sf::st_drop_geometry()",
      "",
      "# Add MPAs to main data",
      "dat_sf <- dplyr::bind_cols(dat_sf, mpas)",
      "",
      "# TODO: Add custom locked-in/out areas",
      "# locked_out <- sf::st_read(file.path(data_path, \"no_take_zones.gpkg\")) %>%",
      '#   spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "locked_out")',
      ""
    )
  }

  # Climate data
  if (include_climate) {
    content <- c(content,
      "# =============================================================================",
      "# CLIMATE DATA (optional)",
      "# =============================================================================",
      "",
      "# TODO: Load climate data if available",
      "# Climate data should be a metric where higher/lower values indicate",
      "# climate refugia (depending on direction setting in setup-app.R)",
      "",
      "# Example: SST trend data",
      "# climate_sf <- readr::read_rds(file.path(data_path, \"sst_trends.rds\")) %>%",
      "#   sf::st_transform(crs) %>%",
      "#   sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)",
      "",
      "# If you have climate data, bind it:",
      "# dat_sf <- dplyr::bind_cols(dat_sf, climate_sf %>% sf::st_drop_geometry())",
      ""
    )
  }

  # Final checks and save
  content <- c(content,
    "# =============================================================================",
    "# FINAL PROCESSING AND SAVE",
    "# =============================================================================",
    "",
    "# Ensure geometry is last column",
    "dat_sf <- dat_sf %>%",
    "  dplyr::relocate(geometry, .after = tidyselect::everything())",
    "",
    "# Check for any remaining NAs and replace with 0",
    "if (any(is.na(sf::st_drop_geometry(dat_sf)))) {",
    "  warning(\"NA values found in data - replacing with 0\")",
    "  dat_sf <- dat_sf %>%",
    "    dplyr::mutate(across(where(is.numeric), ~replace_na(., 0)))",
    "}",
    "",
    "# Check column names match Dict_Feature.csv",
    "message(\"Data columns: \", paste(names(dat_sf), collapse = \", \"))",
    "",
    "# Save the processed data",
    "save(dat_sf, bndry, coast,",
    '     file = file.path(data_dir, paste0(country, "_RawData.rda")))',
    "",
    'message("Data saved to: ", file.path(data_dir, paste0(country, "_RawData.rda")))',
    'message("Finished processing data for ", country)',
    ""
  )

  # Write file
  file_path <- file.path(output_dir, "setup-data.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Internal function to write setup-app.R
.write_setup_app <- function(output_dir, country, crs, include_climate) {

  content <- c(
    "# Setup app configuration for shinyplanr",
    paste0("# Country/Region: ", country),
    paste0("# Generated: ", Sys.Date()),
    "",
    "library(tidyverse)",
    "library(sf)",
    "",
    paste0('country <- "', country, '"'),
    'data_dir <- file.path("data-raw", country)',
    "",
    "# =============================================================================",
    "# APP PARAMETERS",
    "# =============================================================================",
    "",
    "options <- list(",
    "",
    "  ## General Options",
    paste0('  app_title = "', country, ': shinyplanr",'),
    paste0('  nav_title = "', country, ' Spatial Planning",  # Navbar title'),
    '  navbar = list(theme = "dark"),  # "light" or "dark" - determines text colour',
    "",
    "  ## Funder/credit link",
    '  funder_url = "https://spatialplanning.github.io",  # URL for funder logo link',
    "",
    "  ## File locations",
    '  file_logo = file.path(data_dir, "logos", "logo.png"),       # Main logo',
    '  file_logo2 = file.path(data_dir, "logos", "logo2.png"),     # Secondary logo',
    '  file_logo3 = file.path(data_dir, "logos", "logo3.png"),     # Third logo',
    '  file_logo_funder = file.path(data_dir, "logos", "logo_funder.png"),  # Funder logo',
    '  file_data = file.path(data_dir, paste0(country, "_RawData.rda")),',
    "",
    "  ## Module switches (TRUE = enabled, FALSE = disabled)",
    "  mod_1welcome = TRUE,    # Welcome/introduction module",
    "  mod_2scenario = TRUE,   # Scenario building module",
    "  mod_3compare = TRUE,    # Compare solutions module",
    "  mod_4features = TRUE,   # Feature exploration module",
    "  mod_5coverage = TRUE,   # Coverage analysis module",
    "  mod_6help = TRUE,       # Help/FAQ module",
    "  mod_7credit = FALSE,    # Credits module",
    "",
    "  ## Report generation",
    "  include_report = TRUE,",
    "",
    "  ## Bioregion stratification",
    "  include_bioregion = FALSE,",
    ""
  )

  # Climate options
  if (include_climate) {
    content <- c(content,
      "  ## Climate-smart planning options",
      "  include_climateChange = FALSE,  # Set TRUE when climate data is available",
      "  climate_change = 1,  # 0 = off; 1 = CPA; 2 = Feature; 3 = Percentile",
      "  percentile = 5,      # Percentile for climate refugia",
      "  direction = -1,      # 1 = high values are refugia; -1 = low values are refugia",
      "  refugiaTarget = 1,   # Target for climate refugia",
      ""
    )
  }

  content <- c(content,
    "  ## Locked areas",
    "  include_lockedArea = TRUE,  # Include locked-in/out constraints",
    "",
    "  ## Target grouping",
    '  targetsBy = "individual",  # Options: "individual", "category", "master"',
    "",
    "  ## Objective function",
    '  obj_func = "min_shortfall",  # Options: "min_set", "min_shortfall"',
    "",
    "  ## Geographic options",
    paste0('  cCRS = "', crs, '"'),
    ")",
    "",
    "# =============================================================================",
    "# COPY LOGOS",
    "# =============================================================================",
    "",
    "# Copy logos to app directory (create placeholder if missing)",
    'if (file.exists(options$file_logo)) {',
    '  file.copy(options$file_logo, file.path("inst", "app", "www", "logo.png"), overwrite = TRUE)',
    '} else {',
    '  message("Logo file not found: ", options$file_logo)',
    '}',
    "",
    'if (file.exists(options$file_logo2)) {',
    '  file.copy(options$file_logo2, file.path("inst", "app", "www", "logo2.png"), overwrite = TRUE)',
    '}',
    "",
    'if (file.exists(options$file_logo3)) {',
    '  file.copy(options$file_logo3, file.path("inst", "app", "www", "logo3.png"), overwrite = TRUE)',
    '}',
    "",
    'if (file.exists(options$file_logo_funder)) {',
    '  file.copy(options$file_logo_funder, file.path("inst", "app", "www", "logo_funder.png"), overwrite = TRUE)',
    '}',
    "",
    "# Set favicon",
    'if (file.exists(options$file_logo)) {',
    '  golem::use_favicon(options$file_logo, pkg = golem::get_golem_wd(), method = "curl")',
    '}',
    "",
    "# =============================================================================",
    "# LOAD DATA DICTIONARY",
    "# =============================================================================",
    "",
    '# Dictionary defines all layers and their properties',
    'Dict <- readr::read_csv(file.path(data_dir, "Dict_Feature.csv")) %>%',
    "  dplyr::filter(includeApp) %>%",
    "  dplyr::arrange(.data$type, .data$categoryID, .data$nameCommon)",
    "",
    "# Get variable names for features (not justification text)",
    "vars <- Dict %>%",
    '  dplyr::filter(!type %in% c("Justification")) %>%',
    "  dplyr::pull(nameVariable)",
    "",
    "# =============================================================================",
    "# LOAD AND PROCESS SPATIAL DATA",
    "# =============================================================================",
    "",
    "load(options$file_data)",
    "",
    "# Select only variables in the dictionary",
    "raw_sf <- dat_sf %>%",
    "  sf::st_drop_geometry() %>%",
    "  dplyr::select(tidyselect::all_of(vars))",
    "",
    "# Remove columns that are all zeros",
    "zero_cols <- colnames(raw_sf)[which(colSums(raw_sf, na.rm = TRUE) == 0)]",
    "",
    "if (length(zero_cols) > 0) {",
    '  message("Removing zero columns: ", paste(zero_cols, collapse = ", "))',
    "  raw_sf <- raw_sf %>%",
    "    dplyr::select(-tidyselect::any_of(zero_cols))",
    "  vars <- vars[!vars %in% zero_cols]",
    "  Dict <- Dict %>%",
    "    dplyr::filter(!nameVariable %in% zero_cols)",
    "}",
    "",
    "# Add geometry back",
    "raw_sf <- raw_sf %>%",
    "  dplyr::bind_cols(dat_sf %>% dplyr::select(geometry)) %>%",
    "  sf::st_as_sf()",
    "",
    "# Validate",
    "if (length(unique(vars)) != ncol(raw_sf) - 1) {",
    '  stop("Mismatch between Dict variables and data columns. Check Dict_Feature.csv")',
    "}",
    "",
    "# =============================================================================",
    "# PLOTTING OVERLAYS",
    "# =============================================================================",
    "",
    "# These are used for map overlays",
    "bndry <- bndry   # From loaded data",
    "overlay <- coast  # Coastline for overlay",
    "",
    "# =============================================================================",
    "# TEXT CONTENT - WELCOME MODULE",
    "# =============================================================================",
    "",
    "tx <- list(",
    "  welcome = list(",
    "    list(",
    '      title = "Welcome",',
    '      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome1.md"))',
    "    ),",
    "    list(",
    '      title = "Terminology",',
    '      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome2.md"))',
    "    ),",
    "    list(",
    '      title = "Instructions",',
    '      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome3.md"))',
    "    ),",
    "    list(",
    '      title = "CARE",',
    '      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome4.md"))',
    "    ),",
    "    list(",
    '      title = "References",',
    '      text = readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1welcome5.md"))',
    "    )",
    "  )",
    ")",
    "",
    "# =============================================================================",
    "# TEXT CONTENT - SCENARIO MODULE",
    "# =============================================================================",
    "",
    'tx_2solution <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2solution.md"))',
    'tx_2targets <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2targets.md"))',
    'tx_2cost <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2cost.md"))',
    'tx_2climate <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2climate.md"))',
    'tx_2ess <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_2ecosystemServices.md"))',
    "",
    "# =============================================================================",
    "# TEXT CONTENT - HELP MODULE",
    "# =============================================================================",
    "",
    'tx_1footer <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_1footer.md"))',
    "",
    'tx_6faq <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6faq.md"))',
    'tx_6technical <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6technical.md"))',
    'tx_6changelog <- readr::read_file(file.path(data_dir, "markdown", "shinyplanr_6changelog.md"))',
    "",
    "# =============================================================================",
    "# PLOTTING THEMES",
    "# =============================================================================",
    "",
    "map_theme <- ggplot2::theme_bw(base_size = 14) +",
    "  ggplot2::theme(",
    '    legend.position = "right",',
    '    legend.direction = "vertical",',
    "    axis.title = ggplot2::element_blank()",
    "  )",
    "",
    "bar_theme <- ggplot2::theme_bw(base_size = 14) +",
    "  ggplot2::theme(",
    '    legend.position = "right",',
    '    legend.direction = "vertical",',
    "    axis.title = ggplot2::element_blank()",
    "  )",
    "",
    "# =============================================================================",
    "# OPTIONAL: CUSTOM CSS",
    "# =============================================================================",
    "",
    "# Uncomment to use custom CSS",
    '# file.copy(file.path(data_dir, "custom.css"),',
    '#           file.path("inst", "app", "www", "custom.css"),',
    "#           overwrite = TRUE)",
    "",
    "# =============================================================================",
    "# SAVE INTERNAL DATA",
    "# =============================================================================",
    "",
    "usethis::use_data(",
    "  options,",
    "  map_theme,",
    "  bar_theme,",
    "  Dict,",
    "  vars,",
    "  raw_sf,",
    "  bndry,",
    "  overlay,",
    "  tx,",
    "  tx_1footer,",
    "  tx_2solution,",
    "  tx_2targets,",
    "  tx_2cost,",
    "  tx_2climate,",
    "  tx_2ess,",
    "  tx_6faq,",
    "  tx_6technical,",
    "  tx_6changelog,",
    "  overwrite = TRUE,",
    "  internal = TRUE",
    ")",
    "",
    'message("App configuration complete for ", country)',
    ""
  )

  file_path <- file.path(output_dir, "setup-app.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Internal function to write Dict_Feature.csv
.write_dict_feature <- function(output_dir, oceandatr, include_cost, include_mpas) {

  if (oceandatr) {
    # Pre-populated dictionary for oceandatr layers
    # Variable names must match oceandatr output exactly
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",

      # Bathymetry / Depth Zones (from oceandatr::get_bathymetry with classify_bathymetry = TRUE)
      "Continental Shelf (0-200m),continental_shelf,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The shallow ocean zone from the coast to 200m depth.",
      "Upper Bathyal (200-800m),upper_bathyal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The upper slope zone from 200-800m depth.",
      "Lower Bathyal (800-3500m),lower_bathyal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The lower slope zone from 800-3500m depth.",
      "Abyssal (3500-6500m),abyssal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The abyssal zone found on abyssal plains from 3500-6500m.",
      "Hadal (>6500m),hadal,Depth Zones,Depth,Feature,30,0,85,FALSE,TRUE,,The deepest ocean zone found in trenches below 6500m.",

      # Geomorphology (from oceandatr::get_geomorphology)
      "Abyssal Hills,Abyssal_Hills,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Small elevations on the abyssal plain.",
      "Abyssal Plains,Abyssal_Plains,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat areas of the deep ocean floor.",
      "Bridges,Bridges,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Seafloor features connecting elevated areas.",
      "Canyons (Blind),Canyons_blind,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that do not incise the continental shelf.",
      "Canyons (Shelf-incising),Canyons_shelf_incising,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that cut into the continental shelf.",
      "Escarpments,Escarpments,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Long cliff-like features on the seafloor.",
      "Guyots,Guyots,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat-topped seamounts (tablemounts).",
      "Large Basins,Large_basins_of_seas_and_oceans,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Large enclosed or semi-enclosed depressions on the seafloor.",
      "Major Ocean Basins,Major_ocean_basins,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,The main structural basins of the ocean floor.",
      "Plateaus,Plateaus,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat elevated areas of the seafloor.",
      "Ridges,Ridges,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Elongated elevated features on the seafloor.",
      "Rift Valleys,Rift_valleys,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Linear depressions associated with tectonic spreading.",
      "Sills,Sills,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Shallow ridges separating basins.",
      "Small Basins,Small_basins_of_seas_and_oceans,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Smaller enclosed depressions on the seafloor.",
      "Spreading Ridges,Spreading_ridges,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Mid-ocean ridges where new seafloor is created.",
      "Terraces,Terraces,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Step-like features on the seafloor.",
      "Trenches,Trenches,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Deep linear depressions at subduction zones.",
      "Troughs,Troughs,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Long narrow depressions on the seafloor.",
      "Shelf Basins (Perched),Basins_perched_on_the_shelf,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental shelf.",
      "Slope Basins (Perched),Basins_perched_on_the_slope,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental slope.",
      "Fans,Fans,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Submarine fan deposits at canyon mouths.",
      "Glacial Troughs,Glacial_troughs,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,U-shaped valleys carved by glaciers.",
      "Large Shelf Valleys,Large_shelf_valleys_and_glacial_troughs,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Major valleys crossing the continental shelf.",
      "Moderate Shelf Valleys,Moderate_size_shelf_valley,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Medium-sized valleys on the continental shelf.",
      "Rises,Rises,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Gradual elevations of the seafloor.",
      "Small Shelf Valleys,Small_shelf_valley,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Minor valleys on the continental shelf.",

      # Seamounts and Knolls (from oceandatr::get_seamounts_buffered and get_knolls)
      "Seamounts,seamounts,Seamounts,Seamounts,Feature,30,0,85,TRUE,TRUE,,Underwater mountains rising >1000m from the seafloor.",
      "Knolls,knolls,Knolls,Knolls,Feature,30,0,85,TRUE,TRUE,,Smaller underwater hills rising 500-1000m from the seafloor.",

      # Environmental Regions (from oceandatr::get_enviro_regions)
      "Environmental Zone 1,enviro_zone_1,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 2,enviro_zone_2,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 3,enviro_zone_3,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",

      # Deep-sea Corals (from oceandatr::get_coral_habitat)
      "Antipatharia (Black Coral),antipatharia,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for black corals.",
      "Cold-water Corals,cold_corals,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for cold-water corals.",
      "Octocorals,octocorals,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for soft corals."
    )

    # Add cost layers
    if (include_cost) {
      dict_rows <- c(dict_rows,
        "Equal Area Cost,Cost_Area,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,All planning units have equal cost based on their area.",
        "Distance to Coast,Cost_Distance,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,Cost based on distance from the coast."
      )
    }

    # Add MPA constraint
    if (include_mpas) {
      dict_rows <- c(dict_rows,
        "Marine Protected Areas,mpas,Protected Areas,MPAs,LockIn,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas."
      )
    }

  } else {
    # Minimal template for custom data
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",
      "# Example Feature,example_feature,Habitat,Habitat,Feature,30,0,85,TRUE,TRUE,,Description of why this feature is important.",
      "# Example Cost,example_cost,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,Description of the cost layer."
    )

    if (include_cost) {
      dict_rows <- c(dict_rows,
        "Equal Area Cost,Cost_Area,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,All planning units have equal cost."
      )
    }

    if (include_mpas) {
      dict_rows <- c(dict_rows,
        "Marine Protected Areas,mpas,Protected Areas,MPAs,LockIn,NA,NA,NA,TRUE,TRUE,,Existing protected areas to lock in."
      )
    }
  }

  file_path <- file.path(output_dir, "Dict_Feature.csv")
  writeLines(dict_rows, file_path)
  message("Created: ", file_path)
}


# Internal function to write markdown templates
.write_markdown_templates <- function(output_dir, country) {

  # Copy template markdown files from inst/templates/markdown/

  template_dir <- system.file("templates", "markdown", package = "shinyplanr")
  if (template_dir == "") {
    # Fallback for development: look relative to package root
    template_dir <- file.path("inst", "templates", "markdown")
  }

  # Target markdown directory
  md_dir <- file.path(output_dir, "markdown")

  # List of expected template files
  template_files <- c(
    "shinyplanr_1welcome1.md",
    "shinyplanr_1welcome2.md",
    "shinyplanr_1welcome3.md",
    "shinyplanr_1welcome4.md",
    "shinyplanr_1welcome5.md",
    "shinyplanr_1footer.md",
    "shinyplanr_2solution.md",
    "shinyplanr_2targets.md",
    "shinyplanr_2cost.md",
    "shinyplanr_2climate.md",
    "shinyplanr_2ecosystemServices.md",
    "shinyplanr_6faq.md",
    "shinyplanr_6technical.md",
    "shinyplanr_6changelog.md"
  )

  # Copy each template file
  copied_count <- 0
  for (filename in template_files) {
    src_file <- file.path(template_dir, filename)
    dst_file <- file.path(md_dir, filename)

    if (file.exists(src_file)) {
      file.copy(src_file, dst_file, overwrite = FALSE)
      copied_count <- copied_count + 1
    } else {
      message("Warning: Template not found: ", filename)
    }
  }

  message("Copied: ", copied_count, " markdown template files from inst/templates/markdown/")
}
