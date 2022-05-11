# Provides folder structure

dir_name = dirname(rstudioapi::getActiveDocumentContext()$path)
folder_root = file.path(dir_name, "..")

folder_scripts = "Scripts"
folder_data = "ISIMIP data"
folder_template_LER = "LER_template"
folder_other = "Other"
folder_test_result = "Other/Test dataset"
folder_report = "Reports"
