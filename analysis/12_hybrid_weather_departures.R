# Exploratory hybrid slope comparison, paired by measurement year.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
out <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('hybrid_weather_',n,'.csv')),row.names=FALSE)
obj <- readRDS(file.path(root,'results/models/weather_departure_models.rds'))
dat <- obj$data;years <- sort(unique(dat$measurement_year));hybrids <- names(publication_hybrids)
fit_all <- function(d,degree=2,standardise=TRUE) {
  rows <- list();coefs <- list()
  for(h in hybrids) {
    x <- d[d$hybrid_code==h,]
    trend <- lm(if(degree==2) log(PAIC)~age_c+I(age_c^2) else log(PAIC)~age_c,data=x)
    x$departure <- residuals(trend)/if(standardise) sd(residuals(trend)) else 1
    f <- lm(departure~rainfall+temperature,data=x)
    x$fitted_departure <- fitted(f);x$weather_residual <- residuals(f)
    rows[[h]] <- x
    coefs[[h]] <- data.frame(hybrid_code=h,hybrid=publication_labels(h),term=c('rainfall','temperature'),estimate=coef(f)[c('rainfall','temperature')],R2=summary(f)$r.squared)
  }
  list(data=do.call(rbind,rows),slopes=do.call(rbind,coefs))
}
full <- fit_all(dat)
joint <- lm(departure~hybrid_code*(rainfall+temperature),data=full$data)
stopifnot(max(abs(fitted(joint)-full$data$fitted_departure))<1e-8)
pairs <- combn(hybrids,2,simplify=FALSE)
diffs <- function(slopes) unlist(lapply(c('rainfall','temperature'),function(v) {
  b <- setNames(slopes$estimate[slopes$term==v],slopes$hybrid_code[slopes$term==v])
  setNames(vapply(pairs,function(p) b[p[2]]-b[p[1]],numeric(1)),vapply(pairs,function(p) paste(v,p[2],p[1],sep=':'),character(1)))
}))
point <- diffs(full$slopes)
set.seed(20261020);B <- 1000
boot_slopes <- matrix(NA_real_,B,nrow(full$slopes));boot_diff <- matrix(NA_real_,B,length(point))
for(i in seq_len(B)) {
  # Paired circular moving blocks of three ordered observations preserve short
  # temporal dependence. Gaps remain: blocks are visits, not three calendar years.
  starts <- sample(seq_along(years),ceiling(length(years)/3),replace=TRUE)
  indices <- unlist(lapply(starts,function(s) ((s-1+0:2) %% length(years))+1))[seq_along(years)]
  draw <- years[indices]
  d <- do.call(rbind,lapply(draw,function(y) dat[dat$measurement_year==y,]))
  z <- fit_all(d)
  boot_slopes[i,] <- z$slopes$estimate;boot_diff[i,] <- diffs(z$slopes)
}
stopifnot(all(is.finite(boot_diff)),all(is.finite(boot_slopes)))
slopes <- full$slopes
slopes$lower <- apply(boot_slopes,2,quantile,.025);slopes$upper <- apply(boot_slopes,2,quantile,.975)
se <- apply(boot_diff,2,sd)
centred <- sweep(sweep(boot_diff,2,point,'-'),2,se,'/')
critical <- quantile(apply(abs(centred),1,max),.95)
parts <- strsplit(names(point),':',fixed=TRUE)
contrasts <- data.frame(term=vapply(parts,`[`,character(1),1),hybrid_code_1=vapply(parts,`[`,character(1),2),hybrid_code_2=vapply(parts,`[`,character(1),3),difference=as.numeric(point),lower=point-critical*se,upper=point+critical*se)
contrasts$hybrid_1 <- publication_labels(contrasts$hybrid_code_1);contrasts$hybrid_2 <- publication_labels(contrasts$hybrid_code_2)
contrasts$interval_excludes_zero <- contrasts$lower*contrasts$upper>0
out(slopes,'slopes');out(contrasts,'paired_slope_differences');out(full$data[c('measurement_year','hybrid_code','PAIC','departure','fitted_departure','weather_residual')],'fitted_departures')
linear <- fit_all(dat,1)$slopes;linear$detrending <- 'Linear'
raw_log <- fit_all(dat,2,FALSE)$slopes;raw_log$detrending <- 'Quadratic without residual standardisation'
out(rbind(linear,raw_log),'sensitivity_slopes')
influence <- do.call(rbind,lapply(years,function(y) {
  z <- fit_all(dat[dat$measurement_year!=y,])$slopes
  z$omitted_year <- y;z
}))
out(influence,'omit_year_slopes')
# Residual correlation is descriptive; irregular gaps are retained and flagged.
resdiag <- do.call(rbind,lapply(hybrids,function(h) {
  x <- full$data[full$data$hybrid_code==h,];x <- x[order(x$measurement_year),]
  consecutive <- which(diff(x$measurement_year)==1)
  data.frame(hybrid_code=h,hybrid=publication_labels(h),R2=slopes$R2[slopes$hybrid_code==h][1],consecutive_pairs=length(consecutive),residual_lag1_r=cor(x$weather_residual[consecutive],x$weather_residual[consecutive+1]))
}))
out(resdiag,'residual_summary')
saveRDS(list(joint=joint,full=full,slopes=slopes,contrasts=contrasts,bootstrap_slopes=boot_slopes,bootstrap_differences=boot_diff,simultaneous_critical=critical),file.path(root,'results/models/hybrid_weather_departures.rds'))
plotdat <- rbind(transform(full$data,value=departure,series='Observed departure'),transform(full$data,value=fitted_departure,series='Weather fitted'))
plotdat$hybrid <- factor(publication_labels(plotdat$hybrid_code),levels=unname(publication_hybrids))
a <- ggplot(plotdat,aes(measurement_year,value,colour=series,shape=series,linetype=series))+
  geom_hline(yintercept=0,colour='grey80')+geom_line(linewidth=.6)+geom_point(size=1.6)+facet_wrap(~hybrid,ncol=2)+
  scale_colour_manual(values=c('Observed departure'='#0072B2','Weather fitted'='#D55E00'),name=NULL)+scale_shape_manual(values=c('Observed departure'=16,'Weather fitted'=17),name=NULL)+scale_linetype_manual(values=c('Observed departure'='solid','Weather fitted'='dashed'),name=NULL)+
  labs(title='Observed and summer weather fitted growth departures',x='Measurement year',y='Standardised log PAIC departure',caption='Separate quadratic age trends removed; weather model includes June-August rainfall and temperature.\nFits use all observed data and are descriptive, not held-out predictions. Missing years are not imputed.')+theme_publication(11)
