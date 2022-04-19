

onedrive_url <- "https://usepa-my.sharepoint.com/:u:/g/personal/wheeler_william_epa_gov/EUVVXmpI6PpJsLCl3Ot_uTMBCT2D5krFL1Nb8LpLrzqp4Q?e=pV2w1s"

download.file(onedrive_url, destfile = "California_Drinking_Water_System_Area_Boundaries.geojson")

sharepoint_url <- "https://usepa.sharepoint.com/:u:/s/NCEEWaterTeam/Ebp8gJ0Dj49FqO2powcDB1kBl2hvx6nU0aq3fcn0Rq91eg?e=YbtHau"

download.file(sharepoint_url, destfile = "California_Drinking_Water_System_Area_Boundaries.geojson")
