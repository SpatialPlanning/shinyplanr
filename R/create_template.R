#' Create a new shinyplanr deployment project
#'
#' Creates a standalone deployment project for a new region. The project
#' contains all the files a practitioner needs to prepare their spatial data,
#' configure the app, test locally, and deploy to Posit Connect — without
#' modifying the shinyplanr package source code.
#'
#' @param country Character. Name of the country/region (e.g., "Fiji", "Kosrae").
#'   Used for folder naming and default titles.
#' @param crs Character. Coordinate reference system for the analysis.
#'   Default is "ESRI:54009" (Mollweide equal-area projection).
#'   Use \url{https://projectionwizard.org} to find an appropriate local CRS.
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
#' @param output_dir Character. Path where the deployment project folder will be
#'   created. Defaults to \code{file.path("..", country)}, creating a sibling
#'   directory to the current working directory. The deployer opens this folder
#'   as their R project — it is \strong{not} inside the shinyplanr package source.
#' @param use_renv Logical. If TRUE (default), initialises renv in the new
#'   project to lock package versions for reproducible deployments. Requires
#'   the renv package to be installed. Set to FALSE to skip renv initialisation.
#' @param create_rproj Logical. If TRUE (default), creates an RStudio .Rproj
#'   file in the new project for easy project opening.
#'
#' @return Invisibly returns the path to the created project folder.
#'
#' @examples
#' \dontrun{
#' # Create a deployment project for Tonga
#' create_shinyplanr_template(
#'   country    = "Tonga",
#'   crs        = "EPSG:32702",
#'   oceandatr  = TRUE,
#'   output_dir = "../tonga-shinyplanr"
#' )
#'
#' # Minimal template for custom data, without renv
#' create_shinyplanr_template(
#'   country   = "MyRegion",
#'   crs       = "+proj=cea +lon_0=150 +lat_ts=-10",
#'   oceandatr = FALSE,
#'   use_renv  = FALSE
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
    output_dir = file.path("..", country),
    use_renv = TRUE,
    create_rproj = TRUE
) {

  # Validate inputs
  if (missing(country) || !is.character(country) || nchar(country) == 0) {
    stop("'country' must be a non-empty character string.")
  }
  if (!is.character(crs) || nchar(crs) == 0) {
    stop("'crs' must be a non-empty character string.")
  }
  if (!is.logical(oceandatr)) stop("'oceandatr' must be TRUE or FALSE.")
  if (!is.logical(use_renv))  stop("'use_renv' must be TRUE or FALSE.")

  # The setup/ folder holds all deployer-edited scripts and source data
  setup_dir <- file.path(output_dir, "setup")

  dirs_to_create <- c(
    output_dir,
    file.path(output_dir, "config"),
    file.path(output_dir, "www"),
    setup_dir,
    file.path(setup_dir, "data"),
    file.path(setup_dir, "logos"),
    file.path(setup_dir, "content")
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
    default_logo <- file.path("man", "figures", "logo.png")
  }
  logos_dir <- file.path(setup_dir, "logos")
  if (file.exists(default_logo)) {
    file.copy(default_logo, file.path(logos_dir, "logo.png"),  overwrite = FALSE)
    file.copy(default_logo, file.path(logos_dir, "logo2.png"), overwrite = FALSE)
    file.copy(default_logo, file.path(logos_dir, "logo3.png"), overwrite = FALSE)
    message("Copied default logo to: ", logos_dir)
  }

  # Copy default funder logo
  funder_logo <- system.file("app", "www", "FunderLogo.png", package = "shinyplanr")
  if (funder_logo == "") {
    funder_logo <- file.path("inst", "app", "www", "FunderLogo.png")
  }
  if (file.exists(funder_logo)) {
    file.copy(funder_logo, file.path(logos_dir, "logo_funder.png"), overwrite = FALSE)
    message("Copied funder logo to: ", logos_dir)
  }

  # Copy UQ logo to project www/ (needed at runtime)
  uq_logo <- system.file("app", "www", "uq-logo-white.png", package = "shinyplanr")
  if (file.exists(uq_logo)) {
    file.copy(uq_logo, file.path(output_dir, "www", "uq-logo-white.png"), overwrite = FALSE)
  }

  # Generate files
  .write_setup_data(setup_dir, country, crs, oceandatr, resolution,
                    include_climate, include_cost, include_mpas)
  .write_setup_app(setup_dir, country, crs, include_climate)
  .write_dict_feature(setup_dir, oceandatr, include_cost, include_mpas)
  .write_content_templates(setup_dir, country)
  .write_app_r(output_dir, country)
  .write_deploy_r(output_dir, country)

  if (isTRUE(create_rproj)) {
    .write_rproj(output_dir, country)
  }

  if (isTRUE(use_renv)) {
    .init_renv(output_dir)
  }

  message("\n========================================")
  message("Deployment project created: ", normalizePath(output_dir))
  message("========================================")
  message("")
  message("Project structure:")
  message("  ", output_dir, "/")
  message("  \u251c\u2500\u2500 app.R          \u2190 do not edit")
  message("  \u251c\u2500\u2500 deploy.R       \u2190 deploy to Posit Connect")
  message("  \u251c\u2500\u2500 ", country, ".Rproj   \u2190 open this in RStudio")
  message("  \u251c\u2500\u2500 config/        \u2190 auto-generated by setup-app.R")
  message("  \u251c\u2500\u2500 www/           \u2190 auto-generated by setup-app.R")
  message("  \u2514\u2500\u2500 setup/")
  message("      \u251c\u2500\u2500 setup-data.R \u2190 Step 1: prepare spatial data")
  message("      \u251c\u2500\u2500 setup-app.R  \u2190 Step 2: configure the app")
  message("      \u251c\u2500\u2500 Dict_Feature.csv")
  message("      \u251c\u2500\u2500 data/        \u2190 place raw spatial files here")
  message("      \u251c\u2500\u2500 logos/       \u2190 place logo image files here")
  message("      \u2514\u2500\u2500 content/     \u2190 edit markdown/content files here")
  message("")
  message("Next steps:")
  message("1. Open the project in RStudio:")
  message("   File > Open Project > ", file.path(output_dir, paste0(country, ".Rproj")))
  message("2. Edit and run: setup/setup-data.R")
  message("   (generates the spatial data file in setup/data/)")
  message("3. Edit as needed:")
  message("   - setup/Dict_Feature.csv  (feature definitions)")
  message("   - setup/logos/            (logo images)")
  message("   - setup/content/          (help text)")
  message("4. Run: setup/setup-app.R")
  message("   (generates config/shinyplanr_config.rds)")
  message("5. Test locally: shiny::runApp()")
  message("6. Before first deployment, set up Posit Connect:")
  message("   rsconnect::setAccountInfo(name='...', token='...', secret='...')")
  message("7. Deploy: source('deploy.R')")
  message("")
  message("See the shinyplanr manual (Chapter 4) for detailed instructions.")

  invisible(output_dir)
}


