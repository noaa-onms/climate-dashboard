# climate-dashboard

dashboard of climate indicators across sanctuaries

## Motivation

The layout of this dashboard is fashioned after [EcoWatch.noaa.gov](https://ecowatch.noaa.gov/regions/california-current), i.e. National Marine Ecosystem Status (NAMES), but using open-source relatively straightforward R based tools such as [flexdashboard](https://pkgs.rstudio.com/flexdashboard/) and hosted for free on GitHub.

## Interchangability

The map and time series visualizations shown here can be dropped into other R based outputs, such as [SanctuaryWatch.ioos.us](https://sanctuarywatch.ioos.us).

## Add an indicator

Here's the process to add a dataset and indicator plot:

1.  Add a row to [./data/datasets.csv](https://github.com/noaa-onms/climate-dashboard/blob/main/data/datasets.csv)
2.  Run [./scripts/get_data.R](https://github.com/noaa-onms/climate-dashboard/blob/main/scripts/get_data.R) to generate CSV per sanctuary under [data/](https://github.com/noaa-onms/climate-dashboard/tree/main/data/)
3.  Add a new plot under the template [\_sanctuary.Rmd](https://github.com/noaa-onms/climate-dashboard/blob/main/_sanctuary.Rmd)
4.  Update all sanctuary pages with [make_pages.R](https://github.com/noaa-onms/climate-dashboard/blob/main/scripts/make_pages.R)
