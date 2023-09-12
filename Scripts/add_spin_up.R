# Function that adds a spin-up period to a folder

# # Test
# folder = the_folder
# spin_up_years = 3L
# spin_up_source = "recycle"

# Update 2023-03: if spin_up_source is anything other than "recycle",
#                 the full length of the met file will be used 
#                 (avoids issues during calibration if run time is shorter
#                 than spin-up time).
# Update 2023-09: add option `use_historical_for_future` to use the last period
#                 of the "historical" meteorology for the future climate scenario.
#                 If TRUE, will check the `scenario` argument, and if it a future
#                 scenario, will read the historical met file to create the
#                 spin-up. Only works if `spin_up_source` == "recycle"

add_spin_up = function(folder, spin_up_years = 0L, spin_up_source = "recycle",
                       use_historical_for_future = FALSE, scenario = ""){
  
  if(!is.integer(spin_up_years)){
    stop("add_spin_up function can only run with an integer number of years. E.g. '3L'")
  }
  
  the_start_date = get_yaml_multiple(file.path(folder, "LakeEnsemblR.yaml"),
                                     key1 = "time", key2 = "start")
  the_start_date = as.POSIXct(the_start_date, format = "%Y-%m-%d%H:%M:%S")
  
  if(spin_up_source == "recycle"){
    ### Meteo file
    df_meteo = fread(file.path(folder, "meteo.csv"))
    
    met_time_step = LakeEnsemblR:::get_meteo_time_step(file.path(folder, "meteo.csv")) # in sec
    
    # Cut to start on the_start_date
    df_meteo = df_meteo[datetime >= the_start_date]
    
    if(use_historical_for_future & grepl("ssp", scenario)){
      # Place last years of historical period in front
      df_meteo_hist = fread(file.path(folder, "../historical/meteo.csv"))
      
      df_meteo = rbindlist(list(df_meteo_hist[datetime >= the_start_date - years(spin_up_years)],
                                df_meteo))
    }else{
      # Repeat the first spin_up_years years
      ind = df_meteo[datetime < (the_start_date + years(spin_up_years)), .N]
      
      # Place in front
      df_meteo = df_meteo[c(1:ind, 1:.N)]
      
      # Subtract the years
      df_meteo[1:ind, datetime := datetime - years(spin_up_years)]
    }
    
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
    
    new_start_date = df_meteo[1L, datetime]
  }else{
    new_start_date = format(the_start_date - years(spin_up_years), "%Y-%m-%d %H:%M:%S")
  }
  
  ### Configuration file
  input_yaml_multiple(file.path(folder, "LakeEnsemblR.yaml"),
                      key1 = "time", key2 = "start",
                      value = new_start_date,
                      verbose = F)
  
  # (if inflow will be part of ISIMIP3, then this will need updating as well)
}
