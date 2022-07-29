# Script to turn the LakeEnsemblR netcdf output files into the required files for ISIMIP

# Important: this script assumes that max_members in the output section has been set to 1!
# This speeds up the run and removes the need for selecting only the first member

# ISIMIP naming convention:
# <model>_<climate-forcing>_<bias-adjustment>_<climate-scenario>_<soc-scenario>_<sens-scenario>_<variable>_<lake-site>_<time-step>_<start-year>_<end-year>.nc
# Source: https://protocol.isimip.org/#reporting-model-results

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

for(i in lakes){
  for(j in gcms){
    for(k in scens[scens != "calibration"]){
      latitude = get_yaml_multiple(file.path(folder_root, folder_data, i, tolower(j), k, "LakeEnsemblR.yaml"),
                                   key1 = "location", key2 = "latitude")
      longitude = get_yaml_multiple(file.path(folder_root, folder_data, i, tolower(j), k, "LakeEnsemblR.yaml"),
                                    key1 = "location", key2 = "longitude")
      
      ##### Read all LER output -----
      nc = nc_open(file.path(folder_root, folder_data, i, tolower(j), k, "output", "ensemble_output.nc"))
      df_temp = ncvar_get(nc, varid = "temp")
      df_ice = ncvar_get(nc, varid = "ice_height")
      df_qh = ncvar_get(nc, varid = "q_sens")
      df_qe = ncvar_get(nc, varid = "q_lat")
      depths = ncvar_get(nc, varid = "z")
      tim = ncvar_get(nc, "time")
      tunits = ncatt_get(nc, "time")
      nc_close(nc)
      
      ##### Time settings -----
      # For ISIMIP3b, the relative axis reference year is 1601. This is not the same as we use in LER
      # so we have to convert the time
      tustr <- strsplit(tunits$units, " ")
      tdstr <- strsplit(unlist(tustr)[3], "-")
      tmonth <- as.integer(unlist(tdstr)[2])
      tday <- as.integer(unlist(tdstr)[3])
      tyear <- as.integer(unlist(tdstr)[1])
      tdstr <- strsplit(unlist(tustr)[4], ":")
      thour <- as.integer(unlist(tdstr)[1])
      tmin <- as.integer(unlist(tdstr)[2])
      origin <- as.POSIXct(paste0(tyear, "-", tmonth,
                                  "-", tday, " ", thour, ":", tmin),
                           format = "%Y-%m-%d %H:%M", tz = "UTC")
      time <- as.POSIXct(tim, origin = origin, tz = "UTC")
      
      ##### Read or compute the relevant output variables and write them for all models -----
      for(l in seq_along(models_to_run)){
        modelname = paste0(tolower(models_to_run[l]), "-ler")
        
        ### Water temperature - watertemp
        df_model_temp = data.table(df_temp[l, , ])
        
        ### Correct the number of dimensions for FLake
        last_col_non_na = sum(colSums(is.na(df_model_temp)) < nrow(df_model_temp)) # To avoid errors with FLake
        model_depths = depths[1:last_col_non_na]
        
        df_model_temp_write = as.matrix(df_model_temp[, 1:last_col_non_na])
        df_model_temp_write = df_model_temp_write + 273.15 # Convert to Kelvin
        
        var_name = "temp"
        
        # The bias_adjustment seems to be described in the 
        # ISIMIP3b bias adjustment fact sheet by Lange (2021)
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        
        if(!dir.exists(file.path(folder_root, folder_out))){
          dir.create(file.path(folder_root, folder_out), recursive = TRUE)
        }
        
        write_isimip_netcdf(df_model_temp_write, time, deps = model_depths, var_name = var_name,
                            var_unit = "K",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        
        ### Stratification - strat
        # Stratified if top-bottom density difference is greater than 0.1 kg/m3
        df_model_strat = fifelse(temp_to_dens(df_model_temp[, ..last_col_non_na]) - temp_to_dens(df_model_temp[, 1L]) >= 0.1,
                                 1L, 0L)
        var_name = "strat"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_strat, time, var_name = var_name,
                            var_unit = "1",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        
        ### Thermocline - thermodepth
        # Using rLakeAnalyzer and its default settings
        df_thermo_depth = copy(df_model_temp)
        setnames(df_thermo_depth, paste0("wtr_", abs(depths)))
        df_thermo_depth[, datetime := time]
        df_thermo_depth = suppressWarnings(ts.thermo.depth(df_thermo_depth, na.rm = T)[[2L]])
        df_thermo_depth[is.na(df_thermo_depth)] = 0 # Set NA's for thermocline depth to 0
        
        var_name = "thermodepth"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_thermo_depth, time, var_name = var_name,
                            var_unit = "m",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Surface temperature - surftemp
        df_surf_temp = df_model_temp[[1L]]
        
        var_name = "surftemp"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_surf_temp, time, var_name = var_name,
                            var_unit = "K",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Bottom temperature - bottemp
        df_bott_temp = df_model_temp[[last_col_non_na]]
        
        var_name = "bottemp"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_bott_temp, time, var_name = var_name,
                            var_unit = "K",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Ice thickness - icethick
        df_model_icethick = df_ice[l, ]
        
        var_name = "icethick"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_icethick, time, var_name = var_name,
                            var_unit = "m",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Ice presence - ice
        df_model_icepresence = fifelse(df_model_icethick > 0, 1L, 0L)
        
        var_name = "ice"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_icepresence, time, var_name = var_name,
                            var_unit = "1",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Sensible heat flux (upward is positive) - sensheatf-total
        df_model_qh = -1 * df_qh[l, ]
        
        var_name = "sensheatf-total"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_qh, time, var_name = var_name,
                            var_unit = "W m-2",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Latent heat flux (upward is positive) - latentheatf
        df_model_qe = -1 * df_qe[l, ]
        
        var_name = "latentheatf"
        name_netcdf = paste0(modelname, "_", tolower(j), "_lange2021_", k, "_", var_name,
                             "_", tolower(i), "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_qe, time, var_name = var_name,
                            var_unit = "W m-2",
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
      }
    }
  }
}
