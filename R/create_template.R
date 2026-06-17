#' Create a new shinyplanr deployment project
#'
#' Creates a standalone deployment project for a new region. The project
#' contains all the files a practitioner needs to prepare their spatial data,
#' configure the app, test locally, and deploy to Posit Connect -- without
#' modifying the shinyplanr package source code.
#'
#' @param country Character. Name of the country/region (e.g., "Fiji", "Kosrae").
#'   Used for folder naming and default titles.
#' @param crs Character. Coordinate reference system for the analysis.
#'   Default is "ESRI:54009" (Mollweide equal-area projection).
#'   Use \url{https://projectionwizard.org} to find an appropriate local CRS.
#' @param oceandatr Logical. If TRUE (default), the 2_setup_data.R template will
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
#'   as their R project - it is \strong{not} inside the shinyplanr package source.
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
    output_dir = file.path("..", paste0("shinyplanr_", country)),
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

  # Copy default logos to the logos directory.
  # These are placeholder files - the deployer replaces them with their own images.
  #
  #   logo_navbar.png  - top-left of the navbar on every page
  #   logo_welcome.png - inline image in the welcome page (shinyplanr_1welcome1.md)
  #   logo_funder.png  - primary "Funded by" logo in the welcome page footer
  #   logo_funder2.png - optional second funder logo (default: UQ logo)
  #                      comment out file_logo_funder2 in 3_setup_app.R to hide it
  logos_dir <- file.path(setup_dir, "logos")

  default_logo <- system.file("man", "figures", "logo.png", package = "shinyplanr")
  if (default_logo == "") {
    default_logo <- file.path("man", "figures", "logo.png")
  }
  if (file.exists(default_logo)) {
    file.copy(default_logo, file.path(logos_dir, "logo_navbar.png"),  overwrite = FALSE)
    file.copy(default_logo, file.path(logos_dir, "logo_welcome.png"), overwrite = FALSE)
    message("Copied default navbar/welcome logos to: ", logos_dir)
  }

  funder_logo <- system.file("app", "www", "logo_funder.png", package = "shinyplanr")
  if (funder_logo == "") {
    funder_logo <- file.path("inst", "app", "www", "logo_funder.png")
  }
  if (file.exists(funder_logo)) {
    file.copy(funder_logo, file.path(logos_dir, "logo_funder.png"), overwrite = FALSE)
    message("Copied default funder logo to: ", logos_dir)
  }

  # Copy UQ logo as the default second funder logo.
  # It is placed in setup/logos/ as uq-logo-white.png so the deployer can
  # immediately see it is the UQ logo. They can replace it with any image
  # and point file_logo_funder2 at the new file, or comment out
  # file_logo_funder2 in 3_setup_app.R to show only one funder logo.
  uq_logo <- system.file("app", "www", "uq-logo-white.png", package = "shinyplanr")
  if (uq_logo == "") {
    uq_logo <- file.path("inst", "app", "www", "uq-logo-white.png")
  }
  if (file.exists(uq_logo)) {
    file.copy(uq_logo, file.path(logos_dir, "uq-logo-white.png"), overwrite = FALSE)
    message("Copied default second funder logo (UQ) to: ", logos_dir)
  }

  # Generate files
  .write_setup_enviro(setup_dir, oceandatr)
  .write_setup_data(setup_dir, country, crs, oceandatr, resolution,
                    include_climate, include_cost, include_mpas)
  .write_setup_app(setup_dir, country, crs, include_climate)
  .write_dict_feature(setup_dir, oceandatr, include_cost, include_mpas)
  .write_content_templates(setup_dir, country)
  .write_custom_css(setup_dir)
  .write_logos_readme(logos_dir)
  .write_app_r(output_dir, country)
  .write_deploy_r(output_dir, country)

  if (isTRUE(create_rproj)) {
    .write_rproj(output_dir, country)
  }

  if (isTRUE(use_renv)) {
    .init_renv(output_dir)
  }

  rproj_path <- normalizePath(
    file.path(output_dir, paste0(country, ".Rproj")),
    mustWork = FALSE
  )

  message("\n========================================")
  message("Deployment project created: ", normalizePath(output_dir))
  message("========================================")
  message("")
  message("Project structure:")
  message("  ", output_dir, "/")
  message("  \u251c\u2500\u2500 app.R          \u2190 do not edit")
  message("  \u251c\u2500\u2500 deploy.R       \u2190 deploy to Posit Connect")
  message("  \u251c\u2500\u2500 ", country, ".Rproj   \u2190 open this in RStudio")
  message("  \u251c\u2500\u2500 config/        \u2190 auto-generated by setup/3_setup_app.R")
  message("  \u251c\u2500\u2500 www/           \u2190 auto-generated by setup/3_setup_app.R")
  message("  \u2514\u2500\u2500 setup/")
  message("      \u251c\u2500\u2500 1_setup_enviro.R  \u2190 Step 1: install packages + renv")
  message("      \u251c\u2500\u2500 2_setup_data.R    \u2190 Step 2: prepare spatial data")
  message("      \u251c\u2500\u2500 3_setup_app.R     \u2190 Step 3: configure the app")
  message("      \u251c\u2500\u2500 Dict_Feature.csv")
  message("      \u251c\u2500\u2500 data/             \u2190 place raw spatial files here")
  message("      \u251c\u2500\u2500 logos/            \u2190 place logo image files here")
  message("      \u2514\u2500\u2500 content/          \u2190 edit markdown/content files here")
  message("")

  # Switch to the new project in the same RStudio window (newSession defaults
  # to FALSE, matching golem / RStudio's "New Project" wizard behaviour).
  # RStudio closes the current project and reopens in the same window.
  # The .Rprofile hook fires in the new session and opens 1_setup_enviro.R.
  # If prompted "Save workspace?", click "Don't Save".
  if (requireNamespace("rstudioapi", quietly = TRUE) &&
      rstudioapi::isAvailable()) {
    message("Switching to ", country, ".Rproj in RStudio...")
    message("(If prompted 'Save workspace?', click 'Don't Save')")
    message("setup/1_setup_enviro.R will open automatically.")
    rstudioapi::openProject(rproj_path)
  } else {
    message("Next steps:")
    message("1. Open the project:")
    message("   File > Open Project > ", rproj_path)
    message("   (setup/1_setup_enviro.R will open automatically)")
    message("2. Source setup/1_setup_enviro.R")
    message("   (installs all packages, writes renv.lock, opens step 2)")
    message("3. Source setup/2_setup_data.R")
    message("   (prepares spatial data, opens step 3)")
    message("4. Source setup/3_setup_app.R")
    message("   (generates config/shinyplanr_config.rds, opens app.R)")
    message("5. Test locally: shiny::runApp()")
    message("6. Deploy: source('deploy.R')")
    message("")
    message("See the shinyplanr manual (Chapter 4) for detailed instructions.")
  }

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
      "# Include renv files needed by Posit Connect.",
      "# Connect reads renv.lock and installs packages server-side - do NOT include",
      "# renv/library/ (local compiled binaries that won't run on Connect's Linux server).",
      'if (file.exists("renv.lock"))        files_to_deploy <- c(files_to_deploy, "renv.lock")',
      'if (file.exists(".Rprofile"))        files_to_deploy <- c(files_to_deploy, ".Rprofile")',
      'if (file.exists("renv/activate.R")) files_to_deploy <- c(files_to_deploy, "renv/activate.R")',
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


