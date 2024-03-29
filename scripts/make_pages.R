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

dir_delete(here("docs"))
dir_create(here("docs"))

nmsanctuaries <- readRDS(here("data/sanctuaries.rds")) |>
  arrange(sanctuary) |>
  filter(sanctuary != "Monitor") # TODO: resolve issues with no data for Monitor

# _navbar.html: only update if Sanctuaries change
# make_navbar()

for (i in 1:nrow(nmsanctuaries)){ # i = 1

  message(glue("nrow(nmsanctuaries): {nrow(nmsanctuaries)}"))

  s <- slice(nmsanctuaries, i)
  out_html <- here(glue("docs/{s$nms}.html"))
  message(glue("{s$sanctuary} -> {basename(out_html)}"))

  render(
    here("_sanctuary.Rmd"),
    output_file = out_html,
    params = list(
      sanctuary = s$sanctuary,
      nms       = s$nms))
}

# make index
render(
  here("index.Rmd"),
  output_file = here(glue("docs/index.html")))

# copy dependent files
fs::file_copy("_style.css", here("docs/_style.css"))


