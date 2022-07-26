# Provides folder structure

dir_name = dirname(rstudioapi::getActiveDocumentContext()$path)
folder_root = file.path(dir_name, "..")

folder_scripts = "Scripts"
folder_data = "ISIMIPdata"
folder_template_LER = "LER_template"
folder_other = "Other"
folder_test_result = "Other/Test dataset"
folder_report = "Reports"
folder_isimip_root = "ISIMIPdownload"
folder_isimip_calib_files = file.path(folder_isimip_root, "calibration")
folder_cal_files = "Cal_files"
