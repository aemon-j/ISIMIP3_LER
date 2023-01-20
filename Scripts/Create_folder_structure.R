# Move ISIMIP forcing files to our folder structure (Lake - GCM - Scen)
# Assumes all ISIMIP zip files are in the same structure as they
# are stored on the DKRZ server, starting in folder_isimip_root
# Hypsograph and temperature observations are not yet copied
# (they should be put in the lakes folder, see 1_Set_up_LER_folders.R,
# but obs do not yet need to be compiled)

# Run 0_Initialise.R first

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

df_char = fread(file.path(folder_root, folder_lakechar, "LakeCharacteristics.csv"))
name_couples = df_char[`Lake Short Name` %in% lakes, .(`Lake Short Name`, `Lake Name Folder`)]

# Create folder structure and copy files
for(i in lakes){
  lake_report = name_couples[`Lake Short Name` == i, `Lake Name Folder`]
  
  if(lake_report == "rappbodep"){
    lake_report = "rappbode"
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
                                           k, j), pattern = paste0("_", lake_report))
      
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
                               pattern = paste0("_", lake_report))
    
    file.copy(from = file.path(folder_root, folder_isimip_calib_files,
                               calib_gcm, files_to_copy),
              the_folder, overwrite = TRUE)
  }
}
