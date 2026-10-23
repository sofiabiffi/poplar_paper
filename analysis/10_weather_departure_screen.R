# Exploratory screen only: no selected-model prediction claims or confirmatory p-values.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
save_table <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('weather_departure_',n,'.csv')),row.names=FALSE)
departures <- read.csv(file.path(root,'results/tables/paic_synchrony_departures.csv'))
primary <- subset(departures,source=='Tree medians')
years <- sort(unique(primary$measurement_year))
shared <- do.call(rbind,lapply(years,function(y) {
  d <- primary[primary$measurement_year==y,]
  data.frame(measurement_year=y,growth_year=y-1,age_years=d$age_years[1],shared_departure=mean(d$standardised_departure),linear_departure=mean(d$linear_residual / ave(primary$linear_residual,primary$hybrid_code,FUN=sd)[match(paste(d$measurement_year,d$hybrid_code),paste(primary$measurement_year,primary$hybrid_code))]))
}))
windows <- read.csv(file.path(root,'data/processed/weather_windows.csv'))
daily <- read.csv(file.path(root,'data/processed/weather_daily.csv')); daily$date <- as.Date(daily$date)
definitions <- data.frame(id=c('spring_rainfall','summer_rainfall','spring_sunshine','summer_sunshine','spring_temp','summer_temp','dry_spell','spring_air_frost_days','spring_ground_frost_days'),
  label=c('Spring rainfall (mm)','Summer rainfall (mm)','Spring sunshine (hours)','Summer sunshine (hours)','Spring air temperature (degrees C)','Summer air temperature (degrees C)','Apr-Sep longest dry spell (days)','Spring air frost (days)','Spring ground frost (days)'))
long <- list()
for(y in years) for(i in seq_len(nrow(definitions))) {
  id <- definitions$id[i]
  if(id=='dry_spell') {
    g <- y-1; expected_dates <- seq(as.Date(sprintf('%d-04-01',g)),as.Date(sprintf('%d-09-30',g)),by='day')
    rain <- daily$rainfall[match(expected_dates,daily$date)]
    coverage <- mean(is.finite(rain)); value <- NA_real_
    if(coverage==1) { runs <- rle(rain<1); value <- if(any(runs$values)) max(runs$lengths[runs$values]) else 0 }
  } else {
    period <- sub('_.*','',id);metric <- sub('^[^_]+_','',id)
    w <- windows[windows$measurement_year==y & windows$weather_period==period,]
    coverage <- w[[paste0('n_valid_',metric)]]/w$n_days_expected
    value <- if(isTRUE(w$calendar_complete) && coverage==1) w[[metric]] else NA_real_
  }
  long[[paste(y,id)]] <- data.frame(measurement_year=y,id=id,label=definitions$label[i],value=value,coverage=coverage)
}
long <- merge(do.call(rbind,long),shared,by='measurement_year')
complete_years <- years[vapply(years,function(y) all(is.finite(long$value[long$measurement_year==y])),logical(1))]
long$common_basis <- long$measurement_year %in% complete_years
save_table(long,'screen_data');save_table(shared,'shared_signal')
screen <- function(d) {
  d <- d[is.finite(d$value),]; a <- (d$age_years-15)/10
  xres <- resid(lm(d$value~a+I(a^2)));yres <- resid(lm(d$shared_departure~a+I(a^2)))
  r <- cor(d$value,d$shared_departure)
  jack <- vapply(seq_len(nrow(d)),function(i) cor(d$value[-i],d$shared_departure[-i]),numeric(1))
  data.frame(id=d$id[1],label=d$label[1],n=nrow(d),pearson_r=r,spearman_r=cor(d$value,d$shared_departure,method='spearman'),age_adjusted_r=cor(xres,yres),linear_detrending_r=cor(d$value,d$linear_departure),jackknife_min=min(jack),jackknife_max=max(jack),largest_influence_year=d$measurement_year[which.max(abs(jack-r))])
}
results <- do.call(rbind,lapply(definitions$id,function(id) screen(long[long$id==id & long$common_basis,])))
available <- do.call(rbind,lapply(definitions$id,function(id) screen(long[long$id==id,])))
save_table(results,'screen_common_years');save_table(available,'screen_available_years')
hybrid <- do.call(rbind,lapply(definitions$id,function(id) do.call(rbind,lapply(names(publication_hybrids),function(h) {
  x <- merge(long[long$id==id & long$common_basis,c('measurement_year','value')],primary[primary$hybrid_code==h,c('measurement_year','standardised_departure')],by='measurement_year')
  data.frame(id=id,hybrid_code=h,hybrid=publication_labels(h),n=nrow(x),pearson_r=cor(x$value,x$standardised_departure))
}))))
save_table(hybrid,'hybrid_correlations')
# Weather-weather redundancy on the common basis.
wide <- reshape(long[long$common_basis,c('measurement_year','id','value')],idvar='measurement_year',timevar='id',direction='wide')
save_table(data.frame(variable=sub('value.','',names(wide)[-1],fixed=TRUE),cor(wide[-1]),check.names=FALSE),'predictor_correlations')
results$label <- factor(results$label,levels=rev(definitions$label))
a <- ggplot(results,aes(pearson_r,label))+geom_vline(xintercept=0,colour='grey60',linetype=2)+
  geom_errorbar(aes(xmin=jackknife_min,xmax=jackknife_max),orientation='y',width=.15,colour='#0072B2')+
  geom_point(aes(shape='Pearson'),size=2.8,colour='#0072B2')+
  geom_point(aes(x=spearman_r,shape='Spearman'),size=2.5,colour='#D55E00')+
  scale_shape_manual(values=c(Pearson=16,Spearman=17),name=NULL)+scale_x_continuous(limits=c(-1,1),breaks=seq(-1,1,.25))+
  labs(title='Weather associations with shared PAIC departures',subtitle=sprintf('%d common measurement years; equal weight across four hybrids',length(complete_years)),x='Correlation with shared standardised departure',y=NULL,
    caption='Blue bars: range after omitting each year in turn, not confidence intervals. Orange triangles: rank correlations.\nExploratory screen of nine predefined candidates; no selected-model validation or causal interpretation.\nWeather from growth year t - 1. Complete daily coverage required for each predictor; dry days have rainfall <1 mm.')+theme_publication(11)
