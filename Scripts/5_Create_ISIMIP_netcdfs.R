# Script to turn the LakeEnsemblR netcdf output files into the required files for ISIMIP

# Important: this script assumes that max_members in the output section has been set to 1!
# This speeds up the run and removes the need for selecting only the first member

# ISIMIP naming convention:
# <model>_<climate-forcing>_<bias-adjustment>_<climate-scenario>_<soc-scenario>_<sens-scenario>_<variable>_<lake-site>_<time-step>_<start-year>_<end-year>.nc
# Source: https://protocol.isimip.org/#reporting-model-results

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

df_char = fread(file.path(folder_root, folder_lakechar, "LakeCharacteristics.csv"))
name_couples = df_char[, .(`Lake Short Name`, `Lake Name Folder`)]

bias_adj_name = "w5e5"
soc_scen_name = "2015soc"
sens_scen_name = "default"

for(i in lakes){
  lake_report_name = name_couples[`Lake Short Name` == i, `Lake Name Folder`]
  
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
      
      ##### Fill NAs at start and end (can be relevant for FLake) -----
      df_temp = fill_first_last_na(df_temp)
      df_ice = fill_first_last_na(df_ice)
      df_qh = fill_first_last_na(df_qh)
      df_qe = fill_first_last_na(df_qe)
      
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
      
      ### Remove the spin-up period
      first_time_sim = time[1L] + years(spin_up_period)
      first_ind = which(time >= first_time_sim)[1L]
      df_temp = df_temp[,first_ind:length(time),]
      df_ice = df_ice[,first_ind:length(time)]
      df_qh = df_qh[,first_ind:length(time)]
      df_qe = df_qe[,first_ind:length(time)]
      time = time[first_ind:length(time)]
      
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
        
        var_name = "watertemp"
        var_longname = "Temperature of Lake Water"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        
        if(!dir.exists(file.path(folder_root, folder_out))){
          dir.create(file.path(folder_root, folder_out), recursive = TRUE)
        }
        
        write_isimip_netcdf(df_model_temp_write, time, deps = model_depths, var_name = var_name,
                            var_unit = "K", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        
        ### Stratification - strat
        # Stratified if top-bottom density difference is greater than 0.1 kg/m3
        
        # Extracting the last non-NA value for each row
        last_col_non_na_variable = rowSums(!is.na(df_model_temp))
        bottom_temps = sapply(1:nrow(df_model_temp), function(x){
          if(last_col_non_na_variable[x] == 0){
            as.numeric(NA)
          }else{
            df_model_temp[[last_col_non_na_variable[x]]][x]
          }
        })
        
        df_model_strat = fifelse(temp_to_dens(bottom_temps) - temp_to_dens(df_model_temp[, 1L]) >= 0.1,
                                 1L, 0L)
        var_name = "strat"
        var_longname = "Thermal Stratification"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_strat, time, var_name = var_name,
                            var_unit = "1", var_longname,
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
        var_longname = "Depth of Thermocline"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_thermo_depth, time, var_name = var_name,
                            var_unit = "m", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Surface temperature - surftemp
        df_surf_temp = df_model_temp[[1L]] + 273.15
        
        var_name = "surftemp"
        var_longname = "Temperature of Lake Surface Water"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_surf_temp, time, var_name = var_name,
                            var_unit = "K", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Bottom temperature - bottemp
        df_bott_temp = bottom_temps + 273.15
        
        var_name = "bottemp"
        var_longname = "Temperature of Lake Bottom Water"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_bott_temp, time, var_name = var_name,
                            var_unit = "K", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Ice thickness - icethick
        df_model_icethick = df_ice[l, ]
        
        var_name = "icethick"
        var_longname = "Ice Thickness"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_icethick, time, var_name = var_name,
                            var_unit = "m", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Ice presence - ice
        df_model_icepresence = fifelse(df_model_icethick > 0, 1L, 0L)
        
        var_name = "ice"
        var_longname = "Lake Ice Cover"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_icepresence, time, var_name = var_name,
                            var_unit = "1", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Sensible heat flux (upward is positive) - sensheatf-total
        df_model_qh = -1 * df_qh[l, ]
        
        if(modelname == "gotm-ler"){
          # Information from Ana Ayala: the GOTM output has not been multiplied
          # by the heat scale factor, even though this is used in the heat budget
          heat_scale_factor = get_yaml_multiple(file.path(folder_root, folder_data, i,
                                                          tolower(j), k, "GOTM", "gotm.yaml"),
                                                key1 = "surface", key2 = "fluxes",
                                                key3 = "heat", key4 = "scale_factor")
          df_model_qh = df_model_qh * heat_scale_factor
        }
        
        var_name = "sensheatf-total"
        var_longname = "Sensible Heat Flux at Lake-Atmosphere Interface"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_qh, time, var_name = var_name,
                            var_unit = "W m-2", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
        
        ### Latent heat flux (upward is positive) - latentheatf
        df_model_qe = -1 * df_qe[l, ]
        if(modelname == "gotm-ler"){
          df_model_qe = df_model_qe * heat_scale_factor
        }
        var_name = "latentheatf"
        var_longname = "Latent Heat Flux at Lake-Atmosphere Interface"
        
        name_netcdf = paste0(modelname, "_", tolower(j), "_", bias_adj_name, "_", k, "_", soc_scen_name, "_", sens_scen_name, "_", var_name,
                             "_", lake_report_name, "_daily_", year(time[1L]), "_",
                             year(time[length(time)]), ".nc")
        write_isimip_netcdf(df_model_qe, time, var_name = var_name,
                            var_unit = "W m-2", var_longname,
                            file_name = file.path(folder_root, folder_out, name_netcdf),
                            lat = latitude, lon = longitude)
      }
    }
  }
}
