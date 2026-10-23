# Descriptive synchrony, without subtracting a fitted shared year effect.
# Run from workspace root with Rscript --vanilla.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
write_table <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('paic_synchrony_',n,'.csv')),row.names=FALSE)
tree <- read.csv(file.path(root,'results/tables/growth_by_year_hybrid.csv'))
tree <- subset(tree,metric=='PAIC' & is.finite(median) & median>0)
tree$PAIC <- tree$median
legacy <- read.csv(file.path(root,'data/processed/growth_weather.csv'))
legacy <- subset(legacy,is.finite(PAIC) & PAIC>0)
analyse <- function(d,source) {
  counts <- table(d$measurement_year)
  d <- d[d$measurement_year %in% names(counts)[counts==4],]
  d <- d[order(d$measurement_year,d$hybrid_code),]
  d$age_c <- (d$age_years-15)/10
  d$linear_residual <- d$quadratic_residual <- d$trend <- d$standardised_departure <- NA_real_
  for(h in names(publication_hybrids)) {
    ix <- which(d$hybrid_code==h); x <- d[ix,]
    f1 <- lm(log(PAIC)~age_c,data=x);f2 <- lm(log(PAIC)~age_c+I(age_c^2),data=x)
    d$linear_residual[ix] <- residuals(f1);d$quadratic_residual[ix] <- residuals(f2)
    d$trend[ix] <- exp(fitted(f2));d$standardised_departure[ix] <- residuals(f2)/sd(residuals(f2))
  }
  d$source <- source
  d$hybrid <- publication_labels(d$hybrid_code)
  d
}
primary <- analyse(tree,'Tree medians');sensitivity <- analyse(legacy,'Legacy weather summaries')
all <- rbind(primary[c('measurement_year','age_years','hybrid_code','hybrid','PAIC','trend','linear_residual','quadratic_residual','standardised_departure','source')],sensitivity[c('measurement_year','age_years','hybrid_code','hybrid','PAIC','trend','linear_residual','quadratic_residual','standardised_departure','source')])
write_table(all,'departures')
pairs <- combn(names(publication_hybrids),2,simplify=FALSE)
correlations <- list()
for(src in unique(all$source)) for(method in c('raw_log','linear_residual','quadratic_residual')) {
  d <- all[all$source==src,]; d$value <- if(method=='raw_log') log(d$PAIC) else d[[method]]
  for(pair in pairs) {
    a <- d[d$hybrid_code==pair[1],];b <- d[d$hybrid_code==pair[2],]
    stopifnot(identical(a$measurement_year,b$measurement_year))
    correlations[[paste(src,method,paste(pair,collapse=''))]] <- data.frame(source=src,method=method,hybrid_code_1=pair[1],hybrid_1=publication_labels(pair[1]),hybrid_code_2=pair[2],hybrid_2=publication_labels(pair[2]),n=nrow(a),pearson_r=cor(a$value,b$value),spearman_r=cor(a$value,b$value,method='spearman'))
  }
}
cors <- do.call(rbind,correlations);write_table(cors,'correlations')
years <- sort(unique(primary$measurement_year));last10 <- tail(years,10)
trichobel <- do.call(rbind,lapply(years,function(yr) {
  d <- primary[primary$measurement_year==yr,];t <- d[d$hybrid_code=='T',];other <- d[d$hybrid_code!='T',]
  data.frame(measurement_year=yr,Trichobel=t$PAIC,other_geometric_mean=exp(mean(log(other$PAIC))),ratio=t$PAIC/exp(mean(log(other$PAIC))),Trichobel_departure=t$standardised_departure,others_departure=mean(other$standardised_departure),period=if(yr %in% last10)'Last ten observations' else 'Earlier observations')
}))
write_table(trichobel,'trichobel')
periods <- do.call(rbind,lapply(unique(trichobel$period),function(p) {
  d <- trichobel[trichobel$period==p,]
  data.frame(period=p,n=nrow(d),first_year=min(d$measurement_year),last_year=max(d$measurement_year),Trichobel_vs_others_r=cor(d$Trichobel_departure,d$others_departure),median_raw_ratio=median(d$ratio))
}))
write_table(periods,'period_summary')
a <- ggplot(primary,aes(measurement_year,PAIC,colour=hybrid_code,shape=hybrid_code,linetype=hybrid_code))+
  geom_line(linewidth=.4)+geom_point(size=1.7)+geom_line(aes(y=trend),linewidth=.9,show.legend=FALSE)+
  publication_scales(names(publication_hybrids),'Hybrid')+
  labs(title='A  PAIC and broad trajectories',subtitle='Thin lines and symbols: observed medians; thick lines: quadratic trends on log PAIC',x=NULL,y=expression(PAIC~(Mg~C~ha^{-1}~yr^{-1})))+theme_publication(10)
