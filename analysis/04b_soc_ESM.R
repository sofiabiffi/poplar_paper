# Linear ESM calculation. Called by 04_soc_stocks.R after fixed-depth outputs.
# Soil mass Mg/ha = BD g/cm3 * thickness cm * 100.
esm_layers <- soil_depth |> mutate(soil_mass_mg_ha = bulk_density_g_cm3 * depth_thickness_cm * 100)
stopifnot(all(is.finite(esm_layers$soil_mass_mg_ha)), all(esm_layers$soil_mass_mg_ha > 0))
esm_reference <- esm_layers |> filter(location_code == "3_arable") |>
  group_by(depth_interval_cm) |>
  summarise(n_samples=n(), mean_layer_mass_mg_ha=mean(soil_mass_mg_ha), .groups="drop") |>
  arrange(depth_interval_cm) |>
  mutate(reference_cumulative_mass_mg_ha=cumsum(mean_layer_mass_mg_ha))
stopifnot(identical(esm_reference$depth_interval_cm,c("0-15","15-30")))
ref_mass <- esm_reference$reference_cumulative_mass_mg_ha
write_table(esm_reference,"soc_ESM_arable_reference_masses")
coords <- list(); estimates <- list(); extensions <- list()
for (id in unique(esm_layers$profile_id)) {
  dat <- esm_layers |> filter(profile_id==id) |> arrange(depth_top_cm)
  contiguous <- dat$depth_top_cm[1] == 0 && all(head(dat$depth_bottom_cm,-1)==tail(dat$depth_top_cm,-1))
  if (!contiguous) stop("Noncontiguous profile: ",id)
  complete <- identical(dat$depth_interval_cm,c("0-15","15-30"))
  mass <- c(0,cumsum(dat$soil_mass_mg_ha)); carbon <- c(0,cumsum(dat$SOC_stock_mg_ha))
  key <- dat[1,c("profile_id","sampling_id","location_code","location","sampling_year",
    "former_treatment_code","former_treatment","block","tree_row","spatial_band",
    "field_id","latitude","longitude","legacy_profile_id","legacy_location_code")]
  coords[[id]] <- bind_cols(key[rep(1,length(mass)),],data.frame(depth_bottom_cm=c(0,dat$depth_bottom_cm),cumulative_mass_mg_ha=mass,cumulative_SOC_mg_ha=carbon))
  final_slope <- tail(dat$SOC_percent,1)/100
  get_stock <- function(m) {
    if (m <= max(mass)) return(approx(mass,carbon,xout=m,method="linear")$y)
    if (!complete && m > ref_mass[1]) return(NA_real_)
    tail(carbon,1)+(m-tail(mass,1))*final_slope
  }
  values <- vapply(ref_mass,get_stock,numeric(1))
  status <- ifelse(ref_mass <= max(mass),"interpolated","extrapolated")
  status[is.na(values)] <- "excluded_incomplete_profile"
  # A full-profile result requires both measured depths, irrespective of mass.
  if (!complete) { values[2] <- NA_real_; status[2] <- "excluded_incomplete_profile" }
  is_arable <- dat$location_code[1] == "3_arable"
  if (is_arable) {
    values <- c(carbon[2],if(complete) tail(carbon,1) else NA_real_)
    status <- c("fixed_depth",if(complete) "fixed_depth" else "excluded_incomplete_profile")
  }
  estimates[[id]] <- bind_cols(key,data.frame(profile_complete=complete,
    stock_basis=if(is_arable) "Fixed depth" else "Equivalent soil mass",
    SOC_stock_upper_mg_ha=values[1],SOC_stock_lower_mg_ha=values[2]-values[1],SOC_stock_total_mg_ha=values[2],
    observed_mass_0_15_mg_ha=mass[2], observed_mass_0_30_mg_ha=if(complete) tail(mass,1) else NA_real_,
    reference_mass_upper_mg_ha=ref_mass[1],reference_mass_total_mg_ha=ref_mass[2],
    SOC_ESM_upper_mg_ha=if(is_arable) NA_real_ else values[1],SOC_ESM_lower_mg_ha=if(is_arable) NA_real_ else values[2]-values[1],SOC_ESM_total_mg_ha=if(is_arable) NA_real_ else values[2],
    upper_method=status[1],total_method=status[2],
    shallow_bedrock=!complete,
    extrapolated_mass_upper_mg_ha=if(is_arable) 0 else max(0,ref_mass[1]-max(mass)),
    extrapolated_mass_total_mg_ha=if(is_arable) {if(complete) 0 else NA_real_} else if(complete) max(0,ref_mass[2]-max(mass)) else NA_real_,
    extrapolated_SOC_total_mg_ha=if(is_arable) {if(complete) 0 else NA_real_} else if(complete) max(0,ref_mass[2]-max(mass))*final_slope else NA_real_,
    equivalent_depth_total_cm=if(is_arable) {if(complete) 30 else NA_real_} else if(complete) {
      if(ref_mass[2]<=mass[2]) ref_mass[2]/dat$soil_mass_mg_ha[1]*15 else 15+(ref_mass[2]-mass[2])/dat$soil_mass_mg_ha[2]*15
    } else NA_real_))
  extension_target <- if (complete) ref_mass[2] else ref_mass[1]
  if (!is_arable && extension_target > max(mass)) extensions[[id]] <- bind_cols(key,data.frame(x=max(mass),xend=extension_target,y=tail(carbon,1),yend=if(complete) values[2] else values[1]))
}
esm_coordinates <- bind_rows(coords); esm_profiles <- bind_rows(estimates) |> order_soil()
esm_extensions <- bind_rows(extensions)
write_table(esm_coordinates,"soc_ESM_cumulative_coordinates")
write_table(esm_profiles,"soc_ESM_profile_estimates")
write_table(esm_profiles,"soc_stock_comparison_profiles")
esm_long <- esm_profiles |> tidyr::pivot_longer(c(SOC_stock_upper_mg_ha,SOC_stock_lower_mg_ha,SOC_stock_total_mg_ha),names_to="mass_interval",values_to="SOC_stock_mg_ha") |>
  mutate(mass_interval=recode(mass_interval,SOC_stock_upper_mg_ha="Upper reference mass",SOC_stock_lower_mg_ha="Lower reference mass increment",SOC_stock_total_mg_ha="Total reference mass"))
