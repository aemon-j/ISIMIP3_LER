# Function to create an (LER-format) initial temperature profile data.table that is calculated
# from observations. 

# Arguments:
# folder; path to a folder with _temp_ .csv files
# start_date: in POSIXct or character. 
# margin_time: period-class. This margin will be taken around the start yday 

# We take 2001 as "standard" to calculate DOY, as it's not a leap year

source(file.path(folder_root, folder_scripts, "merge_temp_obs.R"))

# folder = "C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Annie"
# start_date = "2006-01-01 00:00:00"
# margin_time = months(1)

create_init_profile = function(folder = ".", start_date = "2001-01-01", margin_time = months(1)){
  
  if(margin_time > months(6)){
    stop("margin_time cannot be larger than six months!")
  }
  
  obs_files = list.files(folder)
  obs_files = obs_files[grepl("_temp_", obs_files)]
  
  if(any(grepl("_daily", obs_files))){
    obs_files = obs_files[grepl("_daily", obs_files)][1]
  }
  
  if(length(obs_files) > 1L){
    df_obs = merge_temp_obs(obs_files, folder = folder)
    df_obs = df_obs[, -(1:3)]
    strmatch = str_match(df_obs[, TIMESTAMP_END], "(\\d{4})(\\d{2})(\\d{2})(\\d{2})(\\d{2})")
    df_obs[, TIMESTAMP_END := paste0(strmatch[,2], "-", strmatch[,3], "-", strmatch[,4], " ",
                                     strmatch[,5], ":", strmatch[,6], ":00")]
    df_obs[, TIMESTAMP_END := as.POSIXct(TIMESTAMP_END)]
    # Calculate daily averages
    df_obs = df_obs[, .(WTEMP = mean(WTEMP)), by = .(ceiling_date(TIMESTAMP_END, unit = "days"),
                                                     DEPTH)]
  }else{
    df_obs = fread(file.path(folder, obs_files))
    df_obs = df_obs[, -(1:2)]
    strmatch = str_match(df_obs[, TIMESTAMP], "(\\d{4})(\\d{2})(\\d{2})")
    df_obs[, TIMESTAMP := paste0(strmatch[,2], "-", strmatch[,3], "-", strmatch[,4], " ",
                                 "00:00:00")]
    df_obs[, TIMESTAMP := as.POSIXct(TIMESTAMP)]
  }
  setnames(df_obs, c("datetime", "Depth_meter", "Water_Temperature_celsius"))
  
  # Now keep the times around the DOY of the start date
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
  df_av_prof = df_obs[, mean(Water_Temperature_celsius), by = Depth_meter]
  setnames(df_av_prof, old = "V1", new = "Water_Temperature_celsius")
  
  df_av_prof
}

