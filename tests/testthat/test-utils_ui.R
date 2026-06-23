# tests/testthat/test-utils_ui.R
#
# Tests for utils_ui.R:
#   fcreate_vars()            — pure data wrangling, no Shiny session needed
#   fcreate_check()           — pure data wrangling, no Shiny session needed
#   fcustom_sliderCategory()  — returns Shiny tag lists; testable without a
#                               running Shiny session because tag construction
#                               is pure R
#
# Design rationale
# ----------------
# All three functions build UI metadata or Shiny tag objects from plain data
# frames. They have no reactive dependencies and no side-effects, so they can
# be called directly in tests.
#
# fcustom_slider() and fcustom_checkCategory() are also pure but are already
# exercised indirectly through fcustom_sliderCategory() and
# fcustom_checkCategory() respectively.
#
# Coverage gap (94.3%): the byCategory = TRUE branch of
# fcustom_sliderCategory() (lines ~191-201) has 0 hits. The fcreate_vars()
# byCategory path (lines ~52-62) is also uncovered. These tests close both
# gaps.

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

make_dict_ui <- function() {
  data.frame(
    nameCommon = c("Feature A", "Feature B", "Feature C"),
    nameVariable = c("feature_A", "feature_B", "feature_C"),
    category = c("Habitat", "Habitat", "Coral"),
    categoryID = c("Hab", "Hab", "Cor"),
    type = c("Feature", "Feature", "Feature"),
    targetInitial = c(30L, 40L, 50L),
    targetMin = c(0L, 0L, 0L),
    targetMax = c(85L, 85L, 85L),
    includeApp = c(TRUE, TRUE, TRUE),
    includeJust = c(TRUE, TRUE, TRUE),
    justification = c("A.", "B.", "C."),
    stringsAsFactors = FALSE
  )
}