b <- ggplot(primary,aes(measurement_year,standardised_departure,colour=hybrid_code,shape=hybrid_code,linetype=hybrid_code))+
  geom_hline(yintercept=0,colour='grey70')+geom_line(linewidth=.6)+geom_point(size=1.8)+publication_scales(names(publication_hybrids),'Hybrid')+
  labs(title='B  Departures from each hybrid trajectory',subtitle='Log PAIC residuals divided by their within-hybrid standard deviation',x='Measurement year',y='Standardised departure')+theme_publication(10)
cc <- cors[cors$source=='Tree medians' & cors$method=='quadratic_residual',]
heat <- rbind(data.frame(x=cc$hybrid_1,y=cc$hybrid_2,r=cc$pearson_r),data.frame(x=cc$hybrid_2,y=cc$hybrid_1,r=cc$pearson_r),data.frame(x=unname(publication_hybrids),y=unname(publication_hybrids),r=1))
heat$x <- factor(heat$x,levels=unname(publication_hybrids));heat$y <- factor(heat$y,levels=rev(unname(publication_hybrids)))
c <- ggplot(heat,aes(x,y,fill=r))+geom_tile(colour='white',linewidth=1)+geom_text(aes(label=sprintf('%.2f',r)),size=4)+
  scale_fill_gradient2(low='#2166AC',mid='white',high='#B35806',limits=c(-1,1),name='Pearson r')+
  labs(title='C  Correlation of departures',x=NULL,y=NULL)+theme_publication(10)+theme(axis.line=element_blank(),axis.ticks=element_blank())
d <- ggplot(trichobel,aes(measurement_year,ratio))+geom_hline(yintercept=1,colour='grey65',linetype=2)+geom_line(colour='#CC79A7')+geom_point(colour='#CC79A7',shape=18,size=2)+
  labs(title='D  Trichobel relative to the other hybrids',subtitle='Observed PAIC ratio; comparison uses the others\' geometric mean',x='Measurement year',y='Trichobel / other hybrids')+theme_publication(10)
standalone_d <- d + labs(title='Trichobel relative to the other hybrids',
  caption='Tree-level hybrid medians. Reference: geometric mean of Beaupre, Gibecq and Robusta.\nDashed line: equal PAIC. Lines connect observed visits; missing years are not imputed.')
save_publication_plot(standalone_d,file.path(root,'results/figures/trichobel_relative_paic'),width=7.2,height=4.8)
ggsave(file.path(root,'results/figures/trichobel_relative_paic_preview.png'),standalone_d,width=7.2,height=4.8,dpi=150,bg='white')
draw <- function() {
  grid::grid.newpage();grid::pushViewport(grid::viewport(layout=grid::grid.layout(3,2,heights=grid::unit(c(4.5,4.5,.8),'null'))))
  print(a,vp=grid::viewport(layout.pos.row=1,layout.pos.col=1));print(b,vp=grid::viewport(layout.pos.row=1,layout.pos.col=2));print(c,vp=grid::viewport(layout.pos.row=2,layout.pos.col=1));print(d,vp=grid::viewport(layout.pos.row=2,layout.pos.col=2))
  grid::grid.text(sprintf('DESCRIPTIVE | %d common positive-response measurement years; tree-level hybrid medians as in the PAIC/MAIC descriptive plot.\nTrends fitted separately by hybrid; no shared year effect removed. Lines connect observed visits; missing years are not imputed.\nCorrelations are descriptive and do not establish weather causation. Linear detrending and legacy-response sensitivity exported.',length(years)),x=.02,just='left',gp=grid::gpar(fontsize=9),vp=grid::viewport(layout.pos.row=3,layout.pos.col=1:2))
}
stem <- file.path(root,'results/figures/paic_shared_fluctuations')
png(paste0(stem,'.png'),width=13,height=10,units='in',res=600);draw();dev.off()
pdf(paste0(stem,'.pdf'),width=13,height=10,useDingbats=FALSE);draw();dev.off()
png(paste0(stem,'_preview.png'),width=1560,height=1200,res=120);draw();dev.off()
print(cc);print(periods)
cat('All-year Trichobel vs others correlation:',cor(trichobel$Trichobel_departure,trichobel$others_departure),'\n')
