# Make vectors to loop over for all ISIMIPs settings



gcms = c("GFDL-ESM2M", "HadGEM2-ES", "IPSL-CM5A-LR", "MIROC5", "EWEMBI")
scens = c("historical", "piControl", "rcp26", "rcp60", "rcp85", "calibration")
lakes = c("Allequash_Lake", "Alqueva", "Annecy", "Annie", "Argyle", "Biel", 
          "Big_Muskellunge_Lake", "Black_Oak_Lake", "Bourget", "Burley_Griffin", 
          "Crystal_Bog", "Crystal_Lake", "Delavan", "Dickie_Lake", "Eagle_Lake", 
          "Ekoln_basin_of_Malaren", "Erken", "Esthwaite_Water", "Falling_Creek_Reservoir", 
          "Feeagh", "Fish_Lake", "Geneva", "Great_Pond", "Green_Lake", 
          "Harp_Lake", "Kilpisjarvi", "Kinneret", "Kivu", "Klicava", "Kuivajarvi", 
          "Langtjern", "Laramie_Lake", "Lower_Zurich", "Mendota", "Monona", 
          "Mozaisk", "Mt_Bold", "Mueggelsee", "Neuchatel", "Ngoring", "Nohipalo_Mustjarv", 
          "Nohipalo_Valgejarv", "Okauchee_Lake", "Paajarvi", "Rappbode_Reservoir", 
          "Rimov", "Rotorua", "Sammamish", "Sau_Reservoir", "Sparkling_Lake", 
          "Stechlin", "Sunapee", "Tahoe", "Tarawera", "Toolik_Lake", "Trout_Bog", 
          "Trout_Lake", "Two_Sisters_Lake", "Washington", "Vendyurskoe", 
          "Windermere", "Wingra", "Vortsjarv", "Zlutice")
models_to_run = c("FLake", "GLM", "GOTM", "Simstrat")