esm_summary <- esm_long |> group_by(location_code,location,stock_basis,mass_interval) |>
  summarise(n_profiles=sum(is.finite(SOC_stock_mg_ha)),mean=mean(SOC_stock_mg_ha,na.rm=TRUE),sd=sd(SOC_stock_mg_ha,na.rm=TRUE),
    se=sd/sqrt(n_profiles),median=median(SOC_stock_mg_ha,na.rm=TRUE),q25=quantile(SOC_stock_mg_ha,.25,na.rm=TRUE),q75=quantile(SOC_stock_mg_ha,.75,na.rm=TRUE),.groups="drop") |> order_soil()
write_table(esm_summary,"soc_ESM_summary")
write_table(esm_summary,"soc_stock_comparison_summary")
write_table(filter(esm_summary,mass_interval=="Total reference mass"),"soc_stock_comparison_total_summary")
write_table(filter(esm_summary,mass_interval=="Total reference mass"),"soc_ESM_total_summary")
esm_audit <- esm_profiles |> group_by(location_code,location) |>
 summarise(n_profiles=n(),n_complete=sum(profile_complete),n_total_extrapolated=sum(total_method=="extrapolated"),
 n_upper_extrapolated=sum(upper_method=="extrapolated"),
 n_total_excluded=sum(is.na(SOC_stock_total_mg_ha)),n_upper_excluded=sum(is.na(SOC_stock_upper_mg_ha)),
 max_extrapolated_mass_mg_ha=max(extrapolated_mass_total_mg_ha,na.rm=TRUE),max_equivalent_depth_cm=max(equivalent_depth_total_cm,na.rm=TRUE),.groups="drop") |> order_soil()
write_table(esm_audit,"soc_ESM_extrapolation_audit")

# Recalculate location letters for the corrected mass increments, not fixed depths.
esm_plot_data <- esm_long |> filter(mass_interval!="Total reference mass",is.finite(SOC_stock_mg_ha)) |>
  mutate(depth_interval_cm=factor(mass_interval,levels=c("Upper reference mass","Lower reference mass increment")))
