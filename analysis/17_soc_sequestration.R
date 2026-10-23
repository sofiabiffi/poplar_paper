# Run from workspace root. Analysis is calculated independently in Python and
# reconciled to the existing linear ESM calculation before plotting.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
d <- read.csv('poplar_paper/results/tables/soc_sequestration_ESM_summary.csv',fileEncoding='UTF-8-BOM')
d$display <- factor(d$group_code,levels=c('arable','alley_C','alley_F','trees'),labels=c('Arable\nreference','Alley fallow\n19 years','Alley fallow\n32 years','Tree rows\n32 years'))
p <- ggplot(d,aes(display,mean_SOC_ESM_mg_ha,colour=display,shape=display)) +
 geom_hline(yintercept=d$mean_SOC_ESM_mg_ha[d$group_code=='arable'],linetype='dashed',colour='grey50') +
 geom_errorbar(aes(ymin=mean_SOC_ESM_mg_ha-sd_SOC_ESM_mg_ha,ymax=mean_SOC_ESM_mg_ha+sd_SOC_ESM_mg_ha),width=.12) + geom_point(size=3) +
 publication_scales(levels(d$display),include_linetype=FALSE) + scale_x_discrete(limits=levels(d$display)) + theme_publication() + theme(legend.position='none') +
 labs(x=NULL,y=expression('ESM SOC stock (Mg C ha'^{-1}*')'),caption='Arable 0-30 cm reference soil mass; all groups evaluated at the same mass.\nPoints: profile means; error bars: SD among complete profiles. Dashed line: arable mean.')
save_publication_plot(p,'poplar_paper/results/figures/soc_sequestration_ESM_stocks',8,4.8)
p2 <- ggplot(d,aes(display,annualised_SOC_excess_mg_ha_yr,colour=display,shape=display)) +
 geom_hline(yintercept=0,linetype='dashed',colour='grey50') +
 geom_errorbar(data=d[d$group_code!='arable',],aes(ymin=annualised_SOC_excess_mg_ha_yr-sd_annualised_SOC_excess_mg_ha_yr,ymax=annualised_SOC_excess_mg_ha_yr+sd_annualised_SOC_excess_mg_ha_yr),width=.12) + geom_point(size=3) +
 publication_scales(levels(d$display),include_linetype=FALSE) + scale_x_discrete(limits=levels(d$display)) + theme_publication() + theme(legend.position='none') +
 labs(x=NULL,y=expression(SOC[ESM]~'sequestration rate (Mg C ha'^{-1}*' yr'^{-1}*')'),caption='(ESM stock - arable mean) / years: alley fallow 19 years; alley fallow 32 years; tree rows 32 years.\nError bars: profile SD / years, conditional on the arable mean; not confidence intervals. Reference = 0 by definition.')
save_publication_plot(p2,'poplar_paper/results/figures/soc_sequestration_ESM_rates',8,4.8)

