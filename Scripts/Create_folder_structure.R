# Move ISIMIP forcing files to our folder structure (Lake - GCM - Scen)
# Assumes all ISIMIP zip files are in the same structure as they
# are stored on the DKRZ server, starting in folder_isimip_root
# Hypsograph and temperature observations are not yet copied
# (they should be put in the lakes folder, see 1_Set_up_LER_folders.R,
# but obs do not yet need to be compiled)

# Run 0_Initialise.R first

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

# Unzip all the nc files, if not already done so
for(i in scens){
  if(i == "calibration"){
    # Different dataset for calibration
    if(!dir.exists(file.path(folder_root, folder_isimip_calib_files, calib_gcm))) next
    
    isimip_files = list.files(file.path(folder_root, folder_isimip_calib_files, calib_gcm))
    
    if(length(grep(".txt", isimip_files)) == 0L){
      unzip_isimip(file.path(folder_root, folder_isimip_root, i, calib_gcm), only_certain_lakes = lakes)
    }
    
  }else{
    for(j in gcms){
      if(!dir.exists(file.path(folder_root, folder_isimip_root,
                               i, j))) next
      
      isimip_files = list.files(file.path(folder_root, folder_isimip_root,
                                          i, j))
      if(length(grep(".txt", isimip_files)) == 0L){
        unzip_isimip(file.path(folder_root, folder_isimip_root, i, j), only_certain_lakes = lakes)
      }
    }
  }
}

# Create folder structure and copy files
for(i in lakes){
  # If there are no data for this lake on the portal, skip
  filename = paste(tolower(gcms[1]), "r1i1p1f1_w5e5",
                   scens[1], "hurs", tolower(i), "daily.txt", sep = "_")
  if(!file.exists(file.path(folder_root, folder_isimip_root,
                            scens[1], gcms[1], filename))){
    warning("No data found for lake ", i)
    next
  }
  
  for(j in gcms){
    for(k in scens){
      if(k == "calibration") next
      
      the_folder = file.path(folder_root,
                             folder_data,
                             i, tolower(j), k)
      if(!dir.exists(the_folder)){
        dir.create(the_folder, recursive = TRUE)
      }
      
      files_to_copy = list.files(file.path(folder_root, folder_isimip_root,
                                           k, j), pattern = ".txt")
      files_to_copy = files_to_copy[grepl(tolower(i), files_to_copy)]
      
      file.copy(from = file.path(folder_root, folder_isimip_root,
                                 k, j, files_to_copy),
                the_folder, overwrite = TRUE)
    }
  }
  
  if("calibration" %in% scens){
    the_folder = file.path(folder_root,
                           folder_data,
                           i, tolower(calib_gcm), "calibration")
    if(!dir.exists(the_folder)){
      dir.create(the_folder, recursive = TRUE)
    }
    files_to_copy = list.files(file.path(folder_root, folder_isimip_calib_files,
                                         calib_gcm),
                               pattern = ".txt")
    files_to_copy = files_to_copy[grepl(tolower(i), files_to_copy)]
    
    file.copy(from = file.path(folder_root, folder_isimip_calib_files,
                               calib_gcm, files_to_copy),
              the_folder, overwrite = TRUE)
  }
}
