# tests/testthat/test-solvers.R
#
# Tests for fsolve_problem(), fsolve_with_log(), and fdefine_problem().
# All three are internal (@noRd) functions accessed via :::.
#
# Key constraint: fsolve_problem() and fdefine_problem() call
#   shinyalert::shinyalert(callbackR = shinyjs::runjs(...))
# R evaluates callbackR eagerly (before shinyalert is called), so
# shinyjs::runjs fires immediately and crashes outside a Shiny session.
# We mock both shinyjs::runjs and shinyalert::shinyalert for the entire
# file using local_mocked_bindings() at the top level of each test.
# A helper wraps this so every test gets the mocks automatically.

# ---------------------------------------------------------------------------
# Skip entire file if no solver backend is available.
# prioritizr::add_default_solver() requires at least one of: highs, gurobi,
# rcbc, cplexAPI, lpsymphony, Rsymphony.  Without any solver the tests cannot
# run and would produce misleading failures.
# ---------------------------------------------------------------------------
solver_available <- any(vapply(
  c("highs", "gurobi", "rcbc", "cplexAPI", "lpsymphony", "Rsymphony"),
  requireNamespace, logical(1L),
  quietly = TRUE
))
if (!solver_available) {
  skip("No solver backend available (need highs, gurobi, rcbc, or similar)")
}

# ---------------------------------------------------------------------------
# Shared test fixtures
# ---------------------------------------------------------------------------

# 4-cell square grid in ESRI:54009 with binary features and a cost column
make_test_sf <- function() {
  sf::st_sf(
    feature_A = c(1, 0, 1, 0),
    feature_B = c(0, 1, 1, 0),
    Cost_Area = c(1, 1, 2, 1),
    geometry = sf::st_sfc(
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(0, 0, 1, 1, 0)))),
      sf::st_polygon(list(cbind(c(0, 1, 1, 0, 0), c(1, 1, 2, 2, 1)))),
      sf::st_polygon(list(cbind(c(1, 2, 2, 1, 1), c(1, 1, 2, 2, 1)))),
      crs = "ESRI:54009"
    )
  )
}

# Minimal prioritizr min_set problem (2 features, 4 PUs).
# Two features are required: prioritizr::presolve_check() rejects single-feature
# problems as ecologically meaningless, causing fsolve_problem() to return NULL.
# Uses add_default_solver() so the tests run with whatever solver is installed
# (highs, gurobi, rcbc, etc.) without requiring a specific backend.
make_test_problem <- function(raw_sf = make_test_sf()) {
  prioritizr::problem(
    x           = raw_sf,
    features    = c("feature_A", "feature_B"),
    cost_column = "Cost_Area"
  ) |>
    prioritizr::add_min_set_objective() |>
    prioritizr::add_relative_targets(0.5) |>
    prioritizr::add_binary_decisions() |>
    prioritizr::add_default_solver(verbose = FALSE)
}

# Helper: run expr with shinyjs::runjs and shinyalert::shinyalert mocked.
# Returns a list(result = ..., alert_called = logical).
with_shiny_mocks <- function(expr, capture_alert = FALSE) {
  alert_called <- FALSE
  local_mocked_bindings(
    runjs      = function(...) invisible(NULL),
    .package   = "shinyjs"
  )
  local_mocked_bindings(
    shinyalert = function(...) {
      alert_called <<- TRUE
      invisible(NULL)
    },
    .package = "shinyalert"
  )
  result <- force(expr)
  list(result = result, alert_called = alert_called)
}

# ---------------------------------------------------------------------------
# fsolve_problem() — happy path
# ---------------------------------------------------------------------------

test_that("fsolve_problem() returns an sf object for a feasible problem", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  sol <- shinyplanr:::fsolve_problem(prob)

  expect_s3_class(sol, "sf")
  expect_true("solution_1" %in% names(sol))
  expect_true(all(sol$solution_1 %in% c(0, 1)))
})

test_that("fsolve_problem() solution selects at least one planning unit", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  sol <- shinyplanr:::fsolve_problem(prob)

  expect_gt(sum(sol$solution_1), 0)
})

# ---------------------------------------------------------------------------
# fsolve_problem() — presolve failure path
# ---------------------------------------------------------------------------

