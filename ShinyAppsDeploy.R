options(rsconnect.packrat = TRUE)

files <- rsconnect::listBundleFiles(".")$contents

files <- files[stringr::str_which(files, "data-raw/", negate = TRUE)]

# rsconnect::deployApp(appName = "shinyplanr_Vanuatu", appFiles = files)


rsconnect::deployApp(appName = "shinyplanr_Kosrae", appFiles = files)
