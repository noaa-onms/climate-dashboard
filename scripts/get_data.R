# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, fs, glue, here, lubridate, purrr, readr, sf, stringr, terra, tibble, tidyr,
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
  for (i_s in 1:nrow(sanctuaries)){ # i_s = 2
    ply <- slice(sanctuaries, i_s)
    message(glue("  sanctuary: {ply$nms} ~ {Sys.time()}"))
    bb <- sf::st_bbox(ply)

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

    if (class(ed_dates_todo) == "numeric")
      ed_dates_todo <- as.Date(ed_dates_todo, origin = "1970-01-01")

    if (length(ed_dates_todo) == 0)
      next

    ed_dates_todo <- ed_dates[
      ed_dates >= min(ed_dates_todo) &
      ed_dates <= max(ed_dates_todo)]

    n_dates <- 500
    for (i_beg in seq(1, length(ed_dates_todo), by = n_dates)){  # i_beg = 1

      date_beg <- ed_dates_todo[i_beg]
      i_end <- min(c(i_beg + n_dates, length(ed_dates_todo)))
      date_end <-ed_dates_todo[i_end]
      message(glue("    {i_beg}:{date_beg} to {i_end}:{date_end} of {length(ed_dates_todo)} dates ~ {Sys.time()}"))

      nc <- try(rerddap::griddap(
        attr(ed, "datasetid"),
        fields    = ed_row$var,
        url       = ed$base_url,
        longitude = c(bb["xmin"], bb["xmax"]),
        latitude  = c(bb["ymin"], bb["ymax"]),
        time      = c(date_beg, date_end),
        fmt       = "nc"))

      if ("try-error" %in% class(nc)){
        stop(glue("
        Problem fetching data from ERDDAP server using:
          rerddap::griddap(
            x         = '{attr(ed, 'datasetid')}',
            fields    = '{ed_row$var}',
            url       = '{ed$base_url}',
            longitude = c({bb['xmin']}, {bb['xmax']}),
            latitude  = c({bb['ymin']}, {bb['ymax']}),
            time      = c('{date_beg}', '{date_end}'))"))}

      if (all(c("lon", "lat") %in% colnames(nc$data))){
        x <- tibble(nc$data) %>%
          mutate(
            # round b/c of uneven intervals
            #   unique(tbl$lon) %>% sort() %>% diff() %>% unique() %>% as.character()
            #     0.0499954223632812 0.0500030517578125
            #   TODO: inform Maria/Joaquin about uneven intervals
            lon  = round(lon, 4),
            lat  = round(lat, 4),
            date = as.Date(time, "%Y-%m-%dT12:00:00Z")) %>%
          select(-time)
      } else if (all(c("longitude", "latitude") %in% colnames(nc$data))){
        x <- tibble(nc$data) %>%
          mutate(
            lon  = round(longitude, 4),
            lat  = round(latitude,  4),
            date = as.Date(time, "%Y-%m-%dT12:00:00Z")) %>%
          select(-time, -longitude, -latitude)
      } else {
        stop("Expected lon/lat or longitude/latitude in ERDDAP dataset.")
      }

      x <- x |>
        group_by(date) |>
        nest(data = all_of(c("lon", "lat", ed_row$var))) |>
        mutate(
          r = map(data, rast))
      stk <- rast(x$r)
      names(stk) <- glue("{ed_row$var}_{as.character(x$date) |> str_replace_all('-','.')}")
      crs(stk) <- "EPSG:4326"
      d_ed <- grds_to_ts(
        stk, fxns = c("mean", "sd", "isNA", "notNA"),
        verbose = T)

      # merge newly fetched ERDDAP data with existing csv and write out
      if (file_exists(ts_csv)){
        d_csv <- read_csv(ts_csv)
      } else {
        d_csv <- tibble(
          lyr   = character(0),
          date  = Date(0),
          mean  = numeric(0),
          sd    = numeric(0),
          isNA  = numeric(0),
          notNA = numeric(0))
      }
      d_csv |>
        bind_rows(d_ed) |>
        arrange(date) |>
        filter(
          !duplicated(date)) |>
        write_csv(ts_csv)

    } # loop dates
  } # loop sanctuaries
} # loop datasets

