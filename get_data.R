# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, glue, here, sf, stringr,
  calcofi/calcofi4r, # temporarily to get Chumash
  noaa-onms/onmsR #, marinebon/extractr
  )
# TODO: fix onmsr -- Warning message: replacing previous import ‘magrittr::extract’ by ‘tidyr::extract’ when loading ‘onmsR’
devtools::load_all("~/Github/marinebon/extractr/")

# notes ----

# * [extractr • extractr](https://marinebon.github.io/extractr/articles/extractr.html)
# * [indicators - climate vulnerability for sanctuaries - Google Sheets](https://docs.google.com/spreadsheets/d/1H8JGwdVM5YCZXPhcVLNpSvITlxCraDKUwMVpr_5Rn3Q/edit#gid=0)

# get sanctuaries ----
sanctuaries_rds <- here("data/sanctuaries.rds")
if (!file.exists(sanctuaries_rds)){
  # table(cc_places$category)
  sanctuaries <- onmsR::sanctuaries |>
    select(-spatial) |>
    filter(
      str_detect(nms, "NMS"),
      !nms %in% c("WSCNMS")) |>
    rbind(
      # TODO: + Chumash Proposed Action in onmsr
      calcofi4r::cc_places |>
        filter(key == "nms_cp") |>
        mutate(
          nms = "CPNMS") |>
        select(
          sanctuary = name,
          nms, geom ) ) |>
    arrange(nms)
  # TODO: ∆ "Flower Garden BanksUpdated 03/23/21" to "Flower Garden Banks" in onmsr
  sanctuaries$sanctuary[sanctuaries$nms == "FGBNMS"] = "Flower Garden Banks"
}
sanctuaries <- readRDS(sanctuaries_rds)

# choose ERDDAP dataset ----
ed_url   <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.html"
ed_var   <- "CRW_SST"
ed_dates <- glue("{1986:2023}-01-01")
# TODO: assign vars to sanctuaries since Coral Reef Watch not applicable to all

ed <- extractr::get_ed_info(ed_url)

# iterate over sanctuaries ----
for (i in 1:nrow(sanctuaries)){ # i = 1
  ply <- slice(sanctuaries, i)
  message(glue("sanctuary: {ply$nms} ~ {Sys.time()}"))

  dir_tif <- here(glue("data/{ed_var}/{ply$nms}"))
  ts_csv  <- here(glue("data/{ed_var}/{ply$nms}.csv"))

  dir.create(dir_tif, showWarnings = F, recursive = T)

  for (date_i in ed_dates){  # date_i = ed_dates[1]
    # devtools::load_all("~/Github/marinebon/extractr")
    grds <- get_ed_grds(
      ed, ed_var = ed_var, ply = ply, dir_tif = dir_tif,
      date_beg = date_i, date_end = date_i,
      verbose = T) # , date_beg = "2021-10-01")
  }
  grds <- terra::rast(list.files(dir_tif, "tif$", full.names = T))
  # mapview::mapView(grds[[1]])

  ts <- grds_to_ts(
    grds, fxns = c("mean", "sd", "isNA", "notNA"),
    ts_csv = ts_csv, verbose = T)

  # plot_ts(ts_csv, "mean", "sd", label = ed_var)
}

