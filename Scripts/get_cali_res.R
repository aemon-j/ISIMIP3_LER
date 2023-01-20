# read in results forom the calibration

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = TRUE))



# data frame with the paths for each lake
dat_f_cali <- data.frame(lake = lakes,
                         fcali = file.path("../ISIMIPdata",lakes,
                                           "gswp3-w5e5/calibration/cali"),
                         yaml = file.path("ISIMIPdata", lakes,
                                          "gswp3-w5e5/calibration/LakeEnsemblR.yaml"))

###### Divide the tasks over the available cores -----
all_cores = detectCores()
use_cores = ceiling(all_cores * frac_of_cores) - 1

# split the directories to the cores
splt <- rep(seq_len(use_cores), each = floor(nrow(dat_f_cali)/use_cores))
splt <- c(splt,
          seq_len(use_cores)[seq_len(nrow(dat_f_cali) -
                                       floor(nrow(dat_f_cali)/use_cores)*use_cores)])
splt <- sort(splt)

dat_f_cali <- lapply(seq_len(use_cores), function(n)dat_f_cali[splt == n, ])

###### Set up cores using the parallel package -----
clust = makeCluster(use_cores)
clusterExport(clust, varlist = list("models_to_run"),
              envir = environment())
clusterEvalQ(clust, expr = {library(LakeEnsemblR)})
res_cali <- parLapply(clust,
                      dat_f_cali,
                      function(core_job){
                        res_cali <- list()
                        for (f in seq_len(length(core_job$fcali))) {
                            # find unique LHC run dates
                            dates <- unique(gsub(pattern = ".csv",
                                                 replacement = "",
                                                 x = gsub(pattern = "\\w+_LHC_",
                                                          replacement = "",
                                                          x = list.files(core_job$fcali[f]))))
                            for (d in dates) {
                              tryCatch({
                                dfiles <- list.files(core_job$fcali[f])[grepl(d, list.files(core_job$fcali[f]))]
                                
                                dat.t <- load_LHC_results(config_file = core_job$yaml[f], model = models_to_run,
                                                          res_files = file.path(core_job$fcali[f], dfiles))
                                dat.t <- reshape2::melt(dat.t, id.var = c("par_id"))
                                colnames(dat.t)[4] <- "model"
                                dat.t$cdate <- d
                                dat.t$lake <- core_job$lake[f]
                                res_cali[[paste0(f, d)]] <- dat.t
                              },
                              error = function(e) {
                              })
                          }
                        }
                        res_cali_l <- reshape2::melt(res_cali,
                                                     id.var = c("par_id", "cdate", "lake", "model", "value", "variable"))
                        res_cali_l <- res_cali_l[, -7]
                        return(res_cali_l)
                      })
stopCluster(clust)

res_cali_l <- reshape2::melt(res_cali, id.var = c("par_id", "lake", "cdate",
                                                  "model", "variable", "value"))
res_cali_l$par_id <- paste0(res_cali_l$cdate, res_cali_l$par_id)
res_cali_l <- res_cali_l[, -c(7)]

# reshape to wide format
res_wide <- tidyr::pivot_wider(res_cali_l, id_cols = c("par_id", "model", "cdate", "lake"),
                               names_from = "variable")

res <- list(long = res_cali_l,
            wide = res_wide)
save(res, file = "res_cali.RData")
# plot result
#ggplot(res_wide) + geom_point(aes(x = wind_speed, y = rmse, col = model)) +
#  facet_grid(~lake)
