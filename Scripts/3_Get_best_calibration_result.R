# Change the settings of the folders to the best calibration
# If the lake was not calibrated, the default values are used and this script will not change any values. 

# Script assumes that the calibration folder is called "cali". The script will try to find the
# latest calibration result in that folder. If this is not what you want, only keep one calibration
# file in the "cali" folder.

# Lowest rmse is assumed to be the best fit

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

progressBar = txtProgressBar(min = 0, max = length(lakes), initial = 0)
progress = 0

for(i in lakes){
  
  the_folder = file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration", "cali")
  
  if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
    progress = progress + 1
    setTxtProgressBar(progressBar,progress)
    
    next
  }
  
  ### Get best calibration for every model
  the_files = list.files(the_folder)
  
  if(calib_type == "cal_project"){
    file.copy(file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration", "LakeEnsemblR.yaml"),
              file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration", "LakeEnsemblR_calib.yaml"),
              overwrite = T)
  }
  
  for(j in models_to_run){
    
    param_files = the_files[grepl(paste0("params_", j), the_files)]
    if(length(param_files) == 0L){
      next
    }
    
    # Extract the last date
    tags = str_match(param_files, "params_.*_(\\d*).csv")[,2]
    the_tag = tags[which.max(tags)]
    param_file_name = param_files[which.max(tags)]
    cal_output_file_name = the_files[!grepl("params_", the_files) &
                                       grepl(j, the_files) &
                                       grepl(the_tag, the_files)]
    
    df_pars = fread(file.path(the_folder, param_file_name))
    df_output = fread(file.path(the_folder, cal_output_file_name))
    
    df_cal = merge(df_pars, df_output[, .(par_id, rmse)], by = "par_id")
    ind_bestfit = which.min(df_cal[, rmse])
    
    # Enter information in the LER config file in the folder of every gcm
    pars_to_set = names(df_cal)[!(names(df_cal) %in% c("par_id", "rmse"))]
    
    if(calib_type == "cal_project"){
      # Write to same folder as "LakeEnsemblR_calib.yaml" and then don't do
      # the whole loop over the gcms and scens
      ls_LER_config = read.config(file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration", "LakeEnsemblR_calib.yaml"))
      
      for(m in pars_to_set){
        if(m %in% c("wind_speed", "swr", "lwr")){
          # Add in scaling_factors section
          ls_LER_config[["scaling_factors"]][[j]][[m]] = df_cal[ind_bestfit, ..m][[1]]
        }else if(m == "Kw"){
          ls_LER_config[["input"]][["light"]][[m]][[j]] = df_cal[ind_bestfit, ..m][[1]]
        }else{
          # Add in model_parameters section
          ls_LER_config[["model_parameters"]][[j]][[m]] = df_cal[ind_bestfit, ..m][[1]]
        }
      }
      
      # Write the updated config file
      write.config(ls_LER_config,
                   file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration", "LakeEnsemblR_calib.yaml"),
                   write.type = "yaml",
                   indent = 3L,
                   handlers = list(
                     logical = function(x){
                       result = ifelse(x, "true", "false")
                       class(result) = "verbatim"
                       return(result)
                     },
                     NULL = function(x){
                       result = "NULL"
                       class(result) = "verbatim"
                       return(result)
                     }
                   ))
      
      progress = progress + 1
      setTxtProgressBar(progressBar,progress)
      next
    }
    
    for(k in gcms){
      #for(l in scens[!(scens %in% "calibration")]){
      for(l in scens){
        
        LER_config_path = file.path(folder_root, folder_data, i, tolower(k), l, "LakeEnsemblR.yaml")
        ls_LER_config = read.config(LER_config_path)
        
        # We now have the file that needs to be changed and the best calibration for one of the models
        # Enter this information in the LakeEnsemblR.yaml file
        for(m in pars_to_set){
          if(m %in% c("wind_speed", "swr", "lwr")){
            # Add in scaling_factors section
            ls_LER_config[["scaling_factors"]][[j]][[m]] = df_cal[ind_bestfit, ..m][[1]]
          }else if(m == "Kw"){
            ls_LER_config[["input"]][["light"]][[m]][[j]] = df_cal[ind_bestfit, ..m][[1]]
          }else{
            # Add in model_parameters section
            ls_LER_config[["model_parameters"]][[j]][[m]] = df_cal[ind_bestfit, ..m][[1]]
          }
        }
        
        # Write the updated config file
        # (handles needed to write true/false instead of yes/no, and to write "" for empty fields)
        write.config(ls_LER_config,
                     LER_config_path,
                     write.type = "yaml",
                     indent = 3L,
                     handlers = list(
                       logical = function(x){
                         result = ifelse(x, "true", "false")
                         class(result) = "verbatim"
                         return(result)
                       },
                       NULL = function(x){
                         result = "NULL"
                         class(result) = "verbatim"
                         return(result)
                       }
                     ))
      }
    }
  }
  
  # Update the config file for every sub-folder of the lake
  if(calib_type != "cal_project"){
    for(j in gcms){
      #for(k in scens[!(scens %in% "calibration")]){
      for(k in scens){
        export_config("LakeEnsemblR.yaml",
                      model = models_to_run,
                      folder = file.path(folder_root, folder_data, i, tolower(j), k))
      }
    }
  }
  
  progress = progress + 1
  setTxtProgressBar(progressBar,progress)
}
