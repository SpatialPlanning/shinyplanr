#' Apply all UI show/hide switches driven by the options list
#'
#' Centralises the imperative \code{shinyjs::show/hide} and
#' \code{shiny::hideTab} calls that are run once at server startup in both the
#' scenario and comparison modules.  Every argument that controls a tab has a
#' default of \code{NULL}; passing \code{NULL} skips that \code{hideTab} call,
#' so each module only needs to supply the tabs it actually owns.
#'
#' Switches for UI elements that do not yet exist in a given module (e.g.
#' \code{switchBoundaryPenalty} in the comparison module) are silently ignored
#' by \code{shinyjs} — the calls are included here so the comparison module is
#' ready to adopt those features without further changes to this helper.
#'
#' @param options Named list of app options (from \code{load_config()}).
#' @param session Shiny session object from the enclosing \code{moduleServer}.
#' @param tab_climate Character tab value for the Climate tab, or \code{NULL}
#'   to skip.
#' @param tab_explore Character tab value for the Explore tab, or \code{NULL}
#'   to skip.
#' @param tab_ess Character tab value for the Ecosystem Services tab, or
#'   \code{NULL} to skip.
#' @param tab_report Character tab value for the Report tab, or \code{NULL}
#'   to skip.
#' @param tab_log Character tab value for the Log tab, or \code{NULL} to skip.
#'
#' @return Invisibly \code{NULL}. Called for its side-effects.
#'
#' @noRd
#'
fapply_ui_switches <- function(options, session,
                               tab_climate = NULL,
                               tab_explore = NULL,
                               tab_ess     = NULL,
                               tab_report  = NULL,
                               tab_log     = NULL) {

  # --- Objective function switches ---
  if (options$obj_func == "min_shortfall") {
    shinyjs::show(id = "switchMinShortfall")
  } else {
    shinyjs::hide(id = "switchMinShortfall")
  }

  if (options$obj_func == "min_set") {
    shinyjs::show(id = "switchMinSet")
  } else {
    shinyjs::hide(id = "switchMinSet")
  }

  # --- Optional feature switches (no-op if element absent) ---
  if (isTRUE(options$switchBoundaryPenalty)) {
    shinyjs::show(id = "switchBoundaryPenalty")
  }

  if (isTRUE(options$include_bioregion)) {
    shinyjs::show(id = "switchBioregions")
  }

  if (isTRUE(options$include_lockedArea)) {
    shinyjs::show(id = "switchConstraints")
  }

  # --- Target slider visibility ---
  switch(options$targetsBy,
    "master"     = shinyjs::show(id = "switchMasterTargets"),
    "category"   = shinyjs::show(id = "switchCategoryTargets"),
    "individual" = shinyjs::show(id = "switchIndividualTargets")
  )

  # --- Tab visibility ---
  if (!isTRUE(options$include_climateChange) && !is.null(tab_climate)) {
    shiny::hideTab(inputId = "tabs", target = tab_climate, session = session)
  }

  if (!isTRUE(options$include_explore) && !is.null(tab_explore)) {
    shiny::hideTab(inputId = "tabs", target = tab_explore, session = session)
  }

  if (!isTRUE(options$include_ess) && !is.null(tab_ess)) {
    shiny::hideTab(inputId = "tabs", target = tab_ess, session = session)
  }

  if (!isTRUE(options$include_report) && !is.null(tab_report)) {
    shiny::hideTab(inputId = "tabs", target = tab_report, session = session)
  }

  if (!isTRUE(options$include_log) && !is.null(tab_log)) {
    shiny::hideTab(inputId = "tabs", target = tab_log, session = session)
  }

  invisible(NULL)
}


