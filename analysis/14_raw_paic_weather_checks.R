# Companion residual diagnostics for the current quadratic-age weather analysis.
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args))normalizePath(args[1],winslash='/') else normalizePath('.',winslash='/')
.libPaths(c(file.path(root,'renv/library'),.libPaths()))
library(ggplot2)
source(file.path(root,'plot_style.R'))
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

# Reproducible diagnostics for the reporting summer models.
qd <- do.call(rbind,lapply(names(m$fits)[grepl('Both$',names(m$fits))],function(key){
 f<-m$fits[[key]];h<-substr(key,1,1);mu<-fitted(f);phi<-summary(f)$dispersion
 data.frame(hybrid=publication_labels(h),year=m$data$measurement_year[m$data$hybrid_code==h],
  fitted=mu,pearson=residuals(f,type='pearson'),deviance=residuals(f,type='deviance'),
  quantile_residual=qnorm(pmin(1-1e-10,pmax(1e-10,pgamma(f$y,shape=1/phi,scale=mu*phi)))),
  cooks=cooks.distance(f))
}))
write.csv(qd,file.path(root,'results/checks/weather_model_se_diagnostics.csv'),row.names=FALSE)
pdf(file.path(root,'results/checks/weather_model_se_diagnostics.pdf'),width=10,height=8)
for(h in unique(qd$hybrid)){
 q<-qd[qd$hybrid==h,];par(mfrow=c(2,3),mar=c(4,4,3,1))
 plot(q$fitted,q$pearson,xlab='Fitted PAIC',ylab='Pearson residual',main=h);abline(h=0,lty=2)
 plot(q$fitted,sqrt(abs(q$pearson)),xlab='Fitted PAIC',ylab='Sqrt absolute Pearson residual',main='Variance pattern')
 qqnorm(q$quantile_residual,main='Gamma quantile residuals');qqline(q$quantile_residual)
 plot(q$year,q$deviance,type='b',xlab='Measurement year',ylab='Deviance residual',main='Temporal pattern');abline(h=0,lty=2)
 plot(q$year,q$cooks,type='h',xlab='Measurement year',ylab="Cook's distance",main='Influence');abline(h=4/nrow(q),lty=2)
 acf(q$deviance,main='ACF by observed visits')
}
dev.off()
