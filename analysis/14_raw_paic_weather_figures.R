# Sourced by 14_raw_paic_weather_final.R after estimation and raw screening.
# Current figure set only: weather associations and age supplement.
effects$hybrid <- factor(effects$hybrid,levels=rev(unname(publication_hybrids)))
effects$predictor <- factor(effects$predictor,levels=c('Rainfall','Temperature'),labels=c('Summer rainfall increase of 100 mm','Summer temperature increase of 1 degree C'))
c <- ggplot(effects,aes(difference,hybrid,colour=hybrid,shape=hybrid))+
  geom_vline(xintercept=0,colour='grey65',linetype=2)+
  geom_errorbar(aes(xmin=lower,xmax=upper),orientation='y',width=.12,linewidth=.65)+geom_point(size=3.2)+
  facet_wrap(~predictor,ncol=2)+publication_scales(unname(publication_hybrids),'Hybrid',include_linetype=FALSE)+
  labs(title='Summer weather associations with PAIC by hybrid',x=expression(Delta~PAIC~(Mg~C~ha^{-1}~yr^{-1})),y=NULL,
       caption='Original PAIC models include hybrid-specific linear and squared age terms, summer rainfall and temperature.\nPoints are absolute mean differences; whiskers are plus or minus one model-based standard error (delta method), not 95% intervals.\nWeather contrasts are centred on observed means; the other weather variable is fixed and ages are averaged equally.')+
  theme_publication(12)+theme(legend.position='none')
age_shapes <- do.call(rbind,lapply(hybrids,function(h) {
  d <- dat[dat$hybrid_code==h,]
  nd <- data.frame(age_years=seq(min(d$age_years),max(d$age_years),length.out=200),temp_c=ref_temp,rain_c=ref_rain)
  nd$age_c <- (nd$age_years-15)/10
  data.frame(hybrid_code=h,hybrid=publication_labels(h),age_years=nd$age_years,
             fitted_PAIC=predict(fits[[paste(h,ages,'Both',sep='|')]],nd,type='response'))
}))
out(age_shapes,'quadratic_age_shapes')
age_shapes$hybrid <- factor(age_shapes$hybrid,levels=unname(publication_hybrids))
d <- ggplot(age_shapes,aes(age_years,fitted_PAIC,colour=hybrid,linetype=hybrid))+
  geom_line(linewidth=1)+facet_wrap(~hybrid,ncol=2)+publication_scales(unname(publication_hybrids),'Hybrid')[c(1,3)]+
  labs(title='Fitted age trajectories at fixed summer weather',x='Tree age (years)',
       y=expression('Fitted PAIC'~(Mg~C~ha^{-1}~yr^{-1})),
       caption=sprintf('Quadratic age on the log-mean scale; summer temperature held at %.2f degrees C and rainfall at %.2f mm.\nShapes of fitted means only; uncertainty is omitted for clarity. These are not observed trajectories or isolated causal age effects.',ref_temp+16,100*ref_rain+200))+
  theme_publication(12)+theme(legend.position='none')
figs <- list(hybrid_effects=c,quadratic_age_shapes=d)
for(n in names(figs)) {
  height <- if(n=='hybrid_effects')4.8 else 6.5
  stem <- file.path(root,'results/figures',paste0('final_weather_',n))
  save_publication_plot(figs[[n]],stem,width=9,height=height)
  ggsave(paste0(stem,'_preview.png'),figs[[n]],width=9,height=height,dpi=150,bg='white')
}
