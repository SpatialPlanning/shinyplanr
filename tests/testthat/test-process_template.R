# tests/testthat/test-process_template.R
#
# Unit tests for the internal .process_template() helper and integration tests
# confirming that the template-based setup script writers produce correct output.
#
# .process_template() is an internal function accessed via shinyplanr:::.

# ---------------------------------------------------------------------------
# Helper: write a temporary template file and return its path.
# Uses tempfile() so the path persists for the duration of the test.
# R cleans up tempdir() at session end.
# ---------------------------------------------------------------------------

make_template_file <- function(lines) {
  path <- tempfile(fileext = ".R")
  writeLines(lines, path)
  path
}

# ---------------------------------------------------------------------------
# Happy path: no conditions, no substitutions
# ---------------------------------------------------------------------------

test_that(".process_template() returns lines unchanged when no conditions or substitutions", {
  lines <- c("library(sf)", "", "x <- 1")
  path  <- make_template_file(lines)

  result <- shinyplanr:::.process_template(path)

  expect_equal(result, lines)
})

# ---------------------------------------------------------------------------
# Token substitution
# ---------------------------------------------------------------------------

test_that(".process_template() substitutes {placeholder} tokens", {
  lines <- c('country <- "{country}"', 'crs <- "{crs}"')
  path  <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    substitutions = list(country = "Fiji", crs = "EPSG:32760")
  )

  expect_equal(result[[1]], 'country <- "Fiji"')
  expect_equal(result[[2]], 'crs <- "EPSG:32760"')
})

test_that(".process_template() substitutes {resolution} with a numeric value", {
  lines <- c("resolution <- {resolution}L")
  path  <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    substitutions = list(resolution = 20000)
  )

  expect_equal(result[[1]], "resolution <- 20000L")
})

# ---------------------------------------------------------------------------
# [IF TRUE] block: lines kept, markers removed
# ---------------------------------------------------------------------------

test_that(".process_template() keeps lines inside a TRUE [IF] block", {
  lines <- c(
    "before",
    "# [IF myblock]",
    "inside",
    "# [END myblock]",
    "after"
  )
  path <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    conditions = list(myblock = TRUE)
  )

  expect_equal(result, c("before", "inside", "after"))
})

# ---------------------------------------------------------------------------
# [IF FALSE] block: lines removed, markers removed
# ---------------------------------------------------------------------------

test_that(".process_template() removes lines inside a FALSE [IF] block", {
  lines <- c(
    "before",
    "# [IF myblock]",
    "inside",
    "# [END myblock]",
    "after"
  )
  path <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    conditions = list(myblock = FALSE)
  )

  expect_equal(result, c("before", "after"))
})

# ---------------------------------------------------------------------------
# Multiple conditions: mutually exclusive oceandatr / manual pattern
# ---------------------------------------------------------------------------

test_that(".process_template() handles mutually exclusive oceandatr/manual blocks", {
  lines <- c(
    "# [IF oceandatr]",
    "library(oceandatr)",
    "# [END oceandatr]",
    "# [IF manual]",
    "# TODO: load manually",
    "# [END manual]"
  )
  path <- make_template_file(lines)

  # oceandatr = TRUE
  result_ocean <- shinyplanr:::.process_template(
    path,
    conditions = list(oceandatr = TRUE, manual = FALSE)
  )
  expect_equal(result_ocean, "library(oceandatr)")

  # oceandatr = FALSE
  result_manual <- shinyplanr:::.process_template(
    path,
    conditions = list(oceandatr = FALSE, manual = TRUE)
  )
  expect_equal(result_manual, "# TODO: load manually")
})

# ---------------------------------------------------------------------------
# Substitution inside a kept [IF] block
# ---------------------------------------------------------------------------

test_that(".process_template() substitutes tokens inside a kept [IF] block", {
  lines <- c(
    "# [IF myblock]",
    'x <- "{value}"',
    "# [END myblock]"
  )
  path <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    conditions    = list(myblock = TRUE),
    substitutions = list(value = "hello")
  )

  expect_equal(result, 'x <- "hello"')
})

test_that(".process_template() does NOT substitute tokens inside a FALSE [IF] block", {
  lines <- c(
    "# [IF myblock]",
    'x <- "{value}"',
    "# [END myblock]",
    'y <- "{value}"'
  )
  path <- make_template_file(lines)

  result <- shinyplanr:::.process_template(
    path,
    conditions    = list(myblock = FALSE),
    substitutions = list(value = "hello")
  )

  # Only the line outside the block should be substituted
  expect_equal(result, 'y <- "hello"')
})

