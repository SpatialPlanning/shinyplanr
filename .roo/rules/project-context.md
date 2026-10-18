# Project context: shinyplanr

## What this repo is
- shinyplanr is a golem-based Shiny app for spatial planning, designed for stakeholder engagement.
- Users run conservation prioritisations through the app using the prioritizr package.
- Users create their own region-specific version of the app with the `create_template()` function. The new app opens in a separate R project, so changes here must work for generated templates as well as this repo.

## Related package: spatialplanr
- shinyplanr is designed to be used together with the spatialplanr package, located at `@/../spatialplanr`.
- You are authorised to read and modify spatialplanr when needed to achieve what we need in shinyplanr.
- When a change belongs in spatialplanr rather than shinyplanr, tell me and explain why before editing it.

## Conventions
- Follow golem structure: UI and server logic live in modules under `R/`; keep module code consistent with the existing modules.
- Map legends and labels should be consistent across all leaflet plots in the app.