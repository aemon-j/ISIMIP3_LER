# Function to create an (LER-format) initial temperature profile data.table that is calculated
# from observations. 

# Arguments:
# folder; path to a folder with _temp_ .csv files
# start_date: in POSIXct or character. 
# margin_time: period-class. This margin will be taken around the start yday 

# We take 2001 as "standard" to calculate DOY, as it's not a leap year

# Update 2021-09-01: changed input from a directory to a df_obs
#                    df_obs is assumed to be a data.table, and is created in 1_Set_up_LER_folders


# folder = "C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Annie"
# start_date = "2006-01-01 00:00:00"
# margin_time = months(1)

create_init_profile2 = function(df_obs, start_date = "2001-01-01", margin_time = months(1)){
  
  if(margin_time > months(6)){
    stop("margin_time cannot be larger than six months!")
  }
  
  # Keep the times around the DOY of the start date
  start_date = as.POSIXct(start_date)
  year(start_date) = 2001 # Set to non leap year
  mindate = start_date - margin_time
  maxdate = start_date + margin_time
  minDOY = yday(mindate)
  maxDOY = yday(maxdate)
  
  diffyear = diff(c(year(mindate), year(maxdate)))
  
  if(diffyear == 0){
    df_obs = df_obs[yday(datetime) >= minDOY & yday(datetime) <= maxDOY]
  }else if(diffyear == 1){
    df_obs = df_obs[yday(datetime) >= minDOY | yday(datetime) <= maxDOY]
  }
  
  # Create average profile and put in LER format
  df_av_prof = df_obs[, mean(Water_Temperature_celsius, na.rm = T), by = Depth_meter]
  setnames(df_av_prof, old = "V1", new = "Water_Temperature_celsius")
  setorder(df_av_prof, Depth_meter)
  
  df_av_prof
}

