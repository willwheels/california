library(sf)
library(tidyverse)
library(tidycensus)
library(areal)
library(stringr)
library(openxlsx)
library(lubridate)

theme_set(theme_minimal() + 
            theme(plot.title.position = "plot", 
                  plot.caption.position = "plot"))

## below gets unstandardized rates

# water_rates_download_url <- "https://data.ca.gov/dataset/21415426-f919-4f79-a1cf-7804a9110152/resource/ebac19f0-618f-4d5f-8610-c826877b66c2/download/standard-1218-public-only.csv"
# 
# cali_water_rates <- read_csv(water_rates_download_url)
# 
# cali_water_rates <- cali_water_rates %>%
#   janitor::clean_names()

## EAR data

## some rows don't parse correctly--appears to be issue in data file
EAR_data_2018 <- read_tsv(here::here("data", "EARSurveyResults_2018RY.txt"))

EAR_standard_rates <- EAR_data_2018 %>%
  filter(str_detect(QuestionName, "HCF Total WBill")) %>%
  select(PWSID, Survey, QuestionName, QuestionResults) %>%
  pivot_wider(names_from = "QuestionName", values_from = "QuestionResults") %>%
  janitor::clean_names() %>%
  rename(PWSID = pwsid)


## distinct is necessary because there are duplicate lines in the data OR I messed up
EAR_shutoffs <- EAR_data_2018 %>%
  filter(QuestionName %in% c("WR SHUT_OFFS Once SF Total")) %>%
  select(PWSID, Survey, QuestionName, QuestionResults) %>%
  distinct() %>%
  pivot_wider(names_from = "QuestionName", values_from = "QuestionResults") %>%
  janitor::clean_names() %>%
  rename(PWSID = pwsid)

          

rm(EAR_data_2018)

## read in Service Area Boundaries

cali_geojson <- read_sf(here::here("data", "California_Drinking_Water_System_Area_Boundaries.geojson"))

cali_data <- cali_geojson %>%
  select(SABL_PWSID, WATER_SYSTEM_NAME, geometry) %>%
  rename(PWSID = SABL_PWSID) %>%
  left_join(EAR_standard_rates) %>%
  left_join(EAR_shutoffs) %>%
  mutate(wr_12_hcf_total_w_bill = as.numeric(wr_12_hcf_total_w_bill),
         wr_shut_offs_once_sf_total)

cali <- map_data("state", region = "california")

ggplot() + 
  geom_polygon(data = cali,
               aes(x=long, y = lat, group = group),
               fill = NA, color = "black", size = .25) +
  labs(title= "Map of California Drinking Water System Boundaries") +
  geom_sf(data = cali_geojson) +
  ggthemes::theme_map()


## load ACS variable names, if needed, cache should speed later calls according 
## to docs
v18 <- load_variables(2018, "acs5", cache = TRUE)


## replace with your own Census API Key
## http://api.census.gov/data/key_signup.html

options(tigris_use_cache = TRUE)
source(here::here("will_api_key.R"))
census_api_key(wills_api_key, install = TRUE)

readRenviron("~/.Renviron")



cali_acs_income <- get_acs(state = "CA", geography = "block group",
                    variables = c(median_income = "B19013_001"),
                    geometry = TRUE)

## need to transform to common coordinate reference system: the boundary files
## and ACS data had different ones, neither of which worked w/ the areal pkg
cali_acs_income2 <- st_transform(cali_acs_income, crs = 26915) %>%
  select(-NAME, -variable, -moe)

  
## got some error about a self-intersecting polygon, this is a fix
## I don't really know what I am doing
cali_data <- st_transform(cali_data, crs = 26915) %>%
  st_buffer(., dist = 0)

## verify all true for interpolation
ar_validate(cali_acs_income2, cali_data, varList = "estimate", verbose = TRUE)

cali_interpolated_inc <- aw_interpolate(cali_data,
                                    tid = PWSID,
                                    source = cali_acs_income2,
                                    sid = GEOID,
                                    weight = "sum",
                                    output = "sf",
                                    intensive = "estimate")

sum(is.na(cali_interpolated_inc$estimate))

## 693/4672 have no interpolated estimate! need to work on that
## (numbers changed slightly after new pulls)

## redo interpolatios by race
## stolen from some Datacamp slides 

race_vars <- c(White = "B03002_003", Black = "B03002_004",
               Native = "B03002_005", Asian = "B03002_006",
               HIPI = "B03002_007", Hispanic = "B03002_012")



ca_race <- get_acs(state = "CA", geography = "block group",
                   variables = race_vars,
                   summary_var = "B03002_001",
                   geometry = TRUE)



## note some block groups have no pop--too small?

