## use renv package to manage R packages, should only have to run once...
## routinely get a warning about pacman, even though the package no longer uses pacman...

renv::hydrate()
renv::settings$use.cache(FALSE)
renv::install("geojson")
renv::install("remotes")
renv::snapshot()
