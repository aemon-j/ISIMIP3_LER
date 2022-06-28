##### ISIMIP settings -----

gcms = c("GFDL-ESM4", "IPSL-CM6A-LR", "MPI-ESM1-2-HR", "MRI-ESM2-0", "UKESM1-0-LL")
calib_gcm = "GSWP3-W5E5"
scens = c("historical", "piControl", "ssp126", "ssp370", "ssp585", "calibration")
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


##### Folder set-up settings -----

# Length of spin-up period, in years. Must be an integer, so the "L" must be present! 
# Spin-up period used for all simulations, including the calibration
spin_up_period = 0L

##### Report settings -----

report_name = "Test"


##### Calibration settings -----

frac_of_cores = 0.75 # Fraction of available cores to use, rounded up. 
cal_iterations = 1000
cmethod = "LHC" # Calibration method to use, see ?cali_ensemble

#### IMPORTANT!!!!!
#### THE PARAMETERS TO CALIBRATE AND THEIR RANGES SHOULD BE SET IN THE "LakeEnsemblR.yaml" FILE
#### IN THE file.path(folder_root, folder_template_LER) FOLDER!!!!!!!!!!
#### CHANGE THE SETTINGS IN THE CALIBRATION SECTION. 
