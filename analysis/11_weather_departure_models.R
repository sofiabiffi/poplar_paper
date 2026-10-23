# Exploratory, post-screen candidate comparison. Fold-wise detrending prevents
# preprocessing leakage but does not undo earlier full-data predictor screening.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
save_table <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('weather_departure_model_',n,'.csv')),row.names=FALSE)
raw <- read.csv(file.path(root,'results/tables/growth_by_year_hybrid.csv'))
raw <- subset(raw,metric=='PAIC' & is.finite(median) & median>0)
raw$PAIC <- raw$median
w <- read.csv(file.path(root,'data/processed/weather_windows.csv'))
w <- subset(w,weather_period=='summer' & calendar_complete & n_valid_temp==n_days_expected & n_valid_rainfall==n_days_expected)
weather <- data.frame(measurement_year=w$measurement_year,temperature=w$temp,rainfall=w$rainfall/100)
dat <- merge(raw,weather,by='measurement_year')
cnt <- table(dat$measurement_year);dat <- dat[dat$measurement_year %in% names(cnt)[cnt==4],]
dat <- dat[order(dat$measurement_year,dat$hybrid_code),]
dat$age_c <- (dat$age_years-15)/10
years <- sort(unique(dat$measurement_year))
formulas <- list(Baseline=shared~1,Rainfall=shared~rainfall,Temperature=shared~temperature,Both=shared~rainfall+temperature)
# Every fold estimates each hybrid trend and residual SD on training years only.
depart <- function(train,test,degree=2) {
  trendform <- if(degree==2) log(PAIC)~age_c+I(age_c^2) else log(PAIC)~age_c
  train$z <- test$z <- NA_real_
  audit <- list()
  for(h in names(publication_hybrids)) {
    i <- which(train$hybrid_code==h);j <- which(test$hybrid_code==h)
    f <- lm(trendform,data=train[i,]);s <- sd(residuals(f))
    stopifnot(is.finite(s),s>0)
    train$z[i] <- residuals(f)/s
    test$z[j] <- (log(test$PAIC[j])-predict(f,newdata=test[j,]))/s
    audit[[h]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),training_n=length(i),residual_sd=s)
  }
  agg <- function(d) {
    a <- aggregate(z~measurement_year+temperature+rainfall,d,mean);names(a)[names(a)=='z'] <- 'shared';a
  }
  list(train=agg(train),test=agg(test),audit=do.call(rbind,audit))
}
blocks <- split(years,cut(seq_along(years),breaks=5,labels=FALSE))
schemes <- list('Leave one year out'=as.list(years),'Five contiguous blocks'=blocks)
predictions <- list();audits <- list()
for(degree in c(2,1)) for(scheme in names(schemes)) for(i in seq_along(schemes[[scheme]])) {
  held <- schemes[[scheme]][[i]]
  tr <- dat[!dat$measurement_year %in% held,];te <- dat[dat$measurement_year %in% held,]
  stopifnot(!any(tr$measurement_year %in% te$measurement_year))
  z <- depart(tr,te,degree)
  audits[[paste(degree,scheme,i)]] <- data.frame(degree=degree,scheme=scheme,fold=i,z$audit,held_out_years=paste(held,collapse=','))
  for(n in names(formulas)) {
    f <- lm(formulas[[n]],data=z$train)
    p <- predict(f,newdata=z$test)
    predictions[[paste(degree,scheme,i,n)]] <- data.frame(degree=degree,scheme=scheme,fold=i,model=n,measurement_year=z$test$measurement_year,observed=z$test$shared,predicted=p)
  }
}
cv <- do.call(rbind,predictions);stopifnot(all(is.finite(cv$predicted)),!anyDuplicated(cv[c('degree','scheme','model','measurement_year')]))
metrics <- do.call(rbind,lapply(split(cv,interaction(cv$degree,cv$scheme,cv$model,drop=TRUE)),function(d) data.frame(degree=d$degree[1],scheme=d$scheme[1],model=d$model[1],n=nrow(d),RMSE=sqrt(mean((d$observed-d$predicted)^2)),MAE=mean(abs(d$observed-d$predicted)))))
metrics$RMSE_improvement_percent <- vapply(seq_len(nrow(metrics)),function(i) {
  b <- metrics$RMSE[metrics$degree==metrics$degree[i] & metrics$scheme==metrics$scheme[i] & metrics$model=='Baseline']
  100*(1-metrics$RMSE[i]/b)
},numeric(1))
save_table(cv,'held_out_predictions');save_table(metrics,'validation');save_table(do.call(rbind,audits),'fold_audit')
full <- depart(dat,dat,2)
fits <- lapply(formulas,function(f) lm(f,data=full$train))
coefs <- do.call(rbind,lapply(names(fits),function(n) {
  ct <- coef(summary(fits[[n]]));ci <- confint(fits[[n]])
  data.frame(model=n,term=rownames(ct),estimate=ct[,1],std_error=ct[,2],lower=ci[,1],upper=ci[,2],in_sample_R2=summary(fits[[n]])$r.squared)
}))
save_table(coefs,'coefficients');save_table(full$train,'full_data_shared_signal')
saveRDS(list(fits=fits,data=dat,full_departures=full,validation=cv,metrics=metrics),file.path(root,'results/models/weather_departure_models.rds'))
curves <- list()
for(v in c('rainfall','temperature')) {
  nd <- data.frame(rainfall=mean(full$train$rainfall),temperature=mean(full$train$temperature))[rep(1,100),]
  nd[[v]] <- seq(min(full$train[[v]]),max(full$train[[v]]),length.out=100)
  p <- predict(fits$Both,newdata=nd,interval='confidence')
  curves[[v]] <- data.frame(variable=v,x=nd[[v]],p)
}
curve <- do.call(rbind,curves);save_table(curve,'effect_curves')
effect <- function(v,title,xlab) ggplot(curve[curve$variable==v,],aes(x,fit))+
  geom_hline(yintercept=0,colour='grey65',linetype=2)+geom_ribbon(aes(ymin=lwr,ymax=upr),fill='#56B4E9',alpha=.3)+geom_line(colour='#0072B2',linewidth=.8)+
  geom_rug(data=full$train,aes(x=.data[[v]]),inherit.aes=FALSE,colour='grey45')+
  labs(title=title,x=xlab,y='Shared standardised PAIC departure')+theme_publication(11)
