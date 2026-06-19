# tests/testthat/test-config_schema.R
#
# Tests for config_schema.R:
#   get_schema_version() — exported function, returns the current schema version
#
# Design rationale
# ----------------
# get_schema_version() is a one-liner that reads .shinyplanr_schema_version
# from the package namespace. The coverage report shows line 32 (the function
# body) has 0 hits. This test exercises it directly.
#
# We test:
#   1. The return value is a positive integer scalar.
#   2. The value matches the internal constant (so a schema bump without
#      updating this test will cause a deliberate failure — acting as a
#      reminder to update documentation and migration notes).

test_that("get_schema_version() returns a positive integer scalar", {
  v <- get_schema_version()

  expect_type(v, "integer")
  expect_length(v, 1L)
  expect_true(v >= 1L)
})

test_that("get_schema_version() matches the internal .shinyplanr_schema_version constant", {
  internal_version <- shinyplanr:::.shinyplanr_schema_version

  expect_equal(get_schema_version(), internal_version)
})

test_that("get_schema_version() is consistent across repeated calls", {
  v1 <- get_schema_version()
  v2 <- get_schema_version()

  expect_equal(v1, v2)
})
