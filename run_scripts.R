library(tidyverse)
library(jsonlite)
library(lubridate)

source("weekly_code/1_weekly_preprint_list.R")
source("weekly_code/2_download_preprint_PDFs.R")
source("weekly_code/3_download_preprint_text.R")
source("weekly_code/4_run_oddpub.R")
source("weekly_code/5_retrieve_DAS.R")
source("weekly_code/6_oddpub_medrxiv_DAS.R")

#set parameters - for now we assume that we run the script on Mondays
# and retrieve the list from last week - probably need to be converted to input parameters
start_date = Sys.Date() - 7
end_date = Sys.Date() - 1

#make new dirs
weekly_dir <- paste0("weekly_lists/", start_date, "_", end_date, "/")
pdf_folder <- paste0(weekly_dir, "PDFs/")
pdf_html_folder <- paste0(weekly_dir, "PDFs_html_text/")
pdf_text_folder <- paste0(weekly_dir, "PDFs_to_text/")
results_folder <- paste0(weekly_dir, "results/")

dir.create(weekly_dir)  
dir.create(pdf_folder)  
dir.create(pdf_html_folder)  
dir.create(pdf_text_folder)  
dir.create(results_folder)  

#-----------------------------------------------------------------------------------------------
# 1 - retrieve newest preprint list
#-----------------------------------------------------------------------------------------------

weekly_list_filename <- paste0(weekly_dir, 
                               "preprint_list_week_", start_date, "_", end_date, ".csv") 
preprint_metadata_weekly <- get_weekly_preprint_list(start_date, end_date)
write_csv(preprint_metadata_weekly, weekly_list_filename)

#-----------------------------------------------------------------------------------------------
# 2 - download preprint PDFs
#-----------------------------------------------------------------------------------------------

download_preprints(preprint_metadata_weekly, pdf_folder)


#-----------------------------------------------------------------------------------------------
# 3 - download preprint text from HTML - only works for biorxiv
#-----------------------------------------------------------------------------------------------

#as it takes some time until the html version is available, load html from last week
last_week_list <- get_weekly_preprint_list(start_date - 7, end_date - 7)
download_biorxiv_text(last_week_list, pdf_html_folder)


#-----------------------------------------------------------------------------------------------
# 4 - run ODDPub
#-----------------------------------------------------------------------------------------------

oddpub_result_filename <- paste0(results_folder, 
                                "covid_oddpub_results_", start_date, "_", end_date, ".csv") 
run_oddpub(pdf_folder, pdf_text_folder, oddpub_result_filename)


#-----------------------------------------------------------------------------------------------
# 5 - retrieve data availibility statements from website
#-----------------------------------------------------------------------------------------------

save_filename_DAS <- paste0(results_folder, 
                        "data_availibility_statements_fields_", start_date, "_", end_date, ".csv")
get_medrxiv_DAS(weekly_list_filename, save_filename_DAS)


#-----------------------------------------------------------------------------------------------
# 6 - run ODDPub on data availibility statements from website and combine results
#-----------------------------------------------------------------------------------------------

oddpub_result_comb_filename <- paste0(results_folder, 
                        "covid_oddpub_results_with_DAS_", start_date, "_", end_date, ".csv")
oddpub_results_DAS <- screen_DAS(save_filename_DAS)
oddpub_results_full_text <- read_csv(oddpub_result_filename)
combine_oddpub_results(oddpub_results_DAS, oddpub_results_full_text, oddpub_result_comb_filename)


