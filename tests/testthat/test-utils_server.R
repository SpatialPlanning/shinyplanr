# tests/testthat/test-utils_server.R
#
# Tests for utility server functions:
#   fget_targets(), fget_targets_with_bioregions(), fget_feature_representation()
#
# Uses lightweight synthetic data — no Shiny session or prioritizr solve required.

# ---------------------------------------------------------------------------
# Shared test data
# ---------------------------------------------------------------------------

make_test_dict <- function() {
  data.frame(
    nameCommon    = c("Feature A", "Feature B", "Cost Layer"),
    nameVariable  = c("feature_A", "feature_B", "Cost_Area"),
    category      = c("Habitat", "Habitat", "Cost"),
    categoryID    = c("Hab", "Hab", "Cost"),
    type          = c("Feature", "Feature", "Cost"),
    targetInitial = c(30, 50, NA),
    targetMin     = c(0, 0, NA),
    targetMax     = c(85, 85, NA),
    includeApp    = c(TRUE, TRUE, TRUE),
    includeJust   = c(TRUE, TRUE, TRUE),
    units         = c("", "", ""),
    justification = c("Habitat A.", "Habitat B.", "Equal area cost."),
    stringsAsFactors = FALSE
  )
}

make_test_dict_with_bioregion <- function() {
  data.frame(
    nameCommon    = c("Feature A", "Bioregion 1"),
    nameVariable  = c("feature_A", "bio_1"),
    category      = c("Habitat", "Bioregion"),
    categoryID    = c("Hab", "Bio"),
    type          = c("Feature", "Bioregion"),
    targetInitial = c(30, 40),
    targetMin     = c(0, 0),
    targetMax     = c(85, 85),
    includeApp    = c(TRUE, TRUE),
    includeJust   = c(TRUE, TRUE),
    units         = c("", ""),
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

  result <- shinyplanr:::fget_targets(input = input, Dict = Dict, name_check = "sli_",
                                      dataType = "Feature")

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  expect_equal(nrow(result), 2L)
  expect_true(all(result$target >= 0 & result$target <= 1))
})

test_that("fget_targets() divides slider values by 100", {
  Dict <- make_test_dict()
  input <- list(sli_feature_A = 30, sli_feature_B = 50)

  result <- shinyplanr:::fget_targets(input = input, Dict = Dict, name_check = "sli_")

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

  result <- shinyplanr:::fget_targets(input = input, Dict = Dict,
                                       name_check = "sli_", dataType = "Cost")

  expect_equal(nrow(result), 1L)
  expect_equal(result$feature, "Cost_Area")
})

# ---------------------------------------------------------------------------
# fget_targets_with_bioregions()
# ---------------------------------------------------------------------------

test_that("fget_targets_with_bioregions() returns only features when no bioregions in Dict", {
  Dict <- make_test_dict()
  input <- list(sli_feature_A = 30, sli_feature_B = 50)

  result <- shinyplanr:::fget_targets_with_bioregions(input = input, name_check = "sli_",
                                                       Dict = Dict)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  expect_equal(nrow(result), 2L)
})

test_that("fget_targets_with_bioregions() appends bioregion rows when Dict has Bioregion type", {
  Dict <- make_test_dict_with_bioregion()
  # Feature slider + bioregion slider (uses master_ prefix inside function)
  input <- list(
    sli_feature_A     = 30,
    master_sli_Bio    = 40   # bioregion slider uses categoryID
  )

  result <- shinyplanr:::fget_targets_with_bioregions(input = input, name_check = "sli_",
                                                       Dict = Dict)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "target"))
  # Should have 1 feature + 1 bioregion
  expect_equal(nrow(result), 2L)
  expect_true("bio_1" %in% result$feature)
  expect_equal(result$target[result$feature == "bio_1"], 0.40)
})

# ---------------------------------------------------------------------------
# fget_feature_representation()
# ---------------------------------------------------------------------------

test_that("fget_feature_representation() returns NULL when solution is not an sf object", {
  Dict <- make_test_dict()

  result <- shinyplanr:::fget_feature_representation(
    soln         = NULL,
    problem_data = NULL,
    targets      = data.frame(feature = "feature_A", target = 0.3),
    climate_id   = "NA",
    options      = list(climate_change = 0L),
    Dict         = Dict
  )

  expect_null(result)
})

test_that("fget_feature_representation() returns NULL for a non-sf character input", {
  Dict <- make_test_dict()

  result <- shinyplanr:::fget_feature_representation(
    soln         = "not_an_sf",
    problem_data = NULL,
    targets      = data.frame(feature = "feature_A", target = 0.3),
    climate_id   = "NA",
    options      = list(climate_change = 0L),
    Dict         = Dict
  )

  expect_null(result)
})
