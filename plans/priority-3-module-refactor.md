# Priority 3 — Module Config Refactor Plan

## Goal

Eliminate all implicit global variable access from Shiny modules. Instead, all config
objects (`Dict`, `raw_sf`, `options`, `bndry`, `overlay`, `map_theme`, `tx_*`, etc.)
are passed explicitly via a single `cfg` list argument to both the UI and server
function of every module.

---

## Design Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Config argument shape | Single `cfg` list | Avoids long signatures; mirrors existing config structure |
| How `app_ui` / `app_server` get `cfg` | `get_pkg_config()` namespace helper | Keeps `load_config()` as single source of truth; no golem-opts coupling |
| Scope of refactor | Both UI and server functions | Full consistency; UI functions already use `Dict` in `fcreate_vars()` calls |
| Access style inside module bodies | Local extraction at top | `Dict <- cfg$Dict` etc. at top of each function; body code unchanged; extraction block acts as explicit dependency manifest for the module |

---

## Config Object Inventory

All globals currently injected into the package namespace by `load_config()` and used by modules:

| Object | Type | Used in |
|---|---|---|
| `Dict` | tibble | mod_2, mod_3, mod_4, mod_5 |
| `options` | list | app_ui, app_server, mod_1, mod_2, mod_3 |
| `raw_sf` | sf data frame | mod_2, mod_3, mod_4, mod_5 |
| `bndry` | sf / sfc | mod_2, mod_3, mod_4 |
| `overlay` | sf / sfc | mod_2, mod_3, mod_4 |
| `map_theme` | ggplot2 theme | mod_2, mod_3, mod_4 |
| `tx` | list (welcome pages) | mod_1 |
| `tx_1footer` | character | mod_1 |
| `tx_2solution` | character | mod_2 |
| `tx_2targets` | character | mod_2 |
| `tx_2cost` | character | mod_2 |
| `tx_2climate` | character | mod_2 |
| `tx_2ess` | character | mod_2 |
| `tx_6faq` | character | mod_6 |
| `tx_6technical` | character | mod_6 |

`bar_theme` and `vars` appear in the config schema but are not accessed in any
module directly.

---

## Architecture After Refactor

```
load_config("config/shinyplanr_config.rds")
    └── assigns all objects into pkg namespace

run_app()
    └── shinyApp(ui = app_ui, server = app_server)

app_ui(request)
    cfg <- get_pkg_config()            # reads namespace once
    └── mod_1welcome_ui("1welcome_ui_1", cfg)
    └── mod_2scenario_ui("2scenario_ui_1", cfg)
    └── mod_3compare_ui("3compare_ui_1", cfg)
    └── mod_4features_ui("4features_ui_1", cfg)
    └── mod_5coverage_ui("5coverage_ui_1", cfg)
    └── mod_6help_ui("6help_ui_1", cfg)

app_server(input, output, session)
    cfg <- get_pkg_config()            # reads namespace once
    └── mod_1welcome_server("1welcome_ui_1", cfg)
    └── mod_2scenario_server("2scenario_ui_1", cfg)
    └── ...
```

Inside each module:
```r
mod_2scenario_ui <- function(id, cfg) {
  Dict     <- cfg$Dict
  options  <- cfg$options
  # ... rest unchanged
}
```

---

## Step-by-Step Implementation

### Step 1 — Add `get_pkg_config()` to `R/app_config.R`

Add a small helper that reads the full config back out of the package namespace.
This is the only place that "knows" about the namespace pattern.

```r
#' Retrieve the full shinyplanr config from the package namespace
#'
#' Called once at the top of app_ui() and app_server() to get the config
#' list that was populated by load_config(). All module functions receive
#' this list as their `cfg` argument.
#'
#' @return A named list with all config keys (Dict, raw_sf, options, etc.)
#' @noRd
get_pkg_config <- function() {
  pkg_env <- asNamespace("shinyplanr")
  required <- shinyplanr:::.shinyplanr_required_keys
  cfg <- mget(required, envir = pkg_env, inherits = FALSE)
  cfg
}
```

> Note: `schema_version` is in `.shinyplanr_required_keys` but modules don't
> use it — it will just be present in `cfg` and ignored.

---

