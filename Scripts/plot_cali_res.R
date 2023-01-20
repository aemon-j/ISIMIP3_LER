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

thm <- theme_pubr(base_size = 13) + grids()

p_dist_rmse <- res$wide %>% ggplot() + geom_histogram(aes(x = rmse, fill = model),
                                       alpha=0.6, position = 'identity') +
  facet_wrap(~lake) + xlim(0, 15) + ggtitle("RMSE (°C)") + thm

p_dist_r <- res$wide %>% ggplot() + geom_histogram(aes(x = r, fill = model),
                                       alpha=0.6, position = 'identity') +
  facet_wrap(~lake) + ggtitle("Pearson corelation") + thm

best <- res$wide %>% group_by(lake = lake,
                              model = model) %>%
  summarise(minRMSE = min(rmse, na.rm = TRUE),
            maxR = max(r, na.rm = TRUE))

best <- left_join(best, lake_meta, by = c("lake" = "Lake.Short.Name"))

p_best_rmse <- ggplot(best) + geom_col(aes(x = model, y = minRMSE, fill = model)) +
  facet_wrap(~lake) + ggtitle("minimum RMSE (°C)") + thm

p_best_r <- ggplot(best) + geom_col(aes(x = model, y = maxR, fill = model)) +
  facet_wrap(~lake) + ggtitle("maximum r") + thm

p_meta1 <- ggplot(best) + geom_point(aes(x = mean.depth.m, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs. mean lake depth") + thm

p_meta2 <- ggplot(best) + geom_point(aes(x = lake.area.sqkm, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs. mean lake area") + thm

p_meta3 <- ggplot(best) + geom_point(aes(x = latitude.dec.deg, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs.latitude") + thm

p_meta4 <- ggplot(best) + geom_point(aes(x = longitude.dec.deg, y = minRMSE, col = model)) +
  scale_x_log10() + ggtitle("min rmse vs.longitude") + thm

p_meta <- ggarrange(p_meta1,
                    p_meta2,
                    p_meta3,
                    p_meta4,
                    ncol = 2, nrow = 2, common.legend = TRUE)

p_dist_model <- ggplot(best) + geom_histogram(aes(x = minRMSE, fill = model),
                              alpha=0.6, position = 'identity') + 
   geom_density(aes(x = minRMSE, y =..count.., col = model)) + 
  ggtitle("Model performance (RMSE) distribution") + thm

ggsave("dist_r.pdf",p_dist_r, device = "pdf", width = 15, height = 11)
ggsave("dist_rmse.pdf",p_dist_rmse, device = "pdf", width = 15, height = 11)
ggsave("best_r.pdf",p_best_r, device = "pdf", width = 15, height = 11)
ggsave("best_rmse.pdf",p_best_rmse, device = "pdf", width = 15, height = 11)
ggsave("performance_meta.pdf",p_meta, device = "pdf", width = 13, height = 11)
ggsave("performance_model_rmse.pdf",p_dist_model, device = "pdf", width = 11,
       height = 7)
