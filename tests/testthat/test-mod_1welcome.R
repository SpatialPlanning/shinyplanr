# tests/testthat/test-mod_1welcome.R
#
# Meaningful tests for mod_1welcome_ui() and mod_1welcome_server().
# The module reads tx, tx_1footer, and options from the package namespace;
# the stub sysdata.rda provides these for testing.

# Helper: safely overwrite a (potentially locked) namespace binding and restore.
.ns_set <- function(nm, value, envir) {
  if (bindingIsLocked(nm, envir)) unlockBinding(nm, envir)
  assign(nm, value, envir = envir)
}

# ---------------------------------------------------------------------------
# UI structure tests
# ---------------------------------------------------------------------------

test_that("mod_1welcome_ui() returns a shiny tag list", {
  ui <- mod_1welcome_ui(id = "test")
  golem::expect_shinytaglist(ui)
})

test_that("mod_1welcome_ui() formals contain 'id'", {
  fmls <- formals(mod_1welcome_ui)
  expect_true("id" %in% names(fmls))
})

test_that("mod_1welcome_ui() renders without error using stub namespace data", {
  # Stub sysdata.rda sets tx, tx_1footer, and options in the namespace;
  # the UI should build without throwing.
  expect_no_error(mod_1welcome_ui(id = "test"))
})

test_that("mod_1welcome_ui() produces HTML containing a footer div", {
  ui <- mod_1welcome_ui(id = "test")
  html <- as.character(ui)
  expect_match(html, "home-footer", fixed = TRUE)
})

test_that("mod_1welcome_ui() includes a funder logo image tag", {
  ui <- mod_1welcome_ui(id = "test")
  html <- as.character(ui)
  expect_match(html, "logo_funder\\.png", perl = TRUE)
})

test_that("mod_1welcome_ui() shows UQ logo when options$show_uq_logo is TRUE", {
  # Temporarily set show_uq_logo = TRUE in the namespace
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  .ns_set("options", modifyList(original_options, list(show_uq_logo = TRUE)), pkg_env)
  on.exit(.ns_set("options", original_options, pkg_env), add = TRUE)

  ui <- mod_1welcome_ui(id = "test_uq")
  html <- as.character(ui)
  expect_match(html, "uq-logo-white\\.png", perl = TRUE)
})

test_that("mod_1welcome_ui() hides UQ logo when options$show_uq_logo is FALSE", {
  pkg_env <- asNamespace("shinyplanr")
  original_options <- get("options", envir = pkg_env, inherits = FALSE)
  .ns_set("options", modifyList(original_options, list(show_uq_logo = FALSE)), pkg_env)
  on.exit(.ns_set("options", original_options, pkg_env), add = TRUE)

  ui <- mod_1welcome_ui(id = "test_nouq")
  html <- as.character(ui)
  expect_false(grepl("uq-logo-white\\.png", html))
})

test_that("mod_1welcome_ui() renders a tabsetPanel when tx$welcome has multiple entries", {
  pkg_env <- asNamespace("shinyplanr")
  original_tx <- get("tx", envir = pkg_env, inherits = FALSE)
  multi_tx <- list(
    welcome = list(
      list(title = "Tab 1", text = "# First tab"),
      list(title = "Tab 2", text = "# Second tab")
    )
  )
  .ns_set("tx", multi_tx, pkg_env)
  on.exit(.ns_set("tx", original_tx, pkg_env), add = TRUE)

  ui <- mod_1welcome_ui(id = "test_multi")
  html <- as.character(ui)
  expect_match(html, "nav nav-pills", fixed = TRUE)
})

test_that("mod_1welcome_ui() renders plain div when tx$welcome has a single entry", {
  pkg_env <- asNamespace("shinyplanr")
  original_tx <- get("tx", envir = pkg_env, inherits = FALSE)
  single_tx <- list(
    welcome = list(
      list(title = "Welcome", text = "# Hello")
    )
  )
  .ns_set("tx", single_tx, pkg_env)
  on.exit(.ns_set("tx", original_tx, pkg_env), add = TRUE)

  ui <- mod_1welcome_ui(id = "test_single")
  html <- as.character(ui)
  # A single entry is rendered without a tabsetPanel
  expect_false(grepl("nav nav-pills", html, fixed = TRUE))
})

# ---------------------------------------------------------------------------
# Server tests
# ---------------------------------------------------------------------------

test_that("mod_1welcome_server() has correct formals", {
  fmls <- formals(mod_1welcome_server)
  expect_true("id" %in% names(fmls))
})

testServer(mod_1welcome_server, args = list(), {
  ns <- session$ns
  expect_true(inherits(ns, "function"))
  expect_true(grepl(id, ns("")))
  expect_true(grepl("test", ns("test")))
})
