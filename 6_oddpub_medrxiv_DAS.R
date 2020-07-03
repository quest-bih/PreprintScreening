library(tidyverse)
library(xml2)
library(jsonlite)
library(oddpub)

screen_DAS <- function(DAS_filename)
{
  print("Screen medrxiv data availibility statements with ODDPub.")
  DAS_table <- read_csv(DAS_filename)
  open_data_statements <- as.list(DAS_table$DAS)
  names(open_data_statements) <- DAS_table$doi
  
  oddpub_results_DAS <- oddpub::open_data_search_parallel(open_data_statements)
  oddpub_results_DAS <- oddpub_results_DAS %>%
    rename(is_open_data_DAS = is_open_data) %>%
    rename(is_open_code_DAS = is_open_code) %>%
    rename(open_data_statements_DAS = open_data_statements) %>%
    rename(open_code_statements_DAS = open_code_statements) 
  
  return(oddpub_results_DAS)
}

combine_oddpub_results <- function(oddpub_results_DAS, oddpub_results_full_text, save_filename)
{
  print("Combine results of ODDPub screening of full texts and medrxiv data availibility statements.")
  oddpub_results_comb <- oddpub_results_full_text %>%
    left_join(oddpub_results_DAS)
  
  #fill missing fields with false
  oddpub_results_comb$is_open_data_DAS[is.na(oddpub_results_comb$is_open_data_DAS)] <- FALSE
  oddpub_results_comb$is_open_code_DAS[is.na(oddpub_results_comb$is_open_code_DAS)] <- FALSE
  
  #combine results for the statements
  oddpub_results_comb[["is_open_data_comb"]] <- oddpub_results_comb$is_open_data | oddpub_results_comb$is_open_data_DAS
  oddpub_results_comb[["is_open_code_comb"]] <- oddpub_results_comb$is_open_code | oddpub_results_comb$is_open_code_DAS
  
  
  #combine detected statements
  oddpub_results_comb$open_data_statements[is.na(oddpub_results_comb$open_data_statements)] <- ""
  oddpub_results_comb$open_data_statements_DAS[is.na(oddpub_results_comb$open_data_statements_DAS)] <- ""
  oddpub_results_comb[["open_data_statements_comb"]] <- paste(oddpub_results_comb$open_data_statements, 
                                                              oddpub_results_comb$open_data_statements_DAS, 
                                                              sep = "; ")
  oddpub_results_comb$open_data_statements_comb[oddpub_results_comb$open_data_statements_comb == "; "] = ""
  
  
  oddpub_results_comb$open_code_statements[is.na(oddpub_results_comb$open_code_statements)] <- ""
  oddpub_results_comb$open_code_statements_DAS[is.na(oddpub_results_comb$open_code_statements_DAS)] <- ""
  oddpub_results_comb[["open_code_statements_comb"]] <- paste(oddpub_results_comb$open_code_statements, 
                                                              oddpub_results_comb$open_code_statements_DAS, 
                                                              sep = "; ")
  oddpub_results_comb$open_code_statements_comb[oddpub_results_comb$open_code_statements_comb == "; "] = ""
  
  
  oddpub_results_comb_clean <- oddpub_results_comb %>% 
    select(article, is_open_data_comb, is_open_code_comb, 
           open_data_statements_comb, open_code_statements_comb) %>%
    rename(is_open_data = is_open_data_comb) %>%
    rename(is_open_code = is_open_code_comb) %>%
    rename(open_data_statements = open_data_statements_comb) %>%
    rename(open_code_statements = open_code_statements_comb) %>% 
    arrange(article)
  
  
  write_csv(oddpub_results_comb_clean, save_filename)
}