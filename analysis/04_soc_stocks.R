# Source after prepare_data.R; standalone execution uses only the soil preparation.
if (!exists("paper_data")) {
  options(poplar.paper.root = normalizePath("poplar_paper", winslash = "/"))
  .libPaths(c(file.path(getOption("poplar.paper.root"), "renv/library"), .libPaths()))
  library(dplyr); library(ggplot2)
  source("plot_style.R")
  source("poplar_paper/scripts/config.R")
  source("poplar_paper/scripts/prep/00_helpers.R")
}
# Always reload the current raw CSV, including when a prepared session exists.
source(project_path("scripts", "prep", "03_soc.R"))
location_order <- c("Arable reference", "Alley", "Tree row")
order_soil <- function(x) x |> mutate(location = factor(location, levels = location_order)) |> arrange(location)
soil_depth <- order_soil(soil_depth)
soil_stock_summary <- order_soil(soil_stock_summary)
write_table <- function(x, name) write.csv(x, project_path("results/tables", paste0(name, ".csv")), row.names = FALSE)
write_table(soil_stock_summary, "soc_profile_summary")
write_table(order_soil(soil_depth_summary), "supplement_soil_depth_summary")

# Depth-specific exploratory inference, matching the legacy Dunn BH procedure.
dunn_depth <- function(dat) {
  dat <- dat[is.finite(dat$SOC_stock_mg_ha), ]
  ranks <- rank(dat$SOC_stock_mg_ha); N <- nrow(dat)
  ties <- table(dat$SOC_stock_mg_ha)
  variance <- N * (N + 1) / 12 - sum(ties^3 - ties) / (12 * (N - 1))
  means <- tapply(ranks, dat$location, mean); ns <- table(dat$location)
  pairs <- combn(location_order, 2)
  out <- data.frame(group1 = pairs[1, ], group2 = pairs[2, ])
  out$z <- vapply(seq_len(ncol(pairs)), function(i) {
    a <- pairs[1,i]; b <- pairs[2,i]
    (means[a] - means[b]) / sqrt(variance * (1/ns[a] + 1/ns[b]))
  }, numeric(1))
  out$p <- 2 * pnorm(-abs(out$z)); out$p_BH <- p.adjust(out$p, "BH")
  out
}
kw <- list(); tests <- list(); annotations <- list()
for (depth in c("0-15", "15-30")) {
  dat <- filter(soil_depth, depth_interval_cm == depth)
  test <- kruskal.test(SOC_stock_mg_ha ~ location, data = dat)
  kw[[depth]] <- data.frame(depth_interval_cm = depth, H = unname(test$statistic), df = unname(test$parameter), p = test$p.value)
  pairs <- dunn_depth(dat); pairs$depth_interval_cm <- depth; tests[[depth]] <- pairs
  # Maximal nonsignificant cliques give shared letters, including bridging groups.
  subsets <- unlist(lapply(1:3, function(k) combn(1:3, k, simplify = FALSE)), recursive = FALSE)
  cliques <- Filter(function(s) length(s) == 1 || all(vapply(combn(s,2,simplify=FALSE), function(p) {
    row <- pairs$group1 == location_order[p[1]] & pairs$group2 == location_order[p[2]]
    pairs$p_BH[row] >= .05
  }, logical(1))), subsets)
  maximal <- Filter(function(s) !any(vapply(cliques, function(t) length(t)>length(s) && all(s %in% t), logical(1))), cliques)
  labels <- vapply(1:3, function(i) paste0(letters[which(vapply(maximal, function(s) i %in% s, logical(1)))], collapse=""), character(1))
  annotations[[depth]] <- data.frame(location = factor(location_order, levels=location_order), depth_interval_cm=depth, letter=labels, y=max(dat$SOC_stock_mg_ha,na.rm=TRUE)*1.09)
}
kw <- bind_rows(kw); tests <- bind_rows(tests); annotations <- bind_rows(annotations)
write_table(kw,"soc_stock_depth_kruskal"); write_table(tests,"soc_stock_depth_dunn_BH"); write_table(annotations,"soc_stock_depth_letters")
p <- ggplot(soil_depth, aes(location, SOC_stock_mg_ha, colour=location, shape=location)) +
  geom_boxplot(outlier.shape=NA, colour="grey30", width=.6) +
  geom_point(position=position_jitter(width=.12,seed=1),alpha=.65,size=1.8) +
  geom_text(data=annotations,aes(x=location,y=y,label=letter),inherit.aes=FALSE,size=4.5) +
  facet_wrap(~depth_interval_cm,labeller=as_labeller(c("0-15"="0-15 cm","15-30"="15-30 cm"))) +
  labs(x=NULL,y=expression("SOC stock (Mg C ha"^{-1}*")"),
       caption="Letters compare locations within each depth (Dunn, BH-adjusted p < 0.05).\nShared letters indicate no detected difference. Boxes: median and IQR; whiskers: 1.5 x IQR; points: samples.") +
  publication_scales(location_order,include_linetype=FALSE) + theme_publication() + theme(legend.position="none")
save_publication_plot(p,project_path("results/figures/soc_stock_by_depth"),width=8,height=4.8)

