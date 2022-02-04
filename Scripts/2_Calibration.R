# Second step: calibrate the models
# Use multiple cores with jobs
# Using advice from: https://edwinth.github.io/blog/parallel-jobs/

# # Test
# folder_test = "C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Annie/hadgem2-es/calibration"
# models_to_run = "FLake"
# lakes = c("Allequash_Lake", "Annie", "Biel")

# Calibration tasks
cal_tasks = data.table(Lakes = lakes,
                       Data = 1L)

# Lakes with a non-existing calibration folder or an empty one need to be removed
for(i in seq_len(nrow(cal_tasks))){
  the_folder = file.path(folder_root, folder_data, cal_tasks[i, Lakes], "ewembi", "calibration")
  if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
    cal_tasks[i, Data := 0L]
  }
}
cal_tasks = cal_tasks[Data == 1L]

###### Divide the tasks over the available cores -----
all_cores = detectCores()
use_cores = ceiling(all_cores * frac_of_cores)

cal_tasks = divide_tasks_over_cores(cal_tasks, use_cores)

use_cores = max(cal_tasks[, Core])

###### Set up jobs -----
# Make sure to have one script that does the calibration
# based on core_job and then it selects from cal_tasks
# and picks the right folder
# Also pass the workingDir that should be used

for(i in seq_len(use_cores)){
  core_job = i
  rstudioapi::jobRunScript(path = "run_calib_on_core.R",
                           importEnv = TRUE,
                           name = paste0("job_", i))
}

