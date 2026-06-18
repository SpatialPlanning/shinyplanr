# data-raw/manual — ARCHIVED

> **This directory is no longer maintained.**
>
> The content here was an earlier Quarto book version of the shinyplanr
> documentation. It has been superseded by the pkgdown vignettes in
> [`vignettes/`](../../vignettes/).

## Why it is kept

The directory is retained for historical reference only. Some content
(e.g. the package ecosystem diagram in `chapters/05-useful-tools.qmd`)
was used as source material when updating the vignettes.

## Current documentation

The live documentation is the pkgdown website built from `vignettes/`:

| Vignette | Description |
|----------|-------------|
| [`vignettes/aa-introduction.qmd`](../../vignettes/aa-introduction.qmd) | Conceptual foundation for spatial prioritisation |
| [`vignettes/ab-using-shinyplanr.qmd`](../../vignettes/ab-using-shinyplanr.qmd) | Guide to using the shinyplanr application |
| [`vignettes/ac-setting-up.qmd`](../../vignettes/ac-setting-up.qmd) | Setting up shinyplanr for a new region |
| [`vignettes/ad-deployment.qmd`](../../vignettes/ad-deployment.qmd) | Deploying to Posit Connect |

## Known stale content in this directory

- Script names use the old convention (`setup-data.R`, `setup-app.R`)
  instead of the current numbered scripts (`2_setup_data.R`, `3_setup_app.R`)
- The `options` variable name is used instead of `shinyplanr_options`
- Directory structure diagrams reflect the pre-v2 project layout

Do not use this content as a reference for the current package.
