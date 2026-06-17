# tests/testthat/test-create_template.R
#
# Tests for create_shinyplanr_template() — exported public function.
# All tests write into a temporary directory and clean up on exit.
# renv initialisation is always disabled (use_renv = FALSE) to avoid
# network calls and long runtimes in CI.

# ---------------------------------------------------------------------------
# Helper: run the template generator into a fresh tempdir
# ---------------------------------------------------------------------------

make_template <- function(country = "TestIsland", ...) {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_", country, "_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country    = country,
      output_dir = out_dir,
      use_renv   = FALSE,
      create_rproj = FALSE,
      ...
    )
  )

  out_dir
}

# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() stops when country is missing", {
  expect_error(
    create_shinyplanr_template(output_dir = tempdir(), use_renv = FALSE),
    regexp = "country"
  )
})

test_that("create_shinyplanr_template() stops when country is empty string", {
  expect_error(
    create_shinyplanr_template(
      country    = "",
      output_dir = tempdir(),
      use_renv   = FALSE
    ),
    regexp = "country"
  )
})

test_that("create_shinyplanr_template() stops when crs is empty string", {
  expect_error(
    create_shinyplanr_template(
      country    = "TestIsland",
      crs        = "",
      output_dir = tempdir(),
      use_renv   = FALSE
    ),
    regexp = "crs"
  )
})

test_that("create_shinyplanr_template() stops when oceandatr is not logical", {
  expect_error(
    create_shinyplanr_template(
      country    = "TestIsland",
      oceandatr  = "yes",
      output_dir = tempdir(),
      use_renv   = FALSE
    ),
    regexp = "oceandatr"
  )
})

test_that("create_shinyplanr_template() stops when use_renv is not logical", {
  expect_error(
    create_shinyplanr_template(
      country    = "TestIsland",
      use_renv   = "no",
      output_dir = tempdir()
    ),
    regexp = "use_renv"
  )
})

# ---------------------------------------------------------------------------
# Return value
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() invisibly returns the output directory path", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_ReturnTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  result <- suppressMessages(
    create_shinyplanr_template(
      country      = "ReturnTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_equal(result, out_dir)
})

# ---------------------------------------------------------------------------
# Directory structure
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() creates the expected top-level directories", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_DirTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "DirTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_true(dir.exists(out_dir))
  expect_true(dir.exists(file.path(out_dir, "config")))
  expect_true(dir.exists(file.path(out_dir, "www")))
  expect_true(dir.exists(file.path(out_dir, "setup")))
  expect_true(dir.exists(file.path(out_dir, "setup", "data")))
  expect_true(dir.exists(file.path(out_dir, "setup", "logos")))
  expect_true(dir.exists(file.path(out_dir, "setup", "content")))
})

# ---------------------------------------------------------------------------
# Required files
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() creates app.R in the project root", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_FileTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "FileTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_true(file.exists(file.path(out_dir, "app.R")))
})

test_that("create_shinyplanr_template() creates deploy.R in the project root", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_DeployTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "DeployTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_true(file.exists(file.path(out_dir, "deploy.R")))
})

test_that("create_shinyplanr_template() creates the three setup scripts", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_SetupTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "SetupTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  setup_dir <- file.path(out_dir, "setup")
  expect_true(file.exists(file.path(setup_dir, "1_setup_enviro.R")))
  expect_true(file.exists(file.path(setup_dir, "2_setup_data.R")))
  expect_true(file.exists(file.path(setup_dir, "3_setup_app.R")))
})

test_that("create_shinyplanr_template() creates Dict_Feature.csv in setup/", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_DictTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "DictTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_true(file.exists(file.path(out_dir, "setup", "Dict_Feature.csv")))
})

# ---------------------------------------------------------------------------
# .Rproj creation (opt-in)
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() creates .Rproj when create_rproj = TRUE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_RprojTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "RprojTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = TRUE
    )
  )

  expect_true(file.exists(file.path(out_dir, "RprojTest.Rproj")))
})

