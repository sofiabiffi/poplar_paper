# Exploratory combined seasonal PCA + Gamma(log) PAIC models.
# From workspace root: Rscript --vanilla poplar_paper/analysis/06_combined_seasonal_weather.R
.libPaths(c('poplar_paper/renv/library', .libPaths()))
library(ggplot2)
source('plot_style.R')
root <- 'poplar_paper'
read <- function(p) read.csv(file.path(root,p))
save_table <- function(x,n) write.csv(x,file.path(root,'results/tables',paste0('combined_seasonal_',n,'.csv')),row.names=FALSE)
seasons <- c('winter','spring','summer','autumn')
weather <- read('data/processed/weather_wide.csv')
responses <- read('data/processed/growth_weather.csv')
vars <- grep('^(winter|spring|summer|autumn)_',names(weather),value=TRUE)
eligible <- tapply(responses$PAIC,responses$measurement_year,function(x) length(x)==4 && all(is.finite(x) & x>0))
basis <- weather[weather$measurement_year %in% names(eligible)[eligible] & complete.cases(weather[vars]),]
varying <- vars[vapply(basis[vars],function(x) sd(x)>0,logical(1))]
save_table(data.frame(variable=setdiff(vars,varying),reason='Constant on common complete-year basis'),'exclusions')
# Keep correlated variables for this first exploration; audit exact duplicates.
correlations <- cor(basis[varying])
idx <- which(upper.tri(correlations) & abs(correlations)>.999999,arr.ind=TRUE)
save_table(data.frame(variable1=rownames(correlations)[idx[,1]],variable2=colnames(correlations)[idx[,2]],r=correlations[idx]),'redundancy_audit')
pca <- prcomp(basis[varying],center=TRUE,scale.=TRUE)
variance <- pca$sdev^2/sum(pca$sdev^2)
k <- which(cumsum(variance)>=.8)[1]
pcs <- paste0('PC',seq_len(k))
save_table(data.frame(PC=colnames(pca$x),proportion_variance=variance,cumulative_variance=cumsum(variance),retained=seq_along(variance)<=k),'variance')
scores <- data.frame(basis[c('measurement_year','growth_year')],pca$x)
save_table(scores,'scores')
save_table(data.frame(variable=varying,center=pca$center,scale=pca$scale),'scaling')
loadings <- data.frame(variable=rep(rownames(pca$rotation),times=ncol(pca$rotation)),PC=rep(colnames(pca$rotation),each=nrow(pca$rotation)),loading=as.vector(pca$rotation))
save_table(loadings,'loadings')
models <- list(); coefficients <- list(); summaries <- list(); diagnostics <- list()
for(code in names(publication_hybrids)) {
  dat <- merge(responses[responses$hybrid_code==code,c('measurement_year','PAIC','interval_years')],scores,by='measurement_year')
  fit <- glm(reformulate(pcs,'PAIC'),data=dat,family=Gamma('log'))
  null <- glm(PAIC~1,data=dat,family=Gamma('log'))
  stopifnot(fit$converged,fit$df.residual>0,all(is.finite(coef(fit))))
  ct <- summary(fit)$coefficients[-1,,drop=FALSE]
  sd_pc <- vapply(dat[rownames(ct)],sd,numeric(1))
  critical <- qt(.975,fit$df.residual)
  coefficients[[code]] <- data.frame(hybrid_code=code,hybrid=publication_labels(code),PC=rownames(ct),estimate=ct[,1],std_error=ct[,2],p_value=ct[,4],score_sd=sd_pc,
    effect=100*expm1(ct[,1]*sd_pc),lower=100*expm1((ct[,1]-critical*ct[,2])*sd_pc),upper=100*expm1((ct[,1]+critical*ct[,2])*sd_pc))
  summaries[[code]] <- data.frame(hybrid_code=code,hybrid=publication_labels(code),n=nrow(dat),n_pcs=k,df_residual=fit$df.residual,AIC=AIC(fit),deviance_reduction=1-fit$deviance/null$deviance)
  diagnostics[[code]] <- data.frame(hybrid_code=code,dat[c('measurement_year','PAIC','interval_years')],fitted=fitted(fit),deviance_residual=residuals(fit,type='deviance'),cooks_distance=cooks.distance(fit))
  models[[code]] <- fit
}
coefs <- do.call(rbind,coefficients); sm <- do.call(rbind,summaries)
save_table(coefs,'effects'); save_table(sm,'model_summary'); save_table(do.call(rbind,diagnostics),'diagnostics')
saveRDS(list(pca=pca,models=models,basis=basis,retained_pcs=pcs),file.path(root,'results/models/combined_seasonal_weather.rds'))
metric_names <- c(temp='Air temperature',soil_temp='Soil temperature',rainfall='Rainfall',sunshine='Sunshine',ground_frost_days='Ground frost days',air_frost_days='Air frost days',growing_days='Growing days',growing_degree_days='Growing degree days',windspeed='Wind speed',windy_days='Windy days')
ld <- subset(loadings,PC %in% pcs)
ld$season <- factor(sub('_.*','',ld$variable),levels=seasons,labels=tools::toTitleCase(seasons))
ld$metric <- factor(sub('^[^_]+_','',ld$variable),levels=rev(names(metric_names)),labels=rev(unname(metric_names)))
ld$PC <- factor(ld$PC,levels=pcs)
pca_labels <- setNames(sprintf('%s\n%.1f%%',pcs,100*variance[seq_len(k)]),pcs)
a <- ggplot(ld,aes(PC,metric,fill=loading))+geom_tile(colour='white',linewidth=.3)+
  facet_wrap(~season,ncol=2)+scale_x_discrete(labels=pca_labels)+
  scale_fill_gradient2(low='#2166AC',mid='white',high='#B35806',limits=c(-max(abs(ld$loading)),max(abs(ld$loading))),name='Loading')+
  labs(title='A  Weather patterns across four seasons',x=NULL,y=NULL)+theme_publication(10)+
  theme(axis.text.x=element_text(size=8),axis.line=element_blank(),axis.ticks=element_blank())
