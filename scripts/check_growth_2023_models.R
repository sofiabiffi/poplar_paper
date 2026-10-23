# Shared diagnostic audit for every saved 2023 growth model.
# Diagnostics inform judgement; nonsignificant tests do not establish assumptions.
increments <- readRDS('results/models/growth_2023_hybrid_models.rds')
stock <- readRDS('results/models/growth_2023_stock_models.rds')
models <- c(increments,list(stock=stock$model,stock_row_sensitivity=stock$row_sensitivity))
row <- read.csv('data/processed/tree_growth.csv')
row <- subset(row,measurement_year==2023)
for(v in c('PAIC','MAIC')) {
 r <- aggregate(row[[v]],list(row_id=row$tree_row,hybrid=row$hybrid),mean,na.rm=TRUE)
 names(r)[3]<-'response';r$row_id<-factor(r$row_id)
 models[[paste0(v,'_row_sensitivity')]]<-lm(response~row_id+hybrid,r)
}
checks<-list();details<-list();spreads<-list()
for(nm in names(models)) {
 m<-models[[nm]];e<-residuals(m);h<-hatvalues(m)
 checks[[nm]]<-data.frame(model=nm,n=nobs(m),residual_df=df.residual(m),shapiro_W=unname(shapiro.test(e)$statistic),shapiro_p=shapiro.test(e)$p.value,max_abs_standardised=max(abs(rstandard(m))),max_cooks=max(cooks.distance(m)),max_leverage=max(h))
 mf<-model.frame(m)
 details[[nm]]<-data.frame(model=nm,mf,fitted=fitted(m),residual=e,standardised=rstandard(m),cooks=cooks.distance(m),leverage=h)
 spreads[[nm]]<-data.frame(model=nm,hybrid=levels(factor(mf$hybrid)),residual_sd=as.numeric(tapply(e,mf$hybrid,sd)))
 png(paste0('results/checks/growth_2023_',nm,'_diagnostics.png'),width=1600,height=1400,res=140)
 par(mfrow=c(2,2));plot(m,which=c(1,2,3,5));dev.off()
}
write.csv(do.call(rbind,checks),'results/checks/growth_2023_model_diagnostics.csv',row.names=FALSE)
write.csv(do.call(rbind,spreads),'results/checks/growth_2023_residual_spread.csv',row.names=FALSE)
# Model frames differ between primary and sensitivity models: export separately.
for(nm in names(details))write.csv(details[[nm]],paste0('results/checks/growth_2023_',nm,'_residuals.csv'),row.names=FALSE)
print(do.call(rbind,checks));print(do.call(rbind,spreads))
