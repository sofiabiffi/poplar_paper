# Original PAIC scale; retain June-August rainfall and temperature, no rescreening.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
out <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('absolute_weather_',n,'.csv')),row.names=FALSE)
dat <- readRDS(file.path(root,'results/models/weather_departure_models.rds'))$data
hybrids <- names(publication_hybrids);years <- sort(unique(dat$measurement_year))
# Fixed centring only, not residual standardisation or response detrending.
dat$temp_c <- dat$temperature-16;dat$rain_c <- dat$rainfall-2
fit_all <- function(d,degree=2) setNames(lapply(hybrids,function(h) {
  x <- d[d$hybrid_code==h,]
  f <- glm(if(degree==2) PAIC~age_c+I(age_c^2)+temp_c+rain_c else PAIC~age_c+temp_c+rain_c,data=x,family=Gamma('log'),control=glm.control(maxit=200))
  if(!f$converged || any(!is.finite(coef(f)))) stop('Unusable Gamma fit')
  f
}),hybrids)
fits <- fit_all(dat)
# Verify equivalence to fully interacting hybrid effects in a joint mean model.
joint <- glm(PAIC~hybrid_code*(age_c+I(age_c^2)+temp_c+rain_c),data=dat,family=Gamma('log'))
sep_pred <- numeric(nrow(dat))
for(h in hybrids) { ix <- which(dat$hybrid_code==h);sep_pred[ix] <- predict(fits[[h]],dat[ix,],type='response') }
stopifnot(max(abs(fitted(joint)-sep_pred))<1e-4)
reference <- data.frame(temp_c=mean(dat$temp_c),rain_c=mean(dat$rain_c))
grid <- expand.grid(hybrid_code=hybrids,term=c('temperature','rainfall'),x=seq(0,1,length.out=80),stringsAsFactors=FALSE)
grid$value <- ifelse(grid$term=='temperature',min(dat$temperature)+grid$x*diff(range(dat$temperature)),min(dat$rainfall)+grid$x*diff(range(dat$rainfall)))
# Fixed observed age distribution shared across hybrids. Original PAIC units.
newdata <- function() data.frame(age_c=sort(unique(dat$age_c)),temp_c=reference$temp_c,rain_c=reference$rain_c)
effects <- function(fs) do.call(rbind,lapply(hybrids,function(h) do.call(rbind,lapply(c('temperature','rainfall'),function(v) {
  low <- high <- newdata()
  if(v=='temperature') { low$temp_c <- reference$temp_c-.5;high$temp_c <- reference$temp_c+.5;term <- 'temp_c' }
  else { low$rain_c <- reference$rain_c-.5;high$rain_c <- reference$rain_c+.5;term <- 'rain_c' }
  a <- mean(predict(fs[[h]],low,type='response'));b <- mean(predict(fs[[h]],high,type='response'))
  data.frame(hybrid_code=h,hybrid=publication_labels(h),term=v,lower_weather=if(v=='temperature') mean(dat$temperature)-.5 else mean(dat$rainfall)*100-50,upper_weather=if(v=='temperature')mean(dat$temperature)+.5 else mean(dat$rainfall)*100+50,mean_low=a,mean_high=b,absolute_difference=b-a,percent_difference=100*expm1(coef(fs[[h]])[term]))
}))))
curve_predictions <- function(fs) {
  ans <- numeric(nrow(grid));age <- newdata()$age_c
  for(h in hybrids) {
    b <- coef(fs[[h]])
    age_mean <- mean(exp(b['(Intercept)']+b['age_c']*age+if('I(age_c^2)' %in% names(b))b['I(age_c^2)']*age^2 else 0))
    ix <- which(grid$hybrid_code==h)
    tc <- ifelse(grid$term[ix]=='temperature',grid$value[ix]-16,reference$temp_c)
    rc <- ifelse(grid$term[ix]=='rainfall',grid$value[ix]-2,reference$rain_c)
    ans[ix] <- age_mean*exp(b['temp_c']*tc+b['rain_c']*rc)
  }
  ans
}
point <- effects(fits);grid$mean <- curve_predictions(fits)
pairs <- combn(hybrids,2,simplify=FALSE)
differences <- function(e) unlist(lapply(c('temperature','rainfall'),function(v) {
  b <- setNames(e$absolute_difference[e$term==v],e$hybrid_code[e$term==v])
  setNames(vapply(pairs,function(p) b[p[2]]-b[p[1]],numeric(1)),vapply(pairs,function(p) paste(v,p[2],p[1],sep=':'),character(1)))
}))
pd <- differences(point)
B <- 1000;set.seed(20261021)
ba <- bp <- matrix(NA_real_,B,nrow(point));bd <- matrix(NA_real_,B,length(pd));bc <- matrix(NA_real_,B,nrow(grid))
for(i in seq_len(B)) {
  starts <- sample(seq_along(years),ceiling(length(years)/3),replace=TRUE)
  ix <- unlist(lapply(starts,function(s) ((s-1+0:2) %% length(years))+1))[seq_along(years)]
  d <- do.call(rbind,lapply(years[ix],function(y) dat[dat$measurement_year==y,]))
  f <- fit_all(d);e <- effects(f)
  ba[i,] <- e$absolute_difference;bp[i,] <- e$percent_difference;bd[i,] <- differences(e);bc[i,] <- curve_predictions(f)
}
stopifnot(all(is.finite(ba)),all(is.finite(bc)),all(is.finite(bd)))
point$lower <- apply(ba,2,quantile,.025);point$upper <- apply(ba,2,quantile,.975)
point$percent_lower <- apply(bp,2,quantile,.025);point$percent_upper <- apply(bp,2,quantile,.975)
grid$lower <- apply(bc,2,quantile,.025);grid$upper <- apply(bc,2,quantile,.975)
out(data.frame(hybrid_code=point$hybrid_code,term=point$term,bootstrap_count=B,count_abs_effect_above_10=colSums(abs(ba)>10),maximum_absolute_effect=apply(abs(ba),2,max)),'bootstrap_tail_audit')
parts <- strsplit(names(pd),':',fixed=TRUE)
contrasts <- data.frame(term=vapply(parts,`[`,character(1),1),hybrid_code_1=vapply(parts,`[`,character(1),2),hybrid_code_2=vapply(parts,`[`,character(1),3),difference=as.numeric(pd),lower=apply(bd,2,quantile,.025),upper=apply(bd,2,quantile,.975))
contrasts$hybrid_1 <- publication_labels(contrasts$hybrid_code_1);contrasts$hybrid_2 <- publication_labels(contrasts$hybrid_code_2)
contrasts$interval_excludes_zero <- contrasts$lower*contrasts$upper>0
out(point,'adjusted_differences');out(contrasts,'paired_differences');out(grid,'curves')
linear <- effects(fit_all(dat,1));out(linear,'linear_age_sensitivity')
coeff <- do.call(rbind,lapply(hybrids,function(h) data.frame(hybrid_code=h,hybrid=publication_labels(h),term=names(coef(fits[[h]])),estimate=coef(fits[[h]]))))
out(coeff,'coefficients')
diag <- dat[c('measurement_year','hybrid_code','hybrid','PAIC')];diag$fitted <- sep_pred
diag$deviance_residual <- NA_real_
for(h in hybrids)diag$deviance_residual[diag$hybrid_code==h] <- residuals(fits[[h]],type='deviance')
out(diag,'diagnostics')
saveRDS(list(fits=fits,joint=joint,data=dat,reference=reference,effects=point,contrasts=contrasts,bootstrap_effects=ba,bootstrap_percent=bp,bootstrap_differences=bd),file.path(root,'results/models/absolute_weather_paic.rds'))
grid$predictor <- factor(grid$term,levels=c('rainfall','temperature'),labels=c('June-August rainfall (100 mm)','June-August mean air temperature (degrees C)'))
a <- ggplot(grid,aes(value,mean,colour=hybrid_code,fill=hybrid_code,linetype=hybrid_code))+
  geom_ribbon(aes(ymin=lower,ymax=upper),alpha=.10,colour=NA)+geom_line(linewidth=.8)+facet_wrap(~predictor,scales='free_x',ncol=2)+publication_scales(hybrids,'Hybrid',include_fill=TRUE)[c(1,3,4)]+
  labs(title='Summer weather associations on the PAIC scale',x=NULL,y=expression(PAIC~(Mg~C~ha^{-1}~yr^{-1})),caption='Gamma(log) models include hybrid-specific quadratic age trajectories and weather slopes.\nCurves average over the same 26 observed ages; the other weather predictor is held at its mean.\nPointwise 95% intervals: 1,000 paired three-visit block bootstrap samples. Exploratory after weather screening.')+theme_publication(11)
