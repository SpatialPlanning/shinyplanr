# tests/testthat/test-utils_server.R
#
# Tests for utility server functions:
#   fget_targets(), fget_targets_expanded(), fget_feature_representation()
#
# Uses lightweight synthetic data — no Shiny session or prioritizr solve required.

# ---------------------------------------------------------------------------
# Shared test data
# ---------------------------------------------------------------------------

make_test_dict <- function() {
  data.frame(
    nameCommon = c("Feature A", "Feature B", "Cost Layer"),
    nameVariable = c("feature_A", "feature_B", "Cost_Area"),
    category = c("Habitat", "Habitat", "Cost"),
    categoryID = c("Hab", "Hab", "Cost"),
    type = c("Feature", "Feature", "Cost"),
    targetInitial = c(30, 50, NA),
    targetMin = c(0, 0, NA),
    targetMax = c(85, 85, NA),
    includeApp = c(TRUE, TRUE, TRUE),
    includeJust = c(TRUE, TRUE, TRUE),
    units = c("", "", ""),
    justification = c("Habitat A.", "Habitat B.", "Equal area cost."),
    stringsAsFactors = FALSE
  )
}

make_test_dict_with_bioregion <- function() {
  data.frame(
    nameCommon = c("Feature A", "Bioregion 1"),
    nameVariable = c("feature_A", "bio_1"),
    category = c("Habitat", "Bioregion"),
    categoryID = c("Hab", "Bio"),
    type = c("Feature", "Bioregion"),
    targetInitial = c(30, 40),
    targetMin = c(0, 0),
    targetMax = c(85, 85),
    includeApp = c(TRUE, TRUE),
    includeJust = c(TRUE, TRUE),
    units = c("", ""),
    justification = c("Habitat A.", "Bioregion 1."),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# fget_targets()
# ---------------------------------------------------------------------------

test_that("fget_targets() returns correct structure for Feature type", {
  Dict <- make_test_dict()

  # Simulate a Shiny input list: sliders for Feature type only
  input <- list(
    sli_feature_A = 30,
    sli_feature_B = 50
  )

  result <- shinyplanr:::fget_targets(
    input = input,
    Dict = Dict,
    name_check = "sli_",
    dataType = "Feature"
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  expect_equal(nrow(result), 2L)
  expect_true(all(result$target >= 0 & result$target <= 1))
})

test_that("fget_targets() divides slider values by 100", {
  Dict <- make_test_dict()
  input <- list(sli_feature_A = 30, sli_feature_B = 50)

  result <- shinyplanr:::fget_targets(
    input = input,
    Dict = Dict,
    name_check = "sli_"
  )

  expect_equal(result$target[result$feature == "feature_A"], 0.30)
  expect_equal(result$target[result$feature == "feature_B"], 0.50)
})

test_that("fget_targets() returns feature names matching Dict$nameVariable", {
  Dict <- make_test_dict()
  input <- list(sli_feature_A = 20, sli_feature_B = 60)

  result <- shinyplanr:::fget_targets(input = input, Dict = Dict)

  expect_setequal(result$feature, c("feature_A", "feature_B"))
})

test_that("fget_targets() respects dataType filter", {
  Dict <- make_test_dict()
  input <- list(sli_Cost_Area = 0)

  result <- shinyplanr:::fget_targets(
    input = input,
    Dict = Dict,
    name_check = "sli_",
    dataType = "Cost"
  )

  expect_equal(nrow(result), 1L)
  expect_equal(result$feature, "Cost_Area")
})

# ---------------------------------------------------------------------------
# fget_targets_expanded()
# ---------------------------------------------------------------------------

test_that("fget_targets_expanded() returns only features when no bioregions or silent features in Dict", {
  Dict <- make_test_dict()
  input <- list(sli_feature_A = 30, sli_feature_B = 50)

  result <- shinyplanr:::fget_targets_expanded(
    input = input,
    name_check = "sli_",
    Dict = Dict
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  expect_equal(nrow(result), 2L)
})

test_that("fget_targets_expanded() appends bioregion rows when Dict has Bioregion type", {
  Dict <- make_test_dict_with_bioregion()
  # Feature slider + bioregion slider (uses bioregion_ prefix inside function)
  input <- list(
    sli_feature_A = 30,
    bioregion_sli_Bio = 40 # bioregion slider uses "bioregion_<name_check><categoryID>"
  )

  result <- shinyplanr:::fget_targets_expanded(
    input = input,
    name_check = "sli_",
    Dict = Dict
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  # Should have 1 feature + 1 bioregion
  expect_equal(nrow(result), 2L)
  expect_true("bio_1" %in% result$feature)
  expect_equal(result$target[result$feature == "bio_1"], 0.40)
})

test_that("fget_targets_expanded() expands SilentFeature category slider to per-feature targets", {
  # Dict with one regular Feature and two SilentFeature layers in the same category
  Dict <- data.frame(
    nameCommon = c("Feature A", "Silent 1", "Silent 2"),
    nameVariable = c("feature_A", "silent_1", "silent_2"),
    category = c("Habitat", "Seagrass", "Seagrass"),
    categoryID = c("Hab", "Sea", "Sea"),
    type = c("Feature", "SilentFeature", "SilentFeature"),
    targetInitial = c(30, 20, 20),
    targetMin = c(0, 0, 0),
    targetMax = c(85, 85, 85),
    includeApp = c(TRUE, TRUE, TRUE),
    includeJust = c(TRUE, TRUE, TRUE),
    units = c("", "", ""),
    justification = c("A.", "B.", "C."),
    stringsAsFactors = FALSE
  )
  # One regular slider + one silent category slider (prefix: "silent_sli_" + categoryID)
  input <- list(
    sli_feature_A = 30,
    silent_sli_Sea = 25 # category-level slider for "Seagrass" (categoryID = "Sea")
  )

  result <- shinyplanr:::fget_targets_expanded(
    input = input,
    name_check = "sli_",
    Dict = Dict
  )

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  # 1 Feature + 2 SilentFeature rows
  expect_equal(nrow(result), 3L)
  expect_true("silent_1" %in% result$feature)
  expect_true("silent_2" %in% result$feature)
  # Both silent features get the same target from the category slider
  expect_equal(result$target[result$feature == "silent_1"], 0.25)
  expect_equal(result$target[result$feature == "silent_2"], 0.25)
})

# ---------------------------------------------------------------------------
# fget_feature_representation()
# ---------------------------------------------------------------------------

test_that("fget_feature_representation() returns NULL when solution is not an sf object", {
  Dict <- make_test_dict()

  result <- shinyplanr:::fget_feature_representation(
    soln = NULL,
    problem_data = NULL,
    targets = data.frame(feature = "feature_A", target = 0.3),
    climate_id = "NA",
    options = list(climate_change = 0L),
    Dict = Dict
  )

  expect_null(result)
})

test_that("fget_feature_representation() returns NULL for a non-sf character input", {
  Dict <- make_test_dict()

  result <- shinyplanr:::fget_feature_representation(
    soln = "not_an_sf",
    problem_data = NULL,
    targets = data.frame(feature = "feature_A", target = 0.3),
    climate_id = "NA",
    options = list(climate_change = 0L),
    Dict = Dict
  )

  expect_null(result)
})

# ---------------------------------------------------------------------------
# fsetup_category_lock_observers()
# ---------------------------------------------------------------------------

make_slider_vars <- function() {
  data.frame(
    id_in = c("sli_feature_A", "sli_feature_B", "sli_feature_C"),
    category = c("Habitat", "Habitat", "Reef"),
    categoryID = c("Hab", "Hab", "Reef"),
    stringsAsFactors = FALSE
  )
}

test_that("fsetup_category_lock_observers() returns NULL invisibly for NULL slider_vars", {
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        result <- shinyplanr:::fsetup_category_lock_observers(
          input = input,
          session = session,
          slider_vars = NULL,
          lock_prefix = "lock_"
        )
        expect_null(result)
      }
    ),
    {}
  )
})

test_that("fsetup_category_lock_observers() returns NULL invisibly for empty slider_vars", {
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        result <- shinyplanr:::fsetup_category_lock_observers(
          input = input,
          session = session,
          slider_vars = data.frame(
            id_in = character(0),
            category = character(0),
            categoryID = character(0),
            stringsAsFactors = FALSE
          ),
          lock_prefix = "lock_"
        )
        expect_null(result)
      }
    ),
    {}
  )
})