### Step 2 — Refactor `R/app_ui.R`

- Add `cfg <- get_pkg_config()` as first line of `app_ui()`
- Replace all bare `options$` reads with `cfg$options$`
- Add `cfg` as second argument to every `mod_X_ui()` call
- `golem_add_external_resources()` still uses `options$app_title` — replace
  with accepting `cfg` as an argument too, or extract `options` into a local
  variable first

**Before (example):**
```r
app_ui <- function(request) {
  shiny::navbarPage(
    title = shiny::a(..., options$nav_title),
    if (options$mod_1welcome == TRUE) {
      mod_1welcome_ui("1welcome_ui_1")
    },
    ...
  )
}
```

**After:**
```r
app_ui <- function(request) {
  cfg     <- get_pkg_config()
  options <- cfg$options
  shiny::navbarPage(
    title = shiny::a(..., options$nav_title),
    if (options$mod_1welcome == TRUE) {
      mod_1welcome_ui("1welcome_ui_1", cfg)
    },
    ...
  )
}
```

Also update `golem_add_external_resources()` signature to accept `options`:
```r
golem_add_external_resources <- function(options) { ... }
```
and call it as `golem_add_external_resources(cfg$options)` in `app_ui`.

---

### Step 3 — Refactor `R/app_server.R`

- Add `cfg <- get_pkg_config()` at the top of `app_server()`
- Replace all bare `options$` reads with local `options <- cfg$options`
- Add `cfg` as second argument to every `mod_X_server()` call

**After (sketch):**
```r
app_server <- function(input, output, session) {
  cfg     <- get_pkg_config()
  options <- cfg$options

  shiny::observe({
    if (options$mod_1welcome == TRUE && shiny::req(input$navbar) == "Welcome") {
      mod_1welcome_server("1welcome_ui_1", cfg)
    }
    ...
  })
}
```

---

### Step 4 — Refactor `R/mod_1welcome.R`

Globals used: `tx$welcome`, `tx_1footer`, `options$funder_url`, `options$show_uq_logo`

**Signature changes:**
```r
mod_1welcome_ui <- function(id, cfg) { ... }
mod_1welcome_server <- function(id, cfg) { ... }
```

**Body — at top of UI function, extract locals:**
```r
  tx      <- cfg$tx
  tx_1footer <- cfg$tx_1footer
  options <- cfg$options
```

---

### Step 5 — Refactor `R/mod_2scenario.R` _(largest, ~1495 lines)_

Globals used: `Dict`, `options`, `raw_sf`, `bndry`, `overlay`, `map_theme`,
`tx_2solution`, `tx_2targets`, `tx_2cost`, `tx_2climate`, `tx_2ess`

**Signature changes:**
```r
mod_2scenario_ui     <- function(id, cfg) { ... }
mod_2scenario_server <- function(id, cfg) { ... }
```

**Body — extract locals at top of each function:**
```r
  Dict       <- cfg$Dict
  options    <- cfg$options
  raw_sf     <- cfg$raw_sf
  bndry      <- cfg$bndry
  overlay    <- cfg$overlay
  map_theme  <- cfg$map_theme
  tx_2solution <- cfg$tx_2solution
  tx_2targets  <- cfg$tx_2targets
  tx_2cost     <- cfg$tx_2cost
  tx_2climate  <- cfg$tx_2climate
  tx_2ess      <- cfg$tx_2ess
```

All downstream uses of these variables inside the function body remain
**unchanged** — local names match existing names, so no further edits needed
in the function body.

---

### Step 6 — Refactor `R/mod_3compare.R` _(~1328 lines)_

Globals used: `Dict`, `options`, `raw_sf`, `bndry`, `overlay`, `map_theme`

Same pattern as mod_2. Extract at top:
```r
  Dict      <- cfg$Dict
  options   <- cfg$options
  raw_sf    <- cfg$raw_sf
  bndry     <- cfg$bndry
  overlay   <- cfg$overlay
  map_theme <- cfg$map_theme
```

---

### Step 7 — Refactor `R/mod_4features.R`

Globals used: `Dict`, `raw_sf`, `bndry`, `overlay`, `map_theme`

Same pattern. No `options` or `tx_*` needed.

---

