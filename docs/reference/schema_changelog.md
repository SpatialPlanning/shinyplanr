# Print the shinyplanr config schema changelog

Prints a human-readable summary of what changed in `setup/3_setup_app.R`
between each schema version. Call this after upgrading shinyplanr to see
whether your `3_setup_app.R` needs manual updates before you re-run it.

## Usage

``` r
schema_changelog(from = 2L)
```

## Arguments

- from:

  Integer. Show changelog entries from this version onwards (inclusive).
  Defaults to `2L` (the first version with a changelog). Set to your
  current config's `schema_version + 1` to see only what is new since
  your last update.

## Value

Invisibly returns the changelog list. Called for its side effect of
printing to the console.

## Details

The changelog covers all versions from version 2 onwards. If your config
was generated with an older version, look at all entries with a version
number higher than your config's `schema_version`.

## Examples

``` r
# See everything that has changed since the initial release
shinyplanr::schema_changelog()
#> shinyplanr config schema changelog (current version: 2)
#> --------------------------------------------------
#> 
#> [v2]
#>   • Removed the `vars` key from config_list (now derived from Dict$nameVariable at runtime).
#>   • Added the `sidebar` key: pre-computed fcreate_vars() / fcreate_check() results.
#>   • In 3_setup_app.R, add the `sidebar` block before `config_list <- list(...)` and
#>   •   include `sidebar = sidebar` in config_list. See the current template for the
#>   •   exact code: shinyplanr:::.write_setup_app
#> 

# See only what changed since your config was at version 2
shinyplanr::schema_changelog(from = 3L)
#> shinyplanr config schema changelog (current version: 2)
#> --------------------------------------------------
#> No changelog entries for version >= 3.
```
