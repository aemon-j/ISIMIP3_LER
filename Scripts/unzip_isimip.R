# Unzips all ISIMIP zip files
# Assumes all are in the same folder

unzip_isimip = function(folder){
  # Set working directory
  oldwd <- getwd()
  setwd(folder)
  
  on.exit({
    setwd(oldwd)
  })
  
  all_files = list.files(pattern = ".zip")
  
  if(.Platform$OS.type == "windows"){
    unzip_command = "tar -xf"
  }else{
    unzip_command = "unzip -p"
  }
  
  setwd(folder)
  lapply(all_files, function(x) system(paste(unzip_command, x)))
  
}
