# Create a new shinyplanr deployment project

Creates a standalone deployment project for a new region. The project
contains all the files a practitioner needs to prepare their spatial
data, configure the app, test locally, and deploy to Posit Connect —
without modifying the shinyplanr package source code.

## Usage

``` r
create_shinyplanr_template(
  country,
  crs = "ESRI:54009",
  oceandatr = TRUE,
  resolution = 20000,
  include_climate = TRUE,
  include_cost = TRUE,
  include_mpas = TRUE,
  output_dir = file.path("..", paste0("shinyplanr_", country)),
  use_renv = TRUE,
  create_rproj = TRUE
)
```

## Arguments

- country:

  Character. Name of the country/region (e.g., "Fiji", "Kosrae"). Used
  for folder naming and default titles.

- crs:

  Character. Coordinate reference system for the analysis. Default is
  "ESRI:54009" (Mollweide equal-area projection). Use
  <https://projectionwizard.org> to find an appropriate local CRS.

- oceandatr:

  Logical. If TRUE (default), the 2_setup_data.R template will include
  code to automatically download data from oceandatr (bathymetry,
  geomorphology, seamounts, knolls, coral habitat, environmental
  regions). If FALSE, creates a minimal template for manual data entry.

- resolution:

  Numeric. Planning unit resolution in meters. Default is 20000 (20 km x
  20 km). Smaller values create more planning units.

- include_climate:

  Logical. If TRUE (default), includes climate-smart planning options in
  setup-app.R and placeholder climate data loading.

- include_cost:

  Logical. If TRUE (default), includes cost layer setup (distance to
  coast, equal area).

- include_mpas:

  Logical. If TRUE (default), includes code to fetch marine protected
  areas from WDPA as locked-in constraints.

- output_dir:

  Character. Path where the deployment project folder will be created.
  Defaults to `file.path("..", country)`, creating a sibling directory
  to the current working directory. The deployer opens this folder as
  their R project — it is **not** inside the shinyplanr package source.

- use_renv:

  Logical. If TRUE (default), initialises renv in the new project to
  lock package versions for reproducible deployments. Requires the renv
  package to be installed. Set to FALSE to skip renv initialisation.

- create_rproj:

  Logical. If TRUE (default), creates an RStudio .Rproj file in the new
  project for easy project opening.

## Value

Invisibly returns the path to the created project folder.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a deployment project for Tonga
create_shinyplanr_template(
  country    = "Tonga",
  crs        = "EPSG:32702",
  oceandatr  = TRUE,
  output_dir = "../tonga-shinyplanr"
)

# Minimal template for custom data, without renv
create_shinyplanr_template(
  country   = "MyRegion",
  crs       = "+proj=cea +lon_0=150 +lat_ts=-10",
  oceandatr = FALSE,
  use_renv  = FALSE
)
} # }
```
