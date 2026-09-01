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
  if (!is.logical(use_renv)) stop("'use_renv' must be TRUE or FALSE.")

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

  navbar_logo <- system.file("app", "www", "logo_navbar.png", package = "shinyplanr")
  if (navbar_logo == "") {
    navbar_logo <- file.path("inst", "app", "www", "logo_navbar.png")
  }
  if (file.exists(navbar_logo)) {
    file.copy(navbar_logo, file.path(logos_dir, "logo_navbar.png"), overwrite = FALSE)
    message("Copied default navbar logo to: ", logos_dir)
  }

  welcome_logo <- system.file("app", "www", "logo_welcome.png", package = "shinyplanr")
  if (welcome_logo == "") {
    welcome_logo <- file.path("inst", "app", "www", "logo_welcome.png")
  }
  if (file.exists(welcome_logo)) {
    file.copy(welcome_logo, file.path(logos_dir, "logo_welcome.png"), overwrite = FALSE)
    message("Copied default welcome logo to: ", logos_dir)
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

  favicon <- system.file("app", "www", "favicon.png", package = "shinyplanr")
  if (favicon == "") {
    favicon <- file.path("inst", "app", "www", "favicon.png")
  }
  if (file.exists(favicon)) {
    file.copy(favicon, file.path(logos_dir, "favicon.png"), overwrite = FALSE)
    message("Copied default favicon to: ", logos_dir)
  }

  # Generate files
  .write_setup_enviro(setup_dir, oceandatr)
  .write_setup_data(
    setup_dir, country, crs, oceandatr, resolution,
    include_climate, include_cost, include_mpas
  )
  .write_setup_app(setup_dir, country, crs, include_climate)
  .write_dict_feature(setup_dir, oceandatr, include_cost, include_mpas)
  .write_packages_extra(setup_dir)
  .write_content_templates(setup_dir, country)
  .write_custom_css(setup_dir)
  .write_logos_readme(logos_dir)
  .write_app_r(output_dir, country)
  .write_deploy_r(output_dir, country)
  .write_root_renvignore(output_dir)
  .write_setup_renvignore(setup_dir)

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
  if (isTRUE(create_rproj)) {
    message("  \u251c\u2500\u2500 ", country, ".Rproj   \u2190 open this in RStudio")
  }
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

  # When use_renv = TRUE, renv::init() calls rstudioapi::openProject() itself
  # at the end of initialisation, switching RStudio to the new project
  # automatically. No further action is needed here.
  #
  # When use_renv = FALSE (or renv is not installed), we open the project
  # ourselves so the user lands in the new project immediately.
  if (isTRUE(create_rproj) &&
    !isTRUE(use_renv) &&
    !isTRUE(getOption("shinyplanr.testing", FALSE)) &&
    identical(Sys.getenv("TESTTHAT"), "") &&
    requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::isAvailable()) {
    rproj_path <- normalizePath(
      file.path(output_dir, paste0(country, ".Rproj")),
      mustWork = FALSE
    )
    message("Switching to ", country, ".Rproj in RStudio...")
    message("(If prompted 'Save workspace?', click 'Don't Save')")
    rstudioapi::openProject(rproj_path)
  } else if (!isTRUE(create_rproj)) {
    rproj_path <- normalizePath(output_dir)
    message("Next steps:")
    message("1. Open the project folder: ", rproj_path)
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
  } else if (!isTRUE(use_renv)) {
    rproj_path <- normalizePath(
      file.path(output_dir, paste0(country, ".Rproj")),
      mustWork = FALSE
    )
    message("Next steps:")
    message("1. Open the project:")
    message("   File > Open Project > ", rproj_path)
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
  # use_renv = TRUE: renv::init() has already called openProject() and
  # switched to the new project. R is restarting — no further messages needed.

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
      "# =============================================================================",
      "# FIRST TIME SETUP",
      "# =============================================================================",
      "#   1. Create an API key at: https://connect.posit.cloud/connect/#!/api-keys",
      "#   2. Run:",
      "#      rsconnect::setAccountInfo(name='<name>', token='<token>', secret='<secret>')",
      "#",
      "# =============================================================================",
      "# NORMAL DEPLOYMENT (no shinyplanr upgrade)",
      "# =============================================================================",
      "#   1. Re-run setup/3_setup_app.R  (regenerates config/shinyplanr_config.rds)",
      "#   2. source('deploy.R')",
      "#",
      "# =============================================================================",
      "# UPGRADING shinyplanr",
      "# =============================================================================",
      "#",
      "# Step 1 -- Install the new shinyplanr into the renv library:",
      "#",
      "#   renv::install('SpatialPlanning/shinyplanr@HEAD', prompt = FALSE)",
      "#",
      "#   IMPORTANT: Restart R after this step so the new version is loaded.",
      "#   (Session > Restart R, or Ctrl/Cmd+Shift+F10 in RStudio)",
      "#",
      "# Step 2 -- Refresh safe-to-overwrite template files:",
      "#",
      "#   shinyplanr::update_shinyplanr_template()",
      "#",
      "# Step 3 -- Reinstall all packages at new versions and lock renv.lock:",
      "#",
      "#   source('setup/1_setup_enviro.R')   # re-installs at HEAD + your extras",
      "#                                      # renv::snapshot() is called at the end",
      "#",
      "# Step 4 -- Check if 3_setup_app.R needs manual updates:",
      "#",
      "#   shinyplanr::schema_changelog()     # prints what changed between versions",
      "#   # Update setup/3_setup_app.R manually if needed.",
      "#   # DO NOT overwrite it -- it contains your customisations.",
      "#",
      "# Step 5 -- Regenerate the config and redeploy:",
      "#",
      "#   source('setup/3_setup_app.R')",
      "#   source('deploy.R')",
      "#",
      "# =============================================================================",
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


# Writes a root-level .renvignore to exclude deploy.R from renv's dependency
# scan. deploy.R calls rsconnect::deployApp(), which would otherwise cause
# rsconnect to be captured in renv.lock. rsconnect is a local deployment tool
# and is not needed on Posit Connect.
.write_root_renvignore <- function(output_dir) {
  content <- c(
    "# Exclude deployment script from renv dependency scanning.",
    "# deploy.R calls rsconnect::deployApp() which is a local tool,",
    "# not a runtime dependency of the app. Excluding it prevents rsconnect",
    "# from being captured in renv.lock.",
    "deploy.R"
  )
  file_path <- file.path(output_dir, ".renvignore")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# Writes setup/.renvignore to exclude the entire setup/ directory from renv's
# dependency scan. The setup/ scripts reference data-preparation packages
# (oceandatr, spatialgridr, rnaturalearth, gitcreds, rstudioapi, etc.) that
# are local tooling only — they are not runtime dependencies of the deployed
# Shiny app. Without this file, renv::snapshot() would capture all of them in
# renv.lock, causing Posit Connect to install unnecessary packages.
#
# The wildcard '*' excludes all files in setup/ regardless of what the
# deployer adds later, which is correct: the entire directory is tooling.
.write_setup_renvignore <- function(setup_dir) {
  content <- c(
    "# Exclude all setup/ scripts from renv dependency scanning.",
    "# These scripts are local data-preparation tooling and are not",
    "# runtime dependencies of the deployed Shiny app.",
    "*"
  )
  file_path <- file.path(setup_dir, ".renvignore")
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
      #
      # renv::init() calls rstudioapi::openProject() at the end of
      # initialisation (via renv_restart_request), which switches RStudio to
      # the new project. This is the correct behaviour — the user lands in the
      # new project automatically and can then open 1_setup_enviro.R.
      renv::init(bare = TRUE)

      # Prepend global .Renviron loading so user-level env vars (e.g.
      # GITHUB_PAT) are available inside the isolated renv session.
      # renv's .Rprofile only sources renv/activate.R; without this line
      # the GitHub PAT stored in ~/.Renviron is invisible to renv::install().
      #
      # Note: renv::init() calls openProject() which restarts R, so this code
      # only runs in non-RStudio environments (e.g. terminal / CI) where
      # renv falls back to a simple restartR rather than openProject.
      # In those cases the .Rprofile edit is still useful for subsequent runs.
      rprofile_path <- file.path(proj, ".Rprofile")
      if (file.exists(rprofile_path)) {
        existing_rp <- readLines(rprofile_path, warn = FALSE)
        writeLines(
          c(
            "# Load global ~/.Renviron so GITHUB_PAT and other user env vars are",
            "# available inside the renv project session (added by shinyplanr).",
            'if (file.exists("~/.Renviron")) readRenviron("~/.Renviron")',
            "",
            existing_rp
          ),
          rprofile_path
        )
      }

      message(
        "\nrenv infrastructure created. Open ", basename(proj),
        ".Rproj and run setup/1_setup_enviro.R to install packages."
      )
    }),
    error = function(e) {
      message(
        "\nCould not initialise renv: ", e$message,
        "\nYou can initialise it manually: renv::init(bare = TRUE)"
      )
    }
  )
}


