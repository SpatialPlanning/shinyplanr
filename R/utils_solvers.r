# Ensure rcbc is imported — it is the CBC solver backend used by
# prioritizr::add_cbc_solver(). prioritizr calls rcbc internally, but CHECK
# requires at least one importFrom declaration for packages listed in Imports.
#' @importFrom rcbc cbc_solve
NULL

#' Solve prioritization problem with error handling
#'
#' Wraps the solve() call with standardized error handling and alerts.
#'
#' @param problem_data The prioritizr problem object to solve
#'
#' @return sf object with solution, or NULL if solve fails
#'
#' @noRd
#'
fsolve_problem <- function(problem_data) {
    # define alternate versions of functions with message handling
    q_presolve_check <- purrr::quietly(prioritizr::presolve_check)
    s_solve <- purrr::safely(solve)

    # run presolve checks
    check_result <- q_presolve_check(problem_data)

    # if checks failed, then return warning messages
    if (!isTRUE(check_result$result)) {

        # Show user-friendly alert
        shinyalert::shinyalert(
            "Error",
            check_result$warnings,
            type = "error",
            callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
        )
        return(NULL)
    }


    # attempt to solve the problem
    ## note we use presolve_check = FALSE to avoid redoing the checks
    solve_result <- s_solve(problem_data, run_checks = FALSE)

    # if solve failed, then return error message
    if (!is.null(solve_result$error)) {

   # Show user-friendly alert
        shinyalert::shinyalert(
            title = "Error",
            text = paste("<h4>", solve_result$error$message, "</h4>", "<br>",
                    "<p>", solve_result$error$body, "</p>"),
            type = "error",
            html = TRUE,
            callbackR = shinyjs::runjs("window.scrollTo(0, 0)")
        )
        return(NULL)
    }

    # otherwise, return solution
    return(solve_result$result)
}


