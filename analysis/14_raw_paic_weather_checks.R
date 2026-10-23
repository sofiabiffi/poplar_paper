# Companion residual diagnostics for the current quadratic-age weather analysis.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
m <- readRDS(file.path(root,'results/models/final_raw_paic_weather.rds'))
z <- read.csv(file.path(root,'results/tables/final_weather_diagnostics.csv'))
checks <- do.call(rbind,lapply(split(z,interaction(z$hybrid_code,z$age_model)),function(d){
  d <- d[order(d$measurement_year),];adj <- which(diff(d$measurement_year)==1)
  data.frame(hybrid_code=d$hybrid_code[1],hybrid=d$hybrid[1],age_model=d$age_model[1],
    consecutive_year_pairs=length(adj),lag1_residual_correlation=cor(d$deviance_residual[adj],d$deviance_residual[adj+1]),
    largest_cooks_distance=max(d$cooks_distance),largest_absolute_deviance_residual=max(abs(d$deviance_residual)))
}))
write.csv(checks,file.path(root,'results/tables/final_weather_residual_summary.csv'),row.names=FALSE)
# Earlier candidate scatterplots are archived; diagnostics do not recreate them.
cat('Year range:',range(m$data$measurement_year),'\nTemperature/rainfall means:',mean(m$data$temp),mean(m$data$rainfall),'\n')
cat('Weather correlation:',cor(m$data$temp,m$data$rainfall),'\n');print(checks)
print(m$comparison[ave(m$comparison$AICc,m$comparison$hybrid_code,FUN=function(x)rank(x,ties.method='first'))<=3,])
