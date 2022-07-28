# Calculate density from temperature using the formula (Millero & Poisson, 1981):
# this is the method stated in the isimip 2b protocol in July 2019

temp_to_dens = function(t){
  999.842594 + (6.793952e-2 * t) - (9.095290e-3 * t^2) +
    (1.001685e-4 * t^3) - (1.120083e-6 * t^4) + (6.536336e-9 * t^5)
}
