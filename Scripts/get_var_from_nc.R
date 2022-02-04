# Function to get a variable from a ncdf file. Returns a data.table
# Code based on gotmtools::get_vari


get_var_from_nc = function(ncdf, var, incl_time = TRUE){
  
  on.exit({
    nc_close(nc_file)
  })
  
  nc_file = nc_open(ncdf)
  
  if(incl_time){
    tim = ncvar_get(nc_file, "time")
    tunits = ncatt_get(nc_file, "time")
    tustr = strsplit(tunits$units, " ")
    step = tustr[[1]][1]
    tdstr = strsplit(unlist(tustr)[3], "-")
    tmonth = as.integer(unlist(tdstr)[2])
    tday = as.integer(unlist(tdstr)[3])
    tyear = as.integer(unlist(tdstr)[1])
    tdstr = strsplit(unlist(tustr)[4], ":")
    thour = as.integer(unlist(tdstr)[1])
    tmin = as.integer(unlist(tdstr)[2])
    origin = as.POSIXct(paste0(tyear, "-", tmonth,
                               "-", tday, " ", thour, ":", tmin),
                        format = "%Y-%m-%d %H:%M", tz = "UTC")
    
    tim_multipl = fcase(step == "days", 60 * 60 * 24,
                        step == "hours", 60 * 60,
                        step == "minutes", 60,
                        default = 1)
    
    tim = tim * tim_multipl
    
    time = as.POSIXct(tim, origin = origin, tz = "UTC")
  }
  
  
  var1 = ncvar_get(nc_file, var)
  tunits = ncatt_get(nc_file, var)
  
  dims = dim(var1)
  if(length(dims) == 2L){
    flag = which(dim(var1) == length(time))
    if(flag == 2L){
      var1 = as.data.table(t(var1))
    }else{
      var1 = as.data.table(var1)
    }
    var1 = var1[, ncol(var1):1L]
    if(incl_time){
      var1[, Datetime := time]
      var1 = var1[, c(ncol(var1), 1L:(ncol(var1) - 1L))]
    }
  }else if(length(dims) == 1L){
    if(incl_time){
      var1 = data.table(time, var1)
    }
  }
  
  return(var1)
}
