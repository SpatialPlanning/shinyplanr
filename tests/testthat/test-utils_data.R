# tests/testthat/test-utils_data.R
#
# Tests for utils_data.R:
#   fformat_feature_table()  — pure data wrangling, no Shiny/spatialplanr
#   fget_category()          — pure Dict filter
#   fCheckFeatureNo()        — pure column count
#
# Design rationale
# ----------------
# All three functions are pure (data in → data out) with no Shiny reactivity
# or external solver dependency. They can be fully unit-tested with synthetic
# data frames and sf objects.
#
# fget_targets() and fget_targets_with_bioregions() are already tested in
# test-utils_server.R (the file predates the rename of the test file).
# fget_feature_representation() requires a solved prioritizr problem and is
# excluded from unit tests here.

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

make_dict <- function() {
  data.frame(
    nameCommon    = c("Feature A", "Feature B", "Cost Layer"),
    nameVariable  = c("feature_A", "feature_B", "Cost_Area"),
    category      = c("Habitat", "Coral", "Cost"),
    categoryID    = c("Hab", "Cor", "Cost"),
    type          = c("Feature", "Feature", "Cost"),
    targetInitial = c(30, 50, NA),
    targetMin     = c(0, 0, NA),
    targetMax     = c(85, 85, NA),
    includeApp    = c(TRUE, TRUE, TRUE),
    includeJust   = c(TRUE, TRUE, TRUE),
    justification = c("Habitat A.", "Coral B.", "Equal area."),
    stringsAsFactors = FALSE
  )
}

make_tpd <- function() {
  # Typical output of spatialplanr::splnr_get_featureRep()
  data.frame(
    feature       = c("feature_A", "feature_B"),
    total_amount  = c(3, 2),
    absolute_held = c(2, 1),
    relative_held = c(2 / 3, 0.5),
    target        = c(0.30, 0.50),
    incidental    = c(FALSE, FALSE),
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------
# fformat_feature_table() — NULL input
# ---------------------------------------------------------------------------

test_that("fformat_feature_table() returns NULL when tpd is NULL", {
  result <- shinyplanr:::fformat_feature_table(NULL, make_dict())
  expect_null(result)
})

# ---------------------------------------------------------------------------
# fformat_feature_table() — structure
# ---------------------------------------------------------------------------

test_that("fformat_feature_table() returns a data frame with expected columns (no suffix)", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  expect_s3_class(result, "data.frame")
  expect_true("Category"        %in% names(result))
  expect_true("Feature"         %in% names(result))
  expect_true("Target (%)"      %in% names(result))
  expect_true("Protection (%)"  %in% names(result))
  expect_true("Incidental"      %in% names(result))
})

test_that("fformat_feature_table() appends suffix to column names", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict(), suffix = " 1")

  expect_true("Target 1 (%)"     %in% names(result))
  expect_true("Protection 1 (%)" %in% names(result))
  expect_true("Incidental 1"     %in% names(result))
})

test_that("fformat_feature_table() returns correct number of rows", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())
  expect_equal(nrow(result), 2L)
})

# ---------------------------------------------------------------------------
# fformat_feature_table() — value correctness
# ---------------------------------------------------------------------------

test_that("fformat_feature_table() converts relative_held to integer percentage", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  # relative_held = 2/3 ≈ 0.667 → 67%
  prot_col <- result[["Protection (%)"]]
  expect_type(prot_col, "integer")
  expect_equal(prot_col[result$Feature == "Feature A"], 67L)
})

test_that("fformat_feature_table() converts target to integer percentage", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  tgt_col <- result[["Target (%)"]]
  expect_type(tgt_col, "integer")
  expect_equal(tgt_col[result$Feature == "Feature A"], 30L)
  expect_equal(tgt_col[result$Feature == "Feature B"], 50L)
})

test_that("fformat_feature_table() replaces nameVariable with nameCommon", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  # nameVariable values should NOT appear in Feature column
  expect_false(any(c("feature_A", "feature_B") %in% result$Feature))
  # nameCommon values SHOULD appear
  expect_true("Feature A" %in% result$Feature)
  expect_true("Feature B" %in% result$Feature)
})

test_that("fformat_feature_table() adds Category column from Dict", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  expect_true("Habitat" %in% result$Category)
  expect_true("Coral"   %in% result$Category)
})

test_that("fformat_feature_table() sorts by Category then Feature", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  # Coral < Habitat alphabetically
  expect_equal(result$Category[1], "Coral")
  expect_equal(result$Category[2], "Habitat")
})

# ---------------------------------------------------------------------------
# fformat_feature_table() — zero-target → incidental
# ---------------------------------------------------------------------------