# ---------------------------------------------------------------------------
# Error: template file not found
# ---------------------------------------------------------------------------

test_that(".process_template() errors when template file does not exist", {
  expect_error(
    shinyplanr:::.process_template("/nonexistent/path/template.R"),
    regexp = "Template file not found"
  )
})

# ---------------------------------------------------------------------------
# Error: unknown condition name
# ---------------------------------------------------------------------------

test_that(".process_template() errors on unknown condition name in template", {
  lines <- c(
    "# [IF unknown_cond]",
    "x <- 1",
    "# [END unknown_cond]"
  )
  path <- make_template_file(lines)

  expect_error(
    shinyplanr:::.process_template(path, conditions = list(other = TRUE)),
    regexp = "Unknown condition 'unknown_cond'"
  )
})

# ---------------------------------------------------------------------------
# Error: nested [IF] blocks
# ---------------------------------------------------------------------------

test_that(".process_template() errors on nested [IF] blocks", {
  lines <- c(
    "# [IF outer]",
    "# [IF inner]",
    "x <- 1",
    "# [END inner]",
    "# [END outer]"
  )
  path <- make_template_file(lines)

  expect_error(
    shinyplanr:::.process_template(
      path,
      conditions = list(outer = TRUE, inner = TRUE)
    ),
    regexp = "Nested \\[IF\\] blocks are not supported"
  )
})

# ---------------------------------------------------------------------------
# Error: [END] without matching [IF]
# ---------------------------------------------------------------------------

test_that(".process_template() errors on [END] without matching [IF]", {
  lines <- c(
    "x <- 1",
    "# [END orphan]"
  )
  path <- make_template_file(lines)

  expect_error(
    shinyplanr:::.process_template(path, conditions = list(orphan = TRUE)),
    regexp = "\\[END orphan\\] without matching \\[IF orphan\\]"
  )
})

# ---------------------------------------------------------------------------
# Error: unclosed [IF]
# ---------------------------------------------------------------------------

test_that(".process_template() errors on unclosed [IF] block", {
  lines <- c(
    "# [IF myblock]",
    "x <- 1"
  )
  path <- make_template_file(lines)

  expect_error(
    shinyplanr:::.process_template(path, conditions = list(myblock = TRUE)),
    regexp = "Unclosed \\[IF myblock\\]"
  )
})

# ---------------------------------------------------------------------------
# Integration: 1_setup_enviro.R template produces no [IF]/[END] markers
# ---------------------------------------------------------------------------

test_that("1_setup_enviro.R template output contains no [IF]/[END] markers", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_ProcTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "ProcTpl",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  enviro_lines <- readLines(
    file.path(out_dir, "setup", "1_setup_enviro.R"),
    warn = FALSE
  )

  expect_false(
    any(grepl("\\[IF\\s+\\w+\\]", enviro_lines)),
    label = "1_setup_enviro.R must not contain [IF ...] markers"
  )
  expect_false(
    any(grepl("\\[END\\s+\\w+\\]", enviro_lines)),
    label = "1_setup_enviro.R must not contain [END ...] markers"
  )
})

# ---------------------------------------------------------------------------
# Integration: oceandatr = TRUE includes oceandatr installs in 1_setup_enviro.R
# ---------------------------------------------------------------------------

