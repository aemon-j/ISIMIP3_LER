# Function to write a single ISIMIP netcdf file, based on the inputs given
# Based on LakeEnsemblR's create_netcdf_output function

# Default settings are in line with instructions for ISIMIP3b on:
# https://protocol.isimip.org/#reporting-model-results

write_isimip_netcdf = function(vals, time, deps = NULL, var_name, var_unit,
                                  file_name, lat, lon,
                                  ref_year = "1601", compression = 5L){
  
  ref_time = as.POSIXct(paste0(ref_year, "-01-01 00:00:00"), tz = "UTC")
  ndays = as.numeric(difftime(time, ref_time, units = "days"))
  
  # Define lon and lat dimensions
  lon1 = ncdim_def("lon", "degrees_east", vals = as.double(ifelse(longitude >= 0, longitude, longitude + 360)))
  lat2 = ncdim_def("lat", "degrees_north", vals = as.double(lat))
  
  # Time dimension
  timedim = ncdf4::ncdim_def("time", units = paste0("days since ", ref_year, "-01-01 00:00:00"),
                             vals = as.double(ndays), calendar = "proleptic_gregorian")
  
  # Depth dimension (positive numbers below surface)
  if(!is.null(deps)){
    depthdim = ncdim_def("levlak", units = "meters", vals = as.double((-deps)),
                         longname = "Depth from surface")
  }
  
  # What to do with NA data?
  fillvalue = 1e20
  missvalue = 1e20
  
  # Define variable
  if(is.null(ncol(vals)) & is.null(deps)){
    nc_var = ncvar_def(var_name, var_unit,
                       list(lon1, lat2, timedim),
                       fillvalue, var_name,
                       prec = "float", compression = compression, shuffle = FALSE)
  }else{
    nc_var = ncvar_def(var_name, var_unit,
                       list(lon1, lat2, depthdim, timedim),
                       fillvalue, var_name,
                       prec = "float", compression = compression, shuffle = FALSE)
  }
  
  # If file exists - delete it
  if(file.exists(file_name)) {
    unlink(file_name, recursive = TRUE)
  }
  
  # Create and input data into the netCDF file
  ncout = nc_create(file_name, list(var_name = nc_var), force_v4 = T)
  
  # Add tryCatch ensure that it closes netCDF file
  result = tryCatch({
    if(is.null(ncol(vals)) & is.null(deps)){
      # Add 1D variable
      ncvar_put(ncout, nc_var, vals)
      ncatt_put(ncout, nc_var, attname = "coordinates",
                attval = c("lon lat"))
      ncvar_change_missval(ncout, nc_var, missval = fillvalue)
    }else{
      # Add 2D variable
      ncvar_put(nc = ncout, varid = nc_var, vals = vals)
      ncatt_put(ncout, "levlak", attname = "coordinates", attval = c("levlak"))
      ncatt_put(ncout, nc_var, attname = "coordinates",
                attval = c("lon lat levlak"))
      ncvar_change_missval(ncout, nc_var, missval = fillvalue)
      
    }
  }, warning = function(w){
    return_val = "Warning"
  }, error = function(e){
    return_val = "Error"
    warning("Error creating netCDF file!")
  }, finally = {
    nc_close(ncout) # Close netCDF file
  })
}
