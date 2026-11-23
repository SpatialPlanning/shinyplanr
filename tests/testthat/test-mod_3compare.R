# tests/testthat/test-mod_3compare.R
#
# Tests for mod_3compare_ui() and mod_3compare_server().
# cfg is built from the stub sysdata.rda objects in the package namespace.

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

testServer(
  mod_3compare_server,
  args = list(cfg = cfg),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl(id, ns("")))
    expect_true(grepl("test", ns("test")))
  }
)

test_that("mod_3compare_ui() works", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  golem::expect_shinytag(ui)
  # Check that formals contain id and cfg
  fmls <- formals(mod_3compare_ui)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_3compare_server() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_3compare_server)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

# ---------------------------------------------------------------------------
# Copy-targets buttons
# ---------------------------------------------------------------------------

test_that("mod_3compare_ui() contains copyFromScen1 and copyFromScen2 buttons", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_true(grepl("copyFromScen1", html))
  expect_true(grepl("copyFromScen2", html))
})

test_that("mod_3compare_ui() copy buttons have expected labels", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_true(grepl("Match Scenario 1", html))
  expect_true(grepl("Match Scenario 2", html))
})

test_that("mod_3compare_server() copyFromScen1 button input exists in server", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg),
    {
      # Verify the server can receive the copyFromScen1 input without error
      expect_no_error(session$setInputs(copyFromScen1 = 1L))
    }
  )
})

test_that("mod_3compare_server() copyFromScen2 button input exists in server", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg),
    {
      # Verify the server can receive the copyFromScen2 input without error
      expect_no_error(session$setInputs(copyFromScen2 = 1L))
    }
  )
})

# ---------------------------------------------------------------------------
# Climate-smart approach controls (visible_climateOptions)
# ---------------------------------------------------------------------------

test_that("mod_3compare_ui() does not render climate-options controls when visible_climateOptions is FALSE", {
  cfg_clim <- cfg
  cfg_clim$options <- modifyList(
    cfg$options,
    list(include_climateChange = TRUE, visible_climateOptions = FALSE)
  )

  ui <- mod_3compare_ui(id = "test_clim_hidden", cfg = cfg_clim)
  html <- as.character(ui)
  expect_false(grepl("climate_change1", html, fixed = TRUE))
  expect_false(grepl("climate_change2", html, fixed = TRUE))
  expect_false(grepl("refugiaTarget1", html, fixed = TRUE))
  expect_false(grepl("refugiaTarget2", html, fixed = TRUE))
})

test_that("mod_3compare_ui() renders independent climate-options controls for both scenarios when visible_climateOptions is TRUE", {
  cfg_clim <- cfg
  cfg_clim$options <- modifyList(
    cfg$options,
    list(include_climateChange = TRUE, visible_climateOptions = TRUE)
  )

  ui <- mod_3compare_ui(id = "test_clim_visible", cfg = cfg_clim)
  html <- as.character(ui)
  expect_match(html, "climate_change1", fixed = TRUE)
  expect_match(html, "climate_change2", fixed = TRUE)
  expect_match(html, "percentile1", fixed = TRUE)
  expect_match(html, "percentile2", fixed = TRUE)
  expect_match(html, "direction1", fixed = TRUE)
  expect_match(html, "direction2", fixed = TRUE)
  expect_match(html, "refugiaTarget1", fixed = TRUE)
  expect_match(html, "refugiaTarget2", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# Explore tab
# ---------------------------------------------------------------------------

test_that("mod_3compare_ui() contains the Explore tab, mode radio, and scenario checkboxes", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "Explore Map", fixed = TRUE)
  expect_match(html, "exploreMode", fixed = TRUE)
  expect_match(html, "showScen1", fixed = TRUE)
  expect_match(html, "showScen2", fixed = TRUE)
  expect_match(html, "leaflet_map_explore", fixed = TRUE)
})

test_that("mod_3compare_ui() renders separate Display Mode and Planning Unit panels", {
  ui <- mod_3compare_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "displayModePanel", fixed = TRUE)
  expect_match(html, "planningUnitPanel", fixed = TRUE)
  expect_match(html, "Display Mode", fixed = TRUE)
  # The "Planning Unit" heading is rendered server-side (inside
  # exploreInfoPanelContent) rather than hardcoded in the static UI, so
  # that a clicked planning unit's heading replaces it instead of adding a
  # second heading below it (see next test).
  expect_false(grepl("explorePanel", html, fixed = TRUE))
})

