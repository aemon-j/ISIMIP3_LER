# copy old calibration results to a folder and delete them in the lake specific
# folder

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = TRUE))

dat_f_cali <- data.frame(lake = lakes,
                         fcali = file.path("../ISIMIPdata",lakes,
                                           "gswp3-w5e5/calibration/cali"))

lapply(seq_len(nrow(dat_f_cali)), function(i){
  files <- list.files(dat_f_cali$fcali[i])
  file.copy(file.path(dat_f_cali$fcali[i], files),
            file.path("../old_calibration_results",
                      paste0(dat_f_cali$lake[i], "_", files)))
  file.remove(file.path(dat_f_cali$fcali[i], files))
})