# Function to quickly get start and end date from an ISIMIP nc file

get_start_end_date = function(ncfile){
  
  nc = nc_open(ncfile)
  
  on.exit({
    nc_close(nc)
  })
  
  tim = ncvar_get(nc, "time")
  start_time = tim[1L]
  end_time = tim[length(tim)]
  tunits = ncatt_get(nc, "time")
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
  
  start_time = start_time * tim_multipl
  end_time = end_time * tim_multipl
  
  c(start = as.POSIXct(start_time, origin = origin, tz = "UTC"),
    end = as.POSIXct(end_time, origin = origin, tz = "UTC"))
}
