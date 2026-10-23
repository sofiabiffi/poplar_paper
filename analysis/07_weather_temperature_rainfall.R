# Run from workspace root: Rscript --vanilla poplar_paper/analysis/07_weather_temperature_rainfall.R
.libPaths(c('poplar_paper/renv/library', .libPaths()))
library(ggplot2)
library(lme4)
source('plot_style.R')
root <- 'poplar_paper'
prefix <- 'weather_temperature_rainfall_'
table_out <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0(prefix,n,'.csv')),row.names=FALSE)
raw <- read.csv(file.path(root,'data/processed/growth_weather.csv'))
needed <- c('PAIC','age_years','summerhalf_temp','summerhalf_rainfall')
keep <- complete.cases(raw[needed]) & raw$PAIC>0
valid_years <- names(which(tapply(keep,raw$measurement_year,function(z) length(z)==4 && all(z))))
dat <- raw[raw$measurement_year %in% valid_years,]
dat$hybrid_code <- factor(dat$hybrid_code,levels=names(publication_hybrids))
dat$year_group <- factor(dat$measurement_year)
# Fixed reference centre: no estimated preprocessing leaks into held-out years.
dat$age_c <- (dat$age_years-15)/10
dat$temperature <- dat$summerhalf_temp-13
dat$rainfall <- (dat$summerhalf_rainfall-400)/100
dat$winter_temperature <- dat$winter_temp-5
formulas <- list(Baseline=PAIC~hybrid_code*(age_c+I(age_c^2))+(1|year_group),
  Weather=PAIC~hybrid_code*(age_c+I(age_c^2))+temperature+rainfall+(1|year_group),
  Hybrid_slopes=PAIC~hybrid_code*(age_c+I(age_c^2)+temperature+rainfall)+(1|year_group),
  Winter=PAIC~hybrid_code*(age_c+I(age_c^2))+temperature+rainfall+winter_temperature+(1|year_group))
fit_model <- function(f,d) glmer(f,data=d,family=Gamma('log'),nAGQ=1,
  control=glmerControl(optimizer='bobyqa',optCtrl=list(maxfun=100000,rhoend=1e-9),calc.derivs=TRUE))
