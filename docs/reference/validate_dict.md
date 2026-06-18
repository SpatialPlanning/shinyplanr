# Validate a shinyplanr feature dictionary (Dict_Feature.csv)

Runs structural checks on the raw (unfiltered) feature dictionary read
from `Dict_Feature.csv` in `setup/3_setup_app.R`, **before** the
`includeApp` filter is applied. Call this immediately after
[`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html)
and before `dplyr::filter(includeApp)`.

## Usage

``` r
validate_dict(Dict, strict = TRUE)
```

## Arguments

- Dict:

  A data frame. The raw (unfiltered) feature dictionary, typically the
  direct output of
  `readr::read_csv(file.path(setup_dir, "Dict_Feature.csv"))`.

- strict:

  Logical. If `TRUE` (default), stops immediately with a clear,
  actionable error message on the first failed check. If `FALSE`, all
  checks are run and a summary report is returned invisibly;
  [`warning()`](https://rdrr.io/r/base/warning.html) is called for each
  failure.

## Value

When `strict = FALSE`, invisibly returns a named list of logical values
(`TRUE` = passed, `FALSE` = failed) for each check. When
`strict = TRUE`, returns `invisible(TRUE)` if all checks pass.

## Details

Catching problems here – before the data is loaded – gives the deployer
the clearest possible error messages, because the issue is in the CSV
they just edited rather than buried inside a spatial data pipeline.

## Checks performed

- All required columns are present in `Dict`.

- `includeApp` and `includeJust` columns are logical (`TRUE`/`FALSE`),
  not character or integer. A common mistake is editing the CSV in
  Excel, which can convert `TRUE` to `1` or `"TRUE"` (character),
  causing `dplyr::filter(includeApp)` to silently drop all rows.

- All values in the `type` column are from the known set (`"Feature"`,
  `"Cost"`, `"LockIn"`, `"LockOut"`, `"Bioregion"`,
  `"EcosystemServices"`, `"Justification"`). A typo like `"feature"`
  (lowercase) silently excludes a row from all app processing.

- `nameVariable` is unique within each `type`. Duplicates cause silent
  bugs in `prioritizr` (duplicate feature columns) and duplicate slider
  input IDs in the Shiny UI. Note: the same `nameVariable` may
  legitimately appear in both `"LockIn"` and `"LockOut"` rows (e.g.
  MPAs) – uniqueness is only enforced within each type.

- At least one row has `includeApp == TRUE` and `type == "Feature"`. An
  app with no active features cannot run a prioritisation.

- All rows with `includeApp == TRUE` and `type == "Feature"` have
  `targetMin`, `targetMax`, and `targetInitial` values in the 0–100
  range. Out-of-range values cause `prioritizr` to error at solve time.

## Examples

``` r
if (FALSE) { # \dontrun{
# In setup/3_setup_app.R, immediately after reading the CSV:
Dict_raw <- readr::read_csv(file.path(setup_dir, "Dict_Feature.csv"))
shinyplanr::validate_dict(Dict_raw)

Dict <- Dict_raw |>
  dplyr::filter(includeApp) |>
  dplyr::arrange(type, categoryID, nameCommon)
} # }
```
