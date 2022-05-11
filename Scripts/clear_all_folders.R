# Function to clear the contents of all the folders.
# Will remove all non-netcdf files and the LER folders
# IMPORTANT: You'll have to rerun the models/calibrations after you do this
# After this, you'll have to run 1_Set_up_LER_folders.R again, and then the rest of the scripts
# This function will not touch the .nc files

# You need to have run Settings.R beforehand and be in the "ISIMIP data" folder

clear_all_folders = function(i_am_certain = FALSE){
  if(isFALSE(i_am_certain)){
    stop("This function only works if you are certain you want to clear the folder contents!")
  }
  
  for(i in lakes){
    if(!dir.exists(i)) next
    
    for(j in tolower(gcms)){
      for(k in scens){
        all_files = list.files(file.path(i, j, k))
        
        files_to_remove = all_files[!dir.exists(file.path(i, j, k, all_files)) &
                                      !grepl(".nc", all_files)]
        dirs_to_remove = all_files[dir.exists(file.path(i, j, k, all_files))]
        
        file.remove(file.path(i, j, k, files_to_remove))
        unlink(file.path(i, j, k, dirs_to_remove), recursive = T)
      }
    }
  }
}
