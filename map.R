
library(sf)
library(tidyverse)
library(mapdata)


cali <- map_data("state", region = "california")

cali_map_geojson <- read_sf(here::here("data", "California_Drinking_Water_System_Area_Boundaries.geojson"))

# https://www.r-graph-gallery.com/325-background-map-from-geojson-format-in-r.html



ggplot() + 
  geom_polygon(data = cali,
               aes(x=long, y = lat, group = group),
               fill = NA, color = "black", size = .25) +
  geom_sf(data = cali_map_geojson) +
  ggthemes::theme_map()