predict_mean <- function(f,newdata) {
  # Integrate over the random intercept for an unseen year, rather than use BLUPs.
  exp(predict(f,newdata=newdata,re.form=NA,allow.new.levels=TRUE)+as.numeric(VarCorr(f)$year_group)/2)
}
gamma_deviance <- function(y,mu) 2*((y-mu)/mu-log(y/mu))
fits <- list(); cv <- list(); checks <- list()
run <- function(name) {
  cat('Fitting',name,'\n'); flush.console()
  f <- fit_model(formulas[[name]],dat)
  fits[[name]] <<- f
  checks[[name]] <<- data.frame(model=name,fold='full',singular=isSingular(f),message=paste(f@optinfo$conv$lme4$messages,collapse='; '))
  rows <- list()
  for(yr in sort(unique(dat$measurement_year))) {
    cat('  Held out',yr,'\n'); flush.console()
    train <- droplevels(dat[dat$measurement_year!=yr,]); test <- dat[dat$measurement_year==yr,]
    stopifnot(!any(train$measurement_year %in% test$measurement_year))
    fm <- fit_model(formulas[[name]],train)
    pred <- predict_mean(fm,test)
    stopifnot(all(is.finite(pred)),all(pred>0))
    rows[[as.character(yr)]] <- data.frame(model=name,measurement_year=yr,hybrid_code=test$hybrid_code,hybrid=publication_labels(test$hybrid_code),observed=test$PAIC,predicted=pred,deviance=gamma_deviance(test$PAIC,pred))
    checks[[paste(name,yr)]] <<- data.frame(model=name,fold=as.character(yr),singular=isSingular(fm),message=paste(fm@optinfo$conv$lme4$messages,collapse='; '))
  }
  cv[[name]] <<- do.call(rbind,rows)
}
reuse <- '--reuse' %in% commandArgs(trailingOnly=TRUE)
if(reuse) {
  saved <- readRDS(file.path(root,'results/models/weather_temperature_rainfall.rds'))
  fits <- saved$models;cv <- split(saved$validation,saved$validation$model)
} else { run('Baseline'); run('Weather') }
metric <- function(z) data.frame(model=z$model[1],RMSE=sqrt(mean((z$observed-z$predicted)^2)),MAE=mean(abs(z$observed-z$predicted)),mean_gamma_deviance=mean(z$deviance))
main_metrics <- do.call(rbind,lapply(cv,metric))
# Explore extensions only if shared weather terms improve both primary metrics.
improves <- main_metrics$RMSE[2]<main_metrics$RMSE[1] && main_metrics$mean_gamma_deviance[2]<main_metrics$mean_gamma_deviance[1]
if(improves && !reuse) { run('Hybrid_slopes'); if(all(is.finite(dat$winter_temperature))) run('Winter') }
cv_all <- do.call(rbind,cv); metrics <- do.call(rbind,lapply(cv,metric))
table_out(metrics,'validation');table_out(cv_all,'held_out_predictions');if(!reuse) table_out(do.call(rbind,checks),'fit_checks')
table_out(dat[c('measurement_year','growth_year','hybrid_code','PAIC','age_years','interval_years','temperature','rainfall')],'analysis_data')
coeff <- do.call(rbind,lapply(names(fits),function(n) {
  ct <- coef(summary(fits[[n]])); data.frame(model=n,term=rownames(ct),estimate=ct[,1],std_error=ct[,2],lower=ct[,1]-1.96*ct[,2],upper=ct[,1]+1.96*ct[,2])
}))
table_out(coeff,'coefficients')
saveRDS(list(models=fits,data=dat,formulas=formulas,validation=cv_all),file.path(root,'results/models/weather_temperature_rainfall.rds'))
# Marginal effects at reference age, with other weather predictor at its mean.
f <- fits$Weather
curves <- list()
for(variable in c('temperature','rainfall')) for(h in levels(dat$hybrid_code)) {
  nd <- dat[rep(1,100),];nd$hybrid_code <- factor(h,levels=levels(dat$hybrid_code));nd$age_c <- 0
  nd$temperature <- mean(dat$temperature);nd$rainfall <- mean(dat$rainfall)
  nd[[variable]] <- seq(min(dat[[variable]]),max(dat[[variable]]),length.out=100)
  X <- model.matrix(delete.response(terms(reformulas::nobars(formula(f)))),nd)
  eta <- as.vector(X%*%fixef(f));se <- sqrt(rowSums((X%*%as.matrix(vcov(f)))*X))
  correction <- as.numeric(VarCorr(f)$year_group)/2
  curves[[paste(variable,h)]] <- data.frame(variable=variable,hybrid_code=h,x=nd[[variable]],mean=exp(eta+correction),lower=exp(eta+correction-1.96*se),upper=exp(eta+correction+1.96*se))
}
curves <- do.call(rbind,curves);table_out(curves,'effect_curves')
effect_plot <- function(variable,title,xlabel) {
  z <- curves[curves$variable==variable,]
  z$x <- z$x + if(variable=='temperature') 13 else 4
  ggplot(z,aes(x,mean,colour=hybrid_code,fill=hybrid_code,linetype=hybrid_code))+
    geom_ribbon(aes(ymin=lower,ymax=upper),alpha=.12,colour=NA)+geom_line(linewidth=.8)+
    publication_scales(levels(dat$hybrid_code),'Hybrid',include_fill=TRUE)[c(1,3,4)]+
    labs(title=title,x=xlabel,y=expression(PAIC~(Mg~C~ha^{-1}~yr^{-1})))+theme_publication(11)
}
a <- effect_plot('temperature','A  Growing-season temperature','April-September mean air temperature (degrees C)')
b <- effect_plot('rainfall','B  Growing-season rainfall','April-September rainfall (100 mm)')
by_year <- aggregate(deviance~model+measurement_year,cv_all,mean)
wide <- reshape(by_year,idvar='measurement_year',timevar='model',direction='wide')
changes <- do.call(rbind,lapply(setdiff(names(cv),'Baseline'),function(n) data.frame(measurement_year=wide$measurement_year,model=n,improvement=wide[['deviance.Baseline']]-wide[[paste0('deviance.',n)]])))
model_labels <- c(Weather='Temperature + rainfall',Hybrid_slopes='Hybrid-specific weather slopes',Winter='Temperature + rainfall + winter')
changes$model <- factor(changes$model,levels=names(model_labels),labels=unname(model_labels))
c <- ggplot(changes,aes(improvement,model))+geom_vline(xintercept=0,linetype=2,colour='grey50')+
  geom_point(alpha=.5,colour='#0072B2',position=position_jitter(height=.12,width=0,seed=42))+
  stat_summary(fun=mean,geom='point',shape=18,size=4,colour='#D55E00')+
  labs(title='C  Held-out-year improvement over the age baseline',subtitle='Each blue dot: one held-out year (all four hybrids); orange diamond: mean',x='Reduction in mean Gamma deviance (positive = improvement)',y=NULL)+theme_publication(11)
draw <- function() {
  grid::grid.newpage();grid::pushViewport(grid::viewport(layout=grid::grid.layout(3,2,heights=grid::unit(c(5,2.4,1.2),'null'))))
  print(a,vp=grid::viewport(layout.pos.row=1,layout.pos.col=1));print(b,vp=grid::viewport(layout.pos.row=1,layout.pos.col=2))
  print(c,vp=grid::viewport(layout.pos.row=2,layout.pos.col=1:2))
  grid::grid.text(sprintf('EXPLORATORY | %d measurement years; %d hybrid summaries. Gamma(log), hybrid-specific quadratic age trends, random year intercept.\nCurves: age 15; other weather variable at its mean; marginal over year effects. Shading: approximate 95%% fixed-effect intervals;\nvariance-component uncertainty excluded. Validation holds out whole years; assesses interpolation, not future forecasting.\nPAIC is annualised across sampling intervals; weather remains from year t - 1, including multi-year intervals.',length(unique(dat$measurement_year)),nrow(dat)),x=.02,just='left',gp=grid::gpar(fontsize=9),vp=grid::viewport(layout.pos.row=3,layout.pos.col=1:2))
}
stem <- file.path(root,'results/figures/weather_temperature_rainfall_draft')
png(paste0(stem,'.png'),width=12,height=9,units='in',res=600);draw();dev.off()
pdf(paste0(stem,'.pdf'),width=12,height=9,useDingbats=FALSE);draw();dev.off()
png(paste0(stem,'_preview.png'),width=1560,height=1170,res=130);draw();dev.off()
print(metrics);print(coeff[coeff$model=='Weather' & coeff$term %in% c('temperature','rainfall'),])
