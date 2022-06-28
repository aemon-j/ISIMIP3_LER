# This script initialises all the settings for the ISIMIP3-LakeEnsemblR project
# Folder_structure.R needs to be run before this script

# Working directory will always be the script folder
setwd(file.path(folder_root, folder_scripts))

source("Load_packages.R")
source("Settings.R")

# Load all functions
source("add_spin_up.R")
source("add_to_report.R")
source("convert_ISIMIP_to_LER.R")
source("create_init_profile2.R")
source("divide_tasks_over_cores.R")
source("get_output_resolution.R")
source("get_start_end_date.R")
source("get_var_from_nc.R")
source("merge_temp_obs.R")
source("unzip_isimip.R")

# Set TZ to "UTC"
Sys.setenv(TZ = "UTC")