esm_pairs <- list(); esm_letters <- list(); esm_kw <- list()
for (interval in levels(esm_plot_data$depth_interval_cm)) {
 dat <- filter(esm_plot_data,depth_interval_cm==interval)
 pair <- dunn_depth(dat); pair$mass_interval <- interval; esm_pairs[[interval]] <- pair
 kt <- kruskal.test(SOC_stock_mg_ha~location,data=dat)
 esm_kw[[interval]] <- data.frame(mass_interval=interval,H=unname(kt$statistic),df=unname(kt$parameter),p=kt$p.value)
 subsets <- unlist(lapply(1:3,function(k) combn(1:3,k,simplify=FALSE)),recursive=FALSE)
 cliques <- Filter(function(s) length(s)==1 || all(vapply(combn(s,2,simplify=FALSE),function(v) pair$p_BH[pair$group1==location_order[v[1]] & pair$group2==location_order[v[2]]] >= .05,logical(1))),subsets)
 maximal <- Filter(function(s) !any(vapply(cliques,function(t) length(t)>length(s) && all(s %in% t),logical(1))),cliques)
 lab <- vapply(1:3,function(i) paste0(letters[which(vapply(maximal,function(s) i %in% s,logical(1)))],collapse=""),character(1))
 esm_letters[[interval]] <- data.frame(location=factor(location_order,levels=location_order),depth_interval_cm=interval,letter=lab,y=max(dat$SOC_stock_mg_ha)*1.1)
}
esm_pairs <- bind_rows(esm_pairs); esm_letters <- bind_rows(esm_letters) |> mutate(depth_interval_cm=factor(depth_interval_cm,levels=levels(esm_plot_data$depth_interval_cm)))
write_table(esm_pairs,"soc_ESM_layer_dunn_BH"); write_table(bind_rows(esm_kw),"soc_ESM_layer_kruskal");write_table(esm_letters,"soc_ESM_layer_letters")
esm_boxplot <- ggplot(esm_plot_data,aes(location,SOC_stock_mg_ha,colour=location,shape=location)) +
 geom_boxplot(outlier.shape=NA,colour="grey30",width=.6) + geom_point(position=position_jitter(width=.12,seed=1),alpha=.65,size=1.8) +
 geom_text(data=esm_letters,aes(location,y,label=letter),inherit.aes=FALSE,size=4.5) + facet_wrap(~depth_interval_cm,labeller=as_labeller(c("Upper reference mass"="0-15 cm reference mass depth", "Lower reference mass increment"="15-30 cm reference mass depth"))) +
 publication_scales(location_order,include_linetype=FALSE) + theme_publication() + theme(legend.position="none") +
 labs(x=NULL,y=expression("SOC stock (Mg C ha"^{-1}*")"),caption="Arable: measured fixed-depth stocks. Alley/tree row: ESM stocks at arable reference masses; physical depths vary.\nDunn letters: BH adjustment within mass interval, p < 0.05. Boxes: median and IQR; whiskers: 1.5 x IQR.")
save_publication_plot(esm_boxplot,project_path("results/figures/soc_ESM_by_mass_layer"),8,4.8)

# One small facet per alley/tree sampling profile, including incomplete profiles.
site_key <- esm_profiles |> filter(location_code!="3_arable") |> arrange(location,sampling_id) |>
 mutate(site_label=paste0(as.character(location)," ",sampling_id,ifelse(profile_complete,""," *")),site_label=factor(site_label,levels=site_label)) |>
 select(profile_id,site_label)
write_table(left_join(site_key,soil_profile_metadata,by="profile_id"),"soc_ESM_figure_profile_key")
plot_coords <- inner_join(esm_coordinates,site_key,by="profile_id")
plot_extensions <- inner_join(esm_extensions,site_key,by="profile_id")
plot_targets <- esm_profiles |> inner_join(site_key,by="profile_id") |>
 tidyr::pivot_longer(c(SOC_ESM_upper_mg_ha,SOC_ESM_total_mg_ha),names_to="target",values_to="SOC") |>
 mutate(reference=ifelse(target=="SOC_ESM_upper_mg_ha","ESM-corrected 0-15 cm SOC stock","ESM-corrected 0-30 cm SOC stock"),
        mass=ifelse(target=="SOC_ESM_upper_mg_ha",ref_mass[1],ref_mass[2])) |> filter(is.finite(SOC))
