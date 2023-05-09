librarian::shelf(
  dplyr, DT, ggplot2, glue, here, lubridate,
  marinebon/extractr,
  ncdf4, readr, rgdal, tibble, terra)

sanctuaries_nms <- c("GRNMS","FKNMS","FGBNMS")

for (nms in sanctuaries_nms){ # nms = sanctuaries_nms[2]

  nc_path     <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev.nc"))
  csv_path    <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev.csv"))
  yr_csv_path <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev_annual.csv"))

  if (all(file.exists(c(csv_path, yr_csv_path)))){
    message(glue("{nms} csv files exist, skipping"))
    next
  }

  nc <- ncdf4::nc_open(nc_path) # nc

  d <- tibble(
    microseconds = ncvar_get(nc, "time") |> as.numeric(),
    time         = microseconds/1000000 + ISOdatetime(1850,1,16,13,0,0) ,
    date         = as.Date(time),
    sst_mean     = ncvar_get(nc, "SST_mean") |> as.numeric(),
    sst_sd       = ncvar_get(nc, "SST_stdev") |> as.numeric()) |>
    select(-microseconds, -time)
  write_csv(d, csv_path)

  d_yr <- d |>
    mutate(
      year = glue("{year(date)}-01-01") |> as.Date()) |>
    group_by(year) |>
    summarize(
      sst_mean = mean(sst_mean),
      sst_sd   = mean(sst_sd))
  write_csv(d_yr, yr_csv_path)
}

# show metadata
nc

# interactive table
DT::datatable(d)

# interactive time series
extractr::plot_ts(csv_path, fld_avg = "sst_mean", fld_sd = "sst_sd")

extractr::plot_ts(yr_csv_path, fld_avg = "sst_mean", fld_sd = "sst_sd", fld_date = "year")
