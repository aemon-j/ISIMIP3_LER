# First step - Set up LER folder structure for each run
# However, before this step, the file structure should be in place - see 0_Create_folder_structure.R

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

progressBar = txtProgressBar(min = 0, max = length(lakes), initial = 0)
progress = 0

for(i in lakes){
  the_lake_folder = file.path(folder_root, folder_lakechar, i)
  
  if(!dir.exists(the_lake_folder)){
    next
  }
  
  ##### Read hypsograph -----
  hyps_filename = list.files(the_lake_folder)
  hyps_filename = hyps_filename[grepl("hypsometry", hyps_filename)]
  
  df_hyps = fread(file.path(the_lake_folder, hyps_filename))
  df_hyps = df_hyps[, -(1:2)]
  setnames(df_hyps, c("Depth_meter", "Area_meterSquared"))
  
  ##### Read wtemp observations -----
  obs_files = list.files(the_lake_folder)
  obs_files = obs_files[grepl("temp_", obs_files)]
  
  if(any(grepl("_daily", obs_files))){
    obs_files = obs_files[grepl("_daily", obs_files)][1]
  }
  
  if(length(obs_files) > 1L){
    df_obs = merge_temp_obs(obs_files, folder = the_lake_folder)
    df_obs = df_obs[, -(1:3)]
    df_obs = df_obs[complete.cases(df_obs)]
    strmatch = str_match(df_obs[, TIMESTAMP_END], "(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})")
    df_obs[, TIMESTAMP_END := paste0(strmatch[,2], "-", strmatch[,3], "-", strmatch[,4], " ",
                                     strmatch[,5], ":", strmatch[,6], ":00")]
    df_obs[, TIMESTAMP_END := as.POSIXct(TIMESTAMP_END)]
    # Calculate daily averages
    df_obs = df_obs[, .(WTEMP = mean(WTEMP)), by = .(ceiling_date(TIMESTAMP_END, unit = "days"),
                                                                 DEPTH)]
  }else{
    df_obs = fread(file.path(the_lake_folder, obs_files))
    df_obs = df_obs[, -(1:2)]
    df_obs = df_obs[complete.cases(df_obs)]
    strmatch = str_match(df_obs[, TIMESTAMP], "(\\d{4})(\\d{2})(\\d{2})")
    df_obs[, TIMESTAMP := paste0(strmatch[,2], "-", strmatch[,3], "-", strmatch[,4], " ",
                                 "00:00:00")]
    df_obs[, TIMESTAMP := as.POSIXct(TIMESTAMP)]
  }
  setnames(df_obs, c("datetime", "Depth_meter", "Water_Temperature_celsius"))
  df_obs[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  
  ##### Select depth resolution of output -----
  df_char = fread(file.path(folder_root, folder_lakechar, "LakeCharacteristics.csv"))
  
  max_depth = max(df_hyps[, max(Depth_meter)], df_char[`Lake Short Name` == i, `max depth (m)`], na.rm = T)
  
  # Get output resolution based on max_depth
  output_res = get_output_resolution(max_depth)
  
  ##### Get light extinction -----
  secchi_d = df_char[`Lake Short Name` == i, `Average Secchi disk depth [m]`]
  kw = df_char[`Lake Short Name` == i, `Light extinction coefficient [m-1]`]
  
  if(!is.na(kw)){
    extinc_coef = kw
  }else if(!is.na(secchi_d)){
    # Koenings and Edmundson (1991). doi:10.4319/lo.1991.36.1.0091
    extinc_coef = 1.7 / secchi_d
  }else{
    # Default is Hakanson function (Aquatic Sciences, 1995)
    extinc_coef = round(1.1925 * max_depth^(-0.424), 3L)
  }
  
  ##### Read elevation -----
  elev = df_char[`Lake Short Name` == i, `elevation (m)`]
  latitude = df_char[`Lake Short Name` == i, `latitude (dec deg)`]
  longitude = df_char[`Lake Short Name` == i, `longitude (dec deg)`]
  
  for(j in c(gcms, calib_gcm)){
    for(k in scens){
      if(j != calib_gcm & k == "calibration") next
      if(j == calib_gcm & k != "calibration") next
      
      the_folder = file.path(folder_root, folder_data, i, tolower(j), k)
      
      if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
        progress = progress + 1
        setTxtProgressBar(progressBar,progress)
        
        next
      }
      
      ##### Convert meteo into LER format -----
      convert_ISIMIP_to_LER(the_folder, rounding_dec = 4L)
      
      ##### Hypsograph ----
      fwrite(df_hyps, file.path(the_folder, "hypsograph.csv"))
      
      ##### Observations -----
      if(k == "calibration"){
        fwrite(df_obs, file.path(the_folder, "obs_wtemp.csv"))
      }
      
      ##### LER configuration file -----
      # Standard settings are supposed to be correct in the LakeEnsemblR.yaml configuration file
      # Only settings that change per lake are altered. 
      
      file.copy(file.path(folder_root, folder_template_LER, "LakeEnsemblR.yaml"),
                file.path(the_folder, "LakeEnsemblR.yaml"),
                overwrite = T)
      
      ### Location and time settings
      df_meteo = fread(file.path(the_folder, "meteo.csv"))
      start_end_dates = c(df_meteo[1L, datetime],
                          df_meteo[.N, datetime])
      start_end_dates = format(start_end_dates, "%Y-%m-%d %H:%M:%S")
      
      if(k == "calibration"){
        # Set start and end date based on observations
        # Same end date if obs exceed forcing period
        cal_start_date = df_obs[1L, datetime]
        
        if(as.POSIXct(df_obs[.N, datetime]) < df_meteo[.N, datetime]){
          cal_end_date = df_obs[.N, datetime]
        }else{
          cal_end_date = start_end_dates[2]
        }
        start_end_dates = c(cal_start_date, cal_end_date)
      }
      
      # Latitude and longitude: take from LakeCharacteristics file
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "time", key2 = "start", value = start_end_dates[1], verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "time", key2 = "stop", value = start_end_dates[2], verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "location", key2 = "depth", value = max_depth, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "location", key2 = "init_depth", value = max_depth, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "location", key2 = "latitude", value = latitude, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "location", key2 = "longitude", value = longitude, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "location", key2 = "elevation", value = elev, verbose = F)
      
      # Set number of layers
      num_layers = ceiling(max_depth / output_res)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "model_parameters", key2 = "GOTM", key3 = "nlev",
                          value = num_layers, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "model_parameters", key2 = "Simstrat", key3 = "Grid",
                          value = num_layers, verbose = F)
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "output", key2 = "depths", value = output_res, verbose = F)
      
      ### Light
      input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                          key1 = "input", key2 = "light", key3 = "Kw", value = extinc_coef, verbose = F)
      
      ### No observed water temperature in case of no calibration
      if(k != "calibration"){
        input_yaml_multiple(file = file.path(the_folder, "LakeEnsemblR.yaml"),
                            key1 = "observations", key2 = "temperature", key3 = "file", value = "", verbose = F)
      }
      
      ##### Initial temperature profile -----
      df_init = create_init_profile2(df_obs, start_date = start_end_dates[1],
                                     max_depths = max_depths_init_prof)
      if(nrow(df_init) == 0L){
        df_init = create_init_profile2(df_obs, start_date = start_end_dates[1],
                                       margin_time = months(3),
                                       max_depths = max_depths_init_prof)
      }
      if(nrow(df_init) == 0L){
        df_init = create_init_profile2(df_obs, start_date = start_end_dates[1],
                                       margin_time = months(5),
                                       max_depths = max_depths_init_prof)
      }
      df_init = df_init[Depth_meter <= max_depth]
      
      # Some lakes only have surface measurements - assume fully mixed lake
      if(nrow(df_init) == 1L){
        df_init = rbindlist(list(df_init, df_init, df_init))
        df_init[, Depth_meter := c(0.0, round(max_depth / 2, 2L), max_depth)]
      }
      
      fwrite(df_init, file.path(the_folder, "init_temp_prof.csv"))
      
      ##### Spin-up -----
      if(spin_up_period > 0L){
        if(k == "calibration"){
          add_spin_up(the_folder, spin_up_years = spin_up_period, spin_up_source = "met_file")
        }else{
          add_spin_up(the_folder, spin_up_years = spin_up_period)
        }
        
      }
      
      export_config("LakeEnsemblR.yaml",
                    model = models_to_run,
                    folder = the_folder)
      
    }
  }
  
  progress = progress + 1
  setTxtProgressBar(progressBar,progress)
}

# ## fix problem with GLM fore some lakes caused by to low max_layers value
# for (i in c("Argyle", "FallingCreek", "Hassel", "Kinneret",
#             "Rimov", "Sammamish", "Tahoe", "Vendyurskoe")) {
#   glm_nml <- glmtools::read_nml(file.path(folder_root, folder_data, i,
#                                           calib_gcm, "calibration", "GLM",
#                                           "glm3.nml"))
#   glm_nml <- glmtools::set_nml(glm_nml, arg_name = 'max_layers', arg_val = 10000)
#   glmtools::write_nml(glm_nml, file = file.path(folder_root, folder_data, i,
#                                                 calib_gcm, "calibration", "GLM",
#                                                 "glm3.nml"))
#   
# }
