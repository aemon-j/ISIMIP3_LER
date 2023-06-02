# First run the calibrated fit. Then set up and run the standard,
# uncalibrated run for the calibration project

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

if(calib_type != "cal_project") stop("This script is only relevant for cal_project!")

for(i in lakes){
  cal_folder = file.path(folder_root, folder_data, i, tolower(calib_gcm), "calibration")
  
  # Check if the observations are sufficiently long
  if(!dir.exists(cal_folder) | length(list.files(cal_folder, pattern = "obs_")) == 0L){
    next
  }
  
  ##### Calibrated run -----
  oldwd = getwd()
  setwd(cal_folder)
  run_ensemble(config_file = "LakeEnsemblR_calib.yaml",
               model = models_to_run)
  setwd(oldwd)
  
  ##### Standard, uncalibrated run -----
  std_folder = file.path(folder_root, folder_data, i, tolower(calib_gcm), "uncal_run")
  if(!dir.exists(std_folder)){
    dir.create(std_folder)
  }
  
  ### Create standard-run config file
  LER_config_path = file.path(cal_folder, "LakeEnsemblR.yaml")
  ls_LER_config = read.config(LER_config_path)
  
  max_depth = ls_LER_config[["location"]][["depth"]]
  extinc_coef = round(1.1925 * max_depth^(-0.424), 3L)
  
  ## Set extinction coefficient for all models
  for(j in models_to_run){
    ls_LER_config[["input"]][["light"]][["Kw"]][[j]] = extinc_coef
  }
  
  ## No scaling factors
  ls_LER_config[["scaling_factors"]] = list(all = list(wind_speed = 1.0,
                                                       swr = 1.0))
  
  ## No model parameters (except those specifying grid structure)
  gotm_nlev = ls_LER_config[["model_parameters"]][["GOTM"]][["nlev"]]
  simstrat_grid = ls_LER_config[["model_parameters"]][["Simstrat"]][["Grid"]]
  ls_LER_config[["model_parameters"]] = list(GOTM = list(nlev = gotm_nlev),
                                             Simstrat = list(Grid = simstrat_grid))
  
  ## Write file
  write.config(ls_LER_config,
               file.path(std_folder, "LakeEnsemblR.yaml"),
               write.type = "yaml",
               indent = 3L,
               handlers = list(logical = function(x){
                 result = ifelse(x, "true", "false")
                 class(result) = "verbatim"
                 return(result)
               },
               NULL = function(x){
                 result = ""
                 class(result) = "verbatim"
                 return(result)
               }))
  
  ### Copy all files
  file_hyps = ls_LER_config[["location"]][["hypsograph"]]
  file_init = ls_LER_config[["input"]][["init_temp_profile"]][["file"]]
  file_met = ls_LER_config[["input"]][["meteo"]][["file"]]
  
  file.copy(file.path(cal_folder, c(file_hyps, file_init, file_met)),
            file.path(std_folder, c(file_hyps, file_init, file_met)),
            overwrite = T)
  
  ### Run export_config
  export_config("LakeEnsemblR.yaml",
                model = models_to_run,
                folder = std_folder)
  
  ### Run ensemble
  setwd(std_folder)
  run_ensemble("LakeEnsemblR.yaml",
               model = models_to_run)
  setwd(oldwd)
}
