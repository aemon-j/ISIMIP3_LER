# From the calibration and uncalibrated runs, create the csv files
# requested for the project:
# "Four CSV files, each with four columns: datetime, depth, obs, mod
# One file for each of calibrated/uncalibrated model, and
# calibration/validation time periods"

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

if(calib_type != "cal_project") stop("This script is only relevant for cal_project!")

folder_csv_output = file.path(folder_root, folder_out, "Calib_project")
if(!dir.exists(folder_csv_output)){
  dir.create(folder_csv_output)
}

for(i in lakes){
  the_folder = file.path(folder_root, folder_data, i, tolower(calib_gcm))
  
  if(!file.exists(file.path(the_folder, "calibration", "obs_wtemp.csv"))) next
  
  ### Read observations
  df_obs_cal = fread(file.path(the_folder, "calibration", "obs_wtemp.csv"))
  df_obs_val = fread(file.path(the_folder, "calibration", "obs_wtemp_val.csv"))
  setnames(df_obs_cal, c("datetime", "depth", "obs"))
  setnames(df_obs_val, c("datetime", "depth", "obs"))
  
  # df_obs_all = rbindlist(list(df_obs_cal, df_obs_val))
  obs_depths = unique(c(df_obs_cal$depth, df_obs_val$depth))
  obs_depths = obs_depths[order(obs_depths)]
  
  ### Get simulation outputs
  # Do not use the "obs" part of the output, as validation was not included
  output_cal = load_var(file.path(the_folder, "calibration",
                                  "output", "ensemble_output.nc"),
                        var = "temp", print = F)
  output_uncal = load_var(file.path(the_folder, "uncal_run",
                                    "output", "ensemble_output.nc"),
                          var = "temp", print = F)
  
  for(j in models_to_run){
    ### Calibrated
    df_sim_cal = output_cal[[j]]
    setDT(df_sim_cal)
    df_sim_cal = melt(df_sim_cal, id.vars = "datetime",
                      variable.name = "depth",
                      value.name = "mod")
    df_sim_cal[, depth := as.character(depth)]
    df_sim_cal[, depth := as.numeric(gsub("wtr_", "", depth))]
    setorder(df_sim_cal, datetime, depth)
    
    # Remove spin-up-period
    first_date = df_sim_cal[1L, datetime]
    df_sim_cal = df_sim_cal[datetime >= first_date + years(spin_up_period)]
    
    # Remove days with all NAs (FLake last day)
    days_with_data = unique(df_sim_cal[!is.na(mod), datetime])
    df_sim_cal = df_sim_cal[datetime %in% days_with_data]
    
    # Interpolate to observed depths
    df_sim_cal_interp = expand.grid(datetime = unique(df_sim_cal$datetime),
                                    depth = obs_depths)
    setDT(df_sim_cal_interp)
    setorder(df_sim_cal_interp, datetime, depth)
    
    df_sim_cal = merge(df_sim_cal,
                       df_sim_cal_interp,
                       by = c("datetime", "depth"),
                       all = T)
    df_sim_cal[, mod := approx(x = depth,
                               y = mod,
                               xout = depth,
                               rule = 1)$y,
               by = datetime]
    
    # Merge observed and simulated
    df_cal_calibrated = merge(df_obs_cal, df_sim_cal,
                              by = c("datetime", "depth"))
    df_val_calibrated = merge(df_obs_val, df_sim_cal,
                              by = c("datetime", "depth"))
    
    ### Uncalibrated
    df_sim_uncal = output_uncal[[j]]
    setDT(df_sim_uncal)
    df_sim_uncal = melt(df_sim_uncal, id.vars = "datetime",
                        variable.name = "depth",
                        value.name = "mod")
    df_sim_uncal[, depth := as.character(depth)]
    df_sim_uncal[, depth := as.numeric(gsub("wtr_", "", depth))]
    setorder(df_sim_uncal, datetime, depth)
    
    # Remove spin-up-period
    first_date = df_sim_uncal[1L, datetime]
    df_sim_uncal = df_sim_uncal[datetime >= first_date + years(spin_up_period)]
    
    # Remove days with all NAs (FLake last day)
    days_with_data = unique(df_sim_uncal[!is.na(mod), datetime])
    df_sim_uncal = df_sim_uncal[datetime %in% days_with_data]
    
    # Interpolate to observed depths
    df_sim_uncal_interp = expand.grid(datetime = unique(df_sim_uncal$datetime),
                                    depth = obs_depths)
    setDT(df_sim_uncal_interp)
    setorder(df_sim_uncal_interp, datetime, depth)
    
    df_sim_uncal = merge(df_sim_uncal,
                       df_sim_uncal_interp,
                       by = c("datetime", "depth"),
                       all = T)
    df_sim_uncal[, mod := approx(x = depth,
                               y = mod,
                               xout = depth,
                               rule = 1)$y,
                 by = datetime]
    
    # Merge observed and simulated
    df_cal_uncalibrated = merge(df_obs_cal, df_sim_uncal,
                                by = c("datetime", "depth"))
    df_val_uncalibrated = merge(df_obs_val, df_sim_uncal,
                                by = c("datetime", "depth"))
    
    if(nrow(df_cal_calibrated) == 0L |
       nrow(df_val_calibrated) == 0L |
       nrow(df_cal_uncalibrated) == 0L |
       nrow(df_val_uncalibrated) == 0L){
      stop("Non-unique obs-sim combinations detected for ", i, "!")
    }
    
    fwrite(df_cal_calibrated,
           paste0(folder_csv_output, "/", i, "_", j, "-LER_CalPeriod_Calibrated.csv"), dateTimeAs = "write.csv")
    fwrite(df_val_calibrated,
           paste0(folder_csv_output, "/", i, "_", j, "-LER_ValPeriod_Calibrated.csv"), dateTimeAs = "write.csv")
    fwrite(df_cal_uncalibrated,
           paste0(folder_csv_output, "/", i, "_", j, "-LER_CalPeriod_Uncalibrated.csv"), dateTimeAs = "write.csv")
    fwrite(df_val_uncalibrated,
           paste0(folder_csv_output, "/", i, "_", j, "-LER_ValPeriod_Uncalibrated.csv"), dateTimeAs = "write.csv")
  }
}
