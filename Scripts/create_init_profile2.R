# Function to create an (LER-format) initial temperature profile data.table that is calculated
# from observations. 

# Arguments:
# folder; path to a folder with _temp_ .csv files
# start_date: in POSIXct or character. 
# margin_time: period-class. This margin will be taken around the start yday 

# We take 2001 as "standard" to calculate DOY, as it's not a leap year

create_init_profile2 = function(df_obs, start_date = "2001-01-01", margin_time = months(1),
                                max_depths = 20L, round_dec = 2L){
  
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
  
  # Limit the number of depths in the initial profile
  if(length(unique(df_obs$Depth_meter)) > max_depths){
    the_unique_depths = unique(df_obs$Depth_meter)
    the_unique_depths = the_unique_depths[order(the_unique_depths)]
    
    new_depths = seq(min(the_unique_depths), max(the_unique_depths), length.out = max_depths)
    
    # Code partially from https://stackoverflow.com/questions/12861061/round-to-nearest-arbitrary-number-from-list
    # Round the_unique_depths to new_depths
    low = findInterval(df_obs$Depth_meter, new_depths)
    high = low + 1
    low_diff = df_obs$Depth_meter - new_depths[ifelse(low == 0, NA, low)]
    high_diff = new_depths[ifelse(high == 0, NA, high)] - df_obs$Depth_meter
    mins = pmin(low_diff, high_diff, na.rm = T) 
    pick = ifelse(!is.na(low_diff) & mins == low_diff, low, high)
    df_obs[, Depth_meter := round(new_depths[pick], round_dec)]
    df_obs = df_obs[complete.cases(df_obs)]
  }
  
  # Create average profile and put in LER format
  df_av_prof = df_obs[, round(mean(Water_Temperature_celsius, na.rm = T), round_dec),
                      by = Depth_meter]
  setnames(df_av_prof, old = "V1", new = "Water_Temperature_celsius")
  setorder(df_av_prof, Depth_meter)
  
  df_av_prof
}

