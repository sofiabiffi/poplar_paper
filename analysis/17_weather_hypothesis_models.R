# Hypothesis comparison on identical years; run from the project or pass its path.
args <- commandArgs(trailingOnly=TRUE)
root <- if(length(args))normalizePath(args[1],winslash='/') else normalizePath('.',winslash='/')
.libPaths(c(file.path(root,'renv/library'),.libPaths()))
library(ggplot2)
source(file.path(root,'plot_style.R'))
out <- function(x,stem)write.csv(x,file.path(root,'results/tables',paste0('weather_hypothesis_',stem,'.csv')),row.names=FALSE)
raw <- read.csv(file.path(root,'results/tables/growth_by_year_hybrid.csv'))
raw <- subset(raw,metric=='PAIC' & is.finite(median) & median>0)
raw$PAIC <- raw$median
w <- read.csv(file.path(root,'results/tables/weather_departure_screen_data.csv'))
w <- unique(w[c('measurement_year','id','value','coverage')])
stopifnot(!anyDuplicated(w[c('measurement_year','id')]))
ids <- c('spring_rainfall','summer_rainfall','spring_temp','summer_temp','spring_sunshine','summer_sunshine','dry_spell','spring_air_frost_days','spring_ground_frost_days')
w <- w[w$id %in% ids,]
wide <- reshape(w[c('measurement_year','id','value')],idvar='measurement_year',timevar='id',direction='wide')
names(wide) <- sub('^value\\.','',names(wide))
complete <- complete.cases(wide[ids])
coverage_ok <- vapply(wide$measurement_year,function(y)all(w$coverage[w$measurement_year==y]==1),logical(1))
wide <- wide[complete & coverage_ok,]
dat <- merge(raw[c('measurement_year','growth_year','age_years','hybrid_code','hybrid','PAIC')],wide,by='measurement_year')
counts <- table(dat$measurement_year);dat <- dat[dat$measurement_year %in% names(counts)[counts==4],]
dat <- dat[order(dat$measurement_year,dat$hybrid_code),]
years <- sort(unique(dat$measurement_year));hybrids <- names(publication_hybrids)
stopifnot(length(years)==24,nrow(dat)==96,all(dat$growth_year==dat$measurement_year-1))
# The reporting summer model uses all 26 eligible summer years. Verify reuse.
existing <- readRDS(file.path(root,'results/models/final_raw_paic_weather.rds'))
audit <- merge(existing$data[c('measurement_year','hybrid_code','PAIC')],raw[c('measurement_year','hybrid_code','PAIC')],by=c('measurement_year','hybrid_code'),suffixes=c('_reporting','_current'))
stopifnot(nrow(audit)==104,max(abs(audit$PAIC_reporting-audit$PAIC_current))<1e-10)
weather_audit <- merge(dat,existing$data[c('measurement_year','hybrid_code','temp','rainfall')],by=c('measurement_year','hybrid_code'))
stopifnot(nrow(weather_audit)==96,max(abs(weather_audit$summer_temp-weather_audit$temp))<1e-8,max(abs(weather_audit$summer_rainfall-weather_audit$rainfall))<1e-8)
out(data.frame(check=c('Reporting PAIC matches current medians','Common summer temperature matches','Common summer rainfall matches'),maximum_absolute_difference=c(max(abs(audit$PAIC_reporting-audit$PAIC_current)),max(abs(weather_audit$summer_temp-weather_audit$temp)),max(abs(weather_audit$summer_rainfall-weather_audit$rainfall)))),'reporting_input_audit')
dat$age_c <- (dat$age_years-15)/10
# Fixed numerical scales; no response detrending or correlation-based exclusion.
for(v in c('spring_rainfall','summer_rainfall','spring_sunshine','summer_sunshine'))dat[[paste0(v,'_s')]] <- dat[[v]]/100
for(v in c('dry_spell','spring_air_frost_days','spring_ground_frost_days'))dat[[paste0(v,'_s')]] <- dat[[v]]/10
dat$spring_temp_s <- dat$spring_temp-9;dat$summer_temp_s <- dat$summer_temp-16
specs <- list(age_only=character(0),spring_conditions=c('spring_rainfall_s','spring_temp_s'),summer_conditions=c('summer_rainfall_s','summer_temp_s'),spring_light='spring_sunshine_s',summer_light='summer_sunshine_s',dry_spell='dry_spell_s',air_frost='spring_air_frost_days_s',ground_frost='spring_ground_frost_days_s')
labels <- c(age_only='Stand development alone',spring_conditions='Spring rainfall and temperature',summer_conditions='Summer rainfall and temperature',spring_light='Spring sunshine',summer_light='Summer sunshine',dry_spell='Longest dry spell',air_frost='Spring air frost',ground_frost='Spring ground frost')
form <- function(id)reformulate(c('age_c','I(age_c^2)',specs[[id]]),'PAIC')
fit <- function(d,id){f<-glm(form(id),data=d,family=Gamma('log'),control=glm.control(maxit=200));stopifnot(f$converged,all(is.finite(coef(f))));f}
aicc <- function(f){k<-attr(logLik(f),'df');n<-nobs(f);AIC(f)+2*k*(k+1)/(n-k-1)}
fits <- list();comparison <- list();diagnostics <- list();coefficients <- list()
for(h in hybrids)for(id in names(specs)) {
  d <- dat[dat$hybrid_code==h,];f <- fit(d,id);key<-paste(h,id,sep='|');fits[[key]]<-f
  comparison[[key]]<-data.frame(hybrid_code=h,hybrid=publication_labels(h),model_id=id,hypothesis=unname(labels[id]),n=nobs(f),k=attr(logLik(f),'df'),AICc=aicc(f),deviance=f$deviance,pseudo_R2=1-f$deviance/f$null.deviance)
  diagnostics[[key]]<-data.frame(hybrid_code=h,hybrid=publication_labels(h),model_id=id,measurement_year=d$measurement_year,PAIC=d$PAIC,fitted=fitted(f),deviance_residual=residuals(f,type='deviance'),cooks_distance=cooks.distance(f))
  coefficients[[key]]<-data.frame(hybrid_code=h,hybrid=publication_labels(h),model_id=id,term=names(coef(f)),estimate=coef(f))
}
comparison<-do.call(rbind,comparison)
comparison$delta_AICc<-ave(comparison$AICc,comparison$hybrid_code,FUN=function(x)x-min(x))
comparison$akaike_weight<-ave(exp(-.5*comparison$delta_AICc),comparison$hybrid_code,FUN=function(x)x/sum(x))
comparison$rank<-ave(comparison$AICc,comparison$hybrid_code,FUN=function(x)rank(x,ties.method='min'))
comparison$weather_deviance_reduction<-vapply(seq_len(nrow(comparison)),function(i){z<-comparison[i,];base<-subset(comparison,hybrid_code==z$hybrid_code & model_id=='age_only');1-z$deviance/base$deviance},numeric(1))
diagnostics<-do.call(rbind,diagnostics)
summary_checks<-do.call(rbind,lapply(split(diagnostics,interaction(diagnostics$hybrid_code,diagnostics$model_id)),function(d){d<-d[order(d$measurement_year),];ix<-which(diff(d$measurement_year)==1);data.frame(hybrid_code=d$hybrid_code[1],hybrid=d$hybrid[1],model_id=d$model_id[1],n_consecutive_pairs=length(ix),lag1=cor(d$deviance_residual[ix],d$deviance_residual[ix+1]),max_cooks=max(d$cooks_distance))}))
# Year omission is influence checking, not predictive validation or independent selection.
omission<-list()
for(y in years)for(h in hybrids) {
  values<-vapply(names(specs),function(id)aicc(fit(dat[dat$hybrid_code==h & dat$measurement_year!=y,],id)),numeric(1))
  omission[[paste(y,h)]]<-data.frame(omitted_year=y,hybrid_code=h,model_id=names(specs),AICc=values,delta_AICc=values-min(values),rank=rank(values,ties.method='min'))
}
omission<-do.call(rbind,omission)
comparison$omission_wins<-vapply(seq_len(nrow(comparison)),function(i){z<-comparison[i,];sum(omission$hybrid_code==z$hybrid_code & omission$model_id==z$model_id & omission$rank==1)},integer(1))
out(dat,'analysis_data');out(comparison,'comparison');out(diagnostics,'diagnostics');out(summary_checks,'residual_summary');out(do.call(rbind,coefficients),'coefficients');out(omission,'year_omission')
out(data.frame(model_id=names(specs),hypothesis=unname(labels),formula=vapply(names(specs),function(id)paste(deparse(form(id)),collapse=''),character(1))),'definitions')
plotdat<-comparison;plotdat$hypothesis<-factor(plotdat$hypothesis,levels=rev(unname(labels)));plotdat$hybrid<-factor(plotdat$hybrid,levels=unname(publication_hybrids))
threshold<-max(plotdat$delta_AICc)*.48
p<-ggplot(plotdat,aes(hybrid,hypothesis,fill=delta_AICc))+geom_tile(colour='white',linewidth=.7)+
  geom_text(aes(label=sprintf('%.1f',delta_AICc),colour=delta_AICc<threshold),size=3.7)+
  scale_fill_viridis_c(option='D',name=expression(Delta*AICc))+scale_colour_manual(values=c('TRUE'='white','FALSE'='black'),guide='none')+
  labs(x=NULL,y=NULL)+theme_publication(12)+theme(axis.line=element_blank(),axis.ticks=element_blank(),legend.position='bottom')