test_that("fsolve_problem() returns NULL and calls shinyalert when presolve fails", {
  # All-zero feature columns — prioritizr presolve_check will flag this.
  # Both features must be zeroed: a single-feature problem also fails presolve,
  # so we keep two features but zero both to ensure the failure is about data
  # quality, not feature count.
  raw_sf <- make_test_sf()
  raw_sf$feature_A <- 0
  raw_sf$feature_B <- 0

  # Build problem — prioritizr warns about zero columns but still constructs it
  prob <- suppressWarnings(
    prioritizr::problem(
      x           = raw_sf,
      features    = c("feature_A", "feature_B"),
      cost_column = "Cost_Area"
    ) |>
      prioritizr::add_min_set_objective() |>
      prioritizr::add_relative_targets(0.5) |>
      prioritizr::add_binary_decisions() |>
      prioritizr::add_default_solver(verbose = FALSE)
  )

  alert_called <- FALSE
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(
    shinyalert = function(...) {
      alert_called <<- TRUE
      invisible(NULL)
    },
    .package = "shinyalert"
  )

  result <- shinyplanr:::fsolve_problem(prob)

  expect_null(result)
  expect_true(alert_called)
})

# ---------------------------------------------------------------------------
# fsolve_with_log() — happy path
# ---------------------------------------------------------------------------

test_that("fsolve_with_log() returns a list with 'solution' and 'log' elements", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = "Cost_Area")

  expect_type(result, "list")
  expect_named(result, c("solution", "log"))
})

test_that("fsolve_with_log() solution element is an sf object", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = "Cost_Area")

  expect_s3_class(result$solution, "sf")
})

test_that("fsolve_with_log() log contains expected sections", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = "Cost_Area")

  expect_match(result$log, "PRIORITIZR PROBLEM SETUP")
  expect_match(result$log, "SOLVE SUMMARY")
  expect_match(result$log, "Runtime:")
  expect_match(result$log, "Planning units selected:")
})

test_that("fsolve_with_log() log includes cost summary when cost_id is provided", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = "Cost_Area")

  expect_match(result$log, "Cost selected \\(Cost_Area\\)")
})

test_that("fsolve_with_log() log omits cost summary when cost_id is NULL", {
  prob <- make_test_problem()
  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = NULL)

  expect_false(grepl("Cost selected", result$log))
})

