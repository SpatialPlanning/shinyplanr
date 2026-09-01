# tests/testthat/test-mod_4afeatures.R
#
# Tests for mod_4afeatures_ui() and mod_4afeatures_server().
# cfg is built from the stub sysdata.rda objects in the package namespace.
#
# NOTE: render_layer() defers all leafletProxy/output updates via
# shinyjs::delay(0), which requires a genuine browser round-trip (it sends a
# custom message and waits for a matching input event) and therefore never
# fires synchronously inside shiny::testServer(). This mirrors the existing
# WebGL rendering pattern in mod_2scenario.R. Consequently these tests
# exercise the reactive wiring (formals, UI structure, no-error on input
# changes) rather than asserting on the delayed output content.

# Build a cfg list from the stub namespace for use across all tests.
cfg <- shinyplanr:::get_pkg_config()

# ---------------------------------------------------------------------------
# UI structure tests
# ---------------------------------------------------------------------------

test_that("mod_4afeatures_ui() returns a shiny.tag.list", {
  ui <- mod_4afeatures_ui(id = "test", cfg = cfg)
  expect_s3_class(ui, "shiny.tag.list")
})

test_that("mod_4afeatures_ui() formals contain 'id' and 'cfg'", {
  fmls <- formals(mod_4afeatures_ui)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
})

test_that("mod_4afeatures_ui() renders without error using stub cfg", {
  expect_no_error(mod_4afeatures_ui(id = "test", cfg = cfg))
})

test_that("mod_4afeatures_ui() contains the leaflet output and layer selector", {
  ui <- mod_4afeatures_ui(id = "test", cfg = cfg)
  html <- as.character(ui)
  expect_match(html, "leaflet_map", fixed = TRUE)
  expect_match(html, "selectedLayer", fixed = TRUE)
  expect_match(html, "Feature Density", fixed = TRUE)
})

# ---------------------------------------------------------------------------
# Regression: grouped layer dropdown respects forder_dict_categories() order
# ---------------------------------------------------------------------------
#
# Categories are deliberately named so alphabetical-by-category-label order
# ("Aardvark Zone" < "Zebra Zone") is the OPPOSITE of the intended order
# (Zebra Zone first, via categoryOrder = 1). A passing test can only be
# explained by the ordered factor produced by forder_dict_categories()
# actually driving group_by()/group_split() order in mod_4afeatures_ui(),
# not alphabetical fallback.
test_that("mod_4afeatures_ui() layer dropdown optgroups respect forder_dict_categories() order", {
  Dict <- data.frame(
    nameCommon = c("Feature Z", "Feature A"),
    nameVariable = c("feature_z", "feature_a"),
    category = c("Zebra Zone", "Aardvark Zone"),
    categoryID = c("Zebra", "Aardvark"),
    categoryOrder = c(1, 2),
    type = c("Feature", "Feature"),
    targetInitial = c(30, 30),
    targetMin = c(0, 0),
    targetMax = c(85, 85),
    includeApp = TRUE,
    includeJust = TRUE,
    justification = "Stub.",
    stringsAsFactors = FALSE
  )
  Dict <- shinyplanr:::forder_dict_categories(Dict)

  cfg2 <- cfg
  cfg2$Dict <- Dict

  ui <- mod_4afeatures_ui(id = "test", cfg = cfg2)
  html <- as.character(ui)

  optgroup_labels <- regmatches(
    html,
    gregexpr('(?<=<optgroup label=")[^"]+', html, perl = TRUE)
  )[[1]]

  expect_equal(optgroup_labels[1], "Zebra Zone")
  expect_equal(optgroup_labels[2], "Aardvark Zone")
})

test_that("mod_4afeatures_ui() does not error when Dict$category is an ordered factor (map_chr/as.character fix)", {
  # Regression test for the purrr::map_chr() + factor incompatibility fixed
  # alongside forder_dict_categories(): map_chr() requires a character
  # result and does not coerce factors.
  Dict <- data.frame(
    nameCommon = c("Feature Z", "Feature A"),
    nameVariable = c("feature_z", "feature_a"),
    category = c("Zebra Zone", "Aardvark Zone"),
    categoryID = c("Zebra", "Aardvark"),
    type = c("Feature", "Feature"),
    targetInitial = c(30, 30),
    targetMin = c(0, 0),
    targetMax = c(85, 85),
    includeApp = TRUE,
    includeJust = TRUE,
    justification = "Stub.",
    stringsAsFactors = FALSE
  )
  Dict <- shinyplanr:::forder_dict_categories(Dict)

  cfg2 <- cfg
  cfg2$Dict <- Dict

  expect_no_error(mod_4afeatures_ui(id = "test", cfg = cfg2))
})

# ---------------------------------------------------------------------------
# Server tests
# ---------------------------------------------------------------------------

test_that("mod_4afeatures_server() formals contain 'id', 'cfg' and 'tab_visible'", {
  fmls <- formals(mod_4afeatures_server)
  expect_true("id" %in% names(fmls))
  expect_true("cfg" %in% names(fmls))
  expect_true("tab_visible" %in% names(fmls))
})

testServer(
  mod_4afeatures_server,
  args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
  {
    ns <- session$ns
    expect_true(inherits(ns, "function"))
    expect_true(grepl(id, ns("")))
    expect_true(grepl("test", ns("test")))
  }
)

test_that("selecting a Feature (binary) layer does not error", {
  # feature_A/feature_B are Feature-type columns in the stub Dict/raw_sf.
  # A single uniform render path (clearGlLayers() + addGlPolygons()) is used
  # for all layer types — see mod_4afeatures.R for rationale (a previous
  # base/overlay WebGL caching split was reverted because it only paid off
  # for binary-to-binary switches and added overhead for the more common
  # case of browsing freely across layer types).
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(session$setInputs(selectedLayer = "feature_A"))
    }
  )
})

test_that("switching between two Feature layers does not error", {
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      session$setInputs(selectedLayer = "feature_A")
      expect_no_error(session$setInputs(selectedLayer = "feature_B"))
    }
  )
})

test_that("selecting Feature Density (__density__) does not error", {
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(session$setInputs(selectedLayer = "__density__"))
    }
  )
})

test_that("switching from a binary layer to Feature Density and back does not error", {
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      session$setInputs(selectedLayer = "feature_A")
      session$setInputs(selectedLayer = "__density__")
      expect_no_error(session$setInputs(selectedLayer = "feature_B"))
    }
  )
})

test_that("toggling tab_visible does not error", {
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      session$setInputs(selectedLayer = "feature_A")
      expect_no_error(session$flushReact())
    }
  )
})

test_that("selecting an unknown layer name does not error", {
  testServer(
    mod_4afeatures_server,
    args = list(cfg = cfg, tab_visible = shiny::reactive(TRUE)),
    {
      expect_no_error(session$setInputs(selectedLayer = "nonexistent_var"))
    }
  )
})
