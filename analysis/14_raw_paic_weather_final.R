# Current explanatory workflow: original PAIC with hybrid-specific quadratic age.
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args))normalizePath(args[1],winslash='/') else normalizePath('.',winslash='/')
.libPaths(c(file.path(root,'renv/library'),.libPaths()))
library(ggplot2)
source(file.path(root,'plot_style.R'))
out <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('final_weather_',n,'.csv')),row.names=FALSE)
raw <- read.csv(file.path(root,'results/tables/growth_by_year_hybrid.csv'))
raw <- subset(raw,metric=='PAIC' & is.finite(median) & median>0)
raw$PAIC <- raw$median
screen <- read.csv(file.path(root,'results/tables/weather_departure_screen_data.csv'))
screen <- screen[c('measurement_year','id','label','value','coverage','common_basis')]
long <- merge(raw[c('measurement_year','hybrid_code','hybrid','PAIC')],screen,by='measurement_year')
stopifnot(!anyDuplicated(long[c('measurement_year','hybrid_code','id')]))
corr <- function(d) {
  d <- d[is.finite(d$value),]
  r <- cor(d$PAIC,d$value)
  jack <- vapply(seq_len(nrow(d)),function(i) cor(d$PAIC[-i],d$value[-i]),numeric(1))
  data.frame(hybrid_code=d$hybrid_code[1],hybrid=d$hybrid[1],id=d$id[1],label=d$label[1],n=nrow(d),pearson_r=r,spearman_r=cor(d$PAIC,d$value,method='spearman'),omit_year_min=min(jack),omit_year_max=max(jack))
}
raw_cor <- do.call(rbind,lapply(split(long,interaction(long$hybrid_code,long$id,drop=TRUE)),corr))
common_cor <- do.call(rbind,lapply(split(long[long$common_basis,],interaction(long$hybrid_code[long$common_basis],long$id[long$common_basis],drop=TRUE)),corr))
out(raw_cor,'raw_correlations_available');out(common_cor,'raw_correlations_common');out(long,'raw_screen_data')
w <- read.csv(file.path(root,'data/processed/weather_windows.csv'))
w <- subset(w,weather_period=='summer' & calendar_complete & n_valid_temp==n_days_expected & n_valid_rainfall==n_days_expected)
dat <- merge(raw,w[c('measurement_year','growth_year','temp','rainfall')],by='measurement_year',suffixes=c('','_weather'))
cnt <- table(dat$measurement_year);dat <- dat[dat$measurement_year %in% names(cnt)[cnt==4],]
dat <- dat[order(dat$measurement_year,dat$hybrid_code),]
dat$age_c <- (dat$age_years-15)/10;dat$temp_c <- dat$temp-16;dat$rain_c <- (dat$rainfall-200)/100
years <- sort(unique(dat$measurement_year));hybrids <- names(publication_hybrids)
ages <- 'Quadratic age';weathers <- c('No weather','Rainfall','Temperature','Both')
formula_for <- function(age,weather) {
  terms <- c('age_c','I(age_c^2)',if(weather %in% c('Rainfall','Both'))'rain_c',if(weather %in% c('Temperature','Both'))'temp_c')
  if(!length(terms)) PAIC~1 else reformulate(terms,'PAIC')
}
fit <- function(d,age,weather='Both') {
  f <- glm(formula_for(age,weather),data=d,family=Gamma('log'),control=glm.control(maxit=200))
  if(!f$converged || any(!is.finite(coef(f)))) stop('Gamma model did not converge')
  f
}
fits <- list();comparison <- list();coefs <- list();diagnostics <- list()
for(h in hybrids) for(age in ages) for(weather in weathers) {
  d <- dat[dat$hybrid_code==h,];id <- paste(h,age,weather,sep='|');f <- fit(d,age,weather)
  fits[[id]] <- f;k <- attr(logLik(f),'df');n <- nrow(d)
  comparison[[id]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),age_model=age,weather_model=weather,n=n,k=k,AICc=AIC(f)+2*k*(k+1)/(n-k-1),deviance=f$deviance,null_deviance=f$null.deviance,dispersion=summary(f)$dispersion)
  sm <- coef(summary(f))
  coefs[[id]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),age_model=age,weather_model=weather,term=rownames(sm),estimate=sm[,1],standard_error=sm[,2],t_statistic=sm[,3],p_value=sm[,4])
  if(weather=='Both')diagnostics[[id]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),age_model=age,measurement_year=d$measurement_year,PAIC=d$PAIC,fitted=fitted(f),deviance_residual=residuals(f,type='deviance'),cooks_distance=cooks.distance(f))
}
comparison <- do.call(rbind,comparison)
comparison$deviance_reduction_vs_same_age <- vapply(seq_len(nrow(comparison)),function(i) {
  z <- comparison[i,];base <- subset(comparison,hybrid_code==z$hybrid_code & age_model==z$age_model & weather_model=='No weather')
  1-z$deviance/base$deviance
},numeric(1))
comparison$delta_AICc_within_hybrid <- ave(comparison$AICc,comparison$hybrid_code,FUN=function(x)x-min(x))
comparison$deviance_pseudo_R2 <- 1-comparison$deviance/comparison$null_deviance
out(comparison,'candidate_models');out(do.call(rbind,coefs),'coefficients');out(do.call(rbind,diagnostics),'diagnostics')
ref_temp <- mean(dat$temp_c);ref_rain <- mean(dat$rain_c);age_reference <- sort(unique(dat$age_c))
effect <- function(f,h,age) {
  nd <- data.frame(age_c=age_reference,temp_c=ref_temp,rain_c=ref_rain)
  baseline <- predict(f,nd,type='response')
  do.call(rbind,lapply(c('Temperature','Rainfall'),function(v) {
    b <- unname(coef(f)[if(v=='Temperature')'temp_c' else 'rain_c'])
    low <- mean(baseline)*exp(-b/2);high <- mean(baseline)*exp(b/2)
    data.frame(hybrid_code=h,hybrid=publication_labels(h),age_model=age,predictor=v,low_mean=low,high_mean=high,difference=high-low)
  }))
}
effects <- do.call(rbind,lapply(hybrids,function(h)do.call(rbind,lapply(ages,function(age)effect(fits[[paste(h,age,'Both',sep='|')]],h,age)))))
# Model-based SE of absolute response-scale contrasts by the delta method.
# Use the full within-model coefficient covariance, not just the weather slope SE.
delta_audit <- list()
for(i in seq_len(nrow(effects))) {
  h <- effects$hybrid_code[i]; v <- effects$predictor[i]
  f <- fits[[paste(h,ages,'Both',sep='|')]]
  term <- if(v=='Temperature')'temp_c' else 'rain_c'
  lo <- hi <- data.frame(age_c=age_reference,temp_c=ref_temp,rain_c=ref_rain)
  lo[[term]] <- lo[[term]]-.5; hi[[term]] <- hi[[term]]+.5
  xl <- model.matrix(delete.response(terms(f)),lo)
  xh <- model.matrix(delete.response(terms(f)),hi)
  ml <- drop(exp(xl %*% coef(f))); mh <- drop(exp(xh %*% coef(f)))
  gradient <- colMeans(xh*mh-xl*ml)
  se <- sqrt(drop(t(gradient)%*%vcov(f)%*%gradient))
  # Verify the analytic derivative against central finite differences.
  fun <- function(b)mean(exp(xh%*%b)-exp(xl%*%b))
  numeric_gradient <- vapply(seq_along(coef(f)),function(j){
    bp <- bm <- coef(f);bp[j]<-bp[j]+1e-6;bm[j]<-bm[j]-1e-6
    (fun(bp)-fun(bm))/2e-6
  },numeric(1))
  stopifnot(abs(mean(mh-ml)-effects$difference[i])<1e-10,
            max(abs(gradient-numeric_gradient))<1e-6,is.finite(se),se>0)
  effects$standard_error[i] <- se
  delta_audit[[i]] <- data.frame(hybrid_code=h,predictor=v,
    maximum_gradient_difference=max(abs(gradient-numeric_gradient)))
}
effects$lower <- effects$difference-effects$standard_error
effects$upper <- effects$difference+effects$standard_error
effects$uncertainty <- 'Estimate plus or minus one model-based SE (delta method)'
out(effects,'absolute_effects')
write.csv(do.call(rbind,delta_audit),file.path(root,'results/checks/weather_model_se_delta_audit.csv'),row.names=FALSE)
influence <- list()
for(y in years)for(h in hybrids)for(age in ages) {
  f <- fit(dat[dat$measurement_year!=y & dat$hybrid_code==h,],age)
  influence[[paste(y,h,age)]] <- data.frame(omitted_year=y,effect(f,h,age))
}
out(do.call(rbind,influence),'year_omission_effects')
# Current reporting figures: absolute summer associations and age supplement.
source(file.path(root,'analysis/14_raw_paic_weather_figures.R'))
saveRDS(list(fits=fits,data=dat,effects=effects,comparison=comparison,age_shapes=age_shapes,
  uncertainty='Conventional model SE; delta method for absolute contrasts'),
  file.path(root,'results/models/final_raw_paic_weather.rds'))
stopifnot(nrow(dat)==104,nrow(comparison)==16,nrow(effects)==8)
cat('Model-based standard errors; no bootstrap resampling.\n');print(effects)
print(comparison[comparison$weather_model=='Both',])
