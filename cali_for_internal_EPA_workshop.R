library(tidyverse)


load(here::here("data", "cali_interpolated_all.Rda"))

sdwa_geo_areas <- read_csv(here::here("data", "SDWA_GEOGRAPHIC_AREAS.csv"))

sdwa_geo_areas <- sdwa_geo_areas %>%
  filter(substr(PWSID, 1, 2) == "CA") %>%
  select(PWSID, AREA_TYPE_CODE, CITY_SERVED, COUNTY_SERVED) # California only reports these two ways

sdwa_counties <- sdwa_geo_areas %>%
  filter(AREA_TYPE_CODE == "CN") %>%
  group_by(PWSID) %>%
  mutate(num_counties = n()) %>%
  ungroup() %>%
  filter(num_counties == 1) %>%
  select(PWSID, COUNTY_SERVED)


summary(sdwa_counties)

sdwa_cities <- sdwa_geo_areas %>%
  filter(AREA_TYPE_CODE == "CT") %>%
  group_by(PWSID) %>%
  mutate(num_cities = n()) %>%
  ungroup() 

summary(sdwa_cities)



cali_acs_income_county <- tidycensus::get_acs(state = "CA", geography = "county",
                                              variables = c(median_income = "B19013_001"),
                                              geometry = FALSE)


cali_acs_income_state <- tidycensus::get_acs(state = "CA", geography = "state",
                                             variables = c(median_income = "B19013_001"),
                                             geometry = FALSE)

cali_acs_income_county <-cali_acs_income_county %>%
  mutate(NAME = stringr::str_replace(NAME, " County, California", "")) %>%
  select(NAME, estimate) %>%
  rename(COUNTY_SERVED = NAME, county_mhi = estimate)


cali_interpolated_all_county_inc <- cali_interpolated_all %>%
  left_join(sdwa_counties) %>%
  filter(!is.na(COUNTY_SERVED)) %>%
  left_join(cali_acs_income_county) %>%
  mutate(pct_income_county = wr_12_hcf_total_w_bill*12/county_mhi) 


ggplot(data = cali_interpolated_all_county_inc, aes(x = median_income, y = county_mhi)) +
  geom_point() +
  theme_minimal()

ggplot(data = cali_interpolated_all_county_inc %>% filter(pct_income < .5),
       aes(x = pct_income, y = pct_income_county)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1, linetype = 2) + 
  theme_minimal()

# ref_sdwa <- read_csv(here::here("data", "SDWA_REF_CODE_VALUES.csv")) %>%
#   filter(VALUE_TYPE == "SERVICE_AREA_TYPE_CODE") %>%
#   select(-VALUE_TYPE)

  
## switch to using 6 HCF and 1.5 %



ggplot(data = cali_interpolated_all %>% filter(!is.na(median_income), POPULATION >= 25), 
       aes(x = median_income, y = log(POPULATION))) +
  geom_point(aes(color = pct_poverty)) +
  scale_color_viridis_b(option = "magma", direction = -1) +
  geom_hline(yintercept = log(10000), linetype = 2) +
  geom_vline(xintercept = cali_acs_income_state$estimate*.8, linetype = 3) +
  geom_vline(xintercept = cali_acs_income_state$estimate*.6, linetype = 3) +
  labs(title = "California Systems, Population vs Median Income", 
       subtitle = "Dashed lines indicate disadvantaged community thresholds",
       caption = "Systems > 25 service population",
       color = "% Poverty") +
  xlab("Median Household Income") + ylab("Log Population") +
  theme_minimal() 

ggsave("cali_dwsrf_defs.png", w = 11, h = 8.5, units = "in")