#' Solve problem and build log
#'
#' Runs a full solve cycle while capturing a clean textual summary of the
#' prioritizr problem (summary(prob)) and a solve summary including runtime,
#' planning units selected, total/selected area (km^2), and total/selected cost.
#'
#' @param problem_data prioritizr problem object
#' @param cost_id name of the cost column to summarize (e.g., "Cost_X" or "Cost_None")
#'
#' @return list(solution = sf or NULL, log = single character string)
#'
#' @noRd
fsolve_with_log <- function(problem_data, cost_id = "Cost_None") {
    solve_start <- Sys.time()

    # Header
    log_lines <- character(0)
    log_lines <- c(log_lines, "========================================")
    log_lines <- c(log_lines, "PRIORITIZR PROBLEM SETUP")
    log_lines <- c(log_lines, "========================================")
    log_lines <- c(log_lines, paste("Timestamp:", format(solve_start, "%Y-%m-%d %H:%M:%S")))
    log_lines <- c(log_lines, "")

    # Capture summary(problem_data) to a temporary file and clean ANSI
    problem_summary <- tryCatch(
        {
            tmp <- tempfile()
            withr::with_options(
                list(crayon.enabled = FALSE, cli.num_colors = 1),
                {
                    withr::with_output_sink(tmp, {
                        withr::with_message_sink(tmp, {
                            summary(problem_data)
                        })
                    })
                }
            )
            captured <- readLines(tmp, warn = FALSE)
            unlink(tmp)

            # Strip ANSI/escape sequences and artifacts
            captured <- gsub("\033\\[[0-9;?]*[ -/]*[@-~]", "", captured) # CSI
            captured <- gsub("\\x1b\\[[0-9;?]*[ -/]*[@-~]", "", captured) # CSI (hex)
            captured <- gsub("\033.", "", captured) # ESC + char
            captured <- gsub("\\x1b.", "", captured) # ESC + char (hex)
            captured <- gsub("^\u001bG[0-9]+;", "", captured) # ESC G3;
            captured <- gsub("^\u001b?[A-Z][0-9]+;", "", captured) # G3;
            captured <- gsub("^[0-9]+;", "", captured) # Leading digit sequences like "3;"
            captured <- gsub("\u001bg$", "", captured) # ESC g
            captured <- gsub("(^|\n)g$", "\\1", captured) # lone g lines
            captured <- gsub("\r", "", captured) # CR
            captured <- trimws(captured, which = "both")
            captured <- captured[captured != ""]

            captured
        },
        error = function(e) {
            c("Could not capture problem output.", paste("Error:", e$message))
        }
    )

    log_lines <- c(log_lines, problem_summary)
    log_lines <- c(log_lines, "")

    # Solve
    sol <- fsolve_problem(problem_data)

    # Runtime
    solve_end <- Sys.time()
    runtime_secs <- as.numeric(difftime(solve_end, solve_start, units = "secs"))

    # Solve summary footer
    log_lines <- c(log_lines, "========================================")
    log_lines <- c(log_lines, "SOLVE SUMMARY")
    log_lines <- c(log_lines, "========================================")
    log_lines <- c(log_lines, paste("Runtime:", round(runtime_secs, 2), "seconds"))

    if (inherits(sol, "sf")) {
        log_lines <- c(log_lines, "Status: Solution found")

        # PU selection counts
        n_selected <- sum(sol$solution_1 == 1, na.rm = TRUE)
        n_total <- nrow(sol)
        pct_selected <- round(100 * n_selected / max(n_total, 1), 2)
        log_lines <- c(log_lines, paste("Planning units selected:", n_selected, "of", n_total, paste0("(", pct_selected, "%)")))

        # Area (km^2)
        total_area_all_km2 <- tryCatch(
            {
                sum(as.numeric(sf::st_area(sol)), na.rm = TRUE) / 1e6
            },
            error = function(e) NA_real_
        )
        total_area_sel_km2 <- tryCatch(
            {
                sum(as.numeric(sf::st_area(sol[sol$solution_1 == 1, ])), na.rm = TRUE) / 1e6
            },
            error = function(e) NA_real_
        )
        if (is.finite(total_area_all_km2) && total_area_all_km2 > 0 && is.finite(total_area_sel_km2)) {
            pct_area <- round(100 * total_area_sel_km2 / total_area_all_km2, 2)
            log_lines <- c(
                log_lines,
                paste0(
                    "Area selected: ", format(round(total_area_sel_km2, 2), big.mark = ","), " km^2 of ",
                    format(round(total_area_all_km2, 2), big.mark = ","), " km^2 (", pct_area, "%)"
                )
            )
        }

        # Cost
        if (!identical(cost_id, "Cost_None") && cost_id %in% names(sol)) {
            total_cost_all <- sum(sol[[cost_id]], na.rm = TRUE)
            total_cost_sel <- sum(sol[[cost_id]][sol$solution_1 == 1], na.rm = TRUE)
            if (is.finite(total_cost_all) && total_cost_all > 0) {
                pct_cost <- round(100 * total_cost_sel / total_cost_all, 2)
                log_lines <- c(
                    log_lines,
                    paste0(
                        "Cost selected (", cost_id, "): ", format(round(total_cost_sel, 2), big.mark = ","),
                        " of ", format(round(total_cost_all, 2), big.mark = ","), " (", pct_cost, "%)"
                    )
                )
            } else {
                log_lines <- c(log_lines, paste0("Cost selected (", cost_id, "): ", round(total_cost_sel, 2)))
            }
        }

        log_lines <- c(log_lines, "Feasibility: Feasible solution returned")
    } else {
        log_lines <- c(log_lines, "Status: No solution found")
        log_lines <- c(log_lines, "Feasibility: Infeasible or solver error")
    }

    log_lines <- c(log_lines, "")
    log_lines <- c(log_lines, "========================================")

    list(solution = sol, log = paste(log_lines, collapse = "\n"))
}