point$predictor <- factor(point$term,levels=c('rainfall','temperature'),labels=c('Rainfall increase of 100 mm','Temperature increase of 1 degree C'))
b <- ggplot(point,aes(absolute_difference,hybrid_code,colour=hybrid_code,shape=hybrid_code))+
  geom_vline(xintercept=0,linetype=2,colour='grey60')+geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.15)+geom_point(size=3)+facet_wrap(~predictor,ncol=2)+publication_scales(hybrids,'Hybrid')[1:2]+scale_y_discrete(limits=rev(hybrids),labels=publication_labels)+
  labs(title='Adjusted absolute differences in carbon increment',x=expression(Delta~PAIC~(Mg~C~ha^{-1}~yr^{-1})),y=NULL,caption='Contrasts span mean temperature +/-0.5 degree C or mean rainfall +/-50 mm; other weather at its mean.\nAverage over a common observed age distribution. Pointwise 95% block-bootstrap intervals shown.\nDirect hybrid comparisons use paired percentile intervals; exploratory after screening, not causal.')+theme_publication(11)+theme(legend.position='none')
for(n in c('curves','differences')) {
  p <- if(n=='curves') a else b;stem <- file.path(root,'results/figures',paste0('absolute_weather_',n))
  save_publication_plot(p,stem,width=10,height=5.7)
  ggsave(paste0(stem,'_preview.png'),p,width=10,height=5.7,dpi=140,bg='white')
}
print(point);print(contrasts);print(linear)
