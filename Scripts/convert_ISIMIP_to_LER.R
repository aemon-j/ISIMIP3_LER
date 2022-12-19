# Convert ISIMIP files to LakeEnsemblR input files
# This function should be used in every folder that has a setup for LER.
# Important: only a single file for each variable must be present

# Update 2022-06-28: Now uses .txt files, as present on the ISIMIP portal
# Update 2022-12-19: Now uses a single .csv file. as with the updated ISIMIP3 forcings

convert_ISIMIP_to_LER = function(folder, rounding_dec = 10L){
  
  allFiles = list.files(folder)
  
  met_filename = list.files(folder, pattern = "\\d\\d\\d\\d.csv")
  if(length(met_filename) != 1L) stop("Cannot find ISIMIP meteo file in ", folder)
  
  df_meteo = fread(file.path(folder, met_filename))
  
  LER_vars = list(time = "datetime",
                  tas = "Air_Temperature_celsius",
                  sfcwind = "Ten_Meter_Elevation_Wind_Speed_meterPerSecond",
                  hurs = "Relative_Humidity_percent",
                  pr = "Precipitation_millimeterPerDay",
                  ps = "Surface_Level_Barometric_Pressure_pascal",
                  rsds = "Shortwave_Radiation_Downwelling_wattPerMeterSquared",
                  rlds = "Longwave_Radiation_Downwelling_wattPerMeterSquared")
  
  cols_to_keep = names(df_meteo) %in% names(LER_vars)
  df_meteo = df_meteo[, ..cols_to_keep]
  
  # Round (not time or pr)
  round_cols = names(df_meteo)[!(names(df_meteo) %in% c("time", "pr"))]
  df_meteo[, (round_cols) := lapply(.SD, function(x) round(x, rounding_dec)), .SDcols = round_cols]
  
  # Set to LER names
  setnames(df_meteo, old = names(LER_vars), new = unlist(LER_vars))
  
  ### Unit conversions
  # Air temperature: Kelvin to degC
  df_meteo[, Air_Temperature_celsius := Air_Temperature_celsius - 273.15]
  # For some reason we need to round again
  df_meteo[, Air_Temperature_celsius := round(Air_Temperature_celsius, rounding_dec)]
  
  # Precipitation: kg/m2/s (i.e. mm/s) to millimetre per day
  df_meteo[, Precipitation_millimeterPerDay := Precipitation_millimeterPerDay * 86400]
  df_meteo[, Precipitation_millimeterPerDay := round(Precipitation_millimeterPerDay, rounding_dec)]
  
  df_meteo[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  
  ### Write file
  fwrite(df_meteo, file.path(folder, "meteo.csv"))
}