a <- effect('rainfall','A  Summer rainfall','June-August rainfall (100 mm)')
b <- effect('temperature','B  Summer temperature','June-August mean air temperature (degrees C)')
m <- metrics[metrics$degree==2,];m$model <- factor(m$model,levels=names(formulas),labels=c('No weather','Rainfall','Temperature','Both'))
c <- ggplot(m,aes(model,RMSE,colour=scheme,shape=scheme,group=scheme))+geom_line(linewidth=.6)+geom_point(size=3)+
  scale_colour_manual(values=c('Leave one year out'='#0072B2','Five contiguous blocks'='#D55E00'),name=NULL)+
  scale_shape_manual(values=c('Leave one year out'=16,'Five contiguous blocks'=17),name=NULL)+
  labs(title='C  Prediction of held-out shared departures',subtitle='Lower error is better; age trends and standardisation refitted within every training fold',x=NULL,y='Held-out RMSE (standardised units)')+theme_publication(11)
draw <- function() {
  grid::grid.newpage();grid::pushViewport(grid::viewport(layout=grid::grid.layout(3,2,heights=grid::unit(c(4,3,1),'null'))))
  print(a,vp=grid::viewport(layout.pos.row=1,layout.pos.col=1));print(b,vp=grid::viewport(layout.pos.row=1,layout.pos.col=2));print(c,vp=grid::viewport(layout.pos.row=2,layout.pos.col=1:2))
  grid::grid.text(sprintf('EXPLORATORY POST-SCREEN COMPARISON | %d measurement years; tree medians; equal hybrid weights.\nCurves: combined weather model, other predictor at its mean; 95%% mean intervals conditional on full-data detrending.\nValidation prevents detrending leakage but does not remove optimism from prior full-data weather screening.\nFold targets use training-estimated age trajectories and residual SDs. Multi-year PAIC retains t - 1 weather alignment.',length(years)),x=.02,just='left',gp=grid::gpar(fontsize=9),vp=grid::viewport(layout.pos.row=3,layout.pos.col=1:2))
}
stem <- file.path(root,'results/figures/weather_departure_models')
png(paste0(stem,'.png'),width=11,height=8.5,units='in',res=600);draw();dev.off()
pdf(paste0(stem,'.pdf'),width=11,height=8.5,useDingbats=FALSE);draw();dev.off()
png(paste0(stem,'_preview.png'),width=1430,height=1105,res=130);draw();dev.off()
stopifnot(all(metrics$n==length(years)))
print(metrics);print(coefs)
