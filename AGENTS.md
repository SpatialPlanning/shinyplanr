# AGENTS.md

This file provides guidance to coding agent when working with code in this repository.

<!-- CUSTOMIZE HERE -->

## Description

<Insert here the description of your application in details>

## Architecture

<Describe the target architecture>

<!-- STOP CUSTOMIZE -->

# Golem Shiny App — Development Rules

# init

Read the Project Overview section in CLAUDE.md, then build the golem app
following all the rules defined in this file.

## Key commands

```r
# To launch the shiny application
Rscript -e "golem::run_dev()"

# To run the tests
Rscript -e "devtools::test()"

# To check the package
Rscript -e "devtools::check()"

# To redocument the package
Rscript -e "devtools::document()"

# To format code
air format .
```

## Communication

- Whenever you have finished a change, invite the user to launch the app with `golem::run_dev()`
- Do not suggest `source("dev/run_dev.R")` or `pkgload::load_all();run_app()`

## Creation of a golem app

- The first thing to do when asked to create a golem app is to run the `golem::create_golem()` function with the name of the app.
- The name of the app should either be the basename of the folder (i.e example/gpxviewer is "gpxviewer"), or the one provided by the user.
- The output directory should contain the same structure as the template in golem.
- Never create the folder yourself,
- When you have finished creating the application, invite the user to move to the folder (if they are not already in it) and to run `golem::run_dev()` in their R console.

## Project Structure

- A golem app IS an R package — "the fundamental unit of reproducible R code". Apply all R package conventions: DESCRIPTION, NAMESPACE, R/, tests/, etc.
- Any file that doesn't fit the package structure must be added to `.Rbuildignore` via `usethis::use_build_ignore("<name>")`.
- `R/` folder must stay flat — no subfolders.
- Never edit `NAMESPACE` by hand. Use `devtools::document()`.
- Development scripts go in `dev/`, never in `R/`.
- Data creation & manipulation go into a `data-raw` folder, and files here should be created with `usethis::use_data_raw()`
- Other possible folders (but not limited to): `renv`, `tools`, `doc`, `meta`, `rsconnect`

## File Naming

- Modules: `R/mod_<name>.R`
- Module-specific functions: `R/mod_<name>_fct_<fn>.R`
- Module-specific utilities: `R/mod_<name>_utils_<fn>.R`
- Standalone functions: `R/fct_<name>.R`
- Utilities: `R/utils_<name>.R`
- Test files mirror `R/` files: `tests/testthat/test-mod_<name>.R`
- External files (js/css/png...): `inst/app/www/<name>.js` / `inst/app/www/<name>.css` / `inst/app/www/<name>.png`

## Creating Files

The project should be created using `golem::create_golem()`.

Always use {golem} helpers — never create files manually:

- `golem::add_module("name")` — always pass `with_test = TRUE`
- `golem::add_fct("name")`— always pass `with_test = TRUE`
- `golem::add_utils("name")`— always pass `with_test = TRUE`

Whenever you can, update the test files to test the modules and the fct & utils functions. You should aim for a 100% code coverage.

## Development Workflow

1. Edit `R/` files
2. `devtools::document()` if roxygen/NAMESPACE changed
3. `golem::run_dev()` to test interactively
4. `devtools::test()` to run tests
5. `devtools::check()` before any commit or release

## Modules

- Use `moduleServer()` — NEVER `callModule()` (deprecated).
- Always namespace UI elements: `ns <- NS(id)`.
- When working on a module, check if there might be missing `ns` in the UI.
- NEVER pass `reactive()` objects between modules unless explicitly prompted to.

## Reactive Programming

- ALWAYS use `observeEvent()` — NEVER use `observe()`.
- ALWAYS use `reactiveValues()` — NEVER use `reactive()` or `reactiveVal()`.
- ALWAYS put reactive value inside a reactive consumer.

Correct:

```
local_rv <- reactiveValues(
  a = NULL
)
observeEvent(
  input$a, {
    local_rv$a <- input$a
  }
)
```

Bad:

```
local_rv <- reactiveValues(
  a = NULL
)
local_rv$a <- input$a
```

