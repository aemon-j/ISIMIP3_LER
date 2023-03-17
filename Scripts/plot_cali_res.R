# plot results forom the calibration

load("my_environment.RData")
invisible(sapply(loaded_packages, library, character.only = T))

load("res_cali.RData")
library(ggplot2)
library(ggpubr)
library(tidyverse)

lake_meta <- read.table("../LakeCharacteristics/LakeCharacteristics.csv", sep = ",",
                        header = TRUE, fileEncoding = "iso-8859-1")
colnames(lake_meta) <- c("Lake.Name", "Lake.Short.Name", "Lake.Name.Folder",
                         "Reservoir.or.lake.", "Country", "latitude.dec.deg",
                         "longitude.dec.deg", "elevation.m", "mean.depth.m",
                         "max.depth.m", "lake.area.sqkm",
                         "Average.Secchi.disk.depth.m",
                         "Light.extinction.coefficient.m")
load("../LakeCharacteristics/runtime.RData")
lake_meta <- left_join(lake_meta, df_runtime,
                       by = c("Lake.Short.Name" = "Lakes"))
thm <- theme_pubr(base_size = 13) + grids()

p_dist_rmse <- res$wide %>% ggplot() + geom_histogram(aes(x = rmse, fill = model),
                                       alpha=0.6, position = 'identity') +
  facet_wrap(~lake) + xlim(0, 15) + ggtitle("RMSE (°C)") + thm

p_dist_r <- res$wide %>% ggplot() + geom_histogram(aes(x = r, fill = model),
                                       alpha=0.6, position = 'identity') +
  facet_wrap(~lake) + ggtitle("Pearson corelation") + thm

# create new column for the two calibration runs
res$wide$run <- (ymd_hm(res$wide$cdate) > ymd("20230212")) + 1

best <- res$wide %>% group_by(lake = lake,
                              model = model,
                              run = run) %>%
  summarise(minRMSE = min(rmse, na.rm = TRUE),
            maxR = max(r, na.rm = TRUE)) %>%
  slice(which.min(minRMSE))
  
# best for the two runs seperately
best_sep <- res$wide %>% group_by(lake = lake,
                              model = model,
                              run = run) %>%
  summarise(minRMSE = min(rmse, na.rm = TRUE),
            maxR = max(r, na.rm = TRUE))

best <- left_join(best, lake_meta, by = c("lake" = "Lake.Short.Name"))

ggplot(best) + geom_histogram(aes(x = run))

p_best_rmse <- ggplot(best) + geom_col(aes(x = model, y = minRMSE, fill = model)) +
  facet_wrap(~lake) + ggtitle("minimum RMSE (°C)") + thm

p_best_r <- ggplot(best) + geom_col(aes(x = model, y = maxR, fill = model)) +
  facet_wrap(~lake) + ggtitle("maximum r") + thm

