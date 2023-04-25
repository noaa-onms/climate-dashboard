# load packages ----
if (!installed.packages("librarian"))
  install.packages("librarian")
librarian::shelf(
  dplyr, glue, here, sf, stringr,
  calcofi/calcofi4r, # temporarily to get Chumash
  noaa-onms/onmsR #, marinebon/extractr
  )
devtools::load_all("~/Github/marinebon/extractr/")

# notes ----

# * [extractr • extractr](https://marinebon.github.io/extractr/articles/extractr.html)
# * [indicators - climate vulnerability for sanctuaries - Google Sheets](https://docs.google.com/spreadsheets/d/1H8JGwdVM5YCZXPhcVLNpSvITlxCraDKUwMVpr_5Rn3Q/edit#gid=0)

# get sanctuaries ----

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

# choose ERDDAP dataset ----
ed_url   <- "https://coastwatch.pfeg.noaa.gov/erddap/griddap/NOAA_DHW.html"
ed_var   <- "CRW_SST"

ed <- extractr::get_ed_info(ed_url)

# iterate over sanctuaries ----
for (i in 1:nrow(sanctuaries)){ # i = 1
  ply <- slice(sanctuaries, i)

  dir_tif <- here(glue("data/{ed_var}/{ply$nms}"))
  ts_csv  <- here(glue("data/{ed_var}/{ply$nms}.csv"))

  dir.create(dir_grds, showWarnings = F, recursive = T)

  grds <- get_ed_grds(
    ed, ed_var = ed_var, ply = ply, dir_tif = dir_tif,
    date_beg = "2023-04-20",
    date_end = "2023-04-24",
    verbose = T) # , date_beg = "2021-10-01")

  # devtools::load_all("~/Github/marinebon/extractr")
  ts <- grds_to_ts(grds, ts_csv = ts_csv, verbose = T)

  # plot_ts(ts_csv, "mean", "sd", label = ed_var)
}




