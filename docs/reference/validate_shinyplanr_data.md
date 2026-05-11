# Validate a shinyplanr deployment configuration before saving

Runs a comprehensive set of checks on a config list produced by
`setup-app.R` before it is saved to `config/shinyplanr_config.rds`. This
function is intended to be called at the end of the deployer's
`setup-app.R` script, immediately before
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html), to catch data
problems early rather than at runtime.

## Usage

``` r
validate_shinyplanr_data(config_list, strict = TRUE)
```

## Arguments

- config_list:

  A named list. The config object built in `setup-app.R`, containing at
  minimum the keys listed in `.shinyplanr_required_keys`.

- strict:

  Logical. If `TRUE` (default), the function stops immediately with a
  clear error message on the first failed check. If `FALSE`, all checks
  are run and a summary report is returned invisibly; warnings are
  issued for each failure.

## Value

When `strict = FALSE`, invisibly returns a named list of logical values
(`TRUE` = passed, `FALSE` = failed) for each check. When
`strict = TRUE`, returns `invisible(TRUE)` if all checks pass.

## Checks performed

- `Dict` contains all required columns.

- All `Dict$nameVariable` values for Feature/Cost/LockIn/LockOut types
  are present as columns in `raw_sf`.

- `raw_sf` CRS matches `options$cCRS`.

- `bndry` and `overlay` are valid `sf` objects.

- `bndry` CRS matches `raw_sf` CRS.

- No Feature columns in `raw_sf` are entirely zero or entirely `NA`
  (would cause prioritizr to error or produce meaningless results).

- `tx` is a list with a `welcome` element, each entry of which contains
  `title` and `text` character fields.

- All `tx_*` text fields are non-`NULL` character strings.

- Feature-type Dict rows have `targetMin`, `targetMax`, and
  `targetInitial` values within the 0-100 range.

## Examples

``` r
if (FALSE) { # \dontrun{
# At the end of setup-app.R, before saveRDS():
validate_shinyplanr_data(config_list)           # strict -- stops on failure
validate_shinyplanr_data(config_list, strict = FALSE)  # report mode
} # }
```