# ---- Template processing helper ----------------------------------------------

# Process a template .R file from inst/templates/setup/.
#
# Reads the file, applies conditional block filtering, then applies token
# substitution. Returns a character vector of lines ready for writeLines().
#
# Conditional blocks use comment markers:
#
#   # [IF condition_name]
#   ... lines included only when conditions[[condition_name]] is TRUE ...
#   # [END condition_name]
#
# The marker lines themselves are always removed from the output.
# Nesting is not supported and will raise an error.
#
# Token substitution replaces {placeholder} with the corresponding value from
# the `substitutions` named list. Substitution is applied after block
# filtering, so tokens inside a FALSE block are never substituted.
#
# @param template_path Character. Full path to the template file.
# @param conditions Named logical list. Names must match all [IF ...] markers
#   in the template. Unknown condition names in the template raise an error.
# @param substitutions Named character list. {name} tokens in the filtered
#   lines are replaced with the corresponding value.
# @return Character vector of processed lines.
.process_template <- function(template_path, conditions = list(),
                              substitutions = list()) {
  if (!file.exists(template_path)) {
    stop(
      "Template file not found: ", template_path,
      call. = FALSE
    )
  }

  lines <- readLines(template_path, warn = FALSE)

  # ---- Validate [IF]/[END] structure -----------------------------------------
  # Collect all marker lines and check for structural problems before filtering.

  if_pattern  <- "^\\s*#\\s*\\[IF\\s+(\\w+)\\]\\s*$"
  end_pattern <- "^\\s*#\\s*\\[END\\s+(\\w+)\\]\\s*$"

  open_stack <- character(0)  # tracks currently-open condition names

  for (i in seq_along(lines)) {
    line <- lines[[i]]

    if_match  <- regmatches(line, regexpr(if_pattern,  line, perl = TRUE))
    end_match <- regmatches(line, regexpr(end_pattern, line, perl = TRUE))

    if (length(if_match) > 0) {
      cond_name <- sub(if_pattern, "\\1", if_match, perl = TRUE)

      # Nesting check
      if (length(open_stack) > 0) {
        stop(
          "Nested [IF] blocks are not supported in template: ",
          basename(template_path),
          "\n  Line ", i, ": ", trimws(line),
          "\n  Already inside [IF ", open_stack[length(open_stack)], "]",
          call. = FALSE
        )
      }

      # Unknown condition check
      if (!cond_name %in% names(conditions)) {
        stop(
          "Unknown condition '", cond_name, "' in template: ",
          basename(template_path),
          "\n  Line ", i, ": ", trimws(line),
          "\n  Known conditions: ",
          if (length(conditions) == 0) "(none)" else paste(names(conditions), collapse = ", "),
          call. = FALSE
        )
      }

      open_stack <- c(open_stack, cond_name)

    } else if (length(end_match) > 0) {
      cond_name <- sub(end_pattern, "\\1", end_match, perl = TRUE)

      if (length(open_stack) == 0 || open_stack[length(open_stack)] != cond_name) {
        stop(
          "[END ", cond_name, "] without matching [IF ", cond_name, "] in template: ",
          basename(template_path),
          "\n  Line ", i, ": ", trimws(line),
          call. = FALSE
        )
      }

      open_stack <- open_stack[-length(open_stack)]
    }
  }

  if (length(open_stack) > 0) {
    stop(
      "Unclosed [IF ", open_stack[length(open_stack)], "] in template: ",
      basename(template_path),
      call. = FALSE
    )
  }

  # ---- Filter conditional blocks ---------------------------------------------

  out_lines  <- character(0)
  in_block   <- FALSE
  keep_block <- TRUE

  for (line in lines) {
    if_match  <- regmatches(line, regexpr(if_pattern,  line, perl = TRUE))
    end_match <- regmatches(line, regexpr(end_pattern, line, perl = TRUE))

    if (length(if_match) > 0) {
      cond_name  <- sub(if_pattern, "\\1", if_match, perl = TRUE)
      in_block   <- TRUE
      keep_block <- isTRUE(conditions[[cond_name]])
      next
    }

    if (length(end_match) > 0) {
      in_block   <- FALSE
      keep_block <- TRUE
      next
    }

    if (!in_block || keep_block) {
      out_lines <- c(out_lines, line)
    }
  }

  # ---- Apply token substitutions ---------------------------------------------

  for (token_name in names(substitutions)) {
    pattern     <- paste0("\\{", token_name, "\\}")
    replacement <- as.character(substitutions[[token_name]])
    out_lines   <- gsub(pattern, replacement, out_lines, perl = TRUE)
  }

  out_lines
}


