# Supplementary measured 0-30 cm properties: land-cover comparisons.
property_pairs <- list(); property_kw <- list(); property_letters <- list()
for (variable_name in c("BD_mass_weighted_g_cm3","SOC_content_mean_percent")) {
 dat <- profile_properties |> mutate(SOC_stock_mg_ha=.data[[variable_name]])
 pair <- dunn_depth(dat);pair$variable <- variable_name; property_pairs[[variable_name]] <- pair
 kt <- kruskal.test(SOC_stock_mg_ha~location,data=dat)
 property_kw[[variable_name]] <- data.frame(variable=variable_name,H=unname(kt$statistic),df=unname(kt$parameter),p=kt$p.value)
 subsets <- unlist(lapply(1:3,function(k) combn(1:3,k,simplify=FALSE)),recursive=FALSE)
 cliques <- Filter(function(s) length(s)==1 || all(vapply(combn(s,2,simplify=FALSE),function(v) pair$p_BH[pair$group1==location_order[v[1]] & pair$group2==location_order[v[2]]] >= .05,logical(1))),subsets)
 maximal <- Filter(function(s) !any(vapply(cliques,function(t) length(t)>length(s) && all(s %in% t),logical(1))),cliques)
 lab <- vapply(1:3,function(i) paste0(letters[which(vapply(maximal,function(s) i %in% s,logical(1)))],collapse=""),character(1))
 property_letters[[variable_name]] <- data.frame(variable=variable_name,location=location_order,significance_letter=lab)
}
properties <- properties |> left_join(bind_rows(property_letters),by=c("variable","location"))
write_table(bind_rows(property_pairs),"supplement_soil_properties_dunn_BH")
write_table(bind_rows(property_kw),"supplement_soil_properties_kruskal")
write_table(properties,"supplement_soil_properties_0_30")
write_table(filter(properties,variable=="BD_mass_weighted_g_cm3"),"supplement_BD_0_30")
write_table(filter(properties,variable=="SOC_content_mean_percent"),"supplement_SOC_content_0_30")
writeLines("Supplementary BD and SOC-content letters compare land covers using two-sided tie-corrected Dunn tests, BH adjustment across three pairs separately for each property, alpha 0.05. Shared letters indicate no detected difference. Tests use complete-profile measured 0-30 cm property values and assume profile independence.",project_path("results/tables/supplement_soil_properties_letters_README.txt"))
