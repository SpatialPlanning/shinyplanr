# Return the current shinyplanr config schema version

Returns the integer schema version that this installation of shinyplanr
expects. Use this in your \`3_setup_app.R\` script to stamp the config
with the correct version so that \`load_config()\` can detect
mismatches.

## Usage

``` r
get_schema_version()
```

## Value

An integer scalar.

## Examples

``` r
shinyplanr::get_schema_version()
#> [1] 2
```