# ---- 1_setup_enviro.R writer -------------------------------------------------

.write_setup_enviro <- function(setup_dir, oceandatr = TRUE) {
  template_path <- system.file(
    "templates", "setup", "1_setup_enviro.R",
    package = "shinyplanr"
  )
  if (template_path == "") {
    template_path <- file.path("inst", "templates", "setup", "1_setup_enviro.R")
  }

  content <- .process_template(
    template_path,
    conditions    = list(oceandatr = isTRUE(oceandatr)),
    substitutions = list(date = Sys.Date())
  )

  file_path <- file.path(setup_dir, "1_setup_enviro.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- 2_setup_data.R writer ---------------------------------------------------

.write_setup_data <- function(setup_dir, country, crs, oceandatr, resolution,
                              include_climate, include_cost, include_mpas) {
  template_path <- system.file(
    "templates", "setup", "2_setup_data.R",
    package = "shinyplanr"
  )
  if (template_path == "") {
    template_path <- file.path("inst", "templates", "setup", "2_setup_data.R")
  }

  content <- .process_template(
    template_path,
    conditions = list(
      oceandatr       = isTRUE(oceandatr),
      manual          = !isTRUE(oceandatr),
      include_cost    = isTRUE(include_cost),
      include_mpas    = isTRUE(include_mpas),
      include_climate = isTRUE(include_climate)
    ),
    substitutions = list(
      country    = country,
      crs        = crs,
      resolution = resolution,
      date       = Sys.Date()
    )
  )

  file_path <- file.path(setup_dir, "2_setup_data.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- 3_setup_app.R writer ----------------------------------------------------

.write_setup_app <- function(setup_dir, country, crs, include_climate) {
  template_path <- system.file(
    "templates", "setup", "3_setup_app.R",
    package = "shinyplanr"
  )
  if (template_path == "") {
    template_path <- file.path("inst", "templates", "setup", "3_setup_app.R")
  }

  content <- .process_template(
    template_path,
    conditions    = list(include_climate = isTRUE(include_climate)),
    substitutions = list(
      country = country,
      crs     = crs,
      date    = Sys.Date()
    )
  )

  file_path <- file.path(setup_dir, "3_setup_app.R")
  writeLines(content, file_path)
  message("Created: ", file_path)
}


# ---- Dict_Feature.csv writer -------------------------------------------------

.write_dict_feature <- function(setup_dir, oceandatr, include_cost, include_mpas) {
  # NOTE on `categoryOrder` (optional column):
  # Controls the display order of categories in the sidebar sliders and
  # dropdowns, WITHIN a given `type` (see shinyplanr:::forder_dict_categories()
  # and vignette("ac-setting-up")). It must be numeric and identical across
  # every row that shares the same (type, category) -- like `categoryID`,
  # it is a category-level attribute, not a per-row one.
  #
  # Without it, categories fall back to alphabetical-by-categoryID order,
  # which for this template would show them as: Corals, Depth, EnviroZone,
  # GeoMorph, Knolls, Seamt -- not the more natural depth-to-shallow /
  # geomorphology-grouped sequence used below.
  if (oceandatr) {
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,categoryOrder,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",
      "Continental Shelf (0-200m),continental_shelf,Depth Zones,Depth,1,Feature,30,0,85,TRUE,TRUE,,The shallow ocean zone from the coast to 200m depth.",
      "Upper Bathyal (200-800m),upper_bathyal,Depth Zones,Depth,1,Feature,30,0,85,TRUE,TRUE,,The upper slope zone from 200-800m depth.",
      "Lower Bathyal (800-3500m),lower_bathyal,Depth Zones,Depth,1,Feature,30,0,85,TRUE,TRUE,,The lower slope zone from 800-3500m depth.",
      "Abyssal (3500-6500m),abyssal,Depth Zones,Depth,1,Feature,30,0,85,TRUE,TRUE,,The abyssal zone found on abyssal plains from 3500-6500m.",
      "Hadal (>6500m),hadal,Depth Zones,Depth,1,Feature,30,0,85,FALSE,TRUE,,The deepest ocean zone found in trenches below 6500m.",
      "Abyssal Hills,abyssal_hills,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Small elevations on the abyssal plain.",
      "Abyssal Plains,abyssal_plains,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Flat areas of the deep ocean floor.",
      "Bridges,bridges,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Seafloor features connecting elevated areas.",
      "Canyons (Blind),canyons_blind,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that do not incise the continental shelf.",
      "Canyons (Shelf-incising),canyons_shelf_incising,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Submarine canyons that cut into the continental shelf.",
      "Escarpments,escarpments,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Long cliff-like features on the seafloor.",
      "Guyots,guyots,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Flat-topped seamounts (tablemounts).",
      "Large Basins,large_basins_of_seas_and_oceans,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Large enclosed or semi-enclosed depressions on the seafloor.",
      "Major Ocean Basins,major_ocean_basins,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,The main structural basins of the ocean floor.",
      "Plateaus,plateaus,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Flat elevated areas of the seafloor.",
      "Ridges,ridges,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Elongated elevated features on the seafloor.",
      "Rift Valleys,rift_valleys,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Linear depressions associated with tectonic spreading.",
      "Sills,sills,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Shallow ridges separating basins.",
      "Small Basins,small_basins_of_seas_and_oceans,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Smaller enclosed depressions on the seafloor.",
      "Spreading Ridges,spreading_ridges,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Mid-ocean ridges where new seafloor is created.",
      "Terraces,terraces,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Step-like features on the seafloor.",
      "Trenches,trenches,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Deep linear depressions at subduction zones.",
      "Troughs,troughs,Geomorphology,GeoMorph,2,Feature,30,0,85,TRUE,TRUE,,Long narrow depressions on the seafloor.",
      "Shelf Basins (Perched),basins_perched_on_the_shelf,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental shelf.",
      "Slope Basins (Perched),basins_perched_on_the_slope,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Basins located on the continental slope.",
      "Fans,fans,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Submarine fan deposits at canyon mouths.",
      "Glacial Troughs,glacial_troughs,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,U-shaped valleys carved by glaciers.",
      "Large Shelf Valleys,large_shelf_valleys_and_glacial_troughs,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Major valleys crossing the continental shelf.",
      "Moderate Shelf Valleys,moderate_size_shelf_valley,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Medium-sized valleys on the continental shelf.",
      "Rises,rises,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Gradual elevations of the seafloor.",
      "Small Shelf Valleys,small_shelf_valley,Geomorphology,GeoMorph,2,Feature,30,0,85,FALSE,TRUE,,Minor valleys on the continental shelf.",
      "Seamounts,seamounts,Seamounts,Seamounts,3,Feature,30,0,85,TRUE,TRUE,,Underwater mountains rising >1000m from the seafloor.",
      "Knolls,knolls,Knolls,Knolls,4,Feature,30,0,85,TRUE,TRUE,,Smaller underwater hills rising 500-1000m from the seafloor.",
      "Environmental Zone 1,enviro_zone_1,Environmental Zones,EnviroZone,5,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 2,enviro_zone_2,Environmental Zones,EnviroZone,5,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Environmental Zone 3,enviro_zone_3,Environmental Zones,EnviroZone,5,Feature,30,0,85,TRUE,TRUE,,Data-driven environmental classification zone.",
      "Antipatharia (Black Coral),antipatharia,Deep-sea Corals,Corals,6,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for black corals.",
      "Cold-water Corals,cold_corals,Deep-sea Corals,Corals,6,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for cold-water corals.",
      "Octocorals,octocorals,Deep-sea Corals,Corals,6,Feature,30,0,85,TRUE,TRUE,,Predicted habitat suitability for soft corals."
    )
  } else {
    dict_rows <- c(
      "nameCommon,nameVariable,category,categoryID,categoryOrder,type,targetInitial,targetMin,targetMax,includeApp,includeJust,units,justification",
      "# TODO: Add your feature rows here",
      "# Example Feature,example_feature,Habitat,Habitat,1,Feature,30,0,85,TRUE,TRUE,,Description of this feature."
    )
  }

  if (include_cost) {
    dict_rows <- c(
      dict_rows,
      "Equal Area Cost,cost_area,Cost,Cost,1,Cost,NA,NA,NA,TRUE,TRUE,,All planning units have equal cost based on their area.",
      "Distance to Coast,cost_distance,Cost,Cost,1,Cost,NA,NA,NA,TRUE,TRUE,,Cost based on distance from the coast."
    )
  }

  if (include_mpas) {
    dict_rows <- c(
      dict_rows,
      "Marine Protected Areas,mpas,Protected Areas,MPAs,1,LockIn,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas.",
      "Marine Protected Areas,mpas,Protected Areas,MPAs,1,LockOut,NA,NA,NA,TRUE,TRUE,,Existing MPAs from the World Database on Protected Areas."
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
  dst_file <- file.path(content_dir, "custom.css")

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
    "| `favicon.png`         | Browser tab icon | Recommended size: 32x32 px PNG. Replace with your own icon and re-run `3_setup_app.R`. |",
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


# ---- packages_extra.R writer -------------------------------------------------

# Writes setup/packages_extra.R — a user-owned file for additional package
# installs. It is created ONCE by create_shinyplanr_template() and is NEVER
# overwritten by update_shinyplanr_template(). The user adds their own
# renv::install() calls here; 1_setup_enviro.R sources it automatically.
.write_packages_extra <- function(setup_dir) {
  file_path <- file.path(setup_dir, "packages_extra.R")

  # Never overwrite — this file belongs to the user.
  if (file.exists(file_path)) {
    return(invisible(file_path))
  }

  content <- c(
    "# setup/packages_extra.R",
    "# Add any additional packages your project needs beyond the shinyplanr defaults.",
    "#",
    "# This file is sourced automatically by setup/1_setup_enviro.R (Step 4b).",
    "# It is NEVER overwritten when you run shinyplanr::update_shinyplanr_template().",
    "#",
    "# Add renv::install() calls below, one per line. Examples:",
    "#",
    "#   renv::install('ggforce', prompt = FALSE)",
    "#   renv::install('MyOrg/mypackage@HEAD', prompt = FALSE)",
    "#",
    "# Leave this file empty (or commented out) if you have no extra packages.",
    ""
  )

  writeLines(content, file_path)
  message("Created: ", file_path)
  invisible(file_path)
}


# ---- update_shinyplanr_template() --------------------------------------------

#' Update safe-to-overwrite files in an existing shinyplanr deployment project
#'
#' Refreshes the files in a deployment project that are safe to overwrite
#' without losing any user customisations. Call this after upgrading the
#' shinyplanr package to pick up changes to the install script, app entry
#' point, deployment script, and any new content template files.
#'
#' @section What is updated:
#' \describe{
#'   \item{\code{setup/1_setup_enviro.R}}{Always overwritten. Contains the
#'     package install list, which changes when shinyplanr adds or removes
#'     dependencies. Any extra packages you need should be in
#'     \code{setup/packages_extra.R} (never overwritten).}
#'   \item{\code{app.R}}{Always overwritten. This is a 3-line thin wrapper
#'     that calls \code{load_config()} and \code{run_app()}. It should never
#'     need user edits.}
#'   \item{\code{deploy.R}}{Always overwritten. Contains deployment
#'     instructions and the \code{rsconnect::deployApp()} call. The
#'     \code{appName} is re-stamped from \code{country}.}
#'   \item{\code{setup/content/*.md}}{New template files only. Existing files
#'     are never overwritten, preserving your edited text content.}
#' }
#'
#' @section What is NEVER updated:
#' \describe{
#'   \item{\code{setup/2_setup_data.R}}{Your spatial data pipeline.}
#'   \item{\code{setup/3_setup_app.R}}{Your app configuration (options, Dict
#'     path, logos, module switches, CRS, etc.). If a shinyplanr upgrade
#'     changes the config schema, \code{load_config()} will print a changelog
#'     describing exactly what to add manually.}
#'   \item{\code{setup/Dict_Feature.csv}}{Your feature dictionary.}
#'   \item{\code{setup/packages_extra.R}}{Your additional package installs.}
#'   \item{\code{setup/logos/}}{Your logo image files.}
#'   \item{\code{setup/content/*.md} (existing)}{Your edited text content.}
#'   \item{\code{config/shinyplanr_config.rds}}{Regenerated by
#'     \code{3_setup_app.R}, not by this function.}
#' }
#'
#' @param project_dir Character. Path to the deployment project root (the
#'   directory containing \code{app.R} and the \code{setup/} folder).
#'   Defaults to the current working directory.
#' @param country Character. The country/region name used when the project was
#'   created. Used to re-stamp \code{deploy.R} with the correct
#'   \code{appName}. If \code{NULL} (default), the function attempts to infer
#'   it from the existing \code{deploy.R} file; if that fails it uses
#'   \code{"MyRegion"} and emits a warning.
#' @param oceandatr Logical. Whether the project uses oceandatr. Passed to
#'   \code{1_setup_enviro.R} to include the oceandatr/spatialgridr install
#'   lines. Defaults to \code{TRUE}.
#'
#' @return Invisibly returns the path to the project directory.
#'
#' @examples
#' \dontrun{
#' # From inside the deployment project (e.g. after opening Fiji.Rproj):
#' shinyplanr::update_shinyplanr_template()
#'
#' # From outside the project:
#' shinyplanr::update_shinyplanr_template(
#'   project_dir = "../shinyplanr_Fiji",
#'   country     = "Fiji"
#' )
#' }
#'
#' @export
update_shinyplanr_template <- function(
  project_dir = ".",
  country     = NULL,
  oceandatr   = TRUE
) {
  project_dir <- normalizePath(project_dir, mustWork = TRUE)
  setup_dir   <- file.path(project_dir, "setup")

  if (!dir.exists(setup_dir)) {
    stop(
      "No 'setup/' directory found in: ", project_dir, "\n",
      "Is this a shinyplanr deployment project created by ",
      "create_shinyplanr_template()?",
      call. = FALSE
    )
  }

  # Infer country from existing deploy.R if not supplied
  if (is.null(country)) {
    deploy_path <- file.path(project_dir, "deploy.R")
    country <- .infer_country_from_deploy(deploy_path)
  }

  message("Updating shinyplanr template files in: ", project_dir)
  message("  Country: ", country)
  message("")

  # ---- Files that are always overwritten -------------------------------------

  # 1_setup_enviro.R: package list changes with shinyplanr versions
  .write_setup_enviro(setup_dir, oceandatr)
  message("  [updated] setup/1_setup_enviro.R")

  # app.R: thin wrapper, should never need user edits
  .write_app_r(project_dir, country)
  message("  [updated] app.R")

  # deploy.R: updated instructions + re-stamped appName
  .write_deploy_r(project_dir, country)
  message("  [updated] deploy.R")

  # ---- New content template files only (overwrite = FALSE) -------------------

  content_dir    <- file.path(setup_dir, "content")
  template_dir   <- system.file("templates", "markdown", package = "shinyplanr")
  if (template_dir == "") template_dir <- file.path("inst", "templates", "markdown")

  template_files <- c(
    "shinyplanr_1welcome1.md", "shinyplanr_1welcome2.md",
    "shinyplanr_1welcome3.md", "shinyplanr_1welcome4.md",
    "shinyplanr_1welcome5.md", "shinyplanr_1footer.md",
    "shinyplanr_2solution.md", "shinyplanr_2targets.md",
    "shinyplanr_2cost.md",     "shinyplanr_2climate.md",
    "shinyplanr_2ecosystemServices.md",
    "shinyplanr_6faq.md",      "shinyplanr_6technical.md",
    "shinyplanr_6changelog.md"
  )

  new_files <- character(0)
  for (filename in template_files) {
    src <- file.path(template_dir, filename)
    dst <- file.path(content_dir, filename)
    if (!file.exists(dst) && file.exists(src)) {
      file.copy(src, dst, overwrite = FALSE)
      new_files <- c(new_files, filename)
    }
  }

  if (length(new_files) > 0) {
    message(
      "  [added]   setup/content/: ",
      paste(new_files, collapse = ", ")
    )
  } else {
    message("  [skipped] setup/content/: all template files already exist")
  }

  # ---- Files that are NEVER overwritten --------------------------------------
  message("")
  message("The following files were NOT changed (user-owned):")
  message("  setup/2_setup_data.R")
  message("  setup/3_setup_app.R")
  message("  setup/Dict_Feature.csv")
  message("  setup/packages_extra.R")
  message("  setup/logos/")
  message("  setup/content/*.md  (existing files)")
  message("  config/shinyplanr_config.rds")
  message("")
  message("Next steps:")
  message("  1. Source setup/1_setup_enviro.R")
  message("     Reinstalls shinyplanr and all dependencies at their new versions,")
  message("     then snapshots renv.lock automatically.")
  message("")
  message("  2. Source setup/3_setup_app.R")
  message("     Regenerates config/shinyplanr_config.rds.")
  message("     If this script errors, the new shinyplanr version may require")
  message("     changes to 3_setup_app.R (e.g. new config keys or options).")
  message("     Run shinyplanr::schema_changelog() to see what changed and")
  message("     what to add to your 3_setup_app.R.")
  message("")
  message("  3. Test locally: shiny::runApp()")
  message("")
  message("  4. Deploy: source('deploy.R')")

  invisible(project_dir)
}


# Attempt to infer the country name from an existing deploy.R file.
# Looks for the appName = "..." line written by .write_deploy_r().
# Returns "MyRegion" with a warning if inference fails.
.infer_country_from_deploy <- function(deploy_path) {
  if (!file.exists(deploy_path)) {
    warning(
      "Could not find deploy.R to infer country name. ",
      "Using 'MyRegion'. Pass country = '<YourCountry>' explicitly.",
      call. = FALSE
    )
    return("MyRegion")
  }

  lines <- readLines(deploy_path, warn = FALSE)
  # Match:  appName     = "Fiji",
  match <- regmatches(
    lines,
    regexpr('appName\\s*=\\s*"([^"]+)"', lines, perl = TRUE)
  )

  if (length(match) == 0) {
    warning(
      "Could not parse country name from deploy.R. ",
      "Using 'MyRegion'. Pass country = '<YourCountry>' explicitly.",
      call. = FALSE
    )
    return("MyRegion")
  }

  # Extract the capture group (the country name)
  country <- sub('appName\\s*=\\s*"([^"]+)"', "\\1", match[[1]], perl = TRUE)
  country
}
