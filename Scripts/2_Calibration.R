# Second step: calibrate the models
# Rewrite to use the parallel package instead of rstudio jobs

# # Test
# folder_test = "C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/ISIMIP data/Annie/hadgem2-es/calibration"
# models_to_run = "FLake"
# lakes = c("Allequash_Lake", "Annie", "Biel")

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

# Calibration tasks
cal_tasks = data.table(Lakes = lakes,
                       Data = 1L)

# Lakes with a non-existing calibration folder or an empty one need to be removed
for(i in seq_len(nrow(cal_tasks))){
  the_folder = file.path(folder_root, folder_data, cal_tasks[i, Lakes], tolower(calib_gcm), "calibration")
  if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
    cal_tasks[i, Data := 0L]
  }
}
cal_tasks = cal_tasks[Data == 1L]

###### Divide the tasks over the available cores -----
all_cores = detectCores()
use_cores = ceiling(all_cores * frac_of_cores)
if(use_cores == all_cores){
  use_cores = all_cores - 1
}

cal_tasks = divide_tasks_over_cores(cal_tasks, use_cores)

use_cores = max(cal_tasks[, Core])

###### Set up cores using the parallel package -----
clust = makeCluster(use_cores)
clusterExport(clust, varlist = list("cal_tasks", "run_calib_on_core", "add_to_report",
                                    "folder_root", "folder_data", "calib_gcm",
                                    "cal_iterations", "cmethod", "models_to_run",
                                    "folder_report", "report_name"),
                        envir = environment())
clusterEvalQ(clust, expr = {library(LakeEnsemblR); library(data.table)})
message("Calibrating models in parallel... ", paste0("[", Sys.time(), "]"))
parLapply(clust, seq_len(use_cores), function(core_job) do.call(run_calib_on_core,
                                                                args = list(cal_tasks, core_job)))
stopCluster(clust)
message("Calibration complete!", paste0("[", Sys.time(), "]"))