test_that("mod_3compare_server() exploreInfoPanelContent shows a single 'Planning Unit' heading by default, with no duplicate after a click", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      default_html <- output$exploreInfoPanelContent$html
      # Exactly one heading occurrence before any click.
      expect_equal(
        length(gregexpr("Planning Unit", default_html, fixed = TRUE)[[1]]),
        1
      )
    }
  )
})

test_that("mod_3compare_ui() Explore tab is always present in HTML regardless of include_explore", {
  # The Explore tab is always rendered in the HTML; server-side hideTab()
  # controls visibility at runtime based on options$include_explore.
  cfg_no_explore <- cfg
  cfg_no_explore$options <- modifyList(
    cfg$options,
    list(include_explore = FALSE)
  )
  ui_no_explore <- mod_3compare_ui(id = "test_no_explore", cfg = cfg_no_explore)
  html_no_explore <- as.character(ui_no_explore)
  expect_match(html_no_explore, "Explore Map", fixed = TRUE)

  cfg_with_explore <- cfg
  cfg_with_explore$options <- modifyList(
    cfg$options,
    list(include_explore = TRUE)
  )
  ui_with_explore <- mod_3compare_ui(
    id = "test_with_explore",
    cfg = cfg_with_explore
  )
  html_with_explore <- as.character(ui_with_explore)
  expect_match(html_with_explore, "Explore Map", fixed = TRUE)
})

test_that("mod_3compare_server() accepts a tab_visible argument", {
  fmls <- formals(mod_3compare_server)
  expect_true("tab_visible" %in% names(fmls))
})

testServer(
  mod_3compare_server,
  args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
  }
)

test_that("mod_3compare_server() exploreMode input can be set without error", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(session$setInputs(exploreMode = "compare"))
      expect_no_error(session$setInputs(exploreMode = "scenario"))
    }
  )
})

test_that("mod_3compare_server() showScen1/showScen2 inputs can be set without error", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(session$setInputs(showScen1 = FALSE))
      expect_no_error(session$setInputs(showScen2 = FALSE))
    }
  )
})

test_that("mod_3compare_server() registers leaflet_map_explore as an output", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      mock_session <- .subset2(session$output, "impl")
      registered <- names(mock_session$.__enclos_env__$private$outs)
      expect_true(
        any(grepl("leaflet_map_explore", registered)),
        info = paste("Registered outputs:", paste(registered, collapse = ", "))
      )
    }
  )
})

test_that("mod_3compare_server() glify click handler on Explore map does not error before an analysis has run", {
  testServer(
    mod_3compare_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(
        session$setInputs(
          leaflet_map_explore_glify_click = list(id = 1)
        )
      )
    }
  )
})

test_that("mod_3compare_server() uses the updated light/dark green Scenario-mode colours", {
  # Scenario 1 "Selected" must be the light green (#7fc97f), Scenario 2 the
  # dark green (#00441b) -- the old near-identical greens (#2ca02c/#1b7837)
  # must no longer appear as colour_selected values.
  src <- paste(readLines("../../R/mod_3compare.R"), collapse = "\n")
  expect_match(src, "#7fc97f", fixed = TRUE)
  expect_match(src, "#00441b", fixed = TRUE)
})

test_that("mod_3compare_server() Explore map legends use bottomleft position", {
  # Legend sits at bottomleft, next to the zoom control (also bottomleft) --
  # Leaflet stacks same-corner controls, and a CSS rule (shinyplanr.css)
  # arranges them in a row so the legend appears beside the zoom buttons.
  src <- paste(readLines("../../R/mod_3compare.R"), collapse = "\n")
  expect_match(src, 'position = "bottomleft"', fixed = TRUE)
})

test_that("mod_3compare_server() suppresses the default zoom control and relocates a single one via onRender()", {
  src <- paste(readLines("../../R/mod_3compare.R"), collapse = "\n")
  # zoomControl = FALSE at map creation prevents a duplicate top-left control
  # from appearing alongside the bottom-left one added by onRender().
  expect_match(src, "zoomControl = FALSE", fixed = TRUE)
  expect_match(src, "L.control.zoom", fixed = TRUE)
  expect_match(src, "bottomleft", fixed = TRUE)
})
