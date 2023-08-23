# Function to write a single ISIMIP netcdf file, based on the inputs given
# Based on LakeEnsemblR's create_netcdf_output function

# Default settings are in line with instructions for ISIMIP3b on:
# https://protocol.isimip.org/#reporting-model-results

write_isimip_netcdf = function(vals, time, deps = NULL, var_name, var_unit,
                               var_longname,
                               file_name, lat, lon,
                               ref_year = "1601", compression = 5L){
  
  ref_time = as.POSIXct(paste0(ref_year, "-01-01 00:00:00"), tz = "UTC")
  ndays = as.numeric(difftime(time, ref_time, units = "days"))
  
  # Define lon and lat dimensions
  lon1 = ncdim_def("lon", "degrees_east", vals = as.double(ifelse(longitude >= 0, longitude, longitude + 360)),
                   longname = "Longitude")
  lat2 = ncdim_def("lat", "degrees_north", vals = as.double(lat), longname = "Latitude")
  
  # Time dimension
  timedim = ncdim_def("time", units = paste0("days since ", ref_year, "-01-01 00:00:00"),
                      vals = as.double(ndays), calendar = "proleptic_gregorian",
                      unlim = T)
  
  # Levlak (positive numbers below surface) and depth-bounds dimensions
  if(!is.null(deps)){
    levlakdim = ncdim_def("levlak", units = "-", vals = as.numeric(seq_along(deps)),
                          longname = "Vertical Water Layer Index")
    bndsdim = ncdim_def("bnds", units = "", vals = c(0, 1),
                        longname = "")
  }
  
  # What to do with NA data?
  fillvalue = 1e20
  missvalue = 1e20
  
  # Define variable
  if(is.null(ncol(vals)) & is.null(deps)){
    nc_var = ncvar_def(var_name, var_unit,
                       list(lon1, lat2, timedim),
                       fillvalue, var_longname,
                       prec = "float", compression = compression, shuffle = FALSE)
  }else{
    nc_var = ncvar_def(var_name, var_unit,
                       list(lon1, lat2, levlakdim, timedim),
                       fillvalue, var_longname,
                       prec = "float", compression = compression, shuffle = FALSE)
    depth_var = ncvar_def("depth", "m",
                          list(levlakdim),
                          missval = NULL,
                          longname = "Depth of Vertical Layer Center Below Surface",
                          prec = "float", compression = compression, shuffle = FALSE)
    depthbnd_var = ncvar_def("depth_bnds", "m",
                             list(bndsdim, levlakdim),
                             missval = NULL,
                             longname = "Depth of Layer's Top and Bottom Below Surface",
                             prec = "float", compression = compression, shuffle = FALSE)
  }
  
  # If file exists - delete it
  if(file.exists(file_name)) {
    unlink(file_name, recursive = TRUE)
  }
  
  # Create and input data into the netCDF file
  if(is.null(ncol(vals)) & is.null(deps)){
    ncout = nc_create(file_name, list(var_name = nc_var), force_v4 = T)
  }else{
    ncout = nc_create(file_name, list(depth = depth_var,
                                      depth_bnds = depthbnd_var,
                                      var_name = nc_var), force_v4 = T)
  }
  
  # # Change format to netcdf4-classic
  # ncout$format = "NC_FORMAT_NETCDF4_CLASSIC"
  # ncdf4:::ncdf4_format(ncout$id)
  # .Call( "R_nc4_inq_format", as.integer(ncout$id), as.integer(-1), PACKAGE="ncdf4")
  
  # Add Global attributes
  ncatt_put(ncout, varid = 0, attname = "contact", attval = "Jorrit Mesman <jorrit.mesman@ebc.uu.se>")
  ncatt_put(ncout, varid = 0, attname = "institution", attval = "Uppsala University (UU); Technische Universitaet Dresden (TUD)")
  ncatt_put(ncout, varid = 0, attname = "comment", attval = "Data prepared for ISIMIP3b")
  
  # Add standard name to the variable
  ncatt_put(ncout, varid = var_name, attname = "standard_name", attval = var_name)
  
  # Add standard names and axis names to the dimensions
  ncatt_put(ncout, varid = "lon", attname = "standard_name", attval = "longitude")
  ncatt_put(ncout, varid = "lon", attname = "axis", attval = "X")
  ncatt_put(ncout, varid = "lat", attname = "standard_name", attval = "latitude")
  ncatt_put(ncout, varid = "lat", attname = "axis", attval = "Y")
  ncatt_put(ncout, varid = "time", attname = "standard_name", attval = "time")
  ncatt_put(ncout, varid = "time", attname = "axis", attval = "T")
  
  if(!is.null(deps)){
    ncatt_put(ncout, varid = "levlak", attname = "standard_name", attval = "water_layer")
    ncatt_put(ncout, varid = "levlak", attname = "positive", attval = "down")
    ncatt_put(ncout, varid = "levlak", attname = "axis", attval = "Z")
    
    ncatt_put(ncout, varid = "bnds", attname = "positive", attval = "down")
    
    # Compute depth-bounds matrix
    bnd_step = (deps[1] - deps[2]) / 2
    max_depth = max(abs(deps))
    the_bnds = 1
    upr_bnds = abs(deps) - bnd_step
    lwr_bnds = abs(deps) + bnd_step
    upr_bnds[upr_bnds < 0] = 0
    lwr_bnds[lwr_bnds > max_depth] = max_depth
    bnd_mtr = rbind(upr_bnds, lwr_bnds)
  }
  
  # Add tryCatch ensure that it closes netCDF file
  result = tryCatch({
    if(is.null(ncol(vals)) & is.null(deps)){
      # Add 1D variable
      ncvar_put(ncout, nc_var, vals)
      # ncatt_put(ncout, nc_var, attname = "coordinates",
      #           attval = c("lon lat"))
      ncvar_change_missval(ncout, nc_var, missval = fillvalue)
    }else{
      # Add 2D variable
      ncvar_put(nc = ncout, varid = depth_var, vals = as.double(-deps))
      ncvar_put(nc = ncout, varid = depthbnd_var, vals = bnd_mtr)
      ncvar_put(nc = ncout, varid = nc_var, vals = vals)
      
      ncatt_put(ncout, "depth", attname = "standard_name", attval = "depth")
      ncatt_put(ncout, "depth", attname = "positive", attval = "down")
      ncatt_put(ncout, "depth", attname = "axis", attval = "Z")
      
      ncatt_put(ncout, "depth_bnds", attname = "standard_name", attval = "depth_bounds")
      ncatt_put(ncout, "depth_bnds", attname = "positive", attval = "down")
      ncatt_put(ncout, "depth_bnds", attname = "comment",
                attval = "bnds=0 for the top of the layer, and bnds=1 for the bottom of the layer")
      
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