coefs$PC <- factor(coefs$PC,levels=rev(pcs))
pd <- position_dodge(.65)
b <- ggplot(coefs,aes(effect,PC,colour=hybrid_code,shape=hybrid_code,group=hybrid_code))+
  geom_vline(xintercept=0,linetype=2,colour='grey65')+
  geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',position=pd,width=.15)+geom_point(position=pd,size=2)+
  publication_scales(names(publication_hybrids),'Hybrid')[1:2]+
  labs(title='B  Association with PAIC',subtitle='Estimates and conditional 95% t-Wald intervals',x='Change in PAIC per 1 SD of PC (%)',y=NULL)+theme_publication(10)
draw <- function() {
  grid::grid.newpage(); grid::pushViewport(grid::viewport(layout=grid::grid.layout(2,2,heights=grid::unit(c(9,1),'null'),widths=grid::unit(c(1.4,1),'null'))))
  print(a,vp=grid::viewport(layout.pos.row=1,layout.pos.col=1)); print(b,vp=grid::viewport(layout.pos.row=1,layout.pos.col=2))
  grid::grid.text(sprintf('EXPLORATORY | %d years; %d varying seasonal predictors; %d PCs explain %.1f%% of weather variance.\nWeather variance is not PAIC predictive relevance: PC retention and validation remain open.\nGamma(log) models; in-sample estimates; intervals condition on fitted PCA. Age/time adjustment pending.',nrow(basis),length(varying),k,100*sum(variance[seq_len(k)])),x=.02,just='left',gp=grid::gpar(fontsize=10),vp=grid::viewport(layout.pos.row=2,layout.pos.col=1:2))
}
stem <- file.path(root,'results/figures/combined_seasonal_weather_draft')
png(paste0(stem,'.png'),width=14,height=10,units='in',res=600);draw();dev.off()
pdf(paste0(stem,'.pdf'),width=14,height=10,useDingbats=FALSE);draw();dev.off()
png(paste0(stem,'_preview.png'),width=1680,height=1200,res=120);draw();dev.off()
cat(sprintf('\n%d years, %d predictors, %d retained PCs (%.1f%%)\n',nrow(basis),length(varying),k,100*sum(variance[seq_len(k)])))
print(sm)
