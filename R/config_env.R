# Internal package environment for storing runtime config
#
# This environment is declared at package load time and populated by
# load_config() before run_app() is called. Because the *binding* of
# shinyplanr_config in the namespace is locked (you cannot replace the
# environment object itself), but the *environment* it points to is not
# locked, we can freely add or overwrite keys inside it without ever
# calling unlockBinding(). This avoids the R CMD check NOTE:
#   "Found the following possibly unsafe calls: unlockBinding(nm, pkg_env)"
#
# Pattern borrowed from BioOceanObserver (CSIRO):
#   pkg.env <- new.env(parent = emptyenv())
#
# All config keys (Dict, raw_sf, options, bndry, overlay, tx, etc.)
# are stored here after load_config() runs.

shinyplanr_config <- new.env(parent = emptyenv())