test_that("create_shinyplanr_template() does NOT create .Rproj when create_rproj = FALSE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_NoRprojTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "NoRprojTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  expect_false(file.exists(file.path(out_dir, "NoRprojTest.Rproj")))
})

# ---------------------------------------------------------------------------
# oceandatr = FALSE produces a minimal template (no oceandatr calls)
# ---------------------------------------------------------------------------

test_that("create_shinyplanr_template() succeeds with oceandatr = FALSE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_NoOcean_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  expect_no_error(
    suppressMessages(
      create_shinyplanr_template(
        country      = "NoOcean",
        oceandatr    = FALSE,
        output_dir   = out_dir,
        use_renv     = FALSE,
        create_rproj = FALSE
      )
    )
  )

  expect_true(file.exists(file.path(out_dir, "setup", "2_setup_data.R")))
})

# ---------------------------------------------------------------------------
# 3_setup_app.R content: include_ess defaults to FALSE
# ---------------------------------------------------------------------------

test_that("3_setup_app.R sets include_ess = FALSE by default", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_EssTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "EssTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  setup_app <- readLines(file.path(out_dir, "setup", "3_setup_app.R"), warn = FALSE)
  setup_app_text <- paste(setup_app, collapse = "\n")

  expect_true(
    grepl("include_ess\\s*=\\s*FALSE", setup_app_text),
    label = "3_setup_app.R should default include_ess to FALSE (no ESS data in default Dict)"
  )
})

# ---------------------------------------------------------------------------
# 3_setup_app.R content: uses public get_schema_version() not :::
# ---------------------------------------------------------------------------

test_that("3_setup_app.R references get_schema_version() without ::: operator", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_SchemaTest_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "SchemaTest",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE
    )
  )

  setup_app <- readLines(file.path(out_dir, "setup", "3_setup_app.R"), warn = FALSE)
  setup_app_text <- paste(setup_app, collapse = "\n")

  # Should use the public get_schema_version() function, not the internal :::
  expect_false(
    grepl("shinyplanr:::.shinyplanr_schema_version", setup_app_text, fixed = TRUE),
    label = "3_setup_app.R must not use ::: to access internal schema version"
  )
  expect_true(
    grepl("get_schema_version()", setup_app_text, fixed = TRUE),
    label = "3_setup_app.R should call shinyplanr::get_schema_version()"
  )
})

# ---------------------------------------------------------------------------
# Dict_Feature.csv content: MPA LockIn and LockOut rows
# ---------------------------------------------------------------------------

test_that("Dict_Feature.csv contains both LockIn and LockOut MPA rows when include_mpas = TRUE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_MpaDict_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "MpaDict",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE,
      include_mpas = TRUE
    )
  )

  dict_path <- file.path(out_dir, "setup", "Dict_Feature.csv")
  dict_text <- paste(readLines(dict_path, warn = FALSE), collapse = "\n")

  expect_true(
    grepl("mpas.*LockIn", dict_text),
    label = "Dict_Feature.csv should contain an mpas LockIn row"
  )
  expect_true(
    grepl("mpas.*LockOut", dict_text),
    label = "Dict_Feature.csv should contain an mpas LockOut row"
  )
})

test_that("Dict_Feature.csv contains no MPA rows when include_mpas = FALSE", {
  out_dir <- file.path(tempdir(), paste0("shinyplanr_NoMpaDict_", Sys.getpid()))
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)

  suppressMessages(
    create_shinyplanr_template(
      country      = "NoMpaDict",
      output_dir   = out_dir,
      use_renv     = FALSE,
      create_rproj = FALSE,
      include_mpas = FALSE
    )
  )

  dict_path <- file.path(out_dir, "setup", "Dict_Feature.csv")
  dict_text <- paste(readLines(dict_path, warn = FALSE), collapse = "\n")

  expect_false(
    grepl("LockIn", dict_text),
    label = "Dict_Feature.csv should not contain LockIn rows when include_mpas = FALSE"
  )
  expect_false(
    grepl("LockOut", dict_text),
    label = "Dict_Feature.csv should not contain LockOut rows when include_mpas = FALSE"
  )
})
