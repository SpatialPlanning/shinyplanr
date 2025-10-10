library(tidyverse)

# Set packrat option (as in original code)
options(rsconnect.packrat = TRUE)

# 1. Get a comprehensive list of all files recursively in the current directory.
# We include all.files = TRUE to capture dotfiles (like .Rprofile or .gitignore),
# but exclude directories themselves (include.dirs = FALSE).
all_files <- list.files(
  path = ".",
  recursive = TRUE,
  all.files = TRUE,
  include.dirs = FALSE
)

# 2. Use stringr::str_subset() (a cleaner alternative to str_which and subsetting)
# to exclude the specified directories and files. The 'negate = TRUE' argument
# ensures we only keep files that DO NOT match the pattern.

files_to_deploy <- all_files %>%
  stringr::str_subset(pattern = "^data-raw/", negate = TRUE) %>%
  stringr::str_subset(pattern = "^.git/", negate = TRUE) %>%
  stringr::str_subset(pattern = "^tests/", negate = TRUE) %>%
  stringr::str_subset(pattern = "^.Rproj.user/", negate = TRUE) %>%
  stringr::str_subset(pattern = "^man/", negate = TRUE) %>%
  stringr::str_subset(pattern = "ShinyAppsUpdate", negate = TRUE)

# 3. Deploy the application using the curated file list
rsconnect::deployApp(
  appName = "Fiji",
  appFiles = files_to_deploy
)
