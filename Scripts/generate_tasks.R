# Subdivide all calibration/simulation tasks for LHC into a single table
# Code based on cali_ensemble.R
# Use same parameter set for each lake
# Assumes that Folder_Structure.R and 0_Initialise.R have been run beforehand
# If you need a subset of this, it's best to read the generated table and make selections within it

# type; one of "calibration" or "simulation"
# name; name of the output file. If "automatic" (the default), it will use a standard name. Include file type when specifying own name

generate_tasks = function(type, name = "automatic"){
  
  if(!(type %in% c("calibration", "simulation"))) stop("'type' argument should be one of c('calibration', 'simulation')")
  
  config_file = read.config(file.path(folder_root, folder_template_LER, "LakeEnsemblR.yaml"))
  
  if(type == "calibration"){
    ##### Construct a data.frame for each model with the pars to calibrate -----
    # meteo parameter
    cal_section <- config_file[["calibration"]][["met"]]
    params_met <- sapply(names(cal_section), function(n) cal_section[[n]]$initial)
    p_lower_met <- sapply(names(cal_section), function(n) cal_section[[n]]$lower)
    p_upper_met <- sapply(names(cal_section), function(n) cal_section[[n]]$upper)
    # get names of models for which parameter are given
    model_p <- models_to_run[models_to_run %in% names(config_file[["calibration"]])]
    # model specific parameters
    cal_section <- lapply(model_p, function(m) config_file[["calibration"]][[m]])
    names(cal_section) <- model_p
    # get parameters
    params_mod <- lapply(model_p, function(m) {
      sapply(names(cal_section[[m]]),
             function(n) as.numeric(cal_section[[m]][[n]]$initial))})
    names(params_mod) <- model_p
    # get lower bound
    p_lower_mod <- lapply(model_p, function(m) {
      sapply(names(cal_section[[m]]),
             function(n) as.numeric(cal_section[[m]][[n]]$lower))})
    names(p_lower_mod) <- model_p
    # get upper bound
    p_upper_mod <- lapply(model_p, function(m) {
      sapply(names(cal_section[[m]]),
             function(n) as.numeric(cal_section[[m]][[n]]$upper))})
    names(p_upper_mod) <- model_p
    # log transform for LHC?
    log_mod <- lapply(model_p, function(m) {
      sapply(names(cal_section[[m]]),
             function(n) as.logical(cal_section[[m]][[n]]$log))})
    names(log_mod) <- model_p
    
    # create a list with parameters for every model
    pars_l <- lapply(models_to_run, function(m){
      df <- data.frame(pars = c(params_met, params_mod[[m]], recursive = TRUE),
                       name = c(names(params_met), names(params_mod[[m]]), recursive = TRUE),
                       upper = c(p_upper_met, p_upper_mod[[m]], recursive = TRUE),
                       lower = c(p_lower_met, p_lower_mod[[m]], recursive = TRUE),
                       type = c(rep("met", length(params_met)),
                                rep("model", length(params_mod[[m]])), recursive = TRUE),
                       log = c(rep(FALSE, length(params_met)), log_mod[[m]], recursive = TRUE),
                       stringsAsFactors = FALSE)
      colnames(df) <- c("pars", "name", "upper", "lower", "type", "log")
      return(df)
    })
    names(pars_l) <- models_to_run
    
    ##### Generate parameter files for calibration -----
    pars_lhc <- list()
    for (m in models_to_run) {
      # range of parametes
      prange <- matrix(c(pars_l[[m]]$lower, pars_l[[m]]$upper), ncol = 2)
      # calculate log if wanted
      prange[pars_l[[m]]$log, ] <- log10(prange[pars_l[[m]]$log, ])
      # sample parameter sets
      pars_lhc[[m]] <- Latinhyper(parRange = prange, num = cal_iterations)
      # retransform log parameter
      pars_lhc[[m]][, pars_l[[m]]$log] <- 10^pars_lhc[[m]][, pars_l[[m]]$log]
      # only use 5 significant digits
      pars_lhc[[m]] <- signif(pars_lhc[[m]], 5)
      # set colnames
      colnames(pars_lhc[[m]]) <- pars_l[[m]]$name
      pars_lhc[[m]] <- as.data.frame(pars_lhc[[m]])
      pars_lhc[[m]]$par_id <- paste0("p", formatC(seq_len(cal_iterations), width = round(log10(cal_iterations)) + 1,
                                                  format = "d", flag = "0"))
      pars_lhc[[m]]$model <- m
    }
    
    ##### Merge and format calibration files -----
    
    df_tasks = rbindlist(pars_lhc, fill = T)
    len_df = nrow(df_tasks)
    
    df_tasks = df_tasks[rep(df_tasks[, .I], length(lakes))]
    df_tasks[, lake := rep(lakes, each = len_df)]
  }else if(type == "simulation"){
    df_tasks = expand.grid(gcm = gcms, scen = scens[scens != "calibration"], lake = lakes, model = models_to_run)
    setDT(df_tasks)
  }
  
  ##### Write table -----
  if("par_id" %in% names(df_tasks)){
    setcolorder(df_tasks, c("lake", "model", "par_id"))
  }else{
    setcolorder(df_tasks, c("lake", "model"))
  }
  
  
  if(!dir.exists(file.path(folder_root, folder_cal_files))){
    dir.create(file.path(folder_root, folder_cal_files))
  }
  
  # Naming
  if(name != "automatic"){
    file_name = name
  }else{
    file_name = fifelse(type == "calibration", "calibration_tasks.csv", "simulation_tasks.csv")
  }
  
  fwrite(df_tasks, file.path(folder_root, folder_cal_files, file_name))
}
