# This script initialises all the settings for the ISIMIP3-LakeEnsemblR project

# Specify the folder structure here
dir_name = dirname(rstudioapi::getActiveDocumentContext()$path)
folder_root = file.path(dir_name, "..")

folder_scripts = "Scripts"
folder_data = "ISIMIPdata"
folder_template_LER = "LER_template"
folder_other = "Other"
folder_out = "Output"
folder_test_result = "Other/Test dataset"
folder_report = "Reports"
folder_isimip_root = "ISIMIPdownload"
folder_isimip_calib_files = file.path(folder_isimip_root, "calibration")
folder_cal_files = "Cal_files"

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
source("run_calib_on_core.R")
source("temp_to_dens.R")
source("unzip_isimip.R")
source("write_isimip_netcdf.R")

# Set TZ to "UTC"
Sys.setenv(TZ = "UTC")

loaded_packages = gsub("package:", "", search()[grepl("package:", search())])
save.image(file = "my_environment.RData")
