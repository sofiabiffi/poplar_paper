# Final-visit hybrid comparisons. Blocks are replicates; trees are subsamples.
options(poplar.paper.root=getwd())
source('library.R')
d <- read.csv('data/processed/tree_growth.csv')
x <- subset(d, measurement_year == 2023)
stopifnot(nrow(x)==180, all(table(x$hybrid)==45))
row <- x |> dplyr::group_by(block,tree_row,hybrid) |> dplyr::summarise(dplyr::across(c(PAIC,MAIC), ~mean(.x,na.rm=TRUE)),.groups='drop')
b <- row |> dplyr::group_by(block,hybrid) |> dplyr::summarise(dplyr::across(c(PAIC,MAIC),mean),.groups='drop')
b$block <- factor(b$block)
write.csv(b,'results/tables/growth_2023_block_means.csv',row.names=FALSE)
contrasts <- list(); tests <- list(); fits <- list()
for (v in c('PAIC','MAIC')) {
 m <- lm(reformulate(c('block','hybrid'),v),b)
 a <- as.data.frame(anova(m)); a$term<-rownames(a); a$metric<-v; tests[[v]]<-a
 e <- emmeans::emmeans(m,~hybrid)
 z <- as.data.frame(summary(pairs(e),infer=c(TRUE,TRUE),adjust='none')); z$metric<-v
 contrasts[[v]]<-z; fits[[v]]<-m
}
z<-dplyr::bind_rows(contrasts);z$p_holm_12<-p.adjust(z$p.value,'holm')
write.csv(z,'results/tables/growth_2023_hybrid_contrasts.csv',row.names=FALSE)
write.csv(dplyr::bind_rows(tests),'results/tables/growth_2023_hybrid_tests.csv',row.names=FALSE)
# Sensitivity retaining nine paired rows instead of averaging within blocks.
row$row_id<-factor(row$tree_row)
sens<-lapply(c('PAIC','MAIC'),function(v){
 m<-lm(reformulate(c('row_id','hybrid'),v),row)
 z<-as.data.frame(summary(pairs(emmeans::emmeans(m,~hybrid)),infer=c(TRUE,TRUE),adjust='none'));z$metric<-v;z
}) |> dplyr::bind_rows()
sens$p_holm_12<-p.adjust(sens$p.value,'holm')
write.csv(sens,'results/tables/growth_2023_row_sensitivity.csv',row.names=FALSE)
s <- x |> tidyr::pivot_longer(c(PAIC,MAIC,carbon_stock_mg_ha),names_to='metric') |> dplyr::group_by(hybrid,metric) |> dplyr::summarise(n=sum(is.finite(value)),median=median(value,na.rm=TRUE),q25=quantile(value,.25,na.rm=TRUE),q75=quantile(value,.75,na.rm=TRUE),.groups='drop')
write.csv(s,'results/tables/growth_2023_descriptive.csv',row.names=FALSE)
saveRDS(fits,'results/models/growth_2023_hybrid_models.rds')
print(z);print(dplyr::bind_rows(tests));print(s)
a<-read.csv('results/tables/growth_by_year_hybrid.csv')
print(a |> dplyr::filter(metric %in% c('PAIC','MAIC')) |> dplyr::group_by(hybrid,metric) |> dplyr::slice_max(median,n=1,with_ties=FALSE) |> dplyr::select(hybrid,metric,measurement_year,median,q25,q75))


# Always audit assumptions after fitting.
source('scripts/check_growth_2023_models.R')
