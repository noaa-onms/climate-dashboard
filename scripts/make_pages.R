# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, fs, glue, here, rmarkdown, sf, stringr)

dir_delete(here("docs"))
dir_create(here("docs"))

sanctuaries <- readRDS(here("data/sanctuaries.rds")) |>
  arrange(sanctuary)

for (i in 1:nrow(sanctuaries)){ # i = 1
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

# make index
render(
  here("index.Rmd"),
  output_file = here(glue("docs/index.html")))

# copy dependent files
fs::file_copy("_style.css", here("docs/_style.css"))


