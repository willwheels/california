## download needed data files

library(sp)


# got tempfiles created that aren't used

if(!dir.exists(here::here("data"))) {
  dir.create(here::here("data"))
}

# cali_url_geojson <- "https://opendata.arcgis.com/datasets/fbba842bf134497c9d611ad506ec48cc_0.geojson"
# 
# download.file(cali_url_geojson,
#               destfile = here::here("data", "California_Drinking_Water_System_Area_Boundaries.geojson"))

if (!file.exists(here::here("data", "hr2w_web_data_active.xlsx"))) {
  viols_urls <- "https://www.waterboards.ca.gov/water_issues/programs/hr2w/docs/data/hr2w_web_data_active.xlsx"
  
  download.file(viols_urls,
                destfile = here::here("data", "hr2w_web_data_active.xlsx"),
                mode = "wb")
  
}

if(!(file.exists(here::here("data", "earsurveyresults_2018ry.zip")))){
  EAR_url_2018 <- "https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/ear/earsurveyresults_2018ry.zip"
  
  temp <- tempfile()
  download.file(EAR_url_2018, destfile = here::here("data", "earsurveyresults_2018ry.zip"))
  unzip(here::here("data", "earsurveyresults_2018ry.zip"), exdir = here::here("data"))
  unlink(temp)
}


if(!file.exists(here::here("data", "SDWA_GEOGRAPHIC_AREAS.csv"))) {
  SDWA_url <- "https://echo.epa.gov/files/echodownloads/SDWA_latest_downloads.zip"
  
  temp_dir <- tempdir()
  download.file(SDWA_url, destfile = file.path(temp_dir, "SDWA_latest_downloads.zip"))
  unzip(file.path(temp_dir, "SDWA_latest_downloads.zip"), 
        files = c("SDWA_GEOGRAPHIC_AREAS.csv", "SDWA_REF_CODE_VALUES.csv"),
        exdir = here::here("data"))
  unlink(temp_dir)
  
  
}

