# Move ISIMIP forcing files to our folder structure (Lake - GCM - Scen)

# IMPORTANT: File currently made for testing on own PC; changes needed for use on cluster. 
# Note: this currently assumes that all folders are in the root directory
# Note: this assumes that all (empty) folders already exist
# (The script could improve to create folders if needed, copy if files already exist, and to allow
#   copying from one folder with the files to another. Potentially also add an extra loop for lakes.)
# Might need to update for hypsograph and temperature observations as well (compile subdaily files)
# Leave nc files in original location: I only need to make a meteo file from them. 
# There needs to be a calibration folder too! Same forcing as historical, but cut to time period
# with observations! 

# setwd("C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Biel")

allFiles = list.files()
allFiles = allFiles[!(dir.exists(allFiles))]

gcms = c("GFDL-ESM2M", "HadGEM2-ES", "IPSL-CM5A-LR", "MIROC5", "EWEMBI")
scens = c("historical", "piControl", "rcp26", "rcp60", "rcp85", "calibration")


for(i in allFiles){
  for(j in gcms){
    if(grepl(j, i)){
      for(k in scens){
        k_temp = fifelse(k == "calibration", "EWEMBI_historical", k)
        
        # Meteo forcing
        if(grepl(k_temp, i)){
          file.rename(i, file.path(tolower(j), k, i))
          next
        }
        
        # Hypsograph
        ## Copy hypsograph to right folder
        
        
        
      }
    }
  }
}

