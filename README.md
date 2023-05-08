# climate-dashboard
dashboard of climate indicators across sanctuaries

## Add an indicator

Here's the process to add a dataset and indicator plot:

1. Add a row to [datasets.csv](https://github.com/noaa-onms/climate-dashboard/blob/main/data/datasets.csv)
1. Run [get_data.R](https://github.com/noaa-onms/climate-dashboard/blob/main/scripts/get_data.R) to generate CSV per sanctuary under [data/](https://github.com/noaa-onms/climate-dashboard/tree/main/data/)
1. Add a new plot under the template [_sanctuary.Rmd](https://github.com/noaa-onms/climate-dashboard/blob/main/_sanctuary.Rmd)
1. Update all sanctuary pages with [make_pages.R](https://github.com/noaa-onms/climate-dashboard/blob/main/scripts/make_pages.R)
