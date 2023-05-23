librarian::shelf(
  dplyr, DT, ggplot2, glue, here, lubridate,
  marinebon/extractr,
  ncdf4, readr, rgdal, tibble, terra)

sanctuaries_nms <- c("GRNMS","FKNMS","FGBNMS")

for (nms in sanctuaries_nms){ # nms = sanctuaries_nms[1]

  nc_path     <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev.nc"))
  csv_path    <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev.csv"))
  yr_csv_path <- here(glue("data/Climate_projections/{nms}_CESM2LE_data_1850-2100_mean_stdev_annual.csv"))

  # if (all(file.exists(c(csv_path, yr_csv_path)))){
  #   message(glue("{nms} csv files exist, skipping"))
  #   next
  # }

  nc <- ncdf4::nc_open(nc_path) # nc
  # names(nc$var)
  # [1] "SST_mean"      "SST_stdev"     "Chl_mean"      "Chl_stdev"
  # [5] "HMXL_DR_mean"  "HMXL_DR_stdev" "PH_mean"       "PH_stdev"
  # [9] "SSS_mean"      "SSS_stdev"     "lat_bounds"    "lon_bounds"
  # [13] "delta_sigma_t"

  d <- tibble(
    microseconds = ncvar_get(nc, "time") |> as.numeric(),
    time         = microseconds/1000000 + ISOdatetime(1850,1,16,13,0,0) ,
    date         = as.Date(time),
    sst_mean     = ncvar_get(nc, "SST_mean") |> as.numeric(),
    sst_sd       = ncvar_get(nc, "SST_stdev") |> as.numeric(),
    chl_mean     = ncvar_get(nc, "Chl_mean") |> as.numeric(),
    chl_sd       = ncvar_get(nc, "Chl_stdev") |> as.numeric(),
    mld_mean     = ncvar_get(nc, "HMXL_DR_mean") |> as.numeric(),
    mld_sd       = ncvar_get(nc, "HMXL_DR_stdev") |> as.numeric(),
    ph_mean      = ncvar_get(nc, "PH_mean") |> as.numeric(),
    ph_sd        = ncvar_get(nc, "PH_stdev") |> as.numeric(),
    sss_mean     = ncvar_get(nc, "SSS_mean") |> as.numeric(),
    sss_sd       = ncvar_get(nc, "SSS_stdev") |> as.numeric()) |>
    select(-microseconds, -time)
  write_csv(d, csv_path)

  d_yr <- d |>
    mutate(
      year = glue("{year(date)}-01-01") |> as.Date()) |>
    group_by(year) |>
    summarize(
      # TODO: summarizing monthly to yearly; invalid to take mean of sd
      sst_mean = mean(sst_mean),
      sst_sd   = mean(sst_sd),
      chl_mean = mean(chl_mean),
      chl_sd   = mean(chl_sd),
      mld_mean = mean(mld_mean),
      mld_sd   = mean(mld_sd),
      ph_mean  = mean(ph_mean),
      ph_sd    = mean(ph_sd),
      sss_mean = mean(sss_mean),
      sss_sd   = mean(sss_sd))
  write_csv(d_yr, yr_csv_path)
}

# show metadata
nc

# interactive table
DT::datatable(d)

# interactive time series
extractr::plot_ts(csv_path, fld_avg = "sst_mean", fld_sd = "sst_sd")

extractr::plot_ts(yr_csv_path, fld_avg = "sst_mean", fld_sd = "sst_sd", fld_date = "year")