ca_race_pct_white <- ca_race %>%
  mutate(pct_white = (estimate/summary_est)*100) 

cali_race_pct_white2 <- st_transform(ca_race_pct_white, crs = 26915) %>%
  select(GEOID, geometry, pct_white)


ar_validate(cali_race_pct_white2, cali_data, varList = "pct_white", verbose = TRUE)


cali_interpolated_white <- aw_interpolate(cali_data %>% select(PWSID, geometry),
                                          tid = PWSID,
                                          source = cali_race_pct_white2,
                                          sid = GEOID,
                                          weight = "sum",
                                          output = "sf",
                                          intensive = "pct_white")

# only 76 NA
sum(is.na(cali_interpolated_white$pct_white))


ca_race_pct_black <- ca_race %>%
  filter(variable == "Black") %>%
  mutate(pct_black = (estimate/summary_est)*100) 
  

cali_race_pct_black2 <- st_transform(ca_race_pct_black, crs = 26915) %>%
  select(GEOID, geometry, pct_black)

ar_validate(cali_race_pct_black2, cali_data, varList = "pct_black", verbose = TRUE)

cali_interpolated_black <- aw_interpolate(cali_data %>% select(PWSID, geometry),
                                         tid = PWSID,
                                         source = cali_race_pct_black2,
                                         sid = GEOID,
                                         weight = "sum",
                                         output = "sf",
                                         intensive = "pct_black")


sum(is.na(cali_interpolated_black$pct_black))

## only 76 have no interpolated estimate 



ca_race_pct_hispanic <- ca_race %>%
  filter(variable == "Hispanic") %>%
  mutate(pct_hispanic = (estimate/summary_est)*100) 


cali_race_pct_hispanic2 <- st_transform(ca_race_pct_hispanic, crs = 26915) %>%
  select(GEOID, geometry, pct_hispanic)

ar_validate(cali_race_pct_hispanic2, cali_data, varList = "pct_hispanic", verbose = TRUE)

cali_interpolated_hispanic <- aw_interpolate(cali_data %>% select(PWSID, geometry),
                                          tid = PWSID,
                                          source = cali_race_pct_hispanic2,
                                          sid = GEOID,
                                          weight = "sum",
                                          output = "sf",
                                          intensive = "pct_hispanic")


sum(is.na(cali_interpolated_hispanic$pct_hispanic))

## only 76 have no interpolated estimate 

## merge in interpolated race data

cali_interpolated_all <- cali_interpolated_inc %>%
  left_join(st_drop_geometry(cali_interpolated_black)) %>%
  left_join(st_drop_geometry(cali_interpolated_white)) %>%
  left_join(st_drop_geometry(cali_interpolated_hispanic)) %>%
  rename(median_income = estimate)



## get violation data


violation_data <- read.xlsx(here::here("data", "hr2w_web_data_active.xlsx"),
                            detectDates = TRUE)

## VIOL_END_DATE is not correctly identified as a date (possible b/c of missings)

violation_data2 <- violation_data %>%
  rename(PWSID = WATER_SYSTEM_NUMBER) %>%
  mutate(VIOL_END_DATE = ymd(VIOL_END_DATE)) %>%
  filter(VIOL_BEGIN_DATE >= ymd("2018-01-01")) %>%
  group_by(PWSID) %>%
  count() %>%
  rename(viols_since_2018 = n) %>%
  replace_na(list(viols_since_2018 = 0))

cali_interpolated_all <- cali_interpolated_all %>%
  left_join(violation_data2) %>% 
  mutate(pct_income = wr_12_hcf_total_w_bill*12/median_income) 

load(here::here("data", "thm.Rda"))

all_thm <- all_thm %>%
  separate(PRIM_STA_C, into = c("PWSID", NA)) %>%
  mutate(PWSID = paste0("CA", PWSID)) %>%
  select(PWSID, sample_year, FINDING) %>%
  filter(sample_year >= 2018) %>%
  group_by(PWSID) %>%
  summarise(mean_thm = mean(FINDING))


load(here::here("data", "nitrate.Rda"))

all_nitrate <- all_nitrate %>%
  separate(PRIM_STA_C, into = c("PWSID", NA)) %>%
  mutate(PWSID = paste0("CA", PWSID)) %>%
  select(PWSID, sample_year, FINDING) %>%
  filter(sample_year >= 2010) %>%
  group_by(PWSID) %>%
  summarise(mean_nitrate = mean(FINDING))
  
cali_interpolated_all <- cali_interpolated_all %>%
  left_join(all_thm) %>%
  left_join(all_nitrate)



save(cali_interpolated_all, file = here::here("data", "cali_interpolated_all.Rda"))
