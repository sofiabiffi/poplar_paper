# Current explanatory workflow: original PAIC with hybrid-specific quadratic age.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
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
  coefs[[id]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),age_model=age,weather_model=weather,term=names(coef(f)),estimate=coef(f))
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
# Paired three-visit bootstrap across all four hybrid models.
# Extreme resampled effects, if any, are audited rather than removed.
B <- 1000;set.seed(20261022);boot <- matrix(NA_real_,B,nrow(effects));failures <- 0L
for(i in seq_len(B)) {
  starts <- sample(seq_along(years),ceiling(length(years)/3),replace=TRUE)
  ix <- unlist(lapply(starts,function(s)((s-1+0:2)%%length(years))+1))[seq_along(years)]
  d <- do.call(rbind,lapply(years[ix],function(y)dat[dat$measurement_year==y,]))
  for(h in hybrids)for(age in ages) {
    at <- which(effects$hybrid_code==h & effects$age_model==age)
    f <- tryCatch(suppressWarnings(fit(d[d$hybrid_code==h,],age)),error=function(e)NULL)
    if(is.null(f)){failures<-failures+1L;next}
    e <- effect(f,h,age);boot[i,at] <- e$difference
  }
}
effects$n_boot <- colSums(is.finite(boot))
stopifnot(all(effects$n_boot>=990))
effects$lower <- apply(boot,2,quantile,.025,na.rm=TRUE);effects$upper <- apply(boot,2,quantile,.975,na.rm=TRUE)
out(effects,'absolute_effects')
tail_audit <- effects[c('hybrid_code','hybrid','age_model','predictor','n_boot')]
tail_audit$above_10_absolute <- colSums(abs(boot)>10,na.rm=TRUE);tail_audit$maximum <- apply(abs(boot),2,max,na.rm=TRUE)
out(tail_audit,'bootstrap_tail_audit')
contrast <- list()
for(age in ages)for(v in c('Temperature','Rainfall'))for(pair in combn(hybrids,2,simplify=FALSE)) {
  a <- which(effects$hybrid_code==pair[1] & effects$age_model==age & effects$predictor==v)
  b <- which(effects$hybrid_code==pair[2] & effects$age_model==age & effects$predictor==v)
  db <- boot[,b]-boot[,a]
  contrast[[paste(age,v,paste(pair,collapse=''))]] <- data.frame(age_model=age,predictor=v,hybrid_code_1=pair[2],hybrid_1=publication_labels(pair[2]),hybrid_code_2=pair[1],hybrid_2=publication_labels(pair[1]),difference=effects$difference[b]-effects$difference[a],lower=quantile(db,.025,na.rm=TRUE),upper=quantile(db,.975,na.rm=TRUE))
}
out(do.call(rbind,contrast),'paired_hybrid_differences')
influence <- list()
for(y in years)for(h in hybrids)for(age in ages) {
  f <- fit(dat[dat$measurement_year!=y & dat$hybrid_code==h,],age)
  influence[[paste(y,h,age)]] <- data.frame(omitted_year=y,effect(f,h,age))
}
out(do.call(rbind,influence),'year_omission_effects')
# Final figures use raw PAIC and a single quadratic-age specification.
labels <- c(spring_rainfall='Spring rainfall',summer_rainfall='Summer rainfall',spring_sunshine='Spring sunshine',summer_sunshine='Summer sunshine',spring_temp='Spring air temperature',summer_temp='Summer air temperature',dry_spell='Longest dry spell',spring_air_frost_days='Spring air frost days',spring_ground_frost_days='Spring ground frost days')
common_cor$id <- factor(common_cor$id,levels=rev(names(labels)),labels=rev(unname(labels)))
common_cor$hybrid <- factor(common_cor$hybrid,levels=unname(publication_hybrids))
a <- ggplot(common_cor,aes(hybrid,id,fill=pearson_r))+geom_tile(colour='white',linewidth=.6)+geom_text(aes(label=sprintf('%.2f',pearson_r)),size=3.5)+
  scale_fill_gradient2(low='#2166AC',mid='white',high='#B35806',limits=c(-1,1),name='Pearson r')+
  labs(title='Weather associations with original PAIC',x=NULL,y=NULL,caption='Descriptive raw correlations on 24 common complete-weather measurement years. No age removal or standardisation.\nNine hypothesis-guided candidates; correlations are not the sole model-selection rule and may reflect temporal trends.')+theme_publication(11)+theme(axis.line=element_blank(),axis.ticks=element_blank())
source('poplar_paper/analysis/14_raw_paic_weather_figures.R')
saveRDS(list(fits=fits,data=dat,effects=effects,bootstrap=boot,comparison=comparison,age_shapes=age_shapes,failed_bootstrap_fits=failures),file.path(root,'results/models/final_raw_paic_weather.rds'))
stopifnot(nrow(dat)==104,nrow(comparison)==16,nrow(effects)==8,nrow(raw_cor)==36,nrow(common_cor)==36)
cat('Failed bootstrap model fits:',failures,'\n');print(effects)
print(comparison[comparison$weather_model=='Both',])