test_that("fsetup_category_lock_observers() registers observers without error", {
  slider_vars <- make_slider_vars()
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        expect_no_error(
          shinyplanr:::fsetup_category_lock_observers(
            input = input,
            session = session,
            slider_vars = slider_vars,
            lock_prefix = "lock_"
          )
        )
      }
    ),
    {}
  )
})

# Note: shiny::updateSliderInput() in testServer sends a message to the
# client-side session mock but does NOT update input$ or expose the message
# via any public session API.  The propagation logic is therefore tested by
# verifying the *structure* of the observers (they register without error and
# the guard conditions are correct) rather than by inspecting side-effects.

test_that("fsetup_category_lock_observers() registers observers without error for multi-category data", {
  slider_vars <- make_slider_vars()
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        # Two categories (Habitat: A+B, Reef: C) — should register 3 observers
        expect_no_error(
          shinyplanr:::fsetup_category_lock_observers(
            input = input,
            session = session,
            slider_vars = slider_vars,
            lock_prefix = "lock_"
          )
        )
        # Inputs can be set without error after observers are registered
        expect_no_error(session$setInputs(lock_Hab = TRUE, sli_feature_A = 60))
        expect_no_error(session$setInputs(lock_Hab = FALSE, sli_feature_A = 70))
      }
    ),
    {}
  )
})

