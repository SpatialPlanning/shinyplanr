# setup/1_setup_enviro.R
# Step 1: Install all required packages and lock versions with renv.
# Generated: {date}
#
# Run this script ONCE after opening the project for the first time.
# Re-run if you add packages or upgrade shinyplanr.
#
# HOW TO RUN: Click 'Source' or run line-by-line.

# =============================================================================
# PRE-CHECK — Quarto CLI
# =============================================================================
#
# The app generates reports using Quarto. The 'quarto' R package (installed
# below) is a wrapper that calls the Quarto CLI binary. If the CLI is not
# installed, report generation will fail at runtime.
#
# Download Quarto CLI from: https://quarto.org/docs/get-started/
#
if (!nzchar(Sys.which('quarto'))) {
  warning(
    '\n[ACTION REQUIRED] Quarto CLI not found on PATH.',
    '\nThe app uses Quarto to generate reports.',
    '\nDownload and install it from: https://quarto.org/docs/get-started/',
    '\nThen restart R and re-run this script.',
    '\n(You can continue without Quarto, but report generation will fail.)',
    call. = FALSE
  )
} else {
  message('Quarto CLI found: v', system('quarto --version', intern = TRUE))
}

# =============================================================================
# STEP 0 — GitHub Credentials
# =============================================================================
#
# Several packages are installed from GitHub. renv contacts the GitHub API
# for each one. Without authentication, requests are rate-limited to
# 60/hour, causing intermittent 'error code 56' failures. Authentication
# raises this to 5,000/hour and eliminates these errors.
#
# We use the 'gitcreds' package, which reads your GitHub PAT from the
# system keychain (macOS Keychain / Windows Credential Manager).
# If you have authenticated with GitHub via the 'gh' CLI or RStudio,
# your credentials may already be stored and this will work automatically.
#
# Run the block below. It will:
#   a) Install gitcreds if needed
#   b) Check if a GitHub PAT is already stored in your keychain
#   c) If not, open a prompt for you to paste your PAT
#   d) Set GITHUB_PAT in this session so renv can use it
#
# To create a PAT (do this once, only if you don't have one):
#   1. Go to: https://github.com/settings/tokens/new
#      - Token name: 'R renv installs'
#      - Expiration: 90 days
#      - Scopes: leave ALL boxes UNCHECKED (public repos need no scope)
#      - Click 'Generate token' and copy it (starts with ghp_...)
#
if (!requireNamespace('gitcreds', quietly = TRUE)) install.packages('gitcreds', quiet = TRUE)
local({
  cred <- tryCatch(gitcreds::gitcreds_get(), error = function(e) NULL)
  if (is.null(cred) || !nzchar(cred$password)) {
    message('No GitHub credentials found in keychain.')
    message('Running gitcreds::gitcreds_set() — paste your PAT when prompted.')
    gitcreds::gitcreds_set()
    cred <- tryCatch(gitcreds::gitcreds_get(), error = function(e) NULL)
  }
  if (!is.null(cred) && nzchar(cred$password)) {
    Sys.setenv(GITHUB_PAT = cred$password)
    message('GITHUB_PAT set from keychain. Unauthenticated rate limit lifted.')
  } else {
    warning('Could not load GitHub credentials. GitHub API calls may fail.')
  }
})

# =============================================================================
# STEP 1 — Install GitHub-only packages
# =============================================================================
#
# These packages are not on CRAN. Explicit org/repo ensures renv.lock
# records the correct source for Posit Connect / new-machine deployments.
# renv checks its global cache first — already-cached = near-instant.
#
# WARNING: @HEAD installs the LATEST commit each time this script is run.
# Step 5 (renv::snapshot) locks the exact SHA so deployments are
# reproducible. Do NOT re-run this script unless you intend to upgrade
# shinyplanr — doing so will update to the latest HEAD and require a new
# snapshot and redeployment.

renv::install("SpatialPlanning/shinyplanr@HEAD", prompt = FALSE)
renv::install("SpatialPlanning/spatialplanr@HEAD", prompt = FALSE)
renv::install("dreamRs/shinyWidgets@HEAD", prompt = FALSE)
# [IF oceandatr]
renv::install("emlab-ucsb/oceandatr@HEAD", prompt = FALSE)
renv::install("emlab-ucsb/spatialgridr@HEAD", prompt = FALSE)
# [END oceandatr]

