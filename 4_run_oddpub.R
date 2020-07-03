library(tidyverse)

run_oddpub <- function(PDF_folder, text_folder, save_file)
{
  print("Convert PDFs to text.")
  oddpub::pdf_convert(PDF_folder, text_folder)
  
  print("Load converted preprints.")
  PDF_text <- oddpub::pdf_load(text_folder)
  
  print("Run ODDPub.")
  oddpub_results <- oddpub::open_data_search_parallel(PDF_text)
  
  oddpub_results$article <- oddpub_results$article %>%
    str_remove(fixed(".txt")) %>%
    str_replace_all(fixed("+"), "/")
  
  write_csv(oddpub_results, save_file)
}
