# Script called from 4_Run_all_simulations.R
# simulates a certain selection of sim_tasks

# Imported packages are not transferred to the job, so need to be imported again. 
library(data.table)
library(LakeEnsemblR)

if(!exists("core_job")){
  stop("core_job should exist!")
}

setDT(sim_tasks)

sim_tasks = sim_tasks[Core == core_job]

add_to_report(file.path(folder_root, folder_report), report_name, 4L, core_job,
              paste0("Tasks (", nrow(sim_tasks), "): ", paste(sim_tasks[, Lakes],
                                                              sim_tasks[, GCM],
                                                              sim_tasks[, Scen],
                                                              sep = "_",
                                                              collapse = ", ")))

for(i in seq_len(nrow(sim_tasks))){
  sim_folder = file.path(folder_root,
                         folder_data,
                         sim_tasks[i, Lakes],
                         tolower(sim_tasks[i, GCM]),
                         as.character(sim_tasks[i, Scen]))
  
  setwd(sim_folder)
  
  run_ensemble(config_file = "LakeEnsemblR.yaml",
               model = models_to_run)
  
  add_to_report(file.path(folder_root, folder_report), report_name, 4L, core_job,
                paste0("Completed: ", paste(sim_tasks[i, Lakes], sim_tasks[i, GCM], sim_tasks[i, Scen], sep = "_")))
}