# Initialises renv (bare infrastructure only).
# Package installation is deferred to setup/1_setup_enviro.R, which the user
# runs interactively from inside the correctly-activated project.
# This avoids all renv session-conflict and interactive-prompt issues.
#
# Also appends a one-time .Rprofile hook that opens 1_setup_enviro.R
# automatically when the user first opens the project in RStudio/Positron.
.init_renv <- function(output_dir) {
  if (!requireNamespace("renv", quietly = TRUE)) {
    message(
      "\nNote: renv is not installed. Skipping renv initialisation.",
      "\nTo set up renv later, open the project and run:",
      "\n  install.packages('renv')",
      "\n  source('setup/1_setup_enviro.R')"
    )
    return(invisible(NULL))
  }

  proj <- normalizePath(output_dir, mustWork = FALSE)

  tryCatch(
    withr::with_dir(proj, {

      # Create renv infrastructure only. Package installation happens in
      # 1_setup_enviro.R once the user is inside the activated project.
      renv::init(bare = TRUE)

      # Prepend global .Renviron loading so user-level env vars (e.g.
      # GITHUB_PAT) are available inside the isolated renv session.
      # renv's .Rprofile only sources renv/activate.R; without this line
      # the GitHub PAT stored in ~/.Renviron is invisible to renv::install().
      rprofile_path_tmp <- file.path(proj, ".Rprofile")
      existing_rp <- if (file.exists(rprofile_path_tmp)) {
        readLines(rprofile_path_tmp, warn = FALSE)
      } else {
        character(0)
      }
      writeLines(
        c(
          "# Load global ~/.Renviron so GITHUB_PAT and other user env vars are",
          "# available inside the renv project session (added by shinyplanr).",
          'if (file.exists("~/.Renviron")) readRenviron("~/.Renviron")',
          "",
          existing_rp
        ),
        rprofile_path_tmp
      )

      # Append a one-time startup hook to .Rprofile.
      # When the user opens the project, this opens 1_setup_enviro.R as a tab
      # then removes itself so it never fires again.
      #
      # renv::init(bare = TRUE) restricts .libPaths() to the project library
      # (empty), so requireNamespace("rstudioapi") fails even though rstudioapi
      # is installed. The fix: load rstudioapi from .Library (the base R system
      # library that renv never removes from the search path).
      hook <- paste(c(
        "",
        "# --- shinyplanr one-time startup hook (auto-removes after first run) ---",
        "local({",
        "  if (interactive() && nzchar(Sys.getenv('RSTUDIO'))) {",
        "    api <- tryCatch(",
        "      loadNamespace('rstudioapi', lib.loc = c(.libPaths(), .Library)),",
        "      error = function(e) NULL",
        "    )",
        "    if (!is.null(api) && api$isAvailable())",
        "      api$navigateToFile('setup/1_setup_enviro.R')",
        "  }",
        "  rp    <- readLines('.Rprofile', warn = FALSE)",
        "  start <- grep('shinyplanr one-time startup hook', rp)[1L]",
        "  if (!is.na(start)) writeLines(rp[seq_len(start - 1L)], '.Rprofile')",
        "})",
        "# --- end shinyplanr hook ---"
      ), collapse = "\n")

      rprofile_path <- file.path(proj, ".Rprofile")
      cat(hook, "\n", file = rprofile_path, append = TRUE)

      message("\nrenv infrastructure created. Open ", basename(proj),
              ".Rproj and run setup/1_setup_enviro.R to install packages.")
    }),
    error = function(e) {
      message(
        "\nCould not initialise renv: ", e$message,
        "\nYou can initialise it manually: renv::init(bare = TRUE)"
      )
    }
  )
}


