# tests/testthat/test-utils_data.R
#
# Tests for utils_data.R:
#   fformat_feature_table()   — pure data wrangling, no Shiny/spatialplanr
#   fget_category()           — pure Dict filter
#   fCheckFeatureNo()         — pure column count
#   forder_dict_categories()  — pure Dict re-ordering / factor-level assignment
#
# Design rationale
# ----------------
# All these functions are pure (data in → data out) with no Shiny reactivity
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
    nameCommon = c("Feature A", "Feature B", "Cost Layer"),
    nameVariable = c("feature_A", "feature_B", "Cost_Area"),
    category = c("Habitat", "Coral", "Cost"),
    categoryID = c("Hab", "Cor", "Cost"),
    type = c("Feature", "Feature", "Cost"),
    targetInitial = c(30, 50, NA),
    targetMin = c(0, 0, NA),
    targetMax = c(85, 85, NA),
    includeApp = c(TRUE, TRUE, TRUE),
    includeJust = c(TRUE, TRUE, TRUE),
    justification = c("Habitat A.", "Coral B.", "Equal area."),
    stringsAsFactors = FALSE
  )
}

make_tpd <- function() {
  # Typical output of spatialplanr::splnr_get_featureRep()
  data.frame(
    feature = c("feature_A", "feature_B"),
    total_amount = c(3, 2),
    absolute_held = c(2, 1),
    relative_held = c(2 / 3, 0.5),
    target = c(0.30, 0.50),
    incidental = c(FALSE, FALSE),
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
  expect_true("Category" %in% names(result))
  expect_true("Feature" %in% names(result))
  expect_true("Target (%)" %in% names(result))
  expect_true("Selected (%)" %in% names(result))
  expect_true("Incidental" %in% names(result))
})

test_that("fformat_feature_table() appends suffix to column names", {
  result <- shinyplanr:::fformat_feature_table(make_tpd(), make_dict(), suffix = " 1")

  expect_true("Target 1 (%)" %in% names(result))
  expect_true("Selected 1 (%)" %in% names(result))
  expect_true("Incidental 1" %in% names(result))
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
  prot_col <- result[["Selected (%)"]]
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
  expect_true("Coral" %in% result$Category)
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
  tpd$target[1] <- 0 # feature_A has zero target

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
  expect_true("bio_1" %in% result$feature)
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
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      crs = "EPSG:4326"
    )
  )
}

