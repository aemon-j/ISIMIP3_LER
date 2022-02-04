# Function to compile subdaily temperature files

merge_temp_obs = function(vctr_obs, folder = "."){
  l_obs = lapply(vctr_obs, function(x) fread(file.path(folder, x)))
  
  rbindlist(l_obs)
}

