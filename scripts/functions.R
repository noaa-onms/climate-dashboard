map_sanctuary <- function(ply){
  librarian::shelf(
    leaflet)

  leaflet(width = "100%", height = "95vh") |>
    # add base: blue bathymetry and light brown/green topography
    addProviderTiles(
      "Esri.OceanBasemap",
      options = providerTileOptions(
        variant = "Ocean/World_Ocean_Base")) |>
    # add reference: placename labels and borders
    addProviderTiles(
      "Esri.OceanBasemap",
      options = providerTileOptions(
        variant = "Ocean/World_Ocean_Reference")) |>
    addPolygons(data = ply)
}

make_navbar <- function(){
  librarian::shelf(
    dplyr, glue, here, jsonlite, sf)

  navbar_html <- here("_navbar.html")

  sanctuaries <- readRDS(here("data/sanctuaries.rds"))
  navbar_json <- list(
    title = "Sanctuaries",
    items = sanctuaries |>
      st_drop_geometry() |>
      arrange(sanctuary) |>
      mutate(
        href = glue("./{nms}.html")) |>
      select(title = sanctuary, href)) |>
    toJSON(auto_unbox = T)

  paste(
    '<script id="flexdashboard-navbar" type="application/json">',
    '[',
    navbar_json,
    ']',
    '</script>',
    sep = '\n') |>
    writeLines(navbar_html)
}
