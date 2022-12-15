# Workflow

1. Change root directory in the 0_Initialise.R document.
2. Fill in the Settings.R document to change settings for the runs. 
3. Set calibration parameters and ranges in LER_template/LakeEnsemblR.yaml
4. Run 0_Initialise.R, which saves a my_environment.Rdata file with all settings (this needs to be rerun if you access the drive from another user account).
5. (Only once) After downloading the ISIMIP data, you will have to run Create_folder_structure.R to unpack the ISIMIP files and place them in the right directories. 
6. Now you can run the other scripts in order (1_, 2_, etc.).