esm_overview <- ggplot() +
 geom_vline(xintercept=ref_mass,colour="grey65",linetype="dotted",linewidth=.35) +
 geom_line(data=plot_coords,aes(cumulative_mass_mg_ha,cumulative_SOC_mg_ha,group=profile_id),linewidth=.45) +
 geom_point(data=plot_coords,aes(cumulative_mass_mg_ha,cumulative_SOC_mg_ha),size=.85) +
 geom_segment(data=plot_extensions,aes(x=x,xend=xend,y=y,yend=yend),colour=publication_palette[4],linetype="dashed",linewidth=.55) +
 geom_point(data=plot_targets,aes(mass,SOC,colour=reference,shape=reference),size=1.65) +
 scale_colour_manual(values=c("ESM-corrected 0-15 cm SOC stock"=publication_palette[1],"ESM-corrected 0-30 cm SOC stock"=publication_palette[2])) +
 scale_shape_manual(values=c("ESM-corrected 0-15 cm SOC stock"=17,"ESM-corrected 0-30 cm SOC stock"=15)) +
 facet_wrap(~site_label,ncol=6) + theme_publication(9) +
 theme(strip.text=element_text(size=8),axis.text=element_text(size=6.5),legend.title=element_blank(),panel.spacing=grid::unit(.6,"lines")) +
 scale_x_continuous(breaks=c(0,2000,4000,6000),labels=function(x) format(x,big.mark=",",scientific=FALSE,trim=TRUE)) +
 labs(x=expression("Cumulative soil mass (Mg soil ha"^{-1}*")"),y=expression("Cumulative SOC stock (Mg C ha"^{-1}*")"),
 caption=paste0("Black: measured cumulative coordinates joined linearly from the origin. Purple dashed: extension using the final measured layer SOC content.\nGrey dotted lines: arable mean cumulative reference masses (",round(ref_mass[1])," and ",round(ref_mass[2])," Mg soil/ha). Coloured symbols: evaluated stocks.\n* Shallow bedrock: upper-reference estimate only; no lower interval or full-profile estimate. Shared axes; labels show land cover and company core number (Field 2)."))
save_publication_plot(esm_overview,project_path("results/figures/supplement_soc_ESM_cumulative_profiles"),13.4,11.4)
writeLines(c("Linear ESM: origin plus measured cumulative soil-mass/SOC-stock endpoints; straight segments, no spline.",
 "Reference masses: sum of mean arable layer masses; all available observations per layer (n shown in reference table).",
 "Arable stocks remain measured fixed-depth values; only alley and tree-row profiles are evaluated at the arable mean reference masses.",
 "Complete profiles: linear interpolation within measured mass; beyond 30 cm, extend last segment with measured 15-30 cm SOC concentration.",
 "Shallow-bedrock profiles: upper-reference stock from the measured upper-layer slope, extended to that mass if necessary; no total or lower-increment estimate.",
 "Mass intervals correspond to arable fixed-depth layers but are not fixed physical depths in other profiles. Total is arable 0-30 cm equivalent mass.",
 "No additional organic-matter subtraction or coarse-fragment adjustment; mass uses supplied fine bulk density.",
 "SD/SE are conditional on estimated reference masses; reference-mass uncertainty is not propagated.",
 "Fixed-depth outputs are retained separately. Supplementary BD and content tables remain measured 0-30 cm properties.",
 "Profile independence and spatial clustering remain open; ESM tests are exploratory."),project_path("results/tables/soc_ESM_README.txt"))


# Diagnostics for rank-based sampled-core comparisons; independence is a design issue.
comparison_diagnostics <- esm_plot_data |> group_by(location_code,location,depth_interval_cm) |>
 summarise(n=n(),median=median(SOC_stock_mg_ha),q25=quantile(SOC_stock_mg_ha,.25),q75=quantile(SOC_stock_mg_ha,.75),
 min=min(SOC_stock_mg_ha),max=max(SOC_stock_mg_ha),n_unique=n_distinct(SOC_stock_mg_ha),.groups="drop")
write.csv(comparison_diagnostics,project_path("results/checks/soc_comparison_distribution_diagnostics.csv"),row.names=FALSE)
influence <- list()
for (interval in levels(esm_plot_data$depth_interval_cm)) {
 dat <- filter(esm_plot_data,depth_interval_cm==interval)
 full <- dunn_depth(dat)
 for (i in seq_len(nrow(dat))) {
  reduced <- dunn_depth(dat[-i,]); reduced$omitted_profile_id <- dat$profile_id[i]; reduced$mass_interval <- interval
  reduced$full_p_BH <- full$p_BH
  reduced$decision_changed <- (reduced$p_BH < .05) != (full$p_BH < .05)
  influence[[length(influence)+1]] <- reduced
 }
}
write.csv(bind_rows(influence),project_path("results/checks/soc_comparison_leave_one_out.csv"),row.names=FALSE)
writeLines(c("Rank comparisons assume independent cores. Separate land-cover distributions and leave-one-core-out sensitivity are saved.",
 "Reference field versus agroforestry field is not replicated land-use assignment. Former treatment is confounded with block/row band.",
 "Different spreads preclude an unqualified median-only interpretation. Pairwise p-values describe sampled-core rank contrasts, not causal or replicated treatment effects.",
 "The fine-BD volume denominator and any required coarse-fragment correction remain an outstanding measurement-basis check; this revision corrects FD versus ESM handling only."),project_path("results/checks/soc_comparison_diagnostic_notes.txt"))
