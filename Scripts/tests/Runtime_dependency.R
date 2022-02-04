# Test to see how runtime depends on the amount of layers in the model and on the runtime
# We use the GOTM model and do multiple runs for several combinations, then fit a linear model. 
# Lake Biel - gfdl-esm2m is used as test case (copied into separate folder)
# The duration of the entire run_ensemble call is assessed (including writing the final ensemble output)

# 74 m deep
# Historical simulation: 1861-2005 (145 years)

Sys.setenv(TZ = "UTC")

setwd("C:/Users/mesman/Documents/Projects/2021/ISIMIP3 - LakeEnsemblR/Other/Test dataset")


library(data.table)
library(lubridate)
library(LakeEnsemblR)

# Settings
layers = c(74 / 2, 74, 74 * 2, 74 * 4)
durations = c(145, 120, 95, 70, 45, 20)
repetitions = 3L

# Initialising table
df_tests = data.table(expand.grid(layers, durations))
setnames(df_tests, c("Layers", "Durations"))
new_cols = paste0("run_", 1:repetitions)

df_tests[, (new_cols) := as.numeric(NA)]
df_tests[, av_runtime := as.numeric(NA)]


# Prepare before runs
start_date = get_yaml_multiple("LakeEnsemblR.yaml", key1 = "time", "key2" = "start")
start_date = as.POSIXct(start_date)
max_depth = get_yaml_multiple("LakeEnsemblR.yaml", key1 = "location", "key2" = "depth")

progressBar = txtProgressBar(min = 0, max = nrow(df_tests), initial = 0)
progress = 0
for(i in seq_len(nrow(df_tests))){
  
  # Runtime
  end_date_setting = format(start_date + years(df_tests[i, Durations]) - days(1),
                            "%Y-%m-%d %H:%M:%S")
  input_yaml_multiple("LakeEnsemblR.yaml", key1 = "time", "key2" = "stop",
                      value = end_date_setting)
  
  export_config("LakeEnsemblR.yaml", model = "GOTM")
  
  # Number of layers
  input_yaml_multiple("./GOTM/gotm.yaml", key1 = "grid", "key2" = "nlev",
                      value = df_tests[i, Layers])
  
  
  for(j in seq_len(repetitions)){
    time_start = Sys.time()
    
    run_ensemble("LakeEnsemblR.yaml", model = "GOTM")
    
    time_end = Sys.time()
    
    the_col = paste0("run_", j)
    df_tests[i, (the_col) := as.numeric(difftime(time_end, time_start, units = "secs"))]
  }
  
  progress = progress + 1
  setTxtProgressBar(progressBar,progress)
}

df_tests[, av_runtime := apply(.SD, 1, mean), .SDcols = new_cols]

fwrite(df_tests, "Runtime_dependency_table.csv")


# Fitting a linear model to the data to predict runtime from duration and number of layers
M1 = lm(av_runtime ~ Layers * Durations, data = df_tests)
summary(M1)

### Assumption testing
# Homogeneity
E1 <- resid(M1)   #or better: E1 <- rstandard(M1)
F1 <- fitted(M1)
plot(x = F1, 
     y = E1, 
     xlab = "Fitted values",
     ylab = "Residuals", 
     main = "Homogeneity?")
abline(h = 0, v = 0, lty = 2)
# Homogeneity OK

# Normality
hist(E1, main = "Normality", breaks=10)
# Or qq-plot
qqnorm(E1)
qqline(E1)
# Normality OK

# Constructed equation:
coefs = round(M1$coefficients, 4L)

paste0("Constructed equation: ",
      "Estimated runtime (s) = ", coefs[1], " + Num_of_Layers * ", coefs[2],
      " + Duration(y) * ", coefs[3], " + Num_of_Layers * Duration(y) * ", coefs[4])

num_of_layers = 37
duration_y = 145

coefs[1] + coefs[2] * num_of_layers + coefs[3] * duration_y + coefs[4] * num_of_layers * duration_y

df_equation = data.table(intercept = coefs[1],
                         slope_layers = coefs[2],
                         slope_duration = coefs[3],
                         slope_interaction = coefs[4])
fwrite(df_equation, "Runtime_Equation.csv")