test_that("fCheckFeatureNo() counts Feature columns when Dict is supplied", {
  raw_sf <- make_raw_sf()
  Dict <- make_dict()

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

# ---------------------------------------------------------------------------
# forder_dict_categories()
# ---------------------------------------------------------------------------
#
# Builds a Dict spanning multiple `type`s and multiple categories per type,
# deliberately in an order that does NOT match either the master type order
# or alphabetical categoryID, so that a passing test can only be explained by
# forder_dict_categories() actively re-ordering rather than a coincidental
# pre-existing order.

make_multi_type_dict <- function() {
  data.frame(
    nameCommon = c(
      "Seamounts", "Corals",                # Feature: Seamt, Corals
      "Zone 1",                              # Bioregion: EnviroZone
      "Equal Area Cost",                     # Cost: Cost
      "SST Trend",                           # Climate: Climate
      "MPA (in)",                            # LockIn: MPAs
      "Shipping (out)",                      # LockOut: Shipping
      "Fish Biomass"                         # EcosystemServices: FishBio
    ),
    nameVariable = c(
      "seamounts", "corals",
      "zone_1",
      "cost_area",
      "sst_trend",
      "mpas",
      "shipping",
      "fish_biomass"
    ),
    category = c(
      "Seamounts", "Deep-sea Corals",
      "Environmental Zones",
      "Cost",
      "Climate",
      "Protected Areas",
      "Shipping Exclusions",
      "Ecosystem Services"
    ),
    categoryID = c(
      "Seamt", "Corals",
      "EnviroZone",
      "Cost",
      "Climate",
      "MPAs",
      "Shipping",
      "FishBio"
    ),
    type = c(
      "Feature", "Feature",
      "Bioregion",
      "Cost",
      "Climate",
      "LockIn",
      "LockOut",
      "EcosystemServices"
    ),
    targetInitial = c(30, 30, 30, NA, NA, NA, NA, NA),
    targetMin = c(0, 0, 0, NA, NA, NA, NA, NA),
    targetMax = c(85, 85, 85, NA, NA, NA, NA, NA),
    includeApp = TRUE,
    includeJust = TRUE,
    justification = "Stub.",
    stringsAsFactors = FALSE
  )
}

test_that("forder_dict_categories() converts category to an ordered factor", {
  Dict <- make_multi_type_dict()
  result <- shinyplanr:::forder_dict_categories(Dict)

  expect_s3_class(result$category, "factor")
  expect_true(is.ordered(result$category))
})

test_that("forder_dict_categories() orders categories by master type order (Feature < Bioregion < Cost < Climate < LockIn < LockOut < EcosystemServices)", {
  Dict <- make_multi_type_dict()
  result <- shinyplanr:::forder_dict_categories(Dict)

  type_order_by_row <- result$type[order(as.integer(result$category))]
  # Deduplicate consecutive types to get the sequence of first-appearance types
  first_appearance_types <- unique(type_order_by_row)

  expect_equal(
    first_appearance_types,
    c("Feature", "Bioregion", "Cost", "Climate", "LockIn", "LockOut", "EcosystemServices")
  )
})

test_that("forder_dict_categories() re-arranges Dict rows to match the factor level order", {
  Dict <- make_multi_type_dict()
  result <- shinyplanr:::forder_dict_categories(Dict)

  # Rows should now be grouped by type in master order: Feature rows first,
  # then Bioregion, then Cost, etc.
  expect_equal(
    as.character(result$type),
    c("Feature", "Feature", "Bioregion", "Cost", "Climate", "LockIn", "LockOut", "EcosystemServices")
  )
})

test_that("forder_dict_categories() orders categories within a type alphabetically by categoryID when categoryOrder is absent", {
  Dict <- make_multi_type_dict()
  # Add a second Feature category whose categoryID alphabetically precedes
  # "Corals" and "Seamt" -- "Abyssal" should come first among Feature rows.
  extra <- data.frame(
    nameCommon = "Abyssal Plains", nameVariable = "abyssal_plains",
    category = "Geomorphology", categoryID = "Abyssal", type = "Feature",
    targetInitial = 30, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE, justification = "Stub.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, extra)

  result <- shinyplanr:::forder_dict_categories(Dict2)
  feature_rows <- result[result$type == "Feature", ]

  # Alphabetical categoryID order: Abyssal < Corals < Seamt
  expect_equal(
    as.character(unique(feature_rows$category)),
    c("Geomorphology", "Deep-sea Corals", "Seamounts")
  )
})

test_that("forder_dict_categories() uses categoryOrder (numeric) over categoryID when present", {
  Dict <- make_multi_type_dict()
  # Assign categoryOrder so that "Seamounts" (categoryID "Seamt", alphabetically
  # last of the two Feature categories) is forced to come FIRST.
  Dict$categoryOrder <- NA_real_
  Dict$categoryOrder[Dict$category == "Seamounts"] <- 1
  Dict$categoryOrder[Dict$category == "Deep-sea Corals"] <- 2

  result <- shinyplanr:::forder_dict_categories(Dict)
  feature_rows <- result[result$type == "Feature", ]

  expect_equal(
    as.character(unique(feature_rows$category)),
    c("Seamounts", "Deep-sea Corals")
  )
})

test_that("forder_dict_categories() sorts categoryOrder numerically, not lexicographically", {
  Dict <- make_multi_type_dict()
  extra <- data.frame(
    nameCommon = c("A", "B", "C"),
    nameVariable = c("feat_a", "feat_b", "feat_c"),
    category = c("Cat A", "Cat B", "Cat C"),
    categoryID = c("A", "B", "C"),
    type = "Feature",
    targetInitial = 30, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE, justification = "Stub.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, extra)
  # Numeric order should be 2, 10 (not lexicographic "10" < "2")
  Dict2$categoryOrder <- NA_real_
  Dict2$categoryOrder[Dict2$category == "Seamounts"] <- 10
  Dict2$categoryOrder[Dict2$category == "Deep-sea Corals"] <- 2
  Dict2$categoryOrder[Dict2$category == "Cat A"] <- 1

  result <- shinyplanr:::forder_dict_categories(Dict2)
  feature_cats <- as.character(unique(result$category[result$type == "Feature"]))

  # "Cat A" (1) < "Deep-sea Corals" (2) < "Seamounts" (10); "Cat B"/"Cat C"
  # have no categoryOrder so fall back to categoryID and sort after.
  expect_equal(feature_cats[1:3], c("Cat A", "Deep-sea Corals", "Seamounts"))
})

test_that("forder_dict_categories() appends types outside the master order (e.g. Justification) without dropping rows", {
  Dict <- make_multi_type_dict()
  extra <- data.frame(
    nameCommon = "Note", nameVariable = "note_var",
    category = "Notes", categoryID = "Notes", type = "Justification",
    targetInitial = NA, targetMin = NA, targetMax = NA,
    includeApp = TRUE, includeJust = TRUE, justification = "Just a note.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, extra)

  result <- shinyplanr:::forder_dict_categories(Dict2)

  # No rows dropped
  expect_equal(nrow(result), nrow(Dict2))
  # "Justification" is not NA in the category factor levels
  expect_false(anyNA(result$category))
  # Justification appears after all known master-order types
  last_type <- as.character(tail(result$type, 1))
  expect_equal(last_type, "Justification")
})

test_that("forder_dict_categories() preserves original row order as a tiebreak within a category", {
  Dict <- make_multi_type_dict()
  # Add a second row to an existing category ("Seamounts") to confirm
  # feature-level (within-category) order is untouched.
  extra <- data.frame(
    nameCommon = "Knolls", nameVariable = "knolls",
    category = "Seamounts", categoryID = "Seamt", type = "Feature",
    targetInitial = 30, targetMin = 0, targetMax = 85,
    includeApp = TRUE, includeJust = TRUE, justification = "Stub.",
    stringsAsFactors = FALSE
  )
  Dict2 <- rbind(Dict, extra)

  result <- shinyplanr:::forder_dict_categories(Dict2)
  seamount_rows <- result[result$category == "Seamounts", ]

  expect_equal(seamount_rows$nameVariable, c("seamounts", "knolls"))
})
