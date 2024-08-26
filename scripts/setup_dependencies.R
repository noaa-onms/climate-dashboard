# This script is simply for managing the /DESCRIPTION.txt file and
#   R package dependencies used by the Github Action:
#     * /.github/workflows/update-dashboard.yaml
#   based on R package dependencies in:
#     * /scripts/
#        * get_data.R
#        * make_pages.R
#     * /_sanctuary.Rmd
usethis::use_description(check_name = F)
usethis::use_dev_package("extractr", remote = "marinebon/extractr")
usethis::use_dev_package("onmsR", remote = "noaa-onms/onmsR")
pkgs = c(
  "dplyr", "flexdashboard", "fs", "glue", "here", "lubridate", "mapview",
  "purrr", "readr", "rmarkdown", "sf", "stringr", "terra", "tibble", "tidyr")
sapply(pkgs, usethis::use_package)
