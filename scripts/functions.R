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
    addPolygons(
      data  = ply,
      label = ~sanctuary)
}

nc_meta <- function(var){
  v <- datasets_nc |>
    filter(var == !!var)

  cat(glue(
    '### {v$var_header} {{data-height=300}}

  <details>
  <summary><span style="color: #737373; font-size: 12px">Metadata</span></summary>
  {v$metadata_nc}
  </details>
  '))
}

nc_plot <- function(var){
  v <- datasets_nc |>
    filter(var == !!var)

  clim_csv |>
    read_csv() |>
    filter(
      year >= glue("{v$yr_beg}-01-01") &
      year <= glue("{v$yr_end}-12-31")) |>
    plot_ts(
      fld_avg  = glue("{var}_mean"),
      fld_sd   = glue("{var}_sd"),
      fld_date = "year",
      color    = v$plot_color,
      label    = v$plot_label)
}