#' Render a Quarto report and stream it to a Shiny download handler
#'
#' Encapsulates the boilerplate shared by the scenario and comparison report
#' download handlers:
#' \enumerate{
#'   \item Show a progress notification and spinner in \code{output$reportStatus}.
#'   \item Resolve the QMD template via \code{system.file()} with a local
#'     \code{inst/} fallback.
#'   \item Save each ggplot in \code{plots} as a PNG and each data frame in
#'     \code{tables} as a CSV into \code{tempdir()}.
#'   \item Copy the QMD into a fresh temp sub-directory and call
#'     \code{quarto::quarto_render()}, passing the saved file paths plus any
#'     additional scalar \code{params} as \code{execute_params}.
#'   \item Copy the rendered HTML to \code{file} (the path Shiny expects).
#'   \item Show a success or error notification and update
#'     \code{output$reportStatus}.
#' }
#'
#' The names of \code{plots} and \code{tables} become the \code{execute_params}
#' keys for the file paths: plot names get a \code{"_plot_path"} suffix
#' (e.g. \code{list(solution = p)} → param key \code{"solution_plot_path"}),
#' and table names get a \code{"_table_path"} suffix
#' (e.g. \code{list(details = d)} → param key \code{"details_table_path"}).
#' These must match the \code{params:} block in the QMD template.
#' Additional scalar params are passed through \code{params} unchanged.
#'
#' @param file Character. The file path provided by Shiny's
#'   \code{downloadHandler} \code{content} function.
#' @param output Shiny output list from the enclosing \code{moduleServer}.
#'   Used to update \code{output$reportStatus}.
#' @param template_name Character. Filename of the QMD template inside
#'   \code{inst/app/} (e.g. \code{"report_scenario.qmd"}).
#' @param notification_id Character. ID passed to
#'   \code{shiny::showNotification()} / \code{shiny::removeNotification()}.
#' @param notification_msg Character. Message shown in the progress
#'   notification while the report is rendering.
#' @param tmp_dir_prefix Character. Prefix for the temporary render directory
#'   (e.g. \code{"qrender_"} or \code{"qrender_compare_"}).
#' @param plots Named list of ggplot objects (or \code{NULL} entries).  Each
#'   non-\code{NULL} entry is saved as a PNG; the param key is
#'   \code{paste0(name, "_plot_path")}.
#' @param tables Named list of data frames (or \code{NULL} entries).  Each
#'   non-\code{NULL} entry is saved as a CSV; the param key is
#'   \code{paste0(name, "_table_path")}.
#' @param params Named list of additional scalar values passed directly to
#'   \code{execute_params} (e.g. \code{list(solver_log = "...", cost_id = "x")}).
#' @param ts Character. Timestamp string used to make temp file names unique.
#'   Typically \code{analysisTime()}.
#'
#' @return Invisibly \code{NULL}. Called for its side-effects.
#'
#' @noRd
#'
frender_report <- function(file, output, template_name, notification_id,
                           notification_msg, tmp_dir_prefix,
                           plots, tables, params, ts) {

  # 1. Progress notification + spinner
  shiny::showNotification(
    notification_msg,
    duration    = NULL,
    closeButton = FALSE,
    id          = notification_id,
    type        = "message"
  )
  output$reportStatus <- shiny::renderUI({
    shiny::tagList(
      shiny::icon("spinner", class = "fa-spin"),
      shiny::span(" Generating report\u2026")
    )
  })

  # 2. Resolve template
  template_path <- system.file("app", template_name, package = "shinyplanr")
  if (template_path == "" || !file.exists(template_path)) {
    template_path <- file.path("inst", "app", template_name)
  }
  if (!file.exists(template_path)) {
    shiny::removeNotification(notification_id)
    shiny::showNotification(
      paste0("Report template not found: ", template_name),
      type     = "error",
      duration = 10
    )
    return(invisible(NULL))
  }

  out_dir <- tempdir()

  # 3a. Save plots → build path params
  plot_paths <- purrr::imap(plots, function(plt, nm) {
    if (is.null(plt)) return(NULL)
    path <- file.path(out_dir, paste0(nm, "_", ts, ".png"))
    try(
      ggplot2::ggsave(path, plot = plt, width = 10, height = 8,
                      dpi = 150, bg = "white"),
      silent = TRUE
    )
    path
  })

  # 3b. Save tables → build path params
  table_paths <- purrr::imap(tables, function(tbl, nm) {
    if (is.null(tbl)) return(NULL)
    path <- file.path(out_dir, paste0(nm, "_", ts, ".csv"))
    try(utils::write.csv(tbl, path, row.names = FALSE), silent = TRUE)
    path
  })

  # Rename to *_plot_path / *_table_path keys for execute_params,
  # matching the param names declared in the QMD templates.
  path_params <- c(
    stats::setNames(plot_paths,  paste0(names(plot_paths),  "_plot_path")),
    stats::setNames(table_paths, paste0(names(table_paths), "_table_path"))
  )

  # 4. Render
  tryCatch({
    tmp_dir <- file.path(tempdir(), paste0(tmp_dir_prefix, ts))
    if (!dir.exists(tmp_dir)) dir.create(tmp_dir, recursive = TRUE)
    tmp_qmd <- file.path(tmp_dir, template_name)
    file.copy(template_path, tmp_qmd, overwrite = TRUE)

    quarto::quarto_render(
      input       = tmp_qmd,
      output_file = "report.html",
      execute_params = c(path_params, params)
    )

    # 5. Copy rendered HTML to Shiny's expected path
    out_html <- file.path(tmp_dir, "report.html")
    if (!file.exists(out_html)) stop("Rendered report not found at ", out_html)
    file.copy(out_html, file, overwrite = TRUE)

    # 6a. Success
    shiny::removeNotification(notification_id)
    shiny::showNotification("Report generated successfully!",
                            type = "message", duration = 3)
    output$reportStatus <- shiny::renderUI({
      shiny::tagList(
        shiny::icon("check-circle"),
        shiny::span(paste(" Report generated at",
                          format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
      )
    })
  }, error = function(e) {
    # 6b. Error
    shiny::removeNotification(notification_id)
    shiny::showNotification(
      paste("Error generating report:", e$message),
      type = "error", duration = 10
    )
    output$reportStatus <- shiny::renderUI({
      shiny::tagList(
        shiny::icon("exclamation-triangle"),
        shiny::span(paste(" Error generating report:", e$message))
      )
    })
  })

  invisible(NULL)
}


#' Create a tab-visit cache for a plot or table reactive
#'
#' Encapsulates the repeated three-part pattern used throughout the scenario and
#' comparison modules:
#' \enumerate{
#'   \item A \code{reactiveVal(NULL)} that stores the last evaluated result.
#'   \item An \code{observeEvent} on \code{input$analyse} that resets the cache
#'     to \code{NULL} whenever a new analysis is run, preventing stale plots
#'     from appearing in downloaded reports.
#'   \item An \code{observeEvent} on \code{input[[tabs_id]]} that populates the
#'     cache when the user navigates to \code{tab_id}.
#' }
#'
#' The cache is used by the report download handler so that plots do not need to
#' be re-evaluated at download time if the user has already visited the tab.
#' The reset on \code{input$analyse} ensures that if the user runs a new analysis
#' and downloads the report without revisiting a tab, the report handler's
#' \code{\%||\%} fallback correctly re-evaluates the reactive rather than
#' returning a plot from the previous analysis.
#'
#' Must be called from inside \code{shiny::moduleServer()} so that the observers
#' are correctly bound to the active session.
#'
#' @param gg_reactive A reactive expression (no parentheses) that returns the
#'   plot or table object to cache.
#' @param tab_id The value of the tab panel (as set in \code{tabPanel(value = ...)})
#'   that should trigger cache population.
#' @param input Shiny input object from the enclosing \code{moduleServer}.
#' @param tabs_id Character. The input ID of the \code{tabsetPanel} to watch.
#'   Default \code{"tabs"}.
#'
#' @return A \code{reactiveVal} initialised to \code{NULL}. Assign the return
#'   value to a named variable (e.g. \code{costPlotData_cache <- fmake_tab_cache(...)}).
#'
#' @noRd
#'
fmake_tab_cache <- function(gg_reactive, tab_id, input, tabs_id = "tabs") {
  cache <- shiny::reactiveVal(NULL)

  # Reset cache on every new analysis so the report handler's %||% fallback
  # re-evaluates the reactive rather than returning a plot from a prior run.
  shiny::observeEvent(input$analyse, {
    cache(NULL)
  }, ignoreInit = TRUE)

  # Populate cache when the user visits this tab.
  shiny::observeEvent(input[[tabs_id]], {
    if (input[[tabs_id]] == tab_id) {
      val <- tryCatch(gg_reactive(), error = function(e) NULL)
      if (!is.null(val)) cache(val)
    }
  })

  cache
}


#' Set up paired lock-in / lock-out observers
#'
#' For each conservation feature that appears in both the lock-in and lock-out
#' checkbox lists, registers a pair of \code{observeEvent} handlers so that
#' enabling one automatically disables the other (mutual exclusion).
#'
#' This helper must be called from inside \code{shiny::moduleServer()} so that
#' the observers are correctly bound to the active session.
#'
#' @param input Shiny input object (from the enclosing \code{moduleServer}).
#' @param check_lockIn Data frame. Output of \code{fcreate_check()} for the
#'   lock-in type. Must contain column \code{id_in}.
#' @param check_lockOut Data frame. Output of \code{fcreate_check()} for the
#'   lock-out type. Must contain column \code{id_in}.
#' @param li_prefix Character. The prefix used in lock-in input IDs
#'   (e.g. \code{"checkLI_"} for scenario, \code{"check1LI_"} for compare
#'   scenario 1).
#' @param lo_prefix Character. The prefix used in lock-out input IDs
#'   (e.g. \code{"checkLO_"} for scenario, \code{"check1LO_"} for compare
#'   scenario 1).
#'
#' @return Invisibly \code{NULL}. Called for its side-effect of registering
#'   Shiny observers.
#'
#' @noRd
#'
fsetup_lock_observers <- function(input, check_lockIn, check_lockOut,
                                  li_prefix, lo_prefix) {
  get_feature <- function(id, prefix) stringr::str_remove(id, prefix)

  lockIn_features  <- purrr::map_chr(check_lockIn$id_in,  get_feature, prefix = li_prefix)
  lockOut_features <- purrr::map_chr(check_lockOut$id_in, get_feature, prefix = lo_prefix)

  shared_features <- intersect(lockIn_features, lockOut_features)

  purrr::walk(shared_features, function(feat) {
    lockInId  <- paste0(li_prefix, feat)
    lockOutId <- paste0(lo_prefix, feat)
    shiny::observeEvent(input[[lockInId]], {
      shinyjs::toggleState(lockOutId)
    }, ignoreInit = TRUE)
    shiny::observeEvent(input[[lockOutId]], {
      shinyjs::toggleState(lockInId)
    }, ignoreInit = TRUE)
  })

  invisible(NULL)
}



#' Download Plot - Server Side
#'
#' Creates a \code{downloadHandler} for a ggplot or data frame output.
#'
#' @param gg_reactive A \strong{reactive} (callable, no parentheses) that
#'   returns the current ggplot object or data frame. Evaluated lazily inside
#'   the \code{content} function so it always reflects the latest analysis.
#' @param gg_prefix Character. Filename prefix (e.g. \code{"Solution"},
#'   \code{"DataSummary"}).
#' @param time_date_reactive A \strong{reactive} or \strong{reactiveVal}
#'   (callable, no parentheses) that returns a timestamp string used in the
#'   filename. Evaluated lazily inside \code{filename}.
#' @param type Character. Either \code{"plot"} (default, saves a PNG via
#'   \code{ggplot2::ggsave()}) or \code{"table"} (saves a CSV via
#'   \code{readr::write_csv()}).
#' @param width,height Numeric. PNG dimensions in inches. Default 19 × 18.
#'   Ignored when \code{type = "table"}.
#'
#' @noRd
#'
fDownloadPlotServer <- function(gg_reactive, gg_prefix, time_date_reactive,
                                type = c("plot", "table"),
                                width = 19, height = 18) {

  type <- match.arg(type)

  if (type == "plot") {

    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste0(gg_prefix, "_", time_date_reactive(), ".png")
      },
      content = function(file) {
        gg <- gg_reactive()
        if (is.null(gg)) {
          shiny::showNotification(
            "Please run an analysis and generate the plot before downloading.",
            type = "error", duration = 5
          )
          stop("No plot available to download.")
        }
        ggplot2::ggsave(file,
                        plot = gg,
                        device = "png", width = width, height = height,
                        units = "in", dpi = 400)
      }
    )

  } else {

    dlPlot <- shiny::downloadHandler(
      filename = function() {
        paste0(gg_prefix, "_", time_date_reactive(), ".csv")
      },
      content = function(file) {
        dat <- gg_reactive()
        if (is.null(dat) || !is.data.frame(dat)) {
          shiny::showNotification(
            "No data available to download yet. Please run an analysis first.",
            type = "error", duration = 5
          )
          stop("No data available to download.")
        }
        readr::write_csv(dat, file)
      }
    )

  }

  return(dlPlot)
}


