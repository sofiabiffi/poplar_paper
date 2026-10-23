.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(lme4)
root <- 'poplar_paper'
obj <- readRDS(file.path(root,'results/models/weather_temperature_rainfall.rds'))
dat <- obj$data
cv <- obj$validation
stopifnot(!anyDuplicated(cv[c('model','measurement_year','hybrid_code')]),all(is.finite(cv$predicted)),all(cv$predicted>0))
for(n in unique(cv$model)) stopifnot(sum(cv$model==n)==nrow(dat))
diagnostics <- do.call(rbind,lapply(names(obj$models),function(n) {
  f <- obj$models[[n]]
  data.frame(model=n,measurement_year=dat$measurement_year,hybrid_code=dat$hybrid_code,
    observed=dat$PAIC,fitted=fitted(f),pearson=residuals(f,type='pearson'),deviance=residuals(f,type='deviance'))
}))
write.csv(diagnostics,file.path(root,'results/checks/weather_temperature_rainfall_residuals.csv'),row.names=FALSE)
weather <- unique(dat[c('measurement_year','temperature','rainfall')])
cat('Temperature/rainfall correlation:',cor(weather$temperature,weather$rainfall),'\n')
cat('Multi-year intervals:',paste(unique(dat$measurement_year[dat$interval_years>1]),collapse=', '),'\n')
checks <- read.csv(file.path(root,'results/tables/weather_temperature_rainfall_fit_checks.csv'))
print(checks[checks$singular | (!is.na(checks$message) & nzchar(checks$message)),])
cat('Validation coverage and finite positive predictions checked.\n')
print(read.csv(file.path(root,'results/tables/weather_temperature_rainfall_validation.csv')))
