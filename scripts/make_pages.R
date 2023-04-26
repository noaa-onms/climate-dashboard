# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, glue, here, rmarkdown, sf, stringr)
# devtools::install_github("rstudio/flexdashboard")

sanctuaries <- readRDS(here("data/sanctuaries.rds")) |>
  arrange(sanctuary)
for (i in 1:nrow(sanctuaries)){ # i = 1
#for (i in 1:3){ # i = 2
  s <- slice(sanctuaries, i)
  out_html <- here(glue("{s$nms}.html"))
  message(glue("{s$sanctuary} -> {basename(out_html)}"))

  render(
    here("_sanctuary.Rmd"),
    output_file = out_html,
    params = list(
      sanctuary = s$sanctuary,
      nms       = s$nms))
}





