# Function that adds a spin-up period to a folder

# # Test
# folder = the_folder
# spin_up_years = 3L


add_spin_up = function(folder, spin_up_years = 0L){
  
  if(!is.integer(spin_up_years)){
    stop("add_spin_up function can only run with an integer number of years. E.g. '3L'")
  }
  
  the_start_date = get_yaml_multiple(file.path(folder, "LakeEnsemblR.yaml"),
                                     key1 = "time", key2 = "start")
  the_start_date = as.POSIXct(the_start_date, format = "%Y-%m-%d%H:%M:%S")
  
  ### Meteo file
  df_meteo = fread(file.path(folder, "meteo.csv"))
  
  met_time_step = LakeEnsemblR:::get_meteo_time_step(file.path(folder, "meteo.csv")) # in sec
  
  # Cut to start on the_start_date and repeat the first spin_up_years years
  df_meteo = df_meteo[datetime >= the_start_date]
  ind = df_meteo[datetime < (the_start_date + years(spin_up_years)), .N]
  
  # Place in front
  df_meteo = df_meteo[c(1:ind, 1:.N)]
  
  # Subtract the years
  df_meteo[1:ind, datetime := datetime - years(spin_up_years)]
  
  # Deal with leap years: remove generated NAs and fill gaps with date before
  df_meteo = df_meteo[!is.na(datetime)]
  df_meteo = merge.data.table(df_meteo,
                              list("datetime" = seq.POSIXt(from = df_meteo[1L, datetime],
                                              to = df_meteo[.N, datetime],
                                              by = met_time_step)),
                              by = "datetime",
                              all.y = TRUE)
  setnafill(df_meteo, type = "locf")
  setnafill(df_meteo, type = "nocb") # Precaution if starting date is a leap date
  
  df_meteo[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  fwrite(df_meteo, file.path(folder, "meteo.csv"))
  
  ### Configuration file
  input_yaml_multiple(file.path(folder, "LakeEnsemblR.yaml"),
                      key1 = "time", key2 = "start",
                      value = df_meteo[1L, datetime],
                      verbose = F)
  
  # (if inflow will be part of ISIMIP3, then this will need updating as well)
}