#' Download a solution sf object as a GeoJSON file
#'
#' Shared helper used by \code{mod_2scenario_server} and \code{mod_3compare_server}
#' for the individual-scenario spatial download buttons. Transforms the solution
#' to WGS84 (EPSG:4326), renames \code{solution_1} to \code{solution} if needed,
#' and writes a GeoJSON file.
#'
#' @param sol An \code{sf} object returned by the solver (must contain a
#'   \code{solution_1} or \code{solution} column).
#' @param file Character. Output file path supplied by Shiny's
#'   \code{downloadHandler} content function.
#'
#' @return Invisibly \code{NULL}; called for its side-effect of writing \code{file}.
#'
#' @noRd
#'
fdownload_solution_geojson <- function(sol, file) {
  if (!inherits(sol, "sf")) {
    shiny::showNotification(
      "Please run an analysis before downloading the spatial file.",
      type = "error", duration = 5
    )
    stop("No solution available.")
  }

  # Normalise column name: solution_1 -> solution
  if (!("solution" %in% names(sol))) {
    if ("solution_1" %in% names(sol)) {
      names(sol)[names(sol) == "solution_1"] <- "solution"
    } else {
      sol <- dplyr::mutate(sol, solution = NA_integer_)
    }
  }

  sol_out <- sol %>%
    dplyr::select("solution") %>%
    sf::st_transform("EPSG:4326")

  sf::st_write(sol_out, file, driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
  invisible(NULL)
}
