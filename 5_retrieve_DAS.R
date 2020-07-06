library(tidyverse)
library(xml2)
library(jsonlite)


get_medrxiv_DAS <- function(weekly_list_filename, save_filename)
{
  print("Filter only medrxiv URLs for data availibility statement retrieval.")
  preprint_metadata_weekly <- read_csv(weekly_list_filename) %>%
    filter(site == "medrxiv")
  
  print("Retrieve data availibility statements from medrxiv website.")
  DAS_table <- retrieve_DAS(preprint_metadata_weekly$URL, preprint_metadata_weekly$doi)
  write_csv(DAS_table, save_filename)
}



retrieve_DAS <- function(URL_list, doi_list, retry = 2)
{
  DAS_list <- list()
  
  for(i in 1:length(URL_list))
  {
    URL <- URL_list[i]
    doi <- doi_list[i]
    data_availibility_statement = ""
    current_retry = retry
    
    #sometimes connection to server fails, need to retry
    while(current_retry > 0 & data_availibility_statement == "")
    {
      print(URL)
      current_retry = current_retry - 1
      
      tryCatch({
        #get journal page from URL
        page_content <- readLines(URL, warn = FALSE)
        
        #find lines with links to Data/Code page
        link_idx <- page_content %>% str_detect("external-links")
        link_lines <- page_content[link_idx]
        
        #extracts link from those lines
        link_lines_split <- link_lines %>% str_split(fixed('\"')) %>% unlist()
        links <- link_lines_split[link_lines_split %>% str_detect("external-links")]
        
        #take longest link URL
        data_link <- links[links %>% map_int(nchar) %>% which.max()]
        data_link <- paste0("https://www.medrxiv.org", data_link)

        #now open the page with the Data availability information
        data_page_content <- readLines(data_link, warn = FALSE) %>% 
          paste(collapse = " ")
        
        data_page_lines <- (data_page_content %>% str_split(fixed("<div")))[[1]]
        
        #find lines with the Data availibility info
        data_lines_idx <- data_page_lines %>% str_detect(fixed("Data Availability</h2>"))
        data_lines <- data_page_lines[data_lines_idx]
        data_availibility_statement <- data_lines %>% 
          str_split('Data Availability</h2><p id=\"p-[[:digit:]]{1,3}\">') %>% 
          map_chr(last) %>%
          str_split('</p>') %>%
          map_chr(first)
        
        if(length(data_availibility_statement) == 0) {
          data_availibility_statement = ""
        }
        
      }, error=function(e){
        print("Could not open URL webpage.")
      })
      
    }
    
    DAS_list[[URL]] <- tibble(URL = URL,
                              doi = doi,
                              DAS = data_availibility_statement)
    
  }
  
  DAS_table <- do.call(rbind, DAS_list)
  DAS_table
  
  return(DAS_table)
}