test_that("fformat_feature_table() marks zero-target features as incidental", {
  tpd <- make_tpd()
  tpd$target[1] <- 0  # feature_A has zero target

  result <- shinyplanr:::fformat_feature_table(tpd, make_dict())

  row_A <- result[result$Feature == "Feature A", ]
  expect_true(row_A$Incidental)
})

test_that("fformat_feature_table() does not mark non-zero-target features as incidental", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict())

  row_B <- result[result$Feature == "Feature B", ]
  expect_false(row_B$Incidental)
})

# ---------------------------------------------------------------------------
# fget_category()
# ---------------------------------------------------------------------------

test_that("fget_category() returns a data frame with feature and category columns", {
  result <- shinyplanr:::fget_category(make_dict())

  expect_s3_class(result, "data.frame")
  expect_named(result, c("feature", "category"))
})

test_that("fget_category() filters to Feature and Bioregion types only", {
  Dict <- make_dict()
  # Add a Bioregion row
  bio_row <- data.frame(
    nameCommon = "Bio 1", nameVariable = "bio_1",
    category = "Bioregion", categoryID = "Bio",
    type = "Bioregion",
    targetInitial = 40, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE,
    justification = "Bio.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, bio_row)

  result <- shinyplanr:::fget_category(Dict2)

  # Should include Feature and Bioregion rows, but NOT Cost
  expect_true("feature_A" %in% result$feature)
  expect_true("bio_1"     %in% result$feature)
  expect_false("Cost_Area" %in% result$feature)
})

test_that("fget_category() renames nameVariable to feature", {
  result <- shinyplanr:::fget_category(make_dict())

  expect_true("feature_A" %in% result$feature)
  expect_true("feature_B" %in% result$feature)
})

test_that("fget_category() returns correct category values", {
  result <- shinyplanr:::fget_category(make_dict())

  expect_equal(
    result$category[result$feature == "feature_A"],
    "Habitat"
  )
  expect_equal(
    result$category[result$feature == "feature_B"],
    "Coral"
  )
})

# ---------------------------------------------------------------------------
# fCheckFeatureNo() — with Dict
# ---------------------------------------------------------------------------

make_raw_sf <- function() {
  sf::st_sf(
    feature_A = c(1, 0),
    feature_B = c(0, 1),
    Cost_Area = c(1, 1),
    geometry  = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
}

test_that("fCheckFeatureNo() counts Feature columns when Dict is supplied", {
  raw_sf <- make_raw_sf()
  Dict   <- make_dict()

  result <- shinyplanr:::fCheckFeatureNo(raw_sf, Dict)

  # Dict has 2 Feature rows (feature_A, feature_B); Cost_Area is type "Cost"
  expect_equal(result, 2L)
})

test_that("fCheckFeatureNo() counts Bioregion columns when Dict has Bioregion type", {
  raw_sf <- make_raw_sf()
  raw_sf$bio_1 <- c(1, 0)

  Dict <- make_dict()
  bio_row <- data.frame(
    nameCommon = "Bio 1", nameVariable = "bio_1",
    category = "Bioregion", categoryID = "Bio",
    type = "Bioregion",
    targetInitial = 40, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE,
    justification = "Bio.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, bio_row)

  result <- shinyplanr:::fCheckFeatureNo(raw_sf, Dict2)

  # 2 Feature + 1 Bioregion = 3
  expect_equal(result, 3L)
})

# ---------------------------------------------------------------------------
# fCheckFeatureNo() — legacy fallback (no Dict)
# ---------------------------------------------------------------------------

test_that("fCheckFeatureNo() uses legacy fallback when Dict is NULL", {
  raw_sf <- make_raw_sf()
  # Without Dict: excludes Cost_ prefix columns and "metric" column
  # Columns: feature_A, feature_B, Cost_Area → after exclusion: feature_A, feature_B = 2
  result <- shinyplanr:::fCheckFeatureNo(raw_sf, Dict = NULL)

  expect_equal(result, 2L)
})

test_that("fCheckFeatureNo() legacy fallback excludes 'metric' column", {
  raw_sf <- make_raw_sf()
  raw_sf$metric <- c(0.5, 0.3)

  result <- shinyplanr:::fCheckFeatureNo(raw_sf, Dict = NULL)

  # feature_A, feature_B only (Cost_Area and metric excluded)
  expect_equal(result, 2L)
})

test_that("fCheckFeatureNo() works on a plain data frame (no geometry)", {
  df <- data.frame(feature_A = c(1, 0), feature_B = c(0, 1))
  Dict <- data.frame(
    nameVariable = c("feature_A", "feature_B"),
    type = c("Feature", "Feature"),
    stringsAsFactors = FALSE
  )

  # st_drop_geometry on a plain data frame is a no-op
  result <- shinyplanr:::fCheckFeatureNo(df, Dict)

  expect_equal(result, 2L)
})
