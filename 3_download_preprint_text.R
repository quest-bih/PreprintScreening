

download_biorxiv_text <- function(preprint_list, pdf_html_folder)
{
  #load current list
  biorxiv_list <- preprint_list  %>%
    filter(site == "biorxiv")
  
  preprint_dois <- biorxiv_list$doi
  
  for(doi in preprint_dois) {
    
    save_filename <- paste0(pdf_html_folder,
                            doi %>% str_replace_all(fixed("/"), "+"),
                            ".txt")
    
    com <- paste0("python weekly_code/biorxiv_extractor.py ", doi, 
                  " txt ", save_filename)
    
    tryCatch({
      system(com, wait = T)
    }, error=function(e){
      print("Could not retrieve HTML text from biorxiv.")
    })
    
    print(paste0("Downloaded text file from HTML for DOI: ", doi))
    
  }
}