# ---- 1_setup_enviro.R writer -------------------------------------------------

.write_setup_enviro <- function(setup_dir, oceandatr = TRUE) {

  github_pkgs_lines <- c(
    'renv::install("SpatialPlanning/shinyplanr@HEAD", prompt = FALSE)',
    'renv::install("SpatialPlanning/spatialplanr@HEAD", prompt = FALSE)',
    'renv::install("dreamRs/shinyWidgets@HEAD", prompt = FALSE)'
  )
  if (isTRUE(oceandatr)) {
    github_pkgs_lines <- c(
      github_pkgs_lines,
      'renv::install("emlab-ucsb/oceandatr@HEAD", prompt = FALSE)',
      'renv::install("emlab-ucsb/spatialgridr@HEAD", prompt = FALSE)'
    )
  }

  content <- c(
    "# setup/1_setup_enviro.R",
    "# Step 1: Install all required packages and lock versions with renv.",
    paste0("# Generated: ", Sys.Date()),
    "#",
    "# Run this script ONCE after opening the project for the first time.",
    "# Re-run if you add packages or upgrade shinyplanr.",
    "#",
    "# HOW TO RUN: Click 'Source' or run line-by-line.",
    "",
    "# =============================================================================",
    "# PRE-CHECK \u2014 Quarto CLI",
    "# =============================================================================",
    "#",
    "# The app generates reports using Quarto. The 'quarto' R package (installed",
    "# below) is a wrapper that calls the Quarto CLI binary. If the CLI is not",
    "# installed, report generation will fail at runtime.",
    "#",
    "# Download Quarto CLI from: https://quarto.org/docs/get-started/",
    "#",
    "if (!nzchar(Sys.which('quarto'))) {",
    "  warning(",
    "    '\\n[ACTION REQUIRED] Quarto CLI not found on PATH.',",
    "    '\\nThe app uses Quarto to generate reports.',",
    "    '\\nDownload and install it from: https://quarto.org/docs/get-started/',",
    "    '\\nThen restart R and re-run this script.',",
    "    '\\n(You can continue without Quarto, but report generation will fail.)',",
    "    call. = FALSE",
    "  )",
    "} else {",
    "  message('Quarto CLI found: v', system('quarto --version', intern = TRUE))",
    "}",
    "",
    "# =============================================================================",
    "# STEP 0 \u2014 GitHub Credentials",
    "# =============================================================================",
    "#",
    "# Several packages are installed from GitHub. renv contacts the GitHub API",
    "# for each one. Without authentication, requests are rate-limited to",
    "# 60/hour, causing intermittent 'error code 56' failures. Authentication",
    "# raises this to 5,000/hour and eliminates these errors.",
    "#",
    "# We use the 'gitcreds' package, which reads your GitHub PAT from the",
    "# system keychain (macOS Keychain / Windows Credential Manager).",
    "# If you have authenticated with GitHub via the 'gh' CLI or RStudio,",
    "# your credentials may already be stored and this will work automatically.",
    "#",
    "# Run the block below. It will:",
    "#   a) Install gitcreds if needed",
    "#   b) Check if a GitHub PAT is already stored in your keychain",
    "#   c) If not, open a prompt for you to paste your PAT",
    "#   d) Set GITHUB_PAT in this session so renv can use it",
    "#",
    "# To create a PAT (do this once, only if you don't have one):",
    "#   1. Go to: https://github.com/settings/tokens/new",
    "#      - Token name: 'R renv installs'",
    "#      - Expiration: 90 days",
    "#      - Scopes: leave ALL boxes UNCHECKED (public repos need no scope)",
    "#      - Click 'Generate token' and copy it (starts with ghp_...)",
    "#",
    "if (!requireNamespace('gitcreds', quietly = TRUE)) install.packages('gitcreds', quiet = TRUE)",
    "local({",
    "  cred <- tryCatch(gitcreds::gitcreds_get(), error = function(e) NULL)",
    "  if (is.null(cred) || !nzchar(cred$password)) {",
    "    message('No GitHub credentials found in keychain.')",
    "    message('Running gitcreds::gitcreds_set() \u2014 paste your PAT when prompted.')",
    "    gitcreds::gitcreds_set()",
    "    cred <- tryCatch(gitcreds::gitcreds_get(), error = function(e) NULL)",
    "  }",
    "  if (!is.null(cred) && nzchar(cred$password)) {",
    "    Sys.setenv(GITHUB_PAT = cred$password)",
    "    message('GITHUB_PAT set from keychain. Unauthenticated rate limit lifted.')",
    "  } else {",
    "    warning('Could not load GitHub credentials. GitHub API calls may fail.')",
    "  }",
    "})",
    "",
    "# =============================================================================",
    "# STEP 1 \u2014 Install GitHub-only packages",
    "# =============================================================================",
    "#",
    "# These packages are not on CRAN. Explicit org/repo ensures renv.lock",
    "# records the correct source for Posit Connect / new-machine deployments.",
    "# renv checks its global cache first \u2014 already-cached = near-instant.",
    "",
    github_pkgs_lines,
    "",
    "# =============================================================================",
    "# STEP 2 \u2014 Install CRAN packages",
    "# =============================================================================",
    "",
    "renv::install(c(",
    '  "shiny", "tidyverse", "sf", "terra", "ggplot2", "readr", "dplyr",',
    '  "tidyr", "purrr", "stringr", "tibble", "tidyselect", "bslib",',
    '  "leaflet", "htmltools", "patchwork", "gridExtra", "reactable",',
    '  "shinyalert", "shinycssloaders", "shinydisconnect", "shinyjs",',
    '  "prioritizr", "highs", "rnaturalearth", "rnaturalearthdata", "units",',
    '  "quarto", "withr", "rsconnect"',
    "), prompt = FALSE)",
    "",
    "# =============================================================================",
    "# STEP 3 \u2014 Optional: faster solvers",
    "# =============================================================================",
    "#",
    "# shinyplanr uses HiGHS by default (installed above) \u2014 no system dependencies.",
    "# For better performance on large problems, you can optionally install:",
    "#",
    "# CBC solver (rcbc) \u2014 requires system CBC libraries first:",
    "#   See: https://github.com/dirkschumacher/rcbc",
    "#",
    "# Gurobi \u2014 commercial solver, free academic licence available:",
    "#   See: https://www.gurobi.com/academia/academic-program-and-licenses/",
    "#",
    "# If either is installed, prioritizr will use it automatically in preference",
    "# to HiGHS (priority order: Gurobi > CBC > HiGHS).",
    "#",
    "# Uncomment to install rcbc (after installing system CBC libraries):",
    '# renv::install("dirkschumacher/rcbc@HEAD", prompt = FALSE)',
    "",
    "# =============================================================================",
    "# STEP 4 \u2014 Verify installs before locking",
    "# =============================================================================",
    "#",
    "# Check that the packages most critical to the app are actually installed.",
    "# renv::install() with prompt = FALSE does not stop on partial failure, so",
    "# this catches silent errors before they produce a broken renv.lock.",
    "",
    "local({",
    "  required <- c(",
    '    "shinyplanr", "spatialplanr", "shinyWidgets",',
    '    "shiny", "sf", "prioritizr", "highs",',
    '    "leaflet", "reactable", "bslib"',
    "  )",
    "  missing_pkgs <- required[",
    "    !vapply(required, requireNamespace, logical(1L), quietly = TRUE)",
    "  ]",
    "  if (length(missing_pkgs) > 0L) {",
    '    stop(',
    '      "The following packages failed to install:\\n  ",',
    '      paste(missing_pkgs, collapse = "\\n  "),',
    '      "\\nFix the errors above, then re-run renv::snapshot()."',
    "    )",
    "  }",
    '  message("All critical packages verified.")',
    "})",
    "",
    "# =============================================================================",
    "# STEP 5 \u2014 Lock versions",
    "# =============================================================================",
    "#",
    "# Writes renv.lock. Commit this file to version control.",
    "",
    "renv::snapshot()",
    "",
    'message("\\nAll packages installed. renv.lock written.")',
    'message("Next: open setup/2_setup_data.R and prepare the spatial data.")',
    "",
    "# Open the next setup script -----------------------------------------------",
    "if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {",
    "  rstudioapi::navigateToFile('setup/2_setup_data.R')",
    "}",
    ""
  )

  file_path <- file.path(setup_dir, "1_setup_enviro.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- 2_setup_data.R writer ---------------------------------------------------

.write_setup_data <- function(setup_dir, country, crs, oceandatr, resolution,
                               include_climate, include_cost, include_mpas) {

  # Header
  content <- c(
    "# setup/2_setup_data.R",
    paste0("# Step 2: Prepare spatial data for shinyplanr: ", country),
    paste0("# Generated: ", Sys.Date()),
    "#",
    "# Run this script once to prepare the raw spatial data.",
    "# Output: setup/data/{country}_RawData.rda",
    "#",
    "# HOW TO RUN: Click 'Source' or run line-by-line.",
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
      "bathymetry <- oceandatr::get_bathymetry(spatial_grid = PUs, classify_bathymetry = TRUE) # Keep geometry for bathymetry",
      "geomorphology <- oceandatr::get_geomorphology(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "knolls <- oceandatr::get_knolls(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "seamounts <- oceandatr::get_seamounts(spatial_grid = PUs, buffer = 30000) %>% sf::st_drop_geometry()",
      "enviro_zones <- oceandatr::get_enviro_zones(spatial_grid = PUs, max_num_clusters = 5, show_plots = FALSE) %>% sf::st_drop_geometry()",
      "corals <- oceandatr::get_coral_habitat(spatial_grid = PUs) %>% sf::st_drop_geometry()",
      "",
      "dat_sf <- dplyr::bind_cols(bathymetry, geomorphology, knolls, seamounts, enviro_zones, corals) %>%",
      "  dplyr::mutate(across(where(is.numeric), ~replace_na(.x, 0)))",
      "",
      "# Replace any spaces in column names with underscores",
      "names(dat_sf) <- stringr::str_replace_all(names(dat_sf), ' ', '_')",
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
      "    cost_area     = PU_Area,",
      "    cost_distance = coastDistance_km",
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
    'message("Next: open setup/3_setup_app.R and configure the app.")',
    "",
    "# Open the next setup script -----------------------------------------------",
    "if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {",
    "  rstudioapi::navigateToFile('setup/3_setup_app.R')",
    "}",
    ""
  )

  file_path <- file.path(setup_dir, "2_setup_data.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- 3_setup_app.R writer ----------------------------------------------------

.write_setup_app <- function(setup_dir, country, crs, include_climate) {

  content <- c(
    "# setup/3_setup_app.R",
    paste0("# Step 3: Configure shinyplanr app for: ", country),
    paste0("# Generated: ", Sys.Date()),
    "#",
    "# Run this script after 2_setup_data.R.",
    "# Output: config/shinyplanr_config.rds  (in the project root)",
    "#",
    "# HOW TO RUN: Click 'Source' or run line-by-line.",
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
    "#",
    "# NOTE: This variable is named 'shinyplanr_options' (not 'options') to avoid",
    "# shadowing base::options(), which is a function. If 'options' were used here",
    "# and you ran the app in the same R session without restarting, any code that",
    "# calls options() internally (e.g. withr, purrr) would find the list instead",
    "# of the function and crash R immediately.",
    "",
    "shinyplanr_options <- list(",
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
    "  #",
    "  # Replace the placeholder images in setup/logos/ with your own files,",
    "  # then re-run this script to copy them to www/.",
    "  #",
    "  #   logo_navbar.png  -- top-left of the navbar on every page",
    "  #   logo_welcome.png -- inline image in the welcome page (shinyplanr_1welcome1.md)",
    "  #   logo_funder.png  -- 'Funded by' section in the welcome page footer",
    "  #",
    "  # The option values are the SOURCE paths (in setup/logos/).",
    "  # This script copies them to www/ with the same filenames.",
    '  file_logo_navbar  = file.path(setup_dir, "logos", "logo_navbar.png"),',
    '  file_logo_welcome = file.path(setup_dir, "logos", "logo_welcome.png"),',
    '  file_logo_funder  = file.path(setup_dir, "logos", "logo_funder.png"),',
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
    "  ## Optional tabs",
    "  include_ess     = FALSE,  # Ecosystem Services tab - set TRUE if Dict contains EcosystemServices rows",
    "  include_explore = TRUE,  # Explore tab",
    "  include_log     = TRUE,  # Log tab",
    "",
    "  ## Bioregion stratification",
    "  include_bioregion = FALSE,",
    "",
    "  ## Second funder logo in welcome footer (optional)",
    "  # The default is the UQ logo (shinyplanr was developed at UQ).",
    "  # Replace setup/logos/uq-logo-white.png with your own image and update",
    "  # the path below, or comment out file_logo_funder2 to show only one",
    "  # funder logo.",
    '  file_logo_funder2 = file.path(setup_dir, "logos", "uq-logo-white.png"),',
    '  funder2_url       = "https://spatialplanning.github.io",',
    "",
    "  ## Institution text in welcome footer",
    '  # institution_text = "This application was developed by researchers at My Institution."',
    "  # Leave commented out to use the default UQ text."
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
    "  #",
    "  # 'min_set'       (default) -- finds the smallest-cost set of planning units",
    "  #                  that meets ALL targets. Use this for most analyses.",
    "  #",
    "  # 'min_shortfall' -- finds the set of planning units that minimises the",
    "  #                  overall shortfall across features while staying within a",
    "  #                  fixed budget (set as a % of the total cost layer).",
    "  #                  Only use this when you have a hard budget constraint.",
    '  obj_func = "min_set",  # "min_set" or "min_shortfall"',
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
    "# Maps each option key to its fixed destination filename in www/.",
    "# The filenames in www/ are what the running app loads - do not change them.",
    "logo_map <- list(",
    '  file_logo_navbar  = "logo_navbar.png",',
    '  file_logo_welcome = "logo_welcome.png",',
    '  file_logo_funder  = "logo_funder.png",',
    '  file_logo_funder2 = "logo_funder2.png"',
    ")",
    "",
    "for (opt_name in names(logo_map)) {",
    "  src <- shinyplanr_options[[opt_name]]",
    "  dst <- file.path(\"www\", logo_map[[opt_name]])",
    "  if (!is.null(src) && file.exists(src)) {",
    "    file.copy(src, dst, overwrite = TRUE)",
    "    message(\"Copied logo: \", basename(src), \" -> \", dst)",
    "  } else if (!is.null(src)) {",
    "    message(\"Logo not found (skipping): \", src)",
    "  }",
    "}",
    "",
    "# Derive show_logo_funder2: TRUE only if the file was successfully copied.",
    "# This is set automatically - do not set it manually in shinyplanr_options.",
    "shinyplanr_options$show_logo_funder2 <- file.exists(file.path(\"www\", \"logo_funder2.png\"))",
    "",
    "# Copy custom CSS override if present (overrides package default styling)",
    "# Edit setup/content/custom.css to change colours, fonts, etc.",
    "custom_css_src <- file.path(setup_dir, \"content\", \"custom.css\")",
    "if (!file.exists(custom_css_src)) custom_css_src <- file.path(setup_dir, \"custom.css\")",
    "if (file.exists(custom_css_src)) {",
    "  file.copy(custom_css_src, file.path(\"www\", \"custom.css\"), overwrite = TRUE)",
    "  message(\"Copied: www/custom.css\")",
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
    "load(shinyplanr_options$file_data)",
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
    "  sf::st_set_geometry(sf::st_geometry(dat_sf))",
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
    'tx_1footer_path <- file.path(content_dir, "shinyplanr_1footer.md")',
    'tx_1footer <- if (file.exists(tx_1footer_path)) readr::read_file(tx_1footer_path) else ""',
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
    "# =============================================================================",
    "# SIDEBAR (pre-computed slider/checkbox metadata)",
    "# =============================================================================",
    "#",
    "# These are computed once here so that mod_2scenario and mod_3compare do not",
    "# need to recompute them on every UI render and every server init.",
    "# The module IDs must match those used in app_ui.R / app_server.R.",
    "",
    "sidebar <- list(",
    "  scenario = list(",
    '    slider_vars     = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",',
    "                                                categoryOut = TRUE, byCategory = FALSE),",
    '    slider_varsBioR = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",',
    "                                                categoryOut = TRUE, byCategory = TRUE,",
    '                                                dataType = "Bioregion"),',
    '    slider_varsCat  = shinyplanr:::fcreate_vars("2scenario_ui_1", Dict, "sli_",',
    "                                                categoryOut = TRUE, byCategory = TRUE),",
    '    check_lockIn    = shinyplanr:::fcreate_check("2scenario_ui_1", Dict, "LockIn",',
    '                                                 "checkLI_", categoryOut = TRUE),',
    '    check_lockOut   = shinyplanr:::fcreate_check("2scenario_ui_1", Dict, "LockOut",',
    '                                                 "checkLO_", categoryOut = TRUE)',
    "  ),",
    "  compare = list(",
    '    Vars            = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli_",',
    "                                               categoryOut = TRUE),",
    '    Vars2           = shinyplanr:::fcreate_vars("3compare_ui_1", Dict, "sli2_",',
    "                                               categoryOut = TRUE),",
    '    check_lockIn    = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockIn",',
    '                                                 "check1LI_", categoryOut = TRUE),',
    '    check_lockIn2   = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockIn",',
    '                                                 "check2LI_", categoryOut = TRUE),',
    '    check_lockOut   = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockOut",',
    '                                                 "check1LO_", categoryOut = TRUE),',
    '    check_lockOut2  = shinyplanr:::fcreate_check("3compare_ui_1", Dict, "LockOut",',
    '                                                 "check2LO_", categoryOut = TRUE)',
    "  )",
    ")",
    "",
    "config_list <- list(",
    "  schema_version = shinyplanr::get_schema_version(),",
    "  options        = shinyplanr_options,",
    "  map_theme      = map_theme,",
    "  bar_theme      = bar_theme,",
    "  Dict           = Dict,",
    "  raw_sf         = raw_sf,",
    "  bndry          = bndry,",
    "  overlay        = overlay,",
    "  sidebar        = sidebar,",
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
    "",
    "# =============================================================================",
    "# CLEAN UP AND RESTART",
    "# =============================================================================",
    "#",
    "# The setup scripts leave large objects (dat_sf, raw_sf, shinyplanr_options,",
    "# etc.) in the global environment. Running the app in the same R session",
    "# without clearing these can cause hard-to-diagnose crashes because some",
    "# names shadow base R functions (e.g. a variable named 'options' would shadow",
    "# base::options()). We therefore restart R (in RStudio/Positron) or remove",
    "# the known problematic objects (in other environments) before opening app.R.",
    "",
    "if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {",
    "  # RStudio / Positron: restart the session cleanly, then open app.R.",
    "  # The .Rprofile hook (if renv is active) will re-activate the project",
    "  # automatically after the restart.",
    "  message('\\nRestarting R session to clear setup objects before running the app...')",
    "  message('app.R will open automatically after the restart.')",
    "  rstudioapi::restartSession(command = \"rstudioapi::navigateToFile('app.R')\")",
    "} else {",
    "  # Non-RStudio environment (e.g. VSCode, terminal): remove known objects",
    "  # that could shadow base R functions or consume unnecessary memory.",
    "  rm(list = intersect(",
    "    ls(),",
    "    c('shinyplanr_options', 'config_list', 'dat_sf', 'raw_sf', 'bndry',",
    "      'coast', 'overlay', 'Dict', 'vars', 'sidebar', 'tx', 'map_theme',",
    "      'bar_theme', 'tx_1footer', 'tx_2solution', 'tx_2targets', 'tx_2cost',",
    "      'tx_2climate', 'tx_2ess', 'tx_6faq', 'tx_6technical', 'tx_6changelog',",
    "      'zero_cols', 'logo_map', 'opt_name', 'src', 'dst', 'custom_css_src',",
    "      'content_dir', 'tx_1footer_path', 'country', 'setup_dir', 'data_path')",
    "  ))",
    "  message('\\nSetup objects removed from global environment.')",
    "  message('Open app.R and run shiny::runApp() to test the app.')",
    "}",
    ""
  )

  file_path <- file.path(setup_dir, "3_setup_app.R")
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
      "Abyssal Hills,abyssal_hills,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Small elevations on the abyssal plain.",
      "Abyssal Plains,abyssal_plains,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat areas of the deep ocean floor.",
      "Bridges,bridges,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Seafloor features connecting elevated areas.",
      "Canyons (Blind),canyons_blind,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that do not incise the continental shelf.",
      "Canyons (Shelf-incising),canyons_shelf_incising,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that cut into the continental shelf.",
      "Escarpments,escarpments,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Long cliff-like features on the seafloor.",
      "Guyots,guyots,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat-topped seamounts (tablemounts).",
      "Large Basins,large_basins_of_seas_and_oceans,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Large enclosed or semi-enclosed depressions on the seafloor.",
      "Major Ocean Basins,major_ocean_basins,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,The main structural basins of the ocean floor.",
      "Plateaus,plateaus,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Flat elevated areas of the seafloor.",
      "Ridges,ridges,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Elongated elevated features on the seafloor.",
      "Rift Valleys,rift_valleys,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Linear depressions associated with tectonic spreading.",
      "Sills,sills,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Shallow ridges separating basins.",
      "Small Basins,small_basins_of_seas_and_oceans,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Smaller enclosed depressions on the seafloor.",
      "Spreading Ridges,spreading_ridges,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Mid-ocean ridges where new seafloor is created.",
      "Terraces,terraces,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Step-like features on the seafloor.",
      "Trenches,trenches,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Deep linear depressions at subduction zones.",
      "Troughs,troughs,Geomorphology,GeoMorph,Feature,30,0,85,TRUE,TRUE,,Long narrow depressions on the seafloor.",
      "Shelf Basins (Perched),basins_perched_on_the_shelf,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental shelf.",
      "Slope Basins (Perched),basins_perched_on_the_slope,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental slope.",
      "Fans,fans,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Submarine fan deposits at canyon mouths.",
      "Glacial Troughs,glacial_troughs,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,U-shaped valleys carved by glaciers.",
      "Large Shelf Valleys,large_shelf_valleys_and_glacial_troughs,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Major valleys crossing the continental shelf.",
      "Moderate Shelf Valleys,moderate_size_shelf_valley,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Medium-sized valleys on the continental shelf.",
      "Rises,rises,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Gradual elevations of the seafloor.",
      "Small Shelf Valleys,small_shelf_valley,Geomorphology,GeoMorph,Feature,30,0,85,FALSE,TRUE,,Minor valleys on the continental shelf.",
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
      "Equal Area Cost,cost_area,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,All planning units have equal cost based on their area.",
      "Distance to Coast,cost_distance,Cost,Cost,Cost,NA,NA,NA,TRUE,TRUE,,Cost based on distance from the coast."
    )
  }

  if (include_mpas) {
    dict_rows <- c(dict_rows,
      "Marine Protected Areas,mpas,Protected Areas,MPAs,LockIn,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas.",
      "Marine Protected Areas,mpas,Protected Areas,MPAs,LockOut,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas."
    )
  }

  file_path <- file.path(setup_dir, "Dict_Feature.csv")
  writeLines(dict_rows, file_path)
  message("Created: ", file_path)
}


# ---- Custom CSS template writer ----------------------------------------------

.write_custom_css <- function(setup_dir) {
  template_path <- system.file("templates", "custom.css", package = "shinyplanr")
  if (template_path == "") {
    template_path <- file.path("inst", "templates", "custom.css")
  }

  content_dir <- file.path(setup_dir, "content")
  dst_file    <- file.path(content_dir, "custom.css")

  if (file.exists(template_path)) {
    file.copy(template_path, dst_file, overwrite = FALSE)
    message("Created: ", dst_file)
  } else {
    message("Warning: custom.css template not found; skipping.")
  }
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


# ---- Logos README writer -----------------------------------------------------

.write_logos_readme <- function(logos_dir) {
  content <- c(
    "# setup/logos/",
    "",
    "Place your logo image files here, then re-run `setup/3_setup_app.R` to",
    "copy them to `www/` where the running app can load them.",
    "",
    "## Logo slots",
    "",
    "| File in setup/logos/ | Where it appears in the app | Notes |",
    "|----------------------|----------------------------|-------|",
    "| `logo_navbar.png`     | Top-left of the navbar on every page | Recommended height: 40 px; white/transparent background works best |",
    "| `logo_welcome.png`    | Inline image in the welcome page (`shinyplanr_1welcome1.md`) | Embedded as `<img src=\"www/logo_welcome.png\">` - edit that file to resize or remove |",
    "| `logo_funder.png`     | Primary logo in the welcome page footer \"Funded by\" section | Links to `funder_url` in `3_setup_app.R` |",
    "| `uq-logo-white.png`   | Optional second logo in the welcome page footer | Default is the UQ logo. To use a different image, replace this file and update `file_logo_funder2` in `3_setup_app.R`. To hide it entirely, comment out `file_logo_funder2`. |",
    "",
    "## How to customise",
    "",
    "1. Replace any placeholder image with your own `.png` file.",
    "2. Update the corresponding path in `setup/3_setup_app.R` if you use a",
    "   different filename.",
    "3. To hide the second funder logo, comment out `file_logo_funder2` in",
    "   `setup/3_setup_app.R`.",
    "4. Re-run `setup/3_setup_app.R` to copy updated logos to `www/`.",
    "",
    "## Image format",
    "",
    "PNG is recommended. SVG is not supported by all browsers in `<img>` tags.",
    "White or transparent backgrounds work best on the dark navbar.",
    "",
    "## The welcome page image",
    "",
    "The `logo_welcome.png` image is embedded directly in",
    "`setup/content/shinyplanr_1welcome1.md` as:",
    "",
    "```html",
    "<img src=\"www/logo_welcome.png\" style=\"width:25%;float:right\">",
    "```",
    "",
    "Edit that file to change the size, position, or remove the image entirely."
  )

  dst_file <- file.path(logos_dir, "README.md")
  writeLines(content, dst_file)
  message("Created: ", dst_file)
}
