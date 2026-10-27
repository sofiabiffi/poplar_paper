.libPaths(c('C:/Users/sofia/Documents/poplar_paper/renv/library','C:/Users/sofia/AppData/Local/R/win-library/4.6',.libPaths()))
library(ggplot2)
source('C:/Users/sofia/Documents/poplar_paper/plot_style.R')
args<-commandArgs(trailingOnly=TRUE)
script_file<-sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE)[1])
root<-if(length(args))args[1] else normalizePath(file.path(dirname(script_file),'..'),winslash='/')
d<-read.csv(file.path(root,'tables/uk_scenario_annual_results.csv'))
d<-subset(d,land=='UK total' & cropland_definition=='Croppable area')
stopifnot(nrow(d)==60,all(d$total_CO2_Mt==d$total_without_grassland_SOC_CO2_Mt))
make<-function(column,series,metric){z<-d;z$value<-z[[column]];z$series<-series;z$metric<-metric;z}
stock_label<-'Additional carbon stock (Mt CO2)'
growth_label<-'AGB accumulation (Mt CO2 per year)'
long<-rbind(make('AGB_CO2_Mt','Stock: AGB only',stock_label),
 make('total_CO2_Mt','Stock: AGB + BGB + SOC',stock_label),
 make('annual_AGB_CO2_Mt','Growth: PAIC',growth_label),
 make('MAIC_AGB_CO2_Mt','Growth: MAIC',growth_label))
groups<-c('Stock: AGB only','Stock: AGB + BGB + SOC','Growth: PAIC','Growth: MAIC')
long$series<-factor(long$series,levels=groups)
long$metric<-factor(long$metric,levels=c(stock_label,growth_label))
colours<-setNames(publication_palette[c(1,3,2,4)],groups)
lines<-setNames(rep('solid',length(groups)),groups)
shapes<-setNames(c(16,15,17,18),groups)
panel<-function(metric_name,tag,legend_labels){
 selected<-subset(long,metric==metric_name)
 panel_groups<-groups[groups %in% as.character(selected$series)]
 selected$series<-factor(selected$series,levels=panel_groups)
 ggplot(selected,aes(year,value,colour=series,linetype=series,shape=series))+
 geom_vline(xintercept=2050,colour='grey65',linetype='dotted',linewidth=.4)+
 geom_line(linewidth=.85)+geom_point(data=subset(selected,year==2056),size=3.3)+
 facet_grid(.~schedule)+
 scale_colour_manual(values=colours[panel_groups],labels=legend_labels,name=NULL)+
 scale_linetype_manual(values=lines[panel_groups],labels=legend_labels,name=NULL)+
 scale_shape_manual(values=shapes[panel_groups],labels=legend_labels,name=NULL)+
 scale_x_continuous(breaks=c(2027,2035,2040,2050,2056),limits=c(2027,2056))+
 scale_y_continuous(limits=c(0,NA),expand=expansion(mult=c(0,.05)))+
 labs(x='year',y=metric_name,tag=tag)+theme_publication(11)+
 theme(plot.tag=element_text(face='bold',size=16),plot.tag.position=c(0,1),
 axis.text.x=element_text(angle=35,hjust=1),legend.position='bottom',
 legend.key.width=grid::unit(2,'lines'),plot.margin=margin(12,12,8,12))+
 guides(colour=guide_legend(nrow=1),shape=guide_legend(nrow=1),linetype=guide_legend(nrow=1))
}
pA<-panel(stock_label,'A',c('AGB only','AGB + BGB + SOC'))
pB<-panel(growth_label,'B',c('PAIC','MAIC'))
gA<-ggplotGrob(pA);gB<-ggplotGrob(pB)
stopifnot(length(gA$widths)==length(gB$widths))
widths<-grid::unit.pmax(gA$widths,gB$widths)
gA$widths<-gB$widths<-widths
combined<-gtable::gtable(widths=grid::unit(1,'null'),heights=grid::unit(c(1,1),'null'))
combined<-gtable::gtable_add_grob(combined,list(gA,gB),t=c(1,2),l=c(1,1),name=c('panel_A','panel_B'))
save_publication_plot(combined,file.path(root,'figures/uk_scenarios_summary'),width=9,height=8.4)
write.csv(long,file.path(root,'tables/uk_scenario_figure_data.csv'),row.names=FALSE)
cat('Two labelled panels A and B, independent legends, distinct colours and shapes; endpoint markers only.\n')
