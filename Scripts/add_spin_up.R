# Function that adds a spin-up period to a folder

# # Test
# folder = the_folder
# spin_up_years = 3L


add_spin_up = function(folder, spin_up_years = 0L){
  
  if(!is.integer(spin_up_years)){
    stop("add_spin_up function can only run with an integer number of years. E.g. '3L'")
  }
  
  ### Meteo file
  df_meteo = fread(file.path(folder, "meteo.csv"))
  
  # Get row numbers that are first three years
  ind = max(df_meteo[, which(datetime < (df_meteo[1L, datetime] + years(spin_up_years)))])
  
  # Place in front
  df_meteo = df_meteo[c(1:ind, 1:.N)]
  
  # Subtract three years
  df_meteo[1:ind, datetime := datetime - years(spin_up_years)]
  
  df_meteo[, datetime := format(datetime, "%Y-%m-%d %H:%M:%S")]
  fwrite(df_meteo, file.path(folder, "meteo.csv"))
  
  ### Configuration file
  input_yaml_multiple(file.path(folder, "LakeEnsemblR.yaml"),
                      key1 = "time", key2 = "start",
                      value = df_meteo[1L, datetime],
                      verbose = F)
  
  
  # (if inflow will be part of ISIMIP3, then this will be needed as well)
}
