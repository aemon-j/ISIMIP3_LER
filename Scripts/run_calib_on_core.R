# Script called from 2_calibration.R
# calibrates a certain selection of cal_tasks

run_calib_on_core = function(cal_tasks, core_job){
  cal_tasks = cal_tasks[Core == core_job]
  
  add_to_report(file.path(folder_root, folder_report),
                paste0(report_name,"_", report_date, "_"), 2L, core_job,
                paste0("Core:", core_job, ",Method:", cmethod, ",number_of_runs:",
                       cal_iterations, ",Start_time:", Sys.time(), ",Tasks:",
                       nrow(cal_tasks), ",Lake_names:'",
                       paste0(cal_tasks[, Lakes], collapse = ", "),"'"))
  
  add_to_report(file.path(folder_root, folder_report),
                paste0(report_name,"_", report_date, "_"), 2L, core_job,
                paste0("Lake,Start_time,End_time"))
  
  for(i in seq_len(nrow(cal_tasks))){
    cal_folder = file.path(folder_root,
                           folder_data,
                           cal_tasks[i, Lakes],
                           tolower(calib_gcm),
                           "calibration")
    
    setwd(cal_folder)
    start_time <- Sys.time()
    cali_ensemble(config_file = "LakeEnsemblR.yaml",
                  num = cal_iterations,
                  cmethod = cmethod,
                  model = models_to_run)
    end_time <- Sys.time()
    # Note: Cannot be run without setting wd
    # can't find file, despite file.exists(file.path(cal_folder, "LakeEnsemblR.yaml")) being TRUE
    # This should be possible (it can be done with export_config)
    # run_ensemble also crashes if doing it this way.
    # Either work with folder = "." and setwd, or fix. 
    # I'd say it's an important thing to fix, but not doable right now, so let's use setwd
    
    add_to_report(file.path(folder_root, folder_report),
                  paste0(report_name,"_", report_date, "_"), 2L, core_job,
                  paste0(c(cal_tasks[i, Lakes], as.character(start_time),
                           as.character(end_time)), collapse = ","))
    
  }
}
