# Unzips all ISIMIP zip files
# Assumes all are in the same folder

unzip_isimip = function(folder, only_certain_lakes = NULL){
  # Set working directory
  oldwd <- getwd()
  setwd(folder)
  
  on.exit({
    setwd(oldwd)
  })
  
  all_files = list.files(pattern = ".zip")
  
  if(!is.null(only_certain_lakes)){
    condition = tolower(paste0(only_certain_lakes, collapse = "|"))
    all_files = all_files[grepl(condition, all_files)]
  }
  
  if(.Platform$OS.type == "windows"){
    unzip_command = "tar -xf"
  }else{
    unzip_command = "unzip"
  }
  
  setwd(folder)
  lapply(all_files, function(x) system(paste(unzip_command, x)))
  
}
