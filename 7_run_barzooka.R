
run_barzooka <- function(pdf_folder, tmp_folder, save_file)
{
  print("Barzooka prediction...")
  #need correct conda environment to run Barzooka script
  use_condaenv("fastai", required = TRUE)
  barzooka = Barzooka()
  barzooka_pred_list <- list()
  pdf_list <- paste0(pdf_folder, list.files(pdf_folder))
  
  for(pdf in pdf_list) 
  {
    print(pdf)
    tryCatch({
      barzooka_pred_list[[pdf]] <- barzooka$predict_from_file(pdf, tmp_folder)
    }, error=function(e){
      print(paste0("Could not screen pdf ", pdf))
    })
  }
  barzooka_results <- do.call(rbind, barzooka_pred_list %>% map(as_tibble))
  write_csv(barzooka_results, save_file)
  
}