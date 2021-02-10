library(tidyverse)
library(foreign)
library(data.table)
library(tidytable)
library(rlang)

base_chem_url <- "https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/edtlibrary/"

chem_files <- c("chemical_as_dbf.zip", "chemical_as_csv.zip",
                "chemhist_as_dbf.zip", "chemhist_as_csv.zip",
                "chemarch_as_dbf.zip", "chemarch_as_csv.zip",
                "chemxarc_as_dbf.zip", "chemxarc_as_csv.zip"
)


get_chem_file <- function(filename) {
  
  local_filename <- here::here("data", "chem_data", filename)
  
  if(!(file.exists(local_filename))){
    chem_url <- paste0(base_chem_url, filename)
    
    download.file(chem_url, destfile = local_filename)
    unzip(local_filename, exdir = here::here("data", "chem_data"))
    
  }
  
}

walk(chem_files, get_chem_file)

base_library_url <- "https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/edtlibrary/"

library_files <- c("siteloc_as_dbf.zip", "siteloc_as_excel.zip",
                   "watsys_as_dbf.zip", "watsys_as_excel.zip",
                   "lab_as_dbf.zip", "lab_as_excel.zip",
                   "storet_as_dbf.zip", "storet_as_excel.zip",
                   "pre_2016_storet.zip", "pre_2016_as_excel.zip"
)


get_library_file <- function(filename) {
  
  local_filename <- here::here("data", "chem_data", filename)
  
  if(!(file.exists(local_filename))){
    library_url <- paste0(base_library_url, filename)
    
    download.file(library_url, destfile = local_filename)
    unzip(local_filename, exdir = here::here("data", "chem_data"))
    
  }
  
}

walk(library_files, get_library_file)


storet <- openxlsx::read.xlsx(here::here("data", "chem_data", "storet.xlsx")) %>%
  select(STORE_NUM, CHEMICAL__)


siteloc <- openxlsx::read.xlsx(here::here("data", "chem_data", "siteloc.xlsx")) %>%
  select(PRI_STA_C, STATUS) %>%
  rename(PRIM_STA_C = PRI_STA_C)


chem_csv_files <- list.files(here::here("data", "chem_data"), pattern = ".csv$", full.names = TRUE)

## this is just so I can look at column names
check <- fread(file = chem_csv_files[1], nrows = 10)

check2 <- check %>%
  left_join(siteloc) 

count_analytes <- function(filename) {
  
  fread(filename) %>%
    count.(STORE_NUM) %>%
    arrange.(-N)
  
  
}



analytes <- map_dfr(chem_csv_files, count_analytes)

analytes2 <- analytes %>%
  group_by(STORE_NUM) %>%
  summarize(N = sum(N)) %>%
  arrange(-N) %>%
  left_join(storet)

count_status <- function(filename) {
  
  fread(filename) %>%
    left_join.(siteloc) %>%
    count.(STORE_NUM, STATUS) %>%
    arrange.(-N)
  
}



statuses <- map_dfr(chem_csv_files, count_status)


statuses2 <- statuses %>%
  group_by(STORE_NUM, STATUS) %>%
  summarize(N = sum(N)) %>%
  arrange(-N) %>%
  left_join(storet)

get_samples_one_poll <- function(filename, storenum) {
  
  fread(filename) %>%
    filter.(STORE_NUM == {{storenum}}) %>%
    select.(PRIM_STA_C, STORE_NUM, FINDING, XMOD, LAB_NUM, SAMP_DATE) %>%
    mutate.(sample_date = lubridate::mdy_hms(SAMP_DATE),
            sample_year = year(sample_date),
            LAB_NUM = as.character(LAB_NUM)
    ) %>%
    left_join.(siteloc)
  
}



all_lead <- map2_dfr(chem_csv_files, "01051", get_samples_one_poll)


summary(all_lead)

ggplot(data = all_lead %>% filter(FINDING > 5, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)

ggplot(data = all_lead %>% filter(FINDING > 10, FINDING < 20), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)


ggplot(data = all_lead %>% filter(FINDING > 10, FINDING < 20), aes(x = FINDING)) +
  geom_histogram(binwidth = 1) +
  facet_wrap(~sample_year)

ggplot(data = all_lead %>% filter(FINDING > 10, FINDING < 20, sample_year > 2000), 
       aes(x = FINDING)) +
  geom_histogram(binwidth = 1) +
  facet_wrap(~LAB_NUM)

all_pce <-  map2_dfr(chem_csv_files, "34475", get_samples_one_poll)

summary(all_pce)

ggplot(data = all_pce %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)



all_tce <-  map2_dfr(chem_csv_files, "39180", get_samples_one_poll)

summary(all_tce)

ggplot(data = all_tce %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)



#all_nitrate <-  map2_dfr(chem_csv_files, "71850", get_samples_one_poll)

#summary(all_nitrate)

#save(all_nitrate, file = here::here("data", "nitrate.Rda"))

## oops nitrate is from one freaking facility!!

#ggplot(data = all_nitrate %>% filter(FINDING > 0, FINDING < 30), aes(x = FINDING)) +
#  geom_histogram(binwidth = 1)


# ggplot(data = all_nitrate %>% filter(FINDING > 5, FINDING < 20), aes(x = FINDING)) +
#   geom_histogram(binwidth = 1)


thms <- analytes2 %>%
  filter(str_detect(CHEMICAL__, "THM"))

all_thm1 <-  map2_dfr(chem_csv_files, thms$STORE_NUM[1], get_samples_one_poll)

summary(all_thm1)


all_thm2 <-  map2_dfr(chem_csv_files, thms$STORE_NUM[2], get_samples_one_poll)

summary(all_thm2)

all_thm3 <-  map2_dfr(chem_csv_files, thms$STORE_NUM[3], get_samples_one_poll)

summary(all_thm3)

all_thm4 <-  map2_dfr(chem_csv_files, thms$STORE_NUM[4], get_samples_one_poll)

summary(all_thm4)


ggplot(data = all_thm1 %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)

ggplot(data = all_thm2 %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)


ggplot(data = all_thm3 %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)

ggplot(data = all_thm4 %>% filter(FINDING > 0, FINDING < 25), aes(x = FINDING)) +
  geom_histogram(binwidth = 1)

all_thm <- rbind(all_thm1, all_thm2 ,all_thm3, all_thm4)

save(all_thm, file = here::here("data", "thm.Rda"))
