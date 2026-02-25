#' Utility functions for the coverage module
#'
#' @noRd


#' Read and validate an uploaded spatial file
#'
#' @param file_input The file input object from shiny::fileInput
#'
#' @return A list with 'success' (logical), 'data' (sf object or NULL), and 'message' (character)
#'
#' @noRd
#'
fread_uploaded_spatial <- function(file_input) {


  # Check if file input is valid
  if (is.null(file_input) || is.null(file_input$datapath)) {
    return(list(
      success = FALSE,
      data = NULL,
      message = "No file provided."
    ))
  }

  file_path <- file_input$datapath
  file_name <- file_input$name

  # Determine file type from extension

file_ext <- tolower(tools::file_ext(file_name))

  # Validate file extension
  if (!file_ext %in% c("gpkg", "gdb", "geojson")) {
    return(list(
      success = FALSE,
      data = NULL,
      message = paste0("Unsupported file format: .", file_ext,
                       ". Please upload a GeoPackage (.gpkg), GeoJSON (.geojson) or File Geodatabase (.gdb).")
    ))
  }

  # Attempt to read the spatial file
  tryCatch({
    sf_data <- sf::st_read(file_path, quiet = TRUE)

    # Validate that we have geometry
    if (is.null(sf::st_geometry(sf_data)) || nrow(sf_data) == 0) {
      return(list(
        success = FALSE,
        data = NULL,
        message = "The uploaded file contains no geometries."
      ))
    }

    # Check geometry type - we only want polygons
    geom_types <- unique(sf::st_geometry_type(sf_data))

    if (!any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      return(list(
        success = FALSE,
        data = NULL,
        message = paste0("The uploaded file contains ", paste(geom_types, collapse = ", "),
                         " geometries. Only POLYGON or MULTIPOLYGON geometries are accepted.")
      ))
    }

    # Filter to only polygon geometries if mixed
    if (length(geom_types) > 1) {
      sf_data <- sf_data[sf::st_geometry_type(sf_data) %in% c("POLYGON", "MULTIPOLYGON"), ]
    }

    # Validate geometries
    if (!all(sf::st_is_valid(sf_data))) {
      # Attempt to fix invalid geometries
      sf_data <- sf::st_make_valid(sf_data)
    }

    return(list(
      success = TRUE,
      data = sf_data,
      message = NULL
    ))

  }, error = function(e) {
    return(list(
      success = FALSE,
      data = NULL,
      message = paste0("Error reading file: ", e$message)
    ))
  })
}


#' Calculate feature coverage for uploaded polygons
#'
#' This function calculates the feature representation dataframe (targetPlotData)
#' that can be passed directly to spatialplanr::splnr_plot_featureRep.
#'
#' @param uploaded_sf An sf object with the uploaded polygons
#' @param raw_sf The raw planning unit data with feature columns
#' @param Dict The data dictionary
#'
#' @return A tibble with columns: feature, total_amount, absolute_held, relative_held, target, incidental
#'
#' @noRd
#'
fcalculate_coverage <- function(uploaded_sf, raw_sf, Dict) {

 # Step 1: Get feature names from Dict (type == "Feature" and includeApp == TRUE)
  feature_info <- Dict %>%
    dplyr::filter(.data$type == "Feature", .data$includeApp == TRUE) %>%
    dplyr::select(.data$nameVariable, .data$targetInitial)

  feature_names <- feature_info$nameVariable

 # Step 2: Ensure uploaded polygons are in the same CRS as raw_sf
  uploaded_transformed <- sf::st_transform(uploaded_sf, sf::st_crs(raw_sf))

 # Step 3: Determine which planning units intersect with uploaded polygons
  intersects_matrix <- sf::st_intersects(raw_sf, uploaded_transformed, sparse = FALSE)
  is_covered <- apply(intersects_matrix, 1, any)

  # Step 4: Calculate coverage statistics for each feature
  # Drop geometry for faster calculations
  raw_df <- sf::st_drop_geometry(raw_sf)

  targetPlotData <- purrr::map_dfr(feature_names, function(feat) {
    feat_values <- raw_df[[feat]]

    # total_amount: sum of 1s across all planning units
    total_amount <- sum(feat_values == 1, na.rm = TRUE)

    # absolute_held: sum of 1s in planning units that are covered
    absolute_held <- sum(feat_values[is_covered] == 1, na.rm = TRUE)

    # relative_held: proportion
    relative_held <- if (total_amount > 0) absolute_held / total_amount else 0

    # Get target from Dict
    target_val <- feature_info$targetInitial[feature_info$nameVariable == feat]
    target <- if (length(target_val) > 0 && !is.na(target_val)) target_val / 100 else 0.3

    tibble::tibble(
      feature = feat,
      total_amount = total_amount,
      absolute_held = absolute_held,
      relative_held = relative_held,
      target = target,
      incidental = FALSE
    )
  })

  return(targetPlotData)
}

