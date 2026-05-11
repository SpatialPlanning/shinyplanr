# tests/testthat/test-golem-recommended.R
#
# Golem-recommended app-level tests, with meaningful assertions added.

# ---------------------------------------------------------------------------
# app_ui()
# ---------------------------------------------------------------------------

test_that("app_ui() returns a valid shiny tag list", {
  ui <- app_ui()
  golem::expect_shinytaglist(ui)
})

test_that("app_ui() formals contain 'request'", {
  fmls <- formals(app_ui)
  expect_true("request" %in% names(fmls))
})

test_that("app_ui() always includes the Scenario tab", {
  ui   <- app_ui()
  html <- as.character(ui)
  expect_match(html, "Scenario", fixed = TRUE)
})

test_that("app_ui() includes Welcome tab when options$mod_1welcome is TRUE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(mod_1welcome = TRUE))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- app_ui()
  html <- as.character(ui)
  expect_match(html, "Welcome", fixed = TRUE)
})

test_that("app_ui() omits Welcome tab when options$mod_1welcome is FALSE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(mod_1welcome = FALSE))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- app_ui()
  html <- as.character(ui)
  # Welcome tab panel should not be present when disabled
  expect_false(grepl('<a.*>Welcome</a>', html, perl = TRUE) &&
                 grepl('mod_1welcome_ui', html, fixed = TRUE))
})

test_that("app_ui() includes Comparison tab when options$mod_3compare is TRUE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(mod_3compare = TRUE))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- app_ui()
  html <- as.character(ui)
  expect_match(html, "Comparison", fixed = TRUE)
})

test_that("app_ui() includes Help tab when options$mod_6help is TRUE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  modified_options <- modifyList(original_options, list(mod_6help = TRUE))
  assign("options", modified_options, envir = pkg_env)
  on.exit(assign("options", original_options, envir = pkg_env), add = TRUE)

  ui   <- app_ui()
  html <- as.character(ui)
  expect_match(html, "Help", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# app_server()
# ---------------------------------------------------------------------------

test_that("app_server() is a function (closure)", {
  expect_type(app_server, "closure")
})

test_that("app_server() formals contain 'input', 'output', 'session'", {
  fmls <- formals(app_server)
  for (i in c("input", "output", "session")) {
    expect_true(i %in% names(fmls))
  }
})

# ---------------------------------------------------------------------------
# golem infrastructure
# ---------------------------------------------------------------------------

test_that("app_sys() returns a non-empty path for golem-config.yml", {
  expect_true(app_sys("golem-config.yml") != "")
})

test_that("golem-config.yml is valid and has expected keys", {
  config_file <- app_sys("golem-config.yml")
  skip_if(config_file == "")

  expect_true(
    get_golem_config("app_prod", config = "production", file = config_file)
  )
  expect_false(
    get_golem_config("app_prod", config = "dev", file = config_file)
  )
})

# ---------------------------------------------------------------------------
# App launch (integration)
# ---------------------------------------------------------------------------

test_that("app launches and stays running for 5 seconds", {
  golem::expect_running(sleep = 5)
})