p_meta1 <- ggplot(best) + geom_point(aes(x = mean.depth.m, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs. mean lake depth") + thm + xlab("Mean lake depth (m)")

p_meta2 <- ggplot(best) + geom_point(aes(x = lake.area.sqkm, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs. lake area") + thm + xlab("Lake Area (km²)")

p_meta3 <- ggplot(best) + geom_point(aes(x = latitude.dec.deg, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs.latitude") + thm + xlab("Latitude (°N)")

p_meta4 <- ggplot(best) + geom_point(aes(x = longitude.dec.deg, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs.longitude") + thm + xlab("Longitude (°E)")

p_meta5 <- ggplot(best) + geom_point(aes(x = Duration, y = minRMSE, col = model)) +
  ggtitle("min rmse vs.available data") + thm + xlab("Available observations (a)")

p_meta6 <- ggplot(best) + geom_point(aes(x = elevation.m, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs. elevation") + thm + xlab("Lake elevation (m asl)")

p_meta7 <- ggplot(best) + geom_point(aes(x = Average.Secchi.disk.depth.m, y = minRMSE, col = model)) +
  ggtitle("min rmse vs. Secchi disk depth") + thm + xlab("Average Secchi disk depth (m)")


p_meta <- ggarrange(p_meta1,
                    p_meta2,
                    p_meta3,
                    p_meta6,
                    p_meta5,
                    p_meta4,
                    ncol = 3, nrow = 2, common.legend = TRUE)

p_dist_model <- ggplot(best) + geom_histogram(aes(x = minRMSE, fill = model,
                                                  y = ..density..),
                              alpha=0.6, position = 'identity', bins = 40) + 
   geom_density(aes(x = minRMSE, y =..density.., col = model), lwd = 1.5) + 
  ggtitle("Model performance (RMSE) distribution") + thm

p_dist_model_2runs <- ggplot(best_sep) + geom_histogram(aes(x = minRMSE, fill = model,
                                                  y = ..density..),
                                              alpha=0.6, position = 'identity', bins = 40) + 
  geom_density(aes(x = minRMSE, y =..density.., col = model), lwd = 1.5) + 
  ggtitle("Model performance (RMSE) distribution") + thm + facet_grid(run~.)

p_dist_lake <- best %>% group_by(lake) %>% summarise(minRMSE = min(minRMSE)) %>%
  ggplot() + geom_histogram(aes(x = minRMSE, y = ..density..),
                                              alpha=0.6, position = 'identity', bins = 20) + 
  geom_density(aes(x = minRMSE, y =..density..), lwd = 1.5) + 
  ggtitle("best RMSE of any model per lake") + thm

p_dist_lake_2runs <- best_sep %>% group_by(lake, run) %>% summarise(minRMSE = min(minRMSE)) %>%
  ggplot() + geom_histogram(aes(x = minRMSE, y = ..density..),
                            alpha=0.6, position = 'identity', bins = 20) + 
  geom_density(aes(x = minRMSE, y =..density..), lwd = 1.5) + 
  ggtitle("best RMSE of any model per lake") + facet_grid(run~.) + thm

p_dist_model_r <- ggplot(best) + geom_histogram(aes(x = maxR, fill = model,
                                                    y = ..density..),
                                              alpha=0.6, position = 'identity',
                                              bins = 40) + 
  geom_density(aes(x = maxR, y =..density.., col = model), lwd = 1.5) + 
  ggtitle("Model performance (RMSE) distribution") + thm

ggsave("dist_r.pdf",p_dist_r, device = "pdf", width = 15, height = 11)
ggsave("dist_rmse.pdf",p_dist_rmse, device = "pdf", width = 15, height = 11)
ggsave("best_r.pdf",p_best_r, device = "pdf", width = 15, height = 11)
ggsave("best_rmse.pdf",p_best_rmse, device = "pdf", width = 15, height = 11)
ggsave("performance_meta.pdf",p_meta, device = "pdf", width = 13, height = 11)
ggsave("performance_model_rmse.pdf",p_dist_model, device = "pdf", width = 11,
       height = 7)
ggsave("performance_model_r.pdf",p_dist_model_r, device = "pdf", width = 11,
       height = 7)

best %>% group_by(model) %>%
  summarise(n = length(minRMSE),
            n_2 = sum(minRMSE<2, na.rm = TRUE),
            n_25 = sum(minRMSE<2.5, na.rm = TRUE)) %>% print()

## check if the boundaries of the parameters are a problem

plot_par_dist <- function(slake, res, model = c("FLake", "GLM", "GOTM",
                                                "Simstrat")) {
  dat <- filter(res$wide, lake == slake)
  p <- list()
  for (m in model) {
    par <- select(dat, c("model", colnames(dat)[11:24])) %>%
      filter(model == m) %>% mutate(across(.fns = function(x)sum(!is.na(x)))) %>%
      select(which(colMeans(.)>0), -model) %>% colnames()
  p[[m]] <- dat %>% filter(model == m) %>% select(c(par, "rmse", "par_id")) %>% pivot_longer(1:5) %>%
      ggplot() + geom_point(aes(x = value, y = rmse)) +
      facet_wrap(.~name, scales = "free_x") + scale_x_log10() +
      ggtitle(paste0(slake, " - ", m))
  }
  return(p)  
}

plot_par_dist("BlackOak", res)


## check the characteristics of the lakes where the difference in best rmse is
## large between the models

# lakes with attitude
lwa <- best %>% group_by(lake) %>% summarise(var_rmse = sd(minRMSE)) %>%
  mutate(model_diff = var_rmse > 1)

best <- left_join(best, lwa) 

m <- lm(var_rmse ~ latitude.dec.deg+longitude.dec.deg+mean.depth.m+lake.area.sqkm+elevation.m, best)
ms <- step(m, direction = "both")
summary(m)

