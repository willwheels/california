
library(sp)

#cali_map_url <- "https://opendata.arcgis.com/datasets/fbba842bf134497c9d611ad506ec48cc_0.zip?geometry=%7B%22xmin%22%3A-123.699%2C%22ymin%22%3A37.052%2C%22xmax%22%3A-116.762%2C%22ymax%22%3A38.571%2C%22type%22%3A%22extent%22%2C%22spatialReference%22%3A%7B%22wkid%22%3A4326%7D%7D&outSR=%7B%22falseM%22%3A-100000%2C%22xyTolerance%22%3A8.98315284119521e-9%2C%22mUnits%22%3A10000%2C%22zUnits%22%3A10000%2C%22latestWkid%22%3A4326%2C%22zTolerance%22%3A0.001%2C%22wkid%22%3A4326%2C%22xyUnits%22%3A999999999.9999999%2C%22mTolerance%22%3A0.001%2C%22falseX%22%3A-400%2C%22falseY%22%3A-400%2C%22falseZ%22%3A-100000%7D"

## this map seems incomplete

#cali_map_url <- "https://opendata.arcgis.com/datasets/fbba842bf134497c9d611ad506ec48cc_0.zip?outSR=%7B%22falseM%22%3A-100000%2C%22xyTolerance%22%3A8.98315284119521e-9%2C%22mUnits%22%3A10000%2C%22zUnits%22%3A10000%2C%22latestWkid%22%3A4326%2C%22zTolerance%22%3A0.001%2C%22wkid%22%3A4326%2C%22xyUnits%22%3A999999999.9999999%2C%22mTolerance%22%3A0.001%2C%22falseX%22%3A-400%2C%22falseY%22%3A-400%2C%22falseZ%22%3A-100000%7D"
#temp <- tempfile()
#download.file(cali_map_url, destfile = here::here("data", "California_Drinking_Water_System_Area_Boundaries-shp.zip"))
#unzip(here::here("data", "California_Drinking_Water_System_Area_Boundaries-shp.zip"), exdir = here::here("data"))
#unlink(temp)

cali_url_geojson <- "https://opendata.arcgis.com/datasets/fbba842bf134497c9d611ad506ec48cc_0.geojson"

download.file(cali_url_geojson,
              destfile = here::here("data", "California_Drinking_Water_System_Area_Boundaries.geojson"))

if (!file.exists(here::here("data", "hr2w_web_data_active.xlsx"))) {
  viols_urls <- "https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/hr2w_web_data_active.xlsx"
  
  download.file(viols_urls,
                destfile = here::here("data", "hr2w_web_data_active.xlsx"))
  
}
