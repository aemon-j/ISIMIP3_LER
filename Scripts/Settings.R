##### ISIMIP settings -----

gcms = c("GFDL-ESM4", "IPSL-CM6A-LR", "MPI-ESM1-2-HR", "MRI-ESM2-0", "UKESM1-0-LL")
calib_gcm = "GSWP3-W5E5"
scens = c("historical", "picontrol", "ssp126", "ssp370", "ssp585", "calibration")
lakes = c("Allequash", "Alqueva", "Annie", "Arendsee", "Argyle", "Biel", 
          "BigMuskellunge", "BlackOak", "Bosumtwi", "Bryrup", "BurleyGriffin", 
          "Chao", "Crystal", "CrystalBog", "Delavan", "Dickie", "Eagle", 
          "Ekoln", "Erken", "EsthwaiteWater", "FallingCreek", "Feeagh", 
          "Fish", "GreatPond", "Green", "Harp", "Hassel", "Hulun", "Kilpisjarvi", 
          "Kinneret", "Kivu", "Klicava", "Kuivajarvi", "Langtjern", "Laramie", 
          "LowerLakeZurich", "Mendota", "Monona", "Mozhaysk", "MtBold", 
          "Muggelsee", "Murten", "Neuchatel", "Ngoring", "NohipaloMustjarv", 
          "NohipaloValgejarv", "Okauchee", "Paajarvi", "Rappbode", "Rappbodep", 
          "Rimov", "Rotorua", "Sammamish", "Sau", "Scharmutzel", "Sparkling", 
          "Stechlin", "Sunapee", "Tahoe", "Taihu", "Tarawera", "Thun", 
          "Toolik", "Trout", "TroutBog", "TwoSisters", "Vendyurskoe", "Vortsjarv", 
          "Washington", "Windermere", "Wingra", "Zlutice", "Zurich")
models_to_run = c("FLake", "GLM", "GOTM", "Simstrat")


##### Folder set-up settings -----

# Length of spin-up period, in years. Must be an integer, so the "L" must be present! 
# Spin-up period used for all simulations, including the calibration
spin_up_period = 0L

##### Report settings -----

report_name = "Test"


##### Calibration settings -----

frac_of_cores = 1.0 # Fraction of available cores to use, rounded up. 
cal_iterations = 2000
cmethod = "LHC" # Calibration method to use, see ?cali_ensemble

#### IMPORTANT!!!!!
#### THE PARAMETERS TO CALIBRATE AND THEIR RANGES SHOULD BE SET IN THE "LakeEnsemblR.yaml" FILE
#### IN THE file.path(folder_root, folder_template_LER) FOLDER!!!!!!!!!!
#### CHANGE THE SETTINGS IN THE CALIBRATION SECTION. 
