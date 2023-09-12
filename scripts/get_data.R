# load packages ----
if (!"librarian" %in% installed.packages()[,1])
  install.packages("librarian")
librarian::shelf(
  dplyr, fs, glue, here, lubridate, purrr, readr, sf, stringr, terra, tibble, tidyr,
  calcofi/calcofi4r, # temporarily to get Chumash
  noaa-onms/onmsR,
  marinebon/extractr)
# TODO: fix onmsr -- Warning message: replacing previous import ‘magrittr::extract’ by ‘tidyr::extract’ when loading ‘onmsR’
# devtools::load_all(here("../../marinebon/extractr"))                        # debug locally
# devtools::install_github("marinebon/extractr", force = T)                   # get latest from Github
# devtools::install_local(here::here("../../marinebon/extractr"), force = T)  # get latest locally
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
  saveRDS(sanctuaries, sanctuaries_rds)
}
sanctuaries <- readRDS(sanctuaries_rds)

# ERDDAP datasets ----
ed_datasets <- read_csv(here("data/datasets.csv")) |>
  filter(
    type == "erddap",
    active == TRUE) # View(ed_datasets)

# TODO: assign vars to sanctuaries since Coral Reef Watch not applicable to all

# iterate over ERDDAP datasets ----
for (i_ed in 1:nrow(ed_datasets)){ # i_ed = 1
# for (i_ed in c(3)){ # i_ed = 3

  ed_row <- ed_datasets |> slice(i_ed)
  message(glue("dataset: {ed_row$var} ~ {Sys.time()}"))

  ed            <- extractr::get_ed_info(ed_row$url)
  ed_date_range <- extractr::get_ed_dates(ed)
  ed_dates      <- extractr::get_ed_dates_all(
    ed, min(ed_date_range), max(ed_date_range))

  # iterate over sanctuaries ----
  for (i_s in 1:nrow(sanctuaries)){ # i_s = 15
  #for (i_s in 10:nrow(sanctuaries)){ # i_s = 2

    ply <- slice(sanctuaries, i_s)
    message(glue("  sanctuary: {ply$nms} ~ {Sys.time()}"))
    bb <- sf::st_bbox(ply)

    ts_csv  <- here(glue("data/{ed_row$var}/{ply$nms}.csv"))

    # if (ply$nms %in% c("MNMS","NMSAS") & ed_row$var == "CRW_SST")
    if (ed_row$var == "CRW_SST")
      next

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

      # install.packages("rerddap") # get latest rerddap version 1.0.3
      hr_var <- ifelse(ed_row$var == "CRW_SST", "12", "00")
      # TODO: fix extractr::get_ed_dates() to return hour:minute:second


      date_beg_str <- glue("{date_beg}T{hr_var}:00:00Z")
      date_end_str <- glue("{date_end}T{hr_var}:00:00Z")

      nc <- try(rerddap::griddap(
        datasetx  = attr(ed, "datasetid"),
        fields    = ed_row$var,
        url       = ed$base_url,
        # url       = "https://coastwatch.pfeg.noaa.gov/erddap",
        longitude = c(bb["xmin"], bb["xmax"]),
        latitude  = c(bb["ymin"], bb["ymax"]),
        time      = c(date_beg_str, date_end_str),
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
            time      = c('{date_beg_str}', '{date_end_str}'))"))}

      if (all(c("lon", "lat") %in% colnames(nc$data))){
        x <- tibble(nc$data) %>%
          mutate(
            date = as.Date(time, glue("%Y-%m-%dT{hr_var}:00:00Z"))) %>%
          select(-time)
      } else if (all(c("longitude", "latitude") %in% colnames(nc$data))){
        x <- tibble(nc$data) %>%
          mutate(
            lon  = longitude,
            lat  = latitude,
            date = str_replace(time, "(.*)T(.*)", "\\1")) |>
          select(-time, -longitude, -latitude)
      } else {
        stop("Expected lon/lat or longitude/latitude in ERDDAP dataset.")
      }

      n_pts <- x |>
        group_by(lon, lat) |>
        summarize(n = n(), .groups = "drop") |>
        nrow()

      if (n_pts < 4){
        # skip masking b/c rast() prob won't work
        d_ed <- x |>
          group_by(date) |>
          summarize(
            mean  = mean(.data[[ed_row$var]], na.rm=T),
            sd    = sd(.data[[ed_row$var]], na.rm=T),
            isNA  = is.na(.data[[ed_row$var]]) |> length(),
            notNA = is.na(.data[[ed_row$var]]) |> length(),
            .groups = "drop") |>
          mutate(
            lyr   = glue("{ed_row$var}_{as.character(date) |> str_replace_all('-','.')}")) |>
          select(lyr, mean, sd, isNA, notNA)
      } else {

        # OLD: with rounded lon/lat
        # x <- x |>
        #   group_by(date) |>
        #   nest(data = all_of(c("lon", "lat", ed_row$var))) |>
        #   mutate(
        #     r = map(data, rast))
        # rast(data) not working:
        #   [raster,matrix(xyz)] x cell sizes are not regular

        # NEW: with true grid (possibly diff't xres and yres)

        # get geospatial attributes
        a <- ed$alldata$NC_GLOBAL |>
          filter(
            attribute_name |> str_starts("geospatial_"),
            data_type == "double") |>
          select(attribute_name, value)
        g <- setNames(as.numeric(a$value), a$attribute_name) |> as.list()
        lon_half <- g$geospatial_lon_resolution/2
        lat_half <- g$geospatial_lat_resolution/2

        # setup raster with potentially different xres() and yres()
        r_template <- rast(
          xmin       = min(x$lon) - lon_half,
          xmax       = max(x$lon) + lon_half,
          ymin       = min(x$lat) - lat_half,
          ymax       = max(x$lat) + lat_half,
          resolution = c(
            g$geospatial_lon_resolution,
            g$geospatial_lat_resolution),
          crs = "epsg:4326")

        df_to_rast <- function(df, r_template){
          # data frame to points
          p <- df |>
            select(lon, lat, all_of(ed_row$var)) |>
            st_as_sf(
              coords = c("lon", "lat"),
              crs    = 4326)
          # points to raster
          rasterize(p, r_template, field = ed_row$var)
        }

        x <- x |>
          group_by(date) |>
          nest(data = all_of(c("lon", "lat", ed_row$var))) |>
          mutate(
            r = map(data, df_to_rast, r_template))

        stk <- rast(x$r)
        names(stk) <- glue("{ed_row$var}_{as.character(x$date) |> str_replace_all('-','.')}")
        crs(stk) <- "EPSG:4326"

        # devtools::load_all(here("../../marinebon/extractr"))
        d_ed <- grds_to_ts(
          stk, fxns = c("mean", "sd", "isNA", "notNA"),
          verbose = T)
      }

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