test_that("1_setup_enviro.R includes oceandatr install when oceandatr = TRUE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_OceanTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "OceanTpl",
      oceandatr    = TRUE,
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  enviro_text <- paste(
    readLines(file.path(out_dir, "setup", "1_setup_enviro.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_true(
    grepl("oceandatr", enviro_text, fixed = TRUE),
    label = "1_setup_enviro.R should reference oceandatr when oceandatr = TRUE"
  )
  expect_true(
    grepl("spatialgridr", enviro_text, fixed = TRUE),
    label = "1_setup_enviro.R should reference spatialgridr when oceandatr = TRUE"
  )
})

# ---------------------------------------------------------------------------
# Integration: oceandatr = FALSE omits oceandatr installs from 1_setup_enviro.R
# ---------------------------------------------------------------------------

test_that("1_setup_enviro.R omits oceandatr install when oceandatr = FALSE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_NoOceanTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "NoOceanTpl",
      oceandatr    = FALSE,
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  enviro_text <- paste(
    readLines(file.path(out_dir, "setup", "1_setup_enviro.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_false(
    grepl('renv::install("emlab-ucsb/oceandatr', enviro_text, fixed = TRUE),
    label = "1_setup_enviro.R must not install oceandatr when oceandatr = FALSE"
  )
})

# ---------------------------------------------------------------------------
# Integration: {country} and {crs} tokens are substituted in 2_setup_data.R
# ---------------------------------------------------------------------------

test_that("2_setup_data.R substitutes country and crs tokens correctly", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_TknTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "TokenTest",
      crs          = "EPSG:32760",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  data_text <- paste(
    readLines(file.path(out_dir, "setup", "2_setup_data.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_true(
    grepl('country    <- "TokenTest"', data_text, fixed = TRUE),
    label = "2_setup_data.R should contain the substituted country name"
  )
  expect_true(
    grepl('crs        <- "EPSG:32760"', data_text, fixed = TRUE),
    label = "2_setup_data.R should contain the substituted CRS"
  )
  expect_false(
    grepl("{country}", data_text, fixed = TRUE),
    label = "2_setup_data.R must not contain unsubstituted {country} token"
  )
})

# ---------------------------------------------------------------------------
# Integration: 2_setup_data.R includes boundary/coastline simplification
# ---------------------------------------------------------------------------

test_that("2_setup_data.R includes st_simplify() calls for bndry and coast", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_SimplifyTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "SimplifyTpl",
      resolution   = 100,
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  data_text <- paste(
    readLines(file.path(out_dir, "setup", "2_setup_data.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_true(
    grepl("simplify_tol <- resolution / 4", data_text, fixed = TRUE),
    label = "2_setup_data.R should define simplify_tol relative to resolution"
  )
  expect_true(
    grepl('bndry <- sf::st_simplify(bndry, preserveTopology = TRUE, dTolerance = simplify_tol)',
      data_text, fixed = TRUE),
    label = "2_setup_data.R should simplify bndry before saving"
  )
  expect_true(
    grepl('coast <- sf::st_simplify(coast, preserveTopology = TRUE, dTolerance = simplify_tol)',
      data_text, fixed = TRUE),
    label = "2_setup_data.R should simplify coast before saving"
  )

  # The simplification block must appear AFTER the planning unit grid (PUs)
  # is created, so it never affects the spatial analysis - only the saved
  # plotting geometry.
  pu_pos       <- regexpr("PUs <- spatialgridr::get_grid", data_text, fixed = TRUE)
  simplify_pos <- regexpr("simplify_tol <- resolution", data_text, fixed = TRUE)
  expect_true(
    pu_pos > 0 && simplify_pos > pu_pos,
    label = "Simplification must occur after the planning unit grid is created"
  )
})

# ---------------------------------------------------------------------------
# Integration: include_climate = FALSE omits climate block from 3_setup_app.R
# ---------------------------------------------------------------------------

test_that("3_setup_app.R omits climate options when include_climate = FALSE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_NoClimTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country         = "NoClimTpl",
      include_climate = FALSE,
      output_dir      = out_dir,
      use_renv        = FALSE,
      create_rproj    = FALSE
    )
  )

  app_text <- paste(
    readLines(file.path(out_dir, "setup", "3_setup_app.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_false(
    grepl("include_climateChange", app_text, fixed = TRUE),
    label = "3_setup_app.R must not contain climate options when include_climate = FALSE"
  )
})

# ---------------------------------------------------------------------------
# Integration: include_climate = TRUE includes climate block in 3_setup_app.R
# ---------------------------------------------------------------------------

test_that("3_setup_app.R includes climate options when include_climate = TRUE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_ClimTpl_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country         = "ClimTpl",
      include_climate = TRUE,
      output_dir      = out_dir,
      use_renv        = FALSE,
      create_rproj    = FALSE
    )
  )

  app_text <- paste(
    readLines(file.path(out_dir, "setup", "3_setup_app.R"), warn = FALSE),
    collapse = "\n"
  )

  expect_true(
    grepl("include_climateChange", app_text, fixed = TRUE),
    label = "3_setup_app.R should contain climate options when include_climate = TRUE"
  )
})
