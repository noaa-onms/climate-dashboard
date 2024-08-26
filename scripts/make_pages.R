# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr,
  # marinebon/extractr,
  flexdashboard,
  fs, glue, here,
  # "noaa-onms/onmsR",
  rmarkdown, sf, stringr,
  quiet = T)
source(here("scripts/functions.R"))

redo_all = F

if (redo_all){
  dir_delete(here("docs"))
  dir_create(here("docs"))
}

sanctuaries <- readRDS(here("data/sanctuaries.rds")) |>
  arrange(nms) |>
  filter(sanctuary != "Monitor") # TODO: resolve issues with no data for Monitor
  # filter(nms == "FKNMS")       # DEBUG FKNMS

# _navbar.html: only update if Sanctuaries change
# make_navbar()

for (i in 1:nrow(sanctuaries)){ # i = 1

  message(glue("nrow(sanctuaries): {nrow(sanctuaries)}"))

  s <- slice(sanctuaries, i)
  out_html <- here(glue("docs/{s$nms}.html"))
  message(glue("{s$sanctuary} -> {basename(out_html)}"))

  render(
    here("_sanctuary.Rmd"),
    output_file = out_html,
    params = list(
      sanctuary = s$sanctuary,
      nms       = s$nms))
}

if (redo_all){
  # make index
  render(
    here("index.Rmd"),
    output_file = here(glue("docs/index.html")))

  # copy dependent files
  fs::file_copy("_style.css", here("docs/_style.css"))
}



