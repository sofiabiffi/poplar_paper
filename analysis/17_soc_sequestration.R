script_file<-sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE)[1])
root<-normalizePath(file.path(dirname(script_file),'..'),winslash='/')
.libPaths(c(file.path(root,'renv/library'),'C:/Users/sofia/AppData/Local/R/win-library/4.6',.libPaths()))
library(ggplot2);source(file.path(root,'plot_style.R'))
d<-read.csv(file.path(root,'results/tables/soc_sequestration_ESM_summary.csv'),fileEncoding='UTF-8-BOM')
d$display<-factor(d$group_code,levels=c('arable','alley_C','alley_F','trees'),labels=c('Arable\nreference','Alley fallow\n19 years','Alley fallow\n32 years','Tree rows\n32 years'))
p<-ggplot(d,aes(display,mean_SOC_stock_mg_ha,colour=display,shape=display))+
 geom_hline(yintercept=d$mean_SOC_stock_mg_ha[d$group_code=='arable'],linetype='dashed',colour='grey50')+
 geom_errorbar(aes(ymin=mean_SOC_stock_mg_ha-sd_SOC_stock_mg_ha,ymax=mean_SOC_stock_mg_ha+sd_SOC_stock_mg_ha),width=.12)+geom_point(size=3)+
 publication_scales(levels(d$display),include_linetype=FALSE)+scale_x_discrete(limits=levels(d$display))+theme_publication()+theme(legend.position='none')+
 labs(x=NULL,y=expression('SOC stock (Mg C ha'^{-1}*')'),caption='Arable: measured fixed-depth 0-30 cm stocks. Alley/tree rows: ESM stocks at arable reference mass.\nPoints: complete-profile means; error bars: profile SD. Dashed line: fixed-depth arable mean.')
save_publication_plot(p,file.path(root,'results/figures/soc_sequestration_ESM_stocks'),8,4.8)
p2<-ggplot(d,aes(display,annualised_SOC_excess_mg_ha_yr,colour=display,shape=display))+
 geom_hline(yintercept=0,linetype='dashed',colour='grey50')+
 geom_errorbar(data=subset(d,group_code!='arable'),aes(ymin=annualised_SOC_excess_mg_ha_yr-sd_annualised_SOC_excess_mg_ha_yr,ymax=annualised_SOC_excess_mg_ha_yr+sd_annualised_SOC_excess_mg_ha_yr),width=.12)+geom_point(size=3)+
 publication_scales(levels(d$display),include_linetype=FALSE)+scale_x_discrete(limits=levels(d$display))+theme_publication()+theme(legend.position='none')+
 labs(x=NULL,y=expression('Annualised SOC accumulation (Mg C ha'^{-1}*' yr'^{-1}*')'),
 caption='(Agroforestry ESM stock - mean arable fixed-depth stock) / agreed years.\nBars: SD among profile-level rates, conditional on the shared fixed-depth arable mean.\nArable zero is the comparison reference. SD is not a confidence interval.')
save_publication_plot(p2,file.path(root,'results/figures/soc_sequestration_ESM_rates'),8,5)