slopes$hybrid_code <- factor(slopes$hybrid_code,levels=rev(hybrids))
slopes$predictor <- factor(slopes$term,levels=c('rainfall','temperature'),labels=c('Rainfall per 100 mm','Temperature per degree C'))
b <- ggplot(slopes,aes(estimate,hybrid_code,colour=hybrid_code,shape=hybrid_code))+
  geom_vline(xintercept=0,colour='grey65',linetype=2)+geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.15)+geom_point(size=3)+facet_wrap(~predictor,ncol=2)+
  publication_scales(hybrids,'Hybrid')[1:2]+scale_y_discrete(labels=publication_labels)+
  labs(title='Summer weather associations by hybrid',x='Change in standardised departure',y=NULL,caption='Pointwise 95% intervals: 1,000 paired bootstrap samples of three-visit blocks; trends and scales refitted.\nSlope differences assessed with simultaneous approximate bootstrap intervals across all 12 pairwise contrasts.\nBlocks follow observed visits across gaps. Exploratory; slopes are relative to each hybrid\'s variability.')+theme_publication(11)+theme(legend.position='none')
for(n in c('time_series','slopes')) {
  p <- if(n=='time_series') a else b
  stem <- file.path(root,'results/figures',paste0('hybrid_weather_',n))
  save_publication_plot(p,stem,width=10,height=if(n=='time_series')7 else 5)
  ggsave(paste0(stem,'_preview.png'),p,width=10,height=if(n=='time_series')7 else 5,dpi=140,bg='white')
}
print(slopes);print(contrasts);print(resdiag)
