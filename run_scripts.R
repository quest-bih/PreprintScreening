library(tidyverse)
library(jsonlite)
library(lubridate)
library(reticulate)

source("1_weekly_preprint_list.R")
source("2_download_preprint_PDFs.R")
source("3_download_preprint_text.R")
source("4_run_oddpub.R")
source("5_retrieve_DAS.R")
source("6_oddpub_medrxiv_DAS.R")
source("7_run_barzooka.R")
source_python("barzooka.py")

#set parameters - for now we assume that we run the script on Mondays
# and retrieve the list from last week - probably need to be converted to input parameters
start_date = Sys.Date() - 7
end_date = Sys.Date() - 1

#make new dirs
weekly_dir <- paste0("../weekly_lists/", start_date, "_", end_date, "/")
pdf_folder <- paste0(weekly_dir, "PDFs/")
pdf_html_folder <- paste0(weekly_dir, "PDFs_html_text/")
pdf_text_folder <- paste0(weekly_dir, "PDFs_to_text/")
results_folder <- paste0(weekly_dir, "results/")
tmp_folder <- paste0(weekly_dir, "tmp/")

dir.create(weekly_dir)  
dir.create(pdf_folder)  
dir.create(pdf_html_folder)  
dir.create(pdf_text_folder)  
dir.create(results_folder)
dir.create(tmp_folder)


#-----------------------------------------------------------------------------------------------
# 1 - retrieve newest preprint list
#-----------------------------------------------------------------------------------------------

#download newest json metadata file
biorxiv_json_filename <- paste0(weekly_dir, "biorxiv_medrxiv_covid_papers_", Sys.Date(),".json")
download_preprint_json_list(biorxiv_json_filename)

#filter weekly preprints
weekly_list_filename <- paste0(weekly_dir, 
                               "preprint_list_week_", start_date, "_", end_date, ".csv") 
preprint_metadata_weekly <- filter_weekly_preprint_list(start_date, end_date, biorxiv_json_filename)
write_csv(preprint_metadata_weekly, weekly_list_filename)


#-----------------------------------------------------------------------------------------------
# 2 - download preprint PDFs
#-----------------------------------------------------------------------------------------------

download_preprints(preprint_metadata_weekly, pdf_folder)


#-----------------------------------------------------------------------------------------------
# 3 - download preprint text from HTML - only works for biorxiv
#-----------------------------------------------------------------------------------------------

#as it takes some time until the html version is available, load html from last week
last_week_list <- filter_weekly_preprint_list(start_date - 7, end_date - 7, biorxiv_json_filename)
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


#-----------------------------------------------------------------------------------------------
# 7 - run Barzooka
#-----------------------------------------------------------------------------------------------

barzooka_results_filename <- paste0(results_folder, 
                                    "covid_barzooka_results_", 
                                    start_date, "_", end_date, ".csv")
run_barzooka(pdf_folder, tmp_folder, barzooka_results_filename)

