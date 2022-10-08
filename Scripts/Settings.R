##### ISIMIP settings -----

gcms = c("GFDL-ESM4", "IPSL-CM6A-LR", "MPI-ESM1-2-HR", "MRI-ESM2-0", "UKESM1-0-LL")
calib_gcm = "GSWP3-W5E5"
scens = c("historical", "picontrol", "ssp126", "ssp370", "ssp585", "calibration")
lakes = c("Allequash-Lake", "Alqueva", "Annecy", "Annie", "Argyle", "Biel", 
          "Big-Muskellunge-Lake", "Black-Oak-Lake", "Bourget", "Burley-Griffin", 
          "Crystal-Bog", "Crystal-Lake", "Delavan", "Dickie-Lake", "Eagle-Lake", 
          "Ekoln-basin-of-Malaren", "Erken", "Esthwaite-Water", "Falling-Creek-Reservoir", 
          "Feeagh", "Fish-Lake", "Geneva", "Great-Pond", "Green-Lake", 
          "Harp-Lake", "Kilpisjarvi", "Kinneret", "Kivu", "Klicava", "Kuivajarvi", 
          "Langtjern", "Laramie-Lake", "Lower-Zurich", "Mendota", "Monona", 
          "Mozaisk", "Mt-Bold", "Mueggelsee", "Neuchatel", "Nohipalo-Mustjarv", 
          "Nohipalo-Valgejarv", "Okauchee-Lake", "Paajarvi", "Rappbode-Reservoir", 
          "Rimov", "Rotorua", "Sammamish", "Sau-Reservoir", "Sparkling-Lake", 
          "Stechlin", "Sunapee", "Tahoe", "Tarawera", "Toolik-Lake", "Trout-Bog", 
          "Trout-Lake", "Two-Sisters-Lake", "Washington", "Vendyurskoe", 
          "Windermere", "Wingra", "Vortsjarv", "Zlutice")
models_to_run = c("FLake", "GLM", "GOTM", "Simstrat")


##### Folder set-up settings -----

# Length of spin-up period, in years. Must be an integer, so the "L" must be present! 
# Spin-up period used for all simulations, including the calibration
spin_up_period = 0L

##### Report settings -----

report_name = "Test"


##### Calibration settings -----

frac_of_cores = 0.75 # Fraction of available cores to use, rounded up. 
cal_iterations = 150
cmethod = "LHC" # Calibration method to use, see ?cali_ensemble

#### IMPORTANT!!!!!
#### THE PARAMETERS TO CALIBRATE AND THEIR RANGES SHOULD BE SET IN THE "LakeEnsemblR.yaml" FILE
#### IN THE file.path(folder_root, folder_template_LER) FOLDER!!!!!!!!!!
#### CHANGE THE SETTINGS IN THE CALIBRATION SECTION. 