# =============================================================================
# STEP 2 — Install CRAN packages
# =============================================================================
#
# NOTE: terra is pinned to 1.9-27 (TEMPORARY).
# terra 1.9-34 introduced a breaking change that affects this app.
# Remove the pinned install line below once the issue is resolved upstream.
# See: https://github.com/rspatial/terra/issues

renv::install("terra@1.9-27", prompt = FALSE)

renv::install(c(
  "shiny", "tidyverse", "sf", "ggplot2", "readr", "dplyr",
  "tidyr", "purrr", "stringr", "tibble", "tidyselect", "bslib",
  "leafgl", "leaflet", "htmltools", "patchwork", "gridExtra", "reactable",
  "shinyalert", "shinycssloaders", "shinydisconnect", "shinyjs",
  "prioritizr", "highs", "rnaturalearth", "rnaturalearthdata", "units",
  "quarto", "withr", "rsconnect", "ggridges", "kableExtra"
), prompt = FALSE)

# =============================================================================
# STEP 3 — Optional: faster solvers
# =============================================================================
#
# shinyplanr uses HiGHS by default (installed above) — no system dependencies.
# For better performance on large problems, you can optionally install:
#
# CBC solver (rcbc) — requires system CBC libraries first:
#   See: https://github.com/dirkschumacher/rcbc
#
# Gurobi — commercial solver, free academic licence available:
#   See: https://www.gurobi.com/academia/academic-program-and-licenses/
#
# If either is installed, prioritizr will use it automatically in preference
# to HiGHS (priority order: Gurobi > CBC > HiGHS).
#
# Uncomment to install rcbc (after installing system CBC libraries):
# renv::install("dirkschumacher/rcbc@HEAD", prompt = FALSE)

# =============================================================================
# STEP 4 — Verify installs before locking
# =============================================================================
#
# Check that the packages most critical to the app are actually installed.
# renv::install() with prompt = FALSE does not stop on partial failure, so
# this catches silent errors before they produce a broken renv.lock.

local({
  required <- c(
    "shinyplanr", "spatialplanr", "shinyWidgets",
    "shiny", "sf", "prioritizr", "highs",
    "leafgl", "leaflet", "reactable", "bslib", "ggridges"
  )
  missing_pkgs <- required[
    !vapply(required, requireNamespace, logical(1L), quietly = TRUE)
  ]
  if (length(missing_pkgs) > 0L) {
    stop(
      "The following packages failed to install:\n  ",
      paste(missing_pkgs, collapse = "\n  "),
      "\nFix the errors above, then re-run renv::snapshot()."
    )
  }
  message("All critical packages verified.")
})

# =============================================================================
# STEP 4b — Optional: your additional packages
# =============================================================================
#
# If you need packages beyond the shinyplanr defaults (e.g. for custom data
# processing in 2_setup_data.R), add them to setup/packages_extra.R.
# That file is sourced here automatically and is NEVER overwritten when you
# run shinyplanr::update_shinyplanr_template().
#
# Example setup/packages_extra.R:
#   renv::install('ggforce', prompt = FALSE)
#   renv::install('MyOrg/mypackage@HEAD', prompt = FALSE)

if (file.exists('setup/packages_extra.R')) {
  message('\nInstalling your additional packages (setup/packages_extra.R)...')
  source('setup/packages_extra.R', local = TRUE)
}

# =============================================================================
# STEP 5 — Lock versions
# =============================================================================
#
# Writes renv.lock. Commit this file to version control.

renv::snapshot(type = 'implicit')

message("\nAll packages installed. renv.lock written.")
message("Next: open setup/2_setup_data.R and prepare the spatial data.")

# Open the next setup script -----------------------------------------------
if (requireNamespace('rstudioapi', quietly = TRUE) && rstudioapi::isAvailable()) {
  rstudioapi::navigateToFile('setup/2_setup_data.R')
}
