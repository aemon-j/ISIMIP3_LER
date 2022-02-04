# Get output resolution (in m) based on max depth.
# This is also used to set the layer thickness for GOTM and Simstrat

get_output_resolution = function(max_depth){
  fcase(max_depth <= 2, 0.25,
        max_depth > 2 & max_depth <= 20, 0.5,
        max_depth > 20 & max_depth <= 50, 1.0,
        max_depth > 50 & max_depth <= 100, 2.0,
        max_depth > 100 & max_depth <= 300, 5.0,
        max_depth > 300, 10.0)
  
}
