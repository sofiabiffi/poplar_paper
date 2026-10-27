.libPaths(c('C:/Users/sofia/AppData/Local/R/win-library/4.4',.libPaths()))
library(ggplot2)
source('C:/Users/sofia/Documents/poplar_paper/plot_style.R')
args<-commandArgs(trailingOnly=TRUE)
script_file<-sub('^--file=','',grep('^--file=',commandArgs(),value=TRUE)[1])
root<-if(length(args))args[1] else normalizePath(file.path(dirname(script_file),'..'),winslash='/')
box<-data.frame(
 x=c(3,9,3,9,6,2,6,10,8,8,2),
 y=c(11.1,11.1,8.9,8.9,6.95,4.75,4.75,4.75,2.65,.85,1.7),
 w=c(5.5,5.5,5.5,5.5,11.5,3.5,3.5,3.5,7.5,7.5,3.5),
 h=c(1.65,1.65,1.65,1.65,1.15,1.85,1.85,1.85,1.05,1.25,2.8),
 group=c('Scenario','Evidence','Scenario','Evidence','Calculation','AGB','BGB','SOC','Calculation','Output','Output'),
 title=c('UK land targets','Observed tree growth','Planting programme and layout','Mean tree biomass through time','Follow each annual planting cohort',
 'Aboveground carbon','Belowground carbon','Additional soil carbon','Sum cohorts and land types','Carbon stocks','AGB growth summaries'),
 body=c(
 'Permanent grassland: 5.985m ha x 14% = 837,900 ha\nCroppable land: 6.1m ha x 7% = 427,000 ha\nCropped land: 4.1m ha x 7% = 287,000 ha\nCroppable and cropped are alternatives',
 '45 Trichobel trees\nDiameters converted to dry biomass per tree\nAverage dry biomass across trees at each visit\nObserved ages 1-31',
 'All planted in 2027 OR equal planting in 2027-2050\nCropland: 47.62 trees/ha; 2m strips / 30m rows\nGrassland: 166 trees/ha; 2m strips / 10m rows\nAlleys retain their previous use',
 'Mean tree dry biomass at each measured age\nLinear interpolation between measured ages\nUse ages 1-30; assume zero biomass at age zero\nSame growth assumed across planting layouts',
 'For every year in 2027-2056: determine cohort age, area and tree count\nTree count x dry biomass per tree at that age = cohort dry AGB',
 'Dry AGB x 0.4884\n\nCarbon fraction of shoots',
 'Dry AGB x 0.26 x 0.4690\n\nRoot:shoot dry-mass ratio\nand root carbon fraction',
 'Tree-row ESM minus arable FD\n/ 32 yr = 0.6510 Mg C/ha/yr\nx cropland strip area x cohort age\nGrassland and alleys: zero gain',
 'Sum AGB C, BGB C and additional SOC separately\nacross planting cohorts and land types',
 'AGB separately; combined = AGB + BGB + additional SOC\nConvert C to CO2 using 44/12',
 'For each planting cohort:\nPAIC: annual AGB carbon gain\nMAIC: average annual gain\nsince planting (stock / age)\n\nThen sum cohorts and land types\nand convert C to CO2 (44/12)'))
palette<-c(Scenario='#666666',Evidence='#666666',Calculation='#666666',AGB='#0072B2',BGB='#009E73',SOC='#E69F00',Output='#666666')
arrows<-data.frame(
 x=c(3,9,3,9,2,6,10,3,6,10,8,2),
 y=c(10.275,10.275,8.075,8.075,6.375,6.375,6.375,3.825,3.825,3.825,2.125,3.825),
 xend=c(3,9,3,9,2,6,10,4.75,6,10,8,2),
 yend=c(9.725,9.725,7.525,7.525,5.675,5.675,5.675,3.175,3.175,3.175,1.475,3.1))
p<-ggplot()+
 geom_segment(data=arrows,aes(x=x,y=y,xend=xend,yend=yend),colour='grey45',linewidth=.45,
  arrow=grid::arrow(length=grid::unit(.1,'inches'),type='closed'))+
 geom_rect(data=box,aes(xmin=x-w/2,xmax=x+w/2,ymin=y-h/2,ymax=y+h/2,colour=group),fill='white',linewidth=.65)+
 geom_text(data=box,aes(x=x,y=y+h/2-.23,label=title),fontface='bold',size=3.35)+
 geom_text(data=box,aes(x=x,y=y-.15,label=body),size=3.05,lineheight=1.2)+
 scale_colour_manual(values=palette,guide='none')+
 coord_cartesian(xlim=c(0,12),ylim=c(0,12.1),expand=FALSE)+theme_void()+
 theme(plot.background=element_rect(fill='white',colour=NA),plot.margin=margin(12,12,12,12))
save_publication_plot(p,file.path(root,'figures/uk_scenarios_method_schematic'),width=8.5,height=9.5)
cat('Draft method schematic exported as 600 dpi PNG and vector PDF.\n')

write.csv(box,file.path(root,'schematic_boxes.csv'),row.names=FALSE)
write.csv(arrows,file.path(root,'schematic_arrows.csv'),row.names=FALSE)