out <- file.path(root,'results/figures/weather_departure_screen')
save_publication_plot(a,out,width=9,height=6.5)
ggsave(paste0(out,'_preview.png'),a,width=9,height=6.5,dpi=150,bg='white')
scat <- long[long$common_basis,];scat$label <- factor(scat$label,levels=definitions$label)
extreme_years <- shared$measurement_year[order(abs(shared$shared_departure),decreasing=TRUE)[1:2]]
b <- ggplot(scat,aes(value,shared_departure))+geom_hline(yintercept=0,colour='grey80')+
  geom_smooth(method='lm',formula=y~x,se=FALSE,colour='#D55E00',linewidth=.6)+
  geom_point(shape=16,colour='#0072B2',size=1.7)+
  geom_text(data=scat[scat$measurement_year %in% extreme_years,],aes(label=measurement_year),vjust=-.6,size=2.6,check_overlap=TRUE)+
  scale_y_continuous(expand=expansion(mult=c(.08,.18)))+
  facet_wrap(~label,ncol=3,scales='free_x',labeller=label_wrap_gen(32))+
  labs(title='Seasonal weather and shared PAIC departures',x='Weather predictor in units stated above each panel',y='Mean standardised PAIC departure',
    caption='Lines are descriptive linear fits, not validated predictions. Labels identify the two largest absolute shared departures.\nAll panels use identical complete years. Shared growth and predictor selection have not been independently validated.')+theme_publication(10)
save_publication_plot(b,file.path(root,'results/figures/weather_departure_scatterplots'),width=11,height=9)
ggsave(file.path(root,'results/figures/weather_departure_scatterplots_preview.png'),b,width=11,height=9,dpi=140,bg='white')
stopifnot(!anyDuplicated(long[c('measurement_year','id')]),all(results$n==length(complete_years)),all(is.finite(results$pearson_r)))
cat('Common years:',paste(complete_years,collapse=', '),'\nExcluded:',paste(setdiff(years,complete_years),collapse=', '),'\n')
print(results[order(-abs(results$pearson_r)),])
