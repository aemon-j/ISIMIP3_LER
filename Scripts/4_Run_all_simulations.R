# Runs all the scenarios and lakes (except calibration)
# Export config is not needed, as that happened in step 3

# Can test for Biel/ipsl-cm5a-lr/rcp85

# As in script 2, divide tasks over cores. I should define the sim_tasks and then make a function
# that returns the division per core.

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

sim_tasks = data.table(Lakes = lakes,
                       Data = 1L)

# Lakes with a non-existing calibration folder or an empty one need to be removed
for(i in seq_len(nrow(sim_tasks))){
  the_folder = file.path(folder_root, folder_data, sim_tasks[i, Lakes], tolower(calib_gcm), "calibration")
  if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
    sim_tasks[i, Data := 0L]
  }
}
sim_tasks = sim_tasks[Data == 1L]
lakes = sim_tasks[, Lakes]

# Now also multiple gcms and scens
sim_tasks = expand.grid(lakes, gcms, scens[!(scens %in% "calibration")])
#sim_tasks = expand.grid(lakes, gcms, scens) use this to also run for calib scen and get profiles for best performing params
setDT(sim_tasks)
setnames(sim_tasks, c("Lakes", "GCM", "Scen"))
setorder(sim_tasks, Lakes, GCM)

all_cores = detectCores()
use_cores = ceiling(all_cores * frac_of_cores)
if(use_cores == all_cores){
  use_cores = all_cores - 1
}

sim_tasks = divide_tasks_over_cores(sim_tasks, use_cores)

use_cores = max(sim_tasks[, Core])

###### Set up cores using the parallel package -----
clust = makeCluster(use_cores)
clusterExport(clust, varlist = list("sim_tasks", "run_model_on_core", "add_to_report",
                                    "folder_root", "folder_data",
                                    "models_to_run",
                                    "folder_report", "report_name"),
              envir = environment())
clusterEvalQ(clust, expr = {library(LakeEnsemblR); library(data.table)})
message("Running models in parallel... ", paste0("[", Sys.time(), "]"))
parLapply(clust, seq_len(use_cores), function(core_job) do.call(run_model_on_core,
                                                                args = list(sim_tasks, core_job)))
stopCluster(clust)
message("Model run complete!", paste0("[", Sys.time(), "]"))

# ###### Set up jobs -----
# 
# for(i in seq_len(use_cores)){
#   core_job = i
#   rstudioapi::jobRunScript(path = "run_model_on_core.R",
#                            importEnv = TRUE,
#                            name = paste0("job_", i))
# }

