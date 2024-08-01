##### ISIMIP settings -----

gcms = c("GFDL-ESM4", "IPSL-CM6A-LR", "MPI-ESM1-2-HR", "MRI-ESM2-0", "UKESM1-0-LL")
calib_gcm = "GSWP3-W5E5"
scens = c("historical", "picontrol", "ssp126", "ssp370", "ssp585", "calibration")

## if you want to run different lakes with different spin up periods the must be run one at a time and
## you need to change this file inbetween
# all lakes
# lakes = c("Allequash", "Alqueva", "Annie", "Arendsee", "Argyle", "Biel",
#           "BigMuskellunge", "BlackOak", "Bosumtwi", "Bryrup", "BurleyGriffin",
#           "Chao", "Crystal", "CrystalBog", "Delavan", "Dickie", "Eagle",
#           "Ekoln", "Erken", "EsthwaiteWater", "FallingCreek", "Feeagh",
#           "Fish", "GreatPond", "Green", "Harp", "Hassel", "Hulun", "Kilpisjarvi",
#           "Kinneret", "Kivu", "Klicava", "Kuivajarvi", "Langtjern", "Laramie",
#           "LowerLakeZurich", "Mendota", "Monona", "Mozhaysk", "MtBold",
#           "Muggelsee", "Murten", "Neuchatel", "Ngoring", "NohipaloMustjarv",
#           "NohipaloValgejarv", "Okauchee", "Paajarvi", "Rappbode", "Rappbodep",
#           "Rimov", "Rotorua", "Sammamish", "Sau", "Scharmutzel", "Sparkling",
#           "Stechlin", "Sunapee", "Tahoe", "Taihu", "Tarawera", "Thun",
#           "Toolik", "Trout", "TroutBog", "TwoSisters", "Vendyurskoe", "Vortsjarv",
#           "Washington", "Windermere", "Wingra", "Zlutice", "Zurich")

# lakes without Tahoe and Kivu
lakes = c("Allequash", "Alqueva", "Annie", "Arendsee", "Argyle", "Biel",
          "BigMuskellunge", "BlackOak", "Bosumtwi", "Bryrup", "BurleyGriffin",
          "Chao", "Crystal", "CrystalBog", "Delavan", "Dickie", "Eagle",
          "Ekoln", "Erken", "EsthwaiteWater", "FallingCreek", "Feeagh",
          "Fish", "GreatPond", "Green", "Harp", "Hassel", "Hulun", "Kilpisjarvi",
          "Kinneret", "Klicava", "Kuivajarvi", "Langtjern", "Laramie",
          "LowerLakeZurich", "Mendota", "Monona", "Mozhaysk", "MtBold",
          "Muggelsee", "Murten", "Neuchatel", "Ngoring", "NohipaloMustjarv",
          "NohipaloValgejarv", "Okauchee", "Paajarvi", "Rappbode", "Rappbodep",
          "Rimov", "Rotorua", "Sammamish", "Sau", "Scharmutzel", "Sparkling",
          "Stechlin", "Sunapee", "Taihu", "Tarawera", "Thun",
          "Toolik", "Trout", "TroutBog", "TwoSisters", "Vendyurskoe", "Vortsjarv",
          "Washington", "Windermere", "Wingra", "Zlutice", "Zurich")

#lakes =  "Kivu" #"Tahoe"#
 
models_to_run = c("FLake", "GLM", "GOTM", "Simstrat")


calib_type = "standard" # "standard" or "cal_project"

##### Folder set-up settings -----

# Length of spin-up period, in years. Must be an integer, so the "L" must be present! 
# Spin-up period used for all simulations, including the calibration
spin_up_period = 1L#5L#1L#30L#   ## change for Tahoe or Kivu

# Maximum number of depths to include in the initial temperature profile
max_depths_init_prof = 20L

##### Report settings -----

report_name = "Test"


##### Calibration settings -----

frac_of_cores = 1.0 # Fraction of available cores to use, rounded up. 
cal_iterations = 2000
cmethod = "LHC" # Calibration method to use, see ?cali_ensemble

# cal_project only:
max_duration_run = 10 # years

#### IMPORTANT!!!!!
#### THE PARAMETERS TO CALIBRATE AND THEIR RANGES SHOULD BE SET IN THE "LakeEnsemblR.yaml" FILE
#### IN THE file.path(folder_root, folder_template_LER) FOLDER!!!!!!!!!!
#### CHANGE THE SETTINGS IN THE CALIBRATION SECTION. 