- Avoid `renderUI()` + `uiOutput()` as much as you can. Only use it if there are no other options.
  - Prefer `update*()` functions (e.g. `updateSelectInput()`).
  - Prefer JS-side show/hide over server-side UI regeneration.
- Watch for reactive cycles (A updates B updates A). Break them with explicit conditions.
- If ever you need to share data across module, either use a global environment if the values can be shared across all shiny sessions, or share a `reactiveValues()` object between modules. Always use your `reactiveValues()` with parsimony, make it so that there is just what is needed to be shared from one module to the other. Don't call these reactiveValues `r` or `rv`, find something meaningful like `global_storage` or something like that.

Here is the pattern you should aim for from the server-side, but this is not a strict rule. Aim for the best working architecture that follows the other rules.

```r
mod_<name>_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    local_rv <- reactiveValues()

    observeEvent(
      input$btn,
      {
        local_rv$value <- compute_things(
          input$btn
        )
      }
    )

    output$plot <- renderPlot({
      local_rv$value
    })
  })
}
```

## Code Quality

- Follow the tidyverse style guide.
- Use `air format .` if the formatter is installed.
- Any R code outside of a function body is suspicious — wrap it in a function.
- Use `TRUE`/`FALSE` — never `T`/`F`.
- Never use `=` for assignment.
- No non-ASCII characters in `R/` files — use unicode escapes (`\uXXXX`) if the app is to be deployed on CRAN. Otherwise, create a file in `tools/`, that will contain `check.env`, with inside `_R_CHECK_ASCII_CODE_=FALSE`.
- Avoid modifying global state (`options()`, `setwd()`, `Sys.setenv()`). If unavoidable, restore with `on.exit(..., add = TRUE)` or `{withr}`.
- No `library()`, `require()`, or `source()` calls inside package code.
- No `:::` to access another package's internal functions unless there is no other solution. If you want to do that, ask the user if they are ok with it.

## Dependencies

- Add with `usethis::use_package("pkg")` → goes into `Imports` in DESCRIPTION.
- Always use `@importFrom` on top of each function. Whenever you can, check if new `@importFrom` are required.
- Never depend on {tidyverse} or {devtools} — depend on specific packages instead.
- For optional (Suggested) packages, check availability with `requireNamespace("pkg", quietly = TRUE)` or `rlang::check_installed("pkg")`.
- Use `Imports` over `Depends`. `Depends` is only for R version requirements.
- Specify minimum versions with `>=`, never exact versions with `==`.

## Documentation

- All exported functions must be documented with {roxygen2}.
- Enable markdown in roxygen: add `Roxygen: list(markdown = TRUE)` to DESCRIPTION.
- Run `devtools::document()` after any {roxygen2} change — never edit `.Rd` files or `NAMESPACE` by hand.
- Use `@noRd` for internal functions that should not generate a `.Rd` file.
- Use `@inheritParams source_fn` to avoid duplicating parameter documentation.
- All exported functions must have at least one `@examples` entry.

## Configuration

- Environment config → `golem-config.yml` + `get_golem_config("key")`
- Runtime config → `run_app(param = val)` + `golem::get_golem_options("param")`
- NEVER store secrets/passwords in config files.

## Testing

- Test files are created with `usethis::use_test("name")`.
- Tests should be hermetic: each `test_that()` block sets up its own data inline.
- Minimize top-level code outside `test_that()` blocks.
- Use `withr::local_*()` for any temporary state change (options, env vars, files).
- Write temporary files only to `withr::local_tempfile()` / `withr::local_tempdir()`. Never write to the home directory or working directory.
- Store static test data in `tests/testthat/fixtures/`; load with `readRDS(test_path("fixtures", "file.rds"))`.
- Prefer `expect_error(..., class = "error_class")` over matching error messages.
- Use `skip_on_cran()` for tests that are slow or require network access.
- Test business logic outside of reactive context whenever possible.

## Deployment

- Add a Dockerfile with `golem::add_dockerfile()` or other platforms.
- Never hardcode environment-specific values — use `golem-config.yml` with named environments (default, dev, production).
- Check the app passes `R CMD check` before deploying.
- Keep total package size under 5 MB.
