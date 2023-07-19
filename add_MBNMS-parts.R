librarian::shelf(
  dplyr, glue, here, mapview, readr, sf, stringr,
  marinebon/extractr)
# devtools::load_all("~/Github/marinebon/extractr")
source(here("scripts/functions.R"))

sanctuaries_rds <- here("data/sanctuaries.rds")
sanctuaries <- readRDS(sanctuaries_rds)

if (!"MBNMS-Davidson" %in% sanctuaries$nms){
  url_pfx   <- "https://github.com/noaa-onms/seascapes-app/raw/main/data/ply"
  url_david <- glue("{url_pfx}/mbnms-david.geojson")
  url_main  <- glue("{url_pfx}/mbnms-main.geojson")

  ply_parts <- read_sf(url_david) |>
    mutate(
      nms       = "MBNMS-david",
      sanctuary = "Monterey Bay - Davidson Seamount") |>
    rbind(
      read_sf(url_main) |>
        mutate(
          nms       = "MBNMS-main",
          sanctuary = "Monterey Bay - Mainland")) |>
    select(sanctuary, nms)
  st_geometry(ply_parts) <- "geom"

  sanctuaries <- sanctuaries |>
    rbind(ply_parts)

  write_rds(sanctuaries, sanctuaries_rds)
}