stem<-file.path(root,'results/figures/weather_hypothesis_comparison')
save_publication_plot(p,stem,width=9,height=6)
ggsave(paste0(stem,'_preview.png'),p,width=9,height=6,dpi=150,bg='white')
caption<-'Comparison of eight biologically motivated PAIC models, fitted separately for Beaupre, Gibecq, Robusta and Trichobel on the same 24 measurement years (96 hybrid summaries). All models use a Gamma log link and hybrid-specific linear and squared age terms. The weather hypotheses add the variables named in the rows; spring is March-May, summer June-August and dry spell April-September. Cell values are AICc minus the lowest AICc within that hybrid: zero identifies the best-fitting candidate after penalising complexity; values below about 2 indicate close competitors. The common-year set avoids comparing models on different responses. AICc and rankings are exploratory because residual temporal dependence remains, and candidate construction was informed by earlier examination of these data. Colours and displayed values encode the same quantity.'
dir.create(file.path(root,'results/figure_descriptions'),showWarnings=FALSE)
writeLines(caption,file.path(root,'results/figure_descriptions/weather_hypothesis_comparison.txt'))
saveRDS(list(data=dat,fits=fits,comparison=comparison,definitions=specs,residual_summary=summary_checks,omission=omission),file.path(root,'results/models/weather_hypothesis_models.rds'))
stopifnot(nrow(comparison)==32,nrow(omission)==768,all(comparison$n==24),all(is.finite(comparison$AICc)))
print(comparison[order(comparison$hybrid_code,comparison$rank),c('hybrid','hypothesis','AICc','delta_AICc','akaike_weight','pseudo_R2','omission_wins')],row.names=FALSE)
