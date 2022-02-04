# Convert ISIMIP files to LakeEnsemblR input files
# This function should be used in every folder that has a setup for LER.
# Important: only a single file for each variable must be present

# # Test:
# folder = "C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Allequash_Lake/hadgem2-es/rcp26"
# rounding_dec = 4L

convert_ISIMIP_to_LER = function(folder, rounding_dec = 10L){
  
  allFiles = list.files(folder)
  
  df_meteo = data.table(time = as.POSIXct(NA))
  df_meteo = df_meteo[-1L]
  
  ### Read files from ISIMIP ncdfs into data.tables
  # list(ISIMIP_nc_name = LakeEnsemblR_name)
  LER_vars = list(tas = "Air_Temperature_celsius",
                  sfcWind = "Ten_Meter_Elevation_Wind_Speed_meterPerSecond",
                  hurs = "Relative_Humidity_percent",
                  pr = "Precipitation_millimeterPerDay",
                  ps = "Surface_Level_Barometric_Pressure_pascal",
                  rsds = "Shortwave_Radiation_Downwelling_wattPerMeterSquared",
                  rlds = "Longwave_Radiation_Downwelling_wattPerMeterSquared")
  
  for(i in names(LER_vars)){
    file = allFiles[grepl(paste0(i, "_"), allFiles)]
    
    if(length(file) > 1L){
      stop("More than one file for ", i, " in folder ", folder, "!")
    }
    
    df = get_var_from_nc(file.path(folder, file), i)
    
    # Rounding (limit file size)
    if(i != "pr"){
      df[, var1 := round(var1, rounding_dec)]
    }
    
    # LER naming
    setnames(df, "var1", LER_vars[[i]])
    
    # Assign to a separate data.table
    assign(paste0("df_", i), df)
  }
  
  ### Unit conversions
  # Air temperature: Kelvin to degC
  df_tas[, Air_Temperature_celsius := Air_Temperature_celsius - 273.15]
  # For some reason we need to round again
  df_tas[, Air_Temperature_celsius := round(Air_Temperature_celsius, rounding_dec)]
  
  # Precipitation: kg/m2/s (i.e. mm/s) to millimetre per day
  df_pr[, Precipitation_millimeterPerDay := Precipitation_millimeterPerDay * 86400]
  df_pr[, Precipitation_millimeterPerDay := round(Precipitation_millimeterPerDay, rounding_dec)]
  
  ### Compile into single file
  df_meteo = Reduce(function(x, y) merge(x, y, by = "time", all = T), list(df_meteo,
                                                                           df_tas,
                                                                           df_sfcWind,
                                                                           df_hurs,
                                                                           df_pr,
                                                                           df_ps,
                                                                           df_rsds,
                                                                           df_rlds))
  
  setnames(df_meteo, "time", "datetime")
  df_meteo[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  
  ### Write file
  fwrite(df_meteo, file.path(folder, "meteo.csv"))
}

