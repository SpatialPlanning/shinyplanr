# tests/testthat/helper-config.R
#
# Populates shinyplanr_config with the sysdata.rda stubs before any test runs.
# This mirrors what load_config() does at runtime. Required because
# shinyplanr_config starts empty at package load — load_config() must be called
# before run_app() in production, and this helper plays the equivalent role for
# tests that call app_ui() or get_pkg_config().

local({
  pkg_env  <- asNamespace("shinyplanr")
  cfg_env  <- shinyplanr:::shinyplanr_config
  required <- shinyplanr:::.shinyplanr_required_keys
  for (nm in required) {
    if (exists(nm, envir = pkg_env, inherits = FALSE)) {
      cfg_env[[nm]] <- get(nm, envir = pkg_env, inherits = FALSE)
    }
  }
})