# Profile aggregation precedes summaries across profiles. No partial profiles.
profile_properties <- soil_depth |> filter(profile_id %in% soil_profile_complete$profile_id) |>
  group_by(profile_id,sampling_id,location_code,location) |>
  summarise(depth_interval_cm="0-30",
    BD_mass_weighted_g_cm3=sum(bulk_density_g_cm3^2 * depth_thickness_cm)/sum(bulk_density_g_cm3 * depth_thickness_cm),
    SOC_content_mean_percent=mean(SOC_percent), .groups="drop") |> order_soil()
profile_properties <- left_join(profile_properties,soil_profile_metadata,by="profile_id")
stopifnot(nrow(profile_properties)==nrow(soil_profile_complete), !anyNA(profile_properties[c("BD_mass_weighted_g_cm3","SOC_content_mean_percent")]))
properties <- profile_properties |> tidyr::pivot_longer(c(BD_mass_weighted_g_cm3,SOC_content_mean_percent),names_to="variable",values_to="value") |>
  group_by(location_code,location,depth_interval_cm,variable) |>
  summarise(n_profiles=n(),mean=mean(value),sd=sd(value),se=sd(value)/sqrt(n()),median=median(value),q25=quantile(value,.25),q75=quantile(value,.75),.groups="drop") |> order_soil()
write_table(profile_properties,"soil_profile_properties_0_30")
write_table(properties,"supplement_soil_properties_0_30")
write_table(filter(properties,variable=="BD_mass_weighted_g_cm3"),"supplement_BD_0_30")
write_table(filter(properties,variable=="SOC_content_mean_percent"),"supplement_SOC_content_0_30")
writeLines(c("SOC stocks: fixed depth 0-30 cm, sum of both observed layers; Mg C/ha.",
 "BD: soil-mass-weighted within profile: sum(BD^2 * thickness)/sum(BD * thickness); g/cm3. Layer mass per unit area = BD * thickness.",
 "SOC content: arithmetic average of the two layer percentages per profile, then summary across profiles; percent.",
 "All 0-30 summaries use complete profiles. SD describes variation across profiles; SE = SD/sqrt(n).",
 "BD weighting does not constitute equivalent-soil-mass correction of SOC stocks.",
 "Depth letters: two-sided tie-corrected Dunn tests; BH across three location pairs separately per depth, alpha 0.05.",
 "Inference assumes independent profiles and is exploratory pending clarification of spatial clustering.",
 "Upscaling requires tree-row and alley area fractions and a common area basis with aboveground carbon."), project_path("results/tables/soc_tables_README.txt"))


source(project_path("analysis", "04b_soc_ESM.R"))

source(project_path("analysis", "04c_soil_property_letters.R"))

# Refresh soil datasets and the soil members of the preparation cache only.
soil_exports <- list(soil_depth=soil_depth, soil_profiles=soil_profiles,
 soil_profile_complete=soil_profile_complete, soil_stock_summary=soil_stock_summary,
 soil_depth_summary=soil_depth_summary)
for (name in names(soil_exports)) write.csv(soil_exports[[name]],
 project_path("data/processed",paste0(name,".csv")),row.names=FALSE,na="")
write.csv(filter(soil_profiles,!profile_complete),project_path("results/checks/incomplete_soil_profiles.csv"),row.names=FALSE,na="")
cache_path <- project_path("data/processed/paper_data.rds")
if (file.exists(cache_path)) {
 cached <- readRDS(cache_path)
 for (name in names(soil_exports)) cached[[name]] <- soil_exports[[name]]
 saveRDS(cached,cache_path)
 inventory <- data.frame(dataset=names(cached),rows=vapply(cached,nrow,integer(1)),columns=vapply(cached,ncol,integer(1)))
 write.csv(inventory,project_path("results/checks/prepared_dataset_inventory.csv"),row.names=FALSE)
}
write.csv(data.frame(source="data/raw/study_site_soil_2024.csv",
 md5=unname(tools::md5sum(project_path("data/raw/study_site_soil_2024.csv"))),
 n_layers=nrow(soil_depth),n_profiles=nrow(soil_profiles),n_complete=nrow(soil_profile_complete)),
 project_path("results/checks/soc_source_audit.csv"),row.names=FALSE)
# Keep the fixed-depth total-stock figure current alongside ESM figures.
p_total <- ggplot(order_soil(soil_profile_complete),aes(location,SOC_stock_0_30_mg_ha,colour=location,shape=location)) +
 geom_boxplot(outlier.shape=NA,colour="grey30") +
 geom_point(position=position_jitter(width=.12,seed=1),alpha=.65,size=1.8) +
 publication_scales(location_order,include_linetype=FALSE) + theme_publication() + theme(legend.position="none") +
 labs(x=NULL,y=expression("SOC stock, 0-30 cm (Mg C ha"^{-1}*")"),
 caption=paste0("2024 complete measured profiles (n = ",nrow(soil_profile_complete),"). Boxes: median and IQR; whiskers: 1.5 x IQR."))
save_publication_plot(p_total,project_path("results/figures/soc_stock_0_30"))

