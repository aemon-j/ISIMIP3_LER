# Script called from 2_calibration.R
# calibrates a certain selection of cal_tasks

# Imported packages are not transferred, so need to be imported again. 
library(data.table)
library(LakeEnsemblR)

if(!exists("core_job")){
  stop("core_job should exist!")
}

setDT(cal_tasks)

cal_tasks = cal_tasks[Core == core_job]


for(i in seq_len(nrow(cal_tasks))){
  cal_folder = file.path(folder_root,
                         folder_data,
                         cal_tasks[i, Lakes],
                         "ewembi",
                         "calibration")
  
  setwd(cal_folder)
  
  cali_ensemble(config_file = "LakeEnsemblR.yaml",
                num = cal_iterations,
                cmethod = cmethod,
                model = models_to_run)
  
  # Note: Cannot be run without setting wd
  # can't find file, despite file.exists(file.path(cal_folder, "LakeEnsemblR.yaml")) being TRUE
  # This should be possible (it can be done with export_config)
  # run_ensemble also crashes if doing it this way.
  # Either work with folder = "." and setwd, or fix. 
  # I'd say it's an important thing to fix, but not doable right now, so let's use setwd
  
  
  print(paste("Core number", core_job, ", task", cal_tasks[i, Lakes], "completed!"))
}





