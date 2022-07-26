# Load packages required for the project

req_packages = c("data.table",
                 "LakeEnsemblR",
                 "stringr",
                 "lubridate",
                 "ncdf4",
                 "parallel",
                 "configr",
                 "FME")

# Make sure all packages are installed and then load them
suppressWarnings({
  inst_pack = sapply(req_packages, function(x) x %in% rownames(installed.packages()))
  
  if(any(inst_pack == F)){
    notinstalled = inst_pack[which(inst_pack == F)]
    
    stop("Install the following packages first: ",
         names(notinstalled),
         "\n Then run Load_packages.R again. ")
    
  }else{
    sapply(req_packages, require, character.only = TRUE)
  }
})

rm(req_packages)