make_dict_lock <- function() {
  data.frame(
    nameCommon = c("MPAs", "Reserves"),
    nameVariable = c("mpas", "reserves"),
    category = c("Protected", "Protected"),
    categoryID = c("Prot", "Prot"),
    type = c("LockIn", "LockIn"),
    targetInitial = c(NA_real_, NA_real_),
    targetMin = c(NA_real_, NA_real_),
    targetMax = c(NA_real_, NA_real_),
    includeApp = c(TRUE, TRUE),
    includeJust = c(FALSE, FALSE),
    justification = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# fcreate_vars() — basic structure
# ---------------------------------------------------------------------------

test_that("fcreate_vars() returns a data frame with expected columns (no category)", {
  result <- shinyplanr:::fcreate_vars(
    id         = "mod1",
    Dict       = make_dict_ui(),
    name_check = "sli_"
  )

  expect_s3_class(result, "data.frame")
  expect_true("id" %in% names(result))
  expect_true("id_in" %in% names(result))
  expect_true("nameCommon" %in% names(result))
  expect_true("targetMin" %in% names(result))
  expect_true("targetMax" %in% names(result))
  expect_true("targetInitial" %in% names(result))
  # category columns should NOT be present when categoryOut = FALSE
  expect_false("category" %in% names(result))
  expect_false("categoryID" %in% names(result))
})

test_that("fcreate_vars() builds correct id_in values", {
  result <- shinyplanr:::fcreate_vars(
    id         = "mod1",
    Dict       = make_dict_ui(),
    name_check = "sli_"
  )

  expect_true("sli_feature_A" %in% result$id_in)
  expect_true("sli_feature_B" %in% result$id_in)
  expect_true("sli_feature_C" %in% result$id_in)
})

test_that("fcreate_vars() filters to the requested dataType", {
  Dict <- make_dict_ui()
  # Add a Cost row that should be excluded when dataType = "Feature"
  Dict <- rbind(Dict, data.frame(
    nameCommon = "Cost", nameVariable = "Cost_Area",
    category = "Cost", categoryID = "Cost",
    type = "Cost",
    targetInitial = NA_real_, targetMin = NA_real_, targetMax = NA_real_,
    includeApp = TRUE, includeJust = FALSE,
    justification = NA_character_,
    stringsAsFactors = FALSE
  ))

  result <- shinyplanr:::fcreate_vars(
    id         = "mod1",
    Dict       = Dict,
    name_check = "sli_",
    dataType   = "Feature"
  )

  expect_false("sli_Cost_Area" %in% result$id_in)
  expect_equal(nrow(result), 3L)
})

test_that("fcreate_vars() returns category columns when categoryOut = TRUE", {
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE
  )

  expect_true("category" %in% names(result))
  expect_true("categoryID" %in% names(result))
})

# ---------------------------------------------------------------------------
# fcreate_vars() — byCategory = TRUE path (the coverage gap)
# ---------------------------------------------------------------------------

test_that("fcreate_vars() with byCategory = TRUE returns one row per category", {
  # Dict has 2 Habitat features and 1 Coral feature → 2 categories
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  expect_equal(nrow(result), 2L)
  expect_setequal(result$nameCommon, c("Habitat", "Coral"))
})

test_that("fcreate_vars() byCategory id_in uses master_ prefix", {
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  # id_in should be "master_sli_<categoryID>"
  expect_true(all(grepl("^master_sli_", result$id_in)))
})

test_that("fcreate_vars() byCategory targetMin is min across category features", {
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  hab_row <- result[result$nameCommon == "Habitat", ]
  # Both Habitat features have targetMin = 0
  expect_equal(hab_row$targetMin, 0L)
})

test_that("fcreate_vars() byCategory targetMax is max across category features", {
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  hab_row <- result[result$nameCommon == "Habitat", ]
  # Both Habitat features have targetMax = 85
  expect_equal(hab_row$targetMax, 85L)
})

test_that("fcreate_vars() byCategory targetInitial is rounded mean across category", {
  result <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  hab_row <- result[result$nameCommon == "Habitat", ]
  # Habitat features: targetInitial = 30, 40 → mean = 35
  expect_equal(hab_row$targetInitial, 35L)
})

# ---------------------------------------------------------------------------
# fcreate_check() — basic structure
# ---------------------------------------------------------------------------

test_that("fcreate_check() returns a data frame with expected columns (no category)", {
  result <- shinyplanr:::fcreate_check(
    id         = "mod1",
    Dict       = make_dict_lock(),
    idType     = "LockIn",
    name_check = "checkLI_"
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c("id", "id_in", "nameCommon"))
})

test_that("fcreate_check() builds correct id_in values", {
  result <- shinyplanr:::fcreate_check(
    id         = "mod1",
    Dict       = make_dict_lock(),
    idType     = "LockIn",
    name_check = "checkLI_"
  )

  expect_true("checkLI_mpas" %in% result$id_in)
  expect_true("checkLI_reserves" %in% result$id_in)
})

test_that("fcreate_check() includes category column when categoryOut = TRUE", {
  result <- shinyplanr:::fcreate_check(
    id          = "mod1",
    Dict        = make_dict_lock(),
    idType      = "LockIn",
    name_check  = "checkLI_",
    categoryOut = TRUE
  )

  expect_named(result, c("id", "id_in", "nameCommon", "category"))
  expect_true("Protected" %in% result$category)
})

test_that("fcreate_check() filters to the requested idType", {
  Dict <- rbind(make_dict_lock(), data.frame(
    nameCommon = "Exclude Zone", nameVariable = "excl_zone",
    category = "Exclusion", categoryID = "Excl",
    type = "LockOut",
    targetInitial = NA_real_, targetMin = NA_real_, targetMax = NA_real_,
    includeApp = TRUE, includeJust = FALSE,
    justification = NA_character_,
    stringsAsFactors = FALSE
  ))

  result <- shinyplanr:::fcreate_check(
    id         = "mod1",
    Dict       = Dict,
    idType     = "LockIn",
    name_check = "checkLI_"
  )

  # LockOut row should not appear
  expect_false("checkLI_excl_zone" %in% result$id_in)
  expect_equal(nrow(result), 2L)
})

# ---------------------------------------------------------------------------
# fcustom_sliderCategory() — NULL / empty guard
# ---------------------------------------------------------------------------

test_that("fcustom_sliderCategory() returns NULL when varsIn is NULL", {
  result <- shinyplanr:::fcustom_sliderCategory(NULL, labelNum = 1)
  expect_null(result)
})

test_that("fcustom_sliderCategory() returns NULL when varsIn has 0 rows", {
  empty <- make_dict_ui()[0, ] # 0-row data frame with correct columns
  result <- shinyplanr:::fcustom_sliderCategory(empty, labelNum = 1)
  expect_null(result)
})

# ---------------------------------------------------------------------------
# fcustom_sliderCategory() — byCategory = FALSE (default path)
# ---------------------------------------------------------------------------

test_that("fcustom_sliderCategory() returns a list when byCategory = FALSE", {
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(vars, labelNum = 1, byCategory = FALSE)

  expect_type(result, "list")
  # 2 categories × 2 entries (header + sliders) = 4 list elements
  expect_length(result, 4L)
})

test_that("fcustom_sliderCategory() labelCategory = FALSE uses invisible spacer", {
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(
    vars,
    labelNum = 1, byCategory = FALSE, labelCategory = FALSE
  )

  # shiny::HTML() returns class c("html", "character"), not "shiny.tag".
  # The odd-indexed elements should be raw HTML spacers.
  header_el <- result[[1]]
  expect_true(inherits(header_el, "html"))
})

# ---------------------------------------------------------------------------
# fcustom_sliderCategory() — byCategory = TRUE (the coverage gap)
# ---------------------------------------------------------------------------

test_that("fcustom_sliderCategory() returns a list when byCategory = TRUE", {
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(vars, labelNum = 1, byCategory = TRUE)

  expect_type(result, "list")
})

test_that("fcustom_sliderCategory() byCategory = TRUE returns one entry per category", {
  # Dict has 2 categories (Habitat, Coral) → 2 master sliders
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(vars, labelNum = 1, byCategory = TRUE)

  # byCategory = TRUE: one list entry per category (no separate header entries)
  expect_length(result, 2L)
})

test_that("fcustom_sliderCategory() byCategory = TRUE entries are lists of slider tags", {
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(vars, labelNum = 1, byCategory = TRUE)

  # Each element is a list produced by purrr::pmap → list of shiny.tag objects
  expect_type(result[[1]], "list")
  expect_type(result[[2]], "list")
})

test_that("fcustom_sliderCategory() byCategory = TRUE slider ids use master_ prefix", {
  vars <- shinyplanr:::fcreate_vars(
    id          = "mod1",
    Dict        = make_dict_ui(),
    name_check  = "sli_",
    categoryOut = TRUE,
    byCategory  = TRUE
  )

  result <- shinyplanr:::fcustom_sliderCategory(vars, labelNum = 1, byCategory = TRUE)

  # Each element of result is a list (from purrr::pmap) of sliderInput div tags.
  # sliderInput wraps everything in a div; the label child has
  # attribs$id = "<namespace>-<id_in>-label".  We extract those label ids to
  # confirm the master_ prefix is present.
  all_slider_divs <- unlist(result, recursive = FALSE)
  label_ids <- vapply(all_slider_divs, function(tag) {
    # The label is the first child of the outer div
    tag$children[[1]]$attribs$id
  }, character(1))
  expect_true(all(grepl("master_sli_", label_ids)))
})
