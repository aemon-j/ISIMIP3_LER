# Convert ISIMIP files to LakeEnsemblR input files
# This function should be used in every folder that has a setup for LER.
# Important: only a single file for each variable must be present

# Update 2022-06-28: Now uses .txt files, as present on the ISIMIP portal

convert_ISIMIP_to_LER = function(folder, rounding_dec = 10L){
  
  allFiles = list.files(folder)
  
  df_meteo = data.table(datetime = as.POSIXct(NA))
  df_meteo = df_meteo[-1L]
  
  ### Read files from ISIMIP ncdfs into data.tables
  # list(ISIMIP_nc_name = LakeEnsemblR_name)
  LER_vars = list(tas = "Air_Temperature_celsius",
                  sfcwind = "Ten_Meter_Elevation_Wind_Speed_meterPerSecond",
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
    
    df = fread(file.path(folder, file))
    df[, V1 := as.POSIXct(V1)]
    # df = get_var_from_nc(file.path(folder, file), i)
    
    # Rounding (limit file size)
    if(i != "pr"){
      df[, V2 := round(V2, rounding_dec)]
    }
    
    # LER naming
    setnames(df, c("V1", "V2"), c("datetime", LER_vars[[i]]))
    
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
  df_meteo = Reduce(function(x, y) merge(x, y, by = "datetime", all = T), list(df_meteo,
                                                                           df_tas,
                                                                           df_sfcwind,
                                                                           df_hurs,
                                                                           df_pr,
                                                                           df_ps,
                                                                           df_rsds,
                                                                           df_rlds))
  
  df_meteo[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  
  ### Write file
  fwrite(df_meteo, file.path(folder, "meteo.csv"))
}
