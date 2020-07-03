library(tidyverse)
library(jsonlite)
library(foreach)
require(doParallel)

#------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------

download_preprints <- function(preprint_list, save_folder)
{
  preprint_dois <- preprint_list$doi
  preprint_links <- preprint_list$URL

  print("Download preprints.")
  
  #download pdfs - use the URLs for the download as the 
  #DOIs are invalid for the first few days
  #need to pass dois only to name downloaded files
  download_preprints_from_URLs(preprint_dois, preprint_links, save_folder)
  
}


#------------------------------------------------------------------------------------------
# helper functions
#------------------------------------------------------------------------------------------

download_preprints_from_URLs <- function(dois, URLs, save_folder, cluster_num = 3) 
{
  cl <- makeCluster(cluster_num, outfile="")
  registerDoParallel(cl)
  
  download_success <- foreach(i = 1:length(URLs), .export = "download_from_URL", .packages = "tidyverse") %dopar% {
    download_from_URL(dois[i], URLs[i], save_folder)
  }
  
  stopCluster(cl)
}


download_from_URL <- function(doi, URL, save_folder) 
{
  print(paste0("doi: ", doi))
  current_URL <- URL
  current_doi <- doi
  
  target_filename <- paste0(save_folder, 
                            current_doi %>% str_replace_all(fixed("/"), "+"),
                            ".pdf")
  
  if(file.exists(target_filename)) {
    print(paste0("File already exists for doi ", current_doi))
  } else {
    
    tryCatch({
      page_content <- readLines(current_URL, warn = FALSE)
      pdf_url <- .get_pdf_url_meta(page_content)
      
    }, error=function(e){
      pdf_url <- ""
      print("Could not open doi webpage.")
    })
    
    download_URL <- paste0(current_URL, "v1.full.pdf")
    print(download_URL)
    
    tryCatch({
      download.file(download_URL, target_filename, mode = "wb", quiet = TRUE)
    }, error=function(e){
      print(paste0("Could not access pdf file at ", download_URL))
    })
    
  }
}

.get_pdf_url_meta <- function(page_content)
{
  journal_name <- .get_meta_content(page_content, "citation_pdf_url")
  return(journal_name)
}


#---------------------------------------------------------------------
# get content of meta info with name='field'
#---------------------------------------------------------------------

.get_meta_content <- function(page_content, field)
{
  meta_line <- .get_field_line(page_content, field)
  meta_field_substr <- .get_field_substr(meta_line, field)
  meta_content <- .extract_content(meta_field_substr)
  
  if(is.na(meta_content)) {
    meta_content = ""
  }
  return(meta_content)
}


#get line that includes 'field'
.get_field_line <- function(content, field)
{
  grep_str <- paste0('meta name="',field,'"')
  field_idx <- grep(grep_str, content)
  if(length(field_idx) == 0) {
    #if nothing found, make second try
    #both meta and name=field need to be in the line, but the order might vary between webpages -> split to two greps
    grep_str_1 <- 'meta'
    grep_str_2 <- field
    field_idx_1 <- grep(grep_str_1, content)
    field_idx_2 <- grep(grep_str_2, content)
    field_idx <- intersect(field_idx_1, field_idx_2)
    if(length(field_idx) == 0) {
      return("")
    }
  }
  field_line <- content[field_idx]
  return(field_line)
}


#check if many meta infos in one line, extract right field
.get_field_substr <- function(meta_line, field)
{
  meta_line_fields <- strsplit(meta_line,"<")[[1]]
  if(length(meta_line_fields) == 2) {
    return(meta_line) #everything ok, only one field in line
  }
  
  meta_field <- .get_field_line(meta_line_fields, field)
  return(meta_field)
}


#strip unneccesary parts of the line string to get content of the field
.extract_content <- function(meta_line)
{
  meta_content <- strsplit(meta_line, 'content=')[[1]][2]
  if(length(grep('\"',meta_content)) == 0) { #check if quotation marks are given as " or '
    meta_content <- strsplit(meta_content, '\'')[[1]][2]
  } else {
    meta_content <- strsplit(meta_content, '\"')[[1]][2]
  }
  #meta_content <- gsub("[\"'/>]","",meta_content)
  meta_content <- trimws(meta_content, which = "both")
}

