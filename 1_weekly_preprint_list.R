library(tidyverse)
library(jsonlite)
library(lubridate)


download_preprint_json_list <- function(save_filename)
{
  print("Download latest json file from biorxiv.")
  #download latest JSON file

  biorxiv_json_url <- "https://connect.biorxiv.org/relate/collection_json.php?grp=181"
  download.file(biorxiv_json_url, save_filename)
}
  
filter_weekly_preprint_list <- function(start_date, end_date, json_file)
{
  #load metadata
  preprint_metadata <- fromJSON(json_file)
  preprint_metadata_tbl <- preprint_metadata$rels %>% as_tibble()
  

  print("Filter and format preprint list.")
  
  preprint_metadata_weekly <- preprint_metadata_tbl %>% 
    filter(rel_date >= start_date) %>%
    filter(rel_date <= end_date)
  
  #bring table in shape for export
  preprint_metadata_weekly <- preprint_metadata_weekly %>%
    select(-rel_abs, -rel_authors) %>% 
    rename(title = rel_title) %>%
    rename(doi = rel_doi) %>%
    rename(URL = rel_link) %>%
    rename(date = rel_date) %>%
    rename(site = rel_site)

  return(preprint_metadata_weekly)


}
