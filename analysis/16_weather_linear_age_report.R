# Current paper presentation: summer rainfall and temperature, with linear age.
# Uses the existing fitted models and paired bootstrap; does not repeat selection.
.libPaths(c('poplar_paper/renv/library',.libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
read_table <- function(stem) read.csv(file.path(root,'results/tables',paste0('final_weather_',stem,'.csv')))
write_table <- function(x,stem) write.csv(x,file.path(root,'results/tables',paste0('final_weather_',stem,'.csv')),row.names=FALSE)
effects <- read_table('absolute_effects')
effects <- subset(effects,age_model=='Linear age')
comparison <- subset(read_table('candidate_models'),age_model=='Linear age')
comparison$delta_AICc_within_hybrid <- ave(comparison$AICc,comparison$hybrid_code,FUN=function(x)x-min(x))
paired <- subset(read_table('paired_hybrid_differences'),age_model=='Linear age')
write_table(effects,'linear_effects')
write_table(comparison,'linear_candidate_models')
write_table(paired,'linear_hybrid_differences')
write_table(subset(read_table('residual_summary'),age_model=='Linear age'),'linear_residual_summary')
stopifnot(nrow(effects)==8,nrow(comparison)==16,nrow(paired)==12)
effects$hybrid <- factor(effects$hybrid,levels=rev(unname(publication_hybrids)))
effects$predictor <- factor(effects$predictor,levels=c('Rainfall','Temperature'),labels=c('100 mm more summer rainfall','1 degree C warmer summer'))
groups <- unname(publication_hybrids)
p <- ggplot(effects,aes(difference,hybrid,colour=hybrid,shape=hybrid))+
  geom_vline(xintercept=0,colour='grey60',linetype='dashed',linewidth=.45)+
  geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.14,linewidth=.65)+
  geom_point(size=3)+facet_wrap(~predictor,ncol=2)+
  publication_scales(groups,'Hybrid',include_linetype=FALSE)+
  labs(title='Summer weather associations with PAIC',x=expression('Estimated difference in PAIC'~(Mg~C~ha^{-1}~yr^{-1})),y=NULL,
    caption='Hybrid-specific Gamma models with summer rainfall, temperature and linear age; 26 measurement years.\nDots: absolute mean contrasts at reference weather, averaged over the same observed ages.\nWhiskers: pointwise 95% paired block-bootstrap intervals (1,000 resamples); uncertainty in associations, not annual variability.')+
  theme_publication(12)+theme(legend.position='none',plot.caption=element_text(size=9))
stem <- file.path(root,'results/figures/final_weather_hybrid_effects')
save_publication_plot(p,stem,width=9,height=5)
ggsave(paste0(stem,'_preview.png'),p,width=9,height=5,dpi=150,bg='white')
print(effects)