# ---- Internal writer functions -----------------------------------------------

# Writes app.R to the deployment project root
.write_app_r <- function(output_dir, country) {
  template_path <- system.file("templates", "app.R", package = "shinyplanr")
  if (template_path != "" && file.exists(template_path)) {
    content <- readLines(template_path, warn = FALSE)
    content <- gsub("\\{country\\}", country, content)
  } else {
    content <- c(
      "# app.R",
      paste0("# shinyplanr deployment for ", country),
      "# Generated by shinyplanr::create_shinyplanr_template()",
      "#",
      "# DO NOT edit this file directly.",
      "# To update the app configuration, re-run:",
      "#   setup/setup-app.R",
      "",
      "# Load region configuration (generated by setup-app.R)",
      'shinyplanr::load_config("config/shinyplanr_config.rds")',
      "",
      "# Launch the app",
      "shinyplanr::run_app()"
    )
  }
  file_path <- file.path(output_dir, "app.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Writes deploy.R to the deployment project root
.write_deploy_r <- function(output_dir, country) {
  template_path <- system.file("templates", "deploy.R", package = "shinyplanr")
  if (template_path != "" && file.exists(template_path)) {
    content <- readLines(template_path, warn = FALSE)
    content <- gsub("\\{country\\}", country, content)
  } else {
    content <- c(
      "# deploy.R",
      paste0("# Deploy ", country, " shinyplanr app to Posit Connect"),
      "# Generated by shinyplanr::create_shinyplanr_template()",
      "#",
      "# FIRST TIME SETUP:",
      "#   1. Create an API key at: https://connect.posit.cloud/connect/#!/api-keys",
      "#   2. Run:",
      "#      rsconnect::setAccountInfo(name='<name>', token='<token>', secret='<secret>')",
      "#",
      "# BEFORE DEPLOYING: ensure config is up to date",
      "#   source('setup/setup-app.R')",
      "#",
      "# IF USING renv: update the lock file before deploying",
      "#   renv::snapshot()",
      "#",
      "# TO UPGRADE shinyplanr:",
      "#   renv::update('shinyplanr')",
      "#   source('setup/setup-app.R')",
      "#   renv::snapshot()",
      "#   source('deploy.R')",
      "",
      "files_to_deploy <- c(",
      '  "app.R",',
      '  "deploy.R",',
      '  list.files("config", full.names = TRUE, recursive = TRUE),',
      '  list.files("www",    full.names = TRUE, recursive = TRUE)',
      ")",
      "",
      "# Include renv files if present",
      'if (file.exists("renv.lock"))  files_to_deploy <- c(files_to_deploy, "renv.lock")',
      'if (file.exists(".Rprofile"))  files_to_deploy <- c(files_to_deploy, ".Rprofile")',
      'if (dir.exists("renv"))        files_to_deploy <- c(files_to_deploy,',
      '                                 list.files("renv", full.names = TRUE, recursive = TRUE))',
      "",
      "rsconnect::deployApp(",
      paste0('  appName     = "', country, '",'),
      "  appFiles    = files_to_deploy,",
      "  forceUpdate = TRUE",
      ")"
    )
  }
  file_path <- file.path(output_dir, "deploy.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Writes an RStudio .Rproj file to the deployment project root
.write_rproj <- function(output_dir, country) {
  template_path <- system.file("templates", "project.Rproj", package = "shinyplanr")
  if (template_path != "" && file.exists(template_path)) {
    content <- readLines(template_path, warn = FALSE)
  } else {
    content <- c(
      "Version: 1.0",
      "",
      "RestoreWorkspace: No",
      "SaveWorkspace: No",
      "AlwaysSaveHistory: Default",
      "",
      "EnableCodeIndexing: Yes",
      "UseSpacesForTab: Yes",
      "NumSpacesForTab: 2",
      "Encoding: UTF-8",
      "",
      "AutoAppendNewline: Yes",
      "StripTrailingWhitespace: Yes",
      "LineEndingConversion: Posix"
    )
  }
  file_path <- file.path(output_dir, paste0(country, ".Rproj"))
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Initialises renv in the deployment project (bare = TRUE: infrastructure only)
.init_renv <- function(output_dir) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    message(
      "\nNote: renv is not installed. Skipping renv initialisation.",
      "\nTo use renv for reproducible deployments, run:",
      "\n  install.packages('renv')",
      "\n  renv::init()   # from inside the new project directory"
    )
    return(invisible(NULL))
  }

  old_wd <- setwd(output_dir)
  on.exit(setwd(old_wd), add = TRUE)

  tryCatch(
    {
      # bare = TRUE: set up renv infrastructure without installing packages.
      # The deployer runs renv::snapshot() after testing locally to lock versions.
      renv::init(bare = TRUE)
      message(
        "\nrenv initialised (bare). After testing locally, run:",
        "\n  renv::snapshot()   # lock package versions",
        "\n  source('deploy.R') # deploy to Posit Connect"
      )
    },
    error = function(e) {
      message(
        "\nCould not initialise renv: ", e$message,
        "\nYou can initialise it manually later: renv::init()"
      )
    }
  )
}


# ---- setup-data.R writer -----------------------------------------------------

.write_setup_data <- function(setup_dir, country, crs, oceandatr, resolution,
                               include_climate, include_cost, include_mpas) {

  # Header
  content <- c(
    "# setup-data.R",
    paste0("# Prepare spatial data for shinyplanr: ", country),
    paste0("# Generated: ", Sys.Date()),
    "#",
    "# Run this script once to prepare the raw spatial data.",
    "# Output: setup/data/{country}_RawData.rda",
    "#",
    "# Run from the project root (with the .Rproj open):",
    "#   source('setup/setup-data.R')",
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

  content <- c(content,
    "# =============================================================================",
    "# BASIC PARAMETERS",
    "# =============================================================================",
    "",
    paste0('country   <- "', country, '"'),
    paste0('crs       <- "', crs, '"'),
    paste0("resolution <- ", resolution, "L  # Planning unit size in meters"),
    "",
    'setup_dir <- "setup"                              # Location of this folder',
    'data_path <- file.path(setup_dir, "data")         # Raw spatial data files',
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
      '# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%',
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
      '  geom_sf(data = PUs, fill = NA, colour = "grey80") +',
      '  geom_sf(data = bndry, fill = NA, colour = "blue") +',
      '  geom_sf(data = coast, fill = "darkgrey")',
      ""
    )
  } else {
    content <- c(content,
      "# =============================================================================",
      "# BOUNDARIES (custom data)",
      "# =============================================================================",
      "",
      "# TODO: Load your boundary file",
      '# bndry <- sf::st_read(file.path(data_path, "my_boundary.gpkg")) %>%',
      "#   sf::st_transform(crs = crs)",
      "",
      "# TODO: Load your coastline for plotting",
      '# coast <- sf::st_read(file.path(data_path, "my_coastline.gpkg")) %>%',
      "#   sf::st_transform(crs = crs)",
      "",
      "# TODO: Create or load planning units",
      "# PUs <- spatialgridr::get_grid(boundary = bndry,",
      "#                               crs = crs,",
      '#                               output = "sf_hex",',
      "#                               resolution = resolution)",
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
      "bathymetry   <- oceandatr::get_bathymetry(spatial_grid = PUs, classify_bathymetry = TRUE) %>% sf::st_drop_geometry()",
      "geomorphology <- oceandatr::get_geomorphology(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "knolls       <- oceandatr::get_knolls(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "seamounts    <- oceandatr::get_seamounts(spatial_grid = PUs, buffer = 30000) %>% sf::st_drop_geometry()",
      "enviro_zones <- oceandatr::get_enviro_zones(spatial_grid = PUs, max_num_clusters = 5, show_plots = FALSE) %>% sf::st_drop_geometry()",
      "corals       <- oceandatr::get_coral_habitat(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "",
      "dat_sf <- dplyr::bind_cols(PUs, bathymetry, geomorphology, knolls, seamounts, enviro_zones, corals) %>%",
      "  dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))",
      ""
    )
  } else {
    content <- c(content,
      "# TODO: Load and process your feature data, then combine into dat_sf",
      "# dat_sf <- dplyr::bind_cols(PUs, ...) %>%",
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
      "PU_Area <- as.numeric(units::set_units(sf::st_area(PUs)[1], km^2)) %>% round(2)",
      "",
      "cost <- dat_sf %>%",
      "  dplyr::select(geometry) %>%",
      "  spatialplanr::splnr_get_distCoast(custom_coast = coast) %>%",
      "  dplyr::mutate(",
      "    Cost_Area     = PU_Area,",
      "    Cost_Distance = coastDistance_km",
      "  ) %>%",
      "  dplyr::select(-coastDistance_km) %>%",
      "  sf::st_drop_geometry()",
      "",
      "dat_sf <- dplyr::bind_cols(dat_sf, cost)",
      ""
    )
  }

  # MPA data
  if (include_mpas) {
    content <- c(content,
      "# =============================================================================",
      "# LOCKED-IN AREAS (MPAs)",
      "# =============================================================================",
      "",
      "mpas <- spatialplanr::splnr_get_MPAs(PlanUnits = PUs, Countries = country) %>%",
      "  sf::st_transform(crs = crs) %>%",
      "  dplyr::select(geometry) %>%",
      '  spatialgridr::get_data_in_grid(spatial_grid = PUs, dat = ., name = "mpas", cutoff = 0.5) %>%',
      "  sf::st_drop_geometry()",
      "",
      "dat_sf <- dplyr::bind_cols(dat_sf, mpas)",
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
      "# climate_sf <- readr::read_rds(file.path(data_path, 'sst_trends.rds')) %>%",
      "#   sf::st_transform(crs) %>%",
      "#   sf::st_interpolate_aw(dat_sf, extensive = FALSE, na.rm = TRUE, keep_NA = TRUE)",
      "# dat_sf <- dplyr::bind_cols(dat_sf, climate_sf %>% sf::st_drop_geometry())",
      ""
    )
  }

  # Final save
  content <- c(content,
    "# =============================================================================",
    "# FINAL PROCESSING AND SAVE",
    "# =============================================================================",
    "",
    "dat_sf <- dat_sf %>%",
    "  dplyr::relocate(geometry, .after = tidyselect::everything())",
    "",
    "if (any(is.na(sf::st_drop_geometry(dat_sf)))) {",
    '  warning("NA values found in data - replacing with 0")',
    "  dat_sf <- dat_sf %>%",
    "    dplyr::mutate(across(where(is.numeric), ~replace_na(., 0)))",
    "}",
    "",
    'message("Data columns: ", paste(names(dat_sf), collapse = ", "))',
    "",
    "save(dat_sf, bndry, coast,",
    '     file = file.path(data_path, paste0(country, "_RawData.rda")))',
    "",
    'message("Data saved to: ", file.path(data_path, paste0(country, "_RawData.rda")))',
    'message("Next: run setup/setup-app.R")',
    ""
  )

  file_path <- file.path(setup_dir, "setup-data.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- setup-app.R writer ------------------------------------------------------

.write_setup_app <- function(setup_dir, country, crs, include_climate) {

  content <- c(
    "# setup-app.R",
    paste0("# Configure shinyplanr app for: ", country),
    paste0("# Generated: ", Sys.Date()),
    "#",
    "# Run this script after setup-data.R.",
    "# Output: config/shinyplanr_config.rds  (in the project root)",
    "#",
    "# Run from the project root (with the .Rproj open):",
    "#   source('setup/setup-app.R')",
    "",
    "library(tidyverse)",
    "library(sf)",
    "",
    paste0('country   <- "', country, '"'),
    'setup_dir <- "setup"                              # Location of the setup folder',
    'data_path <- file.path(setup_dir, "data")         # Raw spatial data files',
    "",
    "# =============================================================================",
    "# APP OPTIONS",
    "# =============================================================================",
    "",
    "options <- list(",
    "",
    "  ## General",
    paste0('  app_title  = "', country, ': shinyplanr",'),
    paste0('  nav_title  = "', country, ' Spatial Planning",'),
    '  navbar = list(theme = "dark"),  # "light" or "dark"',
    "",
    "  ## Funder link",
    '  funder_url = "https://spatialplanning.github.io",',
    "",
    "  ## Logo file locations (relative to setup/logos/)",
    '  file_logo        = file.path(setup_dir, "logos", "logo.png"),',
    '  file_logo2       = file.path(setup_dir, "logos", "logo2.png"),',
    '  file_logo3       = file.path(setup_dir, "logos", "logo3.png"),',
    '  file_logo_funder = file.path(setup_dir, "logos", "logo_funder.png"),',
    '  file_data        = file.path(data_path, paste0(country, "_RawData.rda")),',
    "",
    "  ## Module switches (TRUE = enabled, FALSE = disabled)",
    "  mod_1welcome = TRUE,",
    "  mod_2scenario = TRUE,",
    "  mod_3compare = TRUE,",
    "  mod_4features = TRUE,",
    "  mod_5coverage = TRUE,",
    "  mod_6help = TRUE,",
    "  mod_7credit = FALSE,",
    "",
    "  ## Report generation",
    "  include_report = TRUE,",
    "",
    "  ## Bioregion stratification",
    "  include_bioregion = FALSE,",
    "",
    "  ## UQ logo in welcome footer",
    "  show_uq_logo = TRUE,   # Set FALSE to hide the UQ logo"
  )

  # Climate options
  if (include_climate) {
    content <- c(content,
      "",
      "  ## Climate-smart planning",
      "  include_climateChange = FALSE,  # Set TRUE when climate data is available",
      "  climate_change = 1,  # 0 = off; 1 = CPA; 2 = Feature; 3 = Percentile",
      "  percentile     = 5,",
      "  direction      = -1,  # 1 = high values are refugia; -1 = low values",
      "  refugiaTarget  = 1,"
    )
  }

  content <- c(content,
    "",
    "  ## Locked areas",
    "  include_lockedArea = TRUE,",
    "",
    "  ## Target grouping",
    '  targetsBy = "individual",  # "individual", "category", or "master"',
    "",
    "  ## Objective function",
    '  obj_func = "min_shortfall",  # "min_set" or "min_shortfall"',
    "",
    "  ## CRS",
    paste0('  cCRS = "', crs, '"'),
    ")",
    "",
    "# =============================================================================",
    "# COPY LOGOS TO www/",
    "# =============================================================================",
    "",
    'if (!dir.exists("www")) dir.create("www", recursive = TRUE)',
    "",
    "logo_map <- list(",
    '  file_logo        = "logo.png",',
    '  file_logo2       = "logo2.png",',
    '  file_logo3       = "logo3.png",',
    '  file_logo_funder = "logo_funder.png"',
    ")",
    "",
    "for (opt_name in names(logo_map)) {",
    "  src <- options[[opt_name]]",
    "  dst <- file.path(\"www\", logo_map[[opt_name]])",
    "  if (!is.null(src) && file.exists(src)) {",
    "    file.copy(src, dst, overwrite = TRUE)",
    "    message(\"Copied logo: \", basename(src))",
    "  } else {",
    "    message(\"Logo not found (skipping): \", src)",
    "  }",
    "}",
    "",
    "# =============================================================================",
    "# FEATURE DICTIONARY",
    "# =============================================================================",
    "",
    'Dict <- readr::read_csv(file.path(setup_dir, "Dict_Feature.csv")) %>%',
    "  dplyr::filter(includeApp) %>%",
    "  dplyr::arrange(.data$type, .data$categoryID, .data$nameCommon)",
    "",
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
    "raw_sf <- dat_sf %>%",
    "  sf::st_drop_geometry() %>%",
    "  dplyr::select(tidyselect::all_of(vars))",
    "",
    "zero_cols <- colnames(raw_sf)[which(colSums(raw_sf, na.rm = TRUE) == 0)]",
    "if (length(zero_cols) > 0) {",
    '  message("Removing all-zero columns: ", paste(zero_cols, collapse = ", "))',
    "  raw_sf <- raw_sf %>% dplyr::select(-tidyselect::any_of(zero_cols))",
    "  vars   <- vars[!vars %in% zero_cols]",
    "  Dict   <- Dict %>% dplyr::filter(!nameVariable %in% zero_cols)",
    "}",
    "",
    "raw_sf <- raw_sf %>%",
    "  dplyr::bind_cols(dat_sf %>% dplyr::select(geometry)) %>%",
    "  sf::st_as_sf()",
    "",
    "if (length(unique(vars)) != ncol(raw_sf) - 1) {",
    '  stop("Mismatch between Dict variables and data columns. Check Dict_Feature.csv")',
    "}",
    "",
    "# =============================================================================",
    "# PLOTTING OVERLAYS",
    "# =============================================================================",
    "",
    "bndry   <- bndry",
    "overlay <- coast",
    "",
    "# =============================================================================",
    "# TEXT CONTENT",
    "# =============================================================================",
    "",
    "content_dir <- file.path(setup_dir, \"content\")",
    "",
    "tx <- list(",
    "  welcome = list(",
    '    list(title = "Welcome",      text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome1.md"))),',
    '    list(title = "Terminology",  text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome2.md"))),',
    '    list(title = "Instructions", text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome3.md"))),',
    '    list(title = "CARE",         text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome4.md"))),',
    '    list(title = "References",   text = readr::read_file(file.path(content_dir, "shinyplanr_1welcome5.md")))',
    "  )",
    ")",
    "",
    'tx_1footer    <- readr::read_file(file.path(content_dir, "shinyplanr_1footer.md"))',
    'tx_2solution  <- readr::read_file(file.path(content_dir, "shinyplanr_2solution.md"))',
    'tx_2targets   <- readr::read_file(file.path(content_dir, "shinyplanr_2targets.md"))',
    'tx_2cost      <- readr::read_file(file.path(content_dir, "shinyplanr_2cost.md"))',
    'tx_2climate   <- readr::read_file(file.path(content_dir, "shinyplanr_2climate.md"))',
    'tx_2ess       <- readr::read_file(file.path(content_dir, "shinyplanr_2ecosystemServices.md"))',
    'tx_6faq       <- readr::read_file(file.path(content_dir, "shinyplanr_6faq.md"))',
    'tx_6technical <- readr::read_file(file.path(content_dir, "shinyplanr_6technical.md"))',
    'tx_6changelog <- readr::read_file(file.path(content_dir, "shinyplanr_6changelog.md"))',
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
    "# SAVE CONFIGURATION",
    "# =============================================================================",
    "",
    "config_list <- list(",
    "  schema_version = shinyplanr:::.shinyplanr_schema_version,",
    "  options        = options,",
    "  map_theme      = map_theme,",
    "  bar_theme      = bar_theme,",
    "  Dict           = Dict,",
    "  vars           = vars,",
    "  raw_sf         = raw_sf,",
    "  bndry          = bndry,",
    "  overlay        = overlay,",
    "  tx             = tx,",
    "  tx_1footer     = tx_1footer,",
    "  tx_2solution   = tx_2solution,",
    "  tx_2targets    = tx_2targets,",
    "  tx_2cost       = tx_2cost,",
    "  tx_2climate    = tx_2climate,",
    "  tx_2ess        = tx_2ess,",
    "  tx_6faq        = tx_6faq,",
    "  tx_6technical  = tx_6technical,",
    "  tx_6changelog  = tx_6changelog",
    ")",
    "",
    "# =============================================================================",
    "# VALIDATE CONFIGURATION",
    "# =============================================================================",
    "#",
    "# Runs checks on the config before saving:",
    "#   - All Dict variables are present in raw_sf",
    "#   - CRS is consistent across raw_sf, bndry, and options$cCRS",
    "#   - No feature columns are all-zero or all-NA",
    "#   - Text content fields are character strings",
    "#   - Target values are in the 0-100 range",
    "#",
    "# strict = TRUE (default) stops with a clear error if any check fails.",
    "# Use strict = FALSE to get a report without stopping.",
    "shinyplanr::validate_shinyplanr_data(config_list)",
    "",
    "# =============================================================================",
    "# SAVE CONFIGURATION",
    "# =============================================================================",
    "",
    'if (!dir.exists("config")) dir.create("config", recursive = TRUE)',
    'saveRDS(config_list, file.path("config", "shinyplanr_config.rds"))',
    "",
    'message("\\nConfig saved: config/shinyplanr_config.rds")',
    'message("Run shiny::runApp() to test, or source(\'deploy.R\') to deploy.")',
    ""
  )

  file_path <- file.path(setup_dir, "setup-app.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- Dict_Feature.csv writer -------------------------------------------------

.write_dict_feature <- function(setup_dir, oceandatr, include_cost, include_mpas) {

  if (oceandatr) {
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",
      "Continental Shelf (0-200m),continental_shelf,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The shallow ocean zone from the coast to 200m depth.",
      "Upper Bathyal (200-800m),upper_bathyal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The upper slope zone from 200-800m depth.",
      "Lower Bathyal (800-3500m),lower_bathyal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The lower slope zone from 800-3500m depth.",
      "Abyssal (3500-6500m),abyssal,Depth Zones,Depth,Feature,30,0,85,TRUE,TRUE,,The abyssal zone found on abyssal plains from 3500-6500m.",
      "Hadal (>6500m),hadal,Depth Zones,Depth,Feature,30,0,85,FALSE,TRUE,,The deepest ocean zone found in trenches below 6500m.",
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
      "Seamounts,seamounts,Seamounts,Seamounts,Feature,30,0,85,TRUE,TRUE,,Underwater mountains rising >1000m from the seafloor.",
      "Knolls,knolls,Knolls,Knolls,Feature,30,0,85,TRUE,TRUE,,Smaller underwater hills rising 500-1000m from the seafloor.",
      "Environmental Zone 1,enviro_zone_1,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 2,enviro_zone_2,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 3,enviro_zone_3,Environmental Zones,EnviroZone,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Antipatharia (Black Coral),antipatharia,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for black corals.",
      "Cold-water Corals,cold_corals,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for cold-water corals.",
      "Octocorals,octocorals,Deep-sea Corals,Corals,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for soft corals."
    )
  } else {
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",
      "# TODO: Add your feature rows here",
      "# Example Feature,example_feature,Habitat,Habitat,Feature,30,0,85,TRUE,TRUE,,Description of this feature."
    )
  }

  if (include_cost) {
    dict_rows <- c(dict_rows,
      "Equal Area Cost,Cost_Area,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,All planning units have equal cost based on their area.",
      "Distance to Coast,Cost_Distance,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,Cost based on distance from the coast."
    )
  }

  if (include_mpas) {
    dict_rows <- c(dict_rows,
      "Marine Protected Areas,mpas,Protected Areas,MPAs,LockIn,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas."
    )
  }

  file_path <- file.path(setup_dir, "Dict_Feature.csv")
  writeLines(dict_rows, file_path)
  message("Created: ", file_path)
}


# ---- Content templates writer -----------------------------------------------
# (replaces the old .write_markdown_templates which used setup/markdown/)

.write_content_templates <- function(setup_dir, country) {
  # Source templates from inst/templates/markdown/ in the package
  template_dir <- system.file("templates", "markdown", package = "shinyplanr")
  if (template_dir == "") {
    template_dir <- file.path("inst", "templates", "markdown")
  }

  content_dir <- file.path(setup_dir, "content")

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

  copied_count <- 0
  for (filename in template_files) {
    src_file <- file.path(template_dir, filename)
    dst_file <- file.path(content_dir, filename)
    if (file.exists(src_file)) {
      file.copy(src_file, dst_file, overwrite = FALSE)
      copied_count <- copied_count + 1
    } else {
      message("Warning: Template not found: ", filename)
    }
  }

  message("Copied ", copied_count, " content template files to setup/content/")
}