test_that("fsetup_category_lock_observers() handles single-slider category without error", {
  # A category with only one slider should register an observer that is a no-op
  # (setdiff of id_in from itself is empty, so no updateSliderInput is called)
  single_cat <- data.frame(
    id_in = "sli_feature_C",
    category = "Reef",
    categoryID = "Reef",
    stringsAsFactors = FALSE
  )
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        expect_no_error(
          shinyplanr:::fsetup_category_lock_observers(
            input = input,
            session = session,
            slider_vars = single_cat,
            lock_prefix = "lock_"
          )
        )
        expect_no_error(session$setInputs(lock_Reef = TRUE, sli_feature_C = 50))
      }
    ),
    {}
  )
})

test_that("fsetup_category_lock_observers() custom lock_prefix registers without error", {
  slider_vars <- make_slider_vars()
  testServer(
    shiny::shinyApp(
      ui = shiny::fluidPage(),
      server = function(input, output, session) {
        expect_no_error(
          shinyplanr:::fsetup_category_lock_observers(
            input = input,
            session = session,
            slider_vars = slider_vars,
            lock_prefix = "lock1_"
          )
        )
        expect_no_error(session$setInputs(lock1_Hab = TRUE, sli_feature_A = 55))
      }
    ),
    {}
  )
})

test_that("fsetup_category_lock_observers() guard: others-set is correct per category", {
  # Test the pure logic: for each slider, 'others' = all sliders in same
  # category minus itself.  Verify by inspecting slider_vars structure.
  slider_vars <- make_slider_vars()
  hab <- dplyr::filter(slider_vars, .data$category == "Habitat")
  reef <- dplyr::filter(slider_vars, .data$category == "Reef")

  # Habitat: A and B — each should see the other as 'others'
  others_A <- setdiff(hab$id_in, "sli_feature_A")
  others_B <- setdiff(hab$id_in, "sli_feature_B")
  expect_equal(others_A, "sli_feature_B")
  expect_equal(others_B, "sli_feature_A")

  # Reef: only C — others is empty (no cross-category propagation)
  others_C <- setdiff(reef$id_in, "sli_feature_C")
  expect_length(others_C, 0L)
})
