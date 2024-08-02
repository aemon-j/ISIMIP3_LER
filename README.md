[![DOI](https://zenodo.org/badge/455537462.svg)](https://zenodo.org/doi/10.5281/zenodo.13165427)

# Workflow

## Only once
1. Download ISIMIP meteo forcing into 'ISIMIPdownload/'
2. Download lake characteristics files (hypsograph and temperature observations) into 'LakeCharacteristics/' (see 'LakeCharacteristics/ReadMe.md')
3. Run 'Checking_lake_characteristics.R', to standardise all lake characteristics file and correct mistakes.
4. Where needed, change settings in 'Settings.R' and '0_Initialise.R'.
5. Where needed, adjust calibration parameters and ranges in 'LER_template/LakeEnsemblR.yaml'
6. Run 0_Initialise.R, which saves a my_environment.Rdata file with all settings
7. Run 'Create_folder_structure.R' to unpack the ISIMIP files and place them in the right directories (inside 'ISIMIPdata/'.

## Iteratively (whenever you need to re-calibrate or change settings
1. 0_Initialise.R  -> This again creates the my_environment.Rdata file with all settings and the folder structure
2. 1_Set_up_LER_folders.R  -> Prepares all folders for the calibration and future climate runs, setting the correct lake characteristics, etc.
3. 2_Calibration.R  -> Runs the actual calibration, dividing lakes over multiple cores, for calib_gcm only
4. 3_Get_best_calibration_result.R  -> Extract the parameters for the best calibration in each lake, and export these parameters to the non-calibration scenarios (historical, ssp126, etc.)
5. 4_Run_all_simulations.R  -> Runs all the non-calibration scenario simulations
6. 5_Create_ISIMIP_netcdfs.R  -> Converts the LakeEnsemblR output netcdf files into the netcdf format required by ISIMIP

## Additional information
This repository also contains a parallel way of running the scripts, which can be changed in 'Settings.R' ('calib_type = "cal_project"'), with two
alternative scripts 4_ and 5_. These are not required to recreate the ISIMIP calibration, but allow a way to more conveniently compare a LakeEnsemblR
calibration with uncalibrated runs and global simulations.