test_that("fsolve_with_log() returns NULL solution and logs failure for infeasible problem", {
  # Zero out both features so presolve_check() reliably fails.
  raw_sf <- make_test_sf()
  raw_sf$feature_A <- 0
  raw_sf$feature_B <- 0

  prob <- suppressWarnings(
    prioritizr::problem(
      x           = raw_sf,
      features    = c("feature_A", "feature_B"),
      cost_column = "Cost_Area"
    ) |>
      prioritizr::add_min_set_objective() |>
      prioritizr::add_relative_targets(0.5) |>
      prioritizr::add_binary_decisions() |>
      prioritizr::add_default_solver(verbose = FALSE)
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  result <- shinyplanr:::fsolve_with_log(prob, cost_id = "Cost_Area")

  expect_null(result$solution)
  expect_match(result$log, "No solution found|Infeasible")
})

# ---------------------------------------------------------------------------
# fdefine_problem() — min_set, no climate, no locks
# ---------------------------------------------------------------------------

test_that("fdefine_problem() returns a prioritizr problem for min_set", {
  raw_sf <- make_test_sf()
  targets <- data.frame(feature = "feature_A", target = 0.5)
  options <- list(
    obj_func       = "min_set",
    climate_change = 0L,
    percentile     = 10,
    direction      = -1,
    refugiaTarget  = 0.1
  )
  # Plain list acts as a Shiny input — input[[key]] works on lists
  input <- list(
    costid    = "Cost_Area",
    climateid = "NA"
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  prob <- shinyplanr:::fdefine_problem(
    targets    = targets,
    raw_sf     = raw_sf,
    options    = options,
    input      = input,
    name_check = "sli_",
    clim_input = "NA",
    compare_id = ""
  )

  expect_s3_class(prob, "ConservationProblem")
})

# ---------------------------------------------------------------------------
# fdefine_problem() — min_shortfall with budget
# ---------------------------------------------------------------------------

test_that("fdefine_problem() returns a prioritizr problem for min_shortfall", {
  raw_sf <- make_test_sf()
  targets <- data.frame(feature = "feature_A", target = 0.5)
  options <- list(
    obj_func       = "min_shortfall",
    climate_change = 0L,
    percentile     = 10,
    direction      = -1,
    refugiaTarget  = 0.1
  )
  input <- list(
    costid    = "Cost_Area",
    climateid = "NA",
    budget    = 50 # 50% of total cost
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  prob <- shinyplanr:::fdefine_problem(
    targets    = targets,
    raw_sf     = raw_sf,
    options    = options,
    input      = input,
    name_check = "sli_",
    clim_input = "NA",
    compare_id = ""
  )

  expect_s3_class(prob, "ConservationProblem")
})

# ---------------------------------------------------------------------------
# fdefine_problem() — compare_id suffix (Compare module)
# ---------------------------------------------------------------------------

test_that("fdefine_problem() works with compare_id = '1' (Compare module suffix)", {
  raw_sf <- make_test_sf()
  targets <- data.frame(feature = "feature_A", target = 0.5)
  options <- list(
    obj_func       = "min_set",
    climate_change = 0L,
    percentile     = 10,
    direction      = -1,
    refugiaTarget  = 0.1
  )
  # Compare module uses costid1, climateid1
  input <- list(
    costid1    = "Cost_Area",
    climateid1 = "NA"
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  prob <- shinyplanr:::fdefine_problem(
    targets    = targets,
    raw_sf     = raw_sf,
    options    = options,
    input      = input,
    name_check = "sli_",
    clim_input = "NA",
    compare_id = "1"
  )

  expect_s3_class(prob, "ConservationProblem")
})

# ---------------------------------------------------------------------------
# fdefine_problem() — NULL clim_input treated as non-climate-smart
# ---------------------------------------------------------------------------

test_that("fdefine_problem() handles NULL clim_input without error", {
  raw_sf <- make_test_sf()
  targets <- data.frame(feature = "feature_A", target = 0.5)
  options <- list(
    obj_func       = "min_set",
    climate_change = 0L,
    percentile     = 10,
    direction      = -1,
    refugiaTarget  = 0.1
  )
  input <- list(
    costid    = "Cost_Area",
    climateid = NULL
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  prob <- shinyplanr:::fdefine_problem(
    targets    = targets,
    raw_sf     = raw_sf,
    options    = options,
    input      = input,
    name_check = "sli_",
    clim_input = NULL,
    compare_id = ""
  )

  expect_s3_class(prob, "ConservationProblem")
})

# ---------------------------------------------------------------------------
# fdefine_problem() — no features selected (f_no == 0, not 1)
#
# When targets is empty, out_sf contains only Cost_Area + geometry.
# fCheckFeatureNo drops geometry and Cost_* columns, leaving 0 columns.
# The f_no == 1 guard in fdefine_problem does NOT fire (it checks for == 1,
# not <= 1), so the function falls through to prioritizr::problem() with
# features = character(0), which errors. This is a known latent bug (the
# guard should be f_no <= 1). The test documents the current behaviour.
# ---------------------------------------------------------------------------

test_that("fdefine_problem() errors when no features are selected (known latent bug)", {
  raw_sf <- make_test_sf()
  targets <- data.frame(feature = character(0), target = numeric(0))
  options <- list(
    obj_func       = "min_set",
    climate_change = 0L,
    percentile     = 10,
    direction      = -1,
    refugiaTarget  = 0.1
  )
  input <- list(
    costid    = "Cost_Area",
    climateid = "NA"
  )

  local_mocked_bindings(runjs = function(...) invisible(NULL), .package = "shinyjs")
  local_mocked_bindings(shinyalert = function(...) invisible(NULL), .package = "shinyalert")

  # prioritizr::problem() rejects features = character(0)
  expect_error(
    shinyplanr:::fdefine_problem(
      targets    = targets,
      raw_sf     = raw_sf,
      options    = options,
      input      = input,
      name_check = "sli_",
      clim_input = "NA",
      compare_id = ""
    )
  )
})
