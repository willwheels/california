library(tidyverse)

theme_set(theme_minimal() + 
            theme(plot.title.position = "plot", 
                  plot.caption.position = "plot"))

if(!(file.exists(here::here("data", "earsurveyresults_2019ry.zip")))){
  EAR_url_2019 <- "https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/ear/earsurveyresults_2019ry.zip"
  
  temp <- tempfile()
  download.file(EAR_url_2019, destfile = here::here("data", "earsurveyresults_2019ry.zip"))
  unzip(here::here("data", "earsurveyresults_2019ry.zip"), exdir = here::here("data"))
  unlink(temp)
}

## some rows don't parse correctly--appears to be issue in data file
EAR_data_2018 <- read_tsv(here::here("data", "EARSurveyResults_2018RY.txt"))

## distinct is necessary because there are duplicate lines in the data OR I messed up
EAR_shutoffs_2018 <- EAR_data_2018 %>%
  filter(QuestionName %in% c("WR SHUT_OFFS Once SF Total")) %>%
  select(PWSID, Survey, Year, QuestionName, QuestionResults) %>%
  distinct() %>%
  pivot_wider(names_from = "QuestionName", values_from = "QuestionResults") %>%
  janitor::clean_names() %>%
  rename(PWSID = pwsid) %>%
  mutate(total_sf_shutoffs = as.integer(wr_shut_offs_once_sf_total)) %>%
  arrange(desc(total_sf_shutoffs))


## some rows don't parse correctly--appears to be issue in data file
EAR_data_2019 <- read_tsv(here::here("data", "EARSurveyResults_2019RY_10262020.txt"),
                          col_names = FALSE)

colnames(EAR_data_2019) <- colnames(EAR_data_2018)

## distinct is necessary because there are duplicate lines in the data OR I messed up
EAR_shutoffs_2019 <- EAR_data_2019 %>%
  filter(QuestionName %in% c("WR SHUT_OFFS Once SF Total")) %>%
  select(PWSID, Survey, Year, QuestionName, QuestionResults) %>%
  distinct() %>%
  pivot_wider(names_from = "QuestionName", values_from = "QuestionResults") %>%
  janitor::clean_names() %>%
  rename(PWSID = pwsid) %>%
  mutate(total_sf_shutoffs = as.integer(wr_shut_offs_once_sf_total)) %>%
  arrange(desc(total_sf_shutoffs))

EAR_shutoffs_combined <- rbind(EAR_shutoffs_2018, EAR_shutoffs_2019) %>%
  arrange(desc(total_sf_shutoffs))


EAR_shutoffs_combined <- EAR_shutoffs_combined %>%
  pivot_wider(id_cols = c("PWSID", "survey"), names_from = "year", values_from = "total_sf_shutoffs")

