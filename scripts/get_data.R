# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, fs, glue, here, lubridate, readr, sf, stringr, tibble,
  calcofi/calcofi4r, # temporarily to get Chumash
  noaa-onms/onmsR,
  marinebon/extractr
  )
# TODO: fix onmsr -- Warning message: replacing previous import ‘magrittr::extract’ by ‘tidyr::extract’ when loading ‘onmsR’
# devtools::load_all(here("../../marinebon/extractr"))
# devtools::install_local(here::here("../../marinebon/extractr"))
options(readr.show_col_types = F)

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

# ERDDAP datasets ----
ed_datasets <- read_csv(here("data/datasets.csv"))

# TODO: assign vars to sanctuaries since Coral Reef Watch not applicable to all

# iterate over ERDDAP datasets ----
# for (i_ed in 1:nrow(ed_datasets)){ # i_ed = 3
for (i_ed in c(3)){ # i_ed = 3

  ed_row <- ed_datasets |> slice(i_ed)
  message(glue("dataset: {ed_row$var} ~ {Sys.time()}"))

  ed            <- extractr::get_ed_info(ed_row$url)
  ed_date_range <- extractr::get_ed_dates(ed)
  ed_dates      <- extractr::get_ed_dates_all(
    ed, min(ed_date_range), max(ed_date_range))

  # iterate over sanctuaries ----
  for (i_s in 1:nrow(sanctuaries)){ # i_s = 1
    ply <- slice(sanctuaries, i_s)
    message(glue("  sanctuary: {ply$nms} ~ {Sys.time()}"))

    dir_tif <- here(glue("data/{ed_row$var}/{ply$nms}"))
    ts_csv  <- here(glue("data/{ed_row$var}/{ply$nms}.csv"))

    if (file_exists(ts_csv)){
      d_csv <- read_csv(ts_csv)
      csv_dates <- d_csv |> pull(date)
      ed_dates_todo <- setdiff(ed_dates, csv_dates) |>
        as.Date(origin = "1970-01-01")
    } else {
      d_csv <- tibble(
        lyr   = character(0),
        date  = Date(0),
        mean  = numeric(),
        sd    = numeric(),
        isNA  = numeric(),
        notNA = numeric())
      ed_dates_todo <- ed_dates
    }

    tif_dates <- tibble(
      tif = dir_ls(dir_tif, glob = "*.tif")) |>
      mutate(
        date = str_replace(
          tif,
          ".*([0-9]{4})\\.([0-9]{2})\\.([0-9]{2})\\.tif",
          "\\1-\\2-\\3") |> as.Date()) |>
      pull(date)
    ed_dates_todo <- setdiff(ed_dates_todo, tif_dates) |> as.Date(origin = "1970-01-01")
    # range(ed_dates_todo) # "2005-10-28" "2023-05-03"

    if (length(ed_dates_todo) == 0)
      next

    message(glue("  have {nrow(d_csv)} dates in CSV, {length(tif_dates)} dates as TIFs, fetching {length(ed_dates_todo)} dates from ERDDAP ~ {Sys.time()}"))

    dir_create(dir_tif)
    for (i_d in 1:length(ed_dates_todo)){  # date_i = ed_dates[1]
      date_i = ed_dates_todo[i_d]

      if (class(date_i) == "numeric") date_i <- as.Date(date_i, origin = "1970-01-01")
      message(glue("date_i: {date_i}"))

      grds <- get_ed_grds(
        ed, ed_var = ed_row$var, ply = ply, dir_tif = dir_tif,
        date_beg = date_i, date_end = date_i, del_cache=T, verbose = F)

      # every 1,000 dates load and refresh
      if (i_d %% 10){

        tifs <- list.files(dir_tif, "tif$", full.names = T)
        lyrs <- basename(tifs) |> str_replace("^grd_", "") |> str_replace("\\.tif$", "")
        grds <- terra::rast(tifs) # maximum seems to be 4K files
        names(grds) <- lyrs

        d_ed <- grds_to_ts(
          grds, fxns = c("mean", "sd", "isNA", "notNA"),
          verbose = T)

        # merge newly fetched ERDDAP data with existing csv and write out
        d_csv |>
          bind_rows(d_ed) |>
          # TODO: remove duplicates
          arrange(date) |>
          write_csv(ts_csv)

        # refresh
        d_csv <- read_csv(ts_csv)
        dir_delete(dir_tif)
        dir_create(dir_tif)
      }
    }

    tifs <- list.files(dir_tif, "tif$", full.names = T)

    lyrs <- basename(tifs) |> str_replace("^grd_", "") |> str_replace("\\.tif$", "")
    grds <- terra::rast(tifs) # maximum seems to be 4K files
    names(grds) <- lyrs

    d_ed <- grds_to_ts(
      grds, fxns = c("mean", "sd", "isNA", "notNA"),
      verbose = T)

    # merge newly fetched ERDDAP data with existing csv and write out
    d_csv |>
      bind_rows(d_ed) |>
      # TODO: remove duplicates
      arrange(date) |>
      write_csv(ts_csv)
    d_csv <- read_csv(ts_csv)

    # remove space-consuming tifs
    dir_delete(dir_tif)
  }
}
