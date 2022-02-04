# Runs all the scenarios and lakes (except calibration)
# Export config is not needed, as that happened in step 3

# Can test for Biel/ipsl-cm5a-lr/rcp85

# As in script 2, divide tasks over cores. I should define the cal_tasks and then make a function
# that returns the division per core.
# Calibration tasks
sim_tasks = data.table(Lakes = lakes,
                       Data = 1L)

# Lakes with a non-existing calibration folder or an empty one need to be removed
for(i in seq_len(nrow(sim_tasks))){
  the_folder = file.path(folder_root, folder_data, sim_tasks[i, Lakes], "ewembi", "calibration")
  if(!dir.exists(the_folder) | length(list.files(the_folder)) == 0L){
    sim_tasks[i, Data := 0L]
  }
}
sim_tasks = sim_tasks[Data == 1L]
lakes = sim_tasks[, Lakes]

# Now also multiple gcms and scens
sim_tasks = expand.grid(lakes, gcms[!(gcms %in% "EWEMBI")], scens[!(scens %in% "calibration")])
setDT(sim_tasks)
setnames(sim_tasks, c("Lakes", "GCM", "Scen"))
setorder(sim_tasks, Lakes, GCM)

all_cores = detectCores()
use_cores = ceiling(all_cores * frac_of_cores)

sim_tasks = divide_tasks_over_cores(sim_tasks, use_cores)

use_cores = max(sim_tasks[, Core])

###### Set up jobs -----

for(i in seq_len(use_cores)){
  core_job = i
  rstudioapi::jobRunScript(path = "run_model_on_core.R",
                           importEnv = TRUE,
                           name = paste0("job_", i))
}