### Step 8 — Refactor `R/mod_5coverage.R`

Globals used: `raw_sf`, `Dict`

Smallest data-dependent module. Extract:
```r
  raw_sf <- cfg$raw_sf
  Dict   <- cfg$Dict
```

---

### Step 9 — Refactor `R/mod_6help.R`

Globals used: `tx_6faq`, `tx_6technical`

```r
mod_6help_ui <- function(id, cfg) {
  tx_6faq       <- cfg$tx_6faq
  tx_6technical <- cfg$tx_6technical
  ...
}
mod_6help_server <- function(id, cfg) { ... }
```

---

### Step 10 — Refactor `R/mod_7multiobj.R`

Currently a placeholder with no config globals used. Still add `cfg` to
both signatures for consistency:

```r
mod_7multiobj_ui     <- function(id, cfg) { ... }
mod_7multiobj_server <- function(id, cfg) { ... }
```

---

### Step 11 — Update test files

The following test files call module functions directly and will need a mock
`cfg` list passed as the second argument:

- [`tests/testthat/test-mod_1welcome.R`](tests/testthat/test-mod_1welcome.R)
- [`tests/testthat/test-mod_2scenario.R`](tests/testthat/test-mod_2scenario.R)
- [`tests/testthat/test-mod_3compare.R`](tests/testthat/test-mod_3compare.R)
- [`tests/testthat/test-mod_5coverage.R`](tests/testthat/test-mod_5coverage.R)
- [`tests/testthat/test-golem-recommended.R`](tests/testthat/test-golem-recommended.R)

Create a shared `cfg` fixture using `R/sysdata.rda` stub objects (already
used by existing tests via `load_config()` in setup). The mock can be
assembled as:

```r
# In each test file or a shared helper:
cfg <- list(
  Dict      = shinyplanr:::Dict,
  options   = shinyplanr:::options,
  raw_sf    = shinyplanr:::raw_sf,
  bndry     = shinyplanr:::bndry,
  overlay   = shinyplanr:::overlay,
  map_theme = shinyplanr:::map_theme,
  tx        = shinyplanr:::tx,
  tx_1footer    = shinyplanr:::tx_1footer,
  tx_2solution  = shinyplanr:::tx_2solution,
  tx_2targets   = shinyplanr:::tx_2targets,
  tx_2cost      = shinyplanr:::tx_2cost,
  tx_2climate   = shinyplanr:::tx_2climate,
  tx_2ess       = shinyplanr:::tx_2ess,
  tx_6faq       = shinyplanr:::tx_6faq,
  tx_6technical = shinyplanr:::tx_6technical,
  tx_6changelog = shinyplanr:::tx_6changelog,
  schema_version = 1L
)
```

Alternatively, call `shinyplanr:::get_pkg_config()` directly after the
existing `load_config()` setup call.

---

### Step 12 — `devtools::document()` clean pass

Run and confirm zero warnings/errors.

### Step 13 — `devtools::check()` / `devtools::test()` clean pass

Run and confirm all tests pass with no `R CMD CHECK` notes about undefined
global variables (the refactor should eliminate any such notes for the
globals listed above).

---

## What Does NOT Change

- [`R/load_config.R`](R/load_config.R) — no changes; keeps injecting into namespace
- [`R/config_schema.R`](R/config_schema.R) — no changes
- [`R/utils_server.R`](R/utils_server.R) — already takes explicit `Dict` parameter
- [`R/fdefine_problem.R`](R/fdefine_problem.R) — already takes explicit args
- [`R/validate_config.R`](R/validate_config.R) — no changes
- All `tx_*` markdown content files — no changes
- All `inst/templates/` files — no changes
- `R/sysdata.rda` / `data-raw/build_stub_sysdata.R` — no changes

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|---|---|---|
| Missed global reference in large modules | Medium | After implementation, run `devtools::check()` — R CMD CHECK flags undefined globals |
| Test failures from missing `cfg` arg | High (expected) | Update all test files in Step 11 before running tests |
| `golem_add_external_resources()` breakage | Low | Internal `@noRd` function; updated in same PR as `app_ui` |
| `bindCache()` / `<<-` closures in mod_2 capturing old env | Low | Local variable extraction at top of function creates correct lexical scope |
